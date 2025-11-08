#!/bin/bash

################################################################################
#
# 🔀 Canonical Workflow Automation - OPÇÃO 3→2→1 Completo
#
# 👨‍💻 Author: Kleilson Santos
# 📅 Created: 2025-11-07
# 🔄 Last Updated: 2025-11-07
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 📖 Purpose:
#    Orquestrar execução completa do Protocolo Canônico 3→2→1
#    ✅ OPÇÃO 3 (Ler): Validação de análise
#    ✅ OPÇÃO 2 (Testar): Execução de 7 testes
#    ✅ OPÇÃO 1 (Mergear): Automação de merge
#
# 📋 Usage:
#    ./canonical-workflow-automation.sh <PR_NUMBER> [--auto] [--skip-merge]
#    ./canonical-workflow-automation.sh 42
#    ./canonical-workflow-automation.sh 42 --auto (pula confirmações)
#    ./canonical-workflow-automation.sh 42 --skip-merge (para em OPÇÃO 2)
#
################################################################################

set -euo pipefail

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PR_NUMBER=""
AUTO_MODE="${AUTO_MODE:-false}"
SKIP_MERGE="${SKIP_MERGE:-false}"
VERBOSE="${VERBOSE:-false}"

# Colors are defined in lib.sh (already readonly)

# Script directory
SCRIPT_DIR="$(dirname "$0")"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

usage() {
    cat << 'EOF'
🔀 Canonical Workflow Automation - Protocolo Canônico 3→2→1

USAGE:
    ./canonical-workflow-automation.sh <PR_NUMBER> [OPTIONS]

ARGUMENTS:
    PR_NUMBER       Número da PR (ex: 42)

OPTIONS:
    --auto              Pular confirmações (não interativo)
    --skip-merge        Parar após OPÇÃO 2 (não fazer merge)
    --verbose           Mostrar detalhes completos
    --help              Mostrar esta ajuda

EXEMPLOS:
    # Executar workflow completo interativo
    ./canonical-workflow-automation.sh 42

    # Auto-mode: pula confirmações
    ./canonical-workflow-automation.sh 42 --auto

    # Parar após validações (sem merge)
    ./canonical-workflow-automation.sh 42 --skip-merge

WORKFLOW:
    1️⃣  OPÇÃO 3 (Ler): Análise Técnica Completa
    2️⃣  OPÇÃO 2 (Testar): 7 Validações Obrigatórias
    3️⃣  OPÇÃO 1 (Mergear): Integração Formal

EOF
}

