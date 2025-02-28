# FreeLIMS Documentation

Welcome to the FreeLIMS documentation. This directory contains comprehensive documentation for all aspects of the FreeLIMS system.

## Contents

- [**Database Management**](database_management.md): Complete guide for database backup, restore, and maintenance
- [Installation](installation.md): Installation instructions for different environments
- [Configuration](configuration.md): Configuration options and environment setup
- [User Guide](user_guide.md): End-user documentation for using FreeLIMS
- [Development](development.md): Guide for developers working on FreeLIMS
- [API Reference](api_reference.md): API documentation for the backend services

## Quick Start

For new installations, follow the [Installation Guide](installation.md) to get started.

For existing installations, the [User Guide](user_guide.md) will help you navigate the system.

For database management, including backup and restoration procedures, see the [Database Management Guide](database_management.md).

## Directory Structure

The FreeLIMS repository is organized as follows:

```
freelims/
├── backend/            # Backend API (FastAPI)
├── frontend/           # Frontend application (React)
├── scripts/            # Utility scripts
│   ├── db_backup.sh    # Database backup script
│   ├── db_manager.sh   # Core database management
│   ├── db_restore.sh   # Database restore script
│   └── utils/          # Utility functions
├── backups/            # Database backups location
├── logs/               # Log files
├── docs/               # Documentation (you are here)
└── config/             # Configuration files
```

## Support

If you need help with FreeLIMS, please check the documentation first. If you still have questions, contact the development team. 