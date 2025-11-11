#!/usr/bin/env python3
"""
Phase 1 Synthetic Data Generation
Generates realistic multi-agent traces across departments, environments, and versions
"""

import asyncio
import asyncpg
import random
from datetime import datetime, timedelta
from uuid import uuid4
import math

# Configuration
DATABASE_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'user': 'postgres',
    'password': 'postgres',
    'database': 'agent_observability'
}

# Agent naming templates by department
AGENT_TEMPLATES = {
    'engineering': [
        'code-assistant', 'code-reviewer', 'debug-helper', 'refactor-bot',
        'test-generator', 'doc-writer', 'api-designer', 'tech-advisor'
    ],
    'sales': [
        'sales-assistant', 'lead-qualifier', 'proposal-writer', 'crm-helper',
        'demo-scheduler', 'follow-up-bot', 'pipeline-analyzer'
    ],
    'support': [
        'support-agent', 'ticket-classifier', 'kb-search', 'escalation-bot',
        'feedback-analyzer', 'onboarding-helper', 'troubleshooter'
    ],
    'marketing': [
        'content-creator', 'seo-optimizer', 'campaign-planner', 'social-writer',
        'email-composer', 'ad-copy-writer', 'analytics-bot'
    ],
    'finance': [
        'expense-reviewer', 'budget-analyzer', 'invoice-processor', 'forecast-helper',
        'compliance-checker', 'report-generator'
    ],
    'hr': [
        'recruiting-assistant', 'onboarding-bot', 'policy-advisor', 'performance-helper',
        'benefits-guide', 'training-coordinator'
    ],
    'operations': [
        'ops-automation', 'workflow-optimizer', 'resource-planner', 'capacity-analyzer',
        'incident-responder', 'process-mapper'
    ],
    'product': [
        'roadmap-planner', 'feature-prioritizer', 'user-researcher', 'spec-writer',
        'feedback-synthesizer', 'metrics-analyzer'
    ],
    'data': [
        'data-analyzer', 'query-assistant', 'viz-helper', 'ml-advisor',
        'etl-monitor', 'data-quality-checker', 'report-builder'
    ],
    'legal': [
        'contract-reviewer', 'compliance-advisor', 'policy-checker', 'risk-analyzer',
        'doc-drafter'
    ]
}

# Intent categories by department (primary intents)
DEPARTMENT_INTENTS = {
    'engineering': ['code_generation', 'research', 'automation'],
    'sales': ['content_creation', 'data_analysis', 'customer_support'],
    'support': ['customer_support', 'research', 'automation'],
    'marketing': ['content_creation', 'data_analysis', 'automation'],
    'finance': ['data_analysis', 'automation', 'research'],
    'hr': ['content_creation', 'automation', 'research'],
    'operations': ['automation', 'data_analysis', 'research'],
    'product': ['research', 'data_analysis', 'content_creation'],
    'data': ['data_analysis', 'code_generation', 'research'],
    'legal': ['research', 'content_creation', 'automation']
}

# Model distribution (by environment)
MODEL_DISTRIBUTION = {
    'production': [
        ('gpt-4-turbo', 0.60),
        ('gpt-4', 0.25),
        ('gpt-3.5-turbo', 0.15)
    ],
    'staging': [
        ('gpt-4-turbo', 0.40),
        ('gpt-4', 0.40),
        ('gpt-3.5-turbo', 0.20)
    ],
    'development': [
        ('gpt-3.5-turbo', 0.60),
        ('gpt-4', 0.30),
        ('gpt-4-turbo', 0.10)
    ]
}

# Version adoption curve (time-based)
VERSION_TIMELINE = {
    'v2.1': {'start_days_ago': 30, 'adoption_rate': 0.70},
    'v2.0': {'start_days_ago': 60, 'adoption_rate': 0.20},
    'v1.9': {'start_days_ago': 90, 'adoption_rate': 0.08},
    'v1.8': {'start_days_ago': 120, 'adoption_rate': 0.02}
}

