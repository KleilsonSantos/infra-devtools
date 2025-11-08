# 💾 Backup Procedures

> **Backup e restauração de dados**

---

## Quick Reference

| Database | Backup Command | Size | Frequency |
|----------|--------|------|-----------|
| PostgreSQL | `docker exec infra-default-postgres pg_dump -U $POSTGRES_USER` | ~100MB | Daily |
| MongoDB | `docker exec infra-default-mongo mongodump` | ~50MB | Daily |
| MySQL | `docker exec infra-default-mysql mysqldump -u $MYSQL_USER` | ~80MB | Daily |
| Redis | `docker exec infra-default-redis redis-cli BGSAVE` | ~10MB | On-demand |

---

## Backup Strategy

**RTO (Recovery Time Objective):** < 30 minutes
**RPO (Recovery Point Objective):** < 1 hour

**Current:** Manual backups
**Recommended:** Automate com cron job

---

## PostgreSQL Backup

### Full Database Backup

```bash
# 1. Create backup directory
mkdir -p /backups/postgres
cd /backups/postgres

# 2. Backup
docker exec infra-default-postgres pg_dump \
  -U $POSTGRES_USER \
  -d $POSTGRES_DB \
  --format=custom \
  --verbose \
  -f backup_$(date +%Y%m%d_%H%M%S).dump

# 3. Verify
ls -lh backup_*.dump
```

### All Databases Backup

```bash
docker exec infra-default-postgres pg_dumpall \
  -U $POSTGRES_USER \
  > all_databases_$(date +%Y%m%d_%H%M%S).sql
```

### PostgreSQL Restore

```bash
# 1. Stop connections
docker exec infra-default-postgres \
  psql -U $POSTGRES_USER -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$POSTGRES_DB' AND pid != pg_backend_pid();"

# 2. Restore from dump
docker exec -i infra-default-postgres pg_restore \
  -U $POSTGRES_USER \
  -d $POSTGRES_DB \
  -v \
  < /backups/postgres/backup_20251108_120000.dump

# 3. Verify
docker exec infra-default-postgres \
  psql -U $POSTGRES_USER -d $POSTGRES_DB -c "\dt"
```

---

## MongoDB Backup

### Using mongodump

```bash
# 1. Create backup directory
mkdir -p /backups/mongodb
cd /backups/mongodb

# 2. Dump all databases
docker exec infra-default-mongo mongodump \
  --username $MONGO_INITDB_ROOT_USERNAME \
  --password $MONGO_INITDB_ROOT_PASSWORD \
  --out dump_$(date +%Y%m%d_%H%M%S)

# 3. Verify
ls -lh dump_*/
```

### Using snapshots (Better for large databases)

```bash
# 1. Enable replica set (if not enabled)
docker exec infra-default-mongo mongosh --eval "rs.initiate()"

# 2. Create snapshot
docker exec infra-default-mongo mongosh --eval "db.fsyncLock()"

# 3. Backup volumes
cp -r /var/lib/docker/volumes/infra-default-mongo_data/_data \
  /backups/mongodb/snapshot_$(date +%Y%m%d_%H%M%S)

# 4. Unlock
docker exec infra-default-mongo mongosh --eval "db.fsyncUnlock()"
```

### MongoDB Restore

```bash
# 1. Stop MongoDB
docker compose down mongo

# 2. Remove old data
docker volume rm infra-default-mongo_data

# 3. Restore from dump
docker compose up -d mongo
sleep 10

docker exec -i infra-default-mongo mongorestore \
  --username $MONGO_INITDB_ROOT_USERNAME \
  --password $MONGO_INITDB_ROOT_PASSWORD \
  --archive < /backups/mongodb/backup.archive

# 4. Verify
docker exec infra-default-mongo mongosh --eval "show databases"
```

---

## MySQL Backup

### Full Database Backup

