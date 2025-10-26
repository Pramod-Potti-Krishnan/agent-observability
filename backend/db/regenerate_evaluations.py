#!/usr/bin/env python3
"""
Regenerate evaluation data spread across 7 days
Connects to both TimescaleDB (for traces) and PostgreSQL (for evaluations)
"""

import psycopg2
import random
from datetime import datetime, timedelta
from uuid import uuid4

# Database connection strings
TIMESCALE_CONN = "postgresql://postgres:postgres@localhost:5432/agent_observability"
POSTGRES_CONN = "postgresql://postgres:postgres@localhost:5433/agent_observability_metadata"

WORKSPACE_ID = "37160be9-7d69-43b5-8d5f-9d7b5e14a57a"
BASE_DATE = datetime(2025, 10, 16, 0, 0, 0)

EVALUATORS = ['gemini', 'gemini', 'gemini', 'human', 'custom_model']

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

def get_trace_ids():
    """Fetch 1000 random successful trace IDs from TimescaleDB"""
    print("Connecting to TimescaleDB...")
    conn = psycopg2.connect(TIMESCALE_CONN)
    cur = conn.cursor()

    cur.execute("""
        SELECT trace_id
        FROM traces
        WHERE workspace_id = %s
        AND status = 'success'
        ORDER BY RANDOM()
        LIMIT 1000
    """, (WORKSPACE_ID,))

    trace_ids = [row[0] for row in cur.fetchall()]

    cur.close()
    conn.close()

    print(f"Found {len(trace_ids)} trace IDs")
    return trace_ids

def generate_scores():
    """Generate realistic quality scores biased toward good quality"""
    rand = random.random()

    if rand < 0.2:
        # Excellent scores (9-10)
        base = 9.0
        range_val = 1.0
    elif rand < 0.8:
        # Good scores (7-9)
        base = 7.0
        range_val = 2.0
    else:
        # Acceptable scores (6-7)
        base = 6.0
        range_val = 1.0

    accuracy = round(base + random.random() * range_val, 1)
    relevance = round(base + random.random() * range_val, 1)
    helpfulness = round(base + random.random() * range_val, 1)
    coherence = round(base + random.random() * range_val, 1)
    overall = round((accuracy + relevance + helpfulness + coherence) / 4.0, 1)

    return accuracy, relevance, helpfulness, coherence, overall

def create_evaluations(trace_ids):
    """Create evaluation records in PostgreSQL"""
    print("Connecting to PostgreSQL...")
    conn = psycopg2.connect(POSTGRES_CONN)
    cur = conn.cursor()

    evals_per_day = len(trace_ids) / 7.0

    for i, trace_id in enumerate(trace_ids):
        # Calculate which day (0-6)
        day_offset = min(int(i / evals_per_day), 6)

        # Generate timestamp within that day
        timestamp = BASE_DATE + timedelta(
            days=day_offset,
            hours=random.randint(0, 23),
            minutes=random.randint(0, 59)
        )

        # Select evaluator
        evaluator = random.choice(EVALUATORS)

        # Generate scores
        accuracy, relevance, helpfulness, coherence, overall = generate_scores()

        # Select reasoning
        reasoning = random.choice(REASONING_TEMPLATES)

        # Create metadata
        model_version = 'gemini-1.5-pro' if evaluator == 'gemini' else ('custom-evaluator-v1' if evaluator == 'custom_model' else 'manual')
        confidence = round(0.85 + random.random() * 0.15, 2)
        duration_ms = random.randint(1000, 5000)

        metadata = {
            'model_version': model_version,
            'confidence': confidence,
            'evaluation_duration_ms': duration_ms
        }

        # Insert evaluation
        cur.execute("""
            INSERT INTO evaluations (
                id, workspace_id, trace_id, created_at, evaluator,
                accuracy_score, relevance_score, helpfulness_score,
                coherence_score, overall_score, reasoning, metadata
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s::jsonb
            )
        """, (
            str(uuid4()), WORKSPACE_ID, trace_id, timestamp, evaluator,
            accuracy, relevance, helpfulness, coherence, overall,
            reasoning, str(metadata).replace("'", '"')
        ))

        if (i + 1) % 100 == 0:
            print(f"Generated {i + 1} evaluations...")
            conn.commit()

    conn.commit()
    print(f"Successfully created {len(trace_ids)} evaluations")

    # Verification
    cur.execute("""
        SELECT
            DATE(created_at) as eval_date,
            COUNT(*) as count,
            ROUND(AVG(overall_score), 2) as avg_score
        FROM evaluations
        WHERE workspace_id = %s
        GROUP BY DATE(created_at)
        ORDER BY eval_date
    """, (WORKSPACE_ID,))

    print("\n=== Distribution by Date ===")
    for row in cur.fetchall():
        print(f"{row[0]}: {row[1]} evaluations, avg score {row[2]}")

    cur.close()
    conn.close()

def main():
    try:
        trace_ids = get_trace_ids()
        create_evaluations(trace_ids)
        print("\n✓ Evaluation data regenerated successfully!")
    except Exception as e:
        print(f"\n✗ Error: {e}")
        raise

if __name__ == "__main__":
    main()
