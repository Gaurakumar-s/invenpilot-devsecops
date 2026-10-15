from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import Product, StockMovement
from ..schemas import (
    MovementCreate,
    MovementOut,
    ProductCreate,
    ProductOut,
    ProductUpdate,
    StatsOut,
)

router = APIRouter(prefix="/api/products", tags=["products"])


def to_out(product: Product) -> ProductOut:
    return ProductOut(
        id=product.id,
        sku=product.sku,
        name=product.name,
        category=product.category,
        description=product.description,
        quantity=product.quantity,
        reorder_level=product.reorder_level,
        unit_price=float(product.unit_price),
        low_stock=product.quantity <= product.reorder_level,
        created_at=product.created_at,
        updated_at=product.updated_at,
    )


def movement_out(m: StockMovement) -> MovementOut:
    return MovementOut(
        id=m.id,
        product_id=m.product_id,
        product_sku=m.product.sku,
        product_name=m.product.name,
        movement_type=m.movement_type,
        quantity=m.quantity,
        note=m.note,
        created_at=m.created_at,
    )


def get_or_404(db: Session, product_id: int) -> Product:
    product = db.get(Product, product_id)
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return product


@router.get("", response_model=list[ProductOut])
def list_products(
    db: Session = Depends(get_db),
    category: str | None = Query(default=None),
    search: str | None = Query(default=None, max_length=100),
):
    stmt = select(Product).order_by(Product.id.desc())
    if category:
        stmt = stmt.where(Product.category == category)
    if search:
        pattern = f"%{search.lower()}%"
        stmt = stmt.where(
            func.lower(Product.name).like(pattern) | func.lower(Product.sku).like(pattern)
        )
    return [to_out(p) for p in db.scalars(stmt)]


@router.get("/stats", response_model=StatsOut)
def product_stats(db: Session = Depends(get_db)):
    products = list(db.scalars(select(Product)))
    return StatsOut(
        total_products=len(products),
        total_units=sum(p.quantity for p in products),
        inventory_value=round(sum(p.quantity * float(p.unit_price) for p in products), 2),
        low_stock_count=sum(1 for p in products if 0 < p.quantity <= p.reorder_level),
        out_of_stock_count=sum(1 for p in products if p.quantity == 0),
        categories=len({p.category for p in products}),
    )


@router.get("/low-stock", response_model=list[ProductOut])
def low_stock(db: Session = Depends(get_db)):
    stmt = (
        select(Product)
        .where(Product.quantity <= Product.reorder_level)
        .order_by(Product.quantity.asc())
    )
    return [to_out(p) for p in db.scalars(stmt)]


@router.get("/{product_id}", response_model=ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db)):
    return to_out(get_or_404(db, product_id))


@router.post("", response_model=ProductOut, status_code=status.HTTP_201_CREATED)
def create_product(payload: ProductCreate, db: Session = Depends(get_db)):
    product = Product(**payload.model_dump())
    db.add(product)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="SKU already exists") from None
    db.refresh(product)
    return to_out(product)


@router.put("/{product_id}", response_model=ProductOut)
def update_product(product_id: int, payload: ProductUpdate, db: Session = Depends(get_db)):
    product = get_or_404(db, product_id)
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(product, key, value)
    db.commit()
    db.refresh(product)
    return to_out(product)


@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_product(product_id: int, db: Session = Depends(get_db)):
    product = get_or_404(db, product_id)
    db.delete(product)
    db.commit()
    return None


@router.post(
    "/{product_id}/movements",
    response_model=MovementOut,
    status_code=status.HTTP_201_CREATED,
)
def record_movement(product_id: int, payload: MovementCreate, db: Session = Depends(get_db)):
    product = get_or_404(db, product_id)
    if payload.movement_type == "OUT":
        if payload.quantity > product.quantity:
            raise HTTPException(
                status_code=400,
                detail=f"Insufficient stock: only {product.quantity} units available",
            )
        product.quantity -= payload.quantity
    else:
        product.quantity += payload.quantity
    movement = StockMovement(
        product=product,
        movement_type=payload.movement_type,
        quantity=payload.quantity,
        note=payload.note,
    )
    db.add(movement)
    db.commit()
    db.refresh(movement)
    return movement_out(movement)
