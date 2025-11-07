# 📋 Guia de Contribuição — Infra DevTools

Este documento estabelece os padrões de desenvolvimento para o **Infra DevTools** — uma infraestrutura DevOps profissional com Docker, monitoring e quality assurance.

---

## 🎯 Fluxo de Trabalho

### 1️⃣ **Conventional Commits** (Commits Semânticos)

Todo commit deve seguir o padrão **Conventional Commits**:

```
<tipo>(<escopo>): <descrição>

<corpo (opcional)>

<rodapé (opcional)>
```

### Tipos de Commit

| Tipo | Descrição | Impacto | Exemplo |
|------|-----------|---------|---------|
| **feat** | Nova feature/funcionalidade | Minor (v1.X.0) | `feat(monitoring): adicionar alertas Prometheus` |
| **fix** | Correção de bug | Patch (v1.2.X) | `fix(docker): corrigir health checks` |
| **docs** | Documentação | Nenhum | `docs: atualizar CONTRIBUTING.md` |
| **style** | Formatação de código | Nenhum | `style: formatar com Black e Prettier` |
| **refactor** | Refatoração sem mudar comportamento | Nenhum | `refactor(scripts): usar lib.sh compartilhada` |
| **perf** | Melhoria de performance | Patch (v1.2.X) | `perf(prometheus): otimizar queries` |
| **test** | Adicionar/atualizar testes | Nenhum | `test(integration): adicionar testes Docker` |
| **chore** | Tarefas gerais (deps, config) | Nenhum | `chore: atualizar dependências npm` |
| **ci** | Mudanças em CI/CD | Nenhum | `ci: adicionar matrix testing` |

### Exemplos Completos

#### ✅ Feature com corpo
```
feat(backup): implementar sistema de backup automatizado

Adiciona scripts/backup.sh com suporte a PostgreSQL, MongoDB, MySQL e Redis.
Integra com cron para execução automática a cada 4 horas.
Retenção de 30 dias configurável.

Closes #45
```

#### ✅ Fix com breaking change
```
fix(docker)!: refatorar network configuration

BREAKING CHANGE: Nome da network mudou de 'default' para 'infra-default-shared-net'

Afeta: Todos os serviços no docker-compose.yml
Solução: Executar 'make down' e 'make up' para recriar network
```

#### ✅ Simples
```
docs: adicionar seção de troubleshooting ao README
```

---

### 🔐 **Autor e Assinatura de Commits (OBRIGATÓRIO)**

**TODOS os commits devem ser assinados com o autor correto:**

```bash
git config user.name "Kleilson Santos"
git config user.email "kleilsonsantos0907@gmail.com"

# Commit com assinatura
git commit -m "feat: descrição" \
  --author="Kleilson Santos <kleilsonsantos0907@gmail.com>" \
  -S  # (opcional: GPG sign)
```

#### ❌ PROIBIDO (Não faça isto)
```
Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: [Assistente AI]
Author: GitHub Actions <actions@github.com>
Signed-off-by: bot@example.com
```

#### ✅ OBRIGATÓRIO
```
Author: Kleilson Santos <kleilsonsantos0907@gmail.com>
Signed-off-by: Kleilson Santos <kleilsonsantos0907@gmail.com>
```

**Por quê?**
- Rastreabilidade profissional (auditoria exata)
- Responsabilidade legal pelos commits
- Histórico profissional e verificável
- Padrão industry (GitHub, GitLab, Kubernetes, CNCF)

---

## 📌 Versionamento Semântico (SemVer)

Seguimos **Semantic Versioning** (`MAJOR.MINOR.PATCH`):

### Format: `vX.Y.Z`

```
v1.2.9
│ │ │
│ │ └─ PATCH (1.2.X) — Bugfixes, melhorias
│ └─── MINOR (1.X.0) — Novas features, compatível
└───── MAJOR (X.0.0) — Breaking changes
```

### Quando Incrementar?

| Tipo de Mudança | Versão | Exemplo |
|-----------------|--------|---------|
| **feat:** | MINOR | v1.2.0 → v1.3.0 |
| **fix:** / **perf:** | PATCH | v1.2.0 → v1.2.1 |
| **BREAKING CHANGE** | MAJOR | v1.2.0 → v2.0.0 |
| **docs, style, test, chore, ci** | Nenhum | Não incrementa versão |

### Exemplos

