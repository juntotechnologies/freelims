#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Production Environment Management Script
# This script provides commands to manage the FreeLIMS production environment
# ----------------------------------------------------------------------------

# Source the utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../common/utils.sh"

# Main log file for this script
LOG_FILE="prod_environment.log"

# Configuration
BACKEND_PORT=8000
FRONTEND_PORT=3000
PROD_BACKEND_PORT=9000
DB_CONFIG_FILE="${BACKEND_DIR}/app/database.py"

# Print usage information
usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start        Start the production environment"
    echo "  stop         Stop the production environment"
    echo "  restart      Restart the production environment"
    echo "  status       Show the status of production services"
    echo "  logs         Show production logs"
    echo "  build        Build the frontend for production"
    echo "  deploy       Deploy the production environment"
    echo "  help         Show this help message"
    echo ""
    exit 0
}

# Build frontend for production
build_frontend() {
    log_info "Building frontend for production..." "${LOG_FILE}"
    
    # Check if Node.js and npm are installed
    check_nodejs "${LOG_FILE}" || return 1
    
    # Check npm packages
    check_npm_packages "${LOG_FILE}" || return 1
    
    # Set environment variable for production build
    log_info "Setting up environment for production build..." "${LOG_FILE}"
    
    # Create or update .env.production
    if [[ ! -f "${FRONTEND_DIR}/.env.production" ]]; then
        log_info "Creating frontend .env.production..." "${LOG_FILE}"
        echo "REACT_APP_API_URL=/api" > "${FRONTEND_DIR}/.env.production"
    else
        # Ensure correct API URL in .env.production
        grep -q "REACT_APP_API_URL" "${FRONTEND_DIR}/.env.production" && \
        sed -i.bak "s|REACT_APP_API_URL=.*|REACT_APP_API_URL=/api|g" "${FRONTEND_DIR}/.env.production" || \
        echo "REACT_APP_API_URL=/api" >> "${FRONTEND_DIR}/.env.production"
    fi
    
    # Clean previous build
    if [[ -d "${FRONTEND_DIR}/build" ]]; then
        log_info "Cleaning previous build..." "${LOG_FILE}"
        rm -rf "${FRONTEND_DIR}/build"
    fi
    
    # Build the frontend
    log_info "Building frontend application..." "${LOG_FILE}"
    (cd "${FRONTEND_DIR}" && npm run build) || {
        log_error "Frontend build failed" "${LOG_FILE}"
        return 1
    }
    
    log_success "Frontend built successfully for production" "${LOG_FILE}"
    return 0
}

# Start the production environment
start_prod() {
    log_info "Starting FreeLIMS production environment..." "${LOG_FILE}"
    
    # Check prerequisites
    check_prerequisites || {
        log_error "Failed to meet prerequisites for production environment" "${LOG_FILE}"
        return 1
    }
    
    # Check if already running
    if is_prod_running; then
        log_warning "Production environment is already running" "${LOG_FILE}"
        log_info "Use '$0 restart' to restart or '$0 stop' to stop first" "${LOG_FILE}"
        return 0
    fi
    
    # Check if frontend is built
    if [[ ! -d "${FRONTEND_DIR}/build" ]]; then
        log_warning "Frontend is not built for production" "${LOG_FILE}"
        log_info "Building frontend first..." "${LOG_FILE}"
        build_frontend || {
            log_error "Failed to build frontend for production" "${LOG_FILE}"
            return 1
        }
    fi
    
    # Start backend
    start_backend || {
        log_error "Failed to start production backend" "${LOG_FILE}"
        return 1
    }
    
    # Start frontend
    start_frontend || {
        log_error "Failed to start production frontend" "${LOG_FILE}"
        # Try to stop backend since we're failing
        stop_backend
        return 1
    }
    
    # Verify services are running
    sleep 5
    if ! check_backend_health "${PROD_BACKEND_PORT}" "${LOG_FILE}" 10 1; then
        log_error "Production backend health check failed" "${LOG_FILE}"
        stop_prod
        return 1
    fi
    
    if ! check_frontend_health "${FRONTEND_PORT}" "${LOG_FILE}" 10 1; then
        log_error "Production frontend not accessible" "${LOG_FILE}"
        stop_prod
        return 1
    fi
    
    log_success "FreeLIMS production environment started successfully" "${LOG_FILE}"
    log_info "Backend running on http://localhost:${PROD_BACKEND_PORT}" "${LOG_FILE}"
    log_info "Frontend running on http://localhost:${FRONTEND_PORT}" "${LOG_FILE}"
    
    return 0
}

# Stop the production environment
stop_prod() {
    log_info "Stopping FreeLIMS production environment..." "${LOG_FILE}"
    
    stop_frontend
    stop_backend
    
    if is_prod_running; then
        log_warning "Some production services are still running. Check with '$0 status'" "${LOG_FILE}"
        return 1
    else
        log_success "FreeLIMS production environment stopped successfully" "${LOG_FILE}"
        return 0
    fi
}

