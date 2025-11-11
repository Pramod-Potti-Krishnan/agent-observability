-- Phase 5 Migration: Performance Monitoring Schema
-- Purpose: Add tables and columns for advanced performance monitoring features
-- Date: October 27, 2025

-- ================================================
-- STEP 1: Add phase_timing to traces table
-- ================================================
-- Add JSON column to store execution phase breakdown
ALTER TABLE traces ADD COLUMN IF NOT EXISTS phase_timing JSONB;

-- Add index for phase timing queries
CREATE INDEX IF NOT EXISTS idx_traces_phase_timing ON traces USING GIN (phase_timing);

-- Add comment
COMMENT ON COLUMN traces.phase_timing IS 'Execution phase breakdown: {auth_ms, preprocessing_ms, llm_call_ms, postprocessing_ms, tool_use_ms}';

-- ================================================
-- STEP 2: Create SLO Configurations Table
-- ================================================
CREATE TABLE IF NOT EXISTS slo_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    agent_id VARCHAR(128) NOT NULL,

    -- SLO Targets
    p50_latency_target_ms INTEGER,
    p90_latency_target_ms INTEGER,
    p95_latency_target_ms INTEGER,
    p99_latency_target_ms INTEGER,
    error_rate_target_pct DECIMAL(5,2),
    availability_target_pct DECIMAL(5,2) DEFAULT 99.9,

    -- Error Budget
    error_budget_minutes INTEGER, -- Monthly error budget in minutes
    error_budget_consumed_pct DECIMAL(5,2) DEFAULT 0,

    -- Status
    is_active BOOLEAN DEFAULT true,
    alert_on_violation BOOLEAN DEFAULT true,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by VARCHAR(128),

    -- Constraints
    CONSTRAINT unique_agent_slo UNIQUE (workspace_id, agent_id),
    CONSTRAINT check_latency_targets CHECK (
        p50_latency_target_ms > 0 AND
        p90_latency_target_ms >= p50_latency_target_ms AND
        p95_latency_target_ms >= p90_latency_target_ms AND
        p99_latency_target_ms >= p95_latency_target_ms
    ),
    CONSTRAINT check_error_rate CHECK (error_rate_target_pct >= 0 AND error_rate_target_pct <= 100),
    CONSTRAINT check_availability CHECK (availability_target_pct >= 0 AND availability_target_pct <= 100)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_slo_configs_workspace ON slo_configs(workspace_id);
CREATE INDEX IF NOT EXISTS idx_slo_configs_agent ON slo_configs(workspace_id, agent_id);
CREATE INDEX IF NOT EXISTS idx_slo_configs_active ON slo_configs(workspace_id, is_active);

-- Comments
COMMENT ON TABLE slo_configs IS 'Service Level Objective configurations for agents';
COMMENT ON COLUMN slo_configs.error_budget_minutes IS 'Monthly error budget in minutes (e.g., 99.9% uptime = 43 minutes/month)';

