/*
 * Phase 4 Synthetic Data Generation
 * File: seed-business-goals.sql
 *
 * EXECUTION ORDER:
 * 1. First run: get-workspace-id.sql
 * 2. Capture the workspace_id from the output
 * 3. Run this script
 *
 * Usage:
 * psql -h localhost -p 5433 -U postgres -d agent_observability_metadata -f seed-business-goals.sql
 *
 * OR via docker:
 * docker exec -i agent_obs_postgres psql -U postgres -d agent_observability_metadata -f /docker-entrypoint-initdb.d/seed-business-goals.sql
 *
 * Generates: 10 business goals with various progress levels (64-97%)
 * All goals set to 'in_progress' status
 */

-- Create business_goals table if it doesn't exist
CREATE TABLE IF NOT EXISTS business_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL,
    goal_type VARCHAR(64) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    baseline DECIMAL(10, 2) NOT NULL,
    target DECIMAL(10, 2) NOT NULL,
    current_value DECIMAL(10, 2) NOT NULL,
    unit VARCHAR(32) NOT NULL,
    progress_percentage DECIMAL(5, 2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    target_date DATE,
    status VARCHAR(32) DEFAULT 'in_progress',
    CONSTRAINT fk_workspace FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE
);

-- Create index on workspace_id for faster queries
CREATE INDEX IF NOT EXISTS idx_business_goals_workspace_id ON business_goals(workspace_id);
CREATE INDEX IF NOT EXISTS idx_business_goals_status ON business_goals(status);
CREATE INDEX IF NOT EXISTS idx_business_goals_goal_type ON business_goals(goal_type);

-- Insert 10 business goals
WITH workspace AS (
    SELECT id FROM workspaces WHERE slug = 'dev-workspace' LIMIT 1
)
INSERT INTO business_goals (
    id,
    workspace_id,
    goal_type,
    name,
    description,
    baseline,
    target,
    current_value,
    unit,
    progress_percentage,
    created_at,
    updated_at,
    target_date,
    status
)
SELECT * FROM (VALUES
    (
        gen_random_uuid(),
        (SELECT id FROM workspace),
        'support_tickets',
        'Reduce Support Ticket Volume',
        'Reduce monthly support ticket volume by automating common customer inquiries through AI agents. Target represents a 60% reduction from baseline.',
        1000.00,
        400.00,
        550.00,
        'tickets/month',
        -- For "lower is better" metrics: ((baseline - current) / (baseline - target)) * 100
        ROUND(CAST(((1000.00 - 550.00) / (1000.00 - 400.00)) * 100 AS numeric), 2),
        NOW() - INTERVAL '28 days',
        NOW(),
        CURRENT_DATE + INTERVAL '62 days',
        'in_progress'
    ),
    (
        gen_random_uuid(),
        (SELECT id FROM workspace),
        'csat_score',
        'Improve Customer Satisfaction Score',
        'Increase CSAT score through improved response quality and faster resolution times enabled by AI agent assistance.',
        3.20,
        4.50,
        4.10,
        'score (1-5)',
        -- For "higher is better" metrics: ((current - baseline) / (target - baseline)) * 100
        ROUND(CAST(((4.10 - 3.20) / (4.50 - 3.20)) * 100 AS numeric), 2),
        NOW() - INTERVAL '25 days',
        NOW(),
        CURRENT_DATE + INTERVAL '65 days',
        'in_progress'
    ),
    (
        gen_random_uuid(),
        (SELECT id FROM workspace),
        'cost_savings',
        'Achieve Quarterly Cost Savings',
        'Generate $50,000 in quarterly cost savings through reduced support staffing needs and improved operational efficiency.',
        0.00,
        50000.00,
        38000.00,
        'USD',
        ROUND(CAST(((38000.00 - 0.00) / (50000.00 - 0.00)) * 100 AS numeric), 2),
        NOW() - INTERVAL '30 days',
        NOW(),
        CURRENT_DATE + INTERVAL '60 days',
        'in_progress'
    ),
    (
        gen_random_uuid(),
        (SELECT id FROM workspace),
        'response_time',
        'Reduce Average Response Time',
        'Decrease average customer response time from 45 seconds to under 10 seconds using AI-powered instant responses.',
        45.00,
        10.00,
        15.00,
        'seconds',
        -- For "lower is better": ((baseline - current) / (baseline - target)) * 100
        ROUND(CAST(((45.00 - 15.00) / (45.00 - 10.00)) * 100 AS numeric), 2),
        NOW() - INTERVAL '22 days',
        NOW(),
        CURRENT_DATE + INTERVAL '68 days',
        'in_progress'
    ),
    (
        gen_random_uuid(),
        (SELECT id FROM workspace),
        'accuracy',
        'Improve Response Accuracy',
        'Increase response accuracy from 75% to 95% through enhanced AI models and better training data.',
        75.00,
        95.00,
        91.00,
        'percentage',
        ROUND(CAST(((91.00 - 75.00) / (95.00 - 75.00)) * 100 AS numeric), 2),
        NOW() - INTERVAL '27 days',
        NOW(),
        CURRENT_DATE + INTERVAL '63 days',
        'in_progress'
    ),
    (
        gen_random_uuid(),
        (SELECT id FROM workspace),
        'automation_rate',
        'Increase Query Automation Rate',
        'Increase the percentage of customer queries fully automated without human intervention from 30% to 85%.',
        30.00,
        85.00,
        72.00,
        'percentage',
        ROUND(CAST(((72.00 - 30.00) / (85.00 - 30.00)) * 100 AS numeric), 2),
        NOW() - INTERVAL '24 days',
        NOW(),
        CURRENT_DATE + INTERVAL '66 days',
        'in_progress'
    ),
    (
        gen_random_uuid(),
        (SELECT id FROM workspace),
        'error_rate',
        'Reduce Agent Error Rate',
        'Reduce agent error rate from 8.5% to below 2% through improved guardrails and quality monitoring.',
        8.50,
        2.00,
        3.20,
        'percentage',
        -- For "lower is better": ((baseline - current) / (baseline - target)) * 100
        ROUND(CAST(((8.50 - 3.20) / (8.50 - 2.00)) * 100 AS numeric), 2),
        NOW() - INTERVAL '26 days',
        NOW(),
        CURRENT_DATE + INTERVAL '64 days',
        'in_progress'
    ),
    (
        gen_random_uuid(),
        (SELECT id FROM workspace),
        'fcr',
        'Improve First Contact Resolution',
        'Increase First Contact Resolution rate from 55% to 85% by enabling agents with comprehensive knowledge and tools.',
        55.00,
        85.00,
        78.00,
        'percentage',
        ROUND(CAST(((78.00 - 55.00) / (85.00 - 55.00)) * 100 AS numeric), 2),
        NOW() - INTERVAL '29 days',
        NOW(),
        CURRENT_DATE + INTERVAL '61 days',
        'in_progress'
    ),
    (
        gen_random_uuid(),
        (SELECT id FROM workspace),
        'average_handle_time',
        'Reduce Average Handle Time',
        'Reduce average handle time from 180 seconds to 90 seconds through AI-assisted responses and automated workflows.',
        180.00,
        90.00,
        110.00,
        'seconds',
        -- For "lower is better": ((baseline - current) / (baseline - target)) * 100
        ROUND(CAST(((180.00 - 110.00) / (180.00 - 90.00)) * 100 AS numeric), 2),
        NOW() - INTERVAL '23 days',
        NOW(),
        CURRENT_DATE + INTERVAL '67 days',
        'in_progress'
    ),
    (
        gen_random_uuid(),
        (SELECT id FROM workspace),
        'user_satisfaction',
        'Improve Overall User Satisfaction',
        'Increase user satisfaction score from 7.2 to 9.0 (out of 10) through enhanced service quality and faster resolutions.',
        7.20,
        9.00,
        8.60,
        'score (1-10)',
        ROUND(CAST(((8.60 - 7.20) / (9.00 - 7.20)) * 100 AS numeric), 2),
        NOW() - INTERVAL '21 days',
        NOW(),
        CURRENT_DATE + INTERVAL '69 days',
        'in_progress'
    )
) AS goals(id, workspace_id, goal_type, name, description, baseline, target, current_value, unit, progress_percentage, created_at, updated_at, target_date, status)
WHERE NOT EXISTS (
    SELECT 1 FROM business_goals
    WHERE workspace_id = (SELECT id FROM workspace)
    AND goal_type = goals.goal_type
);

