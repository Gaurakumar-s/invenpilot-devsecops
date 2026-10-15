from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class ProductBase(BaseModel):
    sku: str = Field(min_length=2, max_length=40, examples=["LAP-001"])
    name: str = Field(min_length=1, max_length=200, examples=["Dell Latitude 5540"])
    category: str = Field(default="General", max_length=80)
    description: str = Field(default="", max_length=2000)
    quantity: int = Field(default=0, ge=0)
    reorder_level: int = Field(default=10, ge=0)
    unit_price: float = Field(default=0, ge=0)


class ProductCreate(ProductBase):
    pass


class ProductUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=200)
    category: str | None = Field(default=None, max_length=80)
    description: str | None = Field(default=None, max_length=2000)
    quantity: int | None = Field(default=None, ge=0)
    reorder_level: int | None = Field(default=None, ge=0)
    unit_price: float | None = Field(default=None, ge=0)


class ProductOut(ProductBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    low_stock: bool
    created_at: datetime
    updated_at: datetime


class MovementCreate(BaseModel):
    movement_type: Literal["IN", "OUT"]
    quantity: int = Field(gt=0)
    note: str = Field(default="", max_length=255)


class MovementOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    product_id: int
    product_sku: str
    product_name: str
    movement_type: str
    quantity: int
    note: str
    created_at: datetime


class StatsOut(BaseModel):
    total_products: int
    total_units: int
    inventory_value: float
    low_stock_count: int
    out_of_stock_count: int
    categories: int
