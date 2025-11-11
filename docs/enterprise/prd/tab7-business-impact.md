---

# Tab 7: Business Impact

**Route**: `/dashboard/impact`
**Purpose**: Connect technical metrics to business outcomes, track ROI, goal achievement, cost savings validation, productivity gains, and stakeholder value demonstration

## Personas & User Goals

| Persona | Primary Goals | Key Questions |
|---------|---------------|---------------|
| **C-Suite Executive** | ROI validation, strategic value assessment, investment justification, board reporting | Is AI delivering promised value? What's our ROI? Should we expand AI investment? |
| **Business Unit Leader** | Department-specific impact measurement, goal achievement tracking, budget justification | Is my team achieving goals? Can I justify continued investment? What's our productivity gain? |
| **Finance Director** | Cost savings validation, payback period calculation, TCO analysis, budget forecasting | Have we recouped investment? What's actual cost savings? When do we break even? |
| **Product Manager** | Feature impact measurement, user satisfaction tracking, adoption metrics, value realization | Are new features delivering value? Are users satisfied? What's the business case for expansion? |
| **Customer Success Leader** | Customer outcomes, satisfaction trends, retention impact, customer lifetime value | Are customers successful with AI agents? Is satisfaction improving? Impact on retention? |

## Multi-Level Structure

### Level 1: Fleet View
- Organization-wide ROI, payback period, and net value created
- Business goal dashboard aggregated across all departments
- Customer impact metrics (CSAT, NPS, retention, ticket deflection)
- Impact attribution modeling (which agents/departments drive most value)
- Cost savings waterfall (labor savings, efficiency gains, error reduction)

### Level 2: Filtered Subset
- Department-specific impact and goal tracking
- Agent-level value contribution analysis
- Use case impact comparison (support vs sales vs operations)
- Business unit ROI comparison
- Goal achievement leaderboards

### Level 3: Agent + Business Metric Detail
- Individual agent business metrics and value contribution
- User testimonials and satisfaction scores for specific agent
- Before/after comparisons for agent deployments
- Goal progress drill-down with contributing factors
- Time-to-value analysis for agent initiatives

## Filters

| Filter | Options | Default |
|--------|---------|---------|
| **Time Range** | 1 month, 1 quarter, 6 months, 1 year, All Time, Custom | 1 quarter |
| **Department** | All, [List] | All |
| **Business Unit** | All, [List] | All |
| **Use Case** | All, Customer Support, Sales, Operations, HR, Finance, IT, [Custom] | All |
| **Goal Status** | All, On Track, At Risk, Behind, Completed | All |
| **Value Type** | All, Cost Savings, Revenue Impact, Productivity Gain, Quality Improvement | All |

---

## Table 1: Existing Charts Adaptation

| Chart ID | Current Name | Required Modifications | New Metrics | Multi-Level Filtering | Interactivity | Caching Strategy | Priority |
|----------|--------------|----------------------|-------------|----------------------|---------------|------------------|----------|
| **7.1** | Cost KPI (from Tab 3) | Transform into ROI KPI with payback period; Add net value created; Investment vs savings comparison | ROI %, payback period (months), net value, investment amount, cumulative savings | Fleet: Overall ROI; Subset: By dept/use case; Detail: By agent contribution | Click to drill into ROI components; Hover for calculation details | 30min TTL for fleet; 15min for subset | **P0** |
| **7.2** | Usage Trends (from Tab 2) | Overlay with business value metrics; Show correlation between usage and business outcomes; Add value per request | Usage volume, value per request, total value created, correlation coefficient | Fleet: All usage value; Subset: By dept/use case; Detail: By agent value contribution | Click to see value drivers; Toggle correlation view | 15min TTL | **P0** |
| **7.3** | Agent Performance (from Tab 4) | Add business impact scoring; Correlate performance with outcomes; Show value-weighted performance | Business impact score, performance × value, outcome correlation | Fleet: Top value agents; Subset: By dept performance; Detail: Agent impact breakdown | Sort by business impact; Compare performance vs value | 10min TTL | **P0** |
| **7.4** | Quality Score (from Tab 5) | Link quality to customer satisfaction; Show quality → CSAT correlation; Add business impact of quality | Quality-CSAT correlation, CSAT by quality tier, business impact of quality improvement | Fleet: Overall quality-value link; Subset: By dept quality impact; Detail: Agent quality value | Click quality tier to see CSAT; Show improvement scenarios | 15min TTL | **P0** |
| **7.5** | Error Tracking (from Tab 4) | Quantify business cost of errors; Show error impact on customer satisfaction; Add error cost calculation | Error cost ($ impact), customer impact, lost opportunity value | Fleet: Total error cost; Subset: By dept error impact; Detail: By agent error cost | Click to see costly errors; Filter by impact severity | 10min TTL | **P0** |

