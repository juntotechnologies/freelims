#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Development Environment Management Script
# This script provides commands to manage the FreeLIMS development environment
# ----------------------------------------------------------------------------

# Source the utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../common/utils.sh"

# Main log file for this script
LOG_FILE="dev_environment.log"

# Configuration
BACKEND_PORT=8000
FRONTEND_PORT=3001
DB_CONFIG_FILE="${BACKEND_DIR}/app/database.py"

# Print usage information
usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start        Start the development environment"
    echo "  stop         Stop the development environment"
    echo "  restart      Restart the development environment"
    echo "  status       Show the status of development services"
    echo "  clean        Clean the development environment (remove temporary files, caches, etc.)"
    echo "  logs         Show development logs"
    echo "  fix          Fix common development environment issues"
    echo "  help         Show this help message"
    echo ""
    exit 0
}

# Start the development environment
start_dev() {
    log_info "Starting FreeLIMS development environment..." "${LOG_FILE}"
    
    # Check prerequisites
    check_prerequisites || {
        log_error "Failed to meet prerequisites for development environment" "${LOG_FILE}"
        return 1
    }
    
    # Check if already running
    if is_dev_running; then
        log_warning "Development environment is already running" "${LOG_FILE}"
        log_info "Use '$0 restart' to restart or '$0 stop' to stop first" "${LOG_FILE}"
        return 0
    fi
    
    # Start backend
    start_backend || {
        log_error "Failed to start backend" "${LOG_FILE}"
        return 1
    }
    
    # Start frontend
    start_frontend || {
        log_error "Failed to start frontend" "${LOG_FILE}"
        # Try to stop backend since we're failing
        stop_backend
        return 1
    }
    
    # Verify services are running
    sleep 5
    if ! check_backend_health "${BACKEND_PORT}" "${LOG_FILE}" 10 1; then
        log_error "Backend health check failed" "${LOG_FILE}"
        stop_dev
        return 1
    fi
    
    if ! check_frontend_health "${FRONTEND_PORT}" "${LOG_FILE}" 10 1; then
        log_error "Frontend not accessible" "${LOG_FILE}"
        stop_dev
        return 1
    fi
    
    log_success "FreeLIMS development environment started successfully" "${LOG_FILE}"
    log_info "Backend running on http://localhost:${BACKEND_PORT}" "${LOG_FILE}"
    log_info "Frontend running on http://localhost:${FRONTEND_PORT}" "${LOG_FILE}"
    
    return 0
}

# Stop the development environment
stop_dev() {
    log_info "Stopping FreeLIMS development environment..." "${LOG_FILE}"
    
    stop_frontend
    stop_backend
    
    if is_dev_running; then
        log_warning "Some services are still running. Check with '$0 status'" "${LOG_FILE}"
        return 1
    else
        log_success "FreeLIMS development environment stopped successfully" "${LOG_FILE}"
        return 0
    fi
}

# Restart the development environment
restart_dev() {
    log_info "Restarting FreeLIMS development environment..." "${LOG_FILE}"
    
    stop_dev
    sleep 2
    start_dev
    
    return $?
}

# Show status of development services
show_status() {
    log_info "Checking FreeLIMS development environment status..." "${LOG_FILE}"
    
    echo -e "\n${BLUE}=== FreeLIMS Development Environment Status ===${NC}\n"
    
    # Check backend status
    echo -e "${BLUE}Backend (Port ${BACKEND_PORT}):${NC}"
    if is_port_in_use "${BACKEND_PORT}"; then
        BACKEND_PID=$(lsof -t -i:"${BACKEND_PORT}" 2>/dev/null)
        echo -e "  ${GREEN}✓ Running${NC} (PID: ${BACKEND_PID})"
        
        # Check backend health
        if curl -s "http://localhost:${BACKEND_PORT}/api/health" | grep -q "healthy"; then
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
    
    # Check database status
    echo -e "\n${BLUE}Database:${NC}"
    if check_database "status.log" 2>/dev/null; then
        echo -e "  ${GREEN}✓ Connected${NC}"
    else
        echo -e "  ${RED}✗ Connection failed${NC}"
    fi
    
    echo -e "\n${BLUE}Environment:${NC}"
    echo -e "  Backend logs: ${LOGS_DIR}/backend_dev.log"
    echo -e "  Frontend logs: ${LOGS_DIR}/frontend_dev.log"
    echo -e "  Script logs: ${LOGS_DIR}/${LOG_FILE}"
    echo -e "\n"
    
    return 0
}

