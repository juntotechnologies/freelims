#!/bin/bash

# ============================================================================
# FreeLIMS Utility Functions
# Common utility functions used across FreeLIMS scripts
# ============================================================================

# Set strict mode
set -eo pipefail

# ============================================================================
# Environment and Path Variables
# ============================================================================

# Repository root path
if [[ -z "${REPO_ROOT}" ]]; then
    REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

# Other important paths
BACKEND_DIR="${REPO_ROOT}/backend"
FRONTEND_DIR="${REPO_ROOT}/frontend"
LOGS_DIR="${REPO_ROOT}/logs"
BACKUPS_DIR="${REPO_ROOT}/backups"
CONFIG_DIR="${REPO_ROOT}/config"

# Ensure directories exist
mkdir -p "${LOGS_DIR}" "${BACKUPS_DIR}" "${CONFIG_DIR}"

# ============================================================================
# Terminal Colors and Formatting
# ============================================================================

# Define colors if terminal supports it
if [[ -t 1 ]]; then
    RED="\033[1;31m"
    GREEN="\033[1;32m"
    YELLOW="\033[1;33m"
    BLUE="\033[1;34m"
    PURPLE="\033[1;35m"
    CYAN="\033[1;36m"
    WHITE="\033[1;37m"
    GRAY="\033[0;37m"
    NC="\033[0m" # No Color
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    PURPLE=""
    CYAN=""
    WHITE=""
    GRAY=""
    NC=""
fi

# ============================================================================
# Logging Functions
# ============================================================================

# Log a message to console and/or log file
# Usage: log_message [level] [message] [log_file]
log_message() {
    local level="$1"
    local message="$2"
    local log_file="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Format based on level
    case "${level}" in
        "DEBUG")   local color="${GRAY}" ;;
        "INFO")    local color="${BLUE}" ;;
        "SUCCESS") local color="${GREEN}" ;;
        "WARNING") local color="${YELLOW}" ;;
        "ERROR")   local color="${RED}" ;;
        *)         local color="${WHITE}" ;;
    esac
    
    # Print to console with color
    echo -e "${color}[${level}]${NC} ${message}"
    
    # Log to file if specified
    if [[ -n "${log_file}" ]]; then
        echo "${timestamp} [${level}] ${message}" >> "${log_file}"
    fi
}

# Shorthand logging functions
log_debug() {
    local message="$1"
    local log_file="$2"
    log_message "DEBUG" "${message}" "${log_file}"
}

log_info() {
    local message="$1"
    local log_file="$2"
    log_message "INFO" "${message}" "${log_file}"
}

log_success() {
    local message="$1"
    local log_file="$2"
    log_message "SUCCESS" "${message}" "${log_file}"
}

log_warning() {
    local message="$1"
    local log_file="$2"
    log_message "WARNING" "${message}" "${log_file}"
}

log_error() {
    local message="$1"
    local log_file="$2"
    log_message "ERROR" "${message}" "${log_file}"
}

# ============================================================================
# Command Execution and Status Functions
# ============================================================================

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a port is in use
is_port_in_use() {
    local port="$1"
    if command_exists lsof; then
        lsof -i:"${port}" >/dev/null 2>&1
        return $?
    elif command_exists netstat; then
        netstat -tuln | grep -q ":${port} "
        return $?
    elif command_exists ss; then
        ss -tuln | grep -q ":${port} "
        return $?
    else
        log_warning "No command found to check port usage"
        return 1
    fi
}

# Get process ID using a specific port
get_pid_for_port() {
    local port="$1"
    if command_exists lsof; then
        lsof -t -i:"${port}" 2>/dev/null
    elif command_exists netstat && command_exists grep && command_exists awk; then
        netstat -tuln | grep ":${port} " | awk '{print $7}' | cut -d'/' -f1
    else
        log_warning "No command found to get PID for port"
        return 1
    fi
}

# Kill process using a specific port with user confirmation
kill_process_on_port() {
    local port="$1"
    local pid=$(get_pid_for_port "${port}")
    
    if [[ -n "${pid}" ]]; then
        log_info "Process with PID ${pid} found using port ${port}"
        
        # Ask for confirmation with Y/n prompt
        read -p "Do you want to kill the process on port ${port}? (Y/n): " response
        response=${response:-Y}  # Default to Y if enter is pressed
        
        if [[ "${response}" =~ ^[Yy]$ ]]; then
            log_info "Terminating process with PID ${pid} on port ${port}"
            kill "${pid}" 2>/dev/null || kill -9 "${pid}" 2>/dev/null
            return $?
        else
            log_warning "User chose not to kill process on port ${port}"
            return 2  # Special return code for user rejection
        fi
    else
        log_warning "No process found on port ${port}"
        return 1
    fi
}

