#!/bin/bash

# FreeLIMS Production Start Script
# This script starts the FreeLIMS production services

# Define paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_PATH="$( cd "$SCRIPT_DIR/../.." &> /dev/null && pwd )"
BACKEND_PATH="$REPO_PATH/backend"
FRONTEND_PATH="$REPO_PATH/frontend"
LOG_PATH="$REPO_PATH/logs"

# Source the port configuration
if [ -f "$REPO_PATH/port_config.sh" ]; then
  source "$REPO_PATH/port_config.sh"
else
  # Default ports if config file not found
  PROD_BACKEND_PORT=8002
  PROD_FRONTEND_PORT=3002
fi

# Display header
echo "=========================================="
echo "FreeLIMS Production Start"
echo "=========================================="
echo "Started at: $(date)"
echo ""

# Print paths for debugging
echo "Repository path: $REPO_PATH"
echo "Backend path: $BACKEND_PATH"
echo "Frontend path: $FRONTEND_PATH"
echo "Log path: $LOG_PATH"
echo "Backend port: $PROD_BACKEND_PORT"
echo "Frontend port: $PROD_FRONTEND_PORT"

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
    
    # Source the port utilities if available
    if [ "$(type -t is_port_in_use)" = "function" ] && [ "$(type -t safe_kill_process_on_port)" = "function" ]; then
        # Check for backend
        if is_port_in_use $PROD_BACKEND_PORT; then
            echo "Backend service is already running on port $PROD_BACKEND_PORT"
            get_process_on_port $PROD_BACKEND_PORT
            read -p "Do you want to terminate these processes and continue? (y/N): " confirm
            if [[ ! "$confirm" =~ ^[Yy] ]]; then
                echo "Operation cancelled. Exiting..."
                exit 1
            fi
            safe_kill_process_on_port $PROD_BACKEND_PORT "yes"
        fi
        
        # Check for frontend
        if is_port_in_use $PROD_FRONTEND_PORT; then
            echo "Frontend service is already running on port $PROD_FRONTEND_PORT"
            get_process_on_port $PROD_FRONTEND_PORT
            read -p "Do you want to terminate these processes and continue? (y/N): " confirm
            if [[ ! "$confirm" =~ ^[Yy] ]]; then
                echo "Operation cancelled. Exiting..."
                exit 1
            fi
            safe_kill_process_on_port $PROD_FRONTEND_PORT "yes"
        fi
    else
        # Fallback if port utilities are not available
        # Check for backend
        if lsof -ti :$PROD_BACKEND_PORT > /dev/null; then
            echo "Backend service is already running on port $PROD_BACKEND_PORT"
            echo "Running processes:"
            lsof -i :$PROD_BACKEND_PORT
            read -p "Do you want to terminate these processes and continue? (y/N): " confirm
            if [[ ! "$confirm" =~ ^[Yy] ]]; then
                echo "Operation cancelled. Exiting..."
                exit 1
            fi
            lsof -ti :$PROD_BACKEND_PORT | xargs kill -9
        fi
        
        # Check for frontend
        if lsof -ti :$PROD_FRONTEND_PORT > /dev/null; then
            echo "Frontend service is already running on port $PROD_FRONTEND_PORT"
            echo "Running processes:"
            lsof -i :$PROD_FRONTEND_PORT
            read -p "Do you want to terminate these processes and continue? (y/N): " confirm
            if [[ ! "$confirm" =~ ^[Yy] ]]; then
                echo "Operation cancelled. Exiting..."
                exit 1
            fi
            lsof -ti :$PROD_FRONTEND_PORT | xargs kill -9
        fi
    fi
    
    return 0
}

# Check the PostgreSQL status
check_postgres() {
    echo "Checking PostgreSQL connection..."
    
    if ! command -v psql &> /dev/null; then
        handle_error "PostgreSQL client not found. Please install PostgreSQL."
    fi
    
    if ! pg_isready -h localhost -q; then
        handle_error "PostgreSQL server is not running. Please start it first."
    fi
    
    echo "PostgreSQL connection verified."
}

# Setup and start the backend
start_backend() {
    echo "Starting backend service..."
    cd "$BACKEND_PATH"
    
    # Activate virtual environment
    if [ ! -d "venv" ]; then
        handle_error "Virtual environment not found in $BACKEND_PATH."
    fi
    
    source venv/bin/activate
    
    # Copy production environment file
    cp .env.production .env
    
    # Additional environment variables needed for production
    echo "ENVIRONMENT=production" >> .env
    echo "PORT=$PROD_BACKEND_PORT" >> .env
    
    # Start Gunicorn in the background
    gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:$PROD_BACKEND_PORT > "$LOG_PATH/backend_prod.log" 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > "$LOG_PATH/backend_prod.pid"
    
    # Check if process started successfully
    if ps -p $BACKEND_PID > /dev/null; then
        echo "Backend service started with PID: $BACKEND_PID"
    else
        handle_error "Failed to start backend service."
    fi
    
    # Deactivate virtual environment
    deactivate
}

# Setup and start the frontend
start_frontend() {
    echo "Starting frontend service..."
    cd "$FRONTEND_PATH"
    
    # Create production environment
    cat > .env.production.local << EOF
REACT_APP_API_URL=http://localhost:$PROD_BACKEND_PORT/api
PORT=$PROD_FRONTEND_PORT
NODE_ENV=production
EOF
    
    # Build the frontend if needed
    if [ ! -d "build" ] || [ "$1" == "--rebuild" ]; then
        echo "Building frontend application..."
        npm ci
        npm run build
    fi
    
    # Start frontend with serve
    npx serve -s build -l $PROD_FRONTEND_PORT > "$LOG_PATH/frontend_prod.log" 2>&1 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > "$LOG_PATH/frontend_prod.pid"
    
    # Check if process started successfully
    if ps -p $FRONTEND_PID > /dev/null; then
        echo "Frontend service started with PID: $FRONTEND_PID"
    else
        handle_error "Failed to start frontend service."
    fi
}

# Main execution
check_running_services
check_postgres
start_backend
start_frontend

# Return to project root
cd "$REPO_PATH"

# Display success message
echo "=========================================="
echo "FreeLIMS Production is running!"
echo "Backend API: http://localhost:$PROD_BACKEND_PORT"
echo "Frontend App: http://localhost:$PROD_FRONTEND_PORT"
echo "=========================================="
echo "Server logs available in: $LOG_PATH" 