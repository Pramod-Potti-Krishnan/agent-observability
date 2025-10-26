"""Home dashboard endpoints"""
from fastapi import APIRouter, HTTPException, status, Depends, Header
from typing import Optional
import asyncpg
from ..models import HomeKPIs, KPIMetric
from ..database import get_timescale_pool, get_postgres_pool
from ..queries import get_home_kpis, parse_time_range
from ..cache import get_cache, set_cache
from ..config import get_settings

router = APIRouter(prefix="/api/v1/metrics", tags=["metrics"])
settings = get_settings()


@router.get("/home-kpis", response_model=HomeKPIs)
async def get_home_dashboard_kpis(
    range: str = "24h",
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool),
    postgres_pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Get home dashboard KPIs with caching.

    Query Parameters:
        - range: Time range (1h, 24h, 7d, 30d) - Default: 24h

    Returns:
        HomeKPIs with all metrics and percentage changes
    """
    # Parse time range
    range_hours = parse_time_range(range)
    if range_hours is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid time range: {range}. Valid options: 1h, 24h, 7d, 30d"
        )

    # Try cache first
    cache_key = f"home_kpis:{x_workspace_id}:{range}"
    cached = get_cache(cache_key)
    if cached:
        return HomeKPIs(**cached)

    # Query database
    try:
        kpi_data = await get_home_kpis(timescale_pool, postgres_pool, x_workspace_id, range_hours)

        if not kpi_data:
            # Return zeros if no data
            kpi_data = {
                'curr_requests': 0,
                'requests_change': 0.0,
                'curr_latency': 0.0,
                'latency_change': 0.0,
                'curr_error_rate': 0.0,
                'error_rate_change': 0.0,
                'curr_cost': 0.0,
                'cost_change': 0.0,
                'curr_quality_score': 0.0,
                'quality_score_change': 0.0
            }

        # Format response
        result = HomeKPIs(
            total_requests=KPIMetric(
                value=float(kpi_data['curr_requests']),
                change=kpi_data['requests_change'],
                change_label=f"vs last {range}",
                trend='normal'
            ),
            avg_latency_ms=KPIMetric(
                value=kpi_data['curr_latency'],
                change=kpi_data['latency_change'],
                change_label=f"vs last {range}",
                trend='inverse'
            ),
            error_rate=KPIMetric(
                value=kpi_data['curr_error_rate'],
                change=kpi_data['error_rate_change'],
                change_label=f"vs last {range}",
                trend='inverse'
            ),
            total_cost_usd=KPIMetric(
                value=kpi_data['curr_cost'],
                change=kpi_data['cost_change'],
                change_label=f"vs last {range}",
                trend='normal'
            ),
            avg_quality_score=KPIMetric(
                value=kpi_data['curr_quality_score'],
                change=kpi_data['quality_score_change'],
                change_label=f"vs last {range}",
                trend='normal'
            )
        )

        # Cache result
        try:
            set_cache(cache_key, result.model_dump(), settings.cache_ttl_home_kpis)
        except Exception as cache_error:
            # Log but don't fail request on cache errors
            pass

        return result

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch home KPIs: {str(e)}"
        )
