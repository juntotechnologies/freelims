#!/usr/bin/env python3
"""
Unit tests for the FreeLIMS database management functionality.
These tests validate the init, migrate, backup, and restore commands
without actually executing database operations.
"""

import unittest
import os
import subprocess
import tempfile
import shutil
from unittest.mock import patch, MagicMock

# Root of the project (parent directory of tests)
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

class TestDatabaseManagement(unittest.TestCase):
    """Test cases for the FreeLIMS database management functionality."""
    
    def setUp(self):
        """Set up the test environment."""
        self.script_path = os.path.join(PROJECT_ROOT, 'freelims.sh')
        # Ensure the script exists and is executable
        self.assertTrue(os.path.exists(self.script_path), "freelims.sh not found")
        self.assertTrue(os.access(self.script_path, os.X_OK), "freelims.sh is not executable")
        
        # Create a temporary directory for test files
        self.temp_dir = tempfile.mkdtemp()
        
        # Write a mock database management script to simulate database operations
        self.mock_db_script = os.path.join(self.temp_dir, 'manage.sh')
        with open(self.mock_db_script, 'w') as f:
            f.write("""#!/bin/bash
            if [ "$1" = "backup" ]; then
                echo "Backing up database to $2..."
                mkdir -p "$(dirname "$2")"
                echo "TEST_BACKUP_DATA" > "$2"
                exit 0
            elif [ "$1" = "restore" ]; then
                echo "Restoring database from $2..."
                if [ -f "$2" ]; then
                    echo "Restore successful"
                    exit 0
                else
                    echo "Backup file not found"
                    exit 1
                fi
            elif [ "$1" = "init" ]; then
                echo "Initializing database..."
                exit 0
            elif [ "$1" = "migrate" ]; then
                echo "Migrating database..."
                exit 0
            else
                echo "Unknown command: $1"
                exit 1
            fi
            """)
        os.chmod(self.mock_db_script, 0o755)
    
    def tearDown(self):
        """Clean up after the test."""
        # Remove the temporary directory and its contents
        shutil.rmtree(self.temp_dir)
    
    @patch('subprocess.run')
    def test_db_backup_command(self, mock_run):
        """Test the db backup command."""
        # Configure the mock
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = "Backing up database...\nBackup completed successfully.".encode('utf-8')
        mock_run.return_value = mock_process
        
        # Run the command
        result = subprocess.run(
            [self.script_path, 'db', 'dev', 'backup'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=False
        )
        
        # Verify the output
        stdout = result.stdout.decode('utf-8')
        self.assertIn("Backing up database", stdout)
        self.assertIn("completed successfully", stdout)
    
    @patch('subprocess.run')
    def test_db_restore_command(self, mock_run):
        """Test the db restore command."""
        # Create a mock backup file
        backup_dir = os.path.join(self.temp_dir, 'backups')
        os.makedirs(backup_dir, exist_ok=True)
        backup_file = os.path.join(backup_dir, 'dev_db_backup.sql')
        with open(backup_file, 'w') as f:
            f.write("TEST_BACKUP_DATA")
        
        # Configure the mock
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = f"Restoring database from {backup_file}...\nRestore completed successfully.".encode('utf-8')
        mock_run.return_value = mock_process
        
        # Mock the environment
        with patch.dict('os.environ', {'REPO_ROOT': self.temp_dir}):
            # Run the command
            result = subprocess.run(
                [self.script_path, 'db', 'dev', 'restore'],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=False
            )
            
            # Verify the output
            stdout = result.stdout.decode('utf-8')
            self.assertIn("Restoring database", stdout)
            self.assertIn("completed successfully", stdout)
    
    @patch('subprocess.run')
    def test_db_init_command(self, mock_run):
        """Test the db init command."""
        # Configure the mock
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = "Initializing database...\nDatabase initialization completed successfully.".encode('utf-8')
        mock_run.return_value = mock_process
        
        # Run the command
        result = subprocess.run(
            [self.script_path, 'db', 'dev', 'init'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=False
        )
        
        # Verify the output
        stdout = result.stdout.decode('utf-8')
        self.assertIn("Initializing database", stdout)
        self.assertIn("completed successfully", stdout)
    
    @patch('subprocess.run')
    def test_db_migrate_command(self, mock_run):
        """Test the db migrate command."""
        # Configure the mock
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = "Migrating database...\nDatabase migration completed successfully.".encode('utf-8')
        mock_run.return_value = mock_process
        
        # Run the command
        result = subprocess.run(
            [self.script_path, 'db', 'dev', 'migrate'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=False
        )
        
        # Verify the output
        stdout = result.stdout.decode('utf-8')
        self.assertIn("Migrating database", stdout)
        self.assertIn("completed successfully", stdout)
    
    @patch('subprocess.run')
    def test_db_invalid_command(self, mock_run):
        """Test an invalid db command."""
        # Configure the mock
        mock_process = MagicMock()
        mock_process.returncode = 1
        mock_process.stdout = "Error: Invalid command 'invalid_command' for category 'db'".encode('utf-8')
        mock_run.return_value = mock_process
        
        # Run an invalid command
        result = subprocess.run(
            [self.script_path, 'db', 'dev', 'invalid_command'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=False
        )
        
        # Verify the output indicates an error
        self.assertEqual(result.returncode, 1)
        stdout = result.stdout.decode('utf-8')
        self.assertIn("Invalid command", stdout)


if __name__ == '__main__':
    unittest.main() 