# Tab 2: Usage Analytics

**Route**: `/dashboard/usage`  
**Purpose**: Track adoption, engagement patterns, and agent portfolio utilization across the organization with actionable insights for optimization

## Personas & User Goals

| Persona | Primary Goals | Key Questions |
|---------|---------------|---------------|
| **Product Manager** | Understand feature adoption, identify underutilized agents, user engagement trends | Which agents are most valuable? Where should we invest development? |
| **Engineering Manager** | Resource planning, capacity forecasting, team workload distribution | Do we have capacity constraints? Which teams are most active? |
| **Director AI/ML** | Agent portfolio optimization, ROI per agent, deprecation candidates | Which agents should we retire? Where's the highest usage concentration? |
| **Business Analyst** | User segmentation, usage patterns, adoption metrics for reporting | How are different user cohorts engaging? What's our growth trajectory? |
| **Customer Success** | Power user identification, onboarding effectiveness, engagement health | Who are our champions? Are new users adopting successfully? |

## Multi-Level Structure

### Level 1: Fleet View (Default)
- Organization-wide usage metrics aggregated across all agents/departments
- Agent portfolio heat map showing usage distribution
- User segmentation analysis (power users, regular, occasional, dormant)
- Intent/use case distribution across organization

### Level 2: Filtered Subset
**Comparative Analysis**:
- Department A vs Department B usage patterns
- Version 2.0 adoption vs Version 1.9 (migration tracking)
- Production vs Staging environment usage (testing coverage)
- Intent-based filtering (e.g., "customer support" use cases only)

### Level 3: Agent Detail
- Individual agent request logs with user attribution
- User journey analysis for specific agent
- Agent-specific adoption curve and retention metrics
- Integration health (API clients calling the agent)

## Filters & Controls

### Primary Filters
| Filter | Options | Default | Behavior |
|--------|---------|---------|----------|
| **Time Range** | 1h, 24h, 7d, 30d, 90d, Custom | 30d | Longer default for trend analysis |
| **Department** | All, [List of departments], Multi-select | All | Compare up to 5 departments |
| **Agent Status** | All, Active, Beta, Deprecated | Active | Lifecycle-based filtering |
| **Intent Category** | All, Customer Support, Code Gen, Analysis, Content, Other | All | Use-case segmentation |
| **User Segment** | All, Power Users (top 10%), Regular, New (last 30d), Dormant (no activity 30d+) | All | Cohort analysis |
| **Environment** | All, Production, Staging, Development | Production | Environment comparison |
| **Provider** | All, [List of providers] | All | Provider preference analysis |

### Secondary Filters (Per chart)
- Agent ID (multi-select for comparison)
- User ID (for drill-down)
- Request status (success, error, timeout)
- Model family (GPT-4, Claude-3, etc.)

---

## Table 1: Existing Charts Adaptation

