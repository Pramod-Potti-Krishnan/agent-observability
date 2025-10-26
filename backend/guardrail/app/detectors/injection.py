"""Prompt Injection Detection Module"""
import re
from typing import List, Dict

INJECTION_PATTERNS = [
    r'ignore\s+(previous|above|all)\s+instructions',
    r'disregard\s+(previous|above|all)',
    r'forget\s+everything',
    r'new\s+instructions?:',
    r'system\s*:\s*',
    r'<\s*script\s*>',
    r'eval\s*\(',
    r'override\s+instructions',
    r'act\s+as\s+if',
]


def detect_prompt_injection(text: str) -> List[Dict]:
    """Detect potential prompt injection attempts"""
    violations = []

    for pattern in INJECTION_PATTERNS:
        if re.search(pattern, text, re.IGNORECASE):
            violations.append({
                'type': 'prompt_injection',
                'pattern': pattern,
                'severity': 'critical'
            })

    return violations
