-- Seed Data for Agent Observability Platform
-- Generates synthetic traces for testing and demo purposes

-- Generate sample traces for the past 7 days
-- This will populate the dashboards with meaningful data

DO $$
DECLARE
    workspace_id UUID := '00000000-0000-0000-0000-000000000001';
    agent_ids TEXT[] := ARRAY['agent-gpt4', 'agent-claude', 'agent-gemini', 'agent-mixtral'];
    models TEXT[] := ARRAY['gpt-4-turbo', 'claude-3-opus', 'gemini-pro', 'mixtral-8x7b'];
    statuses TEXT[] := ARRAY['success', 'success', 'success', 'success', 'success', 'error', 'timeout'];
    users TEXT[] := ARRAY['user-001', 'user-002', 'user-003', 'user-004', 'user-005'];
    i INT;
    days_back INT;
    hour_offset INT;
    agent TEXT;
    model TEXT;
    status TEXT;
    user_id TEXT;
    trace_timestamp TIMESTAMPTZ;
    latency INT;
    cost DECIMAL(10,6);
BEGIN
    -- Generate 1000 sample traces across 7 days
    FOR i IN 1..1000 LOOP
        -- Random day in past 7 days
        days_back := floor(random() * 7)::INT;
        hour_offset := floor(random() * 24)::INT;
        trace_timestamp := NOW() - (days_back || ' days')::INTERVAL - (hour_offset || ' hours')::INTERVAL;

        -- Random selections
        agent := agent_ids[1 + floor(random() * array_length(agent_ids, 1))::INT];
        model := models[1 + floor(random() * array_length(models, 1))::INT];
        status := statuses[1 + floor(random() * array_length(statuses, 1))::INT];
        user_id := users[1 + floor(random() * array_length(users, 1))::INT];

        -- Realistic latency (100-5000ms, with occasional spikes)
        IF random() < 0.9 THEN
            latency := 100 + floor(random() * 2000)::INT;
        ELSE
            latency := 2000 + floor(random() * 3000)::INT;
        END IF;

        -- Realistic costs based on model
        CASE model
            WHEN 'gpt-4-turbo' THEN cost := 0.01 + random() * 0.05;
            WHEN 'claude-3-opus' THEN cost := 0.015 + random() * 0.06;
            WHEN 'gemini-pro' THEN cost := 0.005 + random() * 0.02;
            WHEN 'mixtral-8x7b' THEN cost := 0.003 + random() * 0.01;
        END CASE;

        -- Insert trace
        INSERT INTO traces (
            trace_id,
            workspace_id,
            agent_id,
            user_id,
            timestamp,
            latency_ms,
            status,
            model,
            model_provider,
            tokens_input,
            tokens_output,
            tokens_total,
            cost_usd,
            input,
            output,
            error,
            metadata,
            tags
        ) VALUES (
            'trace-' || i::TEXT || '-' || extract(epoch from trace_timestamp)::TEXT,
            workspace_id,
            agent,
            user_id,
            trace_timestamp,
            latency,
            status,
            model,
            CASE
                WHEN model LIKE 'gpt%' THEN 'openai'
                WHEN model LIKE 'claude%' THEN 'anthropic'
                WHEN model LIKE 'gemini%' THEN 'google'
                ELSE 'mistral'
            END,
            floor(50 + random() * 500)::INT,
            floor(20 + random() * 200)::INT,
            floor(70 + random() * 700)::INT,
            CASE WHEN status = 'success' THEN cost ELSE NULL END,
            'Sample prompt for testing iteration ' || i::TEXT,
            CASE WHEN status = 'success' THEN 'Sample response from AI model for iteration ' || i::TEXT ELSE NULL END,
            CASE
                WHEN status = 'error' THEN 'Sample error message: API_ERROR'
                WHEN status = 'timeout' THEN 'Request timeout after ' || latency::TEXT || 'ms'
                ELSE NULL
            END,
            jsonb_build_object(
                'temperature', 0.7,
                'max_tokens', 1000,
                'environment', 'development'
            ),
            ARRAY['test', 'synthetic']
        );
    END LOOP;

    RAISE NOTICE 'Generated 1000 synthetic traces';
END $$;

-- Verify data was inserted
SELECT
    COUNT(*) as total_traces,
    COUNT(DISTINCT agent_id) as unique_agents,
    COUNT(DISTINCT user_id) as unique_users,
    MIN(timestamp) as earliest_trace,
    MAX(timestamp) as latest_trace
FROM traces;
