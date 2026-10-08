# ✅ OPÇÃO 3: Ler (Análise) - Checklist Interativo

> **Protocolo Canônico 3→2→1 - Fase 3: Análise Técnica Completa**
>
> Duração: **10-15 minutos** | Fase crítica: **LEITURA E ANÁLISE**

---

## 📋 Instruções Iniciais

1. **Copie este checklist** antes de começar a revisar a PR
2. **Substitua `#PR_NUMBER`** pelo número real da PR
3. **Responda TODAS as 12 perguntas** em ordem
4. **PARE imediatamente** se alguma das questões críticas (1-5) falhar
5. **Documente o resultado** no PR comment
6. **Não prossiga para OPÇÃO 2** até completar OPÇÃO 3

---

## 🔍 Contexto da PR

- **PR Number**: #\_\_\_\_\_\_\_\_\_\_\_\_\_
- **Título da PR**: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
- **Autor**: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
- **Branch**: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
- **Target**: main
- **Reviewer (você)**: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
- **Data/Hora de Início**: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

---

## ⚠️ Questões Críticas (1-5: PARAR se falhar)

### ❓ Pergunta 1: Todos os commits são semânticos?

**Objetivo**: Validar que commits seguem Conventional Commits

**Como verificar**:
```bash
# Clone ou acesse o repo e execute:
git log main..REMOTE/BRANCH_NAME --oneline | head -20

# OU veja no GitHub:
# PR → Commits (aba)
# Verificar que TODOS commits têm formato:
# type(scope): 📝 descrição
```

**Formatos esperados**:
```
✅ feat(auth): 🎯 add multi-factor authentication
✅ fix(api): 🐛 resolve timeout issue in endpoint
✅ docs(readme): 📚 update installation instructions
✅ refactor(db): 🔄 optimize query performance
✅ test(utils): 🧪 add unit tests for helpers
✅ chore(deps): 🔧 upgrade spring-boot to 3.0
```

**Formatos INVÁLIDOS**:
```
❌ Fixed bug
❌ WIP: trying something
❌ asdfasdfsadf
❌ Update file
```

**Critério de Aprovação**:
- [ ] ✅ **TODOS** os commits são semânticos
- [ ] ❌ **FALHA**: Alguns commits não seguem formato

**Resultado**:
- ✅ **PASSA**: Prosseguir para pergunta 2
- ❌ **FALHA**: **PARAR AQUI** - Comentar na PR: "@author Por favor, faça rebase com commits semânticos. Use: `git rebase -i main`"

**Status**: [ ] ✅ PASSA | [ ] ❌ FALHA

---

### ❓ Pergunta 2: O autor é o correto?

**Objetivo**: Validar autoria dos commits

**Como verificar**:
```bash
# Clonar e checar:
git log main..REMOTE/BRANCH_NAME --format="%an <%ae>"

# OU no GitHub:
# PR → Commits → Verificar nome/email de cada commit
```

**Critérios aceitos**:
- [ ] ✅ Seu nome <seu.email@example.com>
- [ ] ✅ Kleilson Santos <kleilson@example.com>
- [ ] ✅ Co-authored-by: Name <email> (em commit message)

**Critérios rejeitados**:
- [ ] ❌ Autor desconhecido ou suspeito
- [ ] ❌ Bot commit sem referência apropriada
- [ ] ❌ GitHub user "Anonymous" ou sem email

**Status**: [ ] ✅ PASSA | [ ] ❌ FALHA

---

### ❓ Pergunta 3: Há breaking changes?

**Objetivo**: Detectar mudanças que quebram compatibilidade

**Como verificar**:
```bash
# Método 1: Procurar em commit messages
git log main..REMOTE/BRANCH_NAME --format=%b | grep -i "BREAKING CHANGE"

# Método 2: Procurar em diff
git diff main...REMOTE/BRANCH_NAME | grep -iE "BREAKING|breaking change"

# Método 3: Procurar por patterns suspeitos
git diff main...REMOTE/BRANCH_NAME | grep -iE "^-.*def |^-.*class |^-.*const |^-.*export"
```

