/*
 * Phase 4 Synthetic Data Generation
 * File: seed-alerts.sql
 *
 * EXECUTION ORDER:
 * 1. First run: get-workspace-id.sql
 * 2. Capture the workspace_id from the output
 * 3. Run this script
 *
 * Usage:
 * psql -h localhost -p 5433 -U postgres -d agent_observability_metadata -f seed-alerts.sql
 *
 * OR via docker:
 * docker exec -i agent_obs_postgres psql -U postgres -d agent_observability_metadata -f /docker-entrypoint-initdb.d/seed-alerts.sql
 *
 * Generates:
 * - 4 alert rules (latency, error rate, cost, quality)
 * - 50 alert notifications (60% resolved, 30% acknowledged, 10% open)
 * Time range: Last 7 days
 */

-- Part A: Insert 4 alert rules
WITH workspace AS (
    SELECT id FROM workspaces WHERE slug = 'dev-workspace' LIMIT 1
)
INSERT INTO alert_rules (
    id,
    workspace_id,
    rule_name,
    metric,
    condition,
    threshold,
    window_minutes,
    severity,
    is_active,
    notification_channels,
    metadata
)
SELECT * FROM (VALUES
    (
        gen_random_uuid(),
        (SELECT id FROM workspace),
        'High Latency Alert',
        'latency_p99',
        'greater_than',
        2000.00,
        60,
        'high',
        true,
        '["webhook", "email"]'::jsonb,
        '{"description": "Triggers when P99 latency exceeds 2000ms over a 60-minute window", "cooldown_minutes": 30}'::jsonb
    ),
    (
        gen_random_uuid(),
        (SELECT id FROM workspace),
        'Error Rate Spike',
        'error_rate',
        'greater_than',
        5.00,
        30,
        'critical',
        true,
        '["webhook", "email", "slack"]'::jsonb,
        '{"description": "Triggers when error rate exceeds 5% over a 30-minute window", "cooldown_minutes": 15}'::jsonb
    ),
    (
        gen_random_uuid(),
        (SELECT id FROM workspace),
        'Cost Overrun',
        'hourly_cost',
        'greater_than',
        50.00,
        60,
        'high',
        true,
        '["webhook", "email"]'::jsonb,
        '{"description": "Triggers when hourly cost exceeds $50 over a 60-minute window", "cooldown_minutes": 60}'::jsonb
    ),
    (
        gen_random_uuid(),
        (SELECT id FROM workspace),
        'Quality Score Drop',
        'quality_score',
        'less_than',
        6.00,
        120,
        'medium',
        true,
        '["webhook"]'::jsonb,
        '{"description": "Triggers when average quality score drops below 6.0 over a 120-minute window", "cooldown_minutes": 120}'::jsonb
    )
) AS rules(id, workspace_id, rule_name, metric, condition, threshold, window_minutes, severity, is_active, notification_channels, metadata)
WHERE NOT EXISTS (
    SELECT 1 FROM alert_rules
    WHERE workspace_id = (SELECT id FROM workspace)
    AND rule_name = rules.rule_name
);

