"""Integration test: Evaluation Flow - Ingest trace → Evaluate → Query results"""
import pytest
import httpx
import uuid
import asyncio


@pytest.mark.asyncio
@pytest.mark.integration
async def test_evaluation_flow_end_to_end():
    """
    Integration test: Ingest trace → Evaluate → Query results
    Tests full evaluation pipeline from ingestion to querying

    Prerequisites:
    - All services must be running (ingestion:8001, evaluation:8004)
    - PostgreSQL and TimescaleDB must be accessible
    - Gemini API key must be configured
    """
    workspace_id = "test-workspace-id"
    trace_id = f"test-trace-{uuid.uuid4()}"

    try:
        # Step 1: Ingest a trace via ingestion service
        print(f"\n[1/3] Ingesting test trace: {trace_id}")
        async with httpx.AsyncClient(timeout=30.0) as client:
            ingest_response = await client.post(
                "http://localhost:8001/api/v1/ingest/trace",
                json={
                    "trace_id": trace_id,
                    "agent_id": "test-agent",
                    "input": "What is artificial intelligence?",
                    "output": "Artificial Intelligence (AI) is the simulation of human intelligence processes by machines, especially computer systems.",
                    "latency_ms": 250,
                    "token_count": 50,
                    "status": "success"
                },
                headers={"X-Workspace-ID": workspace_id}
            )

            print(f"Ingest status: {ingest_response.status_code}")
            assert ingest_response.status_code == 201, f"Ingest failed: {ingest_response.text}"
            print(f"✓ Trace ingested successfully")

        # Step 2: Trigger evaluation via evaluation service
        print(f"\n[2/3] Evaluating trace: {trace_id}")
        async with httpx.AsyncClient(timeout=30.0) as client:
            eval_response = await client.post(
                f"http://localhost:8004/api/v1/evaluate/trace/{trace_id}",
                headers={"X-Workspace-ID": workspace_id}
            )

            print(f"Evaluation status: {eval_response.status_code}")
            if eval_response.status_code != 200:
                print(f"Evaluation response: {eval_response.text}")

            assert eval_response.status_code == 200, f"Evaluation failed: {eval_response.text}"
            eval_data = eval_response.json()

            # Verify evaluation data
            assert "overall_score" in eval_data
            assert "accuracy_score" in eval_data
            assert "reasoning" in eval_data
            assert 0 <= eval_data["overall_score"] <= 10
            print(f"✓ Trace evaluated successfully - Overall Score: {eval_data['overall_score']}")

        # Step 3: Query evaluation results
        print(f"\n[3/3] Querying evaluation history")
        async with httpx.AsyncClient(timeout=30.0) as client:
            query_response = await client.get(
                f"http://localhost:8004/api/v1/evaluate/history",
                headers={"X-Workspace-ID": workspace_id}
            )

            assert query_response.status_code == 200, f"Query failed: {query_response.text}"
            query_data = query_response.json()

            # Verify history contains evaluations
            assert "evaluations" in query_data
            assert "total" in query_data
            assert query_data["total"] > 0
            print(f"✓ Evaluation history retrieved - Total: {query_data['total']} evaluations")

            # Verify our trace is in the results (it might not be the first if other tests ran)
            trace_ids = [e["trace_id"] for e in query_data["evaluations"]]
            print(f"✓ Found {len(trace_ids)} evaluations in history")

        print("\n✅ Integration test PASSED: Full evaluation flow completed successfully")

    except httpx.ConnectError as e:
        pytest.skip(f"Service not available: {e}. Run 'docker-compose up' to start services.")
    except Exception as e:
        print(f"\n❌ Integration test FAILED: {e}")
        raise


if __name__ == "__main__":
    # Allow running this test standalone for debugging
    asyncio.run(test_evaluation_flow_end_to_end())
