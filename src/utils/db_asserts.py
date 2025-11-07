"""Utility functions for asserting database connections."""

import psycopg2


def assert_postgres_connection(conn: psycopg2.extensions.connection) -> None:
    """Assert that the provided PostgreSQL connection is valid by executing a simple query."""
    cursor = conn.cursor()
    cursor.execute("SELECT 1;")
    result = cursor.fetchone()
    assert (
        result is not None and result[0] == 1
    ), "❌ PostgreSQL did not respond correctly."

    conn.close()
