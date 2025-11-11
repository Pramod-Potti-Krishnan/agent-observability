-- Backfill Script: Populate agent_id in evaluations table
-- Date: 2025-10-31
-- Purpose: Populate agent_id for existing evaluations from traces table
--
-- This script safely backfills the agent_id column by joining with traces
-- It can be run multiple times safely (idempotent)

-- Start transaction
BEGIN;

-- Show current state before backfill
SELECT 'BEFORE BACKFILL:' as status;
SELECT
    COUNT(*) as total_evaluations,
    COUNT(agent_id) as evaluations_with_agent_id,
    COUNT(*) - COUNT(agent_id) as missing_agent_id,
    ROUND((COUNT(agent_id)::DECIMAL / NULLIF(COUNT(*), 0)) * 100, 2) as fill_percentage
FROM evaluations;

-- Perform the backfill
-- Join evaluations with traces to get agent_id
UPDATE evaluations e
SET agent_id = t.agent_id
FROM traces t
WHERE e.trace_id = t.trace_id
  AND e.workspace_id = t.workspace_id
  AND e.agent_id IS NULL  -- Only update records without agent_id
  AND t.agent_id IS NOT NULL;  -- Only if trace has agent_id

-- Show results after backfill
SELECT 'AFTER BACKFILL:' as status;
SELECT
    COUNT(*) as total_evaluations,
    COUNT(agent_id) as evaluations_with_agent_id,
    COUNT(*) - COUNT(agent_id) as missing_agent_id,
    ROUND((COUNT(agent_id)::DECIMAL / NULLIF(COUNT(*), 0)) * 100, 2) as fill_percentage
FROM evaluations;

-- Show breakdown by agent
SELECT 'EVALUATIONS PER AGENT:' as status;
SELECT
    agent_id,
    COUNT(*) as evaluation_count,
    MIN(created_at) as first_evaluation,
    MAX(created_at) as last_evaluation
FROM evaluations
WHERE agent_id IS NOT NULL
GROUP BY agent_id
ORDER BY evaluation_count DESC
LIMIT 20;

-- Commit the transaction
COMMIT;

-- Success message
DO $$
DECLARE
    updated_count INT;
    total_count INT;
    fill_pct DECIMAL;
BEGIN
    SELECT COUNT(*) INTO total_count FROM evaluations;
    SELECT COUNT(agent_id) INTO updated_count FROM evaluations;
    fill_pct := ROUND((updated_count::DECIMAL / NULLIF(total_count, 0)) * 100, 2);

    RAISE NOTICE '============================================';
    RAISE NOTICE 'Backfill Complete!';
    RAISE NOTICE 'Total evaluations: %', total_count;
    RAISE NOTICE 'Evaluations with agent_id: % (%.2f%%)', updated_count, fill_pct;
    RAISE NOTICE '============================================';
END $$;
