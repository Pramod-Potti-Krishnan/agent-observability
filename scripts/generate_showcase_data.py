#!/usr/bin/env python3
"""Generate a realistic 60-day showcase dataset for GARUDAI dashboards.

Populates:
- TimescaleDB traces (usage/cost/performance)
- Postgres evaluations (quality)
- Postgres guardrail rules + violations (safety)
- TimescaleDB impact tables when available (impact)
"""

import argparse
import asyncio
import json
import random
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
from uuid import UUID, uuid4

import asyncpg

TIMESCALE_DSN = "postgresql://postgres:postgres@localhost:5432/agent_observability"
POSTGRES_DSN = "postgresql://postgres:postgres@localhost:5433/agent_observability_metadata"

AGENTS = [
    "eng-code-assistant",
    "eng-review-bot",
    "support-ticket-router",
    "support-escalation-ai",
    "sales-proposal-gen",
    "sales-qa-assistant",
    "ops-runbook-helper",
    "product-research-copilot",
]

MODELS = [
    ("gpt-4o", "openai", 0.008),
    ("gpt-4.1-mini", "openai", 0.0025),
    ("claude-3-5-sonnet", "anthropic", 0.006),
    ("gemini-1.5-pro", "google", 0.0035),
]

INTENTS = [
    "code_generation",
    "customer_support",
    "data_analysis",
    "content_creation",
    "automation",
    "research",
    "general_assistance",
]

SEVERITIES = ["medium", "high", "critical"]
VIOLATION_TYPES = ["pii", "toxicity", "injection"]


@dataclass
class TraceRow:
    trace_id: str
    workspace_id: UUID
    agent_id: str
    timestamp: datetime
    latency_ms: int
    input: str
    output: Optional[str]
    error: Optional[str]
    status: str
    model: str
    model_provider: str
    tokens_input: int
    tokens_output: int
    tokens_total: int
    cost_usd: float
    metadata: Dict[str, Any]
    tags: List[str]
    department_id: Optional[UUID] = None
    environment_id: Optional[UUID] = None
    version: Optional[str] = None
    intent_category: Optional[str] = None
    user_segment: Optional[str] = None
    phase_timing: Optional[Dict[str, int]] = None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate showcase data for the last 60 days")
    parser.add_argument("--days", type=int, default=60, help="Number of days to backfill")
    parser.add_argument("--traces", type=int, default=12000, help="Number of traces to generate")
    parser.add_argument("--evaluations", type=int, default=1800, help="Number of evaluations to generate")
    parser.add_argument("--violations", type=int, default=320, help="Number of guardrail violations to generate")
    return parser.parse_args()


async def table_exists(conn: asyncpg.Connection, table_name: str) -> bool:
    result = await conn.fetchval(
        """
        SELECT EXISTS (
          SELECT 1 FROM information_schema.tables
          WHERE table_schema = 'public' AND table_name = $1
        )
        """,
        table_name,
    )
    return bool(result)


async def column_set(conn: asyncpg.Connection, table_name: str) -> set[str]:
    rows = await conn.fetch(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = $1
        """,
        table_name,
    )
    return {r["column_name"] for r in rows}


async def not_null_columns(conn: asyncpg.Connection, table_name: str) -> set[str]:
    rows = await conn.fetch(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = $1
          AND is_nullable = 'NO'
        """,
        table_name,
    )
    return {r["column_name"] for r in rows}


async def get_workspace_id(timescale: asyncpg.Connection, postgres: asyncpg.Connection) -> UUID:
    ws = await timescale.fetchval("SELECT workspace_id FROM traces ORDER BY timestamp DESC LIMIT 1")
    if ws:
        return ws

    ws2 = await postgres.fetchval("SELECT id FROM workspaces ORDER BY created_at ASC LIMIT 1")
    if ws2:
        return ws2

    default_ws = UUID("00000000-0000-0000-0000-000000000001")
    await postgres.execute(
        """
        INSERT INTO workspaces (id, name, slug, created_at, updated_at)
        VALUES ($1, 'Development Workspace', 'dev-workspace', NOW(), NOW())
        ON CONFLICT (id) DO NOTHING
        """,
        default_ws,
    )
    return default_ws


