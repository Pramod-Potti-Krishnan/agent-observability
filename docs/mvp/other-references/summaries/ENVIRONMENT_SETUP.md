# Environment Configuration Guide

## Overview

**Is `.env` necessary?**

- **For Phase 0 (current):** Optional - defaults work for local development
- **For Phase 1+:** Yes - required for backend services to connect to databases
- **For Production:** Absolutely required with secure values

The system uses a **hierarchical configuration approach**:
1. Environment variables (highest priority)
2. `.env` file values
3. Hardcoded defaults (lowest priority)

---

## Quick Start (Phase 0)

For Phase 0, you can run without `.env` if using default Docker ports:

```bash
# Start databases with defaults
docker-compose up -d

# Frontend works without .env (uses hardcoded defaults)
cd frontend
npm run dev
```

**However**, creating `.env` is recommended:

```bash
cp .env.example .env
# Edit .env if you need custom ports or passwords
```

---

## Environment Files Structure

```
Agent Monitoring/
├── .env                          # Root env file (databases, shared config)
├── backend/
│   ├── .env                      # Backend-specific overrides (optional)
│   ├── gateway/.env              # API Gateway config (Phase 1)
│   ├── ingestion/.env            # Ingestion Service config (Phase 1)
│   └── processing/.env           # Processing Service config (Phase 1)
└── frontend/
    └── .env.local                # Frontend-specific config (optional)
```

**Best Practice:** Use root `.env` for shared configuration (databases, Redis), and service-specific `.env` files only for overrides.

---

## Configuration by Phase

### Phase 0 (Current) - Foundation

**Root `.env` (required for tests and data loading):**

```bash
# Database Configuration
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

**Frontend `.env.local` (optional - defaults work):**

```bash
# API endpoint (will be used in Phase 1+)
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_WS_URL=ws://localhost:8000
```

**What uses these values in Phase 0:**
- `backend/synthetic_data/load_data.py` - loads data into databases
- `backend/tests/test_infrastructure.py` - runs database tests
- Docker Compose - database passwords

---

### Phase 1 - Core Backend Services

**Additional config needed in root `.env`:**

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
```

**Backend service-specific `.env` files (optional - inherit from root):**

`backend/gateway/.env`:
```bash
# Only if you need to override root config
PORT=8000
CORS_ORIGINS=http://localhost:3000,http://localhost:3001
```

`backend/ingestion/.env`:
```bash
# Only if you need to override root config
PORT=8001
MAX_PAYLOAD_SIZE=10485760  # 10MB
```

---

### Phase 4 - Advanced Features (Evaluation, Guardrails)

**Additional config needed:**

```bash
# Google Gemini API (for evaluations)
GEMINI_API_KEY=your-gemini-api-key-here

# Perspective API (for toxicity detection - optional)
PERSPECTIVE_API_KEY=your-perspective-api-key-here

# Alert Webhooks (optional)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
PAGERDUTY_API_KEY=your-pagerduty-key-here
```

---

## How to Get API Keys

### 1. Google Gemini API Key (Phase 4)

**Purpose:** AI-powered quality evaluation of agent responses

**Steps:**
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click **"Get API Key"** or **"Create API Key"**
4. Copy the key (starts with `AIza...`)
5. Add to `.env`:
   ```bash
   GEMINI_API_KEY=AIzaSyC...your-key-here
   ```

**Free Tier:**
- 60 requests per minute
- Sufficient for development and testing

**Test it:**
```bash
cd backend
source venv/bin/activate
python -c "
import google.generativeai as genai
import os
from dotenv import load_dotenv

load_dotenv()
genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
model = genai.GenerativeModel('gemini-1.5-pro')
response = model.generate_content('Say hello')
print('✅ Gemini API working:', response.text)
"
```

---

### 2. Perspective API Key (Phase 4, Optional)

**Purpose:** Toxicity detection in agent outputs

