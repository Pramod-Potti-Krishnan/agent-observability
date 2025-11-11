# Phase 3 API Specification

**Version:** 1.0
**Status:** Draft
**Last Updated:** 2025-10-22

## Overview

This document specifies all 12 API endpoints for Phase 3 Analytics Pages:
- **Usage Analytics:** 4 endpoints
- **Cost Management:** 4 endpoints
- **Performance Monitoring:** 4 endpoints

All endpoints follow the Query Service pattern established in Phase 2.

---

## Common Patterns

### Authentication
All endpoints require workspace identification via header:
```http
X-Workspace-ID: <uuid>
```

### Response Format
```json
{
  "data": {},
  "metadata": {
    "timestamp": "2025-10-22T10:00:00Z",
    "workspace_id": "uuid",
    "cached": boolean
  }
}
```

### Error Responses
```json
{
  "detail": "Error message",
  "error_code": "ERROR_CODE",
  "timestamp": "2025-10-22T10:00:00Z"
}
```

### Time Range Parameter
All endpoints support `range` query parameter:
- `1h` - Last hour
- `24h` - Last 24 hours (default)
- `7d` - Last 7 days
- `30d` - Last 30 days
- `custom` - Custom range (requires `start` and `end` parameters)

---

## Usage Analytics Endpoints

### 1. Usage Overview

**Endpoint:** `GET /api/v1/usage/overview`

**Purpose:** Get high-level usage metrics

**Query Parameters:**
- `range` (string, optional): Time range (default: "24h")
  - Pattern: `^(1h|24h|7d|30d|custom)$`

**Headers:**
- `X-Workspace-ID` (UUID, required): Workspace identifier

**Response Model:**
```typescript
interface UsageOverview {
  total_calls: number
  unique_users: number
  active_agents: number
  avg_calls_per_user: number
  change_from_previous: {
    total_calls: number  // percentage
    unique_users: number
    active_agents: number
  }
}
```

**Example Request:**
```bash
curl "http://localhost:8003/api/v1/usage/overview?range=24h" \
  -H "X-Workspace-ID: 550e8400-e29b-41d4-a716-446655440000"
```

**Example Response:**
```json
{
  "total_calls": 1234,
  "unique_users": 56,
  "active_agents": 3,
  "avg_calls_per_user": 22.04,
  "change_from_previous": {
    "total_calls": 15.3,
    "unique_users": -2.1,
    "active_agents": 0.0
  }
}
```

**Cache:** 5 minutes TTL
**Performance Target:** < 50ms

---

### 2. API Calls Over Time

**Endpoint:** `GET /api/v1/usage/calls-over-time`

**Purpose:** Get time-series data of API calls

**Query Parameters:**
- `range` (string, optional): Time range (default: "7d")
- `granularity` (string, optional): Time bucket size (default: "hourly")
  - Options: `5m`, `hourly`, `daily`, `weekly`
- `agent_id` (string, optional): Filter by specific agent

**Headers:**
- `X-Workspace-ID` (UUID, required)

**Response Model:**
```typescript
interface CallsOverTime {
  data: Array<{
    timestamp: string  // ISO 8601
    agent_id: string
    call_count: number
    avg_latency_ms: number
    total_cost_usd: number
  }>
  granularity: string
  range: string
}
```

**Example Request:**
```bash
curl "http://localhost:8003/api/v1/usage/calls-over-time?range=7d&granularity=daily" \
  -H "X-Workspace-ID: 550e8400-e29b-41d4-a716-446655440000"
```

**Example Response:**
```json
{
  "data": [
    {
      "timestamp": "2025-10-22T00:00:00Z",
      "agent_id": "support-bot",
      "call_count": 145,
      "avg_latency_ms": 1234,
      "total_cost_usd": 0.0234
    }
  ],
  "granularity": "daily",
  "range": "7d"
}
```

**Cache:** 2 minutes TTL
**Performance Target:** < 100ms

---

### 3. Agent Distribution

**Endpoint:** `GET /api/v1/usage/agent-distribution`

**Purpose:** Get percentage breakdown of calls by agent

**Query Parameters:**
- `range` (string, optional): Time range (default: "30d")
- `limit` (integer, optional): Max number of agents (default: 10)

**Headers:**
- `X-Workspace-ID` (UUID, required)

**Response Model:**
```typescript
interface AgentDistribution {
  data: Array<{
    agent_id: string
    call_count: number
    percentage: number
    avg_latency_ms: number
    error_rate: number
  }>
  total_calls: number
}
```

