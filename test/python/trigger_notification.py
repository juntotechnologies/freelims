#!/usr/bin/env python
import sys
import os
import requests
import json
import argparse
from datetime import datetime

# Add backend to path
sys.path.append(os.path.abspath('backend'))

# Command line arguments
parser = argparse.ArgumentParser(description='Trigger WebSocket notifications by updating inventory')
parser.add_argument('--item-id', type=int, help='Inventory item ID to update (default: first available)', default=None)
parser.add_argument('--api-url', default='http://localhost:8001/api', help='API URL')
args = parser.parse_args()

def get_auth_token():
    """Get authentication token by logging in"""
    print("Logging in to get auth token...")
    login_url = f"{args.api_url}/token"
    login_data = {
        "username": "admin",
        "password": "password"
    }
    
    response = requests.post(login_url, data=login_data)
    if response.status_code == 200:
        token = response.json().get("access_token")
        print("✅ Successfully obtained auth token")
        return token
    else:
        print(f"❌ Failed to login: {response.status_code} - {response.text}")
        return None

def get_inventory_items(token):
    """Get list of inventory items"""
    print("Getting inventory items...")
    headers = {"Authorization": f"Bearer {token}"}
    
    response = requests.get(f"{args.api_url}/inventory/items", headers=headers)
    if response.status_code == 200:
        items = response.json()
        print(f"✅ Got {len(items)} inventory items")
        return items
    else:
        print(f"❌ Failed to get inventory items: {response.status_code} - {response.text}")
        return []

def update_inventory_item(token, item_id, new_quantity):
    """Update an inventory item to trigger WebSocket notification"""
    print(f"Updating inventory item {item_id} with quantity {new_quantity}...")
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    data = {
        "quantity": new_quantity
    }
    
    response = requests.put(
        f"{args.api_url}/inventory/items/{item_id}", 
        headers=headers, 
        data=json.dumps(data)
    )
    
    if response.status_code == 200:
        print(f"✅ Successfully updated inventory item {item_id}")
        print(f"Item details: {json.dumps(response.json(), indent=2)}")
        return True
    else:
        print(f"❌ Failed to update inventory item: {response.status_code} - {response.text}")
        return False

def main():
    print("WebSocket Notification Trigger Tool")
    print("===================================")
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Get authentication token
    token = get_auth_token()
    if not token:
        print("Cannot continue without authentication")
        sys.exit(1)
    
    # Get inventory items
    items = get_inventory_items(token)
    if not items:
        print("No inventory items available")
        sys.exit(1)
    
    # Select item to update
    item_id = args.item_id
    if not item_id and items:
        item_id = items[0]["id"]
        print(f"Using first available item with ID: {item_id}")
    
    # Get current quantity and update with a new value
    current_item = next((item for item in items if item["id"] == item_id), None)
    if not current_item:
        print(f"Item with ID {item_id} not found")
        sys.exit(1)
    
    current_quantity = current_item.get("quantity", 0)
    new_quantity = current_quantity + 10
    
    # Update the item
    success = update_inventory_item(token, item_id, new_quantity)
    
    if success:
        print("\n🔔 WebSocket notification should have been triggered!")
        print("Check your WebSocket monitor to see if the notification was received.")
    
if __name__ == "__main__":
    main() 