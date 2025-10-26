"""Toxicity Detection Module"""
from typing import Dict

# Simplified toxicity detection using keyword matching
# In production, use transformers or Perspective API

TOXIC_KEYWORDS = [
    'hate', 'stupid', 'idiot', 'moron', 'dumb', 'ugly',
    'kill', 'die', 'death', 'violence'
]


def detect_toxicity(text: str) -> Dict:
    """Detect toxic content using keyword matching"""
    text_lower = text.lower()

    toxic_count = sum(1 for keyword in TOXIC_KEYWORDS if keyword in text_lower)

    # Calculate confidence based on toxic keyword density
    words = len(text.split())
    confidence = min(1.0, toxic_count / max(1, words / 10))

    is_toxic = confidence > 0.3

    if confidence > 0.7:
        severity = 'high'
    elif confidence > 0.4:
        severity = 'medium'
    else:
        severity = 'low'

    return {
        'is_toxic': is_toxic,
        'confidence': confidence,
        'severity': severity
    }