confirm_action() {
    local prompt="$1"
    local response

    if [[ "$AUTO_MODE" == "true" ]]; then
        return 0
    fi

    echo -ne "${YELLOW}$prompt${NC} (s/N): "
    read -r response

    if [[ "$response" =~ ^[Ss]$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_pr_number() {
    local pr_number="$1"

    if [[ ! "$pr_number" =~ ^[0-9]+$ ]]; then
        log_error "PR_NUMBER deve ser um número válido"
        exit 1
    fi

    if [[ "$pr_number" -lt 1 ]]; then
        log_error "PR_NUMBER deve ser maior que 0"
        exit 1
    fi
}

check_scripts_exist() {
    log_header "🔍 Verificando Dependências"

    local scripts_needed=(
        "enforce-pr-validation.sh"
        "merge-pr.sh"
    )

    for script in "${scripts_needed[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$script" ]]; then
            log_error "Script não encontrado: $SCRIPT_DIR/$script"
            return 1
        fi
        log_success "✅ $script encontrado"
    done

    return 0
}

print_workflow_header() {
    echo ""
    echo -e "${MAGENTA}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${MAGENTA}│ 🔀 PROTOCOLO CANÔNICO 3→2→1 - WORKFLOW COMPLETO        │${NC}"
    echo -e "${MAGENTA}│                                                         │${NC}"
    echo -e "${MAGENTA}│ 3️⃣ OPÇÃO 3 (Ler): Análise Técnica Completa             │${NC}"
    echo -e "${MAGENTA}│ 2️⃣ OPÇÃO 2 (Testar): 7 Validações Obrigatórias        │${NC}"
    echo -e "${MAGENTA}│ 1️⃣ OPÇÃO 1 (Mergear): Integração Formal                │${NC}"
    echo -e "${MAGENTA}│                                                         │${NC}"
    echo -e "${MAGENTA}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""

    log_info "PR Number: #$PR_NUMBER"
    log_info "Modo: $([ "$AUTO_MODE" = "true" ] && echo "AUTO" || echo "INTERATIVO")"
    echo ""
}

execute_opcao_3() {
    log_header "📋 OPÇÃO 3: Ler (Análise Técnica)"

    echo ""
    log_info "Instruções:"
    log_info "1. Revisar documentação: docs/CANONICAL-OPÇÃO-3-LEITURA.md"
    log_info "2. Responder 12 perguntas obrigatórias"
    log_info "3. Validar que TODAS questões críticas (1-5) passaram"
    echo ""

    if ! confirm_action "Você completou OPÇÃO 3? (Todas 12 perguntas respondidas?)"; then
        log_error "OPÇÃO 3 não foi completada. Abortando workflow."
        exit 1
    fi

    log_success "✅ OPÇÃO 3 COMPLETA"
    echo ""
}

execute_opcao_2() {
    log_header "🧪 OPÇÃO 2: Testar (Validações)"

    echo ""
    log_info "Executando 7 testes obrigatórios..."
    log_info "Isso pode levar 15-30 minutos (maioria é automatizada)"
    echo ""

    local enforce_script="$SCRIPT_DIR/enforce-pr-validation.sh"

    # Executar validate script
    if ! "$enforce_script" "$PR_NUMBER" --verbose; then
        log_error "❌ OPÇÃO 2 FALHOU - Alguns testes não passaram"
        log_error "Corrija os problemas e execute novamente:"
        log_error "  $enforce_script #$PR_NUMBER"
        exit 1
    fi

    log_success "✅ OPÇÃO 2 COMPLETA - 7/7 TESTES PASSARAM"
    echo ""
}

execute_opcao_1() {
    if [[ "$SKIP_MERGE" == "true" ]]; then
        log_warn "⚠️ --skip-merge ativado: Pulando OPÇÃO 1"
        log_info "Para fazer merge, execute:"
        log_info "  $SCRIPT_DIR/merge-pr.sh #$PR_NUMBER"
        return 0
    fi

    log_header "1️⃣ OPÇÃO 1: Mergear (Integração)"

    echo ""
    log_info "Fazendo merge de PR #$PR_NUMBER com protocolo..."
    log_info "Tipo: Merge commit (--no-ff)"
    log_info "Mensagem: Padrão com documentação de protocolo"
    echo ""

    if ! confirm_action "Proceder com merge de PR #$PR_NUMBER?"; then
        log_warn "⚠️ Merge cancelado"
        log_info "Para fazer merge depois, execute:"
        log_info "  $SCRIPT_DIR/merge-pr.sh #$PR_NUMBER"
        exit 0
    fi

    local merge_script="$SCRIPT_DIR/merge-pr.sh"

    # Executar merge script
    if ! "$merge_script" "$PR_NUMBER" --verbose; then
        log_error "❌ OPÇÃO 1 FALHOU - Erro ao fazer merge"
        exit 1
    fi

    log_success "✅ OPÇÃO 1 COMPLETA"
    echo ""
}

print_workflow_summary() {
    echo ""
    echo -e "${GREEN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│ ✅ PROTOCOLO CANÔNICO 3→2→1 COMPLETO                  │${NC}"
    echo -e "${GREEN}│                                                         │${NC}"
    echo -e "${GREEN}│ 3️⃣ OPÇÃO 3 (Ler): ✅ Análise Técnica Completa           │${NC}"
    echo -e "${GREEN}│ 2️⃣ OPÇÃO 2 (Testar): ✅ 7/7 Testes Passaram            │${NC}"
    echo -e "${GREEN}│ 1️⃣ OPÇÃO 1 (Mergear): ✅ Integração Formal             │${NC}"
    echo -e "${GREEN}│                                                         │${NC}"
    echo -e "${GREEN}│ 🎉 PR #$PR_NUMBER mergeada com sucesso                │${NC}"
    echo -e "${GREEN}│ 📍 Main branch atualizada                              │${NC}"
    echo -e "${GREEN}│ 📊 Histórico completo e rastreável                     │${NC}"
    echo -e "${GREEN}│                                                         │${NC}"
    echo -e "${GREEN}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""

    log_info "Próximos passos:"
    log_info "1. Verificar GitHub Actions em main"
    log_info "2. Validar que deploy foi acionado (se automático)"
    log_info "3. Monitorar aplicação em produção"
    echo ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main Execution
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    # Parse arguments
    if [[ $# -eq 0 ]]; then
        usage
        exit 1
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                usage
                exit 0
                ;;
            --auto)
                AUTO_MODE="true"
                shift
                ;;
            --skip-merge)
                SKIP_MERGE="true"
                shift
                ;;
            --verbose)
                VERBOSE="true"
                shift
                ;;
            *)
                if [[ -z "$PR_NUMBER" ]]; then
                    PR_NUMBER="$1"
                fi
                shift
                ;;
        esac
    done

    # Validate PR number
    validate_pr_number "$PR_NUMBER"

    # Print header
    print_workflow_header

    # Check scripts exist
    if ! check_scripts_exist; then
        log_error "Dependências não encontradas"
        exit 1
    fi
    echo ""

    # Execute OPÇÃO 3
    execute_opcao_3

    # Execute OPÇÃO 2
    execute_opcao_2

    # Execute OPÇÃO 1
    execute_opcao_1

    # Print summary
    print_workflow_summary

    exit 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main "$@"
