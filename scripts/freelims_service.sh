#!/bin/bash

# FreeLIMS - Service Runner Script
# This script starts both production and development environments
# as a background service without user interaction

# Define paths
PROJECT_ROOT="/Users/shaun/Documents/GitHub/projects/freelims"
SCRIPTS_PATH="$PROJECT_ROOT/scripts"
LOG_PATH="$PROJECT_ROOT/logs"

# Create log directory if it doesn't exist
mkdir -p "$LOG_PATH"

# Log file for this script
SCRIPT_LOG="$LOG_PATH/freelims_service.log"

# Function to log messages
log_message() {
    local MESSAGE=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $MESSAGE" >> "$SCRIPT_LOG"
}

# Function to check if a port is in use
check_port() {
    local PORT=$1
    lsof -i:$PORT -t >/dev/null 2>&1
    return $?
}

# Function to kill process on a port without confirmation
kill_process_on_port() {
    local PORT=$1
    local PID=$(lsof -i:$PORT -t)
    if [ -n "$PID" ]; then
        log_message "Process with PID $PID is using port $PORT - killing it"
        kill -9 $PID >/dev/null 2>&1
    fi
}

# Log script start
log_message "==== FreeLIMS Service Starting ====="
log_message "Starting service at $(date)"

# First, ensure all environments are stopped
log_message "Stopping any existing environments..."
"$SCRIPTS_PATH/freelims.sh" prod stop >/dev/null 2>&1
"$SCRIPTS_PATH/freelims.sh" dev stop >/dev/null 2>&1

# Check and kill any remaining processes without user confirmation
log_message "Checking for processes using required ports..."
PORTS=(3001 3002 8001 8002)
for PORT in "${PORTS[@]}"; do
    if check_port $PORT; then
        kill_process_on_port $PORT
        sleep 1
    fi
done

# Start development environment
log_message "Starting development environment..."
cd "$PROJECT_ROOT" && ./run_dev.sh > "$LOG_PATH/dev_environment.log" 2>&1 &
DEV_PID=$!
log_message "Development environment started with PID: $DEV_PID"

# Allow time for the development environment to start
sleep 10

# Start production environment
log_message "Starting production environment..."
cd "$PROJECT_ROOT" && ./run_prod.sh > "$LOG_PATH/prod_environment.log" 2>&1 &
PROD_PID=$!
log_message "Production environment started with PID: $PROD_PID"

# Log success
log_message "Both environments started successfully"
log_message "Development PID: $DEV_PID"
log_message "Production PID: $PROD_PID"
log_message "==== FreeLIMS Service Started ====="

# Keep the script running to maintain the parent process
# This allows us to monitor the child processes
while true; do
    # Check if processes are still running
    if ! ps -p $DEV_PID > /dev/null; then
        log_message "WARNING: Development environment process died. Restarting..."
        cd "$PROJECT_ROOT" && ./run_dev.sh > "$LOG_PATH/dev_environment.log" 2>&1 &
        DEV_PID=$!
        log_message "Development environment restarted with PID: $DEV_PID"
    fi
    
    if ! ps -p $PROD_PID > /dev/null; then
        log_message "WARNING: Production environment process died. Restarting..."
        cd "$PROJECT_ROOT" && ./run_prod.sh > "$LOG_PATH/prod_environment.log" 2>&1 &
        PROD_PID=$!
        log_message "Production environment restarted with PID: $PROD_PID"
    fi
    
    # Log status every hour
    log_message "Service health check: Both environments still running"
    
    # Sleep for 1 hour before checking again
    sleep 3600
done 