"""SQL query builders and executors for Query Service"""
import asyncpg
import logging
from typing import Dict, Any, List, Optional
from uuid import UUID
from datetime import datetime

logger = logging.getLogger(__name__)


def parse_time_range(range_str: str) -> Optional[int]:
    """
    Parse time range string to hours

    Args:
        range_str: Time range (1h, 24h, 7d, 30d)

    Returns:
        Number of hours or None if invalid
    """
    range_map = {
        '1h': 1,
        '24h': 24,
        '7d': 24 * 7,
        '30d': 24 * 30
    }
    return range_map.get(range_str)


async def get_home_kpis(
    timescale_pool: asyncpg.Pool,
    postgres_pool: asyncpg.Pool,
    workspace_id: str,
    range_hours: int,
    department: Optional[str] = None,
    environment: Optional[str] = None,
    version: Optional[str] = None,
    agent_id: Optional[str] = None
) -> Dict[str, Any]:
    """
    Get home dashboard KPIs from both TimescaleDB (traces) and PostgreSQL (evaluations).

    Queries both databases separately and combines results in Python since we cannot
    JOIN across database instances.

    Returns KPIs with percentage change from previous period.

    Args:
        timescale_pool: TimescaleDB connection pool
        postgres_pool: PostgreSQL connection pool
        workspace_id: Workspace UUID
        range_hours: Time range in hours
        department: Optional department code filter
        environment: Optional environment code filter
        version: Optional version filter
        agent_id: Optional agent_id filter
    """
    # Build dynamic WHERE clause for filters
    def build_filter_clause(param_offset: int = 2) -> tuple[str, list]:
        """Build WHERE clause and params for filters"""
        filters = []
        params = []
        idx = param_offset + 1

        if department:
            filters.append(f"""
                department_id = (SELECT id FROM departments
                                WHERE workspace_id = $1 AND department_code = ${idx})
            """)
            params.append(department)
            idx += 1

        if environment:
            filters.append(f"""
                environment_id = (SELECT id FROM environments
                                 WHERE workspace_id = $1 AND environment_code = ${idx})
            """)
            params.append(environment)
            idx += 1

        if version:
            filters.append(f"version = ${idx}")
            params.append(version)
            idx += 1

        if agent_id:
            filters.append(f"agent_id = ${idx}")
            params.append(agent_id)
            idx += 1

        filter_clause = " AND " + " AND ".join(filters) if filters else ""
        return filter_clause, params

    filter_clause, filter_params = build_filter_clause()

    # Query traces metrics from TimescaleDB
    traces_query = f"""
    WITH current_period AS (
        SELECT
            COUNT(DISTINCT id) as total_requests,
            AVG(latency_ms) as avg_latency,
            SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END)::float /
                NULLIF(COUNT(DISTINCT id), 0) * 100 as error_rate,
            SUM(COALESCE(cost_usd, 0)) as total_cost
        FROM traces
        WHERE workspace_id = $1
          AND timestamp >= NOW() - INTERVAL '1 hour' * $2
          {filter_clause}
    ),
    previous_period AS (
        SELECT
            COUNT(DISTINCT id) as total_requests,
            AVG(latency_ms) as avg_latency,
            SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END)::float /
                NULLIF(COUNT(DISTINCT id), 0) * 100 as error_rate,
            SUM(COALESCE(cost_usd, 0)) as total_cost
        FROM traces
        WHERE workspace_id = $1
          AND timestamp >= NOW() - INTERVAL '1 hour' * ($2 * 2)
          AND timestamp < NOW() - INTERVAL '1 hour' * $2
          {filter_clause}
    )
    SELECT
        COALESCE(c.total_requests, 0) as curr_requests,
        COALESCE(p.total_requests, 0) as prev_requests,
        COALESCE(c.avg_latency, 0) as curr_latency,
        COALESCE(p.avg_latency, 0) as prev_latency,
        COALESCE(c.error_rate, 0) as curr_error_rate,
        COALESCE(p.error_rate, 0) as prev_error_rate,
        COALESCE(c.total_cost, 0) as curr_cost,
        COALESCE(p.total_cost, 0) as prev_cost
    FROM current_period c, previous_period p;
    """

    # Query quality scores from PostgreSQL evaluations table
    quality_query = """
    WITH current_period AS (
        SELECT AVG(overall_score) as avg_quality_score
        FROM evaluations
        WHERE workspace_id = $1
          AND created_at >= NOW() - INTERVAL '1 hour' * $2
    ),
    previous_period AS (
        SELECT AVG(overall_score) as avg_quality_score
        FROM evaluations
        WHERE workspace_id = $1
          AND created_at >= NOW() - INTERVAL '1 hour' * ($2 * 2)
          AND created_at < NOW() - INTERVAL '1 hour' * $2
    )
    SELECT
        COALESCE(c.avg_quality_score, 0) as curr_quality_score,
        COALESCE(p.avg_quality_score, 0) as prev_quality_score
    FROM current_period c, previous_period p;
    """

    try:
        # Query both databases in parallel
        async with timescale_pool.acquire() as traces_conn, postgres_pool.acquire() as eval_conn:
            # Combine workspace_id, range_hours, and filter params
            all_params = [workspace_id, range_hours] + filter_params
            traces_row = await traces_conn.fetchrow(traces_query, *all_params)
            quality_row = await eval_conn.fetchrow(quality_query, workspace_id, range_hours)

            if not traces_row:
                return {}

            # Calculate percentage changes
            def calc_change(current, previous):
                if previous == 0:
                    return 0.0 if current == 0 else 100.0
                return ((current - previous) / previous) * 100

            return {
                'curr_requests': int(traces_row['curr_requests']),
                'prev_requests': int(traces_row['prev_requests']),
                'requests_change': calc_change(traces_row['curr_requests'], traces_row['prev_requests']),
                'curr_latency': float(traces_row['curr_latency']),
                'prev_latency': float(traces_row['prev_latency']),
                'latency_change': calc_change(traces_row['curr_latency'], traces_row['prev_latency']),
                'curr_error_rate': float(traces_row['curr_error_rate']),
                'prev_error_rate': float(traces_row['prev_error_rate']),
                'error_rate_change': calc_change(traces_row['curr_error_rate'], traces_row['prev_error_rate']),
                'curr_cost': float(traces_row['curr_cost']),
                'prev_cost': float(traces_row['prev_cost']),
                'cost_change': calc_change(traces_row['curr_cost'], traces_row['prev_cost']),
                'curr_quality_score': float(quality_row['curr_quality_score']) if quality_row else 0.0,
                'prev_quality_score': float(quality_row['prev_quality_score']) if quality_row else 0.0,
                'quality_score_change': calc_change(
                    quality_row['curr_quality_score'] if quality_row else 0.0,
                    quality_row['prev_quality_score'] if quality_row else 0.0
                )
            }
    except Exception as e:
        logger.error(f"Error fetching home KPIs: {str(e)}")
        raise


