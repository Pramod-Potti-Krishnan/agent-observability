"""Input validation utilities"""
from pydantic import ValidationError
from .models import TraceInput, BatchTraceInput
import logging

logger = logging.getLogger(__name__)


def validate_trace(trace_data: dict) -> tuple[bool, TraceInput, str]:
    """
    Validate a single trace

    Args:
        trace_data: Raw trace data dictionary

    Returns:
        tuple: (is_valid, validated_trace, error_message)
    """
    try:
        validated = TraceInput(**trace_data)
        return True, validated, ""
    except ValidationError as e:
        error_msg = str(e)
        logger.warning(f"Trace validation failed: {error_msg}")
        return False, None, error_msg


def validate_batch(traces: list[dict]) -> tuple[list[TraceInput], list[dict]]:
    """
    Validate a batch of traces

    Args:
        traces: List of raw trace dictionaries

    Returns:
        tuple: (valid_traces, errors)
            - valid_traces: List of validated TraceInput objects
            - errors: List of error dicts with index and error message
    """
    valid_traces = []
    errors = []

    for index, trace_data in enumerate(traces):
        is_valid, validated, error_msg = validate_trace(trace_data)

        if is_valid:
            valid_traces.append(validated)
        else:
            errors.append({
                "index": index,
                "trace_id": trace_data.get("trace_id", "unknown"),
                "error": error_msg
            })

    return valid_traces, errors
