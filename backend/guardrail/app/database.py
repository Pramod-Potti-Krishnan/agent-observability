"""Database connection for Guardrail Service"""
import asyncpg
from typing import Optional
from .config import get_settings

settings = get_settings()
_postgres_pool: Optional[asyncpg.Pool] = None


async def get_postgres_pool() -> asyncpg.Pool:
    """Get or create PostgreSQL connection pool"""
    global _postgres_pool
    if _postgres_pool is None:
        _postgres_pool = await asyncpg.create_pool(
            settings.postgres_url,
            min_size=5,
            max_size=20,
            command_timeout=60
        )
    return _postgres_pool


async def close_postgres_pool():
    """Close PostgreSQL connection pool"""
    global _postgres_pool
    if _postgres_pool is not None:
        await _postgres_pool.close()
        _postgres_pool = None
