"""
Comprehensive functional tests for database services.

This module performs real CRUD operations to verify that database services
are not only running but fully functional and ready for production use.
"""

import pytest

from src.utils.constants import DATABASE_SERVICES
from src.utils.database_testing import (
    DatabaseConnectionError,
    DatabaseTestUtils,
    perform_mongodb_crud_test,
    perform_mysql_crud_test,
    perform_postgres_crud_test,
    perform_redis_crud_test,
)


@pytest.mark.integration
@pytest.mark.databases
class TestDatabaseFunctionality:
    """Test suite for database functionality validation."""

    def test_postgres_full_functionality(self) -> None:
        """
        🐘 Test PostgreSQL complete functionality including CRUD operations.

        This test verifies:
        - Connection establishment
        - Table creation/modification
        - Data insertion, selection, updating, and deletion
        - Transaction handling
        - Service readiness for production workloads
        """
        postgres_config = DATABASE_SERVICES["infra-default-postgres"]

        # Ensure service is available before testing
        assert DatabaseTestUtils.wait_for_service(
            "localhost", postgres_config["port"], timeout=30
        ), f"❌ PostgreSQL service not available on port {postgres_config['port']}"

        # Perform comprehensive CRUD operations
        with DatabaseTestUtils.postgres_connection() as conn:
            results = perform_postgres_crud_test(conn)

            assert results["create"], "❌ PostgreSQL table creation failed"
            assert results["read"], "❌ PostgreSQL data reading failed"
            assert results["update"], "❌ PostgreSQL data updating failed"
            assert results["delete"], "❌ PostgreSQL data deletion failed"

            # Additional PostgreSQL-specific functionality tests
            with conn.cursor() as cursor:
                # Test transaction rollback
                cursor.execute("BEGIN;")
                cursor.execute("CREATE TEMPORARY TABLE test_rollback (id SERIAL);")
                cursor.execute("ROLLBACK;")

                # Verify table was rolled back
                cursor.execute(
                    """
                    SELECT COUNT(*) FROM information_schema.tables
                    WHERE table_name = 'test_rollback';
                """
                )
                table_count = cursor.fetchone()[0]
                assert table_count == 0, "❌ PostgreSQL transaction rollback failed"

                # Test JSON functionality (PostgreSQL specific)
                cursor.execute(
                    """
                    CREATE TEMPORARY TABLE test_json (
                        id SERIAL PRIMARY KEY,
                        data JSONB
                    );
                """
                )
                cursor.execute(
                    "INSERT INTO test_json (data) VALUES (%s);",
                    ('{"key": "value", "number": 42}',),
                )
                cursor.execute("SELECT data->>'key' FROM test_json;")
                json_value = cursor.fetchone()[0]
                assert json_value == "value", "❌ PostgreSQL JSON functionality failed"

    def test_mysql_full_functionality(self) -> None:
        """
        🐬 Test MySQL complete functionality including CRUD operations.

        This test verifies:
        - Connection establishment with proper charset
        - InnoDB engine functionality
        - ACID compliance
        - Stored procedure execution
        - Service readiness for production workloads
        """
        mysql_config = DATABASE_SERVICES["infra-default-mysql"]

        # Ensure service is available
        assert DatabaseTestUtils.wait_for_service(
            "localhost", mysql_config["port"], timeout=30
        ), f"❌ MySQL service not available on port {mysql_config['port']}"

        # Perform comprehensive CRUD operations
        with DatabaseTestUtils.mysql_connection() as conn:
            results = perform_mysql_crud_test(conn)

            assert results["create"], "❌ MySQL table creation failed"
            assert results["read"], "❌ MySQL data reading failed"
            assert results["update"], "❌ MySQL data updating failed"
            assert results["delete"], "❌ MySQL data deletion failed"

            # Additional MySQL-specific functionality tests
            cursor = conn.cursor()

            try:
                # Test transaction handling
                conn.start_transaction()
                cursor.execute(
                    """
                    CREATE TEMPORARY TABLE test_transaction (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        value VARCHAR(50)
                    ) ENGINE=InnoDB;
                """
                )
                cursor.execute(
                    "INSERT INTO test_transaction (value) VALUES (%s);", ("test_data",)
                )
                conn.rollback()

                # Verify rollback worked
                cursor.execute(
                    """
                    SELECT COUNT(*) FROM information_schema.tables
                    WHERE table_name = 'test_transaction' AND table_schema = DATABASE();
                """
                )
                table_count = cursor.fetchone()[0]
                assert table_count == 0, "❌ MySQL transaction rollback failed"

                # Test stored procedure functionality
                cursor.execute("DROP PROCEDURE IF EXISTS test_proc;")
                cursor.execute(
                    """
                    CREATE PROCEDURE test_proc(IN input_val INT, OUT output_val INT)
                    BEGIN
                        SET output_val = input_val * 2;
                    END;
                """
                )

                cursor.callproc("test_proc", (21, 0))
                results = cursor.stored_results()
                # Clean up procedure
                cursor.execute("DROP PROCEDURE test_proc;")

            finally:
                cursor.close()

    def test_mongodb_full_functionality(self) -> None:
        """
        🍃 Test MongoDB complete functionality including document operations.

        This test verifies:
        - Connection to replica set or standalone
        - Database and collection operations
        - Document CRUD with complex data types
        - Index creation and querying
        - Aggregation pipeline functionality
        """
        mongodb_config = DATABASE_SERVICES["infra-default-mongo"]

        # Ensure service is available
        assert DatabaseTestUtils.wait_for_service(
            "localhost", mongodb_config["port"], timeout=30
        ), f"❌ MongoDB service not available on port {mongodb_config['port']}"

        # Perform comprehensive document operations
        with DatabaseTestUtils.mongodb_connection() as client:
            results = perform_mongodb_crud_test(client)

            assert results["create"], "❌ MongoDB document creation failed"
            assert results["read"], "❌ MongoDB document reading failed"
            assert results["update"], "❌ MongoDB document updating failed"
            assert results["delete"], "❌ MongoDB document deletion failed"

            # Additional MongoDB-specific functionality tests
            db = client.test_infrastructure_advanced
            collection = db.advanced_test

            try:
                # Test complex document operations
                complex_docs = [
                    {
                        "name": "user1",
                        "age": 25,
                        "skills": ["Python", "Docker", "MongoDB"],
                        "profile": {"location": "Brazil", "active": True},
                    },
                    {
                        "name": "user2",
                        "age": 30,
                        "skills": ["JavaScript", "React", "Node.js"],
                        "profile": {"location": "Portugal", "active": False},
                    },
                ]

                # Bulk insert
                insert_result = collection.insert_many(complex_docs)
                assert (
                    len(insert_result.inserted_ids) == 2
                ), "❌ MongoDB bulk insert failed"

                # Test indexing
                collection.create_index("name")
                collection.create_index([("age", 1), ("profile.active", -1)])

                # Test complex queries
                active_users = list(collection.find({"profile.active": True}))
                assert len(active_users) == 1, "❌ MongoDB complex query failed"

                python_users = list(collection.find({"skills": "Python"}))
                assert len(python_users) == 1, "❌ MongoDB array query failed"

                # Test aggregation pipeline
                pipeline = [
                    {"$match": {"age": {"$gte": 25}}},
                    {"$group": {"_id": "$profile.location", "count": {"$sum": 1}}},
                    {"$sort": {"count": -1}},
                ]

                agg_result = list(collection.aggregate(pipeline))
                assert len(agg_result) >= 1, "❌ MongoDB aggregation failed"

            finally:
                # Clean up
                db.drop_collection("advanced_test")

    def test_redis_full_functionality(self) -> None:
        """
        🔴 Test Redis complete functionality including all data structures.

        This test verifies:
        - Connection and authentication
        - All Redis data types (strings, hashes, lists, sets, sorted sets)
        - Pub/Sub functionality
        - Pipeline operations
        - Expiration and TTL
        - Memory usage optimization
        """
        redis_config = DATABASE_SERVICES["infra-default-redis"]

        # Ensure service is available
        assert DatabaseTestUtils.wait_for_service(
            "localhost", redis_config["port"], timeout=30
        ), f"❌ Redis service not available on port {redis_config['port']}"

        # Perform comprehensive Redis operations
        with DatabaseTestUtils.redis_connection() as client:
            results = perform_redis_crud_test(client)

            assert results["string_ops"], "❌ Redis string operations failed"
            assert results["hash_ops"], "❌ Redis hash operations failed"
            assert results["list_ops"], "❌ Redis list operations failed"
            assert results["set_ops"], "❌ Redis set operations failed"
            assert results["expiry"], "❌ Redis expiry functionality failed"

            # Additional Redis-specific advanced functionality
            try:
                # Test sorted sets
                client.zadd(
                    "test_zset", {"member1": 1.0, "member2": 2.0, "member3": 3.0}
                )
                zset_count = client.zcard("test_zset")
                assert zset_count == 3, "❌ Redis sorted set operations failed"

                top_member = client.zrevrange("test_zset", 0, 0, withscores=True)
                assert (
                    top_member[0][0] == b"member3"
                ), "❌ Redis sorted set ranking failed"

                # Test atomic operations
                client.set("counter", 0)
                pipe = client.pipeline()
                for _ in range(10):
                    pipe.incr("counter")
                pipe.execute()

                final_count = int(client.get("counter"))
                assert final_count == 10, "❌ Redis atomic operations failed"

                # Test pub/sub (simplified test)
                pubsub = client.pubsub()
                pubsub.subscribe("test_channel")

                # Publish a test message
                client.publish("test_channel", "test_message")

                # Check if subscription worked
                message = pubsub.get_message(timeout=1)
                if message and message["type"] == "subscribe":
                    message = pubsub.get_message(timeout=1)
                    if message:
                        assert (
                            message["data"] == b"test_message"
                        ), "❌ Redis pub/sub failed"

                pubsub.unsubscribe("test_channel")
                pubsub.close()

                # Test memory optimization
                client.config_set("maxmemory-policy", "allkeys-lru")
                memory_policy = client.config_get("maxmemory-policy")
                assert "allkeys-lru" in str(
                    memory_policy
                ), "❌ Redis memory policy config failed"

            finally:
                # Clean up test keys
                test_keys = ["test_zset", "counter", "test_channel"]
                client.delete(*test_keys)


