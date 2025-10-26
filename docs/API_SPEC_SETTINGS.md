# Settings API Specification - Agent Observability Platform

**Version:** 1.0.0
**Last Updated:** 2025-10-25
**Service:** Gateway API (Port 8000)
**Base URL:** `http://localhost:8000/api/v1`

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication & Authorization](#authentication--authorization)
3. [Common Patterns](#common-patterns)
4. [Data Models](#data-models)
5. [Workspace APIs](#workspace-apis)
6. [Team Management APIs](#team-management-apis)
7. [API Keys](#api-keys)
8. [Billing APIs](#billing-apis)
9. [Integrations APIs](#integrations-apis)
10. [Error Handling](#error-handling)
11. [Cache Strategies](#cache-strategies)
12. [RBAC Permission Matrix](#rbac-permission-matrix)
13. [Integration Test Scenarios](#integration-test-scenarios)

---

## Overview

The Settings API provides endpoints for managing workspace configuration, team members, billing, and external integrations for the Agent Observability Platform. All endpoints follow REST principles and use JSON for request/response payloads.

### Service Architecture

- **Gateway Service** (Port 8000): Entry point, authentication, routing
- **Query Service** (Port 8003): Data retrieval and aggregation
- **Evaluation Service** (Port 8004): Metrics and analytics
- Multi-tenant architecture with workspace isolation

### Base URL Structure

```
{base_url}/api/v1/{resource}
```

### Versioning Strategy

- **Method**: URL-based versioning (`/api/v1/`)
- **Deprecation Policy**: 6 months notice for breaking changes
- **Backward Compatibility**: Maintained for 2 major versions
- **Version Header**: `API-Version: 1.0` (optional, informational)

---

## Authentication & Authorization

### Authentication Method

**JWT Bearer Token** (implemented in Gateway service)

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Required Headers

All requests must include:

```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
Content-Type: application/json
```

### JWT Token Claims

```json
{
  "sub": "user_uuid",
  "email": "user@example.com",
  "workspace_id": "ws_uuid",
  "role": "admin",
  "exp": 1735142400,
  "iat": 1735056000
}
```

### RBAC Roles

| Role | Level | Description |
|------|-------|-------------|
| `owner` | 4 | Full workspace access, billing, team management |
| `admin` | 3 | All settings except billing and owner transfers |
| `member` | 2 | Read team info, limited configuration |
| `viewer` | 1 | Read-only access, no modifications |

---

## Common Patterns

### Pagination

All list endpoints support cursor-based pagination:

**Query Parameters:**
```
?limit=20&cursor={base64_encoded_cursor}
```

**Response Structure:**
```json
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJpZCI6MTIzLCJ0aW1lc3RhbXAiOjE3MzUwNTYwMDB9",
    "has_more": true,
    "total_count": 150
  }
}
```

### Filtering

Use query parameters for filtering:

```
?status=active&role=admin&search=john
```

### Sorting

```
?sort=created_at:desc,name:asc
```

### Field Selection

```
?fields=id,name,email,role
```

### Rate Limiting

- **Default**: 100 requests/minute per workspace
- **Burst**: 200 requests/minute
- **Headers Returned**:
  ```
  X-RateLimit-Limit: 100
  X-RateLimit-Remaining: 95
  X-RateLimit-Reset: 1735056060
  ```

### Idempotency

POST/PUT endpoints support idempotency keys:

```http
Idempotency-Key: unique-request-id-123
```

---

## Data Models

### Common Types

```python
from pydantic import BaseModel, Field, EmailStr, HttpUrl
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum
from uuid import UUID

# Enums
class UserRole(str, Enum):
    OWNER = "owner"
    ADMIN = "admin"
    MEMBER = "member"
    VIEWER = "viewer"

class InvitationStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    EXPIRED = "expired"
    CANCELLED = "cancelled"

class BillingPlan(str, Enum):
    FREE = "free"
    STARTER = "starter"
    PROFESSIONAL = "professional"
    ENTERPRISE = "enterprise"

class BillingInterval(str, Enum):
    MONTHLY = "monthly"
    YEARLY = "yearly"

class IntegrationType(str, Enum):
    SLACK = "slack"
    PAGERDUTY = "pagerduty"
    WEBHOOK = "webhook"
    EMAIL = "email"
    DATADOG = "datadog"

class MemberStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"

# Base Response Model
class BaseResponse(BaseModel):
    success: bool = True
    message: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)

# Pagination
class PaginationInfo(BaseModel):
    next_cursor: Optional[str] = None
    has_more: bool = False
    total_count: Optional[int] = None

class PaginatedResponse(BaseResponse):
    pagination: PaginationInfo
```

### Workspace Models

```python
class WorkspaceBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    timezone: str = Field(default="UTC", pattern="^[A-Za-z]+/[A-Za-z_]+$")
    settings: Optional[Dict[str, Any]] = Field(default_factory=dict)

class WorkspaceResponse(WorkspaceBase):
    id: UUID
    owner_id: UUID
    created_at: datetime
    updated_at: datetime
    member_count: int
    plan: BillingPlan

    class Config:
        json_schema_extra = {
            "example": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "name": "Acme Corp Workspace",
                "description": "Production monitoring workspace",
                "timezone": "America/New_York",
                "owner_id": "650e8400-e29b-41d4-a716-446655440000",
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-10-25T14:20:00Z",
                "member_count": 12,
                "plan": "professional",
                "settings": {
                    "default_retention_days": 90,
                    "allow_public_sharing": false
                }
            }
        }

class UpdateWorkspaceRequest(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    timezone: Optional[str] = Field(None, pattern="^[A-Za-z]+/[A-Za-z_]+$")
    settings: Optional[Dict[str, Any]] = None

    class Config:
        json_schema_extra = {
            "example": {
                "name": "Acme Corp - Updated",
                "timezone": "America/Los_Angeles",
                "settings": {
                    "default_retention_days": 120
                }
            }
        }
```

### Team Member Models

```python
class TeamMemberBase(BaseModel):
    email: EmailStr
    role: UserRole
    first_name: Optional[str] = Field(None, max_length=50)
    last_name: Optional[str] = Field(None, max_length=50)

class TeamMemberResponse(TeamMemberBase):
    id: UUID
    workspace_id: UUID
    user_id: UUID
    status: MemberStatus
    last_active_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    invited_by: Optional[UUID] = None

    class Config:
        json_schema_extra = {
            "example": {
                "id": "750e8400-e29b-41d4-a716-446655440000",
                "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
                "user_id": "650e8400-e29b-41d4-a716-446655440000",
                "email": "john.doe@example.com",
                "first_name": "John",
                "last_name": "Doe",
                "role": "admin",
                "status": "active",
                "last_active_at": "2024-10-25T14:15:00Z",
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-10-20T09:45:00Z",
                "invited_by": "650e8400-e29b-41d4-a716-446655440000"
            }
        }

class ListTeamMembersResponse(BaseResponse):
    data: List[TeamMemberResponse]
    pagination: PaginationInfo

class InviteTeamMemberRequest(BaseModel):
    email: EmailStr
    role: UserRole = Field(default=UserRole.MEMBER)
    first_name: Optional[str] = Field(None, max_length=50)
    last_name: Optional[str] = Field(None, max_length=50)
    message: Optional[str] = Field(None, max_length=500)

    class Config:
        json_schema_extra = {
            "example": {
                "email": "jane.smith@example.com",
                "role": "admin",
                "first_name": "Jane",
                "last_name": "Smith",
                "message": "Welcome to our monitoring team!"
            }
        }

class InvitationResponse(BaseModel):
    id: UUID
    workspace_id: UUID
    email: EmailStr
    role: UserRole
    status: InvitationStatus
    token: str
    invited_by: UUID
    expires_at: datetime
    created_at: datetime

    class Config:
        json_schema_extra = {
            "example": {
                "id": "850e8400-e29b-41d4-a716-446655440000",
                "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
                "email": "jane.smith@example.com",
                "role": "admin",
                "status": "pending",
                "token": "inv_AbCdEfGhIjKlMnOpQrStUvWxYz123456",
                "invited_by": "650e8400-e29b-41d4-a716-446655440000",
                "expires_at": "2024-11-01T14:20:00Z",
                "created_at": "2024-10-25T14:20:00Z"
            }
        }

class ListInvitationsResponse(BaseResponse):
    data: List[InvitationResponse]
    pagination: PaginationInfo

class AcceptInvitationRequest(BaseModel):
    first_name: Optional[str] = Field(None, max_length=50)
    last_name: Optional[str] = Field(None, max_length=50)

class UpdateMemberRoleRequest(BaseModel):
    role: UserRole

    class Config:
        json_schema_extra = {
            "example": {
                "role": "admin"
            }
        }
```

### Billing Models

```python
class PlanLimits(BaseModel):
    max_traces_per_month: int
    max_team_members: int
    max_api_keys: int
    data_retention_days: int
    rate_limit_per_minute: int
    custom_integrations: bool
    priority_support: bool
    sla_uptime: Optional[float] = None  # e.g., 99.9

    class Config:
        json_schema_extra = {
            "example": {
                "max_traces_per_month": 1000000,
                "max_team_members": 10,
                "max_api_keys": 5,
                "data_retention_days": 90,
                "rate_limit_per_minute": 100,
                "custom_integrations": true,
                "priority_support": true,
                "sla_uptime": 99.9
            }
        }

class BillingConfigResponse(BaseResponse):
    plan: BillingPlan
    interval: BillingInterval
    limits: PlanLimits
    price_per_month: float
    currency: str = "USD"
    trial_ends_at: Optional[datetime] = None
    subscription_id: Optional[str] = None
    next_billing_date: Optional[datetime] = None
    auto_renew: bool = True

    class Config:
        json_schema_extra = {
            "example": {
                "success": true,
                "plan": "professional",
                "interval": "monthly",
                "limits": {
                    "max_traces_per_month": 1000000,
                    "max_team_members": 10,
                    "max_api_keys": 5,
                    "data_retention_days": 90,
                    "rate_limit_per_minute": 100,
                    "custom_integrations": true,
                    "priority_support": true,
                    "sla_uptime": 99.9
                },
                "price_per_month": 99.00,
                "currency": "USD",
                "trial_ends_at": null,
                "subscription_id": "sub_1234567890",
                "next_billing_date": "2024-11-25T00:00:00Z",
                "auto_renew": true,
                "timestamp": "2024-10-25T14:20:00Z"
            }
        }

class UpdateBillingPlanRequest(BaseModel):
    plan: BillingPlan
    interval: BillingInterval = Field(default=BillingInterval.MONTHLY)

    class Config:
        json_schema_extra = {
            "example": {
                "plan": "enterprise",
                "interval": "yearly"
            }
        }

class UsageStats(BaseModel):
    traces_current_month: int
    traces_limit: int
    traces_percentage: float
    api_calls_today: int
    api_calls_limit: int
    storage_gb: float
    team_members_count: int
    team_members_limit: int
    api_keys_count: int
    api_keys_limit: int
    period_start: datetime
    period_end: datetime

    class Config:
        json_schema_extra = {
            "example": {
                "traces_current_month": 450000,
                "traces_limit": 1000000,
                "traces_percentage": 45.0,
                "api_calls_today": 12500,
                "api_calls_limit": 144000,
                "storage_gb": 45.8,
                "team_members_count": 8,
                "team_members_limit": 10,
                "api_keys_count": 3,
                "api_keys_limit": 5,
                "period_start": "2024-10-01T00:00:00Z",
                "period_end": "2024-10-31T23:59:59Z"
            }
        }

class BillingUsageResponse(BaseResponse):
    usage: UsageStats

class CheckoutSessionRequest(BaseModel):
    plan: BillingPlan
    interval: BillingInterval
    success_url: HttpUrl
    cancel_url: HttpUrl

    class Config:
        json_schema_extra = {
            "example": {
                "plan": "professional",
                "interval": "monthly",
                "success_url": "https://app.example.com/settings/billing?success=true",
                "cancel_url": "https://app.example.com/settings/billing"
            }
        }

class CheckoutSessionResponse(BaseResponse):
    session_id: str
    checkout_url: HttpUrl
    expires_at: datetime

    class Config:
        json_schema_extra = {
            "example": {
                "success": true,
                "session_id": "cs_test_1234567890",
                "checkout_url": "https://checkout.stripe.com/pay/cs_test_1234567890",
                "expires_at": "2024-10-25T15:20:00Z",
                "timestamp": "2024-10-25T14:20:00Z"
            }
        }

class Invoice(BaseModel):
    id: str
    amount: float
    currency: str
    status: str  # paid, pending, failed
    period_start: datetime
    period_end: datetime
    invoice_url: Optional[HttpUrl] = None
    created_at: datetime

    class Config:
        json_schema_extra = {
            "example": {
                "id": "inv_1234567890",
                "amount": 99.00,
                "currency": "USD",
                "status": "paid",
                "period_start": "2024-09-01T00:00:00Z",
                "period_end": "2024-09-30T23:59:59Z",
                "invoice_url": "https://invoice.stripe.com/i/inv_1234567890",
                "created_at": "2024-09-01T00:05:00Z"
            }
        }

class ListInvoicesResponse(BaseResponse):
    data: List[Invoice]
    pagination: PaginationInfo
```

### Integration Models

```python
class SlackConfig(BaseModel):
    webhook_url: HttpUrl
    channel: str = Field(..., pattern="^#[a-z0-9-_]+$")
    notify_on_error: bool = True
    notify_on_alert: bool = True
    mention_users: List[str] = Field(default_factory=list)

class PagerDutyConfig(BaseModel):
    integration_key: str = Field(..., min_length=32, max_length=32)
    severity: str = Field(default="error", pattern="^(critical|error|warning|info)$")
    auto_resolve: bool = True

class WebhookConfig(BaseModel):
    url: HttpUrl
    method: str = Field(default="POST", pattern="^(POST|PUT)$")
    headers: Dict[str, str] = Field(default_factory=dict)
    events: List[str] = Field(default_factory=list)
    secret: Optional[str] = None  # For HMAC signature verification

class EmailConfig(BaseModel):
    recipients: List[EmailStr] = Field(..., min_items=1)
    notify_on_error: bool = True
    notify_on_alert: bool = True
    daily_digest: bool = False

class DatadogConfig(BaseModel):
    api_key: str = Field(..., min_length=32, max_length=40)
    app_key: str = Field(..., min_length=32, max_length=40)
    site: str = Field(default="datadoghq.com")
    service: str = Field(..., min_length=1)

class IntegrationConfigBase(BaseModel):
    type: IntegrationType
    enabled: bool = True
    config: Dict[str, Any]  # Type-specific configuration
    name: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = Field(None, max_length=500)

class IntegrationConfigResponse(IntegrationConfigBase):
    id: UUID
    workspace_id: UUID
    last_tested_at: Optional[datetime] = None
    last_test_status: Optional[str] = None  # success, failed
    last_test_message: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        json_schema_extra = {
            "example": {
                "id": "950e8400-e29b-41d4-a716-446655440000",
                "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
                "type": "slack",
                "enabled": true,
                "name": "Engineering Alerts",
                "description": "Slack notifications for production errors",
                "config": {
                    "webhook_url": "https://hooks.slack.com/services/T00/B00/XXX",
                    "channel": "#alerts",
                    "notify_on_error": true,
                    "notify_on_alert": true,
                    "mention_users": ["@john", "@jane"]
                },
                "last_tested_at": "2024-10-25T14:15:00Z",
                "last_test_status": "success",
                "last_test_message": "Test notification sent successfully",
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-10-25T14:15:00Z"
            }
        }

class ListIntegrationsResponse(BaseResponse):
    data: List[IntegrationConfigResponse]

class UpdateIntegrationRequest(BaseModel):
    enabled: Optional[bool] = None
    config: Optional[Dict[str, Any]] = None
    name: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = Field(None, max_length=500)

    class Config:
        json_schema_extra = {
            "example": {
                "enabled": true,
                "name": "Updated Slack Integration",
                "config": {
                    "webhook_url": "https://hooks.slack.com/services/T00/B00/YYY",
                    "channel": "#production-alerts",
                    "notify_on_error": true
                }
            }
        }

class TestIntegrationResponse(BaseResponse):
    test_successful: bool
    response_time_ms: int
    details: Optional[str] = None

    class Config:
        json_schema_extra = {
            "example": {
                "success": true,
                "test_successful": true,
                "response_time_ms": 245,
                "details": "Test message delivered to #alerts channel",
                "timestamp": "2024-10-25T14:20:00Z"
            }
        }
```

---

## Workspace APIs

### Get Workspace Details

Retrieve current workspace information including configuration and metadata.

**Endpoint:** `GET /api/v1/workspace`

**Required Permission:** `member` (all roles)

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
```

**Response:** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Acme Corp Workspace",
    "description": "Production monitoring workspace",
    "timezone": "America/New_York",
    "owner_id": "650e8400-e29b-41d4-a716-446655440000",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-10-25T14:20:00Z",
    "member_count": 12,
    "plan": "professional",
    "settings": {
      "default_retention_days": 90,
      "allow_public_sharing": false
    }
  },
  "timestamp": "2024-10-25T14:20:00Z"
}
```

**Cache Strategy:**
- **Key Pattern:** `workspace:{workspace_id}:details`
- **TTL:** 5 minutes
- **Invalidation:** On workspace update

**Error Responses:**

```json
// 404 Not Found
{
  "success": false,
  "error": {
    "code": "WORKSPACE_NOT_FOUND",
    "message": "Workspace not found",
    "details": null
  },
  "timestamp": "2024-10-25T14:20:00Z"
}
```

---

### Update Workspace

Update workspace configuration settings.

**Endpoint:** `PUT /api/v1/workspace`

**Required Permission:** `admin`

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
Content-Type: application/json
```

**Request Body:**

```json
{
  "name": "Acme Corp - Updated",
  "timezone": "America/Los_Angeles",
  "settings": {
    "default_retention_days": 120,
    "allow_public_sharing": false
  }
}
```

**Response:** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Acme Corp - Updated",
    "description": "Production monitoring workspace",
    "timezone": "America/Los_Angeles",
    "owner_id": "650e8400-e29b-41d4-a716-446655440000",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-10-25T14:25:00Z",
    "member_count": 12,
    "plan": "professional",
    "settings": {
      "default_retention_days": 120,
      "allow_public_sharing": false
    }
  },
  "message": "Workspace updated successfully",
  "timestamp": "2024-10-25T14:25:00Z"
}
```

**Cache Strategy:**
- **Invalidate:** `workspace:{workspace_id}:details`
- **Invalidate:** `workspace:{workspace_id}:*` (all related caches)

**Error Responses:**

```json
// 400 Bad Request - Validation Error
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request data",
    "details": {
      "timezone": ["Invalid timezone format. Expected: 'Region/City'"]
    }
  },
  "timestamp": "2024-10-25T14:25:00Z"
}

// 403 Forbidden
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_PERMISSIONS",
    "message": "Admin role required to update workspace settings",
    "details": {
      "required_role": "admin",
      "current_role": "member"
    }
  },
  "timestamp": "2024-10-25T14:25:00Z"
}
```

---

## Team Management APIs

### List Team Members

Retrieve all team members with optional filtering and pagination.

**Endpoint:** `GET /api/v1/team/members`

**Required Permission:** `member` (all roles)

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
```

**Query Parameters:**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `limit` | integer | No | Results per page (1-100) | `20` |
| `cursor` | string | No | Pagination cursor | `eyJpZCI6MTIzfQ==` |
| `status` | string | No | Filter by status: `active`, `inactive`, `suspended` | `active` |
| `role` | string | No | Filter by role: `owner`, `admin`, `member`, `viewer` | `admin` |
| `search` | string | No | Search by name or email | `john` |
| `sort` | string | No | Sort fields | `created_at:desc` |

**Example Request:**

```http
GET /api/v1/team/members?limit=20&status=active&role=admin&sort=created_at:desc
```

**Response:** `200 OK`

```json
{
  "success": true,
  "data": [
    {
      "id": "750e8400-e29b-41d4-a716-446655440000",
      "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
      "user_id": "650e8400-e29b-41d4-a716-446655440000",
      "email": "john.doe@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "role": "admin",
      "status": "active",
      "last_active_at": "2024-10-25T14:15:00Z",
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-10-20T09:45:00Z",
      "invited_by": "650e8400-e29b-41d4-a716-446655440000"
    },
    {
      "id": "760e8400-e29b-41d4-a716-446655440000",
      "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
      "user_id": "660e8400-e29b-41d4-a716-446655440000",
      "email": "jane.smith@example.com",
      "first_name": "Jane",
      "last_name": "Smith",
      "role": "admin",
      "status": "active",
      "last_active_at": "2024-10-25T13:45:00Z",
      "created_at": "2024-02-10T14:20:00Z",
      "updated_at": "2024-10-15T11:30:00Z",
      "invited_by": "650e8400-e29b-41d4-a716-446655440000"
    }
  ],
  "pagination": {
    "next_cursor": "eyJpZCI6Ijc2MGU4NDAwLWUyOWItNDFkNC1hNzE2LTQ0NjY1NTQ0MDAwMCJ9",
    "has_more": true,
    "total_count": 12
  },
  "timestamp": "2024-10-25T14:20:00Z"
}
```

**Cache Strategy:**
- **Key Pattern:** `workspace:{workspace_id}:team:members:{hash(params)}`
- **TTL:** 2 minutes
- **Invalidation:** On member add/update/remove

**Error Responses:**

```json
// 400 Bad Request
{
  "success": false,
  "error": {
    "code": "INVALID_QUERY_PARAMETER",
    "message": "Invalid query parameter",
    "details": {
      "role": ["Invalid role. Must be one of: owner, admin, member, viewer"]
    }
  },
  "timestamp": "2024-10-25T14:20:00Z"
}
```

---

### Invite Team Member

Send an invitation email to a new team member.

**Endpoint:** `POST /api/v1/team/invite`

**Required Permission:** `admin`

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
Content-Type: application/json
Idempotency-Key: inv-{unique-id}
```

**Request Body:**

```json
{
  "email": "jane.smith@example.com",
  "role": "admin",
  "first_name": "Jane",
  "last_name": "Smith",
  "message": "Welcome to our monitoring team!"
}
```

**Response:** `201 Created`

```json
{
  "success": true,
  "data": {
    "id": "850e8400-e29b-41d4-a716-446655440000",
    "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "jane.smith@example.com",
    "role": "admin",
    "status": "pending",
    "token": "inv_AbCdEfGhIjKlMnOpQrStUvWxYz123456",
    "invited_by": "650e8400-e29b-41d4-a716-446655440000",
    "expires_at": "2024-11-01T14:20:00Z",
    "created_at": "2024-10-25T14:20:00Z"
  },
  "message": "Invitation sent successfully",
  "timestamp": "2024-10-25T14:20:00Z"
}
```

**Cache Strategy:**
- **Invalidate:** `workspace:{workspace_id}:team:invitations`
- **Invalidate:** `workspace:{workspace_id}:team:members:*`

**Error Responses:**

```json
// 400 Bad Request - Invalid Email
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request data",
    "details": {
      "email": ["Invalid email address format"]
    }
  },
  "timestamp": "2024-10-25T14:20:00Z"
}

// 403 Forbidden - Cannot Invite Owner
{
  "success": false,
  "error": {
    "code": "INVALID_ROLE",
    "message": "Cannot invite members with owner role",
    "details": {
      "allowed_roles": ["admin", "member", "viewer"]
    }
  },
  "timestamp": "2024-10-25T14:20:00Z"
}

// 409 Conflict - Already Member
{
  "success": false,
  "error": {
    "code": "MEMBER_ALREADY_EXISTS",
    "message": "User is already a member of this workspace",
    "details": {
      "email": "jane.smith@example.com",
      "existing_member_id": "760e8400-e29b-41d4-a716-446655440000"
    }
  },
  "timestamp": "2024-10-25T14:20:00Z"
}

// 409 Conflict - Pending Invitation
{
  "success": false,
  "error": {
    "code": "INVITATION_ALREADY_PENDING",
    "message": "An invitation for this email is already pending",
    "details": {
      "email": "jane.smith@example.com",
      "invitation_id": "850e8400-e29b-41d4-a716-446655440000",
      "expires_at": "2024-11-01T14:20:00Z"
    }
  },
  "timestamp": "2024-10-25T14:20:00Z"
}

// 422 Unprocessable Entity - Team Limit Reached
{
  "success": false,
  "error": {
    "code": "TEAM_LIMIT_REACHED",
    "message": "Team member limit reached for current plan",
    "details": {
      "current_count": 10,
      "limit": 10,
      "plan": "professional",
      "upgrade_url": "/settings/billing"
    }
  },
  "timestamp": "2024-10-25T14:20:00Z"
}
```

---

### List Pending Invitations

Retrieve all pending invitations for the workspace.

**Endpoint:** `GET /api/v1/team/invitations`

**Required Permission:** `admin`

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
```

**Query Parameters:**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `limit` | integer | No | Results per page (1-100) | `20` |
| `cursor` | string | No | Pagination cursor | `eyJpZCI6MTIzfQ==` |
| `status` | string | No | Filter by status: `pending`, `expired`, `cancelled` | `pending` |

**Response:** `200 OK`

```json
{
  "success": true,
  "data": [
    {
      "id": "850e8400-e29b-41d4-a716-446655440000",
      "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "jane.smith@example.com",
      "role": "admin",
      "status": "pending",
      "token": "inv_AbCdEfGhIjKlMnOpQrStUvWxYz123456",
      "invited_by": "650e8400-e29b-41d4-a716-446655440000",
      "expires_at": "2024-11-01T14:20:00Z",
      "created_at": "2024-10-25T14:20:00Z"
    }
  ],
  "pagination": {
    "next_cursor": null,
    "has_more": false,
    "total_count": 1
  },
  "timestamp": "2024-10-25T14:25:00Z"
}
```

**Cache Strategy:**
- **Key Pattern:** `workspace:{workspace_id}:team:invitations`
- **TTL:** 2 minutes
- **Invalidation:** On invitation create/cancel/accept

---

### Accept Invitation

Accept a team invitation and join the workspace.

**Endpoint:** `POST /api/v1/team/invitations/{token}/accept`

**Required Permission:** None (public endpoint with token authentication)

**Request Headers:**
```http
Content-Type: application/json
```

**Path Parameters:**
- `token` (string, required): Invitation token (e.g., `inv_AbCdEfGhIjKlMnOpQrStUvWxYz123456`)

**Request Body:**

```json
{
  "first_name": "Jane",
  "last_name": "Smith"
}
```

**Response:** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": "760e8400-e29b-41d4-a716-446655440000",
    "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
    "user_id": "660e8400-e29b-41d4-a716-446655440000",
    "email": "jane.smith@example.com",
    "first_name": "Jane",
    "last_name": "Smith",
    "role": "admin",
    "status": "active",
    "last_active_at": "2024-10-25T14:30:00Z",
    "created_at": "2024-10-25T14:30:00Z",
    "updated_at": "2024-10-25T14:30:00Z",
    "invited_by": "650e8400-e29b-41d4-a716-446655440000"
  },
  "message": "Invitation accepted successfully",
  "timestamp": "2024-10-25T14:30:00Z"
}
```

**Cache Strategy:**
- **Invalidate:** `workspace:{workspace_id}:team:invitations`
- **Invalidate:** `workspace:{workspace_id}:team:members:*`
- **Invalidate:** `workspace:{workspace_id}:details` (member count update)

**Error Responses:**

```json
// 404 Not Found
{
  "success": false,
  "error": {
    "code": "INVITATION_NOT_FOUND",
    "message": "Invitation not found or invalid",
    "details": null
  },
  "timestamp": "2024-10-25T14:30:00Z"
}

// 409 Conflict - Already Accepted
{
  "success": false,
  "error": {
    "code": "INVITATION_ALREADY_ACCEPTED",
    "message": "This invitation has already been accepted",
    "details": {
      "accepted_at": "2024-10-20T10:15:00Z"
    }
  },
  "timestamp": "2024-10-25T14:30:00Z"
}

// 410 Gone - Expired
{
  "success": false,
  "error": {
    "code": "INVITATION_EXPIRED",
    "message": "This invitation has expired",
    "details": {
      "expired_at": "2024-10-20T14:20:00Z"
    }
  },
  "timestamp": "2024-10-25T14:30:00Z"
}
```

---

### Cancel Invitation

Cancel a pending invitation.

**Endpoint:** `DELETE /api/v1/team/invitations/{id}`

**Required Permission:** `admin`

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
```

**Path Parameters:**
- `id` (UUID, required): Invitation ID

**Response:** `200 OK`

```json
{
  "success": true,
  "message": "Invitation cancelled successfully",
  "timestamp": "2024-10-25T14:35:00Z"
}
```

**Cache Strategy:**
- **Invalidate:** `workspace:{workspace_id}:team:invitations`

**Error Responses:**

```json
// 404 Not Found
{
  "success": false,
  "error": {
    "code": "INVITATION_NOT_FOUND",
    "message": "Invitation not found",
    "details": null
  },
  "timestamp": "2024-10-25T14:35:00Z"
}

// 409 Conflict
{
  "success": false,
  "error": {
    "code": "INVITATION_ALREADY_ACCEPTED",
    "message": "Cannot cancel an invitation that has already been accepted",
    "details": {
      "status": "accepted",
      "accepted_at": "2024-10-20T10:15:00Z"
    }
  },
  "timestamp": "2024-10-25T14:35:00Z"
}
```

---

### Update Member Role

Update a team member's role.

**Endpoint:** `PUT /api/v1/team/members/{id}/role`

**Required Permission:** `admin` (cannot modify owner, only owner can transfer ownership)

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
Content-Type: application/json
```

**Path Parameters:**
- `id` (UUID, required): Team member ID

**Request Body:**

```json
{
  "role": "member"
}
```

**Response:** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": "760e8400-e29b-41d4-a716-446655440000",
    "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
    "user_id": "660e8400-e29b-41d4-a716-446655440000",
    "email": "jane.smith@example.com",
    "first_name": "Jane",
    "last_name": "Smith",
    "role": "member",
    "status": "active",
    "last_active_at": "2024-10-25T13:45:00Z",
    "created_at": "2024-02-10T14:20:00Z",
    "updated_at": "2024-10-25T14:40:00Z",
    "invited_by": "650e8400-e29b-41d4-a716-446655440000"
  },
  "message": "Member role updated successfully",
  "timestamp": "2024-10-25T14:40:00Z"
}
```

**Cache Strategy:**
- **Invalidate:** `workspace:{workspace_id}:team:members:*`
- **Invalidate:** `user:{user_id}:permissions`

**Error Responses:**

```json
// 403 Forbidden - Cannot Modify Owner
{
  "success": false,
  "error": {
    "code": "CANNOT_MODIFY_OWNER",
    "message": "Cannot modify workspace owner role",
    "details": {
      "required_action": "Transfer ownership to change owner role"
    }
  },
  "timestamp": "2024-10-25T14:40:00Z"
}

// 403 Forbidden - Cannot Assign Owner
{
  "success": false,
  "error": {
    "code": "CANNOT_ASSIGN_OWNER_ROLE",
    "message": "Only workspace owner can transfer ownership",
    "details": {
      "required_role": "owner",
      "current_role": "admin"
    }
  },
  "timestamp": "2024-10-25T14:40:00Z"
}

// 404 Not Found
{
  "success": false,
  "error": {
    "code": "MEMBER_NOT_FOUND",
    "message": "Team member not found",
    "details": null
  },
  "timestamp": "2024-10-25T14:40:00Z"
}

// 409 Conflict - Self Demotion
{
  "success": false,
  "error": {
    "code": "CANNOT_DEMOTE_SELF",
    "message": "Cannot modify your own role",
    "details": {
      "suggestion": "Ask another admin to change your role"
    }
  },
  "timestamp": "2024-10-25T14:40:00Z"
}
```

---

### Remove Team Member

Remove a team member from the workspace (soft delete).

**Endpoint:** `DELETE /api/v1/team/members/{id}`

**Required Permission:** `admin` (cannot remove owner)

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
```

**Path Parameters:**
- `id` (UUID, required): Team member ID

**Response:** `200 OK`

```json
{
  "success": true,
  "message": "Team member removed successfully",
  "timestamp": "2024-10-25T14:45:00Z"
}
```

**Cache Strategy:**
- **Invalidate:** `workspace:{workspace_id}:team:members:*`
- **Invalidate:** `workspace:{workspace_id}:details` (member count update)
- **Invalidate:** `user:{user_id}:workspaces`

**Error Responses:**

```json
// 403 Forbidden - Cannot Remove Owner
{
  "success": false,
  "error": {
    "code": "CANNOT_REMOVE_OWNER",
    "message": "Cannot remove workspace owner",
    "details": {
      "required_action": "Transfer ownership before removing"
    }
  },
  "timestamp": "2024-10-25T14:45:00Z"
}

// 403 Forbidden - Self Removal
{
  "success": false,
  "error": {
    "code": "CANNOT_REMOVE_SELF",
    "message": "Cannot remove yourself from workspace",
    "details": {
      "suggestion": "Ask another admin to remove you"
    }
  },
  "timestamp": "2024-10-25T14:45:00Z"
}

// 404 Not Found
{
  "success": false,
  "error": {
    "code": "MEMBER_NOT_FOUND",
    "message": "Team member not found",
    "details": null
  },
  "timestamp": "2024-10-25T14:45:00Z"
}
```

---

### Reactivate Team Member

Reactivate a previously removed team member.

**Endpoint:** `POST /api/v1/team/members/{id}/reactivate`

**Required Permission:** `admin`

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
```

**Path Parameters:**
- `id` (UUID, required): Team member ID

**Response:** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": "760e8400-e29b-41d4-a716-446655440000",
    "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
    "user_id": "660e8400-e29b-41d4-a716-446655440000",
    "email": "jane.smith@example.com",
    "first_name": "Jane",
    "last_name": "Smith",
    "role": "member",
    "status": "active",
    "last_active_at": null,
    "created_at": "2024-02-10T14:20:00Z",
    "updated_at": "2024-10-25T14:50:00Z",
    "invited_by": "650e8400-e29b-41d4-a716-446655440000"
  },
  "message": "Team member reactivated successfully",
  "timestamp": "2024-10-25T14:50:00Z"
}
```

**Cache Strategy:**
- **Invalidate:** `workspace:{workspace_id}:team:members:*`
- **Invalidate:** `workspace:{workspace_id}:details` (member count update)

**Error Responses:**

```json
// 404 Not Found
{
  "success": false,
  "error": {
    "code": "MEMBER_NOT_FOUND",
    "message": "Team member not found",
    "details": null
  },
  "timestamp": "2024-10-25T14:50:00Z"
}

// 409 Conflict
{
  "success": false,
  "error": {
    "code": "MEMBER_ALREADY_ACTIVE",
    "message": "Team member is already active",
    "details": {
      "status": "active"
    }
  },
  "timestamp": "2024-10-25T14:50:00Z"
}

// 422 Unprocessable Entity
{
  "success": false,
  "error": {
    "code": "TEAM_LIMIT_REACHED",
    "message": "Team member limit reached for current plan",
    "details": {
      "current_count": 10,
      "limit": 10,
      "plan": "professional"
    }
  },
  "timestamp": "2024-10-25T14:50:00Z"
}
```

---

## API Keys

**Note:** API Key management endpoints already exist in the Gateway service. Reference the existing implementation at:

- `GET /api/v1/api-keys` - List API keys
- `POST /api/v1/api-keys` - Create new API key
- `DELETE /api/v1/api-keys/{id}` - Revoke API key
- `PUT /api/v1/api-keys/{id}` - Update API key metadata

For consistency with the Settings page, ensure these endpoints:
1. Enforce the same RBAC rules (`admin` role required)
2. Respect plan limits for max API keys
3. Use the same cache invalidation patterns
4. Follow the error response format defined in this spec

---

## Billing APIs

### Get Billing Configuration

Retrieve current billing plan, limits, and subscription details.

**Endpoint:** `GET /api/v1/billing/config`

**Required Permission:** `admin`

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
```

**Response:** `200 OK`

```json
{
  "success": true,
  "plan": "professional",
  "interval": "monthly",
  "limits": {
    "max_traces_per_month": 1000000,
    "max_team_members": 10,
    "max_api_keys": 5,
    "data_retention_days": 90,
    "rate_limit_per_minute": 100,
    "custom_integrations": true,
    "priority_support": true,
    "sla_uptime": 99.9
  },
  "price_per_month": 99.00,
  "currency": "USD",
  "trial_ends_at": null,
  "subscription_id": "sub_1234567890",
  "next_billing_date": "2024-11-25T00:00:00Z",
  "auto_renew": true,
  "timestamp": "2024-10-25T14:20:00Z"
}
```

**Cache Strategy:**
- **Key Pattern:** `workspace:{workspace_id}:billing:config`
- **TTL:** 10 minutes
- **Invalidation:** On plan update, subscription change

**Error Responses:**

```json
// 403 Forbidden
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_PERMISSIONS",
    "message": "Admin role required to view billing information",
    "details": {
      "required_role": "admin",
      "current_role": "member"
    }
  },
  "timestamp": "2024-10-25T14:20:00Z"
}
```

---

### Update Billing Plan

Update subscription plan and billing interval.

**Endpoint:** `PUT /api/v1/billing/plan`

**Required Permission:** `owner`

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
Content-Type: application/json
```

**Request Body:**

```json
{
  "plan": "enterprise",
  "interval": "yearly"
}
```

**Response:** `200 OK`

```json
{
  "success": true,
  "plan": "enterprise",
  "interval": "yearly",
  "limits": {
    "max_traces_per_month": 10000000,
    "max_team_members": 50,
    "max_api_keys": 20,
    "data_retention_days": 365,
    "rate_limit_per_minute": 500,
    "custom_integrations": true,
    "priority_support": true,
    "sla_uptime": 99.99
  },
  "price_per_month": 416.67,
  "currency": "USD",
  "trial_ends_at": null,
  "subscription_id": "sub_1234567890",
  "next_billing_date": "2025-10-25T00:00:00Z",
  "auto_renew": true,
  "message": "Billing plan updated successfully. Changes will take effect immediately.",
  "timestamp": "2024-10-25T15:00:00Z"
}
```

**Cache Strategy:**
- **Invalidate:** `workspace:{workspace_id}:billing:config`
- **Invalidate:** `workspace:{workspace_id}:billing:usage`
- **Invalidate:** `workspace:{workspace_id}:details`

**Error Responses:**

```json
// 403 Forbidden
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_PERMISSIONS",
    "message": "Owner role required to update billing plan",
    "details": {
      "required_role": "owner",
      "current_role": "admin"
    }
  },
  "timestamp": "2024-10-25T15:00:00Z"
}

// 400 Bad Request - Invalid Downgrade
{
  "success": false,
  "error": {
    "code": "INVALID_PLAN_DOWNGRADE",
    "message": "Cannot downgrade to this plan due to current usage",
    "details": {
      "requested_plan": "starter",
      "current_plan": "professional",
      "blockers": [
        {
          "limit": "max_team_members",
          "current_value": 12,
          "new_limit": 5,
          "action_required": "Remove 7 team members before downgrading"
        },
        {
          "limit": "max_api_keys",
          "current_value": 7,
          "new_limit": 3,
          "action_required": "Revoke 4 API keys before downgrading"
        }
      ]
    }
  },
  "timestamp": "2024-10-25T15:00:00Z"
}

// 402 Payment Required
{
  "success": false,
  "error": {
    "code": "PAYMENT_METHOD_REQUIRED",
    "message": "Valid payment method required to upgrade plan",
    "details": {
      "checkout_url": "/settings/billing/checkout"
    }
  },
  "timestamp": "2024-10-25T15:00:00Z"
}
```

---

### Get Billing Usage

Retrieve current usage statistics against plan limits.

**Endpoint:** `GET /api/v1/billing/usage`

**Required Permission:** `admin`

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
```

**Query Parameters:**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `period` | string | No | Time period: `current`, `previous`, `custom` | `current` |
| `start_date` | string | No | Start date (ISO 8601) for custom period | `2024-10-01` |
| `end_date` | string | No | End date (ISO 8601) for custom period | `2024-10-31` |

**Response:** `200 OK`

```json
{
  "success": true,
  "usage": {
    "traces_current_month": 450000,
    "traces_limit": 1000000,
    "traces_percentage": 45.0,
    "api_calls_today": 12500,
    "api_calls_limit": 144000,
    "storage_gb": 45.8,
    "team_members_count": 8,
    "team_members_limit": 10,
    "api_keys_count": 3,
    "api_keys_limit": 5,
    "period_start": "2024-10-01T00:00:00Z",
    "period_end": "2024-10-31T23:59:59Z"
  },
  "timestamp": "2024-10-25T15:05:00Z"
}
```

**Cache Strategy:**
- **Key Pattern:** `workspace:{workspace_id}:billing:usage:{period}`
- **TTL:** 5 minutes
- **Invalidation:** None (time-based expiry)

**Error Responses:**

```json
// 400 Bad Request
{
  "success": false,
  "error": {
    "code": "INVALID_DATE_RANGE",
    "message": "Invalid date range for custom period",
    "details": {
      "start_date": "Must be before end_date",
      "max_range_days": 365
    }
  },
  "timestamp": "2024-10-25T15:05:00Z"
}
```

---

### Create Checkout Session

Create a Stripe checkout session for plan upgrades.

**Endpoint:** `POST /api/v1/billing/checkout`

**Required Permission:** `owner`

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
Content-Type: application/json
```

**Request Body:**

```json
{
  "plan": "professional",
  "interval": "monthly",
  "success_url": "https://app.example.com/settings/billing?success=true",
  "cancel_url": "https://app.example.com/settings/billing"
}
```

**Response:** `201 Created`

```json
{
  "success": true,
  "session_id": "cs_test_1234567890",
  "checkout_url": "https://checkout.stripe.com/pay/cs_test_1234567890",
  "expires_at": "2024-10-25T16:10:00Z",
  "timestamp": "2024-10-25T15:10:00Z"
}
```

**Cache Strategy:**
- No caching (one-time use session)

**Error Responses:**

```json
// 403 Forbidden
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_PERMISSIONS",
    "message": "Owner role required to manage billing",
    "details": {
      "required_role": "owner",
      "current_role": "admin"
    }
  },
  "timestamp": "2024-10-25T15:10:00Z"
}

// 400 Bad Request
{
  "success": false,
  "error": {
    "code": "INVALID_PLAN_SELECTION",
    "message": "Cannot create checkout for current plan",
    "details": {
      "current_plan": "professional",
      "requested_plan": "professional"
    }
  },
  "timestamp": "2024-10-25T15:10:00Z"
}

// 500 Internal Server Error
{
  "success": false,
  "error": {
    "code": "PAYMENT_PROVIDER_ERROR",
    "message": "Failed to create checkout session",
    "details": {
      "provider": "stripe",
      "error": "Unable to communicate with payment provider"
    }
  },
  "timestamp": "2024-10-25T15:10:00Z"
}
```

---

### List Billing Invoices

Retrieve billing history and invoices.

**Endpoint:** `GET /api/v1/billing/invoices`

**Required Permission:** `owner`

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
```

**Query Parameters:**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `limit` | integer | No | Results per page (1-100) | `20` |
| `cursor` | string | No | Pagination cursor | `eyJpZCI6MTIzfQ==` |
| `status` | string | No | Filter by status: `paid`, `pending`, `failed` | `paid` |

**Response:** `200 OK`

```json
{
  "success": true,
  "data": [
    {
      "id": "inv_1234567890",
      "amount": 99.00,
      "currency": "USD",
      "status": "paid",
      "period_start": "2024-09-01T00:00:00Z",
      "period_end": "2024-09-30T23:59:59Z",
      "invoice_url": "https://invoice.stripe.com/i/inv_1234567890",
      "created_at": "2024-09-01T00:05:00Z"
    },
    {
      "id": "inv_0987654321",
      "amount": 99.00,
      "currency": "USD",
      "status": "paid",
      "period_start": "2024-08-01T00:00:00Z",
      "period_end": "2024-08-31T23:59:59Z",
      "invoice_url": "https://invoice.stripe.com/i/inv_0987654321",
      "created_at": "2024-08-01T00:05:00Z"
    }
  ],
  "pagination": {
    "next_cursor": "eyJpZCI6Imludl8wOTg3NjU0MzIxIn0=",
    "has_more": true,
    "total_count": 24
  },
  "timestamp": "2024-10-25T15:15:00Z"
}
```

**Cache Strategy:**
- **Key Pattern:** `workspace:{workspace_id}:billing:invoices:{hash(params)}`
- **TTL:** 30 minutes
- **Invalidation:** On new invoice (webhook-triggered)

**Error Responses:**

```json
// 403 Forbidden
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_PERMISSIONS",
    "message": "Owner role required to view billing invoices",
    "details": {
      "required_role": "owner",
      "current_role": "admin"
    }
  },
  "timestamp": "2024-10-25T15:15:00Z"
}
```

---

## Integrations APIs

### List All Integrations

Retrieve all integration configurations for the workspace.

**Endpoint:** `GET /api/v1/integrations`

**Required Permission:** `admin`

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
```

**Query Parameters:**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `enabled` | boolean | No | Filter by enabled status | `true` |
| `type` | string | No | Filter by integration type | `slack` |

**Response:** `200 OK`

```json
{
  "success": true,
  "data": [
    {
      "id": "950e8400-e29b-41d4-a716-446655440000",
      "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
      "type": "slack",
      "enabled": true,
      "name": "Engineering Alerts",
      "description": "Slack notifications for production errors",
      "config": {
        "webhook_url": "https://hooks.slack.com/services/T00/B00/XXX",
        "channel": "#alerts",
        "notify_on_error": true,
        "notify_on_alert": true,
        "mention_users": ["@john", "@jane"]
      },
      "last_tested_at": "2024-10-25T14:15:00Z",
      "last_test_status": "success",
      "last_test_message": "Test notification sent successfully",
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-10-25T14:15:00Z"
    },
    {
      "id": "960e8400-e29b-41d4-a716-446655440000",
      "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
      "type": "pagerduty",
      "enabled": true,
      "name": "On-Call Incidents",
      "description": "PagerDuty integration for critical alerts",
      "config": {
        "integration_key": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
        "severity": "error",
        "auto_resolve": true
      },
      "last_tested_at": "2024-10-20T09:30:00Z",
      "last_test_status": "success",
      "last_test_message": "Test incident created successfully",
      "created_at": "2024-02-01T11:00:00Z",
      "updated_at": "2024-10-20T09:30:00Z"
    }
  ],
  "timestamp": "2024-10-25T15:20:00Z"
}
```

**Cache Strategy:**
- **Key Pattern:** `workspace:{workspace_id}:integrations:list`
- **TTL:** 5 minutes
- **Invalidation:** On integration create/update/delete

---

### Get Specific Integration

Retrieve configuration for a specific integration type.

**Endpoint:** `GET /api/v1/integrations/{type}`

**Required Permission:** `admin`

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
```

**Path Parameters:**
- `type` (string, required): Integration type (`slack`, `pagerduty`, `webhook`, `email`, `datadog`)

**Response:** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": "950e8400-e29b-41d4-a716-446655440000",
    "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
    "type": "slack",
    "enabled": true,
    "name": "Engineering Alerts",
    "description": "Slack notifications for production errors",
    "config": {
      "webhook_url": "https://hooks.slack.com/services/T00/B00/XXX",
      "channel": "#alerts",
      "notify_on_error": true,
      "notify_on_alert": true,
      "mention_users": ["@john", "@jane"]
    },
    "last_tested_at": "2024-10-25T14:15:00Z",
    "last_test_status": "success",
    "last_test_message": "Test notification sent successfully",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-10-25T14:15:00Z"
  },
  "timestamp": "2024-10-25T15:25:00Z"
}
```

**Cache Strategy:**
- **Key Pattern:** `workspace:{workspace_id}:integration:{type}`
- **TTL:** 5 minutes
- **Invalidation:** On integration update

**Error Responses:**

```json
// 404 Not Found
{
  "success": false,
  "error": {
    "code": "INTEGRATION_NOT_FOUND",
    "message": "Integration configuration not found",
    "details": {
      "type": "slack"
    }
  },
  "timestamp": "2024-10-25T15:25:00Z"
}

// 400 Bad Request
{
  "success": false,
  "error": {
    "code": "INVALID_INTEGRATION_TYPE",
    "message": "Invalid integration type",
    "details": {
      "type": "invalid_type",
      "allowed_types": ["slack", "pagerduty", "webhook", "email", "datadog"]
    }
  },
  "timestamp": "2024-10-25T15:25:00Z"
}
```

---

### Update Integration Configuration

Update or create an integration configuration.

**Endpoint:** `PUT /api/v1/integrations/{type}`

**Required Permission:** `admin`

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
Content-Type: application/json
```

**Path Parameters:**
- `type` (string, required): Integration type

**Request Body (Slack Example):**

```json
{
  "enabled": true,
  "name": "Updated Slack Integration",
  "description": "Production alerts and notifications",
  "config": {
    "webhook_url": "https://hooks.slack.com/services/T00/B00/YYY",
    "channel": "#production-alerts",
    "notify_on_error": true,
    "notify_on_alert": true,
    "mention_users": ["@oncall", "@team-lead"]
  }
}
```

**Request Body (PagerDuty Example):**

```json
{
  "enabled": true,
  "name": "Critical Incident Alerts",
  "config": {
    "integration_key": "x1y2z3a4b5c6d7e8f9g0h1i2j3k4l5m6",
    "severity": "critical",
    "auto_resolve": true
  }
}
```

**Request Body (Webhook Example):**

```json
{
  "enabled": true,
  "name": "Custom Webhook Integration",
  "config": {
    "url": "https://api.example.com/webhooks/alerts",
    "method": "POST",
    "headers": {
      "Authorization": "Bearer token123",
      "X-Custom-Header": "value"
    },
    "events": ["error", "alert", "anomaly"],
    "secret": "webhook_secret_for_hmac"
  }
}
```

**Response:** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": "950e8400-e29b-41d4-a716-446655440000",
    "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
    "type": "slack",
    "enabled": true,
    "name": "Updated Slack Integration",
    "description": "Production alerts and notifications",
    "config": {
      "webhook_url": "https://hooks.slack.com/services/T00/B00/YYY",
      "channel": "#production-alerts",
      "notify_on_error": true,
      "notify_on_alert": true,
      "mention_users": ["@oncall", "@team-lead"]
    },
    "last_tested_at": "2024-10-25T14:15:00Z",
    "last_test_status": "success",
    "last_test_message": "Test notification sent successfully",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-10-25T15:30:00Z"
  },
  "message": "Integration updated successfully",
  "timestamp": "2024-10-25T15:30:00Z"
}
```

**Cache Strategy:**
- **Invalidate:** `workspace:{workspace_id}:integration:{type}`
- **Invalidate:** `workspace:{workspace_id}:integrations:list`

**Error Responses:**

```json
// 400 Bad Request - Invalid Configuration
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid integration configuration",
    "details": {
      "config.webhook_url": ["Invalid URL format"],
      "config.channel": ["Channel name must start with #"]
    }
  },
  "timestamp": "2024-10-25T15:30:00Z"
}

// 400 Bad Request - Missing Required Fields
{
  "success": false,
  "error": {
    "code": "MISSING_REQUIRED_CONFIG",
    "message": "Missing required configuration fields for integration type",
    "details": {
      "type": "slack",
      "missing_fields": ["webhook_url", "channel"],
      "required_fields": {
        "webhook_url": "Slack webhook URL",
        "channel": "Slack channel name (starting with #)"
      }
    }
  },
  "timestamp": "2024-10-25T15:30:00Z"
}

// 403 Forbidden - Plan Restriction
{
  "success": false,
  "error": {
    "code": "INTEGRATION_NOT_AVAILABLE",
    "message": "This integration is not available on your current plan",
    "details": {
      "integration": "datadog",
      "current_plan": "starter",
      "required_plan": "professional",
      "upgrade_url": "/settings/billing"
    }
  },
  "timestamp": "2024-10-25T15:30:00Z"
}
```

---

### Test Integration Connection

Test an integration configuration to verify it works correctly.

**Endpoint:** `POST /api/v1/integrations/{type}/test`

**Required Permission:** `admin`

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
```

**Path Parameters:**
- `type` (string, required): Integration type

**Response:** `200 OK` (Success)

```json
{
  "success": true,
  "test_successful": true,
  "response_time_ms": 245,
  "details": "Test message delivered to #alerts channel",
  "timestamp": "2024-10-25T15:35:00Z"
}
```

**Response:** `200 OK` (Failure)

```json
{
  "success": true,
  "test_successful": false,
  "response_time_ms": 5000,
  "details": "Connection timeout: Unable to reach webhook URL",
  "timestamp": "2024-10-25T15:35:00Z"
}
```

**Cache Strategy:**
- No caching (live test)
- Update `last_tested_at`, `last_test_status`, `last_test_message` in database

**Error Responses:**

```json
// 404 Not Found
{
  "success": false,
  "error": {
    "code": "INTEGRATION_NOT_CONFIGURED",
    "message": "Integration not configured. Configure before testing.",
    "details": {
      "type": "slack"
    }
  },
  "timestamp": "2024-10-25T15:35:00Z"
}

// 400 Bad Request
{
  "success": false,
  "error": {
    "code": "INTEGRATION_DISABLED",
    "message": "Cannot test disabled integration",
    "details": {
      "type": "slack",
      "action_required": "Enable integration before testing"
    }
  },
  "timestamp": "2024-10-25T15:35:00Z"
}
```

---

### Disable Integration

Disable an integration without deleting the configuration.

**Endpoint:** `DELETE /api/v1/integrations/{type}`

**Required Permission:** `admin`

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
```

**Path Parameters:**
- `type` (string, required): Integration type

**Response:** `200 OK`

```json
{
  "success": true,
  "message": "Integration disabled successfully",
  "timestamp": "2024-10-25T15:40:00Z"
}
```

**Cache Strategy:**
- **Invalidate:** `workspace:{workspace_id}:integration:{type}`
- **Invalidate:** `workspace:{workspace_id}:integrations:list`

**Note:** This endpoint sets `enabled: false` rather than deleting the record, preserving configuration for easy re-enablement.

---

### Enable Integration

Enable a previously disabled integration.

**Endpoint:** `POST /api/v1/integrations/{type}/enable`

**Required Permission:** `admin`

**Request Headers:**
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
```

**Path Parameters:**
- `type` (string, required): Integration type

**Response:** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": "950e8400-e29b-41d4-a716-446655440000",
    "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
    "type": "slack",
    "enabled": true,
    "name": "Engineering Alerts",
    "description": "Slack notifications for production errors",
    "config": {
      "webhook_url": "https://hooks.slack.com/services/T00/B00/XXX",
      "channel": "#alerts",
      "notify_on_error": true,
      "notify_on_alert": true,
      "mention_users": ["@john", "@jane"]
    },
    "last_tested_at": "2024-10-25T14:15:00Z",
    "last_test_status": "success",
    "last_test_message": "Test notification sent successfully",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-10-25T15:45:00Z"
  },
  "message": "Integration enabled successfully",
  "timestamp": "2024-10-25T15:45:00Z"
}
```

**Cache Strategy:**
- **Invalidate:** `workspace:{workspace_id}:integration:{type}`
- **Invalidate:** `workspace:{workspace_id}:integrations:list`

**Error Responses:**

```json
// 404 Not Found
{
  "success": false,
  "error": {
    "code": "INTEGRATION_NOT_CONFIGURED",
    "message": "Integration not configured",
    "details": {
      "type": "slack",
      "action_required": "Configure integration before enabling"
    }
  },
  "timestamp": "2024-10-25T15:45:00Z"
}

// 409 Conflict
{
  "success": false,
  "error": {
    "code": "INTEGRATION_ALREADY_ENABLED",
    "message": "Integration is already enabled",
    "details": {
      "type": "slack"
    }
  },
  "timestamp": "2024-10-25T15:45:00Z"
}
```

---

## Error Handling

### Standard Error Response Format

All error responses follow this structure:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {
      "field": ["Specific error details"],
      "additional_context": "value"
    }
  },
  "timestamp": "2024-10-25T15:50:00Z"
}
```

### HTTP Status Codes

| Status Code | Usage | Examples |
|-------------|-------|----------|
| `200 OK` | Successful GET, PUT, DELETE | Resource retrieved/updated/deleted |
| `201 Created` | Successful POST | New resource created |
| `204 No Content` | Successful DELETE (no body) | Resource deleted |
| `400 Bad Request` | Validation errors, malformed request | Invalid input data |
| `401 Unauthorized` | Missing or invalid authentication | No/invalid JWT token |
| `403 Forbidden` | Insufficient permissions | User lacks required role |
| `404 Not Found` | Resource doesn't exist | Workspace/member/integration not found |
| `409 Conflict` | Resource conflict | Duplicate invitation, concurrent update |
| `410 Gone` | Resource permanently unavailable | Expired invitation |
| `422 Unprocessable Entity` | Business logic validation failed | Plan limit exceeded |
| `429 Too Many Requests` | Rate limit exceeded | Too many API calls |
| `500 Internal Server Error` | Server error | Database error, external service failure |
| `503 Service Unavailable` | Service temporarily down | Maintenance mode |

### Common Error Codes

#### Authentication & Authorization

- `UNAUTHORIZED` - Missing or invalid authentication token
- `INSUFFICIENT_PERMISSIONS` - User lacks required role
- `WORKSPACE_ACCESS_DENIED` - User not a member of workspace
- `TOKEN_EXPIRED` - JWT token has expired
- `INVALID_WORKSPACE_ID` - Workspace ID header missing or invalid

#### Validation Errors

- `VALIDATION_ERROR` - Request data validation failed
- `INVALID_QUERY_PARAMETER` - Query parameter validation failed
- `MISSING_REQUIRED_FIELD` - Required field missing from request
- `INVALID_EMAIL_FORMAT` - Email address format invalid
- `INVALID_URL_FORMAT` - URL format invalid
- `INVALID_DATE_RANGE` - Date range parameters invalid

#### Resource Errors

- `WORKSPACE_NOT_FOUND` - Workspace doesn't exist
- `MEMBER_NOT_FOUND` - Team member doesn't exist
- `INVITATION_NOT_FOUND` - Invitation doesn't exist
- `INTEGRATION_NOT_FOUND` - Integration configuration doesn't exist

#### Conflict Errors

- `MEMBER_ALREADY_EXISTS` - User already a workspace member
- `INVITATION_ALREADY_PENDING` - Pending invitation already exists
- `INVITATION_ALREADY_ACCEPTED` - Invitation already accepted
- `INVITATION_EXPIRED` - Invitation has expired
- `INTEGRATION_ALREADY_ENABLED` - Integration already enabled
- `CANNOT_MODIFY_OWNER` - Cannot modify workspace owner
- `CANNOT_REMOVE_SELF` - Cannot perform action on self

#### Business Logic Errors

- `TEAM_LIMIT_REACHED` - Team member limit exceeded for plan
- `API_KEY_LIMIT_REACHED` - API key limit exceeded for plan
- `INVALID_PLAN_DOWNGRADE` - Cannot downgrade due to usage
- `PAYMENT_METHOD_REQUIRED` - Payment method required for action
- `INTEGRATION_NOT_AVAILABLE` - Integration unavailable on current plan

#### External Service Errors

- `PAYMENT_PROVIDER_ERROR` - Stripe/payment provider error
- `EMAIL_DELIVERY_FAILED` - Email service error
- `INTEGRATION_TEST_FAILED` - Integration connection test failed

### Error Details Object

The `details` field provides context-specific information:

**Validation Errors:**
```json
"details": {
  "email": ["Invalid email address format"],
  "role": ["Invalid role. Must be one of: owner, admin, member, viewer"]
}
```

**Permission Errors:**
```json
"details": {
  "required_role": "admin",
  "current_role": "member"
}
```

**Limit Errors:**
```json
"details": {
  "current_count": 10,
  "limit": 10,
  "plan": "professional",
  "upgrade_url": "/settings/billing"
}
```

**Conflict Errors:**
```json
"details": {
  "existing_resource_id": "uuid",
  "conflict_field": "email",
  "conflict_value": "user@example.com"
}
```

---

## Cache Strategies

### Cache Key Patterns

```
workspace:{workspace_id}:details                          # Workspace info
workspace:{workspace_id}:team:members:{hash(params)}      # Team member list
workspace:{workspace_id}:team:invitations                 # Pending invitations
workspace:{workspace_id}:billing:config                   # Billing configuration
workspace:{workspace_id}:billing:usage:{period}           # Usage statistics
workspace:{workspace_id}:billing:invoices:{hash(params)}  # Invoice history
workspace:{workspace_id}:integrations:list                # All integrations
workspace:{workspace_id}:integration:{type}               # Specific integration
user:{user_id}:permissions                                # User permissions
user:{user_id}:workspaces                                 # User's workspaces
```

### TTL Configuration

| Resource | TTL | Rationale |
|----------|-----|-----------|
| Workspace details | 5 minutes | Moderate change frequency |
| Team members | 2 minutes | Frequent changes during onboarding |
| Team invitations | 2 minutes | Time-sensitive data |
| Billing config | 10 minutes | Infrequent changes |
| Billing usage | 5 minutes | Updated periodically |
| Billing invoices | 30 minutes | Historical data, rarely changes |
| Integrations list | 5 minutes | Moderate change frequency |
| Specific integration | 5 minutes | Moderate change frequency |
| User permissions | 2 minutes | Critical for RBAC, needs freshness |

### Cache Invalidation Strategies

#### Write-Through Invalidation

Invalidate immediately on updates:

```python
# Example: Update workspace
async def update_workspace(workspace_id: UUID, data: UpdateWorkspaceRequest):
    # Update database
    workspace = await db.update_workspace(workspace_id, data)

    # Invalidate caches
    await cache.delete(f"workspace:{workspace_id}:details")
    await cache.delete_pattern(f"workspace:{workspace_id}:*")

    return workspace
```

#### Cascade Invalidation

Related cache entries invalidated together:

- **Team member added/removed**: Invalidate team members list + workspace details (member count)
- **Role updated**: Invalidate team members + user permissions
- **Workspace updated**: Invalidate workspace details + related aggregations
- **Integration updated**: Invalidate integration list + specific integration

#### Pattern-Based Invalidation

Use wildcards for batch invalidation:

```python
# Invalidate all team-related caches
await cache.delete_pattern(f"workspace:{workspace_id}:team:*")

# Invalidate all workspace caches
await cache.delete_pattern(f"workspace:{workspace_id}:*")
```

### Cache Warming

Pre-populate frequently accessed data:

```python
# On user login, warm critical caches
async def warm_user_caches(user_id: UUID, workspace_id: UUID):
    # Workspace details
    await get_workspace(workspace_id)  # Cached for 5 min

    # User permissions
    await get_user_permissions(user_id, workspace_id)  # Cached for 2 min

    # Billing config (for admin/owner)
    if user_has_role(user_id, ["admin", "owner"]):
        await get_billing_config(workspace_id)  # Cached for 10 min
```

### Cache Consistency

#### Read-Through Pattern

```python
async def get_workspace(workspace_id: UUID) -> WorkspaceResponse:
    cache_key = f"workspace:{workspace_id}:details"

    # Try cache first
    cached = await cache.get(cache_key)
    if cached:
        return WorkspaceResponse.parse_raw(cached)

    # Cache miss - fetch from database
    workspace = await db.get_workspace(workspace_id)

    # Cache result
    await cache.set(cache_key, workspace.json(), ttl=300)

    return workspace
```

#### Write-Through Pattern

```python
async def update_workspace(
    workspace_id: UUID,
    data: UpdateWorkspaceRequest
) -> WorkspaceResponse:
    # Update database
    workspace = await db.update_workspace(workspace_id, data)

    # Update cache immediately
    cache_key = f"workspace:{workspace_id}:details"
    await cache.set(cache_key, workspace.json(), ttl=300)

    # Also invalidate related caches
    await cache.delete_pattern(f"workspace:{workspace_id}:team:*")

    return workspace
```

### Cache Headers

Return cache metadata in responses:

```http
X-Cache-Status: HIT              # or MISS
X-Cache-TTL: 180                 # seconds remaining
X-Cache-Key: workspace:uuid:details
```

---

## RBAC Permission Matrix

### Permission Levels

| Role | Level | Description |
|------|-------|-------------|
| **Owner** | 4 | Full workspace control, billing, transfers |
| **Admin** | 3 | Team management, settings, no billing |
| **Member** | 2 | Read team, basic operations |
| **Viewer** | 1 | Read-only access |

### Endpoint Permission Requirements

#### Workspace APIs

| Endpoint | Method | Owner | Admin | Member | Viewer |
|----------|--------|-------|-------|--------|--------|
| `/api/v1/workspace` | GET | ✓ | ✓ | ✓ | ✓ |
| `/api/v1/workspace` | PUT | ✓ | ✓ | ✗ | ✗ |

#### Team Management APIs

| Endpoint | Method | Owner | Admin | Member | Viewer |
|----------|--------|-------|-------|--------|--------|
| `/api/v1/team/members` | GET | ✓ | ✓ | ✓ | ✓ |
| `/api/v1/team/invite` | POST | ✓ | ✓ | ✗ | ✗ |
| `/api/v1/team/invitations` | GET | ✓ | ✓ | ✗ | ✗ |
| `/api/v1/team/invitations/{token}/accept` | POST | Public (token-based) |
| `/api/v1/team/invitations/{id}` | DELETE | ✓ | ✓ | ✗ | ✗ |
| `/api/v1/team/members/{id}/role` | PUT | ✓ | ✓* | ✗ | ✗ |
| `/api/v1/team/members/{id}` | DELETE | ✓ | ✓* | ✗ | ✗ |
| `/api/v1/team/members/{id}/reactivate` | POST | ✓ | ✓ | ✗ | ✗ |

**Notes:**
- *Admin can modify roles/remove members EXCEPT owner
- Admin cannot assign owner role (only owner can transfer ownership)
- Admin cannot modify their own role (prevents self-lockout)

#### Billing APIs

| Endpoint | Method | Owner | Admin | Member | Viewer |
|----------|--------|-------|-------|--------|--------|
| `/api/v1/billing/config` | GET | ✓ | ✓ | ✗ | ✗ |
| `/api/v1/billing/plan` | PUT | ✓ | ✗ | ✗ | ✗ |
| `/api/v1/billing/usage` | GET | ✓ | ✓ | ✗ | ✗ |
| `/api/v1/billing/checkout` | POST | ✓ | ✗ | ✗ | ✗ |
| `/api/v1/billing/invoices` | GET | ✓ | ✗ | ✗ | ✗ |

**Notes:**
- Only owner can view invoices and manage billing
- Admin can view config and usage for capacity planning

#### Integrations APIs

| Endpoint | Method | Owner | Admin | Member | Viewer |
|----------|--------|-------|-------|--------|--------|
| `/api/v1/integrations` | GET | ✓ | ✓ | ✓* | ✓* |
| `/api/v1/integrations/{type}` | GET | ✓ | ✓ | ✓* | ✓* |
| `/api/v1/integrations/{type}` | PUT | ✓ | ✓ | ✗ | ✗ |
| `/api/v1/integrations/{type}/test` | POST | ✓ | ✓ | ✗ | ✗ |
| `/api/v1/integrations/{type}` | DELETE | ✓ | ✓ | ✗ | ✗ |
| `/api/v1/integrations/{type}/enable` | POST | ✓ | ✓ | ✗ | ✗ |

**Notes:**
- *Member/Viewer can view enabled integrations (for transparency)
- Sensitive fields (API keys, webhooks) are masked for non-admin roles

### Special Rules

#### Owner-Only Operations

1. **Transfer Ownership**: Assign owner role to another member
2. **Manage Billing**: Update plan, view invoices
3. **Delete Workspace**: Permanently remove workspace
4. **Downgrade with Data Loss**: Approve destructive operations

#### Admin Restrictions

1. **Cannot modify owner**: Cannot change owner role or remove owner
2. **Cannot assign owner role**: Cannot promote members to owner
3. **Cannot modify self**: Cannot change own role (prevents lockout)
4. **No billing access**: Cannot view invoices or update payment methods

#### Member Capabilities

1. **Read team info**: View team members list
2. **Read integrations**: View enabled integrations (masked secrets)
3. **Basic operations**: Use API keys, view dashboards

#### Viewer Limitations

1. **Read-only**: Cannot modify any settings
2. **No team actions**: Cannot invite or manage members
3. **No integrations**: Cannot configure or test integrations

### RBAC Enforcement

#### Middleware Implementation

```python
from functools import wraps
from fastapi import HTTPException, status

def require_role(min_role: UserRole):
    """Decorator to enforce minimum role requirement"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Extract user from request context
            current_user = kwargs.get("current_user")

            # Check role hierarchy
            role_hierarchy = {
                UserRole.VIEWER: 1,
                UserRole.MEMBER: 2,
                UserRole.ADMIN: 3,
                UserRole.OWNER: 4
            }

            if role_hierarchy[current_user.role] < role_hierarchy[min_role]:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail={
                        "code": "INSUFFICIENT_PERMISSIONS",
                        "message": f"{min_role.value} role required",
                        "details": {
                            "required_role": min_role.value,
                            "current_role": current_user.role.value
                        }
                    }
                )

            return await func(*args, **kwargs)
        return wrapper
    return decorator

# Usage example
@router.put("/workspace")
@require_role(UserRole.ADMIN)
async def update_workspace(
    data: UpdateWorkspaceRequest,
    current_user: User = Depends(get_current_user)
):
    # Implementation
    pass
```

#### Field-Level Permissions

Mask sensitive fields based on role:

```python
class IntegrationConfigResponse(BaseModel):
    # ... fields ...

    @validator("config", always=True)
    def mask_sensitive_fields(cls, v, values, **kwargs):
        # Get current user role from context
        current_user_role = kwargs.get("context", {}).get("user_role")

        if current_user_role in [UserRole.MEMBER, UserRole.VIEWER]:
            # Mask sensitive fields
            masked_config = v.copy()
            if "webhook_url" in masked_config:
                masked_config["webhook_url"] = "***MASKED***"
            if "api_key" in masked_config:
                masked_config["api_key"] = "***MASKED***"
            if "integration_key" in masked_config:
                masked_config["integration_key"] = "***MASKED***"
            return masked_config

        return v
```

---

## Integration Test Scenarios

### 1. Team Member Invitation Flow

**Scenario**: Admin invites new member, member accepts invitation

```gherkin
Feature: Team Member Invitation

  Scenario: Successful invitation and acceptance
    Given I am logged in as an admin
    And my workspace has 8/10 team members
    When I POST to /api/v1/team/invite with:
      """
      {
        "email": "newmember@example.com",
        "role": "member",
        "first_name": "New",
        "last_name": "Member"
      }
      """
    Then I should receive a 201 response
    And the response should contain an invitation token
    And an email should be sent to "newmember@example.com"

    When the new user POSTs to /api/v1/team/invitations/{token}/accept
    Then they should receive a 200 response
    And they should be added to the workspace
    And workspace member_count should be 9
    And the invitation status should be "accepted"

    When I GET /api/v1/team/members
    Then the list should include "newmember@example.com"
```

**Test Data:**

```python
# test_team_invitation.py

async def test_invitation_flow(client: AsyncClient, admin_token: str):
    # Step 1: Send invitation
    response = await client.post(
        "/api/v1/team/invite",
        headers={
            "Authorization": f"Bearer {admin_token}",
            "X-Workspace-ID": workspace_id
        },
        json={
            "email": "newmember@example.com",
            "role": "member",
            "first_name": "New",
            "last_name": "Member",
            "message": "Welcome!"
        }
    )
    assert response.status_code == 201
    invitation = response.json()["data"]
    token = invitation["token"]

    # Step 2: Accept invitation
    response = await client.post(
        f"/api/v1/team/invitations/{token}/accept",
        json={
            "first_name": "New",
            "last_name": "Member"
        }
    )
    assert response.status_code == 200
    member = response.json()["data"]
    assert member["email"] == "newmember@example.com"
    assert member["status"] == "active"

    # Step 3: Verify member in list
    response = await client.get(
        "/api/v1/team/members",
        headers={
            "Authorization": f"Bearer {admin_token}",
            "X-Workspace-ID": workspace_id
        }
    )
    assert response.status_code == 200
    members = response.json()["data"]
    assert any(m["email"] == "newmember@example.com" for m in members)
```

### 2. Role Update with Validation

**Scenario**: Admin updates member role with various edge cases

```gherkin
Feature: Role Update

  Scenario: Update member role successfully
    Given I am logged in as an admin
    And there is a member with role "viewer"
    When I PUT to /api/v1/team/members/{id}/role with:
      """
      {"role": "member"}
      """
    Then I should receive a 200 response
    And the member's role should be "member"
    And the cache should be invalidated

  Scenario: Cannot update owner role
    Given I am logged in as an admin
    And there is an owner
    When I PUT to /api/v1/team/members/{owner_id}/role with:
      """
      {"role": "admin"}
      """
    Then I should receive a 403 response
    And the error code should be "CANNOT_MODIFY_OWNER"

  Scenario: Cannot update own role
    Given I am logged in as an admin
    When I PUT to /api/v1/team/members/{my_id}/role with:
      """
      {"role": "viewer"}
      """
    Then I should receive a 409 response
    And the error code should be "CANNOT_DEMOTE_SELF"
```

### 3. Billing Plan Downgrade Validation

**Scenario**: Prevent downgrades that exceed new plan limits

```gherkin
Feature: Billing Plan Downgrade

  Scenario: Blocked downgrade due to team size
    Given I am logged in as owner
    And my workspace has 12 team members
    And I am on "professional" plan (limit: 10 members)
    When I PUT to /api/v1/billing/plan with:
      """
      {
        "plan": "starter",
        "interval": "monthly"
      }
      """
    Then I should receive a 400 response
    And the error code should be "INVALID_PLAN_DOWNGRADE"
    And the details should include:
      """
      {
        "blockers": [
          {
            "limit": "max_team_members",
            "current_value": 12,
            "new_limit": 5,
            "action_required": "Remove 7 team members"
          }
        ]
      }
      """

  Scenario: Successful downgrade
    Given I am logged in as owner
    And my workspace has 4 team members
    And I have 2 API keys
    When I PUT to /api/v1/billing/plan with:
      """
      {
        "plan": "starter",
        "interval": "monthly"
      }
      """
    Then I should receive a 200 response
    And my plan should be "starter"
    And limits should be updated
```

### 4. Integration Configuration and Testing

**Scenario**: Configure and test Slack integration

```gherkin
Feature: Slack Integration

  Scenario: Configure and test Slack integration
    Given I am logged in as admin
    When I PUT to /api/v1/integrations/slack with:
      """
      {
        "enabled": true,
        "name": "Production Alerts",
        "config": {
          "webhook_url": "https://hooks.slack.com/services/T00/B00/XXX",
          "channel": "#alerts",
          "notify_on_error": true
        }
      }
      """
    Then I should receive a 200 response
    And the integration should be saved

    When I POST to /api/v1/integrations/slack/test
    Then I should receive a 200 response
    And the test should be successful
    And a test message should be sent to Slack
    And last_tested_at should be updated

  Scenario: Invalid Slack configuration
    Given I am logged in as admin
    When I PUT to /api/v1/integrations/slack with:
      """
      {
        "enabled": true,
        "config": {
          "webhook_url": "invalid-url",
          "channel": "alerts"
        }
      }
      """
    Then I should receive a 400 response
    And the error should indicate validation failures:
      """
      {
        "config.webhook_url": ["Invalid URL format"],
        "config.channel": ["Channel must start with #"]
      }
      """
```

### 5. Concurrent Invitation Handling

**Scenario**: Handle duplicate invitations and race conditions

```gherkin
Feature: Concurrent Invitations

  Scenario: Prevent duplicate invitations
    Given I am logged in as admin
    And I have sent an invitation to "user@example.com"
    When I POST to /api/v1/team/invite again with same email
    Then I should receive a 409 response
    And the error code should be "INVITATION_ALREADY_PENDING"
    And details should include existing invitation ID

  Scenario: Invitation expiry handling
    Given there is an expired invitation
    When a user tries to accept it
    Then they should receive a 410 response
    And the error code should be "INVITATION_EXPIRED"

    When admin sends a new invitation to same email
    Then it should succeed (old expired invitation ignored)
```

### 6. Cache Consistency Test

**Scenario**: Verify cache invalidation on updates

```gherkin
Feature: Cache Consistency

  Scenario: Cache invalidation on member addition
    Given workspace cache is warmed
    And team members cache exists
    When a new member is added
    Then workspace:{id}:details cache should be invalidated
    And workspace:{id}:team:members:* cache should be invalidated

    When I GET /api/v1/workspace
    Then it should fetch from database
    And member_count should be updated

  Scenario: Cache invalidation on role update
    Given member cache exists for user
    And user permissions cache exists
    When member role is updated from "viewer" to "admin"
    Then workspace:{id}:team:members:* should be invalidated
    And user:{id}:permissions should be invalidated

    When user makes admin-level request
    Then new permissions should be enforced immediately
```

### 7. Permission Boundary Testing

**Scenario**: Test RBAC enforcement at boundaries

```gherkin
Feature: Permission Boundaries

  Scenario: Member cannot access admin endpoints
    Given I am logged in as member
    When I POST to /api/v1/team/invite
    Then I should receive a 403 response

    When I PUT to /api/v1/workspace
    Then I should receive a 403 response

    When I GET to /api/v1/billing/config
    Then I should receive a 403 response

  Scenario: Admin cannot access owner endpoints
    Given I am logged in as admin
    When I GET to /api/v1/billing/config
    Then I should receive a 200 response

    When I PUT to /api/v1/billing/plan
    Then I should receive a 403 response

    When I GET to /api/v1/billing/invoices
    Then I should receive a 403 response
```

### 8. Rate Limiting Test

**Scenario**: Verify rate limiting enforcement

```gherkin
Feature: Rate Limiting

  Scenario: Exceed rate limit
    Given I am logged in as admin
    When I make 101 requests in 1 minute
    Then the 101st request should receive 429
    And the response should include retry-after header
    And the error code should be "RATE_LIMIT_EXCEEDED"

  Scenario: Rate limit reset
    Given I have hit the rate limit
    When I wait 60 seconds
    Then I should be able to make requests again
```

### 9. Idempotency Test

**Scenario**: Test idempotent operations

```gherkin
Feature: Idempotency

  Scenario: Idempotent invitation creation
    Given I am logged in as admin
    When I POST to /api/v1/team/invite with idempotency key "inv-123"
    Then I should receive a 201 response
    And invitation should be created

    When I POST again with same idempotency key "inv-123"
    Then I should receive the same 201 response
    And no duplicate invitation should be created

    When I POST with different email but same key
    Then I should still receive the original response
```

### 10. Workspace Isolation Test

**Scenario**: Verify multi-tenant isolation

```gherkin
Feature: Workspace Isolation

  Scenario: Cannot access other workspace data
    Given I am owner of workspace A
    And there exists workspace B
    When I GET /api/v1/team/members with workspace B header
    Then I should receive a 403 response
    And the error should be "WORKSPACE_ACCESS_DENIED"

  Scenario: Workspace-specific cache isolation
    Given I have cached data for workspace A
    When I switch to workspace B
    Then I should not see cached data from workspace A
    And all operations should use workspace B data
```

---

## Additional Documentation

### Example cURL Requests

#### Get Workspace Details

```bash
curl -X GET 'http://localhost:8000/api/v1/workspace' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'X-Workspace-ID: 550e8400-e29b-41d4-a716-446655440000'
```

#### Invite Team Member

```bash
curl -X POST 'http://localhost:8000/api/v1/team/invite' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'X-Workspace-ID: 550e8400-e29b-41d4-a716-446655440000' \
  -H 'Content-Type: application/json' \
  -H 'Idempotency-Key: inv-unique-123' \
  -d '{
    "email": "jane.smith@example.com",
    "role": "admin",
    "first_name": "Jane",
    "last_name": "Smith",
    "message": "Welcome to the team!"
  }'
```

#### Update Billing Plan

```bash
curl -X PUT 'http://localhost:8000/api/v1/billing/plan' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'X-Workspace-ID: 550e8400-e29b-41d4-a716-446655440000' \
  -H 'Content-Type: application/json' \
  -d '{
    "plan": "enterprise",
    "interval": "yearly"
  }'
```

#### Configure Slack Integration

```bash
curl -X PUT 'http://localhost:8000/api/v1/integrations/slack' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'X-Workspace-ID: 550e8400-e29b-41d4-a716-446655440000' \
  -H 'Content-Type: application/json' \
  -d '{
    "enabled": true,
    "name": "Production Alerts",
    "config": {
      "webhook_url": "https://hooks.slack.com/services/T00/B00/XXX",
      "channel": "#alerts",
      "notify_on_error": true,
      "notify_on_alert": true,
      "mention_users": ["@oncall"]
    }
  }'
```

### Pagination Example

```bash
# First page
curl -X GET 'http://localhost:8000/api/v1/team/members?limit=20' \
  -H 'Authorization: Bearer ...' \
  -H 'X-Workspace-ID: ...'

# Next page using cursor from previous response
curl -X GET 'http://localhost:8000/api/v1/team/members?limit=20&cursor=eyJpZCI6IjEyMyJ9' \
  -H 'Authorization: Bearer ...' \
  -H 'X-Workspace-ID: ...'
```

### Filtering and Sorting Example

```bash
curl -X GET 'http://localhost:8000/api/v1/team/members?status=active&role=admin&sort=created_at:desc&limit=20' \
  -H 'Authorization: Bearer ...' \
  -H 'X-Workspace-ID: ...'
```

---

## Migration Guide

### Breaking Changes (Future Versions)

When API breaking changes are introduced, this section will document:

1. **What Changed**: Detailed description of the change
2. **Migration Steps**: Step-by-step guide to adapt
3. **Backward Compatibility**: Timeline for old version support
4. **Code Examples**: Before/after comparison

### Deprecation Notice Format

```json
{
  "success": true,
  "data": {...},
  "deprecation_warning": {
    "field": "old_field_name",
    "message": "This field is deprecated and will be removed in v2.0",
    "sunset_date": "2025-06-01",
    "replacement": "new_field_name",
    "documentation_url": "https://docs.example.com/migration/v2"
  }
}
```

---

## OpenAPI 3.0 Specification

For a complete OpenAPI 3.0 specification compatible with Swagger UI and other tooling, generate from the Pydantic models using:

```python
from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi

app = FastAPI(
    title="Agent Observability Platform - Settings API",
    version="1.0.0",
    description="API for managing workspace settings, team, billing, and integrations"
)

# Register all routers
app.include_router(workspace_router)
app.include_router(team_router)
app.include_router(billing_router)
app.include_router(integrations_router)

# Export OpenAPI spec
openapi_schema = get_openapi(
    title=app.title,
    version=app.version,
    description=app.description,
    routes=app.routes
)
```

Access at: `http://localhost:8000/openapi.json`

---

## Support and Contact

For API support and questions:

- **Documentation**: https://docs.example.com/api
- **Support Email**: api-support@example.com
- **Status Page**: https://status.example.com
- **Changelog**: https://docs.example.com/changelog

---

**End of API Specification**
