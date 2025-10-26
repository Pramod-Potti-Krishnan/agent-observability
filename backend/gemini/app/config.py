"""Configuration settings for Gemini Integration Service"""
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings"""

    # Service Info
    app_name: str = "Gemini Integration Service"
    debug: bool = False

    # Database - PostgreSQL
    postgres_url: str

    # Database - TimescaleDB
    timescale_url: str

    # Redis
    redis_url: str

    # Gemini API
    gemini_api_key: str
    gemini_model: str = "gemini-1.5-flash"  # Using stable model compatible with google-generativeai 0.3.2

    # Cache TTL (30 minutes for insights)
    cache_ttl_insights: int = 1800  # 30 minutes in seconds

    # API Settings
    api_timeout: int = 60
    max_lookback_days: int = 30

    # Insight generation settings
    temperature: float = 0.7
    max_output_tokens: int = 2048

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()
