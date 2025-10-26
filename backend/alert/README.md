# Alert Service

Alert and notification microservice for Agent Monitoring Platform - Port 8006

## Overview

The Alert Service monitors agent performance metrics and sends notifications when thresholds are breached or anomalies are detected. It provides real-time alerting capabilities with support for multiple notification channels.

## Features

- **Threshold-based Alerts**: Monitor metrics and trigger alerts when values breach defined thresholds
- **Anomaly Detection**: Statistical anomaly detection using Z-score analysis
- **Webhook Notifications**: Send alert notifications via HTTP webhooks
- **Alert Management**: Create, list, acknowledge, and resolve alerts
- **Multi-tenancy**: Workspace-isolated alert rules and notifications
- **Agent-specific Rules**: Create rules for specific agents or all agents in a workspace

## Architecture

### Database Connections
- **PostgreSQL**: Alert rules and notifications storage (tables: `alert_rules`, `alert_notifications`)
- **TimescaleDB**: Performance metrics for threshold checks and anomaly detection
- **Redis**: Caching (planned)

### Components

```
backend/alert/
├── app/
│   ├── config.py              # Configuration settings
│   ├── models.py              # Pydantic models
│   ├── database.py            # Database operations
│   ├── main.py               # FastAPI application
│   ├── detectors/
│   │   ├── threshold.py      # Threshold breach detection
│   │   └── anomaly.py        # Z-score anomaly detection
│   ├── notifications/
│   │   └── webhook.py        # Webhook sender
│   └── routes/
│       └── alerts.py         # API endpoints
├── tests/
├── Dockerfile
└── requirements.txt
```

## API Endpoints

### Alert Management

#### 1. GET /api/v1/alerts
List active alerts (recent notifications) for a workspace.

**Query Parameters:**
- `workspace_id` (UUID, required): Workspace ID
- `limit` (int, optional): Max results (default: 100, max: 500)
- `offset` (int, optional): Pagination offset (default: 0)

**Response:**
```json
{
  "alerts": [
    {
      "id": "uuid",
      "alert_rule_id": "uuid",
      "workspace_id": "uuid",
      "sent_at": "2025-01-15T10:30:00Z",
      "title": "Alert: High Latency",
      "message": "latency_ms value 1500.00 is greater than threshold 1000.00",
      "severity": "warning",
      "metric_value": 1500.0,
      "channels_sent": ["webhook"],
      "delivery_status": {}
    }
  ],
  "total": 42,
  "unacknowledged": 42
}
```

#### 2. GET /api/v1/alerts/{alert_id}
Get detailed information about a specific alert.

**Path Parameters:**
- `alert_id` (UUID): Alert notification ID

**Query Parameters:**
- `workspace_id` (UUID, required): Workspace ID

**Response:** Single `AlertNotificationResponse` object

#### 3. POST /api/v1/alerts/{alert_id}/acknowledge
Acknowledge an alert notification.

**Path Parameters:**
- `alert_id` (UUID): Alert notification ID

**Query Parameters:**
- `workspace_id` (UUID, required): Workspace ID

**Request Body:**
```json
{
  "acknowledged_by": "user@example.com"
}
```

**Response:**
```json
{
  "id": "uuid",
  "acknowledged": true,
  "acknowledged_at": "2025-01-15T10:35:00Z",
  "acknowledged_by": "user@example.com"
}
```

#### 4. POST /api/v1/alerts/{alert_id}/resolve
Resolve an alert notification.

**Path Parameters:**
- `alert_id` (UUID): Alert notification ID

**Query Parameters:**
- `workspace_id` (UUID, required): Workspace ID

**Request Body:**
```json
{
  "resolved_by": "user@example.com",
  "resolution_notes": "Fixed by restarting service"
}
```

**Response:**
```json
{
  "id": "uuid",
  "resolved": true,
  "resolved_at": "2025-01-15T10:40:00Z",
  "resolved_by": "user@example.com"
}
```

### Alert Rules

#### 5. POST /api/v1/alert-rules
Create a new alert rule.

**Request Body:**
```json
{
  "workspace_id": "uuid",
  "agent_id": "agent-123",
  "name": "High Latency Alert",
  "description": "Alert when latency exceeds 1 second",
  "metric": "latency_ms",
  "condition": "gt",
  "threshold": 1000.0,
  "window_minutes": 5,
  "channels": ["webhook"],
  "webhook_url": "https://hooks.example.com/alerts"
}
```

**Metric Types:**
- `latency_ms`: Average latency in milliseconds
- `error_rate`: Error rate percentage
- `cost_usd`: Total cost in USD
- `request_count`: Number of requests

