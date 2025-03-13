#!/usr/bin/env python3
"""
Creates environment-specific .env files for the backend from the root .env file
"""
import os
import sys
from pathlib import Path
import shutil
from dotenv import dotenv_values

# Find paths
current_file = Path(__file__).resolve()
backend_dir = current_file.parent.parent
root_dir = backend_dir.parent
env_path = root_dir / '.env'

# Check if root .env exists
if not env_path.exists():
    print(f"Root .env file not found at {env_path}")
    print("Please create a .env file in the root directory")
    sys.exit(1)

# Read root .env file
env_vars = dotenv_values(env_path)

# Create development .env file
dev_env_path = backend_dir / '.env.development'
with open(dev_env_path, 'w') as f:
    f.write("# FreeLIMS Inventory - Development Environment\n\n")
    
    # Database Configuration
    f.write("# Database\n")
    f.write(f"DB_HOST={env_vars.get('DB_HOST', 'localhost')}\n")
    f.write(f"DB_PORT={env_vars.get('DB_PORT', '5432')}\n")
    f.write(f"DB_NAME={env_vars.get('DB_NAME', 'freelims_dev')}\n")
    f.write(f"DB_USER={env_vars.get('DB_USER', 'postgres')}\n")
    f.write(f"DB_PASSWORD={env_vars.get('DB_PASSWORD', 'postgres')}\n\n")
    
    # Security Settings
    f.write("# Security\n")
    f.write(f"SECRET_KEY={env_vars.get('SECRET_KEY', 'dev_secret_key_not_for_production_use')}\n")
    f.write("ENVIRONMENT=development\n\n")
    
    # Server Settings
    f.write("# Server\n")
    f.write(f"HOST={env_vars.get('HOST', '0.0.0.0')}\n")
    f.write(f"PORT={env_vars.get('DEV_BACKEND_PORT', '8005')}\n")

print(f"Created development environment file at {dev_env_path}")

# Create production .env file
prod_env_path = backend_dir / '.env.production'
with open(prod_env_path, 'w') as f:
    f.write("# FreeLIMS Inventory - Production Environment\n\n")
    
    # Database Configuration
    f.write("# Database\n")
    f.write(f"DB_HOST={env_vars.get('DB_HOST', 'localhost')}\n")
    f.write(f"DB_PORT={env_vars.get('DB_PORT', '5432')}\n")
    f.write(f"DB_NAME={env_vars.get('DB_NAME', 'freelims_prod')}\n")
    f.write(f"DB_USER={env_vars.get('DB_USER', 'postgres')}\n")
    f.write(f"DB_PASSWORD={env_vars.get('DB_PASSWORD', 'postgres')}\n\n")
    
    # Security Settings
    f.write("# Security\n")
    f.write(f"SECRET_KEY={env_vars.get('SECRET_KEY', 'prod_secret_key_change_this_in_production')}\n")
    f.write("ENVIRONMENT=production\n\n")
    
    # Server Settings
    f.write("# Server\n")
    f.write(f"HOST={env_vars.get('HOST', '0.0.0.0')}\n")
    f.write(f"PORT={env_vars.get('PROD_BACKEND_PORT', '8006')}\n")

print(f"Created production environment file at {prod_env_path}")

# Create a symlink to the appropriate .env file based on the environment
env_type = env_vars.get('ENVIRONMENT', 'development').lower()
target_env_path = dev_env_path if env_type == 'development' else prod_env_path
env_link_path = backend_dir / '.env'

# Remove existing .env file if it exists
if env_link_path.exists():
    os.remove(env_link_path)

# Create a copy of the appropriate .env file
shutil.copy2(target_env_path, env_link_path)
print(f"Created .env file at {env_link_path} (copied from {target_env_path})")

print("Backend environment setup complete!") 