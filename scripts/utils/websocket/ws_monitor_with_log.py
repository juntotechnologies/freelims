#!/usr/bin/env python
import asyncio
import socketio
import argparse
import sys
import json
import os
from datetime import datetime

# Create command-line argument parser
parser = argparse.ArgumentParser(description='WebSocket monitoring tool for FreeLIMS')
parser.add_argument('--url', default='http://localhost:8001', help='WebSocket server base URL')
parser.add_argument('--log-file', default='ws_monitor.log', help='Log file path')
args = parser.parse_args()

# Create log directory and file
log_file = args.log_file
log_dir = os.path.dirname(log_file)
if log_dir and not os.path.exists(log_dir):
    os.makedirs(log_dir)

def log_message(message):
    """Log a message to both console and file"""
    now = datetime.now().strftime('%H:%M:%S')
    formatted_message = f"[{now}] {message}"
    print(formatted_message)
    with open(log_file, 'a') as f:
        f.write(formatted_message + '\n')

# Create a Socket.IO client
sio = socketio.AsyncClient(logger=True, engineio_logger=True)

# Event handlers
@sio.event
async def connect():
    log_message(f"✅ Connected to WebSocket server at {args.url}/ws")
    log_message(f"🔄 Subscribing to resource channels...")
    
    # Subscribe to all resource channels
    resources = ['inventory', 'experiments', 'tests', 'users', 'locations']
    for resource in resources:
        await sio.emit('subscribe', {'resource': resource})
        log_message(f"📢 Attempting to subscribe to {resource}")

@sio.event
async def connect_error(error):
    log_message(f"❌ Connection error: {error}")

@sio.event
async def disconnect():
    log_message(f"🔌 Disconnected from server")

@sio.event
async def subscription_success(data):
    log_message(f"✅ Successfully subscribed to {data['resource']}")

@sio.event
async def subscription_error(data):
    log_message(f"❌ Subscription error: {data['message']}")

# Define handlers for resource updates
@sio.event
async def inventory_updated(data):
    log_message(f"📦 Received inventory update:")
    log_message(json.dumps(data, indent=2))

@sio.event
async def experiments_updated(data):
    log_message(f"🧪 Received experiments update:")
    log_message(json.dumps(data, indent=2))

@sio.event
async def tests_updated(data):
    log_message(f"📋 Received tests update:")
    log_message(json.dumps(data, indent=2))

@sio.event
async def users_updated(data):
    log_message(f"📣 Received users update:")
    formatted_data = json.dumps(data, indent=2)
    log_message(formatted_data)

@sio.event
async def locations_updated(data):
    log_message(f"📣 Received locations update:")
    formatted_data = json.dumps(data, indent=2)
    log_message(formatted_data)

async def main():
    log_message("WebSocket Monitor for FreeLIMS")
    log_message("==============================")
    log_message(f"Connecting to: {args.url}/ws/socket.io")
    log_message(f"Logging to: {os.path.abspath(log_file)}")
    
    try:
        # Use the exact same format that worked in our test
        await sio.connect(
            f"{args.url}", 
            transports=["polling", "websocket"],
            namespaces=["/"],
            socketio_path="ws/socket.io"
        )
        
        # Keep the client running
        while True:
            await asyncio.sleep(1)
            
    except socketio.exceptions.ConnectionError as e:
        log_message(f"❌ Failed to connect: {e}")
    except KeyboardInterrupt:
        log_message("\n👋 Exiting WebSocket monitor...")
    finally:
        if sio.connected:
            await sio.disconnect()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        log_message("\n👋 Exiting WebSocket monitor...")
        sys.exit(0) 