# Database Schema Conventions

**Purpose**: Standard patterns for database design, naming, and migrations
**Version**: 1.0
**Last Updated**: October 27, 2025
**Status**: Blueprint for Enterprise Release

---

## Table of Contents

1. [Table Naming Conventions](#table-naming-conventions)
2. [Column Naming Standards](#column-naming-standards)
3. [Standard Columns Template](#standard-columns-template)
4. [Index Naming Patterns](#index-naming-patterns)
5. [JSON Column Usage](#json-column-usage)
6. [Continuous Aggregates (TimescaleDB)](#continuous-aggregates-timescaledb)
7. [Migration Safety Rules](#migration-safety-rules)
8. [Foreign Key Conventions](#foreign-key-conventions)

---

## Table Naming Conventions

### Entity Tables

**Pattern**: Singular nouns

```sql
-- ✅ CORRECT
CREATE TABLE agent (...);
CREATE TABLE user (...);
CREATE TABLE trace (...);
CREATE TABLE workspace (...);

-- ❌ WRONG
CREATE TABLE agents (...);
CREATE TABLE users (...);
```

### Junction Tables (Many-to-Many)

**Pattern**: Plural nouns or `{entity1}_{entity2}`

```sql
-- ✅ CORRECT
CREATE TABLE workspace_members (...);
CREATE TABLE user_roles (...);
CREATE TABLE agent_tags (...);
```

### Descriptive Suffixes

**Pattern**: Add suffix to indicate purpose

```sql
-- Metadata extensions
CREATE TABLE agent_metadata (...);
CREATE TABLE user_preferences (...);

-- Historical/audit tables
CREATE TABLE agent_history (...);
CREATE TABLE config_versions (...);

-- Aggregated/summary tables
CREATE TABLE usage_summary (...);
CREATE TABLE cost_summary (...);

-- Continuous aggregates (TimescaleDB)
CREATE MATERIALIZED VIEW traces_hourly (...);
CREATE MATERIALIZED VIEW traces_daily (...);
```

---

## Column Naming Standards

### Case Convention

**Rule**: Always use `snake_case`

```sql
-- ✅ CORRECT
agent_id
created_at
last_deployed_at
department_code

-- ❌ WRONG
agentId
createdAt
lastDeployedAt
departmentCode
```

### Timestamp Columns

**Standard Names**:

```sql
created_at TIMESTAMPTZ DEFAULT NOW()
updated_at TIMESTAMPTZ DEFAULT NOW()
deleted_at TIMESTAMPTZ  -- For soft deletes
last_seen_at TIMESTAMPTZ
last_login_at TIMESTAMPTZ
deployed_at TIMESTAMPTZ
expires_at TIMESTAMPTZ
```

**Always use** `TIMESTAMPTZ` (with timezone), never `TIMESTAMP`

### Foreign Key Columns

**Pattern**: `{referenced_table}_id`

```sql
-- ✅ CORRECT
workspace_id UUID REFERENCES workspaces(id)
agent_id VARCHAR(128) REFERENCES agents(agent_id)
department_id UUID REFERENCES departments(id)
user_id UUID REFERENCES users(id)

-- ❌ WRONG
workspace UUID
agent VARCHAR(128)
dept_id UUID
```

### Boolean Columns

**Pattern**: Prefix with `is_` or `has_`

```sql
-- ✅ CORRECT
is_active BOOLEAN DEFAULT TRUE
is_deleted BOOLEAN DEFAULT FALSE
has_error BOOLEAN DEFAULT FALSE
is_verified BOOLEAN DEFAULT FALSE
has_permission BOOLEAN

-- ❌ WRONG
active BOOLEAN
deleted BOOLEAN
error BOOLEAN
```

### Count/Numeric Columns

**Pattern**: Be explicit about what is being counted

```sql
-- ✅ CORRECT
request_count INTEGER
error_count INTEGER
token_count INTEGER
retry_count INTEGER

-- ❌ WRONG
count INTEGER
errors INTEGER
tokens INTEGER
```

---

## Standard Columns Template

### Every Table Must Have

```sql
CREATE TABLE example_table (
    -- Primary key (UUID recommended for distributed systems)
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Multi-tenancy (CRITICAL - required for data isolation)
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,

    -- Timestamps (for audit trail)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Soft delete (optional, if needed)
    deleted_at TIMESTAMPTZ,

    -- ... other columns specific to table
);

-- Index on workspace_id (REQUIRED for multi-tenancy queries)
CREATE INDEX idx_example_table_workspace ON example_table(workspace_id);

-- Index on created_at (REQUIRED for time-based queries)
CREATE INDEX idx_example_table_created ON example_table(created_at DESC);
```

### Update Trigger for `updated_at`

```sql
-- Function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for each table
CREATE TRIGGER update_example_table_updated_at
    BEFORE UPDATE ON example_table
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

---

## Index Naming Patterns

### Standard Indexes

**Pattern**: `idx_{table}_{column(s)}`

```sql
-- Single column index
CREATE INDEX idx_traces_agent_id ON traces(agent_id);
CREATE INDEX idx_traces_timestamp ON traces(timestamp DESC);

-- Multi-column index
CREATE INDEX idx_traces_workspace_agent ON traces(workspace_id, agent_id);
CREATE INDEX idx_traces_workspace_time ON traces(workspace_id, timestamp DESC);
```

### Partial Indexes

**Pattern**: `idx_{table}_{column}_partial`

```sql
-- Index only active agents
CREATE INDEX idx_agents_active_partial
ON agents(workspace_id, agent_id)
WHERE is_active = TRUE;

-- Index only errors
CREATE INDEX idx_traces_errors_partial
ON traces(workspace_id, timestamp DESC)
WHERE status = 'error';
```

### Unique Indexes

**Pattern**: `uniq_{table}_{column(s)}`

```sql
-- Unique constraint
CREATE UNIQUE INDEX uniq_agents_workspace_agent_id
ON agents(workspace_id, agent_id);

CREATE UNIQUE INDEX uniq_users_email
ON users(email);
```

### GIN Indexes (for JSONB)

**Pattern**: `idx_{table}_{column}_gin`

```sql
-- GIN index for JSONB column
CREATE INDEX idx_traces_metadata_gin
ON traces USING GIN (metadata);

-- GIN index for array column
CREATE INDEX idx_traces_tags_gin
ON traces USING GIN (tags);
```

---

## JSON Column Usage

### When to Use JSONB

**Use JSONB for**:
- Flexible metadata (varying structure)
- Configuration settings
- Arbitrary key-value pairs
- Arrays of objects

**Don't use JSONB for**:
- Core business data (use proper columns)
- Data that needs frequent filtering
- Relationships (use foreign keys)

### JSONB Column Pattern

```sql
CREATE TABLE agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL,
    agent_id VARCHAR(128) NOT NULL,

    -- Core data as columns
    name VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Flexible data as JSONB
    metadata JSONB DEFAULT '{}',
    config JSONB DEFAULT '{}',
    tags TEXT[] DEFAULT '{}',  -- Use TEXT[] for simple arrays

    -- GIN index for JSONB queries
    CONSTRAINT agents_pkey PRIMARY KEY (id)
);

CREATE INDEX idx_agents_metadata_gin ON agents USING GIN (metadata);
CREATE INDEX idx_agents_config_gin ON agents USING GIN (config);
CREATE INDEX idx_agents_tags_gin ON agents USING GIN (tags);
```

### Querying JSONB

```sql
-- Query by JSON key
SELECT * FROM agents
WHERE metadata->>'environment' = 'production';

-- Query nested JSON
SELECT * FROM agents
WHERE config->'settings'->>'debug' = 'true';

-- Check if key exists
SELECT * FROM agents
WHERE metadata ? 'deployment_id';

-- Array contains
SELECT * FROM agents
WHERE tags @> ARRAY['production', 'critical'];
```

---

## Continuous Aggregates (TimescaleDB)

### Naming Convention

**Pattern**: `{base_table}_{granularity}`

```sql
-- Hourly aggregates
CREATE MATERIALIZED VIEW traces_hourly ...

-- Daily aggregates
CREATE MATERIALIZED VIEW traces_daily ...

-- Weekly aggregates
CREATE MATERIALIZED VIEW traces_weekly ...

-- Monthly aggregates
CREATE MATERIALIZED VIEW traces_monthly ...
```

### Standard Template

```sql
CREATE MATERIALIZED VIEW traces_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', timestamp) AS hour,
    workspace_id,
    agent_id,
    department_id,
    environment,
    version,

    -- Aggregated metrics
    COUNT(*) as trace_count,
    AVG(latency_ms) as avg_latency,
    percentile_cont(0.50) WITHIN GROUP (ORDER BY latency_ms) as p50_latency,
    percentile_cont(0.90) WITHIN GROUP (ORDER BY latency_ms) as p90_latency,
    percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms) as p95_latency,
    percentile_cont(0.99) WITHIN GROUP (ORDER BY latency_ms) as p99_latency,
    SUM(cost_usd) as total_cost,
    SUM(tokens_total) as total_tokens,
    COUNT(*) FILTER (WHERE status = 'success') as success_count,
    COUNT(*) FILTER (WHERE status = 'error') as error_count

FROM traces
GROUP BY hour, workspace_id, agent_id, department_id, environment, version;

-- Add refresh policy
SELECT add_continuous_aggregate_policy('traces_hourly',
    start_offset => INTERVAL '3 hours',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');
```

### Always Include

- **time_bucket**: Time dimension for aggregation
- **workspace_id**: Multi-tenancy dimension
- **Key dimensions**: agent_id, department_id, environment, version
- **Aggregated metrics**: COUNT, AVG, SUM, percentiles
- **Refresh policy**: Auto-update strategy

---

## Migration Safety Rules

### Rule 1: Non-Destructive Changes Only

```sql
-- ✅ SAFE: Add new column with default
ALTER TABLE traces ADD COLUMN department_id UUID REFERENCES departments(id);
ALTER TABLE traces ADD COLUMN environment VARCHAR(50) DEFAULT 'production';

-- ❌ DANGEROUS: Drop column (data loss!)
ALTER TABLE traces DROP COLUMN old_column;  -- Never do this in production!
```

### Rule 2: Make Columns Nullable First

```sql
-- Step 1: Add nullable column
ALTER TABLE traces ADD COLUMN new_field VARCHAR(100);

-- Step 2: Backfill data
UPDATE traces SET new_field = 'default_value' WHERE new_field IS NULL;

-- Step 3: Make NOT NULL (only after backfill complete)
ALTER TABLE traces ALTER COLUMN new_field SET NOT NULL;
```

### Rule 3: Always Create Backup

```bash
# Before any schema migration
pg_dump -h localhost -p 5432 -U postgres -d agent_observability \
  > backup_pre_migration_$(date +%Y%m%d_%H%M%S).sql
```

### Rule 4: Test Rollback Script

```sql
-- Migration
ALTER TABLE traces ADD COLUMN new_column VARCHAR(100);

-- Rollback (test this before running migration!)
ALTER TABLE traces DROP COLUMN new_column;
```

### Rule 5: Validate Data Integrity

```sql
-- After migration, validate:

-- 1. Row count unchanged
SELECT COUNT(*) FROM traces;  -- Should match pre-migration count

-- 2. No NULL workspace_ids (multi-tenancy)
SELECT COUNT(*) FROM traces WHERE workspace_id IS NULL;  -- Should be 0

-- 3. Foreign key integrity
SELECT COUNT(*) FROM traces t
LEFT JOIN agents a ON t.agent_id = a.agent_id
WHERE a.id IS NULL;  -- Should be 0

-- 4. No orphaned records
SELECT COUNT(*) FROM traces t
LEFT JOIN departments d ON t.department_id = d.id
WHERE t.department_id IS NOT NULL AND d.id IS NULL;  -- Should be 0
```

---

## Foreign Key Conventions

### Cascade Behavior

**Use ON DELETE CASCADE** for owned relationships:

```sql
-- Department owns agents
CREATE TABLE agents (
    ...
    department_id UUID REFERENCES departments(id) ON DELETE CASCADE
);

-- Workspace owns traces
CREATE TABLE traces (
    ...
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE
);
```

**Use ON DELETE SET NULL** for optional relationships:

```sql
-- User is optional for automated traces
CREATE TABLE traces (
    ...
    user_id UUID REFERENCES users(id) ON DELETE SET NULL
);
```

**Use ON DELETE RESTRICT** for protected relationships:

```sql
-- Don't allow deleting agent if traces exist
CREATE TABLE traces (
    ...
    agent_id UUID REFERENCES agents(id) ON DELETE RESTRICT
);
```

### Deferred Constraints

**Use DEFERRABLE for bulk operations**:

```sql
CREATE TABLE example (
    ...
    parent_id UUID REFERENCES parent(id) DEFERRABLE INITIALLY DEFERRED
);

-- Allow temporary constraint violations within transaction
BEGIN;
SET CONSTRAINTS ALL DEFERRED;
-- Insert data that temporarily violates constraints
INSERT INTO parent ...;
INSERT INTO example ...;
COMMIT;  -- Constraints checked at commit time
```

---

## Data Types Best Practices

### UUIDs vs Serial IDs

**Use UUID** when:
- Distributed system (prevents ID collisions)
- Security (non-sequential IDs)
- Merging databases

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
```

**Use SERIAL/BIGSERIAL** when:
- Single database instance
- Need sequential ordering
- Performance critical (UUIDs are larger)

```sql
id BIGSERIAL PRIMARY KEY
```

### VARCHAR vs TEXT

**Use VARCHAR(n)** when:
- Known maximum length
- Need to enforce length limit

```sql
email VARCHAR(255)
agent_id VARCHAR(128)
status VARCHAR(20)
```

**Use TEXT** when:
- Variable/unlimited length
- Large text content

```sql
description TEXT
input TEXT
output TEXT
error_message TEXT
```

### Numeric Types

```sql
-- Integer counts
request_count INTEGER
token_count BIGINT  -- Use BIGINT for large counts

-- Decimal for money (avoid floating point!)
cost_usd DECIMAL(10, 6)  -- 10 digits, 6 after decimal
budget DECIMAL(10, 2)     -- 10 digits, 2 after decimal

-- Float for scientific/approximate values
quality_score REAL
confidence DOUBLE PRECISION
```

---

## Summary

These conventions ensure:
- ✅ Consistent naming across all tables
- ✅ Multi-tenancy enforced at schema level
- ✅ Safe migrations with rollback capability
- ✅ Optimal indexing for query performance
- ✅ Proper use of JSONB for flexible data
- ✅ Continuous aggregates for fast time-series queries

All database changes must follow these patterns.

**Cross-References**:
- Query patterns: See `ARCHITECTURE_PATTERNS.md`
- API integration: See `API_CONTRACTS.md`
- Testing: See `TESTING_PATTERNS.md`

---

**Document Version**: 1.0
**Last Updated**: October 27, 2025
**Status**: Active Blueprint
