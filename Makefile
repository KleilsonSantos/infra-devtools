# -------------------------------------------
# 🐳 Infraestrutura Base - Makefile
# 🧑‍💻 Autor: Kleilson Santos
# 📅 Última atualização: 2025-05-11
#
# 📦 Serviços Integrados:
#   🔍 Monitoramento:		→ Prometheus, Node Exporter, cAdvisor
#   📊 Bancos de Dados:		→ MongoDB, PostgreSQL, Redis, MySQL
#   🛠️ DevTools:		 	 → Portainer, RedisInsight, phpMyAdmin, pgAdmin
#   🧹 Qualidade de Código: → SonarQube, ESLint, Prettier, OWASP Dependency-Check
#
# 🎯 Comandos Disponíveis (targets):
#   🔼 up				   → Inicia todos os containers listados
#   🔽 down				   → Para os containers sem remover volumes
#   ♻️ force-recreate	   → Força recriação dos containers
#   📋 logs				   → Mostra os logs do serviço especificado
#   📜 ps / ps-format	   → Lista os containers em diferentes formatos
#   📊 coverage			   → Executa testes com cobertura
#   ✨ lint / format		  → Executa ESLint e Prettier para lint e formatação
#   🔍 check-deps		   → Executa o Dependency Check
#   🧹 clean			   → Limpa a pasta de relatórios
#   🔍 sonar-scanner	   → Executa análise com SonarQube
# -------------------------------------------


# 🌍 Configurações de Ambiente
MODULE=src
ENV_FILE=.env
include $(ENV_FILE)

# 🏷️ Sonar Configuration
SONAR_SCANNER=npx sonar-scanner
SONAR_PROJECT_KEY=infra-devtools

# 🏷️ MAIN SERVICES
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

# 📁 DIRECTORIES
REPORTS_DIR = $(MODULE)/reports

# 🔍 SONARQUBE CONFIG
SONAR_SCANNER = npx sonar-scanner
SONAR_PROJECT_KEY = infra-devtools

# 🐳 DOCKER COMPOSE COMMANDS
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

# 🧪 TEST CONFIGURATION
#PYTEST = pytest
PYTEST = python3 -m pytest
COV_REPORT = --cov-report xml:$(REPORTS_DIR)/coverage/coverage.xml --cov-report html:$(REPORTS_DIR)/coverage
JUNIT_REPORT = --junitxml=$(REPORTS_DIR)/coverage/test-results.xml
CONVERTER_SCRIPT = src/utils/convert_junit_to_sonar.py

# 🎨 LINTING TOOLS
LINT = npx eslint --ext .ts,.js --fix
FORMAT = npx prettier --write "src/**/*.{ts,js,json,md,py}" --ignore-path .prettierignore --ignore-unknown


# 🔍 DEPENDENCY CHECK
CHECK_DEPS = scripts/run-dependency-check.sh

# 🎯 MAIN TARGETS
.PHONY: up down force-recreate logs ps ps-format ps-detailed rebuild \
        clean check-deps coverage test lint format sonar-scanner convert-tests

## Start all containers
up:
	@echo "🔼 Starting containers..."
	$(DC_UP) $(SERVICES)

## Start a specific container: make up-service service=name
up-service:
	@echo "🔼 Starting container $(service)..."
	$(DC_UP) $(service)

## Stop a specific service
down-service:
	@echo "🔽 Stopping container $(service)..."
	$(DC_DOWN) $(service)

## Stop all containers (keep volumes)
down:
	@echo "🔽 Stopping containers..."
	$(DC_DOWN)

## Force recreate containers
force-recreate:
	@echo "♻️ Recreating containers..."
	$(DC_DOWN) && $(DC_UP) $(SERVICES)

## Show logs for a specific service (make logs service=sonarqube)
logs:
	@echo "📋 Showing logs for service $(service)..."
	$(DC_LOGS) $(service)

## List containers (default format)
ps:
	@echo "📜 Listing containers..."
	$(DC_PS)

## List containers (compact format)
ps-format:
	@echo "📜 Compact list of containers..."
	$(DC_PS_FORMAT)

## List containers with details
ps-detailed:
	@echo "📜 Detailed list of containers..."
	$(DC_PS_DETAILED)

## Rebuild all containers
rebuild:
	@echo "🛠️ Rebuilding containers..."
	$(DC_DOWN) && $(DC_BUILD) && $(DC_UP)

## Run tests with coverage
coverage:
	@echo "🧪 Running tests with coverage..."
	$(PYTEST) --cov=$(MODULE) $(COV_REPORT) $(JUNIT_REPORT)

## Run ESLint analysis
lint:
	@echo "✨ Running ESLint..."
	$(LINT)

## Format code with Prettier
format:
	@echo "🖌️ Formatting code..."
	$(FORMAT)

## Check for dependency vulnerabilities
check-deps:
	@echo "🔍 Checking dependencies..."
	$(CHECK_DEPS)

## Clean reports
clean:
	@echo "🧹 Cleaning reports..."
	rm -rf $(REPORTS_DIR)/*

## Run SonarQube analysis
sonar-scanner:
	@echo "🔎 Running SonarQube Scanner..."
	$(SONAR_SCANNER) -Dsonar.projectKey=$(SONAR_PROJECT_KEY) \
	-Dsonar.sources=. \
	-Dsonar.host.url=${SONAR_HOST_URL} \
	-Dsonar.token=${SONAR_TOKEN_INFRA_DEVTOOLS} \
	-Dsonar.sourceEncoding=UTF-8