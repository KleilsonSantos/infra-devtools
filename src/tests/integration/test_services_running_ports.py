"""
Integration tests to verify the status and configuration of essential service containers.

This module checks if the essential Docker service containers are running, listening on
their expected ports, and if the Prometheus configuration is valid.
"""

import pytest
from testinfra.host import Host

from src.utils.constants import ESSENTIAL_SERVICES, SERVICES_PORTS


@pytest.mark.integration
@pytest.mark.services
def test_services_running(host: Host) -> None:
    """🟢 Checks if essential service containers are running."""
    for service in ESSENTIAL_SERVICES:
        container = host.docker(service)
        assert container.is_running, f"❌ Service {service} is not running!"


@pytest.mark.integration
@pytest.mark.services
def test_services_ports(host: Host) -> None:
    """🔌 Checks if services are listening on the expected ports."""
    for service, port in SERVICES_PORTS.items():
        socket = host.socket(f"tcp://0.0.0.0:{port}")
        assert (
            socket.is_listening
        ), f"❌ Service {service} is not listening on port {port}!"


@pytest.mark.integration
@pytest.mark.services
def test_prometheus_config(host: Host) -> None:
    """📊 Validates if the Prometheus configuration is correct using promtool."""
    result = host.run(
        "docker exec infra-default-prometheus promtool check config /etc/prometheus/prometheus.yml"
    )
    assert result.rc == 0, f"❌ Invalid Prometheus configuration: {result.stderr}"
