#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Common Utility Functions
# This script provides common utility functions used across all FreeLIMS scripts
# ----------------------------------------------------------------------------

# Ensure scripts exit immediately when a command fails and pipelines return the status of the last command that failed
set -eo pipefail

# Base directory of the project
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load environment variables if .env exists
if [[ -f "${REPO_ROOT}/.env" ]]; then
    source "${REPO_ROOT}/.env"
fi

# Constants
LOGS_DIR="${REPO_ROOT}/logs"
BACKEND_DIR="${REPO_ROOT}/backend"
FRONTEND_DIR="${REPO_ROOT}/frontend"
VENV_DIR="${BACKEND_DIR}/venv"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create logs directory if it doesn't exist
mkdir -p "${LOGS_DIR}"

# ----------------------------------------------------------------------------
# Logging Functions
# ----------------------------------------------------------------------------

# Log a message to the console and log file
# Usage: log_message "message" "log_file" "color"
log_message() {
    local message=$1
    local log_file=$2
    local color=${3:-$NC}
    
    # Print to console with color
    echo -e "${color}${message}${NC}"
    
    # Log to file without color codes
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${message}" >> "${LOGS_DIR}/${log_file}"
}

# Log an info message
# Usage: log_info "message" "log_file"
log_info() {
    log_message "$1" "$2" "${BLUE}"
}

# Log a success message
# Usage: log_success "message" "log_file"
log_success() {
    log_message "$1" "$2" "${GREEN}"
}

# Log a warning message
# Usage: log_warning "message" "log_file"
log_warning() {
    log_message "$1" "$2" "${YELLOW}"
}

# Log an error message
# Usage: log_error "message" "log_file"
log_error() {
    log_message "$1" "$2" "${RED}"
}

# ----------------------------------------------------------------------------
# Error Handling Functions
# ----------------------------------------------------------------------------

# Error handler function
# Usage: trap 'error_handler $? "$BASH_COMMAND" "$_"' ERR
error_handler() {
    local exit_code=$1
    local command=$2
    local func_name=$3
    local log_file=${4:-"script_error.log"}
    
    log_error "Error occurred in ${func_name} (${command}). Exit code: ${exit_code}" "${log_file}"
    exit ${exit_code}
}

# Clean exit function
# Usage: clean_exit "exit_code" "message" "log_file"
clean_exit() {
    local exit_code=${1:-0}
    local message=${2:-"Script completed"}
    local log_file=${3:-"script.log"}
    
    if [[ ${exit_code} -eq 0 ]]; then
        log_success "${message}" "${log_file}"
    else
        log_error "${message}" "${log_file}"
    fi
    
    exit ${exit_code}
}

# ----------------------------------------------------------------------------
# Process Management Functions
# ----------------------------------------------------------------------------

# Check if a process is running
# Usage: is_process_running "process_name"
is_process_running() {
    local process_name=$1
    pgrep -f "${process_name}" > /dev/null
    return $?
}

# Check if a port is in use
# Usage: is_port_in_use "port"
is_port_in_use() {
    local port=$1
    lsof -i:"${port}" > /dev/null 2>&1
    return $?
}

# Kill a process by name
# Usage: kill_process "process_name" "log_file"
kill_process() {
    local process_name=$1
    local log_file=${2:-"process.log"}
    
    if is_process_running "${process_name}"; then
        log_info "Stopping ${process_name}..." "${log_file}"
        pkill -f "${process_name}" > /dev/null 2>&1 || true
        sleep 2
        
        if is_process_running "${process_name}"; then
            log_warning "Failed to stop ${process_name} gracefully, using SIGKILL..." "${log_file}"
            pkill -9 -f "${process_name}" > /dev/null 2>&1 || true
            sleep 1
            
            if is_process_running "${process_name}"; then
                log_error "Failed to stop ${process_name}!" "${log_file}"
                return 1
            fi
        fi
        
        log_success "${process_name} stopped successfully" "${log_file}"
    else
        log_info "${process_name} is not running" "${log_file}"
    fi
    
    return 0
}

# ----------------------------------------------------------------------------
# Environment Management Functions
# ----------------------------------------------------------------------------

# Check if Python virtual environment exists and is activated
# Usage: check_venv "log_file"
check_venv() {
    local log_file=${1:-"venv.log"}
    
    if [[ ! -d "${VENV_DIR}" ]]; then
        log_error "Python virtual environment not found at ${VENV_DIR}" "${log_file}"
        log_info "Creating virtual environment..." "${log_file}"
        
        python3 -m venv "${VENV_DIR}" || {
            log_error "Failed to create virtual environment" "${log_file}"
            return 1
        }
    fi
    
    if [[ -z "${VIRTUAL_ENV}" ]]; then
        source "${VENV_DIR}/bin/activate" || {
            log_error "Failed to activate virtual environment" "${log_file}"
            return 1
        }
        log_info "Virtual environment activated" "${log_file}"
    fi
    
    return 0
}

