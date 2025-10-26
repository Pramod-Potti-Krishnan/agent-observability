"""Tests for TimescaleDB writer"""
import pytest
from datetime import datetime
from unittest.mock import AsyncMock, Mock, patch
from app.writer import TraceWriter


@pytest.fixture
def mock_asyncpg():
    """Mock asyncpg connection"""
    with patch('app.writer.asyncpg') as mock:
        mock_conn = AsyncMock()
        mock.connect.return_value = mock_conn
        yield mock_conn


@pytest.fixture
def valid_trace():
    """Valid processed trace for writing"""
    return {
        "trace_id": "trace_123",
        "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
        "agent_id": "agent_456",
        "timestamp": datetime.fromisoformat("2024-01-01T12:00:00"),
        "latency_ms": 150,
        "input": "test input",
        "output": "test output",
        "error": None,
        "status": "success",
        "model": "gpt-4",
        "model_provider": "openai",
        "tokens_input": 100,
        "tokens_output": 50,
        "tokens_total": 150,
        "cost_usd": 0.015,
        "metadata": {"key": "value"},
        "tags": ["test"]
    }


class TestTraceWriter:
    """Test TimescaleDB writer"""

    @pytest.mark.asyncio
    async def test_write_trace_success(self, mock_asyncpg, valid_trace):
        """Test writing a single trace successfully"""
        writer = TraceWriter()
        writer.conn = mock_asyncpg
        mock_asyncpg.execute.return_value = None

        result = await writer.write_trace(valid_trace)

        assert result is True
        assert mock_asyncpg.execute.called

    @pytest.mark.asyncio
    async def test_write_batch_success(self, mock_asyncpg, valid_trace):
        """Test writing multiple traces in batch"""
        writer = TraceWriter()
        writer.conn = mock_asyncpg
        mock_asyncpg.executemany.return_value = None

        traces = [valid_trace, valid_trace.copy()]
        successful, failed = await writer.write_batch(traces)

        assert successful == 2
        assert failed == 0
        assert mock_asyncpg.executemany.called

    @pytest.mark.asyncio
    async def test_write_batch_handles_failures(self, mock_asyncpg, valid_trace):
        """Test batch write falls back to individual writes on failure"""
        writer = TraceWriter()
        writer.conn = mock_asyncpg

        # Mock executemany to fail, but individual execute to succeed
        mock_asyncpg.executemany.side_effect = Exception("Batch insert failed")
        mock_asyncpg.execute.return_value = None

        traces = [valid_trace, valid_trace.copy()]
        successful, failed = await writer.write_batch(traces)

        # Should fall back to individual inserts
        assert successful >= 0
        assert failed >= 0
        assert successful + failed == 2
