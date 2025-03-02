#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Main Management Script
# This script serves as the entry point for all FreeLIMS operations
# ----------------------------------------------------------------------------

VERSION="1.0.1"

# Determine the script and repository paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
SCRIPTS_DIR="$REPO_ROOT/scripts"

# Utility functions
print_banner() {
    echo "======================================"
    echo "  FreeLIMS Management Console v$VERSION"
    echo "======================================"
    echo "$(date)"
    echo "======================================"
}

print_usage() {
    echo "Usage: $0 [category] [environment] [command]"
    echo ""
    echo "Categories:"
    echo "  system      System management operations"
    echo "  db          Database management operations"
    echo "  user        User management operations"
    echo "  port        Port management operations"
    echo "  persistent  Persistent service management"
    echo ""
    echo "Environments:"
    echo "  dev         Development environment"
    echo "  prod        Production environment"
    echo "  all         Both environments"
    echo ""
    echo "System Commands:"
    echo "  start       Start the specified environment"
    echo "  stop        Stop the specified environment"
    echo "  restart     Restart the specified environment"
    echo "  status      Show the status of the environment"
    echo ""
    echo "Database Commands:"
    echo "  backup      Create a database backup"
    echo "  restore     Restore from a database backup"
    echo "  init        Initialize the database"
    echo "  migrate     Run database migrations"
    echo ""
    echo "User Commands:"
    echo "  list        List users in the database"
    echo "  create      Create a new user"
    echo "  delete      Delete a user"
    echo "  clear       Clear all users (optional: keep admin)"
    echo ""
    echo "Port Commands:"
    echo "  list        List port configurations"
    echo "  check       Check if ports are in use"
    echo "  free        Free up used ports"
    echo ""
    echo "Persistent Service Commands:"
    echo "  setup       Setup persistent services (create necessary files)"
    echo "  enable      Enable persistent services to run on startup"
    echo "  disable     Disable persistent services"
    echo "  monitor     Start the monitoring service in the background"
    echo "  stop-monitor Stop the monitoring service"
    echo ""
    echo "Examples:"
    echo "  $0 system dev start     # Start development environment"
    echo "  $0 system prod restart  # Restart production environment"
    echo "  $0 db dev backup        # Backup development database"
    echo "  $0 user dev clear       # Clear users from development database"
    echo "  $0 port list            # List port configurations"
    echo "  $0 persistent all setup # Setup persistent services for both environments"
    echo "  $0 persistent all monitor # Start monitoring service for all environments"
}

# Check if port_config.sh exists, source it
if [ -f "$REPO_ROOT/port_config.sh" ]; then
    source "$REPO_ROOT/port_config.sh"
else
    echo "Warning: port_config.sh not found. Port management will be limited."
fi

# Create log directory if it doesn't exist
mkdir -p "$REPO_ROOT/logs"

# Main logic
if [ $# -lt 2 ]; then
    print_banner
    print_usage
    exit 1
fi

CATEGORY=$1
ENVIRONMENT=$2
COMMAND=$3

# Validate environment (except for port and persistent category, which have their own validations)
if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ] && [ "$ENVIRONMENT" != "all" ] && [ "$CATEGORY" != "port" ] && [ "$CATEGORY" != "persistent" ]; then
    echo "Error: Invalid environment. Must be 'dev', 'prod', or 'all'."
    print_usage
    exit 1
fi

# Function to print formatted messages
print_status() {
    local status=$1
    local message=$2
    if [ "$status" == "success" ]; then
        echo -e "\033[0;32m[✓] $message\033[0m"
    elif [ "$status" == "warning" ]; then
        echo -e "\033[1;33m[!] $message\033[0m"
    elif [ "$status" == "error" ]; then
        echo -e "\033[0;31m[✗] $message\033[0m"
    else
        echo -e "[-] $message"
    fi
}

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$REPO_ROOT/logs/freelims.log"
}

# Setup persistent services
setup_persistent_services() {
    local env=$1
    local os_type=$(uname)

    if [[ "$os_type" == "Darwin" ]]; then
        # macOS setup
        setup_persistent_services_mac "$env"
    elif [[ "$os_type" == "Linux" ]]; then
        # Linux setup (assuming systemd)
        setup_persistent_services_linux "$env"
    else
        echo "Unsupported operating system: $os_type"
        return 1
    fi
}

