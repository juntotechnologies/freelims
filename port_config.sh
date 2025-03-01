#!/bin/bash
#
# FreeLIMS Port Configuration
# This file defines standard ports for different environments
# and provides utility functions for port management
#

# Standard port assignments
DEV_BACKEND_PORT=8001
DEV_FRONTEND_PORT=3001
PROD_BACKEND_PORT=8002
PROD_FRONTEND_PORT=3002

# Check if a port is in use
is_port_in_use() {
    local port=$1
    if lsof -i :$port -t >/dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Get process using a specific port
get_process_on_port() {
    local port=$1
    local pids=$(lsof -i :$port -t 2>/dev/null)
    
    if [ -n "$pids" ]; then
        for pid in $pids; do
            local process_info=$(ps -p $pid -o comm= 2>/dev/null)
            if [ -n "$process_info" ]; then
                echo "PID: $pid ($process_info)"
            else
                echo "PID: $pid"
            fi
        done
    else
        echo "No process found on port $port"
    fi
}

# Safe kill process on port with confirmation
safe_kill_process_on_port() {
    local port=$1
    local force=${2:-"no"}  # Whether to force kill without confirmation
    local pids=$(lsof -i :$port -t 2>/dev/null)
    
    if [ -z "$pids" ]; then
        echo "No process found on port $port"
        return 0
    fi
    
    echo "Processes using port $port:"
    for pid in $pids; do
        ps -p $pid -o pid,ppid,user,command 2>/dev/null
    done
    
    if [ "$force" != "yes" ]; then
        read -p "Do you want to terminate these processes? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy] ]]; then
            echo "Operation cancelled"
            return 1
        fi
    fi
    
    for pid in $pids; do
        echo "Terminating process with PID $pid"
        kill -9 $pid 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "Process terminated successfully"
        else
            echo "Failed to terminate process"
            return 1
        fi
    done
    
    # Verify port is now free
    sleep 1
    if is_port_in_use $port; then
        echo "Warning: Port $port is still in use"
        return 1
    else
        echo "Port $port is now free"
        return 0
    fi
}

# Display port configuration
show_port_config() {
    echo "FreeLIMS Port Configuration"
    echo "============================"
    echo "Development Environment:"
    echo "  - Backend API: $DEV_BACKEND_PORT"
    echo "  - Frontend App: $DEV_FRONTEND_PORT"
    echo ""
    echo "Production Environment:"
    echo "  - Backend API: $PROD_BACKEND_PORT"
    echo "  - Frontend App: $PROD_FRONTEND_PORT"
} 