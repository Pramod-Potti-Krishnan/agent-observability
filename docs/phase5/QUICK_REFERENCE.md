# Phase 5 Settings Database - Quick Reference Guide

## File Locations

All Phase 5 database files are located in:

```
/Users/pk1980/Documents/Software/Agent Monitoring/
├── backend/
│   ├── alembic/versions/
│   │   └── phase5_001_settings_tables.py      # Alembic migration
│   └── db/
│       ├── phase5_001_settings_tables_up.sql   # Standalone migration (upgrade)
│       ├── phase5_001_settings_tables_down.sql # Standalone migration (rollback)
│       └── phase5_seed_data.sql                # Development seed data
└── docs/phase5/
    ├── DATABASE_SCHEMA_PHASE5.md               # Complete schema documentation
    └── QUICK_REFERENCE.md                      # This file
```

---

## Running the Migration

### Option 1: Using Alembic (Recommended)

```bash
# Navigate to backend directory
cd /Users/pk1980/Documents/Software/Agent\ Monitoring/backend

# Review migration before applying
alembic show phase5_001_settings

# Apply migration
alembic upgrade head

# If you need to rollback
alembic downgrade -1
```

### Option 2: Using psql (Direct SQL)

```bash
# Connect to PostgreSQL (port 5433)
psql -h localhost -p 5433 -U postgres -d observability

# Run migration
\i /Users/pk1980/Documents/Software/Agent\ Monitoring/backend/db/phase5_001_settings_tables_up.sql

# If you need to rollback
\i /Users/pk1980/Documents/Software/Agent\ Monitoring/backend/db/phase5_001_settings_tables_down.sql
```

### Option 3: Using Docker (If database is containerized)

```bash
# Copy migration file into container
docker cp backend/db/phase5_001_settings_tables_up.sql postgres_container:/tmp/

# Execute migration
docker exec -it postgres_container psql -U postgres -d observability -f /tmp/phase5_001_settings_tables_up.sql
```

---

## Loading Seed Data

After running the migration, load test data:

```bash
# Using psql
psql -h localhost -p 5433 -U postgres -d observability \
  -f /Users/pk1980/Documents/Software/Agent\ Monitoring/backend/db/phase5_seed_data.sql

# Or within psql session
\i /Users/pk1980/Documents/Software/Agent\ Monitoring/backend/db/phase5_seed_data.sql
```

---

## Verification Queries

### Check Tables Were Created

```sql
-- List Phase 5 tables
SELECT tablename, schemaname
FROM pg_tables
WHERE tablename IN ('team_members', 'billing_config', 'integrations_config')
  AND schemaname = 'public';

-- Count columns in each table
SELECT
    table_name,
    COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('team_members', 'billing_config', 'integrations_config')
GROUP BY table_name;
```

### Check Indexes Were Created

```sql
-- List indexes for Phase 5 tables
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename IN ('team_members', 'billing_config', 'integrations_config')
ORDER BY tablename, indexname;
```

### Verify Seed Data

```sql
-- Team members summary
SELECT role, status, COUNT(*) AS count
FROM team_members
WHERE workspace_id = '00000000-0000-0000-0000-000000000001'
GROUP BY role, status;

-- Billing configuration
SELECT
    plan_type,
    traces_current_month,
    traces_per_month_limit,
    ROUND((traces_current_month::NUMERIC / NULLIF(traces_per_month_limit, 0) * 100), 2) AS usage_percent
FROM billing_config
WHERE workspace_id = '00000000-0000-0000-0000-000000000001';

-- Integrations status
SELECT
    integration_type,
    integration_name,
    is_enabled,
    health_status,
    total_events_sent
FROM integrations_config
WHERE workspace_id = '00000000-0000-0000-0000-000000000001'
ORDER BY integration_type;
```

---

## Table Schema Quick Reference

### 1. team_members

**Purpose:** Workspace team management with RBAC

**Key Columns:**
- `workspace_id` (UUID, FK to workspaces) - Multi-tenant isolation
- `user_id` (UUID, FK to users) - Team member reference
- `role` (VARCHAR) - owner, admin, member, viewer
- `status` (VARCHAR) - pending, active, inactive
- `invitation_token` (VARCHAR) - Secure invitation token
- `deleted_at` (TIMESTAMPTZ) - Soft delete timestamp

**Common Queries:**

```sql
-- Get active team members for workspace
SELECT tm.*, u.email, u.full_name
FROM team_members tm
JOIN users u ON tm.user_id = u.id
WHERE tm.workspace_id = :workspace_id
  AND tm.status = 'active'
  AND tm.deleted_at IS NULL
ORDER BY tm.role, tm.created_at;

-- Count team members by role
SELECT role, COUNT(*) AS count
FROM team_members
WHERE workspace_id = :workspace_id
  AND status = 'active'
  AND deleted_at IS NULL
GROUP BY role;

-- Get pending invitations
SELECT *
FROM team_members
WHERE workspace_id = :workspace_id
  AND status = 'pending'
  AND invitation_expires_at > NOW()
  AND deleted_at IS NULL;
```

