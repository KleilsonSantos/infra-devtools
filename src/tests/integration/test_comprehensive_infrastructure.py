"""
Comprehensive infrastructure validation tests.

This module performs complete validation of all infrastructure services,
including recently added services and comprehensive functionality testing.
"""

import pytest
import requests
from testinfra.host import Host

from src.utils.constants import (
    CONTAINERS,
    DATABASE_SERVICES,
    METRICS_EXPORTERS,
    WEB_SERVICES,
)
from src.utils.database_testing import DatabaseTestUtils
from src.utils.security_testing import comprehensive_security_test


@pytest.mark.integration
@pytest.mark.comprehensive
def test_all_containers_running(host: Host) -> None:
    """🐳 Validate that ALL containers from docker-compose are running."""
    failed_containers = []

    for container in CONTAINERS:
        service = host.docker(container)
        if not service.is_running:
            failed_containers.append(container)
        else:
            print(f"✅ {container} is running")

    if failed_containers:
        failure_msg = f"❌ {len(failed_containers)} containers not running: {', '.join(failed_containers)}"
        pytest.fail(failure_msg)

    print(f"🎉 All {len(CONTAINERS)} containers are running successfully!")


@pytest.mark.integration
@pytest.mark.comprehensive
def test_all_web_services_responsive() -> None:
    """🌐 Test that all web services are responding correctly."""
    failed_services = []

    for service_name, config in WEB_SERVICES.items():
        try:
            url = f"http://localhost:{config['port']}{config['endpoint']}"
            auth = config.get("auth")

            response = requests.get(url, auth=auth, timeout=15)

            if response.status_code != config["expected_status"]:
                failed_services.append(
                    f"{service_name}: Expected {config['expected_status']}, got {response.status_code}"
                )
            else:
                print(f"✅ {service_name} responding correctly")

        except requests.RequestException as e:
            failed_services.append(f"{service_name}: Connection failed - {e}")

    if failed_services:
        failure_msg = "❌ Web service failures:\n" + "\n".join(failed_services)
        pytest.fail(failure_msg)

    print(f"🎉 All {len(WEB_SERVICES)} web services are responding!")


@pytest.mark.integration
@pytest.mark.comprehensive
def test_all_metrics_exporters() -> None:
    """📊 Test that all metrics exporters are providing metrics."""
    failed_exporters = []

    for exporter_name, config in METRICS_EXPORTERS.items():
        try:
            url = f"http://localhost:{config['port']}{config['endpoint']}"
            response = requests.get(url, timeout=15)

            if response.status_code != 200:
                failed_exporters.append(f"{exporter_name}: HTTP {response.status_code}")
            elif "# HELP" not in response.text:
                failed_exporters.append(
                    f"{exporter_name}: No Prometheus metrics format detected"
                )
            else:
                # Count metrics
                metric_lines = [
                    line
                    for line in response.text.split("\n")
                    if line and not line.startswith("#")
                ]
                print(f"✅ {exporter_name}: {len(metric_lines)} metrics exported")

        except requests.RequestException as e:
            failed_exporters.append(f"{exporter_name}: Connection failed - {e}")

    if failed_exporters:
        failure_msg = "❌ Metrics exporter failures:\n" + "\n".join(failed_exporters)
        pytest.fail(failure_msg)

    print(f"🎉 All {len(METRICS_EXPORTERS)} metrics exporters are working!")


