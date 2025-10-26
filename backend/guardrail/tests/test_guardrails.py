"""Tests for guardrail service endpoints"""
import pytest
from httpx import AsyncClient
from unittest.mock import patch


@pytest.mark.asyncio
async def test_pii_detection_email(test_client):
    """Test POST /api/v1/guardrails/pii detects email addresses"""
    content = "Please contact me at john.doe@example.com for more information"

    response = await test_client.post(
        "/api/v1/guardrails/pii",
        json={"text": content},
        headers={"X-Workspace-ID": "test-workspace-id"}
    )

    assert response.status_code == 200
    data = response.json()

    # Verify PII detection
    assert "has_pii" in data
    assert data["has_pii"] == True
    assert "detections" in data
    assert len(data["detections"]) > 0

    # Verify email was detected
    detection_types = [d["pii_type"] for d in data["detections"]]
    assert "email" in detection_types

    # Verify redaction
    assert "redacted_text" in data
    assert "[REDACTED: EMAIL]" in data["redacted_text"]
    assert "john.doe@example.com" not in data["redacted_text"]


@pytest.mark.asyncio
async def test_violations_list(test_client, db_pool):
    """Test GET /api/v1/guardrails/violations returns violation history"""
    response = await test_client.get(
        "/api/v1/guardrails/violations?range=7d",
        headers={"X-Workspace-ID": "test-workspace-id"}
    )

    assert response.status_code == 200
    data = response.json()

    # Verify response structure
    assert "violations" in data
    assert isinstance(data["violations"], list)
    assert "total_count" in data

    # Verify violation data if present
    if len(data["violations"]) > 0:
        violation = data["violations"][0]
        assert "id" in violation
        assert "violation_type" in violation
        assert "severity" in violation
        assert "redacted_content" in violation


@pytest.mark.asyncio
async def test_pii_detection_multiple_types(test_client):
    """Test PII detection with multiple PII types in one text"""
    content = "Call me at 555-123-4567 or email john@test.com. My SSN is 123-45-6789"

    response = await test_client.post(
        "/api/v1/guardrails/pii",
        json={"text": content},
        headers={"X-Workspace-ID": "test-workspace-id"}
    )

    assert response.status_code == 200
    data = response.json()

    assert data["has_pii"] == True
    assert len(data["detections"]) >= 2  # At least email and phone

    detection_types = [d["pii_type"] for d in data["detections"]]
    # Should detect at least some of these
    assert any(t in detection_types for t in ["email", "phone", "ssn"])


@pytest.mark.asyncio
async def test_guardrails_check_comprehensive(test_client):
    """Test POST /api/v1/guardrails/check runs all guardrail checks"""
    content = "Contact john.doe@example.com for sensitive information"

    with patch('app.routes.guardrails.detect_toxicity') as mock_toxicity, \
         patch('app.routes.guardrails.detect_prompt_injection') as mock_injection:

        # Mock toxicity and injection detectors
        mock_toxicity.return_value = {'is_toxic': False, 'toxicity_score': 0.1}
        mock_injection.return_value = {'is_injection': False, 'confidence': 0.05}

        response = await test_client.post(
            "/api/v1/guardrails/check",
            json={"text": content},
            headers={"X-Workspace-ID": "test-workspace-id"}
        )

        assert response.status_code == 200
        data = response.json()

        # Verify comprehensive check was performed
        assert "has_violations" in data
        assert "violations" in data
        assert "redacted_text" in data

        # Verify all detection types were checked
        assert mock_toxicity.called
        assert mock_injection.called
