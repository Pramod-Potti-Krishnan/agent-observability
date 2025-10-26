"""Prompt templates for Gemini AI insights"""
from typing import Dict, Any, List


def create_cost_optimization_prompt(
    total_cost: float,
    total_requests: int,
    avg_cost_per_request: float,
    cost_breakdown: List[Dict[str, Any]],
    days: int
) -> str:
    """
    Create prompt for cost optimization analysis

    Args:
        total_cost: Total cost in USD
        total_requests: Total number of requests
        avg_cost_per_request: Average cost per request
        cost_breakdown: List of cost breakdown by model/agent
        days: Number of days analyzed

    Returns:
        Formatted prompt for Gemini
    """

    # Format cost breakdown
    breakdown_text = ""
    for item in cost_breakdown[:10]:  # Top 10
        breakdown_text += f"\n- Model: {item['model']}, Agent: {item.get('agent_id', 'N/A')}, "
        breakdown_text += f"Cost: ${item['total_cost']:.2f}, Requests: {item['request_count']}, "
        breakdown_text += f"Avg Cost: ${item['total_cost']/item['request_count']:.4f}, Tokens: {item['total_tokens']}"

    prompt = f"""
You are an AI cost optimization expert analyzing LLM usage costs for an AI agent monitoring platform.

COST ANALYSIS DATA (Last {days} days):
- Total Cost: ${total_cost:.2f} USD
- Total Requests: {total_requests:,}
- Average Cost per Request: ${avg_cost_per_request:.4f}

COST BREAKDOWN BY MODEL/AGENT (Top 10):{breakdown_text}

YOUR TASK:
Analyze this cost data and provide actionable cost optimization recommendations.

Identify the TOP 3 cost saving opportunities, ranked by potential impact.
For each opportunity:
1. Calculate estimated potential savings in USD
2. Assess impact level (high/medium/low)
3. Provide specific, actionable recommendations

Consider these optimization strategies:
- Model selection (using cheaper models for simple tasks)
- Prompt optimization (reducing token usage)
- Caching strategies (reducing redundant API calls)
- Rate limiting or throttling
- Batching requests
- Context window optimization
- Agent consolidation

Return your analysis as valid JSON in this EXACT format:
{{
  "summary": "2-3 sentence executive summary of cost analysis",
  "opportunities": [
    {{
      "title": "Opportunity title",
      "description": "Detailed description of the opportunity",
      "potential_savings_usd": 123.45,
      "impact": "high",
      "recommendation": "Specific actionable recommendation"
    }},
    {{
      "title": "Second opportunity title",
      "description": "Detailed description",
      "potential_savings_usd": 67.89,
      "impact": "medium",
      "recommendation": "Specific actionable recommendation"
    }},
    {{
      "title": "Third opportunity title",
      "description": "Detailed description",
      "potential_savings_usd": 34.56,
      "impact": "low",
      "recommendation": "Specific actionable recommendation"
    }}
  ]
}}

Important:
- Return ONLY valid JSON, no additional text
- Ensure potential_savings_usd is a number
- Impact must be "high", "medium", or "low"
- Be specific and actionable in recommendations
- Base savings estimates on the actual data provided
"""

    return prompt


