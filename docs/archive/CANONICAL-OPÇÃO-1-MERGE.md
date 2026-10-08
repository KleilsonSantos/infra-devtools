# ✅ OPÇÃO 1: Mergear (Integração) - Checklist Interativo

> **Protocolo Canônico 3→2→1 - Fase 1: Integração Formal**
>
> Duração: **5-10 minutos** | Fase final: **MERGE COM PROTOCOLO**

---

## 📋 Instruções Iniciais

1. **OPÇÃO 3 DEVE SER COMPLETA** (Ler/Análise)
2. **OPÇÃO 2 DEVE SER COMPLETA** (Testar/Validação)
3. **TODOS OS 7 TESTES DEVEM PASSAR**
4. **Copie este checklist** antes de começar merge
5. **Substitua `#PR_NUMBER`** pelo número real da PR
6. **Use merge commit obrigatoriamente** (--no-ff)
7. **Inclua mensagem de protocolo** no merge commit
8. **Documente o resultado** no PR comment

---

## 🔍 Contexto da PR

- **PR Number**: #\_\_\_\_\_\_\_\_\_\_\_\_\_
- **Título da PR**: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
- **Autor**: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
- **Branch**: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
- **Status OPÇÃO 3**: [ ] ✅ COMPLETA
- **Status OPÇÃO 2**: [ ] ✅ COMPLETA (7/7 testes)
- **Merguer**: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
- **Data/Hora do Merge**: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

---

## ⚠️ Pré-requisitos para Merge

### ✅ Checklist Pré-Merge

Antes de proceder, **validar que TODOS os requisitos foram atendidos**:

```
VALIDAÇÃO PRÉ-MERGE OBRIGATÓRIA
═══════════════════════════════

✅ OPÇÃO 3 (Ler)
  - [ ] ✅ Commits semânticos
  - [ ] ✅ Autor correto
  - [ ] ✅ Sem breaking changes não documentados
  - [ ] ✅ Sem conflitos com main
  - [ ] ✅ Sem secrets expostos
  - [ ] ✅ Documentação completa
  - [ ] ✅ Arquivos críticos preservados
  - [ ] ✅ Escopo bem definido
  - [ ] ✅ Testes adicionados
  - [ ] ✅ Dependências documentadas
  - [ ] ✅ Issue referenciada
  - [ ] ✅ Código bem comentado

✅ OPÇÃO 2 (Testar)
  - [ ] ✅ Teste 1: Validação de Sintaxe PASSOU
  - [ ] ✅ Teste 2: Arquivos Críticos PASSOU
  - [ ] ✅ Teste 3: Segurança PASSOU
  - [ ] ✅ Teste 4: Formato Compatível PASSOU
  - [ ] ✅ Teste 5: Conflitos de Merge PASSOU
  - [ ] ✅ Teste 6: Breaking Changes PASSOU
  - [ ] ✅ Teste 7: GitHub Actions PASSOU ✅
```

**SE ALGUM ITEM ACIMA FALHAR** ❌:
```
PARE AQUI - Não prosseguir com merge
Volte à OPÇÃO 3 ou OPÇÃO 2 e corrija
```

---

## 🔀 Procedimento de Merge

### Passo 1: Preparar Ambiente Local

```bash
# Atualizar main
git fetch origin main

# Verificar branch atual
git branch -a | grep "^\*"

# Se não está em main, trocar para main
git checkout main

# Atualizar para versão remota mais recente
git pull origin main
```

**Validação**:
```bash
# Verificar que estamos em main
git rev-parse --abbrev-ref HEAD
# Esperado output: main
```

---

### Passo 2: Preparar Branch da PR

```bash
# Buscar branch da PR
git fetch origin BRANCH_NAME

# Verificar commits a serem mergeados
git log --oneline origin/main..origin/BRANCH_NAME

# Esperado: Ver lista de commits da PR
```

**Validação**:
```bash
# Contar quantos commits serão mergeados
git log --oneline origin/main..origin/BRANCH_NAME | wc -l

# Esperado: Número de commits da PR (usualmente 2-5)
```

---

### Passo 3: Iniciar Merge com --no-ff

**IMPORTANTE**: Usar **`--no-ff`** (no fast-forward) OBRIGATORIAMENTE

