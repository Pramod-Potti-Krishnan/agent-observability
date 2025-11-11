#!/usr/bin/env python3
"""
Quality Monitoring Synthetic Data Generation
Generates realistic evaluation data for quality monitoring features
"""

import asyncio
import asyncpg
import random
from datetime import datetime, timedelta
from uuid import uuid4
import math

# Configuration
TIMESCALEDB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'user': 'postgres',
    'password': 'postgres',
    'database': 'agent_observability'
}

POSTGRES_CONFIG = {
    'host': 'localhost',
    'port': 5433,
    'user': 'postgres',
    'password': 'postgres',
    'database': 'agent_observability_metadata'
}

# Evaluation methods
EVALUATORS = ['llm-as-judge', 'human-review', 'rule-based', 'automated-test']

# Quality tier definitions
QUALITY_TIERS = {
    'excellent': (9.0, 10.0),   # 20% of evaluations
    'good': (7.0, 8.9),          # 40% of evaluations
    'fair': (5.0, 6.9),          # 25% of evaluations
    'poor': (3.0, 4.9),          # 10% of evaluations
    'failing': (0.0, 2.9)        # 5% of evaluations
}

# Agent quality profiles (for realistic distribution)
AGENT_QUALITY_PROFILES = {
    'high_performer': {
        'tier_distribution': {'excellent': 0.50, 'good': 0.40, 'fair': 0.08, 'poor': 0.02, 'failing': 0.00},
        'criteria_variance': 0.3  # Low variance across criteria
    },
    'average_performer': {
        'tier_distribution': {'excellent': 0.15, 'good': 0.45, 'fair': 0.30, 'poor': 0.08, 'failing': 0.02},
        'criteria_variance': 0.5  # Medium variance
    },
    'struggling_performer': {
        'tier_distribution': {'excellent': 0.05, 'good': 0.15, 'fair': 0.30, 'poor': 0.35, 'failing': 0.15},
        'criteria_variance': 0.8  # High variance
    }
}

# Criteria correlation patterns (some criteria correlate)
CRITERIA_CORRELATIONS = {
    'accuracy': ['relevance', 'coherence'],  # Accuracy correlates with relevance and coherence
    'relevance': ['accuracy', 'helpfulness'],
    'helpfulness': ['relevance'],
    'coherence': ['accuracy']
}


def select_quality_tier(profile):
    """Select quality tier based on agent profile"""
    dist = AGENT_QUALITY_PROFILES[profile]['tier_distribution']
    tiers = list(dist.keys())
    weights = list(dist.values())
    return random.choices(tiers, weights=weights)[0]


def generate_score_in_tier(tier):
    """Generate a score within a quality tier range"""
    min_score, max_score = QUALITY_TIERS[tier]
    return round(random.uniform(min_score, max_score), 1)


def generate_criteria_scores(overall_score, profile):
    """Generate individual criteria scores correlated with overall score"""
    variance = AGENT_QUALITY_PROFILES[profile]['criteria_variance']

    # Base scores around overall score with variance
    criteria_scores = {}
    for criterion in ['accuracy', 'relevance', 'helpfulness', 'coherence']:
        # Add some variance but keep generally correlated
        deviation = random.gauss(0, variance)
        score = overall_score + deviation
        # Clamp to valid range
        score = max(0.0, min(10.0, score))
        criteria_scores[criterion] = round(score, 1)

    return criteria_scores


def generate_reasoning(overall_score, criteria_scores):
    """Generate evaluation reasoning text"""
    if overall_score >= 9.0:
        templates = [
            "Excellent response quality. All criteria met with high accuracy and relevance.",
            "Outstanding performance. Response demonstrates deep understanding and coherence.",
            "Exemplary output. Highly accurate, relevant, and helpful to the user."
        ]
    elif overall_score >= 7.0:
        templates = [
            "Good response quality. Most criteria met with minor areas for improvement.",
            "Solid performance. Response is accurate and helpful with good coherence.",
            "Above average output. Relevant and well-structured with acceptable accuracy."
        ]
    elif overall_score >= 5.0:
        templates = [
            "Fair response quality. Some criteria met but needs improvement in accuracy.",
            "Moderate performance. Response partially addresses the query.",
            "Acceptable output but lacks depth in some areas."
        ]
    elif overall_score >= 3.0:
        templates = [
            "Poor response quality. Multiple criteria not met. Significant improvements needed.",
            "Below average performance. Response lacks accuracy and relevance.",
            "Inadequate output. Does not sufficiently address user needs."
        ]
    else:
        templates = [
            "Failing response quality. Critical issues with accuracy and relevance.",
            "Unacceptable performance. Response is incoherent or completely irrelevant.",
            "Critical quality issues. Does not meet minimum standards."
        ]

    return random.choice(templates)