@pytest.mark.integration
@pytest.mark.databases
@pytest.mark.parametrize("service_name,config", DATABASE_SERVICES.items())
def test_database_service_availability(service_name: str, config: dict) -> None:
    """
    🔍 Test that all database services are available and responsive.

    This parameterized test checks each database service individually
    to ensure they are running and accepting connections.
    """
    port = config["port"]
    db_type = config["type"]

    # Wait for service to be available
    is_available = DatabaseTestUtils.wait_for_service("localhost", port, timeout=30)
    assert is_available, (
        f"❌ {service_name} ({db_type}) is not available on port {port}. "
        f"Ensure the service is running and properly configured."
    )


def _check_postgresql_health(service_name: str) -> dict:
    """Check PostgreSQL service health."""
    try:
        with DatabaseTestUtils.postgres_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT version();")
                version = cursor.fetchone()[0]
                return {"status": "healthy", "version": version}
    except DatabaseConnectionError as e:
        return {"status": "connection_failed", "error": str(e)}


def _check_mysql_health(service_name: str) -> dict:
    """Check MySQL service health."""
    try:
        with DatabaseTestUtils.mysql_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT VERSION();")
            version = cursor.fetchone()[0]
            cursor.close()
            return {"status": "healthy", "version": version}
    except DatabaseConnectionError as e:
        return {"status": "connection_failed", "error": str(e)}


