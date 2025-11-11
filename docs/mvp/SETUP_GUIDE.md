# Setup Guide
**AI Agent Observability Platform - Complete Installation and Configuration**

**Version:** 1.0 (MVP Complete - Phases 0-4)
**Last Updated:** October 26, 2025

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Prerequisites](#prerequisites)
3. [Environment Configuration](#environment-configuration)
4. [Docker Setup](#docker-setup)
5. [Database Initialization](#database-initialization)
6. [Running the Platform](#running-the-platform)
7. [Verification Steps](#verification-steps)
8. [Platform-Specific Notes](#platform-specific-notes)
9. [Troubleshooting](#troubleshooting)

---

## Quick Start

**TL;DR - Fastest Way to Get Started:**

```bash
# 1. Clone and navigate to project
cd /path/to/Agent\ Monitoring

# 2. Copy environment file
cp .env.example .env

# 3. Start Docker services
docker-compose up -d

# 4. Setup backend (Phase 0)
cd backend
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements-phase0.txt

# 5. Verify setup
python check_env.py
python test_connections.py

# 6. Generate synthetic data
python synthetic_data/generator.py
python synthetic_data/load_data.py

# 7. Start frontend
cd ../frontend
npm install
npm run dev
```

**Access the platform:**
- Frontend: http://localhost:3000
- API Gateway: http://localhost:8000
- API Docs: http://localhost:8000/docs

---

## Prerequisites

### Required Software

| Software | Minimum Version | Purpose | Installation |
|----------|----------------|---------|--------------|
| **Python** | 3.11+ | Backend services | [python.org](https://www.python.org/downloads/) |
| **Node.js** | 18+ | Frontend application | [nodejs.org](https://nodejs.org/) |
| **Docker Desktop** | 20.10+ | Container orchestration | [docker.com](https://www.docker.com/products/docker-desktop/) |
| **Docker Compose** | 2.0+ | Service orchestration | Included with Docker Desktop |
| **Git** | 2.0+ | Version control | [git-scm.com](https://git-scm.com/) |

### System Requirements

**Development:**
- RAM: 8GB minimum, 16GB recommended
- Storage: 10GB free space
- OS: macOS, Linux, or Windows 10/11

**Production:**
- RAM: 16GB minimum, 32GB recommended
- Storage: 100GB+ for time-series data
- OS: Linux (Ubuntu 22.04 LTS recommended)

### Verify Prerequisites

```bash
# Check Python version
python3 --version  # Should be 3.11 or higher

# Check Node.js version
node --version  # Should be v18 or higher

# Check Docker
docker --version
docker-compose --version

# Check Docker is running
docker ps  # Should not show error
```

---

## Environment Configuration

### Is `.env` Required?

**Phase 0 (Foundation):** Optional - defaults work for local development
**Phase 1+ (Backend Services):** Required - need JWT secrets and database URLs
**Production:** Critical - secure values required

### Phase-by-Phase Configuration

#### Phase 0 (Current) - Foundation Setup

**Minimum Setup:**
```bash
cp .env.example .env
# Defaults work for local development
```

**Environment Variables:**
```bash
# Database Configuration (Docker default ports)
TIMESCALE_DB=agent_observability
TIMESCALE_USER=postgres
TIMESCALE_PASSWORD=postgres
TIMESCALE_URL=postgresql://postgres:postgres@localhost:5432/agent_observability

POSTGRES_DB=agent_observability_metadata
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_URL=postgresql://postgres:postgres@localhost:5433/agent_observability_metadata

# Redis Configuration
REDIS_PASSWORD=redis123
REDIS_URL=redis://:redis123@localhost:6379/0

# Development Mode
NODE_ENV=development
PYTHON_ENV=development
DEBUG=true
```

**Frontend Configuration (Optional):**
```bash
# frontend/.env.local
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_WS_URL=ws://localhost:8000
```

---

#### Phase 1 (Backend Services) - Additional Config

**Add to `.env`:**
```bash
# JWT Authentication (IMPORTANT: Change in production!)
JWT_SECRET=your-super-secret-jwt-key-change-in-production-min-32-chars
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# API Key Security (IMPORTANT: Change in production!)
API_KEY_SALT=your-api-key-salt-change-in-production-min-32-chars

# Rate Limiting
RATE_LIMIT_REQUESTS_PER_MINUTE=1000
RATE_LIMIT_BURST=100

# Service Ports
API_GATEWAY_PORT=8000
INGESTION_SERVICE_PORT=8001
PROCESSING_SERVICE_PORT=8002
QUERY_SERVICE_PORT=8003
```

**Generate Secure Secrets:**
```bash
# Option 1: OpenSSL
openssl rand -base64 32

# Option 2: Python
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# Add to .env:
JWT_SECRET=$(openssl rand -base64 32)
API_KEY_SALT=$(openssl rand -base64 32)
```

---

#### Phase 4 (AI Features) - Google Gemini API

**Get API Key:**
1. Visit: https://makersuite.google.com/app/apikey
2. Sign in with Google account
3. Click "Get API Key" or "Create API Key"
4. Copy the key (starts with `AIza...`)

**Add to `.env`:**
```bash
# Google Gemini API (for AI evaluations)
GEMINI_API_KEY=AIzaSyC...your-key-here

# Optional: Perspective API (for toxicity detection)
PERSPECTIVE_API_KEY=your-perspective-api-key-here

# Optional: Alert Webhooks
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
PAGERDUTY_API_KEY=your-pagerduty-key-here
```

**Test Gemini API:**
```bash
cd backend
source venv/bin/activate
python3 -c "
import google.generativeai as genai
import os
from dotenv import load_dotenv

load_dotenv()
genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
model = genai.GenerativeModel('gemini-1.5-pro')
response = model.generate_content('Hello')
print('✅ Gemini API working!')
print(response.text)
"
```

---

### Configuration for Different Environments

#### Local Development (Default)
```bash
# .env (development)
TIMESCALE_URL=postgresql://postgres:postgres@localhost:5432/agent_observability
POSTGRES_URL=postgresql://postgres:postgres@localhost:5433/agent_observability_metadata
REDIS_URL=redis://:redis123@localhost:6379/0

NEXT_PUBLIC_API_URL=http://localhost:8000
DEBUG=true
```

#### Docker Internal Network
```bash
# .env (Docker internal - when backend runs in Docker)
# Use service names instead of localhost
TIMESCALE_URL=postgresql://postgres:postgres@timescaledb:5432/agent_observability
POSTGRES_URL=postgresql://postgres:postgres@postgres:5432/agent_observability_metadata
REDIS_URL=redis://:redis123@redis:6379/0

NEXT_PUBLIC_API_URL=http://api-gateway:8000
DEBUG=true
```

#### Production
```bash
# .env.production (SECURE THESE VALUES!)

# Use managed database services
TIMESCALE_URL=postgresql://user:password@your-timescale-host.com:5432/dbname?sslmode=require
POSTGRES_URL=postgresql://user:password@your-postgres-host.com:5432/dbname?sslmode=require
REDIS_URL=rediss://user:password@your-redis-host.com:6379/0

# Strong secrets (32+ character random strings)
JWT_SECRET=$(openssl rand -base64 32)
API_KEY_SALT=$(openssl rand -base64 32)

# Production API URL
NEXT_PUBLIC_API_URL=https://api.yourdomain.com
NEXT_PUBLIC_WS_URL=wss://api.yourdomain.com

# Disable debug
DEBUG=false
NODE_ENV=production
PYTHON_ENV=production

# Real API keys
GEMINI_API_KEY=your-production-gemini-key
SLACK_WEBHOOK_URL=your-production-slack-webhook

# Rate limiting (stricter)
RATE_LIMIT_REQUESTS_PER_MINUTE=500
RATE_LIMIT_BURST=50

# Data retention
TRACES_RETENTION_DAYS=30
METRICS_RETENTION_DAYS=90
LOGS_RETENTION_DAYS=7
```

---

## Docker Setup

### Docker Compose Architecture

The platform uses Docker Compose to run three core databases:

```yaml
services:
  timescaledb:     # Port 5432 - Time-series metrics
  postgres:        # Port 5433 - Relational metadata
  redis:           # Port 6379 - Cache & queues
```

### Starting Docker Services

```bash
# Start all services in detached mode
docker-compose up -d

# Check status
docker-compose ps

# Expected output:
# NAME                    STATUS      PORTS
# agent_obs_timescaledb   Up          0.0.0.0:5432->5432/tcp
# agent_obs_postgres      Up          0.0.0.0:5433->5432/tcp
# agent_obs_redis         Up          0.0.0.0:6379->6379/tcp
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f timescaledb
docker-compose logs -f postgres
docker-compose logs -f redis
```

### Stopping Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes all data)
docker-compose down -v
```

### Restarting Services

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart timescaledb
```

---

## Database Initialization

### Automatic Initialization

Docker Compose automatically initializes databases on first startup using SQL scripts in `backend/db/`:

```
backend/db/
├── timescale_init.sql    # TimescaleDB schema & hypertables
└── postgres_init.sql     # PostgreSQL schema & metadata tables
```

### Manual Database Setup (if needed)

**Connect to TimescaleDB:**
```bash
docker-compose exec timescaledb psql -U postgres -d agent_observability
```

**Connect to PostgreSQL:**
```bash
docker-compose exec postgres psql -U postgres -d agent_observability_metadata
```

**Run initialization scripts manually:**
```bash
# TimescaleDB
docker-compose exec -T timescaledb psql -U postgres -d agent_observability < backend/db/timescale_init.sql

# PostgreSQL
docker-compose exec -T postgres psql -U postgres -d agent_observability_metadata < backend/db/postgres_init.sql
```

### Verify Database Schema

```bash
# Check TimescaleDB hypertables
docker-compose exec timescaledb psql -U postgres -d agent_observability -c "\d+"

# Expected tables:
# - traces (hypertable)
# - hourly_metrics (continuous aggregate)
# - daily_metrics (continuous aggregate)

# Check PostgreSQL tables
docker-compose exec postgres psql -U postgres -d agent_observability_metadata -c "\dt"

# Expected tables:
# - workspaces, users, agents, api_keys
# - evaluations, guardrail_rules, guardrail_violations
# - alert_rules, alert_notifications, business_goals, budgets
```

---

## Running the Platform

### Backend Services (Phases 1-4)

**Start all backend services:**
```bash
# Gateway Service (Port 8000)
cd backend/gateway
source ../venv/bin/activate
python -m app.main

# Ingestion Service (Port 8001)
cd backend/ingestion
source ../venv/bin/activate
python -m app.main

# Processing Service (Background)
cd backend/processing
source ../venv/bin/activate
python -m app.main

# Query Service (Port 8003)
cd backend/query
source ../venv/bin/activate
python -m app.main

# Evaluation Service (Port 8004)
cd backend/evaluation
source ../venv/bin/activate
python -m app.main

# Guardrail Service (Port 8005)
cd backend/guardrail
source ../venv/bin/activate
python -m app.main

# Alert Service (Port 8006)
cd backend/alert
source ../venv/bin/activate
python -m app.main

# Gemini Service (Port 8007)
cd backend/gemini
source ../venv/bin/activate
python -m app.main
```

**Or use Docker Compose for all services (Future Phase 6):**
```bash
# Will be added in Phase 6 for production deployment
docker-compose -f docker-compose.full.yml up -d
```

### Frontend Application

```bash
cd frontend
npm install
npm run dev

# Production build:
npm run build
npm start
```

**Access URLs:**
- Frontend: http://localhost:3000
- API Gateway: http://localhost:8000
- API Documentation: http://localhost:8000/docs (FastAPI auto-docs)

---

## Verification Steps

### 1. Check Environment Variables

```bash
cd backend
source venv/bin/activate
python check_env.py
```

**Expected Output:**
```
======================================================================
Agent Observability Platform - Environment Configuration Check
======================================================================

📋 Required Variables (Phase 0+):
  ✅ TIMESCALE_URL         = postgresql://postgre...
  ✅ POSTGRES_URL          = postgresql://postgre...
  ✅ REDIS_URL             = redis://:redis123@lo...

🔧 Optional Variables:
  ⚠️  GEMINI_API_KEY       = Not set
  ⚠️  JWT_SECRET           = Not set
  ⚠️  API_KEY_SALT         = Not set

✅ All required environment variables are properly configured!
```

### 2. Test Database Connections

```bash
cd backend
python test_connections.py
```

**Expected Output:**
```
======================================================================
Agent Observability Platform - Database Connection Tests
======================================================================

🔍 Testing TimescaleDB connection...
  📡 Connecting to: localhost:5432/agent_observability
  ✅ Connected: PostgreSQL 15.5
  ✅ TimescaleDB extension: v2.13.0
  ✅ Hypertables found: 3
     - traces
     - performance_metrics
     - events
  ✅ Traces count: 10,000

🔍 Testing PostgreSQL connection...
  📡 Connecting to: localhost:5433/agent_observability_metadata
  ✅ Connected: PostgreSQL 15.5
  ✅ Tables found: 12
     - workspaces: 1 rows
     - users: 1 rows
     - agents: 3 rows
     - api_keys: 0 rows

🔍 Testing Redis connection...
  📡 Connecting to: localhost:6379 (db=0)
  ✅ Connected: PING successful
  ✅ Redis version: 7.2.3
  ✅ Memory used: 2.1M
  ✅ Connected clients: 1
  ✅ SET/GET test successful

✅ All database connections successful!
```

### 3. Generate Synthetic Data

```bash
cd backend

# Generate 10,000 synthetic traces
python synthetic_data/generator.py

# Load data into databases
python synthetic_data/load_data.py
```

### 4. Run Backend Tests

```bash
cd backend
pytest -v

# Expected: 60+ tests passing across all services
```

### 5. Run Frontend Tests

```bash
cd frontend
npm test

# Expected: Component tests passing for all dashboard pages
```

### 6. Test API Endpoints

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

# Login (get JWT token and workspace_id)
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{
    "email":"test@example.com",
    "password":"SecurePass123"
  }'

# Save the workspace_id from response
export WORKSPACE_ID="your-workspace-id"

# Get home KPIs
curl "http://localhost:8003/api/v1/metrics/home-kpis?range=24h" \
  -H "X-Workspace-ID: $WORKSPACE_ID"
```

---

## Platform-Specific Notes

### macOS Setup

#### Quick Fix for "pg_config executable not found"

If you see this error during setup:
```
Error: pg_config executable not found.
```

**Solution:**
```bash
# Phase 0 uses requirements-phase0.txt (no PostgreSQL client needed)
cd backend
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements-phase0.txt
```

#### Install PostgreSQL Client (Phase 1+)

```bash
# Using Homebrew
brew install postgresql@15

# Add to PATH
echo 'export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify
pg_config --version
```

#### Apple Silicon (M1/M2/M3) Notes

Docker Desktop handles ARM64 automatically. If you have issues:

```bash
# Force x86_64 platform in docker-compose.yml
services:
  timescaledb:
    platform: linux/amd64
    image: timescale/timescaledb:latest-pg15
```

#### Common macOS Issues

**Port conflicts:**
```bash
# Check what's using ports
lsof -i :5432
lsof -i :5433
lsof -i :6379

# Stop conflicting services
brew services stop postgresql
```

**Docker not running:**
```bash
# Start Docker Desktop
open -a Docker

# Wait for startup, then verify
docker ps
```

---

### Linux Setup

#### Install Docker on Ubuntu

```bash
# Update package index
sudo apt-get update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo apt-get install docker-compose-plugin

# Verify
docker --version
docker compose version
```

#### Install Python 3.11+

```bash
# Ubuntu 22.04+
sudo apt-get update
sudo apt-get install python3.11 python3.11-venv python3-pip

# Verify
python3.11 --version
```

#### Install Node.js 18+

```bash
# Using NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify
node --version
npm --version
```

---

### Windows Setup

#### Install Prerequisites

1. **Python 3.11+**: Download from [python.org](https://www.python.org/downloads/)
2. **Node.js 18+**: Download from [nodejs.org](https://nodejs.org/)
3. **Docker Desktop**: Download from [docker.com](https://www.docker.com/products/docker-desktop/)
4. **Git**: Download from [git-scm.com](https://git-scm.com/)

#### Windows-Specific Commands

```powershell
# Activate virtual environment (PowerShell)
backend\venv\Scripts\Activate.ps1

# Or Command Prompt
backend\venv\Scripts\activate.bat

# Environment variables
$env:WORKSPACE_ID="your-workspace-id"
```

#### WSL2 (Recommended)

For better Docker performance:

```powershell
# Install WSL2
wsl --install

# Set as default
wsl --set-default-version 2

# Install Ubuntu
wsl --install -d Ubuntu-22.04

# Use WSL2 terminal for all commands
```

---

## Troubleshooting

### Connection Issues

#### "Connection refused" errors

```bash
# Check Docker containers are running
docker-compose ps

# Should show all services as "Up"
# If not, start them:
docker-compose up -d

# Wait for startup
sleep 10

# Check logs
docker-compose logs timescaledb
docker-compose logs postgres
docker-compose logs redis
```

#### "Database does not exist"

```bash
# Restart containers to trigger initialization
docker-compose down
docker-compose up -d

# Wait for startup
sleep 10

# Check initialization logs
docker-compose logs timescaledb | grep "database system is ready"
```

#### Wrong ports

```bash
# Check what ports Docker mapped
docker-compose ps

# Update .env to match actual ports:
TIMESCALE_URL=postgresql://postgres:postgres@localhost:ACTUAL_PORT/agent_observability
```

---

### Frontend Issues

#### "API Error: Network Error"

**Check backend is running:**
```bash
# In Phase 0, backend services don't exist yet - this is expected!
# In Phase 1+, verify Gateway is running:
curl http://localhost:8000/health
```

**Create frontend .env.local:**
```bash
cd frontend
cat > .env.local << EOF
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_WS_URL=ws://localhost:8000
EOF

# Restart Next.js
npm run dev
```

#### "Module not found" errors

```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
npm run dev
```

---

### Backend Issues

#### ImportError or ModuleNotFoundError

```bash
# Ensure virtual environment is activated
cd backend
source venv/bin/activate  # macOS/Linux
# or
venv\Scripts\activate  # Windows

# Reinstall dependencies
pip install -r requirements-phase0.txt  # Phase 0
# or
pip install -r requirements.txt  # Phase 1+
```

#### "Async function not awaited" warnings

This is expected in async Python code. Ensure you're using:
```python
# Always await async functions
await db.fetch(query)
await redis_client.set(key, value)
```

---

### Docker Issues

#### "Cannot connect to Docker daemon"

**macOS:**
```bash
open -a Docker
```

**Linux:**
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

**Windows:**
- Start Docker Desktop from Start Menu

#### Port conflicts

```bash
# Find processes using ports
# macOS/Linux:
lsof -i :5432

# Windows:
netstat -ano | findstr :5432

# Kill the process or change ports in docker-compose.yml
```

#### Out of disk space

```bash
# Clean up Docker
docker system prune -a --volumes

# WARNING: This removes ALL unused containers, networks, images, and volumes
```

---

### Environment Variable Issues

#### Variables not loading

**Check .env file exists:**
```bash
ls -la .env  # Should exist in project root
```

**Check .env is loaded:**
```python
# In Python
from dotenv import load_dotenv
import os

load_dotenv()
print(os.getenv('TIMESCALE_URL'))  # Should print URL
```

**Check Next.js public variables:**
```typescript
// Must start with NEXT_PUBLIC_
console.log(process.env.NEXT_PUBLIC_API_URL)
```

---

## Security Best Practices

### Development
- ✅ Use `.env` file (gitignored)
- ✅ Keep default passwords simple for local dev
- ✅ Share `.env.example` (no secrets)
- ✅ Debug mode enabled

### Production
- ✅ Use environment variables (not `.env` files)
- ✅ Use secret management (AWS Secrets Manager, HashiCorp Vault)
- ✅ Rotate secrets regularly
- ✅ Use strong random values (32+ characters)
- ✅ Enable SSL/TLS for all database connections
- ✅ Use managed database services with automatic backups
- ❌ NEVER commit `.env` to git
- ❌ NEVER use default passwords in production
- ❌ NEVER expose database ports publicly

---

## Quick Reference

### Essential Commands

| Task | Command |
|------|---------|
| **Check environment** | `python backend/check_env.py` |
| **Test connections** | `python backend/test_connections.py` |
| **Generate secrets** | `openssl rand -base64 32` |
| **Start Docker** | `docker-compose up -d` |
| **Check Docker** | `docker-compose ps` |
| **View logs** | `docker-compose logs -f [service]` |
| **Restart Docker** | `docker-compose restart` |
| **Stop Docker** | `docker-compose down` |
| **Backend tests** | `pytest backend/` |
| **Frontend tests** | `cd frontend && npm test` |
| **Start frontend** | `cd frontend && npm run dev` |

### Environment Variables

| Variable | Required When | Default | Description |
|----------|--------------|---------|-------------|
| `TIMESCALE_URL` | Phase 0+ | `postgresql://postgres:postgres@localhost:5432/agent_observability` | TimescaleDB connection |
| `POSTGRES_URL` | Phase 0+ | `postgresql://postgres:postgres@localhost:5433/agent_observability_metadata` | PostgreSQL connection |
| `REDIS_URL` | Phase 0+ | `redis://:redis123@localhost:6379/0` | Redis connection |
| `JWT_SECRET` | Phase 1+ | None | JWT token signing (32+ chars) |
| `API_KEY_SALT` | Phase 1+ | None | API key hashing salt (32+ chars) |
| `GEMINI_API_KEY` | Phase 4+ | None | Google Gemini API key |
| `NEXT_PUBLIC_API_URL` | Phase 1+ | `http://localhost:8000` | Backend API endpoint |
| `DEBUG` | All | `true` | Enable debug logging |

### Service Ports

| Service | Port | Purpose |
|---------|------|---------|
| Frontend | 3000 | Next.js application |
| Gateway | 8000 | API gateway, auth |
| Ingestion | 8001 | Trace ingestion |
| Processing | - | Background processor |
| Query | 8003 | Analytics API |
| Evaluation | 8004 | Quality evaluation |
| Guardrail | 8005 | Safety checks |
| Alert | 8006 | Monitoring |
| Gemini | 8007 | AI insights |
| TimescaleDB | 5432 | Time-series database |
| PostgreSQL | 5433 | Relational database |
| Redis | 6379 | Cache & queues |

---

## Next Steps

After successful setup:

**Phase 0 (Complete):**
- ✅ Docker infrastructure running
- ✅ Databases initialized
- ✅ Frontend shell working
- ✅ Synthetic data generated

**Phase 1 (Next):**
```bash
# Add JWT secrets to .env
echo "JWT_SECRET=$(openssl rand -base64 32)" >> .env
echo "API_KEY_SALT=$(openssl rand -base64 32)" >> .env

# Start backend services
cd backend/gateway && python -m app.main
```

**Phase 4 (AI Features):**
```bash
# Get Gemini API key from Google AI Studio
# Add to .env
echo "GEMINI_API_KEY=your-key-here" >> .env
```

---

## Getting Help

### Documentation

- **Architecture:** [ARCHITECTURE.md](ARCHITECTURE.md) - Complete system design
- **API Reference:** [API_REFERENCE.md](API_REFERENCE.md) - All endpoints
- **Troubleshooting:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues

### Health Checks

```bash
# Quick system check
docker-compose ps
cd backend && python test_connections.py
curl http://localhost:8000/health  # Phase 1+
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f timescaledb
docker-compose logs -f postgres
docker-compose logs -f redis
```

### Clean Restart

```bash
# Stop everything
docker-compose down

# Remove Python venv
rm -rf backend/venv

# Remove Node modules
rm -rf frontend/node_modules

# Start fresh
./setup.sh  # or manual steps above
```

---

**Setup complete!** You're ready to start using the AI Agent Observability Platform.

For detailed architecture information, see [ARCHITECTURE.md](ARCHITECTURE.md).
