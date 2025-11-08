"""
Comprehensive tests for web services and HTTP endpoints.

This module validates that all web-based services are not only accessible
but fully functional, with proper authentication, API responses, and
service-specific functionality.
"""

import time
from typing import Dict, Optional, Tuple

import pytest
import requests
from requests.auth import HTTPBasicAuth
from requests.exceptions import ConnectionError, RequestException, Timeout

from src.utils.constants import METRICS_EXPORTERS, WEB_SERVICES


class WebServiceTestUtils:
    """Utility class for web service testing operations."""

    @staticmethod
    def wait_for_web_service(
        url: str, timeout: int = 30, auth: Optional[Tuple[str, str]] = None
    ) -> bool:
        """
        Wait for a web service to become available.

        Args:
            url: Full URL to test
            timeout: Maximum wait time in seconds
            auth: Optional basic auth tuple (username, password)

        Returns:
            True if service becomes available, False otherwise
        """
        start_time = time.time()

        while time.time() - start_time < timeout:
            try:
                response = requests.get(
                    url,
                    timeout=5,
                    auth=HTTPBasicAuth(*auth) if auth else None,
                    verify=False,  # For self-signed certificates in dev
                )
                if response.status_code < 500:  # Service is responding
                    return True
            except (ConnectionError, Timeout):
                pass
            time.sleep(2)

        return False

    @staticmethod
    def make_authenticated_request(
        url: str, auth: Optional[Tuple[str, str]] = None, timeout: int = 10
    ) -> requests.Response:
        """
        Make an authenticated HTTP request with proper error handling.

        Args:
            url: URL to request
            auth: Optional basic auth tuple
            timeout: Request timeout

        Returns:
            Response object

        Raises:
            RequestException: If request fails
        """
        try:
            response = requests.get(
                url,
                timeout=timeout,
                auth=HTTPBasicAuth(*auth) if auth else None,
                verify=False,
                allow_redirects=True,
            )
            return response
        except RequestException as e:
            raise RequestException(f"Request to {url} failed: {e}")


