"""Configuration settings for Alert Service"""
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings"""

    # Service Info
    app_name: str = "Alert Service"
    debug: bool = False

    # Database
    postgres_url: str
    timescale_url: str

    # Redis
    redis_url: str

    # Cache TTL
    cache_ttl_alerts: int = 60  # 1 minute
    cache_ttl_rules: int = 300  # 5 minutes

    # Alert Settings
    alert_check_interval: int = 60  # Check alerts every 60 seconds
    default_window_minutes: int = 5
    anomaly_zscore_threshold: float = 3.0  # Standard deviations for anomaly detection

    # API Settings
    api_timeout: int = 30
    max_rules_per_workspace: int = 100
    webhook_timeout: int = 10

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()
