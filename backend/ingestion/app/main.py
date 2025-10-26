"""Ingestion Service - Main FastAPI Application"""
from fastapi import FastAPI
from .routes import router
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Create FastAPI app
app = FastAPI(
    title="Ingestion Service",
    description="Trace ingestion service for Agent Observability Platform",
    version="1.0.0"
)

# Include routers
app.include_router(router)


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Agent Observability Platform - Ingestion Service",
        "version": "1.0.0",
        "docs": "/docs"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
