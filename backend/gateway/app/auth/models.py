"""Authentication data models"""
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional
from uuid import UUID


class UserCreate(BaseModel):
    """User registration model"""
    email: EmailStr
    password: str = Field(..., min_length=8)
    full_name: str
    workspace_name: str


class UserLogin(BaseModel):
    """User login model"""
    email: EmailStr
    password: str


class Token(BaseModel):
    """JWT token response"""
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class TokenData(BaseModel):
    """JWT token payload data"""
    user_id: str
    workspace_id: str
    email: str


class User(BaseModel):
    """User model"""
    id: UUID
    email: str
    full_name: str
    workspace_id: UUID
    created_at: datetime
    is_active: bool = True


class APIKeyCreate(BaseModel):
    """API key creation model"""
    name: str
    description: Optional[str] = None


class APIKey(BaseModel):
    """API key model"""
    id: UUID
    workspace_id: UUID
    name: str
    key_prefix: str
    created_at: datetime
    last_used: Optional[datetime] = None
    is_active: bool = True
