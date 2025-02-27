#!/bin/bash

# FreeLIMS Deployment Setup Script
# This script sets up the complete FreeLIMS deployment workflow

# Display header
echo "===================================="
echo "FreeLIMS Deployment Setup"
echo "===================================="
echo "Started at: $(date)"
echo ""

# Define paths
DEV_PATH="/Users/shaun/Documents/GitHub/projects/freelims"
PROD_PATH="/Users/Shared/SDrive/freelims_production"
DB_PATH="/Users/Shared/SDrive/freelims_db"
BACKUP_PATH="/Users/Shared/ADrive/freelims_backups"
LOG_PATH="/Users/Shared/SDrive/freelims_logs"
LAUNCHD_PATH="$HOME/Library/LaunchAgents"

# Create required directories
echo "Creating required directories..."
mkdir -p "$PROD_PATH"
mkdir -p "$DB_PATH"
mkdir -p "$BACKUP_PATH"
mkdir -p "$LOG_PATH"
mkdir -p "$LAUNCHD_PATH"

# Make all scripts executable
echo "Making scripts executable..."
chmod +x deploy.sh
chmod +x start_production.sh
chmod +x stop_production.sh
chmod +x backup_freelims.sh
chmod +x check_sensitive_info.sh
# Keep these scripts available but don't use them in automation
chmod +x auto_commit_push.sh
chmod +x scheduled_commit.sh

# Copy scripts to production directory
echo "Copying scripts to production directory..."
cp deploy.sh "$PROD_PATH/"
cp start_production.sh "$PROD_PATH/"
cp stop_production.sh "$PROD_PATH/"
cp backup_freelims.sh "$PROD_PATH/"

# Install the enhanced .gitignore
echo "Installing enhanced .gitignore..."
if [ -f .gitignore ]; then
    echo "Backing up existing .gitignore..."
    cp .gitignore .gitignore.bak
fi
cp .gitignore-enhanced .gitignore

# Install launchd services (excluding autocommit)
echo "Installing launchd services..."
cp com.freelims.app.plist "$LAUNCHD_PATH/"
cp com.freelims.backup.plist "$LAUNCHD_PATH/"
# Removed: cp com.freelims.autocommit.plist "$LAUNCHD_PATH/"

# Load launchd services (excluding autocommit)
echo "Loading launchd services..."
launchctl load "$LAUNCHD_PATH/com.freelims.app.plist"
launchctl load "$LAUNCHD_PATH/com.freelims.backup.plist"
# Removed: launchctl load "$LAUNCHD_PATH/com.freelims.autocommit.plist"

# Run the initial deployment
echo "Running initial deployment..."
./deploy.sh

echo ""
echo "Setup completed successfully!"
echo "FreeLIMS deployment workflow is now configured."
echo ""
echo "Usage guide:"
echo "- To deploy changes from dev to production: ./deploy.sh"
echo "- To start the production server: ./start_production.sh"
echo "- To stop the production server: ./stop_production.sh"
echo "- To run a security check for sensitive info: ./check_sensitive_info.sh"
echo "- To manually check and commit changes: git status, git add, git commit, git push"
echo ""
echo "Automated processes:"
echo "- The application will start automatically on system boot"
echo "- Backups run automatically at 2 AM daily"
echo "- Git commits and pushes must be performed manually"
echo "=====================================" 