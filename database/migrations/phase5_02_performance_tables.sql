-- Phase 5 Migration Part 2: Performance Tables (without workspace FK)
-- Purpose: Create performance tracking tables
-- Date: October 27, 2025

-- ================================================
-- CREATE SLO Configurations Table
-- ================================================
CREATE TABLE IF NOT EXISTS slo_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL,
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

-- ================================================
-- CREATE Performance Events Table
-- ================================================
CREATE TABLE IF NOT EXISTS performance_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL,

    -- Event Details
    event_type VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Change Information
    version_before VARCHAR(50),
    version_after VARCHAR(50),
    affected_agents TEXT[],

    -- Impact Metrics
    impact_on_latency_pct DECIMAL(7,2),
    impact_on_error_rate_pct DECIMAL(7,2),
    impact_on_throughput_pct DECIMAL(7,2),

    -- Event Context
    description TEXT,
    metadata JSONB,

    -- Status
    status VARCHAR(20) DEFAULT 'detected',
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

-- ================================================
-- CREATE Capacity Configurations Table
-- ================================================
CREATE TABLE IF NOT EXISTS capacity_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL,

    -- Capacity Limits
    max_requests_per_hour INTEGER NOT NULL,
    max_requests_per_second INTEGER NOT NULL,
    max_concurrent_requests INTEGER NOT NULL,

    -- Thresholds for Alerts
    warning_threshold_pct DECIMAL(5,2) DEFAULT 80.0,
    critical_threshold_pct DECIMAL(5,2) DEFAULT 95.0,

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

-- ================================================
-- VALIDATION
-- ================================================
SELECT 'Tables created successfully!' AS status;

SELECT tablename, schemaname
FROM pg_tables
WHERE tablename IN ('slo_configs', 'performance_events', 'capacity_configs')
ORDER BY tablename;