| Chart ID | Current Chart Name | Current Purpose | Required Modifications | New Filter Behavior | New Drilldown Behavior | Data Enhancements Needed | Priority |
|----------|-------------------|-----------------|----------------------|-------------------|----------------------|------------------------|----------|
| **2.1** | Total API Calls | Track overall platform usage | Add multi-department stacked area chart showing contribution by dept over time | Filters show subset; Comparison mode overlays multiple departments; Trend line includes forecast based on last 30d | Click data point → Request list for that time bucket; Click dept in legend → Dept usage deep-dive | Add `department_id`, `intent_category`, `agent_id`, `version` to request logs; Pre-aggregate hourly/daily | **P0** |
| **2.2** | Unique Users | Monitor user base growth | Transform to user segmentation view: New vs Returning vs Power Users; Add retention cohort overlay | Show filtered user count by segment; Multi-period comparison (MoM, QoQ); Churn calculation for filtered scope | Click segment → User list with activity details; Click user → User journey timeline; Hover → Engagement metrics (avg calls, last active) | Add `user_first_seen`, `user_last_seen`, `user_request_count_total`, `user_segment` to user metadata | **P0** |
| **2.3** | Active Agents | Track agent diversity | Convert to agent portfolio health matrix: Active/Beta/Deprecated counts with usage intensity heatmap | Show agents by status and usage intensity; Filter by dept shows only dept's agents; Version filter shows adoption of new vs old | Click status category → Agent list; Click agent → Agent detail dashboard; Hover → Request count, top users, last deployment | Add `agent_status`, `agent_version`, `agent_owner_team`, `last_deployed_at`, `deprecation_date` to agent registry | **P0** |
| **2.4** | Average Calls per User | Measure engagement depth | Add engagement distribution histogram + percentile indicators (P25, P50, P75, P90); Include "at risk" user identification | Show distribution for filtered scope; Overlay historical avg; Highlight outliers (>P90 and <P10) | Click histogram bar → Users in that range; Click outlier → User detail; Hover → Sample user examples | Add `user_daily_calls[]`, `user_engagement_score`, `days_active_last_30d` to user activity aggregation | **P1** |
| **2.5** | API Calls Over Time | Visualize temporal usage patterns | Enhance with: (1) Hour-of-day heatmap for peak identification, (2) Day-of-week seasonality, (3) Anomaly markers, (4) Forecast line | Multi-department overlay for comparison; Version toggle to see adoption curves; Environment split for test vs prod | Click time bucket → Request details; Click anomaly → Root cause suggestions; Hover → Breakdown by agent and dept | Add `hour_of_day`, `day_of_week`, `is_anomaly`, `forecast_value` to time-series aggregation | **P0** |
| **2.6** | Agent Distribution | Show agent usage concentration | Transform to Sunburst or Treemap: Dept → Agent → Intent hierarchy; Add Gini coefficient for concentration measurement | Filter by dept shows only that dept's agents; Color by usage intensity; Size by request volume | Click dept segment → Dept agents view; Click agent → Agent detail; Hover → Usage stats, cost, quality score | Add hierarchical structure: `department_id` → `agent_id` → `intent_category` with request counts at each level | **P1** |
| **2.7** | Top Users Table | Identify power users | Add columns: Dept, Intent Preference, Cost Impact, Risk Score (concentration); Add export button; Increase to Top 20 | Filter by dept, segment; Sort by any column; Search by user ID or name | Click user → User activity dashboard; Click dept → Dept dashboard; Click "View All" → Full user table | Add `user_department`, `user_primary_intent`, `user_cost_contribution`, `user_concentration_risk_score` | **P0** |

---

## Table 2: New Charts Addition

