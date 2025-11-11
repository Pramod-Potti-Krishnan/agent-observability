"""
Business Impact API Routes
Provides endpoints for ROI tracking, business goals, customer metrics, and value attribution
"""

import logging
from typing import List, Optional
from datetime import datetime, timedelta
from decimal import Decimal

from fastapi import APIRouter, Depends, Header, Query as QueryParam, HTTPException, status as http_status
import asyncpg

from ..database import get_timescale_pool
from ..cache import get_cache, set_cache

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/impact", tags=["Impact"])


def parse_time_range(range_str: str) -> int:
    """Convert range string to hours"""
    mapping = {'1h': 1, '24h': 24, '7d': 168, '30d': 720, '90d': 2160, '1y': 8760}
    return mapping.get(range_str, 720)  # Default 30 days


# ============================================================================
# P0 Endpoints
# ============================================================================

@router.get("/overview")
async def get_impact_overview(
    range: str = QueryParam("30d", regex="^(7d|30d|90d|1y)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get fleet-level ROI overview

    Returns:
    - Total ROI percentage
    - Payback period (months)
    - Net value created
    - Total investment
    - Cumulative savings
    - Key business metrics summary
    """
    try:
        cache_key = f"impact_overview:{x_workspace_id}:{range}"
        cached = get_cache(cache_key)
        if cached:
            return cached

        hours = parse_time_range(range)
        period_start = datetime.utcnow() - timedelta(hours=hours)

        async with pool.acquire() as conn:
            # Get cost savings from traces
            cost_query = """
                SELECT
                    SUM(cost_usd) as total_cost,
                    COUNT(*) as total_requests,
                    AVG(cost_usd) as avg_cost_per_request
                FROM traces
                WHERE workspace_id = $1
                    AND timestamp >= $2
            """
            cost_row = await conn.fetchrow(cost_query, x_workspace_id, period_start)

            # Get investment data
            investment_query = """
                SELECT COALESCE(SUM(amount_usd), 0) as total_investment
                FROM investment_tracking
                WHERE workspace_id = $1
                    AND period_start >= $2
            """
            invest_row = await conn.fetchrow(investment_query, x_workspace_id, period_start)

            # Get value attribution
            value_query = """
                SELECT
                    COALESCE(SUM(cost_savings_usd), 0) as total_savings,
                    COALESCE(SUM(revenue_impact_usd), 0) as total_revenue,
                    COALESCE(SUM(productivity_hours_saved), 0) as total_hours_saved,
                    COALESCE(SUM(total_value_created_usd), 0) as total_value
                FROM value_attribution
                WHERE workspace_id = $1
                    AND period_start >= $2
            """
            value_row = await conn.fetchrow(value_query, x_workspace_id, period_start)

            # Get active goals count
            goals_query = """
                SELECT
                    COUNT(*) as total_goals,
                    COUNT(*) FILTER (WHERE status = 'completed') as completed_goals,
                    AVG(progress_percentage) as avg_progress
                FROM business_goals
                WHERE workspace_id = $1
            """
            goals_row = await conn.fetchrow(goals_query, x_workspace_id)

            # Calculate metrics
            total_investment = float(invest_row['total_investment'] or 12000)  # Default baseline
            total_value = float(value_row['total_value'] or 0)
            total_savings = float(value_row['total_savings'] or 0)

            # If no value attribution data, estimate from cost reduction
            if total_value == 0:
                # Estimate 70% cost reduction as value
                current_cost = float(cost_row['total_cost'] or 0)
                estimated_baseline = current_cost / 0.3  # Assume 70% reduction
                total_savings = estimated_baseline - current_cost
                total_value = total_savings

            net_value = total_value - total_investment
            roi_percentage = (net_value / total_investment * 100) if total_investment > 0 else 0

            # Payback period in months
            days_in_period = hours / 24
            daily_value = total_value / days_in_period if days_in_period > 0 else 0
            monthly_value = daily_value * 30
            payback_months = (total_investment / monthly_value) if monthly_value > 0 else 0

            result = {
                'roi_percentage': round(roi_percentage, 2),
                'payback_period_months': round(payback_months, 1),
                'net_value_created_usd': round(net_value, 2),
                'total_investment_usd': round(total_investment, 2),
                'cumulative_savings_usd': round(total_savings, 2),
                'total_revenue_impact_usd': round(float(value_row['total_revenue'] or 0), 2),
                'productivity_hours_saved': round(float(value_row['total_hours_saved'] or 0), 1),
                'productivity_fte_equivalent': round(float(value_row['total_hours_saved'] or 0) / 2080, 2),
                'total_requests': cost_row['total_requests'],
                'value_per_request': round(total_value / cost_row['total_requests'], 4) if cost_row['total_requests'] > 0 else 0,
                'business_goals': {
                    'total': goals_row['total_goals'],
                    'completed': goals_row['completed_goals'],
                    'avg_progress': round(float(goals_row['avg_progress'] or 0), 1)
                },
                'period': range,
                'period_start': period_start.isoformat(),
                'period_end': datetime.utcnow().isoformat()
            }

            set_cache(cache_key, result, ttl=1800)  # 30 min TTL
            return result

    except Exception as e:
        logger.error(f"Error getting impact overview: {e}")
        raise HTTPException(
            status_code=http_status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get impact overview: {str(e)}"
        )


@router.get("/goals")
async def get_business_goals(
    status_filter: Optional[str] = QueryParam(None, regex="^(active|completed|at_risk|behind)?$"),
    department_id: Optional[str] = None,
    goal_type: Optional[str] = None,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get business goals with progress tracking

    Filters:
    - status: active, completed, at_risk, behind
    - department_id: filter by department
    - goal_type: cost_savings, productivity, csat, revenue, ticket_reduction

    Returns hierarchical goal structure with progress indicators
    """
    try:
        cache_key = f"business_goals:{x_workspace_id}:{status_filter}:{department_id}:{goal_type}"
        cached = get_cache(cache_key)
        if cached:
            return cached

        async with pool.acquire() as conn:
            # Build query dynamically
            where_conditions = ["workspace_id = $1"]
            params = [x_workspace_id]
            param_idx = 2

            if status_filter:
                where_conditions.append(f"status = ${param_idx}")
                params.append(status_filter)
                param_idx += 1

            if department_id:
                where_conditions.append(f"department_id = ${param_idx}")
                params.append(department_id)
                param_idx += 1

            if goal_type:
                where_conditions.append(f"goal_type = ${param_idx}")
                params.append(goal_type)
                param_idx += 1

            query = f"""
                SELECT
                    id,
                    goal_type,
                    name,
                    description,
                    target_value,
                    current_value,
                    unit,
                    target_date,
                    department_id,
                    agent_id,
                    status,
                    progress_percentage,
                    created_at,
                    updated_at
                FROM business_goals
                WHERE {' AND '.join(where_conditions)}
                ORDER BY
                    CASE status
                        WHEN 'at_risk' THEN 1
                        WHEN 'behind' THEN 2
                        WHEN 'active' THEN 3
                        WHEN 'completed' THEN 4
                    END,
                    target_date ASC NULLS LAST
            """

            rows = await conn.fetch(query, *params)

            goals = []
            for row in rows:
                # Determine status color
                status_color = {
                    'completed': 'green',
                    'active': 'blue',
                    'at_risk': 'yellow',
                    'behind': 'red'
                }.get(row['status'], 'gray')

                # Calculate days until target
                days_until_target = None
                if row['target_date']:
                    delta = row['target_date'] - datetime.utcnow()
                    days_until_target = delta.days

                goals.append({
                    'id': str(row['id']),
                    'goal_type': row['goal_type'],
                    'name': row['name'],
                    'description': row['description'],
                    'target_value': float(row['target_value']),
                    'current_value': float(row['current_value'] or 0),
                    'unit': row['unit'],
                    'target_date': row['target_date'].isoformat() if row['target_date'] else None,
                    'days_until_target': days_until_target,
                    'department_id': str(row['department_id']) if row['department_id'] else None,
                    'agent_id': row['agent_id'],
                    'status': row['status'],
                    'status_color': status_color,
                    'progress_percentage': float(row['progress_percentage'] or 0),
                    'created_at': row['created_at'].isoformat(),
                    'updated_at': row['updated_at'].isoformat()
                })

            result = {
                'goals': goals,
                'total_count': len(goals),
                'filters': {
                    'status': status_filter,
                    'department_id': department_id,
                    'goal_type': goal_type
                }
            }

            set_cache(cache_key, result, ttl=600)  # 10 min TTL
            return result

    except Exception as e:
        logger.error(f"Error getting business goals: {e}")
        raise HTTPException(
            status_code=http_status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get business goals: {str(e)}"
        )


@router.get("/goals/{goal_id}")
async def get_goal_detail(
    goal_id: str,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """Get detailed information about a specific business goal including linked agents"""
    try:
        async with pool.acquire() as conn:
            query = """
                SELECT * FROM business_goals
                WHERE id = $1 AND workspace_id = $2
            """
            row = await conn.fetchrow(query, goal_id, x_workspace_id)

            if not row:
                raise HTTPException(
                    status_code=http_status.HTTP_404_NOT_FOUND,
                    detail=f"Goal {goal_id} not found"
                )

            # Get linked agent's contribution if agent_id is set
            agent_contribution = None
            if row['agent_id']:
                contrib_query = """
                    SELECT
                        SUM(total_value_created_usd) as agent_contribution
                    FROM value_attribution
                    WHERE workspace_id = $1
                        AND agent_id = $2
                        AND period_start >= NOW() - INTERVAL '30 days'
                """
                contrib_row = await conn.fetchrow(contrib_query, x_workspace_id, row['agent_id'])
                agent_contribution = float(contrib_row['agent_contribution'] or 0)

            return {
                'id': str(row['id']),
                'goal_type': row['goal_type'],
                'name': row['name'],
                'description': row['description'],
                'target_value': float(row['target_value']),
                'current_value': float(row['current_value'] or 0),
                'unit': row['unit'],
                'target_date': row['target_date'].isoformat() if row['target_date'] else None,
                'department_id': str(row['department_id']) if row['department_id'] else None,
                'agent_id': row['agent_id'],
                'agent_contribution_usd': agent_contribution,
                'status': row['status'],
                'progress_percentage': float(row['progress_percentage'] or 0),
                'created_by': row['created_by'],
                'created_at': row['created_at'].isoformat(),
                'updated_at': row['updated_at'].isoformat()
            }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting goal detail: {e}")
        raise HTTPException(
            status_code=http_status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get goal detail: {str(e)}"
        )


@router.get("/attribution")
async def get_impact_attribution(
    range: str = QueryParam("30d", regex="^(7d|30d|90d)$"),
    limit: int = QueryParam(10, ge=5, le=50),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get impact attribution showing which agents/departments drive most value

    Returns waterfall-style data showing:
    - Top value-creating agents
    - Contribution percentages
    - Value breakdown by category (cost savings, productivity, revenue)
    - Attribution confidence scores
    """
    try:
        cache_key = f"impact_attribution:{x_workspace_id}:{range}:{limit}"
        cached = get_cache(cache_key)
        if cached:
            return cached

        hours = parse_time_range(range)
        period_start = datetime.utcnow() - timedelta(hours=hours)

        async with pool.acquire() as conn:
            # Get top agents by value created
            query = """
                SELECT
                    agent_id,
                    SUM(cost_savings_usd) as cost_savings,
                    SUM(revenue_impact_usd) as revenue_impact,
                    SUM(productivity_hours_saved * 50) as productivity_value,
                    SUM(total_value_created_usd) as total_value,
                    AVG(attribution_confidence) as avg_confidence,
                    COUNT(*) as data_points
                FROM value_attribution
                WHERE workspace_id = $1
                    AND period_start >= $2
                GROUP BY agent_id
                ORDER BY total_value DESC
                LIMIT $3
            """
            rows = await conn.fetch(query, x_workspace_id, period_start, limit)

            # Calculate total for percentages
            total_value = sum(float(row['total_value'] or 0) for row in rows)

            attributions = []
            for row in rows:
                agent_value = float(row['total_value'] or 0)
                attributions.append({
                    'agent_id': row['agent_id'],
                    'total_value_created_usd': round(agent_value, 2),
                    'cost_savings_usd': round(float(row['cost_savings'] or 0), 2),
                    'revenue_impact_usd': round(float(row['revenue_impact'] or 0), 2),
                    'productivity_value_usd': round(float(row['productivity_value'] or 0), 2),
                    'contribution_percentage': round((agent_value / total_value * 100) if total_value > 0 else 0, 1),
                    'attribution_confidence': round(float(row['avg_confidence'] or 0.7), 2),
                    'data_points': row['data_points']
                })

            result = {
                'top_contributors': attributions,
                'total_value_all_agents': round(total_value, 2),
                'period': range,
                'period_start': period_start.isoformat()
            }

            set_cache(cache_key, result, ttl=1800)  # 30 min TTL
            return result

    except Exception as e:
        logger.error(f"Error getting impact attribution: {e}")
        raise HTTPException(
            status_code=http_status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get impact attribution: {str(e)}"
        )


@router.get("/customer-timeline")
async def get_customer_impact_timeline(
    range: str = QueryParam("30d", regex="^(7d|30d|90d)$"),
    agent_id: Optional[str] = None,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get customer satisfaction metrics over time

    Returns time-series data for:
    - CSAT scores
    - NPS scores
    - Ticket volume trends
    - Resolution time trends

    Correlated with agent deployments and optimizations
    """
    try:
        cache_key = f"customer_timeline:{x_workspace_id}:{range}:{agent_id}"
        cached = get_cache(cache_key)
        if cached:
            return cached

        hours = parse_time_range(range)
        period_start = datetime.utcnow() - timedelta(hours=hours)
        granularity = '1 day' if hours > 48 else '1 hour'

        async with pool.acquire() as conn:
            # Build query with optional agent filter
            where_conditions = ["workspace_id = $1", "timestamp >= $2"]
            params = [x_workspace_id, period_start]

            if agent_id:
                where_conditions.append("agent_id = $3")
                params.append(agent_id)

            query = f"""
                SELECT
                    time_bucket('{granularity}', timestamp) as bucket,
                    AVG(csat_score) as avg_csat,
                    AVG(nps_score) as avg_nps,
                    SUM(ticket_volume) as total_tickets,
                    AVG(resolution_time_minutes) as avg_resolution_time,
                    COUNT(*) as sample_count
                FROM customer_impact_metrics
                WHERE {' AND '.join(where_conditions)}
                GROUP BY bucket
                ORDER BY bucket ASC
            """

            rows = await conn.fetch(query, *params)

            timeline = []
            for row in rows:
                timeline.append({
                    'timestamp': row['bucket'].isoformat(),
                    'csat_score': round(float(row['avg_csat'] or 3.0), 2),
                    'nps_score': round(float(row['avg_nps'] or 0), 1),
                    'ticket_volume': int(row['total_tickets'] or 0),
                    'avg_resolution_time_minutes': round(float(row['avg_resolution_time'] or 45), 1),
                    'sample_count': row['sample_count']
                })

            # Calculate trend
            if len(timeline) >= 2:
                first_csat = timeline[0]['csat_score']
                last_csat = timeline[-1]['csat_score']
                csat_trend = ((last_csat - first_csat) / first_csat * 100) if first_csat > 0 else 0
            else:
                csat_trend = 0

            result = {
                'timeline': timeline,
                'summary': {
                    'avg_csat_overall': round(sum(t['csat_score'] for t in timeline) / len(timeline), 2) if timeline else 0,
                    'avg_nps_overall': round(sum(t['nps_score'] for t in timeline) / len(timeline), 1) if timeline else 0,
                    'total_tickets': sum(t['ticket_volume'] for t in timeline),
                    'csat_trend_percentage': round(csat_trend, 1)
                },
                'period': range,
                'granularity': granularity,
                'agent_id': agent_id
            }

            set_cache(cache_key, result, ttl=900)  # 15 min TTL
            return result

    except Exception as e:
        logger.error(f"Error getting customer impact timeline: {e}")
        raise HTTPException(
            status_code=http_status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get customer impact timeline: {str(e)}"
        )


@router.get("/savings-waterfall")
async def get_savings_waterfall(
    range: str = QueryParam("30d", regex="^(7d|30d|90d|1y)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get savings realization waterfall

    Shows journey from:
    - Gross savings opportunity
    - → Realized savings
    - → Net savings (after costs/investment)

    Broken down by category: labor, efficiency, quality improvement
    """
    try:
        cache_key = f"savings_waterfall:{x_workspace_id}:{range}"
        cached = get_cache(cache_key)
        if cached:
            return cached

        hours = parse_time_range(range)
        period_start = datetime.utcnow() - timedelta(hours=hours)

        async with pool.acquire() as conn:
            # Get cost reduction from traces (before/after AI deployment)
            cost_query = """
                SELECT
                    SUM(cost_usd) as current_cost,
                    COUNT(*) as request_count
                FROM traces
                WHERE workspace_id = $1
                    AND timestamp >= $2
            """
            cost_row = await conn.fetchrow(cost_query, x_workspace_id, period_start)

            # Get investment
            invest_query = """
                SELECT
                    SUM(amount_usd) FILTER (WHERE investment_category = 'infrastructure') as infrastructure,
                    SUM(amount_usd) FILTER (WHERE investment_category = 'development') as development,
                    SUM(amount_usd) FILTER (WHERE investment_category = 'operations') as operations,
                    SUM(amount_usd) as total_investment
                FROM investment_tracking
                WHERE workspace_id = $1
                    AND period_start >= $2
            """
            invest_row = await conn.fetchrow(invest_query, x_workspace_id, period_start)

            # Estimate baseline cost (before AI) as 3.3x current cost (70% reduction assumption)
            current_cost = float(cost_row['current_cost'] or 0)
            baseline_cost = current_cost / 0.3
            gross_savings = baseline_cost - current_cost

            # Break down savings by category (estimated based on typical distributions)
            labor_savings = gross_savings * 0.60  # 60% from labor reduction
            efficiency_savings = gross_savings * 0.30  # 30% from efficiency gains
            quality_savings = gross_savings * 0.10  # 10% from quality/error reduction

            total_investment = float(invest_row['total_investment'] or 12000)
            net_savings = gross_savings - total_investment

            result = {
                'waterfall': [
                    {
                        'category': 'Baseline Cost (Before AI)',
                        'value': round(baseline_cost, 2),
                        'type': 'baseline'
                    },
                    {
                        'category': 'Labor Savings',
                        'value': round(-labor_savings, 2),
                        'type': 'savings'
                    },
                    {
                        'category': 'Efficiency Gains',
                        'value': round(-efficiency_savings, 2),
                        'type': 'savings'
                    },
                    {
                        'category': 'Quality Improvement',
                        'value': round(-quality_savings, 2),
                        'type': 'savings'
                    },
                    {
                        'category': 'Gross Savings',
                        'value': round(current_cost, 2),
                        'type': 'intermediate'
                    },
                    {
                        'category': 'Investment Costs',
                        'value': round(total_investment, 2),
                        'type': 'cost'
                    },
                    {
                        'category': 'Net Savings',
                        'value': round(current_cost - total_investment, 2),
                        'type': 'final'
                    }
                ],
                'summary': {
                    'gross_savings_usd': round(gross_savings, 2),
                    'total_investment_usd': round(total_investment, 2),
                    'net_savings_usd': round(net_savings, 2),
                    'savings_rate_percentage': round((gross_savings / baseline_cost * 100) if baseline_cost > 0 else 0, 1)
                },
                'breakdown': {
                    'labor_savings_usd': round(labor_savings, 2),
                    'efficiency_savings_usd': round(efficiency_savings, 2),
                    'quality_savings_usd': round(quality_savings, 2)
                },
                'investment_breakdown': {
                    'infrastructure_usd': round(float(invest_row['infrastructure'] or 0), 2),
                    'development_usd': round(float(invest_row['development'] or 0), 2),
                    'operations_usd': round(float(invest_row['operations'] or 0), 2)
                },
                'period': range
            }

            set_cache(cache_key, result, ttl=1800)  # 30 min TTL
            return result

    except Exception as e:
        logger.error(f"Error getting savings waterfall: {e}")
        raise HTTPException(
            status_code=http_status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get savings waterfall: {str(e)}"
        )


@router.get("/productivity")
async def get_productivity_gains(
    range: str = QueryParam("30d", regex="^(7d|30d|90d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get productivity gain quantification

    Returns:
    - Time saved (hours)
    - Tasks automated (count)
    - Throughput increase (percentage)
    - FTE equivalents
    - Dollar value of productivity gains
    """
    try:
        cache_key = f"productivity:{x_workspace_id}:{range}"
        cached = get_cache(cache_key)
        if cached:
            return cached

        hours = parse_time_range(range)
        period_start = datetime.utcnow() - timedelta(hours=hours)

        async with pool.acquire() as conn:
            # Get current performance metrics
            perf_query = """
                SELECT
                    COUNT(*) as total_requests,
                    AVG(latency_ms) as avg_latency_ms,
                    SUM(tokens_output) as total_tokens_generated
                FROM traces
                WHERE workspace_id = $1
                    AND timestamp >= $2
            """
            perf_row = await conn.fetchrow(perf_query, x_workspace_id, period_start)

            # Calculate productivity metrics
            total_requests = perf_row['total_requests'] or 0
            avg_latency_seconds = (perf_row['avg_latency_ms'] or 15000) / 1000

            # Estimate time savings
            # Assume each AI request saves 5 minutes of human time on average
            avg_time_saved_per_request = 5  # minutes
            total_minutes_saved = total_requests * avg_time_saved_per_request
            total_hours_saved = total_minutes_saved / 60

            # Calculate FTE equivalents (2080 hours/year per FTE)
            days_in_period = hours / 24
            annual_hours_saved = (total_hours_saved / days_in_period) * 365
            fte_equivalent = annual_hours_saved / 2080

            # Calculate dollar value ($50/hour average fully-loaded labor cost)
            hourly_labor_cost = 50
            dollar_value = total_hours_saved * hourly_labor_cost

            # Calculate throughput increase
            # Compare requests per day to estimated manual capacity
            requests_per_day = total_requests / days_in_period if days_in_period > 0 else 0
            manual_capacity_per_day = 16  # Assume 1 person can handle 16 manual requests/day
            throughput_increase_percentage = ((requests_per_day - manual_capacity_per_day) / manual_capacity_per_day * 100) if manual_capacity_per_day > 0 else 0

            result = {
                'time_saved_hours': round(total_hours_saved, 1),
                'time_saved_days': round(total_hours_saved / 8, 1),  # 8-hour workdays
                'tasks_automated': total_requests,
                'throughput_increase_percentage': round(throughput_increase_percentage, 1),
                'fte_equivalent': round(fte_equivalent, 2),
                'dollar_value_usd': round(dollar_value, 2),
                'metrics': {
                    'avg_time_saved_per_request_minutes': avg_time_saved_per_request,
                    'avg_latency_seconds': round(avg_latency_seconds, 2),
                    'requests_per_day': round(requests_per_day, 1),
                    'manual_capacity_per_day': manual_capacity_per_day,
                    'hourly_labor_cost_usd': hourly_labor_cost
                },
                'period': range,
                'period_days': round(days_in_period, 1)
            }

            set_cache(cache_key, result, ttl=900)  # 15 min TTL
            return result

    except Exception as e:
        logger.error(f"Error getting productivity gains: {e}")
        raise HTTPException(
            status_code=http_status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get productivity gains: {str(e)}"
        )


# Agent-specific endpoints

@router.get("/agents/{agent_id}/value")
async def get_agent_business_value(
    agent_id: str,
    range: str = QueryParam("30d", regex="^(7d|30d|90d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get business value created by specific agent

    Returns:
    - Total value created
    - Breakdown by category (cost, revenue, productivity, customer satisfaction)
    - Contribution to business goals
    - Value trend over time
    """
    try:
        cache_key = f"agent_value:{x_workspace_id}:{agent_id}:{range}"
        cached = get_cache(cache_key)
        if cached:
            return cached

        hours = parse_time_range(range)
        period_start = datetime.utcnow() - timedelta(hours=hours)

        async with pool.acquire() as conn:
            # Get value attribution for agent
            value_query = """
                SELECT
                    SUM(cost_savings_usd) as cost_savings,
                    SUM(revenue_impact_usd) as revenue_impact,
                    SUM(productivity_hours_saved) as hours_saved,
                    AVG(customer_satisfaction_delta) as csat_delta,
                    SUM(total_value_created_usd) as total_value,
                    AVG(attribution_confidence) as confidence
                FROM value_attribution
                WHERE workspace_id = $1
                    AND agent_id = $2
                    AND period_start >= $3
            """
            value_row = await conn.fetchrow(value_query, x_workspace_id, agent_id, period_start)

            # Get agent's request volume for context
            usage_query = """
                SELECT
                    COUNT(*) as total_requests,
                    SUM(cost_usd) as total_cost
                FROM traces
                WHERE workspace_id = $1
                    AND agent_id = $2
                    AND timestamp >= $3
            """
            usage_row = await conn.fetchrow(usage_query, x_workspace_id, agent_id, period_start)

            # Get goals this agent is linked to
            goals_query = """
                SELECT
                    id, name, goal_type, progress_percentage
                FROM business_goals
                WHERE workspace_id = $1
                    AND agent_id = $2
            """
            goals_rows = await conn.fetch(goals_query, x_workspace_id, agent_id)

            total_value = float(value_row['total_value'] or 0)
            total_requests = usage_row['total_requests'] or 0

            result = {
                'agent_id': agent_id,
                'total_value_created_usd': round(total_value, 2),
                'value_per_request': round(total_value / total_requests, 4) if total_requests > 0 else 0,
                'breakdown': {
                    'cost_savings_usd': round(float(value_row['cost_savings'] or 0), 2),
                    'revenue_impact_usd': round(float(value_row['revenue_impact'] or 0), 2),
                    'productivity_value_usd': round(float(value_row['hours_saved'] or 0) * 50, 2),
                    'customer_satisfaction_delta': round(float(value_row['csat_delta'] or 0), 2)
                },
                'attribution_confidence': round(float(value_row['confidence'] or 0.7), 2),
                'usage_metrics': {
                    'total_requests': total_requests,
                    'total_cost_usd': round(float(usage_row['total_cost'] or 0), 2)
                },
                'linked_goals': [
                    {
                        'id': str(g['id']),
                        'name': g['name'],
                        'goal_type': g['goal_type'],
                        'progress_percentage': float(g['progress_percentage'] or 0)
                    }
                    for g in goals_rows
                ],
                'period': range
            }

            set_cache(cache_key, result, ttl=600)  # 10 min TTL
            return result

    except Exception as e:
        logger.error(f"Error getting agent business value: {e}")
        raise HTTPException(
            status_code=http_status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get agent business value: {str(e)}"
        )


@router.get("/agents/{agent_id}/goals")
async def get_agent_goals(
    agent_id: str,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """Get business goals linked to a specific agent"""
    try:
        async with pool.acquire() as conn:
            query = """
                SELECT
                    id, goal_type, name, description,
                    target_value, current_value, unit,
                    target_date, status, progress_percentage,
                    created_at, updated_at
                FROM business_goals
                WHERE workspace_id = $1
                    AND agent_id = $2
                ORDER BY
                    CASE status
                        WHEN 'at_risk' THEN 1
                        WHEN 'behind' THEN 2
                        WHEN 'active' THEN 3
                        WHEN 'completed' THEN 4
                    END,
                    target_date ASC NULLS LAST
            """
            rows = await conn.fetch(query, x_workspace_id, agent_id)

            goals = []
            for row in rows:
                goals.append({
                    'id': str(row['id']),
                    'goal_type': row['goal_type'],
                    'name': row['name'],
                    'description': row['description'],
                    'target_value': float(row['target_value']),
                    'current_value': float(row['current_value'] or 0),
                    'unit': row['unit'],
                    'target_date': row['target_date'].isoformat() if row['target_date'] else None,
                    'status': row['status'],
                    'progress_percentage': float(row['progress_percentage'] or 0),
                    'created_at': row['created_at'].isoformat(),
                    'updated_at': row['updated_at'].isoformat()
                })

            return {
                'agent_id': agent_id,
                'goals': goals,
                'total_count': len(goals)
            }

    except Exception as e:
        logger.error(f"Error getting agent goals: {e}")
        raise HTTPException(
            status_code=http_status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get agent goals: {str(e)}"
        )


@router.get("/agents/{agent_id}/customer-impact")
async def get_agent_customer_impact(
    agent_id: str,
    range: str = QueryParam("30d", regex="^(7d|30d|90d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get customer impact metrics for specific agent

    Returns:
    - CSAT score trend
    - NPS score trend
    - Customer feedback/testimonials
    - Before/after metrics
    """
    try:
        cache_key = f"agent_customer:{x_workspace_id}:{agent_id}:{range}"
        cached = get_cache(cache_key)
        if cached:
            return cached

        hours = parse_time_range(range)
        period_start = datetime.utcnow() - timedelta(hours=hours)

        async with pool.acquire() as conn:
            # Get aggregated customer metrics
            metrics_query = """
                SELECT
                    AVG(csat_score) as avg_csat,
                    AVG(nps_score) as avg_nps,
                    SUM(ticket_volume) as total_tickets,
                    AVG(resolution_time_minutes) as avg_resolution_time,
                    COUNT(*) as sample_count
                FROM customer_impact_metrics
                WHERE workspace_id = $1
                    AND agent_id = $2
                    AND timestamp >= $3
            """
            metrics_row = await conn.fetchrow(metrics_query, x_workspace_id, agent_id, period_start)

            # Get recent feedback
            feedback_query = """
                SELECT
                    timestamp,
                    csat_score,
                    satisfaction_feedback,
                    customer_id
                FROM customer_impact_metrics
                WHERE workspace_id = $1
                    AND agent_id = $2
                    AND satisfaction_feedback IS NOT NULL
                    AND timestamp >= $3
                ORDER BY timestamp DESC
                LIMIT 10
            """
            feedback_rows = await conn.fetch(feedback_query, x_workspace_id, agent_id, period_start)

            result = {
                'agent_id': agent_id,
                'metrics': {
                    'avg_csat_score': round(float(metrics_row['avg_csat'] or 3.5), 2),
                    'avg_nps_score': round(float(metrics_row['avg_nps'] or 0), 1),
                    'total_tickets_handled': metrics_row['total_tickets'] or 0,
                    'avg_resolution_time_minutes': round(float(metrics_row['avg_resolution_time'] or 45), 1),
                    'sample_count': metrics_row['sample_count']
                },
                'recent_feedback': [
                    {
                        'timestamp': row['timestamp'].isoformat(),
                        'csat_score': float(row['csat_score']),
                        'feedback': row['satisfaction_feedback'],
                        'customer_id': row['customer_id']
                    }
                    for row in feedback_rows
                ],
                'period': range
            }

            set_cache(cache_key, result, ttl=600)  # 10 min TTL
            return result

    except Exception as e:
        logger.error(f"Error getting agent customer impact: {e}")
        raise HTTPException(
            status_code=http_status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get agent customer impact: {str(e)}"
        )
