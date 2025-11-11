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
                    MAX(timestamp) as last_active,
                    SUM(cost_usd) as total_cost,
                    COUNT(*) FILTER (WHERE status = 'error')::int as error_count,
                    MODE() WITHIN GROUP (ORDER BY model_provider) as department
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
                COALESCE(p.prev_calls, 0) as prev_calls,
                COALESCE(c.department, 'Unknown') as department,
                COALESCE(c.total_cost, 0.0) as total_cost_usd,
                c.error_count,
                -- Risk score: 0-100 based on error rate (40%) + cost per call (60%)
                LEAST(100, ROUND(
                    (c.error_count::numeric / NULLIF(c.total_calls, 0) * 40) +
                    (LEAST(c.total_cost / NULLIF(c.total_calls, 0) / 0.01, 1) * 60),
                    2
                )) as risk_score
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
                    change_percentage=change_pct,
                    department=row['department'],
                    total_cost_usd=float(row['total_cost_usd']),
                    risk_score=float(row['risk_score']) if row['risk_score'] else None
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


@router.get("/user-segments")
async def get_user_segments(
    range: str = QueryParam("30d", regex="^(1h|24h|7d|30d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get user segmentation analytics

    Returns user distribution across segments:
    - power_user: Top 10% by request volume
    - regular: Moderate activity users
    - new: Joined in last 30 days
    - dormant: No activity in 30+ days

    PRD Tab 2: User Segmentation (P0)
    """
    cache_key = f"user_segments:{x_workspace_id}:{range}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return cached

    try:
        hours = parse_time_range(range)

        # Query to calculate user segments
        query = """
            WITH user_stats AS (
                SELECT
                    user_id,
                    COUNT(*)::int as request_count,
                    MIN(timestamp) as first_seen,
                    MAX(timestamp) as last_seen,
                    COUNT(DISTINCT agent_id)::int as agents_used
                FROM traces
                WHERE workspace_id = $1
                GROUP BY user_id
            ),
            user_stats_current AS (
                SELECT
                    user_id,
                    COUNT(*)::int as current_requests
                FROM traces
                WHERE workspace_id = $1
                    AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                GROUP BY user_id
            ),
            user_stats_previous AS (
                SELECT
                    user_id,
                    COUNT(*)::int as prev_requests
                FROM traces
                WHERE workspace_id = $1
                    AND timestamp >= NOW() - INTERVAL '1 hour' * $3
                    AND timestamp < NOW() - INTERVAL '1 hour' * $2
                GROUP BY user_id
            ),
            percentiles AS (
                SELECT
                    percentile_cont(0.90) WITHIN GROUP (ORDER BY request_count) as p90_threshold
                FROM user_stats
            ),
            segmented_users AS (
                SELECT
                    us.user_id,
                    us.request_count,
                    usc.current_requests,
                    usp.prev_requests,
                    us.first_seen,
                    us.last_seen,
                    CASE
                        -- Power users: top 10% by activity
                        WHEN us.request_count >= p.p90_threshold THEN 'power_user'
                        -- Dormant: no activity in 30+ days
                        WHEN us.last_seen < NOW() - INTERVAL '30 days' THEN 'dormant'
                        -- New: first seen in last 30 days
                        WHEN us.first_seen >= NOW() - INTERVAL '30 days' THEN 'new'
                        -- Regular: everyone else
                        ELSE 'regular'
                    END as segment
                FROM user_stats us
                CROSS JOIN percentiles p
                LEFT JOIN user_stats_current usc ON us.user_id = usc.user_id
                LEFT JOIN user_stats_previous usp ON us.user_id = usp.user_id
            )
            SELECT
                segment,
                COUNT(*)::int as user_count,
                COALESCE(AVG(NULLIF(current_requests, 0)), 0) as avg_current_requests,
                COALESCE(AVG(NULLIF(prev_requests, 0)), 0) as avg_prev_requests
            FROM segmented_users
            GROUP BY segment
        """

        rows = await pool.fetch(query, x_workspace_id, hours, hours * 2)
        total_users = sum(row['user_count'] for row in rows)

        data = []
        for row in rows:
            user_count = row['user_count']
            percentage = (user_count / total_users * 100) if total_users > 0 else 0
            avg_current = float(row['avg_current_requests'])
            avg_prev = float(row['avg_prev_requests'])

            # Calculate trend
            if avg_prev > 0:
                trend_pct = ((avg_current - avg_prev) / avg_prev) * 100
            else:
                trend_pct = 100.0 if avg_current > 0 else 0.0

            data.append({
                'segment': row['segment'],
                'count': user_count,
                'percentage': round(percentage, 2),
                'avg_requests_per_user': round(avg_current, 1),
                'trend_percentage': round(trend_pct, 2)
            })

        result = {
            'data': data,
            'meta': {
                'total_users': total_users,
                'range': range
            }
        }

        # Cache for 5 minutes
        set_cache(cache_key, result, ttl=300)
        logger.info(f"User segments fetched: {len(data)} segments")

        return result

    except Exception as e:
        logger.error(f"Error fetching user segments: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch user segments: {str(e)}"
        )


@router.get("/intent-distribution")
async def get_intent_distribution(
    range: str = QueryParam("30d", regex="^(1h|24h|7d|30d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get intent distribution matrix (department × intent category)

    Returns heatmap data showing which departments use which intent categories.
    Intent categories are extracted from trace metadata or inferred from patterns.

    PRD Tab 2: Chart 2.8 - Intent Distribution Matrix (P0)
    """
    cache_key = f"intent_distribution:{x_workspace_id}:{range}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return cached

    try:
        hours = parse_time_range(range)

        # Query to get intent × department distribution
        # Now using actual intent_category and department_id from traces table
        query = """
            WITH intent_mapping AS (
                SELECT
                    COALESCE(department_id::text, 'unknown') as department_id,
                    COALESCE(intent_category, 'other') as intent_category,
                    COUNT(*)::int as request_count
                FROM traces
                WHERE workspace_id = $1
                    AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                GROUP BY department_id, intent_category
            ),
            dept_totals AS (
                SELECT
                    department_id,
                    SUM(request_count)::int as dept_total
                FROM intent_mapping
                GROUP BY department_id
            )
            SELECT
                im.department_id,
                im.intent_category,
                im.request_count,
                ROUND((im.request_count::numeric / NULLIF(dt.dept_total, 0)) * 100, 2) as pct_of_dept_total
            FROM intent_mapping im
            JOIN dept_totals dt ON im.department_id = dt.department_id
            ORDER BY im.department_id, im.request_count DESC
        """

        rows = await pool.fetch(query, x_workspace_id, hours)

        # Extract unique departments and intents
        departments = list(set(row['department_id'] for row in rows))
        intent_categories = list(set(row['intent_category'] for row in rows))

        # Build cells array
        cells = [
            {
                'department_id': row['department_id'],
                'intent_category': row['intent_category'],
                'request_count': row['request_count'],
                'pct_of_dept_total': float(row['pct_of_dept_total'])
            }
            for row in rows
        ]

        total_requests = sum(row['request_count'] for row in rows)

        result = {
            'cells': cells,
            'departments': sorted(departments),
            'intent_categories': sorted(intent_categories),
            'meta': {
                'range': range,
                'total_requests': total_requests
            }
        }

        # Cache for 5 minutes
        set_cache(cache_key, result, ttl=300)
        logger.info(f"Intent distribution fetched: {len(cells)} cells, {len(departments)} depts, {len(intent_categories)} intents")

        return result

    except Exception as e:
        logger.error(f"Error fetching intent distribution: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch intent distribution: {str(e)}"
        )


@router.get("/retention-cohorts")
async def get_retention_cohorts(
    range: str = QueryParam("90d", regex="^(1h|24h|7d|30d|90d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get user retention cohort analysis

    Returns monthly cohort retention data showing user stickiness over time.
    Each cohort is defined by signup month, tracked over subsequent months.

    PRD Tab 2: Chart 2.9 - Retention Cohort Analysis (P0)
    """
    cache_key = f"retention_cohorts:{x_workspace_id}:{range}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return cached

    try:
        # Query to calculate cohort retention
        query = """
            WITH user_first_seen AS (
                SELECT
                    user_id,
                    DATE_TRUNC('month', MIN(timestamp)) as cohort_month
                FROM traces
                WHERE workspace_id = $1
                GROUP BY user_id
            ),
            user_monthly_activity AS (
                SELECT DISTINCT
                    t.user_id,
                    DATE_TRUNC('month', t.timestamp) as activity_month
                FROM traces t
                WHERE workspace_id = $1
                    AND timestamp >= NOW() - INTERVAL '12 months'
            ),
            cohort_retention AS (
                SELECT
                    TO_CHAR(ufs.cohort_month, 'YYYY-MM') as cohort_month,
                    EXTRACT(YEAR FROM AGE(uma.activity_month, ufs.cohort_month)) * 12 +
                    EXTRACT(MONTH FROM AGE(uma.activity_month, ufs.cohort_month)) as month_offset,
                    COUNT(DISTINCT uma.user_id)::int as retained_users
                FROM user_first_seen ufs
                JOIN user_monthly_activity uma ON ufs.user_id = uma.user_id
                WHERE ufs.cohort_month >= NOW() - INTERVAL '12 months'
                GROUP BY cohort_month, month_offset
            ),
            cohort_sizes AS (
                SELECT
                    TO_CHAR(cohort_month, 'YYYY-MM') as cohort_month,
                    COUNT(DISTINCT user_id)::int as cohort_size
                FROM user_first_seen
                WHERE cohort_month >= NOW() - INTERVAL '12 months'
                GROUP BY cohort_month
            )
            SELECT
                cr.cohort_month,
                cr.month_offset::int,
                cr.retained_users,
                ROUND((cr.retained_users::numeric / NULLIF(cs.cohort_size, 0)) * 100, 2) as retention_pct
            FROM cohort_retention cr
            JOIN cohort_sizes cs ON cr.cohort_month = cs.cohort_month
            ORDER BY cr.cohort_month DESC, cr.month_offset ASC
        """

        rows = await pool.fetch(query, x_workspace_id)

        # Extract unique cohort months
        cohort_months = sorted(list(set(row['cohort_month'] for row in rows)), reverse=True)
        max_offset = max((row['month_offset'] for row in rows), default=0)

        cohorts = [
            {
                'cohort_month': row['cohort_month'],
                'month_offset': row['month_offset'],
                'retained_users': row['retained_users'],
                'retention_pct': float(row['retention_pct'])
            }
            for row in rows
        ]

        result = {
            'cohorts': cohorts,
            'cohort_months': cohort_months,
            'max_offset': max_offset,
            'meta': {
                'range': range,
                'total_cohorts': len(cohort_months)
            }
        }

        # Cache for 1 hour (cohort data changes slowly)
        set_cache(cache_key, result, ttl=3600)
        logger.info(f"Retention cohorts fetched: {len(cohorts)} cells, {len(cohort_months)} cohorts")

        return result

    except Exception as e:
        logger.error(f"Error fetching retention cohorts: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch retention cohorts: {str(e)}"
        )


@router.get("/agent-adoption")
async def get_agent_adoption(
    range: str = QueryParam("90d", regex="^(1h|24h|7d|30d|90d)$"),
    limit: int = QueryParam(10, ge=1, le=20),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get agent adoption curves for new agents/versions

    Tracks S-curve adoption trajectory for recently launched agents.
    Shows cumulative user adoption over time since launch.

    PRD Tab 2: Chart 2.10 - Agent Adoption Curve (P1)
    """
    cache_key = f"agent_adoption:{x_workspace_id}:{range}:{limit}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return cached

    try:
        hours = parse_time_range(range)

        # Query to get agent adoption data
        # Identify "new" agents as those first seen in last 90 days
        query = """
            WITH agent_launches AS (
                SELECT
                    agent_id,
                    MIN(timestamp) as launch_date
                FROM traces
                WHERE workspace_id = $1
                GROUP BY agent_id
                HAVING MIN(timestamp) >= NOW() - INTERVAL '90 days'
            ),
            agent_daily_adoption AS (
                SELECT
                    al.agent_id,
                    al.launch_date,
                    DATE_TRUNC('day', t.timestamp) as activity_date,
                    COUNT(DISTINCT t.user_id)::int as new_users,
                    COUNT(*)::int as requests
                FROM agent_launches al
                JOIN traces t ON al.agent_id = t.agent_id
                WHERE t.workspace_id = $1
                    AND t.timestamp >= al.launch_date
                GROUP BY al.agent_id, al.launch_date, activity_date
            ),
            total_users_per_agent AS (
                SELECT
                    agent_id,
                    COUNT(DISTINCT user_id)::int as total_users
                FROM traces
                WHERE workspace_id = $1
                GROUP BY agent_id
            )
            SELECT
                ada.agent_id,
                ada.launch_date,
                ada.activity_date,
                SUM(ada.new_users) OVER (
                    PARTITION BY ada.agent_id
                    ORDER BY ada.activity_date
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                ) as cumulative_users,
                SUM(ada.requests) OVER (
                    PARTITION BY ada.agent_id
                    ORDER BY ada.activity_date
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                ) as cumulative_requests,
                tua.total_users,
                'v1.0' as agent_version,
                'active' as lifecycle_stage
            FROM agent_daily_adoption ada
            JOIN total_users_per_agent tua ON ada.agent_id = tua.agent_id
            ORDER BY ada.agent_id, ada.activity_date
            LIMIT 500
        """

        rows = await pool.fetch(query, x_workspace_id)

        # Group by agent
        agents_dict = {}
        for row in rows:
            agent_id = row['agent_id']
            if agent_id not in agents_dict:
                agents_dict[agent_id] = {
                    'agent_id': agent_id,
                    'agent_version': row['agent_version'],
                    'launch_date': row['launch_date'].isoformat(),
                    'data_points': [],
                    'total_users': row['total_users'],
                    'lifecycle_stage': row['lifecycle_stage']
                }

            agents_dict[agent_id]['data_points'].append({
                'date': row['activity_date'].isoformat(),
                'cumulative_users': row['cumulative_users'],
                'cumulative_requests': row['cumulative_requests'],
                'adoption_rate': 0  # Placeholder
            })

        # Calculate adoption percentages
        agents = []
        for agent_data in agents_dict.values():
            total_users = agent_data['total_users']
            current_adoption = agent_data['data_points'][-1]['cumulative_users'] if agent_data['data_points'] else 0

            # Update adoption rates
            for point in agent_data['data_points']:
                point['adoption_rate'] = round((point['cumulative_users'] / max(total_users, 1)) * 100, 2)

            agent_data['current_adoption_pct'] = round((current_adoption / max(total_users, 1)) * 100, 2)
            agents.append(agent_data)

        # Sort by current adoption and limit
        agents = sorted(agents, key=lambda x: x['current_adoption_pct'], reverse=True)[:limit]

        result = {
            'agents': agents,
            'meta': {
                'range': range,
                'total_agents': len(agents)
            }
        }

        # Cache for 10 minutes
        set_cache(cache_key, result, ttl=600)
        logger.info(f"Agent adoption fetched: {len(agents)} agents")

        return result

    except Exception as e:
        logger.error(f"Error fetching agent adoption: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch agent adoption: {str(e)}"
        )


@router.get("/time-of-day-heatmap")
async def get_time_of_day_heatmap(
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get time-of-day usage heatmap (hour × day of week)

    Returns 24×7 grid showing average request volume by hour and day.
    Useful for identifying peak usage patterns and scheduling maintenance.

    PRD Tab 2: Chart 2.16 - Time-of-Day Usage Heatmap (P1)
    """
    cache_key = f"time_of_day_heatmap:{x_workspace_id}:{range}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return cached

    try:
        hours = parse_time_range(range)

        query = """
            WITH hourly_stats AS (
                SELECT
                    EXTRACT(HOUR FROM timestamp)::int as hour_of_day,
                    EXTRACT(DOW FROM timestamp)::int as day_of_week,
                    COUNT(*)::int as request_count
                FROM traces
                WHERE workspace_id = $1
                    AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                GROUP BY hour_of_day, day_of_week
            ),
            averages AS (
                SELECT
                    hour_of_day,
                    day_of_week,
                    AVG(request_count) as request_count_avg
                FROM hourly_stats
                GROUP BY hour_of_day, day_of_week
            ),
            percentiles AS (
                SELECT
                    a.hour_of_day,
                    a.day_of_week,
                    a.request_count_avg,
                    percent_rank() OVER (ORDER BY a.request_count_avg) * 100 as percentile_rank
                FROM averages a
            )
            SELECT
                hour_of_day,
                day_of_week,
                ROUND(request_count_avg::numeric, 2) as request_count_avg,
                ROUND(percentile_rank::numeric, 2) as percentile_rank
            FROM percentiles
            ORDER BY hour_of_day, day_of_week
        """

        rows = await pool.fetch(query, x_workspace_id, hours)

        cells = [
            {
                'hour_of_day': row['hour_of_day'],
                'day_of_week': row['day_of_week'],
                'request_count_avg': float(row['request_count_avg']),
                'percentile_rank': float(row['percentile_rank'])
            }
            for row in rows
        ]

        max_requests = max((cell['request_count_avg'] for cell in cells), default=0)
        total_requests = sum(cell['request_count_avg'] for cell in cells)

        result = {
            'cells': cells,
            'max_requests': max_requests,
            'meta': {
                'range': range,
                'total_requests': int(total_requests)
            }
        }

        # Cache for 10 minutes
        set_cache(cache_key, result, ttl=600)
        logger.info(f"Time-of-day heatmap fetched: {len(cells)} cells")

        return result

    except Exception as e:
        logger.error(f"Error fetching time-of-day heatmap: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch time-of-day heatmap: {str(e)}"
        )