```bash
# Executar merge
git merge --no-ff origin/BRANCH_NAME

# Será aberto editor de texto com mensagem de merge
# NÃO SAIA DO EDITOR AINDA - Vá para Passo 4
```

**Por que --no-ff**:
```
--no-ff cria um MERGE COMMIT explícito

COM --no-ff:
  main: ●───●
         └─●─●─┘
      (merge commit criado)

SEM --no-ff (fast-forward):
  main: ●───●─●─●
      (histórico linear, não rastreável)
```

---

### Passo 4: Criar Mensagem de Merge Padronizada

**Quando editor abrir**, substituir mensagem padrão por:

**Formato**:
```
chore(merge): 🔀 Merge PR #{PR_NUMBER}: {TÍTULO DA PR}

Protocolo Canônico 3→2→1 - Merge Completo

═══════════════════════════════════════════════════════════════

📋 OPÇÃO 3 (Ler): Análise Técnica Completa
  ✅ Commits semânticos
  ✅ Autor validado
  ✅ Sem breaking changes não documentados
  ✅ Sem conflitos de merge
  ✅ Sem secrets expostos
  ✅ Documentação completa
  ✅ Arquivos críticos preservados
  ✅ Escopo bem definido
  ✅ Testes inclusos
  ✅ Dependências rastreadas
  ✅ Issue referenciada
  ✅ Código comentado

🧪 OPÇÃO 2 (Testar): 7 Validações Obrigatórias
  ✅ Teste 1: Validação de Sintaxe
  ✅ Teste 2: Arquivos Críticos
  ✅ Teste 3: Segurança (Secrets)
  ✅ Teste 4: Formato Compatível
  ✅ Teste 5: Conflitos de Merge
  ✅ Teste 6: Breaking Changes
  ✅ Teste 7: GitHub Actions Status ✅

═══════════════════════════════════════════════════════════════

Autor: {NOME DO AUTHOR}
Reviewer: {SEU NOME}
Data: {DATA DO MERGE}

Co-Authored-By: {NOME DO AUTHOR} <{EMAIL}>
```

**Exemplo Prático**:
```
chore(merge): 🔀 Merge PR #42: Add dark mode toggle to settings

Protocolo Canônico 3→2→1 - Merge Completo

═══════════════════════════════════════════════════════════════

📋 OPÇÃO 3 (Ler): Análise Técnica Completa
  ✅ Commits semânticos (feat, refactor)
  ✅ Autor: João Silva <joao@example.com>
  ✅ Sem breaking changes
  ✅ Sem conflitos com main
  ✅ Sem secrets expostos
  ✅ Documentação: docs/DARK_MODE.md criado
  ✅ Todos arquivos críticos preservados
  ✅ Escopo: settings + UI components (3 arquivos)
  ✅ Testes: 8 testes novos adicionados
  ✅ Dependências: material-ui@5.14.1 (security update)
  ✅ Issue: fixes #38
  ✅ Código bem comentado

🧪 OPÇÃO 2 (Testar): 7 Validações Obrigatórias
  ✅ Teste 1: Sintaxe TypeScript/CSS válida
  ✅ Teste 2: README, docker-compose, Makefile OK
  ✅ Teste 3: Nenhuma API key exposta
  ✅ Teste 4: UTF-8 encoding, LF line endings
  ✅ Teste 5: Branch up-to-date, sem conflicts
  ✅ Teste 6: Breaking changes documentados em CHANGELOG
  ✅ Teste 7: GitHub Actions = SUCCESS ✅

═══════════════════════════════════════════════════════════════

Autor: João Silva <joao@example.com>
Reviewer: Kleilson Santos <kleilson@example.com>
Data: 2024-01-07 15:30:00 UTC

Co-Authored-By: João Silva <joao@example.com>
```

---

### Passo 5: Salvar e Confirmar Mensagem

**No editor**:
- Vim/Nano: Pressionar Ctrl+X depois Y para salvar
- VS Code: Salvar arquivo e fechar editor

**Se merge foi bem-sucedido**:
```bash
# Saída esperada:
Merge made by the 'recursive' strategy.
 src/settings.py | 5 ++++
 src/ui.tsx | 12 +++++++
 tests/test_settings.py | 20 ++++++++++++
 3 files changed, 37 insertions(+)

# Ou se fast-forward foi evitado:
Merge made by the 'merge' strategy.
 [main XXXXX] chore(merge): 🔀 Merge PR #42...
 Author: Kleilson Santos <kleilson@example.com>
 1 file changed, 1 insertion(+)
```

