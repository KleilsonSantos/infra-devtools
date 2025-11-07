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

# 📦 Python Environment Configuration
PYTHON := .venv/bin/python3
PIP := .venv/bin/pip3
VENV_BIN = .venv/bin

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

# 🛡️ OWASP Dependency Check
CHECK_DEPS = scripts/run-dependency-check.sh

# 📦 Common Targets
.PHONY: up down force-recreate logs ps ps-format ps-detailed rebuild \
        clean check-deps coverage test lint format sonar-scanner \
        test-unit test-integration test-volumes test-docker test-all

# 🛠️ Setup Python Environment
setup:
	@echo "🔧 Setting up environment..." && \
	python3 -m venv .venv && \
	make install

# 📦 Install Python dependencies
install:
	@echo "📦 Installing dependencies..." && \
	$(PIP) install --upgrade pip && \
	$(PIP) install black defusedxml types-defusedxml types-psycopg2 isort flake8 mypy bandit pydocstyle pylint pytest pytest-cov pytest-html testcontainers psycopg2-binary python-dotenv requests pytest-mock testinfra

## 🚀 Start all containers
up:
	@echo "🔼 Starting containers..."
	$(DC_UP) $(SERVICES)

## 🚀 Start a specific service: make up-service service=name
up-service:
	@echo "🔼 Starting container $(service)..."
	$(DC_UP) $(service)

## ⛔ Stop a specific service
down-service:
	@echo "🔽 Stopping container $(service)..."
	$(DC_DOWN) $(service)

## ⛔ Stop all containers (preserve volumes)
down:
	@echo "🔽 Stopping containers..."
	$(DC_DOWN)

## ♻️ Force recreate all containers
force-recreate:
	@echo "♻️ Recreating containers..."
	$(DC_DOWN) && $(DC_UP) $(SERVICES)

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

## 🧪 Run only unit tests
test-unit:
	@echo "🧪 Running unit tests..."
	$(PYTHON) -m pytest -m "unit" $(JUNIT_REPORT)

## 🔗 Run only integration tests
test-integration:
	@echo "🔗 Running integration tests..."
	$(PYTHON) -m pytest -m "integration" $(JUNIT_REPORT)

## 💾 Run only volume-related tests
test-volumes:
	@echo "💾 Running volume tests..."
	$(PYTHON) -m pytest -m "volumes" $(JUNIT_REPORT)

## 🐳 Run only docker/network related tests
test-docker:
	@echo "🐳 Running docker/network tests..."
	$(PYTHON) -m pytest -m "docker or network" $(JUNIT_REPORT)

## 🧪 Run all tests without coverage
test-all:
	@echo "🧪 Running all tests..."
	$(PYTHON) -m pytest $(JUNIT_REPORT)

## 🖌️ Format code using Prettier
format-black:
	@echo "🖌️ Formatting Python code with Black..."
	$(PYTHON) -m black src/

# 🔍 Check code formatting with Black
check-black:
	@echo "🔍 Checking Python code formatting with Black..."
	$(VENV_BIN)/black src/ --check

# 🖌️ Format code using Prettier
format-isort:
	@echo "🖌️ Formatting imports with isort..."
	$(VENV_BIN)/isort src/

# 🔍 Check import order with isort
check-isort:
	@echo "🔍 Checking import order with isort..."
	$(VENV_BIN)/isort src/ --check-only

# 🔍 Run flake8 for critical errors
lint-flake8-critical:
	@echo "🔍 Running flake8 (critical errors)..."
	$(VENV_BIN)/flake8 . --exclude=.venv --count --select=E9,F63,F7,F82 --show-source --statistics

# 🔍 Run flake8 for style and complexity checks
lint-flake8-style:
	@echo "🔍 Running flake8 (style and complexity)..."
	$(VENV_BIN)/flake8 . --exclude=.venv --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics

# 🔍 Run mypy 
lint-mypy:
	@echo "🔍 Running mypy type checking..."
	$(VENV_BIN)/mypy src/ --config-file mypy.ini

# 🔍 Run bandit for security analysis
lint-bandit:
	@echo "🔍 Running bandit security analysis..."
	$(VENV_BIN)/bandit -r src/ -ll --ini .bandit

# 🔍 Run pydocstyle for docstring checks
lint-pydocstyle:
	@echo "🔍 Checking docstrings with pydocstyle..."
	$(VENV_BIN)/pydocstyle src/

# 🔍 Run pylint for code quality
lint-pylint:
	@echo "🔍 Running pylint code quality check..."
	$(VENV_BIN)/pylint src/ --rcfile=.pylintrc
#	$(PYTHON) -m pylint src/

## 📊 Run test 
lint-python: format-black \
format-isort \
check-black \
check-isort \
lint-flake8-critical \
lint-flake8-style \
lint-mypy \
lint-bandit \
lint-pydocstyle \
lint-pylint
	@echo "✅ All Python lint checks passed."


## 🔍 Run OWASP Dependency Check
check-deps:
	@echo "🔍 Checking for dependency vulnerabilities..."
	$(CHECK_DEPS)

## 🧹 Clean environment
clean:
	@echo "🧹 Limpando arquivos temporários..." && \
	rm -rf .venv __pycache__ .pytest_cache .mypy_cache dist build src/reports
	@echo "🧹 Limpeza concluída."

## 🔍 Run SonarQube scanner
sonar-scanner:
	@echo "🔎 Running SonarQube analysis..."
	$(SONAR_SCANNER) \
		-Dsonar.projectKey=$(SONAR_PROJECT_KEY) \
		-Dsonar.sources=. \
		-Dsonar.host.url=${SONAR_HOST_URL} \
		-Dsonar.token=${SONAR_TOKEN_INFRA_DEVTOOLS} \
		-Dsonar.sourceEncoding=UTF-8