| Chart ID | Chart Name | Description | Priority | D3 Visualization Type | Backend Data Required | Multi-Agent Behavior | Drilldown Behavior |
|----------|------------|-------------|----------|----------------------|----------------------|---------------------|-------------------|
| **2.8** | Intent Distribution Matrix | Heatmap showing which departments use which intent categories most | **P0** | Matrix Heatmap (d3-scale-chromatic, sequential) | Aggregation: `department_id`, `intent_category`, `request_count`, `pct_of_dept_total` | Rows = Departments, Columns = Intents; Color intensity = Usage %; Marginal totals show dept and intent popularity | Click cell → Agents in dept+intent; Click row → Dept deep-dive; Click column → Intent analysis |
| **2.9** | User Retention Cohort Analysis | Cohort retention table showing user stickiness over time | **P0** | Cohort Table (heatmap style) | User cohorts by signup month; Retention % for each subsequent month; Fields: `cohort_month`, `month_offset`, `retained_users`, `retention_pct` | Rows = Signup cohorts (month), Columns = Months since signup; Color = Retention %; Filter by dept, agent, intent | Click cohort cell → Users in that cohort+month; Hover → Absolute numbers; Export cohort data |
| **2.10** | Agent Adoption Curve | S-curve showing adoption trajectory for new agents/versions | **P1** | Multi-line chart with cumulative adoption | Per agent/version: `date`, `cumulative_users`, `cumulative_requests`, `adoption_rate` | One line per agent/version; Color by lifecycle stage; Benchmark against historical successful launches | Click line → Agent detail; Hover → Daily adoption metrics; Overlay → Forecast future adoption |
| **2.11** | User Journey Sankey | Flow diagram showing user navigation between agents | **P1** | Sankey Diagram (d3-sankey) | User session data: `user_id`, `agent_sequence[]`, `transition_count`, `session_length` | Nodes = Agents, Links = Transitions; Link thickness = Frequency; Filter by dept, time range | Click node → Agent detail; Click link → Sessions with that transition; Hover → Transition frequency |
| **2.12** | Usage Forecast Model | ML-driven forecast for next 30/60/90 days with confidence intervals | **P1** | Line chart with confidence bands (area fill) | Historical usage: `date`, `request_count`, `forecast_value`, `confidence_lower`, `confidence_upper`, `model_type` | Separate forecasts for: Fleet, Per Dept, Per Agent; Model explainability tooltip; Accuracy tracking | Click forecast period → Assumptions and model details; Hover → Confidence interval values; Export forecast data |
| **2.13** | Capacity Utilization Gauge | Real-time gauge showing current vs max capacity by resource type | **P1** | Radial Gauge / Bullet Chart | Resource metrics: `resource_type`, `current_usage`, `max_capacity`, `warning_threshold`, `critical_threshold` | One gauge per resource (API rate limits, compute, memory, tokens/min); Color-coded status (green/yellow/red) | Click gauge → Resource detail with time-series; Hover → Threshold values; Alert config shortcut |
| **2.14** | Agent Dependency Graph | Network graph showing which agents call other agents (agentic workflows) | **P2** | Force-Directed Graph (d3-force) | Agent call graph: `source_agent_id`, `target_agent_id`, `call_count`, `avg_latency` | Nodes = Agents, Edges = Calls; Node size = Request volume; Edge thickness = Call frequency; Filter by dept | Click node → Agent detail; Click edge → Call traces; Hover → Call metrics; Layout controls (hierarchical/force/radial) |
| **2.15** | Geographic Usage Map | World map showing request volume by user location | **P2** | Choropleth + Bubble Map (d3-geo) | Geolocation data: `country`, `region`, `city`, `latitude`, `longitude`, `request_count`, `user_count`, `avg_latency` | Map colored by request density; Bubbles sized by user count; Filter by dept, agent, intent | Click region → Users in region; Hover → Stats; Zoom → City-level detail; Switch projection (Mercator/Robinson) |
| **2.16** | Time-of-Day Usage Heatmap | 24x7 heatmap showing peak usage patterns by hour and day | **P1** | Calendar Heatmap (hour × day grid) | Time aggregation: `hour_of_day`, `day_of_week`, `request_count_avg`, `percentile_rank` | Rows = Hours (0-23), Columns = Days (Mon-Sun); Color = Request intensity; Overlay maintenance windows | Click cell → Requests in that hour/day; Hover → Request count; Identify maintenance windows |

---

## Table 3: Actionable Interventions

