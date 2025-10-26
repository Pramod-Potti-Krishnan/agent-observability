-- =====================================================================
-- SEED DATA: Phase 5 Settings (Development Environment)
-- FILE: phase5_seed_data.sql
-- DESCRIPTION: Sample data for testing Settings functionality
-- DEPENDENCIES: Requires phase5_001_settings_tables_up.sql
-- AUTHOR: Database Designer Agent
-- DATE: 2025-10-25
-- =====================================================================

BEGIN;

\echo '========================================='
\echo 'Phase 5: Seeding Test Data'
\echo '========================================='

-- Assumes existing workspace and users from init-postgres.sql
-- workspace_id: '00000000-0000-0000-0000-000000000001'
-- user_id:      '00000000-0000-0000-0000-000000000001' (demo@example.com)

-- ================================================================
-- 1. SEED: team_members
-- ================================================================

\echo 'Seeding team_members...'

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

\echo '✓ team_members seeded (6 records)'

-- ================================================================
-- 2. SEED: billing_config
-- ================================================================

\echo 'Seeding billing_config...'

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

\echo '✓ billing_config seeded (1 record)'

-- ================================================================
-- 3. SEED: integrations_config
-- ================================================================

\echo 'Seeding integrations_config...'

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

\echo '✓ integrations_config seeded (4 records)'

-- ================================================================
-- VERIFICATION
-- ================================================================

\echo ''
\echo '========================================='
\echo 'Seed Data Summary'
\echo '========================================='

-- Team members breakdown
\echo 'Team Members by Role & Status:'
SELECT
    role,
    status,
    COUNT(*) as count
FROM team_members
WHERE workspace_id = '00000000-0000-0000-0000-000000000001'
GROUP BY role, status
ORDER BY role, status;

-- Billing usage
\echo ''
\echo 'Billing Configuration:'
SELECT
    plan_type,
    traces_current_month,
    traces_per_month_limit,
    ROUND((traces_current_month::NUMERIC / traces_per_month_limit * 100), 2) as usage_percent
FROM billing_config
WHERE workspace_id = '00000000-0000-0000-0000-000000000001';

-- Integrations
\echo ''
\echo 'Integrations Status:'
SELECT
    integration_type,
    integration_name,
    is_enabled,
    health_status
FROM integrations_config
WHERE workspace_id = '00000000-0000-0000-0000-000000000001'
ORDER BY integration_type;

\echo ''
\echo '✓ Phase 5 seed data loaded successfully'
\echo ''

COMMIT;
