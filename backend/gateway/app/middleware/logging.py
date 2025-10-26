"""Request logging middleware"""
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
import time
import logging


# Configure logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """
    Middleware to log all HTTP requests and responses
    """

    async def dispatch(self, request: Request, call_next):
        # Start timer
        start_time = time.time()

        # Log request
        logger.info(
            f"Incoming: {request.method} {request.url.path} "
            f"from {request.client.host if request.client else 'unknown'}"
        )

        # Process request
        response = await call_next(request)

        # Calculate duration
        duration_ms = (time.time() - start_time) * 1000

        # Log response
        logger.info(
            f"Completed: {request.method} {request.url.path} "
            f"status={response.status_code} duration={duration_ms:.2f}ms"
        )

        # Add custom headers
        response.headers["X-Process-Time"] = f"{duration_ms:.2f}ms"

        return response
