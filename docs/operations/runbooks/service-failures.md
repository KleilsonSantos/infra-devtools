# 🚨 Service Failures Runbook

> **Diagnóstico e recuperação de falhas de serviços**

---

## Quick Reference

| Serviço | Container | Status Check | Restart |
|---------|-----------|--------------|---------|
| MongoDB | `infra-default-mongo` | `docker exec infra-default-mongo mongosh --eval "db.adminCommand('ping')"` | `docker compose restart mongo` |
| PostgreSQL | `infra-default-postgres` | `docker exec infra-default-postgres psql -U $POSTGRES_USER -c "SELECT 1"` | `docker compose restart postgres` |
| MySQL | `infra-default-mysql` | `docker exec infra-default-mysql mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -e "SELECT 1"` | `docker compose restart mysql` |
| Redis | `infra-default-redis` | `docker exec infra-default-redis redis-cli ping` | `docker compose restart redis` |
| Prometheus | `infra-default-prometheus` | `curl -f http://localhost:9090/-/healthy` | `docker compose restart prometheus` |
| Grafana | `infra-default-grafana` | `curl -f http://localhost:3001/api/health` | `docker compose restart grafana` |
| Alertmanager | `infra-default-alertmanager` | `curl -f http://localhost:9093/-/healthy` | `docker compose restart alertmanager` |

---

## 🗄️ Database Services

### MongoDB (`infra-default-mongo`)

**Portas:** 27017
**Credenciais:** MONGO_INITDB_ROOT_USERNAME, MONGO_INITDB_ROOT_PASSWORD
**Volume:** `infra-default-mongo_data`

**Diagnóstico:**
```bash
# 1. Verificar status do container
docker compose ps mongo

# 2. Ver logs
docker compose logs mongo --tail=50

# 3. Testar conectividade
docker exec infra-default-mongo mongosh --eval "db.adminCommand('ping')"
```

**Recuperação:**
```bash
# Simples restart
docker compose restart mongo

# Se problema persistir, checar volume
docker volume inspect infra-default-mongo_data

# Se corrupto, remover e recriar
docker compose down mongo
docker volume rm infra-default-mongo_data
docker compose up -d mongo
```

---

### PostgreSQL (`infra-default-postgres`)

**Portas:** 5432
**Credenciais:** POSTGRES_USER, POSTGRES_PASSWORD
**Volume:** `infra-default-postgres_data`

**Diagnóstico:**
```bash
# 1. Verificar status
docker compose ps postgres

# 2. Ver logs
docker compose logs postgres --tail=50

# 3. Testar conexão
docker exec infra-default-postgres \
  psql -U $POSTGRES_USER -c "SELECT 1"
```

**Recuperação:**
```bash
# Restart simples
docker compose restart postgres

# Se problema, verificar volume
docker volume inspect infra-default-postgres_data

# Se corrupto, remover e recriar
docker compose down postgres
docker volume rm infra-default-postgres_data
docker compose up -d postgres
```

---

### MySQL (`infra-default-mysql`)

**Portas:** 3306
**Credenciais:** MYSQL_USER, MYSQL_PASSWORD
**Volume:** `infra-default-mysql_data`

**Diagnóstico:**
```bash
# 1. Status
docker compose ps mysql

# 2. Logs
docker compose logs mysql --tail=50

# 3. Teste de conectividade
docker exec infra-default-mysql \
  mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -e "SELECT 1"
```

**Recuperação:**
```bash
# Restart
docker compose restart mysql

# Se falha, verificar volume
docker volume inspect infra-default-mysql_data

# Reset completo
docker compose down mysql
docker volume rm infra-default-mysql_data
docker compose up -d mysql
```

---

### Redis (`infra-default-redis`)

**Portas:** 6379
**Volume:** `infra-default-redis_data`

**Diagnóstico:**
```bash
# 1. Status
docker compose ps redis

# 2. Logs
docker compose logs redis --tail=50

# 3. Teste PING
docker exec infra-default-redis redis-cli ping
```

**Recuperação:**
```bash
# Restart
docker compose restart redis

# Se problema com AOF (Append-Only File)
docker compose down redis
docker exec -it infra-default-redis redis-cli --rdb /tmp/dump.rdb
docker volume rm infra-default-redis_data
docker compose up -d redis
```

---

## 📊 Monitoring Services

### Prometheus (`infra-default-prometheus`)

**Portas:** 9090
**Config:** `prometheus.yml`

**Diagnóstico:**
```bash
# 1. Status
docker compose ps prometheus

# 2. Logs
docker compose logs prometheus --tail=50

# 3. Health check
curl -f http://localhost:9090/-/healthy

# 4. Verificar config
docker exec infra-default-prometheus \
  prometheus --config.file=/etc/prometheus/prometheus.yml --test
```

