"""Performance Monitoring endpoints"""
from fastapi import APIRouter, HTTPException, status, Depends, Header, Query as QueryParam
from typing import Optional, List
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
