#!/usr/bin/env python

"""
Create Admin User Script for FreeLIMS
=====================================

This script allows you to create a new administrator user directly in the database
after clearing all users or when setting up a fresh system.

Usage:
  python create_admin.py --env [dev|prod]
  
  --env: Which environment to create the admin for (dev or prod)
  
Example:
  python create_admin.py --env dev
"""

import os
import sys
import argparse
from datetime import datetime
from getpass import getpass
import re
from passlib.context import CryptContext
import psycopg2
from psycopg2 import sql

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def validate_email(email):
    """Validate email format"""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

def validate_username(username):
    """Validate username format"""
    pattern = r'^[a-zA-Z0-9_]{3,20}$'
    return re.match(pattern, username) is not None

def hash_password(password):
    """Hash a password for storing"""
    return pwd_context.hash(password)

def get_db_connection(env):
    """Get database connection based on environment"""
    db_params = {
        'dev': {
            'dbname': 'freelims_dev',
            'user': 'shaun',
            'host': 'localhost',
            'port': '5432'
        },
        'prod': {
            'dbname': 'freelims_prod',
            'user': 'shaun',
            'host': 'localhost',
            'port': '5432'
        }
    }
    
    if env not in db_params:
        print(f"Error: Unknown environment '{env}'")
        sys.exit(1)
    
    try:
        conn = psycopg2.connect(**db_params[env])
        return conn
    except Exception as e:
        print(f"Error connecting to database: {e}")
        sys.exit(1)

def create_admin_user(conn, email, username, full_name, hashed_password):
    """Create a new admin user in the database"""
    now = datetime.now()
    
    try:
        with conn.cursor() as cur:
            # Check if user already exists
            cur.execute("SELECT id FROM users WHERE email = %s OR username = %s", (email, username))
            if cur.fetchone():
                print("Error: A user with this email or username already exists.")
                return False
            
            # Insert new admin user
            cur.execute(
                """
                INSERT INTO users (email, username, full_name, hashed_password, is_active, is_admin, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING id
                """,
                (email, username, full_name, hashed_password, True, True, now)
            )
            user_id = cur.fetchone()[0]
            conn.commit()
            
            return user_id
    except Exception as e:
        conn.rollback()
        print(f"Error creating admin user: {e}")
        return False

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Create an admin user for FreeLIMS')
    parser.add_argument('--env', choices=['dev', 'prod'], required=True, help='Environment (dev or prod)')
    args = parser.parse_args()
    
    # Get environment
    env = args.env
    
    print(f"\n{'=' * 40}")
    print(f"FreeLIMS Admin User Creation Tool ({env.upper()})")
    print(f"{'=' * 40}\n")
    
    # Get user input
    print("Please provide the following information for the new admin user:")
    email = input("Email: ").strip()
    while not validate_email(email):
        print("Error: Invalid email format. Please try again.")
        email = input("Email: ").strip()
    
    username = input("Username: ").strip()
    while not validate_username(username):
        print("Error: Username must be 3-20 characters and can only contain letters, numbers, and underscores.")
        username = input("Username: ").strip()
    
    full_name = input("Full Name: ").strip()
    
    password = getpass("Password: ")
    while len(password) < 8:
        print("Error: Password must be at least 8 characters.")
        password = getpass("Password: ")
    
    confirm_password = getpass("Confirm Password: ")
    while password != confirm_password:
        print("Error: Passwords do not match.")
        password = getpass("Password: ")
        confirm_password = getpass("Confirm Password: ")
    
    # Hash password
    hashed_password = hash_password(password)
    
    # Connect to database
    conn = get_db_connection(env)
    
    # Create admin user
    print("\nCreating admin user...")
    user_id = create_admin_user(conn, email, username, full_name, hashed_password)
    
    if user_id:
        print(f"\n✅ Admin user created successfully with ID: {user_id}")
        print(f"Environment: {env.upper()}")
        print(f"Username: {username}")
        print(f"Email: {email}")
        print(f"Full Name: {full_name}")
        print("\nYou can now log in to the system with these credentials.")
    else:
        print("\n❌ Failed to create admin user.")
    
    # Close connection
    conn.close()

if __name__ == "__main__":
    main() 