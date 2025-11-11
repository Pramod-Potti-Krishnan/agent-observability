-- Cost Management Migration: Department Budgets Table
-- Purpose: Track per-department budgets with spend, burn rate, and alert thresholds
-- Date: October 27, 2025

-- Create department_budgets table
CREATE TABLE IF NOT EXISTS department_budgets (
    -- Primary key
    budget_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign keys
    workspace_id UUID NOT NULL,
    department_id UUID NOT NULL, -- Will add FK constraint when departments table is created

    -- Budget allocation
    budget_period VARCHAR(20) NOT NULL CHECK (budget_period IN ('monthly', 'quarterly', 'annual')),
    period_start_date DATE NOT NULL,
    period_end_date DATE NOT NULL,
    allocated_budget_usd DECIMAL(12,2) NOT NULL CHECK (allocated_budget_usd >= 0),

    -- Consumption tracking (computed/updated values)
    spent_to_date_usd DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (spent_to_date_usd >= 0),
    remaining_budget_usd DECIMAL(12,2) GENERATED ALWAYS AS (allocated_budget_usd - spent_to_date_usd) STORED,
    budget_consumed_pct DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE
            WHEN allocated_budget_usd > 0 THEN ROUND((spent_to_date_usd / allocated_budget_usd) * 100, 2)
            ELSE 0
        END
    ) STORED,
    burn_rate_daily_usd DECIMAL(10,2) DEFAULT 0,
    projected_overrun_usd DECIMAL(12,2) DEFAULT 0,
    days_until_depletion INTEGER,

    -- Alert configuration
    alert_threshold_warning DECIMAL(5,2) NOT NULL DEFAULT 80.0 CHECK (alert_threshold_warning BETWEEN 0 AND 100),
    alert_threshold_critical DECIMAL(5,2) NOT NULL DEFAULT 95.0 CHECK (alert_threshold_critical BETWEEN 0 AND 100),
    alert_status VARCHAR(10) NOT NULL DEFAULT 'green' CHECK (alert_status IN ('green', 'yellow', 'red')),
    last_alert_sent_at TIMESTAMP,

    -- Approval & Audit
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP,
    adjustment_history JSONB DEFAULT '[]'::jsonb,

    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT unique_active_dept_budget UNIQUE (workspace_id, department_id, budget_period, period_start_date, is_active),
    CONSTRAINT end_after_start CHECK (period_end_date > period_start_date),
    CONSTRAINT critical_higher_than_warning CHECK (alert_threshold_critical >= alert_threshold_warning)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_dept_budgets_workspace ON department_budgets(workspace_id, is_active);
CREATE INDEX IF NOT EXISTS idx_dept_budgets_dept ON department_budgets(department_id, is_active);
CREATE INDEX IF NOT EXISTS idx_dept_budgets_period ON department_budgets(period_start_date, period_end_date);
CREATE INDEX IF NOT EXISTS idx_dept_budgets_alert_status ON department_budgets(alert_status, is_active);

-- Update trigger for updated_at
CREATE OR REPLACE FUNCTION update_department_budgets_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER department_budgets_updated_at
BEFORE UPDATE ON department_budgets
FOR EACH ROW
EXECUTE FUNCTION update_department_budgets_updated_at();

-- Function to update alert status based on budget consumption
CREATE OR REPLACE FUNCTION update_budget_alert_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.budget_consumed_pct >= NEW.alert_threshold_critical THEN
        NEW.alert_status = 'red';
    ELSIF NEW.budget_consumed_pct >= NEW.alert_threshold_warning THEN
        NEW.alert_status = 'yellow';
    ELSE
        NEW.alert_status = 'green';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER department_budgets_alert_status
BEFORE INSERT OR UPDATE OF spent_to_date_usd, allocated_budget_usd, alert_threshold_warning, alert_threshold_critical
ON department_budgets
FOR EACH ROW
EXECUTE FUNCTION update_budget_alert_status();

-- Add comment for documentation
COMMENT ON TABLE department_budgets IS 'Per-department budget tracking with consumption, burn rate, and alert thresholds';
COMMENT ON COLUMN department_budgets.burn_rate_daily_usd IS 'Average daily spend rate calculated from recent usage';
COMMENT ON COLUMN department_budgets.alert_status IS 'Traffic light status: green (<warning%), yellow (warning-critical%), red (>=critical%)';
COMMENT ON COLUMN department_budgets.adjustment_history IS 'JSON array of budget adjustments: [{adjusted_by, adjusted_at, old_budget, new_budget, justification}]';
