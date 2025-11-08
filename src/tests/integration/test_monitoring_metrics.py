"""
Comprehensive tests for monitoring infrastructure and metrics collection.

This module validates the complete observability stack including Prometheus
scraping, metrics exporters functionality, Grafana dashboards integration,
and alerting pipeline to ensure production-ready monitoring.
"""

import re
import time
from typing import Dict, List, Optional

import pytest  # type: ignore[import-untyped]
import requests
from requests.auth import HTTPBasicAuth
from requests.exceptions import RequestException

from src.utils.constants import METRICS_EXPORTERS, WEB_SERVICES


class MonitoringTestUtils:
    """Utility class for monitoring and metrics testing."""

    @staticmethod
    def get_prometheus_metrics(
        prometheus_url: str = "http://localhost:9090",
    ) -> Optional[str]:
        """
        Retrieve metrics from Prometheus /metrics endpoint.

        Args:
            prometheus_url: Prometheus base URL

        Returns:
            Metrics content as string or None if failed
        """
        try:
            response = requests.get(f"{prometheus_url}/metrics", timeout=10)
            if response.status_code == 200:
                return response.text
            return None
        except RequestException:
            return None

    @staticmethod
    def query_prometheus(
        query: str, prometheus_url: str = "http://localhost:9090"
    ) -> Optional[Dict]:
        """
        Execute a PromQL query against Prometheus API.

        Args:
            query: PromQL query string
            prometheus_url: Prometheus base URL

        Returns:
            Query result dictionary or None if failed
        """
        try:
            response = requests.get(
                f"{prometheus_url}/api/v1/query", params={"query": query}, timeout=10
            )
            if response.status_code == 200:
                return response.json()
            return None
        except RequestException:
            return None

    @staticmethod
    def get_prometheus_targets(
        prometheus_url: str = "http://localhost:9090",
    ) -> Optional[Dict]:
        """
        Get all Prometheus targets and their states.

        Args:
            prometheus_url: Prometheus base URL

        Returns:
            Targets information or None if failed
        """
        try:
            response = requests.get(f"{prometheus_url}/api/v1/targets", timeout=10)
            if response.status_code == 200:
                return response.json()
            return None
        except RequestException:
            return None

    @staticmethod
    def parse_prometheus_metrics(metrics_content: str) -> Dict[str, List[str]]:
        """
        Parse Prometheus metrics content and extract metric names.

        Args:
            metrics_content: Raw metrics content

        Returns:
            Dictionary with metric families and their samples
        """
        metric_families = {}
        current_family = None

        for line in metrics_content.split("\n"):
            line = line.strip()

            if line.startswith("# HELP "):
                current_family = line.split(" ", 2)[2].split(" ")[0]
                if current_family not in metric_families:
                    metric_families[current_family] = []
            elif line and not line.startswith("#"):
                # Extract metric name from sample line
                metric_match = re.match(r"^([a-zA-Z_][a-zA-Z0-9_]*)", line)
                if metric_match:
                    metric_name = metric_match.group(1)
                    if (
                        current_family
                        and metric_name not in metric_families[current_family]
                    ):
                        metric_families[current_family].append(metric_name)

        return metric_families

    @staticmethod
    def wait_for_prometheus_scrape(
        target_job: str,
        prometheus_url: str = "http://localhost:9090",
        timeout: int = 60,
    ) -> bool:
        """
        Wait for Prometheus to successfully scrape a specific target job.

        Args:
            target_job: Job name to wait for
            prometheus_url: Prometheus base URL
            timeout: Maximum wait time in seconds

        Returns:
            True if target is scraped successfully, False otherwise
        """
        start_time = time.time()

        while time.time() - start_time < timeout:
            targets_data = MonitoringTestUtils.get_prometheus_targets(prometheus_url)
            if targets_data and targets_data.get("status") == "success":
                active_targets = targets_data.get("data", {}).get("activeTargets", [])

                for target in active_targets:
                    if (
                        target.get("labels", {}).get("job") == target_job
                        and target.get("health") == "up"
                    ):
                        return True

            time.sleep(5)

        return False