---

### Passo 6: Verificar Merge Localmente

```bash
# Ver último commit (deve ser merge commit)
git log --oneline -n 5

# Esperado:
# XXXXX chore(merge): 🔀 Merge PR #42: Add dark mode...
# YYYYY feat(ui): 🎯 add dark mode toggle
# ZZZZZ refactor(theme): 🔄 organize theme colors
# ...

# Ver diferença entre main e origin/main
git log --oneline origin/main..HEAD

# Esperado: 1 commit (o merge commit)
```

---

### Passo 7: Fazer Push para Remote

```bash
# Push do merge para main
git push origin main

# Ou se tiver erro de permissão:
git push -u origin main

# Saída esperada:
# To github.com:KleilsonSantos/infra-devtools.git
#    abc1234..def5678  main -> main
```

**Validação**:
```bash
# Verificar que push foi bem-sucedido
git rev-parse HEAD
git rev-parse origin/main

# Ambos devem retornar o mesmo commit hash
```

---

### Passo 8: Verificar PR no GitHub

Após push, acessar PR no GitHub:

1. **Navegar para**: https://github.com/KleilsonSantos/infra-devtools/pull/PR_NUMBER

2. **Validar que**:
   - [ ] ✅ PR mostra "merged"
   - [ ] ✅ Merge commit aparece no histórico
   - [ ] ✅ Merge commit tem mensagem padronizada
   - [ ] ✅ Branch está marcada como "merged"

3. **Marcar branch para deletar** (opcional):
   ```
   GitHub UI → PR → "Delete branch" button
   Clique para deletar a branch remota (libera espaço)
   ```

---

## 📊 Checklist de Merge Completo

### Antes do Merge

```
PRÉ-REQUISITOS VALIDADOS
  - [ ] ✅ OPÇÃO 3 completa
  - [ ] ✅ OPÇÃO 2 completa (7/7 testes)
  - [ ] ✅ Nenhum item blocante
  - [ ] ✅ Aprovações obtidas
  - [ ] ✅ Branch up-to-date com main
```

### Durante o Merge

```
EXECUÇÃO DO MERGE
  - [ ] ✅ git fetch origin main
  - [ ] ✅ git checkout main
  - [ ] ✅ git pull origin main
  - [ ] ✅ git merge --no-ff origin/BRANCH
  - [ ] ✅ Mensagem de merge padronizada
  - [ ] ✅ Sem conflitos durante merge
  - [ ] ✅ git push origin main
```

### Após o Merge

```
VALIDAÇÃO PÓS-MERGE
  - [ ] ✅ Merge commit criado com --no-ff
  - [ ] ✅ Merge commit tem mensagem padronizada
  - [ ] ✅ Commit é visível em main
  - [ ] ✅ GitHub mostra PR como "merged"
  - [ ] ✅ GitHub Actions reexecutado em main
  - [ ] ✅ Main branch está estável
  - [ ] ✅ Branch deletada (opcional)
```

---

## ⚠️ Tratamento de Problemas

### Problema: Merge Conflict

**Sintoma**:
```
CONFLICT (content): Merge conflict in file.py
Automatic merge failed; fix conflicts and then commit the result.
```

**Solução**:
```bash
# Abrir arquivos com conflitos
# Procurar por: <<<<<<< | ======= | >>>>>>>
# Resolver conflitos manualmente

# Após resolver
git add file.py
git commit -m "resolve: merge conflicts"

# Continuar merge
git merge --continue
```

---

### Problema: Permissão Negada no Push

**Sintoma**:
```
remote: Permission to KleilsonSantos/infra-devtools.git denied to user.
fatal: unable to access 'https://github.com/...': Received HTTP 403
```

**Solução**:
```bash
# Usar SSH ao invés de HTTPS
git remote set-url origin git@github.com:KleilsonSantos/infra-devtools.git

# Ou usar token pessoal
git config --global credential.helper store
# E fazer push, ele pedirá token
git push origin main
```

---

### Problema: Branch Protection Violations

**Sintoma**:
```
remote: error: GitHub branch protection rules were violated
remote: error: "Require pull request reviews before merging"
```