---

## Table 2: New Charts Addition

| Chart ID | Chart Name | Description | Personas | Data Sources | D3 Visualization | Tech Implementation | Priority |
|----------|------------|-------------|----------|--------------|------------------|---------------------|----------|
| **7.6** | ROI Calculator Dashboard | Interactive ROI calculator with what-if scenarios; Inputs: investment, labor costs, productivity gains, time savings; Outputs: ROI %, payback period, NPV | C-Suite Executive, Finance Director, Business Unit Leader | `traces` (usage, cost); `business_goals` (targets); Manual inputs for labor costs | Interactive dashboard with input sliders, real-time ROI calculation, scenario comparison | React form with dynamic calculations; PostgreSQL for historical data; Redis cache (30min TTL); D3 for visualization | **P0** |
| **7.7** | Business Goal Progress Tracker | Hierarchical goal visualization showing organizational goals → department goals → agent goals; Progress bars, status indicators, deadline tracking | C-Suite Executive, Business Unit Leader | `business_goals` table (hierarchy, targets, actuals, deadlines) | Hierarchical tree or sunburst chart with progress indicators, color-coded status | PostgreSQL goal hierarchy queries; Progress calculation; Redis cache (10min TTL); D3 tree or sunburst | **P0** |
| **7.8** | Impact Attribution Model | Statistical model showing which agents, departments, or features contribute most to business value; Attribution coefficients with confidence intervals | C-Suite Executive, Product Manager | `traces`, `business_goals`, `customer_metrics`; ML attribution model | Waterfall chart showing value attribution, contribution percentages | Gemini ML for attribution modeling; PostgreSQL aggregations; Redis cache (30min TTL); D3 waterfall | **P0** |
| **7.9** | Customer Impact Timeline | Time-series showing customer satisfaction metrics (CSAT, NPS, retention, ticket volume) correlated with agent deployments and optimizations | Customer Success Leader, Product Manager | `customer_metrics` table; Agent deployment events; Satisfaction surveys | Multi-line chart with event markers, correlation annotations | TimescaleDB time-series; Event correlation analysis; Redis cache (15min TTL); D3 multi-line with annotations | **P0** |
| **7.10** | Savings Realization Waterfall | Waterfall chart showing journey from gross savings opportunity → realized savings → net savings after costs; Breaks down by category (labor, efficiency, quality) | Finance Director, C-Suite Executive | Cost data, savings calculations, investment amounts | Waterfall chart with category breakdown, cumulative value | PostgreSQL savings calculations; Category aggregation; Redis cache (30min TTL); D3 waterfall | **P0** |
| **7.11** | Productivity Gain Quantification | Metrics showing time saved, tasks automated, throughput increase; Converts to FTE equivalents and dollar value | Business Unit Leader, Finance Director | `traces` (latency, volume); Baseline comparisons; Time savings models | Grouped bar chart comparing before/after, FTE equivalents, dollar conversion | PostgreSQL time savings aggregation; FTE calculation; Redis cache (15min TTL); D3 grouped bars | **P0** |
| **7.12** | Value Realization Curve | S-curve showing value realization over time from initial investment through payback to maturity; Shows current position and projected trajectory | C-Suite Executive, Finance Director | Investment timeline; Cumulative value created over time; Projection model | S-curve with current position marker, projection line, key milestone annotations | TimescaleDB cumulative aggregations; ML projection model; Redis cache (1hr TTL); D3 curve with annotations | **P1** |
| **7.13** | Department Impact Scorecard | Scorecard comparing departments across multiple impact dimensions (ROI, goal achievement, cost savings, customer satisfaction, productivity) | C-Suite Executive, Business Unit Leader | Aggregated metrics by department; Multi-dimensional scoring | Heatmap or radar chart showing department performance across dimensions | PostgreSQL department aggregations; Multi-dimensional scoring; Redis cache (20min TTL); D3 heatmap or radar | **P1** |
| **7.14** | Use Case ROI Comparison | Comparative analysis of ROI across different use cases (customer support, sales, operations, etc.); Identifies highest-value applications | Product Manager, C-Suite Executive | `traces` tagged with use case; Cost and value by use case | Grouped bar chart or bubble chart with use cases, ROI %, and investment size | PostgreSQL use case grouping; ROI calculation; Redis cache (30min TTL); D3 grouped bars or bubble chart | **P1** |
| **7.15** | Customer Testimonial Feed | Curated feed of customer satisfaction scores, testimonials, and success stories; Filterable by agent, department, time | Customer Success Leader, Product Manager | `customer_feedback` table; Satisfaction scores; Testimonial text | Card-based feed with ratings, quotes, timestamps, filter controls | PostgreSQL feedback queries; Sentiment analysis; Redis cache (10min TTL); React card grid | **P1** |
| **7.16** | Before/After Comparison | Side-by-side comparison of key metrics before and after agent deployment; Shows pre/post performance across multiple dimensions | Business Unit Leader, Product Manager | Historical baseline data; Post-deployment metrics | Split-view comparison with metric deltas, percentage improvements | PostgreSQL historical comparisons; Statistical significance testing; Redis cache (30min TTL); React split view | **P2** |
| **7.17** | Stakeholder Value Matrix | 2x2 matrix plotting agents/features by effort vs impact; Identifies quick wins and strategic investments | C-Suite Executive, Product Manager | Effort estimates; Impact metrics; Prioritization scores | 2x2 matrix scatter plot with quadrant labels, bubble sizing by potential value | PostgreSQL effort/impact data; Scoring algorithm; Redis cache (1hr TTL); D3 scatter with quadrants | **P2** |