-- Verification queries
SELECT '=== Business Goals Data Generation Complete ===' as status;

SELECT COUNT(*) as total_business_goals
FROM business_goals
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace');

SELECT
    goal_type,
    name,
    baseline,
    current_value,
    target,
    unit,
    progress_percentage,
    status
FROM business_goals
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
ORDER BY progress_percentage DESC;

SELECT
    CASE
        WHEN progress_percentage >= 90 THEN 'Excellent (90-100%)'
        WHEN progress_percentage >= 75 THEN 'On Track (75-89%)'
        WHEN progress_percentage >= 50 THEN 'Progressing (50-74%)'
        ELSE 'Needs Attention (<50%)'
    END as progress_category,
    COUNT(*) as goal_count,
    ROUND(AVG(progress_percentage), 2) as avg_progress
FROM business_goals
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
GROUP BY progress_category
ORDER BY MIN(progress_percentage) DESC;

SELECT
    status,
    COUNT(*) as count
FROM business_goals
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
GROUP BY status;

SELECT
    ROUND(AVG(progress_percentage), 2) as overall_avg_progress,
    MIN(progress_percentage) as min_progress,
    MAX(progress_percentage) as max_progress,
    COUNT(*) as total_goals
FROM business_goals
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace');

-- Display goals with "lower is better" vs "higher is better" classification
SELECT
    goal_type,
    name,
    CASE
        WHEN goal_type IN ('support_tickets', 'response_time', 'error_rate', 'average_handle_time')
        THEN 'Lower is Better'
        ELSE 'Higher is Better'
    END as optimization_direction,
    baseline,
    current_value,
    target,
    progress_percentage || '%' as progress
FROM business_goals
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
ORDER BY
    CASE
        WHEN goal_type IN ('support_tickets', 'response_time', 'error_rate', 'average_handle_time')
        THEN 1
        ELSE 2
    END,
    goal_type;
