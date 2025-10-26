"""API Gateway - Main FastAPI Application"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .config import get_settings
from .auth.routes import router as auth_router
from .proxy.routes import router as proxy_router
from .routes.workspace import router as workspace_router
from .middleware.rate_limit import RateLimitMiddleware
from .middleware.logging import RequestLoggingMiddleware


settings = get_settings()

# Create FastAPI app
app = FastAPI(
    title=settings.app_name,
    description="API Gateway for Agent Observability Platform",
    version="1.0.0",
    debug=settings.debug
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add custom middleware
app.add_middleware(RequestLoggingMiddleware)
app.add_middleware(RateLimitMiddleware)

# Include routers
app.include_router(auth_router)
app.include_router(workspace_router)  # Phase 5: Settings APIs
app.include_router(proxy_router)


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "api-gateway",
        "version": "1.0.0"
    }


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Agent Observability Platform - API Gateway",
        "version": "1.0.0",
        "docs": "/docs"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
