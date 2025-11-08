# 🔒 Configuração de Branch Protection Rules

> Guia para configurar proteção de branch em GitHub seguindo Protocolo Canônico 3→2→1

## 📌 Localização no GitHub

```
Repository → Settings → Branches → Branch protection rules
https://github.com/KleilsonSantos/infra-devtools/settings/branches
```

---

## 🎯 Regras a Configurar

### 1. Criar Rule para Branch: `main`

#### Passo 1: Acessar Branch Protection

1. Vá para: **Settings > Branches**
2. Clique em **"Add rule"**
3. Em **"Branch name pattern"**, digite: `main`
4. Clique **"Create"**

#### Passo 2: Configurar Proteções

As seguintes opções devem estar **HABILITADAS** ✅:

### ✅ Opção 1: Require a pull request before merging

```
☑ Require a pull request before merging

     ☑ Require approvals (recomendado: 1 approval)
       Number of required approvals: 1

     ☑ Require review from code owners

     ☑ Dismiss stale pull request approvals when new commits are pushed

     ☑ Require approval of the most recent reviewable push
```

**Por quê**: Garante que toda mudança passa por PR formal

---

### ✅ Opção 2: Require status checks to pass before merging

```
☑ Require status checks to pass before merging

     ☑ Require branches to be up to date before merging

     Status checks that must pass:

     ☑ GitHub Actions (todos)
     ☑ build / (or any required workflow)
     ☑ test / (or any required workflow)
     ☑ lint / (or any required workflow)
```

**Por quê**: Garante que Actions passou (TESTE 7 do protocolo)

---

### ✅ Opção 3: Require conversation resolution before merging

```
☑ Require conversation resolution before merging
```

**Por quê**: Garante que todos comentários foram respondidos

---

### ✅ Opção 4: Require commits to be signed

```
☑ Require commits to be signed
```

**Por quê**: Auditoria de autoria de commits

---

### ✅ Opção 5: Require linear history

```
☑ Require linear history
```

**Por quê**: Garante merge commits (--no-ff obrigatório)

---

### ✅ Opção 6: Require merge commits (Essencial para 3→2→1)

```
☑ Require merge commits (em vez de squash ou rebase)
```

**Por quê**: Merge commit é OBRIGATÓRIO no protocolo 3→2→1

**Configuração específica**:
```
Merge method restrictions:
  ☐ Allow squash merging
  ☐ Allow rebase merging
  ☑ Allow merge commits (OBRIGATÓRIO)
```

---

### ✅ Opção 7: Restrict who can push to matching branches

```
☑ Restrict who can push to matching branches

     Users or teams with push access:
     ☑ KleilsonSantos (seu usuario)
     ☑ (adicionar co-maintainers se houver)
```

**Por quê**: Apenas maintainers podem fazer push

---

### ⚠️ Opção 8: Include administrators (Recomendado)

```
☑ Include administrators

     (Força que até admins sigam as regras)
```

**Por quê**: Nenhuma exceção, mesmo para admins

---

### ⏳ Opção 9: Allow force pushes (Manter DESABILITADO)

```
☐ Allow force pushes
   (DEVE estar desabilitado ❌)
```

**Por quê**: Force push apaga histórico - proibido

---

### 🗑️ Opção 10: Allow deletions (Manter DESABILITADO)

```
☐ Allow deletions
   (DEVE estar desabilitado ❌)
```

**Por quê**: Proteção contra deleção acidental de main

---

## 📋 Checklist de Configuração

Após preencher todas as opções, verify:

```
PROTEÇÕES DE PR:
☑ Require pull request before merging
☑ Require reviews (1 approval)
☑ Require review from code owners (se applicable)
☑ Dismiss stale approvals on new pushes
☑ Require latest changes approved

PROTEÇÕES DE QUALIDADE:
☑ Require status checks to pass
☑ Require branches up to date
☑ Require conversation resolution

PROTEÇÕES DE SEGURANÇA:
☑ Require signed commits
☑ Require merge commits
☑ Include administrators

PROTEÇÕES DE INTEGRIDADE:
☑ Require linear history
☑ Restrict push access
☑ Allow merge commits (SIM)
☑ Allow squash merging (NÃO)
☑ Allow rebase merging (NÃO)

TESTES/WORKFLOWS OBRIGATÓRIOS:
☑ GitHub Actions - pr-validation.yml
☑ (outros workflows se houver)

ALERTAS:
☐ Allow force pushes (desabilitado)
☐ Allow deletions (desabilitado)
```

---

## 🔍 Verificar Configuração

### Via GitHub UI

1. **Settings > Branches > Branch protection rules**
2. Clicar em **"main"**
3. Verificar que todos os checkboxes estão corretos

### Via GitHub API

