"""Pytest hooks: port conflict preflight for non-unit tests."""

from __future__ import annotations

import pytest

from src.utils.port_preflight import assert_no_foreign_ports


def _collected_needs_port_gate(session: pytest.Session) -> bool:
    for item in session.items:
        marks = {m.name for m in item.iter_markers()}
        if "unit" in marks and not (
            marks
            & {
                "integration",
                "docker",
                "network",
                "services",
                "volumes",
                "testcontainers",
            }
        ):
            continue
        path = str(getattr(item, "path", getattr(item, "fspath", "")))
        if "/unit/" in path.replace("\\", "/") and "/integration/" not in path.replace(
            "\\", "/"
        ):
            continue
        return True
    return False


@pytest.fixture(scope="session", autouse=True)
def _session_port_preflight(request: pytest.FixtureRequest) -> None:
    """Fail closed before integration/docker-like tests if foreign ports are busy."""
    if not _collected_needs_port_gate(request.session):
        return
    assert_no_foreign_ports()
