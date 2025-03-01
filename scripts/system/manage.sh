#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS System Management Script
# This script handles system operations (start, stop, restart)
# ----------------------------------------------------------------------------

# Source port configuration if not already sourced
if [ "$(type -t get_process_on_port)" != "function" ]; then
    if [ -f "$REPO_ROOT/port_config.sh" ]; then
        source "$REPO_ROOT/port_config.sh"
    fi
fi

# Initialize variables with defaults (use port_config.sh values if available)
DEV_BACKEND_PORT=${DEV_BACKEND_PORT:-8001}
DEV_FRONTEND_PORT=${DEV_FRONTEND_PORT:-3001}
PROD_BACKEND_PORT=${PROD_BACKEND_PORT:-8002}
PROD_FRONTEND_PORT=${PROD_FRONTEND_PORT:-3002}

# Log directory
LOG_DIR="$REPO_ROOT/logs"
mkdir -p "$LOG_DIR"

# Log file for system operations
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
SYSTEM_LOG="$LOG_DIR/system_operations_$TIMESTAMP.log"

# Colors for better visibility
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Log function to record events
log() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "[$timestamp] $message"
    echo "[$timestamp] $message" >> "$SYSTEM_LOG"
}

# Start the development environment
start_dev() {
    log "Starting development environment..."
    
    # Call the specialized run script
    if [ -f "$SCRIPTS_DIR/system/dev/run_dev_env.sh" ]; then
        bash "$SCRIPTS_DIR/system/dev/run_dev_env.sh"
        return $?
    else
        log "Error: Development environment run script not found"
        echo -e "${RED}Error: scripts/system/dev/run_dev_env.sh not found${NC}"
        return 1
    fi
}

# Start the production environment
start_prod() {
    log "Starting production environment..."
    
    # Define paths
    BACKEND_PATH="$REPO_ROOT/backend"
    FRONTEND_PATH="$REPO_ROOT/frontend"
    
    # Check and kill backend processes if needed
    if is_port_in_use $PROD_BACKEND_PORT; then
        log "Port $PROD_BACKEND_PORT is already in use."
        get_process_on_port $PROD_BACKEND_PORT
        read -p "Do you want to terminate these processes and continue? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy] ]]; then
            log "Operation cancelled. Exiting..."
            return 1
        fi
        safe_kill_process_on_port $PROD_BACKEND_PORT "yes"
    fi
    
    # Check and kill frontend processes if needed
    if is_port_in_use $PROD_FRONTEND_PORT; then
        log "Port $PROD_FRONTEND_PORT is already in use."
        get_process_on_port $PROD_FRONTEND_PORT
        read -p "Do you want to terminate these processes and continue? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy] ]]; then
            log "Operation cancelled. Exiting..."
            return 1
        fi
        safe_kill_process_on_port $PROD_FRONTEND_PORT "yes"
    fi
    
    # Check PostgreSQL connection
    log "Checking PostgreSQL connection..."
    if ! command -v psql &> /dev/null; then
        log "PostgreSQL client not found. Please install PostgreSQL."
        return 1
    fi
    
    if ! pg_isready -h localhost -q; then
        log "PostgreSQL server is not running. Please start it first."
        return 1
    fi
    
    log "PostgreSQL connection verified."
    
    # Setup backend
    log "Setting up backend environment..."
    cd "$BACKEND_PATH"
    
    # Activate virtual environment
    if [ -d "venv" ]; then
        source venv/bin/activate
    else
        log "Virtual environment not found. Creating..."
        python -m venv venv
        source venv/bin/activate
        pip install -r requirements.txt
    fi
    
    # Copy production environment file
    cp .env.production .env
    
    # Additional environment variables needed for production
    echo "ENVIRONMENT=production" >> .env
    echo "PORT=$PROD_BACKEND_PORT" >> .env
    
    # Start Gunicorn in the background
    log "Starting backend server..."
    gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:$PROD_BACKEND_PORT > "$LOG_DIR/backend_prod.log" 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > "$LOG_DIR/backend_prod.pid"
    
    # Check if process started successfully
    if ps -p $BACKEND_PID > /dev/null; then
        log "Backend service started with PID: $BACKEND_PID"
    else
        log "Failed to start backend service."
        return 1
    fi
    
    # Deactivate virtual environment
    deactivate
    
    # Setup frontend
    log "Setting up frontend environment..."
    cd "$FRONTEND_PATH"
    
    # Create production environment
    cat > .env.production.local << EOF
REACT_APP_API_URL=http://localhost:$PROD_BACKEND_PORT/api
PORT=$PROD_FRONTEND_PORT
NODE_ENV=production
EOF
    
    # Build the frontend if needed
    if [ ! -d "build" ]; then
        log "Building frontend application..."
        npm ci
        npm run build
    fi
    
    # Start frontend with serve
    log "Starting frontend server..."
    npx serve -s build -l $PROD_FRONTEND_PORT > "$LOG_DIR/frontend_prod.log" 2>&1 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > "$LOG_DIR/frontend_prod.pid"
    
    # Check if process started successfully
    if ps -p $FRONTEND_PID > /dev/null; then
        log "Frontend service started with PID: $FRONTEND_PID"
    else
        log "Failed to start frontend service."
        return 1
    fi
    
    # Return to project root
    cd "$REPO_ROOT"
    
    # Display success message
    log "Production environment is running!"
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}Production environment is running!${NC}"
    echo -e "${GREEN}Backend API: http://localhost:$PROD_BACKEND_PORT${NC}"
    echo -e "${GREEN}Frontend App: http://localhost:$PROD_FRONTEND_PORT${NC}"
    echo -e "${GREEN}=====================================${NC}"
    
    return 0
}

