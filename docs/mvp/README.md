# AI Agent Observability Platform - Documentation

**Version:** 1.0 (MVP Complete)
**Last Updated:** October 26, 2025
**Status:** Phases 0-4 Complete ✅

---

## Quick Start

### Essential Documentation

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **[SETUP_GUIDE.md](SETUP_GUIDE.md)** | Complete installation and configuration guide | Getting started, first-time setup |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | Complete system architecture, services, data flows | Understanding how the platform works |
| **[API_REFERENCE.md](API_REFERENCE.md)** | All API endpoints with examples | Integrating with the platform |
| **[DATABASE_REFERENCE.md](DATABASE_REFERENCE.md)** | Complete database schemas and query examples | Database design, queries, optimization |
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | Common issues and solutions | When something isn't working |

---

## What Was Built (MVP)

### Phases 0-4 Complete

**Phase 0: Foundation** ✅
- Docker infrastructure (TimescaleDB, PostgreSQL, Redis)
- Database schemas with hypertables and retention policies
- Next.js 14 frontend with shadcn/ui
- Synthetic data generator (10,000+ traces)

**Phase 1: Core Backend Services** ✅
- Gateway Service (Port 8000) - Auth, routing, rate limiting
- Ingestion Service (Port 8001) - Trace ingestion
- Processing Service (Background) - Async trace processing

**Phase 2: Query Service + Frontend Integration** ✅
- Query Service (Port 8003) - Analytics API
- Dashboard components (KPI cards, alerts, activity feed)
- Multi-tier Redis caching
- Authentication pages (login/register)

**Phase 3: Core Analytics Pages** ✅
- Usage Analytics Dashboard
- Cost Management Dashboard
- Performance Monitoring Dashboard
- 13 API endpoints with caching

**Phase 4: Advanced Features + AI** ✅
- Evaluation Service (Port 8004) - Quality scoring with Google Gemini
- Guardrail Service (Port 8005) - PII detection, toxicity filtering
- Alert Service (Port 8006) - Threshold monitoring, anomaly detection
- Gemini Integration Service (Port 8007) - AI insights
- Quality, Safety, and Business Impact Dashboards

**Phase 5: Settings + SDKs** ⏸️
- *Not implemented in MVP* (planned for enterprise version)
- Will include: Team management, API key UI, Python/TypeScript SDKs

---

## System Architecture

### Services Running

| Service | Port | Status | Purpose |
|---------|------|--------|---------|
| **Frontend** | 3000 | ✅ | Next.js UI with 7 dashboards |
| **Gateway** | 8000 | ✅ | API gateway, auth, routing |
| **Ingestion** | 8001 | ✅ | Trace ingestion |
| **Processing** | - | ✅ | Background trace processor |
| **Query** | 8003 | ✅ | Analytics API (13+ endpoints) |
| **Evaluation** | 8004 | ✅ | Quality evaluation with Gemini |
| **Guardrail** | 8005 | ✅ | Safety and PII detection |
| **Alert** | 8006 | ✅ | Monitoring and notifications |
| **Gemini** | 8007 | ✅ | AI insights |
| **TimescaleDB** | 5432 | ✅ | Time-series metrics |
| **PostgreSQL** | 5433 | ✅ | Relational metadata |
| **Redis** | 6379 | ✅ | Cache & queues |

---

## Quick Commands

### Start the Platform

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f [service-name]
```

### Access URLs

- **Frontend:** http://localhost:3000
- **API Gateway:** http://localhost:8000
- **API Docs:** http://localhost:8000/docs (FastAPI auto-docs)

### Test the API

```bash
# Register a user
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{
    "email":"test@example.com",
    "password":"SecurePass123",
    "full_name":"Test User",
    "workspace_name":"Test Workspace"
  }'

# Login (get JWT token)
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{
    "email":"test@example.com",
    "password":"SecurePass123"
  }'

# Get workspace ID from response, then query metrics
export WORKSPACE_ID="your-workspace-id"

