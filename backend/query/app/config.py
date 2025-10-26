"""Query Service Configuration"""
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""

    # Service
    app_name: str = "Query Service"
    debug: bool = False

    # Database URLs
    timescale_url: str
    postgres_url: str
    redis_url: str

    # Cache settings
    cache_ttl_home_kpis: int = 300  # 5 minutes
    cache_ttl_alerts: int = 60  # 1 minute
    cache_ttl_activity: int = 30  # 30 seconds
    cache_ttl_traces: int = 120  # 2 minutes

    # Query limits
    max_page_size: int = 100
    default_page_size: int = 20

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()
