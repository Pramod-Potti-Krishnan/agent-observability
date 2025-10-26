"""Gemini Integration Service - Main FastAPI Application"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from .config import get_settings
from .routes.insights import router as insights_router
from .database import get_postgres_pool, get_timescale_pool, get_redis_client, close_pools, check_database_connections
from .gemini_client import is_gemini_configured
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
    logger.info("Starting Gemini Integration Service...")

    # Initialize database pools
    try:
        postgres_pool = await get_postgres_pool()
        logger.info("PostgreSQL connection pool initialized")

        timescale_pool = await get_timescale_pool()
        logger.info("TimescaleDB connection pool initialized")

        redis_client = await get_redis_client()
        logger.info("Redis client initialized")
    except Exception as e:
        logger.error(f"Failed to initialize connections: {e}")
        raise

    # Check Gemini configuration
    if is_gemini_configured():
        logger.info(f"Gemini API configured with model: {settings.gemini_model}")
    else:
        logger.warning("Gemini API not configured - insights will fail")

    yield

    # Shutdown
    logger.info("Shutting down Gemini Integration Service...")
    await close_pools()


# Create FastAPI app
app = FastAPI(
    title="Gemini Integration Service",
    description="AI-powered business insights service using Google Gemini for cost optimization, error diagnosis, and feedback analysis",
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
app.include_router(insights_router)


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    db_status = await check_database_connections()

    databases_ok = db_status['postgres'] and db_status['timescale']
    redis_ok = db_status['redis']

    return HealthResponse(
        status="healthy" if (databases_ok and redis_ok) else "degraded",
        service="gemini",
        version="1.0.0",
        gemini_configured=is_gemini_configured(),
        databases_connected=databases_ok,
        redis_connected=redis_ok
    )


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Gemini Integration Service - AI-powered business insights",
        "version": "1.0.0",
        "features": [
            "Cost Optimization Analysis",
            "Error Diagnosis & Fixes",
            "Feedback Sentiment Analysis",
            "Daily Executive Summaries",
            "Business Goals Tracking"
        ],
        "docs": "/docs"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8007)
