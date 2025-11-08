# ⚡ Performance Tuning Guide

> Guia para otimizar infraestrutura para ambientes de produção e desenvolvimento de alta performance.

## 📑 Índice

1. [System-Level Tuning](#system-level-tuning)
2. [Docker Optimization](#docker-optimization)
3. [Database Tuning](#database-tuning)
4. [Application Performance](#application-performance)
5. [Caching Strategy](#caching-strategy)
6. [Monitoring & Metrics](#monitoring--metrics)

---

## System-Level Tuning

### 🔧 Kernel Parameters

**Aumente file descriptors:**

```bash
# Permanente (/etc/security/limits.conf)
*       soft    nofile  65536
*       hard    nofile  65536
*       soft    nproc   65536
*       hard    nproc   65536

# Temporário
ulimit -n 65536
```

**Otimize TCP stack:**

```bash
sudo sysctl -w net.core.somaxconn=65535
sudo sysctl -w net.ipv4.tcp_max_syn_backlog=65535
sudo sysctl -w net.ipv4.ip_local_port_range="1024 65535"

# Persistente (/etc/sysctl.conf)
echo "net.core.somaxconn = 65535" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 65535" | sudo tee -a /etc/sysctl.conf
```

**Ative BBR congestion control:**

```bash
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 💾 Memory Management

**Configure swappiness:**

```bash
# Defina para 10 (menor swap)
sudo sysctl -w vm.swappiness=10
echo "vm.swappiness = 10" | sudo tee -a /etc/sysctl.conf
```

**Ative transparent huge pages:**

```bash
echo madvise | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
```

---

## Docker Optimization

### 🐳 Docker Daemon Configuration

**Edit `/etc/docker/daemon.json`:**

```json
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65536,
      "Soft": 65536
    }
  },
  "ipv6": false,
  "userland-proxy": false
}
```

Reload:
```bash
sudo systemctl reload docker
```

### 📦 Container Resource Limits

**Otimize docker-compose.yml:**

```yaml
services:
  postgres:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G

  redis:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 2G
```

### 🔄 Volume Performance

**Use tmpfs para temporários:**

```yaml
services:
  app:
    tmpfs:
      - /tmp
      - /var/tmp
```

**Opções de mount:**

```yaml
volumes:
  postgres_data:
    driver: local
    driver_opts:
      o: "defaults,noatime"
```

---

## Database Tuning

### 🐘 PostgreSQL

**Otimização de configuração:**

```bash
# Dentro do container
docker exec infra-default-postgres psql -U postgres -c "
ALTER SYSTEM SET shared_buffers = '2GB';
ALTER SYSTEM SET effective_cache_size = '8GB';
ALTER SYSTEM SET maintenance_work_mem = '512MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;
SELECT pg_reload_conf();
"
```

**Enable query logging:**

```bash
docker exec infra-default-postgres psql -U postgres -c "
ALTER SYSTEM SET log_min_duration_statement = 1000;
ALTER SYSTEM SET log_statement = 'all';
SELECT pg_reload_conf();
"
```

**Reindex tables:**

```bash
docker exec infra-default-postgres vacuumdb -U postgres --analyze --full
```

### 🍃 MongoDB

**Optimize storage engine:**

```bash
docker exec infra-default-mongodb mongosh --eval "
db.adminCommand({
  setParameter: 1,
  cacheSizeGB: 4
});
"
```

**Enable compression:**

```bash
docker exec infra-default-mongodb mongosh --eval "
use admin
db.setProfilingLevel(0)
db.system.profile.deleteMany({})
"
```

**Create indexes:**

```bash
docker exec infra-default-mongodb mongosh --eval "
use mydb
db.users.createIndex({email: 1})
db.users.createIndex({createdAt: -1})
"
```

### 🔴 Redis

**Optimize memory:**

```bash
docker exec infra-default-redis redis-cli CONFIG SET \
  maxmemory-policy allkeys-lru

docker exec infra-default-redis redis-cli CONFIG SET \
  maxmemory 2gb

# Persistir
docker exec infra-default-redis redis-cli CONFIG REWRITE
```

**Enable AOF:**

```bash
docker exec infra-default-redis redis-cli CONFIG SET \
  appendonly yes

docker exec infra-default-redis redis-cli CONFIG SET \
  appendfsync everysec
```

---

## Application Performance

### 🔗 Connection Pooling

**PostgreSQL (django/sqlalchemy):**

```python
# settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'CONN_MAX_AGE': 600,
        'OPTIONS': {
            'connect_timeout': 10,
        }
    }
}
```

**MongoDB (pymongo):**

```python
from pymongo import MongoClient

client = MongoClient(
    'mongodb://localhost:27017',
    maxPoolSize=50,
    minPoolSize=10
)
```

### 🔄 Query Optimization

**PostgreSQL - Use prepared statements:**

```python
cursor.execute("PREPARE stmt AS SELECT * FROM users WHERE id = $1")
cursor.execute("EXECUTE stmt (%s,)", [user_id])
```

**MongoDB - Use projection:**

```python
# Instead of
users = db.users.find({})

# Use
users = db.users.find({}, {"name": 1, "email": 1})
```

### 📦 API Response Caching

**Cache control headers:**

```python
from django.views.decorators.cache import cache_page

@cache_page(60 * 15)  # 15 minutes
def my_view(request):
    return JsonResponse(data)
```

---

## Caching Strategy

### 🧠 Redis Caching

**Setup cache backend:**

```python
# Django
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'CONNECTION_POOL_KWARGS': {'max_connections': 50}
        }
    }
}
```

**Cache patterns:**

```python
from django.core.cache import cache

