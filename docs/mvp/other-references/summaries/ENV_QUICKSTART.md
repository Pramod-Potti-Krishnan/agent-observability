# Environment Setup - Quick Start Guide

## TL;DR - Fastest Way to Get Started

```bash
# 1. Copy the example file
cp .env.example .env

# 2. (Optional) Edit .env if you need custom ports or passwords
# For Phase 0, the defaults work fine!

# 3. Verify configuration
cd backend
source venv/bin/activate  # or: . venv/bin/activate
python check_env.py

# 4. Test connections
python test_connections.py

# 5. Start using the platform!
```

**That's it!** For local development in Phase 0, you don't need to change anything in `.env`.

---

## Is .env Required?

### Phase 0 (Foundation) - **Optional**
- Defaults work out of the box
- Create `.env` for consistency
- **Recommended but not required**

### Phase 1+ (Backend Services) - **Required**
- Need JWT secrets
- Backend services require database URLs
- **Must have `.env` file**

### Production - **Critical**
- Use environment variables (not files)
- Strong secrets required
- **Never use defaults**

---

## Quick Setup by Phase

### Phase 0 (Current)

**Minimum Setup:**
```bash
cp .env.example .env
# Done! Defaults work for local development
```

**What .env contains:**
```bash
# Database URLs (Docker default ports)
TIMESCALE_URL=postgresql://postgres:postgres@localhost:5432/agent_observability
POSTGRES_URL=postgresql://postgres:postgres@localhost:5433/agent_observability_metadata
REDIS_URL=redis://:redis123@localhost:6379/0

# Development settings
DEBUG=true
NODE_ENV=development
PYTHON_ENV=development
```

---

### Phase 1 (Backend Services)

**Add these to .env:**
```bash
# Generate secure secrets
JWT_SECRET=$(openssl rand -base64 32)
API_KEY_SALT=$(openssl rand -base64 32)

# Or manually:
JWT_SECRET=your-32-character-secret-here-change-this
API_KEY_SALT=another-32-character-secret-here-change-this
```

**Generate secrets:**
```bash
# Option 1: OpenSSL
openssl rand -base64 32

# Option 2: Python
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Copy the output to .env
```

---

### Phase 4 (AI Features)

**Get Gemini API Key:**
1. Visit: https://makersuite.google.com/app/apikey
2. Click "Get API Key"
3. Copy the key

**Add to .env:**
```bash
GEMINI_API_KEY=AIzaSyC...your-key-here
```

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
response = model.generate_content('Hello')
print('✅ Gemini API working!')
print(response.text)
"
```

---

## Verification Tools

### 1. Check Environment Variables
```bash
cd backend
python check_env.py
```

**Output:**
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

---

### 2. Test Database Connections
```bash
cd backend
python test_connections.py
```

**Output:**
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

---

## Common Issues

### Issue: "Connection refused"

**Symptom:**
```
❌ Connection refused. Is Docker running?
```

**Fix:**
```bash
# Check if Docker containers are running
docker-compose ps

# If not running, start them
docker-compose up -d

# Wait a few seconds for startup
sleep 5

# Try again
python test_connections.py
```

---

### Issue: "Database does not exist"

**Symptom:**
```
❌ Database does not exist. Run setup.sh to create it.
```

**Fix:**
```bash
# Docker should auto-create databases on first start
# If not, restart containers
docker-compose down
docker-compose up -d

# Wait for startup
sleep 10

# Check logs
docker-compose logs timescaledb
docker-compose logs postgres
```

---

### Issue: Wrong ports

**Symptom:**
```
❌ Connection failed: could not connect to server
```

**Fix:**
```bash
# Check what ports Docker mapped
docker-compose ps

# You should see:
# timescaledb  ... 0.0.0.0:5432->5432/tcp
# postgres     ... 0.0.0.0:5433->5432/tcp
# redis        ... 0.0.0.0:6379->6379/tcp

# If ports are different, update .env:
# Example: if TimescaleDB is on 15432:
TIMESCALE_URL=postgresql://postgres:postgres@localhost:15432/agent_observability
```

---

### Issue: Frontend can't reach API

**Symptom:**
```
API Error: Network Error
```

**Fix:**

**Option 1: Create frontend .env.local**
```bash
cd frontend
cat > .env.local << EOF
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_WS_URL=ws://localhost:8000
EOF