async def get_recent_alerts(
    pool: asyncpg.Pool,
    workspace_id: str,
    limit: int,
    severity: Optional[str] = None
) -> List[Dict[str, Any]]:
    """
    Get recent alerts with optional severity filter.

    Note: This is a placeholder. In a real implementation, you would have
    an alerts table. For now, we'll generate synthetic alerts based on
    trace error patterns.
    """
    # For Phase 2, we'll create synthetic alerts based on error spikes
    query = """
    SELECT
        gen_random_uuid() as id,
        $1::uuid as workspace_id,
        'High Error Rate' as title,
        'Error rate increased in the last hour' as description,
        CASE
            WHEN error_rate > 10 THEN 'critical'
            WHEN error_rate > 5 THEN 'warning'
            ELSE 'info'
        END as severity,
        error_rate as metric_value,
        NOW() - INTERVAL '1 hour' as created_at
    FROM (
        SELECT
            SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END)::float /
                NULLIF(COUNT(*), 0) * 100 as error_rate
        FROM traces
        WHERE workspace_id = $1
          AND timestamp >= NOW() - INTERVAL '1 hour'
    ) subq
    WHERE error_rate > 0
    LIMIT $2
    """

    try:
        async with pool.acquire() as conn:
            rows = await conn.fetch(query, workspace_id, limit)
            return [dict(row) for row in rows] if rows else []
    except Exception as e:
        logger.error(f"Error fetching alerts: {str(e)}")
        return []


