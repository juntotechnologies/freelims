# FreeLIMS Tests

This directory contains test scripts for the FreeLIMS management script.

## Test Structure

The tests are organized into the following categories:

- **Unit Tests**: Tests individual components of the script without external dependencies
- **Integration Tests**: Tests interactions between components in a controlled environment

## Running Tests

### Using the Run Script

The simplest way to run the tests is to use the provided script:

```bash
./run_tests.sh
```

This script will:
1. Create a virtual environment if one doesn't exist
2. Install the required dependencies
3. Run the unit tests
4. Optionally run integration tests (requires confirmation)

### Manual Execution

If you prefer to run the tests manually:

1. Create a virtual environment and install dependencies:
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

2. Run all tests:
```bash
pytest
```

3. Run only unit tests:
```bash
pytest unit/
```

4. Run only integration tests:
```bash
pytest integration/
```

5. Run a specific test file:
```bash
pytest unit/test_freelims.py
```

6. Run with coverage:
```bash
pytest --cov=. --cov-report=term
```

## GitHub Actions

The tests are automatically run on GitHub Actions when pushing to the `main` or `develop` branches, or when creating a pull request to these branches.

The GitHub Actions workflow:
- Tests on both Ubuntu and macOS
- Tests with Python 3.9 and 3.10
- Generates coverage reports
- Uploads test results as artifacts

## Test Coverage

The tests cover the following functionality:

- **Base Script Commands**: Help display, version display
- **System Management**: Start, stop, restart, status
- **Database Management**: Backup, restore, init, migrate
- **User Management**: List, create, delete, clear
- **Port Management**: List, check, free
- **Persistent Services**: Setup, enable, disable, monitor, stop-monitor

## Mocking Strategy

To avoid side effects and enable fast test execution, these tests use mocking extensively:

- Files and directories are created in temporary locations
- External commands are mocked to simulate their output
- Database operations are simulated without actual connections
- Network operations are simulated without actual ports

## Writing New Tests

When adding new functionality to the script, please:

1. Add unit tests for the new functions
2. Add integration tests if the feature interacts with other components
3. Run the full test suite to ensure no regressions
4. Check test coverage to ensure the new code is well-tested 