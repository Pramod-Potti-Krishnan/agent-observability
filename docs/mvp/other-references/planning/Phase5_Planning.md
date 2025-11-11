# Agent Observability Platform - Phase 5 Implementation Guide

**Version:** 1.0.0
**Date:** October 25, 2025
**Current Phase:** Phase 5 - Settings + SDKs
**Status:** Phases 0-4 Complete ✅ | Phase 5 In Progress 🚀

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Current System State](#current-system-state)
3. [Available Sub-Agents](#available-sub-agents)
4. [New Phase 5 Sub-Agents](#new-phase-5-sub-agents)
5. [Phase 5 Implementation Workflow](#phase-5-implementation-workflow)
6. [Code Patterns & Standards](#code-patterns--standards)
7. [Testing Strategies](#testing-strategies)
8. [Success Criteria](#success-criteria)

---

## Project Overview

### What We're Building

The **Agent Observability Platform** is a comprehensive monitoring, analytics, and management system for AI agents. It provides:

- Real-time trace ingestion and processing
- Advanced analytics (usage, cost, performance)
- AI-powered quality evaluation (using Google Gemini)
- Safety guardrails (PII detection, toxicity filtering)
- Intelligent alerting and anomaly detection
- Business impact tracking and ROI analysis
- Multi-tenant workspace management

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Frontend (Next.js)                     │
│                         Port 3000                             │
└───────────────────────────────┬─────────────────────────────┘
                                │
                ┌───────────────┴───────────────┐
                │    Gateway (FastAPI)          │
                │    Port 8000 - Auth & Routing │
                └───────────────┬───────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
┌───────▼────────┐   ┌──────────▼──────────┐   ┌──────▼──────┐
│   Ingestion    │   │      Query          │   │  Evaluation │
│   Port 8001    │   │    Port 8003        │   │  Port 8004  │
└───────┬────────┘   └─────────────────────┘   └─────────────┘
        │
┌───────▼────────┐   ┌─────────────────────┐   ┌─────────────┐
│   Processing   │   │    Guardrail        │   │    Alert    │
│   Background   │   │    Port 8005        │   │  Port 8006  │
└────────────────┘   └─────────────────────┘   └─────────────┘

┌────────────────┐   ┌─────────────────────┐   ┌─────────────┐
│   TimescaleDB  │   │    PostgreSQL       │   │    Redis    │
│   Port 5432    │   │    Port 5433        │   │  Port 6379  │
└────────────────┘   └─────────────────────┘   └─────────────┘
```

### Completed Phases

**Phase 0 (Foundation):** ✅
- Docker infrastructure (TimescaleDB, PostgreSQL, Redis)
- Database schemas with hypertables
- Next.js frontend shell with shadcn/ui
- Synthetic data generator (10,000 traces)

**Phase 1 (Core Backend):** ✅
- Gateway Service - Authentication, rate limiting, routing
- Ingestion Service - High-throughput trace ingestion
- Processing Service - Background trace processing with Redis Streams

**Phase 2 (Query Service + Home Dashboard):** ✅
- Query Service - Analytics and metrics API
- Home Dashboard - KPIs, alerts feed, activity stream
- Redis caching layer (multi-tier TTLs)

**Phase 3 (Core Analytics Pages):** ✅
- Usage Analytics Dashboard - API calls, users, agents
- Cost Management Dashboard - Spend tracking, budgets
- Performance Monitoring Dashboard - Latency percentiles, errors

**Phase 4 (Advanced Features + AI):** ✅
- Evaluation Service - LLM-as-a-judge with Google Gemini
- Guardrail Service - PII detection, toxicity filtering
- Alert Service - Threshold monitoring, anomaly detection
- Gemini Integration Service - AI-powered insights
- Quality, Safety, and Business Impact Dashboards

### Phase 5 Goals

**Duration:** 2 weeks (Weeks 15-16)

**Primary Deliverables:**
1. **Settings Page** - Multi-tab interface for workspace configuration
   - General settings (workspace name, timezone)
   - Team management (invite, roles, permissions)
   - API key management (create, revoke, copy)
   - Billing configuration (plans, usage limits)
   - Integrations (Slack, PagerDuty, webhooks)

2. **Python SDK** - `agent-observability` package
   - Decorator-based instrumentation
   - Context manager support
   - Async/await patterns
   - Automatic trace capture

3. **TypeScript SDK** - `@agent-observability/sdk` package
   - Type-safe decorators
   - Framework integrations (Express, Next.js)
   - Promise-based API
   - Automatic trace capture

**Test Coverage:** 26 tests
- 5 Settings page tests
- 9 Python SDK tests
- 9 TypeScript SDK tests
- 3 Integration tests (SDK → API → DB)

---

## Current System State

### Running Services

| Service | Port | Status | Purpose |
|---------|------|--------|---------|
| Frontend | 3000 | ✅ Running | Next.js UI with 8 dashboards |
| Gateway | 8000 | ✅ Running | API gateway, auth, routing |
| Ingestion | 8001 | ✅ Running | Trace ingestion endpoint |
| Processing | - | ✅ Running | Background trace processor |
| Query | 8003 | ✅ Running | Analytics API (13 endpoints) |
| Evaluation | 8004 | ✅ Running | Quality evaluation with Gemini |
| Guardrail | 8005 | ✅ Running | Safety and PII detection |
| Alert | 8006 | ✅ Running | Monitoring and notifications |
| Gemini | 8007 | ✅ Running | AI insights |
| TimescaleDB | 5432 | ✅ Running | Time-series metrics |
| PostgreSQL | 5433 | ✅ Running | Relational metadata |
| Redis | 6379 | ✅ Running | Cache & queues |

### Database Schema

**TimescaleDB (Time-series):**
- `traces` - Agent execution traces (10,000+ records)
- `hourly_metrics` - Aggregated hourly stats
- `daily_metrics` - Aggregated daily stats

**PostgreSQL (Metadata):**
- `workspaces` - Multi-tenant workspaces
- `users` - User accounts
- `agents` - Agent configurations
- `api_keys` - API key management
- `evaluations` - Quality evaluations (1,000+ records)
- `guardrail_rules` - Safety rules
- `guardrail_violations` - Violation history (200+ records)
- `alert_rules` - Alert configurations
- `alert_notifications` - Alert instances (50+ records)
- `business_goals` - Goal tracking (10+ records)
- `budgets` - Cost budgets

### Frontend Pages

| Route | Component | Status |
|-------|-----------|--------|
| `/login` | Login page | ✅ Complete |
| `/register` | Registration page | ✅ Complete |
| `/dashboard` | Home dashboard | ✅ Complete |
| `/dashboard/usage` | Usage analytics | ✅ Complete |
| `/dashboard/cost` | Cost management | ✅ Complete |
| `/dashboard/performance` | Performance monitoring | ✅ Complete |
| `/dashboard/quality` | Quality evaluation | ✅ Complete |
| `/dashboard/safety` | Safety & guardrails | ✅ Complete |
| `/dashboard/impact` | Business impact | ✅ Complete |
| `/dashboard/settings` | Settings (5 tabs) | 🚧 Phase 5 |

### Tech Stack

**Backend:**
- Python 3.11+
- FastAPI (async)
- asyncpg (TimescaleDB)
- Redis (caching + streams)
- Google Gemini API
- Pydantic v2

**Frontend:**
- Next.js 14 (App Router)
- React 18
- TypeScript (strict mode)
- shadcn/ui components
- Recharts visualization
- TanStack Query (data fetching)
- Tailwind CSS

**Infrastructure:**
- Docker Compose (development)
- TimescaleDB 2.11+
- PostgreSQL 15
- Redis 7

---

## Available Sub-Agents

These are pre-built specialized agents you can invoke during Phase 5 implementation. Each agent has specific capabilities and usage patterns.

### 1. fullstack-api-designer

**Purpose:** Design comprehensive API specifications for backend services

**Capabilities:**
- REST API endpoint design
- Request/response schema definition
- OpenAPI/Swagger specification generation
- API versioning strategies
- Error response modeling
- Rate limiting specifications

**When to Use:**
- Designing Settings page APIs (workspace, team, billing, integrations)
- Defining new endpoint contracts
- Creating API documentation
- Planning API versioning

**Example Usage:**
```
You: "Design the Settings page APIs for team management, including invite, role assignment, and member removal endpoints."

[Agent creates comprehensive API specification with:]
- Endpoint definitions (POST /api/v1/team/invite, etc.)
- Request/response schemas
- Authentication requirements
- Error handling
- Cache strategies
```

**Invocation:**
Use the Task tool with `subagent_type: "fullstack-api-designer"`

---

### 2. fullstack-database-designer

**Purpose:** Design database schemas, tables, indexes, and migration strategies

**Capabilities:**
- Table schema design (PostgreSQL, TimescaleDB)
- Index optimization
- Foreign key relationships
- Migration script generation
- Data modeling best practices
- Query optimization planning

**When to Use:**
- Designing new tables for Phase 5 (team_members, billing_config, integrations_config)
- Creating migration scripts
- Optimizing existing schemas
- Planning data relationships

**Example Usage:**
```
You: "Design a team_members table to support role-based access control with workspace isolation."

[Agent creates:]
- CREATE TABLE statement
- Appropriate indexes
- Foreign key constraints
- Migration script
- Rollback strategy
```

**Invocation:**
Use the Task tool with `subagent_type: "fullstack-database-designer"`

---

### 3. fullstack-integration-tester

**Purpose:** Create comprehensive test suites for full-stack applications

**Capabilities:**
- Unit test generation
- Integration test suites
- End-to-end test scenarios
- Test data fixtures
- Mock strategies
- CI/CD pipeline setup

**When to Use:**
- Creating Settings page tests
- Testing SDK integrations
- Writing API integration tests
- Validating end-to-end flows

**Example Usage:**
```
You: "Create comprehensive tests for the Settings page APIs including team management and API key operations."

[Agent creates:]
- pytest test files with 5+ test cases
- Request/response fixtures
- Mock external dependencies
- Assertion strategies
```

**Invocation:**
Use the Task tool with `subagent_type: "fullstack-integration-tester"`

---

### 4. Explore

**Purpose:** Fast exploration of codebases to find patterns, files, and understand architecture

**Capabilities:**
- Quick file pattern matching (Glob)
- Content search across files (Grep)
- Architecture analysis
- Code pattern identification
- Naming convention detection

**When to Use:**
- Understanding existing backend service patterns
- Finding similar implementations to replicate
- Analyzing frontend component structure
- Discovering authentication flows

**Example Usage:**
```
You: "Explore how existing services handle workspace isolation and authentication."

[Agent explores and reports:]
- Common patterns in gateway/app/middleware/
- Workspace ID header usage
- Authentication decorator patterns
- Database query filters
```

**Invocation:**
Use the Task tool with `subagent_type: "Explore"` and specify thoroughness level

---

## New Phase 5 Sub-Agents

These are newly defined agents specifically designed for Phase 5 Settings and SDK implementation. While these may not exist as invocable sub-agents in your current Claude Code system, their specifications can guide your implementation approach.

### 5. sdk-architect (Conceptual Guide)

**Purpose:** Architect Python and TypeScript SDKs with best practices and cross-language consistency

**Core Principles:**
- **Decorator Pattern:** Use decorators for automatic instrumentation
- **Context Management:** Provide context managers for manual control
- **Async Support:** Full async/await support in both languages
- **Type Safety:** Strict typing (Pydantic for Python, TypeScript for TS)
- **Framework Agnostic:** Work with any framework (Flask, FastAPI, Express, Next.js)

**SDK Design Pattern:**

**Python SDK Structure:**
```python
agent_observability/
├── __init__.py              # Public API exports
├── client.py                # Main SDK class
├── decorators.py            # @trace decorator
├── context.py               # Context managers
├── models.py                # Pydantic models
├── transport.py             # HTTP client (async)
├── config.py                # Configuration
└── exceptions.py            # Custom exceptions
```

**TypeScript SDK Structure:**
```typescript
src/
├── index.ts                 # Public API exports
├── client.ts                # Main SDK class
├── decorators.ts            # @trace decorator
├── context.ts               # Trace context
├── models.ts                # Type definitions
├── transport.ts             # HTTP client (fetch/axios)
├── config.ts                # Configuration
└── errors.ts                # Custom error classes
```

**Key APIs to Implement:**

1. **Initialization:**
```python
# Python
from agent_observability import AgentObservability
obs = AgentObservability(api_key="...", workspace_id="...")

// TypeScript
import { AgentObservability } from '@agent-observability/sdk'
const obs = new AgentObservability({ apiKey: '...', workspaceId: '...' })
```

2. **Decorator Usage:**
```python
# Python
@obs.trace(agent_id="support-bot", tags=["production"])
def handle_customer_query(user_input: str) -> str:
    response = call_llm(user_input)
    return response

// TypeScript
class SupportBot {
  @obs.trace({ agentId: 'support-bot', tags: ['production'] })
  async handleCustomerQuery(userInput: string): Promise<string> {
    const response = await callLLM(userInput)
    return response
  }
}
```

3. **Context Manager:**
```python
# Python
with obs.trace_context(agent_id="support-bot") as ctx:
    response = call_llm(user_input)
    ctx.set_output(response)
    ctx.set_cost(0.0023)
    ctx.set_metadata({"model": "gpt-4-turbo"})

// TypeScript
await obs.trace('support-bot', async (ctx) => {
  const response = await callLLM(userInput)
  ctx.setOutput(response)
  ctx.setCost(0.0023)
  ctx.setMetadata({ model: 'gpt-4-turbo' })
  return response
})
```

**Implementation Guidelines:**

1. **HTTP Client Layer:**
   - Use `httpx` for Python (async support)
   - Use `fetch` or `axios` for TypeScript
   - Implement retry logic (exponential backoff)
   - Batch trace sending (configurable batch size)
   - Background sending (non-blocking)

2. **Error Handling:**
   - Never fail user code due to SDK errors
   - Log SDK errors for debugging
   - Provide silent failure mode
   - Expose error callbacks for monitoring

3. **Configuration:**
   - API key (required)
   - Workspace ID (required)
   - Base URL (default: http://localhost:8000)
   - Batch size (default: 10)
   - Flush interval (default: 5 seconds)
   - Retry attempts (default: 3)
   - Timeout (default: 10 seconds)

4. **Trace Capture:**
   - Automatically capture: input, output, latency, status
   - Allow manual enrichment: cost, tokens, model, metadata
   - Generate unique trace IDs (UUID)
   - Include timestamps (ISO 8601)

**Testing Strategy:**
- Mock HTTP client in unit tests
- Test decorator functionality
- Test async patterns
- Test error handling (SDK errors don't break user code)
- Test batching and flushing
- Integration test with real API

---

### 6. settings-ui-builder (Conceptual Guide)

**Purpose:** Build complex multi-tab settings interfaces with shadcn/ui components

**Core Principles:**
- **Tab-based Layout:** Use shadcn/ui Tabs for organization
- **Form Validation:** Use React Hook Form + Zod for validation
- **State Management:** Use React Query for server state
- **Optimistic Updates:** Immediate UI feedback
- **Error Handling:** Clear error messages with toast notifications

**Settings Page Structure:**

```typescript
// app/dashboard/settings/page.tsx
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'

export default function SettingsPage() {
  return (
    <div className="container mx-auto py-8">
      <h1 className="text-3xl font-bold mb-6">Settings</h1>

      <Tabs defaultValue="general" className="w-full">
        <TabsList className="grid w-full grid-cols-5">
          <TabsTrigger value="general">General</TabsTrigger>
          <TabsTrigger value="team">Team</TabsTrigger>
          <TabsTrigger value="api-keys">API Keys</TabsTrigger>
          <TabsTrigger value="billing">Billing</TabsTrigger>
          <TabsTrigger value="integrations">Integrations</TabsTrigger>
        </TabsList>

        <TabsContent value="general">
          <GeneralSettings />
        </TabsContent>

        <TabsContent value="team">
          <TeamSettings />
        </TabsContent>

        {/* ... other tabs ... */}
      </Tabs>
    </div>
  )
}
```

**Tab Implementations:**

**1. General Tab:**
```typescript
// components/settings/GeneralSettings.tsx
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Button } from '@/components/ui/button'
import { useToast } from '@/components/ui/use-toast'

const generalSchema = z.object({
  workspace_name: z.string().min(3).max(100),
  description: z.string().max(500).optional(),
  timezone: z.string(),
})

export function GeneralSettings() {
  const { toast } = useToast()
  const form = useForm({
    resolver: zodResolver(generalSchema),
  })

  const onSubmit = async (data) => {
    try {
      await apiClient.put('/api/v1/workspace', data)
      toast({ title: 'Settings saved successfully' })
    } catch (error) {
      toast({ title: 'Error saving settings', variant: 'destructive' })
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>General Settings</CardTitle>
      </CardHeader>
      <CardContent>
        <form onSubmit={form.handleSubmit(onSubmit)}>
          <div className="space-y-4">
            <div>
              <Label>Workspace Name</Label>
              <Input {...form.register('workspace_name')} />
              {form.formState.errors.workspace_name && (
                <p className="text-sm text-red-500">{form.formState.errors.workspace_name.message}</p>
              )}
            </div>

            <div>
              <Label>Description</Label>
              <Textarea {...form.register('description')} />
            </div>

            <div>
              <Label>Timezone</Label>
              <Select {...form.register('timezone')}>
                <SelectTrigger>
                  <SelectValue placeholder="Select timezone" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="UTC">UTC</SelectItem>
                  <SelectItem value="America/New_York">Eastern Time</SelectItem>
                  <SelectItem value="America/Los_Angeles">Pacific Time</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <Button type="submit">Save Changes</Button>
          </div>
        </form>
      </CardContent>
    </Card>
  )
}
```

**2. Team Tab:**
```typescript
// components/settings/TeamSettings.tsx
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Select } from '@/components/ui/select'

export function TeamSettings() {
  const { data: members } = useQuery({
    queryKey: ['team-members'],
    queryFn: () => apiClient.get('/api/v1/team/members'),
  })

  return (
    <Card>
      <CardHeader>
        <div className="flex justify-between items-center">
          <CardTitle>Team Members</CardTitle>
          <InviteMemberDialog />
        </div>
      </CardHeader>
      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Email</TableHead>
              <TableHead>Role</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {members?.map(member => (
              <TableRow key={member.id}>
                <TableCell>{member.full_name}</TableCell>
                <TableCell>{member.email}</TableCell>
                <TableCell>
                  <RoleSelector
                    currentRole={member.role}
                    memberId={member.id}
                  />
                </TableCell>
                <TableCell>
                  <Badge variant={member.status === 'active' ? 'default' : 'secondary'}>
                    {member.status}
                  </Badge>
                </TableCell>
                <TableCell>
                  <Button
                    variant="destructive"
                    size="sm"
                    onClick={() => removeMember(member.id)}
                  >
                    Remove
                  </Button>
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

**3. API Keys Tab:**
```typescript
// components/settings/APIKeysSettings.tsx
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog'
import { Check, Copy } from 'lucide-react'

export function APIKeysSettings() {
  const { data: apiKeys } = useQuery({
    queryKey: ['api-keys'],
    queryFn: () => apiClient.get('/api/v1/api-keys'),
  })

  const [copiedKey, setCopiedKey] = useState<string | null>(null)

  const copyToClipboard = (key: string) => {
    navigator.clipboard.writeText(key)
    setCopiedKey(key)
    setTimeout(() => setCopiedKey(null), 2000)
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex justify-between items-center">
          <CardTitle>API Keys</CardTitle>
          <CreateAPIKeyDialog />
        </div>
      </CardHeader>
      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Key</TableHead>
              <TableHead>Created</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {apiKeys?.map(key => (
              <TableRow key={key.id}>
                <TableCell>{key.name}</TableCell>
                <TableCell>
                  <div className="flex items-center gap-2">
                    <code className="text-sm">{key.key_preview}...</code>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => copyToClipboard(key.full_key)}
                    >
                      {copiedKey === key.full_key ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                    </Button>
                  </div>
                </TableCell>
                <TableCell>{formatDate(key.created_at)}</TableCell>
                <TableCell>
                  <Badge variant={key.status === 'active' ? 'default' : 'destructive'}>
                    {key.status}
                  </Badge>
                </TableCell>
                <TableCell>
                  <AlertDialog>
                    <AlertDialogTrigger asChild>
                      <Button variant="destructive" size="sm">Revoke</Button>
                    </AlertDialogTrigger>
                    <AlertDialogContent>
                      <AlertDialogHeader>
                        <AlertDialogTitle>Revoke API Key?</AlertDialogTitle>
                        <AlertDialogDescription>
                          This action cannot be undone. Applications using this key will stop working.
                        </AlertDialogDescription>
                      </AlertDialogHeader>
                      <AlertDialogFooter>
                        <AlertDialogCancel>Cancel</AlertDialogCancel>
                        <AlertDialogAction onClick={() => revokeKey(key.id)}>
                          Revoke Key
                        </AlertDialogAction>
                      </AlertDialogFooter>
                    </AlertDialogContent>
                  </AlertDialog>
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
- `Tabs`, `TabsContent`, `TabsList`, `TabsTrigger` - Tab layout
- `Card`, `CardContent`, `CardHeader`, `CardTitle` - Content containers
- `Input`, `Textarea`, `Select` - Form inputs
- `Button` - Actions
- `Table` - Data display
- `Badge` - Status indicators
- `Dialog` - Modals
- `AlertDialog` - Destructive confirmations
- `Switch` - Toggle switches
- `useToast` - Notifications

---

### 7. sdk-integration-tester (Conceptual Guide)

**Purpose:** Test SDK integrations with various frameworks to ensure compatibility

**Testing Frameworks:**

**Python SDK Tests:**
```python
# tests/test_decorator.py
import pytest
from agent_observability import AgentObservability
from unittest.mock import MagicMock, patch

@pytest.fixture
def obs_client():
    return AgentObservability(api_key="test-key", workspace_id="test-workspace")

def test_decorator_captures_trace(obs_client):
    """Test that decorator captures function input/output"""
    mock_transport = MagicMock()
    obs_client._transport = mock_transport

    @obs_client.trace(agent_id="test-agent")
    def sample_function(x: int) -> int:
        return x * 2

    result = sample_function(5)

    assert result == 10
    assert mock_transport.send_trace.called
    trace_data = mock_transport.send_trace.call_args[0][0]
    assert trace_data['agent_id'] == 'test-agent'
    assert trace_data['input'] == '5'
    assert trace_data['output'] == '10'

def test_context_manager_manual_control(obs_client):
    """Test context manager for manual trace control"""
    mock_transport = MagicMock()
    obs_client._transport = mock_transport

    with obs_client.trace_context(agent_id="manual-agent") as ctx:
        result = "processed result"
        ctx.set_output(result)
        ctx.set_cost(0.0023)
        ctx.set_metadata({"model": "gpt-4"})

    assert mock_transport.send_trace.called
    trace_data = mock_transport.send_trace.call_args[0][0]
    assert trace_data['output'] == 'processed result'
    assert trace_data['cost_usd'] == 0.0023
    assert trace_data['metadata']['model'] == 'gpt-4'

@pytest.mark.asyncio
async def test_async_decorator(obs_client):
    """Test async function decoration"""
    mock_transport = MagicMock()
    obs_client._transport = mock_transport

    @obs_client.trace(agent_id="async-agent")
    async def async_function(x: int) -> int:
        await asyncio.sleep(0.1)
        return x * 3

    result = await async_function(7)

    assert result == 21
    assert mock_transport.send_trace.called
```

**TypeScript SDK Tests:**
```typescript
// tests/decorator.test.ts
import { AgentObservability } from '../src'
import { jest } from '@jest/globals'

describe('AgentObservability Decorator', () => {
  let obs: AgentObservability
  let mockTransport: jest.Mock

  beforeEach(() => {
    mockTransport = jest.fn()
    obs = new AgentObservability({
      apiKey: 'test-key',
      workspaceId: 'test-workspace'
    })
    obs._transport.sendTrace = mockTransport
  })

  it('should capture function input and output', async () => {
    class TestAgent {
      @obs.trace({ agentId: 'test-agent' })
      async process(x: number): Promise<number> {
        return x * 2
      }
    }

    const agent = new TestAgent()
    const result = await agent.process(5)

    expect(result).toBe(10)
    expect(mockTransport).toHaveBeenCalled()
    const traceData = mockTransport.mock.calls[0][0]
    expect(traceData.agent_id).toBe('test-agent')
    expect(traceData.input).toBe('5')
    expect(traceData.output).toBe('10')
  })

  it('should allow manual trace control', async () => {
    await obs.trace('manual-agent', async (ctx) => {
      const result = 'processed result'
      ctx.setOutput(result)
      ctx.setCost(0.0023)
      ctx.setMetadata({ model: 'gpt-4' })
      return result
    })

    expect(mockTransport).toHaveBeenCalled()
    const traceData = mockTransport.mock.calls[0][0]
    expect(traceData.output).toBe('processed result')
    expect(traceData.cost_usd).toBe(0.0023)
    expect(traceData.metadata.model).toBe('gpt-4')
  })
})
```

**Integration Tests:**
```python
# tests/integration/test_sdk_to_platform.py
import pytest
from agent_observability import AgentObservability
import requests
import time

@pytest.mark.integration
def test_sdk_sends_trace_to_platform():
    """Test full flow: SDK → Gateway → Ingestion → Processing → Database"""

    # Initialize SDK with real endpoint
    obs = AgentObservability(
        api_key="test-api-key",
        workspace_id="37160be9-7d69-43b5-8d5f-9d7b5e14a57a",
        base_url="http://localhost:8000"
    )

    # Use decorator to capture trace
    @obs.trace(agent_id="integration-test-agent")
    def test_function(x: int) -> int:
        return x * 2

    result = test_function(42)
    assert result == 84

    # Wait for async processing
    time.sleep(3)

    # Verify trace appears in database via Query API
    response = requests.get(
        "http://localhost:8003/api/v1/traces",
        headers={"X-Workspace-ID": "37160be9-7d69-43b5-8d5f-9d7b5e14a57a"},
        params={"agent_id": "integration-test-agent", "limit": 1}
    )

    assert response.status_code == 200
    traces = response.json()['data']
    assert len(traces) > 0
    assert traces[0]['agent_id'] == 'integration-test-agent'
    assert traces[0]['input'] == '42'
    assert traces[0]['output'] == '84'
```

---

### 8. sdk-documentation-writer (Conceptual Guide)

**Purpose:** Create comprehensive, developer-friendly documentation for SDKs

**Documentation Structure:**

**Python SDK README.md:**
```markdown
# Agent Observability Python SDK

[![PyPI version](https://badge.fury.io/py/agent-observability.svg)](https://badge.fury.io/py/agent-observability)
[![Tests](https://github.com/yourorg/agent-observability-python/workflows/Tests/badge.svg)](https://github.com/yourorg/agent-observability-python/actions)

Instrument your AI agents with just 2 lines of code.

## Installation

```bash
pip install agent-observability
```

## Quick Start

```python
from agent_observability import AgentObservability

# Initialize (use your API key from Settings page)
obs = AgentObservability(
    api_key="your-api-key",
    workspace_id="your-workspace-id"
)

# Option 1: Decorator (automatic capture)
@obs.trace(agent_id="support-bot")
def handle_customer_query(user_input: str) -> str:
    response = call_llm(user_input)
    return response

# Option 2: Context manager (manual control)
with obs.trace_context(agent_id="support-bot") as ctx:
    response = call_llm(user_input)
    ctx.set_output(response)
    ctx.set_cost(0.0023)
    ctx.set_metadata({"model": "gpt-4-turbo"})
```

## Features

- ✅ **Zero-overhead instrumentation** - Async, non-blocking
- ✅ **Automatic trace capture** - Input, output, latency, errors
- ✅ **Framework agnostic** - Works with Flask, FastAPI, Django
- ✅ **Async support** - Full async/await compatibility
- ✅ **Type-safe** - Full type hints with Pydantic
- ✅ **Batching** - Efficient batch sending
- ✅ **Error resilience** - Never breaks your code

## Framework Integrations

### FastAPI
```python
from fastapi import FastAPI
from agent_observability import AgentObservability

app = FastAPI()
obs = AgentObservability(api_key="...", workspace_id="...")

@app.post("/chat")
@obs.trace(agent_id="chat-bot")
async def chat_endpoint(message: str):
    response = await process_chat(message)
    return {"response": response}
```

### Flask
```python
from flask import Flask, request
from agent_observability import AgentObservability

app = Flask(__name__)
obs = AgentObservability(api_key="...", workspace_id="...")

@app.route("/chat", methods=["POST"])
@obs.trace(agent_id="chat-bot")
def chat_endpoint():
    message = request.json["message"]
    response = process_chat(message)
    return {"response": response}
```

## API Reference

### AgentObservability

**Constructor:**
```python
AgentObservability(
    api_key: str,              # Required: Your API key
    workspace_id: str,         # Required: Your workspace ID
    base_url: str = "...",     # Optional: Custom API endpoint
    batch_size: int = 10,      # Optional: Traces per batch
    flush_interval: float = 5.0 # Optional: Seconds between flushes
)
```

**Methods:**

`@trace(agent_id: str, tags: List[str] = None, metadata: Dict = None)`
- Decorator for automatic trace capture
- Captures input, output, latency, status automatically

`trace_context(agent_id: str, **kwargs) -> TraceContext`
- Context manager for manual trace control
- Provides methods: `set_output()`, `set_cost()`, `set_metadata()`, etc.

## Configuration

Set environment variables (optional):
```bash
export AGENT_OBS_API_KEY="your-api-key"
export AGENT_OBS_WORKSPACE_ID="your-workspace-id"
export AGENT_OBS_BASE_URL="http://localhost:8000"  # Development
```

## Troubleshooting

**Traces not appearing in dashboard?**
- Check API key is valid (Settings → API Keys)
- Verify workspace ID is correct
- Enable debug mode: `obs.enable_debug()`
- Check network connectivity to platform

**High latency?**
- SDK sends traces asynchronously in background
- Adjust `batch_size` and `flush_interval` if needed
- Monitor with: `obs.get_stats()`

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

MIT License - see [LICENSE](LICENSE)
```

**TypeScript SDK README.md:**
```markdown
# Agent Observability TypeScript SDK

[![npm version](https://badge.fury.io/js/@agent-observability%2Fsdk.svg)](https://www.npmjs.com/package/@agent-observability/sdk)
[![Tests](https://github.com/yourorg/agent-observability-ts/workflows/Tests/badge.svg)](https://github.com/yourorg/agent-observability-ts/actions)

Instrument your AI agents with type-safe TypeScript support.

## Installation

```bash
npm install @agent-observability/sdk
# or
yarn add @agent-observability/sdk
# or
pnpm add @agent-observability/sdk
```

## Quick Start

```typescript
import { AgentObservability } from '@agent-observability/sdk'

// Initialize
const obs = new AgentObservability({
  apiKey: 'your-api-key',
  workspaceId: 'your-workspace-id'
})

// Option 1: Decorator
class SupportBot {
  @obs.trace({ agentId: 'support-bot' })
  async handleQuery(input: string): Promise<string> {
    const response = await callLLM(input)
    return response
  }
}

// Option 2: Manual trace
await obs.trace('support-bot', async (ctx) => {
  const response = await callLLM(input)
  ctx.setOutput(response)
  ctx.setCost(0.0023)
  ctx.setMetadata({ model: 'gpt-4-turbo' })
  return response
})
```

## Features

- ✅ **Type-safe** - Full TypeScript support
- ✅ **Async/await** - Promise-based API
- ✅ **Framework agnostic** - Express, Next.js, NestJS
- ✅ **Decorator support** - Clean, declarative syntax
- ✅ **Zero dependencies** - Uses native fetch
- ✅ **Tree-shakeable** - Optimized bundle size

## Framework Integrations

### Express
```typescript
import express from 'express'
import { AgentObservability } from '@agent-observability/sdk'

const app = express()
const obs = new AgentObservability({ apiKey: '...', workspaceId: '...' })

app.post('/chat', async (req, res) => {
  await obs.trace('chat-bot', async (ctx) => {
    const response = await processChat(req.body.message)
    ctx.setOutput(response)
    res.json({ response })
  })
})
```

### Next.js API Routes
```typescript
import { NextRequest, NextResponse } from 'next/server'
import { AgentObservability } from '@agent-observability/sdk'

const obs = new AgentObservability({ apiKey: '...', workspaceId: '...' })

export async function POST(request: NextRequest) {
  return await obs.trace('chat-bot', async (ctx) => {
    const { message } = await request.json()
    const response = await processChat(message)
    ctx.setOutput(response)
    return NextResponse.json({ response })
  })
}
```

## API Reference

See [API.md](docs/API.md) for complete documentation.

## Examples

Check out the [examples](examples/) directory:
- [Express example](examples/express/)
- [Next.js example](examples/nextjs/)
- [NestJS example](examples/nestjs/)

## License

MIT License
```

---

## Phase 5 Implementation Workflow

This section provides a detailed week-by-week implementation guide for Phase 5.

### Week 1: Settings Page Implementation

#### Day 1-2: Database Design & APIs

**Step 1: Design Database Tables**

Invoke the `fullstack-database-designer` agent:
```
Prompt: "Design database tables for Phase 5 Settings page:
1. team_members table - workspace members with roles
2. billing_config table - subscription plans and usage limits
3. integrations_config table - Slack, PagerDuty, webhook configurations

Requirements:
- Workspace isolation (workspace_id foreign key)
- Role-based access (owner, admin, member, viewer)
- Audit trails (created_at, updated_at)
- Soft deletes for team members"
```

Expected Output:
- CREATE TABLE statements for 3 new tables
- Appropriate indexes
- Foreign key constraints
- Migration script (Alembic)

**Step 2: Design Settings APIs**

Invoke the `fullstack-api-designer` agent:
```
Prompt: "Design REST APIs for Settings page with 5 sections:

1. General Settings:
   - GET/PUT /api/v1/workspace - Workspace name, description, timezone

2. Team Management:
   - GET /api/v1/team/members - List team members
   - POST /api/v1/team/invite - Invite new member
   - PUT /api/v1/team/members/:id/role - Update role
   - DELETE /api/v1/team/members/:id - Remove member

3. API Keys:
   - GET /api/v1/api-keys - List keys (already exists in gateway)
   - POST /api/v1/api-keys - Create key (already exists)
   - DELETE /api/v1/api-keys/:id - Revoke key (already exists)

4. Billing:
   - GET /api/v1/billing/config - Get plan and limits
   - PUT /api/v1/billing/config - Update plan
   - GET /api/v1/billing/usage - Current usage stats

5. Integrations:
   - GET /api/v1/integrations - List all integrations
   - PUT /api/v1/integrations/slack - Configure Slack
   - PUT /api/v1/integrations/pagerduty - Configure PagerDuty
   - PUT /api/v1/integrations/webhook - Configure webhooks
   - POST /api/v1/integrations/:type/test - Test integration

Include request/response schemas, error handling, and caching strategies."
```

Expected Output:
- Complete API specification document
- Pydantic models for requests/responses
- Error response schemas
- Cache TTL recommendations

**Step 3: Implement Backend Service**

Options for implementation:
- Option A: Extend Gateway service (recommended for simplicity)
- Option B: Create new Settings service (Port 8008)

Recommended: **Extend Gateway Service**

Create new routes in Gateway:
```
backend/gateway/app/routes/
├── workspace.py        # General settings
├── team.py            # Team management
├── billing.py         # Billing configuration
└── integrations.py    # Integration management
```

Implementation pattern (follow existing services):
```python
# backend/gateway/app/routes/workspace.py
from fastapi import APIRouter, Depends, HTTPException
from app.models import WorkspaceUpdate, WorkspaceResponse
from app.database import get_db
from app.auth import get_current_user

router = APIRouter(prefix="/api/v1/workspace", tags=["workspace"])

@router.get("", response_model=WorkspaceResponse)
async def get_workspace(
    workspace_id: str = Depends(get_workspace_id),
    db = Depends(get_db)
):
    """Get workspace configuration"""
    # Implementation here
    pass

@router.put("", response_model=WorkspaceResponse)
async def update_workspace(
    data: WorkspaceUpdate,
    workspace_id: str = Depends(get_workspace_id),
    user = Depends(get_current_user),
    db = Depends(get_db)
):
    """Update workspace configuration"""
    # Validate user has admin/owner role
    # Update database
    # Invalidate cache
    # Return updated workspace
    pass
```

#### Day 3-4: Frontend Implementation

**Step 1: Create Settings Page Structure**

Create new page:
```bash
frontend/app/dashboard/settings/page.tsx
```

Implement tab-based layout (reference: settings-ui-builder guide above):
```typescript
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'

export default function SettingsPage() {
  return (
    <div className="container mx-auto py-8">
      <h1 className="text-3xl font-bold mb-6">Settings</h1>

      <Tabs defaultValue="general" className="w-full">
        <TabsList className="grid w-full grid-cols-5">
          <TabsTrigger value="general">General</TabsTrigger>
          <TabsTrigger value="team">Team</TabsTrigger>
          <TabsTrigger value="api-keys">API Keys</TabsTrigger>
          <TabsTrigger value="billing">Billing</TabsTrigger>
          <TabsTrigger value="integrations">Integrations</TabsTrigger>
        </TabsList>

        <TabsContent value="general">
          <GeneralSettings />
        </TabsContent>

        {/* Additional tabs */}
      </Tabs>
    </div>
  )
}
```

**Step 2: Implement Each Tab**

Create components:
```
frontend/components/settings/
├── GeneralSettings.tsx     # Workspace name, description, timezone
├── TeamSettings.tsx        # Team members table + invite dialog
├── APIKeysSettings.tsx     # API keys table + create dialog
├── BillingSettings.tsx     # Plan info + usage stats
└── IntegrationsSettings.tsx # Integration configs + test buttons
```

Use React Hook Form + Zod for validation:
```typescript
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'

const schema = z.object({
  workspace_name: z.string().min(3).max(100),
  // ... other fields
})

export function GeneralSettings() {
  const form = useForm({
    resolver: zodResolver(schema),
  })

  const onSubmit = async (data) => {
    // API call
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      {/* Form fields */}
    </form>
  )
}
```

Use TanStack Query for data fetching:
```typescript
const { data: workspace, isLoading } = useQuery({
  queryKey: ['workspace'],
  queryFn: () => apiClient.get('/api/v1/workspace'),
})

const updateMutation = useMutation({
  mutationFn: (data) => apiClient.put('/api/v1/workspace', data),
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ['workspace'] })
    toast({ title: 'Settings saved successfully' })
  },
})
```

#### Day 5: Testing

**Step 1: Backend Tests**

Create test file:
```python
# backend/gateway/tests/test_settings.py
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_get_workspace(client: AsyncClient, auth_headers):
    response = await client.get(
        "/api/v1/workspace",
        headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert 'workspace_name' in data

@pytest.mark.asyncio
async def test_update_workspace(client: AsyncClient, auth_headers):
    response = await client.put(
        "/api/v1/workspace",
        headers=auth_headers,
        json={"workspace_name": "Updated Workspace"}
    )
    assert response.status_code == 200
    assert response.json()['workspace_name'] == 'Updated Workspace'

# Additional tests for team, billing, integrations
```

**Step 2: Frontend Tests**

Create test file:
```typescript
// frontend/__tests__/settings.test.tsx
import { render, screen, waitFor } from '@testing-library/react'
import { SettingsPage } from '@/app/dashboard/settings/page'

describe('Settings Page', () => {
  it('renders all tabs', () => {
    render(<SettingsPage />)
    expect(screen.getByText('General')).toBeInTheDocument()
    expect(screen.getByText('Team')).toBeInTheDocument()
    expect(screen.getByText('API Keys')).toBeInTheDocument()
    expect(screen.getByText('Billing')).toBeInTheDocument()
    expect(screen.getByText('Integrations')).toBeInTheDocument()
  })

  it('saves general settings', async () => {
    // Test implementation
  })
})
```

---

### Week 2: SDK Development

#### Day 1-2: SDK Architecture & Design

**Step 1: Create SDK Project Structures**

**Python SDK:**
```bash
mkdir -p python-sdk/agent_observability
mkdir -p python-sdk/tests
mkdir -p python-sdk/examples

# File structure
python-sdk/
├── agent_observability/
│   ├── __init__.py
│   ├── client.py
│   ├── decorators.py
│   ├── context.py
│   ├── models.py
│   ├── transport.py
│   ├── config.py
│   └── exceptions.py
├── tests/
│   ├── test_client.py
│   ├── test_decorators.py
│   ├── test_context.py
│   └── conftest.py
├── examples/
│   ├── flask_app.py
│   ├── fastapi_app.py
│   └── basic.py
├── setup.py
├── pyproject.toml
├── README.md
└── LICENSE
```

**TypeScript SDK:**
```bash
mkdir -p typescript-sdk/src
mkdir -p typescript-sdk/tests
mkdir -p typescript-sdk/examples

# File structure
typescript-sdk/
├── src/
│   ├── index.ts
│   ├── client.ts
│   ├── decorators.ts
│   ├── context.ts
│   ├── models.ts
│   ├── transport.ts
│   ├── config.ts
│   └── errors.ts
├── tests/
│   ├── client.test.ts
│   ├── decorators.test.ts
│   └── context.test.ts
├── examples/
│   ├── express.ts
│   ├── nextjs.ts
│   └── basic.ts
├── package.json
├── tsconfig.json
├── README.md
└── LICENSE
```

**Step 2: Implement Core SDK Functionality**

Follow the patterns outlined in the "sdk-architect" guide above.

**Key implementations:**

1. **HTTP Transport Layer:**
```python
# Python: agent_observability/transport.py
import httpx
from typing import Dict, Any
import asyncio

class Transport:
    def __init__(self, base_url: str, api_key: str, workspace_id: str):
        self.base_url = base_url
        self.api_key = api_key
        self.workspace_id = workspace_id
        self.client = httpx.AsyncClient(timeout=10.0)
        self._batch = []
        self._batch_size = 10
        self._lock = asyncio.Lock()

    async def send_trace(self, trace_data: Dict[str, Any]):
        """Send single trace (batches internally)"""
        async with self._lock:
            self._batch.append(trace_data)
            if len(self._batch) >= self._batch_size:
                await self._flush()

    async def _flush(self):
        """Send batch of traces"""
        if not self._batch:
            return

        try:
            response = await self.client.post(
                f"{self.base_url}/api/v1/traces/batch",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "X-Workspace-ID": self.workspace_id,
                    "Content-Type": "application/json"
                },
                json={"traces": self._batch}
            )
            response.raise_for_status()
            self._batch = []
        except Exception as e:
            # Log error but don't fail user code
            print(f"Agent Observability SDK Error: {e}")
```

2. **Decorator Implementation:**
```python
# Python: agent_observability/decorators.py
from functools import wraps
import time
import uuid
from datetime import datetime
from typing import Callable, Any

def trace(self, agent_id: str, tags: list = None, metadata: dict = None):
    """Decorator for automatic trace capture"""
    def decorator(func: Callable) -> Callable:
        if asyncio.iscoroutinefunction(func):
            @wraps(func)
            async def async_wrapper(*args, **kwargs) -> Any:
                trace_id = str(uuid.uuid4())
                start_time = time.time()

                trace_data = {
                    "trace_id": trace_id,
                    "agent_id": agent_id,
                    "workspace_id": self.workspace_id,
                    "timestamp": datetime.utcnow().isoformat(),
                    "input": str(args[0]) if args else "",
                    "tags": tags or [],
                    "metadata": metadata or {},
                }

                try:
                    result = await func(*args, **kwargs)
                    trace_data["output"] = str(result)
                    trace_data["status"] = "success"
                    return result
                except Exception as e:
                    trace_data["status"] = "error"
                    trace_data["metadata"]["error"] = str(e)
                    raise
                finally:
                    trace_data["latency_ms"] = int((time.time() - start_time) * 1000)
                    await self._transport.send_trace(trace_data)

            return async_wrapper
        else:
            @wraps(func)
            def sync_wrapper(*args, **kwargs) -> Any:
                # Similar implementation for sync functions
                pass
            return sync_wrapper
    return decorator
```

3. **Context Manager:**
```python
# Python: agent_observability/context.py
from contextlib import asynccontextmanager
import time
import uuid
from datetime import datetime

class TraceContext:
    def __init__(self, agent_id: str, transport, workspace_id: str):
        self.trace_id = str(uuid.uuid4())
        self.agent_id = agent_id
        self.workspace_id = workspace_id
        self._transport = transport
        self._data = {
            "trace_id": self.trace_id,
            "agent_id": agent_id,
            "workspace_id": workspace_id,
            "timestamp": datetime.utcnow().isoformat(),
            "metadata": {},
        }
        self._start_time = time.time()

    def set_output(self, output: str):
        self._data["output"] = output

    def set_cost(self, cost_usd: float):
        self._data["cost_usd"] = cost_usd

    def set_metadata(self, metadata: dict):
        self._data["metadata"].update(metadata)

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        self._data["latency_ms"] = int((time.time() - self._start_time) * 1000)
        if exc_type:
            self._data["status"] = "error"
            self._data["metadata"]["error"] = str(exc_val)
        else:
            self._data["status"] = "success"

        await self._transport.send_trace(self._data)
```

**TypeScript implementations** should follow similar patterns with TypeScript-specific idioms.

#### Day 3-4: SDK Examples & Documentation

**Step 1: Create Example Applications**

**Flask Example:**
```python
# python-sdk/examples/flask_app.py
from flask import Flask, request, jsonify
from agent_observability import AgentObservability
import os

app = Flask(__name__)
obs = AgentObservability(
    api_key=os.getenv("AGENT_OBS_API_KEY"),
    workspace_id=os.getenv("AGENT_OBS_WORKSPACE_ID")
)

@app.route("/chat", methods=["POST"])
@obs.trace(agent_id="flask-chat-bot")
def chat_endpoint():
    message = request.json["message"]
    response = f"Echo: {message}"  # Simulate LLM call
    return jsonify({"response": response})

if __name__ == "__main__":
    app.run(port=5000)
```

**FastAPI Example:**
```python
# python-sdk/examples/fastapi_app.py
from fastapi import FastAPI
from agent_observability import AgentObservability
import os

app = FastAPI()
obs = AgentObservability(
    api_key=os.getenv("AGENT_OBS_API_KEY"),
    workspace_id=os.getenv("AGENT_OBS_WORKSPACE_ID")
)

@app.post("/chat")
@obs.trace(agent_id="fastapi-chat-bot")
async def chat_endpoint(message: str):
    response = f"Echo: {message}"  # Simulate LLM call
    return {"response": response}
```

**Express Example:**
```typescript
// typescript-sdk/examples/express.ts
import express from 'express'
import { AgentObservability } from '@agent-observability/sdk'

const app = express()
app.use(express.json())

const obs = new AgentObservability({
  apiKey: process.env.AGENT_OBS_API_KEY!,
  workspaceId: process.env.AGENT_OBS_WORKSPACE_ID!
})

app.post('/chat', async (req, res) => {
  await obs.trace('express-chat-bot', async (ctx) => {
    const { message } = req.body
    const response = `Echo: ${message}` // Simulate LLM call
    ctx.setOutput(response)
    res.json({ response })
  })
})

app.listen(3000, () => console.log('Server running on port 3000'))
```

**Step 2: Create Documentation**

Follow the documentation templates in the "sdk-documentation-writer" guide above.

Create:
- `python-sdk/README.md` - Comprehensive Python SDK docs
- `typescript-sdk/README.md` - Comprehensive TypeScript SDK docs
- `python-sdk/docs/API.md` - Detailed API reference
- `typescript-sdk/docs/API.md` - Detailed API reference

#### Day 5: Testing & Integration

**Step 1: Unit Tests**

Invoke `sdk-integration-tester` conceptual patterns:

**Python SDK Tests:**
```bash
cd python-sdk
pytest tests/ -v
```

Expected: 9+ tests passing

**TypeScript SDK Tests:**
```bash
cd typescript-sdk
npm test
```

Expected: 9+ tests passing

**Step 2: Integration Tests**

Create integration test:
```python
# backend/tests/test_sdk_integration.py
import pytest
from agent_observability import AgentObservability
import time
import requests

@pytest.mark.integration
def test_python_sdk_to_platform():
    """Test: Python SDK → Platform → Database"""
    obs = AgentObservability(
        api_key="test-key",
        workspace_id="37160be9-7d69-43b5-8d5f-9d7b5e14a57a",
        base_url="http://localhost:8000"
    )

    @obs.trace(agent_id="integration-test")
    def test_func(x: int) -> int:
        return x * 2

    result = test_func(42)
    assert result == 84

    time.sleep(3)  # Wait for processing

    # Verify in database
    response = requests.get(
        "http://localhost:8003/api/v1/traces",
        headers={"X-Workspace-ID": "37160be9-7d69-43b5-8d5f-9d7b5e14a57a"},
        params={"agent_id": "integration-test", "limit": 1}
    )

    assert response.status_code == 200
    traces = response.json()['data']
    assert len(traces) > 0
    assert traces[0]['input'] == '42'
    assert traces[0]['output'] == '84'
```

**Step 3: Package Publishing (Optional)**

**Python:**
```bash
cd python-sdk
python setup.py sdist bdist_wheel
twine upload dist/*
```

**TypeScript:**
```bash
cd typescript-sdk
npm run build
npm publish --access public
```

---

## Code Patterns & Standards

This section documents established patterns from Phases 0-4 that must be followed in Phase 5.

### Backend Service Patterns

**1. FastAPI Service Structure:**
```
backend/[service]/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app
│   ├── config.py            # Settings from env
│   ├── database.py          # DB connections
│   ├── models.py            # Pydantic models
│   ├── routes/
│   │   └── [feature].py     # API endpoints
│   └── [feature modules]/
├── tests/
│   ├── test_[feature].py
│   └── conftest.py
├── Dockerfile
├── requirements.txt
└── pytest.ini
```

**2. API Endpoint Pattern:**
```python
from fastapi import APIRouter, Depends, HTTPException, Header
from app.models import RequestModel, ResponseModel
from app.database import get_db
from typing import Optional

router = APIRouter(prefix="/api/v1/[resource]", tags=["resource"])

@router.get("", response_model=ResponseModel)
async def get_resource(
    workspace_id: str = Header(..., alias="X-Workspace-ID"),
    range: str = "24h",
    db = Depends(get_db)
):
    """Get resource with workspace isolation"""
    try:
        # Query with workspace filter
        query = """
            SELECT * FROM resources
            WHERE workspace_id = $1
            LIMIT 100
        """
        result = await db.fetch(query, workspace_id)
        return {"data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

**3. Database Connection Pattern:**
```python
# database.py
import asyncpg
from contextlib import asynccontextmanager

class Database:
    def __init__(self, url: str):
        self.url = url
        self.pool = None

    async def connect(self):
        self.pool = await asyncpg.create_pool(
            self.url,
            min_size=5,
            max_size=20,
            command_timeout=60
        )

    async def disconnect(self):
        if self.pool:
            await self.pool.close()

    async def fetch(self, query: str, *args):
        async with self.pool.acquire() as conn:
            return await conn.fetch(query, *args)
```

**4. Redis Caching Pattern:**
```python
import redis.asyncio as redis
import json

class Cache:
    def __init__(self, url: str):
        self.client = redis.from_url(url)

    async def get(self, key: str):
        value = await self.client.get(key)
        return json.loads(value) if value else None

    async def set(self, key: str, value, ttl: int = 300):
        await self.client.setex(key, ttl, json.dumps(value))

    async def delete(self, pattern: str):
        keys = await self.client.keys(pattern)
        if keys:
            await self.client.delete(*keys)
```

**5. Pydantic Model Pattern:**
```python
from pydantic import BaseModel, Field, UUID4
from datetime import datetime
from typing import Optional, List

class TraceBase(BaseModel):
    trace_id: str = Field(..., description="Unique trace identifier")
    agent_id: str = Field(..., description="Agent identifier")
    workspace_id: UUID4
    timestamp: datetime
    input: str
    output: str
    latency_ms: int
    status: str  # 'success', 'error', 'timeout'

    class Config:
        json_schema_extra = {
            "example": {
                "trace_id": "trace_abc123",
                "agent_id": "support-bot",
                "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
                "timestamp": "2025-10-25T10:00:00Z",
                "input": "Hello",
                "output": "Hi there!",
                "latency_ms": 1234,
                "status": "success"
            }
        }
```

**6. Error Handling Pattern:**
```python
from fastapi import HTTPException
import logging

logger = logging.getLogger(__name__)

async def endpoint_with_error_handling():
    try:
        # Business logic
        pass
    except ValueError as e:
        logger.error(f"Validation error: {e}")
        raise HTTPException(
            status_code=400,
            detail={"error": "INVALID_INPUT", "message": str(e)}
        )
    except Exception as e:
        logger.exception("Unexpected error")
        raise HTTPException(
            status_code=500,
            detail={"error": "INTERNAL_ERROR", "message": "An unexpected error occurred"}
        )
```

### Frontend Component Patterns

**1. Page Structure:**
```typescript
// app/dashboard/[page]/page.tsx
'use client'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { useWorkspace } from '@/contexts/WorkspaceContext'

export default function PageName() {
  const { workspaceId } = useWorkspace()

  const { data, isLoading, error } = useQuery({
    queryKey: ['page-data', workspaceId],
    queryFn: () => apiClient.get('/api/v1/endpoint'),
    refetchInterval: 30000, // Auto-refresh every 30s
  })

  if (isLoading) return <LoadingState />
  if (error) return <ErrorState error={error} />

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">Page Title</h1>
      {/* Content */}
    </div>
  )
}
```

**2. shadcn/ui Component Usage:**
```typescript
// KPI Card example
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { TrendingUp, TrendingDown } from 'lucide-react'

export function KPICard({ title, value, change, trend }) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium">
          {title}
        </CardTitle>
        <Badge variant={change > 0 ? "default" : "secondary"}>
          {change > 0 ? <TrendingUp className="h-3 w-3" /> : <TrendingDown className="h-3 w-3" />}
        </Badge>
      </CardHeader>
      <CardContent>
        <div className="text-3xl font-bold">{value}</div>
        <p className="text-xs text-muted-foreground">
          {change > 0 ? '+' : ''}{change}% from last period
        </p>
      </CardContent>
    </Card>
  )
}
```

**3. API Client Pattern:**
```typescript
// lib/api-client.ts
import axios from 'axios'

const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
  timeout: 10000,
})

// Add workspace ID to all requests
apiClient.interceptors.request.use((config) => {
  const workspaceId = localStorage.getItem('workspaceId')
  if (workspaceId) {
    config.headers['X-Workspace-ID'] = workspaceId
  }
  return config
})

// Handle errors globally
apiClient.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response?.status === 401) {
      // Redirect to login
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default apiClient
```

**4. Form Handling Pattern:**
```typescript
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'

const formSchema = z.object({
  name: z.string().min(3).max(100),
  email: z.string().email(),
})

export function FormComponent() {
  const form = useForm({
    resolver: zodResolver(formSchema),
    defaultValues: {
      name: '',
      email: '',
    },
  })

  const onSubmit = async (data) => {
    try {
      await apiClient.post('/api/v1/endpoint', data)
      toast({ title: 'Success' })
    } catch (error) {
      toast({ title: 'Error', variant: 'destructive' })
    }
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      <Input {...form.register('name')} />
      {form.formState.errors.name && (
        <p className="text-red-500">{form.formState.errors.name.message}</p>
      )}
      <Button type="submit">Submit</Button>
    </form>
  )
}
```

### Testing Patterns

**1. Backend Test Pattern:**
```python
# tests/test_feature.py
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.fixture
async def client():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest.fixture
def auth_headers():
    return {
        "X-Workspace-ID": "37160be9-7d69-43b5-8d5f-9d7b5e14a57a"
    }

@pytest.mark.asyncio
async def test_endpoint_success(client: AsyncClient, auth_headers):
    response = await client.get(
        "/api/v1/endpoint",
        headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert 'data' in data

@pytest.mark.asyncio
async def test_endpoint_validation_error(client: AsyncClient, auth_headers):
    response = await client.post(
        "/api/v1/endpoint",
        headers=auth_headers,
        json={"invalid": "data"}
    )
    assert response.status_code == 400
```

**2. Frontend Test Pattern:**
```typescript
// __tests__/component.test.tsx
import { render, screen, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import Component from '@/components/Component'

const queryClient = new QueryClient()

const renderWithProviders = (ui: React.ReactElement) => {
  return render(
    <QueryClientProvider client={queryClient}>
      {ui}
    </QueryClientProvider>
  )
}

describe('Component', () => {
  it('renders successfully', () => {
    renderWithProviders(<Component />)
    expect(screen.getByText('Component Title')).toBeInTheDocument()
  })

  it('fetches and displays data', async () => {
    renderWithProviders(<Component />)
    await waitFor(() => {
      expect(screen.getByText('Data Value')).toBeInTheDocument()
    })
  })
})
```

---

## Testing Strategies

### Test Categories

**1. Unit Tests**
- Test individual functions/methods
- Mock external dependencies
- Fast execution (< 5 seconds total)
- 80%+ code coverage target

**2. Integration Tests**
- Test service interactions
- Use real database connections (test database)
- Test Redis integration
- Verify end-to-end flows

**3. End-to-End Tests (Future Phase 6)**
- Test user workflows
- Real browser automation (Playwright)
- Production-like environment

### Phase 5 Test Requirements

**Settings Page Tests (5 tests):**
1. Test workspace update (general settings)
2. Test team member invitation
3. Test API key creation
4. Test billing configuration update
5. Test integration configuration (Slack/webhook)

**Python SDK Tests (9 tests):**
1. Test decorator captures input/output
2. Test decorator with async functions
3. Test context manager manual control
4. Test batching functionality
5. Test error handling (SDK errors don't break user code)
6. Test retry logic
7. Test configuration
8. Test Flask integration
9. Test FastAPI integration

**TypeScript SDK Tests (9 tests):**
1. Test decorator captures input/output
2. Test decorator with promises
3. Test manual trace control
4. Test batching functionality
5. Test error handling
6. Test retry logic
7. Test configuration
8. Test Express integration
9. Test Next.js integration

**Integration Tests (3 tests):**
1. Test Python SDK → Platform → Database
2. Test TypeScript SDK → Platform → Database
3. Test Settings API → Database → Frontend

### Running Tests

**Backend:**
```bash
# All backend tests
cd backend
pytest -v

# Specific service
pytest gateway/tests/ -v

# With coverage
pytest --cov=app --cov-report=html
```

**Frontend:**
```bash
# All frontend tests
cd frontend
npm test

# Watch mode
npm test -- --watch

# Coverage
npm test -- --coverage
```

**Integration (requires running services):**
```bash
# Start services
docker-compose up -d

# Run integration tests
pytest backend/tests/integration/ -v -m integration
```

---

## Success Criteria

Phase 5 is complete when all of the following criteria are met:

### Functional Requirements

**Settings Page:**
- ✅ All 5 tabs render correctly
- ✅ General settings can be updated (workspace name, timezone)
- ✅ Team members can be invited, roles changed, members removed
- ✅ API keys can be created, copied, revoked
- ✅ Billing configuration displays correctly
- ✅ Integrations can be configured and tested

**Python SDK:**
- ✅ Package installable via `pip install agent-observability`
- ✅ Decorator captures traces automatically
- ✅ Context manager provides manual control
- ✅ Async/await fully supported
- ✅ Works with Flask and FastAPI
- ✅ Error resilience (SDK errors don't break user code)
- ✅ Batching and flushing work correctly

**TypeScript SDK:**
- ✅ Package installable via `npm install @agent-observability/sdk`
- ✅ Decorator captures traces automatically
- ✅ Manual trace control via trace() function
- ✅ Promise-based API
- ✅ Works with Express and Next.js
- ✅ Error resilience
- ✅ Batching and flushing work correctly

### Testing Requirements

- ✅ 5/5 Settings page tests passing
- ✅ 9/9 Python SDK tests passing
- ✅ 9/9 TypeScript SDK tests passing
- ✅ 3/3 Integration tests passing
- ✅ **Total: 26/26 tests passing**

### Code Quality

- ✅ All code follows established patterns
- ✅ Type safety (Pydantic for Python, TypeScript for TS)
- ✅ Async/await for all I/O operations
- ✅ Comprehensive error handling
- ✅ Clear, readable code
- ✅ Consistent style

### Documentation

- ✅ Settings page APIs documented
- ✅ Python SDK README.md complete
- ✅ TypeScript SDK README.md complete
- ✅ Example applications for both SDKs
- ✅ API reference documentation

### Performance

- ✅ Settings APIs respond in < 100ms (P95)
- ✅ SDK decorator overhead < 1ms
- ✅ SDK batching reduces network calls
- ✅ No memory leaks in SDKs

### Deployment

- ✅ Settings backend deployed (gateway extended or new service)
- ✅ Frontend Settings page accessible at /dashboard/settings
- ✅ Python SDK published to PyPI (optional)
- ✅ TypeScript SDK published to NPM (optional)

---

## Appendix

### Useful Commands

**Docker:**
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f [service]

# Restart service
docker-compose restart [service]

# Rebuild service
docker-compose build --no-cache [service]
docker-compose up -d --force-recreate [service]

# Stop all
docker-compose down
```

**Database:**
```bash
# Connect to TimescaleDB
docker-compose exec timescaledb psql -U postgres -d agent_observability

# Connect to PostgreSQL
docker-compose exec postgres psql -U postgres -d agent_observability_metadata

# Run migration
cd backend
alembic upgrade head
```

**Testing:**
```bash
# Backend unit tests
pytest backend/[service]/tests/ -v

# Backend integration tests
pytest backend/tests/integration/ -v -m integration

# Frontend tests
cd frontend && npm test

# E2E tests (Phase 6)
cd e2e && npx playwright test
```

### Environment Variables

**Phase 5 Additions:**
```bash
# .env
# ... existing variables ...

# Settings Service (if separate service created)
SETTINGS_PORT=8008

# SDK Testing
AGENT_OBS_API_KEY=test-api-key
AGENT_OBS_WORKSPACE_ID=37160be9-7d69-43b5-8d5f-9d7b5e14a57a
AGENT_OBS_BASE_URL=http://localhost:8000
```

### File Structure Reference

**Backend:**
```
backend/
├── gateway/          # Port 8000 (extended with Settings APIs)
├── ingestion/        # Port 8001
├── processing/       # Background
├── query/            # Port 8003
├── evaluation/       # Port 8004
├── guardrail/        # Port 8005
├── alert/            # Port 8006
├── gemini/           # Port 8007
├── db/               # Database scripts
└── tests/            # Integration tests
```

**Frontend:**
```
frontend/
├── app/
│   ├── dashboard/
│   │   ├── page.tsx              # Home
│   │   ├── usage/page.tsx        # Usage Analytics
│   │   ├── cost/page.tsx         # Cost Management
│   │   ├── performance/page.tsx  # Performance
│   │   ├── quality/page.tsx      # Quality
│   │   ├── safety/page.tsx       # Safety
│   │   ├── impact/page.tsx       # Impact
│   │   └── settings/page.tsx     # Settings (Phase 5)
│   ├── login/page.tsx
│   └── register/page.tsx
├── components/
│   ├── ui/                       # shadcn/ui components
│   ├── dashboard/                # Dashboard components
│   └── settings/                 # Settings components (Phase 5)
└── lib/
    ├── api-client.ts
    └── utils.ts
```

**SDKs:**
```
python-sdk/
├── agent_observability/
├── tests/
├── examples/
└── README.md

typescript-sdk/
├── src/
├── tests/
├── examples/
└── README.md
```

---

## Quick Reference

### Most Common Sub-Agent Invocations

**API Design:**
```
Task tool with subagent_type: "fullstack-api-designer"
Prompt: "Design APIs for [feature] with [requirements]"
```

**Database Design:**
```
Task tool with subagent_type: "fullstack-database-designer"
Prompt: "Design database tables for [feature] with [constraints]"
```

**Testing:**
```
Task tool with subagent_type: "fullstack-integration-tester"
Prompt: "Create comprehensive tests for [feature]"
```

**Codebase Exploration:**
```
Task tool with subagent_type: "Explore"
Prompt: "Explore [aspect] in codebase, thoroughness: [quick|medium|very thorough]"
```

### Common API Patterns

**Workspace-Isolated Query:**
```sql
SELECT * FROM table
WHERE workspace_id = $1
  AND [conditions]
ORDER BY created_at DESC
LIMIT $2
```

**Time-Range Filter:**
```sql
SELECT * FROM table
WHERE workspace_id = $1
  AND timestamp >= NOW() - INTERVAL $2
```

**Cache Key Format:**
```
{endpoint}:{workspace_id}:{params_hash}
```

---

**End of CLAUDE.md**

This comprehensive guide should enable smooth implementation of Phase 5. Follow the patterns, leverage the sub-agents, and maintain the quality standards established in previous phases. Good luck with Phase 5 implementation!
