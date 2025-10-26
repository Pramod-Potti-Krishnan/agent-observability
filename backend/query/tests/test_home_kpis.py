"""Tests for home KPIs endpoint"""
import pytest
from unittest.mock import AsyncMock, patch
from app.queries import parse_time_range


@pytest.mark.asyncio
async def test_home_kpis_valid_range(async_client, mock_workspace_id, sample_kpi_data):
    """Test home KPIs endpoint with valid 24h time range"""
    with patch('app.routes.home.get_home_kpis', new_callable=AsyncMock) as mock_get_kpis:
        mock_get_kpis.return_value = sample_kpi_data
        
        response = await async_client.get(
            "/api/v1/metrics/home-kpis?range=24h",
            headers={"X-Workspace-ID": mock_workspace_id}
        )
        
        assert response.status_code == 200
        data = response.json()
        
        assert "total_requests" in data
        assert "avg_latency_ms" in data
        assert "error_rate" in data
        assert "total_cost_usd" in data
        assert "avg_quality_score" in data
        
        # Validate structure
        assert "value" in data["total_requests"]
        assert "change" in data["total_requests"]
        assert "trend" in data["total_requests"]
        assert data["total_requests"]["trend"] == "normal"
        assert data["avg_latency_ms"]["trend"] == "inverse"


@pytest.mark.asyncio
async def test_home_kpis_invalid_range(async_client, mock_workspace_id):
    """Test home KPIs endpoint with invalid time range"""
    response = await async_client.get(
        "/api/v1/metrics/home-kpis?range=invalid",
        headers={"X-Workspace-ID": mock_workspace_id}
    )
    
    assert response.status_code == 400
    assert "Invalid time range" in response.json()["detail"]


@pytest.mark.asyncio
async def test_home_kpis_no_data(async_client, mock_workspace_id):
    """Test home KPIs with workspace that has no data"""
    with patch('app.routes.home.get_home_kpis', new_callable=AsyncMock) as mock_get_kpis:
        mock_get_kpis.return_value = {}
        
        response = await async_client.get(
            "/api/v1/metrics/home-kpis?range=24h",
            headers={"X-Workspace-ID": mock_workspace_id}
        )
        
        assert response.status_code == 200
        data = response.json()
        
        # Should return zeros
        assert data["total_requests"]["value"] == 0.0
        assert data["total_requests"]["change"] == 0.0


def test_parse_time_range():
    """Test time range parsing function"""
    assert parse_time_range("1h") == 1
    assert parse_time_range("24h") == 24
    assert parse_time_range("7d") == 168
    assert parse_time_range("30d") == 720
    assert parse_time_range("invalid") is None


@pytest.mark.asyncio
async def test_home_kpis_missing_workspace_header(async_client):
    """Test home KPIs endpoint without workspace header"""
    response = await async_client.get("/api/v1/metrics/home-kpis?range=24h")
    
    # Should fail with 422 (missing required header)
    assert response.status_code == 422