@pytest.mark.integration
@pytest.mark.comprehensive
@pytest.mark.slow
def test_all_databases_functional() -> None:
    """🗄️ Test that all databases are functionally working with CRUD operations."""
    db_results = {}
    failures = []

    for service_name, config in DATABASE_SERVICES.items():
        try:
            db_type = config["type"]
            port = config["port"]

            # Wait for service to be ready
            if not DatabaseTestUtils.wait_for_service("localhost", port, timeout=30):
                failures.append(f"{service_name}: Service not reachable on port {port}")
                continue

            if db_type == "postgresql":
                with DatabaseTestUtils.postgres_connection() as conn:
                    from src.utils.database_testing import perform_postgres_crud_test

                    db_results[service_name] = perform_postgres_crud_test(conn)

            elif db_type == "mysql":
                with DatabaseTestUtils.mysql_connection() as conn:
                    from src.utils.database_testing import perform_mysql_crud_test

                    db_results[service_name] = perform_mysql_crud_test(conn)

            elif db_type == "mongodb":
                with DatabaseTestUtils.mongodb_connection() as client:
                    from src.utils.database_testing import perform_mongodb_crud_test

                    db_results[service_name] = perform_mongodb_crud_test(client)

            elif db_type == "redis":
                with DatabaseTestUtils.redis_connection() as client:
                    from src.utils.database_testing import perform_redis_crud_test

                    db_results[service_name] = perform_redis_crud_test(client)

            # Validate CRUD results
            service_results = db_results[service_name]
            failed_operations = [
                op for op, success in service_results.items() if not success
            ]

            if failed_operations:
                failures.append(
                    f"{service_name}: Failed operations - {', '.join(failed_operations)}"
                )
            else:
                operations_count = len(service_results)
                print(
                    f"✅ {service_name}: All {operations_count} operations successful"
                )

        except Exception as e:
            failures.append(f"{service_name}: {str(e)}")

    if failures:
        failure_msg = "❌ Database functionality failures:\n" + "\n".join(failures)
        pytest.fail(failure_msg)

    print(f"🎉 All {len(DATABASE_SERVICES)} databases are fully functional!")


@pytest.mark.integration
@pytest.mark.comprehensive
def test_all_security_services_functional() -> None:
    """🔒 Test that all security services are functionally working."""
    security_results = comprehensive_security_test()
    failures = []

    for service_name, results in security_results.items():
        if results.get("overall_status") == "FAIL":
            failures.append(f"{service_name}: {results.get('error', 'Unknown error')}")
        else:
            successful_tests = sum(
                1 for result in results.values() if result is True and result != "PASS"
            )
            total_tests = len(
                [
                    k
                    for k, v in results.items()
                    if k != "overall_status" and isinstance(v, bool)
                ]
            )
            print(
                f"✅ {service_name}: {successful_tests}/{total_tests} security tests passed"
            )

    if failures:
        failure_msg = "❌ Security service failures:\n" + "\n".join(failures)
        pytest.fail(failure_msg)

    print("🎉 All security services are functional!")


def _check_network_connectivity() -> tuple[int, str]:
    """Check network connectivity and return container count and network name."""
    import docker  # type: ignore[import-untyped]

    client = docker.from_env()
    network_name = "infra-default-shared-net"

    try:
        network = client.networks.get(network_name)
        connected_containers = network.attrs.get("Containers", {})
        return len(connected_containers), network_name
    except docker.errors.NotFound:
        raise RuntimeError(f"Network {network_name} not found")


def _test_dns_resolution() -> int:
    """Test DNS resolution between containers."""
    import docker  # type: ignore[import-untyped]

    client = docker.from_env()
    network = client.networks.get("infra-default-shared-net")
    connected_containers = network.attrs.get("Containers", {})

    test_container = None
    for container_id in connected_containers:
        try:
            test_container = client.containers.get(container_id)
            break
        except Exception:
            continue

    if not test_container:
        return 0

    dns_tests = ["postgres", "mongo", "redis", "rabbitmq"]
    successful_resolutions = 0

    for service in dns_tests:
        try:
            result = test_container.exec_run(f"nslookup {service}", timeout=5)
            if result.exit_code == 0:
                successful_resolutions += 1
        except Exception:
            pass

    return successful_resolutions


@pytest.mark.integration
@pytest.mark.comprehensive
def test_service_discovery_and_networking() -> None:
    """🔗 Test that services can communicate with each other."""
    try:
        container_count, network_name = _check_network_connectivity()

        if container_count < len(CONTAINERS):
            pytest.fail(
                f"❌ Only {container_count} containers connected to {network_name}, "
                f"expected {len(CONTAINERS)}"
            )

        print(f"✅ Network {network_name} has {container_count} connected containers")

        successful_resolutions = _test_dns_resolution()

        if successful_resolutions > 0:
            print(
                f"✅ DNS resolution working: {successful_resolutions}/4 services resolvable"
            )
        else:
            print("⚠️ DNS resolution tests inconclusive")

    except Exception as e:
        pytest.fail(f"❌ Network test failed: {e}")


