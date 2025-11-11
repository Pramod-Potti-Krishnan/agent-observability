"""Filter options endpoints - provides available values for multi-dimensional filtering"""
from fastapi import APIRouter, HTTPException, status, Depends, Header
from typing import Optional, List
from datetime import datetime
from uuid import UUID
import asyncpg
from pydantic import BaseModel
from ..database import get_timescale_pool
from ..cache import get_cache, set_cache
from ..config import get_settings

router = APIRouter(prefix="/api/v1/filters", tags=["filters"])
settings = get_settings()


class FilterOption(BaseModel):
    """Single filter option"""
    code: str
    name: str
    count: Optional[int] = None


class FilterOptionsResponse(BaseModel):
    """Response model for filter options"""
    data: List[FilterOption]
    meta: dict


@router.get("/departments", response_model=FilterOptionsResponse)
async def get_available_departments(
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get available departments with trace counts.

    Returns list of departments that have traces in the current workspace.
    Useful for populating filter dropdowns.
    """
    cache_key = f"filters:departments:{x_workspace_id}"
    cached = get_cache(cache_key)
    if cached:
        return FilterOptionsResponse(**cached)

    query = """
    SELECT
        d.department_code as code,
        d.department_name as name,
        COUNT(t.id) as count
    FROM departments d
    LEFT JOIN traces t ON t.department_id = d.id
        AND t.workspace_id = d.workspace_id
        AND t.timestamp >= NOW() - INTERVAL '90 days'
    WHERE d.workspace_id = $1
    GROUP BY d.department_code, d.department_name
    HAVING COUNT(t.id) > 0
    ORDER BY COUNT(t.id) DESC
    """

    try:
        workspace_uuid = UUID(x_workspace_id)
        async with timescale_pool.acquire() as conn:
            rows = await conn.fetch(query, workspace_uuid)

            options = [
                FilterOption(
                    code=row['code'],
                    name=row['name'],
                    count=int(row['count'])
                )
                for row in rows
            ]

            result = FilterOptionsResponse(
                data=options,
                meta={
                    "generated_at": str(datetime.now()),
                    "total": len(options)
                }
            )

            # Cache for 5 minutes (warm data)
            set_cache(cache_key, result.model_dump(), ttl=300)

            return result

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid workspace ID format: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch departments: {str(e)}"
        )


@router.get("/environments", response_model=FilterOptionsResponse)
async def get_available_environments(
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get available environments with trace counts.

    Returns list of environments (production, staging, development) with counts.
    """
    cache_key = f"filters:environments:{x_workspace_id}"
    cached = get_cache(cache_key)
    if cached:
        return FilterOptionsResponse(**cached)

    query = """
    SELECT
        e.environment_code as code,
        e.environment_name as name,
        COUNT(t.id) as count,
        BOOL_OR(e.is_production) as is_production
    FROM environments e
    LEFT JOIN traces t ON t.environment_id = e.id
        AND t.workspace_id = e.workspace_id
        AND t.timestamp >= NOW() - INTERVAL '90 days'
    WHERE e.workspace_id = $1
    GROUP BY e.environment_code, e.environment_name
    HAVING COUNT(t.id) > 0
    ORDER BY
        BOOL_OR(e.is_production) DESC,  -- Production first
        COUNT(t.id) DESC
    """

    try:
        workspace_uuid = UUID(x_workspace_id)
        async with timescale_pool.acquire() as conn:
            rows = await conn.fetch(query, workspace_uuid)

            options = [
                FilterOption(
                    code=row['code'],
                    name=row['name'],
                    count=int(row['count'])
                )
                for row in rows
            ]

            result = FilterOptionsResponse(
                data=options,
                meta={
                    "generated_at": str(datetime.now()),
                    "total": len(options)
                }
            )

            # Cache for 5 minutes
            set_cache(cache_key, result.model_dump(), ttl=300)

            return result

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid workspace ID format: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch environments: {str(e)}"
        )


