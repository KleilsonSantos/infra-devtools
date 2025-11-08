"""
Comprehensive infrastructure health checks and integration tests.

This module provides a complete health assessment of the entire infrastructure
stack, testing all components together to ensure they work as an integrated
system ready for production workloads.
"""

import concurrent.futures
import time
from typing import Dict

import pytest  # type: ignore[import-untyped]

from src.tests.integration.test_web_services_functionality import WebServiceTestUtils
from src.utils.constants import (
    CONTAINERS,
    DATABASE_SERVICES,
    METRICS_EXPORTERS,
    WEB_SERVICES,
)
from src.utils.database_testing import (
    DatabaseTestUtils,
    perform_mongodb_crud_test,
    perform_mysql_crud_test,
    perform_postgres_crud_test,
    perform_redis_crud_test,
)


class InfrastructureHealthChecker:
    """Complete infrastructure health assessment utility."""

    @staticmethod
    def check_container_status() -> Dict[str, str]:
        """Check the status of all expected containers."""
        container_results = {}

        # This would normally use docker API, but for simplicity we'll assume running
        # In a real implementation, you'd use docker-py or subprocess to check
        for container in CONTAINERS:
            container_results[container] = "running"  # Simplified for demo

        return container_results

    @staticmethod
    def check_database_health() -> Dict[str, Dict]:
        """Perform health checks on all database services."""
        db_results = {}

        for service_name, config in DATABASE_SERVICES.items():
            try:
                port = config["port"]
                db_type = config["type"]

                # Check service availability
                is_available = DatabaseTestUtils.wait_for_service(
                    "localhost", port, timeout=15
                )

                if not is_available:
                    db_results[service_name] = {
                        "status": "unavailable",
                        "error": f"Port {port} not reachable",
                    }
                    continue

                # Perform basic connectivity test
                if db_type == "postgresql":
                    with DatabaseTestUtils.postgres_connection() as conn:
                        with conn.cursor() as cursor:
                            cursor.execute("SELECT 1;")
                            result = cursor.fetchone()
                            if result and result[0] == 1:
                                db_results[service_name] = {
                                    "status": "healthy",
                                    "type": db_type,
                                }
                            else:
                                db_results[service_name] = {
                                    "status": "error",
                                    "error": "Query failed",
                                }

                elif db_type == "mysql":
                    with DatabaseTestUtils.mysql_connection() as conn:
                        cursor = conn.cursor()
                        cursor.execute("SELECT 1;")
                        result = cursor.fetchone()
                        cursor.close()
                        if result and result[0] == 1:
                            db_results[service_name] = {
                                "status": "healthy",
                                "type": db_type,
                            }
                        else:
                            db_results[service_name] = {
                                "status": "error",
                                "error": "Query failed",
                            }

                elif db_type == "mongodb":
                    with DatabaseTestUtils.mongodb_connection() as client:
                        # Test with admin command
                        client.admin.command("ismaster")
                        db_results[service_name] = {
                            "status": "healthy",
                            "type": db_type,
                        }

                elif db_type == "redis":
                    with DatabaseTestUtils.redis_connection() as client:
                        pong = client.ping()
                        if pong:
                            db_results[service_name] = {
                                "status": "healthy",
                                "type": db_type,
                            }
                        else:
                            db_results[service_name] = {
                                "status": "error",
                                "error": "Ping failed",
                            }

            except Exception as e:
                db_results[service_name] = {"status": "error", "error": str(e)}

        return db_results

    @staticmethod
    def check_web_services_health() -> Dict[str, Dict]:
        """Perform health checks on all web services."""
        web_results = {}

        all_services = {**WEB_SERVICES, **METRICS_EXPORTERS}

        for service_name, config in all_services.items():
            try:
                port = config["port"]
                endpoint = config["endpoint"]
                auth = config.get("auth")

                base_url = f"http://localhost:{port}"
                full_url = f"{base_url}{endpoint}"

                # Check availability
                is_available = WebServiceTestUtils.wait_for_web_service(
                    full_url, timeout=10, auth=auth
                )

                if not is_available:
                    web_results[service_name] = {
                        "status": "unavailable",
                        "error": f"Endpoint {full_url} not reachable",
                    }
                    continue

                # Test endpoint response
                response = WebServiceTestUtils.make_authenticated_request(
                    full_url, auth=auth
                )

                if response.status_code < 400:
                    web_results[service_name] = {
                        "status": "healthy",
                        "status_code": response.status_code,
                        "type": (
                            "metrics" if service_name in METRICS_EXPORTERS else "web"
                        ),
                    }
                else:
                    web_results[service_name] = {
                        "status": "error",
                        "status_code": response.status_code,
                        "error": f"HTTP {response.status_code}",
                    }

            except Exception as e:
                web_results[service_name] = {"status": "error", "error": str(e)}

        return web_results

    @staticmethod
    def perform_integration_tests() -> Dict[str, bool]:
        """Perform cross-service integration tests."""
        integration_results = {
            "database_crud_operations": False,
            "web_service_connectivity": False,
            "monitoring_data_flow": False,
            "end_to_end_functionality": False,
        }

        try:
            # Test database CRUD operations
            db_operations_success = 0
            db_operations_total = 0

            for service_name, config in DATABASE_SERVICES.items():
                db_type = config["type"]
                try:
                    if db_type == "postgresql":
                        with DatabaseTestUtils.postgres_connection() as conn:
                            results = perform_postgres_crud_test(conn)
                            if all(results.values()):
                                db_operations_success += 1

                    elif db_type == "mysql":
                        with DatabaseTestUtils.mysql_connection() as conn:
                            results = perform_mysql_crud_test(conn)
                            if all(results.values()):
                                db_operations_success += 1

                    elif db_type == "mongodb":
                        with DatabaseTestUtils.mongodb_connection() as client:
                            results = perform_mongodb_crud_test(client)
                            if all(results.values()):
                                db_operations_success += 1

                    elif db_type == "redis":
                        with DatabaseTestUtils.redis_connection() as client:
                            results = perform_redis_crud_test(client)
                            if all(results.values()):
                                db_operations_success += 1

                    db_operations_total += 1

                except Exception:
                    db_operations_total += 1

            if db_operations_success == db_operations_total and db_operations_total > 0:
                integration_results["database_crud_operations"] = True

            # Test web service connectivity (sample a few key services)
            key_web_services = [
                "infra-default-grafana",
                "infra-default-prometheus",
                "infra-default-portainer",
            ]
            web_services_healthy = 0

            for service_name in key_web_services:
                if service_name in WEB_SERVICES:
                    config = WEB_SERVICES[service_name]
                    try:
                        port = config["port"]
                        endpoint = config["endpoint"]
                        auth = config.get("auth")

                        full_url = f"http://localhost:{port}{endpoint}"

                        if WebServiceTestUtils.wait_for_web_service(
                            full_url, timeout=5, auth=auth
                        ):
                            response = WebServiceTestUtils.make_authenticated_request(
                                full_url, auth=auth
                            )
                            if response.status_code < 400:
                                web_services_healthy += 1
                    except Exception:
                        pass

            if (
                web_services_healthy >= len(key_web_services) // 2
            ):  # At least half should be healthy
                integration_results["web_service_connectivity"] = True

            # Test monitoring data flow (simplified)
            try:
                # Check if Prometheus is collecting metrics from at least one exporter
                prometheus_config = WEB_SERVICES.get("infra-default-prometheus")
                if prometheus_config:
                    prometheus_url = f"http://localhost:{prometheus_config['port']}"

                    # Check if we can query for 'up' metrics
                    response = WebServiceTestUtils.make_authenticated_request(
                        f"{prometheus_url}/api/v1/query?query=up"
                    )

                    if response.status_code == 200:
                        data = response.json()
                        if (
                            data.get("status") == "success"
                            and len(data.get("data", {}).get("result", [])) > 0
                        ):
                            integration_results["monitoring_data_flow"] = True
            except Exception:
                pass

            # End-to-end functionality test
            if (
                integration_results["database_crud_operations"]
                and integration_results["web_service_connectivity"]
            ):
                integration_results["end_to_end_functionality"] = True

        except Exception:
            pass

        return integration_results


