"""Tests for alert service endpoints"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_list_alerts(test_client, db_pool):
    """Test GET /api/v1/alerts returns active alerts"""
    response = await test_client.get(
        "/api/v1/alerts?status=open",
        headers={"X-Workspace-ID": "test-workspace-id"}
    )

    assert response.status_code == 200
    data = response.json()

    # Verify response structure
    assert "alerts" in data
    assert isinstance(data["alerts"], list)
    assert "total" in data

    # Verify alert data if present
    if len(data["alerts"]) > 0:
        alert = data["alerts"][0]
        assert "id" in alert
        assert "severity" in alert
        assert "status" in alert
        assert "message" in alert


@pytest.mark.asyncio
async def test_threshold_detection():
    """Test threshold detector identifies values exceeding limits"""
    from app.detectors.threshold import ThresholdDetector

    detector = ThresholdDetector(
        metric="latency_p99",
        threshold=2000,
        condition="greater_than"
    )

    # Test value exceeding threshold
    assert detector.check(2500) == True  # Triggers alert
    assert detector.check(1500) == False  # Below threshold


@pytest.mark.asyncio
async def test_acknowledge_alert(test_client, db_pool):
    """Test POST /api/v1/alerts/{id}/acknowledge updates alert status"""
    alert_id = "alert-1"

    response = await test_client.post(
        f"/api/v1/alerts/{alert_id}/acknowledge",
        json={"acknowledged_by": "test-user"},
        headers={"X-Workspace-ID": "test-workspace-id"}
    )

    assert response.status_code == 200
    data = response.json()

    assert "message" in data or "status" in data


@pytest.mark.asyncio
async def test_list_alert_rules(test_client, db_pool):
    """Test GET /api/v1/alert-rules returns configured rules"""
    response = await test_client.get(
        "/api/v1/alert-rules",
        headers={"X-Workspace-ID": "test-workspace-id"}
    )

    assert response.status_code == 200
    data = response.json()

    # Verify response structure
    assert "rules" in data
    assert isinstance(data["rules"], list)

    # Verify rule data if present
    if len(data["rules"]) > 0:
        rule = data["rules"][0]
        assert "id" in rule
        assert "rule_name" in rule
        assert "metric" in rule
        assert "threshold" in rule
        assert "condition" in rule
