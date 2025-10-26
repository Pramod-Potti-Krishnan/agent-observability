-- Seed Evaluation Data for Agent Observability Platform
-- Generates synthetic evaluation records for testing Quality Dashboard
-- Links evaluations to existing traces with realistic score distributions

DO $$
DECLARE
    workspace_id UUID := '37160be9-7d69-43b5-8d5f-9d7b5e14a57a'; -- test-workspace-af436a3e
    evaluators TEXT[] := ARRAY['gemini', 'gemini', 'gemini', 'human', 'custom_model'];
    trace_ids TEXT[];
    i INT;
    trace_id TEXT;
    evaluator TEXT;
    eval_timestamp TIMESTAMPTZ;
    accuracy DECIMAL(3,1);
    relevance DECIMAL(3,1);
    helpfulness DECIMAL(3,1);
    coherence DECIMAL(3,1);
    overall DECIMAL(3,1);
    reasoning_templates TEXT[] := ARRAY[
        'The response demonstrates excellent understanding of the query and provides accurate, relevant information.',
        'Strong performance across all criteria. The answer is coherent and directly addresses the user''s needs.',
        'Good quality response with minor room for improvement in specificity.',
        'Very helpful and accurate response. Clear and well-structured.',
        'Outstanding response quality. Demonstrates deep understanding and provides actionable insights.',
        'Solid performance. The response is relevant and helpful, though could be more detailed.',
        'Excellent coherence and relevance. The response fully addresses the user''s question.',
        'High-quality response with strong accuracy and helpfulness scores.',
        'Well-structured answer that provides clear and relevant information.',
        'Very good response. Shows good understanding and provides useful information.'
    ];
    reasoning TEXT;
BEGIN
    -- Get 1000 random successful trace IDs
    SELECT ARRAY(
        SELECT t.trace_id
        FROM traces t
        WHERE t.workspace_id = workspace_id
        AND t.status = 'success'
        ORDER BY RANDOM()
        LIMIT 1000
    ) INTO trace_ids;

    RAISE NOTICE 'Found % traces to evaluate', array_length(trace_ids, 1);

    -- Generate 1000 evaluation records
    FOR i IN 1..array_length(trace_ids, 1) LOOP
        trace_id := trace_ids[i];

        -- Select evaluator (75% gemini, 20% human, 5% custom)
        evaluator := evaluators[1 + floor(random() * array_length(evaluators, 1))::INT];

        -- Get trace timestamp and use it for evaluation timestamp (add 1-60 minutes)
        SELECT timestamp + (floor(random() * 60)::INT || ' minutes')::INTERVAL
        INTO eval_timestamp
        FROM traces
        WHERE traces.trace_id = trace_ids[i]
        LIMIT 1;

        -- Generate realistic scores (biased toward good quality: 6.0-10.0)
        -- 70% of scores will be 7-9, 20% will be 9-10, 10% will be 6-7
        IF random() < 0.2 THEN
            -- Excellent scores (9-10)
            accuracy := 9.0 + (random() * 1.0);
            relevance := 9.0 + (random() * 1.0);
            helpfulness := 9.0 + (random() * 1.0);
            coherence := 9.0 + (random() * 1.0);
        ELSIF random() < 0.8 THEN
            -- Good scores (7-9)
            accuracy := 7.0 + (random() * 2.0);
            relevance := 7.0 + (random() * 2.0);
            helpfulness := 7.0 + (random() * 2.0);
            coherence := 7.0 + (random() * 2.0);
        ELSE
            -- Acceptable scores (6-7)
            accuracy := 6.0 + (random() * 1.0);
            relevance := 6.0 + (random() * 1.0);
            helpfulness := 6.0 + (random() * 1.0);
            coherence := 6.0 + (random() * 1.0);
        END IF;

        -- Round to 1 decimal place
        accuracy := ROUND(accuracy, 1);
        relevance := ROUND(relevance, 1);
        helpfulness := ROUND(helpfulness, 1);
        coherence := ROUND(coherence, 1);

        -- Calculate overall score (average of 4 criteria)
        overall := ROUND((accuracy + relevance + helpfulness + coherence) / 4.0, 1);

        -- Select random reasoning template
        reasoning := reasoning_templates[1 + floor(random() * array_length(reasoning_templates, 1))::INT];

        -- Insert evaluation record
        INSERT INTO evaluations (
            id,
            workspace_id,
            trace_id,
            created_at,
            evaluator,
            accuracy_score,
            relevance_score,
            helpfulness_score,
            coherence_score,
            overall_score,
            reasoning,
            metadata
        ) VALUES (
            gen_random_uuid(),
            workspace_id,
            trace_id,
            eval_timestamp,
            evaluator,
            accuracy,
            relevance,
            helpfulness,
            coherence,
            overall,
            reasoning,
            jsonb_build_object(
                'model_version', CASE
                    WHEN evaluator = 'gemini' THEN 'gemini-1.5-pro'
                    WHEN evaluator = 'custom_model' THEN 'custom-evaluator-v1'
                    ELSE 'manual'
                END,
                'confidence', 0.85 + (random() * 0.15),
                'evaluation_duration_ms', floor(1000 + random() * 4000)::INT
            )
        );

        -- Log progress every 100 records
        IF i % 100 = 0 THEN
            RAISE NOTICE 'Generated % evaluation records', i;
        END IF;
    END LOOP;

    RAISE NOTICE 'Successfully generated % evaluation records', array_length(trace_ids, 1);
END $$;

-- Verification query
SELECT
    COUNT(*) as total_evaluations,
    ROUND(AVG(overall_score), 2) as avg_overall_score,
    ROUND(AVG(accuracy_score), 2) as avg_accuracy,
    ROUND(AVG(relevance_score), 2) as avg_relevance,
    ROUND(AVG(helpfulness_score), 2) as avg_helpfulness,
    ROUND(AVG(coherence_score), 2) as avg_coherence,
    evaluator,
    COUNT(*) as count_by_evaluator
FROM evaluations
WHERE workspace_id = '37160be9-7d69-43b5-8d5f-9d7b5e14a57a'
GROUP BY evaluator
ORDER BY evaluator;

-- Show distribution by score range
SELECT
    CASE
        WHEN overall_score >= 9.0 THEN '9.0-10.0 (Excellent)'
        WHEN overall_score >= 7.0 THEN '7.0-8.9 (Good)'
        WHEN overall_score >= 6.0 THEN '6.0-6.9 (Acceptable)'
        ELSE 'Below 6.0'
    END as score_range,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as percentage
FROM evaluations
WHERE workspace_id = '37160be9-7d69-43b5-8d5f-9d7b5e14a57a'
GROUP BY score_range
ORDER BY score_range DESC;