**Example Response:**
```json
{
  "data": [
    {
      "agent_id": "support-bot",
      "call_count": 5432,
      "percentage": 54.32,
      "avg_latency_ms": 1234,
      "error_rate": 2.3
    },
    {
      "agent_id": "sales-assistant",
      "call_count": 3210,
      "percentage": 32.10,
      "avg_latency_ms": 987,
      "error_rate": 1.1
    }
  ],
  "total_calls": 10000
}
```

**Cache:** 5 minutes TTL
**Performance Target:** < 100ms

---

### 4. Top Users

**Endpoint:** `GET /api/v1/usage/top-users`

**Purpose:** Get most active users

**Query Parameters:**
- `range` (string, optional): Time range (default: "7d")
- `limit` (integer, optional): Number of users (default: 10, max: 100)
- `sort_by` (string, optional): Sort field (default: "calls")
  - Options: `calls`, `last_active`, `agents_used`

**Headers:**
- `X-Workspace-ID` (UUID, required)

**Response Model:**
```typescript
interface TopUsers {
  data: Array<{
    user_id: string
    total_calls: number
    agents_used: number
    last_active: string  // ISO 8601
    trend: 'up' | 'down' | 'stable'
    change_percentage: number
  }>
  total_users: number
}
```

**Example Response:**
```json
{
  "data": [
    {
      "user_id": "user_123",
      "total_calls": 543,
      "agents_used": 3,
      "last_active": "2025-10-22T09:45:00Z",
      "trend": "up",
      "change_percentage": 23.4
    }
  ],
  "total_users": 56
}
```

**Cache:** 5 minutes TTL
**Performance Target:** < 100ms

---

## Cost Management Endpoints

### 5. Cost Overview

**Endpoint:** `GET /api/v1/cost/overview`

**Purpose:** Get high-level cost metrics

**Query Parameters:**
- `range` (string, optional): Time range (default: "30d")

**Headers:**
- `X-Workspace-ID` (UUID, required)

**Response Model:**
```typescript
interface CostOverview {
  total_spend: number  // USD
  budget_remaining: number | null  // null if no budget set
  budget_total: number | null
  budget_percentage_used: number | null
  avg_cost_per_call: number
  projected_monthly: number
  change_from_previous: {
    total_spend: number  // percentage
    avg_cost_per_call: number
  }
}
```

**Example Response:**
```json
{
  "total_spend": 234.56,
  "budget_remaining": 765.44,
  "budget_total": 1000.00,
  "budget_percentage_used": 23.46,
  "avg_cost_per_call": 0.0234,
  "projected_monthly": 703.68,
  "change_from_previous": {
    "total_spend": 17.28,
    "avg_cost_per_call": -3.45
  }
}
```

**Cache:** 5 minutes TTL
**Performance Target:** < 50ms

---

### 6. Cost Trend

**Endpoint:** `GET /api/v1/cost/trend`

**Purpose:** Get cost over time broken down by model

**Query Parameters:**
- `range` (string, optional): Time range (default: "30d")
- `granularity` (string, optional): Time bucket (default: "daily")
  - Options: `hourly`, `daily`, `weekly`

**Headers:**
- `X-Workspace-ID` (UUID, required)

**Response Model:**
```typescript
interface CostTrend {
  data: Array<{
    timestamp: string  // ISO 8601
    total_cost: number
    by_model: {
      [model: string]: number  // model name -> cost
    }
    cumulative_cost: number
  }>
  granularity: string
}
```

**Example Response:**
```json
{
  "data": [
    {
      "timestamp": "2025-10-22T00:00:00Z",
      "total_cost": 45.67,
      "by_model": {
        "gpt-4-turbo": 34.50,
        "gpt-3.5-turbo": 11.17
      },
      "cumulative_cost": 45.67
    },
    {
      "timestamp": "2025-10-23T00:00:00Z",
      "total_cost": 52.34,
      "by_model": {
        "gpt-4-turbo": 40.12,
        "gpt-3.5-turbo": 12.22
      },
      "cumulative_cost": 98.01
    }
  ],
  "granularity": "daily"
}
```

**Cache:** 5 minutes TTL
**Performance Target:** < 100ms

---

### 7. Cost by Model

**Endpoint:** `GET /api/v1/cost/by-model`

**Purpose:** Get cost breakdown by model

**Query Parameters:**
- `range` (string, optional): Time range (default: "30d")

**Headers:**
- `X-Workspace-ID` (UUID, required)

**Response Model:**
```typescript
interface CostByModel {
  data: Array<{
    model: string
    model_provider: string
    total_cost: number
    call_count: number
    avg_cost_per_call: number
    percentage_of_total: number
  }>
  total_cost: number
}
```

