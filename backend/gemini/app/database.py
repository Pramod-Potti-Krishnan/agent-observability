"""Database connection management and data aggregation for Gemini Service"""
import asyncpg
import redis.asyncio as redis
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta, date
from decimal import Decimal
from .config import get_settings
import logging
import json

logger = logging.getLogger(__name__)
settings = get_settings()

# Global connection pools
_postgres_pool: Optional[asyncpg.Pool] = None
_timescale_pool: Optional[asyncpg.Pool] = None
_redis_client: Optional[redis.Redis] = None


# ===== Connection Pool Management =====

async def get_postgres_pool() -> asyncpg.Pool:
    """Get or create PostgreSQL connection pool"""
    global _postgres_pool

    if _postgres_pool is None:
        _postgres_pool = await asyncpg.create_pool(
            settings.postgres_url,
            min_size=5,
            max_size=20,
            command_timeout=60
        )
        logger.info("PostgreSQL connection pool created")

    return _postgres_pool


async def get_timescale_pool() -> asyncpg.Pool:
    """Get or create TimescaleDB connection pool"""
    global _timescale_pool

    if _timescale_pool is None:
        _timescale_pool = await asyncpg.create_pool(
            settings.timescale_url,
            min_size=5,
            max_size=20,
            command_timeout=60
        )
        logger.info("TimescaleDB connection pool created")

    return _timescale_pool


async def get_redis_client() -> redis.Redis:
    """Get or create Redis client"""
    global _redis_client

    if _redis_client is None:
        _redis_client = await redis.from_url(
            settings.redis_url,
            encoding="utf-8",
            decode_responses=True
        )
        logger.info("Redis client created")

    return _redis_client


async def close_pools():
    """Close all connection pools"""
    global _postgres_pool, _timescale_pool, _redis_client

    if _postgres_pool is not None:
        await _postgres_pool.close()
        _postgres_pool = None
        logger.info("PostgreSQL pool closed")

    if _timescale_pool is not None:
        await _timescale_pool.close()
        _timescale_pool = None
        logger.info("TimescaleDB pool closed")

    if _redis_client is not None:
        await _redis_client.close()
        _redis_client = None
        logger.info("Redis client closed")


# ===== Cache Functions =====

async def get_cached_insight(cache_key: str) -> Optional[Dict[str, Any]]:
    """Get cached insight from Redis"""
    try:
        redis_client = await get_redis_client()
        cached = await redis_client.get(cache_key)

        if cached:
            logger.info(f"Cache hit for key: {cache_key}")
            return json.loads(cached)

        return None
    except Exception as e:
        logger.error(f"Redis get error: {e}")
        return None


async def set_cached_insight(cache_key: str, data: Dict[str, Any], ttl: int = None) -> bool:
    """Set cached insight in Redis"""
    try:
        redis_client = await get_redis_client()
        ttl = ttl or settings.cache_ttl_insights

        await redis_client.setex(
            cache_key,
            ttl,
            json.dumps(data, default=str)
        )
        logger.info(f"Cache set for key: {cache_key} (TTL: {ttl}s)")
        return True
    except Exception as e:
        logger.error(f"Redis set error: {e}")
        return False


# ===== Cost Analysis Queries =====

async def get_cost_data(
    workspace_id: str,
    days: int,
    agent_id: Optional[str] = None
) -> List[Dict[str, Any]]:
    """Get cost data from TimescaleDB for analysis"""
    pool = await get_timescale_pool()

    start_date = datetime.utcnow() - timedelta(days=days)

    query = """
        SELECT
            model,
            agent_id,
            SUM(total_cost_usd) as total_cost,
            SUM(request_count) as request_count,
            SUM(total_tokens_input + total_tokens_output) as total_tokens
        FROM traces_daily
        WHERE workspace_id = $1
            AND day >= $2
    """

    params = [workspace_id, start_date]

    if agent_id:
        query += " AND agent_id = $3"
        params.append(agent_id)

    query += """
        GROUP BY model, agent_id
        ORDER BY total_cost DESC
    """

    rows = await pool.fetch(query, *params)

    return [
        {
            'model': row['model'],
            'agent_id': row['agent_id'],
            'total_cost': float(row['total_cost'] or 0),
            'request_count': int(row['request_count'] or 0),
            'total_tokens': int(row['total_tokens'] or 0)
        }
        for row in rows
    ]


