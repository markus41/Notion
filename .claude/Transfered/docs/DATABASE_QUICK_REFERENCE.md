# Database Quick Reference

A cheat sheet for common database operations in the Agent Studio platform.

## Connection Strings

### PostgreSQL

```bash
# Local Development
postgresql://postgres:dev_password@localhost:5432/agent_studio

# Azure Production
postgresql://dbadmin@agent-studio-postgres:password@agent-studio-postgres.postgres.database.azure.com:5432/agent_studio?sslmode=require
```

### Cosmos DB

```python
# Python
endpoint = "https://agent-studio-cosmos.documents.azure.com:443/"
key = os.getenv("COSMOS_DB_KEY")
```

```csharp
// .NET
var endpoint = "https://agent-studio-cosmos.documents.azure.com:443/";
var key = Environment.GetEnvironmentVariable("COSMOS_DB_KEY");
```

### Redis

```bash
# Local
redis://localhost:6379

# Azure
rediss://agent-studio-redis.redis.cache.windows.net:6380,password=<key>,ssl=True
```

### Azure AI Search

```python
# Python
endpoint = "https://agent-studio-search.search.windows.net"
api_key = os.getenv("SEARCH_API_KEY")
```

---

## Common Queries

### PostgreSQL

#### Get Active Agents

```sql
SELECT
    a.agent_id,
    a.name,
    a.agent_type,
    a.total_executions,
    a.avg_latency_ms,
    w.name AS workspace_name
FROM agents a
JOIN workspaces w ON a.workspace_id = w.workspace_id
WHERE a.is_active = true
  AND a.deleted_at IS NULL
ORDER BY a.total_executions DESC
LIMIT 10;
```

#### Get Workspace Stats

```sql
SELECT * FROM workspace_stats
WHERE workspace_id = '...';
```

#### Check User Permissions

```sql
SELECT
    w.name,
    wm.role
FROM workspace_members wm
JOIN workspaces w ON wm.workspace_id = w.workspace_id
WHERE wm.user_id = '...'
  AND w.deleted_at IS NULL;
```

#### Audit Log Search

```sql
SELECT
    event_type,
    action,
    resource_name,
    user_id,
    created_at
FROM audit_logs
WHERE workspace_id = '...'
  AND created_at >= NOW() - INTERVAL '7 days'
ORDER BY created_at DESC
LIMIT 100;
```

### Cosmos DB

#### Get Active Workflows

```sql
SELECT * FROM c
WHERE c.workspaceId = @workspaceId
  AND c.status IN ('pending', 'running')
  AND c.type = 'workflow_execution'
ORDER BY c.createdAt DESC
```

#### Get Workflow Execution

```sql
SELECT * FROM c
WHERE c.id = @executionId
  AND c.workspaceId = @workspaceId
```

#### Get Conversation History

```sql
SELECT * FROM c
WHERE c.sessionId = @sessionId
  AND c.type = 'conversation_message'
ORDER BY c.timestamp ASC
```

#### Get Events for Aggregate (Event Sourcing)

```sql
SELECT * FROM c
WHERE c.aggregateId = @workflowId
  AND c.type = 'domain_event'
ORDER BY c.version ASC
```

### Redis

#### Session Management

```bash
# Store session
SET session:{session_id} "{\"user_id\":\"...\",\"workspace_id\":\"...\"}" EX 86400

# Get session
GET session:{session_id}

# Delete session
DEL session:{session_id}

# List user sessions
SMEMBERS user:{user_id}:sessions
```

#### Rate Limiting

```bash
# Increment counter
INCR rate_limit:user:{user_id}:minute:{timestamp}

# Set expiration
EXPIRE rate_limit:user:{user_id}:minute:{timestamp} 60

# Check rate limit
GET rate_limit:user:{user_id}:minute:{timestamp}
```

#### Caching

```bash
# Cache query result
SETEX workspace:{workspace_id}:agents 300 "[{...}, {...}]"

# Get cached result
GET workspace:{workspace_id}:agents

# Invalidate cache
DEL workspace:{workspace_id}:agents
```

#### Pub/Sub

```bash
# Subscribe to workspace notifications
SUBSCRIBE workspace:{workspace_id}:notifications

# Publish event
PUBLISH workspace:{workspace_id}:notifications "{\"type\":\"workflow.completed\"}"
```

