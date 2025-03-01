#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS User Management Script
# This script handles user operations (list, create, delete, clear)
# ----------------------------------------------------------------------------

# Source port configuration if not already sourced
if [ "$(type -t get_process_on_port)" != "function" ]; then
    if [ -f "$REPO_ROOT/port_config.sh" ]; then
        source "$REPO_ROOT/port_config.sh"
    fi
fi

# Log directory
LOG_DIR="$REPO_ROOT/logs"
mkdir -p "$LOG_DIR"

# Define paths
VENV_PATH="$REPO_ROOT/backend/venv"
DB_BACKUP_DIR="$REPO_ROOT/db_backups"
mkdir -p "$DB_BACKUP_DIR"

# Colors for better visibility
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Log function to record events
log() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "[$timestamp] $message"
}

# Create a backup of the database
backup_database() {
    local env="$1"
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local db_name="freelims_${env}"
    local backup_file="$DB_BACKUP_DIR/${db_name}_backup_${timestamp}.sql"
    
    log "Creating backup of ${db_name} database..."
    pg_dump -h localhost -U shaun -d "$db_name" -f "$backup_file"
    
    if [ $? -eq 0 ]; then
        log "✅ Database backup created at: $backup_file"
        return 0
    else
        log "❌ Failed to create database backup"
        return 1
    fi
}

