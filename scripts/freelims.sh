#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Main Management Script
# This script serves as the entry point for all FreeLIMS operations
# ----------------------------------------------------------------------------

# Source the utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/common/utils.sh"

# Main log file for this script
LOG_FILE="freelims.log"

# Print usage information
usage() {
    echo "FreeLIMS Management Script"
    echo "Usage: $0 [environment] [command]"
    echo ""
    echo "Environments:"
    echo "  dev          Development environment"
    echo "  prod         Production environment"
    echo "  db           Database operations"
    echo "  setup        Setup operations"
    echo "  all          All environments"
    echo ""
    echo "Commands for dev/prod environments:"
    echo "  start        Start the environment"
    echo "  stop         Stop the environment"
    echo "  restart      Restart the environment"
    echo "  status       Show the status of services"
    echo "  logs         Show logs"
    echo "  clean        Clean temporary files (dev only)"
    echo "  fix          Fix common issues (dev only)"
    echo "  build        Build the frontend (prod only)"
    echo "  deploy       Deploy the environment (prod only)"
    echo ""
    echo "Commands for db environment:"
    echo "  backup       Create a database backup"
    echo "  restore      Restore from a database backup"
    echo "  status       Show the database status"
    echo "  migrate      Run database migrations"
    echo "  create       Create a new database"
    echo "  drop         Drop the database"
    echo "  init         Initialize the database with sample data"
    echo ""
    echo "Commands for setup environment:"
    echo "  init         Initialize FreeLIMS (first-time setup)"
    echo "  dev-db       Create and setup the development database"
    echo "  prod-db      Create and setup the production database"
    echo "  deps         Install or update dependencies"
    echo ""
    echo "Commands for all environment:"
    echo "  status       Show status of all services"
    echo "  start        Start all services"
    echo "  stop         Stop all services"
    echo "  restart      Restart all services"
    echo "  start_both   Start both environments with consistent authentication"
    echo ""
    echo "Examples:"
    echo "  $0 dev start       # Start the development environment"
    echo "  $0 prod status     # Show production status"
    echo "  $0 db backup       # Create a database backup"
    echo "  $0 setup init      # Initialize FreeLIMS for first time use"
    echo "  $0 all status      # Show status of all services"
    echo ""
    exit 0
}

# Common functions
source_common_functions() {
    # Import common utility functions
    [ -f "${SCRIPT_DIR}/common/utils.sh" ] && source "${SCRIPT_DIR}/common/utils.sh"
    [ -f "${SCRIPT_DIR}/common/colors.sh" ] && source "${SCRIPT_DIR}/common/colors.sh"
}

# Check if a port is in use
check_port() {
    local port=$1
    if lsof -i:$port -t >/dev/null 2>&1; then
        return 0 # Port is in use
    else
        return 1 # Port is not in use
    fi
}

# Execute a command in the development environment
execute_dev_command() {
    local command=$1
    "${SCRIPT_DIR}/dev/manage.sh" "${command}"
    return $?
}

# Execute a command in the production environment
execute_prod_command() {
    local command=$1
    "${SCRIPT_DIR}/prod/manage.sh" "${command}"
    return $?
}

# Execute a command for database operations
execute_db_command() {
    local command=$1
    shift
    "${SCRIPT_DIR}/db/manage.sh" "${command}" "$@"
    return $?
}

