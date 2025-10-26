"""Shared test fixtures for evaluation service"""
import pytest
import asyncpg
from unittest.mock import AsyncMock, MagicMock, patch
from httpx import AsyncClient
import json

# Mock Gemini API
@pytest.fixture
def mock_gemini_client():
    """Mock Google Gemini client"""
    with patch('app.gemini_client.genai') as mock:
        # Create mock response
        mock_response = MagicMock()
        mock_response.text = json.dumps({
            "accuracy": 8.5,
            "relevance": 9.0,
            "helpfulness": 8.0,
            "coherence": 8.5,
            "overall": 8.5,
            "reasoning": "Excellent response quality with accurate and helpful information."
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

    # Mock fetchrow for trace lookup
    async def mock_fetchrow(query, *args):
        if "SELECT" in query and "traces" in query:
            return {
                'trace_id': 'test-trace-123',
                'input': 'What is artificial intelligence?',
                'output': 'Artificial Intelligence (AI) is the simulation of human intelligence processes by machines.',
                'status': 'success',
                'agent_id': 'test-agent'
            }
        elif "evaluations" in query:
            return {
                'id': 'eval-id-123',
                'workspace_id': 'test-workspace-id',
                'trace_id': 'test-trace-123',
                'created_at': '2025-01-15T10:00:00Z',
                'evaluator': 'gemini',
                'accuracy_score': 8.5,
                'relevance_score': 9.0,
                'helpfulness_score': 8.0,
                'coherence_score': 8.5,
                'overall_score': 8.5,
                'reasoning': 'Excellent response quality',
                'metadata': {'model': 'gemini-pro'}
            }
        return None

    # Mock fetch for batch queries
    async def mock_fetch(query, *args):
        if "evaluations" in query:
            return [
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
                    'reasoning': 'Good quality',
                    'metadata': {}
                }
            ]
        return []

    # Mock execute for inserts
    async def mock_execute(query, *args):
        return "INSERT 0 1"

    pool.fetchrow = mock_fetchrow
    pool.fetch = mock_fetch
    pool.execute = mock_execute

    return pool


@pytest.fixture
async def test_client(db_pool, mock_gemini_client):
    """Test client with mocked dependencies"""
    from app.main import app

    # Override database dependency
    async def override_get_postgres_pool():
        return db_pool

    from app.database import get_postgres_pool
    app.dependency_overrides[get_postgres_pool] = override_get_postgres_pool

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