# Restart the production environment
restart_prod() {
    log_info "Restarting FreeLIMS production environment..." "${LOG_FILE}"
    
    stop_prod
    sleep 2
    start_prod
    
    return $?
}

# Show status of production services
show_status() {
    log_info "Checking FreeLIMS production environment status..." "${LOG_FILE}"
    
    echo -e "\n${BLUE}=== FreeLIMS Production Environment Status ===${NC}\n"
    
    # Check backend status
    echo -e "${BLUE}Backend (Port ${PROD_BACKEND_PORT}):${NC}"
    if is_port_in_use "${PROD_BACKEND_PORT}"; then
        BACKEND_PID=$(lsof -t -i:"${PROD_BACKEND_PORT}" 2>/dev/null)
        echo -e "  ${GREEN}✓ Running${NC} (PID: ${BACKEND_PID})"
        
        # Check backend health
        if curl -s "http://localhost:${PROD_BACKEND_PORT}/api/health" | grep -q "healthy"; then
            echo -e "  ${GREEN}✓ Health check passed${NC}"
        else
            echo -e "  ${RED}✗ Health check failed${NC}"
        fi
    else
        echo -e "  ${RED}✗ Not running${NC}"
    fi
    
    # Check frontend status
    echo -e "\n${BLUE}Frontend (Port ${FRONTEND_PORT}):${NC}"
    if is_port_in_use "${FRONTEND_PORT}"; then
        FRONTEND_PID=$(lsof -t -i:"${FRONTEND_PORT}" 2>/dev/null)
        echo -e "  ${GREEN}✓ Running${NC} (PID: ${FRONTEND_PID})"
        
        # Check frontend accessibility
        if curl -s -I "http://localhost:${FRONTEND_PORT}" | grep -q "200 OK\|Content-Type: text/html"; then
            echo -e "  ${GREEN}✓ Accessible${NC}"
        else
            echo -e "  ${RED}✗ Not accessible${NC}"
        fi
    else
        echo -e "  ${RED}✗ Not running${NC}"
    fi
    
    # Check frontend build status
    echo -e "\n${BLUE}Frontend Build:${NC}"
    if [[ -d "${FRONTEND_DIR}/build" ]]; then
        echo -e "  ${GREEN}✓ Built${NC} ($(du -sh "${FRONTEND_DIR}/build" | cut -f1))"
    else
        echo -e "  ${RED}✗ Not built${NC}"
    fi
    
    # Check database status
    echo -e "\n${BLUE}Database:${NC}"
    if check_database "status.log" 2>/dev/null; then
        echo -e "  ${GREEN}✓ Connected${NC}"
    else
        echo -e "  ${RED}✗ Connection failed${NC}"
    fi
    
    echo -e "\n${BLUE}Environment:${NC}"
    echo -e "  Backend logs: ${LOGS_DIR}/backend_prod.log"
    echo -e "  Frontend logs: ${LOGS_DIR}/frontend_prod.log"
    echo -e "  Script logs: ${LOGS_DIR}/${LOG_FILE}"
    echo -e "\n"
    
    return 0
}

# Show production logs
show_logs() {
    echo -e "\n${BLUE}=== FreeLIMS Production Logs ===${NC}\n"
    echo -e "${BLUE}Backend logs (last 20 lines):${NC}"
    tail -n 20 "${LOGS_DIR}/backend_prod.log"
    
    echo -e "\n${BLUE}Frontend logs (last 20 lines):${NC}"
    tail -n 20 "${LOGS_DIR}/frontend_prod.log"
    
    echo -e "\n${BLUE}To follow logs in real-time, use:${NC}"
    echo "  tail -f ${LOGS_DIR}/backend_prod.log"
    echo "  tail -f ${LOGS_DIR}/frontend_prod.log"
    echo -e "\n"
    
    return 0
}

# Deploy production environment 
deploy_prod() {
    log_info "Deploying FreeLIMS production environment..." "${LOG_FILE}"
    
    # Stop current services
    stop_prod
    
    # Build frontend
    build_frontend || {
        log_error "Frontend build failed. Deployment aborted" "${LOG_FILE}"
        return 1
    }
    
    # Start production services
    start_prod || {
        log_error "Failed to start production services. Deployment failed" "${LOG_FILE}"
        return 1
    }
    
    log_success "FreeLIMS production environment deployed successfully" "${LOG_FILE}"
    log_info "Backend running on http://localhost:${PROD_BACKEND_PORT}" "${LOG_FILE}"
    log_info "Frontend running on http://localhost:${FRONTEND_PORT}" "${LOG_FILE}"
    
    return 0
}

# Helper functions

# Check if production environment is running
is_prod_running() {
    is_port_in_use "${PROD_BACKEND_PORT}" || is_port_in_use "${FRONTEND_PORT}"
    return $?
}

