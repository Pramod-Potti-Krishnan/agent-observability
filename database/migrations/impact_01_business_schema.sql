--
-- Business Impact Schema
-- Tables for tracking business goals, customer metrics, and value attribution
--

-- Business Goals table
CREATE TABLE IF NOT EXISTS business_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL,
    goal_type VARCHAR(50) NOT NULL, -- 'cost_savings', 'productivity', 'csat', 'revenue', 'ticket_reduction'
    name VARCHAR(255) NOT NULL,
    description TEXT,
    target_value NUMERIC NOT NULL,
    current_value NUMERIC DEFAULT 0,
    unit VARCHAR(50), -- 'usd', 'tickets', 'hours', 'percentage', 'score'
    target_date TIMESTAMP,
    department_id UUID,
    agent_id VARCHAR(255),
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'completed', 'at_risk', 'behind'
    progress_percentage NUMERIC DEFAULT 0,
    created_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Customer Impact Metrics table
CREATE TABLE IF NOT EXISTS customer_impact_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    agent_id VARCHAR(255),
    department_id UUID,
    csat_score NUMERIC, -- 1-5
    nps_score INTEGER, -- -100 to 100
    ticket_volume INTEGER,
    resolution_time_minutes INTEGER,
    satisfaction_feedback TEXT,
    customer_id VARCHAR(255),
    interaction_type VARCHAR(50), -- 'chat', 'email', 'voice'
    created_at TIMESTAMP DEFAULT NOW()
);

-- Convert to hypertable for time-series queries
SELECT create_hypertable('customer_impact_metrics', 'timestamp', if_not_exists => TRUE);

-- Value Attribution table
CREATE TABLE IF NOT EXISTS value_attribution (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL,
    period_start TIMESTAMPTZ NOT NULL,
    period_end TIMESTAMPTZ NOT NULL,
    agent_id VARCHAR(255) NOT NULL,
    department_id UUID,
    cost_savings_usd NUMERIC DEFAULT 0,
    revenue_impact_usd NUMERIC DEFAULT 0,
    productivity_hours_saved NUMERIC DEFAULT 0,
    customer_satisfaction_delta NUMERIC DEFAULT 0, -- -4 to +4 (on 5-point scale)
    total_value_created_usd NUMERIC DEFAULT 0,
    attribution_confidence NUMERIC, -- 0-1
    calculation_method VARCHAR(100), -- 'direct', 'correlated', 'estimated'
    created_at TIMESTAMP DEFAULT NOW()
);

-- Investment Tracking table
CREATE TABLE IF NOT EXISTS investment_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL,
    period_start TIMESTAMPTZ NOT NULL,
    period_end TIMESTAMPTZ NOT NULL,
    investment_category VARCHAR(100), -- 'infrastructure', 'development', 'operations', 'training'
    amount_usd NUMERIC NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_business_goals_workspace ON business_goals(workspace_id, status);
CREATE INDEX IF NOT EXISTS idx_business_goals_agent ON business_goals(agent_id) WHERE agent_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_business_goals_dept ON business_goals(department_id) WHERE department_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_business_goals_type ON business_goals(workspace_id, goal_type, status);

CREATE INDEX IF NOT EXISTS idx_customer_metrics_workspace_time ON customer_impact_metrics(workspace_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_customer_metrics_agent ON customer_impact_metrics(workspace_id, agent_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_customer_metrics_dept ON customer_impact_metrics(workspace_id, department_id, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_value_attribution_workspace_agent ON value_attribution(workspace_id, agent_id, period_start);
CREATE INDEX IF NOT EXISTS idx_value_attribution_workspace_period ON value_attribution(workspace_id, period_start DESC);
CREATE INDEX IF NOT EXISTS idx_value_attribution_dept ON value_attribution(workspace_id, department_id, period_start DESC);

CREATE INDEX IF NOT EXISTS idx_investment_workspace_period ON investment_tracking(workspace_id, period_start DESC);

-- Continuous aggregate for daily customer impact summary
CREATE MATERIALIZED VIEW IF NOT EXISTS customer_impact_daily
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', timestamp) AS bucket,
    workspace_id,
    agent_id,
    department_id,
    AVG(csat_score) as avg_csat,
    AVG(nps_score) as avg_nps,
    SUM(ticket_volume) as total_tickets,
    AVG(resolution_time_minutes) as avg_resolution_time,
    COUNT(*) as sample_count
FROM customer_impact_metrics
GROUP BY bucket, workspace_id, agent_id, department_id
WITH NO DATA;

-- Refresh policy for continuous aggregate
SELECT add_continuous_aggregate_policy('customer_impact_daily',
    start_offset => INTERVAL '3 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour',
    if_not_exists => TRUE
);

-- Comments for documentation
COMMENT ON TABLE business_goals IS 'Tracks organizational business goals with progress and status';
COMMENT ON TABLE customer_impact_metrics IS 'Time-series data for customer satisfaction and support metrics';
COMMENT ON TABLE value_attribution IS 'Quantifies business value created by agents and departments';
COMMENT ON TABLE investment_tracking IS 'Tracks AI/ML infrastructure and operational investments for ROI calculation';

COMMENT ON COLUMN business_goals.progress_percentage IS 'Calculated as (current_value / target_value) * 100';
COMMENT ON COLUMN customer_impact_metrics.csat_score IS 'Customer Satisfaction Score on 1-5 scale';
COMMENT ON COLUMN customer_impact_metrics.nps_score IS 'Net Promoter Score on -100 to +100 scale';
COMMENT ON COLUMN value_attribution.attribution_confidence IS 'Statistical confidence in value attribution (0-1)';
COMMENT ON COLUMN value_attribution.total_value_created_usd IS 'Sum of all value components in USD equivalent';
