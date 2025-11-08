import psycopg2
import pytest
from psycopg2.extensions import connection
from testcontainers.postgres import PostgresContainer


@pytest.mark.integration
def test_postgres_container() -> None:
    """🧪 Testa container PostgreSQL temporário utilizando Testcontainers."""
    with PostgresContainer("postgres:15") as postgres:
        postgres.with_env("POSTGRES_DB", "defaultdb")
        postgres.with_env("POSTGRES_USER", "admin")
        postgres.with_env("POSTGRES_PASSWORD", "adminpass")

        conn: connection = psycopg2.connect(
            host=postgres.get_container_host_ip(),
            port=postgres.get_exposed_port(5432),
            user="admin",
            password="adminpass",
            database="defaultdb",
        )

        cursor = conn.cursor()
        cursor.execute("SELECT 1;")
        result = cursor.fetchone()

        assert (
            result is not None and result[0] == 1
        ), "❌ Container PostgreSQL (isolado) não respondeu corretamente."

        conn.close()
