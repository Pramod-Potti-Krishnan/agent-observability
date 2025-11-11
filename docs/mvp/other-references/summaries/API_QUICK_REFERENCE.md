# Settings API Quick Reference

Quick reference guide for Settings API endpoints in the Agent Observability Platform.

---

## Authentication

All requests require:
```http
Authorization: Bearer {jwt_token}
X-Workspace-ID: {workspace_id}
```

---

## Workspace APIs

### Get Workspace
```http
GET /api/v1/workspace
```
**Permission:** member (all roles)

### Update Workspace
```http
PUT /api/v1/workspace
Content-Type: application/json

{
  "name": "Updated Name",
  "timezone": "America/Los_Angeles",
  "settings": {"key": "value"}
}
```
**Permission:** admin

---

## Team Management APIs

### List Team Members
```http
GET /api/v1/team/members?limit=20&status=active&role=admin
```
**Permission:** member (all roles)

**Query Parameters:**
- `limit`: 1-100 (default: 20)
- `cursor`: pagination cursor
- `status`: active, inactive, suspended
- `role`: owner, admin, member, viewer
- `search`: search term
- `sort`: field:direction (e.g., created_at:desc)

### Invite Team Member
```http
POST /api/v1/team/invite
Content-Type: application/json
Idempotency-Key: inv-{unique-id}

{
  "email": "user@example.com",
  "role": "admin",
  "first_name": "John",
  "last_name": "Doe",
  "message": "Welcome!"
}
```
**Permission:** admin

### List Pending Invitations
```http
GET /api/v1/team/invitations?status=pending
```
**Permission:** admin

### Accept Invitation
```http
POST /api/v1/team/invitations/{token}/accept
Content-Type: application/json

{
  "first_name": "John",
  "last_name": "Doe"
}
```
**Permission:** public (token-based)

### Cancel Invitation
```http
DELETE /api/v1/team/invitations/{id}
```
**Permission:** admin

### Update Member Role
```http
PUT /api/v1/team/members/{id}/role
Content-Type: application/json

{
  "role": "admin"
}
```
**Permission:** admin (cannot modify owner)

### Remove Team Member
```http
DELETE /api/v1/team/members/{id}
```
**Permission:** admin (cannot remove owner)

### Reactivate Team Member
```http
POST /api/v1/team/members/{id}/reactivate
```
**Permission:** admin

---

## Billing APIs

### Get Billing Configuration
```http
GET /api/v1/billing/config
```
**Permission:** admin

**Response:**
```json
{
  "plan": "professional",
  "interval": "monthly",
  "limits": {
    "max_traces_per_month": 1000000,
    "max_team_members": 10,
    "max_api_keys": 5,
    "data_retention_days": 90,
    "rate_limit_per_minute": 100
  },
  "price_per_month": 99.00,
  "next_billing_date": "2024-11-25T00:00:00Z"
}
```

### Update Billing Plan
```http
PUT /api/v1/billing/plan
Content-Type: application/json

{
  "plan": "enterprise",
  "interval": "yearly"
}
```
**Permission:** owner

### Get Billing Usage
```http
GET /api/v1/billing/usage?period=current
```
**Permission:** admin

**Query Parameters:**
- `period`: current, previous, custom
- `start_date`: ISO 8601 (for custom period)
- `end_date`: ISO 8601 (for custom period)

### Create Checkout Session
```http
POST /api/v1/billing/checkout
Content-Type: application/json

{
  "plan": "professional",
  "interval": "monthly",
  "success_url": "https://app.example.com/settings/billing?success=true",
  "cancel_url": "https://app.example.com/settings/billing"
}
```
**Permission:** owner

### List Invoices
```http
GET /api/v1/billing/invoices?limit=20&status=paid
```
**Permission:** owner

---

## Integrations APIs

### List All Integrations
```http
GET /api/v1/integrations?enabled=true
```
**Permission:** admin

### Get Specific Integration
```http
GET /api/v1/integrations/{type}
```
**Permission:** admin

**Types:** slack, pagerduty, webhook, email, datadog

### Update Integration Configuration

