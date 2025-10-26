# Phase 2 Quick Start Guide

## Start Services

```bash
cd "/Users/pk1980/Documents/Software/Agent Monitoring"

# Start all services
docker-compose up --build -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f query frontend
```

## Access Applications

- **Frontend Dashboard:** http://localhost:3000
- **API Gateway:** http://localhost:8000
- **Query Service API:** http://localhost:8003
- **Query Service Docs:** http://localhost:8003/docs

## Quick Test

### 1. Register User
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "demo@test.com",
    "password": "password123",
    "full_name": "Demo User",
    "workspace_name": "Demo Workspace"
  }'
```

### 2. Login
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "demo@test.com", "password": "password123"}'
```

### 3. Open Dashboard
Navigate to http://localhost:3000/login and login with:
- Email: demo@test.com
- Password: password123

## Run Tests

```bash
# Backend tests
cd backend/query
pip install -r requirements.txt
pytest tests/ -v

# Check test coverage
pytest tests/ -v --cov=app --cov-report=html
```

## Stop Services

```bash
docker-compose down

# Remove volumes (clean slate)
docker-compose down -v
```

## Troubleshooting

### Query Service not starting
```bash
docker-compose logs query
docker exec -it agent_obs_query curl http://localhost:8003/health
```

### Frontend not loading
```bash
docker-compose logs frontend
docker-compose restart frontend
```

### Database connection issues
```bash
docker-compose logs timescaledb postgres
docker-compose restart timescaledb postgres
```

### Clear cache
```bash
docker exec -it agent_obs_redis redis-cli -a redis123 FLUSHALL
```

## File Locations

**Backend Query Service:**
- `/Users/pk1980/Documents/Software/Agent Monitoring/backend/query/`

**Frontend:**
- `/Users/pk1980/Documents/Software/Agent Monitoring/frontend/`

**Tests:**
- `/Users/pk1980/Documents/Software/Agent Monitoring/backend/query/tests/`

## Key Endpoints

**Query Service (8003):**
- GET `/api/v1/metrics/home-kpis?range=24h`
- GET `/api/v1/alerts/recent?limit=10`
- GET `/api/v1/activity/stream?limit=50`
- GET `/api/v1/traces?range=24h&limit=50`
- GET `/api/v1/traces/{trace_id}`

**Gateway (8000):**
- POST `/api/v1/auth/register`
- POST `/api/v1/auth/login`
- GET `/api/v1/auth/me`

## Environment Variables

Query Service (.env):
```
TIMESCALE_URL=postgresql://postgres:postgres@timescaledb:5432/agent_observability
POSTGRES_URL=postgresql://postgres:postgres@postgres:5432/agent_observability_metadata
REDIS_URL=redis://:redis123@redis:6379/0
CACHE_TTL_HOME_KPIS=300
CACHE_TTL_ALERTS=60
CACHE_TTL_ACTIVITY=30
CACHE_TTL_TRACES=120
```

Frontend (.env.local):
```
NEXT_PUBLIC_API_URL=http://localhost:8000
```