# Clean the development environment
clean_dev() {
    log_info "Cleaning FreeLIMS development environment..." "${LOG_FILE}"
    
    # Stop services first
    stop_dev
    
    # Clean frontend build artifacts and caches
    log_info "Cleaning frontend build artifacts and caches..." "${LOG_FILE}"
    (cd "${FRONTEND_DIR}" && rm -rf build node_modules/.cache) || {
        log_warning "Failed to clean some frontend artifacts" "${LOG_FILE}"
    }
    
    # Clean backend __pycache__ directories
    log_info "Cleaning Python cache files..." "${LOG_FILE}"
    find "${BACKEND_DIR}" -type d -name "__pycache__" -exec rm -rf {} +
    find "${BACKEND_DIR}" -type f -name "*.pyc" -delete
    
    # Clean logs
    log_info "Cleaning old log files..." "${LOG_FILE}"
    find "${LOGS_DIR}" -type f -name "*_dev.log" -mtime +7 -delete
    
    log_success "Development environment cleaned successfully" "${LOG_FILE}"
    return 0
}

# Show development logs
show_logs() {
    echo -e "\n${BLUE}=== FreeLIMS Development Logs ===${NC}\n"
    echo -e "${BLUE}Backend logs (last 20 lines):${NC}"
    tail -n 20 "${LOGS_DIR}/backend_dev.log"
    
    echo -e "\n${BLUE}Frontend logs (last 20 lines):${NC}"
    tail -n 20 "${LOGS_DIR}/frontend_dev.log"
    
    echo -e "\n${BLUE}To follow logs in real-time, use:${NC}"
    echo "  tail -f ${LOGS_DIR}/backend_dev.log"
    echo "  tail -f ${LOGS_DIR}/frontend_dev.log"
    echo -e "\n"
    
    return 0
}

# Fix common development environment issues
fix_dev_environment() {
    log_info "Attempting to fix FreeLIMS development environment issues..." "${LOG_FILE}"
    
    # Stop services first
    stop_dev
    
    # Clean environment
    clean_dev
    
    # Check if .env.local exists in frontend, if not create it
    if [[ ! -f "${FRONTEND_DIR}/.env.local" ]]; then
        log_info "Creating frontend .env.local with correct API URL..." "${LOG_FILE}"
        echo "REACT_APP_API_URL=http://localhost:${BACKEND_PORT}/api" > "${FRONTEND_DIR}/.env.local"
    else
        # Update API URL in .env.local
        log_info "Updating API URL in frontend .env.local..." "${LOG_FILE}"
        grep -q "REACT_APP_API_URL" "${FRONTEND_DIR}/.env.local" && \
        sed -i.bak "s|REACT_APP_API_URL=.*|REACT_APP_API_URL=http://localhost:${BACKEND_PORT}/api|g" "${FRONTEND_DIR}/.env.local" || \
        echo "REACT_APP_API_URL=http://localhost:${BACKEND_PORT}/api" >> "${FRONTEND_DIR}/.env.local"
    fi
    
    # Check package.json proxy setting
    log_info "Checking frontend package.json proxy setting..." "${LOG_FILE}"
    if grep -q '"proxy":' "${FRONTEND_DIR}/package.json"; then
        sed -i.bak "s|\"proxy\": \".*\"|\"proxy\": \"http://localhost:${BACKEND_PORT}\"|g" "${FRONTEND_DIR}/package.json"
    else
        log_warning "No proxy setting found in package.json" "${LOG_FILE}"
    fi
    
    # Clear browser caches (can't do directly, but inform user)
    log_info "It's recommended to clear your browser cache for the frontend site" "${LOG_FILE}"
    
    # Install dependencies
    log_info "Installing/updating dependencies..." "${LOG_FILE}"
    check_python_packages "${BACKEND_DIR}/requirements.txt" "${LOG_FILE}"
    check_npm_packages "${LOG_FILE}"
    
    # Start services again
    start_dev
    
    log_success "Development environment fix completed" "${LOG_FILE}"
    log_info "If issues persist, please check logs for more details" "${LOG_FILE}"
    
    return 0
}

# Helper functions

# Check if development environment is running
is_dev_running() {
    is_port_in_use "${BACKEND_PORT}" || is_port_in_use "${FRONTEND_PORT}"
    return $?
}

