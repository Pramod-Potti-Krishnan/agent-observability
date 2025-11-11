-- Phase 1 Migration: Rebuild Continuous Aggregates with New Dimensions
-- Purpose: Add department, environment, version dimensions to aggregates
-- Date: October 27, 2025

-- Drop existing continuous aggregates (they don't have new dimensions)
DROP MATERIALIZED VIEW IF EXISTS traces_hourly CASCADE;
DROP MATERIALIZED VIEW IF EXISTS traces_daily CASCADE;

-- Create NEW traces_hourly with all dimensions
CREATE MATERIALIZED VIEW traces_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', timestamp) AS hour,
    workspace_id,
    agent_id,
    department_id,
    environment_id,
    version,
    intent_category,
    user_segment,
    model,
    model_provider,

    -- Aggregated metrics
    COUNT(*) as request_count,
    AVG(latency_ms) as avg_latency_ms,
    percentile_cont(0.50) WITHIN GROUP (ORDER BY latency_ms) as p50_latency_ms,
    percentile_cont(0.90) WITHIN GROUP (ORDER BY latency_ms) as p90_latency_ms,
    percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms) as p95_latency_ms,
    percentile_cont(0.99) WITHIN GROUP (ORDER BY latency_ms) as p99_latency_ms,
    MAX(latency_ms) as max_latency_ms,
    SUM(tokens_input) as total_tokens_input,
    SUM(tokens_output) as total_tokens_output,
    SUM(tokens_total) as total_tokens_total,
    SUM(cost_usd) as total_cost_usd,
    COUNT(*) FILTER (WHERE status = 'success') as success_count,
    COUNT(*) FILTER (WHERE status = 'error') as error_count,
    COUNT(*) FILTER (WHERE status = 'timeout') as timeout_count

FROM traces
GROUP BY hour, workspace_id, agent_id, department_id, environment_id,
         version, intent_category, user_segment, model, model_provider
WITH NO DATA;

-- Add refresh policy (refresh every hour, covering last 3 hours)
SELECT add_continuous_aggregate_policy('traces_hourly',
    start_offset => INTERVAL '3 hours',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

-- Create NEW traces_daily with all dimensions
CREATE MATERIALIZED VIEW traces_daily
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', timestamp) AS day,
    workspace_id,
    agent_id,
    department_id,
    environment_id,
    version,
    intent_category,
    user_segment,
    model,
    model_provider,

    -- Aggregated metrics
    COUNT(*) as request_count,
    AVG(latency_ms) as avg_latency_ms,
    percentile_cont(0.50) WITHIN GROUP (ORDER BY latency_ms) as p50_latency_ms,
    percentile_cont(0.90) WITHIN GROUP (ORDER BY latency_ms) as p90_latency_ms,
    percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms) as p95_latency_ms,
    percentile_cont(0.99) WITHIN GROUP (ORDER BY latency_ms) as p99_latency_ms,
    MAX(latency_ms) as max_latency_ms,
    SUM(tokens_input) as total_tokens_input,
    SUM(tokens_output) as total_tokens_output,
    SUM(tokens_total) as total_tokens_total,
    SUM(cost_usd) as total_cost_usd,
    COUNT(*) FILTER (WHERE status = 'success') as success_count,
    COUNT(*) FILTER (WHERE status = 'error') as error_count,
    COUNT(*) FILTER (WHERE status = 'timeout') as timeout_count

FROM traces
GROUP BY day, workspace_id, agent_id, department_id, environment_id,
         version, intent_category, user_segment, model, model_provider
WITH NO DATA;

-- Add refresh policy (refresh daily, covering last 7 days)
SELECT add_continuous_aggregate_policy('traces_daily',
    start_offset => INTERVAL '7 days',
    end_offset => INTERVAL '1 day',
    schedule_interval => INTERVAL '1 day');

-- Manually refresh to populate with existing data
CALL refresh_continuous_aggregate('traces_hourly', NULL, NULL);
CALL refresh_continuous_aggregate('traces_daily', NULL, NULL);

-- Validation queries
SELECT
    'traces_hourly' as view_name,
    COUNT(*) as row_count,
    MIN(hour) as earliest_hour,
    MAX(hour) as latest_hour
FROM traces_hourly
UNION ALL
SELECT
    'traces_daily' as view_name,
    COUNT(*) as row_count,
    MIN(day) as earliest_day,
    MAX(day) as latest_day
FROM traces_daily;

-- Sample query to verify new dimensions
SELECT
    d.department_name,
    e.environment_code,
    th.version,
    SUM(th.request_count) as total_requests,
    AVG(th.avg_latency_ms) as avg_latency
FROM traces_hourly th
JOIN departments d ON th.department_id = d.id
JOIN environments e ON th.environment_id = e.id
GROUP BY d.department_name, e.environment_code, th.version
ORDER BY total_requests DESC
LIMIT 10;