# Check if PostgreSQL server is running
check_postgres_running() {
    if command_exists pg_isready; then
        pg_isready >/dev/null 2>&1
        return $?
    fi
    
    # Alternative check
    if command_exists psql; then
        psql -h localhost -U postgres -c "SELECT 1" postgres >/dev/null 2>&1
        return $?
    fi
    
    log_error "PostgreSQL client utilities not found"
    return 1
}

# Check backend health at the specified URL
check_backend_health() {
    local port="${1:-8001}"
    local log_file="$2"
    local retry="${3:-0}"
    local delay="${4:-2}"
    
    log_info "Checking backend health on port ${port}..." "${log_file}"
    
    # Check with retry
    local attempt=1
    local url="http://localhost:${port}/api/health"
    
    while [[ ${attempt} -le ${retry} || ${retry} -eq 0 ]]; do
        if curl -s "${url}" | grep -q "healthy"; then
            log_success "Backend health check passed" "${log_file}"
            return 0
        fi
        
        if [[ ${retry} -ne 0 ]]; then
            log_info "Attempt ${attempt}/${retry} failed, retrying in ${delay} seconds..." "${log_file}"
            sleep ${delay}
            ((attempt++))
        else
            # No retry specified, just fail immediately
            break
        fi
    done
    
    log_error "Backend health check failed" "${log_file}"
    return 1
}

# Check frontend accessibility
check_frontend_health() {
    local port="${1:-3001}"
    local log_file="$2"
    local retry="${3:-0}"
    local delay="${4:-2}"
    
    log_info "Checking frontend accessibility on port ${port}..." "${log_file}"
    
    # Check with retry
    local attempt=1
    local url="http://localhost:${port}"
    
    while [[ ${attempt} -le ${retry} || ${retry} -eq 0 ]]; do
        if curl -s -I "${url}" | grep -q "200 OK\|Content-Type: text/html"; then
            log_success "Frontend accessibility check passed" "${log_file}"
            return 0
        fi
        
        if [[ ${retry} -ne 0 ]]; then
            log_info "Attempt ${attempt}/${retry} failed, retrying in ${delay} seconds..." "${log_file}"
            sleep ${delay}
            ((attempt++))
        else
            # No retry specified, just fail immediately
            break
        fi
    done
    
    log_error "Frontend accessibility check failed" "${log_file}"
    return 1
}

# ============================================================================
# Environment and Dependency Functions
# ============================================================================

# Check if virtual environment exists and activate if needed
check_venv() {
    local log_file="$1"
    
    log_info "Checking virtual environment..." "${log_file}"
    
    if [[ ! -d "${BACKEND_DIR}/venv" ]]; then
        log_error "Virtual environment not found at ${BACKEND_DIR}/venv" "${log_file}"
        log_info "Run setup script first to create the environment" "${log_file}"
        return 1
    fi
    
    # Check if already activated
    if [[ -n "${VIRTUAL_ENV}" ]]; then
        log_info "Virtual environment is already activated: ${VIRTUAL_ENV}" "${log_file}"
        return 0
    fi
    
    # Not needed because we'll use the venv from subshells
    log_success "Virtual environment exists" "${log_file}"
    return 0
}

# Check Python version
check_python_version() {
    local log_file="$1"
    local min_version="${2:-3.8}"
    
    log_info "Checking Python version..." "${log_file}"
    
    if ! command_exists python3; then
        log_error "Python 3 not found" "${log_file}"
        return 1
    fi
    
    local python_version=$(python3 --version | cut -d' ' -f2)
    log_info "Found Python version: ${python_version}" "${log_file}"
    
    # Compare versions (simple method)
    if [[ "${python_version}" < "${min_version}" ]]; then
        log_error "Python version ${python_version} is less than required ${min_version}" "${log_file}"
        return 1
    fi
    
    log_success "Python version check passed" "${log_file}"
    return 0
}

