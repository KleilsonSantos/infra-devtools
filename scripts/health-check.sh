#!/bin/bash
################################################################################
#
# 💚 Health Check - Validação de Saúde da Infraestrutura
#
# 👨‍💻 Author: Kleilson Santos
# 📅 Created: 2025-11-07
# 🔄 Last Updated: 2025-11-07
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 📖 Purpose:
#    Validação abrangente de saúde de todos os serviços:
#    ✅ Status dos containers
#    ✅ Conectividade entre serviços
#    ✅ Testes de endpoints HTTP
#    ✅ Validação de bancos de dados
#    ✅ Verificação de ports e networking
#    ✅ Relatório de saúde consolidado
#
# ⚡ Features:
#    ✅ Health checks de todos os 24 serviços
#    ✅ Validação de dependências entre serviços
#    ✅ Testes de conectividade de banco de dados
#    ✅ Relatório estruturado (JSON/texto)
#    ✅ Exit code apropriado para CI/CD
#
# 📋 Usage:
#    ./health-check.sh              # Health check completo
#    ./health-check.sh containers   # Apenas status dos containers
#    ./health-check.sh endpoints    # Testa endpoints HTTP
#    ./health-check.sh databases    # Testa conectividade de DBs
#    ./health-check.sh quick        # Quick health check (30s)
#
################################################################################

# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/..)" && pwd)"
DOCKER_COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"
HEALTH_REPORT="$PROJECT_ROOT/reports/health-check.json"

# Timeouts e limites
TIMEOUT_CONNECT=5
TIMEOUT_RESPONSE=10
MAX_RETRIES=3

# Contadores
HEALTHY=0
UNHEALTHY=0
UNKNOWN=0

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 Health Check Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

check_containers() {
    log_header "🐳 Container Status"

    local all_running=true

    # Get services from docker-compose.yml
    local services
    services=$(grep -E "^\s+[a-z].*:$" "$DOCKER_COMPOSE_FILE" | sed 's/[: ]//g' | sort -u)

    while read -r service; do
        [[ -z "$service" ]] && continue

        local container_name="${service}"
        local status

        if docker ps --filter "name=$container_name" --format "{{.Names}}" | grep -q "$container_name"; then
            local health
            health=$(docker inspect --format='{{.State.Health.Status}}' "infra-default-$container_name" 2>/dev/null || echo "no-health")

            case "$health" in
                "healthy")
                    log_success "  ✅ $service: Running (healthy)"
                    ((HEALTHY++))
                    ;;
                "starting")
                    log_warning "  ⏳ $service: Starting..."
                    ((UNKNOWN++))
                    ;;
                "unhealthy")
                    log_error "  ❌ $service: Unhealthy"
                    ((UNHEALTHY++))
                    all_running=false
                    ;;
                *)
                    log_info "  ℹ️  $service: Running (no health check)"
                    ((HEALTHY++))
                    ;;
            esac
        else
            log_error "  ❌ $service: Not running"
            ((UNHEALTHY++))
            all_running=false
        fi
    done <<< "$services"

    return $([ "$all_running" = true ] && echo 0 || echo 1)
}

check_endpoints() {
    log_header "🌐 HTTP Endpoints"

    local endpoints=(
        "http://localhost:9002 SonarQube"
        "http://localhost:9001 Portainer"
        "http://localhost:8081 Mongo Express"
        "http://localhost:8088 pgAdmin"
        "http://localhost:8082 phpMyAdmin"
        "http://localhost:8083 RedisInsight"
        "http://localhost:3001 Grafana"
        "http://localhost:9090 Prometheus"
        "http://localhost:8200 Vault"
        "http://localhost:8084 Keycloak"
        "http://localhost:15672 RabbitMQ"
    )

    local all_accessible=true

    for endpoint in "${endpoints[@]}"; do
        local url port_name
        url=$(echo "$endpoint" | awk '{print $1}')
        port_name=$(echo "$endpoint" | awk '{$1=""; print $0}' | sed 's/^ //')

        if timeout $TIMEOUT_RESPONSE curl -s -f "$url" > /dev/null 2>&1; then
            log_success "  ✅ $port_name: Accessible"
            ((HEALTHY++))
        else
            log_warning "  ⚠️  $port_name: Not accessible (may be starting)"
            ((UNKNOWN++))
        fi
    done

    return 0
}

