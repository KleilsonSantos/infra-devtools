#!/bin/bash
################################################################################
#
# 💾 Infra DevTools - Automated Backup System
#
# 👨‍💻 Author: Kleilson Santos
# 📅 Created: 2025-11-06
# 🔄 Last Updated: 2025-11-06
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 📖 Purpose:
#    Sistema de backup automatizado para todos os bancos de dados e volumes
#    críticos da infraestrutura DevOps.
#
# ⚡ Features:
#    ✅ Backup PostgreSQL, MongoDB, MySQL e Redis
#    ✅ Backup de volumes Docker críticos
#    ✅ Compressão automática
#    ✅ Retenção configurável (padrão: 30 dias)
#    ✅ Logs estruturados
#    ✅ Restore simplificado
#
# 📋 Usage:
#    ./backup.sh backup              # Criar backup completo
#    ./backup.sh restore YYYYMMDD    # Restaurar backup específico
#    ./backup.sh list                # Listar backups disponíveis
#    ./backup.sh cleanup             # Limpar backups antigos
#    ./backup.sh setup               # Configurar cron job
#
# 🔧 Cron Setup:
#    # Backup a cada 4 horas
#    0 */4 * * * /path/to/scripts/backup.sh backup
#
################################################################################

# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly BACKUP_BASE_DIR="${PROJECT_ROOT}/backups"
readonly BACKUP_DIR="${BACKUP_BASE_DIR}/$(date +%Y%m%d_%H%M%S)"
readonly LOG_DIR="${PROJECT_ROOT}/logs"
readonly LOG_FILE="${LOG_DIR}/backup.log"
readonly RETENTION_DAYS=30

