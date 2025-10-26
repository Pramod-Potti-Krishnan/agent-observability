"""Pytest fixtures for Query Service tests"""
import pytest
import asyncpg
from httpx import AsyncClient
from app.main import app


@pytest.fixture
async def async_client():
    """HTTP client fixture for testing FastAPI endpoints"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client


@pytest.fixture
def mock_workspace_id():
    """Mock workspace ID for testing"""
    return "550e8400-e29b-41d4-a716-446655440000"


@pytest.fixture
def sample_kpi_data():
    """Sample KPI data for testing"""
    return {
        'curr_requests': 1000,
        'prev_requests': 800,
        'requests_change': 25.0,
        'curr_latency': 1234.5,
        'prev_latency': 1500.0,
        'latency_change': -17.7,
        'curr_error_rate': 1.5,
        'prev_error_rate': 2.0,
        'error_rate_change': -25.0,
        'curr_cost': 234.56,
        'prev_cost': 200.00,
        'cost_change': 17.28,
        'curr_quality_score': 87.3,
        'prev_quality_score': 85.0,
        'quality_score_change': 2.7
    }


@pytest.fixture
def sample_traces():
    """Sample traces for testing"""
    return [
        {
            'trace_id': 'trace_001',
            'agent_id': 'test-agent',
            'workspace_id': '550e8400-e29b-41d4-a716-446655440000',
            'timestamp': '2025-10-22T10:00:00Z',
            'latency_ms': 1234,
            'status': 'success',
            'model': 'gpt-4-turbo',
            'model_provider': 'openai',
            'tokens_total': 500,
            'cost_usd': 0.05,
            'tags': ['production']
        },
        {
            'trace_id': 'trace_002',
            'agent_id': 'test-agent',
            'workspace_id': '550e8400-e29b-41d4-a716-446655440000',
            'timestamp': '2025-10-22T10:05:00Z',
            'latency_ms': 2000,
            'status': 'error',
            'model': 'gpt-4-turbo',
            'model_provider': 'openai',
            'tokens_total': 300,
            'cost_usd': 0.03,
            'tags': ['production']
        }
    ]
