# 🔧 Advanced Troubleshooting Guide

> **Nota:** Este guia complementa [HELP.md](/HELP.md) com soluções avançadas para problemas complexos.

## 📑 Índice

1. [Container Issues](#container-issues)
2. [Database Problems](#database-problems)
3. [Network Issues](#network-issues)
4. [Performance Degradation](#performance-degradation)
5. [Monitoring & Debugging](#monitoring--debugging)
6. [Data Recovery](#data-recovery)
7. [Common Error Messages](#common-error-messages)

---

## Container Issues

### ❌ Container Keeps Crashing

**Sintoma:** Container para após alguns segundos de iniciar

**Diagnóstico:**

```bash
# Ver logs detalhados
docker logs -f infra-default-<service_name>

# Ver health status
docker inspect infra-default-<service_name> | grep -A 10 "Health"

# Verificar se há recursos disponíveis
docker stats infra-default-<service_name>
```

**Soluções:**

1. **Verifique variáveis de ambiente:**
   ```bash
   docker inspect infra-default-<service_name> | grep -A 20 "Env"
   cat .env | grep -i "<service_name>" | head -10
   ```

2. **Aumente resource limits:**
   ```yaml
   # docker-compose.yml
   <service_name>:
     deploy:
       resources:
         limits:
           cpus: '2'
           memory: 2G
         reservations:
           cpus: '1'
           memory: 1G
   ```

3. **Recompile a image:**
   ```bash
   docker-compose down <service_name>
   docker-compose up -d <service_name>
   ```

### 🔌 Port Already in Use

**Sintoma:** `Address already in use` ao iniciar containers

**Diagnóstico:**

```bash
# Encontre qual processo usa a porta
lsof -i :<port_number>

# Ou no Windows
netstat -ano | findstr :<port_number>
```

**Soluções:**

1. **Kill processo existente:**
   ```bash
   kill -9 <PID>
   ```

2. **Altere a porta no .env:**
   ```bash
   SONARQUBE_PORT=9003
   PORTAINER_PORT=9011
   ```

3. **Aguarde liberação da porta:**
   ```bash
   # Aguarde alguns segundos e tente novamente
   sleep 30
   docker-compose up -d <service_name>
   ```

### 📁 Volume Mount Issues

**Sintoma:** Erro de permissão ao acessar volumes

**Diagnóstico:**

```bash
# Verifique volumes
docker volume ls
docker volume inspect infra-devtools_<volume_name>

# Verifique permissões
ls -la /var/lib/docker/volumes/infra-devtools_<volume_name>/_data/
```

**Soluções:**

1. **Corrija permissões:**
   ```bash
   sudo chown -R 1000:1000 /var/lib/docker/volumes/infra-devtools_<volume_name>/_data/
   ```

2. **Recrie volume:**
   ```bash
   docker volume rm infra-devtools_<volume_name>
   docker-compose up -d
   ```

3. **Use volume anônimo:**
   ```yaml
   volumes:
     - /data  # Instead of named volume
   ```

---

## Database Problems

### 🐘 PostgreSQL Connection Refused

**Sintoma:** `FATAL: Ident authentication failed` ou `Connection refused`

**Diagnóstico:**

```bash
# Teste conectividade
docker exec infra-default-postgres psql -U postgres -c "SELECT version();"

# Verifique status do serviço
docker ps | grep postgres
docker logs infra-default-postgres | tail -20

# Teste com pg_isready
docker exec infra-default-postgres pg_isready -U postgres
```

**Soluções:**

1. **Verifique credenciais:**
   ```bash
   cat .env | grep POSTGRES
   # Certifique-se de que POSTGRES_USER e POSTGRES_PASSWORD estão definidos
   ```

2. **Reinicie com reset:**
   ```bash
   docker-compose down postgres
   docker volume rm infra-devtools_postgres_data
   docker-compose up -d postgres
   sleep 10  # Aguarde inicialização
   ```

3. **Verifique arquivo de configuração:**
   ```bash
   docker exec infra-default-postgres cat /etc/postgresql/postgresql.conf | grep -i listen
   ```

### 🍃 MongoDB Connection Issues

**Sintoma:** `MongoServerSelectionError` ou `connection refused`

**Diagnóstico:**

```bash
# Teste conexão
docker exec infra-default-mongodb mongosh --eval "db.version()"

# Verifique replica set status
docker exec infra-default-mongodb mongosh --eval "rs.status()"

# Check authentication
docker exec infra-default-mongodb mongosh --eval "db.adminCommand('ping')"
```

**Soluções:**

1. **Repare replica set:**
   ```bash
   docker exec infra-default-mongodb mongosh --eval "rs.initiate()"
   ```

2. **Reset com novo volume:**
   ```bash
   docker-compose down mongodb
   docker volume rm infra-devtools_mongodb_data
   docker-compose up -d mongodb
   ```

3. **Verifique storage:**
   ```bash
   docker exec infra-default-mongodb du -sh /data/db
   ```

### 🔴 Redis Connection Timeout

**Sintoma:** `Connection timed out` ao conectar ao Redis

**Diagnóstico:**

```bash
# Teste conectividade
docker exec infra-default-redis redis-cli ping

# Verifique memória
docker exec infra-default-redis redis-cli info memory

# Verifique configuração
docker exec infra-default-redis redis-cli CONFIG GET maxmemory
```

**Soluções:**

1. **Aumente maxmemory:**
   ```bash
   docker exec infra-default-redis redis-cli CONFIG SET maxmemory 1gb
   docker exec infra-default-redis redis-cli CONFIG REWRITE
   ```

2. **Limpe dados antigos:**
   ```bash
   docker exec infra-default-redis redis-cli FLUSHDB  # Cuidado!
   ```

3. **Reinicie serviço:**
   ```bash
   docker-compose restart redis
   ```

---

## Network Issues

### 🌐 DNS Resolution Failing

**Sintoma:** Serviços não conseguem se conectar entre eles

**Diagnóstico:**

```bash
# Teste DNS dentro de container
docker exec infra-default-postgres nslookup mongodb
docker exec infra-default-postgres ping postgres

# Verifique rede Docker
docker network inspect infra-devtools_default

# Verifique resolv.conf
docker exec infra-default-postgres cat /etc/resolv.conf
```

**Soluções:**

1. **Recrie a rede:**
   ```bash
   docker-compose down
   docker network rm infra-devtools_default
   docker-compose up -d
   ```

2. **Use IP address em vez de hostname:**
   ```yaml
   # docker-compose.yml
   environment:
     DATABASE_URL: postgresql://postgres:password@172.18.0.5:5432/db
   ```

3. **Configure DNS customizado:**
   ```yaml
   services:
     postgres:
       dns:
         - 8.8.8.8
         - 8.8.4.4
   ```

### 🚫 Firewall Blocking Connections

**Sintoma:** Timeouts ao acessar serviços remotos

**Diagnóstico:**

```bash
# Teste conectividade com timeout
timeout 5 bash -c 'cat < /dev/null > /dev/tcp/remote-host/port'

# Use netcat
docker exec infra-default-postgres nc -zv external-host 5432

# Verifique regras do firewall
sudo iptables -L -n
```

**Soluções:**

1. **Adicione regra de firewall:**
   ```bash
   sudo ufw allow 5432/tcp
   ```

2. **Configure Docker para usar bridge network:**
   ```bash
   docker network create --driver bridge my-network
   docker-compose --network my-network up -d
   ```

---

## Performance Degradation

### ⚠️ High CPU Usage

**Sintoma:** Um ou mais containers usando >80% CPU

**Diagnóstico:**

```bash
# Identifique container culpado
docker stats --no-stream | sort -k3 -rn | head -5

# Analise processo específico
docker exec infra-default-<service> top -b -n 1

# Verifique logs para loops
docker logs infra-default-<service> | tail -100 | grep -i error
```

**Soluções:**

1. **Limite CPU:**
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '0.5'  # 50% de 1 CPU
   ```

2. **Otimize índices de banco:**
   ```bash
   # PostgreSQL
   docker exec infra-default-postgres ANALYZE;

   # MongoDB
   docker exec infra-default-mongodb mongosh --eval "db.collection.createIndex({field: 1})"
   ```

3. **Ative query caching:**
   ```bash
   # Redis
   docker exec infra-default-redis redis-cli CONFIG SET maxmemory-policy allkeys-lru
   ```

### 💾 Memory Leak

**Sintoma:** Uso de memória cresce constantemente

**Diagnóstico:**

```bash
# Monitore memória
watch -n 1 'docker stats --no-stream | grep <service>'

# Analise heap (Java/Node)
docker exec infra-default-<service> curl http://localhost:9090/heap > heap.dump
```

**Soluções:**

1. **Aumente limite de memória temporariamente:**
   ```yaml
   deploy:
     resources:
       limits:
         memory: 4G  # Aumentar
   ```

2. **Reinicie container periodicamente:**
   ```bash
   # Adicione ao cron
   0 3 * * * docker restart infra-default-<service>
   ```

3. **Otimize código/configuração:**
   - Revise logs para patterns
   - Ajuste pool de conexões
   - Ative garbage collection agressivo

### 📊 Slow Queries

**Sintoma:** Respostas lentas, timeouts

**Diagnóstico:**

```bash
# PostgreSQL - Enable query logging
docker exec infra-default-postgres psql -U postgres -c \
  "ALTER SYSTEM SET log_statement = 'all';"

# MySQL - Check slow query log
docker exec infra-default-mysql mysql -u root -p<password> -e \
  "SHOW VARIABLES LIKE 'slow%';"

# MongoDB - Profile collection
docker exec infra-default-mongodb mongosh --eval "db.setProfilingLevel(1)"
```

**Soluções:**

1. **Adicione índices:**
   ```bash
   # PostgreSQL
   docker exec infra-default-postgres psql -U postgres -c \
     "CREATE INDEX idx_users_email ON users(email);"
   ```

2. **Analise execution plan:**
   ```bash
   # PostgreSQL
   docker exec infra-default-postgres psql -U postgres -c \
     "EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test';"
   ```

3. **Otimize queries:**
   - Use índices
   - Evite N+1 queries
   - Cache resultados em Redis

---

## Monitoring & Debugging

### 📊 Access Prometheus for Metrics

**URL:** http://localhost:9090

**Queries úteis:**

```promql
# CPU usage por container
rate(container_cpu_usage_seconds_total[5m]) * 100

# Memory usage
container_memory_usage_bytes / 1024 / 1024

# Disk I/O
rate(container_fs_io_current[5m])
```

### 📈 Access Grafana Dashboards

**URL:** http://localhost:3001

**Dashboards recomendados:**
- Docker Dashboard
- Node Exporter Full
- Prometheus

### 🔍 Collect System Diagnostics

```bash
# Diagrama completo do sistema
./scripts/diagnose.sh full

# Apenas containers
./scripts/diagnose.sh containers

# Apenas bancos
./scripts/diagnose.sh databases
```

---

## Data Recovery

### 🔄 Restore from Backup

```bash
# Listar backups disponíveis
make backup-list

# Restaurar backup específico
make restore BACKUP_ID=20251107_120000

# Verificar integrity pós-restore
make health-check-databases
```

### 🗄️ Manual PostgreSQL Recovery

```bash
# Backup antes de qualquer ação
docker exec infra-default-postgres pg_dump -U postgres dbname > dump.sql

# Restaurar database
docker exec -i infra-default-postgres psql -U postgres < dump.sql

# Verificar corruption
docker exec infra-default-postgres REINDEX DATABASE dbname;
```

### 🍃 Manual MongoDB Recovery

```bash
# Backup da collection
docker exec infra-default-mongodb mongodump --archive=backup.archive

# Restaurar collection
docker exec -i infra-default-mongodb mongorestore --archive < backup.archive

# Repair
docker exec infra-default-mongodb mongosh --eval "db.repairDatabase()"
```

---

## Common Error Messages

### Error: `OOM Killed`

**Causa:** Out of Memory - container foi killed pelo sistema

**Solução:**
```bash
# Aumente limite de memória
# ou
# Reduza quantidade de containers
docker-compose down <service>
```

### Error: `Cannot connect to Docker daemon`

**Causa:** Docker service não está rodando

**Solução:**
```bash
# Linux
sudo systemctl start docker

# macOS
open /Applications/Docker.app
```

### Error: `Network unreachable`

**Causa:** Network isolada ou firewall

**Solução:**
```bash
docker network rm infra-devtools_default
docker-compose up -d
```

### Error: `Permission denied`

**Causa:** Arquivo sem permissões apropriadas

**Solução:**
```bash
chmod +x scripts/*.sh
sudo chown -R $USER:$USER .
```

---

## 📞 Support & Documentation

- **HELP.md** - Quick reference
- **README.md** - Concept documentation
- **SECURITY.md** - Security policies
- **CHANGELOG.md** - Version history
- **CONTRIBUTING.md** - Development workflow

---

<p align="center">
  <b>Ainda com problemas? Abra uma issue ou consulte a documentação oficial.</b><br>
  <b>🚀 Kleilson Santos</b>
</p>
