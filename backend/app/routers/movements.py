from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from ..db import get_db
from ..models import StockMovement
from ..schemas import MovementOut
from .products import movement_out

router = APIRouter(prefix="/api/movements", tags=["movements"])


@router.get("", response_model=list[MovementOut])
def list_movements(db: Session = Depends(get_db), limit: int = Query(default=20, ge=1, le=200)):
    stmt = (
        select(StockMovement)
        .options(selectinload(StockMovement.product))
        .order_by(StockMovement.id.desc())
        .limit(limit)
    )
    return [movement_out(m) for m in db.scalars(stmt)]
