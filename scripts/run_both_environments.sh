#!/bin/bash

# FreeLIMS - Run Both Environments Script
# This script starts both production and development environments
# with uniform authentication configuration

echo "======================================"
echo "FreeLIMS Dual Environment Launcher"
echo "======================================"
echo "Started at: $(date)"
echo ""

# Define paths
PROJECT_ROOT="$(pwd)"
SCRIPTS_PATH="$PROJECT_ROOT/scripts"
LOG_PATH="$PROJECT_ROOT/logs"

# Create log directory if it doesn't exist
mkdir -p "$LOG_PATH"

# Log file for this script
SCRIPT_LOG="$LOG_PATH/dual_environment.log"

# Function to log messages
log_message() {
    local MESSAGE=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $MESSAGE" | tee -a "$SCRIPT_LOG"
}

# Function to check if a port is in use
check_port() {
    local PORT=$1
    lsof -i:$PORT -t >/dev/null 2>&1
    return $?
}

# First, ensure all environments are stopped
log_message "Stopping any existing environments..."
$SCRIPTS_PATH/freelims.sh prod stop >/dev/null 2>&1
$SCRIPTS_PATH/freelims.sh dev stop >/dev/null 2>&1

# Kill any remaining processes
log_message "Cleaning up any remaining processes..."
PORTS=(3000 3001 3002 8000 9000)
for PORT in "${PORTS[@]}"; do
    if check_port $PORT; then
        PID=$(lsof -i:$PORT -t)
        log_message "Killing process $PID on port $PORT"
        kill -9 $PID >/dev/null 2>&1
    fi
done

# Start production environment
log_message "Starting production environment..."
$SCRIPTS_PATH/freelims.sh prod start

# Check if production environment started successfully
if check_port 9000 && check_port 3000; then
    log_message "✅ Production environment started successfully"
else
    log_message "❌ Production environment failed to start"
    exit 1
fi

# Start development environment
log_message "Starting development environment..."
$SCRIPTS_PATH/freelims.sh dev start

# Check if development environment started successfully
if check_port 8000 && check_port 3001; then
    log_message "✅ Development environment started successfully"
else
    log_message "❌ Development environment failed to start"
    exit 1
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
echo "$SCRIPTS_PATH/freelims.sh prod stop && $SCRIPTS_PATH/freelims.sh dev stop"
echo "======================================"

exit 0 