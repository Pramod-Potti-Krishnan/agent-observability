-- Migration: Add agent_id column to evaluations table
-- Date: 2025-10-31
-- Purpose: Fix agent quality queries by adding agent_id as a direct column
--
-- This migration:
-- 1. Adds agent_id column to evaluations table
-- 2. Backfills agent_id from traces table for existing evaluations
-- 3. Creates index on agent_id for performance
-- 4. Updates metadata to remove redundant agent_id storage

-- Step 1: Add agent_id column (nullable initially for safe migration)
ALTER TABLE evaluations
ADD COLUMN IF NOT EXISTS agent_id VARCHAR(255);

-- Step 2: Backfill agent_id from traces for existing evaluations
-- This joins evaluations with traces to get the agent_id
UPDATE evaluations e
SET agent_id = t.agent_id
FROM traces t
WHERE e.trace_id = t.trace_id
  AND e.workspace_id = t.workspace_id
  AND e.agent_id IS NULL;

-- Step 3: Create index on agent_id for query performance
CREATE INDEX IF NOT EXISTS idx_evaluations_agent_id
ON evaluations(agent_id);

-- Step 4: Create composite index for common query patterns
-- (workspace_id, agent_id) is frequently used together
CREATE INDEX IF NOT EXISTS idx_evaluations_workspace_agent
ON evaluations(workspace_id, agent_id);

-- Step 5: Create index for time-based agent queries
CREATE INDEX IF NOT EXISTS idx_evaluations_agent_created
ON evaluations(agent_id, created_at DESC);

-- Step 6: Add helpful comment
COMMENT ON COLUMN evaluations.agent_id IS 'Agent ID from the corresponding trace, denormalized for query performance';

-- Verification query (to be run manually after migration)
-- SELECT
--   COUNT(*) as total_evaluations,
--   COUNT(agent_id) as evaluations_with_agent_id,
--   COUNT(*) - COUNT(agent_id) as missing_agent_id
-- FROM evaluations;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Migration complete: agent_id added to evaluations table';
    RAISE NOTICE 'Please verify the backfill by checking that agent_id is populated for all evaluations';
END $$;
