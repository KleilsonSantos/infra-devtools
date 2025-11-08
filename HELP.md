# 🆘 HELP - Guia Técnico Rápido

> Este arquivo contém referência técnica rápida e prática. Para documentação conceitual completa, veja [README.md](README.md).

## 📑 Índice

1. [Primeiros Passos](#primeiros-passos)
2. [Comandos Essenciais](#comandos-essenciais)
3. [Semantic Versioning](#semantic-versioning)
4. [Troubleshooting](#troubleshooting)
5. [Scripts Disponíveis](#scripts-disponíveis)

---

## 🚀 Primeiros Passos

### Inicialização do Projeto

```bash
# 1. Clone o repositório
git clone https://github.com/KleilsonSantos/infra-devtools.git
cd infra-devtools

# 2. Instale dependências e configure ambiente
chmod +x scripts/*.sh
./scripts/setup.sh

# 3. Inicie os serviços
make up

# 4. Valide a configuração
./scripts/validate-env.sh
```

---

## ⚡ Comandos Essenciais

### 🐳 Gerenciamento de Containers

| Comando | Descrição |
|---------|-----------|
| `make up` | Inicia todos os containers |
| `make down` | Para todos os containers |
| `make rebuild` | Reconstrói e inicia containers |
| `make logs` | Exibe logs em tempo real |
| `make ps` | Lista containers ativos |

### 🔍 Validação e Verificação

| Comando | Descrição |
|---------|-----------|
| `./scripts/validate-env.sh` | Valida arquivo .env |
| `./scripts/check-version-alignment.sh` | Verifica alinhamento de versões |
| `./scripts/run-dependency-check.sh` | Scan de vulnerabilidades |
| `make test` | Executa testes |

### 📦 Versioning

| Comando | Descrição |
|---------|-----------|
| `./scripts/version.sh show` | Exibe versão atual |
| `./scripts/version.sh check` | Verifica alinhamento |
| `./scripts/version.sh patch` | Bumpa patch (1.2.9 → 1.2.10) |
| `./scripts/version.sh minor` | Bumpa minor (1.2.9 → 1.3.0) |
| `./scripts/version.sh major` | Bumpa major (1.2.9 → 2.0.0) |

### 🔐 Segurança, Auditoria e Backup

| Comando | Descrição |
|---------|-----------|
| `make audit-full` | Auditoria completa de segurança |
| `make audit-images` | Scan de Docker images (Trivy) |
| `make audit-secrets` | Verifica secrets expostos |
| `make audit-permissions` | Análise de permissões de files |
| `make audit-deps` | Check de dependências (OWASP) |
| `make audit-code` | Análise estática (Bandit) |
| `make audit-compose` | Revisa segurança do docker-compose.yml |
| `make backup` | Cria backup de todos os serviços |
| `make backup-list` | Lista backups disponíveis |
| `make restore BACKUP_ID=<id>` | Restaura backup específico |
| `./scripts/encode-env.sh` | Codifica .env para GitHub secrets |

### 🔗 Hooks Git

| Comando | Descrição |
|---------|-----------|
| `./scripts/install-hooks.sh` | Instala Git Hooks com Husky |
| `./scripts/run-ci-local.sh` | Executa CI localmente com act |

---

## 🔖 Semantic Versioning

### Formato: MAJOR.MINOR.PATCH

```
MAJOR.MINOR.PATCH
│      │      └─ Correções de bugs (1.2.X)
│      └─────── Novas funcionalidades (1.X.0)
└──────────── Mudanças incompatíveis (X.0.0)
```

### Arquivos Sincronizados Automaticamente

```
VERSION (fonte de verdade)
    ↓
package.json
sonar-project.properties
CHANGELOG.md
Git Tags (v1.2.10)
```

### 📝 Workflow de Release

#### Passo 1: Verificar Versão Atual

```bash
./scripts/version.sh show
```

Saída esperada:
```
🔖 Current Version
VERSION file:     1.2.9
package.json:     1.2.9
sonar-project:    1.2.9
```

#### Passo 2: Bumpar Versão

**Para bug fix (recomendado para patches):**
```bash
./scripts/version.sh patch
# 1.2.9 → 1.2.10
```

**Para nova feature (recomendado para novas funcionalidades):**
```bash
./scripts/version.sh minor
# 1.2.9 → 1.3.0
```

**Para mudança incompatível (recomendado para breaking changes):**
```bash
./scripts/version.sh major
# 1.2.9 → 2.0.0
```

#### Passo 3: Revisar Mudanças

```bash
git diff
```

Você verá atualizações em:
- `VERSION`
- `package.json`
- `sonar-project.properties`
- `CHANGELOG.md` (nova entrada)

#### Passo 4: Confirmar Mudanças

```bash
git add .
git commit -m 'chore(release): bump to 1.2.10'
```

#### Passo 5: Fazer Push com Tags

```bash
git push
git push --tags
```

#### Passo 6: Confirmar Nova Versão

```bash
./scripts/version.sh check
```

### 🔗 Integração com Makefile

```bash
# Shortcut commands via Makefile
make version-patch    # → ./scripts/version.sh patch
make version-minor    # → ./scripts/version.sh minor
make version-major    # → ./scripts/version.sh major
make version-check    # → ./scripts/version.sh check
```

---

## 🐛 Troubleshooting

### ❌ Erro: ".env file not found"

```bash
# Solução: Copie .env.development
cp .env.development .env
nano .env  # Configure conforme necessário
```

### ❌ Erro: "Docker is not running"

```bash
# Solução: Inicie o Docker
docker --version  # Verifique instalação
# No Linux:
sudo systemctl start docker
```

### ❌ Erro: "Port already in use"

```bash
# Encontre qual processo usa a porta
lsof -i :9002  # Substitua 9002 pela porta

# Ou altere a porta no .env
SONARQUBE_PORT=9003
```

### ❌ Erro: "Version mismatch detected"

```bash
# Solução: Sincronize versões
./scripts/check-version-alignment.sh
# Siga as instruções para alinhamento
```

### ❌ Erro: "Containers not responding"

```bash
# Verifique saúde dos containers
make ps

# Veja logs de erro
make logs

# Reconstrua e reinicie
make rebuild
```

### ❌ Erro: "Permission denied" em scripts

```bash
# Dê permissão de execução
chmod +x scripts/*.sh

# Ou use explicitamente com bash
bash scripts/version.sh show
```

---

## 📦 Scripts Disponíveis

### `scripts/setup.sh`
Configura ambiente inicial (dependências, .env, diretórios)

```bash
./scripts/setup.sh
```

### `scripts/version.sh`
Gerencia versioning semântico

```bash
./scripts/version.sh {patch|minor|major|show|check|help}
```

### `scripts/validate-env.sh`
Valida configuração de ambiente

```bash
./scripts/validate-env.sh
```

### `scripts/check-version-alignment.sh`
Verifica alinhamento entre files de versão

```bash
./scripts/check-version-alignment.sh
```

### `scripts/run-dependency-check.sh`
Executa OWASP Dependency-Check

```bash
./scripts/run-dependency-check.sh [path]
```

### `scripts/backup.sh`
Sistema de backup para bancos e volumes

```bash
./scripts/backup.sh
```

### `scripts/encode-env.sh`
Codifica .env para GitHub secrets

```bash
./scripts/encode-env.sh
# Saída: Base64-encoded content pronto para copiar
```

### `scripts/install-hooks.sh`
Instala Git Hooks com Husky

```bash
./scripts/install-hooks.sh
```

### `scripts/run-ci-local.sh`
Executa CI localmente (requer 'act')

```bash
./scripts/run-ci-local.sh
```

---

## 🔐 Security Audit (Auditoria de Segurança)

A auditoria de segurança é um processo abrangente que verifica vulnerabilidades, secrets expostos e boas práticas de segurança.

### 📋 O que é verificado?

| Item | Ferramenta | O que detecta |
|------|-----------|--------------|
| **Docker Images** | Trivy | CVE vulnerabilities em imagens |
| **Secrets** | grep + patterns | Credentials hardcoded ou em .env |
| **Permissões** | find + stat | Files com permissões inseguras |
| **Dependências** | OWASP Dependency-Check | Vulnerabilities em bibliotecas |
| **Código** | Bandit | Security issues em Python |
| **docker-compose.yml** | Manual checks | Best practices de segurança |

### 🚀 Como Usar

**Auditoria Completa:**
```bash
make audit-full
# ou
./scripts/security-audit.sh full
```

**Auditorias Específicas:**
```bash
make audit-images       # Trivy scan
make audit-secrets      # Detectar secrets
make audit-permissions  # Analisar permissões
make audit-deps         # OWASP check
make audit-code         # Bandit analysis
make audit-compose      # docker-compose review
```

### 📊 Saída

Os relatórios são salvos em:
```
reports/security-audits/
├── audit_20251107_120000.json   (Dados estruturados)
└── audit_20251107_120000.html   (Relatório visual)
```

### ⏰ Execução Automática

A auditoria é executada **automaticamente todo trimestre** via GitHub Actions:
- 1º de janeiro (Q1)
- 1º de abril (Q2)
- 1º de julho (Q3)
- 1º de outubro (Q4)

Você pode também executar manualmente via GitHub Actions workflow.

### 🔍 Interpretando Resultados

**Critical:** Vulnerabilidades que precisam ser corrigidas imediatamente
**High:** Problemas de segurança significativos
**Medium:** Issues que devem ser endereçadas em breve
**Low:** Melhorias recomendadas

---

## 💚 Health Checks (Verificação de Saúde)

Valide a saúde de todos os serviços com um conjunto abrangente de testes.

### 🚀 Como Usar

**Health Check Completo:**
```bash
make health-check
# Executa todas as verificações
```

**Health Checks Específicos:**
```bash
make health-check-quick          # Apenas containers (rápido, ~5s)
make health-check-endpoints      # Testa HTTP endpoints (SonarQube, Grafana, etc)
make health-check-databases      # Valida conectividade de DBs
```

### 📊 O que é Verificado?

| Verificação | Detalhe |
|-------------|---------|
| **Containers** | Status (running/unhealthy/stopped) |
| **HTTP Endpoints** | Acessibilidade (SonarQube, Grafana, etc) |
| **Databases** | Conectividade (PostgreSQL, MongoDB, MySQL, Redis) |
| **Networking** | DNS resolution, rede Docker |
| **Resources** | Disco, Docker engine, volumes |

### 📄 Relatório

O resultado é salvo em:
```
reports/health-check.json
```

Contém:
- `health_percentage` - % de saúde geral
- `healthy` - Serviços saudáveis
- `unhealthy` - Serviços com problemas
- `status` - "operational" ou "degraded"

---

## 📊 Performance Monitoring (Monitoramento em Tempo Real)

Dashboard CLI para acompanhar métricas em tempo real.

### 🚀 Como Usar

**Dashboard Contínuo (30s refresh):**
```bash
make monitor
# Atualiza a cada 30 segundos
# Pressione Ctrl+C para sair
```

**Dashboard com Intervalo Customizado:**
```bash
./scripts/performance-monitor.sh watch 60
# Atualiza a cada 60 segundos
```

**Snapshot Único:**
```bash
make monitor-once
# Mostra uma vez e sai
```

### 📊 Métricas Exibidas

```
💻 SYSTEM RESOURCES
  • CPU Usage (bar chart)
  • Memory Usage (bar chart)
  • Disk Usage (bar chart)

🐳 CONTAINERS
  • Container count
  • Top containers by CPU

🌐 NETWORK
  • Network I/O

🚨 ALERTS
  • Alertas acima de thresholds
```

### ⚠️ Thresholds de Alerta

| Métrica | Warning | Critical |
|---------|---------|----------|
| CPU | 70% | 80% |
| Memory | 75% | 85% |
| Disk | 70% | 80% |

### 📈 Histórico

Métricas são registradas automaticamente em:
```
reports/metrics.log
```

Exemplo:
```
2025-11-07T14:30:45Z | CPU: 25% | Memory: 42% | Disk: 65%
2025-11-07T14:31:15Z | CPU: 28% | Memory: 43% | Disk: 65%
```

---

## 📊 ELK Stack (Logging Centralizado)

Centralize, processe e analise logs de todos os serviços com Elasticsearch, Logstash e Kibana.

### 🚀 Como Usar

**Iniciar ELK Stack:**
```bash
docker-compose up -d elasticsearch logstash kibana filebeat
```

**Inicializar (criar índices, políticas):**
```bash
make elk-init
```

**Acessar Kibana:**
```
http://localhost:5601
```

### 📊 Comandos

```bash
make elk-init          # Inicializar ELK (criar padrões, políticas)
make elk-verify        # Verificar conectividade
make elk-indexes       # Listar índices
make elk-stats         # Estatísticas do Elasticsearch
make elk-cleanup       # Limpar índices > 30 dias
make elk-logs          # Ver logs dos componentes
```

### 🔍 Buscas Rápidas (KQL)

**Em Kibana > Discover:**

```
# Erros
level: "ERROR"

# Container específico
container.name: "postgres"

# Últimas 24 horas com erro
level: "ERROR" AND @timestamp > now-24h

# Múltiplos containers
container.name: (postgres OR redis OR mongodb)
```

### 📚 Mais Informações

Para guia completo, veja: [docs/ELK-GUIDE.md](docs/ELK-GUIDE.md)

---

## 🔄 Jaeger (Distributed Tracing)

Rastreie requisições através de múltiplos serviços com Jaeger + OpenTelemetry.

### 🚀 Como Usar

**Iniciar Jaeger:**
```bash
docker-compose up -d jaeger-collector jaeger-agent
```

**Inicializar:**
```bash
make jaeger-init
```

**Acessar UI:**
```
http://localhost:16686
```

### 📊 Comandos

```bash
make jaeger-init              # Inicializar Jaeger
make jaeger-verify            # Verificar conectividade
make jaeger-services          # Listar serviços rastreados
make jaeger-traces service=api    # Ver traces de um serviço
make jaeger-operations service=api # Ver operações do serviço
make jaeger-stats             # Estatísticas
make jaeger-logs              # Ver logs dos componentes
```

### 🔌 Endpoints OpenTelemetry

```
gRPC:  localhost:4317   (Recomendado)
HTTP:  localhost:4318
```

### 🎯 Instrumentação Rápida

**Java (Auto):**
```bash
java -javaagent:opentelemetry-javaagent.jar \
  -Dotel.service.name=my-service \
  -Dotel.exporter.otlp.endpoint=http://localhost:4317 \
  -jar app.jar
```

**Python:**
```bash
pip install opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp
export OTEL_SERVICE_NAME=my-service
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
python app.py
```

**Node.js:**
```bash
npm install @opentelemetry/api @opentelemetry/sdk-node @opentelemetry/exporter-otlp-proto
# Importar tracing.js antes de app.js
node app.js
```

### 🔍 Análise de Traces

**Em Jaeger UI:**
1. Selecione serviço no dropdown
2. Escolha operation (GET /api/users)
3. Configure duração mín/máx
4. Clique "Find Traces"

**Exemplos:**
```
Buscar requisições lentas:   Min Duration: 1000ms
Buscar erros:                Min Duration: 0ms, Tags: error=true
Buscar por usuário:          Tags: user.id=123
```

### 📚 Mais Informações

Para guia completo, veja: [docs/TRACING-GUIDE.md](docs/TRACING-GUIDE.md)

---

## 🧪 APM (Application Performance Monitoring)

Monitoramento integrado de Métricas + Logs + Traces em Grafana.

### 🚀 Acessar APM

**Grafana:**
```
http://localhost:3001
Menu → Dashboards → Observability → Observability Integration
```

### 📊 Dashboards Disponíveis

1. **APM - Traces Overview** - Rastreamento em tempo real
   - Recent traces
   - Error rate
   - Request latency (P50/P95/P99)
   - Traces per second

2. **Observability - Metrics + Logs + Traces** - Integração completa
   - System health
   - Request rate
   - Log levels
   - Error traces correlatos

### 🔗 Correlação de Dados

**Traces → Logs:**
- Clique em uma trace
- Veja correlation ID
- Busque o mesmo correlation ID em Logs

**Logs → Traces:**
- Clique em trace_id em um log
- Abre a trace correspondente em Jaeger

**Métricas → Traces:**
- Veja latência alta em métrica
- Busque traces com mesmo período
- Investigue qual serviço causa problema

### 📚 Mais Informações

Para guia completo, veja: [docs/APM-INTEGRATION-GUIDE.md](docs/APM-INTEGRATION-GUIDE.md)

---

## 🔍 Verificações Pré-Merge (PR Validation)

O workflow `.github/workflows/pr-validation.yml` executa **9 validações automaticamente**:

### Opção 3: Análise de Documentação
- ✅ Coleta estatísticas da PR (commits, files, linhas)

### Opção 2: 7 Testes Obrigatórios
1. **Teste 1 - Formatos:** Valida YAML, shell scripts, JSON
2. **Teste 2 - Integridade:** Verifica arquivos críticos
3. **Teste 3 - Unit Tests:** Executa pytest
4. **Teste 4 - Segurança:** Scan de secrets, Bandit
5. **Teste 5 - Code Quality:** Flake8, ESLint
6. **Teste 6 - Compatibilidade:** Testa PostgreSQL
7. **Teste 7 - Ambiente:** Valida .env setup

### Opção 1: Merge PR
- ✅ Desbloqueado apenas se todos os testes passarem

---

## 📊 Portas Padrão dos Serviços

### 🔍 Monitoramento & Observabilidade

| Serviço | Porta | URL |
|---------|-------|-----|
| Prometheus | 9090 | http://localhost:9090 |
| Grafana | 3001 | http://localhost:3001 |
| Kibana (ELK) | 5601 | http://localhost:5601 |
| Elasticsearch | 9200 | http://localhost:9200 |
| Jaeger UI | 16686 | http://localhost:16686 |

### 🗂️ Gerenciamento & Admin

| Serviço | Porta | URL |
|---------|-------|-----|
| SonarQube | 9002 | http://localhost:9002 |
| Portainer | 9001 | http://localhost:9001 |
| pgAdmin | 8088 | http://localhost:8088 |
| phpMyAdmin | 8082 | http://localhost:8082 |
| Mongo Express | 8081 | http://localhost:8081 |
| RedisInsight | 8083 | http://localhost:8083 |
| Vault | 8200 | http://localhost:8200 |
| Keycloak | 8084 | http://localhost:8084 |

### 🔄 Integração (Traces & Logs)

| Serviço | Porta | Protocolo |
|---------|-------|-----------|
| Jaeger Agent | 6831 | UDP (Thrift) |
| Jaeger Collector gRPC | 14250 | gRPC |
| Jaeger Collector HTTP | 14268 | HTTP (Thrift) |
| OpenTelemetry gRPC | 4317 | gRPC |
| OpenTelemetry HTTP | 4318 | HTTP |
| Logstash | 5000 | TCP (Beats) |

---

## 📚 Referências Rápidas

### Estrutura de Commits (Conventional Commits)

```bash
feat: adiciona nova feature
fix: corrige um bug
docs: atualiza documentação
style: reformata código
refactor: refatora código
test: adiciona testes
chore: tarefas não-código
ci: altera CI/CD
```

### Como Usar Makefile

```bash
make help      # Lista todos os comandos
make <comando> # Executa comando
```

### Como Usar npm scripts

```bash
npm run start   # = make up
npm run stop    # = make down
npm run logs    # = make logs
npm run build   # = make build
```

---

## 🆘 Suporte Rápido

- 📖 **Documentação:** Veja [README.md](README.md)
- 🔒 **Segurança:** Veja [SECURITY.md](SECURITY.md)
- 🤝 **Contribuir:** Veja [CONTRIBUTING.md](CONTRIBUTING.md)
- 📋 **Changelog:** Veja [CHANGELOG.md](CHANGELOG.md)

---

## ⚡ Dicas Produtivas

### Verificação Rápida de Saúde

```bash
# Tudo em um comando
make down && make up && make logs
```

### Backup Antes de Mudanças Críticas

```bash
make backup
```

### Validação Completa Antes de Push

```bash
./scripts/validate-env.sh && \
./scripts/check-version-alignment.sh && \
./scripts/run-dependency-check.sh
```

### Reset Completo (Use com Cuidado!)

```bash
make down
docker system prune -a
make up
```

---

<p align="center">
<b>⚡ Dúvidas? Consulte README.md para documentação completa</b><br>
<b>🚀 by Kleilson Santos</b>
</p>
