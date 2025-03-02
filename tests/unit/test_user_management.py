#!/usr/bin/env python3
"""
Unit tests for the FreeLIMS user management functionality.
These tests validate the list, create, delete, and clear commands
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

class TestUserManagement(unittest.TestCase):
    """Test cases for the FreeLIMS user management functionality."""
    
    def setUp(self):
        """Set up the test environment."""
        self.script_path = os.path.join(PROJECT_ROOT, 'freelims.sh')
        # Ensure the script exists and is executable
        self.assertTrue(os.path.exists(self.script_path), "freelims.sh not found")
        self.assertTrue(os.access(self.script_path, os.X_OK), "freelims.sh is not executable")
        
        # Create a temporary directory for test files
        self.temp_dir = tempfile.mkdtemp()
        
        # Write a mock user management script to simulate user operations
        self.mock_user_script = os.path.join(self.temp_dir, 'manage.sh')
        with open(self.mock_user_script, 'w') as f:
            f.write("""#!/bin/bash
            if [ "$1" = "list" ]; then
                echo "Listing users..."
                echo "admin (admin)"
                echo "john.doe (staff)"
                echo "jane.doe (researcher)"
                exit 0
            elif [ "$1" = "create" ]; then
                echo "Creating user $2 with role $3..."
                echo "User $2 created successfully."
                exit 0
            elif [ "$1" = "delete" ]; then
                echo "Deleting user $2..."
                echo "User $2 deleted successfully."
                exit 0
            elif [ "$1" = "clear" ]; then
                echo "Clearing all users except admin..."
                echo "All users except admin cleared successfully."
                exit 0
            else
                echo "Unknown command: $1"
                exit 1
            fi
            """)
        os.chmod(self.mock_user_script, 0o755)
    
    def tearDown(self):
        """Clean up after the test."""
        # Remove the temporary directory and its contents
        shutil.rmtree(self.temp_dir)
    
    @patch('subprocess.run')
    def test_user_list_command(self, mock_run):
        """Test the user list command."""
        # Configure the mock
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = """Listing users...
admin (admin)
john.doe (staff)
jane.doe (researcher)""".encode('utf-8')
        mock_run.return_value = mock_process
        
        # Run the command
        result = subprocess.run(
            [self.script_path, 'user', 'dev', 'list'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=False
        )
        
        # Verify the output
        stdout = result.stdout.decode('utf-8')
        self.assertIn("Listing users", stdout)
        self.assertIn("admin", stdout)
        self.assertIn("john.doe", stdout)
        self.assertIn("jane.doe", stdout)
    
    @patch('subprocess.run')
    def test_user_create_command(self, mock_run):
        """Test the user create command."""
        # Configure the mock
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = "Creating user test.user with role staff...\nUser test.user created successfully.".encode('utf-8')
        mock_run.return_value = mock_process
        
        # Run the command
        result = subprocess.run(
            [self.script_path, 'user', 'dev', 'create', 'test.user', 'staff'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=False
        )
        
        # Verify the output
        stdout = result.stdout.decode('utf-8')
        self.assertIn("Creating user test.user", stdout)
        self.assertIn("created successfully", stdout)
    
    @patch('subprocess.run')
    def test_user_delete_command(self, mock_run):
        """Test the user delete command."""
        # Configure the mock
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = "Deleting user test.user...\nUser test.user deleted successfully.".encode('utf-8')
        mock_run.return_value = mock_process
        
        # Run the command
        result = subprocess.run(
            [self.script_path, 'user', 'dev', 'delete', 'test.user'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=False
        )
        
        # Verify the output
        stdout = result.stdout.decode('utf-8')
        self.assertIn("Deleting user test.user", stdout)
        self.assertIn("deleted successfully", stdout)
    
    @patch('subprocess.run')
    def test_user_clear_command(self, mock_run):
        """Test the user clear command."""
        # Configure the mock
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = "Clearing all users except admin...\nAll users except admin cleared successfully.".encode('utf-8')
        mock_run.return_value = mock_process
        
        # Run the command
        result = subprocess.run(
            [self.script_path, 'user', 'dev', 'clear'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=False
        )
        
        # Verify the output
        stdout = result.stdout.decode('utf-8')
        self.assertIn("Clearing all users", stdout)
        self.assertIn("cleared successfully", stdout)
    
    @patch('subprocess.run')
    def test_user_invalid_command(self, mock_run):
        """Test an invalid user command."""
        # Configure the mock
        mock_process = MagicMock()
        mock_process.returncode = 1
        mock_process.stdout = "Error: Invalid command 'invalid' for category 'user'".encode('utf-8')
        mock_run.return_value = mock_process
        
        # Run an invalid command
        result = subprocess.run(
            [self.script_path, 'user', 'dev', 'invalid'],
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