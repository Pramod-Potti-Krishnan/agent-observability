"""Guardrail Service - Main FastAPI Application"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from .config import get_settings
from .database import get_postgres_pool, close_postgres_pool
from .models import HealthResponse

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting Guardrail Service...")
    await get_postgres_pool()
    yield
    logger.info("Shutting down Guardrail Service...")
    await close_postgres_pool()


app = FastAPI(
    title="Guardrail Service",
    description="Safety and compliance checks: PII, toxicity, prompt injection",
    version="1.0.0",
    debug=settings.debug,
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import and register guardrails routes
from .routes.guardrails import router as guardrails_router
app.include_router(guardrails_router)


@app.get("/health", response_model=HealthResponse)
async def health_check():
    return HealthResponse(status="healthy", service="guardrail", version="1.0.0")


@app.get("/")
async def root():
    return {"message": "Guardrail Service", "version": "1.0.0", "docs": "/docs"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8005)