# Setup persistent services for macOS
setup_persistent_services_mac() {
    local env=$1
    log "Setting up persistent services for macOS (LaunchAgent)..."
    echo "Setting up persistent services for macOS..."
    
    # Create necessary directories
    mkdir -p "$REPO_ROOT/launch_files"
    mkdir -p "$REPO_ROOT/scripts/system/dev"
    mkdir -p "$REPO_ROOT/scripts/system/prod"
    
    # Define LaunchAgents directory
    LAUNCH_AGENTS_DIR=~/Library/LaunchAgents
    
    # Create run scripts based on environment
    if [[ "$env" == "dev" || "$env" == "all" ]]; then
        # Create dev backend run script
        cat > "$REPO_ROOT/scripts/system/dev/run_dev_backend.sh" << EOF
#!/bin/bash
cd "$REPO_ROOT/backend"
source venv/bin/activate
cp .env.development .env
echo "ENVIRONMENT=development" >> .env
echo "PORT=8001" >> .env
exec uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
EOF
        chmod +x "$REPO_ROOT/scripts/system/dev/run_dev_backend.sh"
        
        # Create dev frontend run script
        cat > "$REPO_ROOT/scripts/system/dev/run_dev_frontend.sh" << EOF
#!/bin/bash
cd "$REPO_ROOT/frontend"
cat > .env.development.local << ENVEOF
REACT_APP_API_URL=http://localhost:8001/api
PORT=3001
ENVEOF
exec npm start
EOF
        chmod +x "$REPO_ROOT/scripts/system/dev/run_dev_frontend.sh"
        
        # Create launchd plist for dev backend
        cat > "$REPO_ROOT/launch_files/com.freelims.dev.backend.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.freelims.dev.backend</string>
    <key>ProgramArguments</key>
    <array>
        <string>$REPO_ROOT/scripts/system/dev/run_dev_backend.sh</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$REPO_ROOT</string>
    <key>StandardOutPath</key>
    <string>$REPO_ROOT/logs/dev_backend.log</string>
    <key>StandardErrorPath</key>
    <string>$REPO_ROOT/logs/dev_backend_error.log</string>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

        # Create launchd plist for dev frontend
        cat > "$REPO_ROOT/launch_files/com.freelims.dev.frontend.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.freelims.dev.frontend</string>
    <key>ProgramArguments</key>
    <array>
        <string>$REPO_ROOT/scripts/system/dev/run_dev_frontend.sh</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$REPO_ROOT</string>
    <key>StandardOutPath</key>
    <string>$REPO_ROOT/logs/dev_frontend.log</string>
    <key>StandardErrorPath</key>
    <string>$REPO_ROOT/logs/dev_frontend_error.log</string>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
        print_status "success" "Created dev environment service files"
    fi
    
    if [[ "$env" == "prod" || "$env" == "all" ]]; then
        # Create prod backend run script
        cat > "$REPO_ROOT/scripts/system/prod/run_prod_backend.sh" << EOF
#!/bin/bash
cd "$REPO_ROOT/backend"
source venv/bin/activate
cp .env.production .env
echo "ENVIRONMENT=production" >> .env
echo "PORT=8002" >> .env
exec gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8002
EOF
        chmod +x "$REPO_ROOT/scripts/system/prod/run_prod_backend.sh"
        
        # Create prod frontend run script
        cat > "$REPO_ROOT/scripts/system/prod/run_prod_frontend.sh" << EOF
#!/bin/bash
cd "$REPO_ROOT/frontend"
cat > .env.production.local << ENVEOF
REACT_APP_API_URL=http://localhost:8002/api
PORT=3002
NODE_ENV=production
ENVEOF
exec npx serve -s build -l 3002
EOF
        chmod +x "$REPO_ROOT/scripts/system/prod/run_prod_frontend.sh"
        
        # Create launchd plist for prod backend
        cat > "$REPO_ROOT/launch_files/com.freelims.prod.backend.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.freelims.prod.backend</string>
    <key>ProgramArguments</key>
    <array>
        <string>$REPO_ROOT/scripts/system/prod/run_prod_backend.sh</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$REPO_ROOT</string>
    <key>StandardOutPath</key>
    <string>$REPO_ROOT/logs/prod_backend.log</string>
    <key>StandardErrorPath</key>
    <string>$REPO_ROOT/logs/prod_backend_error.log</string>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

        # Create launchd plist for prod frontend
        cat > "$REPO_ROOT/launch_files/com.freelims.prod.frontend.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.freelims.prod.frontend</string>
    <key>ProgramArguments</key>
    <array>
        <string>$REPO_ROOT/scripts/system/prod/run_prod_frontend.sh</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$REPO_ROOT</string>
    <key>StandardOutPath</key>
    <string>$REPO_ROOT/logs/prod_frontend.log</string>
    <key>StandardErrorPath</key>
    <string>$REPO_ROOT/logs/prod_frontend_error.log</string>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
        print_status "success" "Created prod environment service files"
    fi
    
    echo ""
    print_status "success" "Persistent service files created in $REPO_ROOT/launch_files"
    echo ""
    echo "To enable these services, run:"
    echo "  $0 persistent $env enable"
    
    return 0
}

