"""PII Detection Module"""
import re
from typing import List, Dict

PII_PATTERNS = {
    'email': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    'phone': r'\b(?:\+?1[-.]?)?\(?\d{3}\)?[-.]?\d{3}[-.]?\d{4}\b',
    'ssn': r'\b\d{3}[-]?\d{2}[-]?\d{4}\b',
    'credit_card': r'\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b',
    'ip_address': r'\b(?:\d{1,3}\.){3}\d{1,3}\b'
}

PII_SEVERITY = {
    'email': 'medium',
    'phone': 'medium',
    'ssn': 'critical',
    'credit_card': 'critical',
    'ip_address': 'low'
}


def detect_pii(text: str) -> List[Dict]:
    """Detect PII in text using regex patterns"""
    violations = []

    for pii_type, pattern in PII_PATTERNS.items():
        matches = re.finditer(pattern, text)
        for match in matches:
            violations.append({
                'type': pii_type,
                'value': match.group(),
                'position': match.span(),
                'severity': PII_SEVERITY.get(pii_type, 'medium')
            })

    return violations


def redact_pii(text: str) -> str:
    """Redact PII from text"""
    redacted = text

    for pii_type, pattern in PII_PATTERNS.items():
        if pii_type == 'email':
            redacted = re.sub(pattern, '[EMAIL REDACTED]', redacted)
        elif pii_type == 'phone':
            redacted = re.sub(pattern, '[PHONE REDACTED]', redacted)
        elif pii_type == 'ssn':
            redacted = re.sub(pattern, '[SSN REDACTED]', redacted)
        elif pii_type == 'credit_card':
            redacted = re.sub(pattern, '[CARD REDACTED]', redacted)
        elif pii_type == 'ip_address':
            redacted = re.sub(pattern, '[IP REDACTED]', redacted)

    return redacted
