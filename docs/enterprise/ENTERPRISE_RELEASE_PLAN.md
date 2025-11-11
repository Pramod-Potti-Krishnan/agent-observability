# Enterprise Observability Platform - Phased Implementation Plan v2.0

**Document Version**: 2.0
**Created**: October 27, 2025
**Status**: Ready for Execution
**Location**: `/docs/enterprise/ENTERPRISE_RELEASE_PLAN.md`

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Gap Analysis: MVP → Enterprise](#gap-analysis-mvp--enterprise)
3. [Blueprint Architecture Documents](#blueprint-architecture-documents)
4. [Phased Implementation](#phased-implementation)
   - [Phase 0: Blueprint Creation](#phase-0-blueprint-creation--architecture-documentation)
   - [Phase 1: Database Schema Transformation](#phase-1-foundation---database-schema-transformation)
   - [Phase 2: Core Backend APIs](#phase-2-core-backend-apis---multi-agent-filtering)
   - [Phase 3: Home Dashboard Upgrade](#phase-3-frontend---multi-level-filters--home-dashboard-upgrade)
   - [Phase 4-12: Remaining Phases](#phases-4-12-summary)
5. [Cross-Session Continuity](#cross-session-continuity-mechanisms)
6. [Synthetic Data Strategy](#synthetic-data-strategy)
7. [Risk Mitigation](#risk-mitigation)
8. [Timeline Summary](#timeline-summary)

---

## Executive Summary

This plan transforms the MVP (single-agent POC with 7 basic tabs) into a comprehensive **Multi-Agent Enterprise Observability & Actionability Platform** with 11 advanced tabs, organizational context, and autonomous operations capabilities.

### Key Enhancements in v2.0

✅ **Blueprint documents** for cross-session architectural consistency
✅ **Explicit data preservation** and migration strategy
✅ **Synthetic data generation** in every phase for demo capabilities
✅ **"Previous Phase Context"** and **"Next Phase Handoff"** sections for continuity
✅ **Validation checkpoints** after each phase
✅ **Reference document structure** for Claude Code sessions

### Strategic Goals

- **Scalability**: Support 100+ agents across multiple departments, versions, and environments
- **Organizational Context**: Department-aware, team-scoped, environment-specific insights
- **Actionable Intelligence**: Move from passive monitoring to active optimization and governance
- **Autonomous Operations**: Enable self-healing, predictive optimization, and closed-loop automation
- **Business Alignment**: Direct connection between technical metrics and business outcomes
- **Demo-Ready**: Rich synthetic data at every level for compelling demonstrations

---

## Gap Analysis: MVP → Enterprise

### MVP Current State (Phases 0-4 Complete)

✅ **Infrastructure**:
- 8 microservices running (Gateway, Ingestion, Processing, Query, Evaluation, Guardrail, Alert, Gemini)
- TimescaleDB (time-series), PostgreSQL (relational), Redis (cache & streams)
- Docker Compose orchestration

✅ **7 Basic Dashboard Pages**:
1. Home Dashboard - Basic KPIs, alerts, activity
2. Usage Analytics - API calls, users
3. Cost Management - Spending tracking
4. Performance - Latency, throughput
5. Quality - Evaluation scores
6. Safety & Compliance - Guardrails, violations
7. Business Impact - ROI, goals

✅ **Data**:
- 10,000+ synthetic traces in TimescaleDB
- Basic metrics (requests, latency, cost, quality)

❌ **Missing Enterprise Features**:
- No multi-agent/fleet support
- No organizational context (departments, teams, environments)
- No version tracking or canary deployments
- No actionability features (configuration, automation, governance)
- Missing 4 tabs (Incidents, Experiments, Configuration, Automations)
- Limited synthetic data variety

### Enterprise Target State

🎯 **Multi-Agent Fleet Management**: 100+ agents across organization
🎯 **Three-Level Hierarchy**: Fleet → Filtered Subset → Agent traces
🎯 **Organizational Context**: Departments, teams, versions, environments
🎯 **11 Comprehensive Tabs**: 80+ new charts, 50+ actionable interventions
🎯 **Autonomous Operations**: Self-healing, predictive optimization
🎯 **Rich Demo Data**: Realistic multi-agent scenarios across all dimensions

### Tab Coverage Verification

**7 Existing MVP Tabs (to be upgraded)**:
1. ✅ Home Dashboard → Fleet view with multi-agent heatmaps
2. ✅ Usage Analytics → Multi-agent adoption, cohorts, intent distribution
3. ✅ Cost Management → Department budgets, provider comparison
4. ✅ Performance → SLO tracking, environment parity
5. ✅ Quality → Rubric management, version comparison
6. ✅ Safety & Compliance → Policy governance, audit trails
7. ✅ Business Impact → Department goals, ROI tracking

**4 NEW Enterprise Tabs (to be built)**:
8. ✅ Incidents & Reliability → SLO management, MTTR, postmortems
9. ✅ Experiments & Optimization → A/B testing, canary deployments
10. ✅ Configuration & Policy → Governance hub, drift detection, RBAC
11. ✅ Automations & Playbooks → Autonomous operations

**Total: 11 tabs ✅ Fully Covered**

---

## Blueprint Architecture Documents

### Purpose

These blueprints serve as the "contract" that Claude Code will reference in every session to maintain consistency across:
- API design patterns
- Database schema conventions
- Frontend component structures
- Error handling approaches
- Authentication/authorization patterns
- Testing methodologies

### Blueprint Document Structure

All blueprints stored in: `/docs/enterprise/blueprints/`

| Blueprint | Purpose | Primary Users |
|-----------|---------|--------------|
| **ARCHITECTURE_PATTERNS.md** | Service communication, caching, state management, multi-tenancy | All phases |
| **COMPONENT_LIBRARY.md** | Frontend component contracts and reusable patterns | Phases 3-12 |
| **DATABASE_CONVENTIONS.md** | Schema design, naming conventions, index patterns | Phases 1, 8-11 |
| **API_CONTRACTS.md** | Endpoint naming, response envelopes, error formats | Phases 2-12 |
| **ACTION_IMPLEMENTATION_PLAYBOOK.md** | Step-by-step action implementation pattern | Phases 3-12 (all actions) |
| **TESTING_PATTERNS.md** | Unit, integration, E2E test templates | All phases |
| **PHASE_CHECKLIST_TEMPLATE.md** | Completion criteria for each phase | All phases |

---

## Phased Implementation

---

## **PHASE 0: Blueprint Creation & Architecture Documentation**

**Duration**: 1 session
**Priority**: P0
**Token Estimate**: 25K

### Goals

Create comprehensive reference documents that ensure architectural consistency across all subsequent phases. These blueprints are the foundation for cross-session continuity.

### Why This Matters

- **Consistency**: Every Claude Code session references the same patterns
- **Efficiency**: No need to re-explain architectural decisions
- **Quality**: Proven patterns reduce bugs and inconsistencies
- **Scalability**: New developers/sessions can onboard quickly

### Deliverables

#### 1. **ARCHITECTURE_PATTERNS.md**

**Location**: `docs/enterprise/blueprints/ARCHITECTURE_PATTERNS.md`

**Contents**:
```markdown
# Architecture Patterns Reference

## Service Communication Patterns
- Gateway proxying rules (URL rewriting, header forwarding)
- Service-to-service authentication (JWT validation)
- Timeout and retry policies (30s timeout, 3 retries with exponential backoff)
- Error propagation (preserve error context across services)

## Database Query Patterns
- TimescaleDB continuous aggregate templates
- Multi-tenant filtering (ALWAYS include workspace_id)
- Pagination patterns (LIMIT + OFFSET with total count)
- Index usage guidelines (covering indexes for common queries)

## Caching Strategy
- Redis key naming: `{domain}:{workspace_id}:{scope}:{identifier}`
- TTL policies: Hot (30s), Warm (5min), Cold (30min)
- Cache invalidation patterns (pattern-based deletion)
- Cache-aside pattern (check cache → DB → set cache)

## State Management (Frontend)
- React Context for global state (auth, workspace, filters)
- TanStack Query for server state (automatic caching, refetching)
- URL query params for shareable state (filters, time range)
- localStorage for user preferences (theme, default view)

## Multi-Tenancy Enforcement
- Every DB query MUST filter by workspace_id
- Every API endpoint MUST validate workspace_id from JWT or header
- Every trace/log MUST include workspace_id for isolation
- Row-level security patterns for PostgreSQL

## Error Handling
- Standard error codes (INSUFFICIENT_PERMISSIONS, RESOURCE_NOT_FOUND, etc.)
- Error context preservation across service boundaries
- User-friendly error messages vs technical details
- Error logging with request_id for tracing
```

#### 2. **COMPONENT_LIBRARY.md**

**Location**: `docs/enterprise/blueprints/COMPONENT_LIBRARY.md`

**Contents**:
```markdown
# Frontend Component Library Contracts

## KPICard Component
**File**: `frontend/components/dashboard/KPICard.tsx`

**Props**:
```typescript
interface KPICardProps {
  title: string
  value: string | number
  change: number
  changeLabel: string
  trend?: 'normal' | 'inverse'
  sparklineData?: Array<{timestamp: string, value: number}>
  onClick?: () => void
  departmentBreakdown?: Array<{dept: string, value: number}>
}
```

**Behavior**:
- Green up arrow for positive change (or negative if trend='inverse')
- Hover shows department breakdown if provided
- Click navigates to detail view if onClick provided
- Sparkline embedded in footer if data provided

## FilterBar Component
**File**: `frontend/components/shared/FilterBar.tsx`

**Props**:
```typescript
interface FilterConfig {
  timeRange: string
  department?: string
  environment?: string
  version?: string
}
```

**State Management**:
- URL sync: `useSearchParams()` for shareable links
- localStorage sync: Save last used filters per page
- Global context: React Context for cross-component access

## DrilldownModal Component
**File**: `frontend/components/shared/DrilldownModal.tsx`

**Purpose**: Unified trace viewer with full context
**Sections**: Request metadata, Timeline, Step details, Costs, Quality scores

## Chart Wrapper Patterns
- Recharts for standard charts (line, bar, area, pie)
- D3 for custom visualizations (heatmaps, sankey, force graphs)
- Consistent color palette (use theme colors)
- Loading skeleton with same dimensions as chart
- Error boundary with retry capability
```

#### 3. **DATABASE_CONVENTIONS.md**

**Location**: `docs/enterprise/blueprints/DATABASE_CONVENTIONS.md`

**Contents**:
```markdown
# Database Schema Conventions

## Table Naming
- Singular nouns for entities: `agent`, `user`, `trace`
- Plural for junction tables: `workspace_members`
- Descriptive suffixes: `_metadata`, `_history`, `_summary`

## Column Naming
- snake_case always
- Timestamps: `created_at`, `updated_at`, `deleted_at`
- Foreign keys: `{table}_id` (e.g., `workspace_id`, `agent_id`)
- Booleans: `is_{adjective}` or `has_{noun}` (e.g., `is_active`, `has_error`)

## Standard Columns (include in every table)
```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
created_at TIMESTAMPTZ DEFAULT NOW(),
updated_at TIMESTAMPTZ DEFAULT NOW()
```

## Index Naming
- `idx_{table}_{column(s)}` for regular indexes
- `idx_{table}_{column}_partial` for partial indexes
- Always index: workspace_id, created_at, foreign keys

## JSON Columns
- Use JSONB (not JSON) for performance
- Index with GIN: `CREATE INDEX idx_{table}_{column}_gin ON {table} USING GIN ({column});`
- Store flexible metadata, not core data

## Continuous Aggregates (TimescaleDB)
- Name: `{table}_{granularity}` (e.g., `traces_hourly`, `traces_daily`)
- Always include: time_bucket, workspace_id, aggregation dimensions
- Refresh policy: INTERVAL '1 hour' for hourly, '1 day' for daily

## Migration Safety
- Always use non-destructive migrations (ADD COLUMN, not DROP)
- Set defaults for new columns to maintain backward compatibility
- Create backup before schema changes
- Test rollback scripts before applying migrations
```

#### 4. **API_CONTRACTS.md**

**Location**: `docs/enterprise/blueprints/API_CONTRACTS.md`

**Contents**:
```markdown
# API Design Contracts

## Endpoint Naming
- RESTful: `/api/v1/{resource}/{action}`
- Collections: GET /api/v1/agents
- Single resource: GET /api/v1/agents/{agent_id}
- Actions: POST /api/v1/agents/{agent_id}/pause

## Query Parameters (Standard)
- `workspace_id`: UUID (validated against JWT)
- `range`: 1h | 24h | 7d | 30d | 90d | custom
- `department`: Department filter
- `environment`: production | staging | development
- `version`: Version filter
- `page`: Page number (1-indexed)
- `limit`: Page size (default 50, max 1000)

## Response Envelope (Standard)
```json
{
  "data": [...],
  "meta": {
    "total": 1234,
    "page": 1,
    "limit": 50,
    "has_more": true
  },
  "filters_applied": {
    "workspace_id": "...",
    "range": "24h",
    "department": "engineering"
  }
}
```

## Error Response (Standard)
```json
{
  "error": {
    "code": "INSUFFICIENT_PERMISSIONS",
    "message": "User does not have permission to access this resource",
    "details": {...},
    "timestamp": "2025-10-27T10:00:00Z",
    "request_id": "req_abc123"
  }
}
```

## Authentication Headers
- `Authorization: Bearer {jwt_token}` (for user auth)
- `X-API-Key: {api_key}` (for service auth)
- `X-Workspace-ID: {workspace_id}` (workspace context)

## Pagination
- Use LIMIT/OFFSET for small datasets (< 10k rows)
- Use cursor-based pagination for large datasets
- Always include total count in meta
- Include has_more boolean for infinite scroll
```

#### 5. **ACTION_IMPLEMENTATION_PLAYBOOK.md**

**Location**: `docs/enterprise/blueprints/ACTION_IMPLEMENTATION_PLAYBOOK.md`

**Contents**:
```markdown
# Action Implementation Playbook

## Step-by-Step Implementation Pattern

### 1. Define Action Schema (Database)
```sql
CREATE TABLE action_audit_log (
  action_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID REFERENCES workspaces(id),
  action_type VARCHAR(100) NOT NULL,
  action_scope VARCHAR(50), -- 'fleet' | 'department' | 'agent'
  actor_user_id UUID REFERENCES users(id),
  action_params JSONB,
  status VARCHAR(20), -- 'pending' | 'in_progress' | 'completed' | 'failed' | 'rolled_back'
  result JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  rollback_action_id UUID REFERENCES action_audit_log(id)
);
```

### 2. Implement Backend API Endpoint
**File**: `backend/{service}/app/actions/{action_name}.py`

**Pattern**:
```python
@router.post("/api/v1/actions/{action_name}")
async def execute_action(
    workspace_id: UUID,
    action_params: ActionParams,
    user: User = Depends(get_current_user)
):
    # 1. Validate permissions
    if not user.can_perform_action(action_name, workspace_id):
        raise HTTPException(403, "Insufficient permissions")

    # 2. Log action initiation
    action_log = await create_action_log(
        workspace_id, action_name, action_params, user.id
    )

    # 3. Execute action with rollback capability
    try:
        result = await perform_action(action_params)
        await update_action_log(action_log.id, "completed", result)

        # 4. Trigger notifications
        await notify_stakeholders(workspace_id, action_name, result)

        # 5. Invalidate relevant caches
        await invalidate_caches(workspace_id, action_scope)

        return {"action_id": action_log.id, "result": result}
    except Exception as e:
        await update_action_log(action_log.id, "failed", {"error": str(e)})
        raise
```

### 3. Implement Frontend UI Component
**File**: `frontend/components/actions/{ActionName}Button.tsx`

**Pattern**:
```typescript
export function ActionButton({ onSuccess, onError }) {
  const [isOpen, setIsOpen] = useState(false)
  const mutation = useMutation({
    mutationFn: (params) => apiClient.post('/api/v1/actions/...', params),
    onSuccess: (data) => {
      queryClient.invalidateQueries(['related-data'])
      onSuccess?.(data)
    }
  })

  return (
    <>
      <Button onClick={() => setIsOpen(true)}>Action Name</Button>
      <ActionDialog
        open={isOpen}
        onConfirm={(params) => mutation.mutate(params)}
        onCancel={() => setIsOpen(false)}
      />
    </>
  )
}
```

### 4. Testing Checklist
- [ ] Permission validation (unauthorized user cannot execute)
- [ ] Action logged in audit trail
- [ ] Success case: Result stored, caches invalidated, notifications sent
- [ ] Failure case: Error logged, no partial state changes
- [ ] Rollback capability tested
- [ ] UI loading/error states handled
```

#### 6. **TESTING_PATTERNS.md**

**Location**: `docs/enterprise/blueprints/TESTING_PATTERNS.md`

**Contents**:
```markdown
# Testing Patterns

## Backend Unit Tests (pytest)
**File location**: `backend/{service}/tests/test_{module}.py`

**Pattern**:
```python
# API endpoint test
async def test_get_home_kpis_with_filters(client, auth_headers):
    response = await client.get(
        "/api/v1/metrics/home-kpis",
        params={"range": "24h", "department": "engineering"},
        headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert "total_requests" in data
    assert data["filters_applied"]["department"] == "engineering"

# Service logic test
async def test_calculate_department_metrics(db_session):
    result = await calculate_department_metrics(
        workspace_id=WORKSPACE_ID,
        department_id="engineering",
        time_range="24h"
    )
    assert result["request_count"] > 0
    assert "avg_latency" in result
```

## Frontend Component Tests (React Testing Library)
**File location**: `frontend/components/{component}/__tests__/{Component}.test.tsx`

**Pattern**:
```typescript
describe('KPICard', () => {
  it('renders with correct data', () => {
    render(<KPICard title="Total Requests" value="1,234" change={12.5} changeLabel="vs yesterday" />)
    expect(screen.getByText('Total Requests')).toBeInTheDocument()
    expect(screen.getByText('1,234')).toBeInTheDocument()
    expect(screen.getByText('+12.5%')).toBeInTheDocument()
  })

  it('calls onClick when clicked', () => {
    const handleClick = jest.fn()
    render(<KPICard title="Test" value="100" onClick={handleClick} />)
    fireEvent.click(screen.getByRole('button'))
    expect(handleClick).toHaveBeenCalled()
  })
})
```

## Integration Tests
**File location**: `backend/tests/integration/test_{feature}_e2e.py`

**Pattern**: Test complete workflows (UI → API → DB → UI)
```

#### 7. **PHASE_CHECKLIST_TEMPLATE.md**

**Location**: `docs/enterprise/blueprints/PHASE_CHECKLIST_TEMPLATE.md`

**Contents**:
```markdown
# Phase Completion Checklist Template

## Database Changes
- [ ] Migration script created and tested
- [ ] Indexes added for new columns
- [ ] Continuous aggregates updated
- [ ] Rollback script prepared
- [ ] Data integrity validated (no orphaned records)
- [ ] Synthetic data generated for new structures

## Backend API Changes
- [ ] New endpoints implemented with Pydantic models
- [ ] Authentication/authorization added
- [ ] Error handling comprehensive
- [ ] Caching strategy implemented
- [ ] API documentation updated (Swagger/OpenAPI)
- [ ] Unit tests written and passing

## Frontend Changes
- [ ] Components follow component library patterns
- [ ] State management consistent with architecture
- [ ] Loading states implemented
- [ ] Error boundaries in place
- [ ] Responsive design validated
- [ ] Accessibility checked (ARIA labels, keyboard nav)

## Integration
- [ ] End-to-end flow tested (UI → API → DB → UI)
- [ ] Cross-tab dependencies validated
- [ ] Cache invalidation working
- [ ] Real-time updates functioning

## Synthetic Data
- [ ] Demo scenarios created for new features
- [ ] Data variety sufficient for compelling demos
- [ ] Edge cases represented in data
- [ ] Data documented with examples

## Performance
- [ ] API response time < 200ms (P95)
- [ ] Dashboard load time < 3s
- [ ] Database queries optimized
- [ ] No N+1 query issues

## Documentation
- [ ] Phase completion summary written
- [ ] Known issues documented
- [ ] Next phase handoff prepared
```

### Acceptance Criteria for Phase 0

- [ ] All 7 blueprint documents created in `docs/enterprise/blueprints/`
- [ ] Each blueprint reviewed for completeness
- [ ] Templates validated with sample code
- [ ] Documents ready for reference in subsequent phases
- [ ] Cross-references between blueprints validated

### Next Phase Handoff

**To Phase 1**: Blueprint documents are now the authoritative reference for all architectural decisions. All database changes must follow `DATABASE_CONVENTIONS.md`. All API endpoints must follow `API_CONTRACTS.md`. Review blueprints before starting Phase 1 schema design.

---

## **PHASE 1: Foundation - Database Schema Transformation**

**Duration**: 1-2 sessions
**Priority**: P0
**Token Estimate**: 45K

### Previous Phase Context

**From Phase 0**: Blueprint documents are now available as architectural references. All database changes must follow `DATABASE_CONVENTIONS.md` patterns. Schema must preserve existing 10,000+ traces without data loss.

### Goals

1. ✅ Transform single-agent schema to multi-agent with organizational context
2. ✅ Preserve ALL existing MVP data (10,000+ traces) - **ZERO data loss**
3. ✅ Add department/environment/version dimensions to all relevant tables
4. ✅ Create new reference tables for organizational hierarchy
5. ✅ **Generate rich synthetic data** for multi-agent demo scenarios

### Sub-Agent Strategy (Parallel Execution)

- **Agent 1** (`fullstack-database-designer`): Design enhanced schema following `DATABASE_CONVENTIONS.md`
- **Agent 2** (`general-purpose`): Create migration scripts with data preservation
- **Agent 3** (`general-purpose`): Build comprehensive synthetic data generator

### Deliverables

#### 1. New Reference Tables

Following `DATABASE_CONVENTIONS.md` naming and structure:

```sql
-- Departments table
CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    department_name VARCHAR(128) NOT NULL,
    department_code VARCHAR(50) NOT NULL, -- 'engineering', 'sales', 'support'
    description TEXT,
    budget_monthly_usd DECIMAL(10,2),
    owner_user_id UUID REFERENCES users(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(workspace_id, department_code)
);

CREATE INDEX idx_departments_workspace ON departments(workspace_id);
CREATE INDEX idx_departments_code ON departments(department_code);

-- Environments table
CREATE TABLE environments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    environment_name VARCHAR(50) NOT NULL,
    environment_type VARCHAR(20) NOT NULL, -- 'prod', 'staging', 'dev', 'qa'
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(workspace_id, environment_name)
);

CREATE INDEX idx_environments_workspace ON environments(workspace_id);

-- Agent metadata extended (enhancing existing agents table)
ALTER TABLE agents ADD COLUMN department_id UUID REFERENCES departments(id);
ALTER TABLE agents ADD COLUMN environment VARCHAR(50) DEFAULT 'production';
ALTER TABLE agents ADD COLUMN version VARCHAR(50) DEFAULT 'v1.0';
ALTER TABLE agents ADD COLUMN agent_status VARCHAR(20) DEFAULT 'active'; -- 'active', 'beta', 'deprecated'
ALTER TABLE agents ADD COLUMN owner_team VARCHAR(128);
ALTER TABLE agents ADD COLUMN last_deployed_at TIMESTAMPTZ;
ALTER TABLE agents ADD COLUMN deprecation_date TIMESTAMPTZ;
ALTER TABLE agents ADD COLUMN replacement_agent_id UUID REFERENCES agents(id);

CREATE INDEX idx_agents_department ON agents(department_id);
CREATE INDEX idx_agents_environment ON agents(environment);
CREATE INDEX idx_agents_version ON agents(version);
CREATE INDEX idx_agents_status ON agents(agent_status);
```

#### 2. Enhanced Traces Table (NON-DESTRUCTIVE Migration)

**Critical**: This migration preserves ALL existing data:

```sql
-- Step 1: Add new columns (nullable initially to preserve existing data)
ALTER TABLE traces ADD COLUMN department_id UUID REFERENCES departments(id);
ALTER TABLE traces ADD COLUMN environment VARCHAR(50);
ALTER TABLE traces ADD COLUMN version VARCHAR(50);
ALTER TABLE traces ADD COLUMN agent_version VARCHAR(50);
ALTER TABLE traces ADD COLUMN intent_category VARCHAR(100);
ALTER TABLE traces ADD COLUMN user_segment VARCHAR(50); -- 'power_user', 'regular', 'new', 'dormant'

-- Step 2: Create indexes for new query patterns
CREATE INDEX idx_traces_department_id ON traces(department_id, timestamp DESC);
CREATE INDEX idx_traces_environment ON traces(environment, timestamp DESC);
CREATE INDEX idx_traces_version ON traces(version, timestamp DESC);
CREATE INDEX idx_traces_intent_category ON traces(intent_category, timestamp DESC);
CREATE INDEX idx_traces_user_segment ON traces(user_segment, timestamp DESC);

-- Step 3: Backfill existing data with intelligent defaults
-- This preserves all 10,000+ existing traces
UPDATE traces SET
    environment = 'production',
    version = 'v1.0',
    intent_category = 'general',
    user_segment = 'regular'
WHERE environment IS NULL;

-- Link to default department for existing traces
UPDATE traces t SET
    department_id = (
        SELECT d.id FROM departments d
        WHERE d.department_code = 'engineering'
        AND d.workspace_id = t.workspace_id
        LIMIT 1
    )
WHERE department_id IS NULL;

-- Validate: Count should match before and after
-- SELECT COUNT(*) FROM traces; -- Should be unchanged
```

#### 3. Data Preservation Strategy

**Migration Safety Plan**:

1. **Pre-Migration Backup**:
```bash
# Create full database backup before migration
pg_dump -h localhost -p 5432 -U postgres agent_observability > backup_pre_phase1_$(date +%Y%m%d).sql
```

2. **Non-Destructive Schema Changes**:
   - All new columns added as `NULLABLE` or with `DEFAULT` values
   - No `DROP COLUMN` operations
   - No data deletion

3. **Intelligent Backfill**:
   - Parse `agent_id` patterns to infer department:
     - "support-bot" → support department
     - "sales-agent" → sales department
     - "eng-*" → engineering department
   - Default `environment` to 'production' (safest assumption)
   - Default `version` to 'v1.0' (earliest version)

4. **Validation Queries**:
```sql
-- Verify row count unchanged
SELECT COUNT(*) FROM traces; -- Should match pre-migration count

-- Verify no NULL workspace_ids (multi-tenancy enforcement)
SELECT COUNT(*) FROM traces WHERE workspace_id IS NULL; -- Should be 0

-- Verify all traces have department assignments
SELECT COUNT(*) FROM traces WHERE department_id IS NULL; -- Should be 0 after backfill

-- Verify foreign key integrity
SELECT COUNT(*) FROM traces t
LEFT JOIN departments d ON t.department_id = d.id
WHERE t.department_id IS NOT NULL AND d.id IS NULL; -- Should be 0
```

5. **Rollback Script** (if needed):
```sql
-- Emergency rollback if migration fails
ALTER TABLE traces DROP COLUMN IF EXISTS department_id;
ALTER TABLE traces DROP COLUMN IF EXISTS environment;
ALTER TABLE traces DROP COLUMN IF EXISTS version;
ALTER TABLE traces DROP COLUMN IF EXISTS agent_version;
ALTER TABLE traces DROP COLUMN IF EXISTS intent_category;
ALTER TABLE traces DROP COLUMN IF EXISTS user_segment;

-- Restore from backup if needed:
-- psql -h localhost -p 5432 -U postgres agent_observability < backup_pre_phase1_YYYYMMDD.sql
```

#### 4. Updated Continuous Aggregates

```sql
-- Drop old aggregates (will be rebuilt with new data)
DROP MATERIALIZED VIEW IF EXISTS traces_hourly CASCADE;
DROP MATERIALIZED VIEW IF EXISTS traces_daily CASCADE;

-- Recreate with multi-agent dimensions
CREATE MATERIALIZED VIEW traces_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', timestamp) AS hour,
    workspace_id,
    agent_id,
    department_id,
    environment,
    version,
    intent_category,
    user_segment,
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
GROUP BY hour, workspace_id, agent_id, department_id, environment, version, intent_category, user_segment;

-- Add continuous aggregate refresh policy
SELECT add_continuous_aggregate_policy('traces_hourly',
    start_offset => INTERVAL '3 hours',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

-- Create daily aggregates for longer-term analysis
CREATE MATERIALIZED VIEW traces_daily
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', timestamp) AS day,
    workspace_id,
    agent_id,
    department_id,
    environment,
    version,
    COUNT(*) as trace_count,
    AVG(latency_ms) as avg_latency,
    SUM(cost_usd) as total_cost,
    COUNT(*) FILTER (WHERE status = 'success') as success_count,
    COUNT(*) FILTER (WHERE status = 'error') as error_count
FROM traces
GROUP BY day, workspace_id, agent_id, department_id, environment, version;

SELECT add_continuous_aggregate_policy('traces_daily',
    start_offset => INTERVAL '7 days',
    end_offset => INTERVAL '1 day',
    schedule_interval => INTERVAL '1 day');
```

#### 5. Synthetic Data Generator - **COMPREHENSIVE DEMO DATA**

**File**: `backend/db/synthetic_data_generator_v2.py`

This generator creates **rich, realistic multi-agent scenarios** for compelling demos:

```python
import random
import uuid
from datetime import datetime, timedelta
from faker import Faker
import asyncpg

fake = Faker()

# Configuration for realistic demo data
DEMO_CONFIG = {
    'departments': 10,
    'agents_per_department': 8-12,
    'traces_per_agent_per_day': 50-200,
    'days_of_history': 90,
    'user_count': 500,
    'environments': ['production', 'staging', 'development'],
    'versions': ['v2.1', 'v2.0', 'v1.9', 'v1.8', 'v1.7'],
    'intent_categories': [
        'customer_support', 'code_generation', 'data_analysis',
        'content_creation', 'automation', 'research', 'translation'
    ]
}

# Department definitions with realistic budgets and characteristics
DEPARTMENTS = [
    {
        'code': 'engineering',
        'name': 'Engineering',
        'budget': 50000,
        'agent_types': ['code-assistant', 'documentation-bot', 'review-helper'],
        'primary_intents': ['code_generation', 'data_analysis', 'research']
    },
    {
        'code': 'sales',
        'name': 'Sales',
        'budget': 30000,
        'agent_types': ['sales-copilot', 'lead-qualifier', 'proposal-writer'],
        'primary_intents': ['customer_support', 'content_creation', 'data_analysis']
    },
    {
        'code': 'support',
        'name': 'Customer Support',
        'budget': 25000,
        'agent_types': ['support-bot', 'ticket-classifier', 'kb-assistant'],
        'primary_intents': ['customer_support', 'research', 'translation']
    },
    {
        'code': 'marketing',
        'name': 'Marketing',
        'budget': 35000,
        'agent_types': ['content-generator', 'social-media-bot', 'analytics-assistant'],
        'primary_intents': ['content_creation', 'data_analysis', 'research']
    },
    {
        'code': 'finance',
        'name': 'Finance',
        'budget': 15000,
        'agent_types': ['expense-analyzer', 'report-generator', 'forecast-bot'],
        'primary_intents': ['data_analysis', 'automation', 'research']
    },
    {
        'code': 'hr',
        'name': 'Human Resources',
        'budget': 10000,
        'agent_types': ['onboarding-assistant', 'policy-bot', 'feedback-analyzer'],
        'primary_intents': ['customer_support', 'content_creation', 'data_analysis']
    },
    {
        'code': 'operations',
        'name': 'Operations',
        'budget': 20000,
        'agent_types': ['inventory-bot', 'logistics-optimizer', 'status-reporter'],
        'primary_intents': ['automation', 'data_analysis', 'customer_support']
    },
    {
        'code': 'product',
        'name': 'Product Management',
        'budget': 40000,
        'agent_types': ['feature-analyzer', 'roadmap-assistant', 'user-research-bot'],
        'primary_intents': ['research', 'data_analysis', 'content_creation']
    },
    {
        'code': 'data',
        'name': 'Data Science',
        'budget': 45000,
        'agent_types': ['ml-assistant', 'data-cleaner', 'viz-generator'],
        'primary_intents': ['data_analysis', 'code_generation', 'research']
    },
    {
        'code': 'legal',
        'name': 'Legal',
        'budget': 12000,
        'agent_types': ['contract-analyzer', 'compliance-checker', 'doc-reviewer'],
        'primary_intents': ['research', 'data_analysis', 'customer_support']
    }
]

async def generate_departments(conn, workspace_id):
    """Generate department records"""
    dept_ids = {}
    for dept in DEPARTMENTS:
        dept_id = await conn.fetchval("""
            INSERT INTO departments (workspace_id, department_name, department_code, budget_monthly_usd, is_active)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id
        """, workspace_id, dept['name'], dept['code'], dept['budget'], True)
        dept_ids[dept['code']] = dept_id
        print(f"Created department: {dept['name']} (ID: {dept_id})")
    return dept_ids

async def generate_agents(conn, workspace_id, dept_ids):
    """Generate 80-100 realistic agents across departments"""
    agents = []

    for dept in DEPARTMENTS:
        dept_id = dept_ids[dept['code']]
        agent_count = random.randint(8, 12)

        for i in range(agent_count):
            agent_type = random.choice(dept['agent_types'])
            version_dist = random.choices(
                DEMO_CONFIG['versions'],
                weights=[40, 30, 20, 8, 2]  # Newer versions more common
            )[0]

            env_dist = random.choices(
                DEMO_CONFIG['environments'],
                weights=[70, 20, 10]  # Production most common
            )[0]

            status_dist = random.choices(
                ['active', 'beta', 'deprecated'],
                weights=[80, 15, 5]  # Most agents active
            )[0]

            agent_id = await conn.fetchval("""
                INSERT INTO agents (
                    workspace_id, agent_id, name, description,
                    department_id, environment, version, agent_status,
                    owner_team, is_active, last_deployed_at
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
                RETURNING id
            """,
                workspace_id,
                f"{dept['code']}-{agent_type}-{i+1}",
                f"{dept['name']} {agent_type.replace('-', ' ').title()} #{i+1}",
                f"AI assistant for {dept['name']} department",
                dept_id,
                env_dist,
                version_dist,
                status_dist,
                dept['name'],
                status_dist != 'deprecated',
                datetime.now() - timedelta(days=random.randint(1, 180))
            )

            agents.append({
                'id': agent_id,
                'agent_id': f"{dept['code']}-{agent_type}-{i+1}",
                'department_code': dept['code'],
                'environment': env_dist,
                'version': version_dist,
                'status': status_dist,
                'primary_intents': dept['primary_intents']
            })

    print(f"Created {len(agents)} agents across {len(DEPARTMENTS)} departments")
    return agents

async def generate_traces(conn, workspace_id, agents, days=90):
    """
    Generate rich trace data with realistic patterns:
    - Business hours usage patterns (9am-6pm higher volume)
    - Weekend vs weekday differences
    - Version adoption curves
    - Department-specific intent distributions
    - Realistic error patterns (2-5% error rate)
    - Cost variations by model and provider
    """
    print(f"Generating {days} days of trace history...")

    start_date = datetime.now() - timedelta(days=days)
    trace_count = 0

    for day_offset in range(days):
        current_date = start_date + timedelta(days=day_offset)
        is_weekend = current_date.weekday() >= 5

        # Weekend traffic is 30% of weekday
        daily_multiplier = 0.3 if is_weekend else 1.0

        for agent in agents:
            # Skip deprecated agents after certain date
            if agent['status'] == 'deprecated':
                if day_offset < days - 30:  # Deprecated in last 30 days
                    continue

            # Production has 70% of traffic, staging 20%, dev 10%
            env_multiplier = {
                'production': 0.7,
                'staging': 0.2,
                'development': 0.1
            }[agent['environment']]

            traces_today = int(
                random.randint(50, 200) * daily_multiplier * env_multiplier
            )

            for _ in range(traces_today):
                # Realistic timestamp distribution (business hours)
                hour = random.choices(
                    range(24),
                    weights=[1,1,1,1,1,2,5,10,15,20,20,18,15,18,20,15,10,5,3,2,1,1,1,1]
                )[0]

                timestamp = current_date.replace(
                    hour=hour,
                    minute=random.randint(0, 59),
                    second=random.randint(0, 59)
                )

                # Intent selection based on department
                intent = random.choice(agent['primary_intents'])

                # Realistic latency distribution (log-normal)
                base_latency = random.lognormvariate(7, 0.5)  # Mean ~1100ms
                latency_ms = int(base_latency)

                # Status distribution (2-5% error rate)
                status_dist = random.choices(
                    ['success', 'error', 'timeout'],
                    weights=[95, 4, 1]
                )[0]

                # Model selection based on version
                if agent['version'] in ['v2.1', 'v2.0']:
                    model = random.choice(['gpt-4-turbo', 'claude-3-sonnet', 'gemini-pro'])
                else:
                    model = random.choice(['gpt-3.5-turbo', 'claude-2', 'gemini-1.0-pro'])

                # Realistic token counts
                tokens_input = random.randint(50, 500)
                tokens_output = random.randint(100, 1000)
                tokens_total = tokens_input + tokens_output

                # Cost calculation (realistic pricing)
                cost_per_1k = {
                    'gpt-4-turbo': 0.01,
                    'gpt-3.5-turbo': 0.002,
                    'claude-3-sonnet': 0.015,
                    'claude-2': 0.008,
                    'gemini-pro': 0.00025,
                    'gemini-1.0-pro': 0.0001
                }[model]
                cost_usd = (tokens_total / 1000) * cost_per_1k

                # User segment distribution
                user_segment = random.choices(
                    ['power_user', 'regular', 'new', 'dormant'],
                    weights=[10, 70, 15, 5]
                )[0]

                await conn.execute("""
                    INSERT INTO traces (
                        trace_id, workspace_id, agent_id, timestamp,
                        input, output, error,
                        latency_ms, status, model, model_provider,
                        tokens_input, tokens_output, tokens_total, cost_usd,
                        department_id, environment, version, intent_category, user_segment
                    )
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
                """,
                    f"trace_{uuid.uuid4().hex[:16]}",
                    workspace_id,
                    agent['agent_id'],
                    timestamp,
                    f"Demo query for {intent}",
                    f"Demo response for {intent}" if status_dist == 'success' else None,
                    f"Error: {random.choice(['timeout', 'rate_limit', 'server_error'])}" if status_dist == 'error' else None,
                    latency_ms,
                    status_dist,
                    model,
                    model.split('-')[0],  # Extract provider
                    tokens_input,
                    tokens_output,
                    tokens_total,
                    cost_usd,
                    agent['id'],  # department_id from agent
                    agent['environment'],
                    agent['version'],
                    intent,
                    user_segment
                )

                trace_count += 1

                if trace_count % 10000 == 0:
                    print(f"Generated {trace_count} traces...")

    print(f"✅ Total traces generated: {trace_count}")
    return trace_count

async def main():
    """Main synthetic data generation orchestrator"""
    conn = await asyncpg.connect(
        host='localhost',
        port=5432,
        user='postgres',
        password='postgres',
        database='agent_observability'
    )

    try:
        # Get workspace_id (assuming single workspace for demo)
        workspace_id = await conn.fetchval("SELECT id FROM workspaces LIMIT 1")

        if not workspace_id:
            print("No workspace found! Creating demo workspace...")
            workspace_id = await conn.fetchval("""
                INSERT INTO workspaces (name, slug, plan, is_active)
                VALUES ('Demo Organization', 'demo-org', 'enterprise', TRUE)
                RETURNING id
            """)

        print(f"Using workspace: {workspace_id}")

        # Generate organizational structure
        print("\n=== Generating Departments ===")
        dept_ids = await generate_departments(conn, workspace_id)

        print("\n=== Generating Agents ===")
        agents = await generate_agents(conn, workspace_id, dept_ids)

        print("\n=== Generating Trace History ===")
        trace_count = await generate_traces(conn, workspace_id, agents, days=90)

        print("\n=== Synthetic Data Generation Complete ===")
        print(f"✅ {len(DEPARTMENTS)} departments")
        print(f"✅ {len(agents)} agents")
        print(f"✅ {trace_count} traces (90 days of history)")
        print(f"✅ Realistic distribution across versions, environments, intents")

    finally:
        await conn.close()

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
```

**Demo Data Characteristics**:
- ✅ **10 departments** with realistic budgets and agent types
- ✅ **80-100 agents** distributed across departments
- ✅ **90 days of trace history** (~500,000-800,000 traces)
- ✅ **Realistic patterns**:
  - Business hours usage (9am-6pm peaks)
  - Weekend traffic reduction (30% of weekday)
  - Version adoption curves (40% on latest, declining for older)
  - Environment distribution (70% prod, 20% staging, 10% dev)
  - Intent categories matched to department types
  - Error rates (2-5%)
  - Cost variations by model/provider
  - User segmentation (10% power users, 70% regular, 15% new, 5% dormant)

### Validation Checklist

- [ ] **Data Preservation**:
  - [ ] Row count matches pre-migration: `SELECT COUNT(*) FROM traces`
  - [ ] No NULL workspace_ids: `SELECT COUNT(*) FROM traces WHERE workspace_id IS NULL` = 0
  - [ ] All traces have departments: `SELECT COUNT(*) FROM traces WHERE department_id IS NULL` = 0
  - [ ] Foreign key integrity: No orphaned references

- [ ] **Schema Changes**:
  - [ ] All new columns added successfully
  - [ ] Indexes created on new columns
  - [ ] Continuous aggregates rebuilt
  - [ ] Continuous aggregate policies active

- [ ] **Synthetic Data**:
  - [ ] 10 departments created
  - [ ] 80-100 agents generated
  - [ ] 500k+ traces generated (90 days history)
  - [ ] Realistic distribution validated:
    - [ ] Version distribution (40% v2.1, 30% v2.0, etc.)
    - [ ] Environment distribution (70% prod, 20% staging, 10% dev)
    - [ ] Intent categories distributed appropriately
    - [ ] Business hours patterns visible in data
  - [ ] Demo scenarios documented with examples

- [ ] **Migration Safety**:
  - [ ] Pre-migration backup created
  - [ ] Rollback script tested (on dev environment)
  - [ ] Migration ran successfully
  - [ ] Post-migration validation queries passed

### Synthetic Data Demo Scenarios

Document these scenarios for demos:

**Scenario 1: Department Comparison**
- Engineering vs Sales vs Support departments
- Different agent types and usage patterns
- Budget tracking across departments

**Scenario 2: Version Rollout**
- v2.1 adoption across different departments
- Performance comparison between versions
- Canary deployment patterns visible

**Scenario 3: Environment Parity**
- Production vs Staging differences
- Testing coverage analysis
- Configuration drift detection

**Scenario 4: Intent Analysis**
- Customer support concentrated in Support dept
- Code generation dominant in Engineering
- Content creation in Marketing

**Scenario 5: Time Patterns**
- Business hours vs after-hours usage
- Weekend traffic reduction
- Seasonal variations (if longer history)

### Next Phase Handoff

**To Phase 2**:

**Database Schema Ready**:
- ✅ All tables support multi-agent queries
- ✅ department_id, environment, version columns in all relevant tables
- ✅ Continuous aggregates include new dimensions
- ✅ Indexes optimized for common query patterns

**Data Ready**:
- ✅ 10 departments with realistic budgets
- ✅ 80-100 agents across departments
- ✅ 500k+ traces with 90 days history
- ✅ Existing 10k traces preserved and backfilled
- ✅ Realistic patterns for compelling demos

**Next Steps**:
- Backend APIs can now query by department/environment/version
- Reference `API_CONTRACTS.md` for query parameter standards
- Reference `DATABASE_CONVENTIONS.md` for query patterns
- Demo scenarios ready for frontend visualization

---

## **PHASE 2: Core Backend APIs - Multi-Agent Filtering**

**Duration**: 2-3 sessions
**Priority**: P0
**Token Estimate**: 55K

### Previous Phase Context

**From Phase 1**:
- ✅ Database supports multi-agent queries with department_id, environment, version
- ✅ 500k+ traces across 90 days, 10 departments, 80-100 agents
- ✅ Continuous aggregates include new dimensions
- ✅ Reference `DATABASE_CONVENTIONS.md` for query patterns
- ✅ Reference `API_CONTRACTS.md` for endpoint design

### Goals

1. ✅ Enhance Query Service APIs to support fleet-level aggregation
2. ✅ Implement department/environment/version filtering on all endpoints
3. ✅ Add comparative analysis capabilities (dept A vs dept B)
4. ✅ Implement caching layer following `ARCHITECTURE_PATTERNS.md`
5. ✅ **Generate API response examples** with synthetic data for demos

### Sub-Agent Strategy (Parallel Execution)

- **Agent 1** (`fullstack-api-designer`): Design API specs for all enhanced endpoints (following `API_CONTRACTS.md`)
- **Agent 2** (`general-purpose`): Implement Home + Usage APIs with filtering
- **Agent 3** (`general-purpose`): Implement Cost + Performance APIs with filtering
- **Agent 4** (`general-purpose`): Implement caching layer with Redis

### Deliverables

#### 1. Enhanced Query Service APIs

All endpoints follow `API_CONTRACTS.md` patterns with standard query parameters and response envelopes.

**File Structure**:
```
backend/query/
├── app/
│   ├── main.py
│   ├── config.py
│   ├── routes/
│   │   ├── home.py          # Home Dashboard APIs (NEW)
│   │   ├── usage.py         # Usage Analytics APIs (ENHANCED)
│   │   ├── cost.py          # Cost Management APIs (ENHANCED)
│   │   ├── performance.py   # Performance APIs (ENHANCED)
│   │   └── quality.py       # Quality APIs (existing)
│   ├── cache.py             # Redis caching layer (NEW)
│   ├── query_builder.py     # SQL query utilities (NEW)
│   └── models.py            # Pydantic response models
└── tests/
    ├── test_home_apis.py
    ├── test_usage_apis.py
    ├── test_cost_apis.py
    └── test_cache.py
```

**Key Endpoints** (following `API_CONTRACTS.md`):

**Home Dashboard APIs** (`routes/home.py`):
```python
@router.get("/api/v1/metrics/home-kpis")
async def get_home_kpis(
    workspace_id: UUID,
    range: str = "24h",
    department: Optional[str] = None,
    environment: Optional[str] = None,
    version: Optional[str] = None,
    cache: Cache = Depends(get_cache)
) -> HomeKPIsResponse:
    """
    Fleet-level KPIs with multi-dimensional filtering.

    Returns:
    - total_requests (with % change vs previous period)
    - avg_latency (P50/P90/P99 with % change)
    - error_rate (with % change)
    - total_cost (with % change)
    - avg_quality_score (with % change)
    - requests_by_department (for breakdown)
    - requests_sparkline (24h hourly data)
    """

@router.get("/api/v1/fleet/health-heatmap")
async def get_fleet_health_heatmap(
    workspace_id: UUID,
    range: str = "7d",
    department: Optional[str] = None
) -> FleetHealthResponse:
    """
    NEW: Fleet health heatmap data.
    Returns health scores per agent per time bucket.

    Health score calculation:
    - 100: No errors, latency < P90 threshold, all SLOs met
    - 70-99: Minor issues, some SLO degradation
    - 40-69: Moderate issues, SLO breaches
    - 0-39: Critical issues, multiple failures
    """

@router.get("/api/v1/slo/compliance-dashboard")
async def get_slo_compliance(
    workspace_id: UUID,
    department: Optional[str] = None
) -> SLOComplianceResponse:
    """
    NEW: SLO compliance metrics.
    Returns current SLO status vs targets for:
    - Latency SLO (P90 < 2000ms target)
    - Error rate SLO (< 2% target)
    - Quality SLO (avg score > 80 target)
    """
```

**Usage Analytics APIs** (`routes/usage.py`):
```python
@router.get("/api/v1/usage/overview")
async def get_usage_overview(
    workspace_id: UUID,
    range: str = "30d",
    department: Optional[str] = None,
    agent_id: Optional[str] = None,
    environment: Optional[str] = None,
    version: Optional[str] = None
) -> UsageOverviewResponse:
    """
    Enhanced usage overview with multi-dimensional filtering.

    Returns:
    - total_api_calls (with % change)
    - unique_users (with % change)
    - active_agents (with % change)
    - avg_calls_per_user (with % change)
    - calls_by_department (breakdown)
    - calls_over_time (time-series)
    """

@router.get("/api/v1/usage/intent-distribution")
async def get_intent_distribution(
    workspace_id: UUID,
    range: str = "30d",
    department: Optional[str] = None
) -> IntentDistributionResponse:
    """
    NEW: Intent category distribution matrix.
    Returns department × intent heatmap data.

    Example response:
    {
      "data": [
        {"department": "engineering", "intent": "code_generation", "count": 45000, "pct": 35.5},
        {"department": "engineering", "intent": "data_analysis", "count": 30000, "pct": 23.6},
        ...
      ]
    }
    """

@router.get("/api/v1/usage/retention-cohorts")
async def get_retention_cohorts(
    workspace_id: UUID,
    cohort_size: str = "monthly"
) -> RetentionCohortResponse:
    """
    NEW: User retention cohort analysis.

    Returns cohort table:
    - cohort_month (signup month)
    - month_0 (100% - signup month)
    - month_1 (% retained after 1 month)
    - month_2, month_3, ... (ongoing retention)
    """
```

**Cost Management APIs** (`routes/cost.py`):
```python
@router.get("/api/v1/cost/by-department")
async def get_cost_by_department(
    workspace_id: UUID,
    range: str = "30d"
) -> CostByDepartmentResponse:
    """
    NEW: Cost breakdown by department with budget tracking.

    Returns for each department:
    - department_name
    - total_cost
    - budget_monthly
    - budget_used_pct
    - cost_trend (vs previous period)
    - top_agents (by cost)
    """

@router.get("/api/v1/cost/provider-comparison")
async def get_provider_comparison(
    workspace_id: UUID,
    range: str = "30d",
    department: Optional[str] = None
) -> ProviderComparisonResponse:
    """
    NEW: Cost/performance comparison across providers.

    Returns for each provider:
    - provider_name (OpenAI, Anthropic, Google)
    - total_cost
    - request_count
    - avg_latency
    - cost_per_request
    - quality_score_avg
    """

@router.get("/api/v1/cost/budget-tracking")
async def get_budget_tracking(
    workspace_id: UUID,
    department: Optional[str] = None
) -> BudgetTrackingResponse:
    """
    NEW: Real-time budget consumption tracking.

    Returns:
    - current_period_cost
    - budget_limit
    - budget_remaining
    - days_remaining_in_period
    - projected_end_of_period_cost
    - alert_status (on_track, warning, exceeded)
    """
```

**Performance APIs** (`routes/performance.py`):
```python
@router.get("/api/v1/performance/latency-heatmap")
async def get_latency_heatmap(
    workspace_id: UUID,
    range: str = "24h",
    department: Optional[str] = None
) -> LatencyHeatmapResponse:
    """
    NEW: Latency percentile heatmap.
    Returns agent × time bucket with P90/P95/P99 values.

    Example response:
    {
      "agents": ["eng-code-1", "eng-code-2", ...],
      "time_buckets": ["2025-10-27 10:00", "2025-10-27 11:00", ...],
      "heatmap": [
        [1234, 1456, 1389, ...],  # P90 latencies for eng-code-1
        [2100, 2200, 2050, ...],  # P90 latencies for eng-code-2
        ...
      ]
    }
    """

@router.get("/api/v1/performance/environment-parity")
async def get_environment_parity(
    workspace_id: UUID,
    department: Optional[str] = None
) -> EnvironmentParityResponse:
    """
    NEW: Environment parity comparison.
    Compares prod vs staging vs dev performance.

    Returns for each environment:
    - environment_name
    - avg_latency_p90
    - error_rate
    - request_count
    - parity_score (how close to production, 0-100)
    """
```

#### 2. Caching Layer Implementation

**File**: `backend/query/app/cache.py`

Following `ARCHITECTURE_PATTERNS.md` caching strategy:

```python
import redis.asyncio as redis
import json
from typing import Any, Optional
import hashlib

class Cache:
    """
    Redis caching layer following ARCHITECTURE_PATTERNS.md

    Key naming: {domain}:{workspace_id}:{scope}:{identifier}
    TTL policies: Hot (30s), Warm (5min), Cold (30min)
    """

    def __init__(self, redis_url: str):
        self.client = redis.from_url(redis_url, decode_responses=True)

    async def get(self, key: str) -> Optional[Any]:
        """Get cached value, return None if not found or expired"""
        value = await self.client.get(key)
        return json.loads(value) if value else None

    async def set(self, key: str, value: Any, ttl: int):
        """Set cache value with TTL in seconds"""
        await self.client.setex(key, ttl, json.dumps(value, default=str))

    async def invalidate_pattern(self, pattern: str):
        """Invalidate all keys matching pattern (e.g., 'home_kpis:workspace-123:*')"""
        keys = await self.client.keys(pattern)
        if keys:
            await self.client.delete(*keys)

    async def invalidate_workspace(self, workspace_id: str):
        """Invalidate all cache keys for a workspace"""
        await self.invalidate_pattern(f"*:{workspace_id}:*")

    def generate_key(self, domain: str, workspace_id: str, **kwargs) -> str:
        """
        Generate cache key from parameters.

        Example:
        generate_key("home_kpis", "ws-123", range="24h", dept="engineering")
        -> "home_kpis:ws-123:range=24h&dept=engineering"
        """
        params_str = "&".join(f"{k}={v}" for k, v in sorted(kwargs.items()) if v)
        return f"{domain}:{workspace_id}:{params_str}"

# TTL Constants (from ARCHITECTURE_PATTERNS.md)
TTL_HOT = 30      # Real-time data (alerts, activity)
TTL_WARM = 300    # Dashboard KPIs (5 minutes)
TTL_COLD = 1800   # Historical aggregates (30 minutes)
```

**Usage in API endpoints**:
```python
@router.get("/api/v1/metrics/home-kpis")
async def get_home_kpis(
    workspace_id: UUID,
    range: str = "24h",
    department: Optional[str] = None,
    cache: Cache = Depends(get_cache)
):
    # Generate cache key
    cache_key = cache.generate_key(
        "home_kpis", str(workspace_id),
        range=range, dept=department
    )

    # Try cache first
    cached = await cache.get(cache_key)
    if cached:
        return cached

    # Cache miss - query database
    result = await query_home_kpis(workspace_id, range, department)

    # Cache result (warm data - 5 min TTL)
    await cache.set(cache_key, result, TTL_WARM)

    return result
```

#### 3. Query Builder Utilities

**File**: `backend/query/app/query_builder.py`

Following `DATABASE_CONVENTIONS.md` patterns:

```python
from typing import Optional, List, Tuple
from uuid import UUID

def build_filtered_query(
    base_table: str,
    workspace_id: UUID,
    time_range: str,
    department: Optional[str] = None,
    environment: Optional[str] = None,
    version: Optional[str] = None,
    additional_filters: dict = {}
) -> Tuple[str, List]:
    """
    Build filtered SQL query following DATABASE_CONVENTIONS.md

    ALWAYS includes workspace_id filter (multi-tenancy enforcement)

    Returns: (query_string, parameters)
    """
    params = [workspace_id]
    filters = ["workspace_id = $1"]

    # Time range filter
    time_offset = parse_time_range(time_range)  # e.g., "24h" -> "24 hours"
    filters.append(f"timestamp >= NOW() - INTERVAL '{time_offset}'")

    # Department filter
    if department:
        params.append(department)
        filters.append(f"department_id = (SELECT id FROM departments WHERE department_code = ${len(params)})")

    # Environment filter
    if environment:
        params.append(environment)
        filters.append(f"environment = ${len(params)}")

    # Version filter
    if version:
        params.append(version)
        filters.append(f"version = ${len(params)}")

    # Additional filters
    for key, value in additional_filters.items():
        params.append(value)
        filters.append(f"{key} = ${len(params)}")

    where_clause = " AND ".join(filters)
    query = f"SELECT * FROM {base_table} WHERE {where_clause}"

    return query, params

def parse_time_range(range: str) -> str:
    """Convert range string to PostgreSQL interval"""
    mapping = {
        '1h': '1 hour',
        '24h': '24 hours',
        '7d': '7 days',
        '30d': '30 days',
        '90d': '90 days'
    }
    return mapping.get(range, '24 hours')
```

#### 4. **Synthetic API Response Examples for Demos**

Generate realistic response examples for documentation and demos:

**Example: Home KPIs Response**
```json
{
  "data": {
    "total_requests": {
      "value": 487234,
      "change": 12.5,
      "change_label": "vs previous 24h",
      "by_department": [
        {"department": "engineering", "value": 145000, "pct": 29.7},
        {"department": "sales", "value": 98000, "pct": 20.1},
        {"department": "support", "value": 87000, "pct": 17.9}
      ],
      "sparkline": [
        {"timestamp": "2025-10-27T00:00:00Z", "value": 18234},
        {"timestamp": "2025-10-27T01:00:00Z", "value": 16789},
        ...
      ]
    },
    "avg_latency": {
      "value": 1234,
      "p50": 987,
      "p90": 1892,
      "p95": 2345,
      "p99": 3456,
      "change": -8.3,
      "change_label": "vs previous 24h"
    },
    "error_rate": {
      "value": 2.34,
      "change": -0.5,
      "error_breakdown": {
        "timeout": 45,
        "rate_limit": 23,
        "server_error": 12
      }
    },
    "total_cost": {
      "value": 1234.56,
      "change": 15.2,
      "by_provider": [
        {"provider": "openai", "cost": 567.89, "pct": 46.0},
        {"provider": "anthropic", "cost": 432.10, "pct": 35.0},
        {"provider": "google", "cost": 234.57, "pct": 19.0}
      ]
    },
    "avg_quality_score": {
      "value": 87.3,
      "change": 2.1,
      "distribution": {
        "excellent": 234,
        "good": 456,
        "fair": 123,
        "poor": 34
      }
    }
  },
  "meta": {
    "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
    "generated_at": "2025-10-27T10:15:30Z",
    "query_duration_ms": 45
  },
  "filters_applied": {
    "range": "24h",
    "department": null,
    "environment": null,
    "version": null
  }
}
```

**Example: Intent Distribution Response**
```json
{
  "data": [
    {
      "department": "engineering",
      "intent": "code_generation",
      "count": 45000,
      "pct_of_dept": 35.5,
      "pct_of_total": 9.2
    },
    {
      "department": "engineering",
      "intent": "data_analysis",
      "count": 30000,
      "pct_of_dept": 23.6,
      "pct_of_total": 6.2
    },
    {
      "department": "support",
      "intent": "customer_support",
      "count": 67000,
      "pct_of_dept": 77.0,
      "pct_of_total": 13.8
    },
    ...
  ],
  "meta": {
    "total_requests": 487234,
    "departments_count": 10,
    "intents_count": 7
  }
}
```

### Validation Checklist

- [ ] **API Endpoints**:
  - [ ] All endpoints follow `API_CONTRACTS.md` patterns
  - [ ] Standard query parameters implemented (workspace_id, range, department, etc.)
  - [ ] Standard response envelope used
  - [ ] Error responses follow standard format

- [ ] **Filtering**:
  - [ ] Multi-dimensional filtering works (dept + env + version simultaneously)
  - [ ] Filter validation prevents invalid combinations
  - [ ] Workspace_id enforced on all queries (multi-tenancy)

- [ ] **Caching**:
  - [ ] Redis caching reduces DB load by 70%+
  - [ ] Cache keys follow naming pattern
  - [ ] TTLs set appropriately (hot/warm/cold)
  - [ ] Cache invalidation working

- [ ] **Performance**:
  - [ ] API response time P95 < 200ms
  - [ ] Database queries use indexes
  - [ ] No N+1 query issues
  - [ ] Continuous aggregates used where appropriate

- [ ] **Documentation**:
  - [ ] Swagger docs auto-generated
  - [ ] Example responses documented
  - [ ] Demo scenarios with synthetic data examples

### Demo API Scenarios

Document these for demonstrations:

**Scenario 1: Fleet-Wide KPIs**
```bash
curl "http://localhost:8003/api/v1/metrics/home-kpis?range=24h" \
  -H "X-Workspace-ID: {workspace_id}"
# Shows organization-wide metrics
```

**Scenario 2: Department Comparison**
```bash
# Engineering department
curl "http://localhost:8003/api/v1/usage/overview?range=30d&department=engineering"

# Sales department
curl "http://localhost:8003/api/v1/usage/overview?range=30d&department=sales"

# Compare results
```

**Scenario 3: Version Performance**
```bash
# v2.1 performance
curl "http://localhost:8003/api/v1/performance/overview?version=v2.1"

# v2.0 performance
curl "http://localhost:8003/api/v1/performance/overview?version=v2.0"

# Shows performance improvement in newer version
```

**Scenario 4: Environment Parity**
```bash
curl "http://localhost:8003/api/v1/performance/environment-parity"
# Shows prod vs staging vs dev comparison
```

### Next Phase Handoff

**To Phase 3**:

**Backend APIs Ready**:
- ✅ 15+ enhanced endpoints with multi-agent filtering
- ✅ Home Dashboard APIs (KPIs, health heatmap, SLO compliance)
- ✅ Usage Analytics APIs (overview, intent distribution, retention cohorts)
- ✅ Cost Management APIs (by department, provider comparison, budget tracking)
- ✅ Performance APIs (latency heatmap, environment parity)
- ✅ All endpoints follow `API_CONTRACTS.md` standards
- ✅ Caching layer operational (70%+ DB load reduction)

**Data & Examples**:
- ✅ API response examples documented
- ✅ Demo scenarios ready with synthetic data
- ✅ Filter combinations validated

**Next Steps**:
- Frontend can consume APIs using TanStack Query
- Reference `COMPONENT_LIBRARY.md` for component patterns
- Reference `ARCHITECTURE_PATTERNS.md` for state management
- Build FilterBar component with URL/localStorage persistence

---

## **PHASE 3: Frontend - Multi-Level Filters & Home Dashboard Upgrade**

**Duration**: 2 sessions
**Priority**: P0
**Token Estimate**: 50K

### Previous Phase Context

**From Phase 2**:
- ✅ Backend APIs operational with multi-dimensional filtering
- ✅ All endpoints return standard response envelope
- ✅ Caching layer reduces DB load by 70%+
- ✅ Demo API responses documented
- ✅ Reference `COMPONENT_LIBRARY.md` for component patterns
- ✅ Reference `ARCHITECTURE_PATTERNS.md` for state management

### Goals

1. ✅ Build shared FilterBar component with persistent state (URL + localStorage)
2. ✅ Transform Home Dashboard (Tab 1) for fleet view
3. ✅ Implement P0 new charts (Fleet Health Heatmap, SLO Compliance)
4. ✅ Establish filter propagation patterns for other tabs
5. ✅ **Create demo-ready dashboard** with realistic synthetic data visualization

### Sub-Agent Strategy (Parallel Execution)

- **Agent 1** (`general-purpose`): Build FilterBar component + global state management
- **Agent 2** (`general-purpose`): Enhance existing KPI cards (1.1-1.5) with multi-agent features
- **Agent 3** (`general-purpose`): Build new charts (Fleet Health Heatmap 1.8, SLO Compliance 1.9)

### Deliverables

[Content continues with detailed frontend implementation following the same pattern as Phase 1 and 2]

---

## Phases 4-12 Summary

Due to document length constraints, Phases 4-12 follow the same detailed structure as Phases 1-3:

### Phase 4: Usage Analytics Dashboard Upgrade (2 sessions)
- Enhance existing charts for multi-agent
- Build Intent Distribution Matrix, Retention Cohorts
- Implement agent deprecation, capacity threshold actions
- Generate synthetic usage patterns for demos

### Phase 5: Cost & Performance Dashboards Upgrade (2 sessions)
- Department budget tracking, provider comparison
- Environment parity visualization, version performance
- Configure SLO thresholds, auto-scaling actions
- Generate synthetic cost/performance data

### Phase 6: Quality & Safety Dashboards Upgrade (2 sessions)
- Quality score distribution by department
- Policy compliance visualization
- Rubric management, policy configuration actions
- Generate synthetic quality/safety data

### Phase 7: Business Impact Dashboard Upgrade (1 session)
- Department goal tracking, ROI by department
- Impact forecasting with ML
- Goal management actions
- Generate synthetic business metrics

### Phase 8: NEW - Incidents & Reliability Tab (2 sessions)
- Build incidents & SLO schema
- Incident management APIs and frontend
- SLO configuration, postmortem tracking
- Generate synthetic incidents for demos

### Phase 9: NEW - Experiments & Optimization Tab (2 sessions)
- Build experiments schema
- A/B testing framework and APIs
- Statistical significance calculation
- Generate synthetic experiment data

### Phase 10: NEW - Configuration & Policy Tab (2 sessions)
- Build config and policy schema
- Policy governance dashboard
- Configuration drift detection
- Generate synthetic config scenarios

### Phase 11: NEW - Automations & Playbooks Tab (2 sessions)
- Build automation schema
- Playbook designer and execution engine
- Scheduled automation workflows
- Generate synthetic automation examples

### Phase 12: Polish & Production Readiness (2-3 sessions)
- Performance optimization
- Remaining P2 features
- E2E testing
- Documentation completion

**Each phase includes**:
- Previous Phase Context
- Detailed deliverables
- Synthetic data generation
- Validation checklist
- Next Phase Handoff

---

## Cross-Session Continuity Mechanisms

### 1. Blueprint Reference System
Every phase explicitly references blueprint documents:
- **Phase 1**: `DATABASE_CONVENTIONS.md`
- **Phase 2**: `API_CONTRACTS.md`, `ARCHITECTURE_PATTERNS.md`
- **Phase 3**: `COMPONENT_LIBRARY.md`, `ARCHITECTURE_PATTERNS.md`
- **Phases 4-11**: All blueprints as needed
- **Phases 8, 11**: `ACTION_IMPLEMENTATION_PLAYBOOK.md`

### 2. Previous Phase Context Sections
Each phase starts with summary of:
- What was delivered in previous phase
- Key data/structures available
- Which blueprint patterns to follow
- Current state of synthetic data

### 3. Next Phase Handoff Sections
Each phase ends with documentation of:
- Components/APIs now available
- Patterns established
- Context for next session
- Synthetic data scenarios ready

### 4. Validation Checklists
Every phase has measurable acceptance criteria with:
- Database changes validated
- API endpoints tested
- Frontend components working
- Synthetic data generated
- Performance benchmarks met

### 5. Phase Completion Template
Use `PHASE_CHECKLIST_TEMPLATE.md` for each phase completion.

---

## Synthetic Data Strategy

### Comprehensive Demo Data Across All Phases

Each phase generates realistic synthetic data to enable compelling demonstrations:

#### Phase 1: Organizational Foundation
- ✅ 10 departments with budgets
- ✅ 80-100 agents across departments
- ✅ 500k+ traces (90 days history)
- ✅ Realistic patterns: business hours, weekends, version distribution

#### Phase 2: API Demo Data
- ✅ API response examples for all endpoints
- ✅ Department comparison scenarios
- ✅ Version performance scenarios
- ✅ Environment parity scenarios

#### Phase 3: Dashboard Visualization Data
- ✅ Fleet health heatmap data (agent health scores)
- ✅ SLO compliance data (latency, error rate, quality)
- ✅ KPI sparkline data (24h hourly trends)
- ✅ Department breakdown data

#### Phase 4: Usage Analytics Demo Data
- ✅ User cohort data (signup dates, retention)
- ✅ Intent distribution data (dept × intent matrix)
- ✅ Agent adoption curves
- ✅ User segment data (power users, regular, new, dormant)

#### Phase 5: Cost & Performance Demo Data
- ✅ Department budget consumption data
- ✅ Provider cost comparison data (OpenAI, Anthropic, Google)
- ✅ Latency heatmap data (agent × time)
- ✅ Environment parity data (prod vs staging vs dev)

#### Phase 6: Quality & Safety Demo Data
- ✅ Quality evaluation scores by rubric
- ✅ Policy violation data (PII, toxicity, injection)
- ✅ Compliance audit trails
- ✅ Guardrail effectiveness metrics

#### Phase 7: Business Impact Demo Data
- ✅ Department goals and progress
- ✅ ROI calculations
- ✅ Impact attribution data
- ✅ Forecast models with confidence intervals

#### Phase 8: Incidents Demo Data
- ✅ Incident records with timelines
- ✅ SLO breach history
- ✅ MTTR calculations
- ✅ Postmortem data

#### Phase 9: Experiments Demo Data
- ✅ A/B test results with statistical significance
- ✅ Variant performance data
- ✅ Rollout history
- ✅ Winner declarations

#### Phase 10: Configuration Demo Data
- ✅ Policy definitions and compliance status
- ✅ Configuration versions and history
- ✅ Drift detection data
- ✅ Change approval workflows

#### Phase 11: Automation Demo Data
- ✅ Playbook definitions
- ✅ Execution history with outcomes
- ✅ Scheduled automation runs
- ✅ Success/failure patterns

### Demo Scenario Documentation

Each phase documents specific demo scenarios:
- **Scenario description**: What to demonstrate
- **Data setup**: Which synthetic data to use
- **Expected outcome**: What should be visible
- **Talking points**: Key insights to highlight

Example from Phase 1:
```markdown
**Demo Scenario: Department Comparison**

Setup:
- Engineering: 12 agents, 145k requests/day, $15k/month cost
- Sales: 8 agents, 98k requests/day, $8k/month cost
- Support: 10 agents, 87k requests/day, $7k/month cost

What to show:
1. Filter by Engineering department
2. Show request volume, cost, quality scores
3. Switch to Sales department
4. Highlight differences in usage patterns
5. Show comparative view side-by-side

Talking points:
- Engineering has highest usage (code generation heavy)
- Sales has better quality scores (focused use case)
- Support has most consistent patterns (24/7 support)
```

---

## Risk Mitigation

| Risk | Impact | Likelihood | Mitigation Strategy |
|------|--------|------------|---------------------|
| **Blueprint inconsistency across sessions** | High | Medium | Phase 0 creates all blueprints first; Every phase references blueprints explicitly; Blueprint updates require review |
| **Data loss during migration** | Critical | Low | Phase 1 includes explicit backup/rollback scripts; Non-destructive schema evolution; Row count validation |
| **Cross-session pattern drift** | High | Medium | "Previous Phase Context" and "Next Phase Handoff" sections; Blueprint references in every phase; Validation checklists |
| **Token limit exceeded** | Medium | Medium | Blueprint documents keep context compact; Sub-agents reference blueprints; Strategic use of specialized agents |
| **Sub-agent coordination failure** | Medium | Low | Clear interface contracts in blueprints; Schema-first design; API specs before implementation; Integration tests |
| **Synthetic data insufficient for demos** | Medium | Low | Comprehensive data generation in each phase; Demo scenarios documented; Data variety validated |
| **Performance degradation with scale** | High | Medium | Continuous aggregates for fast queries; Redis caching (70%+ hit rate); Query optimization; Load testing after each phase |
| **Missing cross-tab dependencies** | Medium | Low | Dependency mapping documented; Integration tests across tabs; Phase handoffs include dependency status |

---

## Timeline Summary

| Phase | Focus Area | Sessions | Priority | Blueprint References | Synthetic Data | Cumulative |
|-------|------------|----------|----------|---------------------|----------------|------------|
| 0 | Blueprint Creation | 1 | P0 | Creates all blueprints | N/A | 1 |
| 1 | Database Schema | 1-2 | P0 | DATABASE_CONVENTIONS | 10 depts, 100 agents, 500k traces | 3 |
| 2 | Backend APIs | 2-3 | P0 | API_CONTRACTS, ARCHITECTURE_PATTERNS | API response examples | 6 |
| 3 | Home Dashboard | 2 | P0 | COMPONENT_LIBRARY | Dashboard visualization data | 8 |
| 4 | Usage Analytics | 2 | P0 | All blueprints | User cohorts, intent distribution | 10 |
| 5 | Cost & Performance | 2 | P0-P1 | All blueprints | Budget data, latency heatmaps | 12 |
| 6 | Quality & Safety | 2 | P0-P1 | All blueprints | Evaluations, violations | 14 |
| 7 | Business Impact | 1 | P1 | All blueprints | Goals, ROI data | 15 |
| 8 | Incidents Tab (NEW) | 2 | P0 | All + ACTION_PLAYBOOK | Incidents, SLOs | 17 |
| 9 | Experiments Tab (NEW) | 2 | P1 | All blueprints | A/B tests, results | 19 |
| 10 | Configuration Tab (NEW) | 2 | P0 | All blueprints | Policies, drift data | 21 |
| 11 | Automations Tab (NEW) | 2 | P1 | All + ACTION_PLAYBOOK | Playbooks, executions | 23 |
| 12 | Polish & Production | 2-3 | P1-P2 | TESTING_PATTERNS | Edge cases, load test data | 26 |
| **TOTAL** | | **23-26** | | | **Complete demo suite** | |

**Total Estimated Time**: 23-26 Claude Code sessions (~46-52 hours of development)

---

## Success Metrics

### Phase Completion Metrics
- [ ] All P0 features complete (100%)
- [ ] 90%+ of P1 features complete
- [ ] Database schema supports all 11 tabs
- [ ] All APIs operational with <200ms P95 response time
- [ ] All 11 dashboards functional with real data
- [ ] Synthetic data comprehensive for demos

### Quality Metrics
- [ ] API response time P95 < 200ms
- [ ] Dashboard load time < 3s
- [ ] Cache hit rate > 70%
- [ ] Zero critical security vulnerabilities
- [ ] All foreign key constraints valid
- [ ] Zero data loss during migration

### Demo Readiness Metrics
- [ ] 10+ department demo scenarios documented
- [ ] 100+ agents with realistic data
- [ ] 500k+ traces with 90 days history
- [ ] All chart types have demo data
- [ ] All actions have example executions
- [ ] Compelling narratives prepared for each tab

---

## Next Steps to Begin

1. ✅ **Review and approve** this enhanced plan
2. ✅ **Start Phase 0**: Create all 7 blueprint documents (1 session)
3. ✅ **Review blueprints**: Validate patterns align with preferences
4. ✅ **Begin Phase 1**: Database transformation with data preservation (1-2 sessions)
5. ✅ **Execute phases sequentially**: Each phase builds on previous foundation

This plan provides:
- ✅ **Architectural consistency** via blueprint documents
- ✅ **Data preservation guarantees** with explicit migration strategy
- ✅ **Cross-session continuity** through structured handoffs
- ✅ **Demo-ready platform** with comprehensive synthetic data
- ✅ **Complete coverage** of all 11 enterprise tabs
- ✅ **Realistic timeline** with parallel sub-agent execution

---

**END OF ENTERPRISE RELEASE PLAN**

**Document Version**: 2.0
**Last Updated**: October 27, 2025
**Ready for Execution**: ✅ YES
