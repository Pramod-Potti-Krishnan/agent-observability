#!/usr/bin/env python3
"""
Performance-Focused Synthetic Data Generation
Generates 50,000+ traces with realistic performance patterns and compelling stories
"""

import asyncio
import asyncpg
import random
from datetime import datetime, timedelta
from uuid import uuid4, UUID
import json

# Database Configuration
DATABASE_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'user': 'postgres',
    'password': 'postgres',
    'database': 'agent_observability'
}

# Global workspace ID (will be fetched from DB)
WORKSPACE_ID = None

# Multi-Agent Configuration
DEPARTMENTS = ['engineering', 'sales', 'support']
ENVIRONMENTS = ['production', 'staging', 'development']
VERSIONS = ['v1.8', 'v1.9', 'v2.0', 'v2.1-beta', 'v2.2-alpha']
PROVIDERS = ['openai', 'anthropic', 'google']
MODELS = {
    'openai': 'gpt-4',
    'anthropic': 'claude-3-opus',
    'google': 'gemini-pro'
}

# Agent definitions (20 agents across departments)
AGENTS = {
    'engineering': ['code-assistant-eng-001', 'code-reviewer-eng-002', 'debug-helper-eng-003', 'test-generator-eng-004'],
    'sales': ['sales-assistant-sales-001', 'lead-qualifier-sales-002', 'proposal-writer-sales-003', 'crm-helper-sales-004'],
    'support': ['support-agent-sup-001', 'ticket-classifier-sup-002', 'kb-search-sup-003', 'escalation-bot-sup-004']
}

# Performance patterns by scenario
PERFORMANCE_SCENARIOS = {
    # Week 1: Baseline (stable performance)
    'baseline': {
        'latency_range': (200, 800),
        'error_rate': 0.01,  # 1%
        'timeout_rate': 0.005,  # 0.5%
        'phase_distribution': {'auth_ms': (10, 30), 'preprocessing_ms': (20, 60), 'llm_call_ms': (150, 600), 'postprocessing_ms': (20, 80), 'tool_use_ms': (0, 100)}
    },
    # Week 2: Regression (v2.1-beta deployment)
    'regression': {
        'latency_range': (500, 3000),
        'error_rate': 0.05,  # 5%
        'timeout_rate': 0.02,  # 2%
        'phase_distribution': {'auth_ms': (10, 30), 'preprocessing_ms': (30, 100), 'llm_call_ms': (400, 2500), 'postprocessing_ms': (30, 150), 'tool_use_ms': (0, 200)}
    },
    # Week 3: High load (capacity stress)
    'high_load': {
        'latency_range': (300, 1500),
        'error_rate': 0.025,  # 2.5%
        'timeout_rate': 0.015,  # 1.5%
        'phase_distribution': {'auth_ms': (15, 50), 'preprocessing_ms': (30, 100), 'llm_call_ms': (250, 1200), 'postprocessing_ms': (30, 100), 'tool_use_ms': (0, 150)}
    },
    # Week 4: Improvement (v2.2-alpha optimized)
    'improvement': {
        'latency_range': (150, 600),
        'error_rate': 0.005,  # 0.5%
        'timeout_rate': 0.002,  # 0.2%
        'phase_distribution': {'auth_ms': (8, 25), 'preprocessing_ms': (15, 50), 'llm_call_ms': (120, 450), 'postprocessing_ms': (15, 60), 'tool_use_ms': (0, 70)}
    }
}

# Provider-specific performance characteristics
PROVIDER_CHARACTERISTICS = {
    'openai': {'latency_multiplier': 1.0, 'error_rate_multiplier': 1.0, 'cost_per_1k': 0.03},
    'anthropic': {'latency_multiplier': 0.85, 'error_rate_multiplier': 0.8, 'cost_per_1k': 0.025},  # Fastest
    'google': {'latency_multiplier': 1.15, 'error_rate_multiplier': 1.2, 'cost_per_1k': 0.02}  # Cheapest
}

# Environment-specific patterns
ENVIRONMENT_PATTERNS = {
    'production': {'volume_pct': 0.60, 'latency_multiplier': 1.0},
    'staging': {'volume_pct': 0.30, 'latency_multiplier': 1.15},
    'development': {'volume_pct': 0.10, 'latency_multiplier': 1.30}
}

