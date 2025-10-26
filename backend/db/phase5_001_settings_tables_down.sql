-- =====================================================================
-- ROLLBACK: Phase 5 Settings Tables (DOWNGRADE)
-- FILE: phase5_001_settings_tables_down.sql
-- DESCRIPTION: Remove team_members, billing_config, integrations_config
-- WARNING: This will delete all data in these tables
-- AUTHOR: Database Designer Agent
-- DATE: 2025-10-25
-- =====================================================================

BEGIN;

\echo '========================================='
\echo 'Phase 5: Removing Settings Tables'
\echo '========================================='
\echo 'WARNING: This will delete all data!'
\echo ''

-- Drop tables in reverse order (respecting foreign key dependencies)

\echo 'Dropping table: integrations_config...'
DROP TABLE IF EXISTS integrations_config CASCADE;
\echo '✓ integrations_config table dropped'

\echo 'Dropping table: billing_config...'
DROP TABLE IF EXISTS billing_config CASCADE;
\echo '✓ billing_config table dropped'

\echo 'Dropping table: team_members...'
DROP TABLE IF EXISTS team_members CASCADE;
\echo '✓ team_members table dropped'

-- Verification
\echo ''
\echo '========================================='
\echo 'Verification'
\echo '========================================='

SELECT
    CASE
        WHEN NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'team_members')
         AND NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'billing_config')
         AND NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'integrations_config')
        THEN '✓ All Phase 5 tables removed successfully'
        ELSE '✗ Warning: Some tables may still exist'
    END AS rollback_status;

\echo ''

COMMIT;
