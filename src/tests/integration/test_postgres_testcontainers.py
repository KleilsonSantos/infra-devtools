"""
Integration test for a temporary PostgreSQL container using Testcontainers.

This module loads environment variables from a .env file to configure the
PostgreSQL container with a fixed password, then verifies that the container
starts correctly and accepts connections.
"""

import os

import psycopg2
import pytest
from dotenv import load_dotenv
from psycopg2.extensions import connection
from testcontainers.postgres import PostgresContainer

from src.utils.db_asserts import assert_postgres_connection

load_dotenv()


@pytest.mark.integration
def test_postgres_container() -> None:
    """🧪 Tests a temporary PostgreSQL container using Testcontainers."""
    fixed_password = os.getenv("POSTGRES_PASSWORD")

    # ⛔️ Important: configure all environment variables BEFORE entering the `with`
    postgres = PostgresContainer("postgres:15")
    postgres = (
        postgres.with_env("POSTGRES_DB", "defaultdb")
        .with_env("POSTGRES_USER", "admin")
        .with_env("POSTGRES_PASSWORD", fixed_password)
    )

    with postgres:  # The container starts here, with environment variables already set
        conn: connection = psycopg2.connect(
            host=postgres.get_container_host_ip(),
            port=postgres.get_exposed_port(5432),
            user="admin",
            password=fixed_password,
            database="defaultdb",
        )

        assert_postgres_connection(conn)
