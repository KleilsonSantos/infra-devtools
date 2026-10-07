# -------------------------------------------------------------
# 🐳 Infrastructure DevTools - Makefile
# 👨‍💻 Author: Kleilson Santos
# 📅 Last Updated: 2025-06-19
#
# 📦 Integrated Services:
#   🔍 Monitoring:        → Prometheus, Node Exporter, cAdvisor
#   🧮 Databases:         → MongoDB, PostgreSQL, Redis, MySQL
#   🛠️ Dev Tools:         → Portainer, RedisInsight, phpMyAdmin, pgAdmin
#   🧹 Code Quality:      → SonarQube, ESLint, Prettier, OWASP Dependency-Check
#
# 🎯 Available Targets:
#   ┌───────────── Container Management ─────────────┐
#   │ up               → Start all containers         │
#   │ down             → Stop containers (keep data)  │
#   │ force-recreate   → Recreate all containers      │
#   │ up-service       → Start specific container     │
#   │ down-service     → Stop specific container      │
#   │ logs             → Show container logs          │
#   │ ps / ps-format   → List containers (detailed)   │
#   └────────────────────────────────────────────────┘
#   ┌───────────── Testing & Linting ────────────────┐
#   │ test-all          → Run all tests              │
#   │ test-unit         → Run unit tests             │
#   │ test-integration  → Run integration tests      │
#   │ test-docker       → Run docker/network tests   │
#   │ test-volumes      → Run volume-related tests   │
#   │ coverage          → Run tests with coverage    │
#   │ lint / format     → Run ESLint / Prettier      │
#   └────────────────────────────────────────────────┘
#   🔍 check-deps        → Run OWASP Dependency Check
#   🔍 sonar-scanner     → Run SonarQube static analysis
#   🧹 clean             → Clean generated reports
# -------------------------------------------------------------

# 🌍 Environment Configuration
MODULE = src
ENV_FILE = .env
include $(ENV_FILE)

# 🔍 SonarQube Configuration
SONAR_SCANNER = npx sonar-scanner
SONAR_PROJECT_KEY = infra-devtools

# 🐳 Docker Compose Service List
SERVICES = \
  mongo \
  mongo-express \
  postgres \
  pgadmin \
  mysql \
  phpmyadmin \
  redis \
  redisinsight \
  rabbitmq \
  rabbitmq-exporter \
  prometheus \
  grafana \
  alertmanager \
  blackbox-exporter \
  cadvisor \
  node-exporter \
  postgres-exporter \
  mysql-exporter \
  mongodb-exporter \
  redis-exporter \
  sonarqube \
  portainer \
  vault \
  mailhog \
  keycloak \
  eureka-server \
  users-api \
  webhook-listener

# 📁 Directory Paths
REPORTS_DIR = $(MODULE)/reports

# 🐳 Docker Compose Shortcuts
DC = docker compose --env-file $(ENV_FILE)
DC_UP = $(DC) up -d
DC_DOWN = $(DC) down --volumes=false --remove-orphans
DC_BUILD = $(DC) build
DC_EXEC = $(DC) exec
DC_PULL = $(DC) pull
DC_RUN = $(DC) run --rm
DC_LOGS = $(DC) logs -f
DC_PS = $(DC) ps
DC_PS_FORMAT = $(DC) ps --format 'table {{.Names}}'
DC_PS_DETAILED = $(DC) ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# 🧪 Test Configuration
PYTEST = python3 -m pytest
COV_REPORT = --cov-report xml:$(REPORTS_DIR)/coverage/coverage.xml --cov-report html:$(REPORTS_DIR)/coverage
JUNIT_REPORT = --junitxml=$(REPORTS_DIR)/coverage/test-results.xml

# 🎨 Linting & Formatting
LINT = npx eslint --ext .ts,.js --fix
FORMAT = npx prettier --write "src/**/*.{ts,js,json,md,py}" --ignore-path .prettierignore --ignore-unknown
FORMAT_BLACK= black src/
FORMAT_ISORT = isort src/
# 🛡️ OWASP Dependency Check
CHECK_DEPS = scripts/run-dependency-check.sh

# 📦 Common Targets
.PHONY: up down force-recreate logs ps ps-format ps-detailed rebuild \
        clean check-deps coverage test lint format sonar-scanner \
        test-unit test-integration test-volumes test-docker test-all \
        check-ports check-ports-start check-compose-ports

