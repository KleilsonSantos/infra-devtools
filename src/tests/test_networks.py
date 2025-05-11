import socket
import pytest
import logging

logging.basicConfig(level=logging.INFO)

containers = [
    ("infra-default-mongo", 27017),
    ("infra-default-mongo-express", 8081),
    ("infra-default-mysql", 3306),
    ("infra-default-mysql-exporter", 9104),
    ("infra-default-sonarqube", 9000),
    ("infra-default-grafana", 3001),
    ("infra-default-cadvisor", 8080),
    ("infra-default-pgadmin", 8082),
    ("infra-default-phpmyadmin", 8088),
    ("infra-default-portainer", 9001),
    ("infra-default-prometheus", 9090),
    ("infra-default-redis", 6379),
    ("infra-default-postgres", 5432),
    ("infra-default-redisinsight", 8083),
    ("infra-default-node-exporter", 9100),
    ("infra-default-redis-exporter", 9121),
    ("infra-default-mongodb-exporter", 9216),
    ("infra-default-postgres-exporter", 9187),
]
@pytest.mark.network
def test_network_exists(host):
    """Verifica se a rede Docker principal existe."""
    network_name = "infra-default-shared-net"
    networks = host.check_output("docker network ls --filter name=%s --format '{{.Name}}'", network_name)
    assert network_name in networks, f"A rede {network_name} não foi encontrada!"


@pytest.mark.parametrize("container_name, port", containers)
def test_container_accessible(host, container_name, port):
    connected = False
    try:
        with socket.create_connection(("localhost", port), timeout=5):
            connected = True
    except Exception as e:
        print(f"Erro ao conectar com {container_name}:{port} -> {e}")
    assert connected, f"❌ Falha ao conectar em {container_name}:{port}"

@pytest.mark.network
def test_dns_resolution_getent(host):
    """Verifica resolução de DNS usando getent hosts"""
    services = [
        "infra-default-mongo",
        "infra-default-redis",
        "infra-default-mysql",
        "infra-default-grafana",
        "infra-default-pgadmin",
        "infra-default-cadvisor",
        "infra-default-postgres",
        "infra-default-sonarqube",
        "infra-default-phpmyadmin",
        "infra-default-redisinsight",
        "infra-default-mongo-express",
    ]
    target_host = "infra-default-postgres"

    for service in services:
        result = host.run(f"docker exec {service} getent hosts {target_host}")
        assert result.rc == 0 and target_host in result.stdout, f"[getent] DNS FAIL: {service} -> {target_host}"


@pytest.mark.network
def test_service_dns_resolution(host):
    """Verifica se os serviços podem resolver DNS antes de conectar."""
    
    services = [
        "infra-default-mysql",
        "infra-default-postgres",
        "infra-default-redis",
        "infra-default-mongo"
    ]

    for service in services:
        try:
            result = host.run(f"docker exec {service} getent hosts {service}")
            if result.rc == 0 and service in result.stdout:
                logging.info(f"✅ DNS resolvido corretamente para {service}")
            else:
                logging.error(f"❌ Falha na resolução DNS para {service}")
                pytest.fail(f"❌ Serviço {service} não conseguiu resolver DNS corretamente")
        except Exception as e:
                logging.error(f"❌ Erro ao testar DNS para {service} -> {e}")
                pytest.fail(f"❌ Erro crítico na verificação DNS para {service}: {e}")

