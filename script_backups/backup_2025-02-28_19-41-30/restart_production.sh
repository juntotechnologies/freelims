#!/bin/bash

# -------------------------------------------
# FreeLIMS Production System Restart Script
# -------------------------------------------
# This script safely shuts down all FreeLIMS production components
# and restarts them without losing any data
# -------------------------------------------

# Set this to the root directory of your FreeLIMS project
PROJECT_ROOT="$(pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
RESTART_LOG="$LOG_DIR/restart_prod_$TIMESTAMP.log"

# Source the port configuration
if [ -f "$PROJECT_ROOT/port_config.sh" ]; then
  source "$PROJECT_ROOT/port_config.sh"
else
  # Default ports if config file not found
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
echo -e "${GREEN}   FreeLIMS Production System Restart   ${NC}"
echo -e "${GREEN}=====================================${NC}"
log "Starting production system restart"

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
      log "Process on port $port terminated successfully"
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
      echo "Processes using port $port:"
      lsof -i :$port
      read -p "Do you want to terminate these processes? (y/N): " confirm
      if [[ ! "$confirm" =~ ^[Yy] ]]; then
        log "Operation cancelled"
        echo "Operation cancelled"
        exit 1
      fi
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
kill_all_freelims_production_processes() {
  log "Terminating all FreeLIMS production processes..."
  
  # Kill processes on specific ports
  kill_process_on_port $PROD_BACKEND_PORT  # Backend port
  kill_process_on_port $PROD_FRONTEND_PORT  # Frontend port
  
  # Kill processes using PID files if they exist
  if [ -f "$LOG_DIR/backend_prod.pid" ]; then
    local backend_pid=$(cat "$LOG_DIR/backend_prod.pid")
    if ps -p $backend_pid >/dev/null 2>&1; then
      log "Killing backend process with PID $backend_pid"
      kill -9 $backend_pid 2>/dev/null
    fi
  fi
  
  if [ -f "$LOG_DIR/frontend_prod.pid" ]; then
    local frontend_pid=$(cat "$LOG_DIR/frontend_prod.pid")
    if ps -p $frontend_pid >/dev/null 2>&1; then
      log "Killing frontend process with PID $frontend_pid"
      kill -9 $frontend_pid 2>/dev/null
    fi
  fi
  
  # Additionally, find and kill any stray processes that might be related
  # Find any gunicorn processes
  for pid in $(ps aux | grep "gunicorn.*app.main:app" | grep -v grep | awk '{print $2}'); do
    log "Killing gunicorn process with PID $pid"
    kill -9 $pid 2>/dev/null
  done
  
  # Find any serve processes for the frontend
  for pid in $(ps aux | grep "serve -s build -l" | grep -v grep | awk '{print $2}'); do
    log "Killing serve process with PID $pid"
    kill -9 $pid 2>/dev/null
  done
  
  log "All FreeLIMS production processes terminated"
}

# Step 3: Verify database is running
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

# Step 4: Restart the system using start_production.sh
restart_production_system() {
  log "Restarting FreeLIMS production system..."
  
  # Check if start_production.sh exists
  local start_script="$PROJECT_ROOT/scripts/deploy/start_production.sh"
  if [ ! -f "$start_script" ]; then
    log "${RED}Error: start_production.sh script not found at $start_script${NC}"
    echo -e "${RED}Error: start_production.sh script not found!${NC}"
    return 1
  fi
  
  # Make sure it's executable
  if [ ! -x "$start_script" ]; then
    log "Making start_production.sh executable"
    chmod +x "$start_script"
  fi
  
  # Execute the production script
  log "Executing start_production.sh"
  echo -e "${GREEN}Starting FreeLIMS production system...${NC}"
  "$start_script"
  
  # Check status
  if [ $? -eq 0 ]; then
    log "FreeLIMS production system restarted successfully"
    echo -e "${GREEN}FreeLIMS production system restarted successfully${NC}"
  else
    log "${RED}Failed to restart FreeLIMS production system${NC}"
    echo -e "${RED}Failed to restart FreeLIMS production system. Check logs for details.${NC}"
    return 1
  fi
}

# Execute all steps
kill_all_freelims_production_processes
check_database
restart_production_system

log "Production restart process completed"
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Restart completed! Log saved to:${NC}"
echo -e "${GREEN}$RESTART_LOG${NC}"
echo -e "${GREEN}=====================================${NC}" 