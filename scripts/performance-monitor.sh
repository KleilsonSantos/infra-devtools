#!/bin/bash
################################################################################
#
# 📊 Performance Monitor - Dashboard CLI de Métricas em Tempo Real
#
# 👨‍💻 Author: Kleilson Santos
# 📅 Created: 2025-11-07
# 🔄 Last Updated: 2025-11-07
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 📖 Purpose:
#    Dashboard CLI para monitoramento em tempo real:
#    ✅ Métricas de CPU, memória, disco
#    ✅ Status de containers
#    ✅ Uso de rede
#    ✅ Métricas de cada serviço
#    ✅ Alertas de thresholds
#
# ⚡ Features:
#    ✅ Atualização em tempo real
#    ✅ Color-coded status
#    ✅ Alertas automáticos
#    ✅ Histórico de métricas
#
# 📋 Usage:
#    ./performance-monitor.sh              # Dashboard contínuo (30s refresh)
#    ./performance-monitor.sh once         # Uma vez e sai
#    ./performance-monitor.sh watch 60     # Refresh a cada 60s
#
################################################################################

# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/..)" && pwd)"
REFRESH_INTERVAL="${2:-30}"
METRICS_FILE="$PROJECT_ROOT/reports/metrics.log"

# Thresholds para alertas
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=80

mkdir -p "$(dirname "$METRICS_FILE")"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 Metrics Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

get_cpu_usage() {
    if command -v docker &> /dev/null; then
        docker stats --no-stream --format "table {{.CPUPerc}}" 2>/dev/null | \
            tail -n +2 | sed 's/%//g' | awk '{sum+=$1; count++} END {print int(sum/count)}'
    else
        echo "0"
    fi
}

get_memory_usage() {
    if command -v docker &> /dev/null; then
        docker stats --no-stream --format "table {{.MemPerc}}" 2>/dev/null | \
            tail -n +2 | sed 's/%//g' | awk '{sum+=$1; count++} END {print int(sum/count)}'
    else
        echo "0"
    fi
}

get_disk_usage() {
    df -h "$PROJECT_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//'
}

get_container_count() {
    docker ps --format "{{.Names}}" 2>/dev/null | wc -l
}

get_network_io() {
    if command -v docker &> /dev/null; then
        local stats
        stats=$(docker stats --no-stream --format "table {{.NetIO}}" 2>/dev/null | tail -n +2 | head -1)
        echo "$stats"
    else
        echo "N/A"
    fi
}

format_status() {
    local value=$1
    local threshold=$2
    local label=$3

    if [[ "$value" -ge "$threshold" ]]; then
        echo -e "❌ $label: ${value}% (critical)"
        return 1
    elif [[ "$value" -ge $((threshold - 10)) ]]; then
        echo -e "⚠️  $label: ${value}% (warning)"
        return 0
    else
        echo -e "✅ $label: ${value}%"
        return 0
    fi
}

