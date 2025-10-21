# Cosmos DB Container Schemas

## Overview

This document defines the schema for all Azure Cosmos DB containers used in the meta-agent platform. The database uses Session consistency level for optimal performance and strong consistency guarantees within a session.

## Database Configuration

- **Database Name**: `project-ascension-db`
- **Consistency Level**: Session
- **Backup Policy**: Continuous (7-day PITR)
- **Capacity Mode**: Serverless (Development), Provisioned (Production)
- **Multi-Region**: Single region (Development), Multi-region with automatic failover (Production)

## Container Design Principles

1. **Partition Key Selection**: Choose high-cardinality keys that distribute data evenly
2. **Denormalization**: Embed related data to minimize cross-partition queries
3. **Time-Series Optimization**: Use TTL for automatic cleanup of old data
4. **Indexing Strategy**: Custom indexing policies to optimize query performance
5. **Optimistic Concurrency**: Use `_etag` for conflict resolution

---

## 1. Workflow State Container

**Container Name**: `workflow-states`

**Purpose**: Store workflow execution state for checkpointing and resumption

**Partition Key**: `/workflow_id`

**TTL**: 2592000 seconds (30 days) - configurable via `ttl` field

**Indexing Policy**:
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

**Schema**:
```typescript
{
  "id": string,                    // Unique document ID (UUID v4)
  "workflow_id": string,           // Partition key - workflow instance ID
  "workspace_id": string,          // Multi-tenancy isolation
  "type": string,                  // "sequential" | "concurrent" | "group_chat" | "handoff" | "state_machine" | "saga"
  "name": string,                  // Human-readable workflow name
  "description": string,           // Workflow description
  "status": string,                // "pending" | "in_progress" | "completed" | "failed" | "paused" | "cancelled"
  "current_step": number,          // Current execution step (0-indexed)
  "total_steps": number,           // Total number of steps
  "agents": [                      // Agent execution details
    {
      "agent_id": string,          // Reference to agent configuration
      "agent_name": string,        // Agent display name
      "status": string,            // "pending" | "in_progress" | "completed" | "failed" | "skipped"
      "started_at": string,        // ISO 8601 timestamp
      "completed_at": string,      // ISO 8601 timestamp
      "duration_ms": number,       // Execution duration in milliseconds
      "result": {                  // Agent execution result
        "output": any,             // Agent output (structured or text)
        "tool_calls": [            // Tools invoked by agent
          {
            "tool_name": string,
            "tool_args": object,
            "tool_result": any,
            "duration_ms": number,
            "error": string | null
          }
        ],
        "token_usage": {
          "prompt_tokens": number,
          "completion_tokens": number,
          "total_tokens": number
        },
        "error": string | null
      }
    }
  ],
  "checkpoints": [                 // State checkpoints for resumption
    {
      "step": number,              // Step number
      "timestamp": string,         // ISO 8601 timestamp
      "state": object,             // Serialized workflow state
      "agent_context": object      // Agent-specific context
    }
  ],
  "metadata": {
    "created_by": string,          // User ID or system identifier
    "tags": string[],              // Workflow tags for categorization
    "priority": number,            // Execution priority (1-10)
    "retry_count": number,         // Number of retries attempted
    "max_retries": number,         // Maximum retries allowed
    "timeout_seconds": number,     // Workflow timeout
    "environment": string          // "development" | "staging" | "production"
  },
  "performance_metrics": {
    "total_duration_ms": number,
    "queue_time_ms": number,
    "execution_time_ms": number,
    "avg_step_duration_ms": number,
    "total_cost_usd": number       // Estimated cost (LLM API calls)
  },
  "error_details": {
    "error_type": string,
    "error_message": string,
    "stack_trace": string,
    "failed_step": number,
    "recovery_action": string      // "retry" | "skip" | "manual_intervention"
  } | null,
  "created_at": string,            // ISO 8601 timestamp
  "updated_at": string,            // ISO 8601 timestamp
  "completed_at": string | null,   // ISO 8601 timestamp
  "ttl": number,                   // Time to live in seconds (optional)
  "_etag": string                  // Optimistic concurrency control
}
```

