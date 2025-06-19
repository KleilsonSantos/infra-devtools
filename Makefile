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
  cadvisor \
  node-exporter \
  postgres-exporter \
  mysql-exporter \
  mongodb-exporter \
  redis-exporter \
  sonarqube \
  portainer \
  keycloak
>>>>>>> Stashed changes

# 🐳 Configuração do Docker Compose
DOCKER_COMPOSE=docker compose --env-file $(ENV_FILE)
DOCKER_COMPOSE_UP=$(DOCKER_COMPOSE) up -d
DOCKER_COMPOSE_DOWN=$(DOCKER_COMPOSE) down --volumes=false --remove-orphans
DOCKER_COMPOSE_BUILD=$(DOCKER_COMPOSE) build
DOCKER_COMPOSE_EXEC=$(DOCKER_COMPOSE) exec
DOCKER_COMPOSE_PULL=$(DOCKER_COMPOSE) pull
DOCKER_COMPOSE_RUN=$(DOCKER_COMPOSE) run --rm

# 🔍 Status & Logs
DOCKER_COMPOSE_PS=$(DOCKER_COMPOSE) ps
DOCKER_COMPOSE_LOGS=$(DOCKER_COMPOSE) logs -f
DOCKER_COMPOSE_FORMAT=$(DOCKER_COMPOSE) ps --format 'table {{.Names}}'
DOCKER_COMPOSE_FORMAT_DETAILED=$(DOCKER_COMPOSE) ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# 🧪 Testes e Cobertura
CONVERTER_SCRIPT=src/utils/convert_junit_to_sonar.py
JUNIT_XML=reports/coverage/test-results.xml
SONAR_XML=reports/coverage/test-executions.xml
PYTEST_COVERAGE_ALL=pytest --cov=$(MODULE) --cov-report xml:$(REPORTS_DIR)/coverage/coverage.xml --cov-report html:$(REPORTS_DIR)/coverage
PYTEST_COVERAGE_JUNIT=pytest --junitxml=reports/coverage/test-results.xml

# 🎨 Linting e Formatação
LINT=npx eslint --ext .ts,.js --fix
FORMAT=npx prettier --write "**/*.{ts,js,json,md,py}"


# 🚀 Comandos para Containers
.PHONY: up down force-recreate logs ps ps-format ps-format-detailed ps-filter rebuild clean check-deps coverage sonar-scanner lint format convert-tests

up:
	@echo "🔼 Iniciando containers..."
	$(DOCKER_COMPOSE_UP) $(SERVICES)

down:
	@echo "🔽 Parando todos os containers..."
	$(DOCKER_COMPOSE_DOWN)

force-recreate:
	@echo "🔄 Recriando containers..."
	$(DOCKER_COMPOSE_DOWN) && \
	$(DOCKER_COMPOSE_UP) $(SERVICES)

logs:
	@echo "📋 Mostrando logs do serviço $(service)..."
	$(DOCKER_COMPOSE_LOGS) $(service)

ps:
	@echo "📜 Listando todos os containers..."
	$(DOCKER_COMPOSE_PS)

ps-format:
	@echo "📜 Listando containers em formato compacto..."
	$(DOCKER_COMPOSE_FORMAT)

ps-format-detailed:
	@echo "📜 Listando containers com detalhes..."
	$(DOCKER_COMPOSE_FORMAT_DETAILED)

ps-filter:
	@echo "📜 Filtrando containers por: $(filter)"
	$(DOCKER_COMPOSE_PS) -a | grep $(filter)

rebuild:
	@echo "♻️ Reconstruindo containers..."
	$(DOCKER_COMPOSE_DOWN) && \
	$(DOCKER_COMPOSE_BUILD) && \
	$(DOCKER_COMPOSE_UP)

## Check for dependency vulnerabilities
check-deps:
	@echo "🔎 Executando Dependency Check..."
	$(CHECK-DEPS)

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