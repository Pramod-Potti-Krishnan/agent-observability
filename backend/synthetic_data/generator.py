"""Synthetic data generator for agent observability platform.

Generates realistic traces, metrics, and events for testing and visualization.
"""

import random
import uuid
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Any
from faker import Faker
import json

fake = Faker()


class SyntheticDataGenerator:
    """Generates synthetic observability data."""

    AGENTS = [
        {"id": "customer_support", "name": "Customer Support Agent", "model": "gpt-4"},
        {"id": "sales_agent", "name": "Sales Agent", "model": "gpt-3.5-turbo"},
        {"id": "content_writer", "name": "Content Writer Agent", "model": "claude-3-opus"},
        {"id": "code_reviewer", "name": "Code Review Agent", "model": "gpt-4"},
        {"id": "data_analyzer", "name": "Data Analysis Agent", "model": "claude-3-sonnet"},
    ]

    MODELS = [
        {"name": "gpt-4", "provider": "openai", "input_cost": 0.03, "output_cost": 0.06},
        {"name": "gpt-3.5-turbo", "provider": "openai", "input_cost": 0.0005, "output_cost": 0.0015},
        {"name": "claude-3-opus", "provider": "anthropic", "input_cost": 0.015, "output_cost": 0.075},
        {"name": "claude-3-sonnet", "provider": "anthropic", "input_cost": 0.003, "output_cost": 0.015},
        {"name": "gemini-pro", "provider": "google", "input_cost": 0.00025, "output_cost": 0.0005},
    ]

    CUSTOMER_SUPPORT_INPUTS = [
        "How do I reset my password?",
        "What are your business hours?",
        "I need help with my order #12345",
        "Can you help me track my shipment?",
        "I want to cancel my subscription",
        "How do I update my billing information?",
        "What's your refund policy?",
        "I'm having trouble logging in",
        "Can you explain the pricing plans?",
        "How do I contact support?",
    ]

    SALES_INPUTS = [
        "What features does the premium plan include?",
        "Can you give me a demo of the product?",
        "What's the pricing for enterprise customers?",
        "Do you offer volume discounts?",
        "What's the difference between plans?",
        "Can I upgrade my plan later?",
        "Do you have a trial period?",
        "What payment methods do you accept?",
        "Is there a setup fee?",
        "Can you customize the solution for our needs?",
    ]

    CONTENT_INPUTS = [
        "Write a blog post about AI trends in 2024",
        "Create a product description for a smartwatch",
        "Generate social media captions for a new product launch",
        "Write an email newsletter about our latest features",
        "Create SEO-optimized content for landing page",
        "Draft a press release for our funding announcement",
        "Write a case study about customer success",
        "Generate ideas for our content calendar",
        "Create ad copy for Facebook campaign",
        "Write a whitepaper on industry best practices",
    ]

    def __init__(self, workspace_id: str = "00000000-0000-0000-0000-000000000001"):
        """Initialize generator with workspace ID."""
        self.workspace_id = workspace_id

    def generate_trace(
        self,
        agent_id: str = None,
        timestamp: datetime = None,
        force_error: bool = False,
    ) -> Dict[str, Any]:
        """Generate a single trace."""
        if agent_id is None:
            agent = random.choice(self.AGENTS)
            agent_id = agent["id"]
            model_name = agent["model"]
        else:
            agent = next((a for a in self.AGENTS if a["id"] == agent_id), self.AGENTS[0])
            model_name = agent["model"]

        model = next((m for m in self.MODELS if m["name"] == model_name), self.MODELS[0])

        if timestamp is None:
            timestamp = datetime.now(timezone.utc)

        # Select appropriate input based on agent type
        if agent_id == "customer_support":
            user_input = random.choice(self.CUSTOMER_SUPPORT_INPUTS)
        elif agent_id == "sales_agent":
            user_input = random.choice(self.SALES_INPUTS)
        elif agent_id == "content_writer":
            user_input = random.choice(self.CONTENT_INPUTS)
        else:
            user_input = fake.text(max_nb_chars=200)

        # Generate realistic latency based on model (GPT-4 is slower)
        if model_name in ["gpt-4", "claude-3-opus"]:
            base_latency = random.randint(2000, 8000)
        elif model_name in ["claude-3-sonnet"]:
            base_latency = random.randint(1500, 5000)
        else:
            base_latency = random.randint(500, 3000)

        # Add some outliers (5% chance of very slow response)
        if random.random() < 0.05:
            base_latency = random.randint(10000, 30000)

        latency_ms = base_latency

        # Token counts (realistic ranges)
        tokens_input = random.randint(50, 500)
        tokens_output = random.randint(100, 2000) if not force_error else 0

        # Calculate cost based on token usage
        cost_usd = (
            (tokens_input / 1000) * model["input_cost"]
            + (tokens_output / 1000) * model["output_cost"]
        )

        # Status (95% success, 5% error)
        if force_error or random.random() < 0.05:
            status = "error"
            output = None
            error = random.choice([
                "Rate limit exceeded",
                "API timeout",
                "Invalid API key",
                "Model overloaded",
                "Connection error",
                "Context length exceeded",
            ])
        else:
            status = "success"
            error = None
            # Generate realistic output based on input
            output = fake.text(max_nb_chars=1000)

        # Some traces have timeouts (1% chance)
        if random.random() < 0.01:
            status = "timeout"
            error = "Request timeout after 30s"
            output = None
            latency_ms = 30000

        trace = {
            "trace_id": f"trace_{uuid.uuid4().hex[:16]}",
            "workspace_id": self.workspace_id,
            "agent_id": agent_id,
            "timestamp": timestamp.isoformat(),
            "latency_ms": latency_ms,
            "input": user_input,
            "output": output,
            "error": error,
            "status": status,
            "model": model_name,
            "model_provider": model["provider"],
            "tokens_input": tokens_input,
            "tokens_output": tokens_output,
            "tokens_total": tokens_input + tokens_output,
            "cost_usd": round(cost_usd, 6),
            "metadata": {
                "user_id": fake.uuid4(),
                "session_id": fake.uuid4(),
                "ip_address": fake.ipv4(),
                "user_agent": fake.user_agent(),
            },
            "tags": random.sample(["production", "beta", "test", "urgent", "low-priority"], k=random.randint(1, 3)),
        }

        return trace

    def generate_traces(
        self,
        count: int,
        days_back: int = 30,
        agent_id: str = None,
    ) -> List[Dict[str, Any]]:
        """Generate multiple traces over a time period."""
        traces = []
        start_time = datetime.now(timezone.utc) - timedelta(days=days_back)

        # Generate traces with realistic distribution (more recent = more traffic)
        for i in range(count):
            # Weighted towards recent data
            days_offset = random.betavariate(2, 5) * days_back
            hours_offset = random.uniform(0, 24)
            timestamp = start_time + timedelta(days=days_offset, hours=hours_offset)

            trace = self.generate_trace(agent_id=agent_id, timestamp=timestamp)
            traces.append(trace)

        # Sort by timestamp
        traces.sort(key=lambda x: x["timestamp"])
        return traces

    def generate_performance_metric(
        self,
        agent_id: str,
        metric_name: str,
        timestamp: datetime = None,
    ) -> Dict[str, Any]:
        """Generate a performance metric."""
        if timestamp is None:
            timestamp = datetime.now(timezone.utc)

        # Generate realistic metric values
        if metric_name == "latency":
            value = random.randint(500, 5000)
            unit = "ms"
        elif metric_name == "throughput":
            value = random.uniform(10, 100)
            unit = "requests/s"
        elif metric_name == "error_rate":
            value = random.uniform(0, 10)
            unit = "%"
        elif metric_name == "cache_hit_rate":
            value = random.uniform(60, 95)
            unit = "%"
        else:
            value = random.uniform(0, 100)
            unit = "units"

        return {
            "timestamp": timestamp.isoformat(),
            "workspace_id": self.workspace_id,
            "agent_id": agent_id,
            "metric_name": metric_name,
            "value": round(value, 2),
            "unit": unit,
            "metadata": {},
        }

    def generate_event(
        self,
        event_type: str = None,
        severity: str = None,
        timestamp: datetime = None,
    ) -> Dict[str, Any]:
        """Generate an event (alert, anomaly, etc.)."""
        if timestamp is None:
            timestamp = datetime.now(timezone.utc)

        if event_type is None:
            event_type = random.choice(["alert", "anomaly", "threshold_breach", "guardrail_violation"])

        if severity is None:
            severity = random.choice(["info", "warning", "error", "critical"])

        agent_id = random.choice(self.AGENTS)["id"]

        # Generate realistic event titles and descriptions
        event_templates = {
            "alert": {
                "titles": [
                    "High error rate detected",
                    "Latency spike detected",
                    "Cost threshold exceeded",
                    "Unusual traffic pattern",
                ],
                "descriptions": [
                    "Error rate increased to {value}% in the last 5 minutes",
                    "Average latency reached {value}ms",
                    "Hourly cost exceeded ${value}",
                    "Request volume {value}x higher than baseline",
                ],
            },
            "anomaly": {
                "titles": [
                    "Anomalous behavior detected",
                    "Unusual response time",
                    "Unexpected output pattern",
                ],
                "descriptions": [
                    "Detected unusual pattern in agent responses",
                    "Response time deviates from normal by {value}%",
                    "Output length anomaly detected",
                ],
            },
            "threshold_breach": {
                "titles": [
                    "Budget threshold exceeded",
                    "Rate limit approaching",
                    "Latency SLA breached",
                ],
                "descriptions": [
                    "Monthly budget reached {value}% of limit",
                    "API rate at {value}% of limit",
                    "Latency exceeded SLA by {value}ms",
                ],
            },
            "guardrail_violation": {
                "titles": [
                    "PII detected in output",
                    "Toxic content flagged",
                    "Prompt injection attempt",
                ],
                "descriptions": [
                    "Detected personal information in agent response",
                    "Content toxicity score: {value}/10",
                    "Potential prompt injection detected",
                ],
            },
        }

        templates = event_templates.get(event_type, event_templates["alert"])
        title = random.choice(templates["titles"])
        description = random.choice(templates["descriptions"]).format(value=random.randint(5, 95))

        return {
            "event_id": f"event_{uuid.uuid4().hex[:16]}",
            "timestamp": timestamp.isoformat(),
            "workspace_id": self.workspace_id,
            "agent_id": agent_id,
            "event_type": event_type,
            "severity": severity,
            "title": title,
            "description": description,
            "metadata": {
                "source": "synthetic_generator",
                "trace_id": f"trace_{uuid.uuid4().hex[:16]}",
            },
            "acknowledged": random.choice([True, False]) if random.random() < 0.3 else False,
            "acknowledged_at": None,
            "acknowledged_by": None,
        }

    def generate_guardrail_violation(
        self,
        violation_type: str = None,
        timestamp: datetime = None,
    ) -> Dict[str, Any]:
        """Generate a guardrail violation."""
        if timestamp is None:
            timestamp = datetime.now(timezone.utc)

        if violation_type is None:
            violation_type = random.choice(["pii_detection", "toxicity", "prompt_injection", "content_policy"])

        severities = {
            "pii_detection": "critical",
            "toxicity": "error",
            "prompt_injection": "critical",
            "content_policy": "warning",
        }

        messages = {
            "pii_detection": "Detected email address and phone number in output",
            "toxicity": "Detected toxic language with confidence score 0.89",
            "prompt_injection": "Detected potential prompt injection attempt",
            "content_policy": "Output may violate content policy guidelines",
        }

        return {
            "violation_type": violation_type,
            "severity": severities.get(violation_type, "warning"),
            "message": messages.get(violation_type, "Guardrail violation detected"),
            "timestamp": timestamp.isoformat(),
            "trace_id": f"trace_{uuid.uuid4().hex[:16]}",
            "detected_content": "Sample detected content (redacted)",
            "redacted_content": "[REDACTED]",
        }


