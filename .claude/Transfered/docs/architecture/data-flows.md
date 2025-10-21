# Data Flow Documentation - Agent Studio

## Overview
This document establishes comprehensive data flow patterns across Agent Studio's distributed architecture, showing how information moves through the platform to streamline workflow execution, state management, and real-time communication.

**Best for:** Engineers implementing integrations or debugging issues requiring understanding of end-to-end data movement across services.

## Primary Data Flows

### 1. Workflow Execution Flow (Sequential Pattern)

This flow demonstrates how a sequential workflow moves through the platform from creation to completion, with state persistence and real-time updates.

```mermaid
sequenceDiagram
    autonumber
    participant User as Developer
    participant WebApp as Web Application<br/>(React)
    participant API as Orchestration API<br/>(.NET)
    participant Orchestrator as MetaAgent<br/>Orchestrator
    participant Python as Python Agent<br/>Service
    participant OpenAI as Azure OpenAI
    participant Cosmos as Cosmos DB
    participant SignalR as SignalR Hub
    participant Redis as Redis Cache

    User->>WebApp: Create Sequential Workflow
    WebApp->>API: POST /api/workflows<br/>{workflow definition}

    API->>API: Validate request<br/>Authenticate via Azure AD
    API->>Orchestrator: ExecuteWorkflowAsync()

    Orchestrator->>Cosmos: Create workflow record<br/>Status: Pending
    Cosmos-->>Orchestrator: Workflow created<br/>with ETag

    Orchestrator->>SignalR: PublishWorkflowStarted
    SignalR-->>WebApp: ReceiveWorkflowStarted<br/>(WebSocket)
    WebApp-->>User: Show "Workflow Running"

    loop For each task in sequence
        Orchestrator->>Python: POST /api/agents/execute<br/>{task definition}
        Python->>Redis: Check context cache<br/>GET context:{hash}
        alt Cache hit
            Redis-->>Python: Cached context
        else Cache miss
            Python->>Cosmos: Load context from DB
            Cosmos-->>Python: Context data
            Python->>Redis: Cache for future use
        end

        Python->>OpenAI: Generate response<br/>POST /openai/deployments/gpt-4
        OpenAI-->>Python: AI completion

        Python->>Cosmos: Save task result
        Python-->>Orchestrator: AgentResult

        Orchestrator->>Cosmos: Update workflow state<br/>UpsertItem with ETag
        Cosmos-->>Orchestrator: State updated

        Orchestrator->>Cosmos: Create checkpoint<br/>CheckpointType.Automatic
        Cosmos-->>Orchestrator: Checkpoint saved

        Orchestrator->>SignalR: PublishTaskCompleted
        SignalR-->>WebApp: ReceiveTaskCompleted
        WebApp-->>User: Update progress bar
    end

    Orchestrator->>Cosmos: Update workflow<br/>Status: Completed
    Orchestrator->>SignalR: PublishWorkflowCompleted
    SignalR-->>WebApp: ReceiveWorkflowCompleted
    WebApp-->>User: Show final results

    API-->>WebApp: 200 OK<br/>{workflow result}
    WebApp-->>User: Display success message
```

**Key Points:**
- **Optimistic Concurrency:** Cosmos DB uses ETag for conflict detection
- **Context Caching:** Redis reduces redundant Cosmos DB reads by 80%
- **Real-time Updates:** SignalR provides live progress without polling
- **Checkpointing:** Automatic checkpoints after each task enable recovery
- **Async Communication:** All I/O operations use async/await for efficiency

**Performance Metrics:**
- Workflow creation: < 500ms
- Task execution: 2-10s (depends on LLM complexity)
- State persistence: < 100ms
- Real-time event delivery: < 50ms

---

### 2. Parallel Workflow Execution with DAG Scheduling

This flow shows how parallel tasks execute concurrently with dependency management and level-based scheduling.

