# 🚨 Alerts Reference

> **Referência completa de alertas do Prometheus**

---

## Alert Overview

Todos os alertas são definidos em `alerts.yml` e roteirizados pelo Alertmanager para notificações via email.

**Dashboard:** http://localhost:9093 (Alertmanager UI)
**Definição:** http://localhost:9090/alerts (Prometheus Alerts)

### Exporter / probe requirements

| Alert | Requires |
|-------|----------|
| HighCPUUsage, HighMemoryUsage, LowDiskSpace | `job=node-exporter` |
| MongoDBDown | `job=mongodb-exporter` (`percona/mongodb_exporter`) |
| PostgreSQLDown | `job=postgres-exporter` |
| MySQLDown | `job=mysql-exporter` |
| RedisDown | `job=redis-exporter` |
| RabbitMQDown / Queue / Consumers | `job=rabbitmq-exporter` (`rabbitmq_*` metrics) |
| BlackboxDown | `job=blackbox-exporter` |
| BlackboxICMPDown | `job=blackbox-exporter-icmp-ping` (`probe_success`) |
| KeycloakDown | `job=blackbox-keycloak` (`http_2xx` → `http://keycloak:8080`) |
| Test_Always_Firing | none (test group only; always true) |

Production-named rules must not use constant-true expressions (`1 == bool 1`). Only `Test_Always_Firing` under `test-rules` is allowed to use `vector(1)`.

---

## Test Alerts

### Test_Always_Firing

**Severidade:** test
**Condição:** Sempre dispara (vector(1))
**Propósito:** Validar pipeline Prometheus → Alertmanager → Email

**Ação:** Ignorar - apenas para testes

---

## Infrastructure Alerts

### HighCPUUsage

**Severidade:** warning
**Serviço:** node-exporter
**Condição:** CPU > 80% por >2 minutos
**Significado:** Host está com alta utilização de CPU

**Ações:**
1. Verificar qual processo consome CPU
   ```bash
   top -b -n 1 | head -20
   ```

2. Identificar container problemático
   ```bash
   docker stats --no-stream | sort -k 3 -h -r
   ```

3. Possíveis causas:
   - Prometheus com muitas métricas
   - Grafana com dashboards complexos
   - Database com queries lentas
   - Aplicação com memory leak

4. Resolução:
   - Se Prometheus: aumentar scrape_interval
   - Se Grafana: simplificar dashboards
   - Se banco: otimizar queries
   - Se app: restart container

**SLA:** Investigar dentro de 15 minutos

---

### HighMemoryUsage

**Severidade:** warning
**Serviço:** node-exporter
**Condição:** Memory > 85% por >2 minutos
**Significado:** Host está ficando sem memória

**Ações:**
1. Verificar uso de memória
   ```bash
   free -h
   docker stats --no-stream
   ```

2. Container com maior uso
   ```bash
   docker stats --no-stream | sort -k 4 -h -r
   ```

3. Possíveis causas:
   - Database cache muito grande
   - Prometheus retention muito longo
   - Memory leak em aplicação
   - Redis usando muita memória

4. Resolução curta:
   ```bash
   # Reiniciar container problemático
   docker compose restart <service>
   ```

5. Resolução longa:
   - Aumentar memória do host
   - Reduzir retention em Prometheus
   - Otimizar database queries
   - Implementar memory limits

**SLA:** Investigar dentro de 10 minutos

---

### LowDiskSpace

**Severidade:** critical
**Serviço:** node-exporter
**Condição:** Disco < 10% livre
**Significado:** Disco está quase cheio - risco de falha total

**Ações Imediatas:**
1. Verificar uso de disco
   ```bash
   df -h
   du -sh /var/lib/docker/volumes/infra-default-*
   ```

2. Identificar maior consumidor
   ```bash
   docker system df
   docker volume ls -q | xargs -I {} sh -c 'echo {} && du -sh /var/lib/docker/volumes/{}/_data 2>/dev/null'
   ```

3. Liberar espaço (em ordem de segurança):
   ```bash
   # Opção 1: Prune unused images (seguro)
   docker image prune -a

   # Opção 2: Reduce Prometheus retention (requer restart)
   # Edit prometheus.yml, change retention to 7d
   docker compose restart prometheus

   # Opção 3: Delete old backups (verificar primeiro!)
   ls -lh /backups/ | tail -10
   ```