### 2. billing_config

**Purpose:** Subscription plans, usage limits, and billing

**Key Columns:**
- `workspace_id` (UUID, UNIQUE FK) - One-to-one with workspace
- `plan_type` (VARCHAR) - free, starter, professional, enterprise
- `plan_status` (VARCHAR) - active, trialing, past_due, canceled, suspended
- `traces_per_month_limit` (INTEGER) - Monthly trace limit
- `traces_current_month` (INTEGER) - Current usage
- `stripe_customer_id` (VARCHAR) - Stripe integration

**Common Queries:**

```sql
-- Get billing config for workspace
SELECT *
FROM billing_config
WHERE workspace_id = :workspace_id;

-- Check if usage limit exceeded
SELECT
    workspace_id,
    traces_current_month,
    traces_per_month_limit,
    traces_current_month >= traces_per_month_limit AS limit_exceeded
FROM billing_config
WHERE workspace_id = :workspace_id;

-- Get workspaces approaching limits (>80% usage)
SELECT
    bc.workspace_id,
    w.name,
    bc.traces_current_month,
    bc.traces_per_month_limit,
    ROUND((bc.traces_current_month::NUMERIC / bc.traces_per_month_limit * 100), 2) AS usage_percent
FROM billing_config bc
JOIN workspaces w ON bc.workspace_id = w.id
WHERE bc.plan_status = 'active'
  AND bc.traces_per_month_limit IS NOT NULL
  AND bc.traces_current_month::NUMERIC / bc.traces_per_month_limit >= 0.8
ORDER BY usage_percent DESC;
```

### 3. integrations_config

**Purpose:** External service integrations (Slack, PagerDuty, etc.)

**Key Columns:**
- `workspace_id` (UUID, FK to workspaces) - Multi-tenant isolation
- `integration_type` (VARCHAR) - slack, pagerduty, webhook, sentry, datadog, custom
- `integration_name` (VARCHAR) - User-friendly name
- `config_data` (JSONB) - Type-specific configuration
- `credentials_encrypted` (TEXT) - Encrypted credentials (AES-256-GCM)
- `is_enabled` (BOOLEAN) - Active status
- `health_status` (VARCHAR) - healthy, degraded, unhealthy, unknown

**Common Queries:**

```sql
-- Get enabled integrations for workspace
SELECT *
FROM integrations_config
WHERE workspace_id = :workspace_id
  AND is_enabled = TRUE
ORDER BY integration_type;

-- Get unhealthy integrations
SELECT
    workspace_id,
    integration_type,
    integration_name,
    health_status,
    last_error_message,
    last_error_at
FROM integrations_config
WHERE is_enabled = TRUE
  AND health_status IN ('degraded', 'unhealthy')
ORDER BY last_error_at DESC;

-- Get integration by type
SELECT *
FROM integrations_config
WHERE workspace_id = :workspace_id
  AND integration_type = 'slack'
  AND is_enabled = TRUE
LIMIT 1;

-- Get integrations with recent errors
SELECT
    integration_type,
    integration_name,
    total_events_sent,
    total_errors,
    ROUND((total_errors::NUMERIC / NULLIF(total_events_sent, 0) * 100), 2) AS error_rate_percent
FROM integrations_config
WHERE workspace_id = :workspace_id
  AND total_errors > 0
ORDER BY error_rate_percent DESC;
```

---

## RBAC Permission Matrix

| Action | Owner | Admin | Member | Viewer |
|--------|:-----:|:-----:|:------:|:------:|
| View workspace data | ✓ | ✓ | ✓ | ✓ |
| Create/edit agents | ✓ | ✓ | ✓ | ✗ |
| Manage team members | ✓ | ✓ | ✗ | ✗ |
| View billing | ✓ | ✗ | ✗ | ✗ |
| Manage billing | ✓ | ✗ | ✗ | ✗ |
| Delete workspace | ✓ | ✗ | ✗ | ✗ |
| Manage integrations | ✓ | ✓ | ✗ | ✗ |
| View API keys | ✓ | ✓ | ✓ | ✗ |
| Create API keys | ✓ | ✓ | ✓ | ✗ |

---

## Subscription Plan Limits

| Feature | Free | Starter | Professional | Enterprise |
|---------|------|---------|--------------|------------|
| Traces/month | 10,000 | 100,000 | 1,000,000 | Unlimited |
| Team members | 3 | 10 | 25 | Unlimited |
| API keys | 2 | 5 | 10 | Unlimited |
| Data retention | 7 days | 30 days | 90 days | Custom |
| Integrations | 1 | 3 | 5 | Unlimited |

Example configuration in code:

```python
PLAN_LIMITS = {
    'free': {
        'traces_per_month_limit': 10_000,
        'team_members_limit': 3,
        'api_keys_limit': 2,
        'data_retention_days': 7,
        'custom_integrations_limit': 1,
        'monthly_price_usd': 0.00,
    },
    'starter': {
        'traces_per_month_limit': 100_000,
        'team_members_limit': 10,
        'api_keys_limit': 5,
        'data_retention_days': 30,
        'custom_integrations_limit': 3,
        'monthly_price_usd': 29.00,
    },
    'professional': {
        'traces_per_month_limit': 1_000_000,
        'team_members_limit': 25,
        'api_keys_limit': 10,
        'data_retention_days': 90,
        'custom_integrations_limit': 5,
        'monthly_price_usd': 99.00,
    },
    'enterprise': {
        'traces_per_month_limit': None,  # Unlimited
        'team_members_limit': None,
        'api_keys_limit': None,
        'data_retention_days': 365,
        'custom_integrations_limit': None,
        'monthly_price_usd': None,  # Custom pricing
    },
}
```

---

## Security Best Practices

### 1. Credential Encryption

**IMPORTANT:** Always encrypt sensitive credentials before storing in `integrations_config.credentials_encrypted`

```python
from cryptography.fernet import Fernet
import os

# Initialize encryption
encryption_key = os.getenv('INTEGRATION_CREDENTIALS_KEY')
fernet = Fernet(encryption_key.encode())

# Encrypt credentials
plaintext = "xoxb-slack-token-12345"
encrypted = fernet.encrypt(plaintext.encode())

# Store in database
db.execute("""
    INSERT INTO integrations_config (credentials_encrypted, encryption_key_id, ...)
    VALUES (:encrypted, 'key_v1_production', ...)
""", encrypted=encrypted.decode())

# Decrypt when needed
decrypted = fernet.decrypt(encrypted).decode()
```

### 2. Invitation Token Generation

```python
import secrets
import hashlib
from datetime import datetime, timedelta

def generate_invitation_token():
    # Generate secure random token
    token = secrets.token_urlsafe(32)

    # Hash for storage
    token_hash = hashlib.sha256(token.encode()).hexdigest()

    # Set expiration (7 days)
    expiration = datetime.utcnow() + timedelta(days=7)

    return token, token_hash, expiration

# Usage
token, token_hash, expiration = generate_invitation_token()

# Store hash, send plain token in email
db.execute("""
    INSERT INTO team_members (invitation_token, invitation_expires_at, ...)
    VALUES (:token_hash, :expiration, ...)
""", token_hash=token_hash, expiration=expiration)

# Email: https://app.example.com/invite/accept?token={token}
```

### 3. Row-Level Security (Optional)

```sql
-- Enable RLS
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE integrations_config ENABLE ROW LEVEL SECURITY;

-- Create policy for workspace isolation
CREATE POLICY team_members_isolation ON team_members
    USING (workspace_id = current_setting('app.current_workspace_id')::UUID);

CREATE POLICY billing_config_isolation ON billing_config
    USING (workspace_id = current_setting('app.current_workspace_id')::UUID);

CREATE POLICY integrations_config_isolation ON integrations_config
    USING (workspace_id = current_setting('app.current_workspace_id')::UUID);

-- Set workspace in application code
SET app.current_workspace_id = '00000000-0000-0000-0000-000000000001';
```

---

## Troubleshooting

### Migration fails with "relation already exists"

```sql
-- Check if tables already exist
SELECT tablename FROM pg_tables WHERE tablename IN ('team_members', 'billing_config', 'integrations_config');

-- If tables exist but migration wasn't recorded, manually mark as applied
INSERT INTO alembic_version (version_num) VALUES ('phase5_001_settings');
```

### Foreign key constraint violations

```sql
-- Verify required tables exist
SELECT tablename FROM pg_tables WHERE tablename IN ('workspaces', 'users');

-- Verify uuid-ossp extension is enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### Trigger function not found

```sql
-- Check if update_updated_at_column() exists
SELECT proname FROM pg_proc WHERE proname = 'update_updated_at_column';

-- If missing, create it
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## Next Steps

1. **Run Migration**
   ```bash
   cd backend && alembic upgrade head
   ```

2. **Load Seed Data**
   ```bash
   psql -h localhost -p 5433 -U postgres -d observability -f backend/db/phase5_seed_data.sql
   ```

3. **Verify Tables**
   ```sql
   SELECT * FROM team_members LIMIT 5;
   SELECT * FROM billing_config LIMIT 5;
   SELECT * FROM integrations_config LIMIT 5;
   ```

4. **Implement Backend Endpoints**
   - Create FastAPI routes for team management
   - Implement billing configuration endpoints
   - Build integration management APIs

5. **Build Frontend UI**
   - Settings page with tabs (Team, Billing, Integrations)
   - Team member invitation flow
   - Usage dashboard
   - Integration connection forms

---

## Support

For issues or questions:
- Review full documentation: `DATABASE_SCHEMA_PHASE5.md`
- Check migration files for detailed comments
- Verify PostgreSQL logs for errors
- Test queries in development environment first

**Database Connection:**
```bash
psql -h localhost -p 5433 -U postgres -d observability
```

**Environment Variables:**
```bash
DATABASE_URL=postgresql://postgres:postgres@localhost:5433/observability
INTEGRATION_CREDENTIALS_KEY=<your-32-byte-fernet-key>
```
