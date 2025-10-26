"""Alerts endpoints"""
from fastapi import APIRouter, HTTPException, status, Depends, Header
from typing import Optional, List
import asyncpg
from ..models import Alert
from ..database import get_timescale_pool
from ..queries import get_recent_alerts
from ..cache import get_cache, set_cache
from ..config import get_settings

router = APIRouter(prefix="/api/v1/alerts", tags=["alerts"])
settings = get_settings()


@router.get("/recent")
async def get_recent_alerts_endpoint(
    limit: int = 10,
    severity: Optional[str] = None,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get recent alerts with optional severity filter.

    Query Parameters:
        - limit: Number of alerts to return (1-100) - Default: 10
        - severity: Filter by severity (info, warning, critical) - Optional

    Returns:
        List of recent alerts
    """
    # Validate limit
    if limit < 1 or limit > 100:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Limit must be between 1 and 100"
        )

    # Validate severity if provided
    if severity and severity not in ['info', 'warning', 'critical']:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Severity must be one of: info, warning, critical"
        )

    # Try cache first
    cache_key = f"alerts:recent:{x_workspace_id}:{limit}:{severity or 'all'}"
    cached = get_cache(cache_key)
    if cached:
        return cached

    # Query database
    try:
        alerts = await get_recent_alerts(pool, x_workspace_id, limit, severity)

        result = {
            "items": alerts,
            "total": len(alerts)
        }

        # Cache result
        try:
            set_cache(cache_key, result, settings.cache_ttl_alerts)
        except Exception:
            pass

        return result

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch alerts: {str(e)}"
        )
