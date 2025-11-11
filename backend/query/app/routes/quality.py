"""Quality Monitoring endpoints"""
from fastapi import APIRouter, HTTPException, status, Depends, Header, Query as QueryParam
from typing import Optional, List, Literal
import asyncpg
from datetime import datetime, timedelta
from ..models import (
    QualityOverview, QualityTierDistribution,
    QualityDistribution, QualityDistributionItem,
    TopFailingAgents, TopFailingAgentItem,
    QualityCostTradeoff, QualityCostTradeoffItem,
    RubricHeatmap, RubricHeatmapItem,
    DriftTimeline, DriftTimelineItem,
    AgentQualityDetails, AgentCriteriaBreakdown, AgentEvaluationItem,
    UnevaluatedTracesResponse, UnevaluatedTraceItem
)
from ..database import get_timescale_pool, get_postgres_pool
from ..cache import get_cache, set_cache
from ..config import get_settings
import logging
from uuid import UUID

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/quality", tags=["quality"])
settings = get_settings()


def parse_time_range(range_str: str) -> int:
    """Convert range string to hours"""
    range_map = {
        "1h": 1,
        "24h": 24,
        "7d": 168,
        "30d": 720,
    }
    return range_map.get(range_str, 168)


def parse_granularity(granularity: str) -> str:
    """Convert granularity to TimescaleDB interval"""
    granularity_map = {
        "hourly": "1 hour",
        "daily": "1 day",
        "weekly": "1 week",
    }
    return granularity_map.get(granularity, "1 hour")


def classify_quality_tier(score: float) -> str:
    """Classify score into quality tier"""
    if score >= 9.0:
        return "excellent"
    elif score >= 7.0:
        return "good"
    elif score >= 5.0:
        return "fair"
    elif score >= 3.0:
        return "poor"
    else:
        return "failing"


def classify_cost_quality_quadrant(quality: float, cost: float, avg_quality: float, avg_cost: float) -> str:
    """Classify into cost/quality quadrant"""
    if quality >= avg_quality and cost < avg_cost:
        return "high_quality_low_cost"
    elif quality >= avg_quality and cost >= avg_cost:
        return "high_quality_high_cost"
    elif quality < avg_quality and cost < avg_cost:
        return "low_quality_low_cost"
    else:
        return "low_quality_high_cost"


