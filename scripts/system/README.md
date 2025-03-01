# System Management Scripts

This directory contains scripts for managing the FreeLIMS system operations.

## Overview

The `manage.sh` script is the primary script for all system-related operations like starting, stopping, and restarting the FreeLIMS application in different environments.

## Functionality

The system management script provides the following key functionality:

- **Starting environments**: Start the development or production environments
- **Stopping environments**: Safely stop running environments
- **Restarting environments**: Restart environments after changes
- **Status checking**: Check the status of running systems
- **Port management**: Handle port conflicts and process termination
- **Environment setup**: Configure environment variables and dependencies

## Usage

The system management script is typically called through the main `freelims.sh` script:

```bash
./freelims.sh system [environment] [command] [options]
```

### Environments

- `dev` - Development environment
- `prod` - Production environment
- `all` - Both environments

### Commands

- `start` - Start the specified environment
- `stop` - Stop the specified environment
- `restart` - Restart the specified environment
- `status` - Show the status of the environment

### Examples

```bash
# Start development environment
./freelims.sh system dev start

# Restart production environment
./freelims.sh system prod restart

# Stop all environments
./freelims.sh system all stop

# Check status of development environment
./freelims.sh system dev status
```

## Implementation Details

The system management script handles:

1. **Port management**: Checking for and resolving port conflicts
2. **Process management**: Starting and stopping processes safely
3. **Logging**: Comprehensive logging of all operations
4. **Error handling**: Robust error handling and recovery
5. **Virtual environment**: Setting up and activating Python virtual environments
6. **Environment variables**: Setting necessary environment variables for each component 