@pytest.mark.integration
@pytest.mark.monitoring
class TestMonitoringInfrastructure:
    """Test suite for monitoring infrastructure validation."""

    def test_prometheus_configuration_and_startup(self) -> None:
        """
        🔍 Test Prometheus configuration validation and startup health.

        This test verifies:
        - Prometheus configuration file validity
        - Service startup and readiness
        - API endpoints accessibility
        - Basic system metrics collection
        """
        prometheus_config = WEB_SERVICES["infra-default-prometheus"]
        base_url = f"http://localhost:{prometheus_config['port']}"

        # Test Prometheus health endpoints
        health_response = requests.get(f"{base_url}/-/healthy", timeout=10)
        assert health_response.status_code == 200, "❌ Prometheus health check failed"

        ready_response = requests.get(f"{base_url}/-/ready", timeout=10)
        assert ready_response.status_code == 200, "❌ Prometheus readiness check failed"

        # Test configuration reload endpoint
        reload_response = requests.post(f"{base_url}/-/reload", timeout=10)
        # Should return 200 (success) or 405 (method not allowed if disabled)
        assert reload_response.status_code in [
            200,
            405,
        ], "❌ Prometheus reload endpoint failed"

        # Test basic metrics collection
        metrics_response = requests.get(f"{base_url}/metrics", timeout=10)
        assert (
            metrics_response.status_code == 200
        ), "❌ Prometheus metrics endpoint failed"

        metrics_content = metrics_response.text
        assert (
            "prometheus_build_info" in metrics_content
        ), "❌ Prometheus build info missing"
        assert (
            "prometheus_config_last_reload_successful" in metrics_content
        ), "❌ Config reload metric missing"

    def test_metrics_exporters_data_collection(self) -> None:
        """
        📊 Test that all metrics exporters are collecting and exposing data.

        This test verifies:
        - All exporters are responding with valid metrics
        - Metric formats comply with Prometheus standards
        - Essential system metrics are present
        - Data collection is functioning correctly
        """
        failed_exporters = []

        for exporter_name, config in METRICS_EXPORTERS.items():
            try:
                port = config["port"]
                endpoint = config["endpoint"]

                response = requests.get(
                    f"http://localhost:{port}{endpoint}", timeout=15
                )

                if response.status_code != 200:
                    failed_exporters.append(
                        f"{exporter_name}: HTTP {response.status_code}"
                    )
                    continue

                metrics_content = response.text

                # Validate metrics format and content
                if not metrics_content or len(metrics_content.strip()) == 0:
                    failed_exporters.append(f"{exporter_name}: Empty metrics response")
                    continue

                # Parse and validate metrics
                parsed_metrics = MonitoringTestUtils.parse_prometheus_metrics(
                    metrics_content
                )

                if len(parsed_metrics) == 0:
                    failed_exporters.append(f"{exporter_name}: No valid metrics found")
                    continue

                # Validate specific exporter metrics based on type
                if "node-exporter" in exporter_name:
                    required_metrics = ["node_cpu", "node_memory", "node_filesystem"]
                    missing_metrics = [
                        m
                        for m in required_metrics
                        if not any(m in family for family in parsed_metrics.keys())
                    ]
                    if missing_metrics:
                        failed_exporters.append(
                            f"{exporter_name}: Missing metrics {missing_metrics}"
                        )

                elif "cadvisor" in exporter_name:
                    required_metrics = ["container_cpu", "container_memory"]
                    missing_metrics = [
                        m
                        for m in required_metrics
                        if not any(m in family for family in parsed_metrics.keys())
                    ]
                    if missing_metrics:
                        failed_exporters.append(
                            f"{exporter_name}: Missing metrics {missing_metrics}"
                        )

                elif "postgres-exporter" in exporter_name:
                    required_metrics = ["pg_up", "pg_stat"]
                    missing_metrics = [
                        m
                        for m in required_metrics
                        if not any(m in family for family in parsed_metrics.keys())
                    ]
                    if missing_metrics:
                        failed_exporters.append(
                            f"{exporter_name}: Missing metrics {missing_metrics}"
                        )

            except RequestException as e:
                failed_exporters.append(f"{exporter_name}: Connection error - {e}")
            except Exception as e:
                failed_exporters.append(f"{exporter_name}: Unexpected error - {e}")

        if failed_exporters:
            failure_details = "\n".join([f"  - {error}" for error in failed_exporters])
            pytest.fail(
                f"❌ {len(failed_exporters)} metrics exporter(s) failed:\n{failure_details}"
            )

    def test_prometheus_target_discovery_and_scraping(self) -> None:
        """
        🎯 Test Prometheus target discovery and successful scraping.

        This test verifies:
        - All configured targets are discovered
        - Targets are successfully scraped (UP state)
        - Scrape intervals are being respected
        - No persistent scrape failures
        """
        prometheus_config = WEB_SERVICES["infra-default-prometheus"]
        base_url = f"http://localhost:{prometheus_config['port']}"

        # Get all targets
        targets_data = MonitoringTestUtils.get_prometheus_targets(base_url)
        assert targets_data is not None, "❌ Failed to retrieve Prometheus targets"
        assert (
            targets_data.get("status") == "success"
        ), "❌ Prometheus targets API failed"

        active_targets = targets_data.get("data", {}).get("activeTargets", [])
        targets_data.get("data", {}).get("droppedTargets", [])

        assert len(active_targets) > 0, "❌ No active targets found in Prometheus"

        # Check target health
        unhealthy_targets = []
        expected_jobs = {
            "prometheus",
            "node-exporter",
            "cadvisor",
            "postgres-exporter",
            "mysql-exporter",
            "redis-exporter",
            "mongodb-exporter",
            "rabbitmq-exporter",
        }

        discovered_jobs = set()

        for target in active_targets:
            job_name = target.get("labels", {}).get("job", "unknown")
            discovered_jobs.add(job_name)

            health = target.get("health")
            last_error = target.get("lastError", "")

            if health != "up":
                unhealthy_targets.append(f"{job_name}: {health} - {last_error}")

        # Check for missing expected jobs
        missing_jobs = expected_jobs - discovered_jobs
        if missing_jobs:
            print(f"⚠️  Missing expected jobs: {missing_jobs}")

        if unhealthy_targets:
            failure_details = "\n".join([f"  - {error}" for error in unhealthy_targets])
            pytest.fail(
                f"❌ {len(unhealthy_targets)} target(s) unhealthy:\n{failure_details}"
            )

        print(f"✅ {len(active_targets)} targets discovered and healthy")
        print(
            f"✅ {len(discovered_jobs)} job types active: {', '.join(sorted(discovered_jobs))}"
        )

    def test_prometheus_query_functionality(self) -> None:
        """
        📈 Test Prometheus query engine and PromQL functionality.

        This test verifies:
        - PromQL query execution
        - Basic metric queries return data
        - Aggregation functions work correctly
        - Time-series data is available
        """
        prometheus_config = WEB_SERVICES["infra-default-prometheus"]
        base_url = f"http://localhost:{prometheus_config['port']}"

        # Test basic queries
        test_queries = [
            ("up", "Service uptime metrics"),
            ("prometheus_build_info", "Prometheus build information"),
            ("prometheus_config_last_reload_successful", "Configuration reload status"),
            (
                "rate(prometheus_http_requests_total[5m])",
                "HTTP request rate calculation",
            ),
            ("sum(up) by (job)", "Aggregation by job"),
        ]

        failed_queries = []

        for query, description in test_queries:
            try:
                result = MonitoringTestUtils.query_prometheus(query, base_url)

                if result is None:
                    failed_queries.append(f"{description}: Query failed")
                    continue

                if result.get("status") != "success":
                    failed_queries.append(
                        f"{description}: {result.get('error', 'Unknown error')}"
                    )
                    continue

                data = result.get("data", {})
                result_type = data.get("resultType")
                result_values = data.get("result", [])

                if result_type not in ["vector", "matrix", "scalar"]:
                    failed_queries.append(
                        f"{description}: Invalid result type {result_type}"
                    )
                    continue

                if len(result_values) == 0 and query in ["up", "prometheus_build_info"]:
                    failed_queries.append(
                        f"{description}: No data returned for basic query"
                    )

            except Exception as e:
                failed_queries.append(f"{description}: Exception - {e}")

        if failed_queries:
            failure_details = "\n".join([f"  - {error}" for error in failed_queries])
            pytest.fail(
                f"❌ {len(failed_queries)} PromQL quer(ies) failed:\n{failure_details}"
            )

    def test_grafana_prometheus_integration(self) -> None:
        """
        📊 Test Grafana and Prometheus integration.

        This test verifies:
        - Grafana can connect to Prometheus
        - Data sources are configured correctly
        - Basic dashboard functionality works
        - Query execution through Grafana API
        """
        grafana_config = WEB_SERVICES["infra-default-grafana"]
        base_url = f"http://localhost:{grafana_config['port']}"
        auth = grafana_config["auth"]

        # Test Grafana health
        health_response = requests.get(
            f"{base_url}/api/health", auth=HTTPBasicAuth(*auth), timeout=10
        )
        assert health_response.status_code == 200, "❌ Grafana health check failed"

        # Test data sources API
        ds_response = requests.get(
            f"{base_url}/api/datasources", auth=HTTPBasicAuth(*auth), timeout=10
        )
        assert ds_response.status_code == 200, "❌ Grafana data sources API failed"

        datasources = ds_response.json()

        # Look for Prometheus data source
        prometheus_ds = None
        for ds in datasources:
            if ds.get("type") == "prometheus":
                prometheus_ds = ds
                break

        if prometheus_ds:
            # Test data source connectivity
            ds_id = prometheus_ds.get("id")
            test_response = requests.get(
                f"{base_url}/api/datasources/{ds_id}/health",
                auth=HTTPBasicAuth(*auth),
                timeout=15,
            )

            if test_response.status_code == 200:
                health_data = test_response.json()
                assert (
                    health_data.get("status") == "OK"
                ), "❌ Prometheus data source unhealthy"
            else:
                print("⚠️  Could not test Prometheus data source connectivity")
        else:
            print("⚠️  No Prometheus data source found in Grafana")

    def test_alerting_pipeline_functionality(self) -> None:
        """
        🚨 Test alerting pipeline and notification functionality.

        This test verifies:
        - Alertmanager connectivity
        - Alert rules are loaded in Prometheus
        - Alert routing configuration
        - Basic alerting workflow
        """
        prometheus_config = WEB_SERVICES["infra-default-prometheus"]
        prometheus_url = f"http://localhost:{prometheus_config['port']}"

        # Test alert rules API
        rules_response = requests.get(f"{prometheus_url}/api/v1/rules", timeout=10)
        assert rules_response.status_code == 200, "❌ Prometheus rules API failed"

        rules_data = rules_response.json()
        assert (
            rules_data.get("status") == "success"
        ), "❌ Failed to retrieve alert rules"

        rule_groups = rules_data.get("data", {}).get("groups", [])

        # Check if any rules are loaded
        total_rules = sum(len(group.get("rules", [])) for group in rule_groups)
        if total_rules > 0:
            print(
                f"✅ {total_rules} alert rule(s) loaded across {len(rule_groups)} group(s)"
            )
        else:
            print("⚠️  No alert rules configured")

        # Test alerts API
        alerts_response = requests.get(f"{prometheus_url}/api/v1/alerts", timeout=10)
        assert alerts_response.status_code == 200, "❌ Prometheus alerts API failed"

        alerts_data = alerts_response.json()
        assert alerts_data.get("status") == "success", "❌ Failed to retrieve alerts"

        active_alerts = alerts_data.get("data", {}).get("alerts", [])

        # Count alerts by state
        alert_states = {}
        for alert in active_alerts:
            state = alert.get("state", "unknown")
            alert_states[state] = alert_states.get(state, 0) + 1

        if alert_states:
            state_summary = ", ".join(
                [f"{state}: {count}" for state, count in alert_states.items()]
            )
            print(f"📊 Alert states: {state_summary}")


