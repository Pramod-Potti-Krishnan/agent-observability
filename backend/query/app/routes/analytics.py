"""Advanced analytics endpoints - latency trends, cost breakdown, error analysis"""
from fastapi import APIRouter, HTTPException, status, Depends, Header
from typing import Optional, List
from datetime import datetime, timedelta
import asyncpg
from ..database import get_timescale_pool
from ..cache import get_cache, set_cache
from ..queries import parse_time_range
from ..config import get_settings

router = APIRouter(prefix="/api/v1/analytics", tags=["analytics"])
settings = get_settings()


@router.get("/latency-trends")
async def get_latency_trends(
    range: str = "24h",
    granularity: str = "1h",
    department: Optional[str] = None,
    environment: Optional[str] = None,
    version: Optional[str] = None,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get latency trends over time with percentiles (P50, P95, P99).

    Returns time-series data showing how latency evolves, broken down by department if desired.

    Query Parameters:
        - range: Time range (1h, 24h, 7d, 30d) - Default: 24h
        - granularity: Time bucket size (1h, 6h, 1d) - Default: 1h
        - department: Optional department filter
        - environment: Optional environment filter
        - version: Optional version filter

    Response:
        {
            "data": [
                {
                    "timestamp": "2025-10-27T14:00:00Z",
                    "p50_latency_ms": 1250.5,
                    "p95_latency_ms": 3500.2,
                    "p99_latency_ms": 5200.8,
                    "avg_latency_ms": 1800.3,
                    "request_count": 1250
                },
                // ... more time buckets
            ],
            "meta": {
                "granularity": "1h",
                "range": "24h",
                "filters_applied": { ... }
            }
        }
    """
    # Parse time range
    range_hours = parse_time_range(range)
    if range_hours is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid time range: {range}. Valid options: 1h, 24h, 7d, 30d"
        )

    # Validate granularity
    granularity_map = {
        "1h": "1 hour",
        "6h": "6 hours",
        "1d": "1 day"
    }
    if granularity not in granularity_map:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid granularity: {granularity}. Valid options: 1h, 6h, 1d"
        )

    # Build cache key
    filter_parts = [range, granularity]
    if department:
        filter_parts.append(f"dept:{department}")
    if environment:
        filter_parts.append(f"env:{environment}")
    if version:
        filter_parts.append(f"ver:{version}")

    cache_key = f"latency_trends:{x_workspace_id}:{':'.join(filter_parts)}"
    cached = get_cache(cache_key)
    if cached:
        return cached

    # Build WHERE clause
    where_clauses = ["workspace_id = $1", "timestamp >= NOW() - INTERVAL '1 hour' * $2"]
    params = [x_workspace_id, range_hours]
    param_idx = 3

    if department:
        where_clauses.append(f"""
            department_id = (SELECT id FROM departments
                            WHERE workspace_id = $1 AND department_code = ${param_idx})
        """)
        params.append(department)
        param_idx += 1

    if environment:
        where_clauses.append(f"""
            environment_id = (SELECT id FROM environments
                             WHERE workspace_id = $1 AND environment_code = ${param_idx})
        """)
        params.append(environment)
        param_idx += 1

    if version:
        where_clauses.append(f"version = ${param_idx}")
        params.append(version)
        param_idx += 1

    where_clause = " AND ".join(where_clauses)

    query = f"""
    SELECT
        time_bucket(INTERVAL '{granularity_map[granularity]}', timestamp) AS bucket,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY latency_ms) AS p50_latency_ms,
        percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms) AS p95_latency_ms,
        percentile_cont(0.99) WITHIN GROUP (ORDER BY latency_ms) AS p99_latency_ms,
        AVG(latency_ms) AS avg_latency_ms,
        COUNT(*) AS request_count
    FROM traces
    WHERE {where_clause}
    GROUP BY bucket
    ORDER BY bucket ASC
    """

    try:
        async with timescale_pool.acquire() as conn:
            rows = await conn.fetch(query, *params)

            data_points = [
                {
                    "timestamp": row['bucket'].isoformat(),
                    "p50_latency_ms": float(row['p50_latency_ms']),
                    "p95_latency_ms": float(row['p95_latency_ms']),
                    "p99_latency_ms": float(row['p99_latency_ms']),
                    "avg_latency_ms": float(row['avg_latency_ms']),
                    "request_count": int(row['request_count'])
                }
                for row in rows
            ]

            result = {
                "data": data_points,
                "meta": {
                    "granularity": granularity,
                    "range": range,
                    "total_buckets": len(data_points),
                    "filters_applied": {
                        "department": department,
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
            detail=f"Failed to fetch latency trends: {str(e)}"
        )


@router.get("/cost-breakdown")
async def get_cost_breakdown(
    range: str = "24h",
    breakdown_by: str = "department",
    environment: Optional[str] = None,
    version: Optional[str] = None,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get cost breakdown by different dimensions.

    Allows breaking down costs by department, model, version, or environment.

    Query Parameters:
        - range: Time range (1h, 24h, 7d, 30d) - Default: 24h
        - breakdown_by: Dimension to break down by (department, model, version, environment)
        - environment: Optional environment filter
        - version: Optional version filter

    Response:
        {
            "data": [
                {
                    "dimension": "engineering",
                    "dimension_name": "Engineering",
                    "total_cost_usd": 125.50,
                    "request_count": 15000,
                    "avg_cost_per_request": 0.0083,
                    "percentage_of_total": 35.5
                },
                // ... more breakdown items
            ],
            "meta": {
                "total_cost_usd": 353.25,
                "breakdown_by": "department"
            }
        }
    """
    # Parse time range
    range_hours = parse_time_range(range)
    if range_hours is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid time range: {range}"
        )

    # Validate breakdown dimension
    valid_dimensions = ["department", "model", "version", "environment"]
    if breakdown_by not in valid_dimensions:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid breakdown_by: {breakdown_by}. Valid options: {', '.join(valid_dimensions)}"
        )

    # Build cache key
    filter_parts = [range, breakdown_by]
    if environment:
        filter_parts.append(f"env:{environment}")
    if version:
        filter_parts.append(f"ver:{version}")

    cache_key = f"cost_breakdown:{x_workspace_id}:{':'.join(filter_parts)}"
    cached = get_cache(cache_key)
    if cached:
        return cached

    # Build query based on breakdown dimension
    if breakdown_by == "department":
        dimension_select = """
            d.department_code as dimension,
            d.department_name as dimension_name
        """
        from_join = "FROM traces t JOIN departments d ON t.department_id = d.id"
        group_by = "d.department_code, d.department_name"
    elif breakdown_by == "model":
        dimension_select = """
            t.model as dimension,
            t.model as dimension_name
        """
        from_join = "FROM traces t"
        group_by = "t.model"
    elif breakdown_by == "version":
        dimension_select = """
            t.version as dimension,
            t.version as dimension_name
        """
        from_join = "FROM traces t"
        group_by = "t.version"
    else:  # environment
        dimension_select = """
            e.environment_code as dimension,
            e.environment_name as dimension_name
        """
        from_join = "FROM traces t JOIN environments e ON t.environment_id = e.id"
        group_by = "e.environment_code, e.environment_name"

    # Build WHERE clause
    where_clauses = ["t.workspace_id = $1", "t.timestamp >= NOW() - INTERVAL '1 hour' * $2"]
    params = [x_workspace_id, range_hours]
    param_idx = 3

    if environment and breakdown_by != "environment":
        where_clauses.append(f"""
            t.environment_id = (SELECT id FROM environments
                               WHERE workspace_id = $1 AND environment_code = ${param_idx})
        """)
        params.append(environment)
        param_idx += 1

    if version and breakdown_by != "version":
        where_clauses.append(f"t.version = ${param_idx}")
        params.append(version)
        param_idx += 1

    where_clause = " AND ".join(where_clauses)

    query = f"""
    WITH breakdown_data AS (
        SELECT
            {dimension_select},
            SUM(COALESCE(t.cost_usd, 0)) as total_cost_usd,
            COUNT(*) as request_count,
            AVG(COALESCE(t.cost_usd, 0)) as avg_cost_per_request
        {from_join}
        WHERE {where_clause}
        GROUP BY {group_by}
    ),
    total_calc AS (
        SELECT SUM(total_cost_usd) as grand_total
        FROM breakdown_data
    )
    SELECT
        bd.*,
        (bd.total_cost_usd / tc.grand_total * 100) as percentage_of_total
    FROM breakdown_data bd, total_calc tc
    ORDER BY bd.total_cost_usd DESC
    """

    try:
        async with timescale_pool.acquire() as conn:
            rows = await conn.fetch(query, *params)

            breakdown_items = [
                {
                    "dimension": row['dimension'],
                    "dimension_name": row['dimension_name'],
                    "total_cost_usd": float(row['total_cost_usd']),
                    "request_count": int(row['request_count']),
                    "avg_cost_per_request": float(row['avg_cost_per_request']),
                    "percentage_of_total": float(row['percentage_of_total'])
                }
                for row in rows
            ]

            total_cost = sum(item['total_cost_usd'] for item in breakdown_items)

            result = {
                "data": breakdown_items,
                "meta": {
                    "total_cost_usd": total_cost,
                    "breakdown_by": breakdown_by,
                    "total_items": len(breakdown_items),
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
            detail=f"Failed to fetch cost breakdown: {str(e)}"
        )


@router.get("/error-analysis")
async def get_error_analysis(
    range: str = "24h",
    department: Optional[str] = None,
    environment: Optional[str] = None,
    version: Optional[str] = None,
    limit: int = 20,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get error analysis with top error messages and patterns.

    Returns most common errors, their frequencies, and affected agents.

    Query Parameters:
        - range: Time range (1h, 24h, 7d, 30d) - Default: 24h
        - department: Optional department filter
        - environment: Optional environment filter
        - version: Optional version filter
        - limit: Max number of error types to return - Default: 20

    Response:
        {
            "data": [
                {
                    "error_message": "Timeout after 30s",
                    "error_count": 125,
                    "percentage_of_errors": 35.5,
                    "affected_agents": 12,
                    "first_seen": "2025-10-27T10:15:00Z",
                    "last_seen": "2025-10-27T15:45:00Z"
                },
                // ... more errors
            ],
            "meta": {
                "total_errors": 352,
                "total_requests": 15000,
                "error_rate": 2.35,
                "range": "24h"
            }
        }
    """
    # Parse time range
    range_hours = parse_time_range(range)
    if range_hours is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid time range: {range}"
        )

    # Build cache key
    filter_parts = [range, str(limit)]
    if department:
        filter_parts.append(f"dept:{department}")
    if environment:
        filter_parts.append(f"env:{environment}")
    if version:
        filter_parts.append(f"ver:{version}")

    cache_key = f"error_analysis:{x_workspace_id}:{':'.join(filter_parts)}"
    cached = get_cache(cache_key)
    if cached:
        return cached

    # Build WHERE clause
    where_clauses = [
        "workspace_id = $1",
        "timestamp >= NOW() - INTERVAL '1 hour' * $2",
        "status = 'error'"
    ]
    params = [x_workspace_id, range_hours]
    param_idx = 3

    if department:
        where_clauses.append(f"""
            department_id = (SELECT id FROM departments
                            WHERE workspace_id = $1 AND department_code = ${param_idx})
        """)
        params.append(department)
        param_idx += 1

    if environment:
        where_clauses.append(f"""
            environment_id = (SELECT id FROM environments
                             WHERE workspace_id = $1 AND environment_code = ${param_idx})
        """)
        params.append(environment)
        param_idx += 1

    if version:
        where_clauses.append(f"version = ${param_idx}")
        params.append(version)
        param_idx += 1

    where_clause = " AND ".join(where_clauses)

    # Query for error breakdown
    error_query = f"""
    WITH error_summary AS (
        SELECT
            COALESCE(error, 'Unknown error') as error_message,
            COUNT(*) as error_count,
            COUNT(DISTINCT agent_id) as affected_agents,
            MIN(timestamp) as first_seen,
            MAX(timestamp) as last_seen
        FROM traces
        WHERE {where_clause}
        GROUP BY error
        ORDER BY error_count DESC
        LIMIT ${param_idx}
    ),
    total_errors AS (
        SELECT COUNT(*) as total
        FROM traces
        WHERE {where_clause}
    )
    SELECT
        es.*,
        (es.error_count::float / te.total * 100) as percentage_of_errors
    FROM error_summary es, total_errors te
    """

    # Query for overall stats
    stats_query = f"""
    SELECT
        COUNT(*) FILTER (WHERE status = 'error') as total_errors,
        COUNT(*) as total_requests,
        (COUNT(*) FILTER (WHERE status = 'error')::float / NULLIF(COUNT(*), 0) * 100) as error_rate
    FROM traces
    WHERE workspace_id = $1
      AND timestamp >= NOW() - INTERVAL '1 hour' * $2
    """

    try:
        async with timescale_pool.acquire() as conn:
            params.append(limit)
            error_rows = await conn.fetch(error_query, *params)
            stats_row = await conn.fetchrow(stats_query, x_workspace_id, range_hours)

            errors = [
                {
                    "error_message": row['error_message'],
                    "error_count": int(row['error_count']),
                    "percentage_of_errors": float(row['percentage_of_errors']),
                    "affected_agents": int(row['affected_agents']),
                    "first_seen": row['first_seen'].isoformat(),
                    "last_seen": row['last_seen'].isoformat()
                }
                for row in error_rows
            ]

            result = {
                "data": errors,
                "meta": {
                    "total_errors": int(stats_row['total_errors']) if stats_row else 0,
                    "total_requests": int(stats_row['total_requests']) if stats_row else 0,
                    "error_rate": float(stats_row['error_rate']) if stats_row else 0.0,
                    "range": range,
                    "filters_applied": {
                        "department": department,
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
            detail=f"Failed to fetch error analysis: {str(e)}"
        )