| Action ID | Action Name | Description | Trigger | Required UI Components | Required Backend/Data | Who Can Perform It | Scope | Expected Business Outcome | Dependencies | Priority |
|-----------|-------------|-------------|---------|----------------------|---------------------|-------------------|-------|---------------------------|--------------|----------|
| **A2.1** | Promote Agent | Feature an underutilized agent to increase adoption | Manual | "Promote Agent" button on agent detail; Promotion channels selector (email, in-app banner, docs); Target audience (dept, user segment) | Promotion campaign API; Email/notification service; User targeting engine | Product Manager, Director AI/ML | Agent-specific | Adoption ↑, Portfolio diversification ↑, Agent ROI ↑ | Agent registry, Notification service | **P1** |
| **A2.2** | Deprecate Agent | Mark agent for end-of-life with migration plan | Manual | Deprecation modal; Deprecation date picker; Replacement agent selector; User notification config; Migration guide link | Agent lifecycle API; Deprecation schedule; User notification; Request routing rules (gradual sunset) | Director AI/ML, Engineering Manager | Agent-specific | Maintenance cost ↓, User experience ↑ (migrate to better), Tech debt ↓ | Agent registry, Migration tooling | **P0** |
| **A2.3** | Create User Segment | Define custom user cohort for targeted analysis or campaigns | Manual | Segment builder UI; Criteria selector (request count range, agents used, dept, engagement score); Segment name; Save/share options | User segmentation engine; Segment storage; Query builder for complex criteria | Product Manager, Business Analyst, Customer Success | Fleet-wide or Dept-specific | Targeted optimization ↑, Personalization ↑, Marketing efficiency ↑ | User metadata, Activity logs | **P1** |
| **A2.4** | Export User List | Download list of users matching filter criteria | Manual | "Export Users" button; Format selector (CSV, JSON); Field selector (user_id, dept, activity stats, contact info) | User data export API; Privacy compliance checks (PII redaction if needed); Export job queue | Engineering Manager, Customer Success, Business Analyst | Filtered scope | Sales outreach ↑, User research ↑, Support targeting ↑ | User directory, RBAC (privacy controls) | **P1** |
| **A2.5** | Set Capacity Threshold Alert | Configure alerts when usage approaches capacity limits | Manual | Threshold config modal; Resource selector; Warning level (%, absolute); Notification channels; Escalation policy | Capacity monitoring; Alert rule engine; Threshold evaluation (real-time or periodic) | Platform Architect, DevOps, Engineering Manager | Global or Environment-specific | Service reliability ↑, Proactive scaling ↑, Incident prevention ↑ | Resource monitoring, Alert system | **P0** |
| **A2.6** | Schedule Agent Downtime | Plan maintenance window with automatic user notifications | Manual | Maintenance scheduler; Agent selector; Start/end time; Impact estimate (affected users); Notification template | Agent maintenance API; Request routing (fail-over or queue); User notification service; Calendar integration | DevOps, Engineering Manager | Agent-specific or Agent-group | User communication ↑, Incident reduction ↓ (planned vs unplanned), Trust ↑ | Agent routing, Notification service, Failover system | **P1** |
| **A2.7** | Clone Agent Configuration | Duplicate agent settings to create similar agent faster | Manual | "Clone Agent" button; New agent name input; Config review/edit modal; Department assignment | Agent registry CRUD API; Config validation; Version control for agent configs | Engineer, ML Engineer, Product Manager | Agent-specific (source) → New agent | Development velocity ↑, Configuration consistency ↑, Time to market ↓ | Agent registry, Config management | **P2** |
| **A2.8** | Invite User to Platform | Onboard new users with guided setup | Manual | "Invite User" button; Email input; Department/role selector; Initial agent assignment; Welcome email template | User management API; Email service; Onboarding workflow; Access provisioning | Engineering Manager, Customer Success, Admin | Fleet-wide | Adoption ↑, Onboarding friction ↓, Time to value ↓ | User directory, RBAC, Email service | **P1** |
| **A2.9** | Create Usage Report | Generate custom usage report for specific stakeholders | Manual | Report builder; Metric selector (requests, users, costs, etc.); Filter/grouping options; Schedule/one-time; Recipients | Report generation engine; Data aggregation; Scheduling system; Distribution (email, Slack, shared drive) | Product Manager, Business Analyst, Director AI/ML | Filtered scope | Stakeholder communication ↑, Decision velocity ↑, Transparency ↑ | All usage data sources, Report templates | **P1** |
| **A2.10** | Set Agent Request Quota | Limit max requests per agent per time period (rate limiting) | Manual | Quota config modal; Agent selector; Quota value (requests/min or /hour or /day); Overage behavior (queue, reject, throttle) | Rate limiting service; Quota enforcement; Request queue management; Overage alerting | Platform Architect, DevOps, Finance (cost control) | Agent-specific or Global | Cost control ↑, Fair usage ↑, Abuse prevention ↑ | Rate limiter, Request router | **P0** |
| **A2.11** | Configure Intent Tagging Rules | Auto-classify requests into intent categories using rules or ML | Manual | Intent rule builder; Pattern matcher (regex, keywords, ML model selector); Intent category assignment; Test cases | Intent classification service (rule engine + ML model); Auto-tagging pipeline; Training data management | ML Engineer, Product Manager | Global or Dept-specific | Analytics accuracy ↑, Segmentation quality ↑, Insight clarity ↑ | Request metadata, ML model infrastructure | **P2** |
| **A2.12** | Enable Auto-Retry for Failed Requests | Automatically retry failed agent requests with configurable backoff | Manual / Automated (toggle) | Auto-retry toggle; Max retry count input; Backoff strategy selector (exponential, linear, fixed); Error types to retry | Request retry service; Failure classification; Backoff logic; Retry telemetry | DevOps, Engineering Manager | Agent-specific or Global | Success rate ↑, User experience ↑, Error rate ↓ | Request orchestration, Error handling | **P1** |

