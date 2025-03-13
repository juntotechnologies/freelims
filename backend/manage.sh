#!/bin/bash

# ============================================================================
# FreeLIMS Backend Management Script
# This script provides an interface for managing the FreeLIMS backend
# ============================================================================

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
LOG_DIR="${ROOT_DIR}/logs"

# Create log directory if it doesn't exist
mkdir -p "${LOG_DIR}"

# Function to print colored messages
print_message() {
  echo -e "${GREEN}[FreeLIMS Backend]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[FreeLIMS Backend]${NC} $1"
}

print_error() {
  echo -e "${RED}[FreeLIMS Backend]${NC} $1"
}

# Function to print usage information
print_usage() {
  echo "Usage: $0 [command] [environment]"
  echo ""
  echo "Commands:"
  echo "  start       Start the backend server"
  echo "  stop        Stop the backend server"
  echo "  restart     Restart the backend server"
  echo "  status      Show the status of the backend server"
  echo "  db:backup   Create a database backup"
  echo "  db:restore  Restore from a database backup"
  echo "  setup       Set up the backend environment"
  echo "  help        Show this help message"
  echo ""
  echo "Environments:"
  echo "  dev         Development environment (default)"
  echo "  prod        Production environment"
  echo ""
  echo "Examples:"
  echo "  $0 start dev     # Start development backend server"
  echo "  $0 stop prod     # Stop production backend server"
  echo "  $0 db:backup     # Backup development database"
  echo "  $0 setup         # Set up development environment"
}

# Function to set up the application environment
setup_environment() {
  local env=${1:-dev}
  
  print_message "Setting up ${env} environment..."
  
  # Check if .env file exists
  if [ ! -f "${ROOT_DIR}/.env" ]; then
    print_warning "No .env file found. Creating from .env.example..."
    cp "${ROOT_DIR}/.env.example" "${ROOT_DIR}/.env"
    print_message ".env file created. Please update it with your configuration."
  fi
  
  # Check if virtual environment exists
  if [ ! -d "${SCRIPT_DIR}/venv" ]; then
    print_message "Creating virtual environment..."
    python3 -m venv "${SCRIPT_DIR}/venv"
  fi
  
  # Activate virtual environment
  source "${SCRIPT_DIR}/venv/bin/activate"
  
  # Install dependencies
  print_message "Installing backend dependencies..."
  pip install -r "${SCRIPT_DIR}/requirements.txt"
  
  # Run setup-env.py
  print_message "Setting up backend environment variables..."
  python "${SCRIPT_DIR}/scripts/setup-env.py"
  
  # Deactivate virtual environment
  deactivate
  
  print_message "${env} environment setup complete!"
}

# Function to start the backend server
start_server() {
  local env=${1:-dev}
  local backend_port=$(get_backend_port "${env}")
  
  print_message "Starting ${env} backend server on port ${backend_port}..."
  
  # Activate virtual environment
  source "${SCRIPT_DIR}/venv/bin/activate"
  
  # Check if server is already running
  if is_server_running "${backend_port}"; then
    print_warning "Backend server is already running on port ${backend_port}."
    deactivate
    return 0
  fi
  
  # Start server
  if [ "${env}" = "prod" ]; then
    # Production mode
    python -m app.main > "${LOG_DIR}/backend_${env}.log" 2>&1 &
  else
    # Development mode
    python -m app.main > "${LOG_DIR}/backend_${env}.log" 2>&1 &
  fi
  
  BACKEND_PID=$!
  print_message "Backend started with PID: ${BACKEND_PID}"
  
  # Wait a moment to check if server started successfully
  sleep 2
  if is_server_running "${backend_port}"; then
    print_message "Backend server started successfully on http://localhost:${backend_port}"
  else
    print_error "Failed to start backend server. Check logs at ${LOG_DIR}/backend_${env}.log"
  fi
  
  # Deactivate virtual environment
  deactivate
}

# Function to stop the backend server
stop_server() {
  local env=${1:-dev}
  local backend_port=$(get_backend_port "${env}")
  
  print_message "Stopping ${env} backend server..."
  
  # Check if server is running
  local backend_pid=$(lsof -t -i:${backend_port} 2>/dev/null)
  if [ -n "${backend_pid}" ]; then
    print_message "Stopping backend server (PID: ${backend_pid})..."
    kill "${backend_pid}" 2>/dev/null || kill -9 "${backend_pid}" 2>/dev/null
    print_message "Backend server stopped."
  else
    print_warning "Backend server not running."
  fi
}

# Function to show the status of the backend server
show_status() {
  local env=${1:-dev}
  local backend_port=$(get_backend_port "${env}")
  
  print_message "Status of ${env} backend server:"
  
  # Check backend status
  if is_server_running "${backend_port}"; then
    local backend_pid=$(lsof -t -i:${backend_port} 2>/dev/null)
    print_message "Backend server: RUNNING (PID: ${backend_pid}, Port: ${backend_port})"
    print_message "URL: http://localhost:${backend_port}"
  else
    print_warning "Backend server: NOT RUNNING"
  fi
}

# Function to check if server is running
is_server_running() {
  local port=$1
  lsof -i:${port} >/dev/null 2>&1
  return $?
}

# Function to backup the database
backup_database() {
  local env=${1:-dev}
  
  print_message "Backing up ${env} database..."
  
  # Activate virtual environment
  source "${SCRIPT_DIR}/venv/bin/activate"
  
  # Run backup script
  python "${SCRIPT_DIR}/scripts/db/db_backup.py" "${env}"
  
  # Deactivate virtual environment
  deactivate
  
  print_message "Database backup complete!"
}

# Function to restore the database
restore_database() {
  local env=${1:-dev}
  local backup_file=$2
  
  if [ -z "${backup_file}" ]; then
    print_error "Backup file not specified."
    echo "Usage: $0 db:restore [environment] [backup_file]"
    exit 1
  fi
  
  print_message "Restoring ${env} database from ${backup_file}..."
  
  # Activate virtual environment
  source "${SCRIPT_DIR}/venv/bin/activate"
  
  # Run restore script
  python "${SCRIPT_DIR}/scripts/db/db_restore.py" "${env}" "${backup_file}"
  
  # Deactivate virtual environment
  deactivate
  
  print_message "Database restore complete!"
}

# Function to get backend port based on environment
get_backend_port() {
  local env=$1
  
  if [ "${env}" = "prod" ]; then
    echo "${PROD_BACKEND_PORT:-8006}"
  else
    echo "${DEV_BACKEND_PORT:-8005}"
  fi
}

# Load environment variables from .env file
if [ -f "${ROOT_DIR}/.env" ]; then
  # Parse .env file and export variables
  export $(grep -v '^#' "${ROOT_DIR}/.env" | xargs)
fi

# Main logic
COMMAND=${1:-help}
ENVIRONMENT=${2:-dev}

case "${COMMAND}" in
  start)
    start_server "${ENVIRONMENT}"
    ;;
  stop)
    stop_server "${ENVIRONMENT}"
    ;;
  restart)
    stop_server "${ENVIRONMENT}"
    sleep 2
    start_server "${ENVIRONMENT}"
    ;;
  status)
    show_status "${ENVIRONMENT}"
    ;;
  db:backup)
    backup_database "${ENVIRONMENT}"
    ;;
  db:restore)
    restore_database "${ENVIRONMENT}" "$3"
    ;;
  setup)
    setup_environment "${ENVIRONMENT}"
    ;;
  help|--help|-h)
    print_usage
    ;;
  *)
    print_error "Unknown command: ${COMMAND}"
    print_usage
    exit 1
    ;;
esac

exit 0 