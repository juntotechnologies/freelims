from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from sqlalchemy import or_

from ..database import get_db
from ..schemas import InventoryItem, InventoryItemCreate, InventoryItemUpdate, InventoryChange, InventoryChangeCreate, InventoryAudit, InventoryAuditCreate
from ..models import InventoryItem as InventoryItemModel, InventoryChange as InventoryChangeModel, Chemical as ChemicalModel, Location as LocationModel, InventoryAudit as InventoryAuditModel
from ..auth import get_current_active_user, get_current_user
from ..websockets import notify_clients  # Import the notify_clients function

router = APIRouter()

@router.post("/items", response_model=InventoryItem, status_code=status.HTTP_201_CREATED)
async def create_inventory_item(
    item: InventoryItemCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Create a new inventory item.
    """
    # Check if chemical exists
    chemical = db.query(ChemicalModel).filter(ChemicalModel.id == item.chemical_id).first()
    if not chemical:
        raise HTTPException(status_code=404, detail="Chemical not found")
    
    # Check if location exists
    location = db.query(LocationModel).filter(LocationModel.id == item.location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")
    
    # Create new inventory item
    db_item = InventoryItemModel(
        chemical_id=item.chemical_id,
        location_id=item.location_id,
        quantity=item.quantity,
        unit=item.unit,
        batch_number=item.batch_number,
        expiration_date=item.expiration_date
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    
    # Create initial inventory change record
    inventory_change = InventoryChangeModel(
        inventory_item_id=db_item.id,
        user_id=current_user.id,
        change_amount=item.quantity,
        reason="Initial inventory creation"
    )
    db.add(inventory_change)
    
    # Create audit record for the item creation
    audit_record = InventoryAuditModel(
        inventory_item_id=db_item.id,
        user_id=current_user.id,
        field_name="all",
        old_value="",
        new_value=f"Chemical: {chemical.name}, Location: {location.name}, Quantity: {item.quantity}, Unit: {item.unit}, Batch: {item.batch_number}",
        action="CREATE"
    )
    db.add(audit_record)
    db.commit()
    
    # Notify all connected clients about the new inventory item
    await notify_clients('inventory', 'create', db_item.as_dict())
    
    return db_item

@router.get("/items", response_model=List[InventoryItem])
async def read_inventory_items(
    skip: int = 0,
    limit: int = 100,
    search: Optional[str] = None,
    chemical_id: Optional[int] = None,
    location_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Get all inventory items with optional filtering.
    """
    query = db.query(InventoryItemModel)
    
    if chemical_id:
        query = query.filter(InventoryItemModel.chemical_id == chemical_id)
    
    if location_id:
        query = query.filter(InventoryItemModel.location_id == location_id)
    
    if search:
        search_term = f"%{search}%"
        query = query.join(ChemicalModel).filter(
            or_(
                ChemicalModel.name.ilike(search_term),
                ChemicalModel.cas_number.ilike(search_term),
                InventoryItemModel.batch_number.ilike(search_term)
            )
        )
    
    items = query.offset(skip).limit(limit).all()
    return items

@router.get("/items/{item_id}", response_model=InventoryItem)
async def read_inventory_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Get a specific inventory item by ID.
    """
    db_item = db.query(InventoryItemModel).filter(InventoryItemModel.id == item_id).first()
    if db_item is None:
        raise HTTPException(status_code=404, detail="Inventory item not found")
    return db_item

@router.put("/items/{item_id}", response_model=InventoryItem)
async def update_inventory_item(
    item_id: int,
    item: InventoryItemUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Update an inventory item by ID.
    """
    db_item = db.query(InventoryItemModel).filter(InventoryItemModel.id == item_id).first()
    if db_item is None:
        raise HTTPException(status_code=404, detail="Inventory item not found")
    
    # Check if chemical exists if being updated
    if item.chemical_id is not None and item.chemical_id != db_item.chemical_id:
        chemical = db.query(ChemicalModel).filter(ChemicalModel.id == item.chemical_id).first()
        if not chemical:
            raise HTTPException(status_code=404, detail="Chemical not found")
        
        # Create audit record for chemical change
        old_chemical = db.query(ChemicalModel).filter(ChemicalModel.id == db_item.chemical_id).first()
        audit_record = InventoryAuditModel(
            inventory_item_id=db_item.id,
            user_id=current_user.id,
            field_name="chemical_id",
            old_value=f"{old_chemical.name} (ID: {db_item.chemical_id})" if old_chemical else str(db_item.chemical_id),
            new_value=f"{chemical.name} (ID: {item.chemical_id})",
            action="UPDATE"
        )
        db.add(audit_record)
        
        # Update the field
        db_item.chemical_id = item.chemical_id
    
    # Check if location exists if being updated
    if item.location_id is not None and item.location_id != db_item.location_id:
        location = db.query(LocationModel).filter(LocationModel.id == item.location_id).first()
        if not location:
            raise HTTPException(status_code=404, detail="Location not found")
        
        # Create audit record for location change
        old_location = db.query(LocationModel).filter(LocationModel.id == db_item.location_id).first()
        audit_record = InventoryAuditModel(
            inventory_item_id=db_item.id,
            user_id=current_user.id,
            field_name="location_id",
            old_value=f"{old_location.name} (ID: {db_item.location_id})" if old_location else str(db_item.location_id),
            new_value=f"{location.name} (ID: {item.location_id})",
            action="UPDATE"
        )
        db.add(audit_record)
        
        # Update the field
        db_item.location_id = item.location_id
    
    # Update batch number if changed
    if item.batch_number is not None and item.batch_number != db_item.batch_number:
        # Create audit record for batch number change
        audit_record = InventoryAuditModel(
            inventory_item_id=db_item.id,
            user_id=current_user.id,
            field_name="batch_number",
            old_value=db_item.batch_number or "",
            new_value=item.batch_number,
            action="UPDATE"
        )
        db.add(audit_record)
        
        # Update the field
        db_item.batch_number = item.batch_number
    
    # Update expiration date if changed
    if item.expiration_date is not None and item.expiration_date != db_item.expiration_date:
        # Create audit record for expiration date change
        audit_record = InventoryAuditModel(
            inventory_item_id=db_item.id,
            user_id=current_user.id,
            field_name="expiration_date",
            old_value=str(db_item.expiration_date) if db_item.expiration_date else "",
            new_value=str(item.expiration_date),
            action="UPDATE"
        )
        db.add(audit_record)
        
        # Update the field
        db_item.expiration_date = item.expiration_date
    
    # Update unit if changed
    if item.unit is not None and item.unit != db_item.unit:
        # Create audit record for unit change
        audit_record = InventoryAuditModel(
            inventory_item_id=db_item.id,
            user_id=current_user.id,
            field_name="unit",
            old_value=db_item.unit,
            new_value=item.unit,
            action="UPDATE"
        )
        db.add(audit_record)
        
        # Update the field
        db_item.unit = item.unit
    
    # Handle quantity change separately to create a change record
    if item.quantity is not None and item.quantity != db_item.quantity:
        change_amount = item.quantity - db_item.quantity
        
        # Create inventory change record
        inventory_change = InventoryChangeModel(
            inventory_item_id=db_item.id,
            user_id=current_user.id,
            change_amount=change_amount,
            reason="Manual inventory update"
        )
        db.add(inventory_change)
        
        # Create audit record for quantity change
        audit_record = InventoryAuditModel(
            inventory_item_id=db_item.id,
            user_id=current_user.id,
            field_name="quantity",
            old_value=str(db_item.quantity),
            new_value=str(item.quantity),
            action="UPDATE"
        )
        db.add(audit_record)
        
        # Update quantity
        db_item.quantity = item.quantity
    
    db.commit()
    db.refresh(db_item)
    
    # Notify all connected clients about the updated inventory item
    await notify_clients('inventory', 'update', db_item.as_dict())
    
    return db_item

@router.post("/changes", response_model=InventoryChange, status_code=status.HTTP_201_CREATED)
async def create_inventory_change(
    change: InventoryChangeCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Record an inventory change (consumption or addition).
    """
    # Check if inventory item exists
    db_item = db.query(InventoryItemModel).filter(InventoryItemModel.id == change.inventory_item_id).first()
    if db_item is None:
        raise HTTPException(status_code=404, detail="Inventory item not found")
    
    # Check if experiment exists if provided
    if change.experiment_id:
        experiment = db.query(ExperimentModel).filter(ExperimentModel.id == change.experiment_id).first()
        if not experiment:
            raise HTTPException(status_code=404, detail="Experiment not found")
    
    # Record old quantity before change
    old_quantity = db_item.quantity
    new_quantity = db_item.quantity + change.change_amount
    
    # Create inventory change record
    db_change = InventoryChangeModel(
        inventory_item_id=change.inventory_item_id,
        user_id=current_user.id,
        change_amount=change.change_amount,
        reason=change.reason,
        experiment_id=change.experiment_id
    )
    db.add(db_change)
    
    # Create audit record for the quantity change
    audit_record = InventoryAuditModel(
        inventory_item_id=db_item.id,
        user_id=current_user.id,
        field_name="quantity",
        old_value=str(old_quantity),
        new_value=str(new_quantity),
        action="UPDATE"
    )
    db.add(audit_record)
    
    # Update inventory quantity
    db_item.quantity = new_quantity
    
    # Check if quantity is negative
    if db_item.quantity < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inventory quantity cannot be negative"
        )
    
    db.commit()
    db.refresh(db_change)
    db.refresh(db_item)  # Refresh the item to get updated quantity
    
    # Notify all connected clients about the inventory change
    await notify_clients('inventory', 'update', db_item.as_dict())
    
    return db_change

@router.get("/changes", response_model=List[InventoryChange])
async def read_inventory_changes(
    skip: int = 0,
    limit: int = 100,
    inventory_item_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Get inventory changes with optional filtering.
    """
    query = db.query(InventoryChangeModel)
    
    if inventory_item_id:
        query = query.filter(InventoryChangeModel.inventory_item_id == inventory_item_id)
    
    changes = query.order_by(InventoryChangeModel.timestamp.desc()).offset(skip).limit(limit).all()
    return changes

@router.get("/audit", response_model=List[InventoryAudit])
async def read_inventory_audit_logs(
    skip: int = 0,
    limit: int = 100,
    inventory_item_id: Optional[int] = None,
    field_name: Optional[str] = None,
    action: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    """
    Get inventory audit logs with optional filtering.
    """
    query = db.query(InventoryAuditModel)
    
    if inventory_item_id:
        query = query.filter(InventoryAuditModel.inventory_item_id == inventory_item_id)
    
    if field_name:
        query = query.filter(InventoryAuditModel.field_name == field_name)
    
    if action:
        query = query.filter(InventoryAuditModel.action == action)
    
    audit_logs = query.order_by(InventoryAuditModel.timestamp.desc()).offset(skip).limit(limit).all()
    return audit_logs 