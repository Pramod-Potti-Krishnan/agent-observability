-- Phase 3 PostgreSQL Optimizations
-- Add budgets table for cost management

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create budgets table for cost management
CREATE TABLE IF NOT EXISTS budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL UNIQUE REFERENCES workspaces(id) ON DELETE CASCADE,
    monthly_limit_usd DECIMAL(10, 2),
    alert_threshold_percentage DECIMAL(5, 2) DEFAULT 80.0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_budgets_workspace ON budgets (workspace_id);

-- Add trigger for updated_at
CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON budgets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default budget for development workspace
INSERT INTO budgets (workspace_id, monthly_limit_usd, alert_threshold_percentage) VALUES
    ('00000000-0000-0000-0000-000000000001', 1000.00, 80.0)
ON CONFLICT (workspace_id) DO NOTHING;

-- Optimize statistics
ANALYZE budgets;

-- Log completion
SELECT 'Phase 3 PostgreSQL optimizations completed successfully' AS message;
