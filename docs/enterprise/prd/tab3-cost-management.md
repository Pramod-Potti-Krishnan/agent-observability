# Tab 3: Cost Management

**Route**: `/dashboard/cost`  
**Purpose**: Financial tracking, budget governance, and cost optimization across the multi-agent fleet with actionable FinOps capabilities

## Personas & User Goals

| Persona | Primary Goals | Key Questions |
|---------|---------------|---------------|
| **CFO / Finance Director** | Budget oversight, cost forecasting, ROI validation | Are we staying within budget? What's driving cost increases? |
| **FinOps Manager** | Cost allocation, chargeback accuracy, optimization recommendations | Which departments are overspending? Where can we optimize? |
| **Engineering Director** | Technical cost efficiency, model selection, infrastructure optimization | Which models are most cost-effective? Should we switch providers? |
| **Department Head** | Department budget tracking, justification for overages | Is my team within budget? Can I get more allocation? |
| **Platform Architect** | Architectural cost impact, caching strategies, token optimization | How much would switching providers save? What's the ROI of caching? |

## Multi-Level Structure

### Level 1: Fleet View (Default)
- Organization-wide cost aggregation across all departments, providers, models
- Budget vs actual tracking with variance analysis
- Cost drivers breakdown (provider, model, department, agent)
- Optimization opportunities ranked by potential savings

### Level 2: Filtered Subset
**Cost Attribution Analysis**:
- Department A cost breakdown vs Department B
- Provider cost comparison (OpenAI vs Anthropic vs Google)
- Model family comparison (GPT-4 vs Claude-3-Opus vs Gemini-Ultra)
- Environment cost isolation (Production vs Staging spend)
- Version cost impact analysis (v2.0 costs vs v1.9)

### Level 3: Agent Detail
- Individual agent cost breakdown (prompt tokens, completion tokens, tool use)
- Request-level cost attribution with trace context
- Token efficiency metrics per agent
- Cost anomaly detection at agent level

## Filters & Controls

### Primary Filters
| Filter | Options | Default | Behavior |
|--------|---------|---------|----------|
| **Time Range** | 1h, 24h, 7d, 30d, 90d, Custom, MTD (Month-to-Date), QTD (Quarter-to-Date) | 30d | Financial reporting periods |
| **Department** | All, [List], Multi-select for comparison | All | Department-level cost attribution |
| **Provider** | All, OpenAI, Anthropic, Google, AWS Bedrock, Azure OpenAI, Multi-select | All | Provider cost comparison |
| **Model Family** | All, GPT-4, Claude-3, Gemini, Llama, Custom, Multi-select | All | Model-level cost analysis |
| **Environment** | All, Production, Staging, Development | Production | Environment cost isolation |
| **Cost Center** | All, [Org-specific cost centers] | All | Financial chargeback alignment |
| **Agent Status** | All, Active, Beta, Deprecated | Active | Exclude deprecated costs if needed |

### Secondary Filters
- Agent ID (multi-select)
- User segment (power users, regular, etc.)
- Token type (prompt tokens, completion tokens, tool use, embeddings)
- Cost category (LLM inference, data processing, storage, infrastructure)

---

## Table 1: Existing Charts Adaptation