# Execute a command for setup operations
execute_setup_command() {
    local command=$1
    shift
    local exit_code=0
    
    case "${command}" in
        init)
            log_info "Initializing FreeLIMS..." "${LOG_FILE}"
            "${SCRIPT_DIR}/setup/setup.sh" "$@"
            exit_code=$?
            ;;
        dev-db)
            log_info "Setting up development database..." "${LOG_FILE}"
            "${SCRIPT_DIR}/db/setup_dev_db.sh" "$@"
            exit_code=$?
            ;;
        prod-db)
            log_info "Setting up production database..." "${LOG_FILE}"
            # Add production database setup script when available
            log_warning "Production database setup not implemented yet" "${LOG_FILE}"
            exit_code=1
            ;;
        deps)
            log_info "Installing/updating dependencies..." "${LOG_FILE}"
            # Backend dependencies
            log_info "Installing backend dependencies..." "${LOG_FILE}"
            cd "${BACKEND_DIR}" || return 1
            if [[ -d "${BACKEND_DIR}/venv" ]]; then
                source "${BACKEND_DIR}/venv/bin/activate" || return 1
                pip install --upgrade -r requirements.txt
                deactivate
            else
                log_warning "Backend virtual environment not found. Run 'setup init' first." "${LOG_FILE}"
            fi
            
            # Frontend dependencies
            log_info "Installing frontend dependencies..." "${LOG_FILE}"
            cd "${FRONTEND_DIR}" || return 1
            npm install
            exit_code=$?
            ;;
        *)
            log_error "Unknown command for setup environment: ${command}" "${LOG_FILE}"
            usage
            exit_code=1
            ;;
    esac
    
    return ${exit_code}
}

# Execute a command for all environments
execute_all_command() {
    local command=$1
    local exit_code=0
    
    case "${command}" in
        status)
            log_info "Checking status of all FreeLIMS services..." "${LOG_FILE}"
            echo -e "\n${BLUE}=== Development Environment ===${NC}"
            execute_dev_command "status"
            echo -e "\n${BLUE}=== Production Environment ===${NC}"
            execute_prod_command "status"
            ;;
        start)
            log_info "Starting all FreeLIMS services..." "${LOG_FILE}"
            execute_dev_command "start" || exit_code=$?
            execute_prod_command "start" || exit_code=$?
            ;;
        start_both)
            log_info "Starting both environments with consistent authentication..." "${LOG_FILE}"
            echo -e "\n${BLUE}=== Starting Dual Environment ===${NC}"
            
            # Stop any existing environments first
            log_info "Stopping any existing environments..." "${LOG_FILE}"
            echo "Stopping production environment..."
            execute_prod_command "stop" >/dev/null 2>&1 || true
            echo "Stopping development environment..."
            execute_dev_command "stop" >/dev/null 2>&1 || true
            
            # Clean up any remaining processes
            log_info "Cleaning up any remaining processes..." "${LOG_FILE}"
            echo "Cleaning up processes..."
            PORTS=(3000 3001 8000 9000)
            for PORT in "${PORTS[@]}"; do
                if lsof -i:$PORT -t >/dev/null 2>&1; then
                    PID=$(lsof -i:$PORT -t)
                    echo "Killing process $PID on port $PORT"
                    log_info "Killing process $PID on port $PORT" "${LOG_FILE}"
                    kill -9 $PID >/dev/null 2>&1 || true
                fi
            done
            
            # Start production environment directly using the script instead of function calls
            log_info "Starting production environment..." "${LOG_FILE}"
            echo "Starting production environment..."
            bash "${SCRIPT_DIR}/prod/manage.sh" start
            
            # Check if production environment started successfully
            echo "Checking if production environment started successfully..."
            sleep 5  # Give services time to start up
            if check_port 9000 && check_port 3000; then
                log_success "Production environment started successfully" "${LOG_FILE}"
                echo "Production environment started successfully"
            else
                log_error "Production environment failed to start" "${LOG_FILE}"
                echo "Production environment failed to start"
                echo "Port 9000 status: $(check_port 9000; echo $?)"
                echo "Port 3000 status: $(check_port 3000; echo $?)"
                return 1
            fi
            
            # Start development environment directly using the script instead of function calls
            log_info "Starting development environment..." "${LOG_FILE}"
            echo "Starting development environment..."
            bash "${SCRIPT_DIR}/dev/manage.sh" start
            
            # Check if development environment started successfully
            echo "Checking if development environment started successfully..."
            sleep 5  # Give services time to start up
            if check_port 8000 && check_port 3001; then
                log_success "Development environment started successfully" "${LOG_FILE}"
                echo "Development environment started successfully"
            else
                log_error "Development environment failed to start" "${LOG_FILE}"
                echo "Development environment failed to start"
                echo "Port 8000 status: $(check_port 8000; echo $?)"
                echo "Port 3001 status: $(check_port 3001; echo $?)"
                return 1
            fi
            
            # Display success message and access URLs
            echo ""
            echo "======================================"
            echo "🎉 Both environments are now running!"
            echo ""
            echo "📱 Production Environment:"
            echo "- Backend API: http://localhost:9000"
            echo "- Frontend: http://localhost:3000"
            echo ""
            echo "📱 Development Environment:"
            echo "- Backend API: http://localhost:8000"
            echo "- Frontend: http://localhost:3001"
            echo ""
            echo "📋 API Documentation:"
            echo "- Production: http://localhost:9000/docs"
            echo "- Development: http://localhost:8000/docs"
            echo ""
            echo "⚠️ To stop both environments, run:"
            echo "${SCRIPT_DIR}/freelims.sh prod stop && ${SCRIPT_DIR}/freelims.sh dev stop"
            echo "======================================"
            return 0
            ;;
        stop)
            log_info "Stopping all FreeLIMS services..." "${LOG_FILE}"
            execute_dev_command "stop" || exit_code=$?
            execute_prod_command "stop" || exit_code=$?
            ;;
        restart)
            log_info "Restarting all FreeLIMS services..." "${LOG_FILE}"
            execute_dev_command "restart" || exit_code=$?
            execute_prod_command "restart" || exit_code=$?
            ;;
        *)
            log_error "Unknown command for 'all' environment: ${command}" "${LOG_FILE}"
            usage
            exit_code=1
            ;;
    esac
    
    return ${exit_code}
}

