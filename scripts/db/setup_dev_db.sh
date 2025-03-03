#!/bin/bash

# ----------------------------------------------------------------------------
# FreeLIMS Development Database Setup Script
# This script sets up a development database for the FreeLIMS application
# ----------------------------------------------------------------------------

# Source the utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../common/utils.sh"

# Main log file for this script
LOG_FILE="db_setup.log"

# Database configuration (can be overridden by .env file)
DEV_DB_SCHEMA_PATH="/Users/Shared/ADrive/freelims_db_dev"
DEFAULT_ADMIN_USER="admin"
DEFAULT_ADMIN_PASSWORD="admin123"

# Print usage information
usage() {
    echo "FreeLIMS Development Database Setup Script"
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --help, -h           Show this help message"
    echo "  --db-path PATH       Set custom database path"
    echo "  --admin-user USER    Set custom admin username"
    echo "  --admin-pass PASS    Set custom admin password"
    echo "  --no-sample-data     Skip sample data generation"
    echo ""
    exit 0
}

# Set up the development database directory
setup_db_directory() {
    log_info "Setting up database directory..." "${LOG_FILE}"
    
    # Create the database directory if it doesn't exist
    mkdir -p "${DEV_DB_SCHEMA_PATH}" || {
        log_error "Failed to create database directory: ${DEV_DB_SCHEMA_PATH}" "${LOG_FILE}"
        return 1
    }
    
    log_success "Database directory created: ${DEV_DB_SCHEMA_PATH}" "${LOG_FILE}"
    return 0
}

# Check PostgreSQL status
check_postgres() {
    log_info "Checking PostgreSQL status..." "${LOG_FILE}"
    
    pg_isready &>/dev/null || {
        log_error "PostgreSQL is not running. Please start PostgreSQL service." "${LOG_FILE}"
        return 1
    }
    
    log_success "PostgreSQL is running" "${LOG_FILE}"
    return 0
}

# Create development database
create_dev_database() {
    log_info "Creating development database..." "${LOG_FILE}"
    
    # Drop existing database if it exists
    PGPASSWORD="${DB_PASSWORD}" dropdb -h "${DB_HOST}" -U "${DB_USER}" "${DB_NAME}" --if-exists || {
        log_warning "Failed to drop existing database" "${LOG_FILE}"
    }
    
    # Create new database
    PGPASSWORD="${DB_PASSWORD}" createdb -h "${DB_HOST}" -U "${DB_USER}" "${DB_NAME}" || {
        log_error "Failed to create development database" "${LOG_FILE}"
        return 1
    }
    
    log_success "Development database created: ${DB_NAME}" "${LOG_FILE}"
    return 0
}

# Set up development environment settings
setup_dev_env() {
    log_info "Setting up development environment..." "${LOG_FILE}"
    
    # Copy development environment settings
    if [[ -f "${BACKEND_DIR}/.env.development" ]]; then
        cp "${BACKEND_DIR}/.env.development" "${BACKEND_DIR}/.env" || {
            log_error "Failed to copy development environment settings" "${LOG_FILE}"
            return 1
        }
        
        # Update database path if needed
        if [[ -n "${DEV_DB_SCHEMA_PATH}" ]]; then
            sed -i.bak "s|^DB_SCHEMA_PATH=.*|DB_SCHEMA_PATH=${DEV_DB_SCHEMA_PATH}|" "${BACKEND_DIR}/.env" || {
                log_warning "Failed to update database path in .env file" "${LOG_FILE}"
            }
            rm -f "${BACKEND_DIR}/.env.bak"
        fi
    else
        log_warning "No .env.development file found. Using existing .env file." "${LOG_FILE}"
    fi
    
    log_success "Development environment setup completed" "${LOG_FILE}"
    return 0
}

# Run database migrations
run_migrations() {
    log_info "Running database migrations..." "${LOG_FILE}"
    
    cd "${BACKEND_DIR}" || return 1
    python -m alembic upgrade head || {
        log_error "Failed to run database migrations" "${LOG_FILE}"
        return 1
    }
    
    log_success "Database migrations completed" "${LOG_FILE}"
    return 0
}

# Create initial admin user
create_admin_user() {
    log_info "Creating admin user..." "${LOG_FILE}"
    
    cd "${BACKEND_DIR}" || return 1
    
    # Check if admin user already exists
    python -c "from app.models.user import User; from app.db.session import engine; from sqlalchemy.orm import Session; \
        with Session(engine) as session: print('exists' if session.query(User).filter(User.username == '${DEFAULT_ADMIN_USER}').first() else 'not_exists')" | grep -q "exists" && {
        log_info "Admin user already exists" "${LOG_FILE}"
        return 0
    }
    
    # Create admin user
    python -c "
from app.models.user import User
from app.core.security import get_password_hash
from app.db.session import engine
from sqlalchemy.orm import Session

user = User(
    username='${DEFAULT_ADMIN_USER}',
    email='admin@example.com',
    hashed_password=get_password_hash('${DEFAULT_ADMIN_PASSWORD}'),
    is_active=True,
    is_superuser=True
)

with Session(engine) as session:
    session.add(user)
    session.commit()
    print(f'Admin user created: {user.username}')
" || {
        log_error "Failed to create admin user" "${LOG_FILE}"
        return 1
    }
    
    log_success "Admin user created: ${DEFAULT_ADMIN_USER}" "${LOG_FILE}"
    log_warning "Default admin password is set. Please change it after first login." "${LOG_FILE}"
    return 0
}

