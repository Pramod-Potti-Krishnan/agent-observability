# API Design Contracts

**Purpose**: Standard patterns for RESTful API design and responses
**Version**: 1.0
**Last Updated**: October 27, 2025
**Status**: Blueprint for Enterprise Release

---

## Table of Contents

1. [Endpoint Naming Conventions](#endpoint-naming-conventions)
2. [Standard Query Parameters](#standard-query-parameters)
3. [Response Envelope Format](#response-envelope-format)
4. [Error Response Format](#error-response-format)
5. [Authentication Headers](#authentication-headers)
6. [Pagination Patterns](#pagination-patterns)
7. [Status Codes](#status-codes)

---

## Endpoint Naming Conventions

### RESTful Resource Pattern

**Base Pattern**: `/api/v1/{resource}/{action}`

```python
# Collections (GET all)
GET /api/v1/agents
GET /api/v1/traces
GET /api/v1/users

# Single resource (GET by ID)
GET /api/v1/agents/{agent_id}
GET /api/v1/traces/{trace_id}
GET /api/v1/users/{user_id}

# Create (POST to collection)
POST /api/v1/agents
POST /api/v1/traces
POST /api/v1/users

# Update (PUT/PATCH to resource)
PUT /api/v1/agents/{agent_id}
PATCH /api/v1/agents/{agent_id}

# Delete (DELETE resource)
DELETE /api/v1/agents/{agent_id}
DELETE /api/v1/traces/{trace_id}

# Actions on resource (POST)
POST /api/v1/agents/{agent_id}/pause
POST /api/v1/agents/{agent_id}/resume
POST /api/v1/agents/{agent_id}/deploy
```

### Nested Resources

```python
# Agent's traces
GET /api/v1/agents/{agent_id}/traces

# Department's agents
GET /api/v1/departments/{dept_id}/agents

# Workspace's users
GET /api/v1/workspaces/{workspace_id}/users
```

### Aggregation/Metrics Endpoints

```python
# Dashboard metrics
GET /api/v1/metrics/home-kpis
GET /api/v1/metrics/usage-overview
GET /api/v1/metrics/cost-summary

# Fleet-level aggregations
GET /api/v1/fleet/health-heatmap
GET /api/v1/fleet/agent-distribution

# SLO endpoints
GET /api/v1/slo/compliance-dashboard
GET /api/v1/slo/{slo_id}/history
```

---

## Standard Query Parameters

### Required Parameters

**workspace_id**: Always validated against JWT or header

```python
# Via header (preferred)
X-Workspace-ID: 550e8400-e29b-41d4-a716-446655440000

# Via query param (fallback)
?workspace_id=550e8400-e29b-41d4-a716-446655440000
```

### Filter Parameters

**Time Range**:
```python
?range=1h | 24h | 7d | 30d | 90d | custom
?start_date=2025-10-01T00:00:00Z  # For custom range
?end_date=2025-10-27T23:59:59Z
```

**Dimensional Filters**:
```python
?department=engineering
?environment=production | staging | development
?version=v2.1
?agent_id=eng-code-1
?agent_status=active | beta | deprecated
?intent_category=code_generation
?user_segment=power_user | regular | new | dormant
```

### Pagination Parameters

```python
?page=1          # Page number (1-indexed)
?limit=50        # Items per page (default: 50, max: 1000)
?offset=0        # Offset for LIMIT/OFFSET pagination
?cursor=abc123   # Cursor for cursor-based pagination
```

### Sorting Parameters

```python
?sort=created_at     # Sort field
?order=desc | asc    # Sort direction (default: desc)
```

### Example Complete URL

```python
GET /api/v1/metrics/home-kpis?range=24h&department=engineering&environment=production&limit=100
```

---

## Response Envelope Format

### Standard Success Response

**Pattern**: All successful responses wrapped in standard envelope

```json
{
  "data": {
    // Actual response data
  },
  "meta": {
    "total": 1234,
    "page": 1,
    "limit": 50,
    "has_more": true,
    "generated_at": "2025-10-27T10:15:30Z",
    "query_duration_ms": 45
  },
  "filters_applied": {
    "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
    "range": "24h",
    "department": "engineering",
    "environment": "production"
  }
}
```

### Single Resource Response

```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "agent_id": "eng-code-1",
    "name": "Engineering Code Assistant",
    "status": "active",
    "created_at": "2025-10-01T10:00:00Z"
  },
  "meta": {
    "generated_at": "2025-10-27T10:15:30Z"
  }
}
```

### Collection Response

```json
{
  "data": [
    {
      "id": "uuid-1",
      "agent_id": "eng-code-1",
      "name": "Agent 1"
    },
    {
      "id": "uuid-2",
      "agent_id": "eng-code-2",
      "name": "Agent 2"
    }
  ],
  "meta": {
    "total": 87,
    "page": 1,
    "limit": 50,
    "has_more": true
  },
  "filters_applied": {
    "workspace_id": "550e8400",
    "department": "engineering"
  }
}
```

### Aggregation Response

```json
{
  "data": {
    "total_requests": {
      "value": 487234,
      "change": 12.5,
      "change_label": "vs previous 24h"
    },
    "avg_latency": {
      "value": 1234,
      "p50": 987,
      "p90": 1892,
      "p95": 2345,
      "p99": 3456,
      "change": -8.3
    }
  },
  "meta": {
    "generated_at": "2025-10-27T10:15:30Z",
    "query_duration_ms": 125
  },
  "filters_applied": {
    "range": "24h",
    "department": null
  }
}
```

---

## Error Response Format

### Standard Error Structure

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {
      // Additional context
    },
    "timestamp": "2025-10-27T10:15:30Z",
    "request_id": "req_abc123xyz",
    "documentation_url": "https://docs.example.com/errors/ERROR_CODE"
  }
}
```

### Error Code Categories

**Authentication/Authorization (401, 403)**:
```json
{
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "The provided credentials are invalid",
    "timestamp": "2025-10-27T10:15:30Z",
    "request_id": "req_abc123"
  }
}

{
  "error": {
    "code": "INSUFFICIENT_PERMISSIONS",
    "message": "User does not have permission to access this resource",
    "details": {
      "required_permission": "agents:write",
      "user_role": "viewer"
    },
    "timestamp": "2025-10-27T10:15:30Z",
    "request_id": "req_abc123"
  }
}
```

**Resource Errors (404, 409)**:
```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Agent with ID 'eng-code-1' does not exist",
    "details": {
      "resource_type": "agent",
      "agent_id": "eng-code-1",
      "workspace_id": "550e8400"
    },
    "timestamp": "2025-10-27T10:15:30Z",
    "request_id": "req_abc123"
  }
}

{
  "error": {
    "code": "RESOURCE_ALREADY_EXISTS",
    "message": "Agent with ID 'eng-code-1' already exists in this workspace",
    "details": {
      "agent_id": "eng-code-1",
      "workspace_id": "550e8400"
    },
    "timestamp": "2025-10-27T10:15:30Z",
    "request_id": "req_abc123"
  }
}
```

**Validation Errors (400)**:
```json
{
  "error": {
    "code": "INVALID_INPUT",
    "message": "Request validation failed",
    "details": {
      "field_errors": [
        {
          "field": "agent_id",
          "message": "agent_id must be between 3 and 128 characters"
        },
        {
          "field": "department_id",
          "message": "department_id is required"
        }
      ]
    },
    "timestamp": "2025-10-27T10:15:30Z",
    "request_id": "req_abc123"
  }
}
```

**Rate Limiting (429)**:
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit of 1000 requests per hour exceeded",
    "details": {
      "limit": 1000,
      "window": "1h",
      "retry_after": 3600
    },
    "timestamp": "2025-10-27T10:15:30Z",
    "request_id": "req_abc123"
  },
  "headers": {
    "X-RateLimit-Limit": "1000",
    "X-RateLimit-Remaining": "0",
    "X-RateLimit-Reset": "1735315200",
    "Retry-After": "3600"
  }
}
```

**System Errors (500, 503)**:
```json
{
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An unexpected error occurred",
    "timestamp": "2025-10-27T10:15:30Z",
    "request_id": "req_abc123"
  }
}

{
  "error": {
    "code": "SERVICE_UNAVAILABLE",
    "message": "Service temporarily unavailable",
    "details": {
      "service": "query-service",
      "retry_after": 60
    },
    "timestamp": "2025-10-27T10:15:30Z",
    "request_id": "req_abc123"
  }
}
```

---

## Authentication Headers

### JWT Authentication (User Sessions)

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**JWT Payload**:
```json
{
  "sub": "user_id",
  "email": "user@example.com",
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "role": "admin",
  "exp": 1735142400,
  "iat": 1735056000
}
```

### API Key Authentication (Service-to-Service)

```http
X-API-Key: pk_live_abc123xyz456...
```

### Workspace Context

```http
X-Workspace-ID: 550e8400-e29b-41d4-a716-446655440000
```

### Request Tracking

```http
X-Request-ID: req_abc123xyz456
```

### Example Complete Request

```http
GET /api/v1/metrics/home-kpis?range=24h HTTP/1.1
Host: api.example.com
Authorization: Bearer eyJhbGci...
X-Workspace-ID: 550e8400-e29b-41d4-a716-446655440000
X-Request-ID: req_abc123xyz
Accept: application/json
```

---

## Pagination Patterns

### LIMIT/OFFSET (Small Datasets < 10k)

**Request**:
```http
GET /api/v1/agents?page=2&limit=50
```

**Response**:
```json
{
  "data": [...],
  "meta": {
    "total": 287,
    "page": 2,
    "limit": 50,
    "has_more": true,
    "total_pages": 6
  }
}
```

### Cursor-Based (Large Datasets)

**Request**:
```http
GET /api/v1/traces?cursor=eyJpZCI6IjEyMyIsInRzIjoiMjAyNS...&limit=100
```

**Response**:
```json
{
  "data": [...],
  "meta": {
    "next_cursor": "eyJpZCI6IjIyMyIsInRzIjoiMjAyNS...",
    "has_more": true,
    "limit": 100
  }
}
```

**Advantages**:
- Consistent results even with data changes
- No offset performance penalty
- Works with infinite scroll

### Keyset Pagination (Time-Series)

**Request**:
```http
GET /api/v1/traces?before=2025-10-27T10:00:00Z&limit=100
```

**Response**:
```json
{
  "data": [...],
  "meta": {
    "before": "2025-10-27T09:00:00Z",
    "limit": 100,
    "has_more": true
  }
}
```

---

## Status Codes

### Success Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST (resource created) |
| 202 | Accepted | Async operation initiated |
| 204 | No Content | Successful DELETE |

### Client Error Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 400 | Bad Request | Invalid input/validation error |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource does not exist |
| 409 | Conflict | Resource already exists |
| 422 | Unprocessable Entity | Semantic validation error |
| 429 | Too Many Requests | Rate limit exceeded |

### Server Error Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 500 | Internal Server Error | Unexpected server error |
| 502 | Bad Gateway | Service communication error |
| 503 | Service Unavailable | Service down or overloaded |
| 504 | Gateway Timeout | Service timeout |

---

## Request/Response Examples

### Create Agent

**Request**:
```http
POST /api/v1/agents HTTP/1.1
Content-Type: application/json
Authorization: Bearer eyJhbGci...
X-Workspace-ID: 550e8400

{
  "agent_id": "eng-code-3",
  "name": "Engineering Code Assistant 3",
  "department_id": "dept_uuid",
  "environment": "production",
  "version": "v2.1",
  "config": {
    "model": "gpt-4-turbo",
    "temperature": 0.7
  }
}
```

**Response** (201 Created):
```json
{
  "data": {
    "id": "uuid_new",
    "agent_id": "eng-code-3",
    "name": "Engineering Code Assistant 3",
    "department_id": "dept_uuid",
    "environment": "production",
    "version": "v2.1",
    "status": "active",
    "created_at": "2025-10-27T10:15:30Z"
  },
  "meta": {
    "generated_at": "2025-10-27T10:15:30Z"
  }
}
```

### Get Filtered Traces

**Request**:
```http
GET /api/v1/traces?range=24h&department=engineering&status=error&limit=20 HTTP/1.1
Authorization: Bearer eyJhbGci...
X-Workspace-ID: 550e8400
```

**Response** (200 OK):
```json
{
  "data": [
    {
      "trace_id": "tr_abc123",
      "agent_id": "eng-code-1",
      "timestamp": "2025-10-27T10:00:00Z",
      "status": "error",
      "error": "Timeout after 30s",
      "latency_ms": 30000
    }
  ],
  "meta": {
    "total": 45,
    "page": 1,
    "limit": 20,
    "has_more": true
  },
  "filters_applied": {
    "workspace_id": "550e8400",
    "range": "24h",
    "department": "engineering",
    "status": "error"
  }
}
```

### Action Execution

**Request**:
```http
POST /api/v1/agents/eng-code-1/pause HTTP/1.1
Content-Type: application/json
Authorization: Bearer eyJhbGci...
X-Workspace-ID: 550e8400

{
  "reason": "Maintenance window",
  "duration_minutes": 30
}
```

**Response** (200 OK):
```json
{
  "data": {
    "action_id": "action_uuid",
    "status": "completed",
    "result": {
      "agent_id": "eng-code-1",
      "previous_status": "active",
      "new_status": "paused",
      "resume_at": "2025-10-27T10:45:00Z"
    },
    "executed_at": "2025-10-27T10:15:00Z"
  },
  "meta": {
    "generated_at": "2025-10-27T10:15:30Z"
  }
}
```

---

## Summary

These API contracts ensure:
- ✅ Consistent endpoint naming across all services
- ✅ Standard query parameters for filtering
- ✅ Uniform response envelopes
- ✅ Comprehensive error handling
- ✅ Proper pagination for all data sizes
- ✅ Clear authentication patterns

All API endpoints must follow these patterns.

**Cross-References**:
- Authentication: See `ARCHITECTURE_PATTERNS.md`
- Database queries: See `DATABASE_CONVENTIONS.md`
- Frontend integration: See `COMPONENT_LIBRARY.md`
- Testing: See `TESTING_PATTERNS.md`

---

**Document Version**: 1.0
**Last Updated**: October 27, 2025
**Status**: Active Blueprint