| Chart ID | Current Chart Name | Current Purpose | Required Modifications | New Filter Behavior | New Drilldown Behavior | Data Enhancements Needed | Priority |
|----------|-------------------|-----------------|----------------------|-------------------|----------------------|------------------------|----------|
| **3.1** | Total Spend | Track overall AI costs | Add multi-dimensional breakdown: By provider, model, department; Include budget overlay with % consumed; Forecast line for end-of-period projection | Filters show subset spend; Multi-provider comparison view; Budget-relative % changes | Click → Cost breakdown table; Click provider → Provider cost analysis; Click dept → Dept cost dashboard | Add `provider`, `model_family`, `department_id`, `cost_center`, `budget_id`, `forecast_value` to billing data | **P0** |
| **3.2** | Budget Remaining | Monitor budget consumption | Transform to multi-budget view: One card per department budget; Color-coded status (green <70%, yellow 70-90%, red >90%); Burn rate indicator; Days remaining at current rate | Show budgets for filtered scope; Dept comparison mode; Alert threshold visualization | Click budget card → Budget details (history, adjustments, approvals); Hover → Burn rate and depletion date | Add `department_budget[]`, `budget_period`, `budget_threshold_warning`, `budget_threshold_critical`, `burn_rate_daily` | **P0** |
| **3.3** | Cost per Request | Track unit economics | Add comparative view: Cost per request by dept/agent/provider; Benchmarking against baseline; Token efficiency metric (cost per 1k tokens); Model mix impact | Show filtered avg; Distribution histogram; Outlier identification; Comparison across dimensions | Click → Agents with highest/lowest cost per request; Hover → Token breakdown; Click outlier → Cost anomaly investigation | Add `token_count_prompt`, `token_count_completion`, `model_pricing_tier`, `cache_hit_rate` to request logs | **P0** |
| **3.4** | Average Cost per Call | Synonym for 3.3 | **Merge with 3.3** to avoid duplication | N/A | N/A | N/A | **P0** |
| **3.5** | Cost Trend | Visualize cost over time | Enhance to stacked area chart: Layers = Providers or Models or Departments; Add trend line with forecast; Anomaly markers; Cost spikes annotated with causes | Multi-dimensional stacking; Comparison overlays; Period-over-period comparison | Click stack layer → That provider/model/dept deep-dive; Click anomaly → Root cause (e.g., traffic spike, model change); Hover → Breakdown values | Add `cost_attribution_dimension`, `anomaly_flag`, `spike_reason`, `baseline_cost`, `forecast_cost` | **P0** |
| **3.6** | Cost by Provider | Show provider cost distribution | Add comparative metrics per provider: Cost, Latency, Quality, Error Rate; Multi-objective optimization view (cost-quality-performance tradeoff); "Switch provider" savings estimator | Filter by time, dept, environment; Multi-provider benchmarking; Hypothetical scenario modeling ("What if we moved 50% to Provider B?") | Click provider → Detailed cost breakdown by model and usage; Hover → Provider SLA compliance; Click "Estimate Savings" → What-if analysis tool | Add `provider_sla_met`, `provider_quality_score`, `provider_latency_p90`, `provider_error_rate`, `switching_cost_estimate` | **P1** |
| **3.7** | Model Usage Cost | Cost breakdown by model | Transform to cost-efficiency matrix: X-axis = Cost, Y-axis = Quality or Performance; Bubble size = Usage volume; Color = Model family; Pareto frontier identification | Filter by dept, agent, time; Model comparison mode; "Optimal model" highlighter | Click bubble → Model deep-dive; Hover → Detailed metrics; Select models → Multi-model comparison table | Add `model_quality_score`, `model_latency_avg`, `model_request_volume`, `model_cost_per_request` for Pareto analysis | **P1** |
| **3.8** | Top Costly Agents | Identify cost drivers | Add columns: Dept, Requests, Cost per Req, Token Efficiency, Optimization Potential ($/month); Add "Optimize" action buttons; Increase to Top 20 | Sort by any column; Filter by dept, environment; Search by agent name | Click agent → Agent cost detail dashboard; Click "Optimize" → Optimization recommendations modal; Hover → Token usage pattern | Add `optimization_potential_usd`, `token_efficiency_score`, `cache_hit_rate`, `prompt_length_avg`, `completion_length_avg` | **P0** |

---

## Table 2: New Charts Addition

