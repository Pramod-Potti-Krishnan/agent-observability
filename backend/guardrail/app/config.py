"""Configuration settings for Guardrail Service"""
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings"""

    # Service Info
    app_name: str = "Guardrail Service"
    debug: bool = False

    # Database
    postgres_url: str

    # Redis
    redis_url: str

    # Cache TTL
    cache_ttl_rules: int = 600  # 10 minutes

    # Detection Settings
    pii_confidence_threshold: float = 0.8
    toxicity_threshold: float = 0.7
    max_text_length: int = 100000  # Maximum text length to scan

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()