# Setup persistent services for Linux (systemd)
setup_persistent_services_linux() {
    local env=$1
    log "Setting up persistent services for Linux (systemd)..."
    echo "Setting up persistent services for Linux..."
    
    # Create necessary directories
    mkdir -p "$REPO_ROOT/service_files"
    mkdir -p "$REPO_ROOT/scripts/system/dev"
    mkdir -p "$REPO_ROOT/scripts/system/prod"
    
    # Create run scripts based on environment
    if [[ "$env" == "dev" || "$env" == "all" ]]; then
        # Create dev backend run script
        cat > "$REPO_ROOT/scripts/system/dev/run_dev_backend.sh" << EOF
#!/bin/bash
cd "$REPO_ROOT/backend"
source venv/bin/activate
cp .env.development .env
echo "ENVIRONMENT=development" >> .env
echo "PORT=8001" >> .env
uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
EOF
        chmod +x "$REPO_ROOT/scripts/system/dev/run_dev_backend.sh"
        
        # Create dev frontend run script
        cat > "$REPO_ROOT/scripts/system/dev/run_dev_frontend.sh" << EOF
#!/bin/bash
cd "$REPO_ROOT/frontend"
cat > .env.development.local << ENVEOF
REACT_APP_API_URL=http://localhost:8001/api
PORT=3001
ENVEOF
npm start
EOF
        chmod +x "$REPO_ROOT/scripts/system/dev/run_dev_frontend.sh"
        
        # Create systemd service file for dev backend
        cat > "$REPO_ROOT/service_files/freelims-dev-backend.service" << EOF
[Unit]
Description=FreeLIMS Development Backend
After=network.target postgresql.service

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$REPO_ROOT
ExecStart=$REPO_ROOT/scripts/system/dev/run_dev_backend.sh
Restart=always
RestartSec=10
StandardOutput=append:$REPO_ROOT/logs/dev_backend.log
StandardError=append:$REPO_ROOT/logs/dev_backend_error.log

[Install]
WantedBy=multi-user.target
EOF

        # Create systemd service file for dev frontend
        cat > "$REPO_ROOT/service_files/freelims-dev-frontend.service" << EOF
[Unit]
Description=FreeLIMS Development Frontend
After=network.target freelims-dev-backend.service

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$REPO_ROOT
ExecStart=$REPO_ROOT/scripts/system/dev/run_dev_frontend.sh
Restart=always
RestartSec=10
StandardOutput=append:$REPO_ROOT/logs/dev_frontend.log
StandardError=append:$REPO_ROOT/logs/dev_frontend_error.log

[Install]
WantedBy=multi-user.target
EOF
        print_status "success" "Created dev environment service files"
    fi
    
    if [[ "$env" == "prod" || "$env" == "all" ]]; then
        # Create systemd service file for prod backend
        cat > "$REPO_ROOT/service_files/freelims-prod-backend.service" << EOF
[Unit]
Description=FreeLIMS Production Backend
After=network.target postgresql.service

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$REPO_ROOT
ExecStart=/bin/bash -c 'cd $REPO_ROOT/backend && source venv/bin/activate && cp .env.production .env && echo "ENVIRONMENT=production" >> .env && echo "PORT=8002" >> .env && gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8002'
Restart=always
RestartSec=10
StandardOutput=append:$REPO_ROOT/logs/prod_backend.log
StandardError=append:$REPO_ROOT/logs/prod_backend_error.log

[Install]
WantedBy=multi-user.target
EOF

        # Create systemd service file for prod frontend
        cat > "$REPO_ROOT/service_files/freelims-prod-frontend.service" << EOF
[Unit]
Description=FreeLIMS Production Frontend
After=network.target freelims-prod-backend.service

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$REPO_ROOT/frontend
ExecStart=/bin/bash -c 'cd $REPO_ROOT/frontend && cat > .env.production.local << ENVEOF
REACT_APP_API_URL=http://localhost:8002/api
PORT=3002
NODE_ENV=production
ENVEOF
&& npx serve -s build -l 3002'
Restart=always
RestartSec=10
StandardOutput=append:$REPO_ROOT/logs/prod_frontend.log
StandardError=append:$REPO_ROOT/logs/prod_frontend_error.log

[Install]
WantedBy=multi-user.target
EOF
        print_status "success" "Created prod environment service files"
    fi
    
    echo ""
    print_status "success" "Persistent service files created in $REPO_ROOT/service_files"
    echo ""
    echo "To enable these services, run:"
    echo "  $0 persistent $env enable"
    
    return 0
}

