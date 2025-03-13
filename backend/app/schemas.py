from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional
from datetime import datetime

# User schemas
class UserBase(BaseModel):
    email: EmailStr
    username: str
    full_name: str

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    username: Optional[str] = None
    full_name: Optional[str] = None
    password: Optional[str] = None
    is_active: Optional[bool] = None

class User(UserBase):
    id: int
    is_active: bool
    is_admin: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        orm_mode = True

# Chemical schemas
class ChemicalBase(BaseModel):
    name: str
    cas_number: Optional[str] = None
    formula: Optional[str] = None
    molecular_weight: Optional[float] = None
    description: Optional[str] = None
    hazard_information: Optional[str] = None
    storage_conditions: Optional[str] = None

class ChemicalCreate(ChemicalBase):
    pass

class ChemicalUpdate(BaseModel):
    name: Optional[str] = None
    cas_number: Optional[str] = None
    formula: Optional[str] = None
    molecular_weight: Optional[float] = None
    description: Optional[str] = None
    hazard_information: Optional[str] = None
    storage_conditions: Optional[str] = None

class Chemical(ChemicalBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        orm_mode = True

# Category schemas
class CategoryBase(BaseModel):
    name: str
    description: Optional[str] = None

class CategoryCreate(CategoryBase):
    pass

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None

class Category(CategoryBase):
    id: int

    class Config:
        orm_mode = True

# Location schemas
class LocationBase(BaseModel):
    name: str
    description: Optional[str] = None

class LocationCreate(LocationBase):
    pass

class LocationUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None

class Location(LocationBase):
    id: int

    class Config:
        orm_mode = True

# Inventory Item schemas
class InventoryItemBase(BaseModel):
    chemical_id: int
    location_id: int
    quantity: float
    unit: str
    batch_number: Optional[str] = None
    expiration_date: Optional[datetime] = None
    supplier: Optional[str] = None
    acquisition_date: Optional[datetime] = None

class InventoryItemCreate(InventoryItemBase):
    pass

class InventoryItemUpdate(BaseModel):
    chemical_id: Optional[int] = None
    location_id: Optional[int] = None
    quantity: Optional[float] = None
    unit: Optional[str] = None
    batch_number: Optional[str] = None
    expiration_date: Optional[datetime] = None
    supplier: Optional[str] = None
    acquisition_date: Optional[datetime] = None

class InventoryItem(InventoryItemBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    chemical: Chemical
    location: Location

    class Config:
        orm_mode = True

# Inventory Change schemas
class InventoryChangeBase(BaseModel):
    inventory_item_id: int
    change_amount: float
    reason: str
    supplier: Optional[str] = None
    acquisition_date: Optional[datetime] = None

class InventoryChangeCreate(InventoryChangeBase):
    pass

class InventoryChange(InventoryChangeBase):
    id: int
    user_id: int
    timestamp: datetime

    class Config:
        orm_mode = True

# Inventory Audit schemas
class InventoryAuditBase(BaseModel):
    inventory_item_id: int
    field_name: str
    old_value: str
    new_value: str
    action: str

class InventoryAuditCreate(InventoryAuditBase):
    pass

class InventoryAudit(InventoryAuditBase):
    id: int
    user_id: int
    timestamp: datetime

    class Config:
        orm_mode = True

# Chemical Audit schemas
class ChemicalAuditBase(BaseModel):
    chemical_id: int
    field_name: str
    old_value: str
    new_value: str
    action: str

class ChemicalAuditCreate(ChemicalAuditBase):
    pass

class ChemicalAudit(ChemicalAuditBase):
    id: int
    user_id: int
    timestamp: datetime

    class Config:
        orm_mode = True

# Location Audit schemas
class LocationAuditBase(BaseModel):
    location_id: int
    field_name: str
    old_value: str
    new_value: str
    action: str

class LocationAuditCreate(LocationAuditBase):
    pass

class LocationAudit(LocationAuditBase):
    id: int
    user_id: int
    timestamp: datetime

    class Config:
        orm_mode = True

# Token schemas for authentication
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None 