@router.get("/overview", response_model=QualityOverview)
async def get_quality_overview(
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool),
    postgres_pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Get quality overview metrics with distribution

    Returns average score, median, distribution across tiers,
    drift indicator, and at-risk agents count.
    """
    cache_key = f"quality_overview:{x_workspace_id}:{range}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return QualityOverview(**cached)

    try:
        workspace_uuid = UUID(x_workspace_id)
        hours = parse_time_range(range)

        # Get current period quality metrics
        current_query = """
            SELECT
                COALESCE(AVG(overall_score), 0) as avg_score,
                COALESCE(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY overall_score), 0) as median_score,
                COUNT(*)::int as total_evals,
                COUNT(DISTINCT CASE WHEN overall_score >= 9.0 THEN 1 END)::int as excellent,
                COUNT(DISTINCT CASE WHEN overall_score >= 7.0 AND overall_score < 9.0 THEN 1 END)::int as good,
                COUNT(DISTINCT CASE WHEN overall_score >= 5.0 AND overall_score < 7.0 THEN 1 END)::int as fair,
                COUNT(DISTINCT CASE WHEN overall_score >= 3.0 AND overall_score < 5.0 THEN 1 END)::int as poor,
                COUNT(DISTINCT CASE WHEN overall_score < 3.0 THEN 1 END)::int as failing
            FROM evaluations
            WHERE workspace_id = $1
                AND created_at >= NOW() - INTERVAL '1 hour' * $2
                AND overall_score IS NOT NULL
        """

        # Get previous period for drift calculation
        previous_query = """
            SELECT
                COALESCE(AVG(overall_score), 0) as prev_avg_score
            FROM evaluations
            WHERE workspace_id = $1
                AND created_at >= NOW() - INTERVAL '1 hour' * $2
                AND created_at < NOW() - INTERVAL '1 hour' * $3
                AND overall_score IS NOT NULL
        """

        # Get at-risk agents (below quality threshold of 5.0)
        # Now using agent_id directly from evaluations table
        at_risk_query = """
            SELECT COUNT(DISTINCT agent_id)::int as at_risk_count
            FROM (
                SELECT
                    agent_id,
                    AVG(overall_score) as avg_score
                FROM evaluations
                WHERE workspace_id = $1
                    AND created_at >= NOW() - INTERVAL '1 hour' * $2
                    AND overall_score IS NOT NULL
                    AND agent_id IS NOT NULL
                GROUP BY agent_id
                HAVING AVG(overall_score) < 5.0
            ) subq
        """

        current = await postgres_pool.fetchrow(current_query, workspace_uuid, hours)
        previous = await postgres_pool.fetchrow(previous_query, workspace_uuid, hours * 2, hours)
        at_risk = await postgres_pool.fetchrow(at_risk_query, workspace_uuid, hours)

        avg_score = float(current['avg_score'] or 0)
        median_score = float(current['median_score'] or 0)
        prev_avg = float(previous['prev_avg_score'] or 0)

        # Calculate drift indicator
        drift_indicator = 0.0
        if prev_avg > 0:
            drift_indicator = ((avg_score - prev_avg) / prev_avg) * 100

        distribution = QualityTierDistribution(
            excellent=current['excellent'] or 0,
            good=current['good'] or 0,
            fair=current['fair'] or 0,
            poor=current['poor'] or 0,
            failing=current['failing'] or 0
        )

        result = QualityOverview(
            avg_score=avg_score,
            median_score=median_score,
            total_evaluations=current['total_evals'] or 0,
            distribution=distribution,
            drift_indicator=drift_indicator,
            at_risk_agents=at_risk['at_risk_count'] or 0,
            range=range
        )

        set_cache(cache_key, result.dict(), ttl=600)  # 10 min cache
        return result

    except Exception as e:
        logger.error(f"Error fetching quality overview: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch quality overview: {str(e)}"
        )


@router.get("/distribution", response_model=QualityDistribution)
async def get_quality_distribution(
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool),
    postgres_pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Get quality score distribution with cost breakdown

    Returns distribution of evaluations across score ranges
    with average cost per range.
    """
    cache_key = f"quality_distribution:{x_workspace_id}:{range}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return QualityDistribution(**cached)

    try:
        workspace_uuid = UUID(x_workspace_id)
        hours = parse_time_range(range)

        # Get distribution from evaluations only
        # Cost data omitted for now to avoid cross-database joins
        eval_query = """
            SELECT
                CASE
                    WHEN overall_score >= 9.0 THEN '9.0-10.0'
                    WHEN overall_score >= 7.0 THEN '7.0-8.9'
                    WHEN overall_score >= 5.0 THEN '5.0-6.9'
                    WHEN overall_score >= 3.0 THEN '3.0-4.9'
                    ELSE '0.0-2.9'
                END as score_range,
                COUNT(*)::int as count
            FROM evaluations
            WHERE workspace_id = $1
                AND created_at >= NOW() - INTERVAL '1 hour' * $2
                AND overall_score IS NOT NULL
            GROUP BY score_range
            ORDER BY score_range DESC
        """

        rows = await postgres_pool.fetch(eval_query, workspace_uuid, hours)
        total = sum(row['count'] for row in rows) or 1

        items = [
            QualityDistributionItem(
                score_range=row['score_range'],
                count=row['count'],
                percentage=(row['count'] / total) * 100,
                avg_cost_usd=0.0  # Cost data omitted for now
            )
            for row in rows
        ]

        result = QualityDistribution(
            data=items,
            total_evaluations=total
        )

        set_cache(cache_key, result.dict(), ttl=300)  # 5 min cache
        return result

    except Exception as e:
        logger.error(f"Error fetching quality distribution: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch quality distribution: {str(e)}"
        )