**Exemplos de breaking changes**:
```
✅ BREAKING CHANGE: API endpoint /v1/users moved to /v2/users
✅ BREAKING CHANGE: Removed authentication via API key (use OAuth only)
✅ BREAKING CHANGE: Python 3.9+ required (was 3.7+)
```

**Checklist**:
- [ ] ✅ Sem breaking changes
- [ ] ✅ Com breaking changes, **TODOS documentados em CHANGELOG.md**
- [ ] ❌ Com breaking changes, **NÃO documentados**

**Documentação obrigatória**:
```markdown
# CHANGELOG.md

## [X.Y.Z] - YYYY-MM-DD

### ⚠️ BREAKING CHANGES
- Removed API endpoint `/v1/users` (use `/v2/users` instead)
- Changed authentication from API Key to OAuth 2.0

### Migration Guide
1. Update your API client to use `/v2/users`
2. Obtain OAuth token: [docs link]
```

**Status**: [ ] ✅ PASSA | [ ] ❌ FALHA

---

### ❓ Pergunta 4: Há conflitos com main?

**Objetivo**: Verificar se há merge conflicts

**Como verificar**:
```bash
# Via GitHub:
# PR → Arquivo "Conversation" mostra:
# ✅ "This branch has no conflicts"
# ❌ "This branch has conflicts that must be resolved"

# Via linha de comando:
git fetch origin
git merge --no-commit --no-ff origin/main
# Se tiver conflitos, você verá mensagens de conflict
git merge --abort
```

**Checklist**:
- [ ] ✅ Nenhum conflito - "This branch can be merged"
- [ ] ✅ Conflitos resolvidos - Branch está atualizada
- [ ] ❌ Conflitos não resolvidos - Rebase necessário

**Se houver conflitos**:
```bash
# Autor deve executar:
git fetch origin main
git rebase origin/main
# Resolver conflicts
git rebase --continue
git push -f origin BRANCH_NAME
```

**Status**: [ ] ✅ PASSA | [ ] ❌ FALHA

---

### ❓ Pergunta 5: Há credenciais ou secrets expostos?

**Objetivo**: Garantir nenhuma exposição de dados sensíveis

**Como verificar**:
```bash
# Método 1: Procurar padrões comuns
git diff main...REMOTE/BRANCH_NAME | grep -iE "password|api_key|secret|token|private_key|ssh_key"

# Método 2: Procurar .env commitado
git diff --name-only main...REMOTE/BRANCH_NAME | grep -E "\.env"

# Método 3: Procurar arquivos sensíveis
git diff --name-only main...REMOTE/BRANCH_NAME | grep -iE "\.key$|\.pem$|secret|credential"

# Método 4: Usar ferramenta automatizada
# (Se disponível no seu workflow)
```

**Exemplos de VIOLAÇÕES**:
```python
❌ api_key = "sk_live_123abc456def789ghi"
❌ password = "MyP@ssw0rd123"
❌ AWS_SECRET_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE
❌ ssh-rsa AAAAB3NzaC1yc2EAAAA... (private key)
```

**Exemplos SEGUROS**:
```python
✅ api_key = os.getenv("API_KEY")
✅ password_hash = bcrypt.hashpw(password, salt)
✅ AWS_SECRET_ACCESS_KEY = "${AWS_SECRET}"
✅ # SSH keys stored in ~/.ssh/config
```

**Checklist**:
- [ ] ✅ Nenhuma credencial exposta em plain text
- [ ] ✅ Nenhum arquivo `.env` commitado
- [ ] ✅ Nenhuma private key (.pem, .key) commitada
- [ ] ✅ Credenciais usando environment variables
- [ ] ❌ **FALHA**: Encontrados secrets em plain text

**Status**: [ ] ✅ PASSA | [ ] ❌ FALHA

