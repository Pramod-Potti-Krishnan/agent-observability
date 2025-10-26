# Phase 5: Next Steps Implementation Guide

**Created:** October 25, 2025
**Session:** Continuation from Phase 5 initial implementation
**Status:** Backend partially complete (workspace routes done), frontend & remaining backend pending

---

## 🎯 What's Been Completed

### ✅ Database Layer (100%)
- ✅ 3 tables created: `team_members`, `billing_config`, `integrations_config`
- ✅ 21 indexes applied for performance
- ✅ Migration executed successfully
- ✅ Tables verified in database

### ✅ Models & Schemas (100%)
- ✅ 60+ Pydantic models created in `/backend/gateway/app/models/settings.py`
- ✅ All request/response schemas defined
- ✅ Enumerations for roles, plans, integrations

### ✅ Workspace API (100%)
- ✅ GET `/api/v1/workspace` - Retrieves workspace configuration
- ✅ PUT `/api/v1/workspace` - Updates workspace settings
- ✅ Routes registered in `/backend/gateway/app/main.py`
- ✅ Redis caching implemented (5-minute TTL)

---

## 🚧 Remaining Work

### Backend Routes (3 files, 19 endpoints)

#### 1. Team Management Routes
**File:** `/backend/gateway/app/routes/team.py`

**Endpoints to implement:**

```python
# 1. GET /api/v1/team/members - List team members
# 2. POST /api/v1/team/invite - Send invitation
# 3. GET /api/v1/team/invitations - List pending invitations
# 4. POST /api/v1/team/invitations/:token/accept - Accept invitation
# 5. DELETE /api/v1/team/invitations/:id - Cancel invitation
# 6. PUT /api/v1/team/members/:id/role - Update member role
# 7. DELETE /api/v1/team/members/:id - Remove member (soft delete)
# 8. POST /api/v1/team/members/:id/reactivate - Reactivate member
```

**Code Template:**

