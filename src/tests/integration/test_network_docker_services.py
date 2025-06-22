"""
Integration tests to verify Docker network existence, container accessibility, and DNS resolution.

This module checks if the main Docker network exists, if containers are accessible via
localhost and mapped ports, and if containers correctly resolve DNS names both externally
and internally.
"""

import logging
import socket
from typing import Tuple

import pytest
from testinfra.host import Host

logging.basicConfig(level=logging.INFO)

# List of containers and their respective ports
CONTAINER_PORTS: list[Tuple[str, int]] = [
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


@pytest.mark.integration
@pytest.mark.network
def test_network_exists(host: Host) -> None:
    """🕸️ Checks if the main Docker network 'infra-default-shared-net' exists."""
    network_name = "infra-default-shared-net"
    networks = host.check_output(
        "docker network ls --filter name=%s --format '{{.Name}}'", network_name
    )
    assert network_name in networks, f"❌ Network {network_name} not found!"


@pytest.mark.integration
@pytest.mark.network
@pytest.mark.parametrize("container_name, port", CONTAINER_PORTS)
def test_container_accessible(container_name: str, port: int) -> None:
    """🔌 Checks if containers are accessible via localhost and mapped port."""
    try:
        with socket.create_connection(("localhost", port), timeout=5):
            pass
    except OSError as e:
        pytest.fail(f"❌ Failed to connect to {container_name}:{port} → {e}")


@pytest.mark.integration
@pytest.mark.network
def test_dns_resolution_getent(host: Host) -> None:
    """🌐 Checks if containers resolve DNS via getent hosts."""
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
        assert (
            result.rc == 0 and target_host in result.stdout
        ), f"❌ [getent] DNS FAIL: {service} → {target_host}"


@pytest.mark.integration
@pytest.mark.network
def test_service_dns_resolution(host: Host) -> None:
    """📡 Checks if services resolve their own DNS before connecting."""
    services = [
        "infra-default-mysql",
        "infra-default-postgres",
        "infra-default-redis",
        "infra-default-mongo",
    ]

    for service in services:
        try:
            result = host.run(f"docker exec {service} getent hosts {service}")
            if result.rc == 0 and service in result.stdout:
                logging.info("✅ DNS successfully resolved for %s", service)
            else:
                logging.error("❌ DNS resolution failed for %s", service)
                pytest.fail(f"❌ Service {service} could not resolve its DNS correctly")
        except OSError as e:
            logging.error("❌ Error testing DNS for %s → %s", service, e)
            pytest.fail(f"❌ Critical DNS check failure for {service}: {e}")