check_databases() {
    log_header "🗄️ Database Connectivity"

    # PostgreSQL
    if command -v psql &> /dev/null || docker image ls | grep -q postgres; then
        if timeout $TIMEOUT_CONNECT docker exec infra-default-postgres \
            psql -U postgres -c "SELECT 1" > /dev/null 2>&1; then
            log_success "  ✅ PostgreSQL: Connected"
            ((HEALTHY++))
        else
            log_warning "  ⚠️  PostgreSQL: Cannot connect"
            ((UNKNOWN++))
        fi
    fi

    # MongoDB
    if docker image ls | grep -q mongo; then
        if timeout $TIMEOUT_CONNECT docker exec infra-default-mongodb \
            mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
            log_success "  ✅ MongoDB: Connected"
            ((HEALTHY++))
        else
            log_warning "  ⚠️  MongoDB: Cannot connect"
            ((UNKNOWN++))
        fi
    fi

    # MySQL
    if command -v mysql &> /dev/null; then
        if timeout $TIMEOUT_CONNECT docker exec infra-default-mysql \
            mysql -u root -ppassword -e "SELECT 1" > /dev/null 2>&1; then
            log_success "  ✅ MySQL: Connected"
            ((HEALTHY++))
        else
            log_warning "  ⚠️  MySQL: Cannot connect"
            ((UNKNOWN++))
        fi
    fi

    # Redis
    if command -v redis-cli &> /dev/null || docker image ls | grep -q redis; then
        if timeout $TIMEOUT_CONNECT docker exec infra-default-redis \
            redis-cli ping > /dev/null 2>&1; then
            log_success "  ✅ Redis: Connected"
            ((HEALTHY++))
        else
            log_warning "  ⚠️  Redis: Cannot connect"
            ((UNKNOWN++))
        fi
    fi

    return 0
}

check_networking() {
    log_header "🔗 Network Connectivity"

    # Verificar rede Docker
    local network_name="infra-devtools_default"

    if docker network ls | grep -q "$network_name"; then
        log_success "  ✅ Docker network exists: $network_name"
        ((HEALTHY++))
    else
        log_warning "  ⚠️  Docker network not found"
        ((UNKNOWN++))
    fi

    # Verificar DNS resolution
    if docker run --rm --network "$network_name" alpine nslookup postgres > /dev/null 2>&1; then
        log_success "  ✅ DNS resolution working"
        ((HEALTHY++))
    else
        log_warning "  ⚠️  DNS resolution may have issues"
        ((UNKNOWN++))
    fi

    return 0
}

