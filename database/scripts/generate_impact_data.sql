--
-- Generate synthetic business impact data
-- Run this after impact_01_business_schema.sql
--

-- Get a workspace_id to use (take the first one)
DO $$
DECLARE
    v_workspace_id UUID;
    v_dept_id UUID;
    v_agent_ids TEXT[] := ARRAY[
        'customer-support-ai-001',
        'escalation-bot-sup-004',
        'sales-qualifier-003',
        'hr-assistant-002',
        'code-review-bot-005'
    ];
    v_agent_id TEXT;
    v_start_date TIMESTAMP;
    v_end_date TIMESTAMP;
    i INTEGER;
BEGIN
    -- Use workspace_id from traces table
    SELECT DISTINCT workspace_id INTO v_workspace_id FROM traces LIMIT 1;

    IF v_workspace_id IS NULL THEN
        RAISE EXCEPTION 'No traces found. Please generate trace data first.';
    END IF;

    RAISE NOTICE 'Using workspace: %', v_workspace_id;

    -- Get a department_id from traces (may be null)
    SELECT DISTINCT department_id INTO v_dept_id FROM traces WHERE department_id IS NOT NULL LIMIT 1;

    -- ================================================================
    -- 1. Insert Business Goals
    -- ================================================================

    -- Goal 1: Cost Savings
    INSERT INTO business_goals (
        workspace_id, goal_type, name, description,
        target_value, current_value, unit, target_date,
        department_id, status, progress_percentage
    ) VALUES (
        v_workspace_id,
        'cost_savings',
        'Reduce AI Infrastructure Costs',
        'Achieve 50% reduction in AI infrastructure costs through optimization',
        50000, 38000, 'usd',
        NOW() + INTERVAL '3 months',
        v_dept_id,
        'active',
        76.0
    );

    -- Goal 2: Customer Satisfaction
    INSERT INTO business_goals (
        workspace_id, goal_type, name, description,
        target_value, current_value, unit, target_date,
        status, progress_percentage
    ) VALUES (
        v_workspace_id,
        'csat',
        'Improve Customer Satisfaction',
        'Increase CSAT score to 4.5/5.0',
        4.5, 4.1, 'score',
        NOW() + INTERVAL '2 months',
        'active',
        82.0
    );

    -- Goal 3: Ticket Reduction
    INSERT INTO business_goals (
        workspace_id, goal_type, name, description,
        target_value, current_value, unit, target_date,
        agent_id, status, progress_percentage
    ) VALUES (
        v_workspace_id,
        'ticket_reduction',
        'Reduce Support Ticket Volume',
        'Reduce daily support tickets by 500',
        500, 450, 'tickets',
        NOW() + INTERVAL '1 month',
        'customer-support-ai-001',
        'at_risk',
        90.0
    );

    -- Goal 4: Productivity
    INSERT INTO business_goals (
        workspace_id, goal_type, name, description,
        target_value, current_value, unit, target_date,
        status, progress_percentage
    ) VALUES (
        v_workspace_id,
        'productivity',
        'Save 2000 Hours Monthly',
        'Save 2000 employee hours per month through automation',
        2000, 1650, 'hours',
        NOW() + INTERVAL '6 months',
        'active',
        82.5
    );

    -- Goal 5: Revenue Impact
    INSERT INTO business_goals (
        workspace_id, goal_type, name, description,
        target_value, current_value, unit, target_date,
        agent_id, status, progress_percentage
    ) VALUES (
        v_workspace_id,
        'revenue',
        'Increase Sales Conversion',
        'Drive $100K additional revenue through AI sales qualification',
        100000, 45000, 'usd',
        NOW() + INTERVAL '4 months',
        'sales-qualifier-003',
        'behind',
        45.0
    );

    -- ================================================================
    -- 2. Insert Investment Tracking Data
    -- ================================================================

    INSERT INTO investment_tracking (
        workspace_id, period_start, period_end,
        investment_category, amount_usd, description
    ) VALUES
    (v_workspace_id, NOW() - INTERVAL '90 days', NOW(), 'infrastructure', 5000, 'GPU compute and cloud costs'),
    (v_workspace_id, NOW() - INTERVAL '90 days', NOW(), 'development', 4000, 'Engineering time for AI agent development'),
    (v_workspace_id, NOW() - INTERVAL '90 days', NOW(), 'operations', 3000, 'Monitoring and maintenance');

    -- ================================================================
    -- 3. Insert Customer Impact Metrics (last 30 days)
    -- ================================================================

    v_start_date := NOW() - INTERVAL '30 days';
    v_end_date := NOW();

    -- Generate daily customer metrics for each agent
    FOREACH v_agent_id IN ARRAY v_agent_ids
    LOOP
        FOR i IN 0..29 LOOP
            INSERT INTO customer_impact_metrics (
                workspace_id, timestamp, agent_id, department_id,
                csat_score, nps_score, ticket_volume, resolution_time_minutes,
                satisfaction_feedback
            ) VALUES (
                v_workspace_id,
                v_start_date + (i || ' days')::INTERVAL,
                v_agent_id,
                v_dept_id,
                3.2 + (i * 0.03) + (random() * 0.3), -- CSAT trending up from 3.2 to 4.1
                -10 + (i * 2) + (random() * 10), -- NPS trending up from -10 to +40
                1000 - (i * 15) + (random() * 50)::INTEGER, -- Tickets trending down
                50 - (i * 1) + (random() * 10)::INTEGER, -- Resolution time improving
                CASE
                    WHEN random() > 0.7 THEN 'Great experience! The AI agent was very helpful.'
                    WHEN random() > 0.4 THEN 'Quick response time, accurate answers.'
                    ELSE NULL
                END
            );
        END LOOP;
    END LOOP;

    -- ================================================================
    -- 4. Insert Value Attribution Data
    -- ================================================================

    -- Generate weekly value attribution for last 4 weeks
    FOR i IN 0..3 LOOP
        FOREACH v_agent_id IN ARRAY v_agent_ids
        LOOP
            INSERT INTO value_attribution (
                workspace_id, period_start, period_end,
                agent_id, department_id,
                cost_savings_usd, revenue_impact_usd,
                productivity_hours_saved, customer_satisfaction_delta,
                total_value_created_usd, attribution_confidence,
                calculation_method
            ) VALUES (
                v_workspace_id,
                v_start_date + (i * 7 || ' days')::INTERVAL,
                v_start_date + ((i + 1) * 7 || ' days')::INTERVAL,
                v_agent_id,
                v_dept_id,
                -- Cost savings: 8000-12000 per week
                8000 + (random() * 4000),
                -- Revenue impact: 0-5000 per week (varies by agent)
                CASE
                    WHEN v_agent_id LIKE 'sales%' THEN 3000 + (random() * 2000)
                    ELSE random() * 1000
                END,
                -- Productivity: 200-400 hours saved per week
                200 + (random() * 200),
                -- CSAT delta: +0.5 to +1.5
                0.5 + (random() * 1.0),
                -- Total value calculated
                0, -- Will be calculated below
                0.75 + (random() * 0.2), -- Confidence 75-95%
                'correlated'
            );

            -- Update total_value_created_usd
            UPDATE value_attribution
            SET total_value_created_usd = cost_savings_usd + revenue_impact_usd + (productivity_hours_saved * 50)
            WHERE workspace_id = v_workspace_id
                AND agent_id = v_agent_id
                AND period_start = v_start_date + (i * 7 || ' days')::INTERVAL;
        END LOOP;
    END LOOP;

    -- ================================================================
    -- Update goal progress based on current values
    -- ================================================================

    UPDATE business_goals
    SET progress_percentage = (current_value / NULLIF(target_value, 0) * 100)::NUMERIC
    WHERE workspace_id = v_workspace_id;

    -- Update goal status based on progress
    UPDATE business_goals
    SET status = CASE
        WHEN progress_percentage >= 100 THEN 'completed'
        WHEN progress_percentage >= 70 THEN 'active'
        WHEN progress_percentage >= 50 THEN 'at_risk'
        ELSE 'behind'
    END
    WHERE workspace_id = v_workspace_id;

    RAISE NOTICE 'Successfully generated impact data for workspace: %', v_workspace_id;
    RAISE NOTICE 'Created 5 business goals, 30 days of customer metrics, and 4 weeks of value attribution';

END $$;

-- Verify data was created
SELECT 'Business Goals' as table_name, COUNT(*) as row_count FROM business_goals
UNION ALL
SELECT 'Customer Impact Metrics', COUNT(*) FROM customer_impact_metrics
UNION ALL
SELECT 'Value Attribution', COUNT(*) FROM value_attribution
UNION ALL
SELECT 'Investment Tracking', COUNT(*) FROM investment_tracking;
