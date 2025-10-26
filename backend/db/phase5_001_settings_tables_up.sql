-- =====================================================================
-- MIGRATION: Phase 5 Settings Tables (UPGRADE)
-- FILE: phase5_001_settings_tables_up.sql
-- DESCRIPTION: Add team_members, billing_config, integrations_config
-- DEPENDENCIES: Requires existing workspaces, users tables
-- AUTHOR: Database Designer Agent
-- DATE: 2025-10-25
-- =====================================================================

BEGIN;

\echo '========================================='
\echo 'Phase 5: Creating Settings Tables'
\echo '========================================='

-- ================================================================
-- 1. CREATE TABLE: team_members
-- ================================================================

\echo 'Creating table: team_members...'

CREATE TABLE IF NOT EXISTS team_members (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Multi-Tenant Isolation
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    -- User Reference
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Role-Based Access Control
    role VARCHAR(32) NOT NULL DEFAULT 'viewer',
    status VARCHAR(32) NOT NULL DEFAULT 'pending',

    -- Invitation Management
    invitation_email VARCHAR(256),
    invitation_token VARCHAR(128) UNIQUE,
    invitation_expires_at TIMESTAMPTZ,

    -- Audit Trail
    invited_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    accepted_at TIMESTAMPTZ,
    last_active_at TIMESTAMPTZ,

    -- Soft Delete
    deleted_at TIMESTAMPTZ,
    deleted_by UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Constraints
    CONSTRAINT team_members_role_check
        CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
    CONSTRAINT team_members_status_check
        CHECK (status IN ('pending', 'active', 'inactive')),
    CONSTRAINT team_members_unique_active_member
        UNIQUE NULLS NOT DISTINCT (workspace_id, user_id, deleted_at)
);

-- Add table comment
COMMENT ON TABLE team_members IS 'Enhanced workspace team management with RBAC and invitation workflow';
COMMENT ON COLUMN team_members.role IS 'Permission level: owner, admin, member, viewer';
COMMENT ON COLUMN team_members.status IS 'Membership status: pending, active, inactive';
COMMENT ON COLUMN team_members.invitation_token IS 'Secure token for invitation acceptance (SHA-256 hash)';
COMMENT ON COLUMN team_members.deleted_at IS 'Soft delete timestamp - NULL if active';

-- Create indexes
\echo 'Creating indexes for team_members...'

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

-- Add trigger
\echo 'Adding updated_at trigger for team_members...'

CREATE TRIGGER update_team_members_updated_at
BEFORE UPDATE ON team_members
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

\echo '✓ team_members table created successfully'

-- ================================================================
-- 2. CREATE TABLE: billing_config
-- ================================================================

\echo 'Creating table: billing_config...'

