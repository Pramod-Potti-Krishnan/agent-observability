# Agent Observability Platform

AI Agent and LLM Observability Solution for monitoring, analyzing, and optimizing AI agent performance.

## 🚀 Quick Start

```bash
# 1. Clone and setup
cp .env.example .env
chmod +x setup.sh
./setup.sh

# 2. Start the frontend
cd frontend
npm run dev

# 3. Visit http://localhost:3000
```

**That's it!** The defaults work for local development.

**macOS Users:** If you encounter "pg_config executable not found", see [MACOS_SETUP.md](MACOS_SETUP.md) (already fixed in latest setup.sh).

## 📋 What is This?

A comprehensive observability platform for AI agents and LLMs that provides:

- **Usage Analytics** - Track API calls, token usage, model distribution
- **Cost Management** - Monitor spending, budget tracking, cost optimization
- **Performance Metrics** - Latency percentiles, throughput, error rates
- **Quality Evaluation** - AI-powered response quality scoring with Gemini
- **Safety & Guardrails** - PII detection, toxicity filtering, prompt injection detection
- **Business Impact** - ROI tracking, goal management, KPI dashboards

## 🏗️ Project Status

**✅ Phase 0 Complete** - Foundation & Infrastructure (Week 1-2)

- Docker Compose with TimescaleDB, PostgreSQL, Redis
- Database schemas with retention policies
- Synthetic data generator (10,000+ traces)
- Next.js 14 frontend with shadcn/ui
- 8 dashboard pages with navigation
- 8 passing tests

**➡️ Next: Phase 1** - Core Backend Services (Week 3-5)

## 📚 Documentation

### Getting Started
- **[ENV_QUICKSTART.md](ENV_QUICKSTART.md)** - Environment setup (TL;DR version)
- **[PHASE_0_COMPLETE.md](PHASE_0_COMPLETE.md)** - What was built in Phase 0
- **[setup.sh](setup.sh)** - Automated setup script

### Comprehensive Guides
- **[docs/ENVIRONMENT_SETUP.md](docs/ENVIRONMENT_SETUP.md)** - Complete environment configuration
- **[docs/frontend-architecture.md](docs/frontend-architecture.md)** - Frontend architecture
- **[docs/backend-services-architecture.md](docs/backend-services-architecture.md)** - Backend services
- **[docs/database-schema-design.md](docs/database-schema-design.md)** - Database design
- **[docs/integration-strategies.md](docs/integration-strategies.md)** - Integration patterns

### Reference
- **[.env.example](.env.example)** - Environment variables template (heavily commented)

## 🔧 Environment Configuration

### Is .env Required?

| Phase | Required? | What's Needed |
|-------|-----------|---------------|
| **Phase 0** (Current) | Optional | Defaults work fine |
| **Phase 1+** (Backend) | Yes | JWT secrets required |
| **Phase 4** (AI Features) | Yes | Gemini API key needed |
| **Production** | Critical | All values must be secure |

### Quick Setup

```bash
# For Phase 0 (now)
cp .env.example .env
# Defaults work! No changes needed.

# Verify configuration
cd backend
python check_env.py

# Test database connections
python test_connections.py
```

### For Phase 1+ (later)

```bash
# Generate secure secrets
echo "JWT_SECRET=$(openssl rand -base64 32)" >> .env
echo "API_KEY_SALT=$(openssl rand -base64 32)" >> .env
```

### For Phase 4 (AI features)

```bash
# Get Gemini API key from: https://makersuite.google.com/app/apikey
echo "GEMINI_API_KEY=your-key-here" >> .env
```

**See [ENV_QUICKSTART.md](ENV_QUICKSTART.md) for detailed instructions.**

## 🛠️ Tech Stack

### Frontend
- **Framework:** Next.js 14 (App Router)
- **UI Library:** shadcn/ui (all components, no plain HTML)
- **Styling:** Tailwind CSS
- **State:** TanStack Query + Zustand
- **Charts:** Recharts
- **Language:** TypeScript (strict mode)

### Backend (Phase 1+)
- **Framework:** FastAPI (Python 3.11+)
- **Architecture:** Microservices (7 services)
- **Message Queue:** Redis Streams
- **Real-time:** Redis Pub/Sub + WebSockets

### Databases
- **TimescaleDB** - Time-series metrics
- **PostgreSQL** - Relational data
- **Redis** - Caching & queues

### AI/ML (Phase 4+)
- **Google Gemini** - Quality evaluation
- **Custom Models** - Guardrails & detection

## 📁 Project Structure

