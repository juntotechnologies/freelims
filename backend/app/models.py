from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime, Text, Table
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base
from datetime import datetime

# Base model mixin with as_dict implementation
class ModelMixin:
    def as_dict(self):
        """Convert model instance to dictionary for JSON serialization"""
        result = {}
        for column in self.__table__.columns:
            value = getattr(self, column.name)
            # Convert datetime objects to ISO format strings for JSON serialization
            if isinstance(value, datetime):
                value = value.isoformat()
            result[column.name] = value
        return result

# Association tables for many-to-many relationships
chemical_category = Table(
    'chemical_category',
    Base.metadata,
    Column('chemical_id', Integer, ForeignKey('chemicals.id')),
    Column('category_id', Integer, ForeignKey('categories.id'))
)

class User(Base, ModelMixin):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    username = Column(String, unique=True, index=True)
    full_name = Column(String)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)
    is_admin = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    inventory_changes = relationship("InventoryChange", back_populates="user")
    inventory_audits = relationship("InventoryAudit", back_populates="user")
    chemical_audits = relationship("ChemicalAudit", back_populates="user")
    location_audits = relationship("LocationAudit", back_populates="user")

class Chemical(Base, ModelMixin):
    __tablename__ = "chemicals"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    cas_number = Column(String, unique=True, index=True)
    formula = Column(String)
    molecular_weight = Column(Float)
    description = Column(Text)
    hazard_information = Column(Text)
    storage_conditions = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    inventory_items = relationship("InventoryItem", back_populates="chemical")
    categories = relationship("Category", secondary=chemical_category, back_populates="chemicals")
    audit_logs = relationship("ChemicalAudit", back_populates="chemical")

class Category(Base, ModelMixin):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    description = Column(Text)

    # Relationships
    chemicals = relationship("Chemical", secondary=chemical_category, back_populates="categories")

class Location(Base, ModelMixin):
    __tablename__ = "locations"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    description = Column(Text)
    
    # Relationships
    inventory_items = relationship("InventoryItem", back_populates="location")
    audit_logs = relationship("LocationAudit", back_populates="location")

class InventoryItem(Base, ModelMixin):
    __tablename__ = "inventory_items"

    id = Column(Integer, primary_key=True, index=True)
    chemical_id = Column(Integer, ForeignKey("chemicals.id"))
    location_id = Column(Integer, ForeignKey("locations.id"))
    quantity = Column(Float)
    unit = Column(String)
    batch_number = Column(String, index=True)
    expiration_date = Column(DateTime)
    supplier = Column(String, nullable=True)
    acquisition_date = Column(DateTime, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    chemical = relationship("Chemical", back_populates="inventory_items")
    location = relationship("Location", back_populates="inventory_items")
    inventory_changes = relationship("InventoryChange", back_populates="inventory_item")
    audit_logs = relationship("InventoryAudit", back_populates="inventory_item")

class InventoryChange(Base, ModelMixin):
    __tablename__ = "inventory_changes"

    id = Column(Integer, primary_key=True, index=True)
    inventory_item_id = Column(Integer, ForeignKey("inventory_items.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    change_amount = Column(Float)
    reason = Column(String)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    supplier = Column(String, nullable=True)
    acquisition_date = Column(DateTime, nullable=True)

    # Relationships
    inventory_item = relationship("InventoryItem", back_populates="inventory_changes")
    user = relationship("User", back_populates="inventory_changes")

class InventoryAudit(Base, ModelMixin):
    __tablename__ = "inventory_audits"

    id = Column(Integer, primary_key=True, index=True)
    inventory_item_id = Column(Integer, ForeignKey("inventory_items.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    field_name = Column(String)  # The field that was changed
    old_value = Column(String)   # Store as string, convert as needed
    new_value = Column(String)   # Store as string, convert as needed
    action = Column(String)      # "CREATE", "UPDATE", "DELETE"
    timestamp = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    inventory_item = relationship("InventoryItem", back_populates="audit_logs")
    user = relationship("User", back_populates="inventory_audits")

# Audit tables for chemicals and locations
class ChemicalAudit(Base, ModelMixin):
    __tablename__ = "chemical_audits"

    id = Column(Integer, primary_key=True, index=True)
    chemical_id = Column(Integer, ForeignKey("chemicals.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    field_name = Column(String)  # The field that was changed
    old_value = Column(String)   # Store as string, convert as needed
    new_value = Column(String)   # Store as string, convert as needed
    action = Column(String)      # "CREATE", "UPDATE", "DELETE"
    timestamp = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    chemical = relationship("Chemical", back_populates="audit_logs")
    user = relationship("User", back_populates="chemical_audits")

class LocationAudit(Base, ModelMixin):
    __tablename__ = "location_audits"

    id = Column(Integer, primary_key=True, index=True)
    location_id = Column(Integer, ForeignKey("locations.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    field_name = Column(String)  # The field that was changed
    old_value = Column(String)   # Store as string, convert as needed
    new_value = Column(String)   # Store as string, convert as needed
    action = Column(String)      # "CREATE", "UPDATE", "DELETE"
    timestamp = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    location = relationship("Location", back_populates="audit_logs")
    user = relationship("User", back_populates="location_audits") 