async def get_workspace_id(conn):
    """Get or create default workspace"""
    result = await conn.fetchrow("SELECT workspace_id FROM traces LIMIT 1")
    if result:
        return result['workspace_id']
    # If no traces, create a default workspace ID
    return UUID('00000000-0000-0000-0000-000000000001')

async def get_department_env_mappings(conn):
    """Get department and environment ID mappings"""
    depts = await conn.fetch("SELECT id, department_code FROM departments")
    envs = await conn.fetch("SELECT id, environment_code FROM environments")

    dept_map = {d['department_code']: d['id'] for d in depts}
    env_map = {e['environment_code']: e['id'] for e in envs}

    return dept_map, env_map

def generate_phase_timing(scenario):
    """Generate realistic phase timing breakdown"""
    phases = scenario['phase_distribution']
    timing = {}

    for phase, (min_ms, max_ms) in phases.items():
        timing[phase] = random.randint(min_ms, max_ms)

    return timing

def calculate_total_latency(phase_timing):
    """Calculate total latency from phase breakdown"""
    return sum(phase_timing.values())

def determine_status(scenario, provider):
    """Determine request status based on scenario and provider"""
    error_rate = scenario['error_rate'] * PROVIDER_CHARACTERISTICS[provider]['error_rate_multiplier']
    timeout_rate = scenario['timeout_rate']

    rand = random.random()
    if rand < timeout_rate:
        return 'timeout', 'timeout'
    elif rand < (timeout_rate + error_rate):
        error_types = ['validation_error', 'rate_limit', 'llm_error', 'auth_error']
        return 'error', random.choice(error_types)
    else:
        return 'success', None

def generate_cost(tokens_total, provider):
    """Calculate cost based on tokens and provider"""
    cost_per_1k = PROVIDER_CHARACTERISTICS[provider]['cost_per_1k']
    return (tokens_total / 1000) * cost_per_1k

async def generate_traces(conn, dept_map, env_map, num_traces=50000):
    """Generate performance-focused traces"""
    print(f"\n📊 Generating {num_traces:,} traces with performance patterns...")

    # Define time periods (30 days, broken into 4 weeks)
    end_time = datetime.now()
    start_time = end_time - timedelta(days=30)

    week_scenarios = [
        ('baseline', 0, 7),
        ('regression', 7, 14),
        ('high_load', 14, 21),
        ('improvement', 21, 30)
    ]

    traces = []
    batch_size = 1000

    for i in range(num_traces):
        # Determine which week/scenario
        day_offset = random.uniform(0, 30)
        timestamp = start_time + timedelta(days=day_offset)

        scenario_name = 'baseline'
        for sname, start_day, end_day in week_scenarios:
            if start_day <= day_offset < end_day:
                scenario_name = sname
                break

        scenario = PERFORMANCE_SCENARIOS[scenario_name]

        # Select department, environment, agent
        dept_name = random.choice(DEPARTMENTS)
        env_name = random.choices(
            list(ENVIRONMENT_PATTERNS.keys()),
            weights=[ENVIRONMENT_PATTERNS[e]['volume_pct'] for e in ENVIRONMENT_PATTERNS.keys()]
        )[0]

        agent_id = random.choice(AGENTS[dept_name])

        # Select version based on week
        if day_offset < 7:
            version = random.choice(['v1.9', 'v2.0'])
        elif day_offset < 14:
            version = random.choice(['v2.0', 'v2.1-beta'])  # Regression period
        elif day_offset < 21:
            version = random.choice(['v2.0', 'v2.1-beta'])
        else:
            version = random.choice(['v2.0', 'v2.2-alpha'])  # Improvement period

        # Select provider
        provider = random.choice(PROVIDERS)
        model = MODELS[provider]

        # Generate phase timing
        phase_timing = generate_phase_timing(scenario)

        # Apply provider and environment multipliers
        latency_multiplier = (
            PROVIDER_CHARACTERISTICS[provider]['latency_multiplier'] *
            ENVIRONMENT_PATTERNS[env_name]['latency_multiplier']
        )

        for phase in phase_timing:
            phase_timing[phase] = int(phase_timing[phase] * latency_multiplier)

        latency_ms = calculate_total_latency(phase_timing)

        # Determine status
        status, error_type = determine_status(scenario, provider)

        # Generate tokens and cost
        tokens_input = random.randint(500, 3000)
        tokens_output = random.randint(200, 2000) if status == 'success' else 0
        tokens_total = tokens_input + tokens_output
        cost_usd = generate_cost(tokens_total, provider)

        # Create trace
        trace = {
            'trace_id': str(uuid4()),
            'workspace_id': WORKSPACE_ID,
            'agent_id': agent_id,
            'timestamp': timestamp,
            'latency_ms': latency_ms,
            'status': status,
            'model': model,
            'model_provider': provider,
            'tokens_input': tokens_input,
            'tokens_output': tokens_output,
            'tokens_total': tokens_total,
            'cost_usd': cost_usd,
            'department_id': dept_map[dept_name],
            'environment_id': env_map[env_name],
            'version': version,
            'intent_category': 'code_generation' if dept_name == 'engineering' else 'customer_support' if dept_name == 'support' else 'general_assistance',
            'user_segment': 'power_user' if status == 'success' else 'regular',
            'phase_timing': json.dumps(phase_timing),
            'error': error_type if error_type else None
        }

        traces.append(trace)

        # Insert in batches
        if len(traces) >= batch_size:
            await insert_traces_batch(conn, traces)
            traces = []
            print(f"  ✓ Inserted {i+1:,}/{num_traces:,} traces ({((i+1)/num_traces*100):.1f}%)")

    # Insert remaining traces
    if traces:
        await insert_traces_batch(conn, traces)

    print(f"✅ Successfully generated {num_traces:,} traces")

