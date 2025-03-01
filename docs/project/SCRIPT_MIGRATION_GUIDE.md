# FreeLIMS Script Migration Guide

> **IMPORTANT UPDATE**: All backward compatibility features have been removed.
> Only the new command structure with `freelims.sh` is now supported.

## Overview

The FreeLIMS codebase has undergone script consolidation to improve maintainability, reduce duplication, and provide a consistent interface. This guide documents the transition from the old script names to the new management system.

## Key Changes

The main changes in the script structure are:

1. A single entry point script (`freelims.sh`) for all operations
2. A standardized command structure: `./freelims.sh [category] [environment] [command] [options]`
3. Specialized management scripts organized by category in the `scripts/` directory
4. Standardized port configuration management through `port_config.sh`

## Command Mapping

Below is a mapping of old script names to their equivalents in the new system:

| Old Command | New Command |
|-------------|-------------|
| `./run_dev.sh` | `./freelims.sh system dev start` |
| `./stop_dev.sh` | `./freelims.sh system dev stop` |
| `./run_prod.sh` | `./freelims.sh system prod start` |
| `./restart_system.sh` | `./freelims.sh system dev restart` |
| `./restart_production.sh` | `./freelims.sh system prod restart` |
| `./create_admin_user.sh dev` | `./freelims.sh user dev create --admin` |
| `./create_admin_user.sh prod` | `./freelims.sh user prod create --admin` |
| `./clear_users.sh dev` | `./freelims.sh user dev clear` |
| `./clear_users.sh dev --keep-admin` | `./freelims.sh user dev clear --keep-admin` |
| `./remove_all_users.sh` | `./freelims.sh user all clear` |
| `./setup.sh` | `./freelims.sh system setup` |
| `./deploy.sh` | `./freelims.sh system deploy` |
| `./fix_dev_environment.sh` | `./freelims.sh system dev fix` |
| `./clean_start.sh` | `./freelims.sh system dev clean` |
| `./setup_dev_db.sh` | `./freelims.sh db dev init` |
| `./check_database_config.sh` | `./freelims.sh db check-config` |

## Benefits of the New Structure

The new script structure offers several advantages:

1. **Consistency**: All commands follow the same pattern
2. **Discoverability**: Help text shows all available options
3. **Reduced duplication**: Common code is shared between scripts
4. **Improved error handling**: Consistent approach to errors and logs
5. **Better port management**: Standardized port handling across all scripts
6. **Organized Directory Structure**: Scripts organized by function in dedicated directories

## Examples of Common Commands

Here are examples of common operations using the command structure:

```bash
# Start development environment
./freelims.sh system dev start

# Stop development environment
./freelims.sh system dev stop

# Backup development database
./freelims.sh db dev backup

# Create a new admin user in production
./freelims.sh user prod create --admin

# List port configuration
./freelims.sh port list

# Check system status
./freelims.sh system dev status
```

## Additional Resources

For more detailed information about each category of commands, see:

- [System Management Documentation](scripts/system/README.md)
- [User Management Documentation](scripts/user/README.md)
- [Database Management Documentation](scripts/db/README.md)
- [MANAGEMENT_SYSTEM.md](MANAGEMENT_SYSTEM.md) - Full documentation of the management system

## Note for CI/CD Pipelines and Automation

If you have any CI/CD pipelines, automated tests, or other systems that used the old script names, make sure to update them to use the new command structure. The old script names are no longer supported.
