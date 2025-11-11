"""Performance Monitoring endpoints"""
from fastapi import APIRouter, HTTPException, status, Depends, Header, Query as QueryParam, Body
from typing import Optional, List
from uuid import UUID
import asyncpg
from datetime import datetime, timedelta
from ..models import (
    PerformanceOverview,
    LatencyPercentiles, LatencyPercentilesItem,
    Throughput, ThroughputItem,
    ErrorAnalysis, ErrorAnalysisItem
)
from ..database import get_timescale_pool
from ..cache import get_cache, set_cache
from ..config import get_settings
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/performance", tags=["performance"])
settings = get_settings()


def parse_time_range(range_str: str) -> int:
    """Convert range string to hours"""
    range_map = {
        "1h": 1,
        "24h": 24,
        "7d": 168,
        "30d": 720,
    }
    return range_map.get(range_str, 24)


def parse_granularity(granularity: str) -> str:
    """Convert granularity to TimescaleDB interval"""
    granularity_map = {
        "hourly": "1 hour",
        "daily": "1 day",
        "weekly": "1 week",
    }
    return granularity_map.get(granularity, "1 hour")


def get_time_filter(range_str: str) -> str:
    """Convert range string to PostgreSQL interval string"""
    range_map = {
        "1h": "1 hour",
        "24h": "24 hours",
        "7d": "7 days",
        "30d": "30 days",
    }
    return range_map.get(range_str, "24 hours")