@router.get("/agents", response_model=TopFailingAgents)
async def get_top_failing_agents(
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    limit: int = QueryParam(20, ge=5, le=100),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool),
    postgres_pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Get top failing agents ranked by quality issues

    Returns agents with lowest average scores, failing rates,
    trends, and cost impact.
    """
    cache_key = f"quality_agents:{x_workspace_id}:{range}:{limit}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return TopFailingAgents(**cached)

    try:
        workspace_uuid = UUID(x_workspace_id)
        hours = parse_time_range(range)

        # Get agents with quality metrics from evaluations
        # Cost data omitted to avoid cross-database joins
        query = """
            WITH agent_metrics AS (
                SELECT
                    agent_id,
                    COALESCE(AVG(overall_score), 0) as avg_score,
                    COUNT(*)::int as eval_count,
                    (COUNT(CASE WHEN overall_score < 5.0 THEN 1 END)::float / NULLIF(COUNT(*), 0) * 100) as failing_rate,
                    MAX(CASE WHEN overall_score < 5.0 THEN created_at END) as last_failure,
                    -- Recent vs older average for trend
                    AVG(CASE WHEN created_at >= NOW() - INTERVAL '1 hour' * ($2 / 2) THEN overall_score END) as recent_avg,
                    AVG(CASE WHEN created_at < NOW() - INTERVAL '1 hour' * ($2 / 2) THEN overall_score END) as older_avg
                FROM evaluations
                WHERE workspace_id = $1
                    AND created_at >= NOW() - INTERVAL '1 hour' * $2
                    AND overall_score IS NOT NULL
                    AND agent_id IS NOT NULL
                GROUP BY agent_id
            )
            SELECT
                agent_id,
                avg_score,
                eval_count,
                failing_rate,
                last_failure,
                CASE
                    WHEN recent_avg > older_avg + 0.5 THEN 'improving'
                    WHEN recent_avg < older_avg - 0.5 THEN 'degrading'
                    ELSE 'stable'
                END as trend
            FROM agent_metrics
            WHERE failing_rate > 0
            ORDER BY failing_rate DESC, avg_score ASC
            LIMIT $3
        """

        rows = await postgres_pool.fetch(query, workspace_uuid, hours, limit)

        items = [
            TopFailingAgentItem(
                agent_id=row['agent_id'],
                avg_score=float(row['avg_score'] or 0),
                evaluation_count=row['eval_count'],
                failing_rate=float(row['failing_rate'] or 0),
                recent_trend=row['trend'],
                cost_impact_usd=0.0,  # Cost data omitted for now
                last_failure=row['last_failure']
            )
            for row in rows
        ]

        # Get total failing agents count
        count_query = """
            SELECT COUNT(DISTINCT agent_id)::int as total
            FROM evaluations
            WHERE workspace_id = $1
                AND created_at >= NOW() - INTERVAL '1 hour' * $2
                AND overall_score < 5.0
                AND agent_id IS NOT NULL
        """
        total_row = await postgres_pool.fetchrow(count_query, workspace_uuid, hours)

        result = TopFailingAgents(
            data=items,
            total_failing_agents=total_row['total'] or 0
        )

        set_cache(cache_key, result.dict(), ttl=300)  # 5 min cache
        return result

    except Exception as e:
        logger.error(f"Error fetching top failing agents: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch top failing agents: {str(e)}"
        )


@router.get("/cost-tradeoff", response_model=QualityCostTradeoff)
async def get_quality_cost_tradeoff(
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool),
    postgres_pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Get quality vs cost tradeoff analysis

    Returns agents plotted by quality score and cost per request,
    categorized into quadrants for optimization insights.
    """
    cache_key = f"quality_cost_tradeoff:{x_workspace_id}:{range}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return QualityCostTradeoff(**cached)

    try:
        workspace_uuid = UUID(x_workspace_id)
        hours = parse_time_range(range)

        # Get quality metrics from evaluations
        quality_query = """
            SELECT
                agent_id,
                COALESCE(AVG(overall_score), 0) as avg_quality,
                COUNT(*)::int as eval_count
            FROM evaluations
            WHERE workspace_id = $1
                AND created_at >= NOW() - INTERVAL '1 hour' * $2
                AND overall_score IS NOT NULL
                AND agent_id IS NOT NULL
            GROUP BY agent_id
            HAVING COUNT(*) >= 5
        """

        # Get cost metrics from traces
        cost_query = """
            SELECT
                agent_id,
                COALESCE(AVG(cost_usd), 0) as avg_cost,
                COUNT(*)::int as trace_count
            FROM traces
            WHERE workspace_id = $1
                AND timestamp >= NOW() - INTERVAL '1 hour' * $2
                AND cost_usd IS NOT NULL
            GROUP BY agent_id
        """

        quality_rows = await postgres_pool.fetch(quality_query, workspace_uuid, hours)
        cost_rows = await timescale_pool.fetch(cost_query, workspace_uuid, hours)

        # Join in Python by agent_id
        cost_map = {row['agent_id']: float(row['avg_cost'] or 0) for row in cost_rows}

        # Combine quality and cost data
        rows = []
        for q_row in quality_rows:
            agent_id = q_row['agent_id']
            avg_cost = cost_map.get(agent_id, 0.0)
            if avg_cost > 0:  # Only include agents with cost data
                rows.append({
                    'agent_id': agent_id,
                    'avg_quality': float(q_row['avg_quality'] or 0),
                    'avg_cost': avg_cost,
                    'total_requests': q_row['eval_count']
                })

        # Calculate global averages for quadrant classification
        total_quality = sum(float(row['avg_quality'] or 0) for row in rows)
        total_cost = sum(float(row['avg_cost'] or 0) for row in rows)
        count = len(rows) or 1

        avg_quality = total_quality / count
        avg_cost = total_cost / count

        items = []
        for row in rows:
            quality = float(row['avg_quality'] or 0)
            cost = float(row['avg_cost'] or 0)

            # Calculate efficiency score (higher is better)
            efficiency = (quality / max(cost, 0.0001)) * 100

            quadrant = classify_cost_quality_quadrant(quality, cost, avg_quality, avg_cost)

            items.append(QualityCostTradeoffItem(
                agent_id=row['agent_id'],
                avg_quality_score=quality,
                avg_cost_per_request_usd=cost,
                total_requests=row['total_requests'],
                efficiency_score=efficiency,
                quadrant=quadrant
            ))

        result = QualityCostTradeoff(
            data=items,
            avg_quality=avg_quality,
            avg_cost=avg_cost
        )

        set_cache(cache_key, result.dict(), ttl=600)  # 10 min cache
        return result

    except Exception as e:
        logger.error(f"Error fetching quality cost tradeoff: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch quality cost tradeoff: {str(e)}"
        )


