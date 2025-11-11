#!/usr/bin/env python3
"""
Synthetic Data Generator for AI Agent Observability Platform

This script populates the traces table with realistic user data to enable
all analytics features including:
- User segmentation (Power, Regular, New, Dormant)
- Intent distribution analysis
- Department analytics
- Retention cohort analysis

Usage:
    python generate_synthetic_data.py [--dry-run]
"""

import asyncio
import asyncpg
import random
import uuid
from datetime import datetime, timedelta
from typing import List, Dict
import argparse

# Configuration
TIMESCALE_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'user': 'postgres',
    'password': 'postgres',
    'database': 'agent_observability'
}

# Synthetic User Data
USER_NAMES = [
    # Engineering
    "alice.engineer", "bob.developer", "carol.architect", "david.devops", "emma.backend",
    "frank.frontend", "grace.fullstack", "henry.ml", "iris.data", "jack.qa",

    # Product & Design
    "kate.product", "liam.designer", "maya.ux", "noah.pm", "olivia.analyst",

    # Sales & Marketing
    "paul.sales", "quinn.marketing", "rachel.growth", "steve.account", "tina.sales",

    # Customer Success
    "uma.support", "victor.success", "wendy.onboarding", "xavier.trainer", "yara.support",

    # Operations
    "zack.ops", "amy.finance", "brian.hr", "claire.legal", "daniel.admin",

    # Leadership
    "eve.cto", "fred.vp", "gina.director", "hugo.manager", "iris.lead",

    # Additional power users
    "poweruser1", "poweruser2", "poweruser3", "poweruser4", "poweruser5",

    # New users (last 30 days)
    "newbie1", "newbie2", "newbie3", "newbie4", "newbie5",
    "newbie6", "newbie7", "newbie8", "newbie9", "newbie10"
]

# Intent categories (must match database constraint)
INTENT_CATEGORIES = [
    'code_generation',
    'customer_support',
    'data_analysis',
    'content_creation',
    'automation',
    'research',
    'translation',
    'general_assistance'
]

# User segment weights for realistic distribution
USER_SEGMENT_WEIGHTS = {
    'power_user': 0.10,  # Top 10% by activity
    'regular': 0.40,      # 40% regular users
    'new': 0.20,          # 20% new users (< 30 days)
    'dormant': 0.10,      # 10% dormant (no recent activity)
    None: 0.20            # 20% unclassified/struggling
}

# Department ID mapping (from existing traces)
DEPARTMENT_IDS = [
    '094a28fe-5142-43af-b245-dcb155816896',  # Engineering
    '317ce307-6465-47cf-855b-294e61d08cbb',  # Product
    '51e569a5-9092-4fd4-a1ed-0c1ce478867f',  # Sales
    '552e17db-a105-44e9-b1d0-387b02fb69b4',  # Customer Success
    '5cabcbcb-0d57-449a-9d90-457fadbefdaa',  # Operations
]