# Stop the development environment
stop_dev() {
    log "Stopping development environment..."
    
    # Call the specialized stop script
    if [ -f "$SCRIPTS_DIR/system/dev/stop_dev_env.sh" ]; then
        bash "$SCRIPTS_DIR/system/dev/stop_dev_env.sh"
        return $?
    else
        log "Error: Development environment stop script not found"
        echo -e "${RED}Error: scripts/system/dev/stop_dev_env.sh not found${NC}"
        return 1
    fi
}

# Stop the production environment
stop_prod() {
    log "Stopping production environment..."
    
    # Kill processes using PID files if they exist
    if [ -f "$LOG_DIR/backend_prod.pid" ]; then
        local backend_pid=$(cat "$LOG_DIR/backend_prod.pid")
        if ps -p $backend_pid >/dev/null 2>&1; then
            log "Killing backend process with PID $backend_pid"
            kill -9 $backend_pid 2>/dev/null
            rm "$LOG_DIR/backend_prod.pid"
        fi
    fi
    
    if [ -f "$LOG_DIR/frontend_prod.pid" ]; then
        local frontend_pid=$(cat "$LOG_DIR/frontend_prod.pid")
        if ps -p $frontend_pid >/dev/null 2>&1; then
            log "Killing frontend process with PID $frontend_pid"
            kill -9 $frontend_pid 2>/dev/null
            rm "$LOG_DIR/frontend_prod.pid"
        fi
    fi
    
    # Additionally kill any processes on the production ports
    safe_kill_process_on_port $PROD_BACKEND_PORT "yes"
    safe_kill_process_on_port $PROD_FRONTEND_PORT "yes"
    
    log "Production environment stopped."
    echo -e "${GREEN}Production environment stopped.${NC}"
    
    return 0
}

# Clean up temporary files
cleanup_temp_files() {
    log "Cleaning up temporary files..."
    
    # Remove any .pyc files in the backend directory
    if [ -d "$REPO_ROOT/backend" ]; then
        find "$REPO_ROOT/backend" -name "*.pyc" -delete
        log "Cleaned up Python cache files"
    fi
    
    # Clear node_modules/.cache if it exists
    if [ -d "$REPO_ROOT/frontend/node_modules/.cache" ]; then
        rm -rf "$REPO_ROOT/frontend/node_modules/.cache"
        log "Cleaned up frontend cache"
    fi
    
    log "Temporary files cleanup completed."
    return 0
}

# Restart the development environment
restart_dev() {
    log "Restarting development environment..."
    
    # Stop the development environment
    stop_dev
    
    # Clean up temporary files
    cleanup_temp_files
    
    # Check database
    if ! pgrep -x "postgres" > /dev/null; then
        log "${YELLOW}WARNING: PostgreSQL does not appear to be running${NC}"
        log "${YELLOW}Please ensure PostgreSQL is started before continuing${NC}"
        echo -e "${YELLOW}WARNING: PostgreSQL does not appear to be running${NC}"
        echo -e "${YELLOW}Please ensure PostgreSQL is started before continuing${NC}"
        
        # Ask if we should continue anyway
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Restart aborted by user"
            echo -e "${RED}Restart aborted${NC}"
            return 1
        fi
    fi
    
    # Start the development environment
    start_dev
    
    log "Development environment restarted."
    return 0
}