| Chart ID | Chart Name | Description | Priority | D3 Visualization Type | Backend Data Required | Multi-Agent Behavior | Drilldown Behavior |
|----------|------------|-------------|----------|----------------------|----------------------|---------------------|-------------------|
| **3.9** | Department Budget Dashboard | Grid of budget cards for all departments with status indicators | **P0** | Small Multiples (Card grid with progress bars) | Per department: `dept_id`, `budget_allocated`, `budget_spent`, `budget_remaining`, `burn_rate`, `forecast_overrun`, `status` | One card per department; Color-coded status; Sort by overrun risk; Filter by status (on-track, warning, critical) | Click card → Dept cost deep-dive; Hover → Burn rate and depletion date; Click "Adjust Budget" → Budget modification workflow |
| **3.10** | Cost Attribution Sunburst | Hierarchical cost breakdown: Dept → Agent → Model → Request Type | **P0** | Sunburst (d3-hierarchy) | Hierarchical cost data: `department` → `agent_id` → `model` → `request_type` with cost values | Concentric rings represent hierarchy; Size = Cost; Color = Cost category; Filter by time, environment | Click segment → Drill into that level; Click center → Drill back up; Hover → Cost and % of parent; Export path |
| **3.11** | Cost Optimization Leaderboard | Ranked list of optimization opportunities with estimated savings | **P0** | Sortable Table with progress indicators | Optimization recs: `opportunity_id`, `type`, `affected_agents`, `current_cost_monthly`, `optimized_cost_monthly`, `savings_potential`, `effort`, `status` | Sorted by savings potential; Types: Model downgrade, Caching, Prompt optimization, Provider switch, Batching; Color-coded by effort | Click opportunity → Implementation guide; Hover → Technical details; Mark as "Implemented" → Track savings realization |
| **3.12** | Token Usage Waterfall | Waterfall chart showing token consumption breakdown | **P1** | Waterfall Chart (d3-shape) | Token breakdown: `prompt_tokens`, `completion_tokens`, `tool_use_tokens`, `cached_tokens_saved`, `embeddings_tokens`, `reasoning_tokens` | Bars show additive token consumption; Highlight cache savings; Show cost per token tier | Click bar → Agents contributing to that token type; Hover → Token count and cost; Export token analysis |
| **3.13** | Cost Forecast Model | 30/60/90-day cost forecast with confidence intervals and scenario modeling | **P1** | Line Chart with confidence bands + scenario overlays | Forecast data: `date`, `forecast_cost`, `confidence_lower`, `confidence_upper`, `baseline_scenario`, `optimistic_scenario`, `pessimistic_scenario` | Default: Baseline forecast; Overlay scenarios (e.g., +20% traffic, -10% via optimization); Show budget runway | Click forecast period → Assumptions and drivers; Hover → Daily cost projections; Adjust scenarios → Recalculate |
| **3.14** | Provider Cost-Performance Matrix | 2D scatter: X=Cost, Y=Performance/Quality; Identify Pareto-optimal providers | **P1** | Scatter Plot with Pareto frontier | Per provider: `provider`, `avg_cost_per_request`, `avg_latency_p90` or `avg_quality_score`, `request_volume`, `reliability_score` | Bubbles = Providers; Size = Volume; Color = Model family; Pareto frontier line; Quadrants: Optimal/Expensive/Cheap-Slow | Click bubble → Provider detail; Hover → Metrics; Select provider → "Switch to" savings calculator |
| **3.15** | Caching ROI Calculator | Interactive widget showing cost savings from caching strategies | **P1** | Interactive Form + ROI Visualization | Cache metrics: `cache_hit_rate_current`, `cache_hit_rate_target`, `cacheable_request_pct`, `avg_cost_per_request`, `request_volume_monthly` | Input target cache hit rate → Calculate savings; Show payback period; Compare strategies (semantic cache, exact match, embedding cache) | Adjust parameters → Live ROI update; Click strategy → Implementation guide; Export business case |
| **3.16** | Cost Anomaly Timeline | Timeline of detected cost anomalies with root cause annotations | **P1** | Timeline with markers (d3-time) | Anomaly events: `timestamp`, `anomaly_score`, `cost_spike_amount`, `affected_agents[]`, `root_cause`, `auto_resolved`, `manual_action_taken` | Timeline with severity-colored markers; Group by root cause; Filter by dept, agent | Click anomaly → Detailed investigation view; Hover → Spike details; Mark as "Expected" → Suppress future similar alerts |
| **3.17** | Model Pricing Comparison Table | Side-by-side pricing for all models across providers with TCO calculation | **P2** | Comparison Table with calculators | Model pricing: `provider`, `model`, `prompt_token_price`, `completion_token_price`, `context_window`, `speed_tps`, `quality_benchmarks` | Table with sortable columns; TCO calculator based on usage profile; Highlight best value per use case | Click model → Detailed specs; Hover → Pricing tiers; Calculate TCO → Custom usage input |
| **3.18** | Cost Allocation Flowchart | Sankey diagram showing cost flow from org → departments → agents → models | **P2** | Sankey Diagram (d3-sankey) | Cost flow: `source` → `target` with `cost_value`; Hierarchy: Organization → Departments → Agents → Models | Links thickness = Cost amount; Color = Cost category; Filter by time, environment | Click node → That entity's cost detail; Click link → Breakdown of that flow; Hover → Cost amount and % |

---

## Table 3: Actionable Interventions

