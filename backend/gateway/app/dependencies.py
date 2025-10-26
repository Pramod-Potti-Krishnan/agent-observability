"""Shared dependencies for dependency injection"""
import asyncpg
from redis import Redis
from fastapi import HTTPException, status
from .config import get_settings


settings = get_settings()


async def get_postgres_connection():
    """Get PostgreSQL database connection"""
    conn = None
    try:
        conn = await asyncpg.connect(settings.postgres_url)
        yield conn
    except HTTPException:
        # Re-raise HTTP exceptions as-is
        raise
    except Exception as e:
        import traceback
        error_details = f"{type(e).__name__}: {str(e)} | {repr(e)} | {traceback.format_exc()}"
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Database connection failed: {error_details}"
        )
    finally:
        if conn:
            await conn.close()


def get_redis_client():
    """Get Redis client"""
    try:
        client = Redis.from_url(settings.redis_url, decode_responses=True)
        return client
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Redis connection failed: {str(e)}"
        )
