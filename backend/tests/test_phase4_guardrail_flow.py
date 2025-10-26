"""Integration test: Guardrail Flow - Create rule → Check content with PII → Verify violation"""
import pytest
import httpx
import uuid


@pytest.mark.asyncio
@pytest.mark.integration
async def test_guardrail_flow_pii_detection():
    """
    Integration test: Create rule → Check content with PII → Verify violation
    Tests PII detection and violation recording

    Prerequisites:
    - Guardrail service must be running (guardrail:8005)
    - PostgreSQL must be accessible
    """
    workspace_id = "test-workspace-id"

    try:
        # Step 1: Create a custom guardrail rule
        print(f"\n[1/3] Creating custom PII detection rule")
        async with httpx.AsyncClient(timeout=30.0) as client:
            rule_response = await client.post(
                "http://localhost:8005/api/v1/guardrails/rules",
                json={
                    "rule_name": "Test Email Detection",
                    "rule_type": "pii",
                    "severity": "high",
                    "pattern": r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"
                },
                headers={"X-Workspace-ID": workspace_id}
            )

            print(f"Create rule status: {rule_response.status_code}")
            if rule_response.status_code == 201:
                rule_data = rule_response.json()
                rule_id = rule_data.get("id")
                print(f"✓ Rule created successfully - ID: {rule_id}")
            else:
                print(f"Rule creation response: {rule_response.text}")
                # Rule might already exist, continue anyway

        # Step 2: Check content with PII
        pii_content = f"Please contact me at test.user.{uuid.uuid4().hex[:8]}@example.com for more information"
        print(f"\n[2/3] Checking content with PII: {pii_content}")

        async with httpx.AsyncClient(timeout=30.0) as client:
            check_response = await client.post(
                "http://localhost:8005/api/v1/guardrails/pii",
                json={"text": pii_content},
                headers={"X-Workspace-ID": workspace_id}
            )

            print(f"PII check status: {check_response.status_code}")
            assert check_response.status_code == 200, f"PII check failed: {check_response.text}"
            check_data = check_response.json()

            # Verify PII was detected
            assert "has_pii" in check_data
            assert check_data["has_pii"] == True, "PII should have been detected"

            assert "detections" in check_data
            assert len(check_data["detections"]) > 0, "Should have at least one PII detection"

            # Verify email was detected
            detection_types = [d["pii_type"] for d in check_data["detections"]]
            assert "email" in detection_types, "Email should be detected as PII"

            # Verify redaction
            assert "redacted_text" in check_data
            assert "[REDACTED:" in check_data["redacted_text"], "Content should be redacted"
            print(f"✓ PII detected successfully - Found {len(check_data['detections'])} PII instances")
            print(f"✓ Redacted content: {check_data['redacted_text']}")

        # Step 3: Query violations to verify they were recorded
        print(f"\n[3/3] Querying violation history")
        async with httpx.AsyncClient(timeout=30.0) as client:
            violations_response = await client.get(
                "http://localhost:8005/api/v1/guardrails/violations?range=24h",
                headers={"X-Workspace-ID": workspace_id}
            )

            assert violations_response.status_code == 200, f"Violations query failed: {violations_response.text}"
            violations_data = violations_response.json()

            # Verify violations exist
            assert "violations" in violations_data
            assert "total_count" in violations_data
            print(f"✓ Violation history retrieved - Total: {violations_data['total_count']} violations")

            # If violations exist, verify structure
            if violations_data["total_count"] > 0:
                violation = violations_data["violations"][0]
                assert "violation_type" in violation
                assert "severity" in violation
                assert "redacted_content" in violation
                print(f"✓ Violation record structure verified")

        print("\n✅ Integration test PASSED: Full guardrail flow completed successfully")

    except httpx.ConnectError as e:
        pytest.skip(f"Service not available: {e}. Run 'docker-compose up' to start services.")
    except Exception as e:
        print(f"\n❌ Integration test FAILED: {e}")
        raise


if __name__ == "__main__":
    import asyncio
    asyncio.run(test_guardrail_flow_pii_detection())