```python
"""
Team management routes for Phase 5.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Header, Query
from typing import Optional, List
import asyncpg
import json
import secrets
from datetime import datetime, timedelta
from redis import Redis
from ..dependencies import get_postgres_connection, get_redis_client
from ..models.settings import (
    TeamMemberResponse,
    TeamMemberListResponse,
    InviteTeamMemberRequest,
    InvitationResponse,
    InvitationListResponse,
    UpdateMemberRoleRequest,
    PaginationInfo
)

router = APIRouter(prefix="/api/v1/team", tags=["team"])


@router.get("/members", response_model=TeamMemberListResponse)
async def list_team_members(
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    status_filter: Optional[str] = Query(None, description="Filter by status: active, inactive, pending"),
    role_filter: Optional[str] = Query(None, description="Filter by role"),
    limit: int = Query(20, le=100),
    cursor: Optional[str] = None,
    conn: asyncpg.Connection = Depends(get_postgres_connection),
    redis: Redis = Depends(get_redis_client)
):
    """
    List all team members for the workspace.

    RBAC: Any authenticated workspace member
    Cache: 2 minutes
    """
    # Try cache
    cache_key = f"team:members:{x_workspace_id}:{status_filter}:{role_filter}:{limit}:{cursor}"
    try:
        cached = redis.get(cache_key)
        if cached:
            return TeamMemberListResponse(**json.loads(cached))
    except Exception:
        pass

    # Build query
    where_conditions = ["workspace_id = $1", "deleted_at IS NULL"]
    params = [x_workspace_id]
    param_count = 2

    if status_filter:
        where_conditions.append(f"status = ${param_count}")
        params.append(status_filter)
        param_count += 1

    if role_filter:
        where_conditions.append(f"role = ${param_count}")
        params.append(role_filter)
        param_count += 1

    if cursor:
        where_conditions.append(f"id > ${param_count}")
        params.append(cursor)
        param_count += 1

    query = f"""
        SELECT
            tm.id,
            tm.workspace_id,
            tm.user_id,
            tm.role,
            tm.status,
            tm.invitation_email,
            tm.invited_by,
            tm.created_at,
            tm.updated_at,
            tm.accepted_at,
            tm.last_active_at,
            u.email,
            u.full_name
        FROM team_members tm
        LEFT JOIN users u ON u.id = tm.user_id
        WHERE {' AND '.join(where_conditions)}
        ORDER BY tm.created_at DESC
        LIMIT ${param_count}
    """
    params.append(limit + 1)  # Fetch one extra for pagination

    rows = await conn.fetch(query, *params)

    # Process results
    has_more = len(rows) > limit
    members = []
    for row in rows[:limit]:
        members.append({
            "id": str(row['id']),
            "workspace_id": str(row['workspace_id']),
            "user_id": str(row['user_id']),
            "email": row['email'] or row['invitation_email'],
            "full_name": row['full_name'],
            "role": row['role'],
            "status": row['status'],
            "invited_by": str(row['invited_by']) if row['invited_by'] else None,
            "created_at": row['created_at'].isoformat(),
            "accepted_at": row['accepted_at'].isoformat() if row['accepted_at'] else None,
            "last_active_at": row['last_active_at'].isoformat() if row['last_active_at'] else None
        })

    next_cursor = str(rows[limit-1]['id']) if has_more else None

    result_data = {
        "members": members,
        "pagination": {
            "next_cursor": next_cursor,
            "has_more": has_more,
            "total_count": len(members)
        }
    }

    result = TeamMemberListResponse(**result_data)

    # Cache for 2 minutes
    try:
        redis.setex(cache_key, 120, json.dumps(result_data))
    except Exception:
        pass

    return result


@router.post("/invite", response_model=InvitationResponse, status_code=status.HTTP_201_CREATED)
async def invite_team_member(
    invite_data: InviteTeamMemberRequest,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    conn: asyncpg.Connection = Depends(get_postgres_connection),
    redis: Redis = Depends(get_redis_client)
):
    """
    Send invitation to join workspace.

    RBAC: Owner or Admin only
    """
    # Check if user already exists
    user_query = "SELECT id FROM users WHERE email = $1"
    user_row = await conn.fetchrow(user_query, invite_data.email)

    # Check if already a member
    member_check = """
        SELECT id, status FROM team_members
        WHERE workspace_id = $1 AND user_id = $2 AND deleted_at IS NULL
    """
    existing = await conn.fetchrow(member_check, x_workspace_id, user_row['id'] if user_row else None)

    if existing:
        if existing['status'] == 'active':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User is already an active member"
            )

    # Generate secure invitation token
    invitation_token = secrets.token_urlsafe(32)
    expires_at = datetime.utcnow() + timedelta(days=7)

    # Insert invitation
    insert_query = """
        INSERT INTO team_members (
            workspace_id,
            user_id,
            role,
            status,
            invitation_email,
            invitation_token,
            invitation_expires_at,
            invited_by,
            created_by
        ) VALUES ($1, $2, $3, 'pending', $4, $5, $6, $7, $7)
        RETURNING id, invitation_token, invitation_expires_at, created_at
    """

    # TODO: Get current_user_id from auth context
    current_user_id = x_workspace_id  # Placeholder

    row = await conn.fetchrow(
        insert_query,
        x_workspace_id,
        user_row['id'] if user_row else current_user_id,  # Placeholder user
        invite_data.role,
        invite_data.email,
        invitation_token,
        expires_at,
        current_user_id
    )

    # Invalidate team members cache
    try:
        pattern = f"team:members:{x_workspace_id}:*"
        for key in redis.scan_iter(pattern):
            redis.delete(key)
    except Exception:
        pass

    # TODO: Send invitation email
    # await send_invitation_email(invite_data.email, invitation_token, invite_data.role)

    return InvitationResponse(
        id=str(row['id']),
        email=invite_data.email,
        role=invite_data.role,
        status="pending",
        invitation_token=invitation_token,
        expires_at=row['invitation_expires_at'].isoformat(),
        created_at=row['created_at'].isoformat()
    )


# TODO: Implement remaining 6 endpoints following the same pattern
# - GET /api/v1/team/invitations
# - POST /api/v1/team/invitations/:token/accept
# - DELETE /api/v1/team/invitations/:id
# - PUT /api/v1/team/members/:id/role
# - DELETE /api/v1/team/members/:id
# - POST /api/v1/team/members/:id/reactivate
```

