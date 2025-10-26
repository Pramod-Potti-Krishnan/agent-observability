"""Tests for Performance Monitoring endpoints"""
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from datetime import datetime
from app.models import PerformanceOverview, LatencyPercentiles, LatencyPercentilesItem, Throughput, ThroughputItem, ErrorAnalysis, ErrorAnalysisItem


@pytest.mark.asyncio
async def test_performance_overview_valid_range(async_client, mock_workspace_id):
    """Test performance overview endpoint with valid 24h time range"""
    response = await async_client.get(
        "/api/v1/performance/overview?range=24h",
        headers={"X-Workspace-ID": mock_workspace_id}
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert "p50_latency_ms" in data
    assert "p95_latency_ms" in data
    assert "p99_latency_ms" in data
    assert "avg_latency_ms" in data
    assert "error_rate" in data
    assert "success_rate" in data
    assert "total_requests" in data
    assert "requests_per_second" in data
    
    # Validate data types
    assert isinstance(data["p50_latency_ms"], (int, float))
    assert isinstance(data["p95_latency_ms"], (int, float))
    assert isinstance(data["p99_latency_ms"], (int, float))
    assert isinstance(data["error_rate"], (int, float))
    assert isinstance(data["success_rate"], (int, float))
    
    # Validate percentile ordering: P50 <= P95 <= P99
    assert data["p50_latency_ms"] <= data["p95_latency_ms"]
    assert data["p95_latency_ms"] <= data["p99_latency_ms"]
    
    # Validate rates are percentages (0-100)
    assert 0 <= data["error_rate"] <= 100
    assert 0 <= data["success_rate"] <= 100


@pytest.mark.asyncio
async def test_latency_percentiles_hourly_granularity(async_client, mock_workspace_id):
    """Test latency percentiles with hourly granularity"""
    response = await async_client.get(
        "/api/v1/performance/latency?range=7d&granularity=hourly",
        headers={"X-Workspace-ID": mock_workspace_id}
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert "data" in data
    assert "granularity" in data
    assert "range" in data
    assert data["granularity"] == "hourly"
    assert data["range"] == "7d"
    assert isinstance(data["data"], list)
    
    # Check data item structure if data exists
    if len(data["data"]) > 0:
        item = data["data"][0]
        assert "timestamp" in item
        assert "p50" in item
        assert "p95" in item
        assert "p99" in item
        assert "avg" in item
        # Validate percentile ordering
        assert item["p50"] <= item["p95"]
        assert item["p95"] <= item["p99"]


@pytest.mark.asyncio
async def test_throughput_daily_granularity(async_client, mock_workspace_id):
    """Test throughput with daily granularity"""
    response = await async_client.get(
        "/api/v1/performance/throughput?range=7d&granularity=daily",
        headers={"X-Workspace-ID": mock_workspace_id}
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert "data" in data
    assert "granularity" in data
    assert "range" in data
    assert data["granularity"] == "daily"
    assert data["range"] == "7d"
    assert isinstance(data["data"], list)
    
    # Check data item structure if data exists
    if len(data["data"]) > 0:
        item = data["data"][0]
        assert "timestamp" in item
        assert "success_count" in item
        assert "error_count" in item
        assert "timeout_count" in item
        assert "total_count" in item
        assert "requests_per_second" in item
        
        # Validate total equals sum of statuses
        assert item["total_count"] == (
            item["success_count"] + item["error_count"] + item["timeout_count"]
        )


@pytest.mark.asyncio
async def test_error_analysis(async_client, mock_workspace_id):
    """Test error analysis endpoint"""
    response = await async_client.get(
        "/api/v1/performance/errors?range=24h&limit=20",
        headers={"X-Workspace-ID": mock_workspace_id}
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert "data" in data
    assert "total_errors" in data
    assert "total_requests" in data
    assert "overall_error_rate" in data
    assert isinstance(data["data"], list)
    assert isinstance(data["total_errors"], int)
    assert isinstance(data["total_requests"], int)
    assert isinstance(data["overall_error_rate"], (int, float))
    assert len(data["data"]) <= 20  # Limit should be respected
    
    # Validate overall error rate
    assert 0 <= data["overall_error_rate"] <= 100
    
    # Check data item structure if data exists
    if len(data["data"]) > 0:
        item = data["data"][0]
        assert "agent_id" in item
        assert "error_type" in item
        assert "error_count" in item
        assert "error_rate" in item
        assert "last_occurrence" in item
        assert 0 <= item["error_rate"] <= 100


@pytest.mark.asyncio
async def test_performance_with_agent_filter(async_client, mock_workspace_id):
    """Test performance endpoints with agent_id filter"""
    agent_id = "test-agent-123"
    
    response = await async_client.get(
        f"/api/v1/performance/latency?range=24h&granularity=hourly&agent_id={agent_id}",
        headers={"X-Workspace-ID": mock_workspace_id}
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert "data" in data
    assert isinstance(data["data"], list)


@pytest.mark.asyncio
async def test_performance_missing_workspace_header(async_client):
    """Test performance endpoints without workspace header"""
    response = await async_client.get("/api/v1/performance/overview?range=24h")
    
    # Should fail with 422 (missing required header)
    assert response.status_code == 422