**Example Document**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "workflow_id": "workflow-123",
  "workspace_id": "ws-tenant-001",
  "type": "sequential",
  "name": "API Development Workflow",
  "description": "Design, implement, and test REST API endpoints",
  "status": "in_progress",
  "current_step": 2,
  "total_steps": 4,
  "agents": [
    {
      "agent_id": "architect-001",
      "agent_name": "System Architect",
      "status": "completed",
      "started_at": "2025-10-07T10:00:00Z",
      "completed_at": "2025-10-07T10:05:30Z",
      "duration_ms": 330000,
      "result": {
        "output": {
          "api_design": {
            "endpoints": ["/api/users", "/api/products"],
            "auth_method": "JWT"
          }
        },
        "tool_calls": [],
        "token_usage": {
          "prompt_tokens": 1500,
          "completion_tokens": 800,
          "total_tokens": 2300
        },
        "error": null
      }
    },
    {
      "agent_id": "developer-002",
      "agent_name": "Backend Developer",
      "status": "in_progress",
      "started_at": "2025-10-07T10:05:35Z",
      "completed_at": null,
      "duration_ms": null,
      "result": null
    }
  ],
  "checkpoints": [
    {
      "step": 0,
      "timestamp": "2025-10-07T10:00:00Z",
      "state": {
        "initialized": true,
        "agents_loaded": true
      },
      "agent_context": {}
    },
    {
      "step": 1,
      "timestamp": "2025-10-07T10:05:30Z",
      "state": {
        "architect_output": "..."
      },
      "agent_context": {
        "architect-001": {
          "conversation_id": "conv-123"
        }
      }
    }
  ],
  "metadata": {
    "created_by": "user-456",
    "tags": ["api-development", "backend"],
    "priority": 5,
    "retry_count": 0,
    "max_retries": 3,
    "timeout_seconds": 3600,
    "environment": "production"
  },
  "performance_metrics": {
    "total_duration_ms": 0,
    "queue_time_ms": 1200,
    "execution_time_ms": 330000,
    "avg_step_duration_ms": 165000,
    "total_cost_usd": 0.046
  },
  "error_details": null,
  "created_at": "2025-10-07T09:59:58Z",
  "updated_at": "2025-10-07T10:05:35Z",
  "completed_at": null,
  "ttl": 2592000
}
```

---

## 2. Agent Memory Container

**Container Name**: `agent-memories`

**Purpose**: Store agent conversation history and episodic memory (non-vectorized)

**Partition Key**: `/agent_id`

**TTL**: 7776000 seconds (90 days) - configurable via `ttl` field

**Indexing Policy**:
```json
{
  "indexingMode": "consistent",
  "automatic": true,
  "includedPaths": [
    {"path": "/agent_id/?"},
    {"path": "/session_id/?"},
    {"path": "/workspace_id/?"},
    {"path": "/message_type/?"},
    {"path": "/timestamp/?"},
    {"path": "/relevance_score/?"}
  ],
  "excludedPaths": [
    {"path": "/_etag/?"},
    {"path": "/content/?"},
    {"path": "/metadata/tool_result/?"}
  ],
  "compositeIndexes": [
    [
      {"path": "/agent_id", "order": "ascending"},
      {"path": "/session_id", "order": "ascending"},
      {"path": "/timestamp", "order": "ascending"}
    ],
    [
      {"path": "/workspace_id", "order": "ascending"},
      {"path": "/agent_id", "order": "ascending"},
      {"path": "/relevance_score", "order": "descending"}
    ]
  ]
}
```

**Schema**:
```typescript
{
  "id": string,                    // Unique document ID (UUID v4)
  "agent_id": string,              // Partition key - agent identifier
  "session_id": string,            // Conversation session ID
  "workspace_id": string,          // Multi-tenancy isolation
  "content": string,               // Message content (full text)
  "message_type": string,          // "user" | "assistant" | "system" | "thought" | "tool_call" | "tool_result"
  "timestamp": string,             // ISO 8601 timestamp
  "relevance_score": number,       // Relevance score (0.0 - 1.0) for context retrieval
  "token_count": number,           // Token count for context window management
  "parent_message_id": string | null, // Reference to parent message (for threads)
  "metadata": {
    "tool_name": string | null,    // Tool name if message_type is tool_call/tool_result
    "tool_args": object | null,    // Tool arguments
    "tool_result": any | null,     // Tool execution result
    "reasoning_chain": string[],   // Chain-of-thought reasoning steps
    "tags": string[],              // Message tags
    "model": string,               // LLM model used
    "temperature": number,         // Model temperature
    "user_id": string | null       // User who initiated the message
  },
  "created_at": string,            // ISO 8601 timestamp
  "ttl": number,                   // Time to live in seconds (optional)
  "_etag": string                  // Optimistic concurrency control
}
```

**Example Document**:
```json
{
  "id": "msg-550e8400-e29b-41d4-a716-446655440002",
  "agent_id": "architect-001",
  "session_id": "session-abc123",
  "workspace_id": "ws-tenant-001",
  "content": "User requested a REST API design for user management with JWT authentication.",
  "message_type": "user",
  "timestamp": "2025-10-07T10:00:00Z",
  "relevance_score": 0.95,
  "token_count": 24,
  "parent_message_id": null,
  "metadata": {
    "tool_name": null,
    "tool_args": null,
    "tool_result": null,
    "reasoning_chain": [],
    "tags": ["api-design", "authentication"],
    "model": "gpt-4",
    "temperature": 0.7,
    "user_id": "user-456"
  },
  "created_at": "2025-10-07T10:00:00Z",
  "ttl": 7776000
}
```

---

## 3. Agent Performance Metrics Container

**Container Name**: `agent-metrics`

**Purpose**: Time-series metrics for agent performance monitoring and analytics

**Partition Key**: `/metric_date` (format: `YYYY-MM-DD`)

**TTL**: 15552000 seconds (180 days) - configurable via `ttl` field

**Indexing Policy**:
```json
{
  "indexingMode": "consistent",
  "automatic": true,
  "includedPaths": [
    {"path": "/metric_date/?"},
    {"path": "/agent_id/?"},
    {"path": "/workspace_id/?"},
    {"path": "/metric_type/?"},
    {"path": "/timestamp/?"}
  ],
  "excludedPaths": [
    {"path": "/_etag/?"}
  ],
  "compositeIndexes": [
    [
      {"path": "/metric_date", "order": "descending"},
      {"path": "/agent_id", "order": "ascending"},
      {"path": "/metric_type", "order": "ascending"}
    ]
  ]
}
```

**Schema**:
```typescript
{
  "id": string,                    // Unique document ID (UUID v4)
  "metric_date": string,           // Partition key - date in YYYY-MM-DD format
  "agent_id": string,              // Agent identifier
  "workspace_id": string,          // Multi-tenancy isolation
  "metric_type": string,           // "latency" | "token_usage" | "cost" | "success_rate" | "tool_usage"
  "timestamp": string,             // ISO 8601 timestamp
  "value": number,                 // Metric value
  "dimensions": {                  // Additional dimensions for filtering/aggregation
    "session_id": string,
    "workflow_id": string,
    "environment": string,
    "model": string,
    "tool_name": string | null
  },
  "created_at": string,            // ISO 8601 timestamp
  "ttl": number,                   // Time to live in seconds (optional)
  "_etag": string                  // Optimistic concurrency control
}
```

**Example Document**:
```json
{
  "id": "metric-550e8400-e29b-41d4-a716-446655440003",
  "metric_date": "2025-10-07",
  "agent_id": "architect-001",
  "workspace_id": "ws-tenant-001",
  "metric_type": "latency",
  "timestamp": "2025-10-07T10:05:30Z",
  "value": 330000,
  "dimensions": {
    "session_id": "session-abc123",
    "workflow_id": "workflow-123",
    "environment": "production",
    "model": "gpt-4",
    "tool_name": null
  },
  "created_at": "2025-10-07T10:05:30Z",
  "ttl": 15552000
}
```

---

## 4. Tool Invocation Logs Container

**Container Name**: `tool-invocations`

**Purpose**: Audit trail of all tool invocations for debugging and compliance

**Partition Key**: `/tool_date` (format: `YYYY-MM-DD`)

**TTL**: 7776000 seconds (90 days) - configurable via `ttl` field

**Indexing Policy**:
```json
{
  "indexingMode": "consistent",
  "automatic": true,
  "includedPaths": [
    {"path": "/tool_date/?"},
    {"path": "/tool_name/?"},
    {"path": "/agent_id/?"},
    {"path": "/workspace_id/?"},
    {"path": "/status/?"},
    {"path": "/timestamp/?"}
  ],
  "excludedPaths": [
    {"path": "/_etag/?"},
    {"path": "/input_args/*"},
    {"path": "/output_result/*"},
    {"path": "/error_details/*"}
  ],
  "compositeIndexes": [
    [
      {"path": "/tool_date", "order": "descending"},
      {"path": "/tool_name", "order": "ascending"},
      {"path": "/status", "order": "ascending"}
    ]
  ]
}
```

**Schema**:
```typescript
{
  "id": string,                    // Unique document ID (UUID v4)
  "tool_date": string,             // Partition key - date in YYYY-MM-DD format
  "tool_name": string,             // Tool identifier
  "agent_id": string,              // Agent that invoked the tool
  "workspace_id": string,          // Multi-tenancy isolation
  "session_id": string,            // Conversation session ID
  "workflow_id": string | null,    // Workflow ID if part of a workflow
  "timestamp": string,             // ISO 8601 timestamp
  "status": string,                // "success" | "error" | "timeout"
  "duration_ms": number,           // Execution duration in milliseconds
  "input_args": object,            // Tool input arguments
  "output_result": any,            // Tool output result
  "error_details": {
    "error_type": string,
    "error_message": string,
    "stack_trace": string
  } | null,
  "security_context": {
    "user_id": string | null,
    "ip_address": string,
    "user_agent": string
  },
  "created_at": string,            // ISO 8601 timestamp
  "ttl": number,                   // Time to live in seconds (optional)
  "_etag": string                  // Optimistic concurrency control
}
```

---

## 5. Existing Containers (from current infrastructure)

### 5.1 thread-message-store

**Partition Key**: `/threadId`

**Purpose**: Store conversation threads

**Schema**: (Existing schema - maintained for backward compatibility)

### 5.2 system-thread-message-store

**Partition Key**: `/threadId`

**Purpose**: Store system-level conversation threads

**Schema**: (Existing schema - maintained for backward compatibility)

### 5.3 agent-entity-store

**Partition Key**: `/agentId`

**Purpose**: Store agent entity configurations

**Schema**: (Existing schema - maintained for backward compatibility)

---

## Partitioning Strategy

### High-Cardinality Partitions

1. **workflow-states**: Partitioned by `workflow_id` (each workflow instance = unique partition)
   - **Rationale**: Isolates workflow state updates, prevents hot partitions
   - **Expected Cardinality**: 10,000+ active workflows
   - **Avg. Document Size**: 50 KB
   - **Avg. Documents per Partition**: 1-5 (workflow + checkpoints)

2. **agent-memories**: Partitioned by `agent_id`
   - **Rationale**: Isolates agent conversation history, enables fast session queries
   - **Expected Cardinality**: 1,000+ unique agents
   - **Avg. Document Size**: 5 KB
   - **Avg. Documents per Partition**: 100-10,000 (depends on session length)

### Time-Based Partitions

3. **agent-metrics**: Partitioned by `metric_date` (YYYY-MM-DD)
   - **Rationale**: Optimizes time-range queries, simplifies TTL management
   - **Expected Cardinality**: 365+ partitions per year
   - **Avg. Document Size**: 1 KB
   - **Avg. Documents per Partition**: 10,000-100,000 (depends on activity)

4. **tool-invocations**: Partitioned by `tool_date` (YYYY-MM-DD)
   - **Rationale**: Optimizes audit trail queries, simplifies compliance reporting
   - **Expected Cardinality**: 365+ partitions per year
   - **Avg. Document Size**: 10 KB
   - **Avg. Documents per Partition**: 1,000-50,000 (depends on tool usage)

---

## Performance Targets

### Query Performance (p95)

- **Workflow State Read** (single document): < 10ms
- **Workflow State Update** (single document): < 50ms
- **Agent Memory Query** (partition query, 100 docs): < 50ms
- **Agent Metrics Query** (cross-partition, time range): < 200ms
- **Tool Invocation Query** (partition query): < 100ms

### Throughput

- **Workflow State Writes**: 1,000 RU/s (serverless), 5,000 RU/s (provisioned)
- **Agent Memory Writes**: 2,000 RU/s (serverless), 10,000 RU/s (provisioned)
- **Metrics Writes**: 500 RU/s (batch inserts)
- **Tool Logs Writes**: 500 RU/s (batch inserts)

### Scalability

- **Concurrent Workflows**: 1,000+
- **Active Agents**: 10,000+
- **Daily Metrics Events**: 1,000,000+
- **Daily Tool Invocations**: 100,000+

---

## Data Retention Policies

| Container | Default TTL | GDPR Compliance | Backup Retention |
|-----------|-------------|-----------------|------------------|
| workflow-states | 30 days | Auto-delete on user request | 7 days (PITR) |
| agent-memories | 90 days | Auto-delete on user request | 7 days (PITR) |
| agent-metrics | 180 days | Anonymized aggregates | 7 days (PITR) |
| tool-invocations | 90 days | Auto-delete on user request | 7 days (PITR) |

**GDPR Compliance**: All containers support right to erasure (GDPR Article 17) via workspace-level deletion queries:
```sql
SELECT * FROM c WHERE c.workspace_id = @workspace_id
```

---

## Optimistic Concurrency Pattern

All containers use `_etag` for optimistic concurrency control:

```csharp
// .NET example
var requestOptions = new ItemRequestOptions
{
    IfMatchEtag = existingDocument.ETag
};

