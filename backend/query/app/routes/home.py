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
    department: Optional[str] = None,
    environment: Optional[str] = None,
    version: Optional[str] = None,
    agent_id: Optional[str] = None,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool),
    postgres_pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Get home dashboard KPIs with multi-dimensional filtering and caching.

    Query Parameters:
        - range: Time range (1h, 24h, 7d, 30d) - Default: 24h
        - department: Filter by department code (e.g., 'engineering', 'sales')
        - environment: Filter by environment (e.g., 'production', 'staging', 'development')
        - version: Filter by version (e.g., 'v2.1', 'v2.0')
        - agent_id: Filter by specific agent ID

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

    # Build cache key with all filter dimensions
    filter_parts = [range]
    if department:
        filter_parts.append(f"dept:{department}")
    if environment:
        filter_parts.append(f"env:{environment}")
    if version:
        filter_parts.append(f"ver:{version}")
    if agent_id:
        filter_parts.append(f"agent:{agent_id}")

    cache_key = f"home_kpis:{x_workspace_id}:{':'.join(filter_parts)}"
    cached = get_cache(cache_key)
    if cached:
        return HomeKPIs(**cached)

    # Query database
    try:
        kpi_data = await get_home_kpis(
            timescale_pool,
            postgres_pool,
            x_workspace_id,
            range_hours,
            department=department,
            environment=environment,
            version=version,
            agent_id=agent_id
        )

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


@router.get("/department-breakdown")
async def get_department_breakdown(
    range: str = "24h",
    environment: Optional[str] = None,
    version: Optional[str] = None,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get request breakdown by department for visualization.

    Returns aggregated metrics per department:
    - Request counts
    - Average latency
    - Error rates
    - Total cost

    Query Parameters:
        - range: Time range (1h, 24h, 7d, 30d) - Default: 24h
        - environment: Filter by environment (optional)
        - version: Filter by version (optional)

    Note: Department filter is NOT applied here since we want to show all departments
    """
    # Parse time range
    range_hours = parse_time_range(range)
    if range_hours is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid time range: {range}. Valid options: 1h, 24h, 7d, 30d"
        )

    # Build cache key
    filter_parts = [range]
    if environment:
        filter_parts.append(f"env:{environment}")
    if version:
        filter_parts.append(f"ver:{version}")

    cache_key = f"dept_breakdown:{x_workspace_id}:{':'.join(filter_parts)}"
    cached = get_cache(cache_key)
    if cached:
        return cached

    # Build WHERE clause for optional filters
    where_clauses = ["t.workspace_id = $1", "t.timestamp >= NOW() - INTERVAL '1 hour' * $2"]
    params = [x_workspace_id, range_hours]
    param_idx = 3

    if environment:
        where_clauses.append(f"""
            t.environment_id = (SELECT id FROM environments
                               WHERE workspace_id = $1 AND environment_code = ${param_idx})
        """)
        params.append(environment)
        param_idx += 1

    if version:
        where_clauses.append(f"t.version = ${param_idx}")
        params.append(version)
        param_idx += 1

    where_clause = " AND ".join(where_clauses)

    query = f"""
    SELECT
        d.department_code,
        d.department_name,
        COUNT(t.id) as request_count,
        AVG(t.latency_ms) as avg_latency_ms,
        SUM(CASE WHEN t.status = 'error' THEN 1 ELSE 0 END)::float /
            NULLIF(COUNT(t.id), 0) * 100 as error_rate,
        SUM(COALESCE(t.cost_usd, 0)) as total_cost_usd
    FROM departments d
    LEFT JOIN traces t ON t.department_id = d.id AND {where_clause}
    WHERE d.workspace_id = $1
    GROUP BY d.department_code, d.department_name
    HAVING COUNT(t.id) > 0
    ORDER BY COUNT(t.id) DESC
    """

    try:
        async with timescale_pool.acquire() as conn:
            rows = await conn.fetch(query, *params)

            departments = [
                {
                    "department_code": row['department_code'],
                    "department_name": row['department_name'],
                    "request_count": int(row['request_count']),
                    "avg_latency_ms": float(row['avg_latency_ms']),
                    "error_rate": float(row['error_rate']),
                    "total_cost_usd": float(row['total_cost_usd'])
                }
                for row in rows
            ]

            total_requests = sum(d['request_count'] for d in departments)

            result = {
                "data": departments,
                "meta": {
                    "total_departments": len(departments),
                    "total_requests": total_requests,
                    "filters_applied": {
                        "environment": environment,
                        "version": version
                    }
                }
            }

            # Cache for 5 minutes
            set_cache(cache_key, result, ttl=300)

            return result

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch department breakdown: {str(e)}"
        )