@router.get("/overview", response_model=PerformanceOverview)
async def get_performance_overview(
    range: str = QueryParam("24h", regex="^(1h|24h|7d|30d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get performance overview metrics
    
    Returns latency percentiles (P50, P95, P99), error rate, success rate,
    and requests per second for the specified time range.
    """
    cache_key = f"performance_overview:{x_workspace_id}:{range}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return PerformanceOverview(**cached)
    
    try:
        hours = parse_time_range(range)
        
        # Query for latency percentiles and counts
        query = """
            SELECT
                percentile_cont(0.50) WITHIN GROUP (ORDER BY latency_ms) as p50,
                percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms) as p95,
                percentile_cont(0.99) WITHIN GROUP (ORDER BY latency_ms) as p99,
                AVG(latency_ms) as avg_latency,
                COUNT(*) as total_requests,
                COUNT(*) FILTER (WHERE status = 'success') as success_count,
                COUNT(*) FILTER (WHERE status = 'error') as error_count
            FROM traces
            WHERE workspace_id = $1 
                AND timestamp >= NOW() - INTERVAL '1 hour' * $2
        """
        
        result = await pool.fetchrow(query, x_workspace_id, hours)
        
        total_requests = result['total_requests']
        success_count = result['success_count']
        error_count = result['error_count']
        
        # Calculate rates
        error_rate = (error_count / max(total_requests, 1)) * 100
        success_rate = (success_count / max(total_requests, 1)) * 100
        
        # Calculate requests per second
        total_seconds = hours * 3600
        requests_per_second = total_requests / max(total_seconds, 1)
        
        response = PerformanceOverview(
            p50_latency_ms=round(float(result['p50'] or 0), 2),
            p95_latency_ms=round(float(result['p95'] or 0), 2),
            p99_latency_ms=round(float(result['p99'] or 0), 2),
            avg_latency_ms=round(float(result['avg_latency'] or 0), 2),
            error_rate=round(error_rate, 2),
            success_rate=round(success_rate, 2),
            total_requests=total_requests,
            requests_per_second=round(requests_per_second, 4)
        )
        
        # Cache for 5 minutes
        set_cache(cache_key, response.model_dump(), ttl=300)
        logger.info(f"Performance overview fetched for workspace {x_workspace_id}, range {range}")
        
        return response
        
    except Exception as e:
        logger.error(f"Error fetching performance overview: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch performance overview: {str(e)}"
        )


@router.get("/latency", response_model=LatencyPercentiles)
async def get_latency_percentiles(
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    granularity: str = QueryParam("hourly", regex="^(hourly|daily|weekly)$"),
    agent_id: Optional[str] = QueryParam(None),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get latency percentiles over time
    
    Returns P50, P95, P99, and average latency for each time bucket.
    Useful for multi-line charts showing latency trends.
    """
    cache_key = f"performance_latency:{x_workspace_id}:{range}:{granularity}:{agent_id or 'all'}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return LatencyPercentiles(**cached)
    
    try:
        hours = parse_time_range(range)
        interval = parse_granularity(granularity)
        
        # Build query with optional agent_id filter
        agent_filter = "AND agent_id = $3" if agent_id else ""
        params = [x_workspace_id, hours] + ([agent_id] if agent_id else [])
        
        query = f"""
            SELECT
                time_bucket(INTERVAL '{interval}', timestamp) as bucket,
                percentile_cont(0.50) WITHIN GROUP (ORDER BY latency_ms) as p50,
                percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms) as p95,
                percentile_cont(0.99) WITHIN GROUP (ORDER BY latency_ms) as p99,
                AVG(latency_ms) as avg_latency
            FROM traces
            WHERE workspace_id = $1 
                AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                {agent_filter}
            GROUP BY bucket
            ORDER BY bucket DESC
            LIMIT 1000
        """
        
        rows = await pool.fetch(query, *params)
        
        data = [
            LatencyPercentilesItem(
                timestamp=row['bucket'],
                p50=round(float(row['p50'] or 0), 2),
                p95=round(float(row['p95'] or 0), 2),
                p99=round(float(row['p99'] or 0), 2),
                avg=round(float(row['avg_latency'] or 0), 2)
            )
            for row in rows
        ]
        
        result = LatencyPercentiles(
            data=data,
            granularity=granularity,
            range=range
        )
        
        # Cache for 2 minutes
        set_cache(cache_key, result.model_dump(), ttl=120)
        logger.info(f"Latency percentiles fetched: {len(data)} buckets")
        
        return result
        
    except Exception as e:
        logger.error(f"Error fetching latency percentiles: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch latency percentiles: {str(e)}"
        )


@router.get("/throughput", response_model=Throughput)
async def get_throughput(
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    granularity: str = QueryParam("hourly", regex="^(hourly|daily|weekly)$"),
    agent_id: Optional[str] = QueryParam(None),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get request throughput over time
    
    Returns request counts broken down by status (success, error, timeout)
    for each time bucket. Useful for stacked area charts.
    """
    cache_key = f"performance_throughput:{x_workspace_id}:{range}:{granularity}:{agent_id or 'all'}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return Throughput(**cached)
    
    try:
        hours = parse_time_range(range)
        interval = parse_granularity(granularity)
        
        # Build query with optional agent_id filter
        agent_filter = "AND agent_id = $3" if agent_id else ""
        params = [x_workspace_id, hours] + ([agent_id] if agent_id else [])
        
        query = f"""
            SELECT
                time_bucket(INTERVAL '{interval}', timestamp) as bucket,
                COUNT(*) FILTER (WHERE status = 'success')::int as success_count,
                COUNT(*) FILTER (WHERE status = 'error')::int as error_count,
                COUNT(*) FILTER (WHERE status = 'timeout')::int as timeout_count,
                COUNT(*)::int as total_count
            FROM traces
            WHERE workspace_id = $1 
                AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                {agent_filter}
            GROUP BY bucket
            ORDER BY bucket DESC
            LIMIT 1000
        """
        
        rows = await pool.fetch(query, *params)
        
        # Parse granularity to seconds for RPS calculation
        granularity_seconds = {
            "hourly": 3600,
            "daily": 86400,
            "weekly": 604800
        }
        bucket_seconds = granularity_seconds.get(granularity, 3600)
        
        data = [
            ThroughputItem(
                timestamp=row['bucket'],
                success_count=row['success_count'],
                error_count=row['error_count'],
                timeout_count=row['timeout_count'],
                total_count=row['total_count'],
                requests_per_second=round(row['total_count'] / bucket_seconds, 4)
            )
            for row in rows
        ]
        
        result = Throughput(
            data=data,
            granularity=granularity,
            range=range
        )
        
        # Cache for 2 minutes
        set_cache(cache_key, result.model_dump(), ttl=120)
        logger.info(f"Throughput fetched: {len(data)} buckets")
        
        return result
        
    except Exception as e:
        logger.error(f"Error fetching throughput: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch throughput: {str(e)}"
        )


@router.get("/errors", response_model=ErrorAnalysis)
async def get_error_analysis(
    range: str = QueryParam("24h", regex="^(1h|24h|7d|30d)$"),
    agent_id: Optional[str] = QueryParam(None),
    limit: int = QueryParam(20, ge=1, le=100),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get error analysis

    Returns error breakdown by agent and error type, including error rates,
    counts, and sample error messages. Useful for debugging and monitoring.
    """
    cache_key = f"performance_errors:{x_workspace_id}:{range}:{agent_id or 'all'}:{limit}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return ErrorAnalysis(**cached)

    try:
        hours = parse_time_range(range)

        # Build query with optional agent_id filter
        agent_filter = "AND agent_id = $3" if agent_id else ""
        params = [x_workspace_id, hours] + ([agent_id] if agent_id else [])
        if not agent_id:
            params.append(limit)
        else:
            params.append(limit)

        # First get total requests for error rate calculation
        total_query = f"""
            SELECT
                COUNT(*)::int as total_requests,
                COUNT(*) FILTER (WHERE status = 'error')::int as total_errors
            FROM traces
            WHERE workspace_id = $1
                AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                {agent_filter}
        """

        total_result = await pool.fetchrow(total_query, *params[:-1])
        total_requests = total_result['total_requests']
        total_errors = total_result['total_errors']
        overall_error_rate = (total_errors / max(total_requests, 1)) * 100

        # Get error details by agent and type
        error_query = f"""
            WITH error_groups AS (
                SELECT
                    agent_id,
                    COALESCE(error, 'Unknown Error') as error_type,
                    COUNT(*)::int as error_count,
                    MAX(timestamp) as last_occurrence,
                    (ARRAY_AGG(error ORDER BY timestamp DESC))[1] as sample_error
                FROM traces
                WHERE workspace_id = $1
                    AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                    AND status = 'error'
                    {agent_filter}
                GROUP BY agent_id, error_type
            ),
            agent_totals AS (
                SELECT
                    agent_id,
                    COUNT(*)::int as agent_total
                FROM traces
                WHERE workspace_id = $1
                    AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                    {agent_filter}
                GROUP BY agent_id
            )
            SELECT
                e.agent_id,
                e.error_type,
                e.error_count,
                e.last_occurrence,
                e.sample_error,
                ROUND((e.error_count::numeric / NULLIF(a.agent_total, 0)) * 100, 2) as error_rate
            FROM error_groups e
            JOIN agent_totals a ON e.agent_id = a.agent_id
            ORDER BY e.error_count DESC
            LIMIT ${len(params)}
        """

        error_rows = await pool.fetch(error_query, *params)

        data = [
            ErrorAnalysisItem(
                agent_id=row['agent_id'],
                error_type=row['error_type'],
                error_count=row['error_count'],
                error_rate=float(row['error_rate'] or 0),
                last_occurrence=row['last_occurrence'],
                sample_error_message=row['sample_error'] if row['sample_error'] else None
            )
            for row in error_rows
        ]

        result = ErrorAnalysis(
            data=data,
            total_errors=total_errors,
            total_requests=total_requests,
            overall_error_rate=round(overall_error_rate, 2)
        )

        # Cache for 2 minutes
        set_cache(cache_key, result.model_dump(), ttl=120)
        logger.info(f"Error analysis fetched: {len(data)} error types")

        return result

    except Exception as e:
        logger.error(f"Error fetching error analysis: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch error analysis: {str(e)}"
        )


@router.get("/environment-parity")
async def get_environment_parity(
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Compare performance across environments (simplified MVP version)

    Returns performance metrics for each agent to identify parity issues.
    Uses agent_id as proxy for environments until Phase 1 schema is implemented.
    Includes latency percentiles, error rates, request counts, and parity scores.
    """
    cache_key = f"environment_parity:{x_workspace_id}:{range}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return cached

    try:
        hours = parse_time_range(range)

        # Use model provider as environment proxy for MVP
        query = """
            WITH env_metrics AS (
                SELECT
                    COALESCE(model_provider, 'unknown') as environment,
                    COUNT(*)::int as request_count,
                    COUNT(*) FILTER (WHERE status = 'success')::int as success_count,
                    COUNT(*) FILTER (WHERE status = 'error')::int as error_count,
                    percentile_cont(0.50) WITHIN GROUP (ORDER BY latency_ms) as p50_latency,
                    percentile_cont(0.90) WITHIN GROUP (ORDER BY latency_ms) as p90_latency,
                    percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms) as p95_latency,
                    percentile_cont(0.99) WITHIN GROUP (ORDER BY latency_ms) as p99_latency,
                    AVG(latency_ms) as avg_latency,
                    AVG(cost_usd) as avg_cost,
                    COUNT(DISTINCT agent_id) as unique_agents
                FROM traces
                WHERE workspace_id = $1
                    AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                GROUP BY model_provider
            ),
            first_baseline AS (
                SELECT
                    p50_latency as base_p50,
                    p90_latency as base_p90,
                    error_count::float / NULLIF(request_count, 0) as base_error_rate,
                    request_count as base_request_count
                FROM env_metrics
                ORDER BY request_count DESC
                LIMIT 1
            )
            SELECT
                em.environment,
                em.request_count,
                em.success_count,
                em.error_count,
                ROUND((em.error_count::float / NULLIF(em.request_count, 0))::numeric * 100, 2) as error_rate,
                ROUND(CAST(em.p50_latency AS numeric), 2) as p50_latency_ms,
                ROUND(CAST(em.p90_latency AS numeric), 2) as p90_latency_ms,
                ROUND(CAST(em.p95_latency AS numeric), 2) as p95_latency_ms,
                ROUND(CAST(em.p99_latency AS numeric), 2) as p99_latency_ms,
                ROUND(CAST(em.avg_latency AS numeric), 2) as avg_latency_ms,
                ROUND(CAST(em.avg_cost AS numeric), 6) as avg_cost_per_request,
                em.unique_agents,
                -- Parity score: compared to highest volume provider
                ROUND(
                    CAST(100.0 - (
                        LEAST(40, COALESCE(ABS(em.p90_latency - fb.base_p90) / NULLIF(fb.base_p90, 0) * 40, 0)) +
                        LEAST(40, COALESCE(ABS((em.error_count::float / NULLIF(em.request_count, 0)) - fb.base_error_rate) * 1000, 0)) +
                        LEAST(20, COALESCE(ABS(em.request_count - fb.base_request_count) / NULLIF(fb.base_request_count, 0) * 20, 0))
                    ) AS numeric),
                    2
                ) as parity_score
            FROM env_metrics em
            CROSS JOIN first_baseline fb
            ORDER BY em.request_count DESC
        """

        rows = await pool.fetch(query, x_workspace_id, hours)

        data = []
        for row in rows:
            data.append({
                'environment': row['environment'],
                'request_count': row['request_count'],
                'success_count': row['success_count'],
                'error_count': row['error_count'],
                'error_rate': float(row['error_rate'] or 0),
                'p50_latency_ms': float(row['p50_latency_ms'] or 0),
                'p90_latency_ms': float(row['p90_latency_ms'] or 0),
                'p95_latency_ms': float(row['p95_latency_ms'] or 0),
                'p99_latency_ms': float(row['p99_latency_ms'] or 0),
                'avg_latency_ms': float(row['avg_latency_ms'] or 0),
                'avg_cost_per_request': float(row['avg_cost_per_request'] or 0),
                'unique_agents': row['unique_agents'],
                'parity_score': float(row['parity_score'] or 0)
            })

        result = {
            'data': data,
            'meta': {
                'range': range,
                'total_environments': len(data)
            }
        }

        # Cache for 5 minutes
        set_cache(cache_key, result, ttl=300)
        logger.info(f"Environment parity fetched: {len(data)} environments")

        return result

    except Exception as e:
        logger.error(f"Error fetching environment parity: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch environment parity: {str(e)}"
        )


@router.get("/version-comparison")
async def get_version_comparison(
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Compare performance across models (simplified MVP version)

    Returns performance metrics for each model to identify improvements or regressions.
    Uses model as version proxy until Phase 1 schema is implemented.
    Includes latency percentiles, error rates, request counts, and trend indicators.
    """
    cache_key = f"version_comparison:{x_workspace_id}:{range}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return cached

    try:
        hours = parse_time_range(range)

        # Use model as version proxy for MVP
        query = """
            WITH version_metrics AS (
                SELECT
                    COALESCE(model, 'unknown') as version,
                    COUNT(*)::int as request_count,
                    COUNT(*) FILTER (WHERE status = 'success')::int as success_count,
                    COUNT(*) FILTER (WHERE status = 'error')::int as error_count,
                    percentile_cont(0.50) WITHIN GROUP (ORDER BY latency_ms) as p50_latency,
                    percentile_cont(0.90) WITHIN GROUP (ORDER BY latency_ms) as p90_latency,
                    percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms) as p95_latency,
                    percentile_cont(0.99) WITHIN GROUP (ORDER BY latency_ms) as p99_latency,
                    AVG(latency_ms) as avg_latency,
                    AVG(cost_usd) as avg_cost,
                    COUNT(DISTINCT agent_id) as unique_agents,
                    MIN(timestamp) as first_seen,
                    MAX(timestamp) as last_seen
                FROM traces
                WHERE workspace_id = $1
                    AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                GROUP BY model
            ),
            prev_period AS (
                SELECT
                    COALESCE(model, 'unknown') as version,
                    percentile_cont(0.90) WITHIN GROUP (ORDER BY latency_ms) as prev_p90_latency,
                    COUNT(*) FILTER (WHERE status = 'error')::float / NULLIF(COUNT(*), 0) as prev_error_rate
                FROM traces
                WHERE workspace_id = $1
                    AND timestamp >= NOW() - INTERVAL '1 hour' * ($2 * 2)
                    AND timestamp < NOW() - INTERVAL '1 hour' * $2
                GROUP BY model
            )
            SELECT
                vm.version,
                vm.request_count,
                vm.success_count,
                vm.error_count,
                ROUND((vm.error_count::float / NULLIF(vm.request_count, 0))::numeric * 100, 2) as error_rate,
                ROUND(CAST(vm.p50_latency AS numeric), 2) as p50_latency_ms,
                ROUND(CAST(vm.p90_latency AS numeric), 2) as p90_latency_ms,
                ROUND(CAST(vm.p95_latency AS numeric), 2) as p95_latency_ms,
                ROUND(CAST(vm.p99_latency AS numeric), 2) as p99_latency_ms,
                ROUND(CAST(vm.avg_latency AS numeric), 2) as avg_latency_ms,
                ROUND(CAST(vm.avg_cost AS numeric), 6) as avg_cost_per_request,
                vm.unique_agents,
                vm.first_seen,
                vm.last_seen,
                -- Performance trend vs previous period
                CASE
                    WHEN pp.prev_p90_latency IS NULL THEN 'new'
                    WHEN vm.p90_latency < pp.prev_p90_latency * 0.9 THEN 'improving'
                    WHEN vm.p90_latency > pp.prev_p90_latency * 1.1 THEN 'degrading'
                    ELSE 'stable'
                END as performance_trend,
                -- Latency improvement percentage
                CASE
                    WHEN pp.prev_p90_latency > 0 THEN
                        ROUND(CAST(((vm.p90_latency - pp.prev_p90_latency) / pp.prev_p90_latency) * 100 AS numeric), 2)
                    ELSE NULL
                END as latency_change_pct,
                -- Error rate change
                CASE
                    WHEN pp.prev_error_rate > 0 THEN
                        ROUND(CAST((((vm.error_count::float / NULLIF(vm.request_count, 0)) - pp.prev_error_rate) / pp.prev_error_rate) * 100 AS numeric), 2)
                    ELSE NULL
                END as error_rate_change_pct
            FROM version_metrics vm
            LEFT JOIN prev_period pp ON vm.version = pp.version
            ORDER BY vm.request_count DESC
        """

        rows = await pool.fetch(query, x_workspace_id, hours)

        data = []
        for row in rows:
            data.append({
                'version': row['version'],
                'request_count': row['request_count'],
                'success_count': row['success_count'],
                'error_count': row['error_count'],
                'error_rate': float(row['error_rate'] or 0),
                'p50_latency_ms': float(row['p50_latency_ms'] or 0),
                'p90_latency_ms': float(row['p90_latency_ms'] or 0),
                'p95_latency_ms': float(row['p95_latency_ms'] or 0),
                'p99_latency_ms': float(row['p99_latency_ms'] or 0),
                'avg_latency_ms': float(row['avg_latency_ms'] or 0),
                'avg_cost_per_request': float(row['avg_cost_per_request'] or 0),
                'unique_agents': row['unique_agents'],
                'first_seen': row['first_seen'],
                'last_seen': row['last_seen'],
                'performance_trend': row['performance_trend'],
                'latency_change_pct': float(row['latency_change_pct']) if row['latency_change_pct'] is not None else None,
                'error_rate_change_pct': float(row['error_rate_change_pct']) if row['error_rate_change_pct'] is not None else None
            })

        result = {
            'data': data,
            'meta': {
                'range': range,
                'total_versions': len(data)
            }
        }

        # Cache for 5 minutes
        set_cache(cache_key, result, ttl=300)
        logger.info(f"Version comparison fetched: {len(data)} versions")

        return result

    except Exception as e:
        logger.error(f"Error fetching version comparison: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch version comparison: {str(e)}"
        )

# =============================================================================
# P0 PERFORMANCE ENDPOINTS (Phase 5)
# =============================================================================

@router.get("/slo-compliance")
async def get_slo_compliance(
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get SLO compliance status for all agents
    
    Returns grid showing each agent's SLO compliance (P50/P90/P95/P99 latency, error rate)
    with color-coded status (green >99%, yellow 95-99%, red <95%)
    """
    cache_key = f"performance_slo_compliance:{x_workspace_id}:{range}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return cached
    
    try:
        hours = parse_time_range(range)
        
        query = """
            WITH agent_metrics AS (
                SELECT
                    t.agent_id,
                    percentile_cont(0.50) WITHIN GROUP (ORDER BY t.latency_ms) as actual_p50,
                    percentile_cont(0.90) WITHIN GROUP (ORDER BY t.latency_ms) as actual_p90,
                    percentile_cont(0.95) WITHIN GROUP (ORDER BY t.latency_ms) as actual_p95,
                    percentile_cont(0.99) WITHIN GROUP (ORDER BY t.latency_ms) as actual_p99,
                    (COUNT(*) FILTER (WHERE t.status = 'error')::DECIMAL / NULLIF(COUNT(*), 0) * 100) as actual_error_rate,
                    COUNT(*) as request_count
                FROM traces t
                WHERE t.workspace_id = $1 
                    AND t.timestamp >= NOW() - INTERVAL '1 hour' * $2
                GROUP BY t.agent_id
            )
            SELECT
                am.agent_id,
                sc.p50_latency_target_ms,
                sc.p90_latency_target_ms,
                sc.p95_latency_target_ms,
                sc.p99_latency_target_ms,
                sc.error_rate_target_pct,
                am.actual_p50,
                am.actual_p90,
                am.actual_p95,
                am.actual_p99,
                am.actual_error_rate,
                am.request_count,
                (am.actual_p50 <= sc.p50_latency_target_ms) as p50_compliant,
                (am.actual_p90 <= sc.p90_latency_target_ms) as p90_compliant,
                (am.actual_p95 <= sc.p95_latency_target_ms) as p95_compliant,
                (am.actual_p99 <= sc.p99_latency_target_ms) as p99_compliant,
                (am.actual_error_rate <= sc.error_rate_target_pct) as error_rate_compliant
            FROM agent_metrics am
            LEFT JOIN slo_configs sc ON sc.agent_id = am.agent_id AND sc.workspace_id = $1 AND sc.is_active = true
            WHERE sc.id IS NOT NULL
            ORDER BY am.agent_id
        """
        
        rows = await pool.fetch(query, x_workspace_id, hours)
        
        data = []
        for row in rows:
            # Calculate overall compliance (percentage of SLOs met)
            compliant_count = sum([
                row['p50_compliant'],
                row['p90_compliant'],
                row['p95_compliant'],
                row['p99_compliant'],
                row['error_rate_compliant']
            ])
            overall_compliance_pct = (compliant_count / 5.0) * 100
            
            # Determine status
            if overall_compliance_pct >= 99:
                status = 'excellent'
            elif overall_compliance_pct >= 95:
                status = 'good'
            elif overall_compliance_pct >= 80:
                status = 'warning'
            else:
                status = 'critical'
            
            data.append({
                'agent_id': row['agent_id'],
                'slo_targets': {
                    'p50_ms': row['p50_latency_target_ms'],
                    'p90_ms': row['p90_latency_target_ms'],
                    'p95_ms': row['p95_latency_target_ms'],
                    'p99_ms': row['p99_latency_target_ms'],
                    'error_rate_pct': float(row['error_rate_target_pct'])
                },
                'actual_metrics': {
                    'p50_ms': round(float(row['actual_p50']), 2),
                    'p90_ms': round(float(row['actual_p90']), 2),
                    'p95_ms': round(float(row['actual_p95']), 2),
                    'p99_ms': round(float(row['actual_p99']), 2),
                    'error_rate_pct': round(float(row['actual_error_rate'] or 0), 2)
                },
                'compliance': {
                    'p50': row['p50_compliant'],
                    'p90': row['p90_compliant'],
                    'p95': row['p95_compliant'],
                    'p99': row['p99_compliant'],
                    'error_rate': row['error_rate_compliant'],
                    'overall_pct': round(overall_compliance_pct, 2)
                },
                'status': status,
                'request_count': row['request_count']
            })
        
        result = {
            'data': data,
            'meta': {
                'range': range,
                'total_agents': len(data),
                'compliant_agents': sum(1 for d in data if d['status'] in ['excellent', 'good'])
            }
        }
        
        # Cache for 3 minutes
        set_cache(cache_key, result, ttl=180)
        logger.info(f"SLO compliance fetched: {len(data)} agents")
        
        return result
        
    except Exception as e:
        logger.error(f"Error fetching SLO compliance: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch SLO compliance: {str(e)}"
        )


@router.get("/latency-heatmap")
async def get_latency_heatmap(
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    granularity: str = QueryParam("hourly", regex="^(hourly|daily)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get latency heatmap data showing P50-P99 distribution over time
    
    Returns time-series data for heatmap visualization with percentiles as rows
    and time buckets as columns. Color intensity indicates latency severity.
    """
    cache_key = f"performance_latency_heatmap:{x_workspace_id}:{range}:{granularity}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return cached
    
    try:
        hours = parse_time_range(range)
        interval = parse_granularity(granularity)
        
        query = f"""
            SELECT
                time_bucket(INTERVAL '{interval}', timestamp) as bucket,
                percentile_cont(0.50) WITHIN GROUP (ORDER BY latency_ms) as p50,
                percentile_cont(0.75) WITHIN GROUP (ORDER BY latency_ms) as p75,
                percentile_cont(0.90) WITHIN GROUP (ORDER BY latency_ms) as p90,
                percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms) as p95,
                percentile_cont(0.99) WITHIN GROUP (ORDER BY latency_ms) as p99,
                COUNT(*) as request_count
            FROM traces
            WHERE workspace_id = $1 
                AND timestamp >= NOW() - INTERVAL '1 hour' * $2
            GROUP BY bucket
            ORDER BY bucket
        """
        
        rows = await pool.fetch(query, x_workspace_id, hours)
        
        data = []
        for row in rows:
            data.append({
                'timestamp': row['bucket'].isoformat(),
                'percentiles': {
                    'p50': round(float(row['p50']), 2),
                    'p75': round(float(row['p75']), 2),
                    'p90': round(float(row['p90']), 2),
                    'p95': round(float(row['p95']), 2),
                    'p99': round(float(row['p99']), 2)
                },
                'request_count': row['request_count']
            })
        
        result = {
            'data': data,
            'meta': {
                'range': range,
                'granularity': granularity,
                'buckets': len(data)
            }
        }
        
        # Cache for 5 minutes
        set_cache(cache_key, result, ttl=300)
        logger.info(f"Latency heatmap fetched: {len(data)} time buckets")
        
        return result
        
    except Exception as e:
        logger.error(f"Error fetching latency heatmap: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch latency heatmap: {str(e)}"
        )


@router.get("/dependency-breakdown")
async def get_dependency_breakdown(
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    agent_id: Optional[str] = QueryParam(None),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get latency breakdown by execution phase (waterfall chart data)
    
    Returns average latency for each phase: auth, preprocessing, LLM call, 
    postprocessing, and tool use. Identifies bottlenecks in execution pipeline.
    """
    cache_key = f"performance_dependency_breakdown:{x_workspace_id}:{range}:{agent_id or 'all'}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return cached
    
    try:
        hours = parse_time_range(range)
        
        # Build query with optional agent_id filter
        agent_filter = "AND agent_id = $3" if agent_id else ""
        params = [x_workspace_id, hours] + ([agent_id] if agent_id else [])
        
        query = f"""
            SELECT
                AVG((phase_timing->>'auth_ms')::int) as avg_auth_ms,
                AVG((phase_timing->>'preprocessing_ms')::int) as avg_preprocessing_ms,
                AVG((phase_timing->>'llm_call_ms')::int) as avg_llm_call_ms,
                AVG((phase_timing->>'postprocessing_ms')::int) as avg_postprocessing_ms,
                AVG((phase_timing->>'tool_use_ms')::int) as avg_tool_use_ms,
                COUNT(*) as request_count
            FROM traces
            WHERE workspace_id = $1 
                AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                AND phase_timing IS NOT NULL
                {agent_filter}
        """
        
        row = await pool.fetchrow(query, *params)
        
        if not row or row['request_count'] == 0:
            return {
                'data': [],
                'meta': {'range': range, 'agent_id': agent_id, 'request_count': 0}
            }
        
        phases = [
            {'phase': 'Authentication', 'avg_latency_ms': round(float(row['avg_auth_ms'] or 0), 2)},
            {'phase': 'Preprocessing', 'avg_latency_ms': round(float(row['avg_preprocessing_ms'] or 0), 2)},
            {'phase': 'LLM Call', 'avg_latency_ms': round(float(row['avg_llm_call_ms'] or 0), 2)},
            {'phase': 'Postprocessing', 'avg_latency_ms': round(float(row['avg_postprocessing_ms'] or 0), 2)},
            {'phase': 'Tool Use', 'avg_latency_ms': round(float(row['avg_tool_use_ms'] or 0), 2)}
        ]
        
        total_latency = sum(p['avg_latency_ms'] for p in phases)
        
        for phase in phases:
            phase['percentage'] = round((phase['avg_latency_ms'] / max(total_latency, 1)) * 100, 2)
        
        result = {
            'data': phases,
            'meta': {
                'range': range,
                'agent_id': agent_id,
                'request_count': row['request_count'],
                'total_avg_latency_ms': round(total_latency, 2)
            }
        }
        
        # Cache for 5 minutes
        set_cache(cache_key, result, ttl=300)
        logger.info(f"Dependency breakdown fetched for {agent_id or 'all agents'}")
        
        return result
        
    except Exception as e:
        logger.error(f"Error fetching dependency breakdown: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch dependency breakdown: {str(e)}"
        )


# ============================================================================
# P0 ACTION APIS
# ============================================================================

@router.post("/slo")
async def create_slo(
    agent_id: str = Body(...),
    p50_ms: int = Body(...),
    p90_ms: int = Body(...),
    p95_ms: int = Body(...),
    p99_ms: int = Body(...),
    error_rate_pct: float = Body(...),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    P0 Action: Create or update SLO configuration for an agent
    """
    try:
        # Validate percentile ordering
        if not (p50_ms < p90_ms < p95_ms < p99_ms):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="SLO targets must be in ascending order: P50 < P90 < P95 < P99"
            )

        query = """
            INSERT INTO slo_configs (
                workspace_id, agent_id,
                p50_latency_target_ms, p90_latency_target_ms,
                p95_latency_target_ms, p99_latency_target_ms,
                error_rate_target_pct, is_active, alert_on_violation
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, true, true)
            ON CONFLICT (workspace_id, agent_id)
            DO UPDATE SET
                p50_latency_target_ms = EXCLUDED.p50_latency_target_ms,
                p90_latency_target_ms = EXCLUDED.p90_latency_target_ms,
                p95_latency_target_ms = EXCLUDED.p95_latency_target_ms,
                p99_latency_target_ms = EXCLUDED.p99_latency_target_ms,
                error_rate_target_pct = EXCLUDED.error_rate_target_pct,
                updated_at = NOW()
            RETURNING id, agent_id, p50_latency_target_ms, p90_latency_target_ms,
                      p95_latency_target_ms, p99_latency_target_ms, error_rate_target_pct
        """

        async with pool.acquire() as conn:
            result = await conn.fetchrow(
                query,
                UUID(x_workspace_id), agent_id,
                p50_ms, p90_ms, p95_ms, p99_ms, error_rate_pct
            )

        logger.info(f"SLO created/updated for agent {agent_id}")

        return {
            "success": True,
            "message": f"SLO configured for agent {agent_id}",
            "slo": {
                "id": str(result['id']),
                "agent_id": result['agent_id'],
                "targets": {
                    "p50_ms": result['p50_latency_target_ms'],
                    "p90_ms": result['p90_latency_target_ms'],
                    "p95_ms": result['p95_latency_target_ms'],
                    "p99_ms": result['p99_latency_target_ms'],
                    "error_rate_pct": float(result['error_rate_target_pct'])
                }
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating SLO: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create SLO: {str(e)}"
        )


@router.post("/profile")
async def trigger_profiling(
    agent_id: str = Body(...),
    duration_hours: int = Body(1),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    P0 Action: Enable detailed performance profiling for specific agent
    """
    try:
        if duration_hours not in [1, 2, 4, 8]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Duration must be 1, 2, 4, or 8 hours"
            )

        # Create profiling session (mock implementation - would integrate with actual profiler)
        profiling_id = str(uuid4())
        end_time = datetime.utcnow() + timedelta(hours=duration_hours)

        query = """
            INSERT INTO performance_events (
                workspace_id, event_type, timestamp,
                affected_agents, description, metadata, status
            )
            VALUES ($1, 'profiling', NOW(), $2, $3, $4, 'active')
            RETURNING id
        """

        metadata = {
            "profiling_id": profiling_id,
            "duration_hours": duration_hours,
            "end_time": end_time.isoformat(),
            "overhead_pct": "5-10"
        }

        async with pool.acquire() as conn:
            result = await conn.fetchrow(
                query,
                UUID(x_workspace_id),
                [agent_id],
                f"Performance profiling enabled for {agent_id} ({duration_hours}h)",
                json.dumps(metadata)
            )

        logger.info(f"Profiling triggered for agent {agent_id}, duration: {duration_hours}h")

        return {
            "success": True,
            "message": f"Profiling enabled for {duration_hours} hour(s)",
            "profiling_session": {
                "id": profiling_id,
                "agent_id": agent_id,
                "duration_hours": duration_hours,
                "start_time": datetime.utcnow().isoformat(),
                "end_time": end_time.isoformat(),
                "overhead": "5-10%",
                "status": "active"
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error triggering profiling: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to trigger profiling: {str(e)}"
        )


@router.post("/alerts")
async def create_performance_alert(
    agent_id: str = Body(...),
    metric_type: str = Body(...),  # "p95_latency" | "error_rate"
    threshold: float = Body(...),
    channel: str = Body("email"),  # "email" | "slack"
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    P0 Action: Create performance alert for agent
    """
    try:
        valid_metrics = ["p50_latency", "p90_latency", "p95_latency", "p99_latency", "error_rate"]
        if metric_type not in valid_metrics:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid metric type. Must be one of: {valid_metrics}"
            )

        # Create alert event
        alert_id = str(uuid4())

        query = """
            INSERT INTO performance_events (
                workspace_id, event_type, timestamp,
                affected_agents, description, metadata, status
            )
            VALUES ($1, 'alert_created', NOW(), $2, $3, $4, 'active')
            RETURNING id
        """

        metadata = {
            "alert_id": alert_id,
            "metric_type": metric_type,
            "threshold": threshold,
            "channel": channel,
            "agent_id": agent_id
        }

        description = f"Alert created: {metric_type} > {threshold} for {agent_id}"

        async with pool.acquire() as conn:
            result = await conn.fetchrow(
                query,
                UUID(x_workspace_id),
                [agent_id],
                description,
                json.dumps(metadata)
            )

        logger.info(f"Alert created for agent {agent_id}: {metric_type} > {threshold}")

        return {
            "success": True,
            "message": f"Alert created for {agent_id}",
            "alert": {
                "id": alert_id,
                "agent_id": agent_id,
                "metric_type": metric_type,
                "threshold": threshold,
                "channel": channel,
                "status": "active",
                "created_at": datetime.utcnow().isoformat()
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating alert: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create alert: {str(e)}"
        )


@router.post("/regression")
async def flag_performance_regression(
    version: str = Body(...),
    agent_ids: List[str] = Body(...),
    impact_pct: float = Body(...),
    notes: str = Body(""),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    P0 Action: Flag version as performance regression
    """
    try:
        query = """
            INSERT INTO performance_events (
                workspace_id, event_type, timestamp,
                version_after, affected_agents,
                impact_on_latency_pct, description,
                metadata, status
            )
            VALUES ($1, 'regression', NOW(), $2, $3, $4, $5, $6, 'detected')
            RETURNING id, timestamp
        """

        description = f"Performance regression detected in {version}: +{impact_pct}% latency impact"
        metadata = {
            "version": version,
            "agent_count": len(agent_ids),
            "impact_pct": impact_pct,
            "notes": notes,
            "flagged_by": "manual"
        }

        async with pool.acquire() as conn:
            result = await conn.fetchrow(
                query,
                UUID(x_workspace_id),
                version,
                agent_ids,
                impact_pct,
                description,
                json.dumps(metadata)
            )

        logger.info(f"Regression flagged for version {version}, impact: +{impact_pct}%")

        return {
            "success": True,
            "message": f"Regression flagged for version {version}",
            "regression": {
                "id": str(result['id']),
                "version": version,
                "affected_agents": agent_ids,
                "impact_pct": impact_pct,
                "notes": notes,
                "status": "detected",
                "flagged_at": result['timestamp'].isoformat()
            }
        }

    except Exception as e:
        logger.error(f"Error flagging regression: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to flag regression: {str(e)}"
        )


# ============================================================================
# AGENT DETAIL API
# ============================================================================

@router.get("/agents/{agent_id}")
async def get_agent_detail(
    agent_id: str,
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get detailed performance metrics for specific agent
    """
    try:
        time_filter = get_time_filter(range)

        # Fetch agent metrics
        # Get time range in seconds for requests_per_second calculation
        time_range_seconds = {
            "1h": 3600,
            "24h": 86400,
            "7d": 604800,
            "30d": 2592000
        }.get(range, 86400)

        metrics_query = f"""
            SELECT
                agent_id,
                percentile_cont(0.50) WITHIN GROUP (ORDER BY latency_ms) as p50_ms,
                percentile_cont(0.90) WITHIN GROUP (ORDER BY latency_ms) as p90_ms,
                percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms) as p95_ms,
                percentile_cont(0.99) WITHIN GROUP (ORDER BY latency_ms) as p99_ms,
                AVG(latency_ms) as avg_ms,
                COUNT(*) as total_requests,
                SUM(CASE WHEN status = 'error' OR status = 'timeout' THEN 1 ELSE 0 END) as error_count,
                (SUM(CASE WHEN status = 'error' OR status = 'timeout' THEN 1 ELSE 0 END)::FLOAT / COUNT(*)::FLOAT * 100) as error_rate_pct,
                (COUNT(*) - SUM(CASE WHEN status = 'error' OR status = 'timeout' THEN 1 ELSE 0 END))::FLOAT / COUNT(*)::FLOAT * 100 as success_rate_pct
            FROM traces
            WHERE workspace_id = $1
                AND agent_id = $2
                AND timestamp >= NOW() - INTERVAL '{time_filter}'
            GROUP BY agent_id
        """

        # Fetch recent traces
        traces_query = f"""
            SELECT
                trace_id,
                timestamp,
                latency_ms,
                status,
                version,
                model_provider
            FROM traces
            WHERE workspace_id = $1
                AND agent_id = $2
                AND timestamp >= NOW() - INTERVAL '{time_filter}'
            ORDER BY timestamp DESC
            LIMIT 50
        """

        # Fetch SLO config
        slo_query = """
            SELECT p50_latency_target_ms, p90_latency_target_ms,
                   p95_latency_target_ms, p99_latency_target_ms,
                   error_rate_target_pct
            FROM slo_configs
            WHERE workspace_id = $1 AND agent_id = $2 AND is_active = true
        """

        async with pool.acquire() as conn:
            metrics = await conn.fetchrow(metrics_query, UUID(x_workspace_id), agent_id)
            traces = await conn.fetch(traces_query, UUID(x_workspace_id), agent_id)
            slo = await conn.fetchrow(slo_query, UUID(x_workspace_id), agent_id)

        if not metrics:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"No data found for agent {agent_id}"
            )

        result = {
            "agent_id": agent_id,
            "range": range,
            "metrics": {
                "p50_ms": round(metrics['p50_ms'], 2) if metrics['p50_ms'] else 0,
                "p90_ms": round(metrics['p90_ms'], 2) if metrics['p90_ms'] else 0,
                "p95_ms": round(metrics['p95_ms'], 2) if metrics['p95_ms'] else 0,
                "p99_ms": round(metrics['p99_ms'], 2) if metrics['p99_ms'] else 0,
                "avg_latency_ms": round(metrics['avg_ms'], 2) if metrics['avg_ms'] else 0,
                "error_rate_pct": round(metrics['error_rate_pct'], 2) if metrics['error_rate_pct'] else 0,
                "success_rate_pct": round(metrics['success_rate_pct'], 2) if metrics['success_rate_pct'] else 0,
                "request_count": metrics['total_requests'],
                "requests_per_second": round(metrics['total_requests'] / time_range_seconds, 2)
            },
            "slo_config": {
                "p50_ms": slo['p50_latency_target_ms'] if slo else None,
                "p90_ms": slo['p90_latency_target_ms'] if slo else None,
                "p95_ms": slo['p95_latency_target_ms'] if slo else None,
                "p99_ms": slo['p99_latency_target_ms'] if slo else None,
                "error_rate_pct": float(slo['error_rate_target_pct']) if slo else None
            } if slo else None,
            "recent_traces": [
                {
                    "trace_id": str(t['trace_id']),
                    "timestamp": t['timestamp'].isoformat(),
                    "latency_ms": t['latency_ms'],
                    "status": t['status'],
                    "error_message": None  # Add error_message field (currently not in DB)
                }
                for t in traces
            ]
        }

        logger.info(f"Agent detail fetched for {agent_id}")
        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching agent detail: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch agent detail: {str(e)}"
        )