try
{
    await container.ReplaceItemAsync(updatedDocument, documentId, new PartitionKey(partitionKeyValue), requestOptions);
}
catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.PreconditionFailed)
{
    // Handle conflict: retry with latest version
}
```

---

## Backup and Disaster Recovery

### Continuous Backup (PITR)

- **Enabled**: Yes (Continuous7Days tier)
- **Recovery Scope**: Any point in time within the last 7 days
- **Recovery Granularity**: 1-second intervals
- **Recovery Process**: Azure Portal or Azure CLI

### Periodic Backup (Alternative for cost optimization)

- **Backup Interval**: 4 hours
- **Retention**: 8 hours
- **Use Case**: Development/staging environments

### Disaster Recovery Strategy

1. **Multi-Region Replication** (Production):
   - **Primary Region**: East US 2
   - **Secondary Region**: West US 2
   - **Automatic Failover**: Enabled
   - **RTO**: < 1 minute
   - **RPO**: < 5 seconds

2. **Database-Level Restore**:
   - **Restore from PITR**: Target any timestamp within 7 days
   - **Container-Level Restore**: Restore individual containers
   - **Account-Level Restore**: Full database restore

---

## Cost Optimization

### Serverless vs. Provisioned

| Scenario | Recommended Mode | Rationale |
|----------|------------------|-----------|
| Development | Serverless | Low traffic, unpredictable workloads |
| Staging | Serverless | Intermittent testing, cost-effective |
| Production (< 1M RU/s) | Serverless | Pay-per-request, auto-scaling |
| Production (> 1M RU/s) | Provisioned | Predictable costs, reserved capacity discounts |

### Indexing Optimization

- **Excluded Paths**: Large text fields (content, tool_result, stack_trace)
- **Composite Indexes**: Frequently queried filter combinations
- **Partial Indexes**: Not supported (use application-level filtering)

### TTL Management

- **Automatic Cleanup**: Cosmos DB automatically deletes expired documents
- **Cost Reduction**: Reduces storage costs and query latency
- **Granular Control**: Per-document TTL override

---

## Migration Strategy

### Phase 1: Schema Deployment
1. Create new containers via Bicep template
2. Configure indexing policies
3. Enable TTL on containers

### Phase 2: Data Migration
1. Migrate existing data to new containers (if applicable)
2. Validate data integrity
3. Update application connection strings

### Phase 3: Cutover
1. Update .NET/Python services to use new containers
2. Monitor performance metrics
3. Deprecate old containers (after validation period)

### Rollback Plan
1. Keep old containers active for 7 days
2. Dual-write to old and new containers during transition
3. Revert connection strings if issues detected
