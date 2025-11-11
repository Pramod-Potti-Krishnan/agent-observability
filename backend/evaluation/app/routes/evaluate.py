"""Evaluation routes"""
from fastapi import APIRouter, HTTPException, status, Header, Depends
from typing import Optional
import asyncpg
import json
import redis.asyncio as redis
import logging
from uuid import UUID

from ..models import (
    EvaluationRequest,
    BatchEvaluationRequest,
    EvaluationResult,
    BatchEvaluationResult,
    EvaluationHistory,
    CreateCriteriaRequest,
    CriteriaResponse,
    EvaluationCriteria,
    AgentEvaluationRequest
)
from ..database import (
    get_postgres_pool,
    get_trace_by_id,
    save_evaluation,
    get_evaluation_history,
    get_evaluation_stats
)
from ..gemini_client import evaluate_with_gemini, batch_evaluate_with_gemini
from ..config import get_settings

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/evaluate", tags=["evaluation"])
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


@router.post("/trace/{trace_id}", response_model=EvaluationResult)
async def evaluate_trace(
    trace_id: str,
    request: Optional[EvaluationRequest] = None,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Evaluate a single trace using Gemini LLM-as-a-judge

    Args:
        trace_id: Trace ID to evaluate
        request: Optional evaluation parameters
        x_workspace_id: Workspace ID from header

    Returns:
        Evaluation result with scores and reasoning
    """

    try:
        # Check cache first
        cache_key = f"evaluation:{x_workspace_id}:{trace_id}"
        cached = await get_cache(cache_key)
        if cached:
            logger.info(f"Returning cached evaluation for trace {trace_id}")
            return EvaluationResult(**cached)

        # Get trace data
        trace = await get_trace_by_id(pool, x_workspace_id, trace_id)
        if not trace:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Trace {trace_id} not found in workspace"
            )

        # Check if trace has output (can't evaluate failed traces)
        if not trace.get('output') or trace.get('status') != 'success':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot evaluate trace without successful output"
            )

        # Extract custom criteria if provided
        custom_criteria = None
        if request and request.custom_criteria:
            custom_criteria = request.custom_criteria

        # Call Gemini for evaluation
        logger.info(f"Evaluating trace {trace_id} with Gemini")
        evaluation = await evaluate_with_gemini(
            trace['input'],
            trace['output'],
            custom_criteria
        )

        # Save evaluation to database with agent_id from trace
        evaluation_id = await save_evaluation(
            pool,
            x_workspace_id,
            trace_id,
            'gemini',
            {
                'accuracy_score': evaluation['accuracy_score'],
                'relevance_score': evaluation['relevance_score'],
                'helpfulness_score': evaluation['helpfulness_score'],
                'coherence_score': evaluation['coherence_score'],
                'overall_score': evaluation['overall_score']
            },
            evaluation['reasoning'],
            {
                'model': settings.gemini_model,
                'has_custom_criteria': custom_criteria is not None
            },
            agent_id=trace.get('agent_id')  # Pass agent_id from trace
        )

        # Fetch saved evaluation
        query = """
            SELECT
                id, workspace_id, trace_id, created_at, evaluator,
                accuracy_score, relevance_score, helpfulness_score,
                coherence_score, overall_score, reasoning, metadata
            FROM evaluations
            WHERE id = $1
        """
        row = await pool.fetchrow(query, UUID(evaluation_id))

        result = EvaluationResult(
            id=row['id'],
            workspace_id=row['workspace_id'],
            trace_id=row['trace_id'],
            created_at=row['created_at'],
            evaluator=row['evaluator'],
            accuracy_score=float(row['accuracy_score']),
            relevance_score=float(row['relevance_score']),
            helpfulness_score=float(row['helpfulness_score']),
            coherence_score=float(row['coherence_score']),
            overall_score=float(row['overall_score']),
            reasoning=row['reasoning'],
            metadata=json.loads(row['metadata']) if isinstance(row['metadata'], str) else row['metadata']
        )

        # Cache result
        await set_cache(cache_key, result.model_dump(mode='json'), settings.cache_ttl_evaluations)

        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to evaluate trace {trace_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Evaluation failed: {str(e)}"
        )


@router.post("/batch", response_model=BatchEvaluationResult)
async def evaluate_batch(
    request: BatchEvaluationRequest,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Batch evaluate multiple traces

    Args:
        request: Batch evaluation request with trace IDs
        x_workspace_id: Workspace ID from header

    Returns:
        Batch evaluation results
    """

    try:
        trace_ids = request.trace_ids

        if len(trace_ids) > settings.max_batch_size:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Batch size exceeds maximum of {settings.max_batch_size}"
            )

        # Fetch all traces with agent_id
        query = """
            SELECT trace_id, agent_id, input, output, status
            FROM traces
            WHERE workspace_id = $1 AND trace_id = ANY($2) AND status = 'success'
        """
        rows = await pool.fetch(query, x_workspace_id, trace_ids)

        traces = [
            {
                'trace_id': row['trace_id'],
                'agent_id': row['agent_id'],
                'input': row['input'],
                'output': row['output']
            }
            for row in rows
        ]

        if not traces:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No valid traces found for evaluation"
            )

        # Batch evaluate with Gemini
        logger.info(f"Batch evaluating {len(traces)} traces")
        evaluations = await batch_evaluate_with_gemini(traces, request.custom_criteria)

        # Save successful evaluations
        results = []
        successful = 0
        failed = 0

        # Create a trace_id to agent_id mapping for quick lookup
        trace_agent_map = {t['trace_id']: t.get('agent_id') for t in traces}

        for eval_data in evaluations:
            if eval_data.get('success'):
                try:
                    # Get agent_id for this trace
                    trace_id = eval_data['trace_id']
                    agent_id = trace_agent_map.get(trace_id)

                    eval_id = await save_evaluation(
                        pool,
                        x_workspace_id,
                        trace_id,
                        'gemini',
                        {
                            'accuracy_score': eval_data['accuracy_score'],
                            'relevance_score': eval_data['relevance_score'],
                            'helpfulness_score': eval_data['helpfulness_score'],
                            'coherence_score': eval_data['coherence_score'],
                            'overall_score': eval_data['overall_score']
                        },
                        eval_data['reasoning'],
                        {'model': settings.gemini_model, 'batch': True},
                        agent_id=agent_id  # Pass agent_id from trace
                    )

                    # Fetch saved evaluation
                    query = """
                        SELECT
                            id, workspace_id, trace_id, created_at, evaluator,
                            accuracy_score, relevance_score, helpfulness_score,
                            coherence_score, overall_score, reasoning, metadata
                        FROM evaluations
                        WHERE id = $1
                    """
                    row = await pool.fetchrow(query, UUID(eval_id))

                    results.append(EvaluationResult(
                        id=row['id'],
                        workspace_id=row['workspace_id'],
                        trace_id=row['trace_id'],
                        created_at=row['created_at'],
                        evaluator=row['evaluator'],
                        accuracy_score=float(row['accuracy_score']),
                        relevance_score=float(row['relevance_score']),
                        helpfulness_score=float(row['helpfulness_score']),
                        coherence_score=float(row['coherence_score']),
                        overall_score=float(row['overall_score']),
                        reasoning=row['reasoning'],
                        metadata=json.loads(row['metadata']) if isinstance(row['metadata'], str) else row['metadata']
                    ))

                    successful += 1

                except Exception as e:
                    logger.error(f"Failed to save evaluation for {eval_data['trace_id']}: {e}")
                    failed += 1
            else:
                failed += 1

        return BatchEvaluationResult(
            evaluations=results,
            total=len(trace_ids),
            successful=successful,
            failed=failed
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Batch evaluation failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Batch evaluation failed: {str(e)}"
        )


