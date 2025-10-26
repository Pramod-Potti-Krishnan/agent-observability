"""Tests for evaluation service endpoints"""
import pytest
from httpx import AsyncClient
from unittest.mock import patch, MagicMock
import json


@pytest.mark.asyncio
async def test_evaluate_trace_success(test_client, mock_gemini_client):
    """Test successful trace evaluation via POST /api/v1/evaluate/trace/{trace_id}"""
    trace_id = "test-trace-123"

    # Mock database save_evaluation to return an ID
    with patch('app.routes.evaluate.save_evaluation') as mock_save:
        mock_save.return_value = "eval-id-123"

        response = await test_client.post(
            f"/api/v1/evaluate/trace/{trace_id}",
            headers={"X-Workspace-ID": "test-workspace-id"}
        )

        assert response.status_code == 200
        data = response.json()

        # Verify response structure
        assert "overall_score" in data
        assert "accuracy_score" in data
        assert "relevance_score" in data
        assert "helpfulness_score" in data
        assert "coherence_score" in data
        assert "reasoning" in data
        assert "evaluator" in data

        # Verify score ranges
        assert 0 <= data["overall_score"] <= 10
        assert 0 <= data["accuracy_score"] <= 10
        assert data["evaluator"] == "gemini"

        # Verify save was called
        assert mock_save.called


@pytest.mark.asyncio
async def test_evaluation_history(test_client, db_pool):
    """Test GET /api/v1/evaluate/history returns list of evaluations"""
    # Mock get_evaluation_history and get_evaluation_stats
    with patch('app.routes.evaluate.get_evaluation_history') as mock_history, \
         patch('app.routes.evaluate.get_evaluation_stats') as mock_stats:

        mock_history.return_value = [
            {
                'id': 'eval-1',
                'workspace_id': 'test-workspace-id',
                'trace_id': 'trace-1',
                'created_at': '2025-01-15T10:00:00Z',
                'evaluator': 'gemini',
                'accuracy_score': 8.5,
                'relevance_score': 9.0,
                'helpfulness_score': 8.0,
                'coherence_score': 8.5,
                'overall_score': 8.5,
                'reasoning': 'Good quality response',
                'metadata': {}
            }
        ]

        mock_stats.return_value = {
            'total': 1,
            'avg_overall_score': 8.5,
            'avg_accuracy_score': 8.5,
            'avg_relevance_score': 9.0,
            'avg_helpfulness_score': 8.0,
            'avg_coherence_score': 8.5
        }

        response = await test_client.get(
            "/api/v1/evaluate/history?range=7d",
            headers={"X-Workspace-ID": "test-workspace-id"}
        )

        assert response.status_code == 200
        data = response.json()

        # Verify response structure
        assert "evaluations" in data
        assert isinstance(data["evaluations"], list)
        assert "total" in data
        assert "avg_overall_score" in data
        assert "avg_accuracy_score" in data

        # Verify data
        assert data["total"] == 1
        assert len(data["evaluations"]) == 1
        assert data["evaluations"][0]["trace_id"] == "trace-1"
        assert data["avg_overall_score"] == 8.5


@pytest.mark.asyncio
async def test_evaluate_trace_not_found(test_client):
    """Test evaluation fails when trace not found"""
    with patch('app.routes.evaluate.get_trace_by_id') as mock_get_trace:
        mock_get_trace.return_value = None

        response = await test_client.post(
            "/api/v1/evaluate/trace/nonexistent-trace",
            headers={"X-Workspace-ID": "test-workspace-id"}
        )

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_list_criteria(test_client):
    """Test GET /api/v1/evaluate/criteria returns standard criteria"""
    response = await test_client.get(
        "/api/v1/evaluate/criteria",
        headers={"X-Workspace-ID": "test-workspace-id"}
    )

    assert response.status_code == 200
    data = response.json()

    assert "criteria" in data
    assert "total" in data
    assert isinstance(data["criteria"], list)
    assert data["total"] >= 4  # At least 4 standard criteria

    # Verify standard criteria exist
    criteria_names = [c["name"] for c in data["criteria"]]
    assert "Accuracy" in criteria_names
    assert "Relevance" in criteria_names
    assert "Helpfulness" in criteria_names
    assert "Coherence" in criteria_names
