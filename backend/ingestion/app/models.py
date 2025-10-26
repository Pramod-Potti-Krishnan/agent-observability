"""Trace ingestion data models"""
from pydantic import BaseModel, Field, validator
from datetime import datetime
from typing import Optional, Literal
from uuid import UUID


class TraceInput(BaseModel):
    """Trace input model for ingestion"""
    trace_id: str = Field(..., min_length=1, max_length=64)
    agent_id: str = Field(..., min_length=1, max_length=128)
    workspace_id: UUID
    timestamp: datetime
    input: str
    output: str
    latency_ms: int = Field(..., gt=0)
    status: Literal['success', 'error', 'timeout'] = 'success'
    model: str = Field(..., min_length=1, max_length=64)
    model_provider: str = Field(..., min_length=1, max_length=32)
    tokens_input: Optional[int] = Field(None, ge=0)
    tokens_output: Optional[int] = Field(None, ge=0)
    tokens_total: Optional[int] = Field(None, ge=0)
    cost_usd: Optional[float] = Field(None, ge=0)
    metadata: dict = Field(default_factory=dict)
    tags: list[str] = Field(default_factory=list)

    @validator('tags')
    def validate_tags(cls, v):
        """Ensure tags are unique and limited"""
        if len(v) > 10:
            raise ValueError('Maximum 10 tags allowed')
        return list(set(v))  # Remove duplicates


class BatchTraceInput(BaseModel):
    """Batch trace ingestion model"""
    traces: list[TraceInput] = Field(..., min_items=1, max_items=100)


class TraceResponse(BaseModel):
    """Trace ingestion response"""
    trace_id: str
    status: str = "accepted"
    message: str = "Trace queued for processing"


class BatchTraceResponse(BaseModel):
    """Batch trace ingestion response"""
    accepted: int
    rejected: int
    errors: list[dict] = Field(default_factory=list)
