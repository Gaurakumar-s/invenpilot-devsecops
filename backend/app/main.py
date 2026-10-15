from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from sqlalchemy import text
from sqlalchemy.orm import Session

from .config import settings
from .db import get_db
from .routers import movements, products

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="Inventory management API: products, stock levels and stock movements.",
)
app.add_middleware(
    CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"]
)

# Prometheus metrics: http_requests_total, http_request_duration_seconds, ...
Instrumentator(
    should_group_status_codes=False,
    excluded_handlers=["/metrics", "/health", "/ready"],
).instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)

app.include_router(products.router)
app.include_router(movements.router)


@app.get("/", tags=["system"])
def root():
    return {
        "service": settings.app_name,
        "version": settings.app_version,
        "docs": "/docs",
        "health": "/health",
        "metrics": "/metrics",
    }


@app.get("/health", tags=["system"])
def health():
    """Liveness probe: process is up."""
    return {"status": "UP"}


@app.get("/ready", tags=["system"])
def ready(db: Session = Depends(get_db)):
    """Readiness probe: database reachable."""
    db.execute(text("SELECT 1"))
    return {"status": "READY", "database": "connected"}
