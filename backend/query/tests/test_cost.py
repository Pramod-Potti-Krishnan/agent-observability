"""Tests for Cost Management endpoints"""
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from datetime import datetime
from app.models import CostOverview, CostTrend, CostTrendItem, CostByModel, CostByModelItem, Budget, BudgetUpdate


@pytest.mark.asyncio
async def test_cost_overview_valid_range(async_client, mock_workspace_id):
    """Test cost overview endpoint with valid 30d time range"""
    response = await async_client.get(
        "/api/v1/cost/overview?range=30d",
        headers={"X-Workspace-ID": mock_workspace_id}
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert "total_spend_usd" in data
    assert "avg_cost_per_call_usd" in data
    assert "projected_monthly_spend_usd" in data
    assert "change_from_previous" in data
    assert isinstance(data["total_spend_usd"], (int, float))
    assert isinstance(data["avg_cost_per_call_usd"], (int, float))
    
    # Budget fields are optional
    if data.get("budget_limit_usd"):
        assert isinstance(data["budget_limit_usd"], (int, float))
        assert "budget_remaining_usd" in data
        assert "budget_used_percentage" in data


@pytest.mark.asyncio
async def test_cost_trend_daily_granularity(async_client, mock_workspace_id):
    """Test cost trend with daily granularity"""
    response = await async_client.get(
        "/api/v1/cost/trend?range=7d&granularity=daily",
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
        assert "model" in item
        assert "total_cost_usd" in item
        assert "call_count" in item
        assert "avg_cost_per_call_usd" in item


@pytest.mark.asyncio
async def test_cost_by_model(async_client, mock_workspace_id):
    """Test cost breakdown by model"""
    response = await async_client.get(
        "/api/v1/cost/by-model?range=30d",
        headers={"X-Workspace-ID": mock_workspace_id}
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert "data" in data
    assert "total_cost_usd" in data
    assert isinstance(data["data"], list)
    assert isinstance(data["total_cost_usd"], (int, float))
    
    # Check data item structure if data exists
    if len(data["data"]) > 0:
        item = data["data"][0]
        assert "model" in item
        assert "model_provider" in item
        assert "total_cost_usd" in item
        assert "call_count" in item
        assert "avg_cost_per_call_usd" in item
        assert "percentage_of_total" in item
        # Validate percentage is between 0 and 100
        assert 0 <= item["percentage_of_total"] <= 100


@pytest.mark.asyncio
async def test_get_budget(async_client, mock_workspace_id):
    """Test get budget endpoint"""
    response = await async_client.get(
        "/api/v1/cost/budget",
        headers={"X-Workspace-ID": mock_workspace_id}
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert "workspace_id" in data
    assert "alert_threshold_percentage" in data
    assert "current_spend_usd" in data
    assert "created_at" in data
    assert "updated_at" in data
    assert isinstance(data["current_spend_usd"], (int, float))
    assert isinstance(data["alert_threshold_percentage"], (int, float))
    
    # monthly_limit_usd is optional
    if data.get("monthly_limit_usd"):
        assert isinstance(data["monthly_limit_usd"], (int, float))


@pytest.mark.asyncio
async def test_update_budget(async_client, mock_workspace_id):
    """Test update budget endpoint"""
    budget_update = {
        "monthly_limit_usd": 5000.00,
        "alert_threshold_percentage": 85.0
    }
    
    response = await async_client.put(
        "/api/v1/cost/budget",
        headers={"X-Workspace-ID": mock_workspace_id},
        json=budget_update
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert "workspace_id" in data
    assert "monthly_limit_usd" in data
    assert "alert_threshold_percentage" in data
    assert "current_spend_usd" in data
    assert data["monthly_limit_usd"] == 5000.00
    assert data["alert_threshold_percentage"] == 85.0


@pytest.mark.asyncio
async def test_cost_missing_workspace_header(async_client):
    """Test cost endpoints without workspace header"""
    response = await async_client.get("/api/v1/cost/overview?range=30d")
    
    # Should fail with 422 (missing required header)
    assert response.status_code == 422
