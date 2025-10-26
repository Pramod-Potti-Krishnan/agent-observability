"""Ingestion API routes"""
from fastapi import APIRouter, HTTPException, status, Header
from .models import TraceInput, BatchTraceInput, TraceResponse, BatchTraceResponse
from .publisher import TracePublisher
from .validation import validate_trace, validate_batch
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1", tags=["ingestion"])

# Initialize publisher
publisher = TracePublisher()


@router.post("/traces", response_model=TraceResponse, status_code=status.HTTP_202_ACCEPTED)
async def ingest_trace(trace: TraceInput):
    """
    Ingest a single trace

    This endpoint accepts a trace and queues it for async processing.
    The trace will be validated, enriched, and stored in TimescaleDB.
    """
    try:
        # Convert to dict and publish to Redis Stream
        trace_dict = trace.model_dump(mode='json')
        message_id = publisher.publish_trace(trace_dict)

        return TraceResponse(
            trace_id=trace.trace_id,
            status="accepted",
            message=f"Trace queued for processing (message_id: {message_id})"
        )

    except Exception as e:
        logger.error(f"Failed to ingest trace: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to queue trace: {str(e)}"
        )


@router.post("/traces/batch", response_model=BatchTraceResponse, status_code=status.HTTP_202_ACCEPTED)
async def ingest_batch(batch: BatchTraceInput):
    """
    Ingest multiple traces in a single request

    Accepts up to 100 traces. Invalid traces are rejected with error details.
    Valid traces are queued for processing.
    """
    # Validate all traces
    traces_data = [trace.model_dump(mode='json') for trace in batch.traces]
    valid_traces, validation_errors = validate_batch(traces_data)

    # Publish valid traces
    published_count = 0
    publish_errors = []

    if valid_traces:
        try:
            valid_traces_dicts = [t.model_dump(mode='json') for t in valid_traces]
            publisher.publish_batch(valid_traces_dicts)
            published_count = len(valid_traces)
        except Exception as e:
            logger.error(f"Failed to publish batch: {str(e)}")
            publish_errors.append({
                "error": f"Failed to queue traces: {str(e)}"
            })

    # Combine errors
    all_errors = validation_errors + publish_errors
    rejected_count = len(validation_errors)

    return BatchTraceResponse(
        accepted=published_count,
        rejected=rejected_count,
        errors=all_errors
    )


@router.post("/traces/otlp", status_code=status.HTTP_202_ACCEPTED)
async def ingest_otlp(
    content_type: str = Header(...),
    data: bytes = None
):
    """
    OTLP (OpenTelemetry Protocol) endpoint

    Accepts traces in OTLP format (protobuf or JSON).
    This is a basic implementation for Phase 1.
    """
    # Basic OTLP support - just acknowledge for now
    # Full implementation would parse OTLP format and convert to our schema
    logger.info(f"Received OTLP request with content-type: {content_type}")

    return {
        "status": "accepted",
        "message": "OTLP ingestion is in development. Use /api/v1/traces for now."
    }


@router.get("/health")
async def health_check():
    """Health check endpoint"""
    # Check Redis connection
    try:
        stream_length = publisher.get_stream_length()
        return {
            "status": "healthy",
            "service": "ingestion",
            "stream_length": stream_length
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Redis connection failed: {str(e)}"
        )
