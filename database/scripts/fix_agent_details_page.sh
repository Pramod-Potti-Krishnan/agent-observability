#!/bin/bash
# Fix Agent Details Page - Complete Script
# Run this after Docker is started
# Date: 2025-10-31

set -e

echo "=========================================="
echo "Fix Agent Details Page - Complete Script"
echo "=========================================="
echo ""

# Check if Docker is running
if ! docker ps > /dev/null 2>&1; then
    echo "ERROR: Docker is not running!"
    echo "Please start Docker and run this script again."
    exit 1
fi

echo "✓ Docker is running"
echo ""

# Step 1: Update trace timestamps
echo "Step 1: Updating trace timestamps to recent dates..."
echo "----------------------------------------"

docker exec agent_obs_timescaledb psql -U postgres -d agent_observability << 'EOF'
-- Show current state
SELECT 'BEFORE UPDATE:' as status;
SELECT
    MIN(timestamp) as oldest_trace,
    MAX(timestamp) as newest_trace,
    NOW() as current_time,
    EXTRACT(EPOCH FROM (NOW() - MAX(timestamp)))/86400 as days_since_newest
FROM traces;

-- Update timestamps (unlimited tuple decompression)
SET timescaledb.max_tuples_decompressed_per_dml_transaction = 0;
UPDATE traces SET timestamp = timestamp + INTERVAL '4 days';

-- Show new state
SELECT 'AFTER UPDATE:' as status;
SELECT
    MIN(timestamp) as oldest_trace,
    MAX(timestamp) as newest_trace,
    NOW() as current_time,
    EXTRACT(EPOCH FROM (NOW() - MAX(timestamp)))/3600 as hours_since_newest,
    COUNT(*) as total_traces
FROM traces;
EOF

echo ""
echo "✓ Trace timestamps updated successfully!"
echo ""

# Step 2: Test the agent endpoint
echo "Step 2: Testing agent details endpoint..."
echo "----------------------------------------"

RESPONSE=$(curl -s 'http://localhost:8003/api/v1/performance/agents/engineering-refactor-bot-6?range=7d' \
  -H 'X-Workspace-ID: 37160be9-7d69-43b5-8d5f-9d7b5e14a57a')

if echo "$RESPONSE" | grep -q '"agent_id"'; then
    echo "✓ Agent details endpoint is working!"
    echo ""
    echo "Sample response:"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null | head -20
else
    echo "✗ Agent details endpoint returned an error:"
    echo "$RESPONSE"
    exit 1
fi

echo ""
echo "=========================================="
echo "✓ Agent Details Page Fixed Successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Refresh the agent details page in your browser"
echo "2. Run seed_slo_configs.sql to populate SLO data for Performance page"
echo ""
