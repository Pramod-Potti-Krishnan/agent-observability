# Phase 4 Testing Report - Essential Test Suite

## Overview

This document provides information about the essential test suite created for Phase 4 services of the Agent Observability Platform.

**Test Count**: 15 essential tests covering critical Phase 4 functionality
- **Backend Tests**: 8 tests (2 per service × 4 services)
- **Frontend Tests**: 4 tests (Quality, Safety, Impact dashboards + Navigation)
- **Integration Tests**: 3 tests (End-to-end flows)

---

## Backend Tests (8 tests)

### 1. Evaluation Service Tests (2 tests)
**Location**: `/backend/evaluation/tests/test_evaluate.py`

#### Tests:
1. **test_evaluate_trace_success**: Tests successful trace evaluation via POST /api/v1/evaluate/trace/{trace_id}
   - Verifies Gemini API integration (mocked)
   - Validates score ranges (0-10)
   - Checks response structure

2. **test_evaluation_history**: Tests GET /api/v1/evaluate/history returns list of evaluations
   - Verifies pagination
   - Checks aggregate statistics
   - Validates response format

**Run command**:
```bash
cd /Users/pk1980/Documents/Software/Agent Monitoring/backend/evaluation
pytest tests/test_evaluate.py -v
```

---

### 2. Guardrail Service Tests (2 tests)
**Location**: `/backend/guardrail/tests/test_guardrails.py`

#### Tests:
1. **test_pii_detection_email**: Tests POST /api/v1/guardrails/pii detects email addresses
   - Validates PII detection patterns
   - Checks redaction functionality
   - Verifies PII types

2. **test_violations_list**: Tests GET /api/v1/guardrails/violations returns violation history
   - Verifies violation tracking
   - Checks severity classification
   - Validates data structure

**Run command**:
```bash
cd /Users/pk1980/Documents/Software/Agent Monitoring/backend/guardrail
pytest tests/test_guardrails.py -v
```

---

### 3. Alert Service Tests (2 tests)
**Location**: `/backend/alert/tests/test_alerts.py`

#### Tests:
1. **test_list_alerts**: Tests GET /api/v1/alerts returns active alerts
   - Verifies alert filtering
   - Checks response structure
   - Validates alert metadata

2. **test_threshold_detection**: Tests threshold detector identifies values exceeding limits
   - Unit test for threshold logic
   - Tests boundary conditions
   - Validates detection accuracy

**Run command**:
```bash
cd /Users/pk1980/Documents/Software/Agent Monitoring/backend/alert
pytest tests/test_alerts.py -v
```

---

### 4. Gemini Integration Service Tests (2 tests)
**Location**: `/backend/gemini/tests/test_insights.py`

#### Tests:
1. **test_cost_optimization_mocked**: Tests POST /api/v1/insights/cost-optimization returns suggestions
   - Mocks Gemini API
   - Validates suggestion structure
   - Checks savings calculations

2. **test_business_goals_retrieval**: Tests GET /api/v1/business-goals returns goals list
   - Verifies goal tracking
   - Checks progress calculations
   - Validates data integrity

**Run command**:
```bash
cd /Users/pk1980/Documents/Software/Agent Monitoring/backend/gemini
pytest tests/test_insights.py -v
```

---

## Frontend Tests (4 tests)

### Location: `/frontend/__tests__/`

### 1. Quality Dashboard Tests (2 tests)
**File**: `quality.test.tsx`

#### Tests:
1. **quality dashboard renders without errors**: Verifies page loads successfully
2. **displays quality score metrics**: Checks data fetching and display

**Run command**:
```bash
cd /Users/pk1980/Documents/Software/Agent Monitoring/frontend
npm test -- quality.test.tsx
```

---

### 2. Safety Dashboard Tests (2 tests)
**File**: `safety.test.tsx`

#### Tests:
1. **safety dashboard renders violation metrics**: Verifies page loads
2. **violation table displays redacted content**: Checks PII redaction in UI