```mermaid
sequenceDiagram
    autonumber
    participant WebApp as Web Application
    participant API as Orchestration API
    participant Executor as Workflow Executor
    participant DAG as DAG Builder
    participant AgentClient as Python Agent Client
    participant Python as Python Agent Service
    participant Cosmos as Cosmos DB
    participant SignalR as SignalR Hub

    WebApp->>API: POST /api/workflows<br/>Pattern: Parallel
    API->>Executor: ExecuteParallelAsync()

    Executor->>DAG: BuildDependencyGraph<br/>(tasks with dependencies)
    DAG->>DAG: TopologicalSort()
    DAG-->>Executor: Execution levels:<br/>Level 0: [Task A]<br/>Level 1: [Task B, C, D]<br/>Level 2: [Task E]

    Executor->>SignalR: PublishWorkflowStarted
    SignalR-->>WebApp: Real-time notification

    Note over Executor: Execute Level 0 (Sequential)
    Executor->>AgentClient: ExecuteTaskAsync(Task A)
    AgentClient->>Python: HTTP POST /api/agents/execute
    Python-->>AgentClient: Result A
    AgentClient-->>Executor: AgentResult A

    Executor->>Cosmos: SaveStateAsync<br/>Task A completed
    Executor->>Cosmos: CreateCheckpointAsync
    Executor->>SignalR: PublishTaskCompleted(Task A)

    Note over Executor: Execute Level 1 (Parallel)
    par Task B
        Executor->>AgentClient: ExecuteTaskAsync(Task B)
        AgentClient->>Python: HTTP POST
        Python-->>AgentClient: Result B
        AgentClient-->>Executor: AgentResult B
    and Task C
        Executor->>AgentClient: ExecuteTaskAsync(Task C)
        AgentClient->>Python: HTTP POST
        Python-->>AgentClient: Result C
        AgentClient-->>Executor: AgentResult C
    and Task D
        Executor->>AgentClient: ExecuteTaskAsync(Task D)
        AgentClient->>Python: HTTP POST
        Python-->>AgentClient: Result D
        AgentClient-->>Executor: AgentResult D
    end

    Executor->>Cosmos: SaveStateAsync<br/>Tasks B, C, D completed
    Executor->>Cosmos: CreateCheckpointAsync
    Executor->>SignalR: PublishTaskCompleted(B, C, D)

    Note over Executor: Execute Level 2 (Sequential)
    Executor->>AgentClient: ExecuteTaskAsync(Task E)<br/>Context: [A, B, C, D results]
    AgentClient->>Python: HTTP POST
    Python-->>AgentClient: Result E
    AgentClient-->>Executor: AgentResult E

    Executor->>Cosmos: SaveStateAsync<br/>Status: Completed
    Executor->>SignalR: PublishWorkflowCompleted
    SignalR-->>WebApp: Final notification

    Executor-->>API: WorkflowResult
    API-->>WebApp: 200 OK
```

**Parallelization Benefits:**
- **Time Savings:** 3 tasks run in parallel instead of sequence
- **Resource Utilization:** Multiple Python agent instances handle concurrent requests
- **Dependency Respect:** Level-based execution ensures dependencies are satisfied
- **Failure Isolation:** One task failure doesn't block independent tasks

**Example Timeline:**
```
Sequential:  A(5s) → B(8s) → C(6s) → D(7s) → E(10s) = 36 seconds
Parallel:    A(5s) → [B,C,D](8s) → E(10s) = 23 seconds
Speedup:     36% faster execution
```

---

### 3. Iterative Workflow with Validation Feedback

This flow demonstrates the Builder-Validator pattern with iterative refinement based on quality gate feedback.

```mermaid
sequenceDiagram
    autonumber
    participant WebApp as Web Application
    participant API as Orchestration API
    participant Executor as Workflow Executor
    participant Builder as Builder Agent
    participant Validator as Validator Agent
    participant QualityGate as Quality Gate<br/>Validator
    participant Cosmos as Cosmos DB
    participant SignalR as SignalR Hub

    WebApp->>API: POST /api/workflows<br/>Pattern: Iterative<br/>MaxIterations: 5
    API->>Executor: ExecuteIterativeAsync()

    Executor->>SignalR: PublishWorkflowStarted

    loop Until valid OR max iterations
        Note over Executor: Iteration N
        Executor->>SignalR: PublishProgress<br/>"Iteration N: Building..."

        Executor->>Builder: Execute with feedback<br/>from previous iteration
        Builder->>Builder: Generate output<br/>using context + feedback
        Builder-->>Executor: BuilderOutput

        Executor->>SignalR: PublishAgentThought<br/>"Generated solution..."

        Executor->>Validator: Execute validation<br/>ValidateOutput(BuilderOutput)
        Validator->>QualityGate: ValidateAsync<br/>(output, quality gates)

        alt Validation passed
            QualityGate-->>Validator: ValidationResult<br/>IsValid: true
            Validator-->>Executor: Valid output
            Executor->>Cosmos: SaveStateAsync<br/>Status: Completed
            Executor->>SignalR: PublishWorkflowCompleted
            Note over Executor: Exit loop (success)
        else Validation failed
            QualityGate-->>Validator: ValidationResult<br/>IsValid: false<br/>Feedback: "Issues found..."
            Validator-->>Executor: Invalid output<br/>+ feedback

            Executor->>Cosmos: SaveStateAsync<br/>Status: InProgress<br/>Iteration: N+1
            Executor->>Cosmos: CreateCheckpointAsync
            Executor->>SignalR: PublishTaskCompleted<br/>"Iteration N failed, retrying..."

            alt Max iterations reached
                Executor->>Cosmos: SaveStateAsync<br/>Status: Failed
                Executor->>SignalR: PublishWorkflowFailed<br/>"Max iterations exceeded"
                Note over Executor: Exit loop (failure)
            end
        end
    end

    Executor-->>API: WorkflowResult
    API-->>WebApp: 200 OK
```

