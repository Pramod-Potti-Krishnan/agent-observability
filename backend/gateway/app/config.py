"""Gateway Service Configuration"""
from pydantic_settings import BaseSettings
from pydantic import field_validator
from functools import lru_cache
from typing import Union


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""

    # Service
    app_name: str = "API Gateway"
    debug: bool = False

    # Database URLs
    timescale_url: str
    postgres_url: str
    redis_url: str

    # JWT Configuration
    jwt_secret: str
    jwt_algorithm: str = "HS256"
    jwt_expiration_hours: int = 24

    # API Key Configuration
    api_key_salt: str

    # Rate Limiting
    rate_limit_requests_per_minute: int = 1000
    rate_limit_burst: int = 100

    # CORS
    cors_origins: Union[list[str], str] = ["http://localhost:3000", "http://localhost:3001"]

    @field_validator('cors_origins', mode='before')
    @classmethod
    def parse_cors_origins(cls, v):
        """Parse CORS origins from comma-separated string or list"""
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(',')]
        return v

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()
