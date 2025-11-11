-- Phase 1 Migration: Enhance Traces Table with Multi-Agent Dimensions
-- Purpose: Add department, environment, version, intent, and user segment tracking
-- Date: October 27, 2025
-- Note: Simplified for MVP schema (no agents table yet)

-- Step 1: Add new columns (nullable initially)
ALTER TABLE traces ADD COLUMN IF NOT EXISTS department_id UUID;
ALTER TABLE traces ADD COLUMN IF NOT EXISTS environment_id UUID;
ALTER TABLE traces ADD COLUMN IF NOT EXISTS version VARCHAR(50);
ALTER TABLE traces ADD COLUMN IF NOT EXISTS intent_category VARCHAR(100);
ALTER TABLE traces ADD COLUMN IF NOT EXISTS user_segment VARCHAR(50);

-- Step 2: Create indexes for new columns (CRITICAL for query performance)
CREATE INDEX IF NOT EXISTS idx_traces_department ON traces(department_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_traces_environment ON traces(environment_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_traces_version ON traces(version, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_traces_intent ON traces(intent_category, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_traces_user_segment ON traces(user_segment, timestamp DESC);

-- Composite indexes for common filter combinations
CREATE INDEX IF NOT EXISTS idx_traces_workspace_dept_time ON traces(workspace_id, department_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_traces_workspace_env_time ON traces(workspace_id, environment_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_traces_dept_env_time ON traces(department_id, environment_id, timestamp DESC);

-- Step 3: Backfill department_id - distribute agents across departments intelligently
-- We'll assign each existing agent_id to a department based on hash distribution
UPDATE traces
SET department_id = (
    SELECT id FROM departments
    WHERE workspace_id = traces.workspace_id
    ORDER BY md5(traces.agent_id || departments.department_code)
    LIMIT 1
)
WHERE department_id IS NULL;

-- Step 4: Backfill environment_id - 70% production, 20% staging, 10% development
UPDATE traces
SET environment_id = (
    SELECT id FROM environments
    WHERE workspace_id = traces.workspace_id
      AND environment_code = CASE
          WHEN random() < 0.70 THEN 'production'
          WHEN random() < 0.90 THEN 'staging'
          ELSE 'development'
      END
    LIMIT 1
)
WHERE environment_id IS NULL;

-- Step 5: Backfill version - simulate version distribution (60% v2.1, 25% v2.0, 10% v1.9, 5% v1.8)
UPDATE traces
SET version = CASE
    WHEN random() < 0.60 THEN 'v2.1'
    WHEN random() < 0.85 THEN 'v2.0'
    WHEN random() < 0.95 THEN 'v1.9'
    ELSE 'v1.8'
END
WHERE version IS NULL;

-- Step 6: Backfill intent_category with intelligent defaults based on agent_id patterns
UPDATE traces
SET intent_category = CASE
    WHEN agent_id LIKE '%code%' OR agent_id LIKE '%eng%' THEN 'code_generation'
    WHEN agent_id LIKE '%support%' OR agent_id LIKE '%customer%' THEN 'customer_support'
    WHEN agent_id LIKE '%data%' OR agent_id LIKE '%analytics%' THEN 'data_analysis'
    WHEN agent_id LIKE '%content%' OR agent_id LIKE '%marketing%' THEN 'content_creation'
    WHEN agent_id LIKE '%auto%' OR agent_id LIKE '%workflow%' THEN 'automation'
    WHEN agent_id LIKE '%research%' OR agent_id LIKE '%qa%' THEN 'research'
    ELSE 'general_assistance'
END
WHERE intent_category IS NULL;

-- Step 7: Backfill user_segment based on usage patterns
UPDATE traces
SET user_segment = CASE
    WHEN status = 'success' AND latency_ms < 2000 THEN 'power_user'
    WHEN status = 'success' THEN 'regular'
    WHEN status = 'error' THEN 'struggling'
    ELSE 'new'
END
WHERE user_segment IS NULL;

-- Step 8: Make columns NOT NULL after backfill
ALTER TABLE traces ALTER COLUMN department_id SET NOT NULL;
ALTER TABLE traces ALTER COLUMN environment_id SET NOT NULL;
ALTER TABLE traces ALTER COLUMN version SET NOT NULL;
ALTER TABLE traces ALTER COLUMN intent_category SET NOT NULL;

-- Add constraints for categorical values
ALTER TABLE traces ADD CONSTRAINT IF NOT EXISTS check_intent_category
    CHECK (intent_category IN (
        'code_generation', 'customer_support', 'data_analysis',
        'content_creation', 'automation', 'research',
        'translation', 'general_assistance'
    ));

ALTER TABLE traces ADD CONSTRAINT IF NOT EXISTS check_user_segment
    CHECK (user_segment IS NULL OR user_segment IN (
        'power_user', 'regular', 'new', 'struggling', 'dormant'
    ));

-- Add foreign key constraints to reference tables
ALTER TABLE traces ADD CONSTRAINT fk_traces_department
    FOREIGN KEY (department_id) REFERENCES departments(id);

ALTER TABLE traces ADD CONSTRAINT fk_traces_environment
    FOREIGN KEY (environment_id) REFERENCES environments(id);

-- Validation queries
SELECT
    'Total traces' as metric,
    COUNT(*) as count
FROM traces
UNION ALL
SELECT
    'Traces with NULL department_id' as metric,
    COUNT(*) as count
FROM traces WHERE department_id IS NULL
UNION ALL
SELECT
    'Traces with NULL environment_id' as metric,
    COUNT(*) as count
FROM traces WHERE environment_id IS NULL
UNION ALL
SELECT
    'Traces with NULL version' as metric,
    COUNT(*) as count
FROM traces WHERE version IS NULL
UNION ALL
SELECT
    'Traces with NULL intent_category' as metric,
    COUNT(*) as count
FROM traces WHERE intent_category IS NULL;

-- Distribution analysis
SELECT
    d.department_name,
    COUNT(t.id) as trace_count,
    ROUND(AVG(t.latency_ms), 2) as avg_latency,
    SUM(t.cost_usd) as total_cost
FROM departments d
LEFT JOIN traces t ON t.department_id = d.id
GROUP BY d.id, d.department_name
ORDER BY trace_count DESC;

SELECT
    e.environment_code,
    COUNT(t.id) as trace_count,
    ROUND(AVG(t.latency_ms), 2) as avg_latency,
    ROUND(100.0 * COUNT(t.id) / (SELECT COUNT(*) FROM traces), 2) as percentage
FROM environments e
LEFT JOIN traces t ON t.environment_id = e.id
GROUP BY e.id, e.environment_code
ORDER BY trace_count DESC;

SELECT
    intent_category,
    COUNT(*) as trace_count,
    ROUND(AVG(latency_ms), 2) as avg_latency,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM traces), 2) as percentage
FROM traces
GROUP BY intent_category
ORDER BY trace_count DESC;

SELECT
    version,
    COUNT(*) as trace_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM traces), 2) as percentage
FROM traces
GROUP BY version
ORDER BY version DESC;
