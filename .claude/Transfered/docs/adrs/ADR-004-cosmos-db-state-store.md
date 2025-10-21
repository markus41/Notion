# ADR-004: Azure Cosmos DB as Primary State Store

## Status
Accepted

## Context

Agent Studio orchestrates complex AI workflows that require durable, scalable state management for:

- **Workflow Execution State:** Current status, completed tasks, pending tasks, context
- **Checkpoints:** Recovery points for fault tolerance and long-running workflows
- **Agent Conversations:** Thread history with messages, roles, and timestamps
- **Agent Metadata:** Capabilities, configurations, and performance metrics
- **Audit Logs:** Comprehensive execution history for compliance and debugging

### Requirements

1. **Global Distribution:** Low-latency access across geographic regions
2. **Elastic Scalability:** Handle variable workload from 10 to 10,000+ workflows
3. **High Availability:** 99.99% uptime SLA for business-critical workflows
4. **Flexible Schema:** Support evolving workflow patterns without migrations
5. **ACID Transactions:** Ensure data consistency for critical state updates
6. **Point-in-Time Recovery:** Restore workflows to previous checkpoint states
7. **Cost Efficiency:** Pay-per-use pricing for variable workloads
8. **Query Flexibility:** Support complex queries for analytics and monitoring
9. **Azure Integration:** Seamless integration with existing Azure infrastructure

### Constraints

- Must support optimistic concurrency for parallel workflow updates
- Must handle documents up to 2MB (large workflow contexts)
- Must provide sub-100ms latency for state read operations
- Must support time-to-live (TTL) for automatic checkpoint cleanup
- Must integrate with Application Insights for monitoring
- Must support managed identity authentication

## Decision

We will use **Azure Cosmos DB with SQL API** as the primary state store for Agent Studio, configured with:

- **Provisioning Model:** Serverless for dev/test; Provisioned throughput for production
- **Consistency Level:** Session (default) for read-your-writes guarantees
- **Partition Strategy:** By workflow ID to support parallel operations
- **Indexing Policy:** Optimized indexes on frequently queried fields
- **TTL Configuration:** Automatic expiration for checkpoints (30 days)

### Database Architecture

**Database:** `AgentStudio`

**Containers:**

1. **`workflows`** (Partition Key: `/id`)
   - Workflow execution state and metadata
   - Current status, progress, and results
   - Provisioned throughput: 400-10K RU/s (production)

2. **`checkpoints`** (Partition Key: `/workflowId`)
   - Recovery checkpoints with full state snapshots
   - TTL: 30 days (automatic cleanup)
   - Provisioned throughput: 400-2K RU/s

3. **`thread-message-store`** (Partition Key: `/threadId`)
   - Agent conversation history
   - Messages with roles, content, timestamps
   - Provisioned throughput: 400-1K RU/s

4. **`agent-entity-store`** (Partition Key: `/agentType`)
   - Agent capabilities and configurations
   - Performance metrics and usage statistics
   - Provisioned throughput: 400 RU/s (low throughput)

### Data Model Examples

**Workflow Document:**
```json
{
  "id": "wf_abc123",
  "name": "Customer Onboarding Workflow",
  "pattern": "Sequential",
  "status": "Running",
  "createdAt": "2025-10-14T10:00:00Z",
  "updatedAt": "2025-10-14T10:05:30Z",
  "createdBy": "user@example.com",
  "tasks": [
    {
      "id": "task_001",
      "agentType": "Architect",
      "status": "Completed",
      "startedAt": "2025-10-14T10:00:15Z",
      "completedAt": "2025-10-14T10:02:30Z",
      "durationMs": 135000,
      "result": {...},
      "tokenUsage": {"prompt": 1200, "completion": 800}
    },
    {
      "id": "task_002",
      "agentType": "Builder",
      "status": "Running",
      "startedAt": "2025-10-14T10:02:31Z"
    }
  ],
  "context": {
    "customerId": "cust_456",
    "region": "US-West",
    "sharedData": {...}
  },
  "metadata": {
    "totalTasks": 4,
    "completedTasks": 1,
    "failedTasks": 0,
    "estimatedDurationMs": 300000,
    "actualDurationMs": 135000,
    "totalCost": 0.024
  },
  "_etag": "\"abc123xyz\"",
  "ttl": -1
}
```

