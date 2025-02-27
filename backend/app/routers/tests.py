from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from .. import schemas, models, database
from ..dependencies import get_current_active_user

router = APIRouter(
    prefix="/api/tests",
    tags=["tests"],
    dependencies=[Depends(get_current_active_user)],
)

@router.get("/", response_model=List[schemas.Test])
def read_tests(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(database.get_db),
    current_user: schemas.User = Depends(get_current_active_user)
):
    return db.query(models.Test).offset(skip).limit(limit).all()

@router.post("/", response_model=schemas.Test, status_code=status.HTTP_201_CREATED)
def create_test(
    test: schemas.TestCreate,
    db: Session = Depends(database.get_db),
    current_user: schemas.User = Depends(get_current_active_user)
):
    db_test = models.Test(
        internal_id=test.internal_id,
        test_id=test.test_id,
        sample_id=test.sample_id,
        test_type=test.test_type,
        method=test.method,
        status=test.status,
        start_date=test.start_date,
        test_date=test.test_date,
        results=test.results
    )
    db.add(db_test)
    db.flush()  # Flush to get the id of the test
    
    # Add analysts to the test
    for analyst_id in test.analyst_ids:
        analyst = db.query(models.User).filter(models.User.id == analyst_id).first()
        if analyst:
            db_test.analysts.append(analyst)
        else:
            db.rollback()
            raise HTTPException(status_code=404, detail=f"Analyst with id {analyst_id} not found")
    
    db.commit()
    db.refresh(db_test)
    return db_test

@router.get("/{test_id}", response_model=schemas.Test)
def read_test(
    test_id: int,
    db: Session = Depends(database.get_db),
    current_user: schemas.User = Depends(get_current_active_user)
):
    db_test = db.query(models.Test).filter(models.Test.id == test_id).first()
    if db_test is None:
        raise HTTPException(status_code=404, detail="Test not found")
    return db_test

@router.put("/{test_id}", response_model=schemas.Test)
def update_test(
    test_id: int,
    test: schemas.TestUpdate,
    db: Session = Depends(database.get_db),
    current_user: schemas.User = Depends(get_current_active_user)
):
    db_test = db.query(models.Test).filter(models.Test.id == test_id).first()
    if db_test is None:
        raise HTTPException(status_code=404, detail="Test not found")
    
    # Update test fields
    test_data = test.dict(exclude_unset=True)
    analyst_ids = None
    
    # Extract analyst_ids before updating the test
    if "analyst_ids" in test_data:
        analyst_ids = test_data.pop("analyst_ids")
    
    for key, value in test_data.items():
        setattr(db_test, key, value)
    
    # Update analysts if provided
    if analyst_ids is not None:
        db_test.analysts = []  # Clear existing analysts
        for analyst_id in analyst_ids:
            analyst = db.query(models.User).filter(models.User.id == analyst_id).first()
            if analyst:
                db_test.analysts.append(analyst)
            else:
                raise HTTPException(status_code=404, detail=f"Analyst with id {analyst_id} not found")
    
    db.commit()
    db.refresh(db_test)
    return db_test

@router.delete("/{test_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_test(
    test_id: int,
    db: Session = Depends(database.get_db),
    current_user: schemas.User = Depends(get_current_active_user)
):
    db_test = db.query(models.Test).filter(models.Test.id == test_id).first()
    if db_test is None:
        raise HTTPException(status_code=404, detail="Test not found")
    
    db.delete(db_test)
    db.commit()
    return {"ok": True}

@router.get("/types/", response_model=List[str])
def read_test_types():
    """Return the available test types"""
    return ["HPLC", "GC", "Titration", "IR", "NMR"] 