| Action ID | Action Name | Description | Trigger | Required UI Components | Required Backend/Data | Who Can Perform It | Scope | Expected Business Outcome | Dependencies | Priority |
|-----------|-------------|-------------|---------|----------------------|---------------------|-------------------|-------|---------------------------|--------------|----------|
| **A3.1** | Set Department Budget | Allocate monthly/quarterly budget to departments | Manual | Budget config modal; Dept selector; Amount input ($/month or $/quarter); Budget period; Approval workflow (CFO approval for >$X); Alert thresholds (80%, 95%) | Budget management API; Department mapping; Approval workflow engine; Budget alerting service | CFO, Finance Director, FinOps Manager | Department-specific | Cost control ↑, Accountability ↑, Budget discipline ↑ | Department structure, Approval system | **P0** |
| **A3.2** | Adjust Budget Mid-Period | Increase/decrease department budget with justification | Manual | Budget adjustment modal; Current budget display; New budget input; Justification text (required); Approval required toggle | Budget adjustment API; Change log; Notification to dept head and finance; Approval workflow | Finance Director, CFO | Department-specific | Flexibility ↑, Budget accuracy ↑ | Budget system, Approval workflow | **P0** |
| **A3.3** | Configure Budget Alert | Set up alerts when budget thresholds are approached | Manual | Alert config modal; Budget selector; Threshold % (e.g., 80%, 95%); Notification channels (email, Slack, PagerDuty); Recipients | Alert rule engine; Budget tracking; Multi-channel notification service | FinOps Manager, Finance Director, Dept Head | Department or Global | Proactive cost management ↑, Budget overrun prevention ↑ | Budget system, Alert infrastructure | **P0** |
| **A3.4** | Implement Model Downgrade | Switch agent(s) to lower-cost model with acceptable quality tradeoff | Manual / Automated (recommendation-triggered) | Agent selector; Current model display; Recommended model; Quality impact estimate; Cost savings estimate ($/month); Test period option | Model switching API; Agent configuration; Quality benchmarking; Cost calculation; A/B testing framework | Engineering Director, Platform Architect, FinOps Manager | Agent-specific or Agent-group | Cost ↓ 20-40%, Acceptable quality maintained, ROI ↑ | Agent config system, Model routing, Quality monitoring | **P0** |
| **A3.5** | Enable Caching | Configure semantic or exact-match caching to reduce redundant LLM calls | Manual / Automated (toggle) | Caching config modal; Cache type selector (exact match, semantic, embedding-based); TTL (time-to-live); Cache size limit; Affected agents | Caching infrastructure (Redis, Memcached); Semantic embedding service; Cache hit tracking; Cost attribution | Platform Architect, Engineering Director | Agent-specific or Global | Cost ↓ 30-60% for cacheable requests, Latency ↓, Throughput ↑ | Caching infrastructure, Semantic similarity service | **P0** |
| **A3.6** | Optimize Prompt | Reduce prompt length while maintaining quality through prompt engineering | Manual | Prompt editor; Current prompt display; Token count; Suggested optimizations (remove redundancy, compress instructions); Test interface; Quality benchmark | Prompt management system; Token counter; LLM-as-judge for quality evaluation; Version control for prompts | ML Engineer, Engineering Manager | Agent-specific | Cost ↓ 10-30%, Latency ↓, Quality maintained or ↑ | Prompt versioning, Quality evaluation system | **P1** |
| **A3.7** | Switch Provider | Migrate agent(s) to lower-cost provider with comparable performance | Manual | Provider comparison modal; Current provider; Recommended provider; Cost comparison (before/after); Performance comparison; Migration complexity estimate; Rollback plan | Multi-provider routing; Cost calculator; Performance benchmarking; Gradual rollout (canary); Rollback automation | Platform Architect, Engineering Director, FinOps Manager | Agent-specific or Multi-agent | Cost ↓ 15-50% depending on provider, Performance maintained | Multi-provider infrastructure, Canary deployment | **P1** |
| **A3.8** | Enable Request Batching | Batch multiple requests to reduce overhead and leverage volume pricing | Manual / Automated | Batching config modal; Batch size; Max wait time; Affected agents; Volume pricing tier eligibility | Request batching service; Queue management; Volume pricing tracker | Platform Architect, DevOps | Agent-specific or Global | Cost ↓ 5-15%, Throughput ↑, Latency may ↑ slightly | Request orchestration, Batch processing | **P1** |
| **A3.9** | Set Cost Alert | Configure alerts when cost exceeds threshold for agent/dept/fleet | Manual | Cost alert modal; Scope selector (agent/dept/fleet); Threshold type (absolute $/day, % increase, budget %); Notification config | Cost monitoring; Alert evaluation (real-time or hourly); Multi-channel notifications | FinOps Manager, Dept Head, Engineering Director | Configurable scope | Proactive cost control ↑, Incident response ↑, Budget protection ↑ | Cost tracking, Alert system | **P0** |
| **A3.10** | Export Cost Report | Generate detailed cost report for finance, leadership, or chargebacks | Manual | Report config modal; Report type (summary, detailed, chargeback); Date range; Department/cost center; Format (PDF, Excel, CSV); Recipients | Report generation engine; Cost aggregation; Chargeback calculation; Multi-format export | FinOps Manager, Finance Director, CFO, Dept Head | Configurable scope | Transparency ↑, Chargeback accuracy ↑, Stakeholder communication ↑ | Cost data, Report templates | **P1** |
| **A3.11** | Create Cost Optimization Experiment | Set up A/B test to validate cost optimization strategy | Manual | Experiment designer; Hypothesis input; Control vs treatment config (e.g., GPT-4 vs Claude-3); Success metrics (cost, quality, latency); Sample size and duration | Experiment framework; Statistical analysis; Multi-arm bandit or A/B testing; Metric tracking | ML Engineer, Platform Architect, FinOps Manager | Agent-specific or Multi-agent | Data-driven optimization ↑, Risk mitigation ↑, Cost ↓ with validated quality | Experiment infrastructure, Metric collection | **P1** |
| **A3.12** | Approve Cost Overage | Formally approve budget overage with justification and adjusted limits | Manual (workflow-triggered) | Approval modal; Overage amount; Justification; Adjusted budget limit; Approval deadline | Approval workflow; Budget override; Audit log; Notification to requester | CFO, Finance Director | Department-specific | Budget flexibility ↑, Accountability ↑, Transparency ↑ | Budget system, Approval workflow | **P0** |
| **A3.13** | Enable Token Reduction Features | Activate features like output length limits, streaming cutoffs, compression | Manual / Automated | Token reduction config; Feature selector (max output tokens, streaming, compression); Per-agent settings | Token limiting service; Streaming control; Response compression | Engineering Manager, Platform Architect | Agent-specific or Global | Cost ↓ 10-25%, Latency ↓, UX impact (carefully tested) | Request processing pipeline | **P1** |
| **A3.14** | Schedule Cost Review | Set up recurring cost review meetings with automated pre-reports | Manual | Schedule modal; Recurrence (weekly, monthly, quarterly); Participants; Pre-report config (metrics, format); Slack/Calendar integration | Scheduling system; Report pre-generation; Calendar API; Notification service | FinOps Manager, Finance Director, Engineering Director | Global | Operational discipline ↑, Proactive optimization ↑, Alignment ↑ | Scheduling, Report generator | **P2** |