async def load_dept_env_ids(timescale: asyncpg.Connection, workspace_id: UUID) -> tuple[List[UUID], List[UUID]]:
    dept_ids: List[UUID] = []
    env_ids: List[UUID] = []

    if await table_exists(timescale, "departments"):
        await timescale.execute(
            """
            INSERT INTO departments (workspace_id, department_code, department_name, description, monthly_budget_usd, metadata)
            VALUES
              ($1, 'engineering', 'Engineering', 'Core engineering teams', 52000, '{}'::jsonb),
              ($1, 'support', 'Customer Support', 'Support operations', 18000, '{}'::jsonb),
              ($1, 'sales', 'Sales', 'Sales and GTM', 26000, '{}'::jsonb),
              ($1, 'product', 'Product', 'Product and design', 22000, '{}'::jsonb)
            ON CONFLICT (workspace_id, department_code) DO NOTHING
            """,
            workspace_id,
        )
        dept_ids = [
            r["id"]
            for r in await timescale.fetch(
                "SELECT id FROM departments WHERE workspace_id = $1 LIMIT 12",
                workspace_id,
            )
        ]
    if await table_exists(timescale, "environments"):
        await timescale.execute(
            """
            INSERT INTO environments (workspace_id, environment_code, environment_name, description, is_production, requires_approval, metadata)
            VALUES
              ($1, 'production', 'Production', 'Live environment', TRUE, TRUE, '{}'::jsonb),
              ($1, 'staging', 'Staging', 'Validation environment', FALSE, TRUE, '{}'::jsonb),
              ($1, 'development', 'Development', 'Development and testing', FALSE, FALSE, '{}'::jsonb)
            ON CONFLICT (workspace_id, environment_code) DO NOTHING
            """,
            workspace_id,
        )
        env_ids = [
            r["id"]
            for r in await timescale.fetch(
                "SELECT id FROM environments WHERE workspace_id = $1 LIMIT 8",
                workspace_id,
            )
        ]

    if not dept_ids:
        dept_ids = [
            r["department_id"]
            for r in await timescale.fetch(
                """
                SELECT DISTINCT department_id
                FROM traces
                WHERE workspace_id = $1 AND department_id IS NOT NULL
                LIMIT 12
                """,
                workspace_id,
            )
        ]

    if not env_ids:
        env_ids = [
            r["environment_id"]
            for r in await timescale.fetch(
                """
                SELECT DISTINCT environment_id
                FROM traces
                WHERE workspace_id = $1 AND environment_id IS NOT NULL
                LIMIT 8
                """,
                workspace_id,
            )
        ]

    return dept_ids, env_ids


def gen_latency(day_offset: float, env_factor: float) -> int:
    if day_offset < 14:
        baseline = random.randint(900, 2400)
    elif day_offset < 30:
        baseline = random.randint(1100, 3200)
    elif day_offset < 45:
        baseline = random.randint(800, 2100)
    else:
        baseline = random.randint(700, 1700)

    if random.random() < 0.03:
        baseline = random.randint(6000, 18000)

    return int(max(120, baseline * env_factor))


def build_trace(
    workspace_id: UUID,
    start_ts: datetime,
    days: int,
    dept_ids: List[UUID],
    env_ids: List[UUID],
) -> TraceRow:
    day_offset = random.random() * days
    ts = start_ts + timedelta(days=day_offset, minutes=random.randint(0, 1439))
    agent_id = random.choice(AGENTS)

    model, provider, unit_cost = random.choice(MODELS)

    env_factor = random.choice([0.9, 1.0, 1.15])
    latency_ms = gen_latency(day_offset, env_factor)

    if random.random() < 0.88:
        status = "success"
        error = None
    elif random.random() < 0.75:
        status = "error"
        error = random.choice(["rate_limit", "model_overloaded", "validation_error"])
    else:
        status = "timeout"
        error = "timeout"

    tokens_input = random.randint(180, 2100)
    tokens_output = random.randint(120, 1800) if status == "success" else random.randint(0, 120)
    tokens_total = tokens_input + tokens_output
    cost_usd = round(tokens_total / 1000 * unit_cost * random.uniform(0.85, 1.25), 6)

    phase_timing = {
        "auth_ms": random.randint(8, 25),
        "preprocessing_ms": random.randint(20, 100),
        "llm_call_ms": max(80, latency_ms - random.randint(45, 180)),
        "postprocessing_ms": random.randint(15, 65),
    }

    return TraceRow(
        trace_id=f"showcase-{uuid4().hex[:18]}",
        workspace_id=workspace_id,
        agent_id=agent_id,
        timestamp=ts,
        latency_ms=latency_ms,
        input=f"Showcase request for {agent_id} at {ts.isoformat()}",
        output=None if status != "success" else "Synthetic response generated for dashboard showcase.",
        error=error,
        status=status,
        model=model,
        model_provider=provider,
        tokens_input=tokens_input,
        tokens_output=tokens_output,
        tokens_total=tokens_total,
        cost_usd=cost_usd,
        metadata={"source": "showcase_seed", "region": random.choice(["us-east", "us-west", "eu-central"])},
        tags=["showcase", "synthetic", random.choice(["prod", "staging", "canary"])],
        department_id=random.choice(dept_ids) if dept_ids else None,
        environment_id=random.choice(env_ids) if env_ids else None,
        version=random.choice(["v2.0", "v2.1", "v2.2", "v2.3-canary"]),
        intent_category=random.choice(INTENTS),
        user_segment=random.choice(["power_user", "regular", "new", None]),
        phase_timing=phase_timing,
    )


