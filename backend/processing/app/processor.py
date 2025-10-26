"""Trace processing logic"""
import logging
from datetime import datetime, timezone
from typing import Optional

logger = logging.getLogger(__name__)


class TraceProcessor:
    """Processes raw traces and extracts metrics"""

    def process_trace(self, trace_data: dict) -> dict:
        """
        Process a single trace

        Args:
            trace_data: Raw trace dictionary

        Returns:
            dict: Processed trace ready for database insertion
        """
        try:
            # Extract and validate required fields
            processed = {
                'trace_id': trace_data['trace_id'],
                'workspace_id': trace_data['workspace_id'],
                'agent_id': trace_data['agent_id'],
                'timestamp': self._parse_timestamp(trace_data['timestamp']),
                'latency_ms': int(trace_data['latency_ms']),
                'input': trace_data.get('input', ''),
                'output': trace_data.get('output', ''),
                'error': trace_data.get('error'),
                'status': trace_data.get('status', 'success'),
                'model': trace_data['model'],
                'model_provider': trace_data['model_provider'],
                'tokens_input': trace_data.get('tokens_input'),
                'tokens_output': trace_data.get('tokens_output'),
                'tokens_total': trace_data.get('tokens_total'),
                'cost_usd': trace_data.get('cost_usd'),
                'metadata': trace_data.get('metadata', {}),
                'tags': trace_data.get('tags', [])
            }

            # Calculate total tokens if not provided
            if processed['tokens_total'] is None and processed['tokens_input'] and processed['tokens_output']:
                processed['tokens_total'] = processed['tokens_input'] + processed['tokens_output']

            # Validate status
            if processed['status'] not in ['success', 'error', 'timeout']:
                logger.warning(f"Invalid status '{processed['status']}' for trace {processed['trace_id']}, defaulting to 'success'")
                processed['status'] = 'success'

            return processed

        except KeyError as e:
            logger.error(f"Missing required field in trace: {str(e)}")
            raise ValueError(f"Missing required field: {str(e)}")
        except Exception as e:
            logger.error(f"Failed to process trace: {str(e)}")
            raise

    def process_batch(self, traces: list[dict]) -> tuple[list[dict], list[dict]]:
        """
        Process a batch of traces

        Args:
            traces: List of raw trace dictionaries

        Returns:
            tuple: (processed_traces, failed_traces)
        """
        processed = []
        failed = []

        for trace in traces:
            try:
                processed_trace = self.process_trace(trace)
                processed.append(processed_trace)
            except Exception as e:
                logger.error(f"Failed to process trace {trace.get('trace_id', 'unknown')}: {str(e)}")
                failed.append({
                    'trace_id': trace.get('trace_id', 'unknown'),
                    'error': str(e),
                    'raw_data': trace
                })

        return processed, failed

    def _parse_timestamp(self, timestamp) -> datetime:
        """Parse timestamp to datetime object"""
        if isinstance(timestamp, datetime):
            return timestamp
        elif isinstance(timestamp, str):
            # Try to parse ISO format
            try:
                return datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
            except ValueError:
                # Fallback to current time
                logger.warning(f"Invalid timestamp format: {timestamp}, using current time")
                return datetime.now(timezone.utc)
        else:
            logger.warning(f"Unexpected timestamp type: {type(timestamp)}, using current time")
            return datetime.now(timezone.utc)

    def extract_metrics(self, trace: dict) -> dict:
        """
        Extract key metrics from a trace

        Args:
            trace: Processed trace dictionary

        Returns:
            dict: Extracted metrics
        """
        return {
            'trace_id': trace['trace_id'],
            'latency_ms': trace['latency_ms'],
            'tokens_total': trace['tokens_total'],
            'cost_usd': trace['cost_usd'],
            'status': trace['status'],
            'model': trace['model'],
            'timestamp': trace['timestamp']
        }
