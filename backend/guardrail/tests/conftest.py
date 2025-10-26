"""Shared test fixtures for guardrail service"""
import pytest
import asyncpg
from unittest.mock import AsyncMock, MagicMock
from httpx import AsyncClient


@pytest.fixture
async def db_pool():
    """Mock database pool"""
    pool = AsyncMock(spec=asyncpg.Pool)

    # Mock fetch for violations list
    async def mock_fetch(query, *args):
        if "guardrail_violations" in query:
            return [
                {
                    'id': 'violation-1',
                    'workspace_id': 'test-workspace-id',
                    'trace_id': 'trace-1',
                    'rule_id': 'rule-1',
                    'violation_type': 'pii',
                    'severity': 'high',
                    'detected_at': '2025-01-15T10:00:00Z',
                    'original_content': 'Contact me at john.doe@example.com',
                    'redacted_content': 'Contact me at [REDACTED: EMAIL]',
                    'metadata': {'pii_type': 'email'}
                }
            ]
        elif "guardrail_rules" in query:
            return [
                {
                    'id': 'rule-1',
                    'workspace_id': 'test-workspace-id',
                    'rule_name': 'PII Detection',
                    'rule_type': 'pii',
                    'severity': 'high',
                    'enabled': True,
                    'created_at': '2025-01-01T00:00:00Z',
                    'config': {}
                }
            ]
        return []

    # Mock fetchval for counts
    async def mock_fetchval(query, *args):
        if "COUNT" in query:
            return 1
        return None

    # Mock execute for inserts
    async def mock_execute(query, *args):
        return "INSERT 0 1"

    pool.fetch = mock_fetch
    pool.fetchval = mock_fetchval
    pool.execute = mock_execute

    return pool


@pytest.fixture
async def test_client(db_pool):
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
