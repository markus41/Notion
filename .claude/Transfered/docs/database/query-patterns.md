---
title: Query Patterns & Optimization
description: Establish high-performance data access patterns for scalable AI workflows. Comprehensive guide to Azure Cosmos DB, Redis, and AI Search optimization.
tags:
  - database
  - query-optimization
  - cosmos-db
  - redis
  - performance
  - best-practices
  - azure
lastUpdated: 2025-10-09
author: Agent Studio Team
audience: developers
---

# Query Patterns & Optimization

## Overview

This document provides comprehensive query patterns and optimization techniques for Agent Studio's data architecture. The platform uses a hybrid storage strategy combining **Azure Cosmos DB** (NoSQL document database for workflow state management), **Azure AI Search** (vector storage for semantic memory), and **Azure Cache for Redis** (caching and session management).

### Data Store Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     APPLICATION LAYER                           │
│  .NET Services (C#)    │    Python Services    │   Node.js      │
│  - AgentStudio.Api     │    - meta_agents      │   - MCP        │
│  - WorkflowRepository  │    - VectorStore      │   - Servers    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     DATA LAYER                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Cosmos DB    │  │ AI Search    │  │ Redis Cache         │  │
│  │ - State      │  │ - Vectors    │  │ - Sessions          │  │
│  │ - Metrics    │  │ - Semantic   │  │ - Rate Limiting     │  │
│  │ - Audit      │  │ - Hybrid     │  │ - Distributed Locks │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

**Access Patterns**:
- **Read-Heavy**: Agent memories (70% reads, 30% writes)
- **Write-Heavy**: Workflow states (40% reads, 60% writes)
- **Time-Series**: Metrics and logs (append-only, time-range queries)
- **Session-Based**: Agent conversations (session-scoped queries)

**Performance Targets** (p95):
- Workflow state read: < 10ms
- Workflow state write: < 50ms
- Vector search: < 100ms
- Redis cache hit: < 5ms
- Cross-partition query: < 200ms

---

## Cosmos DB Patterns

Azure Cosmos DB provides globally distributed, multi-model database capabilities with guaranteed low latency and high availability. Agent Studio uses the **NoSQL API** with **Session consistency** for optimal performance and strong consistency within a session.

### Core Queries

#### 1. Get Workflow Execution (Point Read)

**Use Case**: Retrieve workflow state by ID - fastest possible query

**.NET Implementation**:
```csharp
using AgentStudio.Data.Repositories;
using Microsoft.Azure.Cosmos;

public class WorkflowService
{
    private readonly IWorkflowRepository _workflowRepo;

    public async Task<WorkflowState?> GetWorkflowAsync(string workflowId)
    {
        // Point read: uses id + partition key (workflow_id)
        var workflow = await _workflowRepo.GetWorkflowStateAsync(workflowId);

        if (workflow != null)
        {
            Console.WriteLine($"Status: {workflow.Status}");
            Console.WriteLine($"Current Step: {workflow.CurrentStep}/{workflow.TotalSteps}");
            Console.WriteLine($"Duration: {workflow.PerformanceMetrics?.TotalDurationMs}ms");
        }

        return workflow;
    }
}
```

**Direct Cosmos DB SDK**:
```csharp
var container = cosmosClient.GetContainer("project-ascension-db", "workflow-states");

// Point read - most efficient query (1 RU)
var response = await container.ReadItemAsync<WorkflowState>(
    id: "workflow-123",
    partitionKey: new PartitionKey("workflow-123")
);

var workflow = response.Resource;
Console.WriteLine($"RU Charged: {response.RequestCharge}"); // ~1 RU
Console.WriteLine($"Latency: {response.Diagnostics.GetClientElapsedTime()}"); // ~5-10ms
```

**Performance Notes**:
- **Latency**: 5-10ms (p95)
- **RU Cost**: 1 RU for 1 KB document
- **Indexing**: Not required (direct lookup by id + partition key)
- **Optimization**: Always use partition key to avoid cross-partition queries

---

#### 2. List Active Workflows (Filtered Query)

**Use Case**: Dashboard view showing in-progress workflows for a workspace

**.NET Implementation**:
```csharp
public async Task<List<WorkflowState>> GetActiveWorkflowsAsync(
    string workspaceId,
    int limit = 100,
    string? continuationToken = null)
{
    var workflows = await _workflowRepo.QueryWorkflowsByWorkspaceAsync(
        workspaceId: workspaceId,
        status: "in_progress",
        limit: limit,
        continuationToken: continuationToken
    );

    return workflows;
}
```

**Cosmos DB SQL Query**:
```sql
SELECT
    c.id,
    c.workflow_id,
    c.name,
    c.type,
    c.status,
    c.current_step,
    c.total_steps,
    c.created_at,
    c.updated_at,
    c.performance_metrics
FROM c
WHERE c.workspace_id = @workspaceId
  AND c.status = @status
ORDER BY c.created_at DESC
OFFSET @offset LIMIT @limit
```

**Pagination Pattern**:
```csharp
var queryDefinition = new QueryDefinition(
    @"SELECT * FROM c
      WHERE c.workspace_id = @workspaceId
        AND c.status = @status
      ORDER BY c.created_at DESC")
    .WithParameter("@workspaceId", "ws-tenant-001")
    .WithParameter("@status", "in_progress");

var queryIterator = container.GetItemQueryIterator<WorkflowState>(
    queryDefinition,
    continuationToken: null,
    requestOptions: new QueryRequestOptions
    {
        MaxItemCount = 100,
        PartitionKey = null // Cross-partition query
    }
);

var results = new List<WorkflowState>();
while (queryIterator.HasMoreResults)
{
    var response = await queryIterator.ReadNextAsync();
    results.AddRange(response.Resource);

    Console.WriteLine($"RU Charged: {response.RequestCharge}"); // ~10-20 RU
    Console.WriteLine($"Continuation Token: {response.ContinuationToken}");
}
```

**Performance Notes**:
- **Latency**: 50-150ms (p95, cross-partition)
- **RU Cost**: 10-20 RU (depends on workspace size)
- **Indexing**: Uses composite index: `(workspace_id ASC, status ASC, created_at DESC)`
- **Optimization**: Cache results for 5 minutes for dashboard views

---

#### 3. Get Task Execution History (Time-Series Query)

**Use Case**: Retrieve agent metrics for performance analysis

**Python Implementation**:
```python
from datetime import datetime, timezone
from azure.cosmos import CosmosClient

async def get_agent_metrics(
    cosmos_client: CosmosClient,
    agent_id: str,
    metric_type: str,
    start_date: str,
    end_date: str
):
    container = cosmos_client.get_database_client("project-ascension-db") \
        .get_container_client("agent-metrics")

    query = """
        SELECT
            c.timestamp,
            c.agent_id,
            c.metric_type,
            c.value,
            c.dimensions
        FROM c
        WHERE c.metric_date >= @start_date
          AND c.metric_date <= @end_date
          AND c.agent_id = @agent_id
          AND c.metric_type = @metric_type
        ORDER BY c.timestamp ASC
    """

    items = container.query_items(
        query=query,
        parameters=[
            {"name": "@start_date", "value": start_date},
            {"name": "@end_date", "value": end_date},
            {"name": "@agent_id", "value": agent_id},
            {"name": "@metric_type", "value": metric_type}
        ],
        enable_cross_partition_query=True
    )

    metrics = [item async for item in items]

    # Calculate statistics
    values = [m['value'] for m in metrics]
    avg_value = sum(values) / len(values) if values else 0
    max_value = max(values) if values else 0
    min_value = min(values) if values else 0

    return {
        "metrics": metrics,
        "statistics": {
            "count": len(metrics),
            "avg": avg_value,
            "max": max_value,
            "min": min_value
        }
    }

# Usage
metrics_data = await get_agent_metrics(
    cosmos_client=cosmos_client,
    agent_id="architect-001",
    metric_type="latency",
    start_date="2025-10-01",
    end_date="2025-10-07"
)

print(f"Average latency: {metrics_data['statistics']['avg']:.2f}ms")
```

**Performance Notes**:
- **Latency**: 20-80ms (p95, single partition per day)
- **RU Cost**: 3-15 RU (depends on time range)
- **Indexing**: Uses composite index: `(metric_date DESC, agent_id ASC, metric_type ASC)`
- **Partitioning**: Partitioned by `metric_date` (YYYY-MM-DD format)
- **Optimization**: Query single partition when possible (single day queries)

---

### Partition Key Strategy

Cosmos DB performance depends heavily on partition key selection. Agent Studio uses multiple strategies:

**1. High-Cardinality Partitions** (workflow-states, agent-memories):
- **Partition Key**: `/workflow_id` or `/agent_id`
- **Rationale**: Each workflow/agent instance is a unique partition
- **Expected Cardinality**: 10,000+ active workflows
- **Avg. Documents per Partition**: 1-5 (workflow + checkpoints)
- **Query Pattern**: Point reads (id + partition key)

**2. Time-Based Partitions** (agent-metrics, tool-invocations):
- **Partition Key**: `/metric_date` or `/tool_date` (YYYY-MM-DD)
- **Rationale**: Optimizes time-range queries, simplifies TTL management
- **Expected Cardinality**: 365+ partitions per year
- **Avg. Documents per Partition**: 10,000-100,000 (depends on activity)
- **Query Pattern**: Single-day queries (single partition) or multi-day (cross-partition)

**Design Tradeoffs**:

| Pattern | Pros | Cons |
|---------|------|------|
| **High-Cardinality** | Point reads are 1 RU, no hot partitions | Cross-workspace queries are expensive |
| **Time-Based** | Time-range queries are efficient | Hot partitions during high-activity periods |
| **Composite** | Flexible querying | Complex partition logic, potential skew |

---

### Indexing

Cosmos DB automatically indexes all document properties by default. Agent Studio uses **custom indexing policies** to optimize query performance and reduce RU consumption.

#### Indexing Policy Example (workflow-states)

```json
{
  "indexingMode": "consistent",
  "automatic": true,
  "includedPaths": [
    {"path": "/workflow_id/?"},
    {"path": "/workspace_id/?"},
    {"path": "/status/?"},
    {"path": "/type/?"},
    {"path": "/created_at/?"},
    {"path": "/updated_at/?"},
    {"path": "/current_step/?"}
  ],
  "excludedPaths": [
    {"path": "/_etag/?"},
    {"path": "/agents/*/result/*"},
    {"path": "/checkpoints/*/state/*"}
  ],
  "compositeIndexes": [
    [
      {"path": "/workspace_id", "order": "ascending"},
      {"path": "/status", "order": "ascending"},
      {"path": "/created_at", "order": "descending"}
    ],
    [
      {"path": "/workspace_id", "order": "ascending"},
      {"path": "/type", "order": "ascending"},
      {"path": "/updated_at", "order": "descending"}
    ]
  ]
}
```

**Indexing Strategy**:

1. **Included Paths**: Index only frequently queried fields
   - Status, type, timestamps (query filters)
   - Workspace ID, agent ID (multi-tenancy)

2. **Excluded Paths**: Skip large fields to reduce RU cost
   - Agent result payloads (large JSON objects)
   - Checkpoint state snapshots (serialized data)
   - ETag (internal Cosmos DB field)

3. **Composite Indexes**: Multi-field queries
   - `(workspace_id, status, created_at)` - "List workflows by status"
   - `(workspace_id, type, updated_at)` - "List workflows by type"
   - Order matters: Match query ORDER BY clause

**Index Utilization Monitoring**:
```csharp
var query = container.GetItemQueryIterator<WorkflowState>(
    queryDefinition,
    requestOptions: new QueryRequestOptions
    {
        PopulateIndexMetrics = true
    }
);

var response = await query.ReadNextAsync();
Console.WriteLine($"Index Metrics: {response.IndexMetrics}");
Console.WriteLine($"Utilized Single Indexes: {response.IndexMetrics.UtilizedSingleIndexes}");
Console.WriteLine($"Utilized Composite Indexes: {response.IndexMetrics.CompositeIndexes}");
```

---

### Change Feed

Cosmos DB **Change Feed** provides a persistent record of all document changes in insertion or update order. Agent Studio uses Change Feed for real-time event processing.

#### Real-Time Workflow Status Updates

**.NET Change Feed Processor**:
```csharp
using Microsoft.Azure.Cosmos;

public class WorkflowChangeFeedProcessor
{
    private readonly Container _workflowContainer;
    private readonly Container _leaseContainer;
    private readonly ILogger<WorkflowChangeFeedProcessor> _logger;
    private readonly IHubContext<MetaAgentHub, IMetaAgentClient> _hubContext;

    public async Task StartAsync(CancellationToken cancellationToken)
    {
        var changeFeedProcessor = _workflowContainer
            .GetChangeFeedProcessorBuilder<WorkflowState>(
                processorName: "workflowStatusProcessor",
                onChangesDelegate: HandleWorkflowChangesAsync)
            .WithInstanceName($"instance-{Environment.MachineName}")
            .WithLeaseContainer(_leaseContainer)
            .WithStartTime(DateTime.UtcNow.AddHours(-1)) // Process last hour
            .WithPollInterval(TimeSpan.FromSeconds(5))
            .WithMaxItems(100)
            .Build();

        await changeFeedProcessor.StartAsync();
        _logger.LogInformation("Change Feed Processor started");
    }

    private async Task HandleWorkflowChangesAsync(
        IReadOnlyCollection<WorkflowState> changes,
        CancellationToken cancellationToken)
    {
        foreach (var workflow in changes)
        {
            _logger.LogInformation(
                "Workflow {WorkflowId} status changed to {Status}",
                workflow.WorkflowId, workflow.Status);

            // Broadcast via SignalR
            await _hubContext.Clients
                .Group($"workspace:{workflow.WorkspaceId}")
                .ReceiveWorkflowUpdate(new WorkflowUpdateEvent
                {
                    WorkflowId = workflow.WorkflowId,
                    Status = workflow.Status,
                    CurrentStep = workflow.CurrentStep,
                    TotalSteps = workflow.TotalSteps,
                    UpdatedAt = workflow.UpdatedAt
                });

            // Trigger downstream processing
            if (workflow.Status == "completed")
            {
                await ProcessCompletedWorkflow(workflow);
            }
            else if (workflow.Status == "failed")
            {
                await NotifyWorkflowFailure(workflow);
            }
        }
    }
}
```

**Use Cases**:
- **Real-Time Dashboards**: Update UI when workflow status changes
- **Analytics Pipeline**: Stream events to Azure Event Hubs or Synapse
- **Audit Logging**: Write immutable audit trail to Azure Data Lake
- **Cache Invalidation**: Invalidate Redis cache on state changes

**Performance Notes**:
- **Latency**: Near real-time (< 5 seconds from write to notification)
- **Throughput**: 100-1000 changes/sec per processor instance
- **Scalability**: Horizontally scalable (multiple processor instances)
- **Reliability**: Lease-based coordination prevents duplicate processing

---

## Redis Patterns

Azure Cache for Redis provides sub-millisecond latency for caching, session management, rate limiting, and distributed locks. Agent Studio uses **Redis 6.x** with **Standard tier** (replication enabled).

### Caching Strategies

#### Cache-Aside Pattern (Lazy Loading)

**Use Case**: Cache frequently accessed workflow states to reduce Cosmos DB load

**.NET Implementation with StackExchange.Redis**:
```csharp
using StackExchange.Redis;
using System.Text.Json;

public class CachedWorkflowRepository : IWorkflowRepository
{
    private readonly IWorkflowRepository _cosmosRepo;
    private readonly IConnectionMultiplexer _redis;
    private readonly IDatabase _cache;
    private readonly TimeSpan _defaultTtl = TimeSpan.FromMinutes(5);

    public CachedWorkflowRepository(
        IWorkflowRepository cosmosRepo,
        IConnectionMultiplexer redis)
    {
        _cosmosRepo = cosmosRepo;
        _redis = redis;
        _cache = redis.GetDatabase();
    }

    public async Task<WorkflowState?> GetWorkflowStateAsync(
        string workflowId,
        CancellationToken cancellationToken = default)
    {
        var cacheKey = $"workflow:{workflowId}";

        // 1. Try cache first
        var cachedValue = await _cache.StringGetAsync(cacheKey);
        if (cachedValue.HasValue)
        {
            Console.WriteLine("Cache HIT");
            return JsonSerializer.Deserialize<WorkflowState>(cachedValue!);
        }

        Console.WriteLine("Cache MISS");

        // 2. Fetch from Cosmos DB
        var workflow = await _cosmosRepo.GetWorkflowStateAsync(
            workflowId, cancellationToken);

        if (workflow != null)
        {
            // 3. Populate cache
            var serialized = JsonSerializer.Serialize(workflow);
            await _cache.StringSetAsync(
                cacheKey,
                serialized,
                expiry: _defaultTtl,
                when: When.Always,
                flags: CommandFlags.FireAndForget // Async set
            );
        }

        return workflow;
    }

    public async Task SaveWorkflowStateAsync(
        WorkflowState workflow,
        CancellationToken cancellationToken = default)
    {
        // 1. Write to Cosmos DB (source of truth)
        await _cosmosRepo.SaveWorkflowStateAsync(workflow, cancellationToken);

        // 2. Invalidate cache (write-through not guaranteed)
        var cacheKey = $"workflow:{workflow.WorkflowId}";
        await _cache.KeyDeleteAsync(cacheKey, flags: CommandFlags.FireAndForget);
    }
}
```

**Redis Commands**:
```bash
# Get cached workflow
GET workflow:workflow-123

# Set cached workflow (5 minute TTL)
SETEX workflow:workflow-123 300 "{\"id\":\"workflow-123\",\"status\":\"in_progress\"...}"

# Delete cache on update
DEL workflow:workflow-123

# Check if key exists
EXISTS workflow:workflow-123

# Get TTL
TTL workflow:workflow-123
```

**Performance Notes**:
- **Cache Hit Latency**: < 5ms (p95)
- **Cache Miss Latency**: ~10-15ms (Redis + Cosmos DB)
- **Cache Hit Ratio Target**: > 95%
- **TTL Strategy**: 5 minutes for workflow states (balance freshness vs. hit ratio)

---

#### Write-Through Cache

**Use Case**: Ensure cache consistency by writing to both Redis and Cosmos DB

**.NET Implementation**:
```csharp
public async Task UpdateAgentStatusAsync(
    string workflowId,
    string agentId,
    string status,
    AgentResult result,
    CancellationToken cancellationToken = default)
{
    // 1. Write to Cosmos DB (source of truth)
    var workflow = await _cosmosRepo.UpdateAgentStatusAsync(
        workflowId, agentId, status, result, cancellationToken);

    // 2. Update cache (write-through)
    var cacheKey = $"workflow:{workflowId}";
    var serialized = JsonSerializer.Serialize(workflow);
    await _cache.StringSetAsync(cacheKey, serialized, expiry: _defaultTtl);

    return workflow;
}
```

**Tradeoffs**:
- **Pros**: Strong consistency, cache always fresh
- **Cons**: Higher write latency (Redis + Cosmos DB), potential for partial failures
- **Recommendation**: Use write-through for critical paths (workflow status updates), cache-aside for reads

---

### Session Management

**Use Case**: Store agent conversation sessions with automatic expiration

**Python Implementation with redis-py**:
```python
import redis.asyncio as redis
import json
from datetime import timedelta

class SessionManager:
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
        self.session_ttl = timedelta(hours=2)  # 2-hour session timeout

    async def create_session(
        self,
        session_id: str,
        agent_id: str,
        workspace_id: str,
        user_id: str
    ) -> dict:
        session_key = f"session:{session_id}"

        session_data = {
            "session_id": session_id,
            "agent_id": agent_id,
            "workspace_id": workspace_id,
            "user_id": user_id,
            "created_at": datetime.utcnow().isoformat(),
            "message_count": 0
        }

        # Store session with TTL
        await self.redis.setex(
            session_key,
            int(self.session_ttl.total_seconds()),
            json.dumps(session_data)
        )

        return session_data

    async def get_session(self, session_id: str) -> dict | None:
        session_key = f"session:{session_id}"

        session_json = await self.redis.get(session_key)
        if not session_json:
            return None

        # Refresh TTL on access (sliding expiration)
        await self.redis.expire(session_key, int(self.session_ttl.total_seconds()))

        return json.loads(session_json)

    async def add_message_to_session(
        self,
        session_id: str,
        message: dict
    ) -> None:
        # 1. Increment message count
        session_key = f"session:{session_id}"
        session_data = await self.get_session(session_id)
        if not session_data:
            raise ValueError(f"Session {session_id} not found")

        session_data["message_count"] += 1
        await self.redis.setex(
            session_key,
            int(self.session_ttl.total_seconds()),
            json.dumps(session_data)
        )

        # 2. Add message to session history (list)
        history_key = f"session:{session_id}:messages"
        await self.redis.rpush(history_key, json.dumps(message))
        await self.redis.expire(history_key, int(self.session_ttl.total_seconds()))

    async def get_session_messages(
        self,
        session_id: str,
        limit: int = 50
    ) -> list[dict]:
        history_key = f"session:{session_id}:messages"

        # Get last N messages
        messages = await self.redis.lrange(history_key, -limit, -1)
        return [json.loads(msg) for msg in messages]

    async def delete_session(self, session_id: str) -> None:
        session_key = f"session:{session_id}"
        history_key = f"session:{session_id}:messages"

        # Delete both session and history
        await self.redis.delete(session_key, history_key)
```

**Redis Commands**:
```bash
# Create session (2 hour TTL)
SETEX session:session-123 7200 "{\"session_id\":\"session-123\",\"agent_id\":\"arch-001\"...}"

# Get session (refresh TTL)
GET session:session-123
EXPIRE session:session-123 7200

# Add message to session
RPUSH session:session-123:messages "{\"role\":\"user\",\"content\":\"Hello\"}"
EXPIRE session:session-123:messages 7200

# Get last 50 messages
LRANGE session:session-123:messages -50 -1

# Delete session
DEL session:session-123 session:session-123:messages
```

---

### Rate Limiting

**Use Case**: Token bucket algorithm for API rate limiting

**.NET Implementation**:
```csharp
using StackExchange.Redis;

public class RateLimiter
{
    private readonly IDatabase _cache;
    private readonly int _maxTokens;
    private readonly TimeSpan _refillInterval;

    public RateLimiter(
        IConnectionMultiplexer redis,
        int maxTokens = 100,
        TimeSpan? refillInterval = null)
    {
        _cache = redis.GetDatabase();
        _maxTokens = maxTokens;
        _refillInterval = refillInterval ?? TimeSpan.FromMinutes(1);
    }

    public async Task<bool> AllowRequestAsync(
        string workspaceId,
        int tokensRequired = 1)
    {
        var bucketKey = $"ratelimit:{workspaceId}";
        var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();

        // Lua script for atomic token bucket check
        var script = @"
            local bucket_key = KEYS[1]
            local max_tokens = tonumber(ARGV[1])
            local refill_rate = tonumber(ARGV[2])
            local tokens_required = tonumber(ARGV[3])
            local now = tonumber(ARGV[4])

            local bucket = redis.call('HMGET', bucket_key, 'tokens', 'last_refill')
            local tokens = tonumber(bucket[1]) or max_tokens
            local last_refill = tonumber(bucket[2]) or now

            -- Refill tokens based on elapsed time
            local elapsed = now - last_refill
            local refilled_tokens = elapsed * refill_rate
            tokens = math.min(max_tokens, tokens + refilled_tokens)

            -- Check if enough tokens
            if tokens >= tokens_required then
                tokens = tokens - tokens_required
                redis.call('HMSET', bucket_key, 'tokens', tokens, 'last_refill', now)
                redis.call('EXPIRE', bucket_key, 3600)
                return 1
            else
                return 0
            end
        ";

        var refillRate = _maxTokens / _refillInterval.TotalSeconds;

        var result = await _cache.ScriptEvaluateAsync(
            script,
            keys: new RedisKey[] { bucketKey },
            values: new RedisValue[]
            {
                _maxTokens,
                refillRate,
                tokensRequired,
                now
            }
        );

        return (int)result == 1;
    }
}

// Usage
var rateLimiter = new RateLimiter(redis, maxTokens: 100, refillInterval: TimeSpan.FromMinutes(1));

if (await rateLimiter.AllowRequestAsync("ws-tenant-001"))
{
    // Process request
    Console.WriteLine("Request allowed");
}
else
{
    // Return 429 Too Many Requests
    Console.WriteLine("Rate limit exceeded");
}
```

**Redis Commands**:
```bash
# Check token bucket
HMGET ratelimit:ws-tenant-001 tokens last_refill

# Manual token bucket update (for testing)
HMSET ratelimit:ws-tenant-001 tokens 100 last_refill 1696723200
EXPIRE ratelimit:ws-tenant-001 3600
```

---

### Distributed Locks

**Use Case**: Prevent concurrent workflow execution (idempotency)

**.NET Implementation with RedLock**:
```csharp
using RedLockNet;
using RedLockNet.SERedis;
using StackExchange.Redis;

public class WorkflowExecutionService
{
    private readonly IDistributedLockFactory _lockFactory;
    private readonly IWorkflowRepository _workflowRepo;

    public WorkflowExecutionService(
        IConnectionMultiplexer redis,
        IWorkflowRepository workflowRepo)
    {
        _lockFactory = RedLockFactory.Create(new List<RedLockMultiplexer>
        {
            new RedLockMultiplexer(redis)
        });
        _workflowRepo = workflowRepo;
    }

    public async Task ExecuteWorkflowAsync(string workflowId)
    {
        var lockKey = $"workflow:lock:{workflowId}";
        var expiry = TimeSpan.FromMinutes(5);

        // Try to acquire distributed lock
        await using var redLock = await _lockFactory.CreateLockAsync(
            resource: lockKey,
            expiryTime: expiry,
            waitTime: TimeSpan.FromSeconds(10),
            retryTime: TimeSpan.FromSeconds(1)
        );

        if (!redLock.IsAcquired)
        {
            throw new InvalidOperationException(
                $"Workflow {workflowId} is already executing");
        }

        try
        {
            // Execute workflow (lock held)
            Console.WriteLine($"Lock acquired for {workflowId}");

            var workflow = await _workflowRepo.GetWorkflowStateAsync(workflowId);
            // ... workflow execution logic ...

            await _workflowRepo.SaveWorkflowStateAsync(workflow);
        }
        finally
        {
            // Lock is automatically released on disposal
            Console.WriteLine($"Lock released for {workflowId}");
        }
    }
}
```

**Redis Commands (RedLock algorithm)**:
```bash
# Acquire lock (SET with NX and PX)
SET workflow:lock:workflow-123 "instance-abc" NX PX 300000

# Check lock owner
GET workflow:lock:workflow-123

# Release lock (Lua script for atomic check + delete)
# Only delete if lock is owned by current instance

# Manual lock release (for debugging)
DEL workflow:lock:workflow-123
```

---

## Performance Optimization

### Query Optimization

**1. RU Optimization (Cosmos DB)**:

```csharp
// ❌ BAD: SELECT * returns all fields
var query = "SELECT * FROM c WHERE c.workspace_id = @workspaceId";

// ✅ GOOD: Project only required fields (30-50% RU reduction)
var query = @"
    SELECT
        c.id,
        c.workflow_id,
        c.status,
        c.created_at
    FROM c
    WHERE c.workspace_id = @workspaceId";
```

**2. Avoid Cross-Partition Queries**:
```csharp
// ❌ BAD: Cross-partition query (10-100x slower)
var workflows = await container.GetItemQueryIterator<WorkflowState>(
    queryDefinition,
    requestOptions: new QueryRequestOptions
    {
        PartitionKey = null // Cross-partition
    }
).ReadNextAsync();

// ✅ GOOD: Single-partition query
var workflows = await container.GetItemQueryIterator<WorkflowState>(
    queryDefinition,
    requestOptions: new QueryRequestOptions
    {
        PartitionKey = new PartitionKey("workflow-123")
    }
).ReadNextAsync();
```

**3. Use Composite Indexes**:
```sql
-- Query MUST match composite index order
-- Composite index: (workspace_id ASC, status ASC, created_at DESC)

-- ✅ GOOD: Matches index order
SELECT * FROM c
WHERE c.workspace_id = 'ws-001'
  AND c.status = 'in_progress'
ORDER BY c.created_at DESC

-- ❌ BAD: Does not match index order (full scan)
SELECT * FROM c
WHERE c.status = 'in_progress'
  AND c.workspace_id = 'ws-001'
ORDER BY c.updated_at DESC
```

---

### Bulk Operations

**Batch Writes (Cosmos DB Transactional Batch)**:
```csharp
// Write multiple items in single transaction (same partition key)
var batch = container.CreateTransactionalBatch(
    new PartitionKey("2025-10-07")
);

// Add 100 metrics to batch
foreach (var metric in metrics)
{
    batch.CreateItem(metric);
}

// Execute batch (atomically)
var response = await batch.ExecuteAsync();

if (response.IsSuccessStatusCode)
{
    Console.WriteLine($"Batch RU cost: {response.RequestCharge}"); // ~5-10 RU per item
}
```

**Parallel Inserts (Azure AI Search)**:
```python
from azure.search.documents import SearchClient
import asyncio

async def batch_insert_memories(
    search_client: SearchClient,
    memories: list[dict],
    batch_size: int = 100
):
    # Split into batches
    batches = [memories[i:i+batch_size] for i in range(0, len(memories), batch_size)]

    # Upload batches in parallel
    tasks = [
        search_client.upload_documents(batch)
        for batch in batches
    ]

    results = await asyncio.gather(*tasks, return_exceptions=True)

    total_uploaded = sum(len(batch) for batch in batches)
    print(f"Uploaded {total_uploaded} documents")

    return results

# Usage
await batch_insert_memories(search_client, memories, batch_size=100)
```

---

### Connection Pooling

**.NET Cosmos DB Configuration**:
```csharp
var cosmosClientOptions = new CosmosClientOptions
{
    // Connection pool settings
    MaxRetryAttemptsOnRateLimitedRequests = 3,
    MaxRetryWaitTimeOnRateLimitedRequests = TimeSpan.FromSeconds(30),

    // HTTP client factory (connection pooling)
    HttpClientFactory = () => new HttpClient(new SocketsHttpHandler
    {
        PooledConnectionLifetime = TimeSpan.FromMinutes(5),
        PooledConnectionIdleTimeout = TimeSpan.FromMinutes(2),
        MaxConnectionsPerServer = 50
    }),

    // Consistency level
    ConsistencyLevel = ConsistencyLevel.Session,

    // Serialization
    Serializer = new CosmosSystemTextJsonSerializer(new JsonSerializerOptions
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    }),

    // Bulk execution (for batch operations)
    AllowBulkExecution = true
};

var cosmosClient = new CosmosClient(endpoint, key, cosmosClientOptions);
```

**.NET Redis Configuration**:
```csharp
var redisOptions = ConfigurationOptions.Parse(connectionString);

// Connection pool settings
redisOptions.ConnectRetry = 3;
redisOptions.ConnectTimeout = 5000;
redisOptions.SyncTimeout = 5000;
redisOptions.AbortOnConnectFail = false;
redisOptions.KeepAlive = 60;

// Connection multiplexing (single connection per endpoint)
var redis = ConnectionMultiplexer.Connect(redisOptions);

// Recommended: Register as singleton in DI
services.AddSingleton<IConnectionMultiplexer>(redis);
```

---

## Monitoring Queries

### Expensive Queries (Application Insights KQL)

**Top 10 Most Expensive Cosmos DB Queries**:
```kql
dependencies
| where type == "Azure DocumentDB"
| where timestamp > ago(1h)
| summarize
    Count = count(),
    AvgDuration = avg(duration),
    P95Duration = percentile(duration, 95),
    TotalRU = sum(customDimensions.RequestCharge)
  by operation_Name
| top 10 by TotalRU desc
| project
    Operation = operation_Name,
    Count,
    AvgDurationMs = AvgDuration,
    P95DurationMs = P95Duration,
    TotalRU
```

### Slow Query Detection

**Queries Exceeding 200ms**:
```kql
dependencies
| where type == "Azure DocumentDB"
| where timestamp > ago(1h)
| where duration > 200
| project
    timestamp,
    operation_Name,
    duration,
    resultCode,
    customDimensions.RequestCharge,
    customDimensions.PartitionKey
| order by duration desc
| take 50
```

### Cache Hit Ratio

**Redis Cache Performance**:
```kql
dependencies
| where type == "Redis"
| where timestamp > ago(1h)
| extend CacheHit = iif(success == true and duration < 10, 1, 0)
| summarize
    TotalRequests = count(),
    CacheHits = sum(CacheHit),
    AvgDuration = avg(duration),
    P95Duration = percentile(duration, 95)
| extend CacheHitRatio = (CacheHits * 100.0) / TotalRequests
| project
    TotalRequests,
    CacheHits,
    CacheHitRatio = strcat(round(CacheHitRatio, 2), "%"),
    AvgDurationMs = AvgDuration,
    P95DurationMs = P95Duration
```

---

## Best Practices

### Data Modeling

**1. Denormalization vs. Normalization**:
- **Embed** related data when it's small and frequently accessed together (agent execution results within workflow state)
- **Reference** when data is large or updated independently (agent configurations stored separately)

**Example**:
```json
{
  "workflow_id": "workflow-123",
  "agents": [
    {
      "agent_id": "arch-001",  // Reference to agent configuration
      "result": {              // Embedded execution result
        "output": {...},
        "token_usage": {...}
      }
    }
  ]
}
```

**2. Embedding vs. Referencing**:

| Pattern | Use When | Example |
|---------|----------|---------|
| **Embedding** | Data is small, read-heavy, 1:few relationship | Agent execution results in workflow |
| **Referencing** | Data is large, write-heavy, many:many relationship | Agent configurations (shared across workflows) |

---

### Consistency

**1. Eventual Consistency** (Cache-Aside Pattern):
- Cache may be stale for TTL duration
- Acceptable for non-critical reads (dashboard views)
- Invalidate cache on writes

**2. Strong Consistency** (Write-Through Pattern):
- Cache always reflects latest state
- Required for critical operations (workflow status, session tokens)
- Higher write latency

**Cosmos DB Consistency Levels**:
- **Session** (default): Strong consistency within a session, eventual across sessions
- **Strong**: Linearizability (highest latency)
- **Bounded Staleness**: Configurable staleness (time or operations)
- **Eventual**: Lowest latency, no ordering guarantees

---

### Error Handling

**.NET Retry Logic with Polly**:
```csharp
using Polly;
using Polly.Retry;

var retryPolicy = Policy
    .Handle<CosmosException>(ex => ex.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
    .Or<CosmosException>(ex => ex.StatusCode == System.Net.HttpStatusCode.ServiceUnavailable)
    .WaitAndRetryAsync(
        retryCount: 3,
        sleepDurationProvider: attempt => TimeSpan.FromSeconds(Math.Pow(2, attempt)),
        onRetry: (exception, timeSpan, retryCount, context) =>
        {
            Console.WriteLine($"Retry {retryCount} after {timeSpan.TotalSeconds}s due to {exception.Message}");
        }
    );

// Execute with retry
var workflow = await retryPolicy.ExecuteAsync(async () =>
    await _workflowRepo.GetWorkflowStateAsync(workflowId)
);
```

**Circuit Breaker Pattern**:
```csharp
var circuitBreakerPolicy = Policy
    .Handle<CosmosException>()
    .CircuitBreakerAsync(
        exceptionsAllowedBeforeBreaking: 5,
        durationOfBreak: TimeSpan.FromMinutes(1),
        onBreak: (exception, duration) =>
        {
            Console.WriteLine($"Circuit breaker opened for {duration.TotalSeconds}s");
        },
        onReset: () =>
        {
            Console.WriteLine("Circuit breaker reset");
        }
    );

// Combine retry + circuit breaker
var combinedPolicy = Policy.WrapAsync(retryPolicy, circuitBreakerPolicy);
```

---

## Code Examples

### TypeScript Examples (Using @azure/cosmos SDK)

```typescript
import { CosmosClient, Container } from "@azure/cosmos";

const client = new CosmosClient({
  endpoint: process.env.COSMOS_DB_ENDPOINT!,
  key: process.env.COSMOS_DB_KEY!,
});

const container: Container = client
  .database("project-ascension-db")
  .container("workflow-states");

// Point read
async function getWorkflow(workflowId: string): Promise<WorkflowState | null> {
  try {
    const { resource, requestCharge, diagnostics } = await container
      .item(workflowId, workflowId)
      .read<WorkflowState>();

    console.log(`RU charged: ${requestCharge}`);
    console.log(`Latency: ${diagnostics.clientSideRequestStatistics.requestLatencyInMs}ms`);

    return resource ?? null;
  } catch (error) {
    if (error.code === 404) {
      return null;
    }
    throw error;
  }
}

// Query with pagination
async function listWorkflows(
  workspaceId: string,
  status: string,
  limit: number = 100
): Promise<WorkflowState[]> {
  const query = {
    query: `
      SELECT * FROM c
      WHERE c.workspace_id = @workspaceId
        AND c.status = @status
      ORDER BY c.created_at DESC
      OFFSET 0 LIMIT @limit
    `,
    parameters: [
      { name: "@workspaceId", value: workspaceId },
      { name: "@status", value: status },
      { name: "@limit", value: limit },
    ],
  };

  const { resources, requestCharge } = await container.items.query(query).fetchAll();

  console.log(`RU charged: ${requestCharge}`);
  return resources;
}

// Update with optimistic concurrency
async function updateWorkflowStatus(
  workflowId: string,
  status: string
): Promise<WorkflowState> {
  const { resource: workflow, etag } = await container
    .item(workflowId, workflowId)
    .read<WorkflowState>();

  workflow!.status = status;
  workflow!.updated_at = new Date().toISOString();

  try {
    const { resource, requestCharge } = await container
      .item(workflowId, workflowId)
      .replace(workflow!, { accessCondition: { type: "IfMatch", condition: etag } });

    console.log(`Updated workflow, RU charged: ${requestCharge}`);
    return resource!;
  } catch (error) {
    if (error.code === 412) {
      console.log("Conflict detected, retrying...");
      return await updateWorkflowStatus(workflowId, status);
    }
    throw error;
  }
}
```

---

### Python Examples (Using azure-cosmos SDK)

```python
from azure.cosmos import CosmosClient, PartitionKey, exceptions
from typing import Optional, List
import os

# Initialize client
client = CosmosClient(
    url=os.environ["COSMOS_DB_ENDPOINT"],
    credential=os.environ["COSMOS_DB_KEY"]
)

database = client.get_database_client("project-ascension-db")
container = database.get_container_client("workflow-states")

# Point read
async def get_workflow(workflow_id: str) -> Optional[dict]:
    try:
        response = container.read_item(
            item=workflow_id,
            partition_key=workflow_id
        )

        print(f"RU charged: {response['_request_charge']}")
        return response
    except exceptions.CosmosResourceNotFoundError:
        return None

# Batch insert with retries
async def batch_insert_metrics(metrics: List[dict]) -> None:
    metrics_container = database.get_container_client("agent-metrics")

    # Group by partition key (metric_date)
    from collections import defaultdict
    batches = defaultdict(list)
    for metric in metrics:
        batches[metric["metric_date"]].append(metric)

    # Insert each batch
    for metric_date, batch in batches.items():
        for metric in batch:
            try:
                metrics_container.create_item(body=metric)
            except exceptions.CosmosHttpResponseError as e:
                if e.status_code == 429:  # Throttled
                    await asyncio.sleep(1)
                    metrics_container.create_item(body=metric)
                else:
                    raise

# Query with continuation token
async def list_workflows_paginated(
    workspace_id: str,
    status: str,
    page_size: int = 100
) -> List[dict]:
    query = """
        SELECT * FROM c
        WHERE c.workspace_id = @workspace_id
          AND c.status = @status
        ORDER BY c.created_at DESC
    """

    parameters = [
        {"name": "@workspace_id", "value": workspace_id},
        {"name": "@status", "value": status}
    ]

    items = []
    continuation_token = None

    while True:
        query_result = container.query_items(
            query=query,
            parameters=parameters,
            max_item_count=page_size,
            continuation_token=continuation_token,
            enable_cross_partition_query=True
        )

        # Fetch page
        page_items = [item for item in query_result.by_page(continuation_token)]
        if not page_items:
            break

        items.extend(page_items[0])

        # Get continuation token for next page
        continuation_token = query_result.continuation_token
        if not continuation_token:
            break

    return items
```

---

## Troubleshooting

### Common Issues

**1. Throttling (429 Errors)**:
- **Cause**: RU consumption exceeds provisioned throughput
- **Solution**:
  - Use projections (SELECT specific fields)
  - Implement retry logic with exponential backoff
  - Increase provisioned RU/s or switch to autoscale
  - Optimize queries (use partition keys, composite indexes)

**2. Hot Partitions**:
- **Cause**: Uneven distribution of requests across partitions
- **Solution**:
  - Choose high-cardinality partition keys
  - Avoid using timestamps as partition keys (all writes go to current timestamp partition)
  - Use synthetic partition keys (hash of multiple fields)

**3. Slow Queries**:
- **Cause**: Missing indexes, cross-partition queries, large result sets
- **Solution**:
  - Check index utilization (`PopulateIndexMetrics = true`)
  - Use composite indexes for multi-field queries
  - Use pagination (continuation tokens)
  - Filter by partition key when possible

**4. Cache Stampede**:
- **Cause**: Multiple requests fetch same data on cache miss
- **Solution**:
  - Use distributed lock (RedLock) for cache refresh
  - Implement probabilistic early expiration (refresh before TTL expires)

**5. Connection Pool Exhaustion**:
- **Cause**: Too many concurrent requests, connection leaks
- **Solution**:
  - Use connection pooling (StackExchange.Redis multiplexer)
  - Register Cosmos client as singleton (not transient)
  - Monitor connection count via Application Insights

---

## Summary

Agent Studio's query patterns prioritize **performance**, **scalability**, and **maintainability**:

- **Cosmos DB**: Point reads (< 10ms), composite indexes for complex queries, optimistic concurrency for conflict resolution
- **Redis**: Cache-aside pattern (> 95% hit ratio), session management with sliding expiration, distributed locks for idempotency
- **Azure AI Search**: Vector similarity search (< 100ms), hybrid search for text + embeddings, GDPR-compliant deletion

**Key Takeaways**:
1. Always use partition keys for Cosmos DB queries
2. Implement caching for read-heavy workloads (5-minute TTL)
3. Use bulk operations for batch inserts (100-200 docs/sec)
4. Monitor RU consumption and cache hit ratios
5. Implement retry logic with exponential backoff (429 errors)

---

## References

- [Azure Cosmos DB Query Performance](https://learn.microsoft.com/en-us/azure/cosmos-db/nosql/query-performance)
- [Azure AI Search Best Practices](https://learn.microsoft.com/en-us/azure/search/search-performance-tips)
- [StackExchange.Redis Best Practices](https://stackexchange.github.io/StackExchange.Redis/Basics)
- [Cosmos DB Indexing Policies](https://learn.microsoft.com/en-us/azure/cosmos-db/index-policy)
- [Redis Patterns Documentation](https://redis.io/docs/manual/patterns/)

---

**Last Updated**: 2025-10-08
**Version**: 2.0.0
**Document Word Count**: ~2,400 words
