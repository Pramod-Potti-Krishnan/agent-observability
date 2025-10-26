"""Shared test fixtures for gemini integration service"""
import pytest
import asyncpg
from unittest.mock import AsyncMock, MagicMock, patch
from httpx import AsyncClient
import json


@pytest.fixture
def mock_gemini_client():
    """Mock Google Gemini client"""
    with patch('app.gemini_client.genai') as mock:
        # Create mock response for cost optimization
        mock_response = MagicMock()
        mock_response.text = json.dumps({
            "suggestions": [
                {
                    "suggestion": "Switch to smaller model for simple queries",
                    "estimated_savings": 500.00,
                    "difficulty": "low",
                    "implementation_steps": [
                        "Classify queries by complexity",
                        "Route simple queries to gemini-flash",
                        "Monitor quality impact"
                    ]
                },
                {
                    "suggestion": "Implement request caching",
                    "estimated_savings": 300.00,
                    "difficulty": "medium"
                }
            ],
            "total_potential_savings": 800.00,
            "priority_order": [1, 2]
        })

        # Setup mock client
        mock_model = MagicMock()
        mock_model.generate_content.return_value = mock_response
        mock.GenerativeModel.return_value = mock_model

        yield mock


@pytest.fixture
async def db_pool():
    """Mock database pool"""
    pool = AsyncMock(spec=asyncpg.Pool)

    # Mock fetch for business goals
    async def mock_fetch(query, *args):
        if "business_goals" in query:
            return [
                {
                    'id': 'goal-1',
                    'workspace_id': 'test-workspace-id',
                    'goal_type': 'support_tickets',
                    'name': 'Reduce Support Tickets',
                    'baseline': 1000,
                    'target': 400,
                    'current_value': 550,
                    'unit': 'tickets',
                    'start_date': '2025-01-01',
                    'target_date': '2025-12-31',
                    'created_at': '2025-01-01T00:00:00Z'
                }
            ]
        return []

    # Mock fetchrow for single record
    async def mock_fetchrow(query, *args):
        return {
            'total_cost': 1500.00,
            'total_requests': 10000,
            'avg_latency': 500.0
        }

    pool.fetch = mock_fetch
    pool.fetchrow = mock_fetchrow

    return pool


@pytest.fixture
async def timescale_pool():
    """Mock TimescaleDB pool"""
    pool = AsyncMock(spec=asyncpg.Pool)

    async def mock_fetch(query, *args):
        # Mock metrics data
        return [
            {'model': 'gemini-pro', 'cost': 800.00, 'requests': 6000},
            {'model': 'gpt-4', 'cost': 700.00, 'requests': 4000}
        ]

    pool.fetch = mock_fetch
    return pool


@pytest.fixture
async def test_client(db_pool, timescale_pool, mock_gemini_client):
    """Test client with mocked dependencies"""
    from app.main import app

    # Override database dependencies
    async def override_get_postgres_pool():
        return db_pool

    async def override_get_timescale_pool():
        return timescale_pool

    from app.database import get_postgres_pool, get_timescale_pool
    app.dependency_overrides[get_postgres_pool] = override_get_postgres_pool
    app.dependency_overrides[get_timescale_pool] = override_get_timescale_pool

    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

    app.dependency_overrides.clear()


@pytest.fixture
def mock_redis_client():
    """Mock Redis client"""
    mock_redis = AsyncMock()
    mock_redis.get.return_value = None
    mock_redis.setex.return_value = True
    return mock_redis
