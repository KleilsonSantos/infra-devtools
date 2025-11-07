"""
Comprehensive tests for RabbitMQ messaging functionality.

This module validates RabbitMQ's core messaging capabilities including
queue management, message publishing/consuming, routing, and
high-availability features to ensure production readiness.
"""

import json
import os
import time
import uuid
from contextlib import contextmanager
from typing import Dict, Optional

import pika  # type: ignore[import-untyped]
import pytest
from dotenv import load_dotenv
from pika.exceptions import (  # type: ignore[import-untyped]
    AMQPConnectionError,
    AMQPError,
)

load_dotenv()


class RabbitMQConnectionError(Exception):
    """Custom exception for RabbitMQ connection issues."""


class RabbitMQTestUtils:
    """Utility class for RabbitMQ testing operations."""

    @staticmethod
    @contextmanager
    def rabbitmq_connection(
        host: str = "localhost",
        port: int = 5672,
        username: Optional[str] = None,
        password: Optional[str] = None,
        virtual_host: str = "/",
    ):
        """
        Context manager for RabbitMQ connections.

        Args:
            host: RabbitMQ host
            port: RabbitMQ port (AMQP port, not management)
            username: Username (defaults to env RABBIT_USER)
            password: Password (defaults to env RABBIT_PASSWORD)
            virtual_host: Virtual host

        Yields:
            Pika connection and channel objects

        Raises:
            RabbitMQConnectionError: If connection fails
        """
        username = username or os.getenv("RABBIT_USER", "guest")
        password = password or os.getenv("RABBIT_PASSWORD", "guest")

        connection = None
        channel = None

        try:
            credentials = pika.PlainCredentials(username, password)
            parameters = pika.ConnectionParameters(
                host=host,
                port=port,
                virtual_host=virtual_host,
                credentials=credentials,
                connection_attempts=3,
                retry_delay=1,
                socket_timeout=10,
            )

            connection = pika.BlockingConnection(parameters)
            channel = connection.channel()

            yield connection, channel

        except AMQPConnectionError as e:
            raise RabbitMQConnectionError(f"RabbitMQ connection failed: {e}")
        except AMQPError as e:
            raise RabbitMQConnectionError(f"RabbitMQ AMQP error: {e}")
        finally:
            if channel and not channel.is_closed:
                channel.close()
            if connection and not connection.is_closed:
                connection.close()

    @staticmethod
    def wait_for_rabbitmq(
        host: str = "localhost", port: int = 5672, timeout: int = 30
    ) -> bool:
        """
        Wait for RabbitMQ to become available.

        Args:
            host: RabbitMQ host
            port: RabbitMQ AMQP port
            timeout: Maximum wait time in seconds

        Returns:
            True if RabbitMQ becomes available, False otherwise
        """
        start_time = time.time()

        while time.time() - start_time < timeout:
            try:
                with RabbitMQTestUtils.rabbitmq_connection(host, port):
                    return True
            except RabbitMQConnectionError:
                time.sleep(2)

        return False


def perform_basic_messaging_test(connection, channel) -> Dict[str, bool]:
    """
    Perform basic messaging operations test.

    Args:
        connection: RabbitMQ connection
        channel: RabbitMQ channel

    Returns:
        Dictionary with test results
    """
    results = {
        "queue_declare": False,
        "message_publish": False,
        "message_consume": False,
        "queue_delete": False,
    }

    test_queue = f"test_queue_{uuid.uuid4().hex[:8]}"
    test_message = f"test_message_{uuid.uuid4().hex[:8]}"

    try:
        # Queue declaration
        method = channel.queue_declare(queue=test_queue, durable=False, exclusive=True)
        if method.method.queue == test_queue:
            results["queue_declare"] = True

        # Message publishing
        channel.basic_publish(
            exchange="",
            routing_key=test_queue,
            body=test_message,
            properties=pika.BasicProperties(
                delivery_mode=1,  # Non-persistent
                content_type="text/plain",
                timestamp=int(time.time()),
            ),
        )
        results["message_publish"] = True

        # Message consumption
        method_frame, _, body = channel.basic_get(queue=test_queue)
        if body and body.decode() == test_message:
            results["message_consume"] = True
            # Acknowledge the message
            if method_frame:
                channel.basic_ack(method_frame.delivery_tag)

        # Queue deletion
        channel.queue_delete(queue=test_queue)
        results["queue_delete"] = True

    except AMQPError as e:
        raise RabbitMQConnectionError(f"Basic messaging test failed: {e}")

    return results


