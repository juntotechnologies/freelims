#!/bin/bash

# FreeLIMS Deployment Script
# This script automates the deployment of FreeLIMS to production

# Display header
echo "=========================================="
echo "FreeLIMS Production Deployment"
echo "=========================================="
echo "Started at: $(date)"
echo ""

# Define paths and settings
REPO_PATH="$(cd ../.. && pwd)"
BACKEND_PATH="$REPO_PATH/backend"
FRONTEND_PATH="$REPO_PATH/frontend"
SCRIPTS_PATH="$REPO_PATH/scripts"
LOG_PATH="$REPO_PATH/logs"
PROD_LOG="$LOG_PATH/deployment.log"
BACKUP_DIR="$REPO_PATH/backups/$(date +%Y%m%d_%H%M%S)"

# Create log directory if it doesn't exist
mkdir -p "$LOG_PATH"
mkdir -p "$BACKUP_DIR"

# Function to log messages
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$PROD_LOG"
}

# Function to handle errors
handle_error() {
    local message="$1"
    log_message "ERROR: $message"
    echo ""
    echo "Deployment failed. See $PROD_LOG for details."
    exit 1
}

# Backup existing database
backup_database() {
    log_message "Backing up database..."
    
    if [ -f "$SCRIPTS_PATH/maintenance/backup_freelims.sh" ]; then
        bash "$SCRIPTS_PATH/maintenance/backup_freelims.sh" "$BACKUP_DIR" || handle_error "Database backup failed"
        log_message "Database backup completed successfully to $BACKUP_DIR"
    else
        log_message "Backup script not found, skipping database backup"
    fi
}

# Stop production services
stop_services() {
    log_message "Stopping production services..."
    
    if [ -f "$SCRIPTS_PATH/deploy/stop_production.sh" ]; then
        bash "$SCRIPTS_PATH/deploy/stop_production.sh" || handle_error "Failed to stop services"
        log_message "Services stopped successfully"
    else
        log_message "Stop script not found, attempting manual stop"
        
        # Try to find and kill backend processes
        pkill -f "uvicorn.*app.main:app" || true
        
        # Try to find and kill frontend processes
        pkill -f "node.*serve -s build" || true
        
        log_message "Manual service stop attempted"
    fi
    
    # Wait for processes to stop
    sleep 3
}

# Update code from repository
update_code() {
    log_message "Updating code from repository..."
    
    # Save the current commit hash for potential rollback
    OLD_COMMIT=$(git rev-parse HEAD)
    echo "$OLD_COMMIT" > "$BACKUP_DIR/previous_commit.txt"
    
    # Pull the latest changes
    git pull || handle_error "Failed to pull latest code"
    
    log_message "Code updated successfully"
}

# Update backend
update_backend() {
    log_message "Updating backend..."
    
    cd "$BACKEND_PATH" || handle_error "Failed to access backend directory"
    
    # Activate virtual environment
    source venv/bin/activate || handle_error "Failed to activate virtual environment"
    
    # Install dependencies
    pip install -r requirements.txt || handle_error "Failed to install backend dependencies"
    
    # Run database migrations
    alembic upgrade head || handle_error "Failed to run database migrations"
    
    log_message "Backend updated successfully"
}

# Update frontend
update_frontend() {
    log_message "Updating frontend..."
    
    cd "$FRONTEND_PATH" || handle_error "Failed to access frontend directory"
    
    # Install dependencies
    npm install || handle_error "Failed to install frontend dependencies"
    
    # Build for production
    npm run build || handle_error "Failed to build frontend"
    
    log_message "Frontend updated successfully"
}

# Start production services
start_services() {
    log_message "Starting production services..."
    
    if [ -f "$SCRIPTS_PATH/deploy/start_production.sh" ]; then
        bash "$SCRIPTS_PATH/deploy/start_production.sh" || handle_error "Failed to start services"
        log_message "Services started successfully"
    else
        log_message "Start script not found, attempting manual start"
        
        # Start backend
        cd "$BACKEND_PATH" || handle_error "Failed to access backend directory"
        source venv/bin/activate
        nohup python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 > "$LOG_PATH/backend_prod.log" 2>&1 &
        
        # Start frontend
        cd "$FRONTEND_PATH" || handle_error "Failed to access frontend directory"
        nohup npx serve -s build -p 3000 > "$LOG_PATH/frontend_prod.log" 2>&1 &
        
        log_message "Manual service start attempted"
    fi
}

# Verify deployment
verify_deployment() {
    log_message "Verifying deployment..."
    
    # Wait for services to start
    sleep 5
    
    # Check backend
    if curl -s "http://localhost:8000/api/health" | grep -q "healthy"; then
        log_message "Backend verification successful"
    else
        handle_error "Backend verification failed"
    fi
    
    # Check if frontend is responding
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000/" | grep -q "200"; then
        log_message "Frontend verification successful"
    else
        handle_error "Frontend verification failed"
    fi
    
    log_message "Deployment verification successful"
}

# Main deployment process
main() {
    log_message "Starting deployment process"
    
    backup_database
    stop_services
    update_code
    update_backend
    update_frontend
    start_services
    verify_deployment
    
    log_message "Deployment completed successfully"
    
    echo ""
    echo "=========================================="
    echo "FreeLIMS has been successfully deployed!"
    echo "=========================================="
    echo ""
    echo "Frontend: http://localhost:3000"
    echo "Backend API: http://localhost:8000"
    echo "API Documentation: http://localhost:8000/docs"
    echo ""
    echo "If you need to rollback, use:"
    echo "git reset --hard $(cat "$BACKUP_DIR/previous_commit.txt")"
    echo ""
}

# Execute main function
main 