def main():
    """CLI entry point for generating synthetic data."""
    generator = SyntheticDataGenerator()

    print("Generating synthetic data...")

    # Generate 10,000 traces over 30 days
    print("\nGenerating traces...")
    traces = generator.generate_traces(count=10000, days_back=30)
    print(f"Generated {len(traces)} traces")

    # Save to JSON file
    with open("synthetic_traces.json", "w") as f:
        json.dump(traces, f, indent=2)
    print(f"Saved traces to synthetic_traces.json")

    # Generate events
    print("\nGenerating events...")
    events = []
    for i in range(100):
        days_offset = random.uniform(0, 30)
        timestamp = datetime.now(timezone.utc) - timedelta(days=days_offset)
        event = generator.generate_event(timestamp=timestamp)
        events.append(event)

    with open("synthetic_events.json", "w") as f:
        json.dump(events, f, indent=2)
    print(f"Generated {len(events)} events")

    # Generate sample violations
    print("\nGenerating guardrail violations...")
    violations = []
    for i in range(50):
        days_offset = random.uniform(0, 30)
        timestamp = datetime.now(timezone.utc) - timedelta(days=days_offset)
        violation = generator.generate_guardrail_violation(timestamp=timestamp)
        violations.append(violation)

    with open("synthetic_violations.json", "w") as f:
        json.dump(violations, f, indent=2)
    print(f"Generated {len(violations)} violations")

    print("\n✅ Synthetic data generation complete!")
    print(f"   - {len(traces)} traces")
    print(f"   - {len(events)} events")
    print(f"   - {len(violations)} guardrail violations")


if __name__ == "__main__":
    main()
