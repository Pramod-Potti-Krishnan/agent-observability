"""Configuration settings for Evaluation Service"""
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings"""

    # Service Info
    app_name: str = "Evaluation Service"
    debug: bool = False

    # Database
    postgres_url: str

    # Redis
    redis_url: str

    # Gemini API
    gemini_api_key: str
    gemini_model: str = "gemini-1.5-flash"  # Using stable model compatible with google-generativeai 0.3.2

    # Cache TTL
    cache_ttl_evaluations: int = 300  # 5 minutes

    # API Settings
    api_timeout: int = 30
    max_batch_size: int = 100

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()
