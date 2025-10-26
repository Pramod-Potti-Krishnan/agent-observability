---
description: Systematically redeploy backend/frontend changes with verification
---

# Redeploy Changes Command

You are tasked with systematically redeploying code changes to the Agent Observability Platform and verifying they are reflected correctly.

## Context

This system has 8 backend microservices + 1 frontend service running in Docker. Changes often don't appear due to:
- Docker build cache
- Browser cache
- Services not restarted
- Port/workspace configuration issues

## Your Task

Follow this systematic workflow to ensure changes are deployed and verified:

### Phase 1: Identify What Changed

Ask yourself:
1. Which service(s) were modified? (gateway, ingestion, query, cost, evaluation, guardrail, alert, gemini, frontend)
2. Was it backend code or frontend code?
3. Did API response structure change? (If yes, frontend may need rebuild too)

### Phase 2: Rebuild Backend Service(s)

For EACH modified backend service:

```bash
# Step 1: Rebuild with --no-cache (critical!)
docker-compose build --no-cache <service_name>

# Step 2: Restart with --force-recreate
docker-compose up -d --force-recreate --no-deps <service_name>

# Step 3: Verify service started
docker-compose ps <service_name>

# Step 4: Check logs for errors
docker-compose logs --tail=50 <service_name>
```

**Services**: gateway, ingestion, query, cost, evaluation, guardrail, alert, gemini

### Phase 3: Test API Directly

Before testing frontend, verify backend works:

```bash
# Get workspace ID
WORKSPACE_ID="37160be9-7d69-43b5-8d5f-9d7b5e14a57a"

# Test endpoint directly (bypass frontend)
curl -H "X-Workspace-ID: $WORKSPACE_ID" \
  "http://localhost:8000/api/v1/<your-endpoint>" \
  | python3 -m json.tool

# Verify:
# 1. Returns 200 status
# 2. Contains expected data
# 3. Field names match frontend expectations
```

**Common Endpoints**:
- `/api/v1/kpis?range=7d` - Home page KPIs
- `/api/v1/guardrails/violations?range=7d` - Safety violations
- `/api/v1/evaluate/history?range=7d` - Quality evaluations
- `/api/v1/cost/overview?range=7d` - Cost metrics

### Phase 4: Rebuild Frontend (If Needed)

Rebuild frontend if:
- Frontend code changed
- Backend API structure changed
- Field names changed

```bash
# Step 1: Remove old frontend container
docker-compose stop frontend
docker-compose rm -f frontend

# Step 2: Clean .next build directory (inside container)
docker-compose run --rm frontend rm -rf .next

# Step 3: Rebuild with --no-cache
docker-compose build --no-cache frontend

# Step 4: Start frontend
docker-compose up -d frontend

# Step 5: Monitor build logs
docker-compose logs -f frontend
# Wait for: "ready - started server on 0.0.0.0:3000"
# This takes 2-3 minutes
```

### Phase 5: Clear Browser Cache

Critical step often forgotten:

```
# Option 1: Hard Refresh
Mac: Cmd+Shift+R
Windows/Linux: Ctrl+Shift+R

# Option 2: DevTools
1. Open DevTools (F12)
2. Right-click reload → "Empty Cache and Hard Reload"

# Option 3: Incognito Mode
Test in incognito/private window first to confirm caching issue

# Option 4: Force Re-authentication
Navigate to: http://localhost:3000/login
Log in again (forces fresh JavaScript download)
```

### Phase 6: Verify in Browser

1. Navigate to affected dashboard
2. Open browser console (F12)
3. Check for errors:
   - Failed API calls (404, 500)
   - CORS errors
   - JavaScript errors
   - "Invalid Date" errors
   - "Cannot read property" errors

4. Verify data displays correctly:
   - KPI cards show values (not 0 or "—")
   - Charts render with data points
   - Tables populate with rows
   - Time range selector works

### Phase 7: Verify Cross-Page

Test navigation between pages to ensure:
- Data persists across navigation
- No console errors on page transitions
- All dashboards load correctly

**Pages to test**:
- `/dashboard` - Home page
- `/dashboard/usage` - Usage metrics
- `/dashboard/cost` - Cost management
- `/dashboard/performance` - Performance tracking
- `/dashboard/quality` - Quality evaluations
- `/dashboard/safety` - Safety & violations
- `/dashboard/impact` - Business impact

## Common Issues & Solutions

### Issue: "No data available" despite API returning data

**Diagnosis**:
```bash
# Check if workspace ID is correct
curl -H "X-Workspace-ID: 37160be9-7d69-43b5-8d5f-9d7b5e14a57a" \
  "http://localhost:8000/api/v1/<endpoint>"

# NOT: 00000000-0000-0000-0000-000000000000 (wrong workspace)
```

**Solution**: Use correct workspace ID in headers

### Issue: Field name mismatch

