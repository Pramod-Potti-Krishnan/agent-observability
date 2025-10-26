"""Redis caching layer for Query Service"""
import redis
import json
import logging
from typing import Optional, Any
from functools import wraps
from .config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

# Global Redis client
redis_client = redis.from_url(settings.redis_url, decode_responses=True)


def get_cache(key: str) -> Optional[Any]:
    """Get value from cache"""
    try:
        value = redis_client.get(key)
        if value:
            logger.debug(f"Cache HIT: {key}")
            return json.loads(value)
        logger.debug(f"Cache MISS: {key}")
        return None
    except Exception as e:
        logger.error(f"Cache read error: {str(e)}")
        return None


def set_cache(key: str, value: Any, ttl: int):
    """Set value in cache with TTL"""
    try:
        redis_client.setex(key, ttl, json.dumps(value, default=str))
        logger.debug(f"Cache SET: {key} (TTL: {ttl}s)")
    except Exception as e:
        logger.error(f"Cache write error: {str(e)}")


def invalidate_cache(pattern: str):
    """Invalidate cache keys matching pattern"""
    try:
        keys = redis_client.keys(pattern)
        if keys:
            redis_client.delete(*keys)
            logger.info(f"Invalidated {len(keys)} cache keys: {pattern}")
    except Exception as e:
        logger.error(f"Cache invalidation error: {str(e)}")


def cached(ttl: int, key_prefix: str = ""):
    """
    Decorator to cache function results
    
    Args:
        ttl: Time to live in seconds
        key_prefix: Prefix for cache key
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Build cache key from function name and arguments
            cache_key = f"{key_prefix}:{func.__name__}"
            
            # Add relevant kwargs to cache key
            if 'workspace_id' in kwargs:
                cache_key += f":{kwargs['workspace_id']}"
            if 'range' in kwargs:
                cache_key += f":{kwargs['range']}"
            if 'limit' in kwargs:
                cache_key += f":{kwargs['limit']}"
            
            # Try to get from cache
            cached_value = get_cache(cache_key)
            if cached_value is not None:
                return cached_value
            
            # Execute function
            result = await func(*args, **kwargs)
            
            # Store in cache
            set_cache(cache_key, result, ttl)
            
            return result
        return wrapper
    return decorator