**Solução**:
```
Isso significa que branch protection está ativo.
Você NÃO pode fazer merge direto via CLI.

Use GitHub UI ao invés:
1. PR → "Merge pull request" button
2. Selecionar "Create a merge commit"
3. Confirmar merge
```

---

### Problema: Failed to Update Ref

**Sintoma**:
```
error: failed to push some refs to 'origin'
hint: Updates were rejected because the tip of your current branch is behind its remote counterpart
```

**Solução**:
```bash
# Fetch atualizações remotas
git fetch origin main

# Rebase local em remote
git rebase origin/main

# Ou fazer merge
git merge origin/main

# Depois tentar push novamente
git push origin main
```

---

## 📝 Template de Merge Commit Message

### Uso do Script `merge-pr.sh`

Se usando script de automação (será criado em P1):

```bash
# Automático (recomendado)
./scripts/merge-pr.sh #PR_NUMBER

# Ou manual com os passos acima
```

### Template para Merge Manual

**Use este template** ao fazer merge manualmente:

```
chore(merge): 🔀 Merge PR #{NUMBER}: {TITLE}

Protocolo Canônico 3→2→1 - Merge Completo

═══════════════════════════════════════════════════════════════

📋 OPÇÃO 3 (Ler): ✅ Análise Completa
🧪 OPÇÃO 2 (Testar): ✅ 7/7 Testes Passaram
1️⃣ OPÇÃO 1 (Mergear): ✅ Integração Formal

═══════════════════════════════════════════════════════════════

Autor: {AUTHOR}
Reviewer: {REVIEWER}
Data: {DATE}

Co-Authored-By: {AUTHOR} <{EMAIL}>
```

---

## ✅ Resultado Final - Merge Completo

### Resumo de Status

```
PROTOCOLO CANÔNICO 3→2→1 COMPLETO ✅

3️⃣ OPÇÃO 3 (Ler):     ✅ Análise Técnica Completa
2️⃣ OPÇÃO 2 (Testar):  ✅ 7/7 Testes Passaram
1️⃣ OPÇÃO 1 (Mergear): ✅ Integração Formal Realizada

═══════════════════════════════════════════════════════════════

RESULTADO FINAL
✅ PR Mergeada com Sucesso
✅ Main Branch Atualizada
✅ Histórico Rastreável (Merge Commit)
✅ Protocolo Documentado no Commit
✅ Todos os Requisitos Atendidos

═══════════════════════════════════════════════════════════════
```

---

## 💬 Template de Comentário Final no GitHub

**Após merge bem-sucedido**:

```markdown
✅ **OPÇÃO 1 (Mergear) COMPLETA - PR MERGEADA COM SUCESSO**

Protocolo Canônico 3→2→1 finalizado ✅

**Resumo**:
- ✅ OPÇÃO 3: Análise Técnica Completa
- ✅ OPÇÃO 2: 7/7 Testes Passaram
- ✅ OPÇÃO 1: Integração Formal Realizada

**Merge Details**:
- Merge Commit: abc1234def5678 (--no-ff)
- Timestamp: 2024-01-07 15:30:00 UTC
- Reviewer: Kleilson Santos
- Merged into: main

**Main Branch Status**:
- ✅ Atualizada com nova PR
- ✅ GitHub Actions iniciado
- ✅ Histórico rastreável

**Próximos Passos**:
- [ ] Monitorar Actions em main
- [ ] Verificar deploy (se automático)
- [ ] Comentar em issues relacionadas

---
🔀 **Protocolo Canônico 3→2→1 - Ciclo Completo**
by Kleilson Santos
```

---

## 🎯 Checklist Final

- [ ] ✅ OPÇÃO 3 completa e validada
- [ ] ✅ OPÇÃO 2 completa (7/7 testes passaram)
- [ ] ✅ Merge feito com `--no-ff`
- [ ] ✅ Mensagem de merge padronizada
- [ ] ✅ Push realizado para main
- [ ] ✅ GitHub mostra PR como "merged"
- [ ] ✅ Histórico é rastreável
- [ ] ✅ Protocolo foi documentado
- [ ] ✅ Comentário final postado

---

<p align="center">
  <b>OPÇÃO 1: Mergear (Integração) - Protocolo Canônico 3→2→1</b><br>
  <b>🔀 Merge Formal com --no-ff e Documentação Completa</b><br>
  <b>🔀 by Kleilson Santos</b>
</p>
