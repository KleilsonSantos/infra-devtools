#!/bin/bash
################################################################################
#
# 📊 Infra DevTools - Shared Library Functions
#
# 👨‍💻 Author: Kleilson Santos
# 📅 Created: 2025-11-06
# 🔄 Last Updated: 2025-11-06
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 📖 Purpose:
#    Shared utility functions for all Infra DevTools scripts.
#    Eliminates code duplication and ensures consistency across the project.
#
# ⚡ Features:
#    ✅ Standardized logging functions with consistent colors and formats
#    ✅ Environment configuration helpers (.env loading)
#    ✅ Command availability checking
#    ✅ Docker and system validation utilities
#    ✅ Spinner and progress indicators
#    ✅ Error handling and exit codes
#
# 📋 Usage:
#    Source this library at the beginning of scripts:
#      # shellcheck source=scripts/lib.sh
#      . "$(dirname "$0")/lib.sh"
#
# 🔧 Functions Available:
#    • Logging: log_info(), log_success(), log_warning(), log_error(), log_header()
#    • Environment: load_env(), require_cmd()
#    • Docker: check_docker(), check_compose()
#    • UI: show_spinner(), show_progress()
#    • Validation: validate_file(), validate_directory()
#
# ⚠️  Requirements:
#    • Bash 4.0+
#    • Standard Unix utilities (cat, grep, awk)
#
################################################################################

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🛡️  Safety and Error Handling
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎨 Color Configuration & Visual Elements
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;37m'
readonly NC='\033[0m'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚀 Standard Logging Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $*${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
}

log_error() {
    echo -e "${RED}❌ $*${NC}" >&2
}

log_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}$*${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${GRAY}🔍 DEBUG: $*${NC}" >&2
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 Environment and Configuration Helpers
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

load_env() {
    local env_file="${1:-$(pwd)/.env}"

    if [[ -f "$env_file" ]]; then
        log_debug "Loading environment from: $env_file"
        set -o allexport
        # shellcheck source=/dev/null
        source "$env_file"
        set +o allexport
        log_debug "Environment loaded successfully"
    else
        log_warning "Environment file not found: $env_file"
    fi
}

require_cmd() {
    local cmd="$1"
    local install_hint="${2:-}"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "Required command '$cmd' not found"
        if [[ -n "$install_hint" ]]; then
            log_info "Install with: $install_hint"
        fi
        return 1
    fi
    log_debug "Command '$cmd' is available"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🐳 Docker and System Validation
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

check_docker() {
    log_info "Verificando Docker..."

    if ! require_cmd "docker" "curl -fsSL https://get.docker.com | sh"; then
        return 1
    fi

    if ! docker version >/dev/null 2>&1; then
        log_error "Docker daemon não está rodando"
        log_info "Inicie o Docker: sudo systemctl start docker"
        return 1
    fi

    log_success "Docker está funcionando"
}

check_compose() {
    log_info "Verificando Docker Compose..."

    if ! require_cmd "docker-compose" "sudo apt install docker-compose-plugin" &&
       ! docker compose version >/dev/null 2>&1; then
        log_error "Docker Compose não encontrado"
        return 1
    fi

    log_success "Docker Compose está disponível"
}

check_port() {
    local port="$1"
    local service="${2:-unknown}"

    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        local pid
        pid=$(netstat -tulpn 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | head -1)
        log_warning "Porta $port ($service) em uso por PID $pid"
        return 1
    fi

    log_debug "Porta $port está livre"
    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 UI and Progress Indicators
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

show_spinner() {
    local pid=$1
    local message="$2"
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    while ps -p "$pid" > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf "\r${CYAN}%c${NC} %s" "$spinstr" "$message"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r"
}

show_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-Progress}"
    local width=50

    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))

    printf "\r${CYAN}%s${NC} [" "$message"
    printf "%*s" "$completed" | tr ' ' '█'
    printf "%*s" "$remaining" | tr ' ' '░'
    printf "] %d%%" "$percentage"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📁 File and Directory Validation
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

validate_file() {
    local file="$1"
    local description="${2:-File}"

    if [[ ! -f "$file" ]]; then
        log_error "$description não encontrado: $file"
        return 1
    fi

    if [[ ! -r "$file" ]]; then
        log_error "$description não é legível: $file"
        return 1
    fi

    log_debug "$description válido: $file"
    return 0
}

