"""Cost Management endpoints"""
from fastapi import APIRouter, HTTPException, status, Depends, Header, Query as QueryParam
from typing import Optional, List
import asyncpg
from datetime import datetime, timedelta
from ..models import (
    CostOverview, CostTrend, CostTrendItem,
    CostByModel, CostByModelItem,
    Budget, BudgetUpdate
)
from ..database import get_timescale_pool, get_postgres_pool
from ..cache import get_cache, set_cache
from ..config import get_settings
import logging
from uuid import UUID

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/cost", tags=["cost"])
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


@router.get("/overview", response_model=CostOverview)
async def get_cost_overview(
    range: str = QueryParam("30d", regex="^(1h|24h|7d|30d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool),
    postgres_pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Get cost overview metrics
    
    Returns total spend, budget info, average cost per call,
    and projected monthly spend based on current usage.
    """
    cache_key = f"cost_overview:{x_workspace_id}:{range}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return CostOverview(**cached)
    
    try:
        hours = parse_time_range(range)
        
        # Get current period cost
        current_query = """
            SELECT
                COALESCE(SUM(cost_usd), 0) as total_cost,
                COUNT(*)::int as total_calls
            FROM traces
            WHERE workspace_id = $1 
                AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                AND cost_usd IS NOT NULL
        """
        
        # Get previous period cost for comparison
        previous_query = """
            SELECT
                COALESCE(SUM(cost_usd), 0) as prev_cost
            FROM traces
            WHERE workspace_id = $1 
                AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                AND timestamp < NOW() - INTERVAL '1 hour' * $3
                AND cost_usd IS NOT NULL
        """
        
        current = await timescale_pool.fetchrow(current_query, x_workspace_id, hours)
        previous = await timescale_pool.fetchrow(previous_query, x_workspace_id, hours * 2, hours)
        
        total_spend = float(current['total_cost'])
        total_calls = current['total_calls']
        prev_cost = float(previous['prev_cost'])
        
        # Calculate average cost per call
        avg_cost = total_spend / max(total_calls, 1)
        
        # Calculate percentage change
        change_from_previous = 0.0
        if prev_cost > 0:
            change_from_previous = round(((total_spend - prev_cost) / prev_cost) * 100, 2)
        
        # Project monthly spend based on current rate
        if hours > 0:
            daily_rate = (total_spend / hours) * 24
            projected_monthly = daily_rate * 30
        else:
            projected_monthly = 0.0
        
        # Get budget info from PostgreSQL
        budget_query = """
            SELECT monthly_limit_usd, alert_threshold_percentage
            FROM budgets
            WHERE workspace_id = $1
            ORDER BY updated_at DESC
            LIMIT 1
        """
        budget_row = await postgres_pool.fetchrow(budget_query, UUID(x_workspace_id))
        
        budget_limit = None
        budget_remaining = None
        budget_used_pct = None
        
        if budget_row and budget_row['monthly_limit_usd']:
            budget_limit = float(budget_row['monthly_limit_usd'])
            # Get current month spend for budget calculation
            month_query = """
                SELECT COALESCE(SUM(cost_usd), 0) as month_cost
                FROM traces
                WHERE workspace_id = $1 
                    AND timestamp >= date_trunc('month', NOW())
                    AND cost_usd IS NOT NULL
            """
            month_row = await timescale_pool.fetchrow(month_query, x_workspace_id)
            month_cost = float(month_row['month_cost'])
            
            budget_remaining = budget_limit - month_cost
            budget_used_pct = round((month_cost / budget_limit) * 100, 2) if budget_limit > 0 else 0
        
        result = CostOverview(
            total_spend_usd=round(total_spend, 4),
            budget_limit_usd=budget_limit,
            budget_remaining_usd=round(budget_remaining, 4) if budget_remaining is not None else None,
            budget_used_percentage=budget_used_pct,
            avg_cost_per_call_usd=round(avg_cost, 6),
            projected_monthly_spend_usd=round(projected_monthly, 2),
            change_from_previous=change_from_previous
        )
        
        # Cache for 5 minutes
        set_cache(cache_key, result.model_dump(), ttl=300)
        logger.info(f"Cost overview fetched for workspace {x_workspace_id}, range {range}")
        
        return result
        
    except Exception as e:
        logger.error(f"Error fetching cost overview: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch cost overview: {str(e)}"
        )


@router.get("/trend", response_model=CostTrend)
async def get_cost_trend(
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    granularity: str = QueryParam("daily", regex="^(hourly|daily|weekly)$"),
    model: Optional[str] = QueryParam(None),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get cost trend over time
    
    Returns time-series cost data grouped by model and time bucket.
    Useful for visualizing cost trends in stacked area charts.
    """
    cache_key = f"cost_trend:{x_workspace_id}:{range}:{granularity}:{model or 'all'}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return CostTrend(**cached)
    
    try:
        hours = parse_time_range(range)
        interval = parse_granularity(granularity)
        
        # Build query with optional model filter
        model_filter = "AND model = $3" if model else ""
        params = [x_workspace_id, hours] + ([model] if model else [])
        
        query = f"""
            SELECT
                time_bucket(INTERVAL '{interval}', timestamp) as bucket,
                model,
                COALESCE(SUM(cost_usd), 0) as total_cost,
                COUNT(*)::int as call_count
            FROM traces
            WHERE workspace_id = $1 
                AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                AND cost_usd IS NOT NULL
                {model_filter}
            GROUP BY bucket, model
            ORDER BY bucket DESC, model
            LIMIT 1000
        """
        
        rows = await pool.fetch(query, *params)
        
        data = [
            CostTrendItem(
                timestamp=row['bucket'],
                model=row['model'],
                total_cost_usd=round(float(row['total_cost']), 4),
                call_count=row['call_count'],
                avg_cost_per_call_usd=round(
                    float(row['total_cost']) / max(row['call_count'], 1), 
                    6
                )
            )
            for row in rows
        ]
        
        result = CostTrend(
            data=data,
            granularity=granularity,
            range=range
        )
        
        # Cache for 2 minutes
        set_cache(cache_key, result.model_dump(), ttl=120)
        logger.info(f"Cost trend fetched: {len(data)} buckets")
        
        return result
        
    except Exception as e:
        logger.error(f"Error fetching cost trend: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch cost trend: {str(e)}"
        )


@router.get("/by-model", response_model=CostByModel)
async def get_cost_by_model(
    range: str = QueryParam("30d", regex="^(1h|24h|7d|30d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get cost breakdown by model
    
    Returns cost distribution across different AI models with percentages.
    Useful for identifying most expensive models.
    """
    cache_key = f"cost_by_model:{x_workspace_id}:{range}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return CostByModel(**cached)
    
    try:
        hours = parse_time_range(range)
        
        query = """
            WITH model_costs AS (
                SELECT
                    model,
                    model_provider,
                    COALESCE(SUM(cost_usd), 0) as total_cost,
                    COUNT(*)::int as call_count
                FROM traces
                WHERE workspace_id = $1 
                    AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                    AND cost_usd IS NOT NULL
                GROUP BY model, model_provider
            ),
            total_cost AS (
                SELECT SUM(total_cost) as total FROM model_costs
            )
            SELECT
                m.model,
                m.model_provider,
                m.total_cost,
                m.call_count,
                ROUND((m.total_cost / NULLIF(t.total, 0)) * 100, 2) as percentage
            FROM model_costs m
            CROSS JOIN total_cost t
            ORDER BY m.total_cost DESC
            LIMIT 50
        """
        
        rows = await pool.fetch(query, x_workspace_id, hours)
        total_cost = sum(float(row['total_cost']) for row in rows)
        
        data = [
            CostByModelItem(
                model=row['model'],
                model_provider=row['model_provider'],
                total_cost_usd=round(float(row['total_cost']), 4),
                call_count=row['call_count'],
                avg_cost_per_call_usd=round(
                    float(row['total_cost']) / max(row['call_count'], 1),
                    6
                ),
                percentage_of_total=float(row['percentage'] or 0)
            )
            for row in rows
        ]
        
        result = CostByModel(
            data=data,
            total_cost_usd=round(total_cost, 4)
        )
        
        # Cache for 5 minutes
        set_cache(cache_key, result.model_dump(), ttl=300)
        logger.info(f"Cost by model fetched: {len(data)} models")
        
        return result
        
    except Exception as e:
        logger.error(f"Error fetching cost by model: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch cost by model: {str(e)}"
        )


@router.get("/budget", response_model=Budget)
async def get_budget(
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    postgres_pool: asyncpg.Pool = Depends(get_postgres_pool),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get current budget settings and spend
    
    Returns budget limit, alert threshold, and current month's spend.
    """
    cache_key = f"budget:{x_workspace_id}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return Budget(**cached)
    
    try:
        workspace_uuid = UUID(x_workspace_id)
        
        # Get budget settings
        budget_query = """
            SELECT 
                workspace_id,
                monthly_limit_usd,
                alert_threshold_percentage,
                created_at,
                updated_at
            FROM budgets
            WHERE workspace_id = $1
            ORDER BY updated_at DESC
            LIMIT 1
        """
        budget_row = await postgres_pool.fetchrow(budget_query, workspace_uuid)
        
        # Get current month's spend
        spend_query = """
            SELECT COALESCE(SUM(cost_usd), 0) as current_spend
            FROM traces
            WHERE workspace_id = $1 
                AND timestamp >= date_trunc('month', NOW())
                AND cost_usd IS NOT NULL
        """
        spend_row = await timescale_pool.fetchrow(spend_query, x_workspace_id)
        current_spend = float(spend_row['current_spend'])
        
        if budget_row:
            result = Budget(
                workspace_id=budget_row['workspace_id'],
                monthly_limit_usd=float(budget_row['monthly_limit_usd']) if budget_row['monthly_limit_usd'] else None,
                alert_threshold_percentage=float(budget_row['alert_threshold_percentage']),
                current_spend_usd=round(current_spend, 4),
                created_at=budget_row['created_at'],
                updated_at=budget_row['updated_at']
            )
        else:
            # No budget set, return default
            now = datetime.utcnow()
            result = Budget(
                workspace_id=workspace_uuid,
                monthly_limit_usd=None,
                alert_threshold_percentage=80.0,
                current_spend_usd=round(current_spend, 4),
                created_at=now,
                updated_at=now
            )
        
        # Cache for 1 minute (budget changes should be reflected quickly)
        set_cache(cache_key, result.model_dump(), ttl=60)
        logger.info(f"Budget fetched for workspace {x_workspace_id}")
        
        return result
        
    except Exception as e:
        logger.error(f"Error fetching budget: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch budget: {str(e)}"
        )


@router.put("/budget", response_model=Budget)
async def update_budget(
    budget_update: BudgetUpdate,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    postgres_pool: asyncpg.Pool = Depends(get_postgres_pool),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Update budget settings
    
    Updates monthly limit and/or alert threshold for the workspace.
    Creates a new budget entry if none exists.
    """
    try:
        workspace_uuid = UUID(x_workspace_id)
        
        # Check if budget exists
        check_query = "SELECT 1 FROM budgets WHERE workspace_id = $1"
        exists = await postgres_pool.fetchval(check_query, workspace_uuid)
        
        if exists:
            # Update existing budget
            update_parts = []
            params = [workspace_uuid]
            param_idx = 2
            
            if budget_update.monthly_limit_usd is not None:
                update_parts.append(f"monthly_limit_usd = ${param_idx}")
                params.append(budget_update.monthly_limit_usd)
                param_idx += 1
            
            if budget_update.alert_threshold_percentage is not None:
                update_parts.append(f"alert_threshold_percentage = ${param_idx}")
                params.append(budget_update.alert_threshold_percentage)
                param_idx += 1
            
            if not update_parts:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="No fields to update"
                )
            
            update_parts.append("updated_at = NOW()")
            
            update_query = f"""
                UPDATE budgets
                SET {', '.join(update_parts)}
                WHERE workspace_id = $1
                RETURNING workspace_id, monthly_limit_usd, alert_threshold_percentage, created_at, updated_at
            """
            
            result_row = await postgres_pool.fetchrow(update_query, *params)
        else:
            # Insert new budget
            insert_query = """
                INSERT INTO budgets (
                    workspace_id, 
                    monthly_limit_usd, 
                    alert_threshold_percentage,
                    created_at,
                    updated_at
                )
                VALUES ($1, $2, $3, NOW(), NOW())
                RETURNING workspace_id, monthly_limit_usd, alert_threshold_percentage, created_at, updated_at
            """
            
            result_row = await postgres_pool.fetchrow(
                insert_query,
                workspace_uuid,
                budget_update.monthly_limit_usd,
                budget_update.alert_threshold_percentage or 80.0
            )
        
        # Get current month's spend
        spend_query = """
            SELECT COALESCE(SUM(cost_usd), 0) as current_spend
            FROM traces
            WHERE workspace_id = $1 
                AND timestamp >= date_trunc('month', NOW())
                AND cost_usd IS NOT NULL
        """
        spend_row = await timescale_pool.fetchrow(spend_query, x_workspace_id)
        current_spend = float(spend_row['current_spend'])
        
        result = Budget(
            workspace_id=result_row['workspace_id'],
            monthly_limit_usd=float(result_row['monthly_limit_usd']) if result_row['monthly_limit_usd'] else None,
            alert_threshold_percentage=float(result_row['alert_threshold_percentage']),
            current_spend_usd=round(current_spend, 4),
            created_at=result_row['created_at'],
            updated_at=result_row['updated_at']
        )
        
        # Invalidate cache
        cache_key = f"budget:{x_workspace_id}"
        set_cache(cache_key, None, ttl=0)  # Delete cache
        
        logger.info(f"Budget updated for workspace {x_workspace_id}")
        
        return result
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid workspace ID: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Error updating budget: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update budget: {str(e)}"
        )
