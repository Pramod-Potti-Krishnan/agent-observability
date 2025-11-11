# AI Agent Observability Platform - Documentation

**Version:** 1.0 (MVP Complete - Phases 0-4)
**Last Updated:** October 26, 2025

---

## Documentation Structure

```
docs/
├── README.md          # Documentation navigation guide
│
└── mvp/               # Complete MVP documentation (Phases 0-4)
    ├── README.md      # MVP documentation index
    ├── SETUP_GUIDE.md
    ├── ARCHITECTURE.md
    ├── API_REFERENCE.md
    ├── DATABASE_REFERENCE.md
    ├── TROUBLESHOOTING.md
    │
    └── other-references/  # Historical documentation
        ├── planning/      # PRDs, specs, Phase 5 planning
        ├── phase-reports/ # Completion reports (Phases 0-4)
        ├── summaries/     # Component docs, quick references
        ├── wip/           # Work-in-progress trackers
        ├── temporary/     # Quick fixes
        └── checklists/    # File inventories
```

---

## Quick Start

### For New Users
👉 **Start here:** [mvp/README.md](mvp/README.md) → [mvp/SETUP_GUIDE.md](mvp/SETUP_GUIDE.md)

### For Developers
👉 **Start here:** [mvp/README.md](mvp/README.md) → [mvp/ARCHITECTURE.md](mvp/ARCHITECTURE.md)

### For API Integration
👉 **Start here:** [mvp/README.md](mvp/README.md) → [mvp/API_REFERENCE.md](mvp/API_REFERENCE.md)

### For Database Work
👉 **Start here:** [mvp/README.md](mvp/README.md) → [mvp/DATABASE_REFERENCE.md](mvp/DATABASE_REFERENCE.md)

---

## MVP Documentation (Phases 0-4)

All essential documentation for the completed MVP is in the **`mvp/`** folder:

| Document | Purpose | Audience |
|----------|---------|----------|
| **[README.md](mvp/README.md)** | MVP documentation index | All users |
| **[SETUP_GUIDE.md](mvp/SETUP_GUIDE.md)** | Complete installation & configuration | New users, DevOps |
| **[ARCHITECTURE.md](mvp/ARCHITECTURE.md)** | Complete system architecture | Developers, Architects |
| **[API_REFERENCE.md](mvp/API_REFERENCE.md)** | All API endpoints with examples | API consumers, Integrators |
| **[DATABASE_REFERENCE.md](mvp/DATABASE_REFERENCE.md)** | Complete database schemas | DBAs, Backend developers |
| **[TROUBLESHOOTING.md](mvp/TROUBLESHOOTING.md)** | Common issues and solutions | All users |

---

## What Was Built (MVP)

### Completed Phases

**Phase 0: Foundation** ✅
- Docker infrastructure (TimescaleDB, PostgreSQL, Redis)
- Database schemas with hypertables
- Next.js 14 frontend with shadcn/ui
- Synthetic data generator (10,000+ traces)

**Phase 1: Core Backend Services** ✅
- Gateway Service (Port 8000) - Auth, routing, rate limiting
- Ingestion Service (Port 8001) - Trace ingestion
- Processing Service (Background) - Async trace processing

**Phase 2: Query Service + Frontend** ✅
- Query Service (Port 8003) - Analytics API
- Dashboard components (KPI cards, alerts, activity feed)
- Multi-tier Redis caching
- Authentication pages

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
- Not implemented in MVP (planned for enterprise version)
- See `archive/planning/Phase5_Planning.md` for details

---

## System Overview

### Services

| Service | Port | Purpose |
|---------|------|---------|
| Frontend | 3000 | Next.js UI with 7 dashboards |
| Gateway | 8000 | API gateway, auth, routing |
| Ingestion | 8001 | Trace ingestion |
| Processing | - | Background trace processor |
| Query | 8003 | Analytics API (13+ endpoints) |
| Evaluation | 8004 | Quality evaluation with Gemini |
| Guardrail | 8005 | Safety and PII detection |
| Alert | 8006 | Monitoring and notifications |
| Gemini | 8007 | AI insights |
| TimescaleDB | 5432 | Time-series metrics |
| PostgreSQL | 5433 | Relational metadata |
| Redis | 6379 | Cache & queues |

### Tech Stack

**Backend:** Python 3.11+, FastAPI, TimescaleDB, PostgreSQL, Redis, Google Gemini API
**Frontend:** Next.js 14, React 18, TypeScript, shadcn/ui, TanStack Query, Recharts
**Infrastructure:** Docker Compose, 8 microservices + 3 databases

---

## Quick Commands

```bash
# Start the platform
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f [service-name]

# Access URLs
# Frontend: http://localhost:3000
# API Gateway: http://localhost:8000
# API Docs: http://localhost:8000/docs
```

---

## Other References

Historical planning documents and phase-specific reports are in **`mvp/other-references/`**:

- **planning/** - Original PRD, Phase 5 planning, future roadmap
- **phase-reports/** - Completion reports from Phases 0-4
- **summaries/** - Quick references, component documentation
- **wip/** - Work-in-progress trackers (Phase 5)
- **temporary/** - Quick fixes and patches
- **checklists/** - File inventories

---

## Next Steps

### For New Users
1. Read [mvp/README.md](mvp/README.md) for an overview
2. Follow [mvp/SETUP_GUIDE.md](mvp/SETUP_GUIDE.md) for installation
3. Explore [mvp/ARCHITECTURE.md](mvp/ARCHITECTURE.md) to understand the system

### For Developers
1. Review [mvp/ARCHITECTURE.md](mvp/ARCHITECTURE.md) for system design
2. Check [mvp/API_REFERENCE.md](mvp/API_REFERENCE.md) for API integration
3. See [mvp/DATABASE_REFERENCE.md](mvp/DATABASE_REFERENCE.md) for data models

### For Future Development
1. See `mvp/other-references/planning/Phase5_Planning.md` for enterprise version plans
2. Review `mvp/other-references/phase-reports/` to understand implementation history

---

**Current Status:** MVP Complete (Phases 0-4) ✅
**Timeline:** 14 weeks (Phases 0-4)
**Next Milestone:** Enterprise Version (Phase 5+)

For detailed documentation, see the **[mvp/](mvp/)** folder.
