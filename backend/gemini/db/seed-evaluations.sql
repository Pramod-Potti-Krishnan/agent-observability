/*
 * Phase 4 Synthetic Data Generation
 * File: seed-evaluations.sql
 *
 * EXECUTION ORDER:
 * 1. First run: get-workspace-id.sql
 * 2. Capture the workspace_id from the output
 * 3. Run this script
 *
 * Usage:
 * psql -h localhost -p 5433 -U postgres -d agent_observability_metadata -f seed-evaluations.sql
 *
 * OR via docker:
 * docker exec -i agent_obs_postgres psql -U postgres -d agent_observability_metadata -f /docker-entrypoint-initdb.d/seed-evaluations.sql
 *
 * Generates: 1000 evaluation records linked to existing traces
 * Score range: 6.0 - 10.0 (biased toward good quality)
 * Time range: Last 7 days
 */

-- Insert 1000 evaluation records
WITH workspace AS (
    SELECT id FROM workspaces WHERE slug = 'dev-workspace' LIMIT 1
),
existing_traces AS (
    SELECT trace_id, ROW_NUMBER() OVER (ORDER BY start_time DESC) as rn
    FROM traces
    WHERE workspace_id = (SELECT id FROM workspace)
    LIMIT 1000
),
reasoning_templates AS (
    SELECT unnest(ARRAY[
        'Excellent response with high accuracy and relevance. The agent provided comprehensive information and addressed all user concerns effectively.',
        'Good quality output with minor improvements needed. The response was accurate but could be more concise.',
        'Strong performance across all criteria. The agent demonstrated excellent understanding of the context and provided actionable insights.',
        'Very good response quality. The information was accurate and well-structured, though some details could be enhanced.',
        'Outstanding coherence and helpfulness. The agent maintained context throughout the conversation and provided clear explanations.',
        'High-quality response with excellent relevance. The agent addressed the user query directly and provided valuable additional context.',
        'Solid performance with good accuracy. The response was helpful and coherent, meeting all expected quality standards.',
        'Excellent helpfulness and coherence. The agent provided detailed answers and followed up appropriately.',
        'Strong accuracy and relevance scores. The response was well-aligned with user intent and provided comprehensive information.',
        'Very good overall quality. The agent demonstrated strong understanding and provided accurate, relevant information.'
    ]) as reasoning_text,
    ROW_NUMBER() OVER () as template_id
),
generated_evaluations AS (
    SELECT
        gen_random_uuid() as id,
        (SELECT id FROM workspace) as workspace_id,
        et.trace_id,
        NOW() - (RANDOM() * INTERVAL '7 days') as created_at,
        'gemini' as evaluator,
        ROUND(CAST(6.0 + (RANDOM() * 4.0) AS numeric), 1) as accuracy_score,
        ROUND(CAST(6.0 + (RANDOM() * 4.0) AS numeric), 1) as relevance_score,
        ROUND(CAST(6.0 + (RANDOM() * 4.0) AS numeric), 1) as helpfulness_score,
        ROUND(CAST(6.0 + (RANDOM() * 4.0) AS numeric), 1) as coherence_score,
        rt.reasoning_text,
        et.rn
    FROM existing_traces et
    CROSS JOIN LATERAL (
        SELECT reasoning_text
        FROM reasoning_templates
        WHERE template_id = (et.rn % 10) + 1
        LIMIT 1
    ) rt
)
INSERT INTO evaluations (
    id,
    workspace_id,
    trace_id,
    created_at,
    evaluator,
    accuracy_score,
    relevance_score,
    helpfulness_score,
    coherence_score,
    overall_score,
    reasoning,
    metadata
)
SELECT
    id,
    workspace_id,
    trace_id,
    created_at,
    evaluator,
    accuracy_score,
    relevance_score,
    helpfulness_score,
    coherence_score,
    ROUND(CAST((accuracy_score + relevance_score + helpfulness_score + coherence_score) / 4.0 AS numeric), 1) as overall_score,
    reasoning_text,
    '{}'::jsonb as metadata
FROM generated_evaluations
ORDER BY created_at DESC;

-- Verification queries
SELECT '=== Evaluation Data Generation Complete ===' as status;
SELECT COUNT(*) as total_evaluations
FROM evaluations
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace');

SELECT
    MIN(created_at) as earliest_evaluation,
    MAX(created_at) as latest_evaluation
FROM evaluations
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace');

SELECT
    evaluator,
    COUNT(*) as count,
    ROUND(AVG(overall_score), 2) as avg_overall_score,
    ROUND(AVG(accuracy_score), 2) as avg_accuracy,
    ROUND(AVG(relevance_score), 2) as avg_relevance,
    ROUND(AVG(helpfulness_score), 2) as avg_helpfulness,
    ROUND(AVG(coherence_score), 2) as avg_coherence
FROM evaluations
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
GROUP BY evaluator;

SELECT
    CASE
        WHEN overall_score >= 9.0 THEN 'Excellent (9.0-10.0)'
        WHEN overall_score >= 8.0 THEN 'Very Good (8.0-8.9)'
        WHEN overall_score >= 7.0 THEN 'Good (7.0-7.9)'
        ELSE 'Acceptable (6.0-6.9)'
    END as quality_tier,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as percentage
FROM evaluations
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
GROUP BY quality_tier
ORDER BY MIN(overall_score) DESC;
