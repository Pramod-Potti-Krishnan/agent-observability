"""Guardrail routes"""
from fastapi import APIRouter, HTTPException, status, Header, Depends
from typing import Optional, List
import asyncpg
import json
import redis.asyncio as redis
import logging
from uuid import UUID, uuid4
from datetime import datetime

from ..models import (
    GuardrailCheckRequest,
    GuardrailCheckResponse,
    GuardrailViolation,
    PIIDetectionRequest,
    PIIDetectionResponse,
    PIIDetection,
    ToxicityCheckRequest,
    ToxicityResult,
    ViolationsListResponse,
    ViolationHistory,
    ViolationSummaryResponse,
    SeverityBreakdown,
    TypeBreakdown,
    CreateRuleRequest,
    GuardrailRule
)
from ..database import get_postgres_pool
from ..detectors.pii import detect_pii, redact_pii
from ..detectors.toxicity import detect_toxicity
from ..detectors.injection import detect_prompt_injection
from ..config import get_settings

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/guardrails", tags=["guardrails"])
settings = get_settings()

# Redis client for caching
_redis_client: Optional[redis.Redis] = None


async def get_redis_client() -> redis.Redis:
    """Get or create Redis client"""
    global _redis_client

    if _redis_client is None:
        _redis_client = await redis.from_url(
            settings.redis_url,
            encoding="utf-8",
            decode_responses=True
        )

    return _redis_client


async def get_cache(key: str) -> Optional[dict]:
    """Get value from cache"""
    try:
        client = await get_redis_client()
        value = await client.get(key)
        if value:
            return json.loads(value)
    except Exception as e:
        logger.warning(f"Cache get failed: {e}")
    return None


async def set_cache(key: str, value: dict, ttl: int):
    """Set value in cache"""
    try:
        client = await get_redis_client()
        await client.setex(key, ttl, json.dumps(value))
    except Exception as e:
        logger.warning(f"Cache set failed: {e}")