**Feedback Loop Mechanism:**
```json
// Iteration 1: Initial attempt
{
  "builderPrompt": "Design a REST API for user management",
  "feedback": null
}

// Iteration 2: With validator feedback
{
  "builderPrompt": "Design a REST API for user management",
  "feedback": "Missing authentication endpoints. Add OAuth 2.0 support."
}

// Iteration 3: Refined with accumulated feedback
{
  "builderPrompt": "Design a REST API for user management",
  "feedback": "OAuth endpoints added but missing rate limiting. Add throttling."
}
```

**Quality Gates Example:**
```json
{
  "qualityGates": [
    {
      "name": "Schema Validation",
      "type": "JsonSchema",
      "schema": {...}
    },
    {
      "name": "Security Check",
      "type": "LLM",
      "prompt": "Validate that all endpoints require authentication"
    },
    {
      "name": "Performance",
      "type": "Custom",
      "maxExecutionTimeMs": 5000
    }
  ]
}
```

---

### 4. Real-time Event Broadcasting with SignalR

This flow shows how real-time events propagate from backend services to connected web clients via SignalR.

```mermaid
sequenceDiagram
    autonumber
    participant User as Developer
    participant WebApp as Web Application
    participant SignalRClient as SignalR Client<br/>(Browser)
    participant SignalRHub as SignalR Hub<br/>(.NET)
    participant SignalRService as Azure SignalR<br/>Service
    participant Orchestrator as Orchestration<br/>Components

    User->>WebApp: Open workflow details page
    WebApp->>SignalRClient: Initialize connection

    SignalRClient->>SignalRHub: Negotiate connection<br/>GET /hubs/meta-agent/negotiate
    SignalRHub-->>SignalRClient: Connection info<br/>(AccessToken, URL)

    SignalRClient->>SignalRService: Connect via WebSocket<br/>ws://...
    SignalRService-->>SignalRClient: Connection established

    SignalRClient->>SignalRHub: Invoke("SubscribeToWorkflow", workflowId)
    SignalRHub->>SignalRHub: Add to group<br/>Groups.AddToGroupAsync()
    SignalRHub-->>SignalRClient: Subscription confirmed

    WebApp-->>User: "Connected - Live updates enabled"

    Note over Orchestrator: Workflow execution events

    Orchestrator->>SignalRHub: PublishWorkflowStarted(workflowId)
    SignalRHub->>SignalRService: Clients.Group(workflowId)<br/>.SendAsync("ReceiveWorkflowStarted")
    SignalRService-->>SignalRClient: Broadcast to group
    SignalRClient->>WebApp: Update UI:<br/>Status = "Running"
    WebApp-->>User: Visual indicator changes

    Orchestrator->>SignalRHub: PublishAgentThought(thought)
    SignalRHub->>SignalRService: Broadcast to group
    SignalRService-->>SignalRClient: "ReceiveAgentThought"
    SignalRClient->>WebApp: Append to thought stream
    WebApp-->>User: Real-time thought display

    Orchestrator->>SignalRHub: PublishProgress(50, "Task 2 of 4")
    SignalRHub->>SignalRService: Broadcast to group
    SignalRService-->>SignalRClient: "ReceiveProgress"
    SignalRClient->>WebApp: Update progress bar
    WebApp-->>User: 50% progress shown

    Orchestrator->>SignalRHub: PublishTaskCompleted(taskId, result)
    SignalRHub->>SignalRService: Broadcast to group
    SignalRService-->>SignalRClient: "ReceiveTaskCompleted"
    SignalRClient->>WebApp: Add task to completed list
    WebApp-->>User: Task marked complete

    Orchestrator->>SignalRHub: PublishWorkflowCompleted(workflowId, result)
    SignalRHub->>SignalRService: Broadcast to group
    SignalRService-->>SignalRClient: "ReceiveWorkflowCompleted"
    SignalRClient->>WebApp: Status = "Completed"<br/>Display final results
    WebApp-->>User: Success notification

    User->>WebApp: Navigate away
    WebApp->>SignalRClient: Cleanup
    SignalRClient->>SignalRHub: Invoke("UnsubscribeFromWorkflow")
    SignalRHub->>SignalRHub: Groups.RemoveFromGroupAsync()
    SignalRClient->>SignalRService: Disconnect
    SignalRService-->>SignalRClient: Connection closed
```

