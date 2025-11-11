"""
Usage and Cost action endpoints for the AI Agent Observability platform.

Provides administrative action APIs for:
- Deprecating agents
- Setting capacity alerts
- Configuring request quotas
- Budget management
- Cost optimization
"""

from datetime import datetime, timedelta
from typing import Optional, Literal
from fastapi import APIRouter, Depends, Header, HTTPException, status
from pydantic import BaseModel, Field
import asyncpg
import logging

from ..database import get_timescale_pool, get_postgres_pool
from ..cache import get_cache, set_cache

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1", tags=["actions"])


# Request Models

class DeprecateAgentRequest(BaseModel):
    """Request to deprecate an agent"""
    agent_id: str = Field(..., description="Agent to deprecate")
    sunset_date: str = Field(..., description="Date when agent will be sunset (YYYY-MM-DD)")
    replacement_agent_id: Optional[str] = Field(None, description="Recommended replacement agent")
    migration_message: Optional[str] = Field(None, description="Migration guidance for users")


class SetCapacityAlertRequest(BaseModel):
    """Request to configure capacity alert"""
    agent_id: str = Field(..., description="Agent to monitor")
    max_requests_per_hour: int = Field(..., gt=0, description="Maximum requests per hour")
    alert_threshold_percentage: int = Field(80, ge=50, le=95, description="Alert trigger threshold (50-95%)")
    notification_email: Optional[str] = Field(None, description="Email for notifications")


class SetRequestQuotaRequest(BaseModel):
    """Request to set usage quota"""
    scope: Literal['user', 'department'] = Field(..., description="Quota scope")
    user_id: Optional[str] = Field(None, description="Target user (if scope=user)")
    department_id: Optional[str] = Field(None, description="Target department (if scope=department)")
    quota_limit: int = Field(..., gt=0, description="Request limit")
    period: Literal['hourly', 'daily', 'monthly'] = Field('daily', description="Quota period")


# Response Models

class ActionResponse(BaseModel):
    """Standard action response"""
    success: bool
    message: str
    action_id: Optional[str] = None


# Endpoints

@router.post("/usage/actions/deprecate-agent", response_model=ActionResponse)
async def deprecate_agent(
    request: DeprecateAgentRequest,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Mark an agent as deprecated with sunset date

    Deprecated agents will show warnings to users and be removed after sunset date.
    """
    try:
        # Validate sunset date is in the future
        sunset_dt = datetime.strptime(request.sunset_date, "%Y-%m-%d")
        if sunset_dt.date() <= datetime.now().date():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Sunset date must be in the future"
            )

        # Insert deprecation record
        query = """
            INSERT INTO agent_deprecations (
                workspace_id,
                agent_id,
                sunset_date,
                replacement_agent_id,
                migration_message,
                created_at
            ) VALUES ($1, $2, $3, $4, $5, NOW())
            ON CONFLICT (workspace_id, agent_id)
            DO UPDATE SET
                sunset_date = EXCLUDED.sunset_date,
                replacement_agent_id = EXCLUDED.replacement_agent_id,
                migration_message = EXCLUDED.migration_message,
                updated_at = NOW()
            RETURNING id
        """

        action_id = await pool.fetchval(
            query,
            x_workspace_id,
            request.agent_id,
            sunset_dt,
            request.replacement_agent_id,
            request.migration_message
        )

        # Invalidate caches
        cache_pattern = f"usage_*:{x_workspace_id}:*"
        # Note: Would need Redis SCAN for pattern invalidation

        logger.info(f"Agent deprecated: {request.agent_id} in workspace {x_workspace_id}")

        return ActionResponse(
            success=True,
            message=f"Agent {request.agent_id} marked as deprecated. Sunset date: {request.sunset_date}",
            action_id=str(action_id)
        )

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid date format: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Error deprecating agent: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to deprecate agent: {str(e)}"
        )


@router.post("/usage/actions/set-capacity-alert", response_model=ActionResponse)
async def set_capacity_alert(
    request: SetCapacityAlertRequest,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Configure capacity alert for an agent

    Alerts trigger when usage exceeds threshold percentage of max capacity.
    """
    try:
        trigger_threshold = int((request.max_requests_per_hour * request.alert_threshold_percentage) / 100)

        # Insert capacity alert configuration
        query = """
            INSERT INTO capacity_alerts (
                workspace_id,
                agent_id,
                max_requests_per_hour,
                alert_threshold_percentage,
                trigger_threshold,
                notification_email,
                enabled,
                created_at
            ) VALUES ($1, $2, $3, $4, $5, $6, true, NOW())
            ON CONFLICT (workspace_id, agent_id)
            DO UPDATE SET
                max_requests_per_hour = EXCLUDED.max_requests_per_hour,
                alert_threshold_percentage = EXCLUDED.alert_threshold_percentage,
                trigger_threshold = EXCLUDED.trigger_threshold,
                notification_email = EXCLUDED.notification_email,
                enabled = true,
                updated_at = NOW()
            RETURNING id
        """

        action_id = await pool.fetchval(
            query,
            x_workspace_id,
            request.agent_id,
            request.max_requests_per_hour,
            request.alert_threshold_percentage,
            trigger_threshold,
            request.notification_email
        )

        logger.info(f"Capacity alert set for agent: {request.agent_id} in workspace {x_workspace_id}")

        return ActionResponse(
            success=True,
            message=f"Capacity alert configured for {request.agent_id}. Alert triggers at {trigger_threshold} req/hr",
            action_id=str(action_id)
        )

    except Exception as e:
        logger.error(f"Error setting capacity alert: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to set capacity alert: {str(e)}"
        )


@router.post("/usage/actions/set-request-quota", response_model=ActionResponse)
async def set_request_quota(
    request: SetRequestQuotaRequest,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Set request quota for user or department

    Quotas enforce usage limits to control costs and ensure fair usage.
    """
    try:
        # Validate scope and target
        if request.scope == 'user' and not request.user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="user_id required when scope is 'user'"
            )

        if request.scope == 'department' and not request.department_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="department_id required when scope is 'department'"
            )

        # Insert quota configuration
        query = """
            INSERT INTO request_quotas (
                workspace_id,
                scope,
                user_id,
                department_id,
                quota_limit,
                period,
                enabled,
                created_at
            ) VALUES ($1, $2, $3, $4, $5, $6, true, NOW())
            ON CONFLICT (workspace_id, scope, COALESCE(user_id, ''), COALESCE(department_id, ''))
            DO UPDATE SET
                quota_limit = EXCLUDED.quota_limit,
                period = EXCLUDED.period,
                enabled = true,
                updated_at = NOW()
            RETURNING id
        """

        action_id = await pool.fetchval(
            query,
            x_workspace_id,
            request.scope,
            request.user_id,
            request.department_id,
            request.quota_limit,
            request.period
        )

        target = request.user_id if request.scope == 'user' else request.department_id
        logger.info(f"Request quota set for {request.scope} {target} in workspace {x_workspace_id}")

        return ActionResponse(
            success=True,
            message=f"Quota set: {request.quota_limit} requests/{request.period} for {request.scope} {target}",
            action_id=str(action_id)
        )

    except Exception as e:
        logger.error(f"Error setting request quota: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to set request quota: {str(e)}"
        )
