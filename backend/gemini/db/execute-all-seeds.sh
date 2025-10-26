#!/bin/bash

################################################################################
# Phase 4 Synthetic Data Generation - Master Execution Script
#
# This script executes all Phase 4 seed scripts in the correct order
# and provides verification output for each step.
#
# Usage:
#   chmod +x execute-all-seeds.sh
#   ./execute-all-seeds.sh
#
# Prerequisites:
#   - PostgreSQL running on localhost:5433
#   - Database: agent_observability_metadata
#   - User: postgres
#   - Phase 4 tables initialized (from init-postgres.sql)
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

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to execute SQL file
execute_sql() {
    local file=$1
    local description=$2

    print_info "Executing: $description"
    print_info "File: $file"

    if [ ! -f "$SCRIPT_DIR/$file" ]; then
        print_error "File not found: $SCRIPT_DIR/$file"
        return 1
    fi

    # Execute SQL and capture output
    output=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SCRIPT_DIR/$file" 2>&1)
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        print_success "Completed: $description"
        echo "$output" | tail -20  # Show last 20 lines of output
    else
        print_error "Failed: $description"
        echo "$output"
        return 1
    fi

    echo ""
    echo "----------------------------------------"
    echo ""
}

# Function to check database connection
check_connection() {
    print_info "Checking database connection..."

    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        print_success "Database connection successful"
        echo ""
    else
        print_error "Cannot connect to database"
        print_error "Please ensure PostgreSQL is running on $DB_HOST:$DB_PORT"
        exit 1
    fi
}

# Function to verify workspace exists
verify_workspace() {
    print_info "Verifying workspace existence..."

    workspace_count=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM workspaces WHERE slug = 'dev-workspace';" 2>/dev/null | xargs)

    if [ "$workspace_count" -eq "0" ]; then
        print_error "Workspace 'dev-workspace' not found"
        print_error "Please create workspace first or update slug in seed scripts"
        exit 1
    else
        print_success "Workspace 'dev-workspace' found"
        echo ""
    fi
}

# Function to show final summary
show_summary() {
    print_info "Generating final summary..."

    summary=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t <<'EOF'
WITH workspace AS (
    SELECT id FROM workspaces WHERE slug = 'dev-workspace'
)
SELECT
    'evaluations' as table_name,
    COUNT(*)::text as record_count
FROM evaluations
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT
    'guardrail_rules',
    COUNT(*)::text
FROM guardrail_rules
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT
    'guardrail_violations',
    COUNT(*)::text
FROM guardrail_violations
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT
    'alert_rules',
    COUNT(*)::text
FROM alert_rules
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT
    'alert_notifications',
    COUNT(*)::text
FROM alert_notifications
WHERE workspace_id = (SELECT id FROM workspace)

UNION ALL

SELECT
    'business_goals',
    COUNT(*)::text
FROM business_goals
WHERE workspace_id = (SELECT id FROM workspace);
EOF
)

    echo ""
    echo "========================================"
    echo "  PHASE 4 DATA GENERATION SUMMARY"
    echo "========================================"
    echo ""
    echo "$summary" | column -t -s '|'
    echo ""
    echo "========================================"
    echo ""
}

################################################################################
# Main Execution
################################################################################

echo ""
echo "========================================"
echo "  Phase 4 Synthetic Data Generation"
echo "========================================"
echo ""
echo "Database: $DB_NAME"
echo "Host: $DB_HOST:$DB_PORT"
echo "User: $DB_USER"
echo ""
echo "========================================"
echo ""

# Step 1: Check database connection
check_connection

# Step 2: Verify workspace exists
verify_workspace

# Step 3: Query workspace ID
execute_sql "get-workspace-id.sql" "Query workspace ID"
if [ $? -ne 0 ]; then
    print_error "Failed to query workspace ID. Aborting."
    exit 1
fi

# Step 4: Seed evaluations
execute_sql "seed-evaluations.sql" "Generate 1000 evaluation records"
if [ $? -ne 0 ]; then
    print_error "Failed to generate evaluations. Aborting."
    exit 1
fi

# Step 5: Seed guardrail violations
execute_sql "seed-violations.sql" "Generate guardrail rules and violations"
if [ $? -ne 0 ]; then
    print_error "Failed to generate violations. Aborting."
    exit 1
fi

# Step 6: Seed alerts
execute_sql "seed-alerts.sql" "Generate alert rules and notifications"
if [ $? -ne 0 ]; then
    print_error "Failed to generate alerts. Aborting."
    exit 1
fi

# Step 7: Seed business goals
execute_sql "seed-business-goals.sql" "Generate business goals"
if [ $? -ne 0 ]; then
    print_error "Failed to generate business goals. Aborting."
    exit 1
fi

# Step 8: Show summary
show_summary

print_success "Phase 4 synthetic data generation complete!"
print_info "Next steps:"
echo "  1. Verify home page quality score displays correctly"
echo "  2. Test /dashboard/quality page (1000 evaluations)"
echo "  3. Test /dashboard/safety page (200 violations)"
echo "  4. Test /dashboard/impact page (10 business goals)"
echo "  5. Test Phase 4 API endpoints with generated data"
echo ""

exit 0
