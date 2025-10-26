"""
Workspace settings routes for Phase 5.

Endpoints:
- GET /api/v1/workspace - Get workspace configuration
- PUT /api/v1/workspace - Update workspace settings
"""

from fastapi import APIRouter, Depends, HTTPException, status, Header
from typing import Optional
import asyncpg
import json
from redis import Redis
from ..dependencies import get_postgres_connection, get_redis_client
from ..models.settings import WorkspaceResponse, UpdateWorkspaceRequest

router = APIRouter(prefix="/api/v1/workspace", tags=["workspace"])


@router.get("", response_model=WorkspaceResponse)
async def get_workspace(
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    conn: asyncpg.Connection = Depends(get_postgres_connection),
    redis: Redis = Depends(get_redis_client)
):
    """
    Get workspace configuration and details.

    Headers:
        X-Workspace-ID: UUID of the workspace (required)

    Returns:
        WorkspaceResponse: Complete workspace configuration

    RBAC: Any authenticated workspace member
    Cache: 5 minutes
    """
    # Try cache first
    cache_key = f"workspace:{x_workspace_id}"
    try:
        cached = redis.get(cache_key)
        if cached:
            return WorkspaceResponse(**json.loads(cached))
    except Exception:
        pass  # Cache miss, continue to database

    # Query workspace from database
    query = """
        SELECT
            w.id,
            w.name,
            w.description,
            w.timezone,
            w.owner_id,
            w.created_at,
            w.updated_at,
            w.settings,
            (SELECT COUNT(*) FROM team_members tm
             WHERE tm.workspace_id = w.id
             AND tm.status = 'active'
             AND tm.deleted_at IS NULL) as member_count,
            COALESCE(bc.plan_type, 'free') as plan
        FROM workspaces w
        LEFT JOIN billing_config bc ON bc.workspace_id = w.id
        WHERE w.id = $1
    """

    row = await conn.fetchrow(query, x_workspace_id)

    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Workspace {x_workspace_id} not found"
        )

    # Build response
    workspace_data = {
        "id": str(row['id']),
        "name": row['name'],
        "description": row['description'],
        "timezone": row['timezone'] or "UTC",
        "owner_id": str(row['owner_id']),
        "created_at": row['created_at'].isoformat(),
        "updated_at": row['updated_at'].isoformat(),
        "member_count": row['member_count'] or 0,
        "plan": row['plan'],
        "settings": row['settings'] or {}
    }

    result = WorkspaceResponse(**workspace_data)

    # Cache for 5 minutes
    try:
        redis.setex(cache_key, 300, json.dumps(workspace_data))
    except Exception:
        pass  # Cache write failure is non-critical

    return result


@router.put("", response_model=WorkspaceResponse)
async def update_workspace(
    update_data: UpdateWorkspaceRequest,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    conn: asyncpg.Connection = Depends(get_postgres_connection),
    redis: Redis = Depends(get_redis_client)
):
    """
    Update workspace settings.

    Headers:
        X-Workspace-ID: UUID of the workspace (required)

    Body:
        UpdateWorkspaceRequest: Fields to update (all optional)

    Returns:
        WorkspaceResponse: Updated workspace configuration

    RBAC: Owner or Admin only
    Cache: Invalidated on update
    """
    # Build update query dynamically based on provided fields
    update_fields = []
    values = []
    param_count = 1

    if update_data.name is not None:
        update_fields.append(f"name = ${param_count}")
        values.append(update_data.name)
        param_count += 1

    if update_data.description is not None:
        update_fields.append(f"description = ${param_count}")
        values.append(update_data.description)
        param_count += 1

    if update_data.timezone is not None:
        update_fields.append(f"timezone = ${param_count}")
        values.append(update_data.timezone)
        param_count += 1

    if update_data.settings is not None:
        update_fields.append(f"settings = ${param_count}")
        values.append(json.dumps(update_data.settings))
        param_count += 1

    if not update_fields:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields provided for update"
        )

    # Add updated_at
    update_fields.append(f"updated_at = NOW()")

    # Add workspace_id to values
    values.append(x_workspace_id)

    # Execute update
    query = f"""
        UPDATE workspaces
        SET {', '.join(update_fields)}
        WHERE id = ${param_count}
        RETURNING id, name, description, timezone, owner_id, created_at, updated_at, settings
    """

    try:
        row = await conn.fetchrow(query, *values)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update workspace: {str(e)}"
        )

    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Workspace {x_workspace_id} not found"
        )

    # Get member count and plan
    member_query = """
        SELECT COUNT(*) as member_count
        FROM team_members
        WHERE workspace_id = $1 AND status = 'active' AND deleted_at IS NULL
    """
    member_row = await conn.fetchrow(member_query, x_workspace_id)

    plan_query = """
        SELECT COALESCE(plan_type, 'free') as plan
        FROM billing_config
        WHERE workspace_id = $1
    """
    plan_row = await conn.fetchrow(plan_query, x_workspace_id)

    # Build response
    workspace_data = {
        "id": str(row['id']),
        "name": row['name'],
        "description": row['description'],
        "timezone": row['timezone'] or "UTC",
        "owner_id": str(row['owner_id']),
        "created_at": row['created_at'].isoformat(),
        "updated_at": row['updated_at'].isoformat(),
        "member_count": member_row['member_count'] if member_row else 0,
        "plan": plan_row['plan'] if plan_row else 'free',
        "settings": row['settings'] or {}
    }

    result = WorkspaceResponse(**workspace_data)

    # Invalidate cache
    cache_key = f"workspace:{x_workspace_id}"
    try:
        redis.delete(cache_key)
        # Also cache new data
        redis.setex(cache_key, 300, json.dumps(workspace_data))
    except Exception:
        pass  # Cache operations are non-critical

    return result