@router.get("/versions", response_model=FilterOptionsResponse)
async def get_available_versions(
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    department: Optional[str] = None,
    environment: Optional[str] = None,
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get available agent versions with trace counts.

    Can be filtered by department and/or environment to show only relevant versions.

    Query Parameters:
        - department: Optional department code filter
        - environment: Optional environment code filter

    Returns list of versions sorted by most recent first.
    """
    # Build cache key with filters
    cache_parts = [x_workspace_id]
    if department:
        cache_parts.append(f"dept:{department}")
    if environment:
        cache_parts.append(f"env:{environment}")

    cache_key = f"filters:versions:{':'.join(cache_parts)}"
    cached = get_cache(cache_key)
    if cached:
        return FilterOptionsResponse(**cached)

    # Build WHERE clause
    try:
        workspace_uuid = UUID(x_workspace_id)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid workspace ID format: {str(e)}"
        )

    where_clauses = ["t.workspace_id = $1", "t.timestamp >= NOW() - INTERVAL '90 days'"]
    params = [workspace_uuid]
    param_idx = 2

    if department:
        where_clauses.append(f"""
            t.department_id = (SELECT id FROM departments
                              WHERE workspace_id = $1 AND department_code = ${param_idx})
        """)
        params.append(department)
        param_idx += 1

    if environment:
        where_clauses.append(f"""
            t.environment_id = (SELECT id FROM environments
                               WHERE workspace_id = $1 AND environment_code = ${param_idx})
        """)
        params.append(environment)
        param_idx += 1

    where_clause = " AND ".join(where_clauses)

    query = f"""
    SELECT
        version as code,
        version as name,
        COUNT(*) as count
    FROM traces t
    WHERE {where_clause}
    GROUP BY version
    HAVING COUNT(*) > 0
    ORDER BY version DESC
    """

    try:
        async with timescale_pool.acquire() as conn:
            rows = await conn.fetch(query, *params)

            options = [
                FilterOption(
                    code=row['code'],
                    name=row['name'],
                    count=int(row['count'])
                )
                for row in rows
            ]

            result = FilterOptionsResponse(
                data=options,
                meta={
                    "generated_at": str(datetime.now()),
                    "total": len(options),
                    "filters_applied": {
                        "department": department,
                        "environment": environment
                    }
                }
            )

            # Cache for 5 minutes
            set_cache(cache_key, result.model_dump(), ttl=300)

            return result

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch versions: {str(e)}"
        )


@router.get("/agents", response_model=FilterOptionsResponse)
async def get_available_agents(
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    department: Optional[str] = None,
    environment: Optional[str] = None,
    version: Optional[str] = None,
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get available agents with trace counts.

    Can be filtered by department, environment, and/or version.

    Query Parameters:
        - department: Optional department code filter
        - environment: Optional environment code filter
        - version: Optional version filter

    Returns list of agents with recent activity.
    """
    # Build cache key
    cache_parts = [x_workspace_id]
    if department:
        cache_parts.append(f"dept:{department}")
    if environment:
        cache_parts.append(f"env:{environment}")
    if version:
        cache_parts.append(f"ver:{version}")

    cache_key = f"filters:agents:{':'.join(cache_parts)}"
    cached = get_cache(cache_key)
    if cached:
        return FilterOptionsResponse(**cached)

    # Build WHERE clause
    try:
        workspace_uuid = UUID(x_workspace_id)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid workspace ID format: {str(e)}"
        )

    where_clauses = ["t.workspace_id = $1", "t.timestamp >= NOW() - INTERVAL '90 days'"]
    params = [workspace_uuid]
    param_idx = 2

    if department:
        where_clauses.append(f"""
            t.department_id = (SELECT id FROM departments
                              WHERE workspace_id = $1 AND department_code = ${param_idx})
        """)
        params.append(department)
        param_idx += 1

    if environment:
        where_clauses.append(f"""
            t.environment_id = (SELECT id FROM environments
                               WHERE workspace_id = $1 AND environment_code = ${param_idx})
        """)
        params.append(environment)
        param_idx += 1

    if version:
        where_clauses.append(f"t.version = ${param_idx}")
        params.append(version)
        param_idx += 1

    where_clause = " AND ".join(where_clauses)

    query = f"""
    SELECT
        agent_id as code,
        agent_id as name,
        COUNT(*) as count
    FROM traces t
    WHERE {where_clause}
    GROUP BY agent_id
    HAVING COUNT(*) > 0
    ORDER BY COUNT(*) DESC
    LIMIT 100
    """

    try:
        async with timescale_pool.acquire() as conn:
            rows = await conn.fetch(query, *params)

            options = [
                FilterOption(
                    code=row['code'],
                    name=row['name'],
                    count=int(row['count'])
                )
                for row in rows
            ]

            result = FilterOptionsResponse(
                data=options,
                meta={
                    "generated_at": str(datetime.now()),
                    "total": len(options),
                    "filters_applied": {
                        "department": department,
                        "environment": environment,
                        "version": version
                    }
                }
            )

            # Cache for 5 minutes
            set_cache(cache_key, result.model_dump(), ttl=300)

            return result

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch agents: {str(e)}"
        )
