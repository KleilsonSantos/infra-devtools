# 🔀 Protocolo Canônico 3→2→1 - PR Workflow Profissional

> Sistema formal e profissional para gerenciamento de Pull Requests com validação, auditoria e rastreabilidade completa

## 📑 Índice

1. [Visão Geral](#visão-geral)
2. [O Ciclo Canônico 3→2→1](#o-ciclo-canônico-3→2→1)
3. [OPÇÃO 3: Ler (Análise)](#opção-3-ler-análise)
4. [OPÇÃO 2: Testar (Validação)](#opção-2-testar-validação)
5. [OPÇÃO 1: Mergear (Integração)](#opção-1-mergear-integração)
6. [Exemplo Prático](#exemplo-prático)
7. [Regras Críticas](#regras-críticas)
8. [Troubleshooting](#troubleshooting)

---

## Visão Geral

### O que é o Protocolo Canônico 3→2→1?

O **Protocolo Canônico 3→2→1** é um sistema **formal, profissional e obrigatório** para garantir que:

✅ **Toda PR é analisada** antes de merge (qualidade)
✅ **Todas as validações passam** antes de merge (segurança)
✅ **Todo merge é rastreável** e documentado (auditoria)
✅ **O processo é profissional** e demonstrável (conformidade)

### Filosofia

```
NUNCA pular etapas
NUNCA fazer merge sem protocolo completo
SEMPRE seguir a ordem 3→2→1 (obrigatória)
SEMPRE documentar resultados
```

### ⚠️ REGRA FUNDAMENTAL: UM CICLO POR COMMIT

```
❌ ERRADO: Fazer múltiplos commits em sequência
   commit 1 → commit 2 → commit 3 → depois fazer PRs

✅ CORRETO: Um ciclo completo por commit
   commit 1 → CICLO 3→2→1 → merge
   commit 2 → CICLO 3→2→1 → merge  
   commit 3 → CICLO 3→2→1 → merge

CADA COMMIT = UMA PR = UM CICLO COMPLETO 3→2→1
```

### Tempo Total por PR

```
3️⃣ OPÇÃO 3 (Ler)     →  10-15 minutos
2️⃣ OPÇÃO 2 (Testar)  →  15-30 minutos
1️⃣ OPÇÃO 1 (Mergear) →   5-10 minutos
                        ─────────────
                        45-83 minutos
```

---

## O Ciclo Canônico 3→2→1

### Estrutura

```
┌─────────────────────────────────────────────────────────────┐
│                  CICLO CANÔNICO 3→2→1                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  3️⃣ OPÇÃO 3: LER (Análise Técnica Completa)                 │
│     └─ Entender 100% da PR                                 │
│     └─ Responder 12 perguntas obrigatórias                 │
│     └─ Validar commits, arquivos, breaking changes         │
│     └─ Duração: 10-15 minutos                              │
│                                                              │
│  ➜ Se OPÇÃO 3 falha: ❌ PARAR - Não proceder              │
│                                                              │
│  2️⃣ OPÇÃO 2: TESTAR (7 Validações Obrigatórias)             │
│     └─ Teste 1: Syntax validation                          │
│     └─ Teste 2: Arquivos críticos                          │
│     └─ Teste 3: Segurança (secrets, credenciais)           │
│     └─ Teste 4: Formato compatível                         │
│     └─ Teste 5: Conflitos de merge                         │
│     └─ Teste 6: Breaking changes                           │
│     └─ Teste 7: Actions Status (✅ CRÍTICO)                │
│     └─ Duração: 15-30 minutos                              │
│                                                              │
│  ➜ Se algum teste falha: ❌ PARAR - Não proceder           │
│  ➜ Se Actions ≠ SUCCESS: ❌ BLOQUEADO - Não mergear        │
│                                                              │
│  1️⃣ OPÇÃO 1: MERGEAR (Integração Formal)                    │
│     └─ Validar que OPÇÃO 3 & 2 foram completadas           │
│     └─ Merge com --no-ff (merge commit obrigatório)        │
│     └─ Mensagem padrão: chore(merge): 🔀 Merge PR #N       │
│     └─ Incluir documentação de protocolo                   │
│     └─ Duração: 5-10 minutos                               │
│                                                              │
│  ✅ PR COMPLETA E RASTREÁVEL                                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Ordem OBRIGATÓRIA

```
OPÇÃO 3 → OPÇÃO 2 → OPÇÃO 1
(não pular nenhuma)
(não alterar ordem)
(sempre validar 100%)
```

---

## OPÇÃO 3: Ler (Análise)

### Objetivo

Entender **100%** do que a PR faz antes de qualquer teste.

### Duração

**10-15 minutos** (depende da complexidade da PR)

### Checklist de Análise (12 Perguntas Obrigatórias)

Execute os comandos abaixo para responder as perguntas:

#### Pergunta 1: Todos os commits são semânticos?

```bash
# Listar commits da PR
git log main..HEAD --oneline

# Formato esperado:
# feat(scope): 📝 descrição
# fix(scope): 🐛 descrição
# docs(scope): 📚 descrição
# chore(scope): 🔧 descrição
```

**Critério**: ✅ Todos commits seguem Conventional Commits
**Se falha**: ❌ PARAR - Pedir rebase

---

#### Pergunta 2: O autor é o correto?

```bash
# Verificar autor dos commits
git log main..HEAD --format="%an <%ae>"

# Esperado:
# Seu Nome <seu.email@example.com>
```

**Critério**: ✅ Autor é você ou Kleilson Santos
**Se falha**: ❌ PARAR - Pedir ammend

---

#### Pergunta 3: Há breaking changes?

```bash
# Procurar por breaking changes
git diff main..HEAD | grep -iE "BREAKING|remove|delete|api.*change"

# Ou verificar commit message
git log main..HEAD --format=%b | grep -i "BREAKING CHANGE"
```

**Critério**: ✅ Se há breaking changes, deve estar documentado em CHANGELOG.md
**Se falha**: ❌ PARAR - Pedir documentação

---

#### Pergunta 4: Há conflitos com main?

```bash
# Tentar merge simulado
git merge --no-commit --no-ff main

# Se falha, há conflitos:
git merge --abort
```

**Critério**: ✅ Nenhum conflito, ou conflitos resolvidos
**Se falha**: ❌ PARAR - Pedir rebase em main

---

#### Pergunta 5: Há credenciais ou secrets expostos?

```bash
# Procurar por padrões de secrets
git diff main..HEAD | grep -iE "password|token|key|secret|api_key|aws_" | grep -v "PASSWORD" | grep -v "TOKEN_" | head -10

# Procurar por .env commitado
git diff --name-only main..HEAD | grep "\.env"
```

**Critério**: ✅ Nenhuma credencial em plain text, .env não commitado
**Se falha**: ❌ PARAR - Pedir remoção imediata

---

#### Pergunta 6: A documentação está completa?

```bash
# Verificar arquivos modificados
git diff --name-only main..HEAD

# Se há código novo, deve haver:
# - Comentários explicativos
# - Documentação em docs/
# - Atualização de README.md (se necessário)
# - Atualização de CHANGELOG.md
```

**Critério**: ✅ Documentação completa para mudanças
**Se falha**: ❌ PARAR - Pedir documentação adicional

---

#### Pergunta 7: Há arquivos críticos deletados?

```bash
# Listar arquivos deletados
git diff --name-only --diff-filter=D main..HEAD

# Verificar se algum dos críticos foi deletado:
# README.md, docker-compose.yml, Makefile, VERSION, .github/workflows/
```

**Critério**: ✅ Nenhum arquivo crítico deletado
**Se falha**: ❌ PARAR - Entender por que foi deletado

---

#### Pergunta 8: O escopo da PR é bem definido?

```bash
# Contar número de arquivos modificados
git diff --name-only main..HEAD | wc -l

# Verificar se PR não mistura vários escopos
# Ideal: 1-5 arquivos (exceto refatoração)
# Suspeito: 20+ arquivos (pode ser refatoração ou escopo muito amplo)
```

**Critério**: ✅ Escopo claro e focado
**Se falha**: ⚠️ AVISAR - Verificar se é refatoração ou mudança ampla

---

#### Pergunta 9: Há testes adicionados?

```bash
# Procurar por arquivos de teste
git diff --name-only main..HEAD | grep -E "test|spec"

# Verificar cobertura
git diff main..HEAD | grep -E "^+.*def test_|^+.*def spec_|^+.*it(" | wc -l
```

**Critério**: ✅ Se há código novo, há testes correspondentes
**Se falha**: ⚠️ AVISAR - Pedir testes adicionais

---

#### Pergunta 10: As dependências foram atualizadas?

```bash
# Procurar por changes em package.json, requirements.txt, etc
git diff --name-only main..HEAD | grep -E "package.json|requirements.txt|Gemfile|pom.xml|go.mod"

# Se sim, verificar se há CHANGELOG entry
git log main..HEAD --oneline | grep -iE "bump|update|upgrade|dependency"
```

**Critério**: ✅ Se há atualizações, estão documentadas
**Se falha**: ⚠️ AVISAR - Documentar mudanças

---

#### Pergunta 11: A PR referencia uma issue ou ticket?

```bash
# Procurar por referências a issues
git log main..HEAD --format=%b | grep -iE "#[0-9]+|fixes|closes|resolves"
```

**Critério**: ✅ Se há issue, deve ser referenciada (fixes #123)
**Se falha**: ⚠️ AVISAR - Recomendado adicionar referência

---

#### Pergunta 12: Há comentários explicativos para código complexo?

```bash
# Procurar por código novo sem comentários
git diff main..HEAD | grep "^+" | grep -v "^+++" | head -20

# Verificar se há comentários explicativos
git diff main..HEAD | grep "^+.*#" | wc -l
```

**Critério**: ✅ Código complexo tem comentários
**Se falha**: ⚠️ AVISAR - Adicionar comentários se necessário

---

### Resultado de OPÇÃO 3

Se **todas as 12 perguntas passarem** ✅:
```
✅ OPÇÃO 3 COMPLETA - Proceder para OPÇÃO 2
```

Se **alguma questão crítica (#1-5) falhar** ❌:
```
❌ OPÇÃO 3 FALHOU - PARAR, não proceder
Avisar o PR autor para corrigir
```

Se **questões secundárias (#6-12) avisar** ⚠️:
```
⚠️ OPÇÃO 3 COM AVISOS - Pode proceder com cuidado
Documentar os avisos
```

---

## OPÇÃO 2: Testar (Validação)

### Objetivo

Garantir que a PR **passou em todos os testes obrigatórios** antes de merge.

### Duração

**15-30 minutos** (a maioria roda automaticamente em Actions)

### 7 Testes Obrigatórios

#### Teste 1: Validação de Sintaxe

**O quê testa**: Sintaxe de scripts shell, YAML, JSON, etc.

```bash
# Shell scripts
bash -n scripts/*.sh

# YAML files
python3 -c "import yaml; yaml.safe_load(open('docker-compose.yml'))"

# JSON files
python3 -c "import json; json.load(open('file.json'))"
```

**Status esperado**: ✅ PASSA
**Se falha**: ❌ Corrigir sintaxe

---

#### Teste 2: Arquivos Críticos

**O quê testa**: Nenhum arquivo crítico foi deletado

```bash
# Arquivos que devem existir sempre:
[ -f README.md ] && echo "✅" || echo "❌"
[ -f CONTRIBUTING.md ] && echo "✅" || echo "❌"
[ -f docker-compose.yml ] && echo "✅" || echo "❌"
[ -f Makefile ] && echo "✅" || echo "❌"
[ -f VERSION ] && echo "✅" || echo "❌"
[ -f CHANGELOG.md ] && echo "✅" || echo "❌"
```

**Status esperado**: ✅ Todos presentes
**Se falha**: ❌ Restaurar arquivos

---

#### Teste 3: Segurança

**O quê testa**: Nenhuma credencial, secret ou .env foi commitado

```bash
# Verificar .env
git diff --name-only | grep "\.env" | grep -v "\.env.example"

# Verificar secrets
git diff | grep -iE "password.*=|token.*=|key.*=|secret.*=" | grep -v "PASSWORD_" | head -5
```

**Status esperado**: ✅ Sem secrets
**Se falha**: ❌ Remover secrets

---

#### Teste 4: Compatibilidade de Formato

**O quê testa**: Arquivos estão em encoding correto (UTF-8) e formato válido

```bash
# Verificar encoding
file *.md | grep UTF-8

# Verificar markdown
grep "^#" README.md > /dev/null && echo "✅" || echo "❌"
```

**Status esperado**: ✅ UTF-8, markdown válido
**Se falha**: ❌ Converter para UTF-8

---

#### Teste 5: Conflitos de Merge

**O quê testa**: Nenhum conflito com main

```bash
# Testar merge
git merge --no-commit --no-ff main 2>/dev/null && echo "✅" || echo "❌"
git merge --abort
```

**Status esperado**: ✅ Sem conflitos
**Se falha**: ❌ Rebase em main

---

#### Teste 6: Breaking Changes

**O quê testa**: Se há breaking changes, estão documentados

```bash
# Procurar BREAKING CHANGE
git log main..HEAD --format=%b | grep -i "BREAKING CHANGE"

# Se encontrado, deve estar em CHANGELOG.md
grep -i "breaking" CHANGELOG.md > /dev/null && echo "✅" || echo "❌"
```

**Status esperado**: ✅ Documentado se existe
**Se falha**: ❌ Documentar breaking changes

---

#### **Teste 7: Actions Status** ⭐ CRÍTICO

**O quê testa**: GitHub Actions passaram com sucesso

```bash
# Verificar status via GitHub API
./scripts/enforce-pr-validation.sh <PR_NUMBER>

# Saída esperada:
# ✅ PR #123 - All checks passed
# ✅ Actions Status: SUCCESS
# ✅ Ready to merge
```

**Status esperado**: ✅ SUCCESS
**Se falha**: ❌ BLOQUEADO - Corrigir e re-run

---

### Resultado de OPÇÃO 2

**6/7 testes passaram?** ⚠️ PARAR - Um teste crítico falhou
**7/7 testes passaram?** ✅ OPÇÃO 2 COMPLETA - Proceder para OPÇÃO 1
**Actions ≠ SUCCESS?** ❌ BLOQUEADO - Não mergear

---

## OPÇÃO 1: Mergear (Integração)

### Objetivo

Integrar a PR em main **de forma formal e profissional**.

### Duração

**5-10 minutos**

### Pré-requisitos Obrigatórios

Antes de fazer merge, verificar:

```bash
✅ OPÇÃO 3 foi completada (12 perguntas respondidas)
✅ OPÇÃO 2 foi completada (7/7 testes passaram)
✅ Actions Status = SUCCESS
✅ Nenhum bloqueador encontrado
✅ PR está atualizada com main (rebase se necessário)
```

### Passo a Passo do Merge

#### 1. Sincronizar com main (local)

```bash
git fetch origin
git checkout main
git pull origin main
git checkout seu-branch
git rebase main  # Se houver divergência
```

#### 2. Executar script de merge

```bash
# Script automatiza merge commit padrão
./scripts/merge-pr.sh <PR_NUMBER>

# Exemplo:
./scripts/merge-pr.sh 42
```

**O script irá**:
- Ler número da PR via GitHub API
- Gerar merge commit message padrão
- Executar: `git merge --no-ff` com message
- Incluir: protocolo 3→2→1, PR reference, Co-Authored-By

#### 3. Merge commit message padrão

```
chore(merge): 🔀 Merge PR #42: descrição da feature

Protocolo Canônico 3→2→1:
✅ OPÇÃO 3 (Ler) - Análise técnica completa
✅ OPÇÃO 2 (Testar) - 7/7 testes PASSARAM
✅ OPÇÃO 1 (Mergear) - Merge com merge commit

Closes #42

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

#### 4. Push para main

```bash
git push origin main
```

#### 5. Sincronizar localmente

```bash
git checkout main
git pull origin main
```

### Resultado de OPÇÃO 1

Se merge foi bem-sucedido ✅:
```
✅ OPÇÃO 1 COMPLETA
✅ PR MERGEADA
✅ PROTOCOLO 3→2→1 100% COMPLETO
✅ PR RASTREÁVEL NO GIT HISTORY
```

---

## Exemplo Prático

### Cenário: Implementar nova feature "Dark Mode"

#### 1️⃣ Criar Branch

```bash
git checkout -b feat/dark-mode
```

#### 2️⃣ Implementar

```bash
# Adicionar código, testes, documentação
git commit --author="Seu Nome <email>" -m "feat(ui): 🌙 add dark mode toggle"
git commit -m "test(ui): add dark mode tests"
git commit -m "docs(readme): document dark mode"
```

#### 3️⃣ Push para GitHub

```bash
git push -u origin feat/dark-mode
```

#### 4️⃣ Abrir PR

GitHub Actions rodão automaticamente (6/7 testes)

#### 5️⃣ **OPÇÃO 3: LER** (10-15 min)

```bash
# Responder checklist de 12 perguntas
cat docs/CANONICAL-WORKFLOW.md  # Ler seção OPÇÃO 3

# Perguntas:
1. ✅ Todos commits semânticos? → SIM
2. ✅ Autor correto? → SIM
3. ✅ Breaking changes? → NÃO
4. ✅ Conflitos? → NÃO
5. ✅ Secrets expostos? → NÃO
6. ✅ Documentação completa? → SIM
7. ✅ Arquivos críticos deletados? → NÃO
8. ✅ Escopo bem definido? → SIM
9. ✅ Testes adicionados? → SIM
10. ✅ Dependências atualizadas? → NÃO
11. ✅ Issue referenciada? → SIM (#42)
12. ✅ Comentários em código complexo? → SIM

→ ✅ OPÇÃO 3 COMPLETA
```

#### 6️⃣ **OPÇÃO 2: TESTAR** (15-30 min)

```bash
# GitHub Actions executam automaticamente
# Verificar que 7/7 testes passaram:

✅ Teste 1: Syntax validation - PASSOU
✅ Teste 2: Arquivos críticos - PASSOU
✅ Teste 3: Segurança - PASSOU
✅ Teste 4: Formato compatível - PASSOU
✅ Teste 5: Conflitos - PASSOU
✅ Teste 6: Breaking changes - PASSOU
✅ Teste 7: Actions Status - SUCCESS ✅

→ ✅ OPÇÃO 2 COMPLETA
```

#### 7️⃣ **OPÇÃO 1: MERGEAR** (5-10 min)

```bash
# Executar merge automatizado
./scripts/merge-pr.sh 42

# Merge commit criado automaticamente com mensagem padrão
# PR mergeada em main
# Histórico rastreável

→ ✅ OPÇÃO 1 COMPLETA
→ ✅ PR #42 100% RASTREÁVEL COM PROTOCOLO COMPLETO
```

---

## Regras Críticas

### ❌ PROIBIDO (Nunca fazer)

```bash
# ❌ Mergear sem Actions passar
# (Actions deve estar com status SUCCESS)

# ❌ Pular alguma das 3 opções
# (Ordem é OBRIGATÓRIA: 3 → 2 → 1)

# ❌ Mergear sem protocolo documentado
# (Merge commit deve incluir protocolo 3→2→1)

# ❌ Fazer push direto em main
# (Sempre via PR e protocolo)

# ❌ Usar squash ou rebase ao mergear
# (Deve ser --no-ff, merge commit obrigatório)

# ❌ Ignorar avisos de OPÇÃO 3
# (Se crítico, PARAR e pedir correção)

# ❌ Committar secrets ou .env
# (Verificado em Teste 3 - BLOQUEADO automaticamente)
```

### ✅ OBRIGATÓRIO (Sempre fazer)

```bash
# ✅ Sempre seguir ordem 3 → 2 → 1
# (Nesta sequência, sem exceções)

# ✅ Sempre responder 12 perguntas OPÇÃO 3
# (Documentar respostas se necessário)

# ✅ Sempre validar 7/7 testes OPÇÃO 2
# (Actions deve passar com SUCCESS)

# ✅ Sempre mergear com --no-ff
# (Merge commit obrigatório)

# ✅ Sempre usar merge commit padronizado
# (chore(merge): 🔀 + protocolo)

# ✅ Sempre sincronizar com main
# (git pull origin main antes de merge)

# ✅ Sempre documentar protocolo no merge commit
# (Incluir ✅ OPÇÃO 3, 2, 1)
```

---

## Troubleshooting

### Problema: Actions não passou

**Solução**:
1. Ver detalhes do erro em GitHub Actions
2. Corrigir código/config
3. Fazer commit com correção
4. Push
5. Aguardar Actions passar novamente
6. ❌ PARAR - Não proceder com OPÇÃO 1 até Actions = SUCCESS

---

### Problema: PR tem conflitos com main

**Solução**:
```bash
git fetch origin
git rebase origin/main
# Resolver conflitos
git add .
git rebase --continue
git push -f origin seu-branch
```

---

### Problema: Commitei um arquivo .env acidentalmente

**Solução**:
```bash
# IMEDIATO - Remover de git history
git rm --cached .env
git commit --amend --no-edit
git push -f origin seu-branch

# Então:
# 1. Renovar credenciais (credencial exposta!)
# 2. Adicionar .env ao .gitignore
# 3. Fazer novo commit com fix
# 4. Verificar que Teste 3 passa
```

---

### Problema: Breaking change não está documentado

**Solução**:
1. Adicionar em CHANGELOG.md:
   ```markdown
   ## BREAKING CHANGES
   - Descrição da breaking change
   ```
2. Commit com fix
3. Push
4. Revalidar com Actions
5. Completar protocolo 3→2→1

---

## Integração com GitHub

### Branch Protection Rules

As seguintes regras devem estar configuradas em GitHub > Settings > Branches > main:

```
✅ Require status checks to pass before merging
✅ Require branches to be up to date before merging
✅ Require a pull request before merging (optional)
✅ Require merge commits (--no-ff)
```

### Status Checks Obrigatórios

- ✅ `GitHub Actions` (todos os 7 testes devem passar)
- ✅ `Canonical Workflow` (validação de protocolo)

---

## Referência Rápida

### Tempo por Etapa

| Etapa | Tempo | Descrição |
|-------|-------|-----------|
| OPÇÃO 3 | 10-15 min | Análise técnica (12 perguntas) |
| OPÇÃO 2 | 15-30 min | 7 testes obrigatórios |
| OPÇÃO 1 | 5-10 min | Merge com merge commit |
| **TOTAL** | **45-83 min** | **Por PR** |

### Checklist Final

```
OPÇÃO 3: Análise Completa
├─ [ ] 12 perguntas respondidas
├─ [ ] Nenhuma questão crítica falhou
└─ ✅ Pronto para OPÇÃO 2

OPÇÃO 2: Validações Passaram
├─ [ ] 7/7 testes passaram
├─ [ ] Actions Status = SUCCESS
└─ ✅ Pronto para OPÇÃO 1

OPÇÃO 1: Merge Formal
├─ [ ] Main está atualizada
├─ [ ] Merge commit padronizado
├─ [ ] Protocolo documentado
└─ ✅ PR MERGEADA
```

### Comandos Úteis

```bash
# Ver commits da PR
git log main..HEAD --oneline

# Ver arquivos modificados
git diff --name-only main..HEAD

# Testar merge simulado
git merge --no-commit --no-ff main

# Fazer merge com merge commit
./scripts/merge-pr.sh <PR_NUMBER>

# Sincronizar com main
git fetch origin && git rebase origin/main
```

---

<p align="center">
  <b>Protocolo Canônico 3→2→1 = Qualidade + Rastreabilidade + Profissionalismo</b><br>
  <b>🔀 by Kleilson Santos</b>
</p>
