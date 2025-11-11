# Database Schema Design
## AI Agent Observability Platform

**Stack:** TimescaleDB | PostgreSQL 15 | Redis 7
**Last Updated:** October 2025
**Status:** Development Specification

---

## Table of Contents

1. [Database Architecture](#database-architecture)
2. [TimescaleDB Schema (Time-Series)](#timescaledb-schema)
3. [PostgreSQL Schema (Relational)](#postgresql-schema)
4. [Redis Data Structures](#redis-data-structures)
5. [Indexes & Performance](#indexes--performance)
6. [Data Retention Policies](#data-retention-policies)
7. [Migration Strategy](#migration-strategy)

---

## Database Architecture

### Three-Database Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                      TimescaleDB                            │
│              Time-Series Metrics (Hot Storage)              │
│                                                             │
│  • Traces (hypertable, 30d retention)                      │
│  • Usage Metrics (1 year retention)                        │
│  • Cost Metrics (1 year retention)                         │
│  • Performance Metrics (90d retention)                     │
│  • Safety Metrics (1 year retention)                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     PostgreSQL                              │
│              Relational Data (Persistent)                   │
│                                                             │
│  • Workspaces, Users, Teams                                │
│  • Agents, Guardrails, Alerts                              │
│  • Evaluations, Datasets, Goals                            │
│  • Feedback, Reports                                        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                        Redis                                │
│              Cache & Real-Time (Volatile)                   │
│                                                             │
│  • Query result cache (TTL: 1-60 min)                      │
│  • Real-time pub/sub (metrics, alerts)                     │
│  • Rate limiting counters                                   │
│  • Session storage                                          │
│  • Task queues (Redis Streams)                             │
└─────────────────────────────────────────────────────────────┘
```

---

## TimescaleDB Schema

TimescaleDB extends PostgreSQL with time-series optimizations using hypertables.

### 1. Traces (Hypertable)

Primary table for storing all agent traces with automatic time-based partitioning.

```sql
-- Create extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Traces table
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

### 2. Usage Metrics (Hypertable)

Aggregated usage metrics for fast queries.

```sql
CREATE TABLE usage_metrics (
    timestamp TIMESTAMPTZ NOT NULL,
    workspace_id UUID NOT NULL,
    agent_id VARCHAR(128) NOT NULL,

    -- Aggregated metrics
    total_requests INTEGER DEFAULT 0,
    unique_users INTEGER DEFAULT 0,
    unique_sessions INTEGER DEFAULT 0,

    -- Geographic distribution
    geography VARCHAR(64), -- country code or region

    -- Time bucket (for pre-aggregation)
    bucket_interval VARCHAR(16) DEFAULT '1h', -- 1h, 1d, 1w

    PRIMARY KEY (timestamp, workspace_id, agent_id, geography)
);

SELECT create_hypertable('usage_metrics', 'timestamp',
    chunk_time_interval => INTERVAL '7 days',
    if_not_exists => TRUE
);

-- Continuous aggregate for hourly metrics
CREATE MATERIALIZED VIEW usage_metrics_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', timestamp) AS hour,
    workspace_id,
    agent_id,
    COUNT(*) AS total_requests,
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(DISTINCT session_id) AS unique_sessions
FROM traces
GROUP BY hour, workspace_id, agent_id
WITH NO DATA;

-- Refresh policy (refresh every 15 minutes)
SELECT add_continuous_aggregate_policy('usage_metrics_hourly',
    start_offset => INTERVAL '1 day',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '15 minutes'
);
```

### 3. Cost Metrics (Hypertable)

Cost tracking with model-level granularity.

```sql
CREATE TABLE cost_metrics (
    timestamp TIMESTAMPTZ NOT NULL,
    workspace_id UUID NOT NULL,
    agent_id VARCHAR(128) NOT NULL,
    model VARCHAR(64) NOT NULL,

    -- Cost breakdown
    cost_prompt_usd DECIMAL(10, 6) DEFAULT 0,
    cost_completion_usd DECIMAL(10, 6) DEFAULT 0,
    cost_total_usd DECIMAL(10, 6) DEFAULT 0,

    -- Token usage
    tokens_prompt INTEGER DEFAULT 0,
    tokens_completion INTEGER DEFAULT 0,
    tokens_total INTEGER DEFAULT 0,

    -- Request count
    request_count INTEGER DEFAULT 0,

    PRIMARY KEY (timestamp, workspace_id, agent_id, model)
);

SELECT create_hypertable('cost_metrics', 'timestamp',
    chunk_time_interval => INTERVAL '7 days'
);

-- Continuous aggregate for daily cost
CREATE MATERIALIZED VIEW cost_metrics_daily
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', timestamp) AS day,
    workspace_id,
    agent_id,
    model,
    SUM(cost_total_usd) AS total_cost,
    SUM(tokens_total) AS total_tokens,
    SUM(request_count) AS total_requests
FROM cost_metrics
GROUP BY day, workspace_id, agent_id, model
WITH NO DATA;

SELECT add_continuous_aggregate_policy('cost_metrics_daily',
    start_offset => INTERVAL '7 days',
    end_offset => INTERVAL '1 day',
    schedule_interval => INTERVAL '1 hour'
);
```

### 4. Performance Metrics (Hypertable)

Latency, throughput, and error tracking.

```sql
CREATE TABLE performance_metrics (
    timestamp TIMESTAMPTZ NOT NULL,
    workspace_id UUID NOT NULL,
    agent_id VARCHAR(128) NOT NULL,

    -- Latency percentiles (pre-calculated for speed)
    latency_p50 INTEGER,
    latency_p90 INTEGER,
    latency_p95 INTEGER,
    latency_p99 INTEGER,
    latency_max INTEGER,
    latency_avg INTEGER,

    -- Throughput
    requests_per_minute INTEGER DEFAULT 0,

    -- Errors
    error_count INTEGER DEFAULT 0,
    error_rate DECIMAL(5, 4) DEFAULT 0, -- 0.0000 to 1.0000

    -- Specific error types
    timeout_count INTEGER DEFAULT 0,
    rate_limit_count INTEGER DEFAULT 0,
    validation_error_count INTEGER DEFAULT 0,

    PRIMARY KEY (timestamp, workspace_id, agent_id)
);

SELECT create_hypertable('performance_metrics', 'timestamp',
    chunk_time_interval => INTERVAL '7 days'
);

-- Continuous aggregate for 5-minute buckets
CREATE MATERIALIZED VIEW performance_metrics_5min
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('5 minutes', timestamp) AS bucket,
    workspace_id,
    agent_id,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY latency_ms) AS latency_p50,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY latency_ms) AS latency_p90,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY latency_ms) AS latency_p95,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY latency_ms) AS latency_p99,
    MAX(latency_ms) AS latency_max,
    AVG(latency_ms) AS latency_avg,
    COUNT(*) AS request_count,
    SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END) AS error_count,
    CAST(SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END) AS DECIMAL) / COUNT(*) AS error_rate
FROM traces
GROUP BY bucket, workspace_id, agent_id
WITH NO DATA;

SELECT add_continuous_aggregate_policy('performance_metrics_5min',
    start_offset => INTERVAL '1 day',
    end_offset => INTERVAL '5 minutes',
    schedule_interval => INTERVAL '5 minutes'
);
```

### 5. Safety Metrics (Hypertable)

Guardrail triggers and violation tracking.

```sql
CREATE TABLE safety_metrics (
    timestamp TIMESTAMPTZ NOT NULL,
    workspace_id UUID NOT NULL,
    agent_id VARCHAR(128) NOT NULL,
    guardrail_id UUID NOT NULL,

    -- Violation counts
    violation_count INTEGER DEFAULT 0,
    blocked_count INTEGER DEFAULT 0,
    redacted_count INTEGER DEFAULT 0,
    warned_count INTEGER DEFAULT 0,

    -- Severity distribution
    critical_count INTEGER DEFAULT 0,
    high_count INTEGER DEFAULT 0,
    medium_count INTEGER DEFAULT 0,
    low_count INTEGER DEFAULT 0,

    PRIMARY KEY (timestamp, workspace_id, agent_id, guardrail_id)
);

SELECT create_hypertable('safety_metrics', 'timestamp',
    chunk_time_interval => INTERVAL '7 days'
);
```

---

## PostgreSQL Schema

### 1. Workspaces

```sql
CREATE TABLE workspaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(128) UNIQUE NOT NULL,

    -- Settings
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

### 2. Users

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,

    role VARCHAR(32) DEFAULT 'member', -- admin, member, viewer

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

### 3. API Keys

```sql
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

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
```

### 4. Agents

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

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_agents_workspace ON agents(workspace_id);
CREATE INDEX idx_agents_agent_id ON agents(agent_id);
```

### 5. Guardrails

```sql
CREATE TABLE guardrails (
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

    -- Performance
    avg_latency_ms INTEGER,
    success_rate DECIMAL(5, 2),

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_guardrails_workspace ON guardrails(workspace_id);
CREATE INDEX idx_guardrails_type ON guardrails(type);
```

### 6. Violations

```sql
CREATE TABLE violations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    guardrail_id UUID NOT NULL REFERENCES guardrails(id) ON DELETE CASCADE,

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

CREATE INDEX idx_violations_workspace ON violations(workspace_id);
CREATE INDEX idx_violations_guardrail ON violations(guardrail_id);
CREATE INDEX idx_violations_trace ON violations(trace_id);
CREATE INDEX idx_violations_occurred_at ON violations(occurred_at);
```

### 7. Alerts

```sql
CREATE TABLE alert_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    name VARCHAR(255) NOT NULL,
    type VARCHAR(64) NOT NULL, -- budget_exceeded, latency_spike, error_rate_high

    -- Conditions
    threshold DECIMAL(10, 4) NOT NULL,
    comparison VARCHAR(16) DEFAULT 'greater_than', -- greater_than, less_than, equals

    -- Notification channels
    channels JSONB DEFAULT '["email"]', -- email, slack, pagerduty

    -- Status
    is_enabled BOOLEAN DEFAULT TRUE,
    severity VARCHAR(32) DEFAULT 'warning', -- critical, warning, info

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_alert_rules_workspace ON alert_rules(workspace_id);

CREATE TABLE alert_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    rule_id UUID NOT NULL REFERENCES alert_rules(id) ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,
    description TEXT,
    severity VARCHAR(32) NOT NULL,

    -- Status
    status VARCHAR(32) DEFAULT 'open', -- open, acknowledged, resolved
    acknowledged_by UUID REFERENCES users(id),
    acknowledged_at TIMESTAMPTZ,

    -- Timestamps
    triggered_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

CREATE INDEX idx_alert_instances_workspace ON alert_instances(workspace_id);
CREATE INDEX idx_alert_instances_rule ON alert_instances(rule_id);
CREATE INDEX idx_alert_instances_status ON alert_instances(status);
```

### 8. Evaluations

```sql
CREATE TABLE evaluations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    agent_id VARCHAR(128) NOT NULL,
    dataset_id UUID REFERENCES datasets(id),

    -- Configuration
    dimensions JSONB DEFAULT '["accuracy", "relevance", "helpfulness"]',
    evaluator VARCHAR(64) DEFAULT 'gemini', -- gemini, custom

    -- Results
    status VARCHAR(32) DEFAULT 'running', -- running, completed, failed
    overall_score DECIMAL(5, 2),

    test_cases_total INTEGER,
    test_cases_passed INTEGER,
    test_cases_failed INTEGER,

    results JSONB DEFAULT '[]',

    -- Timestamps
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX idx_evaluations_workspace ON evaluations(workspace_id);
CREATE INDEX idx_evaluations_agent ON evaluations(agent_id);
CREATE INDEX idx_evaluations_status ON evaluations(status);
```

### 9. Datasets

```sql
CREATE TABLE datasets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- Test cases
    test_cases JSONB DEFAULT '[]',
    test_case_count INTEGER DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_datasets_workspace ON datasets(workspace_id);
```

### 10. Feedback

```sql
CREATE TABLE feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    trace_id VARCHAR(64) NOT NULL,
    agent_id VARCHAR(128) NOT NULL,
    user_id VARCHAR(128),

    -- Feedback
    rating INTEGER CHECK (rating BETWEEN 1 AND 5), -- 1-5 stars or NULL
    thumbs_up BOOLEAN, -- thumbs up/down or NULL
    comment TEXT,

    -- Sentiment (auto-calculated)
    sentiment VARCHAR(32), -- positive, neutral, negative

    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_feedback_workspace ON feedback(workspace_id);
CREATE INDEX idx_feedback_agent ON feedback(agent_id);
CREATE INDEX idx_feedback_trace ON feedback(trace_id);
CREATE INDEX idx_feedback_sentiment ON feedback(sentiment);
```

### 11. Goals

```sql
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,
    description TEXT,

    -- Goal metrics
    metric_type VARCHAR(64) NOT NULL, -- reduce_tickets, increase_conversion, etc.
    baseline DECIMAL(10, 2) NOT NULL,
    target DECIMAL(10, 2) NOT NULL,
    current DECIMAL(10, 2),

    -- Deadline
    deadline DATE,

    -- Status
    status VARCHAR(32) DEFAULT 'in_progress', -- in_progress, completed, failed

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_goals_workspace ON goals(workspace_id);
CREATE INDEX idx_goals_status ON goals(status);
```

### 12. Reports (Gemini-generated)

```sql
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    type VARCHAR(64) NOT NULL, -- usage_summary, cost_optimization, stakeholder_report
    title VARCHAR(255) NOT NULL,

    -- Content
    content TEXT NOT NULL, -- Markdown format

    -- Parameters
    date_range VARCHAR(32),
    filters JSONB DEFAULT '{}',

    -- Timestamps
    generated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reports_workspace ON reports(workspace_id);
CREATE INDEX idx_reports_type ON reports(type);
```

---

## Redis Data Structures

### 1. Query Cache

```
Pattern: cache:{function_name}:{hash(params)}
Type: String
TTL: 60-3600 seconds (varies by query type)
Value: JSON-serialized query result

Example:
Key: cache:get_usage_timeseries:a1b2c3d4
Value: '{"timeseries": [...], "peak": 2345, ...}'
TTL: 300 seconds
```

### 2. Rate Limiting

```
Pattern: rate_limit:{workspace_id}:{endpoint}
Type: String (counter)
TTL: 60 seconds (1-minute window)
Value: Request count

Example:
Key: rate_limit:ws_123:api_traces
Value: 234
TTL: 60 seconds

Commands:
INCR rate_limit:ws_123:api_traces
EXPIRE rate_limit:ws_123:api_traces 60
GET rate_limit:ws_123:api_traces
```

### 3. Real-Time Pub/Sub

```
Channels:
- metrics:update - New metrics available
- alert:new - New alert triggered
- trace:ingested - New trace ingested

Example:
PUBLISH metrics:update '{"workspace_id": "ws_123", "metric": "usage"}'

Subscriber (WebSocket service):
SUBSCRIBE metrics:update alert:new
```

### 4. Task Queue (Redis Streams)

```
Stream: trace_queue
Consumer Group: processor_group

Producer:
XADD trace_queue * trace '{"trace_id": "tr_abc", ...}'

Consumer:
XREADGROUP GROUP processor_group consumer1 STREAMS trace_queue >
XACK trace_queue processor_group message_id
```

### 5. Session Storage

```
Pattern: session:{session_id}
Type: Hash
TTL: 86400 seconds (24 hours)

Example:
Key: session:sess_xyz
Fields:
  user_id: usr_123
  workspace_id: ws_456
  created_at: 1698345600

Commands:
HSET session:sess_xyz user_id usr_123
HGETALL session:sess_xyz
EXPIRE session:sess_xyz 86400
```

### 6. Gemini Response Cache

```
Pattern: gemini_cache:{prompt_hash}
Type: String
TTL: 86400 seconds (24 hours)
Value: JSON-serialized Gemini response

Example:
Key: gemini_cache:h5g7j8k9
Value: '{"insights": "Key findings...", "generated_at": "..."}'
TTL: 86400 seconds
```

---

## Indexes & Performance

### Critical Indexes

```sql
-- Traces table (most queried)
CREATE INDEX idx_traces_workspace_timestamp ON traces(workspace_id, timestamp DESC);
CREATE INDEX idx_traces_agent_timestamp ON traces(agent_id, timestamp DESC);
CREATE INDEX idx_traces_user ON traces(user_id);
CREATE INDEX idx_traces_session ON traces(session_id);
CREATE INDEX idx_traces_status ON traces(status) WHERE status = 'error';

-- GIN index for JSONB metadata search
CREATE INDEX idx_traces_metadata ON traces USING GIN (metadata);

-- Violations
CREATE INDEX idx_violations_workspace_occurred ON violations(workspace_id, occurred_at DESC);

-- Feedback
CREATE INDEX idx_feedback_workspace_created ON feedback(workspace_id, created_at DESC);

-- Alert instances
CREATE INDEX idx_alert_instances_workspace_triggered ON alert_instances(workspace_id, triggered_at DESC);
```

### Query Optimization Tips

```sql
-- Use time_bucket for aggregations
SELECT
    time_bucket('1 hour', timestamp) AS hour,
    COUNT(*) AS request_count
FROM traces
WHERE workspace_id = 'ws_123'
    AND timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY hour;

-- Use continuous aggregates for pre-computed metrics
SELECT * FROM usage_metrics_hourly
WHERE hour >= NOW() - INTERVAL '7 days';

-- Leverage compression for older data
SELECT compress_chunk(i) FROM show_chunks('traces') i;
```

---

## Data Retention Policies

### TimescaleDB Automatic Retention

```sql
-- Traces: 30 days
SELECT add_retention_policy('traces', INTERVAL '30 days');

-- Performance metrics: 90 days
SELECT add_retention_policy('performance_metrics', INTERVAL '90 days');

-- Cost metrics: 1 year
SELECT add_retention_policy('cost_metrics', INTERVAL '365 days');

-- Usage metrics: 1 year
SELECT add_retention_policy('usage_metrics', INTERVAL '365 days');

-- Safety metrics: 1 year
SELECT add_retention_policy('safety_metrics', INTERVAL '365 days');
```

### PostgreSQL Manual Cleanup

```sql
-- Clean up old alert instances (resolved > 90 days ago)
DELETE FROM alert_instances
WHERE status = 'resolved'
    AND resolved_at < NOW() - INTERVAL '90 days';

-- Archive old evaluations (> 1 year)
-- Move to cold storage or delete
DELETE FROM evaluations
WHERE completed_at < NOW() - INTERVAL '1 year';
```

---

## Migration Strategy

### Initial Setup

```bash
# 1. Install TimescaleDB extension
psql -U postgres -c "CREATE EXTENSION timescaledb;"

# 2. Create databases
psql -U postgres -c "CREATE DATABASE metrics;"
psql -U postgres -c "CREATE DATABASE observability;"

# 3. Run migrations
alembic upgrade head
```

### Alembic Migration Example

```python
# alembic/versions/001_create_traces_table.py
from alembic import op
import sqlalchemy as sa

def upgrade():
    # Create traces table
    op.execute("""
        CREATE TABLE traces (
            id BIGSERIAL,
            trace_id VARCHAR(64) NOT NULL UNIQUE,
            workspace_id UUID NOT NULL,
            timestamp TIMESTAMPTZ NOT NULL,
            ...
            PRIMARY KEY (timestamp, trace_id)
        );
    """)

    # Convert to hypertable
    op.execute("""
        SELECT create_hypertable('traces', 'timestamp',
            chunk_time_interval => INTERVAL '1 day'
        );
    """)

def downgrade():
    op.execute("DROP TABLE traces;")
```

### Zero-Downtime Migrations

```python
# For adding columns
def upgrade():
    # Add column with default (non-blocking)
    op.add_column('agents',
        sa.Column('max_tokens', sa.Integer, default=1000)
    )

    # Backfill in batches to avoid locks
    op.execute("""
        UPDATE agents
        SET max_tokens = 1000
        WHERE max_tokens IS NULL;
    """)

    # Make NOT NULL after backfill
    op.alter_column('agents', 'max_tokens',
        nullable=False
    )
```

---

## Summary

This database design provides:

**TimescaleDB (Time-Series):**
- Traces, Usage, Cost, Performance, Safety metrics
- Automatic partitioning and compression
- Continuous aggregates for fast queries
- Retention policies for automatic cleanup

**PostgreSQL (Relational):**
- Workspaces, Users, Agents, Guardrails
- Evaluations, Datasets, Feedback, Goals
- Alerts, Reports, Violations
- Full ACID compliance

**Redis (Cache & Real-Time):**
- Query result caching (1-60 min TTL)
- Rate limiting counters
- Real-time pub/sub for live updates
- Task queues for async processing
- Session storage

**Performance Features:**
- Strategic indexes on hot paths
- Continuous aggregates for pre-computed metrics
- Compression for older data
- Partitioning by time for scalability

**Next:** Review integration-strategies.md for SDK and telemetry integration approaches.
