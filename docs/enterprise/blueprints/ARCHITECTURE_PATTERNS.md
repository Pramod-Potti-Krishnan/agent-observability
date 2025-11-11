# Architecture Patterns Reference

**Purpose**: Authoritative reference for architectural decisions across all phases
**Version**: 1.0
**Last Updated**: October 27, 2025
**Status**: Blueprint for Enterprise Release

---

## Table of Contents

1. [Service Communication Patterns](#service-communication-patterns)
2. [Database Query Patterns](#database-query-patterns)
3. [Caching Strategy](#caching-strategy)
4. [State Management (Frontend)](#state-management-frontend)
5. [Multi-Tenancy Enforcement](#multi-tenancy-enforcement)
6. [Error Handling](#error-handling)
7. [Async/Await Patterns](#asyncawait-patterns)

---

## Service Communication Patterns

### Gateway Proxying Rules

**Pattern**: All external requests → Gateway → Backend Services

```python
# Gateway service proxying
@app.middleware("http")
async def proxy_to_services(request: Request, call_next):
    # Extract service from path
    # /api/v1/metrics/* → Query Service (port 8003)
    # /api/v1/traces/* → Ingestion Service (port 8001)

    service_map = {
        '/api/v1/metrics': 'http://query:8003',
        '/api/v1/usage': 'http://query:8003',
        '/api/v1/cost': 'http://query:8003',
        '/api/v1/performance': 'http://query:8003',
        '/api/v1/traces': 'http://ingestion:8001',
        '/api/v1/evaluate': 'http://evaluation:8004',
        '/api/v1/guardrails': 'http://guardrail:8005',
        '/api/v1/alerts': 'http://alert:8006',
    }

    # URL rewriting: Preserve path and query params
    # Header forwarding: X-Workspace-ID, Authorization
    # Timeout: 30 seconds
    # Retry: 3 attempts with exponential backoff (1s, 2s, 4s)
```

### Service-to-Service Authentication

**Pattern**: JWT validation at Gateway, internal services trust Gateway

```python
# Gateway validates JWT
jwt_payload = decode_jwt(request.headers['Authorization'])

# Gateway adds validated context to forwarded request
internal_headers = {
    'X-Workspace-ID': jwt_payload['workspace_id'],
    'X-User-ID': jwt_payload['user_id'],
    'X-User-Role': jwt_payload['role'],
    'X-Request-ID': generate_request_id()
}

# Backend services trust these headers (no re-validation needed)
```

### Timeout and Retry Policies

**Standard Timeouts**:
- Gateway → Service: 30 seconds
- Service → Database: 10 seconds
- Service → Redis: 5 seconds
- Frontend → Gateway: 60 seconds

**Retry Policy** (for idempotent operations):
```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=1, max=10)
)
async def call_service_with_retry(url, payload):
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(url, json=payload)
        response.raise_for_status()
        return response.json()
```

### Error Propagation

**Pattern**: Preserve error context across service boundaries

```python
# Backend service error
raise HTTPException(
    status_code=404,
    detail={
        'code': 'AGENT_NOT_FOUND',
        'message': 'Agent with ID agent-123 does not exist',
        'agent_id': 'agent-123',
        'workspace_id': str(workspace_id)
    }
)

# Gateway preserves error and adds request_id
# Frontend receives full error context for debugging
```

---

## Database Query Patterns

### Multi-Tenant Filtering (CRITICAL)

**Rule**: EVERY database query MUST filter by workspace_id

```python
# ✅ CORRECT: Always filter by workspace_id
async def get_traces(workspace_id: UUID, agent_id: str):
    query = """
        SELECT * FROM traces
        WHERE workspace_id = $1 AND agent_id = $2
        ORDER BY timestamp DESC
        LIMIT 100
    """
    return await db.fetch(query, workspace_id, agent_id)

# ❌ INCORRECT: Missing workspace_id filter (security vulnerability!)
async def get_traces_wrong(agent_id: str):
    query = "SELECT * FROM traces WHERE agent_id = $1"
    return await db.fetch(query, agent_id)
```

### TimescaleDB Continuous Aggregates

**Pattern**: Use continuous aggregates for fast time-series queries

```sql
-- Always query from continuous aggregates for time-series data
SELECT
    time_bucket('1 hour', hour) as time,
    workspace_id,
    department_id,
    SUM(trace_count) as total_requests,
    AVG(avg_latency) as avg_latency
FROM traces_hourly
WHERE workspace_id = $1
  AND hour >= NOW() - INTERVAL '24 hours'
GROUP BY time, workspace_id, department_id
ORDER BY time DESC;
```

**Benefits**:
- 10-100x faster than querying raw traces table
- Pre-computed aggregations
- Automatic refresh with policies

### Pagination Patterns

**Small Datasets** (< 10k rows): Use LIMIT/OFFSET
```python
async def get_agents_paginated(workspace_id: UUID, page: int = 1, limit: int = 50):
    offset = (page - 1) * limit
    query = """
        SELECT * FROM agents
        WHERE workspace_id = $1
        ORDER BY created_at DESC
        LIMIT $2 OFFSET $3
    """
    agents = await db.fetch(query, workspace_id, limit, offset)

    # Get total count for pagination
    total = await db.fetchval(
        "SELECT COUNT(*) FROM agents WHERE workspace_id = $1",
        workspace_id
    )

    return {
        'data': agents,
        'meta': {
            'total': total,
            'page': page,
            'limit': limit,
            'has_more': offset + limit < total
        }
    }
```

**Large Datasets** (> 10k rows): Use cursor-based pagination
```python
async def get_traces_cursor(workspace_id: UUID, cursor: Optional[str] = None, limit: int = 100):
    if cursor:
        query = """
            SELECT * FROM traces
            WHERE workspace_id = $1 AND timestamp < $2
            ORDER BY timestamp DESC
            LIMIT $3
        """
        traces = await db.fetch(query, workspace_id, decode_cursor(cursor), limit)
    else:
        query = """
            SELECT * FROM traces
            WHERE workspace_id = $1
            ORDER BY timestamp DESC
            LIMIT $2
        """
        traces = await db.fetch(query, workspace_id, limit)

    next_cursor = encode_cursor(traces[-1]['timestamp']) if traces else None

    return {
        'data': traces,
        'meta': {
            'next_cursor': next_cursor,
            'has_more': len(traces) == limit
        }
    }
```

### Index Usage Guidelines

**Always Index**:
- `workspace_id` (for multi-tenancy)
- `created_at` / `timestamp` (for time-series)
- Foreign keys
- Columns used in WHERE clauses frequently

**Covering Indexes** for common queries:
```sql
-- For query: WHERE workspace_id = X AND timestamp >= Y ORDER BY timestamp DESC
CREATE INDEX idx_traces_workspace_time
ON traces(workspace_id, timestamp DESC);

-- For query: WHERE workspace_id = X AND department_id = Y
CREATE INDEX idx_traces_workspace_dept
ON traces(workspace_id, department_id, timestamp DESC);
```

---

## Caching Strategy

### Redis Key Naming Convention

**Pattern**: `{domain}:{workspace_id}:{scope}:{identifier}`

**Examples**:
```python
# Home KPIs for workspace, 24h range, engineering department
key = "home_kpis:550e8400:range=24h&dept=engineering"

# Alert feed for workspace
key = "alerts:550e8400:active"

# Agent metadata
key = "agent:550e8400:eng-code-1"

# User session
key = "session:550e8400:user-123"
```

### TTL Policies

**Hot Data** (TTL: 30 seconds):
- Real-time alerts
- Activity stream
- Live metrics

**Warm Data** (TTL: 5 minutes):
- Dashboard KPIs
- Usage overview
- Cost metrics

**Cold Data** (TTL: 30 minutes):
- Historical aggregates
- Trend analysis
- Monthly reports

```python
# TTL constants
TTL_HOT = 30      # 30 seconds
TTL_WARM = 300    # 5 minutes
TTL_COLD = 1800   # 30 minutes

# Usage
await cache.set("home_kpis:ws-123:24h", data, TTL_WARM)
```

### Cache Invalidation Patterns

**Pattern-Based Deletion**:
```python
# Invalidate all home KPIs for workspace
await cache.invalidate_pattern("home_kpis:ws-123:*")

# Invalidate all caches for workspace (nuclear option)
await cache.invalidate_pattern("*:ws-123:*")

# Invalidate specific agent caches
await cache.invalidate_pattern("agent:ws-123:eng-code-1")
```

**Event-Driven Invalidation**:
```python
# When new trace ingested
async def on_trace_ingested(workspace_id: UUID):
    # Invalidate relevant caches
    await cache.invalidate_pattern(f"home_kpis:{workspace_id}:*")
    await cache.invalidate_pattern(f"usage:{workspace_id}:*")
    await cache.invalidate_pattern(f"performance:{workspace_id}:*")
```

### Cache-Aside Pattern

**Standard Implementation**:
```python
async def get_with_cache(key: str, fetch_fn, ttl: int):
    # 1. Check cache
    cached = await cache.get(key)
    if cached:
        return cached

    # 2. Cache miss - fetch from database
    data = await fetch_fn()

    # 3. Store in cache
    await cache.set(key, data, ttl)

    return data

# Usage
home_kpis = await get_with_cache(
    key="home_kpis:ws-123:24h",
    fetch_fn=lambda: query_home_kpis(workspace_id, "24h"),
    ttl=TTL_WARM
)
```

---

## State Management (Frontend)

### React Context for Global State

**Use Cases**:
- Authentication state (user, workspace)
- Filter state (department, environment, version, time range)
- Theme preferences (dark mode)

```typescript
// FilterContext.tsx
interface FilterState {
  timeRange: string
  department?: string
  environment?: string
  version?: string
}

const FilterContext = createContext<{
  filters: FilterState
  setFilters: (filters: FilterState) => void
}>()

export function FilterProvider({ children }) {
  const [filters, setFilters] = useState<FilterState>({
    timeRange: '24h'
  })

  return (
    <FilterContext.Provider value={{ filters, setFilters }}>
      {children}
    </FilterContext.Provider>
  )
}

// Usage in components
const { filters, setFilters } = useFilterContext()
```

### TanStack Query for Server State

**Use Cases**:
- API data fetching
- Automatic caching and refetching
- Loading/error states

```typescript
// Fetch home KPIs
const { data, isLoading, error } = useQuery({
  queryKey: ['home-kpis', filters],
  queryFn: () => apiClient.get('/api/v1/metrics/home-kpis', {
    params: {
      range: filters.timeRange,
      department: filters.department
    }
  }),
  refetchInterval: 30000, // Auto-refresh every 30s
  staleTime: 5 * 60 * 1000 // 5 minutes
})
```

### URL Query Params for Shareable State

**Use Cases**:
- Filter state (shareable dashboard links)
- Page/tab navigation
- Selected items

```typescript
// Sync filters with URL
const [searchParams, setSearchParams] = useSearchParams()

useEffect(() => {
  // Read from URL on mount
  const urlFilters = {
    timeRange: searchParams.get('range') || '24h',
    department: searchParams.get('dept') || undefined
  }
  setFilters(urlFilters)
}, [])

// Write to URL on filter change
const handleFilterChange = (newFilters: FilterState) => {
  setFilters(newFilters)

  const params = new URLSearchParams()
  params.set('range', newFilters.timeRange)
  if (newFilters.department) params.set('dept', newFilters.department)

  setSearchParams(params)
}
```

### localStorage for User Preferences

**Use Cases**:
- Last used filters
- Column visibility
- Chart preferences

```typescript
// Save filter preferences
localStorage.setItem('lastFilters', JSON.stringify(filters))

// Restore on mount
useEffect(() => {
  const savedFilters = localStorage.getItem('lastFilters')
  if (savedFilters) {
    setFilters(JSON.parse(savedFilters))
  }
}, [])
```

---

## Multi-Tenancy Enforcement

### Database Level

**Rule**: EVERY query MUST include workspace_id filter

```sql
-- ✅ CORRECT
SELECT * FROM traces
WHERE workspace_id = $1 AND agent_id = $2;

-- ❌ WRONG (data leak vulnerability!)
SELECT * FROM traces WHERE agent_id = $1;
```

### API Level

**Rule**: EVERY endpoint MUST validate workspace_id from JWT or header

```python
async def get_current_workspace(request: Request) -> UUID:
    # Option 1: From JWT
    jwt_payload = decode_jwt(request.headers['Authorization'])
    workspace_id = jwt_payload['workspace_id']

    # Option 2: From header (for API key auth)
    workspace_id = request.headers.get('X-Workspace-ID')

    # Validate workspace exists and user has access
    workspace = await db.fetchrow(
        "SELECT * FROM workspaces WHERE id = $1 AND is_active = TRUE",
        workspace_id
    )

    if not workspace:
        raise HTTPException(403, "Invalid workspace")

    return workspace_id
```

### Trace/Log Level

**Rule**: EVERY trace/log MUST include workspace_id for filtering

```python
# Structured logging
logger.info(
    "Trace ingested",
    extra={
        'workspace_id': str(workspace_id),
        'agent_id': agent_id,
        'trace_id': trace_id,
        'request_id': request_id
    }
)
```

### Row-Level Security (PostgreSQL)

**Optional**: Enforce at database level

```sql
-- Enable row-level security
ALTER TABLE traces ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their workspace's data
CREATE POLICY workspace_isolation ON traces
    FOR ALL
    USING (workspace_id = current_setting('app.current_workspace_id')::UUID);
```

---

## Error Handling

### Standard Error Codes

```python
# Authentication/Authorization
'INVALID_CREDENTIALS'
'INSUFFICIENT_PERMISSIONS'
'EXPIRED_TOKEN'
'INVALID_API_KEY'

# Resource Errors
'RESOURCE_NOT_FOUND'
'RESOURCE_ALREADY_EXISTS'
'RESOURCE_CONFLICT'

# Validation Errors
'INVALID_INPUT'
'MISSING_REQUIRED_FIELD'
'INVALID_FORMAT'

# Rate Limiting
'RATE_LIMIT_EXCEEDED'
'QUOTA_EXCEEDED'

# System Errors
'DATABASE_ERROR'
'CACHE_ERROR'
'SERVICE_UNAVAILABLE'
'INTERNAL_ERROR'
```

### Error Response Format

**Standard Structure** (see API_CONTRACTS.md):
```python
{
    "error": {
        "code": "AGENT_NOT_FOUND",
        "message": "Agent with ID 'eng-code-1' does not exist in workspace",
        "details": {
            "agent_id": "eng-code-1",
            "workspace_id": "550e8400-e29b-41d4-a716-446655440000"
        },
        "timestamp": "2025-10-27T10:15:30Z",
        "request_id": "req_abc123xyz"
    }
}
```

### Error Context Preservation

```python
# Service A raises error
try:
    result = await process_trace(trace_data)
except Exception as e:
    raise HTTPException(
        status_code=500,
        detail={
            'code': 'PROCESSING_FAILED',
            'message': str(e),
            'trace_id': trace_data['trace_id'],
            'original_error': str(e)
        }
    )

# Gateway catches and forwards with request_id
# Frontend receives full context for debugging
```

---

## Async/Await Patterns

### Database Queries

**Always use async/await for database operations**:

```python
# ✅ CORRECT
async def get_traces(workspace_id: UUID):
    query = "SELECT * FROM traces WHERE workspace_id = $1"
    return await db.fetch(query, workspace_id)

# ❌ WRONG (blocking)
def get_traces_wrong(workspace_id: UUID):
    query = "SELECT * FROM traces WHERE workspace_id = $1"
    return db.fetch_sync(query, workspace_id)  # Blocks event loop!
```

### HTTP Requests

**Use httpx AsyncClient**:

```python
import httpx

async def call_service(url: str, payload: dict):
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(url, json=payload)
        response.raise_for_status()
        return response.json()
```

### Concurrent Operations

**Use asyncio.gather for parallel operations**:

```python
import asyncio

async def get_dashboard_data(workspace_id: UUID):
    # Fetch multiple metrics in parallel
    kpis, alerts, activity = await asyncio.gather(
        get_home_kpis(workspace_id),
        get_recent_alerts(workspace_id),
        get_activity_stream(workspace_id)
    )

    return {
        'kpis': kpis,
        'alerts': alerts,
        'activity': activity
    }
```

### Connection Pooling

**Use connection pools to prevent exhaustion**:

```python
# Database pool
db_pool = await asyncpg.create_pool(
    dsn=DATABASE_URL,
    min_size=10,
    max_size=50,
    command_timeout=10.0
)

# Redis pool
redis_pool = redis.ConnectionPool.from_url(
    REDIS_URL,
    max_connections=100
)
```

---

## Summary

This document defines the core architectural patterns used throughout the enterprise platform. All phases must reference and follow these patterns to ensure consistency.

**Key Principles**:
1. ✅ Multi-tenancy ALWAYS enforced (workspace_id in every query)
2. ✅ Async/await throughout (no blocking operations)
3. ✅ Caching first (70%+ cache hit rate target)
4. ✅ Standard error handling (consistent error format)
5. ✅ Service independence (communicate via HTTP/Redis)

**Cross-References**:
- Database queries: See `DATABASE_CONVENTIONS.md`
- API design: See `API_CONTRACTS.md`
- Frontend components: See `COMPONENT_LIBRARY.md`
- Testing: See `TESTING_PATTERNS.md`

---

**Document Version**: 1.0
**Last Updated**: October 27, 2025
**Status**: Active Blueprint
