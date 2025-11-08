"""Constants used across the application."""

# Container names
CONTAINERS = [
    "infra-default-mongo",
    "infra-default-postgres",
    "infra-default-mysql",
    "infra-default-redis",
    "infra-default-prometheus",
    "infra-default-grafana",
]

# Database service configurations
DATABASE_SERVICES = {
    "infra-default-postgres": {
        "host": "localhost",
        "port": 5432,
        "database": "testdb",
        "username": "testuser",
        "password": "testpass",
        "type": "postgresql",
    },
    "infra-default-mysql": {
        "host": "localhost",
        "port": 3306,
        "database": "testdb",
        "username": "testuser",
        "password": "testpass",
        "type": "mysql",
    },
    "infra-default-mongo": {
        "host": "localhost",
        "port": 27017,
        "database": "testdb",
        "type": "mongodb",
    },
    "infra-default-redis": {
        "host": "localhost",
        "port": 6379,
        "db": 0,
        "type": "redis",
    },
}

# Web service configurations
WEB_SERVICES = {
    "infra-default-grafana": {
        "host": "localhost",
        "port": 3000,
        "url": "http://localhost:3000",
        "username": "admin",
        "password": "admin",
    },
    "infra-default-prometheus": {
        "host": "localhost",
        "port": 9090,
        "url": "http://localhost:9090",
    },
}

# Metrics exporter configurations
METRICS_EXPORTERS = {
    "node-exporter": {"port": 9100, "url": "http://localhost:9100/metrics"},
    "cadvisor": {"port": 8080, "url": "http://localhost:8080/metrics"},
}

# Security service configurations
SECURITY_SERVICES = {
    "vault": {"host": "localhost", "port": 8200, "url": "http://localhost:8200"},
    "keycloak": {"host": "localhost", "port": 8080, "url": "http://localhost:8080"},
}

ESSENTIAL_SERVICES = CONTAINERS