async def insert_traces(timescale: asyncpg.Connection, workspace_id: UUID, days: int, total: int) -> int:
    trace_cols = await column_set(timescale, "traces")
    required_cols = await not_null_columns(timescale, "traces")

    insert_cols = [
        "trace_id",
        "workspace_id",
        "agent_id",
        "timestamp",
        "latency_ms",
        "input",
        "output",
        "error",
        "status",
        "model",
        "model_provider",
        "tokens_input",
        "tokens_output",
        "tokens_total",
        "cost_usd",
        "metadata",
        "tags",
    ]

    optional_cols = ["department_id", "environment_id", "version", "intent_category", "user_segment", "phase_timing"]
    for col in optional_cols:
        if col in trace_cols:
            insert_cols.append(col)

    placeholders = ", ".join(f"${i}" for i in range(1, len(insert_cols) + 1))
    sql = f"INSERT INTO traces ({', '.join(insert_cols)}) VALUES ({placeholders})"

    dept_ids, env_ids = await load_dept_env_ids(timescale, workspace_id)
    if "department_id" in trace_cols and "department_id" in required_cols and not dept_ids:
        raise RuntimeError("Cannot seed traces: traces.department_id is required but no department IDs were found.")
    if "environment_id" in trace_cols and "environment_id" in required_cols and not env_ids:
        raise RuntimeError("Cannot seed traces: traces.environment_id is required but no environment IDs were found.")
    start_ts = datetime.now(timezone.utc) - timedelta(days=days)

    rows: List[tuple[Any, ...]] = []
    for _ in range(total):
        t = build_trace(workspace_id, start_ts, days, dept_ids, env_ids)
        row_map = {
            "trace_id": t.trace_id,
            "workspace_id": t.workspace_id,
            "agent_id": t.agent_id,
            "timestamp": t.timestamp,
            "latency_ms": t.latency_ms,
            "input": t.input,
            "output": t.output,
            "error": t.error,
            "status": t.status,
            "model": t.model,
            "model_provider": t.model_provider,
            "tokens_input": t.tokens_input,
            "tokens_output": t.tokens_output,
            "tokens_total": t.tokens_total,
            "cost_usd": t.cost_usd,
            "metadata": json.dumps(t.metadata),
            "tags": t.tags,
            "department_id": t.department_id,
            "environment_id": t.environment_id,
            "version": t.version,
            "intent_category": t.intent_category,
            "user_segment": t.user_segment,
            "phase_timing": json.dumps(t.phase_timing) if t.phase_timing else None,
        }
        rows.append(tuple(row_map[c] for c in insert_cols))

    await timescale.executemany(sql, rows)
    return total


