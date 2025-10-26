"""Pydantic models for Gemini Integration Service"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any, Union
from datetime import datetime, date
from uuid import UUID
from decimal import Decimal
from typing_extensions import Annotated


# ===== Request Models =====

class CostOptimizationRequest(BaseModel):
    """Request for cost optimization insights"""
    days: int = Field(7, ge=1, le=30, description="Number of days to analyze")
    agent_id: Optional[str] = Field(default=None, description="Filter by specific agent")


class ErrorDiagnosisRequest(BaseModel):
    """Request for error diagnosis insights"""
    days: int = Field(7, ge=1, le=30, description="Number of days to analyze")
    agent_id: Optional[str] = Field(default=None, description="Filter by specific agent")
    error_threshold: int = Field(10, ge=1, description="Minimum errors to analyze")


class FeedbackAnalysisRequest(BaseModel):
    """Request for feedback analysis insights"""
    days: int = Field(7, ge=1, le=30, description="Number of days to analyze")
    agent_id: Optional[str] = Field(default=None, description="Filter by specific agent")


class DailySummaryRequest(BaseModel):
    """Request for daily summary"""
    date: Annotated[Union[date, None], Field(description="Date for summary (default: yesterday)")] = None
    agent_id: Optional[str] = Field(default=None, description="Filter by specific agent")


class CreateBusinessGoalRequest(BaseModel):
    """Request to create a business goal"""
    name: str = Field(..., min_length=1, max_length=256)
    description: Optional[str] = None
    metric: str = Field(..., description="Goal metric: support_tickets, csat_score, cost_savings, response_time")
    target_value: Decimal = Field(..., gt=0)
    current_value: Decimal = Field(default=0, ge=0)
    unit: Annotated[Union[str, None], Field(max_length=32, description="Unit: tickets, %, $, ms")] = None
    target_date: Union[date, None] = None


# ===== Response Models =====

class CostBreakdown(BaseModel):
    """Cost breakdown by model/agent"""
    model: str
    agent_id: Optional[str]
    total_cost: float
    total_requests: int
    avg_cost_per_request: float
    total_tokens: int


class CostSavingOpportunity(BaseModel):
    """Single cost saving opportunity"""
    title: str
    description: str
    potential_savings_usd: float
    impact: str  # 'high', 'medium', 'low'
    recommendation: str


class CostOptimizationInsight(BaseModel):
    """Cost optimization insight response"""
    summary: str
    total_cost_usd: float
    total_requests: int
    avg_cost_per_request: float
    cost_breakdown: List[CostBreakdown]
    opportunities: List[CostSavingOpportunity]
    generated_at: datetime
    cached: bool = False


class ErrorPattern(BaseModel):
    """Error pattern identified"""
    error_type: str
    count: int
    percentage: float
    sample_message: str
    affected_agents: List[str]


class ErrorFix(BaseModel):
    """Suggested error fix"""
    title: str
    description: str
    root_cause: str
    fix_steps: List[str]
    impact: str  # 'high', 'medium', 'low'
    priority: int  # 1 = highest


class ErrorDiagnosisInsight(BaseModel):
    """Error diagnosis insight response"""
    summary: str
    total_errors: int
    error_rate: float
    patterns: List[ErrorPattern]
    suggested_fixes: List[ErrorFix]
    generated_at: datetime
    cached: bool = False


class FeedbackTheme(BaseModel):
    """Key theme from feedback"""
    theme: str
    sentiment: str  # 'positive', 'negative', 'neutral'
    count: int
    examples: List[str]


class ActionableInsight(BaseModel):
    """Actionable insight from feedback"""
    title: str
    description: str
    priority: str  # 'high', 'medium', 'low'
    actions: List[str]


class FeedbackAnalysisInsight(BaseModel):
    """Feedback analysis insight response"""
    summary: str
    overall_sentiment_score: float  # -1 to 1
    sentiment_label: str  # 'positive', 'negative', 'neutral', 'mixed'
    total_feedback_items: int
    key_themes: List[FeedbackTheme]
    actionable_insights: List[ActionableInsight]
    generated_at: datetime
    cached: bool = False


class DailyHighlight(BaseModel):
    """Daily highlight item"""
    type: str  # 'success', 'concern', 'trend'
    title: str
    description: str
    metrics: Dict[str, Any]


class DailyRecommendation(BaseModel):
    """Daily recommendation"""
    title: str
    description: str
    priority: str  # 'high', 'medium', 'low'


class DailySummaryInsight(BaseModel):
    """Daily summary insight response"""
    executive_summary: str
    date: date
    total_requests: int
    success_rate: float
    avg_latency_ms: float
    total_cost_usd: float
    highlights: List[DailyHighlight]
    concerns: List[DailyHighlight]
    recommendations: List[DailyRecommendation]
    generated_at: datetime
    cached: bool = False


class BusinessGoal(BaseModel):
    """Business goal response"""
    id: UUID
    workspace_id: UUID
    name: str
    description: Optional[str]
    metric: str
    target_value: Decimal
    current_value: Decimal
    unit: Optional[str]
    target_date: Union[date, None]
    is_active: bool
    created_at: datetime
    updated_at: datetime
    progress_percentage: float = Field(0, ge=0, le=100)


class BusinessGoalsResponse(BaseModel):
    """List of business goals"""
    goals: List[BusinessGoal]
    total: int
    active: int


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    service: str
    version: str
    gemini_configured: bool
    databases_connected: bool
    redis_connected: bool


# ===== Internal Models =====

class CostData(BaseModel):
    """Internal cost data from database"""
    model: str
    agent_id: Optional[str]
    total_cost: float
    request_count: int
    total_tokens: int


class ErrorData(BaseModel):
    """Internal error data from database"""
    error_message: str
    count: int
    agent_id: str
    sample_trace_id: str


class DailySummaryData(BaseModel):
    """Internal daily summary data"""
    total_requests: int
    success_count: int
    error_count: int
    avg_latency: float
    total_cost: float
    model_breakdown: List[Dict[str, Any]]