# Set cache
cache.set('user:1', user_data, 3600)

# Get cache
user = cache.get('user:1')

# Cache with decorator
from django.views.decorators.cache import cache_page

@cache_page(60)
def list_users(request):
    return JsonResponse(User.objects.all().values())
```

### 🌐 HTTP Caching

**CDN setup (ngrok/Cloudflare):**

```bash
# Serve static through CDN
STATIC_URL = 'https://cdn.example.com/static/'
```

---

## Monitoring & Metrics

### 📊 Key Metrics to Track

```promql
# CPU usage trend
rate(container_cpu_usage_seconds_total[5m])

# Memory pressure
container_memory_working_set_bytes / container_spec_memory_limit_bytes * 100

# Query latency
histogram_quantile(0.95, rate(http_request_duration_seconds[5m]))

# Connection pool usage
mysql_global_status_threads_connected / mysql_global_variables_max_connections * 100
```

### 🚨 Alert Thresholds

```yaml
# prometheus.yml
- alert: HighCPUUsage
  expr: rate(cpu_usage[5m]) > 80
  for: 5m

- alert: HighMemoryUsage
  expr: memory_usage_percent > 85
  for: 5m

- alert: SlowQueries
  expr: rate(slow_queries[5m]) > 10
  for: 5m
```

### 📈 Performance Baseline

```bash
# Capture baseline metrics
./scripts/performance-monitor.sh once > baseline_$(date +%s).log

# Compare after tuning
./scripts/health-check.sh
```

---

## Checklist de Otimização

### Antes de Produção

- [ ] Ajustar kernel parameters
- [ ] Configurar resource limits para containers
- [ ] Otimizar índices de banco de dados
- [ ] Ativar connection pooling
- [ ] Setup Redis para caching
- [ ] Configurar CDN para assets estáticos
- [ ] Ativar compression (gzip)
- [ ] Setup monitoring e alertas
- [ ] Realizar load testing
- [ ] Documentar configurações

### Monitoramento Contínuo

- [ ] Monitorar CPU/Memory/Disk
- [ ] Rastrear query performance
- [ ] Alertas de slowness
- [ ] Backup testing mensal
- [ ] Segurança audits quarterly

---

<p align="center">
  <b>Performance tuning é iterativo. Meça, otimize, meça novamente.</b><br>
  <b>🚀 Kleilson Santos</b>
</p>
