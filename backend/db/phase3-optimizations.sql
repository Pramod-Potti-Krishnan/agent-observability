-- Phase 3 Performance Optimizations
-- Add budgets table and performance indexes

-- ========================================
-- PostgreSQL Tables
-- ========================================

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


-- ========================================
-- TimescaleDB Performance Indexes
-- ========================================

-- Phase 3 Usage Analytics Indexes
CREATE INDEX IF NOT EXISTS idx_traces_workspace_agent ON traces (workspace_id, agent_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_traces_workspace_model ON traces (workspace_id, model, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_traces_workspace_status ON traces (workspace_id, status, timestamp DESC);

-- Additional user_id index for top users query (if user_id column exists)
-- CREATE INDEX IF NOT EXISTS idx_traces_workspace_user ON traces (workspace_id, user_id, timestamp DESC);

-- Composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_traces_workspace_timestamp_status 
ON traces (workspace_id, timestamp DESC, status) 
WHERE cost_usd IS NOT NULL;

-- Index for error analysis queries
CREATE INDEX IF NOT EXISTS idx_traces_error_analysis 
ON traces (workspace_id, agent_id, status, timestamp DESC) 
WHERE status = 'error';

-- Index for cost queries with non-null cost_usd
CREATE INDEX IF NOT EXISTS idx_traces_cost_analysis 
ON traces (workspace_id, model, timestamp DESC) 
WHERE cost_usd IS NOT NULL;

-- Performance monitoring specific indexes
CREATE INDEX IF NOT EXISTS idx_traces_latency_percentiles 
ON traces (workspace_id, timestamp DESC) 
INCLUDE (latency_ms, status);

-- Add user_id column to traces if it doesn't exist (for top users tracking)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'traces' AND column_name = 'user_id') THEN
        ALTER TABLE traces ADD COLUMN user_id VARCHAR(128);
        CREATE INDEX idx_traces_workspace_user ON traces (workspace_id, user_id, timestamp DESC);
    END IF;
END $$;

-- Optimize statistics for better query planning
ANALYZE traces;
ANALYZE budgets;

-- Log completion
SELECT 'Phase 3 optimizations completed successfully' AS message;
