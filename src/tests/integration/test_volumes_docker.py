"""
Integration tests to verify the existence and correct mounting of Docker volumes.

This module checks that the required Docker volumes are created on the host system
and properly mounted inside their respective containers.
"""

import pytest
from testinfra.host import Host

from src.utils.constants import CONTAINERS_VOLUMES, VOLUMES


@pytest.mark.integration
@pytest.mark.volumes
def test_volumes_exist(host: Host) -> None:
    """💾 Checks if the required Docker volumes are created in the system."""
    for volume in VOLUMES:
        result = host.run(f"docker volume inspect {volume}")
        assert result.rc == 0, f"❌ Volume `{volume}` does not exist in Docker!"


@pytest.mark.integration
@pytest.mark.volumes
def test_volumes_mounted(host: Host) -> None:
    """📦 Checks if volumes are correctly mounted inside their associated containers."""
    for container, mount_path in CONTAINERS_VOLUMES.items():
        result = host.run(f"docker exec {container} test -d {mount_path}")
        assert (
            result.rc == 0
        ), f"❌ Volume `{mount_path}` is not mounted inside container `{container}`!"