---

## Backend Metrics Schema

### Required Tables/Collections

#### `cost_summary_by_dimension` (Multi-dimensional cost aggregation)
```sql
{
  timestamp: DateTime (indexed),
  time_bucket: String (hourly, daily, weekly, monthly),
  
  -- Dimensional keys
  department_id: String (indexed, nullable),
  cost_center: String (indexed, nullable),
  agent_id: String (indexed, nullable),
  provider: String (indexed, nullable),
  model: String (indexed, nullable),
  environment: String (indexed, nullable),
  version: String (nullable),
  
  -- Cost metrics
  total_cost: Decimal(12,4),
  prompt_token_cost: Decimal(12,4),
  completion_token_cost: Decimal(12,4),
  tool_use_cost: Decimal(12,4),
  embedding_cost: Decimal(12,4),
  cache_savings: Decimal(12,4),
  infrastructure_cost: Decimal(12,4),
  
  -- Volume metrics
  request_count: Integer,
  total_tokens: BigInteger,
  prompt_tokens: BigInteger,
  completion_tokens: BigInteger,
  cached_tokens: BigInteger,
  
  -- Efficiency metrics
  cost_per_request: Decimal(10,6),
  cost_per_1k_tokens: Decimal(10,6),
  cache_hit_rate: Decimal(5,2),
  token_efficiency_score: Decimal(5,2),
  
  -- Comparative
  prev_period_cost: Decimal(12,4),
  prev_period_requests: Integer,
  cost_change_pct: Decimal(5,2),
  
  -- Forecasting
  forecast_cost_eop: Decimal(12,4), -- End of Period
  baseline_cost: Decimal(12,4),
  anomaly_score: Decimal(3,2) (0-1)
}
```

