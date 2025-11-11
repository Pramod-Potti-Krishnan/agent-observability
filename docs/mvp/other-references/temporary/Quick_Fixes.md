# Quick Fix for Your Error

## What Happened

You got this error:
```
Error: pg_config executable not found.
```

This is because `psycopg2-binary` needs PostgreSQL client libraries on macOS, but we don't actually need it for Phase 0!

## ✅ Fixed! Here's What to Do

### Step 1: Clean Up Failed Installation

```bash
cd /Users/pk1980/Documents/Software/Agent\ Monitoring/backend
rm -rf venv
```

### Step 2: Re-run Setup

```bash
cd /Users/pk1980/Documents/Software/Agent\ Monitoring
./setup.sh
```

**That's it!** The setup script now uses `requirements-phase0.txt` which works on macOS.

---

## What Changed

I created a new file `backend/requirements-phase0.txt` with minimal dependencies that work on macOS without needing PostgreSQL client libraries:

- ✅ `asyncpg` (for database connections)
- ✅ `redis` (for caching)
- ✅ `pytest` (for testing)
- ✅ `faker` (for synthetic data)
- ✅ `python-dotenv` (for environment variables)

The `setup.sh` script now uses this instead of the full `requirements.txt`.

---

## Expected Output

When you re-run `./setup.sh`, you should see:

```
==========================================
Agent Observability Platform - Setup
==========================================

Step 1: Creating .env file from template...
⚠️  .env file already exists. Skipping.

Step 2: Starting Docker containers...
[+] Running 3/3
 ✔ Container agent_obs_timescaledb  Running
 ✔ Container agent_obs_postgres     Running
 ✔ Container agent_obs_redis        Running

Step 3: Waiting for databases to be ready...

Step 4: Installing Python dependencies...
Installing Phase 0 dependencies...
Successfully installed asyncpg-0.29.0 redis-5.0.1 pytest-7.4.4 ...
✅ Installed Python dependencies

Step 5: Generating synthetic data...
Generating synthetic data...
Generated 10000 traces
✅ Synthetic data generation complete!

Step 6: Loading synthetic data into databases...
Loading 10000 traces into TimescaleDB...
✅ Loaded traces

Step 7: Installing frontend dependencies...
added 380 packages
✅ Installed frontend dependencies

==========================================
✅ Setup complete!
==========================================
```

---

## Verify Everything Works

After setup completes:

```bash
# 1. Test database connections
cd backend
source venv/bin/activate
python test_connections.py

# Expected: ✅ All database connections successful!

# 2. Run tests
pytest

# Expected: ======= 8 passed in X seconds =======

# 3. Start frontend
cd ../frontend
npm run dev

# Expected: ready - started server on 0.0.0.0:3000
```

---

## If You Still Have Issues

See the comprehensive troubleshooting guide: [MACOS_SETUP.md](MACOS_SETUP.md)

Or check these:

**Docker not running?**
```bash
# Start Docker Desktop
open -a Docker
# Wait for it to start, then try again
```

**Port conflicts?**
```bash
# Check if ports are in use
lsof -i :5432
lsof -i :5433
lsof -i :6379

# If something is using these ports, stop it or change docker-compose.yml
```

**Still getting errors?**
```bash
# Complete clean reinstall
docker-compose down -v
rm -rf backend/venv frontend/node_modules .env
./setup.sh
```

---

## Next Steps

Once setup completes successfully:

1. Visit http://localhost:3000
2. See your dashboard with KPI cards
3. Navigate through all 8 pages
4. Phase 0 is complete! 🎉

See [PHASE_0_COMPLETE.md](PHASE_0_COMPLETE.md) for what's next.
