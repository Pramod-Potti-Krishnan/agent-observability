#!/bin/bash

# Agent Observability Platform - Status Check Script
# This script shows the status of all services

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Agent Observability Platform - Status"
echo "=========================================="

# Helper functions
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check Docker
echo ""
echo "Docker Status:"
echo "=============================================="
if docker info > /dev/null 2>&1; then
    print_success "Docker is running"
else
    print_error "Docker is not running"
fi

# Check Docker containers
echo ""
echo "Docker Containers:"
echo "=============================================="
docker-compose ps

# Check individual container health
echo ""
echo "Container Health:"
echo "=============================================="

# TimescaleDB
if docker exec agent_obs_timescaledb pg_isready -U postgres > /dev/null 2>&1; then
    print_success "TimescaleDB: Healthy"
else
    print_error "TimescaleDB: Not responding"
fi

# PostgreSQL
if docker exec agent_obs_postgres pg_isready -U postgres > /dev/null 2>&1; then
    print_success "PostgreSQL: Healthy"
else
    print_error "PostgreSQL: Not responding"
fi

# Redis
if docker exec agent_obs_redis redis-cli -a redis123 ping > /dev/null 2>&1; then
    print_success "Redis: Healthy"
else
    print_error "Redis: Not responding"
fi

# Check ports
echo ""
echo "Port Status:"
echo "=============================================="

check_port() {
    local port=$1
    local service=$2
    if lsof -Pi :$port -sTCP:LISTEN -t > /dev/null 2>&1; then
        print_success "Port $port ($service): In use"
    else
        print_warning "Port $port ($service): Available"
    fi
}

check_port 5432 "TimescaleDB"
check_port 5433 "PostgreSQL"
check_port 6379 "Redis"
check_port 3000 "Frontend"
check_port 8000 "API Gateway (Phase 1+)"

# Check database data
echo ""
echo "Database Data:"
echo "=============================================="

if [ -d "backend/venv" ]; then
    cd backend
    source venv/bin/activate

    # Check trace count
    TRACE_COUNT=$(python -c "
import asyncpg
import asyncio
import os
from dotenv import load_dotenv

load_dotenv()

async def get_count():
    try:
        conn = await asyncpg.connect(os.getenv('TIMESCALE_URL'))
        count = await conn.fetchval('SELECT COUNT(*) FROM traces')
        await conn.close()
        return count
    except:
        return 'N/A'

print(asyncio.run(get_count()))
" 2>/dev/null || echo "N/A")

    echo "  Traces in database: $TRACE_COUNT"

    deactivate
    cd ..
else
    print_warning "Python environment not set up"
fi

# Check frontend
echo ""
echo "Frontend Status:"
echo "=============================================="
if [ -d "frontend/node_modules" ]; then
    print_success "Dependencies installed"
    if lsof -Pi :3000 -sTCP:LISTEN -t > /dev/null 2>&1; then
        print_success "Frontend running on http://localhost:3000"
    else
        print_info "Frontend not running (start with: cd frontend && npm run dev)"
    fi
else
    print_warning "Dependencies not installed (run ./setup.sh)"
fi

# System resources
echo ""
echo "System Resources:"
echo "=============================================="

# Docker stats (non-blocking)
if docker info > /dev/null 2>&1; then
    echo "Container resource usage:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" agent_obs_timescaledb agent_obs_postgres agent_obs_redis 2>/dev/null || echo "  Unable to fetch stats"
fi

# Summary
echo ""
echo "=========================================="
echo "Quick Actions"
echo "=========================================="
echo ""
echo "Start all services:     ${GREEN}./start.sh${NC}"
echo "Stop all services:      ${RED}./stop.sh${NC}"
echo "View logs:              ${YELLOW}docker-compose logs -f${NC}"
echo "Restart containers:     ${BLUE}docker-compose restart${NC}"
echo ""
echo "Test connections:       ${BLUE}python backend/test_connections.py${NC}"
echo "Check environment:      ${BLUE}python backend/check_env.py${NC}"
echo ""
echo "=========================================="
