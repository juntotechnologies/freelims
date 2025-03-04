#!/bin/bash

# Script to configure PostgreSQL to use custom data directory
# This script must be run as your normal user, not root

set -e

FREELIMS_DIR="/Users/Shared/FreeLIMS"
PG_DATA_DIR="$FREELIMS_DIR/postgres_data"
LOG_DIR="$FREELIMS_DIR/logs"
PG_VERSION="15"

# Ensure directories exist
mkdir -p "$LOG_DIR"

# Stop PostgreSQL if it's running
brew services stop postgresql@$PG_VERSION || true

# Create a custom LaunchAgent
cat > ~/Library/LaunchAgents/homebrew.mxcl.postgresql@$PG_VERSION.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>homebrew.mxcl.postgresql@$PG_VERSION</string>
  <key>ProgramArguments</key>
  <array>
    <string>/opt/homebrew/opt/postgresql@$PG_VERSION/bin/postgres</string>
    <string>-D</string>
    <string>$PG_DATA_DIR</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>LC_ALL</key>
    <string>en_US.UTF-8</string>
    <key>LANG</key>
    <string>en_US.UTF-8</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>WorkingDirectory</key>
  <string>/opt/homebrew</string>
  <key>StandardOutPath</key>
  <string>$LOG_DIR/postgres.log</string>
  <key>StandardErrorPath</key>
  <string>$LOG_DIR/postgres_error.log</string>
  <key>HardResourceLimits</key>
  <dict>
    <key>NumberOfFiles</key>
    <integer>4096</integer>
  </dict>
  <key>SoftResourceLimits</key>
  <dict>
    <key>NumberOfFiles</key>
    <integer>4096</integer>
  </dict>
</dict>
</plist>
EOF

# Load the service
launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.postgresql@$PG_VERSION.plist 2>/dev/null || true
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.postgresql@$PG_VERSION.plist

# Wait a bit for PostgreSQL to start
sleep 3

# Check if PostgreSQL is running
if ps aux | grep postgres | grep -v grep | grep -q "$PG_DATA_DIR"; then
  echo "PostgreSQL is now running with data directory at $PG_DATA_DIR"
  echo "Databases will be stored securely on the Mac Mini's internal storage."
else
  echo "Error: PostgreSQL did not start properly. Check $LOG_DIR/postgres_error.log for details."
  exit 1
fi

# Check if the databases exist
if /opt/homebrew/opt/postgresql@$PG_VERSION/bin/psql -U shaun -lqt | cut -d \| -f 1 | grep -qw freelims; then
  echo "FreeLIMS production database is available."
else
  echo "Warning: FreeLIMS production database not found. You may need to restore it."
fi

if /opt/homebrew/opt/postgresql@$PG_VERSION/bin/psql -U shaun -lqt | cut -d \| -f 1 | grep -qw freelims_dev; then
  echo "FreeLIMS development database is available."
else
  echo "Warning: FreeLIMS development database not found. You may need to restore it."
fi

echo "PostgreSQL configuration complete!" 