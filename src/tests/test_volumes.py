import testinfra

def test_volumes_exist(host):
    """Verifica se os volumes Docker necessários estão configurados."""
    volumes = [
        "infra-default-mongo_data",
        "infra-default-postgres_data",
        "infra-default-pgadmin-data",
        "infra-default-grafana-storage",
        "infra-default-mysql_data",
        "infra-default-redis_data",
    ]
    for volume in volumes:
        result = host.run(f"docker volume inspect {volume}")
        assert result.rc == 0, f"O volume {volume} não existe!"

def test_volumes_mounted(host):
    """Verifica se os volumes estão montados corretamente nos containers."""
    containers_volumes = {
    "infra-default-mongo": "/data/db",
    "infra-default-postgres": "/var/lib/postgresql/data",
    "infra-default-pgadmin": "/var/lib/pgadmin",
    "infra-default-mysql": "/var/lib/mysql",
    "infra-default-redis": "/data"
    }

    for container, volume_path in containers_volumes.items():
        result = host.run(f"docker exec {container} test -d {volume_path}")
        assert result.rc == 0, f"O volume {volume_path} não está montado no container {container}!"