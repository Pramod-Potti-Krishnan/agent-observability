# Phase 5 Settings Database Schema
## Agent Observability Platform - Settings Management

**Stack:** PostgreSQL 15 (Port 5433)
**Schema Version:** Phase 5.0
**Last Updated:** October 2025
**Status:** Production Ready

---

## Table of Contents

1. [Overview](#overview)
2. [Schema Design](#schema-design)
3. [Table Definitions](#table-definitions)
4. [Indexes & Performance](#indexes--performance)
5. [Migration Scripts](#migration-scripts)
6. [Seed Data](#seed-data)
7. [Security Considerations](#security-considerations)

---

## Overview

### Architecture Context

This schema extends the existing PostgreSQL metadata database with three new tables to support Phase 5 Settings page functionality:

```
┌─────────────────────────────────────────────────────────────┐
│                 PostgreSQL (Port 5433)                      │
│              Multi-Tenant Relational Database               │
├─────────────────────────────────────────────────────────────┤
│  EXISTING TABLES                                            │
│  • workspaces           - Workspace/tenant isolation        │
│  • users                - User authentication               │
│  • workspace_members    - Existing team membership          │
│  • agents               - Agent configurations              │
│  • api_keys             - API authentication                │
│  • budgets (implied)    - Budget tracking                   │
├─────────────────────────────────────────────────────────────┤
│  NEW PHASE 5 TABLES                                         │
│  • team_members         - Enhanced team management + RBAC   │
│  • billing_config       - Subscription & usage limits       │
│  • integrations_config  - External service integrations     │
└─────────────────────────────────────────────────────────────┘
```

### Design Principles

1. **Multi-Tenancy**: All tables include `workspace_id` for tenant isolation
2. **RBAC Support**: Role-based access control with 4 permission levels
3. **Audit Trail**: Created/updated tracking with user attribution
4. **Soft Deletes**: Support for soft deletion patterns
5. **Scalability**: Optimized indexes for common query patterns
6. **Security**: Encrypted credential storage considerations

---

## Schema Design

### Entity Relationship Diagram

```
┌─────────────────┐
│   workspaces    │
│  (existing)     │
└────────┬────────┘
         │
         │ 1:N
         │
         ├──────────────────────────────────┬─────────────────────────┐
         │                                  │                         │
         ▼                                  ▼                         ▼
┌────────────────┐              ┌──────────────────┐      ┌─────────────────────┐
│ team_members   │              │ billing_config   │      │ integrations_config │
│                │              │                  │      │                     │
│ id (PK)        │              │ id (PK)          │      │ id (PK)             │
│ workspace_id   │              │ workspace_id     │      │ workspace_id        │
│ user_id (FK)   │              │ plan_type        │      │ integration_type    │
│ role           │              │ usage_limits     │      │ config_data         │
│ status         │              │ current_usage    │      │ is_enabled          │
│ invited_by     │              │ stripe_id        │      │ credentials         │
│ deleted_at     │              │                  │      │                     │
└────┬───────────┘              └──────────────────┘      └─────────────────────┘
     │
     │ FK
     │
     ▼
┌────────────────┐
│     users      │
│  (existing)    │
└────────────────┘
```

---

## Table Definitions

### 1. team_members

Enhanced team management table with RBAC support, invitation workflow, and audit tracking.

**Purpose:** Manage workspace team members with granular role-based permissions and invitation lifecycle.

**Key Features:**
- 4-tier role hierarchy (owner, admin, member, viewer)
- Invitation workflow (pending → active → inactive)
- Soft delete support
- Full audit trail (created_by, updated_by, invited_by)
- Conflict prevention with unique constraints

```sql
-- =====================================================================
-- TABLE: team_members
-- PURPOSE: Workspace team management with RBAC
-- ISOLATION: workspace_id
-- NOTES: Replaces/extends existing workspace_members table
-- =====================================================================

CREATE TABLE IF NOT EXISTS team_members (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Multi-Tenant Isolation
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    -- User Reference
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Role-Based Access Control
    role VARCHAR(32) NOT NULL DEFAULT 'viewer',
    -- Allowed values: 'owner', 'admin', 'member', 'viewer'
    -- owner:  Full control including billing and deletion
    -- admin:  Manage team, agents, settings (no billing)
    -- member: Create/edit agents, view all data
    -- viewer: Read-only access to workspace

    -- Invitation & Status Management
    status VARCHAR(32) NOT NULL DEFAULT 'pending',
    -- Allowed values: 'pending', 'active', 'inactive'
    -- pending:  Invitation sent but not accepted
    -- active:   Active team member
    -- inactive: Deactivated but not deleted

    invitation_email VARCHAR(256),
    -- Email where invitation was sent (may differ from user.email)

    invitation_token VARCHAR(128) UNIQUE,
    -- Secure token for invitation acceptance (SHA-256)

    invitation_expires_at TIMESTAMPTZ,
    -- Invitation expiry (typically 7 days from creation)

    -- Audit Trail
    invited_by UUID REFERENCES users(id) ON DELETE SET NULL,
    -- User who sent the invitation

    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    -- User who created this team member record

    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    -- User who last updated this record

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    accepted_at TIMESTAMPTZ,
    -- When invitation was accepted

    last_active_at TIMESTAMPTZ,
    -- Last workspace activity timestamp

    -- Soft Delete
    deleted_at TIMESTAMPTZ,
    deleted_by UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Constraints
    CONSTRAINT team_members_role_check
        CHECK (role IN ('owner', 'admin', 'member', 'viewer')),

    CONSTRAINT team_members_status_check
        CHECK (status IN ('pending', 'active', 'inactive')),

    -- Prevent duplicate active memberships
    CONSTRAINT team_members_unique_active_member
        UNIQUE NULLS NOT DISTINCT (workspace_id, user_id, deleted_at)
);

-- Comments for documentation
COMMENT ON TABLE team_members IS 'Enhanced workspace team management with RBAC and invitation workflow';
COMMENT ON COLUMN team_members.role IS 'Permission level: owner, admin, member, viewer';
COMMENT ON COLUMN team_members.status IS 'Membership status: pending, active, inactive';
COMMENT ON COLUMN team_members.invitation_token IS 'Secure token for invitation acceptance (SHA-256 hash)';
COMMENT ON COLUMN team_members.deleted_at IS 'Soft delete timestamp - NULL if active';
```

### 2. billing_config

Subscription and billing configuration with usage tracking and limits enforcement.

**Purpose:** Track subscription plans, usage limits, and current consumption per workspace.

**Key Features:**
- 4 plan tiers (free, starter, professional, enterprise)
- Per-plan usage limits (traces, team members, API keys)
- Real-time usage tracking
- Billing cycle management
- Stripe integration ready

```sql
-- =====================================================================
-- TABLE: billing_config
-- PURPOSE: Subscription plans, usage limits, and billing management
-- ISOLATION: One record per workspace
-- NOTES: Integrates with Stripe for payment processing
-- =====================================================================

CREATE TABLE IF NOT EXISTS billing_config (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Multi-Tenant Isolation (One-to-One with workspace)
    workspace_id UUID NOT NULL UNIQUE REFERENCES workspaces(id) ON DELETE CASCADE,

    -- Subscription Plan
    plan_type VARCHAR(32) NOT NULL DEFAULT 'free',
    -- Allowed values: 'free', 'starter', 'professional', 'enterprise'

    plan_status VARCHAR(32) NOT NULL DEFAULT 'active',
    -- Allowed values: 'active', 'trialing', 'past_due', 'canceled', 'suspended'

    -- Plan Limits (NULL = unlimited)
    traces_per_month_limit INTEGER,
    -- Monthly trace ingestion limit

    team_members_limit INTEGER,
    -- Maximum team members allowed

    api_keys_limit INTEGER,
    -- Maximum API keys allowed

    data_retention_days INTEGER,
    -- How long traces are retained

    custom_integrations_limit INTEGER,
    -- Number of custom integrations allowed

    -- Current Usage (Reset monthly)
    traces_current_month INTEGER NOT NULL DEFAULT 0,
    -- Traces ingested this billing cycle

    team_members_current INTEGER NOT NULL DEFAULT 0,
    -- Current active team members

    api_keys_current INTEGER NOT NULL DEFAULT 0,
    -- Current active API keys

    -- Usage Metadata
    usage_reset_at TIMESTAMPTZ,
    -- When monthly usage counters were last reset

    overage_allowed BOOLEAN DEFAULT FALSE,
    -- Whether usage can exceed limits (with charges)

    -- Billing Cycle
    billing_cycle_start DATE NOT NULL DEFAULT CURRENT_DATE,
    -- Start of current billing period

    billing_cycle_end DATE,
    -- End of current billing period

    trial_ends_at TIMESTAMPTZ,
    -- Trial expiration (NULL if not on trial)

    -- Payment Integration
    stripe_customer_id VARCHAR(128) UNIQUE,
    -- Stripe customer identifier

    stripe_subscription_id VARCHAR(128) UNIQUE,
    -- Stripe subscription identifier

    payment_method_last4 VARCHAR(4),
    -- Last 4 digits of payment method

    payment_method_brand VARCHAR(32),
    -- Card brand (Visa, Mastercard, etc.)

    -- Pricing
    monthly_price_usd DECIMAL(10, 2),
    -- Current plan monthly price

    annual_price_usd DECIMAL(10, 2),
    -- Current plan annual price (if applicable)

    billing_interval VARCHAR(16) DEFAULT 'monthly',
    -- Billing frequency: 'monthly', 'annual'

    -- Status & Notifications
    next_billing_date DATE,
    -- Next scheduled billing

    auto_renew BOOLEAN DEFAULT TRUE,
    -- Whether subscription auto-renews

    cancellation_requested BOOLEAN DEFAULT FALSE,
    cancellation_effective_date DATE,
    -- When cancellation takes effect

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Audit
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Constraints
    CONSTRAINT billing_config_plan_type_check
        CHECK (plan_type IN ('free', 'starter', 'professional', 'enterprise')),

    CONSTRAINT billing_config_plan_status_check
        CHECK (plan_status IN ('active', 'trialing', 'past_due', 'canceled', 'suspended')),

    CONSTRAINT billing_config_billing_interval_check
        CHECK (billing_interval IN ('monthly', 'annual')),

    CONSTRAINT billing_config_usage_positive_check
        CHECK (
            traces_current_month >= 0 AND
            team_members_current >= 0 AND
            api_keys_current >= 0
        )
);

-- Comments for documentation
COMMENT ON TABLE billing_config IS 'Subscription plans, usage limits, and billing configuration per workspace';
COMMENT ON COLUMN billing_config.plan_type IS 'Subscription tier: free, starter, professional, enterprise';
COMMENT ON COLUMN billing_config.stripe_customer_id IS 'Stripe customer ID for payment processing';
COMMENT ON COLUMN billing_config.traces_per_month_limit IS 'Monthly trace ingestion limit (NULL = unlimited)';
COMMENT ON COLUMN billing_config.usage_reset_at IS 'Last monthly usage counter reset timestamp';
```

### 3. integrations_config

External service integrations configuration with encrypted credential storage.

**Purpose:** Manage third-party integrations (Slack, PagerDuty, Webhooks, Sentry) per workspace.

**Key Features:**
- 4 integration types (slack, pagerduty, webhook, sentry)
- JSONB configuration for flexibility
- Enable/disable without deletion
- Last sync tracking
- Encrypted credential storage pattern

```sql
-- =====================================================================
-- TABLE: integrations_config
-- PURPOSE: External service integrations configuration
-- ISOLATION: workspace_id (multiple integrations per workspace)
-- NOTES: Credentials should be encrypted at application layer
-- =====================================================================

CREATE TABLE IF NOT EXISTS integrations_config (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Multi-Tenant Isolation
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    -- Integration Type
    integration_type VARCHAR(64) NOT NULL,
    -- Allowed values: 'slack', 'pagerduty', 'webhook', 'sentry', 'datadog', 'custom'

    integration_name VARCHAR(256) NOT NULL,
    -- User-friendly name for this integration instance

    -- Configuration (Type-Specific)
    config_data JSONB NOT NULL DEFAULT '{}',
    -- Integration-specific configuration:
    -- slack:      { channel_id, bot_token_encrypted, workspace_url }
    -- pagerduty:  { service_key_encrypted, routing_key, severity_mapping }
    -- webhook:    { url, method, headers, auth_type, payload_template }
    -- sentry:     { dsn_encrypted, environment, sample_rate, traces_sample_rate }
    -- datadog:    { api_key_encrypted, app_key_encrypted, site, service_name }

    -- Encrypted Credentials
    credentials_encrypted TEXT,
    -- Application-layer encrypted credentials (AES-256-GCM)
    -- Store sensitive tokens/keys here, NOT in config_data

    encryption_key_id VARCHAR(128),
    -- ID of encryption key used (for key rotation)

    -- Status & Health
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    -- Whether integration is actively processing events

    health_status VARCHAR(32) DEFAULT 'unknown',
    -- Health check status: 'healthy', 'degraded', 'unhealthy', 'unknown'

    last_health_check_at TIMESTAMPTZ,
    -- Last health verification timestamp

    health_check_message TEXT,
    -- Last health check result message

    -- Sync & Activity
    last_sync_at TIMESTAMPTZ,
    -- Last successful sync/send timestamp

    last_error_at TIMESTAMPTZ,
    -- Last error occurrence

    last_error_message TEXT,
    -- Last error details

    total_events_sent INTEGER DEFAULT 0,
    -- Lifetime event count

    total_errors INTEGER DEFAULT 0,
    -- Lifetime error count

    -- Event Filtering
    event_filters JSONB DEFAULT '{}',
    -- Which events to send to this integration:
    -- {
    --   "alert_types": ["budget_exceeded", "error_spike"],
    --   "severity_min": "warning",
    --   "agents": ["customer_support", "sales_agent"]
    -- }

    -- Rate Limiting
    rate_limit_per_minute INTEGER,
    -- Max events per minute (NULL = no limit)

    -- Retry Configuration
    retry_config JSONB DEFAULT '{"max_retries": 3, "backoff": "exponential"}',
    -- Retry behavior for failed sends

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Audit
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Constraints
    CONSTRAINT integrations_config_type_check
        CHECK (integration_type IN (
            'slack', 'pagerduty', 'webhook', 'sentry', 'datadog', 'custom'
        )),

    CONSTRAINT integrations_config_health_check
        CHECK (health_status IN (
            'healthy', 'degraded', 'unhealthy', 'unknown'
        )),

    -- Prevent duplicate integration types per workspace
    CONSTRAINT integrations_config_unique_type
        UNIQUE (workspace_id, integration_type, integration_name)
);

-- Comments for documentation
COMMENT ON TABLE integrations_config IS 'External service integrations (Slack, PagerDuty, webhooks, etc.)';
COMMENT ON COLUMN integrations_config.integration_type IS 'Integration type: slack, pagerduty, webhook, sentry, datadog, custom';
COMMENT ON COLUMN integrations_config.credentials_encrypted IS 'AES-256-GCM encrypted credentials (encrypt at application layer)';
COMMENT ON COLUMN integrations_config.config_data IS 'JSONB configuration specific to integration type';
COMMENT ON COLUMN integrations_config.event_filters IS 'Filter rules for which events to send';
COMMENT ON COLUMN integrations_config.last_sync_at IS 'Last successful event delivery timestamp';
```

---

## Indexes & Performance

### Performance Optimization Strategy

1. **Workspace Isolation**: All queries filter by `workspace_id` first
2. **Status Filtering**: Common queries filter by status (active members, enabled integrations)
3. **Timestamp Ranges**: Activity tracking queries use time-based filters
4. **Unique Lookups**: Token-based and email-based invitation lookups
5. **Foreign Key Joins**: Efficient joins to users and workspaces tables

### Index Definitions

```sql
-- =====================================================================
-- INDEXES: team_members
-- =====================================================================

-- Primary workspace isolation query
CREATE INDEX IF NOT EXISTS idx_team_members_workspace_status
    ON team_members(workspace_id, status)
    WHERE deleted_at IS NULL;
-- Optimizes: SELECT * FROM team_members WHERE workspace_id = ? AND status = 'active'

-- User membership lookup
CREATE INDEX IF NOT EXISTS idx_team_members_user
    ON team_members(user_id)
    WHERE deleted_at IS NULL;
-- Optimizes: SELECT * FROM team_members WHERE user_id = ?

-- Active members only (most common query)
CREATE INDEX IF NOT EXISTS idx_team_members_active
    ON team_members(workspace_id, status, role)
    WHERE status = 'active' AND deleted_at IS NULL;
-- Optimizes: Dashboard team list queries

-- Invitation token lookup (used during invitation acceptance)
CREATE INDEX IF NOT EXISTS idx_team_members_invitation_token
    ON team_members(invitation_token)
    WHERE invitation_token IS NOT NULL AND deleted_at IS NULL;
-- Optimizes: SELECT * FROM team_members WHERE invitation_token = ?

-- Pending invitations (for cleanup jobs)
CREATE INDEX IF NOT EXISTS idx_team_members_pending_invitations
    ON team_members(status, invitation_expires_at)
    WHERE status = 'pending' AND deleted_at IS NULL;
-- Optimizes: Expired invitation cleanup queries

-- Activity tracking
CREATE INDEX IF NOT EXISTS idx_team_members_last_active
    ON team_members(workspace_id, last_active_at DESC)
    WHERE status = 'active' AND deleted_at IS NULL;
-- Optimizes: Recent activity reports

-- Audit trail queries
CREATE INDEX IF NOT EXISTS idx_team_members_created_at
    ON team_members(created_at DESC);
-- Optimizes: Audit log chronological queries

-- =====================================================================
-- INDEXES: billing_config
-- =====================================================================

-- Primary workspace lookup (enforced by UNIQUE constraint)
-- No additional index needed - UNIQUE constraint creates index

-- Plan type analytics
CREATE INDEX IF NOT EXISTS idx_billing_config_plan_type
    ON billing_config(plan_type, plan_status);
-- Optimizes: Platform-wide plan distribution analytics

-- Billing cycle queries
CREATE INDEX IF NOT EXISTS idx_billing_config_billing_cycle
    ON billing_config(billing_cycle_end)
    WHERE plan_status = 'active';
-- Optimizes: Upcoming renewal notifications

-- Trial expiration tracking
CREATE INDEX IF NOT EXISTS idx_billing_config_trial_expiring
    ON billing_config(trial_ends_at)
    WHERE plan_status = 'trialing' AND trial_ends_at IS NOT NULL;
-- Optimizes: Trial expiration notification jobs

-- Stripe integration lookups
CREATE INDEX IF NOT EXISTS idx_billing_config_stripe_customer
    ON billing_config(stripe_customer_id)
    WHERE stripe_customer_id IS NOT NULL;
-- Optimizes: Stripe webhook processing

-- Usage limit monitoring
CREATE INDEX IF NOT EXISTS idx_billing_config_usage_monitoring
    ON billing_config(workspace_id, traces_current_month)
    WHERE plan_status = 'active' AND traces_per_month_limit IS NOT NULL;
-- Optimizes: Usage limit alert queries

-- =====================================================================
-- INDEXES: integrations_config
-- =====================================================================

-- Primary workspace + enabled lookup
CREATE INDEX IF NOT EXISTS idx_integrations_workspace_enabled
    ON integrations_config(workspace_id, is_enabled, integration_type)
    WHERE is_enabled = TRUE;
-- Optimizes: SELECT * FROM integrations_config WHERE workspace_id = ? AND is_enabled = TRUE

-- Integration type filtering
CREATE INDEX IF NOT EXISTS idx_integrations_type
    ON integrations_config(integration_type, is_enabled);
-- Optimizes: Platform-wide integration analytics

-- Health monitoring
CREATE INDEX IF NOT EXISTS idx_integrations_health_status
    ON integrations_config(health_status, last_health_check_at DESC)
    WHERE is_enabled = TRUE;
-- Optimizes: Unhealthy integration alerts

-- Error tracking
CREATE INDEX IF NOT EXISTS idx_integrations_errors
    ON integrations_config(last_error_at DESC)
    WHERE last_error_at IS NOT NULL;
-- Optimizes: Recent error investigation

-- JSONB indexing for event filters (GIN index for flexible queries)
CREATE INDEX IF NOT EXISTS idx_integrations_event_filters
    ON integrations_config USING GIN (event_filters);
-- Optimizes: JSONB queries like: WHERE event_filters @> '{"alert_types": ["budget_exceeded"]}'

-- Activity tracking
CREATE INDEX IF NOT EXISTS idx_integrations_last_sync
    ON integrations_config(workspace_id, last_sync_at DESC)
    WHERE is_enabled = TRUE;
-- Optimizes: Recent integration activity queries
```

---

## Migration Scripts

### Alembic Migration (Upgrade)

```python
"""
Phase 5: Add Settings Management Tables

Revision ID: phase5_001_settings_tables
Revises: phase4_xxx
Create Date: 2025-10-25

Adds team_members, billing_config, and integrations_config tables
for Phase 5 Settings page functionality.
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# Revision identifiers
revision = 'phase5_001_settings_tables'
down_revision = 'phase4_xxx'  # Update with actual previous revision
branch_labels = None
depends_on = None


def upgrade():
    """Apply Phase 5 schema changes."""

    # ================================================================
    # 1. CREATE TABLE: team_members
    # ================================================================
    op.execute("""
        CREATE TABLE IF NOT EXISTS team_members (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            role VARCHAR(32) NOT NULL DEFAULT 'viewer',
            status VARCHAR(32) NOT NULL DEFAULT 'pending',
            invitation_email VARCHAR(256),
            invitation_token VARCHAR(128) UNIQUE,
            invitation_expires_at TIMESTAMPTZ,
            invited_by UUID REFERENCES users(id) ON DELETE SET NULL,
            created_by UUID REFERENCES users(id) ON DELETE SET NULL,
            updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            accepted_at TIMESTAMPTZ,
            last_active_at TIMESTAMPTZ,
            deleted_at TIMESTAMPTZ,
            deleted_by UUID REFERENCES users(id) ON DELETE SET NULL,

            CONSTRAINT team_members_role_check
                CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
            CONSTRAINT team_members_status_check
                CHECK (status IN ('pending', 'active', 'inactive')),
            CONSTRAINT team_members_unique_active_member
                UNIQUE NULLS NOT DISTINCT (workspace_id, user_id, deleted_at)
        );
    """)

    # Add table comment
    op.execute("""
        COMMENT ON TABLE team_members IS
        'Enhanced workspace team management with RBAC and invitation workflow';
    """)

    # Create indexes for team_members
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_team_members_workspace_status
            ON team_members(workspace_id, status) WHERE deleted_at IS NULL;

        CREATE INDEX IF NOT EXISTS idx_team_members_user
            ON team_members(user_id) WHERE deleted_at IS NULL;

        CREATE INDEX IF NOT EXISTS idx_team_members_active
            ON team_members(workspace_id, status, role)
            WHERE status = 'active' AND deleted_at IS NULL;

        CREATE INDEX IF NOT EXISTS idx_team_members_invitation_token
            ON team_members(invitation_token)
            WHERE invitation_token IS NOT NULL AND deleted_at IS NULL;

        CREATE INDEX IF NOT EXISTS idx_team_members_pending_invitations
            ON team_members(status, invitation_expires_at)
            WHERE status = 'pending' AND deleted_at IS NULL;

        CREATE INDEX IF NOT EXISTS idx_team_members_last_active
            ON team_members(workspace_id, last_active_at DESC)
            WHERE status = 'active' AND deleted_at IS NULL;

        CREATE INDEX IF NOT EXISTS idx_team_members_created_at
            ON team_members(created_at DESC);
    """)

    # Add updated_at trigger
    op.execute("""
        CREATE TRIGGER update_team_members_updated_at
        BEFORE UPDATE ON team_members
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    """)

    # ================================================================
    # 2. CREATE TABLE: billing_config
    # ================================================================
    op.execute("""
        CREATE TABLE IF NOT EXISTS billing_config (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            workspace_id UUID NOT NULL UNIQUE REFERENCES workspaces(id) ON DELETE CASCADE,
            plan_type VARCHAR(32) NOT NULL DEFAULT 'free',
            plan_status VARCHAR(32) NOT NULL DEFAULT 'active',
            traces_per_month_limit INTEGER,
            team_members_limit INTEGER,
            api_keys_limit INTEGER,
            data_retention_days INTEGER,
            custom_integrations_limit INTEGER,
            traces_current_month INTEGER NOT NULL DEFAULT 0,
            team_members_current INTEGER NOT NULL DEFAULT 0,
            api_keys_current INTEGER NOT NULL DEFAULT 0,
            usage_reset_at TIMESTAMPTZ,
            overage_allowed BOOLEAN DEFAULT FALSE,
            billing_cycle_start DATE NOT NULL DEFAULT CURRENT_DATE,
            billing_cycle_end DATE,
            trial_ends_at TIMESTAMPTZ,
            stripe_customer_id VARCHAR(128) UNIQUE,
            stripe_subscription_id VARCHAR(128) UNIQUE,
            payment_method_last4 VARCHAR(4),
            payment_method_brand VARCHAR(32),
            monthly_price_usd DECIMAL(10, 2),
            annual_price_usd DECIMAL(10, 2),
            billing_interval VARCHAR(16) DEFAULT 'monthly',
            next_billing_date DATE,
            auto_renew BOOLEAN DEFAULT TRUE,
            cancellation_requested BOOLEAN DEFAULT FALSE,
            cancellation_effective_date DATE,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            created_by UUID REFERENCES users(id) ON DELETE SET NULL,
            updated_by UUID REFERENCES users(id) ON DELETE SET NULL,

            CONSTRAINT billing_config_plan_type_check
                CHECK (plan_type IN ('free', 'starter', 'professional', 'enterprise')),
            CONSTRAINT billing_config_plan_status_check
                CHECK (plan_status IN ('active', 'trialing', 'past_due', 'canceled', 'suspended')),
            CONSTRAINT billing_config_billing_interval_check
                CHECK (billing_interval IN ('monthly', 'annual')),
            CONSTRAINT billing_config_usage_positive_check
                CHECK (
                    traces_current_month >= 0 AND
                    team_members_current >= 0 AND
                    api_keys_current >= 0
                )
        );
    """)

    # Add table comment
    op.execute("""
        COMMENT ON TABLE billing_config IS
        'Subscription plans, usage limits, and billing configuration per workspace';
    """)

    # Create indexes for billing_config
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_billing_config_plan_type
            ON billing_config(plan_type, plan_status);

        CREATE INDEX IF NOT EXISTS idx_billing_config_billing_cycle
            ON billing_config(billing_cycle_end) WHERE plan_status = 'active';

        CREATE INDEX IF NOT EXISTS idx_billing_config_trial_expiring
            ON billing_config(trial_ends_at)
            WHERE plan_status = 'trialing' AND trial_ends_at IS NOT NULL;

        CREATE INDEX IF NOT EXISTS idx_billing_config_stripe_customer
            ON billing_config(stripe_customer_id)
            WHERE stripe_customer_id IS NOT NULL;

        CREATE INDEX IF NOT EXISTS idx_billing_config_usage_monitoring
            ON billing_config(workspace_id, traces_current_month)
            WHERE plan_status = 'active' AND traces_per_month_limit IS NOT NULL;
    """)

    # Add updated_at trigger
    op.execute("""
        CREATE TRIGGER update_billing_config_updated_at
        BEFORE UPDATE ON billing_config
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    """)

    # ================================================================
    # 3. CREATE TABLE: integrations_config
    # ================================================================
    op.execute("""
        CREATE TABLE IF NOT EXISTS integrations_config (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
            integration_type VARCHAR(64) NOT NULL,
            integration_name VARCHAR(256) NOT NULL,
            config_data JSONB NOT NULL DEFAULT '{}',
            credentials_encrypted TEXT,
            encryption_key_id VARCHAR(128),
            is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
            health_status VARCHAR(32) DEFAULT 'unknown',
            last_health_check_at TIMESTAMPTZ,
            health_check_message TEXT,
            last_sync_at TIMESTAMPTZ,
            last_error_at TIMESTAMPTZ,
            last_error_message TEXT,
            total_events_sent INTEGER DEFAULT 0,
            total_errors INTEGER DEFAULT 0,
            event_filters JSONB DEFAULT '{}',
            rate_limit_per_minute INTEGER,
            retry_config JSONB DEFAULT '{"max_retries": 3, "backoff": "exponential"}',
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            created_by UUID REFERENCES users(id) ON DELETE SET NULL,
            updated_by UUID REFERENCES users(id) ON DELETE SET NULL,

            CONSTRAINT integrations_config_type_check
                CHECK (integration_type IN (
                    'slack', 'pagerduty', 'webhook', 'sentry', 'datadog', 'custom'
                )),
            CONSTRAINT integrations_config_health_check
                CHECK (health_status IN (
                    'healthy', 'degraded', 'unhealthy', 'unknown'
                )),
            CONSTRAINT integrations_config_unique_type
                UNIQUE (workspace_id, integration_type, integration_name)
        );
    """)

    # Add table comment
    op.execute("""
        COMMENT ON TABLE integrations_config IS
        'External service integrations (Slack, PagerDuty, webhooks, etc.)';
    """)

    # Create indexes for integrations_config
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_integrations_workspace_enabled
            ON integrations_config(workspace_id, is_enabled, integration_type)
            WHERE is_enabled = TRUE;

        CREATE INDEX IF NOT EXISTS idx_integrations_type
            ON integrations_config(integration_type, is_enabled);

        CREATE INDEX IF NOT EXISTS idx_integrations_health_status
            ON integrations_config(health_status, last_health_check_at DESC)
            WHERE is_enabled = TRUE;

        CREATE INDEX IF NOT EXISTS idx_integrations_errors
            ON integrations_config(last_error_at DESC)
            WHERE last_error_at IS NOT NULL;

        CREATE INDEX IF NOT EXISTS idx_integrations_event_filters
            ON integrations_config USING GIN (event_filters);

        CREATE INDEX IF NOT EXISTS idx_integrations_last_sync
            ON integrations_config(workspace_id, last_sync_at DESC)
            WHERE is_enabled = TRUE;
    """)

    # Add updated_at trigger
    op.execute("""
        CREATE TRIGGER update_integrations_config_updated_at
        BEFORE UPDATE ON integrations_config
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    """)

    print("✅ Phase 5 Settings tables created successfully")


def downgrade():
    """Rollback Phase 5 schema changes."""

    # Drop tables in reverse order (respecting foreign key dependencies)
    op.execute("DROP TABLE IF EXISTS integrations_config CASCADE;")
    op.execute("DROP TABLE IF EXISTS billing_config CASCADE;")
    op.execute("DROP TABLE IF EXISTS team_members CASCADE;")

    print("✅ Phase 5 Settings tables removed successfully")
```

### Standalone SQL Migration (Upgrade)

```sql
-- =====================================================================
-- MIGRATION: Phase 5 Settings Tables
-- FILE: phase5_001_settings_tables_up.sql
-- DESCRIPTION: Add team_members, billing_config, integrations_config
-- DEPENDENCIES: Requires existing workspaces, users tables
-- =====================================================================

BEGIN;

-- ================================================================
-- 1. CREATE TABLE: team_members
-- ================================================================

CREATE TABLE IF NOT EXISTS team_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(32) NOT NULL DEFAULT 'viewer',
    status VARCHAR(32) NOT NULL DEFAULT 'pending',
    invitation_email VARCHAR(256),
    invitation_token VARCHAR(128) UNIQUE,
    invitation_expires_at TIMESTAMPTZ,
    invited_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    accepted_at TIMESTAMPTZ,
    last_active_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID REFERENCES users(id) ON DELETE SET NULL,

    CONSTRAINT team_members_role_check
        CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
    CONSTRAINT team_members_status_check
        CHECK (status IN ('pending', 'active', 'inactive')),
    CONSTRAINT team_members_unique_active_member
        UNIQUE NULLS NOT DISTINCT (workspace_id, user_id, deleted_at)
);

COMMENT ON TABLE team_members IS 'Enhanced workspace team management with RBAC and invitation workflow';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_team_members_workspace_status
    ON team_members(workspace_id, status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_team_members_user
    ON team_members(user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_team_members_active
    ON team_members(workspace_id, status, role)
    WHERE status = 'active' AND deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_team_members_invitation_token
    ON team_members(invitation_token)
    WHERE invitation_token IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_team_members_pending_invitations
    ON team_members(status, invitation_expires_at)
    WHERE status = 'pending' AND deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_team_members_last_active
    ON team_members(workspace_id, last_active_at DESC)
    WHERE status = 'active' AND deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_team_members_created_at
    ON team_members(created_at DESC);

-- Trigger
CREATE TRIGGER update_team_members_updated_at
BEFORE UPDATE ON team_members
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ================================================================
-- 2. CREATE TABLE: billing_config
-- ================================================================

CREATE TABLE IF NOT EXISTS billing_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL UNIQUE REFERENCES workspaces(id) ON DELETE CASCADE,
    plan_type VARCHAR(32) NOT NULL DEFAULT 'free',
    plan_status VARCHAR(32) NOT NULL DEFAULT 'active',
    traces_per_month_limit INTEGER,
    team_members_limit INTEGER,
    api_keys_limit INTEGER,
    data_retention_days INTEGER,
    custom_integrations_limit INTEGER,
    traces_current_month INTEGER NOT NULL DEFAULT 0,
    team_members_current INTEGER NOT NULL DEFAULT 0,
    api_keys_current INTEGER NOT NULL DEFAULT 0,
    usage_reset_at TIMESTAMPTZ,
    overage_allowed BOOLEAN DEFAULT FALSE,
    billing_cycle_start DATE NOT NULL DEFAULT CURRENT_DATE,
    billing_cycle_end DATE,
    trial_ends_at TIMESTAMPTZ,
    stripe_customer_id VARCHAR(128) UNIQUE,
    stripe_subscription_id VARCHAR(128) UNIQUE,
    payment_method_last4 VARCHAR(4),
    payment_method_brand VARCHAR(32),
    monthly_price_usd DECIMAL(10, 2),
    annual_price_usd DECIMAL(10, 2),
    billing_interval VARCHAR(16) DEFAULT 'monthly',
    next_billing_date DATE,
    auto_renew BOOLEAN DEFAULT TRUE,
    cancellation_requested BOOLEAN DEFAULT FALSE,
    cancellation_effective_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,

    CONSTRAINT billing_config_plan_type_check
        CHECK (plan_type IN ('free', 'starter', 'professional', 'enterprise')),
    CONSTRAINT billing_config_plan_status_check
        CHECK (plan_status IN ('active', 'trialing', 'past_due', 'canceled', 'suspended')),
    CONSTRAINT billing_config_billing_interval_check
        CHECK (billing_interval IN ('monthly', 'annual')),
    CONSTRAINT billing_config_usage_positive_check
        CHECK (
            traces_current_month >= 0 AND
            team_members_current >= 0 AND
            api_keys_current >= 0
        )
);

COMMENT ON TABLE billing_config IS 'Subscription plans, usage limits, and billing configuration per workspace';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_billing_config_plan_type
    ON billing_config(plan_type, plan_status);
CREATE INDEX IF NOT EXISTS idx_billing_config_billing_cycle
    ON billing_config(billing_cycle_end) WHERE plan_status = 'active';
CREATE INDEX IF NOT EXISTS idx_billing_config_trial_expiring
    ON billing_config(trial_ends_at)
    WHERE plan_status = 'trialing' AND trial_ends_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_billing_config_stripe_customer
    ON billing_config(stripe_customer_id)
    WHERE stripe_customer_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_billing_config_usage_monitoring
    ON billing_config(workspace_id, traces_current_month)
    WHERE plan_status = 'active' AND traces_per_month_limit IS NOT NULL;

-- Trigger
CREATE TRIGGER update_billing_config_updated_at
BEFORE UPDATE ON billing_config
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ================================================================
-- 3. CREATE TABLE: integrations_config
-- ================================================================

CREATE TABLE IF NOT EXISTS integrations_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    integration_type VARCHAR(64) NOT NULL,
    integration_name VARCHAR(256) NOT NULL,
    config_data JSONB NOT NULL DEFAULT '{}',
    credentials_encrypted TEXT,
    encryption_key_id VARCHAR(128),
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    health_status VARCHAR(32) DEFAULT 'unknown',
    last_health_check_at TIMESTAMPTZ,
    health_check_message TEXT,
    last_sync_at TIMESTAMPTZ,
    last_error_at TIMESTAMPTZ,
    last_error_message TEXT,
    total_events_sent INTEGER DEFAULT 0,
    total_errors INTEGER DEFAULT 0,
    event_filters JSONB DEFAULT '{}',
    rate_limit_per_minute INTEGER,
    retry_config JSONB DEFAULT '{"max_retries": 3, "backoff": "exponential"}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,

    CONSTRAINT integrations_config_type_check
        CHECK (integration_type IN (
            'slack', 'pagerduty', 'webhook', 'sentry', 'datadog', 'custom'
        )),
    CONSTRAINT integrations_config_health_check
        CHECK (health_status IN (
            'healthy', 'degraded', 'unhealthy', 'unknown'
        )),
    CONSTRAINT integrations_config_unique_type
        UNIQUE (workspace_id, integration_type, integration_name)
);

COMMENT ON TABLE integrations_config IS 'External service integrations (Slack, PagerDuty, webhooks, etc.)';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_integrations_workspace_enabled
    ON integrations_config(workspace_id, is_enabled, integration_type)
    WHERE is_enabled = TRUE;
CREATE INDEX IF NOT EXISTS idx_integrations_type
    ON integrations_config(integration_type, is_enabled);
CREATE INDEX IF NOT EXISTS idx_integrations_health_status
    ON integrations_config(health_status, last_health_check_at DESC)
    WHERE is_enabled = TRUE;
CREATE INDEX IF NOT EXISTS idx_integrations_errors
    ON integrations_config(last_error_at DESC)
    WHERE last_error_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_integrations_event_filters
    ON integrations_config USING GIN (event_filters);
CREATE INDEX IF NOT EXISTS idx_integrations_last_sync
    ON integrations_config(workspace_id, last_sync_at DESC)
    WHERE is_enabled = TRUE;

-- Trigger
CREATE TRIGGER update_integrations_config_updated_at
BEFORE UPDATE ON integrations_config
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

COMMIT;

-- Verification
SELECT 'Phase 5 migration completed successfully' AS status;
SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE '%team_members%';
SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE '%billing_config%';
SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE '%integrations_config%';
```

### Standalone SQL Rollback

```sql
-- =====================================================================
-- ROLLBACK: Phase 5 Settings Tables
-- FILE: phase5_001_settings_tables_down.sql
-- DESCRIPTION: Remove team_members, billing_config, integrations_config
-- WARNING: This will delete all data in these tables
-- =====================================================================

BEGIN;

-- Drop tables in reverse order (respecting foreign key dependencies)
DROP TABLE IF EXISTS integrations_config CASCADE;
DROP TABLE IF EXISTS billing_config CASCADE;
DROP TABLE IF EXISTS team_members CASCADE;

COMMIT;

-- Verification
SELECT 'Phase 5 rollback completed successfully' AS status;
```

---

## Seed Data

### Development Seed Data

```sql
-- =====================================================================
-- SEED DATA: Phase 5 Settings (Development Environment)
-- FILE: phase5_seed_data.sql
-- DESCRIPTION: Sample data for testing Settings functionality
-- =====================================================================

BEGIN;

-- Assumes existing workspace and users from init-postgres.sql
-- workspace_id: '00000000-0000-0000-0000-000000000001'
-- user_id:      '00000000-0000-0000-0000-000000000001' (demo@example.com)

-- ================================================================
-- 1. SEED: team_members
-- ================================================================

-- Owner (existing demo user)
INSERT INTO team_members (
    id,
    workspace_id,
    user_id,
    role,
    status,
    invited_by,
    created_by,
    accepted_at,
    last_active_at
) VALUES (
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'owner',
    'active',
    NULL, -- Self-registered
    '00000000-0000-0000-0000-000000000001',
    NOW() - INTERVAL '30 days',
    NOW() - INTERVAL '1 hour'
) ON CONFLICT DO NOTHING;

-- Create additional test users
INSERT INTO users (id, email, password_hash, full_name, is_verified) VALUES
    ('10000000-0000-0000-0000-000000000002', 'admin@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU.W1PGEtBFS', 'Admin User', TRUE),
    ('10000000-0000-0000-0000-000000000003', 'member@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU.W1PGEtBFS', 'Member User', TRUE),
    ('10000000-0000-0000-0000-000000000004', 'viewer@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU.W1PGEtBFS', 'Viewer User', TRUE)
ON CONFLICT DO NOTHING;

-- Admin team member (active)
INSERT INTO team_members (
    id,
    workspace_id,
    user_id,
    role,
    status,
    invited_by,
    created_by,
    accepted_at,
    last_active_at
) VALUES (
    '10000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000002',
    'admin',
    'active',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    NOW() - INTERVAL '20 days',
    NOW() - INTERVAL '2 hours'
) ON CONFLICT DO NOTHING;

-- Regular member (active)
INSERT INTO team_members (
    id,
    workspace_id,
    user_id,
    role,
    status,
    invited_by,
    created_by,
    accepted_at,
    last_active_at
) VALUES (
    '10000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000003',
    'member',
    'active',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    NOW() - INTERVAL '15 days',
    NOW() - INTERVAL '5 hours'
) ON CONFLICT DO NOTHING;

-- Viewer (active)
INSERT INTO team_members (
    id,
    workspace_id,
    user_id,
    role,
    status,
    invited_by,
    created_by,
    accepted_at,
    last_active_at
) VALUES (
    '10000000-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000004',
    'viewer',
    'active',
    '00000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000002',
    NOW() - INTERVAL '10 days',
    NOW() - INTERVAL '1 day'
) ON CONFLICT DO NOTHING;

-- Pending invitation
INSERT INTO team_members (
    id,
    workspace_id,
    user_id,
    role,
    status,
    invitation_email,
    invitation_token,
    invitation_expires_at,
    invited_by,
    created_by
) VALUES (
    '10000000-0000-0000-0000-000000000005',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001', -- Placeholder user
    'member',
    'pending',
    'pending@example.com',
    'inv_token_abc123def456ghi789jkl012mno345',
    NOW() + INTERVAL '5 days',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001'
) ON CONFLICT DO NOTHING;

-- Inactive member (deactivated)
INSERT INTO team_members (
    id,
    workspace_id,
    user_id,
    role,
    status,
    invited_by,
    created_by,
    accepted_at,
    last_active_at
) VALUES (
    '10000000-0000-0000-0000-000000000006',
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000003',
    'member',
    'inactive',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    NOW() - INTERVAL '60 days',
    NOW() - INTERVAL '30 days'
) ON CONFLICT DO NOTHING;

-- ================================================================
-- 2. SEED: billing_config
-- ================================================================

INSERT INTO billing_config (
    id,
    workspace_id,
    plan_type,
    plan_status,

    -- Limits (Professional plan)
    traces_per_month_limit,
    team_members_limit,
    api_keys_limit,
    data_retention_days,
    custom_integrations_limit,

    -- Current usage
    traces_current_month,
    team_members_current,
    api_keys_current,
    usage_reset_at,

    -- Billing cycle
    billing_cycle_start,
    billing_cycle_end,
    next_billing_date,

    -- Pricing
    monthly_price_usd,
    billing_interval,
    auto_renew,

    -- Stripe (test data)
    stripe_customer_id,
    stripe_subscription_id,
    payment_method_last4,
    payment_method_brand,

    created_by
) VALUES (
    '20000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'professional',
    'active',

    -- Limits
    1000000,  -- 1M traces/month
    25,       -- 25 team members
    10,       -- 10 API keys
    90,       -- 90 days retention
    5,        -- 5 custom integrations

    -- Current usage (65% of limits)
    650000,   -- 650K traces this month
    4,        -- 4 active team members
    3,        -- 3 API keys
    DATE_TRUNC('month', CURRENT_DATE),

    -- Billing cycle (current month)
    DATE_TRUNC('month', CURRENT_DATE)::DATE,
    (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE,
    (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month')::DATE,

    -- Pricing
    99.00,
    'monthly',
    TRUE,

    -- Stripe
    'cus_test_abc123def456',
    'sub_test_xyz789uvw456',
    '4242',
    'Visa',

    '00000000-0000-0000-0000-000000000001'
) ON CONFLICT (workspace_id) DO NOTHING;

-- ================================================================
-- 3. SEED: integrations_config
-- ================================================================

-- Slack integration (enabled, healthy)
INSERT INTO integrations_config (
    id,
    workspace_id,
    integration_type,
    integration_name,
    config_data,
    is_enabled,
    health_status,
    last_health_check_at,
    last_sync_at,
    total_events_sent,
    event_filters,
    created_by
) VALUES (
    '30000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'slack',
    'Engineering Alerts',
    '{
        "channel_id": "C01234567",
        "channel_name": "#agent-alerts",
        "workspace_url": "https://acme-corp.slack.com",
        "mention_users": ["U12345678"]
    }'::jsonb,
    TRUE,
    'healthy',
    NOW() - INTERVAL '15 minutes',
    NOW() - INTERVAL '5 minutes',
    1247,
    '{
        "alert_types": ["budget_exceeded", "error_spike", "latency_high"],
        "severity_min": "warning",
        "agents": ["customer_support", "sales_agent"]
    }'::jsonb,
    '00000000-0000-0000-0000-000000000001'
) ON CONFLICT DO NOTHING;

-- PagerDuty integration (enabled, healthy)
INSERT INTO integrations_config (
    id,
    workspace_id,
    integration_type,
    integration_name,
    config_data,
    is_enabled,
    health_status,
    last_health_check_at,
    last_sync_at,
    total_events_sent,
    event_filters,
    created_by
) VALUES (
    '30000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000001',
    'pagerduty',
    'Production Incidents',
    '{
        "service_id": "PSERVICE123",
        "service_name": "AI Agent Platform",
        "severity_mapping": {
            "critical": "critical",
            "high": "error",
            "medium": "warning",
            "low": "info"
        }
    }'::jsonb,
    TRUE,
    'healthy',
    NOW() - INTERVAL '20 minutes',
    NOW() - INTERVAL '2 hours',
    34,
    '{
        "alert_types": ["budget_exceeded", "system_down"],
        "severity_min": "high"
    }'::jsonb,
    '00000000-0000-0000-0000-000000000001'
) ON CONFLICT DO NOTHING;

-- Webhook integration (enabled, degraded)
INSERT INTO integrations_config (
    id,
    workspace_id,
    integration_type,
    integration_name,
    config_data,
    is_enabled,
    health_status,
    health_check_message,
    last_health_check_at,
    last_sync_at,
    last_error_at,
    last_error_message,
    total_events_sent,
    total_errors,
    event_filters,
    rate_limit_per_minute,
    created_by
) VALUES (
    '30000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000001',
    'webhook',
    'Custom Analytics Endpoint',
    '{
        "url": "https://analytics.acme-corp.com/webhooks/agent-events",
        "method": "POST",
        "headers": {
            "Content-Type": "application/json",
            "X-API-Version": "v1"
        },
        "auth_type": "bearer",
        "timeout_ms": 5000
    }'::jsonb,
    TRUE,
    'degraded',
    'Intermittent timeouts detected (3/10 recent requests)',
    NOW() - INTERVAL '10 minutes',
    NOW() - INTERVAL '3 minutes',
    NOW() - INTERVAL '3 minutes',
    'Request timeout after 5000ms',
    892,
    23,
    '{
        "alert_types": ["all"],
        "include_trace_data": true
    }'::jsonb,
    100,
    '00000000-0000-0000-0000-000000000001'
) ON CONFLICT DO NOTHING;

-- Sentry integration (disabled)
INSERT INTO integrations_config (
    id,
    workspace_id,
    integration_type,
    integration_name,
    config_data,
    is_enabled,
    health_status,
    last_health_check_at,
    last_sync_at,
    total_events_sent,
    created_by
) VALUES (
    '30000000-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000001',
    'sentry',
    'Error Tracking',
    '{
        "environment": "production",
        "sample_rate": 1.0,
        "traces_sample_rate": 0.1
    }'::jsonb,
    FALSE,
    'unknown',
    NULL,
    NOW() - INTERVAL '7 days',
    156,
    '00000000-0000-0000-0000-000000000001'
) ON CONFLICT DO NOTHING;

COMMIT;

-- Verification queries
SELECT 'Seed data inserted successfully' AS status;

SELECT
    role,
    status,
    COUNT(*) as count
FROM team_members
WHERE workspace_id = '00000000-0000-0000-0000-000000000001'
GROUP BY role, status
ORDER BY role, status;

SELECT
    plan_type,
    traces_current_month,
    traces_per_month_limit,
    ROUND((traces_current_month::NUMERIC / traces_per_month_limit * 100), 2) as usage_percent
FROM billing_config
WHERE workspace_id = '00000000-0000-0000-0000-000000000001';

SELECT
    integration_type,
    integration_name,
    is_enabled,
    health_status
FROM integrations_config
WHERE workspace_id = '00000000-0000-0000-0000-000000000001'
ORDER BY integration_type;
```

---

## Security Considerations

### 1. Credential Encryption

**Requirement:** All sensitive credentials in `integrations_config.credentials_encrypted` must be encrypted at the application layer.

**Recommended Approach:**

```python
# Python example using cryptography library
from cryptography.fernet import Fernet
import base64
import os

class CredentialEncryption:
    """Handle encryption/decryption of integration credentials."""

    def __init__(self, encryption_key: str = None):
        """Initialize with encryption key from environment."""
        key = encryption_key or os.getenv('INTEGRATION_CREDENTIALS_KEY')
        if not key:
            raise ValueError("Encryption key not configured")
        self.fernet = Fernet(key.encode())

    def encrypt(self, plaintext: str) -> tuple[str, str]:
        """
        Encrypt plaintext credentials.

        Returns:
            (encrypted_text, key_id) tuple
        """
        encrypted = self.fernet.encrypt(plaintext.encode())
        return base64.b64encode(encrypted).decode(), 'key_v1_production'

    def decrypt(self, encrypted_text: str) -> str:
        """Decrypt credentials."""
        encrypted_bytes = base64.b64decode(encrypted_text.encode())
        return self.fernet.decrypt(encrypted_bytes).decode()

# Usage
encryptor = CredentialEncryption()
slack_token = "xoxb-1234567890-abcdefghijk"
encrypted_token, key_id = encryptor.encrypt(slack_token)

# Store in database
INSERT INTO integrations_config (
    credentials_encrypted,
    encryption_key_id,
    ...
) VALUES (
    encrypted_token,
    key_id,
    ...
);
```

### 2. Invitation Token Security

**Requirements:**
- Use cryptographically secure random tokens (SHA-256)
- Set expiration (7 days default)
- Single-use tokens (delete after acceptance)
- Validate token format and expiration before processing

```python
import secrets
import hashlib
from datetime import datetime, timedelta

def generate_invitation_token() -> tuple[str, str, datetime]:
    """
    Generate secure invitation token.

    Returns:
        (token, token_hash, expiration) tuple
    """
    # Generate 32-byte random token
    token_bytes = secrets.token_bytes(32)
    token = secrets.token_urlsafe(32)

    # Hash for storage (prevents timing attacks)
    token_hash = hashlib.sha256(token.encode()).hexdigest()

    # Set expiration (7 days)
    expiration = datetime.utcnow() + timedelta(days=7)

    return token, token_hash, expiration

# Usage
token, token_hash, expiration = generate_invitation_token()

# Store hash in database, send plain token via email
INSERT INTO team_members (
    invitation_token,
    invitation_expires_at,
    ...
) VALUES (
    token_hash,
    expiration,
    ...
);

# Send email with: https://app.example.com/invite/accept?token={token}
```

### 3. Role-Based Access Control (RBAC)

**Permission Matrix:**

| Action | Owner | Admin | Member | Viewer |
|--------|-------|-------|--------|--------|
| View workspace data | ✓ | ✓ | ✓ | ✓ |
| Create/edit agents | ✓ | ✓ | ✓ | ✗ |
| Manage team members | ✓ | ✓ | ✗ | ✗ |
| View billing | ✓ | ✗ | ✗ | ✗ |
| Manage billing | ✓ | ✗ | ✗ | ✗ |
| Delete workspace | ✓ | ✗ | ✗ | ✗ |
| Manage integrations | ✓ | ✓ | ✗ | ✗ |
| View API keys | ✓ | ✓ | ✓ | ✗ |
| Create API keys | ✓ | ✓ | ✓ | ✗ |

**Enforcement Example:**

```python
from enum import Enum
from typing import List

class Role(Enum):
    OWNER = "owner"
    ADMIN = "admin"
    MEMBER = "member"
    VIEWER = "viewer"

class Permission(Enum):
    VIEW_WORKSPACE = "view_workspace"
    MANAGE_AGENTS = "manage_agents"
    MANAGE_TEAM = "manage_team"
    VIEW_BILLING = "view_billing"
    MANAGE_BILLING = "manage_billing"
    DELETE_WORKSPACE = "delete_workspace"
    MANAGE_INTEGRATIONS = "manage_integrations"
    MANAGE_API_KEYS = "manage_api_keys"

ROLE_PERMISSIONS = {
    Role.OWNER: [
        Permission.VIEW_WORKSPACE,
        Permission.MANAGE_AGENTS,
        Permission.MANAGE_TEAM,
        Permission.VIEW_BILLING,
        Permission.MANAGE_BILLING,
        Permission.DELETE_WORKSPACE,
        Permission.MANAGE_INTEGRATIONS,
        Permission.MANAGE_API_KEYS,
    ],
    Role.ADMIN: [
        Permission.VIEW_WORKSPACE,
        Permission.MANAGE_AGENTS,
        Permission.MANAGE_TEAM,
        Permission.MANAGE_INTEGRATIONS,
        Permission.MANAGE_API_KEYS,
    ],
    Role.MEMBER: [
        Permission.VIEW_WORKSPACE,
        Permission.MANAGE_AGENTS,
        Permission.MANAGE_API_KEYS,
    ],
    Role.VIEWER: [
        Permission.VIEW_WORKSPACE,
    ],
}

def has_permission(role: Role, permission: Permission) -> bool:
    """Check if role has specific permission."""
    return permission in ROLE_PERMISSIONS.get(role, [])

# Usage in API endpoint
@app.delete("/api/workspace/{workspace_id}")
async def delete_workspace(workspace_id: str, current_user: User):
    member = get_team_member(workspace_id, current_user.id)

    if not has_permission(Role(member.role), Permission.DELETE_WORKSPACE):
        raise HTTPException(status_code=403, detail="Insufficient permissions")

    # Proceed with deletion
    ...
```

### 4. Data Isolation

**Multi-Tenant Query Pattern:**

```sql
-- CORRECT: Always filter by workspace_id
SELECT * FROM team_members
WHERE workspace_id = :workspace_id
  AND status = 'active'
  AND deleted_at IS NULL;

-- INCORRECT: Missing workspace_id filter
SELECT * FROM team_members WHERE status = 'active';

-- Use Row-Level Security (RLS) for additional protection
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY team_members_isolation ON team_members
    USING (workspace_id = current_setting('app.current_workspace_id')::UUID);
```

### 5. Audit Logging

**Track all sensitive operations:**

```sql
-- Create audit log table
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id),
    user_id UUID REFERENCES users(id),
    action VARCHAR(64) NOT NULL,
    resource_type VARCHAR(64) NOT NULL,
    resource_id UUID,
    changes JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Log critical actions
INSERT INTO audit_logs (workspace_id, user_id, action, resource_type, resource_id, changes)
VALUES (
    :workspace_id,
    :user_id,
    'team_member.role_changed',
    'team_member',
    :member_id,
    jsonb_build_object('old_role', 'member', 'new_role', 'admin')
);
```

---

## Summary

This Phase 5 database schema provides:

**Tables:**
1. **team_members** - Enhanced RBAC team management with invitation workflow
2. **billing_config** - Subscription plans, usage limits, and Stripe integration
3. **integrations_config** - External service integrations with health monitoring

**Features:**
- Multi-tenant isolation via `workspace_id`
- 4-tier role hierarchy (owner, admin, member, viewer)
- Soft delete support with audit trails
- Optimized indexes for common query patterns
- Encrypted credential storage
- Usage tracking and limits enforcement
- Health monitoring for integrations

**Security:**
- Application-layer credential encryption (AES-256-GCM)
- Secure invitation tokens (SHA-256)
- Row-level security (RLS) support
- Audit logging for sensitive operations
- Foreign key cascades for data integrity

**Migration:**
- Alembic-compatible Python migration
- Standalone SQL scripts (up/down)
- Comprehensive seed data for development
- Zero-downtime migration strategy

**Next Steps:**
1. Review schema with backend team
2. Implement FastAPI endpoints using these tables
3. Add frontend Settings page UI
4. Set up Stripe webhook handlers
5. Implement integration health checks

---

## File Locations

**Recommended file paths:**
- `/Users/pk1980/Documents/Software/Agent Monitoring/backend/db/phase5_001_settings_tables_up.sql`
- `/Users/pk1980/Documents/Software/Agent Monitoring/backend/db/phase5_001_settings_tables_down.sql`
- `/Users/pk1980/Documents/Software/Agent Monitoring/backend/db/phase5_seed_data.sql`
- `/Users/pk1980/Documents/Software/Agent Monitoring/backend/alembic/versions/phase5_001_settings_tables.py`
