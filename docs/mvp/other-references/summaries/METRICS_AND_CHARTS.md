# Dashboard Metrics & Charts Documentation
## AI Agent Observability Platform

**Document Version**: 1.0
**Last Updated**: 2025-10-25
**Context**: Complete reference for all metrics, visualizations, and insights across dashboard tabs

---

## Table of Contents

1. [Home Dashboard](#1-home-dashboard)
2. [Usage Analytics](#2-usage-analytics)
3. [Cost Management](#3-cost-management)
4. [Performance Monitoring](#4-performance-monitoring)
5. [Quality Metrics](#5-quality-metrics)
6. [Safety & Guardrails](#6-safety--guardrails)
7. [Business Impact](#7-business-impact)
8. [Metric Relationships](#8-metric-relationships)
9. [Best Practices](#9-best-practices)

---

## 1. Home Dashboard

**Route**: `/dashboard`
**Purpose**: Executive-level overview of all key metrics across the platform
**Refresh Rate**: Every 5 minutes (300s)

### KPI Cards (5)

#### 1.1 Total Requests
- **Type**: KPI Card
- **Values Displayed**:
  - Current: Total number of AI agent API requests
  - Change: Percentage change vs previous period
  - Change Label: "vs last {timeRange}"
- **Trend Type**: Normal (↑ is good)
- **Format**: Formatted number with commas (e.g., "1,243")
- **Insights**:
  - Indicates overall platform usage and adoption
  - Spike suggests increased user engagement or new use cases
  - Drop may indicate system issues or reduced user activity
- **Actions**:
  - **Significant increase**: Verify system capacity, check for cost implications
  - **Unexpected drop**: Investigate errors, check agent availability
  - **Steady growth**: Monitor scaling needs, prepare infrastructure

#### 1.2 Average Latency
- **Type**: KPI Card
- **Values Displayed**:
  - Current: Mean response time across all requests (milliseconds)
  - Change: Percentage change vs previous period
- **Trend Type**: Inverse (↓ is good)
- **Format**: "1305ms" (rounded to nearest millisecond)
- **Insights**:
  - Indicates system performance and user experience quality
  - Higher latency impacts user satisfaction and agent effectiveness
  - Trends show infrastructure health or model performance changes
- **Actions**:
  - **>2000ms**: Investigate slow endpoints, optimize prompts, consider faster models
  - **Increasing trend**: Check for infrastructure bottlenecks, database query performance
  - **Spikes**: Correlate with high request volume or specific agent behaviors

#### 1.3 Error Rate
- **Type**: KPI Card
- **Values Displayed**:
  - Current: Percentage of failed requests
  - Change: Percentage change vs previous period
- **Trend Type**: Inverse (↓ is good)
- **Format**: "14.6%" (1 decimal place)
- **Insights**:
  - Critical reliability metric for agent operations
  - Errors affect user trust and business outcomes
  - Pattern indicates system stability or integration issues
- **Actions**:
  - **>10%**: Immediate investigation, check error logs, review recent deployments
  - **Sudden spike**: Incident response, check external API status, verify configurations
  - **Persistent elevated rate**: Review prompt quality, check model availability

#### 1.4 Total Cost
- **Type**: KPI Card
- **Values Displayed**:
  - Current: Cumulative spend in USD
  - Change: Percentage change vs previous period
- **Trend Type**: Normal (monitoring for budget)
- **Format**: "$23.04" (2 decimal places)
- **Insights**:
  - Tracks financial impact of AI agent operations
  - Correlate with request volume and model usage
  - Budget management and cost optimization indicator
- **Actions**:
  - **Unexpected increase**: Analyze model usage, check for prompt inefficiencies
  - **Approaching budget**: Optimize expensive models, implement caching
  - **Cost per request rising**: Review model selection, optimize token usage

#### 1.5 Quality Score
- **Type**: KPI Card
- **Values Displayed**:
  - Current: Average LLM evaluation score (0-10 scale)
  - Change: Percentage change vs previous period
- **Trend Type**: Normal (↑ is good)
- **Format**: "8.0" (1 decimal place)
- **Insights**:
  - Measures AI output quality through automated LLM-as-judge evaluations
  - Reflects prompt engineering effectiveness
  - Indicates need for model fine-tuning or prompt adjustments
- **Actions**:
  - **<6.0**: Review failing evaluations, improve prompts, consider better models
  - **Declining trend**: Analyze evaluation criteria, check for prompt drift
  - **High variance**: Investigate specific agents or use cases with poor scores

### Widgets (2)

#### 1.6 Alerts Feed
- **Type**: Dynamic feed/list
- **Purpose**: Real-time display of active alerts and notifications
- **Data Source**: Alert Service (Phase 4)
- **Insights**:
  - Critical issues requiring immediate attention
  - Pattern of recurring alerts indicates systematic problems
- **Actions**:
  - Click alert to view details and resolution steps
  - Acknowledge or resolve directly from feed

#### 1.7 Activity Stream
- **Type**: Dynamic feed/list
- **Purpose**: Recent activity log across all agents
- **Data Source**: Trace data aggregation
- **Insights**:
  - Real-time visibility into agent operations
  - Audit trail for debugging and compliance
- **Actions**:
  - Filter by agent ID, user, or time range
  - Click activity to view full trace details

---

## 2. Usage Analytics

**Route**: `/dashboard/usage`
**Purpose**: Track adoption, user engagement, and agent distribution
**Refresh Rate**: Every 30 seconds

### KPI Cards (4)

#### 2.1 Total API Calls
- **Type**: KPI Card
- **Values**: Total request count, change vs previous period
- **Trend**: Normal (↑ indicates growth)
- **Insights**: Primary usage metric for platform adoption
- **Actions**:
  - Track against business goals
  - Capacity planning for infrastructure
  - Marketing/sales indicator for success

#### 2.2 Unique Users
- **Type**: KPI Card
- **Values**: Count of distinct user IDs, change vs previous
- **Trend**: Normal (↑ indicates expansion)
- **Insights**: User base growth and retention
- **Actions**:
  - **Growing**: Plan onboarding, prepare support resources
  - **Stagnant**: Investigate user experience, identify barriers
  - **Declining**: Critical - review product-market fit

#### 2.3 Active Agents
- **Type**: KPI Card
- **Values**: Count of agents with requests in period
- **Trend**: Normal (↑ indicates diversification)
- **Insights**: Agent ecosystem health and variety
- **Actions**:
  - Low diversity: Promote unused agents, identify gaps
  - High diversity: Ensure resource allocation

#### 2.4 Average Calls per User
- **Type**: KPI Card
- **Values**: Mean requests per unique user
- **Trend**: Normal (shows engagement depth)
- **Insights**: User engagement intensity
- **Actions**:
  - Low: Improve user experience, provide better documentation
  - High: Ensure performance scales with power users

### Charts (3)

#### 2.5 API Calls Over Time
- **Chart Type**: Line Chart (Recharts)
- **X-Axis**: Timestamp (hourly for 1h/24h, daily for 7d/30d)
- **Y-Axis**: Number of API calls
- **Data Points**: Aggregated call counts by timestamp
- **Granularity**:
  - 1h/24h: Hourly buckets
  - 7d/30d: Daily buckets
- **Insights**:
  - Usage patterns: Peak hours, weekly cycles, growth trends
  - Anomalies: Sudden spikes or drops indicate events
  - Seasonality: Recurring patterns guide resource planning
- **Actions**:
  - **Identify peak hours**: Schedule maintenance during lows
  - **Spot anomalies**: Investigate unusual patterns
  - **Forecast needs**: Use trends for capacity planning

#### 2.6 Agent Distribution
- **Chart Type**: Pie Chart (Recharts)
- **Data**: Percentage of requests per agent
- **Values Shown**: Agent ID, percentage, call count
- **Colors**: 7-color palette for visual distinction
- **Insights**:
  - Agent popularity and usage concentration
  - Identify underutilized agents
  - Resource allocation guidance
- **Actions**:
  - **High concentration** (>80% one agent): Diversification opportunity
  - **Even distribution**: Healthy ecosystem
  - **Unused agents**: Deprecation candidates or promotion needs

#### 2.7 Top Users Table
- **Chart Type**: Table
- **Columns**:
  - User ID (truncated to 8 chars + "...")
  - Total Calls
  - Agents Used
  - Trend (icon + percentage)
- **Sorting**: By total calls (descending)
- **Limit**: Top 10 users
- **Insights**:
  - Power user identification
  - Usage concentration risk
  - Customer success opportunities
- **Actions**:
  - **Top 10% using >50%**: Engage for feedback, upsell opportunities
  - **Declining power users**: Proactive outreach, identify issues
  - **New top users**: Onboarding success indicator

---

## 3. Cost Management

**Route**: `/dashboard/cost`
**Purpose**: Financial tracking, budget management, cost optimization
**Refresh Rate**: Every 60 seconds

### KPI Cards (4)

#### 3.1 Total Spend
- **Type**: KPI Card
- **Values**: Cumulative cost in period, change vs previous
- **Trend**: Inverse (monitoring-focused)
- **Format**: "$23.04" (2 decimals)
- **Insights**: Primary financial metric
- **Actions**:
  - Compare to budget limits
  - Investigate spikes immediately
  - Trend analysis for forecasting

#### 3.2 Budget Remaining
- **Type**: KPI Card
- **Values**: Remaining budget or "No budget set"
- **Trend**: Normal (awareness metric)
- **Insights**: Burn rate and remaining runway
- **Actions**:
  - **<20% remaining**: Urgent optimization or budget increase
  - **No budget**: Set limits to prevent overruns
  - **On track**: Continue monitoring

#### 3.3 Average Cost per Call
- **Type**: KPI Card
- **Values**: Mean cost per API request
- **Trend**: Inverse (↓ is better efficiency)
- **Format**: "$0.0185" (4 decimals for precision)
- **Insights**: Cost efficiency metric
- **Actions**:
  - **Rising**: Optimize prompts, use cheaper models
  - **High variance**: Some agents much more expensive
  - **Benchmark**: Compare against industry standards

#### 3.4 Projected Monthly Spend
- **Type**: KPI Card
- **Values**: Estimated month-end cost based on current rate
- **Trend**: Normal (forecasting metric)
- **Insights**: Budget planning and runway estimation
- **Actions**:
  - **Exceeds budget**: Immediate intervention required
  - **Update forecasts**: Inform finance/leadership
  - **Adjust budgets**: Reallocate based on projections

### Charts & Widgets (4)

#### 3.5 Monthly Budget Usage
- **Chart Type**: Progress Bar with Card
- **Values**:
  - Current spend vs monthly limit
  - Percentage used
  - Remaining budget
- **Visual**: Progress bar with color coding
  - <70%: Normal (blue/green)
  - 70-89%: Warning (yellow)
  - ≥90%: Critical (red)
- **Insights**: Budget health at-a-glance
- **Actions**:
  - **≥Alert Threshold**: Notifications sent
  - **Adjust**: Update budget or optimize costs
  - **Plan**: Forecasting for next period

#### 3.6 Cost Trend by Model
- **Chart Type**: Stacked Area Chart
- **X-Axis**: Time (hourly/daily)
- **Y-Axis**: Cost in USD
- **Stacks**: One per model (GPT-4, Claude, etc.)
- **Colors**: Distinct palette per model
- **Insights**:
  - Model cost distribution over time
  - Identify expensive models
  - Track cost optimization efforts
- **Actions**:
  - **Dominant model**: Consider cheaper alternatives
  - **Sudden spikes**: Investigate specific time periods
  - **Optimize**: Switch to cheaper models where appropriate

#### 3.7 Cost by Model (Horizontal Bar Chart)
- **Chart Type**: Horizontal Bar Chart
- **X-Axis**: Total cost (USD)
- **Y-Axis**: Model name
- **Values**: Total spend per model
- **Insights**:
  - Model cost comparison
  - ROI analysis per model
  - Optimization targets
- **Actions**:
  - **Most expensive**: Prime optimization candidate
  - **Underused expensive models**: Evaluate necessity
  - **Balance**: Cost vs performance tradeoffs

#### 3.8 Budget Settings Card
- **Type**: Interactive Form
- **Inputs**:
  - Monthly Budget Limit ($)
  - Alert Threshold (%)
- **Actions**: Update budget settings
- **Display**: Current settings
- **Insights**: Self-service budget management
- **Actions**:
  - Set realistic budgets based on trends
  - Adjust thresholds for notification preferences
  - Regular review and update

### Alerts

#### 3.9 Budget Alert
- **Trigger**: Spend ≥ alert threshold percentage
- **Severity**: Destructive/Critical
- **Message**: "You've used X% of your monthly budget"
- **Actions**: Prompt for optimization or budget increase
- **Insights**: Proactive cost management

---

## 4. Performance Monitoring

**Route**: `/dashboard/performance`
**Purpose**: Latency analysis, throughput tracking, error diagnosis
**Refresh Rate**: Every 30 seconds

### KPI Cards (4)

#### 4.1 P50 Latency (Median)
- **Type**: KPI Card
- **Values**: 50th percentile response time (ms)
- **Trend**: Inverse (↓ is better)
- **Insights**: Typical user experience
- **Actions**:
  - Baseline for performance expectations
  - Target for optimization efforts

#### 4.2 P95 Latency
- **Type**: KPI Card
- **Values**: 95th percentile response time (ms)
- **Trend**: Inverse (↓ is better)
- **Insights**: "Slow but acceptable" threshold
- **Actions**:
  - SLA definition metric
  - Outlier detection trigger

#### 4.3 P99 Latency
- **Type**: KPI Card
- **Values**: 99th percentile response time (ms)
- **Trend**: Inverse (↓ is better)
- **Insights**: Worst-case user experience
- **Actions**:
  - **>5s**: Critical performance issue
  - Investigate slow queries/prompts
  - Capacity or optimization needed

#### 4.4 Error Rate
- **Type**: KPI Card
- **Values**: Percentage of failed requests
- **Trend**: Inverse (↓ is better)
- **Label**: "{total_requests} total requests"
- **Insights**: Reliability metric
- **Actions**:
  - **>5%**: Investigate immediately
  - Check error table for patterns

### Charts (3)

#### 4.5 Latency Percentiles Over Time
- **Chart Type**: Multi-line Chart
- **Lines**:
  - P50 (green): Median
  - P95 (blue): 95th percentile
  - P99 (orange): 99th percentile
- **X-Axis**: Timestamp
- **Y-Axis**: Latency (ms)
- **Insights**:
  - Performance trends over time
  - Identify degradation early
  - Correlate with deployments/changes
- **Actions**:
  - **P95-P99 gap widening**: Investigate outliers
  - **All percentiles rising**: System-wide issue
  - **Spikes**: Correlate with events (deploy, traffic)

#### 4.6 Request Throughput by Status
- **Chart Type**: Stacked Area Chart
- **Stacks**:
  - Success (green)
  - Error (red)
  - Timeout (yellow)
- **X-Axis**: Timestamp
- **Y-Axis**: Request count
- **Insights**:
  - Volume patterns by outcome
  - Error/timeout proportion visibility
  - Capacity planning data
- **Actions**:
  - **High error stack**: Immediate investigation
  - **Timeout patterns**: Increase timeout or optimize
  - **Success trends**: Validate system health

#### 4.7 Error Analysis Table
- **Chart Type**: Table
- **Columns**:
  - Agent ID (truncated)
  - Error Type
  - Error Count
  - Error Rate (%)
  - Last Occurrence
- **Features**:
  - Sample error message (truncated)
  - Severity badges (>10% error rate = red)
  - Sortable by count
- **Limit**: Top 10 errors
- **Insights**:
  - Error patterns by agent
  - Root cause identification
  - Prioritization for fixes
- **Actions**:
  - **Click row**: View full error details
  - **High count**: Systematic issue, needs fix
  - **Recent occurrence**: Active problem

### Summary Card

#### 4.8 Performance Summary
- **Type**: Statistics Card
- **Values**:
  - Average Latency (ms)
  - Success Rate (%)
  - Requests per Second
- **Insights**: Quick health check
- **Actions**: Baseline metrics for troubleshooting

---

## 5. Quality Metrics

**Route**: `/dashboard/quality`
**Purpose**: LLM-based output quality evaluation and tracking
**Refresh Rate**: Every 30 seconds

### KPI Cards (4)

#### 5.1 Quality Score Card
- **Type**: Custom KPI Card with trend
- **Values**:
  - Average overall score (0-10 scale)
  - Trend percentage vs previous period
  - Time range context
- **Visual**: Large score with trend indicator
- **Insights**:
  - Primary quality metric
  - Effectiveness of prompts/models
  - User satisfaction proxy
- **Actions**:
  - **<6.0**: Review poor evaluations, improve prompts
  - **Declining**: Analyze changes, check for prompt drift
  - **8.0+**: Maintain quality, document best practices

#### 5.2 Total Evaluations
- **Type**: KPI Card
- **Values**: Count of LLM evaluations performed
- **Insights**: Evaluation coverage
- **Actions**:
  - Low coverage: Increase evaluation sampling
  - Compare to total requests for coverage %

#### 5.3 Excellent Scores
- **Type**: KPI Card
- **Values**: Count of scores ≥8.0, percentage of total
- **Color**: Green (positive indicator)
- **Insights**: High-quality output proportion
- **Actions**:
  - **<50%**: Quality improvement needed
  - **Increasing**: Validate improvements working
  - Benchmark: Target 70%+ excellent

#### 5.4 Needs Improvement
- **Type**: KPI Card
- **Values**: Count of scores <6.0, percentage of total
- **Color**: Red (attention needed)
- **Insights**: Problem area identification
- **Actions**:
  - **>20%**: Urgent quality initiative
  - Review failing examples
  - Improve prompts for these cases

### Charts (3)

#### 5.5 Quality Trend Chart
- **Chart Type**: Line Chart
- **X-Axis**: Date
- **Y-Axis**: Average quality score
- **Data Points**: Daily average overall scores
- **Insights**:
  - Quality trajectory over time
  - Impact of changes visible
  - Seasonal patterns
- **Actions**:
  - **Improving trend**: Document what worked
  - **Declining**: Investigate root cause
  - **Stable**: Benchmark for consistency

#### 5.6 Criteria Breakdown
- **Chart Type**: Radar/Bar Chart
- **Criteria**:
  - Accuracy Score
  - Relevance Score
  - Helpfulness Score
  - Coherence Score
- **Scale**: 0-10 for each
- **Insights**:
  - Specific quality dimensions
  - Identify weak areas
  - Targeted improvement opportunities
- **Actions**:
  - **Accuracy low**: Fact-checking issues
  - **Relevance low**: Context understanding problem
  - **Helpfulness low**: Output usefulness needs work
  - **Coherence low**: Logical flow issues

#### 5.7 Recent Evaluations Table
- **Chart Type**: Table
- **Columns**:
  - Trace ID (linkable)
  - Created At
  - Evaluator (gemini/custom)
  - Overall Score
  - Individual Criteria Scores
  - Reasoning (truncated)
- **Sorting**: Most recent first
- **Limit**: Last 15 evaluations
- **Insights**:
  - Specific evaluation details
  - Pattern recognition
  - Individual case review
- **Actions**:
  - **Click row**: View full trace + reasoning
  - **Low scores**: Understand failure modes
  - **High scores**: Learn from successes

---

## 6. Safety & Guardrails

**Route**: `/dashboard/safety`
**Purpose**: PII detection, content safety, compliance monitoring
**Refresh Rate**: Every 60 seconds

### KPI Cards & Widgets (2)

#### 6.1 Violation KPI Card
- **Type**: Combined KPI Card
- **Values**:
  - Total Violations count
  - Breakdown by severity:
    - Critical
    - High
    - Medium
  - Trend percentage
- **Insights**: Safety posture at-a-glance
- **Actions**:
  - **Critical > 0**: Immediate review required
  - **Increasing trend**: Tighten guardrails
  - **Zero violations**: Validate guardrails working

#### 6.2 Type Breakdown Chart
- **Chart Type**: Bar Chart (horizontal or vertical)
- **Categories**:
  - PII Detected
  - Toxicity Violations
  - Prompt Injection Attempts
- **Values**: Count per type
- **Insights**:
  - Most common violation types
  - Attack vector identification
  - Compliance risk areas
- **Actions**:
  - **PII high**: Strengthen input filtering
  - **Toxicity**: Review content policies
  - **Injection**: Enhance security measures

### Charts (2)

#### 6.3 Violation Trend Chart
- **Chart Type**: Stacked Area Chart
- **Stacks**:
  - Critical (red)
  - High (orange)
  - Medium (yellow)
- **X-Axis**: Date
- **Y-Axis**: Violation count
- **Insights**:
  - Violation patterns over time
  - Effectiveness of guardrail changes
  - Emerging threat detection
- **Actions**:
  - **Sudden spike**: Investigate cause (attack? bug?)
  - **Decreasing**: Guardrails working
  - **Patterns**: Adjust detection rules

#### 6.4 Recent Violations Table
- **Chart Type**: Table
- **Columns**:
  - Trace ID
  - Violation Type (PII/Toxicity/Injection)
  - Severity (badge)
  - Detected Content (redacted preview)
  - Redacted Content (cleaned version)
  - Detected At
- **Features**:
  - Severity color coding
  - Content truncation for privacy
  - Sortable by severity/date
- **Limit**: Last 15 violations
- **Insights**:
  - Specific violation examples
  - Pattern identification
  - False positive detection
- **Actions**:
  - **Review severity**: Adjust thresholds
  - **False positives**: Refine detection rules
  - **True violations**: Compliance documentation

---

## 7. Business Impact

**Route**: `/dashboard/impact`
**Purpose**: ROI tracking, business goal progress, outcome measurement
**Refresh Rate**: Every 5 minutes

### KPI Cards (4)

#### 7.1 ROI Card
- **Type**: Custom KPI Card
- **Values**:
  - ROI Percentage: ((savings - investment) / investment) × 100
  - Total Savings
  - Investment Amount
  - Period (e.g., "Last 30 days")
- **Visual**: Large ROI % with breakdown
- **Insights**: Financial return justification
- **Actions**:
  - **ROI >100%**: Strong business case
  - **<0%**: Investigate costs, optimize
  - **Track progress**: Compare periods

#### 7.2 Total Cost Savings
- **Type**: KPI Card
- **Values**: Cumulative savings from automation
- **Color**: Green (positive impact)
- **Target**: Compare to goal
- **Insights**: Direct financial benefit
- **Actions**:
  - Compare to manual cost baseline
  - Track against budget justification

#### 7.3 Support Tickets Reduced
- **Type**: KPI Card
- **Values**: Number of tickets deflected
- **Progress**: Percentage of goal achieved
- **Insights**: Operational efficiency gain
- **Actions**:
  - Validate with support team
  - Track deflection rate trends

#### 7.4 CSAT Score
- **Type**: KPI Card
- **Values**: Customer Satisfaction score (1-5 scale)
- **Improvement**: Percentage change
- **Color**: Purple
- **Insights**: User satisfaction metric
- **Actions**:
  - **<4.0**: Investigate quality issues
  - **Improving**: Validate changes working

### Widgets (3)

#### 7.5 Goal Progress Card
- **Type**: Custom Card with Multiple Progress Bars
- **Goals Displayed**:
  - Cost Savings Goal
  - Support Ticket Reduction Goal
  - CSAT Improvement Goal
  - Response Time Goal
  - Accuracy Goal
- **Values per Goal**:
  - Goal Name
  - Current Value
  - Target Value
  - Progress Percentage
  - Target Date
- **Visual**: Progress bars with percentages
- **Insights**:
  - Goal achievement tracking
  - Deadline awareness
  - Priority identification
- **Actions**:
  - **<50% progress, near deadline**: Escalate
  - **>100% achieved**: Set new targets
  - **Off-track**: Adjust strategy

#### 7.6 Impact Timeline Chart
- **Chart Type**: Multi-line Chart
- **Lines**:
  - Cost Savings (cumulative)
  - Support Tickets Reduced
  - CSAT Improvement
- **X-Axis**: Date (last 30 days)
- **Y-Axis**: Multiple scales (different units)
- **Insights**:
  - Impact growth over time
  - Correlation between metrics
  - Forecasting data
- **Actions**:
  - Identify inflection points
  - Correlate with initiatives
  - Forecast future impact

#### 7.7 Metrics Table
- **Type**: Comparison Table
- **Columns**:
  - Category (metric name)
  - Before (baseline)
  - After (current)
  - Improvement (% change)
  - Status (icon)
- **Metrics Tracked**:
  - Average Response Time
  - Support Tickets/Day
  - CSAT Score
  - Cost per Interaction
  - Accuracy Rate
  - Monthly Cost
- **Visual**:
  - Green up arrows for improvements
  - Percentage change formatting
- **Insights**:
  - Before/after comparison
  - Quantified improvements
  - Business case validation
- **Actions**:
  - **Share with stakeholders**: Business justification
  - **Identify laggards**: Focus improvement efforts
  - **Celebrate wins**: Team morale

---

## 8. Metric Relationships

### Primary Relationships

**Usage ↔ Cost**
- More requests = higher cost (direct correlation)
- Track cost per request to optimize efficiency

**Performance ↔ Quality**
- Higher latency may indicate more complex processing = better quality
- Balance speed vs quality based on use case

**Quality ↔ Cost**
- Better models (more expensive) often = higher quality
- Optimize for cost-effective quality threshold

**Safety ↔ Quality**
- Aggressive filtering may reduce violations but impact quality
- Balance security with usability

**Usage ↔ Business Impact**
- Higher usage (tickets deflected) = cost savings
- Adoption drives ROI

### Key Ratios

**Efficiency Metrics**:
- Cost per Request = Total Cost / Total Requests
- Cost per Quality Point = Total Cost / Average Quality Score
- Errors per 1000 Requests = (Error Count / Total Requests) × 1000

**Adoption Metrics**:
- Calls per User = Total Calls / Unique Users
- Agent Utilization = Active Agents / Total Agents
- Ticket Deflection Rate = Tickets Reduced / Baseline Tickets

**Financial Metrics**:
- ROI % = ((Savings - Investment) / Investment) × 100
- Cost Efficiency = Current Cost / Baseline Cost
- Payback Period = Investment / Monthly Savings

---

## 9. Best Practices

### Monitoring Strategy

**Daily Reviews**:
- Home Dashboard: Overall health check
- Performance: Error rates and latency spikes
- Safety: Critical violations

**Weekly Reviews**:
- Cost: Budget tracking, optimization opportunities
- Usage: Adoption trends, user engagement
- Quality: Evaluation scores, improvement areas

**Monthly Reviews**:
- Business Impact: Goal progress, ROI calculation
- All Dashboards: Comprehensive analysis
- Optimization Planning: Cost, quality, performance initiatives

### Alert Thresholds (Recommended)

**Performance**:
- Error Rate >10%: Immediate attention
- P95 Latency >2000ms: Investigate
- P99 Latency >5000ms: Critical

**Cost**:
- Budget Used >80%: Warning notification
- Budget Used >95%: Critical alert
- Cost per Request >$0.05: Review optimization

**Quality**:
- Average Score <6.0: Improvement initiative
- "Needs Improvement" >20%: Quality focus required

**Safety**:
- Critical Violations >0: Immediate review
- Total Violations increasing >50%: Tighten guardrails

### Time Range Selection

**1 Hour**: Real-time monitoring, incident response
**24 Hours**: Daily operations, shift handoffs
**7 Days**: Weekly trends, sprint reviews
**30 Days**: Monthly reports, strategic planning

### Dashboard Customization Needs

**By Role**:

**Executive/Leadership**:
- Focus: Home, Business Impact
- Key Metrics: ROI, cost savings, quality score

**Engineering/DevOps**:
- Focus: Performance, Usage, Cost
- Key Metrics: Latency percentiles, error rates, throughput

**Product/Quality**:
- Focus: Quality, Safety, Usage
- Key Metrics: Evaluation scores, user engagement, violation rates

**Finance/Operations**:
- Focus: Cost, Business Impact
- Key Metrics: Budget usage, cost per request, ROI

### Correlation Analysis

When investigating issues, check related dashboards:

**High Costs**:
1. Check Usage: Request volume spike?
2. Check Performance: Retries due to errors?
3. Check Cost: Model usage shift?

**Quality Drops**:
1. Check Performance: Higher latency = model changes?
2. Check Safety: Over-aggressive filtering?
3. Check Usage: New use cases?

**Error Spikes**:
1. Check Performance: Latency correlation?
2. Check Cost: Rate limiting?
3. Check Usage: Sudden traffic increase?

---

**End of Metrics & Charts Documentation**

**Feedback**: Submit improvements to this documentation via GitHub issues or internal feedback channels.
