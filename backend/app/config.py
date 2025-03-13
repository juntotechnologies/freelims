"""
Configuration module for FreeLIMS Inventory backend.
"""
import os
from pathlib import Path
from dotenv import load_dotenv

# Find root directory and load .env file
current_file = Path(__file__).resolve()
root_dir = current_file.parent.parent.parent  # app -> backend -> root
env_path = root_dir / '.env'
load_dotenv(dotenv_path=env_path)

# Port Configuration
PORT = int(os.getenv("PORT", os.getenv("DEV_BACKEND_PORT", 8005)))

# Database Configuration
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", 5432))
DB_NAME = os.getenv("DB_NAME", "freelims_dev")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

# Security Settings
SECRET_KEY = os.getenv("SECRET_KEY", "dev_secret_key_not_for_production_use")
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", 30))

# Server Settings
HOST = os.getenv("HOST", "0.0.0.0")
DEV_FRONTEND_PORT = int(os.getenv("DEV_FRONTEND_PORT", 3005))
PROD_FRONTEND_PORT = int(os.getenv("PROD_FRONTEND_PORT", 3006))

# Database URL
def get_database_url() -> str:
    """Construct the database URL from environment variables."""
    return f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# Environment helpers
def is_development() -> bool:
    """Check if running in development mode."""
    return ENVIRONMENT.lower() == "development"

def is_production() -> bool:
    """Check if running in production mode."""
    return ENVIRONMENT.lower() == "production"

def is_testing() -> bool:
    """Check if running in testing mode."""
    return ENVIRONMENT.lower() == "testing" 