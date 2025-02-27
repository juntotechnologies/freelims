#!/bin/bash

# FreeLIMS Production Start Script
# This script starts the FreeLIMS production services

# Display header
echo "=========================================="
echo "FreeLIMS Production Start"
echo "=========================================="
echo "Started at: $(date)"
echo ""

# Define paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_PATH="$( cd "$SCRIPT_DIR/../.." &> /dev/null && pwd )"
BACKEND_PATH="$REPO_PATH/backend"
FRONTEND_PATH="$REPO_PATH/frontend"
LOG_PATH="$REPO_PATH/logs"

# Print paths for debugging
echo "Repository path: $REPO_PATH"
echo "Backend path: $BACKEND_PATH"
echo "Frontend path: $FRONTEND_PATH"
echo "Log path: $LOG_PATH"

# Create log directory if it doesn't exist
mkdir -p "$LOG_PATH"

# Function to handle errors
handle_error() {
    local message="$1"
    echo "ERROR: $message"
    exit 1
}

# Check if services are already running
check_running_services() {
    echo "Checking for running services..."
    
    # Check for backend on port 9000
    if lsof -ti :9000 > /dev/null; then
        echo "Backend service is already running on port 9000"
        return 1
    fi
    
    # Check for frontend on port 3000
    if lsof -ti :3000 > /dev/null; then
        echo "Frontend service is already running on port 3000"
        return 1
    fi
    
    return 0
}

# Start backend service
start_backend() {
    echo "Starting backend service..."
    
    cd "$BACKEND_PATH" || handle_error "Failed to access backend directory"
    
    # Activate virtual environment
    source venv/bin/activate || handle_error "Failed to activate virtual environment"
    
    # Start uvicorn
    nohup python -m uvicorn app.main:app --host 0.0.0.0 --port 9000 > "$LOG_PATH/backend_prod.log" 2>&1 &
    
    # Wait a moment for the service to start
    sleep 3
    
    # Check if backend started successfully
    if pgrep -f "uvicorn.*app.main:app" > /dev/null; then
        echo "Backend service started successfully"
    else
        handle_error "Failed to start backend service"
    fi
}

# Start frontend service
start_frontend() {
    echo "Starting frontend service..."
    
    cd "$FRONTEND_PATH" || handle_error "Failed to access frontend directory"
    
    # Check if build directory exists
    if [ ! -d "build" ]; then
        echo "Frontend build directory not found, building frontend..."
        npm run build || handle_error "Failed to build frontend"
    fi
    
    # Start frontend
    nohup npx serve -s build -p 3000 > "$LOG_PATH/frontend_prod.log" 2>&1 &
    
    # Wait a moment for the service to start
    sleep 3
    
    # Check if frontend started successfully
    if pgrep -f "node.*serve -s build" > /dev/null; then
        echo "Frontend service started successfully"
    else
        handle_error "Failed to start frontend service"
    fi
}

# Main function
main() {
    # Check if services are already running
    if check_running_services; then
        # Start services
        start_backend
        start_frontend
        
        echo ""
        echo "=========================================="
        echo "FreeLIMS Production services are running!"
        echo "=========================================="
        echo ""
        echo "Frontend: http://localhost:3000 (also accessible at http://192.168.1.200:3000)"
        echo "Backend API: http://localhost:9000"
        echo "API Documentation: http://localhost:9000/docs"
        echo "Logs directory: $LOG_PATH"
        echo ""
    else
        echo "Some services are already running. Stop them first with stop_production.sh."
        exit 1
    fi
}

# Execute main function
main 