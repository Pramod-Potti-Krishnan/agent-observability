#!/usr/bin/env python3
"""
Backfill agent_id in evaluations table from traces table
This script connects to both PostgreSQL and TimescaleDB to populate agent_id
"""
import asyncio
import asyncpg
import os
from datetime import datetime

# Database connection URLs (from environment or defaults)
POSTGRES_URL = os.getenv('POSTGRES_URL', 'postgresql://postgres:postgres@localhost:5433/agent_observability_metadata')
TIMESCALE_URL = os.getenv('TIMESCALE_URL', 'postgresql://postgres:postgres@localhost:5432/agent_observability')


async def backfill_agent_ids():
    """Backfill agent_id from traces to evaluations"""

    print("=" * 60)
    print("Backfill Agent IDs")
    print("=" * 60)
    print(f"Started at: {datetime.now()}")
    print()

    # Connect to both databases
    print("Connecting to databases...")
    postgres_pool = await asyncpg.create_pool(POSTGRES_URL, min_size=1, max_size=5)
    timescale_pool = await asyncpg.create_pool(TIMESCALE_URL, min_size=1, max_size=5)

    try:
        # Get current state
        print("\n1. Checking current state...")
        current_state = await postgres_pool.fetchrow("""
            SELECT
                COUNT(*) as total_evaluations,
                COUNT(agent_id) as evaluations_with_agent_id,
                COUNT(*) - COUNT(agent_id) as missing_agent_id
            FROM evaluations
        """)

        total = current_state['total_evaluations']
        with_agent = current_state['evaluations_with_agent_id']
        missing = current_state['missing_agent_id']

        print(f"   Total evaluations: {total}")
        print(f"   With agent_id: {with_agent} ({with_agent/max(total,1)*100:.1f}%)")
        print(f"   Missing agent_id: {missing} ({missing/max(total,1)*100:.1f}%)")

        if missing == 0:
            print("\n✓ All evaluations already have agent_id. Nothing to do!")
            return

        # Get evaluations that need agent_id
        print(f"\n2. Fetching {missing} evaluations without agent_id...")
        evaluations_to_update = await postgres_pool.fetch("""
            SELECT trace_id, workspace_id
            FROM evaluations
            WHERE agent_id IS NULL
        """)

        print(f"   Found {len(evaluations_to_update)} evaluations to backfill")

        # Get agent_ids from traces for these evaluations
        print("\n3. Fetching agent_ids from traces...")
        trace_ids = [e['trace_id'] for e in evaluations_to_update]

        # Query traces in batches
        batch_size = 1000
        agent_id_map = {}

        for i in range(0, len(trace_ids), batch_size):
            batch = trace_ids[i:i+batch_size]
            traces = await timescale_pool.fetch("""
                SELECT DISTINCT trace_id, agent_id
                FROM traces
                WHERE trace_id = ANY($1)
                AND agent_id IS NOT NULL
            """, batch)

            for trace in traces:
                agent_id_map[trace['trace_id']] = trace['agent_id']

            print(f"   Processed {min(i+batch_size, len(trace_ids))}/{len(trace_ids)} traces...")

        print(f"   Found agent_id for {len(agent_id_map)} traces")

        # Update evaluations with agent_ids
        print("\n4. Updating evaluations...")
        updated_count = 0
        skipped_count = 0

        for evaluation in evaluations_to_update:
            trace_id = evaluation['trace_id']
            workspace_id = evaluation['workspace_id']
            agent_id = agent_id_map.get(trace_id)

            if agent_id:
                await postgres_pool.execute("""
                    UPDATE evaluations
                    SET agent_id = $1
                    WHERE trace_id = $2 AND workspace_id = $3 AND agent_id IS NULL
                """, agent_id, trace_id, workspace_id)
                updated_count += 1

                if updated_count % 100 == 0:
                    print(f"   Updated {updated_count} evaluations...")
            else:
                skipped_count += 1

        print(f"   Completed: {updated_count} updated, {skipped_count} skipped (no matching trace)")

        # Verify results
        print("\n5. Verifying results...")
        final_state = await postgres_pool.fetchrow("""
            SELECT
                COUNT(*) as total_evaluations,
                COUNT(agent_id) as evaluations_with_agent_id,
                COUNT(*) - COUNT(agent_id) as missing_agent_id
            FROM evaluations
        """)

        final_total = final_state['total_evaluations']
        final_with_agent = final_state['evaluations_with_agent_id']
        final_missing = final_state['missing_agent_id']

        print(f"   Total evaluations: {final_total}")
        print(f"   With agent_id: {final_with_agent} ({final_with_agent/max(final_total,1)*100:.1f}%)")
        print(f"   Missing agent_id: {final_missing} ({final_missing/max(final_total,1)*100:.1f}%)")

        # Show breakdown by agent
        print("\n6. Evaluations per agent:")
        agent_breakdown = await postgres_pool.fetch("""
            SELECT
                agent_id,
                COUNT(*) as evaluation_count,
                MIN(created_at) as first_evaluation,
                MAX(created_at) as last_evaluation
            FROM evaluations
            WHERE agent_id IS NOT NULL
            GROUP BY agent_id
            ORDER BY evaluation_count DESC
            LIMIT 10
        """)

        if agent_breakdown:
            print(f"   {'Agent ID':<40} {'Count':>8} {'First':>12} {'Last':>12}")
            print("   " + "-" * 80)
            for row in agent_breakdown:
                first = row['first_evaluation'].strftime('%Y-%m-%d') if row['first_evaluation'] else 'N/A'
                last = row['last_evaluation'].strftime('%Y-%m-%d') if row['last_evaluation'] else 'N/A'
                print(f"   {row['agent_id']:<40} {row['evaluation_count']:>8} {first:>12} {last:>12}")
        else:
            print("   No evaluations found with agent_id")

        print("\n" + "=" * 60)
        print("✓ Backfill Complete!")
        print(f"Finished at: {datetime.now()}")
        print("=" * 60)

    finally:
        await postgres_pool.close()
        await timescale_pool.close()


if __name__ == "__main__":
    asyncio.run(backfill_agent_ids())
