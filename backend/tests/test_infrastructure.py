"""Tests for infrastructure components (databases, connections)."""

import pytest
import asyncpg
import redis
from dotenv import load_dotenv
import os

load_dotenv()


class TestDatabaseConnections:
    """Test database connectivity."""

    @pytest.mark.asyncio
    async def test_timescaledb_connection(self):
        """Test TimescaleDB connection."""
        timescale_url = os.getenv(
            'TIMESCALE_URL',
            'postgresql://postgres:postgres@localhost:5432/agent_observability'
        )

        conn = await asyncpg.connect(timescale_url)
        try:
            # Check TimescaleDB extension is enabled
            result = await conn.fetchval(
                "SELECT COUNT(*) FROM pg_extension WHERE extname = 'timescaledb'"
            )
            assert result == 1, "TimescaleDB extension not installed"

            # Check hypertables exist
            hypertables = await conn.fetch(
                "SELECT hypertable_name FROM timescaledb_information.hypertables"
            )
            hypertable_names = [row['hypertable_name'] for row in hypertables]

            assert 'traces' in hypertable_names, "traces hypertable not found"
            assert 'performance_metrics' in hypertable_names, "performance_metrics hypertable not found"
            assert 'events' in hypertable_names, "events hypertable not found"
        finally:
            await conn.close()

    @pytest.mark.asyncio
    async def test_postgres_connection(self):
        """Test PostgreSQL connection."""
        postgres_url = os.getenv(
            'POSTGRES_URL',
            'postgresql://postgres:postgres@localhost:5433/agent_observability_metadata'
        )

        conn = await asyncpg.connect(postgres_url)
        try:
            # Check UUID extension is enabled
            result = await conn.fetchval(
                "SELECT COUNT(*) FROM pg_extension WHERE extname = 'uuid-ossp'"
            )
            assert result == 1, "UUID extension not installed"

            # Check core tables exist
            tables = await conn.fetch(
                """
                SELECT table_name FROM information_schema.tables
                WHERE table_schema = 'public'
                """
            )
            table_names = [row['table_name'] for row in tables]

            assert 'workspaces' in table_names, "workspaces table not found"
            assert 'users' in table_names, "users table not found"
            assert 'agents' in table_names, "agents table not found"
            assert 'api_keys' in table_names, "api_keys table not found"
            assert 'evaluations' in table_names, "evaluations table not found"
        finally:
            await conn.close()

    def test_redis_connection(self):
        """Test Redis connection."""
        redis_password = os.getenv('REDIS_PASSWORD', 'redis123')

        r = redis.Redis(
            host='localhost',
            port=6379,
            password=redis_password,
            decode_responses=True
        )

        # Test ping
        assert r.ping(), "Redis ping failed"

        # Test set/get
        test_key = 'test:phase0'
        test_value = 'connection_test'
        r.set(test_key, test_value)

        result = r.get(test_key)
        assert result == test_value, "Redis set/get failed"

        # Cleanup
        r.delete(test_key)


class TestSchemaValidation:
    """Test database schema is correctly created."""

    @pytest.mark.asyncio
    async def test_traces_schema(self):
        """Test traces table schema."""
        timescale_url = os.getenv(
            'TIMESCALE_URL',
            'postgresql://postgres:postgres@localhost:5432/agent_observability'
        )

        conn = await asyncpg.connect(timescale_url)
        try:
            # Check columns exist
            columns = await conn.fetch(
                """
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_name = 'traces'
                """
            )
            column_names = [row['column_name'] for row in columns]

            required_columns = [
                'trace_id', 'workspace_id', 'agent_id', 'timestamp',
                'latency_ms', 'input', 'output', 'error', 'status',
                'model', 'tokens_input', 'tokens_output', 'cost_usd'
            ]

            for col in required_columns:
                assert col in column_names, f"Column {col} not found in traces table"
        finally:
            await conn.close()

    @pytest.mark.asyncio
    async def test_workspaces_schema(self):
        """Test workspaces table schema."""
        postgres_url = os.getenv(
            'POSTGRES_URL',
            'postgresql://postgres:postgres@localhost:5433/agent_observability_metadata'
        )

        conn = await asyncpg.connect(postgres_url)
        try:
            # Check columns exist
            columns = await conn.fetch(
                """
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_name = 'workspaces'
                """
            )
            column_names = [row['column_name'] for row in columns]

            required_columns = ['id', 'name', 'slug', 'created_at', 'plan']

            for col in required_columns:
                assert col in column_names, f"Column {col} not found in workspaces table"
        finally:
            await conn.close()

    @pytest.mark.asyncio
    async def test_seed_data_exists(self):
        """Test that seed data was loaded."""
        postgres_url = os.getenv(
            'POSTGRES_URL',
            'postgresql://postgres:postgres@localhost:5433/agent_observability_metadata'
        )

        conn = await asyncpg.connect(postgres_url)
        try:
            # Check workspace exists
            workspace_count = await conn.fetchval('SELECT COUNT(*) FROM workspaces')
            assert workspace_count >= 1, "No workspaces found"

            # Check users exist
            user_count = await conn.fetchval('SELECT COUNT(*) FROM users')
            assert user_count >= 1, "No users found"

            # Check agents exist
            agent_count = await conn.fetchval('SELECT COUNT(*) FROM agents')
            assert agent_count >= 1, "No agents found"
        finally:
            await conn.close()


class TestSyntheticDataGenerator:
    """Test synthetic data generator functionality."""

    def test_generate_single_trace(self):
        """Test generating a single trace."""
        from synthetic_data.generator import SyntheticDataGenerator

        generator = SyntheticDataGenerator()
        trace = generator.generate_trace()

        # Validate trace structure
        assert 'trace_id' in trace
        assert 'workspace_id' in trace
        assert 'agent_id' in trace
        assert 'timestamp' in trace
        assert 'latency_ms' in trace
        assert 'model' in trace
        assert 'status' in trace

        # Validate trace values
        assert trace['latency_ms'] > 0
        assert trace['status'] in ['success', 'error', 'timeout']
        assert trace['workspace_id'] == "00000000-0000-0000-0000-000000000001"

    def test_generate_multiple_traces(self):
        """Test generating multiple traces."""
        from synthetic_data.generator import SyntheticDataGenerator

        generator = SyntheticDataGenerator()
        traces = generator.generate_traces(count=100, days_back=7)

        # Validate count
        assert len(traces) == 100

        # Validate traces are sorted by timestamp
        timestamps = [trace['timestamp'] for trace in traces]
        assert timestamps == sorted(timestamps)

        # Validate variety in agent_ids
        agent_ids = set(trace['agent_id'] for trace in traces)
        assert len(agent_ids) > 1, "Multiple agents should be represented"