async def insert_traces_batch(conn, traces):
    """Insert batch of traces"""
    await conn.executemany('''
        INSERT INTO traces (
            trace_id, workspace_id, agent_id, timestamp, latency_ms, status,
            model, model_provider, tokens_input, tokens_output, tokens_total, cost_usd,
            department_id, environment_id, version, intent_category, user_segment,
            phase_timing, error
        ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19
        )
    ''', [
        (
            t['trace_id'], t['workspace_id'], t['agent_id'], t['timestamp'], t['latency_ms'],
            t['status'], t['model'], t['model_provider'], t['tokens_input'], t['tokens_output'],
            t['tokens_total'], t['cost_usd'], t['department_id'], t['environment_id'],
            t['version'], t['intent_category'], t['user_segment'], t['phase_timing'], t['error']
        )
        for t in traces
    ])

async def generate_slo_configs(conn):
    """Generate SLO configurations for agents"""
    print("\n🎯 Generating SLO configurations...")

    all_agents = []
    for dept_agents in AGENTS.values():
        all_agents.extend(dept_agents)

    slo_configs = []
    for agent_id in all_agents:
        # Ensure percentiles are in ascending order
        p50 = random.choice([300, 500, 800])
        p90 = random.choice([600, 1000, 1500])
        p95 = random.choice([800, 1200, 2000])
        p99 = random.choice([1500, 2500, 3500])

        # Fix ordering if needed
        if p90 < p50:
            p50, p90 = p90, p50
        if p95 < p90:
            p95 = p90 + 200
        if p99 < p95:
            p99 = p95 + 500

        slo = {
            'workspace_id': WORKSPACE_ID,
            'agent_id': agent_id,
            'p50_latency_target_ms': p50,
            'p90_latency_target_ms': p90,
            'p95_latency_target_ms': p95,
            'p99_latency_target_ms': p99,
            'error_rate_target_pct': random.choice([1.0, 2.0, 5.0]),
            'availability_target_pct': 99.9,
            'error_budget_minutes': 43,  # 99.9% uptime = 43 min/month
            'is_active': True,
            'alert_on_violation': True
        }
        slo_configs.append(slo)

    await conn.executemany('''
        INSERT INTO slo_configs (
            workspace_id, agent_id, p50_latency_target_ms, p90_latency_target_ms,
            p95_latency_target_ms, p99_latency_target_ms, error_rate_target_pct,
            availability_target_pct, error_budget_minutes, is_active, alert_on_violation
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
    ''', [
        (
            s['workspace_id'], s['agent_id'], s['p50_latency_target_ms'],
            s['p90_latency_target_ms'], s['p95_latency_target_ms'], s['p99_latency_target_ms'],
            s['error_rate_target_pct'], s['availability_target_pct'], s['error_budget_minutes'],
            s['is_active'], s['alert_on_violation']
        )
        for s in slo_configs
    ])

    print(f"✅ Generated {len(slo_configs)} SLO configurations")

