#!/usr/bin/env python3
"""
Refresh trace timestamps by sending new trace data to ingestion service
This script will call the ingestion API to create fresh traces
"""

import requests
import random
from datetime import datetime, timedelta

# Configuration
INGESTION_URL = "http://localhost:8001/api/v1/ingest/trace"
WORKSPACE_ID = "37160be9-7d69-43b5-8d5f-9d7b5e14a57a"
NUM_TRACES = 100  # Send 100 fresh traces

# Sample data
AGENT_NAMES = ["agent-claude", "agent-gpt4", "agent-gemini"]
MODELS = [
    {"name": "gpt-4-turbo", "provider": "openai"},
    {"name": "claude-3-5-sonnet", "provider": "anthropic"},
    {"name": "gemini-1.5-pro", "provider": "google"},
]
STATUSES = ["success"] * 80 + ["error"] * 15 + ["timeout"] * 5  # 80% success rate
ERRORS = [
    "Request timeout after {0}ms",
    "Rate limit exceeded",
    "Invalid API key",
    "Context length exceeded",
    "Model unavailable"
]

def generate_trace():
    """Generate a random trace payload"""
    now = datetime.utcnow()
    # Random time within last 12 hours
    offset_seconds = random.randint(0, 12 * 3600)
    timestamp = (now - timedelta(seconds=offset_seconds)).isoformat() + "Z"

    status = random.choice(STATUSES)
    model = random.choice(MODELS)
    latency_ms = random.randint(200, 5000)

    prompt_tokens = random.randint(100, 1000)
    completion_tokens = random.randint(50, 500)
    total_tokens = prompt_tokens + completion_tokens

    # Calculate cost (rough estimate)
    input_cost_per_1k = 0.03
    output_cost_per_1k = 0.06
    cost_usd = (prompt_tokens / 1000 * input_cost_per_1k) + (completion_tokens / 1000 * output_cost_per_1k)

    trace = {
        "trace_id": f"refresh-{random.randint(1, 1000000)}-{int(datetime.utcnow().timestamp() * 1000)}",
        "workspace_id": WORKSPACE_ID,
        "agent_name": random.choice(AGENT_NAMES),
        "timestamp": timestamp,
        "latency_ms": latency_ms,
        "prompt": f"Sample prompt for testing - generated at {timestamp}",
        "completion": None if status != "success" else f"Sample completion for trace at {timestamp}",
        "status": status,
        "model_name": model["name"],
        "model_provider": model["provider"],
        "prompt_tokens": prompt_tokens,
        "completion_tokens": completion_tokens,
        "total_tokens": total_tokens,
        "cost_usd": cost_usd,
        "metadata": {
            "environment": "production",
            "temperature": 0.7,
            "max_tokens": 2000,
            "generated_by": "refresh_script"
        },
        "tags": ["refresh", "synthetic"]
    }

    if status == "error":
        trace["error_message"] = random.choice(ERRORS).format(latency_ms)
    elif status == "timeout":
        trace["error_message"] = f"Request timeout after {latency_ms}ms"

    return trace

def send_trace(trace):
    """Send trace to ingestion API"""
    try:
        response = requests.post(INGESTION_URL, json=trace, timeout=5)
        return response.status_code == 200 or response.status_code == 201
    except Exception as e:
        print(f"Error sending trace: {e}")
        return False

def main():
    print(f"Sending {NUM_TRACES} fresh traces to ingestion service...")
    print(f"Target workspace: {WORKSPACE_ID}")
    print("")

    success_count = 0
    for i in range(NUM_TRACES):
        trace = generate_trace()
        if send_trace(trace):
            success_count += 1
            if (i + 1) % 20 == 0:
                print(f"Sent {i + 1}/{NUM_TRACES} traces...")
        else:
            print(f"Failed to send trace {i + 1}")

    print(f"\n✅ Successfully sent {success_count}/{NUM_TRACES} traces!")
    print("Data should now be available in the dashboards within a few seconds.")

if __name__ == "__main__":
    main()
