# Gemini Integration Service

AI-powered business insights service for agent monitoring platform. Provides cost optimization analysis, error diagnosis, feedback sentiment analysis, and automated daily summaries using Google Gemini Pro.

## Port

**8007**

## Features

### 1. Cost Optimization Insights
- Analyzes LLM usage costs across models and agents
- Identifies top 3 cost-saving opportunities
- Provides actionable recommendations for cost reduction
- Calculates potential savings estimates

### 2. Error Diagnosis
- Analyzes error patterns across agents
- Identifies root causes of failures
- Provides prioritized fix recommendations
- Groups errors by type and severity

### 3. Feedback Analysis
- Sentiment analysis on user feedback
- Identifies key themes and trends
- Extracts actionable insights
- Sentiment scoring (-1 to 1)

### 4. Daily Summaries
- Automated executive summaries
- Highlights achievements and concerns
- Provides prioritized recommendations
- Performance metrics overview

### 5. Business Goals Tracking
- Create and track business goals
- Monitor progress towards targets
- Support for multiple goal types (tickets, CSAT, cost savings, response time)

## API Endpoints

### Insights

#### POST /api/v1/insights/cost-optimization
Generate cost optimization recommendations.

**Request:**
```json
{
  "days": 7,
  "agent_id": "optional-agent-id"
}
```

**Response:**
```json
{
  "summary": "Executive summary of cost analysis",
  "total_cost_usd": 150.50,
  "total_requests": 10000,
  "avg_cost_per_request": 0.015,
  "cost_breakdown": [...],
  "opportunities": [
    {
      "title": "Switch to cheaper model for simple tasks",
      "description": "...",
      "potential_savings_usd": 45.00,
      "impact": "high",
      "recommendation": "..."
    }
  ],
  "generated_at": "2025-10-22T10:00:00Z",
  "cached": false
}
```

#### POST /api/v1/insights/error-diagnosis
Analyze errors and suggest fixes.

**Request:**
```json
{
  "days": 7,
  "agent_id": "optional-agent-id",
  "error_threshold": 10
}
```

**Response:**
```json
{
  "summary": "Executive summary of error analysis",
  "total_errors": 250,
  "error_rate": 2.5,
  "patterns": [...],
  "suggested_fixes": [
    {
      "title": "Implement retry logic for API timeouts",
      "description": "...",
      "root_cause": "...",
      "fix_steps": ["Step 1", "Step 2", "Step 3"],
      "impact": "high",
      "priority": 1
    }
  ],
  "generated_at": "2025-10-22T10:00:00Z",
  "cached": false
}
```

#### POST /api/v1/insights/feedback-analysis
Analyze user feedback sentiment.

**Request:**
```json
{
  "days": 7,
  "agent_id": "optional-agent-id"
}
```

**Response:**
```json
{
  "summary": "Executive summary of feedback",
  "overall_sentiment_score": 0.75,
  "sentiment_label": "positive",
  "total_feedback_items": 150,
  "key_themes": [...],
  "actionable_insights": [...],
  "generated_at": "2025-10-22T10:00:00Z",
  "cached": false
}
```

#### GET /api/v1/insights/daily-summary
Get automated daily summary.

**Query Parameters:**
- `date` (optional): Date in YYYY-MM-DD format (defaults to yesterday)
- `agent_id` (optional): Filter by agent

**Response:**
```json
{
  "executive_summary": "...",
  "date": "2025-10-21",
  "total_requests": 5000,
  "success_rate": 97.5,
  "avg_latency_ms": 250.5,
  "total_cost_usd": 75.25,
  "highlights": [...],
  "concerns": [...],
  "recommendations": [...],
  "generated_at": "2025-10-22T10:00:00Z",
  "cached": false
}
```

### Business Goals

#### GET /api/v1/business-goals
List business goals.

**Query Parameters:**
- `active_only` (optional): Filter to active goals only (default: false)

**Response:**
```json
{
  "goals": [
    {
      "id": "uuid",
      "workspace_id": "uuid",
      "name": "Reduce support tickets by 30%",
      "description": "...",
      "metric": "support_tickets",
      "target_value": 1000,
      "current_value": 850,
      "unit": "tickets",
      "target_date": "2025-12-31",
      "is_active": true,
      "created_at": "2025-01-01T00:00:00Z",
      "updated_at": "2025-10-22T10:00:00Z",
      "progress_percentage": 85.0
    }
  ],
  "total": 5,
  "active": 3
}
```

#### POST /api/v1/business-goals
Create a business goal.

**Request:**
```json
{
  "name": "Reduce support tickets by 30%",
  "description": "Reduce customer support tickets through improved agent responses",
  "metric": "support_tickets",
  "target_value": 1000,
  "current_value": 1430,
  "unit": "tickets",
  "target_date": "2025-12-31"
}
```

**Supported Metrics:**
- `support_tickets` - Number of support tickets
- `csat_score` - Customer satisfaction score
- `cost_savings` - Cost savings in USD
- `response_time` - Response time in milliseconds

## Architecture

### Components

