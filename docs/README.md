# FreeLIMS Documentation

Welcome to the FreeLIMS documentation. This directory contains comprehensive documentation for all aspects of the FreeLIMS system.

## Contents

- [**WORKFLOW**](WORKFLOW.md): Complete guide to development and deployment workflow including Git strategy
- [**MAC_MINI_SETUP**](MAC_MINI_SETUP.md): Detailed setup documentation for the Mac Mini deployment
- [**Database Management**](database_management.md): Complete guide for database backup, restore, and maintenance
- [**Development**](DEVELOPMENT.md): Guide for developers working on FreeLIMS
- [**Repository Management**](REPOSITORY.md): Guidelines for managing the Git repository
- [**Database**](DATABASE.md): Database structure and configuration
- [**Deployment**](DEPLOYMENT.md): Deployment procedures and configurations
- [**Network Access**](network_access_instructions.md): Instructions for network access to the system

## Quick Start

For understanding the system architecture, start with the [MAC_MINI_SETUP.md](MAC_MINI_SETUP.md) documentation.

For development workflow, follow the [WORKFLOW.md](WORKFLOW.md) guide.

For database management, including backup and restoration procedures, see the [Database Management Guide](database_management.md).

## Directory Structure

The FreeLIMS repository is organized as follows:

```
freelims/
├── backend/               # Backend API (FastAPI)
├── frontend/              # Frontend application (React)
├── scripts/               # Utility scripts
│   ├── system/            # System configuration scripts
│   │   └── setup/         # Setup scripts for system configuration
│   ├── deploy/            # Deployment scripts
│   └── dev/               # Development utilities
├── docs/                  # Documentation (you are here)
│   └── images/            # Documentation images
├── logs/                  # Log files
└── service_files/         # Service configuration files
```

## Support

If you need help with FreeLIMS, please check the documentation first. If you still have questions, contact the development team. 