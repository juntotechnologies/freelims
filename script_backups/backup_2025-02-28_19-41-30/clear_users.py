#!/usr/bin/env python
"""
Script to remove all users from the database.

Usage:
    python clear_users.py --env [dev|prod] [--keep-admin]

Arguments:
    --env: Specifies the environment (dev or prod)
    --keep-admin: Optional flag to preserve admin users (role_id = 1)
"""

import argparse
import os
import sys
import psycopg2
from configparser import ConfigParser

def get_db_connection(env):
    """Establish a database connection based on the environment."""
    config = ConfigParser()
    
    if env == "dev":
        config_file = os.path.join(os.path.dirname(__file__), "backend", "app", "config", "config_dev.ini")
    elif env == "prod":
        config_file = os.path.join(os.path.dirname(__file__), "backend", "app", "config", "config_prod.ini")
    else:
        raise ValueError("Environment must be either 'dev' or 'prod'")
    
    if not os.path.exists(config_file):
        print(f"Config file not found: {config_file}")
        sys.exit(1)
    
    config.read(config_file)
    
    try:
        conn = psycopg2.connect(
            host=config["database"]["host"],
            port=config["database"]["port"],
            database=config["database"]["database"],
            user=config["database"]["user"],
            password=config["database"]["password"]
        )
        return conn
    except psycopg2.Error as e:
        print(f"Database connection error: {e}")
        sys.exit(1)

def clear_users(conn, keep_admin=False):
    """Remove users from the database."""
    cursor = conn.cursor()
    try:
        # First, get a count of users
        cursor.execute("SELECT COUNT(*) FROM users")
        count_before = cursor.fetchone()[0]
        
        # Delete users
        if keep_admin:
            cursor.execute("DELETE FROM users WHERE role_id != 1")
            print("Keeping admin users (role_id = 1)")
        else:
            cursor.execute("DELETE FROM users")
            print("Removing ALL users including admins")
        
        conn.commit()
        
        # Get count after deletion
        cursor.execute("SELECT COUNT(*) FROM users")
        count_after = cursor.fetchone()[0]
        
        return count_before, count_after
    except psycopg2.Error as e:
        conn.rollback()
        print(f"Error clearing users: {e}")
        sys.exit(1)
    finally:
        cursor.close()

def main():
    parser = argparse.ArgumentParser(description="Clear users from the database")
    parser.add_argument("--env", required=True, choices=["dev", "prod"], 
                        help="Specify environment (dev or prod)")
    parser.add_argument("--keep-admin", action="store_true", 
                        help="Keep admin users (role_id = 1)")
    
    args = parser.parse_args()
    
    # Confirm with the user before proceeding
    env_type = "DEVELOPMENT" if args.env == "dev" else "PRODUCTION"
    action = "all users EXCEPT admins" if args.keep_admin else "ALL USERS INCLUDING ADMINS"
    
    print(f"⚠️  WARNING: You are about to remove {action} from the {env_type} database! ⚠️")
    confirmation = input("Are you sure you want to continue? (yes/no): ")
    
    if confirmation.lower() != "yes":
        print("Operation canceled.")
        sys.exit(0)
    
    conn = get_db_connection(args.env)
    try:
        count_before, count_after = clear_users(conn, args.keep_admin)
        print(f"Users before: {count_before}")
        print(f"Users remaining: {count_after}")
        print(f"Users removed: {count_before - count_after}")
        print("Operation completed successfully.")
    finally:
        conn.close()

if __name__ == "__main__":
    main() 