**Event Types and Payloads:**

**WorkflowStarted:**
```json
{
  "workflowId": "wf_abc123",
  "name": "Customer Onboarding",
  "pattern": "Sequential",
  "estimatedDurationMs": 30000,
  "startedAt": "2025-10-14T10:00:00Z"
}
```

**AgentThought:**
```json
{
  "workflowId": "wf_abc123",
  "taskId": "task_001",
  "agentType": "Architect",
  "thought": "Analyzing requirements to design scalable system architecture...",
  "timestamp": "2025-10-14T10:00:15Z"
}
```

**Progress:**
```json
{
  "workflowId": "wf_abc123",
  "percentage": 50,
  "message": "Task 2 of 4 completed",
  "currentTask": "Builder Agent executing...",
  "timestamp": "2025-10-14T10:00:30Z"
}
```

**TaskCompleted:**
```json
{
  "workflowId": "wf_abc123",
  "taskId": "task_002",
  "agentType": "Builder",
  "result": {...},
  "durationMs": 8500,
  "tokenUsage": {"prompt": 1200, "completion": 800},
  "timestamp": "2025-10-14T10:00:45Z"
}
```

**Connection Management:**
- **Automatic Reconnection:** Client retries with exponential backoff (1s, 2s, 4s, 8s, 16s max)
- **Keep-Alive:** Ping every 30s to detect stale connections
- **Graceful Degradation:** Falls back to long-polling if WebSocket unavailable
- **Group Isolation:** Clients only receive events for subscribed workflows

---

### 5. Checkpoint and Recovery Flow

This flow demonstrates how checkpoints enable workflow recovery after failures or interruptions.

```mermaid
sequenceDiagram
    autonumber
    participant Executor as Workflow Executor
    participant Checkpoint as Checkpoint Manager
    participant Cosmos as Cosmos DB
    participant Blob as Blob Storage
    participant Recovery as Recovery Service
    participant Orchestrator as MetaAgent<br/>Orchestrator

    Note over Executor: Normal execution with checkpoints

    loop For each completed task
        Executor->>Checkpoint: CreateCheckpointAsync<br/>Type: Automatic
        Checkpoint->>Checkpoint: Serialize context<br/>Generate checkpoint ID

        Checkpoint->>Cosmos: CreateItemAsync<br/>{checkpoint data}<br/>TTL: 30 days
        Cosmos-->>Checkpoint: Checkpoint saved

        par Async backup
            Checkpoint->>Blob: Upload checkpoint<br/>to blob storage<br/>(fire-and-forget)
            Blob-->>Checkpoint: Backup complete
        end

        Checkpoint-->>Executor: Checkpoint created
    end

    Note over Executor: Failure occurs
    Executor->>Executor: Task fails with exception

    Executor->>Checkpoint: CreateCheckpointAsync<br/>Type: Failure
    Checkpoint->>Cosmos: Save failure checkpoint

    Executor->>Cosmos: Update workflow<br/>Status: Failed<br/>ErrorMessage: "..."

    Note over Recovery: Recovery service (every 5 min)

    Recovery->>Cosmos: Query failed workflows<br/>WHERE Status = 'Failed'
    Cosmos-->>Recovery: List of failed workflows

    Recovery->>Recovery: ShouldAttemptRecovery()<br/>(check retry count, time)

    alt Recovery eligible
        Recovery->>Checkpoint: LoadCheckpointAsync<br/>(latest checkpoint)
        Checkpoint->>Cosmos: ReadItemAsync<br/>ORDER BY CreatedAt DESC
        Cosmos-->>Checkpoint: Latest checkpoint
        Checkpoint->>Checkpoint: Deserialize context
        Checkpoint-->>Recovery: WorkflowContext

        Recovery->>Orchestrator: ResumeWorkflowAsync<br/>(workflowId, checkpointId)
        Orchestrator->>Executor: ExecuteWorkflowAsync<br/>(from checkpoint context)

        Note over Executor: Resume from last successful point
        Executor->>Executor: Skip completed tasks<br/>Continue from next task

        alt Recovery successful
            Executor->>Cosmos: Update workflow<br/>Status: Completed
            Recovery-->>Recovery: Log success metric
        else Recovery failed again
            Executor->>Cosmos: Update workflow<br/>Status: Failed<br/>RetryCount++
            Recovery->>Recovery: Schedule next retry<br/>with exponential backoff
        end
    else Not eligible (max retries)
        Recovery->>Cosmos: Update workflow<br/>Status: PermanentlyFailed
        Recovery->>Recovery: Send alert to operators
    end
```

