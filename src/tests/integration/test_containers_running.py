import pytest
from testinfra.host import Host

CONTAINERS: list[str] = [
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


@pytest.mark.integration
@pytest.mark.parametrize("container", CONTAINERS)
def test_containers_running(host: Host, container: str) -> None:
    """🧪 Verifica se o container está em execução."""
    service = host.docker(container)
    assert service.is_running, f"❌ Container {container} não está rodando!"
