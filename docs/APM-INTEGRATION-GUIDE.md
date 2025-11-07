# 🧪 APM Integration Guide - Observability 3 Pillars

> Complete integration of Metrics, Logs, and Traces in Grafana for Application Performance Monitoring

## 📑 Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura](#arquitetura)
3. [Quick Start](#quick-start)
4. [Configuração de Datasources](#configuração-de-datasources)
5. [Dashboards](#dashboards)
6. [Correlação de Dados](#correlação-de-dados)
7. [Alertas e SLO](#alertas-e-slo)
8. [Troubleshooting](#troubleshooting)

---

## Visão Geral

### O que é APM?

APM (Application Performance Monitoring) é a prática de coletar, agregar e analisar dados sobre o desempenho, disponibilidade e comportamento de aplicações.

### 3 Pilares da Observabilidade

```
┌─────────────────────────────────────────────────────┐
│     OBSERVABILIDADE - 3 PILARES INTEGRADOS         │
├─────────────────────────────────────────────────────┤
│                                                     │
│  📊 MÉTRICAS (Prometheus)                          │
│  └─ O QUÊ: Quantidades mensuráveis                 │
│     ├─ CPU, Memory, Disk                           │
│     ├─ Request Rate, Error Rate                    │
│     ├─ Latency (P50, P95, P99)                     │
│     └─ Custom metrics                              │
│                                                     │
│  📋 LOGS (Elasticsearch + Kibana)                  │
│  └─ POR QUÊ: Eventos detalhados                    │
│     ├─ Application logs                            │
│     ├─ Error stacktraces                           │
│     ├─ User actions                                │
│     └─ System events                               │
│                                                     │
│  🔄 TRACES (Jaeger + OpenTelemetry)                │
│  └─ COMO: Jornada completa da requisição           │
│     ├─ Request flow across services                │
│     ├─ Dependency mapping                          │
│     ├─ Latency breakdown                           │
│     └─ Error propagation                           │
│                                                     │
│  ═══════════════════════════════════════════════    │
│  🎯 CORRELAÇÃO: Juntar os 3 para:                   │
│     • Root cause analysis                          │
│     • Performance optimization                     │
│     • Incident response                            │
│     • Proactive monitoring                         │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Por que integrar?

Isolados:
```
❌ Métrica alta → Qual serviço?
❌ Log de erro → De qual requisição?
❌ Trace lento → Por que?
```

Integrados:
```
✅ Métrica alta → Ver logs correlatos → Analisar trace detalhado
✅ Error log → Buscar trace por correlation ID → Ver contexto completo
✅ Trace lento → Verificar métricas → Investigar logs específicos
```

---

## Arquitetura

### Fluxo de Dados

```
┌────────────────────────────────────────────────────────────┐
│                   APLICAÇÕES                               │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  Emite:                                                    │
│  • Métricas → Prometheus exposition format                │
│  • Logs → stdout/stderr → Filebeat                        │
│  • Traces → OpenTelemetry protocol                        │
│                                                             │
└────────────────────────────────────────────────────────────┘
         ↓                    ↓                    ↓
    ┌─────────┐         ┌──────────┐        ┌──────────┐
    │Prometheus         │Filebeat  │        │Jaeger    │
    │:9090   │         │Agent  │        │Agent │
    └────┬────┘         └────┬──────┘        └────┬─────┘
         │                   │                    │
    ┌────▼────┐         ┌────▼──────┐        ┌────▼──────┐
    │ES/Thanos         │Logstash   │        │Collector  │
    │Storage  │         │Pipeline   │        │Storage    │
    └────┬────┘         └────┬──────┘        └────┬──────┘
         │                   │                    │
         └───────────┬───────┴────────────────────┘
                     │
              ┌──────▼──────┐
              │   GRAFANA   │
              │  Dashboard  │
              │             │
              │ • Datasources
              │   ├─ Prometheus (Metrics)
              │   ├─ Elasticsearch (Logs)
              │   └─ Jaeger (Traces)
              │
              │ • Dashboards
              │   ├─ Metrics overview
              │   ├─ Traces overview
              │   ├─ Logs analysis
              │   └─ Integrated APM
              │
              └─────────────┘
```

### Integração em Grafana

```
Grafana Datasources Configuration:
├─ Prometheus (Métricas)
│  └─ Endpoint: http://prometheus:9090
│
├─ Elasticsearch (Logs)
│  ├─ Endpoint: http://elasticsearch:9200
│  ├─ Index: logs-*
│  └─ Time Field: @timestamp
│
└─ Jaeger (Traces)
   ├─ Endpoint: http://jaeger-collector:16686
   └─ Integrations:
      ├─ Traces → Logs (via Correlation ID)
      └─ Traces → Metrics (via Service Names)
```

---

## Quick Start

### 1️⃣ Iniciar Stack Completa

```bash
# Iniciar todos os serviços
docker-compose up -d

# Ou iniciar apenas observabilidade
docker-compose up -d \
  prometheus grafana \
  elasticsearch kibana logstash filebeat \
  jaeger-collector jaeger-agent
```

### 2️⃣ Verificar Integrações

```bash
# Grafana
open http://localhost:3001

# Prometheus
open http://localhost:9090

# Kibana
open http://localhost:5601

# Jaeger UI
open http://localhost:16686
```

### 3️⃣ Verificar Datasources em Grafana

1. Vá em: **Grafana > Settings > Data Sources**
2. Você deve ver:
   - ✅ **Prometheus** (Métricas)
   - ✅ **Elasticsearch** (Logs)
   - ✅ **Jaeger** (Traces)

Se algum estiver faltando, configure manualmente (veja próxima seção).

### 4️⃣ Acessar Dashboards

Em Grafana:
- **Menu > Dashboards > Observability** (pasta auto-criada)
- Você deve ver:
  - 🔄 APM - Traces Overview
  - 🧪 Observability - Metrics + Logs + Traces Integration

---

## Configuração de Datasources

### Configuração Automática

Os datasources são configurados automaticamente via:

```yaml
# grafana/provisioning/datasources.yml
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090

  - name: Elasticsearch
    type: elasticsearch
    url: http://elasticsearch:9200

  - name: Jaeger
    type: jaeger
    url: http://jaeger-collector:16686
```

### Configuração Manual (se necessário)

**Se o arquivo de provisioning não funcionar:**

1. **Adicionar Prometheus:**
   - Grafana > Settings > Data Sources > Add
   - Type: Prometheus
   - URL: http://prometheus:9090
   - Click Save & Test

2. **Adicionar Elasticsearch:**
   - Type: Elasticsearch
   - URL: http://elasticsearch:9200
   - Index name: logs-*
   - Time field: @timestamp
   - Click Save & Test

3. **Adicionar Jaeger:**
   - Type: Jaeger
   - URL: http://jaeger-collector:16686
   - Click Save & Test

### Verificar Conexão

```bash
# Prometheus
curl http://localhost:9090/api/v1/targets

# Elasticsearch
curl http://localhost:9200/_cluster/health

# Jaeger
curl http://localhost:16686/api/services
```

---

## Dashboards

### Dashboard 1: APM - Traces Overview

**Propósito:** Visualizar traces em tempo real e análise de performance

**Panels:**
1. **Recent Traces** - Últimas 20 requisições com duração
2. **Error Rate (5m window)** - Taxa de erro ao longo do tempo
3. **Traces Per Second** - Throughput do sistema
4. **Request Latency (P50/P95/P99)** - Distribuição de latência

**Como Usar:**
```
1. Abra dashboard
2. Procure por traces problemáticas (alto tempo, erros)
3. Clique em uma trace para detalhar
4. Veja timeline de spans
5. Correlacione com logs via Correlation ID
```

### Dashboard 2: Observability - Metrics + Logs + Traces Integration

**Propósito:** Visão integrada de toda a observabilidade

**Panels:**
1. **System Health** - Saúde geral do sistema
2. **Memory Status** - Utilização de memória
3. **Error Count (24h)** - Total de erros nas últimas 24h
4. **Traced Services** - Quantos serviços estão sendo rastreados
5. **Request Rate by Method & Status** - Taxa de requisições por tipo
6. **Log Levels Over Time** - Distribuição de níveis de log
7. **Error Traces (Last 50)** - Últimas 50 traces com erro

**Como Usar:**
```
1. Monitorar saúde geral do sistema
2. Identificar spikes de erro
3. Correlacionar com logs/traces
4. Usar como "status page" da infraestrutura
```

---

## Correlação de Dados

### 1. Traces → Logs

**Como funciona:**
- Cada trace tem um `trace_id` único
- Logs correlatos também têm esse `trace_id`
- Grafana pode linkar traces para logs automáticamente

**Configurar linkagem:**

No datasource Jaeger, adicionar:
```yaml
tracesToLogs:
  datasourceUid: 'Elasticsearch'  # UUID do datasource Elasticsearch
  tags: ['trace_id']              # Tags para procurar
  mappedFields:
    - source: 'trace_id'          # Campo no trace
      target: 'trace_id'          # Campo no log
```

**Usar:**
```
1. Abra uma trace em Jaeger
2. Veja campos: trace_id, span_id, etc.
3. Procure por esse trace_id em Logs
4. Veja logs correlatos ordenados por timestamp
```

### 2. Traces → Métricas

**Como funciona:**
- Extrair métricas de traces (latência, erro rate)
- Correlacionar com métricas do Prometheus

**Exemplo de query:**
```promql
# Latência do serviço X (do Prometheus)
histogram_quantile(0.99, sum(rate(span_duration_bucket{service="api"}[5m])) by (le))

# Trace do serviço X (do Jaeger)
# Buscar traces com service="api" e duration > P99
```

**Usar para:**
- Investigar por que latência subiu
- Correlacionar com CPU/memory
- Análise de causa raiz

### 3. Logs → Traces

**Como funciona:**
- Se um log tem `trace_id`, clickar nele vai para o Jaeger
- Grafana configura links automáticos

**Configurar:**
```yaml
# No datasource Elasticsearch:
jsonData:
  traceLinkFields: ['trace_id']
  traceLinkUrl: 'http://jaeger-collector:16686/trace/${trace_id}'
```

---

## Alertas e SLO

### 1. Alertas por Métrica

**Em Grafana:**
```
1. Dashboard > Panel > Edit
2. Alert tab
3. Configure:
   - Condition: Error Rate > 5%
   - Duration: For 5m
   - Notification: Send to Slack
```

**Exemplos de alertas:**

```yaml
groups:
  - name: apm_alerts
    rules:
      # Error rate alto
      - alert: HighErrorRate
        expr: rate(traces_error_total[5m]) > 0.05
        for: 5m

      # Latência alta
      - alert: HighLatency
        expr: histogram_quantile(0.99, rate(span_duration_bucket[5m])) > 1000
        for: 5m

      # Serviço down
      - alert: ServiceDown
        expr: up{job="api"} == 0
        for: 1m
```

### 2. SLO (Service Level Objectives)

**Definir SLO:**
```
API Service:
├─ Availability: 99.9%   (max 43 minutes/month downtime)
├─ Latency P99: < 500ms  (99% of requests < 500ms)
├─ Error Rate: < 0.1%    (max 0.1% errors)
```

**Configurar em Grafana:**

1. **Criar metric:**
   ```promql
   # Availability
   sum(rate(http_requests_total{status=~"2.."}[5m])) /
   sum(rate(http_requests_total[5m]))
   ```

2. **Criar dashboard panel:**
   ```
   - Query: metric acima
   - Threshold: 99.9%
   - Colorir: green se ≥ 99.9%, red se < 99.9%
   ```

3. **Setup alertas:**
   - Se < 99.9%, trigger alert
   - Notify oncall engineer

---

## Troubleshooting

### ❌ Datasources não conectam

**Problema:** Datasource shows "Error"

```bash
# Verificar conectividade
curl http://prometheus:9090/api/v1/targets
curl http://elasticsearch:9200/_cluster/health
curl http://jaeger-collector:16686/api/services

# Se falhar, verificar network
docker network inspect infra-default-shared-net
```

**Solução:**
- Verificar se containers estão rodando: `docker ps`
- Verificar logs: `docker logs <container>`
- Reiniciar datasource em Grafana

### ❌ Dashboards em branco

**Problema:** Panels não mostram dados

```
1. Verificar datasource está selecionado (dropdown)
2. Verificar query está correta (Edit panel)
3. Verificar dados existem no datasource:
   - Prometheus: http://localhost:9090/graph
   - Elasticsearch: http://localhost:5601
   - Jaeger: http://localhost:16686
```

**Solução:**
- Se não há dados, instrumentar aplicação para gerar dados
- Aguardar alguns minutos para dados aparecer
- Verificar timerange do dashboard

### ❌ Correlação não funciona

**Problema:** Não consigo ir de Trace para Log

**Causa comum:** `trace_id` campo diferente em cada sistema

```
Jaeger: traceID
Elasticsearch: trace_id
Prometheus: trace_id

→ Ajustar configuração de mapping
```

**Solução:**
1. Edit Jaeger datasource
2. Configure tracesToLogs
3. Mapear campos corretamente:
   ```
   source: "traceID"    (Jaeger)
   target: "trace_id"   (Elasticsearch)
   ```

### ❌ Performance lenta

**Se Grafana/dashboards lentos:**

1. **Reduzir período de dados:**
   - Mudar timerange para 1h ao invés de 7d
   - Usar sampling em traces

2. **Desabilitar alguns panels:**
   - Muito pesado: Error Traces (pode ter 1000+ traces)
   - Filtrar dados: `tags="error=true"` ao invés de tudo

3. **Aumentar recursos:**
   ```yaml
   # docker-compose.yml
   grafana:
     mem_limit: 2G  # Aumentar de 1G
     memswap_limit: 2G
   ```

---

## Referência Rápida

### Makefile Commands

Não há comandos específicos para APM, use docker-compose diretamente:

```bash
# Iniciar stack
docker-compose up -d

# Parar
docker-compose down

# Ver logs
docker logs infra-default-grafana
docker logs infra-default-prometheus
docker logs infra-default-elasticsearch
```

### URLs

```
🖥️  Grafana (Dashboards):     http://localhost:3001
📊 Prometheus (Métricas):    http://localhost:9090
📋 Kibana (Logs):            http://localhost:5601
🔄 Jaeger UI (Traces):       http://localhost:16686
```

### Usuários Padrão

```
Grafana:
  Username: admin (ou configurado em .env)
  Password: admin (ou configurado em .env)

Kibana:
  Username: elastic
  Password: changeme

Jaeger:
  (Sem autenticação padrão)
```

### Environment Variables (em .env)

```bash
# Grafana
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=admin
GF_AUTH_ANONYMOUS_ENABLED=true
GF_AUTH_DISABLE_LOGIN_FORM=false

# Elasticsearch
ELASTIC_PASSWORD=changeme
ES_JAVA_OPTS=-Xms512m -Xmx512m

# Prometheus (default no docker-compose)
# Logstash (configurado para Elasticsearch)
# Jaeger (default)
```

---

## Next Steps

1. **Instrumentar aplicações:**
   - Adicionar OpenTelemetry SDK
   - Gerar métricas, logs, traces
   - Veja TRACING-GUIDE.md para exemplos

2. **Criar alertas customizados:**
   - Definir SLOs específicos
   - Setup notificações (Slack, PagerDuty)
   - Auto-remediation rules

3. **Otimizar dashboards:**
   - Adicionar visualizações customizadas
   - Criar alerting rules
   - Setup automation

4. **Monitoramento contínuo:**
   - Daily reviews de alertas
   - Weekly SLO reviews
   - Mensal incident post-mortems

---

<p align="center">
  <b>Observabilidade Integrada = Visibilidade Total = Confiança em Produção</b><br>
  <b>🚀 by Kleilson Santos</b>
</p>
