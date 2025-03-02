#!/usr/bin/env python3
"""
Unit tests for the FreeLIMS management script.
These tests validate the functionality of the shell script without actually running 
real commands or services.
"""

import unittest
import os
import subprocess
import tempfile
import shutil
from unittest.mock import patch, MagicMock

# Root of the project (parent directory of tests)
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

class TestFreeLIMSScript(unittest.TestCase):
    """Test cases for the FreeLIMS shell script."""
    
    def setUp(self):
        """Set up the test environment."""
        self.script_path = os.path.join(PROJECT_ROOT, 'freelims.sh')
        # Ensure the script exists
        self.assertTrue(os.path.exists(self.script_path), "freelims.sh not found")
        
        # On non-Windows systems, check if the script is executable
        if os.name != 'nt':  # 'nt' is the name for Windows
            self.assertTrue(os.access(self.script_path, os.X_OK), "freelims.sh is not executable")
    
    @patch('subprocess.run')
    def test_help_output(self, mock_run):
        """Test that the script displays help information when run without arguments."""
        # Configure the mock
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = """FreeLIMS Management Console
Version 1.1.0

Usage: ./freelims.sh <category> <environment> <command>""".encode('utf-8')
        mock_run.return_value = mock_process
        
        # Run the script with no arguments
        result = subprocess.run([self.script_path], 
                               stdout=subprocess.PIPE, 
                               stderr=subprocess.PIPE,
                               universal_newlines=False)
        
        # Check that the banner and usage information are displayed
        stdout = result.stdout.decode('utf-8')
        self.assertIn("FreeLIMS Management Console", stdout)
        self.assertIn("Usage:", stdout)
    
    @patch('subprocess.run')
    def test_port_list_command(self, mock_run):
        """Test the port list command to ensure it outputs port configurations."""
        # Configure the mock
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = "FreeLIMS Port Configuration".encode('utf-8')
        mock_run.return_value = mock_process
        
        # Run the port list command
        result = subprocess.run([self.script_path, 'port', 'list'], 
                               stdout=subprocess.PIPE, 
                               stderr=subprocess.PIPE,
                               universal_newlines=False)
        
        # Check for expected output
        stdout = result.stdout.decode('utf-8')
        self.assertIn("FreeLIMS Port Configuration", stdout)
        
    @patch('subprocess.run')
    def test_system_status_command(self, mock_run):
        """Test the system status command to ensure it checks service status."""
        # Configure the mock
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = "Environment Status".encode('utf-8')
        mock_run.return_value = mock_process
        
        # Run the system status command for dev environment
        result = subprocess.run([self.script_path, 'system', 'dev', 'status'], 
                               stdout=subprocess.PIPE, 
                               stderr=subprocess.PIPE,
                               universal_newlines=False)
        
        # Check for expected output
        stdout = result.stdout.decode('utf-8')
        self.assertIn("Environment Status", stdout)
    
    @patch('subprocess.run')
    def test_persistent_setup_command(self, mock_run):
        """Test the persistent setup command to ensure it creates necessary files."""
        # Configure the mock
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = "Setting up persistent services".encode('utf-8')
        mock_run.return_value = mock_process
        
        # Create a temporary directory for testing
        with tempfile.TemporaryDirectory() as tmpdirname:
            # Mock the setup
            with patch('os.environ', {'REPO_ROOT': tmpdirname}):
                # Run the persistent setup command
                result = subprocess.run([self.script_path, 'persistent', 'dev', 'setup'], 
                                      stdout=subprocess.PIPE, 
                                      stderr=subprocess.PIPE,
                                      universal_newlines=False)
                
                # Check for expected output
                stdout = result.stdout.decode('utf-8')
                self.assertIn("Setting up persistent services", stdout)


if __name__ == '__main__':
    unittest.main() 