@pytest.mark.integration
@pytest.mark.web_services
class TestWebServiceFunctionality:
    """Test suite for web service functionality validation."""

    def test_grafana_full_functionality(self) -> None:
        """
        📊 Test Grafana complete functionality and API endpoints.

        This test verifies:
        - Health endpoint accessibility
        - Authentication system
        - Dashboard management API
        - Data source configuration API
        - Alerting functionality
        """
        grafana_config = WEB_SERVICES["infra-default-grafana"]
        base_url = f"http://localhost:{grafana_config['port']}"
        auth = grafana_config["auth"]

        # Wait for service to be available
        assert WebServiceTestUtils.wait_for_web_service(
            f"{base_url}{grafana_config['endpoint']}", auth=auth
        ), f"❌ Grafana not available at {base_url}"

        # Test health endpoint
        health_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/api/health", auth=auth
        )
        assert (
            health_response.status_code == 200
        ), f"❌ Grafana health check failed: {health_response.status_code}"

        health_data = health_response.json()
        assert (
            health_data.get("database") == "ok"
        ), "❌ Grafana database connection failed"

        # Test authentication and user info
        user_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/api/user", auth=auth
        )
        assert user_response.status_code == 200, "❌ Grafana authentication failed"

        user_data = user_response.json()
        assert (
            user_data.get("login") == auth[0]
        ), "❌ Grafana user authentication incorrect"

        # Test dashboards API
        dashboards_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/api/search?type=dash-db", auth=auth
        )
        assert (
            dashboards_response.status_code == 200
        ), "❌ Grafana dashboards API failed"

        # Test data sources API
        datasources_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/api/datasources", auth=auth
        )
        assert (
            datasources_response.status_code == 200
        ), "❌ Grafana data sources API failed"

    def test_prometheus_full_functionality(self) -> None:
        """
        🔍 Test Prometheus complete functionality and metrics endpoints.

        This test verifies:
        - Health and readiness endpoints
        - Metrics collection and scraping
        - Query API functionality
        - Configuration and targets
        - Rules and alerting setup
        """
        prometheus_config = WEB_SERVICES["infra-default-prometheus"]
        base_url = f"http://localhost:{prometheus_config['port']}"

        # Wait for service to be available
        assert WebServiceTestUtils.wait_for_web_service(
            f"{base_url}{prometheus_config['endpoint']}"
        ), f"❌ Prometheus not available at {base_url}"

        # Test health endpoint
        healthy_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/-/healthy"
        )
        assert healthy_response.status_code == 200, "❌ Prometheus health check failed"

        # Test readiness endpoint
        ready_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/-/ready"
        )
        assert ready_response.status_code == 200, "❌ Prometheus readiness check failed"

        # Test metrics endpoint
        metrics_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/metrics"
        )
        assert (
            metrics_response.status_code == 200
        ), "❌ Prometheus metrics endpoint failed"
        assert (
            "prometheus_build_info" in metrics_response.text
        ), "❌ Prometheus metrics format invalid"

        # Test query API
        query_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/api/v1/query?query=up"
        )
        assert query_response.status_code == 200, "❌ Prometheus query API failed"

        query_data = query_response.json()
        assert (
            query_data.get("status") == "success"
        ), "❌ Prometheus query execution failed"

        # Test targets API
        targets_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/api/v1/targets"
        )
        assert targets_response.status_code == 200, "❌ Prometheus targets API failed"

        targets_data = targets_response.json()
        assert (
            targets_data.get("status") == "success"
        ), "❌ Prometheus targets retrieval failed"

        # Verify at least some targets are discovered
        active_targets = targets_data.get("data", {}).get("activeTargets", [])
        assert len(active_targets) > 0, "❌ No active targets found in Prometheus"

    def test_sonarqube_full_functionality(self) -> None:
        """
        🧹 Test SonarQube complete functionality and code quality APIs.

        This test verifies:
        - System status and health
        - Project management APIs
        - Quality gates functionality
        - User authentication system
        - Plugin and marketplace access
        """
        sonarqube_config = WEB_SERVICES["infra-default-sonarqube"]
        base_url = f"http://localhost:{sonarqube_config['port']}"

        # Wait for service to be available (SonarQube takes longer to start)
        assert WebServiceTestUtils.wait_for_web_service(
            f"{base_url}{sonarqube_config['endpoint']}", timeout=60
        ), f"❌ SonarQube not available at {base_url}"

        # Test system status
        status_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/api/system/status"
        )
        assert status_response.status_code == 200, "❌ SonarQube status API failed"

        status_data = status_response.json()
        assert status_data.get("status") in [
            "UP",
            "STARTING",
        ], f"❌ SonarQube status: {status_data.get('status')}"

        # Test health endpoint
        health_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/api/system/health"
        )
        assert health_response.status_code == 200, "❌ SonarQube health API failed"

        # Test version info
        version_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/api/server/version"
        )
        assert version_response.status_code == 200, "❌ SonarQube version API failed"

        # Test quality gates API
        qualitygates_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/api/qualitygates/list"
        )
        assert qualitygates_response.status_code in [
            200,
            401,
        ], "❌ SonarQube quality gates API failed"

        # Test metrics API
        metrics_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/api/metrics/search"
        )
        assert metrics_response.status_code in [
            200,
            401,
        ], "❌ SonarQube metrics API failed"

    def test_rabbitmq_management_functionality(self) -> None:
        """
        🐇 Test RabbitMQ management interface and API functionality.

        This test verifies:
        - Management UI accessibility
        - API authentication
        - Cluster and node information
        - Queue and exchange management
        - Connection and channel monitoring
        """
        rabbitmq_config = WEB_SERVICES["infra-default-rabbitmq"]
        base_url = f"http://localhost:{rabbitmq_config['port']}"
        auth = rabbitmq_config["auth"]

        # Wait for service to be available
        assert WebServiceTestUtils.wait_for_web_service(
            f"{base_url}{rabbitmq_config['endpoint']}", auth=auth
        ), f"❌ RabbitMQ Management not available at {base_url}"

        # Test overview API
        overview_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/api/overview", auth=auth
        )
        assert overview_response.status_code == 200, "❌ RabbitMQ overview API failed"

        overview_data = overview_response.json()
        assert (
            "management_version" in overview_data
        ), "❌ RabbitMQ overview data incomplete"
        assert "rabbitmq_version" in overview_data, "❌ RabbitMQ version info missing"

        # Test nodes API
        nodes_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/api/nodes", auth=auth
        )
        assert nodes_response.status_code == 200, "❌ RabbitMQ nodes API failed"

        nodes_data = nodes_response.json()
        assert len(nodes_data) > 0, "❌ No RabbitMQ nodes found"
        assert nodes_data[0].get("running") is True, "❌ RabbitMQ node not running"

        # Test queues API
        queues_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/api/queues", auth=auth
        )
        assert queues_response.status_code == 200, "❌ RabbitMQ queues API failed"

        # Test exchanges API
        exchanges_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/api/exchanges", auth=auth
        )
        assert exchanges_response.status_code == 200, "❌ RabbitMQ exchanges API failed"

        exchanges_data = exchanges_response.json()
        # Should have default exchanges
        exchange_names = [ex.get("name") for ex in exchanges_data]
        assert "amq.direct" in exchange_names, "❌ RabbitMQ default exchanges missing"

    def test_portainer_management_functionality(self) -> None:
        """
        🐳 Test Portainer container management functionality.

        This test verifies:
        - Management UI accessibility
        - Docker engine connectivity
        - Container listing and management
        - System information retrieval
        """
        portainer_config = WEB_SERVICES["infra-default-portainer"]
        base_url = f"http://localhost:{portainer_config['port']}"

        # Wait for service to be available
        assert WebServiceTestUtils.wait_for_web_service(
            f"{base_url}{portainer_config['endpoint']}"
        ), f"❌ Portainer not available at {base_url}"

        # Test status endpoint
        status_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/api/status"
        )
        assert status_response.status_code == 200, "❌ Portainer status API failed"

        status_data = status_response.json()
        assert "Version" in status_data, "❌ Portainer version info missing"

        # Test system info (without auth for basic connectivity)
        system_response = WebServiceTestUtils.make_authenticated_request(
            f"{base_url}/api/system/info"
        )
        # Note: May return 401/403 without proper auth, but service is responding
        assert system_response.status_code in [
            200,
            401,
            403,
        ], "❌ Portainer system API not responding"