```bash
# Listar regras de proteção
curl -H "Authorization: token YOUR_TOKEN" \
  https://api.github.com/repos/KleilsonSantos/infra-devtools/branches/main/protection

# Resposta esperada:
{
  "required_pull_request_reviews": {
    "dismissal_restrictions": {},
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  },
  "required_status_checks": {
    "strict": true,
    "contexts": ["GitHub Actions", "test"]
  },
  "required_linear_history": true,
  "enforce_admins": true,
  "restrict_who_can_push": {
    "users": [{"login": "kleilson"}]
  }
}
```

---

## 🚀 Integração com Protocolo 3→2→1

As branch protection rules **IMPLEMENTAM** os requisitos do protocolo:

### OPÇÃO 2 - Teste 7 (Actions Status)

```
Branch Protection Rule:
  "Require status checks to pass before merging"

↓

GitHub Actions devem passar (status = SUCCESS)

↓

Script enforce-pr-validation.sh verifica isso
```

---

### OPÇÃO 1 - Merge Commit Obrigatório

```
Branch Protection Rule:
  "Require merge commits" (desabilitar squash e rebase)

↓

Merge commit OBRIGATÓRIO (--no-ff)

↓

Protocolo 3→2→1 fica no histórico (merge commit message)
```

---

### OPÇÃO 3 - Code Owner Review

```
Branch Protection Rule:
  "Require review from code owners"

↓

Se CODEOWNERS arquivo existir, PR precisa de review

↓

Garante OPÇÃO 3 (análise) foi feita por alguém
```

---

## 📝 Arquivo CODEOWNERS (Opcional)

Se quiser usar "Require review from code owners":

1. Criar arquivo: `.github/CODEOWNERS`
2. Conteúdo:
```
# Padrão git ignore + @username

* @KleilsonSantos

# Específicos por pasta
docs/ @KleilsonSantos
scripts/ @KleilsonSantos
.github/ @KleilsonSantos
```

3. Commit e push
4. GitHub passa a exigir review desses users

---

## 🧪 Testar as Regras

### Teste 1: PR sem status checks

```bash
# 1. Criar branch e push sem dar push à origem
git checkout -b test/rule-1
echo "test" > test.txt
git add test.txt
git commit -m "test: rule 1"
git push -u origin test/rule-1

# 2. Tentar mergear via GitHub UI
# Esperado: ❌ BLOQUEADO - "Some checks haven't completed yet"
```

### Teste 2: PR com merge rebase ao invés de merge commit

```bash
# Se tentar rebase (squash)
# Esperado: ❌ BLOQUEADO - "Squash merging is not allowed"
```

### Teste 3: Merge direto em main

```bash
# Tentar
git push origin test/rule-1:main

# Esperado: ❌ BLOQUEADO - "Pushing to protected branches is not allowed"
```

### Teste 4: Force push

```bash
# Tentar
git push -f origin main

# Esperado: ❌ BLOQUEADO - "Force push not allowed"
```

---

## ⚠️ Notas Importantes

### 1. CODEOWNERS Review vs PR Approval

```
"Require review from code owners" = Requer review de @username em CODEOWNERS
"Require approvals" = Requer 1+ "Approve" button clicado

→ Geralmente configurar AMBOS para máxima proteção
```

### 2. Status Checks Selection

```
Ao habilitar "Require status checks to pass":
→ GitHub Actions irá aparecer
→ Selecionar "GitHub Actions" (covers all workflows)
→ OU selecionar workflows específicos (pr-validation.yml, etc)
```

### 3. Branches to be up to date

```
"Require branches to be up to date before merging"
→ PR deve ser rebased em main antes de merge
→ Essencial para protocolo 3→2→1 (OPÇÃO 2)
```

### 4. Administradores Inclusos

```
"Include administrators"
→ Força que TODOS sigam as regras (sem exceções)
→ RECOMENDADO para máxima conformidade
```

---

## 📊 Exemplo de Saída

Após configuração correta, PR terá:

```
✅ All checks have passed
  ✅ pr-validation / validate-workflow (passed)
  ✅ pr-validation / test-suite (passed)
  ✅ pr-validation / format (passed)
  ✅ 1 approval by maintainer
  ✅ All conversations resolved
  ✅ Commits signed

✅ This branch can be merged
   (Merge commit obrigatório - --no-ff)
```

---

## 🔐 Conformidade com Protocolo

Essas regras **garantem** que:

```
✅ OPÇÃO 3 foi executada
   (Requer approval/review)

✅ OPÇÃO 2 passou
   (Requer status checks = SUCCESS)

✅ OPÇÃO 1 é formal
   (Requer merge commit, não squash)

✅ Rastreabilidade completa
   (Linear history, merge commits, signed commits)

✅ Segurança
   (Ninguém (nem admins) pode pular regras)
```

---

<p align="center">
  <b>Branch Protection + Protocolo 3→2→1 = Sistema Profissional Completo</b><br>
  <b>🔒 by Kleilson Santos</b>
</p>