@router.get("/rubric-heatmap", response_model=RubricHeatmap)
async def get_rubric_heatmap(
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    limit: int = QueryParam(20, ge=5, le=50),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool),
    postgres_pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Get rubric criteria scores across agents

    Returns heatmap data showing performance across accuracy,
    relevance, helpfulness, and coherence criteria.
    """
    cache_key = f"quality_rubric_heatmap:{x_workspace_id}:{range}:{limit}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return RubricHeatmap(**cached)

    try:
        workspace_uuid = UUID(x_workspace_id)
        hours = parse_time_range(range)

        # Get criteria scores per agent from evaluations
        query = """
            SELECT
                agent_id,
                COALESCE(AVG(accuracy_score), 0) as accuracy,
                COALESCE(AVG(relevance_score), 0) as relevance,
                COALESCE(AVG(helpfulness_score), 0) as helpfulness,
                COALESCE(AVG(coherence_score), 0) as coherence,
                COALESCE(AVG(overall_score), 0) as overall,
                COUNT(*)::int as eval_count
            FROM evaluations
            WHERE workspace_id = $1
                AND created_at >= NOW() - INTERVAL '1 hour' * $2
                AND overall_score IS NOT NULL
                AND agent_id IS NOT NULL
            GROUP BY agent_id
            ORDER BY overall ASC
            LIMIT $3
        """

        rows = await postgres_pool.fetch(query, workspace_uuid, hours, limit)

        items = [
            RubricHeatmapItem(
                agent_id=row['agent_id'],
                accuracy_score=float(row['accuracy'] or 0),
                relevance_score=float(row['relevance'] or 0),
                helpfulness_score=float(row['helpfulness'] or 0),
                coherence_score=float(row['coherence'] or 0),
                overall_score=float(row['overall'] or 0),
                evaluation_count=row['eval_count']
            )
            for row in rows
        ]

        # Calculate criteria averages across all agents
        criteria_averages = {
            "accuracy": sum(item.accuracy_score for item in items) / max(len(items), 1),
            "relevance": sum(item.relevance_score for item in items) / max(len(items), 1),
            "helpfulness": sum(item.helpfulness_score for item in items) / max(len(items), 1),
            "coherence": sum(item.coherence_score for item in items) / max(len(items), 1),
            "overall": sum(item.overall_score for item in items) / max(len(items), 1),
        }

        result = RubricHeatmap(
            data=items,
            criteria_averages=criteria_averages
        )

        set_cache(cache_key, result.dict(), ttl=600)  # 10 min cache
        return result

    except Exception as e:
        logger.error(f"Error fetching rubric heatmap: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch rubric heatmap: {str(e)}"
        )


@router.get("/drift-timeline", response_model=DriftTimeline)
async def get_drift_timeline(
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    granularity: str = QueryParam("daily", regex="^(hourly|daily|weekly)$"),
    drift_threshold: float = QueryParam(10.0, ge=1.0, le=50.0),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool),
    postgres_pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Get quality drift detection timeline

    Returns time-series data showing quality trends compared to baseline,
    with drift alerts when quality degrades beyond threshold.
    """
    cache_key = f"quality_drift:{x_workspace_id}:{range}:{granularity}:{drift_threshold}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return DriftTimeline(**cached)

    try:
        workspace_uuid = UUID(x_workspace_id)
        hours = parse_time_range(range)
        interval = parse_granularity(granularity)

        # Get baseline score (first 20% of period)
        baseline_query = """
            SELECT COALESCE(AVG(overall_score), 0) as baseline_score
            FROM evaluations
            WHERE workspace_id = $1
                AND created_at >= NOW() - INTERVAL '1 hour' * $2
                AND created_at < NOW() - INTERVAL '1 hour' * $2 * 0.8
                AND overall_score IS NOT NULL
        """

        # Get time-bucketed quality scores using date_trunc (Postgres native)
        trend_query = """
            SELECT
                date_trunc($3, created_at) as timestamp,
                COALESCE(AVG(overall_score), 0) as avg_score,
                COUNT(*)::int as eval_count
            FROM evaluations
            WHERE workspace_id = $1
                AND created_at >= NOW() - INTERVAL '1 hour' * $2
                AND overall_score IS NOT NULL
            GROUP BY date_trunc($3, created_at)
            ORDER BY timestamp ASC
        """

        baseline_row = await postgres_pool.fetchrow(baseline_query, workspace_uuid, hours)
        baseline_score = float(baseline_row['baseline_score'] or 0)

        # Convert granularity to date_trunc precision
        granularity_map = {
            'hourly': 'hour',
            'daily': 'day',
            'weekly': 'week'
        }
        trunc_precision = granularity_map.get(granularity, 'day')
        rows = await postgres_pool.fetch(trend_query, workspace_uuid, hours, trunc_precision)

        items = []
        for row in rows:
            avg_score = float(row['avg_score'] or 0)
            drift_pct = 0.0
            if baseline_score > 0:
                drift_pct = ((avg_score - baseline_score) / baseline_score) * 100

            alert_triggered = abs(drift_pct) >= drift_threshold

            items.append(DriftTimelineItem(
                timestamp=row['timestamp'],
                avg_score=avg_score,
                baseline_score=baseline_score,
                drift_percentage=drift_pct,
                evaluation_count=row['eval_count'],
                alert_triggered=alert_triggered
            ))

        # Get current period average for comparison
        current_query = """
            SELECT COALESCE(AVG(overall_score), 0) as current_score
            FROM evaluations
            WHERE workspace_id = $1
                AND created_at >= NOW() - INTERVAL '1 hour' * $2
                AND overall_score IS NOT NULL
        """
        current_row = await postgres_pool.fetchrow(current_query, workspace_uuid, hours)
        current_score = float(current_row['current_score'] or 0)

        result = DriftTimeline(
            data=items,
            baseline_score=baseline_score,
            current_score=current_score,
            drift_threshold=drift_threshold,
            granularity=granularity,
            range=range
        )

        set_cache(cache_key, result.dict(), ttl=180)  # 3 min cache
        return result

    except Exception as e:
        logger.error(f"Error fetching drift timeline: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch drift timeline: {str(e)}"
        )


