-- Phase 1 Migration: Create Departments Reference Table
-- Purpose: Organizational structure for multi-agent context
-- Date: October 27, 2025

-- Create departments table
CREATE TABLE IF NOT EXISTS departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
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

-- Insert default departments for existing workspace
-- (This assumes workspace_id '550e8400-e29b-41d4-a716-446655440000' from MVP)
INSERT INTO departments (workspace_id, department_code, department_name, description, monthly_budget_usd, cost_center_code)
VALUES
    ((SELECT id FROM workspaces LIMIT 1), 'engineering', 'Engineering', 'Product development and technical teams', 50000.00, 'CC-ENG'),
    ((SELECT id FROM workspaces LIMIT 1), 'sales', 'Sales', 'Sales and business development teams', 25000.00, 'CC-SALES'),
    ((SELECT id FROM workspaces LIMIT 1), 'support', 'Customer Support', 'Customer service and technical support', 15000.00, 'CC-SUP'),
    ((SELECT id FROM workspaces LIMIT 1), 'marketing', 'Marketing', 'Marketing and growth teams', 20000.00, 'CC-MKT'),
    ((SELECT id FROM workspaces LIMIT 1), 'finance', 'Finance', 'Financial planning and accounting', 10000.00, 'CC-FIN'),
    ((SELECT id FROM workspaces LIMIT 1), 'hr', 'Human Resources', 'People operations and recruiting', 12000.00, 'CC-HR'),
    ((SELECT id FROM workspaces LIMIT 1), 'operations', 'Operations', 'Business operations and infrastructure', 18000.00, 'CC-OPS'),
    ((SELECT id FROM workspaces LIMIT 1), 'product', 'Product', 'Product management and design', 22000.00, 'CC-PRD'),
    ((SELECT id FROM workspaces LIMIT 1), 'data', 'Data & Analytics', 'Data science and analytics teams', 28000.00, 'CC-DATA'),
    ((SELECT id FROM workspaces LIMIT 1), 'legal', 'Legal & Compliance', 'Legal affairs and compliance', 8000.00, 'CC-LEGAL')
ON CONFLICT (workspace_id, department_code) DO NOTHING;

-- Validation query
SELECT
    COUNT(*) as department_count,
    SUM(monthly_budget_usd) as total_monthly_budget
FROM departments;