**Registration:** Add to `/backend/gateway/app/main.py`:
```python
from .routes.team import router as team_router
app.include_router(team_router)
```

---

#### 2. Billing Routes
**File:** `/backend/gateway/app/routes/billing.py`

**Endpoints to implement:**

```python
# 1. GET /api/v1/billing/config - Get plan & limits
# 2. PUT /api/v1/billing/plan - Update plan
# 3. GET /api/v1/billing/usage - Usage statistics
# 4. POST /api/v1/billing/checkout - Create Stripe checkout session
# 5. GET /api/v1/billing/invoices - Billing history
```

**Code Template:**

```python
"""
Billing configuration routes for Phase 5.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Header
import asyncpg
import json
from redis import Redis
from ..dependencies import get_postgres_connection, get_redis_client
from ..models.settings import (
    BillingConfigResponse,
    UpdateBillingPlanRequest,
    UsageResponse,
    CheckoutSessionRequest,
    CheckoutSessionResponse
)

router = APIRouter(prefix="/api/v1/billing", tags=["billing"])


@router.get("/config", response_model=BillingConfigResponse)
async def get_billing_config(
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    conn: asyncpg.Connection = Depends(get_postgres_connection),
    redis: Redis = Depends(get_redis_client)
):
    """
    Get billing configuration and plan limits.

    RBAC: Any authenticated member
    Cache: 5 minutes
    """
    cache_key = f"billing:config:{x_workspace_id}"
    try:
        cached = redis.get(cache_key)
        if cached:
            return BillingConfigResponse(**json.loads(cached))
    except Exception:
        pass

    query = """
        SELECT
            id,
            workspace_id,
            plan_type,
            plan_status,
            traces_per_month_limit,
            team_members_limit,
            api_keys_limit,
            data_retention_days,
            custom_integrations_limit,
            traces_current_month,
            team_members_current,
            api_keys_current,
            usage_reset_at,
            billing_cycle_start,
            billing_cycle_end,
            next_billing_date,
            monthly_price_usd,
            billing_interval,
            auto_renew,
            stripe_customer_id,
            payment_method_last4,
            payment_method_brand,
            created_at,
            updated_at
        FROM billing_config
        WHERE workspace_id = $1
    """

    row = await conn.fetchrow(query, x_workspace_id)

    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Billing configuration not found"
        )

    billing_data = {
        "id": str(row['id']),
        "workspace_id": str(row['workspace_id']),
        "plan_type": row['plan_type'],
        "plan_status": row['plan_status'],
        "limits": {
            "traces_per_month": row['traces_per_month_limit'],
            "team_members": row['team_members_limit'],
            "api_keys": row['api_keys_limit'],
            "data_retention_days": row['data_retention_days'],
            "custom_integrations": row['custom_integrations_limit']
        },
        "current_usage": {
            "traces": row['traces_current_month'],
            "team_members": row['team_members_current'],
            "api_keys": row['api_keys_current'],
            "reset_at": row['usage_reset_at'].isoformat() if row['usage_reset_at'] else None
        },
        "billing_cycle": {
            "start": row['billing_cycle_start'].isoformat() if row['billing_cycle_start'] else None,
            "end": row['billing_cycle_end'].isoformat() if row['billing_cycle_end'] else None,
            "next_billing_date": row['next_billing_date'].isoformat() if row['next_billing_date'] else None
        },
        "pricing": {
            "monthly_price_usd": float(row['monthly_price_usd']) if row['monthly_price_usd'] else 0.0,
            "billing_interval": row['billing_interval'],
            "auto_renew": row['auto_renew']
        },
        "payment_method": {
            "last4": row['payment_method_last4'],
            "brand": row['payment_method_brand']
        } if row['payment_method_last4'] else None,
        "created_at": row['created_at'].isoformat(),
        "updated_at": row['updated_at'].isoformat()
    }

    result = BillingConfigResponse(**billing_data)

    try:
        redis.setex(cache_key, 300, json.dumps(billing_data))
    except Exception:
        pass

    return result


# TODO: Implement remaining 4 endpoints
# - PUT /api/v1/billing/plan
# - GET /api/v1/billing/usage
# - POST /api/v1/billing/checkout (Stripe integration)
# - GET /api/v1/billing/invoices
```

