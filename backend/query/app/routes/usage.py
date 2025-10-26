"""Usage Analytics endpoints"""
from fastapi import APIRouter, HTTPException, status, Depends, Header, Query as QueryParam
from typing import Optional, List
import asyncpg
from datetime import datetime, timedelta
from ..models import (
    UsageOverview, ChangeMetrics, 
    CallsOverTime, CallsOverTimeItem,
    AgentDistribution, AgentDistributionItem,
    TopUsers, TopUsersItem
)
from ..database import get_timescale_pool
from ..cache import get_cache, set_cache
from ..config import get_settings
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/usage", tags=["usage"])
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


@router.get("/overview", response_model=UsageOverview)
async def get_usage_overview(
    range: str = QueryParam("24h", regex="^(1h|24h|7d|30d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get usage overview metrics
    
    Returns total calls, unique users, active agents, and average calls per user
    with percentage changes from the previous period.
    """
    cache_key = f"usage_overview:{x_workspace_id}:{range}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return UsageOverview(**cached)
    
    try:
        hours = parse_time_range(range)
        
        # Current period query
        current_query = """
            SELECT
                COUNT(*)::int as total_calls,
                COUNT(DISTINCT user_id)::int as unique_users,
                COUNT(DISTINCT agent_id)::int as active_agents,
                ROUND(COUNT(*)::numeric / NULLIF(COUNT(DISTINCT user_id), 0), 2) as avg_calls_per_user
            FROM traces
            WHERE workspace_id = $1 
                AND timestamp >= NOW() - INTERVAL '1 hour' * $2
        """
        
        # Previous period query
        previous_query = """
            SELECT
                COUNT(*)::int as total_calls,
                COUNT(DISTINCT user_id)::int as unique_users,
                COUNT(DISTINCT agent_id)::int as active_agents
            FROM traces
            WHERE workspace_id = $1 
                AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                AND timestamp < NOW() - INTERVAL '1 hour' * $3
        """
        
        current = await pool.fetchrow(current_query, x_workspace_id, hours)
        previous = await pool.fetchrow(previous_query, x_workspace_id, hours * 2, hours)
        
        # Calculate percentage changes
        def calc_change(current_val, prev_val):
            if prev_val == 0:
                return 0.0
            return round(((current_val - prev_val) / prev_val) * 100, 2)
        
        change_metrics = ChangeMetrics(
            total_calls=calc_change(current['total_calls'], previous['total_calls']),
            unique_users=calc_change(current['unique_users'], previous['unique_users']),
            active_agents=calc_change(current['active_agents'], previous['active_agents'])
        )
        
        result = UsageOverview(
            total_calls=current['total_calls'],
            unique_users=current['unique_users'],
            active_agents=current['active_agents'],
            avg_calls_per_user=float(current['avg_calls_per_user'] or 0),
            change_from_previous=change_metrics
        )
        
        # Cache for 5 minutes
        set_cache(cache_key, result.model_dump(), ttl=300)
        logger.info(f"Usage overview fetched for workspace {x_workspace_id}, range {range}")
        
        return result
        
    except Exception as e:
        logger.error(f"Error fetching usage overview: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch usage overview: {str(e)}"
        )


@router.get("/calls-over-time", response_model=CallsOverTime)
async def get_calls_over_time(
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    granularity: str = QueryParam("hourly", regex="^(hourly|daily|weekly)$"),
    agent_id: Optional[str] = QueryParam(None),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get API calls over time with time-bucket aggregation
    
    Returns time-series data showing call count, average latency, and total cost
    grouped by the specified granularity.
    """
    cache_key = f"usage_calls_over_time:{x_workspace_id}:{range}:{granularity}:{agent_id or 'all'}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return CallsOverTime(**cached)
    
    try:
        hours = parse_time_range(range)
        interval = parse_granularity(granularity)
        
        # Build query with optional agent_id filter
        agent_filter = "AND agent_id = $3" if agent_id else ""
        params = [x_workspace_id, hours] + ([agent_id] if agent_id else [])
        
        query = f"""
            SELECT
                time_bucket(INTERVAL '{interval}', timestamp) as bucket,
                agent_id,
                COUNT(*)::int as call_count,
                ROUND(AVG(latency_ms)::numeric, 2) as avg_latency_ms,
                ROUND(COALESCE(SUM(cost_usd), 0)::numeric, 4) as total_cost_usd
            FROM traces
            WHERE workspace_id = $1 
                AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                {agent_filter}
            GROUP BY bucket, agent_id
            ORDER BY bucket DESC
            LIMIT 1000
        """
        
        rows = await pool.fetch(query, *params)
        
        data = [
            CallsOverTimeItem(
                timestamp=row['bucket'],
                agent_id=row['agent_id'],
                call_count=row['call_count'],
                avg_latency_ms=float(row['avg_latency_ms']),
                total_cost_usd=float(row['total_cost_usd'])
            )
            for row in rows
        ]
        
        result = CallsOverTime(
            data=data,
            granularity=granularity,
            range=range
        )
        
        # Cache for 2 minutes
        set_cache(cache_key, result.model_dump(), ttl=120)
        logger.info(f"Calls over time fetched: {len(data)} buckets")
        
        return result
        
    except Exception as e:
        logger.error(f"Error fetching calls over time: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch calls over time: {str(e)}"
        )


@router.get("/agent-distribution", response_model=AgentDistribution)
async def get_agent_distribution(
    range: str = QueryParam("24h", regex="^(1h|24h|7d|30d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get distribution of API calls by agent
    
    Returns percentage breakdown, average latency, and error rate for each agent.
    """
    cache_key = f"usage_agent_distribution:{x_workspace_id}:{range}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return AgentDistribution(**cached)
    
    try:
        hours = parse_time_range(range)
        
        query = """
            WITH agent_stats AS (
                SELECT
                    agent_id,
                    COUNT(*)::int as call_count,
                    ROUND(AVG(latency_ms)::numeric, 2) as avg_latency_ms,
                    COUNT(*) FILTER (WHERE status = 'error')::int as error_count
                FROM traces
                WHERE workspace_id = $1 
                    AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                GROUP BY agent_id
            ),
            total_calls AS (
                SELECT SUM(call_count)::int as total FROM agent_stats
            )
            SELECT
                a.agent_id,
                a.call_count,
                ROUND((a.call_count::numeric / NULLIF(t.total, 0)) * 100, 2) as percentage,
                a.avg_latency_ms,
                ROUND((a.error_count::numeric / NULLIF(a.call_count, 0)) * 100, 2) as error_rate
            FROM agent_stats a
            CROSS JOIN total_calls t
            ORDER BY a.call_count DESC
            LIMIT 100
        """
        
        rows = await pool.fetch(query, x_workspace_id, hours)
        total_calls = sum(row['call_count'] for row in rows)
        
        data = [
            AgentDistributionItem(
                agent_id=row['agent_id'],
                call_count=row['call_count'],
                percentage=float(row['percentage']),
                avg_latency_ms=float(row['avg_latency_ms']),
                error_rate=float(row['error_rate'] or 0)
            )
            for row in rows
        ]
        
        result = AgentDistribution(
            data=data,
            total_calls=total_calls
        )
        
        # Cache for 5 minutes
        set_cache(cache_key, result.model_dump(), ttl=300)
        logger.info(f"Agent distribution fetched: {len(data)} agents")
        
        return result
        
    except Exception as e:
        logger.error(f"Error fetching agent distribution: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch agent distribution: {str(e)}"
        )


@router.get("/top-users", response_model=TopUsers)
async def get_top_users(
    range: str = QueryParam("24h", regex="^(1h|24h|7d|30d)$"),
    limit: int = QueryParam(10, ge=1, le=100),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get top users by API call volume
    
    Returns most active users with total calls, agents used, last active time,
    and trend compared to previous period.
    """
    cache_key = f"usage_top_users:{x_workspace_id}:{range}:{limit}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return TopUsers(**cached)
    
    try:
        hours = parse_time_range(range)
        
        query = """
            WITH current_period AS (
                SELECT
                    user_id,
                    COUNT(*)::int as total_calls,
                    COUNT(DISTINCT agent_id)::int as agents_used,
                    MAX(timestamp) as last_active
                FROM traces
                WHERE workspace_id = $1 
                    AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                GROUP BY user_id
            ),
            previous_period AS (
                SELECT
                    user_id,
                    COUNT(*)::int as prev_calls
                FROM traces
                WHERE workspace_id = $1 
                    AND timestamp >= NOW() - INTERVAL '1 hour' * $3
                    AND timestamp < NOW() - INTERVAL '1 hour' * $2
                GROUP BY user_id
            )
            SELECT
                c.user_id,
                c.total_calls,
                c.agents_used,
                c.last_active,
                COALESCE(p.prev_calls, 0) as prev_calls
            FROM current_period c
            LEFT JOIN previous_period p ON c.user_id = p.user_id
            ORDER BY c.total_calls DESC
            LIMIT $4
        """
        
        rows = await pool.fetch(query, x_workspace_id, hours, hours * 2, limit)
        total_users = len(rows)
        
        def calculate_trend(current: int, previous: int):
            """Calculate trend: up, down, or stable"""
            if previous == 0:
                return "up", 100.0 if current > 0 else 0.0
            
            change_pct = ((current - previous) / previous) * 100
            
            if change_pct > 5:
                return "up", round(change_pct, 2)
            elif change_pct < -5:
                return "down", round(abs(change_pct), 2)
            else:
                return "stable", round(abs(change_pct), 2)
        
        data = []
        for row in rows:
            trend, change_pct = calculate_trend(row['total_calls'], row['prev_calls'])
            data.append(
                TopUsersItem(
                    user_id=row['user_id'],
                    total_calls=row['total_calls'],
                    agents_used=row['agents_used'],
                    last_active=row['last_active'],
                    trend=trend,
                    change_percentage=change_pct
                )
            )
        
        result = TopUsers(
            data=data,
            total_users=total_users
        )
        
        # Cache for 5 minutes
        set_cache(cache_key, result.model_dump(), ttl=300)
        logger.info(f"Top users fetched: {len(data)} users")
        
        return result
        
    except Exception as e:
        logger.error(f"Error fetching top users: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch top users: {str(e)}"
        )
