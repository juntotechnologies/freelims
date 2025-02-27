from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from sqlalchemy import or_
from datetime import datetime, timedelta

from ..database import get_db
from ..schemas import Location, LocationCreate, LocationUpdate, LocationAuditCreate, LocationAudit
from ..models import Location as LocationModel, LocationAudit as LocationAuditModel, User as UserModel
from ..auth import get_current_active_user

router = APIRouter()

# Helper function to create an audit log entry
def create_audit_log(db: Session, user_id: int, location_id: int, field_name: str, old_value: str, new_value: str, action: str):
    audit_entry = LocationAuditModel(
        location_id=location_id,
        user_id=user_id,
        field_name=field_name,
        old_value=old_value,
        new_value=new_value,
        action=action
    )
    db.add(audit_entry)
    db.commit()

@router.post("/", response_model=Location, status_code=status.HTTP_201_CREATED)
async def create_location(
    location: LocationCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Create a new location.
    """
    # Check if location with this name already exists
    db_location = db.query(LocationModel).filter(LocationModel.name == location.name).first()
    if db_location:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Location with this name already exists"
        )
    
    # Create new location
    db_location = LocationModel(
        name=location.name,
        description=location.description,
    )
    db.add(db_location)
    db.commit()
    db.refresh(db_location)
    
    # Create audit log entries for the creation
    create_audit_log(db, current_user.id, db_location.id, "name", "", db_location.name, "CREATE")
    if db_location.description:
        create_audit_log(db, current_user.id, db_location.id, "description", "", db_location.description, "CREATE")
    
    return db_location

@router.get("/", response_model=List[Location])
async def read_locations(
    skip: int = 0,
    limit: int = 100,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Retrieve locations.
    """
    query = db.query(LocationModel)
    
    if search:
        query = query.filter(
            or_(
                LocationModel.name.ilike(f"%{search}%"),
                LocationModel.description.ilike(f"%{search}%")
            )
        )
    
    locations = query.offset(skip).limit(limit).all()
    return locations

@router.get("/{location_id}", response_model=Location)
async def read_location(
    location_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Get a specific location by ID.
    """
    location = db.query(LocationModel).filter(LocationModel.id == location_id).first()
    if location is None:
        raise HTTPException(status_code=404, detail="Location not found")
    return location

@router.put("/{location_id}", response_model=Location)
async def update_location(
    location_id: int, 
    location_update: LocationUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Update a location.
    """
    db_location = db.query(LocationModel).filter(LocationModel.id == location_id).first()
    if not db_location:
        raise HTTPException(status_code=404, detail="Location not found")
    
    # Store original values for audit logging
    original_name = db_location.name
    original_description = db_location.description
    
    # Update location data
    if location_update.name is not None:
        # Check if the new name already exists in another location
        if location_update.name != original_name:
            existing = db.query(LocationModel).filter(
                LocationModel.name == location_update.name,
                LocationModel.id != location_id
            ).first()
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Location with this name already exists"
                )
        db_location.name = location_update.name
    
    if location_update.description is not None:
        db_location.description = location_update.description
    
    db.commit()
    db.refresh(db_location)
    
    # Create audit log entries for changes
    if db_location.name != original_name:
        create_audit_log(db, current_user.id, db_location.id, "name", original_name, db_location.name, "UPDATE")
    if db_location.description != original_description:
        create_audit_log(db, current_user.id, db_location.id, "description", original_description or "", db_location.description or "", "UPDATE")
    
    return db_location

@router.delete("/{location_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_location(
    location_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Delete a location.
    """
    db_location = db.query(LocationModel).filter(LocationModel.id == location_id).first()
    if not db_location:
        raise HTTPException(status_code=404, detail="Location not found")
    
    # Check if this location is associated with any inventory items
    if db_location.inventory_items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete location that is associated with inventory items"
        )
    
    # Create audit log for the deletion
    create_audit_log(db, current_user.id, location_id, "location", db_location.name, "", "DELETE")
    
    db.delete(db_location)
    db.commit()
    return None

@router.get("/audit-logs/", response_model=List[LocationAudit])
async def get_location_audit_logs(
    location_id: Optional[int] = None,
    action: Optional[str] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Retrieve audit logs for locations with optional filtering.
    """
    query = db.query(LocationAuditModel).join(UserModel, LocationAuditModel.user_id == UserModel.id)
    
    if location_id:
        query = query.filter(LocationAuditModel.location_id == location_id)
    
    if action:
        query = query.filter(LocationAuditModel.action == action)
    
    if start_date:
        query = query.filter(LocationAuditModel.timestamp >= start_date)
    
    if end_date:
        query = query.filter(LocationAuditModel.timestamp <= end_date)
    
    # Order by timestamp (most recent first)
    query = query.order_by(LocationAuditModel.timestamp.desc())
    
    audit_logs = query.offset(skip).limit(limit).all()
    return audit_logs

@router.get("/{location_id}/audit-logs/", response_model=List[LocationAudit])
async def get_audit_logs_for_location(
    location_id: int,
    action: Optional[str] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Retrieve audit logs for a specific location.
    """
    # Verify location exists
    location = db.query(LocationModel).filter(LocationModel.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")
    
    query = db.query(LocationAuditModel).filter(LocationAuditModel.location_id == location_id)
    
    if action:
        query = query.filter(LocationAuditModel.action == action)
    
    if start_date:
        query = query.filter(LocationAuditModel.timestamp >= start_date)
    
    if end_date:
        query = query.filter(LocationAuditModel.timestamp <= end_date)
    
    # Order by timestamp (most recent first)
    query = query.order_by(LocationAuditModel.timestamp.desc())
    
    audit_logs = query.offset(skip).limit(limit).all()
    return audit_logs 