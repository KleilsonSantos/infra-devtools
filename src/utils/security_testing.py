"""
Security and authentication testing utilities for infrastructure services.

This module provides comprehensive testing for security-related services
like Keycloak, Vault, and other authentication/authorization components.
"""

import os
from typing import Any, Dict

import requests
from dotenv import load_dotenv  # type: ignore[import-untyped]

load_dotenv()

# Security service timeouts and retries
DEFAULT_TIMEOUT = 30
DEFAULT_RETRIES = 3
RETRY_DELAY = 2


class SecurityTestError(Exception):
    """Custom exception for security testing failures."""


def test_keycloak_functionality(
    host: str = "localhost", port: int = 8099, timeout: int = DEFAULT_TIMEOUT
) -> Dict[str, Any]:
    """
    Test Keycloak authentication server functionality.

    Args:
        host: Keycloak host
        port: Keycloak port
        timeout: Request timeout in seconds

    Returns:
        Dictionary with test results

    Raises:
        SecurityTestError: If critical tests fail
    """
    results = {
        "server_info": False,
        "realms_accessible": False,
        "admin_console": False,
        "health_check": False,
    }

    base_url = f"http://{host}:{port}"

    try:
        # Test server info endpoint
        response = requests.get(
            f"{base_url}/auth/realms/master/.well-known/openid_configuration",
            timeout=timeout,
        )
        if response.status_code == 200:
            server_info = response.json()
            if "issuer" in server_info and "authorization_endpoint" in server_info:
                results["server_info"] = True

        # Test realms endpoint accessibility
        response = requests.get(f"{base_url}/auth/realms/master", timeout=timeout)
        if response.status_code == 200:
            results["realms_accessible"] = True

        # Test admin console accessibility
        response = requests.get(f"{base_url}/auth/admin/", timeout=timeout)
        if response.status_code in [200, 401, 403]:  # Redirects or auth required
            results["admin_console"] = True

        # Test health endpoint
        response = requests.get(f"{base_url}/health", timeout=timeout)
        if response.status_code == 200:
            results["health_check"] = True

    except requests.RequestException as e:
        raise SecurityTestError(f"Keycloak connectivity test failed: {e}")

    return results


def test_vault_functionality(
    host: str = "localhost", port: int = 8200, timeout: int = DEFAULT_TIMEOUT
) -> Dict[str, Any]:
    """
    Test HashiCorp Vault functionality.

    Args:
        host: Vault host
        port: Vault port
        timeout: Request timeout in seconds

    Returns:
        Dictionary with test results

    Raises:
        SecurityTestError: If critical tests fail
    """
    results = {
        "server_status": False,
        "health_check": False,
        "sys_health": False,
        "seal_status": False,
    }

    base_url = f"http://{host}:{port}"
    vault_token = os.getenv("VAULT_DEV_ROOT_TOKEN_ID")
    headers = {"X-Vault-Token": vault_token} if vault_token else {}

    try:
        # Test basic server connectivity
        response = requests.get(f"{base_url}/v1/sys/health", timeout=timeout)
        if response.status_code in [200, 429, 472, 473]:  # Various vault states
            results["server_status"] = True
            health_data = response.json()

            # Check if vault is initialized and unsealed
            if not health_data.get("sealed", True):
                results["health_check"] = True

            if health_data.get("initialized", False):
                results["sys_health"] = True

        # Test seal status endpoint
        response = requests.get(f"{base_url}/v1/sys/seal-status", timeout=timeout)
        if response.status_code == 200:
            results["seal_status"] = True

        # If we have a token, test authenticated endpoint
        if vault_token:
            response = requests.get(
                f"{base_url}/v1/sys/mounts", headers=headers, timeout=timeout
            )
            if response.status_code == 200:
                results["authenticated_access"] = True

    except requests.RequestException as e:
        raise SecurityTestError(f"Vault connectivity test failed: {e}")

    return results


def test_sonarqube_security(
    host: str = "localhost", port: int = 9000, timeout: int = DEFAULT_TIMEOUT
) -> Dict[str, Any]:
    """
    Test SonarQube security configuration and accessibility.

    Args:
        host: SonarQube host
        port: SonarQube port
        timeout: Request timeout in seconds

    Returns:
        Dictionary with test results

    Raises:
        SecurityTestError: If critical tests fail
    """
    results = {
        "system_status": False,
        "authentication": False,
        "web_api": False,
        "security_config": False,
    }

    base_url = f"http://{host}:{port}"

    try:
        # Test system status
        response = requests.get(f"{base_url}/api/system/status", timeout=timeout)
        if response.status_code == 200:
            status_data = response.json()
            if status_data.get("status") == "UP":
                results["system_status"] = True

        # Test authentication endpoint
        response = requests.get(
            f"{base_url}/api/authentication/validate", timeout=timeout
        )
        if response.status_code in [200, 401]:  # Endpoint accessible
            results["authentication"] = True

        # Test web API accessibility
        response = requests.get(f"{base_url}/api/webservices/list", timeout=timeout)
        if response.status_code == 200:
            results["web_api"] = True

        # Test security-related API
        response = requests.get(
            f"{base_url}/api/permissions/search_templates", timeout=timeout
        )
        if response.status_code in [200, 401, 403]:  # Accessible but may require auth
            results["security_config"] = True

    except requests.RequestException as e:
        raise SecurityTestError(f"SonarQube security test failed: {e}")

    return results