```bash
# Adicionar feature → MINOR
make version-minor  # 1.2.9 → 1.3.0
git push --tags

# Corrigir bug → PATCH
make version-patch  # 1.2.9 → 1.2.10
git push --tags

# Breaking change → MAJOR
make version-major  # 1.2.9 → 2.0.0
git push --tags
```

---

## 🔄 Pull Requests — Workflow Obrigatório

### 🚨 **ATENÇÃO: PR OBRIGATÓRIO**

**⚠️ TODAS as mudanças DEVEM usar Pull Requests - sem exceções:**

- ❌ **PROIBIDO**: Merge direto em `main`
- ❌ **PROIBIDO**: Push direto para branch principal
- ✅ **OBRIGATÓRIO**: Criar PR para QUALQUER mudança
- ✅ **OBRIGATÓRIO**: Code review antes de mergear
- ✅ **OBRIGATÓRIO**: GitHub Actions green antes do merge

### 🎯 Workflow com PRs — Passo a Passo

#### 1️⃣ Criar Feature Branch
```bash
git checkout main
git pull origin main
git checkout -b feat/minha-feature
```

#### 2️⃣ Fazer Commits Semânticos
```bash
git add .
git commit -m "feat(escopo): descrição clara"
```

#### 3️⃣ Push da Branch
```bash
git push -u origin feat/minha-feature
```

#### 4️⃣ Abrir PR no GitHub

Ir em: `https://github.com/KleilsonSantos/infra-devtools/compare/feat/minha-feature`

**PR Title:**
```
feat(escopo): descrição clara
```

**PR Body:** (Template recomendado)
```markdown
## 📋 Descrição
Breve descrição da mudança e por quê.

## 🎯 Tipo de Mudança
- [ ] ✨ Nova feature
- [ ] 🐛 Bug fix
- [ ] 📚 Documentação
- [ ] 🔧 Refatoração
- [ ] ⚡ Performance
- [ ] ✅ Testes
- [ ] 🔒 Segurança

## ✅ Checklist
- [ ] Código testado localmente (`make test-all`)
- [ ] Linters executados (`make lint-python`)
- [ ] Documentação atualizada
- [ ] Sem conflitos com main
- [ ] Commits semânticos
- [ ] GitHub Actions green
- [ ] SECURITY.md revisado (se aplicável)
```

#### 5️⃣ Merge da PR

Na interface do GitHub:
1. Aguardar GitHub Actions completar (✅ green)
2. Solicitar code review
3. Após aprovação, clicar em **Merge pull request**
4. Escolher "Squash and merge" ou "Create a merge commit"
5. Confirmar merge

#### 6️⃣ Atualizar Local
```bash
git checkout main
git pull origin main
git branch -d feat/minha-feature  # Deletar branch local
```

### 📊 Exemplo Completo com PR

```bash
# 1. Feature branch
git checkout -b feat/backup-system

# 2. Commits
git commit -m "feat(backup): add PostgreSQL backup script"
git commit -m "feat(backup): add cron scheduling"
git commit -m "docs(backup): update README with usage"

# 3. Push
git push -u origin feat/backup-system

# 4. Abrir PR no GitHub (via browser)
# Título: feat(backup): implement automated backup system
# Body: [descrição profissional com checklist]

# 5. Aguardar GitHub Actions + Code Review
# 6. Merge via GitHub interface

# 7. Local update
git checkout main
git pull origin main
```

### 🏷️ Padrão de PR Title

```
<tipo>(<escopo>): <descrição>

Exemplos:
✅ feat(monitoring): add Prometheus alerts
✅ fix(docker): resolve health check timeout
✅ docs(readme): update installation instructions
✅ chore(deps): update npm dependencies
```

### ✅ PR Checklist

Antes de criar PR, valide:

- [ ] Branch criada a partir de `main` atualizado
- [ ] Todos os commits têm mensagens semânticas
- [ ] Código testado localmente (`make test-all`)
- [ ] Linters passam sem erros (`make lint-python`, `npm run lint`)
- [ ] Sem conflitos de merge
- [ ] Documentação atualizada (README, CHANGELOG, etc.)
- [ ] Nenhum arquivo sensível (`.env`, secrets, credentials)
- [ ] PR title segue padrão `type(scope): description`
- [ ] PR body tem descrição profissional com checklist
- [ ] GitHub Actions green (CI pipeline passed)