**Condition Types:**
- `gt`: Greater than
- `lt`: Less than
- `gte`: Greater than or equal
- `lte`: Less than or equal
- `eq`: Equal

**Channel Types:**
- `email`: Email notifications (planned)
- `webhook`: HTTP webhook
- `slack`: Slack notifications (planned)

**Response:**
```json
{
  "id": "uuid",
  "workspace_id": "uuid",
  "agent_id": "agent-123",
  "name": "High Latency Alert",
  "description": "Alert when latency exceeds 1 second",
  "created_at": "2025-01-15T10:00:00Z",
  "updated_at": "2025-01-15T10:00:00Z",
  "metric": "latency_ms",
  "condition": "gt",
  "threshold": 1000.0,
  "window_minutes": 5,
  "channels": ["webhook"],
  "webhook_url": "https://hooks.example.com/alerts",
  "is_active": true,
  "last_triggered_at": null
}
```

#### 6. GET /api/v1/alert-rules
List all alert rules for a workspace.

**Query Parameters:**
- `workspace_id` (UUID, required): Workspace ID
- `active_only` (bool, optional): Only return active rules (default: false)

**Response:**
```json
{
  "rules": [
    {
      "id": "uuid",
      "workspace_id": "uuid",
      "agent_id": "agent-123",
      "name": "High Latency Alert",
      "metric": "latency_ms",
      "condition": "gt",
      "threshold": 1000.0,
      "window_minutes": 5,
      "channels": ["webhook"],
      "is_active": true,
      "last_triggered_at": "2025-01-15T10:30:00Z"
    }
  ],
  "total": 5
}
```

### Helper Endpoints

#### POST /api/v1/alert-rules/{rule_id}/check
Manually trigger an alert check for testing.

**Path Parameters:**
- `rule_id` (UUID): Alert rule ID

**Query Parameters:**
- `workspace_id` (UUID, required): Workspace ID

**Response:**
```json
{
  "checked": true,
  "triggered": true,
  "alert_id": "uuid",
  "message": "latency_ms value 1500.00 is greater than threshold 1000.00",
  "severity": "warning",
  "current_value": 1500.0,
  "threshold": 1000.0
}
```

### System Endpoints

#### GET /health
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "service": "alert",
  "version": "1.0.0",
  "postgres_connected": true,
  "timescale_connected": true,
  "redis_connected": true
}
```

#### GET /
Root endpoint with service information.

## Detection Algorithms

### Threshold Detection

Checks if a metric value breaches the defined threshold based on the condition type.

**Implementation** (`detectors/threshold.py`):
```python
def check_threshold_breach(metric, current_value, threshold, condition):
    # Compares current_value against threshold using condition
    # Returns ThresholdDetectionResult with breach status
```

**Conditions:**
- `gt`: current_value > threshold
- `lt`: current_value < threshold
- `gte`: current_value >= threshold
- `lte`: current_value <= threshold
- `eq`: abs(current_value - threshold) < 0.01

**Severity Calculation:**
Based on deviation percentage:
- `info`: < 10% deviation
- `warning`: 10-25% deviation
- `error`: 25-50% deviation
- `critical`: > 50% deviation

### Anomaly Detection

Uses Z-score statistical method to detect anomalies.

**Z-score Formula:**
```
z = (value - mean) / std_dev
```

**Implementation** (`detectors/anomaly.py`):
```python
def detect_anomaly_zscore(metric, current_value, mean, std_dev, threshold=3.0):
    # Calculates Z-score
    # Flags as anomaly if |z| > threshold (default: 3.0)
    # Returns AnomalyDetectionResult
```

**Anomaly Threshold:** |z-score| > 3.0 (configurable via `ANOMALY_ZSCORE_THRESHOLD`)

**Severity Levels:**
- `info`: |z| < 2.0
- `warning`: 2.0 ≤ |z| < 3.0
- `error`: 3.0 ≤ |z| < 4.0
- `critical`: |z| ≥ 4.0

## Webhook Notifications

### Payload Format

When an alert is triggered, webhooks receive:

```json
{
  "alert_id": "uuid",
  "alert_rule_id": "uuid",
  "workspace_id": "uuid",
  "timestamp": "2025-01-15T10:30:00Z",
  "title": "Alert: High Latency",
  "message": "latency_ms value 1500.00 is greater than threshold 1000.00",
  "severity": "warning",
  "metric": "latency_ms",
  "metric_value": 1500.0,
  "threshold": 1000.0,
  "condition": "gt",
  "agent_id": "agent-123"
}
```

### Implementation

**Async HTTP POST** (`notifications/webhook.py`):
- Uses `aiohttp` for non-blocking requests
- Configurable timeout (default: 10 seconds)
- Automatic retry handling (planned)
- Delivery status tracking

## Configuration

### Environment Variables

```env
# Service
APP_NAME=Alert Service
DEBUG=false