def test_mailhog_functionality(
    host: str = "localhost", port: int = 8025, timeout: int = DEFAULT_TIMEOUT
) -> Dict[str, Any]:
    """
    Test MailHog email capture functionality.

    Args:
        host: MailHog host
        port: MailHog port
        timeout: Request timeout in seconds

    Returns:
        Dictionary with test results
    """
    results = {
        "web_interface": False,
        "api_accessible": False,
        "messages_endpoint": False,
        "smtp_info": False,
    }

    base_url = f"http://{host}:{port}"

    try:
        # Test web interface
        response = requests.get(base_url, timeout=timeout)
        if response.status_code == 200:
            results["web_interface"] = True

        # Test API accessibility
        response = requests.get(f"{base_url}/api/v1/messages", timeout=timeout)
        if response.status_code == 200:
            results["api_accessible"] = True
            results["messages_endpoint"] = True

        # Test API info endpoint
        response = requests.get(f"{base_url}/api/v2/info", timeout=timeout)
        if response.status_code == 200:
            results["smtp_info"] = True

    except requests.RequestException as e:
        raise SecurityTestError(f"MailHog functionality test failed: {e}")

    return results


def test_alertmanager_functionality(
    host: str = "localhost", port: int = 9093, timeout: int = DEFAULT_TIMEOUT
) -> Dict[str, Any]:
    """
    Test Prometheus Alertmanager functionality.

    Args:
        host: Alertmanager host
        port: Alertmanager port
        timeout: Request timeout in seconds

    Returns:
        Dictionary with test results
    """
    results = {
        "status_check": False,
        "config_check": False,
        "alerts_endpoint": False,
        "silences_endpoint": False,
    }

    base_url = f"http://{host}:{port}"

    try:
        # Test status endpoint
        response = requests.get(f"{base_url}/-/healthy", timeout=timeout)
        if response.status_code == 200:
            results["status_check"] = True

        # Test configuration status
        response = requests.get(f"{base_url}/api/v1/status", timeout=timeout)
        if response.status_code == 200:
            results["config_check"] = True

        # Test alerts API
        response = requests.get(f"{base_url}/api/v1/alerts", timeout=timeout)
        if response.status_code == 200:
            results["alerts_endpoint"] = True

        # Test silences API
        response = requests.get(f"{base_url}/api/v1/silences", timeout=timeout)
        if response.status_code == 200:
            results["silences_endpoint"] = True

    except requests.RequestException as e:
        raise SecurityTestError(f"Alertmanager functionality test failed: {e}")

    return results


def test_webhook_listener_functionality(
    host: str = "localhost", port: int = 5001, timeout: int = DEFAULT_TIMEOUT
) -> Dict[str, Any]:
    """
    Test custom webhook listener functionality.

    Args:
        host: Webhook listener host
        port: Webhook listener port
        timeout: Request timeout in seconds

    Returns:
        Dictionary with test results
    """
    results = {
        "server_accessible": False,
        "webhook_endpoint": False,
        "health_check": False,
    }

    base_url = f"http://{host}:{port}"

    try:
        # Test basic server accessibility
        response = requests.get(base_url, timeout=timeout)
        if response.status_code in [200, 404, 405]:  # Server responding
            results["server_accessible"] = True

        # Test webhook endpoint (POST method)
        response = requests.post(
            f"{base_url}/webhook",
            json={"test": "connectivity"},
            timeout=timeout,
        )
        if response.status_code in [200, 400, 422]:  # Endpoint exists
            results["webhook_endpoint"] = True

        # Test health endpoint if available
        response = requests.get(f"{base_url}/health", timeout=timeout)
        if response.status_code == 200:
            results["health_check"] = True

    except requests.RequestException as e:
        raise SecurityTestError(f"Webhook listener test failed: {e}")

    return results


def comprehensive_security_test() -> Dict[str, Dict[str, Any]]:
    """
    Run comprehensive security tests on all security-related services.

    Returns:
        Dictionary mapping service names to their test results
    """
    security_services = {
        "keycloak": lambda: test_keycloak_functionality(),
        "vault": lambda: test_vault_functionality(),
        "sonarqube": lambda: test_sonarqube_security(),
        "mailhog": lambda: test_mailhog_functionality(),
        "alertmanager": lambda: test_alertmanager_functionality(),
        "webhook-listener": lambda: test_webhook_listener_functionality(),
    }

    results = {}

    for service_name, test_func in security_services.items():
        try:
            results[service_name] = test_func()
            results[service_name]["overall_status"] = "PASS"
        except Exception as e:
            results[service_name] = {
                "overall_status": "FAIL",
                "error": str(e),
            }

    return results