# Check prerequisites for production environment
check_prerequisites() {
    # Check Python and virtual environment
    check_venv "${LOG_FILE}" || return 1
    
    # Check backend requirements
    check_python_packages "${BACKEND_DIR}/requirements.txt" "${LOG_FILE}" || return 1
    
    # Check Node.js and npm for building frontend
    check_nodejs "${LOG_FILE}" || return 1
    
    # Check database configuration
    if [[ ! -f "${DB_CONFIG_FILE}" ]]; then
        log_error "Database configuration file not found: ${DB_CONFIG_FILE}" "${LOG_FILE}"
        return 1
    fi
    
    return 0
}

# Start backend server for production
start_backend() {
    log_info "Starting production backend server on port ${PROD_BACKEND_PORT}..." "${LOG_FILE}"
    
    if is_port_in_use "${PROD_BACKEND_PORT}"; then
        log_warning "Port ${PROD_BACKEND_PORT} is already in use" "${LOG_FILE}"
        return 1
    fi
    
    # Activate virtual environment and start backend
    (cd "${BACKEND_DIR}" && \
     source "${VENV_DIR}/bin/activate" && \
     python -m uvicorn app.main:app --host 0.0.0.0 --port "${PROD_BACKEND_PORT}" > "${LOGS_DIR}/backend_prod.log" 2>&1) &
    
    # Wait for backend to start
    sleep 3
    
    if ! is_port_in_use "${PROD_BACKEND_PORT}"; then
        log_error "Failed to start production backend server" "${LOG_FILE}"
        return 1
    fi
    
    log_success "Production backend server started successfully on port ${PROD_BACKEND_PORT}" "${LOG_FILE}"
    return 0
}

# Start frontend server for production
start_frontend() {
    log_info "Starting production frontend server on port ${FRONTEND_PORT}..." "${LOG_FILE}"
    
    if is_port_in_use "${FRONTEND_PORT}"; then
        log_warning "Port ${FRONTEND_PORT} is already in use" "${LOG_FILE}"
        return 1
    fi
    
    if [[ ! -d "${FRONTEND_DIR}/build" ]]; then
        log_error "Frontend build not found. Run '$0 build' first" "${LOG_FILE}"
        return 1
    fi
    
    # Start frontend using serve (needs to be installed globally)
    if ! command -v npx > /dev/null; then
        log_error "npx command not found. Make sure npm is properly installed" "${LOG_FILE}"
        return 1
    fi
    
    (cd "${FRONTEND_DIR}" && \
     npx serve -s build -p "${FRONTEND_PORT}" > "${LOGS_DIR}/frontend_prod.log" 2>&1) &
    
    # Wait for frontend to start
    sleep 3
    
    if ! is_port_in_use "${FRONTEND_PORT}"; then
        log_error "Failed to start production frontend server" "${LOG_FILE}"
        return 1
    fi
    
    log_success "Production frontend server started successfully on port ${FRONTEND_PORT}" "${LOG_FILE}"
    return 0
}

# Stop backend server
stop_backend() {
    log_info "Stopping production backend server..." "${LOG_FILE}"
    
    if ! is_port_in_use "${PROD_BACKEND_PORT}"; then
        log_info "Production backend server is not running" "${LOG_FILE}"
        return 0
    fi
    
    # Find and kill the backend process
    local pid=$(lsof -t -i:"${PROD_BACKEND_PORT}" 2>/dev/null)
    if [[ -n "${pid}" ]]; then
        kill "${pid}" 2>/dev/null || kill -9 "${pid}" 2>/dev/null
        sleep 2
        
        if is_port_in_use "${PROD_BACKEND_PORT}"; then
            log_error "Failed to stop production backend server" "${LOG_FILE}"
            return 1
        fi
    fi
    
    log_success "Production backend server stopped successfully" "${LOG_FILE}"
    return 0
}

# Stop frontend server
stop_frontend() {
    log_info "Stopping production frontend server..." "${LOG_FILE}"
    
    if ! is_port_in_use "${FRONTEND_PORT}"; then
        log_info "Production frontend server is not running" "${LOG_FILE}"
        return 0
    fi
    
    # Find and kill the frontend process
    local pid=$(lsof -t -i:"${FRONTEND_PORT}" 2>/dev/null)
    if [[ -n "${pid}" ]]; then
        kill "${pid}" 2>/dev/null || kill -9 "${pid}" 2>/dev/null
        sleep 2
        
        if is_port_in_use "${FRONTEND_PORT}"; then
            log_error "Failed to stop production frontend server" "${LOG_FILE}"
            return 1
        fi
    fi
    
    log_success "Production frontend server stopped successfully" "${LOG_FILE}"
    return 0
}

# Main function to parse arguments and execute commands
main() {
    # Create log directory if it doesn't exist
    mkdir -p "${LOGS_DIR}"
    
    # Parse command
    local command=$1
    
    case "${command}" in
        start)
            start_prod
            ;;
        stop)
            stop_prod
            ;;
        restart)
            restart_prod
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        build)
            build_frontend
            ;;
        deploy)
            deploy_prod
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            echo "Unknown command: ${command}"
            usage
            ;;
    esac
    
    exit $?
}

# Execute main function with all arguments
main "$@" 