---

## Table 3: Actionable Interventions

| Action ID | Action Name | Description | Trigger Context | Expected Outcome | Side Effects | Rollback Strategy | User Confirmation | Audit Trail | Observability | Priority |
|-----------|-------------|-------------|-----------------|------------------|--------------|-------------------|-------------------|-------------|---------------|----------|
| **A7.1** | Set Business Goal | Create business goal with target, deadline, owner, and success metrics; Link to specific agents or departments; Define tracking methodology | User clicks "Set Goal" from business impact dashboard or goal tracker | Goal active in system; Progress automatically tracked; Stakeholders notified; Dashboard shows goal status | Team receives goal notifications and progress updates; Accountability assigned | Delete goal or mark as inactive | Yes - define goal details, target, timeline, owner, and success metrics | Log goal creation with all parameters; Track progress updates and milestone achievements | Goal progress visible in dashboard; Alerts when off-track; Milestone notifications | **P0** |
| **A7.2** | Configure Impact Tracking | Define mapping between technical metrics (latency, quality, cost) and business outcomes (CSAT, productivity, savings); Set up attribution model | User clicks "Configure Impact" from business impact settings | Technical metrics automatically converted to business impact; Attribution model active; Impact visible in dashboards | Requires baseline data for comparison; May need manual input for some mappings | Disable impact tracking or revert to previous mapping | Yes - review metric-to-outcome mappings and attribution logic | Log impact configuration with mappings and attribution model parameters | Impact metrics appear across all dashboards; Correlation analysis runs automatically | **P0** |
| **A7.3** | Generate Executive Report | Create automated executive summary report with ROI, goal progress, key wins, risks, and recommendations; Exportable as PDF or presentation | User clicks "Generate Report" from business impact dashboard or scheduled automatically | Comprehensive executive report generated; Charts, metrics, and narrative included; Ready for stakeholder sharing | None | N/A | No for scheduled reports; Yes for manual generation with customization options | Log report generation with scope, timestamp, and distribution list | Report includes all key impact metrics; Downloadable in multiple formats | **P0** |
| **A7.4** | Create Business Case | Generate business case document for new agent initiative or optimization; Includes projected ROI, costs, benefits, risks, and timeline | User clicks "Create Business Case" from impact dashboard or planning tools | Business case document generated; Financial projections included; Risk assessment completed; Approval workflow initiated | Requires input assumptions (costs, expected benefits, timelines) | Delete draft business case | Yes - provide initiative details, cost estimates, expected benefits, and timeline | Log business case creation with all assumptions and projections | Business case visible in planning dashboard; Approval status tracked | **P0** |
| **A7.5** | Link Agent to Goal | Associate specific agent with business goal to track contribution; Enables agent-level impact attribution and goal progress | User clicks "Link to Goal" from agent detail or goal configuration | Agent performance automatically contributes to goal tracking; Impact attribution clear; Progress updates include agent contribution | Agent changes may affect goal progress; Dependency created | Unlink agent from goal | Yes - confirm agent-goal mapping and contribution weight | Log agent-goal linkage with contribution model | Agent contribution visible in goal dashboard; Agent detail shows goal impact | **P0** |
| **A7.6** | Run ROI Scenario Analysis | Execute what-if scenario analysis for ROI projections; Adjust variables (usage, costs, efficiency) to see impact on ROI and payback | User clicks "Run Scenario" from ROI calculator; Adjusts input parameters | Multiple ROI scenarios calculated; Comparison view shows best/worst/likely cases; Sensitivity analysis completed | None (read-only analysis) | N/A | No - interactive tool with real-time updates | Log scenario parameters and results for future reference | Scenario results displayed in comparison view; Sensitivity charts show variable impact | **P1** |
| **A7.7** | Request Customer Feedback | Trigger customer satisfaction survey for agents in specific use case or department; Collects CSAT, NPS, testimonials | User clicks "Request Feedback" from customer impact dashboard | Survey sent to customers; Responses collected; Metrics updated; Testimonials captured | Survey fatigue if overused; Response rate may vary | N/A (survey already sent) | Yes - select customer segment, survey type, and timing | Log feedback request with recipients, response rate, and results | Survey responses appear in customer impact dashboard; Sentiment analysis runs automatically | **P1** |
| **A7.8** | Calculate Cost Savings | Run comprehensive cost savings analysis comparing current state to baseline (before AI agents); Breaks down by category (labor, efficiency, quality) | User clicks "Calculate Savings" from savings waterfall or finance dashboard | Detailed savings calculation completed; Category breakdown available; Comparison to projections shown | Requires accurate baseline data; Manual validation recommended | Revert to previous calculation if assumptions change | Yes - review baseline assumptions and calculation methodology | Log savings calculation with all inputs, assumptions, and results | Savings breakdown visible in dashboard; Variance from projections highlighted | **P1** |
| **A7.9** | Set Value Alert | Configure alert when business impact metric crosses threshold (e.g., ROI < 15%, goal progress < 50% with 30% time remaining, CSAT drop) | User clicks "Create Alert" from business impact dashboard | Proactive business impact monitoring; Stakeholders notified on threshold breach; Escalation if not addressed | Alert noise if threshold too sensitive | Delete alert or adjust threshold | Yes - configure metric, threshold, notification recipients, and escalation policy | Log alert creation with trigger conditions and notification history | Alert status visible in feed; Impact charts show threshold line; Escalation path tracked | **P1** |
| **A7.10** | Export Impact Data | Export detailed business impact data (ROI, goals, savings, customer metrics) for external analysis or compliance reporting | User clicks "Export Data" from business impact dashboard | Comprehensive data export in CSV/Excel; Includes all metrics, timelines, and metadata | None | N/A | No - instant export | Log export request with scope, data range, and user | Exported file includes all selected metrics with full detail | **P2** |

---

**Tab 7: Business Impact PRD Complete**

---
