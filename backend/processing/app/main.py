"""Processing Service - Consumes traces from Redis and writes to TimescaleDB"""
import asyncio
import logging
import signal
import sys
from .consumer import TraceConsumer
from .processor import TraceProcessor
from .writer import TraceWriter

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class ProcessingService:
    """Main processing service that orchestrates consume-process-write pipeline"""

    def __init__(self):
        self.consumer = TraceConsumer()
        self.processor = TraceProcessor()
        self.writer = TraceWriter()
        self.running = False
        self.total_processed = 0
        self.total_failed = 0

    async def start(self):
        """Start the processing service"""
        logger.info("Starting Processing Service...")

        # Connect to database
        await self.writer.connect()

        # Set up signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)

        self.running = True
        logger.info("Processing Service started successfully")

        # Main processing loop
        while self.running:
            await self.process_batch()

    async def process_batch(self):
        """Process a single batch of traces"""
        try:
            # Consume traces from Redis Stream
            traces = self.consumer.consume_batch(batch_size=100, block_ms=1000)

            if not traces:
                # No messages available, wait a bit
                await asyncio.sleep(0.1)
                return

            logger.info(f"Consumed {len(traces)} traces from stream")

            # Extract message IDs for acknowledgment
            message_ids = [trace.pop('_message_id') for trace in traces]

            # Process traces
            processed_traces, failed_traces = self.processor.process_batch(traces)

            if failed_traces:
                logger.warning(f"Failed to process {len(failed_traces)} traces")
                self.total_failed += len(failed_traces)

            if processed_traces:
                # Write to TimescaleDB
                successful, failed = await self.writer.write_batch(processed_traces)
                self.total_processed += successful
                self.total_failed += failed

                logger.info(
                    f"Batch complete: {successful} written, {failed} failed. "
                    f"Total: {self.total_processed} processed, {self.total_failed} failed"
                )

            # Acknowledge messages
            self.consumer.acknowledge_batch(message_ids)

        except Exception as e:
            logger.error(f"Error in process_batch: {str(e)}")
            await asyncio.sleep(1)  # Wait before retrying

    async def stop(self):
        """Stop the processing service gracefully"""
        logger.info("Stopping Processing Service...")
        self.running = False

        # Close connections
        await self.writer.disconnect()
        self.consumer.close()

        logger.info(f"Processing Service stopped. Total processed: {self.total_processed}, Total failed: {self.total_failed}")

    def _signal_handler(self, sig, frame):
        """Handle shutdown signals"""
        logger.info(f"Received signal {sig}, shutting down gracefully...")
        self.running = False


async def main():
    """Main entry point"""
    service = ProcessingService()

    try:
        await service.start()
    except KeyboardInterrupt:
        logger.info("Interrupted by user")
    finally:
        await service.stop()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Service stopped by user")
        sys.exit(0)
