# FreeLIMS Script Organization

This document provides details about the organization of scripts in the FreeLIMS project and how to use the main management script.

## Directory Structure

The FreeLIMS project uses a clean, organized structure for scripts:

- `freelims.sh` - The main entry point script located in the root directory
- `port_config.sh` - Port configuration utilities located in the root directory
- `scripts/` - Contains all specialized scripts organized by category:
  - `scripts/system/` - System management scripts (start, stop, restart)
    - `scripts/system/dev/` - Development-specific system scripts
    - `scripts/system/prod/` - Production-specific system scripts
  - `scripts/db/` - Database management scripts
    - `scripts/db/backups/` - Database backup storage
    - `scripts/db/utils/` - Database utility scripts
  - `scripts/user/` - User management scripts
  - `scripts/compat/` - Compatibility wrapper scripts
  - `scripts/maintenance/` - Maintenance and utility scripts
  - `scripts/common/` - Common utility functions used by multiple scripts
  - `scripts/deploy/` - Deployment scripts
  - `scripts/setup/` - Setup scripts

## Using the Main Management Script

The `freelims.sh` script in the root directory serves as the central controller for all operations. It follows a consistent command structure:

```
./freelims.sh [category] [environment] [command] [options]
```

For example:
- `./freelims.sh system dev start` - Start the development environment
- `./freelims.sh db prod backup` - Backup the production database
- `./freelims.sh user dev create --admin` - Create an admin user in development

## Compatibility with Legacy Scripts

For backward compatibility, symlinks are provided in the root directory that point to compatibility wrapper scripts:

- `run_dev.sh` → `scripts/compat/run_dev_wrapper.sh`
- `stop_dev.sh` → `scripts/compat/stop_dev_wrapper.sh`
- `create_admin_user.sh` → `scripts/compat/create_admin_wrapper.sh`
- etc.

These wrappers print a notice suggesting the new command format, then execute the equivalent command using the new system.

## Port Configuration

The `port_config.sh` script defines standard ports used by different environments and provides utility functions for port management. It is kept in the root directory because it's frequently sourced by other scripts.

## Removing Duplicate Scripts

If you find duplicate scripts that have been consolidated into the management system, you can run the cleanup script:

```
./scripts/maintenance/cleanup_duplicate_scripts.sh
```

This will safely backup and remove outdated scripts.

## Script Types and Their Locations

### System Management Scripts
- `scripts/system/manage.sh` - Main system management interface
- `scripts/system/dev/*.sh` - Development environment scripts
- `scripts/system/prod/*.sh` - Production environment scripts

### Database Management Scripts
- `scripts/db/manage.sh` - Main database management interface
- `scripts/db/setup_dev_db.sh` - Development database setup
- `scripts/db/utils/check_db.py` - Database utility scripts

### User Management Scripts
- `scripts/user/manage.sh` - Main user management interface

### Compatibility Wrappers
- `scripts/compat/*.sh` - Root-level script wrappers
- `scripts/compat/db/*.sh` - Database script wrappers
- `scripts/compat/setup/*.sh` - Setup script wrappers

## Best Practices

1. Always use the central management script (`freelims.sh`) for all operations.
2. Place new scripts in the appropriate category directory under `scripts/`.
3. When creating a new script type, add a management function to the relevant category manager.
4. Update documentation when adding new functionality.
5. Use relative paths within scripts to ensure portability.
6. Source common utilities at the beginning of scripts.
7. Include proper error handling and logging in all scripts. 