"""Query Service - Main FastAPI Application"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
from .config import get_settings
from .database import db_manager
from .routes import home, alerts, activity, traces, usage, cost, performance, filters, analytics, quality, actions, impact

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

settings = get_settings()

# Create FastAPI app
app = FastAPI(
    title="Query Service",
    description="High-performance read API for Agent Observability Platform",
    version="1.0.0",
    debug=settings.debug
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict this
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(home.router)
app.include_router(filters.router)  # Filter options endpoints
app.include_router(analytics.router)  # Advanced analytics endpoints (Phase 4)
app.include_router(alerts.router)
app.include_router(activity.router)
app.include_router(traces.router)
app.include_router(usage.router)
app.include_router(cost.router)
app.include_router(performance.router)
app.include_router(quality.router)  # Quality monitoring endpoints
app.include_router(impact.router)  # Business impact endpoints (Tab 7)
app.include_router(actions.router)  # Admin action endpoints (Phase 1.4 & 2.3)


@app.on_event("startup")
async def startup():
    """Initialize database connections on startup"""
    logger.info("Starting Query Service...")
    try:
        await db_manager.connect_timescale()
        await db_manager.connect_postgres()
        logger.info("Database connections established")
    except Exception as e:
        logger.error(f"Failed to connect to databases: {str(e)}")
        raise


@app.on_event("shutdown")
async def shutdown():
    """Close database connections on shutdown"""
    logger.info("Shutting down Query Service...")
    await db_manager.close()
    logger.info("Database connections closed")


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "query-service",
        "version": "1.0.0"
    }


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Agent Observability Platform - Query Service",
        "version": "1.0.0",
        "docs": "/docs"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8003)