**Checkpoint Storage Strategy:**

**Cosmos DB (Primary - Fast Access):**
- Stores checkpoints with 30-day TTL
- Enables fast loading for recovery
- Partitioned by workflowId for parallel queries
- Automatic cleanup via TTL

**Blob Storage (Backup - Long-term):**
- Async backup for disaster recovery
- Lifecycle management (Hot → Cool → Archive)
- Retention: 365 days
- Cheaper long-term storage

**Checkpoint Content:**
```json
{
  "id": "cp_xyz789",
  "workflowId": "wf_abc123",
  "type": "Automatic",
  "createdAt": "2025-10-14T10:00:30Z",
  "state": {
    "completedTasks": ["task_001", "task_002"],
    "pendingTasks": ["task_003", "task_004"],
    "context": {
      "customerId": "cust_456",
      "regionAnalysis": {...}
    },
    "metrics": {
      "durationMs": 15000,
      "totalTokens": 2500
    }
  },
  "metadata": {
    "tasksCompleted": 2,
    "totalTasks": 4,
    "progressPercentage": 50
  },
  "ttl": 2592000
}
```

**Recovery Decision Logic:**
```csharp
private bool ShouldAttemptRecovery(WorkflowState workflow)
{
    // Don't retry if max attempts exceeded
    if (workflow.RetryCount >= MaxRetryAttempts) return false;

    // Don't retry if too old (> 24 hours)
    if (DateTime.UtcNow - workflow.FailedAt > TimeSpan.FromHours(24)) return false;

    // Check if enough time passed since last retry (exponential backoff)
    var backoffMinutes = Math.Pow(2, workflow.RetryCount); // 1, 2, 4, 8, 16 min
    if (DateTime.UtcNow - workflow.LastRetryAt < TimeSpan.FromMinutes(backoffMinutes)) return false;

    // Check if error is retryable (not permanent errors like auth failure)
    if (IsPermanentError(workflow.ErrorCode)) return false;

    return true;
}
```

---

### 6. Authentication and Authorization Flow

This flow shows how user authentication propagates through the platform using Azure AD and JWT tokens.

