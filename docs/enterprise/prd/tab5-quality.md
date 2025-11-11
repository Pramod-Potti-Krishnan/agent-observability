---

# Tab 5: Quality

**Route**: `/dashboard/quality`  
**Purpose**: Monitor LLM output quality, evaluation accuracy, drift detection, and quality improvement initiatives

## Personas & User Goals

| Persona | Primary Goals | Key Questions |
|---------|---------------|---------------|
| **ML Engineer** | Prompt optimization, model fine-tuning, evaluation accuracy | Which prompts are underperforming? Is quality drifting? |
| **Quality Analyst** | Output quality assurance, evaluation rubric management, issue triage | What % of outputs meet quality bar? Which agents need attention? |
| **Product Manager** | User satisfaction, feature quality, business impact of quality issues | Is quality improving? Are users satisfied with outputs? |
| **Engineering Manager** | Team quality accountability, technical excellence | Which teams produce highest quality outputs? What's quality trend? |
| **Director AI/ML** | Quality standards governance, model selection, strategic quality initiatives | Are we maintaining quality consistency? Which models perform best? |

## Multi-Level Structure

### Level 1: Fleet View
- Organization-wide quality score aggregation
- Quality distribution (Excellent/Good/Fair/Poor/Failing)
- Quality by intent category (customer support quality vs code gen quality)
- Quality drift detection across fleet

### Level 2: Filtered Subset
- Department quality comparison
- Agent quality benchmarking
- Version quality gates (v2.0 quality vs v1.9)
- Evaluation rubric performance comparison

### Level 3: Agent + Evaluation Detail
- Individual agent quality breakdown
- Request-level evaluations with rubric details
- Quality failure analysis with examples
- Improvement recommendations per agent

## Filters

| Filter | Options | Default |
|--------|---------|---------|
| **Time Range** | 1h, 24h, 7d, 30d, 90d | 30d |
| **Department** | All, [List] | All |
| **Quality Category** | All, Excellent (9-10), Good (7-8), Fair (5-6), Poor (3-4), Failing (0-2) | All |
| **Evaluation Method** | All, LLM-as-Judge, Human Review, Rule-Based, Custom | All |
| **Intent Category** | All, [List] | All |

---

## Table 1: Existing Charts Adaptation

| Chart ID | Current Name | Required Modifications | New Metrics | Multi-Level Filtering | Interactivity | Caching Strategy | Priority |
|----------|--------------|----------------------|-------------|----------------------|---------------|------------------|----------|
| **5.1** | Quality Score KPI | Add quality distribution breakdown (Excellent/Good/Fair/Poor/Failing); Department comparison with trend arrows; Drift detection indicator | Quality distribution %; Dept avg quality; Drift severity score | Fleet: Overall quality score; Subset: By dept/team; Detail: By agent | Click distribution segment to filter agents; Hover for drift details | 10min TTL for fleet; 5min for subset | **P0** |
| **5.2** | Evaluation Distribution | Convert pie to stacked bar by department; Add quality category counts; Evaluation method overlay (LLM vs Human vs Rule-based) | Evaluation counts by method; Quality category distribution; Method accuracy comparison | Fleet: All evaluations; Subset: By dept/method; Detail: By agent + method | Click method to filter; Drill down to agent level; Export evaluation data | 10min TTL | **P0** |
| **5.3** | Quality Over Time | Multi-line chart by department/agent with confidence bands; Drift alert markers; Version release overlay; Moving average smoothing | 7d/30d moving avg quality; Statistical drift alerts; Version correlation | Fleet: Overall trend; Subset: By dept/team/version; Detail: Single agent timeline | Click drift marker to see affected agents; Zoom time range; Compare versions | 5min TTL for aggregates | **P0** |
| **5.4** | Top Failing Agents | Add quality score, evaluation count, failure rate %; Improvement potential score (ML-predicted); Quick action buttons (Review, Optimize) | Quality score, eval count, failure rate, improvement potential, last evaluated | Subset: Filter by quality tier; Detail: Agent quality breakdown | Click agent to drill down; Sort by any column; Bulk select for optimization | 3min TTL | **P0** |
| **5.5** | Evaluation Success Rate | Add success rate by evaluation method; Comparison across time periods; Alert threshold line | Success rate % by method; Period-over-period delta; Threshold compliance | Fleet: Overall success rate; Subset: By method/dept; Detail: By agent | Click method to see agent breakdown; Filter by time period | 5min TTL | **P0** |

---

## Table 2: New Charts Addition

