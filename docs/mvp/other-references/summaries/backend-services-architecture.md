# Backend Services Architecture
## AI Agent Observability Platform

**Tech Stack:** Python 3.11+ | FastAPI | PostgreSQL | TimescaleDB | Redis
**Last Updated:** October 2025
**Status:** Development Specification

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Service Specifications](#service-specifications)
3. [API Gateway](#api-gateway)
4. [Authentication & Authorization](#authentication--authorization)
5. [Data Flow](#data-flow)
6. [Deployment Architecture](#deployment-architecture)

---

## Architecture Overview

### Microservices Design

The platform consists of **7 core services** following a lightweight microservices architecture:

```
┌─────────────────────────────────────────────────────────────────────┐
│                           API Gateway (FastAPI)                     │
│                    Authentication, Rate Limiting, Routing           │
└─────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
┌───────▼────────┐      ┌──────────▼────────┐      ┌──────────▼────────┐
│   Ingestion    │      │    Processing     │      │      Query        │
│    Service     │─────▶│     Service       │      │     Service       │
│                │      │                    │      │                   │
│ • REST API     │      │ • Metrics Extract  │      │ • Dashboard APIs  │
│ • OTLP         │      │ • Guardrails      │      │ • Aggregations    │
│ • Validation   │      │ • Enrichment      │      │ • Caching         │
└────────────────┘      └────────────────────┘      └───────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
┌───────▼────────┐      ┌──────────▼────────┐      ┌──────────▼────────┐
│   Evaluation   │      │    Guardrail      │      │      Alert        │
│    Service     │      │     Service       │      │     Service       │
│                │      │                    │      │                   │
│ • Gemini Judge │      │ • PII Detection   │      │ • Monitoring      │
│ • A/B Tests    │      │ • Toxicity Filter │      │ • Anomaly Detect  │
│ • Quality Eval │      │ • Prompt Inject   │      │ • Notifications   │
└────────────────┘      └────────────────────┘      └───────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      Gemini Integration Service                     │
│        Cost Insights | Error Diagnosis | Feedback Analysis          │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                           Data Layer                                │
│  TimescaleDB (Time-series) | PostgreSQL (Relational) | Redis (Cache)│
└─────────────────────────────────────────────────────────────────────┘
```

### Technology Stack

**Core Framework:**
- **FastAPI** - Modern, fast Python web framework
- **Pydantic** - Data validation and settings management
- **Python 3.11+** - Type hints, async/await support

**Databases:**
- **TimescaleDB** - Time-series metrics storage (traces, performance, cost)
- **PostgreSQL** - Relational data (users, agents, evaluations, feedback)
- **Redis** - Caching, rate limiting, real-time pub/sub

**Message Queue:**
- **Redis Streams** - Async task processing, event streaming

**Monitoring:**
- **Prometheus** - Metrics collection
- **Grafana** - Service monitoring dashboards
- **Sentry** - Error tracking

**External APIs:**
- **Google Gemini API** - AI-powered insights and evaluations
- **OpenTelemetry** - Trace ingestion standard

---

## Service Specifications

### 1. Ingestion Service

**Purpose:** Accept and validate incoming agent traces via REST API and OTLP protocol.

**Port:** `8001`

#### Tech Stack
```python
# requirements.txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
redis==5.0.1
opentelemetry-api==1.21.0
opentelemetry-sdk==1.21.0
```

#### API Endpoints

**POST `/api/v1/traces`** - Ingest agent trace (custom JSON format)

```python
# Request
{
  "trace_id": "tr_abc123",
  "agent_id": "agent_support",
  "user_id": "user_12345",
  "timestamp": "2025-10-21T14:32:00Z",
  "input": "How do I reset my password?",
  "output": "To reset your password...",
  "latency_ms": 1200,
  "cost_usd": 0.0034,
  "model": "gpt-4-turbo",
  "tokens": {
    "prompt": 234,
    "completion": 456
  },
  "metadata": {
    "session_id": "sess_xyz",
    "environment": "production"
  }
}

# Response
{
  "trace_id": "tr_abc123",
  "status": "accepted",
  "message": "Trace queued for processing"
}
```

**POST `/api/v1/traces/otlp`** - OTLP-compatible endpoint

```python
# Accepts OpenTelemetry Protocol (OTLP) format
# Content-Type: application/x-protobuf
# or Content-Type: application/json
```

**POST `/api/v1/traces/batch`** - Batch ingestion (up to 100 traces)

```python
# Request
{
  "traces": [
    { /* trace 1 */ },
    { /* trace 2 */ },
    ...
  ]
}

# Response
{
  "accepted": 95,
  "rejected": 5,
  "errors": [
    {"index": 12, "error": "Invalid agent_id"}
  ]
}
```

#### Implementation

```python
# app/main.py
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel, validator
from redis import Redis
import json
from datetime import datetime

app = FastAPI(title="Ingestion Service")
redis_client = Redis(host='redis', port=6379, db=0)

class Trace(BaseModel):
    trace_id: str
    agent_id: str
    user_id: str
    timestamp: datetime
    input: str
    output: str
    latency_ms: int
    cost_usd: float
    model: str
    tokens: dict
    metadata: dict = {}

    @validator('trace_id')
    def validate_trace_id(cls, v):
        if not v.startswith('tr_'):
            raise ValueError('trace_id must start with tr_')
        return v

@app.post("/api/v1/traces")
async def ingest_trace(trace: Trace, api_key: str = Depends(verify_api_key)):
    # Validate API key and rate limit
    workspace_id = get_workspace_from_api_key(api_key)

    if not check_rate_limit(workspace_id):
        raise HTTPException(status_code=429, detail="Rate limit exceeded")

    # Enqueue to Redis Streams for processing
    trace_data = trace.dict()
    trace_data['workspace_id'] = workspace_id
    trace_data['ingested_at'] = datetime.utcnow().isoformat()

    redis_client.xadd(
        'trace_queue',
        {'trace': json.dumps(trace_data)}
    )

    return {
        "trace_id": trace.trace_id,
        "status": "accepted",
        "message": "Trace queued for processing"
    }

def verify_api_key(api_key: str = Header(...)):
    # Verify API key in database
    # Return workspace_id if valid
    pass

def check_rate_limit(workspace_id: str) -> bool:
    # Check Redis for rate limit
    # Return True if within limits
    pass
```

---

### 2. Processing Service

**Purpose:** Extract metrics, run guardrails, enrich traces, and write to databases.

**Port:** `8002`

#### Responsibilities
1. Consume traces from Redis Streams
2. Extract metrics (usage, cost, performance, quality)
3. Run real-time guardrails (PII, toxicity, prompt injection)
4. Enrich with additional metadata
5. Write to TimescaleDB and PostgreSQL
6. Trigger alerts if thresholds exceeded

#### Implementation

```python
# app/processor.py
import asyncio
from redis import Redis
from sqlalchemy.ext.asyncio import AsyncSession
import json

redis_client = Redis(host='redis', port=6379, db=0)

class TraceProcessor:
    def __init__(self):
        self.guardrail_service = GuardrailClient()

    async def process_trace(self, trace_data: dict):
        """Process a single trace"""

        # 1. Run guardrails
        guardrail_results = await self.guardrail_service.check_all(
            text=trace_data['output'],
            agent_id=trace_data['agent_id']
        )

        # 2. Extract metrics
        metrics = self.extract_metrics(trace_data)

        # 3. Write to TimescaleDB (time-series metrics)
        await self.write_timeseries_metrics(metrics)

        # 4. Write to PostgreSQL (trace details)
        await self.write_trace_record(trace_data, guardrail_results)

        # 5. Check alert conditions
        await self.check_alerts(trace_data, metrics)

        # 6. Publish to real-time subscribers via Redis Pub/Sub
        redis_client.publish('metrics:update', json.dumps(metrics))

    def extract_metrics(self, trace_data: dict) -> dict:
        """Extract metrics from trace"""
        return {
            'workspace_id': trace_data['workspace_id'],
            'agent_id': trace_data['agent_id'],
            'timestamp': trace_data['timestamp'],
            'latency_ms': trace_data['latency_ms'],
            'cost_usd': trace_data['cost_usd'],
            'tokens_prompt': trace_data['tokens']['prompt'],
            'tokens_completion': trace_data['tokens']['completion'],
            'model': trace_data['model'],
        }

    async def write_timeseries_metrics(self, metrics: dict):
        """Write to TimescaleDB"""
        # Insert into traces table (hypertable)
        pass

    async def write_trace_record(self, trace_data: dict, guardrail_results: dict):
        """Write full trace to PostgreSQL for storage"""
        pass

    async def check_alerts(self, trace_data: dict, metrics: dict):
        """Check if any alert conditions are met"""
        # Budget exceeded?
        # Latency spike?
        # Error rate threshold?
        pass

async def main():
    processor = TraceProcessor()

    # Consume from Redis Streams
    while True:
        messages = redis_client.xread({'trace_queue': '$'}, block=1000, count=10)

        for stream_name, stream_messages in messages:
            for message_id, message_data in stream_messages:
                trace_json = message_data[b'trace'].decode('utf-8')
                trace_data = json.loads(trace_json)

                await processor.process_trace(trace_data)

                # Acknowledge message
                redis_client.xack('trace_queue', 'processor_group', message_id)

if __name__ == "__main__":
    asyncio.run(main())
```

---

### 3. Query Service

**Purpose:** Serve dashboard data, metrics, and analytics to frontend.

**Port:** `8003`

#### API Endpoints

**GET `/api/metrics/home-kpis`** - Home page KPIs

```python
@app.get("/api/metrics/home-kpis")
async def get_home_kpis(
    range: str = Query("24h"),
    workspace_id: str = Depends(get_workspace)
):
    # Query TimescaleDB for aggregated metrics
    # Calculate trends vs previous period
    return {
        "totalUsers": 12439,
        "totalUsersChange": 23,
        "totalCost": 847.23,
        "totalCostChange": 15,
        "avgLatency": 1.2,
        "avgLatencyChange": -8,
        "qualityScore": 92.4,
        "qualityScoreChange": 3
    }
```

**GET `/api/metrics/usage/timeseries`** - Usage time series

```python
@app.get("/api/metrics/usage/timeseries")
async def get_usage_timeseries(
    range: str = Query("30d"),
    workspace_id: str = Depends(get_workspace)
):
    # Query TimescaleDB with time_bucket
    query = """
        SELECT
            time_bucket('1 day', timestamp) AS day,
            COUNT(*) as requests
        FROM traces
        WHERE workspace_id = $1
            AND timestamp >= NOW() - INTERVAL $2
        GROUP BY day
        ORDER BY day
    """

    return {
        "timeseries": [
            {"timestamp": "2025-10-01T00:00:00Z", "requests": 1234},
            {"timestamp": "2025-10-02T00:00:00Z", "requests": 1456},
        ],
        "peak": 2345,
        "peakTime": "2pm EST",
        "trough": 234,
        "troughTime": "3am EST"
    }
```

**GET `/api/metrics/cost/budget`** - Cost budget overview

```python
@app.get("/api/metrics/cost/budget")
async def get_cost_budget(workspace_id: str = Depends(get_workspace)):
    # Get current month spend
    # Get budget from workspace settings
    # Calculate projection

    return {
        "currentSpend": 847.23,
        "budget": 1000.00,
        "remaining": 152.77,
        "projectedEOM": 998.45,
        "dailyAverage": 39.87,
        "trend": -8
    }
```

**GET `/api/metrics/performance/latency`** - Latency percentiles

```python
@app.get("/api/metrics/performance/latency")
async def get_latency_metrics(
    range: str = Query("1h"),
    workspace_id: str = Depends(get_workspace)
):
    # Calculate percentiles using percentile_cont
    query = """
        SELECT
            time_bucket('5 minutes', timestamp) AS bucket,
            PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY latency_ms) as p50,
            PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY latency_ms) as p90,
            PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY latency_ms) as p95,
            PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY latency_ms) as p99
        FROM traces
        WHERE workspace_id = $1
            AND timestamp >= NOW() - INTERVAL $2
        GROUP BY bucket
        ORDER BY bucket
    """

    return {
        "timeseries": [...],
        "current": {
            "p50": 0.8,
            "p90": 1.2,
            "p95": 2.1,
            "p99": 4.3
        }
    }
```

#### Caching Strategy

```python
# Use Redis for caching expensive queries
from functools import wraps
import hashlib
import json

def cache(ttl: int = 60):
    """Cache decorator with TTL in seconds"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Create cache key from function name + args
            cache_key = f"cache:{func.__name__}:{hashlib.md5(json.dumps(kwargs).encode()).hexdigest()}"

            # Check cache
            cached = redis_client.get(cache_key)
            if cached:
                return json.loads(cached)

            # Execute function
            result = await func(*args, **kwargs)

            # Store in cache
            redis_client.setex(cache_key, ttl, json.dumps(result))

            return result
        return wrapper
    return decorator

@app.get("/api/metrics/usage/timeseries")
@cache(ttl=300)  # Cache for 5 minutes
async def get_usage_timeseries(...):
    pass
```

---

### 4. Evaluation Service

**Purpose:** Run quality evaluations using Gemini as judge, A/B tests, and custom evaluators.

**Port:** `8004`

#### API Endpoints

**POST `/api/evaluations`** - Create and run evaluation

```python
@app.post("/api/evaluations")
async def create_evaluation(
    request: EvaluationRequest,
    workspace_id: str = Depends(get_workspace)
):
    """
    Run evaluation on agent using test dataset
    """

    # Create evaluation record
    evaluation = await db.evaluations.create({
        "workspace_id": workspace_id,
        "agent_id": request.agent_id,
        "dataset_id": request.dataset_id,
        "dimensions": request.dimensions,
        "status": "running"
    })

    # Run evaluation asynchronously
    background_tasks.add_task(
        run_evaluation,
        evaluation.id,
        request.agent_id,
        request.dataset_id,
        request.dimensions
    )

    return {
        "evaluation_id": evaluation.id,
        "status": "running",
        "estimated_duration": "5 minutes"
    }

async def run_evaluation(
    evaluation_id: str,
    agent_id: str,
    dataset_id: str,
    dimensions: list[str]
):
    """Run evaluation using Gemini as judge"""

    # Get test cases from dataset
    test_cases = await db.datasets.get_test_cases(dataset_id)

    results = []
    for test_case in test_cases:
        # Get agent response
        agent_response = await call_agent(agent_id, test_case.input)

        # Evaluate with Gemini
        score = await gemini_client.evaluate(
            input=test_case.input,
            output=agent_response,
            expected=test_case.expected_output,
            dimensions=dimensions
        )

        results.append({
            "test_case_id": test_case.id,
            "score": score,
            "passed": score.overall >= 80
        })

    # Update evaluation with results
    await db.evaluations.update(evaluation_id, {
        "status": "completed",
        "results": results,
        "overall_score": sum(r['score'].overall for r in results) / len(results)
    })
```

**GET `/api/evaluations/{id}`** - Get evaluation results

```python
@app.get("/api/evaluations/{evaluation_id}")
async def get_evaluation(
    evaluation_id: str,
    workspace_id: str = Depends(get_workspace)
):
    evaluation = await db.evaluations.get(evaluation_id)

    return {
        "id": evaluation.id,
        "agent_id": evaluation.agent_id,
        "status": evaluation.status,
        "overall_score": evaluation.overall_score,
        "test_cases_count": len(evaluation.results),
        "passed_count": sum(1 for r in evaluation.results if r.passed),
        "results": evaluation.results
    }
```

---

### 5. Guardrail Service

**Purpose:** Real-time safety checks (PII detection, toxicity filter, prompt injection defense).

**Port:** `8005`

#### API Endpoints

**POST `/api/guardrails/check`** - Check text against all enabled guardrails

```python
@app.post("/api/guardrails/check")
async def check_guardrails(
    request: GuardrailCheckRequest,
    workspace_id: str = Depends(get_workspace)
):
    """
    Check text against all enabled guardrails for given agent
    Returns violations and actions taken
    """

    # Get enabled guardrails for agent
    guardrails = await db.guardrails.get_enabled(
        workspace_id=workspace_id,
        agent_id=request.agent_id
    )

    violations = []

    for guardrail in guardrails:
        result = await execute_guardrail(guardrail, request.text)

        if result.violated:
            violations.append({
                "guardrail_id": guardrail.id,
                "guardrail_name": guardrail.name,
                "severity": result.severity,
                "action": guardrail.action,  # "block", "redact", "warn", "log"
                "details": result.details
            })

            # Log violation
            await db.violations.create({
                "workspace_id": workspace_id,
                "guardrail_id": guardrail.id,
                "trace_id": request.trace_id,
                "severity": result.severity,
                "action_taken": guardrail.action
            })

    return {
        "passed": len(violations) == 0,
        "violations": violations
    }

async def execute_guardrail(guardrail, text: str):
    """Execute specific guardrail check"""

    if guardrail.type == "pii_detection":
        return await detect_pii(text, guardrail.config)

    elif guardrail.type == "toxicity_filter":
        return await detect_toxicity(text, guardrail.config)

    elif guardrail.type == "prompt_injection":
        return await detect_prompt_injection(text, guardrail.config)

async def detect_pii(text: str, config: dict):
    """Detect PII using regex patterns"""
    import re

    patterns = {
        "ssn": r"\d{3}-\d{2}-\d{4}",
        "email": r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b",
        "phone": r"\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}",
        "credit_card": r"\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}"
    }

    violations = []
    for pii_type, pattern in patterns.items():
        if re.search(pattern, text):
            violations.append(pii_type)

    return {
        "violated": len(violations) > 0,
        "severity": "high" if violations else "none",
        "details": violations
    }

async def detect_toxicity(text: str, config: dict):
    """Detect toxic content using ML model or API"""
    # Could use Perspective API or local model
    pass

async def detect_prompt_injection(text: str, config: dict):
    """Detect prompt injection attempts"""
    # Pattern matching for common injection techniques
    pass
```

---

### 6. Alert Service

**Purpose:** Monitor metrics, detect anomalies, and send notifications.

**Port:** `8006`

#### Implementation

```python
# app/alert_monitor.py
import asyncio
from datetime import datetime, timedelta

class AlertMonitor:
    def __init__(self):
        self.alert_rules = []

    async def load_alert_rules(self, workspace_id: str):
        """Load alert rules from database"""
        self.alert_rules = await db.alerts.get_rules(workspace_id)

    async def check_alerts(self):
        """Continuously monitor and check alert conditions"""
        while True:
            for rule in self.alert_rules:
                if await self.should_trigger_alert(rule):
                    await self.trigger_alert(rule)

            await asyncio.sleep(60)  # Check every minute

    async def should_trigger_alert(self, rule) -> bool:
        """Check if alert condition is met"""

        if rule.type == "budget_exceeded":
            current_spend = await get_current_month_spend(rule.workspace_id)
            budget = await get_workspace_budget(rule.workspace_id)
            return current_spend > budget * rule.threshold

        elif rule.type == "latency_spike":
            current_p90 = await get_current_p90_latency(rule.workspace_id)
            baseline_p90 = await get_baseline_p90_latency(rule.workspace_id)
            return current_p90 > baseline_p90 * (1 + rule.threshold)

        elif rule.type == "error_rate_high":
            error_rate = await get_error_rate(rule.workspace_id)
            return error_rate > rule.threshold

    async def trigger_alert(self, rule):
        """Send alert via configured channels"""

        alert = await db.alerts.create({
            "workspace_id": rule.workspace_id,
            "rule_id": rule.id,
            "severity": rule.severity,
            "title": rule.title,
            "description": rule.description,
            "triggered_at": datetime.utcnow()
        })

        # Send notifications
        if "slack" in rule.channels:
            await send_slack_notification(alert)

        if "email" in rule.channels:
            await send_email_notification(alert)

        if "pagerduty" in rule.channels:
            await send_pagerduty_notification(alert)

        # Publish to real-time subscribers
        redis_client.publish('alert:new', json.dumps(alert.dict()))
```

---

### 7. Gemini Integration Service

**Purpose:** Centralized service for all Gemini API calls (insights, diagnostics, evaluations).

**Port:** `8007`

#### API Endpoints

**POST `/api/gemini/usage-insights`** - Generate usage summary

```python
@app.post("/api/gemini/usage-insights")
async def generate_usage_insights(
    request: UsageInsightsRequest,
    workspace_id: str = Depends(get_workspace)
):
    # Get usage data for date range
    usage_data = await db.get_usage_data(workspace_id, request.date_range)

    # Generate insights using Gemini
    prompt = f"""
    Analyze the following AI agent usage data and provide key insights:

    {json.dumps(usage_data, indent=2)}

    Provide:
    1. Growth trends
    2. Behavior patterns
    3. Friction points
    4. Recommendations

    Format as markdown.
    """

    response = await gemini_client.generate_content(prompt)

    return {
        "insights": response.text,
        "generated_at": datetime.utcnow().isoformat()
    }
```

**POST `/api/gemini/cost-optimization`** - Get cost-saving recommendations

```python
@app.post("/api/gemini/cost-optimization")
async def get_cost_optimization(workspace_id: str = Depends(get_workspace)):
    # Analyze cost patterns
    cost_data = await db.get_cost_data(workspace_id)
    token_usage = await db.get_token_usage(workspace_id)

    prompt = f"""
    Analyze cost patterns and provide optimization recommendations:

    Cost Data: {json.dumps(cost_data)}
    Token Usage: {json.dumps(token_usage)}

    Provide actionable recommendations with:
    - Impact level (high/medium/low)
    - Expected savings
    - Implementation steps

    Format as structured JSON.
    """

    response = await gemini_client.generate_content(prompt)

    return {
        "recommendations": json.loads(response.text)
    }
```

**POST `/api/gemini/error-diagnosis`** - Diagnose error root cause

```python
@app.post("/api/gemini/error-diagnosis")
async def diagnose_error(request: ErrorDiagnosisRequest):
    # Get error context
    error_logs = await db.get_error_logs(request.error_id)
    system_metrics = await db.get_system_metrics(request.timestamp)
    recent_changes = await db.get_recent_changes(request.timestamp)

    prompt = f"""
    Diagnose the root cause of this error:

    Error: {error_logs}
    System Metrics: {system_metrics}
    Recent Changes: {recent_changes}

    Provide:
    1. Primary cause
    2. Evidence
    3. Recommended fixes
    4. Temporary mitigation

    Format as structured markdown.
    """

    response = await gemini_client.generate_content(prompt)

    return {
        "diagnosis": response.text
    }
```

---

## API Gateway

### FastAPI Gateway with Rate Limiting

```python
# gateway/main.py
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import httpx

app = FastAPI(title="API Gateway")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "https://yourdomain.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Service registry
SERVICES = {
    "ingestion": "http://ingestion-service:8001",
    "query": "http://query-service:8003",
    "evaluation": "http://evaluation-service:8004",
    "guardrail": "http://guardrail-service:8005",
    "gemini": "http://gemini-service:8007",
}

@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    """Rate limiting middleware"""

    # Extract API key or user token
    api_key = request.headers.get("Authorization", "").replace("Bearer ", "")

    if not api_key:
        return JSONResponse(
            status_code=401,
            content={"detail": "Missing authentication"}
        )

    # Check rate limit in Redis
    workspace_id = await get_workspace_from_token(api_key)

    rate_limit_key = f"rate_limit:{workspace_id}:{request.url.path}"
    current_count = redis_client.incr(rate_limit_key)

    if current_count == 1:
        redis_client.expire(rate_limit_key, 60)  # 1 minute window

    if current_count > 1000:  # 1000 requests per minute
        return JSONResponse(
            status_code=429,
            content={"detail": "Rate limit exceeded"}
        )

    response = await call_next(request)
    return response

# Proxy to services
@app.api_route("/{service}/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_to_service(service: str, path: str, request: Request):
    """Proxy requests to appropriate microservice"""

    if service not in SERVICES:
        raise HTTPException(status_code=404, detail="Service not found")

    url = f"{SERVICES[service]}/api/{path}"

    async with httpx.AsyncClient() as client:
        response = await client.request(
            method=request.method,
            url=url,
            headers=dict(request.headers),
            content=await request.body()
        )

    return Response(
        content=response.content,
        status_code=response.status_code,
        headers=dict(response.headers)
    )
```

---

## Authentication & Authorization

### JWT-based Authentication

```python
# auth/jwt.py
from jose import JWTError, jwt
from datetime import datetime, timedelta
from passlib.context import CryptContext

SECRET_KEY = "your-secret-key"  # Store in environment variable
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})

    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None

# Login endpoint
@app.post("/api/auth/login")
async def login(credentials: LoginCredentials):
    user = await db.users.get_by_email(credentials.email)

    if not user or not pwd_context.verify(credentials.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    access_token = create_access_token(data={"user_id": user.id, "workspace_id": user.workspace_id})

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "name": user.name
        }
    }
```

---

## Data Flow

### Trace Ingestion to Dashboard

```
1. Client SDK → Ingestion Service (POST /api/v1/traces)
2. Ingestion Service → Redis Streams (async queue)
3. Processing Service → Consume from Redis Streams
4. Processing Service → Extract metrics
5. Processing Service → Run guardrails
6. Processing Service → Write to TimescaleDB + PostgreSQL
7. Processing Service → Check alert conditions
8. Alert Service → Send notifications (if triggered)
9. Frontend → Query Service (GET /api/metrics/*)
10. Query Service → TimescaleDB/PostgreSQL (with caching)
11. Query Service → Return aggregated data
12. Frontend → Render charts with Recharts
```

---

## Deployment Architecture

### Docker Compose (Development)

```yaml
# docker-compose.yml
version: '3.8'

services:
  gateway:
    build: ./gateway
    ports:
      - "8000:8000"
    environment:
      - REDIS_URL=redis://redis:6379
    depends_on:
      - redis

  ingestion:
    build: ./ingestion-service
    ports:
      - "8001:8001"
    environment:
      - REDIS_URL=redis://redis:6379
      - POSTGRES_URL=postgresql://user:pass@postgres:5432/observability
    depends_on:
      - redis
      - postgres

  processing:
    build: ./processing-service
    environment:
      - REDIS_URL=redis://redis:6379
      - TIMESCALEDB_URL=postgresql://user:pass@timescale:5432/metrics
    depends_on:
      - redis
      - timescale

  query:
    build: ./query-service
    ports:
      - "8003:8003"
    environment:
      - TIMESCALEDB_URL=postgresql://user:pass@timescale:5432/metrics
      - REDIS_URL=redis://redis:6379

  evaluation:
    build: ./evaluation-service
    ports:
      - "8004:8004"
    environment:
      - GEMINI_API_KEY=${GEMINI_API_KEY}

  guardrail:
    build: ./guardrail-service
    ports:
      - "8005:8005"

  alert:
    build: ./alert-service
    environment:
      - SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL}
      - SENDGRID_API_KEY=${SENDGRID_API_KEY}

  gemini:
    build: ./gemini-service
    ports:
      - "8007:8007"
    environment:
      - GEMINI_API_KEY=${GEMINI_API_KEY}

  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: observability
    volumes:
      - postgres_data:/var/lib/postgresql/data

  timescale:
    image: timescale/timescaledb:latest-pg15
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: metrics
    volumes:
      - timescale_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  timescale_data:
  redis_data:
```

### Kubernetes (Production)

```yaml
# k8s/ingestion-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ingestion-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ingestion
  template:
    metadata:
      labels:
        app: ingestion
    spec:
      containers:
      - name: ingestion
        image: yourregistry/ingestion-service:latest
        ports:
        - containerPort: 8001
        env:
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: redis-credentials
              key: url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8001
          initialDelaySeconds: 30
          periodSeconds: 10
```

---

## Summary

This backend architecture provides:

- **7 Microservices** - Ingestion, Processing, Query, Evaluation, Guardrail, Alert, Gemini
- **Python FastAPI** - Modern, async, high-performance
- **TimescaleDB** - Optimized for time-series metrics
- **PostgreSQL** - Relational data storage
- **Redis** - Caching, queuing, pub/sub
- **Horizontal Scalability** - Stateless services, easy to scale
- **Real-time Updates** - WebSocket support via Redis Pub/Sub
- **Rate Limiting** - Per-workspace rate limits
- **Authentication** - JWT-based auth with role-based access

**Next:** Review database-schema-design.md for detailed table schemas.
