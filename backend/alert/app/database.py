"""Database connection management for Alert Service"""
import asyncpg
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from uuid import UUID
from .config import get_settings

settings = get_settings()

# Global connection pools
_postgres_pool: Optional[asyncpg.Pool] = None
_timescale_pool: Optional[asyncpg.Pool] = None


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

    return _timescale_pool


async def close_postgres_pool():
    """Close PostgreSQL connection pool"""
    global _postgres_pool

    if _postgres_pool is not None:
        await _postgres_pool.close()
        _postgres_pool = None


async def close_timescale_pool():
    """Close TimescaleDB connection pool"""
    global _timescale_pool

    if _timescale_pool is not None:
        await _timescale_pool.close()
        _timescale_pool = None


# Alert Rules CRUD Operations

async def create_alert_rule(
    pool: asyncpg.Pool,
    workspace_id: UUID,
    agent_id: Optional[str],
    name: str,
    description: Optional[str],
    metric: str,
    condition: str,
    threshold: float,
    window_minutes: int,
    channels: List[str],
    webhook_url: Optional[str]
) -> dict:
    """Create a new alert rule"""
    query = """
        INSERT INTO alert_rules (
            workspace_id,
            agent_id,
            name,
            description,
            metric,
            condition,
            threshold,
            window_minutes,
            channels,
            webhook_url,
            is_active
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, TRUE)
        RETURNING id, workspace_id, agent_id, name, description, created_at, updated_at,
                  metric, condition, threshold, window_minutes, channels, webhook_url,
                  is_active, last_triggered_at
    """

    row = await pool.fetchrow(
        query,
        str(workspace_id),
        agent_id,
        name,
        description,
        metric,
        condition,
        threshold,
        window_minutes,
        channels,
        webhook_url
    )

    return dict(row)


async def get_alert_rule(pool: asyncpg.Pool, rule_id: UUID) -> Optional[dict]:
    """Get alert rule by ID"""
    query = """
        SELECT id, workspace_id, agent_id, name, description, created_at, updated_at,
               metric, condition, threshold, window_minutes, channels, webhook_url,
               is_active, last_triggered_at
        FROM alert_rules
        WHERE id = $1
    """

    row = await pool.fetchrow(query, str(rule_id))

    if row:
        return dict(row)

    return None


async def list_alert_rules(
    pool: asyncpg.Pool,
    workspace_id: UUID,
    active_only: bool = False
) -> List[dict]:
    """List alert rules for a workspace"""
    if active_only:
        query = """
            SELECT id, workspace_id, agent_id, name, description, created_at, updated_at,
                   metric, condition, threshold, window_minutes, channels, webhook_url,
                   is_active, last_triggered_at
            FROM alert_rules
            WHERE workspace_id = $1 AND is_active = TRUE
            ORDER BY created_at DESC
        """
    else:
        query = """
            SELECT id, workspace_id, agent_id, name, description, created_at, updated_at,
                   metric, condition, threshold, window_minutes, channels, webhook_url,
                   is_active, last_triggered_at
            FROM alert_rules
            WHERE workspace_id = $1
            ORDER BY created_at DESC
        """

    rows = await pool.fetch(query, str(workspace_id))

    return [dict(row) for row in rows]


async def update_alert_rule_trigger_time(pool: asyncpg.Pool, rule_id: UUID):
    """Update last_triggered_at timestamp for a rule"""
    query = """
        UPDATE alert_rules
        SET last_triggered_at = NOW()
        WHERE id = $1
    """

    await pool.execute(query, str(rule_id))


# Alert Notifications CRUD Operations

async def create_alert_notification(
    pool: asyncpg.Pool,
    alert_rule_id: UUID,
    workspace_id: UUID,
    title: str,
    message: Optional[str],
    severity: str,
    metric_value: Optional[float],
    channels_sent: List[str],
    delivery_status: Dict[str, Any]
) -> dict:
    """Create a new alert notification"""
    query = """
        INSERT INTO alert_notifications (
            alert_rule_id,
            workspace_id,
            title,
            message,
            severity,
            metric_value,
            channels_sent,
            delivery_status
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING id, alert_rule_id, workspace_id, sent_at, title, message,
                  severity, metric_value, channels_sent, delivery_status
    """

    row = await pool.fetchrow(
        query,
        str(alert_rule_id),
        str(workspace_id),
        title,
        message,
        severity,
        metric_value,
        channels_sent,
        delivery_status
    )

    return dict(row)


async def get_alert_notification(pool: asyncpg.Pool, notification_id: UUID) -> Optional[dict]:
    """Get alert notification by ID"""
    query = """
        SELECT id, alert_rule_id, workspace_id, sent_at, title, message,
               severity, metric_value, channels_sent, delivery_status
        FROM alert_notifications
        WHERE id = $1
    """

    row = await pool.fetchrow(query, str(notification_id))

    if row:
        return dict(row)

    return None