async def insert_evaluations(
    timescale: asyncpg.Connection,
    postgres: asyncpg.Connection,
    workspace_id: UUID,
    days: int,
    total: int,
) -> int:
    if not await table_exists(postgres, "evaluations"):
        return 0

    eval_cols = await column_set(postgres, "evaluations")

    traces = await timescale.fetch(
        """
        SELECT trace_id, agent_id, timestamp
        FROM traces
        WHERE workspace_id = $1
          AND timestamp >= NOW() - ($2::text || ' days')::interval
          AND status = 'success'
        ORDER BY RANDOM()
        LIMIT $3
        """,
        workspace_id,
        str(days),
        total,
    )
    if not traces:
        return 0

    inserted = 0
    for tr in traces:
        accuracy = round(random.uniform(5.8, 9.8), 1)
        relevance = round(max(0.0, min(10.0, accuracy + random.uniform(-0.8, 0.8))), 1)
        helpfulness = round(max(0.0, min(10.0, accuracy + random.uniform(-0.9, 0.9))), 1)
        coherence = round(max(0.0, min(10.0, accuracy + random.uniform(-0.7, 0.7))), 1)
        overall = round((accuracy + relevance + helpfulness + coherence) / 4, 1)

        created_at = tr["timestamp"] + timedelta(minutes=random.randint(2, 55))

        fields = [
            "id",
            "workspace_id",
            "trace_id",
            "created_at",
            "evaluator",
            "accuracy_score",
            "relevance_score",
            "helpfulness_score",
            "coherence_score",
            "overall_score",
            "reasoning",
            "metadata",
        ]
        values: List[Any] = [
            uuid4(),
            workspace_id,
            tr["trace_id"],
            created_at,
            random.choice(["gemini", "human", "custom_model"]),
            accuracy,
            relevance,
            helpfulness,
            coherence,
            overall,
            "Synthetic evaluation for showcase reporting and trend analysis.",
            json.dumps({"source": "showcase_seed", "confidence": round(random.uniform(0.83, 0.99), 3)}),
        ]

        if "agent_id" in eval_cols:
            fields.append("agent_id")
            values.append(tr["agent_id"])

        placeholders = ", ".join(f"${i}" for i in range(1, len(fields) + 1))
        await postgres.execute(
            f"INSERT INTO evaluations ({', '.join(fields)}) VALUES ({placeholders})",
            *values,
        )
        inserted += 1

    return inserted


async def ensure_guardrail_rule(postgres: asyncpg.Connection, workspace_id: UUID, rule_type: str, severity: str) -> UUID:
    existing = await postgres.fetchval(
        """
        SELECT id
        FROM guardrail_rules
        WHERE workspace_id = $1 AND rule_type = $2
        ORDER BY created_at ASC
        LIMIT 1
        """,
        workspace_id,
        rule_type,
    )
    if existing:
        return existing

    rid = uuid4()
    await postgres.execute(
        """
        INSERT INTO guardrail_rules (id, workspace_id, rule_type, name, description, config, severity, action, is_active, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, '{}'::jsonb, $6, 'log', TRUE, NOW(), NOW())
        """,
        rid,
        workspace_id,
        rule_type,
        f"{rule_type} detection",
        "Synthetic rule for showcase",
        severity,
    )
    return rid


async def insert_guardrail_violations(
    timescale: asyncpg.Connection,
    postgres: asyncpg.Connection,
    workspace_id: UUID,
    days: int,
    total: int,
) -> int:
    if not await table_exists(postgres, "guardrail_violations") or not await table_exists(postgres, "guardrail_rules"):
        return 0

    traces = await timescale.fetch(
        """
        SELECT trace_id, timestamp, agent_id
        FROM traces
        WHERE workspace_id = $1
          AND timestamp >= NOW() - ($2::text || ' days')::interval
        ORDER BY RANDOM()
        LIMIT $3
        """,
        workspace_id,
        str(days),
        total,
    )
    if not traces:
        return 0

    rule_ids = {
        "pii": await ensure_guardrail_rule(postgres, workspace_id, "pii_detection", "high"),
        "toxicity": await ensure_guardrail_rule(postgres, workspace_id, "toxicity", "medium"),
        "injection": await ensure_guardrail_rule(postgres, workspace_id, "prompt_injection", "critical"),
    }

    inserted = 0
    for tr in traces:
        vtype = random.choices(VIOLATION_TYPES, weights=[0.55, 0.3, 0.15], k=1)[0]
        sev = random.choices(SEVERITIES, weights=[0.6, 0.3, 0.1], k=1)[0]

        detected = tr["timestamp"] + timedelta(seconds=random.randint(5, 240))
        meta = {"source": "showcase_seed", "agent_id": tr["agent_id"], "pattern_type": random.choice(["email", "phone", "ip_address", "prompt_override"])}

        await postgres.execute(
            """
            INSERT INTO guardrail_violations
            (id, workspace_id, rule_id, trace_id, detected_at, violation_type, severity, message, detected_content, redacted_content, metadata)
            VALUES
            ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
            """,
            uuid4(),
            workspace_id,
            rule_ids[vtype],
            tr["trace_id"],
            detected,
            vtype,
            sev,
            f"Synthetic {vtype} violation for showcase",
            "sample-sensitive-content",
            "[REDACTED]",
            json.dumps(meta),
        )
        inserted += 1

    return inserted


