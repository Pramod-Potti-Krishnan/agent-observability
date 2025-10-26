"""Alert API routes"""
import logging
from fastapi import APIRouter, HTTPException, Query, Header
from typing import Optional, List
from uuid import UUID
from datetime import datetime

from ..models import (
    CreateAlertRuleRequest,
    AlertRuleResponse,
    AlertRulesListResponse,
    AlertNotificationResponse,
    AlertsListResponse,
    AcknowledgeAlertRequest,
    AcknowledgeAlertResponse,
    ResolveAlertRequest,
    ResolveAlertResponse
)
from ..database import (
    get_postgres_pool,
    get_timescale_pool,
    create_alert_rule,
    get_alert_rule,
    list_alert_rules,
    get_alert_notification,
    list_active_alerts,
    count_active_alerts,
    get_current_metric_value,
    update_alert_rule_trigger_time,
    create_alert_notification
)
from ..detectors.threshold import check_threshold_breach, calculate_severity
from ..notifications.webhook import create_webhook_payload, send_webhook_notification

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1", tags=["alerts"])


# Endpoint 1: GET /api/v1/alerts - List active alerts
@router.get("/alerts", response_model=AlertsListResponse)
async def list_alerts(
    workspace_id: UUID = Query(..., description="Workspace ID"),
    limit: int = Query(100, ge=1, le=500, description="Max number of results"),
    offset: int = Query(0, ge=0, description="Offset for pagination")
):
    """
    List active alerts (recent alert notifications) for a workspace.

    Returns alerts ordered by sent_at timestamp descending (most recent first).
    """
    try:
        pool = await get_postgres_pool()

        # Get alerts and total count
        alerts_data = await list_active_alerts(pool, workspace_id, limit, offset)
        total = await count_active_alerts(pool, workspace_id)

        # Convert to response models
        alerts = [
            AlertNotificationResponse(
                id=alert['id'],
                alert_rule_id=alert['alert_rule_id'],
                workspace_id=alert['workspace_id'],
                sent_at=alert['sent_at'],
                title=alert['title'],
                message=alert['message'],
                severity=alert['severity'],
                metric_value=alert['metric_value'],
                channels_sent=alert['channels_sent'],
                delivery_status=alert['delivery_status']
            )
            for alert in alerts_data
        ]

        # Count unacknowledged (for now, same as total since we don't have acknowledged field in alert_notifications)
        unacknowledged = total

        return AlertsListResponse(
            alerts=alerts,
            total=total,
            unacknowledged=unacknowledged
        )

    except Exception as e:
        logger.error(f"Error listing alerts: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to list alerts: {str(e)}")


# Endpoint 1b: GET /api/v1/alerts/recent - List recent alerts with workspace from header
@router.get("/alerts/recent", response_model=AlertsListResponse)
async def get_recent_alerts(
    x_workspace_id: UUID = Header(..., alias="X-Workspace-ID"),
    limit: int = Query(10, ge=1, le=100, description="Max number of results")
):
    """
    Get recent alerts for workspace from header.

    This is a convenience endpoint that extracts workspace_id from headers
    and returns the most recent alerts without requiring query parameters.
    """
    return await list_alerts(workspace_id=x_workspace_id, limit=limit, offset=0)