async def get_activity_stream(
    pool: asyncpg.Pool,
    workspace_id: str,
    limit: int
) -> List[Dict[str, Any]]:
    """
    Get recent activity by querying recent traces.
    Maps traces to activity items.
    """
    query = """
    SELECT
        gen_random_uuid() as id,
        workspace_id,
        trace_id,
        agent_id,
        'trace_ingested' as action,
        status,
        timestamp,
        jsonb_build_object(
            'latency_ms', latency_ms,
            'model', model,
            'cost_usd', cost_usd
        ) as metadata
    FROM traces
    WHERE workspace_id = $1
      AND timestamp >= NOW() - INTERVAL '1 hour'
    ORDER BY timestamp DESC
    LIMIT $2
    """

    try:
        async with pool.acquire() as conn:
            rows = await conn.fetch(query, workspace_id, limit)
            return [dict(row) for row in rows]
    except Exception as e:
        logger.error(f"Error fetching activity stream: {str(e)}")
        raise


async def get_traces_list(
    pool: asyncpg.Pool,
    workspace_id: str,
    range_hours: int = 24,
    agent_id: Optional[str] = None,
    status: Optional[str] = None,
    limit: int = 50,
    offset: int = 0
) -> tuple[List[Dict[str, Any]], int]:
    """
    Get paginated list of traces with filters.

    Returns:
        Tuple of (traces, total_count)
    """
    # Build WHERE clause dynamically
    where_clauses = ["workspace_id = $1", "timestamp >= NOW() - INTERVAL '1 hour' * $2"]
    params = [workspace_id, range_hours]
    param_idx = 3

    if agent_id:
        where_clauses.append(f"agent_id = ${param_idx}")
        params.append(agent_id)
        param_idx += 1

    if status:
        where_clauses.append(f"status = ${param_idx}")
        params.append(status)
        param_idx += 1

    where_clause = " AND ".join(where_clauses)

    # Query for traces
    traces_query = f"""
    SELECT
        trace_id,
        agent_id,
        workspace_id,
        timestamp,
        latency_ms,
        status,
        model,
        model_provider,
        tokens_total,
        cost_usd,
        tags
    FROM traces
    WHERE {where_clause}
    ORDER BY timestamp DESC
    LIMIT ${param_idx}
    OFFSET ${param_idx + 1}
    """

    # Query for total count
    count_query = f"""
    SELECT COUNT(*) as total
    FROM traces
    WHERE {where_clause}
    """

    try:
        async with pool.acquire() as conn:
            # Get traces
            traces = await conn.fetch(traces_query, *params, limit, offset)

            # Get total count
            count_row = await conn.fetchrow(count_query, *params)
            total = count_row['total'] if count_row else 0

            return [dict(trace) for trace in traces], total
    except Exception as e:
        logger.error(f"Error fetching traces list: {str(e)}")
        raise


async def get_trace_detail(
    pool: asyncpg.Pool,
    trace_id: str,
    workspace_id: str
) -> Optional[Dict[str, Any]]:
    """
    Get full trace details including input/output.
    """
    query = """
    SELECT
        trace_id,
        agent_id,
        workspace_id,
        timestamp,
        latency_ms,
        status,
        model,
        model_provider,
        tokens_total,
        tokens_input,
        tokens_output,
        cost_usd,
        tags,
        input,
        output,
        error,
        metadata
    FROM traces
    WHERE trace_id = $1 AND workspace_id = $2
    """

    try:
        async with pool.acquire() as conn:
            row = await conn.fetchrow(query, trace_id, workspace_id)
            return dict(row) if row else None
    except Exception as e:
        logger.error(f"Error fetching trace detail: {str(e)}")
        raise
