"""Tests for authentication module"""
import pytest
from app.auth.jwt import (
    hash_password,
    verify_password,
    create_access_token,
    decode_access_token,
    generate_api_key,
    verify_api_key
)


class TestPasswordHashing:
    """Test password hashing functions"""

    def test_hash_password(self):
        """Test password hashing"""
        password = "test_password_123"
        hashed = hash_password(password)

        assert hashed != password
        assert len(hashed) > 0
        assert hashed.startswith("$2b$")  # bcrypt format

    def test_verify_password_correct(self):
        """Test password verification with correct password"""
        password = "test_password_123"
        hashed = hash_password(password)

        assert verify_password(password, hashed) is True

    def test_verify_password_incorrect(self):
        """Test password verification with incorrect password"""
        password = "test_password_123"
        hashed = hash_password(password)

        assert verify_password("wrong_password", hashed) is False


class TestJWT:
    """Test JWT token functions"""

    def test_create_access_token(self):
        """Test JWT token creation"""
        data = {
            "user_id": "123",
            "workspace_id": "456",
            "email": "test@example.com"
        }
        token = create_access_token(data)

        assert isinstance(token, str)
        assert len(token) > 0
        assert "." in token  # JWT has dots

    def test_decode_access_token(self):
        """Test JWT token decoding"""
        data = {
            "user_id": "123",
            "workspace_id": "456",
            "email": "test@example.com"
        }
        token = create_access_token(data)
        decoded = decode_access_token(token)

        assert decoded["user_id"] == "123"
        assert decoded["workspace_id"] == "456"
        assert decoded["email"] == "test@example.com"
        assert "exp" in decoded
        assert "iat" in decoded

    def test_decode_invalid_token(self):
        """Test decoding invalid token raises error"""
        from fastapi import HTTPException

        with pytest.raises(HTTPException) as exc_info:
            decode_access_token("invalid.token.here")

        assert exc_info.value.status_code == 401


class TestAPIKeys:
    """Test API key generation and verification"""

    def test_generate_api_key(self):
        """Test API key generation"""
        api_key, hashed_key = generate_api_key()

        assert api_key.startswith("agobs_")
        assert len(api_key) > 40
        assert len(hashed_key) > 0
        assert api_key != hashed_key

    def test_verify_api_key_correct(self):
        """Test API key verification with correct key"""
        api_key, hashed_key = generate_api_key()

        assert verify_api_key(api_key, hashed_key) is True

    def test_verify_api_key_incorrect(self):
        """Test API key verification with incorrect key"""
        _, hashed_key = generate_api_key()
        wrong_key, _ = generate_api_key()

        assert verify_api_key(wrong_key, hashed_key) is False
