"""Database connection management for Evaluation Service"""
import asyncpg
from typing import Optional
from .config import get_settings

settings = get_settings()

# Global connection pool
_postgres_pool: Optional[asyncpg.Pool] = None


async def get_postgres_pool() -> asyncpg.Pool:
    """Get or create PostgreSQL connection pool"""
    global _postgres_pool

    if _postgres_pool is None:
        _postgres_pool = await asyncpg.create_pool(
            settings.postgres_url,
            min_size=5,
            max_size=20,
            command_timeout=60
        )

    return _postgres_pool


async def close_postgres_pool():
    """Close PostgreSQL connection pool"""
    global _postgres_pool

    if _postgres_pool is not None:
        await _postgres_pool.close()
        _postgres_pool = None


async def get_trace_by_id(pool: asyncpg.Pool, workspace_id: str, trace_id: str) -> Optional[dict]:
    """Get trace data by ID"""
    query = """
        SELECT trace_id, agent_id, input, output, status, timestamp
        FROM traces
        WHERE workspace_id = $1 AND trace_id = $2
        ORDER BY timestamp DESC
        LIMIT 1
    """

    row = await pool.fetchrow(query, workspace_id, trace_id)

    if row:
        return {
            'trace_id': row['trace_id'],
            'agent_id': row['agent_id'],
            'input': row['input'],
            'output': row['output'],
            'status': row['status'],
            'timestamp': row['timestamp']
        }

    return None


async def save_evaluation(
    pool: asyncpg.Pool,
    workspace_id: str,
    trace_id: str,
    evaluator: str,
    scores: dict,
    reasoning: str,
    metadata: dict,
    agent_id: Optional[str] = None
) -> str:
    """Save evaluation to database with agent_id"""
    query = """
        INSERT INTO evaluations (
            id,
            workspace_id,
            trace_id,
            agent_id,
            created_at,
            evaluator,
            accuracy_score,
            relevance_score,
            helpfulness_score,
            coherence_score,
            overall_score,
            reasoning,
            metadata
        ) VALUES (
            uuid_generate_v4(),
            $1, $2, $3, NOW(), $4, $5, $6, $7, $8, $9, $10, $11
        )
        RETURNING id
    """

    evaluation_id = await pool.fetchval(
        query,
        workspace_id,
        trace_id,
        agent_id,
        evaluator,
        scores['accuracy_score'],
        scores['relevance_score'],
        scores['helpfulness_score'],
        scores['coherence_score'],
        scores['overall_score'],
        reasoning,
        metadata
    )

    return str(evaluation_id)


async def get_evaluation_history(
    pool: asyncpg.Pool,
    workspace_id: str,
    limit: int = 100,
    offset: int = 0
) -> list:
    """Get evaluation history for workspace"""
    query = """
        SELECT
            id,
            workspace_id,
            trace_id,
            created_at,
            evaluator,
            accuracy_score,
            relevance_score,
            helpfulness_score,
            coherence_score,
            overall_score,
            reasoning,
            metadata
        FROM evaluations
        WHERE workspace_id = $1
        ORDER BY created_at DESC
        LIMIT $2 OFFSET $3
    """

    rows = await pool.fetch(query, workspace_id, limit, offset)

    return [dict(row) for row in rows]


async def get_evaluation_stats(pool: asyncpg.Pool, workspace_id: str) -> dict:
    """Get evaluation statistics"""
    query = """
        SELECT
            COUNT(*) as total,
            AVG(overall_score) as avg_overall_score,
            AVG(accuracy_score) as avg_accuracy_score,
            AVG(relevance_score) as avg_relevance_score,
            AVG(helpfulness_score) as avg_helpfulness_score,
            AVG(coherence_score) as avg_coherence_score
        FROM evaluations
        WHERE workspace_id = $1
    """

    row = await pool.fetchrow(query, workspace_id)

    return {
        'total': row['total'] or 0,
        'avg_overall_score': float(row['avg_overall_score'] or 0),
        'avg_accuracy_score': float(row['avg_accuracy_score'] or 0),
        'avg_relevance_score': float(row['avg_relevance_score'] or 0),
        'avg_helpfulness_score': float(row['avg_helpfulness_score'] or 0),
        'avg_coherence_score': float(row['avg_coherence_score'] or 0)
    }