```bash
# 1. Create backup directory
mkdir -p /backups/mysql
cd /backups/mysql

# 2. Backup all databases
docker exec infra-default-mysql mysqldump \
  -u $MYSQL_USER \
  -p$MYSQL_PASSWORD \
  --all-databases \
  --single-transaction \
  > backup_$(date +%Y%m%d_%H%M%S).sql

# 3. Verify
ls -lh backup_*.sql
```

### Specific Database Backup

```bash
docker exec infra-default-mysql mysqldump \
  -u $MYSQL_USER \
  -p$MYSQL_PASSWORD \
  $MYSQL_DATABASE \
  > backup_${MYSQL_DATABASE}_$(date +%Y%m%d_%H%M%S).sql
```

### MySQL Restore

```bash
# 1. Restore from backup
docker exec -i infra-default-mysql mysql \
  -u $MYSQL_USER \
  -p$MYSQL_PASSWORD \
  < /backups/mysql/backup_20251108_120000.sql

# 2. Verify
docker exec infra-default-mysql mysql \
  -u $MYSQL_USER \
  -p$MYSQL_PASSWORD \
  -e "SHOW DATABASES;"
```

---

## Redis Backup

### Snapshot Backup

```bash
# 1. Trigger save
docker exec infra-default-redis redis-cli BGSAVE

# 2. Wait for completion
docker exec infra-default-redis redis-cli LASTSAVE

# 3. Copy dump.rdb
docker exec infra-default-redis ls -lh /data/dump.rdb

docker cp infra-default-redis:/data/dump.rdb \
  /backups/redis/dump_$(date +%Y%m%d_%H%M%S).rdb
```

### AOF (Append-Only File) Backup

```bash
# Copy AOF file
docker cp infra-default-redis:/data/appendonly.aof \
  /backups/redis/appendonly_$(date +%Y%m%d_%H%M%S).aof
```

### Redis Restore

```bash
# 1. Stop Redis
docker compose down redis

# 2. Remove old volume
docker volume rm infra-default-redis_data

# 3. Copy backup
docker compose up -d redis
docker cp /backups/redis/dump_20251108_120000.rdb \
  infra-default-redis:/data/dump.rdb

# 4. Restart
docker compose restart redis

# 5. Verify
docker exec infra-default-redis redis-cli DBSIZE
```

---

## Volumes Backup (Docker)

### Backup All Named Volumes

```bash
#!/bin/bash
BACKUP_DIR="/backups/volumes"
DATE=$(date +%Y%m%d_%H%M%S)

for volume in $(docker volume ls -q); do
  echo "Backing up volume: $volume"
  docker run --rm -v "$volume":/data \
    -v "$BACKUP_DIR":/backup \
    alpine tar czf /backup/${volume}_${DATE}.tar.gz /data
done
```

### Restore Volume

```bash
# 1. Create new volume
docker volume create my-volume

# 2. Restore backup
docker run --rm -v my-volume:/data \
  -v /backups/volumes:/backup \
  alpine tar xzf /backup/my-volume_20251108_120000.tar.gz -C /

# 3. Verify
docker volume inspect my-volume
```

---

## Backup Scheduling (Cron)

### Create backup script