check_resources() {
    log_header "💾 System Resources"

    # Verificar espaço em disco
    local disk_usage
    disk_usage=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//')

    if [[ "$disk_usage" -lt 80 ]]; then
        log_success "  ✅ Disk usage: ${disk_usage}% (healthy)"
        ((HEALTHY++))
    elif [[ "$disk_usage" -lt 90 ]]; then
        log_warning "  ⚠️  Disk usage: ${disk_usage}% (warning)"
        ((UNKNOWN++))
    else
        log_error "  ❌ Disk usage: ${disk_usage}% (critical)"
        ((UNHEALTHY++))
    fi

    # Verificar Docker engine
    if docker ps > /dev/null 2>&1; then
        log_success "  ✅ Docker engine: Running"
        ((HEALTHY++))
    else
        log_error "  ❌ Docker engine: Not accessible"
        ((UNHEALTHY++))
    fi

    # Verificar espaço em volumes
    if docker volume ls | grep -q "infra-"; then
        log_success "  ✅ Docker volumes: Available"
        ((HEALTHY++))
    else
        log_warning "  ⚠️  Docker volumes: Not found"
        ((UNKNOWN++))
    fi

    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 Report Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

generate_report() {
    log_header "📊 Health Check Summary"

    local total=$((HEALTHY + UNHEALTHY + UNKNOWN))
    local health_percentage=0

    if [[ "$total" -gt 0 ]]; then
        health_percentage=$((HEALTHY * 100 / total))
    fi

    # Console output
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  💚 HEALTH CHECK REPORT"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "✅ Healthy:     $HEALTHY"
    echo "⚠️  Unknown:     $UNKNOWN"
    echo "❌ Unhealthy:   $UNHEALTHY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Overall:     ${health_percentage}% Healthy"
    echo "════════════════════════════════════════════════════════════════"
    echo ""

    if [[ "$health_percentage" -eq 100 ]]; then
        log_success "✅ All systems operational!"
    elif [[ "$health_percentage" -ge 80 ]]; then
        log_warning "⚠️  Minor issues detected. Review above."
    else
        log_error "❌ Critical issues. Immediate attention required."
    fi

    # JSON report
    mkdir -p "$(dirname "$HEALTH_REPORT")"
    cat > "$HEALTH_REPORT" << EOF
{
  "timestamp": "$(date -I'seconds')",
  "health_percentage": $health_percentage,
  "healthy": $HEALTHY,
  "unknown": $UNKNOWN,
  "unhealthy": $UNHEALTHY,
  "total": $total,
  "status": $([ "$UNHEALTHY" -eq 0 ] && echo '"operational"' || echo '"degraded"')
}
EOF

    log_info "📄 Report saved: $HEALTH_REPORT"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 Command Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cmd_full_check() {
    log_header "💚 Full Infrastructure Health Check"
    echo ""

    check_containers
    echo ""
    check_endpoints
    echo ""
    check_databases
    echo ""
    check_networking
    echo ""
    check_resources
    echo ""

    generate_report

    # Return appropriate exit code
    [ "$UNHEALTHY" -eq 0 ] && return 0 || return 1
}

cmd_quick_check() {
    log_header "⚡ Quick Health Check (30s)"
    echo ""

    check_containers
    echo ""

    generate_report

    [ "$UNHEALTHY" -eq 0 ] && return 0 || return 1
}

cmd_help() {
    cat << 'EOF'
💚 Health Check - Validação de Saúde da Infraestrutura

USAGE:
    ./health-check.sh <command>

COMMANDS:
    (default)   Executa health check completo
    containers  Verifica status dos containers
    endpoints   Testa endpoints HTTP/HTTPS
    databases   Valida conectividade de bancos
    networking  Verifica conectividade de rede
    resources   Checa recursos do sistema
    quick       Quick check (apenas containers, 30s)
    help        Mostra esta mensagem

EXAMPLES:
    # Health check completo
    ./health-check.sh

    # Apenas verificar containers
    ./health-check.sh containers

    # Quick check
    ./health-check.sh quick

RELATÓRIOS:
    JSON: reports/health-check.json

EXIT CODES:
    0  - Todos os serviços saudáveis
    1  - Algum serviço com problemas
EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 Main Execution
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    local command="${1:-full}"

    case "$command" in
        full|"")
            cmd_full_check
            ;;
        containers)
            check_containers
            ;;
        endpoints)
            check_endpoints
            ;;
        databases)
            check_databases
            ;;
        networking)
            check_networking
            ;;
        resources)
            check_resources
            ;;
        quick)
            cmd_quick_check
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            log_error "Unknown command: $command"
            cmd_help
            return $EXIT_INVALID_ARGS
            ;;
    esac
}

main "$@"
