#!/bin/bash

# FreeLIMS Service Installer
# This script installs the FreeLIMS service to run at system startup

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SERVICE_SCRIPT="$SCRIPT_DIR/freelims_service.sh"
PLIST_FILE="$SCRIPT_DIR/com.freelims.service.plist"
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

# Check if service script exists
if [ ! -f "$SERVICE_SCRIPT" ]; then
    log "error" "Service script not found at: $SERVICE_SCRIPT"
    exit 1
fi

# Check if plist file exists
if [ ! -f "$PLIST_FILE" ]; then
    log "error" "LaunchDaemon plist file not found at: $PLIST_FILE"
    exit 1
fi

# Make sure run scripts are executable
chmod +x "$REPO_ROOT/run_dev.sh"
chmod +x "$REPO_ROOT/run_prod.sh"
chmod +x "$SERVICE_SCRIPT"

# Check if service is already installed
if [ -f "$SYSTEM_PLIST_PATH" ]; then
    log "warn" "FreeLIMS service is already installed"
    read -p "Do you want to reinstall? (y/n): " REINSTALL
    if [[ "$REINSTALL" =~ ^[Yy]$ ]]; then
        log "info" "Unloading existing service..."
        launchctl unload "$SYSTEM_PLIST_PATH"
        rm "$SYSTEM_PLIST_PATH"
    else
        log "info" "Installation canceled"
        exit 0
    fi
fi

# Copy the plist file to LaunchDaemons
log "info" "Installing FreeLIMS service..."
cp "$PLIST_FILE" "$SYSTEM_PLIST_PATH"

# Set correct permissions
chown root:wheel "$SYSTEM_PLIST_PATH"
chmod 644 "$SYSTEM_PLIST_PATH"

# Load the service
log "info" "Loading FreeLIMS service..."
launchctl load "$SYSTEM_PLIST_PATH"

# Check if service loaded successfully
sleep 2
SERVICE_STATUS=$(launchctl list | grep com.freelims.service || echo "")
if [ -n "$SERVICE_STATUS" ]; then
    log "info" "FreeLIMS service installed and loaded successfully!"
    log "info" "The service will now run at system startup and persist through logouts."
    log "info" "Development environment available at: http://localhost:3001"
    log "info" "Production environment available at: http://localhost:3002"
else
    log "error" "Failed to load FreeLIMS service. Check system logs for details."
    exit 1
fi

exit 0 