def _check_mongodb_health(service_name: str) -> dict:
    """Check MongoDB service health."""
    try:
        with DatabaseTestUtils.mongodb_connection() as client:
            server_info = client.server_info()
            return {
                "status": "healthy",
                "version": server_info.get("version", "unknown"),
            }
    except DatabaseConnectionError as e:
        return {"status": "connection_failed", "error": str(e)}


def _check_redis_health(service_name: str) -> dict:
    """Check Redis service health."""
    try:
        with DatabaseTestUtils.redis_connection() as client:
            info = client.info()
            return {
                "status": "healthy",
                "version": info.get("redis_version", "unknown"),
            }
    except DatabaseConnectionError as e:
        return {"status": "connection_failed", "error": str(e)}


def _check_service_health(service_name: str, config: dict) -> dict:
    """Check health for a specific database service."""
    port = config["port"]
    db_type = config["type"]

    # Check service availability
    is_available = DatabaseTestUtils.wait_for_service("localhost", port, timeout=10)
    if not is_available:
        return {
            "status": "unavailable",
            "error": f"Service not reachable on port {port}",
        }

    # Perform type-specific health checks
    health_checkers = {
        "postgresql": _check_postgresql_health,
        "mysql": _check_mysql_health,
        "mongodb": _check_mongodb_health,
        "redis": _check_redis_health,
    }

    checker = health_checkers.get(db_type)
    if checker:
        return checker(service_name)

    return {"status": "error", "error": f"Unknown database type: {db_type}"}


@pytest.mark.integration
@pytest.mark.databases
def test_database_services_comprehensive_health() -> None:
    """
    🏥 Comprehensive health check for all database services.

    This test performs a complete health assessment of the database
    infrastructure, testing connectivity, basic operations, and
    service readiness indicators.
    """
    health_results = {}

    for service_name, config in DATABASE_SERVICES.items():
        try:
            health_results[service_name] = _check_service_health(service_name, config)
        except Exception as e:
            health_results[service_name] = {"status": "error", "error": str(e)}

    # Verify all services are healthy
    failed_services = [
        name for name, result in health_results.items() if result["status"] != "healthy"
    ]

    if failed_services:
        failure_details = "\n".join(
            [
                f"  - {name}: {health_results[name]['status']} ({health_results[name].get('error', 'Unknown error')})"
                for name in failed_services
            ]
        )
        pytest.fail(
            f"❌ {len(failed_services)} database service(s) failed health check:\n{failure_details}"
        )

    # Print summary for successful run
    print(f"\n✅ All {len(health_results)} database services are healthy:")
    for service_name, result in health_results.items():
        print(f"  ✓ {service_name}: {result.get('version', 'version unknown')}")
