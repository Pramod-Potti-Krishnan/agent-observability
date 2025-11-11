-- Phase 1 Migration: Enhance Agents Table with Multi-Agent Context
-- Purpose: Add department, environment, version, and lifecycle tracking
-- Date: October 27, 2025

-- Step 1: Add new columns (nullable initially)
ALTER TABLE agents ADD COLUMN IF NOT EXISTS department_id UUID REFERENCES departments(id);
ALTER TABLE agents ADD COLUMN IF NOT EXISTS environment_id UUID REFERENCES environments(id);
ALTER TABLE agents ADD COLUMN IF NOT EXISTS version VARCHAR(50);
ALTER TABLE agents ADD COLUMN IF NOT EXISTS agent_status VARCHAR(20) DEFAULT 'active';
ALTER TABLE agents ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE agents ADD COLUMN IF NOT EXISTS config JSONB DEFAULT '{}';

-- Step 2: Create indexes for new columns
CREATE INDEX IF NOT EXISTS idx_agents_department ON agents(department_id);
CREATE INDEX IF NOT EXISTS idx_agents_environment ON agents(environment_id);
CREATE INDEX IF NOT EXISTS idx_agents_version ON agents(version);
CREATE INDEX IF NOT EXISTS idx_agents_status ON agents(agent_status);
CREATE INDEX IF NOT EXISTS idx_agents_workspace_dept ON agents(workspace_id, department_id);
CREATE INDEX IF NOT EXISTS idx_agents_config_gin ON agents USING GIN (config);

-- Step 3: Backfill department_id with default "engineering" for existing agents
UPDATE agents
SET department_id = (SELECT id FROM departments WHERE department_code = 'engineering' LIMIT 1)
WHERE department_id IS NULL;

-- Step 4: Backfill environment_id with default "production" for existing agents
UPDATE agents
SET environment_id = (SELECT id FROM environments WHERE environment_code = 'production' LIMIT 1)
WHERE environment_id IS NULL;

-- Step 5: Backfill version with default "v2.0" for existing agents
UPDATE agents
SET version = 'v2.0'
WHERE version IS NULL;

-- Step 6: Make columns NOT NULL after backfill
ALTER TABLE agents ALTER COLUMN department_id SET NOT NULL;
ALTER TABLE agents ALTER COLUMN environment_id SET NOT NULL;
ALTER TABLE agents ALTER COLUMN version SET NOT NULL;
ALTER TABLE agents ALTER COLUMN agent_status SET NOT NULL;

-- Add constraint for agent_status values
ALTER TABLE agents ADD CONSTRAINT check_agent_status
    CHECK (agent_status IN ('active', 'beta', 'deprecated', 'retired'));

-- Validation queries
SELECT
    'Total agents' as metric,
    COUNT(*) as count
FROM agents
UNION ALL
SELECT
    'Agents with NULL department_id' as metric,
    COUNT(*) as count
FROM agents WHERE department_id IS NULL
UNION ALL
SELECT
    'Agents with NULL environment_id' as metric,
    COUNT(*) as count
FROM agents WHERE environment_id IS NULL
UNION ALL
SELECT
    'Agents with NULL version' as metric,
    COUNT(*) as count
FROM agents WHERE version IS NULL;

-- Distribution by department
SELECT
    d.department_name,
    COUNT(a.id) as agent_count
FROM departments d
LEFT JOIN agents a ON a.department_id = d.id
GROUP BY d.department_name
ORDER BY agent_count DESC;
