from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ..database import get_db
from ..schemas import SystemSettings, SystemSettingsCreate, SystemSettingsUpdate
from ..models import SystemSettings as SystemSettingsModel
from ..auth import get_current_admin_user, get_current_active_user

router = APIRouter()

@router.get("/", response_model=SystemSettings)
async def get_settings(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Get system settings. Any authenticated user can view settings.
    """
    settings = db.query(SystemSettingsModel).first()
    if not settings:
        # Create default settings if none exist
        settings = SystemSettingsModel()
        db.add(settings)
        db.commit()
        db.refresh(settings)
    return settings

@router.put("/", response_model=SystemSettings)
async def update_settings(
    settings: SystemSettingsUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_admin_user)
):
    """
    Update system settings. Admin only.
    """
    db_settings = db.query(SystemSettingsModel).first()
    if not db_settings:
        db_settings = SystemSettingsModel()
        db.add(db_settings)
    
    # Update settings fields
    for field, value in settings.dict(exclude_unset=True).items():
        setattr(db_settings, field, value)
    
    db_settings.updated_by_id = current_user.id
    db.commit()
    db.refresh(db_settings)
    return db_settings 