**Checkpoint Document:**
```json
{
  "id": "cp_xyz789",
  "workflowId": "wf_abc123",
  "type": "Automatic",
  "createdAt": "2025-10-14T10:02:30Z",
  "state": {
    "completedTasks": ["task_001"],
    "pendingTasks": ["task_002", "task_003", "task_004"],
    "context": {...},
    "metrics": {
      "durationMs": 135000,
      "tokenUsage": 2000,
      "cost": 0.012
    }
  },
  "metadata": {
    "tasksCompleted": 1,
    "totalTasks": 4,
    "progressPercentage": 25
  },
  "ttl": 2592000,
  "_etag": "\"def456uvw\""
}
```

**Thread Message Document:**
```json
{
  "id": "msg_abc001",
  "threadId": "thread_wf_abc123_task_001",
  "role": "assistant",
  "content": "Based on the requirements, I recommend a microservices architecture...",
  "timestamp": "2025-10-14T10:01:00Z",
  "metadata": {
    "model": "gpt-4",
    "tokenCount": 250,
    "temperature": 0.7
  },
  "_etag": "\"ghi789rst\""
}
```

**Agent Entity Document:**
```json
{
  "id": "agent_architect_001",
  "agentType": "Architect",
  "capabilities": ["system-design", "architecture-review", "technology-selection"],
  "configuration": {
    "model": "gpt-4",
    "temperature": 0.7,
    "maxTokens": 4000,
    "systemPrompt": "You are a senior software architect..."
  },
  "metrics": {
    "totalExecutions": 1250,
    "averageDurationMs": 8500,
    "averageTokenUsage": 2800,
    "successRate": 0.94
  },
  "createdAt": "2025-01-01T00:00:00Z",
  "updatedAt": "2025-10-14T10:00:00Z",
  "_etag": "\"jkl012mno\""
}
```

### Optimistic Concurrency Implementation

**Pattern:**
```csharp
public async Task<WorkflowState> UpdateWorkflowAsync(
    WorkflowState workflow,
    CancellationToken cancellationToken)
{
    try
    {
        var response = await _container.UpsertItemAsync(
            workflow,
            new PartitionKey(workflow.Id),
            new ItemRequestOptions
            {
                IfMatchEtag = workflow.ETag
            },
            cancellationToken);

        return response.Resource;
    }
    catch (CosmosException ex) when (ex.StatusCode == HttpStatusCode.PreconditionFailed)
    {
        // ETag mismatch - workflow was modified by another process
        _logger.LogWarning(
            "Optimistic concurrency conflict for workflow {WorkflowId}. Retrying...",
            workflow.Id);

        // Reload latest version and retry
        var latest = await GetWorkflowAsync(workflow.Id, cancellationToken);
        throw new ConcurrencyException("Workflow was modified by another process", latest);
    }
}
```

**Retry Logic:**
```csharp
var retryPolicy = Policy
    .Handle<ConcurrencyException>()
    .WaitAndRetryAsync(
        retryCount: 3,
        sleepDurationProvider: retryAttempt => TimeSpan.FromMilliseconds(100 * Math.Pow(2, retryAttempt)),
        onRetry: (exception, timespan, retryCount, context) =>
        {
            _logger.LogWarning(
                "Retry {RetryCount} after {Delay}ms due to concurrency conflict",
                retryCount, timespan.TotalMilliseconds);
        });

await retryPolicy.ExecuteAsync(async () =>
{
    var latest = await GetWorkflowAsync(workflowId, cancellationToken);
    latest.Status = WorkflowStatus.Completed;
    await UpdateWorkflowAsync(latest, cancellationToken);
});
```

### Indexing Strategy

