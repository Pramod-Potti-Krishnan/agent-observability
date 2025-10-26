-- Reseed Evaluation Data with 7-Day Distribution
-- Deletes existing evaluations and regenerates them spread across 7 days
-- This fixes the Quality trend chart showing only one data point

-- Step 1: Delete existing evaluations
DELETE FROM evaluations
WHERE workspace_id = '37160be9-7d69-43b5-8d5f-9d7b5e14a57a';

-- Step 2: Generate new evaluations spread across 7 days (Oct 16-22, 2025)
DO $$
DECLARE
    workspace_id UUID := '37160be9-7d69-43b5-8d5f-9d7b5e14a57a';
    evaluators TEXT[] := ARRAY['gemini', 'gemini', 'gemini', 'human', 'custom_model'];
    trace_ids TEXT[];
    i INT;
    trace_id TEXT;
    evaluator TEXT;
    eval_timestamp TIMESTAMPTZ;
    base_date TIMESTAMPTZ := '2025-10-16 00:00:00'::TIMESTAMPTZ;  -- Start date
    days_offset INT;
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
    RAISE NOTICE 'Distributing evaluations from Oct 16-22, 2025';

    -- Generate 1000 evaluation records spread across 7 days
    FOR i IN 1..array_length(trace_ids, 1) LOOP
        trace_id := trace_ids[i];

        -- Select evaluator (75% gemini, 20% human, 5% custom)
        evaluator := evaluators[1 + floor(random() * array_length(evaluators, 1))::INT];

        -- Randomly distribute across 7 days (0-6 days from base_date)
        -- Add random hours (0-23) and minutes (0-59) for variety within each day
        days_offset := floor(random() * 7)::INT;
        eval_timestamp := base_date
            + (days_offset || ' days')::INTERVAL
            + (floor(random() * 24)::INT || ' hours')::INTERVAL
            + (floor(random() * 60)::INT || ' minutes')::INTERVAL;

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

    RAISE NOTICE 'Successfully generated % evaluation records across 7 days', array_length(trace_ids, 1);
END $$;

-- Verification queries
SELECT
    '=== Total Evaluations ===' as section;

SELECT
    COUNT(*) as total_evaluations,
    ROUND(AVG(overall_score), 2) as avg_overall_score,
    MIN(created_at) as earliest_evaluation,
    MAX(created_at) as latest_evaluation
FROM evaluations
WHERE workspace_id = '37160be9-7d69-43b5-8d5f-9d7b5e14a57a';

SELECT
    '=== Distribution by Date ===' as section;

SELECT
    DATE(created_at) as eval_date,
    COUNT(*) as evaluations_per_day,
    ROUND(AVG(overall_score), 2) as avg_score
FROM evaluations
WHERE workspace_id = '37160be9-7d69-43b5-8d5f-9d7b5e14a57a'
GROUP BY DATE(created_at)
ORDER BY eval_date;

SELECT
    '=== Distribution by Evaluator ===' as section;

SELECT
    evaluator,
    COUNT(*) as count,
    ROUND(AVG(overall_score), 2) as avg_score
FROM evaluations
WHERE workspace_id = '37160be9-7d69-43b5-8d5f-9d7b5e14a57a'
GROUP BY evaluator
ORDER BY evaluator;

SELECT
    '=== Distribution by Score Range ===' as section;

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
