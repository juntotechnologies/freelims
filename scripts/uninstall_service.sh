#!/bin/bash

# FreeLIMS Service Uninstaller
# This script uninstalls the FreeLIMS service

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Define paths
SYSTEM_PLIST_PATH="/Library/LaunchDaemons/com.freelims.service.plist"

# Helper function for logging
log() {
    local TYPE=$1
    local MESSAGE=$2
    
    case $TYPE in
        "info")
            echo -e "[${GREEN}INFO${NC}] $MESSAGE"
            ;;
        "warn")
            echo -e "[${YELLOW}WARNING${NC}] $MESSAGE"
            ;;
        "error")
            echo -e "[${RED}ERROR${NC}] $MESSAGE"
            ;;
        *)
            echo -e "$MESSAGE"
            ;;
    esac
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    log "error" "This script must be run as root (sudo)"
    echo "Please run: sudo $0"
    exit 1
fi

# Check if service is installed
if [ ! -f "$SYSTEM_PLIST_PATH" ]; then
    log "warn" "FreeLIMS service is not installed"
    exit 0
fi

# Confirm uninstallation
read -p "Are you sure you want to uninstall the FreeLIMS service? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    log "info" "Uninstallation canceled"
    exit 0
fi

# Stop any running FreeLIMS processes
log "info" "Stopping FreeLIMS processes..."
pkill -f "freelims_service.sh" || true
pkill -f "run_dev.sh" || true
pkill -f "run_prod.sh" || true
sleep 1

# Kill processes on specific ports
for PORT in 3001 3002 8001 8002; do
    PID=$(lsof -t -i:$PORT 2>/dev/null)
    if [ -n "$PID" ]; then
        log "info" "Killing process on port $PORT (PID: $PID)"
        kill -9 $PID 2>/dev/null || true
    fi
done

# Unload and remove the service
log "info" "Unloading FreeLIMS service..."
launchctl unload "$SYSTEM_PLIST_PATH"

log "info" "Removing service file..."
rm "$SYSTEM_PLIST_PATH"

log "info" "FreeLIMS service has been uninstalled successfully"
exit 0 