**Run command**:
```bash
cd /Users/pk1980/Documents/Software/Agent Monitoring/frontend
npm test -- safety.test.tsx
```

---

### 3. Impact Dashboard Tests (2 tests)
**File**: `impact.test.tsx`

#### Tests:
1. **impact dashboard renders business goals**: Verifies page loads
2. **displays goal progress and metrics**: Checks goal display logic

**Run command**:
```bash
cd /Users/pk1980/Documents/Software/Agent Monitoring/frontend
npm test -- impact.test.tsx
```

---

### 4. Navigation Tests (1 test)
**File**: `navigation.test.tsx`

#### Tests:
1. **Phase 4 pages are accessible via navigation**: Validates route structure

---

## Integration Tests (3 tests)

### Location: `/backend/tests/`

### 1. Evaluation Flow Test
**File**: `test_phase4_evaluation_flow.py`

**Flow**: Ingest trace → Evaluate → Query results

**Steps**:
1. POST to ingestion service to create trace
2. POST to evaluation service to evaluate trace
3. GET from evaluation service to verify results

**Prerequisites**: Ingestion service (8001), Evaluation service (8004), Gemini API key

**Run command**:
```bash
cd /Users/pk1980/Documents/Software/Agent Monitoring/backend/tests
pytest test_phase4_evaluation_flow.py -v -m integration
```

---

### 2. Guardrail Flow Test
**File**: `test_phase4_guardrail_flow.py`

**Flow**: Create rule → Check content with PII → Verify violation

**Steps**:
1. POST to create custom guardrail rule
2. POST to check content for PII
3. GET to verify violations were recorded

**Prerequisites**: Guardrail service (8005), PostgreSQL

**Run command**:
```bash
cd /Users/pk1980/Documents/Software/Agent Monitoring/backend/tests
pytest test_phase4_guardrail_flow.py -v -m integration
```

---

### 3. Alert Flow Test
**File**: `test_phase4_alert_flow.py`

**Flow**: Create alert rule → Trigger threshold → Verify notification

**Steps**:
1. POST to create alert rule
2. GET to list alert rules
3. GET to query active alerts

**Prerequisites**: Alert service (8006), PostgreSQL, TimescaleDB

**Run command**:
```bash
cd /Users/pk1980/Documents/Software/Agent Monitoring/backend/tests
pytest test_phase4_alert_flow.py -v -m integration
```

---

## Running All Tests

### Backend Unit Tests (All Services)
```bash
# From project root
cd /Users/pk1980/Documents/Software/Agent Monitoring

# Run all backend tests
pytest backend/evaluation/tests/ backend/guardrail/tests/ backend/alert/tests/ backend/gemini/tests/ -v

# With coverage
pytest backend/evaluation/tests/ backend/guardrail/tests/ backend/alert/tests/ backend/gemini/tests/ --cov=app --cov-report=html
```

### Frontend Tests (All Pages)
```bash
cd /Users/pk1980/Documents/Software/Agent Monitoring/frontend

# Run all tests
npm test

# With coverage
npm test -- --coverage

# Watch mode
npm test -- --watch
```

### Integration Tests (All Flows)
```bash
cd /Users/pk1980/Documents/Software/Agent Monitoring/backend/tests

# Run all integration tests
pytest test_phase4_*.py -v -m integration

# Run specific test
pytest test_phase4_evaluation_flow.py -v -m integration
```

---

## Test Configuration Files

### Backend (pytest)
- `/backend/evaluation/pytest.ini`
- `/backend/guardrail/pytest.ini`
- `/backend/alert/pytest.ini`
- `/backend/gemini/pytest.ini`
- `/backend/tests/pytest.ini`

### Frontend (jest)
- `/frontend/jest.config.js`
- `/frontend/jest.setup.js`

---

## Test Fixtures and Mocks

### Backend Fixtures (conftest.py files)
Each backend service has a `tests/conftest.py` with:
- `mock_gemini_client`: Mocks Google Gemini API
- `db_pool`: Mocks asyncpg database pool
- `test_client`: Configured HTTPX test client
- `mock_redis_client`: Mocks Redis for caching

