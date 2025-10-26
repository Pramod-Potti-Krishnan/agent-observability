"""Database connection pool management for Query Service"""
import asyncpg
import logging
from typing import Optional
from .config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


class DatabaseManager:
    """Manages database connection pools"""

    def __init__(self):
        self.timescale_pool: Optional[asyncpg.Pool] = None
        self.postgres_pool: Optional[asyncpg.Pool] = None

    async def connect_timescale(self):
        """Create connection pool to TimescaleDB"""
        if self.timescale_pool is None:
            try:
                self.timescale_pool = await asyncpg.create_pool(
                    settings.timescale_url,
                    min_size=5,
                    max_size=20,
                    command_timeout=10,
                    max_queries=50000,
                    max_inactive_connection_lifetime=300
                )
                logger.info("TimescaleDB connection pool created")
            except Exception as e:
                logger.error(f"Failed to create TimescaleDB pool: {str(e)}")
                raise

    async def connect_postgres(self):
        """Create connection pool to PostgreSQL (metadata)"""
        if self.postgres_pool is None:
            try:
                self.postgres_pool = await asyncpg.create_pool(
                    settings.postgres_url,
                    min_size=2,
                    max_size=10,
                    command_timeout=5
                )
                logger.info("PostgreSQL connection pool created")
            except Exception as e:
                logger.error(f"Failed to create PostgreSQL pool: {str(e)}")
                raise

    async def close(self):
        """Close all database connections"""
        if self.timescale_pool:
            await self.timescale_pool.close()
            logger.info("TimescaleDB connection pool closed")
        if self.postgres_pool:
            await self.postgres_pool.close()
            logger.info("PostgreSQL connection pool closed")


# Global database manager instance
db_manager = DatabaseManager()


async def get_timescale_pool() -> asyncpg.Pool:
    """Dependency to get TimescaleDB connection pool"""
    if db_manager.timescale_pool is None:
        await db_manager.connect_timescale()
    return db_manager.timescale_pool


async def get_postgres_pool() -> asyncpg.Pool:
    """Dependency to get PostgreSQL connection pool"""
    if db_manager.postgres_pool is None:
        await db_manager.connect_postgres()
    return db_manager.postgres_pool
