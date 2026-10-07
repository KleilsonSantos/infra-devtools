"""Unit tests for port preflight helpers (no Docker required for pure logic)."""

from __future__ import annotations

import pytest

from src.utils import port_preflight as pp


@pytest.mark.unit
def test_is_our_holder_accepts_infra_prefix() -> None:
    assert pp.is_our_holder("docker:infra-default-postgres", "infra-default-postgres")
    assert pp.is_our_holder("docker:infra-default-redis")
    assert not pp.is_our_holder("docker:vault-spring-postgres", "infra-default-postgres")
    assert not pp.is_our_holder("proc:ssh:123")


@pytest.mark.unit
def test_service_port_map_covers_core_data_plane() -> None:
    assert 5432 in pp.SERVICE_HOST_PORTS["postgres"]
    assert 6379 in pp.SERVICE_HOST_PORTS["redis"]
    assert 8200 in pp.SERVICE_HOST_PORTS["vault"]


@pytest.mark.unit
def test_port_catalog_has_no_duplicate_host_ports() -> None:
    pp.assert_unique_port_catalog()


@pytest.mark.unit
def test_compose_yml_host_ports_are_unique() -> None:
    """Static parse of docker-compose.yml — one HOST_PORT must not map to two services."""
    from collections import defaultdict
    import re
    from pathlib import Path

    text = Path("docker-compose.yml").read_text(encoding="utf-8")
    ports: dict[int, list[str]] = defaultdict(list)
    svc = None
    in_ports = False
    for line in text.splitlines():
        m = re.match(r"^  ([a-zA-Z0-9_-]+):\s*$", line)
        if m:
            svc = m.group(1)
            in_ports = False
            continue
        if re.match(r"^\s+ports:\s*$", line):
            in_ports = True
            continue
        if in_ports:
            pm = re.search(r"""['\"]?(?:(?:\d+\.){3}\d+:)?(\d+):(\d+)""", line)
            if pm and svc:
                ports[int(pm.group(1))].append(svc)
            elif line.strip() and not line.strip().startswith("-") and not line.strip().startswith("#"):
                in_ports = False
    dups = {p: sorted(set(s)) for p, s in ports.items() if len(set(s)) > 1}
    assert not dups, f"Duplicate HOST ports in compose: {dups}"