**⚠️ SE FALHAR**: PARAR IMEDIATAMENTE
```
@author PARAR: Credenciais expostas detectadas!
Ações necessárias:
1. Remove o secret do commit: git rebase -i
2. Invalidar credencial comprometida
3. Fazer novo push
Link: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository
```

---

## 📚 Questões Secundárias (6-12: Avisar se falhar)

### ❓ Pergunta 6: A documentação está completa?

**Objetivo**: Validar documentação para mudanças de código

**Como verificar**:
```bash
# Listar arquivos modificados
git diff --name-only main...REMOTE/BRANCH_NAME

# Verificar se há mudanças de código
git diff --name-only main...REMOTE/BRANCH_NAME | grep -E "\.(py|js|ts|go|java|rb)$"

# Verificar documentação
git diff --name-only main...REMOTE/BRANCH_NAME | grep -E "\.md$|docs/"
```

**Checklist para código novo**:
- [ ] ✅ Comentários explicativos em código complexo
- [ ] ✅ Docstring/JavaDoc em funções/classes principais
- [ ] ✅ README.md atualizado (se necessário)
- [ ] ✅ docs/ atualizado com novas features
- [ ] ✅ CHANGELOG.md com entrada
- [ ] ⚠️ Código novo SEM documentação

**Checklist para documentação**:
- [ ] ✅ Exemplos de uso inclusos
- [ ] ✅ Diagramas/screenshots (se aplicável)
- [ ] ✅ Link para issue/ticket relacionado
- [ ] ⚠️ Documentação incompleta

**Status**: [ ] ✅ COMPLETA | [ ] ⚠️ AVISAR | [ ] ❌ INCOMPLETA

---

### ❓ Pergunta 7: Há arquivos críticos deletados?

**Objetivo**: Evitar deleção acidental de arquivos essenciais

**Como verificar**:
```bash
# Listar arquivos deletados
git diff --name-only --diff-filter=D main...REMOTE/BRANCH_NAME

# Listar com conteúdo deletado
git diff --diff-filter=D main...REMOTE/BRANCH_NAME
```

**Arquivos CRÍTICOS (não devem ser deletados)**:
- [ ] README.md
- [ ] docker-compose.yml
- [ ] Makefile
- [ ] .github/workflows/
- [ ] VERSION
- [ ] LICENSE
- [ ] pyproject.toml / package.json / go.mod
- [ ] .gitignore

**Checklist**:
- [ ] ✅ Nenhum arquivo crítico deletado
- [ ] ⚠️ Arquivo crítico deletado, **entender por quê**
- [ ] ❌ Arquivo crítico deletado sem justificativa

**Se critério CRÍTICO foi deletado**:
```
⚠️ @author Por que [ARQUIVO] foi deletado?
Se foi acidental, execute:
git revert [commit-hash]
Se foi intencional, adicione comentário explicativo.
```

**Status**: [ ] ✅ NENHUM DELETADO | [ ] ⚠️ INVESTIGAR | [ ] ❌ CRÍTICO DELETADO

---

### ❓ Pergunta 8: O escopo da PR é bem definido?

**Objetivo**: Validar que PR não mistura múltiplos escopos

**Como verificar**:
```bash
# Contar arquivos modificados
git diff --name-only main...REMOTE/BRANCH_NAME | wc -l

# Listar arquivos modificados
git diff --name-only main...REMOTE/BRANCH_NAME

# Verificar tipos de mudanças
git diff --shortstat main...REMOTE/BRANCH_NAME
```

**Orientações por tipo de PR**:

**Feature/Fix (esperado 1-5 arquivos)**:
```
✅ auth-feature/
├── src/auth.py (modificado)
├── tests/test_auth.py (novo)
└── docs/auth.md (novo)

❌ auth-feature/ (mistura escopos)
├── src/auth.py
├── src/payment.py (escopo diferente!)
├── src/database.py (escopo diferente!)
```

**Refatoração (esperado 10-50+ arquivos)**:
```
✅ refactor/rename-variables/
├── src/module1.py
├── src/module2.py
├── tests/test_module1.py
... (várias mudanças semelhantes)
```