#### `department_budgets` (Budget management)
```sql
{
  budget_id: UUID (primary),
  department_id: String (indexed),
  cost_center: String,
  
  -- Budget allocation
  budget_period: Enum (monthly, quarterly, annual),
  period_start_date: Date (indexed),
  period_end_date: Date,
  allocated_budget: Decimal(12,2),
  
  -- Consumption tracking
  spent_to_date: Decimal(12,2),
  remaining_budget: Decimal(12,2),
  budget_consumed_pct: Decimal(5,2),
  burn_rate_daily: Decimal(10,2),
  projected_overrun: Decimal(12,2) (nullable, if forecasted >100%),
  days_until_depletion: Integer (nullable),
  
  -- Alert thresholds
  alert_threshold_warning: Decimal(5,2) (default 80),
  alert_threshold_critical: Decimal(5,2) (default 95),
  alert_status: Enum (green, yellow, red),
  last_alert_sent_at: DateTime (nullable),
  
  -- Approval & Audit
  approved_by: String (user_id),
  approved_at: DateTime,
  adjustment_history: JSON[] {
    adjusted_by: String,
    adjusted_at: DateTime,
    old_budget: Decimal,
    new_budget: Decimal,
    justification: String
  },
  
  -- Status
  is_active: Boolean,
  created_at: DateTime,
  updated_at: DateTime
}
```

#### `cost_optimization_opportunities` (Recommendations)
```sql
{
  opportunity_id: UUID (primary),
  created_at: DateTime (indexed),
  
  -- Opportunity type
  optimization_type: Enum (
    model_downgrade,
    caching,
    prompt_optimization,
    provider_switch,
    batching,
    token_reduction,
    agent_deprecation
  ),
  
  -- Scope
  affected_agents: Array<String> (agent_ids),
  affected_departments: Array<String>,
  
  -- Impact estimate
  current_cost_monthly: Decimal(12,2),
  optimized_cost_monthly: Decimal(12,2),
  savings_potential_monthly: Decimal(12,2),
  savings_potential_annual: Decimal(12,2),
  
  -- Implementation
  implementation_effort: Enum (low, medium, high),
  estimated_hours: Integer,
  technical_risk: Enum (low, medium, high),
  quality_impact: Enum (none, minimal, moderate, significant),
  
  -- Detailed recommendation
  recommendation_details: JSON {
    current_config: Object,
    recommended_config: Object,
    implementation_steps: String[],
    rollback_plan: String,
    testing_checklist: String[]
  },
  
  -- Status tracking
  status: Enum (identified, in_review, approved, in_progress, implemented, declined, obsolete),
  assigned_to: String (user_id, nullable),
  implemented_at: DateTime (nullable),
  actual_savings_realized: Decimal(12,2) (nullable),
  
  -- Priority score (ML-generated or manual)
  priority_score: Integer (0-100),
  
  -- Metadata
  identified_by: String (system_ml, user_id),
  reviewed_by: String (user_id, nullable),
  notes: Text
}
```

#### `cost_anomalies` (Anomaly detection)
```sql
{
  anomaly_id: UUID (primary),
  detected_at: DateTime (indexed),
  timestamp: DateTime (indexed, time of anomaly),
  
  -- Scope
  scope_level: Enum (fleet, department, agent),
  department_id: String (nullable),
  agent_id: String (nullable),
  
  -- Anomaly details
  metric_name: String (total_cost, cost_per_request, token_usage),
  expected_value: Decimal(12,4),
  actual_value: Decimal(12,4),
  deviation_pct: Decimal(5,2),
  anomaly_score: Decimal(3,2) (0-1, confidence),
  
  -- Root cause analysis
  probable_cause: String (traffic_spike, model_change, configuration_error, abuse, seasonal),
  contributing_factors: JSON[] {
    factor: String,
    evidence: String,
    confidence: Decimal(3,2)
  },
  
  -- Response
  status: Enum (detected, investigating, resolved, false_positive, expected),
  investigated_by: String (user_id, nullable),
  resolution_notes: Text (nullable),
  auto_resolved: Boolean,
  manual_action_taken: String (nullable),
  
  -- Impact
  cost_impact: Decimal(12,2),
  affected_requests: Integer,
  alert_triggered: Boolean,
  incident_id: String (nullable)
}
```

#### `model_pricing_catalog` (Provider/model pricing reference)
```sql
{
  pricing_id: UUID (primary),
  provider: String (indexed),
  model_name: String (indexed),
  
  -- Pricing
  prompt_token_price_per_1m: Decimal(10,4) (per 1M tokens),
  completion_token_price_per_1m: Decimal(10,4),
  cached_token_price_per_1m: Decimal(10,4) (nullable),
  reasoning_token_price_per_1m: Decimal(10,4) (nullable),
  tool_use_price_per_call: Decimal(10,4) (nullable),
  
  -- Model specs
  context_window: Integer,
  max_output_tokens: Integer,
  supports_streaming: Boolean,
  supports_function_calling: Boolean,
  supports_vision: Boolean,
  
  -- Performance benchmarks
  avg_latency_p50_ms: Integer (nullable),
  avg_latency_p99_ms: Integer (nullable),
  tokens_per_second: Integer (nullable),
  quality_score_benchmark: Decimal(3,1) (nullable, on standard evals),
  
  -- Availability
  is_active: Boolean,
  deprecation_date: Date (nullable),
  replacement_model: String (nullable),
  
  -- Metadata
  pricing_tier: String (standard, volume, enterprise),
  pricing_effective_date: Date,
  last_updated: DateTime
}
```

