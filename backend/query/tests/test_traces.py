"""Tests for traces endpoints"""
import pytest
from unittest.mock import AsyncMock, patch


@pytest.mark.asyncio
async def test_list_traces_default_params(async_client, mock_workspace_id, sample_traces):
    """Test traces listing with default parameters"""
    with patch('app.routes.traces.get_traces_list', new_callable=AsyncMock) as mock_get_traces:
        mock_get_traces.return_value = (sample_traces, len(sample_traces))
        
        response = await async_client.get(
            "/api/v1/traces",
            headers={"X-Workspace-ID": mock_workspace_id}
        )
        
        assert response.status_code == 200
        data = response.json()
        
        assert "items" in data
        assert "total" in data
        assert "page" in data
        assert "page_size" in data
        assert "has_next" in data
        assert "has_prev" in data
        assert len(data["items"]) == 2


@pytest.mark.asyncio
async def test_list_traces_with_filters(async_client, mock_workspace_id, sample_traces):
    """Test traces listing with agent_id and status filters"""
    with patch('app.routes.traces.get_traces_list', new_callable=AsyncMock) as mock_get_traces:
        filtered = [t for t in sample_traces if t['status'] == 'success']
        mock_get_traces.return_value = (filtered, len(filtered))
        
        response = await async_client.get(
            "/api/v1/traces?agent_id=test-agent&status=success",
            headers={"X-Workspace-ID": mock_workspace_id}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert len(data["items"]) == 1
        assert data["items"][0]["status"] == "success"


@pytest.mark.asyncio
async def test_list_traces_pagination(async_client, mock_workspace_id, sample_traces):
    """Test traces listing pagination"""
    with patch('app.routes.traces.get_traces_list', new_callable=AsyncMock) as mock_get_traces:
        mock_get_traces.return_value = (sample_traces[:1], 2)
        
        response = await async_client.get(
            "/api/v1/traces?limit=1&page=1",
            headers={"X-Workspace-ID": mock_workspace_id}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["page"] == 1
        assert data["page_size"] == 1
        assert data["has_next"] is True
        assert data["has_prev"] is False


@pytest.mark.asyncio
async def test_list_traces_invalid_limit(async_client, mock_workspace_id):
    """Test traces listing with invalid limit"""
    response = await async_client.get(
        "/api/v1/traces?limit=200",
        headers={"X-Workspace-ID": mock_workspace_id}
    )
    
    assert response.status_code == 400
    assert "Limit must be between 1 and 100" in response.json()["detail"]


@pytest.mark.asyncio
async def test_list_traces_invalid_status(async_client, mock_workspace_id):
    """Test traces listing with invalid status"""
    response = await async_client.get(
        "/api/v1/traces?status=invalid",
        headers={"X-Workspace-ID": mock_workspace_id}
        )
    
    assert response.status_code == 400
    assert "Status must be one of" in response.json()["detail"]


@pytest.mark.asyncio
async def test_get_trace_detail_success(async_client, mock_workspace_id, sample_traces):
    """Test getting trace detail by ID"""
    with patch('app.routes.traces.get_trace_detail', new_callable=AsyncMock) as mock_get_detail:
        trace = sample_traces[0].copy()
        trace.update({
            'input': 'test input',
            'output': 'test output',
            'error': None,
            'metadata': {}
        })
        mock_get_detail.return_value = trace
        
        response = await async_client.get(
            "/api/v1/traces/trace_001",
            headers={"X-Workspace-ID": mock_workspace_id}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["trace_id"] == "trace_001"
        assert "input" in data
        assert "output" in data


@pytest.mark.asyncio
async def test_get_trace_detail_not_found(async_client, mock_workspace_id):
    """Test getting non-existent trace"""
    with patch('app.routes.traces.get_trace_detail', new_callable=AsyncMock) as mock_get_detail:
        mock_get_detail.return_value = None
        
        response = await async_client.get(
            "/api/v1/traces/nonexistent",
            headers={"X-Workspace-ID": mock_workspace_id}
        )
        
        assert response.status_code == 404
        assert "Trace not found" in response.json()["detail"]