#### Slack
```http
PUT /api/v1/integrations/slack
Content-Type: application/json

{
  "enabled": true,
  "name": "Production Alerts",
  "config": {
    "webhook_url": "https://hooks.slack.com/services/T00/B00/XXX",
    "channel": "#alerts",
    "notify_on_error": true,
    "notify_on_alert": true,
    "mention_users": ["@oncall"]
  }
}
```

#### PagerDuty
```http
PUT /api/v1/integrations/pagerduty
Content-Type: application/json

{
  "enabled": true,
  "config": {
    "integration_key": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
    "severity": "error",
    "auto_resolve": true
  }
}
```

#### Webhook
```http
PUT /api/v1/integrations/webhook
Content-Type: application/json

{
  "enabled": true,
  "config": {
    "url": "https://api.example.com/webhooks/alerts",
    "method": "POST",
    "headers": {
      "Authorization": "Bearer token123"
    },
    "events": ["error", "alert"],
    "secret": "webhook_secret"
  }
}
```

**Permission:** admin

### Test Integration
```http
POST /api/v1/integrations/{type}/test
```
**Permission:** admin

**Response:**
```json
{
  "success": true,
  "test_successful": true,
  "response_time_ms": 245,
  "details": "Test message delivered successfully"
}
```

### Disable Integration
```http
DELETE /api/v1/integrations/{type}
```
**Permission:** admin

### Enable Integration
```http
POST /api/v1/integrations/{type}/enable
```
**Permission:** admin

---

## Error Responses

All errors follow this format:
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable message",
    "details": {
      "field": ["Error details"]
    }
  },
  "timestamp": "2024-10-25T14:20:00Z"
}
```

### Common Error Codes

| Code | Status | Description |
|------|--------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid request data |
| `UNAUTHORIZED` | 401 | Missing/invalid token |
| `INSUFFICIENT_PERMISSIONS` | 403 | Lacks required role |
| `WORKSPACE_NOT_FOUND` | 404 | Workspace doesn't exist |
| `MEMBER_NOT_FOUND` | 404 | Team member doesn't exist |
| `INVITATION_NOT_FOUND` | 404 | Invitation doesn't exist |
| `MEMBER_ALREADY_EXISTS` | 409 | User already member |
| `INVITATION_ALREADY_PENDING` | 409 | Pending invitation exists |
| `CANNOT_MODIFY_OWNER` | 403 | Cannot modify owner |
| `CANNOT_REMOVE_SELF` | 403 | Cannot remove self |
| `INVITATION_EXPIRED` | 410 | Invitation expired |
| `TEAM_LIMIT_REACHED` | 422 | Team size limit reached |
| `INVALID_PLAN_DOWNGRADE` | 400 | Downgrade blocked by usage |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |

---

## RBAC Permission Matrix

| Endpoint | Owner | Admin | Member | Viewer |
|----------|-------|-------|--------|--------|
| GET /workspace | ✓ | ✓ | ✓ | ✓ |
| PUT /workspace | ✓ | ✓ | ✗ | ✗ |
| GET /team/members | ✓ | ✓ | ✓ | ✓ |
| POST /team/invite | ✓ | ✓ | ✗ | ✗ |
| PUT /team/members/:id/role | ✓ | ✓* | ✗ | ✗ |
| DELETE /team/members/:id | ✓ | ✓* | ✗ | ✗ |
| GET /billing/config | ✓ | ✓ | ✗ | ✗ |
| PUT /billing/plan | ✓ | ✗ | ✗ | ✗ |
| GET /billing/invoices | ✓ | ✗ | ✗ | ✗ |
| GET /integrations | ✓ | ✓ | ✓** | ✓** |
| PUT /integrations/:type | ✓ | ✓ | ✗ | ✗ |

*Admin cannot modify owner or assign owner role
**Member/Viewer see masked secrets

---

## Pagination

All list endpoints support cursor-based pagination:

**Request:**
```http
GET /api/v1/team/members?limit=20&cursor=eyJpZCI6MTIzfQ==
```

**Response:**
```json
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJpZCI6NDU2fQ==",
    "has_more": true,
    "total_count": 150
  }
}
```

**Usage Pattern:**
1. Request first page: `?limit=20`
2. Get `next_cursor` from response
3. Request next page: `?limit=20&cursor={next_cursor}`
4. Repeat until `has_more` is false

---

## Rate Limiting

**Default Limits:**
- 100 requests/minute per workspace
- 200 requests/minute burst

**Response Headers:**
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1735056060
```