#### Leaderboards

```bash
# Increment agent execution count
ZINCRBY leaderboard:agents:executions 1 {agent_id}

# Get top 10 agents
ZREVRANGE leaderboard:agents:executions 0 9 WITHSCORES

# Get agent rank
ZREVRANK leaderboard:agents:executions {agent_id}
```

### Azure AI Search

#### Index Document

```python
# Python
documents = [{
    "memoryId": "mem-123",
    "workspaceId": "ws-456",
    "content": "The agent framework supports sequential workflows.",
    "contentVector": embedding,  # 1536-dim vector
    "timestamp": datetime.utcnow().isoformat()
}]

search_client.upload_documents(documents)
```

#### Hybrid Search

```python
# Python
results = search_client.search(
    search_text="What is a workflow?",
    vector_queries=[
        VectorizedQuery(
            vector=query_embedding,
            k_nearest_neighbors=10,
            fields="contentVector"
        )
    ],
    filter=f"workspaceId eq '{workspace_id}'",
    top=10,
    query_type="semantic",
    semantic_configuration_name="memory-semantic-config"
)
```

---

## Performance Monitoring

### PostgreSQL

#### Active Connections

```sql
SELECT
    count(*),
    state
FROM pg_stat_activity
GROUP BY state;
```

#### Slow Queries (>1s)

```sql
SELECT
    query,
    calls,
    total_exec_time / 1000 AS total_seconds,
    mean_exec_time / 1000 AS avg_seconds
FROM pg_stat_statements
WHERE mean_exec_time > 1000
ORDER BY mean_exec_time DESC
LIMIT 10;
```

#### Cache Hit Ratio

```sql
SELECT
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) AS cache_hit_ratio
FROM pg_statio_user_tables;
-- Should be >0.90
```

#### Index Usage

```sql
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
```

#### Table Sizes

```sql
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
```

### Cosmos DB

#### Check RU Consumption

```bash
az cosmosdb sql container throughput show \
    --account-name agent-studio-cosmos \
    --resource-group rg-agent-studio \
    --database-name agent-studio \
    --name workflows
```

#### Monitor Metrics (Azure Portal)

- Request Units consumed
- Storage used
- Throttled requests (429 errors)
- Partition distribution

### Redis

#### Memory Usage

```bash
redis-cli INFO memory
```

#### Operations Per Second

```bash
redis-cli INFO stats | grep instantaneous_ops_per_sec
```

#### Cache Hit Ratio

```bash
redis-cli INFO stats | grep keyspace
# Calculate: hits / (hits + misses)
```

#### Find Large Keys

```bash
redis-cli --bigkeys
```

### Azure AI Search

#### Index Statistics

```bash
curl "https://agent-studio-search.search.windows.net/indexes/agent-memory-index/stats?api-version=2023-11-01" \
    -H "api-key: <admin-key>"
```

---

## Backup & Restore

### PostgreSQL

#### Full Backup

```bash
pg_dump -Fc \
    -h agent-studio-postgres.postgres.database.azure.com \
    -U dbadmin \
    -d agent_studio \
    -f backup_$(date +%Y%m%d).dump
```

#### Restore

```bash
pg_restore -d agent_studio backup_20250115.dump
```

#### Point-in-Time Recovery (PITR)

```bash
pgbackrest --stanza=agent-studio \
    --type=time \
    --target="2025-01-15 14:30:00" \
    restore
```

### Cosmos DB

#### Point-in-Time Restore

```bash
az cosmosdb sql database restore \
    --account-name agent-studio-cosmos \
    --resource-group rg-agent-studio \
    --name workflows \
    --restore-timestamp "2025-01-15T14:30:00Z" \
    --target-database-name workflows_restored
```

### Redis

#### Snapshot

```bash
redis-cli BGSAVE
```

#### Restore

```bash
cp backup_dump.rdb /var/lib/redis/dump.rdb
redis-cli SHUTDOWN NOSAVE
sudo systemctl start redis
```

---

## Troubleshooting

### PostgreSQL

#### Kill Long-Running Query

```sql
-- Find long-running queries
SELECT
    pid,
    now() - query_start AS duration,
    query
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY duration DESC;

-- Kill query
SELECT pg_terminate_backend(pid);
```

