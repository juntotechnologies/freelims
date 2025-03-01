# FreeLIMS Test Directory

This directory contains test and debugging resources organized by type.

## Directory Structure

- **html/** - HTML test pages for browser-based testing
  - `debug_auth.html` - Authentication debugging page
  - `debug_login.html` - Login debugging page
  - `test_browser.html` - Browser compatibility test page
  - `test_login.html` - Login interface test page

- **js/** - JavaScript test files
  - `test_frontend.js` - Frontend component tests
  - `test_login_frontend.js` - Login component tests
  - `test_login.js` - Login functionality tests
  - `websocket_test.js` - WebSocket functionality tests

- **python/** - Python-based test scripts
  - `create_test_data.py` - Script to generate test data for the system
  - `server_test.py` - Server functionality tests
  - `socket_test.py` - Socket connection tests
  - `trigger_notification.py` - Script to trigger test notifications

- **websocket/** - WebSocket testing resources
  - `websocket_test_summary.md` - Summary of WebSocket test results
  - `ws_monitor.log` - Log file from WebSocket monitoring

## How to Use

### HTML Tests
To use the HTML test pages, open them directly in a web browser while the FreeLIMS system is running.

### JavaScript Tests
Run the JavaScript tests using Node.js:

```bash
node test/js/test_filename.js
```

### Python Tests
Ensure your virtual environment is activated, then run:

```bash
python test/python/script_name.py
```

### WebSocket Tests
WebSocket monitoring tools have been moved to the utility scripts:

```bash
./freelims.sh utils websocket monitor
```

## Notes for Developers

- Add new tests to the appropriate subdirectory
- Update this README when adding significant new test resources
- Consider writing automated test suites in the future 