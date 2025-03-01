#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Root Directory Cleanup
# This script cleans up the root directory by removing symlinks and backup files
# ----------------------------------------------------------------------------

echo "=================================================="
echo "FreeLIMS Root Directory Cleanup"
echo "=================================================="
echo ""

# Get the repository root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Create backup directory if it doesn't exist
BACKUP_DIR="$REPO_ROOT/backups/root_cleanup_$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Creating backup directory: $BACKUP_DIR"

# Function to backup a file
backup_file() {
    local file="$1"
    if [ -f "$file" ] || [ -L "$file" ]; then
        cp -a "$file" "$BACKUP_DIR/"
        echo "✅ Backed up: $file"
        return 0
    fi
    return 1
}

# Function to remove a file (with backup)
remove_file() {
    local file="$1"
    if [ -f "$file" ] || [ -L "$file" ]; then
        backup_file "$file"
        rm -f "$file"
        echo "🗑️  Removed: $file"
        return 0
    else
        echo "⚠️  File not found: $file"
    fi
    return 1
}

# Function to create a symlink to the flims helper
create_helper_link() {
    local name="$1"
    local target="$REPO_ROOT/flims"
    
    if [ -f "$target" ]; then
        ln -sf "$target" "$REPO_ROOT/$name"
        echo "🔗 Created link: $name -> flims"
        return 0
    else
        echo "❌ Failed to create link: $name (target not found)"
        return 1
    fi
}

echo "Backing up and removing symlinks and unnecessary files..."

# List of symlinks/scripts to remove
SYMLINKS=(
    "run_dev.sh"
    "restart_system.sh"
    "stop_dev.sh"
    "create_admin_user.sh"
    "clear_users.sh"
    "setup.sh"
    "deploy.sh"
    "fix_dev_environment.sh"
    "clean_start.sh"
    "setup_dev_db.sh"
    "check_database_config.sh"
)

# Backing up and removing any backup files
echo "Removing backup files..."
for file in "$REPO_ROOT"/*.bak.*; do
    if [ -f "$file" ] || [ -L "$file" ]; then
        backup_file "$file"
        rm -f "$file"
        echo "🗑️  Removed backup file: $file"
    fi
done

# Remove all symlinks
for link in "${SYMLINKS[@]}"; do
    remove_file "$REPO_ROOT/$link"
done

# Create new symlinks to the flims helper script
echo ""
echo "Creating new helper symlinks..."
for link in "${SYMLINKS[@]}"; do
    create_helper_link "$link"
done

# Move check_db.py to the appropriate directory if it exists
if [ -f "$REPO_ROOT/check_db.py" ]; then
    # Determine the destination directory
    DEST_DIR="$REPO_ROOT/scripts/db/utils"
    mkdir -p "$DEST_DIR"
    
    # Backup and move the file
    backup_file "$REPO_ROOT/check_db.py"
    mv "$REPO_ROOT/check_db.py" "$DEST_DIR/"
    echo "📦 Moved check_db.py to $DEST_DIR/"
fi

# Move auth.json to the config directory if it exists
if [ -f "$REPO_ROOT/auth.json" ]; then
    DEST_DIR="$REPO_ROOT/config"
    mkdir -p "$DEST_DIR"
    
    backup_file "$REPO_ROOT/auth.json"
    mv "$REPO_ROOT/auth.json" "$DEST_DIR/"
    echo "📦 Moved auth.json to $DEST_DIR/"
fi

# Remove node_modules from root if it exists (should be in frontend directory)
if [ -d "$REPO_ROOT/node_modules" ]; then
    echo "⚠️  Found node_modules in root directory. This should be in the frontend directory."
    read -p "Do you want to remove it? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "Backing up package.json and package-lock.json..."
        backup_file "$REPO_ROOT/package.json"
        backup_file "$REPO_ROOT/package-lock.json"
        
        echo "Moving node_modules to backup (this may take a while)..."
        mv "$REPO_ROOT/node_modules" "$BACKUP_DIR/"
        rm -f "$REPO_ROOT/package.json" "$REPO_ROOT/package-lock.json"
        echo "🗑️  Removed node_modules, package.json, and package-lock.json from root directory"
    else
        echo "Skipping node_modules removal"
    fi
fi

# Clean up and organize documentation
echo ""
echo "Organizing documentation..."
DOCS_DIR="$REPO_ROOT/docs"
mkdir -p "$DOCS_DIR/project"

# List of documentation files to move
DOCS=(
    "SCRIPT_ORGANIZATION.md"
    "SCRIPT_MIGRATION_GUIDE.md"
    "PROJECT_ORGANIZATION.md"
    "MANAGEMENT_SYSTEM.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$REPO_ROOT/$doc" ]; then
        backup_file "$REPO_ROOT/$doc"
        mv "$REPO_ROOT/$doc" "$DOCS_DIR/project/"
        echo "📄 Moved $doc to docs/project/"
    fi
done

# Create a root README update to reference the moved documentation
echo ""
echo "Updating README.md to reference moved documentation..."

cat > "$REPO_ROOT/README.md.new" << EOF
# FreeLIMS

A Laboratory Information Management System for small to medium-sized laboratories.

## Getting Started

FreeLIMS uses a centralized script management system. The main entry point is `freelims.sh`:

\`\`\`bash
# Start the development environment
./freelims.sh system dev start

# Check the status of the system
./freelims.sh system dev status

# Backup the database
./freelims.sh db dev backup
\`\`\`

For a more familiar interface, you can also use the `flims` helper:

\`\`\`bash
# Start the development environment
./flims start

# Stop the development environment
./flims stop

# Show help
./flims help
\`\`\`

## Documentation

- [Project Organization](docs/project/PROJECT_ORGANIZATION.md)
- [Script Organization](docs/project/SCRIPT_ORGANIZATION.md)
- [Script Migration Guide](docs/project/SCRIPT_MIGRATION_GUIDE.md)
- [Management System](docs/project/MANAGEMENT_SYSTEM.md)

For additional documentation, see the [docs](docs/) directory.

EOF

echo "Created new README.md.new with updated documentation references"

# Let the user know what to do next
echo ""
echo "=================================================="
echo "Root directory cleanup completed!"
echo ""
echo "The following files have been kept in the root directory:"
echo "- freelims.sh (main management script)"
echo "- flims (command helper script)"
echo "- port_config.sh (port configuration)"
echo "- LICENSE (license file)"
echo "- README.md (project overview)"
echo "- .git and git-related files"
echo ""
echo "Documentation has been moved to docs/project/"
echo ""
echo "An updated README.md has been created as README.md.new."
echo "Review it and replace the existing README.md if appropriate:"
echo "mv README.md.new README.md"
echo ""
echo "A backup of all removed files has been created at:"
echo "$BACKUP_DIR"
echo "==================================================" 