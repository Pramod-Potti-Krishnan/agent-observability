"""API routes for Gemini insights and business goals"""
from fastapi import APIRouter, HTTPException, Header
from typing import Optional
from datetime import datetime, date, timedelta
from decimal import Decimal
import logging

from ..models import (
    CostOptimizationRequest,
    CostOptimizationInsight,
    CostBreakdown,
    CostSavingOpportunity,
    ErrorDiagnosisRequest,
    ErrorDiagnosisInsight,
    ErrorPattern,
    ErrorFix,
    FeedbackAnalysisRequest,
    FeedbackAnalysisInsight,
    FeedbackTheme,
    ActionableInsight,
    DailySummaryRequest,
    DailySummaryInsight,
    DailyHighlight,
    DailyRecommendation,
    CreateBusinessGoalRequest,
    BusinessGoal,
    BusinessGoalsResponse
)
from ..database import (
    get_cost_data,
    get_total_cost_summary,
    get_error_data,
    get_error_summary,
    get_feedback_data,
    get_daily_summary_data,
    get_business_goals,
    create_business_goal,
    get_cached_insight,
    set_cached_insight
)
from ..gemini_client import (
    generate_cost_optimization_insight,
    generate_error_diagnosis_insight,
    generate_feedback_analysis_insight,
    generate_daily_summary_insight
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/insights", tags=["insights"])


# ===== Helper Functions =====

def get_workspace_id_from_header(x_workspace_id: Optional[str]) -> str:
    """Extract and validate workspace ID from header"""
    if not x_workspace_id:
        raise HTTPException(status_code=400, detail="X-Workspace-ID header is required")
    return x_workspace_id


# ===== Insight Endpoints =====

@router.post("/cost-optimization", response_model=CostOptimizationInsight)
async def get_cost_optimization_insight(
    request: CostOptimizationRequest,
    x_workspace_id: Optional[str] = Header(None)
):
    """
    Analyze costs and provide optimization recommendations

    This endpoint analyzes LLM usage costs over a specified period and uses
    Gemini AI to identify cost-saving opportunities.
    """
    workspace_id = get_workspace_id_from_header(x_workspace_id)

    try:
        # Generate cache key
        cache_key = f"cost_opt:{workspace_id}:{request.days}:{request.agent_id or 'all'}"

        # Check cache
        cached = await get_cached_insight(cache_key)
        if cached:
            logger.info(f"Returning cached cost optimization insight for workspace {workspace_id}")
            cached['cached'] = True
            cached['generated_at'] = datetime.fromisoformat(cached['generated_at'])
            return CostOptimizationInsight(**cached)

        # Fetch cost data
        logger.info(f"Fetching cost data for workspace {workspace_id} (days: {request.days})")
        cost_data = await get_cost_data(workspace_id, request.days, request.agent_id)
        summary = await get_total_cost_summary(workspace_id, request.days, request.agent_id)

        if summary['total_requests'] == 0:
            raise HTTPException(
                status_code=404,
                detail=f"No cost data found for the last {request.days} days"
            )

        # Generate insight with Gemini
        logger.info("Generating cost optimization insight with Gemini")
        gemini_response = await generate_cost_optimization_insight(
            total_cost=summary['total_cost'],
            total_requests=summary['total_requests'],
            avg_cost_per_request=summary['avg_cost_per_request'],
            cost_breakdown=cost_data,
            days=request.days
        )

        # Build response
        cost_breakdown = [
            CostBreakdown(
                model=item['model'],
                agent_id=item['agent_id'],
                total_cost=item['total_cost'],
                total_requests=item['request_count'],
                avg_cost_per_request=item['total_cost'] / item['request_count'] if item['request_count'] > 0 else 0,
                total_tokens=item['total_tokens']
            )
            for item in cost_data
        ]

        opportunities = [
            CostSavingOpportunity(**opp)
            for opp in gemini_response.get('opportunities', [])
        ]

        insight = CostOptimizationInsight(
            summary=gemini_response.get('summary', ''),
            total_cost_usd=summary['total_cost'],
            total_requests=summary['total_requests'],
            avg_cost_per_request=summary['avg_cost_per_request'],
            cost_breakdown=cost_breakdown,
            opportunities=opportunities,
            generated_at=datetime.utcnow(),
            cached=False
        )

        # Cache the result
        await set_cached_insight(cache_key, insight.model_dump())

        logger.info(f"Cost optimization insight generated successfully for workspace {workspace_id}")
        return insight

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate cost optimization insight: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to generate insight: {str(e)}")


@router.post("/error-diagnosis", response_model=ErrorDiagnosisInsight)
async def get_error_diagnosis_insight(
    request: ErrorDiagnosisRequest,
    x_workspace_id: Optional[str] = Header(None)
):
    """
    Analyze error patterns and suggest fixes

    This endpoint analyzes error patterns over a specified period and uses
    Gemini AI to diagnose root causes and suggest prioritized fixes.
    """
    workspace_id = get_workspace_id_from_header(x_workspace_id)

    try:
        # Generate cache key
        cache_key = f"error_diag:{workspace_id}:{request.days}:{request.agent_id or 'all'}"

        # Check cache
        cached = await get_cached_insight(cache_key)
        if cached:
            logger.info(f"Returning cached error diagnosis insight for workspace {workspace_id}")
            cached['cached'] = True
            cached['generated_at'] = datetime.fromisoformat(cached['generated_at'])
            return ErrorDiagnosisInsight(**cached)

        # Fetch error data
        logger.info(f"Fetching error data for workspace {workspace_id} (days: {request.days})")
        error_data = await get_error_data(
            workspace_id,
            request.days,
            request.agent_id,
            request.error_threshold
        )
        summary = await get_error_summary(workspace_id, request.days, request.agent_id)

        if summary['total_errors'] == 0:
            raise HTTPException(
                status_code=404,
                detail=f"No errors found for the last {request.days} days"
            )

        # Generate insight with Gemini
        logger.info("Generating error diagnosis insight with Gemini")
        gemini_response = await generate_error_diagnosis_insight(
            total_errors=summary['total_errors'],
            error_rate=summary['error_rate'],
            error_patterns=error_data,
            days=request.days
        )

        # Build response
        patterns = [
            ErrorPattern(**pattern)
            for pattern in gemini_response.get('patterns', [])
        ]

        suggested_fixes = [
            ErrorFix(**fix)
            for fix in gemini_response.get('suggested_fixes', [])
        ]

        insight = ErrorDiagnosisInsight(
            summary=gemini_response.get('summary', ''),
            total_errors=summary['total_errors'],
            error_rate=summary['error_rate'],
            patterns=patterns,
            suggested_fixes=suggested_fixes,
            generated_at=datetime.utcnow(),
            cached=False
        )

        # Cache the result
        await set_cached_insight(cache_key, insight.model_dump())

        logger.info(f"Error diagnosis insight generated successfully for workspace {workspace_id}")
        return insight

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate error diagnosis insight: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to generate insight: {str(e)}")


@router.post("/feedback-analysis", response_model=FeedbackAnalysisInsight)
async def get_feedback_analysis_insight(
    request: FeedbackAnalysisRequest,
    x_workspace_id: Optional[str] = Header(None)
):
    """
    Analyze user feedback sentiment and identify themes

    This endpoint analyzes user feedback over a specified period and uses
    Gemini AI to perform sentiment analysis and extract actionable insights.
    """
    workspace_id = get_workspace_id_from_header(x_workspace_id)

    try:
        # Generate cache key
        cache_key = f"feedback_analysis:{workspace_id}:{request.days}:{request.agent_id or 'all'}"

        # Check cache
        cached = await get_cached_insight(cache_key)
        if cached:
            logger.info(f"Returning cached feedback analysis insight for workspace {workspace_id}")
            cached['cached'] = True
            cached['generated_at'] = datetime.fromisoformat(cached['generated_at'])
            return FeedbackAnalysisInsight(**cached)

        # Fetch feedback data
        logger.info(f"Fetching feedback data for workspace {workspace_id} (days: {request.days})")
        feedback_data = await get_feedback_data(workspace_id, request.days, request.agent_id)

        if not feedback_data:
            raise HTTPException(
                status_code=404,
                detail=f"No feedback found for the last {request.days} days"
            )

        # Generate insight with Gemini
        logger.info("Generating feedback analysis insight with Gemini")
        gemini_response = await generate_feedback_analysis_insight(
            feedback_items=feedback_data,
            days=request.days
        )

        # Build response
        key_themes = [
            FeedbackTheme(**theme)
            for theme in gemini_response.get('key_themes', [])
        ]

        actionable_insights = [
            ActionableInsight(**insight)
            for insight in gemini_response.get('actionable_insights', [])
        ]

        insight = FeedbackAnalysisInsight(
            summary=gemini_response.get('summary', ''),
            overall_sentiment_score=gemini_response.get('overall_sentiment_score', 0),
            sentiment_label=gemini_response.get('sentiment_label', 'neutral'),
            total_feedback_items=len(feedback_data),
            key_themes=key_themes,
            actionable_insights=actionable_insights,
            generated_at=datetime.utcnow(),
            cached=False
        )

        # Cache the result
        await set_cached_insight(cache_key, insight.model_dump())

        logger.info(f"Feedback analysis insight generated successfully for workspace {workspace_id}")
        return insight

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate feedback analysis insight: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to generate insight: {str(e)}")


@router.get("/daily-summary", response_model=DailySummaryInsight)
async def get_daily_summary_insight(
    date: Optional[str] = None,
    agent_id: Optional[str] = None,
    x_workspace_id: Optional[str] = Header(None)
):
    """
    Get automated daily summary

    This endpoint generates a daily executive summary of agent performance,
    including highlights, concerns, and recommendations. Defaults to yesterday.
    """
    workspace_id = get_workspace_id_from_header(x_workspace_id)

    try:
        # Parse date or use yesterday
        if date:
            try:
                target_date = datetime.strptime(date, '%Y-%m-%d').date()
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
        else:
            target_date = (datetime.utcnow() - timedelta(days=1)).date()

        # Generate cache key
        cache_key = f"daily_summary:{workspace_id}:{target_date}:{agent_id or 'all'}"

        # Check cache
        cached = await get_cached_insight(cache_key)
        if cached:
            logger.info(f"Returning cached daily summary for workspace {workspace_id}")
            cached['cached'] = True
            cached['generated_at'] = datetime.fromisoformat(cached['generated_at'])
            cached['date'] = datetime.strptime(cached['date'], '%Y-%m-%d').date()
            return DailySummaryInsight(**cached)

        # Fetch daily data
        logger.info(f"Fetching daily data for workspace {workspace_id} (date: {target_date})")
        daily_data = await get_daily_summary_data(workspace_id, target_date, agent_id)

        if daily_data['total_requests'] == 0:
            raise HTTPException(
                status_code=404,
                detail=f"No data found for {target_date}"
            )

        # Generate insight with Gemini
        logger.info("Generating daily summary insight with Gemini")
        gemini_response = await generate_daily_summary_insight(
            date_str=target_date.strftime('%Y-%m-%d'),
            total_requests=daily_data['total_requests'],
            success_rate=daily_data['success_rate'],
            avg_latency=daily_data['avg_latency'],
            total_cost=daily_data['total_cost'],
            error_count=daily_data['error_count'],
            model_breakdown=daily_data['model_breakdown']
        )

        # Build response
        highlights = [
            DailyHighlight(**item)
            for item in gemini_response.get('highlights', [])
        ]

        concerns = [
            DailyHighlight(**item)
            for item in gemini_response.get('concerns', [])
        ]

        recommendations = [
            DailyRecommendation(**item)
            for item in gemini_response.get('recommendations', [])
        ]

        insight = DailySummaryInsight(
            executive_summary=gemini_response.get('executive_summary', ''),
            date=target_date,
            total_requests=daily_data['total_requests'],
            success_rate=daily_data['success_rate'],
            avg_latency_ms=daily_data['avg_latency'],
            total_cost_usd=daily_data['total_cost'],
            highlights=highlights,
            concerns=concerns,
            recommendations=recommendations,
            generated_at=datetime.utcnow(),
            cached=False
        )

        # Cache the result
        await set_cached_insight(cache_key, insight.model_dump())

        logger.info(f"Daily summary insight generated successfully for workspace {workspace_id}")
        return insight

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate daily summary insight: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to generate insight: {str(e)}")


# ===== Business Goals Endpoints =====

@router.get("/business-goals", response_model=BusinessGoalsResponse)
async def list_business_goals(
    active_only: bool = False,
    x_workspace_id: Optional[str] = Header(None)
):
    """
    List business goals for workspace

    Returns all business goals, optionally filtered to active goals only.
    """
    workspace_id = get_workspace_id_from_header(x_workspace_id)

    try:
        logger.info(f"Fetching business goals for workspace {workspace_id} (active_only: {active_only})")
        goals_data = await get_business_goals(workspace_id, active_only)

        goals = []
        active_count = 0

        for goal_data in goals_data:
            # Calculate progress percentage
            target = float(goal_data['target_value'])
            current = float(goal_data['current_value'])
            progress = min((current / target * 100) if target > 0 else 0, 100)

            goal = BusinessGoal(
                id=goal_data['id'],
                workspace_id=goal_data['workspace_id'],
                name=goal_data['name'],
                description=goal_data['description'],
                metric=goal_data['metric'],
                target_value=goal_data['target_value'],
                current_value=goal_data['current_value'],
                unit=goal_data['unit'],
                target_date=goal_data['target_date'],
                is_active=goal_data['is_active'],
                created_at=goal_data['created_at'],
                updated_at=goal_data['updated_at'],
                progress_percentage=progress
            )
            goals.append(goal)

            if goal_data['is_active']:
                active_count += 1

        logger.info(f"Retrieved {len(goals)} business goals for workspace {workspace_id}")
        return BusinessGoalsResponse(
            goals=goals,
            total=len(goals),
            active=active_count
        )

    except Exception as e:
        logger.error(f"Failed to fetch business goals: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch business goals: {str(e)}")


@router.post("/business-goals", response_model=BusinessGoal)
async def create_new_business_goal(
    request: CreateBusinessGoalRequest,
    x_workspace_id: Optional[str] = Header(None)
):
    """
    Create a new business goal

    Creates a new business goal for tracking agent impact on business metrics.
    """
    workspace_id = get_workspace_id_from_header(x_workspace_id)

    try:
        # Validate metric type
        valid_metrics = ['support_tickets', 'csat_score', 'cost_savings', 'response_time']
        if request.metric not in valid_metrics:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid metric. Must be one of: {', '.join(valid_metrics)}"
            )

        logger.info(f"Creating business goal for workspace {workspace_id}: {request.name}")
        goal_data = await create_business_goal(
            workspace_id=workspace_id,
            name=request.name,
            metric=request.metric,
            target_value=request.target_value,
            description=request.description,
            current_value=request.current_value,
            unit=request.unit,
            target_date=request.target_date
        )

        # Calculate progress
        target = float(goal_data['target_value'])
        current = float(goal_data['current_value'])
        progress = min((current / target * 100) if target > 0 else 0, 100)

        goal = BusinessGoal(
            id=goal_data['id'],
            workspace_id=goal_data['workspace_id'],
            name=goal_data['name'],
            description=goal_data['description'],
            metric=goal_data['metric'],
            target_value=goal_data['target_value'],
            current_value=goal_data['current_value'],
            unit=goal_data['unit'],
            target_date=goal_data['target_date'],
            is_active=goal_data['is_active'],
            created_at=goal_data['created_at'],
            updated_at=goal_data['updated_at'],
            progress_percentage=progress
        )

        logger.info(f"Business goal created successfully: {goal.id}")
        return goal

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create business goal: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to create business goal: {str(e)}")
