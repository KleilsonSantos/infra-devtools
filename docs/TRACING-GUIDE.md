# 🔄 Distributed Tracing Guide - Jaeger + OpenTelemetry

> Jaeger + OpenTelemetry: Rastreamento de requisições através de serviços distribuídos

## 📑 Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura](#arquitetura)
3. [Quick Start](#quick-start)
4. [Jaeger](#jaeger)
5. [OpenTelemetry](#opentelemetry)
6. [Instrumentação por Linguagem](#instrumentação-por-linguagem)
7. [Análise de Traces](#análise-de-traces)
8. [Performance Tuning](#performance-tuning)
9. [Troubleshooting](#troubleshooting)

---

## Visão Geral

### O que é Distributed Tracing?

Rastreamento distribuído permite que você veja a jornada completa de uma requisição através de múltiplos serviços em uma arquitetura de microserviços.

### Jaeger vs Observabilidade Tradicional

```
❌ Logs (Isolados)
  → App A: "Processando requisição"
  → App B: "Erro 500"
  → Sem correlação entre serviços

✅ Jaeger (Distribuído)
  → Request ID: abc123
    ├─ Service A: span_id=1, duration=50ms
    │  └─ DB Query: span_id=2, duration=30ms
    └─ Service B: span_id=3, duration=100ms
       └─ Cache Hit: span_id=4, duration=5ms
```

### Por que você precisa?

Sem distributed tracing:
- ❌ Impossível identificar qual serviço é lento
- ❌ Sem visualização de latência entre serviços
- ❌ Difícil debugar problemas em produção
- ❌ Sem correlação entre eventos

Com Jaeger + OpenTelemetry:
- ✅ Rastreamento end-to-end de requisições
- ✅ Visualização da topologia de serviços
- ✅ Identificação de gargalos (bottlenecks)
- ✅ Análise de performance e SLO
- ✅ Debugging distribuído

---

## Arquitetura

### Componentes Jaeger

```
┌─────────────────────────────────────┐
│      Sua Aplicação (OTLP SDK)       │
│  (Java, Python, Node.js, Go, etc)   │
└──────────────┬──────────────────────┘
               │
         ┌─────▼──────────────────────┐
         │  Jaeger Agent              │
         │  (UDP/gRPC receiver)       │
         │  ┌────────────────────┐    │
         │  │ Ports:             │    │
         │  │ 5775 (Thrift)      │    │
         │  │ 6831 (Thrift)      │    │
         │  │ 6832 (Thrift)      │    │
         │  │ 5778 (Serve HTTP)  │    │
         │  └────────────────────┘    │
         └─────────┬──────────────────┘
                   │
         ┌─────────▼──────────────────┐
         │ Jaeger Collector           │
         │ (gRPC/HTTP receiver)       │
         │ ┌────────────────────┐    │
         │ │ Ports:             │    │
         │ │ 14250 (gRPC)       │    │
         │ │ 14268 (Thrift HTTP)│    │
         │ │ 16686 (UI)         │    │
         │ └────────────────────┘    │
         └─────────┬──────────────────┘
                   │
         ┌─────────▼──────────────────┐
         │  Badger Storage            │
         │  (/badger/data)            │
         └────────────────────────────┘

┌─────────────────────────────────────┐
│   Jaeger UI (Web Interface)          │
│   http://localhost:16686             │
├─────────────────────────────────────┤
│  • Search traces by service         │
│  • View service dependency graph    │
│  • Analyze span latency             │
│  • Correlate errors & latency       │
└─────────────────────────────────────┘
```

### Fluxo de Dados

```
1. Application
   └─ emit spans (OTLP Protocol)

2. Jaeger Agent (Sidecar)
   └─ receives UDP/gRPC traces
   └─ batches them

3. Jaeger Collector
   └─ processes & validates
   └─ stores in Badger

4. Jaeger UI
   └─ queries & visualizes
   └─ correlates traces
```

---

## Quick Start

### 1️⃣ Iniciar Jaeger

```bash
# Iniciar todos os serviços (incluindo Jaeger)
docker-compose up -d

# Ou iniciar apenas Jaeger
docker-compose up -d jaeger-collector jaeger-agent
```

### 2️⃣ Inicializar

```bash
# Aguardar serviços ficarem prontos
make jaeger-init
```

### 3️⃣ Verificar Status

```bash
# Verificar conectividade
make jaeger-verify

# Acessar UI
# http://localhost:16686
```

### 4️⃣ Acessar Jaeger UI

Abra no navegador: **http://localhost:16686**

---

## Jaeger

### O que é?

Jaeger (CNCF incubating project) é uma plataforma open-source para:
- Rastreamento distribuído de requisições
- Visualização de latência
- Análise de performance
- Debugging de microserviços

### Componentes

#### 1. Jaeger Agent

Sidecar que coleta spans localmente:

```bash
# Ver logs
docker logs infra-default-jaeger-agent

# Health check
curl http://localhost:5778/status
```

**Portas:**
- 5775 (Thrift compact)
- 6831 (Thrift compact UDP)
- 6832 (Thrift binary UDP)
- 5778 (HTTP server)

#### 2. Jaeger Collector

Serviço central que processa e armazena spans:

```bash
# Ver logs
docker logs infra-default-jaeger-collector

# Health check
curl http://localhost:14268/api/traces

# Verificar configuração
curl http://localhost:14268/api/services
```

**Portas:**
- 14250 (gRPC)
- 14268 (Thrift HTTP)
- 16686 (UI)
- 9411 (Zipkin compatible)

#### 3. Storage (Badger)

Armazenamento local de spans:

```bash
# Localização de dados
/var/lib/docker/volumes/infra-default-jaeger_data/

# Cleanup antigos
docker exec infra-default-jaeger-collector rm -rf /badger/data/*
```

### API Endpoints

```bash
# List all services
curl http://localhost:16686/api/services

# Get operations for service
curl http://localhost:16686/api/services/api/operations

# Search traces (últimas 10)
curl "http://localhost:16686/api/traces?service=api&limit=10"

# Get trace by ID
curl "http://localhost:16686/api/traces/traceid"

# Service dependency graph
curl http://localhost:16686/api/dependencies
```

### Jaeger UI Walkthrough

1. **Search Traces**
   - Select service from dropdown
   - Choose time range
   - Filter by tags/operations
   - Click search

2. **View Trace Details**
   - Click on trace
   - See all spans in timeline
   - Click span for details
   - View trace tags & logs

3. **Service Dependencies**
   - Menu → System Architecture
   - Visual map of services
   - Click edges for traffic info

4. **Latency Profile**
   - Menu → Comparison
   - Compare traces
   - Find performance patterns

---

## OpenTelemetry

### O que é?

OpenTelemetry (OTEL) é um padrão aberto para instrumentação de aplicações. Permite enviar traces, métricas e logs para qualquer backend (Jaeger, Datadog, New Relic, etc).

### Configuração

Arquivo: `config/otel-config.yaml`

```yaml
# ✅ Receivers: Como receber dados
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  jaeger:
    protocols:
      grpc:
        endpoint: 0.0.0.0:14250

# 🔄 Processors: Como processar dados
processors:
  batch:
    timeout: 10s
    send_batch_size: 1024
  memory_limiter:
    check_interval: 1s
    limit_mib: 1024
  attributes:
    actions:
      - key: environment
        value: development
        action: insert

# 📤 Exporters: Para onde enviar dados
exporters:
  jaeger:
    endpoint: jaeger-collector:14250
    tls:
      insecure: true

# 🔗 Service: Conecta tudo
service:
  pipelines:
    traces:
      receivers: [otlp, jaeger]
      processors: [memory_limiter, batch, attributes]
      exporters: [jaeger]
```

### Protocolos OTLP

**gRPC (recomendado):**
```bash
# Porta 4317
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

**HTTP (alternativa):**
```bash
# Porta 4318
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
```

---

## Instrumentação por Linguagem

### Java

#### Setup

```bash
# Baixar agent
curl -L https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar \
  -o opentelemetry-javaagent.jar

# Adicionar ao startup
java -javaagent:opentelemetry-javaagent.jar \
  -Dotel.service.name=my-service \
  -Dotel.exporter.otlp.endpoint=http://localhost:4317 \
  -jar application.jar
```

#### Código Manual (Spring Boot)

```java
import io.opentelemetry.api.trace.Tracer;
import org.springframework.beans.factory.annotation.Autowired;

@RestController
public class ApiController {

    @Autowired
    private Tracer tracer;

    @GetMapping("/api/users")
    public ResponseEntity<?> getUsers() {
        try (Scope scope = tracer.spanBuilder("getUserList")
                .setAttribute("user.id", "123")
                .startActiveSpan()) {

            // Your business logic
            return ResponseEntity.ok(users);
        }
    }
}
```

#### Spring Boot Starter (Automático)

```xml
<dependency>
    <groupId>io.opentelemetry.instrumentation</groupId>
    <artifactId>opentelemetry-instrumentation-spring-boot-starter</artifactId>
    <version>1.17.0</version>
</dependency>
```

```properties
# application.properties
otel.service.name=my-service
otel.exporter.otlp.endpoint=http://localhost:4317
otel.traces.exporter=otlp
otel.instrumentation.common.enabled=true
```

### Python

#### Setup

```bash
pip install opentelemetry-api \
    opentelemetry-sdk \
    opentelemetry-exporter-otlp \
    opentelemetry-instrumentation-flask \
    opentelemetry-instrumentation-requests \
    opentelemetry-instrumentation-sqlalchemy
```

#### Código

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

# Setup
otlp_exporter = OTLPSpanExporter(
    endpoint="localhost:4317",
    insecure=True
)
trace.set_tracer_provider(TracerProvider())
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(otlp_exporter)
)

# Auto-instrumentation
FlaskInstrumentor().instrument()
RequestsInstrumentor().instrument()

tracer = trace.get_tracer(__name__)

# Manual span
@app.route("/api/users")
def get_users():
    with tracer.start_as_current_span("get_users") as span:
        span.set_attribute("request.id", "abc123")
        # Your code
        return users
```

#### Environment Variables

```bash
export OTEL_SERVICE_NAME=my-service
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
export OTEL_TRACES_EXPORTER=otlp
export OTEL_INSTRUMENTATION_ENABLED=true
```

### Node.js

#### Setup

```bash
npm install @opentelemetry/api \
    @opentelemetry/sdk-node \
    @opentelemetry/auto-instrumentations-node \
    @opentelemetry/sdk-trace-node \
    @opentelemetry/exporter-otlp-proto \
    @opentelemetry/resources \
    @opentelemetry/semantic-conventions
```

#### Código (Express)

```javascript
// tracing.js - Deve ser o primeiro import
const { NodeTracerProvider } = require('@opentelemetry/sdk-trace-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-otlp-proto');
const { registerInstrumentations } = require('@opentelemetry/auto-instrumentations-node');

const exporter = new OTLPTraceExporter({
  url: 'http://localhost:4317'
});

const provider = new NodeTracerProvider();
provider.addSpanProcessor(
  new BatchSpanProcessor(exporter)
);
provider.register();

registerInstrumentations({
  instrumentations: [
    new HttpInstrumentation(),
    new ExpressInstrumentation(),
    new PgInstrumentation(),
  ],
});
```

```javascript
// app.js - Use depois de tracing.js
require('./tracing');
const express = require('express');
const { trace } = require('@opentelemetry/api');

const app = express();
const tracer = trace.getTracer('my-service');

app.get('/api/users', async (req, res) => {
  const span = tracer.startSpan('getUsers');
  try {
    span.setAttributes({
      'request.id': req.id,
      'user.id': req.user?.id
    });

    const users = await db.query('SELECT * FROM users');
    res.json(users);
  } finally {
    span.end();
  }
});
```

#### Environment Variables

```bash
export NODE_OPTIONS="--require ./tracing.js"
export OTEL_SERVICE_NAME=my-service
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

### Go

#### Setup

```bash
go get go.opentelemetry.io/otel
go get go.opentelemetry.io/otel/exporters/otlp/otlptrace
go get go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc
go get go.opentelemetry.io/otel/sdk/trace
go get go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp
```

#### Código

```go
package main

import (
    "context"
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
    "go.opentelemetry.io/otel/sdk/trace"
)

func initTracer() (*trace.TracerProvider, error) {
    ctx := context.Background()

    exporter, err := otlptracegrpc.New(ctx,
        otlptracegrpc.WithEndpoint("localhost:4317"),
        otlptracegrpc.WithInsecure(),
    )
    if err != nil {
        return nil, err
    }

    tp := trace.NewTracerProvider(
        trace.WithBatcher(exporter),
    )
    otel.SetTracerProvider(tp)

    return tp, nil
}

func main() {
    tp, _ := initTracer()
    defer tp.Shutdown(context.Background())

    tracer := otel.Tracer("my-service")

    ctx, span := tracer.Start(context.Background(), "getUsers")
    defer span.End()

    span.SetAttributes(
        attribute.String("request.id", "abc123"),
    )

    // Your code
}
```

---

## Análise de Traces

### Busca Básica

1. **Por Serviço:**
   - Selecione serviço no dropdown
   - Clique "Find Traces"

2. **Por Operação:**
   - Service → Operation dropdown
   - Exemplo: `GET /api/users`

3. **Por Duração:**
   - Min Duration: `100ms`
   - Max Duration: `5s`

4. **Por Tags:**
   - `http.status_code=500`
   - `user.id=123`

### Exemplos de Análise

#### 1. Encontrar Requisições Lentas

```
Service: api
Operation: GET /api/users
Min Duration: 1000ms (1 segundo)
Status: Any
```

Resultado: Traces que demoram mais de 1 segundo

#### 2. Encontrar Erros

```
Service: api
Min Duration: 0ms
Max Duration: Unlimited
Tags: error=true
```

#### 3. Encontrar por ID de Usuário

```
Service: api
Tags: user.id=12345
```

### Interpretando o Timeline

```
Trace: abc123 (1.2s total)
├─ api: GET /users (50ms)
│  └─ db: SELECT users (30ms)
├─ cache: SET users (5ms)
├─ auth: VALIDATE token (15ms)
└─ logger: WRITE log (1ms)
```

**Cálculo de latência:**
- Trace total: 1.2s
- Serviço mais lento: db (30ms)
- Paralelização: 4 serviços em ~50ms cada

### Correlação com Erros

Se um trace tem erro:
1. Abra o trace
2. Procure span em vermelho
3. Veja logs associados
4. Correlacione com timestamp dos logs (ELK)

---

## Performance Tuning

### Jaeger Collector

```yaml
# docker-compose.yml
jaeger-collector:
  environment:
    # Memory limits
    - MEMORY_MAX_TRACES=50000  # Default 10000

    # Batch processing
    - COLLECTOR_ZIPKIN_ENABLED=true
    - COLLECTOR_OTLP_ENABLED=true

    # Storage
    - SPAN_STORAGE_TYPE=badger
    - BADGER_EPHEMERAL=false
    - BADGER_DIRECTORY_VALUE=/badger/data
```

### OTLP Exporter Configuration

```yaml
# config/otel-config.yaml
processors:
  batch:
    timeout: 10s              # Wait max 10s
    send_batch_size: 1024     # Send when 1024 spans

  memory_limiter:
    check_interval: 1s        # Check every 1s
    limit_mib: 1024           # Max 1GB memory
```

### Application Level

#### Java
```properties
otel.bsp.max_queue_size=2048
otel.bsp.scheduled_delay=5000
otel.bsp.max_export_batch_size=512
```

#### Python
```python
BatchSpanProcessor(exporter,
    schedule_delay_millis=5000,
    max_queue_size=2048,
    max_export_batch_size=512
)
```

### Sampling

Para high-volume applications, abilite sampling:

```yaml
# config/otel-config.yaml
processors:
  probabilistic_sampler:
    sampling_percentage: 10  # Sample 10% of traces
```

---

## Troubleshooting

### ❌ Jaeger UI não abre

```bash
# Verificar se containers estão rodando
docker ps | grep jaeger

# Se não estiver rodando
docker-compose up -d jaeger-collector jaeger-agent

# Ver logs
docker logs infra-default-jaeger-collector
```

### ❌ Spans não aparecem em Jaeger

**Problema 1: Aplicação não instrumentada**

```bash
# Verificar se spans estão sendo enviados
curl http://localhost:16686/api/services

# Se vazio, aplicação não enviou spans
```

**Problema 2: Conexão com Jaeger falha**

```bash
# Dentro do container da aplicação
curl -v http://jaeger-collector:14268/api/traces

# Se falhar, check rede
docker network ls
docker network inspect infra-default-shared-net
```

**Problema 3: OTLP endpoint incorreto**

```bash
# Correto para gRPC
OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger-collector:4317

# Correto para HTTP
OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger-collector:4318

# ❌ Errado - usando localhost de dentro do container
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

### ❌ Muita latência nos spans

**Causa 1: Sampling não ativado**
```bash
# Ver estatísticas
curl http://localhost:16686/api/services
# Se tiver muitos spans, abilite sampling
```

**Causa 2: Batch processor mal configurado**
```yaml
processors:
  batch:
    send_batch_size: 512      # Aumentar batch
    timeout: 5s                # Diminuir timeout
```

### ❌ Memória alta no Collector

```bash
# Check processo
docker stats infra-default-jaeger-collector

# Limpar dados antigos
docker exec infra-default-jaeger-collector \
  find /badger/data -type f -mtime +7 -delete

# Ou reset completo
docker-compose down
docker volume rm infra-devtools_infra-default-jaeger_data
docker-compose up -d jaeger-collector
```

### ❌ Erros de permissão no storage

```bash
# Verificar permissões
docker exec infra-default-jaeger-collector \
  ls -la /badger/

# Corrigir se necessário
docker exec -u root infra-default-jaeger-collector \
  chown -R nobody:nobody /badger/
```

---

## Referência Rápida

### Makefile Commands

```bash
make jaeger-init          # Inicializar Jaeger
make jaeger-verify        # Verificar conectividade
make jaeger-services      # Listar serviços rastreados
make jaeger-traces        # Ver traces de um serviço
make jaeger-operations    # Ver operações de um serviço
make jaeger-stats         # Mostrar estatísticas
make jaeger-logs          # Ver logs dos componentes
```

### URLs

```
Jaeger UI:              http://localhost:16686
Jaeger Agent:           localhost:6831 (UDP)
Jaeger Collector gRPC:  localhost:14250
Jaeger Collector HTTP:  localhost:14268
OpenTelemetry gRPC:     localhost:4317
OpenTelemetry HTTP:     localhost:4318
```

### Environment Variables

```bash
# OTLP Exporter
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc

# Service Name
export OTEL_SERVICE_NAME=my-service

# Traces Export
export OTEL_TRACES_EXPORTER=otlp
export OTEL_PROPAGATORS=jaeger
```

### Span Attributes (Semântico)

```
# HTTP
http.method=GET
http.url=/api/users
http.status_code=200
http.client_ip=192.168.1.1

# DB
db.system=postgresql
db.name=mydb
db.operation=SELECT
db.statement=SELECT * FROM users

# RPC
rpc.service=UserService
rpc.method=GetUsers
rpc.system=grpc

# Mensaging
messaging.system=rabbitmq
messaging.operation=publish
messaging.message_id=abc123

# Erro
error=true
error.kind=IOException
error.message=Connection refused
```

### Query Jaeger API

```bash
# Listar serviços
curl http://localhost:16686/api/services | jq .

# Operações de um serviço
curl http://localhost:16686/api/services/api/operations | jq .

# Buscar traces
curl "http://localhost:16686/api/traces?service=api&limit=10" | jq .

# Trace específico
curl "http://localhost:16686/api/traces/abc123def456" | jq .
```

---

## Next Steps

1. **Instrumentar suas aplicações**
   - Escolha sua linguagem
   - Instale SDK OpenTelemetry
   - Configure OTLP exporter
   - Gere alguns traces

2. **Criar Dashboards em Grafana**
   - Integre Jaeger como datasource
   - Crie visualizações de traces
   - Correlacione com métricas

3. **Setup Alertas**
   - Monitor latência P99
   - Alert se erro rate > 5%
   - Correlacione com ELK logs

4. **Análise de Performance**
   - Identifique gargalos
   - Otimize operações lentas
   - Monitore SLO/SLI

---

<p align="center">
  <b>Distributed Tracing = Visibilidade Total = Produção Confiável</b><br>
  <b>🚀 by Kleilson Santos</b>
</p>
