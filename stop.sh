#!/bin/bash

# Agent Observability Platform - Stop Script
# This script stops all services gracefully

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Agent Observability Platform - Stopping"
echo "=========================================="

# Helper functions
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Stop frontend (if running)
stop_frontend() {
    echo ""
    print_info "Checking for running frontend..."

    # Find and kill any process running on port 3000
    FRONTEND_PID=$(lsof -ti:3000 2>/dev/null || true)

    if [ ! -z "$FRONTEND_PID" ]; then
        print_info "Stopping frontend (PID: $FRONTEND_PID)..."
        kill $FRONTEND_PID
        print_success "Frontend stopped"
    else
        print_info "Frontend is not running"
    fi
}

# Stop backend services (Phase 1+)
stop_backend_services() {
    echo ""
    print_info "Checking for running backend services..."

    # Check if backend services are running (they will be in Phase 1+)
    BACKEND_PIDS=$(lsof -ti:8000-8007 2>/dev/null || true)

    if [ ! -z "$BACKEND_PIDS" ]; then
        print_info "Stopping backend services..."
        echo $BACKEND_PIDS | xargs kill
        print_success "Backend services stopped"
    else
        print_info "No backend services running"
    fi
}

# Stop Docker containers
stop_docker_services() {
    echo ""
    print_info "Stopping Docker containers..."

    docker-compose stop

    if [ $? -eq 0 ]; then
        print_success "Docker containers stopped"
    else
        print_warning "Failed to stop some Docker containers"
    fi
}

# Show final status
show_status() {
    echo ""
    echo "=========================================="
    echo "Shutdown Complete"
    echo "=========================================="
    echo ""
    print_success "All services stopped"
    echo ""
    echo "To start again, run:"
    echo "  ${GREEN}./start.sh${NC}"
    echo ""
    echo "To completely remove containers and data:"
    echo "  ${RED}docker-compose down -v${NC}"
    echo ""
    echo "=========================================="
}

# Main execution
main() {
    stop_frontend
    stop_backend_services
    stop_docker_services
    show_status
}

# Run main function
main