-- Part B: Generate 50 alert notifications (12-13 per rule)
WITH workspace AS (
    SELECT id FROM workspaces WHERE slug = 'dev-workspace' LIMIT 1
),
alert_rules_data AS (
    SELECT
        id as rule_id,
        rule_name,
        metric,
        threshold,
        severity
    FROM alert_rules
    WHERE workspace_id = (SELECT id FROM workspace)
),
notification_sequence AS (
    -- Generate 12-13 notifications per rule
    SELECT
        rule_id,
        rule_name,
        metric,
        threshold,
        severity,
        ROW_NUMBER() OVER (PARTITION BY rule_id ORDER BY RANDOM()) as seq_num
    FROM alert_rules_data
    CROSS JOIN generate_series(1, 13) gs(n)
    WHERE (rule_name = 'High Latency Alert' AND gs.n <= 13)
       OR (rule_name = 'Error Rate Spike' AND gs.n <= 12)
       OR (rule_name = 'Cost Overrun' AND gs.n <= 13)
       OR (rule_name = 'Quality Score Drop' AND gs.n <= 12)
),
status_assignment AS (
    -- Assign status: 60% resolved, 30% acknowledged, 10% open
    SELECT
        *,
        CASE
            WHEN (ROW_NUMBER() OVER (ORDER BY RANDOM())) <= 30 THEN 'resolved'
            WHEN (ROW_NUMBER() OVER (ORDER BY RANDOM())) <= 45 THEN 'acknowledged'
            ELSE 'open'
        END as status
    FROM notification_sequence
),
metric_values AS (
    SELECT
        *,
        CASE metric
            WHEN 'latency_p99' THEN ROUND(CAST(2100 + (RANDOM() * 900) AS numeric), 2)
            WHEN 'error_rate' THEN ROUND(CAST(5.5 + (RANDOM() * 4.5) AS numeric), 2)
            WHEN 'hourly_cost' THEN ROUND(CAST(55 + (RANDOM() * 25) AS numeric), 2)
            WHEN 'quality_score' THEN ROUND(CAST(4.0 + (RANDOM() * 1.9) AS numeric), 2)
        END as metric_value,
        NOW() - (RANDOM() * INTERVAL '7 days') as triggered_at
    FROM status_assignment
)
INSERT INTO alert_notifications (
    id,
    workspace_id,
    rule_id,
    triggered_at,
    metric_value,
    threshold_value,
    status,
    acknowledged_at,
    resolved_at,
    notification_sent,
    webhook_url,
    metadata
)
SELECT
    gen_random_uuid() as id,
    (SELECT id FROM workspace) as workspace_id,
    rule_id,
    triggered_at,
    metric_value,
    threshold as threshold_value,
    status,
    CASE
        WHEN status IN ('acknowledged', 'resolved')
        THEN triggered_at + (INTERVAL '15 minutes' * (1 + RANDOM() * 3))
        ELSE NULL
    END as acknowledged_at,
    CASE
        WHEN status = 'resolved'
        THEN triggered_at + (INTERVAL '30 minutes' * (1 + RANDOM() * 5))
        ELSE NULL
    END as resolved_at,
    CASE
        WHEN RANDOM() < 0.9 THEN true
        ELSE false
    END as notification_sent,
    'https://hooks.example.com/alerts/' || LOWER(REPLACE(rule_name, ' ', '-')) as webhook_url,
    jsonb_build_object(
        'alert_id', md5(random()::text || clock_timestamp()::text),
        'duration_minutes', CASE
            WHEN status = 'resolved'
            THEN ROUND(CAST(30 + (RANDOM() * 120) AS numeric), 0)
            ELSE NULL
        END,
        'affected_agents', CASE metric
            WHEN 'latency_p99' THEN jsonb_build_array('customer-support-agent', 'sales-assistant')
            WHEN 'error_rate' THEN jsonb_build_array('data-processor-agent')
            WHEN 'hourly_cost' THEN jsonb_build_array('customer-support-agent', 'sales-assistant', 'data-processor-agent')
            WHEN 'quality_score' THEN jsonb_build_array('customer-support-agent')
        END,
        'responder', CASE
            WHEN status IN ('acknowledged', 'resolved')
            THEN (ARRAY['alice@example.com', 'bob@example.com', 'charlie@example.com'])[floor(random() * 3 + 1)]
            ELSE NULL
        END
    ) as metadata
FROM metric_values
ORDER BY triggered_at DESC;

-- Verification queries
SELECT '=== Alert Data Generation Complete ===' as status;

SELECT COUNT(*) as total_alert_rules
FROM alert_rules
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace');

SELECT
    rule_name,
    metric,
    condition,
    threshold,
    severity,
    window_minutes,
    is_active
FROM alert_rules
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
ORDER BY
    CASE severity
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
    END;

SELECT COUNT(*) as total_alert_notifications
FROM alert_notifications
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace');

SELECT
    MIN(triggered_at) as earliest_alert,
    MAX(triggered_at) as latest_alert
FROM alert_notifications
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace');

SELECT
    ar.rule_name,
    ar.severity,
    COUNT(*) as notification_count,
    ROUND(AVG(an.metric_value), 2) as avg_metric_value,
    ar.threshold as threshold_value
FROM alert_notifications an
JOIN alert_rules ar ON an.rule_id = ar.id
WHERE an.workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
GROUP BY ar.rule_name, ar.severity, ar.threshold
ORDER BY notification_count DESC;

SELECT
    status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as percentage
FROM alert_notifications
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
GROUP BY status
ORDER BY
    CASE status
        WHEN 'open' THEN 1
        WHEN 'acknowledged' THEN 2
        WHEN 'resolved' THEN 3
    END;

SELECT
    notification_sent,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as percentage
FROM alert_notifications
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
GROUP BY notification_sent
ORDER BY notification_sent DESC;

SELECT
    ar.rule_name,
    an.status,
    COUNT(*) as count
FROM alert_notifications an
JOIN alert_rules ar ON an.rule_id = ar.id
WHERE an.workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
GROUP BY ar.rule_name, an.status
ORDER BY ar.rule_name, an.status;
