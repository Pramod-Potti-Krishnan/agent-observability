#!/usr/bin/env python3
"""
Cost Management Synthetic Data Generator
Adds cost data to existing traces and creates department budgets + optimization opportunities
"""

import asyncio
import asyncpg
import uuid
from datetime import datetime, timedelta
from typing import List, Dict
import random

# Database connection configs
TIMESCALE_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'agent_observability',
    'user': 'postgres',
    'password': 'postgres'
}

POSTGRES_CONFIG = {
    'host': 'localhost',
    'port': 5433,
    'database': 'agent_observability_metadata',
    'user': 'postgres',
    'password': 'postgres'
}

# Department definitions (matching PRD)
DEPARTMENTS = {
    'Engineering': {
        'budget_monthly': 22000,
        'target_spend': 18500,  # 84% utilization
        'agents': ['code-assistant-eng-001', 'code-review-eng-002', 'doc-generator-eng-003',
                   'test-writer-eng-004', 'refactor-assistant-eng-005', 'bug-analyzer-eng-006',
                   'api-designer-eng-007', 'perf-optimizer-eng-008'],
        'primary_providers': ['anthropic', 'openai'],
        'cost_variance': 0.15
    },
    'Sales': {
        'budget_monthly': 12000,
        'target_spend': 10800,  # 90% utilization
        'agents': ['lead-qualifier-sales-001', 'proposal-writer-sales-002', 'email-responder-sales-003',
                   'crm-assistant-sales-004', 'contract-reviewer-sales-005'],
        'primary_providers': ['openai', 'google'],
        'cost_variance': 0.12
    },
    'Support': {
        'budget_monthly': 8000,
        'target_spend': 7600,  # 95% utilization (near limit!)
        'agents': ['ticket-classifier-support-001', 'response-generator-support-002',
                   'kb-search-support-003', 'escalation-detector-support-004',
                   'sentiment-analyzer-support-005', 'chat-assistant-support-006'],
        'primary_providers': ['openai', 'google'],  # Cheaper models
        'cost_variance': 0.08
    },
    'Marketing': {
        'budget_monthly': 6000,
        'target_spend': 4200,  # 70% utilization (under budget)
        'agents': ['content-generator-mktg-001', 'social-media-mktg-002',
                   'campaign-planner-mktg-003', 'ad-copy-mktg-004'],
        'primary_providers': ['openai', 'anthropic'],
        'cost_variance': 0.20
    }
}

# Model pricing per 1K tokens (simplified for demo)
MODEL_PRICING = {
    'gpt-4': {'prompt': 0.03, 'completion': 0.06},
    'gpt-3.5-turbo': {'prompt': 0.0005, 'completion': 0.0015},
    'claude-3-opus-20240229': {'prompt': 0.015, 'completion': 0.075},
    'claude-3-sonnet-20240229': {'prompt': 0.003, 'completion': 0.015},
    'claude-3-haiku-20240307': {'prompt': 0.00025, 'completion': 0.00125},
    'gemini-1.5-pro': {'prompt': 0.0035, 'completion': 0.0105},
    'gemini-1.5-flash': {'prompt': 0.00035, 'completion': 0.00105}
}

