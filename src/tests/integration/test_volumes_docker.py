from typing import Any

import pytest


@pytest.mark.integration
@pytest.mark.volumes
def test_volumes_exist(host: Any) -> None:
    """💾 Verifica se os volumes Docker necessários estão criados no sistema."""
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
        assert result.rc == 0, f"❌ O volume `{volume}` não existe no Docker!"


@pytest.mark.integration
@pytest.mark.volumes
def test_volumes_mounted(host: Any) -> None:
    """📦 Verifica se os volumes estão corretamente montados nos containers associados."""
    containers_volumes = {
        "infra-default-mongo": "/data/db",
        "infra-default-postgres": "/var/lib/postgresql/data",
        "infra-default-pgadmin": "/var/lib/pgadmin",
        "infra-default-mysql": "/var/lib/mysql",
        "infra-default-redis": "/data",
    }

    for container, mount_path in containers_volumes.items():
        result = host.run(f"docker exec {container} test -d {mount_path}")
        assert (
            result.rc == 0
        ), f"❌ O volume `{mount_path}` não está montado no container `{container}`!"