4. Monitor após ação
   ```bash
   df -h
   docker compose ps  # Verificar se todos containers estão up
   ```

**SLA:** Ação imediata - pode afetar todos os serviços

**Preventivo:**
- Monitorar tendência de crescimento
- Planejar expansão de disco
- Implementar logs rotation

---

## Database Alerts

### MongoDBDown

**Severidade:** critical
**Serviço:** mongo
**Condição:** MongoDB Exporter unreachable >1 minuto
**Significado:** MongoDB não está respondendo ou exporter falhou

**Ações:**
1. Verificar status
   ```bash
   docker compose ps mongo
   docker compose logs mongo --tail=20
   ```

2. Testar conectividade
   ```bash
   docker exec infra-default-mongo \
     mongosh --eval "db.adminCommand('ping')"
   ```

3. Se não responder:
   ```bash
   docker compose restart mongo
   ```

4. Se problema persistir:
   ```bash
   # Verificar volume
   docker volume inspect infra-default-mongo_data

   # Reset completo
   docker compose down mongo
   docker volume rm infra-default-mongo_data
   docker compose up -d mongo
   ```

**SLA:** Resolver dentro de 5 minutos

---

### PostgreSQLDown

**Severidade:** critical
**Serviço:** postgres
**Condição:** PostgreSQL Exporter unreachable >1 minuto
**Significado:** PostgreSQL não está respondendo

**Ações:**
1. Verificar status
   ```bash
   docker compose ps postgres
   docker compose logs postgres --tail=20
   ```

2. Testar conectividade
   ```bash
   docker exec infra-default-postgres \
     psql -U $POSTGRES_USER -c "SELECT 1"
   ```

3. Se não responder:
   ```bash
   docker compose restart postgres
   ```

4. Se problema persistir:
   ```bash
   docker compose down postgres
   docker volume rm infra-default-postgres_data
   docker compose up -d postgres
   ```

**SLA:** Resolver dentro de 5 minutos

---

### MySQLDown

**Severidade:** critical
**Serviço:** mysql
**Condição:** MySQL Exporter unreachable >1 minuto
**Significado:** MySQL não está respondendo

**Ações:**
1. Verificar status
   ```bash
   docker compose ps mysql
   docker compose logs mysql --tail=20
   ```

2. Testar conectividade
   ```bash
   docker exec infra-default-mysql \
     mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -e "SELECT 1"
   ```

3. Se não responder:
   ```bash
   docker compose restart mysql
   ```

4. Se problema persistir:
   ```bash
   docker compose down mysql
   docker volume rm infra-default-mysql_data
   docker compose up -d mysql
   ```

**SLA:** Resolver dentro de 5 minutos

---

### RedisDown

**Severidade:** critical
**Serviço:** redis
**Condição:** Redis Exporter unreachable >1 minuto
**Significado:** Redis não está respondendo

**Ações:**
1. Verificar status
   ```bash
   docker compose ps redis
   docker compose logs redis --tail=20
   ```

2. Testar conectividade
   ```bash
   docker exec infra-default-redis redis-cli ping
   ```

3. Se não responder:
   ```bash
   docker compose restart redis
   ```

4. Se problema persistir:
   ```bash
   docker compose down redis
   docker volume rm infra-default-redis_data
   docker compose up -d redis
   ```

**SLA:** Resolver dentro de 5 minutos

---

## Monitoring & Network Alerts

### BlackboxDown

**Severidade:** warning
**Serviço:** blackbox-exporter
**Condição:** Blackbox Exporter unreachable >1 minuto
**Significado:** Exporter de healthcheck externo offline

**Ações:**
1. Verificar status
   ```bash
   docker compose ps blackbox-exporter
   docker compose logs blackbox-exporter --tail=20
   ```

2. Restart
   ```bash
   docker compose restart blackbox-exporter
   ```

**SLA:** Investigar dentro de 10 minutos

---

### BlackboxICMPDown

**Severidade:** warning
**Condição:** ICMP probes failing
**Significado:** Conectividade de rede degradada (ICMP/ping)