# Check prerequisites for development environment
check_prerequisites() {
    # Check Python and virtual environment
    check_venv "${LOG_FILE}" || return 1
    
    # Check backend requirements
    check_python_packages "${BACKEND_DIR}/requirements.txt" "${LOG_FILE}" || return 1
    
    # Check Node.js and npm
    check_nodejs "${LOG_FILE}" || return 1
    
    # Check frontend packages
    check_npm_packages "${LOG_FILE}" || return 1
    
    # Check database configuration
    if [[ ! -f "${DB_CONFIG_FILE}" ]]; then
        log_error "Database configuration file not found: ${DB_CONFIG_FILE}" "${LOG_FILE}"
        return 1
    fi
    
    return 0
}

# Start backend server
start_backend() {
    log_info "Starting backend server on port ${BACKEND_PORT}..." "${LOG_FILE}"
    
    if is_port_in_use "${BACKEND_PORT}"; then
        log_warning "Port ${BACKEND_PORT} is already in use" "${LOG_FILE}"
        return 1
    fi
    
    # Activate virtual environment and start backend
    (cd "${BACKEND_DIR}" && \
     source "${VENV_DIR}/bin/activate" && \
     python -m uvicorn app.main:app --reload --host 0.0.0.0 --port "${BACKEND_PORT}" > "${LOGS_DIR}/backend_dev.log" 2>&1) &
    
    # Wait for backend to start
    sleep 3
    
    if ! is_port_in_use "${BACKEND_PORT}"; then
        log_error "Failed to start backend server" "${LOG_FILE}"
        return 1
    fi
    
    log_success "Backend server started successfully on port ${BACKEND_PORT}" "${LOG_FILE}"
    return 0
}

# Start frontend server
start_frontend() {
    log_info "Starting frontend server on port ${FRONTEND_PORT}..." "${LOG_FILE}"
    
    if is_port_in_use "${FRONTEND_PORT}"; then
        log_warning "Port ${FRONTEND_PORT} is already in use" "${LOG_FILE}"
        return 1
    fi
    
    # Start frontend development server
    (cd "${FRONTEND_DIR}" && \
     PORT="${FRONTEND_PORT}" npm start > "${LOGS_DIR}/frontend_dev.log" 2>&1) &
    
    # Wait for frontend to start
    sleep 3
    
    if ! is_port_in_use "${FRONTEND_PORT}"; then
        log_error "Failed to start frontend server" "${LOG_FILE}"
        return 1
    fi
    
    log_success "Frontend server started successfully on port ${FRONTEND_PORT}" "${LOG_FILE}"
    return 0
}

# Stop backend server
stop_backend() {
    log_info "Stopping backend server..." "${LOG_FILE}"
    
    if ! is_port_in_use "${BACKEND_PORT}"; then
        log_info "Backend server is not running" "${LOG_FILE}"
        return 0
    fi
    
    # Find and kill the backend process
    local pid=$(lsof -t -i:"${BACKEND_PORT}" 2>/dev/null)
    if [[ -n "${pid}" ]]; then
        kill "${pid}" 2>/dev/null || kill -9 "${pid}" 2>/dev/null
        sleep 2
        
        if is_port_in_use "${BACKEND_PORT}"; then
            log_error "Failed to stop backend server" "${LOG_FILE}"
            return 1
        fi
    fi
    
    log_success "Backend server stopped successfully" "${LOG_FILE}"
    return 0
}

# Stop frontend server
stop_frontend() {
    log_info "Stopping frontend server..." "${LOG_FILE}"
    
    if ! is_port_in_use "${FRONTEND_PORT}"; then
        log_info "Frontend server is not running" "${LOG_FILE}"
        return 0
    fi
    
    # Find and kill the frontend process
    local pid=$(lsof -t -i:"${FRONTEND_PORT}" 2>/dev/null)
    if [[ -n "${pid}" ]]; then
        kill "${pid}" 2>/dev/null || kill -9 "${pid}" 2>/dev/null
        sleep 2
        
        if is_port_in_use "${FRONTEND_PORT}"; then
            log_error "Failed to stop frontend server" "${LOG_FILE}"
            return 1
        fi
    fi
    
    log_success "Frontend server stopped successfully" "${LOG_FILE}"
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
            start_dev
            ;;
        stop)
            stop_dev
            ;;
        restart)
            restart_dev
            ;;
        status)
            show_status
            ;;
        clean)
            clean_dev
            ;;
        logs)
            show_logs
            ;;
        fix)
            fix_dev_environment
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