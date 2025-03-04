"""Remove username use email

Revision ID: xxxx
Revises: previous_revision
Create Date: 2024-xx-xx

"""
from alembic import op
import sqlalchemy as sa

def upgrade():
    # Add email column if it doesn't exist
    op.add_column('users', sa.Column('email', sa.String(), nullable=True))
    
    # Copy usernames to email if needed (for existing data)
    op.execute("UPDATE users SET email = username WHERE email IS NULL")
    
    # Make email required and unique
    op.alter_column('users', 'email', nullable=False)
    op.create_unique_constraint('uq_users_email', 'users', ['email'])
    
    # Remove username column
    op.drop_column('users', 'username')

def downgrade():
    # Add username column
    op.add_column('users', sa.Column('username', sa.String(), nullable=True))
    
    # Copy emails to username
    op.execute("UPDATE users SET username = email WHERE username IS NULL")
    
    # Make username required and unique
    op.alter_column('users', 'username', nullable=False)
    op.create_unique_constraint('uq_users_username', 'users', ['username'])
    
    # Remove constraints from email
    op.drop_constraint('uq_users_email', 'users')
    op.alter_column('users', 'email', nullable=True) 