# Database Reference
**AI Agent Observability Platform - Complete Database Schema Documentation**

**Version:** 1.0 (MVP Complete - Phases 0-4)
**Last Updated:** October 26, 2025
**Database Stack:** TimescaleDB + PostgreSQL 15 + Redis 7

---

## Table of Contents

1. [Database Architecture](#database-architecture)
2. [TimescaleDB Schema](#timescaledb-schema)
3. [PostgreSQL Schema](#postgresql-schema)
4. [Redis Data Structures](#redis-data-structures)
5. [Indexes & Performance](#indexes--performance)
6. [Data Retention Policies](#data-retention-policies)
7. [Migration Guide](#migration-guide)
8. [Query Examples](#query-examples)

---

## Database Architecture

### Three-Database Strategy

The platform uses three specialized databases for optimal performance:

```
┌───────────────────────────────────────────────────────────────┐
│                       TimescaleDB                             │
│               Time-Series Metrics (Hot Storage)               │
│                                                               │
│  • Traces (hypertable, 30d retention)                        │
│  • Usage Metrics (1 year retention)                          │
│  • Cost Metrics (1 year retention)                           │
│  • Performance Metrics (90d retention)                       │
│  • Safety Metrics (1 year retention)                         │
└───────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────┐
│                      PostgreSQL                               │
│               Relational Data (Persistent)                    │
│                                                               │
│  • Workspaces, Users, Teams                                  │
│  • Agents, Guardrails, Alerts                                │
│  • Evaluations, Datasets, Goals                              │
│  • Feedback, Reports                                          │
└───────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────┐
│                         Redis                                 │
│               Cache & Real-Time (Volatile)                    │
│                                                               │
│  • Query result cache (TTL: 1-60 min)                        │
│  • Real-time pub/sub (metrics, alerts)                       │
│  • Rate limiting counters                                     │
│  • Session storage                                            │
│  • Task queues (Redis Streams)                               │
└───────────────────────────────────────────────────────────────┘
```

### Design Principles

**Why Three Databases?**

1. **TimescaleDB** - Optimized for time-series data (traces, metrics)
   - Automatic time-based partitioning
   - Efficient compression for older data
   - Fast time-range queries
   - Continuous aggregates for pre-computed metrics

2. **PostgreSQL** - Optimized for relational data (metadata)
   - ACID compliance
   - Strong consistency
   - Complex joins and relationships
   - Referential integrity

3. **Redis** - Optimized for speed (cache, queues)
   - Sub-millisecond latency
   - Pub/sub for real-time updates
   - Automatic TTL expiration
   - Atomic operations

---

## TimescaleDB Schema

TimescaleDB extends PostgreSQL with time-series optimizations using hypertables.

### Connection Info

```bash
# Development
Host: localhost
Port: 5432
Database: agent_observability
User: postgres
Password: postgres
URL: postgresql://postgres:postgres@localhost:5432/agent_observability
```

### 1. Traces (Hypertable)

Primary table for storing all agent execution traces with automatic time-based partitioning.

**Schema:**
```sql
CREATE EXTENSION IF NOT EXISTS timescaledb;

CREATE TABLE traces (
    id BIGSERIAL,
    trace_id VARCHAR(64) NOT NULL UNIQUE,
    workspace_id UUID NOT NULL,
    agent_id VARCHAR(128) NOT NULL,
    user_id VARCHAR(128),
    session_id VARCHAR(128),

    -- Timing
    timestamp TIMESTAMPTZ NOT NULL,
    latency_ms INTEGER NOT NULL,

    -- Content
    input TEXT,
    output TEXT,
    metadata JSONB DEFAULT '{}',

    -- Model & Tokens
    model VARCHAR(64),
    model_provider VARCHAR(64),
    tokens_prompt INTEGER,
    tokens_completion INTEGER,
    tokens_total INTEGER,

    -- Cost
    cost_usd DECIMAL(10, 6),

    -- Status
    status VARCHAR(32) DEFAULT 'success', -- success, error, timeout
    error_message TEXT,

    -- Guardrails
    guardrail_violations JSONB DEFAULT '[]',

    -- Environment
    environment VARCHAR(32) DEFAULT 'production', -- production, staging, dev

    -- Ingestion metadata
    ingested_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (timestamp, trace_id)
);

-- Convert to hypertable (partitioned by time)
SELECT create_hypertable('traces', 'timestamp',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- Compression policy (compress chunks older than 7 days)
ALTER TABLE traces SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'workspace_id, agent_id',
    timescaledb.compress_orderby = 'timestamp DESC'
);

SELECT add_compression_policy('traces', INTERVAL '7 days');

-- Retention policy (drop chunks older than 30 days)
SELECT add_retention_policy('traces', INTERVAL '30 days');
```

**Key Features:**
- **Automatic Partitioning:** Data partitioned into 1-day chunks
- **Compression:** Chunks older than 7 days compressed automatically
- **Retention:** Data older than 30 days automatically deleted
- **Workspace Isolation:** All queries filtered by `workspace_id`

**Indexes:**
```sql
CREATE INDEX idx_traces_workspace_timestamp ON traces(workspace_id, timestamp DESC);
CREATE INDEX idx_traces_agent_timestamp ON traces(agent_id, timestamp DESC);
CREATE INDEX idx_traces_user ON traces(user_id);
CREATE INDEX idx_traces_session ON traces(session_id);
CREATE INDEX idx_traces_status ON traces(status) WHERE status = 'error';
CREATE INDEX idx_traces_metadata ON traces USING GIN (metadata);
```

---

### 2. Hourly Metrics (Continuous Aggregate)

Pre-computed hourly aggregations for fast dashboard queries.

**Schema:**
```sql
CREATE MATERIALIZED VIEW hourly_metrics
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', timestamp) AS hour,
    workspace_id,
    agent_id,

    -- Usage metrics
    COUNT(*) AS total_requests,
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(DISTINCT session_id) AS unique_sessions,

    -- Performance metrics
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY latency_ms) AS latency_p50,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY latency_ms) AS latency_p90,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY latency_ms) AS latency_p95,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY latency_ms) AS latency_p99,
    MAX(latency_ms) AS latency_max,
    AVG(latency_ms) AS latency_avg,

    -- Error tracking
    SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END) AS error_count,
    CAST(SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END) AS DECIMAL) / COUNT(*) AS error_rate,

    -- Cost metrics
    SUM(cost_usd) AS total_cost,
    SUM(tokens_total) AS total_tokens

FROM traces
GROUP BY hour, workspace_id, agent_id
WITH NO DATA;

-- Refresh policy (refresh every 15 minutes)
SELECT add_continuous_aggregate_policy('hourly_metrics',
    start_offset => INTERVAL '1 day',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '15 minutes'
);
```

**Benefits:**
- Pre-computed aggregations (no expensive PERCENTILE_CONT at query time)
- Auto-refreshes every 15 minutes
- Queries run 100x faster than raw traces table
- Perfect for dashboard KPIs

---

### 3. Daily Metrics (Continuous Aggregate)

Pre-computed daily aggregations for weekly/monthly trend analysis.

**Schema:**
```sql
CREATE MATERIALIZED VIEW daily_metrics
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', timestamp) AS day,
    workspace_id,
    agent_id,
    model,

    -- Aggregated metrics
    COUNT(*) AS total_requests,
    COUNT(DISTINCT user_id) AS unique_users,
    SUM(cost_usd) AS total_cost,
    SUM(tokens_total) AS total_tokens,
    AVG(latency_ms) AS avg_latency,
    SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END) AS error_count

FROM traces
GROUP BY day, workspace_id, agent_id, model
WITH NO DATA;

SELECT add_continuous_aggregate_policy('daily_metrics',
    start_offset => INTERVAL '7 days',
    end_offset => INTERVAL '1 day',
    schedule_interval => INTERVAL '1 hour'
);
```

---

## PostgreSQL Schema

### Connection Info

```bash
# Development
Host: localhost
Port: 5433
Database: agent_observability_metadata
User: postgres
Password: postgres
URL: postgresql://postgres:postgres@localhost:5433/agent_observability_metadata
```

### 1. Workspaces

Multi-tenant workspace management.

```sql
CREATE TABLE workspaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(128) UNIQUE NOT NULL,

    -- Settings
    description TEXT,
    timezone VARCHAR(64) DEFAULT 'UTC',
    currency VARCHAR(3) DEFAULT 'USD',

    -- Budget
    monthly_budget_usd DECIMAL(10, 2),

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_workspaces_slug ON workspaces(slug);
```

**Example Row:**
```json
{
  "id": "37160be9-7d69-43b5-8d5f-9d7b5e14a57a",
  "name": "Acme Corp",
  "slug": "acme-corp",
  "timezone": "America/New_York",
  "currency": "USD",
  "monthly_budget_usd": 5000.00
}
```

---

### 2. Users

User accounts with workspace association and role-based access.

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,

    role VARCHAR(32) DEFAULT 'member', -- owner, admin, member, viewer

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    email_verified BOOLEAN DEFAULT FALSE,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ
);

CREATE INDEX idx_users_workspace ON users(workspace_id);
CREATE INDEX idx_users_email ON users(email);
```

**Roles:**
- **owner** - Full access, billing, team management
- **admin** - All features except billing
- **member** - Read/write access to agents and dashboards
- **viewer** - Read-only access

---

### 3. API Keys

API key management for authentication.

```sql
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    created_by UUID REFERENCES users(id),

    key_prefix VARCHAR(16) NOT NULL, -- pk_live_, pk_test_
    key_hash VARCHAR(255) NOT NULL, -- bcrypt hash of full key
    key_suffix VARCHAR(8) NOT NULL, -- last 8 chars (for display)

    name VARCHAR(255),
    environment VARCHAR(32) DEFAULT 'production', -- production, development

    -- Permissions
    scopes JSONB DEFAULT '["read", "write"]',

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    last_used_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

CREATE INDEX idx_api_keys_workspace ON api_keys(workspace_id);
CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);
CREATE UNIQUE INDEX idx_api_keys_prefix_suffix ON api_keys(key_prefix, key_suffix);
```

**Key Format:**
```
pk_live_1A2B3C4D5E6F7G8H9I0J1K2L3M4N5O6P_12345678
^       ^                                 ^
prefix  secret (32 chars, hashed)       suffix (8 chars, for display)
```

---

### 4. Agents

Agent configuration and metadata.

```sql
CREATE TABLE agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    agent_id VARCHAR(128) UNIQUE NOT NULL, -- e.g., "customer_support"
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- Configuration
    default_model VARCHAR(64),
    system_prompt TEXT,
    temperature DECIMAL(3, 2) DEFAULT 0.7,
    max_tokens INTEGER DEFAULT 1000,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    environment VARCHAR(32) DEFAULT 'production',

    -- Metadata
    metadata JSONB DEFAULT '{}',
    tags JSONB DEFAULT '[]',

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_agents_workspace ON agents(workspace_id);
CREATE INDEX idx_agents_agent_id ON agents(agent_id);
```

---

### 5. Guardrail Rules

Safety and compliance guardrail configurations.

```sql
CREATE TABLE guardrail_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    name VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(64) NOT NULL, -- pii_detection, toxicity_filter, prompt_injection

    -- Configuration
    config JSONB DEFAULT '{}',

    -- Action
    action VARCHAR(32) DEFAULT 'log', -- block, redact, warn, log

    -- Applied to which agents
    agent_ids JSONB DEFAULT '[]', -- ["all"] or ["agent_1", "agent_2"]

    -- Status
    is_enabled BOOLEAN DEFAULT TRUE,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_guardrail_rules_workspace ON guardrail_rules(workspace_id);
CREATE INDEX idx_guardrail_rules_type ON guardrail_rules(type);
```

**Guardrail Types:**
- `pii_detection` - Detect PII (SSN, credit card, email, phone)
- `toxicity_filter` - Filter toxic/offensive content
- `prompt_injection` - Detect prompt injection attempts
- `jailbreak_detection` - Detect jailbreak attempts

---

### 6. Guardrail Violations

Record of guardrail triggers.

```sql
CREATE TABLE guardrail_violations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    guardrail_id UUID NOT NULL REFERENCES guardrail_rules(id) ON DELETE CASCADE,

    trace_id VARCHAR(64) NOT NULL,
    agent_id VARCHAR(128) NOT NULL,
    user_id VARCHAR(128),

    -- Violation details
    severity VARCHAR(32) NOT NULL, -- critical, high, medium, low
    action_taken VARCHAR(32) NOT NULL, -- blocked, redacted, warned, logged

    detected_content TEXT,
    violation_details JSONB DEFAULT '{}',

    -- Timestamp
    occurred_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_guardrail_violations_workspace ON guardrail_violations(workspace_id);
CREATE INDEX idx_guardrail_violations_guardrail ON guardrail_violations(guardrail_id);
CREATE INDEX idx_guardrail_violations_trace ON guardrail_violations(trace_id);
CREATE INDEX idx_guardrail_violations_occurred_at ON guardrail_violations(occurred_at);
```

---

### 7. Alert Rules

Alert configuration for monitoring.

```sql
CREATE TABLE alert_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    name VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(64) NOT NULL, -- budget_exceeded, latency_spike, error_rate_high

    -- Conditions
    threshold DECIMAL(10, 4) NOT NULL,
    comparison VARCHAR(16) DEFAULT 'greater_than', -- greater_than, less_than, equals
    window_minutes INTEGER DEFAULT 60,

    -- Notification channels
    channels JSONB DEFAULT '["email"]', -- email, slack, pagerduty, webhook

    -- Status
    is_enabled BOOLEAN DEFAULT TRUE,
    severity VARCHAR(32) DEFAULT 'warning', -- critical, warning, info

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_alert_rules_workspace ON alert_rules(workspace_id);
CREATE INDEX idx_alert_rules_type ON alert_rules(type);
```

---

### 8. Alert Notifications

Alert instances and their status.

```sql
CREATE TABLE alert_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    rule_id UUID NOT NULL REFERENCES alert_rules(id) ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,
    description TEXT,
    severity VARCHAR(32) NOT NULL,

    -- Metric values
    current_value DECIMAL(10, 4),
    threshold_value DECIMAL(10, 4),

    -- Status
    status VARCHAR(32) DEFAULT 'open', -- open, acknowledged, resolved
    acknowledged_by UUID REFERENCES users(id),
    acknowledged_at TIMESTAMPTZ,

    -- Timestamps
    triggered_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

CREATE INDEX idx_alert_notifications_workspace ON alert_notifications(workspace_id);
CREATE INDEX idx_alert_notifications_rule ON alert_notifications(rule_id);
CREATE INDEX idx_alert_notifications_status ON alert_notifications(status);
CREATE INDEX idx_alert_notifications_triggered_at ON alert_notifications(triggered_at DESC);
```

---

### 9. Evaluations

AI-powered quality evaluations.

```sql
CREATE TABLE evaluations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    trace_id VARCHAR(64) NOT NULL,
    agent_id VARCHAR(128) NOT NULL,

    -- Evaluation dimensions
    accuracy_score DECIMAL(5, 2),
    relevance_score DECIMAL(5, 2),
    helpfulness_score DECIMAL(5, 2),
    coherence_score DECIMAL(5, 2),
    overall_score DECIMAL(5, 2),

    -- Evaluator
    evaluator VARCHAR(64) DEFAULT 'gemini', -- gemini, custom, human

    -- Results
    feedback TEXT,
    metadata JSONB DEFAULT '{}',

    -- Timestamps
    evaluated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_evaluations_workspace ON evaluations(workspace_id);
CREATE INDEX idx_evaluations_agent ON evaluations(agent_id);
CREATE INDEX idx_evaluations_trace ON evaluations(trace_id);
CREATE INDEX idx_evaluations_overall_score ON evaluations(overall_score);
```

---

### 10. Business Goals

Business impact tracking.

```sql
CREATE TABLE business_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,
    description TEXT,

    -- Goal metrics
    metric_type VARCHAR(64) NOT NULL, -- reduce_tickets, increase_conversion, etc.
    baseline DECIMAL(10, 2) NOT NULL,
    target DECIMAL(10, 2) NOT NULL,
    current DECIMAL(10, 2),

    -- Progress
    progress_percentage DECIMAL(5, 2),

    -- Deadline
    deadline DATE,

    -- Status
    status VARCHAR(32) DEFAULT 'in_progress', -- in_progress, completed, failed, on_hold

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_business_goals_workspace ON business_goals(workspace_id);
CREATE INDEX idx_business_goals_status ON business_goals(status);
CREATE INDEX idx_business_goals_metric_type ON business_goals(metric_type);
```

---

### 11. Budgets

Cost budget management.

```sql
CREATE TABLE budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    name VARCHAR(255) NOT NULL,

    -- Budget limits
    period VARCHAR(32) NOT NULL, -- daily, weekly, monthly
    limit_usd DECIMAL(10, 2) NOT NULL,

    -- Current usage
    current_spend_usd DECIMAL(10, 2) DEFAULT 0,

    -- Alert thresholds
    alert_threshold_percentage DECIMAL(5, 2) DEFAULT 80.00,

    -- Scope
    agent_ids JSONB DEFAULT '[]', -- Empty = all agents

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ
);

CREATE INDEX idx_budgets_workspace ON budgets(workspace_id);
CREATE INDEX idx_budgets_period ON budgets(period);
```

---

## Redis Data Structures

### Connection Info

```bash
# Development
Host: localhost
Port: 6379
Password: redis123
Database: 0
URL: redis://:redis123@localhost:6379/0
```

### 1. Query Cache

**Pattern:** `cache:{endpoint}:{workspace_id}:{params_hash}`
**Type:** String (JSON)
**TTL:** Variable (30s - 30min)

```redis
# Set cache
SET cache:home_kpis:ws_123:h4f8g9 '{"total_requests": 12345, ...}' EX 300

# Get cache
GET cache:home_kpis:ws_123:h4f8g9

# Delete pattern
KEYS cache:home_kpis:ws_123:*
DEL cache:home_kpis:ws_123:*
```

**Cache TTLs by endpoint:**
- Real-time metrics (home KPIs): 30 seconds
- Usage timeseries: 5 minutes
- Cost analytics: 5 minutes
- Performance charts: 1 minute
- Quality scores: 30 minutes

---

### 2. Rate Limiting

**Pattern:** `rate_limit:{workspace_id}:{endpoint}`
**Type:** String (counter)
**TTL:** 60 seconds

```redis
# Increment counter
INCR rate_limit:ws_123:api_traces

# Set expiration on first request
EXPIRE rate_limit:ws_123:api_traces 60

# Check current count
GET rate_limit:ws_123:api_traces

# Python implementation
current = await redis.incr(key)
if current == 1:
    await redis.expire(key, 60)
if current > limit:
    raise RateLimitExceeded()
```

---

### 3. Task Queue (Redis Streams)

**Stream:** `trace_processing_queue`
**Consumer Group:** `processor_group`

```redis
# Producer: Add trace to queue
XADD trace_processing_queue * trace_id tr_abc123 workspace_id ws_456

# Consumer: Read from queue
XREADGROUP GROUP processor_group consumer1 COUNT 10 STREAMS trace_processing_queue >

# Acknowledge processed message
XACK trace_processing_queue processor_group message_id
```

**Python Implementation:**
```python
# Producer
await redis.xadd('trace_processing_queue', {
    'trace_id': trace_id,
    'workspace_id': workspace_id,
    'timestamp': datetime.utcnow().isoformat()
})

# Consumer
messages = await redis.xreadgroup(
    groupname='processor_group',
    consumername='consumer1',
    streams={'trace_processing_queue': '>'},
    count=10
)

for stream, msgs in messages:
    for msg_id, data in msgs:
        # Process trace
        await process_trace(data)
        # Acknowledge
        await redis.xack('trace_processing_queue', 'processor_group', msg_id)
```

---

### 4. Session Storage

**Pattern:** `session:{session_id}`
**Type:** Hash
**TTL:** 86400 seconds (24 hours)

```redis
# Create session
HSET session:sess_xyz user_id usr_123 workspace_id ws_456
EXPIRE session:sess_xyz 86400

# Get session data
HGETALL session:sess_xyz

# Update last activity
HSET session:sess_xyz last_activity_at 1698345600
EXPIRE session:sess_xyz 86400
```

---

### 5. Real-Time Pub/Sub

**Channels:**
- `metrics:update:{workspace_id}` - New metrics available
- `alert:new:{workspace_id}` - New alert triggered
- `trace:ingested:{workspace_id}` - New trace ingested

```redis
# Publisher (backend service)
PUBLISH metrics:update:ws_123 '{"metric":"usage","value":12345}'

# Subscriber (WebSocket service)
SUBSCRIBE metrics:update:ws_123 alert:new:ws_123

# Pattern subscription (all workspaces)
PSUBSCRIBE metrics:update:*
```

---

## Indexes & Performance

### Critical Indexes

#### TimescaleDB (Traces)
```sql
-- Most important: workspace + time queries
CREATE INDEX idx_traces_workspace_timestamp ON traces(workspace_id, timestamp DESC);
CREATE INDEX idx_traces_agent_timestamp ON traces(agent_id, timestamp DESC);

-- User and session queries
CREATE INDEX idx_traces_user ON traces(user_id);
CREATE INDEX idx_traces_session ON traces(session_id);

-- Error queries (partial index)
CREATE INDEX idx_traces_status ON traces(status) WHERE status = 'error';

-- JSONB metadata search
CREATE INDEX idx_traces_metadata ON traces USING GIN (metadata);
```

#### PostgreSQL (Metadata)
```sql
-- Workspace isolation
CREATE INDEX idx_users_workspace ON users(workspace_id);
CREATE INDEX idx_agents_workspace ON agents(workspace_id);
CREATE INDEX idx_guardrail_rules_workspace ON guardrail_rules(workspace_id);
CREATE INDEX idx_alert_rules_workspace ON alert_rules(workspace_id);

-- Lookup indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_agents_agent_id ON agents(agent_id);

-- Time-based queries
CREATE INDEX idx_guardrail_violations_occurred_at ON guardrail_violations(occurred_at DESC);
CREATE INDEX idx_alert_notifications_triggered_at ON alert_notifications(triggered_at DESC);
```

### Query Optimization Tips

**Use time_bucket for aggregations:**
```sql
SELECT
    time_bucket('1 hour', timestamp) AS hour,
    COUNT(*) AS request_count
FROM traces
WHERE workspace_id = 'ws_123'
    AND timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY hour;
```

**Use continuous aggregates for pre-computed metrics:**
```sql
-- Fast (uses pre-computed hourly_metrics)
SELECT * FROM hourly_metrics
WHERE hour >= NOW() - INTERVAL '7 days'
    AND workspace_id = 'ws_123';

-- Slow (computes on the fly)
SELECT COUNT(*) FROM traces
WHERE timestamp >= NOW() - INTERVAL '7 days'
    AND workspace_id = 'ws_123';
```

**Leverage compression:**
```sql
-- Manually compress chunks (automatic via policy)
SELECT compress_chunk(i) FROM show_chunks('traces') i;

-- Check compression status
SELECT * FROM timescaledb_information.chunks
WHERE hypertable_name = 'traces';
```

---

## Data Retention Policies

### Automatic Retention (TimescaleDB)

```sql
-- Traces: 30 days
SELECT add_retention_policy('traces', INTERVAL '30 days');

-- Check retention policies
SELECT * FROM timescaledb_information.jobs
WHERE proc_name = 'policy_retention';
```

### Manual Cleanup (PostgreSQL)

```sql
-- Clean up old resolved alerts (90 days)
DELETE FROM alert_notifications
WHERE status = 'resolved'
    AND resolved_at < NOW() - INTERVAL '90 days';

-- Archive old evaluations (1 year)
DELETE FROM evaluations
WHERE evaluated_at < NOW() - INTERVAL '1 year';
```

### Backup Strategy

**Daily backups:**
```bash
# TimescaleDB (time-series)
pg_dump -h localhost -p 5432 -U postgres -Fc agent_observability > backup_timescale_$(date +%Y%m%d).dump

# PostgreSQL (metadata)
pg_dump -h localhost -p 5433 -U postgres -Fc agent_observability_metadata > backup_postgres_$(date +%Y%m%d).dump
```

**Restore:**
```bash
# TimescaleDB
pg_restore -h localhost -p 5432 -U postgres -d agent_observability backup_timescale_20251026.dump

# PostgreSQL
pg_restore -h localhost -p 5433 -U postgres -d agent_observability_metadata backup_postgres_20251026.dump
```

---

## Migration Guide

### Initial Setup

```bash
# 1. Start Docker containers
docker-compose up -d

# 2. Wait for databases to initialize
sleep 10

# 3. Verify connections
docker-compose exec timescaledb psql -U postgres -d agent_observability -c "SELECT version();"
docker-compose exec postgres psql -U postgres -d agent_observability_metadata -c "SELECT version();"

# 4. Check TimescaleDB extension
docker-compose exec timescaledb psql -U postgres -d agent_observability -c "SELECT extname, extversion FROM pg_extension WHERE extname = 'timescaledb';"
```

### Manual Migration (if needed)

**TimescaleDB:**
```sql
-- Connect
docker-compose exec timescaledb psql -U postgres -d agent_observability

-- Load schema
\i /docker-entrypoint-initdb.d/timescale_init.sql

-- Verify hypertables
SELECT hypertable_name FROM timescaledb_information.hypertables;
```

**PostgreSQL:**
```sql
-- Connect
docker-compose exec postgres psql -U postgres -d agent_observability_metadata

-- Load schema
\i /docker-entrypoint-initdb.d/postgres_init.sql

-- List tables
\dt
```

### Schema Changes (Future)

For schema changes, use Alembic migrations:

```python
# Example migration
from alembic import op
import sqlalchemy as sa

def upgrade():
    op.add_column('agents',
        sa.Column('new_field', sa.String(255), nullable=True)
    )

def downgrade():
    op.drop_column('agents', 'new_field')
```

---

## Query Examples

### Common Queries

**Get traces for workspace in last 24 hours:**
```sql
SELECT trace_id, agent_id, timestamp, latency_ms, status
FROM traces
WHERE workspace_id = '37160be9-7d69-43b5-8d5f-9d7b5e14a57a'
    AND timestamp >= NOW() - INTERVAL '24 hours'
ORDER BY timestamp DESC
LIMIT 100;
```

**Get hourly metrics:**
```sql
SELECT
    hour,
    agent_id,
    total_requests,
    unique_users,
    latency_p95,
    error_rate
FROM hourly_metrics
WHERE workspace_id = '37160be9-7d69-43b5-8d5f-9d7b5e14a57a'
    AND hour >= NOW() - INTERVAL '7 days'
ORDER BY hour DESC;
```

**Get cost breakdown by model:**
```sql
SELECT
    model,
    SUM(total_cost) AS total_spend,
    SUM(total_tokens) AS total_tokens,
    SUM(total_requests) AS total_requests
FROM daily_metrics
WHERE workspace_id = '37160be9-7d69-43b5-8d5f-9d7b5e14a57a'
    AND day >= NOW() - INTERVAL '30 days'
GROUP BY model
ORDER BY total_spend DESC;
```

**Get active alerts:**
```sql
SELECT
    an.title,
    an.severity,
    an.current_value,
    an.threshold_value,
    an.triggered_at,
    ar.name AS rule_name
FROM alert_notifications an
JOIN alert_rules ar ON an.rule_id = ar.id
WHERE an.workspace_id = '37160be9-7d69-43b5-8d5f-9d7b5e14a57a'
    AND an.status = 'open'
ORDER BY an.triggered_at DESC;
```

**Get guardrail violations:**
```sql
SELECT
    gv.occurred_at,
    gv.severity,
    gv.action_taken,
    gr.name AS guardrail_name,
    gv.trace_id
FROM guardrail_violations gv
JOIN guardrail_rules gr ON gv.guardrail_id = gr.id
WHERE gv.workspace_id = '37160be9-7d69-43b5-8d5f-9d7b5e14a57a'
    AND gv.occurred_at >= NOW() - INTERVAL '7 days'
ORDER BY gv.occurred_at DESC
LIMIT 100;
```

---

## Summary

**Database Architecture:**
- TimescaleDB for time-series data (traces, metrics)
- PostgreSQL for relational data (metadata)
- Redis for caching and real-time updates

**Performance Features:**
- Automatic time-based partitioning
- Continuous aggregates for fast queries
- Compression for older data (7 days+)
- Automatic retention policies
- Strategic indexes on hot paths
- Multi-tier Redis caching

**Data Retention:**
- Traces: 30 days
- Hourly metrics: Computed from traces
- Daily metrics: 1 year
- Metadata: Permanent (except archived items)

**Scalability:**
- Handles millions of traces per day
- Sub-second query performance with continuous aggregates
- Horizontal scaling via TimescaleDB distributed hypertables (future)

For API integration details, see [API_REFERENCE.md](API_REFERENCE.md).
For system architecture, see [ARCHITECTURE.md](ARCHITECTURE.md).