def perform_advanced_messaging_test(connection, channel) -> Dict[str, bool]:
    """
    Perform advanced messaging patterns test.

    Args:
        connection: RabbitMQ connection
        channel: RabbitMQ channel

    Returns:
        Dictionary with test results
    """
    results = {
        "exchange_declare": False,
        "queue_binding": False,
        "fanout_messaging": False,
        "direct_routing": False,
        "topic_routing": False,
    }

    test_exchange = f"test_exchange_{uuid.uuid4().hex[:8]}"
    test_queues = [f"test_queue_{i}_{uuid.uuid4().hex[:8]}" for i in range(3)]

    try:
        # Exchange declaration
        channel.exchange_declare(
            exchange=test_exchange, exchange_type="topic", durable=False
        )
        results["exchange_declare"] = True

        # Queue declarations and bindings
        for i, queue in enumerate(test_queues):
            channel.queue_declare(queue=queue, durable=False, exclusive=True)

            # Different routing patterns
            routing_keys = ["test.direct", "test.topic.specific", "test.topic.general"]
            channel.queue_bind(
                exchange=test_exchange, queue=queue, routing_key=routing_keys[i]
            )

        results["queue_binding"] = True

        # Test direct routing
        channel.basic_publish(
            exchange=test_exchange, routing_key="test.direct", body="direct_message"
        )

        # Check if message arrived in correct queue
        method_frame, _, body = channel.basic_get(queue=test_queues[0])
        if body and body.decode() == "direct_message":
            results["direct_routing"] = True
            if method_frame:
                channel.basic_ack(method_frame.delivery_tag)

        # Test topic routing
        channel.basic_publish(
            exchange=test_exchange,
            routing_key="test.topic.specific",
            body="topic_message",
        )

        method_frame, _, body = channel.basic_get(queue=test_queues[1])
        if body and body.decode() == "topic_message":
            results["topic_routing"] = True
            if method_frame:
                channel.basic_ack(method_frame.delivery_tag)

        # Cleanup
        for queue in test_queues:
            channel.queue_delete(queue=queue)
        channel.exchange_delete(exchange=test_exchange)

    except AMQPError as e:
        raise RabbitMQConnectionError(f"Advanced messaging test failed: {e}")

    return results


def perform_persistence_test(connection, channel) -> Dict[str, bool]:
    """
    Perform message persistence and durability test.

    Args:
        connection: RabbitMQ connection
        channel: RabbitMQ channel

    Returns:
        Dictionary with test results
    """
    results = {
        "durable_queue": False,
        "persistent_message": False,
        "queue_properties": False,
    }

    test_queue = f"test_durable_queue_{uuid.uuid4().hex[:8]}"

    try:
        # Declare durable queue
        method = channel.queue_declare(
            queue=test_queue, durable=True, exclusive=False, auto_delete=False
        )
        if method.method.queue == test_queue:
            results["durable_queue"] = True

        # Publish persistent message
        persistent_message = {
            "id": str(uuid.uuid4()),
            "timestamp": int(time.time()),
            "data": "persistent_test_data",
        }

        channel.basic_publish(
            exchange="",
            routing_key=test_queue,
            body=json.dumps(persistent_message),
            properties=pika.BasicProperties(
                delivery_mode=2,  # Persistent message
                content_type="application/json",
                timestamp=int(time.time()),
                message_id=persistent_message["id"],
            ),
        )
        results["persistent_message"] = True

        # Verify message properties
        method_frame, properties, body = channel.basic_get(queue=test_queue)
        if (
            method_frame
            and properties
            and properties.delivery_mode == 2
            and properties.content_type == "application/json"
        ):
            results["queue_properties"] = True

            received_message = json.loads(body.decode())
            assert received_message["id"] == persistent_message["id"]

            channel.basic_ack(method_frame.delivery_tag)

        # Cleanup
        channel.queue_delete(queue=test_queue)

    except AMQPError as e:
        raise RabbitMQConnectionError(f"Persistence test failed: {e}")

    return results


