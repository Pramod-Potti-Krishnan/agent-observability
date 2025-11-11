-- Update Trace Timestamps to Recent Dates
-- Date: 2025-10-31
-- Purpose: Shift all trace timestamps forward so they fall within the past 7-30 days
--          This fixes the 404 error on agent details pages where queries look for recent data
--
-- Strategy: Calculate the difference between the newest trace and NOW, then add that
--           difference to all trace timestamps to make them recent

-- Show current date range
SELECT 'CURRENT DATE RANGE:' as status;
SELECT
    MIN(timestamp) as oldest_trace,
    MAX(timestamp) as newest_trace,
    NOW() as current_time,
    EXTRACT(EPOCH FROM (NOW() - MAX(timestamp)))/86400 as days_since_newest
FROM traces;

-- Calculate the time shift needed (difference between max timestamp and NOW)
DO $$
DECLARE
    max_timestamp TIMESTAMP WITH TIME ZONE;
    shift_interval INTERVAL;
    affected_rows INT;
BEGIN
    -- Get the maximum timestamp
    SELECT MAX(timestamp) INTO max_timestamp FROM traces;

    -- Calculate how much to shift (make newest trace be 1 hour ago)
    shift_interval := NOW() - INTERVAL '1 hour' - max_timestamp;

    RAISE NOTICE 'Max trace timestamp: %', max_timestamp;
    RAISE NOTICE 'Shift interval: %', shift_interval;
    RAISE NOTICE 'All traces will be shifted forward by: %', shift_interval;

    -- Update all trace timestamps
    UPDATE traces
    SET timestamp = timestamp + shift_interval;

    GET DIAGNOSTICS affected_rows = ROW_COUNT;

    RAISE NOTICE 'Updated % trace timestamps', affected_rows;

    -- Show new date range
    RAISE NOTICE '-------------------------------------------';
    RAISE NOTICE 'NEW DATE RANGE:';
END $$;

-- Verify the update
SELECT
    MIN(timestamp) as oldest_trace,
    MAX(timestamp) as newest_trace,
    NOW() as current_time,
    EXTRACT(EPOCH FROM (NOW() - MAX(timestamp)))/3600 as hours_since_newest,
    COUNT(*) as total_traces
FROM traces;

-- Show sample of updated traces per agent
SELECT 'SAMPLE OF UPDATED TRACES BY AGENT:' as status;
SELECT
    agent_id,
    COUNT(*) as trace_count,
    MIN(timestamp) as first_trace,
    MAX(timestamp) as last_trace,
    EXTRACT(EPOCH FROM (NOW() - MAX(timestamp)))/3600 as hours_ago
FROM traces
GROUP BY agent_id
ORDER BY trace_count DESC
LIMIT 10;

-- Success message
SELECT '✓ Trace timestamps updated successfully!' as result;
SELECT 'All traces are now within the queryable date range' as info;