# Check if required Python packages are installed
# Usage: check_python_packages "requirements_file" "log_file"
check_python_packages() {
    local requirements_file=$1
    local log_file=${2:-"packages.log"}
    
    if [[ ! -f "${requirements_file}" ]]; then
        log_error "Requirements file not found: ${requirements_file}" "${log_file}"
        return 1
    fi
    
    check_venv "${log_file}" || return 1
    
    log_info "Checking Python packages..." "${log_file}"
    pip install -r "${requirements_file}" || {
        log_error "Failed to install Python packages" "${log_file}"
        return 1
    }
    
    log_success "Python packages installed/updated successfully" "${log_file}"
    return 0
}

# Check if Node.js is installed
# Usage: check_nodejs "log_file"
check_nodejs() {
    local log_file=${1:-"nodejs.log"}
    
    if ! command -v node > /dev/null; then
        log_error "Node.js is not installed" "${log_file}"
        return 1
    fi
    
    if ! command -v npm > /dev/null; then
        log_error "npm is not installed" "${log_file}"
        return 1
    fi
    
    log_info "Node.js version: $(node -v), npm version: $(npm -v)" "${log_file}"
    return 0
}

# Check if npm packages are installed
# Usage: check_npm_packages "log_file"
check_npm_packages() {
    local log_file=${1:-"npm.log"}
    
    check_nodejs "${log_file}" || return 1
    
    if [[ ! -d "${FRONTEND_DIR}/node_modules" ]]; then
        log_info "Installing npm packages..." "${log_file}"
        (cd "${FRONTEND_DIR}" && npm install) || {
            log_error "Failed to install npm packages" "${log_file}"
            return 1
        }
    fi
    
    log_success "npm packages installed successfully" "${log_file}"
    return 0
}

# ----------------------------------------------------------------------------
# Database Functions
# ----------------------------------------------------------------------------

# Check database connection
# Usage: check_database "log_file"
check_database() {
    local log_file=${1:-"database.log"}
    
    log_info "Checking database connection..." "${log_file}"
    
    # This assumes the backend has a check_db_connection.py script
    check_venv "${log_file}" || return 1
    
    if [[ -f "${BACKEND_DIR}/app/utils/check_db_connection.py" ]]; then
        (cd "${BACKEND_DIR}" && python -m app.utils.check_db_connection) || {
            log_error "Database connection failed" "${log_file}"
            return 1
        }
    else
        log_warning "Database connection check script not found" "${log_file}"
        return 1
    fi
    
    log_success "Database connection successful" "${log_file}"
    return 0
}

# ----------------------------------------------------------------------------
# Health Check Functions
# ----------------------------------------------------------------------------

# Check if backend is healthy
# Usage: check_backend_health "port" "log_file"
check_backend_health() {
    local port=${1:-8000}
    local log_file=${2:-"health.log"}
    local max_attempts=${3:-30}
    local retry_interval=${4:-2}
    
    log_info "Checking backend health on port ${port}..." "${log_file}"
    
    local attempt=1
    while ((attempt <= max_attempts)); do
        if curl -s "http://localhost:${port}/api/health" | grep -q "healthy"; then
            log_success "Backend health check passed on port ${port}" "${log_file}"
            return 0
        fi
        
        log_info "Backend not ready yet (attempt ${attempt}/${max_attempts}). Waiting..." "${log_file}"
        sleep ${retry_interval}
        ((attempt++))
    done
    
    log_error "Backend health check failed after ${max_attempts} attempts on port ${port}" "${log_file}"
    return 1
}

# Check if frontend is accessible
# Usage: check_frontend_health "port" "log_file"
check_frontend_health() {
    local port=${1:-3000}
    local log_file=${2:-"health.log"}
    local max_attempts=${3:-30}
    local retry_interval=${4:-2}
    
    log_info "Checking frontend health on port ${port}..." "${log_file}"
    
    local attempt=1
    while ((attempt <= max_attempts)); do
        if curl -s -I "http://localhost:${port}" | grep -q "200 OK\|Content-Type: text/html"; then
            log_success "Frontend health check passed on port ${port}" "${log_file}"
            return 0
        fi
        
        log_info "Frontend not ready yet (attempt ${attempt}/${max_attempts}). Waiting..." "${log_file}"
        sleep ${retry_interval}
        ((attempt++))
    done
    
    log_error "Frontend health check failed after ${max_attempts} attempts on port ${port}" "${log_file}"
    return 1
} 