# Enable persistent services
enable_persistent_services() {
    local env=$1
    local os_type=$(uname)
    
    if [[ "$os_type" == "Darwin" ]]; then
        # macOS enable
        enable_persistent_services_mac "$env"
    elif [[ "$os_type" == "Linux" ]]; then
        # Linux enable (assuming systemd)
        enable_persistent_services_linux "$env"
    else
        echo "Unsupported operating system: $os_type"
        return 1
    fi
}

# Enable persistent services for macOS
enable_persistent_services_mac() {
    local env=$1
    log "Enabling persistent services for macOS..."
    echo "Enabling persistent services for macOS..."
    
    # Define LaunchAgents directory
    LAUNCH_AGENTS_DIR=~/Library/LaunchAgents
    mkdir -p "$LAUNCH_AGENTS_DIR"
    
    # Copy and load plist files based on environment
    if [[ "$env" == "dev" || "$env" == "all" ]]; then
        cp "$REPO_ROOT/launch_files/com.freelims.dev.backend.plist" "$LAUNCH_AGENTS_DIR/"
        cp "$REPO_ROOT/launch_files/com.freelims.dev.frontend.plist" "$LAUNCH_AGENTS_DIR/"
        
        launchctl unload "$LAUNCH_AGENTS_DIR/com.freelims.dev.backend.plist" 2>/dev/null
        launchctl unload "$LAUNCH_AGENTS_DIR/com.freelims.dev.frontend.plist" 2>/dev/null
        
        launchctl load "$LAUNCH_AGENTS_DIR/com.freelims.dev.backend.plist"
        launchctl load "$LAUNCH_AGENTS_DIR/com.freelims.dev.frontend.plist"
        
        print_status "success" "Enabled dev environment services"
    fi
    
    if [[ "$env" == "prod" || "$env" == "all" ]]; then
        cp "$REPO_ROOT/launch_files/com.freelims.prod.backend.plist" "$LAUNCH_AGENTS_DIR/"
        cp "$REPO_ROOT/launch_files/com.freelims.prod.frontend.plist" "$LAUNCH_AGENTS_DIR/"
        
        launchctl unload "$LAUNCH_AGENTS_DIR/com.freelims.prod.backend.plist" 2>/dev/null
        launchctl unload "$LAUNCH_AGENTS_DIR/com.freelims.prod.frontend.plist" 2>/dev/null
        
        launchctl load "$LAUNCH_AGENTS_DIR/com.freelims.prod.backend.plist"
        launchctl load "$LAUNCH_AGENTS_DIR/com.freelims.prod.frontend.plist"
        
        print_status "success" "Enabled prod environment services"
    fi
    
    echo ""
    echo "Services will now start automatically on system boot."
    echo "To check current status, run:"
    echo "  launchctl list | grep freelims"
    echo ""
    echo "To check application status, run:"
    echo "  $0 system $env status"
    
    return 0
}

