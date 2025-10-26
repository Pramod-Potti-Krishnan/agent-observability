"""Environment configuration checker.

Verifies that all required environment variables are set correctly.
"""

from dotenv import load_dotenv
import os
import sys

load_dotenv()

required_vars = {
    'TIMESCALE_URL': 'TimescaleDB connection string',
    'POSTGRES_URL': 'PostgreSQL connection string',
    'REDIS_URL': 'Redis connection string',
}

optional_vars = {
    'GEMINI_API_KEY': 'Google Gemini API key (Phase 4+)',
    'JWT_SECRET': 'JWT secret (Phase 1+)',
    'API_KEY_SALT': 'API key salt (Phase 1+)',
    'PERSPECTIVE_API_KEY': 'Perspective API key for toxicity detection (Phase 4+, optional)',
    'SLACK_WEBHOOK_URL': 'Slack webhook for alerts (Phase 4+, optional)',
}

def mask_sensitive_value(value: str, show_chars: int = 20) -> str:
    """Mask sensitive parts of a value for display."""
    if not value:
        return "NOT SET"

    if len(value) > show_chars:
        # Show first 20 chars and mask the rest
        return value[:show_chars] + '...' + '*' * min(10, len(value) - show_chars)
    else:
        # For short values, show prefix and mask rest
        visible = min(8, len(value) // 2)
        return value[:visible] + '*' * (len(value) - visible)


def check_url_format(url: str, var_name: str) -> bool:
    """Basic validation of database URL format."""
    if not url:
        return False

    if var_name.startswith('TIMESCALE') or var_name.startswith('POSTGRES'):
        if not url.startswith('postgresql://'):
            print(f"    ⚠️  Warning: {var_name} should start with 'postgresql://'")
            return False
    elif 'REDIS' in var_name:
        if not (url.startswith('redis://') or url.startswith('rediss://')):
            print(f"    ⚠️  Warning: {var_name} should start with 'redis://' or 'rediss://'")
            return False

    return True


def main():
    print("=" * 70)
    print("Agent Observability Platform - Environment Configuration Check")
    print("=" * 70)

    print("\n📋 Required Variables (Phase 0+):")
    all_good = True

    for var, description in required_vars.items():
        value = os.getenv(var)
        if value:
            display_value = mask_sensitive_value(value)
            print(f"  ✅ {var:20} = {display_value}")

            # Validate format
            if not check_url_format(value, var):
                all_good = False
        else:
            print(f"  ❌ {var:20} = MISSING")
            print(f"     Description: {description}")
            all_good = False

    print("\n🔧 Optional Variables:")
    for var, description in optional_vars.items():
        value = os.getenv(var)
        if value:
            display_value = mask_sensitive_value(value)
            print(f"  ✅ {var:20} = {display_value}")
        else:
            print(f"  ⚠️  {var:20} = Not set")
            print(f"     Description: {description}")

    # Check for common .env file issues
    print("\n🔍 Additional Checks:")

    # Check if .env file exists
    if os.path.exists('.env'):
        print("  ✅ .env file exists")
    elif os.path.exists('../.env'):
        print("  ✅ .env file exists in parent directory")
    else:
        print("  ⚠️  .env file not found (using environment variables or defaults)")

    # Check NODE_ENV and PYTHON_ENV
    node_env = os.getenv('NODE_ENV', 'development')
    python_env = os.getenv('PYTHON_ENV', 'development')
    debug = os.getenv('DEBUG', 'true')

    print(f"  ℹ️  NODE_ENV = {node_env}")
    print(f"  ℹ️  PYTHON_ENV = {python_env}")
    print(f"  ℹ️  DEBUG = {debug}")

    if python_env == 'production' and debug.lower() == 'true':
        print("  ⚠️  Warning: DEBUG is enabled in production mode")

    # Security checks for production
    if python_env == 'production':
        print("\n🔒 Production Security Checks:")

        jwt_secret = os.getenv('JWT_SECRET')
        if jwt_secret and len(jwt_secret) < 32:
            print("  ⚠️  Warning: JWT_SECRET should be at least 32 characters")
            all_good = False

        api_key_salt = os.getenv('API_KEY_SALT')
        if api_key_salt and len(api_key_salt) < 32:
            print("  ⚠️  Warning: API_KEY_SALT should be at least 32 characters")
            all_good = False

        # Check for default passwords in production
        for var in ['TIMESCALE_URL', 'POSTGRES_URL', 'REDIS_URL']:
            value = os.getenv(var, '')
            if 'postgres:postgres' in value or 'redis123' in value:
                print(f"  ❌ {var} contains default password - CHANGE FOR PRODUCTION!")
                all_good = False

    print("\n" + "=" * 70)
    if all_good:
        print("✅ All required environment variables are properly configured!")
        print("=" * 70)
        print("\nNext steps:")
        print("  1. Start Docker containers: docker-compose up -d")
        print("  2. Test connections: python test_connections.py")
        print("  3. Run tests: pytest")
        sys.exit(0)
    else:
        print("❌ Some configuration issues detected. Please review above.")
        print("=" * 70)
        print("\nTo fix:")
        print("  1. Copy .env.example to .env: cp .env.example .env")
        print("  2. Edit .env and set the missing variables")
        print("  3. Run this script again to verify")
        sys.exit(1)


if __name__ == "__main__":
    main()
