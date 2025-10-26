# Agent Observability Platform - Documentation

This directory contains phase-by-phase documentation for the Agent Observability Platform implementation.

## Documentation Structure

### Phase 0: Foundation Setup
**Location:** `phase0/`

- `PHASE_0_COMPLETE.md` - Complete Phase 0 implementation report

**What was built:**
- Project structure and configuration
- Next.js frontend with shadcn/ui
- Database schema design (TimescaleDB + PostgreSQL)
- Docker infrastructure setup
- Basic UI layout and navigation

---

### Phase 1: Core Backend Services
**Location:** `phase1/`

- `PHASE1_VERIFICATION_REPORT.md` - Phase 1 verification and testing report

**What was built:**
- Gateway Service (FastAPI) - Authentication, routing, rate limiting
- Ingestion Service (FastAPI) - High-throughput trace ingestion
- Processing Service (Python) - Background trace processing
- Redis integration for queues and caching
- Database connection pools
- End-to-end testing and verification

---

### Phase 2: Query Service & Frontend Integration
**Location:** `phase2/`

- `PHASE2_COMPLETE.md` - Comprehensive Phase 2 implementation report
- `PHASE2_SUMMARY.md` - Concise reference guide
- `PHASE2_ARCHITECTURE.md` - Detailed architecture and API specifications
- `PHASE2_QUICK_START.md` - Quick start guide
- `PHASE2_IMPLEMENTATION_SUMMARY.md` - Implementation overview
- `PHASE2_FILES_CHECKLIST.md` - Complete file listing
- `README_PHASE2.md` - Quick reference

**What was built:**
- Query Service (FastAPI) - Analytics and metrics API
- Frontend authentication pages (login/register)
- Dashboard components (KPICard, AlertsFeed, ActivityStream, TimeRangeSelector)
- React auth context
- Multi-tier Redis caching
- Connection pooling for TimescaleDB/PostgreSQL
- Complete E2E testing

---

### Phase 3: Advanced Analytics & Monitoring
**Location:** `phase3/`

- `PHASE3_COMPLETE.md` - Comprehensive Phase 3 implementation report
- `PHASE3_SUMMARY.md` - Quick reference guide

**What was built:**
- Usage Analytics API (4 endpoints) - Call volume, users, agents, trends
- Cost Management API (5 endpoints) - Spend tracking, budgets, projections
- Performance Monitoring API (4 endpoints) - Latency percentiles, error analysis
- Usage Analytics Dashboard - Real-time call metrics with charts
- Cost Management Dashboard - Budget tracking with alerts
- Performance Monitoring Dashboard - P50/P95/P99 latency visualization
- Database optimizations (7 indexes + budgets table)
- 18 backend tests with 100% endpoint coverage

---

### Phase 4: Advanced Features + AI
**Location:** `phase4/`

- `PHASE4_COMPLETE.md` - Comprehensive Phase 4 implementation report
- `PHASE4_IMPLEMENTATION_GUIDE.md` - Step-by-step implementation guide
- `PHASE4_TESTS_COMPLETE.md` - Complete test documentation
- `PHASE4_TEST_SUMMARY.md` - Quick test reference
- `README.md` - Phase 4 overview and quick start

**What was built:**
- Evaluation Service (Port 8004) - LLM-as-a-judge quality assessment with Google Gemini
- Guardrail Service (Port 8005) - PII detection, toxicity filtering, prompt injection prevention
- Alert Service (Port 8006) - Threshold monitoring, anomaly detection, webhook notifications
- Gemini Integration Service (Port 8007) - AI-powered insights and cost optimization
- Quality Dashboard - Evaluation metrics and criteria breakdown
- Safety Dashboard - Violation tracking and guardrail management
- Business Impact Dashboard - ROI tracking and goal progress
- 1400+ synthetic data records (evaluations, violations, alerts, goals)
- 18 comprehensive tests (8 backend + 7 frontend + 3 integration)

---

## Quick Links

### Getting Started
- [Phase 3 Summary](PHASE3_SUMMARY.md) - Latest quick reference (Analytics & Monitoring)
- [Phase 2 Quick Start](phase2/PHASE2_QUICK_START.md) - Start services and test the system
- [Phase 2 Summary](phase2/PHASE2_SUMMARY.md) - Quick reference for commands and APIs