# Restart Next.js
npm run dev
```

**Option 2: Check backend is running (Phase 1+)**
```bash
# In Phase 0, backend services don't exist yet
# This is expected!
```

---

## Environment Files by Service

```
Project Root
├── .env                     ← Main config (create this!)
│
Backend Services (Phase 1+)
├── backend/gateway/.env     ← Optional: Gateway overrides
├── backend/ingestion/.env   ← Optional: Ingestion overrides
└── backend/processing/.env  ← Optional: Processing overrides
│
Frontend
└── frontend/.env.local      ← Optional: Frontend config
```

**Best Practice:** Only use root `.env` for now. Add service-specific `.env` files only if you need to override values for specific services.

---

## Required vs Optional Variables

### ✅ Required (Phase 0)
- `TIMESCALE_URL` - TimescaleDB connection
- `POSTGRES_URL` - PostgreSQL connection
- `REDIS_URL` - Redis connection

### ⚠️ Required (Phase 1+)
- `JWT_SECRET` - JWT signing (32+ chars)
- `API_KEY_SALT` - API key hashing (32+ chars)

### 🔧 Optional (Phase 4+)
- `GEMINI_API_KEY` - AI evaluations
- `PERSPECTIVE_API_KEY` - Toxicity detection
- `SLACK_WEBHOOK_URL` - Alert notifications
- `PAGERDUTY_API_KEY` - Incident management

---

## Security Checklist

### Development ✅
- [x] Use `.env` file (gitignored)
- [x] Simple passwords OK for local
- [x] Share `.env.example` (no secrets)
- [x] Debug mode enabled

### Production 🔒
- [ ] Use environment variables (not `.env`)
- [ ] Strong secrets (32+ chars, random)
- [ ] SSL/TLS for all connections
- [ ] Managed databases
- [ ] Secret rotation policy
- [ ] No default passwords
- [ ] No exposed database ports
- [ ] Debug mode disabled

---

## Next Steps

### Phase 0 (Now)
```bash
# 1. Setup
cp .env.example .env
docker-compose up -d

# 2. Verify
cd backend
python check_env.py
python test_connections.py

# 3. Generate data
python synthetic_data/generator.py
python synthetic_data/load_data.py

# 4. Run frontend
cd ../frontend
npm install
npm run dev
```

### Phase 1 (Next)
```bash
# Add to .env
echo "JWT_SECRET=$(openssl rand -base64 32)" >> .env
echo "API_KEY_SALT=$(openssl rand -base64 32)" >> .env

# Verify
python check_env.py
```

### Phase 4 (Later)
```bash
# Get Gemini key from: https://makersuite.google.com/app/apikey
# Add to .env
echo "GEMINI_API_KEY=your-key-here" >> .env

# Verify
python check_env.py
```

---

## Full Documentation

For comprehensive details, see:
- **[docs/ENVIRONMENT_SETUP.md](docs/ENVIRONMENT_SETUP.md)** - Complete guide with all options
- **[.env.example](.env.example)** - Template with all variables
- **[PHASE_0_COMPLETE.md](PHASE_0_COMPLETE.md)** - Phase 0 completion guide

---

## Quick Reference

| What | Command |
|------|---------|
| **Check environment** | `python backend/check_env.py` |
| **Test connections** | `python backend/test_connections.py` |
| **Generate secrets** | `openssl rand -base64 32` |
| **Check Docker** | `docker-compose ps` |
| **View logs** | `docker-compose logs -f` |
| **Restart Docker** | `docker-compose restart` |
| **Stop Docker** | `docker-compose down` |
| **Start Docker** | `docker-compose up -d` |

---

## Summary

**For Phase 0 (Right Now):**
```bash
cp .env.example .env
# That's it! Defaults work.
```

**For Phase 1+ (Later):**
```bash
# Add JWT secrets when you get there
JWT_SECRET=$(openssl rand -base64 32)
```

**For Production (Much Later):**
```bash
# Use environment variables
# Strong secrets everywhere
# No default passwords
```

**Questions?** See [docs/ENVIRONMENT_SETUP.md](docs/ENVIRONMENT_SETUP.md)
