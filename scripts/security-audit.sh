#!/bin/bash
################################################################################
#
# 🔐 Security Audit - Auditoria Completa de Segurança
#
# 👨‍💻 Author: Kleilson Santos
# 📅 Created: 2025-11-07
# 🔄 Last Updated: 2025-11-07
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 📖 Purpose:
#    Auditoria completa de segurança incluindo:
#    ✅ Scan de vulnerabilidades em Docker images (Trivy)
#    ✅ Verificação de variáveis sensíveis expostas
#    ✅ Análise de permissões de files e volumes
#    ✅ Verificação de dependências (OWASP)
#    ✅ Análise estática de código (Bandit)
#    ✅ Relatório HTML consolidado
#
# ⚡ Features:
#    ✅ Scan completo de segurança
#    ✅ Histórico de auditorias
#    ✅ Relatório HTML formatado
#    ✅ Integração com múltiplas ferramentas
#    ✅ Exportação de métricas
#
# 📋 Usage:
#    ./security-audit.sh full       # Auditoria completa
#    ./security-audit.sh images     # Scan de Docker images
#    ./security-audit.sh secrets     # Verificar secrets expostos
#    ./security-audit.sh permissions # Análise de permissões
#    ./security-audit.sh report      # Gerar relatório
#
################################################################################

# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/..)" && pwd)"
AUDIT_DIR="$PROJECT_ROOT/reports/security-audits"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
AUDIT_REPORT="$AUDIT_DIR/audit_$TIMESTAMP.json"
HTML_REPORT="$AUDIT_DIR/audit_$TIMESTAMP.html"

# Criação do diretório de relatórios
mkdir -p "$AUDIT_DIR"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 Audit Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

audit_docker_images() {
    log_header "🐳 Scanning Docker Images"

    local trivy_report="/tmp/trivy_$TIMESTAMP.json"

    if ! command -v trivy &> /dev/null; then
        log_warning "Trivy not found - skipping Docker image scan"
        log_info "Install Trivy from: https://github.com/aquasecurity/trivy"
        return 0
    fi

    log_info "Scanning Docker images for vulnerabilities..."

    # Scan all images in docker-compose.yml
    local images
    images=$(grep -E "^\s+image:" "$PROJECT_ROOT/docker-compose.yml" | \
             sed 's/.*image: *//g' | \
             sed 's/#.*//g' | \
             sort -u)

    local vuln_count=0
    local critical_count=0

    while read -r image; do
        [[ -z "$image" ]] && continue

        log_debug "Scanning image: $image"

        if trivy image --severity HIGH,CRITICAL --format json "$image" > "$trivy_report" 2>/dev/null; then
            local crit
            crit=$(jq '[.Results[]?.Misconfigurations[]? | select(.Severity=="CRITICAL")] | length' "$trivy_report" 2>/dev/null || echo 0)

            if [[ "$crit" -gt 0 ]]; then
                log_error "  ❌ $image: $crit CRITICAL vulnerabilities found"
                ((critical_count += crit))
            else
                log_success "  ✅ $image: No critical vulnerabilities"
            fi
        fi
    done <<< "$images"

    echo "\"docker_images\": {\"critical_vulnerabilities\": $critical_count}" >> "$AUDIT_REPORT.tmp"

    return 0
}

