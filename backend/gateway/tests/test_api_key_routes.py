"""Tests for API key CRUD routes"""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch, AsyncMock
from app.main import app


@pytest.fixture
def client():
    """Create test client"""
    return TestClient(app)


@pytest.fixture
def mock_jwt_token():
    """Mock JWT token for authenticated requests"""
    return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.token"


class TestAPIKeyRoutes:
    """Test API key CRUD endpoints"""

    @patch('app.auth.routes.get_db')
    @patch('app.auth.routes.decode_access_token')
    async def test_create_api_key(self, mock_decode, mock_get_db, client, mock_jwt_token):
        """Test creating a new API key"""
        # Mock authentication
        mock_decode.return_value = {
            "user_id": "user123",
            "workspace_id": "workspace123"
        }

        # Mock database
        mock_conn = AsyncMock()
        mock_get_db.return_value = mock_conn
        mock_conn.fetchval.return_value = "key123"

        # Make request
        response = client.post(
            "/api/v1/auth/api-keys",
            json={
                "name": "Test API Key",
                "description": "For testing"
            },
            headers={"Authorization": f"Bearer {mock_jwt_token}"}
        )

        # Verify response structure
        assert response.status_code in [200, 201]
        if response.status_code == 200:
            data = response.json()
            assert "api_key" in data
            assert "id" in data
            assert data["api_key"].startswith("agobs_")

    @patch('app.auth.routes.get_db')
    @patch('app.auth.routes.decode_access_token')
    async def test_list_api_keys(self, mock_decode, mock_get_db, client, mock_jwt_token):
        """Test listing user's API keys"""
        # Mock authentication
        mock_decode.return_value = {
            "user_id": "user123",
            "workspace_id": "workspace123"
        }

        # Mock database
        mock_conn = AsyncMock()
        mock_get_db.return_value = mock_conn
        mock_conn.fetch.return_value = [
            {
                "id": "key1",
                "name": "Key 1",
                "description": "First key",
                "created_at": "2024-01-01T00:00:00Z",
                "last_used_at": None
            }
        ]

        # Make request
        response = client.get(
            "/api/v1/auth/api-keys",
            headers={"Authorization": f"Bearer {mock_jwt_token}"}
        )

        # Verify response
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list) or "api_keys" in data

    @patch('app.auth.routes.get_db')
    @patch('app.auth.routes.decode_access_token')
    async def test_delete_api_key(self, mock_decode, mock_get_db, client, mock_jwt_token):
        """Test deleting an API key"""
        # Mock authentication
        mock_decode.return_value = {
            "user_id": "user123",
            "workspace_id": "workspace123"
        }

        # Mock database
        mock_conn = AsyncMock()
        mock_get_db.return_value = mock_conn
        mock_conn.fetchval.return_value = "key123"

        # Make request
        response = client.delete(
            "/api/v1/auth/api-keys/key123",
            headers={"Authorization": f"Bearer {mock_jwt_token}"}
        )

        # Verify response
        assert response.status_code in [200, 204]
