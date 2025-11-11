---

# Tab 6: Safety & Compliance

**Route**: `/dashboard/safety`
**Purpose**: Monitor safety guardrails, PII detection, toxicity filtering, compliance policy enforcement, risk assessment, and security incident response across agent fleet

## Personas & User Goals

| Persona | Primary Goals | Key Questions |
|---------|---------------|---------------|
| **Security Engineer** | Implement and monitor safety guardrails, prevent security incidents, maintain threat detection | Are guardrails blocking harmful outputs? Which agents have safety violations? What's our security posture? |
| **Compliance Officer** | Ensure regulatory compliance (GDPR, HIPAA, SOC 2), audit trail management, policy enforcement | Are we compliant with data regulations? Can we prove PII protection? What's our audit status? |
| **Risk Manager** | Assess and mitigate operational risks, track safety SLAs, manage incident response | What are our top safety risks? Are we meeting safety SLAs? How quickly do we respond to incidents? |
| **Privacy Officer** | PII detection and redaction, data retention policies, user consent management | Is PII being properly detected and redacted? Are we respecting user privacy preferences? |
| **CISO** | Strategic security investments, compliance governance, board reporting | What's our overall security risk score? Are we prepared for audits? What security trends should we address? |

## Multi-Level Structure

### Level 1: Fleet View
- Organization-wide safety score and compliance status
- Total guardrail violations by category (PII, toxicity, prompt injection, etc.)
- Compliance policy adherence rates (GDPR, HIPAA, internal policies)
- Safety SLA compliance (violation detection time, response time)
- Risk heatmap across departments and environments

### Level 2: Filtered Subset
- Department/team safety comparison
- Agent safety benchmarking (safest vs riskiest agents)
- Guardrail effectiveness by type (PII detection accuracy, toxicity precision/recall)
- Environment-specific compliance (production vs staging safety)
- Policy enforcement coverage gaps

### Level 3: Agent + Violation Detail
- Individual agent safety profile and risk score
- Request-level violation examples with context
- Guardrail rule performance (true/false positives)
- Remediation actions taken and outcomes
- Compliance audit trail for specific agent

## Filters

| Filter | Options | Default |
|--------|---------|---------|
| **Time Range** | 1h, 24h, 7d, 30d, 90d, 1y | 30d |
| **Environment** | All, Production, Staging, Development | All |
| **Department** | All, [List] | All |
| **Violation Type** | All, PII Detected, Toxicity, Prompt Injection, Jailbreak Attempt, Policy Violation, Data Leakage | All |
| **Severity** | All, Critical, High, Medium, Low | All |
| **Compliance Policy** | All, GDPR, HIPAA, SOC 2, CCPA, Internal Policies | All |
| **Remediation Status** | All, Auto-Blocked, Manual Review, Resolved, Open | All |

---

## Table 1: Existing Charts Adaptation

| Chart ID | Current Name | Required Modifications | New Metrics | Multi-Level Filtering | Interactivity | Caching Strategy | Priority |
|----------|--------------|----------------------|-------------|----------------------|---------------|------------------|----------|
| **6.1** | Safety Score KPI | Add violation breakdown by type; Severity distribution; Trend with policy compliance overlay; Risk score calculation | Safety score (0-100), violation counts by type, severity distribution, compliance % | Fleet: Overall safety; Subset: By dept/policy; Detail: By agent | Click violation type to drill into details; Hover for compliance status | 5min TTL for fleet; 2min for subset | **P0** |
| **6.2** | Guardrail Violations Over Time | Multi-line chart by violation type with severity overlay; Auto-detected anomaly spikes; Policy change annotations | Violation counts by type, severity, policy violations, anomaly markers | Fleet: All violations; Subset: By type/dept; Detail: By agent + violation type | Click spike to see affected agents; Filter by severity; Zoom time range | 3min TTL for aggregates | **P0** |
| **6.3** | PII Detection Accuracy | Add precision/recall metrics; False positive rate; Redaction coverage %; Entity type breakdown | Detection accuracy %, precision, recall, F1 score, false positive rate, entity types detected | Fleet: Overall accuracy; Subset: By entity type; Detail: By agent | Click entity type to see examples; Compare models | 10min TTL | **P0** |
| **6.4** | Top Risky Agents | Add risk score (ML-calculated), violation frequency, severity trends, last incident date; Quick action buttons | Risk score, violation count, severity trend, last violation, remediation status | Subset: Filter by risk tier; Detail: Agent safety profile | Click agent to drill down; Sort by risk score; Bulk remediation actions | 3min TTL | **P0** |
| **6.5** | Compliance Policy Status | Add policy adherence %; Coverage gaps; Audit readiness score; Next audit countdown | Adherence % by policy, coverage gaps, audit readiness score, time to next audit | Fleet: All policies; Subset: By policy type; Detail: By agent compliance | Click policy to see non-compliant agents; Export audit report | 15min TTL | **P0** |
| **6.6** | Safety SLA Tracker | Add detection SLA (time to detect violation), response SLA (time to remediate), breach indicators | Detection time P50/P95/P99, response time P50/P95/P99, SLA breach count | Fleet: Overall SLA; Subset: By violation type; Detail: By incident | Click SLA breach to see incidents; Trend over time | 5min TTL | **P0** |