**Checklist**:
- [ ] ✅ Escopo claro e focado (1-5 arquivos)
- [ ] ✅ Refatoração consistente (10+ arquivos, mesmo padrão)
- [ ] ⚠️ Escopo amplo (5-10 arquivos, misturado)
- [ ] ❌ Escopo muito misturado (múltiplas features)

**Se escopo misturado**:
```
⚠️ @author Escopo da PR parece misturado.
Você modificou:
- src/auth.py (auth feature)
- src/payment.py (payment feature)
- docs/readme.md (documentação)

Recomendação: Separar em múltiplas PRs para melhor rastreabilidade.
```

**Status**: [ ] ✅ BEM DEFINIDO | [ ] ⚠️ AVISAR | [ ] ❌ MUITO MISTURADO

---

### ❓ Pergunta 9: Há testes adicionados?

**Objetivo**: Validar cobertura de testes

**Como verificar**:
```bash
# Procurar novos testes
git diff --name-only main...REMOTE/BRANCH_NAME | grep -E "test_|_test\.py|\.test\.js|\.spec\.ts"

# Contar linhas de teste
git diff main...REMOTE/BRANCH_NAME | grep "^+" | grep -E "def test_|it\(|describe\(" | wc -l

# Verificar tipos de testes
git diff main...REMOTE/BRANCH_NAME | grep "^+.*def test_" | head -10
```

**Checklist**:

Para **Código novo**:
- [ ] ✅ Testes unitários adicionados
- [ ] ✅ Testes de integração (se aplicável)
- [ ] ✅ Coverage > 80%
- [ ] ⚠️ Alguns testes, mas cobertura baixa
- [ ] ❌ Nenhum teste adicionado

Para **Bug fixes**:
- [ ] ✅ Teste que reproduz o bug
- [ ] ✅ Teste que valida fix
- [ ] ⚠️ Fix sem teste
- [ ] ❌ Sem testes

Para **Refatoração**:
- [ ] ✅ Testes existentes passam (não quebrados)
- [ ] ⚠️ Testes modificados (entender por quê)

**Padrão esperado**:
```python
# SRC: src/calculator.py
class Calculator:
    def add(self, a, b):
        return a + b

# TEST: tests/test_calculator.py
def test_add_positive_numbers():
    calc = Calculator()
    assert calc.add(2, 3) == 5

def test_add_negative_numbers():
    calc = Calculator()
    assert calc.add(-2, 3) == 1
```

**Status**: [ ] ✅ COM TESTES | [ ] ⚠️ COBERTURA BAIXA | [ ] ❌ SEM TESTES

---

### ❓ Pergunta 10: As dependências foram atualizadas?

**Objetivo**: Validar mudanças em dependências

**Como verificar**:
```bash
# Procurar mudanças em dependency files
git diff --name-only main...REMOTE/BRANCH_NAME | grep -E "package.json|requirements.txt|pom.xml|go.mod|Gemfile"

# Ver diffs das dependências
git diff main...REMOTE/BRANCH_NAME -- package.json

# Procurar por commits sobre dependências
git log main...REMOTE/BRANCH_NAME --oneline | grep -iE "bump|update|upgrade|dependency|deps"
```

**Checklist**:

**Se há mudanças em dependências**:
- [ ] ✅ Documentadas em CHANGELOG.md
- [ ] ✅ Justificativa clara (bug fix, feature, security)
- [ ] ✅ Versão bump apropriada (semver)
- [ ] ⚠️ Mudanças sem documentação
- [ ] ❌ Mudanças sem justificativa

**Se sem mudanças em dependências**:
- [ ] ✅ N/A - Nenhuma mudança em dependências

**Padrão esperado em CHANGELOG.md**:
```markdown
## [1.2.0] - 2024-01-07

### Dependencies
- ✅ Upgrade spring-boot from 2.7.0 to 3.0.1 (security fix for CVE-2023-1234)
- ✅ Add lodash 4.17.21 (new utility functions needed)
- ✅ Remove deprecated axios-mock-adapter (replaced with jest.mock)
```