# Enable persistent services for Linux
enable_persistent_services_linux() {
    local env=$1
    log "Enabling persistent services for Linux..."
    echo "Enabling persistent services for Linux..."
    
    echo "To enable these services, you need root access."
    echo "Run the following commands manually:"
    echo ""
    
    if [[ "$env" == "dev" || "$env" == "all" ]]; then
        echo "sudo cp $REPO_ROOT/service_files/freelims-dev-backend.service /etc/systemd/system/"
        echo "sudo cp $REPO_ROOT/service_files/freelims-dev-frontend.service /etc/systemd/system/"
        echo "sudo systemctl daemon-reload"
        echo "sudo systemctl enable freelims-dev-backend.service"
        echo "sudo systemctl enable freelims-dev-frontend.service"
        echo "sudo systemctl start freelims-dev-backend.service"
        echo "sudo systemctl start freelims-dev-frontend.service"
    fi
    
    if [[ "$env" == "prod" || "$env" == "all" ]]; then
        echo "sudo cp $REPO_ROOT/service_files/freelims-prod-backend.service /etc/systemd/system/"
        echo "sudo cp $REPO_ROOT/service_files/freelims-prod-frontend.service /etc/systemd/system/"
        echo "sudo systemctl daemon-reload"
        echo "sudo systemctl enable freelims-prod-backend.service"
        echo "sudo systemctl enable freelims-prod-frontend.service"
        echo "sudo systemctl start freelims-prod-backend.service"
        echo "sudo systemctl start freelims-prod-frontend.service"
    fi
    
    echo ""
    echo "After running these commands, the services will start automatically on system boot."
    echo "To check current status, run:"
    echo "  systemctl status freelims-*"
    
    return 0
}

# Disable persistent services
disable_persistent_services() {
    local env=$1
    local os_type=$(uname)
    
    if [[ "$os_type" == "Darwin" ]]; then
        # macOS disable
        disable_persistent_services_mac "$env"
    elif [[ "$os_type" == "Linux" ]]; then
        # Linux disable (assuming systemd)
        disable_persistent_services_linux "$env"
    else
        echo "Unsupported operating system: $os_type"
        return 1
    fi
}

# Disable persistent services for macOS
disable_persistent_services_mac() {
    local env=$1
    log "Disabling persistent services for macOS..."
    echo "Disabling persistent services for macOS..."
    
    # Define LaunchAgents directory
    LAUNCH_AGENTS_DIR=~/Library/LaunchAgents
    
    # Unload plist files based on environment
    if [[ "$env" == "dev" || "$env" == "all" ]]; then
        launchctl unload "$LAUNCH_AGENTS_DIR/com.freelims.dev.backend.plist" 2>/dev/null
        launchctl unload "$LAUNCH_AGENTS_DIR/com.freelims.dev.frontend.plist" 2>/dev/null
        rm -f "$LAUNCH_AGENTS_DIR/com.freelims.dev.backend.plist"
        rm -f "$LAUNCH_AGENTS_DIR/com.freelims.dev.frontend.plist"
        print_status "success" "Disabled dev environment services"
    fi
    
    if [[ "$env" == "prod" || "$env" == "all" ]]; then
        launchctl unload "$LAUNCH_AGENTS_DIR/com.freelims.prod.backend.plist" 2>/dev/null
        launchctl unload "$LAUNCH_AGENTS_DIR/com.freelims.prod.frontend.plist" 2>/dev/null
        rm -f "$LAUNCH_AGENTS_DIR/com.freelims.prod.backend.plist"
        rm -f "$LAUNCH_AGENTS_DIR/com.freelims.prod.frontend.plist"
        print_status "success" "Disabled prod environment services"
    fi
    
    echo ""
    echo "Services will no longer start automatically on system boot."
    
    return 0
}