draw_bar() {
    local value=$1
    local max=100
    local width=20

    local filled=$((value * width / max))
    local empty=$((width - filled))

    printf "["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' '-'
    printf "] %3d%%\n" "$value"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎨 Dashboard Display
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

display_dashboard() {
    clear

    echo "═══════════════════════════════════════════════════════════════════════════"
    echo "  📊 Infrastructure Performance Monitor | $(date '+%Y-%m-%d %H:%M:%S')"
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo ""

    # System Metrics
    echo "💻 SYSTEM RESOURCES"
    echo "─────────────────────────────────────────────────────────────────────────"

    local cpu
    cpu=$(get_cpu_usage)
    echo -n "  CPU Usage:     "
    draw_bar "$cpu"
    format_status "$cpu" "$CPU_THRESHOLD" "CPU" > /dev/null

    local memory
    memory=$(get_memory_usage)
    echo -n "  Memory Usage:  "
    draw_bar "$memory"
    format_status "$memory" "$MEMORY_THRESHOLD" "Memory" > /dev/null

    local disk
    disk=$(get_disk_usage)
    echo -n "  Disk Usage:    "
    draw_bar "$disk"
    format_status "$disk" "$DISK_THRESHOLD" "Disk" > /dev/null

    echo ""
    echo "🐳 CONTAINERS"
    echo "─────────────────────────────────────────────────────────────────────────"

    local container_count
    container_count=$(get_container_count)
    echo "  Running Containers: $container_count"

    # Top containers by CPU
    echo ""
    echo "  Top Containers by CPU:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}" 2>/dev/null | \
        tail -n +2 | sort -k2 -rn | head -5 | while read -r container cpu; do
        printf "    • %-30s %s\n" "$container" "$cpu"
    done

    # Network I/O
    echo ""
    echo "🌐 NETWORK"
    echo "─────────────────────────────────────────────────────────────────────────"

    local netio
    netio=$(get_network_io)
    echo "  Network I/O: $netio"

    # Critical Alerts
    echo ""
    echo "🚨 ALERTS"
    echo "─────────────────────────────────────────────────────────────────────────"

    local has_alerts=false

    if [[ "$cpu" -ge "$CPU_THRESHOLD" ]]; then
        echo "  ⚠️  CPU usage at ${cpu}% (threshold: ${CPU_THRESHOLD}%)"
        has_alerts=true
    fi

    if [[ "$memory" -ge "$MEMORY_THRESHOLD" ]]; then
        echo "  ⚠️  Memory usage at ${memory}% (threshold: ${MEMORY_THRESHOLD}%)"
        has_alerts=true
    fi

    if [[ "$disk" -ge "$DISK_THRESHOLD" ]]; then
        echo "  ⚠️  Disk usage at ${disk}% (threshold: ${DISK_THRESHOLD}%)"
        has_alerts=true
    fi

    if [[ "$has_alerts" = false ]]; then
        echo "  ✅ No active alerts"
    fi

    # Footer
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo "  Refresh: ${REFRESH_INTERVAL}s | Press Ctrl+C to exit"
    echo "═══════════════════════════════════════════════════════════════════════════"

    # Log metrics
    log_metrics "$cpu" "$memory" "$disk"
}

log_metrics() {
    local cpu=$1
    local memory=$2
    local disk=$3

    echo "$(date -I'seconds') | CPU: ${cpu}% | Memory: ${memory}% | Disk: ${disk}%" >> "$METRICS_FILE"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 Main Execution
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cmd_help() {
    cat << 'EOF'
📊 Performance Monitor - Dashboard CLI em Tempo Real

USAGE:
    ./performance-monitor.sh [mode] [interval]

MODES:
    (default)  Dashboard contínuo (atualiza a cada 30s)
    once       Mostra dashboard uma vez e sai
    watch 60   Dashboard contínuo com refresh customizado (60s)

EXAMPLES:
    # Dashboard padrão (30s refresh)
    ./performance-monitor.sh

    # Atualizar a cada 60 segundos
    ./performance-monitor.sh watch 60

    # Uma vez e sair
    ./performance-monitor.sh once

MÉTRICAS MONITORIZADAS:
    • CPU usage (Average)
    • Memory usage (Average)
    • Disk usage
    • Running containers
    • Network I/O
    • Top containers by CPU

ALERTAS:
    ✅ Green   - Healthy (<70%)
    ⚠️  Yellow - Warning (70-90%)
    ❌ Red    - Critical (>90%)

HISTÓRICO:
    Métricas salvas em: reports/metrics.log
EOF
}

main() {
    local mode="${1:-watch}"

    case "$mode" in
        once)
            display_dashboard
            ;;
        watch|"")
            while true; do
                display_dashboard
                sleep "$REFRESH_INTERVAL"
            done
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            log_error "Unknown mode: $mode"
            cmd_help
            ;;
    esac
}

main "$@"
