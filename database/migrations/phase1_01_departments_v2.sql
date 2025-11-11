-- Phase 1 Migration: Create Departments Reference Table
-- Purpose: Organizational structure for multi-agent context
-- Date: October 27, 2025
-- Note: Simplified for MVP schema (no workspaces table yet)

-- Create update_updated_at_column function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create departments table
CREATE TABLE IF NOT EXISTS departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL,  -- No FK constraint since workspaces table doesn't exist yet
    department_code VARCHAR(50) NOT NULL,
    department_name VARCHAR(255) NOT NULL,
    description TEXT,
    monthly_budget_usd DECIMAL(10, 2),
    cost_center_code VARCHAR(50),

    -- Metadata
    metadata JSONB DEFAULT '{}',

    -- Standard timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Unique constraint: one department code per workspace
    CONSTRAINT uniq_departments_workspace_code UNIQUE (workspace_id, department_code)
);

-- Indexes
CREATE INDEX idx_departments_workspace ON departments(workspace_id);
CREATE INDEX idx_departments_code ON departments(department_code);
CREATE INDEX idx_departments_created ON departments(created_at DESC);

-- Update trigger for updated_at
CREATE TRIGGER update_departments_updated_at
    BEFORE UPDATE ON departments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default departments using existing workspace_id from traces
INSERT INTO departments (workspace_id, department_code, department_name, description, monthly_budget_usd, cost_center_code)
SELECT DISTINCT
    t.workspace_id,
    d.code,
    d.name,
    d.description,
    d.budget,
    d.cost_center
FROM traces t
CROSS JOIN (VALUES
    ('engineering', 'Engineering', 'Product development and technical teams', 50000.00, 'CC-ENG'),
    ('sales', 'Sales', 'Sales and business development teams', 25000.00, 'CC-SALES'),
    ('support', 'Customer Support', 'Customer service and technical support', 15000.00, 'CC-SUP'),
    ('marketing', 'Marketing', 'Marketing and growth teams', 20000.00, 'CC-MKT'),
    ('finance', 'Finance', 'Financial planning and accounting', 10000.00, 'CC-FIN'),
    ('hr', 'Human Resources', 'People operations and recruiting', 12000.00, 'CC-HR'),
    ('operations', 'Operations', 'Business operations and infrastructure', 18000.00, 'CC-OPS'),
    ('product', 'Product', 'Product management and design', 22000.00, 'CC-PRD'),
    ('data', 'Data & Analytics', 'Data science and analytics teams', 28000.00, 'CC-DATA'),
    ('legal', 'Legal & Compliance', 'Legal affairs and compliance', 8000.00, 'CC-LEGAL')
) AS d(code, name, description, budget, cost_center)
LIMIT 10
ON CONFLICT (workspace_id, department_code) DO NOTHING;

-- Validation query
SELECT
    COUNT(*) as department_count,
    SUM(monthly_budget_usd) as total_monthly_budget
FROM departments;