#### `cost_forecast_scenarios` (Forecasting with scenarios)
```sql
{
  forecast_id: UUID (primary),
  forecast_date: Date (indexed),
  forecast_horizon_days: Integer (30, 60, 90),
  
  -- Scope
  scope_level: Enum (fleet, department, agent),
  scope_id: String (dept or agent ID, nullable),
  
  -- Baseline forecast
  baseline_forecast: JSON[] {
    date: Date,
    predicted_cost: Decimal(12,4),
    confidence_lower: Decimal(12,4),
    confidence_upper: Decimal(12,4)
  },
  
  -- Scenario forecasts
  optimistic_forecast: JSON[] (same structure, assumes +optimizations),
  pessimistic_forecast: JSON[] (assumes +traffic, -efficiency),
  
  -- Model metadata
  forecast_model_type: String (ARIMA, Prophet, LSTM, Linear),
  model_accuracy_mape: Decimal(5,2),
  training_period: String,
  
  -- Budget context
  budget_runway_days: Integer (days until budget depletes),
  projected_budget_usage_pct: Decimal(5,2),
  overrun_risk_score: Decimal(3,2) (0-1),
  
  -- Generated
  generated_at: DateTime,
  generated_by: String (system, user_id)
}
```

---

## Cross-Tab Dependencies

### Actions Affecting Multiple Tabs

| Action | Primary Tab | Secondary Tabs Affected | Dependency Chain |
|--------|-------------|------------------------|------------------|
| **Implement Model Downgrade** (A3.4) | Cost | Performance (latency may change), Quality (quality may ↓ slightly), Experiments (track as experiment) | Requires: Model routing, Quality benchmark; Impacts: Cost ↓, Performance ±, Quality tracking |
| **Enable Caching** (A3.5) | Cost | Performance (latency ↓ for cache hits), Usage (effective request count different from actual) | Requires: Cache infrastructure; Impacts: Cost ↓ 30-60%, Latency ↓ 50-90% for hits |
| **Switch Provider** (A3.7) | Cost | Performance (latency profile changes), Quality (quality benchmarks differ), Safety (guardrails may differ) | Requires: Multi-provider setup; Impacts: Cost ±, All metrics affected, Need canary deployment |
| **Set Department Budget** (A3.1) | Cost | Home (budget KPI updates), Business Impact (goal alignment) | Requires: Dept structure; Impacts: Budget alerts, Cost tracking, Chargeback reports |

---

## Acceptance Criteria

### Functional Requirements

**FR3.1**: All cost metrics must update within 10 minutes of request completion (billing lag acceptable)  
**FR3.2**: Budget consumption must calculate in real-time with <1% variance from actual billing  
**FR3.3**: Department cost allocation must sum to exactly 100% of total cost (no rounding errors)  
**FR3.4**: Cost optimization recommendations must refresh daily with new opportunities  
**FR3.5**: Cost forecast must provide 30/60/90-day projections with 95% confidence intervals  
**FR3.6**: Provider cost comparison must support side-by-side comparison of up to 5 providers  
**FR3.7**: Caching ROI calculator must accurately reflect provider-specific pricing models  

### Data Accuracy Requirements

**DA3.1**: Cost per request calculations must match provider invoices within $0.0001  
**DA3.2**: Token counts must match provider-reported tokens (for audit/reconciliation)  
**DA3.3**: Cache hit rate must reflect actual cache performance (no sampling errors >1%)  
**DA3.4**: Budget depletion estimates must recalculate daily based on 7-day rolling burn rate  

### Performance Requirements

**PR3.1**: Cost Management tab initial load <3 seconds for 30-day default range  
**PR3.2**: Cost attribution sunburst must render <5 seconds for org with 50 depts, 200 agents  
**PR3.3**: Budget dashboard must support real-time updates (WebSocket) for budget alerts  
**PR3.4**: Cost forecast calculation must complete <60 seconds for 90-day horizon  
**PR3.5**: Optimization leaderboard must load <2 seconds with up to 100 opportunities  

### UX Requirements

