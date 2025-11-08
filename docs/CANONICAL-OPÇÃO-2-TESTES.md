# ✅ OPÇÃO 2: Testar (Validação) - Checklist Interativo

> **Protocolo Canônico 3→2→1 - Fase 2: 7 Validações Obrigatórias**
>
> Duração: **15-30 minutos** | Fase crítica: **VALIDAÇÃO AUTOMATIZADA**

---

## 📋 Instruções Iniciais

1. **OPÇÃO 3 DEVE SER COMPLETA** antes de começar OPÇÃO 2
2. **Copie este checklist** antes de começar
3. **Substitua `#PR_NUMBER`** pelo número real da PR
4. **Valide TODOS os 7 testes** em ordem
5. **PARE se algum teste falhar**
6. **Documente o resultado** no PR comment
7. **Não prossiga para OPÇÃO 1** até TODOS os 7 testes passarem

---

## 🔍 Contexto da PR

- **PR Number**: #\_\_\_\_\_\_\_\_\_\_\_\_\_
- **Título da PR**: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
- **Autor**: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
- **Branch**: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
- **Status OPÇÃO 3**: [ ] ✅ COMPLETA (deve estar pronta!)
- **Data/Hora de Início**: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

---

## ✅ 7 Testes Obrigatórios (Todos DEVEM passar)

### 🧪 Teste 1: Validação de Sintaxe

**Objetivo**: Garantir que código tem sintaxe válida (sem erros de parsing)

**O que testa**:
- ✅ Shell scripts (.sh)
- ✅ YAML files (.yml, .yaml)
- ✅ JSON files (.json)
- ✅ Python files (.py)
- ✅ JavaScript/TypeScript (.js, .ts)
- ✅ Docker files (Dockerfile)

**Como validar**:

**Shell Scripts**:
```bash
# Validar sintaxe bash
bash -n scripts/my-script.sh

# Se tudo OK:
# (sem output)
# Exit code: 0

# Se erro:
# scripts/my-script.sh: line 42: syntax error near `fi'
# Exit code: 1
```

**YAML Files**:
```bash
# Validar YAML (precisa Python)
python3 -c "import yaml; yaml.safe_load(open('docker-compose.yml'))"

# Alternativa (se yamllint instalado)
yamllint docker-compose.yml

# Se OK:
# (sem output)
# Exit code: 0
```

**JSON Files**:
```bash
# Validar JSON
python3 -c "import json; json.load(open('file.json'))"

# Alternativa
jq . file.json > /dev/null

# Se OK:
# (sem output)
# Exit code: 0
```

**Python Files**:
```bash
# Syntax check sem executar
python3 -m py_compile src/module.py

# Se erro:
# SyntaxError: invalid syntax (file.py, line 42)
```

**JavaScript/TypeScript**:
```bash
# Se usando Node.js
node --check src/file.js

# Se usando TypeScript
npx tsc --noEmit

