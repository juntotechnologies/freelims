# FreeLIMS Project Organization

This document provides an overview of the FreeLIMS project directory structure and organization.

## Directory Structure

### Root Directory
- `freelims.sh` - Main management script (entry point for all operations)
- `port_config.sh` - Port configuration and management utilities
- `SCRIPT_MIGRATION_GUIDE.md` - Guide for migrating from old scripts to new management system
- `MANAGEMENT_SYSTEM.md` - Documentation of the management system
- `README.md` - Project overview and getting started guide

### Main Component Directories
- `frontend/` - React.js frontend application
- `backend/` - FastAPI backend server and API
- `config/` - Configuration files for the application
- `docs/` - Project documentation

### Script Organization
- `scripts/` - Organized script directory containing:
  - `system/` - System management scripts (start, stop, restart)
  - `user/` - User management scripts
  - `db/` - Database management scripts
  - `utils/` - Utility scripts
  - `compat/` - Compatibility wrapper scripts
  - `setup/` - System setup scripts
  - `deploy/` - Deployment scripts
  - `maintenance/` - System maintenance scripts

### Test Resources
- `test/` - Test and debugging resources
  - `html/` - HTML test pages
  - `js/` - JavaScript test files
  - `python/` - Python test scripts
  - `websocket/` - WebSocket testing resources

### Data and Logs
- `logs/` - Log files from various components
- `db_backups/` - Database backup files
- `backups/` - Other backup files

## Key Scripts

### Main Management Scripts
- `freelims.sh` - Central management script
- `scripts/system/dev_system.sh` - Development environment management
- `scripts/system/prod_system.sh` - Production environment management

### Database Management
- `scripts/db/db_manager.sh` - Database operations (backup, restore, migrate)

### User Management
- `scripts/user/user_manager.sh` - User operations (create, list, delete)

### Utilities
- `scripts/utils/websocket/` - WebSocket monitoring tools

## Compatibility Layer

For backward compatibility, symbolic links are provided for commonly used old script names:
- `run_dev.sh` → `scripts/compat/run_dev_wrapper.sh`
- `stop_dev.sh` → `scripts/compat/stop_dev_wrapper.sh`
- `restart_system.sh` → `scripts/compat/restart_system_wrapper.sh`
- etc.

These wrapper scripts redirect to the new management system while providing informative messages.

## Best Practices

1. Use the central management script (`freelims.sh`) for all operations
2. Follow the standard command structure: `./freelims.sh [category] [environment] [command]`
3. Place new scripts in the appropriate category directory
4. Update documentation when adding new functionality
5. Use the port configuration system for consistent port management
6. Add tests to the appropriate test directory 