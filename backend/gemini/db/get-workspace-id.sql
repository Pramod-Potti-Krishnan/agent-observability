/*
 * Phase 4 Synthetic Data Generation
 * File: get-workspace-id.sql
 *
 * EXECUTION ORDER:
 * 1. Run this script FIRST before any other seed scripts
 * 2. Capture the workspace_id from the output
 * 3. Use this workspace_id in subsequent seed scripts
 *
 * Usage:
 * psql -h localhost -p 5433 -U postgres -d agent_observability_metadata -f get-workspace-id.sql
 *
 * OR via docker:
 * docker exec -i agent_obs_postgres psql -U postgres -d agent_observability_metadata -f /docker-entrypoint-initdb.d/get-workspace-id.sql
 */

-- Query the actual workspace ID from the database
SELECT
    id as workspace_id,
    slug,
    name,
    created_at
FROM workspaces
WHERE slug = 'dev-workspace'
LIMIT 1;