```bash
cat > /usr/local/bin/backup-infra.sh << 'EOF'
#!/bin/bash
set -e

BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${BACKUP_DIR}/backup_${DATE}.log"

echo "Starting backup at $(date)" > "$LOG_FILE"

# PostgreSQL
mkdir -p "$BACKUP_DIR/postgres"
docker exec infra-default-postgres pg_dump \
  -U $POSTGRES_USER \
  -d $POSTGRES_DB \
  --format=custom \
  -f /tmp/pg_backup.dump 2>> "$LOG_FILE"
cp /tmp/pg_backup.dump "$BACKUP_DIR/postgres/backup_${DATE}.dump"

# MongoDB
mkdir -p "$BACKUP_DIR/mongodb"
docker exec infra-default-mongo mongodump \
  --username $MONGO_INITDB_ROOT_USERNAME \
  --password $MONGO_INITDB_ROOT_PASSWORD \
  --out "$BACKUP_DIR/mongodb/dump_${DATE}" 2>> "$LOG_FILE"

# MySQL
mkdir -p "$BACKUP_DIR/mysql"
docker exec infra-default-mysql mysqldump \
  -u $MYSQL_USER \
  -p$MYSQL_PASSWORD \
  --all-databases \
  > "$BACKUP_DIR/mysql/backup_${DATE}.sql" 2>> "$LOG_FILE"

# Redis
mkdir -p "$BACKUP_DIR/redis"
docker exec infra-default-redis redis-cli BGSAVE
sleep 2
docker cp infra-default-redis:/data/dump.rdb \
  "$BACKUP_DIR/redis/dump_${DATE}.rdb"

# Clean old backups (keep last 7 days)
find "$BACKUP_DIR" -mtime +7 -delete

echo "Backup completed at $(date)" >> "$LOG_FILE"
EOF

chmod +x /usr/local/bin/backup-infra.sh
```

### Add to crontab

```bash
# Daily at 2 AM
0 2 * * * /usr/local/bin/backup-infra.sh > /var/log/backup.log 2>&1

# Edit crontab
crontab -e
```

---

## Backup Verification

### Check backup integrity

```bash
# PostgreSQL
pg_restore --list /backups/postgres/backup_*.dump | head -20

# MongoDB
tar tzf /backups/mongodb/dump_*.tar.gz | head -10

# MySQL
head -100 /backups/mysql/backup_*.sql

# Redis
file /backups/redis/dump_*.rdb
```

### Test restore (on staging)

```bash
# Never restore on production without testing!

# 1. Create test database
docker exec infra-default-postgres \
  psql -U $POSTGRES_USER -c "CREATE DATABASE test_restore"

# 2. Test restore
docker exec -i infra-default-postgres pg_restore \
  -U $POSTGRES_USER \
  -d test_restore \
  < /backups/postgres/backup_latest.dump

# 3. Verify
docker exec infra-default-postgres \
  psql -U $POSTGRES_USER -d test_restore -c "\dt"

# 4. Cleanup
docker exec infra-default-postgres \
  psql -U $POSTGRES_USER -c "DROP DATABASE test_restore"
```

---

## Backup Storage

### Current Location
`/backups/` (local filesystem)

### Recommended
- **Local:** `/backups/` (fast, quick restore)
- **Offsite:** S3/Cloud (disaster recovery)
- **Retention:** 30 days minimum

### Move to S3 (Optional)

```bash
# Install AWS CLI
aws s3 cp /backups/postgres/backup_*.dump \
  s3://my-bucket/infra-backups/postgres/

# Sync daily
aws s3 sync /backups s3://my-bucket/infra-backups/
```

---

## Backup Checklist

**Daily:**
- [ ] Backups completed without errors
- [ ] Check `/var/log/backup.log`
- [ ] Verify disk space available

**Weekly:**
- [ ] Test restore on non-production
- [ ] Verify offsite backup exists
- [ ] Check backup size trends

**Monthly:**
- [ ] Full restore test
- [ ] Document RTO/RPO achieved
- [ ] Review retention policy

---

## Common Issues

### "Backup permission denied"

```bash
# Fix permissions
docker exec infra-default-postgres chown postgres:postgres /tmp
```

### "Restore fails - database already exists"

```bash
# Drop existing database first
docker exec infra-default-postgres \
  dropdb -U $POSTGRES_USER $POSTGRES_DB

# Then restore
```

### "Backup file corrupted"

```bash
# Test dump integrity
pg_restore --list /path/to/backup.dump > /dev/null && echo "OK" || echo "CORRUPTED"

# If corrupted, restore from older backup
```

---

**Last Updated:** 2025-11-08
**Maintainer:** Operations Team
**Backup SLA:** Daily backups with 30-day retention
