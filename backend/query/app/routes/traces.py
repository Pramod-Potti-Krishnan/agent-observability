"""Traces endpoints"""
from fastapi import APIRouter, HTTPException, status, Depends, Header, Query
from typing import Optional
import asyncpg
from ..models import Trace, TraceDetail
from ..database import get_timescale_pool
from ..queries import get_traces_list, get_trace_detail, parse_time_range
from ..cache import get_cache, set_cache
from ..config import get_settings
import hashlib
import json

router = APIRouter(prefix="/api/v1/traces", tags=["traces"])
settings = get_settings()


@router.get("")
async def list_traces(
    range: str = "24h",
    agent_id: Optional[str] = None,
    trace_status: Optional[str] = Query(None, alias="status"),
    limit: int = 50,
    page: int = 1,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get paginated list of traces with filters.

    Query Parameters:
        - range: Time range (1h, 24h, 7d, 30d) - Default: 24h
        - agent_id: Filter by agent ID - Optional
        - status: Filter by status (success, error, timeout) - Optional
        - limit: Results per page (1-100) - Default: 50
        - page: Page number (1-indexed) - Default: 1

    Returns:
        Paginated list of traces
    """
    # Validate parameters
    if limit < 1 or limit > 100:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Limit must be between 1 and 100"
        )

    if page < 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Page must be >= 1"
        )

    range_hours = parse_time_range(range)
    if range_hours is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid time range: {range}"
        )

    if trace_status and trace_status not in ['success', 'error', 'timeout']:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Status must be one of: success, error, timeout"
        )

    # Calculate offset
    offset = (page - 1) * limit

    # Create cache key from filters
    filters_dict = {
        'range': range,
        'agent_id': agent_id,
        'status': trace_status,
        'limit': limit,
        'page': page
    }
    filters_hash = hashlib.md5(json.dumps(filters_dict, sort_keys=True).encode()).hexdigest()
    cache_key = f"traces:list:{x_workspace_id}:{filters_hash}"

    # Try cache first
    cached = get_cache(cache_key)
    if cached:
        return cached

    # Query database
    try:
        traces, total = await get_traces_list(
            pool,
            x_workspace_id,
            range_hours,
            agent_id,
            trace_status,
            limit,
            offset
        )

        # Calculate pagination metadata
        total_pages = (total + limit - 1) // limit  # Ceiling division

        result = {
            "items": traces,
            "total": total,
            "page": page,
            "page_size": limit,
            "total_pages": total_pages,
            "has_next": page < total_pages,
            "has_prev": page > 1
        }

        # Cache result
        try:
            set_cache(cache_key, result, settings.cache_ttl_traces)
        except Exception:
            pass

        return result

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch traces: {str(e)}"
        )


@router.get("/{trace_id}")
async def get_trace_by_id(
    trace_id: str,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get full trace details by ID.

    Path Parameters:
        - trace_id: Trace identifier

    Returns:
        Full trace details including input/output
    """
    # Try cache first
    cache_key = f"trace:detail:{trace_id}"
    cached = get_cache(cache_key)
    if cached:
        return cached

    # Query database
    try:
        trace = await get_trace_detail(pool, trace_id, x_workspace_id)

        if not trace:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Trace not found: {trace_id}"
            )

        # Cache result (longer TTL since traces don't change)
        try:
            set_cache(cache_key, trace, 600)  # 10 minutes
        except Exception:
            pass

        return trace

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch trace details: {str(e)}"
        )
