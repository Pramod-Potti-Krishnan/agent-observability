# Integration Strategies
## AI Agent Observability Platform

**Goal:** Seamless integration with existing agent infrastructure
**Last Updated:** October 2025
**Status:** High-Level Patterns

---

## Table of Contents

1. [Overview](#overview)
2. [Strategy 1: Custom SDK (Simplest)](#strategy-1-custom-sdk-simplest)
3. [Strategy 2: OpenTelemetry Extension](#strategy-2-opentelemetry-extension)
4. [Strategy 3: LangGraph Connectors](#strategy-3-langgraph-connectors)
5. [Strategy 4: Webhook Integration](#strategy-4-webhook-integration)
6. [Strategy 5: Log Parsing & Ingestion](#strategy-5-log-parsing--ingestion)
7. [Comparison Matrix](#comparison-matrix)
8. [Migration Paths](#migration-paths)

---

## Overview

Organizations can integrate the AI Agent Observability Platform using multiple approaches, each with different trade-offs:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Integration Strategies                       │
└─────────────────────────────────────────────────────────────────┘

1. Custom SDK (2-Line Integration)
   ├─ Python SDK
   ├─ TypeScript/JavaScript SDK
   └─ Minimal code changes, fastest time to value

2. OpenTelemetry Extension
   ├─ Extend existing OTEL setup
   ├─ Custom span attributes for agent-specific data
   └─ Leverage existing observability infrastructure

3. LangGraph Connectors
   ├─ LangGraph callbacks
   ├─ LangSmith integration bridge
   └─ Native support for LangGraph-based agents

4. Webhook Integration
   ├─ Push-based trace delivery
   ├─ Async, fire-and-forget
   └─ No SDK dependency

5. Log Parsing & Ingestion
   ├─ Parse structured logs
   ├─ Batch processing
   └─ For legacy systems
```

---

## Strategy 1: Custom SDK (Simplest)

**Best For:** New projects, fastest integration, minimal dependencies

### Overview

A lightweight SDK that wraps agent calls and automatically captures traces.

### Python SDK

#### Installation
```bash
pip install agent-observability
```

#### Basic Usage (2-Line Integration)

```python
from agent_observability import AgentObservability

# Initialize (once)
obs = AgentObservability(api_key="pk_live_...")

# Wrap your agent call
@obs.trace(agent_id="customer_support")
def handle_customer_query(user_input: str) -> str:
    # Your existing agent logic
    response = llm.generate(user_input)
    return response

# That's it! Traces are automatically sent
result = handle_customer_query("How do I reset my password?")
```

#### Advanced Usage

```python
from agent_observability import AgentObservability, trace_metadata

obs = AgentObservability(
    api_key="pk_live_...",
    environment="production",  # or "staging", "development"
    batch_size=10,  # Batch traces for efficiency
    flush_interval=5  # Flush every 5 seconds
)

@obs.trace(
    agent_id="customer_support",
    user_id_extractor=lambda kwargs: kwargs.get("user_id"),
    session_id_extractor=lambda kwargs: kwargs.get("session_id")
)
def handle_query(user_id: str, session_id: str, query: str) -> str:
    # Add custom metadata
    trace_metadata.set("query_type", classify_query(query))
    trace_metadata.set("intent", detect_intent(query))

    response = llm.generate(query)

    # Track cost manually (if not auto-detected)
    trace_metadata.set("cost_usd", 0.0034)
    trace_metadata.set("model", "gpt-4-turbo")

    return response
```

#### Async Support

```python
@obs.trace(agent_id="async_agent")
async def async_agent_call(query: str) -> str:
    response = await llm.agenerate(query)
    return response

# Works seamlessly with async
result = await async_agent_call("What is the weather?")
```

#### Error Handling

```python
@obs.trace(agent_id="error_prone_agent")
def risky_agent_call(query: str) -> str:
    try:
        response = llm.generate(query)
        return response
    except Exception as e:
        # Errors are automatically captured
        # trace will show status='error' and error_message
        raise
```

### TypeScript/JavaScript SDK

#### Installation
```bash
npm install @agent-observability/sdk
```

#### Usage

```typescript
import { AgentObservability } from '@agent-observability/sdk'

const obs = new AgentObservability({
  apiKey: 'pk_live_...',
  environment: 'production'
})

// Wrap async function
const handleQuery = obs.trace(
  async (query: string): Promise<string> => {
    const response = await llm.generate(query)
    return response
  },
  {
    agentId: 'customer_support',
    getUserId: () => currentUser.id,
    getSessionId: () => currentSession.id
  }
)

// Use it
const result = await handleQuery('How do I reset my password?')
```

### SDK Architecture

```
Application Code
      │
      ├─ @obs.trace() decorator/wrapper
      │
      ├─ Capture inputs/outputs
      ├─ Measure latency
      ├─ Extract metadata
      │
      ├─ Build trace object
      │
      ├─ Add to buffer
      │
      └─ Async flush to API
            │
            └─ POST /api/v1/traces (batch)
```

### Advantages
- ✅ **Fastest integration** (2 lines of code)
- ✅ **Automatic instrumentation** (latency, errors, metadata)
- ✅ **Type-safe** (TypeScript, Python type hints)
- ✅ **Async-friendly** (batching, non-blocking)
- ✅ **Framework agnostic** (works with any agent framework)

### Disadvantages
- ❌ **Vendor lock-in** (platform-specific SDK)
- ❌ **Additional dependency** (SDK must be maintained)

---

## Strategy 2: OpenTelemetry Extension

**Best For:** Organizations already using OpenTelemetry for observability

### Overview

Extend existing OpenTelemetry setup to capture agent-specific data as spans with custom attributes.

### Architecture

```
Your Agent Code
      │
      ├─ OpenTelemetry Tracer
      │
      ├─ Create span: "agent.call"
      ├─ Add attributes:
      │    • agent.id
      │    • agent.input
      │    • agent.output
      │    • agent.model
      │    • agent.cost
      │
      ├─ OTLP Exporter
      │
      └─ Send to OTLP Collector
            │
            ├─ Filter: agent.* attributes
            │
            └─ Forward to Agent Observability Platform
                  POST /api/v1/traces/otlp
```

### Implementation

#### Python (OpenTelemetry)

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Configure OTLP exporter to send to Agent Observability Platform
otlp_exporter = OTLPSpanExporter(
    endpoint="https://api.yourdomain.com/api/v1/traces/otlp",
    headers={"Authorization": f"Bearer {API_KEY}"}
)

# Set up tracer provider
provider = TracerProvider()
provider.add_span_processor(BatchSpanProcessor(otlp_exporter))
trace.set_tracer_provider(provider)

tracer = trace.get_tracer(__name__)

# Instrument your agent
def handle_query(user_input: str) -> str:
    with tracer.start_as_current_span("agent.call") as span:
        # Set agent-specific attributes
        span.set_attribute("agent.id", "customer_support")
        span.set_attribute("agent.input", user_input)
        span.set_attribute("agent.user_id", get_current_user_id())
        span.set_attribute("agent.session_id", get_current_session_id())

        # Call agent
        response = llm.generate(user_input)

        # Capture output and metadata
        span.set_attribute("agent.output", response)
        span.set_attribute("agent.model", "gpt-4-turbo")
        span.set_attribute("agent.cost_usd", 0.0034)
        span.set_attribute("agent.tokens_prompt", 234)
        span.set_attribute("agent.tokens_completion", 456)

        return response
```

#### Semantic Conventions

Define custom semantic conventions for agent traces:

```python
# agent_semantic_conventions.py

# Required attributes
AGENT_ID = "agent.id"  # Unique agent identifier
AGENT_INPUT = "agent.input"  # User input/query
AGENT_OUTPUT = "agent.output"  # Agent response

# Optional attributes
AGENT_USER_ID = "agent.user_id"
AGENT_SESSION_ID = "agent.session_id"
AGENT_MODEL = "agent.model"  # LLM model used
AGENT_COST_USD = "agent.cost_usd"
AGENT_TOKENS_PROMPT = "agent.tokens.prompt"
AGENT_TOKENS_COMPLETION = "agent.tokens.completion"
AGENT_ENVIRONMENT = "agent.environment"  # production, staging, dev

# Error attributes
AGENT_ERROR_TYPE = "agent.error.type"
AGENT_ERROR_MESSAGE = "agent.error.message"
```

### OTLP Collector Configuration

```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  # Filter spans to only agent-related spans
  filter/agent_spans:
    spans:
      include:
        match_type: regexp
        attributes:
          - key: agent.id
            value: .*

  # Add workspace_id from API key
  attributes/workspace:
    actions:
      - key: workspace_id
        action: insert
        value: ws_123  # Extract from auth header

exporters:
  # Export to Agent Observability Platform
  otlphttp/agent_platform:
    endpoint: https://api.yourdomain.com/api/v1/traces/otlp
    headers:
      Authorization: Bearer ${API_KEY}

  # Also export to your existing observability (DataDog, NewRelic, etc.)
  otlp/existing:
    endpoint: your-existing-collector:4317

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [filter/agent_spans, attributes/workspace]
      exporters: [otlphttp/agent_platform, otlp/existing]
```

### Advantages
- ✅ **Leverage existing OTLP infrastructure**
- ✅ **Vendor-neutral** (OpenTelemetry standard)
- ✅ **Unified observability** (agent traces alongside service traces)
- ✅ **Rich ecosystem** (auto-instrumentation, integrations)

### Disadvantages
- ❌ **More complex setup** (collector, semantic conventions)
- ❌ **Requires OTLP knowledge**
- ❌ **Additional configuration overhead**

---

## Strategy 3: LangGraph Connectors

**Best For:** Teams using LangGraph/LangChain for agent orchestration

### Overview

Use LangGraph's callback system and integrate with LangSmith or bridge to Agent Observability Platform.

### Architecture

```
LangGraph Agent
      │
      ├─ LangGraph Callbacks
      │    • on_chain_start
      │    • on_chain_end
      │    • on_llm_start
      │    • on_llm_end
      │
      ├─ Custom Callback Handler
      │
      ├─ Transform to trace format
      │
      └─ Send to Agent Observability Platform
            POST /api/v1/traces
```

### Implementation

#### Custom LangChain/LangGraph Callback

```python
from langchain.callbacks.base import BaseCallbackHandler
from typing import Any, Dict, List
import requests

class AgentObservabilityCallback(BaseCallbackHandler):
    def __init__(self, api_key: str, agent_id: str):
        self.api_key = api_key
        self.agent_id = agent_id
        self.trace_data = {}

    def on_chain_start(
        self, serialized: Dict[str, Any], inputs: Dict[str, Any], **kwargs
    ) -> None:
        """Called when chain starts"""
        self.trace_data = {
            "agent_id": self.agent_id,
            "input": inputs.get("input", ""),
            "timestamp": datetime.utcnow().isoformat(),
            "metadata": {}
        }

    def on_llm_start(
        self, serialized: Dict[str, Any], prompts: List[str], **kwargs
    ) -> None:
        """Called when LLM call starts"""
        self.trace_data["metadata"]["prompts"] = prompts

    def on_llm_end(self, response: Any, **kwargs) -> None:
        """Called when LLM call ends"""
        # Extract token usage
        if hasattr(response, 'llm_output') and 'token_usage' in response.llm_output:
            token_usage = response.llm_output['token_usage']
            self.trace_data["tokens_prompt"] = token_usage.get('prompt_tokens', 0)
            self.trace_data["tokens_completion"] = token_usage.get('completion_tokens', 0)

        # Extract model
        if hasattr(response, 'llm_output') and 'model_name' in response.llm_output:
            self.trace_data["model"] = response.llm_output['model_name']

    def on_chain_end(self, outputs: Dict[str, Any], **kwargs) -> None:
        """Called when chain ends"""
        self.trace_data["output"] = outputs.get("output", "")

        # Calculate latency
        start_time = datetime.fromisoformat(self.trace_data["timestamp"])
        end_time = datetime.utcnow()
        latency_ms = int((end_time - start_time).total_seconds() * 1000)
        self.trace_data["latency_ms"] = latency_ms

        # Send trace
        self._send_trace()

    def on_chain_error(self, error: Exception, **kwargs) -> None:
        """Called when chain errors"""
        self.trace_data["status"] = "error"
        self.trace_data["error_message"] = str(error)
        self._send_trace()

    def _send_trace(self):
        """Send trace to Agent Observability Platform"""
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        # Generate trace_id
        self.trace_data["trace_id"] = f"tr_{uuid.uuid4().hex[:16]}"

        response = requests.post(
            "https://api.yourdomain.com/api/v1/traces",
            headers=headers,
            json=self.trace_data
        )

        if response.status_code != 200:
            # Log error but don't fail agent
            print(f"Failed to send trace: {response.text}")

# Usage with LangChain
from langchain.chains import LLMChain
from langchain.llms import OpenAI

llm = OpenAI()
chain = LLMChain(llm=llm, prompt=prompt_template)

# Add callback
callback = AgentObservabilityCallback(
    api_key="pk_live_...",
    agent_id="customer_support"
)

# Run chain with callback
result = chain.run(
    input="How do I reset my password?",
    callbacks=[callback]
)
```

#### LangGraph Integration

```python
from langgraph.graph import StateGraph
from agent_observability import AgentObservabilityCallback

# Define your LangGraph
graph = StateGraph(...)

# Add nodes and edges
graph.add_node("agent", agent_node)
graph.add_edge("agent", "tools")

# Compile with callback
callback = AgentObservabilityCallback(api_key="pk_live_...", agent_id="langgraph_agent")

app = graph.compile()

# Run with callback
result = app.invoke(
    {"input": "User query"},
    config={"callbacks": [callback]}
)
```

### LangSmith Bridge

If already using LangSmith, create a bridge to sync data:

```python
# langsmith_bridge.py
import requests
from langsmith import Client

langsmith_client = Client()

# Fetch traces from LangSmith
traces = langsmith_client.list_runs(project_name="my-agent-project")

# Transform and send to Agent Observability Platform
for trace in traces:
    transformed = {
        "trace_id": f"tr_{trace.id}",
        "agent_id": "langsmith_agent",
        "input": trace.inputs,
        "output": trace.outputs,
        "latency_ms": trace.total_tokens,  # or calculate from timestamps
        "timestamp": trace.start_time.isoformat(),
        # ... map other fields
    }

    requests.post(
        "https://api.yourdomain.com/api/v1/traces",
        headers={"Authorization": f"Bearer {API_KEY}"},
        json=transformed
    )
```

### Advantages
- ✅ **Native LangGraph/LangChain integration**
- ✅ **Automatic token tracking**
- ✅ **Rich context** (prompts, intermediate steps)
- ✅ **Can bridge existing LangSmith data**

### Disadvantages
- ❌ **LangChain/LangGraph specific**
- ❌ **Callback overhead** (small performance impact)

---

## Strategy 4: Webhook Integration

**Best For:** Push-based architectures, async workflows, serverless

### Overview

Send traces via webhooks after agent execution completes.

### Architecture

```
Agent Execution
      │
      ├─ Execute agent logic
      ├─ Collect trace data
      │
      ├─ Fire webhook (async)
      │
      └─ POST to webhook endpoint
            │
            └─ Agent Observability Platform
                  receives and processes
```

### Implementation

```python
import httpx
import asyncio

async def send_trace_webhook(trace_data: dict):
    """Send trace via webhook (fire-and-forget)"""
    async with httpx.AsyncClient() as client:
        try:
            await client.post(
                "https://api.yourdomain.com/api/v1/webhooks/trace",
                headers={
                    "Authorization": f"Bearer {API_KEY}",
                    "Content-Type": "application/json"
                },
                json=trace_data,
                timeout=5.0
            )
        except Exception as e:
            # Log but don't fail
            print(f"Webhook failed: {e}")

# In your agent code
def handle_query(user_input: str) -> str:
    start_time = time.time()

    try:
        response = llm.generate(user_input)
        status = "success"
        error = None
    except Exception as e:
        response = ""
        status = "error"
        error = str(e)
        raise

    finally:
        # Send trace asynchronously
        trace_data = {
            "trace_id": f"tr_{uuid.uuid4().hex}",
            "agent_id": "customer_support",
            "input": user_input,
            "output": response,
            "latency_ms": int((time.time() - start_time) * 1000),
            "status": status,
            "error_message": error,
            "timestamp": datetime.utcnow().isoformat()
        }

        asyncio.create_task(send_trace_webhook(trace_data))

    return response
```

### Webhook Payload Format

```json
{
  "trace_id": "tr_abc123",
  "agent_id": "customer_support",
  "user_id": "user_12345",
  "session_id": "sess_xyz",
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
  "status": "success",
  "metadata": {}
}
```

### Advantages
- ✅ **No SDK dependency**
- ✅ **Async, non-blocking**
- ✅ **Simple HTTP POST**
- ✅ **Works in serverless environments**

### Disadvantages
- ❌ **Manual instrumentation** (must build trace object manually)
- ❌ **No batching** (one request per trace)
- ❌ **Error handling responsibility** (client must handle retries)

---

## Strategy 5: Log Parsing & Ingestion

**Best For:** Legacy systems, when code changes are difficult

### Overview

Parse structured logs and ingest them as traces.

### Architecture

```
Agent Application
      │
      ├─ Write structured logs
      │    (JSON format)
      │
      ├─ Log file or stdout
      │
      ├─ Log collector (Fluentd, Logstash, Vector)
      │
      ├─ Parse log fields
      ├─ Transform to trace format
      │
      └─ POST /api/v1/traces
```

### Log Format

```json
{
  "timestamp": "2025-10-21T14:32:00Z",
  "level": "INFO",
  "event": "agent_trace",
  "trace_id": "tr_abc123",
  "agent_id": "customer_support",
  "user_id": "user_12345",
  "input": "How do I reset my password?",
  "output": "To reset your password...",
  "latency_ms": 1200,
  "cost_usd": 0.0034,
  "model": "gpt-4-turbo"
}
```

### Fluentd Configuration

```ruby
# fluentd.conf

# Match agent trace logs
<filter app.agent_trace>
  @type parser
  key_name message
  <parse>
    @type json
  </parse>
</filter>

# Send to Agent Observability Platform
<match app.agent_trace>
  @type http
  endpoint https://api.yourdomain.com/api/v1/traces/batch
  headers {"Authorization": "Bearer ${API_KEY}"}
  json_array true

  <buffer>
    @type memory
    flush_interval 10s
    chunk_limit_size 5MB
  </buffer>
</match>
```

### Advantages
- ✅ **No code changes** (if logs already exist)
- ✅ **Centralized log infrastructure** (reuse existing pipelines)
- ✅ **Batch processing** (efficient)

### Disadvantages
- ❌ **Delayed ingestion** (not real-time)
- ❌ **Requires structured logging**
- ❌ **Additional infrastructure** (log collectors)

---

## Comparison Matrix

| Strategy | Ease of Integration | Real-Time | Dependencies | Flexibility | Best For |
|----------|-------------------|-----------|--------------|-------------|----------|
| **Custom SDK** | ⭐⭐⭐⭐⭐ Easiest | ✅ Yes | SDK package | Medium | New projects, fast setup |
| **OpenTelemetry** | ⭐⭐⭐ Moderate | ✅ Yes | OTLP collector | High | Existing OTLP users |
| **LangGraph Callbacks** | ⭐⭐⭐⭐ Easy | ✅ Yes | LangChain/LangGraph | Medium | LangGraph users |
| **Webhooks** | ⭐⭐⭐⭐ Easy | ✅ Yes | None | Low | Serverless, async |
| **Log Parsing** | ⭐⭐ Complex | ❌ No | Log collector | High | Legacy systems |

---

## Migration Paths

### From No Observability → Custom SDK
```
1. Install SDK: pip install agent-observability
2. Add 2-line wrapper to agent calls
3. Deploy and verify traces appear
4. Gradually add metadata, user IDs, etc.
```

### From Existing OTLP → OpenTelemetry Extension
```
1. Add agent.* semantic conventions to spans
2. Configure OTLP collector to filter/forward
3. Update exporter endpoint to include platform
4. Verify dual export (existing + platform)
```

### From LangSmith → LangGraph Callbacks
```
1. Create custom callback handler
2. Add to LangGraph config
3. Run parallel (LangSmith + platform)
4. Validate data parity
5. Optionally migrate historical data via bridge
```

### From Webhooks → Custom SDK
```
1. Install SDK alongside webhook code
2. Run both in parallel for validation period
3. Compare trace data for consistency
4. Remove webhook code once confident
```

---

## Summary

**Choose the right integration strategy based on your needs:**

- **Fast Time to Value?** → Custom SDK (Strategy 1)
- **Already using OpenTelemetry?** → OTLP Extension (Strategy 2)
- **Using LangGraph/LangChain?** → LangGraph Callbacks (Strategy 3)
- **Serverless or async architecture?** → Webhooks (Strategy 4)
- **Legacy systems or structured logs?** → Log Parsing (Strategy 5)

**Hybrid Approach:**
Many organizations use multiple strategies:
- Custom SDK for new agents
- OTLP extension for services already instrumented
- Log parsing for legacy systems

All strategies funnel data into the same platform, providing unified observability across heterogeneous agent infrastructure.

---

**Implementation Order:**
1. Start with **one agent** using **Custom SDK** (fastest validation)
2. Expand to more agents with SDK
3. Integrate existing OTLP infrastructure (if applicable)
4. Add LangGraph callbacks for orchestrated agents
5. Use log parsing for legacy systems as last resort

This multi-strategy approach ensures **maximum compatibility** while **minimizing integration friction**.
