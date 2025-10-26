-- Seed Business Goals Data for Impact Dashboard
-- Generates 10 realistic business goals with various progress levels

DO $$
DECLARE
    ws_id UUID := '37160be9-7d69-43b5-8d5f-9d7b5e14a57a'; -- dev-workspace
BEGIN
    -- Delete existing goals for clean slate
    DELETE FROM business_goals WHERE workspace_id = ws_id;

    -- Goal 1: Reduce Support Tickets
    INSERT INTO business_goals (workspace_id, name, description, metric, target_value, current_value, unit, target_date)
    VALUES (ws_id, 'Reduce Support Ticket Volume', 'Reduce customer support tickets by 30% through AI agent automation',
            'support_tickets', 1400.00, 1580.00, 'tickets', (CURRENT_DATE + INTERVAL '90 days')::DATE);

    -- Goal 2: Improve Customer Satisfaction
    INSERT INTO business_goals (workspace_id, name, description, metric, target_value, current_value, unit, target_date)
    VALUES (ws_id, 'Increase CSAT Score', 'Achieve 90% customer satisfaction score for AI-assisted interactions',
            'csat_score', 90.00, 87.50, '%', (CURRENT_DATE + INTERVAL '120 days')::DATE);

    -- Goal 3: Cost Savings
    INSERT INTO business_goals (workspace_id, name, description, metric, target_value, current_value, unit, target_date)
    VALUES (ws_id, 'Achieve Cost Savings Target', 'Save $50,000/month in operational costs through agent automation',
            'cost_savings', 50000.00, 38500.00, '$', (CURRENT_DATE + INTERVAL '180 days')::DATE);

    -- Goal 4: Reduce Response Time
    INSERT INTO business_goals (workspace_id, name, description, metric, target_value, current_value, unit, target_date)
    VALUES (ws_id, 'Faster Response Times', 'Reduce average response time to under 30 seconds',
            'response_time', 30.00, 42.00, 'seconds', (CURRENT_DATE + INTERVAL '60 days')::DATE);

    -- Goal 5: Improve First Contact Resolution
    INSERT INTO business_goals (workspace_id, name, description, metric, target_value, current_value, unit, target_date)
    VALUES (ws_id, 'First Contact Resolution Rate', 'Achieve 85% first contact resolution rate',
            'fcr_rate', 85.00, 76.50, '%', (CURRENT_DATE + INTERVAL '150 days')::DATE);

    -- Goal 6: Agent Accuracy
    INSERT INTO business_goals (workspace_id, name, description, metric, target_value, current_value, unit, target_date)
    VALUES (ws_id, 'Improve Agent Accuracy', 'Maintain 95% accuracy score across all agent interactions',
            'accuracy_score', 95.00, 91.20, '%', (CURRENT_DATE + INTERVAL '90 days')::DATE);

    -- Goal 7: Reduce Escalation Rate
    INSERT INTO business_goals (workspace_id, name, description, metric, target_value, current_value, unit, target_date)
    VALUES (ws_id, 'Lower Escalation Rate', 'Reduce escalations to human agents to under 15%',
            'escalation_rate', 15.00, 18.50, '%', (CURRENT_DATE + INTERVAL '120 days')::DATE);

    -- Goal 8: Increase Automation Coverage
    INSERT INTO business_goals (workspace_id, name, description, metric, target_value, current_value, unit, target_date)
    VALUES (ws_id, 'Expand Automation Coverage', 'Automate 70% of routine customer inquiries',
            'automation_coverage', 70.00, 58.80, '%', (CURRENT_DATE + INTERVAL '180 days')::DATE);

    -- Goal 9: Agent Uptime
    INSERT INTO business_goals (workspace_id, name, description, metric, target_value, current_value, unit, target_date)
    VALUES (ws_id, '99.9% Uptime SLA', 'Maintain 99.9% uptime for all AI agents',
            'uptime', 99.90, 99.72, '%', (CURRENT_DATE + INTERVAL '365 days')::DATE);

    -- Goal 10: User Adoption
    INSERT INTO business_goals (workspace_id, name, description, metric, target_value, current_value, unit, target_date)
    VALUES (ws_id, 'Increase User Adoption', 'Achieve 80% user adoption rate across departments',
            'adoption_rate', 80.00, 67.20, '%', (CURRENT_DATE + INTERVAL '240 days')::DATE);

    RAISE NOTICE 'Successfully created 10 business goal records';
END $$;

-- Verification query
SELECT
    COUNT(*) as total_goals
FROM business_goals
WHERE workspace_id = '37160be9-7d69-43b5-8d5f-9d7b5e14a57a';

-- Show all goals with progress calculation
SELECT
    name,
    metric,
    target_value,
    current_value,
    unit,
    ROUND(((current_value / NULLIF(target_value, 0)) * 100)::numeric, 1) as progress_percentage,
    target_date
FROM business_goals
WHERE workspace_id = '37160be9-7d69-43b5-8d5f-9d7b5e14a57a'
ORDER BY name;
