# GARUDAI 🦅
**Global Agent Runtime Unified Dashboard AI**

The all-seeing guardian for your AI agents - comprehensive observability, intelligent guardrails, and actionable insights.

![GARUDAI](https://img.shields.io/badge/GARUDAI-Production%20Ready-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Next.js](https://img.shields.io/badge/Next.js-14-black)
![FastAPI](https://img.shields.io/badge/FastAPI-0.104-009688)

---

## 🦅 What is GARUDAI?

Like the mythical Garuda—the divine eagle with all-seeing vision—GARUDAI watches over your AI agent infrastructure with unmatched visibility and protection.

GARUDAI is a production-ready observability platform for AI agents and LLMs that provides:

### Core Capabilities

- 📊 **Usage Analytics** - Track API calls, token usage, model distribution, user adoption
- 💰 **Cost Management** - Real-time spending, budget alerts, optimization recommendations
- ⚡ **Performance Monitoring** - Latency percentiles, throughput, error rates, SLO tracking
- 🏆 **Quality Evaluation** - AI-powered response quality scoring with rubric-based assessments
- 🛡️ **Safety & Guardrails** - PII detection, toxicity filtering, prompt injection prevention
- 📈 **Business Impact** - ROI tracking, goal management, KPI dashboards, revenue attribution

---

## 🚀 Quick Start

### Local Development

```bash
# 1. Clone the repository
git clone https://github.com/Pramod-Potti-Krishnan/agent-observability.git
cd agent-observability

# 2. Setup environment
cp .env.example .env
# Edit .env with your configuration

# 3. Start all services with Docker Compose
docker-compose up -d

# 4. Access the dashboard
open http://localhost:3000
```

**That's it!** All services (frontend, backend, databases) start automatically.

### Production Deployment

See [DEPLOYMENT.md](./DEPLOYMENT.md) for complete deployment guide to Vercel + Railway.

**Quick Deploy:**
- **Frontend** → [![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/your-repo/garudai-frontend)
- **Backend** → [![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new/template)

---

## 📚 Documentation

### Core Documentation
- [**Setup Guide**](./docs/mvp/SETUP_GUIDE.md) - Detailed installation and configuration
- [**Deployment Guide**](./DEPLOYMENT.md) - Production deployment to Vercel + Railway
- [**API Reference**](./docs/mvp/API_REFERENCE.md) - Complete API documentation
- [**Architecture**](./docs/mvp/ARCHITECTURE.md) - System design and components

### Product Requirements
- [**MVP Features**](./docs/mvp/README.md) - Core functionality (Phase 0-5)
- [**Enterprise PRD**](./docs/enterprise/prd/overall.md) - Complete feature set (Tabs 1-11)
- [**Current State**](./docs/CURRENT_STATE_2025-11-11.md) - Implementation status report

### Additional Guides
- [**Database Reference**](./docs/mvp/DATABASE_REFERENCE.md) - Schema and queries
- [**Troubleshooting**](./docs/mvp/TROUBLESHOOTING.md) - Common issues and solutions
- [**Environment Setup**](./docs/mvp/other-references/summaries/ENVIRONMENT_SETUP.md) - Environment variables guide

---

## 🏗️ Architecture

### Technology Stack

**Frontend:**
- Next.js 14 (App Router)
- React 18 + TypeScript
- Tailwind CSS + shadcn/ui
- Recharts for visualizations

**Backend:**
- FastAPI (Python 3.11+)
- Microservices architecture (8 services)
- Docker containerization
- Async I/O with asyncpg

**Databases:**
- PostgreSQL (metadata, configuration)
- TimescaleDB (time-series metrics)
- Redis (caching, rate limiting)

**Deployment:**
- Vercel (frontend hosting)
- Railway (backend + databases)
- GitHub Actions (CI/CD)

### Microservices

```
┌─────────────────────────────────────────────────┐
│               GARUDAI Platform                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ Gateway  │  │  Query   │  │ Evaluation│     │
│  │  (8000)  │  │  (8001)  │  │   (8002)  │     │
│  └──────────┘  └──────────┘  └──────────┘     │
│                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │Guardrail │  │  Alert   │  │  Gemini  │     │
│  │  (8003)  │  │  (8004)  │  │  (8005)  │     │
│  └──────────┘  └──────────┘  └──────────┘     │
│                                                 │
│  ┌──────────┐  ┌──────────┐                   │
│  │Ingestion │  │Processing│                   │
│  │  (8006)  │  │  (8007)  │                   │
│  └──────────┘  └──────────┘                   │
│                                                 │
├─────────────────────────────────────────────────┤
│             Data Layer                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │PostgreSQL│  │TimeScale │  │  Redis   │     │
│  │  (5432)  │  │  (5433)  │  │  (6379)  │     │
│  └──────────┘  └──────────┘  └──────────┘     │
└─────────────────────────────────────────────────┘
```

---

## 🎯 Features

### 📊 Tab 1: Fleet Dashboard (Home)
- Real-time agent fleet overview
- Total requests, active agents, error rates
- Request timeline, department breakdown
- Activity feed, alerts

### 📈 Tab 2: Usage Analytics
- API call volume trends
- User adoption curves
- Intent distribution
- Time-of-day heatmaps
- Top users and agents

### 💰 Tab 3: Cost Management
- Real-time cost tracking
- Provider comparison (OpenAI, Anthropic, Gemini)
- Cost forecasting and anomaly detection
- Department budgets
- Optimization recommendations

### ⚡ Tab 4: Performance
- Latency percentiles (p50, p95, p99)
- Throughput monitoring
- Error rate tracking
- SLO compliance
- Version performance comparison
- Dependency waterfalls

### 🏆 Tab 5: Quality
- AI-powered quality scoring
- Rubric-based evaluation
- Drift detection timeline
- Quality vs cost tradeoffs
- Top failing agents
- Prompt optimization suggestions

### 🛡️ Tab 6: Safety & Compliance
- Guardrail enforcement
- PII detection and redaction
- Toxicity filtering
- Prompt injection prevention
- Compliance status
- Risk heatmaps

### 📊 Tab 7: Business Impact
- ROI tracking
- Goal achievement
- Revenue attribution
- KPI dashboards
- Custom metric tracking

---

## 🚦 Project Status

### ✅ Completed (MVP - Phase 0-5)

- Docker Compose infrastructure
- All 8 microservices operational
- PostgreSQL + TimescaleDB + Redis
- Complete database schema
- Next.js frontend with 7 dashboard tabs
- 80+ React components
- Synthetic data generation
- GARUDAI branding and UI redesign
- Collapsible sidebar navigation
- User profile management

### 🎯 Production Ready

**Current Implementation**: ~70% of Enterprise PRD features

- ✅ Core observability (Usage, Cost, Performance)
- ✅ Quality evaluation system
- ✅ Safety guardrails
- ✅ Business impact tracking
- ✅ Real-time dashboards
- ⏳ Advanced features (experiments, automations) - planned

See [CURRENT_STATE_2025-11-11.md](./docs/CURRENT_STATE_2025-11-11.md) for detailed status.

---

## 🛠️ Development

### Prerequisites

- Docker Desktop 4.20+
- Node.js 18+ and npm 9+
- Python 3.11+ (for backend development)
- PostgreSQL client tools (psql)

### Local Setup

```bash
# 1. Clone repository
git clone https://github.com/Pramod-Potti-Krishnan/agent-observability.git
cd agent-observability

# 2. Environment configuration
cp .env.example .env
cp frontend/.env.example frontend/.env.local

# 3. Start infrastructure
docker-compose up -d

# 4. Generate synthetic data (optional)
python scripts/generate_synthetic_data.py

# 5. Start frontend development server
cd frontend
npm install
npm run dev
```

### Running Tests

```bash
# Frontend tests
cd frontend
npm test

# Backend tests (for each service)
cd backend/query
pytest

# Integration tests
docker-compose exec query pytest tests/
```

### Database Migrations

```bash
# Apply migrations
psql $DATABASE_URL < database/migrations/*.sql

# Or use Alembic
cd backend/query
alembic upgrade head
```

---

## 📖 API Usage

### Quick Example

```python
import requests

# Send trace to GARUDAI
trace = {
    "trace_id": "trace-123",
    "agent_id": "customer-support-bot",
    "model": "gpt-4",
    "prompt_tokens": 150,
    "completion_tokens": 80,
    "latency_ms": 1200,
    "input_text": "How do I reset my password?",
    "output_text": "To reset your password...",
}

response = requests.post(
    "http://localhost:8000/api/v1/traces",
    json=trace
)
```

See [API Reference](./docs/mvp/API_REFERENCE.md) for complete documentation.

---

## 🔧 Configuration

### Environment Variables

Key configuration options:

```bash
# Backend API URL (for frontend)
NEXT_PUBLIC_API_URL=http://localhost:8000

# Database connections
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/agent_obs
TIMESCALEDB_URL=postgresql://postgres:postgres@localhost:5433/agent_obs_metrics
REDIS_URL=redis://localhost:6379

# LLM API Keys (for quality evaluation)
GEMINI_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here

# Security
JWT_SECRET=your_secret_32_chars_minimum
CORS_ORIGINS=http://localhost:3000
```

See [.env.example](./.env.example) for all options.

---

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines (coming soon).

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Built with [Claude Code](https://claude.com/claude-code)
- Inspired by the mythological Garuda - the all-seeing divine eagle
- UI components from [shadcn/ui](https://ui.shadcn.com/)
- Charts powered by [Recharts](https://recharts.org/)

---

## 📞 Support

- **Documentation**: [docs/](./docs/)
- **Issues**: [GitHub Issues](https://github.com/Pramod-Potti-Krishnan/agent-observability/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Pramod-Potti-Krishnan/agent-observability/discussions)

---

<div align="center">

**GARUDAI** - The All-Seeing Guardian for Your AI Agents 🦅

*Global Agent Runtime Unified Dashboard AI*

[![Deploy Frontend](https://vercel.com/button)](https://vercel.com/new)
[![Deploy Backend](https://railway.app/button.svg)](https://railway.app/new)

</div>