**Rate Limit Error:**
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded"
  }
}
```

---

## Cache TTLs

| Resource | TTL | Invalidation |
|----------|-----|--------------|
| Workspace details | 5 min | On workspace update |
| Team members | 2 min | On member add/update/remove |
| Billing config | 10 min | On plan update |
| Billing usage | 5 min | Time-based only |
| Integrations | 5 min | On integration update |

---

## Idempotency

POST/PUT endpoints support idempotency keys:

```http
POST /api/v1/team/invite
Idempotency-Key: inv-unique-123
```

Same key returns same result (prevents duplicate operations).

---

## Example Workflows

### Invite and Onboard Team Member

1. **Send invitation:**
   ```bash
   POST /api/v1/team/invite
   {"email": "user@example.com", "role": "admin"}
   ```

2. **User accepts:**
   ```bash
   POST /api/v1/team/invitations/{token}/accept
   {"first_name": "John", "last_name": "Doe"}
   ```

3. **Verify member added:**
   ```bash
   GET /api/v1/team/members
   ```

### Upgrade Billing Plan

1. **Check current plan:**
   ```bash
   GET /api/v1/billing/config
   ```

2. **Create checkout session:**
   ```bash
   POST /api/v1/billing/checkout
   {"plan": "professional", "interval": "monthly", ...}
   ```

3. **User completes checkout**

4. **Verify plan updated:**
   ```bash
   GET /api/v1/billing/config
   ```

### Configure Slack Integration

1. **Update configuration:**
   ```bash
   PUT /api/v1/integrations/slack
   {"enabled": true, "config": {...}}
   ```

2. **Test connection:**
   ```bash
   POST /api/v1/integrations/slack/test
   ```

3. **Verify configuration:**
   ```bash
   GET /api/v1/integrations/slack
   ```

---

## cURL Examples

### Get Workspace
```bash
curl -X GET 'http://localhost:8000/api/v1/workspace' \
  -H 'Authorization: Bearer {token}' \
  -H 'X-Workspace-ID: {workspace_id}'
```

### Invite Team Member
```bash
curl -X POST 'http://localhost:8000/api/v1/team/invite' \
  -H 'Authorization: Bearer {token}' \
  -H 'X-Workspace-ID: {workspace_id}' \
  -H 'Content-Type: application/json' \
  -H 'Idempotency-Key: inv-123' \
  -d '{
    "email": "user@example.com",
    "role": "admin",
    "first_name": "John",
    "last_name": "Doe"
  }'
```

### Update Role
```bash
curl -X PUT 'http://localhost:8000/api/v1/team/members/{id}/role' \
  -H 'Authorization: Bearer {token}' \
  -H 'X-Workspace-ID: {workspace_id}' \
  -H 'Content-Type: application/json' \
  -d '{"role": "admin"}'
```

### Configure Slack
```bash
curl -X PUT 'http://localhost:8000/api/v1/integrations/slack' \
  -H 'Authorization: Bearer {token}' \
  -H 'X-Workspace-ID: {workspace_id}' \
  -H 'Content-Type: application/json' \
  -d '{
    "enabled": true,
    "name": "Production Alerts",
    "config": {
      "webhook_url": "https://hooks.slack.com/services/...",
      "channel": "#alerts",
      "notify_on_error": true
    }
  }'
```

---

## Testing

Run integration tests:
```bash
pytest tests/integration/test_settings_api.py -v
```

Run specific test:
```bash
pytest tests/integration/test_settings_api.py::TestTeamInvitationFlow::test_successful_invitation_and_acceptance -v
```

---

## Support

- **Full API Spec:** `/Users/pk1980/Documents/Software/Agent Monitoring/docs/API_SPEC_SETTINGS.md`
- **Pydantic Models:** `/Users/pk1980/Documents/Software/Agent Monitoring/apps/gateway/schemas/settings.py`
- **Integration Tests:** `/Users/pk1980/Documents/Software/Agent Monitoring/tests/integration/test_settings_api.py`
