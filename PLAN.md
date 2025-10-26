# Agent Observability Platform - Development Plan
## Complete 6-Phase Implementation Roadmap

**Last Updated:** October 21, 2025
**Status:** Phase 0 Complete ✅ | Phase 1 Next
**Total Timeline:** 20 weeks
**Total Tests:** 133 tests across all phases

---

## Table of Contents

1. [Phase 0: Foundation (COMPLETE)](#phase-0-foundation--complete)
2. [Phase 1: Core Backend Services](#phase-1-core-backend-services-weeks-3-5)
3. [Phase 2: Query Service + Home Dashboard](#phase-2-query-service--home-dashboard-weeks-6-8)
4. [Phase 3: Core Analytics Pages](#phase-3-core-analytics-pages-weeks-9-11)
5. [Phase 4: Advanced Features + AI](#phase-4-advanced-features--ai-weeks-12-14)
6. [Phase 5: Settings + SDKs](#phase-5-settings--sdks-weeks-15-16)
7. [Phase 6: Production Ready](#phase-6-production-ready-weeks-17-20)
8. [Testing Strategy](#testing-strategy)
9. [Success Metrics](#success-metrics)

---

## Phase 0: Foundation ✅ (COMPLETE)

### Delivered
- ✅ Docker Compose infrastructure (TimescaleDB, PostgreSQL, Redis)
- ✅ Database schemas with hypertables, retention policies, compression
- ✅ Synthetic data generator (10,000 traces, 100 events, 50 violations)
- ✅ Next.js 14 frontend with App Router
- ✅ shadcn/ui component library setup
- ✅ 8 dashboard pages (skeleton/placeholder UIs)
- ✅ Sidebar navigation with route structure
- ✅ Setup scripts (setup.sh, start.sh, stop.sh, status.sh)
- ✅ 8 passing tests (database connections, schema validation, data generation)

### Current State
```bash
# Services Running
✅ TimescaleDB - Port 5432 (10,000 traces loaded)
✅ PostgreSQL - Port 5433 (relational metadata)
✅ Redis - Port 6379 (ready for queues)
✅ Frontend - Port 3000 (placeholder UI)

# Test Results
✅ 8/8 tests passing
```

### What Works Now
- Docker containers start successfully
- Databases accept connections and queries
- Synthetic data loads without errors
- Frontend renders with navigation
- All shadcn/ui components styled correctly

### Foundation for Next Phases
- **Backend:** Services will connect to existing databases
- **Frontend:** Pages will consume real API data
- **Testing:** Existing test framework extends for integration tests
- **Data:** Synthetic data provides realistic test scenarios

---

## Phase 1: Core Backend Services (Weeks 3-5)

### Overview
Build the foundational backend services that enable trace ingestion, processing, and basic querying.

### Deliverables

#### 1.1 API Gateway Service
**Port:** 8000
**Purpose:** Authentication, rate limiting, request routing

**Tech Stack:**
```python
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
python-jose[cryptography]==3.3.0  # JWT
passlib[bcrypt]==1.7.4            # Password hashing
redis==5.0.1                      # Rate limiting
```

**Features:**
- JWT-based authentication
- API key management
- Rate limiting (per-workspace, per-API-key)
- Request/response logging
- CORS configuration
- Health check endpoints

**API Endpoints:**
```
POST   /api/v1/auth/login          # JWT login
POST   /api/v1/auth/register       # User registration
POST   /api/v1/auth/refresh        # Token refresh
GET    /api/v1/auth/me             # Current user info
POST   /api/v1/api-keys            # Create API key
GET    /api/v1/api-keys            # List API keys
DELETE /api/v1/api-keys/:id        # Revoke API key
GET    /health                     # Health check
```

**File Structure:**
```
backend/gateway/
├── app/
│   ├── __init__.py
│   ├── main.py                    # FastAPI app
│   ├── config.py                  # Settings (from .env)
│   ├── auth/
│   │   ├── __init__.py
│   │   ├── jwt.py                 # JWT utilities
│   │   ├── models.py              # Auth models
│   │   └── routes.py              # Auth endpoints
│   ├── middleware/
│   │   ├── __init__.py
│   │   ├── rate_limit.py          # Redis-based rate limiting
│   │   └── logging.py             # Request logging
│   └── dependencies.py            # Shared dependencies
├── tests/
│   ├── test_auth.py               # 8 tests
│   ├── test_rate_limit.py         # 4 tests
│   └── test_api_keys.py           # 3 tests
├── Dockerfile
├── requirements.txt
└── .env.example
```

**Tests Required:** 15 tests
- 8 auth tests (login, register, JWT validation)
- 4 rate limiting tests
- 3 API key management tests

#### 1.2 Ingestion Service
**Port:** 8001
**Purpose:** Accept and validate incoming agent traces

**Tech Stack:**
```python
fastapi==0.104.1
redis==5.0.1                      # Streams for async processing
opentelemetry-api==1.21.0         # OTLP support
opentelemetry-sdk==1.21.0
```

**Features:**
- REST API for trace ingestion
- OTLP-compatible endpoint
- Batch ingestion (up to 100 traces)
- Input validation with Pydantic
- Async publishing to Redis Streams
- Error handling and retry logic

**API Endpoints:**
```
POST /api/v1/traces              # Single trace ingestion
POST /api/v1/traces/batch        # Batch ingestion (max 100)
POST /api/v1/traces/otlp         # OTLP protocol endpoint
GET  /health                     # Health check
```

**Trace Schema:**
```python
class TraceInput(BaseModel):
    trace_id: str
    agent_id: str
    workspace_id: UUID
    timestamp: datetime
    input: str
    output: str
    latency_ms: int
    status: Literal['success', 'error', 'timeout']
    model: str
    model_provider: str
    tokens_input: Optional[int]
    tokens_output: Optional[int]
    tokens_total: Optional[int]
    cost_usd: Optional[float]
    metadata: dict = {}
    tags: list[str] = []
```

**File Structure:**
```
backend/ingestion/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── models.py                  # Pydantic models
│   ├── routes.py                  # API endpoints
│   ├── publisher.py               # Redis Streams publisher
│   └── validation.py              # Input validation
├── tests/
│   ├── test_ingestion.py          # 6 tests
│   ├── test_validation.py         # 4 tests
│   └── test_batch.py              # 3 tests
├── Dockerfile
└── requirements.txt
```

**Tests Required:** 13 tests
- 6 single trace ingestion tests
- 4 validation tests (invalid inputs)
- 3 batch ingestion tests

#### 1.3 Processing Service
**Port:** 8002
**Purpose:** Consume traces from Redis Streams, process, and write to TimescaleDB

**Tech Stack:**
```python
asyncpg==0.29.0                   # TimescaleDB async driver
redis==5.0.1                      # Stream consumer
```

**Features:**
- Redis Streams consumer (consumer groups)
- Metric extraction and aggregation
- Data enrichment
- Batch writing to TimescaleDB (1000 records at a time)
- Error handling and dead letter queue
- Monitoring and metrics

**Processing Pipeline:**
```
1. Consume from Redis Stream (traces:pending)
2. Extract metrics (latency, cost, tokens)
3. Enrich with workspace/agent metadata
4. Validate schema
5. Batch insert into TimescaleDB (traces table)
6. Acknowledge message
7. On error → Move to dead letter queue
```

**File Structure:**
```
backend/processing/
├── app/
│   ├── __init__.py
│   ├── main.py                    # Consumer loop
│   ├── consumer.py                # Redis Streams consumer
│   ├── processor.py               # Trace processing logic
│   ├── writer.py                  # TimescaleDB writer
│   └── metrics.py                 # Metric extraction
├── tests/
│   ├── test_consumer.py           # 3 tests
│   ├── test_processor.py          # 4 tests
│   └── test_writer.py             # 3 tests
├── Dockerfile
└── requirements.txt
```

**Tests Required:** 10 tests
- 3 consumer tests (group management, acknowledgment)
- 4 processing tests (metric extraction, enrichment)
- 3 writer tests (batch insert, error handling)

### Integration Tests
**File:** `backend/tests/integration/test_phase1_e2e.py`

**Scenarios:**
1. **Happy Path:** Ingest trace → Process → Query from DB
2. **Batch Ingestion:** 100 traces → All processed → All in DB
3. **Error Handling:** Invalid trace → Rejected → Not in DB
4. **Rate Limiting:** Exceed limit → 429 response
5. **Authentication:** No token → 401 response

**Tests Required:** 5 integration tests

### Total Tests for Phase 1
- **Gateway:** 15 tests
- **Ingestion:** 13 tests
- **Processing:** 10 tests
- **Integration:** 5 tests
- **Total:** **43 tests** (revised from 30)

### Acceptance Criteria
✅ All 3 services start successfully via Docker Compose
✅ Can authenticate and receive JWT token
✅ Can ingest trace via API with valid token
✅ Trace appears in TimescaleDB within 5 seconds
✅ Can query trace from TimescaleDB using trace_id
✅ Rate limiting blocks excessive requests
✅ All 43 tests passing

### Synthetic Data Usage
- Use existing 10,000 traces as baseline
- Generate 1,000 new traces via SDK/API
- Verify all appear in TimescaleDB
- Test with various error conditions

### Docker Compose Updates
```yaml
# Add to docker-compose.yml

  gateway:
    build: ./backend/gateway
    ports:
      - "8000:8000"
    environment:
      - TIMESCALE_URL=${TIMESCALE_URL}
      - POSTGRES_URL=${POSTGRES_URL}
      - REDIS_URL=${REDIS_URL}
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - timescaledb
      - postgres
      - redis

  ingestion:
    build: ./backend/ingestion
    ports:
      - "8001:8001"
    environment:
      - REDIS_URL=${REDIS_URL}
    depends_on:
      - redis

  processing:
    build: ./backend/processing
    ports:
      - "8002:8002"
    environment:
      - TIMESCALE_URL=${TIMESCALE_URL}
      - REDIS_URL=${REDIS_URL}
    depends_on:
      - timescaledb
      - redis
```

---

## Phase 2: Query Service + Home Dashboard (Weeks 6-8)

### Overview
Build the Query Service to aggregate metrics and connect the Home dashboard to real data.

### Deliverables

#### 2.1 Query Service
**Port:** 8003
**Purpose:** Provide aggregated metrics and dashboard data with caching

**Features:**
- Dashboard KPI endpoints
- Time-range filtering (24h, 7d, 30d, custom)
- Redis caching (5-minute TTL)
- Aggregation queries using TimescaleDB continuous aggregates
- Pagination for large datasets
- Real-time metrics via Redis Pub/Sub

**API Endpoints:**
```
# Home Page APIs
GET /api/v1/metrics/home-kpis?range=24h
GET /api/v1/alerts/recent?limit=10
GET /api/v1/activity/stream?limit=50

# Generic Query APIs
GET /api/v1/traces?workspace_id=X&range=24h&limit=100
GET /api/v1/traces/:trace_id
GET /api/v1/metrics/aggregations?type=hourly&range=7d
```

**File Structure:**
```
backend/query/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── routes/
│   │   ├── home.py                # Home KPIs
│   │   ├── traces.py              # Trace queries
│   │   └── metrics.py             # Aggregations
│   ├── cache.py                   # Redis caching layer
│   ├── queries.py                 # SQL query builders
│   └── models.py                  # Response models
├── tests/
│   ├── test_home_kpis.py          # 5 tests
│   ├── test_traces.py             # 7 tests
│   └── test_cache.py              # 3 tests
└── requirements.txt
```

**Tests Required:** 15 tests

#### 2.2 Home Dashboard (Real Data)
**Route:** `/dashboard`
**File:** `frontend/app/dashboard/page.tsx`

**Components to Build:**

**2.2.1 KPI Cards (using shadcn/ui Card)**
```tsx
// components/dashboard/KPICard.tsx
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { TrendingUp, TrendingDown } from 'lucide-react'

interface KPICardProps {
  title: string
  value: string
  change: number
  changeLabel: string
  trend?: 'normal' | 'inverse'  // inverse for latency (lower is better)
}

export function KPICard({ title, value, change, changeLabel, trend }: KPICardProps) {
  const isPositive = trend === 'inverse' ? change < 0 : change > 0

  return (
    <Card className="hover:shadow-lg transition-shadow cursor-pointer">
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          {title}
        </CardTitle>
        <Badge variant={isPositive ? "default" : "secondary"}>
          {isPositive ? <TrendingUp className="h-3 w-3" /> : <TrendingDown className="h-3 w-3" />}
        </Badge>
      </CardHeader>
      <CardContent>
        <div className="text-3xl font-bold">{value}</div>
        <p className="text-xs text-muted-foreground mt-1">
          <span className={isPositive ? 'text-green-600' : 'text-red-600'}>
            {change > 0 ? '+' : ''}{change}%
          </span>
          {' '}{changeLabel}
        </p>
      </CardContent>
    </Card>
  )
}
```

**shadcn/ui Components Used:**
- `Card`, `CardContent`, `CardHeader`, `CardTitle` - Layout structure
- `Badge` - Trend indicators
- Icons from `lucide-react`

**2.2.2 Alerts Feed (using shadcn/ui Alert)**
```tsx
// components/dashboard/AlertsFeed.tsx
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { Button } from '@/components/ui/button'
import { ScrollArea } from '@/components/ui/scroll-area'
import { AlertCircle, AlertTriangle, Info } from 'lucide-react'

export function AlertsFeed() {
  const { data: alerts } = useQuery({
    queryKey: ['alerts'],
    queryFn: () => apiClient.get('/api/v1/alerts/recent')
  })

  return (
    <Card>
      <CardHeader>
        <CardTitle>Recent Alerts</CardTitle>
      </CardHeader>
      <CardContent>
        <ScrollArea className="h-[400px]">
          {alerts?.map(alert => (
            <Alert key={alert.id} variant={alert.severity === 'critical' ? 'destructive' : 'default'}>
              {alert.severity === 'critical' && <AlertCircle className="h-4 w-4" />}
              {alert.severity === 'warning' && <AlertTriangle className="h-4 w-4" />}
              {alert.severity === 'info' && <Info className="h-4 w-4" />}
              <AlertTitle>{alert.title}</AlertTitle>
              <AlertDescription>{alert.description}</AlertDescription>
            </Alert>
          ))}
        </ScrollArea>
      </CardContent>
    </Card>
  )
}
```

**shadcn/ui Components Used:**
- `Alert`, `AlertDescription`, `AlertTitle` - Alert display
- `ScrollArea` - Scrollable list
- `Card` - Container

**2.2.3 Activity Stream (using shadcn/ui Table)**
```tsx
// components/dashboard/ActivityStream.tsx
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'

export function ActivityStream() {
  const { data: activities } = useQuery({
    queryKey: ['activity'],
    queryFn: () => apiClient.get('/api/v1/activity/stream')
  })

  return (
    <Card>
      <CardHeader>
        <CardTitle>Recent Activity</CardTitle>
      </CardHeader>
      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Time</TableHead>
              <TableHead>Agent</TableHead>
              <TableHead>Action</TableHead>
              <TableHead>Status</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {activities?.map(activity => (
              <TableRow key={activity.id}>
                <TableCell>{formatTime(activity.timestamp)}</TableCell>
                <TableCell>{activity.agent_id}</TableCell>
                <TableCell>{activity.action}</TableCell>
                <TableCell>
                  <Badge variant={activity.status === 'success' ? 'default' : 'destructive'}>
                    {activity.status}
                  </Badge>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  )
}
```

**shadcn/ui Components Used:**
- `Table`, `TableBody`, `TableCell`, `TableHead`, `TableHeader`, `TableRow` - Data display
- `Badge` - Status indicators

**2.2.4 Time Range Selector (using shadcn/ui Select)**
```tsx
// components/dashboard/TimeRangeSelector.tsx
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'

export function TimeRangeSelector({ value, onChange }) {
  return (
    <Select value={value} onValueChange={onChange}>
      <SelectTrigger className="w-[180px]">
        <SelectValue placeholder="Select range" />
      </SelectTrigger>
      <SelectContent>
        <SelectItem value="1h">Last Hour</SelectItem>
        <SelectItem value="24h">Last 24 Hours</SelectItem>
        <SelectItem value="7d">Last 7 Days</SelectItem>
        <SelectItem value="30d">Last 30 Days</SelectItem>
        <SelectItem value="custom">Custom Range</SelectItem>
      </SelectContent>
    </Select>
  )
}
```

**shadcn/ui Components Used:**
- `Select`, `SelectContent`, `SelectItem`, `SelectTrigger`, `SelectValue` - Dropdown

### Tests Required
- **Backend:** 15 query service tests
- **Frontend:** 6 component tests (KPI cards, alerts, activity)
- **Total:** **21 tests**

### Acceptance Criteria
✅ Query service returns real data from TimescaleDB
✅ Home dashboard displays live KPIs
✅ Alerts feed shows recent events
✅ Activity stream updates in real-time
✅ Time range selector filters data correctly
✅ All data cached in Redis (5-min TTL)
✅ All 21 tests passing

### Synthetic Data Usage
- Dashboard shows metrics from 10,000 existing traces
- Generate additional events/alerts for testing
- Verify real-time updates work

---

## Phase 3: Core Analytics Pages (Weeks 9-11)

### Overview
Build the three core analytics pages with full Recharts visualizations.

### Deliverables

#### 3.1 Usage Analytics Page
**Route:** `/dashboard/usage`
**File:** `frontend/app/dashboard/usage/page.tsx`

**Sections:**
1. **Overview KPIs** (Cards)
   - Total API Calls
   - Unique Users
   - Active Agents
   - Avg Calls/User

2. **API Calls Over Time** (Line Chart)
   - X-axis: Time (hourly/daily/weekly buckets)
   - Y-axis: Number of calls
   - Multiple lines for different agents

3. **Agent Distribution** (Pie Chart)
   - Show % of calls per agent
   - Interactive legend

4. **Top Users Table** (Table)
   - User ID
   - Total Calls
   - Last Active
   - Trend

**shadcn/ui Components:**
- `Card` - KPI containers
- `Tabs` - Time range switching (Hourly/Daily/Weekly)
- `Table` - Top users
- `Select` - Agent filter

**Recharts Components:**
```tsx
import { LineChart, Line, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'

// Line chart for API calls over time
<ResponsiveContainer width="100%" height={400}>
  <LineChart data={usageData}>
    <CartesianGrid strokeDasharray="3 3" />
    <XAxis dataKey="timestamp" />
    <YAxis />
    <Tooltip />
    <Legend />
    <Line type="monotone" dataKey="calls" stroke="#8884d8" />
  </LineChart>
</ResponsiveContainer>

// Pie chart for agent distribution
<ResponsiveContainer width="100%" height={400}>
  <PieChart>
    <Pie data={agentData} dataKey="value" nameKey="name" cx="50%" cy="50%" label>
      {agentData.map((entry, index) => (
        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
      ))}
    </Pie>
    <Tooltip />
    <Legend />
  </PieChart>
</ResponsiveContainer>
```

**API Endpoints:**
```
GET /api/v1/usage/overview?range=24h
GET /api/v1/usage/calls-over-time?range=7d&granularity=hourly
GET /api/v1/usage/agent-distribution?range=30d
GET /api/v1/usage/top-users?range=7d&limit=10
```

#### 3.2 Cost Management Page
**Route:** `/dashboard/cost`
**File:** `frontend/app/dashboard/cost/page.tsx`

**Sections:**
1. **Cost KPIs** (Cards)
   - Total Spend (period)
   - Budget Remaining
   - Avg Cost per Call
   - Projected Monthly

2. **Cost Trend** (Area Chart)
   - X-axis: Time
   - Y-axis: Cumulative cost
   - Stacked areas for different models

3. **Cost by Model** (Bar Chart)
   - Horizontal bars
   - Compare model costs

4. **Budget Alert** (Alert Component)
   - Show if approaching/exceeded budget
   - Configurable thresholds

**shadcn/ui Components:**
- `Card` - KPI containers
- `Alert` - Budget warnings
- `Progress` - Budget usage bar
- `Button` - "Set Budget" action

**Recharts Components:**
```tsx
import { AreaChart, Area, BarChart, Bar } from 'recharts'

// Area chart for cost trend
<ResponsiveContainer width="100%" height={400}>
  <AreaChart data={costData}>
    <CartesianGrid strokeDasharray="3 3" />
    <XAxis dataKey="date" />
    <YAxis />
    <Tooltip />
    <Legend />
    <Area type="monotone" dataKey="gpt4" stackId="1" stroke="#8884d8" fill="#8884d8" />
    <Area type="monotone" dataKey="gpt35" stackId="1" stroke="#82ca9d" fill="#82ca9d" />
  </AreaChart>
</ResponsiveContainer>

// Bar chart for cost by model
<ResponsiveContainer width="100%" height={400}>
  <BarChart data={modelCostData} layout="vertical">
    <CartesianGrid strokeDasharray="3 3" />
    <XAxis type="number" />
    <YAxis dataKey="model" type="category" />
    <Tooltip />
    <Bar dataKey="cost" fill="#8884d8" />
  </BarChart>
</ResponsiveContainer>
```

**API Endpoints:**
```
GET /api/v1/cost/overview?range=30d
GET /api/v1/cost/trend?range=30d&granularity=daily
GET /api/v1/cost/by-model?range=30d
GET /api/v1/cost/budget?workspace_id=X
PUT /api/v1/cost/budget    # Set/update budget
```

#### 3.3 Performance Monitoring Page
**Route:** `/dashboard/performance`
**File:** `frontend/app/dashboard/performance/page.tsx`

**Sections:**
1. **Performance KPIs** (Cards)
   - P50 Latency
   - P95 Latency
   - P99 Latency
   - Error Rate

2. **Latency Distribution** (Line Chart with multiple lines)
   - P50, P95, P99 over time
   - X-axis: Time
   - Y-axis: Latency (ms)

3. **Throughput** (Area Chart)
   - Requests per second
   - Success vs Error rate

4. **Error Analysis Table** (Table)
   - Error type
   - Count
   - % of total
   - Last seen

**shadcn/ui Components:**
- `Card` - KPI containers
- `Badge` - Status indicators (healthy/degraded/critical)
- `Table` - Error listing
- `Tabs` - View switching (Latency/Throughput/Errors)

**Recharts Components:**
```tsx
// Multi-line chart for latency percentiles
<ResponsiveContainer width="100%" height={400}>
  <LineChart data={latencyData}>
    <CartesianGrid strokeDasharray="3 3" />
    <XAxis dataKey="timestamp" />
    <YAxis />
    <Tooltip />
    <Legend />
    <Line type="monotone" dataKey="p50" stroke="#8884d8" name="P50" />
    <Line type="monotone" dataKey="p95" stroke="#82ca9d" name="P95" />
    <Line type="monotone" dataKey="p99" stroke="#ffc658" name="P99" />
  </LineChart>
</ResponsiveContainer>

// Stacked area for throughput
<ResponsiveContainer width="100%" height={400}>
  <AreaChart data={throughputData}>
    <CartesianGrid strokeDasharray="3 3" />
    <XAxis dataKey="timestamp" />
    <YAxis />
    <Tooltip />
    <Legend />
    <Area type="monotone" dataKey="success" stackId="1" stroke="#82ca9d" fill="#82ca9d" />
    <Area type="monotone" dataKey="error" stackId="1" stroke="#ff0000" fill="#ff0000" />
  </AreaChart>
</ResponsiveContainer>
```

**API Endpoints:**
```
GET /api/v1/performance/overview?range=24h
GET /api/v1/performance/latency?range=24h&granularity=5m
GET /api/v1/performance/throughput?range=24h
GET /api/v1/performance/errors?range=24h&limit=20
```

### Query Service Extensions
Add new routes to Query Service for these pages:

```
backend/query/
├── routes/
│   ├── usage.py          # Usage analytics endpoints
│   ├── cost.py           # Cost endpoints
│   └── performance.py    # Performance endpoints
```

### Tests Required
- **Backend:** 18 tests (6 per page API)
- **Frontend:** 9 tests (3 per page component)
- **Total:** **27 tests**

### Acceptance Criteria
✅ All 3 pages render with real data
✅ All charts interactive and responsive
✅ Time range filters work correctly
✅ Data updates when filters change
✅ Error states handled gracefully
✅ All shadcn/ui components styled beautifully
✅ All 27 tests passing

### Synthetic Data Usage
- Use 10,000 traces with time distribution
- Generate cost data for different models
- Create error scenarios for testing

---

## Phase 4: Advanced Features + AI (Weeks 12-14)

### Overview
Build the remaining 3 pages and all 4 advanced backend services with AI capabilities.

### Backend Services

#### 4.1 Evaluation Service
**Port:** 8004
**Purpose:** AI-powered quality evaluation using Google Gemini

**Features:**
- LLM-as-a-judge evaluations
- A/B testing framework
- Custom evaluation criteria
- Feedback collection
- Quality scoring (0-100)

**Tech Stack:**
```python
google-generativeai==0.3.1
```

**API Endpoints:**
```
POST /api/v1/evaluate/trace/:trace_id    # Evaluate single trace
POST /api/v1/evaluate/batch               # Batch evaluation
GET  /api/v1/evaluate/history             # Evaluation history
POST /api/v1/evaluate/custom-criteria     # Define custom criteria
GET  /api/v1/ab-tests                     # List A/B tests
POST /api/v1/ab-tests                     # Create A/B test
```

**Gemini Evaluation Prompt:**
```python
def evaluate_trace(trace_input: str, trace_output: str, criteria: dict) -> dict:
    prompt = f"""
    Evaluate the following AI agent interaction:

    User Input: {trace_input}
    Agent Output: {trace_output}

    Criteria:
    - Accuracy: Does the response correctly address the input?
    - Helpfulness: Is the response useful and actionable?
    - Tone: Is the tone appropriate and professional?
    - Completeness: Does it cover all aspects of the query?

    Provide scores (0-100) for each criterion and overall quality score.
    Return as JSON.
    """

    response = gemini_model.generate_content(prompt)
    return json.loads(response.text)
```

**File Structure:**
```
backend/evaluation/
├── app/
│   ├── main.py
│   ├── gemini_client.py         # Gemini API wrapper
│   ├── evaluator.py             # Evaluation logic
│   ├── ab_testing.py            # A/B test management
│   └── routes.py
├── tests/
│   ├── test_evaluation.py       # 6 tests
│   └── test_ab_testing.py       # 4 tests
└── requirements.txt
```

**Tests:** 10 tests

#### 4.2 Guardrail Service
**Port:** 8005
**Purpose:** Safety checks (PII, toxicity, prompt injection)

**Features:**
- PII detection (emails, phone numbers, SSNs, credit cards)
- Toxicity filtering (using local model or Perspective API)
- Prompt injection detection
- Jailbreak attempt detection
- Custom guardrail rules

**API Endpoints:**
```
POST /api/v1/guardrails/check         # Check text against all guardrails
POST /api/v1/guardrails/pii           # PII detection only
POST /api/v1/guardrails/toxicity      # Toxicity check only
GET  /api/v1/guardrails/violations    # Recent violations
POST /api/v1/guardrails/rules         # Create custom rule
```

**Detection Examples:**
```python
# PII Detection
import re

PII_PATTERNS = {
    'email': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    'phone': r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b',
    'ssn': r'\b\d{3}-\d{2}-\d{4}\b',
    'credit_card': r'\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b'
}

def detect_pii(text: str) -> dict:
    violations = {}
    for pii_type, pattern in PII_PATTERNS.items():
        matches = re.findall(pattern, text)
        if matches:
            violations[pii_type] = len(matches)
    return violations

# Toxicity Detection (using transformers)
from transformers import pipeline

toxicity_classifier = pipeline("text-classification", model="unitary/toxic-bert")

def detect_toxicity(text: str) -> float:
    result = toxicity_classifier(text)[0]
    return result['score'] if result['label'] == 'toxic' else 0.0
```

**File Structure:**
```
backend/guardrail/
├── app/
│   ├── main.py
│   ├── pii_detector.py
│   ├── toxicity_detector.py
│   ├── injection_detector.py
│   └── routes.py
├── tests/
│   ├── test_pii.py              # 4 tests
│   ├── test_toxicity.py         # 3 tests
│   └── test_injection.py        # 3 tests
└── requirements.txt
```

**Tests:** 10 tests

#### 4.3 Alert Service
**Port:** 8006
**Purpose:** Anomaly detection, monitoring, notifications

**Features:**
- Threshold-based alerts (latency, cost, error rate)
- Anomaly detection (statistical)
- Alert routing (Slack, PagerDuty, email)
- Alert management (acknowledge, resolve)
- Alert history

**API Endpoints:**
```
GET  /api/v1/alerts                      # List active alerts
GET  /api/v1/alerts/:id                  # Get alert details
POST /api/v1/alerts/:id/acknowledge      # Acknowledge alert
POST /api/v1/alerts/:id/resolve          # Resolve alert
POST /api/v1/alert-rules                 # Create alert rule
GET  /api/v1/alert-rules                 # List rules
```

**Alert Rule Example:**
```python
class AlertRule(BaseModel):
    name: str
    metric: str  # 'latency', 'cost', 'error_rate'
    operator: str  # '>', '<', '>=', '<='
    threshold: float
    window: str  # '5m', '1h', '24h'
    severity: str  # 'info', 'warning', 'critical'
    notification_channels: list[str]  # ['slack', 'email']
```

**File Structure:**
```
backend/alert/
├── app/
│   ├── main.py
│   ├── detector.py              # Anomaly detection
│   ├── rules.py                 # Rule engine
│   ├── notifier.py              # Notification sender
│   └── routes.py
├── tests/
│   ├── test_detector.py         # 4 tests
│   └── test_rules.py            # 3 tests
└── requirements.txt
```

**Tests:** 7 tests

#### 4.4 Gemini Integration Service
**Port:** 8007
**Purpose:** AI insights for cost optimization, error diagnosis, feedback analysis

**Features:**
- Cost optimization suggestions
- Error root cause analysis
- Feedback sentiment analysis
- Automated insights generation

**API Endpoints:**
```
POST /api/v1/insights/cost-optimization     # Get cost reduction suggestions
POST /api/v1/insights/error-diagnosis       # Analyze error patterns
POST /api/v1/insights/feedback-analysis     # Sentiment analysis
GET  /api/v1/insights/daily-summary         # Daily automated insights
```

**Example - Cost Optimization:**
```python
def suggest_cost_optimization(cost_data: dict) -> str:
    prompt = f"""
    Analyze this cost data and provide 3 specific recommendations to reduce costs:

    Current spend: ${cost_data['total_cost']}
    Top models:
    - GPT-4: ${cost_data['gpt4_cost']} ({cost_data['gpt4_calls']} calls)
    - GPT-3.5: ${cost_data['gpt35_cost']} ({cost_data['gpt35_calls']} calls)

    Average tokens per call: {cost_data['avg_tokens']}

    Provide actionable recommendations.
    """

    response = gemini_model.generate_content(prompt)
    return response.text
```

**File Structure:**
```
backend/gemini/
├── app/
│   ├── main.py
│   ├── insights.py              # Insight generation
│   ├── analyzer.py              # Data analysis
│   └── routes.py
├── tests/
│   ├── test_insights.py         # 5 tests
└── requirements.txt
```

**Tests:** 5 tests

### Frontend Pages

#### 4.4 Quality Evaluation Page
**Route:** `/dashboard/quality`
**File:** `frontend/app/dashboard/quality/page.tsx`

**Sections:**
1. **Quality Score KPIs** (Cards)
   - Overall Quality Score
   - Accuracy Score
   - Helpfulness Score
   - Tone Score

2. **Quality Trend** (Line Chart)
   - Quality score over time
   - By agent comparison

3. **Evaluation History** (Table with shadcn/ui)
   - Trace ID
   - Quality Score
   - Breakdown (Accuracy, Helpfulness, Tone)
   - Timestamp
   - Actions (View Details)

4. **A/B Test Results** (Comparison Cards)
   - Variant A vs Variant B
   - Statistical significance
   - Winner declaration

**shadcn/ui Components:**
- `Card` - KPI and comparison containers
- `Table` - Evaluation history
- `Dialog` - View evaluation details
- `Tabs` - Switch between Manual/Auto evaluations
- `Button` - Trigger evaluation

**API Integration:**
```tsx
const { data: qualityOverview } = useQuery({
  queryKey: ['quality-overview', timeRange],
  queryFn: () => apiClient.get(`/api/v1/quality/overview?range=${timeRange}`)
})

const { data: evaluations } = useQuery({
  queryKey: ['evaluations', page],
  queryFn: () => apiClient.get(`/api/v1/evaluate/history?page=${page}`)
})
```

#### 4.5 Safety & Guardrails Page
**Route:** `/dashboard/safety`
**File:** `frontend/app/dashboard/safety/page.tsx`

**Sections:**
1. **Safety KPIs** (Cards)
   - Total Violations
   - PII Detections
   - Toxicity Blocks
   - Injection Attempts

2. **Violation Trend** (Stacked Area Chart)
   - PII, Toxicity, Injection over time

3. **Recent Violations** (Table with severity badges)
   - Type (PII/Toxicity/Injection)
   - Severity
   - Agent
   - Timestamp
   - Action Taken

4. **Guardrail Rules** (List with shadcn/ui)
   - Rule name
   - Type
   - Enabled/Disabled toggle
   - Edit/Delete actions

**shadcn/ui Components:**
- `Card` - KPI containers
- `Table` - Violations list
- `Badge` - Severity indicators
- `Switch` - Enable/disable rules
- `Alert` - Critical violations
- `Dialog` - Add/edit rules

#### 4.6 Business Impact Page
**Route:** `/dashboard/impact`
**File:** `frontend/app/dashboard/impact/page.tsx`

**Sections:**
1. **Business KPIs** (Cards)
   - ROI (%)
   - Cost Savings
   - Time Saved
   - User Satisfaction

2. **ROI Calculation** (Info Card)
   - Formula explanation
   - Breakdown of benefits vs costs

3. **Goal Tracking** (Progress Bars with shadcn/ui)
   - Goal name
   - Current value
   - Target value
   - Progress %

4. **Impact Timeline** (Area Chart)
   - Business metrics over time

**shadcn/ui Components:**
- `Card` - KPI and info containers
- `Progress` - Goal progress bars
- `Tabs` - Different impact views (ROI/Goals/Trends)
- `Button` - Add new goal

**API Endpoints:**
```
GET /api/v1/impact/overview?range=30d
GET /api/v1/impact/roi?range=30d
GET /api/v1/impact/goals
POST /api/v1/impact/goals              # Create goal
PUT /api/v1/impact/goals/:id           # Update goal progress
```

### Tests Required
- **Backend Services:** 32 tests
  - Evaluation: 10
  - Guardrail: 10
  - Alert: 7
  - Gemini: 5
- **Frontend Pages:** 9 tests (3 per page)
- **Integration:** 3 tests
- **Total:** **44 tests**

### Acceptance Criteria
✅ All 4 services running
✅ Quality evaluations work with Gemini
✅ Guardrails detect PII, toxicity, injection
✅ Alerts trigger and notify correctly
✅ All 3 pages display real data
✅ Gemini insights generate successfully
✅ All 44 tests passing

### Synthetic Data Usage
- Generate evaluation scores for traces
- Create guardrail violations
- Set up alert scenarios
- Add business goals and progress

---

## Phase 5: Settings + SDKs (Weeks 15-16)

### Overview
Build the Settings page and create Python/TypeScript SDKs for easy integration.

### Deliverables

#### 5.1 Settings Page
**Route:** `/dashboard/settings`
**File:** `frontend/app/dashboard/settings/page.tsx`

**Tabs (using shadcn/ui Tabs):**

**5.1.1 General Tab**
- Workspace name
- Workspace ID (read-only)
- Description
- Timezone

**shadcn/ui Components:**
- `Input` - Text fields
- `Textarea` - Description
- `Select` - Timezone picker
- `Button` - Save changes

**5.1.2 Team Tab**
- Members table
- Invite new members
- Role management (Owner/Admin/Member/Viewer)
- Remove members

**shadcn/ui Components:**
- `Table` - Members list
- `Dialog` - Invite member
- `Select` - Role selector
- `Button` - Actions

**5.1.3 API Keys Tab**
- Create API key
- List API keys
- Revoke API keys
- Copy to clipboard

**shadcn/ui Components:**
- `Button` - Create API key
- `Table` - API keys list
- `Badge` - Status (Active/Revoked)
- `Dialog` - Show new key (one-time)
- `AlertDialog` - Confirm revocation

**5.1.4 Billing Tab**
- Current plan
- Usage limits
- Billing history
- Update payment method

**shadcn/ui Components:**
- `Card` - Plan details
- `Table` - Billing history
- `Button` - Upgrade plan
- `Badge` - Plan tier

**5.1.5 Integrations Tab**
- Slack webhook
- PagerDuty key
- Sentry DSN
- Custom webhooks

**shadcn/ui Components:**
- `Input` - Integration credentials
- `Switch` - Enable/disable integrations
- `Button` - Test connection

**API Endpoints:**
```
# Workspace
GET  /api/v1/workspace
PUT  /api/v1/workspace

# Team
GET  /api/v1/team/members
POST /api/v1/team/invite
PUT  /api/v1/team/members/:id/role
DELETE /api/v1/team/members/:id

# API Keys (already in Gateway)
GET  /api/v1/api-keys
POST /api/v1/api-keys
DELETE /api/v1/api-keys/:id

# Billing
GET /api/v1/billing/plan
GET /api/v1/billing/history
POST /api/v1/billing/payment-method

# Integrations
GET /api/v1/integrations
PUT /api/v1/integrations/:type
POST /api/v1/integrations/:type/test
```

#### 5.2 Python SDK
**Package:** `agent-observability`
**PyPI:** `pip install agent-observability`

**Usage (2-line integration):**
```python
from agent_observability import AgentObservability

# Initialize
obs = AgentObservability(api_key="your-api-key")

# Auto-instrumentation (decorator)
@obs.trace()
def my_agent_function(user_input: str) -> str:
    # Your agent logic
    response = call_llm(user_input)
    return response

# Manual instrumentation
with obs.trace_context(
    agent_id="support-bot",
    user_id="user123",
    metadata={"session": "abc"}
):
    response = my_agent_function("Hello")
    obs.set_output(response)
    obs.set_cost(0.0023)
```

**Features:**
- Auto-instrumentation via decorators
- Context managers for manual tracing
- Async support
- Batch sending
- Error handling
- Retry logic

**File Structure:**
```
python-sdk/
├── agent_observability/
│   ├── __init__.py
│   ├── client.py              # Main SDK class
│   ├── decorators.py          # @trace decorator
│   ├── context.py             # Context managers
│   ├── models.py              # Data models
│   └── transport.py           # HTTP client
├── tests/
│   ├── test_client.py         # 4 tests
│   ├── test_decorators.py     # 3 tests
│   └── test_context.py        # 2 tests
├── examples/
│   ├── basic.py
│   ├── async.py
│   └── advanced.py
├── setup.py
├── README.md
└── pyproject.toml
```

**Tests:** 9 tests

#### 5.3 TypeScript SDK
**Package:** `@agent-observability/sdk`
**NPM:** `npm install @agent-observability/sdk`

**Usage (2-line integration):**
```typescript
import { AgentObservability } from '@agent-observability/sdk'

// Initialize
const obs = new AgentObservability({ apiKey: 'your-api-key' })

// Auto-instrumentation (decorator)
class MyAgent {
  @obs.trace({ agentId: 'support-bot' })
  async handleRequest(input: string): Promise<string> {
    const response = await callLLM(input)
    return response
  }
}

// Manual instrumentation
await obs.trace('support-bot', async (ctx) => {
  const response = await callLLM(input)
  ctx.setOutput(response)
  ctx.setCost(0.0023)
  return response
})
```

**File Structure:**
```
typescript-sdk/
├── src/
│   ├── index.ts               # Main export
│   ├── client.ts              # SDK class
│   ├── decorators.ts          # @trace decorator
│   ├── context.ts             # Trace context
│   ├── models.ts              # Type definitions
│   └── transport.ts           # HTTP client
├── tests/
│   ├── client.test.ts         # 4 tests
│   ├── decorators.test.ts     # 3 tests
│   └── context.test.ts        # 2 tests
├── examples/
│   ├── basic.ts
│   ├── nextjs.ts
│   └── express.ts
├── package.json
├── tsconfig.json
└── README.md
```

**Tests:** 9 tests

### Tests Required
- **Settings Page:** 5 tests
- **Python SDK:** 9 tests
- **TypeScript SDK:** 9 tests
- **Integration:** 3 tests (SDK → API → DB)
- **Total:** **26 tests**

### Acceptance Criteria
✅ Settings page fully functional
✅ Can create/revoke API keys
✅ Python SDK publishes to PyPI
✅ TypeScript SDK publishes to NPM
✅ SDKs can ingest traces with 2 lines of code
✅ Example apps work
✅ Documentation complete
✅ All 26 tests passing

### Synthetic Data Usage
- Test SDK integration with sample apps
- Verify traces appear in dashboard
- Test different SDK configurations

---

## Phase 6: Production Ready (Weeks 17-20)

### Overview
Make the platform production-ready with real-time features, performance optimization, and deployment infrastructure.

### Deliverables

#### 6.1 WebSocket Real-Time Updates
**Purpose:** Live dashboard updates without polling

**Backend:**
```python
# backend/gateway/app/websocket.py
from fastapi import WebSocket
import redis.asyncio as redis

class ConnectionManager:
    def __init__(self):
        self.active_connections: dict[str, list[WebSocket]] = {}
        self.redis_client = redis.from_url("redis://redis:6379")

    async def connect(self, websocket: WebSocket, workspace_id: str):
        await websocket.accept()
        if workspace_id not in self.active_connections:
            self.active_connections[workspace_id] = []
        self.active_connections[workspace_id].append(websocket)

    async def broadcast(self, workspace_id: str, message: dict):
        if workspace_id in self.active_connections:
            for connection in self.active_connections[workspace_id]:
                await connection.send_json(message)

manager = ConnectionManager()

@app.websocket("/ws/{workspace_id}")
async def websocket_endpoint(websocket: WebSocket, workspace_id: str):
    await manager.connect(websocket, workspace_id)
    try:
        while True:
            # Listen to Redis pub/sub for updates
            pass
    except WebSocketDisconnect:
        manager.disconnect(websocket, workspace_id)
```

**Frontend:**
```tsx
// hooks/useWebSocket.ts
import { useEffect, useState } from 'react'

export function useWebSocket(workspaceId: string) {
  const [data, setData] = useState(null)

  useEffect(() => {
    const ws = new WebSocket(`ws://localhost:8000/ws/${workspaceId}`)

    ws.onmessage = (event) => {
      const update = JSON.parse(event.data)
      setData(update)
    }

    return () => ws.close()
  }, [workspaceId])

  return data
}

// Usage in dashboard
function HomePage() {
  const realtimeUpdate = useWebSocket(workspaceId)

  useEffect(() => {
    if (realtimeUpdate?.type === 'new_trace') {
      queryClient.invalidateQueries(['home-kpis'])
    }
  }, [realtimeUpdate])
}
```

#### 6.2 Performance Optimization

**Database Optimization:**
- Add missing indexes
- Optimize continuous aggregate refresh
- Connection pooling (PgBouncer)
- Query analysis and optimization

**Redis Caching:**
- Cache frequently accessed data (5-min TTL)
- Cache invalidation on updates
- Cache warming for common queries

**Frontend Optimization:**
- Code splitting
- Image optimization
- Lazy loading
- React Query caching
- Prefetching

#### 6.3 Docker Production Images

**Multi-stage builds:**
```dockerfile
# backend/gateway/Dockerfile
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Frontend:**
```dockerfile
# frontend/Dockerfile
FROM node:20-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
CMD ["npm", "start"]
```

#### 6.4 Kubernetes Deployment

**Helm chart structure:**
```
k8s/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── gateway/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ingress.yaml
│   ├── ingestion/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── processing/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── query/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── evaluation/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── guardrail/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── alert/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── gemini/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── frontend/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ingress.yaml
│   └── configmap.yaml
```

**Example deployment:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gateway
spec:
  replicas: 3
  selector:
    matchLabels:
      app: gateway
  template:
    metadata:
      labels:
        app: gateway
    spec:
      containers:
      - name: gateway
        image: agent-obs/gateway:latest
        ports:
        - containerPort: 8000
        env:
        - name: TIMESCALE_URL
          valueFrom:
            secretKeyRef:
              name: db-secrets
              key: timescale-url
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
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
```

#### 6.5 Monitoring & Observability

**Prometheus Metrics:**
```python
# Add to all services
from prometheus_client import Counter, Histogram, generate_latest

request_count = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
request_duration = Histogram('http_request_duration_seconds', 'HTTP request duration')

@app.middleware("http")
async def prometheus_middleware(request: Request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start

    request_count.labels(request.method, request.url.path, response.status_code).inc()
    request_duration.observe(duration)

    return response

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type="text/plain")
```

**Grafana Dashboards:**
- Service health dashboard
- Request rate and latency
- Error rates
- Database performance
- Redis metrics

#### 6.6 E2E Testing

**Playwright tests:**
```typescript
// e2e/home.spec.ts
import { test, expect } from '@playwright/test'

test.describe('Home Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:3000/dashboard')
  })

  test('displays KPI cards', async ({ page }) => {
    await expect(page.getByText('Total Requests')).toBeVisible()
    await expect(page.getByText('Avg Latency')).toBeVisible()
    await expect(page.getByText('Total Cost')).toBeVisible()
    await expect(page.getByText('Success Rate')).toBeVisible()
  })

  test('loads real data', async ({ page }) => {
    // Wait for data to load
    await page.waitForSelector('[data-testid="kpi-card"]')

    // Verify data is not placeholder
    const totalRequests = await page.getByTestId('total-requests').textContent()
    expect(totalRequests).not.toBe('—')
    expect(totalRequests).toMatch(/^\d+/)
  })

  test('time range selector works', async ({ page }) => {
    await page.getByRole('button', { name: 'Last 24 Hours' }).click()
    await page.getByRole('option', { name: 'Last 7 Days' }).click()

    // Wait for data refresh
    await page.waitForResponse(resp => resp.url().includes('/api/v1/metrics/home-kpis'))

    // Verify data changed
    const newValue = await page.getByTestId('total-requests').textContent()
    expect(newValue).toBeTruthy()
  })
})
```

**E2E Test Suite:**
```
e2e/
├── home.spec.ts              # 3 tests
├── usage.spec.ts             # 2 tests
├── cost.spec.ts              # 2 tests
├── performance.spec.ts       # 2 tests
├── quality.spec.ts           # 1 test
├── safety.spec.ts            # 1 test
├── impact.spec.ts            # 1 test
├── settings.spec.ts          # 2 tests
└── sdk-integration.spec.ts   # 3 tests
```

**Tests:** 17 E2E tests

#### 6.7 Load Testing

**K6 script:**
```javascript
import http from 'k6/http'
import { check, sleep } from 'k6'

export const options = {
  stages: [
    { duration: '2m', target: 100 },  // Ramp up
    { duration: '5m', target: 100 },  // Stay at 100
    { duration: '2m', target: 200 },  // Ramp to 200
    { duration: '5m', target: 200 },  // Stay at 200
    { duration: '2m', target: 0 },    // Ramp down
  ],
}

export default function () {
  const trace = {
    trace_id: `trace_${__VU}_${__ITER}`,
    agent_id: 'load-test-agent',
    workspace_id: 'workspace-123',
    timestamp: new Date().toISOString(),
    input: 'Test input',
    output: 'Test output',
    latency_ms: 1200,
    model: 'gpt-4-turbo',
    tokens_input: 100,
    tokens_output: 200,
    cost_usd: 0.005,
  }

  const res = http.post('http://localhost:8001/api/v1/traces', JSON.stringify(trace), {
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${__ENV.API_KEY}` },
  })

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  })

  sleep(1)
}
```

**Load Test Goals:**
- 200 requests/second sustained
- P95 latency < 500ms
- 0 errors under load

#### 6.8 Documentation

**Production Docs:**
```
docs/production/
├── DEPLOYMENT.md             # Deployment guide
├── MONITORING.md             # Monitoring setup
├── SCALING.md                # Scaling strategies
├── SECURITY.md               # Security best practices
├── BACKUP.md                 # Backup and recovery
├── TROUBLESHOOTING.md        # Common issues
└── API_REFERENCE.md          # Complete API docs
```

### Tests Required
- **WebSocket:** 3 tests
- **Performance:** 4 tests (query optimization)
- **E2E:** 17 tests
- **Load Testing:** Pass criteria (not counted as tests)
- **Total:** **24 tests**

### Acceptance Criteria
✅ WebSocket real-time updates working
✅ Dashboard updates live without refresh
✅ All queries optimized (< 100ms)
✅ Docker images build successfully
✅ Kubernetes deployment works
✅ Prometheus metrics exposed
✅ Grafana dashboards configured
✅ All E2E tests passing
✅ Load test passes (200 req/s, P95 < 500ms)
✅ Production documentation complete
✅ All 24 tests passing

### Synthetic Data Usage
- Load testing with 100k+ traces
- Stress test WebSocket connections
- Test production deployment with real data

---

## Testing Strategy

### Test Pyramid

```
                  E2E (17)
              ┌─────────────┐
             /               \
           /                   \
         /   Integration (16)    \
       /                           \
     /                               \
   /                                   \
 /         Unit Tests (100)              \
└───────────────────────────────────────────┘
```

### Test Distribution by Phase

| Phase | Unit | Integration | E2E | Total |
|-------|------|-------------|-----|-------|
| 0     | 8    | 0           | 0   | 8     |
| 1     | 38   | 5           | 0   | 43    |
| 2     | 18   | 3           | 0   | 21    |
| 3     | 24   | 3           | 0   | 27    |
| 4     | 38   | 3           | 0   | 41    |
| 5     | 23   | 3           | 0   | 26    |
| 6     | 7    | 0           | 17  | 24    |
| **Total** | **156** | **17** | **17** | **190** |

### Test Requirements

**Unit Tests:**
- Each function/method tested
- Mock external dependencies
- Fast execution (< 5 seconds total)
- 80%+ code coverage

**Integration Tests:**
- Test service interactions
- Real database connections
- Redis Streams flow
- End-to-end trace flow

**E2E Tests:**
- User workflows
- Cross-service functionality
- Real browser automation
- Production-like environment

### Test Commands

```bash
# Backend unit tests
cd backend
pytest

# Backend with coverage
pytest --cov=app --cov-report=html

# Frontend unit tests
cd frontend
npm test

# E2E tests
cd e2e
npx playwright test

# Load testing
k6 run load-test.js

# All tests
./run-all-tests.sh
```

---

## Success Metrics

### Phase Completion Criteria

Each phase must meet these criteria before moving to the next:

1. **All tests passing** (unit + integration + E2E)
2. **Code review complete** (if team available)
3. **Documentation updated**
4. **Synthetic data working**
5. **No critical bugs**
6. **Performance benchmarks met**

### Performance Benchmarks

| Metric | Target |
|--------|--------|
| API Response Time (P95) | < 200ms |
| Database Query Time (P95) | < 100ms |
| Dashboard Load Time | < 2s |
| Trace Ingestion Rate | > 1000/s |
| WebSocket Latency | < 50ms |

### Quality Metrics

| Metric | Target |
|--------|--------|
| Code Coverage | > 80% |
| Type Safety | 100% (TypeScript strict) |
| Linting Errors | 0 |
| Security Vulnerabilities | 0 (high/critical) |
| Accessibility Score | > 90 |

---

## Dependencies Between Phases

```
Phase 0 (Foundation)
    ↓
Phase 1 (Core Backend) ← Must complete before Phase 2
    ↓
Phase 2 (Query + Home) ← Needs Phase 1 services running
    ↓
Phase 3 (Analytics Pages) ← Needs Query Service from Phase 2
    ↓
Phase 4 (Advanced Features) ← Can run parallel to Phase 3
    ↓
Phase 5 (Settings + SDKs) ← Needs all backend services from Phase 4
    ↓
Phase 6 (Production) ← Needs everything above
```

### Can Be Parallelized

- Phase 3 frontend pages + Phase 4 backend services (can develop in parallel)
- SDK development (Python + TypeScript can be done simultaneously)

---

## Timeline Summary

| Phase | Duration | Cumulative | Key Deliverables |
|-------|----------|------------|------------------|
| 0     | 2 weeks  | 2 weeks    | Infrastructure, Schemas, Frontend Shell |
| 1     | 3 weeks  | 5 weeks    | Gateway, Ingestion, Processing |
| 2     | 3 weeks  | 8 weeks    | Query Service, Home Dashboard |
| 3     | 3 weeks  | 11 weeks   | Usage, Cost, Performance Pages |
| 4     | 3 weeks  | 14 weeks   | Quality, Safety, Impact, AI Services |
| 5     | 2 weeks  | 16 weeks   | Settings, Python SDK, TypeScript SDK |
| 6     | 4 weeks  | 20 weeks   | Production Ready, E2E, Deployment |

**Total: 20 weeks (5 months)**

---

## shadcn/ui Component Inventory

### Components Used Throughout Platform

| Component | Usage Count | Primary Use Case |
|-----------|-------------|------------------|
| `Card` | ~50 | Containers, KPI cards, info sections |
| `Button` | ~100 | Actions, navigation, forms |
| `Table` | ~15 | Data display (traces, users, violations) |
| `Badge` | ~30 | Status indicators, tags |
| `Alert` | ~10 | Notifications, warnings |
| `Dialog` | ~20 | Modals, confirmations |
| `Select` | ~25 | Filters, dropdowns |
| `Input` | ~30 | Forms, search |
| `Tabs` | ~10 | View switching |
| `Progress` | ~8 | Goal tracking, loading |
| `ScrollArea` | ~5 | Long lists |
| `Switch` | ~12 | Enable/disable toggles |
| `Textarea` | ~5 | Multi-line input |
| `AlertDialog` | ~8 | Destructive confirmations |
| `Separator` | ~20 | Visual division |
| `Skeleton` | ~15 | Loading states |

### Custom Components Built on shadcn/ui

```
components/
├── dashboard/
│   ├── KPICard.tsx           # Built on Card
│   ├── MetricCard.tsx        # Built on Card + Badge
│   ├── AlertCard.tsx         # Built on Alert
│   └── StatCard.tsx          # Built on Card
├── charts/
│   ├── LineChartCard.tsx     # Card + Recharts
│   ├── PieChartCard.tsx      # Card + Recharts
│   ├── BarChartCard.tsx      # Card + Recharts
│   └── AreaChartCard.tsx     # Card + Recharts
└── layout/
    ├── Sidebar.tsx           # Built on Button
    ├── Header.tsx            # Built on Button + Badge
    └── Footer.tsx
```

---

## Current Status & Next Steps

### ✅ Phase 0 Status
- All infrastructure set up
- Databases running with data
- Frontend scaffolding complete
- 8/8 tests passing

### ➡️ Next: Phase 1

**Immediate Actions:**
1. Create backend service directories
2. Set up FastAPI boilerplate for Gateway
3. Implement JWT authentication
4. Build Ingestion Service REST API
5. Create Redis Streams publisher
6. Build Processing Service consumer
7. Write 43 tests
8. Update docker-compose.yml
9. Test end-to-end trace flow

**Week 3 Goals:**
- Gateway service running with auth
- Ingestion service accepting traces
- 15 tests passing

**Week 4 Goals:**
- Processing service consuming streams
- Traces appearing in TimescaleDB
- 30 tests passing

**Week 5 Goals:**
- All integration tests passing
- End-to-end flow working
- 43/43 tests passing
- Ready for Phase 2

---

## Appendix

### A. Environment Variables (Complete)

```bash
# Phase 0 (Required Now)
TIMESCALE_URL=postgresql://postgres:postgres@localhost:5432/agent_observability
POSTGRES_URL=postgresql://postgres:postgres@localhost:5433/agent_observability_metadata
REDIS_URL=redis://:redis123@localhost:6379/0

# Phase 1 (Required)
JWT_SECRET=<generate with openssl rand -base64 32>
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
API_KEY_SALT=<generate with openssl rand -base64 32>

# Phase 4 (Required)
GEMINI_API_KEY=<from https://makersuite.google.com/app/apikey>

# Phase 4 (Optional)
PERSPECTIVE_API_KEY=<from Google Cloud Console>
SLACK_WEBHOOK_URL=<from Slack App>
PAGERDUTY_API_KEY=<from PagerDuty>

# Phase 6 (Production)
SENTRY_DSN=<from Sentry.io>
PROMETHEUS_ENABLED=true
```

### B. Tech Stack Summary

**Backend:**
- Python 3.11+
- FastAPI
- asyncpg (TimescaleDB)
- Redis
- Google Gemini API
- Pydantic

**Frontend:**
- Next.js 14 (App Router)
- React 18
- TypeScript (strict)
- shadcn/ui
- Recharts
- TanStack Query
- Tailwind CSS

**Infrastructure:**
- Docker & Docker Compose
- Kubernetes + Helm
- TimescaleDB
- PostgreSQL
- Redis
- Prometheus + Grafana

**Testing:**
- pytest (Python)
- Playwright (E2E)
- K6 (Load testing)

### C. Repository Structure (Final)

```
agent-monitoring/
├── backend/
│   ├── gateway/           # Phase 1
│   ├── ingestion/         # Phase 1
│   ├── processing/        # Phase 1
│   ├── query/             # Phase 2
│   ├── evaluation/        # Phase 4
│   ├── guardrail/         # Phase 4
│   ├── alert/             # Phase 4
│   ├── gemini/            # Phase 4
│   ├── db/                # Phase 0
│   ├── tests/
│   │   ├── unit/
│   │   └── integration/
│   └── shared/            # Shared utilities
├── frontend/
│   ├── app/
│   │   ├── dashboard/
│   │   │   ├── page.tsx              # Phase 2
│   │   │   ├── usage/page.tsx        # Phase 3
│   │   │   ├── cost/page.tsx         # Phase 3
│   │   │   ├── performance/page.tsx  # Phase 3
│   │   │   ├── quality/page.tsx      # Phase 4
│   │   │   ├── safety/page.tsx       # Phase 4
│   │   │   ├── impact/page.tsx       # Phase 4
│   │   │   └── settings/page.tsx     # Phase 5
│   │   └── layout.tsx
│   ├── components/
│   │   ├── ui/           # shadcn/ui
│   │   ├── dashboard/
│   │   ├── charts/
│   │   └── layout/
│   └── lib/
├── python-sdk/            # Phase 5
├── typescript-sdk/        # Phase 5
├── k8s/                   # Phase 6
├── e2e/                   # Phase 6
├── docs/
│   ├── production/
│   └── api/
├── docker-compose.yml
├── .env.example
├── setup.sh
├── start.sh
├── stop.sh
├── status.sh
└── PLAN.md               # This file
```

---

**END OF PLAN**

This document serves as the complete development roadmap for the Agent Observability Platform. Each phase builds incrementally on the previous, with clear deliverables, tests, and acceptance criteria. All UI components use shadcn/ui for consistency and beauty. Follow this plan phase-by-phase to build a production-ready observability platform.
