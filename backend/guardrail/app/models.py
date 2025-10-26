"""Pydantic models for Guardrail Service"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from uuid import UUID


class PIIDetectionRequest(BaseModel):
    """Request to detect PII in text"""
    text: str = Field(..., max_length=100000)


class ToxicityCheckRequest(BaseModel):
    """Request to check toxicity"""
    text: str = Field(..., max_length=100000)


class GuardrailCheckRequest(BaseModel):
    """Request to check all guardrails"""
    text: str = Field(..., max_length=100000)
    trace_id: Optional[str] = None


class PIIDetection(BaseModel):
    """PII detection result"""
    type: str  # email, phone, ssn, credit_card, ip_address
    value: str
    position: tuple[int, int]
    severity: str  # low, medium, high, critical


class PIIDetectionResponse(BaseModel):
    """PII detection response"""
    detections: List[PIIDetection]
    total: int
    has_pii: bool
    redacted_text: Optional[str] = None


class ToxicityResult(BaseModel):
    """Toxicity detection result"""
    is_toxic: bool
    confidence: float
    severity: str  # low, medium, high


class GuardrailViolation(BaseModel):
    """Single guardrail violation"""
    type: str  # pii_detection, toxicity, prompt_injection
    severity: str
    message: str
    details: Optional[Dict[str, Any]] = None


class GuardrailCheckResponse(BaseModel):
    """Comprehensive guardrail check response"""
    violations: List[GuardrailViolation]
    total_violations: int
    is_safe: bool
    pii_detected: bool
    is_toxic: bool
    injection_detected: bool


class ViolationHistory(BaseModel):
    """Violation record"""
    id: UUID
    workspace_id: UUID
    rule_id: UUID
    trace_id: str
    detected_at: datetime
    violation_type: str
    severity: str
    message: str
    detected_content: Optional[str] = None
    redacted_content: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


class ViolationsListResponse(BaseModel):
    """List of violations"""
    violations: List[ViolationHistory]
    total: int


class SeverityBreakdown(BaseModel):
    """Severity breakdown"""
    critical: int = 0
    high: int = 0
    medium: int = 0


class TypeBreakdown(BaseModel):
    """Type breakdown"""
    pii: int = 0
    toxicity: int = 0
    injection: int = 0


class ViolationSummaryResponse(BaseModel):
    """Comprehensive violations response with breakdowns for Safety dashboard"""
    violations: List[ViolationHistory]
    total_count: int
    severity_breakdown: SeverityBreakdown
    type_breakdown: TypeBreakdown
    trend_percentage: float = 0.0


class CreateRuleRequest(BaseModel):
    """Request to create a guardrail rule"""
    agent_id: Optional[str] = None
    rule_type: str = Field(..., pattern="^(pii_detection|toxicity|prompt_injection|custom)$")
    name: str = Field(..., min_length=1, max_length=256)
    description: Optional[str] = None
    config: Dict[str, Any] = {}
    severity: str = Field("warning", pattern="^(info|warning|error|critical)$")
    action: str = Field("log", pattern="^(log|block|redact)$")


class GuardrailRule(BaseModel):
    """Guardrail rule"""
    id: UUID
    workspace_id: UUID
    agent_id: Optional[str]
    rule_type: str
    name: str
    description: Optional[str]
    config: Dict[str, Any]
    severity: str
    action: str
    is_active: bool
    created_at: datetime
    updated_at: datetime


class RulesListResponse(BaseModel):
    """List of guardrail rules"""
    rules: List[GuardrailRule]
    total: int


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    service: str
    version: str