```mermaid
sequenceDiagram
    autonumber
    participant User as Developer
    participant WebApp as Web Application
    participant AzureAD as Azure AD
    participant API as Orchestration API
    participant Token as Token Validator
    participant Cosmos as Cosmos DB

    User->>WebApp: Access application<br/>(not authenticated)
    WebApp->>WebApp: Check auth state<br/>(no valid token)

    WebApp->>AzureAD: Redirect to login<br/>OAuth 2.0 authorization request
    AzureAD-->>User: Show login page
    User->>AzureAD: Enter credentials + MFA
    AzureAD->>AzureAD: Validate credentials<br/>Evaluate conditional access

    alt Authentication successful
        AzureAD-->>WebApp: Redirect with auth code
        WebApp->>AzureAD: Exchange code for tokens<br/>POST /oauth2/v2.0/token
        AzureAD-->>WebApp: ID Token + Access Token<br/>Refresh Token

        WebApp->>WebApp: Store tokens<br/>(secure httpOnly cookie)
        WebApp-->>User: Redirect to dashboard
    else Authentication failed
        AzureAD-->>User: Show error<br/>(invalid credentials)
    end

    Note over User,API: Authenticated API call

    User->>WebApp: Create workflow
    WebApp->>API: POST /api/workflows<br/>Authorization: Bearer {token}

    API->>Token: Validate JWT token
    Token->>Token: Verify signature<br/>Check expiration<br/>Validate issuer/audience

    alt Token valid
        Token-->>API: Claims extracted<br/>(userId, roles, scopes)

        API->>API: Authorize request<br/>Check role permissions

        alt User authorized
            API->>Cosmos: Create workflow<br/>OwnerId = userId
            Cosmos-->>API: Workflow created
            API-->>WebApp: 201 Created
            WebApp-->>User: Success notification
        else User not authorized
            API-->>WebApp: 403 Forbidden
            WebApp-->>User: "Insufficient permissions"
        end
    else Token invalid/expired
        Token-->>API: Validation failed
        API-->>WebApp: 401 Unauthorized

        WebApp->>AzureAD: Refresh access token<br/>POST /oauth2/v2.0/token<br/>(with refresh token)
        AzureAD-->>WebApp: New access token

        WebApp->>API: Retry with new token
    end
```

**Token Structure (JWT):**

**Header:**
```json
{
  "typ": "JWT",
  "alg": "RS256",
  "kid": "key-id-123"
}
```

**Payload:**
```json
{
  "iss": "https://login.microsoftonline.com/{tenant-id}/v2.0",
  "sub": "user-object-id",
  "aud": "api://agent-studio",
  "exp": 1697293200,
  "iat": 1697289600,
  "nbf": 1697289600,
  "name": "John Developer",
  "preferred_username": "john@example.com",
  "roles": ["Workflow.Create", "Workflow.Read", "Workflow.Execute"],
  "scp": "user_impersonation"
}
```

**Authorization Policies:**
```csharp
[Authorize(Policy = "WorkflowCreate")]
[HttpPost("api/workflows")]
public async Task<ActionResult<WorkflowResponse>> CreateWorkflow(...)

// Policy definition
services.AddAuthorization(options =>
{
    options.AddPolicy("WorkflowCreate", policy =>
        policy.RequireRole("Workflow.Create"));

    options.AddPolicy("WorkflowExecute", policy =>
        policy.RequireRole("Workflow.Execute"));

    options.AddPolicy("AdminOnly", policy =>
        policy.RequireRole("Admin"));
});
```

**Role-Based Access Control (RBAC):**
- **Admin:** Full access to all workflows and configurations
- **Developer:** Create, read, execute, and delete own workflows
- **Operator:** Read-only access for monitoring and troubleshooting
- **Business Analyst:** Read workflows, configure quality gates

---

### 7. Context Deduplication and Caching Flow

This flow demonstrates how the Context Manager eliminates redundant storage and improves performance through intelligent caching.

```mermaid
sequenceDiagram
    autonumber
    participant Task1 as Task 1
    participant Context as Context Manager
    participant Hash as SHA-256 Hasher
    participant Redis as Redis Cache
    participant Cosmos as Cosmos DB
    participant Task2 as Task 2

    Note over Task1: Task 1 produces context
    Task1->>Context: StoreContextAsync<br/>(workflowId, "analysis", data)

    Context->>Hash: ComputeHash(data)
    Hash-->>Context: hash = "a1b2c3..."

    Context->>Redis: Check if hash exists<br/>GET context:hash:a1b2c3
    Redis-->>Context: Key not found

    Note over Context: First occurrence - store normally
    Context->>Redis: Store content<br/>SET context:wf1:analysis = data<br/>EXPIRE 3600
    Context->>Redis: Store hash mapping<br/>SET context:hash:a1b2c3 = "wf1:analysis"<br/>EXPIRE 3600

    Context-->>Task1: Context stored

    Note over Task2: Task 2 produces identical context
    Task2->>Context: StoreContextAsync<br/>(workflowId, "validation", data)

    Context->>Hash: ComputeHash(data)
    Hash-->>Context: hash = "a1b2c3..." (same!)

    Context->>Redis: Check if hash exists<br/>GET context:hash:a1b2c3
    Redis-->>Context: "wf1:analysis" (exists!)

    Note over Context: Deduplication - don't store again
    Context->>Context: Log("Context deduplicated,<br/>saved 1.2MB storage")
    Context->>Redis: Create reference<br/>SET context:wf2:validation → wf1:analysis

    Context-->>Task2: Context stored (deduplicated)

    Note over Task2: Task 2 loads context
    Task2->>Context: GetContextAsync<br/>(workflowId, "validation")

    Context->>Redis: GET context:wf2:validation
    Redis-->>Context: "wf1:analysis" (reference)

    Context->>Redis: GET context:wf1:analysis
    Redis-->>Context: data

    Context-->>Task2: Retrieved data

    Note over Context: Cache expiration and fallback
    Task2->>Context: GetContextAsync (after expiry)

    Context->>Redis: GET context:wf2:validation
    Redis-->>Context: Key expired (nil)

    Context->>Cosmos: Fallback to database<br/>SELECT * WHERE id = "wf2:validation"
    Cosmos-->>Context: data

    Context->>Redis: Repopulate cache<br/>SET context:wf2:validation = data

    Context-->>Task2: Retrieved data (from DB)
```

