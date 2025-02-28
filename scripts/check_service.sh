#!/bin/bash

# FreeLIMS Service Status Checker
# This script checks if the FreeLIMS service and all components are running

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define paths
SERVICE_NAME="com.freelims.service"
LOG_PATH="/Users/shaun/Documents/GitHub/projects/freelims/logs"

# Helper function for status indicators
status_indicator() {
    local STATUS=$1
    if [ "$STATUS" = "running" ]; then
        echo -e "${GREEN}●${NC} Running"
    else
        echo -e "${RED}●${NC} Stopped"
    fi
}

# Print header
echo -e "\n${BLUE}FreeLIMS Service Status${NC}"
echo "========================================"

# Check if service is installed
if [ ! -f "/Library/LaunchDaemons/$SERVICE_NAME.plist" ]; then
    echo -e "${RED}FreeLIMS service is not installed${NC}"
    echo "Run 'sudo scripts/install_service.sh' to install the service"
    exit 1
fi

# Check service status
SERVICE_STATUS=$(sudo launchctl list | grep $SERVICE_NAME || echo "")
if [ -n "$SERVICE_STATUS" ]; then
    echo -e "Service status: $(status_indicator running)"
else
    echo -e "Service status: $(status_indicator stopped)"
fi

# Check if ports are in use for the development environment
DEV_BACKEND_PID=$(lsof -t -i:8001 2>/dev/null)
if [ -n "$DEV_BACKEND_PID" ]; then
    DEV_BACKEND_STATUS="running"
    DEV_BACKEND_INFO="PID: $DEV_BACKEND_PID"
else
    DEV_BACKEND_STATUS="stopped"
    DEV_BACKEND_INFO=""
fi

DEV_FRONTEND_PID=$(lsof -t -i:3001 2>/dev/null)
if [ -n "$DEV_FRONTEND_PID" ]; then
    DEV_FRONTEND_STATUS="running"
    DEV_FRONTEND_INFO="PID: $DEV_FRONTEND_PID"
else
    DEV_FRONTEND_STATUS="stopped"
    DEV_FRONTEND_INFO=""
fi

# Check if ports are in use for the production environment
PROD_BACKEND_PID=$(lsof -t -i:8002 2>/dev/null)
if [ -n "$PROD_BACKEND_PID" ]; then
    PROD_BACKEND_STATUS="running"
    PROD_BACKEND_INFO="PID: $PROD_BACKEND_PID"
else
    PROD_BACKEND_STATUS="stopped"
    PROD_BACKEND_INFO=""
fi

PROD_FRONTEND_PID=$(lsof -t -i:3002 2>/dev/null)
if [ -n "$PROD_FRONTEND_PID" ]; then
    PROD_FRONTEND_STATUS="running"
    PROD_FRONTEND_INFO="PID: $PROD_FRONTEND_PID"
else
    PROD_FRONTEND_STATUS="stopped"
    PROD_FRONTEND_INFO=""
fi

# Display component status
echo -e "\n${BLUE}Development Environment${NC}"
echo -e "Backend (port 8001): $(status_indicator $DEV_BACKEND_STATUS) $DEV_BACKEND_INFO"
echo -e "Frontend (port 3001): $(status_indicator $DEV_FRONTEND_STATUS) $DEV_FRONTEND_INFO"
echo -e "\n${BLUE}Production Environment${NC}"
echo -e "Backend (port 8002): $(status_indicator $PROD_BACKEND_STATUS) $PROD_BACKEND_INFO"
echo -e "Frontend (port 3002): $(status_indicator $PROD_FRONTEND_STATUS) $PROD_FRONTEND_INFO"

# Display log file sizes and last modified time
echo -e "\n${BLUE}Log Files${NC}"
if [ -d "$LOG_PATH" ]; then
    echo "Main service log:"
    ls -lh "$LOG_PATH/freelims_service.log" 2>/dev/null || echo "  Not found"
    
    echo "Development logs:"
    ls -lh "$LOG_PATH/backend.log" "$LOG_PATH/frontend.log" 2>/dev/null || echo "  Not found"
    
    echo "Production logs:"
    ls -lh "$LOG_PATH/backend_prod.log" "$LOG_PATH/frontend_prod.log" 2>/dev/null || echo "  Not found"
else
    echo -e "${YELLOW}Log directory not found${NC}"
fi

# Help text
echo -e "\n${BLUE}Management Commands${NC}"
echo "Start service:   sudo launchctl load /Library/LaunchDaemons/$SERVICE_NAME.plist"
echo "Stop service:    sudo launchctl unload /Library/LaunchDaemons/$SERVICE_NAME.plist"
echo "Reinstall:       sudo scripts/install_service.sh"
echo "Uninstall:       sudo scripts/uninstall_service.sh"
echo "View logs:       tail -f $LOG_PATH/freelims_service.log"

echo -e "\n========================================"
exit 0 