"""
Integration tests to verify that essential Docker containers are running.

This module checks the running status of each container listed to ensure
the infrastructure is up and operational.
"""

import pytest
from testinfra.host import Host

from src.utils.constants import CONTAINERS


@pytest.mark.integration
@pytest.mark.parametrize("container", CONTAINERS)
def test_containers_running(host: Host, container: str) -> None:
    """🧪 Checks if the container is running."""
    service = host.docker(container)
    assert service.is_running, f"❌ Container {container} is not running!"
