"""
Pydantic models for Settings API endpoints.

This module contains all request/response schemas for the Phase 5 Settings page:
- Workspace management
- Team member management
- Billing configuration
- Integrations configuration

All models use Pydantic v2 with proper validation and JSON schema generation.
"""

from pydantic import BaseModel, Field, EmailStr, HttpUrl, field_validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum
from uuid import UUID


# ============================================================================
# Enumerations
# ============================================================================

class UserRole(str, Enum):
    """User roles with hierarchical permissions."""
    OWNER = "owner"
    ADMIN = "admin"
    MEMBER = "member"
    VIEWER = "viewer"


class InvitationStatus(str, Enum):
    """Status of team member invitations."""
    PENDING = "pending"
    ACCEPTED = "accepted"
    EXPIRED = "expired"
    CANCELLED = "cancelled"


class BillingPlan(str, Enum):
    """Available billing plans."""
    FREE = "free"
    STARTER = "starter"
    PROFESSIONAL = "professional"
    ENTERPRISE = "enterprise"


class BillingInterval(str, Enum):
    """Billing intervals for subscriptions."""
    MONTHLY = "monthly"
    YEARLY = "yearly"


class IntegrationType(str, Enum):
    """Supported integration types."""
    SLACK = "slack"
    PAGERDUTY = "pagerduty"
    WEBHOOK = "webhook"
    EMAIL = "email"
    DATADOG = "datadog"


class MemberStatus(str, Enum):
    """Team member status."""
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"


# ============================================================================
# Base Response Models
# ============================================================================

class BaseResponse(BaseModel):
    """Base response structure for all API endpoints."""
    success: bool = True
    message: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class PaginationInfo(BaseModel):
    """Pagination metadata for list responses."""
    next_cursor: Optional[str] = None
    has_more: bool = False
    total_count: Optional[int] = None


class PaginatedResponse(BaseResponse):
    """Base response for paginated endpoints."""
    pagination: PaginationInfo


# ============================================================================
# Error Models
# ============================================================================

class ErrorDetail(BaseModel):
    """Detailed error information."""
    code: str = Field(..., description="Machine-readable error code")
    message: str = Field(..., description="Human-readable error message")
    details: Optional[Dict[str, Any]] = Field(None, description="Additional context")


class ErrorResponse(BaseModel):
    """Standard error response structure."""
    success: bool = False
    error: ErrorDetail
    timestamp: datetime = Field(default_factory=datetime.utcnow)

    model_config = {
        "json_schema_extra": {
            "example": {
                "success": False,
                "error": {
                    "code": "VALIDATION_ERROR",
                    "message": "Invalid request data",
                    "details": {
                        "email": ["Invalid email address format"]
                    }
                },
                "timestamp": "2024-10-25T14:20:00Z"
            }
        }
    }


# ============================================================================
# Workspace Models
# ============================================================================

class WorkspaceBase(BaseModel):
    """Base workspace fields."""
    name: str = Field(..., min_length=1, max_length=100, description="Workspace name")
    description: Optional[str] = Field(None, max_length=500, description="Workspace description")
    timezone: str = Field(default="UTC", description="Workspace timezone (IANA format)")
    settings: Optional[Dict[str, Any]] = Field(default_factory=dict, description="Custom workspace settings")

    @field_validator("timezone")
    @classmethod
    def validate_timezone(cls, v: str) -> str:
        """Validate timezone format."""
        import re
        if not re.match(r"^[A-Za-z]+/[A-Za-z_]+$", v):
            raise ValueError("Invalid timezone format. Expected: 'Region/City'")
        return v


class WorkspaceResponse(WorkspaceBase):
    """Workspace details response."""
    id: UUID
    owner_id: UUID
    created_at: datetime
    updated_at: datetime
    member_count: int
    plan: BillingPlan

    model_config = {
        "json_schema_extra": {
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
                    "allow_public_sharing": False
                }
            }
        }
    }


class UpdateWorkspaceRequest(BaseModel):
    """Request to update workspace settings."""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    timezone: Optional[str] = None
    settings: Optional[Dict[str, Any]] = None

    @field_validator("timezone")
    @classmethod
    def validate_timezone(cls, v: Optional[str]) -> Optional[str]:
        """Validate timezone format if provided."""
        if v is None:
            return v
        import re
        if not re.match(r"^[A-Za-z]+/[A-Za-z_]+$", v):
            raise ValueError("Invalid timezone format. Expected: 'Region/City'")
        return v

    model_config = {
        "json_schema_extra": {
            "example": {
                "name": "Acme Corp - Updated",
                "timezone": "America/Los_Angeles",
                "settings": {
                    "default_retention_days": 120
                }
            }
        }
    }


