#!/bin/bash

# Script to configure FreeLIMS to start automatically at boot
# This script must be run as your normal user, not root

set -e

# Paths
FREELIMS_DIR="$HOME/Documents/GitHub/projects/freelims"
LOG_DIR="/Users/Shared/FreeLIMS/logs"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Create LaunchAgent for FreeLIMS
cat > ~/Library/LaunchAgents/com.freelims.startup.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.freelims.startup</string>
  <key>ProgramArguments</key>
  <array>
    <string>${FREELIMS_DIR}/freelims.sh</string>
    <string>system</string>
    <string>prod</string>
    <string>start</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
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
  <string>${FREELIMS_DIR}</string>
  <key>StandardOutPath</key>
  <string>${LOG_DIR}/freelims_startup.log</string>
  <key>StandardErrorPath</key>
  <string>${LOG_DIR}/freelims_startup_error.log</string>
  <key>StartInterval</key>
  <integer>300</integer>
</dict>
</plist>
EOF

# Unload if it exists already
launchctl unload ~/Library/LaunchAgents/com.freelims.startup.plist 2>/dev/null || true

# Load the agent
launchctl load ~/Library/LaunchAgents/com.freelims.startup.plist

# Create a script to check and restart FreeLIMS if needed
cat > "${FREELIMS_DIR}/scripts/system/setup/check_restart_freelims.sh" << EOF
#!/bin/bash

# Check if FreeLIMS services are running and restart if needed
BACKEND_RUNNING=\$(ps aux | grep gunicorn | grep -v grep | wc -l)
FRONTEND_RUNNING=\$(ps aux | grep "serve -s build -l 3002" | grep -v grep | wc -l)

if [ \$BACKEND_RUNNING -eq 0 ] || [ \$FRONTEND_RUNNING -eq 0 ]; then
  echo "\$(date): Restarting FreeLIMS services..." >> "${LOG_DIR}/freelims_watchdog.log"
  cd "${FREELIMS_DIR}"
  ./freelims.sh system prod restart
fi
EOF

# Make the check script executable
chmod +x "${FREELIMS_DIR}/scripts/system/setup/check_restart_freelims.sh"

# Create a LaunchAgent for the check script to run periodically
cat > ~/Library/LaunchAgents/com.freelims.watchdog.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.freelims.watchdog</string>
  <key>ProgramArguments</key>
  <array>
    <string>${FREELIMS_DIR}/scripts/system/setup/check_restart_freelims.sh</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>StartInterval</key>
  <integer>300</integer>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${LOG_DIR}/freelims_watchdog_out.log</string>
  <key>StandardErrorPath</key>
  <string>${LOG_DIR}/freelims_watchdog_error.log</string>
</dict>
</plist>
EOF

# Load the watchdog agent
launchctl unload ~/Library/LaunchAgents/com.freelims.watchdog.plist 2>/dev/null || true
launchctl load ~/Library/LaunchAgents/com.freelims.watchdog.plist

echo "FreeLIMS has been configured to start automatically at boot!"
echo "A watchdog service has also been set up to check every 5 minutes that FreeLIMS is running."
echo "All services will be running from the secure database location: /Users/Shared/FreeLIMS/" 