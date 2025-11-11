---

# Tab 8: Incidents & Reliability

**Route**: `/dashboard/incidents`
**Purpose**: Incident management, SLO tracking, MTTR optimization, postmortem analysis, reliability engineering, and on-call effectiveness monitoring

## Personas & User Goals

| Persona | Primary Goals | Key Questions |
|---------|---------------|---------------|
| **SRE / Incident Commander** | Rapid incident detection, response coordination, MTTR reduction, efficient triage | What's broken? Who's impacted? How severe? How do we fix it quickly? |
| **Engineering Manager** | Reliability accountability, incident trends, team response effectiveness, learning from failures | Are incidents decreasing? Is MTTR improving? Are we learning from incidents? |
| **DevOps Engineer** | System reliability, runbook effectiveness, automation opportunities, proactive monitoring | Which runbooks work? Can we auto-remediate? What patterns predict incidents? |
| **VP Engineering** | Organizational reliability, SLO compliance, service excellence, strategic reliability investments | Are we meeting reliability commitments? Trending better or worse? Where should we invest? |
| **On-Call Engineer** | Clear incident context, effective runbooks, escalation paths, minimal toil | Do I have the information I need? What's the fastest path to resolution? |

## Multi-Level Structure

### Level 1: Fleet View
- Active incidents dashboard with severity prioritization and real-time status
- SLO compliance across all agents and services
- MTTR trends by department, severity, and incident category
- Incident patterns, frequency analysis, and root cause distribution
- Reliability score and error budget consumption

### Level 2: Filtered Subset
- Department incident analysis and comparison
- Agent-specific incident history and reliability profile
- Environment reliability comparison (prod vs staging)
- Incident commander effectiveness metrics
- Runbook success rates by category

### Level 3: Incident Detail
- Full incident timeline with detection, response, and resolution steps
- Postmortem documentation with action items
- Related incidents and pattern correlation
- Communication log and stakeholder updates
- Remediation actions and effectiveness

## Filters

| Filter | Options | Default |
|--------|---------|---------|
| **Time Range** | 1h, 24h, 7d, 30d, 90d, 1y | 30d |
| **Environment** | All, Production, Staging, Development | Production |
| **Department** | All, [List] | All |
| **Severity** | All, Critical (SEV1), High (SEV2), Medium (SEV3), Low (SEV4) | All |
| **Status** | All, Active, Investigating, Mitigating, Resolved, Postmortem Pending | Active + Investigating |
| **Incident Category** | All, Latency Spike, High Error Rate, Service Down, Data Issue, Security, [Custom] | All |
| **SLO Status** | All, Meeting SLO, At Risk, Breaching SLO | All |

---

## Table 1: Existing Charts Adaptation

| Chart ID | Current Name | Required Modifications | New Metrics | Multi-Level Filtering | Interactivity | Caching Strategy | Priority |
|----------|--------------|----------------------|-------------|----------------------|---------------|------------------|----------|
| **8.1** | Error Rate (from Home/Performance) | Transform into incident view with severity overlay; Add incident state tracking; Link errors to incidents; Show MTTR by severity | Incident count by severity; Active incidents; MTTR P50/P95; Error budget burn rate | Fleet: All incidents; Subset: By dept/severity; Detail: By incident | Click error spike to create incident; View related errors; Link to runbooks | 1min TTL for active; 5min for historical | **P0** |
| **8.2** | Alert Feed (from Home) | Enhance with incident correlation; Show alert-to-incident conversion; Track alert accuracy (true vs false positives) | Alert count, incident conversion rate, false positive rate, time to incident creation | Fleet: All alerts; Subset: By alert type; Detail: By alert + linked incident | Click alert to view details or create incident; Mark false positive | 2min TTL | **P0** |
| **8.3** | Agent Uptime (from Fleet) | Add SLO compliance overlay; Show error budget consumption; Track availability by agent and environment | Uptime %, SLO target, error budget remaining, availability by environment | Fleet: Overall uptime; Subset: By agent/env; Detail: Agent SLO details | Click agent to see incident history; View SLO config | 5min TTL | **P0** |
| **8.4** | Latency Trends (from Performance) | Correlate latency spikes with incidents; Annotate incident events; Show impact duration | Latency P95/P99, incident markers, impact duration, recovery time | Fleet: Overall latency; Subset: By agent; Detail: Incident impact view | Click latency spike to see related incident; Zoom to incident timeframe | 3min TTL | **P0** |

