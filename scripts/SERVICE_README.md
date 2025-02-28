# FreeLIMS Persistent Service

This guide explains how to set up FreeLIMS to run persistently on your Mac, surviving both logouts and reboots.

## Overview

The FreeLIMS service setup will:

1. Start both development and production environments automatically at system boot
2. Keep both environments running, even when users log out
3. Automatically restart environments if they crash
4. Log all activity to the logs directory

## Service Features

- **Automatic Port Management** - The service automatically handles port conflicts
- **System Integration** - Properly registered as a macOS LaunchDaemon
- **Health Monitoring** - Regular checks to ensure all components are running
- **Comprehensive Logging** - Detailed logs kept for troubleshooting

## Installation

To install the FreeLIMS service:

```bash
# Navigate to your FreeLIMS installation
cd /Users/shaun/Documents/GitHub/projects/freelims

# Run the installation script with sudo
sudo scripts/install_service.sh
```

This will:
1. Install the service as a system LaunchDaemon
2. Set proper permissions
3. Start the service immediately
4. Configure it to start on system boot

## Uninstallation

To remove the FreeLIMS service:

```bash
# Navigate to your FreeLIMS installation
cd /Users/shaun/Documents/GitHub/projects/freelims

# Run the uninstallation script with sudo
sudo scripts/uninstall_service.sh
```

## Accessing the Environments

Once installed, the environments will be accessible at:

- **Development Environment**:
  - Backend API: http://localhost:8001
  - Frontend: http://localhost:3001
  - API Docs: http://localhost:8001/docs

- **Production Environment**:
  - Backend API: http://localhost:8002
  - Frontend: http://localhost:3002
  - API Docs: http://localhost:8002/docs

## Monitoring

The service writes logs to the following locations:

- Main service log: `/Users/shaun/Documents/GitHub/projects/freelims/logs/freelims_service.log`
- Development backend: `/Users/shaun/Documents/GitHub/projects/freelims/logs/backend.log`
- Development frontend: `/Users/shaun/Documents/GitHub/projects/freelims/logs/frontend.log`
- Production backend: `/Users/shaun/Documents/GitHub/projects/freelims/logs/backend_prod.log`
- Production frontend: `/Users/shaun/Documents/GitHub/projects/freelims/logs/frontend_prod.log`

## Manual Control

If needed, you can manually control the service using:

```bash
# To stop the service
sudo launchctl unload /Library/LaunchDaemons/com.freelims.service.plist

# To start the service
sudo launchctl load /Library/LaunchDaemons/com.freelims.service.plist
```

## Troubleshooting

If you encounter issues:

1. Check the log files in the logs directory
2. Ensure all required ports (3001, 3002, 8001, 8002) are available
3. Verify the correct paths in the service configuration file
4. Make sure all scripts have executable permissions

## Notes

- The service requires admin privileges to install as it needs to run at system level
- If you move the FreeLIMS installation directory, you'll need to reinstall the service
- Service auto-recovery will attempt to restart environments if they crash 