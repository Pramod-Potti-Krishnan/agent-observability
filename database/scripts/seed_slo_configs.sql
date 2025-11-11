-- Seed SLO Configurations for Sample Agents
-- Date: 2025-10-31
-- Purpose: Populate slo_configs table with realistic SLO targets for top agents
--
-- This will enable the SLO Compliance Tracker on the Performance page

-- First, identify the top agents by request volume
SELECT 'TOP AGENTS BY REQUEST VOLUME:' as status;
SELECT
    agent_id,
    COUNT(*) as request_count,
    ROUND(AVG(latency_ms)) as avg_latency_ms,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY latency_ms)) as p50_ms,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY latency_ms)) as p95_ms,
    ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY latency_ms)) as p99_ms,
    ROUND(COUNT(*) FILTER (WHERE status = 'error')::DECIMAL / COUNT(*) * 100, 2) as error_rate_pct
FROM traces
GROUP BY agent_id
ORDER BY request_count DESC
LIMIT 15;

-- Get workspace_id (assuming single workspace for dev)
DO $$
DECLARE
    workspace_uuid UUID;
    agent_record RECORD;
    agents_cursor CURSOR FOR
        SELECT
            agent_id,
            ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY latency_ms)) as p50_ms,
            ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY latency_ms)) as p90_ms,
            ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY latency_ms)) as p95_ms,
            ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY latency_ms)) as p99_ms,
            ROUND(COUNT(*) FILTER (WHERE status = 'error')::DECIMAL / COUNT(*) * 100, 2) as error_rate_pct
        FROM traces
        GROUP BY agent_id
        ORDER BY COUNT(*) DESC
        LIMIT 15;
BEGIN
    -- Get the workspace_id from traces
    SELECT DISTINCT workspace_id INTO workspace_uuid FROM traces LIMIT 1;

    RAISE NOTICE 'Creating SLO configs for workspace: %', workspace_uuid;
    RAISE NOTICE '-------------------------------------------';

    -- Loop through top agents and create SLO configs
    FOR agent_record IN agents_cursor LOOP
        -- Set SLO targets at 120% of actual metrics (allowing some buffer)
        INSERT INTO slo_configs (
            workspace_id,
            agent_id,
            p50_latency_target_ms,
            p90_latency_target_ms,
            p95_latency_target_ms,
            p99_latency_target_ms,
            error_rate_target_pct,
            availability_target_pct,
            error_budget_minutes,
            is_active,
            alert_on_violation,
            created_by
        ) VALUES (
            workspace_uuid,
            agent_record.agent_id,
            CAST(agent_record.p50_ms * 1.2 AS INTEGER),  -- 20% buffer
            CAST(agent_record.p90_ms * 1.2 AS INTEGER),
            CAST(agent_record.p95_ms * 1.2 AS INTEGER),
            CAST(agent_record.p99_ms * 1.2 AS INTEGER),
            GREATEST(agent_record.error_rate_pct * 1.5, 1.0),  -- 50% buffer, min 1%
            99.9,  -- 99.9% availability target
            43,    -- ~1 hour error budget per month (30 days * 24 hours * 60 min * 0.1% / 100)
            true,
            true,
            'system_seed'
        )
        ON CONFLICT (workspace_id, agent_id) DO UPDATE SET
            p50_latency_target_ms = EXCLUDED.p50_latency_target_ms,
            p90_latency_target_ms = EXCLUDED.p90_latency_target_ms,
            p95_latency_target_ms = EXCLUDED.p95_latency_target_ms,
            p99_latency_target_ms = EXCLUDED.p99_latency_target_ms,
            error_rate_target_pct = EXCLUDED.error_rate_target_pct,
            updated_at = NOW();

        RAISE NOTICE 'Created SLO for agent: % (P50: %ms, P95: %ms, P99: %ms, Error: %%)',
            agent_record.agent_id,
            CAST(agent_record.p50_ms * 1.2 AS INTEGER),
            CAST(agent_record.p95_ms * 1.2 AS INTEGER),
            CAST(agent_record.p99_ms * 1.2 AS INTEGER),
            GREATEST(agent_record.error_rate_pct * 1.5, 1.0);
    END LOOP;

    RAISE NOTICE '-------------------------------------------';
    RAISE NOTICE '✓ SLO configurations created successfully!';
END $$;

-- Verify the created SLO configs
SELECT 'CREATED SLO CONFIGURATIONS:' as status;
SELECT
    agent_id,
    p50_latency_target_ms,
    p90_latency_target_ms,
    p95_latency_target_ms,
    p99_latency_target_ms,
    error_rate_target_pct,
    is_active,
    created_at
FROM slo_configs
ORDER BY created_at DESC
LIMIT 15;

-- Show compliance summary
SELECT 'SLO COMPLIANCE SUMMARY:' as status;
SELECT
    s.agent_id,
    s.p50_latency_target_ms as slo_p50,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY t.latency_ms)) as actual_p50,
    CASE
        WHEN ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY t.latency_ms)) <= s.p50_latency_target_ms
        THEN '✓ Compliant'
        ELSE '✗ Violation'
    END as p50_status,
    s.error_rate_target_pct as slo_error_rate,
    ROUND(COUNT(*) FILTER (WHERE t.status = 'error')::DECIMAL / COUNT(*) * 100, 2) as actual_error_rate,
    CASE
        WHEN ROUND(COUNT(*) FILTER (WHERE t.status = 'error')::DECIMAL / COUNT(*) * 100, 2) <= s.error_rate_target_pct
        THEN '✓ Compliant'
        ELSE '✗ Violation'
    END as error_rate_status
FROM slo_configs s
JOIN traces t ON t.agent_id = s.agent_id AND t.workspace_id = s.workspace_id
WHERE s.is_active = true
GROUP BY s.agent_id, s.p50_latency_target_ms, s.error_rate_target_pct
ORDER BY s.agent_id
LIMIT 10;

SELECT '✓ SLO seed data completed successfully!' as result;