# Restart the production environment
restart_prod() {
    log "Restarting production environment..."
    
    # Stop the production environment
    stop_prod
    
    # Check database
    if ! pgrep -x "postgres" > /dev/null; then
        log "${YELLOW}WARNING: PostgreSQL does not appear to be running${NC}"
        log "${YELLOW}Please ensure PostgreSQL is started before continuing${NC}"
        echo -e "${YELLOW}WARNING: PostgreSQL does not appear to be running${NC}"
        echo -e "${YELLOW}Please ensure PostgreSQL is started before continuing${NC}"
        
        # Ask if we should continue anyway
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Restart aborted by user"
            echo -e "${RED}Restart aborted${NC}"
            return 1
        fi
    fi
    
    # Start the production environment
    start_prod
    
    log "Production environment restarted."
    return 0
}

# Show status of the development environment
status_dev() {
    echo "Development Environment Status:"
    echo "------------------------------"
    
    # Check if backend is running
    if is_port_in_use $DEV_BACKEND_PORT; then
        echo -e "${GREEN}✓ Backend is running on port $DEV_BACKEND_PORT${NC}"
        get_process_on_port $DEV_BACKEND_PORT
    else
        echo -e "${RED}✗ Backend is not running on port $DEV_BACKEND_PORT${NC}"
    fi
    
    # Check if frontend is running
    if is_port_in_use $DEV_FRONTEND_PORT; then
        echo -e "${GREEN}✓ Frontend is running on port $DEV_FRONTEND_PORT${NC}"
        get_process_on_port $DEV_FRONTEND_PORT
    else
        echo -e "${RED}✗ Frontend is not running on port $DEV_FRONTEND_PORT${NC}"
    fi
    
    return 0
}

# Show status of the production environment
status_prod() {
    echo "Production Environment Status:"
    echo "------------------------------"
    
    # Check if backend is running
    if is_port_in_use $PROD_BACKEND_PORT; then
        echo -e "${GREEN}✓ Backend is running on port $PROD_BACKEND_PORT${NC}"
        get_process_on_port $PROD_BACKEND_PORT
    else
        echo -e "${RED}✗ Backend is not running on port $PROD_BACKEND_PORT${NC}"
    fi
    
    # Check if frontend is running
    if is_port_in_use $PROD_FRONTEND_PORT; then
        echo -e "${GREEN}✓ Frontend is running on port $PROD_FRONTEND_PORT${NC}"
        get_process_on_port $PROD_FRONTEND_PORT
    else
        echo -e "${RED}✗ Frontend is not running on port $PROD_FRONTEND_PORT${NC}"
    fi
    
    return 0
}

# Main function
manage_system() {
    local environment=$1
    local command=$2
    shift 2
    
    case "$environment" in
        dev)
            case "$command" in
                start)
                    start_dev "$@"
                    ;;
                stop)
                    stop_dev "$@"
                    ;;
                restart)
                    restart_dev "$@"
                    ;;
                status)
                    status_dev "$@"
                    ;;
                *)
                    echo "Error: Invalid command for development environment."
                    return 1
                    ;;
            esac
            ;;
        prod)
            case "$command" in
                start)
                    start_prod "$@"
                    ;;
                stop)
                    stop_prod "$@"
                    ;;
                restart)
                    restart_prod "$@"
                    ;;
                status)
                    status_prod "$@"
                    ;;
                *)
                    echo "Error: Invalid command for production environment."
                    return 1
                    ;;
            esac
            ;;
        all)
            case "$command" in
                start)
                    start_dev "$@" && start_prod "$@"
                    ;;
                stop)
                    stop_dev "$@" && stop_prod "$@"
                    ;;
                restart)
                    restart_dev "$@" && restart_prod "$@"
                    ;;
                status)
                    status_dev "$@" && echo "" && status_prod "$@"
                    ;;
                *)
                    echo "Error: Invalid command for all environments."
                    return 1
                    ;;
            esac
            ;;
        *)
            echo "Error: Invalid environment."
            return 1
            ;;
    esac
    
    return 0
} 