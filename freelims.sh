#!/bin/bash

# ============================================================================
# FreeLIMS Main Script
# This script delegates commands to the appropriate component script
# ============================================================================

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="${SCRIPT_DIR}/backend"
FRONTEND_DIR="${SCRIPT_DIR}/frontend"

# Function to print colored messages
print_message() {
  echo -e "${GREEN}[FreeLIMS]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[FreeLIMS]${NC} $1"
}

print_error() {
  echo -e "${RED}[FreeLIMS]${NC} $1"
}

# Function to print usage information
print_usage() {
  echo "Usage: $0 [component] [command] [environment]"
  echo ""
  echo "Components:"
  echo "  backend     Backend operations"
  echo "  frontend    Frontend operations"
  echo "  all         Both backend and frontend"
  echo ""
  echo "Commands:"
  echo "  start       Start the server(s)"
  echo "  stop        Stop the server(s)"
  echo "  restart     Restart the server(s)"
  echo "  status      Show the status of the server(s)"
  echo "  setup       Set up the environment"
  echo "  help        Show this help message"
  echo ""
  echo "Backend-specific commands:"
  echo "  db:backup   Create a database backup"
  echo "  db:restore  Restore from a database backup"
  echo ""
  echo "Frontend-specific commands:"
  echo "  build       Build the frontend for production"
  echo ""
  echo "Environments:"
  echo "  dev         Development environment (default)"
  echo "  prod        Production environment"
  echo ""
  echo "Examples:"
  echo "  $0 backend start dev    # Start development backend server"
  echo "  $0 frontend stop prod   # Stop production frontend server"
  echo "  $0 all start            # Start both backend and frontend in development mode"
  echo "  $0 backend db:backup    # Backup development database"
}

# Function to run backend command
run_backend_command() {
  local command=$1
  local env=${2:-dev}
  local extra_arg=$3
  
  if [ -f "${BACKEND_DIR}/manage.sh" ]; then
    if [ -n "${extra_arg}" ]; then
      "${BACKEND_DIR}/manage.sh" "${command}" "${env}" "${extra_arg}"
    else
      "${BACKEND_DIR}/manage.sh" "${command}" "${env}"
    fi
  else
    print_error "Backend management script not found at ${BACKEND_DIR}/manage.sh"
    exit 1
  fi
}

# Function to run frontend command
run_frontend_command() {
  local command=$1
  local env=${2:-dev}
  
  if [ -f "${FRONTEND_DIR}/manage.sh" ]; then
    "${FRONTEND_DIR}/manage.sh" "${command}" "${env}"
  else
    print_error "Frontend management script not found at ${FRONTEND_DIR}/manage.sh"
    exit 1
  fi
}

# Function to run command on both components
run_all_command() {
  local command=$1
  local env=${2:-dev}
  
  print_message "Running '${command}' on both backend and frontend (${env})..."
  
  # Run on backend first
  run_backend_command "${command}" "${env}"
  
  # Then run on frontend
  run_frontend_command "${command}" "${env}"
}

# Make sure the component scripts are executable
chmod +x "${BACKEND_DIR}/manage.sh" "${FRONTEND_DIR}/manage.sh" 2>/dev/null || true

# Main logic
COMPONENT=${1:-help}
COMMAND=${2:-help}
ENVIRONMENT=${3:-dev}
EXTRA_ARG=$4

case "${COMPONENT}" in
  backend)
    run_backend_command "${COMMAND}" "${ENVIRONMENT}" "${EXTRA_ARG}"
    ;;
  frontend)
    run_frontend_command "${COMMAND}" "${ENVIRONMENT}"
    ;;
  all)
    run_all_command "${COMMAND}" "${ENVIRONMENT}"
    ;;
  help|--help|-h)
    print_usage
    ;;
  *)
    print_error "Unknown component: ${COMPONENT}"
    print_usage
    exit 1
    ;;
esac

exit 0 