**Workflows Container:**
```json
{
  "indexingMode": "consistent",
  "automatic": true,
  "includedPaths": [
    {
      "path": "/status/?",
      "indexes": [{"kind": "Range", "dataType": "String"}]
    },
    {
      "path": "/createdAt/?",
      "indexes": [{"kind": "Range", "dataType": "String"}]
    },
    {
      "path": "/createdBy/?",
      "indexes": [{"kind": "Range", "dataType": "String"}]
    },
    {
      "path": "/pattern/?",
      "indexes": [{"kind": "Range", "dataType": "String"}]
    }
  ],
  "excludedPaths": [
    {
      "path": "/context/*"
    },
    {
      "path": "/tasks/*/result/*"
    }
  ]
}
```

**Rationale:**
- Index frequently queried fields (status, createdAt, createdBy)
- Exclude large nested objects (context, results) to reduce RU consumption
- Range indexes support filtering and sorting
- Excluded paths reduce write costs by 30-40%

### Partitioning Strategy

**Workflows Container:**
- **Partition Key:** `/id` (workflow ID)
- **Rationale:** Each workflow is independent; enables parallel updates
- **Partition Size:** Typically < 10MB per workflow (well within 20GB limit)
- **Cross-Partition Queries:** Rare; most queries filter by workflow ID

**Checkpoints Container:**
- **Partition Key:** `/workflowId`
- **Rationale:** All checkpoints for a workflow co-located for efficient queries
- **Partition Size:** ~5-10 checkpoints per workflow = 50-100MB max
- **Query Pattern:** "Get all checkpoints for workflow X" (single partition)

**Thread-Message-Store:**
- **Partition Key:** `/threadId`
- **Rationale:** Conversation messages grouped by thread for sequential access
- **Partition Size:** Typical conversation = 10-100 messages = 1-5MB
- **Query Pattern:** "Get conversation history for thread X" (single partition)

### Cost Optimization

**Provisioning Models:**

**Serverless (Dev/Test):**
```bicep
resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  properties: {
    capabilities: [
      { name: 'EnableServerless' }
    ]
  }
}
```
- **Pricing:** $0.25/million RUs
- **Best For:** Variable, unpredictable workloads
- **Limitations:** Max 5K RU/s per container

**Provisioned Throughput (Production):**
```bicep
resource workflowsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  properties: {
    options: {
      throughput: 400
      autoscaleMaxThroughput: 4000
    }
  }
}
```
- **Pricing:** $0.008/hour per 100 RUs (standard)
- **Best For:** Predictable, steady workloads
- **Features:** Autoscale, reserved capacity discounts

**Cost Comparison (Monthly):**

| Scenario | Serverless | Provisioned 400 RU/s | Provisioned 4K RU/s |
|----------|------------|---------------------|---------------------|
| 100 workflows/day | ~$15 | $24 (fixed) | $240 (fixed) |
| 1,000 workflows/day | ~$80 | $24 (underprovisioned) | $240 (optimal) |
| 10,000 workflows/day | ~$600 | N/A (exceeds limits) | $240-2,400 (autoscale) |

**Optimization Strategies:**
1. **TTL for Checkpoints:** Automatic deletion after 30 days saves 60% storage costs
2. **Exclude Large Paths:** Reduce indexing costs by 30-40%
3. **Batch Operations:** Group reads/writes to reduce RU consumption
4. **Query Optimization:** Use partition key in queries to avoid cross-partition scans
5. **Reserved Capacity:** 20-60% discount for 1-3 year commitments

### High Availability and Disaster Recovery

**Multi-Region Configuration:**
```bicep
resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  properties: {
    locations: [
      { locationName: 'East US', failoverPriority: 0, isZoneRedundant: true }
      { locationName: 'West US', failoverPriority: 1, isZoneRedundant: true }
    ]
    enableAutomaticFailover: true
    enableMultipleWriteLocations: false
  }
}
```

**Backup Strategy:**
- **Continuous Backup:** Point-in-time restore within last 30 days
- **Interval:** Every 4 hours
- **Retention:** 30 days (configurable up to 365 days)
- **Restore Time:** < 1 hour for databases < 1TB

