# Testing Patterns

**Purpose**: Standard test templates for backend and frontend
**Version**: 1.0
**Last Updated**: October 27, 2025
**Status**: Blueprint for Enterprise Release

---

## Backend Testing (pytest)

### File Location

`backend/{service}/tests/test_{module}.py`

### API Endpoint Tests

```python
import pytest
from httpx import AsyncClient
from uuid import UUID

@pytest.mark.asyncio
async def test_get_home_kpis_success(client: AsyncClient, auth_headers, workspace_id):
    """Test successful KPI retrieval"""
    response = await client.get(
        "/api/v1/metrics/home-kpis",
        params={"range": "24h"},
        headers=auth_headers
    )
    
    assert response.status_code == 200
    data = response.json()
    
    # Verify response structure
    assert "data" in data
    assert "meta" in data
    assert "filters_applied" in data
    
    # Verify KPI fields
    assert "total_requests" in data["data"]
    assert "avg_latency" in data["data"]
    assert "error_rate" in data["data"]
    
    # Verify filters applied
    assert data["filters_applied"]["range"] == "24h"

@pytest.mark.asyncio
async def test_get_home_kpis_with_filters(client: AsyncClient, auth_headers):
    """Test KPI retrieval with department filter"""
    response = await client.get(
        "/api/v1/metrics/home-kpis",
        params={"range": "24h", "department": "engineering"},
        headers=auth_headers
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["filters_applied"]["department"] == "engineering"

@pytest.mark.asyncio
async def test_get_home_kpis_unauthorized(client: AsyncClient):
    """Test KPI retrieval requires authentication"""
    response = await client.get("/api/v1/metrics/home-kpis")
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_get_home_kpis_invalid_workspace(client: AsyncClient, auth_headers):
    """Test KPI retrieval with invalid workspace"""
    headers = {**auth_headers, "X-Workspace-ID": "invalid-uuid"}
    response = await client.get(
        "/api/v1/metrics/home-kpis",
        headers=headers
    )
    assert response.status_code == 403
```

### Service Logic Tests

```python
@pytest.mark.asyncio
async def test_calculate_department_metrics(db_session, workspace_id):
    """Test department metrics calculation"""
    result = await calculate_department_metrics(
        db_session,
        workspace_id=workspace_id,
        department_id="engineering",
        time_range="24h"
    )
    
    assert result["request_count"] > 0
    assert "avg_latency" in result
    assert "total_cost" in result
    assert result["department_id"] == "engineering"

@pytest.mark.asyncio
async def test_filter_traces_by_department(db_session, workspace_id):
    """Test trace filtering by department"""
    traces = await get_traces(
        db_session,
        workspace_id=workspace_id,
        department="engineering",
        limit=100
    )
    
    assert len(traces) > 0
    assert all(t["department_id"] == "engineering" for t in traces)
```

### Database Tests

```python
@pytest.mark.asyncio
async def test_create_agent(db_session, workspace_id):
    """Test agent creation"""
    agent_data = {
        "workspace_id": workspace_id,
        "agent_id": "test-agent-1",
        "name": "Test Agent",
        "department_id": "dept-uuid",
        "environment": "production",
        "version": "v1.0"
    }
    
    agent_id = await db_session.fetchval("""
        INSERT INTO agents (workspace_id, agent_id, name, department_id, environment, version)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING id
    """, *agent_data.values())
    
    assert agent_id is not None
    
    # Verify agent created
    agent = await db_session.fetchrow(
        "SELECT * FROM agents WHERE id = $1", agent_id
    )
    assert agent["agent_id"] == "test-agent-1"
```

---

## Frontend Testing (React Testing Library)

### File Location

`frontend/components/{component}/__tests__/{Component}.test.tsx`

### Component Tests

```typescript
import { render, screen, fireEvent } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { KPICard } from '../KPICard'

describe('KPICard', () => {
  const queryClient = new QueryClient()
  
  const wrapper = ({ children }) => (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  )

  it('renders with correct data', () => {
    render(
      <KPICard
        title="Total Requests"
        value="1,234"
        change={12.5}
        changeLabel="vs yesterday"
      />,
      { wrapper }
    )
    
    expect(screen.getByText('Total Requests')).toBeInTheDocument()
    expect(screen.getByText('1,234')).toBeInTheDocument()
    expect(screen.getByText('+12.5%')).toBeInTheDocument()
  })

  it('shows red for negative trend when trend=normal', () => {
    render(
      <KPICard
        title="Test"
        value="100"
        change={-5}
        changeLabel="vs yesterday"
        trend="normal"
      />,
      { wrapper }
    )
    
    const changeText = screen.getByText('-5%')
    expect(changeText).toHaveClass('text-red-600')
  })

  it('shows green for negative change when trend=inverse', () => {
    render(
      <KPICard
        title="Error Rate"
        value="2.5%"
        change={-10}
        changeLabel="vs yesterday"
        trend="inverse"
      />,
      { wrapper }
    )
    
    const changeText = screen.getByText('-10%')
    expect(changeText).toHaveClass('text-green-600')
  })

  it('calls onClick when clicked', () => {
    const handleClick = jest.fn()
    render(
      <KPICard
        title="Test"
        value="100"
        change={0}
        changeLabel="test"
        onClick={handleClick}
      />,
      { wrapper }
    )
    
    fireEvent.click(screen.getByRole('button'))
    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('shows loading skeleton when loading=true', () => {
    render(
      <KPICard
        title="Test"
        value="100"
        change={0}
        changeLabel="test"
        loading={true}
      />,
      { wrapper }
    )
    
    expect(screen.getByTestId('kpi-skeleton')).toBeInTheDocument()
  })
})
```

