#!/usr/bin/env python
import requests
import json
import time

def test_socketio_handshake():
    """Test the Socket.IO handshake with the server"""
    print("Testing Socket.IO handshake with the server...")
    
    # Try different URL combinations to find the correct one
    urls = [
        "http://localhost:8001/ws/socket.io/?EIO=4&transport=polling",
        "http://localhost:8001/socket.io/?EIO=4&transport=polling",
        "http://localhost:8001/ws/?EIO=4&transport=polling",
        "http://localhost:8001/engine.io/?EIO=4&transport=polling",
        "http://0.0.0.0:8001/ws/socket.io/?EIO=4&transport=polling"
    ]
    
    success = False
    for url in urls:
        try:
            print(f"\nTrying: {url}")
            response = requests.get(url)
            print(f"Status: {response.status_code}")
            print(f"Response: {response.text[:100]}...")
            
            if response.status_code == 200:
                print(f"✅ Connection successful with {url}")
                success = True
                break
        except Exception as e:
            print(f"❌ Error: {e}")
    
    if not success:
        print("\n❌ Failed to connect with any URL configuration")
    
    return success

def test_api():
    """Test if the API is running"""
    print("\nTesting API health endpoint...")
    try:
        response = requests.get("http://localhost:8001/api/health")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Error connecting to API: {e}")
        return False

if __name__ == "__main__":
    print("Socket.IO Diagnostic Tool for FreeLIMS")
    print("======================================")
    
    api_running = test_api()
    if api_running:
        print("✅ API is running")
        test_socketio_handshake()
    else:
        print("❌ API is not running, please start the server first") 