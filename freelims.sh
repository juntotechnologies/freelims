#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Main Management Script
# This script serves as the entry point for all FreeLIMS operations
# ----------------------------------------------------------------------------

VERSION="1.2.0"

# Determine the script and repository paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
SCRIPTS_DIR="$REPO_ROOT/scripts"
UTILS_DIR="$REPO_ROOT/scripts/utils"

# Source the Git environment selector if it exists
if [ -f "$UTILS_DIR/git_env_selector.sh" ]; then
    source "$UTILS_DIR/git_env_selector.sh"
fi

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
    echo "  auto        Auto-detect environment based on Git branch"
    echo "               (main/master -> prod, develop -> dev)"
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
    echo "  $0 system auto start    # Start environment based on current Git branch"
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

# Git branch-based environment auto-detection
if [ "$ENVIRONMENT" == "auto" ]; then
    # Check if git_env_selector.sh was successfully sourced
    if [ "$(type -t select_environment)" != "function" ]; then
        echo "Error: Git environment selector not available. Unable to auto-detect environment."
        echo "Please manually specify 'dev' or 'prod' as the environment."
        exit 1
    fi
    
    # Get the current branch and select environment
    CURRENT_BRANCH=$(get_current_branch)
    DETECTED_ENV=$(select_environment)
    
    echo "Auto-detected Git branch: $CURRENT_BRANCH"
    echo "Using environment: $DETECTED_ENV"
    
    # Update ENVIRONMENT variable
    ENVIRONMENT=$DETECTED_ENV
fi

# Validate environment (except for port and persistent category, which have their own validations)
if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ] && [ "$ENVIRONMENT" != "all" ] && [ "$CATEGORY" != "port" ] && [ "$CATEGORY" != "persistent" ]; then
    echo "Error: Invalid environment. Must be 'dev', 'prod', 'all', or 'auto'."
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

# Log function with better formatting
log() {
    local message="$1"
    local log_file="$REPO_ROOT/logs/freelims.log"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$timestamp] $message" | tee -a "$log_file"
}

# Error handling function
handle_error() {
    local message="$1"
    local exit_code="${2:-1}"  # Default exit code is 1
    
    print_status "error" "$message"
    log "ERROR: $message"
    
    if [ "$exit_code" != "continue" ]; then
        exit "$exit_code"
    fi
}