async def update_traces_with_cost_data(pool: asyncpg.Pool):
    """Add cost_usd to existing traces based on token counts and model"""
    print("📊 Updating existing traces with cost data...")

    # Update cost for each trace based on token counts
    update_query = """
        UPDATE traces
        SET cost_usd = CASE
            -- GPT-4
            WHEN model = 'gpt-4' THEN
                (COALESCE(tokens_input, 0) * 0.03 / 1000.0) + (COALESCE(tokens_output, 0) * 0.06 / 1000.0)
            -- GPT-3.5 Turbo
            WHEN model = 'gpt-3.5-turbo' THEN
                (COALESCE(tokens_input, 0) * 0.0005 / 1000.0) + (COALESCE(tokens_output, 0) * 0.0015 / 1000.0)
            -- Claude 3 Opus
            WHEN model = 'claude-3-opus-20240229' THEN
                (COALESCE(tokens_input, 0) * 0.015 / 1000.0) + (COALESCE(tokens_output, 0) * 0.075 / 1000.0)
            -- Claude 3 Sonnet
            WHEN model = 'claude-3-sonnet-20240229' THEN
                (COALESCE(tokens_input, 0) * 0.003 / 1000.0) + (COALESCE(tokens_output, 0) * 0.015 / 1000.0)
            -- Claude 3 Haiku
            WHEN model = 'claude-3-haiku-20240307' THEN
                (COALESCE(tokens_input, 0) * 0.00025 / 1000.0) + (COALESCE(tokens_output, 0) * 0.00125 / 1000.0)
            -- Gemini Pro
            WHEN model = 'gemini-1.5-pro' THEN
                (COALESCE(tokens_input, 0) * 0.0035 / 1000.0) + (COALESCE(tokens_output, 0) * 0.0105 / 1000.0)
            -- Gemini Flash
            WHEN model = 'gemini-1.5-flash' THEN
                (COALESCE(tokens_input, 0) * 0.00035 / 1000.0) + (COALESCE(tokens_output, 0) * 0.00105 / 1000.0)
            ELSE
                (COALESCE(tokens_input, 0) * 0.002 / 1000.0) + (COALESCE(tokens_output, 0) * 0.006 / 1000.0)  -- Default pricing
        END
        WHERE cost_usd IS NULL
    """

    result = await pool.execute(update_query)
    print(f"✅ Updated cost for traces: {result}")

    # Get statistics
    stats_query = """
        SELECT
            COUNT(*) as total_traces,
            COALESCE(SUM(cost_usd), 0) as total_cost,
            COALESCE(AVG(cost_usd), 0) as avg_cost,
            MIN(timestamp) as earliest,
            MAX(timestamp) as latest
        FROM traces
        WHERE cost_usd IS NOT NULL
    """
    stats = await pool.fetchrow(stats_query)

    print(f"\n💰 Cost Statistics:")
    print(f"   Total traces: {stats['total_traces']:,}")
    print(f"   Total cost: ${stats['total_cost']:,.2f}")
    print(f"   Avg cost per request: ${stats['avg_cost']:.4f}")
    print(f"   Date range: {stats['earliest']} to {stats['latest']}\n")

async def create_department_budgets(pool: asyncpg.Pool, workspace_id: uuid.UUID):
    """Create monthly budgets for each department"""
    print("💼 Creating department budgets...")

    # Create mock department UUIDs (in real system, these would come from departments table)
    dept_ids = {name: uuid.uuid4() for name in DEPARTMENTS.keys()}

    current_date = datetime.now()
    period_start = current_date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    # Get last day of month
    if current_date.month == 12:
        period_end = period_start.replace(year=current_date.year + 1, month=1, day=1) - timedelta(days=1)
    else:
        period_end = period_start.replace(month=current_date.month + 1, day=1) - timedelta(days=1)

    budgets_created = 0

    for dept_name, config in DEPARTMENTS.items():
        dept_id = dept_ids[dept_name]

        # Calculate spent amount (target_spend with some daily variance)
        days_elapsed = (current_date - period_start).days + 1
        daily_target = config['target_spend'] / 30
        spent = daily_target * days_elapsed * random.uniform(0.95, 1.05)

        # Calculate burn rate
        burn_rate = spent / days_elapsed if days_elapsed > 0 else 0

        # Calculate days until depletion
        remaining = config['budget_monthly'] - spent
        days_until_depletion = int(remaining / burn_rate) if burn_rate > 0 else 999

        # Calculate projected overrun
        days_remaining_in_month = (period_end - current_date).days
        projected_total = spent + (burn_rate * days_remaining_in_month)
        projected_overrun = max(0, projected_total - config['budget_monthly'])

        insert_query = """
            INSERT INTO department_budgets (
                workspace_id,
                department_id,
                budget_period,
                period_start_date,
                period_end_date,
                allocated_budget_usd,
                spent_to_date_usd,
                burn_rate_daily_usd,
                projected_overrun_usd,
                days_until_depletion,
                alert_threshold_warning,
                alert_threshold_critical,
                is_active,
                created_at,
                updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
            ON CONFLICT (workspace_id, department_id, budget_period, period_start_date, is_active)
            DO UPDATE SET
                spent_to_date_usd = EXCLUDED.spent_to_date_usd,
                burn_rate_daily_usd = EXCLUDED.burn_rate_daily_usd,
                projected_overrun_usd = EXCLUDED.projected_overrun_usd,
                days_until_depletion = EXCLUDED.days_until_depletion,
                updated_at = EXCLUDED.updated_at
        """

        await pool.execute(
            insert_query,
            workspace_id,
            dept_id,
            'monthly',
            period_start.date(),
            period_end.date(),
            float(config['budget_monthly']),
            float(spent),
            float(burn_rate),
            float(projected_overrun),
            days_until_depletion,
            80.0,  # Warning threshold
            95.0,  # Critical threshold
            True,
            current_date,
            current_date
        )

        budget_pct = (spent / config['budget_monthly']) * 100
        alert_status = 'red' if budget_pct >= 95 else ('yellow' if budget_pct >= 80 else 'green')

        print(f"   ✅ {dept_name}: ${spent:,.0f} / ${config['budget_monthly']:,} ({budget_pct:.1f}%) - {alert_status.upper()}")
        budgets_created += 1

    print(f"\n✅ Created {budgets_created} department budgets\n")
    return dept_ids