---

## Table 2: New Charts Addition

| Chart ID | Chart Name | Description | Personas | Data Sources | D3 Visualization | Tech Implementation | Priority |
|----------|------------|-------------|----------|--------------|------------------|---------------------|----------|
| **8.5** | Active Incidents Dashboard | Real-time status board showing all active incidents with severity, status, assigned owner, elapsed time, and quick actions; Auto-refreshes | SRE, Incident Commander, On-Call Engineer | `incidents` table (status='active' or 'investigating'); Real-time updates | Card-based dashboard with color-coded severity, status badges, elapsed time counters | PostgreSQL active incident queries; WebSocket for real-time updates; Redis cache (30sec TTL); React cards with auto-refresh | **P0** |
| **8.6** | SLO Compliance Matrix | Grid showing SLO compliance status for all agents/services; Rows = agents, columns = SLO types (availability, latency, error rate); Color-coded by compliance level | SRE, VP Engineering, Engineering Manager | `agents` + SLO config; `traces` for actual performance; Error budget calculations | Heatmap grid with compliance percentages, color gradient (green=meeting, yellow=at-risk, red=breaching) | PostgreSQL SLO compliance queries; Error budget math; Redis cache (5min TTL); D3 heatmap with drill-down | **P0** |
| **8.7** | MTTR Trends | Line chart showing Mean Time To Resolve trends over time; Segmented by department, severity, and incident category; Includes P50/P95 bands | Engineering Manager, VP Engineering | `incidents` (resolution timestamps); MTTR calculations by segment | Multi-line chart with P50/P95 confidence bands, target line overlay | TimescaleDB time_bucket() for MTTR aggregation; Percentile calculations; Redis cache (10min TTL); D3 multi-line | **P0** |
| **8.8** | Incident Timeline (Gantt) | Gantt chart showing incident lifecycle timeline: detection → acknowledged → investigating → mitigating → resolved; Multiple incidents displayed with severity color-coding | SRE, Incident Commander, Engineering Manager | `incidents` table (state transitions with timestamps); Incident workflow events | Gantt chart with incident bars, state transitions, severity colors, current time marker | PostgreSQL incident timeline queries; State machine tracking; Redis cache (2min TTL); D3 Gantt | **P0** |
| **8.9** | Root Cause Pareto Analysis | Pareto chart showing incident distribution by root cause category; 80/20 analysis to identify top causes; Cumulative percentage overlay | Engineering Manager, VP Engineering, DevOps Engineer | `incidents` (root_cause field); Postmortem analysis results | Pareto chart with bars (frequency) and line (cumulative %), 80% threshold marker | PostgreSQL root cause grouping; Pareto calculation; Redis cache (15min TTL); D3 combo chart | **P0** |
| **8.10** | Runbook Effectiveness Tracker | Table showing runbooks with success rate, average resolution time, usage frequency, last updated date; Identifies ineffective or outdated runbooks | DevOps Engineer, SRE | `runbook_executions` table; Incident resolution correlation; Runbook metadata | Enhanced data table with success rate bars, sparkline trends, quick edit actions | PostgreSQL runbook effectiveness aggregation; Success rate calculation; Redis cache (10min TTL); React Table | **P0** |
| **8.11** | Error Budget Consumption | Stacked area chart showing error budget consumption over time by service/agent; Alerts when budget at risk; Projects remaining budget | SRE, VP Engineering | SLO config (error budget allocation); `traces` (actual errors); Burn rate calculations | Stacked area chart with budget limit line, projection overlay, alert thresholds | TimescaleDB time-series aggregation; Error budget math; ML projection; Redis cache (5min TTL); D3 stacked area | **P1** |
| **8.12** | Incident Frequency Heatmap | Calendar heatmap showing incident frequency by day/hour; Identifies patterns (e.g., incidents spike on deployment days, certain hours) | Engineering Manager, DevOps Engineer | `incidents` (timestamp); Deployment events; Time-based aggregation | Calendar heatmap with day/hour grid, color intensity by frequency | PostgreSQL temporal aggregation; Pattern detection; Redis cache (1hr TTL); D3 calendar heatmap | **P1** |
| **8.13** | On-Call Response Metrics | Metrics for on-call effectiveness: acknowledgment time, escalation rate, resolution quality, burnout indicators | Engineering Manager, VP Engineering | `incidents` (on-call assignments); Response timestamps; Escalation events | Dashboard with KPI cards, response time distribution, escalation funnel | PostgreSQL on-call metrics aggregation; Response time percentiles; Redis cache (10min TTL); React dashboard | **P1** |
| **8.14** | Incident Communication Log | Timeline view showing all incident communications: status updates, stakeholder notifications, internal notes, external updates | Incident Commander, Engineering Manager | `incident_communications` table; Status update events; Notification logs | Vertical timeline with message cards, timestamp markers, recipient badges | PostgreSQL communication log queries; Timeline aggregation; Redis cache (1min TTL); React timeline | **P1** |
| **8.15** | Postmortem Action Items Tracker | Table tracking action items from postmortems: description, owner, due date, status, completion; Links back to originating incident | Engineering Manager, VP Engineering | `postmortem_action_items` table; Completion tracking; Incident linkage | Enhanced table with status badges, overdue highlighting, completion trends | PostgreSQL action item queries; Status tracking; Redis cache (5min TTL); React Table with filters | **P1** |
| **8.16** | Reliability Score Trend | Composite reliability score (0-100) based on SLO compliance, MTTR, incident frequency, error budget; Shows trend over time with contributing factors | VP Engineering, CISO | Multiple reliability metrics; Weighted scoring algorithm | Line chart with score trend, factor breakdown, target line | PostgreSQL metric aggregation; Weighted scoring model; Redis cache (15min TTL); D3 line with breakdown | **P2** |
| **8.17** | Similar Incidents Finder | ML-powered similar incident detection; Shows related incidents based on symptoms, root cause, affected agents | SRE, On-Call Engineer | `incidents` table; ML similarity model; Text embeddings for incident descriptions | Card grid with similarity scores, quick comparison view | Gemini ML for similarity detection; Vector embeddings; Redis cache (5min TTL); React cards | **P2** |

