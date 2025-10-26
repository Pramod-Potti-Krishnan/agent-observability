# Phase 4 Synthetic Data Generation - Execution Guide

## Overview

This directory contains SQL scripts to generate comprehensive synthetic data for Phase 4 features of the Agent Observability Platform.

**Total Records Generated**: 1,265 records
- 1,000 evaluations
- 5 guardrail rules + 200 violations = 205 records
- 4 alert rules + 50 notifications = 54 records
- 10 business goals

**Time Range**: All data distributed over the last 7 days (except business goals: last 30 days)

---

## Prerequisites

1. **Database Running**: PostgreSQL container must be running
2. **Schema Initialized**: All Phase 4 tables must exist (from init-postgres.sql)
3. **Existing Data**: Phase 1-3 data should exist (workspaces, traces, spans)
4. **Valid Workspace**: A workspace with slug 'dev-workspace' must exist

---

## Execution Order (CRITICAL)

**STEP 1**: Query workspace ID first
```bash
psql -h localhost -p 5433 -U postgres -d agent_observability_metadata -f get-workspace-id.sql
```

**Expected Output**:
```
          workspace_id              |     slug      |      name      |         created_at
------------------------------------+---------------+----------------+----------------------------
 a1b2c3d4-5678-90ab-cdef-1234567890ab | dev-workspace | Dev Workspace  | 2024-01-15 10:30:00+00
```

**STEP 2**: Execute seed scripts in any order (they all auto-query workspace_id)
```bash
# Seed evaluations (1000 records)
psql -h localhost -p 5433 -U postgres -d agent_observability_metadata -f seed-evaluations.sql

# Seed guardrail violations (205 records)
psql -h localhost -p 5433 -U postgres -d agent_observability_metadata -f seed-violations.sql

# Seed alerts (54 records)
psql -h localhost -p 5433 -U postgres -d agent_observability_metadata -f seed-alerts.sql

# Seed business goals (10 records)
psql -h localhost -p 5433 -U postgres -d agent_observability_metadata -f seed-business-goals.sql
```

---

## Alternative Execution (Docker)

If running inside Docker container:

```bash
# Copy SQL files to container
docker cp get-workspace-id.sql agent_obs_postgres:/tmp/
docker cp seed-evaluations.sql agent_obs_postgres:/tmp/
docker cp seed-violations.sql agent_obs_postgres:/tmp/
docker cp seed-alerts.sql agent_obs_postgres:/tmp/
docker cp seed-business-goals.sql agent_obs_postgres:/tmp/

# Execute inside container
docker exec -i agent_obs_postgres psql -U postgres -d agent_observability_metadata -f /tmp/get-workspace-id.sql
docker exec -i agent_obs_postgres psql -U postgres -d agent_observability_metadata -f /tmp/seed-evaluations.sql
docker exec -i agent_obs_postgres psql -U postgres -d agent_observability_metadata -f /tmp/seed-violations.sql
docker exec -i agent_obs_postgres psql -U postgres -d agent_observability_metadata -f /tmp/seed-alerts.sql
docker exec -i agent_obs_postgres psql -U postgres -d agent_observability_metadata -f /tmp/seed-business-goals.sql
```

---

## One-Command Execution

Execute all seed scripts in sequence:

```bash
# Using local psql
for file in get-workspace-id.sql seed-evaluations.sql seed-violations.sql seed-alerts.sql seed-business-goals.sql; do
    echo "Executing $file..."
    psql -h localhost -p 5433 -U postgres -d agent_observability_metadata -f $file
    echo "---"
done
```

```bash
# Using Docker
for file in get-workspace-id.sql seed-evaluations.sql seed-violations.sql seed-alerts.sql seed-business-goals.sql; do
    echo "Executing $file..."
    docker exec -i agent_obs_postgres psql -U postgres -d agent_observability_metadata -f /tmp/$file
    echo "---"
done
```

---

## Verification

After execution, verify data counts:

```sql
-- Connect to database
psql -h localhost -p 5433 -U postgres -d agent_observability_metadata

-- Check all Phase 4 table counts
SELECT
    'evaluations' as table_name,
    COUNT(*) as record_count
FROM evaluations
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')

UNION ALL

SELECT
    'guardrail_rules',
    COUNT(*)
FROM guardrail_rules
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')

UNION ALL

SELECT
    'guardrail_violations',
    COUNT(*)
FROM guardrail_violations
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')

UNION ALL

SELECT
    'alert_rules',
    COUNT(*)
FROM alert_rules
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')

UNION ALL

SELECT
    'alert_notifications',
    COUNT(*)
FROM alert_notifications
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace')

UNION ALL

SELECT
    'business_goals',
    COUNT(*)
FROM business_goals
WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace');
```

**Expected Output**:
```
      table_name       | record_count
-----------------------+--------------
 evaluations           |         1000
 guardrail_rules       |            5
 guardrail_violations  |          200
 alert_rules           |            4
 alert_notifications   |           50
 business_goals        |           10
```

---

## Data Characteristics

### Evaluations (1,000 records)
- **Score Range**: 6.0 - 10.0 (biased toward good quality)
- **Evaluator**: 'gemini' for all records
- **Criteria**: accuracy, relevance, helpfulness, coherence
- **Overall Score**: Average of 4 criteria
- **Reasoning**: 10 different AI-generated explanation templates
- **Time Distribution**: Last 7 days

### Guardrail Rules (5 rules)
1. **PII Email Detection** - High severity, redact action
2. **PII SSN Detection** - Critical severity, block action
3. **Toxicity Content Filter** - Medium severity, flag action
4. **Prompt Injection Detection** - High severity, block action
5. **Credit Card Detection** - Critical severity, redact action

### Guardrail Violations (200 records)
- **Distribution**: 60% PII, 30% toxicity, 10% injection
- **Severity Mix**: 20% critical, 30% high, 50% medium
- **Action Taken**: 'flagged' for all
- **Content**: Realistic detected content with redaction examples
- **Time Distribution**: Last 7 days

### Alert Rules (4 rules)
1. **High Latency Alert** - P99 > 2000ms (high severity)
2. **Error Rate Spike** - Error rate > 5% (critical severity)
3. **Cost Overrun** - Hourly cost > $50 (high severity)
4. **Quality Score Drop** - Quality < 6.0 (medium severity)

### Alert Notifications (50 records)
- **Status Distribution**: 60% resolved, 30% acknowledged, 10% open
- **Notifications Sent**: 90% of alerts
- **Metric Values**: All exceed thresholds to trigger alerts
- **Time Distribution**: Last 7 days

### Business Goals (10 goals)
1. **Reduce Support Tickets** - 75% progress
2. **Improve CSAT Score** - 69% progress
3. **Cost Savings** - 76% progress
4. **Reduce Response Time** - 86% progress
5. **Improve Accuracy** - 80% progress
6. **Increase Automation Rate** - 76% progress
7. **Reduce Error Rate** - 82% progress
8. **Improve First Contact Resolution** - 77% progress
9. **Reduce Average Handle Time** - 78% progress
10. **Improve User Satisfaction** - 78% progress

**Progress Range**: 64% - 97% (showing variety)
**Target Date**: 3 months from execution date
**Status**: All 'in_progress'

---

## Data Reset (Clean Up)

To remove all Phase 4 synthetic data:

```sql
-- Connect to database
psql -h localhost -p 5433 -U postgres -d agent_observability_metadata

-- Delete all Phase 4 data for dev-workspace
WITH workspace AS (
    SELECT id FROM workspaces WHERE slug = 'dev-workspace'
)
DELETE FROM evaluations WHERE workspace_id = (SELECT id FROM workspace);

DELETE FROM guardrail_violations WHERE workspace_id = (SELECT id FROM workspace);
DELETE FROM guardrail_rules WHERE workspace_id = (SELECT id FROM workspace);

DELETE FROM alert_notifications WHERE workspace_id = (SELECT id FROM workspace);
DELETE FROM alert_rules WHERE workspace_id = (SELECT id FROM workspace);

DELETE FROM business_goals WHERE workspace_id = (SELECT id FROM workspace);

-- Verify deletion
SELECT
    (SELECT COUNT(*) FROM evaluations WHERE workspace_id = (SELECT id FROM workspace)) as evaluations,
    (SELECT COUNT(*) FROM guardrail_rules WHERE workspace_id = (SELECT id FROM workspace)) as rules,
    (SELECT COUNT(*) FROM guardrail_violations WHERE workspace_id = (SELECT id FROM workspace)) as violations,
    (SELECT COUNT(*) FROM alert_rules WHERE workspace_id = (SELECT id FROM workspace)) as alert_rules,
    (SELECT COUNT(*) FROM alert_notifications WHERE workspace_id = (SELECT id FROM workspace)) as notifications,
    (SELECT COUNT(*) FROM business_goals WHERE workspace_id = (SELECT id FROM workspace)) as goals;
```

---

## Troubleshooting

### Issue: "workspace_id not found"
**Solution**: Verify workspace exists
```sql
SELECT id, slug, name FROM workspaces WHERE slug = 'dev-workspace';
```
If missing, create workspace first or update slug in seed scripts.

### Issue: "foreign key violation on trace_id"
**Solution**: Ensure Phase 1-3 data exists
```sql
SELECT COUNT(*) FROM traces WHERE workspace_id = (SELECT id FROM workspaces WHERE slug = 'dev-workspace');
```
Should return at least 200 traces for proper data generation.

### Issue: "table does not exist"
**Solution**: Run database initialization first
```bash
psql -h localhost -p 5433 -U postgres -d agent_observability_metadata -f backend/db/init-postgres.sql
```

### Issue: Duplicate key violations
**Solution**: Tables already contain data. Either:
1. Run cleanup script above
2. Modify seed scripts to use `ON CONFLICT DO NOTHING`

---

## Performance Notes

- **Execution Time**: ~30-60 seconds total for all scripts
- **Transaction Safety**: Each script runs in a single transaction
- **Rollback**: If script fails, no partial data is inserted
- **Indexes**: All indexes created automatically with business_goals table

---

## Next Steps After Data Generation

1. **Verify Home Page**: Quality score should now display on dashboard home
2. **Test Quality Page**: Navigate to /dashboard/quality - should show 1000 evaluations
3. **Test Safety Page**: Navigate to /dashboard/safety - should show 200 violations
4. **Test Impact Page**: Navigate to /dashboard/impact - should show 10 business goals
5. **Test Alerts**: Check alert notifications and rules display correctly
6. **API Testing**: Test all Phase 4 API endpoints with generated data

---

## Files in This Directory

| File | Purpose | Records Generated |
|------|---------|-------------------|
| `get-workspace-id.sql` | Query workspace ID | N/A (query only) |
| `seed-evaluations.sql` | Generate evaluation records | 1,000 |
| `seed-violations.sql` | Generate guardrail data | 205 (5 rules + 200 violations) |
| `seed-alerts.sql` | Generate alert data | 54 (4 rules + 50 notifications) |
| `seed-business-goals.sql` | Generate business goals | 10 |
| `README-SYNTHETIC-DATA.md` | This documentation | N/A |

---

## Important Notes

1. **Workspace ID**: All scripts auto-query workspace_id - no manual editing required
2. **Idempotency**: Scripts include `NOT EXISTS` checks to avoid duplicates
3. **Data Quality**: All scores, metrics, and distributions follow realistic patterns
4. **Time Distribution**: Data spread across 7 days for realistic visualization
5. **Foreign Keys**: All records properly linked to existing traces and workspace

---

## Support

For issues or questions:
1. Check verification queries in each SQL file
2. Review troubleshooting section above
3. Verify Phase 1-3 data exists in database
4. Check PostgreSQL logs for detailed error messages

---

**Last Updated**: Phase 4 Implementation (Week 3, Days 11-12)
