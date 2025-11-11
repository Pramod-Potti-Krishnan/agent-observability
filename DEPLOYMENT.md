# GARUDAI Deployment Guide

**Complete guide to deploying GARUDAI to production**

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Frontend Deployment (Vercel)](#frontend-deployment-vercel)
4. [Backend Deployment (Railway)](#backend-deployment-railway)
5. [Environment Variables](#environment-variables)
6. [Custom Domain Setup](#custom-domain-setup)
7. [Monitoring & Maintenance](#monitoring--maintenance)
8. [Troubleshooting](#troubleshooting)

---

## Overview

GARUDAI uses a **split deployment architecture**:

- **Frontend** (Next.js) → Vercel
- **Backend** (FastAPI microservices) → Railway
- **Databases** → Railway managed services

### Architecture Diagram

```
┌─────────────────┐
│   Users/Clients │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│  Vercel (Frontend)              │
│  - Next.js App                  │
│  - GARUDAI UI                   │
│  - Static Assets                │
└────────┬────────────────────────┘
         │ HTTPS API Calls
         ▼
┌─────────────────────────────────┐
│  Railway (Backend)              │
│  ┌───────────────────────────┐ │
│  │ Gateway (API Proxy)       │ │
│  ├───────────────────────────┤ │
│  │ Microservices:            │ │
│  │  - Query                  │ │
│  │  - Evaluation             │ │
│  │  - Guardrail              │ │
│  │  - Alert                  │ │
│  │  - Gemini                 │ │
│  │  - Ingestion              │ │
│  │  - Processing             │ │
│  └───────────────────────────┘ │
│  ┌───────────────────────────┐ │
│  │ Databases:                │ │
│  │  - PostgreSQL             │ │
│  │  - TimescaleDB            │ │
│  │  - Redis                  │ │
│  └───────────────────────────┘ │
└─────────────────────────────────┘
```

---

## Prerequisites

### Required Accounts

1. **GitHub Account** - For repository hosting
2. **Vercel Account** - For frontend deployment (free tier available)
3. **Railway Account** - For backend deployment ($5/month minimum)

### Required Tools

```bash
# Git
git --version  # Should be 2.x+

# Node.js
node --version  # Should be 18.x+ or 20.x+

# NPM
npm --version  # Should be 9.x+ or 10.x+

# Optional: Railway CLI
npm install -g @railway/cli
```

---

## Frontend Deployment (Vercel)

### Step 1: Prepare Frontend Repository

You have two options:

#### Option A: Keep Current Repository (Monorepo)
Deploy only the `frontend/` directory from your existing repo.

#### Option B: Create Separate Frontend Repository (Recommended)

```bash
# Create new directory
mkdir garudai-frontend
cd garudai-frontend

# Copy frontend files
cp -r ../Agent\ Monitoring/frontend/* .
cp ../Agent\ Monitoring/frontend/.env.example .env.local
cp ../Agent\ Monitoring/frontend/vercel.json .

# Initialize git
git init
git add .
git commit -m "Initial commit: GARUDAI frontend"

# Create GitHub repository (via web or CLI)
gh repo create garudai-frontend --public --source=. --push
```

### Step 2: Connect to Vercel

1. Go to [vercel.com](https://vercel.com) and sign in
2. Click **"Add New Project"**
3. Import your GitHub repository
4. Configure build settings:
   - **Framework Preset**: Next.js (auto-detected)
   - **Root Directory**: `./` (or `frontend/` if monorepo)
   - **Build Command**: `npm run build` (auto-detected)
   - **Output Directory**: `.next` (auto-detected)

### Step 3: Configure Environment Variables

In Vercel dashboard → Settings → Environment Variables, add:

```bash
# Required
NEXT_PUBLIC_API_URL=https://your-railway-gateway-url.up.railway.app

# Optional (branding)
NEXT_PUBLIC_APP_NAME=GARUDAI
NEXT_PUBLIC_APP_TAGLINE=Global Agent Runtime Unified Dashboard AI
```

### Step 4: Deploy

1. Click **"Deploy"**
2. Wait for build to complete (2-3 minutes)
3. Your app will be live at: `https://your-project.vercel.app`

### Step 5: Test Frontend

```bash
curl https://your-project.vercel.app
# Should return HTML page
```

---

## Backend Deployment (Railway)

### Why Railway?

- ✅ Docker-native (no code changes needed)
- ✅ Managed PostgreSQL, TimescaleDB, Redis
- ✅ Simple deployment from GitHub
- ✅ Internal networking between services
- ✅ Auto-scaling and health checks
- ✅ Cost-effective ($20-50/month for full stack)

### Step 1: Sign Up for Railway

1. Go to [railway.app](https://railway.app)
2. Sign in with GitHub
3. Verify your account
4. Add payment method ($5 minimum)

### Step 2: Create New Project

1. Click **"New Project"**
2. Select **"Deploy from GitHub repo"**
3. Choose your `garudai-backend` repository (or current repo)
4. Railway will detect your services

### Step 3: Deploy Databases First

#### Deploy PostgreSQL

1. In Railway dashboard, click **"+ New"**
2. Select **"Database" → "PostgreSQL"**
3. Name it: `garudai-postgres`
4. Railway provisions and provides `DATABASE_URL`

#### Deploy TimescaleDB

Railway doesn't have TimescaleDB template, so use PostgreSQL + extension:

1. Add another PostgreSQL database: `garudai-timescaledb`
2. Connect via Railway console and run:
   ```sql
   CREATE EXTENSION IF NOT EXISTS timescaledb;
   ```

#### Deploy Redis

1. Click **"+ New" → "Database" → "Redis"**
2. Name it: `garudai-redis`
3. Railway provides `REDIS_URL`

### Step 4: Deploy Backend Services

For each service (gateway, query, evaluation, etc.):

#### 4.1 Create Service

1. Click **"+ New" → "GitHub Repo"**
2. Select your repository
3. Configure:
   - **Root Directory**: `backend/gateway` (or respective service)
   - **Build Command**: Detected from Dockerfile
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`

#### 4.2 Set Environment Variables

In each service's **Variables** tab, add:

```bash
# Database URLs (copy from Railway-provided variables)
DATABASE_URL=${{garudai-postgres.DATABASE_URL}}
TIMESCALEDB_URL=${{garudai-timescaledb.DATABASE_URL}}
REDIS_URL=${{garudai-redis.REDIS_URL}}

# Service URLs (use Railway internal networking)
QUERY_URL=http://query.railway.internal:8001
EVALUATION_URL=http://evaluation.railway.internal:8002
GUARDRAIL_URL=http://guardrail.railway.internal:8003
# ... etc

# CORS (your Vercel frontend URL)
CORS_ORIGINS=https://your-project.vercel.app

# Secrets (generate secure values!)
JWT_SECRET=$(openssl rand -hex 32)
API_KEY_SALT=$(openssl rand -hex 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)

# LLM API Keys
GEMINI_API_KEY=your_actual_key
OPENAI_API_KEY=your_actual_key
```

#### 4.3 Expose Gateway Service

Only the **Gateway** service needs a public URL:

1. Go to Gateway service → **Settings**
2. Click **"Generate Domain"**
3. Copy the URL: `https://garudai-gateway-xxx.up.railway.app`
4. Update Vercel env var `NEXT_PUBLIC_API_URL` with this URL

### Step 5: Service Deployment Order

Deploy in this order to handle dependencies:

1. **Databases** (PostgreSQL, TimescaleDB, Redis)
2. **Gemini Service** (LLM integration)
3. **Guardrail Service** (safety checks)
4. **Evaluation Service** (quality checks)
5. **Query Service** (analytics)
6. **Alert Service** (notifications)
7. **Ingestion Service** (data collection)
8. **Processing Service** (data transformation)
9. **Gateway Service** (API proxy - last!)

### Step 6: Run Database Migrations

Connect to PostgreSQL via Railway console:

```bash
# Get database credentials from Railway
railway connect garudai-postgres

# Run migrations
psql $DATABASE_URL < database/migrations/*.sql
```

Or use Alembic (if configured):

```bash
railway run alembic upgrade head
```

### Step 7: Test Backend

```bash
# Health check
curl https://garudai-gateway-xxx.up.railway.app/health

# API test
curl https://garudai-gateway-xxx.up.railway.app/api/v1/agents
```

---

## Environment Variables

### Frontend (Vercel)

| Variable | Description | Example |
|----------|-------------|---------|
| `NEXT_PUBLIC_API_URL` | Backend Gateway URL | `https://garudai-gateway.up.railway.app` |
| `NEXT_PUBLIC_APP_NAME` | Application name | `GARUDAI` |
| `NEXT_PUBLIC_APP_TAGLINE` | Tagline | `Global Agent Runtime Unified Dashboard AI` |

### Backend (Railway)

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `DATABASE_URL` | PostgreSQL connection | ✅ | `postgresql://user:pass@host:5432/db` |
| `TIMESCALEDB_URL` | TimescaleDB connection | ✅ | `postgresql://user:pass@host:5432/metrics` |
| `REDIS_URL` | Redis connection | ✅ | `redis://host:6379` |
| `CORS_ORIGINS` | Allowed frontend URLs | ✅ | `https://garudai.vercel.app` |
| `JWT_SECRET` | JWT signing key | ✅ | 32+ char random string |
| `GEMINI_API_KEY` | Google Gemini API key | ❌ | `AIza...` |
| `OPENAI_API_KEY` | OpenAI API key | ❌ | `sk-...` |

### Generate Secure Secrets

```bash
# JWT Secret
openssl rand -hex 32

# API Key Salt
openssl rand -hex 32

# Encryption Key
openssl rand -hex 32
```

---

## Custom Domain Setup

### Configure garudai.app Domain

#### For Vercel (Frontend)

1. Buy domain from Namecheap, GoDaddy, etc.
2. In Vercel → Settings → Domains
3. Add domain: `garudai.app` and `www.garudai.app`
4. Update DNS records (provided by Vercel):
   ```
   A     @        76.76.21.21
   CNAME www      cname.vercel-dns.com
   ```

#### For Railway (Backend API)

1. In Railway Gateway service → Settings → Domains
2. Add custom domain: `api.garudai.app`
3. Update DNS:
   ```
   CNAME api      <your-project>.up.railway.app
   ```

SSL certificates are automatic via Vercel and Railway.

---

## Monitoring & Maintenance

### Vercel Monitoring

- **Analytics**: Built-in (free tier limited)
- **Logs**: Vercel dashboard → Functions → Logs
- **Deployments**: Automatic on git push
- **Rollbacks**: One-click rollback in dashboard

### Railway Monitoring

- **Logs**: Railway dashboard → Service → Logs (real-time)
- **Metrics**: CPU, Memory, Network usage
- **Health Checks**: Configure `/health` endpoints
- **Alerts**: Set up via Railway webhooks

### Database Backups

Railway automatically backs up databases:
- **PostgreSQL**: Daily automatic backups
- **Redis**: Persistence enabled by default

Manual backup:

```bash
# PostgreSQL
railway run pg_dump $DATABASE_URL > backup.sql

# Restore
railway run psql $DATABASE_URL < backup.sql
```

---

## Troubleshooting

### Frontend Issues

#### Build Fails on Vercel

**Error**: `Module not found`

**Solution**:
```bash
# Clear cache and rebuild
vercel --prod --force
```

#### API calls failing (CORS)

**Error**: `Access-Control-Allow-Origin`

**Solution**: Update backend `CORS_ORIGINS` to include Vercel URL:
```bash
CORS_ORIGINS=https://your-project.vercel.app,https://garudai.app
```

### Backend Issues

#### Service won't start on Railway

**Error**: `Port already in use`

**Solution**: Ensure start command uses `$PORT`:
```bash
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

#### Database connection fails

**Error**: `connection refused`

**Solution**: Check Railway internal URLs:
```bash
# Use internal networking
DATABASE_URL=${{garudai-postgres.DATABASE_URL}}

# NOT external URL
```

#### Out of memory

**Solution**: Upgrade Railway plan or optimize:
```python
# Reduce worker count
uvicorn app.main:app --workers 1
```

### General Issues

#### High costs on Railway

**Solution**:
- Check resource usage in dashboard
- Downgrade unused services
- Implement caching (Redis)
- Optimize database queries

#### Slow API responses

**Solution**:
- Add Redis caching
- Optimize database indexes
- Enable connection pooling
- Use Railway's internal networking

---

## Deployment Checklist

### Pre-Deployment

- [ ] All code committed to git
- [ ] Environment variables documented
- [ ] Database migrations ready
- [ ] Frontend connects to backend locally
- [ ] Docker containers working locally

### Frontend (Vercel)

- [ ] Repository connected
- [ ] Environment variables set
- [ ] Build successful
- [ ] API URL points to Railway
- [ ] Custom domain configured (optional)

### Backend (Railway)

- [ ] All databases deployed
- [ ] Database extensions installed (TimescaleDB)
- [ ] All microservices deployed
- [ ] Environment variables configured
- [ ] Gateway has public URL
- [ ] Internal networking configured
- [ ] Migrations run successfully

### Post-Deployment

- [ ] Test all frontend pages
- [ ] Test all API endpoints
- [ ] Verify database connections
- [ ] Check logs for errors
- [ ] Monitor resource usage
- [ ] Set up alerts
- [ ] Configure backups

---

## Cost Estimation

### Monthly Costs

| Service | Tier | Cost |
|---------|------|------|
| **Vercel** | Hobby (Free) | $0 |
| **Vercel** | Pro | $20 |
| **Railway** | Starter | $5 credit/month |
| **Railway** | Databases (3x) | ~$15-20 |
| **Railway** | Services (8x) | ~$10-30 |
| **Domain** | .app TLD | ~$1/month |
| **Total (Free tier)** | | ~$25-30/month |
| **Total (Pro)** | | ~$45-70/month |

### Free Tier Limits

- **Vercel**: Unlimited deployments, bandwidth limits
- **Railway**: $5 free credit/month, then pay-as-you-go

---

## Next Steps

After successful deployment:

1. **Set up monitoring** - Add error tracking (Sentry)
2. **Configure analytics** - Track user behavior
3. **Enable CI/CD** - Automatic testing before deploy
4. **Add staging environment** - Test before production
5. **Scale services** - Adjust based on usage
6. **Optimize costs** - Monitor Railway usage

---

## Support

- **Railway Docs**: https://docs.railway.app
- **Vercel Docs**: https://vercel.com/docs
- **GARUDAI Issues**: https://github.com/your-repo/issues

---

**Document Version**: 1.0
**Last Updated**: November 11, 2025
**Generated with** [Claude Code](https://claude.com/claude-code)
