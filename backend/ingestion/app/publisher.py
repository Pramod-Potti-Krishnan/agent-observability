"""Redis Streams publisher for trace events"""
import json
import redis
import os
from typing import Optional
import logging

logger = logging.getLogger(__name__)


class TracePublisher:
    """Publishes traces to Redis Streams for async processing"""

    def __init__(self, redis_url: Optional[str] = None):
        """
        Initialize publisher

        Args:
            redis_url: Redis connection URL (defaults to env variable)
        """
        url = redis_url or os.getenv('REDIS_URL', 'redis://localhost:6379/0')
        self.client = redis.from_url(url, decode_responses=False)
        self.stream_name = "traces:pending"

    def publish_trace(self, trace_data: dict) -> str:
        """
        Publish a single trace to Redis Stream

        Args:
            trace_data: Trace data dictionary

        Returns:
            str: Message ID from Redis
        """
        try:
            # Convert trace to JSON
            trace_json = json.dumps(trace_data, default=str)

            # Add to stream
            message_id = self.client.xadd(
                self.stream_name,
                {"data": trace_json},
                maxlen=100000  # Keep last 100k messages
            )

            logger.info(f"Published trace {trace_data.get('trace_id')} to stream: {message_id}")
            return message_id.decode('utf-8') if isinstance(message_id, bytes) else message_id

        except Exception as e:
            logger.error(f"Failed to publish trace: {str(e)}")
            raise

    def publish_batch(self, traces: list[dict]) -> list[str]:
        """
        Publish multiple traces to Redis Stream

        Args:
            traces: List of trace data dictionaries

        Returns:
            list[str]: List of message IDs from Redis
        """
        message_ids = []

        try:
            # Use pipeline for efficiency
            pipe = self.client.pipeline()

            for trace in traces:
                trace_json = json.dumps(trace, default=str)
                pipe.xadd(
                    self.stream_name,
                    {"data": trace_json},
                    maxlen=100000
                )

            # Execute pipeline
            results = pipe.execute()
            message_ids = [
                (r.decode('utf-8') if isinstance(r, bytes) else r) for r in results
            ]

            logger.info(f"Published {len(traces)} traces to stream")
            return message_ids

        except Exception as e:
            logger.error(f"Failed to publish batch: {str(e)}")
            raise

    def get_stream_length(self) -> int:
        """Get current length of traces stream"""
        return self.client.xlen(self.stream_name)

    def close(self):
        """Close Redis connection"""
        self.client.close()
