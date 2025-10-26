"""Tests for caching functionality"""
import pytest
from app.cache import get_cache, set_cache, invalidate_cache
import json


def test_cache_set_and_get():
    """Test basic cache set and get operations"""
    key = "test:key:1"
    value = {"data": "test_value", "count": 123}
    ttl = 60
    
    # Set cache
    set_cache(key, value, ttl)
    
    # Get cache
    cached_value = get_cache(key)
    
    assert cached_value is not None
    assert cached_value["data"] == "test_value"
    assert cached_value["count"] == 123
    
    # Clean up
    invalidate_cache("test:*")


def test_cache_get_nonexistent():
    """Test getting a non-existent cache key"""
    cached_value = get_cache("nonexistent:key")
    assert cached_value is None


def test_cache_invalidation():
    """Test cache invalidation with pattern matching"""
    # Set multiple cache keys
    set_cache("workspace:123:kpis", {"value": 100}, 60)
    set_cache("workspace:123:alerts", {"value": 200}, 60)
    set_cache("workspace:456:kpis", {"value": 300}, 60)
    
    # Verify they exist
    assert get_cache("workspace:123:kpis") is not None
    assert get_cache("workspace:123:alerts") is not None
    assert get_cache("workspace:456:kpis") is not None
    
    # Invalidate workspace 123
    invalidate_cache("workspace:123:*")
    
    # Verify workspace 123 keys are gone
    assert get_cache("workspace:123:kpis") is None
    assert get_cache("workspace:123:alerts") is None
    
    # Verify workspace 456 keys still exist
    assert get_cache("workspace:456:kpis") is not None
    
    # Clean up
    invalidate_cache("workspace:*")