# Disable persistent services for Linux
disable_persistent_services_linux() {
    local env=$1
    log "Disabling persistent services for Linux..."
    echo "Disabling persistent services for Linux..."
    
    echo "To disable these services, you need root access."
    echo "Run the following commands manually:"
    echo ""
    
    if [[ "$env" == "dev" || "$env" == "all" ]]; then
        echo "sudo systemctl stop freelims-dev-backend.service"
        echo "sudo systemctl stop freelims-dev-frontend.service"
        echo "sudo systemctl disable freelims-dev-backend.service"
        echo "sudo systemctl disable freelims-dev-frontend.service"
        echo "sudo rm /etc/systemd/system/freelims-dev-backend.service"
        echo "sudo rm /etc/systemd/system/freelims-dev-frontend.service"
    fi
    
    if [[ "$env" == "prod" || "$env" == "all" ]]; then
        echo "sudo systemctl stop freelims-prod-backend.service"
        echo "sudo systemctl stop freelims-prod-frontend.service"
        echo "sudo systemctl disable freelims-prod-backend.service"
        echo "sudo systemctl disable freelims-prod-frontend.service"
        echo "sudo rm /etc/systemd/system/freelims-prod-backend.service"
        echo "sudo rm /etc/systemd/system/freelims-prod-frontend.service"
    fi
    
    echo ""
    echo "After running these commands, the services will no longer start automatically on system boot."
    
    return 0
}

# Setup and start the monitor service
setup_monitor_service() {
    local env=$1
    log "Setting up and starting the monitoring service..."
    echo "Setting up monitoring service for environment: $env"
    
    # Create the keep_alive script
    cat > "$REPO_ROOT/keep_alive.sh" << 'EOF'
#!/bin/bash

# Keep-alive script for FreeLIMS
# This script continuously checks if the FreeLIMS services are running
# and restarts them if they're not.

# Source port configuration
source ./port_config.sh

# Repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Log file
LOG_FILE="$REPO_ROOT/logs/keep_alive.log"
mkdir -p "$REPO_ROOT/logs"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Start development environment
start_dev() {
    log "Starting development environment..."
    cd "$REPO_ROOT"
    ./freelims.sh system dev start > /dev/null 2>&1
    log "Development environment startup completed."
}

# Start production environment
start_prod() {
    log "Starting production environment..."
    cd "$REPO_ROOT"
    ./freelims.sh system prod start > /dev/null 2>&1
    log "Production environment startup completed."
}

# Keep services alive
keep_alive() {
    local env="$1"
    
    while true; do
        if [[ "$env" == "dev" || "$env" == "all" ]]; then
            # Check development backend
            if ! is_port_in_use $DEV_BACKEND_PORT; then
                log "Development backend is not running. Restarting..."
                start_dev
            fi

            # Check development frontend
            if ! is_port_in_use $DEV_FRONTEND_PORT; then
                log "Development frontend is not running. Restarting..."
                start_dev
            fi
        fi
        
        if [[ "$env" == "prod" || "$env" == "all" ]]; then
            # Check production backend
            if ! is_port_in_use $PROD_BACKEND_PORT; then
                log "Production backend is not running. Restarting..."
                start_prod
            fi

            # Check production frontend
            if ! is_port_in_use $PROD_FRONTEND_PORT; then
                log "Production frontend is not running. Restarting..."
                start_prod
            fi
        fi

        # Sleep for 2 minutes before checking again
        log "All services checked at $(date). Sleeping for 2 minutes..."
        sleep 120
    done
}

# Main function
log "===== Starting keep-alive service at $(date) ====="
log "Monitoring environment: $1"

# Start the keep-alive loop with the specified environment
keep_alive "$1"
EOF
    chmod +x "$REPO_ROOT/keep_alive.sh"
    
    # Kill any existing keep-alive process
    pkill -f "keep_alive.sh" > /dev/null 2>&1
    
    # Start the keep-alive script in the background
    nohup "$REPO_ROOT/keep_alive.sh" "$env" > /dev/null 2>&1 &
    KEEP_ALIVE_PID=$!
    echo $KEEP_ALIVE_PID > "$REPO_ROOT/logs/keep_alive.pid"
    
    if ps -p $KEEP_ALIVE_PID > /dev/null; then
        print_status "success" "Monitoring service started with PID: $KEEP_ALIVE_PID"
        log "Monitoring service started with PID: $KEEP_ALIVE_PID"
    else
        print_status "error" "Failed to start monitoring service"
        log "Failed to start monitoring service"
        return 1
    fi
    
    echo ""
    echo "The monitoring service will continuously check if the $env services are running"
    echo "and automatically restart them if they stop."
    echo ""
    echo "To stop the monitoring service, run:"
    echo "  $0 persistent $env stop-monitor"
    
    return 0
}

