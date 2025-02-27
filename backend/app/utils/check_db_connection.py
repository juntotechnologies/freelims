#!/usr/bin/env python3
"""
Database connection check script.
This script attempts to connect to the database and verify the connection is working.
"""

import sys
from sqlalchemy import text
from ..database import engine

def check_connection():
    """Check if the database connection is working."""
    try:
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1"))
            if result.scalar() == 1:
                print("Database connection successful!")
                return True
            else:
                print("Database connection failed: Unexpected result", file=sys.stderr)
                return False
    except Exception as e:
        print(f"Database connection failed: {str(e)}", file=sys.stderr)
        return False

if __name__ == "__main__":
    if check_connection():
        sys.exit(0)
    else:
        sys.exit(1) 