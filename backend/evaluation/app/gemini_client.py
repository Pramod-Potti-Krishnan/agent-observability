"""Google Gemini API client for LLM-as-a-judge evaluations"""
import google.generativeai as genai
import json
import logging
from typing import Dict, List, Optional
from .config import get_settings
from .models import EvaluationCriteria

logger = logging.getLogger(__name__)
settings = get_settings()

# Configure Gemini API
genai.configure(api_key=settings.gemini_api_key)


def create_evaluation_prompt(
    trace_input: str,
    trace_output: str,
    custom_criteria: Optional[List[EvaluationCriteria]] = None
) -> str:
    """
    Create evaluation prompt for Gemini

    Args:
        trace_input: User input from the trace
        trace_output: Agent output from the trace
        custom_criteria: Optional custom evaluation criteria

    Returns:
        Formatted prompt string
    """

    base_criteria = """
    Standard Evaluation Criteria (0-10 scale):
    - Accuracy: Does the response correctly address the input? Is information factually correct?
    - Relevance: Is the response relevant to the user's query? Does it stay on topic?
    - Helpfulness: Is the response useful and actionable? Does it solve the user's problem?
    - Coherence: Is the response well-structured and easy to understand? Is it logically organized?
    """

    custom_criteria_text = ""
    if custom_criteria:
        custom_criteria_text = "\n\nCustom Evaluation Criteria:\n"
        for criterion in custom_criteria:
            custom_criteria_text += f"- {criterion.name} (weight: {criterion.weight}): {criterion.description}\n"

    prompt = f"""
You are an expert AI evaluator. Evaluate the following AI agent interaction based on the criteria below.

User Input:
{trace_input}

Agent Output:
{trace_output}

{base_criteria}
{custom_criteria_text}

Instructions:
1. Provide scores from 0-10 for each criterion (decimals allowed, e.g., 8.5)
2. Calculate an overall score as the weighted average of all criteria
3. Provide brief reasoning (2-3 sentences) explaining the scores

Return your evaluation as valid JSON in this exact format:
{{
  "accuracy_score": 8.5,
  "relevance_score": 9.0,
  "helpfulness_score": 7.5,
  "coherence_score": 9.0,
  "overall_score": 8.5,
  "reasoning": "The response correctly addresses the user's question with accurate information (high accuracy). It stays perfectly on topic (high relevance) and provides clear, actionable guidance (good helpfulness). The structure is logical and easy to follow (high coherence). Overall, this is a strong response that effectively helps the user."
}}

Important: Return ONLY the JSON object, no additional text before or after.
"""

    return prompt


async def evaluate_with_gemini(
    trace_input: str,
    trace_output: str,
    custom_criteria: Optional[List[EvaluationCriteria]] = None
) -> Dict:
    """
    Evaluate trace using Gemini API

    Args:
        trace_input: User input text
        trace_output: Agent output text
        custom_criteria: Optional custom evaluation criteria

    Returns:
        Dictionary with evaluation scores and reasoning

    Raises:
        Exception: If Gemini API call fails
    """

    try:
        # Create model instance
        model = genai.GenerativeModel(settings.gemini_model)

        # Generate prompt
        prompt = create_evaluation_prompt(trace_input, trace_output, custom_criteria)

        # Call Gemini API
        logger.info(f"Calling Gemini API for evaluation (model: {settings.gemini_model})")
        response = model.generate_content(
            prompt,
            generation_config=genai.types.GenerationConfig(
                temperature=0.3,  # Lower temperature for more consistent evaluations
                top_p=0.95,
                top_k=40,
                max_output_tokens=1024,
            )
        )

        # Extract JSON from response
        response_text = response.text.strip()

        # Handle markdown code blocks if present
        if response_text.startswith("```"):
            # Remove markdown code block markers
            lines = response_text.split("\n")
            response_text = "\n".join(lines[1:-1]) if len(lines) > 2 else response_text
            response_text = response_text.replace("```json", "").replace("```", "").strip()

        # Parse JSON
        evaluation = json.loads(response_text)

        # Validate required fields
        required_fields = [
            'accuracy_score',
            'relevance_score',
            'helpfulness_score',
            'coherence_score',
            'overall_score',
            'reasoning'
        ]

        for field in required_fields:
            if field not in evaluation:
                raise ValueError(f"Missing required field: {field}")

        # Ensure scores are within 0-10 range
        for score_field in ['accuracy_score', 'relevance_score', 'helpfulness_score', 'coherence_score', 'overall_score']:
            score = float(evaluation[score_field])
            if score < 0 or score > 10:
                raise ValueError(f"{score_field} must be between 0 and 10, got {score}")
            evaluation[score_field] = score

        logger.info(f"Successfully evaluated trace with overall score: {evaluation['overall_score']}")

        return evaluation

    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse Gemini response as JSON: {e}")
        logger.error(f"Response text: {response_text}")
        raise Exception(f"Gemini API returned invalid JSON: {str(e)}")

    except Exception as e:
        logger.error(f"Gemini API evaluation failed: {e}")
        raise Exception(f"Evaluation failed: {str(e)}")


async def batch_evaluate_with_gemini(
    traces: List[Dict],
    custom_criteria: Optional[List[EvaluationCriteria]] = None
) -> List[Dict]:
    """
    Batch evaluate multiple traces

    Args:
        traces: List of trace dictionaries with 'trace_id', 'input', 'output'
        custom_criteria: Optional custom evaluation criteria

    Returns:
        List of evaluation results
    """

    results = []

    for trace in traces:
        try:
            evaluation = await evaluate_with_gemini(
                trace['input'],
                trace['output'],
                custom_criteria
            )
            evaluation['trace_id'] = trace['trace_id']
            evaluation['success'] = True
            results.append(evaluation)

        except Exception as e:
            logger.error(f"Failed to evaluate trace {trace['trace_id']}: {e}")
            results.append({
                'trace_id': trace['trace_id'],
                'success': False,
                'error': str(e)
            })

    return results


def is_gemini_configured() -> bool:
    """Check if Gemini API is properly configured"""
    try:
        return bool(settings.gemini_api_key and settings.gemini_api_key != "your_gemini_api_key_here")
    except Exception:
        return False