-- ================================================
-- STEP 3: Create Performance Events Table
-- ================================================
CREATE TABLE IF NOT EXISTS performance_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    -- Event Details
    event_type VARCHAR(50) NOT NULL, -- deployment, version_change, scaling, incident, configuration_change
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Change Information
    version_before VARCHAR(50),
    version_after VARCHAR(50),
    affected_agents TEXT[], -- Array of agent IDs

    -- Impact Metrics
    impact_on_latency_pct DECIMAL(7,2), -- Percentage change in latency
    impact_on_error_rate_pct DECIMAL(7,2), -- Percentage change in error rate
    impact_on_throughput_pct DECIMAL(7,2), -- Percentage change in throughput

    -- Event Context
    description TEXT,
    metadata JSONB, -- Additional context (deployment details, config changes, etc.)

    -- Status
    status VARCHAR(20) DEFAULT 'detected', -- detected, investigating, resolved, false_positive
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by VARCHAR(128),

    -- Constraints
    CONSTRAINT check_event_type CHECK (event_type IN (
        'deployment', 'version_change', 'scaling', 'incident',
        'configuration_change', 'regression', 'improvement'
    )),
    CONSTRAINT check_event_status CHECK (status IN (
        'detected', 'investigating', 'resolved', 'false_positive'
    ))
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_perf_events_workspace_time ON performance_events(workspace_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_perf_events_type ON performance_events(event_type, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_perf_events_agents ON performance_events USING GIN (affected_agents);
CREATE INDEX IF NOT EXISTS idx_perf_events_status ON performance_events(status) WHERE status != 'resolved';

-- Comments
COMMENT ON TABLE performance_events IS 'Performance-impacting events (deployments, incidents, regressions)';
COMMENT ON COLUMN performance_events.affected_agents IS 'Array of agent IDs impacted by this event';

-- ================================================
-- STEP 4: Create Capacity Configurations Table
-- ================================================
CREATE TABLE IF NOT EXISTS capacity_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    -- Capacity Limits
    max_requests_per_hour INTEGER NOT NULL,
    max_requests_per_second INTEGER NOT NULL,
    max_concurrent_requests INTEGER NOT NULL,

    -- Thresholds for Alerts
    warning_threshold_pct DECIMAL(5,2) DEFAULT 80.0, -- Alert at 80% capacity
    critical_threshold_pct DECIMAL(5,2) DEFAULT 95.0, -- Critical at 95% capacity

    -- Scope
    department_id UUID REFERENCES departments(id),
    environment_id UUID REFERENCES environments(id),

    -- Status
    is_active BOOLEAN DEFAULT true,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,

    -- Constraints
    CONSTRAINT check_capacity_positive CHECK (
        max_requests_per_hour > 0 AND
        max_requests_per_second > 0 AND
        max_concurrent_requests > 0
    ),
    CONSTRAINT check_threshold_order CHECK (warning_threshold_pct < critical_threshold_pct)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_capacity_workspace ON capacity_configs(workspace_id, is_active);
CREATE INDEX IF NOT EXISTS idx_capacity_dept ON capacity_configs(department_id) WHERE department_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_capacity_env ON capacity_configs(environment_id) WHERE environment_id IS NOT NULL;

-- Comments
COMMENT ON TABLE capacity_configs IS 'Capacity limits and alerting thresholds';

-- ================================================
-- STEP 5: Create Aggregate Views for Performance
-- ================================================

-- Continuous aggregate for latency percentiles (hourly)
CREATE MATERIALIZED VIEW IF NOT EXISTS performance_latency_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour'::interval, timestamp) AS bucket,
    workspace_id,
    agent_id,
    department_id,
    environment_id,
    version,
    model_provider,

    -- Latency Percentiles
    percentile_cont(0.50) WITHIN GROUP (ORDER BY latency_ms) AS p50_latency_ms,
    percentile_cont(0.90) WITHIN GROUP (ORDER BY latency_ms) AS p90_latency_ms,
    percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms) AS p95_latency_ms,
    percentile_cont(0.99) WITHIN GROUP (ORDER BY latency_ms) AS p99_latency_ms,
    AVG(latency_ms) AS avg_latency_ms,
    MIN(latency_ms) AS min_latency_ms,
    MAX(latency_ms) AS max_latency_ms,

    -- Request Counts
    COUNT(*) AS total_requests,
    COUNT(*) FILTER (WHERE status = 'success') AS success_count,
    COUNT(*) FILTER (WHERE status = 'error') AS error_count,
    COUNT(*) FILTER (WHERE status = 'timeout') AS timeout_count,

    -- Error Rate
    (COUNT(*) FILTER (WHERE status = 'error')::DECIMAL / NULLIF(COUNT(*), 0) * 100) AS error_rate_pct
FROM traces
GROUP BY bucket, workspace_id, agent_id, department_id, environment_id, version, model_provider
WITH NO DATA;

-- Add retention policy (keep 90 days)
SELECT add_retention_policy('performance_latency_hourly', INTERVAL '90 days');

-- Refresh policy (every 5 minutes)
SELECT add_continuous_aggregate_policy('performance_latency_hourly',
    start_offset => INTERVAL '3 hours',
    end_offset => INTERVAL '5 minutes',
    schedule_interval => INTERVAL '5 minutes');

-- Indexes on materialized view
CREATE INDEX IF NOT EXISTS idx_perf_latency_hourly_workspace_time
    ON performance_latency_hourly(workspace_id, bucket DESC);
CREATE INDEX IF NOT EXISTS idx_perf_latency_hourly_agent
    ON performance_latency_hourly(agent_id, bucket DESC);
CREATE INDEX IF NOT EXISTS idx_perf_latency_hourly_dept
    ON performance_latency_hourly(department_id, bucket DESC);

-- ================================================
-- STEP 6: Create Helper Functions
-- ================================================

-- Function to calculate SLO compliance
CREATE OR REPLACE FUNCTION calculate_slo_compliance(
    p_workspace_id UUID,
    p_agent_id VARCHAR(128),
    p_start_time TIMESTAMP WITH TIME ZONE,
    p_end_time TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE(
    p50_compliance BOOLEAN,
    p90_compliance BOOLEAN,
    p95_compliance BOOLEAN,
    p99_compliance BOOLEAN,
    error_rate_compliance BOOLEAN,
    overall_compliance_pct DECIMAL(5,2)
) AS $$
DECLARE
    v_slo RECORD;
    v_actual RECORD;
    v_compliant_count INTEGER := 0;
    v_total_checks INTEGER := 5;
BEGIN
    -- Get SLO configuration
    SELECT * INTO v_slo
    FROM slo_configs
    WHERE workspace_id = p_workspace_id
      AND agent_id = p_agent_id
      AND is_active = true
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    -- Get actual metrics
    SELECT
        percentile_cont(0.50) WITHIN GROUP (ORDER BY latency_ms) AS p50,
        percentile_cont(0.90) WITHIN GROUP (ORDER BY latency_ms) AS p90,
        percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms) AS p95,
        percentile_cont(0.99) WITHIN GROUP (ORDER BY latency_ms) AS p99,
        (COUNT(*) FILTER (WHERE status = 'error')::DECIMAL / NULLIF(COUNT(*), 0) * 100) AS error_rate
    INTO v_actual
    FROM traces
    WHERE workspace_id = p_workspace_id
      AND agent_id = p_agent_id
      AND timestamp >= p_start_time
      AND timestamp < p_end_time;

    -- Check compliance
    p50_compliance := (v_actual.p50 <= v_slo.p50_latency_target_ms);
    p90_compliance := (v_actual.p90 <= v_slo.p90_latency_target_ms);
    p95_compliance := (v_actual.p95 <= v_slo.p95_latency_target_ms);
    p99_compliance := (v_actual.p99 <= v_slo.p99_latency_target_ms);
    error_rate_compliance := (v_actual.error_rate <= v_slo.error_rate_target_pct);

    -- Calculate overall compliance
    v_compliant_count := 0;
    IF p50_compliance THEN v_compliant_count := v_compliant_count + 1; END IF;
    IF p90_compliance THEN v_compliant_count := v_compliant_count + 1; END IF;
    IF p95_compliance THEN v_compliant_count := v_compliant_count + 1; END IF;
    IF p99_compliance THEN v_compliant_count := v_compliant_count + 1; END IF;
    IF error_rate_compliance THEN v_compliant_count := v_compliant_count + 1; END IF;

    overall_compliance_pct := (v_compliant_count::DECIMAL / v_total_checks * 100);

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- VALIDATION
-- ================================================
-- Verify tables created
SELECT
    tablename,
    schemaname
FROM pg_tables
WHERE tablename IN ('slo_configs', 'performance_events', 'capacity_configs')
ORDER BY tablename;

-- Verify column added to traces
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'traces'
  AND column_name = 'phase_timing';

-- Verify continuous aggregate created
SELECT view_name, materialization_hypertable_schema, materialization_hypertable_name
FROM timescaledb_information.continuous_aggregates
WHERE view_name = 'performance_latency_hourly';
