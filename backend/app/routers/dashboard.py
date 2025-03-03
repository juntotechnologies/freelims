from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Dict

from ..database import get_db
from ..models import InventoryItem, User, Experiment
from ..auth import get_current_active_user

router = APIRouter()

@router.get("/stats", response_model=Dict[str, int])
async def get_dashboard_stats(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Get dashboard statistics including counts of inventory items, active users,
    and pending experiments/tests.
    """
    # Count inventory items
    inventory_count = db.query(InventoryItem).count()
    
    # Count active users
    active_users_count = db.query(User).filter(User.is_active == True).count()
    
    # Count pending tests/experiments
    pending_tests_count = db.query(Experiment).filter(Experiment.status == "pending").count()
    
    return {
        "inventoryItems": inventory_count,
        "activeUsers": active_users_count,
        "pendingTests": pending_tests_count
    } 