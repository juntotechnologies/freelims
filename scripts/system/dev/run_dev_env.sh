#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Development Environment Runner
# This script starts the FreeLIMS development environment
# It is designed to be called from freelims.sh, but can be run directly
# ----------------------------------------------------------------------------

# If being run directly (not from freelims.sh), determine paths
if [ -z "$REPO_ROOT" ]; then
    # Navigate up three directories from this script to get to repo root
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
    SCRIPTS_DIR="$REPO_ROOT/scripts"
fi

# Source port configuration if not already sourced
if [ "$(type -t is_port_in_use)" != "function" ]; then
    if [ -f "$REPO_ROOT/port_config.sh" ]; then
        source "$REPO_ROOT/port_config.sh"
    else
        echo "Warning: port_config.sh not found. Using default ports."
    fi
fi

# Initialize variables with defaults (use port_config.sh values if available)
DEV_BACKEND_PORT=${DEV_BACKEND_PORT:-8001}
DEV_FRONTEND_PORT=${DEV_FRONTEND_PORT:-3001}

# Log directory
LOG_DIR="$REPO_ROOT/logs"
mkdir -p "$LOG_DIR"

# Colors for better visibility
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Display banner
echo -e "${GREEN}====================================${NC}"
echo -e "${GREEN}  Starting FreeLIMS Development Env  ${NC}"
echo -e "${GREEN}  $(date)  ${NC}"
echo -e "${GREEN}====================================${NC}"

# Check if ports are in use
check_and_kill_port() {
    local port=$1
    local service=$2
    
    if [ "$(type -t is_port_in_use)" = "function" ]; then
        # Use port_config.sh function if available
        if is_port_in_use $port; then
            echo -e "${YELLOW}Port $port is already in use by:${NC}"
            get_process_on_port $port
            read -p "Do you want to terminate these processes and continue? (y/N): " confirm
            if [[ ! "$confirm" =~ ^[Yy] ]]; then
                echo -e "${RED}Operation cancelled. Exiting...${NC}"
                exit 1
            fi
            safe_kill_process_on_port $port "yes"
        fi
    else
        # Fallback check if port_config.sh was not sourced
        if lsof -i:$port -sTCP:LISTEN -t &>/dev/null; then
            echo -e "${YELLOW}Port $port is already in use.${NC}"
            lsof -i:$port -sTCP:LISTEN
            read -p "Do you want to terminate these processes and continue? (y/N): " confirm
            if [[ ! "$confirm" =~ ^[Yy] ]]; then
                echo -e "${RED}Operation cancelled. Exiting...${NC}"
                exit 1
            fi
            echo "Killing process on port $port..."
            lsof -i:$port -sTCP:LISTEN -t | xargs kill -9
        fi
    fi
    
    echo -e "${GREEN}Port $port is free for $service.${NC}"
}

echo "Checking ports..."
check_and_kill_port $DEV_BACKEND_PORT "backend"
check_and_kill_port $DEV_FRONTEND_PORT "frontend"

# Define paths
BACKEND_PATH="$REPO_ROOT/backend"
FRONTEND_PATH="$REPO_ROOT/frontend"

# Setup and start backend
echo -e "${GREEN}Setting up backend environment...${NC}"
cd "$BACKEND_PATH"

# Create and activate virtual environment if needed
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python -m venv venv
fi

source venv/bin/activate
echo "Installing backend dependencies..."
pip install -r requirements.txt

# Copy development environment file if it exists
if [ -f ".env.development" ]; then
    cp .env.development .env
    echo "Copied .env.development to .env"
else
    echo "Warning: .env.development not found, creating minimal .env"
    echo "ENVIRONMENT=development" > .env
    echo "DATABASE_URL=postgresql://postgres:postgres@localhost/freelims_dev" >> .env
fi

# Start backend server in the background
echo -e "${GREEN}Starting backend server...${NC}"
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port $DEV_BACKEND_PORT > "$LOG_DIR/backend_dev.log" 2>&1 &
BACKEND_PID=$!
echo $BACKEND_PID > "$LOG_DIR/backend_dev.pid"
echo "Backend server started with PID: $BACKEND_PID"

# Setup and start frontend
echo -e "${GREEN}Setting up frontend environment...${NC}"
cd "$FRONTEND_PATH"

# Create frontend environment file
cat > .env.development.local << EOF
REACT_APP_API_URL=http://localhost:$DEV_BACKEND_PORT/api
PORT=$DEV_FRONTEND_PORT
EOF

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing frontend dependencies..."
    npm install
fi

# Start frontend server in the background
echo -e "${GREEN}Starting frontend server...${NC}"
BROWSER=none npm start > "$LOG_DIR/frontend_dev.log" 2>&1 &
FRONTEND_PID=$!
echo $FRONTEND_PID > "$LOG_DIR/frontend_dev.pid"
echo "Frontend server started with PID: $FRONTEND_PID"

# Return to project root
cd "$REPO_ROOT"

# Set up trap to handle Ctrl+C and clean up resources
cleanup() {
    echo -e "${YELLOW}Stopping development servers...${NC}"
    if [ -f "$LOG_DIR/backend_dev.pid" ]; then
        PID=$(cat "$LOG_DIR/backend_dev.pid")
        if ps -p $PID > /dev/null; then
            kill $PID
            echo "Backend server stopped (PID: $PID)"
        fi
        rm "$LOG_DIR/backend_dev.pid"
    fi
    
    if [ -f "$LOG_DIR/frontend_dev.pid" ]; then
        PID=$(cat "$LOG_DIR/frontend_dev.pid")
        if ps -p $PID > /dev/null; then
            kill $PID
            echo "Frontend server stopped (PID: $PID)"
        fi
        rm "$LOG_DIR/frontend_dev.pid"
    fi
    
    echo -e "${GREEN}Development environment stopped.${NC}"
    exit 0
}

trap cleanup INT

# Display success message
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Development environment is running!${NC}"
echo -e "${GREEN}Backend server: http://localhost:$DEV_BACKEND_PORT${NC}"
echo -e "${GREEN}Frontend client: http://localhost:$DEV_FRONTEND_PORT${NC}"
echo -e "${GREEN}=====================================${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop all servers${NC}"

# Keep script running until user presses Ctrl+C
while true; do
    sleep 1
done 