async def get_workspace_and_traces(conn):
    """Get workspace_id and trace_ids from existing data"""
    # Get traces with workspace_id
    traces = await conn.fetch("""
        SELECT trace_id, agent_id, timestamp, cost_usd, workspace_id
        FROM traces
        ORDER BY timestamp DESC
        LIMIT 1000
    """)

    if not traces:
        raise Exception("No traces found. Run generate_phase1_synthetic_data.py first")

    # Get workspace_id from first trace
    workspace_id = traces[0]['workspace_id']

    return workspace_id, traces


async def assign_agent_profiles(traces):
    """Assign quality profiles to agents based on realistic distribution"""
    agent_profiles = {}
    unique_agents = set(trace['agent_id'] for trace in traces)

    # Distribute agents across profiles (60% average, 25% high, 15% struggling)
    for agent_id in unique_agents:
        rand = random.random()
        if rand < 0.25:
            profile = 'high_performer'
        elif rand < 0.85:
            profile = 'average_performer'
        else:
            profile = 'struggling_performer'

        agent_profiles[agent_id] = profile

    return agent_profiles


async def generate_evaluations(conn, workspace_id, traces, agent_profiles):
    """Generate synthetic evaluation data"""
    evaluations = []

    print(f"Generating evaluations for {len(traces)} traces...")

    for i, trace in enumerate(traces):
        if i % 100 == 0:
            print(f"  Progress: {i}/{len(traces)} evaluations")

        trace_id = trace['trace_id']
        agent_id = trace['agent_id']
        timestamp = trace['timestamp']

        # Get agent profile
        profile = agent_profiles.get(agent_id, 'average_performer')

        # Select quality tier and generate overall score
        tier = select_quality_tier(profile)
        overall_score = generate_score_in_tier(tier)

        # Generate criteria scores
        criteria = generate_criteria_scores(overall_score, profile)

        # Generate reasoning
        reasoning = generate_reasoning(overall_score, criteria)

        # Select evaluator (LLM-as-judge more common)
        evaluator_weights = [0.70, 0.15, 0.10, 0.05]
        evaluator = random.choices(EVALUATORS, weights=evaluator_weights)[0]

        # Create evaluation timestamp slightly after trace
        eval_timestamp = timestamp + timedelta(seconds=random.randint(10, 300))

        evaluation = {
            'id': uuid4(),
            'workspace_id': workspace_id,
            'trace_id': trace_id,
            'created_at': eval_timestamp,
            'evaluator': evaluator,
            'accuracy_score': criteria['accuracy'],
            'relevance_score': criteria['relevance'],
            'helpfulness_score': criteria['helpfulness'],
            'coherence_score': criteria['coherence'],
            'overall_score': overall_score,
            'reasoning': reasoning,
            'metadata': {}
        }

        evaluations.append(evaluation)

    return evaluations


async def insert_evaluations(conn, evaluations):
    """Bulk insert evaluations into database"""
    print(f"\nInserting {len(evaluations)} evaluations...")

    # Prepare bulk insert
    records = [
        (
            e['id'], e['workspace_id'], e['trace_id'], e['created_at'],
            e['evaluator'], e['accuracy_score'], e['relevance_score'],
            e['helpfulness_score'], e['coherence_score'], e['overall_score'],
            e['reasoning'], '{}'
        )
        for e in evaluations
    ]

    # Insert in batches of 100
    batch_size = 100
    for i in range(0, len(records), batch_size):
        batch = records[i:i + batch_size]
        await conn.executemany("""
            INSERT INTO evaluations (
                id, workspace_id, trace_id, created_at, evaluator,
                accuracy_score, relevance_score, helpfulness_score,
                coherence_score, overall_score, reasoning, metadata
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            ON CONFLICT (id) DO NOTHING
        """, batch)

        if (i + batch_size) % 500 == 0:
            print(f"  Inserted {min(i + batch_size, len(records))}/{len(records)} evaluations")

    print(f"  Completed inserting {len(records)} evaluations")