| Chart ID | Chart Name | Description | Personas | Data Sources | D3 Visualization | Tech Implementation | Priority |
|----------|------------|-------------|----------|--------------|------------------|---------------------|----------|
| **5.6** | Quality vs Cost Tradeoff Matrix | Scatter plot with X-axis = cost per request, Y-axis = quality score, bubble size = request volume; Pareto frontier line shows optimal agents; Identifies agents with poor quality-cost ratio | Product Manager, Director AI/ML, ML Engineer | `traces` (cost_usd, quality metrics); `evaluations` table; Aggregated by agent | Scatter plot with bubble sizing, Pareto frontier overlay, quadrant highlighting | PostgreSQL joins for cost+quality; Pareto calculation; Redis cache (10min TTL); D3 scatter with zoom | **P0** |
| **5.7** | Evaluation Rubric Performance | Heatmap showing individual rubric criterion scores across agents; Rows = agents, columns = rubric criteria (correctness, coherence, safety, etc.); Color intensity = score | Quality Analyst, ML Engineer | `evaluations` table (rubric_scores JSON); `agents` metadata | Heatmap with color gradient (red=low, green=high), sortable rows/columns | PostgreSQL JSON parsing; Aggregation by agent+criterion; Redis cache (5min TTL); D3 heatmap with tooltips | **P0** |
| **5.8** | Quality Drift Detection Timeline | Time-series line chart with statistical control limits (mean ± 2σ); Automatic drift detection using change point analysis; Annotates significant drift events | ML Engineer, Engineering Manager | `evaluations` aggregated by time bucket; ML drift detection results | Line chart with confidence bands, drift alert markers, annotation tooltips | TimescaleDB time_bucket(); Gemini ML for drift detection; Redis cache (5min TTL); D3 line with anomaly markers | **P0** |
| **5.9** | Intent Quality Comparison | Grouped bar chart comparing average quality scores across different intent categories (customer support, code gen, summarization, etc.); Shows category-specific quality standards | Product Manager, Quality Analyst | `traces` (intent metadata); `evaluations` joined on trace_id | Grouped bar chart with category grouping, target line overlay | PostgreSQL intent grouping; Average quality calculation; Redis cache (10min TTL); D3 grouped bars | **P1** |
| **5.10** | Prompt Version Quality Comparison | Multi-line chart showing quality score trends for different prompt versions over time; Annotated with version release dates; Identifies quality regressions | ML Engineer, Backend Engineer | `traces` joined with `agents` (prompt_version); `evaluations` for quality scores | Multi-line chart with version annotations, regression markers | TimescaleDB time-series joins; Version metadata; Redis cache (10min TTL); D3 multi-line with annotations | **P1** |
| **5.11** | Failed Evaluation Examples Table | Sortable, filterable table showing recent failed evaluations with input/output examples, rubric scores, failure reasons, and AI-generated improvement suggestions | Quality Analyst, ML Engineer, Backend Engineer | `evaluations` (status='failed'); `traces` for context; Gemini for improvement suggestions | Enhanced data table with inline expand for full examples, sortable columns | PostgreSQL failed eval queries; Gemini API for suggestions; Redis cache (2min TTL); React Table with virtual scrolling | **P1** |
| **5.12** | Quality Distribution Histogram | Histogram showing distribution of quality scores across all evaluations; Overlays with target distribution and statistical markers (mean, median, percentiles) | Director AI/ML, Quality Analyst | `evaluations` (quality_score bucketed) | Histogram with distribution curve overlay, percentile markers | PostgreSQL histogram bucketing; Statistical calculations; Redis cache (10min TTL); D3 histogram with overlays | **P1** |
| **5.13** | Model Quality Benchmarking | Grouped bar chart comparing quality metrics across different LLM models (GPT-4, Claude, Gemini, etc.) used by agents; Shows model-specific strengths | ML Engineer, Director AI/ML | `traces` (model metadata); `evaluations` aggregated by model | Grouped bar chart with model comparison, radar chart alternative view | PostgreSQL model grouping; Multi-metric aggregation; Redis cache (15min TTL); D3 grouped bars + radar chart | **P1** |
| **5.14** | Evaluation Method Confidence | Box plot showing confidence score distribution for each evaluation method; Identifies methods needing calibration | Quality Analyst, ML Engineer | `evaluations` (confidence_score by method) | Box plot with quartiles, outlier highlighting | PostgreSQL percentile calculations; Method grouping; Redis cache (10min TTL); D3 box plot | **P2** |
| **5.15** | Quality Improvement Funnel | Funnel chart showing quality improvement pipeline: Low Quality Detected → Review Initiated → Optimization Applied → Quality Improved; Tracks conversion rates | Product Manager, Engineering Manager | `evaluations` + improvement tracking events; Workflow state machine | Funnel chart with conversion rates, drop-off highlighting | PostgreSQL workflow tracking; Conversion rate calculation; Redis cache (5min TTL); D3 funnel chart | **P2** |

---

## Table 3: Actionable Interventions