**Consistency Levels:**

| Level | Read Latency | Staleness | Use Case |
|-------|-------------|-----------|----------|
| **Strong** | High | None | Critical financial workflows |
| **Bounded Staleness** | Medium | Lag < K versions or T time | Multi-region with consistency |
| **Session** (default) | Low | Read-your-writes | Most workflows |
| **Consistent Prefix** | Low | Prefix guarantee | Analytics |
| **Eventual** | Lowest | Maximum staleness | Non-critical reads |

**Agent Studio Configuration:** Session consistency (optimal balance of performance and consistency)

### Monitoring and Diagnostics

**Key Metrics:**
- **RU Consumption:** Track per operation type (read, write, query)
- **Throttling Rate:** 429 errors per container
- **Latency:** P50, P95, P99 for read/write operations
- **Storage Size:** Total GB per container
- **Request Rate:** Operations per second

**Application Insights Integration:**
```csharp
services.AddSingleton<CosmosClient>((serviceProvider) =>
{
    var configuration = serviceProvider.GetRequiredService<IConfiguration>();
    var connectionString = configuration["CosmosDB:ConnectionString"];

    return new CosmosClient(connectionString, new CosmosClientOptions
    {
        ApplicationName = "AgentStudio",
        ApplicationRegion = Regions.EastUS,
        ConnectionMode = ConnectionMode.Direct,
        EnableContentResponseOnWrite = false,
        AllowBulkExecution = false,
        RequestTimeout = TimeSpan.FromSeconds(30),
        ApplicationPreferredRegions = new List<string> { Regions.EastUS, Regions.WestUS }
    });
});
```

**Custom Metrics:**
```csharp
private readonly Histogram<double> _cosmosLatency = _meter.CreateHistogram<double>(
    "cosmos.latency",
    unit: "ms",
    description: "Cosmos DB operation latency");

private readonly Counter<long> _cosmosRUs = _meter.CreateCounter<long>(
    "cosmos.request_units",
    description: "Request units consumed");

public async Task<WorkflowState> GetWorkflowAsync(string id)
{
    var sw = Stopwatch.StartNew();
    var response = await _container.ReadItemAsync<WorkflowState>(id, new PartitionKey(id));
    sw.Stop();

    _cosmosLatency.Record(sw.ElapsedMilliseconds, new KeyValuePair<string, object>("operation", "read"));
    _cosmosRUs.Add((long)response.RequestCharge, new KeyValuePair<string, object>("operation", "read"));

    return response.Resource;
}
```

## Consequences

### Positive

1. **Global Distribution**
   - Multi-region replication with < 10ms replication latency
   - Automatic failover ensures 99.999% availability (multi-region)
   - Supports 100+ Azure regions worldwide

2. **Elastic Scalability**
   - Autoscale from 400 to 1M RU/s without downtime
   - Unlimited storage (petabyte scale)
   - Partition key design supports massive parallelism

3. **Developer Productivity**
   - SQL-like query language (familiar to most developers)
   - Strong .NET SDK with async/await support
   - Change feed for reactive patterns
   - Local emulator for offline development

4. **Operational Excellence**
   - Managed service eliminates infrastructure management
   - Automatic indexing with policy customization
   - Built-in backup and point-in-time restore
   - Comprehensive monitoring via Azure Monitor

5. **Cost Efficiency**
   - Serverless pricing for variable workloads
   - TTL eliminates manual cleanup overhead
   - Reserved capacity discounts (20-60% savings)
   - No over-provisioning with autoscale

6. **Compliance and Security**
   - SOC 1, SOC 2, ISO 27001, HIPAA, FedRAMP compliance
   - Encryption at rest (AES-256) and in transit (TLS 1.3)
   - Managed identity for passwordless authentication
   - Private endpoints for network isolation

### Negative

1. **Cost**
   - More expensive than self-hosted databases at scale
   - Provisioned throughput billed hourly (even if unused)
   - Multi-region writes significantly increase costs (3-5x)
   - **Mitigation:** Use serverless for dev/test, autoscale for production, optimize query patterns

