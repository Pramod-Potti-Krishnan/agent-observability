"""JWT token utilities"""
from datetime import datetime, timedelta, timezone
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import HTTPException, status
from ..config import get_settings
import secrets
import hashlib


settings = get_settings()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """Hash a password using bcrypt"""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against a hash"""
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: dict) -> str:
    """Create a JWT access token"""
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(hours=settings.jwt_expiration_hours)
    to_encode.update({"exp": expire, "iat": datetime.now(timezone.utc)})

    encoded_jwt = jwt.encode(
        to_encode,
        settings.jwt_secret,
        algorithm=settings.jwt_algorithm
    )
    return encoded_jwt


def decode_access_token(token: str) -> dict:
    """Decode and validate a JWT token"""
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm]
        )
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )


def generate_api_key() -> tuple[str, str]:
    """
    Generate an API key

    Returns:
        tuple: (api_key, hashed_key)
        - api_key: The full key to show to user (once)
        - hashed_key: The hashed version to store in database
    """
    # Generate random key
    api_key = f"agobs_{secrets.token_urlsafe(32)}"

    # Hash the key for storage
    hash_obj = hashlib.pbkdf2_hmac(
        'sha256',
        api_key.encode('utf-8'),
        settings.api_key_salt.encode('utf-8'),
        100000
    )
    hashed_key = hash_obj.hex()

    return api_key, hashed_key


def verify_api_key(api_key: str, hashed_key: str) -> bool:
    """Verify an API key against its hash"""
    hash_obj = hashlib.pbkdf2_hmac(
        'sha256',
        api_key.encode('utf-8'),
        settings.api_key_salt.encode('utf-8'),
        100000
    )
    computed_hash = hash_obj.hex()
    return secrets.compare_digest(computed_hash, hashed_key)
