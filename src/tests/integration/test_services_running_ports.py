from typing import Any

import pytest


@pytest.mark.integration
@pytest.mark.services
def test_services_running(host: Any) -> None:
    """🟢 Verifica se os containers de serviços essenciais estão em execução."""
    services = [
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

    for service in services:
        container = host.docker(service)
        assert container.is_running, f"❌ O serviço {service} não está rodando!"


@pytest.mark.integration
@pytest.mark.services
def test_services_ports(host: Any) -> None:
    """🔌 Verifica se os serviços estão ouvindo nas portas esperadas."""
    services_ports = {
        "infra-default-mongo": 27017,
        "infra-default-mongo-express": 8081,
        "infra-default-mysql": 3306,
        "infra-default-mysql-exporter": 9104,
        "infra-default-sonarqube": 9000,
        "infra-default-grafana": 3001,
        "infra-default-cadvisor": 8080,
        "infra-default-pgadmin": 8082,
        "infra-default-phpmyadmin": 8088,
        "infra-default-portainer": 9001,
        "infra-default-prometheus": 9090,
        "infra-default-redis": 6379,
        "infra-default-postgres": 5432,
        "infra-default-redisinsight": 8083,
        "infra-default-node-exporter": 9100,
        "infra-default-redis-exporter": 9121,
        "infra-default-mongodb-exporter": 9216,
        "infra-default-postgres-exporter": 9187,
    }

    for service, port in services_ports.items():
        socket = host.socket(f"tcp://0.0.0.0:{port}")
        assert (
            socket.is_listening
        ), f"❌ O serviço {service} não está ouvindo na porta {port}!"


@pytest.mark.integration
@pytest.mark.services
def test_prometheus_config(host: Any) -> None:
    """📊 Valida se a configuração do Prometheus está correta utilizando promtool."""
    result = host.run(
        "docker exec infra-default-prometheus promtool check config /etc/prometheus/prometheus.yml"
    )
    assert result.rc == 0, f"❌ Configuração do Prometheus inválida: {result.stderr}"