1. **config.py** - Configuration settings (database URLs, API keys, cache TTL)
2. **models.py** - Pydantic models for request/response validation
3. **database.py** - Database connection pools and data aggregation queries
4. **gemini_client.py** - Google Gemini API client for insight generation
5. **prompts.py** - Prompt templates for each insight type
6. **routes/insights.py** - FastAPI endpoints for insights and business goals
7. **main.py** - FastAPI application with CORS and lifecycle management

### Data Sources

- **PostgreSQL**: Business goals, feedback data
- **TimescaleDB**: Time-series metrics (traces_daily, traces_hourly)
- **Redis**: Insight caching (30-minute TTL)

### Caching Strategy

All insights are cached in Redis with a 30-minute TTL to:
- Reduce Gemini API costs
- Improve response times
- Handle high request volumes

Cache keys format:
- Cost optimization: `cost_opt:{workspace_id}:{days}:{agent_id}`
- Error diagnosis: `error_diag:{workspace_id}:{days}:{agent_id}`
- Feedback analysis: `feedback_analysis:{workspace_id}:{days}:{agent_id}`
- Daily summary: `daily_summary:{workspace_id}:{date}:{agent_id}`

## Environment Variables

Required environment variables (set in `.env`):

```bash
# Database - PostgreSQL
POSTGRES_URL=postgresql://user:pass@postgres:5432/agent_monitoring

# Database - TimescaleDB
TIMESCALE_URL=postgresql://user:pass@timescaledb:5432/agent_metrics

# Redis
REDIS_URL=redis://redis:6379/0

# Gemini API
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-1.5-pro

# Cache settings
CACHE_TTL_INSIGHTS=1800  # 30 minutes

# Optional
DEBUG=false
TEMPERATURE=0.7
MAX_OUTPUT_TOKENS=2048
```

## Authentication

All endpoints require the `X-Workspace-ID` header:

```bash
curl -H "X-Workspace-ID: your-workspace-uuid" \
     http://localhost:8007/api/v1/insights/cost-optimization \
     -d '{"days": 7}'
```

## Running Locally

### Using Docker

```bash
docker build -t gemini-service .
docker run -p 8007:8007 --env-file .env gemini-service
```

### Using Python

```bash
# Install dependencies
pip install -r requirements.txt

# Run service
uvicorn app.main:app --host 0.0.0.0 --port 8007 --reload
```

## Health Check

```bash
curl http://localhost:8007/health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "gemini",
  "version": "1.0.0",
  "gemini_configured": true,
  "databases_connected": true,
  "redis_connected": true
}
```

## API Documentation

Interactive API documentation available at:
- Swagger UI: http://localhost:8007/docs
- ReDoc: http://localhost:8007/redoc

## Gemini Prompt Engineering

### Cost Optimization Prompt
- Analyzes cost breakdown by model and agent
- Identifies top 3 opportunities ranked by potential savings
- Considers: model selection, prompt optimization, caching, batching

### Error Diagnosis Prompt
- Categorizes errors by type (API, timeout, validation, model)
- Provides root cause analysis
- Generates prioritized fix steps
- Ranks fixes by impact (high/medium/low)

### Feedback Analysis Prompt
- Performs sentiment analysis on ratings and comments
- Calculates sentiment score (-1 to 1)
- Identifies 3-5 key themes with examples
- Provides actionable insights with specific actions

### Daily Summary Prompt
- Creates executive summary suitable for leadership
- Highlights positive trends and achievements
- Identifies concerns needing attention
- Provides prioritized recommendations

## Performance

- **Response Time**: 2-5 seconds (uncached), <100ms (cached)
- **Cache Hit Rate**: ~80% for repeated queries
- **Gemini API**: Uses temperature=0.7 for balanced creativity/consistency
- **Token Usage**: ~1000-2000 tokens per insight

## Error Handling

All endpoints return proper HTTP status codes:
- `200 OK` - Success
- `400 Bad Request` - Invalid request parameters
- `404 Not Found` - No data found for time period
- `500 Internal Server Error` - Service error

## Logging

Structured logging with timestamps:
```
2025-10-22 10:00:00 - gemini - INFO - Fetching cost data for workspace abc123 (days: 7)
2025-10-22 10:00:01 - gemini - INFO - Calling Gemini API for insight generation
2025-10-22 10:00:03 - gemini - INFO - Successfully generated insight with Gemini
2025-10-22 10:00:03 - gemini - INFO - Cache set for key: cost_opt:abc123:7:all
```

## Development

### Adding New Insight Types

1. Add Pydantic models to `models.py`
2. Create prompt template in `prompts.py`
3. Add Gemini client function in `gemini_client.py`
4. Add database query in `database.py`
5. Create endpoint in `routes/insights.py`

### Testing

```bash
# Unit tests (to be implemented)
pytest tests/

# Manual testing
curl -X POST http://localhost:8007/api/v1/insights/cost-optimization \
  -H "Content-Type: application/json" \
  -H "X-Workspace-ID: test-workspace-id" \
  -d '{"days": 7}'
```

## Dependencies

- **FastAPI** - Web framework
- **Uvicorn** - ASGI server
- **Pydantic** - Data validation
- **asyncpg** - PostgreSQL/TimescaleDB async driver
- **redis** - Redis async client
- **google-generativeai** - Gemini API client

## License

Part of the Agent Monitoring Platform - Phase 4 AI Integration
