-- Update Evaluation Timestamps to Spread Across 7 Days
-- This updates existing evaluations to distribute them from Oct 16-22, 2025
-- Preserves existing score data while fixing the date distribution

DO $$
DECLARE
    workspace_id UUID := '37160be9-7d69-43b5-8d5f-9d7b5e14a57a';
    base_date TIMESTAMPTZ := '2025-10-16 00:00:00'::TIMESTAMPTZ;
    total_evals INT;
    evals_per_day INT;
    current_day INT := 0;
    current_count INT := 0;
    eval_record RECORD;
BEGIN
    -- Get total count
    SELECT COUNT(*) INTO total_evals
    FROM evaluations
    WHERE evaluations.workspace_id = update_evaluation_dates.workspace_id;

    RAISE NOTICE 'Updating % evaluations to spread across 7 days', total_evals;

    -- Calculate evaluations per day (distribute evenly)
    evals_per_day := CEIL(total_evals / 7.0);

    RAISE NOTICE 'Target: ~% evaluations per day', evals_per_day;

    -- Update each evaluation with distributed timestamp
    FOR eval_record IN (
        SELECT id
        FROM evaluations
        WHERE evaluations.workspace_id = update_evaluation_dates.workspace_id
        ORDER BY id
    ) LOOP
        -- Calculate which day this evaluation belongs to
        current_day := FLOOR(current_count / evals_per_day::float);

        -- Ensure we don't exceed 6 days (0-6)
        IF current_day > 6 THEN
            current_day := 6;
        END IF;

        -- Update the timestamp to spread within the day
        UPDATE evaluations
        SET created_at = base_date
            + (current_day || ' days')::INTERVAL
            + (floor(random() * 24)::INT || ' hours')::INTERVAL
            + (floor(random() * 60)::INT || ' minutes')::INTERVAL
        WHERE id = eval_record.id;

        current_count := current_count + 1;

        -- Log progress every 100 records
        IF current_count % 100 = 0 THEN
            RAISE NOTICE 'Updated % evaluations', current_count;
        END IF;
    END LOOP;

    RAISE NOTICE 'Successfully updated % evaluation timestamps', current_count;
END $$;

-- Verification queries
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
    '=== Date Range ===' as section;

SELECT
    MIN(created_at) as earliest,
    MAX(created_at) as latest,
    COUNT(*) as total
FROM evaluations
WHERE workspace_id = '37160be9-7d69-43b5-8d5f-9d7b5e14a57a';
