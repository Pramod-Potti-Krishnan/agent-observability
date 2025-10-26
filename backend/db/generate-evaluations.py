#!/usr/bin/env python3
"""
Generate synthetic evaluation data for Quality Dashboard
Links evaluations to existing traces with realistic score distributions
"""

import asyncio
import asyncpg
import json
import random
from datetime import datetime, timedelta
from uuid import uuid4

# Database connection strings
POSTGRES_URL = "postgresql://postgres:postgres@localhost:5433/agent_observability_metadata"
TIMESCALE_URL = "postgresql://postgres:postgres@localhost:5432/agent_observability"

# Configuration
WORKSPACE_ID = "37160be9-7d69-43b5-8d5f-9d7b5e14a57a"
NUM_EVALUATIONS = 1000

# Evaluator distribution (75% gemini, 20% human, 5% custom)
EVALUATORS = ['gemini'] * 75 + ['human'] * 20 + ['custom_model'] * 5

# Reasoning templates
REASONING_TEMPLATES = [
    'The response demonstrates excellent understanding of the query and provides accurate, relevant information.',
    'Strong performance across all criteria. The answer is coherent and directly addresses the user\'s needs.',
    'Good quality response with minor room for improvement in specificity.',
    'Very helpful and accurate response. Clear and well-structured.',
    'Outstanding response quality. Demonstrates deep understanding and provides actionable insights.',
    'Solid performance. The response is relevant and helpful, though could be more detailed.',
    'Excellent coherence and relevance. The response fully addresses the user\'s question.',
    'High-quality response with strong accuracy and helpfulness scores.',
    'Well-structured answer that provides clear and relevant information.',
    'Very good response. Shows good understanding and provides useful information.'
]


def generate_scores():
    """Generate realistic evaluation scores (biased toward 6.0-10.0)"""
    rand = random.random()

    if rand < 0.2:  # 20% excellent (9-10)
        base = 9.0
        variance = 1.0
    elif rand < 0.8:  # 60% good (7-9)
        base = 7.0
        variance = 2.0
    else:  # 20% acceptable (6-7)
        base = 6.0
        variance = 1.0

    accuracy = round(base + random.random() * variance, 1)
    relevance = round(base + random.random() * variance, 1)
    helpfulness = round(base + random.random() * variance, 1)
    coherence = round(base + random.random() * variance, 1)

    # Ensure scores don't exceed 10.0
    accuracy = min(accuracy, 10.0)
    relevance = min(relevance, 10.0)
    helpfulness = min(helpfulness, 10.0)
    coherence = min(coherence, 10.0)

    overall = round((accuracy + relevance + helpfulness + coherence) / 4.0, 1)

    return accuracy, relevance, helpfulness, coherence, overall


async def main():
    print(f"Connecting to databases...")

    # Connect to both databases
    timescale_conn = await asyncpg.connect(TIMESCALE_URL)
    postgres_conn = await asyncpg.connect(POSTGRES_URL)

    try:
        print(f"Fetching {NUM_EVALUATIONS} random successful trace IDs...")

        # Get random successful trace IDs with their timestamps
        traces = await timescale_conn.fetch("""
            SELECT trace_id, timestamp
            FROM traces
            WHERE workspace_id = $1
            AND status = 'success'
            ORDER BY RANDOM()
            LIMIT $2
        """, WORKSPACE_ID, NUM_EVALUATIONS)

        print(f"Found {len(traces)} traces. Generating evaluations...")

        # Generate and insert evaluations
        for i, trace in enumerate(traces, 1):
            trace_id = trace['trace_id']
            trace_timestamp = trace['timestamp']

            # Evaluation happens 1-60 minutes after trace
            eval_timestamp = trace_timestamp + timedelta(minutes=random.randint(1, 60))

            # Select random evaluator
            evaluator = random.choice(EVALUATORS)

            # Generate scores
            accuracy, relevance, helpfulness, coherence, overall = generate_scores()

            # Select random reasoning
            reasoning = random.choice(REASONING_TEMPLATES)

            # Build metadata
            metadata = {
                'model_version': 'gemini-1.5-pro' if evaluator == 'gemini' else ('custom-evaluator-v1' if evaluator == 'custom_model' else 'manual'),
                'confidence': round(0.85 + random.random() * 0.15, 3),
                'evaluation_duration_ms': random.randint(1000, 5000)
            }

            # Insert evaluation
            await postgres_conn.execute("""
                INSERT INTO evaluations (
                    id, workspace_id, trace_id, created_at, evaluator,
                    accuracy_score, relevance_score, helpfulness_score, coherence_score, overall_score,
                    reasoning, metadata
                ) VALUES (
                    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
                )
            """, uuid4(), WORKSPACE_ID, trace_id, eval_timestamp, evaluator,
                accuracy, relevance, helpfulness, coherence, overall,
                reasoning, json.dumps(metadata))

            if i % 100 == 0:
                print(f"Generated {i} evaluations...")

        print(f"\n✅ Successfully generated {len(traces)} evaluation records!\n")

        # Show verification statistics
        print("Verification Statistics:")
        print("=" * 60)

        stats = await postgres_conn.fetch("""
            SELECT
                COUNT(*) as total_evaluations,
                ROUND(AVG(overall_score)::numeric, 2) as avg_overall_score,
                ROUND(AVG(accuracy_score)::numeric, 2) as avg_accuracy,
                ROUND(AVG(relevance_score)::numeric, 2) as avg_relevance,
                ROUND(AVG(helpfulness_score)::numeric, 2) as avg_helpfulness,
                ROUND(AVG(coherence_score)::numeric, 2) as avg_coherence,
                evaluator,
                COUNT(*) as count_by_evaluator
            FROM evaluations
            WHERE workspace_id = $1
            GROUP BY evaluator
            ORDER BY evaluator
        """, WORKSPACE_ID)

        for row in stats:
            print(f"\nEvaluator: {row['evaluator']}")
            print(f"  Count: {row['count_by_evaluator']}")
            print(f"  Avg Overall Score: {row['avg_overall_score']}")
            print(f"  Avg Accuracy: {row['avg_accuracy']}")
            print(f"  Avg Relevance: {row['avg_relevance']}")
            print(f"  Avg Helpfulness: {row['avg_helpfulness']}")
            print(f"  Avg Coherence: {row['avg_coherence']}")

        # Show score distribution
        print("\n" + "=" * 60)
        print("Score Distribution:")
        print("=" * 60)

        distribution = await postgres_conn.fetch("""
            SELECT
                CASE
                    WHEN overall_score >= 9.0 THEN '9.0-10.0 (Excellent)'
                    WHEN overall_score >= 7.0 THEN '7.0-8.9 (Good)'
                    WHEN overall_score >= 6.0 THEN '6.0-6.9 (Acceptable)'
                    ELSE 'Below 6.0'
                END as score_range,
                COUNT(*) as count,
                ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as percentage
            FROM evaluations
            WHERE workspace_id = $1
            GROUP BY score_range
            ORDER BY score_range DESC
        """, WORKSPACE_ID)

        for row in distribution:
            print(f"{row['score_range']:25} {row['count']:4} ({row['percentage']:5}%)")

    finally:
        await timescale_conn.close()
        await postgres_conn.close()
        print("\n✅ Database connections closed.")


if __name__ == "__main__":
    asyncio.run(main())
