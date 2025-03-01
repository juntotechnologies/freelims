# Make sure python-socketio is installed:
# pip install "python-socketio[asyncio_client]"
import socketio
from fastapi import FastAPI
from typing import Dict, Set, List

# Create Socket.IO server
sio = socketio.AsyncServer(async_mode='asgi', cors_allowed_origins='*')
# Use empty socketio_path to match frontend configuration
socket_app = socketio.ASGIApp(sio, socketio_path='')

# Keep track of connected clients
connected_clients: Dict[str, Set[str]] = {
    'inventory': set(),
    'experiments': set(),
    'tests': set(),
    'users': set(),
    'locations': set(),
}

@sio.event
async def connect(sid, environ):
    """Handle client connection"""
    print(f"Client connected: {sid}")

@sio.event
async def disconnect(sid):
    """Handle client disconnection"""
    print(f"Client disconnected: {sid}")
    # Remove client from all resource listeners
    for resource in connected_clients:
        if sid in connected_clients[resource]:
            connected_clients[resource].remove(sid)

@sio.event
async def subscribe(sid, data):
    """Subscribe to updates for a specific resource"""
    resource = data.get('resource')
    if resource and resource in connected_clients:
        connected_clients[resource].add(sid)
        await sio.emit('subscription_success', {'resource': resource}, room=sid)
        print(f"Client {sid} subscribed to {resource}")
    else:
        await sio.emit('subscription_error', {'message': 'Invalid resource'}, room=sid)

async def notify_clients(resource: str, action: str, data: dict):
    """Notify all clients subscribed to a resource about changes"""
    if resource in connected_clients and connected_clients[resource]:
        payload = {
            'action': action,  # 'create', 'update', 'delete'
            'resource': resource,
            'data': data
        }
        await sio.emit(f'{resource}_updated', payload, room=None)
        print(f"Notified {len(connected_clients[resource])} clients about {action} on {resource}")

def setup_socketio(app: FastAPI):
    """Mount the Socket.IO app to the FastAPI app"""
    print("Setting up Socket.IO server at /ws")
    app.mount('/ws', socket_app)
    return app 