**Steps:**
1. Go to [Perspective API](https://developers.perspectiveapi.com/s/docs-get-started)
2. Enable the API in Google Cloud Console
3. Create credentials (API key)
4. Add to `.env`:
   ```bash
   PERSPECTIVE_API_KEY=your-key-here
   ```

**Alternative:** Use open-source models (we'll implement local toxicity detection as fallback)

---

### 3. Slack Webhook URL (Phase 4+, Optional)

**Purpose:** Send alerts to Slack channels

**Steps:**
1. Go to [Slack Apps](https://api.slack.com/apps)
2. Click **"Create New App"** → **"From scratch"**
3. Name it "Agent Observability Alerts"
4. Select your workspace
5. Go to **"Incoming Webhooks"** → Enable it
6. Click **"Add New Webhook to Workspace"**
7. Select channel and authorize
8. Copy the webhook URL
9. Add to `.env`:
   ```bash
   SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX
   ```

**Test it:**
```bash
curl -X POST -H 'Content-type: application/json' \
--data '{"text":"✅ Agent Observability test alert"}' \
$SLACK_WEBHOOK_URL
```

---

## Configuration for Different Environments

### Local Development (Default)

```bash
# .env (development)
TIMESCALE_URL=postgresql://postgres:postgres@localhost:5432/agent_observability
POSTGRES_URL=postgresql://postgres:postgres@localhost:5433/agent_observability_metadata
REDIS_URL=redis://:redis123@localhost:6379/0

NEXT_PUBLIC_API_URL=http://localhost:8000
DEBUG=true
```

---

### Docker Internal Network (When backend runs in Docker)

```bash
# .env (Docker internal)
# Use service names instead of localhost
TIMESCALE_URL=postgresql://postgres:postgres@timescaledb:5432/agent_observability
POSTGRES_URL=postgresql://postgres:postgres@postgres:5432/agent_observability_metadata
REDIS_URL=redis://:redis123@redis:6379/0

NEXT_PUBLIC_API_URL=http://api-gateway:8000
DEBUG=true
```

---

### Production

```bash
# .env.production (SECURE THESE VALUES!)

# Use managed database services
TIMESCALE_URL=postgresql://user:password@your-timescale-host.com:5432/dbname?sslmode=require
POSTGRES_URL=postgresql://user:password@your-postgres-host.com:5432/dbname?sslmode=require
REDIS_URL=rediss://user:password@your-redis-host.com:6379/0

# Strong secrets (use 32+ character random strings)
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

**Generate secure secrets:**
```bash
# Generate JWT secret
openssl rand -base64 32

# Generate API key salt
openssl rand -base64 32

# Or use Python
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

---

## Environment Variable Loading Order

### Backend (Python with python-dotenv)

1. Environment variables (highest priority)
2. `.env` in current directory
3. `.env` in parent directories
4. Hardcoded defaults in code

**Example:**
```python
from dotenv import load_dotenv
import os

load_dotenv()  # Loads .env file

# Gets value in this order: ENV var → .env → default
database_url = os.getenv('TIMESCALE_URL', 'postgresql://localhost/default')
```

---

### Frontend (Next.js)

Next.js loads env files in this order:

1. `.env.production.local` (production only, highest priority)
2. `.env.local` (all environments except test, gitignored)
3. `.env.production` (production only)
4. `.env` (all environments)

**Public variables must start with `NEXT_PUBLIC_`:**

```bash
# ✅ Accessible in browser
NEXT_PUBLIC_API_URL=http://localhost:8000

# ❌ NOT accessible in browser (server-side only)
DATABASE_URL=postgresql://...
```

**Access in code:**
```typescript
// Client-side (browser)
const apiUrl = process.env.NEXT_PUBLIC_API_URL

// Server-side only
const dbUrl = process.env.DATABASE_URL
```

---

## Verification Scripts

### Check All Configuration

```bash
# backend/check_env.py
from dotenv import load_dotenv
import os
import sys

load_dotenv()

required_vars = {
    'TIMESCALE_URL': 'TimescaleDB connection string',
    'POSTGRES_URL': 'PostgreSQL connection string',
    'REDIS_URL': 'Redis connection string',
}

optional_vars = {
    'GEMINI_API_KEY': 'Google Gemini API key (Phase 4+)',
    'JWT_SECRET': 'JWT secret (Phase 1+)',
}

print("=" * 60)
print("Environment Configuration Check")
print("=" * 60)

print("\n📋 Required Variables:")
all_good = True
for var, description in required_vars.items():
    value = os.getenv(var)
    if value:
        # Mask sensitive parts
        display_value = value[:20] + '...' if len(value) > 20 else value
        print(f"  ✅ {var}: {display_value}")
    else:
        print(f"  ❌ {var}: MISSING ({description})")
        all_good = False

print("\n🔧 Optional Variables:")
for var, description in optional_vars.items():
    value = os.getenv(var)
    if value:
        display_value = value[:20] + '...' if len(value) > 20 else value
        print(f"  ✅ {var}: {display_value}")
    else:
        print(f"  ⚠️  {var}: Not set ({description})")

print("\n" + "=" * 60)
if all_good:
    print("✅ All required environment variables are set!")
    sys.exit(0)
else:
    print("❌ Some required variables are missing. Please check .env file.")
    sys.exit(1)
```

**Run it:**
```bash
cd backend
source venv/bin/activate
python check_env.py
```

---

### Test Database Connections

```bash
# backend/test_connections.py
import asyncio
import asyncpg
import redis
from dotenv import load_dotenv
import os

load_dotenv()

async def test_timescale():
    try:
        conn = await asyncpg.connect(os.getenv('TIMESCALE_URL'))
        version = await conn.fetchval('SELECT version()')
        await conn.close()
        print("✅ TimescaleDB connected:", version[:50])
        return True
    except Exception as e:
        print("❌ TimescaleDB connection failed:", str(e))
        return False

async def test_postgres():
    try:
        conn = await asyncpg.connect(os.getenv('POSTGRES_URL'))
        version = await conn.fetchval('SELECT version()')
        await conn.close()
        print("✅ PostgreSQL connected:", version[:50])
        return True
    except Exception as e:
        print("❌ PostgreSQL connection failed:", str(e))
        return False

def test_redis():
    try:
        redis_url = os.getenv('REDIS_URL')
        # Parse Redis URL
        if redis_url.startswith('redis://'):
            parts = redis_url.replace('redis://:', '').split('@')
            password = parts[0]
            host_port = parts[1].split(':')
            host = host_port[0]
            port = int(host_port[1].split('/')[0])
        else:
            host, port, password = 'localhost', 6379, None

        r = redis.Redis(host=host, port=port, password=password, decode_responses=True)
        r.ping()
        print("✅ Redis connected")
        return True
    except Exception as e:
        print("❌ Redis connection failed:", str(e))
        return False

async def main():
    print("=" * 60)
    print("Testing Database Connections")
    print("=" * 60)

    results = []
    results.append(await test_timescale())
    results.append(await test_postgres())
    results.append(test_redis())

    print("\n" + "=" * 60)
    if all(results):
        print("✅ All database connections successful!")
    else:
        print("❌ Some connections failed. Check your .env file and Docker containers.")
    print("=" * 60)

if __name__ == "__main__":
    asyncio.run(main())
```

**Run it:**
```bash
cd backend
source venv/bin/activate
python test_connections.py
```

---

## Common Issues & Solutions

### Issue 1: "Connection refused" errors

**Symptom:** Cannot connect to databases

**Solution:**
```bash
# Check Docker containers are running
docker-compose ps

# Should show all services as "Up"
# If not, start them:
docker-compose up -d

# Check logs
docker-compose logs timescaledb
docker-compose logs postgres
docker-compose logs redis
```

---

### Issue 2: Wrong database ports

**Symptom:** Connection errors with custom ports

**Solution:**
```bash
# Check what ports Docker mapped
docker-compose ps

# Update .env to match:
TIMESCALE_URL=postgresql://postgres:postgres@localhost:ACTUAL_PORT/agent_observability
```

---

### Issue 3: Frontend can't reach backend

**Symptom:** API calls fail with CORS or connection errors

**Solution:**
```bash
# Make sure NEXT_PUBLIC_API_URL is set correctly
# frontend/.env.local
NEXT_PUBLIC_API_URL=http://localhost:8000

# Restart Next.js after changing .env
npm run dev
```

---

### Issue 4: Missing environment variables in Docker

**Symptom:** Services work locally but fail in Docker

**Solution:**
```yaml
# docker-compose.yml - ensure env vars are passed
services:
  api-gateway:
    env_file:
      - .env
    environment:
      - DATABASE_URL=${TIMESCALE_URL}
      - REDIS_URL=${REDIS_URL}
```

---

## Security Best Practices

### Development
- ✅ Use `.env` file (gitignored)
- ✅ Keep default passwords simple for local dev
- ✅ Share `.env.example` (no secrets)

### Production
- ✅ Use environment variables (not `.env` file)
- ✅ Use secret management (AWS Secrets Manager, HashiCorp Vault, etc.)
- ✅ Rotate secrets regularly
- ✅ Use strong random values (32+ characters)
- ✅ Enable SSL/TLS for all database connections
- ✅ Use managed database services with automatic backups
- ❌ NEVER commit `.env` to git
- ❌ NEVER use default passwords in production
- ❌ NEVER expose database ports publicly

---

## Quick Reference

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

---

## Summary

**For Phase 0 (Now):**
```bash
# Minimum to get started
cp .env.example .env
# Defaults work fine for local development
docker-compose up -d
```

**For Phase 1 (Backend Services):**
```bash
# Add to .env
JWT_SECRET=$(openssl rand -base64 32)
API_KEY_SALT=$(openssl rand -base64 32)
```

**For Phase 4 (AI Features):**
```bash
# Get Gemini API key from Google AI Studio
# Add to .env
GEMINI_API_KEY=your-key-here
```

**For Production:**
- Use environment variables (not files)
- Strong secrets (32+ chars)
- Managed databases
- SSL/TLS everywhere