# Validate environment and command
validate_env_command() {
    local env=$1
    local command=$2
    
    case "${env}" in
        dev)
            case "${command}" in
                start|stop|restart|status|logs|clean|fix)
                    return 0
                    ;;
                *)
                    log_error "Invalid command for development environment: ${command}" "${LOG_FILE}"
                    usage
                    return 1
                    ;;
            esac
            ;;
        prod)
            case "${command}" in
                start|stop|restart|status|logs|build|deploy)
                    return 0
                    ;;
                *)
                    log_error "Invalid command for production environment: ${command}" "${LOG_FILE}"
                    usage
                    return 1
                    ;;
            esac
            ;;
        db)
            case "${command}" in
                backup|restore|status|migrate|create|drop|init)
                    return 0
                    ;;
                *)
                    log_error "Invalid command for database environment: ${command}" "${LOG_FILE}"
                    usage
                    return 1
                    ;;
            esac
            ;;
        setup)
            case "${command}" in
                init|dev-db|prod-db|deps)
                    return 0
                    ;;
                *)
                    log_error "Invalid command for setup environment: ${command}" "${LOG_FILE}"
                    usage
                    return 1
                    ;;
            esac
            ;;
        all)
            case "${command}" in
                status|start|stop|restart|start_both)
                    return 0
                    ;;
                *)
                    log_error "Invalid command for 'all' environment: ${command}" "${LOG_FILE}"
                    usage
                    return 1
                    ;;
            esac
            ;;
        *)
            log_error "Invalid environment: ${env}" "${LOG_FILE}"
            usage
            return 1
            ;;
    esac
}

# Main function to parse arguments and execute commands
main() {
    # Create log directory if it doesn't exist
    mkdir -p "${LOGS_DIR}"
    
    # Show usage if no arguments provided
    if [[ $# -lt 2 ]]; then
        usage
        exit 1
    fi
    
    # Parse environment and command
    local env=$1
    local command=$2
    shift 2  # Remove first two arguments
    
    # Special case for help
    if [[ "${env}" == "help" || "${env}" == "--help" || "${env}" == "-h" ]]; then
        usage
        exit 0
    fi
    
    # Validate environment and command
    validate_env_command "${env}" "${command}" || exit 1
    
    # Execute the appropriate command based on environment
    case "${env}" in
        dev)
            execute_dev_command "${command}"
            ;;
        prod)
            execute_prod_command "${command}"
            ;;
        db)
            execute_db_command "${command}" "$@"
            ;;
        setup)
            execute_setup_command "${command}" "$@"
            ;;
        all)
            execute_all_command "${command}"
            ;;
    esac
    
    exit $?
}

# Execute main function with all arguments
main "$@" 