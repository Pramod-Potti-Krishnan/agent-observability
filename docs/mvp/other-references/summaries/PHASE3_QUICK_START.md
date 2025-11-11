# Phase 3 Quick Start Guide

**Version:** 1.0
**For:** Claude implementing Phase 3
**Duration:** 3 weeks (15 days)
**Deliverables:** 3 analytics pages + 12 API endpoints + 27 tests

---

## TL;DR - What to Build

**Backend (Query Service):**
```
backend/query/app/routes/
├── usage.py        (4 endpoints)
├── cost.py         (4 endpoints)
└── performance.py  (4 endpoints)
```

**Frontend (Replace placeholders):**
```
frontend/app/dashboard/
├── usage/page.tsx       (LineChart + PieChart + Table)
├── cost/page.tsx        (AreaChart + BarChart + Progress)
└── performance/page.tsx (Multi-line + AreaChart + Table)
```

**Tests:** 27 total (18 backend + 9 frontend)

---

## Day-by-Day Implementation

### Week 1: Backend (5 days)

**Day 1: API Design**
```bash
# Invoke fullstack-api-designer
Task: "Design 12 Phase 3 API endpoints per docs/phase3/API_SPEC.md template"
Output: Finalized API_SPEC.md
```

**Day 2: Usage Routes**
```bash
# Create backend/query/app/routes/usage.py
Endpoints: /overview, /calls-over-time, /agent-distribution, /top-users
Pattern: Copy home.py structure, modify queries
```

**Day 3: Cost Routes**
```bash
# Create backend/query/app/routes/cost.py
Endpoints: /overview, /trend, /by-model, /budget (GET & PUT)
Special: Budget CRUD operations
```

**Day 4: Performance Routes**
```bash
# Create backend/query/app/routes/performance.py
Endpoints: /overview, /latency, /throughput, /errors
Special: Percentile calculations (P50, P95, P99)
```

**Day 5: Backend Tests**
```bash
# Create 18 tests (6 per route file)
cd backend/query
pytest tests/test_usage.py tests/test_cost.py tests/test_performance.py -v
Goal: 18/18 passing ✅
```

---

### Week 2: Frontend (5 days)

**Day 6: Usage Page**
```tsx
// frontend/app/dashboard/usage/page.tsx
Components:
- 4 KPI Cards (Total Calls, Users, Agents, Avg)
- LineChart (calls over time)
- PieChart (agent distribution)
- Table (top users)
```

**Day 7: Cost Page**
```tsx
// frontend/app/dashboard/cost/page.tsx
Components:
- 4 KPI Cards (Spend, Budget Remaining, Avg Cost, Projected)
- AreaChart Stacked (cost trend by model)
- BarChart Horizontal (cost by model comparison)
- Alert + Progress (budget warning)
```

**Day 8: Performance Page**
```tsx
// frontend/app/dashboard/performance/page.tsx
Components:
- 4 KPI Cards (P50, P95, P99, Error Rate)
- LineChart Multi-line (P50/P95/P99 over time)
- AreaChart Stacked (success vs error throughput)
- Table (error analysis)
```

**Day 9-10: Frontend Tests & Polish**
```bash
# Create 9 tests (3 per page)
cd frontend
npm test
Goal: 9/9 passing ✅

# Polish:
- Responsive design (mobile/tablet/desktop)
- Loading states (Skeleton)
- Error states (Alert)
- Empty states ("No data available")
```

---

### Week 3: Integration & Docs (5 days)

**Day 11-12: E2E Testing**
```bash
# Test complete flow:
1. Send trace via Ingestion
2. Verify in Usage Analytics
3. Check Cost Analytics
4. Check Performance Analytics
5. Test time range filters
6. Test error handling
```

**Day 13: Performance Optimization**
```bash
# Add indexes:
CREATE INDEX idx_traces_workspace_timestamp ON traces (workspace_id, timestamp DESC);
CREATE INDEX idx_traces_workspace_agent ON traces (workspace_id, agent_id);
CREATE INDEX idx_traces_workspace_model ON traces (workspace_id, model);

# Run benchmarks:
pytest tests/ --benchmark

# Goal: All endpoints < 100ms P95
```