**Symptoms**:
```
TypeError: Cannot read property 'created_at' of undefined
RangeError: Invalid Date
```

**Diagnosis**:
```bash
# Check actual API response
curl -H "X-Workspace-ID: <id>" \
  "http://localhost:8000/api/v1/endpoint" | jq '.violations[0]'

# Example output:
{
  "detected_at": "2025-10-22T..."  # ← Field name
}
```

**Solution**: Update frontend TypeScript interface to match:
```typescript
interface Violation {
  detected_at: string  // Not created_at!
}
```

### Issue: Service not restarting

**Diagnosis**:
```bash
# Check container creation time
docker ps --format "table {{.Names}}\t{{.CreatedAt}}"

# If "CreatedAt" is old (before your rebuild), container didn't restart
```

**Solution**:
```bash
# Force remove and recreate
docker-compose stop <service>
docker-compose rm -f <service>
docker-compose up -d <service>
```

### Issue: Port mismatch

**Reference**:
```
Gateway:    localhost:8000 (API entry point)
TimescaleDB: localhost:5432 (traces)
PostgreSQL:  localhost:5433 (metadata, evaluations, rules)
Frontend:    localhost:3000
```

**Common mistake**:
```bash
# ❌ Wrong port
curl "http://localhost:4000/api/v1/endpoint"

# ✅ Correct port
curl "http://localhost:8000/api/v1/endpoint"
```

## Verification Checklist

Before reporting success, verify:

- [ ] Backend service rebuilt with `--no-cache`
- [ ] Backend service restarted with `--force-recreate`
- [ ] Service logs show no errors
- [ ] API returns correct data (tested with curl)
- [ ] Field names match between API and frontend
- [ ] Frontend rebuilt (if API changed)
- [ ] Browser cache cleared (hard refresh)
- [ ] No console errors in browser
- [ ] Data displays correctly in dashboard
- [ ] Navigation between pages works
- [ ] User is logged in (tried /login)

## Reference: Service Architecture

```
┌─────────────┐
│   Browser   │ localhost:3000
│  (Frontend) │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Gateway   │ localhost:8000 (Entry point)
│   (Proxy)   │
└──────┬──────┘
       │
       ├─→ Ingestion (8001)
       ├─→ Query     (8002)  ← Most dashboards
       ├─→ Cost      (8003)
       ├─→ Evaluation(8004)  ← Quality dashboard
       ├─→ Guardrail (8005)  ← Safety dashboard
       ├─→ Alert     (8006)
       └─→ Gemini    (8007)  ← Business Impact
           │
           ▼
    ┌──────────────┬──────────────┐
    │              │              │
    ▼              ▼              ▼
TimescaleDB   PostgreSQL      Redis
(traces)      (metadata)     (cache)
:5432         :5433          :6379
```

## Quick Commands Reference

```bash
# Rebuild backend service
docker-compose build --no-cache <service> && docker-compose up -d --force-recreate --no-deps <service>

# Rebuild frontend
docker-compose build --no-cache frontend && docker-compose up -d --force-recreate --no-deps frontend

# Test API
curl -H "X-Workspace-ID: 37160be9-7d69-43b5-8d5f-9d7b5e14a57a" "http://localhost:8000/api/v1/<endpoint>" | python3 -m json.tool

# Check logs
docker-compose logs --tail=50 <service>

# Check all services
docker-compose ps

# Clean Docker cache
docker builder prune && docker system df
```

## When to Use This Command

Invoke this command whenever:
1. You make backend code changes
2. You make frontend code changes
3. Changes don't appear in the browser
4. Dashboards show stale/missing data
5. After fixing bugs or field name mismatches

## Output Expected

After completing this workflow, provide:

1. **Services Rebuilt**: List which services were rebuilt
2. **API Test Results**: Show curl output confirming API works
3. **Frontend Status**: Confirm frontend rebuilt (if needed)
4. **Verification Results**: List which dashboards were tested and status
5. **Issues Found**: Any errors encountered and how they were resolved

## Example Execution

```
# Changed: backend/query/app/queries.py (home page quality score)

Step 1: Rebuild query service
✓ docker-compose build --no-cache query
✓ docker-compose up -d --force-recreate --no-deps query

Step 2: Test API
✓ curl http://localhost:8000/api/v1/kpis?range=7d
✓ Response contains quality_score: 8.0

Step 3: Rebuild frontend (API structure changed)
✓ docker-compose build --no-cache frontend
✓ docker-compose up -d --force-recreate --no-deps frontend
✓ Waited 2 minutes for build

Step 4: Clear browser cache
✓ Hard refresh (Cmd+Shift+R)
✓ Tested in incognito mode first

Step 5: Verify
✓ Home page displays quality score: 8.0
✓ No console errors
✓ Navigation works correctly

✅ Changes successfully deployed and verified
```

---

**For detailed troubleshooting, refer to**: `docs/TROUBLESHOOTING.md`