# Load environment variables
load_env "${PROJECT_ROOT}/.env"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 Logging Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_backup() {
    local message="$1"
    ensure_directory "$LOG_DIR" "Log directory"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $message" | tee -a "${LOG_FILE}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 💾 Backup Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

backup_postgresql() {
    log_header "Backing up PostgreSQL"
    mkdir -p "${BACKUP_DIR}/postgresql"

    log_info "Dumping PostgreSQL databases..."
    docker exec postgres pg_dumpall -U postgres | gzip > "${BACKUP_DIR}/postgresql/postgres_all.sql.gz"

    if [[ -f "${BACKUP_DIR}/postgresql/postgres_all.sql.gz" ]]; then
        local size
        size=$(du -h "${BACKUP_DIR}/postgresql/postgres_all.sql.gz" | cut -f1)
        log_success "PostgreSQL backup completed (${size})"
        log_backup "✅ PostgreSQL backup: ${size}"
        return 0
    else
        log_error "PostgreSQL backup failed"
        log_backup "❌ PostgreSQL backup failed"
        return 1
    fi
}

backup_mongodb() {
    log_header "Backing up MongoDB"
    mkdir -p "${BACKUP_DIR}/mongodb"

    log_info "Dumping MongoDB databases..."
    docker exec mongo mongodump --out /tmp/backup --gzip

    docker cp mongo:/tmp/backup "${BACKUP_DIR}/mongodb/"
    docker exec mongo rm -rf /tmp/backup

    if [[ -d "${BACKUP_DIR}/mongodb/backup" ]]; then
        local size
        size=$(du -sh "${BACKUP_DIR}/mongodb/backup" | cut -f1)
        log_success "MongoDB backup completed (${size})"
        log_backup "✅ MongoDB backup: ${size}"
        return 0
    else
        log_error "MongoDB backup failed"
        log_backup "❌ MongoDB backup failed"
        return 1
    fi
}

backup_mysql() {
    log_header "Backing up MySQL"
    mkdir -p "${BACKUP_DIR}/mysql"

    log_info "Dumping MySQL databases..."

    if [[ -z "${MYSQL_ROOT_PASSWORD:-}" ]]; then
        log_warning "MYSQL_ROOT_PASSWORD not set, skipping MySQL backup"
        return 1
    fi

    docker exec mysql sh -c "mysqldump -u root -p${MYSQL_ROOT_PASSWORD} --all-databases --single-transaction" | gzip > "${BACKUP_DIR}/mysql/mysql_all.sql.gz"

    if [[ -f "${BACKUP_DIR}/mysql/mysql_all.sql.gz" ]]; then
        local size
        size=$(du -h "${BACKUP_DIR}/mysql/mysql_all.sql.gz" | cut -f1)
        log_success "MySQL backup completed (${size})"
        log_backup "✅ MySQL backup: ${size}"
        return 0
    else
        log_error "MySQL backup failed"
        log_backup "❌ MySQL backup failed"
        return 1
    fi
}

backup_redis() {
    log_header "Backing up Redis"
    mkdir -p "${BACKUP_DIR}/redis"

    log_info "Saving Redis snapshot..."
    docker exec redis redis-cli SAVE

    log_info "Copying Redis dump..."
    docker cp redis:/data/dump.rdb "${BACKUP_DIR}/redis/dump.rdb"

    if [[ -f "${BACKUP_DIR}/redis/dump.rdb" ]]; then
        local size
        size=$(du -h "${BACKUP_DIR}/redis/dump.rdb" | cut -f1)
        log_success "Redis backup completed (${size})"
        log_backup "✅ Redis backup: ${size}"
        return 0
    else
        log_error "Redis backup failed"
        log_backup "❌ Redis backup failed"
        return 1
    fi
}

backup_volumes() {
    log_header "Backing up Critical Docker Volumes"
    mkdir -p "${BACKUP_DIR}/volumes"

    local volumes=(
        "infra-devtools_grafana_data"
        "infra-devtools_prometheus_data"
        "infra-devtools_alertmanager_data"
    )

    for vol in "${volumes[@]}"; do
        log_info "Backing up volume: ${vol}..."

        docker run --rm \
            -v "${vol}:/data:ro" \
            -v "${BACKUP_DIR}/volumes:/backup" \
            alpine:latest \
            tar -czf "/backup/${vol}.tar.gz" -C /data . 2>/dev/null || {
                log_warning "Volume ${vol} not found or empty, skipping"
                continue
            }

        if [[ -f "${BACKUP_DIR}/volumes/${vol}.tar.gz" ]]; then
            local size
            size=$(du -h "${BACKUP_DIR}/volumes/${vol}.tar.gz" | cut -f1)
            log_success "Volume ${vol} backed up (${size})"
            log_backup "✅ Volume ${vol}: ${size}"
        fi
    done
}

create_backup_manifest() {
    log_info "Creating backup manifest..."

    cat > "${BACKUP_DIR}/MANIFEST.txt" << EOF
Infra DevTools - Backup Manifest
═══════════════════════════════════════

Backup Date: $(date +'%Y-%m-%d %H:%M:%S')
Backup ID: $(basename "${BACKUP_DIR}")
Hostname: $(hostname)
User: $(whoami)

Contents:
─────────────────────────────────────────
EOF

    if [[ -d "${BACKUP_DIR}/postgresql" ]]; then
        echo "✅ PostgreSQL: $(du -sh "${BACKUP_DIR}/postgresql" | cut -f1)" >> "${BACKUP_DIR}/MANIFEST.txt"
    fi

    if [[ -d "${BACKUP_DIR}/mongodb" ]]; then
        echo "✅ MongoDB: $(du -sh "${BACKUP_DIR}/mongodb" | cut -f1)" >> "${BACKUP_DIR}/MANIFEST.txt"
    fi

    if [[ -d "${BACKUP_DIR}/mysql" ]]; then
        echo "✅ MySQL: $(du -sh "${BACKUP_DIR}/mysql" | cut -f1)" >> "${BACKUP_DIR}/MANIFEST.txt"
    fi

    if [[ -d "${BACKUP_DIR}/redis" ]]; then
        echo "✅ Redis: $(du -sh "${BACKUP_DIR}/redis" | cut -f1)" >> "${BACKUP_DIR}/MANIFEST.txt"
    fi

    if [[ -d "${BACKUP_DIR}/volumes" ]]; then
        echo "✅ Volumes: $(du -sh "${BACKUP_DIR}/volumes" | cut -f1)" >> "${BACKUP_DIR}/MANIFEST.txt"
    fi

    echo "" >> "${BACKUP_DIR}/MANIFEST.txt"
    echo "Total Backup Size: $(du -sh "${BACKUP_DIR}" | cut -f1)" >> "${BACKUP_DIR}/MANIFEST.txt"

    log_success "Manifest created"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔄 Restore Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

restore_postgresql() {
    local backup_id="$1"
    local backup_path="${BACKUP_BASE_DIR}/${backup_id}/postgresql/postgres_all.sql.gz"

    if [[ ! -f "$backup_path" ]]; then
        log_error "PostgreSQL backup not found: $backup_path"
        return 1
    fi

    log_warning "This will OVERWRITE current PostgreSQL data. Continue? (yes/no)"
    read -r confirm
    if [[ "$confirm" != "yes" ]]; then
        log_info "Restore cancelled"
        return 0
    fi

    log_info "Stopping dependent services..."
    docker compose stop pgadmin crud-users-api

    log_info "Restoring PostgreSQL..."
    gunzip -c "$backup_path" | docker exec -i postgres psql -U postgres

    log_info "Restarting services..."
    docker compose up -d

    log_success "PostgreSQL restore completed"
}

restore_mongodb() {
    local backup_id="$1"
    local backup_path="${BACKUP_BASE_DIR}/${backup_id}/mongodb/backup"

    if [[ ! -d "$backup_path" ]]; then
        log_error "MongoDB backup not found: $backup_path"
        return 1
    fi

    log_warning "This will OVERWRITE current MongoDB data. Continue? (yes/no)"
    read -r confirm
    if [[ "$confirm" != "yes" ]]; then
        log_info "Restore cancelled"
        return 0
    fi

    log_info "Restoring MongoDB..."
    docker cp "$backup_path" mongo:/tmp/backup
    docker exec mongo mongorestore --gzip --drop /tmp/backup
    docker exec mongo rm -rf /tmp/backup

    log_success "MongoDB restore completed"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧹 Utility Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cleanup_old_backups() {
    log_header "Cleaning up backups older than ${RETENTION_DAYS} days"

    if [[ ! -d "$BACKUP_BASE_DIR" ]]; then
        log_warning "No backup directory found"
        return 0
    fi

    local deleted=0
    while IFS= read -r -d '' backup; do
        log_info "Deleting old backup: $(basename "$backup")"
        rm -rf "$backup"
        ((deleted++))
    done < <(find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -mtime +${RETENTION_DAYS} -print0 2>/dev/null)

    if [[ $deleted -gt 0 ]]; then
        log_success "Deleted $deleted old backup(s)"
        log_backup "🧹 Cleanup: $deleted backup(s) deleted"
    else
        log_info "No old backups to delete"
    fi
}

list_backups() {
    log_header "Available Backups"

    if [[ ! -d "$BACKUP_BASE_DIR" ]] || [[ -z "$(ls -A "$BACKUP_BASE_DIR" 2>/dev/null)" ]]; then
        log_warning "No backups found in $BACKUP_BASE_DIR"
        return 0
    fi

    printf "%-20s %-15s %-30s\n" "BACKUP ID" "SIZE" "DATE"
    echo "───────────────────────────────────────────────────────────────"

    for backup in "$BACKUP_BASE_DIR"/*/; do
        if [[ -d "$backup" ]]; then
            local id
            id=$(basename "$backup")
            local size
            size=$(du -sh "$backup" 2>/dev/null | cut -f1)
            local date
            date=$(stat -c %y "$backup" 2>/dev/null | cut -d'.' -f1)
            printf "%-20s %-15s %-30s\n" "$id" "$size" "$date"
        fi
    done
}

setup_cron() {
    log_header "Setting up automated backups"

    local script_path
    script_path="$(realpath "$0")"
    local cron_entry="0 */4 * * * $script_path backup >> ${LOG_FILE} 2>&1"

    log_info "Cron job to add:"
    echo "$cron_entry"
    echo ""
    log_info "Add this to your crontab with: crontab -e"
    log_info "Or run: (crontab -l 2>/dev/null; echo \"$cron_entry\") | crontab -"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 Main Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

do_backup() {
    log_header "Starting Full Backup"
    log_backup "🚀 Starting backup: $(date +'%Y-%m-%d %H:%M:%S')"

    # Check Docker is running
    if ! check_docker; then
        die $EXIT_FAILURE "Docker is not running"
    fi

    # Create backup directory
    ensure_directory "$BACKUP_DIR" "Backup directory"

    local start_time
    start_time=$(date +%s)
    local failed=0

    # Execute backups
    backup_postgresql || ((failed++))
    backup_mongodb || ((failed++))
    backup_mysql || ((failed++))
    backup_redis || ((failed++))
    backup_volumes

    # Create manifest
    create_backup_manifest

    # Cleanup old backups
    cleanup_old_backups

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log_header "Backup Summary"
    log_info "Backup ID: $(basename "${BACKUP_DIR}")"
    log_info "Location: ${BACKUP_DIR}"
    log_info "Duration: ${duration}s"
    log_info "Total Size: $(du -sh "${BACKUP_DIR}" | cut -f1)"

    if [[ $failed -eq 0 ]]; then
        log_success "All backups completed successfully"
        log_backup "✅ Backup completed successfully in ${duration}s"
    else
        log_warning "Backup completed with $failed failure(s)"
        log_backup "⚠️ Backup completed with $failed failure(s) in ${duration}s"
    fi
}

do_restore() {
    local backup_id="$1"

    if [[ -z "$backup_id" ]]; then
        log_error "Usage: $0 restore YYYYMMDD_HHMMSS"
        list_backups
        return 1
    fi

    local backup_path="${BACKUP_BASE_DIR}/${backup_id}"
    if [[ ! -d "$backup_path" ]]; then
        log_error "Backup not found: $backup_id"
        list_backups
        return 1
    fi

    log_header "Restore from Backup: $backup_id"

    if [[ -f "${backup_path}/MANIFEST.txt" ]]; then
        cat "${backup_path}/MANIFEST.txt"
        echo ""
    fi

    log_warning "⚠️ RESTORE WILL OVERWRITE CURRENT DATA ⚠️"
    log_warning "Continue with restore? (yes/no)"
    read -r confirm

    if [[ "$confirm" != "yes" ]]; then
        log_info "Restore cancelled"
        return 0
    fi

    # Restore each service
    [[ -f "${backup_path}/postgresql/postgres_all.sql.gz" ]] && restore_postgresql "$backup_id"
    [[ -d "${backup_path}/mongodb/backup" ]] && restore_mongodb "$backup_id"

    log_success "Restore process completed"
}

show_help() {
    cat << 'EOF'
Infra DevTools - Backup System

USAGE:
    ./backup.sh <command> [options]

COMMANDS:
    backup              Create full backup of all databases and volumes
    restore <backup_id> Restore from specific backup
    list                List available backups
    cleanup             Remove backups older than retention period
    setup               Show cron setup instructions
    help                Show this help message

EXAMPLES:
    # Create backup
    ./backup.sh backup

    # List backups
    ./backup.sh list

    # Restore specific backup
    ./backup.sh restore 20251106_153000

    # Clean old backups
    ./backup.sh cleanup

    # Setup cron job
    ./backup.sh setup

CONFIGURATION:
    Retention: 30 days (configurable in script)
    Backup Location: ./backups/
    Log Location: ./logs/backup.log

DATABASES BACKED UP:
    ✅ PostgreSQL (all databases)
    ✅ MongoDB (all databases)
    ✅ MySQL (all databases)
    ✅ Redis (dump.rdb)

VOLUMES BACKED UP:
    ✅ Grafana data
    ✅ Prometheus data
    ✅ Alertmanager data
EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 Main Entry Point
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    local command="${1:-help}"

    case "$command" in
        backup)
            do_backup
            ;;
        restore)
            do_restore "$2"
            ;;
        list)
            list_backups
            ;;
        cleanup)
            cleanup_old_backups
            ;;
        setup)
            setup_cron
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit $EXIT_INVALID_ARGS
            ;;
    esac
}

# Execute main function
main "$@"
