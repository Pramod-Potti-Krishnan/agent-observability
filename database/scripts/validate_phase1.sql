-- Phase 1 Validation Script
-- Validates all aspects of the database schema transformation

\timing on

SELECT '=== PHASE 1 DATA INTEGRITY VALIDATION ===' as section;
SELECT '' as blank;

-- 1. Row count validation
SELECT '1️⃣  Row Count Validation' as section;
SELECT
    'Total traces' as check_item,
    COUNT(*)::text as value,
    '✅' as status
FROM traces;

-- 2. NULL value checks
SELECT '' as blank;
SELECT '2️⃣  NULL Value Checks' as section;
SELECT
    'Traces with NULL workspace_id' as check_item,
    COUNT(*)::text as value,
    CASE WHEN COUNT(*) = 0 THEN '✅' ELSE '❌ FAIL' END as status
FROM traces WHERE workspace_id IS NULL
UNION ALL
SELECT
    'Traces with NULL department_id' as check_item,
    COUNT(*)::text as value,
    CASE WHEN COUNT(*) = 0 THEN '✅' ELSE '❌ FAIL' END as status
FROM traces WHERE department_id IS NULL
UNION ALL
SELECT
    'Traces with NULL environment_id' as check_item,
    COUNT(*)::text as value,
    CASE WHEN COUNT(*) = 0 THEN '✅' ELSE '❌ FAIL' END as status
FROM traces WHERE environment_id IS NULL
UNION ALL
SELECT
    'Traces with NULL version' as check_item,
    COUNT(*)::text as value,
    CASE WHEN COUNT(*) = 0 THEN '✅' ELSE '❌ FAIL' END as status
FROM traces WHERE version IS NULL
UNION ALL
SELECT
    'Traces with NULL intent_category' as check_item,
    COUNT(*)::text as value,
    CASE WHEN COUNT(*) = 0 THEN '✅' ELSE '❌ FAIL' END as status
FROM traces WHERE intent_category IS NULL;

-- 3. Foreign key integrity
SELECT '' as blank;
SELECT '3️⃣  Foreign Key Integrity' as section;
SELECT
    'Orphaned traces (invalid department_id)' as check_item,
    COUNT(*)::text as value,
    CASE WHEN COUNT(*) = 0 THEN '✅' ELSE '❌ FAIL' END as status
FROM traces t
LEFT JOIN departments d ON t.department_id = d.id
WHERE d.id IS NULL
UNION ALL
SELECT
    'Orphaned traces (invalid environment_id)' as check_item,
    COUNT(*)::text as value,
    CASE WHEN COUNT(*) = 0 THEN '✅' ELSE '❌ FAIL' END as status
FROM traces t
LEFT JOIN environments e ON t.environment_id = e.id
WHERE e.id IS NULL;

-- 4. Index verification
SELECT '' as blank;
SELECT '4️⃣  Index Verification' as section;
SELECT
    'Indexes on traces table' as check_item,
    COUNT(*)::text as value,
    CASE WHEN COUNT(*) >= 18 THEN '✅' ELSE '⚠️  Check' END as status
FROM pg_indexes
WHERE tablename = 'traces';

-- 5. Data distribution validation
SELECT '' as blank;
SELECT '5️⃣  Data Distribution by Department' as section;
SELECT
    d.department_name,
    COUNT(t.id)::text as trace_count,
    ROUND(100.0 * COUNT(t.id) / NULLIF((SELECT COUNT(*) FROM traces), 0), 2)::text || '%' as percentage,
    ROUND(AVG(t.latency_ms), 0)::text || 'ms' as avg_latency,
    '$' || ROUND(SUM(t.cost_usd), 2)::text as total_cost
FROM departments d
LEFT JOIN traces t ON t.department_id = d.id
GROUP BY d.id, d.department_name
ORDER BY COUNT(t.id) DESC;

SELECT '' as blank;
SELECT '6️⃣  Data Distribution by Environment' as section;
SELECT
    e.environment_code,
    COUNT(t.id)::text as trace_count,
    ROUND(100.0 * COUNT(t.id) / NULLIF((SELECT COUNT(*) FROM traces), 0), 2)::text || '%' as percentage,
    ROUND(AVG(t.latency_ms), 0)::text || 'ms' as avg_latency
FROM environments e
LEFT JOIN traces t ON t.environment_id = e.id
GROUP BY e.id, e.environment_code
ORDER BY COUNT(t.id) DESC;

SELECT '' as blank;
SELECT '7️⃣  Data Distribution by Version' as section;
SELECT
    version,
    COUNT(*)::text as trace_count,
    ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM traces), 0), 2)::text || '%' as percentage
FROM traces
GROUP BY version
ORDER BY version DESC;

SELECT '' as blank;
SELECT '8️⃣  Data Distribution by Intent Category' as section;
SELECT
    intent_category,
    COUNT(*)::text as trace_count,
    ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM traces), 0), 2)::text || '%' as percentage
FROM traces
GROUP BY intent_category
ORDER BY COUNT(*) DESC
LIMIT 10;

SELECT '' as blank;
SELECT '9️⃣  Continuous Aggregates Status' as section;
SELECT
    view_name,
    materialization_hypertable_name as mat_table,
    'Active ✅' as status
FROM timescaledb_information.continuous_aggregates
ORDER BY view_name;

SELECT '' as blank;
SELECT '🔟  Sample Query Performance (with new dimensions)' as section;
SELECT
    d.department_name,
    e.environment_code,
    th.version,
    SUM(th.request_count)::text as total_requests,
    ROUND(AVG(th.avg_latency_ms), 0)::text || 'ms' as avg_latency,
    '$' || ROUND(SUM(th.total_cost_usd), 2)::text as total_cost
FROM traces_hourly th
JOIN departments d ON th.department_id = d.id
JOIN environments e ON th.environment_id = e.id
GROUP BY d.department_name, e.environment_code, th.version
ORDER BY SUM(th.request_count) DESC
LIMIT 10;

SELECT '' as blank;
SELECT '=== ✨ PHASE 1 VALIDATION COMPLETE ✨ ===' as section;