**Example Response:**
```json
{
  "data": [
    {
      "model": "gpt-4-turbo",
      "model_provider": "openai",
      "total_cost": 156.78,
      "call_count": 5234,
      "avg_cost_per_call": 0.02995,
      "percentage_of_total": 66.83
    },
    {
      "model": "gpt-3.5-turbo",
      "model_provider": "openai",
      "total_cost": 77.78,
      "call_count": 7892,
      "avg_cost_per_call": 0.00985,
      "percentage_of_total": 33.17
    }
  ],
  "total_cost": 234.56
}
```

**Cache:** 5 minutes TTL
**Performance Target:** < 100ms

---

### 8. Budget Management

**Endpoint (GET):** `GET /api/v1/cost/budget`

**Purpose:** Get current budget configuration

**Query Parameters:** None

**Headers:**
- `X-Workspace-ID` (UUID, required)

**Response Model:**
```typescript
interface Budget {
  budget_amount: number | null
  budget_period: 'daily' | 'weekly' | 'monthly' | null
  alert_threshold: number | null  // percentage (e.g., 80)
  created_at: string | null
  updated_at: string | null
}
```

---

**Endpoint (PUT):** `PUT /api/v1/cost/budget`

**Purpose:** Set or update budget

**Request Body:**
```typescript
interface BudgetUpdate {
  budget_amount: number  // USD
  budget_period: 'daily' | 'weekly' | 'monthly'
  alert_threshold: number  // percentage (50-100)
}
```

**Response:** Same as GET

**Cache Invalidation:** Invalidates cost cache on update

---

## Performance Monitoring Endpoints

### 9. Performance Overview

**Endpoint:** `GET /api/v1/performance/overview`

**Purpose:** Get performance metrics overview

**Query Parameters:**
- `range` (string, optional): Time range (default: "24h")

**Headers:**
- `X-Workspace-ID` (UUID, required)

**Response Model:**
```typescript
interface PerformanceOverview {
  p50_latency_ms: number
  p95_latency_ms: number
  p99_latency_ms: number
  error_rate: number  // percentage
  success_rate: number  // percentage
  total_requests: number
  requests_per_second: number
  change_from_previous: {
    p50_latency_ms: number  // percentage
    p95_latency_ms: number
    error_rate: number
  }
}
```

**Example Response:**
```json
{
  "p50_latency_ms": 1234,
  "p95_latency_ms": 3456,
  "p99_latency_ms": 5678,
  "error_rate": 2.3,
  "success_rate": 97.7,
  "total_requests": 10000,
  "requests_per_second": 11.57,
  "change_from_previous": {
    "p50_latency_ms": -5.2,
    "p95_latency_ms": 3.4,
    "error_rate": 0.8
  }
}
```

**Cache:** 2 minutes TTL
**Performance Target:** < 50ms

---

### 10. Latency Distribution

**Endpoint:** `GET /api/v1/performance/latency`

**Purpose:** Get latency percentiles over time

**Query Parameters:**
- `range` (string, optional): Time range (default: "24h")
- `granularity` (string, optional): Time bucket (default: "5m")
  - Options: `1m`, `5m`, `hourly`

**Headers:**
- `X-Workspace-ID` (UUID, required)

**Response Model:**
```typescript
interface LatencyDistribution {
  data: Array<{
    timestamp: string  // ISO 8601
    p50: number  // ms
    p95: number
    p99: number
    sample_count: number
  }>
  granularity: string
}
```

**Example Response:**
```json
{
  "data": [
    {
      "timestamp": "2025-10-22T10:00:00Z",
      "p50": 1234,
      "p95": 3456,
      "p99": 5678,
      "sample_count": 145
    },
    {
      "timestamp": "2025-10-22T10:05:00Z",
      "p50": 1189,
      "p95": 3290,
      "p99": 5432,
      "sample_count": 152
    }
  ],
  "granularity": "5m"
}
```

**Cache:** 1 minute TTL
**Performance Target:** < 100ms

---

### 11. Throughput

**Endpoint:** `GET /api/v1/performance/throughput`

**Purpose:** Get requests per second over time

**Query Parameters:**
- `range` (string, optional): Time range (default: "24h")

**Headers:**
- `X-Workspace-ID` (UUID, required)

**Response Model:**
```typescript
interface Throughput {
  data: Array<{
    timestamp: string  // ISO 8601
    requests_per_second: number
    success_count: number
    error_count: number
    success_rate: number  // percentage
  }>
  avg_throughput: number
  peak_throughput: number
}
```

**Example Response:**
```json
{
  "data": [
    {
      "timestamp": "2025-10-22T10:00:00Z",
      "requests_per_second": 12.34,
      "success_count": 370,
      "error_count": 10,
      "success_rate": 97.37
    }
  ],
  "avg_throughput": 11.57,
  "peak_throughput": 23.45
}
```

**Cache:** 1 minute TTL
**Performance Target:** < 100ms

---

### 12. Error Analysis

**Endpoint:** `GET /api/v1/performance/errors`