# List users in the database
list_users() {
    local env="$1"
    local db_name="freelims_${env}"
    
    log "Listing users in ${db_name} database..."
    
    # Check if virtual environment exists
    if [ ! -d "$VENV_PATH" ]; then
        log "Error: Virtual environment not found at $VENV_PATH"
        return 1
    fi
    
    # Activate virtual environment and run a Python script to list users
    source "$VENV_PATH/bin/activate"
    
    # Create a temporary script to list users
    local temp_script="$REPO_ROOT/scripts/user/temp_list_users.py"
    
    cat > "$temp_script" << EOF
#!/usr/bin/env python
"""
Script to list all users from the database.
"""

import os
import sys
import psycopg2
from configparser import ConfigParser

def get_db_connection(env):
    """Establish a database connection based on the environment."""
    config = ConfigParser()
    
    if env == "dev":
        config_file = os.path.join("$REPO_ROOT", "backend", "app", "config", "config_dev.ini")
    elif env == "prod":
        config_file = os.path.join("$REPO_ROOT", "backend", "app", "config", "config_prod.ini")
    else:
        raise ValueError("Environment must be either 'dev' or 'prod'")
    
    if not os.path.exists(config_file):
        print(f"Config file not found: {config_file}")
        sys.exit(1)
    
    config.read(config_file)
    
    return psycopg2.connect(
        host=config.get("postgresql", "host"),
        port=config.get("postgresql", "port"),
        database=config.get("postgresql", "database"),
        user=config.get("postgresql", "user"),
        password=config.get("postgresql", "password") if config.has_option("postgresql", "password") else ""
    )

def list_users(env):
    """List all users in the database."""
    conn = get_db_connection(env)
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            SELECT u.user_id, u.username, u.email, u.full_name, r.role_name 
            FROM users u
            JOIN roles r ON u.role_id = r.role_id
            ORDER BY u.user_id
        """)
        
        users = cursor.fetchall()
        
        if not users:
            print("No users found in the database.")
            return
        
        print("\nUser List:")
        print("=" * 80)
        print(f"{'ID':<5} {'Username':<20} {'Email':<30} {'Full Name':<20} {'Role':<10}")
        print("-" * 80)
        
        for user in users:
            user_id, username, email, full_name, role_name = user
            print(f"{user_id:<5} {username:<20} {email:<30} {full_name:<20} {role_name:<10}")
        
        print("=" * 80)
        print(f"Total users: {len(users)}")
        
    except Exception as e:
        print(f"Error listing users: {e}")
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python list_users.py [dev|prod]")
        sys.exit(1)
    
    env = sys.argv[1]
    if env not in ["dev", "prod"]:
        print("Error: Environment must be either 'dev' or 'prod'")
        sys.exit(1)
    
    list_users(env)
EOF
    
    chmod +x "$temp_script"
    python "$temp_script" "$env"
    rm "$temp_script"
    
    deactivate
    return 0
}

# Clear users from the database
clear_users() {
    local env="$1"
    local keep_admin="$2"
    local db_name="freelims_${env}"
    
    # Confirm with the user
    if [ "$keep_admin" == "true" ]; then
        read -p "⚠️  WARNING: This will remove all non-admin users from the $env database. Are you sure? (yes/no): " CONFIRM
    else
        read -p "⚠️  WARNING: This will remove ALL users from the $env database. Are you sure? (yes/no): " CONFIRM
    fi
    
    if [[ "$CONFIRM" != "yes" ]]; then
        log "Operation cancelled."
        return 0
    fi
    
    # Create a backup first
    backup_database "$env"
    if [ $? -ne 0 ]; then
        log "❌ Failed to backup database. Operation cancelled."
        return 1
    fi
    
    log "🔄 Removing users from $env database..."
    
    # Check if virtual environment exists
    if [ ! -d "$VENV_PATH" ]; then
        log "Error: Virtual environment not found at $VENV_PATH"
        return 1
    fi
    
    # Activate virtual environment and run a Python script to clear users
    source "$VENV_PATH/bin/activate"
    
    # Create a temporary script to clear users
    local temp_script="$REPO_ROOT/scripts/user/temp_clear_users.py"
    
    cat > "$temp_script" << EOF
#!/usr/bin/env python
"""
Script to remove users from the database.
"""

import os
import sys
import psycopg2
from configparser import ConfigParser

def get_db_connection(env):
    """Establish a database connection based on the environment."""
    config = ConfigParser()
    
    if env == "dev":
        config_file = os.path.join("$REPO_ROOT", "backend", "app", "config", "config_dev.ini")
    elif env == "prod":
        config_file = os.path.join("$REPO_ROOT", "backend", "app", "config", "config_prod.ini")
    else:
        raise ValueError("Environment must be either 'dev' or 'prod'")
    
    if not os.path.exists(config_file):
        print(f"Config file not found: {config_file}")
        sys.exit(1)
    
    config.read(config_file)
    
    return psycopg2.connect(
        host=config.get("postgresql", "host"),
        port=config.get("postgresql", "port"),
        database=config.get("postgresql", "database"),
        user=config.get("postgresql", "user"),
        password=config.get("postgresql", "password") if config.has_option("postgresql", "password") else ""
    )

def clear_users(env, keep_admin=False):
    """Remove users from the database."""
    conn = get_db_connection(env)
    conn.autocommit = False
    cursor = conn.cursor()
    
    try:
        # Count users before deletion
        cursor.execute("SELECT COUNT(*) FROM users")
        before_count = cursor.fetchone()[0]
        print(f"Users before deletion: {before_count}")
        
        # First handle foreign key constraints
        print("Handling foreign key constraints...")
        
        # Example for test_analyst table
        cursor.execute("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'test_analyst')")
        if cursor.fetchone()[0]:
            print("Clearing test_analyst table...")
            cursor.execute("DELETE FROM test_analyst")
        
        # Example for inventory_changes table
        cursor.execute("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'inventory_changes')")
        if cursor.fetchone()[0]:
            print("Updating inventory_changes to remove user references...")
            cursor.execute("UPDATE inventory_changes SET user_id = NULL WHERE user_id IS NOT NULL")
        
        # Example for inventory_audits table
        cursor.execute("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'inventory_audits')")
        if cursor.fetchone()[0]:
            print("Updating inventory_audits to remove user references...")
            cursor.execute("UPDATE inventory_audits SET user_id = NULL WHERE user_id IS NOT NULL")
        
        # Example for shipments table
        cursor.execute("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'shipments')")
        if cursor.fetchone()[0]:
            print("Updating shipments to remove user references...")
            cursor.execute("UPDATE shipments SET user_id = NULL WHERE user_id IS NOT NULL")
        
        # Example for test_requests table
        cursor.execute("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'test_requests')")
        if cursor.fetchone()[0]:
            print("Updating test_requests to remove user references...")
            cursor.execute("UPDATE test_requests SET user_id = NULL WHERE user_id IS NOT NULL")
        
        # Example for user_activity_log table
        cursor.execute("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_activity_log')")
        if cursor.fetchone()[0]:
            print("Clearing user_activity_log table...")
            cursor.execute("DELETE FROM user_activity_log")
        
        # Now delete users
        if keep_admin:
            print("Removing all non-admin users...")
            cursor.execute("DELETE FROM users WHERE role_id != 1")
        else:
            print("Removing all users...")
            cursor.execute("DELETE FROM users")
        
        # Count users after deletion
        cursor.execute("SELECT COUNT(*) FROM users")
        after_count = cursor.fetchone()[0]
        print(f"Users after deletion: {after_count}")
        print(f"Removed {before_count - after_count} users")
        
        # Commit all changes
        conn.commit()
        print("✅ Users have been successfully removed from the database.")
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Error removing users: {e}")
        sys.exit(1)
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python clear_users.py [dev|prod] [--keep-admin]")
        sys.exit(1)
    
    env = sys.argv[1]
    if env not in ["dev", "prod"]:
        print("Error: Environment must be either 'dev' or 'prod'")
        sys.exit(1)
    
    keep_admin = len(sys.argv) > 2 and sys.argv[2] == "--keep-admin"
    
    clear_users(env, keep_admin)
EOF
    
    chmod +x "$temp_script"
    
    if [ "$keep_admin" == "true" ]; then
        python "$temp_script" "$env" "--keep-admin"
    else
        python "$temp_script" "$env"
    fi
    
    local status=$?
    rm "$temp_script"
    deactivate
    
    if [ $status -eq 0 ]; then
        log "✅ User cleanup completed for $env database."
    else
        log "❌ Failed to clean up users from $env database."
    fi
    
    return $status
}

# Create an admin user
create_user() {
    local env="$1"
    local is_admin="$2"
    local db_name="freelims_${env}"
    
    log "Creating a new user in the $env database..."
    
    # Check if virtual environment exists
    if [ ! -d "$VENV_PATH" ]; then
        log "Error: Virtual environment not found at $VENV_PATH"
        return 1
    fi
    
    # Activate virtual environment and run a Python script to create a user
    source "$VENV_PATH/bin/activate"
    
    # Create a temporary script to create a user
    local temp_script="$REPO_ROOT/scripts/user/temp_create_user.py"
    
    cat > "$temp_script" << EOF
#!/usr/bin/env python
"""
Script to create a new user in the database.
"""

import os
import sys
import re
import getpass
import psycopg2
from configparser import ConfigParser
from passlib.hash import bcrypt

def validate_email(email):
    """Validate email format."""
    pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    return re.match(pattern, email) is not None

def validate_username(username):
    """Validate username format."""
    pattern = r"^[a-zA-Z0-9_-]{3,20}$"
    return re.match(pattern, username) is not None

def hash_password(password):
    """Hash password using bcrypt."""
    return bcrypt.hash(password)

def get_db_connection(env):
    """Establish a database connection based on the environment."""
    config = ConfigParser()
    
    if env == "dev":
        config_file = os.path.join("$REPO_ROOT", "backend", "app", "config", "config_dev.ini")
    elif env == "prod":
        config_file = os.path.join("$REPO_ROOT", "backend", "app", "config", "config_prod.ini")
    else:
        raise ValueError("Environment must be either 'dev' or 'prod'")
    
    if not os.path.exists(config_file):
        print(f"Config file not found: {config_file}")
        sys.exit(1)
    
    config.read(config_file)
    
    return psycopg2.connect(
        host=config.get("postgresql", "host"),
        port=config.get("postgresql", "port"),
        database=config.get("postgresql", "database"),
        user=config.get("postgresql", "user"),
        password=config.get("postgresql", "password") if config.has_option("postgresql", "password") else ""
    )

def create_user(conn, email, username, full_name, hashed_password, is_admin=False):
    """Insert a new user into the database."""
    cursor = conn.cursor()
    
    try:
        # Check if username already exists
        cursor.execute("SELECT COUNT(*) FROM users WHERE username = %s", (username,))
        if cursor.fetchone()[0] > 0:
            print(f"Error: Username '{username}' already exists")
            return False
        
        # Check if email already exists
        cursor.execute("SELECT COUNT(*) FROM users WHERE email = %s", (email,))
        if cursor.fetchone()[0] > 0:
            print(f"Error: Email '{email}' already exists")
            return False
        
        # Get role_id for admin or user
        role_name = "Admin" if is_admin else "User"
        cursor.execute("SELECT role_id FROM roles WHERE role_name = %s", (role_name,))
        result = cursor.fetchone()
        
        if not result:
            print(f"Error: Role '{role_name}' not found")
            return False
        
        role_id = result[0]
        
        # Insert the new user
        cursor.execute(
            "INSERT INTO users (username, email, password_hash, full_name, role_id, is_active) VALUES (%s, %s, %s, %s, %s, %s)",
            (username, email, hashed_password, full_name, role_id, True)
        )
        conn.commit()
        
        print(f"✅ {role_name} user '{username}' created successfully")
        return True
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Error creating user: {e}")
        return False
        
    finally:
        cursor.close()

def main():
    if len(sys.argv) < 2:
        print("Usage: python create_user.py [dev|prod] [--admin]")
        sys.exit(1)
    
    env = sys.argv[1]
    if env not in ["dev", "prod"]:
        print("Error: Environment must be either 'dev' or 'prod'")
        sys.exit(1)
    
    is_admin = len(sys.argv) > 2 and sys.argv[2] == "--admin"
    
    user_type = "admin" if is_admin else "regular"
    print(f"Creating a new {user_type} user in the {env} environment")
    
    # Gather user information
    while True:
        email = input("Email: ").strip()
        if validate_email(email):
            break
        print("Invalid email format. Please try again.")
    
    while True:
        username = input("Username: ").strip()
        if validate_username(username):
            break
        print("Invalid username. Username must be 3-20 characters and contain only letters, numbers, underscores, or hyphens.")
    
    full_name = input("Full Name: ").strip()
    
    while True:
        password = getpass.getpass("Password: ")
        if len(password) < 8:
            print("Password must be at least 8 characters long.")
            continue
        
        confirm_password = getpass.getpass("Confirm Password: ")
        if password != confirm_password:
            print("Passwords do not match. Please try again.")
            continue
        
        break
    
    # Hash the password
    hashed_password = hash_password(password)
    
    # Connect to the database and create user
    try:
        conn = get_db_connection(env)
        if create_user(conn, email, username, full_name, hashed_password, is_admin):
            print(f"User '{username}' has been created in the {env} environment.")
        else:
            sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    main()
EOF
    
    chmod +x "$temp_script"
    
    if [ "$is_admin" == "true" ]; then
        python "$temp_script" "$env" "--admin"
    else
        python "$temp_script" "$env"
    fi
    
    local status=$?
    rm "$temp_script"
    deactivate
    
    if [ $status -eq 0 ]; then
        log "✅ User creation completed for $env database."
    else
        log "❌ Failed to create user in $env database."
    fi
    
    return $status
}

# Delete a specific user
delete_user() {
    local env="$1"
    local username="$2"
    local db_name="freelims_${env}"
    
    if [ -z "$username" ]; then
        log "Error: Username is required"
        return 1
    fi
    
    # Confirm with the user
    read -p "⚠️  WARNING: This will remove user '$username' from the $env database. Are you sure? (yes/no): " CONFIRM
    
    if [[ "$CONFIRM" != "yes" ]]; then
        log "Operation cancelled."
        return 0
    fi
    
    log "🔄 Removing user '$username' from $env database..."
    
    # Check if virtual environment exists
    if [ ! -d "$VENV_PATH" ]; then
        log "Error: Virtual environment not found at $VENV_PATH"
        return 1
    fi
    
    # Activate virtual environment and run a Python script to delete a user
    source "$VENV_PATH/bin/activate"
    
    # Create a temporary script to delete a user
    local temp_script="$REPO_ROOT/scripts/user/temp_delete_user.py"
    
    cat > "$temp_script" << EOF
#!/usr/bin/env python
"""
Script to delete a user from the database.
"""

import os
import sys
import psycopg2
from configparser import ConfigParser

def get_db_connection(env):
    """Establish a database connection based on the environment."""
    config = ConfigParser()
    
    if env == "dev":
        config_file = os.path.join("$REPO_ROOT", "backend", "app", "config", "config_dev.ini")
    elif env == "prod":
        config_file = os.path.join("$REPO_ROOT", "backend", "app", "config", "config_prod.ini")
    else:
        raise ValueError("Environment must be either 'dev' or 'prod'")
    
    if not os.path.exists(config_file):
        print(f"Config file not found: {config_file}")
        sys.exit(1)
    
    config.read(config_file)
    
    return psycopg2.connect(
        host=config.get("postgresql", "host"),
        port=config.get("postgresql", "port"),
        database=config.get("postgresql", "database"),
        user=config.get("postgresql", "user"),
        password=config.get("postgresql", "password") if config.has_option("postgresql", "password") else ""
    )

def delete_user(env, username):
    """Delete a user from the database."""
    conn = get_db_connection(env)
    conn.autocommit = False
    cursor = conn.cursor()
    
    try:
        # Check if the user exists
        cursor.execute("SELECT user_id, role_id FROM users WHERE username = %s", (username,))
        user = cursor.fetchone()
        
        if not user:
            print(f"User '{username}' not found in the database.")
            return False
        
        user_id, role_id = user
        
        # Check if this is the last admin account
        if role_id == 1:  # Admin role
            cursor.execute("SELECT COUNT(*) FROM users WHERE role_id = 1")
            admin_count = cursor.fetchone()[0]
            
            if admin_count == 1:
                print("Error: Cannot delete the last admin account")
                return False
        
        # Handle foreign key constraints
        print("Handling foreign key constraints...")
        
        # Example for test_analyst table
        cursor.execute("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'test_analyst')")
        if cursor.fetchone()[0]:
            print("Removing from test_analyst table...")
            cursor.execute("DELETE FROM test_analyst WHERE user_id = %s", (user_id,))
        
        # Example for inventory_changes table
        cursor.execute("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'inventory_changes')")
        if cursor.fetchone()[0]:
            print("Updating inventory_changes to remove user references...")
            cursor.execute("UPDATE inventory_changes SET user_id = NULL WHERE user_id = %s", (user_id,))
        
        # Example for inventory_audits table
        cursor.execute("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'inventory_audits')")
        if cursor.fetchone()[0]:
            print("Updating inventory_audits to remove user references...")
            cursor.execute("UPDATE inventory_audits SET user_id = NULL WHERE user_id = %s", (user_id,))
        
        # Example for shipments table
        cursor.execute("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'shipments')")
        if cursor.fetchone()[0]:
            print("Updating shipments to remove user references...")
            cursor.execute("UPDATE shipments SET user_id = NULL WHERE user_id = %s", (user_id,))
        
        # Example for test_requests table
        cursor.execute("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'test_requests')")
        if cursor.fetchone()[0]:
            print("Updating test_requests to remove user references...")
            cursor.execute("UPDATE test_requests SET user_id = NULL WHERE user_id = %s", (user_id,))
        
        # Example for user_activity_log table
        cursor.execute("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_activity_log')")
        if cursor.fetchone()[0]:
            print("Removing from user_activity_log table...")
            cursor.execute("DELETE FROM user_activity_log WHERE user_id = %s", (user_id,))
        
        # Now delete the user
        print(f"Deleting user '{username}'...")
        cursor.execute("DELETE FROM users WHERE user_id = %s", (user_id,))
        
        # Commit all changes
        conn.commit()
        print(f"✅ User '{username}' has been successfully removed from the database.")
        return True
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Error deleting user: {e}")
        return False
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python delete_user.py [dev|prod] [username]")
        sys.exit(1)
    
    env = sys.argv[1]
    if env not in ["dev", "prod"]:
        print("Error: Environment must be either 'dev' or 'prod'")
        sys.exit(1)
    
    username = sys.argv[2]
    
    if delete_user(env, username):
        sys.exit(0)
    else:
        sys.exit(1)
EOF
    
    chmod +x "$temp_script"
    python "$temp_script" "$env" "$username"
    
    local status=$?
    rm "$temp_script"
    deactivate
    
    if [ $status -eq 0 ]; then
        log "✅ User '$username' successfully deleted from $env database."
    else
        log "❌ Failed to delete user '$username' from $env database."
    fi
    
    return $status
}

# Main function
manage_users() {
    local environment=$1
    local command=$2
    shift 2
    
    case "$environment" in
        dev|prod)
            case "$command" in
                list)
                    list_users "$environment"
                    ;;
                create)
                    if [ "$1" == "--admin" ]; then
                        create_user "$environment" "true"
                    else
                        create_user "$environment" "false"
                    fi
                    ;;
                delete)
                    if [ -z "$1" ]; then
                        echo "Error: Username is required for delete command."
                        echo "Usage: freelims.sh user [dev|prod] delete [username]"
                        return 1
                    fi
                    delete_user "$environment" "$1"
                    ;;
                clear)
                    if [ "$1" == "--keep-admin" ]; then
                        clear_users "$environment" "true"
                    else
                        clear_users "$environment" "false"
                    fi
                    ;;
                *)
                    echo "Error: Invalid command for user management."
                    echo "Valid commands: list, create, delete, clear"
                    return 1
                    ;;
            esac
            ;;
        all)
            case "$command" in
                list)
                    echo "=== Development Environment ==="
                    list_users "dev"
                    echo ""
                    echo "=== Production Environment ==="
                    list_users "prod"
                    ;;
                clear)
                    echo "=== Development Environment ==="
                    if [ "$1" == "--keep-admin" ]; then
                        clear_users "dev" "true"
                    else
                        clear_users "dev" "false"
                    fi
                    echo ""
                    echo "=== Production Environment ==="
                    if [ "$1" == "--keep-admin" ]; then
                        clear_users "prod" "true"
                    else
                        clear_users "prod" "false"
                    fi
                    ;;
                *)
                    echo "Error: Only 'list' and 'clear' commands are supported for 'all' environments."
                    return 1
                    ;;
            esac
            ;;
        *)
            echo "Error: Invalid environment. Must be 'dev', 'prod', or 'all'."
            return 1
            ;;
    esac
    
    return 0
} 