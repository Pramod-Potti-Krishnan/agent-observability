"""Tests for batch trace ingestion"""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch
from app.main import app


@pytest.fixture
def client():
    """Create test client"""
    return TestClient(app)


@pytest.fixture
def valid_traces():
    """Multiple valid traces for batch testing"""
    return [
        {
            "trace_id": f"trace_{i}",
            "agent_id": "agent_001",
            "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
            "timestamp": "2024-01-01T12:00:00Z",
            "latency_ms": 100 + i * 10,
            "model": "gpt-4",
            "status": "success"
        }
        for i in range(5)
    ]


class TestBatchIngestion:
    """Test batch trace ingestion"""

    @patch('app.routes.TracePublisher')
    def test_batch_ingest_success(self, mock_publisher, client, valid_traces):
        """Test successful batch ingestion"""
        # Mock publisher
        mock_pub_instance = Mock()
        mock_publisher.return_value = mock_pub_instance
        mock_pub_instance.publish_batch.return_value = [f"{i}-0" for i in range(len(valid_traces))]

        # Make request
        response = client.post("/api/v1/traces/batch", json={"traces": valid_traces})

        # Verify response
        assert response.status_code == 202
        data = response.json()
        assert "accepted" in data
        assert data["accepted"] == len(valid_traces)

    def test_batch_ingest_reject_too_many_traces(self, client):
        """Test rejection of batch with more than 100 traces"""
        # Create 101 traces
        too_many_traces = [
            {
                "trace_id": f"trace_{i}",
                "agent_id": "agent_001",
                "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
                "timestamp": "2024-01-01T12:00:00Z",
                "latency_ms": 100,
                "model": "gpt-4"
            }
            for i in range(101)
        ]

        response = client.post("/api/v1/traces/batch", json={"traces": too_many_traces})

        # Should reject batch that's too large
        assert response.status_code == 422

    @patch('app.routes.TracePublisher')
    def test_batch_ingest_empty_list(self, mock_publisher, client):
        """Test handling of empty batch"""
        mock_pub_instance = Mock()
        mock_publisher.return_value = mock_pub_instance

        response = client.post("/api/v1/traces/batch", json={"traces": []})

        # Should accept but do nothing
        assert response.status_code in [202, 422]
