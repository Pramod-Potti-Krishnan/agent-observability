"""Authentication routes"""
from fastapi import APIRouter, Depends, HTTPException, status, Header
from typing import Optional
import asyncpg
import re
from uuid import UUID, uuid4
from datetime import datetime, timezone

from .models import UserCreate, UserLogin, Token, TokenData, User, APIKeyCreate, APIKey
from .jwt import (
    hash_password,
    verify_password,
    create_access_token,
    decode_access_token,
    generate_api_key,
    verify_api_key
)
from ..config import get_settings
from ..dependencies import get_postgres_connection

router = APIRouter(prefix="/api/v1/auth", tags=["authentication"])
settings = get_settings()


def generate_slug(name: str) -> str:
    """Generate a URL-friendly slug from a name"""
    slug = name.lower()
    slug = re.sub(r'[^\w\s-]', '', slug)
    slug = re.sub(r'[-\s]+', '-', slug)
    slug = slug.strip('-')
    # Add random suffix to ensure uniqueness
    import secrets
    suffix = secrets.token_hex(4)
    return f"{slug}-{suffix}"


@router.post("/register", response_model=User, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserCreate,
    conn: asyncpg.Connection = Depends(get_postgres_connection)
):
    """Register a new user and workspace"""
    # Check if user already exists
    existing = await conn.fetchrow(
        "SELECT id FROM users WHERE email = $1",
        user_data.email
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    # Create workspace first
    workspace_id = uuid4()
    workspace_slug = generate_slug(user_data.workspace_name)
    await conn.execute(
        """
        INSERT INTO workspaces (id, name, slug, created_at)
        VALUES ($1, $2, $3, $4)
        """,
        workspace_id,
        user_data.workspace_name,
        workspace_slug,
        datetime.now(timezone.utc)
    )

    # Create user
    user_id = uuid4()
    hashed_password = hash_password(user_data.password)

    await conn.execute(
        """
        INSERT INTO users (id, email, password_hash, full_name, created_at)
        VALUES ($1, $2, $3, $4, $5)
        """,
        user_id,
        user_data.email,
        hashed_password,
        user_data.full_name,
        datetime.now(timezone.utc)
    )

    # Add user to workspace as owner
    await conn.execute(
        """
        INSERT INTO workspace_members (workspace_id, user_id, role)
        VALUES ($1, $2, $3)
        """,
        workspace_id,
        user_id,
        'owner'
    )

    # Fetch and return user with workspace
    user_row = await conn.fetchrow(
        """
        SELECT u.id, u.email, u.full_name, wm.workspace_id, u.created_at, u.is_active
        FROM users u
        JOIN workspace_members wm ON u.id = wm.user_id
        WHERE u.id = $1
        LIMIT 1
        """,
        user_id
    )

    return User(**dict(user_row))


@router.post("/login", response_model=Token)
async def login(
    credentials: UserLogin,
    conn: asyncpg.Connection = Depends(get_postgres_connection)
):
    """Login and receive JWT token"""
    # Fetch user with workspace
    user = await conn.fetchrow(
        """
        SELECT u.id, wm.workspace_id, u.email, u.password_hash, u.is_active
        FROM users u
        JOIN workspace_members wm ON u.id = wm.user_id
        WHERE u.email = $1
        LIMIT 1
        """,
        credentials.email
    )

    if not user or not verify_password(credentials.password, user['password_hash']):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user['is_active']:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is deactivated"
        )

    # Create access token
    token_data = {
        "user_id": str(user['id']),
        "workspace_id": str(user['workspace_id']),
        "email": user['email']
    }
    access_token = create_access_token(token_data)

    return Token(
        access_token=access_token,
        expires_in=settings.jwt_expiration_hours * 3600
    )


@router.get("/me", response_model=User)
async def get_current_user(
    authorization: str = Header(...),
    conn: asyncpg.Connection = Depends(get_postgres_connection)
):
    """Get current authenticated user"""
    # Extract token from Authorization header
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header"
        )

    token = authorization.split(" ")[1]
    payload = decode_access_token(token)

    # Fetch user from database with workspace
    user = await conn.fetchrow(
        """
        SELECT u.id, u.email, u.full_name, wm.workspace_id, u.created_at, u.is_active
        FROM users u
        JOIN workspace_members wm ON u.id = wm.user_id
        WHERE u.id = $1
        LIMIT 1
        """,
        UUID(payload['user_id'])
    )

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return User(**dict(user))


@router.post("/api-keys", response_model=dict, status_code=status.HTTP_201_CREATED)
async def create_api_key(
    key_data: APIKeyCreate,
    authorization: str = Header(...),
    conn: asyncpg.Connection = Depends(get_postgres_connection)
):
    """Create a new API key"""
    # Get current user
    token = authorization.split(" ")[1]
    payload = decode_access_token(token)

    # Generate API key
    api_key, hashed_key = generate_api_key()
    key_id = uuid4()
    key_prefix = api_key[:12]  # Store first 12 chars as prefix

    # Store in database
    await conn.execute(
        """
        INSERT INTO api_keys (id, workspace_id, name, description, key_hash, key_prefix, created_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        """,
        key_id,
        UUID(payload['workspace_id']),
        key_data.name,
        key_data.description,
        hashed_key,
        key_prefix,
        datetime.now(timezone.utc)
    )

    # Return the full key (only shown once!)
    return {
        "id": key_id,
        "api_key": api_key,
        "message": "Save this API key - it won't be shown again!"
    }


@router.get("/api-keys", response_model=list[APIKey])
async def list_api_keys(
    authorization: str = Header(...),
    conn: asyncpg.Connection = Depends(get_postgres_connection)
):
    """List all API keys for current workspace"""
    token = authorization.split(" ")[1]
    payload = decode_access_token(token)

    keys = await conn.fetch(
        """
        SELECT id, workspace_id, name, key_prefix, created_at, last_used, is_active
        FROM api_keys
        WHERE workspace_id = $1 AND is_active = true
        ORDER BY created_at DESC
        """,
        UUID(payload['workspace_id'])
    )

    return [APIKey(**dict(key)) for key in keys]


@router.delete("/api-keys/{key_id}", status_code=status.HTTP_204_NO_CONTENT)
async def revoke_api_key(
    key_id: UUID,
    authorization: str = Header(...),
    conn: asyncpg.Connection = Depends(get_postgres_connection)
):
    """Revoke an API key"""
    token = authorization.split(" ")[1]
    payload = decode_access_token(token)

    # Update key to inactive
    result = await conn.execute(
        """
        UPDATE api_keys
        SET is_active = false
        WHERE id = $1 AND workspace_id = $2
        """,
        key_id,
        UUID(payload['workspace_id'])
    )

    if result == "UPDATE 0":
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="API key not found"
        )

    return None
