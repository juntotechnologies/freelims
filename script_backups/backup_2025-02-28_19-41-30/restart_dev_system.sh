#!/bin/bash

# -------------------------------------------
# FreeLIMS System Restart Script
# -------------------------------------------
# This script safely shuts down all FreeLIMS components
# and restarts them without losing any data
# -------------------------------------------

# Set this to the root directory of your FreeLIMS project
PROJECT_ROOT="$(pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
RESTART_LOG="$LOG_DIR/restart_$TIMESTAMP.log"

# Source the port configuration
if [ -f "$PROJECT_ROOT/port_config.sh" ]; then
  source "$PROJECT_ROOT/port_config.sh"
else
  # Default ports if config file not found
  DEV_BACKEND_PORT=8001
  DEV_FRONTEND_PORT=3001
  PROD_BACKEND_PORT=8002
  PROD_FRONTEND_PORT=3002
fi

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

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
  echo "[$timestamp] $message" >> "$RESTART_LOG"
}

# Print banner
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}       FreeLIMS System Restart       ${NC}"
echo -e "${GREEN}=====================================${NC}"
log "Starting system restart"

# Step 1: Find and terminate processes on specific ports
# Use our port configuration utility if available
if [ "$(type -t safe_kill_process_on_port)" = "function" ]; then
  kill_process_on_port() {
    local port=$1
    log "Checking for processes on port $port..."
    
    # Check if port is in use
    if is_port_in_use $port; then
      log "Found process on port $port"
      safe_kill_process_on_port $port "yes"
      log "Process with PID on port $port terminated successfully"
    else
      log "No process found running on port $port"
    fi
  }
else
  # Fallback if our safe_kill_process_on_port function is not available
  kill_process_on_port() {
    local port=$1
    log "Checking for processes on port $port..."
    
    # Find process using the port
    local pid=$(lsof -i :$port -t)
    
    if [ -n "$pid" ]; then
      log "Found process with PID $pid on port $port"
      log "Terminating process..."
      kill -9 $pid 2>/dev/null
      if [ $? -eq 0 ]; then
        log "Process with PID $pid on port $port terminated successfully"
      else
        log "Failed to terminate process on port $port"
      fi
    else
      log "No process found running on port $port"
    fi
  }
fi

# Step 2: Function to terminate all FreeLIMS-related processes
kill_all_freelims_processes() {
  log "Terminating all FreeLIMS processes..."
  
  # Kill processes on specific ports
  kill_process_on_port $DEV_BACKEND_PORT  # Backend port
  kill_process_on_port $DEV_FRONTEND_PORT  # Frontend port
  
  # Additionally, find and kill any stray processes that might be related
  # Find any python processes running uvicorn for the app
  for pid in $(ps aux | grep "uvicorn app.main:app" | grep -v grep | awk '{print $2}'); do
    log "Killing uvicorn process with PID $pid"
    kill -9 $pid 2>/dev/null
  done
  
  # Find any npm processes for the frontend
  for pid in $(ps aux | grep "npm start" | grep -v grep | awk '{print $2}'); do
    log "Killing npm process with PID $pid"
    kill -9 $pid 2>/dev/null
  done
  
  log "All FreeLIMS processes terminated"
}

# Step 3: Clean up temporary files
cleanup_temp_files() {
  log "Cleaning up temporary files..."
  
  # Remove any .pyc files in the backend directory
  if [ -d "$PROJECT_ROOT/backend" ]; then
    find "$PROJECT_ROOT/backend" -name "*.pyc" -delete
    log "Cleaned up Python cache files"
  fi
  
  # Clear node_modules/.cache if it exists
  if [ -d "$PROJECT_ROOT/frontend/node_modules/.cache" ]; then
    rm -rf "$PROJECT_ROOT/frontend/node_modules/.cache"
    log "Cleaned up frontend cache"
  fi
  
  log "Temporary files cleanup completed"
}

# Step 4: Verify database is running
check_database() {
  log "Checking if PostgreSQL is running..."
  
  # Check if postgres is running
  if pgrep -x "postgres" > /dev/null; then
    log "PostgreSQL is running"
  else
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
      exit 1
    fi
  fi
}

# Step 5: Restart the system using run_dev.sh
restart_system() {
  log "Restarting FreeLIMS system..."
  
  # Check if run_dev.sh exists and is executable
  if [ ! -f "$PROJECT_ROOT/run_dev.sh" ]; then
    log "${RED}Error: run_dev.sh script not found in $PROJECT_ROOT${NC}"
    echo -e "${RED}Error: run_dev.sh script not found!${NC}"
    return 1
  fi
  
  # Make sure it's executable
  if [ ! -x "$PROJECT_ROOT/run_dev.sh" ]; then
    log "Making run_dev.sh executable"
    chmod +x "$PROJECT_ROOT/run_dev.sh"
  fi
  
  # Execute the dev script
  log "Executing run_dev.sh"
  echo -e "${GREEN}Starting FreeLIMS system...${NC}"
  "$PROJECT_ROOT/run_dev.sh"
  
  # Check status
  if [ $? -eq 0 ]; then
    log "FreeLIMS system restarted successfully"
    echo -e "${GREEN}FreeLIMS system restarted successfully${NC}"
  else
    log "${RED}Failed to restart FreeLIMS system${NC}"
    echo -e "${RED}Failed to restart FreeLIMS system. Check logs for details.${NC}"
    return 1
  fi
}

# Execute all steps
kill_all_freelims_processes
cleanup_temp_files
check_database
restart_system

log "Restart process completed"
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Restart completed! Log saved to:${NC}"
echo -e "${GREEN}$RESTART_LOG${NC}"
echo -e "${GREEN}=====================================${NC}" 