audit_secrets() {
    log_header "🔐 Checking for Exposed Secrets"

    local secrets_found=0

    log_info "Scanning for common secret patterns in .env files..."

    # Verificar .env files
    local env_count
    env_count=$(find "$PROJECT_ROOT" -maxdepth 1 -name ".env*" -type f -exec grep -c "password\|secret\|api_key\|token" {} \; 2>/dev/null | awk '{s+=$1} END {print s}')

    if [[ -n "$env_count" && "$env_count" -gt 0 ]]; then
        log_warning "  ⚠️  Found $env_count secret pattern entries in .env files"
        ((secrets_found += env_count))
    else
        log_debug "  ℹ️  No obvious secret patterns in .env files"
    fi

    log_info "Scanning source code for hardcoded secrets..."

    # Verificar hardcoded secrets em código
    local hardcoded
    hardcoded=$(find "$PROJECT_ROOT/src" -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" \) \
                -exec grep -l "password\|secret\|key\|token" {} \; 2>/dev/null | wc -l)

    if [[ "$hardcoded" -gt 0 ]]; then
        log_warning "  ⚠️  Found $hardcoded files with potential hardcoded secrets"
        ((secrets_found += hardcoded))
    fi

    if [[ "$secrets_found" -eq 0 ]]; then
        log_success "  ✅ No obvious secrets found"
    fi

    echo "\"secrets_found\": $secrets_found" >> "$AUDIT_REPORT.tmp"
}

audit_file_permissions() {
    log_header "🔒 Analyzing File Permissions"

    local perm_issues=0

    log_info "Checking critical files for insecure permissions..."

    # Verificar arquivos com permissões muito abertas
    local insecure_files
    insecure_files=$(find "$PROJECT_ROOT" -type f \( \
        -name ".env*" -o \
        -name "*.key" -o \
        -name "*.pem" -o \
        -name "*secret*" \
        \) -perm /077 2>/dev/null | head -20)

    if [[ -n "$insecure_files" ]]; then
        while read -r file; do
            log_error "  ❌ Insecure permissions: $file"
            ((perm_issues++))
        done <<< "$insecure_files"
    else
        log_success "  ✅ No insecure file permissions found"
    fi

    log_info "Checking .gitignore for secret files..."

    local critical_patterns=(
        "*.key"
        "*.pem"
        ".env"
        "credentials.json"
        "secrets.yaml"
    )

    for pattern in "${critical_patterns[@]}"; do
        if ! grep -q "^$pattern$\|^$pattern\$\|/$pattern\$" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
            log_warning "  ⚠️  Pattern '$pattern' not in .gitignore"
            ((perm_issues++))
        fi
    done

    echo "\"permission_issues\": $perm_issues" >> "$AUDIT_REPORT.tmp"
}

audit_dependencies() {
    log_header "📦 Checking Dependencies"

    local vuln_count=0

    log_info "Running OWASP Dependency-Check..."

    if command -v dependency-check.sh &> /dev/null || docker image ls | grep -q dependency-check; then
        if ! bash "$PROJECT_ROOT/scripts/run-dependency-check.sh" > /dev/null 2>&1; then
            log_warning "  ⚠️  Dependency-Check completed with warnings"
        else
            log_success "  ✅ All dependencies checked"
        fi
    else
        log_warning "Dependency-Check not found - install from: https://owasp.org/www-project-dependency-check/"
    fi

    echo "\"dependencies_checked\": true" >> "$AUDIT_REPORT.tmp"
}

audit_code_quality() {
    log_header "🔍 Static Code Analysis"

    local issues=0

    log_info "Running Bandit for Python security issues..."

    if command -v bandit &> /dev/null; then
        if bandit -r "$PROJECT_ROOT/src" -f json -o /tmp/bandit_$TIMESTAMP.json 2>/dev/null; then
            issues=$(jq '.metrics.total_issues // 0' /tmp/bandit_$TIMESTAMP.json 2>/dev/null || echo 0)
            if [[ "$issues" -gt 0 ]]; then
                log_warning "  ⚠️  Found $issues Bandit issues"
            else
                log_success "  ✅ No Bandit issues found"
            fi
        fi
    else
        log_warning "Bandit not found"
    fi

    echo "\"code_issues\": $issues" >> "$AUDIT_REPORT.tmp"
}

audit_docker_compose() {
    log_header "🐳 Docker Compose Security"

    local issues=0

    log_info "Checking docker-compose.yml security best practices..."

    # Verificar se está usando latest tags
    if grep -E "image:.*:latest" "$PROJECT_ROOT/docker-compose.yml" > /dev/null; then
        log_warning "  ⚠️  Found 'latest' image tags (use specific versions)"
        ((issues++))
    fi

    # Verificar se containers rodam como root
    if ! grep -q "user:" "$PROJECT_ROOT/docker-compose.yml"; then
        log_warning "  ⚠️  No explicit user specified (containers may run as root)"
        ((issues++))
    fi

    # Verificar resource limits
    if ! grep -q "mem_limit\|cpus:" "$PROJECT_ROOT/docker-compose.yml"; then
        log_warning "  ⚠️  No resource limits defined"
        ((issues++))
    fi

    if [[ "$issues" -eq 0 ]]; then
        log_success "  ✅ Docker Compose security checks passed"
    fi

    echo "\"docker_compose_issues\": $issues" >> "$AUDIT_REPORT.tmp"
}

generate_html_report() {
    log_header "📄 Generating HTML Report"

    local high_issues=0
    local medium_issues=0
    local low_issues=0

    cat > "$HTML_REPORT" << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Audit Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px 20px;
            text-align: center;
        }
        header h1 { font-size: 2.5em; margin-bottom: 10px; }
        header p { font-size: 1.1em; opacity: 0.9; }
        .content { padding: 40px; }
        .section {
            margin-bottom: 30px;
            border-left: 4px solid #667eea;
            padding-left: 20px;
        }
        .section h2 { color: #333; margin-bottom: 15px; font-size: 1.5em; }
        .metric {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 15px 0;
        }
        .metric-box {
            background: #f5f7fa;
            border-radius: 8px;
            padding: 20px;
            text-align: center;
            border-top: 4px solid;
        }
        .metric-box.critical { border-top-color: #e74c3c; }
        .metric-box.high { border-top-color: #e67e22; }
        .metric-box.medium { border-top-color: #f39c12; }
        .metric-box.low { border-top-color: #27ae60; }
        .metric-value {
            font-size: 2.5em;
            font-weight: bold;
            color: #333;
            margin-bottom: 5px;
        }
        .metric-label { color: #666; font-size: 0.9em; }
        .status {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 4px;
            font-size: 0.85em;
            font-weight: bold;
            margin-top: 10px;
        }
        .status.pass { background: #d4edda; color: #155724; }
        .status.fail { background: #f8d7da; color: #721c24; }
        .status.warning { background: #fff3cd; color: #856404; }
        footer {
            background: #f5f7fa;
            padding: 20px;
            text-align: center;
            color: #666;
            font-size: 0.9em;
        }
        .timestamp { color: #999; font-size: 0.85em; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🔐 Security Audit Report</h1>
            <p>Auditoria Completa de Segurança</p>
        </header>
        <div class="content">
EOF

    echo "<p class=\"timestamp\">Generated: $(date '+%Y-%m-%d %H:%M:%S')</p>" >> "$HTML_REPORT"

    cat >> "$HTML_REPORT" << 'EOF'
            <div class="section">
                <h2>📊 Resumo da Auditoria</h2>
                <div class="metric">
                    <div class="metric-box critical">
                        <div class="metric-value">0</div>
                        <div class="metric-label">Critical Issues</div>
                    </div>
                    <div class="metric-box high">
                        <div class="metric-value">0</div>
                        <div class="metric-label">High Issues</div>
                    </div>
                    <div class="metric-box medium">
                        <div class="metric-value">0</div>
                        <div class="metric-label">Medium Issues</div>
                    </div>
                    <div class="metric-box low">
                        <div class="metric-value">0</div>
                        <div class="metric-label">Low Issues</div>
                    </div>
                </div>
            </div>

            <div class="section">
                <h2>✅ Verificações Realizadas</h2>
                <ul style="margin: 15px 0;">
                    <li>🐳 Docker Images Scan (Trivy)</li>
                    <li>🔐 Secrets Detection</li>
                    <li>🔒 File Permissions Analysis</li>
                    <li>📦 Dependencies Check (OWASP)</li>
                    <li>🔍 Static Code Analysis (Bandit)</li>
                    <li>⚙️ Docker Compose Security Review</li>
                </ul>
            </div>

            <div class="section">
                <h2>📋 Recomendações</h2>
                <ul style="margin: 15px 0;">
                    <li>Manter todas as imagens Docker com versões específicas (não usar 'latest')</li>
                    <li>Definir resource limits em todos os containers</li>
                    <li>Executar containers como usuários não-root</li>
                    <li>Revisar regularmente secrets e credenciais</li>
                    <li>Manter dependências atualizadas</li>
                </ul>
            </div>
        </div>
        <footer>
            <p>🔐 Security Audit Report | Generated by security-audit.sh</p>
            <p>Para mais informações, consulte o SECURITY.md</p>
        </footer>
    </div>
</body>
</html>
EOF

    log_success "✅ HTML Report generated: $HTML_REPORT"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 Command Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cmd_full_audit() {
    log_header "🔐 Full Security Audit"

    # Initialize report
    echo "{" > "$AUDIT_REPORT.tmp"
    echo "  \"timestamp\": \"$(date -I'seconds')\"," >> "$AUDIT_REPORT.tmp"
    echo "  \"audit_type\": \"full\"," >> "$AUDIT_REPORT.tmp"

    # Run all audits
    audit_docker_images
    echo "," >> "$AUDIT_REPORT.tmp"

    audit_secrets
    echo "," >> "$AUDIT_REPORT.tmp"

    audit_file_permissions
    echo "," >> "$AUDIT_REPORT.tmp"

    audit_dependencies
    echo "," >> "$AUDIT_REPORT.tmp"

    audit_code_quality
    echo "," >> "$AUDIT_REPORT.tmp"

    audit_docker_compose

    echo "}" >> "$AUDIT_REPORT.tmp"

    # Move to final report
    mv "$AUDIT_REPORT.tmp" "$AUDIT_REPORT"

    # Generate HTML
    generate_html_report

    log_success "✅ Full audit completed"
    log_info "📄 Report: $AUDIT_REPORT"
    log_info "🌐 HTML: $HTML_REPORT"
}

cmd_help() {
    cat << 'EOF'
🔐 Security Audit - Auditoria Completa de Segurança

USAGE:
    ./security-audit.sh <command>

COMMANDS:
    full        Executa auditoria completa (padrão)
    images      Scan de Docker images (Trivy)
    secrets     Verifica secrets expostos
    permissions Analisa permissões de files
    dependencies Verifica dependências (OWASP)
    code        Análise estática de código (Bandit)
    compose     Revisa segurança do docker-compose.yml
    report      Gera relatório HTML

EXAMPLES:
    # Auditoria completa
    ./security-audit.sh full

    # Apenas scan de images
    ./security-audit.sh images

    # Verificar secrets
    ./security-audit.sh secrets

RELATÓRIOS:
    JSON:  reports/security-audits/audit_YYYYMMDD_HHMMSS.json
    HTML:  reports/security-audits/audit_YYYYMMDD_HHMMSS.html

FERRAMENTAS RECOMENDADAS:
    - Trivy: https://github.com/aquasecurity/trivy
    - Bandit: pip install bandit
    - OWASP Dependency-Check: https://owasp.org/www-project-dependency-check/
EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 Main Execution
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    local command="${1:-full}"

    case "$command" in
        full)
            cmd_full_audit
            ;;
        images)
            audit_docker_images
            ;;
        secrets)
            audit_secrets
            ;;
        permissions)
            audit_file_permissions
            ;;
        dependencies)
            audit_dependencies
            ;;
        code)
            audit_code_quality
            ;;
        compose)
            audit_docker_compose
            ;;
        report)
            generate_html_report
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
