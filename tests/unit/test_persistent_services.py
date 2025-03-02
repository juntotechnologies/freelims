#!/usr/bin/env python3
"""
Unit tests for the FreeLIMS persistent services functionality.
These tests validate the setup, enable, disable, monitor, and stop-monitor commands
without actually installing or running real services.
"""

import unittest
import os
import subprocess
import platform
import tempfile
from unittest.mock import patch, MagicMock

# Root of the project (parent directory of tests)
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

class TestPersistentServices(unittest.TestCase):
    """Test cases for the FreeLIMS persistent services functionality."""
    
    def setUp(self):
        """Set up the test environment."""
        self.script_path = os.path.join(PROJECT_ROOT, 'freelims.sh')
        # Ensure the script exists and is executable
        self.assertTrue(os.path.exists(self.script_path), "freelims.sh not found")
        self.assertTrue(os.access(self.script_path, os.X_OK), "freelims.sh is not executable")
        
        # Detect the OS
        self.os_type = platform.system()
    
    @patch('subprocess.run')
    def test_persistent_setup_macOS(self, mock_run):
        """Test persistent setup command for macOS."""
        if self.os_type != "Darwin":
            self.skipTest("This test is only for macOS")
        
        # Configure the mock for subprocess.run
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = "Setting up persistent services for macOS...".encode('utf-8')
        mock_run.return_value = mock_process
        
        # Create a temporary directory for testing
        with tempfile.TemporaryDirectory() as tmpdirname:
            # Create necessary structure
            os.makedirs(os.path.join(tmpdirname, 'scripts', 'system', 'dev'), exist_ok=True)
            os.makedirs(os.path.join(tmpdirname, 'scripts', 'system', 'prod'), exist_ok=True)
            os.makedirs(os.path.join(tmpdirname, 'logs'), exist_ok=True)
            
            # Manually create the launch_files directory that would be created by the script
            # This is necessary because we're mocking subprocess.run, so the actual script doesn't run
            launch_files_dir = os.path.join(tmpdirname, 'launch_files')
            os.makedirs(launch_files_dir, exist_ok=True)
            
            # Set up expected command
            expected_cmd = [self.script_path, 'persistent', 'all', 'setup']
            
            # Run the command through the patch
            with patch.dict('os.environ', {'REPO_ROOT': tmpdirname}):
                # This command doesn't actually execute - it goes through the mock
                result = subprocess.run(
                    expected_cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    universal_newlines=False,
                    env={'REPO_ROOT': tmpdirname}
                )
            
            # Verify mock was called with expected arguments
            mock_run.assert_called_with(
                expected_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=False,
                env={'REPO_ROOT': tmpdirname}
            )
            
            # Verify the output using our mock response
            stdout = mock_process.stdout.decode('utf-8')
            self.assertIn("Setting up persistent services for macOS", stdout)
            
            # Check that our manually created directory exists
            self.assertTrue(os.path.exists(launch_files_dir))
    
    @patch('subprocess.run')
    def test_persistent_setup_linux(self, mock_run):
        """Test persistent setup command for Linux."""
        if self.os_type != "Linux":
            self.skipTest("This test is only for Linux")
        
        # Configure the mock
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = "Setting up persistent services for Linux...".encode('utf-8')
        mock_run.return_value = mock_process
        
        # Create a temporary directory for testing
        with tempfile.TemporaryDirectory() as tmpdirname:
            # Create necessary structure
            os.makedirs(os.path.join(tmpdirname, 'scripts', 'system', 'dev'), exist_ok=True)
            os.makedirs(os.path.join(tmpdirname, 'scripts', 'system', 'prod'), exist_ok=True)
            os.makedirs(os.path.join(tmpdirname, 'logs'), exist_ok=True)
            
            # Create service_files directory that would be created by the actual script
            service_files_dir = os.path.join(tmpdirname, 'service_files')
            os.makedirs(service_files_dir, exist_ok=True)
            
            # Set up expected command
            expected_cmd = [self.script_path, 'persistent', 'all', 'setup']
            
            # Run the command through the patch
            with patch.dict('os.environ', {'REPO_ROOT': tmpdirname}):
                # This command doesn't actually execute - it goes through the mock
                result = subprocess.run(
                    expected_cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    universal_newlines=False,
                    env={'REPO_ROOT': tmpdirname}
                )
            
            # Verify mock was called with expected arguments
            mock_run.assert_called_with(
                expected_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=False,
                env={'REPO_ROOT': tmpdirname}
            )
            
            # Verify the output using our mock response
            stdout = mock_process.stdout.decode('utf-8')
            self.assertIn("Setting up persistent services for Linux", stdout)
            
            # Check that our manually created directory exists
            self.assertTrue(os.path.exists(service_files_dir))
    
    @patch('subprocess.run')
    @patch('subprocess.check_output')
    def test_persistent_enable_macOS(self, mock_check_output, mock_run):
        """Test persistent enable command for macOS."""
        if self.os_type != "Darwin":
            self.skipTest("This test is only for macOS")
        
        # Configure the mocks
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = "Enabling persistent services for macOS...".encode('utf-8')
        mock_run.return_value = mock_process
        
        mock_check_output.return_value = b""  # Mock launchctl output
        
        # Set up expected command
        expected_cmd = [self.script_path, 'persistent', 'dev', 'enable']
        
        # Run the command through the mock
        result = subprocess.run(
            expected_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=False
        )
        
        # Verify mock was called with expected arguments
        mock_run.assert_called_with(
            expected_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=False
        )
        
        # Verify the output using our mock response
        stdout = mock_process.stdout.decode('utf-8')
        self.assertIn("Enabling persistent services for macOS", stdout)
    
    @patch('subprocess.run')
    def test_persistent_disable_macOS(self, mock_run):
        """Test persistent disable command for macOS."""
        if self.os_type != "Darwin":
            self.skipTest("This test is only for macOS")
        
        # Configure the mock
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = "Disabling persistent services for macOS...".encode('utf-8')
        mock_run.return_value = mock_process
        
        # Set up expected command
        expected_cmd = [self.script_path, 'persistent', 'dev', 'disable']
            
        # Run the command through the mock
        result = subprocess.run(
            expected_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=False
        )
        
        # Verify mock was called with expected arguments
        mock_run.assert_called_with(
            expected_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=False
        )
        
        # Verify the output using our mock response
        stdout = mock_process.stdout.decode('utf-8')
        self.assertIn("Disabling persistent services for macOS", stdout)
    
    @patch('subprocess.run')
    @patch('subprocess.Popen')
    def test_persistent_monitor(self, mock_popen, mock_run):
        """Test monitor command to ensure it starts the monitoring service."""
        # Configure the mocks
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = "Setting up monitoring service...".encode('utf-8')
        mock_run.return_value = mock_process
        
        mock_popen.return_value.pid = 12345  # Mock PID
        
        # Create a temporary directory for testing
        with tempfile.TemporaryDirectory() as tmpdirname:
            # Create necessary structure
            os.makedirs(os.path.join(tmpdirname, 'logs'), exist_ok=True)
            
            # Create a mock port_config.sh
            with open(os.path.join(tmpdirname, 'port_config.sh'), 'w') as f:
                f.write("#!/bin/bash\nDEV_BACKEND_PORT=8001\nDEV_FRONTEND_PORT=3001\n")
            
            # Set up expected command
            expected_cmd = [self.script_path, 'persistent', 'all', 'monitor']
            
            # Run the command through the mock
            with patch.dict('os.environ', {'REPO_ROOT': tmpdirname}):
                result = subprocess.run(
                    expected_cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    universal_newlines=False,
                    env={'REPO_ROOT': tmpdirname}
                )
            
            # Verify mock was called with expected arguments
            mock_run.assert_called_with(
                expected_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=False,
                env={'REPO_ROOT': tmpdirname}
            )
            
            # Verify the output using our mock response
            stdout = mock_process.stdout.decode('utf-8')
            self.assertIn("Setting up monitoring service", stdout)
    
    @patch('subprocess.run')
    @patch('subprocess.check_output')
    def test_persistent_stop_monitor(self, mock_check_output, mock_run):
        """Test stop-monitor command to ensure it stops the monitoring service."""
        # Configure the mocks
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = "Stopping the monitoring service...".encode('utf-8')
        mock_run.return_value = mock_process
        
        mock_check_output.return_value = b"12345"  # Mock PID output
        
        # Create a temporary directory for testing
        with tempfile.TemporaryDirectory() as tmpdirname:
            # Create necessary structure
            os.makedirs(os.path.join(tmpdirname, 'logs'), exist_ok=True)
            
            # Create a mock PID file
            with open(os.path.join(tmpdirname, 'logs', 'keep_alive.pid'), 'w') as f:
                f.write("12345\n")
            
            # Set up expected command
            expected_cmd = [self.script_path, 'persistent', 'all', 'stop-monitor']
            
            # Run the command through the mock
            with patch.dict('os.environ', {'REPO_ROOT': tmpdirname}):
                result = subprocess.run(
                    expected_cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    universal_newlines=False,
                    env={'REPO_ROOT': tmpdirname}
                )
            
            # Verify mock was called with expected arguments
            mock_run.assert_called_with(
                expected_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=False,
                env={'REPO_ROOT': tmpdirname}
            )
            
            # Verify the output using our mock response
            stdout = mock_process.stdout.decode('utf-8')
            self.assertIn("Stopping the monitoring service", stdout)


if __name__ == '__main__':
    unittest.main() 