# 📋 Guia de Contribuição — Infra DevTools

Este documento estabelece os padrões de desenvolvimento para o **Infra DevTools**.

---

## 🎯 Ciclo de entrega (obrigatório)

**SSOT do fluxo:** [docs/guides/delivery-automation.md](./docs/guides/delivery-automation.md) · [docs/guides/git-workflow.md](./docs/guides/git-workflow.md) · [ADR-0001](./docs/adr/0001-sandbox-branching-strategy.md)

```text
Issue (#N)
  → git checkout sandbox && git pull
  → git checkout -b <type>/<N>-<slug>
  → bash scripts/check-pr-delivery-gate.sh   # antes do push / gh pr create
  → PR → sandbox  (body: Refs #N)
  → CI verde
  → bash scripts/merge-pr.sh <n>             # nunca em checks vermelhos
  → PR promote sandbox → main  (body: Closes #N)
  → bash scripts/merge-pr.sh <n>
  → tag vX.Y.Z **somente** se houve bump SemVer (feat/fix/…) — ver releases.md
```

| Não fazer | Fazer |
|-----------|--------|
| PR de trabalho direto para `main` | Sempre `feature/fix/ci/…` → `sandbox` |
| Abrir vários PRs/fixes em cascata na mesma fatia | Uma Issue → um PR de trabalho → um promote |
| `gh pr merge` no vermelho / subject default do GitHub | `bash scripts/merge-pr.sh <n>` |
| Tag a cada merge `ci`/`chore`/`docs` | Tag só com VERSION + CHANGELOG `[X.Y.Z]` |
| Inventar “watchers” paralelos que substituem o mapa | Babysit async: `gh pr checks <n>` |

Comandos:

```bash
npm run delivery-gate          # parity issue-link local
npm run preflight              # inclui delivery-gate + SSOT/tests
npm run merge-pr -- <n>        # merge canónico
```

---

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

**Canônico:** [docs/guides/releases.md](./docs/guides/releases.md) · [ADR-0002](./docs/adr/0002-canonical-semver-releases.md)

- SSOT: `VERSION` (= `package.json` = `sonar.projectVersion`)
- Release **só em `main`** após promote `sandbox → main`
- Tag anotada `vX.Y.Z` + GitHub Release **depois** do bump mergeado
- Não bumpar em todo PR de feature; agregar no release

```bash
bash scripts/version.sh show|check|patch|minor|major
bash scripts/check-semver-alignment.sh
```

| Tipo de Mudança | Versão |
|-----------------|--------|
| **feat:** | MINOR |
| **fix:** / **perf:** | PATCH |
| **BREAKING CHANGE** | MAJOR |
| **docs, style, test, chore, ci** | Não força bump sozinho |

---

## 🪝 Local Git hooks (before GitHub)

Hooks live in [`.githooks/`](./.githooks/) (Git `core.hooksPath`). Enabled by `npm install` / `npm run prepare`:

```bash
git config core.hooksPath .githooks
```

| Hook | Checks |
|------|--------|
| `pre-commit` | Staged shell syntax, flake8 on staged `src/**/*.py`, optional `ggshield secret scan pre-commit` |
| `pre-push` | No direct push to `main`/`sandbox`; runs [`scripts/preflight.sh`](./scripts/preflight.sh) |

```bash
bash scripts/preflight.sh   # or: npm run preflight
```

`preflight` mirrors the CI jobs that historically fail locally (VERSION SSOT, SemVer, unit tests, Bandit, yamllint, `bash -n`). Full guide: [docs/guides/git-workflow.md](./docs/guides/git-workflow.md).

Do not use `--no-verify` for routine work — CI still fail-closes on GitHub.

---

## 🔄 Pull Requests — Workflow Obrigatório

Canonical flow after [ADR-0001](./docs/adr/0001-sandbox-branching-strategy.md):

```text
Issue → branch from sandbox → PR → sandbox → promote PR → main
```

Details: [docs/guides/git-workflow.md](./docs/guides/git-workflow.md) · checklist: [docs/guides/delivery-verification.md](./docs/guides/delivery-verification.md).

### 🚨 **ATENÇÃO: PR OBRIGATÓRIO**

**⚠️ TODAS as mudanças DEVEM usar Pull Requests - sem exceções:**

