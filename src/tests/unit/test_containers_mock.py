from unittest.mock import MagicMock

import pytest

containers = [
    "infra-default-cadvisor",
    "infra-default-grafana",
    "infra-default-mongo",
    "infra-default-mongo-express",
    "infra-default-mongodb-exporter",
    "infra-default-mysql",
    "infra-default-mysql-exporter",
    "infra-default-node-exporter",
    "infra-default-pgadmin",
    "infra-default-phpmyadmin",
    "infra-default-portainer",
    "infra-default-postgres",
    "infra-default-postgres-exporter",
    "infra-default-prometheus",
    "infra-default-redis",
    "infra-default-redis-exporter",
    "infra-default-redisinsight",
    "infra-default-sonarqube",
]


@pytest.mark.unit
@pytest.mark.parametrize("container", containers)
def test_container_is_running_mocked(container: str) -> None:
    mock_service = MagicMock()
    mock_service.is_running = True

    mock_host = MagicMock()
    mock_host.docker.return_value = mock_service

    service = mock_host.docker(container)
    assert service.is_running, f"❌ Mock: Container {container} não está rodando!"