| Action ID | Action Name | Description | Trigger Context | Expected Outcome | Side Effects | Rollback Strategy | User Confirmation | Audit Trail | Observability | Priority |
|-----------|-------------|-------------|-----------------|------------------|--------------|-------------------|-------------------|-------------|---------------|----------|
| **A5.1** | Configure Quality Rubric | Define or update evaluation rubric with custom criteria, scoring weights, and thresholds for specific agent or intent category | User clicks "Configure Rubric" from quality settings or agent detail | Custom quality measurement aligned with business goals; Tailored evaluation criteria | Existing evaluations may be re-scored if retroactive flag set; Historical comparisons affected | Revert to previous rubric version; Keep version history | Yes - review rubric criteria and weights before applying | Log rubric changes with before/after JSON; Version tracking | Quality scores recalculated; Dashboard reflects new rubric immediately | **P0** |
| **A5.2** | Set Quality Alert | Configure alert rule for quality threshold (e.g., quality score < 7.0, drift detected, failure rate > 5%) with notification channels | User clicks "Create Alert" from quality dashboard or drift detection chart | Proactive quality monitoring; Immediate notification on quality degradation | Alert noise if threshold too sensitive; Team receives notifications | Delete alert rule or adjust sensitivity | Yes - confirm threshold, sensitivity, and notification channel | Log alert creation with full config and trigger conditions | Alert status visible in feed; Quality charts show threshold line | **P0** |
| **A5.3** | Trigger Prompt Optimization | Initiate AI-powered prompt engineering workflow for low-quality agent; Gemini analyzes failures and suggests prompt improvements | User clicks "Optimize Prompt" from failing agent detail or improvement recommendations | Quality improvement of 15-30%; Reduced failure rate; Better output consistency | Prompt changes may alter agent behavior; A/B testing recommended before full rollout | Revert to previous prompt version; Version control maintained | Yes - review suggested changes and approve before deployment | Log optimization request, suggestions, and applied changes | Quality metrics tracked before/after; A/B test results visible in experiments tab | **P0** |
| **A5.4** | Enable Quality Sampling | Configure sampling rate for automated quality evaluations (e.g., evaluate 10% of requests vs 100%); Balances cost vs coverage | User clicks "Configure Sampling" from evaluation settings or cost dashboard | Reduced evaluation costs (proportional to sampling rate); Maintained quality visibility with statistical confidence | Lower sample size may miss edge cases; Confidence intervals wider | Adjust sampling rate back to previous level | Yes - confirm sampling rate and confidence level needed | Log sampling config changes with rate and reasoning | Sample coverage visible in quality dashboard; Confidence bands shown in charts | **P1** |
| **A5.5** | Request Human Review | Escalate low-confidence or disputed evaluations to human reviewers; Creates review task in queue | User clicks "Request Review" from evaluation detail or low-confidence list | Improved evaluation accuracy; Ground truth labels for model fine-tuning; Resolution of edge cases | Human review costs (time/money); Delays in feedback loop | N/A (review remains in queue until completed) | No - instant task creation | Log review request with evaluation details and assigned reviewer | Review queue visible in quality tab; Completion status tracked | **P1** |
| **A5.6** | Create Quality Experiment | Set up A/B test to compare quality of different prompt versions, models, or configurations; Automatically routes traffic and measures quality delta | User clicks "Create Experiment" from quality optimization or experiments tab | Data-driven optimization decisions; Statistical validation of quality improvements; Risk mitigation before full rollout | Traffic split may affect user experience temporarily; Requires monitoring | Stop experiment and revert to control version | Yes - configure experiment parameters (variants, traffic split, duration, success metrics) | Log experiment setup, progress, and results with statistical significance | Experiment results visible in experiments tab; Real-time quality comparison charts | **P1** |
| **A5.7** | Mark Evaluation as Incorrect | Provide feedback when LLM-as-judge evaluation is wrong; Creates training example for evaluator fine-tuning (active learning loop) | User clicks "Dispute Evaluation" from evaluation detail or failed examples table | Improved evaluator accuracy over time; Better alignment with human judgment; Continuous learning | Evaluation score may be updated; Historical metrics affected if re-scored | Undo feedback if mistakenly marked | Yes - confirm correct quality score and reasoning | Log feedback with user, timestamp, original score, corrected score | Evaluator improvement visible in confidence metrics; Feedback incorporated in next model version | **P1** |
| **A5.8** | Bulk Re-evaluate Agents | Trigger bulk re-evaluation of selected agents using updated rubric or improved evaluator model | User selects multiple agents and clicks "Re-evaluate" from agent quality list | Updated quality scores reflecting latest standards; Identification of previously missed issues | Evaluation costs (API calls to Gemini); Processing time; Quota consumption | N/A (evaluations are append-only) | Yes - confirm agent selection and cost estimate | Log bulk re-evaluation request with agent list, rubric version, and results summary | Re-evaluation progress bar; Updated quality metrics appear in dashboard | **P2** |
| **A5.9** | Export Quality Report | Generate comprehensive quality report for selected agents/time range with charts, metrics, examples, and recommendations (PDF/CSV) | User clicks "Export Report" from quality dashboard | Stakeholder-ready quality summary; Executive reporting; Compliance documentation | None | N/A | No - instant export | Log report generation with scope and timestamp | Report includes all visible charts and detailed metrics | **P2** |
| **A5.10** | Set Quality Goal | Define quality improvement goal for agent or team (e.g., "Increase avg quality from 7.2 to 8.5 by Q2") with target and timeline | User clicks "Set Goal" from business impact or quality dashboard | Goal tracking; Team accountability; Progress visualization; Business alignment | Team receives goal notifications and progress updates | Delete or modify goal | Yes - confirm goal target, timeline, and team assignment | Log goal creation and progress milestones | Goal progress visible in dashboard; Alerts when off-track or achieved | **P2** |

---

**Tab 5: Quality PRD Complete**

---