## 🔍 Fail-closed: foreign / wrong owners on infra ports
check-ports:
	@bash scripts/check-port-conflicts.sh --mode test

## 🔍 Fail-closed: compose.yml must not map the same HOST port to two services
check-compose-ports:
	@bash scripts/check-port-conflicts.sh --mode catalog

## 🔍 Fail-closed before compose up
check-ports-start:
	@bash scripts/check-port-conflicts.sh --mode start --policy $${E2E_PORT_POLICY:-abort}

## 🚀 Start all containers (serial: preflight→up→verify per service)
up: check-compose-ports
	@echo "🔼 Starting containers serially (port gate per service)..."
	@bash scripts/compose-up-serial.sh $(SERVICES)

## 🚀 Start a specific service: make up-service service=name
up-service:
	@echo "🔼 Starting container $(service) (preflight→up→verify)..."
	@bash scripts/compose-up-serial.sh $(service)

## ⛔ Stop a specific service
down-service:
	@echo "🔽 Stopping container $(service)..."
	$(DC_DOWN) $(service)

## ⛔ Stop all containers (preserve volumes)
down:
	@echo "🔽 Stopping containers..."
	$(DC_DOWN)

## ♻️ Force recreate all containers (serial)
force-recreate:
	@echo "♻️ Recreating containers serially..."
	$(DC_DOWN)
	@bash scripts/compose-up-serial.sh $(SERVICES)

## 📋 Show logs of a specific container: make logs service=name
logs:
	@echo "📋 Showing logs for service $(service)..."
	$(DC_LOGS) $(service)

## 📜 List all containers
ps:
	@echo "📜 Listing containers..."
	$(DC_PS)

## 📜 List containers (compact format)
ps-format:
	@echo "📜 Compact list of containers..."
	$(DC_PS_FORMAT)

## 📜 List containers with details
ps-detailed:
	@echo "📜 Detailed container list..."
	$(DC_PS_DETAILED)

## 🔄 Rebuild all containers
rebuild:
	@echo "🛠️ Rebuilding containers..."
	$(DC_DOWN) && $(DC_BUILD) && $(DC_UP)

## 🧪 Run all tests with coverage report
coverage:
	@echo "🧪 Running tests with coverage..."
	$(PYTEST) --cov=$(MODULE) $(COV_REPORT) $(JUNIT_REPORT)

## 🧪 Run only unit tests
test-unit:
	@echo "🧪 Running unit tests..."
	$(PYTEST) -m "unit" $(JUNIT_REPORT)

## 🔗 Run only integration tests
test-integration: check-ports
	@echo "🔗 Running integration tests..."
	$(PYTEST) -m "integration" $(JUNIT_REPORT)

## 💾 Run only volume-related tests
test-volumes: check-ports
	@echo "💾 Running volume tests..."
	$(PYTEST) -m "volumes" $(JUNIT_REPORT)

## 🐳 Run only docker/network related tests
test-docker: check-ports
	@echo "🐳 Running docker/network tests..."
	$(PYTEST) -m "docker or network" $(JUNIT_REPORT)

## 🧪 Run all tests without coverage
test-all: check-ports
	@echo "🧪 Running all tests..."
	$(PYTEST) $(JUNIT_REPORT)

## ✨ Run ESLint
lint:
	@echo "✨ Running ESLint..."
	$(LINT)

## 🖌️ Format code using Prettier
format:
	@echo "🖌️ Formatting code..."
	$(FORMAT)

format-black:
	@echo "🖌️ Formatting Python code with Black..."
	$(FORMAT_BLACK)

format-isort:
	@echo "🖌️ Formatting imports with isort..."
	$(FORMAT_ISORT)

## 🔍 Run OWASP Dependency Check
check-deps:
	@echo "🔍 Checking for dependency vulnerabilities..."
	$(CHECK_DEPS)

## 🧹 Clean generated reports
clean:
	@echo "🧹 Cleaning reports..."
	rm -rf $(REPORTS_DIR)/*

## 🔍 Run SonarQube scanner
sonar-scanner:
	@echo "🔎 Running SonarQube analysis..."
	$(SONAR_SCANNER) \
		-Dsonar.projectKey=$(SONAR_PROJECT_KEY) \
		-Dsonar.sources=. \
		-Dsonar.host.url=${SONAR_HOST_URL} \
		-Dsonar.token=${SONAR_TOKEN_INFRA_DEVTOOLS} \
		-Dsonar.sourceEncoding=UTF-8