CREATE TABLE IF NOT EXISTS billing_config (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Multi-Tenant Isolation (One-to-One with workspace)
    workspace_id UUID NOT NULL UNIQUE REFERENCES workspaces(id) ON DELETE CASCADE,

    -- Subscription Plan
    plan_type VARCHAR(32) NOT NULL DEFAULT 'free',
    plan_status VARCHAR(32) NOT NULL DEFAULT 'active',

    -- Plan Limits (NULL = unlimited)
    traces_per_month_limit INTEGER,
    team_members_limit INTEGER,
    api_keys_limit INTEGER,
    data_retention_days INTEGER,
    custom_integrations_limit INTEGER,

    -- Current Usage (Reset monthly)
    traces_current_month INTEGER NOT NULL DEFAULT 0,
    team_members_current INTEGER NOT NULL DEFAULT 0,
    api_keys_current INTEGER NOT NULL DEFAULT 0,

    -- Usage Metadata
    usage_reset_at TIMESTAMPTZ,
    overage_allowed BOOLEAN DEFAULT FALSE,

    -- Billing Cycle
    billing_cycle_start DATE NOT NULL DEFAULT CURRENT_DATE,
    billing_cycle_end DATE,
    trial_ends_at TIMESTAMPTZ,

    -- Payment Integration
    stripe_customer_id VARCHAR(128) UNIQUE,
    stripe_subscription_id VARCHAR(128) UNIQUE,
    payment_method_last4 VARCHAR(4),
    payment_method_brand VARCHAR(32),

    -- Pricing
    monthly_price_usd DECIMAL(10, 2),
    annual_price_usd DECIMAL(10, 2),
    billing_interval VARCHAR(16) DEFAULT 'monthly',

    -- Status & Notifications
    next_billing_date DATE,
    auto_renew BOOLEAN DEFAULT TRUE,
    cancellation_requested BOOLEAN DEFAULT FALSE,
    cancellation_effective_date DATE,

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

-- Add table comment
COMMENT ON TABLE billing_config IS 'Subscription plans, usage limits, and billing configuration per workspace';
COMMENT ON COLUMN billing_config.plan_type IS 'Subscription tier: free, starter, professional, enterprise';
COMMENT ON COLUMN billing_config.stripe_customer_id IS 'Stripe customer ID for payment processing';
COMMENT ON COLUMN billing_config.traces_per_month_limit IS 'Monthly trace ingestion limit (NULL = unlimited)';
COMMENT ON COLUMN billing_config.usage_reset_at IS 'Last monthly usage counter reset timestamp';

-- Create indexes
\echo 'Creating indexes for billing_config...'

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

-- Add trigger
\echo 'Adding updated_at trigger for billing_config...'

CREATE TRIGGER update_billing_config_updated_at
BEFORE UPDATE ON billing_config
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

\echo '✓ billing_config table created successfully'

-- ================================================================
-- 3. CREATE TABLE: integrations_config
-- ================================================================

\echo 'Creating table: integrations_config...'

CREATE TABLE IF NOT EXISTS integrations_config (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Multi-Tenant Isolation
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    -- Integration Type
    integration_type VARCHAR(64) NOT NULL,
    integration_name VARCHAR(256) NOT NULL,

    -- Configuration (Type-Specific)
    config_data JSONB NOT NULL DEFAULT '{}',

    -- Encrypted Credentials
    credentials_encrypted TEXT,
    encryption_key_id VARCHAR(128),

    -- Status & Health
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    health_status VARCHAR(32) DEFAULT 'unknown',
    last_health_check_at TIMESTAMPTZ,
    health_check_message TEXT,

    -- Sync & Activity
    last_sync_at TIMESTAMPTZ,
    last_error_at TIMESTAMPTZ,
    last_error_message TEXT,
    total_events_sent INTEGER DEFAULT 0,
    total_errors INTEGER DEFAULT 0,

    -- Event Filtering
    event_filters JSONB DEFAULT '{}',

    -- Rate Limiting
    rate_limit_per_minute INTEGER,

    -- Retry Configuration
    retry_config JSONB DEFAULT '{"max_retries": 3, "backoff": "exponential"}',

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
    CONSTRAINT integrations_config_unique_type
        UNIQUE (workspace_id, integration_type, integration_name)
);

-- Add table comment
COMMENT ON TABLE integrations_config IS 'External service integrations (Slack, PagerDuty, webhooks, etc.)';
COMMENT ON COLUMN integrations_config.integration_type IS 'Integration type: slack, pagerduty, webhook, sentry, datadog, custom';
COMMENT ON COLUMN integrations_config.credentials_encrypted IS 'AES-256-GCM encrypted credentials (encrypt at application layer)';
COMMENT ON COLUMN integrations_config.config_data IS 'JSONB configuration specific to integration type';
COMMENT ON COLUMN integrations_config.event_filters IS 'Filter rules for which events to send';
COMMENT ON COLUMN integrations_config.last_sync_at IS 'Last successful event delivery timestamp';

-- Create indexes
\echo 'Creating indexes for integrations_config...'

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

-- Add trigger
\echo 'Adding updated_at trigger for integrations_config...'

CREATE TRIGGER update_integrations_config_updated_at
BEFORE UPDATE ON integrations_config
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

\echo '✓ integrations_config table created successfully'

-- ================================================================
-- VERIFICATION
-- ================================================================

\echo ''
\echo '========================================='
\echo 'Verification'
\echo '========================================='

SELECT 'team_members' AS table_name, COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'team_members'
UNION ALL
SELECT 'billing_config', COUNT(*)
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'billing_config'
UNION ALL
SELECT 'integrations_config', COUNT(*)
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'integrations_config';

\echo ''
\echo '✓ Phase 5 migration completed successfully'
\echo ''

COMMIT;
