# Phase 4 Implementation Guide - Advanced Features + AI

## Table of Contents
1. [Overview](#overview)
2. [Phase Objectives](#phase-objectives)
3. [Sub-Agent Strategy](#sub-agent-strategy)
4. [Implementation Workflow](#implementation-workflow)
5. [Backend Services Specifications](#backend-services-specifications)
6. [Frontend Implementation](#frontend-implementation)
7. [Synthetic Data Generation](#synthetic-data-generation)
8. [Testing Strategy](#testing-strategy)
9. [Docker & Deployment](#docker--deployment)
10. [Environment Variables](#environment-variables)

---

## Overview

**Phase 4: Advanced Features + AI (Weeks 12-14)**

This phase adds AI-powered capabilities to the Agent Observability Platform:
- **Evaluation Service**: LLM-as-a-judge quality assessment using Google Gemini
- **Guardrail Service**: PII detection, toxicity filtering, prompt injection prevention
- **Alert Service**: Threshold-based alerts and anomaly detection
- **Gemini Integration Service**: AI-powered insights and recommendations
- **3 New Dashboard Pages**: Quality, Safety, and Business Impact visualization

**Duration**: 3 weeks (15 working days)

**Key Technologies**:
- Google Gemini Pro API for evaluations and insights
- FastAPI for backend services (Python 3.11+)
- TimescaleDB + PostgreSQL for data storage
- Redis for caching and pub/sub
- Next.js 14 + TypeScript for frontend
- Recharts for data visualization

---

## Phase Objectives

### Technical Deliverables
- **4 New Backend Services**: 20 total API endpoints
- **3 Frontend Dashboard Pages**: Fully functional with real-time data
- **Synthetic Data**: 1400+ records across evaluations, violations, alerts, goals
- **Comprehensive Testing**: 44 tests (32 backend, 9 frontend, 3 integration)
- **Docker Integration**: Updated docker-compose.yml with new services
- **Gateway Updates**: Proxy routes for new services

### Business Value
- **Quality Assurance**: Automated LLM output quality evaluation
- **Safety & Compliance**: PII detection and content filtering
- **Proactive Monitoring**: Real-time alerting on anomalies
- **AI-Powered Insights**: Automated cost optimization and error analysis
- **Business Impact Tracking**: ROI and goal achievement monitoring

---

## Sub-Agent Strategy

### Virtual Specialization Approach

Phase 4 continues the **virtual specialization** pattern established in Phase 3. We do NOT create new Claude Code sub-agents. Instead, we use specialized prompts with existing agents:

#### Available Agents

1. **fullstack-api-designer**
   - Purpose: Design comprehensive API specifications
   - When to use: Before implementing any new service
   - Output: Detailed API_SPEC.md with endpoints, schemas, examples

2. **general-purpose**
   - Purpose: Implementation tasks with specialized prompting
   - When to use: Building services, routes, utilities
   - Pattern: Provide context-rich prompts with examples

3. **fullstack-integration-tester**
   - Purpose: Comprehensive test suite creation
   - When to use: After implementation of each service
   - Output: pytest tests with fixtures, mocks, and integration tests

### Prompting Patterns for Phase 4

#### Pattern 1: Backend Service Implementation

```
Task: Build {Service Name} Service - Port {PORT}

Context:
- New microservice for Phase 4
- Follows existing service patterns (see backend/query/, backend/ingestion/)
- Uses FastAPI with async/await
- Connects to PostgreSQL for metadata, TimescaleDB for metrics
- Implements Redis caching

Requirements:
1. Create backend/{service_name}/ directory structure:
   - app/main.py (FastAPI app)
   - app/routes/ (API endpoints)
   - app/models.py (Pydantic models)
   - app/database.py (DB connections)
   - app/config.py (Settings)
   - Dockerfile
   - requirements.txt
   - tests/

2. Implement {N} endpoints per specification:
   - {Endpoint 1 description}
   - {Endpoint 2 description}
   ...

3. Add comprehensive error handling
4. Include detailed docstrings
5. Implement Redis caching where appropriate
6. Follow existing code style and patterns

Dependencies:
- Google Gemini API for evaluations/insights
- PostgreSQL tables: {table1, table2, ...}
- Redis for caching

Output:
Complete service implementation ready for Docker deployment
```

#### Pattern 2: Frontend Dashboard Page

```
Task: Build {Page Name} Dashboard - /dashboard/{route}

Context:
- Phase 4 frontend page
- Follow existing dashboard patterns (see frontend/app/dashboard/usage/)
- Use shadcn/ui components
- Implement TanStack Query for data fetching
- Add Recharts for visualizations

Requirements:
1. Replace placeholder in frontend/app/dashboard/{route}/page.tsx
2. Create necessary components in frontend/components/{route}/
3. Implement data fetching with useQuery hooks
4. Add charts, tables, and KPI cards
5. Include loading states and error handling
6. Add time range filters (24h, 7d, 30d)

Features:
- {Feature 1}
- {Feature 2}
- {Feature 3}

API Endpoints:
- GET /api/v1/{endpoint1}
- GET /api/v1/{endpoint2}

Output:
Fully functional dashboard page with real-time data visualization
```

#### Pattern 3: Synthetic Data Generation

```
Task: Generate Synthetic Data for {Feature}

Context:
- Phase 4 synthetic data for testing and demo
- Must use CORRECT workspace_id from database query
- Generate realistic data distributions
- Insert into PostgreSQL/TimescaleDB

Requirements:
1. Query workspace ID: SELECT id FROM workspaces WHERE slug = 'dev-workspace'
2. Generate {N} records with realistic distributions
3. Create SQL script: backend/db/seed-{feature}.sql
4. Include variety in {key_attributes}
5. Add verification query

Data Characteristics:
- {Characteristic 1}
- {Characteristic 2}

Tables:
- {table1} ({columns})
- {table2} ({columns})

Output:
SQL script that generates {N} records with proper foreign keys
```

---

## Implementation Workflow

### Week 1: Backend Services Part 1 (Days 1-5)

#### Day 1-2: Evaluation Service (Port 8004)

**Objective**: Build LLM-as-a-judge evaluation system using Google Gemini

**Tasks**:
1. Use `fullstack-api-designer` to create evaluation API specification
2. Create `backend/evaluation/` directory structure
3. Implement 5 endpoints:
   - `POST /api/v1/evaluate/trace/:trace_id` - Evaluate single trace
   - `POST /api/v1/evaluate/batch` - Batch evaluate traces
   - `GET /api/v1/evaluate/history` - Get evaluation history
   - `POST /api/v1/evaluate/custom-criteria` - Define custom criteria
   - `GET /api/v1/evaluate/criteria` - List evaluation criteria
4. Integrate Google Gemini Pro API
5. Implement evaluation scoring logic (0-10 scale)
6. Add PostgreSQL integration for `evaluations` table
7. Add Redis caching for evaluation results (5min TTL)
8. Write 8 pytest tests

**Key Implementation Details**:

Database schema already exists in `init-postgres.sql` (lines 110-136):
```sql
CREATE TABLE evaluations (
    id UUID PRIMARY KEY,
    workspace_id UUID NOT NULL,
    trace_id VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    evaluator VARCHAR(64) NOT NULL, -- 'gemini', 'human', 'custom_model'
    accuracy_score DECIMAL(3, 1),
    relevance_score DECIMAL(3, 1),
    helpfulness_score DECIMAL(3, 1),
    coherence_score DECIMAL(3, 1),
    overall_score DECIMAL(3, 1),
    reasoning TEXT,
    metadata JSONB DEFAULT '{}'
);
```

**Files to Create**:
- `backend/evaluation/app/main.py`
- `backend/evaluation/app/routes/evaluate.py`
- `backend/evaluation/app/models.py`
- `backend/evaluation/app/database.py`
- `backend/evaluation/app/config.py`
- `backend/evaluation/app/gemini_client.py`
- `backend/evaluation/Dockerfile`
- `backend/evaluation/requirements.txt`
- `backend/evaluation/tests/test_evaluate.py`

---

#### Day 3-5: Guardrail Service (Port 8005)

**Objective**: Build safety and compliance system for PII, toxicity, and prompt injection detection

**Tasks**:
1. Use `fullstack-api-designer` to create guardrail API specification
2. Create `backend/guardrail/` directory structure
3. Implement 5 endpoints:
   - `POST /api/v1/guardrails/check` - Check content against all rules
   - `POST /api/v1/guardrails/pii` - Detect PII in text
   - `POST /api/v1/guardrails/toxicity` - Check for toxic content
   - `GET /api/v1/guardrails/violations` - Get violation history
   - `POST /api/v1/guardrails/rules` - Create custom guardrail rule
4. Implement PII detection with regex patterns
5. Implement toxicity detection (use transformers or Perspective API)
6. Implement prompt injection detection
7. Add PostgreSQL integration for `guardrail_rules` and `guardrail_violations` tables
8. Write 8 pytest tests

**Key PII Patterns**:
```python
PII_PATTERNS = {
    'email': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    'phone': r'\b(?:\+?1[-.]?)?\(?\d{3}\)?[-.]?\d{3}[-.]?\d{4}\b',
    'ssn': r'\b\d{3}[-]?\d{2}[-]?\d{4}\b',
    'credit_card': r'\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b',
    'ip_address': r'\b(?:\d{1,3}\.){3}\d{1,3}\b'
}
```

**Database schemas already exist** in `init-postgres.sql` (lines 138-187)

**Files to Create**:
- `backend/guardrail/app/main.py`
- `backend/guardrail/app/routes/guardrails.py`
- `backend/guardrail/app/models.py`
- `backend/guardrail/app/database.py`
- `backend/guardrail/app/config.py`
- `backend/guardrail/app/detectors/pii.py`
- `backend/guardrail/app/detectors/toxicity.py`
- `backend/guardrail/app/detectors/injection.py`
- `backend/guardrail/Dockerfile`
- `backend/guardrail/requirements.txt`
- `backend/guardrail/tests/test_guardrails.py`

---

### Week 2: Backend Services Part 2 + Frontend (Days 6-10)

#### Day 6-7: Alert Service (Port 8006)

**Objective**: Build real-time alerting system with threshold monitoring and anomaly detection

**Tasks**:
1. Use `fullstack-api-designer` to create alert API specification
2. Create `backend/alert/` directory structure
3. Implement 6 endpoints:
   - `GET /api/v1/alerts` - List active alerts
   - `GET /api/v1/alerts/:id` - Get alert details
   - `POST /api/v1/alerts/:id/acknowledge` - Acknowledge alert
   - `POST /api/v1/alerts/:id/resolve` - Resolve alert
   - `POST /api/v1/alert-rules` - Create alert rule
   - `GET /api/v1/alert-rules` - List alert rules
4. Implement threshold-based monitoring
5. Implement anomaly detection using statistical methods (Z-score)
6. Implement webhook notifications
7. Add PostgreSQL integration for `alert_rules` and `alert_notifications` tables
8. Add background worker for continuous monitoring
9. Write 8 pytest tests

**Key Anomaly Detection**:
```python
# Use Z-score for anomaly detection
# Flag values where |z| > 3 (3 standard deviations from mean)
z_score = (value - mean) / std_deviation
is_anomaly = abs(z_score) > 3
```

**Database schemas already exist** in `init-postgres.sql` (lines 189-239)

**Files to Create**:
- `backend/alert/app/main.py`
- `backend/alert/app/routes/alerts.py`
- `backend/alert/app/models.py`
- `backend/alert/app/database.py`
- `backend/alert/app/config.py`
- `backend/alert/app/monitoring.py` (background worker)
- `backend/alert/app/detectors/threshold.py`
- `backend/alert/app/detectors/anomaly.py`
- `backend/alert/app/notifications/webhook.py`
- `backend/alert/Dockerfile`
- `backend/alert/requirements.txt`
- `backend/alert/tests/test_alerts.py`

---

#### Day 8: Gemini Integration Service (Port 8007)

**Objective**: Build AI-powered insights service for cost optimization, error analysis, and automated summaries

**Tasks**:
1. Use `fullstack-api-designer` to create insights API specification
2. Create `backend/gemini/` directory structure
3. Implement 4 endpoints:
   - `POST /api/v1/insights/cost-optimization` - Get cost saving suggestions
   - `POST /api/v1/insights/error-diagnosis` - Analyze error root causes
   - `POST /api/v1/insights/feedback-analysis` - Analyze user feedback sentiment
   - `GET /api/v1/insights/daily-summary` - Get automated daily summary
4. Integrate Google Gemini Pro API
5. Implement prompt templates for each insight type
6. Add Redis caching for insights (30min TTL)
7. Write 8 pytest tests

**Key Prompt Template Example**:
```python
def cost_optimization_prompt(cost_data: dict) -> str:
    return f"""
    Analyze this AI agent cost breakdown and provide optimization suggestions:

    Total Cost: ${cost_data['total']:.2f}
    Cost by Model: {json.dumps(cost_data['by_model'], indent=2)}
    Request Volume: {json.dumps(cost_data['request_counts'], indent=2)}

    Provide:
    1. Top 3 cost optimization opportunities
    2. Estimated savings for each suggestion
    3. Implementation difficulty (low/medium/high)
    4. Specific action items

    Return as JSON with clear, actionable recommendations.
    """
```

**Files to Create**:
- `backend/gemini/app/main.py`
- `backend/gemini/app/routes/insights.py`
- `backend/gemini/app/models.py`
- `backend/gemini/app/database.py`
- `backend/gemini/app/config.py`
- `backend/gemini/app/gemini_client.py`
- `backend/gemini/app/prompts.py` (prompt templates)
- `backend/gemini/Dockerfile`
- `backend/gemini/requirements.txt`
- `backend/gemini/tests/test_insights.py`

---

#### Day 9-10: Frontend Dashboard Pages

**Objective**: Build 3 fully functional dashboard pages with real-time data visualization

##### Page 1: Quality Dashboard (/dashboard/quality)

**Current State**: Placeholder page exists at `frontend/app/dashboard/quality/page.tsx`

**Features to Build**:
- Overall quality score KPI (avg of all evaluations)
- Quality trend chart (7-day trend)
- Evaluation breakdown by criteria (accuracy, relevance, helpfulness, coherence)
- Recent evaluations table
- Quality distribution histogram
- Agent comparison chart

**Components to Create**:
- `frontend/components/quality/QualityScoreCard.tsx`
- `frontend/components/quality/QualityTrendChart.tsx`
- `frontend/components/quality/CriteriaBreakdown.tsx`
- `frontend/components/quality/EvaluationTable.tsx`
- `frontend/components/quality/QualityDistribution.tsx`

**API Endpoints**:
- `GET /api/v1/evaluate/history?range={timeRange}`
- `GET /api/v1/evaluate/criteria`

---

##### Page 2: Safety Dashboard (/dashboard/safety)

**Current State**: Placeholder page exists at `frontend/app/dashboard/safety/page.tsx`

**Features to Build**:
- Total violations KPI
- Violation trend chart
- Violations by type breakdown (PII, toxicity, injection)
- Severity distribution pie chart
- Recent violations table with redaction view
- Agent risk score chart
- Active guardrail rules list

**Components to Create**:
- `frontend/components/safety/ViolationKPICard.tsx`
- `frontend/components/safety/ViolationTrendChart.tsx`
- `frontend/components/safety/TypeBreakdown.tsx`
- `frontend/components/safety/ViolationTable.tsx`
- `frontend/components/safety/AgentRiskChart.tsx`
- `frontend/components/safety/ActiveRulesCard.tsx`

**API Endpoints**:
- `GET /api/v1/guardrails/violations?range={timeRange}`
- `GET /api/v1/guardrails/rules`

---

##### Page 3: Business Impact Dashboard (/dashboard/impact)

**Current State**: Placeholder page exists at `frontend/app/dashboard/impact/page.tsx`

**Features to Build**:
- ROI KPI (cost savings vs investment)
- Goal progress cards (support tickets, CSAT, response time)
- Impact timeline chart
- Cost savings breakdown
- User satisfaction trend
- Business metrics table

**Components to Create**:
- `frontend/components/impact/ROICard.tsx`
- `frontend/components/impact/GoalProgressCard.tsx`
- `frontend/components/impact/ImpactTimelineChart.tsx`
- `frontend/components/impact/SavingsBreakdown.tsx`
- `frontend/components/impact/SatisfactionTrend.tsx`
- `frontend/components/impact/MetricsTable.tsx`

**API Endpoints**:
- `GET /api/v1/business-goals`
- `GET /api/v1/insights/cost-optimization`

---

### Week 3: Data, Testing & Integration (Days 11-15)

#### Day 11-12: Synthetic Data Generation

**CRITICAL**: Must query actual workspace ID from database before generating data!

**Objective**: Generate comprehensive synthetic data for all Phase 4 features

##### Execution Order:

1. **Query Workspace ID** (ALWAYS DO THIS FIRST):
```sql
-- backend/db/get-workspace-id.sql
SELECT id as workspace_id, slug, name
FROM workspaces
WHERE slug = 'dev-workspace'
LIMIT 1;
```

2. **Generate Evaluation Data** (1000 records):
```sql
-- backend/db/seed-evaluations.sql
-- Use workspace_id from step 1
-- Generate scores biased toward good quality (6-10 range)
-- Link to existing trace_ids
-- Distribute across last 7 days
```

3. **Generate Guardrail Violations** (200 records):
```sql
-- backend/db/seed-violations.sql
-- Create default guardrail rules if missing
-- Generate ~5% violation rate
-- Mix of PII, toxicity, and injection types
```

4. **Generate Alert Scenarios** (50 alerts):
```sql
-- backend/db/seed-alerts.sql
-- Create 4 default alert rules
-- Generate ~12 notifications per rule
-- Mix of severities (critical, high, medium)
```

5. **Generate Business Goals** (10 goals):
```sql
-- backend/db/seed-business-goals.sql
-- Create realistic business goals
-- Set current_value to show various progress levels (64%-97%)
-- Include: support tickets, CSAT, cost savings, response time, accuracy
```

6. **FIX Home Page Quality Score**:
```python
# backend/query/app/queries.py
# Update get_home_kpis() function to include:

quality_query = """
    SELECT
        AVG(overall_score) as curr_quality_score,
        (
            SELECT AVG(overall_score)
            FROM evaluations
            WHERE workspace_id = $1
            AND created_at >= NOW() - ($2 * 2 || ' hours')::INTERVAL
            AND created_at < NOW() - ($2 || ' hours')::INTERVAL
        ) as prev_quality_score
    FROM evaluations
    WHERE workspace_id = $1
    AND created_at >= NOW() - ($2 || ' hours')::INTERVAL
"""
```

**Files to Create**:
- `backend/db/get-workspace-id.sql`
- `backend/db/seed-evaluations.sql`
- `backend/db/seed-violations.sql`
- `backend/db/seed-alerts.sql`
- `backend/db/seed-business-goals.sql`

**File to Update**:
- `backend/query/app/queries.py` (add quality score calculation)

---

#### Day 13-14: Comprehensive Testing

**Objective**: Write 44 tests across backend, frontend, and integration

##### Backend Tests (32 tests = 8 per service)

**Test Categories per Service**:
1. Endpoint success cases (2 tests)
2. Endpoint error cases (2 tests)
3. Database integration (1 test)
4. External API integration - mocked (1 test)
5. Caching behavior (1 test)
6. Business logic (1 test)

**Example Test Structure**:
```python
# backend/evaluation/tests/test_evaluate.py

import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_evaluate_trace_success(client: AsyncClient):
    """Test successful trace evaluation"""
    response = await client.post(
        "/api/v1/evaluate/trace/trace-123",
        headers={"X-Workspace-ID": "test-workspace-id"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "overall_score" in data
    assert 0 <= data["overall_score"] <= 10

# ... 7 more tests
```

##### Frontend Tests (9 tests = 3 per page)

**Test Categories per Page**:
1. Page renders without errors
2. Data fetching works correctly
3. User interactions work (time range selection, filters)

**Example Test Structure**:
```typescript
// frontend/__tests__/quality.test.tsx

import { render, screen, waitFor } from '@testing-library/react'
import QualityPage from '@/app/dashboard/quality/page'

test('renders quality metrics', async () => {
  render(<QualityPage />)
  await waitFor(() => {
    expect(screen.getByText(/Quality Metrics/i)).toBeInTheDocument()
  })
})
```

##### Integration Tests (3 tests)

1. **Evaluation Flow**: Ingest trace → Evaluate → Query results
2. **Guardrail Flow**: Create rule → Ingest trace with PII → Verify violation
3. **Alert Flow**: Create rule → Trigger threshold → Send notification

---

#### Day 15: Docker & Integration

**Objective**: Update Docker configuration and gateway proxy for all new services

##### Update docker-compose.yml

Add 4 new services:

```yaml
services:
  # ... existing services ...

  evaluation:
    build: ./backend/evaluation
    container_name: agent_obs_evaluation
    environment:
      - POSTGRES_URL=postgresql://postgres:postgres@postgres:5432/agent_observability_metadata
      - REDIS_URL=redis://:redis123@redis:6379/0
      - GEMINI_API_KEY=${GEMINI_API_KEY}
    ports:
      - "8004:8004"
    depends_on:
      - postgres
      - redis

  guardrail:
    build: ./backend/guardrail
    container_name: agent_obs_guardrail
    ports:
      - "8005:8005"

  alert:
    build: ./backend/alert
    container_name: agent_obs_alert
    ports:
      - "8006:8006"

  gemini:
    build: ./backend/gemini
    container_name: agent_obs_gemini
    ports:
      - "8007:8007"
```

##### Update Gateway Proxy Routes

Add to `backend/gateway/app/proxy/routes.py`:

```python
# Service URLs
EVALUATION_SERVICE_URL = "http://evaluation:8004"
GUARDRAIL_SERVICE_URL = "http://guardrail:8005"
ALERT_SERVICE_URL = "http://alert:8006"
GEMINI_SERVICE_URL = "http://gemini:8007"

# Proxy routes
@router.api_route("/api/v1/evaluate/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_evaluate(request: Request, path: str):
    return await proxy_request(request, EVALUATION_SERVICE_URL)

@router.api_route("/api/v1/guardrails/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_guardrails(request: Request, path: str):
    return await proxy_request(request, GUARDRAIL_SERVICE_URL)

@router.api_route("/api/v1/alerts/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_alerts(request: Request, path: str):
    return await proxy_request(request, ALERT_SERVICE_URL)

@router.api_route("/api/v1/alert-rules/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_alert_rules(request: Request, path: str):
    return await proxy_request(request, ALERT_SERVICE_URL)

@router.api_route("/api/v1/insights/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_insights(request: Request, path: str):
    return await proxy_request(request, GEMINI_SERVICE_URL)

@router.api_route("/api/v1/business-goals/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_business_goals(request: Request, path: str):
    return await proxy_request(request, GEMINI_SERVICE_URL)
```

---

## Environment Variables

Add to `.env` file:

```bash
# Phase 4 Environment Variables

# Google Gemini API
GEMINI_API_KEY=your_gemini_api_key_here

# Evaluation Service
EVALUATION_PORT=8004
CACHE_TTL_EVALUATIONS=300  # 5 minutes

# Guardrail Service
GUARDRAIL_PORT=8005
CACHE_TTL_RULES=600  # 10 minutes

# Alert Service
ALERT_PORT=8006
WEBHOOK_TIMEOUT_SECONDS=10
ALERT_CHECK_INTERVAL_SECONDS=60

# Gemini Integration Service
GEMINI_PORT=8007
CACHE_TTL_INSIGHTS=1800  # 30 minutes
```

---

## Quality Checklist

Before marking Phase 4 complete, verify:

### Backend Services
- [ ] All 4 services build successfully with Docker
- [ ] All 20 endpoints return 200/201 responses for valid requests
- [ ] All endpoints return proper error codes for invalid requests
- [ ] Gemini API integration works (with valid API key)
- [ ] PII detection catches all pattern types
- [ ] Toxicity detection produces reasonable scores
- [ ] Alert threshold logic works correctly
- [ ] Anomaly detection identifies outliers
- [ ] All services connect to databases successfully
- [ ] Redis caching works for all services

### Frontend Pages
- [ ] Quality page displays evaluation metrics
- [ ] Safety page shows violation trends
- [ ] Impact page renders business goals
- [ ] All charts render without errors
- [ ] Time range selectors work
- [ ] Loading states display properly
- [ ] Error states handle API failures gracefully
- [ ] Data refreshes on user actions

### Synthetic Data
- [ ] 1000 evaluation records generated
- [ ] 200 violation records generated
- [ ] 50 alert notifications generated
- [ ] 10 business goals created
- [ ] Home page quality_score metric works
- [ ] All data uses correct workspace_id
- [ ] Verification queries return expected counts

### Testing
- [ ] All 32 backend tests pass
- [ ] All 9 frontend tests pass
- [ ] All 3 integration tests pass
- [ ] Test coverage > 80% for new code
- [ ] CI/CD pipeline runs successfully

### Docker & Integration
- [ ] docker-compose up builds all 8 services
- [ ] All services show healthy status
- [ ] Gateway routes requests to new services
- [ ] Inter-service communication works
- [ ] Environment variables configured correctly

---

## Troubleshooting Guide

### Common Issues

**Gemini API Errors**:
- Verify API key is set correctly in .env
- Check API quota and rate limits
- Ensure internet connectivity from container
- Add retry logic with exponential backoff

**PII Detection False Positives**:
- Tune regex patterns for accuracy
- Add whitelisting for known safe patterns
- Implement confidence scoring
- Allow manual review and override

**Alert Spam**:
- Increase window_minutes for rules
- Add cooldown period between alerts
- Implement alert deduplication
- Add snooze functionality

**Database Connection Issues**:
- Verify service dependencies in docker-compose
- Check database connection strings
- Ensure healthchecks pass before starting services
- Review database logs for errors

---

## Phase 4 Success Criteria

Phase 4 is complete when:

1. **All 4 backend services deployed** and accessible via gateway
2. **All 20 API endpoints functional** with proper error handling
3. **All 3 frontend pages render** with real-time data
4. **1400+ synthetic data records** generated with correct workspace
5. **44 tests passing** (32 backend + 9 frontend + 3 integration)
6. **Docker Compose working** with all 8 services healthy
7. **Gemini integration functional** for evaluations and insights
8. **PII detection accurate** across all pattern types
9. **Alerting system operational** with webhook notifications
10. **Documentation complete** with API specs and setup guide

---

## Appendix: File Structure

```
backend/
├── evaluation/
│   ├── app/
│   │   ├── main.py
│   │   ├── routes/evaluate.py
│   │   ├── models.py
│   │   ├── database.py
│   │   ├── config.py
│   │   └── gemini_client.py
│   ├── tests/test_evaluate.py
│   ├── Dockerfile
│   └── requirements.txt
├── guardrail/
│   ├── app/
│   │   ├── main.py
│   │   ├── routes/guardrails.py
│   │   ├── models.py
│   │   ├── database.py
│   │   ├── config.py
│   │   └── detectors/
│   │       ├── pii.py
│   │       ├── toxicity.py
│   │       └── injection.py
│   ├── tests/test_guardrails.py
│   ├── Dockerfile
│   └── requirements.txt
├── alert/
│   ├── app/
│   │   ├── main.py
│   │   ├── routes/alerts.py
│   │   ├── models.py
│   │   ├── database.py
│   │   ├── config.py
│   │   ├── monitoring.py
│   │   ├── detectors/
│   │   │   ├── threshold.py
│   │   │   └── anomaly.py
│   │   └── notifications/webhook.py
│   ├── tests/test_alerts.py
│   ├── Dockerfile
│   └── requirements.txt
├── gemini/
│   ├── app/
│   │   ├── main.py
│   │   ├── routes/insights.py
│   │   ├── models.py
│   │   ├── database.py
│   │   ├── config.py
│   │   ├── gemini_client.py
│   │   └── prompts.py
│   ├── tests/test_insights.py
│   ├── Dockerfile
│   └── requirements.txt
└── db/
    ├── get-workspace-id.sql
    ├── seed-evaluations.sql
    ├── seed-violations.sql
    ├── seed-alerts.sql
    └── seed-business-goals.sql

frontend/
├── app/dashboard/
│   ├── quality/page.tsx (REPLACE)
│   ├── safety/page.tsx (REPLACE)
│   └── impact/page.tsx (REPLACE)
├── components/
│   ├── quality/
│   │   ├── QualityScoreCard.tsx
│   │   ├── QualityTrendChart.tsx
│   │   └── ...
│   ├── safety/
│   │   ├── ViolationKPICard.tsx
│   │   └── ...
│   └── impact/
│       ├── ROICard.tsx
│       └── ...
└── __tests__/
    ├── quality.test.tsx
    ├── safety.test.tsx
    └── impact.test.tsx
```

---

**END OF CLAUDE.MD - PHASE 4 IMPLEMENTATION GUIDE**
