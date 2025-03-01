#!/usr/bin/env python
import asyncio
import sys
import os

# Add the backend directory to path
sys.path.append(os.path.abspath('backend'))

try:
    from app.websockets import notify_clients
    print("Successfully imported notify_clients function")
except ImportError as e:
    print(f"Failed to import notify_clients: {e}")
    sys.exit(1)

async def test_notify():
    """Test the notify_clients function with sample data"""
    try:
        print("Testing notify_clients function...")
        test_data = {
            "id": 999,
            "name": "Test Item",
            "quantity": 100,
            "unit": "g"
        }
        
        # Call the notification function with test data
        await notify_clients('inventory', 'create', test_data)
        print("✅ Notification sent successfully!")
        
    except Exception as e:
        print(f"❌ Error during notification: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    print("WebSocket Server Test Script")
    print("============================")
    asyncio.run(test_notify()) 