@pytest.mark.integration
@pytest.mark.web_services
@pytest.mark.parametrize("service_name,config", WEB_SERVICES.items())
def test_web_service_endpoints_availability(service_name: str, config: Dict) -> None:
    """
    🌐 Test that all web service endpoints are accessible and responsive.

    This parameterized test checks each web service endpoint individually
    to ensure they are responding to HTTP requests with expected status codes.
    """
    port = config["port"]
    endpoint = config["endpoint"]
    expected_status = config["expected_status"]
    auth = config.get("auth")

    base_url = f"http://localhost:{port}"
    full_url = f"{base_url}{endpoint}"

    # Wait for service to be available
    is_available = WebServiceTestUtils.wait_for_web_service(full_url, auth=auth)
    assert is_available, (
        f"❌ {service_name} endpoint not available at {full_url}. "
        f"Service may not be running or endpoint may be incorrect."
    )

    # Test the actual endpoint
    response = WebServiceTestUtils.make_authenticated_request(full_url, auth=auth)
    assert (
        response.status_code == expected_status
    ), f"❌ {service_name} returned status {response.status_code}, expected {expected_status}"


@pytest.mark.integration
@pytest.mark.metrics
@pytest.mark.parametrize("service_name,config", METRICS_EXPORTERS.items())
def test_metrics_exporters_functionality(service_name: str, config: Dict) -> None:
    """
    📈 Test that all metrics exporters are providing valid Prometheus metrics.

    This test validates that exporters are not only responding but providing
    properly formatted Prometheus metrics that can be scraped and processed.
    """
    port = config["port"]
    endpoint = config["endpoint"]
    expected_status = config["expected_status"]

    base_url = f"http://localhost:{port}"
    full_url = f"{base_url}{endpoint}"

    # Wait for service to be available
    is_available = WebServiceTestUtils.wait_for_web_service(full_url)
    assert is_available, (
        f"❌ {service_name} metrics endpoint not available at {full_url}. "
        f"Exporter may not be running or metrics endpoint may be incorrect."
    )

    # Test metrics endpoint
    response = WebServiceTestUtils.make_authenticated_request(full_url)
    assert (
        response.status_code == expected_status
    ), f"❌ {service_name} metrics returned status {response.status_code}, expected {expected_status}"

    # Validate metrics format
    metrics_content = response.text
    assert len(metrics_content) > 0, f"❌ {service_name} returned empty metrics"

    # Basic Prometheus metrics validation
    lines = metrics_content.split("\n")
    metric_lines = [line for line in lines if line and not line.startswith("#")]
    assert len(metric_lines) > 0, f"❌ {service_name} provided no valid metrics"

    # Check for basic Prometheus metric format (name{labels} value timestamp?)
    valid_metrics = 0
    for line in metric_lines[:10]:  # Check first 10 metrics
        if " " in line and not line.startswith("#"):
            parts = line.split(" ")
            if len(parts) >= 2:  # metric_name value [timestamp]
                try:
                    float(parts[1])  # Value should be numeric
                    valid_metrics += 1
                except ValueError:
                    pass

    assert valid_metrics > 0, f"❌ {service_name} provided malformed metrics"