async def print_statistics(conn, workspace_id):
    """Print quality data statistics"""
    print("\n" + "="*60)
    print("QUALITY DATA STATISTICS")
    print("="*60)

    # Overall stats
    stats = await conn.fetchrow("""
        SELECT
            COUNT(*) as total_evals,
            ROUND(AVG(overall_score)::numeric, 2) as avg_score,
            ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY overall_score)::numeric, 2) as median_score,
            COUNT(DISTINCT CASE WHEN overall_score >= 9.0 THEN 1 END) as excellent,
            COUNT(DISTINCT CASE WHEN overall_score >= 7.0 AND overall_score < 9.0 THEN 1 END) as good,
            COUNT(DISTINCT CASE WHEN overall_score >= 5.0 AND overall_score < 7.0 THEN 1 END) as fair,
            COUNT(DISTINCT CASE WHEN overall_score >= 3.0 AND overall_score < 5.0 THEN 1 END) as poor,
            COUNT(DISTINCT CASE WHEN overall_score < 3.0 THEN 1 END) as failing
        FROM evaluations
        WHERE workspace_id = $1
    """, workspace_id)

    print(f"\nOverall Quality Metrics:")
    print(f"  Total Evaluations: {stats['total_evals']}")
    print(f"  Average Score: {stats['avg_score']}")
    print(f"  Median Score: {stats['median_score']}")
    print(f"\nQuality Tier Distribution:")
    print(f"  Excellent (9.0-10.0): {stats['excellent']}")
    print(f"  Good (7.0-8.9): {stats['good']}")
    print(f"  Fair (5.0-6.9): {stats['fair']}")
    print(f"  Poor (3.0-4.9): {stats['poor']}")
    print(f"  Failing (0.0-2.9): {stats['failing']}")

    # Agent-level stats
    agent_stats = await conn.fetch("""
        SELECT
            t.agent_id,
            ROUND(AVG(e.overall_score)::numeric, 2) as avg_score,
            COUNT(*) as eval_count,
            ROUND((COUNT(CASE WHEN e.overall_score < 5.0 THEN 1 END)::float / COUNT(*) * 100)::numeric, 1) as failing_rate
        FROM evaluations e
        JOIN traces t ON e.trace_id = t.trace_id
        WHERE e.workspace_id = $1
        GROUP BY t.agent_id
        ORDER BY avg_score ASC
        LIMIT 10
    """, workspace_id)

    print(f"\nTop 10 Struggling Agents:")
    for row in agent_stats:
        print(f"  {row['agent_id']}: avg={row['avg_score']}, failing_rate={row['failing_rate']}%, evals={row['eval_count']}")

    # Evaluator distribution
    evaluator_stats = await conn.fetch("""
        SELECT evaluator, COUNT(*) as count
        FROM evaluations
        WHERE workspace_id = $1
        GROUP BY evaluator
        ORDER BY count DESC
    """, workspace_id)

    print(f"\nEvaluator Distribution:")
    for row in evaluator_stats:
        print(f"  {row['evaluator']}: {row['count']} evaluations")

    print("\n" + "="*60)


async def main():
    """Main execution function"""
    print("="*60)
    print("QUALITY MONITORING SYNTHETIC DATA GENERATOR")
    print("="*60)

    # Connect to both databases
    print("\nConnecting to databases...")
    timescale_conn = await asyncpg.connect(**TIMESCALEDB_CONFIG)
    postgres_conn = await asyncpg.connect(**POSTGRES_CONFIG)

    try:
        # Get workspace and traces from TimescaleDB
        print("\nFetching workspace and traces from TimescaleDB...")
        workspace_id, traces = await get_workspace_and_traces(timescale_conn)
        print(f"  Workspace ID: {workspace_id}")
        print(f"  Found {len(traces)} traces to evaluate")

        # Assign quality profiles to agents
        print("\nAssigning quality profiles to agents...")
        agent_profiles = await assign_agent_profiles(traces)
        print(f"  Assigned profiles to {len(agent_profiles)} agents")

        # Count profile distribution
        profile_counts = {}
        for profile in agent_profiles.values():
            profile_counts[profile] = profile_counts.get(profile, 0) + 1
        print(f"  Profile distribution: {profile_counts}")

        # Generate evaluations
        evaluations = await generate_evaluations(timescale_conn, workspace_id, traces, agent_profiles)

        # Insert evaluations into Postgres
        await insert_evaluations(postgres_conn, evaluations)

        # Print statistics from Postgres
        await print_statistics(postgres_conn, workspace_id)

        print("\n✓ Quality synthetic data generation complete!")

    except Exception as e:
        print(f"\n✗ Error: {e}")
        raise
    finally:
        await timescale_conn.close()
        await postgres_conn.close()
        print("\nDatabase connections closed.")


if __name__ == "__main__":
    asyncio.run(main())
