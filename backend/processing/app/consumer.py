"""Redis Streams consumer for trace processing"""
import redis
import json
import logging
import os
from typing import Optional, Callable
import time

logger = logging.getLogger(__name__)


class TraceConsumer:
    """Consumes traces from Redis Streams for processing"""

    def __init__(self, redis_url: Optional[str] = None, consumer_group: str = "processors"):
        """
        Initialize consumer

        Args:
            redis_url: Redis connection URL
            consumer_group: Consumer group name for distributed processing
        """
        url = redis_url or os.getenv('REDIS_URL', 'redis://localhost:6379/0')
        self.client = redis.from_url(url, decode_responses=False)
        self.stream_name = "traces:pending"
        self.consumer_group = consumer_group
        self.consumer_name = f"processor_{os.getpid()}"

        # Create consumer group if it doesn't exist
        self._create_consumer_group()

    def _create_consumer_group(self):
        """Create consumer group for distributed processing"""
        try:
            self.client.xgroup_create(
                self.stream_name,
                self.consumer_group,
                id='0',
                mkstream=True
            )
            logger.info(f"Created consumer group: {self.consumer_group}")
        except redis.ResponseError as e:
            if "BUSYGROUP" in str(e):
                logger.info(f"Consumer group already exists: {self.consumer_group}")
            else:
                raise

    def consume_batch(self, batch_size: int = 10, block_ms: int = 1000) -> list[dict]:
        """
        Consume a batch of traces from the stream

        Args:
            batch_size: Number of messages to read
            block_ms: How long to block waiting for messages (milliseconds)

        Returns:
            list[dict]: List of trace data dictionaries with metadata
        """
        try:
            # Read from stream using consumer group
            messages = self.client.xreadgroup(
                self.consumer_group,
                self.consumer_name,
                {self.stream_name: '>'},
                count=batch_size,
                block=block_ms
            )

            if not messages:
                return []

            traces = []
            for stream, message_list in messages:
                for message_id, message_data in message_list:
                    try:
                        # Parse trace data
                        trace_json = message_data.get(b'data') or message_data.get('data')
                        if isinstance(trace_json, bytes):
                            trace_json = trace_json.decode('utf-8')

                        trace_data = json.loads(trace_json)

                        # Add message metadata
                        trace_data['_message_id'] = message_id.decode('utf-8') if isinstance(message_id, bytes) else message_id
                        trace_data['_stream_name'] = stream.decode('utf-8') if isinstance(stream, bytes) else stream

                        traces.append(trace_data)

                    except Exception as e:
                        logger.error(f"Failed to parse message {message_id}: {str(e)}")
                        # Move to dead letter queue
                        self._move_to_dlq(message_id, message_data, str(e))

            return traces

        except Exception as e:
            logger.error(f"Failed to consume from stream: {str(e)}")
            return []

    def acknowledge(self, message_id: str):
        """
        Acknowledge successful processing of a message

        Args:
            message_id: Message ID to acknowledge
        """
        try:
            self.client.xack(self.stream_name, self.consumer_group, message_id)
            logger.debug(f"Acknowledged message: {message_id}")
        except Exception as e:
            logger.error(f"Failed to acknowledge message {message_id}: {str(e)}")

    def acknowledge_batch(self, message_ids: list[str]):
        """
        Acknowledge multiple messages at once

        Args:
            message_ids: List of message IDs to acknowledge
        """
        if not message_ids:
            return

        try:
            self.client.xack(self.stream_name, self.consumer_group, *message_ids)
            logger.info(f"Acknowledged {len(message_ids)} messages")
        except Exception as e:
            logger.error(f"Failed to acknowledge batch: {str(e)}")

    def _move_to_dlq(self, message_id: str, message_data: dict, error: str):
        """Move failed message to dead letter queue"""
        try:
            dlq_name = "traces:dead_letter"
            self.client.xadd(
                dlq_name,
                {
                    "original_message_id": str(message_id),
                    "data": json.dumps(message_data, default=str),
                    "error": error,
                    "timestamp": str(int(time.time()))
                }
            )
            # Acknowledge the original message
            self.acknowledge(message_id)
            logger.warning(f"Moved message {message_id} to DLQ: {error}")
        except Exception as e:
            logger.error(f"Failed to move message to DLQ: {str(e)}")

    def get_pending_count(self) -> int:
        """Get count of pending messages in consumer group"""
        try:
            info = self.client.xpending(self.stream_name, self.consumer_group)
            return info['pending']
        except Exception as e:
            logger.error(f"Failed to get pending count: {str(e)}")
            return 0

    def close(self):
        """Close Redis connection"""
        self.client.close()