def create_error_diagnosis_prompt(
    total_errors: int,
    error_rate: float,
    error_patterns: List[Dict[str, Any]],
    days: int
) -> str:
    """
    Create prompt for error diagnosis and fix suggestions

    Args:
        total_errors: Total number of errors
        error_rate: Error rate percentage
        error_patterns: List of error patterns with counts
        days: Number of days analyzed

    Returns:
        Formatted prompt for Gemini
    """

    # Format error patterns
    patterns_text = ""
    for i, pattern in enumerate(error_patterns[:10], 1):  # Top 10
        patterns_text += f"\n{i}. Error: {pattern['error_message'][:200]}"
        patterns_text += f"\n   Count: {pattern['count']}, "
        patterns_text += f"Affected Agents: {', '.join(pattern['agent_ids'][:5])}"
        patterns_text += f"\n   Sample Trace: {pattern['sample_trace_id']}\n"

    prompt = f"""
You are an AI debugging expert analyzing errors from an AI agent monitoring platform.

ERROR ANALYSIS DATA (Last {days} days):
- Total Errors: {total_errors:,}
- Error Rate: {error_rate:.2f}%

TOP ERROR PATTERNS:{patterns_text}

YOUR TASK:
1. Analyze these error patterns and identify the root causes
2. Categorize errors by type (e.g., API errors, timeout errors, validation errors, model errors)
3. Provide TOP 3 prioritized fixes ranked by impact

For each suggested fix:
1. Identify the root cause
2. Provide step-by-step fix instructions
3. Estimate impact (high/medium/low)
4. Assign priority (1 = highest, 3 = lowest)

Return your analysis as valid JSON in this EXACT format:
{{
  "summary": "2-3 sentence executive summary of error analysis",
  "patterns": [
    {{
      "error_type": "Type of error (e.g., 'API Timeout', 'Rate Limit', 'Validation Error')",
      "count": 123,
      "percentage": 45.6,
      "sample_message": "Sample error message",
      "affected_agents": ["agent1", "agent2"]
    }}
  ],
  "suggested_fixes": [
    {{
      "title": "Fix title",
      "description": "Detailed description of the issue",
      "root_cause": "Root cause analysis",
      "fix_steps": [
        "Step 1: Specific action",
        "Step 2: Specific action",
        "Step 3: Specific action"
      ],
      "impact": "high",
      "priority": 1
    }},
    {{
      "title": "Second fix title",
      "description": "Detailed description",
      "root_cause": "Root cause analysis",
      "fix_steps": ["Step 1", "Step 2"],
      "impact": "medium",
      "priority": 2
    }},
    {{
      "title": "Third fix title",
      "description": "Detailed description",
      "root_cause": "Root cause analysis",
      "fix_steps": ["Step 1", "Step 2"],
      "impact": "low",
      "priority": 3
    }}
  ]
}}

Important:
- Return ONLY valid JSON, no additional text
- Categorize errors meaningfully
- Be specific and actionable in fix steps
- Impact must be "high", "medium", or "low"
- Priority must be 1, 2, or 3
"""

    return prompt


def create_feedback_analysis_prompt(
    feedback_items: List[Dict[str, Any]],
    days: int
) -> str:
    """
    Create prompt for feedback sentiment analysis

    Args:
        feedback_items: List of feedback items with ratings and comments
        days: Number of days analyzed

    Returns:
        Formatted prompt for Gemini
    """

    # Format feedback
    feedback_text = ""
    for i, item in enumerate(feedback_items[:50], 1):  # Sample of 50
        rating = item.get('rating', 'N/A')
        comment = item.get('comment', 'No comment')
        feedback_text += f"\n{i}. Rating: {rating}/5, Comment: \"{comment[:200]}\""

    total_items = len(feedback_items)

    # Calculate basic stats
    ratings = [item.get('rating', 0) for item in feedback_items if item.get('rating') is not None]
    avg_rating = sum(ratings) / len(ratings) if ratings else 0

    prompt = f"""
You are a customer feedback analysis expert analyzing user feedback for AI agent interactions.

FEEDBACK DATA (Last {days} days):
- Total Feedback Items: {total_items}
- Average Rating: {avg_rating:.2f}/5

SAMPLE FEEDBACK (up to 50 items):{feedback_text}

YOUR TASK:
1. Perform sentiment analysis on the feedback
2. Calculate overall sentiment score (-1 to 1, where -1 is very negative, 0 is neutral, 1 is very positive)
3. Identify 3-5 key themes from the feedback
4. Provide 3-5 actionable insights with specific actions

For sentiment analysis:
- Consider both ratings and comment text
- Weight recent feedback slightly higher
- Identify sentiment label: positive, negative, neutral, or mixed

For themes:
- Group similar feedback together
- Identify patterns in user comments
- Note whether theme sentiment is positive, negative, or neutral
- Provide examples

For actionable insights:
- Focus on items that can improve user experience
- Prioritize by impact (high/medium/low)
- Provide specific, implementable actions

Return your analysis as valid JSON in this EXACT format:
{{
  "summary": "2-3 sentence executive summary of feedback analysis",
  "overall_sentiment_score": 0.75,
  "sentiment_label": "positive",
  "key_themes": [
    {{
      "theme": "Theme name",
      "sentiment": "positive",
      "count": 25,
      "examples": ["Example 1", "Example 2", "Example 3"]
    }},
    {{
      "theme": "Another theme",
      "sentiment": "negative",
      "count": 15,
      "examples": ["Example 1", "Example 2"]
    }}
  ],
  "actionable_insights": [
    {{
      "title": "Insight title",
      "description": "Detailed description of the insight",
      "priority": "high",
      "actions": [
        "Specific action 1",
        "Specific action 2",
        "Specific action 3"
      ]
    }},
    {{
      "title": "Second insight",
      "description": "Description",
      "priority": "medium",
      "actions": ["Action 1", "Action 2"]
    }}
  ]
}}

Important:
- Return ONLY valid JSON, no additional text
- Sentiment score must be between -1 and 1
- Sentiment label must be "positive", "negative", "neutral", or "mixed"
- Theme sentiment must be "positive", "negative", or "neutral"
- Priority must be "high", "medium", or "low"
- Be specific and actionable
"""

    return prompt


