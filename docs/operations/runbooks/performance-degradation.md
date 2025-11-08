# ⚡ Performance Degradation Runbook

> **Diagnóstico e otimização de performance**

---

## Symptoms

| Sintoma | Possível Causa | Ação Imediata |
|---------|--------|---|
| APIs lentas | Banco de dados lento | Verificar queries longas, índices |
| Dashboards Grafana lentos | Prometheus scraping slow | Aumentar scrape interval |
| Alertmanager demora | Email notifications slow | Verificar SMTP (Mailhog) |
| Container restarts | Out of memory | Verificar `docker stats` |
| High disk I/O | Banco de dados escrevendo muito | Verificar volume space |
| CPU 100% | Processo consumindo recursos | Identificar container, restart |

---

## 🔍 Quick Diagnostics

### Check System Resources

```bash
# Real-time resource usage
docker stats

# If any container near limits
# Example: MongoDB using 90%+ memory
docker stats --no-stream | grep mongo

# Host resources
free -h       # Memory
df -h         # Disk
top -b -n 1   # CPU
```

### Check Docker Logs for Errors

```bash
# All containers
docker compose logs --tail=100 | grep -i "error\|warn\|critical"

# Specific service
docker compose logs prometheus --tail=50 | grep -i "slow\|timeout"
```

### Check Prometheus Targets

```bash
# Via HTTP API
curl -s http://localhost:9090/api/v1/targets | jq '.data'

# Via Grafana UI
# Go to: http://localhost:3001 → Configuration → Data Sources
# → Prometheus → Scrape Pool Health
```

---

## 🐘 Database Performance

### PostgreSQL Slow Queries

**Symptoms:** `SELECT` queries taking >1 second

**Diagnosis:**
```bash
# Connect to PostgreSQL
docker exec -it infra-default-postgres psql -U $POSTGRES_USER -d $POSTGRES_DB

# Inside psql:
# Enable query logging
ALTER SYSTEM SET log_min_duration_statement = 1000; -- Log queries > 1 second
SELECT pg_reload_conf();

# View slow queries
SELECT * FROM pg_stat_statements
WHERE mean_exec_time > 1000
ORDER BY mean_exec_time DESC LIMIT 10;
```

**Optimization:**
```sql
-- Add indexes for frequently queried columns
CREATE INDEX idx_table_column ON table_name(column_name);

-- Vacuum and analyze
VACUUM ANALYZE;

-- Check table size
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

### MongoDB Slow Queries

**Symptoms:** `find()` operations taking too long

**Diagnosis:**
```bash
# Connect to MongoDB
docker exec -it infra-default-mongo mongosh

# Inside mongosh:
# Enable profiling
db.setProfilingLevel(1, { slowms: 100 }) // Log queries > 100ms

# View slow queries
db.system.profile.find().sort({ts:-1}).limit(10).pretty()

# Check indexes
db.collection_name.getIndexes()
```

**Optimization:**
```javascript
// Add index
db.collection_name.createIndex({ field: 1 })

// Rebuild indexes
db.collection_name.reIndex()

// Drop unused index
db.collection_name.dropIndex("field_1")
```

---

### MySQL Slow Queries

**Symptoms:** `SELECT` queries taking >2 seconds

**Diagnosis:**
```bash
# Connect to MySQL
docker exec -it infra-default-mysql \
  mysql -u $MYSQL_USER -p$MYSQL_PASSWORD

# Inside MySQL:
# Enable slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;

# Check current connections
SHOW PROCESSLIST;

# Kill long-running query
KILL <process_id>;
```

---

## 🚀 Prometheus Performance

### High Scrape Latency

**Symptoms:** "Prometheus taking too long to scrape targets"

**Diagnosis:**
```bash
# Check scrape duration
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, scrape_duration: .scrapeUrl}'

# Check number of metrics
curl -s http://localhost:9090/api/v1/label/__name__/values | jq '. | length'
```

**Optimization:**

Edit `prometheus.yml`:
```yaml
global:
  scrape_interval: 30s  # Increase from 15s
  evaluation_interval: 30s

# For heavy scrapers
scrape_configs:
  - job_name: 'monitoring'
    scrape_interval: 60s  # Slower scrape

  - job_name: 'prometheus'
    scrape_interval: 5s   # Keep critical fast
```

Then restart:
```bash
docker compose restart prometheus
```

---

## 📊 Grafana Dashboard Performance

### Slow Dashboard Rendering

**Symptoms:** Dashboard takes >5 seconds to load

**Diagnosis:**
```bash
# Check number of panels
curl -s http://localhost:3001/api/dashboards/uid/<dashboard-uid> | jq '.dashboard.panels | length'