# Check Node.js and npm
check_nodejs() {
    local log_file="$1"
    local min_version="${2:-14.0.0}"
    
    log_info "Checking Node.js installation..." "${log_file}"
    
    if ! command_exists node; then
        log_error "Node.js not found" "${log_file}"
        log_info "Please install Node.js from https://nodejs.org/" "${log_file}"
        return 1
    fi
    
    if ! command_exists npm; then
        log_error "npm not found" "${log_file}"
        log_info "Please check your Node.js installation" "${log_file}"
        return 1
    fi
    
    local node_version=$(node --version | cut -c2-)
    log_info "Found Node.js version: ${node_version}" "${log_file}"
    
    # Simple version check (not comprehensive but works for most cases)
    if [[ "${node_version}" < "${min_version}" ]]; then
        log_warning "Node.js version ${node_version} may be outdated (recommended: ${min_version}+)" "${log_file}"
    fi
    
    log_success "Node.js check passed" "${log_file}"
    return 0
}

# Check if Python packages are installed
check_python_packages() {
    local requirements_file="$1"
    local log_file="$2"
    
    log_info "Checking Python dependencies..." "${log_file}"
    
    if [[ ! -f "${requirements_file}" ]]; then
        log_error "Requirements file not found: ${requirements_file}" "${log_file}"
        return 1
    fi
    
    # Check if pip exists
    if ! command_exists pip; then
        log_error "pip not found" "${log_file}"
        return 1
    fi
    
    # This is a simple check, not comprehensive
    log_info "Requirements file found, assuming dependencies are installed" "${log_file}"
    log_success "Python dependencies check passed" "${log_file}"
    return 0
}

# Check npm packages
check_npm_packages() {
    local log_file="$1"
    
    log_info "Checking npm dependencies..." "${log_file}"
    
    if [[ ! -f "${FRONTEND_DIR}/package.json" ]]; then
        log_error "package.json not found in frontend directory" "${log_file}"
        return 1
    fi
    
    if [[ ! -d "${FRONTEND_DIR}/node_modules" ]]; then
        log_warning "node_modules directory not found, dependencies may not be installed" "${log_file}"
        log_info "Run 'npm install' in the frontend directory" "${log_file}"
        return 1
    fi
    
    log_success "npm dependencies check passed" "${log_file}"
    return 0
}

# ============================================================================
# Database Functions
# ============================================================================

# Check database connection
check_database() {
    local log_file="$1"
    
    log_info "Checking database connection..." "${log_file}"
    
    # Load database configuration if available
    source_env_file "${BACKEND_DIR}/.env" "${log_file}"
    
    # Default values if not set by .env
    DB_HOST=${DB_HOST:-"localhost"}
    DB_PORT=${DB_PORT:-"5432"}
    DB_NAME=${DB_NAME:-"freelims_dev"}
    DB_USER=${DB_USER:-"postgres"}
    
    if ! command_exists psql; then
        log_error "PostgreSQL client tools not found" "${log_file}"
        return 1
    fi
    
    # Check basic connection to PostgreSQL
    if ! pg_isready -h "${DB_HOST}" -p "${DB_PORT}" >/dev/null 2>&1; then
        log_error "PostgreSQL server is not running or not accessible" "${log_file}"
        return 1
    fi
    
    # Try to connect to the database
    if ! PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -c "SELECT 1" >/dev/null 2>&1; then
        log_error "Could not connect to database ${DB_NAME}" "${log_file}"
        return 1
    fi
    
    log_success "Database connection successful" "${log_file}"
    return 0
}

# ============================================================================
# Utility File Functions
# ============================================================================

# Source environment file safely
source_env_file() {
    local env_file="$1"
    local log_file="$2"
    
    if [[ ! -f "${env_file}" ]]; then
        log_warning "Environment file not found: ${env_file}" "${log_file}"
        return 1
    fi
    
    log_info "Loading environment from ${env_file}" "${log_file}"
    
    # Extract environment variables
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "${line}" =~ ^[[:space:]]*$ || "${line}" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Extract key-value pairs
        if [[ "${line}" =~ ^([^=]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Remove quotes if present
            value="${value%\"}"
            value="${value#\"}"
            value="${value%\'}"
            value="${value#\'}"
            
            # Set the environment variable
            export "${key}=${value}"
        fi
    done < "${env_file}"
    
    log_success "Environment loaded successfully" "${log_file}"
    return 0
} 