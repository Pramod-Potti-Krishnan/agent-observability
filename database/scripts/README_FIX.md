# Agent Details Page Fix - README

## Problem Summary

The agent details page was showing 404 errors when accessed from the Quality or Performance tabs due to:

1. **Stale trace data**: Traces dated Sept 30 - Oct 27 (4+ days old), but queries look for data in "past 7 days"
2. **Missing SLO configs**: No SLO configurations in the database, causing Performance page charts to show "No Data"

## Solution

This directory contains scripts to fix both issues:

### Quick Fix (Recommended)

Run the complete fix script:

```bash
cd /Users/pk1980/Documents/Software/Agent\ Monitoring
./database/scripts/complete_fix.sh
```

This script will:
1. ✅ Update all trace timestamps to recent dates (within past 7 days)
2. ✅ Create SLO configurations for top 15 agents
3. ✅ Test all endpoints to verify fixes
4. ✅ Provide a summary and next steps

### Manual Fix (Alternative)

If you prefer to run each step manually:

#### Step 1: Update Trace Timestamps

```bash
cd /Users/pk1980/Documents/Software/Agent\ Monitoring

docker exec agent_obs_timescaledb psql -U postgres -d agent_observability << 'EOF'
SET timescaledb.max_tuples_decompressed_per_dml_transaction = 0;
UPDATE traces SET timestamp = timestamp + INTERVAL '4 days';
EOF
```

#### Step 2: Create SLO Configurations

```bash
docker exec agent_obs_postgres psql -U postgres -d agent_observability_metadata \
  < database/scripts/seed_slo_configs.sql
```

#### Step 3: Test Endpoints

```bash
# Get workspace ID
WORKSPACE_ID=$(docker exec agent_obs_postgres psql -U postgres -d agent_observability_metadata -t -c "SELECT workspace_id FROM evaluations LIMIT 1;" | xargs)

# Test agent details endpoint
curl "http://localhost:8003/api/v1/performance/agents/engineering-refactor-bot-6?range=7d" \
  -H "X-Workspace-ID: $WORKSPACE_ID"

# Test SLO compliance endpoint
curl "http://localhost:8003/api/v1/performance/slo-compliance?range=7d" \
  -H "X-Workspace-ID: $WORKSPACE_ID"
```

## What Gets Fixed

### 1. Agent Details Page 404 Error
**Before**: "Failed to Load Agent Details - Unable to fetch data for agent engineering-refactor-bot-6"

**After**: Agent details page loads successfully showing:
- Performance metrics (P50, P95, P99 latency)
- Error rates and success rates
- Recent traces
- Quality metrics and evaluations

### 2. Performance Page Missing Charts
**Before**: "No SLO Data" message on Performance page

**After**: SLO Compliance Tracker shows:
- 15 agents with SLO configurations
- Compliance status for each agent
- Target vs actual metrics
- Overall compliance rate

## Files Created

| File | Purpose |
|------|---------|
| `complete_fix.sh` | One-click fix for both issues |
| `fix_agent_details_page.sh` | Fixes only the timestamp issue |
| `update_trace_timestamps.sql` | SQL script to update timestamps |
| `seed_slo_configs.sql` | Creates SLO configurations for agents |
| `README_FIX.md` | This documentation |

## Troubleshooting

### Docker Not Running

If you see: `Cannot connect to the Docker daemon`

**Solution:**
```bash
cd /Users/pk1980/Documents/Software/Agent\ Monitoring
docker-compose up -d
# Wait 10 seconds for services to start
./database/scripts/complete_fix.sh
```

### Still Seeing 404 Errors After Fix

1. **Check trace timestamps were updated:**
   ```bash
   docker exec agent_obs_timescaledb psql -U postgres -d agent_observability \
     -c "SELECT MAX(timestamp), NOW() FROM traces;"
   ```
   The max timestamp should be within the past 4 hours.

2. **Verify workspace ID:**
   ```bash
   docker exec agent_obs_postgres psql -U postgres -d agent_observability_metadata \
     -c "SELECT DISTINCT workspace_id FROM evaluations;"
   ```

3. **Hard refresh browser:** Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows/Linux)

### SLO Compliance Still Shows "No Data"

1. **Check SLO configs were created:**
   ```bash
   docker exec agent_obs_postgres psql -U postgres -d agent_observability_metadata \
     -c "SELECT COUNT(*) FROM slo_configs WHERE is_active = true;"
   ```
   Should return at least 10-15 records.

2. **Restart query service:**
   ```bash
   docker-compose restart query
   sleep 5
   ```

## Technical Details

### Timestamp Update Strategy

The script shifts all trace timestamps forward by 4 days, making:
- **Old range**: Sept 30 - Oct 27, 2025
- **New range**: Oct 4 - Oct 31, 2025

This ensures traces fall within any "past 7d" or "past 30d" query window.

### SLO Configuration Strategy

For each agent, the script:
1. Calculates actual P50/P90/P95/P99 latency from traces
2. Sets SLO targets at 120% of actual values (20% buffer)
3. Sets error rate target at 150% of actual rate (50% buffer, minimum 1%)
4. Enables alerts for SLO violations

This creates realistic SLOs that most agents comply with, while still identifying underperformers.

## Support

If you encounter issues not covered here:

1. Check Docker container logs:
   ```bash
   docker logs agent_obs_query --tail 50
   docker logs agent_obs_timescaledb --tail 50
   ```

2. Verify all services are healthy:
   ```bash
   docker ps --format "{{.Names}}\t{{.Status}}"
   ```

3. Review the error messages in browser console (F12)

---

**Last Updated**: 2025-10-31
**Version**: 1.0
**Status**: Ready to run