# Se usando ESLint
npx eslint src/file.js --max-warnings 0
```

**Checklist**:
```bash
# Executar após clonar branch
git checkout REMOTE/PR_BRANCH
bash -n scripts/*.sh 2>&1 | grep -i "error"
# Se saída vazia: ✅ PASSA
# Se tem erros: ❌ FALHA
```

**Resultado esperado**:
```
✅ TODOS os scripts Shell têm sintaxe válida
✅ TODOS os YAML files são válidos
✅ TODOS os JSON files são válidos
✅ TODOS os Python files compilam
✅ TODOS os JS/TS files não têm erros
```

**Status**: [ ] ✅ PASSA | [ ] ❌ FALHA

**Se FALHAR**:
```
❌ Teste 1 FALHOU: Sintaxe inválida

Arquivo com erro: [arquivo]
Linha com erro: [linha]
Mensagem de erro: [mensagem]

Ação: @author Corrija erros de sintaxe acima
```

---

### 🔒 Teste 2: Arquivos Críticos

**Objetivo**: Garantir que nenhum arquivo crítico foi deletado ou corrompido

**Arquivos críticos a validar**:
```
✅ README.md (deve existir)
✅ docker-compose.yml (deve existir)
✅ Makefile (deve existir)
✅ .github/workflows/ (deve existir)
✅ VERSION (arquivo de versionamento, se existir)
✅ pyproject.toml ou setup.py (se projeto Python)
✅ package.json (se projeto Node.js)
✅ go.mod (se projeto Go)
```

**Como validar**:

**Método 1: Verificar deletions**:
```bash
# Listar arquivos deletados
git diff --name-only --diff-filter=D main...REMOTE/BRANCH

# Esperado: vazio (nenhum arquivo crítico deletado)
# Se saída tem arquivos críticos: ❌ FALHA
```

**Método 2: Verificar se existem**:
```bash
# Clonar branch e verificar
git checkout REMOTE/BRANCH

# Verificar arquivos críticos
test -f README.md && echo "✅ README.md" || echo "❌ README.md FALTANDO"
test -f docker-compose.yml && echo "✅ docker-compose.yml" || echo "❌ docker-compose.yml FALTANDO"
test -f Makefile && echo "✅ Makefile" || echo "❌ Makefile FALTANDO"
test -d .github/workflows && echo "✅ .github/workflows/" || echo "❌ .github/workflows/ FALTANDO"
```

**Método 3: Verificar size (não corrompido)**:
```bash
# Verificar tamanho de arquivos críticos
ls -lh README.md docker-compose.yml Makefile

# Se arquivo tem 0 bytes: ❌ Pode estar corrompido
```

**Checklist**:
```
- [ ] ✅ README.md existe e não é vazio
- [ ] ✅ docker-compose.yml existe e é válido YAML
- [ ] ✅ Makefile existe e não é vazio
- [ ] ✅ .github/workflows/ existe e tem arquivos .yml
- [ ] ✅ VERSION/pyproject.toml/package.json (conforme projeto)
- [ ] ❌ FALHA: Arquivo crítico deletado
- [ ] ❌ FALHA: Arquivo crítico vazio/corrompido
```

**Resultado esperado**:
```
✅ Todos os arquivos críticos existem
✅ Nenhum arquivo crítico foi deletado
✅ Nenhum arquivo crítico está vazio/corrompido
```

**Status**: [ ] ✅ PASSA | [ ] ❌ FALHA

**Se FALHAR**:
```
❌ Teste 2 FALHOU: Arquivo crítico deletado

Arquivo deletado: [arquivo]
Ação: @author Por que [arquivo] foi deletado?
      Se foi acidental: git revert [commit]
      Se foi intencional: Adicione comentário explicativo
```

---

### 🔐 Teste 3: Segurança (Secrets & Credenciais)

**Objetivo**: Detectar exposição de dados sensíveis

**O que verifica**:
- ❌ Passwords em plain text
- ❌ API keys / Access tokens
- ❌ Private SSH keys
- ❌ AWS credentials
- ❌ Database passwords
- ❌ .env files commitadas
- ❌ Private keys (.pem, .key)

**Como validar**:

**Método 1: Procurar padrões de secrets**:
```bash
# Padrões comuns de secrets
git diff main...REMOTE/BRANCH | grep -iE "password|api_key|secret|token|private_key|ssh_key|aws_secret" | head -20

# Se encontrar: ❌ FALHA
# Se vazio: ✅ PASSA
```

**Método 2: Procurar .env files**:
```bash
# Verificar se .env foi commitado
git diff --name-only main...REMOTE/BRANCH | grep "\.env"

# Se encontrar: ❌ FALHA (pois .env não deve ser versionado)
```

**Método 3: Procurar arquivos de chave**:
```bash
# Procurar por private keys
git diff --name-only main...REMOTE/BRANCH | grep -iE "\.pem$|\.key$|\.ppk$|id_rsa|id_dsa"

# Se encontrar: ❌ FALHA
```

**Método 4: Procurar credenciais AWS/GCP/Azure**:
```bash
# AWS
git diff main...REMOTE/BRANCH | grep -E "AKIA|aws_access_key_id|AWS_SECRET"

# GCP
git diff main...REMOTE/BRANCH | grep -E "private_key_id|GOOGLE_CREDENTIALS"

# Azure
git diff main...REMOTE/BRANCH | grep -E "AZURE_SUBSCRIPTION|connection_string"

# Se encontrar: ❌ FALHA
```

**Checklist**:
```
- [ ] ✅ Nenhuma password em plain text
- [ ] ✅ Nenhuma API key em plain text
- [ ] ✅ Nenhum token em plain text
- [ ] ✅ Nenhum .env file commitado
- [ ] ✅ Nenhuma private key commitada
- [ ] ✅ Credenciais usando env variables
- [ ] ❌ FALHA: Secrets expostos encontrados
```

**Resultado esperado**:
```
✅ Nenhuma credencial em plain text
✅ Nenhum arquivo .env commitado
✅ Nenhuma private key commitada
✅ Segredo usando variáveis de ambiente
```

**Status**: [ ] ✅ PASSA | [ ] ❌ FALHA

**⚠️ SE FALHAR - CRÍTICO**:
```
❌ Teste 3 FALHOU: SEGURANÇA COMPROMETIDA

Secret exposto: [tipo]
Localização: [arquivo:linha]

⚠️ AÇÕES IMEDIATAS REQUERIDAS:
1. @author REMOVA o secret do commit imediatamente
2. Invalide a credencial comprometida
3. Gere nova credencial
4. Faça push do fix

Documentação: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository

❌ NÃO MERGEAR até corrigir
```

---

### 📝 Teste 4: Formato Compatível

**Objetivo**: Garantir que todos os arquivos têm formato compatível

**O que verifica**:
- ✅ Encoding UTF-8 (não latin1, ASCII com acentos, etc)
- ✅ Line endings (LF, não CRLF)
- ✅ Sem caracteres especiais inválidos
- ✅ Permissões de arquivo corretas

**Como validar**:

**Método 1: Verificar encoding**:
```bash
# Detectar encoding de arquivo
file -i src/file.py

# Esperado:
# text/plain; charset=utf-8

# Inválido:
# text/plain; charset=iso-8859-1
```

**Método 2: Verificar line endings**:
```bash
# Ver line endings
git diff --name-only main...REMOTE/BRANCH | while read f; do
  if file "$f" | grep -q "CRLF"; then
    echo "❌ $f has CRLF (Windows)"
  else
    echo "✅ $f has LF"
  fi
done
```

**Método 3: Verificar caracteres inválidos**:
```bash
# Procurar por BOM (Byte Order Mark)
git diff main...REMOTE/BRANCH | grep -E "^+.*\xef\xbb\xbf" && echo "❌ BOM found" || echo "✅ No BOM"

# Procurar por caracteres NULL
git diff main...REMOTE/BRANCH | grep -P "\0" && echo "❌ NULL chars found" || echo "✅ No NULL"
```

**Método 4: Verificar permissões**:
```bash
# Verificar se scripts têm permissão de execução
git ls-files | grep -E "scripts/.*\.sh$" | while read f; do
  if [ -x "$f" ]; then
    echo "✅ $f é executável"
  else
    echo "⚠️ $f não é executável (pode ser OK)"
  fi
done
```

**Checklist**:
```
- [ ] ✅ Todos arquivos em UTF-8
- [ ] ✅ Todos line endings são LF (Unix)
- [ ] ✅ Sem BOM (Byte Order Mark)
- [ ] ✅ Sem caracteres NULL/especiais inválidos
- [ ] ✅ Scripts com permissão executável
- [ ] ❌ FALHA: Formato incompatível encontrado
```

**Resultado esperado**:
```
✅ Todos os arquivos em UTF-8
✅ Line endings consistentes (LF)
✅ Sem caracteres especiais inválidos
✅ Permissões de arquivo corretas
```

**Status**: [ ] ✅ PASSA | [ ] ❌ FALHA

**Se FALHAR**:
```
❌ Teste 4 FALHOU: Formato incompatível

Arquivo: [arquivo]
Problema: [encoding/line ending/permissão]

Ação: @author Corrija:
  - Para UTF-8: git config core.safecrlf true
  - Para LF: git config core.eol lf
  - Para permissão: chmod +x scripts/file.sh
```

---

### 🔀 Teste 5: Conflitos de Merge

**Objetivo**: Garantir que não há merge conflicts não resolvidos

**O que verifica**:
- ✅ Branch está up-to-date com main
- ✅ Nenhum conflito de merge
- ✅ Markers de conflito foram removidos

**Como validar**:

**Método 1: Via GitHub UI**:
```
GitHub → PR → "Conversation" tab
Procurar por mensagem:
- ✅ "This branch has no conflicts with the base branch"
- ❌ "This branch has conflicts that must be resolved"
```

**Método 2: Via linha de comando**:
```bash
# Testar merge simulado
git fetch origin
git merge --no-commit --no-ff origin/main

# Se OK:
# Merge made by the 'recursive' strategy.
# (nenhuma linha de conflito)

# Se erro:
# CONFLICT (content): Merge conflict in file.py
# Automatic merge failed; fix conflicts and then commit the result.

# Abortar merge de teste
git merge --abort
```

**Método 3: Procurar por markers de conflito**:
```bash
# Procurar por markers não resolvidos
git diff main...REMOTE/BRANCH | grep -E "^+.*<<<<<<<|^+.*=======|^+.*>>>>>>>"

# Se encontrar: ❌ Conflitos não resolvidos
# Se vazio: ✅ PASSA
```

**Checklist**:
```
- [ ] ✅ GitHub mostra "no conflicts"
- [ ] ✅ Merge simulado passa sem conflitos
- [ ] ✅ Nenhum marker de conflito (<<<<<<<, =======, >>>>>>>)
- [ ] ✅ Branch está up-to-date com main
- [ ] ❌ FALHA: Conflitos detectados
```

**Resultado esperado**:
```
✅ Nenhum merge conflict
✅ Branch está up-to-date com main
✅ Markers de conflito foram removidos
```

**Status**: [ ] ✅ PASSA | [ ] ❌ FALHA

**Se FALHAR**:
```
❌ Teste 5 FALHOU: Merge conflicts detectados

Arquivo com conflito: [arquivo]

Ação: @author Resolva os conflitos:
  1. git fetch origin
  2. git rebase origin/main
  3. Abra arquivos com conflitos
  4. Remova markers (<<<<<<<, =======, >>>>>>>)
  5. Teste que tudo funciona
  6. git add .
  7. git rebase --continue
  8. git push -f origin BRANCH_NAME
```

---

### 🚨 Teste 6: Breaking Changes

**Objetivo**: Garantir que breaking changes estão documentados

**O que verifica**:
- ✅ Se há breaking changes, estão em CHANGELOG.md
- ✅ Se há API changes, documentação foi atualizada
- ✅ Migração foi explicada (se necessário)

**Como validar**:

**Método 1: Procurar por breaking change markers**:
```bash
# Procurar em commit messages
git log main...REMOTE/BRANCH --format=%b | grep -i "BREAKING CHANGE"

# Se encontrou, verificar se em CHANGELOG.md:
grep -i "BREAKING" CHANGELOG.md | head -5
```

**Método 2: Procurar por deletions/renames suspeitos**:
```bash
# Deletions que podem ser breaking
git diff --diff-filter=D main...REMOTE/BRANCH

# Renames
git diff --diff-filter=R main...REMOTE/BRANCH

# Modificações de API/interface
git diff main...REMOTE/BRANCH -- "*.py" "*.ts" "*.js" | grep -E "^-.*def |^-.*class |^-.*export " | head -10
```

**Método 3: Verificar CHANGELOG.md**:
```bash
# Se há breaking changes, deve estar documentado
if git log main...REMOTE/BRANCH --format=%b | grep -q "BREAKING"; then
  if grep -q "BREAKING CHANGE" CHANGELOG.md; then
    echo "✅ Breaking changes documentadas"
  else
    echo "❌ Breaking changes NÃO documentadas"
  fi
fi
```

**Checklist**:
```
- [ ] ✅ Sem breaking changes
- [ ] ✅ Com breaking changes, documentadas em CHANGELOG.md
- [ ] ✅ Migração explicada (se necessário)
- [ ] ✅ Exemplos antes/depois (se necessário)
- [ ] ❌ FALHA: Breaking changes não documentadas
```

**Resultado esperado**:
```
✅ Nenhum breaking change não documentado
✅ CHANGELOG.md atualizado (se necessário)
✅ Migração foi explicada (se necessário)
```

**Status**: [ ] ✅ PASSA | [ ] ❌ FALHA

**Se FALHAR**:
```
❌ Teste 6 FALHOU: Breaking changes não documentadas

Breaking change encontrado:
- Removido: [função/classe/endpoint]
- Razão: [razão]

Ação: @author Documente em CHANGELOG.md:
  ## [X.Y.Z] - YYYY-MM-DD
  ### ⚠️ BREAKING CHANGES
  - Removed endpoint /v1/users (use /v2/users)
  - Changed password algorithm (requires re-hashing)

  ### Migration Guide
  1. Step 1
  2. Step 2
```

---

### 🎯 Teste 7: GitHub Actions Status (CRÍTICO)

**Objetivo**: **VALIDAÇÃO MAIS CRÍTICA** - Garantir que GitHub Actions passou com sucesso

**O que verifica**:
- ✅ Todos workflows passaram (✅ SUCCESS)
- ✅ Nenhum workflow com status ❌ FAILED
- ✅ Nenhum workflow com status ⏳ IN PROGRESS
- ❌ Workflow DEVE estar em status SUCCESS antes de merge

**Por quê é CRÍTICO**:
```
Teste 7 = Validação Automatizada
- PR validation workflow roda automaticamente
- Executa linting, testes, build, etc
- SE UM TESTE FALHA EM ACTIONS → PR ESTÁ QUEBRADA
```

**Como validar**:

**Método 1: Via GitHub UI (Recomendado)**:
```
GitHub → PR → "Checks" tab

Procurar por:
✅ "All checks have passed" → ✅ PASSA Teste 7
❌ "Some checks were not successful" → ❌ FALHA Teste 7
⏳ "Some checks were not yet completed" → ❌ FALHA Teste 7
```

**Método 2: Via GitHub API**:
```bash
# Requer GITHUB_TOKEN
curl -H "Authorization: token YOUR_TOKEN" \
  "https://api.github.com/repos/OWNER/REPO/commits/SHA/check-runs" | jq '.check_runs[] | {name, conclusion}'

# Esperado:
# {
#   "name": "pr-validation / test-suite",
#   "conclusion": "success"
# }

# Se algum tiver "failure" ou "pending": ❌ FALHA
```

**Método 3: Via script enforce-pr-validation.sh**:
```bash
# Usar script criado em P0
./scripts/enforce-pr-validation.sh #PR_NUMBER --verbose

# Se output:
# ✅ GitHub Actions = SUCCESS → ✅ PASSA
# ❌ GitHub Actions ≠ SUCCESS → ❌ FALHA
```

**Checklist**:
```
- [ ] ✅ GitHub mostra "All checks have passed"
- [ ] ✅ Todos workflows status = "success" (✅)
- [ ] ✅ Nenhum workflow em "failure" (❌)
- [ ] ✅ Nenhum workflow em "pending" (⏳)
- [ ] ✅ Script enforce-pr-validation.sh retorna PASSED
- [ ] ❌ FALHA: Algum workflow falhou
- [ ] ❌ FALHA: Algum workflow ainda está rodando
```

**Resultado esperado**:
```
✅ Todos os workflows = SUCCESS
✅ Nenhum erro em Actions
✅ Workflow completo: [nome] ✅
✅ Workflow completo: [nome] ✅
✅ Workflow completo: [nome] ✅
```

**Status**: [ ] ✅ PASSA | [ ] ❌ FALHA

**Se FALHA - CRÍTICO**:
```
❌ Teste 7 FALHOU: GITHUB ACTIONS ≠ SUCCESS

Workflow com falha: [nome do workflow]
Job com falha: [nome do job]
Mensagem de erro: [error message]

🔗 Link: https://github.com/OWNER/REPO/pull/PR_NUMBER/checks

⚠️ AÇÕES REQUERIDAS:
1. @author Clique no workflow falhado
2. Veja os detalhes do erro
3. Corrija o problema localmente:
   - Se teste falhou: fix código + re-push
   - Se linter falhou: run linter + fix + re-push
   - Se build falhou: debug build + fix + re-push
4. Novo push reexecuta Actions automaticamente
5. Aguarde Actions passar
6. Depois volta aqui e continua

❌ NÃO MERGEAR até Actions = SUCCESS
```

**Exemplos de Action failures e como corrigir**:

**Failure: Test Suite Failed**:
```
FALHA: tests/test_auth.py::test_login_with_invalid_credentials
  AssertionError: expected True, got False

Ação:
1. Rodar localmente: pytest tests/test_auth.py::test_login_with_invalid_credentials
2. Debug/fix código
3. Re-run: pytest
4. git add . && git push
5. Actions reexecuta automaticamente
```

**Failure: Linting Failed**:
```
FALHA: src/auth.py - Line 42: trailing whitespace

Ação:
1. Abrir arquivo em editor
2. Remover whitespace ao final da linha
3. git add . && git push
```

**Failure: Build Failed**:
```
FALHA: Docker build failed - port 5432 already in use

Ação:
1. Verificar docker-compose.yml
2. Mudar porta ou remover container anterior
3. Testar localmente: docker-compose up
4. git add . && git push
```

---

## 📊 Resultado Final - OPÇÃO 2

### Resumo de Testes

**7 Testes Obrigatórios**:
- [ ] Teste 1: [ ] ✅ PASSA | [ ] ❌ FALHA
- [ ] Teste 2: [ ] ✅ PASSA | [ ] ❌ FALHA
- [ ] Teste 3: [ ] ✅ PASSA | [ ] ❌ FALHA
- [ ] Teste 4: [ ] ✅ PASSA | [ ] ❌ FALHA
- [ ] Teste 5: [ ] ✅ PASSA | [ ] ❌ FALHA
- [ ] Teste 6: [ ] ✅ PASSA | [ ] ❌ FALHA
- [ ] Teste 7: [ ] ✅ PASSA | [ ] ❌ FALHA

### Decisão Final

**✅ SE TODOS OS 7 TESTES PASSAREM**:
```
✅ OPÇÃO 2 COMPLETA - TODOS OS TESTES PASSARAM (7/7)

→ Proceder para OPÇÃO 1: MERGEAR

Próximo passo: Executar merge com protocolo:
./scripts/merge-pr.sh #PR_NUMBER
```

**❌ SE ALGUM TESTE FALHAR**:
```
❌ OPÇÃO 2 INCOMPLETA - TESTES FALHARAM

Testes que falharam: [Teste X]
Problema: [problema]

NÃO PROCEDER para OPÇÃO 1
Avisar @author para corrigir
Quando corrigido, re-executar OPÇÃO 2
```

---

## 💬 Template de Comentário no GitHub

**Para OPÇÃO 2 PASSAR (Todos 7 Testes)**:
```markdown
✅ **OPÇÃO 2 (Testar) COMPLETA - 7/7 TESTES PASSARAM**

Testes validados:
- ✅ Teste 1: Validação de Sintaxe - PASSOU
- ✅ Teste 2: Arquivos Críticos - PASSOU
- ✅ Teste 3: Segurança (Secrets) - PASSOU
- ✅ Teste 4: Formato Compatível - PASSOU
- ✅ Teste 5: Conflitos de Merge - PASSOU
- ✅ Teste 6: Breaking Changes - PASSOU
- ✅ Teste 7: GitHub Actions Status - PASSOU ✅

Relatório: ./scripts/enforce-pr-validation.sh #PR_NUMBER --json

**Próximo**: OPÇÃO 1 (Mergear)
→ Executar: `./scripts/merge-pr.sh #PR_NUMBER`
```

**Para OPÇÃO 2 FALHAR**:
```markdown
❌ **OPÇÃO 2 (Testar) INCOMPLETA - TESTES FALHARAM**

Testes falhados:
- ❌ Teste 7: GitHub Actions Status - FALHOU
  - Workflow falhado: pr-validation / test-suite
  - Erro: Test "test_login_invalid_credentials" falhou
  - Link: https://github.com/.../checks

**Ações necessárias**:
1. @author Corrija o teste falhado
2. Execute localmente: pytest
3. Faça novo push
4. Aguarde Actions passar
5. Quando todos testes passarem, volte à OPÇÃO 2

**NÃO prosseguir para OPÇÃO 1 até TODOS testes passarem**
```

---

## 🎯 Próximos Passos

| Resultado | Ação |
|-----------|------|
| ✅ Todos 7 Testes Passam | → Proceder para **OPÇÃO 1: Mergear** |
| ❌ Algum Teste Falha | → **PARAR** e avisar autor |

---

<p align="center">
  <b>OPÇÃO 2: Testar (Validação) - Protocolo Canônico 3→2→1</b><br>
  <b>🧪 7 Validações Obrigatórias - Teste 7 é CRÍTICO</b><br>
  <b>🔀 by Kleilson Santos</b>
</p>
