"""Evaluation Service - Main FastAPI Application"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from .config import get_settings
from .routes.evaluate import router as evaluate_router
from .database import get_postgres_pool, close_postgres_pool
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
    logger.info("Starting Evaluation Service...")

    # Initialize database pool
    try:
        pool = await get_postgres_pool()
        logger.info("PostgreSQL connection pool initialized")
    except Exception as e:
        logger.error(f"Failed to initialize database pool: {e}")
        raise

    # Check Gemini configuration
    if is_gemini_configured():
        logger.info(f"Gemini API configured with model: {settings.gemini_model}")
    else:
        logger.warning("Gemini API not configured - evaluations will fail")

    yield

    # Shutdown
    logger.info("Shutting down Evaluation Service...")
    await close_postgres_pool()


# Create FastAPI app
app = FastAPI(
    title="Evaluation Service",
    description="AI-powered quality evaluation service using Gemini LLM-as-a-judge",
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
app.include_router(evaluate_router)


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    return HealthResponse(
        status="healthy",
        service="evaluation",
        version="1.0.0",
        gemini_configured=is_gemini_configured()
    )


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Evaluation Service - LLM-as-a-judge powered by Gemini",
        "version": "1.0.0",
        "docs": "/docs"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8004)
