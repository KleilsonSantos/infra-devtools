"""
Integration tests for security and authentication services.

This module tests Keycloak, Vault, SonarQube security features,
MailHog, Alertmanager, and Webhook Listener functionality.
"""

import pytest

from src.utils.security_testing import (
    comprehensive_security_test,
    test_alertmanager_functionality,
    test_keycloak_functionality,
    test_mailhog_functionality,
    test_sonarqube_security,
    test_vault_functionality,
    test_webhook_listener_functionality,
)


@pytest.mark.integration
@pytest.mark.security
def test_keycloak_service_functionality() -> None:
    """🔐 Test Keycloak authentication server functionality."""
    results = test_keycloak_functionality()

    assert results["server_info"], "❌ Keycloak server info endpoint not accessible"
    assert results["realms_accessible"], "❌ Keycloak realms endpoint not accessible"
    assert results["admin_console"], "❌ Keycloak admin console not accessible"

    # Health check is optional for older Keycloak versions
    if not results["health_check"]:
        print("⚠️  Keycloak health endpoint not available (might be older version)")


@pytest.mark.integration
@pytest.mark.security
def test_vault_service_functionality() -> None:
    """🔒 Test HashiCorp Vault functionality."""
    results = test_vault_functionality()

    assert results["server_status"], "❌ Vault server not accessible"
    assert results["sys_health"], "❌ Vault system health check failed"
    assert results["seal_status"], "❌ Vault seal status endpoint not accessible"

    # Health check depends on vault configuration
    if not results["health_check"]:
        print("⚠️  Vault may be sealed or not fully initialized")


@pytest.mark.integration
@pytest.mark.security
def test_sonarqube_security_features() -> None:
    """🧹 Test SonarQube security configuration and API."""
    results = test_sonarqube_security()

    assert results["system_status"], "❌ SonarQube system not running properly"
    assert results[
        "authentication"
    ], "❌ SonarQube authentication endpoint not accessible"
    assert results["web_api"], "❌ SonarQube Web API not accessible"
    assert results[
        "security_config"
    ], "❌ SonarQube security configuration endpoint failed"


@pytest.mark.integration
@pytest.mark.services
def test_mailhog_email_capture() -> None:
    """📧 Test MailHog email capture functionality."""
    results = test_mailhog_functionality()

    assert results["web_interface"], "❌ MailHog web interface not accessible"
    assert results["api_accessible"], "❌ MailHog API not accessible"
    assert results["messages_endpoint"], "❌ MailHog messages endpoint failed"

    # SMTP info is optional
    if not results["smtp_info"]:
        print("⚠️  MailHog SMTP info endpoint not available")


@pytest.mark.integration
@pytest.mark.monitoring
def test_alertmanager_monitoring() -> None:
    """🚨 Test Prometheus Alertmanager functionality."""
    results = test_alertmanager_functionality()

    assert results["status_check"], "❌ Alertmanager health check failed"
    assert results["config_check"], "❌ Alertmanager configuration check failed"
    assert results["alerts_endpoint"], "❌ Alertmanager alerts API not accessible"
    assert results["silences_endpoint"], "❌ Alertmanager silences API not accessible"


@pytest.mark.integration
@pytest.mark.services
def test_webhook_listener_service() -> None:
    """🔗 Test custom webhook listener functionality."""
    results = test_webhook_listener_functionality()

    assert results["server_accessible"], "❌ Webhook listener server not accessible"

    # Webhook endpoint test depends on implementation
    if not results["webhook_endpoint"]:
        print("⚠️  Webhook endpoint may require specific payload format")

    # Health endpoint is optional
    if not results["health_check"]:
        print("⚠️  Webhook listener health endpoint not implemented")


@pytest.mark.integration
@pytest.mark.security
@pytest.mark.comprehensive
def test_all_security_services_comprehensive() -> None:
    """🔒 Comprehensive test of all security-related services."""
    results = comprehensive_security_test()

    # Track failures for detailed reporting
    failures = []

    for service_name, service_results in results.items():
        if service_results.get("overall_status") == "FAIL":
            failures.append(
                f"{service_name}: {service_results.get('error', 'Unknown error')}"
            )
        else:
            print(f"✅ {service_name.title()} security tests passed")

    if failures:
        failure_msg = "❌ Security service failures:\n" + "\n".join(failures)
        pytest.fail(failure_msg)


@pytest.mark.integration
@pytest.mark.security
@pytest.mark.parametrize(
    "service,test_func",
    [
        ("keycloak", test_keycloak_functionality),
        ("vault", test_vault_functionality),
        ("sonarqube", test_sonarqube_security),
        ("mailhog", test_mailhog_functionality),
        ("alertmanager", test_alertmanager_functionality),
        ("webhook-listener", test_webhook_listener_functionality),
    ],
)
def test_security_service_individual(service: str, test_func) -> None:
    """🔐 Individual security service functionality test."""
    try:
        results = test_func()

        # Count successful tests
        successful_tests = sum(1 for result in results.values() if result is True)
        total_tests = len(results)
        success_rate = (successful_tests / total_tests) * 100

        print(
            f"🔍 {service.title()}: {successful_tests}/{total_tests} tests passed ({success_rate:.1f}%)"
        )

        # Ensure at least 50% of tests pass for the service to be considered functional
        assert success_rate >= 50, f"❌ {service} has less than 50% test success rate"

    except Exception as e:
        pytest.fail(f"❌ {service} security test failed: {e}")


# Security-related service health checks
@pytest.mark.integration
@pytest.mark.security
@pytest.mark.health
def test_security_services_basic_health() -> None:
    """🏥 Basic health check for all security services."""
    import requests

    security_endpoints = [
        ("Keycloak", "http://localhost:8099/health"),
        ("Vault", "http://localhost:8200/v1/sys/health"),
        ("SonarQube", "http://localhost:9000/api/system/status"),
        ("MailHog", "http://localhost:8025/api/v1/messages"),
        ("Alertmanager", "http://localhost:9093/-/healthy"),
        ("Webhook Listener", "http://localhost:5001/"),
    ]

    failures = []

    for service_name, endpoint in security_endpoints:
        try:
            response = requests.get(endpoint, timeout=10)
            if response.status_code not in [200, 401, 403, 404, 405]:
                failures.append(f"{service_name}: HTTP {response.status_code}")
            else:
                print(f"✅ {service_name} is accessible")
        except requests.RequestException as e:
            failures.append(f"{service_name}: {str(e)}")

    if failures:
        failure_msg = "❌ Security service health check failures:\n" + "\n".join(
            failures
        )
        pytest.fail(failure_msg)
