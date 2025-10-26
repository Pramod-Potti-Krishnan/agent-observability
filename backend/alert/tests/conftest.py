"""Shared test fixtures for alert service"""
import pytest
import asyncpg
from unittest.mock import AsyncMock
from httpx import AsyncClient
from datetime import datetime


@pytest.fixture
async def db_pool():
    """Mock database pool for both PostgreSQL and TimescaleDB"""
    pool = AsyncMock(spec=asyncpg.Pool)

    # Mock fetch for alerts list
    async def mock_fetch(query, *args):
        if "alert_notifications" in query:
            return [
                {
                    'id': 'alert-1',
                    'workspace_id': 'test-workspace-id',
                    'rule_id': 'rule-1',
                    'severity': 'high',
                    'status': 'open',
                    'message': 'Latency threshold exceeded',
                    'created_at': datetime.now(),
                    'metric_value': 2500.0,
                    'threshold': 2000.0,
                    'metadata': {}
                }
            ]
        elif "alert_rules" in query:
            return [
                {
                    'id': 'rule-1',
                    'workspace_id': 'test-workspace-id',
                    'rule_name': 'High Latency Alert',
                    'metric': 'latency_p99',
                    'condition': 'greater_than',
                    'threshold': 2000.0,
                    'severity': 'high',
                    'enabled': True,
                    'window_minutes': 60,
                    'created_at': datetime.now()
                }
            ]
        return []

    # Mock fetchrow for single record
    async def mock_fetchrow(query, *args):
        if "alert_notifications" in query:
            return {
                'id': 'alert-1',
                'workspace_id': 'test-workspace-id',
                'rule_id': 'rule-1',
                'severity': 'high',
                'status': 'open',
                'message': 'Latency threshold exceeded',
                'created_at': datetime.now(),
                'metric_value': 2500.0,
                'threshold': 2000.0,
                'metadata': {}
            }
        return None

    # Mock fetchval for counts
    async def mock_fetchval(query, *args):
        if "COUNT" in query:
            return 1
        return None

    # Mock execute for updates
    async def mock_execute(query, *args):
        return "UPDATE 1"

    pool.fetch = mock_fetch
    pool.fetchrow = mock_fetchrow
    pool.fetchval = mock_fetchval
    pool.execute = mock_execute

    return pool


@pytest.fixture
async def test_client(db_pool):
    """Test client with mocked dependencies"""
    from app.main import app

    # Override database dependencies
    async def override_get_postgres_pool():
        return db_pool

    async def override_get_timescale_pool():
        return db_pool

    from app.database import get_postgres_pool, get_timescale_pool
    app.dependency_overrides[get_postgres_pool] = override_get_postgres_pool
    app.dependency_overrides[get_timescale_pool] = override_get_timescale_pool

    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

    app.dependency_overrides.clear()
