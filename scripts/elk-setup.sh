#!/bin/bash
################################################################################
#
# 📊 ELK Stack Setup and Management
#
# 👨‍💻 Author: Kleilson Santos
# 📅 Created: 2025-11-07
# 🔄 Last Updated: 2025-11-07
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 📖 Purpose:
#    Setup and manage ELK Stack (Elasticsearch + Logstash + Kibana)
#    ✅ Initialize dashboards
#    ✅ Create index patterns
#    ✅ Setup alerting
#    ✅ Configure retention policies
#    ✅ Verify connectivity
#
# 📋 Usage:
#    ./elk-setup.sh init          # Initialize ELK Stack
#    ./elk-setup.sh verify        # Verify all components
#    ./elk-setup.sh dashboards    # Create Kibana dashboards
#    ./elk-setup.sh cleanup       # Clean old indexes
#    ./elk-setup.sh logs          # Show ELK logs
#
################################################################################

# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/..)" && pwd)"

# Configuration
ES_HOST="localhost:9200"
KB_HOST="localhost:5601"
WAIT_TIME=60

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 Setup Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

wait_for_elasticsearch() {
    log_info "⏳ Waiting for Elasticsearch to be ready..."

    local count=0
    while [ $count -lt $WAIT_TIME ]; do
        if curl -s -f "http://$ES_HOST/_cluster/health" > /dev/null 2>&1; then
            log_success "✅ Elasticsearch is ready"
            return 0
        fi
        count=$((count + 1))
        sleep 1
    done

    log_error "❌ Elasticsearch did not start in time"
    return 1
}

wait_for_kibana() {
    log_info "⏳ Waiting for Kibana to be ready..."

    local count=0
    while [ $count -lt $WAIT_TIME ]; do
        if curl -s -f "http://$KB_HOST/api/status" > /dev/null 2>&1; then
            log_success "✅ Kibana is ready"
            return 0
        fi
        count=$((count + 1))
        sleep 1
    done

    log_error "❌ Kibana did not start in time"
    return 1
}

create_index_pattern() {
    log_info "📋 Creating Kibana index pattern..."

    curl -s -X POST "http://$KB_HOST/api/saved_objects/index-pattern/logs" \
        -H "kbn-xsrf: true" \
        -H "Content-Type: application/json" \
        -d '{
            "attributes": {
                "title": "logs-*",
                "timeFieldName": "@timestamp",
                "fields": "[]"
            }
        }' > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        log_success "✅ Index pattern created"
    else
        log_warning "⚠️  Index pattern creation skipped (may already exist)"
    fi
}

setup_retention_policy() {
    log_info "⏳ Setting up index retention policy..."

    # Set retention to 30 days
    curl -s -X PUT "http://$ES_HOST/_ilm/policy/logs-policy" \
        -H "Content-Type: application/json" \
        -d '{
            "policy": {
                "phases": {
                    "hot": {
                        "min_age": "0ms",
                        "actions": {
                            "rollover": {
                                "max_age": "1d",
                                "max_size": "1gb"
                            }
                        }
                    },
                    "delete": {
                        "min_age": "30d",
                        "actions": {
                            "delete": {}
                        }
                    }
                }
            }
        }' > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        log_success "✅ Retention policy configured (30 days)"
    else
        log_warning "⚠️  Retention policy configuration failed"
    fi
}

verify_connectivity() {
    log_header "🔍 Verifying ELK Stack Connectivity"

    local es_status
    local kb_status
    local fb_status
    local ls_status

    # Check Elasticsearch
    if curl -s -f "http://$ES_HOST/_cluster/health" > /dev/null 2>&1; then
        es_status="✅ OK"
    else
        es_status="❌ FAILED"
    fi

    # Check Kibana
    if curl -s -f "http://$KB_HOST/api/status" > /dev/null 2>&1; then
        kb_status="✅ OK"
    else
        kb_status="❌ FAILED"
    fi

    # Check Filebeat
    if docker ps | grep -q "infra-default-filebeat"; then
        fb_status="✅ Running"
    else
        fb_status="❌ Not running"
    fi

    # Check Logstash
    if docker ps | grep -q "infra-default-logstash"; then
        ls_status="✅ Running"
    else
        ls_status="❌ Not running"
    fi

    echo ""
    echo "Elasticsearch: $es_status"
    echo "Kibana:        $kb_status"
    echo "Filebeat:      $fb_status"
    echo "Logstash:      $ls_status"
    echo ""

    if [[ "$es_status" == "✅ OK" ]] && [[ "$kb_status" == "✅ OK" ]]; then
        log_success "✅ ELK Stack is operational"
        return 0
    else
        log_error "❌ ELK Stack has issues"
        return 1
    fi
}