### 🚨 Regras Obrigatórias

```
❌ NÃO fazer merge direto em main
❌ NÃO commitar sem PR (exceto hotfixes críticos pré-aprovados)
❌ NÃO usar force push em branches compartilhadas
❌ NÃO commitar .env, secrets, credentials
❌ NÃO mergear com GitHub Actions failing
✅ SEMPRE criar PR antes de mergear
✅ SEMPRE usar Conventional Commits
✅ SEMPRE aguardar code review
✅ SEMPRE aguardar CI green
```

---

## 🔴 **PROTOCOLO CANÔNICO: Sequência 3 → 2 → 1** (OBRIGATÓRIO)

A análise e merge de qualquer PR deve seguir esta sequência **EXATAMENTE** nesta ordem.

**Documentação Completa e Scripts Automatizados:**
- 📖 [CANONICAL-WORKFLOW.md](./docs/CANONICAL-WORKFLOW.md) — Protocolo completo e detalhado
- ✅ [CANONICAL-OPÇÃO-3-LEITURA.md](./docs/CANONICAL-OPÇÃO-3-LEITURA.md) — Checklist interativo OPÇÃO 3
- 🧪 [CANONICAL-OPÇÃO-2-TESTES.md](./docs/CANONICAL-OPÇÃO-2-TESTES.md) — Checklist interativo OPÇÃO 2
- 1️⃣ [CANONICAL-OPÇÃO-1-MERGE.md](./docs/CANONICAL-OPÇÃO-1-MERGE.md) — Checklist interativo OPÇÃO 1
- 🔒 [BRANCH-PROTECTION-SETUP.md](./docs/BRANCH-PROTECTION-SETUP.md) — Configuração de branch protection
- 📊 [PR-MAPPING.md](./docs/PR-MAPPING.md) — Histórico formal de PRs mergeadas

**Scripts para Automação:**
```bash
# Validar que OPÇÃO 2 (7 testes) foram completados
./scripts/enforce-pr-validation.sh #PR_NUMBER --verbose

# Fazer merge com protocolo padronizado
./scripts/merge-pr.sh #PR_NUMBER --author "Nome" --reviewer "Nome"

# Orquestrar workflow completo (OPÇÃO 3 → 2 → 1)
./scripts/canonical-workflow-automation.sh #PR_NUMBER --auto
```

### **OPÇÃO 3️⃣: Ler Documentação** (10-15 minutos)

**O que fazer:**
1. Ler descrição completa da PR
2. Revisar:
   - Estatísticas (commits, arquivos modificados, linhas)
   - Arquivos modificados/adicionados/removidos
   - Checklist de qualidade
   - Pontos de atenção
   - Impacto na codebase
   - Recomendação final

**Questões a responder:**
- [ ] O que exatamente a PR adiciona/modifica/remove?
- [ ] Há breaking changes?
- [ ] Há conflitos com main?
- [ ] Há riscos de produção?
- [ ] Está alinhada com os objetivos do projeto?
- [ ] Documentação foi atualizada?

**Resultado esperado:** ✅ Entender completamente a PR

---

### **OPÇÃO 2️⃣: Executar Testes** (15-30 minutos)

**Testes obrigatórios:**

#### **Teste 1: Validação de Formatos**
```bash
# Docker Compose
docker compose -f docker-compose.yml config

# YAML files
yamllint prometheus.yml alerts.yml alertmanager.yml

# Shell scripts
shellcheck scripts/*.sh

# Python syntax
python3 -m py_compile src/**/*.py
```

#### **Teste 2: Arquivos Críticos**
```bash
# Verificar que arquivos essenciais não foram removidos/corrompidos
test -f docker-compose.yml
test -f .env.development
test -f Makefile
test -f pytest.ini
```

#### **Teste 3: Lógica de Negócio**
```bash
# Rodar testes unitários
make test-unit

# Rodar testes de integração (se containers estiverem up)
make test-integration
```

#### **Teste 4: Segurança**
```bash
# Verificar se há secrets expostos
git diff main...HEAD | grep -iE "(password|secret|api_key|token)" || echo "✅ No secrets"

# Bandit security scan
make lint-bandit

# OWASP Dependency Check
make check-deps
```

