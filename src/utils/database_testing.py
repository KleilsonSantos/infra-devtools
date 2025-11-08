"""
Database connection utilities for testing infrastructure services.

This module provides reliable connection utilities and test operations
for all database services in the infrastructure.
"""

import os
import time
from contextlib import contextmanager
from typing import Any, Dict, Generator, Optional

import mysql.connector  # type: ignore[import-untyped]
import psycopg2  # type: ignore[import-untyped]
import redis  # type: ignore[import-untyped]
from dotenv import load_dotenv  # type: ignore[import-untyped]
from mysql.connector import Error as MySQLError  # type: ignore[import-untyped]
from psycopg2.extensions import (
    connection as PostgresConnection,  # type: ignore[import-untyped]
)
from pymongo import MongoClient  # type: ignore[import-untyped]
from pymongo.errors import PyMongoError  # type: ignore[import-untyped]
from redis import Redis  # type: ignore[import-untyped]
from redis.exceptions import RedisError  # type: ignore[import-untyped]

load_dotenv()

# SQL Constants
DROP_TEST_TABLE = "DROP TABLE IF EXISTS test_infrastructure_table;"
CREATE_POSTGRES_TEST_TABLE = """
    CREATE TABLE test_infrastructure_table (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        value INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
"""
CREATE_MYSQL_TEST_TABLE = """
    CREATE TABLE test_infrastructure_table (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        value INT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
"""


class DatabaseConnectionError(Exception):
    """Custom exception for database connection issues."""


class DatabaseTestUtils:
    """Utility class for database testing operations."""

    @staticmethod
    def wait_for_service(host: str, port: int, timeout: int = 30) -> bool:
        """
        Wait for a service to be available.

        Args:
            host: Service hostname
            port: Service port
            timeout: Maximum wait time in seconds

        Returns:
            True if service becomes available, False otherwise
        """
        import socket

        start_time = time.time()
        while time.time() - start_time < timeout:
            try:
                with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
                    sock.settimeout(1)
                    result = sock.connect_ex((host, port))
                    if result == 0:
                        return True
                time.sleep(1)
            except socket.error:
                time.sleep(1)
        return False

    @staticmethod
    @contextmanager
    def postgres_connection(
        host: str = "localhost",
        port: int = 5432,
        user: Optional[str] = None,
        password: Optional[str] = None,
        database: Optional[str] = None,
    ) -> Generator[PostgresConnection, None, None]:
        """
        Context manager for PostgreSQL connections.

        Args:
            host: Database host
            port: Database port
            user: Database user (defaults to env POSTGRES_USER)
            password: Database password (defaults to env POSTGRES_PASSWORD)
            database: Database name (defaults to env POSTGRES_DB)

        Yields:
            PostgreSQL connection object

        Raises:
            DatabaseConnectionError: If connection fails
        """
        user = user or os.getenv("POSTGRES_USER")
        password = password or os.getenv("POSTGRES_PASSWORD")
        database = database or os.getenv("POSTGRES_DB")

        if not all([user, password, database]):
            raise DatabaseConnectionError("Missing PostgreSQL connection parameters")

        conn = None
        try:
            conn = psycopg2.connect(
                host=host,
                port=port,
                user=user,
                password=password,
                database=database,
                connect_timeout=10,
            )
            yield conn
        except psycopg2.Error as e:
            raise DatabaseConnectionError(f"PostgreSQL connection failed: {e}")
        finally:
            if conn:
                conn.close()

    @staticmethod
    @contextmanager
    def mysql_connection(
        host: str = "localhost",
        port: int = 3306,
        user: Optional[str] = None,
        password: Optional[str] = None,
        database: Optional[str] = None,
    ) -> Generator[mysql.connector.MySQLConnection, None, None]:
        """
        Context manager for MySQL connections.

        Args:
            host: Database host
            port: Database port
            user: Database user (defaults to env MYSQL_USER)
            password: Database password (defaults to env MYSQL_PASSWORD)
            database: Database name (defaults to env MYSQL_DATABASE)

        Yields:
            MySQL connection object

        Raises:
            DatabaseConnectionError: If connection fails
        """
        user = user or os.getenv("MYSQL_USER")
        password = password or os.getenv("MYSQL_PASSWORD")
        database = database or os.getenv("MYSQL_DATABASE")

        if not all([user, password, database]):
            raise DatabaseConnectionError("Missing MySQL connection parameters")

        conn = None
        try:
            conn = mysql.connector.connect(
                host=host,
                port=port,
                user=user,
                password=password,
                database=database,
                connection_timeout=10,
            )
            yield conn
        except MySQLError as e:
            raise DatabaseConnectionError(f"MySQL connection failed: {e}")
        finally:
            if conn and conn.is_connected():
                conn.close()

    @staticmethod
    @contextmanager
    def mongodb_connection(
        host: str = "localhost",
        port: int = 27017,
        username: Optional[str] = None,
        password: Optional[str] = None,
        database: Optional[str] = None,
    ) -> Generator[MongoClient, None, None]:
        """
        Context manager for MongoDB connections.

        Args:
            host: Database host
            port: Database port
            username: Database username (defaults to env MONGO_INITDB_ROOT_USERNAME)
            password: Database password (defaults to env MONGO_INITDB_ROOT_PASSWORD)
            database: Database name (defaults to env MONGO_INITDB_DATABASE)

        Yields:
            MongoDB client object

        Raises:
            DatabaseConnectionError: If connection fails
        """
        username = username or os.getenv("MONGO_INITDB_ROOT_USERNAME")
        password = password or os.getenv("MONGO_INITDB_ROOT_PASSWORD")
        database = database or os.getenv("MONGO_INITDB_DATABASE")

        if not all([username, password]):
            raise DatabaseConnectionError("Missing MongoDB connection parameters")

        client = None
        try:
            client = MongoClient(
                host=host,
                port=port,
                username=username,
                password=password,
                serverSelectionTimeoutMS=10000,
                connectTimeoutMS=10000,
            )
            # Test connection
            client.admin.command("ismaster")
            yield client
        except PyMongoError as e:
            raise DatabaseConnectionError(f"MongoDB connection failed: {e}")
        finally:
            if client:
                client.close()

    @staticmethod
    @contextmanager
    def redis_connection(
        host: str = "localhost",
        port: int = 6379,
        password: Optional[str] = None,
        db: int = 0,
    ) -> Generator[Redis, None, None]:
        """
        Context manager for Redis connections.

        Args:
            host: Redis host
            port: Redis port
            password: Redis password (defaults to env REDIS_PASSWORD)
            db: Redis database number

        Yields:
            Redis connection object

        Raises:
            DatabaseConnectionError: If connection fails
        """
        password = password or os.getenv("REDIS_PASSWORD")

        client = None
        try:
            client = redis.Redis(
                host=host,
                port=port,
                password=password if password else None,
                db=db,
                socket_connect_timeout=10,
                socket_timeout=10,
            )
            # Test connection
            client.ping()
            yield client
        except RedisError as e:
            raise DatabaseConnectionError(f"Redis connection failed: {e}")
        finally:
            if client:
                client.close()


