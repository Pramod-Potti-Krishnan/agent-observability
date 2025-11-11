-- Cost Management Migration: Continuous Aggregates for Fast Queries
-- Purpose: Create TimescaleDB continuous aggregates for hourly and daily cost rollups
-- Date: October 27, 2025

-- Drop existing aggregates if they exist (for safe re-runs)
DROP MATERIALIZED VIEW IF EXISTS cost_aggregates_hourly CASCADE;
DROP MATERIALIZED VIEW IF NOT EXISTS cost_aggregates_daily CASCADE;

-- Hourly Cost Aggregates (for recent data, fast queries)
CREATE MATERIALIZED VIEW cost_aggregates_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', timestamp) AS hour_bucket,
    workspace_id,
    department_id,
    agent_id,
    model,
    model_provider,
    environment_id,
    version,

    -- Cost metrics
    COALESCE(SUM(cost_usd), 0) AS total_cost_usd,
    COALESCE(SUM(prompt_tokens * 0.00001), 0) AS prompt_token_cost_usd, -- Estimated
    COALESCE(SUM(completion_tokens * 0.00003), 0) AS completion_token_cost_usd, -- Estimated

    -- Volume metrics
    COUNT(*) AS request_count,
    COUNT(*) FILTER (WHERE status = 'success') AS success_count,
    COUNT(*) FILTER (WHERE status = 'error' OR status = 'timeout') AS error_count,
    COALESCE(SUM(prompt_tokens), 0) AS total_prompt_tokens,
    COALESCE(SUM(completion_tokens), 0) AS total_completion_tokens,
    COALESCE(SUM(total_tokens), 0) AS total_tokens,

    -- Efficiency metrics
    ROUND(AVG(cost_usd)::numeric, 6) AS avg_cost_per_request_usd,
    ROUND((COALESCE(SUM(cost_usd), 0) / NULLIF(COALESCE(SUM(total_tokens), 0), 0) * 1000)::numeric, 6) AS cost_per_1k_tokens_usd,

    -- Performance metrics (for cost-performance analysis)
    ROUND(percentile_cont(0.50) WITHIN GROUP (ORDER BY latency_ms)::numeric, 2) AS p50_latency_ms,
    ROUND(percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms)::numeric, 2) AS p95_latency_ms,
    ROUND(AVG(latency_ms)::numeric, 2) AS avg_latency_ms

FROM traces
WHERE cost_usd IS NOT NULL
GROUP BY hour_bucket, workspace_id, department_id, agent_id, model, model_provider, environment_id, version
WITH NO DATA;

-- Add continuous aggregate policy (refresh every hour for last 7 days)
SELECT add_continuous_aggregate_policy('cost_aggregates_hourly',
    start_offset => INTERVAL '7 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

-- Create indexes on the materialized view
CREATE INDEX IF NOT EXISTS idx_cost_hourly_workspace_time ON cost_aggregates_hourly(workspace_id, hour_bucket DESC);
CREATE INDEX IF NOT EXISTS idx_cost_hourly_dept_time ON cost_aggregates_hourly(department_id, hour_bucket DESC);
CREATE INDEX IF NOT EXISTS idx_cost_hourly_agent_time ON cost_aggregates_hourly(agent_id, hour_bucket DESC);
CREATE INDEX IF NOT EXISTS idx_cost_hourly_provider_time ON cost_aggregates_hourly(model_provider, hour_bucket DESC);
CREATE INDEX IF NOT EXISTS idx_cost_hourly_model_time ON cost_aggregates_hourly(model, hour_bucket DESC);

-- Daily Cost Aggregates (for historical data, dashboards)
CREATE MATERIALIZED VIEW cost_aggregates_daily
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', timestamp) AS day_bucket,
    workspace_id,
    department_id,
    agent_id,
    model,
    model_provider,
    environment_id,
    version,

    -- Cost metrics
    COALESCE(SUM(cost_usd), 0) AS total_cost_usd,
    COALESCE(SUM(prompt_tokens * 0.00001), 0) AS prompt_token_cost_usd,
    COALESCE(SUM(completion_tokens * 0.00003), 0) AS completion_token_cost_usd,

    -- Volume metrics
    COUNT(*) AS request_count,
    COUNT(*) FILTER (WHERE status = 'success') AS success_count,
    COUNT(*) FILTER (WHERE status = 'error' OR status = 'timeout') AS error_count,
    COALESCE(SUM(prompt_tokens), 0) AS total_prompt_tokens,
    COALESCE(SUM(completion_tokens), 0) AS total_completion_tokens,
    COALESCE(SUM(total_tokens), 0) AS total_tokens,

    -- Efficiency metrics
    ROUND(AVG(cost_usd)::numeric, 6) AS avg_cost_per_request_usd,
    ROUND((COALESCE(SUM(cost_usd), 0) / NULLIF(COALESCE(SUM(total_tokens), 0), 0) * 1000)::numeric, 6) AS cost_per_1k_tokens_usd,

    -- Performance metrics
    ROUND(percentile_cont(0.50) WITHIN GROUP (ORDER BY latency_ms)::numeric, 2) AS p50_latency_ms,
    ROUND(percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms)::numeric, 2) AS p95_latency_ms,
    ROUND(AVG(latency_ms)::numeric, 2) AS avg_latency_ms

FROM traces
WHERE cost_usd IS NOT NULL
GROUP BY day_bucket, workspace_id, department_id, agent_id, model, model_provider, environment_id, version
WITH NO DATA;

-- Add continuous aggregate policy (refresh daily for last 90 days)
SELECT add_continuous_aggregate_policy('cost_aggregates_daily',
    start_offset => INTERVAL '90 days',
    end_offset => INTERVAL '1 day',
    schedule_interval => INTERVAL '1 day');

-- Create indexes on daily aggregates
CREATE INDEX IF NOT EXISTS idx_cost_daily_workspace_time ON cost_aggregates_daily(workspace_id, day_bucket DESC);
CREATE INDEX IF NOT EXISTS idx_cost_daily_dept_time ON cost_aggregates_daily(department_id, day_bucket DESC);
CREATE INDEX IF NOT EXISTS idx_cost_daily_agent_time ON cost_aggregates_daily(agent_id, day_bucket DESC);
CREATE INDEX IF NOT EXISTS idx_cost_daily_provider_time ON cost_aggregates_daily(model_provider, day_bucket DESC);
CREATE INDEX IF NOT EXISTS idx_cost_daily_model_time ON cost_aggregates_daily(model, day_bucket DESC);

-- Add comments for documentation
COMMENT ON MATERIALIZED VIEW cost_aggregates_hourly IS 'Hourly cost aggregations by workspace, department, agent, model, provider for fast dashboard queries';
COMMENT ON MATERIALIZED VIEW cost_aggregates_daily IS 'Daily cost aggregations for historical analysis and trending';
