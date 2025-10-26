"""Test database connections.

Verifies connectivity to TimescaleDB, PostgreSQL, and Redis.
"""

import asyncio
import asyncpg
import redis
from dotenv import load_dotenv
import os
import sys

load_dotenv()


async def test_timescale():
    """Test TimescaleDB connection."""
    print("\n🔍 Testing TimescaleDB connection...")

    try:
        url = os.getenv('TIMESCALE_URL')
        if not url:
            print("  ❌ TIMESCALE_URL not set")
            return False

        print(f"  📡 Connecting to: {url.split('@')[1] if '@' in url else url}")

        conn = await asyncpg.connect(url)

        # Check version
        version = await conn.fetchval('SELECT version()')
        print(f"  ✅ Connected: {version.split(',')[0]}")

        # Check TimescaleDB extension
        has_timescale = await conn.fetchval(
            "SELECT COUNT(*) FROM pg_extension WHERE extname = 'timescaledb'"
        )

        if has_timescale:
            ts_version = await conn.fetchval("SELECT extversion FROM pg_extension WHERE extname = 'timescaledb'")
            print(f"  ✅ TimescaleDB extension: v{ts_version}")
        else:
            print("  ⚠️  TimescaleDB extension not installed")
            await conn.close()
            return False

        # Check hypertables
        hypertables = await conn.fetch(
            "SELECT hypertable_name FROM timescaledb_information.hypertables"
        )

        if hypertables:
            print(f"  ✅ Hypertables found: {len(hypertables)}")
            for row in hypertables:
                print(f"     - {row['hypertable_name']}")
        else:
            print("  ⚠️  No hypertables found (run setup.sh to create schemas)")

        # Test query
        count = await conn.fetchval('SELECT COUNT(*) FROM traces')
        print(f"  ✅ Traces count: {count:,}")

        await conn.close()
        return True

    except asyncpg.exceptions.InvalidCatalogNameError:
        print("  ❌ Database does not exist. Run setup.sh to create it.")
        return False
    except asyncpg.exceptions.InvalidPasswordError:
        print("  ❌ Invalid password. Check TIMESCALE_URL in .env")
        return False
    except ConnectionRefusedError:
        print("  ❌ Connection refused. Is Docker running? (docker-compose up -d)")
        return False
    except Exception as e:
        print(f"  ❌ Connection failed: {type(e).__name__}: {str(e)}")
        return False


async def test_postgres():
    """Test PostgreSQL connection."""
    print("\n🔍 Testing PostgreSQL connection...")

    try:
        url = os.getenv('POSTGRES_URL')
        if not url:
            print("  ❌ POSTGRES_URL not set")
            return False

        print(f"  📡 Connecting to: {url.split('@')[1] if '@' in url else url}")

        conn = await asyncpg.connect(url)

        # Check version
        version = await conn.fetchval('SELECT version()')
        print(f"  ✅ Connected: {version.split(',')[0]}")

        # Check tables
        tables = await conn.fetch(
            """
            SELECT table_name FROM information_schema.tables
            WHERE table_schema = 'public'
            ORDER BY table_name
            """
        )

        if tables:
            print(f"  ✅ Tables found: {len(tables)}")
            table_names = [row['table_name'] for row in tables]

            # Check for key tables
            key_tables = ['workspaces', 'users', 'agents', 'api_keys']
            for table in key_tables:
                if table in table_names:
                    count = await conn.fetchval(f'SELECT COUNT(*) FROM {table}')
                    print(f"     - {table}: {count} rows")
                else:
                    print(f"     ⚠️  {table} table missing")
        else:
            print("  ⚠️  No tables found (run setup.sh to create schemas)")

        await conn.close()
        return True

    except asyncpg.exceptions.InvalidCatalogNameError:
        print("  ❌ Database does not exist. Run setup.sh to create it.")
        return False
    except asyncpg.exceptions.InvalidPasswordError:
        print("  ❌ Invalid password. Check POSTGRES_URL in .env")
        return False
    except ConnectionRefusedError:
        print("  ❌ Connection refused. Is Docker running? (docker-compose up -d)")
        return False
    except Exception as e:
        print(f"  ❌ Connection failed: {type(e).__name__}: {str(e)}")
        return False


