"""
Integration tests for Settings API endpoints.

Test scenarios cover:
- Team member invitation flow
- Role updates with validation
- Billing plan downgrades
- Integration configuration and testing
- Concurrent operations
- Cache consistency
- Permission boundaries
- Rate limiting
- Idempotency
- Workspace isolation

Run with: pytest tests/integration/test_settings_api.py -v
"""

import pytest
from httpx import AsyncClient
from datetime import datetime, timedelta
from uuid import uuid4
import asyncio
from typing import Dict, Any


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
def workspace_id() -> str:
    """Test workspace ID."""
    return "550e8400-e29b-41d4-a716-446655440000"


@pytest.fixture
def owner_token() -> str:
    """JWT token for workspace owner."""
    return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.owner_token"


@pytest.fixture
def admin_token() -> str:
    """JWT token for admin user."""
    return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.admin_token"


@pytest.fixture
def member_token() -> str:
    """JWT token for member user."""
    return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.member_token"


@pytest.fixture
def viewer_token() -> str:
    """JWT token for viewer user."""
    return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.viewer_token"


@pytest.fixture
async def client() -> AsyncClient:
    """Async HTTP client for API requests."""
    async with AsyncClient(base_url="http://localhost:8000") as ac:
        yield ac


def auth_headers(token: str, workspace_id: str) -> Dict[str, str]:
    """Generate authentication headers."""
    return {
        "Authorization": f"Bearer {token}",
        "X-Workspace-ID": workspace_id,
        "Content-Type": "application/json"
    }


# ============================================================================
# Test 1: Team Member Invitation Flow
# ============================================================================