### Hook Tests

```typescript
import { renderHook, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useFilterContext } from '@/lib/filter-context'

describe('useFilterContext', () => {
  it('provides default filters', () => {
    const wrapper = ({ children }) => (
      <FilterProvider>{children}</FilterProvider>
    )
    
    const { result } = renderHook(() => useFilterContext(), { wrapper })
    
    expect(result.current.filters.timeRange).toBe('24h')
  })

  it('updates filters', () => {
    const wrapper = ({ children }) => (
      <FilterProvider>{children}</FilterProvider>
    )
    
    const { result } = renderHook(() => useFilterContext(), { wrapper })
    
    act(() => {
      result.current.setFilters({
        ...result.current.filters,
        department: 'engineering'
      })
    })
    
    expect(result.current.filters.department).toBe('engineering')
  })
})
```

---

## Integration Tests

### File Location

`backend/tests/integration/test_{feature}_e2e.py`

### E2E Workflow Tests

```python
@pytest.mark.asyncio
async def test_trace_ingestion_to_dashboard_flow(client, db, workspace_id):
    """Test complete flow: ingest trace → process → query → display"""
    
    # 1. Ingest trace
    trace_data = {
        "trace_id": "tr_test123",
        "agent_id": "eng-code-1",
        "workspace_id": str(workspace_id),
        "timestamp": "2025-10-27T10:00:00Z",
        "input": "test input",
        "output": "test output",
        "latency_ms": 1000,
        "status": "success",
        "cost_usd": 0.05
    }
    
    ingest_response = await client.post(
        "/api/v1/traces",
        json=trace_data
    )
    assert ingest_response.status_code == 201
    
    # 2. Wait for processing (simulated)
    await asyncio.sleep(2)
    
    # 3. Query dashboard KPIs
    kpi_response = await client.get(
        "/api/v1/metrics/home-kpis?range=1h"
    )
    assert kpi_response.status_code == 200
    kpis = kpi_response.json()["data"]
    
    # 4. Verify trace appears in metrics
    assert kpis["total_requests"]["value"] > 0
```

---

## Mock Data Patterns

### Backend Fixtures

```python
@pytest.fixture
async def workspace_id():
    """Provide test workspace ID"""
    return UUID("550e8400-e29b-41d4-a716-446655440000")

@pytest.fixture
async def auth_headers(admin_user):
    """Provide authentication headers"""
    return {
        "Authorization": f"Bearer {admin_user.token}",
        "X-Workspace-ID": str(admin_user.workspace_id)
    }

@pytest.fixture
async def sample_traces(db, workspace_id):
    """Create sample traces for testing"""
    traces = []
    for i in range(10):
        trace_id = await db.fetchval("""
            INSERT INTO traces (
                trace_id, workspace_id, agent_id, timestamp,
                latency_ms, status, cost_usd
            )
            VALUES ($1, $2, $3, NOW(), $4, $5, $6)
            RETURNING id
        """,
            f"tr_{i}",
            workspace_id,
            "test-agent",
            1000 + i * 100,
            "success",
            0.01 * (i + 1)
        )
        traces.append(trace_id)
    return traces
```

### Frontend Mocks

```typescript
import { rest } from 'msw'
import { setupServer } from 'msw/node'

export const handlers = [
  rest.get('/api/v1/metrics/home-kpis', (req, res, ctx) => {
    return res(
      ctx.status(200),
      ctx.json({
        data: {
          total_requests: { value: 1234, change: 12.5 },
          avg_latency: { value: 1000, change: -5.2 },
          error_rate: { value: 2.3, change: -0.5 }
        },
        meta: {
          generated_at: '2025-10-27T10:00:00Z'
        }
      })
    )
  })
]

export const server = setupServer(...handlers)
```

---

**Document Version**: 1.0
**Last Updated**: October 27, 2025
**Status**: Active Blueprint