# Stop the monitor service
stop_monitor_service() {
    log "Stopping the monitoring service..."
    echo "Stopping the monitoring service..."
    
    # Kill any existing keep-alive process
    if pkill -f "keep_alive.sh"; then
        print_status "success" "Monitoring service stopped"
        rm -f "$REPO_ROOT/logs/keep_alive.pid" 2>/dev/null
    else
        print_status "warning" "No monitoring service was running"
    fi
    
    return 0
}

# Handle persistent service management
manage_persistent_services() {
    local environment=$1
    local command=$2
    
    # Validate environment and command
    if [ "$environment" != "dev" ] && [ "$environment" != "prod" ] && [ "$environment" != "all" ]; then
        echo "Error: Invalid environment for persistent services. Must be 'dev', 'prod', or 'all'."
        return 1
    fi
    
    if [ -z "$command" ]; then
        echo "Error: Command is required for persistent service management."
        echo "Available commands: setup, enable, disable, monitor, stop-monitor"
        return 1
    fi
    
    case "$command" in
        setup)
            setup_persistent_services "$environment"
            ;;
        enable)
            enable_persistent_services "$environment"
            ;;
        disable)
            disable_persistent_services "$environment"
            ;;
        monitor)
            setup_monitor_service "$environment"
            ;;
        stop-monitor)
            stop_monitor_service
            ;;
        *)
            echo "Error: Invalid command for persistent service management."
            echo "Available commands: setup, enable, disable, monitor, stop-monitor"
            return 1
            ;;
    esac
    
    return $?
}

# Handle different categories
case "$CATEGORY" in
    system)
        # Load system management script
        if [ -f "$SCRIPTS_DIR/system/manage.sh" ]; then
            source "$SCRIPTS_DIR/system/manage.sh"
            manage_system "$ENVIRONMENT" "$COMMAND" "${@:4}"
        else
            echo "Error: System management script not found."
            exit 1
        fi
        ;;
    db)
        # Load database management script
        if [ -f "$SCRIPTS_DIR/db/manage.sh" ]; then
            source "$SCRIPTS_DIR/db/manage.sh"
            manage_database "$ENVIRONMENT" "$COMMAND" "${@:4}"
        else
            echo "Error: Database management script not found."
            exit 1
        fi
        ;;
    user)
        # Load user management script
        if [ -f "$SCRIPTS_DIR/user/manage.sh" ]; then
            source "$SCRIPTS_DIR/user/manage.sh"
            manage_users "$ENVIRONMENT" "$COMMAND" "${@:4}"
        else
            echo "Error: User management script not found."
            exit 1
        fi
        ;;
    port)
        # Load port management script
        if [ -f "$REPO_ROOT/port_config.sh" ]; then
            case "$ENVIRONMENT" in
                list)
                    show_port_config
                    ;;
                check)
                    PORT=$COMMAND
                    if [ -z "$PORT" ]; then
                        echo "Error: Please specify a port to check."
                        exit 1
                    fi
                    if is_port_in_use "$PORT"; then
                        echo "Port $PORT is in use."
                        get_process_on_port "$PORT"
                    else
                        echo "Port $PORT is free."
                    fi
                    ;;
                free)
                    PORT=$COMMAND
                    if [ -z "$PORT" ]; then
                        echo "Error: Please specify a port to free."
                        exit 1
                    fi
                    safe_kill_process_on_port "$PORT"
                    ;;
                *)
                    echo "Error: Invalid port command. Use 'list', 'check', or 'free'."
                    print_usage
                    exit 1
                    ;;
            esac
        else
            echo "Error: port_config.sh not found. Port management is not available."
            exit 1
        fi
        ;;
    persistent)
        # Handle persistent service management
        manage_persistent_services "$ENVIRONMENT" "$COMMAND" "${@:4}"
        ;;
    *)
        echo "Error: Invalid category. Use 'system', 'db', 'user', 'port', or 'persistent'."
        print_usage
        exit 1
        ;;
esac

exit 0 