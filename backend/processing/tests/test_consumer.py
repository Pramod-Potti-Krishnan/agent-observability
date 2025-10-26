"""Tests for Redis Streams consumer"""
import pytest
from unittest.mock import Mock, patch
from app.consumer import TraceConsumer


@pytest.fixture
def mock_redis():
    """Mock Redis client"""
    with patch('app.consumer.redis') as mock:
        mock_client = Mock()
        mock.from_url.return_value = mock_client
        yield mock_client


class TestTraceConsumer:
    """Test Redis Streams consumer"""

    def test_consumer_initialization(self, mock_redis):
        """Test consumer initializes correctly"""
        consumer = TraceConsumer()

        assert consumer is not None
        assert consumer.stream_name == "traces:pending"
        assert consumer.consumer_group == "processors"
        assert consumer.consumer_name.startswith("processor_")

    def test_consume_batch_returns_traces(self, mock_redis):
        """Test consuming a batch of traces"""
        # Mock Redis response
        mock_redis.xreadgroup.return_value = [
            (
                b'traces:pending',
                [
                    (
                        b'1234567890-0',
                        {b'data': b'{"trace_id": "trace_1", "agent_id": "agent_1"}'}
                    ),
                    (
                        b'1234567891-0',
                        {b'data': b'{"trace_id": "trace_2", "agent_id": "agent_2"}'}
                    )
                ]
            )
        ]

        consumer = TraceConsumer()
        traces = consumer.consume_batch(batch_size=10, block_ms=1000)

        assert len(traces) == 2
        assert traces[0]['trace_id'] == 'trace_1'
        assert traces[1]['trace_id'] == 'trace_2'
        assert '_message_id' in traces[0]

    def test_acknowledge_batch(self, mock_redis):
        """Test acknowledging processed messages"""
        consumer = TraceConsumer()
        message_ids = ['1234567890-0', '1234567891-0']

        consumer.acknowledge_batch(message_ids)

        # Verify xack was called
        mock_redis.xack.assert_called_once_with(
            consumer.stream_name,
            consumer.consumer_group,
            *message_ids
        )