#### Kill Idle Connections

```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle'
  AND state_change < now() - INTERVAL '10 minutes';
```

#### Check for Locks

```sql
SELECT * FROM pg_locks WHERE NOT granted;
```

#### Vacuum Bloated Table

```sql
VACUUM FULL ANALYZE agents;
```

### Cosmos DB

#### Check for Hot Partitions

```sql
SELECT
    c.workspaceId AS partitionKey,
    COUNT(1) AS document_count
FROM c
GROUP BY c.workspaceId
ORDER BY COUNT(1) DESC
```

#### Reduce RU Consumption

- Add composite indexes
- Use partition key in queries
- Limit result set size
- Enable indexing only on required paths

### Redis

#### Memory Exhausted

```bash
# Check memory
redis-cli INFO memory

# Set eviction policy
redis-cli CONFIG SET maxmemory-policy allkeys-lru

# Flush specific database
redis-cli -n 0 FLUSHDB
```

#### Connection Timeout

```bash
# Check connection pool settings
# Python: max_connections parameter
# .NET: connection string options

# Increase timeout
redis-cli CONFIG SET timeout 300
```

---

## Security Commands

### PostgreSQL

#### Create User

```sql
CREATE USER agent_studio_app WITH PASSWORD 'strong-password';
GRANT CONNECT ON DATABASE agent_studio TO agent_studio_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO agent_studio_app;
```

#### Enable RLS

```sql
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;

CREATE POLICY agent_workspace_isolation ON agents
    FOR ALL
    USING (
        workspace_id IN (
            SELECT workspace_id
            FROM workspace_members
            WHERE user_id = current_setting('app.current_user_id')::UUID
        )
    );
```

#### Rotate Password

```sql
ALTER USER agent_studio_app WITH PASSWORD 'new-strong-password';
```

### Cosmos DB

#### Regenerate Keys

```bash
az cosmosdb keys regenerate \
    --account-name agent-studio-cosmos \
    --resource-group rg-agent-studio \
    --key-kind primary
```

### Redis

#### Set Password

```bash
redis-cli CONFIG SET requirepass "strong-password"
```

#### Rename Dangerous Commands

```bash
# In redis.conf
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG "CONFIG_abc123"
```

---

## Maintenance Tasks

### PostgreSQL

#### Refresh Materialized Views

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY workspace_stats;
REFRESH MATERIALIZED VIEW CONCURRENTLY agent_performance;
```

#### Update Statistics

```sql
ANALYZE agents;
ANALYZE workspaces;
```

#### Reindex

```sql
REINDEX TABLE agents;
REINDEX INDEX idx_agents_workspace;
```

#### Create Next Month Partition

```sql
SELECT create_next_audit_log_partition();
```

### Cosmos DB

#### Update Throughput

```bash
az cosmosdb sql container throughput update \
    --account-name agent-studio-cosmos \
    --resource-group rg-agent-studio \
    --database-name agent-studio \
    --name workflows \
    --throughput 8000
```

### Redis

#### Flush Expired Keys

```bash
redis-cli --scan --pattern "expired:*" | xargs redis-cli DEL
```

#### Compact AOF

```bash
redis-cli BGREWRITEAOF
```

---

## Performance Targets

| Metric                     | Target    |
|----------------------------|-----------|
| PostgreSQL Query (p95)     | <20ms     |
| Cosmos DB Point Read (p95) | <25ms     |
| Redis GET (p95)            | <2ms      |
| Azure AI Search (p95)      | <50ms     |
| Cache Hit Ratio            | >95%      |
| Connection Pool Usage      | <80%      |
| Disk Usage                 | <80%      |
| Replication Lag            | <10s      |

---

## Emergency Contacts

- **Database Team**: database@brookside-proving-grounds.com
- **On-Call**: +1-555-123-4567
- **Escalation**: cto@brookside-proving-grounds.com

---

## Useful Links

- [Full Data Layer Design](./DATA_LAYER_DESIGN.md)
- [Database Infrastructure README](../infra/database/README.md)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Cosmos DB Docs](https://docs.microsoft.com/azure/cosmos-db/)
- [Redis Docs](https://redis.io/documentation)
- [Azure AI Search Docs](https://docs.microsoft.com/azure/search/)
