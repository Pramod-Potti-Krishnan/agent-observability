# AI Agent Observability Platform - System Architecture

**Version:** 1.0 (MVP - Phases 0-4 Complete)
**Last Updated:** October 26, 2025
**Status:** Production MVP

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Principles](#architecture-principles)
3. [Service Architecture](#service-architecture)
4. [Data Architecture](#data-architecture)
5. [Frontend Architecture](#frontend-architecture)
6. [Data Flow Pipelines](#data-flow-pipelines)
7. [Authentication & Security](#authentication--security)
8. [Integration Patterns](#integration-patterns)
9. [Deployment Architecture](#deployment-architecture)
10. [Extension Points](#extension-points)

---

## System Overview

### What is This Platform?

The **AI Agent Observability Platform** is a comprehensive monitoring, analytics, and management system for AI agents and LLMs providing:

- **Usage Analytics** - Track API calls, users, agents, interaction patterns
- **Cost Management** - Monitor spending, budgets, forecasts, optimization
- **Performance Monitoring** - Latency percentiles, throughput, error rates
- **Quality Evaluation** - AI-powered response quality scoring with Google Gemini
- **Safety & Guardrails** - PII detection, toxicity filtering, prompt injection prevention
- **Business Impact** - ROI tracking, goal management, KPI dashboards

### High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Client Applications                        │
│              (SDKs, Direct API, Webhooks)                    │
└────────────────────────┬─────────────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────────────┐
│                  Frontend (Next.js 14)                        │
│                      Port 3000                                │
└────────────────────────┬─────────────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────────────┐
│               Gateway Service (FastAPI)                       │
│          Port 8000 - Auth, Routing, Rate Limiting            │
└────────────────────────┬─────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
┌────────▼────────┐ ┌───▼───────┐ ┌────▼──────────┐
│   Ingestion     │ │   Query    │ │  Evaluation   │
│   Port 8001     │ │ Port 8003  │ │  Port 8004    │
└────────┬────────┘ └────────────┘ └───────────────┘
         │
┌────────▼────────┐ ┌─────────────┐ ┌──────────────┐
│   Processing    │ │  Guardrail  │ │    Alert     │
│   Background    │ │  Port 8005  │ │  Port 8006   │
└─────────────────┘ └─────────────┘ └──────────────┘
                         │
                    ┌────▼────────┐
                    │   Gemini    │
                    │  Port 8007  │
                    └─────────────┘

┌──────────────────────────────────────────────────────────────┐
│                      Data Layer                               │
├──────────────────┬─────────────────┬─────────────────────────┤
│   TimescaleDB    │   PostgreSQL    │       Redis             │
│   Port 5432      │   Port 5433     │     Port 6379           │
│  (Time-series)   │  (Relational)   │  (Cache & Streams)      │
└──────────────────┴─────────────────┴─────────────────────────┘
```

### Technology Stack

**Backend:**
- Python 3.11+ with FastAPI (async)
- asyncpg (TimescaleDB/PostgreSQL driver)
- Redis (caching + streams)
- Google Gemini API (AI features)
- Pydantic v2 (data validation)

**Frontend:**
- Next.js 14 (App Router)
- React 18 with TypeScript (strict mode)
- shadcn/ui components (Radix UI + Tailwind)
- TanStack Query (data fetching)
- Recharts (visualization)

**Infrastructure:**
- Docker Compose (development)
- TimescaleDB 2.11+ (time-series metrics)
- PostgreSQL 15 (relational data)
- Redis 7 (cache & message broker)

---

## Architecture Principles

### 1. **Async/Await Throughout**
- All backend services use FastAPI with async/await
- Non-blocking database queries (asyncpg)
- Async HTTP client (httpx) for service-to-service calls
- Proper connection pooling to prevent resource exhaustion

### 2. **Workspace Isolation (Multi-Tenancy)**
- Every database row includes `workspace_id`
- Every API request includes `X-Workspace-ID` header
- All queries filter by `workspace_id`
- True multi-tenancy at the database layer

### 3. **Stream-Based Processing**
- Redis Streams (not Kafka/RabbitMQ) for simplicity
- Consumer groups for distributed processing
- Acknowledgment-based delivery guarantee
- No additional infrastructure required

### 4. **Time-Series Optimized**
- TimescaleDB hypertables partition by timestamp
- Continuous aggregates for fast queries
- Automatic retention policies (30-day default)
- Percentile calculations pre-computed

### 5. **Caching First**
- Redis as primary cache layer
- Multi-tier TTLs based on data freshness
- Pattern-based cache invalidation
- Graceful degradation: query DB on cache miss

### 6. **Service Independence**
- Each service has own database connections
- Services communicate via HTTP (REST)
- Shared data via databases, not in-memory
- Can scale/restart services independently

---

## Service Architecture

### Core Services (8 Microservices)

| Service | Port | Purpose | Dependencies |
|---------|------|---------|--------------|
| **Gateway** | 8000 | API gateway, authentication, routing | TimescaleDB, PostgreSQL, Redis |
| **Ingestion** | 8001 | Trace ingestion (REST + OTLP) | Redis |
| **Processing** | Background | Async trace processing | TimescaleDB, Redis |
| **Query** | 8003 | Analytics and metrics API | TimescaleDB, PostgreSQL, Redis |
| **Evaluation** | 8004 | Quality scoring with Gemini | PostgreSQL, Redis |
| **Guardrail** | 8005 | PII detection, safety checks | PostgreSQL, Redis |
| **Alert** | 8006 | Threshold monitoring, anomaly detection | PostgreSQL, Redis |
| **Gemini** | 8007 | AI-powered insights | TimescaleDB, PostgreSQL, Redis |

### Service Communication Patterns

**1. Client → Gateway**
- All external requests go through Gateway (port 8000)
- Gateway handles authentication (JWT validation)
- Gateway proxies to backend services
- Rate limiting enforced at Gateway

**2. Gateway → Backend Services**
- HTTP proxying via httpx AsyncClient
- URL rewriting (path + query params)
- Header forwarding (X-Workspace-ID, Authorization)
- 30-second timeout per request

**3. Ingestion → Processing (Redis Streams)**
```
Ingestion Service
    ↓
Publishes to Redis Stream: "traces:pending"
    ↓
Processing Service (Consumer Group: "processors")
    ↓
Processes & writes to TimescaleDB
```

**4. Frontend → Gateway → Query**
```
Frontend (React)
    ↓ TanStack Query
HTTP GET /api/v1/metrics/home-kpis
    ↓ Gateway
Proxies to Query Service
    ↓ Query Service
Checks Redis cache → Return cached or query DB
    ↓
Returns JSON response
```

### 1. Gateway Service (Port 8000)

**Purpose:** API gateway, authentication, rate limiting, request routing

**Key Features:**
- JWT-based authentication
- API key validation
- Rate limiting (per workspace, per API key)
- Request/response logging
- CORS configuration
- Proxying to backend services

**File Structure:**
```
backend/gateway/
├── app/
│   ├── main.py              # FastAPI app
│   ├── config.py            # Environment settings
│   ├── auth/
│   │   ├── jwt.py           # JWT utilities
│   │   ├── models.py        # Auth models
│   │   └── routes.py        # Auth endpoints
│   ├── middleware/
│   │   ├── rate_limit.py    # Redis-based rate limiting
│   │   └── logging.py       # Request logging
│   └── dependencies.py      # Shared dependencies
└── tests/
    ├── test_auth.py
    ├── test_rate_limit.py
    └── test_api_keys.py
```

**API Endpoints:**
```
POST   /api/v1/auth/register      # User registration
POST   /api/v1/auth/login         # JWT login
POST   /api/v1/auth/refresh       # Token refresh
GET    /api/v1/auth/me            # Current user
POST   /api/v1/api-keys           # Create API key
GET    /api/v1/api-keys           # List API keys
DELETE /api/v1/api-keys/:id       # Revoke API key
GET    /health                    # Health check
```

---

### 2. Ingestion Service (Port 8001)

**Purpose:** Accept and validate incoming agent traces

**Key Features:**
- REST API for trace ingestion
- OTLP-compatible endpoint (OpenTelemetry)
- Batch ingestion (up to 100 traces)
- Input validation with Pydantic
- Async publishing to Redis Streams

**Trace Schema:**
```python
{
  "trace_id": "tr_abc123",
  "agent_id": "support-bot",
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2025-10-26T10:00:00Z",
  "input": "User query here",
  "output": "Agent response here",
  "latency_ms": 1234,
  "status": "success",  # success|error|timeout
  "model": "gpt-4-turbo",
  "model_provider": "openai",
  "tokens_input": 100,
  "tokens_output": 200,
  "cost_usd": 0.0045,
  "metadata": {},
  "tags": ["production", "customer-support"]
}
```

**API Endpoints:**
```
POST /api/v1/traces              # Single trace
POST /api/v1/traces/batch        # Batch (max 100)
POST /api/v1/traces/otlp         # OTLP protocol
GET  /health                     # Health check
```

---

### 3. Processing Service (Background)

**Purpose:** Consume traces from Redis Streams, process, write to TimescaleDB

**Key Features:**
- Redis Streams consumer (consumer groups)
- Batch writing to TimescaleDB (1000 records)
- Metric extraction and aggregation
- Error handling with dead letter queue

**Processing Pipeline:**
```
1. Consume from Redis Stream (traces:pending)
2. Extract & parse trace data
3. Validate required fields
4. Calculate aggregates (if missing)
5. Batch insert into TimescaleDB
6. Acknowledge message
7. On error → Log + retry (max 3 attempts)
```

**File Structure:**
```
backend/processing/
├── app/
│   ├── main.py          # Consumer loop
│   ├── consumer.py      # Redis Streams consumer
│   ├── processor.py     # Trace processing logic
│   ├── writer.py        # TimescaleDB writer
│   └── metrics.py       # Metric extraction
└── tests/
```

---

### 4. Query Service (Port 8003)

**Purpose:** Provide aggregated metrics and dashboard data

**Key Features:**
- Dashboard KPI endpoints (13+ endpoints)
- Time-range filtering (24h, 7d, 30d, custom)
- Redis caching (5-minute TTL)
- Pagination for large datasets
- Aggregation queries using continuous aggregates

**API Endpoints:**
```
# Home Dashboard
GET /api/v1/metrics/home-kpis?range=24h
GET /api/v1/alerts/recent?limit=10
GET /api/v1/activity/stream?limit=50

# Usage Analytics
GET /api/v1/usage/overview?range=24h
GET /api/v1/usage/calls-over-time?range=7d&granularity=hourly
GET /api/v1/usage/agent-distribution?range=30d
GET /api/v1/usage/top-users?range=7d&limit=10

# Cost Management
GET /api/v1/cost/overview?range=30d
GET /api/v1/cost/trend?range=30d&granularity=daily
GET /api/v1/cost/by-model?range=30d
GET /api/v1/cost/budget?workspace_id=X

# Performance Monitoring
GET /api/v1/performance/overview?range=24h
GET /api/v1/performance/latency?range=24h&granularity=5m
GET /api/v1/performance/throughput?range=24h
GET /api/v1/performance/errors?range=24h&limit=20
```

---

### 5. Evaluation Service (Port 8004)

**Purpose:** AI-powered quality evaluation using Google Gemini

**Key Features:**
- LLM-as-a-judge evaluations
- Custom evaluation criteria
- Quality scoring (0-100)
- Evaluation history

**API Endpoints:**
```
POST /api/v1/evaluate/trace/:trace_id  # Evaluate single trace
POST /api/v1/evaluate/batch             # Batch evaluation
GET  /api/v1/evaluate/history           # Evaluation history
```

**Gemini Evaluation Example:**
```python
def evaluate_trace(trace_input: str, trace_output: str) -> dict:
    prompt = f"""
    Evaluate this AI agent interaction:

    Input: {trace_input}
    Output: {trace_output}

    Score (0-100) on:
    - Accuracy: Correctness of response
    - Helpfulness: Usefulness to user
    - Tone: Professional and appropriate

    Return JSON with scores.
    """

    response = gemini_model.generate_content(prompt)
    return json.loads(response.text)
```

---

### 6. Guardrail Service (Port 8005)

**Purpose:** Safety checks - PII, toxicity, prompt injection detection

**Key Features:**
- PII detection (emails, phones, SSNs, credit cards)
- Toxicity filtering
- Prompt injection detection
- Custom guardrail rules

**API Endpoints:**
```
POST /api/v1/guardrails/check       # Check all guardrails
POST /api/v1/guardrails/pii         # PII detection only
POST /api/v1/guardrails/toxicity    # Toxicity check only
GET  /api/v1/guardrails/violations  # Recent violations
POST /api/v1/guardrails/rules       # Create custom rule
```

**PII Detection Example:**
```python
import re

PII_PATTERNS = {
    'email': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    'phone': r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b',
    'ssn': r'\b\d{3}-\d{2}-\d{4}\b',
    'credit_card': r'\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b'
}

def detect_pii(text: str) -> dict:
    violations = {}
    for pii_type, pattern in PII_PATTERNS.items():
        matches = re.findall(pattern, text)
        if matches:
            violations[pii_type] = len(matches)
    return violations
```

---

### 7. Alert Service (Port 8006)

**Purpose:** Anomaly detection, monitoring, notifications

**Key Features:**
- Threshold-based alerts (latency, cost, error rate)
- Anomaly detection (statistical)
- Alert routing (Slack, email)
- Alert management (acknowledge, resolve)

**API Endpoints:**
```
GET  /api/v1/alerts                      # List active alerts
GET  /api/v1/alerts/:id                  # Alert details
POST /api/v1/alerts/:id/acknowledge      # Acknowledge
POST /api/v1/alerts/:id/resolve          # Resolve
POST /api/v1/alert-rules                 # Create rule
GET  /api/v1/alert-rules                 # List rules
```

**Alert Rule Example:**
```python
{
  "name": "High Latency Alert",
  "metric": "latency",
  "operator": ">",
  "threshold": 2000,  # milliseconds
  "window": "5m",
  "severity": "warning",
  "notification_channels": ["slack", "email"]
}
```

---

### 8. Gemini Integration Service (Port 8007)

**Purpose:** AI insights for cost optimization, error diagnosis

**Key Features:**
- Cost optimization suggestions
- Error root cause analysis
- Automated insights generation

**API Endpoints:**
```
POST /api/v1/insights/cost-optimization  # Cost reduction suggestions
POST /api/v1/insights/error-diagnosis    # Analyze error patterns
GET  /api/v1/insights/daily-summary      # Daily automated insights
```

---

## Data Architecture

### TimescaleDB (Time-Series Metrics)

**Primary Table: `traces` (Hypertable)**

```sql
CREATE TABLE traces (
    trace_id VARCHAR(64) PRIMARY KEY,
    workspace_id UUID NOT NULL,
    agent_id VARCHAR(128) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    input TEXT,
    output TEXT,
    error TEXT,
    latency_ms INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL,  -- success, error, timeout
    model VARCHAR(100),
    model_provider VARCHAR(50),
    tokens_input INTEGER,
    tokens_output INTEGER,
    tokens_total INTEGER,
    cost_usd DECIMAL(10, 6),
    metadata JSONB DEFAULT '{}',
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Convert to hypertable (time-series optimized)
SELECT create_hypertable('traces', 'timestamp');

-- Retention policy (30 days)
SELECT add_retention_policy('traces', INTERVAL '30 days');

-- Compression (data older than 7 days)
SELECT add_compression_policy('traces', INTERVAL '7 days');
```

**Continuous Aggregates (Pre-computed Metrics):**

```sql
-- Hourly metrics
CREATE MATERIALIZED VIEW traces_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', timestamp) AS hour,
    workspace_id,
    agent_id,
    COUNT(*) as trace_count,
    AVG(latency_ms) as avg_latency,
    percentile_cont(0.50) WITHIN GROUP (ORDER BY latency_ms) as p50_latency,
    percentile_cont(0.90) WITHIN GROUP (ORDER BY latency_ms) as p90_latency,
    percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms) as p95_latency,
    percentile_cont(0.99) WITHIN GROUP (ORDER BY latency_ms) as p99_latency,
    SUM(cost_usd) as total_cost,
    SUM(tokens_total) as total_tokens
FROM traces
GROUP BY hour, workspace_id, agent_id;

-- Daily metrics
CREATE MATERIALIZED VIEW traces_daily
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', timestamp) AS day,
    workspace_id,
    agent_id,
    COUNT(*) as trace_count,
    AVG(latency_ms) as avg_latency,
    SUM(cost_usd) as total_cost
FROM traces
GROUP BY day, workspace_id, agent_id;
```

**Indexes:**

```sql
CREATE INDEX idx_traces_workspace_id ON traces(workspace_id, timestamp DESC);
CREATE INDEX idx_traces_agent_id ON traces(agent_id, timestamp DESC);
CREATE INDEX idx_traces_status ON traces(status, timestamp DESC);
CREATE INDEX idx_traces_model ON traces(model, timestamp DESC);
```

---

### PostgreSQL (Relational Metadata)

**Core Tables:**

```sql
-- Workspaces
CREATE TABLE workspaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    settings JSONB DEFAULT '{}',
    plan VARCHAR(50) DEFAULT 'free',  -- free, pro, enterprise
    monthly_budget_usd DECIMAL(10, 2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workspace Members (many-to-many)
CREATE TABLE workspace_members (
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL,  -- owner, admin, member, viewer
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (workspace_id, user_id)
);

-- Agents
CREATE TABLE agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    agent_id VARCHAR(128) NOT NULL,  -- user-defined identifier
    name VARCHAR(255) NOT NULL,
    description TEXT,
    default_model VARCHAR(100),
    default_model_provider VARCHAR(50),
    config JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(workspace_id, agent_id)
);

-- API Keys
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    name VARCHAR(255),
    key_hash VARCHAR(255) NOT NULL,  -- SHA-256 hash
    key_prefix VARCHAR(20),  -- For display: "pk_live_abc..."
    permissions JSONB DEFAULT '{"read": true, "write": true}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE
);

-- Evaluations
CREATE TABLE evaluations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    trace_id VARCHAR(64),
    agent_id VARCHAR(128),
    overall_score DECIMAL(5, 2),  -- 0-100
    accuracy_score DECIMAL(5, 2),
    helpfulness_score DECIMAL(5, 2),
    tone_score DECIMAL(5, 2),
    criteria JSONB,
    evaluator VARCHAR(50) DEFAULT 'gemini',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Guardrail Rules
CREATE TABLE guardrail_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,  -- pii, toxicity, prompt_injection
    config JSONB NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Guardrail Violations
CREATE TABLE guardrail_violations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    rule_id UUID REFERENCES guardrail_rules(id),
    trace_id VARCHAR(64),
    agent_id VARCHAR(128),
    violation_type VARCHAR(50),
    severity VARCHAR(20),  -- low, medium, high, critical
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Alert Rules
CREATE TABLE alert_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    metric VARCHAR(50) NOT NULL,  -- latency, cost, error_rate
    operator VARCHAR(10) NOT NULL,  -- >, <, >=, <=
    threshold DECIMAL(10, 2),
    window VARCHAR(20),  -- 5m, 1h, 24h
    severity VARCHAR(20),
    notification_channels JSONB DEFAULT '[]',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Alert Notifications
CREATE TABLE alert_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    rule_id UUID REFERENCES alert_rules(id),
    metric_value DECIMAL(10, 2),
    threshold_value DECIMAL(10, 2),
    status VARCHAR(20),  -- triggered, acknowledged, resolved
    created_at TIMESTAMPTZ DEFAULT NOW(),
    acknowledged_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ
);

-- Business Goals
CREATE TABLE business_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    target_value DECIMAL(10, 2),
    current_value DECIMAL(10, 2),
    unit VARCHAR(50),
    deadline TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Budgets
CREATE TABLE budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    period VARCHAR(20) NOT NULL,  -- monthly, quarterly, annual
    amount DECIMAL(10, 2) NOT NULL,
    spent DECIMAL(10, 2) DEFAULT 0,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### Redis (Cache & Streams)

**1. Caching Layer (Multi-tier TTLs)**

```python
# Cache Keys
home_kpis:{workspace_id}:{range}        # TTL: 300s (5 min)
alerts:{workspace_id}                    # TTL: 60s (1 min)
activity:{workspace_id}                  # TTL: 30s
traces:{workspace_id}:{agent_id}         # TTL: 120s (2 min)
usage:{workspace_id}:{range}             # TTL: 300s
cost:{workspace_id}:{range}              # TTL: 300s
performance:{workspace_id}:{range}       # TTL: 300s
```

**Cache Strategy:**
```python
import redis.asyncio as redis
import json

class Cache:
    def __init__(self, url: str):
        self.client = redis.from_url(url)

    async def get(self, key: str):
        value = await self.client.get(key)
        return json.loads(value) if value else None

    async def set(self, key: str, value, ttl: int = 300):
        await self.client.setex(key, ttl, json.dumps(value))

    async def delete(self, pattern: str):
        """Pattern-based deletion"""
        keys = await self.client.keys(pattern)
        if keys:
            await self.client.delete(*keys)
```

**2. Redis Streams (Async Processing)**

```python
# Stream Configuration
STREAM_NAME = "traces:pending"
CONSUMER_GROUP = "processors"
MAX_STREAM_LENGTH = 100000

# Publishing (Ingestion Service)
await redis_client.xadd(
    STREAM_NAME,
    {"data": json.dumps(trace_data)},
    maxlen=MAX_STREAM_LENGTH
)

# Consuming (Processing Service)
messages = await redis_client.xreadgroup(
    groupname=CONSUMER_GROUP,
    consumername="processor-1",
    streams={STREAM_NAME: ">"},
    count=100,
    block=1000  # milliseconds
)

# Acknowledge after processing
await redis_client.xack(STREAM_NAME, CONSUMER_GROUP, message_id)
```

---

## Frontend Architecture

### Next.js 14 Structure (App Router)

```
frontend/
├── app/
│   ├── layout.tsx                  # Root layout
│   ├── page.tsx                    # Redirect to login/dashboard
│   ├── login/
│   │   └── page.tsx                # Login page
│   ├── register/
│   │   └── page.tsx                # Registration page
│   └── dashboard/
│       ├── layout.tsx              # Dashboard layout with sidebar
│       ├── page.tsx                # Home/Overview
│       ├── usage/
│       │   └── page.tsx            # Usage Analytics
│       ├── cost/
│       │   └── page.tsx            # Cost Management
│       ├── performance/
│       │   └── page.tsx            # Performance Monitoring
│       ├── quality/
│       │   └── page.tsx            # Quality Evaluation
│       ├── safety/
│       │   └── page.tsx            # Safety & Guardrails
│       └── impact/
│           └── page.tsx            # Business Impact
│
├── components/
│   ├── ui/                         # shadcn/ui primitives
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   ├── table.tsx
│   │   ├── tabs.tsx
│   │   ├── badge.tsx
│   │   ├── alert.tsx
│   │   ├── dialog.tsx
│   │   └── ... (20+ components)
│   │
│   ├── dashboard/                  # Dashboard-specific components
│   │   ├── KPICard.tsx
│   │   ├── AlertsFeed.tsx
│   │   ├── ActivityStream.tsx
│   │   └── TimeRangeSelector.tsx
│   │
│   ├── quality/                    # Quality page components
│   │   ├── QualityScoreCard.tsx
│   │   ├── EvaluationTable.tsx
│   │   └── QualityTrendChart.tsx
│   │
│   ├── safety/                     # Safety page components
│   │   ├── ViolationTable.tsx
│   │   ├── ViolationTrendChart.tsx
│   │   └── TypeBreakdown.tsx
│   │
│   ├── impact/                     # Impact page components
│   │   ├── GoalProgressCard.tsx
│   │   ├── ROICard.tsx
│   │   └── MetricsTable.tsx
│   │
│   └── layout/                     # Layout components
│       ├── Sidebar.tsx
│       ├── Header.tsx
│       └── Footer.tsx
│
└── lib/
    ├── api-client.ts               # Axios instance with interceptors
    ├── auth-context.tsx            # React context for auth state
    └── utils.ts                    # Helper functions
```

### State Management

**1. Server State (TanStack Query):**

```typescript
// lib/api-client.ts
import axios from 'axios'

const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
  timeout: 10000,
})

// Add workspace ID to all requests
apiClient.interceptors.request.use((config) => {
  const workspaceId = localStorage.getItem('workspaceId')
  if (workspaceId) {
    config.headers['X-Workspace-ID'] = workspaceId
  }

  const token = localStorage.getItem('authToken')
  if (token) {
    config.headers['Authorization'] = `Bearer ${token}`
  }

  return config
})

// Handle 401 errors globally
apiClient.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response?.status === 401) {
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default apiClient
```

**2. Data Fetching Pattern:**

```typescript
// app/dashboard/usage/page.tsx
'use client'

import { useQuery } from '@tanstack/react-query'
import apiClient from '@/lib/api-client'

export default function UsagePage() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['usage-overview', '24h'],
    queryFn: () => apiClient.get('/api/v1/usage/overview?range=24h'),
    refetchInterval: 30000, // Auto-refresh every 30s
  })

  if (isLoading) return <LoadingState />
  if (error) return <ErrorState error={error} />

  return (
    <div>
      <KPICard title="Total Users" value={data.total_users} />
      {/* More components */}
    </div>
  )
}
```

**3. Auth Context:**

```typescript
// lib/auth-context.tsx
'use client'

import { createContext, useContext, useState, useEffect } from 'react'

interface AuthContextType {
  user: User | null
  workspaceId: string | null
  login: (token: string, user: User) => void
  logout: () => void
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }) {
  const [user, setUser] = useState<User | null>(null)
  const [workspaceId, setWorkspaceId] = useState<string | null>(null)

  const login = (token: string, user: User) => {
    localStorage.setItem('authToken', token)
    localStorage.setItem('workspaceId', user.workspace_id)
    setUser(user)
    setWorkspaceId(user.workspace_id)
  }

  const logout = () => {
    localStorage.removeItem('authToken')
    localStorage.removeItem('workspaceId')
    setUser(null)
    setWorkspaceId(null)
  }

  return (
    <AuthContext.Provider value={{ user, workspaceId, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth must be used within AuthProvider')
  return context
}
```

---

## Data Flow Pipelines

### 1. Trace Ingestion Pipeline

```
Client SDK/API
    ↓
    └─→ POST /api/v1/traces (Ingestion Service - Port 8001)
          ↓
          └─→ Validation (Pydantic TraceInput model)
                ↓
                ├─→ Valid → Publish to Redis Stream "traces:pending"
                └─→ Invalid → Return 400 error
                      ↓
                      └─→ Redis (Stream: traces:pending, maxlen: 100,000)
                            ↓
                            └─→ Processing Service Consumer
                                  ↓
                                  ├─→ Read batch (100 messages)
                                  ├─→ Parse & validate
                                  ├─→ Calculate aggregates
                                  ├─→ Batch insert to TimescaleDB
                                  └─→ Acknowledge messages
                                        ↓
                                        └─→ TimescaleDB (traces table)
                                              ↓
                                              ├─→ Continuous aggregates (hourly/daily)
                                              └─→ Available for querying
```

**Throughput:** 1,000+ traces/second
**Latency:** < 5 seconds (ingestion → queryable)
**Reliability:** At-least-once delivery with acknowledgment

---

### 2. Query Pipeline (with Caching)

```
Frontend Request
    ↓
    └─→ GET /api/v1/metrics/home-kpis?range=24h (Gateway - Port 8000)
          ↓
          └─→ Proxy to Query Service (Port 8003)
                ↓
                └─→ Query Service Handler
                      ↓
                      ├─→ Check Redis Cache (key: home_kpis:{workspace_id}:24h)
                      │   ↓
                      │   ├─→ Cache HIT → Return cached data (< 10ms)
                      │   └─→ Cache MISS → Continue to DB
                      │         ↓
                      │         └─→ Query TimescaleDB
                      │               ↓
                      │               ├─→ Use continuous aggregates (hourly metrics)
                      │               ├─→ Apply workspace_id filter
                      │               ├─→ Apply time range filter
                      │               └─→ Return results
                      │                     ↓
                      │                     └─→ Store in Redis (TTL: 300s)
                      │                           ↓
                      │                           └─→ Return to client
                      └─→ Return JSON response
```

**Cache Strategy:**
- **Hot Data** (30s TTL): Real-time alerts, activity stream
- **Warm Data** (5 min TTL): Dashboard KPIs, metrics
- **Cold Data** (30 min TTL): Historical aggregates

**Cache Invalidation:**
- Pattern-based: `alerts:*` deleted when alert resolved
- TTL-based: Automatic expiration
- Manual: On settings changes

---

### 3. Real-Time Processing Pipeline

```
Trace Ingested
    ↓
    └─→ Processing Service
          ↓
          ├─→ Run Guardrails (PII, Toxicity, Injection)
          │   ↓
          │   └─→ If violation → Store in guardrail_violations table
          │         ↓
          │         └─→ Trigger alert if severity > threshold
          │
          ├─→ Check Alert Rules
          │   ↓
          │   └─→ Evaluate thresholds (latency > 2000ms?)
          │         ↓
          │         └─→ If triggered → Create alert_notification
          │               ↓
          │               └─→ Send to notification channels (Slack, email)
          │
          └─→ Store in TimescaleDB
                ↓
                └─→ Update continuous aggregates
                      ↓
                      └─→ Invalidate relevant cache keys
```

---

## Authentication & Security

### 1. JWT Authentication Flow

```
User Registration/Login
    ↓
    └─→ POST /api/v1/auth/register or /api/v1/auth/login
          ↓
          └─→ Gateway Service
                ↓
                ├─→ Validate credentials
                ├─→ Hash password (Argon2)
                ├─→ Create user record (PostgreSQL)
                └─→ Generate JWT token
                      ↓
                      └─→ JWT Payload:
                            {
                              "sub": "user_id",
                              "email": "user@example.com",
                              "workspace_id": "ws_uuid",
                              "role": "admin",
                              "exp": 1735142400,  // 24 hours
                              "iat": 1735056000
                            }
                            ↓
                            └─→ Sign with JWT_SECRET (HS256)
                                  ↓
                                  └─→ Return token to client
```

**Subsequent Requests:**
```
Client Request with JWT
    ↓
    └─→ Authorization: Bearer {token}
          ↓
          └─→ Gateway Middleware
                ↓
                ├─→ Decode JWT
                ├─→ Verify signature
                ├─→ Check expiration
                ├─→ Extract user_id, workspace_id, role
                └─→ Attach to request context
                      ↓
                      └─→ Forward to backend service
```

---

### 2. Workspace Isolation (Multi-Tenancy)

**Every request includes workspace context:**

```python
# All database queries filter by workspace_id
query = """
    SELECT * FROM traces
    WHERE workspace_id = $1
      AND timestamp >= $2
    ORDER BY timestamp DESC
    LIMIT $3
"""
results = await db.fetch(query, workspace_id, start_time, limit)
```

**Row-Level Security:**
- Every table has `workspace_id` column
- Every query filters by `workspace_id`
- Workspace ID from JWT (trusted source)
- No cross-workspace data leakage

---

### 3. API Key Authentication

**API Key Generation:**
```python
import secrets
import hashlib

def generate_api_key() -> tuple[str, str]:
    # Generate random key
    key = f"pk_live_{secrets.token_urlsafe(32)}"

    # Hash for storage (SHA-256)
    key_hash = hashlib.sha256(key.encode()).hexdigest()

    # Store prefix for display
    key_prefix = key[:15]  # "pk_live_abc..."

    return key, key_hash, key_prefix
```

**API Key Validation:**
```python
async def validate_api_key(api_key: str) -> Workspace:
    # Hash incoming key
    key_hash = hashlib.sha256(api_key.encode()).hexdigest()

    # Lookup in database
    record = await db.fetchrow("""
        SELECT workspace_id, permissions
        FROM api_keys
        WHERE key_hash = $1 AND is_active = TRUE
    """, key_hash)

    if not record:
        raise HTTPException(401, "Invalid API key")

    # Update last_used_at
    await db.execute("""
        UPDATE api_keys
        SET last_used_at = NOW()
        WHERE key_hash = $1
    """, key_hash)

    return record
```

---

### 4. Rate Limiting

**Redis-based rate limiting:**

```python
import redis.asyncio as redis

async def check_rate_limit(
    workspace_id: str,
    limit: int = 1000,
    window: int = 60
) -> bool:
    """
    Token bucket rate limiting

    Args:
        workspace_id: Workspace identifier
        limit: Max requests per window
        window: Window in seconds (default 60s)

    Returns:
        True if within limit, False if exceeded
    """
    key = f"rate_limit:{workspace_id}"

    # Increment counter
    current = await redis_client.incr(key)

    # Set expiration on first request
    if current == 1:
        await redis_client.expire(key, window)

    # Check if over limit
    if current > limit:
        return False

    return True
```

**Usage in middleware:**
```python
@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    workspace_id = request.headers.get("X-Workspace-ID")

    if not await check_rate_limit(workspace_id):
        return JSONResponse(
            status_code=429,
            content={"error": "Rate limit exceeded"}
        )

    return await call_next(request)
```

---

## Integration Patterns

### 1. SDK Integration (Python Example)

**Future Phase 5 implementation:**

```python
from agent_observability import AgentObservability

# Initialize
obs = AgentObservability(
    api_key="pk_live_abc123...",
    workspace_id="550e8400-e29b-41d4-a716-446655440000"
)

# Auto-instrumentation (decorator)
@obs.trace(agent_id="support-bot")
def handle_customer_query(user_input: str) -> str:
    response = call_llm(user_input)
    return response

# Manual instrumentation
with obs.trace_context(agent_id="support-bot") as ctx:
    response = call_llm(user_input)
    ctx.set_output(response)
    ctx.set_cost(0.0023)
    ctx.set_metadata({"model": "gpt-4-turbo"})
```

---

### 2. Direct API Integration

**cURL Example:**

```bash
# Ingest trace
curl -X POST http://localhost:8001/api/v1/traces \
  -H "Content-Type: application/json" \
  -H "X-API-Key: pk_live_abc123..." \
  -d '{
    "trace_id": "tr_abc123",
    "agent_id": "support-bot",
    "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
    "timestamp": "2025-10-26T10:00:00Z",
    "input": "How do I reset my password?",
    "output": "To reset your password...",
    "latency_ms": 1234,
    "status": "success",
    "model": "gpt-4-turbo",
    "model_provider": "openai",
    "tokens_input": 100,
    "tokens_output": 200,
    "cost_usd": 0.0045
  }'
```

**Python Requests Example:**

```python
import requests
from datetime import datetime

def send_trace(trace_data: dict):
    response = requests.post(
        "http://localhost:8001/api/v1/traces",
        headers={
            "Content-Type": "application/json",
            "X-API-Key": "pk_live_abc123..."
        },
        json=trace_data
    )
    return response.json()

# Usage
trace = {
    "trace_id": f"tr_{uuid.uuid4().hex[:16]}",
    "agent_id": "support-bot",
    "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
    "timestamp": datetime.utcnow().isoformat() + "Z",
    "input": user_query,
    "output": agent_response,
    "latency_ms": latency,
    "status": "success",
    "model": "gpt-4-turbo",
    "model_provider": "openai",
    "cost_usd": calculate_cost(tokens)
}

result = send_trace(trace)
```

---

## Deployment Architecture

### Docker Compose (Development)

**Services:**

```yaml
version: '3.8'

services:
  # Databases
  timescaledb:
    image: timescale/timescaledb:2.11.0-pg15
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: agent_observability
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - timescale_data:/var/lib/postgresql/data

  postgres:
    image: postgres:15
    ports:
      - "5433:5432"
    environment:
      POSTGRES_DB: agent_observability_metadata
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --requirepass redis123
    volumes:
      - redis_data:/data

  # Backend Services
  gateway:
    build: ./backend/gateway
    ports:
      - "8000:8000"
    environment:
      - TIMESCALE_URL=postgresql://postgres:postgres@timescaledb:5432/agent_observability
      - POSTGRES_URL=postgresql://postgres:postgres@postgres:5432/agent_observability_metadata
      - REDIS_URL=redis://:redis123@redis:6379/0
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - timescaledb
      - postgres
      - redis

  ingestion:
    build: ./backend/ingestion
    ports:
      - "8001:8001"
    environment:
      - REDIS_URL=redis://:redis123@redis:6379/0
    depends_on:
      - redis

  processing:
    build: ./backend/processing
    environment:
      - TIMESCALE_URL=postgresql://postgres:postgres@timescaledb:5432/agent_observability
      - REDIS_URL=redis://:redis123@redis:6379/0
    depends_on:
      - timescaledb
      - redis

  query:
    build: ./backend/query
    ports:
      - "8003:8003"
    environment:
      - TIMESCALE_URL=postgresql://postgres:postgres@timescaledb:5432/agent_observability
      - POSTGRES_URL=postgresql://postgres:postgres@postgres:5432/agent_observability_metadata
      - REDIS_URL=redis://:redis123@redis:6379/0
    depends_on:
      - timescaledb
      - postgres
      - redis

  evaluation:
    build: ./backend/evaluation
    ports:
      - "8004:8004"
    environment:
      - POSTGRES_URL=postgresql://postgres:postgres@postgres:5432/agent_observability_metadata
      - REDIS_URL=redis://:redis123@redis:6379/0
      - GEMINI_API_KEY=${GEMINI_API_KEY}
    depends_on:
      - postgres
      - redis

  guardrail:
    build: ./backend/guardrail
    ports:
      - "8005:8005"
    environment:
      - POSTGRES_URL=postgresql://postgres:postgres@postgres:5432/agent_observability_metadata
      - REDIS_URL=redis://:redis123@redis:6379/0
    depends_on:
      - postgres
      - redis

  alert:
    build: ./backend/alert
    ports:
      - "8006:8006"
    environment:
      - POSTGRES_URL=postgresql://postgres:postgres@postgres:5432/agent_observability_metadata
      - REDIS_URL=redis://:redis123@redis:6379/0
    depends_on:
      - postgres
      - redis

  gemini:
    build: ./backend/gemini
    ports:
      - "8007:8007"
    environment:
      - TIMESCALE_URL=postgresql://postgres:postgres@timescaledb:5432/agent_observability
      - POSTGRES_URL=postgresql://postgres:postgres@postgres:5432/agent_observability_metadata
      - REDIS_URL=redis://:redis123@redis:6379/0
      - GEMINI_API_KEY=${GEMINI_API_KEY}
    depends_on:
      - timescaledb
      - postgres
      - redis

  # Frontend
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8000
    depends_on:
      - gateway

volumes:
  timescale_data:
  postgres_data:
  redis_data:
```

---

### Environment Variables

```bash
# Database URLs
TIMESCALE_URL=postgresql://postgres:postgres@timescaledb:5432/agent_observability
POSTGRES_URL=postgresql://postgres:postgres@postgres:5432/agent_observability_metadata
REDIS_URL=redis://:redis123@redis:6379/0

# Security
JWT_SECRET=[32-byte random string]
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
API_KEY_SALT=[32-byte random string]

# Rate Limiting
RATE_LIMIT_REQUESTS_PER_MINUTE=1000
RATE_LIMIT_BURST=100

# Cache TTLs (seconds)
CACHE_TTL_HOME_KPIS=300
CACHE_TTL_ALERTS=60
CACHE_TTL_ACTIVITY=30
CACHE_TTL_TRACES=120

# AI Features
GEMINI_API_KEY=[API key from https://makersuite.google.com/app/apikey]
GEMINI_MODEL=gemini-pro

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:8000
```

---

## Extension Points

### 1. Adding a New Dashboard Page

**Steps:**

1. Create page file: `frontend/app/dashboard/newpage/page.tsx`
2. Add navigation item in `frontend/components/layout/Sidebar.tsx`
3. Create API endpoint in Query Service
4. Add route to Gateway proxy

**Example:**

```typescript
// frontend/app/dashboard/custom/page.tsx
'use client'

import { useQuery } from '@tanstack/react-query'
import apiClient from '@/lib/api-client'

export default function CustomPage() {
  const { data } = useQuery({
    queryKey: ['custom-metrics'],
    queryFn: () => apiClient.get('/api/v1/custom/metrics'),
  })

  return (
    <div>
      <h1>Custom Dashboard</h1>
      {/* Your components */}
    </div>
  )
}
```

---

### 2. Adding a New Guardrail Type

**Steps:**

1. Define guardrail logic in `backend/guardrail/app/detectors/`
2. Register in `backend/guardrail/app/main.py`
3. Add to database schema (if needed)
4. Update frontend Safety page

**Example:**

```python
# backend/guardrail/app/detectors/custom_detector.py
def detect_custom_violation(text: str) -> dict:
    """Custom detection logic"""
    if "forbidden_pattern" in text:
        return {
            "violated": True,
            "type": "custom",
            "severity": "high",
            "details": {"pattern": "forbidden_pattern"}
        }
    return {"violated": False}
```

---

### 3. Adding a New Evaluation Criterion

**Steps:**

1. Update Gemini prompt in `backend/evaluation/app/gemini_client.py`
2. Add criterion to database schema
3. Update frontend Quality page to display new score

**Example:**

```python
# backend/evaluation/app/gemini_client.py
def evaluate_trace_custom(input: str, output: str) -> dict:
    prompt = f"""
    Evaluate this interaction:

    Input: {input}
    Output: {output}

    Score (0-100) on:
    - Accuracy
    - Helpfulness
    - CustomCriterion: [Your custom evaluation logic]

    Return JSON.
    """

    response = gemini.generate_content(prompt)
    return json.loads(response.text)
```

---

## Conclusion

This architecture document provides a complete reference for the AI Agent Observability Platform MVP (Phases 0-4). The system is designed for:

- **Scalability:** Microservices architecture, async processing, time-series optimized
- **Multi-tenancy:** Workspace isolation at every layer
- **Performance:** Redis caching, continuous aggregates, connection pooling
- **Extensibility:** Clear extension points for new features
- **Reliability:** Error handling, retry logic, graceful degradation

**Key Achievements:**
- 8 microservices running in Docker Compose
- 2 databases (TimescaleDB + PostgreSQL) + Redis cache
- 8 frontend dashboard pages with real-time data
- AI-powered features (Gemini evaluation, insights, safety)
- Complete observability: usage, cost, performance, quality, safety, impact

**Future Work (Phase 5 - Enterprise):**
- Settings page (team management, billing, integrations)
- Python SDK (decorator-based instrumentation)
- TypeScript SDK (framework integrations)
- Advanced RBAC and SSO
- Kubernetes deployment

For detailed API documentation, see [API_REFERENCE.md](API_REFERENCE.md).
For setup instructions, see [SETUP_GUIDE.md](SETUP_GUIDE.md).
For troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

---

**Document Version:** 1.0
**Last Updated:** October 26, 2025
**Maintained By:** AI Agent Observability Team
