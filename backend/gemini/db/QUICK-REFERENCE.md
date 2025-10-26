# Phase 4 Synthetic Data - Quick Reference Card

## 🚀 Quick Start (30 seconds)

```bash
cd /Users/pk1980/Documents/Software/Agent\ Monitoring/backend/gemini/db
./execute-all-seeds.sh
```

---

## 📊 What Gets Created

| Data Type | Count | Purpose |
|-----------|-------|---------|
| Evaluations | 1,000 | Quality scores (6-10 range) |
| Guardrail Rules | 5 | PII, toxicity, injection detection |
| Violations | 200 | Safety violation examples |
| Alert Rules | 4 | Latency, errors, cost, quality |
| Alert Notifications | 50 | Triggered alerts (60% resolved) |
| Business Goals | 10 | Impact tracking (64-97% progress) |
| **TOTAL** | **1,269** | **Complete Phase 4 dataset** |

---

## 🛠️ Common Commands

### Execute All Seeds
```bash
./execute-all-seeds.sh
```

### Verify Data
```bash
./verify-data.sh
```

### Cleanup/Reset
```bash
./cleanup-data.sh
```

### Manual Execution
```bash
psql -h localhost -p 5433 -U postgres -d agent_observability_metadata -f get-workspace-id.sql
psql -h localhost -p 5433 -U postgres -d agent_observability_metadata -f seed-evaluations.sql
psql -h localhost -p 5433 -U postgres -d agent_observability_metadata -f seed-violations.sql
psql -h localhost -p 5433 -U postgres -d agent_observability_metadata -f seed-alerts.sql
psql -h localhost -p 5433 -U postgres -d agent_observability_metadata -f seed-business-goals.sql
```

---

## ✅ Quick Verification

```sql
-- Connect to database
psql -h localhost -p 5433 -U postgres -d agent_observability_metadata

-- Check counts
WITH workspace AS (SELECT id FROM workspaces WHERE slug = 'dev-workspace')
SELECT
    'evaluations' as table_name, COUNT(*) as count
FROM evaluations WHERE workspace_id = (SELECT id FROM workspace)
UNION ALL
SELECT 'violations', COUNT(*) FROM guardrail_violations WHERE workspace_id = (SELECT id FROM workspace)
UNION ALL
SELECT 'alert_notifications', COUNT(*) FROM alert_notifications WHERE workspace_id = (SELECT id FROM workspace)
UNION ALL
SELECT 'business_goals', COUNT(*) FROM business_goals WHERE workspace_id = (SELECT id FROM workspace);
```

**Expected Output**:
```
table_name          | count
--------------------+-------
evaluations         | 1000
violations          | 200
alert_notifications | 50
business_goals      | 10
```

---

## 📁 File Reference

| File | Purpose | Records |
|------|---------|---------|
| `get-workspace-id.sql` | Query workspace ID | N/A |
| `seed-evaluations.sql` | AI quality evaluations | 1,000 |
| `seed-violations.sql` | Safety violations | 205 |
| `seed-alerts.sql` | Alert notifications | 54 |
| `seed-business-goals.sql` | Business goals | 10 |
| `execute-all-seeds.sh` | Run all seeds | ALL |
| `verify-data.sh` | Verify data | N/A |
| `cleanup-data.sh` | Reset data | N/A |

---

## 🎯 Dashboard Impact

| Dashboard | Data Used | Endpoint |
|-----------|-----------|----------|
| **Quality** (`/dashboard/quality`) | 1,000 evaluations | `/api/v1/evaluate/history` |
| **Safety** (`/dashboard/safety`) | 200 violations + 5 rules | `/api/v1/guardrails/violations` |
| **Impact** (`/dashboard/impact`) | 10 business goals | `/api/v1/business-goals` |
| **Home** (`/dashboard`) | All data | Multiple endpoints |

---

## 🔧 Troubleshooting

| Error | Solution |
|-------|----------|
| "workspace_id not found" | Verify workspace exists: `SELECT * FROM workspaces WHERE slug = 'dev-workspace';` |
| "foreign key violation" | Ensure Phase 1-3 data exists (traces, spans) |
| "table does not exist" | Run `init-postgres.sql` first |
| Duplicate key violations | Run `./cleanup-data.sh` first |

---

## 📈 Data Characteristics

### Evaluations
- **Scores**: 6.0 - 10.0 (good quality bias)
- **Time**: Last 7 days
- **Evaluator**: 'gemini'

### Violations
- **Types**: 60% PII, 30% toxicity, 10% injection
- **Severity**: 20% critical, 30% high, 50% medium
- **Time**: Last 7 days

### Alerts
- **Status**: 60% resolved, 30% ack, 10% open
- **Metrics**: All exceed thresholds
- **Time**: Last 7 days

### Goals
- **Progress**: 64-97% range
- **Status**: All 'in_progress'
- **Target**: 3 months out

---

## 🚨 Important Notes

1. **Always query workspace_id first** - Scripts auto-query, no manual editing
2. **Idempotent** - Safe to run multiple times (rules won't duplicate)
3. **Foreign keys** - All data properly linked to existing traces
4. **Transaction safe** - Rollback on error, no partial data
5. **No Phase 1-3 impact** - Only adds Phase 4 data

---

## 📚 Full Documentation

- **Detailed Guide**: `README-SYNTHETIC-DATA.md`
- **Complete Summary**: `../PHASE4-DATA-SUMMARY.md`
- **This Quick Reference**: `QUICK-REFERENCE.md`

---

## ⏱️ Execution Time

- **Total**: ~30-60 seconds
- **Per script**: 1-15 seconds each
- **Verification**: ~10 seconds

---

## 🎉 Success Indicators

After execution, verify:

1. ✅ Home page shows quality_score metric
2. ✅ Quality dashboard displays 1,000 evaluations
3. ✅ Safety dashboard shows 200 violations
4. ✅ Impact dashboard displays 10 goals
5. ✅ All Phase 4 API endpoints return data

---

**Last Updated**: October 22, 2024
**Version**: 1.0
**Status**: Production Ready ✅
