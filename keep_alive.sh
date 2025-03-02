#!/bin/bash

# Keep-alive script for FreeLIMS
# This script continuously checks if the FreeLIMS services are running
# and restarts them if they're not.

# Source port configuration
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$REPO_ROOT/port_config.sh" ]; then
    source "$REPO_ROOT/port_config.sh"
else
    echo "ERROR: port_config.sh not found. Monitoring service will exit."
    exit 1
fi

# Set default ports if not defined
DEV_BACKEND_PORT=${DEV_BACKEND_PORT:-8001}
DEV_FRONTEND_PORT=${DEV_FRONTEND_PORT:-3001}
PROD_BACKEND_PORT=${PROD_BACKEND_PORT:-8002}
PROD_FRONTEND_PORT=${PROD_FRONTEND_PORT:-3002}

# Log file
LOG_FILE="$REPO_ROOT/logs/keep_alive.log"
mkdir -p "$REPO_ROOT/logs"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to check if a process is running
check_process() {
    local pid=$1
    if [ -n "$pid" ] && ps -p "$pid" > /dev/null; then
        return 0  # Process is running
    else
        return 1  # Process is not running
    fi
}

# Start development environment
start_dev() {
    log "Starting development environment..."
    cd "$REPO_ROOT"
    ./freelims.sh system dev start > /dev/null 2>&1
    local status=$?
    if [ $status -eq 0 ]; then
        log "Development environment startup completed successfully."
    else
        log "WARNING: Development environment startup failed with status $status."
    fi
}

# Start production environment
start_prod() {
    log "Starting production environment..."
    cd "$REPO_ROOT"
    ./freelims.sh system prod start > /dev/null 2>&1
    local status=$?
    if [ $status -eq 0 ]; then
        log "Production environment startup completed successfully."
    else
        log "WARNING: Production environment startup failed with status $status."
    fi
}

# Keep services alive
keep_alive() {
    local env="$1"
    local restart_attempts=0
    local max_restart_attempts=5
    local restart_cooldown=300  # 5 minutes
    
    log "Starting keep-alive service for environment: $env"
    
    while true; do
        local restart_needed=false
        
        if [[ "$env" == "dev" || "$env" == "all" ]]; then
            # Check development backend
            if ! is_port_in_use $DEV_BACKEND_PORT; then
                log "Development backend is not running on port $DEV_BACKEND_PORT."
                restart_needed=true
            fi

            # Check development frontend
            if ! is_port_in_use $DEV_FRONTEND_PORT; then
                log "Development frontend is not running on port $DEV_FRONTEND_PORT."
                restart_needed=true
            fi
            
            if [ "$restart_needed" = true ]; then
                if [ $restart_attempts -lt $max_restart_attempts ]; then
                    log "Restarting development environment (attempt $((restart_attempts+1))/$max_restart_attempts)..."
                    start_dev
                    restart_attempts=$((restart_attempts+1))
                else
                    log "WARNING: Maximum restart attempts ($max_restart_attempts) reached for development environment. Cooling down for $restart_cooldown seconds."
                    sleep $restart_cooldown
                    restart_attempts=0
                fi
            else
                restart_attempts=0  # Reset counter if everything is running
            fi
        fi
        
        restart_needed=false
        
        if [[ "$env" == "prod" || "$env" == "all" ]]; then
            # Check production backend
            if ! is_port_in_use $PROD_BACKEND_PORT; then
                log "Production backend is not running on port $PROD_BACKEND_PORT."
                restart_needed=true
            fi

            # Check production frontend
            if ! is_port_in_use $PROD_FRONTEND_PORT; then
                log "Production frontend is not running on port $PROD_FRONTEND_PORT."
                restart_needed=true
            fi
            
            if [ "$restart_needed" = true ]; then
                if [ $restart_attempts -lt $max_restart_attempts ]; then
                    log "Restarting production environment (attempt $((restart_attempts+1))/$max_restart_attempts)..."
                    start_prod
                    restart_attempts=$((restart_attempts+1))
                else
                    log "WARNING: Maximum restart attempts ($max_restart_attempts) reached for production environment. Cooling down for $restart_cooldown seconds."
                    sleep $restart_cooldown
                    restart_attempts=0
                fi
            else
                restart_attempts=0  # Reset counter if everything is running
            fi
        fi

        # Sleep before checking again
        log "All services checked at $(date). Sleeping for 2 minutes..."
        sleep 120
    done
}

# Main function
log "===== Starting keep-alive service at $(date) ====="
log "Monitoring environment: $1"

# Start the keep-alive loop with the specified environment
keep_alive "$1"