---

## Table 2: New Charts Addition

| Chart ID | Chart Name | Description | Personas | Data Sources | D3 Visualization | Tech Implementation | Priority |
|----------|------------|-------------|----------|--------------|------------------|---------------------|----------|
| **6.7** | Risk Heatmap by Department | 2D heatmap showing risk score distribution across departments and violation types; Color intensity = risk severity; Identifies high-risk areas | CISO, Risk Manager, Security Engineer | `guardrail_violations` aggregated by dept and type; Risk scoring algorithm | Heatmap with department rows, violation type columns, color gradient | PostgreSQL dept grouping; ML risk scoring; Redis cache (10min TTL); D3 heatmap with drill-down | **P0** |
| **6.8** | PII Entity Detection Breakdown | Stacked bar chart showing detected PII entity types (SSN, email, phone, credit card, etc.) over time; Tracks redaction coverage | Privacy Officer, Compliance Officer | `guardrail_violations` (type='pii', entity_type); Redaction logs | Stacked area chart with entity type breakdown, redaction rate overlay | PostgreSQL PII entity parsing; Time-series aggregation; Redis cache (5min TTL); D3 stacked area | **P0** |
| **6.9** | Toxicity Score Distribution | Histogram showing distribution of toxicity scores across all agent outputs; Overlays threshold line and percentile markers | Security Engineer, Risk Manager | `guardrail_violations` (toxicity_score); All traces analyzed | Histogram with threshold markers, percentile annotations | PostgreSQL histogram bucketing; Toxicity model scores; Redis cache (10min TTL); D3 histogram | **P0** |
| **6.10** | Prompt Injection Detection Timeline | Time-series chart showing prompt injection and jailbreak attempts over time; Annotates attack patterns and sources | Security Engineer, CISO | `guardrail_violations` (type='prompt_injection' or 'jailbreak'); Attack pattern classification | Line chart with attack pattern markers, source IP geo-mapping | TimescaleDB time_bucket(); ML attack classification; Redis cache (5min TTL); D3 line with annotations | **P0** |
| **6.11** | Compliance Audit Dashboard | Multi-panel dashboard showing compliance status for GDPR, HIPAA, SOC 2, CCPA; Traffic light indicators; Evidence collection status | Compliance Officer, Legal Team | `compliance_audits` table; Policy adherence metrics; Evidence vault | Grid layout with policy cards, status indicators, evidence links | PostgreSQL compliance joins; Document vault integration; Redis cache (15min TTL); React grid layout | **P0** |
| **6.12** | Guardrail Rule Performance | Table showing each guardrail rule with performance metrics (precision, recall, false positive rate, latency impact); Sortable and filterable | Security Engineer, ML Engineer | `guardrail_rules` joined with violation results; Performance metrics | Enhanced data table with inline performance charts, sort/filter capabilities | PostgreSQL rule performance aggregation; Precision/recall calculation; Redis cache (10min TTL); React Table | **P0** |
| **6.13** | Safety Incident Response Timeline | Gantt chart showing incident lifecycle from detection ’ investigation ’ remediation ’ closure; Tracks MTTR | Risk Manager, Security Engineer | `safety_incidents` table (state machine tracking); Response timestamps | Gantt chart with incident timelines, SLA markers | PostgreSQL incident workflow joins; MTTR calculation; Redis cache (3min TTL); D3 Gantt | **P1** |
| **6.14** | Data Leakage Detection Map | Network graph showing potential data leakage paths (agent ’ external API ’ third party); Risk-weighted edges | Security Engineer, CISO | `traces` (external API calls); Data flow analysis; Risk classification | Force-directed graph with risk-colored edges, third-party node highlighting | PostgreSQL data flow joins; ML risk weighting; Redis cache (15min TTL); D3 force graph | **P1** |
| **6.15** | Policy Enforcement Coverage | Sankey diagram showing policy enforcement flow: Total Requests ’ Policy Applied ’ Violations Detected ’ Actions Taken | Compliance Officer, Risk Manager | `traces` + `guardrail_violations` + remediation actions | Sankey diagram with flow volumes, drop-off highlighting | PostgreSQL flow tracking; Conversion rate calculation; Redis cache (10min TTL); D3 Sankey | **P1** |
| **6.16** | User Consent Management | Pie chart and table showing user consent status distribution (opted-in, opted-out, pending); Tracks consent preferences by region | Privacy Officer, Legal Team | `user_consent` table; Regional regulations; Consent preferences | Pie chart with regional breakdown, consent preference table | PostgreSQL consent tracking; GDPR/CCPA compliance logic; Redis cache (30min TTL); D3 pie + React Table | **P1** |
| **6.17** | False Positive Trend Analysis | Line chart tracking false positive rate over time for each guardrail type; Shows improvement from model tuning | Security Engineer, ML Engineer | `guardrail_violations` (marked as false positive); Model version history | Multi-line chart with model version annotations, improvement metrics | TimescaleDB time-series; False positive tracking; Redis cache (10min TTL); D3 multi-line | **P2** |
| **6.18** | Security Posture Score Card | Score card with weighted metrics across multiple dimensions (PII protection, toxicity filtering, attack prevention, compliance, incident response) | CISO, Risk Manager | Aggregated security metrics; Weighted scoring model | Radar chart with dimension scoring, historical trend line | PostgreSQL metric aggregation; Scoring algorithm; Redis cache (15min TTL); D3 radar chart | **P2** |