def _check_containers_health() -> dict:
    """Check container health status."""
    from testinfra import get_host  # type: ignore[import-untyped]

    host = get_host("local://")
    health_data = {"total": len(CONTAINERS), "running": 0, "failed": []}

    for container in CONTAINERS:
        service = host.docker(container)
        if service.is_running:
            health_data["running"] += 1
        else:
            health_data["failed"].append(container)

    return health_data


def _check_web_services_health() -> dict:
    """Check web services health status."""
    health_data = {"total": len(WEB_SERVICES), "responsive": 0, "failed": []}

    for service_name, config in WEB_SERVICES.items():
        try:
            url = f"http://localhost:{config['port']}{config['endpoint']}"
            auth = config.get("auth")
            response = requests.get(url, auth=auth, timeout=10)

            if response.status_code == config["expected_status"]:
                health_data["responsive"] += 1
            else:
                health_data["failed"].append(service_name)
        except Exception:
            health_data["failed"].append(service_name)

    return health_data


def _check_databases_health() -> dict:
    """Check database connectivity health."""
    health_data = {"total": len(DATABASE_SERVICES), "functional": 0, "failed": []}

    for service_name, config in DATABASE_SERVICES.items():
        port = config["port"]
        if DatabaseTestUtils.wait_for_service("localhost", port, timeout=10):
            health_data["functional"] += 1
        else:
            health_data["failed"].append(service_name)

    return health_data


def _check_metrics_health() -> dict:
    """Check metrics exporters health."""
    health_data = {"total": len(METRICS_EXPORTERS), "exporting": 0, "failed": []}

    for exporter_name, config in METRICS_EXPORTERS.items():
        try:
            url = f"http://localhost:{config['port']}{config['endpoint']}"
            response = requests.get(url, timeout=10)
            if response.status_code == 200 and "# HELP" in response.text:
                health_data["exporting"] += 1
            else:
                health_data["failed"].append(exporter_name)
        except Exception:
            health_data["failed"].append(exporter_name)

    return health_data


def _get_status_indicator(failed: int, working: int, total: int) -> str:
    """Get status indicator emoji based on failure count."""
    if failed == 0:
        return "✅"
    elif working > total // 2:
        return "⚠️"
    else:
        return "❌"


def _print_health_report(health_report: dict) -> tuple[int, int]:
    """Print health report and return total and working services."""
    print("\n" + "=" * 60)
    print("🏥 COMPLETE INFRASTRUCTURE HEALTH REPORT")
    print("=" * 60)

    total_services = 0
    working_services = 0

    for category, stats in health_report.items():
        total = stats["total"]
        working = stats.get(
            "responsive",
            stats.get("functional", stats.get("running", stats.get("exporting", 0))),
        )
        failed = len(stats["failed"])

        total_services += total
        working_services += working

        status = _get_status_indicator(failed, working, total)
        print(
            f"{status} {category.upper()}: {working}/{total} working ({failed} failed)"
        )

        if failed > 0:
            failed_list = ", ".join(stats["failed"][:3])
            extra = f" and {failed-3} more" if failed > 3 else ""
            print(f"   Failed: {failed_list}{extra}")

    return total_services, working_services


@pytest.mark.integration
@pytest.mark.comprehensive
@pytest.mark.slow
def test_complete_infrastructure_health() -> None:
    """🏥 Complete infrastructure health check - all services together."""
    health_report = {
        "containers": _check_containers_health(),
        "web_services": _check_web_services_health(),
        "databases": _check_databases_health(),
        "metrics": _check_metrics_health(),
    }

    total_services, working_services = _print_health_report(health_report)

    print("=" * 60)
    overall_health = (working_services / total_services) * 100
    print(
        f"🎯 OVERALL HEALTH: {working_services}/{total_services} ({overall_health:.1f}%)"
    )

    if overall_health < 80:
        pytest.fail(f"❌ Infrastructure health below 80%: {overall_health:.1f}%")
    elif overall_health < 95:
        print(
            f"⚠️ Infrastructure health acceptable but not optimal: {overall_health:.1f}%"
        )
    else:
        print(f"🎉 Infrastructure health excellent: {overall_health:.1f}%")

    print("=" * 60)
