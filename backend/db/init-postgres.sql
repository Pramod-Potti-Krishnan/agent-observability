-- PostgreSQL Initialization Script
-- This script sets up relational database for metadata, users, workspaces, etc.

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create workspaces table
CREATE TABLE IF NOT EXISTS workspaces (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(256) NOT NULL,
    slug VARCHAR(128) UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Settings
    settings JSONB DEFAULT '{}',

    -- Billing
    plan VARCHAR(32) DEFAULT 'free', -- 'free', 'pro', 'enterprise'
    monthly_budget_usd DECIMAL(10, 2) DEFAULT 100.00,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_workspaces_slug ON workspaces (slug);
CREATE INDEX IF NOT EXISTS idx_workspaces_active ON workspaces (is_active) WHERE is_active = TRUE;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(256) UNIQUE NOT NULL,
    password_hash VARCHAR(256) NOT NULL,
    full_name VARCHAR(256),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_login_at TIMESTAMPTZ,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);

-- Create workspace_members table (many-to-many)
CREATE TABLE IF NOT EXISTS workspace_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(32) NOT NULL DEFAULT 'member', -- 'owner', 'admin', 'member', 'viewer'
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(workspace_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_workspace_members_workspace ON workspace_members (workspace_id);
CREATE INDEX IF NOT EXISTS idx_workspace_members_user ON workspace_members (user_id);

-- Create agents table
CREATE TABLE IF NOT EXISTS agents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    agent_id VARCHAR(128) NOT NULL, -- User-defined agent identifier
    name VARCHAR(256) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Configuration
    default_model VARCHAR(64),
    default_model_provider VARCHAR(32),
    config JSONB DEFAULT '{}',

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    UNIQUE(workspace_id, agent_id)
);

CREATE INDEX IF NOT EXISTS idx_agents_workspace ON agents (workspace_id);
CREATE INDEX IF NOT EXISTS idx_agents_active ON agents (workspace_id, is_active) WHERE is_active = TRUE;

-- Create API keys table
CREATE TABLE IF NOT EXISTS api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    key_hash VARCHAR(256) NOT NULL UNIQUE, -- Hashed version of the API key
    key_prefix VARCHAR(16) NOT NULL, -- First few characters for display (e.g., "pk_live_abc...")
    name VARCHAR(256),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,

    -- Permissions
    permissions JSONB DEFAULT '{"read": true, "write": true}',

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    revoked_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_api_keys_workspace ON api_keys (workspace_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_hash ON api_keys (key_hash);
CREATE INDEX IF NOT EXISTS idx_api_keys_active ON api_keys (is_active) WHERE is_active = TRUE;

-- Create evaluations table (for quality scoring)
CREATE TABLE IF NOT EXISTS evaluations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    trace_id VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Evaluation criteria
    evaluator VARCHAR(64) NOT NULL, -- 'gemini', 'human', 'custom_model'

    -- Scores (1-10 scale)
    accuracy_score DECIMAL(3, 1),
    relevance_score DECIMAL(3, 1),
    helpfulness_score DECIMAL(3, 1),
    coherence_score DECIMAL(3, 1),
    overall_score DECIMAL(3, 1),

    -- Reasoning
    reasoning TEXT,

    -- Metadata
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_evaluations_workspace ON evaluations (workspace_id);
CREATE INDEX IF NOT EXISTS idx_evaluations_trace ON evaluations (trace_id);
CREATE INDEX IF NOT EXISTS idx_evaluations_created ON evaluations (created_at DESC);

-- Create guardrail_rules table
CREATE TABLE IF NOT EXISTS guardrail_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    agent_id VARCHAR(128), -- NULL means applies to all agents
    rule_type VARCHAR(64) NOT NULL, -- 'pii_detection', 'toxicity', 'prompt_injection', 'custom'
    name VARCHAR(256) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Configuration
    config JSONB NOT NULL DEFAULT '{}',
    severity VARCHAR(16) DEFAULT 'warning', -- 'info', 'warning', 'error', 'critical'

    -- Actions
    action VARCHAR(32) DEFAULT 'log', -- 'log', 'block', 'redact'

    -- Status
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_guardrail_rules_workspace ON guardrail_rules (workspace_id);
CREATE INDEX IF NOT EXISTS idx_guardrail_rules_active ON guardrail_rules (workspace_id, is_active) WHERE is_active = TRUE;

-- Create guardrail_violations table
CREATE TABLE IF NOT EXISTS guardrail_violations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    rule_id UUID NOT NULL REFERENCES guardrail_rules(id) ON DELETE CASCADE,
    trace_id VARCHAR(64) NOT NULL,
    detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Violation details
    violation_type VARCHAR(64) NOT NULL,
    severity VARCHAR(16) NOT NULL,
    message TEXT,

    -- What was detected
    detected_content TEXT,
    redacted_content TEXT,

    -- Metadata
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_violations_workspace ON guardrail_violations (workspace_id);
CREATE INDEX IF NOT EXISTS idx_violations_rule ON guardrail_violations (rule_id);
CREATE INDEX IF NOT EXISTS idx_violations_trace ON guardrail_violations (trace_id);
CREATE INDEX IF NOT EXISTS idx_violations_detected ON guardrail_violations (detected_at DESC);

-- Create alert_rules table
CREATE TABLE IF NOT EXISTS alert_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    agent_id VARCHAR(128), -- NULL means applies to all agents
    name VARCHAR(256) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Alert condition
    metric VARCHAR(64) NOT NULL, -- 'latency_ms', 'error_rate', 'cost_usd', 'request_count'
    condition VARCHAR(16) NOT NULL, -- 'gt', 'lt', 'eq', 'gte', 'lte'
    threshold DECIMAL(10, 2) NOT NULL,
    window_minutes INTEGER DEFAULT 5, -- Time window for evaluation

    -- Notification channels
    channels JSONB DEFAULT '[]', -- ['email', 'webhook', 'slack']
    webhook_url VARCHAR(512),

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    last_triggered_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_alert_rules_workspace ON alert_rules (workspace_id);
CREATE INDEX IF NOT EXISTS idx_alert_rules_active ON alert_rules (workspace_id, is_active) WHERE is_active = TRUE;

-- Create alert_notifications table (log of sent alerts)
CREATE TABLE IF NOT EXISTS alert_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_rule_id UUID NOT NULL REFERENCES alert_rules(id) ON DELETE CASCADE,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Alert details
    title VARCHAR(256) NOT NULL,
    message TEXT,
    severity VARCHAR(16) NOT NULL,

    -- Metric details
    metric_value DECIMAL(10, 2),

    -- Delivery status
    channels_sent JSONB, -- Which channels were used
    delivery_status JSONB -- Status per channel
);