async def generate_performance_events(conn):
    """Generate performance events (deployments, regressions)"""
    print("\n📅 Generating performance events...")

    events = [
        {
            'workspace_id': WORKSPACE_ID,
            'event_type': 'deployment',
            'timestamp': datetime.now() - timedelta(days=23),
            'version_before': 'v1.9',
            'version_after': 'v2.0',
            'affected_agents': [a for agents in AGENTS.values() for a in agents],
            'impact_on_latency_pct': -5.0,
            'impact_on_error_rate_pct': -10.0,
            'description': 'Stable v2.0 release with minor performance improvements',
            'status': 'resolved'
        },
        {
            'workspace_id': WORKSPACE_ID,
            'event_type': 'regression',
            'timestamp': datetime.now() - timedelta(days=16),
            'version_before': 'v2.0',
            'version_after': 'v2.1-beta',
            'affected_agents': [a for agents in AGENTS.values() for a in agents[:2]],
            'impact_on_latency_pct': 40.0,
            'impact_on_error_rate_pct': 300.0,
            'description': 'v2.1-beta introduced significant performance regression',
            'status': 'investigating'
        },
        {
            'workspace_id': WORKSPACE_ID,
            'event_type': 'scaling',
            'timestamp': datetime.now() - timedelta(days=10),
            'affected_agents': [a for agents in AGENTS.values() for a in agents],
            'impact_on_throughput_pct': 25.0,
            'description': 'Increased capacity due to high load period',
            'status': 'resolved'
        },
        {
            'workspace_id': WORKSPACE_ID,
            'event_type': 'improvement',
            'timestamp': datetime.now() - timedelta(days=5),
            'version_before': 'v2.1-beta',
            'version_after': 'v2.2-alpha',
            'affected_agents': [a for agents in AGENTS.values() for a in agents],
            'impact_on_latency_pct': -25.0,
            'impact_on_error_rate_pct': -50.0,
            'description': 'v2.2-alpha with optimizations - performance restored',
            'status': 'resolved'
        }
    ]

    await conn.executemany('''
        INSERT INTO performance_events (
            workspace_id, event_type, timestamp, version_before, version_after,
            affected_agents, impact_on_latency_pct, impact_on_error_rate_pct,
            impact_on_throughput_pct, description, status
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
    ''', [
        (
            e['workspace_id'], e['event_type'], e['timestamp'],
            e.get('version_before'), e.get('version_after'),
            e['affected_agents'], e.get('impact_on_latency_pct'),
            e.get('impact_on_error_rate_pct'), e.get('impact_on_throughput_pct'),
            e['description'], e['status']
        )
        for e in events
    ])

    print(f"✅ Generated {len(events)} performance events")

async def generate_capacity_config(conn):
    """Generate capacity configuration"""
    print("\n⚙️  Generating capacity configuration...")

    await conn.execute('''
        INSERT INTO capacity_configs (
            workspace_id, max_requests_per_hour, max_requests_per_second,
            max_concurrent_requests, warning_threshold_pct, critical_threshold_pct,
            is_active
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)
    ''', WORKSPACE_ID, 10000, 3, 100, 80.0, 95.0, True)

    print("✅ Generated capacity configuration")

async def main():
    print("🚀 Starting Performance-Focused Synthetic Data Generation")
    print("=" * 70)

    conn = await asyncpg.connect(**DATABASE_CONFIG)

    try:
        # Get workspace and mappings
        global WORKSPACE_ID
        WORKSPACE_ID = await get_workspace_id(conn)
        print(f"✓ Using workspace ID: {WORKSPACE_ID}")

        dept_map, env_map = await get_department_env_mappings(conn)
        print(f"✓ Found {len(dept_map)} departments and {len(env_map)} environments")

        # Generate data
        await generate_traces(conn, dept_map, env_map, num_traces=50000)
        await generate_slo_configs(conn)
        await generate_performance_events(conn)
        await generate_capacity_config(conn)

        # Refresh materialized view
        print("\n🔄 Refreshing materialized views...")
        await conn.execute("REFRESH MATERIALIZED VIEW performance_latency_hourly;")
        print("✅ Materialized view refreshed")

        print("\n" + "=" * 70)
        print("🎉 Performance data generation complete!")
        print("\nData Summary:")
        print("  • 50,000 traces with realistic performance patterns")
        print("  • 12 agents with SLO configurations")
        print("  • 4 performance events (deployments, regression, improvement)")
        print("  • Compelling stories: regression, capacity stress, optimization")

    finally:
        await conn.close()

if __name__ == '__main__':
    asyncio.run(main())
