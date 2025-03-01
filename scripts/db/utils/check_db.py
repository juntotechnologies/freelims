#!/usr/bin/env python
import os
import sys
import psycopg2

def check_database(dbname):
    try:
        print(f"\nChecking database: {dbname}")
        # Connect to PostgreSQL
        conn = psycopg2.connect(
            dbname=dbname,
            user="shaun",
            host="localhost",
            port="5432"
        )
        
        # Try to query the users table
        cursor = conn.cursor()
        try:
            # First check if the table exists
            cursor.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_schema = 'public' 
                    AND table_name = 'users'
                );
            """)
            table_exists = cursor.fetchone()[0]
            
            if not table_exists:
                print("Users table does not exist in this database")
                return 0
                
            cursor.execute("SELECT COUNT(*) FROM users")
            user_count = cursor.fetchone()[0]
            print(f"Found {user_count} users in the database")
            
            if user_count > 0:
                # Get usernames
                cursor.execute("SELECT username FROM users LIMIT 5")
                users = cursor.fetchall()
                print("Sample usernames:", [user[0] for user in users])
                
            return user_count
        except Exception as e:
            print(f"Error querying users: {e}")
            return 0
        finally:
            cursor.close()
            conn.close()
            
    except Exception as e:
        print(f"Error connecting to database: {e}")
        return 0

if __name__ == "__main__":
    # The databases to check
    databases = ["freelims_dev", "postgres"]
    
    for db in databases:
        check_database(db) 