@router.get("/history", response_model=EvaluationHistory)
async def get_history(
    range: str = "7d",
    limit: int = 100,
    offset: int = 0,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Get evaluation history for workspace

    Query Parameters:
        - range: Time range (24h, 7d, 30d) - Default: 7d
        - limit: Maximum number of evaluations to return - Default: 100
        - offset: Offset for pagination - Default: 0

    Returns:
        Evaluation history with statistics
    """

    try:
        # Check cache
        cache_key = f"eval_history:{x_workspace_id}:{range}:{limit}:{offset}"
        cached = await get_cache(cache_key)
        if cached:
            return EvaluationHistory(**cached)

        # Get evaluations
        evaluations_data = await get_evaluation_history(pool, x_workspace_id, limit, offset)

        # Get statistics
        stats = await get_evaluation_stats(pool, x_workspace_id)

        evaluations = [
            EvaluationResult(
                id=eval_data['id'],
                workspace_id=eval_data['workspace_id'],
                trace_id=eval_data['trace_id'],
                created_at=eval_data['created_at'],
                evaluator=eval_data['evaluator'],
                accuracy_score=float(eval_data['accuracy_score']),
                relevance_score=float(eval_data['relevance_score']),
                helpfulness_score=float(eval_data['helpfulness_score']),
                coherence_score=float(eval_data['coherence_score']),
                overall_score=float(eval_data['overall_score']),
                reasoning=eval_data['reasoning'],
                metadata=json.loads(eval_data['metadata']) if isinstance(eval_data['metadata'], str) else eval_data['metadata']
            )
            for eval_data in evaluations_data
        ]

        result = EvaluationHistory(
            evaluations=evaluations,
            total=stats['total'],
            avg_overall_score=stats['avg_overall_score'],
            avg_accuracy_score=stats['avg_accuracy_score'],
            avg_relevance_score=stats['avg_relevance_score'],
            avg_helpfulness_score=stats['avg_helpfulness_score'],
            avg_coherence_score=stats['avg_coherence_score']
        )

        # Cache result
        await set_cache(cache_key, result.model_dump(mode='json'), settings.cache_ttl_evaluations)

        return result

    except Exception as e:
        logger.error(f"Failed to fetch evaluation history: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch history: {str(e)}"
        )


@router.post("/custom-criteria", response_model=dict)
async def create_custom_criteria(
    request: CreateCriteriaRequest,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID")
):
    """
    Create custom evaluation criteria (stored in Redis for session)

    Note: This is a simplified implementation. In production, you might want to
    store criteria in PostgreSQL for persistence.
    """

    try:
        # Store in Redis with workspace prefix
        cache_key = f"custom_criteria:{x_workspace_id}"

        # Get existing criteria
        client = await get_redis_client()
        existing = await client.get(cache_key)
        criteria_list = json.loads(existing) if existing else []

        # Add new criterion
        new_criterion = {
            'name': request.name,
            'description': request.description,
            'weight': request.weight
        }
        criteria_list.append(new_criterion)

        # Save back
        await client.setex(cache_key, 86400, json.dumps(criteria_list))  # 24 hour TTL

        return {
            "message": "Custom criterion created successfully",
            "criterion": new_criterion
        }

    except Exception as e:
        logger.error(f"Failed to create custom criterion: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create criterion: {str(e)}"
        )


@router.get("/criteria", response_model=CriteriaResponse)
async def list_criteria(
    x_workspace_id: str = Header(..., alias="X-Workspace-ID")
):
    """
    List all evaluation criteria (standard + custom)
    """

    try:
        # Standard criteria (always available)
        standard_criteria = [
            EvaluationCriteria(
                name="Accuracy",
                description="Does the response correctly address the input? Is information factually correct?",
                weight=1.0
            ),
            EvaluationCriteria(
                name="Relevance",
                description="Is the response relevant to the user's query? Does it stay on topic?",
                weight=1.0
            ),
            EvaluationCriteria(
                name="Helpfulness",
                description="Is the response useful and actionable? Does it solve the user's problem?",
                weight=1.0
            ),
            EvaluationCriteria(
                name="Coherence",
                description="Is the response well-structured and easy to understand?",
                weight=1.0
            )
        ]

        # Get custom criteria from Redis
        client = await get_redis_client()
        cache_key = f"custom_criteria:{x_workspace_id}"
        existing = await client.get(cache_key)

        custom_criteria = []
        if existing:
            criteria_data = json.loads(existing)
            custom_criteria = [EvaluationCriteria(**c) for c in criteria_data]

        all_criteria = standard_criteria + custom_criteria

        return CriteriaResponse(
            criteria=all_criteria,
            total=len(all_criteria)
        )

    except Exception as e:
        logger.error(f"Failed to list criteria: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list criteria: {str(e)}"
        )


@router.post("/agent/{agent_id}", response_model=BatchEvaluationResult)
async def evaluate_agent(
    agent_id: str,
    request: AgentEvaluationRequest,
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Evaluate traces for a specific agent

    Supports two modes:
    - manual: Evaluate specific trace_ids provided in request
    - auto: Evaluate N most recent un-evaluated traces for this agent

    Args:
        agent_id: Agent ID to evaluate traces for
        request: Evaluation request with mode and parameters
        x_workspace_id: Workspace ID from header

    Returns:
        Batch evaluation results
    """

    try:
        workspace_uuid = UUID(x_workspace_id)
        trace_ids = []

        # Mode: Manual - use provided trace IDs
        if request.mode == 'manual':
            if not request.trace_ids or len(request.trace_ids) == 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Manual mode requires trace_ids to be provided"
                )
            trace_ids = request.trace_ids

        # Mode: Auto - fetch recent un-evaluated traces
        elif request.mode == 'auto':
            count = request.count or 10

            # Query to get recent un-evaluated traces for this agent
            # A trace is "un-evaluated" if it doesn't have a corresponding evaluation record
            query = """
                SELECT t.trace_id, t.input, t.output, t.status, t.created_at
                FROM traces t
                LEFT JOIN evaluations e ON t.trace_id = e.trace_id AND e.workspace_id = $1
                WHERE t.workspace_id = $1
                    AND t.agent_id = $2
                    AND t.status = 'success'
                    AND t.output IS NOT NULL
                    AND e.id IS NULL
                ORDER BY t.created_at DESC
                LIMIT $3
            """

            rows = await pool.fetch(query, workspace_uuid, agent_id, count)

            if not rows:
                # No un-evaluated traces found - return empty result
                return BatchEvaluationResult(
                    evaluations=[],
                    total=0,
                    successful=0,
                    failed=0
                )

            trace_ids = [row['trace_id'] for row in rows]
            logger.info(f"Auto mode: Found {len(trace_ids)} un-evaluated traces for agent {agent_id}")

        # Validate we have traces to evaluate
        if not trace_ids:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No traces to evaluate"
            )

        if len(trace_ids) > settings.max_batch_size:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Too many traces. Maximum batch size is {settings.max_batch_size}"
            )

        # Fetch trace data with agent_id
        query = """
            SELECT trace_id, input, output, status, agent_id
            FROM traces
            WHERE workspace_id = $1 AND trace_id = ANY($2) AND status = 'success' AND agent_id = $3
        """
        rows = await pool.fetch(query, workspace_uuid, trace_ids, agent_id)

        traces = [
            {
                'trace_id': row['trace_id'],
                'agent_id': row['agent_id'],
                'input': row['input'],
                'output': row['output']
            }
            for row in rows
        ]

        if not traces:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"No valid traces found for agent {agent_id}"
            )

        # Batch evaluate with Gemini
        logger.info(f"Evaluating {len(traces)} traces for agent {agent_id}")
        evaluations = await batch_evaluate_with_gemini(traces, request.custom_criteria)

        # Save successful evaluations
        results = []
        successful = 0
        failed = 0

        for eval_data in evaluations:
            if eval_data.get('success'):
                try:
                    eval_id = await save_evaluation(
                        pool,
                        x_workspace_id,
                        eval_data['trace_id'],
                        'gemini',
                        {
                            'accuracy_score': eval_data['accuracy_score'],
                            'relevance_score': eval_data['relevance_score'],
                            'helpfulness_score': eval_data['helpfulness_score'],
                            'coherence_score': eval_data['coherence_score'],
                            'overall_score': eval_data['overall_score']
                        },
                        eval_data['reasoning'],
                        {
                            'model': settings.gemini_model,
                            'batch': True,
                            'agent_id': agent_id,
                            'mode': request.mode,
                            'has_custom_criteria': request.custom_criteria is not None
                        },
                        agent_id=agent_id  # Pass agent_id directly
                    )

                    # Fetch saved evaluation
                    query = """
                        SELECT
                            id, workspace_id, trace_id, created_at, evaluator,
                            accuracy_score, relevance_score, helpfulness_score,
                            coherence_score, overall_score, reasoning, metadata
                        FROM evaluations
                        WHERE id = $1
                    """
                    row = await pool.fetchrow(query, UUID(eval_id))

                    results.append(EvaluationResult(
                        id=row['id'],
                        workspace_id=row['workspace_id'],
                        trace_id=row['trace_id'],
                        created_at=row['created_at'],
                        evaluator=row['evaluator'],
                        accuracy_score=float(row['accuracy_score']),
                        relevance_score=float(row['relevance_score']),
                        helpfulness_score=float(row['helpfulness_score']),
                        coherence_score=float(row['coherence_score']),
                        overall_score=float(row['overall_score']),
                        reasoning=row['reasoning'],
                        metadata=json.loads(row['metadata']) if isinstance(row['metadata'], str) else row['metadata']
                    ))

                    successful += 1

                except Exception as e:
                    logger.error(f"Failed to save evaluation for {eval_data['trace_id']}: {e}")
                    failed += 1
            else:
                failed += 1

        logger.info(f"Agent evaluation complete: {successful} successful, {failed} failed")

        return BatchEvaluationResult(
            evaluations=results,
            total=len(trace_ids),
            successful=successful,
            failed=failed
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Agent evaluation failed for {agent_id}: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Agent evaluation failed: {str(e)}"
        )
