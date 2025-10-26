"""Google Gemini API client for business insights generation"""
import google.generativeai as genai
import json
import logging
from typing import Dict, Any
from .config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

# Configure Gemini API
genai.configure(api_key=settings.gemini_api_key)


async def generate_insight_with_gemini(prompt: str) -> Dict[str, Any]:
    """
    Generate insight using Gemini API

    Args:
        prompt: The formatted prompt for insight generation

    Returns:
        Dictionary with parsed JSON response from Gemini

    Raises:
        Exception: If Gemini API call fails or returns invalid JSON
    """

    try:
        # Create model instance
        model = genai.GenerativeModel(settings.gemini_model)

        # Call Gemini API
        logger.info(f"Calling Gemini API for insight generation (model: {settings.gemini_model})")
        response = model.generate_content(
            prompt,
            generation_config=genai.types.GenerationConfig(
                temperature=settings.temperature,
                top_p=0.95,
                top_k=40,
                max_output_tokens=settings.max_output_tokens,
            )
        )

        # Extract text from response
        response_text = response.text.strip()

        # Handle markdown code blocks if present
        if response_text.startswith("```"):
            # Remove markdown code block markers
            lines = response_text.split("\n")
            response_text = "\n".join(lines[1:-1]) if len(lines) > 2 else response_text
            response_text = response_text.replace("```json", "").replace("```", "").strip()

        # Parse JSON
        insight_data = json.loads(response_text)

        logger.info("Successfully generated insight with Gemini")

        return insight_data

    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse Gemini response as JSON: {e}")
        logger.error(f"Response text: {response_text}")
        raise Exception(f"Gemini API returned invalid JSON: {str(e)}")

    except Exception as e:
        logger.error(f"Gemini API insight generation failed: {e}")
        raise Exception(f"Insight generation failed: {str(e)}")


async def generate_cost_optimization_insight(
    total_cost: float,
    total_requests: int,
    avg_cost_per_request: float,
    cost_breakdown: list,
    days: int
) -> Dict[str, Any]:
    """
    Generate cost optimization insight

    Args:
        total_cost: Total cost in USD
        total_requests: Total number of requests
        avg_cost_per_request: Average cost per request
        cost_breakdown: List of cost breakdown by model/agent
        days: Number of days analyzed

    Returns:
        Dictionary with cost optimization insight
    """
    from .prompts import create_cost_optimization_prompt

    prompt = create_cost_optimization_prompt(
        total_cost=total_cost,
        total_requests=total_requests,
        avg_cost_per_request=avg_cost_per_request,
        cost_breakdown=cost_breakdown,
        days=days
    )

    return await generate_insight_with_gemini(prompt)


async def generate_error_diagnosis_insight(
    total_errors: int,
    error_rate: float,
    error_patterns: list,
    days: int
) -> Dict[str, Any]:
    """
    Generate error diagnosis insight

    Args:
        total_errors: Total number of errors
        error_rate: Error rate percentage
        error_patterns: List of error patterns with counts
        days: Number of days analyzed

    Returns:
        Dictionary with error diagnosis insight
    """
    from .prompts import create_error_diagnosis_prompt

    prompt = create_error_diagnosis_prompt(
        total_errors=total_errors,
        error_rate=error_rate,
        error_patterns=error_patterns,
        days=days
    )

    return await generate_insight_with_gemini(prompt)


async def generate_feedback_analysis_insight(
    feedback_items: list,
    days: int
) -> Dict[str, Any]:
    """
    Generate feedback analysis insight

    Args:
        feedback_items: List of feedback items with ratings and comments
        days: Number of days analyzed

    Returns:
        Dictionary with feedback analysis insight
    """
    from .prompts import create_feedback_analysis_prompt

    prompt = create_feedback_analysis_prompt(
        feedback_items=feedback_items,
        days=days
    )

    return await generate_insight_with_gemini(prompt)


async def generate_daily_summary_insight(
    date_str: str,
    total_requests: int,
    success_rate: float,
    avg_latency: float,
    total_cost: float,
    error_count: int,
    model_breakdown: list
) -> Dict[str, Any]:
    """
    Generate daily summary insight

    Args:
        date_str: Date string (YYYY-MM-DD)
        total_requests: Total requests for the day
        success_rate: Success rate percentage
        avg_latency: Average latency in ms
        total_cost: Total cost for the day
        error_count: Number of errors
        model_breakdown: Breakdown by model

    Returns:
        Dictionary with daily summary insight
    """
    from .prompts import create_daily_summary_prompt

    prompt = create_daily_summary_prompt(
        date_str=date_str,
        total_requests=total_requests,
        success_rate=success_rate,
        avg_latency=avg_latency,
        total_cost=total_cost,
        error_count=error_count,
        model_breakdown=model_breakdown
    )

    return await generate_insight_with_gemini(prompt)


def is_gemini_configured() -> bool:
    """Check if Gemini API is properly configured"""
    try:
        return bool(settings.gemini_api_key and settings.gemini_api_key != "your_gemini_api_key_here")
    except Exception:
        return False