async def create_optimization_opportunities(pool: asyncpg.Pool, workspace_id: uuid.UUID):
    """Create predefined optimization opportunities"""
    print("🎯 Creating optimization opportunities...")

    opportunities = [
        {
            'type': 'model_downgrade',
            'agents': ['code-assistant-eng-001', 'proposal-writer-sales-002'],
            'current_cost': 1200,
            'optimized_cost': 800,
            'effort': 'low',
            'risk': 'low',
            'quality_impact': 'minimal',
            'details': {
                'current_config': {'model': 'gpt-4'},
                'recommended_config': {'model': 'gpt-3.5-turbo'},
                'implementation_steps': [
                    'Test GPT-3.5-turbo on 100 sample requests',
                    'Compare output quality with human evaluation',
                    'Gradual rollout: 10% → 50% → 100%',
                    'Monitor quality metrics for 1 week'
                ],
                'rollback_plan': 'Revert model config immediately if quality drops',
                'testing_checklist': ['Quality eval', 'Latency check', 'Cost validation']
            }
        },
        {
            'type': 'caching',
            'agents': ['kb-search-support-003', 'ticket-classifier-support-001'],
            'current_cost': 950,
            'optimized_cost': 380,
            'effort': 'medium',
            'risk': 'low',
            'quality_impact': 'none',
            'details': {
                'current_config': {'caching': False},
                'recommended_config': {'caching': True, 'cache_ttl': 3600, 'cache_type': 'semantic'},
                'implementation_steps': [
                    'Deploy Redis semantic cache layer',
                    'Configure 1-hour TTL',
                    'Monitor cache hit rate',
                    'Adjust TTL based on data freshness requirements'
                ],
                'rollback_plan': 'Disable caching flag in config',
                'testing_checklist': ['Cache hit rate >40%', 'Response freshness OK', 'Latency improved']
            }
        },
        {
            'type': 'prompt_optimization',
            'agents': ['content-generator-mktg-001', 'email-responder-sales-003'],
            'current_cost': 680,
            'optimized_cost': 476,
            'effort': 'medium',
            'risk': 'medium',
            'quality_impact': 'minimal',
            'details': {
                'current_config': {'prompt_tokens_avg': 2800},
                'recommended_config': {'prompt_tokens_avg': 1960},
                'implementation_steps': [
                    'Analyze prompts for redundancy',
                    'Remove verbose instructions',
                    'Use few-shot examples more efficiently',
                    'Test with LLM-as-judge quality eval'
                ],
                'rollback_plan': 'Revert to original prompt templates',
                'testing_checklist': ['Token reduction 30%', 'Quality maintained', 'Latency check']
            }
        },
        {
            'type': 'provider_switch',
            'agents': ['chat-assistant-support-006'],
            'current_cost': 540,
            'optimized_cost': 324,
            'effort': 'low',
            'risk': 'low',
            'quality_impact': 'none',
            'details': {
                'current_config': {'provider': 'openai', 'model': 'gpt-3.5-turbo'},
                'recommended_config': {'provider': 'anthropic', 'model': 'claude-3-haiku-20240307'},
                'implementation_steps': [
                    'Configure Anthropic API credentials',
                    'Test Claude Haiku on representative sample',
                    'Canary deployment: 20% traffic',
                    'Full rollout if metrics look good'
                ],
                'rollback_plan': 'Switch back to OpenAI in load balancer config',
                'testing_checklist': ['Quality parity', 'Cost reduction verified', 'Latency acceptable']
            }
        },
        {
            'type': 'caching',
            'agents': ['crm-assistant-sales-004'],
            'current_cost': 420,
            'optimized_cost': 210,
            'effort': 'low',
            'risk': 'low',
            'quality_impact': 'none',
            'details': {
                'current_config': {'caching': False},
                'recommended_config': {'caching': True, 'cache_ttl': 1800, 'cache_type': 'exact_match'},
                'implementation_steps': [
                    'Enable exact-match caching for common queries',
                    'Set 30-minute TTL',
                    'Monitor for stale data issues'
                ],
                'rollback_plan': 'Disable caching immediately',
                'testing_checklist': ['Cache hit rate >50%', 'No stale data complaints', 'Cost reduction']
            }
        },
        {
            'type': 'model_downgrade',
            'agents': ['doc-generator-eng-003'],
            'current_cost': 890,
            'optimized_cost': 712,
            'effort': 'low',
            'risk': 'low',
            'quality_impact': 'minimal',
            'details': {
                'current_config': {'model': 'claude-3-opus-20240229'},
                'recommended_config': {'model': 'claude-3-sonnet-20240229'},
                'implementation_steps': [
                    'A/B test Sonnet vs Opus on documentation tasks',
                    'Gradual rollout if quality is acceptable',
                    'Monitor doc quality metrics'
                ],
                'rollback_plan': 'Revert to Opus if doc quality drops',
                'testing_checklist': ['Quality eval passed', 'User feedback positive', 'Cost saved']
            }
        },
        {
            'type': 'prompt_optimization',
            'agents': ['lead-qualifier-sales-001'],
            'current_cost': 510,
            'optimized_cost': 357,
            'effort': 'medium',
            'risk': 'medium',
            'quality_impact': 'minimal',
            'details': {
                'current_config': {'prompt_tokens_avg': 3200},
                'recommended_config': {'prompt_tokens_avg': 2240},
                'implementation_steps': [
                    'Compress lead qualification criteria',
                    'Use structured output format',
                    'Reduce example verbosity',
                    'Test qualification accuracy'
                ],
                'rollback_plan': 'Restore full prompt if accuracy drops',
                'testing_checklist': ['Accuracy maintained', '30% token reduction', 'Speed improved']
            }
        },
        {
            'type': 'batching',
            'agents': ['sentiment-analyzer-support-005'],
            'current_cost': 380,
            'optimized_cost': 323,
            'effort': 'high',
            'risk': 'medium',
            'quality_impact': 'none',
            'details': {
                'current_config': {'batch_size': 1},
                'recommended_config': {'batch_size': 10, 'max_wait_ms': 500},
                'implementation_steps': [
                    'Implement request batching queue',
                    'Configure 10-request batch size',
                    'Set 500ms max wait time',
                    'Monitor latency impact'
                ],
                'rollback_plan': 'Disable batching, revert to individual requests',
                'testing_checklist': ['P95 latency <1s', 'Throughput increased', 'Cost reduced']
            }
        },
        {
            'type': 'provider_switch',
            'agents': ['test-writer-eng-004'],
            'current_cost': 720,
            'optimized_cost': 504,
            'effort': 'low',
            'risk': 'low',
            'quality_impact': 'minimal',
            'details': {
                'current_config': {'provider': 'anthropic', 'model': 'claude-3-opus-20240229'},
                'recommended_config': {'provider': 'google', 'model': 'gemini-1.5-pro'},
                'implementation_steps': [
                    'Configure Google AI credentials',
                    'Test Gemini Pro on test generation tasks',
                    'Compare test coverage and quality',
                    'Gradual rollout if satisfactory'
                ],
                'rollback_plan': 'Switch back to Anthropic',
                'testing_checklist': ['Test quality parity', 'Cost savings verified', 'Coverage maintained']
            }
        },
        {
            'type': 'token_reduction',
            'agents': ['api-designer-eng-007', 'contract-reviewer-sales-005'],
            'current_cost': 640,
            'optimized_cost': 480,
            'effort': 'medium',
            'risk': 'low',
            'quality_impact': 'none',
            'details': {
                'current_config': {'max_output_tokens': 4096},
                'recommended_config': {'max_output_tokens': 2048},
                'implementation_steps': [
                    'Analyze typical output lengths',
                    'Set output limit to 2048 tokens',
                    'Enable streaming cutoff at limit',
                    'Monitor for truncated outputs'
                ],
                'rollback_plan': 'Increase max_output_tokens back to 4096',
                'testing_checklist': ['No truncation complaints', '25% cost reduction', 'Quality maintained']
            }
        }
    ]

    opportunities_created = 0

    for opp in opportunities:
        savings = opp['current_cost'] - opp['optimized_cost']

        insert_query = """
            INSERT INTO cost_optimization_opportunities (
                workspace_id,
                optimization_type,
                affected_agents,
                current_cost_monthly_usd,
                optimized_cost_monthly_usd,
                implementation_effort,
                technical_risk,
                quality_impact,
                recommendation_details,
                status,
                priority_score,
                identified_by,
                created_at,
                updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
        """

        # Calculate priority score based on savings, effort, and risk
        savings_score = min(50, (savings / 1000) * 30)  # Up to 50 points for savings
        effort_penalty = {'low': 0, 'medium': -10, 'high': -20}[opp['effort']]
        risk_penalty = {'low': 0, 'medium': -5, 'high': -15}[opp['risk']]
        priority = int(50 + savings_score + effort_penalty + risk_penalty)
        priority = max(0, min(100, priority))  # Clamp to 0-100

        import json
        await pool.execute(
            insert_query,
            workspace_id,
            opp['type'],
            opp['agents'],
            float(opp['current_cost']),
            float(opp['optimized_cost']),
            opp['effort'],
            opp['risk'],
            opp['quality_impact'],
            json.dumps(opp['details']),  # Convert dict to JSON string
            'identified',
            priority,
            'system_ml',
            datetime.now(),
            datetime.now()
        )

        print(f"   ✅ {opp['type'].replace('_', ' ').title()}: ${savings:.0f}/mo savings (Priority: {priority})")
        opportunities_created += 1

    print(f"\n✅ Created {opportunities_created} optimization opportunities\n")