def weighted_choice(choices):
    """Make a weighted random choice from list of (item, weight) tuples"""
    total = sum(weight for item, weight in choices)
    r = random.uniform(0, total)
    upto = 0
    for item, weight in choices:
        if upto + weight >= r:
            return item
        upto += weight
    return choices[-1][0]

def get_business_hours_multiplier(dt):
    """Return activity multiplier based on time (higher during business hours)"""
    if dt.weekday() >= 5:  # Weekend
        return 0.2
    hour = dt.hour
    if 9 <= hour < 18:  # Business hours
        return 1.5
    elif 6 <= hour < 9 or 18 <= hour < 22:  # Off-peak
        return 0.8
    else:  # Night
        return 0.3

def get_version_for_date(dt):
    """Determine version based on date and adoption curve"""
    days_ago = (datetime.now() - dt).days

    # Build version probabilities based on timeline
    version_probs = []
    for version, config in VERSION_TIMELINE.items():
        if days_ago >= config['start_days_ago']:
            # Version is available at this date
            version_probs.append((version, config['adoption_rate']))

    if not version_probs:
        return 'v2.1'  # Default to latest

    return weighted_choice(version_probs)

def generate_latency(intent_category, environment, status):
    """Generate realistic latency based on intent, environment, and status"""
    base_latency = {
        'code_generation': 3500,
        'customer_support': 2000,
        'data_analysis': 2500,
        'content_creation': 2800,
        'automation': 1500,
        'research': 3000,
        'translation': 1800,
        'general_assistance': 2200
    }.get(intent_category, 2000)

    # Environment modifier
    env_multiplier = {
        'production': 0.9,  # Optimized
        'staging': 1.0,
        'development': 1.2  # Slower, more logging
    }.get(environment, 1.0)

    # Add randomness (log-normal distribution for realism)
    latency = int(base_latency * env_multiplier * random.lognormvariate(0, 0.3))

    # Errors tend to timeout
    if status == 'error':
        latency = int(latency * random.uniform(1.5, 3.0))

    return max(100, min(30000, latency))  # Clamp between 100ms and 30s

def generate_tokens_and_cost(model, latency_ms, intent_category):
    """Generate realistic token counts and costs"""
    # Token estimation based on intent
    base_tokens = {
        'code_generation': 2500,
        'customer_support': 800,
        'data_analysis': 1500,
        'content_creation': 1800,
        'automation': 600,
        'research': 2000,
        'translation': 1000,
        'general_assistance': 900
    }.get(intent_category, 1000)

    # Input/output split (roughly 40/60)
    total_tokens = int(base_tokens * random.uniform(0.7, 1.3))
    tokens_input = int(total_tokens * random.uniform(0.35, 0.45))
    tokens_output = total_tokens - tokens_input

    # Cost per 1K tokens (approximate)
    cost_per_1k = {
        'gpt-4-turbo': 0.01,
        'gpt-4': 0.03,
        'gpt-3.5-turbo': 0.002
    }.get(model, 0.01)

    cost_usd = (total_tokens / 1000.0) * cost_per_1k * random.uniform(0.9, 1.1)

    return tokens_input, tokens_output, total_tokens, round(cost_usd, 6)