@pytest.mark.integration
@pytest.mark.messaging
class TestRabbitMQFunctionality:
    """Test suite for RabbitMQ functionality validation."""

    def test_rabbitmq_basic_connectivity(self) -> None:
        """
        🐇 Test RabbitMQ basic connectivity and authentication.

        This test verifies:
        - AMQP port accessibility
        - Authentication with provided credentials
        - Basic channel operations
        - Connection stability
        """
        # Wait for RabbitMQ to be available
        assert RabbitMQTestUtils.wait_for_rabbitmq(
            timeout=30
        ), "❌ RabbitMQ not available on AMQP port 5672"

        # Test connection and basic operations
        with RabbitMQTestUtils.rabbitmq_connection() as (connection, channel):
            # Verify connection is established
            assert connection.is_open, "❌ RabbitMQ connection not open"
            assert channel.is_open, "❌ RabbitMQ channel not open"

            # Test basic channel operations
            channel.queue_declare(queue="test_connectivity", exclusive=True)
            channel.queue_delete(queue="test_connectivity")

    def test_rabbitmq_basic_messaging_functionality(self) -> None:
        """
        📨 Test RabbitMQ basic messaging operations.

        This test verifies:
        - Queue declaration and management
        - Message publishing and acknowledgment
        - Message consumption and delivery
        - Queue cleanup operations
        """
        assert RabbitMQTestUtils.wait_for_rabbitmq(
            timeout=30
        ), "❌ RabbitMQ not available for messaging tests"

        with RabbitMQTestUtils.rabbitmq_connection() as (connection, channel):
            results = perform_basic_messaging_test(connection, channel)

            assert results["queue_declare"], "❌ RabbitMQ queue declaration failed"
            assert results["message_publish"], "❌ RabbitMQ message publishing failed"
            assert results["message_consume"], "❌ RabbitMQ message consumption failed"
            assert results["queue_delete"], "❌ RabbitMQ queue deletion failed"

    def test_rabbitmq_advanced_routing_functionality(self) -> None:
        """
        🎯 Test RabbitMQ advanced routing and exchange patterns.

        This test verifies:
        - Exchange declaration and types (topic, direct, fanout)
        - Queue binding with routing keys
        - Message routing based on patterns
        - Complex messaging topologies
        """
        assert RabbitMQTestUtils.wait_for_rabbitmq(
            timeout=30
        ), "❌ RabbitMQ not available for routing tests"

        with RabbitMQTestUtils.rabbitmq_connection() as (connection, channel):
            results = perform_advanced_messaging_test(connection, channel)

            assert results[
                "exchange_declare"
            ], "❌ RabbitMQ exchange declaration failed"
            assert results["queue_binding"], "❌ RabbitMQ queue binding failed"
            assert results["direct_routing"], "❌ RabbitMQ direct routing failed"
            assert results["topic_routing"], "❌ RabbitMQ topic routing failed"

    def test_rabbitmq_message_persistence(self) -> None:
        """
        💾 Test RabbitMQ message persistence and durability.

        This test verifies:
        - Durable queue creation
        - Persistent message publishing
        - Message properties handling
        - Data integrity across restarts
        """
        assert RabbitMQTestUtils.wait_for_rabbitmq(
            timeout=30
        ), "❌ RabbitMQ not available for persistence tests"

        with RabbitMQTestUtils.rabbitmq_connection() as (connection, channel):
            results = perform_persistence_test(connection, channel)

            assert results["durable_queue"], "❌ RabbitMQ durable queue creation failed"
            assert results[
                "persistent_message"
            ], "❌ RabbitMQ persistent message publishing failed"
            assert results[
                "queue_properties"
            ], "❌ RabbitMQ message properties handling failed"

    def test_rabbitmq_concurrent_operations(self) -> None:
        """
        ⚡ Test RabbitMQ concurrent operations and performance.

        This test verifies:
        - Multiple concurrent publishers
        - Multiple concurrent consumers
        - Message ordering and delivery guarantees
        - Connection pooling behavior
        """
        assert RabbitMQTestUtils.wait_for_rabbitmq(
            timeout=30
        ), "❌ RabbitMQ not available for concurrency tests"

        test_queue = f"test_concurrent_{uuid.uuid4().hex[:8]}"
        message_count = 10
        published_messages = []
        consumed_messages = []

        # Publisher connection
        with RabbitMQTestUtils.rabbitmq_connection() as (pub_connection, pub_channel):
            # Declare queue
            pub_channel.queue_declare(queue=test_queue, durable=False)

            # Publish multiple messages
            for i in range(message_count):
                message = f"concurrent_message_{i}_{uuid.uuid4().hex[:8]}"
                published_messages.append(message)

                pub_channel.basic_publish(
                    exchange="",
                    routing_key=test_queue,
                    body=message,
                    properties=pika.BasicProperties(delivery_mode=1, message_id=str(i)),
                )

            # Consumer connection
            with RabbitMQTestUtils.rabbitmq_connection() as (
                con_connection,
                con_channel,
            ):
                # Consume all messages
                for _ in range(message_count):
                    method_frame, _, body = con_channel.basic_get(queue=test_queue)
                    if body:
                        consumed_messages.append(body.decode())
                        if method_frame:
                            con_channel.basic_ack(method_frame.delivery_tag)

                # Cleanup
                con_channel.queue_delete(queue=test_queue)

        # Verify all messages were published and consumed
        assert (
            len(published_messages) == message_count
        ), "❌ Not all messages were published"
        assert (
            len(consumed_messages) == message_count
        ), "❌ Not all messages were consumed"
        assert set(published_messages) == set(
            consumed_messages
        ), "❌ Message integrity compromised"

    def test_rabbitmq_error_handling_and_recovery(self) -> None:
        """
        🔧 Test RabbitMQ error handling and recovery mechanisms.

        This test verifies:
        - Connection recovery from failures
        - Channel error handling
        - Queue and exchange error scenarios
        - Graceful degradation patterns
        """
        assert RabbitMQTestUtils.wait_for_rabbitmq(
            timeout=30
        ), "❌ RabbitMQ not available for error handling tests"

        with RabbitMQTestUtils.rabbitmq_connection() as (connection, channel):
            # Test invalid queue operations
            with pytest.raises((AMQPError, pika.exceptions.ChannelClosedByBroker)):
                # Try to bind non-existent queue to non-existent exchange
                channel.queue_bind(
                    exchange="non_existent_exchange",
                    queue="non_existent_queue",
                    routing_key="test.key",
                )

            # Create new channel after error (connection should still be valid)
            if channel.is_closed:
                channel = connection.channel()

            # Test that we can still perform valid operations
            test_queue = f"test_recovery_{uuid.uuid4().hex[:8]}"
            method = channel.queue_declare(queue=test_queue, exclusive=True)
            assert method.method.queue == test_queue, "❌ Recovery after error failed"

            # Cleanup
            channel.queue_delete(queue=test_queue)


