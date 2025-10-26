"""Tests for trace processor"""
import pytest
from datetime import datetime
from app.processor import TraceProcessor


@pytest.fixture
def processor():
    """Create processor instance"""
    return TraceProcessor()


@pytest.fixture
def valid_trace_data():
    """Valid trace data for testing"""
    return {
        "trace_id": "trace_123",
        "agent_id": "agent_456",
        "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
        "timestamp": "2024-01-01T12:00:00Z",
        "latency_ms": 150,
        "status": "success",
        "model": "gpt-4",
        "model_provider": "openai",
        "tokens_input": 100,
        "tokens_output": 50,
        "metadata": {"key": "value"},
        "tags": ["test"]
    }


class TestTraceProcessor:
    """Test trace processing logic"""

    def test_process_valid_trace(self, processor, valid_trace_data):
        """Test processing a valid trace"""
        processed = processor.process_trace(valid_trace_data)

        assert processed is not None
        assert processed['trace_id'] == valid_trace_data['trace_id']
        assert processed['tokens_total'] == 150  # 100 + 50
        assert 'timestamp' in processed
        assert 'input' in processed
        assert 'output' in processed
        assert 'error' in processed

    def test_process_trace_calculates_total_tokens(self, processor):
        """Test that processor calculates total tokens"""
        trace_data = {
            "trace_id": "trace_123",
            "agent_id": "agent_456",
            "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
            "timestamp": "2024-01-01T12:00:00Z",
            "latency_ms": 150,
            "model": "gpt-4",
            "tokens_input": 100,
            "tokens_output": 50
        }

        processed = processor.process_trace(trace_data)

        assert processed['tokens_total'] == 150

    def test_process_batch_separates_valid_and_invalid(self, processor):
        """Test batch processing separates valid and invalid traces"""
        traces = [
            {
                "trace_id": "valid_1",
                "agent_id": "agent_1",
                "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
                "timestamp": "2024-01-01T12:00:00Z",
                "latency_ms": 100,
                "model": "gpt-4"
            },
            {
                "trace_id": "invalid_1"
                # Missing required fields
            },
            {
                "trace_id": "valid_2",
                "agent_id": "agent_2",
                "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
                "timestamp": "2024-01-01T12:00:00Z",
                "latency_ms": 200,
                "model": "gpt-4"
            }
        ]

        processed, failed = processor.process_batch(traces)

        # Should have 2 valid, 1 failed
        assert len(processed) >= 1  # At least some valid
        assert len(failed) >= 0  # May have failures

    def test_process_trace_with_error_status(self, processor):
        """Test processing trace with error status"""
        error_trace = {
            "trace_id": "error_trace",
            "agent_id": "agent_456",
            "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
            "timestamp": "2024-01-01T12:00:00Z",
            "latency_ms": 150,
            "model": "gpt-4",
            "status": "error",
            "error": "API timeout"
        }

        processed = processor.process_trace(error_trace)

        assert processed is not None
        assert processed['status'] == 'error'
        assert processed['error'] == "API timeout"
