"""Tests for trace validation"""
import pytest
from fastapi.testclient import TestClient
from app.main import app


@pytest.fixture
def client():
    """Create test client"""
    return TestClient(app)


@pytest.fixture
def base_trace():
    """Base valid trace for testing"""
    return {
        "trace_id": "trace_123",
        "agent_id": "agent_456",
        "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
        "timestamp": "2024-01-01T12:00:00Z",
        "latency_ms": 150,
        "model": "gpt-4"
    }


class TestTraceValidation:
    """Test trace validation logic"""

    def test_reject_invalid_trace_id(self, client, base_trace):
        """Test rejection of invalid trace_id"""
        invalid_trace = base_trace.copy()
        invalid_trace["trace_id"] = ""  # Empty trace_id

        response = client.post("/api/v1/traces", json=invalid_trace)

        assert response.status_code == 422
        data = response.json()
        assert "detail" in data

    def test_reject_invalid_workspace_id(self, client, base_trace):
        """Test rejection of invalid workspace_id UUID"""
        invalid_trace = base_trace.copy()
        invalid_trace["workspace_id"] = "not-a-uuid"

        response = client.post("/api/v1/traces", json=invalid_trace)

        assert response.status_code == 422

    def test_reject_negative_latency(self, client, base_trace):
        """Test rejection of negative latency_ms"""
        invalid_trace = base_trace.copy()
        invalid_trace["latency_ms"] = -10

        response = client.post("/api/v1/traces", json=invalid_trace)

        assert response.status_code == 422

    def test_reject_too_many_tags(self, client, base_trace):
        """Test rejection of more than 10 tags"""
        invalid_trace = base_trace.copy()
        invalid_trace["tags"] = [f"tag_{i}" for i in range(15)]  # 15 tags > 10 max

        response = client.post("/api/v1/traces", json=invalid_trace)

        assert response.status_code == 422