**Registration:** Add to `/backend/gateway/app/main.py`:
```python
from .routes.billing import router as billing_router
app.include_router(billing_router)
```

---

#### 3. Integrations Routes
**File:** `/backend/gateway/app/routes/integrations.py`

**Endpoints to implement:**

```python
# 1. GET /api/v1/integrations - List all integrations
# 2. GET /api/v1/integrations/:type - Get specific integration
# 3. PUT /api/v1/integrations/:type - Update integration config
# 4. POST /api/v1/integrations/:type/test - Test connection
# 5. DELETE /api/v1/integrations/:type - Disable integration
# 6. POST /api/v1/integrations/:type/enable - Enable integration
```

**Code Template:**

```python
"""
Integrations configuration routes for Phase 5.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Header, Path
from typing import List
import asyncpg
import json
from redis import Redis
from ..dependencies import get_postgres_connection, get_redis_client
from ..models.settings import (
    IntegrationResponse,
    IntegrationListResponse,
    UpdateIntegrationRequest,
    TestIntegrationResponse
)

router = APIRouter(prefix="/api/v1/integrations", tags=["integrations"])


@router.get("", response_model=IntegrationListResponse)
async def list_integrations(
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    conn: asyncpg.Connection = Depends(get_postgres_connection),
    redis: Redis = Depends(get_redis_client)
):
    """
    List all configured integrations.

    RBAC: Any authenticated member
    Cache: 5 minutes
    """
    cache_key = f"integrations:list:{x_workspace_id}"
    try:
        cached = redis.get(cache_key)
        if cached:
            return IntegrationListResponse(**json.loads(cached))
    except Exception:
        pass

    query = """
        SELECT
            id,
            workspace_id,
            integration_type,
            integration_name,
            config_data,
            is_enabled,
            health_status,
            last_health_check_at,
            last_sync_at,
            last_error_at,
            last_error_message,
            total_events_sent,
            total_errors,
            created_at,
            updated_at
        FROM integrations_config
        WHERE workspace_id = $1
        ORDER BY created_at DESC
    """

    rows = await conn.fetch(query, x_workspace_id)

    integrations = []
    for row in rows:
        integrations.append({
            "id": str(row['id']),
            "workspace_id": str(row['workspace_id']),
            "integration_type": row['integration_type'],
            "integration_name": row['integration_name'],
            "config_data": row['config_data'],
            "is_enabled": row['is_enabled'],
            "health_status": row['health_status'],
            "last_health_check_at": row['last_health_check_at'].isoformat() if row['last_health_check_at'] else None,
            "last_sync_at": row['last_sync_at'].isoformat() if row['last_sync_at'] else None,
            "last_error_at": row['last_error_at'].isoformat() if row['last_error_at'] else None,
            "last_error_message": row['last_error_message'],
            "stats": {
                "total_events_sent": row['total_events_sent'],
                "total_errors": row['total_errors']
            },
            "created_at": row['created_at'].isoformat(),
            "updated_at": row['updated_at'].isoformat()
        })

    result_data = {"integrations": integrations}
    result = IntegrationListResponse(**result_data)

    try:
        redis.setex(cache_key, 300, json.dumps(result_data))
    except Exception:
        pass

    return result


# TODO: Implement remaining 5 endpoints
# - GET /api/v1/integrations/:type
# - PUT /api/v1/integrations/:type
# - POST /api/v1/integrations/:type/test
# - DELETE /api/v1/integrations/:type
# - POST /api/v1/integrations/:type/enable
```

**Registration:** Add to `/backend/gateway/app/main.py`:
```python
from .routes.integrations import router as integrations_router
app.include_router(integrations_router)
```

---

### Frontend Components (4 files)

The settings page structure already exists at `/frontend/app/dashboard/settings/page.tsx`. You need to create the tab components:

#### 1. GeneralSettings Component
**File:** `/frontend/app/dashboard/settings/components/GeneralSettings.tsx`

```typescript
'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { toast } from 'sonner'

interface WorkspaceData {
  id: string
  name: string
  description?: string
  timezone: string
  member_count: number
  plan: string
  settings?: Record<string, any>
}

export function GeneralSettings() {
  const [workspace, setWorkspace] = useState<WorkspaceData | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    fetchWorkspace()
  }, [])

  const fetchWorkspace = async () => {
    try {
      const workspaceId = localStorage.getItem('workspace_id')
      const response = await fetch('http://localhost:8000/api/v1/workspace', {
        headers: {
          'X-Workspace-ID': workspaceId || ''
        }
      })

      if (!response.ok) throw new Error('Failed to fetch workspace')

      const data = await response.json()
      setWorkspace(data)
    } catch (error) {
      toast.error('Failed to load workspace settings')
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  const handleSave = async () => {
    if (!workspace) return

    setSaving(true)
    try {
      const workspaceId = localStorage.getItem('workspace_id')
      const response = await fetch('http://localhost:8000/api/v1/workspace', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'X-Workspace-ID': workspaceId || ''
        },
        body: JSON.stringify({
          name: workspace.name,
          description: workspace.description,
          timezone: workspace.timezone
        })
      })

      if (!response.ok) throw new Error('Failed to update workspace')

      toast.success('Workspace settings updated successfully')
      fetchWorkspace()
    } catch (error) {
      toast.error('Failed to save workspace settings')
      console.error(error)
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return <div className="p-4">Loading...</div>
  }

  if (!workspace) {
    return <div className="p-4">No workspace found</div>
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>General Settings</CardTitle>
        <CardDescription>
          Manage your workspace name, description, and timezone
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="workspace-name">Workspace Name</Label>
          <Input
            id="workspace-name"
            value={workspace.name}
            onChange={(e) => setWorkspace({ ...workspace, name: e.target.value })}
            placeholder="Enter workspace name"
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="workspace-description">Description</Label>
          <Textarea
            id="workspace-description"
            value={workspace.description || ''}
            onChange={(e) => setWorkspace({ ...workspace, description: e.target.value })}
            placeholder="Enter workspace description"
            rows={3}
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="workspace-timezone">Timezone</Label>
          <Input
            id="workspace-timezone"
            value={workspace.timezone}
            onChange={(e) => setWorkspace({ ...workspace, timezone: e.target.value })}
            placeholder="e.g., America/New_York"
          />
        </div>

        <div className="pt-4">
          <Button onClick={handleSave} disabled={saving}>
            {saving ? 'Saving...' : 'Save Changes'}
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
```

#### 2-4. Remaining Tab Components

Create similar components for:
- `TeamSettings.tsx` - Team member management
- `BillingSettings.tsx` - Billing and usage
- `IntegrationsSettings.tsx` - Integration configurations

Then update `/frontend/app/dashboard/settings/page.tsx` to import and use these components.

---

## 📝 Implementation Checklist

### Backend
- [ ] Create `/backend/gateway/app/routes/team.py` (8 endpoints)
- [ ] Create `/backend/gateway/app/routes/billing.py` (5 endpoints)
- [ ] Create `/backend/gateway/app/routes/integrations.py` (6 endpoints)
- [ ] Register all routes in `main.py`
- [ ] Test endpoints with curl or Postman

### Frontend
- [ ] Create `/frontend/app/dashboard/settings/components/GeneralSettings.tsx`
- [ ] Create `/frontend/app/dashboard/settings/components/TeamSettings.tsx`
- [ ] Create `/frontend/app/dashboard/settings/components/BillingSettings.tsx`
- [ ] Create `/frontend/app/dashboard/settings/components/IntegrationsSettings.tsx`
- [ ] Update settings page.tsx to use components
- [ ] Test in browser at http://localhost:3000/dashboard/settings

### Optional Utilities
- [ ] Create `/backend/gateway/app/utils/email.py` for invitation emails
- [ ] Create `/backend/gateway/app/utils/encryption.py` for credential encryption
- [ ] Implement Stripe integration for billing checkout

