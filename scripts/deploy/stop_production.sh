#!/bin/bash

# FreeLIMS Production Stop Script
# This script stops the FreeLIMS production services

# Display header
echo "=========================================="
echo "FreeLIMS Production Stop"
echo "=========================================="
echo "Started at: $(date)"
echo ""

# Define paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_PATH="$( cd "$SCRIPT_DIR/../.." &> /dev/null && pwd )"
LOG_PATH="$REPO_PATH/logs"

# Print paths for debugging
echo "Repository path: $REPO_PATH"
echo "Log path: $LOG_PATH"

# Function to handle errors
handle_error() {
    local message="$1"
    echo "ERROR: $message"
    exit 1
}

# Stop backend services
stop_backend() {
    echo "Stopping backend services..."
    
    # Find processes running uvicorn with the app module
    local backend_pids=$(pgrep -f "uvicorn.*app.main:app")
    
    if [ -n "$backend_pids" ]; then
        echo "Found backend processes: $backend_pids"
        # Kill the processes
        kill $backend_pids
        
        # Wait for processes to terminate
        sleep 2
        
        # Check if processes are still running
        if pgrep -f "uvicorn.*app.main:app" > /dev/null; then
            echo "Backend processes still running, force killing..."
            pkill -9 -f "uvicorn.*app.main:app"
        fi
        
        echo "Backend services stopped successfully"
    else
        echo "No backend services found running"
        
        # Additional check for processes on port 9000
        local port_pids=$(lsof -ti :9000)
        if [ -n "$port_pids" ]; then
            echo "Found processes on port 9000: $port_pids"
            kill -9 $port_pids
            echo "Killed processes on port 9000"
        fi
    fi
}

# Stop frontend services
stop_frontend() {
    echo "Stopping frontend services..."
    
    # Find processes serving the frontend build
    local frontend_pids=$(pgrep -f "node.*serve -s build")
    
    if [ -n "$frontend_pids" ]; then
        echo "Found frontend processes: $frontend_pids"
        # Kill the processes
        kill $frontend_pids
        
        # Wait for processes to terminate
        sleep 2
        
        # Check if processes are still running
        if pgrep -f "node.*serve -s build" > /dev/null; then
            echo "Frontend processes still running, force killing..."
            pkill -9 -f "node.*serve -s build"
        fi
        
        echo "Frontend services stopped successfully"
    else
        echo "No frontend services found running"
        
        # Additional check for processes on port 3000
        local port_pids=$(lsof -ti :3000)
        if [ -n "$port_pids" ]; then
            echo "Found processes on port 3000: $port_pids"
            kill -9 $port_pids
            echo "Killed processes on port 3000"
        fi
    fi
}

# Main function
main() {
    echo "Stopping all FreeLIMS production services..."
    
    stop_backend
    stop_frontend
    
    # Additional cleanup for any missed processes
    echo "Performing additional cleanup..."
    
    # Check for any uvicorn processes and kill them
    if pgrep -f "uvicorn" > /dev/null; then
        echo "Found additional uvicorn processes, killing them..."
        pkill -9 -f "uvicorn"
    fi
    
    # Check for any serve -s build processes and kill them
    if pgrep -f "serve -s build" > /dev/null; then
        echo "Found additional serve processes, killing them..."
        pkill -9 -f "serve -s build"
    fi
    
    # Check ports 9000 and 3000 directly
    for PORT in 9000 3000; do
        PORT_PIDS=$(lsof -ti :$PORT 2>/dev/null)
        if [ ! -z "$PORT_PIDS" ]; then
            echo "Found processes on port $PORT: $PORT_PIDS"
            kill -9 $PORT_PIDS 2>/dev/null
        fi
    done
    
    echo ""
    echo "=========================================="
    echo "FreeLIMS Production services have been stopped!"
    echo "=========================================="
    echo ""
}

# Execute main function
main 