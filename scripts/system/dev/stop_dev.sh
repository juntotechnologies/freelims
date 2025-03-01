#!/bin/bash

# FreeLIMS Development Environment Stop Script
echo "===================================="
echo "Stopping FreeLIMS Development Environment"
echo "===================================="

LOG_PATH="$(pwd)/logs"

# Stop backend server
if [ -f "$LOG_PATH/backend_dev.pid" ]; then
    BACKEND_PID=$(cat "$LOG_PATH/backend_dev.pid")
    if ps -p $BACKEND_PID > /dev/null; then
        echo "Stopping backend server (PID: $BACKEND_PID)..."
        kill $BACKEND_PID
    else
        echo "Backend server is not running."
    fi
    rm "$LOG_PATH/backend_dev.pid"
else
    echo "Backend PID file not found."
    # Try to find and kill by port if port file exists
    if [ -f "$LOG_PATH/backend_dev.port" ]; then
        BACKEND_PORT=$(cat "$LOG_PATH/backend_dev.port")
        BACKEND_PID=$(lsof -i ":$BACKEND_PORT" -t)
        if [ ! -z "$BACKEND_PID" ]; then
            echo "Found backend server running on port $BACKEND_PORT (PID: $BACKEND_PID). Stopping..."
            kill $BACKEND_PID
        fi
        rm "$LOG_PATH/backend_dev.port"
    else
        echo "Backend port file not found. Cannot determine port."
    fi
fi

# Stop frontend server
if [ -f "$LOG_PATH/frontend_dev.pid" ]; then
    FRONTEND_PID=$(cat "$LOG_PATH/frontend_dev.pid")
    if ps -p $FRONTEND_PID > /dev/null; then
        echo "Stopping frontend server (PID: $FRONTEND_PID)..."
        kill $FRONTEND_PID
    else
        echo "Frontend server is not running."
    fi
    rm "$LOG_PATH/frontend_dev.pid"
else
    echo "Frontend PID file not found."
    # Try to find and kill by port if port file exists
    if [ -f "$LOG_PATH/frontend_dev.port" ]; then
        FRONTEND_PORT=$(cat "$LOG_PATH/frontend_dev.port")
        FRONTEND_PID=$(lsof -i ":$FRONTEND_PORT" -t)
        if [ ! -z "$FRONTEND_PID" ]; then
            echo "Found frontend server running on port $FRONTEND_PORT (PID: $FRONTEND_PID). Stopping..."
            kill $FRONTEND_PID
        fi
        rm "$LOG_PATH/frontend_dev.port"
    else
        echo "Frontend port file not found. Cannot determine port."
    fi
fi

# Additional cleanup for any missed processes
echo "Performing additional cleanup..."

# Check for uvicorn processes related to development - with the reload flag
if pgrep -f "uvicorn.*--reload" > /dev/null; then
    echo "Found additional development uvicorn processes, killing them..."
    pkill -9 -f "uvicorn.*--reload"
fi

# Check for react-scripts start processes
if pgrep -f "react-scripts start" > /dev/null; then
    echo "Found additional frontend development processes, killing them..."
    pkill -9 -f "react-scripts start"
fi

# Check common development ports
for PORT in 8000 8001 3001 3002; do
    PORT_PIDS=$(lsof -ti :$PORT 2>/dev/null)
    if [ ! -z "$PORT_PIDS" ]; then
        echo "Found processes on port $PORT: $PORT_PIDS"
        kill -9 $PORT_PIDS 2>/dev/null
    fi
done

echo "FreeLIMS development environment stopped."
echo "===================================="
