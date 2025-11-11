-- Cost Management Migration: Cost Optimization Opportunities Table
-- Purpose: Track cost optimization recommendations with impact estimates and implementation tracking
-- Date: October 27, 2025

-- Create enum for optimization types
CREATE TYPE optimization_type AS ENUM (
    'model_downgrade',
    'caching',
    'prompt_optimization',
    'provider_switch',
    'batching',
    'token_reduction',
    'agent_deprecation'
);

-- Create enum for implementation effort
CREATE TYPE implementation_effort AS ENUM ('low', 'medium', 'high');

-- Create enum for technical risk
CREATE TYPE technical_risk AS ENUM ('low', 'medium', 'high');

-- Create enum for quality impact
CREATE TYPE quality_impact AS ENUM ('none', 'minimal', 'moderate', 'significant');

-- Create enum for opportunity status
CREATE TYPE opportunity_status AS ENUM (
    'identified',
    'in_review',
    'approved',
    'in_progress',
    'implemented',
    'declined',
    'obsolete'
);

-- Create cost_optimization_opportunities table
CREATE TABLE IF NOT EXISTS cost_optimization_opportunities (
    -- Primary key
    opportunity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign keys
    workspace_id UUID NOT NULL, -- Will add FK when workspaces table is available

    -- Opportunity type
    optimization_type optimization_type NOT NULL,

    -- Scope
    affected_agents TEXT[] NOT NULL DEFAULT '{}',
    affected_departments UUID[] DEFAULT '{}',

    -- Impact estimate
    current_cost_monthly_usd DECIMAL(12,2) NOT NULL CHECK (current_cost_monthly_usd >= 0),
    optimized_cost_monthly_usd DECIMAL(12,2) NOT NULL CHECK (optimized_cost_monthly_usd >= 0),
    savings_potential_monthly_usd DECIMAL(12,2) GENERATED ALWAYS AS (current_cost_monthly_usd - optimized_cost_monthly_usd) STORED,
    savings_potential_annual_usd DECIMAL(12,2) GENERATED ALWAYS AS ((current_cost_monthly_usd - optimized_cost_monthly_usd) * 12) STORED,

    -- Implementation details
    implementation_effort implementation_effort NOT NULL DEFAULT 'medium',
    estimated_hours INTEGER CHECK (estimated_hours > 0),
    technical_risk technical_risk NOT NULL DEFAULT 'low',
    quality_impact quality_impact NOT NULL DEFAULT 'none',

    -- Detailed recommendation (JSON structure)
    recommendation_details JSONB NOT NULL DEFAULT '{}'::jsonb,
    -- Expected structure:
    -- {
    --   "current_config": {...},
    --   "recommended_config": {...},
    --   "implementation_steps": [...],
    --   "rollback_plan": "...",
    --   "testing_checklist": [...]
    -- }

    -- Status tracking
    status opportunity_status NOT NULL DEFAULT 'identified',
    assigned_to UUID, -- Will add FK when users table is available
    implemented_at TIMESTAMP,
    actual_savings_realized_usd DECIMAL(12,2) CHECK (actual_savings_realized_usd >= 0),

    -- Priority score (0-100, higher = more important)
    priority_score INTEGER NOT NULL DEFAULT 50 CHECK (priority_score BETWEEN 0 AND 100),

    -- Metadata
    identified_by VARCHAR(100) NOT NULL, -- 'system_ml' or user_id
    reviewed_by UUID, -- Will add FK when users table is available
    notes TEXT,

    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_savings CHECK (savings_potential_monthly_usd >= 0),
    CONSTRAINT valid_cost_reduction CHECK (optimized_cost_monthly_usd <= current_cost_monthly_usd)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_cost_opp_workspace ON cost_optimization_opportunities(workspace_id, status);
CREATE INDEX IF NOT EXISTS idx_cost_opp_type ON cost_optimization_opportunities(optimization_type, status);
CREATE INDEX IF NOT EXISTS idx_cost_opp_savings ON cost_optimization_opportunities(savings_potential_monthly_usd DESC);
CREATE INDEX IF NOT EXISTS idx_cost_opp_priority ON cost_optimization_opportunities(priority_score DESC, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cost_opp_status ON cost_optimization_opportunities(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cost_opp_assigned ON cost_optimization_opportunities(assigned_to, status);

-- GIN index for array searches
CREATE INDEX IF NOT EXISTS idx_cost_opp_agents ON cost_optimization_opportunities USING GIN (affected_agents);
CREATE INDEX IF NOT EXISTS idx_cost_opp_depts ON cost_optimization_opportunities USING GIN (affected_departments);

-- Update trigger for updated_at
CREATE OR REPLACE FUNCTION update_cost_opp_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cost_opp_updated_at
BEFORE UPDATE ON cost_optimization_opportunities
FOR EACH ROW
EXECUTE FUNCTION update_cost_opp_updated_at();

-- Trigger to auto-set implemented_at timestamp
CREATE OR REPLACE FUNCTION set_opp_implemented_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'implemented' AND OLD.status != 'implemented' THEN
        NEW.implemented_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER opp_implemented_at
BEFORE UPDATE OF status ON cost_optimization_opportunities
FOR EACH ROW
EXECUTE FUNCTION set_opp_implemented_at();

-- Add comments for documentation
COMMENT ON TABLE cost_optimization_opportunities IS 'Cost optimization recommendations with impact estimates and implementation tracking';
COMMENT ON COLUMN cost_optimization_opportunities.optimization_type IS 'Type of optimization: model_downgrade, caching, prompt_optimization, etc.';
COMMENT ON COLUMN cost_optimization_opportunities.affected_agents IS 'Array of agent_ids affected by this optimization';
COMMENT ON COLUMN cost_optimization_opportunities.priority_score IS 'ML-generated or manual priority score (0-100, higher = more important)';
COMMENT ON COLUMN cost_optimization_opportunities.recommendation_details IS 'JSON with current_config, recommended_config, implementation_steps, rollback_plan, testing_checklist';
COMMENT ON COLUMN cost_optimization_opportunities.actual_savings_realized_usd IS 'Actual cost savings measured after implementation (for ROI tracking)';