# Databases
POSTGRES_URL=postgresql://user:pass@postgres:5432/agent_monitoring
TIMESCALE_URL=postgresql://user:pass@timescale:5432/agent_monitoring_metrics
REDIS_URL=redis://redis:6379/0

# Cache TTL
CACHE_TTL_ALERTS=60
CACHE_TTL_RULES=300

# Alert Settings
ALERT_CHECK_INTERVAL=60
DEFAULT_WINDOW_MINUTES=5
ANOMALY_ZSCORE_THRESHOLD=3.0

# API Settings
API_TIMEOUT=30
MAX_RULES_PER_WORKSPACE=100
WEBHOOK_TIMEOUT=10
```

## Database Schema

### alert_rules Table
```sql
CREATE TABLE alert_rules (
    id UUID PRIMARY KEY,
    workspace_id UUID NOT NULL,
    agent_id VARCHAR(128),  -- NULL = all agents
    name VARCHAR(256) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,

    -- Alert condition
    metric VARCHAR(64) NOT NULL,
    condition VARCHAR(16) NOT NULL,
    threshold DECIMAL(10, 2) NOT NULL,
    window_minutes INTEGER DEFAULT 5,

    -- Notification channels
    channels JSONB DEFAULT '[]',
    webhook_url VARCHAR(512),

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    last_triggered_at TIMESTAMPTZ
);
```

### alert_notifications Table
```sql
CREATE TABLE alert_notifications (
    id UUID PRIMARY KEY,
    alert_rule_id UUID NOT NULL,
    workspace_id UUID NOT NULL,
    sent_at TIMESTAMPTZ NOT NULL,

    -- Alert details
    title VARCHAR(256) NOT NULL,
    message TEXT,
    severity VARCHAR(16) NOT NULL,

    -- Metric details
    metric_value DECIMAL(10, 2),

    -- Delivery status
    channels_sent JSONB,
    delivery_status JSONB
);
```

## Running the Service

### Local Development
```bash
cd backend/alert
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8006 --reload
```

### Docker
```bash
docker build -t alert-service .
docker run -p 8006:8006 \
  -e POSTGRES_URL=postgresql://... \
  -e TIMESCALE_URL=postgresql://... \
  -e REDIS_URL=redis://... \
  alert-service
```

### Access
- API Documentation: http://localhost:8006/docs
- Health Check: http://localhost:8006/health

## Testing

### Manual Testing

1. **Create an alert rule:**
```bash
curl -X POST http://localhost:8006/api/v1/alert-rules \
  -H "Content-Type: application/json" \
  -d '{
    "workspace_id": "your-workspace-uuid",
    "agent_id": "agent-123",
    "name": "Test Alert",
    "metric": "latency_ms",
    "condition": "gt",
    "threshold": 1000,
    "window_minutes": 5,
    "channels": ["webhook"],
    "webhook_url": "https://webhook.site/your-unique-url"
  }'
```

2. **List alert rules:**
```bash
curl "http://localhost:8006/api/v1/alert-rules?workspace_id=your-workspace-uuid"
```

3. **Manually check a rule:**
```bash
curl -X POST "http://localhost:8006/api/v1/alert-rules/{rule_id}/check?workspace_id=your-workspace-uuid"
```

4. **List alerts:**
```bash
curl "http://localhost:8006/api/v1/alerts?workspace_id=your-workspace-uuid"
```

## Future Enhancements

- [ ] Email notification support
- [ ] Slack notification support
- [ ] Alert rule scheduling (specific time windows)
- [ ] Alert aggregation (deduplicate similar alerts)
- [ ] Anomaly detection using IQR method
- [ ] Machine learning-based anomaly detection
- [ ] Alert escalation policies
- [ ] Alert muting/snoozing
- [ ] Alert dependencies (parent-child relationships)
- [ ] Redis caching integration
- [ ] Background scheduler for automatic alert checks
- [ ] Alert history analytics
- [ ] Custom notification templates

## Dependencies

- **FastAPI**: Web framework
- **uvicorn**: ASGI server
- **pydantic**: Data validation
- **asyncpg**: PostgreSQL async driver
- **aiohttp**: Async HTTP client for webhooks
- **redis**: Caching (planned)

## Port

The Alert Service runs on **port 8006**.

## License

Part of the Agent Monitoring Platform.
