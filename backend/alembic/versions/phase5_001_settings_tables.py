"""Phase 5: Add Settings Management Tables

Revision ID: phase5_001_settings
Revises: phase4_xxx
Create Date: 2025-10-25 16:00:00.000000

Description:
    Adds three new tables for Phase 5 Settings page functionality:
    - team_members: Enhanced team management with RBAC
    - billing_config: Subscription plans and usage limits
    - integrations_config: External service integrations

Dependencies:
    - Requires existing workspaces table
    - Requires existing users table
    - Requires update_updated_at_column() function

Author: Database Designer Agent
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# Revision identifiers, used by Alembic.
revision = 'phase5_001_settings'
down_revision = 'phase4_xxx'  # TODO: Update with actual previous revision
branch_labels = None
depends_on = None


def upgrade():
    """Apply Phase 5 schema changes."""

    print("=" * 60)
    print("Phase 5: Creating Settings Tables")
    print("=" * 60)

    # ================================================================
    # 1. CREATE TABLE: team_members
    # ================================================================
    print("Creating table: team_members...")

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
    print("Creating indexes for team_members...")
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

    print("✓ team_members table created successfully")

    # ================================================================
    # 2. CREATE TABLE: billing_config
    # ================================================================
    print("Creating table: billing_config...")

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
    print("Creating indexes for billing_config...")
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

    print("✓ billing_config table created successfully")

    # ================================================================
    # 3. CREATE TABLE: integrations_config
    # ================================================================
    print("Creating table: integrations_config...")

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
    print("Creating indexes for integrations_config...")
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

    print("✓ integrations_config table created successfully")

    print("\n" + "=" * 60)
    print("✓ Phase 5 migration completed successfully")
    print("=" * 60)


def downgrade():
    """Rollback Phase 5 schema changes."""

    print("=" * 60)
    print("Phase 5: Rolling Back Settings Tables")
    print("=" * 60)
    print("WARNING: This will delete all data in these tables!")

    # Drop tables in reverse order (respecting foreign key dependencies)
    print("Dropping table: integrations_config...")
    op.execute("DROP TABLE IF EXISTS integrations_config CASCADE;")
    print("✓ integrations_config table dropped")

    print("Dropping table: billing_config...")
    op.execute("DROP TABLE IF EXISTS billing_config CASCADE;")
    print("✓ billing_config table dropped")

    print("Dropping table: team_members...")
    op.execute("DROP TABLE IF EXISTS team_members CASCADE;")
    print("✓ team_members table dropped")

    print("\n" + "=" * 60)
    print("✓ Phase 5 rollback completed successfully")
    print("=" * 60)