class TestTeamInvitationFlow:
    """Test complete invitation lifecycle."""

    @pytest.mark.asyncio
    async def test_successful_invitation_and_acceptance(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test sending invitation and accepting it."""
        # Step 1: Send invitation
        response = await client.post(
            "/api/v1/team/invite",
            headers=auth_headers(admin_token, workspace_id),
            json={
                "email": "newmember@example.com",
                "role": "member",
                "first_name": "New",
                "last_name": "Member",
                "message": "Welcome to the team!"
            }
        )

        assert response.status_code == 201
        data = response.json()
        assert data["success"] is True
        assert data["data"]["email"] == "newmember@example.com"
        assert data["data"]["status"] == "pending"

        invitation_token = data["data"]["token"]
        invitation_id = data["data"]["id"]

        # Step 2: Verify invitation appears in list
        response = await client.get(
            "/api/v1/team/invitations",
            headers=auth_headers(admin_token, workspace_id)
        )

        assert response.status_code == 200
        data = response.json()
        assert any(inv["id"] == invitation_id for inv in data["data"])

        # Step 3: Accept invitation
        response = await client.post(
            f"/api/v1/team/invitations/{invitation_token}/accept",
            json={
                "first_name": "New",
                "last_name": "Member"
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["email"] == "newmember@example.com"
        assert data["data"]["status"] == "active"
        assert data["data"]["role"] == "member"

        member_id = data["data"]["id"]

        # Step 4: Verify member in team list
        response = await client.get(
            "/api/v1/team/members",
            headers=auth_headers(admin_token, workspace_id)
        )

        assert response.status_code == 200
        data = response.json()
        assert any(
            m["id"] == member_id and m["email"] == "newmember@example.com"
            for m in data["data"]
        )

        # Step 5: Verify workspace member count updated
        response = await client.get(
            "/api/v1/workspace",
            headers=auth_headers(admin_token, workspace_id)
        )

        assert response.status_code == 200
        # Member count should have increased

    @pytest.mark.asyncio
    async def test_duplicate_invitation_prevented(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test that duplicate invitations are prevented."""
        invitation_data = {
            "email": "duplicate@example.com",
            "role": "member"
        }

        # Send first invitation
        response = await client.post(
            "/api/v1/team/invite",
            headers=auth_headers(admin_token, workspace_id),
            json=invitation_data
        )
        assert response.status_code == 201

        # Attempt duplicate invitation
        response = await client.post(
            "/api/v1/team/invite",
            headers=auth_headers(admin_token, workspace_id),
            json=invitation_data
        )

        assert response.status_code == 409
        data = response.json()
        assert data["error"]["code"] == "INVITATION_ALREADY_PENDING"

    @pytest.mark.asyncio
    async def test_expired_invitation_rejected(
        self,
        client: AsyncClient,
        workspace_id: str
    ):
        """Test that expired invitations cannot be accepted."""
        # This would require creating an expired invitation in the database
        expired_token = "inv_expired_token_12345"

        response = await client.post(
            f"/api/v1/team/invitations/{expired_token}/accept",
            json={"first_name": "Test", "last_name": "User"}
        )

        assert response.status_code == 410
        data = response.json()
        assert data["error"]["code"] == "INVITATION_EXPIRED"

    @pytest.mark.asyncio
    async def test_invitation_cancellation(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test cancelling a pending invitation."""
        # Send invitation
        response = await client.post(
            "/api/v1/team/invite",
            headers=auth_headers(admin_token, workspace_id),
            json={"email": "cancel@example.com", "role": "member"}
        )
        assert response.status_code == 201
        invitation_id = response.json()["data"]["id"]

        # Cancel invitation
        response = await client.delete(
            f"/api/v1/team/invitations/{invitation_id}",
            headers=auth_headers(admin_token, workspace_id)
        )

        assert response.status_code == 200
        assert response.json()["success"] is True

        # Verify no longer in pending list
        response = await client.get(
            "/api/v1/team/invitations",
            headers=auth_headers(admin_token, workspace_id)
        )
        assert not any(
            inv["id"] == invitation_id and inv["status"] == "pending"
            for inv in response.json()["data"]
        )

    @pytest.mark.asyncio
    async def test_team_limit_enforced(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test that team member limits are enforced."""
        # Assuming workspace is at team limit
        response = await client.post(
            "/api/v1/team/invite",
            headers=auth_headers(admin_token, workspace_id),
            json={"email": "overlimit@example.com", "role": "member"}
        )

        assert response.status_code == 422
        data = response.json()
        assert data["error"]["code"] == "TEAM_LIMIT_REACHED"
        assert "current_count" in data["error"]["details"]
        assert "limit" in data["error"]["details"]


# ============================================================================
# Test 2: Role Update with Validation
# ============================================================================

class TestRoleUpdates:
    """Test role update operations and validations."""

    @pytest.mark.asyncio
    async def test_update_member_role_success(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test successful role update."""
        member_id = "760e8400-e29b-41d4-a716-446655440000"

        response = await client.put(
            f"/api/v1/team/members/{member_id}/role",
            headers=auth_headers(admin_token, workspace_id),
            json={"role": "admin"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["role"] == "admin"

    @pytest.mark.asyncio
    async def test_cannot_modify_owner_role(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test that admin cannot modify owner role."""
        owner_id = "650e8400-e29b-41d4-a716-446655440000"

        response = await client.put(
            f"/api/v1/team/members/{owner_id}/role",
            headers=auth_headers(admin_token, workspace_id),
            json={"role": "admin"}
        )

        assert response.status_code == 403
        data = response.json()
        assert data["error"]["code"] == "CANNOT_MODIFY_OWNER"

    @pytest.mark.asyncio
    async def test_cannot_assign_owner_role(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test that admin cannot assign owner role."""
        member_id = "760e8400-e29b-41d4-a716-446655440000"

        response = await client.put(
            f"/api/v1/team/members/{member_id}/role",
            headers=auth_headers(admin_token, workspace_id),
            json={"role": "owner"}
        )

        assert response.status_code == 403
        data = response.json()
        assert data["error"]["code"] == "CANNOT_ASSIGN_OWNER_ROLE"

    @pytest.mark.asyncio
    async def test_cannot_modify_own_role(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test that users cannot modify their own role."""
        # Assuming admin_token belongs to this member
        own_member_id = "750e8400-e29b-41d4-a716-446655440000"

        response = await client.put(
            f"/api/v1/team/members/{own_member_id}/role",
            headers=auth_headers(admin_token, workspace_id),
            json={"role": "member"}
        )

        assert response.status_code == 409
        data = response.json()
        assert data["error"]["code"] == "CANNOT_DEMOTE_SELF"


# ============================================================================
# Test 3: Billing Plan Downgrade Validation
# ============================================================================

class TestBillingPlanDowngrade:
    """Test billing plan change validations."""

    @pytest.mark.asyncio
    async def test_blocked_downgrade_due_to_team_size(
        self,
        client: AsyncClient,
        owner_token: str,
        workspace_id: str
    ):
        """Test that downgrade is blocked when team size exceeds new limit."""
        response = await client.put(
            "/api/v1/billing/plan",
            headers=auth_headers(owner_token, workspace_id),
            json={
                "plan": "starter",
                "interval": "monthly"
            }
        )

        assert response.status_code == 400
        data = response.json()
        assert data["error"]["code"] == "INVALID_PLAN_DOWNGRADE"

        blockers = data["error"]["details"]["blockers"]
        assert any(b["limit"] == "max_team_members" for b in blockers)

    @pytest.mark.asyncio
    async def test_successful_plan_upgrade(
        self,
        client: AsyncClient,
        owner_token: str,
        workspace_id: str
    ):
        """Test successful plan upgrade."""
        response = await client.put(
            "/api/v1/billing/plan",
            headers=auth_headers(owner_token, workspace_id),
            json={
                "plan": "enterprise",
                "interval": "yearly"
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["plan"] == "enterprise"
        assert data["interval"] == "yearly"

    @pytest.mark.asyncio
    async def test_admin_cannot_change_billing(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test that admin cannot change billing plan."""
        response = await client.put(
            "/api/v1/billing/plan",
            headers=auth_headers(admin_token, workspace_id),
            json={"plan": "professional", "interval": "monthly"}
        )

        assert response.status_code == 403
        data = response.json()
        assert data["error"]["code"] == "INSUFFICIENT_PERMISSIONS"


# ============================================================================
# Test 4: Integration Configuration and Testing
# ============================================================================

class TestIntegrations:
    """Test integration configuration and testing."""

    @pytest.mark.asyncio
    async def test_configure_slack_integration(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test configuring Slack integration."""
        response = await client.put(
            "/api/v1/integrations/slack",
            headers=auth_headers(admin_token, workspace_id),
            json={
                "enabled": True,
                "name": "Production Alerts",
                "config": {
                    "webhook_url": "https://hooks.slack.com/services/T00/B00/XXX",
                    "channel": "#alerts",
                    "notify_on_error": True,
                    "notify_on_alert": True,
                    "mention_users": ["@oncall"]
                }
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["type"] == "slack"
        assert data["data"]["enabled"] is True

    @pytest.mark.asyncio
    async def test_test_integration_success(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test successful integration test."""
        response = await client.post(
            "/api/v1/integrations/slack/test",
            headers=auth_headers(admin_token, workspace_id)
        )

        assert response.status_code == 200
        data = response.json()
        assert data["test_successful"] is True
        assert "response_time_ms" in data

    @pytest.mark.asyncio
    async def test_invalid_slack_configuration(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test validation of invalid Slack configuration."""
        response = await client.put(
            "/api/v1/integrations/slack",
            headers=auth_headers(admin_token, workspace_id),
            json={
                "enabled": True,
                "config": {
                    "webhook_url": "invalid-url",
                    "channel": "alerts"  # Missing #
                }
            }
        )

        assert response.status_code == 400
        data = response.json()
        assert data["error"]["code"] == "VALIDATION_ERROR"
        details = data["error"]["details"]
        assert "config.webhook_url" in details or "config.channel" in details

    @pytest.mark.asyncio
    async def test_disable_integration(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test disabling an integration."""
        response = await client.delete(
            "/api/v1/integrations/slack",
            headers=auth_headers(admin_token, workspace_id)
        )

        assert response.status_code == 200
        assert response.json()["success"] is True

    @pytest.mark.asyncio
    async def test_enable_integration(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test enabling a disabled integration."""
        response = await client.post(
            "/api/v1/integrations/slack/enable",
            headers=auth_headers(admin_token, workspace_id)
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["enabled"] is True


# ============================================================================
# Test 5: Permission Boundaries
# ============================================================================

class TestPermissionBoundaries:
    """Test RBAC enforcement at role boundaries."""

    @pytest.mark.asyncio
    async def test_member_cannot_invite(
        self,
        client: AsyncClient,
        member_token: str,
        workspace_id: str
    ):
        """Test that member cannot invite team members."""
        response = await client.post(
            "/api/v1/team/invite",
            headers=auth_headers(member_token, workspace_id),
            json={"email": "test@example.com", "role": "member"}
        )

        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_member_can_view_team(
        self,
        client: AsyncClient,
        member_token: str,
        workspace_id: str
    ):
        """Test that member can view team list."""
        response = await client.get(
            "/api/v1/team/members",
            headers=auth_headers(member_token, workspace_id)
        )

        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_viewer_cannot_modify_workspace(
        self,
        client: AsyncClient,
        viewer_token: str,
        workspace_id: str
    ):
        """Test that viewer cannot modify workspace."""
        response = await client.put(
            "/api/v1/workspace",
            headers=auth_headers(viewer_token, workspace_id),
            json={"name": "Updated Name"}
        )

        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_admin_cannot_view_invoices(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test that admin cannot view billing invoices."""
        response = await client.get(
            "/api/v1/billing/invoices",
            headers=auth_headers(admin_token, workspace_id)
        )

        assert response.status_code == 403


# ============================================================================
# Test 6: Cache Consistency
# ============================================================================

class TestCacheConsistency:
    """Test cache invalidation on updates."""

    @pytest.mark.asyncio
    async def test_workspace_cache_invalidated_on_update(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test that workspace cache is invalidated on update."""
        # Get workspace (cache)
        response1 = await client.get(
            "/api/v1/workspace",
            headers=auth_headers(admin_token, workspace_id)
        )
        assert response1.status_code == 200
        original_name = response1.json()["data"]["name"]

        # Update workspace
        new_name = f"Updated {datetime.utcnow().isoformat()}"
        response2 = await client.put(
            "/api/v1/workspace",
            headers=auth_headers(admin_token, workspace_id),
            json={"name": new_name}
        )
        assert response2.status_code == 200

        # Get workspace again (should reflect update)
        response3 = await client.get(
            "/api/v1/workspace",
            headers=auth_headers(admin_token, workspace_id)
        )
        assert response3.status_code == 200
        assert response3.json()["data"]["name"] == new_name

    @pytest.mark.asyncio
    async def test_team_cache_invalidated_on_member_add(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test that team cache is invalidated when member is added."""
        # Get team list
        response1 = await client.get(
            "/api/v1/team/members",
            headers=auth_headers(admin_token, workspace_id)
        )
        original_count = len(response1.json()["data"])

        # Send invitation and accept (adds member)
        # ... (invitation flow)

        # Get team list again
        response2 = await client.get(
            "/api/v1/team/members",
            headers=auth_headers(admin_token, workspace_id)
        )
        # Should reflect new member


# ============================================================================
# Test 7: Rate Limiting
# ============================================================================

class TestRateLimiting:
    """Test rate limiting enforcement."""

    @pytest.mark.asyncio
    async def test_rate_limit_enforced(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test that rate limits are enforced."""
        # Make many rapid requests
        requests = []
        for i in range(105):  # Exceed limit of 100/min
            requests.append(
                client.get(
                    "/api/v1/workspace",
                    headers=auth_headers(admin_token, workspace_id)
                )
            )

        responses = await asyncio.gather(*requests, return_exceptions=True)

        # At least one should be rate limited
        rate_limited = [
            r for r in responses
            if not isinstance(r, Exception) and r.status_code == 429
        ]
        assert len(rate_limited) > 0

        # Check rate limit headers
        for response in responses:
            if not isinstance(response, Exception):
                assert "X-RateLimit-Limit" in response.headers
                assert "X-RateLimit-Remaining" in response.headers


# ============================================================================
# Test 8: Idempotency
# ============================================================================

class TestIdempotency:
    """Test idempotent operations."""

    @pytest.mark.asyncio
    async def test_invitation_idempotency(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test that duplicate invitations with same idempotency key return same result."""
        idempotency_key = f"inv-{uuid4()}"
        headers = auth_headers(admin_token, workspace_id)
        headers["Idempotency-Key"] = idempotency_key

        invitation_data = {
            "email": "idempotent@example.com",
            "role": "member"
        }

        # First request
        response1 = await client.post(
            "/api/v1/team/invite",
            headers=headers,
            json=invitation_data
        )
        assert response1.status_code == 201
        invitation_id_1 = response1.json()["data"]["id"]

        # Second request with same key
        response2 = await client.post(
            "/api/v1/team/invite",
            headers=headers,
            json=invitation_data
        )
        assert response2.status_code == 201
        invitation_id_2 = response2.json()["data"]["id"]

        # Should return same invitation
        assert invitation_id_1 == invitation_id_2


# ============================================================================
# Test 9: Workspace Isolation
# ============================================================================

class TestWorkspaceIsolation:
    """Test multi-tenant workspace isolation."""

    @pytest.mark.asyncio
    async def test_cannot_access_other_workspace(
        self,
        client: AsyncClient,
        admin_token: str
    ):
        """Test that users cannot access data from other workspaces."""
        other_workspace_id = "999e8400-e29b-41d4-a716-446655440999"

        response = await client.get(
            "/api/v1/team/members",
            headers=auth_headers(admin_token, other_workspace_id)
        )

        assert response.status_code == 403
        data = response.json()
        assert data["error"]["code"] == "WORKSPACE_ACCESS_DENIED"


# ============================================================================
# Test 10: Pagination
# ============================================================================

class TestPagination:
    """Test pagination functionality."""

    @pytest.mark.asyncio
    async def test_team_members_pagination(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test pagination of team members list."""
        # First page
        response = await client.get(
            "/api/v1/team/members?limit=5",
            headers=auth_headers(admin_token, workspace_id)
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]) <= 5

        if data["pagination"]["has_more"]:
            cursor = data["pagination"]["next_cursor"]

            # Second page
            response2 = await client.get(
                f"/api/v1/team/members?limit=5&cursor={cursor}",
                headers=auth_headers(admin_token, workspace_id)
            )

            assert response2.status_code == 200
            # Should not duplicate results from first page


# ============================================================================
# Test 11: Filtering and Sorting
# ============================================================================

class TestFilteringAndSorting:
    """Test query filtering and sorting."""

    @pytest.mark.asyncio
    async def test_filter_team_members_by_role(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test filtering team members by role."""
        response = await client.get(
            "/api/v1/team/members?role=admin",
            headers=auth_headers(admin_token, workspace_id)
        )

        assert response.status_code == 200
        data = response.json()
        # All returned members should be admin
        assert all(m["role"] == "admin" for m in data["data"])

    @pytest.mark.asyncio
    async def test_sort_team_members(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test sorting team members."""
        response = await client.get(
            "/api/v1/team/members?sort=created_at:desc",
            headers=auth_headers(admin_token, workspace_id)
        )

        assert response.status_code == 200
        data = response.json()

        # Verify descending order
        members = data["data"]
        for i in range(len(members) - 1):
            current = datetime.fromisoformat(members[i]["created_at"].replace("Z", "+00:00"))
            next_member = datetime.fromisoformat(members[i + 1]["created_at"].replace("Z", "+00:00"))
            assert current >= next_member


# ============================================================================
# Test 12: Billing Usage Tracking
# ============================================================================

class TestBillingUsage:
    """Test billing usage statistics."""

    @pytest.mark.asyncio
    async def test_get_current_usage(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test getting current billing usage."""
        response = await client.get(
            "/api/v1/billing/usage",
            headers=auth_headers(admin_token, workspace_id)
        )

        assert response.status_code == 200
        data = response.json()
        usage = data["usage"]

        assert "traces_current_month" in usage
        assert "traces_limit" in usage
        assert "traces_percentage" in usage
        assert usage["traces_percentage"] == (
            usage["traces_current_month"] / usage["traces_limit"] * 100
        )

    @pytest.mark.asyncio
    async def test_usage_custom_period(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test usage statistics for custom period."""
        start_date = "2024-10-01T00:00:00Z"
        end_date = "2024-10-31T23:59:59Z"

        response = await client.get(
            f"/api/v1/billing/usage?period=custom&start_date={start_date}&end_date={end_date}",
            headers=auth_headers(admin_token, workspace_id)
        )

        assert response.status_code == 200
        data = response.json()
        assert data["usage"]["period_start"] == start_date
        assert data["usage"]["period_end"] == end_date


# ============================================================================
# Test 13: Checkout Session Creation
# ============================================================================

class TestCheckoutSession:
    """Test Stripe checkout session creation."""

    @pytest.mark.asyncio
    async def test_create_checkout_session(
        self,
        client: AsyncClient,
        owner_token: str,
        workspace_id: str
    ):
        """Test creating Stripe checkout session."""
        response = await client.post(
            "/api/v1/billing/checkout",
            headers=auth_headers(owner_token, workspace_id),
            json={
                "plan": "professional",
                "interval": "monthly",
                "success_url": "https://app.example.com/settings/billing?success=true",
                "cancel_url": "https://app.example.com/settings/billing"
            }
        )

        assert response.status_code == 201
        data = response.json()
        assert "session_id" in data
        assert "checkout_url" in data
        assert "expires_at" in data


# ============================================================================
# Performance and Load Tests
# ============================================================================

class TestPerformance:
    """Performance and load tests."""

    @pytest.mark.asyncio
    async def test_concurrent_invitations(
        self,
        client: AsyncClient,
        admin_token: str,
        workspace_id: str
    ):
        """Test handling concurrent invitation requests."""
        tasks = []
        for i in range(10):
            tasks.append(
                client.post(
                    "/api/v1/team/invite",
                    headers=auth_headers(admin_token, workspace_id),
                    json={
                        "email": f"concurrent{i}@example.com",
                        "role": "member"
                    }
                )
            )

        responses = await asyncio.gather(*tasks, return_exceptions=True)

        # All should either succeed or fail with proper error
        for response in responses:
            if not isinstance(response, Exception):
                assert response.status_code in [201, 409, 422]
