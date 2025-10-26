"""Load synthetic data into TimescaleDB and PostgreSQL databases.

This script loads the generated synthetic data into the databases for testing.
"""

import os
import json
import asyncio
import asyncpg
from datetime import datetime
from typing import List, Dict, Any
from dotenv import load_dotenv

load_dotenv()


async def load_traces_to_timescaledb(traces: List[Dict[str, Any]]):
    """Load traces into TimescaleDB."""
    timescale_url = os.getenv('TIMESCALE_URL', 'postgresql://postgres:postgres@localhost:5432/agent_observability')

    print(f"\nConnecting to TimescaleDB: {timescale_url}")
    conn = await asyncpg.connect(timescale_url)

    try:
        print(f"Loading {len(traces)} traces into TimescaleDB...")

        # Batch insert for performance
        batch_size = 1000
        for i in range(0, len(traces), batch_size):
            batch = traces[i:i + batch_size]

            values = []
            for trace in batch:
                values.append((
                    trace['trace_id'],
                    trace['workspace_id'],
                    trace['agent_id'],
                    datetime.fromisoformat(trace['timestamp'].replace('Z', '+00:00')),
                    trace['latency_ms'],
                    trace.get('input'),
                    trace.get('output'),
                    trace.get('error'),
                    trace['status'],
                    trace['model'],
                    trace['model_provider'],
                    trace.get('tokens_input'),
                    trace.get('tokens_output'),
                    trace.get('tokens_total'),
                    trace.get('cost_usd'),
                    json.dumps(trace.get('metadata', {})),
                    trace.get('tags', []),
                ))

            await conn.executemany('''
                INSERT INTO traces (
                    trace_id, workspace_id, agent_id, timestamp, latency_ms,
                    input, output, error, status, model, model_provider,
                    tokens_input, tokens_output, tokens_total, cost_usd,
                    metadata, tags
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
                ON CONFLICT (trace_id, timestamp) DO NOTHING
            ''', values)

            print(f"  Loaded batch {i // batch_size + 1}/{(len(traces) - 1) // batch_size + 1}")

        # Verify count
        count = await conn.fetchval('SELECT COUNT(*) FROM traces')
        print(f"✅ Loaded traces. Total count in database: {count}")

    finally:
        await conn.close()


async def load_events_to_timescaledb(events: List[Dict[str, Any]]):
    """Load events into TimescaleDB."""
    timescale_url = os.getenv('TIMESCALE_URL', 'postgresql://postgres:postgres@localhost:5432/agent_observability')

    conn = await asyncpg.connect(timescale_url)

    try:
        print(f"\nLoading {len(events)} events into TimescaleDB...")

        values = []
        for event in events:
            values.append((
                event['event_id'],
                datetime.fromisoformat(event['timestamp'].replace('Z', '+00:00')),
                event['workspace_id'],
                event.get('agent_id'),
                event['event_type'],
                event['severity'],
                event['title'],
                event.get('description'),
                json.dumps(event.get('metadata', {})),
                event.get('acknowledged', False),
                None,  # acknowledged_at
                None,  # acknowledged_by
            ))

        await conn.executemany('''
            INSERT INTO events (
                event_id, timestamp, workspace_id, agent_id, event_type,
                severity, title, description, metadata, acknowledged,
                acknowledged_at, acknowledged_by
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            ON CONFLICT (event_id, timestamp) DO NOTHING
        ''', values)

        count = await conn.fetchval('SELECT COUNT(*) FROM events')
        print(f"✅ Loaded events. Total count in database: {count}")

    finally:
        await conn.close()


async def generate_and_load_sample_evaluations():
    """Generate and load sample evaluations into PostgreSQL."""
    postgres_url = os.getenv('POSTGRES_URL', 'postgresql://postgres:postgres@localhost:5433/agent_observability_metadata')
    timescale_url = os.getenv('TIMESCALE_URL', 'postgresql://postgres:postgres@localhost:5432/agent_observability')

    # Get some trace IDs from TimescaleDB
    timescale_conn = await asyncpg.connect(timescale_url)
    trace_ids = await timescale_conn.fetch('SELECT trace_id FROM traces LIMIT 100')
    await timescale_conn.close()

    if not trace_ids:
        print("No traces found. Skipping evaluation generation.")
        return

    postgres_conn = await asyncpg.connect(postgres_url)

    try:
        print(f"\nGenerating evaluations for {len(trace_ids)} traces...")

        import random
        values = []
        for row in trace_ids:
            trace_id = row['trace_id']
            # Generate realistic scores
            accuracy = round(random.uniform(6.5, 9.5), 1)
            relevance = round(random.uniform(7.0, 10.0), 1)
            helpfulness = round(random.uniform(6.0, 9.5), 1)
            coherence = round(random.uniform(7.5, 10.0), 1)
            overall = round((accuracy + relevance + helpfulness + coherence) / 4, 1)

            values.append((
                '00000000-0000-0000-0000-000000000001',  # workspace_id
                trace_id,
                'gemini',  # evaluator
                accuracy,
                relevance,
                helpfulness,
                coherence,
                overall,
                f"Generated evaluation with scores: accuracy={accuracy}, relevance={relevance}",
                json.dumps({"model": "gemini-pro", "version": "1.0"}),
            ))

        await postgres_conn.executemany('''
            INSERT INTO evaluations (
                workspace_id, trace_id, evaluator,
                accuracy_score, relevance_score, helpfulness_score,
                coherence_score, overall_score, reasoning, metadata
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        ''', values)

        count = await postgres_conn.fetchval('SELECT COUNT(*) FROM evaluations')
        print(f"✅ Loaded evaluations. Total count: {count}")

    finally:
        await postgres_conn.close()


async def main():
    """Main function to load all synthetic data."""
    print("=" * 60)
    print("Loading Synthetic Data into Databases")
    print("=" * 60)

    # Load traces
    if os.path.exists('synthetic_traces.json'):
        with open('synthetic_traces.json', 'r') as f:
            traces = json.load(f)
        await load_traces_to_timescaledb(traces)
    else:
        print("⚠️  synthetic_traces.json not found. Run generator.py first.")

    # Load events
    if os.path.exists('synthetic_events.json'):
        with open('synthetic_events.json', 'r') as f:
            events = json.load(f)
        await load_events_to_timescaledb(events)
    else:
        print("⚠️  synthetic_events.json not found. Run generator.py first.")

    # Generate and load evaluations
    await generate_and_load_sample_evaluations()

    print("\n" + "=" * 60)
    print("✅ Data loading complete!")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