---

## 🧪 Testing Commands

### Test Workspace API (Already working)
```bash
export WORKSPACE_ID="your-workspace-id"

# Get workspace
curl -X GET "http://localhost:8000/api/v1/workspace" \
  -H "X-Workspace-ID: $WORKSPACE_ID"

# Update workspace
curl -X PUT "http://localhost:8000/api/v1/workspace" \
  -H "Content-Type: application/json" \
  -H "X-Workspace-ID: $WORKSPACE_ID" \
  -d '{
    "name": "Updated Workspace",
    "description": "New description",
    "timezone": "America/Los_Angeles"
  }'
```

### Test Team API (Once implemented)
```bash
# List team members
curl "http://localhost:8000/api/v1/team/members" \
  -H "X-Workspace-ID: $WORKSPACE_ID"

# Invite member
curl -X POST "http://localhost:8000/api/v1/team/invite" \
  -H "Content-Type: application/json" \
  -H "X-Workspace-ID: $WORKSPACE_ID" \
  -d '{
    "email": "newmember@example.com",
    "role": "member"
  }'
```

### Test Billing API (Once implemented)
```bash
# Get billing config
curl "http://localhost:8000/api/v1/billing/config" \
  -H "X-Workspace-ID: $WORKSPACE_ID"

# Get usage stats
curl "http://localhost:8000/api/v1/billing/usage" \
  -H "X-Workspace-ID: $WORKSPACE_ID"
```

### Test Integrations API (Once implemented)
```bash
# List integrations
curl "http://localhost:8000/api/v1/integrations" \
  -H "X-Workspace-ID: $WORKSPACE_ID"

# Test integration
curl -X POST "http://localhost:8000/api/v1/integrations/slack/test" \
  -H "X-Workspace-ID: $WORKSPACE_ID"
```

---

## 📚 Reference Files

**Models (Already created):**
- `/backend/gateway/app/models/settings.py` - All Pydantic models

**Database Schema:**
- `/docs/phase5/DATABASE_SCHEMA_PHASE5.md` - Complete schema documentation
- `/docs/phase5/QUICK_REFERENCE.md` - Quick database reference

**Pattern Reference:**
- `/backend/gateway/app/routes/workspace.py` - Working example to follow
- `/backend/query/app/routes/` - Additional FastAPI pattern examples

**Models Reference:**
All models are defined in `settings.py`. Key models:
- `TeamMemberResponse`, `InviteTeamMemberRequest`
- `BillingConfigResponse`, `UpdateBillingPlanRequest`
- `IntegrationResponse`, `UpdateIntegrationRequest`

---

## 🎯 Success Criteria

When implementation is complete, you should have:

1. **21 API endpoints** working (2 workspace + 8 team + 5 billing + 6 integrations)
2. **Settings page** with 4 functional tabs
3. **All endpoints** registered in main.py
4. **Redis caching** on all GET endpoints
5. **Proper error handling** throughout
6. **RBAC checks** (Owner/Admin for sensitive operations)

---

## ⚡ Quick Start Commands

```bash
# 1. Start services
cd "/Users/pk1980/Documents/Software/Agent Monitoring"
docker-compose up -d

# 2. Rebuild gateway after adding routes
docker-compose build gateway
docker-compose up -d --force-recreate --no-deps gateway

# 3. Check gateway logs
docker-compose logs -f gateway

# 4. Test workspace API (should work already)
curl "http://localhost:8000/api/v1/workspace" \
  -H "X-Workspace-ID: 37160be9-7d69-43b5-8d5f-9d7b5e14a57a"
```

---

## 📊 Estimated Time

- Team routes: 2-3 hours
- Billing routes: 1-2 hours
- Integrations routes: 1-2 hours
- Frontend components: 2-3 hours
- Testing & debugging: 1-2 hours

**Total:** 7-12 hours of focused work

---

**Next Session Instructions:**
1. Read this document
2. Implement routes one file at a time (team → billing → integrations)
3. Test each route as you complete it
4. Create frontend components
5. End-to-end testing

Good luck! 🚀
