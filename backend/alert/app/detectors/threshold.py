"""Threshold-based alert detection"""
import logging
from typing import Optional
from ..models import ThresholdDetectionResult, ConditionType

logger = logging.getLogger(__name__)


def check_threshold_breach(
    metric: str,
    current_value: float,
    threshold: float,
    condition: str
) -> ThresholdDetectionResult:
    """
    Check if a metric value breaches the defined threshold.

    Args:
        metric: Name of the metric being checked
        current_value: Current value of the metric
        threshold: Threshold value to compare against
        condition: Condition type (gt, lt, gte, lte, eq)

    Returns:
        ThresholdDetectionResult with breach status and details
    """
    breached = False
    message = ""

    try:
        condition_enum = ConditionType(condition)

        if condition_enum == ConditionType.GT:
            breached = current_value > threshold
            message = f"{metric} value {current_value} is greater than threshold {threshold}"
        elif condition_enum == ConditionType.LT:
            breached = current_value < threshold
            message = f"{metric} value {current_value} is less than threshold {threshold}"
        elif condition_enum == ConditionType.GTE:
            breached = current_value >= threshold
            message = f"{metric} value {current_value} is greater than or equal to threshold {threshold}"
        elif condition_enum == ConditionType.LTE:
            breached = current_value <= threshold
            message = f"{metric} value {current_value} is less than or equal to threshold {threshold}"
        elif condition_enum == ConditionType.EQ:
            breached = abs(current_value - threshold) < 0.01  # Float comparison tolerance
            message = f"{metric} value {current_value} equals threshold {threshold}"

        if not breached:
            message = f"{metric} value {current_value} within acceptable range (threshold: {threshold}, condition: {condition})"

        logger.info(f"Threshold check - Metric: {metric}, Value: {current_value}, Threshold: {threshold}, Condition: {condition}, Breached: {breached}")

    except ValueError as e:
        logger.error(f"Invalid condition type: {condition}")
        message = f"Invalid condition type: {condition}"
        breached = False

    return ThresholdDetectionResult(
        breached=breached,
        metric=metric,
        current_value=current_value,
        threshold=threshold,
        condition=condition,
        message=message
    )


def calculate_severity(
    metric: str,
    current_value: float,
    threshold: float,
    condition: str
) -> str:
    """
    Calculate severity level based on how much the threshold is breached.

    Args:
        metric: Name of the metric
        current_value: Current value
        threshold: Threshold value
        condition: Condition type

    Returns:
        Severity level: 'info', 'warning', 'error', or 'critical'
    """
    if threshold == 0:
        deviation_pct = 100.0
    else:
        deviation_pct = abs((current_value - threshold) / threshold) * 100

    # Determine severity based on deviation percentage
    if deviation_pct < 10:
        return "info"
    elif deviation_pct < 25:
        return "warning"
    elif deviation_pct < 50:
        return "error"
    else:
        return "critical"