@router.post("/check", response_model=GuardrailCheckResponse)
async def check_guardrails(
    request: GuardrailCheckRequest,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Check content against all guardrails (PII, toxicity, injection)

    Args:
        request: Content to check
        x_workspace_id: Workspace ID from header

    Returns:
        Comprehensive guardrail check results with all violations
    """

    try:
        violations: List[GuardrailViolation] = []
        text = request.text

        # 1. Check for PII
        pii_detections = detect_pii(text)
        pii_detected = len(pii_detections) > 0

        for detection in pii_detections:
            violations.append(GuardrailViolation(
                type="pii_detection",
                severity=detection['severity'],
                message=f"Detected {detection['type']}: {detection['value']}",
                details={
                    "pii_type": detection['type'],
                    "value": detection['value'],
                    "position": detection['position']
                }
            ))

        # 2. Check toxicity
        toxicity_result = detect_toxicity(text)
        is_toxic = toxicity_result['is_toxic']

        if is_toxic:
            violations.append(GuardrailViolation(
                type="toxicity",
                severity=toxicity_result['severity'],
                message=f"Toxic content detected (confidence: {toxicity_result['confidence']:.2f})",
                details={
                    "confidence": toxicity_result['confidence'],
                    "severity": toxicity_result['severity']
                }
            ))

        # 3. Check for prompt injection
        injection_detections = detect_prompt_injection(text)
        injection_detected = len(injection_detections) > 0

        for injection in injection_detections:
            violations.append(GuardrailViolation(
                type="prompt_injection",
                severity=injection['severity'],
                message=f"Potential prompt injection detected",
                details={
                    "pattern": injection['pattern']
                }
            ))

        # Save violations to database
        if violations:
            for violation in violations:
                try:
                    # Get or create default rule for this violation type
                    rule_query = """
                        SELECT id FROM guardrail_rules
                        WHERE workspace_id = $1 AND rule_type = $2 AND is_active = true
                        LIMIT 1
                    """
                    rule_row = await pool.fetchrow(rule_query, x_workspace_id, violation.type)

                    # Create default rule if doesn't exist
                    if not rule_row:
                        rule_insert = """
                            INSERT INTO guardrail_rules
                            (id, workspace_id, rule_type, name, severity, action, is_active)
                            VALUES ($1, $2, $3, $4, $5, $6, true)
                            RETURNING id
                        """
                        rule_row = await pool.fetchrow(
                            rule_insert,
                            uuid4(),
                            x_workspace_id,
                            violation.type,
                            f"Default {violation.type} rule",
                            violation.severity,
                            "log"
                        )

                    rule_id = rule_row['id']

                    # Insert violation
                    violation_query = """
                        INSERT INTO guardrail_violations
                        (id, workspace_id, rule_id, trace_id, detected_at, violation_type,
                         severity, message, detected_content, redacted_content, metadata)
                        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
                    """

                    redacted_content = None
                    if violation.type == "pii_detection":
                        redacted_content = redact_pii(text)

                    await pool.execute(
                        violation_query,
                        uuid4(),
                        x_workspace_id,
                        rule_id,
                        request.trace_id or "unknown",
                        datetime.utcnow(),
                        violation.type,
                        violation.severity,
                        violation.message,
                        text[:1000],  # Store first 1000 chars
                        redacted_content,
                        violation.details
                    )

                except Exception as e:
                    logger.error(f"Failed to save violation: {e}")

        is_safe = len(violations) == 0

        return GuardrailCheckResponse(
            violations=violations,
            total_violations=len(violations),
            is_safe=is_safe,
            pii_detected=pii_detected,
            is_toxic=is_toxic,
            injection_detected=injection_detected
        )

    except Exception as e:
        logger.error(f"Guardrail check failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Guardrail check failed: {str(e)}"
        )


@router.post("/pii", response_model=PIIDetectionResponse)
async def detect_pii_endpoint(
    request: PIIDetectionRequest,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID")
):
    """
    Detect PII in text only

    Args:
        request: Text to check for PII
        x_workspace_id: Workspace ID from header

    Returns:
        PII detections with redacted text
    """

    try:
        text = request.text

        # Detect PII
        pii_detections = detect_pii(text)

        # Convert to response format
        detections = [
            PIIDetection(
                type=d['type'],
                value=d['value'],
                position=d['position'],
                severity=d['severity']
            )
            for d in pii_detections
        ]

        # Redact PII
        redacted_text = None
        if detections:
            redacted_text = redact_pii(text)

        return PIIDetectionResponse(
            detections=detections,
            total=len(detections),
            has_pii=len(detections) > 0,
            redacted_text=redacted_text
        )

    except Exception as e:
        logger.error(f"PII detection failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"PII detection failed: {str(e)}"
        )


@router.post("/toxicity", response_model=ToxicityResult)
async def check_toxicity_endpoint(
    request: ToxicityCheckRequest,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID")
):
    """
    Check toxicity in text only

    Args:
        request: Text to check for toxicity
        x_workspace_id: Workspace ID from header

    Returns:
        Toxicity detection result
    """

    try:
        text = request.text

        # Detect toxicity
        toxicity_result = detect_toxicity(text)

        return ToxicityResult(
            is_toxic=toxicity_result['is_toxic'],
            confidence=toxicity_result['confidence'],
            severity=toxicity_result['severity']
        )

    except Exception as e:
        logger.error(f"Toxicity check failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Toxicity check failed: {str(e)}"
        )


@router.get("/violations", response_model=ViolationSummaryResponse)
async def get_violations(
    range: str = '7d',
    limit: int = 100,
    offset: int = 0,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Get violation history with breakdowns for workspace

    Query Parameters:
        - range: Time range (1h, 24h, 7d, 30d, 90d) - default: 7d
        - limit: Maximum number of violations to return (default: 100)
        - offset: Offset for pagination (default: 0)

    Returns:
        Violations with severity/type breakdowns and trend percentage
    """

    try:
        # Check cache
        cache_key = f"violations:{x_workspace_id}:{range}:{limit}:{offset}"
        cached = await get_cache(cache_key)
        if cached:
            logger.info(f"Returning cached violations for workspace {x_workspace_id}")
            return ViolationSummaryResponse(**cached)

        # Parse time range
        time_mapping = {
            '1h': 1,
            '24h': 24,
            '7d': 24 * 7,
            '30d': 24 * 30,
            '90d': 24 * 90
        }
        hours = time_mapping.get(range, 24 * 7)

        # Query violations within time range
        query = """
            SELECT
                v.id, v.workspace_id, v.rule_id, v.trace_id, v.detected_at,
                v.violation_type, v.severity, v.message, v.detected_content,
                v.redacted_content, v.metadata
            FROM guardrail_violations v
            WHERE v.workspace_id = $1
                AND v.detected_at >= NOW() - ($2::text || ' hours')::INTERVAL
            ORDER BY v.detected_at DESC
            LIMIT $3 OFFSET $4
        """

        rows = await pool.fetch(query, x_workspace_id, str(hours), limit, offset)

        # Count total violations in time range
        count_query = """
            SELECT COUNT(*) as total
            FROM guardrail_violations
            WHERE workspace_id = $1
                AND detected_at >= NOW() - ($2::text || ' hours')::INTERVAL
        """
        total_row = await pool.fetchrow(count_query, x_workspace_id, str(hours))
        total = total_row['total'] if total_row else 0

        # Calculate severity breakdown
        severity_query = """
            SELECT
                SUM(CASE WHEN severity = 'critical' THEN 1 ELSE 0 END) as critical,
                SUM(CASE WHEN severity = 'high' THEN 1 ELSE 0 END) as high,
                SUM(CASE WHEN severity = 'medium' THEN 1 ELSE 0 END) as medium
            FROM guardrail_violations
            WHERE workspace_id = $1
                AND detected_at >= NOW() - ($2::text || ' hours')::INTERVAL
        """
        severity_row = await pool.fetchrow(severity_query, x_workspace_id, str(hours))
        severity_breakdown = SeverityBreakdown(
            critical=severity_row['critical'] if severity_row else 0,
            high=severity_row['high'] if severity_row else 0,
            medium=severity_row['medium'] if severity_row else 0
        )

        # Calculate type breakdown
        type_query = """
            SELECT
                SUM(CASE WHEN violation_type = 'pii' THEN 1 ELSE 0 END) as pii,
                SUM(CASE WHEN violation_type = 'toxicity' THEN 1 ELSE 0 END) as toxicity,
                SUM(CASE WHEN violation_type = 'injection' THEN 1 ELSE 0 END) as injection
            FROM guardrail_violations
            WHERE workspace_id = $1
                AND detected_at >= NOW() - ($2::text || ' hours')::INTERVAL
        """
        type_row = await pool.fetchrow(type_query, x_workspace_id, str(hours))
        type_breakdown = TypeBreakdown(
            pii=type_row['pii'] if type_row else 0,
            toxicity=type_row['toxicity'] if type_row else 0,
            injection=type_row['injection'] if type_row else 0
        )

        # Calculate trend percentage (compare to previous period)
        prev_count_query = """
            SELECT COUNT(*) as prev_total
            FROM guardrail_violations
            WHERE workspace_id = $1
                AND detected_at >= NOW() - (($2::text)::int * 2 || ' hours')::INTERVAL
                AND detected_at < NOW() - ($2::text || ' hours')::INTERVAL
        """
        prev_row = await pool.fetchrow(prev_count_query, x_workspace_id, str(hours))
        prev_total = prev_row['prev_total'] if prev_row else 0

        # Calculate trend percentage
        trend_percentage = 0.0
        if prev_total > 0:
            trend_percentage = ((total - prev_total) / prev_total) * 100

        # Convert to response format
        violations = [
            ViolationHistory(
                id=row['id'],
                workspace_id=row['workspace_id'],
                rule_id=row['rule_id'],
                trace_id=row['trace_id'],
                detected_at=row['detected_at'],
                violation_type=row['violation_type'],
                severity=row['severity'],
                message=row['message'],
                detected_content=row['detected_content'],
                redacted_content=row['redacted_content'],
                metadata=json.loads(row['metadata']) if isinstance(row['metadata'], str) else row['metadata']
            )
            for row in rows
        ]

        result = ViolationSummaryResponse(
            violations=violations,
            total_count=total,
            severity_breakdown=severity_breakdown,
            type_breakdown=type_breakdown,
            trend_percentage=trend_percentage
        )

        # Cache result for 10 minutes
        await set_cache(cache_key, result.model_dump(mode='json'), settings.cache_ttl_rules)

        return result

    except Exception as e:
        logger.error(f"Failed to fetch violations: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch violations: {str(e)}"
        )


@router.post("/rules", response_model=GuardrailRule)
async def create_rule(
    request: CreateRuleRequest,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Create a new guardrail rule

    Args:
        request: Rule configuration
        x_workspace_id: Workspace ID from header

    Returns:
        Created guardrail rule
    """

    try:
        # Validate rule_type
        valid_types = ["pii_detection", "toxicity", "prompt_injection", "custom"]
        if request.rule_type not in valid_types:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid rule_type. Must be one of: {valid_types}"
            )

        # Validate severity
        valid_severities = ["info", "warning", "error", "critical"]
        if request.severity not in valid_severities:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid severity. Must be one of: {valid_severities}"
            )

        # Validate action
        valid_actions = ["log", "block", "redact"]
        if request.action not in valid_actions:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid action. Must be one of: {valid_actions}"
            )

        # Insert rule
        rule_id = uuid4()
        now = datetime.utcnow()

        query = """
            INSERT INTO guardrail_rules
            (id, workspace_id, agent_id, rule_type, name, description,
             config, severity, action, is_active, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, true, $10, $10)
            RETURNING id, workspace_id, agent_id, rule_type, name, description,
                      config, severity, action, is_active, created_at, updated_at
        """

        row = await pool.fetchrow(
            query,
            rule_id,
            x_workspace_id,
            request.agent_id,
            request.rule_type,
            request.name,
            request.description,
            request.config,
            request.severity,
            request.action,
            now
        )

        if not row:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create rule"
            )

        return GuardrailRule(
            id=row['id'],
            workspace_id=row['workspace_id'],
            agent_id=row['agent_id'],
            rule_type=row['rule_type'],
            name=row['name'],
            description=row['description'],
            config=row['config'],
            severity=row['severity'],
            action=row['action'],
            is_active=row['is_active'],
            created_at=row['created_at'],
            updated_at=row['updated_at']
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create rule: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create rule: {str(e)}"
        )