async def insert_impact_data(timescale: asyncpg.Connection, workspace_id: UUID, days: int) -> int:
    required = ["investment_tracking", "value_attribution", "business_goals"]
    for t in required:
        if not await table_exists(timescale, t):
            return 0

    # investments
    start = datetime.now(timezone.utc) - timedelta(days=days)
    end = datetime.now(timezone.utc)

    await timescale.execute(
        """
        INSERT INTO investment_tracking (workspace_id, period_start, period_end, investment_category, amount_usd, description)
        VALUES
          ($1, $2, $3, 'infrastructure', 7200, 'Cloud and model serving costs'),
          ($1, $2, $3, 'development', 9800, 'Prompt and agent optimization work'),
          ($1, $2, $3, 'operations', 4100, 'Monitoring and incident response')
        """,
        workspace_id,
        start,
        end,
    )

    for i in range(8):
        p_start = start + timedelta(days=i * max(1, days // 8))
        p_end = min(end, p_start + timedelta(days=7))
        cost_savings = random.uniform(9000, 15000)
        revenue = random.uniform(3000, 9000)
        hours = random.uniform(180, 420)
        total_value = cost_savings + revenue + (hours * 55)

        await timescale.execute(
            """
            INSERT INTO value_attribution (
              workspace_id, period_start, period_end, agent_id, department_id,
              cost_savings_usd, revenue_impact_usd, productivity_hours_saved,
              customer_satisfaction_delta, total_value_created_usd,
              attribution_confidence, calculation_method
            ) VALUES ($1, $2, $3, $4, NULL, $5, $6, $7, $8, $9, $10, 'correlated')
            """,
            workspace_id,
            p_start,
            p_end,
            random.choice(AGENTS),
            cost_savings,
            revenue,
            hours,
            round(random.uniform(0.3, 1.3), 2),
            total_value,
            round(random.uniform(0.78, 0.96), 2),
        )

    # business goals
    goal_rows = [
        ("cost_savings", "Reduce Inference Spend", 120000.0, 93400.0, "usd", "active", 77.8),
        ("csat", "Increase CSAT", 4.6, 4.18, "score", "active", 90.8),
        ("productivity", "Hours Saved", 2200.0, 1715.0, "hours", "at_risk", 78.0),
        ("revenue", "Pipeline Assisted", 180000.0, 102000.0, "usd", "active", 56.7),
    ]

    for gtype, name, target, current, unit, status, progress in goal_rows:
        await timescale.execute(
            """
            INSERT INTO business_goals (
              workspace_id, goal_type, name, description,
              target_value, current_value, unit, target_date,
              status, progress_percentage, created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW() + INTERVAL '90 days', $8, $9, NOW(), NOW())
            """,
            workspace_id,
            gtype,
            name,
            "Synthetic goal seeded for showcase dashboards",
            target,
            current,
            unit,
            status,
            progress,
        )

    return 1


async def main() -> None:
    args = parse_args()

    timescale = await asyncpg.connect(TIMESCALE_DSN)
    postgres = await asyncpg.connect(POSTGRES_DSN)

    try:
        workspace_id = await get_workspace_id(timescale, postgres)
        print(f"Workspace: {workspace_id}")

        trace_count = await insert_traces(timescale, workspace_id, args.days, args.traces)
        print(f"Inserted traces: {trace_count}")

        evaluation_count = await insert_evaluations(timescale, postgres, workspace_id, args.days, args.evaluations)
        print(f"Inserted evaluations: {evaluation_count}")

        violation_count = await insert_guardrail_violations(timescale, postgres, workspace_id, args.days, args.violations)
        print(f"Inserted guardrail violations: {violation_count}")

        impact_seeded = await insert_impact_data(timescale, workspace_id, args.days)
        print(f"Inserted impact data: {'yes' if impact_seeded else 'skipped (tables unavailable)'}")

        # quick verification
        recent_traces = await timescale.fetchrow(
            """
            SELECT COUNT(*)::int AS c, MIN(timestamp) AS min_ts, MAX(timestamp) AS max_ts
            FROM traces
            WHERE workspace_id = $1 AND timestamp >= NOW() - ($2::text || ' days')::interval
            """,
            workspace_id,
            str(args.days),
        )
        print(
            f"Recent traces ({args.days}d): {recent_traces['c']} | "
            f"{recent_traces['min_ts']} -> {recent_traces['max_ts']}"
        )

    finally:
        await timescale.close()
        await postgres.close()


if __name__ == "__main__":
    asyncio.run(main())
