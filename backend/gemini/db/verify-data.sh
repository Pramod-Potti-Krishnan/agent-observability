#!/bin/bash

################################################################################
# Phase 4 Synthetic Data Verification Script
#
# This script verifies that all Phase 4 synthetic data was generated correctly
# and provides detailed statistics for each data type.
#
# Usage:
#   chmod +x verify-data.sh
#   ./verify-data.sh
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Database connection parameters
DB_HOST="localhost"
DB_PORT="5433"
DB_USER="postgres"
DB_NAME="agent_observability_metadata"

# Function to print colored messages
print_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to execute query and display results
execute_query() {
    local query=$1
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$query"
    echo ""
}

################################################################################
# Main Verification
################################################################################

print_section "PHASE 4 DATA VERIFICATION"

# 1. Workspace Check
print_section "1. Workspace Verification"
execute_query "SELECT id, slug, name, created_at FROM workspaces WHERE slug = 'dev-workspace';"

# 2. Record Counts Summary
print_section "2. Record Count Summary"
execute_query "
WITH workspace AS (
    SELECT id FROM workspaces WHERE slug = 'dev-workspace'
)
SELECT
    'evaluations' as table_name,
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) = 1000 THEN '✓ Expected' ELSE '✗ Unexpected' END as status
FROM evaluations
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT
    'guardrail_rules',
    COUNT(*),
    CASE WHEN COUNT(*) = 5 THEN '✓ Expected' ELSE '✗ Unexpected' END
FROM guardrail_rules
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT
    'guardrail_violations',
    COUNT(*),
    CASE WHEN COUNT(*) = 200 THEN '✓ Expected' ELSE '✗ Unexpected' END
FROM guardrail_violations
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT
    'alert_rules',
    COUNT(*),
    CASE WHEN COUNT(*) = 4 THEN '✓ Expected' ELSE '✗ Unexpected' END
FROM alert_rules
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT
    'alert_notifications',
    COUNT(*),
    CASE WHEN COUNT(*) = 50 THEN '✓ Expected' ELSE '✗ Unexpected' END
FROM alert_notifications
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT
    'business_goals',
    COUNT(*),
    CASE WHEN COUNT(*) = 10 THEN '✓ Expected' ELSE '✗ Unexpected' END
FROM business_goals
WHERE workspace_id = (SELECT id FROM workspace);
"

# 3. Evaluation Statistics
print_section "3. Evaluation Statistics"
execute_query "
SELECT
    evaluator,
    COUNT(*) as total_evaluations,
    ROUND(AVG(overall_score), 2) as avg_overall_score,
    ROUND(MIN(overall_score), 2) as min_score,
    ROUND(MAX(overall_score), 2) as max_score,
    ROUND(AVG(accuracy_score), 2) as avg_accuracy,
    ROUND(AVG(relevance_score), 2) as avg_relevance,
    ROUND(AVG(helpfulness_score), 2) as avg_helpfulness,
    ROUND(AVG(coherence_score), 2) as avg_coherence
FROM evaluations
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
GROUP BY evaluator;
"

# 4. Evaluation Time Distribution
print_section "4. Evaluation Time Distribution"
execute_query "
SELECT
    DATE(created_at) as date,
    COUNT(*) as evaluations,
    ROUND(AVG(overall_score), 2) as avg_score
FROM evaluations
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
GROUP BY DATE(created_at)
ORDER BY date DESC;
"

# 5. Guardrail Rules
print_section "5. Guardrail Rules"
execute_query "
SELECT
    rule_name,
    rule_type,
    severity,
    action,
    is_active
FROM guardrail_rules
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
ORDER BY severity DESC;
"

# 6. Guardrail Violations Statistics
print_section "6. Guardrail Violations Statistics"
execute_query "
SELECT
    gr.rule_type,
    gr.rule_name,
    COUNT(*) as violation_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as percentage
FROM guardrail_violations gv
JOIN guardrail_rules gr ON gv.rule_id = gr.id
WHERE gv.workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
GROUP BY gr.rule_type, gr.rule_name
ORDER BY violation_count DESC;
"

# 7. Violation Severity Distribution
print_section "7. Violation Severity Distribution"
execute_query "
SELECT
    severity,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as percentage
FROM guardrail_violations
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
GROUP BY severity
ORDER BY
    CASE severity
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
    END;
"

# 8. Alert Rules
print_section "8. Alert Rules"
execute_query "
SELECT
    rule_name,
    metric,
    condition,
    threshold,
    window_minutes,
    severity,
    is_active
FROM alert_rules
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
ORDER BY severity DESC;
"