# Generate test data
generate_test_data() {
    log_info "Generating test data..." "${LOG_FILE}"
    
    cd "${BACKEND_DIR}" || return 1
    
    # Generate chemicals data
    log_info "Generating chemicals data..." "${LOG_FILE}"
    python -c "
from app.db.session import engine
from app.models.chemical import Chemical
from sqlalchemy.orm import Session
import random

# Sample chemicals data
chemicals = [
    {'name': 'Sodium Chloride', 'cas_number': '7647-14-5', 'molecular_formula': 'NaCl'},
    {'name': 'Glucose', 'cas_number': '50-99-7', 'molecular_formula': 'C6H12O6'},
    {'name': 'Acetic Acid', 'cas_number': '64-19-7', 'molecular_formula': 'CH3COOH'},
    {'name': 'Ethanol', 'cas_number': '64-17-5', 'molecular_formula': 'C2H5OH'},
    {'name': 'Sulfuric Acid', 'cas_number': '7664-93-9', 'molecular_formula': 'H2SO4'}
]

with Session(engine) as session:
    # Check if chemicals already exist
    if session.query(Chemical).count() == 0:
        for chem in chemicals:
            chemical = Chemical(**chem)
            session.add(chemical)
        session.commit()
        print(f'Added {len(chemicals)} chemicals')
    else:
        print('Chemicals already exist, skipping')
" || {
        log_warning "Failed to generate chemicals data" "${LOG_FILE}"
    }
    
    # Generate locations data
    log_info "Generating locations data..." "${LOG_FILE}"
    python -c "
from app.db.session import engine
from app.models.location import Location
from sqlalchemy.orm import Session

# Sample locations data
locations = [
    {'name': 'Lab 1', 'description': 'Main Laboratory'},
    {'name': 'Lab 2', 'description': 'Secondary Laboratory'},
    {'name': 'Storage Room A', 'description': 'Chemical Storage'},
    {'name': 'Cold Storage', 'description': 'Refrigerated Storage'},
    {'name': 'Hazardous Materials', 'description': 'Restricted Access'}
]

with Session(engine) as session:
    # Check if locations already exist
    if session.query(Location).count() == 0:
        for loc in locations:
            location = Location(**loc)
            session.add(location)
        session.commit()
        print(f'Added {len(locations)} locations')
    else:
        print('Locations already exist, skipping')
" || {
        log_warning "Failed to generate locations data" "${LOG_FILE}"
    }
    
    log_success "Test data generation completed" "${LOG_FILE}"
    return 0
}

# Main function
main() {
    # Create log directory if it doesn't exist
    mkdir -p "${LOGS_DIR}"
    
    # Parse arguments
    local generate_sample_data=true
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                usage
                ;;
            --db-path)
                shift
                DEV_DB_SCHEMA_PATH="$1"
                shift
                ;;
            --admin-user)
                shift
                DEFAULT_ADMIN_USER="$1"
                shift
                ;;
            --admin-pass)
                shift
                DEFAULT_ADMIN_PASSWORD="$1"
                shift
                ;;
            --no-sample-data)
                generate_sample_data=false
                shift
                ;;
            *)
                log_error "Unknown option: $1" "${LOG_FILE}"
                usage
                ;;
        esac
    done
    
    log_info "Starting FreeLIMS development database setup..." "${LOG_FILE}"
    
    # Activate Python virtual environment
    source "${BACKEND_DIR}/venv/bin/activate" || {
        log_error "Failed to activate virtual environment. Please run setup.sh first." "${LOG_FILE}"
        exit 1
    }
    
    # Set up database directory
    setup_db_directory || exit 1
    
    # Check PostgreSQL status
    check_postgres || exit 1
    
    # Set up development environment
    setup_dev_env || exit 1
    
    # Create development database
    create_dev_database || exit 1
    
    # Run database migrations
    run_migrations || exit 1
    
    # Create admin user
    create_admin_user || exit 1
    
    # Generate test data if requested
    if [[ "${generate_sample_data}" == "true" ]]; then
        generate_test_data || log_warning "Failed to generate test data" "${LOG_FILE}"
    fi
    
    # Deactivate virtual environment
    deactivate
    
    log_success "FreeLIMS development database setup completed successfully!" "${LOG_FILE}"
    echo ""
    echo "Development database details:"
    echo "  Database Name: ${DB_NAME}"
    echo "  Admin User: ${DEFAULT_ADMIN_USER}"
    echo "  Admin Password: ${DEFAULT_ADMIN_PASSWORD}"
    echo ""
    echo "To start the development environment, run:"
    echo "  ${REPO_ROOT}/freelims.sh dev start"
    echo ""
    
    return 0
}

# Execute main function
main "$@" 