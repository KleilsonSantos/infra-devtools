# 🆘 Disaster Recovery Guide

> Plano completo para recuperação de falhas críticas e desastres.

## 📑 Índice

1. [Quick Recovery Procedures](#quick-recovery-procedures)
2. [Data Recovery](#data-recovery)
3. [Service Recovery](#service-recovery)
4. [Backup & Restore Strategy](#backup--restore-strategy)
5. [RTO/RPO Matrix](#rnorp-matrix)

---

## Quick Recovery Procedures

### 🚨 Emergency: All Services Down

**Tempo esperado:** 5 minutos

```bash
# 1. Diagnosticar
./scripts/health-check.sh quick

# 2. Restart Docker daemon
sudo systemctl restart docker

# 3. Reiniciar todos os containers
docker-compose restart

# 4. Verificar status
make health-check

# 5. Se persistir, full reset
docker-compose down -v
docker-compose up -d
```

### ⚠️ Critical: Database Inaccessible

**Tempo esperado:** 2-5 minutos

```bash
# PostgreSQL
docker-compose restart postgres

# MongoDB
docker exec infra-default-mongodb mongosh --eval "rs.initiate()"

# MySQL
docker-compose restart mysql

# Verificar
make health-check-databases
```

### 🔥 Critical: Data Corruption

**Tempo esperado:** 10-30 minutos

```bash
# 1. Identify corrupted service
docker logs infra-default-<service> | tail -100

# 2. Stop service
docker-compose stop <service>

# 3. Restore from latest backup
make restore BACKUP_ID=<latest_backup_id>

# 4. Verify integrity
docker exec infra-default-<service> \
  <service-specific-integrity-check>

# 5. Resume
docker-compose up -d <service>
```

---

## Data Recovery

### 📦 PostgreSQL Recovery

**Scenario: Database corruption**

```bash
# 1. Check corruption
docker exec infra-default-postgres pg_dump -U postgres dbname 2>&1 | \
  grep -i error

# 2. Attempt repair
docker exec infra-default-postgres psql -U postgres -c \
  "REINDEX DATABASE dbname;"

# 3. If fails, restore from backup
docker-compose stop postgres
docker volume rm infra-devtools_postgres_data

# 4. Restore backup
make restore BACKUP_ID=<id>

# 5. Verify data
docker exec infra-default-postgres psql -U postgres -c \
  "SELECT COUNT(*) FROM table_name;"
```

**Scenario: Accidental DELETE**

```bash
# 1. Restore from point-in-time backup
docker exec infra-default-postgres pg_basebackup \
  -h localhost -U postgres -D /backup/restore -Ft -Pv

# 2. Create recovery.conf
echo "recovery_target_timeline = 'latest'" > /backup/restore/recovery.conf

# 3. Verify restored data
docker exec -i infra-default-postgres psql -U postgres < dump.sql
```

### 🍃 MongoDB Recovery

**Scenario: Collection deleted**

```bash
# 1. Check backups
make backup-list

# 2. Get backup details
ls -lh reports/backups/

# 3. Restore collection
docker exec -i infra-default-mongodb mongorestore \
  --archive=reports/backups/<backup_file> \
  --nsInclude="database.collection"

# 4. Verify
docker exec infra-default-mongodb mongosh --eval \
  "db.collection.count()"
```

**Scenario: Replica set broken**

```bash
# 1. Stop MongoDB
docker-compose stop mongodb

# 2. Delete corrupted data
docker volume rm infra-devtools_mongodb_data

# 3. Start fresh
docker-compose up -d mongodb
sleep 30

# 4. Restore from backup
docker exec -i infra-default-mongodb mongorestore \
  --archive=reports/backups/<backup_file>

# 5. Verify
make health-check-databases
```

### 🔴 Redis Recovery

**Scenario: Memory full (Eviction)**

```bash
# 1. Check status
docker exec infra-default-redis redis-cli info memory

# 2. Increase memory limit
docker exec infra-default-redis redis-cli CONFIG SET \
  maxmemory 4gb

# 3. Set eviction policy
docker exec infra-default-redis redis-cli CONFIG SET \
  maxmemory-policy allkeys-lru

# 4. Save configuration
docker exec infra-default-redis redis-cli CONFIG REWRITE
```

**Scenario: RDB corruption**

```bash
# 1. Delete corrupted dump
docker exec infra-default-redis rm /data/dump.rdb

# 2. Restore from backup
cp reports/backups/redis_dump.rdb /data/

# 3. Restart
docker-compose restart redis
```

---

## Service Recovery

### 🔄 Rolling Recovery (Zero Downtime)

```bash
# Para serviços stateless:
docker-compose up -d --force-recreate postgres

# Para serviços com estado:
docker-compose stop postgres
docker-compose up -d postgres
make health-check-databases
```

### 📁 Volume Recovery

**Scenario: Volume deleted accidentally**

```bash
# 1. Check backup
docker volume ls | grep infra-devtools

# 2. If missing, restore from filesystem backup
docker volume create infra-devtools_postgres_data

# 3. Extract backup
tar -xzf reports/backups/postgres_volume.tar.gz -C /var/lib/docker/volumes/infra-devtools_postgres_data/_data

# 4. Restart service
docker-compose up -d postgres
```

### 🐳 Container Registry Issues

**Scenario: Image not available**

```bash
# 1. Check registry
docker pull postgres:15

# 2. If pull fails, use local image
docker load < local-postgres-backup.tar

# 3. Update docker-compose.yml
# image: postgres:15-alpine  (if needed)

# 4. Rebuild
docker-compose up -d postgres
```

---

## Backup & Restore Strategy

### 📅 Backup Schedule

```
Daily:     0 2 * * *  (02:00 AM)
Weekly:    0 3 * * 0  (Sunday 03:00 AM)
Monthly:   0 4 1 * *  (1st of month 04:00 AM)
```

### ✅ Backup Verification

**Run weekly:**

```bash
# 1. List backups
make backup-list

# 2. Restore to test environment
make restore BACKUP_ID=<recent_backup>

# 3. Verify data integrity
./scripts/health-check-databases

# 4. Check data consistency
docker exec infra-default-postgres psql -U postgres \
  -c "SELECT COUNT(*) FROM table_name;"
```

### 🗜️ Backup Compression

```bash
# Compress old backups
find reports/backups -mtime +7 -name "*.json" -exec \
  gzip {} \;

# Cleanup very old backups
find reports/backups -mtime +30 -delete
```

### 🔐 Backup Encryption

**Encrypt sensitive backups:**

```bash
# Encrypt with GPG
gpg --symmetric --cipher-algo AES256 \
  reports/backups/backup_file.tar.gz

# Decrypt
gpg --decrypt backup_file.tar.gz.gpg > backup_file.tar.gz
```

---

## RTO/RPO Matrix

| Serviço | RTO | RPO | Estratégia |
|---------|-----|-----|-----------|
| PostgreSQL | 5 min | 1 hora | Hot standby + WAL archiving |
| MongoDB | 5 min | 1 hora | Replica set + backup diário |
| MySQL | 5 min | 1 hora | Backup diário |
| Redis | 2 min | 30 min | RDB + AOF |
| SonarQube | 10 min | 24 horas | Backup diário |
| Grafana | 10 min | 24 horas | Backup diário |

**Legenda:**
- **RTO:** Recovery Time Objective (tempo para recuperar)
- **RPO:** Recovery Point Objective (quanto de dados perdidos)

---

## Disaster Recovery Checklist

### Preparação

- [ ] Documentar todas as dependencies
- [ ] Criar runbooks para cada cenário
- [ ] Testar recovery mensal
- [ ] Manter backups em location remota
- [ ] Documentar credenciais (em safe)
- [ ] Setup alertas para falhas
- [ ] Treinar equipe em procedures

### Durante Incidente

- [ ] Notificar stakeholders
- [ ] Abrir incident ticket
- [ ] Executar recovery procedure
- [ ] Monitor progress
- [ ] Documentar ações
- [ ] Comunicar status updates

### Pós Incidente

- [ ] Verify sistema está 100%
- [ ] Restaurar backups como teste
- [ ] Análise de root cause
- [ ] Atualizar documentation
- [ ] Implement preventive measures
- [ ] Post-mortem meeting
- [ ] Update runbooks

---

## Contact & Escalation

| Severidade | Time | Contact | RTO |
|-----------|------|---------|-----|
| Critical | On-call | +55-XX-XXXX | 30 min |
| High | Support | support@example.com | 2 horas |
| Medium | Engineering | engineering@example.com | 4 horas |
| Low | Backlog | slack #ops | Next sprint |

---

<p align="center">
  <b>Esperemos nunca precisar, mas estaremos preparados.</b><br>
  <b>🚀 Kleilson Santos</b>
</p>
