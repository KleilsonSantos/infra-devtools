import os

import psycopg2
import pytest
from dotenv import load_dotenv

load_dotenv()


@pytest.mark.integration
def test_postgres_service():
    """Testa se o PostgreSQL via docker-compose está funcionando."""
    conn = psycopg2.connect(
        host="localhost",
        port=5432,
        user=os.getenv("POSTGRES_USER"),
        password=os.getenv("POSTGRES_PASSWORD"),
        database=os.getenv("POSTGRES_DB"),
    )
    cursor = conn.cursor()
    cursor.execute("SELECT 1;")
    result = cursor.fetchone()
    assert result[0] == 1, "❌ PostgreSQL não respondeu corretamente."
    conn.close()
