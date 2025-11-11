# macOS Setup Guide

## Quick Fix for "pg_config executable not found" Error

If you encountered this error during setup:

```
Error: pg_config executable not found.
pg_config is required to build psycopg2 from source.
```

**Don't worry!** This is fixed. Follow these steps:

### Solution 1: Clean Install (Recommended)

```bash
# 1. Remove the failed venv
cd /Users/pk1980/Documents/Software/Agent\ Monitoring/backend
rm -rf venv

# 2. Run setup again
cd ..
./setup.sh
```

The setup script now uses `requirements-phase0.txt` which works on macOS without needing PostgreSQL client libraries.

### Solution 2: Manual Install

```bash
# 1. Create virtual environment
cd backend
python3 -m venv venv
source venv/bin/activate

# 2. Install Phase 0 dependencies
pip install -r requirements-phase0.txt

# 3. Verify installation
python check_env.py
python test_connections.py

# 4. Generate data
python synthetic_data/generator.py
python synthetic_data/load_data.py
```

---

## What Changed?

### Phase 0 vs Full Requirements

**Phase 0** (Current - works on macOS):
- Uses `requirements-phase0.txt`
- Only installs what's needed for foundation setup
- No PostgreSQL client libraries required
- Minimal dependencies: asyncpg, redis, pytest, faker

**Phase 1+** (Later - may need PostgreSQL client):
- Uses full `requirements.txt`
- Includes all backend service dependencies
- May need PostgreSQL client for some features

### Why This Happened

The `psycopg2-binary` package (used in Phase 1+) needs to compile C extensions that require PostgreSQL development headers (`pg_config`). On macOS, this means you need PostgreSQL client libraries installed.

However, for Phase 0, we **don't actually use** `psycopg2-binary` - we only use `asyncpg` which doesn't need `pg_config`.

---

## Installing PostgreSQL Client (Optional - Only for Phase 1+)

If you need the full requirements later (Phase 1+), install PostgreSQL client:

### Option 1: Using Homebrew (Recommended)

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install PostgreSQL client
brew install postgresql@15

# Add to PATH (add to ~/.zshrc or ~/.bash_profile)
echo 'export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify pg_config is available
pg_config --version
```

### Option 2: Install Full PostgreSQL

```bash
# If you want full PostgreSQL (not just client)
brew install postgresql@15
brew services start postgresql@15
```

### After Installing PostgreSQL Client

Now you can install full requirements:

```bash
cd backend
source venv/bin/activate
pip install -r requirements.txt
```

---

## macOS-Specific Considerations

### Python Version

Ensure you're using Python 3.11+:

```bash
# Check version
python3 --version

# If too old, install newer Python
brew install python@3.11
```

### Shell (Zsh vs Bash)

macOS Catalina+ uses Zsh by default. The setup script works with both, but if you see:

```
The default interactive shell is now zsh.
To update your account to use zsh, please run `chsh -s /bin/zsh`.
```

You can either:
- **Ignore it** (script works fine)
- **Switch to Zsh:** `chsh -s /bin/zsh` (logout/login required)

### Docker Desktop

Make sure Docker Desktop is running:

1. Open Docker Desktop app
2. Wait for "Docker Desktop is running" in menu bar
3. Verify: `docker ps` (should not show error)

### Port Conflicts

If ports 5432, 5433, or 6379 are already in use:

```bash
# Check what's using the ports
lsof -i :5432
lsof -i :5433
lsof -i :6379

# Stop conflicting services (example: local PostgreSQL)
brew services stop postgresql
```

Or edit `docker-compose.yml` to use different ports:

```yaml
# Change from:
ports:
  - "5432:5432"

# To:
ports:
  - "15432:5432"  # Use port 15432 instead
```

---

## Verification Steps

After successful setup:

```bash
# 1. Check Docker containers
docker-compose ps
# Should show: agent_obs_timescaledb, agent_obs_postgres, agent_obs_redis (all Up)

# 2. Check environment
cd backend
source venv/bin/activate
python check_env.py
# Should show ✅ for all required variables

# 3. Test connections
python test_connections.py
# Should show ✅ for TimescaleDB, PostgreSQL, Redis

# 4. Run tests
pytest
# Should show 8 passing tests

# 5. Start frontend
cd ../frontend
npm install
npm run dev
# Should start on http://localhost:3000
```

---

## Common macOS Issues

### Issue: "python3: command not found"

```bash
# Install Python 3
brew install python@3.11

# Add to PATH
echo 'export PATH="/opt/homebrew/opt/python@3.11/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Issue: "docker-compose: command not found"

```bash
# Install Docker Desktop from:
# https://docs.docker.com/desktop/install/mac-install/

# Or use Homebrew
brew install --cask docker
```

### Issue: "Permission denied" on setup.sh

```bash
# Make executable
chmod +x setup.sh

# Run again
./setup.sh
```

### Issue: "Cannot connect to Docker daemon"

```bash
# Start Docker Desktop app
open -a Docker

# Wait for it to start (check menu bar)
# Try again
docker ps
```

### Issue: "Address already in use" (port conflicts)

```bash
# Find what's using the port
lsof -i :5432

# Kill the process (replace PID with actual PID from lsof)
kill -9 <PID>

# Or change docker-compose.yml ports
```

---

## Apple Silicon (M1/M2/M3) Notes

If you're on Apple Silicon (M1/M2/M3 Mac):

### Docker Platform

Docker Desktop should automatically handle ARM64, but if you have issues:

```bash
# Force x86_64 platform in docker-compose.yml
services:
  timescaledb:
    platform: linux/amd64  # Add this line
    image: timescale/timescaledb:latest-pg15
```

### Python Packages

Some packages may need ARM64 builds. If you see errors:

```bash
# Use Rosetta 2 for x86_64 compatibility
arch -x86_64 python3 -m venv venv
source venv/bin/activate
arch -x86_64 pip install -r requirements-phase0.txt
```

---

## Clean Reinstall

If everything is broken, start fresh:

```bash
# 1. Stop and remove all containers
docker-compose down -v

# 2. Remove Python virtual environment
rm -rf backend/venv

# 3. Remove frontend node_modules
rm -rf frontend/node_modules

# 4. Remove .env (will be recreated)
rm .env

# 5. Start fresh
./setup.sh
```

---

## Next Steps

After successful Phase 0 setup:

1. ✅ Docker containers running
2. ✅ Python dependencies installed
3. ✅ Frontend runs without errors
4. ✅ Tests passing

You're ready for Phase 1! See [PHASE_0_COMPLETE.md](PHASE_0_COMPLETE.md) for next steps.

---

## Getting Help

### Check Status

```bash
# Quick health check
docker-compose ps
cd backend && python test_connections.py
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs timescaledb
docker-compose logs postgres
docker-compose logs redis
```

### Restart Everything

```bash
# Restart Docker services
docker-compose restart

# Restart frontend
cd frontend
npm run dev
```

---

## Summary

**For Phase 0 on macOS:**
- ✅ Use `requirements-phase0.txt` (already updated in setup.sh)
- ✅ No PostgreSQL client needed
- ✅ Works out of the box

**For Phase 1+ (later):**
- May need: `brew install postgresql@15`
- Then can use full `requirements.txt`

**Right now, just run:**
```bash
./setup.sh
```

And it will work! 🎉
