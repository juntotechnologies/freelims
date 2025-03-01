#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Development Environment Stopper
# This script stops the FreeLIMS development environment
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

# Initialize variables with defaults
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
echo -e "${YELLOW}====================================${NC}"
echo -e "${YELLOW}  Stopping FreeLIMS Development Env  ${NC}"
echo -e "${YELLOW}  $(date)  ${NC}"
echo -e "${YELLOW}====================================${NC}"

# Function to stop a process by PID file
stop_process_by_pid() {
    local pid_file=$1
    local process_name=$2
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        echo "Checking $process_name process with PID $pid..."
        
        if ps -p $pid > /dev/null; then
            echo -e "${YELLOW}Stopping $process_name process with PID $pid...${NC}"
            kill $pid 2>/dev/null
            
            # Wait a moment for graceful shutdown
            sleep 1
            
            # Force kill if still running
            if ps -p $pid > /dev/null; then
                echo -e "${RED}Process still running, force killing...${NC}"
                kill -9 $pid 2>/dev/null
            fi
            
            echo -e "${GREEN}$process_name process stopped.${NC}"
        else
            echo -e "${YELLOW}$process_name process (PID $pid) is not running.${NC}"
        fi
        
        # Remove PID file
        rm -f "$pid_file"
    else
        echo -e "${YELLOW}No PID file found for $process_name.${NC}"
    fi
}

# Function to stop a process by port
stop_process_by_port() {
    local port=$1
    local service_name=$2
    
    if [ "$(type -t is_port_in_use)" = "function" ]; then
        # Use port_config.sh function if available
        if is_port_in_use $port; then
            echo -e "${YELLOW}Found $service_name process running on port $port:${NC}"
            get_process_on_port $port
            echo -e "${YELLOW}Terminating process on port $port...${NC}"
            safe_kill_process_on_port $port "yes"
            echo -e "${GREEN}$service_name process on port $port stopped.${NC}"
        else
            echo -e "${GREEN}No $service_name process running on port $port.${NC}"
        fi
    else
        # Fallback check if port_config.sh was not sourced
        if lsof -i:$port -sTCP:LISTEN -t &>/dev/null; then
            echo -e "${YELLOW}Found $service_name process running on port $port:${NC}"
            lsof -i:$port -sTCP:LISTEN
            echo -e "${YELLOW}Terminating process on port $port...${NC}"
            lsof -i:$port -sTCP:LISTEN -t | xargs kill -9 2>/dev/null
            echo -e "${GREEN}$service_name process on port $port stopped.${NC}"
        else
            echo -e "${GREEN}No $service_name process running on port $port.${NC}"
        fi
    fi
}

# Stop backend process
echo "Stopping backend process..."
stop_process_by_pid "$LOG_DIR/backend_dev.pid" "Backend"
stop_process_by_port $DEV_BACKEND_PORT "Backend"

# Stop frontend process
echo "Stopping frontend process..."
stop_process_by_pid "$LOG_DIR/frontend_dev.pid" "Frontend"
stop_process_by_port $DEV_FRONTEND_PORT "Frontend"

# Display success message
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Development environment stopped.${NC}"
echo -e "${GREEN}=====================================${NC}"

exit 0 