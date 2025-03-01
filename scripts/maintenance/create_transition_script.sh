#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Transition Script Creator
# This script creates a single transition script that replaces all the symlinks
# ----------------------------------------------------------------------------

echo "=================================================="
echo "FreeLIMS Transition Script Creator"
echo "=================================================="
echo ""

# Get the repository root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Create the transition script
cat > "$REPO_ROOT/flims" << 'EOF'
#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Command Transition Helper
# This script helps transition from old script names to the new management system
# ----------------------------------------------------------------------------

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

# Map old commands to new commands
case "$0" in
  *run_dev.sh)
    echo "⚠️  The run_dev.sh script has been replaced by the FreeLIMS management system."
    echo "⚠️  Running equivalent command: ./freelims.sh system dev start"
    exec "$REPO_ROOT/freelims.sh" system dev start "$@"
    ;;
  *restart_system.sh)
    echo "⚠️  The restart_system.sh script has been replaced by the FreeLIMS management system."
    echo "⚠️  Running equivalent command: ./freelims.sh system dev restart"
    exec "$REPO_ROOT/freelims.sh" system dev restart "$@"
    ;;
  *stop_dev.sh)
    echo "⚠️  The stop_dev.sh script has been replaced by the FreeLIMS management system."
    echo "⚠️  Running equivalent command: ./freelims.sh system dev stop"
    exec "$REPO_ROOT/freelims.sh" system dev stop "$@"
    ;;
  *create_admin_user.sh)
    echo "⚠️  The create_admin_user.sh script has been replaced by the FreeLIMS management system."
    echo "⚠️  Running equivalent command: ./freelims.sh user dev create --admin"
    ENV="${1:-dev}"
    exec "$REPO_ROOT/freelims.sh" user "$ENV" create --admin
    ;;
  *clear_users.sh)
    echo "⚠️  The clear_users.sh script has been replaced by the FreeLIMS management system."
    if [ "$2" == "--keep-admin" ]; then
      echo "⚠️  Running equivalent command: ./freelims.sh user $1 clear --keep-admin"
      exec "$REPO_ROOT/freelims.sh" user "$1" clear --keep-admin
    else
      echo "⚠️  Running equivalent command: ./freelims.sh user $1 clear"
      exec "$REPO_ROOT/freelims.sh" user "$1" clear
    fi
    ;;
  *setup.sh)
    echo "⚠️  The setup.sh script has been replaced by the FreeLIMS management system."
    echo "⚠️  Running equivalent command: ./freelims.sh system setup"
    exec "$REPO_ROOT/freelims.sh" system setup "$@"
    ;;
  *deploy.sh)
    echo "⚠️  The deploy.sh script has been replaced by the FreeLIMS management system."
    echo "⚠️  Running equivalent command: ./freelims.sh system deploy"
    exec "$REPO_ROOT/freelims.sh" system deploy "$@"
    ;;
  *fix_dev_environment.sh)
    echo "⚠️  The fix_dev_environment.sh script has been replaced by the FreeLIMS management system."
    echo "⚠️  Running equivalent command: ./freelims.sh system dev fix"
    exec "$REPO_ROOT/freelims.sh" system dev fix "$@"
    ;;
  *clean_start.sh)
    echo "⚠️  The clean_start.sh script has been replaced by the FreeLIMS management system."
    echo "⚠️  Running equivalent command: ./freelims.sh system dev clean"
    exec "$REPO_ROOT/freelims.sh" system dev clean "$@"
    ;;
  *setup_dev_db.sh)
    echo "⚠️  The setup_dev_db.sh script has been replaced by the FreeLIMS management system."
    echo "⚠️  Running equivalent command: ./freelims.sh db dev init"
    exec "$REPO_ROOT/freelims.sh" db dev init "$@"
    ;;
  *check_database_config.sh)
    echo "⚠️  The check_database_config.sh script has been replaced by the FreeLIMS management system."
    echo "⚠️  Running equivalent command: ./freelims.sh db check-config"
    exec "$REPO_ROOT/freelims.sh" db check-config "$@"
    ;;
  */flims)
    # If called directly as flims, show help
    if [ "$1" == "help" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ -z "$1" ]; then
      echo "FreeLIMS Command Helper"
      echo "======================="
      echo "This is a transition script to help you use the new FreeLIMS management system."
      echo ""
      echo "The recommended way to run FreeLIMS commands is using the main management script:"
      echo "  ./freelims.sh [category] [environment] [command] [options]"
      echo ""
      echo "For example:"
      echo "  ./freelims.sh system dev start    # Start development environment"
      echo "  ./freelims.sh db prod backup      # Backup production database"
      echo ""
      echo "You can also use this helper script with old command names for backward compatibility:"
      echo "  ./flims run_dev                   # Equivalent to ./freelims.sh system dev start"
      echo "  ./flims stop_dev                  # Equivalent to ./freelims.sh system dev stop"
      echo "  ./flims restart                   # Equivalent to ./freelims.sh system dev restart"
      echo "  ./flims clean                     # Equivalent to ./freelims.sh system dev clean"
      echo ""
      echo "See the documentation for more information:"
      echo "  ./freelims.sh help"
      exit 0
    fi
    
    # Simplified commands when called as flims
    case "$1" in
      run_dev|start)
        echo "⚠️  Running equivalent command: ./freelims.sh system dev start"
        exec "$REPO_ROOT/freelims.sh" system dev start "${@:2}"
        ;;
      stop_dev|stop)
        echo "⚠️  Running equivalent command: ./freelims.sh system dev stop"
        exec "$REPO_ROOT/freelims.sh" system dev stop "${@:2}"
        ;;
      restart|restart_dev)
        echo "⚠️  Running equivalent command: ./freelims.sh system dev restart"
        exec "$REPO_ROOT/freelims.sh" system dev restart "${@:2}"
        ;;
      clean|clean_start)
        echo "⚠️  Running equivalent command: ./freelims.sh system dev clean"
        exec "$REPO_ROOT/freelims.sh" system dev clean "${@:2}"
        ;;
      setup)
        echo "⚠️  Running equivalent command: ./freelims.sh system setup"
        exec "$REPO_ROOT/freelims.sh" system setup "${@:2}"
        ;;
      deploy)
        echo "⚠️  Running equivalent command: ./freelims.sh system deploy"
        exec "$REPO_ROOT/freelims.sh" system deploy "${@:2}"
        ;;
      fix|fix_dev)
        echo "⚠️  Running equivalent command: ./freelims.sh system dev fix"
        exec "$REPO_ROOT/freelims.sh" system dev fix "${@:2}"
        ;;
      create_admin|admin)
        echo "⚠️  Running equivalent command: ./freelims.sh user dev create --admin"
        ENV="${2:-dev}"
        exec "$REPO_ROOT/freelims.sh" user "$ENV" create --admin "${@:3}"
        ;;
      clear_users)
        echo "⚠️  Running equivalent command: ./freelims.sh user dev clear"
        ENV="${2:-dev}"
        if [ "$3" == "--keep-admin" ]; then
          exec "$REPO_ROOT/freelims.sh" user "$ENV" clear --keep-admin "${@:4}"
        else
          exec "$REPO_ROOT/freelims.sh" user "$ENV" clear "${@:3}"
        fi
        ;;
      setup_db|init_db)
        echo "⚠️  Running equivalent command: ./freelims.sh db dev init"
        ENV="${2:-dev}"
        exec "$REPO_ROOT/freelims.sh" db "$ENV" init "${@:3}"
        ;;
      check_db|check_database)
        echo "⚠️  Running equivalent command: ./freelims.sh db check-config"
        exec "$REPO_ROOT/freelims.sh" db check-config "${@:2}"
        ;;
      *)
        echo "Unknown command: $1"
        echo "Run './flims help' for usage information."
        exit 1
        ;;
    esac
    ;;
  *)
    echo "This script should be called as one of the FreeLIMS commands or as './flims [command]'."
    echo "Run './flims help' for usage information."
    exit 1
    ;;
esac
EOF

# Make the transition script executable
chmod +x "$REPO_ROOT/flims"

echo "✅ Created transition script: $REPO_ROOT/flims"
echo ""
echo "This script will replace all the symlinks in the root directory."
echo "It can be used either as a direct command or with symlinks to it."
echo "For example: './flims run_dev' or './run_dev.sh'"
echo ""
echo "You should now run the cleanup script to remove all the old symlinks." 