CREATE INDEX IF NOT EXISTS idx_alert_notifications_rule ON alert_notifications (alert_rule_id);
CREATE INDEX IF NOT EXISTS idx_alert_notifications_workspace ON alert_notifications (workspace_id);
CREATE INDEX IF NOT EXISTS idx_alert_notifications_sent ON alert_notifications (sent_at DESC);

-- Create business_goals table (for Impact page)
CREATE TABLE IF NOT EXISTS business_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name VARCHAR(256) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Goal details
    metric VARCHAR(64) NOT NULL, -- 'support_tickets', 'csat_score', 'cost_savings', 'response_time'
    target_value DECIMAL(10, 2) NOT NULL,
    current_value DECIMAL(10, 2) DEFAULT 0,
    unit VARCHAR(32), -- 'tickets', '%', '$', 'ms'

    -- Timeline
    target_date DATE,

    -- Status
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_business_goals_workspace ON business_goals (workspace_id);
CREATE INDEX IF NOT EXISTS idx_business_goals_active ON business_goals (workspace_id, is_active) WHERE is_active = TRUE;

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at
CREATE TRIGGER update_workspaces_updated_at BEFORE UPDATE ON workspaces FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_agents_updated_at BEFORE UPDATE ON agents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_guardrail_rules_updated_at BEFORE UPDATE ON guardrail_rules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_alert_rules_updated_at BEFORE UPDATE ON alert_rules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_business_goals_updated_at BEFORE UPDATE ON business_goals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert seed data for development
INSERT INTO workspaces (id, name, slug, plan) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Development Workspace', 'dev-workspace', 'pro')
ON CONFLICT DO NOTHING;

INSERT INTO users (id, email, password_hash, full_name, is_verified) VALUES
    ('00000000-0000-0000-0000-000000000001', 'demo@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU.W1PGEtBFS', 'Demo User', TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO workspace_members (workspace_id, user_id, role) VALUES
    ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'owner')
ON CONFLICT DO NOTHING;

INSERT INTO agents (workspace_id, agent_id, name, description, default_model) VALUES
    ('00000000-0000-0000-0000-000000000001', 'customer_support', 'Customer Support Agent', 'Handles customer inquiries and support tickets', 'gpt-4'),
    ('00000000-0000-0000-0000-000000000001', 'sales_agent', 'Sales Agent', 'Assists with sales inquiries and lead qualification', 'gpt-3.5-turbo'),
    ('00000000-0000-0000-0000-000000000001', 'content_writer', 'Content Writer Agent', 'Generates marketing and blog content', 'claude-3-opus')
ON CONFLICT DO NOTHING;
