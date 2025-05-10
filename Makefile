# 🌍 Environment Configuration
ENV_FILE=.env

DOCKER_COMPOSE=docker compose --env-file $(ENV_FILE)
DOCKER_COMPOSE_PS=$(DOCKER_COMPOSE) ps

DOCKER_COMPOSE_UP=$(DOCKER_COMPOSE) up -d
DOCKER_COMPOSE_UP_FORCE_RECREATE=$(DOCKER_COMPOSE) up -d --force-recreate
DOCKER_COMPOSE_DOWN=$(DOCKER_COMPOSE) down --volumes=false --remove-orphans
DOCKER_COMPOSE_LOGS=$(DOCKER_COMPOSE) logs -f
DOCKER_COMPOSE_BUILD=$(DOCKER_COMPOSE) build
DOCKER_COMPOSE_RUN=$(DOCKER_COMPOSE) run --rm
DOCKER_COMPOSE_EXEC=$(DOCKER_COMPOSE) exec
DOCKER_COMPOSE_PULL=$(DOCKER_COMPOSE) pull

CHECK-DEPS=scripts/run-dependency-check.sh

# 📦 List of available services
SERVICES=portainer sonarqube mongo mongo-express postgres pgadmin mysql phpmyadmin prometheus grafana cadvisor node-exporter redis redisinsight mysql-exporter postgres-exporter mongodb-exporter redis-exporter

# 🚀 Start containers (all or selected via SERVICES variable)
up:
	@echo "🔼 Starting **all** containers"
	$(DOCKER_COMPOSE_UP) $(SERVICES)

# 🛑 Stop containers without removing volumes
down:
	@echo "🔽 Stopping all containers"
	$(DOCKER_COMPOSE_DOWN)

# 🛑 Stop containers and remove volumes
force-recreate:
	@echo "🔽 Stopping all containers"
	@echo "🔄 Recreating containers"
	$(DOCKER_COMPOSE_DOWN) && \
	$(DOCKER_COMPOSE_UP_FORCE_RECREATE) $(SERVICES)

# 📜 Show logs for a specific service
logs:
	@echo "📋 Showing logs for service $(c)"
	$(DOCKER_COMPOSE_LOGS) $(c)

# 📜 Show logs for all services
ps:
	@echo "📜 Listing all containers"
	$(DOCKER_COMPOSE_PS)

# 📜 Show logs for all services
ps-all:
	@echo "📜 Listing all containers with details"
	$(DOCKER_COMPOSE_PS) -a

# 📜 Show logs for a specific service
ps-filter:
	@echo "📜 Listing all containers with details and filter $(c)"
	$(DOCKER_COMPOSE_PS) -a | grep $(c)

# 🔄 Rebuild containers
rebuild:
	@echo "♻️ Rebuilding containers: $(SERVICES)"
	@echo "🔽 Stopping all containers: $(SERVICES)"
	@echo "🔄 Rebuilding containers: $(SERVICES)"
	@echo "🔼 Starting containers: $(SERVICES)"
	$(DOCKER_COMPOSE_DOWN) && \
	$(DOCKER_COMPOSE_BUILD) && \
	$(DOCKER_COMPOSE_UP)

# 🧪 Check dependencies
check-deps:
	@echo "🔍 Running dependency check: Running..."
	$(CHECK-DEPS)

# 🧪 Check dependencies with specific path
check-deps-path:
	@echo "🔍 Running dependency check for path: $(path)"
	$(CHECK-DEPS) $(path)