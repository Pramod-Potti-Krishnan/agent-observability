# API Reference - AI Agent Observability Platform

**Version:** 1.0 (MVP - Phases 0-4)
**Last Updated:** October 26, 2025
**Base URL:** `http://localhost:8000` (Development)

---

## Table of Contents

1. [Authentication](#authentication)
2. [Gateway Service (Port 8000)](#gateway-service-port-8000)
3. [Ingestion Service (Port 8001)](#ingestion-service-port-8001)
4. [Query Service (Port 8003)](#query-service-port-8003)
5. [Evaluation Service (Port 8004)](#evaluation-service-port-8004)
6. [Guardrail Service (Port 8005)](#guardrail-service-port-8005)
7. [Alert Service (Port 8006)](#alert-service-port-8006)
8. [Gemini Service (Port 8007)](#gemini-service-port-8007)
9. [Common Patterns](#common-patterns)
10. [Error Handling](#error-handling)

---

## Authentication

All API requests require authentication via **JWT Bearer Token** or **API Key**.

### Required Headers

```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
Content-Type: application/json
```

### Get JWT Token

**Endpoint:** `POST /api/v1/auth/login`

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 86400,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "full_name": "John Doe",
    "workspace_id": "ws_uuid",
    "role": "admin"
  }
}
```

---

## Gateway Service (Port 8000)

The Gateway service handles authentication, routing, and proxying to backend services.

### Authentication Endpoints

#### Register User
**POST** `/api/v1/auth/register`

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123",
  "full_name": "John Doe",
  "workspace_name": "My Workspace"
}
```

**Response:**
```json
{
  "user": {
    "id": "user_uuid",
    "email": "user@example.com",
    "workspace_id": "ws_uuid"
  },
  "access_token": "jwt_token..."
}
```

---

#### Login
**POST** `/api/v1/auth/login`

(See Authentication section above)

---

#### Refresh Token
**POST** `/api/v1/auth/refresh`

**Headers:**
```http
Authorization: Bearer {current_token}
```

**Response:**
```json
{
  "access_token": "new_jwt_token...",
  "expires_in": 86400
}
```

---

#### Get Current User
**GET** `/api/v1/auth/me`

**Response:**
```json
{
  "id": "user_uuid",
  "email": "user@example.com",
  "full_name": "John Doe",
  "workspace_id": "ws_uuid",
  "role": "admin",
  "is_active": true
}
```

---

### API Key Management

#### Create API Key
**POST** `/api/v1/api-keys`

**Request:**
```json
{
  "name": "Production Key",
  "permissions": {
    "read": true,
    "write": true
  }
}
```

**Response:**
```json
{
  "id": "key_uuid",
  "key": "pk_live_abc123def456...",  // Only shown once!
  "key_prefix": "pk_live_abc...",
  "name": "Production Key",
  "created_at": "2025-10-26T10:00:00Z"
}
```

---

#### List API Keys
**GET** `/api/v1/api-keys`

**Response:**
```json
{
  "data": [
    {
      "id": "key_uuid",
      "key_prefix": "pk_live_abc...",
      "name": "Production Key",
      "created_at": "2025-10-26T10:00:00Z",
      "last_used_at": "2025-10-26T14:30:00Z",
      "is_active": true
    }
  ]
}
```

---

#### Revoke API Key
**DELETE** `/api/v1/api-keys/:id`

**Response:**
```json
{
  "message": "API key revoked successfully"
}
```

---

## Ingestion Service (Port 8001)

The Ingestion service accepts agent traces via REST API or OTLP protocol.

### Ingest Single Trace
**POST** `/api/v1/traces`

**Request:**
```json
{
  "trace_id": "tr_abc123",
  "agent_id": "support-bot",
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2025-10-26T10:00:00Z",
  "input": "How do I reset my password?",
  "output": "To reset your password, click...",
  "latency_ms": 1234,
  "status": "success",
  "model": "gpt-4-turbo",
  "model_provider": "openai",
  "tokens_input": 100,
  "tokens_output": 200,
  "tokens_total": 300,
  "cost_usd": 0.0045,
  "metadata": {
    "session_id": "sess_xyz",
    "environment": "production"
  },
  "tags": ["customer-support", "password-reset"]
}
```

**Response:**
```json
{
  "trace_id": "tr_abc123",
  "status": "accepted",
  "message": "Trace queued for processing"
}
```

---

### Ingest Batch Traces
**POST** `/api/v1/traces/batch`

**Request:**
```json
{
  "traces": [
    { /* trace 1 */ },
    { /* trace 2 */ },
    // ... up to 100 traces
  ]
}
```

**Response:**
```json
{
  "accepted": 95,
  "rejected": 5,
  "errors": [
    {
      "index": 12,
      "error": "Invalid agent_id"
    }
  ]
}
```

---

### OTLP Endpoint
**POST** `/api/v1/traces/otlp`

Accepts OpenTelemetry Protocol (OTLP) format.

**Content-Type:** `application/x-protobuf` or `application/json`

---

## Query Service (Port 8003)

The Query service provides aggregated metrics and analytics for dashboards.

### Home Dashboard Endpoints

#### Get Home KPIs
**GET** `/api/v1/metrics/home-kpis`

**Query Parameters:**
- `range`: `1h`, `24h`, `7d`, `30d` (required)

**Response:**
```json
{
  "total_requests": 12439,
  "total_requests_change": 23.5,
  "avg_latency_ms": 1234,
  "avg_latency_change": -8.2,
  "total_cost_usd": 847.23,
  "total_cost_change": 15.7,
  "success_rate": 98.7,
  "success_rate_change": 1.2
}
```

---

#### Get Recent Alerts
**GET** `/api/v1/alerts/recent`

**Query Parameters:**
- `limit`: Number of alerts (default: 10)

**Response:**
```json
{
  "data": [
    {
      "id": "alert_uuid",
      "severity": "critical",
      "title": "Budget Overrun",
      "description": "Monthly spend reached 105% of budget",
      "created_at": "2025-10-26T14:32:00Z",
      "status": "triggered"
    }
  ]
}
```

---

#### Get Activity Stream
**GET** `/api/v1/activity/stream`

**Query Parameters:**
- `limit`: Number of activities (default: 50)

**Response:**
```json
{
  "data": [
    {
      "id": "activity_uuid",
      "type": "evaluation",
      "user": "sophia@company.com",
      "description": "ran Quality Evaluation on Customer Support",
      "timestamp": "2025-10-26T12:00:00Z",
      "metadata": {
        "score": 96.8,
        "test_cases": 156
      }
    }
  ]
}
```

---

### Usage Analytics Endpoints

#### Get Usage Overview
**GET** `/api/v1/usage/overview`

**Query Parameters:**
- `range`: `24h`, `7d`, `30d` (required)

**Response:**
```json
{
  "total_users": 12439,
  "total_users_change": 23.0,
  "active_users": 8234,
  "active_users_change": 18.0,
  "total_sessions": 45892,
  "total_sessions_change": 31.0,
  "avg_session_duration_min": 4.2,
  "avg_session_duration_change": -5.0
}
```

---

#### Get API Calls Over Time
**GET** `/api/v1/usage/calls-over-time`

**Query Parameters:**
- `range`: `24h`, `7d`, `30d` (required)
- `granularity`: `5m`, `hourly`, `daily` (required)

**Response:**
```json
{
  "data": [
    {
      "timestamp": "2025-10-26T00:00:00Z",
      "calls": 2345,
      "users": 1234
    },
    {
      "timestamp": "2025-10-26T01:00:00Z",
      "calls": 1890,
      "users": 987
    }
  ]
}
```

---

#### Get Agent Distribution
**GET** `/api/v1/usage/agent-distribution`

**Query Parameters:**
- `range`: `24h`, `7d`, `30d` (required)

**Response:**
```json
{
  "data": [
    {
      "agent_id": "support-bot",
      "calls": 28234,
      "percentage": 62.0
    },
    {
      "agent_id": "sales-assistant",
      "calls": 12891,
      "percentage": 28.0
    }
  ]
}
```

---

#### Get Top Users
**GET** `/api/v1/usage/top-users`

**Query Parameters:**
- `range`: `24h`, `7d`, `30d` (required)
- `limit`: Number of users (default: 10)

**Response:**
```json
{
  "data": [
    {
      "user_id": "user_12345",
      "total_calls": 456,
      "last_active": "2025-10-26T14:30:00Z",
      "trend": "up"
    }
  ]
}
```

---

### Cost Management Endpoints

#### Get Cost Overview
**GET** `/api/v1/cost/overview`

**Query Parameters:**
- `range`: `30d`, `90d`, `12m` (required)

**Response:**
```json
{
  "total_spend_usd": 847.23,
  "budget_usd": 1000.00,
  "budget_remaining_usd": 152.77,
  "budget_utilization_percent": 84.7,
  "projected_month_end_usd": 998.45,
  "daily_average_usd": 39.87,
  "trend_percent": -8.2
}
```

---

#### Get Cost Trend
**GET** `/api/v1/cost/trend`

**Query Parameters:**
- `range`: `30d`, `90d` (required)
- `granularity`: `daily`, `weekly` (required)

**Response:**
```json
{
  "data": [
    {
      "date": "2025-10-01",
      "total_cost_usd": 35.67,
      "gpt4_cost_usd": 28.45,
      "gpt35_cost_usd": 5.22,
      "other_cost_usd": 2.00
    }
  ]
}
```

---

#### Get Cost by Model
**GET** `/api/v1/cost/by-model`

**Query Parameters:**
- `range`: `30d`, `90d` (required)

**Response:**
```json
{
  "data": [
    {
      "model": "gpt-4-turbo",
      "model_provider": "openai",
      "total_cost_usd": 623.45,
      "percentage": 73.5,
      "total_calls": 15234
    },
    {
      "model": "gpt-3.5-turbo",
      "model_provider": "openai",
      "total_cost_usd": 156.78,
      "percentage": 18.5,
      "total_calls": 45678
    }
  ]
}
```

---

#### Get Budget
**GET** `/api/v1/cost/budget`

**Response:**
```json
{
  "monthly_budget_usd": 1000.00,
  "current_spend_usd": 847.23,
  "alert_thresholds": [50, 80, 90, 100]
}
```

---

### Performance Monitoring Endpoints

#### Get Performance Overview
**GET** `/api/v1/performance/overview`

**Query Parameters:**
- `range`: `1h`, `24h`, `7d` (required)

**Response:**
```json
{
  "total_requests": 12439,
  "p50_latency_ms": 856,
  "p90_latency_ms": 1234,
  "p95_latency_ms": 2145,
  "p99_latency_ms": 4321,
  "error_rate_percent": 0.3,
  "uptime_percent": 99.98
}
```

---

#### Get Latency Percentiles
**GET** `/api/v1/performance/latency`

**Query Parameters:**
- `range`: `1h`, `24h`, `7d` (required)
- `granularity`: `5m`, `hourly` (required)

**Response:**
```json
{
  "data": [
    {
      "timestamp": "2025-10-26T14:00:00Z",
      "p50": 800,
      "p90": 1200,
      "p95": 2100,
      "p99": 4300
    }
  ]
}
```

---

#### Get Throughput
**GET** `/api/v1/performance/throughput`

**Query Parameters:**
- `range`: `1h`, `24h` (required)

**Response:**
```json
{
  "requests_per_minute": 234,
  "capacity": 500,
  "utilization_percent": 46.8
}
```

---

#### Get Errors
**GET** `/api/v1/performance/errors`

**Query Parameters:**
- `range`: `24h`, `7d` (required)
- `limit`: Number of error types (default: 20)

**Response:**
```json
{
  "data": [
    {
      "error_type": "TimeoutError",
      "count": 23,
      "percentage": 62.0,
      "most_affected_agent": "support-bot",
      "recent_example": "Knowledge base connection timeout"
    }
  ]
}
```

---

## Evaluation Service (Port 8004)

AI-powered quality evaluation using Google Gemini.

### Evaluate Trace
**POST** `/api/v1/evaluate/trace/:trace_id`

**Response:**
```json
{
  "trace_id": "tr_abc123",
  "overall_score": 94.2,
  "accuracy_score": 96.0,
  "helpfulness_score": 94.0,
  "tone_score": 92.0,
  "evaluator": "gemini",
  "evaluated_at": "2025-10-26T14:30:00Z"
}
```

---

### Batch Evaluate
**POST** `/api/v1/evaluate/batch`

**Request:**
```json
{
  "trace_ids": ["tr_abc123", "tr_def456", "tr_ghi789"]
}
```

**Response:**
```json
{
  "results": [
    {
      "trace_id": "tr_abc123",
      "overall_score": 94.2
    }
  ]
}
```

---

### Get Evaluation History
**GET** `/api/v1/evaluate/history`

**Query Parameters:**
- `limit`: Number of evaluations (default: 50)
- `agent_id`: Filter by agent (optional)

**Response:**
```json
{
  "data": [
    {
      "id": "eval_uuid",
      "trace_id": "tr_abc123",
      "agent_id": "support-bot",
      "overall_score": 94.2,
      "evaluated_at": "2025-10-26T14:30:00Z"
    }
  ]
}
```

---

## Guardrail Service (Port 8005)

Safety checks: PII detection, toxicity filtering, prompt injection prevention.

### Check All Guardrails
**POST** `/api/v1/guardrails/check`

**Request:**
```json
{
  "text": "My email is john@example.com and my phone is 555-123-4567"
}
```

**Response:**
```json
{
  "violations": [
    {
      "type": "pii",
      "subtype": "email",
      "count": 1,
      "severity": "high"
    },
    {
      "type": "pii",
      "subtype": "phone",
      "count": 1,
      "severity": "high"
    }
  ],
  "safe": false
}
```

---

### Check PII Only
**POST** `/api/v1/guardrails/pii`

**Request:**
```json
{
  "text": "Contact me at john@example.com"
}
```

**Response:**
```json
{
  "violations": {
    "email": 1,
    "phone": 0,
    "ssn": 0,
    "credit_card": 0
  },
  "detected_pii": ["email"]
}
```

---

### Check Toxicity
**POST** `/api/v1/guardrails/toxicity`

**Request:**
```json
{
  "text": "This is a normal message"
}
```

**Response:**
```json
{
  "is_toxic": false,
  "toxicity_score": 0.12,
  "threshold": 0.7
}
```

---

### Get Guardrail Violations
**GET** `/api/v1/guardrails/violations`

**Query Parameters:**
- `range`: `24h`, `7d`, `30d` (required)
- `type`: `pii`, `toxicity`, `prompt_injection` (optional)

**Response:**
```json
{
  "data": [
    {
      "id": "violation_uuid",
      "type": "pii",
      "subtype": "email",
      "agent_id": "support-bot",
      "severity": "high",
      "created_at": "2025-10-26T14:00:00Z"
    }
  ]
}
```

---

### Get Guardrail Rules
**GET** `/api/v1/guardrails/rules`

**Response:**
```json
{
  "data": [
    {
      "id": "rule_uuid",
      "name": "PII Redaction",
      "type": "pii",
      "is_active": true,
      "config": {
        "patterns": ["email", "phone", "ssn"]
      }
    }
  ]
}
```

---

## Alert Service (Port 8006)

Threshold monitoring, anomaly detection, notifications.

### List Alerts
**GET** `/api/v1/alerts`

**Query Parameters:**
- `status`: `triggered`, `acknowledged`, `resolved` (optional)
- `severity`: `info`, `warning`, `critical` (optional)

**Response:**
```json
{
  "data": [
    {
      "id": "alert_uuid",
      "rule_id": "rule_uuid",
      "metric": "latency",
      "metric_value": 3456.78,
      "threshold_value": 2000.00,
      "severity": "critical",
      "status": "triggered",
      "created_at": "2025-10-26T14:30:00Z"
    }
  ]
}
```

---

### Get Alert Details
**GET** `/api/v1/alerts/:id`

**Response:**
```json
{
  "id": "alert_uuid",
  "rule_id": "rule_uuid",
  "rule_name": "High Latency Alert",
  "metric": "latency",
  "metric_value": 3456.78,
  "threshold_value": 2000.00,
  "severity": "critical",
  "status": "triggered",
  "created_at": "2025-10-26T14:30:00Z",
  "details": {
    "affected_agent": "support-bot",
    "window": "5m"
  }
}
```

---

### Acknowledge Alert
**POST** `/api/v1/alerts/:id/acknowledge`

**Response:**
```json
{
  "id": "alert_uuid",
  "status": "acknowledged",
  "acknowledged_at": "2025-10-26T14:35:00Z"
}
```

---

### Resolve Alert
**POST** `/api/v1/alerts/:id/resolve`

**Response:**
```json
{
  "id": "alert_uuid",
  "status": "resolved",
  "resolved_at": "2025-10-26T14:40:00Z"
}
```

---

### List Alert Rules
**GET** `/api/v1/alert-rules`

**Response:**
```json
{
  "data": [
    {
      "id": "rule_uuid",
      "name": "High Latency Alert",
      "metric": "latency",
      "operator": ">",
      "threshold": 2000,
      "window": "5m",
      "severity": "critical",
      "is_active": true
    }
  ]
}
```

---

### Create Alert Rule
**POST** `/api/v1/alert-rules`

**Request:**
```json
{
  "name": "High Cost Alert",
  "metric": "cost",
  "operator": ">",
  "threshold": 100.00,
  "window": "1h",
  "severity": "warning",
  "notification_channels": ["slack", "email"]
}
```

**Response:**
```json
{
  "id": "rule_uuid",
  "name": "High Cost Alert",
  "created_at": "2025-10-26T14:45:00Z"
}
```

---

## Gemini Service (Port 8007)

AI-powered insights for cost optimization and error diagnosis.

### Get Cost Optimization Insights
**POST** `/api/v1/insights/cost-optimization`

**Request:**
```json
{
  "range": "30d"
}
```

**Response:**
```json
{
  "insights": [
    {
      "recommendation": "Switch to GPT-3.5 for simple queries",
      "impact": "high",
      "estimated_savings_usd": 280.00,
      "estimated_savings_percent": 45.0,
      "quality_impact_percent": -2.0,
      "details": "67% of Customer Support queries are FAQs"
    }
  ]
}
```

---

### Get Error Diagnosis
**POST** `/api/v1/insights/error-diagnosis`

**Request:**
```json
{
  "error_type": "TimeoutError",
  "range": "24h"
}
```

**Response:**
```json
{
  "primary_cause": "Database query performing full table scan",
  "evidence": [
    "DB query logs show 100% table scan operations",
    "Query execution time correlates 1:1 with timeout occurrences"
  ],
  "recommended_fixes": [
    {
      "fix": "Add database index: CREATE INDEX idx_embeddings ON kb(embedding)",
      "expected_improvement": "30s → 0.2s query time"
    }
  ]
}
```

---

### Get Business Goals
**GET** `/api/v1/business-goals`

**Response:**
```json
{
  "data": [
    {
      "id": "goal_uuid",
      "name": "Reduce support ticket backlog by 50%",
      "target_value": 250,
      "current_value": 312,
      "progress_percent": 76.0,
      "status": "on_track",
      "deadline": "2025-12-31"
    }
  ]
}
```

---

## Common Patterns

### Pagination

All list endpoints support pagination:

**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 50, max: 100)

**Response:**
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 1234,
    "total_pages": 25
  }
}
```

---

### Time Ranges

Standard time range values:
- `1h`: Last hour
- `24h`: Last 24 hours
- `7d`: Last 7 days
- `30d`: Last 30 days
- `90d`: Last 90 days
- `12m`: Last 12 months

---

### Filtering

**Query Parameters:**
- `agent_id`: Filter by specific agent
- `status`: Filter by status
- `start_date`: Start date (ISO 8601)
- `end_date`: End date (ISO 8601)

---

### Sorting

**Query Parameters:**
- `sort_by`: Field to sort by
- `order`: `asc` or `desc` (default: `desc`)

Example: `?sort_by=created_at&order=desc`

---

## Error Handling

### Standard Error Response

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {
      "field": "specific_field",
      "reason": "validation failed"
    }
  }
}
```

### HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid request parameters |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |

### Common Error Codes

| Code | Description |
|------|-------------|
| `INVALID_INPUT` | Request validation failed |
| `INVALID_TOKEN` | JWT token invalid or expired |
| `INVALID_API_KEY` | API key invalid or revoked |
| `RATE_LIMIT_EXCEEDED` | Too many requests |
| `WORKSPACE_NOT_FOUND` | Workspace doesn't exist |
| `AGENT_NOT_FOUND` | Agent doesn't exist |
| `TRACE_NOT_FOUND` | Trace doesn't exist |
| `PERMISSION_DENIED` | Insufficient permissions for operation |

---

## Rate Limiting

**Default Limits:**
- Authenticated requests: 1,000 requests/minute per workspace
- Unauthenticated requests: 60 requests/minute per IP

**Headers:**
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 456
X-RateLimit-Reset: 1635264000
```

**429 Response:**
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded. Retry after 45 seconds.",
    "retry_after": 45
  }
}
```

---

## Webhooks (Future Phase)

Webhook support for real-time notifications (planned for Phase 5).

---

**End of API Reference**

For architecture details, see [ARCHITECTURE.md](ARCHITECTURE.md).
For setup instructions, see [SETUP_GUIDE.md](SETUP_GUIDE.md).
For troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
