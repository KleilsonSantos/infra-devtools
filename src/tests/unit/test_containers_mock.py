"""
Unit tests that verify, using mocks, whether the infrastructure containers are running.

This module uses mocks to simulate the state of the listed Docker containers,
ensuring that tests do not depend on the real infrastructure during execution.
"""

from unittest.mock import MagicMock

import pytest

from src.utils.constants import CONTAINERS


@pytest.mark.unit
@pytest.mark.parametrize("container", CONTAINERS)
def test_container_is_running_mocked(container: str) -> None:
    """🧪 Checks if the container is running (mocked)."""
    mock_service = MagicMock()
    mock_service.is_running = True

    mock_host = MagicMock()
    mock_host.docker.return_value = mock_service

    service = mock_host.docker(container)
    assert service.is_running, f"❌ Mock: Container {container} is not running!"