- ❌ **PROIBIDO**: Merge / push direto em `main` ou `sandbox`
- ✅ **OBRIGATÓRIO**: Abrir (ou reutilizar) uma **GitHub Issue** antes da branch
- ✅ **OBRIGATÓRIO**: PR de trabalho → **`sandbox`** com `Refs #<N>` (CI job `issue-link`)
- ✅ **OBRIGATÓRIO**: Promote `sandbox` → `main` com `Closes #<N>` quando a Issue estiver completa
- ✅ **OBRIGATÓRIO**: Code review + GitHub Actions green antes do merge
- ✅ **OBRIGATÓRIO**: Ao finalizar a entrega, executar o checklist de [delivery-verification](./docs/guides/delivery-verification.md)

Bypass raro: label `ci:no-issue-required`. Bots Dependabot/Snyk são ignorados pelo gate.

### 🎯 Workflow com PRs — Passo a Passo

#### 0️⃣ Abrir Issue
Use os templates em `.github/ISSUE_TEMPLATE/` (bug / feature). Anote o número `#N`.

#### 1️⃣ Criar Feature Branch
```bash
git checkout sandbox
git pull origin sandbox
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

#### 4️⃣ Abrir PR no GitHub (base = sandbox)

Ir em: `https://github.com/KleilsonSantos/infra-devtools/compare/sandbox...feat/minha-feature`

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

#### 5️⃣ Merge da PR (→ sandbox)

Na interface do GitHub (ou `bash scripts/merge-pr.sh <N>`):
1. Aguardar GitHub Actions completar (✅ green), incluindo `issue-link`
2. Solicitar code review
3. Após aprovação, merge para **`sandbox`**
4. Preferir merge commit com subject `merge: PR #<n> — <branch>`

#### 6️⃣ Promote e atualizar local
```bash
# Depois do merge em sandbox: abrir PR sandbox → main (Closes #N)
# Após o promote:
git checkout main
git pull origin main
git checkout sandbox && git pull origin sandbox
git branch -d feat/minha-feature  # Deletar branch local
```

Ver checklist completo: [docs/guides/delivery-verification.md](./docs/guides/delivery-verification.md).

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

- [ ] Branch criada a partir de `sandbox` atualizado
- [ ] PR de trabalho com base `sandbox` e `Refs #<N>`
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

## Delivery workflow (SSOT)

Issue → feature branch → PR → **`sandbox`** (`Refs #<n>`) → promote → **`main`** (`Closes #<n>` when finishing the slice). See [ADR-0001](./docs/adr/0001-sandbox-branching-strategy.md).

**Living docs (use these):**
- [git-workflow.md](./docs/guides/git-workflow.md) — branches, Issues, PRs
- [delivery-automation.md](./docs/guides/delivery-automation.md) — gates + `merge-pr.sh`
- [delivery-verification.md](./docs/guides/delivery-verification.md) — end-of-slice checklist
- [releases.md](./docs/guides/releases.md) · [ADR-0002](./docs/adr/0002-canonical-semver-releases.md)
- [BRANCH-PROTECTION-SETUP.md](./docs/BRANCH-PROTECTION-SETUP.md)
- Historical “Opção / Protocolo Canônico” prose: [docs/archive/](./docs/archive/README.md) (not SSOT)

**Operator commands:**
```bash
bash scripts/check-pr-delivery-gate.sh
bash scripts/preflight.sh
bash scripts/merge-pr.sh <PR_NUMBER>
```

### Review the PR (read)

Was: “OPÇÃO 3”.

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

> **CI Checks UI (PR Validation):** job names are English — `PR change summary`, `Format validation`, `Critical files`, `Unit tests`, `Security scan`, `Code quality`, `Compatibility`, `Environment validation`, plus required `Issue link`, `PR base policy`, `Version SSOT`, `Protocol gate`. Local steps below remain a human checklist (not 1:1 with job labels).

### Validate (CI + local checks)

Was: “OPÇÃO 2”.

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

### Merge the PR

**Pré-requisitos (obrigatório):**
- ✅ Review completa
- ✅ Required checks green (`Protocol gate`, `Issue link`, `Version SSOT`, `PR base policy`, …)
- ✅ Code review aprovado (quando aplicável)
- ✅ Nenhum bloqueador encontrado
- Prefer: `bash scripts/merge-pr.sh <PR>` (sandbox or promote)

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

Procedimento canônico completo: **[docs/guides/releases.md](./docs/guides/releases.md)** (ADR-0002).

Não faça `git push origin main` direto. Fluxo: bump → PR → `sandbox` → promote → `main` → tag + `gh release create`.

Checklist pós-entrega: [docs/guides/delivery-verification.md](./docs/guides/delivery-verification.md).

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
