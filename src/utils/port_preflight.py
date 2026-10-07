"""Shared port/conflict preflight for pytest and Python test runners.

Mirrors scripts/lib-port-preflight.sh so integration/docker tests fail closed
when a host port is held by a foreign process/container.
"""

from __future__ import annotations

import json
import re
import subprocess
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Dict, List, Optional, Sequence, Tuple

INFRA_PREFIX = "infra-default-"

# service → host ports (docker-compose publish map)
SERVICE_HOST_PORTS: Dict[str, Tuple[int, ...]] = {
    "redis": (6379,),
    "postgres": (5432,),
    "mongo": (27017,),
    "mysql": (3306,),
    "prometheus": (9090,),
    "alertmanager": (9093,),
    "node-exporter": (9100,),
    "blackbox-exporter": (9115,),
    "postgres-exporter": (9187,),
    "redis-exporter": (9121,),
    "mongodb-exporter": (9216,),
    "mysql-exporter": (9104,),
    "grafana": (3001,),
    "rabbitmq": (5672, 15672),
    "vault": (8200,),
    "mailhog": (1025, 8025),
    "pgadmin": (8088,),
    "phpmyadmin": (8082,),
    "redisinsight": (8083,),
    "mongo-express": (8081,),
    "cadvisor": (8080,),
    "portainer": (9001,),
    "sonarqube": (9000,),
    "keycloak": (8099,),
    "webhook-listener": (5001,),
}


@dataclass(frozen=True)
class PortConflict:
    service: str
    port: int
    holder: str
    action: str


def _run(cmd: Sequence[str]) -> str:
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def port_listening(port: int) -> bool:
    out = _run(["lsof", "-nP", f"-iTCP:{port}", "-sTCP:LISTEN"])
    return bool(out.strip())


def port_holder(port: int) -> str:
    ps = _run(["docker", "ps", "--format", "{{.Names}}\t{{.Ports}}"])
    needle = f":{port}->"
    for line in ps.splitlines():
        if "\t" not in line:
            continue
        name, ports = line.split("\t", 1)
        if needle in ports:
            return f"docker:{name}"
    lsof = _run(["lsof", "-nP", f"-iTCP:{port}", "-sTCP:LISTEN"])
    lines = [ln for ln in lsof.splitlines() if ln.strip()]
    if len(lines) >= 2:
        parts = lines[1].split()
        if len(parts) >= 2:
            return f"proc:{parts[0]}:{parts[1]}"
    return "unknown" if port_listening(port) else "free"


def is_our_holder(holder: str, expected_container: Optional[str] = None) -> bool:
    if expected_container and holder == f"docker:{expected_container}":
        return True
    return bool(re.match(rf"^docker:{re.escape(INFRA_PREFIX)}", holder))


def container_name(service: str) -> str:
    return f"{INFRA_PREFIX}{service}"


def scan_conflicts(
    services: Optional[Sequence[str]] = None,
) -> List[PortConflict]:
    """Return wrong owners for mapped ports (test mode — exact container)."""
    assert_unique_port_catalog()
    svcs = list(services) if services else list(SERVICE_HOST_PORTS.keys())
    found: List[PortConflict] = []
    for svc in svcs:
        expected = container_name(svc)
        for port in SERVICE_HOST_PORTS.get(svc, ()):
            if not port_listening(port):
                continue
            holder = port_holder(port)
            if holder == f"docker:{expected}":
                continue
            found.append(
                PortConflict(
                    service=svc,
                    port=port,
                    holder=holder,
                    action="test_abort_wrong_owner",
                )
            )
    return found


def assert_unique_port_catalog() -> None:
    """Fail if two services claim the same host port in SERVICE_HOST_PORTS."""
    owner: Dict[int, str] = {}
    for svc, ports in SERVICE_HOST_PORTS.items():
        for port in ports:
            prev = owner.get(port)
            if prev and prev != svc:
                raise AssertionError(
                    f"Port catalog conflict: host port {port} claimed by both "
                    f"'{prev}' and '{svc}'"
                )
            owner[port] = svc


def assert_service_ports_owned(service: str) -> None:
    """Fail unless every listening port for service is held by its exact container."""
    expected = container_name(service)
    for port in SERVICE_HOST_PORTS.get(service, ()):
        if not port_listening(port):
            raise AssertionError(
                f"Service {service}: port {port} not listening after expected up"
            )
        holder = port_holder(port)
        if holder != f"docker:{expected}":
            raise AssertionError(
                f"Service {service}: port {port} owned by {holder}, "
                f"expected docker:{expected}"
            )


def assert_no_foreign_ports(
    services: Optional[Sequence[str]] = None,
) -> None:
    """Raise AssertionError if any mapped port has the wrong owner."""
    assert_unique_port_catalog()
    svcs = list(services) if services else list(SERVICE_HOST_PORTS.keys())
    conflicts: List[PortConflict] = []
    for svc in svcs:
        for port in SERVICE_HOST_PORTS.get(svc, ()):
            if not port_listening(port):
                continue
            holder = port_holder(port)
            expected = container_name(svc)
            if holder == f"docker:{expected}":
                continue
            conflicts.append(
                PortConflict(
                    service=svc,
                    port=port,
                    holder=holder,
                    action="test_abort_wrong_owner",
                )
            )
    if not conflicts:
        return
    payload = [
        {
            "service": c.service,
            "port": c.port,
            "holder": c.holder,
            "action": c.action,
            "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        }
        for c in conflicts
    ]
    detail = "\n".join(
        f"  - {c.service}:{c.port} held by {c.holder} "
        f"(expected docker:{container_name(c.service)})"
        for c in conflicts
    )
    raise AssertionError(
        "Port preflight FAILED — wrong/foreign owner(s):\n"
        f"{detail}\njson={json.dumps(payload)}\n"
        "Stop holders or fix compose port mappings before tests."
    )
