"""Tests for trace ingestion endpoints"""
import pytest
from fastapi.testclient import TestClient
from datetime import datetime
from unittest.mock import Mock, patch
from app.main import app


@pytest.fixture
def client():
    """Create test client"""
    return TestClient(app)


@pytest.fixture
def valid_trace():
    """Valid trace data"""
    return {
        "trace_id": "trace_123",
        "agent_id": "agent_456",
        "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
        "timestamp": "2024-01-01T12:00:00Z",
        "latency_ms": 150,
        "status": "success",
        "model": "gpt-4",
        "tokens_input": 100,
        "tokens_output": 50,
        "metadata": {"key": "value"},
        "tags": ["test"]
    }


class TestTraceIngestion:
    """Test single trace ingestion"""

    @patch('app.routes.TracePublisher')
    def test_ingest_single_trace_success(self, mock_publisher, client, valid_trace):
        """Test successful single trace ingestion"""
        # Mock publisher
        mock_pub_instance = Mock()
        mock_publisher.return_value = mock_pub_instance
        mock_pub_instance.publish_trace.return_value = "1234567890-0"

        # Make request
        response = client.post("/api/v1/traces", json=valid_trace)

        # Verify response
        assert response.status_code == 202
        data = response.json()
        assert "trace_id" in data
        assert "message" in data
        assert data["trace_id"] == valid_trace["trace_id"]

    @patch('app.routes.TracePublisher')
    def test_ingest_trace_with_minimal_fields(self, mock_publisher, client):
        """Test ingestion with only required fields"""
        mock_pub_instance = Mock()
        mock_publisher.return_value = mock_pub_instance
        mock_pub_instance.publish_trace.return_value = "1234567890-0"

        minimal_trace = {
            "trace_id": "trace_minimal",
            "agent_id": "agent_001",
            "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
            "timestamp": "2024-01-01T12:00:00Z",
            "latency_ms": 100,
            "model": "gpt-4"
        }

        response = client.post("/api/v1/traces", json=minimal_trace)

        assert response.status_code == 202
        assert mock_pub_instance.publish_trace.called

    @patch('app.routes.TracePublisher')
    def test_ingest_trace_with_error_status(self, mock_publisher, client, valid_trace):
        """Test ingestion of trace with error status"""
        mock_pub_instance = Mock()
        mock_publisher.return_value = mock_pub_instance
        mock_pub_instance.publish_trace.return_value = "1234567890-0"

        error_trace = valid_trace.copy()
        error_trace["status"] = "error"
        error_trace["error"] = "API rate limit exceeded"

        response = client.post("/api/v1/traces", json=error_trace)

        assert response.status_code == 202

    def test_health_check_endpoint(self, client):
        """Test health check returns 200"""
        response = client.get("/health")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "service" in data

    @patch('app.routes.TracePublisher')
    def test_ingest_trace_publisher_failure(self, mock_publisher, client, valid_trace):
        """Test handling of publisher failures"""
        # Mock publisher to raise exception
        mock_pub_instance = Mock()
        mock_publisher.return_value = mock_pub_instance
        mock_pub_instance.publish_trace.side_effect = Exception("Redis connection failed")

        response = client.post("/api/v1/traces", json=valid_trace)

        # Should return 500 on internal error
        assert response.status_code == 500

    def test_otlp_endpoint_stub(self, client):
        """Test OTLP endpoint returns not implemented"""
        response = client.post(
            "/api/v1/traces/otlp",
            json={"resourceSpans": []},
            headers={"Content-Type": "application/json"}
        )

        # OTLP endpoint should be stubbed for Phase 2
        assert response.status_code in [200, 501]
