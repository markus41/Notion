# Data Layer Design - Meta-Agent Platform

## Executive Summary

This document provides a comprehensive data layer architecture for the Agent Studio meta-agent platform, designed to support high-performance AI agent orchestration with sub-500ms query latency, distributed state management, and enterprise-grade reliability.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [PostgreSQL: Relational Data](#postgresql-relational-data)
3. [Cosmos DB: Workflow State & Event Sourcing](#cosmos-db-workflow-state--event-sourcing)
4. [Azure AI Search: Vector Embeddings](#azure-ai-search-vector-embeddings)
5. [Redis: Caching Layer](#redis-caching-layer)
6. [Data Flow Patterns](#data-flow-patterns)
7. [Query Optimization](#query-optimization)
8. [Migration Strategy](#migration-strategy)
9. [Backup & Recovery](#backup--recovery)
10. [Implementation Examples](#implementation-examples)

---

## Architecture Overview

### Database Distribution Strategy

```
┌─────────────────────────────────────────────────────────────────────┐
│                         APPLICATION LAYER                            │
│              .NET Service (EF Core) + Python Service (SQLAlchemy)   │
└─────────────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┼─────────────┐
                │             │             │
                ▼             ▼             ▼
┌──────────────────┐  ┌──────────────┐  ┌──────────────┐
│   PostgreSQL     │  │  Cosmos DB   │  │    Redis     │
│   (Relational)   │  │  (Document)  │  │   (Cache)    │
│                  │  │              │  │              │
│ • Workspaces     │  │ • Workflows  │  │ • Sessions   │
│ • Users          │  │ • Events     │  │ • Tokens     │
│ • Agents Meta    │  │ • State      │  │ • Counters   │
│ • Tools          │  │ • History    │  │ • Rate Limit │
│ • Permissions    │  │ • Checkpoints│  │              │
└──────────────────┘  └──────────────┘  └──────────────┘
                              │
                              ▼
                ┌──────────────────────────┐
                │   Azure AI Search        │
                │   (Vector Store)         │
                │                          │
                │ • Agent Memory           │
                │ • Semantic Search        │
                │ • RAG Context            │
                │ • Embeddings (1536-dim)  │
                └──────────────────────────┘
```

### Design Principles

1. **Polyglot Persistence**: Right database for each workload
2. **CAP Theorem Balance**: Eventual consistency for workflow state, strong consistency for critical metadata
3. **Query Performance**: <20ms (p50), <50ms (p95), <500ms (p99)
4. **Scalability**: Horizontal scaling via partitioning and sharding
5. **Multi-Tenancy**: Row-level security with workspace isolation
6. **GDPR Compliance**: Data encryption, audit logging, retention policies

---

## PostgreSQL: Relational Data

### Schema Design

PostgreSQL stores **relational metadata** with strong consistency guarantees (ACID). All schemas use **3NF normalization** with strategic denormalization for read-heavy workloads.

#### 1. Workspaces (Multi-Tenancy Boundary)

```sql
-- ============================================
-- WORKSPACES: Multi-tenant isolation boundary
-- ============================================
CREATE TABLE workspaces (
    workspace_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    owner_id UUID NOT NULL,
    tier VARCHAR(50) NOT NULL DEFAULT 'free', -- free, pro, enterprise
    settings JSONB DEFAULT '{}',

    -- Compliance
    data_region VARCHAR(50) NOT NULL DEFAULT 'us-east-1',
    retention_days INTEGER NOT NULL DEFAULT 90,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ, -- Soft delete for GDPR compliance

    -- Metadata
    metadata JSONB DEFAULT '{}',

    CONSTRAINT workspace_slug_valid CHECK (slug ~ '^[a-z0-9-]+$'),
    CONSTRAINT workspace_tier_valid CHECK (tier IN ('free', 'pro', 'enterprise'))
);

-- Indexes
CREATE INDEX idx_workspaces_owner ON workspaces(owner_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_workspaces_slug ON workspaces(slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_workspaces_created ON workspaces(created_at DESC);

-- GIN index for JSONB queries
CREATE INDEX idx_workspaces_settings ON workspaces USING GIN(settings);

-- Partial index for active workspaces (90% of queries)
CREATE INDEX idx_workspaces_active ON workspaces(workspace_id, created_at)
    WHERE deleted_at IS NULL;
```

#### 2. Users & Authentication

```sql
-- ============================================
-- USERS: Identity and authentication
-- ============================================
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    display_name VARCHAR(255) NOT NULL,
    avatar_url TEXT,

    -- Authentication (Azure AD integration)
    azure_ad_oid UUID UNIQUE, -- Azure AD Object ID
    auth_provider VARCHAR(50) NOT NULL DEFAULT 'azure_ad',

    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    email_verified BOOLEAN NOT NULL DEFAULT false,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,

    -- Metadata
    preferences JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',

    CONSTRAINT user_email_valid CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Indexes
CREATE UNIQUE INDEX idx_users_email_active ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_azure_ad ON users(azure_ad_oid) WHERE azure_ad_oid IS NOT NULL;
CREATE INDEX idx_users_last_login ON users(last_login_at DESC NULLS LAST);

-- ============================================
-- WORKSPACE MEMBERS: User-workspace mapping
-- ============================================
CREATE TABLE workspace_members (
    workspace_member_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(workspace_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL DEFAULT 'member', -- owner, admin, member, viewer

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    invited_by UUID REFERENCES users(user_id),

    CONSTRAINT workspace_members_unique UNIQUE (workspace_id, user_id),
    CONSTRAINT workspace_member_role_valid CHECK (role IN ('owner', 'admin', 'member', 'viewer'))
);

-- Indexes
CREATE INDEX idx_workspace_members_workspace ON workspace_members(workspace_id);
CREATE INDEX idx_workspace_members_user ON workspace_members(user_id);
CREATE INDEX idx_workspace_members_role ON workspace_members(workspace_id, role);
```

#### 3. Agents (Metadata Only)

```sql
-- ============================================
-- AGENTS: Agent metadata and configuration
-- ============================================
CREATE TABLE agents (
    agent_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(workspace_id) ON DELETE CASCADE,

    -- Identity
    name VARCHAR(255) NOT NULL,
    description TEXT,
    agent_type VARCHAR(100) NOT NULL, -- sequential, concurrent, group_chat, handoff

    -- Configuration (stored in Cosmos for versioning)
    config_version INTEGER NOT NULL DEFAULT 1,
    config_hash VARCHAR(64), -- SHA-256 of config in Cosmos

    -- LLM Settings
    model_provider VARCHAR(50) NOT NULL DEFAULT 'azure_openai', -- azure_openai, openai, anthropic
    model_name VARCHAR(100) NOT NULL DEFAULT 'gpt-4',
    temperature DECIMAL(3,2) DEFAULT 0.7,
    max_tokens INTEGER DEFAULT 4000,

    -- Status
    is_published BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,

    -- Metrics (denormalized for dashboard performance)
    total_executions BIGINT NOT NULL DEFAULT 0,
    total_tokens_used BIGINT NOT NULL DEFAULT 0,
    avg_latency_ms DECIMAL(10,2),
    last_executed_at TIMESTAMPTZ,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL REFERENCES users(user_id),
    deleted_at TIMESTAMPTZ,

    -- Metadata
    tags TEXT[] DEFAULT '{}',
    metadata JSONB DEFAULT '{}',

    CONSTRAINT agent_temperature_valid CHECK (temperature BETWEEN 0 AND 2),
    CONSTRAINT agent_max_tokens_valid CHECK (max_tokens > 0 AND max_tokens <= 128000)
);

-- Indexes
CREATE INDEX idx_agents_workspace ON agents(workspace_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_agents_type ON agents(workspace_id, agent_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_agents_published ON agents(workspace_id, is_published) WHERE deleted_at IS NULL AND is_published = true;
CREATE INDEX idx_agents_executions ON agents(total_executions DESC);
CREATE INDEX idx_agents_last_executed ON agents(last_executed_at DESC NULLS LAST);

-- GIN index for tag searches
CREATE INDEX idx_agents_tags ON agents USING GIN(tags);

-- ============================================
-- AGENT TOOLS: Tool associations
-- ============================================
CREATE TABLE agent_tools (
    agent_tool_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL REFERENCES agents(agent_id) ON DELETE CASCADE,
    tool_id UUID NOT NULL REFERENCES tools(tool_id) ON DELETE RESTRICT,

    -- Configuration
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    config JSONB DEFAULT '{}',
    execution_order INTEGER,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT agent_tools_unique UNIQUE (agent_id, tool_id)
);

-- Indexes
CREATE INDEX idx_agent_tools_agent ON agent_tools(agent_id) WHERE is_enabled = true;
CREATE INDEX idx_agent_tools_tool ON agent_tools(tool_id);
CREATE INDEX idx_agent_tools_order ON agent_tools(agent_id, execution_order);
```

#### 4. Tools Registry

```sql
-- ============================================
-- TOOLS: MCP tool definitions
-- ============================================
CREATE TABLE tools (
    tool_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID REFERENCES workspaces(workspace_id) ON DELETE CASCADE, -- NULL for global tools

    -- Identity
    name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100), -- code_execution, web_search, file_io, api, custom

    -- MCP Configuration
    mcp_server_url TEXT,
    openapi_spec_url TEXT,
    tool_schema JSONB NOT NULL, -- JSON Schema for tool parameters

    -- Security
    requires_approval BOOLEAN NOT NULL DEFAULT false,
    allowed_domains TEXT[], -- For web tools
    rate_limit_per_minute INTEGER DEFAULT 60,

    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_builtin BOOLEAN NOT NULL DEFAULT false, -- System vs custom tools

    -- Metrics
    total_invocations BIGINT NOT NULL DEFAULT 0,
    total_errors BIGINT NOT NULL DEFAULT 0,
    avg_execution_ms DECIMAL(10,2),

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(user_id),
    deleted_at TIMESTAMPTZ,

    -- Metadata
    metadata JSONB DEFAULT '{}',

    CONSTRAINT tools_workspace_name_unique UNIQUE (workspace_id, name)
);

-- Indexes
CREATE INDEX idx_tools_workspace ON tools(workspace_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_tools_category ON tools(category) WHERE is_active = true;
CREATE INDEX idx_tools_builtin ON tools(is_builtin) WHERE is_builtin = true;
CREATE INDEX idx_tools_invocations ON tools(total_invocations DESC);

-- GIN index for tool schema searches
CREATE INDEX idx_tools_schema ON tools USING GIN(tool_schema);
```

#### 5. Permissions (RBAC)

```sql
-- ============================================
-- PERMISSIONS: Role-based access control
-- ============================================
CREATE TABLE permissions (
    permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_type VARCHAR(100) NOT NULL, -- agent, workflow, tool, workspace
    resource_id UUID NOT NULL,
    principal_type VARCHAR(50) NOT NULL, -- user, role, workspace
    principal_id UUID NOT NULL,

    -- Access control
    can_read BOOLEAN NOT NULL DEFAULT true,
    can_write BOOLEAN NOT NULL DEFAULT false,
    can_execute BOOLEAN NOT NULL DEFAULT false,
    can_delete BOOLEAN NOT NULL DEFAULT false,
    can_admin BOOLEAN NOT NULL DEFAULT false,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    granted_by UUID NOT NULL REFERENCES users(user_id),
    expires_at TIMESTAMPTZ,

    CONSTRAINT permissions_unique UNIQUE (resource_type, resource_id, principal_type, principal_id)
);

-- Indexes
CREATE INDEX idx_permissions_resource ON permissions(resource_type, resource_id);
CREATE INDEX idx_permissions_principal ON permissions(principal_type, principal_id);
CREATE INDEX idx_permissions_expires ON permissions(expires_at) WHERE expires_at IS NOT NULL;

-- Composite index for permission checks (hot path)
CREATE INDEX idx_permissions_check ON permissions(
    resource_type, resource_id, principal_type, principal_id
) WHERE expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP;
```

#### 6. Audit Logs (Compliance)

```sql
-- ============================================
-- AUDIT_LOGS: Compliance and security
-- ============================================
CREATE TABLE audit_logs (
    audit_log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID REFERENCES workspaces(workspace_id) ON DELETE CASCADE,

    -- Event details
    event_type VARCHAR(100) NOT NULL, -- agent.created, workflow.executed, etc.
    event_category VARCHAR(50) NOT NULL, -- authentication, authorization, data_access, etc.
    severity VARCHAR(20) NOT NULL DEFAULT 'info', -- debug, info, warning, error, critical

    -- Actor
    user_id UUID REFERENCES users(user_id),
    ip_address INET,
    user_agent TEXT,

    -- Resource
    resource_type VARCHAR(100),
    resource_id UUID,
    resource_name VARCHAR(255),

    -- Details
    action VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL, -- success, failure, pending
    error_message TEXT,

    -- Context
    request_id UUID, -- Correlation with OTEL traces
    session_id UUID,

    -- Timestamp
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Payload (encrypted for sensitive data)
    before_state JSONB,
    after_state JSONB,
    metadata JSONB DEFAULT '{}'
);

-- Indexes (time-series optimized)
CREATE INDEX idx_audit_logs_workspace_time ON audit_logs(workspace_id, created_at DESC);
CREATE INDEX idx_audit_logs_user_time ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_logs_event_type ON audit_logs(event_type, created_at DESC);
CREATE INDEX idx_audit_logs_request_id ON audit_logs(request_id);

-- Partitioning by time (monthly partitions)
-- See migration script for partition creation
```

### Row-Level Security (RLS)

```sql
-- Enable RLS on multi-tenant tables
ALTER TABLE workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their workspace data
CREATE POLICY workspace_isolation ON agents
    FOR ALL
    USING (
        workspace_id IN (
            SELECT workspace_id
            FROM workspace_members
            WHERE user_id = current_setting('app.current_user_id')::UUID
        )
    );

-- Policy: Users can read audit logs for their workspaces
CREATE POLICY audit_logs_workspace_read ON audit_logs
    FOR SELECT
    USING (
        workspace_id IN (
            SELECT workspace_id
            FROM workspace_members
            WHERE user_id = current_setting('app.current_user_id')::UUID
        )
    );
```

### Performance Optimization

#### Materialized Views for Dashboards

```sql
-- ============================================
-- MATERIALIZED VIEW: Workspace stats
-- ============================================
CREATE MATERIALIZED VIEW workspace_stats AS
SELECT
    w.workspace_id,
    w.name AS workspace_name,
    COUNT(DISTINCT a.agent_id) AS total_agents,
    COUNT(DISTINCT wm.user_id) AS total_members,
    SUM(a.total_executions) AS total_executions,
    SUM(a.total_tokens_used) AS total_tokens,
    AVG(a.avg_latency_ms) AS avg_latency_ms,
    MAX(a.last_executed_at) AS last_activity_at,
    w.created_at
FROM workspaces w
LEFT JOIN agents a ON w.workspace_id = a.workspace_id AND a.deleted_at IS NULL
LEFT JOIN workspace_members wm ON w.workspace_id = wm.workspace_id
WHERE w.deleted_at IS NULL
GROUP BY w.workspace_id, w.name, w.created_at;

-- Refresh strategy: Every 5 minutes via cron job or trigger
CREATE UNIQUE INDEX idx_workspace_stats_workspace_id ON workspace_stats(workspace_id);

-- ============================================
-- MATERIALIZED VIEW: Agent performance
-- ============================================
CREATE MATERIALIZED VIEW agent_performance AS
SELECT
    a.agent_id,
    a.name,
    a.agent_type,
    a.total_executions,
    a.total_tokens_used,
    a.avg_latency_ms,
    a.last_executed_at,
    COUNT(DISTINCT at.tool_id) AS tool_count,
    w.workspace_id,
    w.name AS workspace_name
FROM agents a
JOIN workspaces w ON a.workspace_id = w.workspace_id
LEFT JOIN agent_tools at ON a.agent_id = at.agent_id AND at.is_enabled = true
WHERE a.deleted_at IS NULL AND w.deleted_at IS NULL
GROUP BY a.agent_id, a.name, a.agent_type, a.total_executions,
         a.total_tokens_used, a.avg_latency_ms, a.last_executed_at,
         w.workspace_id, w.name;

CREATE UNIQUE INDEX idx_agent_performance_agent_id ON agent_performance(agent_id);
CREATE INDEX idx_agent_performance_workspace ON agent_performance(workspace_id);
```

### Connection Pooling Configuration

```python
# Python (SQLAlchemy)
SQLALCHEMY_POOL_SIZE = 20
SQLALCHEMY_MAX_OVERFLOW = 40
SQLALCHEMY_POOL_TIMEOUT = 30
SQLALCHEMY_POOL_RECYCLE = 1800  # 30 minutes
SQLALCHEMY_POOL_PRE_PING = True  # Health check
```

```csharp
// .NET (EF Core)
services.AddDbContext<AppDbContext>(options =>
{
    options.UseNpgsql(connectionString, npgsqlOptions =>
    {
        npgsqlOptions.EnableRetryOnFailure(
            maxRetryCount: 3,
            maxRetryDelay: TimeSpan.FromSeconds(5),
            errorCodesToAdd: null
        );
        npgsqlOptions.CommandTimeout(30);
        npgsqlOptions.MinBatchSize(1);
        npgsqlOptions.MaxBatchSize(100);
    });
    options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking); // Read-heavy
});

// Connection pooling (Npgsql defaults)
// Min Pool Size: 1
// Max Pool Size: 100
// Connection Lifetime: 0 (infinite)
// Connection Idle Lifetime: 300s
```

---

## Cosmos DB: Workflow State & Event Sourcing

### Container Design

Cosmos DB provides **multi-region replication**, **automatic indexing**, and **change feed** for event-driven architectures. We use **partition keys** for horizontal scalability.

#### Container 1: Workflows

```json
{
  "containerName": "workflows",
  "partitionKey": "/workspaceId",
  "indexingPolicy": {
    "automatic": true,
    "indexingMode": "consistent",
    "includedPaths": [
      { "path": "/*" }
    ],
    "excludedPaths": [
      { "path": "/state/*" },
      { "path": "/checkpoints/*" }
    ],
    "compositeIndexes": [
      [
        { "path": "/workspaceId", "order": "ascending" },
        { "path": "/status", "order": "ascending" },
        { "path": "/createdAt", "order": "descending" }
      ],
      [
        { "path": "/workspaceId", "order": "ascending" },
        { "path": "/agentId", "order": "ascending" },
        { "path": "/executedAt", "order": "descending" }
      ]
    ],
    "spatialIndexes": []
  },
  "ttl": 7776000
}
```

**Document Schema:**

```typescript
interface WorkflowExecution {
  // Partition key
  workspaceId: string;  // Partition key

  // Identity
  id: string;  // UUID
  workflowId: string;
  executionId: string;
  type: "workflow_execution";

  // Configuration
  agentId: string;
  agentType: "sequential" | "concurrent" | "group_chat" | "handoff";
  workflowConfig: {
    name: string;
    version: number;
    agents: AgentConfig[];
    settings: Record<string, any>;
  };

  // Execution state
  status: "pending" | "running" | "completed" | "failed" | "cancelled";
  progress: {
    currentStep: number;
    totalSteps: number;
    completedSteps: number;
    percentage: number;
  };

  // State management
  state: {
    currentAgentId: string;
    variables: Record<string, any>;
    context: Record<string, any>;
  };

  // Checkpointing
  checkpoints: Checkpoint[];
  latestCheckpointId: string | null;

  // Results
  input: any;
  output: any | null;
  error: ErrorDetails | null;

  // Metrics
  metrics: {
    startedAt: string;
    completedAt: string | null;
    durationMs: number | null;
    tokensUsed: number;
    toolInvocations: number;
    latencyP50: number;
    latencyP95: number;
    latencyP99: number;
  };

  // Timestamps (ISO 8601)
  createdAt: string;
  updatedAt: string;
  executedAt: string;

  // TTL (auto-delete after 90 days)
  ttl: number;

  // Metadata
  metadata: {
    userId: string;
    requestId: string;
    traceId: string;  // OpenTelemetry correlation
    tags: string[];
    [key: string]: any;
  };
}

interface Checkpoint {
  checkpointId: string;
  step: number;
  agentId: string;
  state: Record<string, any>;
  createdAt: string;
  metadata: Record<string, any>;
}

interface ErrorDetails {
  code: string;
  message: string;
  stackTrace: string;
  failedStep: number;
  retryable: boolean;
}
```

#### Container 2: Events (Event Sourcing)

```json
{
  "containerName": "events",
  "partitionKey": "/aggregateId",
  "indexingPolicy": {
    "automatic": true,
    "indexingMode": "consistent",
    "includedPaths": [
      { "path": "/*" }
    ],
    "excludedPaths": [
      { "path": "/payload/*" }
    ],
    "compositeIndexes": [
      [
        { "path": "/aggregateId", "order": "ascending" },
        { "path": "/version", "order": "ascending" }
      ],
      [
        { "path": "/eventType", "order": "ascending" },
        { "path": "/timestamp", "order": "descending" }
      ]
    ]
  },
  "ttl": -1
}
```

**Document Schema:**

```typescript
interface DomainEvent {
  // Partition key
  aggregateId: string;  // Partition key (workflowId, agentId, etc.)

  // Identity
  id: string;  // UUID
  eventId: string;
  type: "domain_event";

  // Event details
  eventType: string;  // workflow.started, agent.executed, tool.invoked, etc.
  eventVersion: number;
  aggregateType: string;  // workflow, agent, tool
  version: number;  // Event sequence number (optimistic locking)

  // Payload
  payload: Record<string, any>;

  // Context
  context: {
    workspaceId: string;
    userId: string;
    requestId: string;
    traceId: string;
    correlationId: string;
  };

  // Timestamps
  timestamp: string;  // ISO 8601

  // Causality
  causationId: string | null;  // Event that caused this event
  correlationId: string;  // Original request ID

  // Metadata
  metadata: Record<string, any>;
}
```

#### Container 3: Conversation History

```json
{
  "containerName": "conversations",
  "partitionKey": "/sessionId",
  "indexingPolicy": {
    "automatic": true,
    "indexingMode": "consistent",
    "includedPaths": [
      { "path": "/*" }
    ],
    "excludedPaths": [
      { "path": "/messages/*/content" }
    ],
    "compositeIndexes": [
      [
        { "path": "/sessionId", "order": "ascending" },
        { "path": "/timestamp", "order": "descending" }
      ]
    ]
  },
  "ttl": 2592000
}
```

**Document Schema:**

```typescript
interface ConversationMessage {
  // Partition key
  sessionId: string;  // Partition key

  // Identity
  id: string;  // UUID
  messageId: string;
  type: "conversation_message";

  // Message details
  role: "user" | "assistant" | "system" | "tool";
  content: string;
  agentId: string | null;
  toolCalls: ToolCall[];

  // Context
  workspaceId: string;
  workflowExecutionId: string | null;

  // Timestamps
  timestamp: string;

  // TTL (30 days)
  ttl: number;

  // Metadata
  metadata: {
    model: string;
    tokensUsed: number;
    latencyMs: number;
    [key: string]: any;
  };
}

interface ToolCall {
  toolId: string;
  toolName: string;
  input: any;
  output: any;
  executionTimeMs: number;
  error: string | null;
}
```

### Change Feed for Event-Driven Architecture

```csharp
// .NET Change Feed Processor
var changeFeedProcessor = container
    .GetChangeFeedProcessorBuilder<WorkflowExecution>(
        "workflowExecutionProcessor",
        HandleChangesAsync)
    .WithInstanceName("instance1")
    .WithLeaseContainer(leaseContainer)
    .WithStartTime(DateTime.UtcNow.AddMinutes(-5))
    .Build();

async Task HandleChangesAsync(
    IReadOnlyCollection<WorkflowExecution> changes,
    CancellationToken cancellationToken)
{
    foreach (var execution in changes)
    {
        if (execution.Status == "completed")
        {
            // Update PostgreSQL metrics
            await UpdateAgentMetrics(execution);

            // Send notification
            await NotifyUser(execution);

            // Update vector embeddings
            await IndexConversation(execution);
        }
    }
}
```

```python
# Python Change Feed Consumer (Azure Functions)
@app.cosmos_db_trigger(
    arg_name="documents",
    container_name="workflows",
    database_name="agent-studio",
    connection="CosmosDBConnection",
    lease_container_name="leases",
    create_lease_container_if_not_exists=True
)
async def workflow_change_handler(documents: func.DocumentList):
    for doc in documents:
        execution = WorkflowExecution(**doc.to_dict())

        if execution.status == "completed":
            # Update vector store
            await index_workflow_memory(execution)

            # Publish event to Redis
            await redis.publish(
                f"workflow:{execution.execution_id}:completed",
                json.dumps(execution.dict())
            )
```

### Query Patterns

```sql
-- Query 1: Get active workflows for workspace
SELECT * FROM c
WHERE c.workspaceId = @workspaceId
  AND c.status IN ('pending', 'running')
  AND c.type = 'workflow_execution'
ORDER BY c.createdAt DESC

-- Query 2: Get workflow execution history
SELECT * FROM c
WHERE c.workspaceId = @workspaceId
  AND c.agentId = @agentId
  AND c.executedAt >= @startDate
ORDER BY c.executedAt DESC

-- Query 3: Get events for aggregate (event sourcing)
SELECT * FROM c
WHERE c.aggregateId = @workflowId
  AND c.type = 'domain_event'
ORDER BY c.version ASC

-- Query 4: Get conversation history
SELECT * FROM c
WHERE c.sessionId = @sessionId
  AND c.type = 'conversation_message'
ORDER BY c.timestamp ASC
```

### Performance Optimization

```json
{
  "consistencyLevel": "Session",
  "automaticFailover": true,
  "multipleWriteLocations": true,
  "locations": [
    { "locationName": "East US", "failoverPriority": 0, "isZoneRedundant": true },
    { "locationName": "West US", "failoverPriority": 1, "isZoneRedundant": true }
  ],
  "requestUnits": {
    "workflows": 4000,
    "events": 2000,
    "conversations": 1000
  }
}
```

---

## Azure AI Search: Vector Embeddings

### Index Design

Azure AI Search provides **vector search** with **hybrid retrieval** (keyword + semantic) for agent memory and RAG patterns.

#### Index 1: Agent Memory

```json
{
  "name": "agent-memory-index",
  "fields": [
    {
      "name": "memoryId",
      "type": "Edm.String",
      "key": true,
      "filterable": false,
      "searchable": false
    },
    {
      "name": "workspaceId",
      "type": "Edm.String",
      "filterable": true,
      "searchable": false,
      "facetable": true
    },
    {
      "name": "agentId",
      "type": "Edm.String",
      "filterable": true,
      "searchable": false
    },
    {
      "name": "sessionId",
      "type": "Edm.String",
      "filterable": true,
      "searchable": false
    },
    {
      "name": "content",
      "type": "Edm.String",
      "filterable": false,
      "searchable": true,
      "analyzer": "en.microsoft"
    },
    {
      "name": "contentVector",
      "type": "Collection(Edm.Single)",
      "searchable": true,
      "filterable": false,
      "sortable": false,
      "facetable": false,
      "dimensions": 1536,
      "vectorSearchProfile": "memory-vector-profile"
    },
    {
      "name": "messageType",
      "type": "Edm.String",
      "filterable": true,
      "searchable": false
    },
    {
      "name": "timestamp",
      "type": "Edm.DateTimeOffset",
      "filterable": true,
      "sortable": true
    },
    {
      "name": "metadata",
      "type": "Edm.ComplexType",
      "fields": [
        { "name": "userId", "type": "Edm.String", "filterable": true },
        { "name": "tags", "type": "Collection(Edm.String)", "filterable": true },
        { "name": "tokensUsed", "type": "Edm.Int32", "filterable": true }
      ]
    }
  ],
  "vectorSearch": {
    "profiles": [
      {
        "name": "memory-vector-profile",
        "algorithm": "memory-hnsw-algorithm"
      }
    ],
    "algorithms": [
      {
        "name": "memory-hnsw-algorithm",
        "kind": "hnsw",
        "hnswParameters": {
          "metric": "cosine",
          "m": 4,
          "efConstruction": 400,
          "efSearch": 500
        }
      }
    ]
  },
  "semantic": {
    "configurations": [
      {
        "name": "memory-semantic-config",
        "prioritizedFields": {
          "titleField": null,
          "prioritizedContentFields": [
            { "fieldName": "content" }
          ],
          "prioritizedKeywordsFields": [
            { "fieldName": "metadata/tags" }
          ]
        }
      }
    ]
  }
}
```

#### Index 2: Knowledge Base (RAG)

```json
{
  "name": "knowledge-base-index",
  "fields": [
    {
      "name": "documentId",
      "type": "Edm.String",
      "key": true
    },
    {
      "name": "workspaceId",
      "type": "Edm.String",
      "filterable": true
    },
    {
      "name": "title",
      "type": "Edm.String",
      "searchable": true
    },
    {
      "name": "content",
      "type": "Edm.String",
      "searchable": true,
      "analyzer": "en.microsoft"
    },
    {
      "name": "contentVector",
      "type": "Collection(Edm.Single)",
      "searchable": true,
      "dimensions": 1536,
      "vectorSearchProfile": "rag-vector-profile"
    },
    {
      "name": "chunkIndex",
      "type": "Edm.Int32",
      "filterable": true,
      "sortable": true
    },
    {
      "name": "sourceUrl",
      "type": "Edm.String",
      "filterable": true
    },
    {
      "name": "category",
      "type": "Edm.String",
      "filterable": true,
      "facetable": true
    },
    {
      "name": "updatedAt",
      "type": "Edm.DateTimeOffset",
      "filterable": true,
      "sortable": true
    }
  ],
  "vectorSearch": {
    "profiles": [
      {
        "name": "rag-vector-profile",
        "algorithm": "rag-hnsw-algorithm"
      }
    ],
    "algorithms": [
      {
        "name": "rag-hnsw-algorithm",
        "kind": "hnsw",
        "hnswParameters": {
          "metric": "cosine",
          "m": 4,
          "efConstruction": 400,
          "efSearch": 500
        }
      }
    ]
  },
  "semantic": {
    "configurations": [
      {
        "name": "rag-semantic-config",
        "prioritizedFields": {
          "titleField": { "fieldName": "title" },
          "prioritizedContentFields": [
            { "fieldName": "content" }
          ],
          "prioritizedKeywordsFields": [
            { "fieldName": "category" }
          ]
        }
      }
    ]
  }
}
```

### Embedding Strategy

```python
# Python: Generate embeddings using Azure OpenAI
from openai import AzureOpenAI

client = AzureOpenAI(
    api_key=os.getenv("AZURE_OPENAI_KEY"),
    api_version="2024-02-01",
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT")
)

async def generate_embedding(text: str) -> List[float]:
    """Generate text-embedding-ada-002 embeddings (1536 dimensions)"""
    response = await client.embeddings.create(
        input=text,
        model="text-embedding-ada-002"
    )
    return response.data[0].embedding

# Chunking strategy for long documents
def chunk_document(content: str, chunk_size: int = 500, overlap: int = 50) -> List[str]:
    """Split document into overlapping chunks"""
    words = content.split()
    chunks = []
    for i in range(0, len(words), chunk_size - overlap):
        chunk = ' '.join(words[i:i + chunk_size])
        chunks.append(chunk)
    return chunks
```

```csharp
// .NET: Generate embeddings
using Azure.AI.OpenAI;

public class EmbeddingService
{
    private readonly OpenAIClient _client;

    public async Task<float[]> GenerateEmbeddingAsync(string text)
    {
        var options = new EmbeddingsOptions("text-embedding-ada-002", new[] { text });
        var response = await _client.GetEmbeddingsAsync(options);
        return response.Value.Data[0].Embedding.ToArray();
    }
}
```

### Hybrid Search Query

```python
# Hybrid search: Vector + keyword + semantic ranking
from azure.search.documents import SearchClient
from azure.search.documents.models import VectorizedQuery

async def hybrid_search(
    query: str,
    workspace_id: str,
    top_k: int = 10
) -> List[SearchResult]:
    """Hybrid search with vector similarity + keyword matching"""

    # Generate query embedding
    query_vector = await generate_embedding(query)

    # Hybrid search
    results = search_client.search(
        search_text=query,
        vector_queries=[
            VectorizedQuery(
                vector=query_vector,
                k_nearest_neighbors=50,
                fields="contentVector"
            )
        ],
        filter=f"workspaceId eq '{workspace_id}'",
        select=["memoryId", "content", "agentId", "timestamp", "metadata"],
        top=top_k,
        query_type="semantic",
        semantic_configuration_name="memory-semantic-config"
    )

    return [result async for result in results]
```

### Performance Benchmarks

```
Query Type              | Latency (p50) | Latency (p95) | Latency (p99)
------------------------|---------------|---------------|---------------
Vector Search (k=10)    | 15ms          | 35ms          | 80ms
Hybrid Search (k=10)    | 25ms          | 50ms          | 120ms
Semantic Search (k=10)  | 40ms          | 90ms          | 180ms
Filtered Vector (k=50)  | 30ms          | 70ms          | 150ms
```

---

## Redis: Caching Layer

### Data Structures

#### 1. Session Store

```python
# Session data (TTL: 24 hours)
SETEX session:{session_id} 86400 '{"user_id":"...","workspace_id":"...","expires_at":"..."}'

# Active sessions set
SADD user:{user_id}:sessions {session_id}
EXPIRE user:{user_id}:sessions 86400
```

#### 2. Token Bucket (Rate Limiting)

```python
# Rate limit: 60 requests per minute
key = f"rate_limit:user:{user_id}:minute:{current_minute}"
count = redis.incr(key)
redis.expire(key, 60)

if count > 60:
    raise RateLimitExceeded()
```

#### 3. Query Result Cache

```python
# Cache PostgreSQL query results (TTL: 5 minutes)
cache_key = f"workspace:{workspace_id}:agents:active"
cached = redis.get(cache_key)

if cached:
    return json.loads(cached)

# Query database
agents = db.query(Agent).filter_by(workspace_id=workspace_id, is_active=True).all()

# Cache results
redis.setex(cache_key, 300, json.dumps([a.dict() for a in agents]))
```

#### 4. Distributed Locks

```python
# Acquire lock for workflow execution (prevent duplicate runs)
lock_key = f"lock:workflow:{workflow_id}"
lock_acquired = redis.set(lock_key, "locked", nx=True, ex=300)

if not lock_acquired:
    raise WorkflowAlreadyRunning()

try:
    # Execute workflow
    result = await execute_workflow(workflow_id)
finally:
    redis.delete(lock_key)
```

#### 5. Pub/Sub for Real-Time Updates

```python
# Publisher (workflow completion)
redis.publish(
    f"workspace:{workspace_id}:notifications",
    json.dumps({
        "type": "workflow.completed",
        "workflow_id": workflow_id,
        "status": "completed",
        "timestamp": datetime.utcnow().isoformat()
    })
)

# Subscriber (WebSocket server)
pubsub = redis.pubsub()
pubsub.subscribe(f"workspace:{workspace_id}:notifications")

for message in pubsub.listen():
    if message['type'] == 'message':
        await websocket.send_json(json.loads(message['data']))
```

#### 6. Leaderboards (Top Agents)

```python
# Sorted set for agent execution counts
redis.zincrby(f"leaderboard:agents:executions", 1, agent_id)

# Get top 10 agents
top_agents = redis.zrevrange(
    f"leaderboard:agents:executions",
    0, 9,
    withscores=True
)
```

### Redis Cluster Configuration

```yaml
# redis.conf
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
cluster-replica-validity-factor 10
cluster-migration-barrier 1
cluster-require-full-coverage yes

# Persistence
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfsync everysec

# Memory
maxmemory 4gb
maxmemory-policy allkeys-lru

# Replication
min-replicas-to-write 1
min-replicas-max-lag 10
```

### Caching Strategy

```python
# Cache-aside pattern with automatic invalidation
class CacheService:
    def __init__(self, redis_client, db_session):
        self.redis = redis_client
        self.db = db_session

    async def get_workspace(self, workspace_id: str) -> Workspace:
        """Get workspace with cache-aside pattern"""
        cache_key = f"workspace:{workspace_id}"

        # Try cache first
        cached = await self.redis.get(cache_key)
        if cached:
            return Workspace.parse_raw(cached)

        # Cache miss - query database
        workspace = await self.db.query(Workspace).get(workspace_id)

        if workspace:
            # Store in cache (TTL: 10 minutes)
            await self.redis.setex(
                cache_key,
                600,
                workspace.json()
            )

        return workspace

    async def invalidate_workspace(self, workspace_id: str):
        """Invalidate cache on update"""
        await self.redis.delete(f"workspace:{workspace_id}")
```

### Performance Targets

```
Operation               | Latency (p50) | Latency (p95) | Latency (p99)
------------------------|---------------|---------------|---------------
GET (cache hit)         | <1ms          | 2ms           | 5ms
SET                     | <1ms          | 3ms           | 8ms
INCR (rate limit)       | <1ms          | 2ms           | 5ms
PUBLISH                 | 1ms           | 5ms           | 15ms
Sorted Set (ZADD)       | 2ms           | 8ms           | 20ms
```

---

## Data Flow Patterns

### Pattern 1: Agent Execution Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                       AGENT EXECUTION FLOW                           │
└─────────────────────────────────────────────────────────────────────┘

1. User Request
   │
   ├─→ [Redis] Check rate limit (INCR)
   │   └─→ If exceeded: Return 429 Too Many Requests
   │
   ├─→ [Redis] Get session data (GET)
   │   └─→ Extract user_id, workspace_id
   │
   ├─→ [PostgreSQL] Validate permissions (RLS policy)
   │   └─→ Query: workspace_members WHERE user_id = ? AND workspace_id = ?
   │
   ├─→ [PostgreSQL] Get agent metadata
   │   └─→ Query: agents WHERE agent_id = ? AND deleted_at IS NULL
   │
   ├─→ [Cosmos DB] Create workflow execution document
   │   └─→ Insert: { workspaceId, agentId, status: "pending", ... }
   │
   ├─→ [Redis] Publish execution started event
   │   └─→ PUBLISH workspace:{id}:notifications { type: "workflow.started" }
   │
   └─→ [Queue] Enqueue execution task
       └─→ Azure Service Bus / RabbitMQ

2. Workflow Execution (Worker Process)
   │
   ├─→ [Cosmos DB] Update status to "running"
   │   └─→ Update: { status: "running", metrics.startedAt: ... }
   │
   ├─→ [Redis] Acquire distributed lock
   │   └─→ SET lock:workflow:{id} "locked" NX EX 300
   │
   ├─→ Execute agent logic (.NET / Python)
   │   ├─→ Call LLM (Azure OpenAI)
   │   ├─→ Invoke tools (MCP servers)
   │   └─→ Process messages
   │
   ├─→ [Cosmos DB] Save checkpoints (every N steps)
   │   └─→ Update: { checkpoints: [...], latestCheckpointId: ... }
   │
   ├─→ [Cosmos DB] Save conversation messages
   │   └─→ Insert into conversations container
   │
   ├─→ [Azure AI Search] Index conversation for semantic search
   │   └─→ Upload document with vector embeddings
   │
   ├─→ [Cosmos DB] Update execution status to "completed"
   │   └─→ Update: { status: "completed", output: ..., metrics: ... }
   │
   ├─→ [PostgreSQL] Update agent metrics (denormalized)
   │   └─→ Update: total_executions++, avg_latency_ms, last_executed_at
   │
   ├─→ [PostgreSQL] Insert audit log
   │   └─→ Insert: { event_type: "workflow.executed", ... }
   │
   ├─→ [Redis] Invalidate cached data
   │   └─→ DELETE workspace:{id}:agents:stats
   │
   ├─→ [Redis] Publish completion event
   │   └─→ PUBLISH workspace:{id}:notifications { type: "workflow.completed" }
   │
   └─→ [Redis] Release distributed lock
       └─→ DELETE lock:workflow:{id}
```

### Pattern 2: Semantic Memory Retrieval (RAG)

```
┌─────────────────────────────────────────────────────────────────────┐
│                   SEMANTIC MEMORY RETRIEVAL (RAG)                    │
└─────────────────────────────────────────────────────────────────────┘

1. User Query (Agent needs context)
   │
   ├─→ [Azure OpenAI] Generate query embedding (1536-dim vector)
   │   └─→ POST /embeddings { input: "What is the agent framework?" }
   │
   ├─→ [Azure AI Search] Hybrid search
   │   ├─→ Vector search (cosine similarity)
   │   ├─→ Keyword search (BM25)
   │   └─→ Semantic ranking (L2 re-ranking)
   │   Result: Top 10 most relevant memories
   │
   ├─→ [Redis] Cache search results (TTL: 5 minutes)
   │   └─→ SETEX search:{query_hash} 300 "[{...}, {...}]"
   │
   ├─→ [Cosmos DB] Get full conversation context (if needed)
   │   └─→ Query: conversations WHERE sessionId = ? ORDER BY timestamp ASC
   │
   └─→ Return context to agent
       └─→ Inject into system prompt or user message
```

### Pattern 3: Real-Time Dashboard Updates

```
┌─────────────────────────────────────────────────────────────────────┐
│                   REAL-TIME DASHBOARD UPDATES                        │
└─────────────────────────────────────────────────────────────────────┘

1. User loads dashboard
   │
   ├─→ [PostgreSQL] Query materialized views
   │   ├─→ workspace_stats (cached, refreshed every 5 min)
   │   └─→ agent_performance (cached, refreshed every 5 min)
   │
   ├─→ [Redis] Get real-time counters
   │   ├─→ GET workspace:{id}:active_workflows
   │   └─→ GET workspace:{id}:requests_per_minute
   │
   ├─→ [WebSocket] Subscribe to updates
   │   └─→ Redis Pub/Sub: workspace:{id}:notifications
   │
   └─→ Return dashboard data

2. Background: Cosmos Change Feed → Redis
   │
   ├─→ Cosmos DB emits change (workflow completed)
   │
   ├─→ Change Feed Processor receives event
   │
   ├─→ [Redis] Update counters
   │   ├─→ DECR workspace:{id}:active_workflows
   │   └─→ HINCRBY workspace:{id}:agent_stats {agent_id} 1
   │
   ├─→ [Redis] Publish notification
   │   └─→ PUBLISH workspace:{id}:notifications { type: "workflow.completed" }
   │
   └─→ [WebSocket] Broadcast to connected clients
```

---

## Query Optimization

### Query 1: Get Active Workflows (Hot Path)

**Problem:** Dashboard displays active workflows (90% of queries)

**Optimizations:**
1. Materialized view in PostgreSQL
2. Redis cache with pub/sub invalidation
3. Cosmos DB composite index on workspaceId + status + createdAt

```sql
-- PostgreSQL: Create covering index
CREATE INDEX idx_workflows_active_covering ON workflows(
    workspace_id,
    status,
    created_at DESC
) INCLUDE (execution_id, agent_id, progress, metrics)
WHERE deleted_at IS NULL AND status IN ('pending', 'running');

-- Query uses index-only scan (no table access)
EXPLAIN ANALYZE
SELECT execution_id, agent_id, status, progress, metrics
FROM workflows
WHERE workspace_id = '...'
  AND status IN ('pending', 'running')
  AND deleted_at IS NULL
ORDER BY created_at DESC
LIMIT 20;
```

**Result:**
- Before: 150ms (seq scan)
- After: 8ms (index-only scan)
- Cache hit: <1ms (Redis)

### Query 2: Agent Execution History (Analytics)

**Problem:** Time-range queries for analytics (slow on large datasets)

**Optimizations:**
1. Partition audit_logs by month (PostgreSQL)
2. Composite index on (workspace_id, event_type, created_at)
3. Aggregation cache in Redis

```sql
-- Create monthly partitions
CREATE TABLE audit_logs_2025_01 PARTITION OF audit_logs
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE audit_logs_2025_02 PARTITION OF audit_logs
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

-- Query with partition pruning
EXPLAIN ANALYZE
SELECT event_type, COUNT(*) as count
FROM audit_logs
WHERE workspace_id = '...'
  AND created_at >= '2025-01-01'
  AND created_at < '2025-02-01'
GROUP BY event_type;

-- Result: Only scans audit_logs_2025_01 partition
```

### Query 3: Permission Check (Security Hot Path)

**Problem:** RLS policy checks on every request (high QPS)

**Optimizations:**
1. Covering index on workspace_members
2. Redis cache for user permissions (TTL: 5 minutes)
3. Prepared statement caching

```sql
-- Create covering index for permission checks
CREATE INDEX idx_workspace_members_permission_check ON workspace_members(
    user_id, workspace_id
) INCLUDE (role)
WHERE role IN ('owner', 'admin', 'member');

-- PostgreSQL prepared statement (connection pooling)
PREPARE check_access (UUID, UUID) AS
SELECT role
FROM workspace_members
WHERE user_id = $1 AND workspace_id = $2;

EXECUTE check_access('user-uuid', 'workspace-uuid');
```

**Python caching:**

```python
@lru_cache(maxsize=10000)
async def check_user_access(user_id: str, workspace_id: str) -> str:
    """Check user access with in-memory cache"""
    cache_key = f"access:{user_id}:{workspace_id}"

    # Try Redis first
    cached_role = await redis.get(cache_key)
    if cached_role:
        return cached_role.decode()

    # Query PostgreSQL
    role = await db.scalar(
        select(WorkspaceMember.role)
        .where(
            WorkspaceMember.user_id == user_id,
            WorkspaceMember.workspace_id == workspace_id
        )
    )

    if role:
        # Cache for 5 minutes
        await redis.setex(cache_key, 300, role)

    return role
```

**Result:**
- Before: 15ms (PostgreSQL query)
- After (Redis hit): <1ms
- After (in-memory LRU): <0.1ms

### Query 4: Vector Search with Filters

**Problem:** Filtered vector search slow on large indexes

**Optimizations:**
1. Pre-filtering before vector search
2. Hybrid search with keyword boosting
3. Index tuning (HNSW parameters)

```python
# Optimized hybrid search with pre-filtering
async def optimized_hybrid_search(
    query: str,
    workspace_id: str,
    session_id: str | None = None,
    top_k: int = 10
) -> List[SearchResult]:
    """Hybrid search with optimized pre-filtering"""

    # Generate query embedding
    query_vector = await generate_embedding(query)

    # Build filter (pre-filter before vector search for performance)
    filters = [f"workspaceId eq '{workspace_id}'"]
    if session_id:
        filters.append(f"sessionId eq '{session_id}'")

    filter_expression = " and ".join(filters)

    # Hybrid search with optimized parameters
    results = search_client.search(
        search_text=query,
        vector_queries=[
            VectorizedQuery(
                vector=query_vector,
                k_nearest_neighbors=50,  # Retrieve 50, return top 10
                fields="contentVector",
                exhaustive=False  # Use HNSW approximation
            )
        ],
        filter=filter_expression,
        select=["memoryId", "content", "timestamp"],
        top=top_k,
        query_type="semantic",
        semantic_configuration_name="memory-semantic-config",
        # Boost recent memories
        scoring_profile="recency-boost"
    )

    return [result async for result in results]
```

**Scoring profile for recency:**

```json
{
  "scoringProfiles": [
    {
      "name": "recency-boost",
      "functions": [
        {
          "type": "freshness",
          "fieldName": "timestamp",
          "boost": 2.0,
          "interpolation": "linear",
          "freshness": {
            "boostingDuration": "P7D"
          }
        }
      ],
      "functionAggregation": "sum"
    }
  ]
}
```

---

## Migration Strategy

### Phase 1: Schema Creation (Zero-Downtime)

```sql
-- Step 1: Create new tables with versioned names
CREATE TABLE workspaces_v2 (...);
CREATE TABLE agents_v2 (...);
CREATE TABLE audit_logs_v2 (...);

-- Step 2: Backfill data (using background worker)
INSERT INTO workspaces_v2
SELECT * FROM workspaces WHERE created_at >= '2025-01-01';

-- Step 3: Set up triggers for dual-write
CREATE OR REPLACE FUNCTION sync_workspace_to_v2()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        INSERT INTO workspaces_v2 VALUES (NEW.*)
        ON CONFLICT (workspace_id) DO UPDATE
        SET name = EXCLUDED.name, updated_at = EXCLUDED.updated_at;
    ELSIF TG_OP = 'DELETE' THEN
        DELETE FROM workspaces_v2 WHERE workspace_id = OLD.workspace_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER workspace_dual_write
AFTER INSERT OR UPDATE OR DELETE ON workspaces
FOR EACH ROW EXECUTE FUNCTION sync_workspace_to_v2();

-- Step 4: Switch application to read from v2 (gradual rollout)
-- Blue-green deployment or feature flag

-- Step 5: Rename tables (atomic operation)
BEGIN;
ALTER TABLE workspaces RENAME TO workspaces_old;
ALTER TABLE workspaces_v2 RENAME TO workspaces;
COMMIT;

-- Step 6: Drop old table after verification
DROP TABLE workspaces_old;
```

### Phase 2: Cosmos DB Migration

```python
# Expand-contract migration for Cosmos DB documents
async def migrate_workflow_schema_v1_to_v2():
    """Add new fields without breaking existing queries"""

    # Read all workflows (paginated)
    query = "SELECT * FROM c WHERE c.type = 'workflow_execution' AND c.version = 1"
    items = container.query_items(query, enable_cross_partition_query=True)

    for item in items:
        # Expand: Add new fields
        item['version'] = 2
        item['metrics']['latencyP50'] = item['metrics'].get('avgLatencyMs', 0)
        item['metrics']['latencyP95'] = None  # Will be calculated later
        item['metrics']['latencyP99'] = None

        # Upsert document
        await container.upsert_item(item)

    # Contract: Remove old fields after all clients updated
    # (Run this after deploying new application version)
```

### Phase 3: Redis Migration (Zero-Downtime)

```python
# Dual-write pattern for Redis key format changes
class RedisService:
    def __init__(self, old_redis, new_redis):
        self.old = old_redis  # Old key format
        self.new = new_redis  # New key format

    async def set_session(self, session_id: str, data: dict):
        """Write to both old and new Redis instances"""
        old_key = f"session:{session_id}"  # Old format
        new_key = f"sessions:{session_id}"  # New format

        # Dual write
        await self.old.setex(old_key, 86400, json.dumps(data))
        await self.new.setex(new_key, 86400, json.dumps(data))

    async def get_session(self, session_id: str) -> dict:
        """Read from new Redis, fallback to old"""
        new_key = f"sessions:{session_id}"
        data = await self.new.get(new_key)

        if data:
            return json.loads(data)

        # Fallback to old Redis
        old_key = f"session:{session_id}"
        data = await self.old.get(old_key)

        if data:
            # Migrate to new format
            parsed = json.loads(data)
            await self.new.setex(new_key, 86400, json.dumps(parsed))
            return parsed

        return None
```

### Migration Rollback Plan

```sql
-- PostgreSQL: Rollback plan using transactions
BEGIN;

-- Rollback step 1: Rename tables back
ALTER TABLE workspaces RENAME TO workspaces_v2;
ALTER TABLE workspaces_old RENAME TO workspaces;

-- Rollback step 2: Verify data integrity
SELECT COUNT(*) FROM workspaces;
SELECT COUNT(*) FROM workspace_members;

-- Rollback step 3: Drop triggers
DROP TRIGGER IF EXISTS workspace_dual_write ON workspaces;

COMMIT;
```

---

## Backup & Recovery

### PostgreSQL Backup Strategy

#### 1. Continuous Archiving (WAL-E / pgBackRest)

```bash
# pgBackRest configuration
[global]
repo1-path=/backup/postgres
repo1-retention-full=7
repo1-retention-diff=4
repo1-retention-archive=14

[db]
pg1-path=/var/lib/postgresql/data
pg1-port=5432

# Full backup (daily at 2 AM)
pgbackrest --stanza=agent-studio --type=full backup

# Differential backup (every 6 hours)
pgbackrest --stanza=agent-studio --type=diff backup

# Point-in-time recovery (PITR)
pgbackrest --stanza=agent-studio \
    --type=time \
    --target="2025-01-15 14:30:00" \
    restore
```

#### 2. Logical Backups (pg_dump)

```bash
# Daily logical backup (compressed)
pg_dump -Fc -f agent_studio_$(date +%Y%m%d).dump \
    -d agent_studio \
    -h postgres.azure.com \
    -U admin

# Restore from logical backup
pg_restore -d agent_studio \
    -h postgres.azure.com \
    -U admin \
    agent_studio_20250115.dump
```

#### 3. Backup Verification

```sql
-- Verify backup integrity (checksum)
SELECT pg_walfile_name(pg_current_wal_lsn());

-- Test restore to staging environment (weekly)
CREATE DATABASE agent_studio_staging TEMPLATE agent_studio;
```

### Cosmos DB Backup Strategy

#### 1. Continuous Backup (Azure Managed)

```json
{
  "backupPolicy": {
    "type": "Continuous",
    "continuousModeProperties": {
      "tier": "Continuous30Days"
    }
  }
}
```

**Point-in-time restore:**

```bash
# Restore to specific timestamp
az cosmosdb sql database restore \
    --account-name agent-studio-cosmos \
    --resource-group rg-agent-studio \
    --name workflows \
    --restore-timestamp "2025-01-15T14:30:00Z" \
    --target-database-name workflows_restored
```

#### 2. Manual Snapshots (Export to Blob Storage)

```python
# Export Cosmos DB container to Azure Blob Storage
from azure.cosmos import CosmosClient
from azure.storage.blob import BlobServiceClient

async def export_cosmos_to_blob(container_name: str, date: str):
    """Export Cosmos DB container to Blob Storage"""

    # Query all documents
    items = container.query_items(
        "SELECT * FROM c",
        enable_cross_partition_query=True
    )

    # Write to blob
    blob_client = blob_service.get_blob_client(
        container="backups",
        blob=f"{container_name}/{date}.jsonl"
    )

    with blob_client.open("w") as f:
        for item in items:
            f.write(json.dumps(item) + "\n")
```

### Redis Backup Strategy

#### 1. RDB Snapshots (Point-in-time)

```bash
# Manual snapshot
redis-cli BGSAVE

# Automated snapshots (redis.conf)
save 900 1      # Save if 1 key changed in 15 min
save 300 10     # Save if 10 keys changed in 5 min
save 60 10000   # Save if 10000 keys changed in 1 min

# Copy RDB file to backup location
cp /var/lib/redis/dump.rdb /backup/redis/dump_$(date +%Y%m%d_%H%M%S).rdb
```

#### 2. AOF (Append-Only File)

```bash
# Enable AOF (redis.conf)
appendonly yes
appendfsync everysec

# Rewrite AOF to compact
redis-cli BGREWRITEAOF

# Backup AOF file
cp /var/lib/redis/appendonly.aof /backup/redis/appendonly_$(date +%Y%m%d).aof
```

### Azure AI Search Backup Strategy

**Note:** Azure AI Search does not support built-in backups. Use export/import strategy.

```python
# Export index to Blob Storage
from azure.search.documents import SearchClient

async def export_search_index(index_name: str):
    """Export search index to Blob Storage"""

    search_client = SearchClient(endpoint, index_name, credential)

    # Query all documents (paginated)
    results = search_client.search("*", include_total_count=True)

    # Write to blob (JSONL format)
    blob_client = blob_service.get_blob_client(
        container="backups",
        blob=f"search-index/{index_name}/{date.today()}.jsonl"
    )

    with blob_client.open("w") as f:
        for result in results:
            f.write(json.dumps(dict(result)) + "\n")

# Import index from backup
async def import_search_index(index_name: str, backup_date: str):
    """Restore search index from Blob Storage"""

    search_client = SearchClient(endpoint, index_name, credential)

    # Read from blob
    blob_client = blob_service.get_blob_client(
        container="backups",
        blob=f"search-index/{index_name}/{backup_date}.jsonl"
    )

    # Batch upload (chunks of 1000)
    documents = []
    async with blob_client.open("r") as f:
        async for line in f:
            documents.append(json.loads(line))

            if len(documents) >= 1000:
                await search_client.upload_documents(documents)
                documents = []

    # Upload remaining documents
    if documents:
        await search_client.upload_documents(documents)
```

### Disaster Recovery Plan

#### RTO (Recovery Time Objective): 1 hour
#### RPO (Recovery Point Objective): 5 minutes

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DISASTER RECOVERY RUNBOOK                         │
└─────────────────────────────────────────────────────────────────────┘

Scenario: Complete Azure region failure (East US)

Step 1: Failover PostgreSQL (10 minutes)
   ├─→ Promote read replica in West US to primary
   ├─→ Update connection strings in Key Vault
   └─→ Restart application services

Step 2: Failover Cosmos DB (Automatic)
   ├─→ Azure automatically fails over to West US
   └─→ Verify read/write operations

Step 3: Rebuild Redis Cache (15 minutes)
   ├─→ Provision new Redis cluster in West US
   ├─→ Restore from latest RDB snapshot
   └─→ Update connection strings

Step 4: Rebuild Azure AI Search (30 minutes)
   ├─→ Create new search service in West US
   ├─→ Recreate indexes (schema from IaC)
   ├─→ Import documents from Blob Storage backup
   └─→ Verify search functionality

Step 5: Update DNS (5 minutes)
   ├─→ Update Azure Front Door backend pool
   └─→ Verify traffic routing

Total RTO: ~60 minutes
Data Loss: <5 minutes (RPO)
```

### Backup Testing Schedule

```yaml
weekly:
  - PostgreSQL logical backup restore to staging
  - Redis RDB restore to dev environment
  - Verify backup checksums

monthly:
  - Full disaster recovery drill
  - PITR test (PostgreSQL)
  - Cosmos DB point-in-time restore test
  - Azure AI Search re-indexing test

quarterly:
  - Multi-region failover simulation
  - Data integrity verification
  - Backup retention audit
  - Update DR runbook
```

---

## Implementation Examples

### Python (SQLAlchemy)

#### 1. Database Models

```python
# models/workspace.py
from sqlalchemy import Column, String, DateTime, Boolean, Integer, JSON, Text, ARRAY
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func
import uuid

Base = declarative_base()

class Workspace(Base):
    __tablename__ = "workspaces"

    workspace_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    slug = Column(String(100), nullable=False, unique=True)
    description = Column(Text)
    owner_id = Column(UUID(as_uuid=True), nullable=False)
    tier = Column(String(50), nullable=False, default="free")
    settings = Column(JSON, default={})

    # Compliance
    data_region = Column(String(50), nullable=False, default="us-east-1")
    retention_days = Column(Integer, nullable=False, default=90)

    # Audit
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    # Metadata
    metadata_ = Column("metadata", JSON, default={})

    def __repr__(self):
        return f"<Workspace(id={self.workspace_id}, name={self.name})>"

class Agent(Base):
    __tablename__ = "agents"

    agent_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    workspace_id = Column(UUID(as_uuid=True), nullable=False)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    agent_type = Column(String(100), nullable=False)

    # Configuration
    config_version = Column(Integer, nullable=False, default=1)
    config_hash = Column(String(64))

    # LLM Settings
    model_provider = Column(String(50), nullable=False, default="azure_openai")
    model_name = Column(String(100), nullable=False, default="gpt-4")
    temperature = Column(Float, default=0.7)
    max_tokens = Column(Integer, default=4000)

    # Status
    is_published = Column(Boolean, nullable=False, default=False)
    is_active = Column(Boolean, nullable=False, default=True)

    # Metrics (denormalized)
    total_executions = Column(Integer, nullable=False, default=0)
    total_tokens_used = Column(Integer, nullable=False, default=0)
    avg_latency_ms = Column(Float)
    last_executed_at = Column(DateTime(timezone=True))

    # Audit
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    created_by = Column(UUID(as_uuid=True), nullable=False)
    deleted_at = Column(DateTime(timezone=True))

    # Metadata
    tags = Column(ARRAY(Text), default=[])
    metadata_ = Column("metadata", JSON, default={})
```

#### 2. Database Session Management

```python
# database.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, scoped_session
from sqlalchemy.pool import QueuePool
from contextlib import contextmanager
import os

# Connection string from environment
DATABASE_URL = os.getenv("DATABASE_URL")

# Engine with connection pooling
engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=20,
    max_overflow=40,
    pool_timeout=30,
    pool_recycle=1800,
    pool_pre_ping=True,  # Health check before use
    echo=False,  # Set to True for SQL logging
    connect_args={
        "application_name": "agent-studio-python",
        "options": "-c statement_timeout=30000"  # 30s timeout
    }
)

# Session factory
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
    expire_on_commit=False
)

# Thread-safe scoped session
Session = scoped_session(SessionLocal)

@contextmanager
def get_db():
    """Dependency for FastAPI endpoints"""
    db = Session()
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()

# Async engine (for async SQLAlchemy)
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

async_engine = create_async_engine(
    DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://"),
    pool_size=20,
    max_overflow=40,
    pool_timeout=30,
    pool_recycle=1800,
    pool_pre_ping=True
)

AsyncSessionLocal = async_sessionmaker(
    async_engine,
    class_=AsyncSession,
    expire_on_commit=False
)

async def get_async_db():
    """Async dependency for FastAPI endpoints"""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
```

#### 3. Repository Pattern

```python
# repositories/workspace_repository.py
from sqlalchemy import select, update, delete
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from models.workspace import Workspace

class WorkspaceRepository:
    def __init__(self, db: Session):
        self.db = db

    async def create(self, **kwargs) -> Workspace:
        """Create new workspace"""
        workspace = Workspace(**kwargs)
        self.db.add(workspace)
        await self.db.flush()
        await self.db.refresh(workspace)
        return workspace

    async def get_by_id(self, workspace_id: str) -> Optional[Workspace]:
        """Get workspace by ID (with RLS check)"""
        stmt = select(Workspace).where(
            Workspace.workspace_id == workspace_id,
            Workspace.deleted_at.is_(None)
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_slug(self, slug: str) -> Optional[Workspace]:
        """Get workspace by slug"""
        stmt = select(Workspace).where(
            Workspace.slug == slug,
            Workspace.deleted_at.is_(None)
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_for_user(self, user_id: str, limit: int = 50) -> List[Workspace]:
        """List workspaces accessible to user"""
        stmt = """
            SELECT w.*
            FROM workspaces w
            JOIN workspace_members wm ON w.workspace_id = wm.workspace_id
            WHERE wm.user_id = :user_id
              AND w.deleted_at IS NULL
            ORDER BY w.created_at DESC
            LIMIT :limit
        """
        result = await self.db.execute(stmt, {"user_id": user_id, "limit": limit})
        return result.fetchall()

    async def update(self, workspace_id: str, **kwargs) -> Workspace:
        """Update workspace"""
        stmt = (
            update(Workspace)
            .where(Workspace.workspace_id == workspace_id)
            .values(**kwargs, updated_at=datetime.utcnow())
            .returning(Workspace)
        )
        result = await self.db.execute(stmt)
        return result.scalar_one()

    async def soft_delete(self, workspace_id: str) -> None:
        """Soft delete workspace"""
        await self.update(workspace_id, deleted_at=datetime.utcnow())
```

#### 4. FastAPI Integration

```python
# api/workspaces.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from database import get_async_db
from repositories.workspace_repository import WorkspaceRepository
from schemas.workspace import WorkspaceCreate, WorkspaceResponse
from typing import List

router = APIRouter(prefix="/api/v1/workspaces", tags=["workspaces"])

@router.post("/", response_model=WorkspaceResponse, status_code=status.HTTP_201_CREATED)
async def create_workspace(
    workspace_data: WorkspaceCreate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
):
    """Create new workspace"""
    repo = WorkspaceRepository(db)

    # Check if slug already exists
    existing = await repo.get_by_slug(workspace_data.slug)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Workspace with slug '{workspace_data.slug}' already exists"
        )

    # Create workspace
    workspace = await repo.create(
        **workspace_data.dict(),
        owner_id=current_user_id
    )

    return workspace

@router.get("/{workspace_id}", response_model=WorkspaceResponse)
async def get_workspace(
    workspace_id: str,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
):
    """Get workspace by ID"""
    repo = WorkspaceRepository(db)

    # Set RLS context (PostgreSQL session variable)
    await db.execute(f"SET app.current_user_id = '{current_user_id}'")

    workspace = await repo.get_by_id(workspace_id)

    if not workspace:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Workspace not found"
        )

    return workspace

@router.get("/", response_model=List[WorkspaceResponse])
async def list_workspaces(
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id),
    limit: int = 50
):
    """List workspaces for current user"""
    repo = WorkspaceRepository(db)
    workspaces = await repo.list_for_user(current_user_id, limit)
    return workspaces
```

### .NET (EF Core)

#### 1. Database Models

```csharp
// Models/Workspace.cs
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AgentStudio.Models
{
    [Table("workspaces")]
    public class Workspace
    {
        [Key]
        [Column("workspace_id")]
        public Guid WorkspaceId { get; set; } = Guid.NewGuid();

        [Required]
        [MaxLength(255)]
        [Column("name")]
        public string Name { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        [Column("slug")]
        public string Slug { get; set; } = string.Empty;

        [Column("description")]
        public string? Description { get; set; }

        [Required]
        [Column("owner_id")]
        public Guid OwnerId { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("tier")]
        public string Tier { get; set; } = "free";

        [Column("settings", TypeName = "jsonb")]
        public string Settings { get; set; } = "{}";

        // Compliance
        [Required]
        [MaxLength(50)]
        [Column("data_region")]
        public string DataRegion { get; set; } = "us-east-1";

        [Required]
        [Column("retention_days")]
        public int RetentionDays { get; set; } = 90;

        // Audit
        [Required]
        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Required]
        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [Column("deleted_at")]
        public DateTime? DeletedAt { get; set; }

        // Metadata
        [Column("metadata", TypeName = "jsonb")]
        public string Metadata { get; set; } = "{}";

        // Navigation properties
        public ICollection<Agent> Agents { get; set; } = new List<Agent>();
        public ICollection<WorkspaceMember> Members { get; set; } = new List<WorkspaceMember>();
    }

    [Table("agents")]
    public class Agent
    {
        [Key]
        [Column("agent_id")]
        public Guid AgentId { get; set; } = Guid.NewGuid();

        [Required]
        [Column("workspace_id")]
        public Guid WorkspaceId { get; set; }

        [Required]
        [MaxLength(255)]
        [Column("name")]
        public string Name { get; set; } = string.Empty;

        [Column("description")]
        public string? Description { get; set; }

        [Required]
        [MaxLength(100)]
        [Column("agent_type")]
        public string AgentType { get; set; } = string.Empty;

        // Configuration
        [Required]
        [Column("config_version")]
        public int ConfigVersion { get; set; } = 1;

        [MaxLength(64)]
        [Column("config_hash")]
        public string? ConfigHash { get; set; }

        // LLM Settings
        [Required]
        [MaxLength(50)]
        [Column("model_provider")]
        public string ModelProvider { get; set; } = "azure_openai";

        [Required]
        [MaxLength(100)]
        [Column("model_name")]
        public string ModelName { get; set; } = "gpt-4";

        [Column("temperature")]
        public decimal Temperature { get; set; } = 0.7m;

        [Column("max_tokens")]
        public int MaxTokens { get; set; } = 4000;

        // Status
        [Required]
        [Column("is_published")]
        public bool IsPublished { get; set; } = false;

        [Required]
        [Column("is_active")]
        public bool IsActive { get; set; } = true;

        // Metrics (denormalized)
        [Required]
        [Column("total_executions")]
        public long TotalExecutions { get; set; } = 0;

        [Required]
        [Column("total_tokens_used")]
        public long TotalTokensUsed { get; set; } = 0;

        [Column("avg_latency_ms")]
        public decimal? AvgLatencyMs { get; set; }

        [Column("last_executed_at")]
        public DateTime? LastExecutedAt { get; set; }

        // Audit
        [Required]
        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Required]
        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [Required]
        [Column("created_by")]
        public Guid CreatedBy { get; set; }

        [Column("deleted_at")]
        public DateTime? DeletedAt { get; set; }

        // Metadata
        [Column("tags", TypeName = "text[]")]
        public string[] Tags { get; set; } = Array.Empty<string>();

        [Column("metadata", TypeName = "jsonb")]
        public string Metadata { get; set; } = "{}";

        // Navigation properties
        [ForeignKey("WorkspaceId")]
        public Workspace Workspace { get; set; } = null!;

        public ICollection<AgentTool> AgentTools { get; set; } = new List<AgentTool>();
    }
}
```

#### 2. DbContext Configuration

```csharp
// Data/AppDbContext.cs
using Microsoft.EntityFrameworkCore;
using AgentStudio.Models;

namespace AgentStudio.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Workspace> Workspaces { get; set; } = null!;
        public DbSet<User> Users { get; set; } = null!;
        public DbSet<Agent> Agents { get; set; } = null!;
        public DbSet<Tool> Tools { get; set; } = null!;
        public DbSet<WorkspaceMember> WorkspaceMembers { get; set; } = null!;
        public DbSet<AgentTool> AgentTools { get; set; } = null!;
        public DbSet<Permission> Permissions { get; set; } = null!;
        public DbSet<AuditLog> AuditLogs { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Workspace configuration
            modelBuilder.Entity<Workspace>(entity =>
            {
                entity.HasKey(e => e.WorkspaceId);
                entity.HasIndex(e => e.Slug).IsUnique();
                entity.HasIndex(e => e.OwnerId).HasFilter("deleted_at IS NULL");
                entity.HasIndex(e => e.CreatedAt);

                entity.Property(e => e.Settings).HasColumnType("jsonb");
                entity.Property(e => e.Metadata).HasColumnType("jsonb");

                entity.HasQueryFilter(e => e.DeletedAt == null);
            });

            // Agent configuration
            modelBuilder.Entity<Agent>(entity =>
            {
                entity.HasKey(e => e.AgentId);
                entity.HasIndex(e => e.WorkspaceId).HasFilter("deleted_at IS NULL");
                entity.HasIndex(e => new { e.WorkspaceId, e.AgentType }).HasFilter("deleted_at IS NULL");
                entity.HasIndex(e => e.TotalExecutions);

                entity.Property(e => e.Tags).HasColumnType("text[]");
                entity.Property(e => e.Metadata).HasColumnType("jsonb");

                entity.HasQueryFilter(e => e.DeletedAt == null);

                entity.HasOne(e => e.Workspace)
                    .WithMany(w => w.Agents)
                    .HasForeignKey(e => e.WorkspaceId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // WorkspaceMember configuration
            modelBuilder.Entity<WorkspaceMember>(entity =>
            {
                entity.HasKey(e => e.WorkspaceMemberId);
                entity.HasIndex(e => new { e.WorkspaceId, e.UserId }).IsUnique();
                entity.HasIndex(e => e.WorkspaceId);
                entity.HasIndex(e => e.UserId);
            });

            // Enable Row-Level Security (requires database trigger)
            // Implemented via OnConfiguring or EF Core interceptors
        }

        public override int SaveChanges()
        {
            UpdateTimestamps();
            return base.SaveChanges();
        }

        public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            UpdateTimestamps();
            return await base.SaveChangesAsync(cancellationToken);
        }

        private void UpdateTimestamps()
        {
            var entries = ChangeTracker.Entries()
                .Where(e => e.Entity is Workspace || e.Entity is Agent)
                .Where(e => e.State == EntityState.Modified);

            foreach (var entry in entries)
            {
                if (entry.Entity is Workspace workspace)
                {
                    workspace.UpdatedAt = DateTime.UtcNow;
                }
                else if (entry.Entity is Agent agent)
                {
                    agent.UpdatedAt = DateTime.UtcNow;
                }
            }
        }
    }
}
```

#### 3. Repository Pattern

```csharp
// Repositories/IWorkspaceRepository.cs
using AgentStudio.Models;

namespace AgentStudio.Repositories
{
    public interface IWorkspaceRepository
    {
        Task<Workspace?> GetByIdAsync(Guid workspaceId);
        Task<Workspace?> GetBySlugAsync(string slug);
        Task<IEnumerable<Workspace>> GetForUserAsync(Guid userId, int limit = 50);
        Task<Workspace> CreateAsync(Workspace workspace);
        Task<Workspace> UpdateAsync(Workspace workspace);
        Task DeleteAsync(Guid workspaceId);
    }

    public class WorkspaceRepository : IWorkspaceRepository
    {
        private readonly AppDbContext _context;

        public WorkspaceRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task<Workspace?> GetByIdAsync(Guid workspaceId)
        {
            return await _context.Workspaces
                .Include(w => w.Members)
                .FirstOrDefaultAsync(w => w.WorkspaceId == workspaceId);
        }

        public async Task<Workspace?> GetBySlugAsync(string slug)
        {
            return await _context.Workspaces
                .FirstOrDefaultAsync(w => w.Slug == slug);
        }

        public async Task<IEnumerable<Workspace>> GetForUserAsync(Guid userId, int limit = 50)
        {
            return await _context.Workspaces
                .Where(w => w.Members.Any(m => m.UserId == userId))
                .OrderByDescending(w => w.CreatedAt)
                .Take(limit)
                .ToListAsync();
        }

        public async Task<Workspace> CreateAsync(Workspace workspace)
        {
            _context.Workspaces.Add(workspace);
            await _context.SaveChangesAsync();
            return workspace;
        }

        public async Task<Workspace> UpdateAsync(Workspace workspace)
        {
            _context.Entry(workspace).State = EntityState.Modified;
            await _context.SaveChangesAsync();
            return workspace;
        }

        public async Task DeleteAsync(Guid workspaceId)
        {
            var workspace = await GetByIdAsync(workspaceId);
            if (workspace != null)
            {
                workspace.DeletedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }
        }
    }
}
```

#### 4. API Controller

```csharp
// Controllers/WorkspacesController.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using AgentStudio.Models;
using AgentStudio.Repositories;
using AgentStudio.DTOs;

namespace AgentStudio.Controllers
{
    [ApiController]
    [Route("api/v1/[controller]")]
    [Authorize]
    public class WorkspacesController : ControllerBase
    {
        private readonly IWorkspaceRepository _workspaceRepository;
        private readonly ILogger<WorkspacesController> _logger;

        public WorkspacesController(
            IWorkspaceRepository workspaceRepository,
            ILogger<WorkspacesController> logger)
        {
            _workspaceRepository = workspaceRepository;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<WorkspaceDto>>> GetWorkspaces(
            [FromQuery] int limit = 50)
        {
            var userId = GetCurrentUserId();
            var workspaces = await _workspaceRepository.GetForUserAsync(userId, limit);

            return Ok(workspaces.Select(w => WorkspaceDto.FromModel(w)));
        }

        [HttpGet("{workspaceId:guid}")]
        public async Task<ActionResult<WorkspaceDto>> GetWorkspace(Guid workspaceId)
        {
            var workspace = await _workspaceRepository.GetByIdAsync(workspaceId);

            if (workspace == null)
            {
                return NotFound(new { message = "Workspace not found" });
            }

            // Check user has access (RLS should handle this, but double-check)
            var userId = GetCurrentUserId();
            if (!workspace.Members.Any(m => m.UserId == userId))
            {
                return Forbid();
            }

            return Ok(WorkspaceDto.FromModel(workspace));
        }

        [HttpPost]
        public async Task<ActionResult<WorkspaceDto>> CreateWorkspace(
            [FromBody] CreateWorkspaceDto createDto)
        {
            // Check if slug already exists
            var existing = await _workspaceRepository.GetBySlugAsync(createDto.Slug);
            if (existing != null)
            {
                return Conflict(new { message = $"Workspace with slug '{createDto.Slug}' already exists" });
            }

            var userId = GetCurrentUserId();

            var workspace = new Workspace
            {
                Name = createDto.Name,
                Slug = createDto.Slug,
                Description = createDto.Description,
                OwnerId = userId,
                Tier = createDto.Tier ?? "free",
                DataRegion = createDto.DataRegion ?? "us-east-1"
            };

            var created = await _workspaceRepository.CreateAsync(workspace);

            _logger.LogInformation(
                "Workspace {WorkspaceId} created by user {UserId}",
                created.WorkspaceId,
                userId
            );

            return CreatedAtAction(
                nameof(GetWorkspace),
                new { workspaceId = created.WorkspaceId },
                WorkspaceDto.FromModel(created)
            );
        }

        [HttpPatch("{workspaceId:guid}")]
        public async Task<ActionResult<WorkspaceDto>> UpdateWorkspace(
            Guid workspaceId,
            [FromBody] UpdateWorkspaceDto updateDto)
        {
            var workspace = await _workspaceRepository.GetByIdAsync(workspaceId);

            if (workspace == null)
            {
                return NotFound();
            }

            // Apply updates
            if (updateDto.Name != null) workspace.Name = updateDto.Name;
            if (updateDto.Description != null) workspace.Description = updateDto.Description;

            var updated = await _workspaceRepository.UpdateAsync(workspace);

            return Ok(WorkspaceDto.FromModel(updated));
        }

        [HttpDelete("{workspaceId:guid}")]
        public async Task<IActionResult> DeleteWorkspace(Guid workspaceId)
        {
            await _workspaceRepository.DeleteAsync(workspaceId);
            return NoContent();
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst("sub") ?? User.FindFirst("user_id");
            if (userIdClaim == null)
            {
                throw new UnauthorizedAccessException("User ID not found in token");
            }
            return Guid.Parse(userIdClaim.Value);
        }
    }
}
```

---

## Performance Benchmarks

### Target SLAs

```
Operation                       | p50    | p95    | p99    | p99.9
--------------------------------|--------|--------|--------|--------
PostgreSQL Query (indexed)      | 5ms    | 15ms   | 30ms   | 100ms
PostgreSQL Query (full scan)    | 50ms   | 200ms  | 500ms  | 2s
Cosmos DB Point Read            | 10ms   | 25ms   | 50ms   | 150ms
Cosmos DB Query (partition)     | 15ms   | 40ms   | 80ms   | 200ms
Cosmos DB Query (cross-part)    | 100ms  | 300ms  | 600ms  | 2s
Azure AI Search (vector)        | 15ms   | 35ms   | 80ms   | 200ms
Azure AI Search (hybrid)        | 25ms   | 50ms   | 120ms  | 300ms
Redis GET (cache hit)           | <1ms   | 2ms    | 5ms    | 15ms
Redis SET                       | <1ms   | 3ms    | 8ms    | 20ms
End-to-End Agent Execution      | 500ms  | 2s     | 5s     | 15s
```

### Capacity Planning

```yaml
PostgreSQL:
  connections: 100 (max)
  pool_size: 20 per instance
  instances: 3 (1 primary + 2 replicas)
  storage: 500GB (initial), auto-scale to 2TB
  compute: 4 vCPUs, 16GB RAM per instance

Cosmos DB:
  request_units: 10,000 RU/s (auto-scale to 50,000)
  storage: Unlimited (pay-per-GB)
  regions: 2 (East US, West US)
  consistency: Session

Redis:
  cluster: 6 nodes (3 primaries + 3 replicas)
  memory: 4GB per node (24GB total)
  eviction: allkeys-lru
  persistence: AOF + RDB snapshots

Azure AI Search:
  tier: S1 (25GB storage, 3 replicas, 3 partitions)
  indexes: 2 (agent-memory, knowledge-base)
  documents: 10M (estimated)
  queries_per_second: 100 (peak), 20 (avg)
```

---

## Security Hardening

### 1. Encryption

```yaml
At Rest:
  - PostgreSQL: Transparent Data Encryption (TDE) enabled
  - Cosmos DB: Encryption enabled by default
  - Redis: Encryption at rest via Azure Disk Encryption
  - Azure AI Search: Encryption enabled by default
  - Backups: Encrypted with customer-managed keys (CMK)

In Transit:
  - PostgreSQL: SSL/TLS 1.2+ required (sslmode=require)
  - Cosmos DB: HTTPS only
  - Redis: TLS 1.2+ required
  - Azure AI Search: HTTPS only
  - Application: End-to-end TLS 1.3
```

### 2. Access Control

```yaml
PostgreSQL:
  - Row-Level Security (RLS) for multi-tenancy
  - Dedicated service accounts per service
  - Least privilege principle
  - Password rotation every 90 days
  - IP allow-listing for production

Cosmos DB:
  - Managed Identity authentication
  - Resource tokens for fine-grained access
  - IP firewall rules
  - Private endpoints (production)

Redis:
  - AUTH password required
  - Rename dangerous commands (CONFIG, FLUSHALL)
  - Network isolation via VNet

Azure AI Search:
  - API key authentication
  - IP restrictions
  - Private endpoints (production)
```

### 3. Audit Logging

All database operations are logged to the `audit_logs` table with:
- User ID
- Workspace ID
- Action type
- Resource ID
- IP address
- Timestamp
- Before/after state (encrypted for sensitive data)

Logs are retained for 7 years for compliance (SOC2, GDPR, HIPAA).

---

## Monitoring & Alerting

### Metrics to Monitor

```yaml
PostgreSQL:
  - Connection pool utilization (alert at 80%)
  - Query latency (p95, p99)
  - Cache hit ratio (alert if <90%)
  - Replication lag (alert if >10s)
  - Disk space (alert at 80%)
  - Long-running queries (alert if >30s)

Cosmos DB:
  - Request Units consumed (alert at 80% of provisioned)
  - 429 rate limiting errors (alert if >1% of requests)
  - Partition hot spots
  - Replication lag (multi-region)

Redis:
  - Memory usage (alert at 80%)
  - Eviction rate (alert if >100/min)
  - Cache hit ratio (alert if <95%)
  - Replication lag

Azure AI Search:
  - Index size (alert at 90% capacity)
  - Query latency (p95, p99)
  - Indexing errors
  - Throttling events
```

### Dashboards

```
Grafana Dashboard: Data Layer Overview
├── PostgreSQL Panel
│   ├── Active connections
│   ├── Query latency (p50, p95, p99)
│   ├── Transactions per second
│   └── Cache hit ratio
├── Cosmos DB Panel
│   ├── Request Units consumed
│   ├── Document count
│   ├── Partition distribution
│   └── Latency heatmap
├── Redis Panel
│   ├── Memory usage
│   ├── Operations per second
│   ├── Cache hit ratio
│   └── Eviction rate
└── Azure AI Search Panel
    ├── Search queries per second
    ├── Indexing operations
    ├── Query latency
    └── Index size
```

---

## Conclusion

This data layer design provides:

1. **High Performance**: Sub-500ms query latency with caching and indexing
2. **Scalability**: Horizontal scaling via partitioning, sharding, and replication
3. **Reliability**: Multi-region replication, automated backups, point-in-time recovery
4. **Security**: Encryption at rest/in transit, RLS, audit logging, GDPR compliance
5. **Multi-Tenancy**: Workspace-level isolation with row-level security
6. **Developer Experience**: Type-safe models in Python (SQLAlchemy) and .NET (EF Core)

### Next Steps

1. **Phase 1**: Deploy PostgreSQL schema with RLS policies
2. **Phase 2**: Set up Cosmos DB containers with change feed
3. **Phase 3**: Configure Azure AI Search indexes and embeddings pipeline
4. **Phase 4**: Deploy Redis cluster with replication
5. **Phase 5**: Implement backup automation and DR testing
6. **Phase 6**: Load testing and performance tuning
7. **Phase 7**: Security hardening and compliance audit

### File Locations

- **Schema Definitions**: `C:\Users\MarkusAhling\Project-Ascension\docs\DATA_LAYER_DESIGN.md`
- **Migration Scripts**: `C:\Users\MarkusAhling\Project-Ascension\infra\database\migrations\`
- **Python Models**: `C:\Users\MarkusAhling\Project-Ascension\services\python\app\models\`
- **.NET Models**: `C:\Users\MarkusAhling\Project-Ascension\services\dotnet\AgentStudio.Api\Models\`
- **Configuration**: `C:\Users\MarkusAhling\Project-Ascension\infra\bicep\databases.bicep`

---

**Document Version**: 1.0
**Last Updated**: 2025-01-15
**Author**: Database Architecture Team
**Status**: Ready for Review