# Check data source latency
# In Grafana UI → Explore → check query execution time
```

**Optimization:**

1. **Reduce panel refresh frequency**
   - Go to Dashboard Settings → Refresh interval
   - Change from 5s to 30s

2. **Simplify queries**
   - Reduce date range
   - Remove unnecessary aggregations
   - Use sampling for large datasets

3. **Add more Prometheus workers**
   - In `prometheus.yml`:
   ```yaml
   global:
     query_max_concurrency: 40  # Default is 20
   ```

---

## 🗄️ Disk Space Issues

**Symptoms:** Containers failing to write, "No space left on device"

**Diagnosis:**
```bash
# Check disk usage
df -h

# Check which service using most space
docker system df

# Check volume sizes
du -sh /var/lib/docker/volumes/infra-default-*

# Identify largest database
docker exec infra-default-postgres \
  psql -U $POSTGRES_USER -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database ORDER BY pg_database_size DESC;"
```

**Cleanup:**

```bash
# Remove old logs (be careful!)
docker compose logs --tail=0 > /dev/null

# Prune unused images
docker image prune -a --filter "until=720h"

# Prune unused volumes
docker volume prune

# Check Prometheus disk usage
du -sh /var/lib/docker/volumes/infra-default-prometheus_data

# If too large, retention can be adjusted
# prometheus.yml:
# global:
#   external_labels:
#     retention: 15d
```

---

## 💾 Memory Pressure

**Symptoms:** Container crashes with OOMKilled (Exit 137)

**Diagnosis:**
```bash
# Check memory limits
docker inspect infra-default-<service> | grep -A 5 Memory

# Check actual usage
docker stats --no-stream | grep <service>

# Check for memory leaks in app logs
docker compose logs <service> | grep -i "memory\|leak\|allocation"
```

**Resolution:**

1. **Increase memory limit** in `docker-compose.yml`:
```yaml
services:
  prometheus:
    mem_limit: 2g  # Increase from 1g
    memswap_limit: 2g
```

2. **Restart service:**
```bash
docker compose down prometheus
docker compose up -d prometheus
```

3. **Or reduce workload:**
   - Reduce retention in Prometheus
   - Increase scrape intervals
   - Reduce dashboard complexity

---

## 📈 CPU Saturation

**Symptoms:** Container using 100% CPU

**Diagnosis:**
```bash
# Identify high-CPU container
docker stats --no-stream | sort -k 3 -h -r

# Get process list inside container
docker top <container-id>

# Check if repeatedly restarting
docker compose logs --tail=20 | grep -i "restart"
```

**Common Causes & Fixes:**

| Service | Cause | Fix |
|---------|-------|-----|
| Prometheus | Too many metrics | Reduce scrape interval |
| Grafana | Complex dashboards | Simplify queries |
| MongoDB | Complex aggregations | Add indexes |
| PostgreSQL | Full table scans | Add indexes |

---

## 🔗 Network Latency

**Symptoms:** Inter-service communication slow

**Diagnosis:**
```bash
# Test latency between containers
docker compose exec prometheus ping -c 5 postgres

# Check network stats
docker network inspect infra-default-shared-net

# Monitor network I/O
iftop -i docker0  # If available
```

**Optimization:**

1. **Ensure containers on same network:**
   ```bash
   docker inspect infra-default-prometheus | grep Networks -A 10
   ```

2. **Reduce payload size:**
   - Use compression if supported
   - Filter unnecessary fields

3. **Increase connections:**
   - Database connection pooling
   - HTTP keep-alive enabled

---

## ✅ Performance Validation

After optimization, validate:

```bash
# 1. Check all containers healthy
docker compose ps | grep -v Up

# 2. Verify no errors in logs
docker compose logs --tail=20 | grep -i error

# 3. Monitor metrics after change
curl -s http://localhost:9090/api/v1/query?query=up | jq '.data.result'

# 4. Run tests
make test-all

# 5. Monitor for 5-10 minutes
docker stats
```

---

## 📊 Monitoring Performance Improvements

Use Prometheus queries to track improvements:

```
# Query latency over time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# Database query latency
histogram_quantile(0.95, rate(db_query_duration_seconds_bucket[5m]))
```

Add these to Grafana for continuous monitoring.

---

**Last Updated:** 2025-11-08
**Maintainer:** Operations Team