#### **Teste 5: Code Quality**
```bash
# Python linting
make lint-python  # Executa Black, Flake8, Pylint, MyPy

# JavaScript/TypeScript linting
npm run lint

# Formatação
npm run format --check
```

#### **Teste 6: Compatibilidade & Impacto**
```bash
# Testar startup de containers (se mudanças em docker-compose.yml)
make down
make up
docker compose ps  # Todos devem estar "healthy" ou "running"

# Verificar se serviços estão acessíveis
curl -f http://localhost:9090  # Prometheus
curl -f http://localhost:3001  # Grafana
```

#### **Teste 7: 🚨 VALIDAÇÃO OBRIGATÓRIA - GitHub Actions Status**
```bash
# No GitHub PR page, verificar que todos os checks estão ✅ green
# Aguardar que workflow "Python Package CI" complete com sucesso
#
# ❌ NÃO MERGEAR se GitHub Actions falharam ou estão pendentes
# ✅ MERGEAR apenas se todos os checks passaram
```

**Documentação de Testes:**
Registre como comentário na PR:
```
## 🧪 Resultados dos Testes

✅ Teste 1: Validação de Formatos → PASSOU
✅ Teste 2: Arquivos Críticos → PASSOU
✅ Teste 3: Testes Automatizados → PASSOU (X unit + Y integration)
✅ Teste 4: Segurança (Bandit, secrets scan) → PASSOU
✅ Teste 5: Code Quality (linters) → PASSOU
✅ Teste 6: Compatibilidade → PASSOU (todos os serviços UP)
🎯 GitHub Actions: ✅ ALL CHECKS PASSED

**Conclusão**: PR está SEGURA para mergear
```

**Resultado esperado:** ✅ Todos os 7 testes devem PASSAR

---

### **OPÇÃO 1️⃣: Mergear PR** (5-10 minutos)

**Pré-requisitos (Obrigatório):**
- ✅ Opção 3 (Leitura) COMPLETA
- ✅ Opção 2 (7 Testes) COMPLETA E PASSARAM
- ✅ **GitHub Actions Status: ALL CHECKS PASSED** (fundamental)
- ✅ Code review aprovado
- ✅ Nenhum bloqueador encontrado

**Via GitHub Interface (Recomendado):**
```
1. Acesse: https://github.com/KleilsonSantos/infra-devtools/pull/[PR-NUMBER]
2. Verificar: "All checks have passed" ✅
3. Scroll até "Merge pull request"
4. Escolher merge strategy:
   - "Create a merge commit" (preserva histórico completo)
   - "Squash and merge" (combina commits)
   - "Rebase and merge" (histórico linear)
5. Clicar em botão verde "Confirm merge"
6. (Opcional) Deletar branch via GitHub
```

**Pós-Merge (Obrigatório):**
1. Sincronizar repositório local:
   ```bash
   git fetch origin
   git checkout main
   git pull origin main
   ```
2. Atualizar documentação:
   - [ ] Atualizar `CHANGELOG.md` se necessário
   - [ ] Bump version se aplicável (`make version-patch` ou `version-minor`)
   - [ ] Criar GitHub Release se for versão nova

**Resultado esperado:** ✅ PR integrada em main com rastreabilidade profissional

---

### ⚠️ **Regras Críticas da Sequência 3→2→1**

```
❌ PROIBIDO: Pular etapas (ex: ir direto do 3 pro 1)
❌ PROIBIDO: Testar sem ler análise completa
❌ PROIBIDO: Mergear sem testar
❌ PROIBIDO: Mergear com GitHub Actions failing
✅ OBRIGATÓRIO: Sempre 3 → 2 → 1 (nesta ordem)
✅ OBRIGATÓRIO: Todos os 7 testes devem PASSAR
✅ OBRIGATÓRIO: GitHub Actions green
✅ OBRIGATÓRIO: Documentação atualizada
```

---

## 📋 Code Quality Standards

### Python Code Standards

**Ferramentas obrigatórias:**
- **Black**: Formatação automática (linha 100 caracteres)
- **isort**: Organização de imports
- **Flake8**: Linting PEP8 (complexidade máx: 10)
- **Pylint**: Análise profunda (complexidade máx: 12, max-args: 5)
- **MyPy**: Type checking (strict mode)
- **Bandit**: Security scanning
- **pydocstyle**: Docstring validation

**Execução:**
```bash
# Format code
make format-black
make format-isort

# Validate
make lint-python  # Roda todos os linters
```