async def main():
    """Main execution function"""
    print("\n" + "="*70)
    print("💰 COST MANAGEMENT SYNTHETIC DATA GENERATOR")
    print("="*70 + "\n")

    # Default workspace ID (should match your actual workspace)
    workspace_id = uuid.UUID('00000000-0000-0000-0000-000000000001')

    try:
        # Connect to TimescaleDB (for traces)
        print("🔌 Connecting to TimescaleDB...")
        timescale_pool = await asyncpg.create_pool(**TIMESCALE_CONFIG, min_size=1, max_size=5)
        print("✅ Connected to TimescaleDB\n")

        # Connect to PostgreSQL (for metadata)
        print("🔌 Connecting to PostgreSQL...")
        postgres_pool = await asyncpg.create_pool(**POSTGRES_CONFIG, min_size=1, max_size=5)
        print("✅ Connected to PostgreSQL\n")

        # Step 1: Add cost data to existing traces
        await update_traces_with_cost_data(timescale_pool)

        # Step 2: Create department budgets
        dept_ids = await create_department_budgets(postgres_pool, workspace_id)

        # Step 3: Create optimization opportunities
        await create_optimization_opportunities(postgres_pool, workspace_id)

        print("="*70)
        print("✅ COST DATA GENERATION COMPLETE!")
        print("="*70)
        print("\nNext steps:")
        print("  1. Refresh continuous aggregates (if created)")
        print("  2. Test backend APIs")
        print("  3. View Cost Management dashboard\n")

    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        # Close connections
        if 'timescale_pool' in locals():
            await timescale_pool.close()
        if 'postgres_pool' in locals():
            await postgres_pool.close()
        print("🔌 Database connections closed\n")

if __name__ == "__main__":
    asyncio.run(main())
