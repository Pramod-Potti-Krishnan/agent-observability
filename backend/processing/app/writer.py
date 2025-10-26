"""TimescaleDB writer for processed traces"""
import asyncpg
import json
import logging
import os
from typing import Optional

logger = logging.getLogger(__name__)


class TraceWriter:
    """Writes processed traces to TimescaleDB"""

    def __init__(self, timescale_url: Optional[str] = None):
        """
        Initialize writer

        Args:
            timescale_url: TimescaleDB connection URL
        """
        self.timescale_url = timescale_url or os.getenv('TIMESCALE_URL')
        self.conn: Optional[asyncpg.Connection] = None

    async def connect(self):
        """Establish database connection"""
        try:
            self.conn = await asyncpg.connect(self.timescale_url)
            logger.info("Connected to TimescaleDB")
        except Exception as e:
            logger.error(f"Failed to connect to TimescaleDB: {str(e)}")
            raise

    async def disconnect(self):
        """Close database connection"""
        if self.conn:
            await self.conn.close()
            logger.info("Disconnected from TimescaleDB")

    async def write_trace(self, trace: dict) -> bool:
        """
        Write a single trace to database

        Args:
            trace: Processed trace dictionary

        Returns:
            bool: True if successful
        """
        if not self.conn:
            await self.connect()

        try:
            await self.conn.execute(
                """
                INSERT INTO traces (
                    trace_id, workspace_id, agent_id, timestamp, latency_ms,
                    input, output, error, status, model, model_provider,
                    tokens_input, tokens_output, tokens_total, cost_usd,
                    metadata, tags
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
                ON CONFLICT (trace_id, timestamp) DO NOTHING
                """,
                trace['trace_id'],
                trace['workspace_id'],
                trace['agent_id'],
                trace['timestamp'],
                trace['latency_ms'],
                trace['input'],
                trace['output'],
                trace['error'],
                trace['status'],
                trace['model'],
                trace['model_provider'],
                trace['tokens_input'],
                trace['tokens_output'],
                trace['tokens_total'],
                trace['cost_usd'],
                json.dumps(trace['metadata']),
                trace['tags']
            )
            logger.debug(f"Wrote trace {trace['trace_id']} to database")
            return True

        except Exception as e:
            logger.error(f"Failed to write trace {trace['trace_id']}: {str(e)}")
            return False

    async def write_batch(self, traces: list[dict]) -> tuple[int, int]:
        """
        Write multiple traces to database in a batch

        Args:
            traces: List of processed trace dictionaries

        Returns:
            tuple: (successful_count, failed_count)
        """
        if not self.conn:
            await self.connect()

        if not traces:
            return 0, 0

        successful = 0
        failed = 0

        try:
            # Prepare data for executemany
            values = []
            for trace in traces:
                values.append((
                    trace['trace_id'],
                    trace['workspace_id'],
                    trace['agent_id'],
                    trace['timestamp'],
                    trace['latency_ms'],
                    trace['input'],
                    trace['output'],
                    trace['error'],
                    trace['status'],
                    trace['model'],
                    trace['model_provider'],
                    trace['tokens_input'],
                    trace['tokens_output'],
                    trace['tokens_total'],
                    trace['cost_usd'],
                    json.dumps(trace['metadata']),
                    trace['tags']
                ))

            # Batch insert
            await self.conn.executemany(
                """
                INSERT INTO traces (
                    trace_id, workspace_id, agent_id, timestamp, latency_ms,
                    input, output, error, status, model, model_provider,
                    tokens_input, tokens_output, tokens_total, cost_usd,
                    metadata, tags
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
                ON CONFLICT (trace_id, timestamp) DO NOTHING
                """,
                values
            )

            successful = len(traces)
            logger.info(f"Successfully wrote {successful} traces to database")

        except Exception as e:
            logger.error(f"Failed to write batch: {str(e)}")
            # Fallback to individual inserts
            for trace in traces:
                if await self.write_trace(trace):
                    successful += 1
                else:
                    failed += 1

        return successful, failed

    async def get_trace_count(self) -> int:
        """Get total count of traces in database"""
        if not self.conn:
            await self.connect()

        try:
            count = await self.conn.fetchval("SELECT COUNT(*) FROM traces")
            return count
        except Exception as e:
            logger.error(f"Failed to get trace count: {str(e)}")
            return 0
