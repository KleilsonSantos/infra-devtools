# 📊 ELK Stack Guide - Complete Logging Solution

> Elasticsearch + Logstash + Kibana: Centralized logging, searching, and analytics

## 📑 Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura](#arquitetura)
3. [Quick Start](#quick-start)
4. [Elasticsearch](#elasticsearch)
5. [Kibana](#kibana)
6. [Logstash](#logstash)
7. [Filebeat](#filebeat)
8. [Queries e Análise](#queries-e-análise)
9. [Performance Tuning](#performance-tuning)
10. [Troubleshooting](#troubleshooting)

---

## Visão Geral

### O que é ELK Stack?

O ELK Stack é uma solução completa de logging baseada em três componentes principais:

- **Elasticsearch:** Motor de busca distribuído para armazenar e indexar logs
- **Logstash:** Pipeline de processamento para coletar, processar e enriquecer dados
- **Kibana:** Interface de visualização e análise de dados

### Por que você precisa?

Sem logs centralizados:
- ❌ Logs perdidos quando container reinicia
- ❌ Impossível debugar problemas em produção
- ❌ Sem correlação entre serviços
- ❌ Sem histórico de eventos

Com ELK Stack:
- ✅ Retenção de 30 dias de logs
- ✅ Busca rápida e poderosa
- ✅ Visualizações e dashboards
- ✅ Alertas baseados em padrões
- ✅ Correlação cross-service

---

## Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                    DOCKER CONTAINERS                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │  App Logs   │  │ App Logs    │  │ App Logs    │    │
│  │ (stdout)    │  │ (stdout)    │  │ (stdout)    │    │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘    │
│         │                │                │           │
│         └────────────────┼────────────────┘           │
│                          │                            │
│         ┌────────────────▼────────────────┐           │
│         │  Docker Container Logs          │           │
│         │  (/var/lib/docker/containers)   │           │
│         └────────────────┬────────────────┘           │
│                          │                            │
└──────────────────────────┼────────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │  Filebeat   │ (Log Shipper)
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │  Logstash   │ (Processor)
                    │  Pipeline   │
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   ┌────▼────┐      ┌──────▼─────┐     ┌─────▼───┐
   │   ES    │      │   Kibana   │     │ Alerter │
   │ Storage │      │  Analytics │     │ Trigger │
   └─────────┘      └────────────┘     └─────────┘
```

### Fluxo de Dados

1. **Containers** produzem logs (stdout/stderr)
2. **Filebeat** coleta logs dos containers
3. **Logstash** processa, filtra e enriquece
4. **Elasticsearch** armazena e indexa
5. **Kibana** visualiza e analisa

---

## Quick Start

### 1️⃣ Iniciar ELK Stack

```bash
# Iniciar todos os serviços (incluindo ELK)
docker-compose up -d

# Ou iniciar apenas ELK
docker-compose up -d elasticsearch logstash kibana filebeat
```

### 2️⃣ Inicializar

```bash
# Criar index patterns, políticas de retenção
make elk-init
```

### 3️⃣ Verificar Status

```bash
make elk-verify
```

### 4️⃣ Acessar Kibana

Abra no navegador: **http://localhost:5601**

---

## Elasticsearch

### O que é?

Motor de busca distribuído que armazena e indexa logs em documentos JSON.

### Endpoints Úteis

```bash
# Health check
curl http://localhost:9200/_cluster/health

# List indexes
curl http://localhost:9200/_cat/indices?v

# Index stats
curl http://localhost:9200/_stats

# Search logs
curl -X GET "http://localhost:9200/logs-*/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match": {
        "message": "error"
      }
    }
  }'
```

### Index Management

```bash
# Ver índices
make elk-indexes

# Ver estatísticas
make elk-stats

# Limpar índices antigos (>30 dias)
make elk-cleanup
```

### Configuração

No `docker-compose.yml`:
- **Memory:** 512MB (ajustável)
- **Discovery:** Single node (produção: cluster)
- **Security:** Desativado (ativar em produção)
- **Retenção:** 30 dias (configurável)

---

## Kibana

### O que é?

Interface visual para explorar, visualizar e analisar logs armazenados no Elasticsearch.

### Features

✅ **Discover:** Explorar logs em tempo real
✅ **Visualizations:** Gráficos, métricas, tabelas
✅ **Dashboards:** Painéis customizados
✅ **Alerts:** Notificações automáticas
✅ **Dev Tools:** Console para queries

### Acessar

- **URL:** http://localhost:5601
- **Usuário:** elastic (se segurança estiver ativa)
- **Senha:** changeme

### Primeiros Passos

1. Acesse http://localhost:5601
2. Vá em **Stack Management** > **Index Patterns**
3. Create index pattern: `logs-*`
4. Set time field: `@timestamp`
5. Vá em **Discover** para ver logs

### Queries (KQL - Kibana Query Language)

```
# Buscar erro
message: "error"

# Buscar por container
container.name: "postgres"

# Buscar por severity
level: "ERROR"

# Buscar por range de tempo
@timestamp > now-1h

# Combinar condições
level: "ERROR" AND container.name: "api"
```

---

## Logstash

### O que é?

Pipeline de processamento que coleta, filtra, transforma e enriquece logs.

### Arquitetura do Pipeline

```
Input (Filebeat)
    ↓
Filter (Parse, Enrich, Transform)
    ↓
Output (Elasticsearch)
```

### Configuração

Localizado em: `config/logstash.conf`

```ruby
# INPUT: Recebe logs do Filebeat
input {
  beats {
    port => 5000
  }
}

# FILTER: Processa logs
filter {
  # Parse JSON
  json { source => "message" }

  # Extract fields
  grok { match => { "message" => "..." } }

  # Add metadata
  mutate { add_field => { "env" => "production" } }
}

# OUTPUT: Envia para Elasticsearch
output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "logs-%{+YYYY.MM.dd}"
  }
}
```

### Plugins Instalados

- `logstash-filter-json` - Parse JSON
- `logstash-filter-grok` - Pattern matching
- `logstash-filter-mutate` - Modify fields
- `logstash-output-elasticsearch` - ES output

### Monitorar Logstash

```bash
# Ver logs
make elk-logs

# Check metrics (Port 9600)
curl http://localhost:9600/_node/stats/jvm
```

---

## Filebeat

### O que é?

Lightweight log shipper que coleta logs de containers Docker e os envia para Logstash.

### Configuração

Localizado em: `config/filebeat.yml`

```yaml
filebeat.inputs:
  - type: container
    paths:
      - '/var/lib/docker/containers/*/*.log'
    json.message_key: log
    processors:
      - add_docker_metadata:
          host: "unix:///var/run/docker.sock"

output.logstash:
  hosts: ["logstash:5000"]
```

### Recursos

- ✅ Coleta de Docker container logs
- ✅ Parsing JSON automático
- ✅ Metadata do container
- ✅ Backpressure handling
- ✅ Low resource usage

### Metrics

Filebeat expõe métricas no port **5066**:

```bash
curl http://localhost:5066/stats
```

---

## Queries e Análise

### KQL (Kibana Query Language)

#### Exemplos Básicos

```
# Buscar texto
message: "connection error"

# Buscar por campo
level: "ERROR"
container.name: "postgres"

# Operadores lógicos
level: "ERROR" AND service: "api"
level: "ERROR" OR level: "WARN"

# Negação
NOT message: "health check"

# Wildcard
container.name: "postgres*"

# Range
@timestamp >= now-1h
http.status: >= 500
```

#### Exemplos Complexos

```
# Erros no último 1 hora
level: "ERROR" AND @timestamp > now-1h

# Requisições lentas
http.response_time > 5000 AND @timestamp > now-30m

# Erros de conexão por serviço
message: "Connection refused" | stats count() by container.name

# Taxa de erro por hora
level: "ERROR" | stats count() by @timestamp
```

### Agregações

```
# Contar erros por container
message: "error" | stats count() by container.name

# Valor máximo de latência
http.response_time | stats max(http.response_time)

# Percentil
http.response_time | stats percentiles(http.response_time)

# Cardinality
container.id | stats cardinality(container.id)
```

### Visualizações

1. **Discover:** Explorar logs brutos
2. **Bar Chart:** Contar eventos
3. **Line Chart:** Tendências ao longo do tempo
4. **Pie Chart:** Distribuição
5. **Metric:** Valor único
6. **Table:** Dados estruturados

---

## Performance Tuning

### Elasticsearch

```bash
# Aumentar heap memory
# No docker-compose.yml:
environment:
  - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
```

### Logstash

```bash
# Ajustar batch size
output {
  elasticsearch {
    batch_size => 5000  # Default: 2048
  }
}
```

### Filebeat

```bash
# Aumentar workers
output.logstash:
  worker: 4  # Default: 1
  batch_size: 4096
```

### Index Optimization

```bash
# Forçar merge
curl -X POST "http://localhost:9200/logs-*/_forcemerge?max_num_segments=1"

# Compact indexes
curl -X POST "http://localhost:9200/logs-*/_shrink/logs-compact"
```

---

## Troubleshooting

### ❌ Elasticsearch não inicia

```bash
# Verifique logs
docker logs infra-default-elasticsearch

# Verifique permissões
sudo chown -R 1000:1000 /var/lib/docker/volumes/infra-default-elasticsearch_data/

# Reset
docker volume rm infra-devtools_infra-default-elasticsearch_data
```

### ❌ Kibana não conecta ao Elasticsearch

```bash
# Verifique conectividade
curl http://elasticsearch:9200

# Verifique configuração
docker logs infra-default-kibana

# Reinicie ambos
docker-compose restart elasticsearch kibana
```

### ❌ Logs não aparecem em Kibana

```bash
# Verifique index
make elk-indexes

# Verifique logs do Filebeat
docker logs infra-default-filebeat

# Verifique logs do Logstash
docker logs infra-default-logstash

# Test manual
echo "Test log" | docker exec -i infra-default-logstash bash -c "cat > /tmp/test.log"
```

### ❌ Diskspace cheio

```bash
# Limpar índices antigos
make elk-cleanup

# Ou manual
curl -X DELETE "http://localhost:9200/logs-2025.01.01"

# Ver espaço
curl "http://localhost:9200/_cat/indices?v&h=index,store.size,docs.count"
```

---

## Referência Rápida

### Makefile Commands

```bash
make elk-init       # Inicializar ELK
make elk-verify     # Verificar status
make elk-indexes    # Listar índices
make elk-stats      # Estatísticas
make elk-cleanup    # Limpar antigos
make elk-logs       # Ver logs
```

### URLs

```
Kibana:           http://localhost:5601
Elasticsearch:    http://localhost:9200
Filebeat Metrics: http://localhost:5066
Logstash Metrics: http://localhost:9600
```

### Índices

Padrão: `logs-YYYY.MM.dd`

Exemplos:
- `logs-2025.11.07`
- `logs-2025.11.08`
- `logs-2025.11.09`

---

## Next Steps

1. **Criar Dashboards Personalizados**
   - Vá em Kibana > Dashboards
   - Criar dashboard customizado
   - Adicionar visualizações

2. **Setup Alertas**
   - Kibana > Stack Management > Alerting
   - Create alert rule
   - Configure notification

3. **Integração com Grafana**
   - Adicionar Elasticsearch como datasource
   - Importar dashboards

---

<p align="center">
  <b>Logs centralizados = Melhor debugging = Melhor produção</b><br>
  <b>🚀 by Kleilson Santos</b>
</p>
