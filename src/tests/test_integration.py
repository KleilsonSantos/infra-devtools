from testcontainers.postgres import PostgresContainer
import psycopg2
import pytest
import os
from dotenv import load_dotenv

load_dotenv()

@pytest.mark.integration
def test_postgres_service():
    """Testa se o serviço PostgreSQL do docker-compose está funcionando corretamente."""
    conn = psycopg2.connect(
        host="172.18.0.3",
        port=5432,
        user=os.getenv("POSTGRES_USER"),
        password=os.getenv("POSTGRES_PASSWORD"),
        database=os.getenv("POSTGRES_DB"),
    )
    cursor = conn.cursor()
    cursor.execute("SELECT 1;")
    result = cursor.fetchone()
    assert result[0] == 1, "O serviço PostgreSQL não está respondendo corretamente."
    conn.close()

@pytest.mark.integration
def test_postgres_container():
    """Testa se o container PostgreSQL temporário está funcionando corretamente."""
    with PostgresContainer("postgres:15") as postgres:
        postgres.with_env("POSTGRES_DB", "defaultdb")
        postgres.with_env("POSTGRES_USER", "admin")
        postgres.with_env("POSTGRES_PASSWORD", "adminpass")
        
        conn = psycopg2.connect(
            host=postgres.get_container_host_ip(),
            port=postgres.get_exposed_port(5432),
            user="admin",
            password="adminpass",
            database="defaultdb",
        )
        cursor = conn.cursor()
        cursor.execute("SELECT 1;")
        result = cursor.fetchone()
        assert result[0] == 1, "O container PostgreSQL não está respondendo corretamente."
        conn.close()