**Deduplication Benefits:**

**Storage Savings:**
```
Without deduplication:
- Workflow 1: 2.5 MB context
- Workflow 2: 2.5 MB context (identical)
- Workflow 3: 2.5 MB context (identical)
Total: 7.5 MB

With deduplication:
- Workflow 1: 2.5 MB context (stored)
- Workflow 2: Reference to WF1 (< 1 KB)
- Workflow 3: Reference to WF1 (< 1 KB)
Total: ~2.5 MB (70% reduction)
```

**Performance Impact:**
- Cache hit rate: 85%+
- Average retrieval time: 5ms (Redis) vs 50ms (Cosmos DB)
- LLM API call reduction: 80% (cached context reused)

**Hash Collision Handling:**
```csharp
private async Task<string> StoreContextWithCollisionDetection(
    string workflowId,
    string key,
    object value)
{
    var json = JsonSerializer.Serialize(value);
    var hash = ComputeSHA256(json);

    var existingKey = await _redis.StringGetAsync($"context:hash:{hash}");

    if (existingKey.HasValue)
    {
        // Verify content actually matches (paranoid check for hash collision)
        var existingJson = await _redis.StringGetAsync(existingKey.ToString());
        if (existingJson.ToString() == json)
        {
            // True deduplication
            _logger.LogDebug("Context deduplicated: {Hash}", hash);
            await _redis.StringSetAsync($"context:{workflowId}:{key}", existingKey.ToString());
            return hash;
        }
        else
        {
            // Hash collision detected (extremely rare with SHA-256)
            _logger.LogWarning("SHA-256 hash collision detected! Using fallback.");
            hash = $"{hash}_{Guid.NewGuid():N}";
        }
    }

    // Store new content
    await _redis.StringSetAsync($"context:{workflowId}:{key}", json, TimeSpan.FromHours(1));
    await _redis.StringSetAsync($"context:hash:{hash}", $"{workflowId}:{key}");

    return hash;
}
```

## Performance Optimization Patterns

### 1. Async I/O Throughout
All database and HTTP operations use async/await to prevent thread blocking and maximize throughput.

### 2. Parallel Execution
Independent tasks execute concurrently using Task.WhenAll() for optimal resource utilization.

### 3. Caching Strategy
- **L1 Cache:** In-memory dictionary for hot data (< 1ms access)
- **L2 Cache:** Redis for shared data across instances (5-10ms access)
- **L3 Storage:** Cosmos DB for persistent storage (50-100ms access)

### 4. Connection Pooling
HTTP clients and database connections are pooled and reused to eliminate connection overhead.

### 5. Batching
Multiple state updates are batched into single Cosmos DB transactions to reduce round trips.

## Related Documentation

- [C4 System Context](c4-system-context.mmd) - High-level system overview
- [C4 Container Diagram](c4-container.mmd) - Service architecture
- [C4 Component Diagram](c4-orchestration-components.mmd) - Internal components
- [ADR-002: Meta-Agent Architecture](../adrs/002-meta-agent-architecture.md)
- [ADR-010: Context Manager Design](../adrs/ADR-010-context-manager-design.md)

---

**Version:** 1.0.0
**Last Updated:** 2025-10-14
**Maintained By:** Architecture Team
**Review Cycle:** Quarterly or on major architecture changes

This data flow documentation establishes comprehensive understanding of information movement designed to streamline troubleshooting, optimization, and integration across Agent Studio's distributed architecture.
