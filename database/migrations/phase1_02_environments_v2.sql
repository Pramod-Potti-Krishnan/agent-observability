-- Phase 1 Migration: Create Environments Reference Table
-- Purpose: Environment tracking (production, staging, development)
-- Date: October 27, 2025
-- Note: Simplified for MVP schema

-- Create environments table
CREATE TABLE IF NOT EXISTS environments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL,  -- No FK constraint since workspaces table doesn't exist yet
    environment_code VARCHAR(50) NOT NULL,
    environment_name VARCHAR(255) NOT NULL,
    description TEXT,
    is_production BOOLEAN DEFAULT FALSE,
    requires_approval BOOLEAN DEFAULT FALSE,

    -- Metadata
    metadata JSONB DEFAULT '{}',

    -- Standard timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Unique constraint: one environment code per workspace
    CONSTRAINT uniq_environments_workspace_code UNIQUE (workspace_id, environment_code)
);

-- Indexes
CREATE INDEX idx_environments_workspace ON environments(workspace_id);
CREATE INDEX idx_environments_code ON environments(environment_code);
CREATE INDEX idx_environments_production ON environments(is_production) WHERE is_production = TRUE;

-- Update trigger for updated_at
CREATE TRIGGER update_environments_updated_at
    BEFORE UPDATE ON environments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default environments using existing workspace_id from traces
INSERT INTO environments (workspace_id, environment_code, environment_name, description, is_production, requires_approval)
SELECT DISTINCT
    t.workspace_id,
    e.code,
    e.name,
    e.description,
    e.is_prod,
    e.requires_approval
FROM traces t
CROSS JOIN (VALUES
    ('production', 'Production', 'Live production environment serving end users', TRUE, TRUE),
    ('staging', 'Staging', 'Pre-production testing environment', FALSE, TRUE),
    ('development', 'Development', 'Development and testing environment', FALSE, FALSE)
) AS e(code, name, description, is_prod, requires_approval)
LIMIT 3
ON CONFLICT (workspace_id, environment_code) DO NOTHING;

-- Validation query
SELECT
    environment_code,
    environment_name,
    is_production,
    requires_approval
FROM environments
ORDER BY is_production DESC, environment_code;