async def list_active_alerts(
    pool: asyncpg.Pool,
    workspace_id: UUID,
    limit: int = 100,
    offset: int = 0
) -> List[dict]:
    """List recent alert notifications for a workspace"""
    query = """
        SELECT id, alert_rule_id, workspace_id, sent_at, title, message,
               severity, metric_value, channels_sent, delivery_status
        FROM alert_notifications
        WHERE workspace_id = $1
        ORDER BY sent_at DESC
        LIMIT $2 OFFSET $3
    """

    rows = await pool.fetch(query, str(workspace_id), limit, offset)

    return [dict(row) for row in rows]


async def count_active_alerts(pool: asyncpg.Pool, workspace_id: UUID) -> int:
    """Count total alerts for a workspace"""
    query = """
        SELECT COUNT(*) as total
        FROM alert_notifications
        WHERE workspace_id = $1
    """

    row = await pool.fetchrow(query, str(workspace_id))

    return row['total'] if row else 0


# TimescaleDB Metrics Queries

async def get_metric_statistics(
    pool: asyncpg.Pool,
    workspace_id: UUID,
    agent_id: Optional[str],
    metric: str,
    window_minutes: int
) -> Optional[Dict[str, float]]:
    """Get metric statistics from TimescaleDB for anomaly detection"""
    time_threshold = datetime.utcnow() - timedelta(minutes=window_minutes)

    # Map metric names to database columns
    metric_column_map = {
        'latency_ms': 'latency_ms',
        'error_rate': 'CASE WHEN COUNT(*) > 0 THEN (COUNT(*) FILTER (WHERE status = \'error\')::float / COUNT(*)::float) * 100 ELSE 0 END',
        'cost_usd': 'cost_usd',
        'request_count': 'COUNT(*)'
    }

    if metric not in metric_column_map:
        return None

    metric_expr = metric_column_map[metric]

    if agent_id:
        query = f"""
            SELECT
                AVG({metric_expr}) as mean,
                STDDEV({metric_expr}) as std_dev,
                MIN({metric_expr}) as min_value,
                MAX({metric_expr}) as max_value,
                COUNT(*) as sample_count
            FROM traces
            WHERE workspace_id = $1
              AND agent_id = $2
              AND timestamp >= $3
        """
        row = await pool.fetchrow(query, str(workspace_id), agent_id, time_threshold)
    else:
        query = f"""
            SELECT
                AVG({metric_expr}) as mean,
                STDDEV({metric_expr}) as std_dev,
                MIN({metric_expr}) as min_value,
                MAX({metric_expr}) as max_value,
                COUNT(*) as sample_count
            FROM traces
            WHERE workspace_id = $1
              AND timestamp >= $2
        """
        row = await pool.fetchrow(query, str(workspace_id), time_threshold)

    if row and row['sample_count'] > 0:
        return {
            'mean': float(row['mean'] or 0),
            'std_dev': float(row['std_dev'] or 0),
            'min_value': float(row['min_value'] or 0),
            'max_value': float(row['max_value'] or 0),
            'sample_count': int(row['sample_count'])
        }

    return None


async def get_current_metric_value(
    pool: asyncpg.Pool,
    workspace_id: UUID,
    agent_id: Optional[str],
    metric: str,
    window_minutes: int
) -> Optional[float]:
    """Get current metric value from TimescaleDB"""
    time_threshold = datetime.utcnow() - timedelta(minutes=window_minutes)

    # Map metric names to aggregation queries
    metric_queries = {
        'latency_ms': 'AVG(latency_ms)',
        'error_rate': 'CASE WHEN COUNT(*) > 0 THEN (COUNT(*) FILTER (WHERE status = \'error\')::float / COUNT(*)::float) * 100 ELSE 0 END',
        'cost_usd': 'SUM(cost_usd)',
        'request_count': 'COUNT(*)'
    }

    if metric not in metric_queries:
        return None

    metric_expr = metric_queries[metric]

    if agent_id:
        query = f"""
            SELECT {metric_expr} as value
            FROM traces
            WHERE workspace_id = $1
              AND agent_id = $2
              AND timestamp >= $3
        """
        row = await pool.fetchrow(query, str(workspace_id), agent_id, time_threshold)
    else:
        query = f"""
            SELECT {metric_expr} as value
            FROM traces
            WHERE workspace_id = $1
              AND timestamp >= $2
        """
        row = await pool.fetchrow(query, str(workspace_id), time_threshold)

    if row and row['value'] is not None:
        return float(row['value'])

    return None