---

## Backend Metrics Schema

### Required Tables/Collections

#### `usage_summary_by_dimension` (Multi-dimensional aggregation)
```sql
{
  timestamp: DateTime (indexed),
  time_bucket: String (hourly, daily, weekly, monthly),
  
  -- Dimensional keys (nullable for aggregation flexibility)
  department_id: String (indexed, nullable),
  agent_id: String (indexed, nullable),
  environment: String (indexed, nullable),
  version: String (nullable),
  intent_category: String (indexed, nullable),
  user_segment: String (nullable),
  
  -- Usage metrics
  request_count: Integer,
  unique_user_count: Integer,
  unique_agent_count: Integer,
  success_count: Integer,
  error_count: Integer,
  
  -- Engagement metrics
  avg_calls_per_user: Decimal(10,2),
  session_count: Integer,
  avg_session_length_min: Decimal(10,2),
  
  -- Comparative
  prev_period_request_count: Integer,
  prev_period_user_count: Integer,
  growth_rate_pct: Decimal(5,2)
}
```

#### `user_engagement_profile` (User-level aggregation)
```sql
{
  user_id: String (primary, indexed),
  department_id: String (indexed),
  
  -- Lifecycle
  first_seen_at: DateTime,
  last_active_at: DateTime,
  user_segment: Enum (power_user, regular, new, dormant),
  days_since_last_active: Integer,
  
  -- Usage stats
  total_requests_lifetime: Integer,
  total_requests_last_30d: Integer,
  avg_daily_requests: Decimal(10,2),
  days_active_last_30d: Integer,
  
  -- Agent usage
  agents_used_lifetime: Array<String> (agent_ids),
  agents_used_last_30d: Array<String>,
  primary_agent_id: String (most used),
  
  -- Intent preferences
  primary_intent_category: String,
  intent_diversity_score: Decimal(3,2) (0-1, entropy-based),
  
  -- Risk/Value
  cost_contribution: Decimal(10,2),
  concentration_risk_score: Decimal(3,2) (high if 1 agent = 90% of activity),
  engagement_score: Integer (0-100, composite metric),
  
  -- Retention
  cohort_month: String (YYYY-MM format),
  retention_day_7: Boolean,
  retention_day_30: Boolean,
  retention_day_90: Boolean
}
```

#### `agent_metadata_extended` (Enhanced agent registry)
```sql
{
  agent_id: String (primary),
  agent_name: String,
  agent_description: Text,
  
  -- Ownership & Organization
  owner_team: String,
  department_id: String (indexed),
  business_unit: String,
  
  -- Lifecycle
  agent_status: Enum (active, beta, deprecated, archived),
  version: String,
  created_at: DateTime,
  last_deployed_at: DateTime,
  deprecation_date: DateTime (nullable),
  replacement_agent_id: String (nullable),
  
  -- Usage
  total_requests_lifetime: Integer,
  total_requests_last_30d: Integer,
  unique_users_last_30d: Integer,
  avg_daily_requests: Decimal(10,2),
  
  -- Performance
  avg_latency_ms: Integer,
  error_rate_pct: Decimal(5,2),
  quality_score_avg: Decimal(3,1),
  
  -- Cost
  cost_per_request: Decimal(10,4),
  total_cost_last_30d: Decimal(10,2),
  
  -- Configuration
  max_requests_per_minute: Integer (quota),
  allowed_users: Array<String> (nullable, if restricted),
  allowed_departments: Array<String> (nullable),
  
  -- Metadata
  tags: Array<String>,
  documentation_url: String,
  support_contact: String
}
```

#### `intent_classification_rules` (Intent auto-tagging)
```sql
{
  rule_id: UUID (primary),
  rule_name: String,
  intent_category: String,
  
  -- Rule logic
  rule_type: Enum (regex, keyword, ml_model),
  pattern: String (regex or keyword list),
  ml_model_id: String (nullable),
  confidence_threshold: Decimal(3,2) (for ML),
  
  -- Scope
  applicable_agents: Array<String> (nullable, if agent-specific),
  applicable_departments: Array<String> (nullable),
  
  -- Metadata
  priority: Integer (execution order),
  is_active: Boolean,
  created_by: String (user_id),
  last_updated_at: DateTime
}
```