**Purpose:** Get error breakdown and analysis

**Query Parameters:**
- `range` (string, optional): Time range (default: "24h")
- `limit` (integer, optional): Max errors to return (default: 20)
- `group_by` (string, optional): Grouping strategy (default: "error_type")
  - Options: `error_type`, `agent_id`, `model`

**Headers:**
- `X-Workspace-ID` (UUID, required)

**Response Model:**
```typescript
interface ErrorAnalysis {
  data: Array<{
    error_type: string
    error_count: number
    percentage: number
    last_seen: string  // ISO 8601
    first_seen: string  // ISO 8601
    affected_agents: string[]
    sample_message: string
  }>
  total_errors: number
  error_rate: number  // percentage
}
```

**Example Response:**
```json
{
  "data": [
    {
      "error_type": "timeout",
      "error_count": 45,
      "percentage": 45.0,
      "last_seen": "2025-10-22T09:55:00Z",
      "first_seen": "2025-10-22T00:12:00Z",
      "affected_agents": ["support-bot", "sales-assistant"],
      "sample_message": "Request timeout after 30s"
    },
    {
      "error_type": "rate_limit",
      "error_count": 35,
      "percentage": 35.0,
      "last_seen": "2025-10-22T09:45:00Z",
      "first_seen": "2025-10-22T01:23:00Z",
      "affected_agents": ["support-bot"],
      "sample_message": "Rate limit exceeded: 1000 requests per minute"
    }
  ],
  "total_errors": 100,
  "error_rate": 2.3
}
```

**Cache:** 1 minute TTL
**Performance Target:** < 100ms

---

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `MISSING_WORKSPACE_ID` | 400 | X-Workspace-ID header not provided |
| `INVALID_WORKSPACE_ID` | 400 | Workspace ID format invalid |
| `INVALID_TIME_RANGE` | 400 | Time range parameter invalid |
| `INVALID_GRANULARITY` | 400 | Granularity parameter invalid |
| `WORKSPACE_NOT_FOUND` | 404 | Workspace does not exist |
| `NO_DATA_AVAILABLE` | 404 | No data for specified parameters |
| `INTERNAL_ERROR` | 500 | Server error |
| `DATABASE_ERROR` | 500 | Database query failed |
| `CACHE_ERROR` | 500 | Redis cache error |

---

## Cache Strategy

**Cache Key Format:**
```
{endpoint}:{workspace_id}:{range}:{additional_params}
```

**Examples:**
- `usage_overview:550e8400-e29b-41d4-a716-446655440000:24h`
- `cost_trend:550e8400-e29b-41d4-a716-446655440000:30d:daily`

**TTL Values:**
- Overview endpoints: 300s (5 minutes)
- Detailed metrics: 120s (2 minutes)
- Real-time data: 60s (1 minute)

**Cache Invalidation:**
- Budget updates → Invalidate all cost_* keys
- No manual invalidation for read-only endpoints (rely on TTL)

---

## Performance Targets

| Endpoint | Target (P95) | Current | Status |
|----------|--------------|---------|--------|
| usage/overview | < 50ms | TBD | 🔄 |
| usage/calls-over-time | < 100ms | TBD | 🔄 |
| usage/agent-distribution | < 100ms | TBD | 🔄 |
| usage/top-users | < 100ms | TBD | 🔄 |
| cost/overview | < 50ms | TBD | 🔄 |
| cost/trend | < 100ms | TBD | 🔄 |
| cost/by-model | < 100ms | TBD | 🔄 |
| cost/budget | < 20ms | TBD | 🔄 |
| performance/overview | < 50ms | TBD | 🔄 |
| performance/latency | < 100ms | TBD | 🔄 |
| performance/throughput | < 100ms | TBD | 🔄 |
| performance/errors | < 100ms | TBD | 🔄 |

---

## Implementation Notes

**SQL Query Optimization:**
- Use `time_bucket()` for time-series aggregations
- Leverage indexes on `(workspace_id, timestamp DESC)`
- Use `percentile_cont()` for latency percentiles
- Implement proper `LIMIT` and `OFFSET` for pagination

**Pydantic Models:**
- All models in `backend/query/app/models.py`
- Use `BaseModel` from pydantic
- Include field descriptions and examples
- Validate enums and patterns

**Error Handling:**
- Catch all database exceptions
- Log errors with context
- Return user-friendly messages
- Include trace ID for debugging

**Testing:**
- Test happy paths
- Test edge cases (empty data, invalid params)
- Test error conditions
- Mock database for unit tests
- Integration tests with real database

---

**Status:** This specification will be implemented in Phase 3 of the Agent Observability Platform.

**Last Updated:** 2025-10-22
**Next Review:** After Phase 3 implementation
