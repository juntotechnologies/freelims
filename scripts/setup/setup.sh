#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Setup Script
# This script sets up the FreeLIMS application on a new system
# ----------------------------------------------------------------------------

# Source the utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../common/utils.sh"

# Main log file for this script
LOG_FILE="setup.log"

# Print usage information
usage() {
    echo "FreeLIMS Setup Script"
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --skip-checks  Skip dependency checks"
    echo ""
    exit 0
}

# Check dependencies
check_dependencies() {
    log_info "Checking for required dependencies..." "${LOG_FILE}"
    
    # Check for Python
    if command -v python3 &>/dev/null; then
        python_version=$(python3 --version | cut -d " " -f 2)
        log_success "Python ${python_version} is installed" "${LOG_FILE}"
    else
        log_error "Python 3 is not installed. Please install Python 3.8 or later." "${LOG_FILE}"
        return 1
    fi
    
    # Check for Node.js
    if command -v node &>/dev/null; then
        node_version=$(node --version)
        log_success "Node.js ${node_version} is installed" "${LOG_FILE}"
    else
        log_error "Node.js is not installed. Please install Node.js 16 or later." "${LOG_FILE}"
        return 1
    fi
    
    # Check for PostgreSQL
    if command -v psql &>/dev/null; then
        psql_version=$(psql --version | cut -d " " -f 3)
        log_success "PostgreSQL ${psql_version} is installed" "${LOG_FILE}"
    else
        log_warning "PostgreSQL is not installed. Some features may not work correctly." "${LOG_FILE}"
    fi
    
    return 0
}

# Set up backend
setup_backend() {
    log_info "Setting up backend..." "${LOG_FILE}"
    
    # Create and activate virtual environment if it doesn't exist
    if [[ ! -d "${BACKEND_DIR}/venv" ]]; then
        log_info "Creating Python virtual environment..." "${LOG_FILE}"
        cd "${BACKEND_DIR}" || return 1
        python3 -m venv venv || {
            log_error "Failed to create virtual environment" "${LOG_FILE}"
            return 1
        }
    fi
    
    # Activate virtual environment
    source "${BACKEND_DIR}/venv/bin/activate" || {
        log_error "Failed to activate virtual environment" "${LOG_FILE}"
        return 1
    }
    
    # Install dependencies
    log_info "Installing backend dependencies..." "${LOG_FILE}"
    pip install --upgrade pip || {
        log_error "Failed to upgrade pip" "${LOG_FILE}"
        return 1
    }
    
    pip install -r "${BACKEND_DIR}/requirements.txt" || {
        log_error "Failed to install backend dependencies" "${LOG_FILE}"
        return 1
    }
    
    # Create .env file if it doesn't exist
    if [[ ! -f "${BACKEND_DIR}/.env" ]]; then
        log_info "Creating .env file from template..." "${LOG_FILE}"
        if [[ -f "${BACKEND_DIR}/.env.example" ]]; then
            cp "${BACKEND_DIR}/.env.example" "${BACKEND_DIR}/.env" || {
                log_error "Failed to create .env file" "${LOG_FILE}"
                return 1
            }
            log_warning "Please edit ${BACKEND_DIR}/.env with your configuration" "${LOG_FILE}"
        else
            log_error "No .env.example file found" "${LOG_FILE}"
            return 1
        fi
    fi
    
    # Deactivate virtual environment
    deactivate
    
    log_success "Backend setup completed" "${LOG_FILE}"
    return 0
}

# Set up frontend
setup_frontend() {
    log_info "Setting up frontend..." "${LOG_FILE}"
    
    # Install dependencies
    cd "${FRONTEND_DIR}" || return 1
    
    log_info "Installing frontend dependencies..." "${LOG_FILE}"
    npm install || {
        log_error "Failed to install frontend dependencies" "${LOG_FILE}"
        return 1
    }
    
    # Create .env.local file if it doesn't exist
    if [[ ! -f "${FRONTEND_DIR}/.env.local" ]]; then
        log_info "Creating .env.local file..." "${LOG_FILE}"
        if [[ -f "${FRONTEND_DIR}/.env.example" ]]; then
            cp "${FRONTEND_DIR}/.env.example" "${FRONTEND_DIR}/.env.local" || {
                log_error "Failed to create .env.local file" "${LOG_FILE}"
                return 1
            }
            log_warning "Please edit ${FRONTEND_DIR}/.env.local with your configuration" "${LOG_FILE}"
        else
            echo "REACT_APP_API_URL=http://localhost:8000/api" > "${FRONTEND_DIR}/.env.local" || {
                log_error "Failed to create .env.local file" "${LOG_FILE}"
                return 1
            }
        fi
    fi
    
    log_success "Frontend setup completed" "${LOG_FILE}"
    return 0
}

# Set up database directories
setup_db_directories() {
    log_info "Setting up database directories..." "${LOG_FILE}"
    
    # Read DB_SCHEMA_PATH from .env file
    local db_schema_path=""
    if [[ -f "${BACKEND_DIR}/.env" ]]; then
        db_schema_path=$(grep -E "^DB_SCHEMA_PATH=" "${BACKEND_DIR}/.env" | cut -d '=' -f 2)
    fi
    
    # If DB_SCHEMA_PATH is defined, create the directory
    if [[ -n "${db_schema_path}" ]]; then
        log_info "Creating database directory: ${db_schema_path}" "${LOG_FILE}"
        mkdir -p "${db_schema_path}" || {
            log_error "Failed to create database directory" "${LOG_FILE}"
            return 1
        }
        
        # Try to set permissions (this might fail if running without sufficient privileges)
        chmod 777 "${db_schema_path}" 2>/dev/null || {
            log_warning "Could not set permissions on database directory. You may need to adjust them manually." "${LOG_FILE}"
        }
    else
        log_warning "DB_SCHEMA_PATH not defined in .env file" "${LOG_FILE}"
    fi
    
    log_success "Database directories setup completed" "${LOG_FILE}"
    return 0
}

# Main function
main() {
    # Create log directory if it doesn't exist
    mkdir -p "${LOGS_DIR}"
    
    # Parse arguments
    local skip_checks=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                usage
                ;;
            --skip-checks)
                skip_checks=true
                shift
                ;;
            *)
                log_error "Unknown option: $1" "${LOG_FILE}"
                usage
                ;;
        esac
    done
    
    log_info "Starting FreeLIMS setup..." "${LOG_FILE}"
    
    # Make scripts executable
    log_info "Making scripts executable..." "${LOG_FILE}"
    find "${SCRIPTS_DIR}" -name "*.sh" -exec chmod +x {} \;
    
    # Check dependencies
    if [[ "${skip_checks}" != "true" ]]; then
        check_dependencies || {
            log_error "Dependency check failed" "${LOG_FILE}"
            exit 1
        }
    fi
    
    # Setup components
    setup_backend || exit 1
    setup_frontend || exit 1
    setup_db_directories || exit 1
    
    log_success "FreeLIMS setup completed successfully!" "${LOG_FILE}"
    echo ""
    echo "To start the development environment, run:"
    echo "  ${REPO_ROOT}/scripts/freelims.sh dev start"
    echo ""
    
    return 0
}

# Execute main function
main "$@" 