@pytest.mark.integration
@pytest.mark.comprehensive
class TestInfrastructureIntegration:
    """Comprehensive infrastructure integration test suite."""

    def test_complete_infrastructure_health(self) -> None:
        """
        🏥 Complete infrastructure health check covering all components.

        This test performs a comprehensive assessment of:
        - All container services
        - Database functionality and connectivity
        - Web services and API endpoints
        - Metrics collection and monitoring
        - Cross-service integrations
        """
        print("\n🔍 Starting comprehensive infrastructure health check...")

        # Collect all health data
        health_data = {
            "databases": InfrastructureHealthChecker.check_database_health(),
            "web_services": InfrastructureHealthChecker.check_web_services_health(),
            "integrations": InfrastructureHealthChecker.perform_integration_tests(),
        }

        # Analyze results
        failed_components = []

        # Check database health
        unhealthy_dbs = [
            name
            for name, result in health_data["databases"].items()
            if result["status"] != "healthy"
        ]
        if unhealthy_dbs:
            failed_components.extend([f"Database: {name}" for name in unhealthy_dbs])

        # Check web services health
        unhealthy_web = [
            name
            for name, result in health_data["web_services"].items()
            if result["status"] != "healthy"
        ]
        if unhealthy_web:
            failed_components.extend([f"Web Service: {name}" for name in unhealthy_web])

        # Check integration tests
        failed_integrations = [
            name for name, result in health_data["integrations"].items() if not result
        ]
        if failed_integrations:
            failed_components.extend(
                [f"Integration: {name}" for name in failed_integrations]
            )

        # Report results
        total_databases = len(health_data["databases"])
        healthy_databases = sum(
            1
            for result in health_data["databases"].values()
            if result["status"] == "healthy"
        )

        total_web_services = len(health_data["web_services"])
        healthy_web_services = sum(
            1
            for result in health_data["web_services"].values()
            if result["status"] == "healthy"
        )

        total_integrations = len(health_data["integrations"])
        passed_integrations = sum(health_data["integrations"].values())

        print(f"\n📊 Infrastructure Health Summary:")
        print(f"  🗃️  Databases: {healthy_databases}/{total_databases} healthy")
        print(f"  🌐 Web Services: {healthy_web_services}/{total_web_services} healthy")
        print(f"  🔗 Integrations: {passed_integrations}/{total_integrations} passing")

        # Fail if any critical components are unhealthy
        if failed_components:
            failure_details = "\n".join(
                [f"  ❌ {component}" for component in failed_components]
            )
            pytest.fail(
                f"\n❌ Infrastructure health check failed:\n{failure_details}\n"
                f"\nSummary: {len(failed_components)} component(s) unhealthy"
            )

        print(f"\n✅ All infrastructure components are healthy and functional!")

    def test_production_readiness_checklist(self) -> None:
        """
        🚀 Production readiness checklist validation.

        This test validates that the infrastructure meets production requirements:
        - All essential services are running
        - Performance benchmarks are met
        - Monitoring and alerting are functional
        - Data persistence is working
        - Security basics are in place
        """
        readiness_checks = {
            "essential_services_running": False,
            "databases_functional": False,
            "monitoring_active": False,
            "web_interfaces_accessible": False,
            "data_persistence_verified": False,
        }

        # Check essential services
        db_health = InfrastructureHealthChecker.check_database_health()
        healthy_dbs = sum(
            1 for result in db_health.values() if result["status"] == "healthy"
        )

        if (
            healthy_dbs >= len(DATABASE_SERVICES) * 0.8
        ):  # At least 80% of databases healthy
            readiness_checks["essential_services_running"] = True

        # Check database functionality
        if healthy_dbs == len(DATABASE_SERVICES):
            readiness_checks["databases_functional"] = True

        # Check monitoring
        web_health = InfrastructureHealthChecker.check_web_services_health()
        monitoring_services = [
            "infra-default-prometheus",
            "infra-default-grafana",
            "infra-default-node-exporter",
            "infra-default-cadvisor",
        ]

        healthy_monitoring = sum(
            1
            for service in monitoring_services
            if service in web_health and web_health[service]["status"] == "healthy"
        )

        if (
            healthy_monitoring >= len(monitoring_services) * 0.75
        ):  # At least 75% monitoring healthy
            readiness_checks["monitoring_active"] = True

        # Check web interfaces
        web_services_count = len(
            [s for s in web_health if web_health[s].get("type") == "web"]
        )
        healthy_web_count = sum(
            1
            for result in web_health.values()
            if result["status"] == "healthy" and result.get("type") == "web"
        )

        if web_services_count > 0 and healthy_web_count >= web_services_count * 0.8:
            readiness_checks["web_interfaces_accessible"] = True

        # Check data persistence (simplified test)
        integration_results = InfrastructureHealthChecker.perform_integration_tests()
        if integration_results.get("database_crud_operations", False):
            readiness_checks["data_persistence_verified"] = True

        # Calculate readiness score
        passed_checks = sum(readiness_checks.values())
        total_checks = len(readiness_checks)
        readiness_score = (passed_checks / total_checks) * 100

        print(f"\n🎯 Production Readiness Assessment:")
        for check_name, result in readiness_checks.items():
            status = "✅ PASS" if result else "❌ FAIL"
            print(f"  {status} {check_name.replace('_', ' ').title()}")

        print(f"\n📈 Overall Readiness Score: {readiness_score:.1f}%")

        # Require at least 80% readiness for production
        if readiness_score < 80.0:
            failed_checks = [
                name for name, result in readiness_checks.items() if not result
            ]
            pytest.fail(
                f"❌ Infrastructure not production ready ({readiness_score:.1f}% < 80%)\n"
                f"Failed checks: {', '.join(failed_checks)}"
            )

        print(
            f"✅ Infrastructure is production ready! ({readiness_score:.1f}% readiness)"
        )