### Frontend Mocks
- Global fetch mock in each test file
- QueryClient provider for TanStack Query
- Mock window.matchMedia, IntersectionObserver, ResizeObserver

---

## Prerequisites for Running Tests

### Backend Tests
1. Install pytest dependencies:
```bash
pip install pytest pytest-asyncio pytest-cov httpx
```

2. Services can be mocked (unit tests) or running (integration tests)

3. For integration tests, start services:
```bash
docker-compose up evaluation guardrail alert gemini ingestion postgres timescaledb
```

### Frontend Tests
1. Install jest dependencies:
```bash
cd frontend
npm install --save-dev jest jest-environment-jsdom @testing-library/react @testing-library/jest-dom @testing-library/user-event
```

2. No running services needed (all API calls are mocked)

---

## Expected Test Results

### Backend Tests (8 tests)
```
evaluation/tests/test_evaluate.py::test_evaluate_trace_success PASSED
evaluation/tests/test_evaluate.py::test_evaluation_history PASSED
guardrail/tests/test_guardrails.py::test_pii_detection_email PASSED
guardrail/tests/test_guardrails.py::test_violations_list PASSED
alert/tests/test_alerts.py::test_list_alerts PASSED
alert/tests/test_alerts.py::test_threshold_detection PASSED
gemini/tests/test_insights.py::test_cost_optimization_mocked PASSED
gemini/tests/test_insights.py::test_business_goals_retrieval PASSED

========================= 8 passed in X.XXs =========================
```

### Frontend Tests (4 tests)
```
PASS __tests__/quality.test.tsx
PASS __tests__/safety.test.tsx
PASS __tests__/impact.test.tsx
PASS __tests__/navigation.test.tsx

Test Suites: 4 passed, 4 total
Tests:       7 passed, 7 total
```

### Integration Tests (3 tests)
```
tests/test_phase4_evaluation_flow.py::test_evaluation_flow_end_to_end PASSED
tests/test_phase4_guardrail_flow.py::test_guardrail_flow_pii_detection PASSED
tests/test_phase4_alert_flow.py::test_alert_flow_threshold_trigger PASSED

========================= 3 passed in X.XXs =========================
```

---

## Troubleshooting

### Backend Tests

**Issue**: Tests fail with connection errors
- **Solution**: Check that mocks are properly configured in conftest.py

**Issue**: Gemini API tests fail
- **Solution**: Ensure mock_gemini_client fixture is being used

**Issue**: Database-related errors
- **Solution**: Verify db_pool fixture returns expected mock data

### Frontend Tests

**Issue**: "Cannot find module '@testing-library/react'"
- **Solution**: Run `npm install --save-dev @testing-library/react @testing-library/jest-dom`

**Issue**: "window is not defined"
- **Solution**: Ensure jest.setup.js is properly configured with window mocks

**Issue**: Tests timeout
- **Solution**: Increase timeout in waitFor() calls or check if components are actually rendering

### Integration Tests

**Issue**: Connection refused errors
- **Solution**: Start required services with docker-compose

**Issue**: Tests skip with "Service not available"
- **Solution**: This is expected if services aren't running. Start them with docker-compose up

**Issue**: Gemini API rate limit errors
- **Solution**: Add delays between tests or use test API key with higher limits

---

## Test Coverage Goals

- **Backend**: 80%+ code coverage for critical business logic
- **Frontend**: Basic rendering and data fetching coverage
- **Integration**: Critical user flows validated end-to-end

---

## Next Steps

1. **Install missing dependencies** (see commands above)
2. **Run backend unit tests** to verify mocks work correctly
3. **Run frontend tests** to ensure UI components render
4. **Start services** for integration tests
5. **Run integration tests** to validate end-to-end flows
6. **Review coverage reports** and add tests for uncovered paths

---

**Last Updated**: 2025-10-22
**Test Suite Version**: 1.0
**Phase**: 4 (Advanced Features + AI)
