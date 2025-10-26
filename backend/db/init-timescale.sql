-- TimescaleDB Initialization Script
-- This script sets up the time-series database for agent observability metrics

-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Create traces table (main time-series table)
CREATE TABLE IF NOT EXISTS traces (
    id BIGSERIAL,
    trace_id VARCHAR(64) NOT NULL,
    workspace_id UUID NOT NULL,
    agent_id VARCHAR(128) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    latency_ms INTEGER NOT NULL,
    input TEXT,
    output TEXT,
    error TEXT,
    status VARCHAR(20) DEFAULT 'success', -- 'success', 'error', 'timeout'

    -- Model information
    model VARCHAR(64),
    model_provider VARCHAR(32), -- 'openai', 'anthropic', 'google', 'cohere'

    -- Token and cost tracking
    tokens_input INTEGER,
    tokens_output INTEGER,
    tokens_total INTEGER,
    cost_usd DECIMAL(10, 6),

    -- Metadata
    metadata JSONB,
    tags VARCHAR(64)[],

    PRIMARY KEY (timestamp, trace_id)
);

-- Convert to hypertable (partitioned by time)
SELECT create_hypertable('traces', 'timestamp',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_traces_workspace_timestamp ON traces (workspace_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_traces_agent_timestamp ON traces (agent_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_traces_status ON traces (status) WHERE status != 'success';
CREATE INDEX IF NOT EXISTS idx_traces_model ON traces (model);
CREATE INDEX IF NOT EXISTS idx_traces_tags ON traces USING GIN(tags);

-- Create unique index on trace_id and timestamp (required for TimescaleDB)
CREATE UNIQUE INDEX IF NOT EXISTS idx_traces_trace_id_timestamp ON traces (trace_id, timestamp);

-- Add retention policy (automatically drop chunks older than 30 days)
SELECT add_retention_policy('traces', INTERVAL '30 days', if_not_exists => TRUE);

-- Create continuous aggregate for hourly metrics
CREATE MATERIALIZED VIEW IF NOT EXISTS traces_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', timestamp) AS hour,
    workspace_id,
    agent_id,
    model,
    COUNT(*) AS request_count,
    AVG(latency_ms) AS avg_latency_ms,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY latency_ms) AS p50_latency_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY latency_ms) AS p95_latency_ms,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY latency_ms) AS p99_latency_ms,
    MAX(latency_ms) AS max_latency_ms,
    SUM(tokens_input) AS total_tokens_input,
    SUM(tokens_output) AS total_tokens_output,
    SUM(cost_usd) AS total_cost_usd,
    COUNT(*) FILTER (WHERE status = 'success') AS success_count,
    COUNT(*) FILTER (WHERE status = 'error') AS error_count,
    COUNT(*) FILTER (WHERE status = 'timeout') AS timeout_count
FROM traces
GROUP BY hour, workspace_id, agent_id, model;

-- Add refresh policy for continuous aggregate (refresh every hour)
SELECT add_continuous_aggregate_policy('traces_hourly',
    start_offset => INTERVAL '3 hours',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour',
    if_not_exists => TRUE
);

-- Create continuous aggregate for daily metrics
CREATE MATERIALIZED VIEW IF NOT EXISTS traces_daily
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', timestamp) AS day,
    workspace_id,
    agent_id,
    model,
    COUNT(*) AS request_count,
    AVG(latency_ms) AS avg_latency_ms,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY latency_ms) AS p50_latency_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY latency_ms) AS p95_latency_ms,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY latency_ms) AS p99_latency_ms,
    SUM(tokens_input) AS total_tokens_input,
    SUM(tokens_output) AS total_tokens_output,
    SUM(cost_usd) AS total_cost_usd,
    COUNT(*) FILTER (WHERE status = 'success') AS success_count,
    COUNT(*) FILTER (WHERE status = 'error') AS error_count
FROM traces
GROUP BY day, workspace_id, agent_id, model;

-- Add refresh policy for daily aggregate
SELECT add_continuous_aggregate_policy('traces_daily',
    start_offset => INTERVAL '7 days',
    end_offset => INTERVAL '1 day',
    schedule_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- Create table for performance metrics (separate from traces)
CREATE TABLE IF NOT EXISTS performance_metrics (
    timestamp TIMESTAMPTZ NOT NULL,
    workspace_id UUID NOT NULL,
    agent_id VARCHAR(128) NOT NULL,
    metric_name VARCHAR(64) NOT NULL, -- 'latency', 'throughput', 'error_rate'
    value DOUBLE PRECISION NOT NULL,
    unit VARCHAR(32), -- 'ms', 'requests/s', '%'
    metadata JSONB,
    PRIMARY KEY (timestamp, workspace_id, agent_id, metric_name)
);

SELECT create_hypertable('performance_metrics', 'timestamp',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

CREATE INDEX IF NOT EXISTS idx_perf_workspace_timestamp ON performance_metrics (workspace_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_perf_agent_metric ON performance_metrics (agent_id, metric_name, timestamp DESC);

-- Add retention policy
SELECT add_retention_policy('performance_metrics', INTERVAL '90 days', if_not_exists => TRUE);

-- Create table for events (alerts, anomalies, etc.)
CREATE TABLE IF NOT EXISTS events (
    id BIGSERIAL,
    event_id VARCHAR(64) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    workspace_id UUID NOT NULL,
    agent_id VARCHAR(128),
    event_type VARCHAR(32) NOT NULL, -- 'alert', 'anomaly', 'threshold_breach', 'guardrail_violation'
    severity VARCHAR(16) NOT NULL, -- 'info', 'warning', 'error', 'critical'
    title VARCHAR(256) NOT NULL,
    description TEXT,
    metadata JSONB,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by VARCHAR(128),
    PRIMARY KEY (timestamp, event_id)
);

SELECT create_hypertable('events', 'timestamp',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

CREATE INDEX IF NOT EXISTS idx_events_workspace_timestamp ON events (workspace_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_events_type_severity ON events (event_type, severity, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_events_unacknowledged ON events (acknowledged, timestamp DESC) WHERE acknowledged = FALSE;

-- Create unique index on event_id and timestamp (required for TimescaleDB)
CREATE UNIQUE INDEX IF NOT EXISTS idx_events_event_id_timestamp ON events (event_id, timestamp);

-- Add retention policy
SELECT add_retention_policy('events', INTERVAL '30 days', if_not_exists => TRUE);

-- Enable compression on hypertables (must be done before adding compression policies)
ALTER TABLE traces SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'workspace_id, agent_id'
);

ALTER TABLE performance_metrics SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'workspace_id, agent_id'
);

ALTER TABLE events SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'workspace_id, event_type'
);

-- Add compression policies (compress data older than 7 days)
SELECT add_compression_policy('traces', INTERVAL '7 days', if_not_exists => TRUE);
SELECT add_compression_policy('performance_metrics', INTERVAL '7 days', if_not_exists => TRUE);
SELECT add_compression_policy('events', INTERVAL '7 days', if_not_exists => TRUE);
