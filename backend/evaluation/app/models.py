"""Pydantic models for Evaluation Service"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from uuid import UUID


class EvaluationCriteria(BaseModel):
    """Custom evaluation criteria"""
    name: str = Field(..., description="Criterion name")
    description: str = Field(..., description="What to evaluate")
    weight: float = Field(1.0, ge=0, le=2, description="Weight for this criterion")


class EvaluationRequest(BaseModel):
    """Request to evaluate a trace"""
    trace_id: str = Field(..., description="Trace ID to evaluate")
    custom_criteria: Optional[List[EvaluationCriteria]] = None


class BatchEvaluationRequest(BaseModel):
    """Request to evaluate multiple traces"""
    trace_ids: List[str] = Field(..., max_length=100, description="Trace IDs to evaluate")
    custom_criteria: Optional[List[EvaluationCriteria]] = None


class EvaluationScores(BaseModel):
    """Evaluation scores for a trace"""
    accuracy_score: float = Field(..., ge=0, le=10)
    relevance_score: float = Field(..., ge=0, le=10)
    helpfulness_score: float = Field(..., ge=0, le=10)
    coherence_score: float = Field(..., ge=0, le=10)
    overall_score: float = Field(..., ge=0, le=10)


class EvaluationResult(BaseModel):
    """Single evaluation result"""
    id: UUID
    workspace_id: UUID
    trace_id: str
    created_at: datetime
    evaluator: str
    accuracy_score: float
    relevance_score: float
    helpfulness_score: float
    coherence_score: float
    overall_score: float
    reasoning: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


class BatchEvaluationResult(BaseModel):
    """Batch evaluation results"""
    evaluations: List[EvaluationResult]
    total: int
    successful: int
    failed: int


class EvaluationHistory(BaseModel):
    """Evaluation history response"""
    evaluations: List[EvaluationResult]
    total: int
    avg_overall_score: float
    avg_accuracy_score: float
    avg_relevance_score: float
    avg_helpfulness_score: float
    avg_coherence_score: float


class CreateCriteriaRequest(BaseModel):
    """Request to create custom criteria"""
    name: str = Field(..., min_length=1, max_length=256)
    description: str = Field(..., min_length=1)
    weight: float = Field(1.0, ge=0, le=2)


class CriteriaResponse(BaseModel):
    """Custom criteria response"""
    criteria: List[EvaluationCriteria]
    total: int


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    service: str
    version: str
    gemini_configured: bool