```
Agent Monitoring/
├── backend/
│   ├── db/                      # Database init scripts
│   ├── alembic/                 # Database migrations
│   ├── synthetic_data/          # Data generator
│   ├── tests/                   # Test suite
│   ├── check_env.py            # Config checker
│   └── test_connections.py     # Connection tester
├── frontend/
│   ├── app/
│   │   └── (dashboard)/        # Dashboard pages
│   ├── components/
│   │   ├── ui/                 # shadcn/ui components
│   │   └── layout/             # Layout components
│   └── lib/                    # Utilities
├── docs/                       # Documentation
├── docker-compose.yml          # Docker services
├── .env.example               # Config template
└── setup.sh                   # Setup script
```

## 🧪 Testing

```bash
cd backend
source venv/bin/activate
pytest

# Expected output:
# ✅ 8 tests passing
#    - 3 database connection tests
#    - 3 schema validation tests
#    - 2 synthetic data tests
```

## 🚦 Verification Checklist

Before moving to Phase 1, verify:

```bash
# 1. Check Docker
docker-compose ps
# All services should be "Up"

# 2. Check environment
cd backend
python check_env.py
# Should show ✅ for required variables

# 3. Test connections
python test_connections.py
# Should show ✅ for all databases

# 4. Run tests
pytest
# Should show 8 passing tests

# 5. Check frontend
cd ../frontend
npm run dev
# Should start without errors
```

## 🎯 Development Phases

### Phase 0: Foundation ✅ (Week 1-2) - COMPLETE
- Docker infrastructure
- Database schemas
- Synthetic data generator
- Frontend scaffolding
- 8 tests

### Phase 1: Core Backend (Week 3-5)
- API Gateway
- Ingestion Service
- Processing Service
- 30 tests

### Phase 2: Query + Basic UI (Week 6-8)
- Query Service
- Home page with real data
- 21 tests

### Phase 3: Core Pages (Week 9-11)
- Usage, Cost, Performance pages
- Charts with Recharts
- 27 tests

### Phase 4: Advanced Features (Week 12-14)
- Quality, Safety, Impact pages
- Gemini evaluation
- Guardrails
- 30 tests

### Phase 5: Settings + SDKs (Week 15-16)
- Settings page
- Python SDK
- TypeScript SDK
- 12 tests

### Phase 6: Production Ready (Week 17-20)
- WebSocket real-time
- Performance optimization
- E2E tests
- Deployment

**Total Timeline:** 16-20 weeks | **Total Tests:** 133

## 🔒 Security

### Development
- Simple passwords OK for local
- `.env` file (gitignored)
- Debug mode enabled

### Production
- Strong secrets (32+ chars)
- Environment variables (not files)
- SSL/TLS everywhere
- Managed databases
- No default passwords
- Debug mode disabled

## 🤝 Contributing

This is a development project following a phased implementation plan. Each phase builds on the previous with comprehensive testing.

## 📊 Features by Phase

| Feature | Phase | Status |
|---------|-------|--------|
| Docker Infrastructure | 0 | ✅ |
| Database Schemas | 0 | ✅ |
| Synthetic Data | 0 | ✅ |
| Frontend Scaffolding | 0 | ✅ |
| API Gateway | 1 | ⏳ |
| Trace Ingestion | 1 | ⏳ |
| Metrics Processing | 1 | ⏳ |
| Query API | 2 | ⏳ |
| Home Dashboard | 2 | ⏳ |
| Usage Analytics | 3 | ⏳ |
| Cost Management | 3 | ⏳ |
| Performance Metrics | 3 | ⏳ |
| Quality Evaluation | 4 | ⏳ |
| Safety Guardrails | 4 | ⏳ |
| Business Impact | 4 | ⏳ |
| Settings | 5 | ⏳ |
| Python SDK | 5 | ⏳ |
| TypeScript SDK | 5 | ⏳ |
| Real-time Updates | 6 | ⏳ |

## 🛟 Getting Help

### Troubleshooting

**Docker containers not starting:**
```bash
docker-compose down
docker-compose up -d
docker-compose logs -f
```

**Database connection errors:**
```bash
python backend/test_connections.py
```

**Frontend build errors:**
```bash
cd frontend
rm -rf .next node_modules
npm install
npm run dev
```

**Environment issues:**
```bash
python backend/check_env.py
```

### Documentation
- Environment: [ENV_QUICKSTART.md](ENV_QUICKSTART.md)
- Phase 0: [PHASE_0_COMPLETE.md](PHASE_0_COMPLETE.md)
- Full docs: [docs/](docs/)

## 📝 License

MIT License - See LICENSE file for details

## 🙏 Acknowledgments

- Built with Next.js, FastAPI, TimescaleDB
- UI components from shadcn/ui
- Charts with Recharts
- AI features powered by Google Gemini

---

**Current Status:** Phase 0 Complete ✅
**Next Step:** Phase 1 - Core Backend Services
**Timeline:** 16-20 weeks total

For detailed setup instructions, see [ENV_QUICKSTART.md](ENV_QUICKSTART.md)