**Ações:**
1. Testar conectividade ICMP
   ```bash
   ping -c 5 8.8.8.8
   ```

2. Verificar network
   ```bash
   docker network inspect infra-default-shared-net
   ```

**SLA:** Investigar dentro de 15 minutos

---

## Message Queue Alerts

### RabbitMQDown

**Severidade:** warning
**Condição:** RabbitMQ Exporter unreachable
**Significado:** RabbitMQ não está respondendo

**Ações:**
```bash
docker compose restart rabbitmq
docker compose logs rabbitmq --tail=20
```

**SLA:** Investigar dentro de 10 minutos

---

### RabbitMQQueueTooLarge

**Severidade:** warning
**Condição:** Fila RabbitMQ > limite configurado
**Significado:** Mensagens acumulando, possível slowdown em consumers

**Ações:**
1. Listar filas
   ```bash
   docker exec infra-default-rabbitmq rabbitmqctl list_queues
   ```

2. Investigar consumers
   ```bash
   docker exec infra-default-rabbitmq rabbitmqctl list_consumers
   ```

3. Escalar consumers se necessário

**SLA:** Investigar dentro de 15 minutos

---

### RabbitMQConsumersZero

**Severidade:** warning
**Condição:** Nenhum consumer ativo em alguma fila
**Significado:** Mensagens podem não ser processadas

**Ações:**
1. Verificar consumers
   ```bash
   docker exec infra-default-rabbitmq rabbitmqctl list_consumers
   ```

2. Verificar aplicação
   ```bash
   docker compose logs | grep -i "rabbitmq\|consumer"
   ```

3. Reiniciar serviço consumer se necessário

**SLA:** Investigar dentro de 10 minutos

---

## Authentication Alerts

### KeycloakDown

**Severidade:** critical
**Serviço:** blackbox-keycloak (`http_2xx`)
**Condição:** `probe_success == 0` por >1 minuto
**Significado:** Keycloak HTTP endpoint unreachable from blackbox

**Ações:**
```bash
docker compose restart keycloak
docker compose logs keycloak --tail=20
curl -sS -o /dev/null -w '%{http_code}\n' http://localhost:8099
```

**SLA:** Investigar dentro de 15 minutos

---

## Alert Response Workflow

```
Alert Fires
    ↓
Prometheus detects → Rule evaluation
    ↓
Alert goes to Alertmanager
    ↓
Alertmanager groups alerts (by alertname)
    ↓
Matches routing rules in alertmanager.yml
    ↓
Sends notification (email via Mailhog)
    ↓
Wait 10s minimum before next notification
    ↓
Repeat every 1 hour until resolved
```

---

## Alert Severity Levels

| Severidade | SLA | Ação |
|-----------|-----|------|
| **critical** | 5 min | Investigar imediatamente, pode afetar operações |
| **warning** | 15 min | Investigar quando possível, não crítico |
| **test** | N/A | Ignorar, apenas testes |

---

## Common False Positives

### Intermittent "Down" Alerts

**Causa:** Exporter temporariamente unreachable (network blip)
**Solução:** Normal, não agir se normaliza em 1-2 minutos

### High Memory After Restart

**Causa:** Database cache aquecendo
**Solução:** Normal, normaliza em 5-10 minutos

### High CPU on Update

**Causa:** Processos de sistema ou container initialization
**Solução:** Normal, normaliza em 1-2 minutos

---

## Disabling Alerts (Temporarily)

```bash
# Via Alertmanager API
curl -X POST http://localhost:9093/api/v1/alerts/silence \
  -H "Content-Type: application/json" \
  -d '{
    "matchers": [
      {"name": "alertname", "value": "HighMemoryUsage", "isRegex": false}
    ],
    "duration": "1h",
    "comment": "Maintenance window"
  }'
```

---

## Monitoring Dashboard

**Grafana:** http://localhost:3001
- Dashboard: "Alerts Overview"
- Shows: Firing alerts, history, trends

**Alertmanager UI:** http://localhost:9093
- Shows: Current alerts, routing, groups, silences

---

**Last Updated:** 2025-11-08
**Maintainer:** Operations Team