**UX3.1**: Budget cards must use traffic light colors (green/yellow/red) consistently  
**UX3.2**: Cost anomalies must have clear visual markers on timelines  
**UX3.3**: All cost values must support currency formatting (USD, EUR, GBP, etc.)  
**UX3.4**: Optimization opportunities must show estimated ROI and implementation effort clearly  
**UX3.5**: Export functionality must generate Excel reports with multiple sheets (summary, detailed, chart data)  

---

## Reuse Notes

### Components from Previous Tabs

| Component | Source Tab | Adaptation |
|-----------|------------|------------|
| **KPI Cards** | Home, Usage | Reuse for Total Spend, Budget Remaining, Cost per Request |
| **Stacked Area Chart** | Usage | Adapt for Cost Trend by provider/model/dept |
| **Scatter Plot** | Home (Cost-Performance Quadrant) | Reuse for Provider Cost-Performance Matrix |
| **Table Component** | Usage (Top Users) | Adapt for Top Costly Agents, Optimization Leaderboard |
| **Forecast Chart** | Usage | Adapt for Cost Forecast with scenarios |

### Components Shareable to Other Tabs

| Component | Usable In | Notes |
|-----------|-----------|-------|
| **Budget Dashboard** | Business Impact | Track budget vs business goal achievement |
| **Optimization Leaderboard** | Performance, Quality | Ranked optimization opportunities for other dimensions |
| **Scenario Modeling** | Business Impact, Experiments | What-if analysis reusable pattern |
| **Provider Comparison Matrix** | Performance, Quality | Compare providers across dimensions |

---

## Risks & Assumptions

### Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Billing data lag from providers** | Medium | High | Implement estimated costs with reconciliation batch jobs; Clearly label estimates vs actuals |
| **Multi-provider pricing complexity** | High | Medium | Maintain pricing catalog; Automate pricing updates; Provide TCO calculator for comparisons |
| **Budget gaming (end-of-period spend spikes)** | Medium | Medium | Implement spend pacing alerts; Require justification for large requests; Monitor burn rate trends |
| **Cost optimization recommendations not implemented** | Medium | High | Track implementation status; Gamify with leaderboards; Executive visibility for top opportunities |
| **Cache hit rate overestimation** | Low | Medium | Validate cache performance in staging; Monitor cache staleness; Provide cache analytics |

### Assumptions

**AS3.1**: Provider billing APIs are available and reliable for real-time cost estimation  
**AS3.2**: Department budgets are set at the beginning of each period and rarely change mid-period  
**AS3.3**: Cost per request is primary unit economics metric for optimization decisions  
**AS3.4**: Token-based pricing is standard across major providers (not request-based or time-based)  
**AS3.5**: Users have appropriate financial access controls (not all users see all cost data)  

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-4)

**Week 1-2**:
- Adapt existing cost KPIs and charts for multi-dimensional filtering
- Implement department budget tracking system
- Backend: Cost aggregation by dimension (dept, provider, model)
- Backend: Budget management tables and APIs

**Week 3-4**:
- Department Budget Dashboard (3.9)
- Cost Attribution Sunburst (3.10)
- Cost Optimization Leaderboard (3.11)
- Set Department Budget action (A3.1)
- Configure Budget Alert action (A3.3)
- Set Cost Alert action (A3.9)

**Milestone**: Multi-agent cost tracking, budget management, and alerting operational

### Phase 2: Advanced (Weeks 5-8)

**Week 5-6**:
- Token Usage Waterfall (3.12)
- Cost Forecast Model (3.13)
- Provider Cost-Performance Matrix (3.14)
- Implement Model Downgrade action (A3.4)
- Enable Caching action (A3.5)
- Optimize Prompt action (A3.6)

**Week 7-8**:
- Caching ROI Calculator (3.15)
- Cost Anomaly Timeline (3.16)
- Switch Provider action (A3.7)
- Enable Request Batching action (A3.8)
- Export Cost Report action (A3.10)
- Create Cost Optimization Experiment action (A3.11)

**Milestone**: Advanced cost optimization and provider management live

### Phase 3: Autonomous (Weeks 9-12)

**Week 9-10**:
- Model Pricing Comparison Table (3.17)
- Cost Allocation Flowchart (3.18)
- Approve Cost Overage workflow (A3.12)
- Enable Token Reduction Features (A3.13)

**Week 11-12**:
- Schedule Cost Review action (A3.14)
- ML-driven cost anomaly detection fine-tuning
- Automated optimization recommendation engine
- Performance optimization and polish

**Milestone**: Autonomous cost management with ML-driven optimization complete

---

**Tab 3: Cost Management PRD Complete**

---