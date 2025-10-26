"""Activity stream endpoints"""
from fastapi import APIRouter, HTTPException, status, Depends, Header
import asyncpg
from ..models import Activity
from ..database import get_timescale_pool
from ..queries import get_activity_stream
from ..cache import get_cache, set_cache
from ..config import get_settings

router = APIRouter(prefix="/api/v1/activity", tags=["activity"])
settings = get_settings()


@router.get("/stream")
async def get_activity_stream_endpoint(
    limit: int = 50,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get recent activity stream.

    Query Parameters:
        - limit: Number of activities to return (1-100) - Default: 50

    Returns:
        List of recent activities
    """
    # Validate limit
    if limit < 1 or limit > 100:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Limit must be between 1 and 100"
        )

    # Try cache first
    cache_key = f"activity:stream:{x_workspace_id}:{limit}"
    cached = get_cache(cache_key)
    if cached:
        return cached

    # Query database
    try:
        activities = await get_activity_stream(pool, x_workspace_id, limit)

        result = {
            "items": activities,
            "total": len(activities)
        }

        # Cache result
        try:
            set_cache(cache_key, result, settings.cache_ttl_activity)
        except Exception:
            pass

        return result

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch activity stream: {str(e)}"
        )
