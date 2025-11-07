"""
Integration test to verify that the PostgreSQL service running via
docker-compose is working correctly.

This module reads connection parameters from environment variables and tests
if the PostgreSQL instance accepts connections and executes a simple query.
"""

import os

import psycopg2
import pytest
from dotenv import load_dotenv
from psycopg2.extensions import connection

from src.utils.db_asserts import assert_postgres_connection

load_dotenv()


@pytest.mark.integration
def test_postgres_service() -> None:
    """🐘 Checks if PostgreSQL via docker-compose is working correctly."""
    conn: connection = psycopg2.connect(
        host="localhost",
        port=5432,
        user=os.getenv("POSTGRES_USER"),
        password=os.getenv("POSTGRES_PASSWORD"),
        database=os.getenv("POSTGRES_DB"),
    )

    assert_postgres_connection(conn)