# Success message function
print_success() {
    local message="$1"
    print_status "success" "$message"
    log "SUCCESS: $message"
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
    mkdir -p "$REPO_ROOT/launch_files" || handle_error "Failed to create launch_files directory"
    mkdir -p "$REPO_ROOT/scripts/system/dev" || handle_error "Failed to create dev scripts directory"
    mkdir -p "$REPO_ROOT/scripts/system/prod" || handle_error "Failed to create prod scripts directory"
    mkdir -p "$REPO_ROOT/logs" || handle_error "Failed to create logs directory"
    
    # Define LaunchAgents directory
    LAUNCH_AGENTS_DIR=~/Library/LaunchAgents
    
    # Common function to create run script
    create_run_script() {
        local env_type=$1
        local script_path="$REPO_ROOT/scripts/system/$env_type/run_${env_type}_backend.sh"
        local port_var="${env_type^^}_BACKEND_PORT"  # Convert to uppercase
        local port=${!port_var:-8001}  # Default to 8001 if not defined
        
        if [[ "$env_type" == "dev" ]]; then
            # Create dev backend run script
            cat > "$script_path" << EOF
#!/bin/bash
cd "$REPO_ROOT/backend"
source venv/bin/activate
cp .env.development .env
echo "ENVIRONMENT=development" >> .env
echo "PORT=$port" >> .env
exec uvicorn app.main:app --reload --host 0.0.0.0 --port $port
EOF
        else
            # Create prod backend run script
            cat > "$script_path" << EOF
#!/bin/bash
cd "$REPO_ROOT/backend"
source venv/bin/activate
cp .env.production .env
echo "ENVIRONMENT=production" >> .env
echo "PORT=$port" >> .env
exec gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:$port
EOF
        fi
        chmod +x "$script_path" || handle_error "Failed to make script executable: $script_path"
        
        # Create frontend run script
        port_var="${env_type^^}_FRONTEND_PORT"  # Convert to uppercase
        port=${!port_var:-3001}  # Default to 3001 if not defined
        script_path="$REPO_ROOT/scripts/system/$env_type/run_${env_type}_frontend.sh"
        
        if [[ "$env_type" == "dev" ]]; then
            cat > "$script_path" << EOF
#!/bin/bash
cd "$REPO_ROOT/frontend"
cat > .env.development.local << ENVEOF
REACT_APP_API_URL=http://localhost:$DEV_BACKEND_PORT/api
PORT=$port
ENVEOF
exec npm start
EOF
        else
            cat > "$script_path" << EOF
#!/bin/bash
cd "$REPO_ROOT/frontend"
cat > .env.production.local << ENVEOF
REACT_APP_API_URL=http://localhost:$PROD_BACKEND_PORT/api
PORT=$port
NODE_ENV=production
ENVEOF
exec npx serve -s build -l $port
EOF
        fi
        chmod +x "$script_path" || handle_error "Failed to make script executable: $script_path"
    }
    
    # Common function to create plist file
    create_plist_file() {
        local env_type=$1
        local component=$2  # backend or frontend
        local label="com.freelims.$env_type.$component"
        local script_path="$REPO_ROOT/scripts/system/$env_type/run_${env_type}_${component}.sh"
        local plist_path="$REPO_ROOT/launch_files/$label.plist"
        
        cat > "$plist_path" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$label</string>
    <key>ProgramArguments</key>
    <array>
        <string>$script_path</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$REPO_ROOT</string>
    <key>StandardOutPath</key>
    <string>$REPO_ROOT/logs/${env_type}_${component}.log</string>
    <key>StandardErrorPath</key>
    <string>$REPO_ROOT/logs/${env_type}_${component}_error.log</string>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
    }
    
    # Create run scripts and plist files based on environment
    if [[ "$env" == "dev" || "$env" == "all" ]]; then
        create_run_script "dev"
        create_plist_file "dev" "backend"
        create_plist_file "dev" "frontend"
        print_success "Created dev environment service files"
    fi
    
    if [[ "$env" == "prod" || "$env" == "all" ]]; then
        create_run_script "prod"
        create_plist_file "prod" "backend"
        create_plist_file "prod" "frontend"
        print_success "Created prod environment service files"
    fi
    
    echo ""
    print_success "Persistent service files created in $REPO_ROOT/launch_files"
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
    mkdir -p "$REPO_ROOT/service_files" || handle_error "Failed to create service_files directory"
    mkdir -p "$REPO_ROOT/scripts/system/dev" || handle_error "Failed to create dev scripts directory"
    mkdir -p "$REPO_ROOT/scripts/system/prod" || handle_error "Failed to create prod scripts directory"
    mkdir -p "$REPO_ROOT/logs" || handle_error "Failed to create logs directory"
    
    # Common function to create run script
    create_run_script() {
        local env_type=$1
        local script_path="$REPO_ROOT/scripts/system/$env_type/run_${env_type}_backend.sh"
        local port_var="${env_type^^}_BACKEND_PORT"  # Convert to uppercase
        local port=${!port_var:-8001}  # Default to 8001 if not defined
        
        if [[ "$env_type" == "dev" ]]; then
            # Create dev backend run script
            cat > "$script_path" << EOF
#!/bin/bash
cd "$REPO_ROOT/backend"
source venv/bin/activate
cp .env.development .env
echo "ENVIRONMENT=development" >> .env
echo "PORT=$port" >> .env
uvicorn app.main:app --reload --host 0.0.0.0 --port $port
EOF
        else
            # Create prod backend run script
            cat > "$script_path" << EOF
#!/bin/bash
cd "$REPO_ROOT/backend"
source venv/bin/activate
cp .env.production .env
echo "ENVIRONMENT=production" >> .env
echo "PORT=$port" >> .env
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:$port
EOF
        fi
        chmod +x "$script_path" || handle_error "Failed to make script executable: $script_path"
        
        # Create frontend run script
        port_var="${env_type^^}_FRONTEND_PORT"  # Convert to uppercase
        port=${!port_var:-3001}  # Default to 3001 if not defined
        script_path="$REPO_ROOT/scripts/system/$env_type/run_${env_type}_frontend.sh"
        
        if [[ "$env_type" == "dev" ]]; then
            cat > "$script_path" << EOF
#!/bin/bash
cd "$REPO_ROOT/frontend"
cat > .env.development.local << ENVEOF
REACT_APP_API_URL=http://localhost:$DEV_BACKEND_PORT/api
PORT=$port
ENVEOF
npm start
EOF
        else
            cat > "$script_path" << EOF
#!/bin/bash
cd "$REPO_ROOT/frontend"
cat > .env.production.local << ENVEOF
REACT_APP_API_URL=http://localhost:$PROD_BACKEND_PORT/api
PORT=$port
NODE_ENV=production
ENVEOF
npx serve -s build -l $port
EOF
        fi
        chmod +x "$script_path" || handle_error "Failed to make script executable: $script_path"
    }
    
    # Common function to create systemd service file
    create_service_file() {
        local env_type=$1
        local component=$2  # backend or frontend
        local label="freelims-$env_type-$component"
        local script_path="$REPO_ROOT/scripts/system/$env_type/run_${env_type}_${component}.sh"
        local service_path="$REPO_ROOT/service_files/$label.service"
        local after_service="network.target"
        
        if [[ "$component" == "frontend" ]]; then
            after_service="network.target freelims-$env_type-backend.service"
        fi
        
        if [[ "$component" == "backend" ]]; then
            cat > "$service_path" << EOF
[Unit]
Description=FreeLIMS ${env_type^} Backend
After=$after_service postgresql.service

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$REPO_ROOT
ExecStart=$script_path
Restart=always
RestartSec=10
StandardOutput=append:$REPO_ROOT/logs/${env_type}_${component}.log
StandardError=append:$REPO_ROOT/logs/${env_type}_${component}_error.log

[Install]
WantedBy=multi-user.target
EOF
        else
            cat > "$service_path" << EOF
[Unit]
Description=FreeLIMS ${env_type^} Frontend
After=$after_service

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$REPO_ROOT
ExecStart=$script_path
Restart=always
RestartSec=10
StandardOutput=append:$REPO_ROOT/logs/${env_type}_${component}.log
StandardError=append:$REPO_ROOT/logs/${env_type}_${component}_error.log

[Install]
WantedBy=multi-user.target
EOF
        fi
    }
    
    # Create run scripts and service files based on environment
    if [[ "$env" == "dev" || "$env" == "all" ]]; then
        create_run_script "dev"
        create_service_file "dev" "backend"
        create_service_file "dev" "frontend"
        print_success "Created dev environment service files"
    fi
    
    if [[ "$env" == "prod" || "$env" == "all" ]]; then
        create_run_script "prod"
        create_service_file "prod" "backend"
        create_service_file "prod" "frontend"
        print_success "Created prod environment service files"
    fi
    
    echo ""
    print_success "Persistent service files created in $REPO_ROOT/service_files"
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
    mkdir -p "$LAUNCH_AGENTS_DIR" || handle_error "Failed to create LaunchAgents directory"
    
    # Copy and load plist files based on environment
    if [[ "$env" == "dev" || "$env" == "all" ]]; then
        cp "$REPO_ROOT/launch_files/com.freelims.dev.backend.plist" "$LAUNCH_AGENTS_DIR/" || 
            handle_error "Failed to copy dev backend plist file" "continue"
        cp "$REPO_ROOT/launch_files/com.freelims.dev.frontend.plist" "$LAUNCH_AGENTS_DIR/" || 
            handle_error "Failed to copy dev frontend plist file" "continue"
        
        launchctl unload "$LAUNCH_AGENTS_DIR/com.freelims.dev.backend.plist" 2>/dev/null
        launchctl unload "$LAUNCH_AGENTS_DIR/com.freelims.dev.frontend.plist" 2>/dev/null
        
        if launchctl load "$LAUNCH_AGENTS_DIR/com.freelims.dev.backend.plist"; then
            log "Loaded dev backend service"
        else
            print_status "warning" "Failed to load dev backend service"
        fi
        
        if launchctl load "$LAUNCH_AGENTS_DIR/com.freelims.dev.frontend.plist"; then
            log "Loaded dev frontend service"
        else
            print_status "warning" "Failed to load dev frontend service"
        fi
        
        print_success "Enabled dev environment services"
    fi
    
    if [[ "$env" == "prod" || "$env" == "all" ]]; then
        cp "$REPO_ROOT/launch_files/com.freelims.prod.backend.plist" "$LAUNCH_AGENTS_DIR/" || 
            handle_error "Failed to copy prod backend plist file" "continue"
        cp "$REPO_ROOT/launch_files/com.freelims.prod.frontend.plist" "$LAUNCH_AGENTS_DIR/" || 
            handle_error "Failed to copy prod frontend plist file" "continue"
        
        launchctl unload "$LAUNCH_AGENTS_DIR/com.freelims.prod.backend.plist" 2>/dev/null
        launchctl unload "$LAUNCH_AGENTS_DIR/com.freelims.prod.frontend.plist" 2>/dev/null
        
        if launchctl load "$LAUNCH_AGENTS_DIR/com.freelims.prod.backend.plist"; then
            log "Loaded prod backend service"
        else
            print_status "warning" "Failed to load prod backend service"
        fi
        
        if launchctl load "$LAUNCH_AGENTS_DIR/com.freelims.prod.frontend.plist"; then
            log "Loaded prod frontend service"
        else
            print_status "warning" "Failed to load prod frontend service"
        fi
        
        print_success "Enabled prod environment services"
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
        if launchctl unload "$LAUNCH_AGENTS_DIR/com.freelims.dev.backend.plist" 2>/dev/null; then
            log "Unloaded dev backend service"
        else
            log "Dev backend service was not loaded"
        fi
        
        if launchctl unload "$LAUNCH_AGENTS_DIR/com.freelims.dev.frontend.plist" 2>/dev/null; then
            log "Unloaded dev frontend service"
        else
            log "Dev frontend service was not loaded"
        fi
        
        # Remove plist files
        rm -f "$LAUNCH_AGENTS_DIR/com.freelims.dev.backend.plist"
        rm -f "$LAUNCH_AGENTS_DIR/com.freelims.dev.frontend.plist"
        
        print_success "Disabled dev environment services"
    fi
    
    if [[ "$env" == "prod" || "$env" == "all" ]]; then
        if launchctl unload "$LAUNCH_AGENTS_DIR/com.freelims.prod.backend.plist" 2>/dev/null; then
            log "Unloaded prod backend service"
        else
            log "Prod backend service was not loaded"
        fi
        
        if launchctl unload "$LAUNCH_AGENTS_DIR/com.freelims.prod.frontend.plist" 2>/dev/null; then
            log "Unloaded prod frontend service"
        else
            log "Prod frontend service was not loaded"
        fi
        
        # Remove plist files
        rm -f "$LAUNCH_AGENTS_DIR/com.freelims.prod.backend.plist"
        rm -f "$LAUNCH_AGENTS_DIR/com.freelims.prod.frontend.plist"
        
        print_success "Disabled prod environment services"
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
    
    # Check if port_config.sh exists and is accessible
    if [ ! -f "$REPO_ROOT/port_config.sh" ]; then
        handle_error "port_config.sh not found. Cannot start monitoring service." "continue"
        print_status "warning" "Creating basic port configuration..."
        cat > "$REPO_ROOT/port_config.sh" << 'EOF'
#!/bin/bash
# FreeLIMS Port Configuration (auto-generated)
DEV_BACKEND_PORT=8001
DEV_FRONTEND_PORT=3001
PROD_BACKEND_PORT=8002
PROD_FRONTEND_PORT=3002

# Check if a port is in use
is_port_in_use() {
    local port=$1
    if lsof -i :$port -t >/dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}
EOF
        chmod +x "$REPO_ROOT/port_config.sh" || handle_error "Failed to make port_config.sh executable"
    fi
    
    # Ensure log directory exists
    mkdir -p "$REPO_ROOT/logs" || handle_error "Failed to create logs directory"
    
    # Create the keep_alive script with better error handling
    cat > "$REPO_ROOT/keep_alive.sh" << 'EOF'
#!/bin/bash

# Keep-alive script for FreeLIMS
# This script continuously checks if the FreeLIMS services are running
# and restarts them if they're not.

# Source port configuration
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$REPO_ROOT/port_config.sh" ]; then
    source "$REPO_ROOT/port_config.sh"
else
    echo "ERROR: port_config.sh not found. Monitoring service will exit."
    exit 1
fi

# Set default ports if not defined
DEV_BACKEND_PORT=${DEV_BACKEND_PORT:-8001}
DEV_FRONTEND_PORT=${DEV_FRONTEND_PORT:-3001}
PROD_BACKEND_PORT=${PROD_BACKEND_PORT:-8002}
PROD_FRONTEND_PORT=${PROD_FRONTEND_PORT:-3002}

# Log file
LOG_FILE="$REPO_ROOT/logs/keep_alive.log"
mkdir -p "$REPO_ROOT/logs"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to check if a process is running
check_process() {
    local pid=$1
    if [ -n "$pid" ] && ps -p "$pid" > /dev/null; then
        return 0  # Process is running
    else
        return 1  # Process is not running
    fi
}

# Start development environment
start_dev() {
    log "Starting development environment..."
    cd "$REPO_ROOT"
    ./freelims.sh system dev start > /dev/null 2>&1
    local status=$?
    if [ $status -eq 0 ]; then
        log "Development environment startup completed successfully."
    else
        log "WARNING: Development environment startup failed with status $status."
    fi
}

# Start production environment
start_prod() {
    log "Starting production environment..."
    cd "$REPO_ROOT"
    ./freelims.sh system prod start > /dev/null 2>&1
    local status=$?
    if [ $status -eq 0 ]; then
        log "Production environment startup completed successfully."
    else
        log "WARNING: Production environment startup failed with status $status."
    fi
}

# Keep services alive
keep_alive() {
    local env="$1"
    local restart_attempts=0
    local max_restart_attempts=5
    local restart_cooldown=300  # 5 minutes
    
    log "Starting keep-alive service for environment: $env"
    
    while true; do
        local restart_needed=false
        
        if [[ "$env" == "dev" || "$env" == "all" ]]; then
            # Check development backend
            if ! is_port_in_use $DEV_BACKEND_PORT; then
                log "Development backend is not running on port $DEV_BACKEND_PORT."
                restart_needed=true
            fi

            # Check development frontend
            if ! is_port_in_use $DEV_FRONTEND_PORT; then
                log "Development frontend is not running on port $DEV_FRONTEND_PORT."
                restart_needed=true
            fi
            
            if [ "$restart_needed" = true ]; then
                if [ $restart_attempts -lt $max_restart_attempts ]; then
                    log "Restarting development environment (attempt $((restart_attempts+1))/$max_restart_attempts)..."
                    start_dev
                    restart_attempts=$((restart_attempts+1))
                else
                    log "WARNING: Maximum restart attempts ($max_restart_attempts) reached for development environment. Cooling down for $restart_cooldown seconds."
                    sleep $restart_cooldown
                    restart_attempts=0
                fi
            else
                restart_attempts=0  # Reset counter if everything is running
            fi
        fi
        
        restart_needed=false
        
        if [[ "$env" == "prod" || "$env" == "all" ]]; then
            # Check production backend
            if ! is_port_in_use $PROD_BACKEND_PORT; then
                log "Production backend is not running on port $PROD_BACKEND_PORT."
                restart_needed=true
            fi

            # Check production frontend
            if ! is_port_in_use $PROD_FRONTEND_PORT; then
                log "Production frontend is not running on port $PROD_FRONTEND_PORT."
                restart_needed=true
            fi
            
            if [ "$restart_needed" = true ]; then
                if [ $restart_attempts -lt $max_restart_attempts ]; then
                    log "Restarting production environment (attempt $((restart_attempts+1))/$max_restart_attempts)..."
                    start_prod
                    restart_attempts=$((restart_attempts+1))
                else
                    log "WARNING: Maximum restart attempts ($max_restart_attempts) reached for production environment. Cooling down for $restart_cooldown seconds."
                    sleep $restart_cooldown
                    restart_attempts=0
                fi
            else
                restart_attempts=0  # Reset counter if everything is running
            fi
        fi

        # Sleep before checking again
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
    chmod +x "$REPO_ROOT/keep_alive.sh" || handle_error "Failed to make keep_alive.sh executable" "continue"
    
    # Kill any existing keep-alive process
    pkill -f "keep_alive.sh" > /dev/null 2>&1
    
    # Start the keep-alive script in the background
    nohup "$REPO_ROOT/keep_alive.sh" "$env" > /dev/null 2>&1 &
    KEEP_ALIVE_PID=$!
    
    if check_process $KEEP_ALIVE_PID; then
        echo $KEEP_ALIVE_PID > "$REPO_ROOT/logs/keep_alive.pid"
        print_success "Monitoring service started with PID: $KEEP_ALIVE_PID"
        log "Monitoring service started with PID: $KEEP_ALIVE_PID"
    else
        handle_error "Failed to start monitoring service" "continue"
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

# Add a helper function to check if a process is running
check_process() {
    local pid=$1
    if [ -n "$pid" ] && ps -p "$pid" > /dev/null; then
        return 0  # Process is running
    else
        return 1  # Process is not running
    fi
}

# Stop the monitor service
stop_monitor_service() {
    log "Stopping the monitoring service..."
    echo "Stopping the monitoring service..."
    
    # Get the PID from file if it exists
    local pid_file="$REPO_ROOT/logs/keep_alive.pid"
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if check_process "$pid"; then
            kill "$pid" 2>/dev/null
            log "Killed monitoring service with PID: $pid"
        else
            log "PID file exists but process $pid is not running"
        fi
        rm -f "$pid_file"
    fi
    
    # Kill any remaining keep-alive processes
    if pkill -f "keep_alive.sh"; then
        print_success "Monitoring service stopped"
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
        handle_error "Invalid environment for persistent services. Must be 'dev', 'prod', or 'all'."
        return 1
    fi
    
    if [ -z "$command" ]; then
        handle_error "Command is required for persistent service management. Available commands: setup, enable, disable, monitor, stop-monitor"
        return 1
    fi
    
    log "Executing persistent service command: $command for environment: $environment"
    
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
            handle_error "Invalid command for persistent service management. Available commands: setup, enable, disable, monitor, stop-monitor"
            return 1
            ;;
    esac
    
    local status=$?
    if [ $status -eq 0 ]; then
        log "Command '$command' completed successfully for environment: $environment"
    else
        log "Command '$command' failed with status $status for environment: $environment"
    fi
    
    return $status
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