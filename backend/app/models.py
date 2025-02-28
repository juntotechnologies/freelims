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

experiment_chemical = Table(
    'experiment_chemical',
    Base.metadata,
    Column('experiment_id', Integer, ForeignKey('experiments.id')),
    Column('chemical_id', Integer, ForeignKey('chemicals.id'))
)

# Association table for test and analysts (many-to-many)
test_analyst = Table(
    'test_analyst',
    Base.metadata,
    Column('test_id', Integer, ForeignKey('tests.id')),
    Column('user_id', Integer, ForeignKey('users.id'))
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
    experiments = relationship("Experiment", back_populates="user")
    inventory_changes = relationship("InventoryChange", back_populates="user")
    inventory_audits = relationship("InventoryAudit", back_populates="user")
    settings_updates = relationship("SystemSettings", back_populates="updated_by")
    tests_as_analyst = relationship("Test", secondary=test_analyst, back_populates="analysts")
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
    experiments = relationship("Experiment", secondary=experiment_chemical, back_populates="chemicals")
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
    experiment_id = Column(Integer, ForeignKey("experiments.id"), nullable=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    inventory_item = relationship("InventoryItem", back_populates="inventory_changes")
    user = relationship("User", back_populates="inventory_changes")
    experiment = relationship("Experiment", back_populates="inventory_changes")

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

class Experiment(Base, ModelMixin):
    __tablename__ = "experiments"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(Text)
    procedure = Column(Text)
    results = Column(Text)
    user_id = Column(Integer, ForeignKey("users.id"))
    status = Column(String)  # planned, in-progress, completed, failed
    start_date = Column(DateTime)
    end_date = Column(DateTime, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="experiments")
    chemicals = relationship("Chemical", secondary=experiment_chemical, back_populates="experiments")
    inventory_changes = relationship("InventoryChange", back_populates="experiment")
    notes = relationship("ExperimentNote", back_populates="experiment")

class ExperimentNote(Base, ModelMixin):
    __tablename__ = "experiment_notes"

    id = Column(Integer, primary_key=True, index=True)
    experiment_id = Column(Integer, ForeignKey("experiments.id"))
    content = Column(Text)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    experiment = relationship("Experiment", back_populates="notes")

class SystemSettings(Base, ModelMixin):
    __tablename__ = "system_settings"

    id = Column(Integer, primary_key=True, index=True)
    company_name = Column(String, default="FreeLIMS")
    system_email = Column(String)
    backup_enabled = Column(Boolean, default=True)
    backup_frequency = Column(String, default="daily")
    backup_location = Column(String, default="/backup")
    email_notifications = Column(Boolean, default=True)
    auto_logout = Column(Integer, default=30)  # minutes
    password_expiry = Column(Integer, default=90)  # days
    require_two_factor = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    updated_by_id = Column(Integer, ForeignKey("users.id"))

    # Relationships
    updated_by = relationship("User", back_populates="settings_updates")

class Test(Base, ModelMixin):
    __tablename__ = "tests"

    id = Column(Integer, primary_key=True, index=True)
    internal_id = Column(String, unique=True, index=True)
    test_id = Column(String, index=True)
    sample_id = Column(String, index=True)
    test_type = Column(String)  # HPLC, GC, Titration, IR, NMR
    method = Column(String)
    status = Column(String)  # Pending, In Progress, Completed, Failed
    start_date = Column(DateTime(timezone=True))
    test_date = Column(DateTime(timezone=True))
    completion_date = Column(DateTime(timezone=True), nullable=True)
    results = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    analysts = relationship("User", secondary=test_analyst, back_populates="tests_as_analyst")

# New audit tables for chemicals and locations
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