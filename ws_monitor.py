#!/usr/bin/env python
import asyncio
import socketio
import argparse
import sys
import json
from datetime import datetime

# Create command-line argument parser
parser = argparse.ArgumentParser(description='WebSocket monitoring tool for FreeLIMS')
parser.add_argument('--url', default='http://localhost:8001', help='WebSocket server base URL')
parser.add_argument('--env', choices=['dev', 'prod'], default='dev', help='Environment to monitor (dev=8001, prod=8002)')
args = parser.parse_args()

# Determine correct URL based on environment flag
if args.env == 'prod' and args.url == 'http://localhost:8001':
    # If --env=prod is specified but default URL is used, switch to production port
    base_url = 'http://localhost:8002'
    print(f"Environment set to production, using URL: {base_url}")
else:
    base_url = args.url

# Create a Socket.IO client
sio = socketio.AsyncClient(logger=True, engineio_logger=True)

# Event handlers
@sio.event
async def connect():
    now = datetime.now().strftime('%H:%M:%S')
    print(f"[{now}] ✅ Connected to WebSocket server at {base_url}/ws")
    print(f"[{now}] 🔄 Subscribing to resource channels...")
    
    # Subscribe to all resource channels
    resources = ['inventory', 'experiments', 'samples', 'tests', 'users', 'locations']
    for resource in resources:
        await sio.emit('subscribe', {'resource': resource})
        print(f"[{now}] 📢 Attempting to subscribe to {resource}")

@sio.event
async def connect_error(error):
    now = datetime.now().strftime('%H:%M:%S')
    print(f"[{now}] ❌ Connection error: {error}")

@sio.event
async def disconnect():
    now = datetime.now().strftime('%H:%M:%S')
    print(f"[{now}] 🔌 Disconnected from server")

@sio.event
async def subscription_success(data):
    now = datetime.now().strftime('%H:%M:%S')
    print(f"[{now}] ✅ Successfully subscribed to {data['resource']}")

@sio.event
async def subscription_error(data):
    now = datetime.now().strftime('%H:%M:%S')
    print(f"[{now}] ❌ Subscription error: {data['message']}")

# Define handlers for resource updates
@sio.event
async def inventory_updated(data):
    now = datetime.now().strftime('%H:%M:%S')
    print(f"[{now}] 📣 Received inventory update:")
    print(json.dumps(data, indent=2))

@sio.event
async def experiments_updated(data):
    now = datetime.now().strftime('%H:%M:%S')
    print(f"[{now}] 📣 Received experiments update:")
    print(json.dumps(data, indent=2))

@sio.event
async def samples_updated(data):
    now = datetime.now().strftime('%H:%M:%S')
    print(f"[{now}] 📣 Received samples update:")
    print(json.dumps(data, indent=2))

@sio.event
async def tests_updated(data):
    now = datetime.now().strftime('%H:%M:%S')
    print(f"[{now}] 📣 Received tests update:")
    print(json.dumps(data, indent=2))

@sio.event
async def users_updated(data):
    now = datetime.now().strftime('%H:%M:%S')
    print(f"[{now}] 📣 Received users update:")
    print(json.dumps(data, indent=2))

@sio.event
async def locations_updated(data):
    now = datetime.now().strftime('%H:%M:%S')
    print(f"[{now}] 📣 Received locations update:")
    print(json.dumps(data, indent=2))

async def main():
    print(f"WebSocket Monitor for FreeLIMS")
    print(f"==============================")
    print(f"Environment: {args.env.upper()}")
    print(f"Connecting to: {base_url}/ws/socket.io")
    
    try:
        # Use the exact same format that worked in our test
        await sio.connect(
            f"{base_url}", 
            transports=["polling", "websocket"],
            namespaces=["/"],
            socketio_path="ws/socket.io"
        )
        
        # Keep the client running
        while True:
            await asyncio.sleep(1)
            
    except socketio.exceptions.ConnectionError as e:
        print(f"❌ Failed to connect: {e}")
    except KeyboardInterrupt:
        print("\n👋 Exiting WebSocket monitor...")
    finally:
        if sio.connected:
            await sio.disconnect()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n👋 Exiting WebSocket monitor...")
        sys.exit(0) 