**Erros Comuns:**

- **Config inválida:** `parse errors in prometheus.yml`
  ```bash
  # Validar YAML
  docker run --rm -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus --config.file=/etc/prometheus/prometheus.yml
  ```

- **Targets down:** Verificar conectividade dos exporters
  ```bash
  docker compose ps | grep exporter
  ```

**Recuperação:**
```bash
# Restart
docker compose restart prometheus

# Se config corrompida, editar prometheus.yml e recarregar
docker compose restart prometheus
```

---

### Grafana (`infra-default-grafana`)

**Portas:** 3001
**Volume:** `infra-default-grafana-storage`

**Diagnóstico:**
```bash
# 1. Status
docker compose ps grafana

# 2. Logs
docker compose logs grafana --tail=50

# 3. Health check
curl -f http://localhost:3001/api/health

# 4. Verificar datasources
curl -s http://localhost:3001/api/datasources | jq .
```

**Recuperação:**
```bash
# Restart
docker compose restart grafana

# Se problema com volume, remover
docker compose down grafana
docker volume rm infra-default-grafana-storage
docker compose up -d grafana
```

---

### Alertmanager (`infra-default-alertmanager`)

**Portas:** 9093
**Config:** `alertmanager.yml`

**Diagnóstico:**
```bash
# 1. Status
docker compose ps alertmanager

# 2. Logs
docker compose logs alertmanager --tail=50

# 3. Health check
curl -f http://localhost:9093/-/healthy

# 4. Verificar alertas ativos
curl -s http://localhost:9093/api/v1/alerts | jq .
```

**Recuperação:**
```bash
# Restart
docker compose restart alertmanager

# Validar config YAML
docker exec infra-default-alertmanager \
  amtool config routes
```

---

## 🔑 Supporting Services

### Keycloak (Authentication)

**Portas:** 8099

**Diagnóstico:**
```bash
# Status
docker compose ps keycloak

# Logs
docker compose logs keycloak --tail=50

# Health check
curl -f http://localhost:8099/auth/realms/master/.well-known/openid-configuration
```

**Recuperação:**
```bash
docker compose restart keycloak
```

---

## 🐇 Message Queue

### RabbitMQ

**Portas:** 5672 (AMQP), 15672 (Management UI)

**Diagnóstico:**
```bash
# Status
docker compose ps rabbitmq

# Management API
curl -u guest:guest http://localhost:15672/api/vhosts

# Check queues
docker exec infra-default-rabbitmq rabbitmqctl list_queues
```

**Recuperação:**
```bash
docker compose restart rabbitmq
```

---

## 🆘 Troubleshooting Steps

### Todos os serviços down

```bash
# 1. Verificar Docker
docker ps
docker compose ps

# 2. Reiniciar Docker daemon
sudo systemctl restart docker

# 3. Reiniciar stack completo
docker compose down
docker compose up -d

# 4. Verificar health
docker compose ps
```

### Container keeps restarting

```bash
# Ver logs
docker compose logs <service> --tail=100 -f

# Verificar recursos
docker stats <container-id>

# Se memory/CPU issue
# Editar docker-compose.yml e aumentar limits
```

### Network connectivity issues

```bash
# Testar conectividade entre containers
docker compose exec <container> ping <outro-container>

# Verificar rede
docker network inspect infra-default-shared-net

# Limpar rede
docker network rm infra-default-shared-net
docker compose down
docker compose up -d
```

---

## ✅ Validation Checklist

Após recuperar um serviço, validar:

```bash
# 1. Container running
docker compose ps | grep <service>

# 2. Logs clean (sem erros)
docker compose logs <service> --tail=20 | grep -i error

# 3. Testes passando
make test-all

# 4. Prometheus scraping
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job=="<service>")'

# 5. Alertmanager clean
curl -s http://localhost:9093/api/v1/alerts | jq '.data[] | select(.status.state=="firing")'
```

---

## 📞 Escalation

Se problema persistir após seguir este runbook:

1. **Coletar logs:**
   ```bash
   docker compose logs > /tmp/logs.txt
   docker stats --no-stream > /tmp/stats.txt
   docker volume inspect infra-default-<service>_data >> /tmp/logs.txt
   ```

2. **Contactar plataforma team** com:
   - Tempo quando problema começou
   - Mudanças recentes (código, config, infra)
   - Saída de: `docker compose ps`, logs e stats
   - Resultado dos testes acima

---

**Last Updated:** 2025-11-08
**Maintainer:** Operations Team
