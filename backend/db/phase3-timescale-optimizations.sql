-- Phase 3 TimescaleDB Performance Optimizations
-- Add performance indexes for Phase 3 queries

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

-- Log completion
SELECT 'Phase 3 TimescaleDB optimizations completed successfully' AS message;