---

## Table 3: Actionable Interventions

| Action ID | Action Name | Description | Trigger Context | Expected Outcome | Side Effects | Rollback Strategy | User Confirmation | Audit Trail | Observability | Priority |
|-----------|-------------|-------------|-----------------|------------------|--------------|-------------------|-------------------|-------------|---------------|----------|
| **A8.1** | Create Incident | Create new incident from alert, manual trigger, or automated detection; Set severity, assign owner, define impact scope | User clicks "Create Incident" from alert, performance anomaly, or manual creation button | Incident tracked in system; Stakeholders notified; Timer started for MTTR; Incident workflow initiated | Team receives incident notifications; On-call engineer paged for high severity | Close incident if created in error | Yes - confirm severity, impact scope, initial description | Log incident creation with all metadata, timeline start | Incident appears in active incidents dashboard; Status tracked in real-time | **P0** |
| **A8.2** | Assign Incident Commander | Assign incident commander (IC) responsible for coordinating response; IC gets elevated permissions and incident context | User clicks "Assign IC" from incident detail or auto-assigned based on on-call rotation | Incident commander assigned; IC notified with full context; Coordination responsibility clear | IC receives notification and incident ownership; Other team members notified of IC | Reassign to different IC if needed | Auto for on-call; Manual confirmation for override | Log IC assignment with timestamp and acceptance | IC visible in incident card; Communication directed to IC | **P0** |
| **A8.3** | Execute Runbook | Launch guided runbook execution for incident remediation; Step-by-step instructions with checkboxes and validation | User clicks "Execute Runbook" from incident detail; Selects applicable runbook | Guided remediation process started; Steps tracked; Completion recorded; Runbook effectiveness measured | Runbook execution time tracked; Success/failure recorded for effectiveness analysis | Abort runbook execution if ineffective | No - instant launch with progress tracking | Log runbook execution start, step completion, outcome | Runbook progress visible in incident timeline; Completion status updated | **P0** |
| **A8.4** | Update Incident Status | Update incident status (Acknowledged → Investigating → Mitigating → Resolved) with notes and timestamp | User clicks status update button or status dropdown in incident detail | Incident status updated; State transition logged; Stakeholders notified of progress; MTTR tracking updated | Status change notifications sent; Incident timeline updated | Revert to previous status if updated incorrectly | Yes - confirm status change and add status note | Log all status transitions with timestamps, notes, and user | Status updates visible in incident timeline and active dashboard | **P0** |
| **A8.5** | Generate Postmortem | Create structured postmortem document from incident; Includes timeline, root cause, impact, action items, and lessons learned | User clicks "Generate Postmortem" after incident resolved; AI assists with draft generation | Postmortem document created with structured template; Action items extracted; Review workflow initiated | Postmortem review assigned to stakeholders; Action items tracked separately | Delete draft postmortem | Yes - review and finalize AI-generated draft | Log postmortem creation, edits, approval, and sharing | Postmortem linked to incident; Action items tracked in separate dashboard | **P0** |
| **A8.6** | Configure SLO Tracking | Define SLO targets for agent/service (availability %, latency threshold, error rate); Set error budget and alerting thresholds | User clicks "Configure SLO" from reliability settings or agent detail | SLO tracking active; Error budget calculated; Alerts configured for SLO breaches; Compliance visible in dashboards | SLO breach alerts may trigger if current performance below target | Delete SLO config or adjust targets | Yes - define SLO targets, error budget, and alert thresholds | Log SLO configuration with targets, budget, and alert rules | SLO compliance visible in matrix and agent details; Error budget tracked | **P0** |
| **A8.7** | Enable Auto-Remediation Playbook | Activate automated remediation playbook for specific incident pattern; System automatically executes remediation steps when pattern detected | User clicks "Enable Auto-Remediation" from runbook settings after validating effectiveness | Automated incident response for known patterns; Reduced MTTR; Decreased manual toil | Auto-remediation failures may cause issues if playbook incorrect; Monitoring critical | Disable auto-remediation playbook | Yes - confirm playbook safety and approval from SRE leadership | Log auto-remediation enablement, executions, and outcomes | Auto-remediation executions logged in incident timeline; Success rate tracked | **P0** |
| **A8.8** | Escalate Incident | Escalate incident to higher severity or broader team; Triggers additional notifications and resources | User clicks "Escalate" from incident detail when severity increases or resolution stalled | Escalation executed; Additional stakeholders notified; Resources mobilized; Incident priority increased | Broader team notified; May trigger executive escalation for critical incidents | De-escalate if situation improves | Yes - confirm escalation reason and new severity/scope | Log escalation with reason, new severity, and stakeholder updates | Escalation visible in incident timeline; Increased visibility in dashboards | **P0** |
| **A8.9** | Add Incident Note | Add timestamped note to incident for context, updates, or communication; Supports markdown formatting | User adds note from incident detail; Can be internal or stakeholder-visible | Note added to incident timeline; Stakeholders notified if external note; Context preserved | None (informational only) | Edit or delete note | No - instant note addition | Log all notes with timestamp, author, and visibility | Notes appear in incident communication log and timeline | **P1** |
| **A8.10** | Link Related Incidents | Manually or automatically link related incidents to identify patterns and recurring issues | User clicks "Link Incidents" from incident detail or ML auto-suggests similar incidents | Incidents linked; Pattern visibility increased; Root cause correlation improved | None (informational linking) | Unlink incidents if not related | Yes for manual; Auto for ML-suggested with review option | Log incident linkages with similarity score and reasoning | Related incidents visible in incident detail; Patterns highlighted | **P1** |
| **A8.11** | Schedule Postmortem Review | Schedule postmortem review meeting with stakeholders; Creates calendar event and shares postmortem document | User clicks "Schedule Review" from postmortem document | Review meeting scheduled; Calendar invites sent; Postmortem shared with attendees | Stakeholders receive calendar invites; Time commitment required | Cancel meeting if no longer needed | Yes - select attendees, date/time, and duration | Log meeting schedule and attendance | Meeting details visible in postmortem; Attendance tracked | **P1** |
| **A8.12** | Set Reliability Goal | Define reliability improvement goal (e.g., reduce MTTR by 30%, achieve 99.9% SLO compliance) with timeline | User clicks "Set Goal" from reliability dashboard | Goal tracked; Progress automatically measured; Alerts when off-track; Visibility in leadership dashboards | Team accountability for goal; Progress updates to stakeholders | Delete or modify goal | Yes - define goal target, timeline, and success metrics | Log goal creation and progress milestones | Goal progress visible in reliability dashboard; Alerts when off-track | **P1** |
| **A8.13** | Export Incident Report | Generate incident report for selected time range with metrics, trends, and detailed incident list; Export as PDF/CSV | User clicks "Export Report" from incidents dashboard | Comprehensive incident report generated; Includes charts, metrics, and incident details | None | N/A | No - instant export | Log report generation with scope and timestamp | Report includes all incident data with visualizations | **P2** |

---

**Tab 8: Incidents & Reliability PRD Complete**

---
