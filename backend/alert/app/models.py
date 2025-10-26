"""Pydantic models for Alert Service"""
from pydantic import BaseModel, Field, validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from uuid import UUID
from enum import Enum


class MetricType(str, Enum):
    """Supported metric types"""
    LATENCY_MS = "latency_ms"
    ERROR_RATE = "error_rate"
    COST_USD = "cost_usd"
    REQUEST_COUNT = "request_count"


class ConditionType(str, Enum):
    """Supported condition types"""
    GT = "gt"  # greater than
    LT = "lt"  # less than
    GTE = "gte"  # greater than or equal
    LTE = "lte"  # less than or equal
    EQ = "eq"  # equal


class SeverityType(str, Enum):
    """Alert severity levels"""
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


class ChannelType(str, Enum):
    """Notification channel types"""
    EMAIL = "email"
    WEBHOOK = "webhook"
    SLACK = "slack"


class CreateAlertRuleRequest(BaseModel):
    """Request to create an alert rule"""
    workspace_id: UUID = Field(..., description="Workspace ID")
    agent_id: Optional[str] = Field(None, description="Agent ID (null for all agents)")
    name: str = Field(..., min_length=1, max_length=256, description="Rule name")
    description: Optional[str] = Field(None, description="Rule description")

    # Alert condition
    metric: MetricType = Field(..., description="Metric to monitor")
    condition: ConditionType = Field(..., description="Condition type")
    threshold: float = Field(..., description="Threshold value")
    window_minutes: int = Field(5, ge=1, le=1440, description="Time window in minutes")

    # Notification channels
    channels: List[ChannelType] = Field(default_factory=list, description="Notification channels")
    webhook_url: Optional[str] = Field(None, max_length=512, description="Webhook URL")

    @validator('channels')
    def validate_channels(cls, v, values):
        """Validate webhook URL if webhook channel is selected"""
        if ChannelType.WEBHOOK in v and not values.get('webhook_url'):
            raise ValueError("webhook_url is required when webhook channel is selected")
        return v


class UpdateAlertRuleRequest(BaseModel):
    """Request to update an alert rule"""
    name: Optional[str] = Field(None, min_length=1, max_length=256)
    description: Optional[str] = None
    metric: Optional[MetricType] = None
    condition: Optional[ConditionType] = None
    threshold: Optional[float] = None
    window_minutes: Optional[int] = Field(None, ge=1, le=1440)
    channels: Optional[List[ChannelType]] = None
    webhook_url: Optional[str] = Field(None, max_length=512)
    is_active: Optional[bool] = None


class AlertRuleResponse(BaseModel):
    """Alert rule response"""
    id: UUID
    workspace_id: UUID
    agent_id: Optional[str]
    name: str
    description: Optional[str]
    created_at: datetime
    updated_at: datetime

    metric: str
    condition: str
    threshold: float
    window_minutes: int

    channels: List[str]
    webhook_url: Optional[str]

    is_active: bool
    last_triggered_at: Optional[datetime]


class AlertRulesListResponse(BaseModel):
    """List of alert rules"""
    rules: List[AlertRuleResponse]
    total: int


class AlertNotificationResponse(BaseModel):
    """Alert notification response"""
    id: UUID
    alert_rule_id: UUID
    workspace_id: UUID
    sent_at: datetime

    title: str
    message: Optional[str]
    severity: str

    metric_value: Optional[float]

    channels_sent: Optional[List[str]]
    delivery_status: Optional[Dict[str, Any]]


class AlertsListResponse(BaseModel):
    """List of active alerts"""
    alerts: List[AlertNotificationResponse]
    total: int
    unacknowledged: int


class AcknowledgeAlertRequest(BaseModel):
    """Request to acknowledge an alert"""
    acknowledged_by: str = Field(..., min_length=1, max_length=128, description="User who acknowledged")


class AcknowledgeAlertResponse(BaseModel):
    """Response after acknowledging an alert"""
    id: UUID
    acknowledged: bool
    acknowledged_at: datetime
    acknowledged_by: str


class ResolveAlertRequest(BaseModel):
    """Request to resolve an alert"""
    resolved_by: str = Field(..., min_length=1, max_length=128, description="User who resolved")
    resolution_notes: Optional[str] = Field(None, description="Resolution notes")


class ResolveAlertResponse(BaseModel):
    """Response after resolving an alert"""
    id: UUID
    resolved: bool
    resolved_at: datetime
    resolved_by: str


class ThresholdDetectionResult(BaseModel):
    """Result of threshold detection"""
    breached: bool
    metric: str
    current_value: float
    threshold: float
    condition: str
    message: str


class AnomalyDetectionResult(BaseModel):
    """Result of anomaly detection"""
    is_anomaly: bool
    metric: str
    current_value: float
    mean: float
    std_dev: float
    z_score: float
    message: str


class WebhookPayload(BaseModel):
    """Webhook notification payload"""
    alert_id: UUID
    alert_rule_id: UUID
    workspace_id: UUID
    timestamp: datetime

    title: str
    message: str
    severity: str

    metric: str
    metric_value: float
    threshold: float
    condition: str

    agent_id: Optional[str]


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    service: str
    version: str
    postgres_connected: bool
    timescale_connected: bool
    redis_connected: bool
