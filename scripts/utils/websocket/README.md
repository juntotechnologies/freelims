# FreeLIMS WebSocket Monitoring Utilities

This directory contains scripts for monitoring and testing WebSocket connections in the FreeLIMS system.

## Available Scripts

- `ws_monitor.py` - Basic WebSocket monitoring script
- `ws_monitor_with_log.py` - WebSocket monitoring with enhanced logging capabilities

## How to Use

These scripts are best used through the FreeLIMS management system:

```bash
# Basic monitoring
./freelims.sh utils websocket monitor

# Monitoring with verbose logging
./freelims.sh utils websocket monitor --verbose
```

## Manual Usage

If you need to run these scripts directly:

```bash
# Basic monitoring
python scripts/utils/websocket/ws_monitor.py

# Monitoring with logging
python scripts/utils/websocket/ws_monitor_with_log.py
```

## Configuration

These scripts use the FreeLIMS port configuration from `port_config.sh` by default.
If you need to modify the WebSocket endpoint, edit the script and update the `ws_url` variable.

## Output

Monitoring output will be displayed in the terminal. When using the logging-enabled version,
a log file will also be created in the logs directory.

## Notes

- These scripts require the `websocket-client` Python package
- The monitoring can be terminated by pressing Ctrl+C
- For detailed WebSocket testing, see the test scripts in the `test/websocket/` directory 