async def get_total_cost_summary(
    workspace_id: str,
    days: int,
    agent_id: Optional[str] = None
) -> Dict[str, Any]:
    """Get total cost summary"""
    pool = await get_timescale_pool()

    start_date = datetime.utcnow() - timedelta(days=days)

    query = """
        SELECT
            SUM(total_cost_usd) as total_cost,
            SUM(request_count) as total_requests
        FROM traces_daily
        WHERE workspace_id = $1
            AND day >= $2
    """

    params = [workspace_id, start_date]

    if agent_id:
        query += " AND agent_id = $3"
        params.append(agent_id)

    row = await pool.fetchrow(query, *params)

    total_cost = float(row['total_cost'] or 0)
    total_requests = int(row['total_requests'] or 0)

    return {
        'total_cost': total_cost,
        'total_requests': total_requests,
        'avg_cost_per_request': total_cost / total_requests if total_requests > 0 else 0
    }


# ===== Error Analysis Queries =====

async def get_error_data(
    workspace_id: str,
    days: int,
    agent_id: Optional[str] = None,
    min_count: int = 1
) -> List[Dict[str, Any]]:
    """Get error data from TimescaleDB"""
    pool = await get_timescale_pool()

    start_date = datetime.utcnow() - timedelta(days=days)

    query = """
        SELECT
            error,
            agent_id,
            trace_id,
            timestamp
        FROM traces
        WHERE workspace_id = $1
            AND timestamp >= $2
            AND status = 'error'
            AND error IS NOT NULL
    """

    params = [workspace_id, start_date]

    if agent_id:
        query += " AND agent_id = $3"
        params.append(agent_id)

    query += " ORDER BY timestamp DESC LIMIT 1000"

    rows = await pool.fetch(query, *params)

    # Group errors by message
    error_groups: Dict[str, Dict[str, Any]] = {}

    for row in rows:
        error_msg = row['error'] or 'Unknown error'

        if error_msg not in error_groups:
            error_groups[error_msg] = {
                'error_message': error_msg,
                'count': 0,
                'agent_ids': set(),
                'sample_trace_id': row['trace_id']
            }

        error_groups[error_msg]['count'] += 1
        error_groups[error_msg]['agent_ids'].add(row['agent_id'])

    # Convert to list and filter by min_count
    result = [
        {
            'error_message': data['error_message'],
            'count': data['count'],
            'agent_ids': list(data['agent_ids']),
            'sample_trace_id': data['sample_trace_id']
        }
        for data in error_groups.values()
        if data['count'] >= min_count
    ]

    # Sort by count descending
    result.sort(key=lambda x: x['count'], reverse=True)

    return result


async def get_error_summary(
    workspace_id: str,
    days: int,
    agent_id: Optional[str] = None
) -> Dict[str, Any]:
    """Get error summary statistics"""
    pool = await get_timescale_pool()

    start_date = datetime.utcnow() - timedelta(days=days)

    query = """
        SELECT
            SUM(request_count) as total_requests,
            SUM(error_count) as total_errors
        FROM traces_daily
        WHERE workspace_id = $1
            AND day >= $2
    """

    params = [workspace_id, start_date]

    if agent_id:
        query += " AND agent_id = $3"
        params.append(agent_id)

    row = await pool.fetchrow(query, *params)

    total_requests = int(row['total_requests'] or 0)
    total_errors = int(row['total_errors'] or 0)

    return {
        'total_errors': total_errors,
        'total_requests': total_requests,
        'error_rate': (total_errors / total_requests * 100) if total_requests > 0 else 0
    }


# ===== Feedback Analysis Queries =====

async def get_feedback_data(
    workspace_id: str,
    days: int,
    agent_id: Optional[str] = None
) -> List[Dict[str, Any]]:
    """Get feedback data from PostgreSQL"""
    pool = await get_postgres_pool()

    start_date = datetime.utcnow() - timedelta(days=days)

    query = """
        SELECT
            id,
            trace_id,
            rating,
            comment,
            created_at,
            metadata
        FROM feedback
        WHERE workspace_id = $1
            AND created_at >= $2
    """

    params = [workspace_id, start_date]

    if agent_id:
        query += " AND trace_id IN (SELECT trace_id FROM traces WHERE agent_id = $3)"
        params.append(agent_id)

    query += " ORDER BY created_at DESC LIMIT 1000"

    rows = await pool.fetch(query, *params)

    return [
        {
            'id': str(row['id']),
            'trace_id': row['trace_id'],
            'rating': row['rating'],
            'comment': row['comment'],
            'created_at': row['created_at'],
            'metadata': row['metadata']
        }
        for row in rows
    ]


# ===== Daily Summary Queries =====

