"""Anomaly detection using statistical methods"""
import logging
import math
from typing import Optional, Dict
from ..models import AnomalyDetectionResult
from ..config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


def detect_anomaly_zscore(
    metric: str,
    current_value: float,
    mean: float,
    std_dev: float,
    threshold: Optional[float] = None
) -> AnomalyDetectionResult:
    """
    Detect anomalies using Z-score method.

    Z-score formula: z = (value - mean) / std_dev
    An observation is considered anomalous if |z| > threshold (default: 3.0)

    Args:
        metric: Name of the metric being analyzed
        current_value: Current value to check for anomaly
        mean: Mean value of the metric over the time window
        std_dev: Standard deviation of the metric
        threshold: Z-score threshold (default from config)

    Returns:
        AnomalyDetectionResult with anomaly status and details
    """
    if threshold is None:
        threshold = settings.anomaly_zscore_threshold

    is_anomaly = False
    z_score = 0.0
    message = ""

    try:
        # Calculate Z-score
        if std_dev > 0:
            z_score = (current_value - mean) / std_dev
            is_anomaly = abs(z_score) > threshold

            if is_anomaly:
                direction = "above" if z_score > 0 else "below"
                message = (
                    f"{metric} anomaly detected: value {current_value:.2f} is {abs(z_score):.2f} "
                    f"standard deviations {direction} the mean ({mean:.2f})"
                )
            else:
                message = (
                    f"{metric} value {current_value:.2f} is within normal range "
                    f"(Z-score: {z_score:.2f}, mean: {mean:.2f}, std: {std_dev:.2f})"
                )
        else:
            # Standard deviation is 0, all values are the same
            if abs(current_value - mean) < 0.01:
                is_anomaly = False
                message = f"{metric} value {current_value:.2f} matches constant baseline {mean:.2f}"
            else:
                is_anomaly = True
                z_score = float('inf') if current_value > mean else float('-inf')
                message = (
                    f"{metric} anomaly detected: value {current_value:.2f} deviates from "
                    f"constant baseline {mean:.2f}"
                )

        logger.info(
            f"Anomaly check - Metric: {metric}, Value: {current_value:.2f}, "
            f"Mean: {mean:.2f}, StdDev: {std_dev:.2f}, Z-score: {z_score:.2f}, "
            f"Anomaly: {is_anomaly}"
        )

    except Exception as e:
        logger.error(f"Error in anomaly detection: {e}")
        message = f"Error calculating Z-score: {str(e)}"
        is_anomaly = False

    return AnomalyDetectionResult(
        is_anomaly=is_anomaly,
        metric=metric,
        current_value=current_value,
        mean=mean,
        std_dev=std_dev,
        z_score=z_score,
        message=message
    )


def calculate_anomaly_severity(z_score: float) -> str:
    """
    Calculate severity level based on Z-score magnitude.

    Args:
        z_score: The Z-score value

    Returns:
        Severity level: 'info', 'warning', 'error', or 'critical'
    """
    abs_z = abs(z_score)

    if abs_z < 2.0:
        return "info"
    elif abs_z < 3.0:
        return "warning"
    elif abs_z < 4.0:
        return "error"
    else:
        return "critical"


def detect_anomaly_iqr(
    metric: str,
    current_value: float,
    statistics: Dict[str, float]
) -> AnomalyDetectionResult:
    """
    Detect anomalies using Interquartile Range (IQR) method.

    This is an alternative to Z-score that's more robust to outliers.
    Values outside of [Q1 - 1.5*IQR, Q3 + 1.5*IQR] are considered anomalies.

    Args:
        metric: Name of the metric
        current_value: Current value to check
        statistics: Dictionary with 'q1', 'q3' quartile values

    Returns:
        AnomalyDetectionResult
    """
    q1 = statistics.get('q1', 0)
    q3 = statistics.get('q3', 0)
    iqr = q3 - q1

    lower_bound = q1 - 1.5 * iqr
    upper_bound = q3 + 1.5 * iqr

    is_anomaly = current_value < lower_bound or current_value > upper_bound

    if is_anomaly:
        direction = "above" if current_value > upper_bound else "below"
        message = f"{metric} anomaly detected using IQR: value {current_value:.2f} is {direction} normal range [{lower_bound:.2f}, {upper_bound:.2f}]"
    else:
        message = f"{metric} value {current_value:.2f} is within IQR range [{lower_bound:.2f}, {upper_bound:.2f}]"

    # Calculate pseudo Z-score for severity
    mean = (q1 + q3) / 2
    z_score = 0.0
    if iqr > 0:
        z_score = (current_value - mean) / (iqr / 1.35)  # IQR ≈ 1.35 * std for normal distribution

    return AnomalyDetectionResult(
        is_anomaly=is_anomaly,
        metric=metric,
        current_value=current_value,
        mean=mean,
        std_dev=iqr / 1.35,
        z_score=z_score,
        message=message
    )