curl "http://localhost:8003/api/v1/metrics/home-kpis?range=24h" \
  -H "X-Workspace-ID: $WORKSPACE_ID"
```

---

## Tech Stack

### Backend
- Python 3.11+ with FastAPI (async)
- TimescaleDB (time-series metrics)
- PostgreSQL (relational data)
- Redis (caching + streams)
- Google Gemini API (AI features)

### Frontend
- Next.js 14 (App Router)
- React 18 with TypeScript
- shadcn/ui components
- TanStack Query (data fetching)
- Recharts (visualization)

### Infrastructure
- Docker Compose (development)
- 8 microservices + 3 databases

---

## Dashboard Pages

1. **Home** (`/dashboard`) - KPIs, alerts, activity stream
2. **Usage Analytics** (`/dashboard/usage`) - API calls, users, agents
3. **Cost Management** (`/dashboard/cost`) - Spend tracking, budgets
4. **Performance** (`/dashboard/performance`) - Latency, throughput, errors
5. **Quality** (`/dashboard/quality`) - AI-powered evaluations
6. **Safety** (`/dashboard/safety`) - Guardrails, violations
7. **Impact** (`/dashboard/impact`) - ROI, business goals

---

## Other References

Historical planning documents and phase-specific reports are available in **`other-references/`**:

```
other-references/
├── planning/          - PRDs, specs, future plans (Phase 5)
├── phase-reports/     - Completion reports (Phases 0-4)
├── summaries/         - Quick references and component docs
├── wip/               - Work-in-progress trackers
├── temporary/         - Quick fixes
└── checklists/        - File inventories
```

---

## Getting Help

### Common Issues

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for solutions to:
- Docker container errors
- Database connection issues
- Frontend build errors
- Environment configuration problems

### Documentation

- **Setup Guide:** [SETUP_GUIDE.md](SETUP_GUIDE.md) - Installation and configuration
- **Architecture:** [ARCHITECTURE.md](ARCHITECTURE.md) - System design and components
- **API Reference:** [API_REFERENCE.md](API_REFERENCE.md) - Complete endpoint documentation
- **Database Reference:** [DATABASE_REFERENCE.md](DATABASE_REFERENCE.md) - Schema and queries
- **Troubleshooting:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions

---

## Next Steps (Future Work)

### Phase 5: Settings + SDKs (Enterprise Version)
- Multi-tab Settings page (workspace, team, billing, integrations)
- Python SDK (`agent-observability` package)
- TypeScript SDK (`@agent-observability/sdk` package)
- Advanced RBAC and team management

### Phase 6: Production Ready
- WebSocket real-time updates
- Performance optimization
- Kubernetes deployment
- E2E testing suite
- Production monitoring

---

## Success Metrics (MVP)

### What We Achieved

- ✅ **8 microservices** running in Docker Compose
- ✅ **3 databases** (TimescaleDB, PostgreSQL, Redis)
- ✅ **7 dashboard pages** with real-time data
- ✅ **13+ API endpoints** with caching
- ✅ **10,000+ synthetic traces** for testing
- ✅ **AI features** (Gemini evaluation, insights, safety)
- ✅ **Multi-tenant** architecture (workspace isolation)
- ✅ **Complete observability:** usage, cost, performance, quality, safety, impact

### Test Coverage

- **Backend:** 60+ unit tests across all services
- **Frontend:** Component tests for all pages
- **Integration:** End-to-end flow tests
- **Total:** 80+ tests passing

---

## License

MIT License - See LICENSE file for details

---

## Acknowledgments

- Built with Next.js, FastAPI, TimescaleDB
- UI components from shadcn/ui
- Charts with Recharts
- AI features powered by Google Gemini

---

**Current Status:** MVP Complete (Phases 0-4) ✅
**Timeline:** 14 weeks (Phase 0-4)
**Next Milestone:** Enterprise Version (Phase 5+)

For detailed documentation, start with [ARCHITECTURE.md](ARCHITECTURE.md).