@router.get("/agent/{agent_id}", response_model=AgentQualityDetails)
async def get_agent_quality(
    agent_id: str,
    range: str = QueryParam("7d", regex="^(1h|24h|7d|30d)$"),
    granularity: str = QueryParam("daily", regex="^(hourly|daily|weekly)$"),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool),
    postgres_pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Get comprehensive quality metrics for a specific agent

    Returns quality scores, trends, criteria breakdown, timeline,
    and recent evaluations scoped to the specified agent.
    """
    cache_key = f"agent_quality:{x_workspace_id}:{agent_id}:{range}:{granularity}"
    cached = get_cache(cache_key)
    if cached:
        logger.info(f"Cache hit for {cache_key}")
        return AgentQualityDetails(**cached)

    try:
        workspace_uuid = UUID(x_workspace_id)
        hours = parse_time_range(range)
        interval = parse_granularity(granularity)

        # Get current period quality metrics for this agent
        current_query = """
            SELECT
                COALESCE(AVG(overall_score), 0) as avg_score,
                COALESCE(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY overall_score), 0) as median_score,
                COUNT(*)::int as total_evals,
                (COUNT(CASE WHEN overall_score < 5.0 THEN 1 END)::float / NULLIF(COUNT(*), 0) * 100) as failing_rate,
                COALESCE(AVG(accuracy_score), 0) as avg_accuracy,
                COALESCE(AVG(relevance_score), 0) as avg_relevance,
                COALESCE(AVG(helpfulness_score), 0) as avg_helpfulness,
                COALESCE(AVG(coherence_score), 0) as avg_coherence,
                -- Recent vs older average for trend
                AVG(CASE WHEN created_at >= NOW() - INTERVAL '1 hour' * ($3 / 2) THEN overall_score END) as recent_avg,
                AVG(CASE WHEN created_at < NOW() - INTERVAL '1 hour' * ($3 / 2) THEN overall_score END) as older_avg
            FROM evaluations
            WHERE workspace_id = $1
                AND agent_id = $2
                AND created_at >= NOW() - INTERVAL '1 hour' * $3
                AND overall_score IS NOT NULL
        """

        # Get baseline score (first 20% of period) for drift calculation
        baseline_query = """
            SELECT COALESCE(AVG(overall_score), 0) as baseline_score
            FROM evaluations
            WHERE workspace_id = $1
                AND agent_id = $2
                AND created_at >= NOW() - INTERVAL '1 hour' * $3
                AND created_at < NOW() - INTERVAL '1 hour' * $3 * 0.8
                AND overall_score IS NOT NULL
        """

        # Get time-bucketed quality scores for timeline
        timeline_query = """
            SELECT
                date_trunc($4, created_at) as timestamp,
                COALESCE(AVG(overall_score), 0) as avg_score,
                COUNT(*)::int as eval_count
            FROM evaluations
            WHERE workspace_id = $1
                AND agent_id = $2
                AND created_at >= NOW() - INTERVAL '1 hour' * $3
                AND overall_score IS NOT NULL
            GROUP BY date_trunc($4, created_at)
            ORDER BY timestamp ASC
        """

        # Get recent evaluations for this agent
        evaluations_query = """
            SELECT
                id,
                trace_id,
                overall_score,
                accuracy_score,
                relevance_score,
                helpfulness_score,
                coherence_score,
                evaluator,
                created_at
            FROM evaluations
            WHERE workspace_id = $1
                AND agent_id = $2
                AND created_at >= NOW() - INTERVAL '1 hour' * $3
                AND overall_score IS NOT NULL
            ORDER BY created_at DESC
            LIMIT 20
        """

        current = await postgres_pool.fetchrow(current_query, workspace_uuid, agent_id, hours)
        baseline = await postgres_pool.fetchrow(baseline_query, workspace_uuid, agent_id, hours)

        # Convert granularity to date_trunc precision
        granularity_map = {
            'hourly': 'hour',
            'daily': 'day',
            'weekly': 'week'
        }
        trunc_precision = granularity_map.get(granularity, 'day')
        timeline_rows = await postgres_pool.fetch(timeline_query, workspace_uuid, agent_id, hours, trunc_precision)
        eval_rows = await postgres_pool.fetch(evaluations_query, workspace_uuid, agent_id, hours)

        # Process metrics
        avg_score = float(current['avg_score'] or 0)
        median_score = float(current['median_score'] or 0)
        total_evaluations = current['total_evals'] or 0
        failing_rate = float(current['failing_rate'] or 0)
        recent_avg = float(current['recent_avg'] or 0)
        older_avg = float(current['older_avg'] or 0)
        baseline_score = float(baseline['baseline_score'] or 0)

        # Determine trend
        if recent_avg > older_avg + 0.5:
            recent_trend = 'improving'
        elif recent_avg < older_avg - 0.5:
            recent_trend = 'degrading'
        else:
            recent_trend = 'stable'

        # Calculate drift indicator
        drift_indicator = 0.0
        if baseline_score > 0:
            drift_indicator = ((avg_score - baseline_score) / baseline_score) * 100

        # Build criteria breakdown
        criteria_breakdown = AgentCriteriaBreakdown(
            accuracy=float(current['avg_accuracy'] or 0),
            relevance=float(current['avg_relevance'] or 0),
            helpfulness=float(current['avg_helpfulness'] or 0),
            coherence=float(current['avg_coherence'] or 0)
        )

        # Build timeline
        timeline = []
        for row in timeline_rows:
            row_avg_score = float(row['avg_score'] or 0)
            drift_pct = 0.0
            if baseline_score > 0:
                drift_pct = ((row_avg_score - baseline_score) / baseline_score) * 100

            timeline.append(DriftTimelineItem(
                timestamp=row['timestamp'],
                avg_score=row_avg_score,
                baseline_score=baseline_score,
                drift_percentage=drift_pct,
                evaluation_count=row['eval_count'],
                alert_triggered=abs(drift_pct) >= 10.0  # 10% default threshold
            ))

        # Build recent evaluations
        recent_evaluations = [
            AgentEvaluationItem(
                id=str(row['id']),
                trace_id=row['trace_id'],
                overall_score=float(row['overall_score'] or 0),
                accuracy_score=float(row['accuracy_score']) if row['accuracy_score'] is not None else None,
                relevance_score=float(row['relevance_score']) if row['relevance_score'] is not None else None,
                helpfulness_score=float(row['helpfulness_score']) if row['helpfulness_score'] is not None else None,
                coherence_score=float(row['coherence_score']) if row['coherence_score'] is not None else None,
                evaluator=row['evaluator'],
                created_at=row['created_at']
            )
            for row in eval_rows
        ]

        result = AgentQualityDetails(
            agent_id=agent_id,
            avg_score=avg_score,
            median_score=median_score,
            total_evaluations=total_evaluations,
            failing_rate=failing_rate,
            recent_trend=recent_trend,
            drift_indicator=drift_indicator,
            criteria_breakdown=criteria_breakdown,
            timeline=timeline,
            recent_evaluations=recent_evaluations,
            range=range
        )

        set_cache(cache_key, result.dict(), ttl=300)  # 5 min cache
        return result

    except Exception as e:
        logger.error(f"Error fetching agent quality for {agent_id}: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch agent quality: {str(e)}"
        )


@router.get("/agent/{agent_id}/unevaluated-traces", response_model=UnevaluatedTracesResponse)
async def get_unevaluated_traces(
    agent_id: str,
    limit: int = QueryParam(20, ge=1, le=100),
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    timescale_pool: asyncpg.Pool = Depends(get_timescale_pool),
    postgres_pool: asyncpg.Pool = Depends(get_postgres_pool)
):
    """
    Get recent un-evaluated traces for a specific agent

    Returns traces that haven't been evaluated yet, for manual selection in UI.
    A trace is considered "un-evaluated" if it doesn't have a corresponding evaluation record.

    Query Parameters:
        - limit: Maximum number of traces to return (1-100, default: 20)

    Returns:
        List of un-evaluated traces with trace_id, input, output, timestamp
    """

    try:
        workspace_uuid = UUID(x_workspace_id)

        # First get trace_ids that have been evaluated from PostgreSQL
        eval_query = """
            SELECT DISTINCT trace_id
            FROM evaluations
            WHERE workspace_id = $1
        """
        evaluated_rows = await postgres_pool.fetch(eval_query, workspace_uuid)
        evaluated_trace_ids = [row['trace_id'] for row in evaluated_rows]

        # Then query traces from TimescaleDB excluding evaluated ones
        if evaluated_trace_ids:
            traces_query = """
                SELECT trace_id, input, output, timestamp, status
                FROM traces
                WHERE workspace_id = $1
                    AND agent_id = $2
                    AND status = 'success'
                    AND output IS NOT NULL
                    AND trace_id NOT IN (SELECT unnest($3::text[]))
                ORDER BY timestamp DESC
                LIMIT $4
            """
            rows = await timescale_pool.fetch(traces_query, workspace_uuid, agent_id, evaluated_trace_ids, limit)
        else:
            # If no evaluations exist, all traces are unevaluated
            traces_query = """
                SELECT trace_id, input, output, timestamp, status
                FROM traces
                WHERE workspace_id = $1
                    AND agent_id = $2
                    AND status = 'success'
                    AND output IS NOT NULL
                ORDER BY timestamp DESC
                LIMIT $3
            """
            rows = await timescale_pool.fetch(traces_query, workspace_uuid, agent_id, limit)

        traces = [
            UnevaluatedTraceItem(
                trace_id=row['trace_id'],
                input=row['input'],
                output=row['output'],
                timestamp=row['timestamp'],
                status=row['status']
            )
            for row in rows
        ]

        logger.info(f"Found {len(traces)} un-evaluated traces for agent {agent_id}")

        return UnevaluatedTracesResponse(
            traces=traces,
            total=len(traces),
            agent_id=agent_id
        )

    except Exception as e:
        logger.error(f"Error fetching un-evaluated traces for {agent_id}: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch un-evaluated traces: {str(e)}"
        )
