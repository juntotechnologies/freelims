#!/bin/bash

# FreeLIMS Clean Start Script
# This script finds and stops all running FreeLIMS processes, then starts the development environment

# Display header
echo "===================================="
echo "FreeLIMS Clean Start"
echo "===================================="
echo "Started at: $(date)"
echo ""

# Define paths
DEV_PATH="$(pwd)"
LOG_PATH="$DEV_PATH/logs"

# Make sure log directory exists
mkdir -p "$LOG_PATH"

echo "🔎 Checking for running FreeLIMS processes..."

# Check for running backend processes (uvicorn/Python)
BACKEND_PIDS=$(ps aux | grep -E "[p]ython.*uvicorn.*app.main:app" | awk '{print $2}')
if [ ! -z "$BACKEND_PIDS" ]; then
    echo "🔴 Found running backend processes:"
    ps aux | grep -E "[p]ython.*uvicorn.*app.main:app"
    echo "Stopping backend processes..."
    for PID in $BACKEND_PIDS; do
        echo "Killing backend process $PID..."
        kill -9 $PID
    done
    echo "✅ Backend processes stopped."
else
    echo "✅ No running backend processes found."
fi

# Check for running frontend processes (node/react)
FRONTEND_PIDS=$(ps aux | grep -E "[n]ode.*react-scripts start" | awk '{print $2}')
if [ ! -z "$FRONTEND_PIDS" ]; then
    echo "🔴 Found running frontend processes:"
    ps aux | grep -E "[n]ode.*react-scripts start"
    echo "Stopping frontend processes..."
    for PID in $FRONTEND_PIDS; do
        echo "Killing frontend process $PID..."
        kill -9 $PID
    done
    echo "✅ Frontend processes stopped."
else
    echo "✅ No running frontend processes found."
fi

# Check for processes on typical FreeLIMS ports
echo "🔎 Checking for processes on FreeLIMS ports..."

# Common backend ports
for PORT in {8000..8010}; do
    PORT_PIDS=$(lsof -i :$PORT -t)
    if [ ! -z "$PORT_PIDS" ]; then
        echo "🔴 Found process using backend port $PORT:"
        lsof -i :$PORT
        echo "Stopping process on port $PORT..."
        for PID in $PORT_PIDS; do
            echo "Killing process $PID on port $PORT..."
            kill -9 $PID
        done
        echo "✅ Process on port $PORT stopped."
    fi
done

# Common frontend ports
for PORT in {3000..3010}; do
    PORT_PIDS=$(lsof -i :$PORT -t)
    if [ ! -z "$PORT_PIDS" ]; then
        echo "🔴 Found process using frontend port $PORT:"
        lsof -i :$PORT
        echo "Stopping process on port $PORT..."
        for PID in $PORT_PIDS; do
            echo "Killing process $PID on port $PORT..."
            kill -9 $PID
        done
        echo "✅ Process on port $PORT stopped."
    fi
done

# Clean up any PID or port files
echo "🧹 Cleaning up PID and port files..."
if [ -f "$LOG_PATH/backend_dev.pid" ]; then
    rm "$LOG_PATH/backend_dev.pid"
    echo "Removed backend PID file."
fi

if [ -f "$LOG_PATH/frontend_dev.pid" ]; then
    rm "$LOG_PATH/frontend_dev.pid"
    echo "Removed frontend PID file."
fi

if [ -f "$LOG_PATH/backend_dev.port" ]; then
    rm "$LOG_PATH/backend_dev.port"
    echo "Removed backend port file."
fi

if [ -f "$LOG_PATH/frontend_dev.port" ]; then
    rm "$LOG_PATH/frontend_dev.port"
    echo "Removed frontend port file."
fi

# Clean up any temporary environment files
if [ -f "$DEV_PATH/frontend/.env.local" ]; then
    rm "$DEV_PATH/frontend/.env.local"
    echo "Removed temporary frontend environment file."
fi

echo ""
echo "🎯 All FreeLIMS processes have been stopped."
echo ""

# Start the development environment
echo "🚀 Starting FreeLIMS development environment..."
echo ""

# Run the development script
./run_dev.sh 