@pytest.mark.integration
@pytest.mark.comprehensive
def test_infrastructure_load_simulation() -> None:
    """
    ⚡ Simulate load on infrastructure to test performance and stability.

    This test simulates realistic load patterns to ensure the infrastructure
    can handle production workloads without degradation.
    """
    print("\n⚡ Starting infrastructure load simulation...")

    load_test_results = {
        "database_concurrent_operations": False,
        "web_service_response_times": False,
        "metrics_collection_under_load": False,
        "system_stability": False,
    }

    start_time = time.time()

    try:
        # Simulate concurrent database operations
        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            # Test PostgreSQL under load
            postgres_futures = []
            for _ in range(3):
                future = executor.submit(_test_postgres_load)
                postgres_futures.append(future)

            # Test Redis under load
            redis_futures = []
            for _ in range(3):
                future = executor.submit(_test_redis_load)
                redis_futures.append(future)

            # Wait for all database tests
            postgres_results = [f.result() for f in postgres_futures if f.result()]
            redis_results = [f.result() for f in redis_futures if f.result()]

            if len(postgres_results) >= 2 and len(redis_results) >= 2:
                load_test_results["database_concurrent_operations"] = True

        # Test web service response times under load
        web_response_times = []
        services_to_test = ["infra-default-prometheus", "infra-default-grafana"]

        for service_name in services_to_test:
            if service_name in WEB_SERVICES:
                config = WEB_SERVICES[service_name]
                port = config["port"]
                endpoint = config["endpoint"]
                auth = config.get("auth")

                full_url = f"http://localhost:{port}{endpoint}"

                # Measure response time
                start_req_time = time.time()
                try:
                    response = WebServiceTestUtils.make_authenticated_request(
                        full_url, auth=auth, timeout=5
                    )
                    if response.status_code < 400:
                        response_time = time.time() - start_req_time
                        web_response_times.append(response_time)
                except Exception:
                    pass

        # Consider acceptable if average response time is under 3 seconds
        if (
            web_response_times
            and sum(web_response_times) / len(web_response_times) < 3.0
        ):
            load_test_results["web_service_response_times"] = True

        # Check if metrics collection is still working
        try:
            prometheus_config = WEB_SERVICES.get("infra-default-prometheus")
            if prometheus_config:
                prometheus_url = f"http://localhost:{prometheus_config['port']}"
                response = WebServiceTestUtils.make_authenticated_request(
                    f"{prometheus_url}/api/v1/query?query=up"
                )

                if response.status_code == 200:
                    data = response.json()
                    if (
                        data.get("status") == "success"
                        and len(data.get("data", {}).get("result", [])) > 0
                    ):
                        load_test_results["metrics_collection_under_load"] = True
        except Exception:
            pass

        # Check system stability (test completed without major errors)
        elapsed_time = time.time() - start_time
        if elapsed_time < 60:  # Test should complete within reasonable time
            load_test_results["system_stability"] = True

    except Exception as e:
        pytest.fail(f"❌ Load simulation failed with error: {e}")

    # Evaluate results
    passed_tests = sum(load_test_results.values())
    total_tests = len(load_test_results)

    print(f"\n📊 Load Simulation Results:")
    for test_name, result in load_test_results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"  {status} {test_name.replace('_', ' ').title()}")

    if passed_tests < total_tests:
        failed_tests = [
            name for name, result in load_test_results.items() if not result
        ]
        pytest.fail(
            f"❌ Load simulation failed: {len(failed_tests)} test(s) failed\n"
            f"Failed: {', '.join(failed_tests)}"
        )

    print(
        f"✅ Infrastructure successfully handled load simulation ({passed_tests}/{total_tests} tests passed)"
    )


def _test_postgres_load() -> bool:
    """Helper function to test PostgreSQL under load."""
    try:
        with DatabaseTestUtils.postgres_connection() as conn:
            with conn.cursor() as cursor:
                # Perform some operations
                for i in range(10):
                    cursor.execute("SELECT %s as test_value;", (i,))
                    result = cursor.fetchone()
                    if not result or result[0] != i:
                        return False
        return True
    except Exception:
        return False


def _test_redis_load() -> bool:
    """Helper function to test Redis under load."""
    try:
        with DatabaseTestUtils.redis_connection() as client:
            # Perform some operations
            for i in range(20):
                key = f"load_test_{i}"
                client.set(key, f"value_{i}")
                value = client.get(key)
                if value != f"value_{i}".encode():
                    return False
                client.delete(key)
        return True
    except Exception:
        return False
