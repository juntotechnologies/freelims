#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Main Management Script
# This script serves as the entry point for all FreeLIMS operations
# ----------------------------------------------------------------------------

VERSION="1.0.0"

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
    echo "Examples:"
    echo "  $0 system dev start     # Start development environment"
    echo "  $0 system prod restart  # Restart production environment"
    echo "  $0 db dev backup        # Backup development database"
    echo "  $0 user dev clear       # Clear users from development database"
    echo "  $0 port list            # List port configurations"
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

# Validate environment
if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ] && [ "$ENVIRONMENT" != "all" ] && [ "$CATEGORY" != "port" ]; then
    echo "Error: Invalid environment. Must be 'dev', 'prod', or 'all'."
    print_usage
    exit 1
fi

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
    *)
        echo "Error: Invalid category. Use 'system', 'db', 'user', or 'port'."
        print_usage
        exit 1
        ;;
esac

exit 0 