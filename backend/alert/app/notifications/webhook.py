"""Webhook notification sender"""
import logging
import aiohttp
import asyncio
from typing import Dict, Any, Optional
from datetime import datetime
from uuid import UUID
from ..models import WebhookPayload
from ..config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


async def send_webhook_notification(
    webhook_url: str,
    payload: WebhookPayload
) -> Dict[str, Any]:
    """
    Send alert notification via webhook (async HTTP POST).

    Args:
        webhook_url: URL to send the webhook to
        payload: WebhookPayload containing alert details

    Returns:
        Dictionary with delivery status
    """
    result = {
        "success": False,
        "status_code": None,
        "error": None,
        "sent_at": datetime.utcnow().isoformat()
    }

    try:
        # Convert payload to JSON-serializable dict
        payload_dict = payload.model_dump(mode='json')

        # Create timeout for webhook request
        timeout = aiohttp.ClientTimeout(total=settings.webhook_timeout)

        async with aiohttp.ClientSession(timeout=timeout) as session:
            logger.info(f"Sending webhook notification to {webhook_url}")

            async with session.post(
                webhook_url,
                json=payload_dict,
                headers={
                    "Content-Type": "application/json",
                    "User-Agent": "Agent-Monitoring-Alert-Service/1.0"
                }
            ) as response:
                result["status_code"] = response.status
                result["success"] = 200 <= response.status < 300

                if result["success"]:
                    logger.info(f"Webhook sent successfully to {webhook_url} (status: {response.status})")
                else:
                    response_text = await response.text()
                    result["error"] = f"HTTP {response.status}: {response_text[:200]}"
                    logger.warning(f"Webhook failed with status {response.status}: {response_text[:200]}")

    except asyncio.TimeoutError:
        result["error"] = f"Webhook request timed out after {settings.webhook_timeout}s"
        logger.error(f"Webhook timeout for {webhook_url}")

    except aiohttp.ClientError as e:
        result["error"] = f"HTTP client error: {str(e)}"
        logger.error(f"Webhook client error for {webhook_url}: {e}")

    except Exception as e:
        result["error"] = f"Unexpected error: {str(e)}"
        logger.error(f"Unexpected webhook error for {webhook_url}: {e}")

    return result


async def send_multiple_webhooks(
    webhook_urls: list[str],
    payload: WebhookPayload
) -> Dict[str, Any]:
    """
    Send webhook notifications to multiple URLs concurrently.

    Args:
        webhook_urls: List of webhook URLs
        payload: WebhookPayload containing alert details

    Returns:
        Dictionary with results for each webhook
    """
    tasks = [send_webhook_notification(url, payload) for url in webhook_urls]
    results = await asyncio.gather(*tasks, return_exceptions=True)

    # Compile results
    webhook_results = {}
    for url, result in zip(webhook_urls, results):
        if isinstance(result, Exception):
            webhook_results[url] = {
                "success": False,
                "error": str(result),
                "sent_at": datetime.utcnow().isoformat()
            }
        else:
            webhook_results[url] = result

    return webhook_results


def create_webhook_payload(
    alert_id: UUID,
    alert_rule_id: UUID,
    workspace_id: UUID,
    title: str,
    message: str,
    severity: str,
    metric: str,
    metric_value: float,
    threshold: float,
    condition: str,
    agent_id: Optional[str] = None
) -> WebhookPayload:
    """
    Create a WebhookPayload object from alert details.

    Args:
        alert_id: Alert notification ID
        alert_rule_id: Alert rule ID
        workspace_id: Workspace ID
        title: Alert title
        message: Alert message
        severity: Alert severity
        metric: Metric name
        metric_value: Current metric value
        threshold: Threshold value
        condition: Condition type
        agent_id: Optional agent ID

    Returns:
        WebhookPayload object
    """
    return WebhookPayload(
        alert_id=alert_id,
        alert_rule_id=alert_rule_id,
        workspace_id=workspace_id,
        timestamp=datetime.utcnow(),
        title=title,
        message=message,
        severity=severity,
        metric=metric,
        metric_value=metric_value,
        threshold=threshold,
        condition=condition,
        agent_id=agent_id
    )


async def test_webhook_connection(webhook_url: str) -> bool:
    """
    Test if a webhook URL is reachable.

    Args:
        webhook_url: URL to test

    Returns:
        True if webhook is reachable, False otherwise
    """
    test_payload = WebhookPayload(
        alert_id=UUID('00000000-0000-0000-0000-000000000000'),
        alert_rule_id=UUID('00000000-0000-0000-0000-000000000000'),
        workspace_id=UUID('00000000-0000-0000-0000-000000000000'),
        timestamp=datetime.utcnow(),
        title="Test Alert",
        message="This is a test webhook notification",
        severity="info",
        metric="test_metric",
        metric_value=0.0,
        threshold=0.0,
        condition="eq"
    )

    result = await send_webhook_notification(webhook_url, test_payload)
    return result["success"]
