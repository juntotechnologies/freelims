#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Complete Root Directory Cleanup
# This script performs a thorough cleanup of the root directory,
# removing all scripts and symlinks except for freelims.sh
# ----------------------------------------------------------------------------

echo "===================================================="
echo "FreeLIMS Complete Root Directory Cleanup"
echo "===================================================="
echo ""

# Get the repository root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Create a timestamp for the backup
TIMESTAMP=$(date +%Y%m%d%H%M%S)
BACKUP_DIR="$REPO_ROOT/backups/root_cleanup_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

echo "Created backup directory: $BACKUP_DIR"
echo ""

# Function to backup a file before removing it
backup_and_remove() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "Backing up and removing: $file"
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        rm "$file"
        return 0
    fi
    return 1
}

# Function to check if a file is a symlink
is_symlink() {
    local file="$1"
    if [ -L "$file" ]; then
        return 0
    else
        return 1
    fi
}

# List of essential files to keep
KEEP_FILES=(
    "$REPO_ROOT/freelims.sh"
    "$REPO_ROOT/port_config.sh"
    "$REPO_ROOT/LICENSE"
    "$REPO_ROOT/README.md"
    "$REPO_ROOT/.git"
    "$REPO_ROOT/.gitignore"
    "$REPO_ROOT/.gitattributes"
    "$REPO_ROOT/.gitignore-enhanced"
)

echo "Removing all symlinks from root directory..."
for file in "$REPO_ROOT"/*; do
    # Skip directories
    if [ -d "$file" ] && [ ! -L "$file" ]; then
        continue
    fi
    
    # Skip essential files
    skip=false
    for keep in "${KEEP_FILES[@]}"; do
        if [ "$file" = "$keep" ]; then
            skip=true
            break
        fi
    done
    
    if $skip; then
        echo "Keeping: $(basename "$file")"
        continue
    fi
    
    # If it's a symlink, remove it; otherwise, back it up
    if is_symlink "$file"; then
        echo "Removing symlink: $(basename "$file")"
        rm "$file"
    else
        backup_and_remove "$file"
    fi
done

# Update documentation regarding scripts
echo "Updating README.md with new instructions..."
cat > "$REPO_ROOT/README.md" << 'EOF'
# FreeLIMS

A Laboratory Information Management System for small to medium-sized laboratories.

## Getting Started

FreeLIMS uses a centralized script management system. The main entry point is:

```bash
# Start the development environment
./freelims.sh system dev start

# Check the status of the system
./freelims.sh system dev status

# Backup the database
./freelims.sh db dev backup
```

## Documentation

- [Project Organization](docs/project/PROJECT_ORGANIZATION.md)
- [Script Organization](docs/project/SCRIPT_ORGANIZATION.md)
- [Script Migration Guide](docs/project/SCRIPT_MIGRATION_GUIDE.md)
- [Management System](docs/project/MANAGEMENT_SYSTEM.md)

For additional documentation, see the [docs](docs/) directory.
EOF

# Create migration guide if it doesn't exist
MIGRATION_GUIDE="$REPO_ROOT/docs/project/SCRIPT_MIGRATION_GUIDE.md"

if [ ! -f "$MIGRATION_GUIDE" ]; then
    echo "Creating Script Migration Guide..."
    mkdir -p "$(dirname "$MIGRATION_GUIDE")"
    cat > "$MIGRATION_GUIDE" << 'EOF'
# FreeLIMS Script Migration Guide

This guide helps you transition from the old script names to the new FreeLIMS management system.

## Script Name Changes

| Old Command | New Command | Description |
|-------------|-------------|-------------|
| `./run_dev.sh` | `./freelims.sh system dev start` | Start development environment |
| `./stop_dev.sh` | `./freelims.sh system dev stop` | Stop development environment |
| `./restart_system.sh` | `./freelims.sh system dev restart` | Restart development environment |
| `./create_admin_user.sh` | `./freelims.sh user dev create --admin` | Create admin user |
| `./clear_users.sh` | `./freelims.sh user dev clear` | Clear users from database |
| `./setup.sh` | `./freelims.sh system setup` | Set up the system |
| `./deploy.sh` | `./freelims.sh system deploy` | Deploy the system |
| `./fix_dev_environment.sh` | `./freelims.sh system dev fix` | Fix development environment |
| `./clean_start.sh` | `./freelims.sh system dev clean` | Clean start development environment |
| `./setup_dev_db.sh` | `./freelims.sh db dev init` | Initialize development database |
| `./check_database_config.sh` | `./freelims.sh db check-config` | Check database configuration |

## Using the New Management System

The new management system uses a consistent command structure:

```bash
./freelims.sh [category] [environment] [command] [options]
```

Where:
- `category` is one of: system, db, user, port
- `environment` is one of: dev, prod, all
- `command` is the specific action to perform
- `options` are any additional parameters

For example:
```bash
./freelims.sh system dev start
./freelims.sh db prod backup
./freelims.sh user dev list
```

## Getting Help

To see all available commands and options:

```bash
./freelims.sh help
```

To see help for a specific category:

```bash
./freelims.sh system help
./freelims.sh db help
./freelims.sh user help
```
EOF
fi

echo ""
echo "===================================================="
echo "Root directory cleanup completed!"
echo ""
echo "Files kept in root directory:"
ls -la "$REPO_ROOT" | grep -v "^d" | grep -v "total" | awk '{print $9}'
echo ""
echo "Backup of removed files: $BACKUP_DIR"
echo "====================================================" 