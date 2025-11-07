#!/bin/bash
################################################################################
#
# 🔄 Jaeger Setup and Management
#
# 👨‍💻 Author: Kleilson Santos
# 📅 Created: 2025-11-07
# 🔄 Last Updated: 2025-11-07
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 📖 Purpose:
#    Setup and manage Jaeger distributed tracing
#    ✅ Verify connectivity
#    ✅ Check services
#    ✅ View traces
#    ✅ Performance monitoring
#
# 📋 Usage:
#    ./jaeger-setup.sh verify      # Verify all components
#    ./jaeger-setup.sh services    # List traced services
#    ./jaeger-setup.sh stats       # Show statistics
#    ./jaeger-setup.sh logs        # Show logs
#
################################################################################

# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/..)" && pwd)"

# Configuration
JAEGER_HOST="localhost:16686"
COLLECTOR_HOST="localhost:14268"
WAIT_TIME=60

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 Setup Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

wait_for_jaeger() {
    log_info "⏳ Waiting for Jaeger to be ready..."

    local count=0
    while [ $count -lt $WAIT_TIME ]; do
        if curl -s -f "http://$JAEGER_HOST/api/services" > /dev/null 2>&1; then
            log_success "✅ Jaeger is ready"
            return 0
        fi
        count=$((count + 1))
        sleep 1
    done

    log_error "❌ Jaeger did not start in time"
    return 1
}

verify_connectivity() {
    log_header "🔍 Verifying Jaeger Connectivity"

    local jaeger_status
    local collector_status
    local agent_status

    # Check Jaeger UI
    if curl -s -f "http://$JAEGER_HOST/api/services" > /dev/null 2>&1; then
        jaeger_status="✅ OK"
    else
        jaeger_status="❌ FAILED"
    fi

    # Check Collector
    if curl -s -f "http://$COLLECTOR_HOST" > /dev/null 2>&1; then
        collector_status="✅ OK"
    else
        collector_status="❌ FAILED"
    fi

    # Check Agent
    if docker ps | grep -q "infra-default-jaeger-agent"; then
        agent_status="✅ Running"
    else
        agent_status="❌ Not running"
    fi

    echo ""
    echo "Jaeger UI:       $jaeger_status (http://$JAEGER_HOST)"
    echo "Jaeger Collector: $collector_status"
    echo "Jaeger Agent:    $agent_status"
    echo ""

    if [[ "$jaeger_status" == "✅ OK" ]]; then
        log_success "✅ Jaeger is operational"
        return 0
    else
        log_error "❌ Jaeger has issues"
        return 1
    fi
}

list_services() {
    log_header "📋 Traced Services"

    local response
    response=$(curl -s "http://$JAEGER_HOST/api/services" 2>/dev/null)

    if [ -n "$response" ]; then
        echo "$response" | jq -r '.data[]?' 2>/dev/null || echo "No services traced yet"
    else
        log_error "Could not retrieve services"
        return 1
    fi
}

get_service_traces() {
    local service=$1

    if [ -z "$service" ]; then
        log_error "Service name required"
        return 1
    fi

    log_header "📊 Traces for $service"

    local response
    response=$(curl -s "http://$JAEGER_HOST/api/traces?service=$service&limit=10" 2>/dev/null)

    if [ -n "$response" ]; then
        echo "$response" | jq '.' || echo "No traces found"
    else
        log_error "Could not retrieve traces"
        return 1
    fi
}

get_service_operations() {
    local service=$1

    if [ -z "$service" ]; then
        log_error "Service name required"
        return 1
    fi

    log_header "📋 Operations for $service"

    local response
    response=$(curl -s "http://$JAEGER_HOST/api/services/$service/operations" 2>/dev/null)

    if [ -n "$response" ]; then
        echo "$response" | jq -r '.data[]?' | head -20
    else
        log_error "Could not retrieve operations"
        return 1
    fi
}

get_statistics() {
    log_header "📊 Jaeger Statistics"

    local response
    response=$(curl -s "http://$JAEGER_HOST/api/services" 2>/dev/null)

    if [ -n "$response" ]; then
        local service_count
        service_count=$(echo "$response" | jq '.data | length' 2>/dev/null || echo "0")

        log_info "Services traced: $service_count"
        log_info ""
        log_info "Services:"

        echo "$response" | jq -r '.data[]?' 2>/dev/null | while read -r service; do
            local op_response
            op_response=$(curl -s "http://$JAEGER_HOST/api/services/$service/operations" 2>/dev/null)
            local op_count
            op_count=$(echo "$op_response" | jq '.data | length' 2>/dev/null || echo "0")

            printf "  • %-30s (%d operations)\n" "$service" "$op_count"
        done
    else
        log_error "Could not retrieve statistics"
        return 1
    fi
}

show_logs() {
    log_header "📋 Jaeger Logs"

    echo ""
    echo "🔹 Jaeger Collector Logs:"
    docker logs infra-default-jaeger-collector 2>&1 | tail -20

    echo ""
    echo "🔹 Jaeger Agent Logs:"
    docker logs infra-default-jaeger-agent 2>&1 | tail -20
}

cmd_init() {
    log_header "🔄 Initializing Jaeger"

    # Wait for services
    wait_for_jaeger || die $EXIT_FAILURE "Jaeger failed to start"

    # Verify
    verify_connectivity

    log_success "✅ Jaeger initialization complete"
}

cmd_help() {
    cat << 'EOF'
🔄 Jaeger Setup and Management

USAGE:
    ./jaeger-setup.sh <command> [args]

COMMANDS:
    init              Initialize Jaeger
    verify            Verify all components are running
    services          List all traced services
    traces SERVICE    List traces for specific service
    operations SERVICE List operations for service
    stats             Show Jaeger statistics
    logs              Show logs from Jaeger components
    help              Show this help message

EXAMPLES:
    # Initialize after first startup
    ./jaeger-setup.sh init

    # Verify connectivity
    ./jaeger-setup.sh verify

    # List services being traced
    ./jaeger-setup.sh services

    # View traces for a service
    ./jaeger-setup.sh traces my-api

    # Get statistics
    ./jaeger-setup.sh stats

URLS:
    Jaeger UI:           http://localhost:16686
    Jaeger Collector:    http://localhost:14268
    OpenTelemetry gRPC:  grpc://localhost:4317
    OpenTelemetry HTTP:  http://localhost:4318
EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 Main Execution
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    local command="${1:-help}"

    case "$command" in
        init)
            cmd_init
            ;;
        verify)
            verify_connectivity
            ;;
        services)
            list_services
            ;;
        traces)
            get_service_traces "$2"
            ;;
        operations)
            get_service_operations "$2"
            ;;
        stats)
            get_statistics
            ;;
        logs)
            show_logs
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
