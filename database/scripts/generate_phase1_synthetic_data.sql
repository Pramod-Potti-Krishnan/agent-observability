-- Phase 1: Synthetic Data Generation (SQL-based for performance)
-- Generates 500K+ traces with realistic patterns
-- Execution time: ~30 seconds

\timing on

-- Store workspace_id in a variable
\set workspace_id `echo "SELECT workspace_id FROM traces LIMIT 1" | docker exec -i agent_obs_timescaledb psql -U postgres -d agent_observability -tA`

\echo '🚀 Starting Phase 1 Synthetic Data Generation'
\echo '======================================================================'
\echo ''

-- Step 1: Generate traces (500K records)
\echo '📊 Generating 500,000 traces over 90 days...'

INSERT INTO traces (
    trace_id,
    workspace_id,
    agent_id,
    department_id,
    environment_id,
    version,
    intent_category,
    user_segment,
    timestamp,
    latency_ms,
    status,
    model,
    model_provider,
    tokens_input,
    tokens_output,
    tokens_total,
    cost_usd,
    input,
    output,
    error
)
SELECT
    'tr_' || md5(random()::text || clock_timestamp()::text)::uuid::text,
    (SELECT workspace_id FROM traces LIMIT 1),
    -- Agent ID: distribute across departments
    dept.department_code || '-' || agent_template || '-' || ((gs % 10) + 1)::text,
    dept.id,
    -- Environment ID: 70% production, 20% staging, 10% development
    CASE
        WHEN random() < 0.70 THEN (SELECT id FROM environments WHERE environment_code = 'production' LIMIT 1)
        WHEN random() < 0.90 THEN (SELECT id FROM environments WHERE environment_code = 'staging' LIMIT 1)
        ELSE (SELECT id FROM environments WHERE environment_code = 'development' LIMIT 1)
    END,
    -- Version: 60% v2.1, 25% v2.0, 10% v1.9, 5% v1.8
    CASE
        WHEN random() < 0.60 THEN 'v2.1'
        WHEN random() < 0.85 THEN 'v2.0'
        WHEN random() < 0.95 THEN 'v1.9'
        ELSE 'v1.8'
    END,
    -- Intent category based on department
    CASE dept.department_code
        WHEN 'engineering' THEN (ARRAY['code_generation', 'research', 'automation'])[floor(random() * 3 + 1)]
        WHEN 'sales' THEN (ARRAY['content_creation', 'data_analysis', 'customer_support'])[floor(random() * 3 + 1)]
        WHEN 'support' THEN (ARRAY['customer_support', 'research', 'automation'])[floor(random() * 3 + 1)]
        WHEN 'marketing' THEN (ARRAY['content_creation', 'data_analysis', 'automation'])[floor(random() * 3 + 1)]
        WHEN 'finance' THEN (ARRAY['data_analysis', 'automation', 'research'])[floor(random() * 3 + 1)]
        WHEN 'hr' THEN (ARRAY['content_creation', 'automation', 'research'])[floor(random() * 3 + 1)]
        WHEN 'operations' THEN (ARRAY['automation', 'data_analysis', 'research'])[floor(random() * 3 + 1)]
        WHEN 'product' THEN (ARRAY['research', 'data_analysis', 'content_creation'])[floor(random() * 3 + 1)]
        WHEN 'data' THEN (ARRAY['data_analysis', 'code_generation', 'research'])[floor(random() * 3 + 1)]
        ELSE 'general_assistance'
    END,
    -- User segment: 40% regular, 30% power_user, 20% new, 10% struggling
    CASE
        WHEN random() < 0.40 THEN 'regular'
        WHEN random() < 0.70 THEN 'power_user'
        WHEN random() < 0.90 THEN 'new'
        ELSE 'struggling'
    END,
    -- Timestamp: spread over 90 days with business hours weighting
    NOW() - (random() * INTERVAL '90 days') +
    -- Add business hours bias (higher activity 9-5 weekdays)
    CASE
        WHEN EXTRACT(DOW FROM NOW() - (random() * INTERVAL '90 days')) IN (0, 6) THEN - INTERVAL '6 hours'  -- Weekend, shift to lower activity
        WHEN EXTRACT(HOUR FROM NOW() - (random() * INTERVAL '90 days')) BETWEEN 9 AND 17 THEN INTERVAL '0 hours'  -- Business hours
        ELSE - INTERVAL '3 hours'  -- Off hours
    END,
    -- Latency: realistic distribution (log-normal)
    (1000 + (random() * 3000 * (1 + random()))::int),
    -- Status: 95% success, 5% error
    CASE WHEN random() < 0.95 THEN 'success' ELSE 'error' END,
    -- Model: varies by environment
    CASE
        WHEN random() < 0.60 THEN 'gpt-4-turbo'
        WHEN random() < 0.85 THEN 'gpt-4'
        ELSE 'gpt-3.5-turbo'
    END,
    'openai',
    -- Tokens (realistic ranges)
    (300 + random() * 1500)::int,
    (500 + random() * 2000)::int,
    (800 + random() * 3500)::int,
    -- Cost (based on tokens)
    ((800 + random() * 3500) / 1000.0 * 0.01 * random())::numeric(10, 6),
    'Sample input text',
    CASE WHEN random() < 0.95 THEN 'Sample output text' ELSE NULL END,
    CASE WHEN random() < 0.95 THEN NULL ELSE 'Error processing request' END
FROM
    generate_series(1, 500000) gs,
    departments dept,
    (VALUES
        ('code-assistant'),
        ('support-agent'),
        ('analyst'),
        ('content-creator'),
        ('automation-bot'),
        ('research-helper'),
        ('advisor'),
        ('optimizer'),
        ('planner'),
        ('processor')
    ) AS templates(agent_template)
WHERE gs % 100 = (dept.id::text::int % 100)  -- Distribute evenly across departments
LIMIT 500000;

\echo '✅ 500,000 traces generated!'
\echo ''

-- Step 2: Refresh continuous aggregates
\echo '🔄 Refreshing continuous aggregates...'
CALL refresh_continuous_aggregate('traces_hourly', NULL, NULL);
CALL refresh_continuous_aggregate('traces_daily', NULL, NULL);
\echo '✅ Continuous aggregates refreshed'
\echo ''

-- Step 3: Display final statistics
\echo '📈 Final Statistics:'
\echo '======================================================================'

SELECT
    '✅ Total Traces' as metric,
    COUNT(*)::text as value
FROM traces
UNION ALL
SELECT
    '✅ Unique Agents' as metric,
    COUNT(DISTINCT agent_id)::text
FROM traces
UNION ALL
SELECT
    '✅ Departments' as metric,
    COUNT(DISTINCT department_id)::text
FROM traces
UNION ALL
SELECT
    '✅ Date Range' as metric,
    MIN(timestamp)::date::text || ' to ' || MAX(timestamp)::date::text
FROM traces
UNION ALL
SELECT
    '✅ Total Cost' as metric,
    '$' || ROUND(SUM(cost_usd), 2)::text
FROM traces
UNION ALL
SELECT
    '✅ Avg Latency' as metric,
    ROUND(AVG(latency_ms))::text || 'ms'
FROM traces
UNION ALL
SELECT
    '✅ Error Rate' as metric,
    ROUND(COUNT(*) FILTER (WHERE status = 'error')::numeric / COUNT(*) * 100, 2)::text || '%'
FROM traces;

\echo ''
\echo '✨ Phase 1 Synthetic Data Generation Complete!'
