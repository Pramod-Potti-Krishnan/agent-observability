#!/bin/bash

# Agent Observability Platform - Startup Script
# This script starts all services for the platform

set -e

echo "=========================================="
echo "Agent Observability Platform - Starting"
echo "=========================================="

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

# Check if Docker is running
check_docker() {
    echo ""
    print_info "Checking Docker..."
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running!"
        echo "Please start Docker Desktop and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Start Docker containers
start_docker_services() {
    echo ""
    print_info "Starting Docker containers..."
    docker-compose up -d

    if [ $? -eq 0 ]; then
        print_success "Docker containers started"
    else
        print_error "Failed to start Docker containers"
        exit 1
    fi
}

# Wait for databases to be ready
wait_for_databases() {
    echo ""
    print_info "Waiting for databases to be ready..."

    MAX_RETRIES=30
    RETRY_COUNT=0

    # Wait for TimescaleDB
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
        exit 1
    fi

    # Wait for PostgreSQL
    RETRY_COUNT=0
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
        exit 1
    fi

    # Wait for Redis
    RETRY_COUNT=0
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
        exit 1
    fi
}

# Check database health
check_database_health() {
    echo ""
    print_info "Checking database health..."

    cd backend

    if [ -d "venv" ]; then
        source venv/bin/activate

        # Run connection test
        if python test_connections.py > /dev/null 2>&1; then
            print_success "All databases are healthy"
        else
            print_warning "Database health check failed (but containers are running)"
            print_info "You may need to run: python backend/test_connections.py"
        fi

        deactivate
    else
        print_warning "Python virtual environment not found"
        print_info "Run ./setup.sh first to set up the environment"
    fi

    cd ..
}

# Start backend services (Phase 1+)
start_backend_services() {
    echo ""
    print_info "Checking for backend services..."

    # Check if backend services exist (they will in Phase 1+)
    if [ -d "backend/gateway" ]; then
        print_info "Starting backend services..."
        # TODO: Add backend service startup commands in Phase 1
        print_warning "Backend services not yet implemented (Phase 1+)"
    else
        print_info "Backend services not yet available (Phase 0)"
    fi
}

# Start frontend
start_frontend() {
    echo ""
    print_info "Starting frontend development server..."

    cd frontend

    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        print_error "node_modules not found!"
        print_info "Run ./setup.sh first to install dependencies"
        exit 1
    fi

    print_success "Frontend ready to start"
    print_info "Run: cd frontend && npm run dev"

    cd ..
}

# Display status
show_status() {
    echo ""
    echo "=========================================="
    echo "Status Summary"
    echo "=========================================="
    echo ""

    # Docker containers
    echo "Docker Containers:"
    docker-compose ps

    echo ""
    echo "=========================================="
    echo "Next Steps"
    echo "=========================================="
    echo ""
    echo "1. Start the frontend:"
    echo "   ${GREEN}cd frontend && npm run dev${NC}"
    echo ""
    echo "2. Visit your application:"
    echo "   ${BLUE}http://localhost:3000${NC}"
    echo ""
    echo "3. View logs:"
    echo "   ${YELLOW}docker-compose logs -f${NC}"
    echo ""
    echo "4. Stop all services:"
    echo "   ${RED}./stop.sh${NC}"
    echo ""
    echo "=========================================="
}

# Main execution
main() {
    check_docker
    start_docker_services
    wait_for_databases
    check_database_health
    start_backend_services
    start_frontend
    show_status
}

# Run main function
main