# 9. Alert Notifications Statistics
print_section "9. Alert Notifications Statistics"
execute_query "
SELECT
    ar.rule_name,
    COUNT(*) as notification_count,
    ROUND(AVG(an.metric_value), 2) as avg_metric_value,
    ar.threshold as threshold_value,
    COUNT(CASE WHEN an.status = 'resolved' THEN 1 END) as resolved,
    COUNT(CASE WHEN an.status = 'acknowledged' THEN 1 END) as acknowledged,
    COUNT(CASE WHEN an.status = 'open' THEN 1 END) as open
FROM alert_notifications an
JOIN alert_rules ar ON an.rule_id = ar.id
WHERE an.workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
GROUP BY ar.rule_name, ar.threshold
ORDER BY notification_count DESC;
"

# 10. Alert Status Distribution
print_section "10. Alert Status Distribution"
execute_query "
SELECT
    status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as percentage
FROM alert_notifications
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
GROUP BY status
ORDER BY
    CASE status
        WHEN 'open' THEN 1
        WHEN 'acknowledged' THEN 2
        WHEN 'resolved' THEN 3
    END;
"

# 11. Business Goals Overview
print_section "11. Business Goals Overview"
execute_query "
SELECT
    goal_type,
    name,
    baseline,
    current_value,
    target,
    unit,
    progress_percentage || '%' as progress,
    status
FROM business_goals
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
ORDER BY progress_percentage DESC;
"

# 12. Business Goals Progress Categories
print_section "12. Business Goals Progress Categories"
execute_query "
SELECT
    CASE
        WHEN progress_percentage >= 90 THEN 'Excellent (90-100%)'
        WHEN progress_percentage >= 75 THEN 'On Track (75-89%)'
        WHEN progress_percentage >= 50 THEN 'Progressing (50-74%)'
        ELSE 'Needs Attention (<50%)'
    END as progress_category,
    COUNT(*) as goal_count,
    ROUND(AVG(progress_percentage), 2) as avg_progress
FROM business_goals
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
GROUP BY progress_category
ORDER BY MIN(progress_percentage) DESC;
"

# 13. Time Range Verification
print_section "13. Time Range Verification"
execute_query "
WITH workspace AS (
    SELECT id FROM workspaces WHERE slug = 'dev-workspace'
)
SELECT
    'evaluations' as data_type,
    MIN(created_at) as earliest,
    MAX(created_at) as latest,
    EXTRACT(DAY FROM (MAX(created_at) - MIN(created_at))) || ' days' as range
FROM evaluations
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT
    'violations',
    MIN(detected_at),
    MAX(detected_at),
    EXTRACT(DAY FROM (MAX(detected_at) - MIN(detected_at))) || ' days'
FROM guardrail_violations
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT
    'alerts',
    MIN(triggered_at),
    MAX(triggered_at),
    EXTRACT(DAY FROM (MAX(triggered_at) - MIN(triggered_at))) || ' days'
FROM alert_notifications
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT
    'goals',
    MIN(created_at),
    MAX(created_at),
    EXTRACT(DAY FROM (MAX(created_at) - MIN(created_at))) || ' days'
FROM business_goals
WHERE workspace_id = (SELECT id FROM workspace);
"

# 14. Final Summary
print_section "14. VERIFICATION SUMMARY"

total_records=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
WITH workspace AS (
    SELECT id FROM workspaces WHERE slug = 'dev-workspace'
)
SELECT
    (SELECT COUNT(*) FROM evaluations WHERE workspace_id = (SELECT id FROM workspace)) +
    (SELECT COUNT(*) FROM guardrail_rules WHERE workspace_id = (SELECT id FROM workspace)) +
    (SELECT COUNT(*) FROM guardrail_violations WHERE workspace_id = (SELECT id FROM workspace)) +
    (SELECT COUNT(*) FROM alert_rules WHERE workspace_id = (SELECT id FROM workspace)) +
    (SELECT COUNT(*) FROM alert_notifications WHERE workspace_id = (SELECT id FROM workspace)) +
    (SELECT COUNT(*) FROM business_goals WHERE workspace_id = (SELECT id FROM workspace));
" | xargs)

echo "Total Phase 4 Records: $total_records"
echo "Expected: 1,269 (1000 + 5 + 200 + 4 + 50 + 10)"
echo ""

if [ "$total_records" -eq "1269" ]; then
    print_success "All Phase 4 data generated successfully!"
else
    print_error "Record count mismatch. Expected 1,269, got $total_records"
fi

echo ""
echo "Verification complete!"
echo ""