**Status**: [ ] ✅ DOCUMENTADAS | [ ] ⚠️ SEM DOCS | [ ] ✅ N/A

---

### ❓ Pergunta 11: A PR referencia uma issue ou ticket?

**Objetivo**: Rastrear PR para issue correspondente

**Como verificar**:
```bash
# Procurar referências em commit messages
git log main...REMOTE/BRANCH_NAME --format=%b | grep -iE "#[0-9]+|fixes|closes|resolves"

# OU verificar na PR description no GitHub
# GitHub UI → PR → Description (procurar "fixes #123")
```

**Formatos esperados**:
```
✅ fixes #123
✅ fixes #123, fixes #124
✅ closes #456
✅ resolves #789
✅ Related to #999
```

**Checklist**:
- [ ] ✅ PR referencia issue/ticket (#XXX)
- [ ] ✅ Múltiplas issues referenciadas (se aplicável)
- [ ] ⚠️ Sem referência de issue
- [ ] ⚠️ Referência unclear

**Se sem referência**:
```
⚠️ @author Adicione referência de issue:
Editar PR description e incluir:
"Fixes #123" ou "Closes #456"
Isso fecha a issue automaticamente quando PR é mergeada.
```

**Status**: [ ] ✅ COM REFERÊNCIA | [ ] ⚠️ SEM REFERÊNCIA

---

### ❓ Pergunta 12: Há comentários explicativos para código complexo?

**Objetivo**: Validar qualidade de código com documentação inline

**Como verificar**:
```bash
# Ver código novo
git diff main...REMOTE/BRANCH_NAME | grep "^+" | head -30

# Contar comentários em código novo
git diff main...REMOTE/BRANCH_NAME | grep "^+.*#.*[a-z]" | wc -l
git diff main...REMOTE/BRANCH_NAME | grep "^+.*//" | wc -l
git diff main...REMOTE/BRANCH_NAME | grep "^+.*/*" | wc -l
```

**Exemplos de código COMENTADO**:
```python
✅ def complex_algorithm(data):
    # Step 1: Normalize input data to handle edge cases
    normalized = normalize(data)

    # Step 2: Apply filter (expensive operation ~100ms)
    filtered = expensive_filter(normalized)

    # Step 3: Sort by relevance score (descending)
    return sorted(filtered, key=lambda x: -x['score'])
```

**Exemplos de código SEM COMENTÁRIO**:
```python
❌ def complex_algorithm(data):
    n = normalize(data)
    f = expensive_filter(n)
    return sorted(f, key=lambda x: -x['score'])
```

**Checklist**:
- [ ] ✅ Código complexo bem comentado
- [ ] ✅ Funções principais têm docstring
- [ ] ⚠️ Algumas partes complexas sem comentários
- [ ] ❌ Código complexo sem explicação

**Se código complexo sem comentários**:
```
⚠️ @author Adicione comentários para código complexo:
A função X faz Y, mas não está claro por quê.
Adicione comentários explicando:
- O que a lógica faz
- Por que é implementada assim
- Qualquer assunção ou edge case
```

**Status**: [ ] ✅ BEM COMENTADO | [ ] ⚠️ PARCIALMENTE | [ ] ❌ SEM COMENTÁRIOS

---

## 📊 Resultado Final - OPÇÃO 3

### Resumo de Respostas

**Questões Críticas (1-5)**:
- [ ] Pergunta 1: [ ] ✅ PASSA | [ ] ❌ FALHA
- [ ] Pergunta 2: [ ] ✅ PASSA | [ ] ❌ FALHA
- [ ] Pergunta 3: [ ] ✅ PASSA | [ ] ❌ FALHA
- [ ] Pergunta 4: [ ] ✅ PASSA | [ ] ❌ FALHA
- [ ] Pergunta 5: [ ] ✅ PASSA | [ ] ❌ FALHA

**Questões Secundárias (6-12)**:
- [ ] Pergunta 6: [ ] ✅ OK | [ ] ⚠️ AVISAR | [ ] ❌ FALHA
- [ ] Pergunta 7: [ ] ✅ OK | [ ] ⚠️ AVISAR | [ ] ❌ FALHA
- [ ] Pergunta 8: [ ] ✅ OK | [ ] ⚠️ AVISAR | [ ] ❌ FALHA
- [ ] Pergunta 9: [ ] ✅ OK | [ ] ⚠️ AVISAR | [ ] ❌ FALHA
- [ ] Pergunta 10: [ ] ✅ OK | [ ] ⚠️ AVISAR | [ ] ❌ FALHA
- [ ] Pergunta 11: [ ] ✅ OK | [ ] ⚠️ AVISAR | [ ] ❌ FALHA
- [ ] Pergunta 12: [ ] ✅ OK | [ ] ⚠️ AVISAR | [ ] ❌ FALHA

### Decisão Final

**⚠️ SE ALGUMA CRÍTICA (1-5) FALHAR**:
```
❌ OPÇÃO 3 FALHOU - NÃO PROCEDER PARA OPÇÃO 2

Comentar na PR:
@author PARAR na OPÇÃO 3.
Questão #X falhou: [motivo]
Ações necessárias: [ações]

Quando corrigido, faça ping novamente para re-review.
```

**✅ SE TODAS CRÍTICAS PASSAREM + SECUNDÁRIAS OK**:
```
✅ OPÇÃO 3 COMPLETA
→ Proceder para OPÇÃO 2: TESTAR

Próximo passo: Executar script
./scripts/enforce-pr-validation.sh #PR_NUMBER --verbose
```

**⚠️ SE CRÍTICAS PASSAM + SECUNDÁRIAS COM AVISOS**:
```
⚠️ OPÇÃO 3 COM AVISOS
→ Pode proceder para OPÇÃO 2 com cuidado

Documentar os avisos acima e proceder.
```

---

## 💬 Template de Comentário no GitHub

**Para OPÇÃO 3 PASSAR**:
```markdown
✅ **OPÇÃO 3 (Ler) COMPLETA**

Análise realizada:
- ✅ Commits semânticos
- ✅ Autor correto
- ✅ Sem breaking changes não documentados
- ✅ Sem conflitos com main
- ✅ Sem secrets expostos
- ✅ Documentação completa
- ✅ Nenhum arquivo crítico deletado
- ✅ Escopo bem definido
- ✅ Testes adicionados
- ✅ Dependências documentadas
- ✅ Issue referenciada (#123)
- ✅ Código bem comentado

**Próximo**: OPÇÃO 2 (Testar)
→ Executar: `./scripts/enforce-pr-validation.sh #PR_NUMBER --verbose`
```

**Para OPÇÃO 3 FALHAR**:
```markdown
❌ **OPÇÃO 3 (Ler) FALHOU**

Bloqueadores críticos:
- ❌ Pergunta 1: Alguns commits não são semânticos
  - Commit "asdf" não segue Conventional Commits
  - Ação: Rebase com `git rebase -i main` e use formato `feat:`, `fix:`, etc.

- ❌ Pergunta 5: Credencial exposta
  - Encontrado: `API_KEY="sk_live_123abc456"`
  - Ação: Remova imediatamente e invalide chave

**Não prosseguir para OPÇÃO 2 até corrigir acima.**
Faça ping quando pronto para re-review.
```

---

## 🎯 Próximos Passos

| Resultado | Ação |
|-----------|------|
| ✅ OPÇÃO 3 Passa | → Proceder para **OPÇÃO 2: Testar** |
| ❌ OPÇÃO 3 Falha | → **PARAR** e avisar autor |
| ⚠️ OPÇÃO 3 Avisos | → Documentar e proceder com cuidado |

---

<p align="center">
  <b>OPÇÃO 3: Ler (Análise) - Protocolo Canônico 3→2→1</b><br>
  <b>🔀 by Kleilson Santos</b>
</p>