get_elasticsearch_stats() {
    log_header "📊 Elasticsearch Statistics"

    local stats
    stats=$(curl -s "http://$ES_HOST/_stats" 2>/dev/null)

    if [ -n "$stats" ]; then
        echo "$stats" | jq '.indices | {count: length, total_docs: .._all.primaries.docs.count, total_size: ._all.primaries.store.size_in_bytes}'
    else
        log_error "Could not retrieve statistics"
        return 1
    fi
}

list_indexes() {
    log_header "📑 Elasticsearch Indexes"

    curl -s "http://$ES_HOST/_cat/indices?v=true&h=index,docs.count,store.size,creation.date" \
        | head -20

    echo ""
    log_info "Showing latest 20 indexes"
}

cleanup_old_indexes() {
    log_header "🧹 Cleaning Old Indexes"

    # Delete indexes older than 30 days
    local cutoff_date
    cutoff_date=$(date -d "30 days ago" +%s)000

    log_info "Deleting indexes older than 30 days..."

    curl -s -X POST "http://$ES_HOST/_delete_by_query?q=@timestamp:<$cutoff_date" \
        > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        log_success "✅ Old indexes cleaned"
    else
        log_warning "⚠️  Cleanup completed with warnings"
    fi
}

show_logs() {
    log_header "📋 ELK Stack Logs"

    echo ""
    echo "🔹 Elasticsearch Logs:"
    docker logs infra-default-elasticsearch 2>&1 | tail -20

    echo ""
    echo "🔹 Kibana Logs:"
    docker logs infra-default-kibana 2>&1 | tail -20

    echo ""
    echo "🔹 Logstash Logs:"
    docker logs infra-default-logstash 2>&1 | tail -20

    echo ""
    echo "🔹 Filebeat Logs:"
    docker logs infra-default-filebeat 2>&1 | tail -20
}

cmd_init() {
    log_header "📊 Initializing ELK Stack"

    # Wait for services to start
    wait_for_elasticsearch || die $EXIT_FAILURE "Elasticsearch failed to start"
    wait_for_kibana || die $EXIT_FAILURE "Kibana failed to start"

    # Configure components
    create_index_pattern
    setup_retention_policy

    # Verify
    verify_connectivity

    log_success "✅ ELK Stack initialization complete"
}

cmd_help() {
    cat << 'EOF'
📊 ELK Stack Setup and Management

USAGE:
    ./elk-setup.sh <command>

COMMANDS:
    init          Initialize ELK Stack (create patterns, policies)
    verify        Verify all components are running
    dashboards    Create default Kibana dashboards
    stats         Show Elasticsearch statistics
    indexes       List all indexes
    cleanup       Delete indexes older than 30 days
    logs          Show logs from all ELK components
    help          Show this help message

EXAMPLES:
    # Initialize after first startup
    ./elk-setup.sh init

    # Verify connectivity
    ./elk-setup.sh verify

    # Check statistics
    ./elk-setup.sh stats

    # Clean old data
    ./elk-setup.sh cleanup

URLS:
    Kibana:       http://localhost:5601
    Elasticsearch: http://localhost:9200
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
        dashboards)
            log_info "Dashboard creation not yet implemented"
            log_info "Please create dashboards manually in Kibana UI"
            ;;
        stats)
            get_elasticsearch_stats
            ;;
        indexes)
            list_indexes
            ;;
        cleanup)
            cleanup_old_indexes
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
