# Troubleshooting Guide - Agent Observability Platform

## Overview

This guide documents common issues encountered during development and deployment, along with systematic debugging approaches. It is based on real learnings from Phase 4 implementation.

---

## Table of Contents

1. [Backend Changes Not Reflecting in Frontend](#backend-changes-not-reflecting-in-frontend)
2. [Field Name Mismatches](#field-name-mismatches)
3. [Docker Build Cache Issues](#docker-build-cache-issues)
4. [Browser Cache Problems](#browser-cache-problems)
5. [Port Configuration Mismatches](#port-configuration-mismatches)
6. [Workspace ID Issues](#workspace-id-issues)
7. [Service Health Verification](#service-health-verification)
8. [Database Cross-References](#database-cross-references)
9. [Authentication & Session Issues](#authentication--session-issues)
10. [Systematic Debugging Workflow](#systematic-debugging-workflow)

---

## 1. Backend Changes Not Reflecting in Frontend

### Symptoms
- Frontend displays old or missing data
- API returns correct data when tested directly (curl/Postman)
- Dashboard shows "No data available" or stale values

### Root Causes
1. Service not rebuilt after code changes
2. Docker container using cached layers
3. Service not restarted after rebuild
4. Browser caching old JavaScript/API responses
5. User not logged in or session expired

### Solution Checklist

#### Step 1: Verify Backend Changes Were Made
```bash
# Check that your file changes are actually saved
cat backend/<service>/app/<file>.py | grep "your_change"
```

#### Step 2: Rebuild Backend Service
```bash
# Rebuild with --no-cache to avoid stale layers
cd /path/to/project
docker-compose build --no-cache <service_name>

# For example:
docker-compose build --no-cache query
docker-compose build --no-cache guardrail
```

#### Step 3: Restart the Service
```bash
# Force recreate to ensure new container
docker-compose up -d --force-recreate --no-deps <service_name>

# Verify it's running
docker-compose ps <service_name>

# Check logs for errors
docker-compose logs --tail=50 <service_name>
```

#### Step 4: Rebuild Frontend (if API structure changed)
```bash
# Frontend needs rebuild if backend API response structure changed
docker-compose build --no-cache frontend
docker-compose up -d --force-recreate --no-deps frontend

# Wait for build to complete (can take 2-3 minutes)
docker-compose logs -f frontend
```

#### Step 5: Clear Browser Cache
```bash
# Hard refresh in browser
# Chrome/Safari: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows/Linux)
# Or clear all browsing data for localhost

# If still not working, try incognito/private mode
# If that works, your regular browser has aggressive caching
```

#### Step 6: Re-authenticate
```bash
# Navigate to http://localhost:3000/login
# Log in with test credentials
# This forces fresh session and JavaScript download
```

---

## 2. Field Name Mismatches

### Symptoms
- Frontend crashes with "Cannot read property of undefined"
- Console shows "Invalid Date" or type errors
- API returns data but frontend can't display it

### Root Cause
Backend API returns different field names than frontend expects.

### Example Case: Safety Dashboard
**Problem**: Backend returned `detected_at`, frontend expected `created_at`

**Symptoms**:
```
RangeError: Invalid Date
  at getRelativeTime (ViolationTable.tsx:36)
  at ViolationTable.tsx:130
```

**Solution**:
1. Check API response structure:
```bash
curl -H "X-Workspace-ID: <workspace_id>" \
  "http://localhost:8000/api/v1/guardrails/violations?range=7d&limit=2" \
  | python3 -m json.tool
```

2. Compare with frontend TypeScript interface:
```typescript
// Frontend expects:
interface Violation {
  detected_at: string  // Must match API field name!
}
```

3. Fix ALL references (not just interface):
```bash
# Search for all occurrences
grep -r "created_at" frontend/app/dashboard/safety/
grep -r "created_at" frontend/components/safety/

# Fix each file
# Don't forget: interface definitions, function calls, JSX rendering
```

### Prevention
- Always check API response before writing frontend code
- Use TypeScript strictly (`strict: true` in tsconfig.json)
- Create shared type definitions if possible

---

## 3. Docker Build Cache Issues

### Symptoms
- Code changes not appearing after rebuild
- Old error messages still showing
- Buildkit shows "CACHED" for all steps

### Root Cause
Docker reuses layers from previous builds if it thinks files haven't changed.

### Solution

#### Always Use --no-cache for Code Changes
```bash
# DON'T do this for code changes:
docker-compose build frontend  # ❌ May use cache

# DO this instead:
docker-compose build --no-cache frontend  # ✅ Fresh build
```

#### Clean Docker Cache Periodically
```bash
# View cache usage
docker system df

# Clean build cache
docker builder prune

# Nuclear option (removes ALL unused data)
docker system prune -a
# WARNING: This removes stopped containers, unused networks, dangling images
```

#### Verify New Container Is Running
```bash
# Check container creation time
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}"

# If CreatedAt is old, container didn't actually restart
```

---

## 4. Browser Cache Problems

### Symptoms
- API returns new data (verified with curl)
- Hard refresh doesn't help
- Incognito mode shows correct data

### Root Cause
Modern browsers aggressively cache:
- JavaScript bundles
- API responses
- Static assets

### Solutions

#### Level 1: Hard Refresh
```bash
# Chrome/Safari (Mac): Cmd+Shift+R
# Chrome/Safari (Windows): Ctrl+Shift+R
# Firefox: Ctrl+F5
```

#### Level 2: Clear Site Data
```bash
# Chrome DevTools
1. Open DevTools (F12)
2. Right-click reload button → "Empty Cache and Hard Reload"

# Safari
1. Develop menu → Empty Caches
2. Or: Safari → Clear History → All History
```

#### Level 3: Incognito/Private Mode
```bash
# Test in incognito to confirm caching issue
# If it works in incognito, it's definitely browser cache
```

#### Level 4: Force Re-authentication
```bash
# Navigate to /login and log in again
# This forces browser to download fresh JavaScript
http://localhost:3000/login
```

#### Level 5: Different Browser
```bash
# Test in a browser you don't normally use
# If it works, confirms cache issue in original browser
```

### Prevention
```javascript
// Add cache-busting headers in backend
headers: {
  'Cache-Control': 'no-store, must-revalidate',
  'Pragma': 'no-cache'
}

// Or use versioned API endpoints
/api/v2/... instead of /api/v1/...
```

---

## 5. Port Configuration Mismatches

### Symptoms
- Connection refused errors
- "Database does not exist" despite it existing
- Service can't reach another service

### Root Cause
Confusion between:
- Docker internal ports (service-to-service)
- Host mapped ports (localhost access)
- Different databases on different ports

### Port Map Reference

#### From docker-compose.yml:
```yaml
Services:
  timescaledb:   5432:5432  → localhost:5432  (traces, time-series)
  postgres:      5433:5432  → localhost:5433  (metadata, evaluations, rules)
  redis:         6379:6379  → localhost:6379
  gateway:       8000:8000  → localhost:8000  (API Gateway)
  ingestion:     8001:8001  → localhost:8001
  query:         8002:8002  → localhost:8002
  cost:          8003:8003  → localhost:8003
  evaluation:    8004:8004  → localhost:8004
  guardrail:     8005:8005  → localhost:8005
  alert:         8006:8006  → localhost:8006
  gemini:        8007:8007  → localhost:8007
  frontend:      3000:3000  → localhost:3000
```

#### Database Connections

**From Host Machine (Python scripts, psql):**
```bash
# TimescaleDB (traces)
postgresql://postgres:postgres@localhost:5432/agent_observability

# PostgreSQL (metadata)
postgresql://postgres:postgres@localhost:5433/agent_observability_metadata
```

**From Docker Containers (backend services):**
```bash
# TimescaleDB (traces)
postgresql://postgres:postgres@timescaledb:5432/agent_observability

# PostgreSQL (metadata)
postgresql://postgres:postgres@postgres:5432/agent_observability_metadata

# Note: Use container name, and internal port (always 5432)
```

### Verification

#### Test Gateway Port
```bash
# Should be 8000, not 4000 or other
curl http://localhost:8000/health

# Common mistake: testing on wrong port
curl http://localhost:4000/health  # ❌ Wrong port
```

#### Test Database Connections
```bash
# TimescaleDB
docker-compose exec timescaledb psql -U postgres -d agent_observability -c "SELECT COUNT(*) FROM traces;"

# PostgreSQL
docker-compose exec postgres psql -U postgres -d agent_observability_metadata -c "SELECT COUNT(*) FROM evaluations;"
```

---

## 6. Workspace ID Issues

### Symptoms
- API returns empty array `{violations: [], total_count: 0}`
- Data exists in database but doesn't show in dashboard
- Different user sees different data

### Root Cause
Multi-tenancy: All queries are scoped by workspace_id

### Solution

#### Get Correct Workspace ID
```sql
-- Connect to PostgreSQL metadata database
docker-compose exec postgres psql -U postgres -d agent_observability_metadata

-- Find your workspace
SELECT id, slug, name FROM workspaces WHERE slug = 'dev-workspace';

-- Example output:
--              id                  |    slug       |      name
-- ----------------------------------+---------------+----------------
--  37160be9-7d69-43b5-8d5f-9d7b5e14a57a | dev-workspace | Development Workspace
```

#### Verify Data Exists for Workspace
```sql
-- Check traces
SELECT COUNT(*) FROM traces
WHERE workspace_id = '37160be9-7d69-43b5-8d5f-9d7b5e14a57a';

-- Check evaluations
SELECT COUNT(*) FROM evaluations
WHERE workspace_id = '37160be9-7d69-43b5-8d5f-9d7b5e14a57a';
```

#### Use Correct Header in API Calls
```bash
# Include X-Workspace-ID header
curl -H "X-Workspace-ID: 37160be9-7d69-43b5-8d5f-9d7b5e14a57a" \
  "http://localhost:8000/api/v1/guardrails/violations"

# NOT generic 00000000-0000-0000-0000-000000000000
```

#### Common Mistake in Seed Scripts
```sql
-- ❌ WRONG: Using placeholder
DECLARE
    workspace_id UUID := '00000000-0000-0000-0000-000000000000';

-- ✅ CORRECT: Query actual workspace
DECLARE
    workspace_id UUID;
BEGIN
    SELECT id INTO workspace_id FROM workspaces WHERE slug = 'dev-workspace';
```

---

## 7. Service Health Verification

### Quick Health Check
```bash
# Check all services
docker-compose ps

# Check specific service
docker-compose ps query

# View logs
docker-compose logs --tail=50 query

# Follow logs in real-time
docker-compose logs -f query
```

### Service-Specific Checks

#### Gateway
```bash
curl http://localhost:8000/health
# Expected: {"status": "healthy", "service": "gateway", "version": "1.0.0"}
```

#### Query Service
```bash
curl -H "X-Workspace-ID: <workspace_id>" \
  "http://localhost:8002/api/v1/kpis?range=7d"
```

#### Frontend
```bash
# Check if Next.js dev server is running
curl http://localhost:3000
# Should return HTML (not connection refused)
```

### Common Service Issues

#### Service Not Running
```bash
# Symptom
docker-compose ps query
# Status: Exit 1

# Solution
docker-compose logs query  # Check error
docker-compose up -d query  # Restart
```

#### Service Running But Not Healthy
```bash
# Symptom
curl http://localhost:8002/health
# Connection refused

# Possible causes:
# 1. Wrong port
# 2. Service crashed on startup
# 3. Dependency (DB/Redis) not available

# Check logs
docker-compose logs --tail=100 query
```

---

## 8. Database Cross-References

### Two Database Architecture

This system uses TWO separate databases:

**TimescaleDB (`agent_observability`)** - localhost:5432
- `traces` - All trace/span data (time-series)
- Optimized for time-series queries
- Partitioned by time

**PostgreSQL (`agent_observability_metadata`)** - localhost:5433
- `workspaces` - Tenant isolation
- `users` - Authentication
- `evaluations` - Quality scores
- `guardrail_rules` - Safety rules
- `guardrail_violations` - Detected violations
- `alert_rules` - Alerting configuration
- `alert_notifications` - Alert history

### Cross-Database Operations

#### Problem: Joining Data Across Databases
You cannot use SQL JOIN across different database connections.

**Example**: Getting evaluations for traces requires:
1. Query traces from TimescaleDB
2. Query evaluations from PostgreSQL
3. Join in application code OR use LEFT JOIN in queries.py

**Solution in queries.py** (backend/query/app/queries.py):
```python
query = """
WITH current_period AS (
    SELECT
        COUNT(DISTINCT t.id) as total_requests,
        AVG(e.overall_score) as avg_quality_score  -- ← Join evaluations
    FROM traces t
    LEFT JOIN evaluations e ON t.trace_id = e.trace_id
        AND t.workspace_id = e.workspace_id  -- ← Important: join on workspace too
    WHERE t.workspace_id = $1
)
```

**Note**: The evaluations table must be in the SAME database as traces for this to work. In our architecture, we use FDW (Foreign Data Wrapper) or the query service handles the join.

### Synthetic Data Generation

When generating test data:

**❌ WRONG: Single database script**
```sql
-- This FAILS because traces is in different database
INSERT INTO evaluations (trace_id, ...)
SELECT trace_id FROM traces WHERE workspace_id = ...;
```

**✅ CORRECT: Python script connecting to both**
```python
# Connect to TimescaleDB for traces
traces_conn = psycopg2.connect("postgresql://...@localhost:5432/agent_observability")
trace_ids = fetch_trace_ids(traces_conn)

# Connect to PostgreSQL for evaluations
eval_conn = psycopg2.connect("postgresql://...@localhost:5433/agent_observability_metadata")
insert_evaluations(eval_conn, trace_ids)
```

---

## 9. Authentication & Session Issues

### Symptom
- User sees "Please log in" despite being on dashboard
- API returns 401 Unauthorized
- Dashboards show "No data"

### Root Causes
1. JWT token expired (default: 24 hours)
2. Cookie cleared or blocked
3. Browser security settings

### Solution

#### Force Fresh Login
```bash
# Navigate to login page
http://localhost:3000/login

# This forces:
# - New JWT token
# - Fresh JavaScript download
# - New session cookies
```

#### Check JWT in DevTools
```javascript
// Open browser console
document.cookie
// Look for: token=eyJ...

// If missing, user needs to log in
```

#### Backend Token Verification
```bash
# Check if backend accepts token
curl -H "Authorization: Bearer <your_jwt_token>" \
  http://localhost:8000/api/v1/workspaces
```

---

## 10. Systematic Debugging Workflow

### When Changes Don't Appear

Follow this checklist in order:

#### 1. Verify Code Changes Saved
```bash
# Check your changes are in the file
cat backend/query/app/queries.py | grep "your_change"
```

#### 2. Rebuild Backend Service
```bash
docker-compose build --no-cache <service>
docker-compose up -d --force-recreate --no-deps <service>
```

#### 3. Check Service Logs
```bash
docker-compose logs --tail=50 <service>
# Look for:
# - Startup errors
# - Import errors
# - Database connection errors
```

#### 4. Test API Directly
```bash
# Bypass frontend, test backend directly
curl -H "X-Workspace-ID: <workspace_id>" \
  "http://localhost:8000/api/v1/<endpoint>"
```

#### 5. If API Works, Rebuild Frontend
```bash
docker-compose build --no-cache frontend
docker-compose up -d --force-recreate --no-deps frontend

# Wait for build (2-3 min)
docker-compose logs -f frontend
```

#### 6. Clear Browser Cache
```bash
# Hard refresh: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)
# Or try incognito mode
```

#### 7. Force Re-authentication
```bash
# Go to login page
http://localhost:3000/login
# Log in again
```

#### 8. Check Browser Console
```bash
# F12 → Console tab
# Look for:
# - Failed API calls (404, 500)
# - CORS errors
# - JavaScript errors
```

---

## Common Error Patterns

### "Invalid Date" Errors

**Symptom**:
```
RangeError: Invalid Date
  at new Date()
```

**Causes**:
1. Field name mismatch (frontend expects `created_at`, API returns `detected_at`)
2. Null/undefined date value
3. Invalid date format

**Solution**:
```typescript
// Add null checks
if (!violation.detected_at) return

// Add try-catch for date parsing
try {
  const date = new Date(violation.detected_at)
} catch (e) {
  console.warn('Invalid date:', violation.detected_at)
  return
}
```

### "Cannot read property of undefined"

**Symptom**:
```
TypeError: Cannot read property 'overall_score' of undefined
```

**Causes**:
1. API returned different structure than expected
2. Data is null/undefined
3. Field name mismatch

**Solution**:
```typescript
// Use optional chaining and nullish coalescing
const score = data?.evaluations?.[0]?.overall_score ?? 0

// Or check before accessing
if (!data || !data.evaluations || data.evaluations.length === 0) {
  return <EmptyState />
}
```

### Database Connection Errors

**Symptom**:
```
psycopg2.OperationalError: database "agent_observability" does not exist
```

**Causes**:
1. Wrong port (5433 instead of 5432 or vice versa)
2. Wrong database name
3. Database not initialized

**Solution**:
```bash
# List databases
docker-compose exec timescaledb psql -U postgres -c "\l"
docker-compose exec postgres psql -U postgres -c "\l"

# Check correct ports in docker-compose.yml
# TimescaleDB: 5432:5432
# PostgreSQL: 5433:5432
```

---

## Prevention Best Practices

### 1. Always Use --no-cache for Code Changes
```bash
# Make it a habit
alias dcb='docker-compose build --no-cache'
alias dcr='docker-compose up -d --force-recreate --no-deps'
```

### 2. Test API Before Testing Frontend
```bash
# Catch backend issues early
curl -H "X-Workspace-ID: <id>" "http://localhost:8000/api/v1/endpoint" | jq
```

### 3. Check Field Names Match
```bash
# API returns
{
  "detected_at": "2025-10-22T..."
}

# Frontend expects
interface Violation {
  detected_at: string  // ✅ Match!
}
```

### 4. Use Strict TypeScript
```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "strictNullChecks": true
  }
}
```

### 5. Log Generously During Development
```python
# Backend
logger.info(f"Received workspace_id: {workspace_id}")
logger.info(f"Found {len(violations)} violations")

# Frontend
console.log('API response:', data)
console.log('Violations count:', data.violations?.length)
```

---

## Quick Reference Commands

```bash
# Rebuild and restart service
docker-compose build --no-cache <service> && docker-compose up -d --force-recreate --no-deps <service>

# Check service health
docker-compose ps && docker-compose logs --tail=50 <service>

# Test API
curl -H "X-Workspace-ID: 37160be9-7d69-43b5-8d5f-9d7b5e14a57a" "http://localhost:8000/api/v1/<endpoint>" | python3 -m json.tool

# Check database
docker-compose exec postgres psql -U postgres -d agent_observability_metadata -c "SELECT COUNT(*) FROM evaluations;"

# Clean Docker cache
docker builder prune && docker system df

# Force fresh frontend
docker-compose build --no-cache frontend && docker-compose up -d --force-recreate --no-deps frontend

# Re-authenticate
# Navigate to: http://localhost:3000/login
```

---

## When All Else Fails

### Nuclear Option: Full Restart
```bash
# Stop everything
docker-compose down

# Clean cache
docker system prune -a

# Rebuild everything
docker-compose build --no-cache

# Start everything
docker-compose up -d

# Check health
docker-compose ps
```

### Ask for Help With Context
When reporting issues, include:
1. What you changed (file + line numbers)
2. What you expected to happen
3. What actually happened
4. Relevant logs (`docker-compose logs <service>`)
5. API response (`curl` output)
6. Browser console errors (screenshots)
7. Steps you already tried

---

## 11. Missing X-Workspace-ID Header in API Calls

### Symptoms
- Dashboard displays all zeros (0.0%) despite other pages showing data correctly
- API returns 422 Unprocessable Entity error
- Browser console shows: `{type: "missing", loc: ["header", "X-Workspace-ID"], msg: "Field required"}`
- curl tests with workspace header work fine, but frontend doesn't

### Root Cause
Frontend code missing explicit `X-Workspace-ID` header in API request and `enabled` guard to prevent query before user data loads.

### Example Case: Home Dashboard Showing Zeros

**Problem**: Home dashboard (`/dashboard/page.tsx`) showed 0.0% for all KPIs while other dashboards (usage, cost, performance) displayed correct data.

**Difference Between Working and Non-Working Pages**:

**Working Page Pattern** (frontend/app/dashboard/usage/page.tsx):
```typescript
const { data: overview, isLoading, error } = useQuery({
  queryKey: ['usage-overview', timeRange],
  queryFn: async () => {
    const response = await apiClient.get(`/api/v1/usage/overview?range=${timeRange}`, {
      headers: { 'X-Workspace-ID': user?.workspace_id }  // ✅ Explicit header
    })
    return response.data as UsageOverview
  },
  enabled: !!user?.workspace_id,  // ✅ Guard prevents query before user loads
  refetchInterval: 30000,
})
```

**Non-Working Pattern** (frontend/app/dashboard/page.tsx - BEFORE FIX):
```typescript
const { data: kpis, isLoading } = useQuery({
  queryKey: ['home-kpis', timeRange],
  queryFn: async () => {
    const response = await apiClient.get(`/api/v1/metrics/home-kpis?range=${timeRange}`)
    // ❌ Missing explicit header
    // ❌ Missing enabled guard
    return response.data as HomeKPIs
  },
  refetchInterval: 300000,
})
```

### Why This Happened

The api-client.ts interceptor adds workspace header from localStorage:
```typescript
// frontend/lib/api-client.ts
apiClient.interceptors.request.use((config) => {
  const workspaceId = localStorage.getItem('workspace_id')
  if (workspaceId) {
    config.headers['X-Workspace-ID'] = workspaceId
  }
  return config
})
```

**However**, when the page first loads:
1. User data hasn't loaded yet (`user` is null)
2. localStorage might not have workspace_id yet
3. Query runs immediately without workspace header
4. Backend rejects request with 422 error

### Solution

**Step 1**: Add explicit header from user context
```typescript
headers: { 'X-Workspace-ID': user?.workspace_id }
```

**Step 2**: Add enabled guard
```typescript
enabled: !!user?.workspace_id,  // Don't query until user loads
```

**Complete Fix** (frontend/app/dashboard/page.tsx):
```typescript
const { user } = useAuth()
const [timeRange, setTimeRange] = useState('7d')

const { data: kpis, isLoading } = useQuery({
  queryKey: ['home-kpis', timeRange],
  queryFn: async () => {
    const response = await apiClient.get(`/api/v1/metrics/home-kpis?range=${timeRange}`, {
      headers: { 'X-Workspace-ID': user?.workspace_id }  // ✅ Added
    })
    return response.data as HomeKPIs
  },
  enabled: !!user?.workspace_id,  // ✅ Added
  refetchInterval: 300000,
})
```

### Verification

**Test API directly**:
```bash
# Should return data
curl -H "X-Workspace-ID: 37160be9-7d69-43b5-8d5f-9d7b5e14a57a" \
  "http://localhost:8000/api/v1/metrics/home-kpis?range=7d" | python3 -m json.tool

# Should return 422 error
curl "http://localhost:8000/api/v1/metrics/home-kpis?range=7d"
```

**Check browser console**:
```javascript
// Before fix: 422 error with missing header
// After fix: 200 response with data
```

### Prevention

**Always use this pattern** for any API call that requires workspace scoping:

```typescript
// Template for workspace-scoped queries
const { user } = useAuth()

const { data, isLoading, error } = useQuery({
  queryKey: ['your-key', timeRange],
  queryFn: async () => {
    const response = await apiClient.get('/api/v1/your-endpoint', {
      headers: { 'X-Workspace-ID': user?.workspace_id }  // Required
    })
    return response.data
  },
  enabled: !!user?.workspace_id,  // Required
  refetchInterval: 60000,
})
```

**Checklist for new dashboard pages**:
- [ ] Import `useAuth` hook
- [ ] Get `user` from auth context
- [ ] Add explicit `X-Workspace-ID` header to all API calls
- [ ] Add `enabled: !!user?.workspace_id` to prevent premature queries
- [ ] Test in browser with network tab open to verify header is sent

---

## 12. Missing Backend Services After Restart

### Symptoms
- All pages show "No data available" or loading states
- Browser console shows connection errors to backend ports
- Frontend loads but no API calls succeed
- docker-compose ps shows only infrastructure (postgres, redis, timescaledb, gateway, frontend)

### Root Cause
Backend service containers (query, ingestion, processing, evaluation, guardrail, alert, gemini) stopped and weren't restarted with `docker-compose up -d`.

### Example Case: Complete Dashboard Failure

**Problem**: After multiple rebuilds and restarts, user reported "none of the dashboards are working".

**Investigation**:
```bash
# Check running containers
docker-compose ps

# Output showed ONLY:
# - timescaledb
# - postgres
# - redis
# - gateway
# - frontend

# Missing:
# - query (critical for dashboard data)
# - ingestion
# - processing
# - evaluation
# - guardrail
# - alert
# - gemini
```

**Why This Happened**:

Using `docker-compose up -d --force-recreate --no-deps <service>` with `--no-deps` flag only restarts THAT specific service without checking dependencies. If services weren't running before, they won't start automatically.

### Solution

**Step 1**: Start all core backend services
```bash
cd /path/to/project
docker-compose up -d ingestion processing query
```

**Step 2**: Start Phase 4 services
```bash
docker-compose up -d evaluation guardrail alert gemini
```

**Step 3**: Verify all services running
```bash
docker-compose ps

# Should show ALL 12 containers:
# - timescaledb (healthy)
# - postgres (healthy)
# - redis (healthy)
# - gateway
# - ingestion
# - processing
# - query
# - frontend
# - evaluation
# - guardrail
# - alert
# - gemini
```

**Step 4**: Check service health
```bash
# Gateway should proxy to query service
curl -H "X-Workspace-ID: <workspace_id>" \
  "http://localhost:8000/api/v1/metrics/home-kpis?range=7d"

# Should return actual data, not errors
```

### Complete Service Architecture

**Infrastructure Layer** (always running):
```yaml
timescaledb:   5432:5432  (traces database)
postgres:      5433:5432  (metadata database)
redis:         6379:6379  (cache & pub/sub)
```

**Core Backend Services** (required for dashboards):
```yaml
gateway:       8000:8000  (API Gateway - proxies all requests)
ingestion:     8001:8001  (Ingests trace data)
processing:    N/A        (Background processing)
query:         8003:8003  (Dashboard data queries) ← CRITICAL
```

**Phase 4 Services** (advanced features):
```yaml
evaluation:    8004:8004  (Quality evaluations)
guardrail:     8005:8005  (Safety violations)
alert:         8006:8006  (Alerting system)
gemini:        8007:8007  (AI insights)
```

**Frontend**:
```yaml
frontend:      3000:3000  (Next.js web interface)
```

### Prevention

**Create startup script** (.claude/commands/redeploy.md already exists):
```bash
#!/bin/bash
# Start all services in correct order

echo "Starting infrastructure..."
docker-compose up -d timescaledb postgres redis

echo "Waiting for databases..."
sleep 5

echo "Starting backend services..."
docker-compose up -d gateway ingestion processing query

echo "Starting Phase 4 services..."
docker-compose up -d evaluation guardrail alert gemini

echo "Starting frontend..."
docker-compose up -d frontend

echo "Checking status..."
docker-compose ps
```

**Or use docker-compose profiles**:
```yaml
# In docker-compose.yml
services:
  query:
    profiles: ["backend", "all"]

  evaluation:
    profiles: ["phase4", "all"]
```

Then:
```bash
# Start everything
docker-compose --profile all up -d

# Or just core backend
docker-compose --profile backend up -d
```

### Quick Recovery Commands

**One-liner to start all services**:
```bash
docker-compose up -d timescaledb postgres redis gateway ingestion processing query evaluation guardrail alert gemini frontend
```

**Or restart everything**:
```bash
docker-compose down && docker-compose up -d
```

**Check which services are missing**:
```bash
# List all defined services
grep -E "^  [a-z]" docker-compose.yml | grep -v "^  #" | cut -d: -f1 | tr -d ' '

# Compare with running services
docker-compose ps --services
```

### Diagnostic Checklist

When dashboards don't load data:

1. **Check all containers running**:
   ```bash
   docker-compose ps
   # Should show 12 containers, all "Up" status
   ```

2. **Check query service specifically**:
   ```bash
   docker-compose ps query
   # Should be "Up" not "Exit 1"
   ```

3. **Test gateway proxy**:
   ```bash
   curl http://localhost:8000/health
   # Should return 200 OK
   ```

4. **Test query service directly**:
   ```bash
   curl -H "X-Workspace-ID: <id>" \
     "http://localhost:8000/api/v1/metrics/home-kpis?range=7d"
   # Should return JSON data
   ```

5. **If query service missing, start it**:
   ```bash
   docker-compose up -d query
   docker-compose logs --tail=50 query
   ```

---

## 13. Frontend Crashes: Division by Zero and .toFixed() Errors

### Symptoms
- Page crashes with `TypeError: Cannot read properties of undefined (reading 'toFixed')`
- Console shows error in compiled JavaScript (e.g., `page-9be4a135a6d6f6b2.js:6:30094`)
- Error occurs in `Array.map()` loop
- Hard refresh doesn't fix the issue
- New chunk files load but error persists

### Root Cause
API returns incomplete or missing metadata, causing mathematical operations to produce `NaN` or `Infinity`, which then crash when `.toFixed()` is called.

### Example Case: Cost Dashboard TopCostlyAgentsTable

**Problem**: Cost Dashboard crashed with `.toFixed()` error in TopCostlyAgentsTable component.

**Root Cause Analysis**:
```typescript
// Line 214 in TopCostlyAgentsTable.tsx (BEFORE FIX):
const costShare = (agent.total_cost / data.meta.total_cost_all_agents) * 100;

// If data.meta.total_cost_all_agents is undefined or 0:
// costShare = NaN or Infinity

// Line 228:
{costShare.toFixed(1)}% of total  // ❌ CRASHES: NaN.toFixed() throws error
```

**Why This Happened**:
1. Backend returned empty or incomplete `data.meta.total_cost_all_agents`
2. Division by undefined/zero produced `NaN`
3. Calling `.toFixed()` on `NaN` throws TypeError
4. Error occurred inside `.map()` loop, causing entire page to crash

### Debugging Process

#### Step 1: Identify Error Location
```bash
# Browser console shows:
TypeError: Cannot read properties of undefined (reading 'toFixed')
  at page-9be4a135a6d6f6b2.js:6:30094
  at Array.map

# This indicates:
# - Error is in a .toFixed() call
# - Happens during Array.map() iteration
# - Look for calculations followed by .toFixed() in map loops
```

#### Step 2: Search for .toFixed() in Map Loops
```bash
# Search all cost components
grep -n "toFixed" frontend/components/cost/*.tsx

# Focus on calculations before .toFixed()
# Look for: division operations, Math operations, NaN-prone calculations
```

#### Step 3: Find Division Operations
```bash
# Search for divisions in the problem component
grep -B 3 -A 3 "\.toFixed" frontend/components/cost/TopCostlyAgentsTable.tsx

# Found:
# const costShare = (agent.total_cost / data.meta.total_cost_all_agents) * 100;
# {costShare.toFixed(1)}% of total
```

### Solution: Three-Layer Defense

**Layer 1: Loading Guard** (Prevent rendering when data incomplete)
```typescript
<CardContent>
  {/* Guard against incomplete meta data */}
  {(!data.meta?.total_cost_all_agents || data.meta.total_cost_all_agents === 0) ? (
    <div className="text-center py-12 text-muted-foreground">
      <p className="text-sm font-medium">No Cost Data Available</p>
      <p className="text-xs mt-1">No agents have generated costs in the selected time range</p>
    </div>
  ) : (
    <>
      <Table>
        {/* ... table content ... */}
      </Table>
      {/* Summary Footer */}
    </>
  )}
</CardContent>
```

**Layer 2: Null Safety in Calculations** (Protect division operations)
```typescript
// BEFORE:
const costShare = (agent.total_cost / data.meta.total_cost_all_agents) * 100;
const efficiencyBadge = getEfficiencyBadge(agent.token_efficiency_score);

// AFTER:
const costShare = ((agent.total_cost || 0) / (data.meta.total_cost_all_agents || 1)) * 100;
const efficiencyBadge = getEfficiencyBadge(agent.token_efficiency_score || 0);
```

**Layer 3: Optional Chaining** (Safe property access)
```typescript
// Use optional chaining for nested properties
${data?.meta?.total_cost_all_agents?.toFixed(2) ?? '0.00'}

// Use nullish coalescing for fallback values
{data?.data?.reduce((sum, a) => sum + a.request_count, 0) ?? 0}
```

### JSX Syntax Requirement: React Fragment

When using ternary operator in JSX, if the false branch contains multiple elements, wrap them in a React Fragment:

```typescript
// ❌ SYNTAX ERROR: Multiple elements without wrapper
{condition ? (
  <div>No data</div>
) : (
  <Table>...</Table>
  <div>Summary</div>  // Second element causes syntax error
)}

// ✅ CORRECT: Wrap multiple elements in fragment
{condition ? (
  <div>No data</div>
) : (
  <>
    <Table>...</Table>
    <div>Summary</div>
  </>
)}
```

### Complete Fix Pattern

```typescript
export function MyTable() {
  const { data, isLoading } = useQuery<MyResponse>({
    queryKey: ['my-data'],
    queryFn: async () => {
      const response = await apiClient.get('/api/v1/my-endpoint');
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
  });

  // Early returns for loading/empty states
  if (isLoading) return <Skeleton />;
  if (!data || data.data.length === 0) return <EmptyState />;

  return (
    <Card>
      <CardContent>
        {/* Layer 1: Guard against incomplete critical data */}
        {(!data.meta?.critical_field || data.meta.critical_field === 0) ? (
          <div>No data message</div>
        ) : (
          <>
            <Table>
              <TableBody>
                {data.data.map((item, index) => {
                  // Layer 2: Null safety in calculations
                  const ratio = ((item.value || 0) / (data.meta.critical_field || 1)) * 100;
                  const score = item.score || 0;

                  return (
                    <TableRow key={item.id}>
                      <TableCell>
                        {/* Layer 3: Optional chaining + nullish coalescing */}
                        {ratio.toFixed(1)}%
                      </TableCell>
                      <TableCell>
                        ${item.cost?.toFixed(2) ?? '0.00'}
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>

            {/* Summary section also in fragment */}
            <div className="summary">
              ${data?.meta?.total?.toFixed(2) ?? '0.00'}
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}
```

### Prevention Checklist

**Before implementing calculations + .toFixed():**

- [ ] Identify all division operations
- [ ] Check if denominator can be undefined/zero
- [ ] Add null coalescing: `(numerator || 0) / (denominator || 1)`
- [ ] Guard critical sections with conditional rendering
- [ ] Use optional chaining for nested properties: `data?.meta?.field`
- [ ] Use nullish coalescing for fallbacks: `?? defaultValue`
- [ ] Test with empty/incomplete API responses
- [ ] Wrap multiple JSX elements in ternary false branch with `<>...</>`

**Common NaN-Producing Operations:**
```typescript
// Division by zero or undefined
x / 0                    // Infinity
x / undefined            // NaN
undefined / x            // NaN

// Math operations with undefined
Math.min(...[])          // Infinity
Math.max(...[])          // -Infinity
undefined * 100          // NaN
undefined + 5            // NaN

// String to number conversions
parseInt(undefined)      // NaN
Number(undefined)        // NaN
parseFloat('')           // NaN
```

**Safe Alternatives:**
```typescript
// Use defaults and filters
(x || 0) / (y || 1)                                    // Safe division
Math.min(...arr.filter(v => v != null)) || 0          // Safe Math.min
Math.max(...arr.filter(v => v != null)) || 0          // Safe Math.max
(value || 0) * 100                                     // Safe multiplication
parseInt(value || '0')                                 // Safe parseInt
```

### Verification

**Test with incomplete data:**
```typescript
// Simulate incomplete API response
const testData = {
  data: [...],
  meta: {
    total_cost_all_agents: undefined,  // Missing
    // OR
    total_cost_all_agents: 0,          // Zero
  }
};

// Component should either:
// 1. Show "No data" message (loading guard)
// 2. Display gracefully with fallback values (null safety)
// NOT crash
```

**Check console for NaN:**
```javascript
// In browser console after render
console.log('Check for NaN:',
  document.body.innerHTML.includes('NaN')
);
// Should be false
```

### Backend Prevention

**Backend should ALWAYS return complete metadata:**

```python
# ❌ BAD: Missing or null metadata
return {
    "data": agents,
    "meta": {
        "total_agents": len(agents),
        "total_cost_all_agents": None,  # Will cause frontend crash
    }
}

# ✅ GOOD: Complete metadata with defaults
return {
    "data": agents,
    "meta": {
        "total_agents": len(agents),
        "total_cost_all_agents": total_cost if total_cost else 0.0,  # Never null
    }
}
```

### Quick Recovery

If you encounter this error in production:

```bash
# 1. Identify the component
# Check error stack trace for file name and line number

# 2. Find the calculation
# Search for division or Math operations before .toFixed()

# 3. Add null safety
# Wrap with || defaults: (value || 0) / (divisor || 1)

# 4. Add loading guard if critical
# Prevent rendering when data incomplete

# 5. Rebuild frontend
docker-compose build --no-cache frontend
docker-compose up -d frontend

# 6. Hard refresh browser
# Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)
```

### Related Issues

This pattern applies to ANY calculation that can produce `NaN`:
- Percentage calculations
- Averages and ratios
- Currency formatting
- Score calculations
- Metric aggregations

**Golden Rule**: Never trust that API data is complete. Always add guards and null safety around mathematical operations.

---

**Document Version**: 1.2
**Last Updated**: 2025-10-30
**Based on**: Phase 4 Implementation + Cost Dashboard Crash Resolution