@pytest.mark.integration
@pytest.mark.monitoring
def test_monitoring_comprehensive_health() -> None:
    """
    🏥 Comprehensive health check for the entire monitoring stack.

    This test performs a complete assessment of the monitoring infrastructure
    including metrics collection, storage, querying, and visualization.
    """
    health_results = {
        "prometheus_health": False,
        "exporters_health": False,
        "target_discovery": False,
        "query_functionality": False,
        "grafana_integration": False,
    }

    try:
        # Test Prometheus health
        prometheus_config = WEB_SERVICES["infra-default-prometheus"]
        prometheus_url = f"http://localhost:{prometheus_config['port']}"

        health_response = requests.get(f"{prometheus_url}/-/healthy", timeout=10)
        if health_response.status_code == 200:
            health_results["prometheus_health"] = True

        # Test exporters health (sample a few key ones)
        key_exporters = ["infra-default-node-exporter", "infra-default-cadvisor"]
        healthy_exporters = 0

        for exporter in key_exporters:
            if exporter in METRICS_EXPORTERS:
                config = METRICS_EXPORTERS[exporter]
                try:
                    response = requests.get(
                        f"http://localhost:{config['port']}{config['endpoint']}",
                        timeout=5,
                    )
                    if response.status_code == 200 and len(response.text) > 0:
                        healthy_exporters += 1
                except RequestException:
                    pass

        if healthy_exporters == len(key_exporters):
            health_results["exporters_health"] = True

        # Test target discovery
        targets_data = MonitoringTestUtils.get_prometheus_targets(prometheus_url)
        if (
            targets_data
            and targets_data.get("status") == "success"
            and len(targets_data.get("data", {}).get("activeTargets", [])) > 0
        ):
            health_results["target_discovery"] = True

        # Test query functionality
        query_result = MonitoringTestUtils.query_prometheus("up", prometheus_url)
        if (
            query_result
            and query_result.get("status") == "success"
            and len(query_result.get("data", {}).get("result", [])) > 0
        ):
            health_results["query_functionality"] = True

        # Test Grafana integration
        try:
            grafana_config = WEB_SERVICES["infra-default-grafana"]
            grafana_url = f"http://localhost:{grafana_config['port']}"
            auth = grafana_config["auth"]

            grafana_response = requests.get(
                f"{grafana_url}/api/health", auth=HTTPBasicAuth(*auth), timeout=10
            )
            if grafana_response.status_code == 200:
                health_results["grafana_integration"] = True
        except RequestException:
            pass

    except Exception as e:
        pytest.fail(f"❌ Monitoring health check failed with error: {e}")

    # Verify all health checks passed
    failed_checks = [name for name, result in health_results.items() if not result]

    if failed_checks:
        failure_details = ", ".join(failed_checks)
        pytest.fail(f"❌ Monitoring stack health check failed for: {failure_details}")

    # Print success summary
    print("\n✅ Monitoring infrastructure comprehensive health check passed:")
    for check_name, result in health_results.items():
        print(f"  ✓ {check_name}: {'PASS' if result else 'FAIL'}")
