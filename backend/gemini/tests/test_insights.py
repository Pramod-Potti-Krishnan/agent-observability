"""Tests for gemini integration service endpoints"""
import pytest
from httpx import AsyncClient
from unittest.mock import patch


@pytest.mark.asyncio
async def test_cost_optimization_mocked(test_client, mock_gemini_client):
    """Test POST /api/v1/insights/cost-optimization returns suggestions (mock Gemini)"""
    # Mock data fetching functions
    with patch('app.routes.insights.fetch_cost_data') as mock_fetch_cost:
        mock_fetch_cost.return_value = {
            'total_cost': 1500.00,
            'by_model': {
                'gemini-pro': 800.00,
                'gpt-4': 700.00
            },
            'request_counts': {
                'gemini-pro': 6000,
                'gpt-4': 4000
            }
        }

        response = await test_client.post(
            "/api/v1/insights/cost-optimization",
            json={"time_range": "30d"},
            headers={"X-Workspace-ID": "test-workspace-id"}
        )

        assert response.status_code == 200
        data = response.json()

        # Verify response structure
        assert "suggestions" in data
        assert isinstance(data["suggestions"], list)
        assert len(data["suggestions"]) > 0

        # Verify suggestion structure
        suggestion = data["suggestions"][0]
        assert "suggestion" in suggestion
        assert "estimated_savings" in suggestion
        assert "difficulty" in suggestion

        # Verify total savings
        assert "total_potential_savings" in data
        assert data["total_potential_savings"] > 0


@pytest.mark.asyncio
async def test_business_goals_retrieval(test_client, db_pool):
    """Test GET /api/v1/business-goals returns goals list"""
    response = await test_client.get(
        "/api/v1/business-goals",
        headers={"X-Workspace-ID": "test-workspace-id"}
    )

    assert response.status_code == 200
    data = response.json()

    # Verify response structure
    assert "goals" in data
    assert isinstance(data["goals"], list)

    # Verify goal data if present
    if len(data["goals"]) > 0:
        goal = data["goals"][0]
        assert "id" in goal
        assert "goal_type" in goal
        assert "name" in goal
        assert "baseline" in goal
        assert "target" in goal
        assert "current_value" in goal

        # Verify progress calculation
        if "progress_percentage" in goal:
            assert 0 <= goal["progress_percentage"] <= 100


@pytest.mark.asyncio
async def test_error_diagnosis_mocked(test_client, mock_gemini_client):
    """Test error diagnosis endpoint with mocked Gemini"""
    with patch('app.routes.insights.fetch_error_data') as mock_fetch_errors:
        mock_fetch_errors.return_value = {
            'total_errors': 50,
            'error_types': {
                'timeout': 20,
                'rate_limit': 15,
                'invalid_input': 15
            },
            'recent_errors': [
                {'message': 'Request timeout after 30s', 'count': 20}
            ]
        }

        response = await test_client.post(
            "/api/v1/insights/error-diagnosis",
            json={"time_range": "7d"},
            headers={"X-Workspace-ID": "test-workspace-id"}
        )

        assert response.status_code == 200
        data = response.json()

        # Verify response has diagnosis
        assert "diagnosis" in data or "root_causes" in data or "recommendations" in data


@pytest.mark.asyncio
async def test_daily_summary(test_client, mock_gemini_client):
    """Test GET /api/v1/insights/daily-summary returns automated summary"""
    with patch('app.routes.insights.fetch_daily_metrics') as mock_fetch_metrics:
        mock_fetch_metrics.return_value = {
            'total_requests': 10000,
            'total_cost': 150.00,
            'avg_latency': 500.0,
            'error_rate': 0.05,
            'top_agents': ['agent-1', 'agent-2']
        }

        response = await test_client.get(
            "/api/v1/insights/daily-summary",
            headers={"X-Workspace-ID": "test-workspace-id"}
        )

        assert response.status_code == 200
        data = response.json()

        # Verify summary structure
        assert "summary" in data or "highlights" in data or "metrics" in data