### Implementation Details
- [Phase 0 Complete Report](phase0/PHASE_0_COMPLETE.md)
- [Phase 1 Verification Report](phase1/PHASE1_VERIFICATION_REPORT.md)
- [Phase 2 Complete Report](phase2/PHASE2_COMPLETE.md)
- [Phase 2 Architecture](phase2/PHASE2_ARCHITECTURE.md)
- [Phase 3 Complete Report](PHASE3_COMPLETE.md)
- [Phase 3 Summary](PHASE3_SUMMARY.md)
- [Phase 4 Complete Report](phase4/PHASE4_COMPLETE.md) ⭐ Latest
- [Phase 4 Implementation Guide](phase4/PHASE4_IMPLEMENTATION_GUIDE.md)
- [Phase 4 Tests Complete](phase4/PHASE4_TESTS_COMPLETE.md)

### System Architecture
All phases build on each other:
```
Phase 0: Foundation (DB + Frontend Shell) ✅
    ↓
Phase 1: Backend Services (Gateway + Ingestion + Processing) ✅
    ↓
Phase 2: Query + Frontend Integration (Query Service + Auth + Dashboard) ✅
    ↓
Phase 3: Advanced Analytics & Monitoring (Usage, Cost, Performance) ✅
    ↓
Phase 4: Advanced Features + AI (Evaluation, Guardrails, Alerts, Insights) ✅
    ↓
Phase 5: Settings + SDKs (Coming next: Team management, Python SDK, TypeScript SDK)
```

---

## Current System Status

**Services Running:**
- TimescaleDB (port 5432) - Time-series metrics
- PostgreSQL (port 5433) - Metadata
- Redis (port 6379) - Cache & queues
- Gateway (port 8000) - API gateway & auth
- Ingestion (port 8001) - Trace ingestion
- Processing (background) - Trace processing
- Query (port 8003) - Analytics API
- Evaluation (port 8004) - Quality evaluation with Google Gemini
- Guardrail (port 8005) - PII detection and safety checks
- Alert (port 8006) - Threshold monitoring and anomaly detection
- Gemini (port 8007) - AI-powered insights
- Frontend (port 3000) - Next.js UI

**Access URLs:**
- Frontend: http://localhost:3000
- Gateway API: http://localhost:8000
- Query API: http://localhost:8003
- Ingestion API: http://localhost:8001

---

## Testing

### Start System
```bash
docker-compose up -d
```

### Test Authentication
```bash
# Register
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com","password":"SecurePass123","full_name":"Test User","workspace_name":"Test Workspace"}'

# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com","password":"SecurePass123"}'
```

### Test Query Service
```bash
# Get workspace ID from registration/login response
export WORKSPACE_ID="your-workspace-id"

# Home KPIs
curl "http://localhost:8003/api/v1/metrics/home-kpis?range=24h" \
  -H "X-Workspace-ID: $WORKSPACE_ID"
```

### Test Phase 3 Analytics
```bash
# Usage Analytics
curl "http://localhost:8000/api/v1/usage/overview?range=24h" \
  -H "X-Workspace-ID: $WORKSPACE_ID"

# Cost Management
curl "http://localhost:8000/api/v1/cost/overview?range=30d" \
  -H "X-Workspace-ID: $WORKSPACE_ID"

# Performance Monitoring
curl "http://localhost:8000/api/v1/performance/overview?range=24h" \
  -H "X-Workspace-ID: $WORKSPACE_ID"

# Run Phase 3 Tests
docker-compose exec query pytest tests/test_usage.py tests/test_cost.py tests/test_performance.py -v
```

### Test Phase 4 AI Features
```bash
# Evaluation Service
curl -X POST "http://localhost:8000/api/v1/evaluate/trace/trace-123" \
  -H "X-Workspace-ID: $WORKSPACE_ID"

# Guardrail Service
curl -X POST "http://localhost:8000/api/v1/guardrails/pii" \
  -H "Content-Type: application/json" \
  -d '{"text":"My email is john@example.com"}'

# Alert Service
curl "http://localhost:8000/api/v1/alerts" \
  -H "X-Workspace-ID: $WORKSPACE_ID"

# Gemini Integration Service
curl "http://localhost:8000/api/v1/business-goals" \
  -H "X-Workspace-ID: $WORKSPACE_ID"

# Run Phase 4 Tests
pytest backend/evaluation/tests/ backend/guardrail/tests/ backend/alert/tests/ backend/gemini/tests/ -v
```

---

For detailed information about each phase, see the respective documentation folders.