2. **Learning Curve**
   - Request Unit (RU) model requires understanding
   - Partition key design critical for performance
   - Query optimization differs from traditional SQL
   - **Mitigation:** Training, documentation, performance testing

3. **Query Limitations**
   - No JOIN support across containers
   - Cross-partition queries consume more RUs
   - Aggregate queries limited (no GROUP BY in some cases)
   - **Mitigation:** Denormalize data, optimize partition strategy

4. **Vendor Lock-in**
   - Cosmos DB specific APIs and features
   - Migration to other databases requires significant rework
   - **Mitigation:** Abstraction layer (repository pattern), document standard data model

5. **Throttling**
   - 429 errors when RU limit exceeded
   - Requires retry logic and exponential backoff
   - **Mitigation:** Autoscale, monitoring alerts, retry policies

## Alternatives Considered

### Azure SQL Database

**Pros:**
- Familiar relational model and SQL syntax
- Strong ACID guarantees with transactions
- Mature ecosystem and tooling

**Cons:**
- Schema rigidity requires migrations
- Vertical scaling limits (80 vCores max)
- Global distribution more complex (active geo-replication)
- Less cost-effective for variable workloads

**Decision:** Rejected; schema flexibility and global distribution more valuable than relational features.

### MongoDB Atlas (on Azure)

**Pros:**
- Document model fits workflow state
- Flexible schema with rich query capabilities
- Strong community and ecosystem

**Cons:**
- Additional vendor (not native Azure service)
- Separate billing and support
- Less integrated with Azure services (Managed Identity, Key Vault)
- No serverless pricing model

**Decision:** Rejected; prefer native Azure service for seamless integration.

### Azure Table Storage

**Pros:**
- Extremely low cost ($0.045/GB/month)
- Serverless pricing model
- Simple key-value operations

**Cons:**
- Limited query capabilities (no complex filters)
- No ACID transactions across partitions
- No change feed or automatic indexing
- Maximum entity size 1MB (too small for workflows)

**Decision:** Rejected; insufficient query flexibility and entity size limits.

### Azure PostgreSQL Flexible Server

**Pros:**
- Full relational database capabilities
- JSON/JSONB support for semi-structured data
- Familiar PostgreSQL ecosystem

**Cons:**
- Requires schema management and migrations
- Horizontal scaling requires sharding complexity
- Global distribution not native (requires custom replication)
- Fixed infrastructure costs

**Decision:** Rejected; prioritize schema flexibility and global distribution.

## Implementation Notes

### Phase 1: Core Infrastructure (Completed)
- Cosmos DB account with SQL API
- Four containers (workflows, checkpoints, threads, agents)
- Optimistic concurrency with ETag validation
- Application Insights integration
- Managed identity authentication

### Phase 2: Optimization (Next 2 months)
- Autoscale policies tuned to workload patterns
- Query optimization based on telemetry
- Indexing policy refinement
- TTL configuration for cost savings
- Cross-region read replicas for global users

### Phase 3: Advanced Features (3-6 months)
- Change feed for reactive workflows
- Multi-region writes for active-active scenarios
- Analytical store (Azure Synapse Link) for BI
- Conflict resolution policies for multi-region writes
- Advanced monitoring dashboards

## References

- [Azure Cosmos DB Documentation](https://docs.microsoft.com/azure/cosmos-db/)
- [Partitioning and Scaling Guide](https://docs.microsoft.com/azure/cosmos-db/partitioning-overview)
- [Request Units in Cosmos DB](https://docs.microsoft.com/azure/cosmos-db/request-units)
- [C4 Container Diagram](../architecture/c4-container.mmd)
- [Data Flow Documentation](../architecture/data-flows.md)

---

**Date:** 2025-10-14
**Authors:** Architecture Team, Database Team
**Reviewers:** Engineering Leadership, DevOps Team
**Status:** Accepted and Implemented

This decision establishes Cosmos DB as the foundation for state management designed to streamline global workflow orchestration with elastic scalability and enterprise-grade reliability.