#### `user_session_traces` (For journey analysis)
```sql
{
  session_id: UUID (primary),
  user_id: String (indexed),
  session_start: DateTime (indexed),
  session_end: DateTime,
  session_duration_minutes: Decimal(10,2),
  
  -- Agent sequence
  agent_sequence: Array<String> (ordered agent_ids),
  request_count: Integer,
  success_count: Integer,
  error_count: Integer,
  
  -- Context
  department_id: String,
  environment: String,
  user_agent: String (browser/API client),
  geo_location: String (country code),
  
  -- Outcomes
  session_successful: Boolean,
  exit_reason: Enum (completed, error, timeout, user_abandoned)
}
```

#### `usage_forecast_models` (ML forecast storage)
```sql
{
  forecast_id: UUID (primary),
  forecast_date: Date (indexed),
  forecast_horizon_days: Integer (30, 60, 90),
  
  -- Scope
  aggregation_level: Enum (fleet, department, agent),
  dimension_id: String (nullable, dept or agent ID),
  
  -- Forecast values (time-series array)
  forecast_data: JSON {
    date: Date,
    predicted_requests: Integer,
    confidence_lower: Integer,
    confidence_upper: Integer,
    prediction_interval: Decimal(3,2) (0.95 for 95% CI)
  }[],
  
  -- Model metadata
  model_type: String (ARIMA, Prophet, LSTM, etc.),
  model_accuracy_mape: Decimal(5,2) (Mean Absolute Percentage Error),
  training_data_start: Date,
  training_data_end: Date,
  
  -- Generated
  generated_at: DateTime,
  generated_by: String (system or user_id)
}
```

---

## Cross-Tab Dependencies

### Actions Affecting Multiple Tabs

| Action | Primary Tab | Secondary Tabs Affected | Dependency Chain |
|--------|-------------|------------------------|------------------|
| **Deprecate Agent** (A2.2) | Usage | Home (↓ active agent count), Cost (cost shift to replacement agent), Performance (latency change), Quality (quality shift) | Requires: Agent registry, Migration plan; Impacts: All agent-specific charts, Routing rules, User notifications |
| **Set Agent Request Quota** (A2.10) | Usage | Performance (may ↑ latency if queueing), Cost (↓ overage costs), Incidents (may ↑ rate limit errors) | Requires: Rate limiter; Impacts: Request distribution, Error rates, Cost control |
| **Enable Auto-Retry** (A2.12) | Usage | Performance (↑ successful requests, variable latency), Cost (↑ due to retries), Quality (may ↑ if errors were transient) | Requires: Retry logic, Failure classification; Impacts: Success rate, Request volume, Cost efficiency |

---

## Acceptance Criteria

### Functional Requirements

**FR2.1**: All usage metrics must update within 2 minutes of request completion  
**FR2.2**: User segmentation must recalculate daily at 00:00 UTC  
**FR2.3**: Retention cohort analysis must support historical cohorts back to platform launch date  
**FR2.4**: Intent classification rules must apply to new requests within 10 seconds  
**FR2.5**: Agent adoption curves must support comparison of up to 10 agents simultaneously  
**FR2.6**: User journey Sankey must render sessions up to 20 agent transitions  
**FR2.7**: Geographic map must support zoom to city-level detail (min population 100k)  

### Data Accuracy Requirements

**DA2.1**: Unique user counts must deduplicate by user_id with 100% accuracy  
**DA2.2**: Agent distribution percentages must sum to exactly 100%  
**DA2.3**: Retention cohort calculations must match SQL queries (no rounding discrepancies)  
**DA2.4**: Usage forecast MAPE must be <15% for 30-day horizon, <25% for 90-day  

### Performance Requirements

**PR2.1**: Usage Analytics tab initial load <2 seconds for default 30-day range  
**PR2.2**: Department comparison must support up to 20 departments without pagination  
**PR2.3**: Intent distribution heatmap must render <3 seconds for 50 intents × 20 departments  
**PR2.4**: User journey Sankey must render <5 seconds for 1000 sessions  
**PR2.5**: Agent deprecation workflow must complete (notifications sent) within 60 seconds  