def create_daily_summary_prompt(
    date_str: str,
    total_requests: int,
    success_rate: float,
    avg_latency: float,
    total_cost: float,
    error_count: int,
    model_breakdown: List[Dict[str, Any]]
) -> str:
    """
    Create prompt for daily summary generation

    Args:
        date_str: Date string (YYYY-MM-DD)
        total_requests: Total requests for the day
        success_rate: Success rate percentage
        avg_latency: Average latency in ms
        total_cost: Total cost for the day
        error_count: Number of errors
        model_breakdown: Breakdown by model

    Returns:
        Formatted prompt for Gemini
    """

    # Format model breakdown
    models_text = ""
    for item in model_breakdown:
        models_text += f"\n- Model: {item['model']}, Requests: {item['requests']}, "
        models_text += f"Cost: ${item['cost']:.2f}, Agents: {item['agent_count']}"

    prompt = f"""
You are an AI operations analyst creating a daily executive summary for an AI agent monitoring platform.

DAILY METRICS FOR {date_str}:
- Total Requests: {total_requests:,}
- Success Rate: {success_rate:.2f}%
- Average Latency: {avg_latency:.0f}ms
- Total Cost: ${total_cost:.2f}
- Errors: {error_count}

MODEL BREAKDOWN:{models_text}

YOUR TASK:
Create a comprehensive daily summary with:
1. Executive summary (2-3 sentences)
2. Key highlights (2-4 items) - positive trends, achievements, milestones
3. Concerns (1-3 items) - issues that need attention
4. Recommendations (2-4 items) - prioritized actions for tomorrow

Focus on:
- Performance trends (latency, success rate)
- Cost efficiency
- Error patterns
- Capacity and scaling
- Model utilization

Return your analysis as valid JSON in this EXACT format:
{{
  "executive_summary": "2-3 sentence high-level summary suitable for executives",
  "highlights": [
    {{
      "type": "success",
      "title": "Highlight title",
      "description": "Description of the positive trend or achievement",
      "metrics": {{
        "key1": "value1",
        "key2": "value2"
      }}
    }},
    {{
      "type": "trend",
      "title": "Another highlight",
      "description": "Description",
      "metrics": {{"key": "value"}}
    }}
  ],
  "concerns": [
    {{
      "type": "concern",
      "title": "Concern title",
      "description": "Description of the issue",
      "metrics": {{"key": "value"}}
    }}
  ],
  "recommendations": [
    {{
      "title": "Recommendation title",
      "description": "Detailed recommendation",
      "priority": "high"
    }},
    {{
      "title": "Second recommendation",
      "description": "Description",
      "priority": "medium"
    }}
  ]
}}

Important:
- Return ONLY valid JSON, no additional text
- Highlight type must be "success", "trend", or "milestone"
- Concern type must be "concern"
- Priority must be "high", "medium", or "low"
- Be specific and data-driven
- Keep executive summary concise and actionable
"""

    return prompt