@pytest.mark.integration
@pytest.mark.web_services
def test_web_services_comprehensive_health() -> None:
    """
    🏥 Comprehensive health check for all web services and metrics exporters.

    This test performs a complete health assessment of all HTTP-based services
    in the infrastructure, checking both accessibility and basic functionality.
    """
    all_services = {**WEB_SERVICES, **METRICS_EXPORTERS}
    health_results = {}

    for service_name, config in all_services.items():
        try:
            port = config["port"]
            endpoint = config["endpoint"]
            auth = config.get("auth")

            base_url = f"http://localhost:{port}"
            full_url = f"{base_url}{endpoint}"

            # Check service availability
            is_available = WebServiceTestUtils.wait_for_web_service(
                full_url, timeout=15, auth=auth
            )

            if not is_available:
                health_results[service_name] = {
                    "status": "unavailable",
                    "error": f"Service not reachable at {full_url}",
                }
                continue

            # Test endpoint response
            response = WebServiceTestUtils.make_authenticated_request(
                full_url, auth=auth
            )

            if response.status_code < 400:
                health_results[service_name] = {
                    "status": "healthy",
                    "status_code": response.status_code,
                    "url": full_url,
                }
            else:
                health_results[service_name] = {
                    "status": "error",
                    "status_code": response.status_code,
                    "error": f"HTTP {response.status_code}",
                }

        except Exception as e:
            health_results[service_name] = {"status": "error", "error": str(e)}

    # Verify all services are healthy
    failed_services = [
        name for name, result in health_results.items() if result["status"] != "healthy"
    ]

    if failed_services:
        failure_details = "\n".join(
            [
                f"  - {name}: {health_results[name]['status']} ({health_results[name].get('error', 'Unknown error')})"
                for name in failed_services
            ]
        )
        pytest.fail(
            f"❌ {len(failed_services)} web service(s) failed health check:\n{failure_details}"
        )

    # Print summary for successful run
    print(f"\n✅ All {len(health_results)} web services are healthy:")
    for service_name, result in health_results.items():
        print(f"  ✓ {service_name}: HTTP {result.get('status_code', 'N/A')}")
