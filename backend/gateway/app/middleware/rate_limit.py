"""Rate limiting middleware using Redis"""
from fastapi import Request, HTTPException, status
from starlette.middleware.base import BaseHTTPMiddleware
import time
from ..dependencies import get_redis_client
from ..config import get_settings


settings = get_settings()


class RateLimitMiddleware(BaseHTTPMiddleware):
    """
    Rate limiting middleware using token bucket algorithm in Redis
    """

    async def dispatch(self, request: Request, call_next):
        # Skip rate limiting for health checks
        if request.url.path == "/health":
            return await call_next(request)

        # Get identifier (API key or IP address)
        identifier = self._get_identifier(request)

        # Check rate limit
        if not self._check_rate_limit(identifier):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Rate limit exceeded. Please try again later.",
                headers={"Retry-After": "60"}
            )

        response = await call_next(request)
        return response

    def _get_identifier(self, request: Request) -> str:
        """Get identifier for rate limiting (API key or IP)"""
        # Try to get API key from header
        api_key = request.headers.get("X-API-Key")
        if api_key:
            return f"api_key:{api_key[:12]}"

        # Fall back to IP address
        client_ip = request.client.host if request.client else "unknown"
        return f"ip:{client_ip}"

    def _check_rate_limit(self, identifier: str) -> bool:
        """
        Check if request is allowed under rate limit using token bucket

        Returns:
            bool: True if request is allowed, False if rate limit exceeded
        """
        redis_client = get_redis_client()
        key = f"rate_limit:{identifier}"
        now = time.time()

        # Token bucket parameters
        capacity = settings.rate_limit_requests_per_minute + settings.rate_limit_burst
        refill_rate = settings.rate_limit_requests_per_minute / 60.0  # tokens per second

        # Get current state
        bucket_data = redis_client.get(key)

        if bucket_data is None:
            # First request - initialize bucket
            tokens = capacity - 1  # Consume one token for this request
            last_refill = now
            redis_client.setex(
                key,
                120,  # TTL 2 minutes
                f"{tokens}:{last_refill}"
            )
            return True

        # Parse bucket state
        try:
            tokens_str, last_refill_str = bucket_data.split(":")
            tokens = float(tokens_str)
            last_refill = float(last_refill_str)
        except (ValueError, AttributeError):
            # Corrupted data - allow request and reset
            redis_client.setex(key, 120, f"{capacity-1}:{now}")
            return True

        # Refill tokens based on time passed
        time_passed = now - last_refill
        tokens_to_add = time_passed * refill_rate
        tokens = min(capacity, tokens + tokens_to_add)

        # Check if we have enough tokens
        if tokens >= 1.0:
            # Consume one token
            tokens -= 1.0
            redis_client.setex(key, 120, f"{tokens}:{now}")
            return True
        else:
            # Rate limit exceeded
            return False