class SyntheticDataGenerator:
    def __init__(self, pool: asyncpg.Pool, dry_run: bool = False):
        self.pool = pool
        self.dry_run = dry_run
        self.workspace_id = None
        self.environment_ids = []
        self.stats = {
            'total_traces': 0,
            'updated_traces': 0,
            'users_created': 0
        }

    async def initialize(self):
        """Get workspace ID and environment IDs"""
        # Get workspace ID
        result = await self.pool.fetchrow(
            "SELECT DISTINCT workspace_id FROM traces LIMIT 1"
        )
        if not result:
            raise Exception("No traces found in database")
        self.workspace_id = result['workspace_id']

        # Get environment IDs
        result = await self.pool.fetch(
            "SELECT DISTINCT environment_id FROM traces LIMIT 10"
        )
        self.environment_ids = [row['environment_id'] for row in result]

        print(f"✓ Workspace ID: {self.workspace_id}")
        print(f"✓ Found {len(self.environment_ids)} environments")

    def assign_user_segment(self, user_index: int, total_users: int) -> str:
        """Assign user segment based on weighted distribution"""
        percentile = user_index / total_users

        if percentile < 0.10:
            return 'power_user'
        elif percentile < 0.50:
            return 'regular'
        elif percentile < 0.70:
            return 'new'
        elif percentile < 0.80:
            return 'dormant'
        else:
            return None  # Struggling/unclassified

    def assign_intent_for_user(self, user_id: str) -> str:
        """Assign primary intent based on user role"""
        if 'engineer' in user_id or 'developer' in user_id or 'backend' in user_id:
            return random.choice(['code_generation', 'automation', 'research'])
        elif 'support' in user_id or 'success' in user_id:
            return random.choice(['customer_support', 'general_assistance'])
        elif 'data' in user_id or 'analyst' in user_id:
            return 'data_analysis'
        elif 'designer' in user_id or 'ux' in user_id or 'marketing' in user_id:
            return random.choice(['content_creation', 'research'])
        elif 'sales' in user_id:
            return random.choice(['customer_support', 'general_assistance', 'content_creation'])
        else:
            # Random distribution for generic users
            return random.choice(INTENT_CATEGORIES)

    def assign_department_for_user(self, user_id: str) -> str:
        """Assign department based on user role"""
        if any(x in user_id for x in ['engineer', 'developer', 'backend', 'frontend', 'fullstack', 'devops', 'ml', 'qa']):
            return DEPARTMENT_IDS[0]  # Engineering
        elif any(x in user_id for x in ['product', 'designer', 'ux', 'pm', 'analyst']):
            return DEPARTMENT_IDS[1]  # Product
        elif any(x in user_id for x in ['sales', 'account', 'marketing', 'growth']):
            return DEPARTMENT_IDS[2]  # Sales
        elif any(x in user_id for x in ['support', 'success', 'onboarding', 'trainer']):
            return DEPARTMENT_IDS[3]  # Customer Success
        else:
            return DEPARTMENT_IDS[4]  # Operations

    async def update_existing_traces(self):
        """Update existing traces with user_id and intent"""
        print("\n📊 Analyzing existing traces...")

        # Get total traces without user_id
        result = await self.pool.fetchrow(
            "SELECT COUNT(*) as count FROM traces WHERE user_id IS NULL"
        )
        total_nulls = result['count']
        self.stats['total_traces'] = total_nulls

        print(f"Found {total_nulls:,} traces without user_id")

        if total_nulls == 0:
            print("✓ All traces already have user_id")
            return

        if self.dry_run:
            print("🔍 DRY RUN: Would update traces with user assignments")
            print(f"   Users to assign: {len(USER_NAMES)}")
            return

        print("\n🔄 Updating traces with synthetic user data...")
        print("   This may take a few minutes for large datasets...")

        # Assign users in batches for better performance
        batch_size = 10000
        updated = 0

        # Create a mapping of trace IDs to user assignments
        # We'll process in batches to avoid memory issues
        for i in range(0, len(USER_NAMES)):
            user_id = USER_NAMES[i]
            user_segment = self.assign_user_segment(i, len(USER_NAMES))
            primary_intent = self.assign_intent_for_user(user_id)
            department_id = self.assign_department_for_user(user_id)

            # Calculate how many traces this user should get
            # Power users get more, dormant users get fewer
            if user_segment == 'power_user':
                trace_ratio = 0.25  # Power users get 25% of traces
            elif user_segment == 'regular':
                trace_ratio = 0.50  # Regular users get 50% of traces
            elif user_segment == 'new':
                trace_ratio = 0.15  # New users get 15% of traces
            elif user_segment == 'dormant':
                trace_ratio = 0.05  # Dormant users get 5% of traces
            else:
                trace_ratio = 0.05  # Others get 5% of traces

            # Limit to max 10,000 traces per user to avoid memory issues
            user_trace_count = min(10000, int((total_nulls / len(USER_NAMES)) * (1 + random.uniform(-0.3, 0.3))))

            # Update traces for this user in smaller chunks
            query = """
                UPDATE traces
                SET
                    user_id = $1,
                    user_segment = $2,
                    intent_category = CASE
                        WHEN RANDOM() < 0.7 THEN $3  -- 70% primary intent
                        ELSE (SELECT unnest(ARRAY['code_generation', 'customer_support', 'data_analysis', 'content_creation', 'automation', 'research', 'translation', 'general_assistance'])
                              ORDER BY RANDOM() LIMIT 1)  -- 30% random
                    END,
                    department_id = $4
                WHERE trace_id IN (
                    SELECT trace_id
                    FROM traces
                    WHERE user_id IS NULL
                    ORDER BY RANDOM()
                    LIMIT $5
                )
            """

            try:
                await self.pool.execute(
                    query,
                    user_id,
                    user_segment,
                    primary_intent,
                    uuid.UUID(department_id),
                    user_trace_count
                )
                updated += user_trace_count
                self.stats['updated_traces'] = updated
                self.stats['users_created'] += 1

                if (i + 1) % 5 == 0:
                    progress = (updated / total_nulls) * 100
                    print(f"   Progress: {updated:,}/{total_nulls:,} traces ({progress:.1f}%) - {self.stats['users_created']} users")

            except Exception as e:
                print(f"   ⚠️  Error updating traces for user {user_id}: {e}")
                continue

        print(f"\n✓ Updated {updated:,} traces with user data")
        print(f"✓ Created {self.stats['users_created']} user profiles")

    async def print_summary(self):
        """Print summary statistics"""
        print("\n" + "="*60)
        print("📈 DATA GENERATION SUMMARY")
        print("="*60)

        # User statistics
        result = await self.pool.fetch("""
            SELECT
                user_segment,
                COUNT(DISTINCT user_id) as users,
                COUNT(*) as traces
            FROM traces
            WHERE user_id IS NOT NULL
            GROUP BY user_segment
            ORDER BY
                CASE user_segment
                    WHEN 'power_user' THEN 1
                    WHEN 'regular' THEN 2
                    WHEN 'new' THEN 3
                    WHEN 'dormant' THEN 4
                    ELSE 5
                END
        """)

        print("\n👥 User Segments:")
        for row in result:
            segment = row['user_segment'] or 'Unclassified'
            print(f"   {segment:15} {row['users']:3} users, {row['traces']:,} traces")

        # Intent distribution
        result = await self.pool.fetch("""
            SELECT intent_category, COUNT(*) as count
            FROM traces
            GROUP BY intent_category
            ORDER BY count DESC
            LIMIT 10
        """)

        print("\n🎯 Intent Distribution:")
        for row in result:
            print(f"   {row['intent_category']:20} {row['count']:,} traces")

        # Department distribution
        result = await self.pool.fetch("""
            SELECT department_id, COUNT(DISTINCT user_id) as users, COUNT(*) as traces
            FROM traces
            WHERE user_id IS NOT NULL
            GROUP BY department_id
            ORDER BY traces DESC
        """)

        print("\n🏢 Department Distribution:")
        for i, row in enumerate(result[:5], 1):
            print(f"   Dept {i:2}: {row['users']:3} users, {row['traces']:,} traces")

        # Overall stats
        result = await self.pool.fetchrow("""
            SELECT
                COUNT(*) as total,
                COUNT(user_id) as with_users,
                COUNT(DISTINCT user_id) as unique_users
            FROM traces
        """)

        print("\n📊 Overall Statistics:")
        print(f"   Total traces:       {result['total']:,}")
        print(f"   With user_id:       {result['with_users']:,} ({result['with_users']/result['total']*100:.1f}%)")
        print(f"   Unique users:       {result['unique_users']}")

        print("\n" + "="*60)
        print("✅ Synthetic data generation complete!")
        print("="*60)


async def main():
    parser = argparse.ArgumentParser(description='Generate synthetic user data for traces')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be done without making changes')
    args = parser.parse_args()

    print("="*60)
    print("🚀 AI AGENT OBSERVABILITY - SYNTHETIC DATA GENERATOR")
    print("="*60)

    if args.dry_run:
        print("\n🔍 DRY RUN MODE - No changes will be made\n")

    try:
        # Connect to database
        print("\n📡 Connecting to TimescaleDB...")
        pool = await asyncpg.create_pool(**TIMESCALE_CONFIG, min_size=1, max_size=5)
        print("✓ Connected successfully")

        # Create generator
        generator = SyntheticDataGenerator(pool, dry_run=args.dry_run)

        # Initialize
        await generator.initialize()

        # Generate data
        await generator.update_existing_traces()

        # Print summary
        if not args.dry_run:
            await generator.print_summary()

        # Close pool
        await pool.close()

        print("\n✨ Done!\n")

    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return 1

    return 0


if __name__ == '__main__':
    exit(asyncio.run(main()))
