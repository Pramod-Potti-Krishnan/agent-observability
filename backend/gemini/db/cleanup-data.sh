#!/bin/bash

################################################################################
# Phase 4 Synthetic Data Cleanup Script
#
# This script removes all Phase 4 synthetic data from the database.
# Use this when you need to regenerate data or clean up test data.
#
# Usage:
#   chmod +x cleanup-data.sh
#   ./cleanup-data.sh
#
# WARNING: This will permanently delete all Phase 4 data!
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
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

################################################################################
# Main Cleanup
################################################################################

echo ""
echo -e "${RED}========================================"
echo "  Phase 4 Data Cleanup Script"
echo "========================================${NC}"
echo ""
print_warning "This will DELETE all Phase 4 synthetic data!"
echo ""
echo "Tables affected:"
echo "  - evaluations"
echo "  - guardrail_violations"
echo "  - guardrail_rules"
echo "  - alert_notifications"
echo "  - alert_rules"
echo "  - business_goals"
echo ""
print_warning "This action CANNOT be undone!"
echo ""

# Prompt for confirmation
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    print_info "Cleanup cancelled."
    exit 0
fi

echo ""
print_info "Starting cleanup process..."
echo ""

# Show current counts before deletion
print_info "Current record counts:"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
WITH workspace AS (
    SELECT id FROM workspaces WHERE slug = 'dev-workspace'
)
SELECT
    'evaluations' as table_name,
    COUNT(*) as records
FROM evaluations
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT 'guardrail_violations', COUNT(*)
FROM guardrail_violations
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT 'guardrail_rules', COUNT(*)
FROM guardrail_rules
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT 'alert_notifications', COUNT(*)
FROM alert_notifications
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT 'alert_rules', COUNT(*)
FROM alert_rules
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT 'business_goals', COUNT(*)
FROM business_goals
WHERE workspace_id = (SELECT id FROM workspace);
"

echo ""
print_info "Deleting Phase 4 data..."
echo ""

# Execute cleanup SQL
cleanup_output=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" <<'EOF'
-- Delete all Phase 4 data for dev-workspace
WITH workspace AS (
    SELECT id FROM workspaces WHERE slug = 'dev-workspace'
),
deleted_evaluations AS (
    DELETE FROM evaluations
    WHERE workspace_id = (SELECT id FROM workspace)
    RETURNING id
),
deleted_violations AS (
    DELETE FROM guardrail_violations
    WHERE workspace_id = (SELECT id FROM workspace)
    RETURNING id
),
deleted_guardrail_rules AS (
    DELETE FROM guardrail_rules
    WHERE workspace_id = (SELECT id FROM workspace)
    RETURNING id
),
deleted_notifications AS (
    DELETE FROM alert_notifications
    WHERE workspace_id = (SELECT id FROM workspace)
    RETURNING id
),
deleted_alert_rules AS (
    DELETE FROM alert_rules
    WHERE workspace_id = (SELECT id FROM workspace)
    RETURNING id
),
deleted_goals AS (
    DELETE FROM business_goals
    WHERE workspace_id = (SELECT id FROM workspace)
    RETURNING id
)
SELECT
    'evaluations' as table_name,
    COUNT(*) as deleted_count
FROM deleted_evaluations

UNION ALL

SELECT 'guardrail_violations', COUNT(*)
FROM deleted_violations

UNION ALL

SELECT 'guardrail_rules', COUNT(*)
FROM deleted_guardrail_rules

UNION ALL

SELECT 'alert_notifications', COUNT(*)
FROM deleted_notifications

UNION ALL

SELECT 'alert_rules', COUNT(*)
FROM deleted_alert_rules

UNION ALL

SELECT 'business_goals', COUNT(*)
FROM deleted_goals;
EOF
)

if [ $? -eq 0 ]; then
    print_success "Cleanup completed successfully!"
    echo ""
    echo "Deleted records:"
    echo "$cleanup_output"
else
    print_error "Cleanup failed!"
    exit 1
fi

# Verify deletion
echo ""
print_info "Verifying deletion..."
verification=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
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

echo ""
if [ "$verification" -eq "0" ]; then
    print_success "All Phase 4 data has been removed!"
    echo ""
    echo "You can now regenerate data by running:"
    echo "  ./execute-all-seeds.sh"
else
    print_warning "Some records may still remain. Total count: $verification"
    echo ""
    echo "Run verification script to see details:"
    echo "  ./verify-data.sh"
fi

echo ""
