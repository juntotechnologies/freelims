#!/usr/bin/env python
import sys
import os
import requests
import json
from datetime import datetime, timedelta

# Get API URL from environment or use default
API_URL = 'http://localhost:8001/api'

def get_auth_token():
    """Get authentication token by logging in"""
    print("Logging in to get auth token...")
    login_url = f"{API_URL}/token"
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

def create_chemical(token):
    """Create a test chemical"""
    print("\nCreating test chemical...")
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    chemical_data = {
        "name": "Test Chemical",
        "cas_number": "12345-67-8",
        "formula": "C2H5OH",
        "molecular_weight": 46.07,
        "description": "Test chemical for WebSocket notifications",
        "hazard_information": "Flammable",
        "storage_conditions": "Cool, dry place"
    }
    
    response = requests.post(
        f"{API_URL}/chemicals", 
        headers=headers, 
        json=chemical_data
    )
    
    if response.status_code in (200, 201):
        chemical = response.json()
        print(f"✅ Successfully created chemical: {chemical['name']} (ID: {chemical['id']})")
        return chemical
    else:
        print(f"❌ Failed to create chemical: {response.status_code} - {response.text}")
        return None

def create_location(token):
    """Create a test location"""
    print("\nCreating test location...")
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    location_data = {
        "name": "Test Location",
        "description": "Test location for WebSocket notifications"
    }
    
    response = requests.post(
        f"{API_URL}/locations", 
        headers=headers, 
        json=location_data
    )
    
    if response.status_code in (200, 201):
        location = response.json()
        print(f"✅ Successfully created location: {location['name']} (ID: {location['id']})")
        return location
    else:
        print(f"❌ Failed to create location: {response.status_code} - {response.text}")
        return None

def create_inventory_item(token, chemical_id, location_id):
    """Create a test inventory item"""
    print("\nCreating test inventory item...")
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    # Set expiration date to 1 year from now
    expiration_date = (datetime.now() + timedelta(days=365)).strftime("%Y-%m-%d")
    
    inventory_data = {
        "chemical_id": chemical_id,
        "location_id": location_id,
        "quantity": 100.0,
        "unit": "g",
        "batch_number": "BATCH-001",
        "expiration_date": expiration_date
    }
    
    response = requests.post(
        f"{API_URL}/inventory/items", 
        headers=headers, 
        json=inventory_data
    )
    
    if response.status_code in (200, 201):
        item = response.json()
        print(f"✅ Successfully created inventory item with quantity: {item['quantity']} {item['unit']} (ID: {item['id']})")
        return item
    else:
        print(f"❌ Failed to create inventory item: {response.status_code} - {response.text}")
        return None

def main():
    print("Creating Test Data for FreeLIMS")
    print("===============================")
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Get authentication token
    token = get_auth_token()
    if not token:
        print("Cannot continue without authentication")
        sys.exit(1)
    
    # Create a chemical
    chemical = create_chemical(token)
    if not chemical:
        print("Cannot continue without chemical")
        sys.exit(1)
    
    # Create a location
    location = create_location(token)
    if not location:
        print("Cannot continue without location")
        sys.exit(1)
    
    # Create an inventory item
    inventory_item = create_inventory_item(token, chemical['id'], location['id'])
    if not inventory_item:
        print("Failed to create inventory item")
        sys.exit(1)
    
    print("\n✅ Successfully created test data for WebSocket notification testing!")
    print(f"Inventory Item ID: {inventory_item['id']}")
    print("\nYou can now use this command to trigger a notification:")
    print(f"python trigger_notification.py --item-id {inventory_item['id']}")

if __name__ == "__main__":
    main() 