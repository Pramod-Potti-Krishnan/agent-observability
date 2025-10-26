"""Tests for Usage Analytics endpoints"""
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from datetime import datetime
from app.models import UsageOverview, ChangeMetrics, CallsOverTime, CallsOverTimeItem, AgentDistribution, AgentDistributionItem, TopUsers, TopUsersItem


@pytest.mark.asyncio
async def test_usage_overview_valid_range(async_client, mock_workspace_id):
    """Test usage overview endpoint with valid 24h time range"""
    response = await async_client.get(
        "/api/v1/usage/overview?range=24h",
        headers={"X-Workspace-ID": mock_workspace_id}
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert "total_calls" in data
    assert "unique_users" in data
    assert "active_agents" in data
    assert "avg_calls_per_user" in data
    assert "change_from_previous" in data
    assert isinstance(data["total_calls"], int)
    assert isinstance(data["unique_users"], int)
    assert isinstance(data["active_agents"], int)


@pytest.mark.asyncio
async def test_usage_overview_invalid_range(async_client, mock_workspace_id):
    """Test usage overview with invalid time range"""
    response = await async_client.get(
        "/api/v1/usage/overview?range=invalid",
        headers={"X-Workspace-ID": mock_workspace_id}
    )
    
    assert response.status_code == 422  # Validation error


@pytest.mark.asyncio
async def test_calls_over_time_hourly_granularity(async_client, mock_workspace_id):
    """Test calls over time with hourly granularity"""
    response = await async_client.get(
        "/api/v1/usage/calls-over-time?range=24h&granularity=hourly",
        headers={"X-Workspace-ID": mock_workspace_id}
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert "data" in data
    assert "granularity" in data
    assert "range" in data
    assert data["granularity"] == "hourly"
    assert data["range"] == "24h"
    assert isinstance(data["data"], list)
    
    # Check data item structure if data exists
    if len(data["data"]) > 0:
        item = data["data"][0]
        assert "timestamp" in item
        assert "agent_id" in item
        assert "call_count" in item
        assert "avg_latency_ms" in item
        assert "total_cost_usd" in item


@pytest.mark.asyncio
async def test_agent_distribution(async_client, mock_workspace_id):
    """Test agent distribution endpoint"""
    response = await async_client.get(
        "/api/v1/usage/agent-distribution?range=24h",
        headers={"X-Workspace-ID": mock_workspace_id}
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert "data" in data
    assert "total_calls" in data
    assert isinstance(data["data"], list)
    assert isinstance(data["total_calls"], int)
    
    # Check data item structure if data exists
    if len(data["data"]) > 0:
        item = data["data"][0]
        assert "agent_id" in item
        assert "call_count" in item
        assert "percentage" in item
        assert "avg_latency_ms" in item
        assert "error_rate" in item
        # Validate percentage is between 0 and 100
        assert 0 <= item["percentage"] <= 100


@pytest.mark.asyncio
async def test_top_users(async_client, mock_workspace_id):
    """Test top users endpoint"""
    response = await async_client.get(
        "/api/v1/usage/top-users?range=24h&limit=10",
        headers={"X-Workspace-ID": mock_workspace_id}
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert "data" in data
    assert "total_users" in data
    assert isinstance(data["data"], list)
    assert isinstance(data["total_users"], int)
    assert len(data["data"]) <= 10  # Limit should be respected
    
    # Check data item structure if data exists
    if len(data["data"]) > 0:
        item = data["data"][0]
        assert "user_id" in item
        assert "total_calls" in item
        assert "agents_used" in item
        assert "last_active" in item
        assert "trend" in item
        assert "change_percentage" in item
        assert item["trend"] in ["up", "down", "stable"]


@pytest.mark.asyncio
async def test_usage_missing_workspace_header(async_client):
    """Test usage endpoints without workspace header"""
    response = await async_client.get("/api/v1/usage/overview?range=24h")
    
    # Should fail with 422 (missing required header)
    assert response.status_code == 422
