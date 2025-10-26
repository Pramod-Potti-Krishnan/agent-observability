#!/bin/bash

# Agent Observability Platform - Setup Script
# This script sets up the development environment

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Wait for databases to be ready
wait_for_databases() {
    echo ""
    print_info "Waiting for databases to be ready..."
    echo ""

    MAX_RETRIES=30
    RETRY_COUNT=0

    # Wait for TimescaleDB
    print_info "Checking TimescaleDB..."
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if docker exec agent_obs_timescaledb pg_isready -U postgres > /dev/null 2>&1; then
            print_success "TimescaleDB is ready"
            break
        fi
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo -n "."
        sleep 1
    done

    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        print_error "TimescaleDB failed to start in time"
        echo ""
        print_info "Check logs with: docker-compose logs timescaledb"
        exit 1
    fi

    # Wait for PostgreSQL
    RETRY_COUNT=0
    print_info "Checking PostgreSQL..."
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if docker exec agent_obs_postgres pg_isready -U postgres > /dev/null 2>&1; then
            print_success "PostgreSQL is ready"
            break
        fi
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo -n "."
        sleep 1
    done

    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        print_error "PostgreSQL failed to start in time"
        echo ""
        print_info "Check logs with: docker-compose logs postgres"
        exit 1
    fi

    # Wait for Redis
    RETRY_COUNT=0
    print_info "Checking Redis..."
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if docker exec agent_obs_redis redis-cli -a redis123 ping > /dev/null 2>&1; then
            print_success "Redis is ready"
            break
        fi
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo -n "."
        sleep 1
    done

    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        print_error "Redis failed to start in time"
        echo ""
        print_info "Check logs with: docker-compose logs redis"
        exit 1
    fi

    echo ""
    print_success "All databases are ready!"
}

echo "=========================================="
echo "Agent Observability Platform - Setup"
echo "=========================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo ""
echo "Step 1: Creating .env file from template..."
if [ ! -f .env ]; then
    cp .env.example .env
    print_success "Created .env file"
else
    print_warning ".env file already exists. Skipping."
fi

echo ""
echo "Step 2: Starting Docker containers..."
docker-compose up -d

echo ""
echo "Step 3: Waiting for databases to be ready..."
wait_for_databases

echo ""
echo "Step 4: Installing Python dependencies..."
cd backend
if [ ! -d "venv" ]; then
    python3 -m venv venv
    print_success "Created virtual environment"
fi

source venv/bin/activate

# Upgrade pip first
pip install --upgrade pip

# Use Phase 0 requirements (minimal, works on macOS without PostgreSQL client)
echo "Installing Phase 0 dependencies..."
pip install -r requirements-phase0.txt

# Capture exact versions installed
pip freeze > requirements-phase0-lock.txt
print_success "Installed Python dependencies (versions saved to requirements-phase0-lock.txt)"

echo ""
echo "Step 5: Generating synthetic data..."
python synthetic_data/generator.py
print_success "Generated synthetic data"

echo ""
echo "Step 6: Loading synthetic data into databases..."
python synthetic_data/load_data.py
print_success "Loaded synthetic data"

cd ..

echo ""
echo "Step 7: Installing frontend dependencies..."
cd frontend
npm install
print_success "Installed frontend dependencies"

cd ..

echo ""
echo "=========================================="
print_success "Setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Start the frontend: cd frontend && npm run dev"
echo "2. Backend services will be implemented in Phase 1"
echo "3. Run tests: cd backend && source venv/bin/activate && pytest"
echo ""
echo "Access the application at: http://localhost:3000"
echo "=========================================="