### UX Requirements

**UX2.1**: All time-series charts must support zoom (click-drag) and pan  
**UX2.2**: Cohort retention table must use color gradient (green = high retention, red = low)  
**UX2.3**: Agent dependency graph must support layout switching (force/hierarchical/radial)  
**UX2.4**: Export functionality must show progress indicator for jobs >5 seconds  
**UX2.5**: All tables must support column sorting, searching, and CSV export  

---

## Reuse Notes

### Components from Tab 1 (Home Dashboard)

| Component | Reuse | Adaptation Needed |
|-----------|-------|-------------------|
| **Filter Bar** | Yes | Add Intent Category and User Segment filters |
| **KPI Cards** | Yes | Reuse for Total API Calls, Unique Users, Active Agents, Avg Calls/User |
| **Time-Series Chart** | Yes | Adapt for API Calls Over Time with multi-line overlays |
| **Table Component** | Yes | Reuse for Top Users Table with sorting/export |

### Components Shareable to Other Tabs

| Component | Usable In | Notes |
|-----------|-----------|-------|
| **Intent Distribution Heatmap** | Quality, Business Impact | Can show quality scores or impact by intent |
| **User Segmentation Logic** | Cost, Performance, Quality | Segment-based filtering universally useful |
| **Cohort Retention Table** | Business Impact | Show retention impact of initiatives |
| **Agent Adoption Curve** | Experiments | Compare experiment arms with adoption curves |

---

## Risks & Assumptions

### Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **User tracking concerns (privacy)** | High | Medium | Implement strict RBAC, anonymization options, compliance with GDPR/CCPA |
| **Intent classification accuracy low** | Medium | Medium | Provide manual override, confidence scoring, active learning loop |
| **Forecast models inaccurate** | Medium | Medium | Display confidence intervals, model accuracy metrics, allow user adjustments |
| **Agent dependency graph too complex (>100 agents)** | Low | Medium | Implement graph clustering, hierarchical grouping, hide low-frequency edges |
| **Geographic data missing for many users** | Low | High | Gracefully handle nulls, provide "Unknown" category, fallback to IP-based geo |

### Assumptions

**AS2.1**: User IDs are consistent and immutable across sessions  
**AS2.2**: Intent categories are predefined and relatively stable (<10 categories)  
**AS2.3**: Agent registry is kept up-to-date by engineering teams  
**AS2.4**: Deprecation requires at least 30-day notice period  
**AS2.5**: User segmentation criteria are agreed upon by product team  

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-4)

**Week 1-2**:
- Adapt existing KPIs (2.1-2.4) and charts (2.5-2.7) for multi-agent
- Implement department, intent, user segment filters
- Backend: User engagement profile aggregation
- Backend: Agent metadata extension

**Week 3-4**:
- Intent Distribution Matrix (2.8)
- User Retention Cohort Analysis (2.9)
- Deprecate Agent workflow (A2.2)
- Set Agent Request Quota (A2.10)

**Milestone**: Core usage analytics with multi-agent support operational

### Phase 2: Advanced (Weeks 5-8)

**Week 5-6**:
- Agent Adoption Curve (2.10)
- Time-of-Day Usage Heatmap (2.16)
- User Journey Sankey (2.11)
- Promote Agent action (A2.1)
- Create User Segment action (A2.3)

**Week 7-8**:
- Usage Forecast Model (2.12)
- Capacity Utilization Gauge (2.13)
- Set Capacity Threshold Alert (A2.5)
- Schedule Agent Downtime (A2.6)
- Enable Auto-Retry (A2.12)

**Milestone**: Advanced analytics and proactive capacity management live

### Phase 3: Autonomous (Weeks 9-12)

**Week 9-10**:
- Agent Dependency Graph (2.14)
- Geographic Usage Map (2.15)
- Configure Intent Tagging Rules (A2.11)

**Week 11-12**:
- Clone Agent Configuration (A2.7)
- Invite User to Platform (A2.8)
- Create Usage Report (A2.9)
- ML model fine-tuning for forecasts

**Milestone**: Full portfolio management and autonomous insights operational

---

**Tab 2: Usage Analytics PRD Complete**

---