---

## Table 3: Actionable Interventions

| Action ID | Action Name | Description | Trigger Context | Expected Outcome | Side Effects | Rollback Strategy | User Confirmation | Audit Trail | Observability | Priority |
|-----------|-------------|-------------|-----------------|------------------|--------------|-------------------|-------------------|-------------|---------------|----------|
| **A6.1** | Enable Guardrail Rule | Activate specific guardrail rule (PII detection, toxicity filter, prompt injection blocker) for selected agents or globally | User clicks "Enable Rule" from guardrail settings or safety dashboard | Guardrail active; Violations detected and logged; Auto-blocking or alerting based on config | May block legitimate requests if rule too strict (false positives); Slight latency increase | Disable rule; Adjust sensitivity threshold | Yes - configure sensitivity, action (block/alert), and scope | Log rule activation with full config and affected agents | Violation detections appear in dashboard; Blocked requests logged | **P0** |
| **A6.2** | Create Safety Incident | Manually create safety incident for detected violation or suspicious activity; Initiates investigation and remediation workflow | User clicks "Create Incident" from violation detail or risk alert | Incident tracking active; Stakeholders notified; Investigation workflow initiated; MTTR timer starts | Team receives incident notifications; May trigger escalation procedures | Close incident if false alarm | Yes - confirm severity, assign owner, set priority | Log incident creation with details, assignments, and timeline | Incident visible in incident tracker; Status updates tracked; SLA timer visible | **P0** |
| **A6.3** | Configure PII Redaction | Set up PII redaction rules for specific entity types (SSN, email, phone, etc.) with masking strategy (full/partial redaction) | User clicks "Configure Redaction" from PII detection settings | PII automatically redacted in outputs; Compliance with privacy regulations; Audit trail maintained | Redacted outputs may be less useful; User experience impact; Storage of original + redacted versions | Disable redaction; Adjust redaction strategy | Yes - select entity types, redaction strategy, and scope | Log redaction config with before/after examples | Redacted outputs visible in trace detail; Redaction stats in dashboard | **P0** |
| **A6.4** | Set Safety Alert | Configure alert for safety threshold (e.g., >10 PII detections/hour, toxicity score >0.8, 5+ prompt injection attempts) | User clicks "Create Alert" from safety dashboard or guardrail chart | Proactive safety monitoring; Immediate notification on threshold breach | Alert fatigue if threshold too sensitive | Delete alert rule or adjust sensitivity | Yes - configure threshold, notification channel, escalation policy | Log alert creation with trigger conditions and recipients | Alert status in feed; Safety charts show threshold line; Escalation path visible | **P0** |
| **A6.5** | Trigger Safety Audit | Initiate comprehensive safety audit for compliance certification (GDPR, HIPAA, SOC 2); Collects evidence and generates report | User clicks "Start Audit" from compliance dashboard or scheduled audit workflow | Audit report generated; Evidence package collected; Compliance gaps identified; Certification readiness assessed | Resource-intensive process; May reveal compliance gaps requiring remediation | N/A (audit is read-only assessment) | Yes - select audit type, scope, and timeline | Log audit initiation, progress, findings, and report generation | Audit progress tracked; Findings dashboard; Evidence vault populated; Report exportable | **P0** |
| **A6.6** | Whitelist Entity/Pattern | Add known-safe entity or pattern to whitelist to reduce false positives (e.g., company email domain, test phone numbers) | User clicks "Whitelist" from false positive review or guardrail settings | Reduced false positives; Improved guardrail precision; Better user experience | Over-whitelisting may reduce security; Regular review needed | Remove from whitelist | Yes - review entity/pattern and confirm safety | Log whitelist addition with entity, reason, and approver | False positive rate reduction visible in metrics; Whitelist entries viewable in settings | **P1** |
| **A6.7** | Escalate to Human Review | Escalate high-risk or ambiguous violation to human security team for manual investigation | User clicks "Escalate" from violation detail or auto-escalation based on risk score | Expert human review; Better decision on true vs false positive; Ground truth for model improvement | Human review costs; Review queue delays | De-escalate if resolved automatically | No - instant escalation to queue | Log escalation with violation details, assigned reviewer, and outcome | Review queue visible in dashboard; Resolution time tracked; Feedback loop for model | **P1** |
| **A6.8** | Apply Policy Template | Apply pre-built compliance policy template (GDPR, HIPAA, SOC 2) to selected agents; Configures all relevant guardrails and settings | User clicks "Apply Template" from compliance settings or onboarding wizard | Rapid compliance setup; Standardized policy enforcement; Reduced configuration errors | May override existing custom settings; Template may not fit all use cases | Revert to previous configuration | Yes - review template settings before apply | Log template application with before/after config diff | Policy compliance immediately tracked; Template coverage visible in dashboard | **P1** |
| **A6.9** | Schedule Penetration Test | Schedule security penetration test for specific agents to identify vulnerabilities (prompt injection, jailbreak, data extraction) | User clicks "Schedule Pentest" from security posture or agent detail | Security vulnerabilities identified; Remediation recommendations; Risk assessment updated | Resource consumption during test; May trigger false alarms | Cancel scheduled test | Yes - confirm test scope, intensity, and timing | Log test schedule, execution, findings, and remediation actions | Test results visible in security dashboard; Vulnerability severity scored; Fix priority assigned | **P1** |
| **A6.10** | Enable Consent Tracking | Activate user consent tracking for privacy compliance; Captures opt-in/opt-out preferences and enforces data handling policies | User clicks "Enable Consent" from privacy settings | GDPR/CCPA compliance; User privacy preferences respected; Audit trail for consent | Consent UI must be added to user-facing apps; Data handling logic required | Disable consent tracking | Yes - configure consent options and data retention policies | Log consent tracking activation and all user consent events | Consent status visible in user profiles; Opt-out requests honored; Analytics dashboard shows consent distribution | **P2** |

---

**Tab 6: Safety & Compliance PRD Complete**

---
