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
    GuardrailRule,
    AgentSafetyMetrics,
    TopRiskyAgentsResponse
)
from ..database import get_postgres_pool, get_timescale_pool
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
            critical=severity_row['critical'] or 0 if severity_row else 0,
            high=severity_row['high'] or 0 if severity_row else 0,
            medium=severity_row['medium'] or 0 if severity_row else 0
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
            pii=type_row['pii'] or 0 if type_row else 0,
            toxicity=type_row['toxicity'] or 0 if type_row else 0,
            injection=type_row['injection'] or 0 if type_row else 0
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


@router.get("/safety-overview")
async def get_safety_overview(
    range: str = '30d',
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Get comprehensive safety metrics for dashboard KPI cards

    Returns:
        - safety_score: 0-100 score based on violation rate
        - sla_compliance: SLA compliance metrics
        - compliance_status: Overall compliance status
        - trend_percentage: Change from previous period
    """
    try:
        # Parse time range
        time_mapping = {'1h': 1, '24h': 24, '7d': 24 * 7, '30d': 24 * 30, '90d': 24 * 90}
        hours = time_mapping.get(range, 24 * 30)

        # Get total requests from traces (TimescaleDB would be needed, using violations for now)
        total_violations_query = """
            SELECT COUNT(*) as total
            FROM guardrail_violations
            WHERE workspace_id = $1
                AND detected_at >= NOW() - ($2::text || ' hours')::INTERVAL
        """
        total_violations = await pool.fetchval(total_violations_query, x_workspace_id, str(hours)) or 0

        # Calculate safety score (100 - violation rate normalized to 0-100)
        # Assuming ~1000 total operations, violation rate of 1% = score of 99
        estimated_total_operations = max(total_violations * 10, 1000)
        violation_rate = (total_violations / estimated_total_operations) * 100
        safety_score = max(0, min(100, 100 - (violation_rate * 5)))  # Scale violation rate

        # Get previous period violations for trend
        prev_violations_query = """
            SELECT COUNT(*) as prev_total
            FROM guardrail_violations
            WHERE workspace_id = $1
                AND detected_at >= NOW() - (($2::text)::int * 2 || ' hours')::INTERVAL
                AND detected_at < NOW() - ($2::text || ' hours')::INTERVAL
        """
        prev_violations = await pool.fetchval(prev_violations_query, x_workspace_id, str(hours)) or 0

        # Calculate trend (positive = improving, negative = degrading)
        trend_percentage = 0.0
        if prev_violations > 0:
            trend_percentage = ((prev_violations - total_violations) / prev_violations) * 100

        # SLA compliance metrics (mock data for now - would need incident tracking table)
        total_incidents = total_violations
        within_sla = int(total_incidents * 0.85)  # 85% compliance
        breached_sla = total_incidents - within_sla
        compliance_rate = (within_sla / total_incidents * 100) if total_incidents > 0 else 100.0

        # Get active rules
        active_rules_query = """
            SELECT COUNT(*) as count
            FROM guardrail_rules
            WHERE workspace_id = $1 AND is_active = true
        """
        active_rules = await pool.fetchval(active_rules_query, x_workspace_id) or 0

        # Determine compliance status
        if safety_score >= 90 and active_rules >= 3:
            compliance_status = 'compliant'
        elif safety_score >= 70 and active_rules >= 2:
            compliance_status = 'partial'
        else:
            compliance_status = 'non_compliant'

        # Get enabled policy types
        enabled_policies_query = """
            SELECT DISTINCT rule_type
            FROM guardrail_rules
            WHERE workspace_id = $1 AND is_active = true
        """
        enabled_policies_rows = await pool.fetch(enabled_policies_query, x_workspace_id)
        enabled_policies = [row['rule_type'] for row in enabled_policies_rows]

        return {
            'safety_score': round(safety_score, 1),
            'safety_trend': round(trend_percentage, 1),
            'sla_compliance': {
                'compliance_rate': round(compliance_rate, 1),
                'total_incidents': total_incidents,
                'within_sla': within_sla,
                'breached_sla': breached_sla
            },
            'compliance_status': {
                'status': compliance_status,
                'active_rules': active_rules,
                'enabled_policies': enabled_policies,
                'last_audit': datetime.utcnow().isoformat()
            }
        }

    except Exception as e:
        logger.error(f"Failed to fetch safety overview: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch safety overview: {str(e)}"
        )


@router.get("/risk-heatmap")
async def get_risk_heatmap(
    time_range: str = '30d',
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pg_pool: asyncpg.Pool = Depends(get_postgres_pool),
    ts_pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get risk heatmap data showing agent × violation type distribution

    Returns grid data for heatmap visualization with cross-database join
    """
    try:
        # Parse time range
        time_mapping = {'1h': 1, '24h': 24, '7d': 24 * 7, '30d': 24 * 30, '90d': 24 * 90}
        hours = time_mapping.get(time_range, 24 * 30)

        # Step 1: Get violations from PostgreSQL
        violation_query = """
            SELECT
                trace_id,
                violation_type,
                severity,
                detected_at
            FROM guardrail_violations
            WHERE workspace_id = $1
                AND detected_at >= NOW() - INTERVAL '1 hour' * $2
        """
        violations = await pg_pool.fetch(violation_query, x_workspace_id, hours)

        if not violations:
            return {
                'cells': [],
                'agents': [],
                'violation_types': ['pii', 'toxicity', 'injection']
            }

        # Step 2: Get trace_id to agent_id mappings from TimescaleDB
        trace_ids = list(set([v['trace_id'] for v in violations]))

        # Query in batches to avoid parameter limits
        agent_mapping = {}
        batch_size = 1000
        for i in range(0, len(trace_ids), batch_size):
            batch = trace_ids[i:i+batch_size]
            trace_query = """
                SELECT DISTINCT trace_id, agent_id
                FROM traces
                WHERE trace_id = ANY($1::text[])
            """
            trace_rows = await ts_pool.fetch(trace_query, batch)
            for row in trace_rows:
                agent_mapping[row['trace_id']] = row['agent_id']

        # Step 3: Aggregate violations by agent_id and violation_type
        from collections import defaultdict
        aggregated = defaultdict(lambda: defaultdict(lambda: {'count': 0, 'severity': 'medium'}))

        severity_rank = {'critical': 3, 'high': 2, 'medium': 1, 'low': 0}

        for violation in violations:
            trace_id = violation['trace_id']
            agent_id = agent_mapping.get(trace_id)

            if not agent_id:
                continue  # Skip if we can't map to agent_id

            v_type = violation['violation_type']
            current_severity = aggregated[agent_id][v_type]['severity']

            # Increment count
            aggregated[agent_id][v_type]['count'] += 1

            # Update severity to max
            if severity_rank.get(violation['severity'], 0) > severity_rank.get(current_severity, 0):
                aggregated[agent_id][v_type]['severity'] = violation['severity']

        # Step 4: Format response
        cells = []
        for agent_id, v_types in aggregated.items():
            for v_type, data in v_types.items():
                cells.append({
                    'agent_id': agent_id,
                    'violation_type': v_type,
                    'count': data['count'],
                    'severity': data['severity']
                })

        # Sort by count and get top agents
        cells_sorted = sorted(cells, key=lambda x: x['count'], reverse=True)

        # Get unique agents (top by total violation count)
        agent_totals = defaultdict(int)
        for cell in cells:
            agent_totals[cell['agent_id']] += cell['count']

        top_agents = sorted(agent_totals.items(), key=lambda x: x[1], reverse=True)[:15]
        top_agent_ids = [agent_id for agent_id, _ in top_agents]

        # Filter cells to only include top agents
        filtered_cells = [cell for cell in cells if cell['agent_id'] in top_agent_ids]

        return {
            'cells': filtered_cells,
            'agents': top_agent_ids,
            'violation_types': ['pii', 'toxicity', 'injection']
        }

    except Exception as e:
        import traceback
        logger.error(f"Failed to fetch risk heatmap: {e}\n{traceback.format_exc()}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch risk heatmap: {e}"
        )


@router.get("/pii-breakdown")
async def get_pii_breakdown(
    range: str = '30d',
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Get PII type breakdown showing distribution of email, phone, SSN, IP, etc.

    Returns breakdown of PII violation types
    """
    try:
        # Parse time range
        time_mapping = {'1h': 1, '24h': 24, '7d': 24 * 7, '30d': 24 * 30, '90d': 24 * 90}
        hours = time_mapping.get(range, 24 * 30)

        # Get PII violations and extract pattern types from metadata
        query = """
            SELECT
                metadata->>'pattern_type' as pii_type,
                COUNT(*) as count
            FROM guardrail_violations
            WHERE workspace_id = $1
                AND detected_at >= NOW() - ($2::text || ' hours')::INTERVAL
                AND violation_type = 'pii'
                AND metadata IS NOT NULL
                AND metadata->>'pattern_type' IS NOT NULL
            GROUP BY metadata->>'pattern_type'
            ORDER BY count DESC
        """

        rows = await pool.fetch(query, x_workspace_id, str(hours))

        # Calculate total and percentages
        total_pii = sum(row['count'] for row in rows)

        breakdown = [
            {
                'type': row['pii_type'],
                'count': row['count'],
                'percentage': (row['count'] / total_pii * 100) if total_pii > 0 else 0
            }
            for row in rows
        ]

        return {
            'breakdown': breakdown,
            'total_pii_violations': total_pii
        }

    except Exception as e:
        logger.error(f"Failed to fetch PII breakdown: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch PII breakdown: {str(e)}"
        )


@router.get("/agents", response_model=TopRiskyAgentsResponse)
async def get_top_risky_agents(
    time_range: str = '30d',
    limit: int = 20,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pg_pool: asyncpg.Pool = Depends(get_postgres_pool),
    ts_pool: asyncpg.Pool = Depends(get_timescale_pool)
):
    """
    Get top risky agents ranked by safety violations

    Returns agents with highest violation counts, severity breakdown,
    risk scores, and trends. Uses cross-database join to map trace_id to agent_id.
    """
    try:
        # Parse time range
        time_mapping = {'1h': 1, '24h': 24, '7d': 24 * 7, '30d': 24 * 30, '90d': 24 * 90}
        hours = time_mapping.get(time_range, 24 * 30)

        # Step 1: Get all violations from PostgreSQL
        violation_query = """
            SELECT
                trace_id,
                violation_type,
                severity,
                detected_at
            FROM guardrail_violations
            WHERE workspace_id = $1
                AND detected_at >= NOW() - INTERVAL '1 hour' * $2
        """
        violations = await pg_pool.fetch(violation_query, x_workspace_id, hours)

        if not violations:
            return TopRiskyAgentsResponse(agents=[], total_agents=0)

        # Step 2: Get trace_id to agent_id mappings from TimescaleDB
        trace_ids = list(set([v['trace_id'] for v in violations]))

        agent_mapping = {}
        batch_size = 1000
        for i in range(0, len(trace_ids), batch_size):
            batch = trace_ids[i:i+batch_size]
            trace_query = """
                SELECT DISTINCT trace_id, agent_id
                FROM traces
                WHERE trace_id = ANY($1::text[])
            """
            trace_rows = await ts_pool.fetch(trace_query, batch)
            for row in trace_rows:
                agent_mapping[row['trace_id']] = row['agent_id']

        # Step 3: Aggregate violations by agent_id
        from collections import defaultdict
        agent_data = defaultdict(lambda: {
            'total_violations': 0,
            'critical_count': 0,
            'high_count': 0,
            'medium_count': 0,
            'pii_count': 0,
            'toxicity_count': 0,
            'injection_count': 0,
            'violations': []
        })

        for violation in violations:
            trace_id = violation['trace_id']
            agent_id = agent_mapping.get(trace_id)

            if not agent_id:
                continue

            agent = agent_data[agent_id]
            agent['total_violations'] += 1
            agent['violations'].append(violation)

            # Count by severity
            if violation['severity'] == 'critical':
                agent['critical_count'] += 1
            elif violation['severity'] == 'high':
                agent['high_count'] += 1
            elif violation['severity'] == 'medium':
                agent['medium_count'] += 1

            # Count by type
            if violation['violation_type'] == 'pii':
                agent['pii_count'] += 1
            elif violation['violation_type'] == 'toxicity':
                agent['toxicity_count'] += 1
            elif violation['violation_type'] == 'injection':
                agent['injection_count'] += 1

        # Step 4: Calculate risk scores and trends
        agents_list = []
        for agent_id, data in agent_data.items():
            # Calculate risk score (0-100)
            # Weight: critical=10, high=5, medium=2
            weighted_score = (
                data['critical_count'] * 10 +
                data['high_count'] * 5 +
                data['medium_count'] * 2
            )
            risk_score = min(100.0, (weighted_score / max(1, data['total_violations'])) * 10)

            # Calculate trend (recent vs older)
            sorted_violations = sorted(data['violations'], key=lambda v: v['detected_at'])
            if len(sorted_violations) >= 2:
                midpoint = len(sorted_violations) // 2
                older_violations = sorted_violations[:midpoint]
                recent_violations = sorted_violations[midpoint:]

                older_rate = len(older_violations) / max(1, hours / 2)
                recent_rate = len(recent_violations) / max(1, hours / 2)

                if recent_rate < older_rate * 0.8:
                    trend = "improving"
                elif recent_rate > older_rate * 1.2:
                    trend = "degrading"
                else:
                    trend = "stable"
            else:
                trend = "stable"

            # Last violation timestamp
            last_violation = max(v['detected_at'] for v in data['violations']) if data['violations'] else None

            agents_list.append({
                'agent_id': agent_id,
                'total_violations': data['total_violations'],
                'critical_count': data['critical_count'],
                'high_count': data['high_count'],
                'medium_count': data['medium_count'],
                'pii_count': data['pii_count'],
                'toxicity_count': data['toxicity_count'],
                'injection_count': data['injection_count'],
                'risk_score': risk_score,
                'recent_trend': trend,
                'last_violation': last_violation
            })

        # Step 5: Sort by risk score and limit
        agents_list.sort(key=lambda x: (-x['risk_score'], -x['total_violations']))
        top_agents = agents_list[:limit]

        # Convert to response models
        agent_metrics = [AgentSafetyMetrics(**agent) for agent in top_agents]

        return TopRiskyAgentsResponse(
            agents=agent_metrics,
            total_agents=len(agents_list)
        )

    except Exception as e:
        import traceback
        logger.error(f"Failed to fetch top risky agents: {e}\n{traceback.format_exc()}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch top risky agents: {e}"
        )