async def get_daily_summary_data(
    workspace_id: str,
    target_date: date,
    agent_id: Optional[str] = None
) -> Dict[str, Any]:
    """Get daily summary data from TimescaleDB"""
    pool = await get_timescale_pool()

    # Convert date to datetime range
    start_dt = datetime.combine(target_date, datetime.min.time())
    end_dt = datetime.combine(target_date, datetime.max.time())

    query = """
        SELECT
            SUM(request_count) as total_requests,
            SUM(success_count) as success_count,
            SUM(error_count) as error_count,
            AVG(avg_latency_ms) as avg_latency,
            SUM(total_cost_usd) as total_cost,
            model,
            COUNT(DISTINCT agent_id) as agent_count
        FROM traces_daily
        WHERE workspace_id = $1
            AND day >= $2
            AND day < $3
    """

    params = [workspace_id, start_dt, end_dt]

    if agent_id:
        query += " AND agent_id = $4"
        params.append(agent_id)

    query += " GROUP BY model"

    rows = await pool.fetch(query, *params)

    # Aggregate totals
    total_requests = 0
    success_count = 0
    error_count = 0
    total_cost = 0.0
    avg_latency_sum = 0.0
    model_count = 0
    model_breakdown = []

    for row in rows:
        req_count = int(row['total_requests'] or 0)
        total_requests += req_count
        success_count += int(row['success_count'] or 0)
        error_count += int(row['error_count'] or 0)
        total_cost += float(row['total_cost'] or 0)
        avg_latency_sum += float(row['avg_latency'] or 0)
        model_count += 1

        model_breakdown.append({
            'model': row['model'],
            'requests': req_count,
            'cost': float(row['total_cost'] or 0),
            'agent_count': int(row['agent_count'] or 0)
        })

    return {
        'total_requests': total_requests,
        'success_count': success_count,
        'error_count': error_count,
        'success_rate': (success_count / total_requests * 100) if total_requests > 0 else 0,
        'avg_latency': avg_latency_sum / model_count if model_count > 0 else 0,
        'total_cost': total_cost,
        'model_breakdown': model_breakdown
    }


# ===== Business Goals CRUD =====

async def get_business_goals(workspace_id: str, active_only: bool = False) -> List[Dict[str, Any]]:
    """Get business goals for workspace"""
    pool = await get_postgres_pool()

    query = """
        SELECT
            id,
            workspace_id,
            name,
            description,
            metric,
            target_value,
            current_value,
            unit,
            target_date,
            is_active,
            created_at,
            updated_at
        FROM business_goals
        WHERE workspace_id = $1
    """

    params = [workspace_id]

    if active_only:
        query += " AND is_active = TRUE"

    query += " ORDER BY created_at DESC"

    rows = await pool.fetch(query, *params)

    return [dict(row) for row in rows]


async def create_business_goal(
    workspace_id: str,
    name: str,
    metric: str,
    target_value: Decimal,
    description: Optional[str] = None,
    current_value: Decimal = Decimal(0),
    unit: Optional[str] = None,
    target_date: Optional[date] = None
) -> Dict[str, Any]:
    """Create a new business goal"""
    pool = await get_postgres_pool()

    query = """
        INSERT INTO business_goals (
            workspace_id,
            name,
            description,
            metric,
            target_value,
            current_value,
            unit,
            target_date,
            is_active
        ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, TRUE
        )
        RETURNING
            id,
            workspace_id,
            name,
            description,
            metric,
            target_value,
            current_value,
            unit,
            target_date,
            is_active,
            created_at,
            updated_at
    """

    row = await pool.fetchrow(
        query,
        workspace_id,
        name,
        description,
        metric,
        target_value,
        current_value,
        unit,
        target_date
    )

    return dict(row)


async def update_business_goal_progress(
    goal_id: str,
    current_value: Decimal
) -> bool:
    """Update current value of a business goal"""
    pool = await get_postgres_pool()

    query = """
        UPDATE business_goals
        SET current_value = $2, updated_at = NOW()
        WHERE id = $1
    """

    await pool.execute(query, goal_id, current_value)
    return True


# ===== Health Check =====

async def check_database_connections() -> Dict[str, bool]:
    """Check database connections"""
    result = {
        'postgres': False,
        'timescale': False,
        'redis': False
    }

    try:
        pool = await get_postgres_pool()
        await pool.fetchval('SELECT 1')
        result['postgres'] = True
    except Exception as e:
        logger.error(f"PostgreSQL health check failed: {e}")

    try:
        pool = await get_timescale_pool()
        await pool.fetchval('SELECT 1')
        result['timescale'] = True
    except Exception as e:
        logger.error(f"TimescaleDB health check failed: {e}")

    try:
        redis_client = await get_redis_client()
        await redis_client.ping()
        result['redis'] = True
    except Exception as e:
        logger.error(f"Redis health check failed: {e}")

    return result
