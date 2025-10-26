"""Alert Service - Main FastAPI Application"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from .config import get_settings
from .routes.alerts import router as alerts_router
from .database import (
    get_postgres_pool,
    get_timescale_pool,
    close_postgres_pool,
    close_timescale_pool
)
from .models import HealthResponse

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup/shutdown events"""
    # Startup
    logger.info("Starting Alert Service...")

    # Initialize database pools
    postgres_connected = False
    timescale_connected = False

    try:
        postgres_pool = await get_postgres_pool()
        logger.info("PostgreSQL connection pool initialized")
        postgres_connected = True
    except Exception as e:
        logger.error(f"Failed to initialize PostgreSQL pool: {e}")

    try:
        timescale_pool = await get_timescale_pool()
        logger.info("TimescaleDB connection pool initialized")
        timescale_connected = True
    except Exception as e:
        logger.error(f"Failed to initialize TimescaleDB pool: {e}")

    if not postgres_connected or not timescale_connected:
        logger.error("Failed to initialize required database connections")
        raise RuntimeError("Database initialization failed")

    logger.info("Alert Service started successfully")

    yield

    # Shutdown
    logger.info("Shutting down Alert Service...")
    await close_postgres_pool()
    await close_timescale_pool()
    logger.info("Alert Service shutdown complete")


# Create FastAPI app
app = FastAPI(
    title="Alert Service",
    description="Alert and notification service for agent monitoring",
    version="1.0.0",
    debug=settings.debug,
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(alerts_router)


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    postgres_connected = False
    timescale_connected = False
    redis_connected = False

    # Check PostgreSQL connection
    try:
        pool = await get_postgres_pool()
        async with pool.acquire() as conn:
            await conn.fetchval("SELECT 1")
        postgres_connected = True
    except Exception as e:
        logger.error(f"PostgreSQL health check failed: {e}")

    # Check TimescaleDB connection
    try:
        pool = await get_timescale_pool()
        async with pool.acquire() as conn:
            await conn.fetchval("SELECT 1")
        timescale_connected = True
    except Exception as e:
        logger.error(f"TimescaleDB health check failed: {e}")

    # TODO: Add Redis health check when Redis is integrated
    redis_connected = True  # Placeholder

    status = "healthy" if (postgres_connected and timescale_connected) else "unhealthy"

    return HealthResponse(
        status=status,
        service="alert",
        version="1.0.0",
        postgres_connected=postgres_connected,
        timescale_connected=timescale_connected,
        redis_connected=redis_connected
    )


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Alert Service - Agent Monitoring Alert and Notification System",
        "version": "1.0.0",
        "docs": "/docs"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8006)