**Day 14: Documentation**
```bash
# Create:
- docs/phase3/PHASE3_COMPLETE.md (implementation report)
- docs/phase3/PHASE3_SUMMARY.md (quick reference)
- docs/phase3/TESTING_REPORT.md (test coverage)
- docs/phase3/PERFORMANCE_BENCHMARKS.md (query metrics)
```

**Day 15: Final Check & Sign-off**
```bash
# Checklist:
☐ 27/27 tests passing
☐ All 3 pages functional
☐ Query performance < 100ms
☐ No errors in logs
☐ Documentation complete
☐ Ready for Phase 4
```

---

## Sub-Agent Invocation Cheatsheet

### 1. API Design
```
Agent: fullstack-api-designer
Task: "Design Phase 3 Analytics API Specifications.
       Create detailed specs for 12 endpoints (4 usage + 4 cost + 4 performance).
       Include request/response schemas, error handling, cache strategy.
       Output: docs/phase3/API_SPEC.md"
```

### 2. Backend Routes (Repeat 3x for usage/cost/performance)
```
Agent: general-purpose
Task: "Build FastAPI route backend/query/app/routes/usage.py
       Follow pattern from backend/query/app/routes/home.py
       Implement 4 endpoints per API_SPEC.md
       Use db_manager.timescale_pool for queries
       Add @cached decorator (300s TTL)
       Include error handling and logging"
```

### 3. Frontend Pages (Repeat 3x)
```
Agent: general-purpose
Task: "Build complete analytics page frontend/app/dashboard/usage/page.tsx
       Replace placeholder with full Recharts implementation
       Include: KPI Cards, LineChart, PieChart, Table
       Use TanStack Query for data fetching
       Add time range selector
       Include loading (Skeleton) and error (Alert) states
       Make responsive with shadcn/ui"
```

### 4. Tests
```
Agent: fullstack-integration-tester
Task: "Create comprehensive test suite for Phase 3
       Backend: 18 tests (6 per route file)
       Frontend: 9 tests (3 per page)
       Follow existing test patterns from backend/query/tests/
       Mock database and API calls
       Test happy paths and error cases"
```

---

## Code Snippets

### Backend Route Template
```python
# backend/query/app/routes/usage.py
from fastapi import APIRouter, Header, HTTPException, Query
from typing import Optional
from uuid import UUID
from ..models import UsageOverview
from ..cache import cached
from ..database import db_manager

router = APIRouter(prefix="/api/v1/usage", tags=["usage"])

@router.get("/overview", response_model=UsageOverview)
@cached(ttl=300, key_prefix="usage_overview")
async def get_usage_overview(
    range: str = Query("24h", regex="^(1h|24h|7d|30d|custom)$"),
    workspace_id: UUID = Header(None, alias="X-Workspace-ID")
):
    if not workspace_id:
        raise HTTPException(status_code=400, detail="X-Workspace-ID required")

    hours = parse_time_range(range)  # Implement this helper

    query = """
        SELECT
            COUNT(*) as total_calls,
            COUNT(DISTINCT user_id) as unique_users,
            COUNT(DISTINCT agent_id) as active_agents,
            ROUND(COUNT(*)::numeric / NULLIF(COUNT(DISTINCT user_id), 0), 2) as avg_calls_per_user
        FROM traces
        WHERE workspace_id = $1 AND timestamp >= NOW() - INTERVAL '%s hours'
    """ % hours

    result = await db_manager.timescale_pool.fetchrow(query, workspace_id)
    return UsageOverview(**dict(result))
```