validate_directory() {
    local dir="$1"
    local description="${2:-Directory}"

    if [[ ! -d "$dir" ]]; then
        log_error "$description não encontrado: $dir"
        return 1
    fi

    if [[ ! -r "$dir" ]] || [[ ! -x "$dir" ]]; then
        log_error "$description sem permissões adequadas: $dir"
        return 1
    fi

    log_debug "$description válido: $dir"
    return 0
}

ensure_directory() {
    local dir="$1"
    local description="${2:-Directory}"

    if [[ ! -d "$dir" ]]; then
        log_info "Criando $description: $dir"
        mkdir -p "$dir" || {
            log_error "Falha ao criar $description: $dir"
            return 1
        }
    fi

    validate_directory "$dir" "$description"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔒 Security and Input Validation
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

sanitize_input() {
    local input="$1"
    # Remove caracteres perigosos para shell
    echo "$input" | sed 's/[^a-zA-Z0-9._-]//g'
}

validate_service_name() {
    local service="$1"
    local valid_services=(
        "postgres" "pgadmin" "postgres-exporter"
        "mongo" "mongo-express" "mongodb-exporter"
        "mysql" "phpmyadmin" "mysql-exporter"
        "redis" "redisinsight" "redis-exporter"
        "rabbitmq" "rabbitmq-exporter"
        "vault" "keycloak"
        "prometheus" "grafana" "alertmanager"
        "blackbox-exporter" "cadvisor" "node-exporter"
        "sonarqube" "portainer"
        "crud-users-api" "webhook-listener" "eureka-server" "mailhog"
    )

    for valid in "${valid_services[@]}"; do
        if [[ "$service" == "$valid" ]]; then
            return 0
        fi
    done

    log_error "Serviço inválido: $service"
    log_info "Serviços válidos: ${valid_services[*]}"
    return 1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚨 Error Handling and Exit Codes
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Standard exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1
readonly EXIT_INVALID_ARGS=2
readonly EXIT_MISSING_DEPS=3
readonly EXIT_PERMISSION_DENIED=4
readonly EXIT_NOT_FOUND=5

die() {
    local exit_code="${1:-$EXIT_FAILURE}"
    shift
    log_error "$@"
    exit "$exit_code"
}

cleanup_temp() {
    if [[ -n "${TEMP_FILES:-}" ]]; then
        log_debug "Limpando arquivos temporários: ${TEMP_FILES[*]}"
        rm -f "${TEMP_FILES[@]}" 2>/dev/null || true
    fi
}

# Trap para limpeza automática
trap cleanup_temp EXIT

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 Library Information
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

lib_version() {
    echo "Infra DevTools Library v1.0.0"
}

lib_help() {
    cat << 'EOF'
Infra DevTools - Shared Library Functions

USAGE:
    # shellcheck source=scripts/lib.sh
    . "$(dirname "$0")/lib.sh"

FUNCTIONS:
    Logging:
        log_info <message>      - Info message (blue)
        log_success <message>   - Success message (green)
        log_warning <message>   - Warning message (yellow)
        log_error <message>     - Error message (red, to stderr)
        log_header <message>    - Section header
        log_debug <message>     - Debug message (if DEBUG=true)

    Environment:
        load_env [file]         - Load environment variables
        require_cmd <cmd> [hint] - Check command availability

    Docker:
        check_docker            - Verify Docker is working
        check_compose           - Verify Docker Compose
        check_port <port> [service] - Check if port is in use

    UI:
        show_spinner <pid> <msg> - Show spinner while process runs
        show_progress <cur> <tot> [msg] - Show progress bar

    Validation:
        validate_file <path> [desc] - Validate file exists and readable
        validate_directory <path> [desc] - Validate directory
        ensure_directory <path> [desc] - Create directory if needed
        sanitize_input <input>   - Remove dangerous characters
        validate_service_name <service> - Check service name

    Error Handling:
        die <code> <message>    - Exit with error message
        cleanup_temp            - Clean temporary files

EXAMPLES:
    log_info "Starting process..."
    require_cmd "docker" "sudo apt install docker.io"
    if check_port 5432 "postgres"; then
        log_success "Port is available"
    fi
EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 Main Guard (for direct execution)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        "help"|"--help"|"-h")
            lib_help
            ;;
        "version"|"--version"|"-v")
            lib_version
            ;;
        *)
            log_info "Infra DevTools - Shared Library"
            echo "Use 'source' to load functions or run with --help for usage"
            ;;
    esac
fi