### JavaScript/TypeScript Standards

**Ferramentas obrigatórias:**
- **ESLint**: Linting com plugins TypeScript
- **Prettier**: Formatação consistente

**Execução:**
```bash
npm run lint      # ESLint with auto-fix
npm run format    # Prettier formatting
```

### Shell Script Standards

**Ferramentas obrigatórias:**
- **ShellCheck**: Linting para bash scripts
- **Shared Library**: Usar `scripts/lib.sh` para funções comuns

**Regras:**
- Sempre usar `set -euo pipefail`
- Source lib.sh: `. "$(dirname "$0")/lib.sh"`
- Usar funções de logging: `log_info`, `log_error`, etc.
- Documentar com header padronizado

---

## 🛡️ Security Guidelines

### Segurança em Commits

**❌ NUNCA commitar:**
- Arquivos `.env` (exceto `.env.development` template)
- Credentials (passwords, tokens, API keys)
- Private keys (`.pem`, `.key`, `.p12`)
- Database dumps com dados reais
- Logs com informações sensíveis

**✅ SEMPRE:**
- Usar `.env.example` para templates
- Usar Vault para secrets em produção
- Revisar com `git diff` antes de commit
- Executar `make lint-bandit` antes de push

### Dependency Security

```bash
# OWASP Dependency-Check
make check-deps

# npm audit
npm audit

# Fix automatically
npm audit fix
```

### Container Security

- Manter imagens atualizadas
- Usar tags específicas (não `:latest`)
- Revisar health checks
- Configurar resource limits em produção

---

## 🧪 Testing Guidelines

### Test Organization

```
src/tests/
├── unit/              # Testes unitários (sem Docker)
│   └── test_*.py
└── integration/       # Testes de integração (com Docker)
    └── test_*.py
```

### Test Markers

```python
@pytest.mark.unit           # Testes rápidos, sem dependências
@pytest.mark.integration    # Requer Docker containers
@pytest.mark.network        # Testes de rede/DNS
@pytest.mark.services       # Testes de disponibilidade de serviços
```

### Running Tests

```bash
# Todos os testes
make test-all

# Apenas unit tests (rápido)
make test-unit

# Apenas integration tests (requer Docker up)
make test-integration

# Com coverage
make coverage
```

---

## 📚 Documentation Standards

### Required Documentation

- **README.md**: Overview, quick start, serviços
- **CONTRIBUTING.md**: Este arquivo
- **CHANGELOG.md**: Histórico de versões
- **SECURITY.md**: Políticas de segurança
- **CODE_OF_CONDUCT.md**: Código de conduta (planejado)

### Docstring Standards (Python)

```python
def backup_database(db_name: str, output_path: str) -> bool:
    """
    Cria backup de um banco de dados específico.

    Args:
        db_name: Nome do banco de dados
        output_path: Caminho para salvar o backup

    Returns:
        True se backup foi bem-sucedido, False caso contrário

    Raises:
        ValueError: Se db_name for inválido
        IOError: Se não conseguir escrever no output_path

    Example:
        >>> backup_database("postgres", "/backups/db.sql")
        True
    """
```

---

## 🚀 Release Process

### Creating a Release

```bash
# 1. Ensure main is up to date
git checkout main
git pull origin main

# 2. Bump version
make version-minor  # ou version-patch, version-major

# 3. Update CHANGELOG.md
# Adicionar entry para a nova versão

# 4. Commit version bump
git add VERSION CHANGELOG.md package.json sonar-project.properties
git commit -m "chore(release): bump version to X.Y.Z"
git push origin main

# 5. Create GitHub Release
gh release create vX.Y.Z \
  --title "Release vX.Y.Z" \
  --notes-file RELEASE_NOTES.md

# 6. (Opcional) Deploy to production
# Seguir procedimentos de deploy específicos
```

---

## 📞 Contato e Suporte

- **Autor**: Kleilson Santos
- **Email**: kleilsonsantos0907@gmail.com
- **GitHub**: https://github.com/KleilsonSantos/infra-devtools
- **Issues**: https://github.com/KleilsonSantos/infra-devtools/issues

---

## 📜 License

Este projeto está licenciado sob MIT License - veja o arquivo LICENSE para detalhes.

---

**Última Atualização**: 2025-11-06
**Versão do Documento**: 1.0.0