def test_redis():
    """Test Redis connection."""
    print("\n🔍 Testing Redis connection...")

    try:
        redis_url = os.getenv('REDIS_URL')
        if not redis_url:
            print("  ❌ REDIS_URL not set")
            return False

        print(f"  📡 Connecting to Redis...")

        # Parse Redis URL
        # Format: redis://:password@host:port/db
        if redis_url.startswith('redis://'):
            # Remove redis://
            url_part = redis_url.replace('redis://', '')

            # Extract password if present
            if ':' in url_part and '@' in url_part:
                password = url_part.split(':')[1].split('@')[0]
                host_port_db = url_part.split('@')[1]
            else:
                password = None
                host_port_db = url_part

            # Extract host, port, db
            parts = host_port_db.split(':')
            host = parts[0]

            if len(parts) > 1:
                port_db = parts[1].split('/')
                port = int(port_db[0])
                db = int(port_db[1]) if len(port_db) > 1 else 0
            else:
                port = 6379
                db = 0
        else:
            print("  ❌ Invalid REDIS_URL format")
            return False

        print(f"  📡 Connecting to: {host}:{port} (db={db})")

        # Connect
        r = redis.Redis(
            host=host,
            port=port,
            password=password,
            db=db,
            decode_responses=True
        )

        # Test ping
        if r.ping():
            print("  ✅ Connected: PING successful")
        else:
            print("  ❌ PING failed")
            return False

        # Get info
        info = r.info()
        print(f"  ✅ Redis version: {info.get('redis_version')}")
        print(f"  ✅ Memory used: {info.get('used_memory_human')}")
        print(f"  ✅ Connected clients: {info.get('connected_clients')}")

        # Test set/get
        test_key = 'test:connection_check'
        test_value = 'success'

        r.set(test_key, test_value, ex=10)  # Expire in 10 seconds
        result = r.get(test_key)

        if result == test_value:
            print("  ✅ SET/GET test successful")
            r.delete(test_key)
        else:
            print("  ⚠️  SET/GET test failed")
            return False

        return True

    except redis.exceptions.AuthenticationError:
        print("  ❌ Authentication failed. Check REDIS_URL password")
        return False
    except redis.exceptions.ConnectionError:
        print("  ❌ Connection refused. Is Docker running? (docker-compose up -d)")
        return False
    except Exception as e:
        print(f"  ❌ Connection failed: {type(e).__name__}: {str(e)}")
        return False


async def main():
    """Run all connection tests."""
    print("=" * 70)
    print("Agent Observability Platform - Database Connection Tests")
    print("=" * 70)

    results = []

    # Test TimescaleDB
    results.append(await test_timescale())

    # Test PostgreSQL
    results.append(await test_postgres())

    # Test Redis
    results.append(test_redis())

    # Summary
    print("\n" + "=" * 70)
    print("Test Summary")
    print("=" * 70)

    total = len(results)
    passed = sum(results)
    failed = total - passed

    print(f"\n  Total:  {total} connections")
    print(f"  ✅ Passed: {passed}")
    print(f"  ❌ Failed: {failed}")

    if all(results):
        print("\n✅ All database connections successful!")
        print("\nYou're ready to:")
        print("  1. Run synthetic data generator: python synthetic_data/generator.py")
        print("  2. Load data: python synthetic_data/load_data.py")
        print("  3. Run tests: pytest")
        print("=" * 70)
        sys.exit(0)
    else:
        print("\n❌ Some connections failed.")
        print("\nTroubleshooting steps:")
        print("  1. Check Docker containers: docker-compose ps")
        print("  2. Start containers: docker-compose up -d")
        print("  3. Check logs: docker-compose logs <service-name>")
        print("  4. Verify .env file: python check_env.py")
        print("=" * 70)
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