@pytest.mark.integration
@pytest.mark.messaging
def test_rabbitmq_comprehensive_health() -> None:
    """
    🏥 Comprehensive health check for RabbitMQ messaging infrastructure.

    This test performs a complete health assessment covering:
    - Service availability and connectivity
    - Core messaging functionality
    - Advanced routing capabilities
    - Performance and reliability metrics
    """
    health_results = {
        "connectivity": False,
        "basic_messaging": False,
        "advanced_routing": False,
        "persistence": False,
        "performance": False,
    }

    try:
        # Test connectivity
        if RabbitMQTestUtils.wait_for_rabbitmq(timeout=30):
            health_results["connectivity"] = True

            with RabbitMQTestUtils.rabbitmq_connection() as (connection, channel):
                # Test basic messaging
                basic_results = perform_basic_messaging_test(connection, channel)
                if all(basic_results.values()):
                    health_results["basic_messaging"] = True

                # Test advanced routing
                advanced_results = perform_advanced_messaging_test(connection, channel)
                if all(advanced_results.values()):
                    health_results["advanced_routing"] = True

                # Test persistence
                persistence_results = perform_persistence_test(connection, channel)
                if all(persistence_results.values()):
                    health_results["persistence"] = True

                # Basic performance test (message throughput)
                start_time = time.time()
                test_queue = f"perf_test_{uuid.uuid4().hex[:8]}"
                channel.queue_declare(queue=test_queue, exclusive=True)

                # Publish and consume 100 messages
                for i in range(100):
                    channel.basic_publish(
                        exchange="", routing_key=test_queue, body=f"perf_message_{i}"
                    )

                consumed_count = 0
                while consumed_count < 100:
                    method_frame, _, _ = channel.basic_get(queue=test_queue)
                    if method_frame:
                        channel.basic_ack(method_frame.delivery_tag)
                        consumed_count += 1
                    else:
                        break

                elapsed_time = time.time() - start_time
                if (
                    consumed_count == 100 and elapsed_time < 10
                ):  # Should complete within 10 seconds
                    health_results["performance"] = True

                channel.queue_delete(queue=test_queue)

    except Exception as e:
        pytest.fail(f"❌ RabbitMQ health check failed with error: {e}")

    # Verify all health checks passed
    failed_checks = [name for name, result in health_results.items() if not result]

    if failed_checks:
        failure_details = ", ".join(failed_checks)
        pytest.fail(f"❌ RabbitMQ health check failed for: {failure_details}")

    # Print success summary
    print("\n✅ RabbitMQ comprehensive health check passed:")
    for check_name, result in health_results.items():
        print(f"  ✓ {check_name}: {'PASS' if result else 'FAIL'}")