def perform_postgres_crud_test(conn: PostgresConnection) -> Dict[str, Any]:
    """
    Perform comprehensive CRUD operations test on PostgreSQL.

    Args:
        conn: PostgreSQL connection

    Returns:
        Dictionary with test results
    """
    results = {"create": False, "read": False, "update": False, "delete": False}

    try:
        with conn.cursor() as cursor:
            # Create test table
            cursor.execute(DROP_TEST_TABLE + CREATE_POSTGRES_TEST_TABLE)
            conn.commit()
            results["create"] = True

            # Insert test data
            cursor.execute(
                "INSERT INTO test_infrastructure_table (name, value) VALUES (%s, %s) RETURNING id;",
                ("test_record", 42),
            )
            test_id = cursor.fetchone()[0]
            conn.commit()

            # Read test data
            cursor.execute(
                "SELECT name, value FROM test_infrastructure_table WHERE id = %s;",
                (test_id,),
            )
            record = cursor.fetchone()
            if record and record[0] == "test_record" and record[1] == 42:
                results["read"] = True

            # Update test data
            cursor.execute(
                "UPDATE test_infrastructure_table SET value = %s WHERE id = %s;",
                (84, test_id),
            )
            conn.commit()

            cursor.execute(
                "SELECT value FROM test_infrastructure_table WHERE id = %s;", (test_id,)
            )
            updated_value = cursor.fetchone()[0]
            if updated_value == 84:
                results["update"] = True

            # Delete test data
            cursor.execute(
                "DELETE FROM test_infrastructure_table WHERE id = %s;", (test_id,)
            )
            conn.commit()

            cursor.execute(
                "SELECT COUNT(*) FROM test_infrastructure_table WHERE id = %s;",
                (test_id,),
            )
            count = cursor.fetchone()[0]
            if count == 0:
                results["delete"] = True

            # Clean up
            cursor.execute(DROP_TEST_TABLE)
            conn.commit()

    except Exception as e:
        raise DatabaseConnectionError(f"PostgreSQL CRUD test failed: {e}")

    return results