class GetWorkspaceResponse(BaseResponse):
    """Response for GET /workspace endpoint."""
    data: WorkspaceResponse


class UpdateWorkspaceResponse(BaseResponse):
    """Response for PUT /workspace endpoint."""
    data: WorkspaceResponse


# ============================================================================
# Team Member Models
# ============================================================================

class TeamMemberBase(BaseModel):
    """Base team member fields."""
    email: EmailStr
    role: UserRole
    first_name: Optional[str] = Field(None, max_length=50)
    last_name: Optional[str] = Field(None, max_length=50)


class TeamMemberResponse(TeamMemberBase):
    """Team member details response."""
    id: UUID
    workspace_id: UUID
    user_id: UUID
    status: MemberStatus
    last_active_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    invited_by: Optional[UUID] = None

    model_config = {
        "json_schema_extra": {
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
    }


class ListTeamMembersResponse(PaginatedResponse):
    """Response for listing team members."""
    data: List[TeamMemberResponse]


class InviteTeamMemberRequest(BaseModel):
    """Request to invite a new team member."""
    email: EmailStr
    role: UserRole = Field(default=UserRole.MEMBER)
    first_name: Optional[str] = Field(None, max_length=50)
    last_name: Optional[str] = Field(None, max_length=50)
    message: Optional[str] = Field(None, max_length=500, description="Custom invitation message")

    @field_validator("role")
    @classmethod
    def validate_role(cls, v: UserRole) -> UserRole:
        """Prevent inviting owners via API."""
        if v == UserRole.OWNER:
            raise ValueError("Cannot invite members with owner role")
        return v

    model_config = {
        "json_schema_extra": {
            "example": {
                "email": "jane.smith@example.com",
                "role": "admin",
                "first_name": "Jane",
                "last_name": "Smith",
                "message": "Welcome to our monitoring team!"
            }
        }
    }


class InvitationResponse(BaseModel):
    """Team invitation details."""
    id: UUID
    workspace_id: UUID
    email: EmailStr
    role: UserRole
    status: InvitationStatus
    token: str
    invited_by: UUID
    expires_at: datetime
    created_at: datetime

    model_config = {
        "json_schema_extra": {
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
    }


class ListInvitationsResponse(PaginatedResponse):
    """Response for listing invitations."""
    data: List[InvitationResponse]


class AcceptInvitationRequest(BaseModel):
    """Request to accept a team invitation."""
    first_name: Optional[str] = Field(None, max_length=50)
    last_name: Optional[str] = Field(None, max_length=50)


class InviteTeamMemberResponse(BaseResponse):
    """Response for sending an invitation."""
    data: InvitationResponse


class AcceptInvitationResponse(BaseResponse):
    """Response for accepting an invitation."""
    data: TeamMemberResponse


class UpdateMemberRoleRequest(BaseModel):
    """Request to update team member role."""
    role: UserRole

    model_config = {
        "json_schema_extra": {
            "example": {
                "role": "admin"
            }
        }
    }


class UpdateMemberRoleResponse(BaseResponse):
    """Response for updating member role."""
    data: TeamMemberResponse


# ============================================================================
# Billing Models
# ============================================================================

class PlanLimits(BaseModel):
    """Plan limits and quotas."""
    max_traces_per_month: int
    max_team_members: int
    max_api_keys: int
    data_retention_days: int
    rate_limit_per_minute: int
    custom_integrations: bool
    priority_support: bool
    sla_uptime: Optional[float] = None

    model_config = {
        "json_schema_extra": {
            "example": {
                "max_traces_per_month": 1000000,
                "max_team_members": 10,
                "max_api_keys": 5,
                "data_retention_days": 90,
                "rate_limit_per_minute": 100,
                "custom_integrations": True,
                "priority_support": True,
                "sla_uptime": 99.9
            }
        }
    }


class BillingConfigResponse(BaseResponse):
    """Billing configuration response."""
    plan: BillingPlan
    interval: BillingInterval
    limits: PlanLimits
    price_per_month: float
    currency: str = "USD"
    trial_ends_at: Optional[datetime] = None
    subscription_id: Optional[str] = None
    next_billing_date: Optional[datetime] = None
    auto_renew: bool = True

    model_config = {
        "json_schema_extra": {
            "example": {
                "success": True,
                "plan": "professional",
                "interval": "monthly",
                "limits": {
                    "max_traces_per_month": 1000000,
                    "max_team_members": 10,
                    "max_api_keys": 5,
                    "data_retention_days": 90,
                    "rate_limit_per_minute": 100,
                    "custom_integrations": True,
                    "priority_support": True,
                    "sla_uptime": 99.9
                },
                "price_per_month": 99.00,
                "currency": "USD",
                "trial_ends_at": None,
                "subscription_id": "sub_1234567890",
                "next_billing_date": "2024-11-25T00:00:00Z",
                "auto_renew": True,
                "timestamp": "2024-10-25T14:20:00Z"
            }
        }
    }


class UpdateBillingPlanRequest(BaseModel):
    """Request to update billing plan."""
    plan: BillingPlan
    interval: BillingInterval = Field(default=BillingInterval.MONTHLY)

    model_config = {
        "json_schema_extra": {
            "example": {
                "plan": "enterprise",
                "interval": "yearly"
            }
        }
    }


class UpdateBillingPlanResponse(BillingConfigResponse):
    """Response for updating billing plan."""
    pass


class UsageStats(BaseModel):
    """Current usage statistics."""
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

    model_config = {
        "json_schema_extra": {
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
    }


class BillingUsageResponse(BaseResponse):
    """Response for billing usage statistics."""
    usage: UsageStats


class CheckoutSessionRequest(BaseModel):
    """Request to create Stripe checkout session."""
    plan: BillingPlan
    interval: BillingInterval
    success_url: HttpUrl
    cancel_url: HttpUrl

    model_config = {
        "json_schema_extra": {
            "example": {
                "plan": "professional",
                "interval": "monthly",
                "success_url": "https://app.example.com/settings/billing?success=true",
                "cancel_url": "https://app.example.com/settings/billing"
            }
        }
    }


class CheckoutSessionResponse(BaseResponse):
    """Response for checkout session creation."""
    session_id: str
    checkout_url: HttpUrl
    expires_at: datetime

    model_config = {
        "json_schema_extra": {
            "example": {
                "success": True,
                "session_id": "cs_test_1234567890",
                "checkout_url": "https://checkout.stripe.com/pay/cs_test_1234567890",
                "expires_at": "2024-10-25T15:20:00Z",
                "timestamp": "2024-10-25T14:20:00Z"
            }
        }
    }


class Invoice(BaseModel):
    """Invoice details."""
    id: str
    amount: float
    currency: str
    status: str
    period_start: datetime
    period_end: datetime
    invoice_url: Optional[HttpUrl] = None
    created_at: datetime

    model_config = {
        "json_schema_extra": {
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
    }


class ListInvoicesResponse(PaginatedResponse):
    """Response for listing invoices."""
    data: List[Invoice]


# ============================================================================
# Integration Models
# ============================================================================

class SlackConfig(BaseModel):
    """Slack integration configuration."""
    webhook_url: HttpUrl
    channel: str = Field(..., pattern=r"^#[a-z0-9-_]+$")
    notify_on_error: bool = True
    notify_on_alert: bool = True
    mention_users: List[str] = Field(default_factory=list)


class PagerDutyConfig(BaseModel):
    """PagerDuty integration configuration."""
    integration_key: str = Field(..., min_length=32, max_length=32)
    severity: str = Field(default="error", pattern=r"^(critical|error|warning|info)$")
    auto_resolve: bool = True


class WebhookConfig(BaseModel):
    """Webhook integration configuration."""
    url: HttpUrl
    method: str = Field(default="POST", pattern=r"^(POST|PUT)$")
    headers: Dict[str, str] = Field(default_factory=dict)
    events: List[str] = Field(default_factory=list)
    secret: Optional[str] = Field(None, description="HMAC secret for signature verification")


class EmailConfig(BaseModel):
    """Email integration configuration."""
    recipients: List[EmailStr] = Field(..., min_length=1)
    notify_on_error: bool = True
    notify_on_alert: bool = True
    daily_digest: bool = False


class DatadogConfig(BaseModel):
    """Datadog integration configuration."""
    api_key: str = Field(..., min_length=32, max_length=40)
    app_key: str = Field(..., min_length=32, max_length=40)
    site: str = Field(default="datadoghq.com")
    service: str = Field(..., min_length=1)


class IntegrationConfigBase(BaseModel):
    """Base integration configuration."""
    type: IntegrationType
    enabled: bool = True
    config: Dict[str, Any]
    name: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = Field(None, max_length=500)


class IntegrationConfigResponse(IntegrationConfigBase):
    """Integration configuration response."""
    id: UUID
    workspace_id: UUID
    last_tested_at: Optional[datetime] = None
    last_test_status: Optional[str] = None
    last_test_message: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = {
        "json_schema_extra": {
            "example": {
                "id": "950e8400-e29b-41d4-a716-446655440000",
                "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
                "type": "slack",
                "enabled": True,
                "name": "Engineering Alerts",
                "description": "Slack notifications for production errors",
                "config": {
                    "webhook_url": "https://hooks.slack.com/services/T00/B00/XXX",
                    "channel": "#alerts",
                    "notify_on_error": True,
                    "notify_on_alert": True,
                    "mention_users": ["@john", "@jane"]
                },
                "last_tested_at": "2024-10-25T14:15:00Z",
                "last_test_status": "success",
                "last_test_message": "Test notification sent successfully",
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-10-25T14:15:00Z"
            }
        }
    }


class ListIntegrationsResponse(BaseResponse):
    """Response for listing integrations."""
    data: List[IntegrationConfigResponse]


class GetIntegrationResponse(BaseResponse):
    """Response for getting specific integration."""
    data: IntegrationConfigResponse


class UpdateIntegrationRequest(BaseModel):
    """Request to update integration configuration."""
    enabled: Optional[bool] = None
    config: Optional[Dict[str, Any]] = None
    name: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = Field(None, max_length=500)

    model_config = {
        "json_schema_extra": {
            "example": {
                "enabled": True,
                "name": "Updated Slack Integration",
                "config": {
                    "webhook_url": "https://hooks.slack.com/services/T00/B00/YYY",
                    "channel": "#production-alerts",
                    "notify_on_error": True
                }
            }
        }
    }


class UpdateIntegrationResponse(BaseResponse):
    """Response for updating integration."""
    data: IntegrationConfigResponse


class TestIntegrationResponse(BaseResponse):
    """Response for testing integration."""
    test_successful: bool
    response_time_ms: int
    details: Optional[str] = None

    model_config = {
        "json_schema_extra": {
            "example": {
                "success": True,
                "test_successful": True,
                "response_time_ms": 245,
                "details": "Test message delivered to #alerts channel",
                "timestamp": "2024-10-25T14:20:00Z"
            }
        }
    }


# ============================================================================
# Query Parameter Models
# ============================================================================

class TeamMemberQueryParams(BaseModel):
    """Query parameters for listing team members."""
    limit: int = Field(default=20, ge=1, le=100)
    cursor: Optional[str] = None
    status: Optional[MemberStatus] = None
    role: Optional[UserRole] = None
    search: Optional[str] = Field(None, max_length=100)
    sort: Optional[str] = Field(None, pattern=r"^[a-z_]+(:(asc|desc))?(,[a-z_]+(:(asc|desc))?)*$")


class InvitationQueryParams(BaseModel):
    """Query parameters for listing invitations."""
    limit: int = Field(default=20, ge=1, le=100)
    cursor: Optional[str] = None
    status: Optional[InvitationStatus] = None


class InvoiceQueryParams(BaseModel):
    """Query parameters for listing invoices."""
    limit: int = Field(default=20, ge=1, le=100)
    cursor: Optional[str] = None
    status: Optional[str] = Field(None, pattern=r"^(paid|pending|failed)$")


class UsageQueryParams(BaseModel):
    """Query parameters for billing usage."""
    period: str = Field(default="current", pattern=r"^(current|previous|custom)$")
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None

    @field_validator("end_date")
    @classmethod
    def validate_date_range(cls, v: Optional[datetime], info) -> Optional[datetime]:
        """Validate date range for custom period."""
        if v and info.data.get("start_date"):
            if v <= info.data["start_date"]:
                raise ValueError("end_date must be after start_date")
        return v


class IntegrationQueryParams(BaseModel):
    """Query parameters for listing integrations."""
    enabled: Optional[bool] = None
    type: Optional[IntegrationType] = None


# ============================================================================
# Deprecation Warning Model
# ============================================================================

class DeprecationWarning(BaseModel):
    """Deprecation warning for phased-out features."""
    field: str
    message: str
    sunset_date: str
    replacement: str
    documentation_url: HttpUrl


# ============================================================================
# Plan Downgrade Blocker Model
# ============================================================================

class PlanDowngradeBlocker(BaseModel):
    """Information about what's blocking a plan downgrade."""
    limit: str = Field(..., description="Limit type (e.g., max_team_members)")
    current_value: int = Field(..., description="Current usage")
    new_limit: int = Field(..., description="Limit in target plan")
    action_required: str = Field(..., description="Action needed to resolve")


class PlanDowngradeError(BaseModel):
    """Detailed error for invalid plan downgrades."""
    code: str = "INVALID_PLAN_DOWNGRADE"
    message: str = "Cannot downgrade to this plan due to current usage"
    details: Dict[str, Any]

    model_config = {
        "json_schema_extra": {
            "example": {
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
                        }
                    ]
                }
            }
        }
    }
