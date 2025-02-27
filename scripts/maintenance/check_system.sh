#!/bin/bash

# FreeLIMS System Check Script
# This script checks the health of the FreeLIMS production environment

# Display header
echo "=========================================="
echo "FreeLIMS System Health Check"
echo "=========================================="
echo "Started at: $(date)"
echo ""

# Define paths and settings
REPO_PATH="$(pwd)"
BACKEND_PATH="$REPO_PATH/backend"
FRONTEND_PATH="$REPO_PATH/frontend"
LOG_PATH="$REPO_PATH/logs"
SYSTEM_LOG="$LOG_PATH/system_check.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_PATH"

# Function to log messages
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$SYSTEM_LOG"
}

# Function to handle errors
handle_error() {
    local message="$1"
    log_message "ERROR: $message"
}

# Function to check if a service is running
check_service() {
    local service_name="$1"
    local grep_pattern="$2"
    local expected_port="$3"
    
    log_message "Checking $service_name..."
    
    # Check if process is running
    if pgrep -f "$grep_pattern" > /dev/null; then
        log_message "✓ $service_name process is running"
        
        # Check if port is in use
        if [ -n "$expected_port" ]; then
            if lsof -i :"$expected_port" > /dev/null 2>&1; then
                log_message "✓ $service_name is listening on port $expected_port"
            else
                handle_error "$service_name process is running but not listening on port $expected_port"
            fi
        fi
    else
        handle_error "$service_name process is not running"
    fi
}

# Function to check disk space
check_disk_space() {
    log_message "Checking disk space..."
    
    # Get disk usage for the repository
    local disk_usage=$(df -h "$REPO_PATH" | awk 'NR==2 {print $5}')
    local disk_usage_number=$(echo "$disk_usage" | sed 's/%//')
    
    if [ "$disk_usage_number" -lt 80 ]; then
        log_message "✓ Disk space usage is $disk_usage (healthy)"
    elif [ "$disk_usage_number" -lt 90 ]; then
        log_message "⚠️ Disk space usage is $disk_usage (warning)"
    else
        handle_error "Disk space usage is $disk_usage (critical)"
    fi
}

# Function to check database
check_database() {
    log_message "Checking database connection..."
    
    # Read database settings from .env file
    if [ -f "$BACKEND_PATH/.env" ]; then
        # Extract database settings
        DB_HOST=$(grep -E "^DB_HOST=" "$BACKEND_PATH/.env" | cut -d '=' -f2)
        DB_PORT=$(grep -E "^DB_PORT=" "$BACKEND_PATH/.env" | cut -d '=' -f2)
        DB_NAME=$(grep -E "^DB_NAME=" "$BACKEND_PATH/.env" | cut -d '=' -f2)
        DB_USER=$(grep -E "^DB_USER=" "$BACKEND_PATH/.env" | cut -d '=' -f2)
        DB_PASSWORD=$(grep -E "^DB_PASSWORD=" "$BACKEND_PATH/.env" | cut -d '=' -f2)
        DB_SCHEMA_PATH=$(grep -E "^DB_SCHEMA_PATH=" "$BACKEND_PATH/.env" | cut -d '=' -f2)
        
        # Check database connection
        if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
            log_message "✓ Database connection successful"
        else
            handle_error "Failed to connect to the database"
        fi
        
        # Check database schema path
        if [ -d "$DB_SCHEMA_PATH" ]; then
            log_message "✓ Database schema path exists: $DB_SCHEMA_PATH"
            
            # Check write permissions
            if touch "$DB_SCHEMA_PATH/test_write_$$" > /dev/null 2>&1; then
                log_message "✓ Database schema path is writable"
                rm "$DB_SCHEMA_PATH/test_write_$$"
            else
                handle_error "Database schema path is not writable"
            fi
        else
            handle_error "Database schema path does not exist: $DB_SCHEMA_PATH"
        fi
    else
        handle_error "Backend .env file not found"
    fi
}

# Function to check API endpoints
check_api() {
    log_message "Checking API endpoints..."
    
    # Check if backend is responding
    local api_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/health)
    
    if [ "$api_status" -eq 200 ]; then
        log_message "✓ API health endpoint is responding (Status: $api_status)"
    else
        handle_error "API health endpoint is not responding correctly (Status: $api_status)"
    fi
    
    # Check if API docs are available
    local docs_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/docs)
    
    if [ "$docs_status" -eq 200 ]; then
        log_message "✓ API documentation is available (Status: $docs_status)"
    else
        handle_error "API documentation is not available (Status: $docs_status)"
    fi
}

# Function to check frontend
check_frontend() {
    log_message "Checking frontend..."
    
    # Check if frontend is responding
    local frontend_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001)
    
    if [ "$frontend_status" -eq 200 ]; then
        log_message "✓ Frontend is responding (Status: $frontend_status)"
    else
        handle_error "Frontend is not responding correctly (Status: $frontend_status)"
    fi
}

# Function to check log files
check_logs() {
    log_message "Checking log files..."
    
    # Check backend logs
    local backend_log="$LOG_PATH/backend_prod.log"
    if [ -f "$backend_log" ]; then
        log_message "✓ Backend log file exists"
        
        # Check for errors in backend logs
        local error_count=$(grep -i "error" "$backend_log" | wc -l | tr -d ' ')
        if [ "$error_count" -eq 0 ]; then
            log_message "✓ No errors found in backend logs"
        else
            local recent_errors=$(grep -i "error" "$backend_log" | tail -5)
            handle_error "Found $error_count errors in backend logs. Recent examples:"
            echo "$recent_errors" | while read -r line; do
                handle_error "  $line"
            done
        fi
    else
        handle_error "Backend log file does not exist"
    fi
    
    # Check frontend logs
    local frontend_log="$LOG_PATH/frontend_prod.log"
    if [ -f "$frontend_log" ]; then
        log_message "✓ Frontend log file exists"
        
        # Check for errors in frontend logs
        local error_count=$(grep -i "error" "$frontend_log" | wc -l | tr -d ' ')
        if [ "$error_count" -eq 0 ]; then
            log_message "✓ No errors found in frontend logs"
        else
            local recent_errors=$(grep -i "error" "$frontend_log" | tail -5)
            handle_error "Found $error_count errors in frontend logs. Recent examples:"
            echo "$recent_errors" | while read -r line; do
                handle_error "  $line"
            done
        fi
    else
        handle_error "Frontend log file does not exist"
    fi
    
    # Check log file sizes
    local log_size_warning=50 # MB
    local log_files=("$backend_log" "$frontend_log" "$SYSTEM_LOG")
    
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            local size_kb=$(du -k "$log_file" | cut -f1)
            local size_mb=$((size_kb / 1024))
            
            if [ "$size_mb" -lt "$log_size_warning" ]; then
                log_message "✓ Log file $(basename "$log_file") has reasonable size ($size_mb MB)"
            else
                handle_error "Log file $(basename "$log_file") is large: $size_mb MB. Consider rotation."
            fi
        fi
    done
}

# Main function
main() {
    log_message "Starting FreeLIMS system health check"
    
    # Perform all checks
    check_service "Backend" "uvicorn.*app.main:app" "8000"
    check_service "Frontend" "node.*serve -s build" "3001"
    check_disk_space
    check_database
    check_api
    check_frontend
    check_logs
    
    log_message "System health check completed"
    
    echo ""
    echo "=========================================="
    echo "FreeLIMS System Health Check Complete"
    echo "=========================================="
    echo "Check $SYSTEM_LOG for details"
    echo ""
}

# Execute main function
main 