# Endpoint 2: GET /api/v1/alerts/:id - Get alert details
@router.get("/alerts/{alert_id}", response_model=AlertNotificationResponse)
async def get_alert_details(
    alert_id: UUID,
    workspace_id: UUID = Query(..., description="Workspace ID")
):
    """
    Get detailed information about a specific alert notification.
    """
    try:
        pool = await get_postgres_pool()

        alert_data = await get_alert_notification(pool, alert_id)

        if not alert_data:
            raise HTTPException(status_code=404, detail="Alert not found")

        # Verify workspace access
        if str(alert_data['workspace_id']) != str(workspace_id):
            raise HTTPException(status_code=403, detail="Access denied to this alert")

        return AlertNotificationResponse(
            id=alert_data['id'],
            alert_rule_id=alert_data['alert_rule_id'],
            workspace_id=alert_data['workspace_id'],
            sent_at=alert_data['sent_at'],
            title=alert_data['title'],
            message=alert_data['message'],
            severity=alert_data['severity'],
            metric_value=alert_data['metric_value'],
            channels_sent=alert_data['channels_sent'],
            delivery_status=alert_data['delivery_status']
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting alert details: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get alert: {str(e)}")


# Endpoint 3: POST /api/v1/alerts/:id/acknowledge - Acknowledge alert
@router.post("/alerts/{alert_id}/acknowledge", response_model=AcknowledgeAlertResponse)
async def acknowledge_alert(
    alert_id: UUID,
    request: AcknowledgeAlertRequest,
    workspace_id: UUID = Query(..., description="Workspace ID")
):
    """
    Acknowledge an alert notification.

    Note: The alert_notifications table doesn't have acknowledged fields by default.
    This endpoint is a placeholder for future functionality. For now, it returns
    a success response.
    """
    try:
        pool = await get_postgres_pool()

        # Verify alert exists and belongs to workspace
        alert_data = await get_alert_notification(pool, alert_id)

        if not alert_data:
            raise HTTPException(status_code=404, detail="Alert not found")

        if str(alert_data['workspace_id']) != str(workspace_id):
            raise HTTPException(status_code=403, detail="Access denied to this alert")

        # TODO: Update alert_notifications table to add acknowledged, acknowledged_at, acknowledged_by fields
        # For now, just return success
        logger.info(f"Alert {alert_id} acknowledged by {request.acknowledged_by}")

        return AcknowledgeAlertResponse(
            id=alert_id,
            acknowledged=True,
            acknowledged_at=datetime.utcnow(),
            acknowledged_by=request.acknowledged_by
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error acknowledging alert: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to acknowledge alert: {str(e)}")


# Endpoint 4: POST /api/v1/alerts/:id/resolve - Resolve alert
@router.post("/alerts/{alert_id}/resolve", response_model=ResolveAlertResponse)
async def resolve_alert(
    alert_id: UUID,
    request: ResolveAlertRequest,
    workspace_id: UUID = Query(..., description="Workspace ID")
):
    """
    Resolve an alert notification.

    Note: The alert_notifications table doesn't have resolved fields by default.
    This endpoint is a placeholder for future functionality. For now, it returns
    a success response.
    """
    try:
        pool = await get_postgres_pool()

        # Verify alert exists and belongs to workspace
        alert_data = await get_alert_notification(pool, alert_id)

        if not alert_data:
            raise HTTPException(status_code=404, detail="Alert not found")

        if str(alert_data['workspace_id']) != str(workspace_id):
            raise HTTPException(status_code=403, detail="Access denied to this alert")

        # TODO: Update alert_notifications table to add resolved, resolved_at, resolved_by, resolution_notes fields
        # For now, just return success
        logger.info(f"Alert {alert_id} resolved by {request.resolved_by}: {request.resolution_notes}")

        return ResolveAlertResponse(
            id=alert_id,
            resolved=True,
            resolved_at=datetime.utcnow(),
            resolved_by=request.resolved_by
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error resolving alert: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to resolve alert: {str(e)}")


# Endpoint 5: POST /api/v1/alert-rules - Create alert rule
@router.post("/alert-rules", response_model=AlertRuleResponse, status_code=201)
async def create_alert_rule_endpoint(request: CreateAlertRuleRequest):
    """
    Create a new alert rule.

    The rule will monitor the specified metric and send notifications when
    the threshold is breached.
    """
    try:
        pool = await get_postgres_pool()

        # Check if workspace has too many rules
        existing_rules = await list_alert_rules(pool, request.workspace_id)
        if len(existing_rules) >= 100:  # Max rules per workspace
            raise HTTPException(
                status_code=400,
                detail="Maximum number of alert rules reached for this workspace"
            )

        # Create the rule
        rule_data = await create_alert_rule(
            pool=pool,
            workspace_id=request.workspace_id,
            agent_id=request.agent_id,
            name=request.name,
            description=request.description,
            metric=request.metric.value,
            condition=request.condition.value,
            threshold=request.threshold,
            window_minutes=request.window_minutes,
            channels=[ch.value for ch in request.channels],
            webhook_url=request.webhook_url
        )

        logger.info(f"Created alert rule {rule_data['id']} for workspace {request.workspace_id}")

        return AlertRuleResponse(
            id=rule_data['id'],
            workspace_id=rule_data['workspace_id'],
            agent_id=rule_data['agent_id'],
            name=rule_data['name'],
            description=rule_data['description'],
            created_at=rule_data['created_at'],
            updated_at=rule_data['updated_at'],
            metric=rule_data['metric'],
            condition=rule_data['condition'],
            threshold=rule_data['threshold'],
            window_minutes=rule_data['window_minutes'],
            channels=rule_data['channels'],
            webhook_url=rule_data['webhook_url'],
            is_active=rule_data['is_active'],
            last_triggered_at=rule_data['last_triggered_at']
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating alert rule: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to create alert rule: {str(e)}")


# Endpoint 6: GET /api/v1/alert-rules - List all alert rules
@router.get("/alert-rules", response_model=AlertRulesListResponse)
async def list_alert_rules_endpoint(
    workspace_id: UUID = Query(..., description="Workspace ID"),
    active_only: bool = Query(False, description="Only return active rules")
):
    """
    List all alert rules for a workspace.

    Returns both active and inactive rules by default. Use active_only=true
    to filter for only active rules.
    """
    try:
        pool = await get_postgres_pool()

        rules_data = await list_alert_rules(pool, workspace_id, active_only)

        rules = [
            AlertRuleResponse(
                id=rule['id'],
                workspace_id=rule['workspace_id'],
                agent_id=rule['agent_id'],
                name=rule['name'],
                description=rule['description'],
                created_at=rule['created_at'],
                updated_at=rule['updated_at'],
                metric=rule['metric'],
                condition=rule['condition'],
                threshold=rule['threshold'],
                window_minutes=rule['window_minutes'],
                channels=rule['channels'],
                webhook_url=rule['webhook_url'],
                is_active=rule['is_active'],
                last_triggered_at=rule['last_triggered_at']
            )
            for rule in rules_data
        ]

        return AlertRulesListResponse(
            rules=rules,
            total=len(rules)
        )

    except Exception as e:
        logger.error(f"Error listing alert rules: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to list alert rules: {str(e)}")


# Helper endpoint to manually trigger alert check (for testing)
@router.post("/alert-rules/{rule_id}/check")
async def check_alert_rule(
    rule_id: UUID,
    workspace_id: UUID = Query(..., description="Workspace ID")
):
    """
    Manually trigger an alert check for a specific rule.

    This endpoint is useful for testing alert rules. In production, alerts
    are checked automatically by a background scheduler.
    """
    try:
        postgres_pool = await get_postgres_pool()
        timescale_pool = await get_timescale_pool()

        # Get the rule
        rule = await get_alert_rule(postgres_pool, rule_id)

        if not rule:
            raise HTTPException(status_code=404, detail="Alert rule not found")

        if str(rule['workspace_id']) != str(workspace_id):
            raise HTTPException(status_code=403, detail="Access denied to this rule")

        if not rule['is_active']:
            raise HTTPException(status_code=400, detail="Alert rule is not active")

        # Get current metric value
        current_value = await get_current_metric_value(
            timescale_pool,
            UUID(rule['workspace_id']),
            rule['agent_id'],
            rule['metric'],
            rule['window_minutes']
        )

        if current_value is None:
            return {
                "checked": True,
                "triggered": False,
                "message": "No data available for this metric"
            }

        # Check threshold
        detection_result = check_threshold_breach(
            rule['metric'],
            current_value,
            float(rule['threshold']),
            rule['condition']
        )

        if detection_result.breached:
            # Calculate severity
            severity = calculate_severity(
                rule['metric'],
                current_value,
                float(rule['threshold']),
                rule['condition']
            )

            # Create alert notification
            title = f"Alert: {rule['name']}"
            message = detection_result.message

            alert_data = await create_alert_notification(
                postgres_pool,
                UUID(rule['id']),
                UUID(rule['workspace_id']),
                title,
                message,
                severity,
                current_value,
                rule['channels'],
                {}
            )

            # Send webhook if configured
            if 'webhook' in rule['channels'] and rule['webhook_url']:
                webhook_payload = create_webhook_payload(
                    alert_id=UUID(alert_data['id']),
                    alert_rule_id=UUID(rule['id']),
                    workspace_id=UUID(rule['workspace_id']),
                    title=title,
                    message=message,
                    severity=severity,
                    metric=rule['metric'],
                    metric_value=current_value,
                    threshold=float(rule['threshold']),
                    condition=rule['condition'],
                    agent_id=rule['agent_id']
                )

                webhook_result = await send_webhook_notification(
                    rule['webhook_url'],
                    webhook_payload
                )

                logger.info(f"Webhook sent for alert {alert_data['id']}: {webhook_result}")

            # Update last triggered time
            await update_alert_rule_trigger_time(postgres_pool, rule_id)

            return {
                "checked": True,
                "triggered": True,
                "alert_id": str(alert_data['id']),
                "message": message,
                "severity": severity,
                "current_value": current_value,
                "threshold": float(rule['threshold'])
            }
        else:
            return {
                "checked": True,
                "triggered": False,
                "message": detection_result.message,
                "current_value": current_value,
                "threshold": float(rule['threshold'])
            }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error checking alert rule: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to check alert rule: {str(e)}")
