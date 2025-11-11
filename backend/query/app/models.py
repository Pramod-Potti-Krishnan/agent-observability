"""Response models for Query Service"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List, Literal
from uuid import UUID


class KPIMetric(BaseModel):
    """Single KPI metric"""
    value: float
    change: float  # Percentage change from previous period
    change_label: str = "vs last period"
    trend: Literal['normal', 'inverse'] = 'normal'


class HomeKPIs(BaseModel):
    """Home dashboard KPIs"""
    total_requests: KPIMetric
    avg_latency_ms: KPIMetric
    error_rate: KPIMetric
    total_cost_usd: KPIMetric
    avg_quality_score: KPIMetric


class Alert(BaseModel):
    """Alert model"""
    id: UUID
    workspace_id: UUID
    title: str
    description: str
    severity: Literal['info', 'warning', 'critical']
    metric_value: Optional[float] = None
    created_at: datetime


class Activity(BaseModel):
    """Activity stream item"""
    id: UUID
    workspace_id: UUID
    trace_id: str
    agent_id: str
    action: str  # e.g., "trace_ingested", "evaluation_completed"
    status: Literal['success', 'error', 'timeout']
    timestamp: datetime
    metadata: dict = Field(default_factory=dict)


class Trace(BaseModel):
    """Trace summary model"""
    trace_id: str
    agent_id: str
    workspace_id: UUID
    timestamp: datetime
    latency_ms: int
    status: Literal['success', 'error', 'timeout']
    model: str
    model_provider: str
    tokens_total: Optional[int] = None
    cost_usd: Optional[float] = None
    tags: List[str] = Field(default_factory=list)


class TraceDetail(Trace):
    """Full trace details"""
    input: str
    output: str
    error: Optional[str] = None
    tokens_input: Optional[int] = None
    tokens_output: Optional[int] = None
    metadata: dict = Field(default_factory=dict)


class PaginatedResponse(BaseModel):
    """Generic paginated response"""
    items: List
    total: int
    page: int
    page_size: int
    has_next: bool
    has_prev: bool


# Usage Analytics Models
class ChangeMetrics(BaseModel):
    """Change metrics from previous period"""
    total_calls: float
    unique_users: float
    active_agents: float


class UsageOverview(BaseModel):
    """Usage overview metrics"""
    total_calls: int
    unique_users: int
    active_agents: int
    avg_calls_per_user: float
    change_from_previous: ChangeMetrics


class CallsOverTimeItem(BaseModel):
    """Single time bucket for calls over time"""
    timestamp: datetime
    agent_id: str
    call_count: int
    avg_latency_ms: float
    total_cost_usd: float


class CallsOverTime(BaseModel):
    """Calls over time response"""
    data: List[CallsOverTimeItem]
    granularity: str
    range: str


class AgentDistributionItem(BaseModel):
    """Single agent distribution item"""
    agent_id: str
    call_count: int
    percentage: float
    avg_latency_ms: float
    error_rate: float


class AgentDistribution(BaseModel):
    """Agent distribution response"""
    data: List[AgentDistributionItem]
    total_calls: int


class TopUsersItem(BaseModel):
    """Single top user item"""
    user_id: str
    total_calls: int
    agents_used: int
    last_active: datetime
    trend: Literal['up', 'down', 'stable']
    change_percentage: float
    department: Optional[str] = None
    total_cost_usd: float = 0.0
    risk_score: Optional[float] = None  # Based on error rate + high-cost usage


class TopUsers(BaseModel):
    """Top users response"""
    data: List[TopUsersItem]
    total_users: int


# Cost Management Models
class CostOverview(BaseModel):
    """Cost overview metrics"""
    total_spend_usd: float
    budget_limit_usd: Optional[float] = None
    budget_remaining_usd: Optional[float] = None
    budget_used_percentage: Optional[float] = None
    avg_cost_per_call_usd: float
    projected_monthly_spend_usd: float
    change_from_previous: float  # Percentage change


class CostTrendItem(BaseModel):
    """Single time bucket for cost trend"""
    timestamp: datetime
    model: str
    total_cost_usd: float
    call_count: int
    avg_cost_per_call_usd: float


class CostTrend(BaseModel):
    """Cost trend over time response"""
    data: List[CostTrendItem]
    granularity: str
    range: str


class CostByModelItem(BaseModel):
    """Cost breakdown by model"""
    model: str
    model_provider: str
    total_cost_usd: float
    call_count: int
    avg_cost_per_call_usd: float
    percentage_of_total: float


class CostByModel(BaseModel):
    """Cost by model response"""
    data: List[CostByModelItem]
    total_cost_usd: float


class Budget(BaseModel):
    """Budget information"""
    workspace_id: UUID
    monthly_limit_usd: Optional[float] = None
    alert_threshold_percentage: float = 80.0  # Alert at 80% by default
    current_spend_usd: float
    created_at: datetime
    updated_at: datetime


class BudgetUpdate(BaseModel):
    """Budget update request"""
    monthly_limit_usd: Optional[float] = None
    alert_threshold_percentage: Optional[float] = None


# Performance Monitoring Models
class PerformanceOverview(BaseModel):
    """Performance overview metrics"""
    p50_latency_ms: float
    p95_latency_ms: float
    p99_latency_ms: float
    avg_latency_ms: float
    error_rate: float  # Percentage
    success_rate: float  # Percentage
    total_requests: int
    requests_per_second: float


class LatencyPercentilesItem(BaseModel):
    """Latency percentiles for a time bucket"""
    timestamp: datetime
    p50: float
    p95: float
    p99: float
    avg: float


class LatencyPercentiles(BaseModel):
    """Latency percentiles over time response"""
    data: List[LatencyPercentilesItem]
    granularity: str
    range: str


class ThroughputItem(BaseModel):
    """Throughput for a time bucket"""
    timestamp: datetime
    success_count: int
    error_count: int
    timeout_count: int
    total_count: int
    requests_per_second: float


class Throughput(BaseModel):
    """Throughput over time response"""
    data: List[ThroughputItem]
    granularity: str
    range: str


class ErrorAnalysisItem(BaseModel):
    """Error analysis for an agent or error type"""
    agent_id: str
    error_type: str
    error_count: int
    error_rate: float  # Percentage
    last_occurrence: datetime
    sample_error_message: Optional[str] = None


class ErrorAnalysis(BaseModel):
    """Error analysis response"""
    data: List[ErrorAnalysisItem]
    total_errors: int
    total_requests: int
    overall_error_rate: float


# Quality Monitoring Models
class QualityTierDistribution(BaseModel):
    """Distribution across quality tiers"""
    excellent: int  # >= 9.0
    good: int       # 7.0-8.9
    fair: int       # 5.0-6.9
    poor: int       # 3.0-4.9
    failing: int    # < 3.0


class QualityOverview(BaseModel):
    """Quality overview metrics"""
    avg_score: float
    median_score: float
    total_evaluations: int
    distribution: QualityTierDistribution
    drift_indicator: float  # Percentage change from baseline
    at_risk_agents: int  # Agents below quality threshold
    range: str


class QualityDistributionItem(BaseModel):
    """Quality score distribution bucket"""
    score_range: str  # e.g., "9.0-10.0"
    count: int
    percentage: float
    avg_cost_usd: float


class QualityDistribution(BaseModel):
    """Quality distribution response"""
    data: List[QualityDistributionItem]
    total_evaluations: int


class TopFailingAgentItem(BaseModel):
    """Agent with quality issues"""
    agent_id: str
    avg_score: float
    evaluation_count: int
    failing_rate: float  # Percentage < 5.0
    recent_trend: Literal['improving', 'stable', 'degrading']
    cost_impact_usd: float  # Cost of failed evaluations
    last_failure: Optional[datetime] = None


class TopFailingAgents(BaseModel):
    """Top failing agents response"""
    data: List[TopFailingAgentItem]
    total_failing_agents: int


class QualityCostTradeoffItem(BaseModel):
    """Quality vs cost analysis point"""
    agent_id: str
    avg_quality_score: float
    avg_cost_per_request_usd: float
    total_requests: int
    efficiency_score: float  # Quality / Cost ratio
    quadrant: Literal['high_quality_low_cost', 'high_quality_high_cost', 'low_quality_low_cost', 'low_quality_high_cost']


class QualityCostTradeoff(BaseModel):
    """Quality cost tradeoff response"""
    data: List[QualityCostTradeoffItem]
    avg_quality: float
    avg_cost: float


class RubricHeatmapItem(BaseModel):
    """Rubric criteria scores for an agent"""
    agent_id: str
    accuracy_score: float
    relevance_score: float
    helpfulness_score: float
    coherence_score: float
    overall_score: float
    evaluation_count: int


class RubricHeatmap(BaseModel):
    """Rubric heatmap response"""
    data: List[RubricHeatmapItem]
    criteria_averages: dict  # { "accuracy": 8.5, "relevance": 7.2, ... }


class DriftTimelineItem(BaseModel):
    """Quality drift detection point"""
    timestamp: datetime
    avg_score: float
    baseline_score: float
    drift_percentage: float
    evaluation_count: int
    alert_triggered: bool


class DriftTimeline(BaseModel):
    """Drift timeline response"""
    data: List[DriftTimelineItem]
    baseline_score: float
    current_score: float
    drift_threshold: float
    granularity: str
    range: str


class AgentCriteriaBreakdown(BaseModel):
    """Rubric criteria breakdown for an agent"""
    accuracy: float
    relevance: float
    helpfulness: float
    coherence: float


class AgentEvaluationItem(BaseModel):
    """Individual evaluation for an agent"""
    id: str
    trace_id: str
    overall_score: float
    accuracy_score: Optional[float] = None
    relevance_score: Optional[float] = None
    helpfulness_score: Optional[float] = None
    coherence_score: Optional[float] = None
    evaluator: str
    created_at: datetime


class AgentQualityDetails(BaseModel):
    """Comprehensive quality metrics for a single agent"""
    agent_id: str
    avg_score: float
    median_score: float
    total_evaluations: int
    failing_rate: float  # Percentage < 5.0
    recent_trend: Literal['improving', 'stable', 'degrading']
    drift_indicator: float  # Percentage change from baseline
    criteria_breakdown: AgentCriteriaBreakdown
    timeline: List[DriftTimelineItem]
    recent_evaluations: List[AgentEvaluationItem]
    range: str


class UnevaluatedTraceItem(BaseModel):
    """Single un-evaluated trace for manual selection"""
    trace_id: str
    input: str
    output: str
    timestamp: datetime
    status: str


class UnevaluatedTracesResponse(BaseModel):
    """Response with un-evaluated traces for an agent"""
    traces: List[UnevaluatedTraceItem]
    total: int
    agent_id: str