### Frontend Page Template
```tsx
// frontend/app/dashboard/usage/page.tsx
'use client'
import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { useState } from 'react'
import { useAuth } from '@/lib/auth-context'

export default function UsagePage() {
  const [timeRange, setTimeRange] = useState('24h')
  const { user } = useAuth()

  const { data: overview, isLoading } = useQuery({
    queryKey: ['usage-overview', timeRange],
    queryFn: async () => {
      const res = await fetch(`http://localhost:8003/api/v1/usage/overview?range=${timeRange}`, {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return res.json()
    },
    refetchInterval: 30000, // Auto-refresh every 30s
    enabled: !!user?.workspace_id
  })

  return (
    <div className="p-8 space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">Usage Analytics</h1>
        <Select value={timeRange} onValueChange={setTimeRange}>
          <SelectTrigger className="w-[180px]">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="1h">Last Hour</SelectItem>
            <SelectItem value="24h">Last 24 Hours</SelectItem>
            <SelectItem value="7d">Last 7 Days</SelectItem>
            <SelectItem value="30d">Last 30 Days</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader>
            <CardTitle>Total API Calls</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">
              {isLoading ? '...' : overview?.total_calls?.toLocaleString()}
            </div>
          </CardContent>
        </Card>
        {/* ... more KPI cards ... */}
      </div>

      {/* LineChart for calls over time */}
      <Card>
        <CardHeader>
          <CardTitle>API Calls Over Time</CardTitle>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={400}>
            <LineChart data={callsData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="timestamp" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Line type="monotone" dataKey="calls" stroke="#8884d8" />
            </LineChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      {/* ... more charts ... */}
    </div>
  )
}
```

---

## Performance Checklist

**Indexes to Add:**
```sql
CREATE INDEX idx_traces_workspace_timestamp ON traces (workspace_id, timestamp DESC);
CREATE INDEX idx_traces_workspace_agent ON traces (workspace_id, agent_id);
CREATE INDEX idx_traces_workspace_model ON traces (workspace_id, model);
CREATE INDEX idx_traces_workspace_status ON traces (workspace_id, status);
```

**Query Patterns:**
- ✅ Use `time_bucket()` for time-series aggregations
- ✅ Use `percentile_cont()` for P50/P95/P99
- ✅ Filter by workspace_id first
- ✅ Add ORDER BY timestamp DESC for recent data
- ✅ Use LIMIT for large results

**Caching:**
- ✅ Overview endpoints: 5 min TTL
- ✅ Detailed metrics: 2 min TTL
- ✅ Real-time data: 1 min TTL

---

## Testing Commands

```bash
# Backend unit tests
cd backend/query
pytest tests/test_usage.py -v
pytest tests/test_cost.py -v
pytest tests/test_performance.py -v
pytest tests/ --cov=app --cov-report=html

# Frontend tests
cd frontend
npm test -- --coverage
npm test -- app/dashboard/usage
npm test -- app/dashboard/cost
npm test -- app/dashboard/performance

# E2E tests
curl "http://localhost:8003/api/v1/usage/overview?range=24h" \
  -H "X-Workspace-ID: $WORKSPACE_ID"

# Start services
docker-compose up -d
docker-compose logs -f query

# Check logs
docker logs agent_obs_query --tail 100 -f
```

---

## Troubleshooting

**Issue:** X-Workspace-ID header missing
**Fix:** Check auth context provides workspace_id

**Issue:** Charts not rendering
**Fix:** Verify data format matches Recharts schema

**Issue:** Slow queries (> 100ms)
**Fix:** Add indexes, check EXPLAIN ANALYZE

**Issue:** Cache not working
**Fix:** Check Redis connection: `docker exec agent_obs_redis redis-cli PING`

**Issue:** Tests failing
**Fix:** Reset databases: `docker-compose down -v && docker-compose up -d`

---

## Acceptance Criteria

- [ ] 12 API endpoints working
- [ ] 3 frontend pages fully functional
- [ ] 27/27 tests passing
- [ ] Query performance < 100ms P95
- [ ] Responsive design on all screens
- [ ] No errors in logs
- [ ] Documentation complete

---

## Next Phase

After Phase 3 completion:
- **Phase 4:** Quality, Safety, Impact pages + AI services (Gemini)
- **Phase 5:** Settings page + Python/TypeScript SDKs
- **Phase 6:** Production readiness, WebSocket, K8s deployment

---

**Ready to Start Phase 3?**

1. Read full guide: `CLAUDE.md`
2. Review API specs: `docs/phase3/API_SPEC.md`
3. Start with Day 1: API Design
4. Follow sub-agent invocation patterns
5. Track progress with todo list

**Good luck! 🚀**