def perform_mysql_crud_test(conn: mysql.connector.MySQLConnection) -> Dict[str, Any]:
    """
    Perform comprehensive CRUD operations test on MySQL.

    Args:
        conn: MySQL connection

    Returns:
        Dictionary with test results
    """
    results = {"create": False, "read": False, "update": False, "delete": False}

    try:
        cursor = conn.cursor()

        # Create test table
        cursor.execute(DROP_TEST_TABLE)
        cursor.execute(CREATE_MYSQL_TEST_TABLE)
        conn.commit()
        results["create"] = True

        # Insert test data
        cursor.execute(
            "INSERT INTO test_infrastructure_table (name, value) VALUES (%s, %s);",
            ("test_record", 42),
        )
        test_id = cursor.lastrowid
        conn.commit()

        # Read test data
        cursor.execute(
            "SELECT name, value FROM test_infrastructure_table WHERE id = %s;",
            (test_id,),
        )
        record = cursor.fetchone()
        if record and record[0] == "test_record" and record[1] == 42:
            results["read"] = True

        # Update test data
        cursor.execute(
            "UPDATE test_infrastructure_table SET value = %s WHERE id = %s;",
            (84, test_id),
        )
        conn.commit()

        cursor.execute(
            "SELECT value FROM test_infrastructure_table WHERE id = %s;", (test_id,)
        )
        record = cursor.fetchone()
        if record and record[0] == 84:
            results["update"] = True

        # Delete test data
        cursor.execute(
            "DELETE FROM test_infrastructure_table WHERE id = %s;", (test_id,)
        )
        conn.commit()

        cursor.execute(
            "SELECT COUNT(*) FROM test_infrastructure_table WHERE id = %s;", (test_id,)
        )
        count = cursor.fetchone()[0]
        if count == 0:
            results["delete"] = True

        # Clean up
        cursor.execute(DROP_TEST_TABLE)
        conn.commit()
        cursor.close()

    except Exception as e:
        raise DatabaseConnectionError(f"MySQL CRUD test failed: {e}")

    return results


def perform_mongodb_crud_test(client: MongoClient) -> Dict[str, Any]:
    """
    Perform comprehensive CRUD operations test on MongoDB.

    Args:
        client: MongoDB client

    Returns:
        Dictionary with test results
    """
    results = {"create": False, "read": False, "update": False, "delete": False}

    try:
        db = client.test_infrastructure_db
        collection = db.test_collection

        # Clean up any existing test data
        collection.drop()

        # Create (Insert) test data
        test_doc = {"name": "test_record", "value": 42, "type": "test"}
        insert_result = collection.insert_one(test_doc)
        if insert_result.inserted_id:
            results["create"] = True

        # Read test data
        found_doc = collection.find_one({"_id": insert_result.inserted_id})
        if (
            found_doc
            and found_doc["name"] == "test_record"
            and found_doc["value"] == 42
        ):
            results["read"] = True

        # Update test data
        update_result = collection.update_one(
            {"_id": insert_result.inserted_id}, {"$set": {"value": 84}}
        )
        if update_result.modified_count > 0:
            updated_doc = collection.find_one({"_id": insert_result.inserted_id})
            if updated_doc and updated_doc["value"] == 84:
                results["update"] = True

        # Delete test data
        delete_result = collection.delete_one({"_id": insert_result.inserted_id})
        if delete_result.deleted_count > 0:
            deleted_doc = collection.find_one({"_id": insert_result.inserted_id})
            if not deleted_doc:
                results["delete"] = True

        # Clean up
        collection.drop()

    except Exception as e:
        raise DatabaseConnectionError(f"MongoDB CRUD test failed: {e}")

    return results


def perform_redis_crud_test(client: Redis) -> Dict[str, Any]:
    """
    Perform comprehensive operations test on Redis.

    Args:
        client: Redis client

    Returns:
        Dictionary with test results
    """
    results = {
        "string_ops": False,
        "hash_ops": False,
        "list_ops": False,
        "set_ops": False,
        "expiry": False,
    }

    try:
        # Clean up any existing test keys
        test_keys = ["test_string", "test_hash", "test_list", "test_set", "test_expire"]
        client.delete(*test_keys)

        # String operations
        client.set("test_string", "test_value")
        if client.get("test_string") == b"test_value":
            results["string_ops"] = True

        # Hash operations
        client.hset("test_hash", mapping={"field1": "value1", "field2": "value2"})
        if (
            client.hget("test_hash", "field1") == b"value1"
            and client.hlen("test_hash") == 2
        ):
            results["hash_ops"] = True

        # List operations
        client.lpush("test_list", "item1", "item2", "item3")
        if client.llen("test_list") == 3 and client.rpop("test_list") == b"item1":
            results["list_ops"] = True

        # Set operations
        client.sadd("test_set", "member1", "member2", "member3")
        if client.scard("test_set") == 3 and client.sismember("test_set", "member1"):
            results["set_ops"] = True

        # Expiry test
        client.setex("test_expire", 2, "expire_value")
        if client.ttl("test_expire") > 0:
            results["expiry"] = True

        # Clean up
        client.delete(*test_keys)

    except Exception as e:
        raise DatabaseConnectionError(f"Redis operations test failed: {e}")

    return results
