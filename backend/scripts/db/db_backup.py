#!/usr/bin/env python3
"""
FreeLIMS Database Backup Script
This script creates a backup of the FreeLIMS database.
"""

import os
import sys
import datetime
import subprocess
import argparse
from pathlib import Path

# Add parent directory to path to import config
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

try:
    from app.core.config import settings
except ImportError:
    print("Error: Could not import settings. Make sure you're running this script from the project root.")
    sys.exit(1)

def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='Backup FreeLIMS database')
    parser.add_argument('environment', nargs='?', default='dev', choices=['dev', 'prod'],
                        help='Environment to backup (dev or prod)')
    return parser.parse_args()

def get_db_url(environment):
    """Get database URL based on environment."""
    if environment == 'prod':
        return settings.PROD_DATABASE_URL
    return settings.DATABASE_URL

def create_backup_dir():
    """Create backup directory if it doesn't exist."""
    backup_dir = Path(__file__).resolve().parent.parent.parent.parent / 'backups'
    if not backup_dir.exists():
        backup_dir.mkdir(parents=True)
    return backup_dir

def backup_database(db_url, backup_dir, environment):
    """Backup the database using pg_dump."""
    timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_file = backup_dir / f"freelims_{environment}_{timestamp}.sql"
    
    # Parse database URL to get connection details
    # Format: postgresql://username:password@host:port/dbname
    db_parts = db_url.replace('postgresql://', '').split('/')
    db_name = db_parts[1]
    connection = db_parts[0].split('@')
    credentials = connection[0].split(':')
    username = credentials[0]
    password = credentials[1] if len(credentials) > 1 else None
    host_port = connection[1].split(':')
    host = host_port[0]
    port = host_port[1] if len(host_port) > 1 else '5432'
    
    # Set environment variables for pg_dump
    env = os.environ.copy()
    if password:
        env['PGPASSWORD'] = password
    
    # Build pg_dump command
    cmd = [
        'pg_dump',
        '-h', host,
        '-p', port,
        '-U', username,
        '-F', 'c',  # Custom format (compressed)
        '-b',       # Include large objects
        '-v',       # Verbose
        '-f', str(backup_file),
        db_name
    ]
    
    print(f"Backing up {environment} database to {backup_file}...")
    
    try:
        result = subprocess.run(cmd, env=env, check=True, capture_output=True, text=True)
        print(f"Backup completed successfully: {backup_file}")
        print(result.stdout)
        return str(backup_file)
    except subprocess.CalledProcessError as e:
        print(f"Error during backup: {e}")
        print(e.stderr)
        return None

def main():
    """Main function."""
    args = parse_args()
    environment = args.environment
    
    print(f"Starting backup of {environment} database...")
    
    # Get database URL
    db_url = get_db_url(environment)
    if not db_url:
        print(f"Error: No database URL found for {environment} environment.")
        sys.exit(1)
    
    # Create backup directory
    backup_dir = create_backup_dir()
    
    # Backup database
    backup_file = backup_database(db_url, backup_dir, environment)
    
    if backup_file:
        print(f"Database backup completed: {backup_file}")
    else:
        print("Database backup failed.")
        sys.exit(1)

if __name__ == "__main__":
    main() 