async def main():
    """Main data generation function"""
    print("🚀 Starting Phase 1 Synthetic Data Generation")
    print("=" * 70)

    # Connect to database
    conn = await asyncpg.connect(**DATABASE_CONFIG)

    try:
        # Fetch existing data
        workspace_id = await conn.fetchval("SELECT DISTINCT workspace_id FROM traces LIMIT 1")
        print(f"📍 Using workspace_id: {workspace_id}")

        # Fetch departments
        departments = await conn.fetch("""
            SELECT id, workspace_id, department_code, department_name
            FROM departments
            WHERE workspace_id = $1
        """, workspace_id)
        print(f"📦 Found {len(departments)} departments")

        # Fetch environments
        environments = await conn.fetch("""
            SELECT id, workspace_id, environment_code
            FROM environments
            WHERE workspace_id = $1
        """, workspace_id)
        print(f"🌍 Found {len(environments)} environments")
        env_by_code = {e['environment_code']: e for e in environments}

        # Generate agents (80-100 agents distributed across departments)
        agents_to_create = []
        total_agents_target = random.randint(80, 100)
        print(f"\n🤖 Generating {total_agents_target} agents...")

        for dept in departments:
            dept_agent_count = random.randint(6, 12)
            templates = AGENT_TEMPLATES.get(dept['department_code'], ['assistant'])

            for i in range(dept_agent_count):
                template = random.choice(templates)
                agent_id = f"{dept['department_code']}-{template}-{i+1}"

                # Determine agent version (newer agents on newer versions)
                if random.random() < 0.7:
                    version = 'v2.1'
                elif random.random() < 0.85:
                    version = 'v2.0'
                else:
                    version = 'v1.9'

                agents_to_create.append({
                    'agent_id': agent_id,
                    'workspace_id': workspace_id,
                    'department_id': dept['id'],
                    'department_code': dept['department_code'],
                    'version': version
                })

                if len(agents_to_create) >= total_agents_target:
                    break

            if len(agents_to_create) >= total_agents_target:
                break

        print(f"✅ Generated {len(agents_to_create)} unique agent IDs")

        # Generate traces (500,000+ over 90 days)
        print(f"\n📊 Generating 500,000+ traces over 90 days...")

        traces_to_insert = []
        target_traces = 500000
        days_range = 90

        start_date = datetime.now() - timedelta(days=days_range)

        # Calculate traces per hour
        hours_total = days_range * 24
        traces_per_hour_base = target_traces // hours_total

        current_date = start_date
        batch_size = 10000
        total_inserted = 0

        while current_date < datetime.now():
            # Determine how many traces for this hour
            business_multiplier = get_business_hours_multiplier(current_date)
            traces_this_hour = int(traces_per_hour_base * business_multiplier * random.uniform(0.8, 1.2))

            for _ in range(traces_this_hour):
                # Select agent
                agent = random.choice(agents_to_create)
                dept_code = agent['department_code']

                # Select environment (70% prod, 20% staging, 10% dev)
                env_roll = random.random()
                if env_roll < 0.70:
                    env = env_by_code['production']
                elif env_roll < 0.90:
                    env = env_by_code['staging']
                else:
                    env = env_by_code['development']

                # Version (use agent version with some variation)
                version = get_version_for_date(current_date)

                # Intent category (based on department)
                intent_choices = DEPARTMENT_INTENTS.get(dept_code, ['general_assistance'])
                intent_category = random.choice(intent_choices)

                # Status (95% success, 5% error)
                status = 'success' if random.random() < 0.95 else 'error'

                # Model (based on environment)
                model = weighted_choice(MODEL_DISTRIBUTION[env['environment_code']])
                model_provider = 'openai'

                # User segment (distribution: 40% regular, 30% power_user, 20% new, 10% struggling)
                segment_roll = random.random()
                if segment_roll < 0.40:
                    user_segment = 'regular'
                elif segment_roll < 0.70:
                    user_segment = 'power_user'
                elif segment_roll < 0.90:
                    user_segment = 'new'
                else:
                    user_segment = 'struggling' if status == 'error' else 'regular'

                # Generate metrics
                latency_ms = generate_latency(intent_category, env['environment_code'], status)
                tokens_input, tokens_output, tokens_total, cost_usd = generate_tokens_and_cost(
                    model, latency_ms, intent_category
                )

                # Create trace
                trace = {
                    'trace_id': f"tr_{uuid4().hex[:16]}",
                    'workspace_id': workspace_id,
                    'agent_id': agent['agent_id'],
                    'department_id': agent['department_id'],
                    'environment_id': env['id'],
                    'version': version,
                    'intent_category': intent_category,
                    'user_segment': user_segment,
                    'timestamp': current_date + timedelta(minutes=random.randint(0, 59)),
                    'latency_ms': latency_ms,
                    'status': status,
                    'model': model,
                    'model_provider': model_provider,
                    'tokens_input': tokens_input,
                    'tokens_output': tokens_output,
                    'tokens_total': tokens_total,
                    'cost_usd': cost_usd,
                    'input': f"Sample input for {intent_category}",
                    'output': f"Sample output for {intent_category}" if status == 'success' else None,
                    'error': f"Error processing request" if status == 'error' else None
                }

                traces_to_insert.append(trace)

                # Insert in batches
                if len(traces_to_insert) >= batch_size:
                    await conn.executemany("""
                        INSERT INTO traces (
                            trace_id, workspace_id, agent_id, department_id, environment_id,
                            version, intent_category, user_segment, timestamp, latency_ms,
                            status, model, model_provider, tokens_input, tokens_output,
                            tokens_total, cost_usd, input, output, error
                        ) VALUES (
                            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
                            $11, $12, $13, $14, $15, $16, $17, $18, $19, $20
                        )
                    """, [
                        (
                            t['trace_id'], t['workspace_id'], t['agent_id'],
                            t['department_id'], t['environment_id'], t['version'],
                            t['intent_category'], t['user_segment'], t['timestamp'],
                            t['latency_ms'], t['status'], t['model'], t['model_provider'],
                            t['tokens_input'], t['tokens_output'], t['tokens_total'],
                            t['cost_usd'], t['input'], t['output'], t['error']
                        ) for t in traces_to_insert
                    ])

                    total_inserted += len(traces_to_insert)
                    print(f"  ✅ Inserted {total_inserted:,} traces... ({(total_inserted/target_traces*100):.1f}%)")
                    traces_to_insert = []

            # Move to next hour
            current_date += timedelta(hours=1)

        # Insert remaining traces
        if traces_to_insert:
            await conn.executemany("""
                INSERT INTO traces (
                    trace_id, workspace_id, agent_id, department_id, environment_id,
                    version, intent_category, user_segment, timestamp, latency_ms,
                    status, model, model_provider, tokens_input, tokens_output,
                    tokens_total, cost_usd, input, output, error
                ) VALUES (
                    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
                    $11, $12, $13, $14, $15, $16, $17, $18, $19, $20
                )
            """, [
                (
                    t['trace_id'], t['workspace_id'], t['agent_id'],
                    t['department_id'], t['environment_id'], t['version'],
                    t['intent_category'], t['user_segment'], t['timestamp'],
                    t['latency_ms'], t['status'], t['model'], t['model_provider'],
                    t['tokens_input'], t['tokens_output'], t['tokens_total'],
                    t['cost_usd'], t['input'], t['output'], t['error']
                ) for t in traces_to_insert
            ])
            total_inserted += len(traces_to_insert)

        print(f"\n🎉 Successfully inserted {total_inserted:,} traces!")

        # Refresh continuous aggregates
        print(f"\n🔄 Refreshing continuous aggregates...")
        await conn.execute("CALL refresh_continuous_aggregate('traces_hourly', NULL, NULL);")
        await conn.execute("CALL refresh_continuous_aggregate('traces_daily', NULL, NULL);")
        print(f"✅ Continuous aggregates refreshed")

        # Final statistics
        print(f"\n📈 Final Statistics:")
        print("=" * 70)

        stats = await conn.fetch("""
            SELECT
                COUNT(*) as total_traces,
                COUNT(DISTINCT agent_id) as unique_agents,
                COUNT(DISTINCT department_id) as departments,
                MIN(timestamp) as earliest_trace,
                MAX(timestamp) as latest_trace,
                SUM(cost_usd) as total_cost,
                AVG(latency_ms) as avg_latency,
                COUNT(*) FILTER (WHERE status = 'error') as error_count
            FROM traces
        """)

        stat = stats[0]
        print(f"Total Traces: {stat['total_traces']:,}")
        print(f"Unique Agents: {stat['unique_agents']}")
        print(f"Departments: {stat['departments']}")
        print(f"Date Range: {stat['earliest_trace']} to {stat['latest_trace']}")
        print(f"Total Cost: ${stat['total_cost']:,.2f}")
        print(f"Avg Latency: {stat['avg_latency']:.0f}ms")
        print(f"Error Rate: {stat['error_count']/stat['total_traces']*100:.2f}%")

        print(f"\n✨ Phase 1 Synthetic Data Generation Complete!")

    finally:
        await conn.close()

if __name__ == '__main__':
    asyncio.run(main())
