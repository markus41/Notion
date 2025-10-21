# Data Flow Between Components

## Table of Contents

- [Overview](#overview)
- [Workflow Execution Flow](#workflow-execution-flow)
- [Agent-to-Agent Communication](#agent-to-agent-communication)
- [State Management Flow](#state-management-flow)
- [Real-time Update Flow](#real-time-update-flow)
- [Authentication Data Flow](#authentication-data-flow)
- [Error Propagation Flow](#error-propagation-flow)
- [Telemetry and Observability Flow](#telemetry-and-observability-flow)

## Overview

This document describes how data flows through the Meta-Agent Platform, from user interaction through the frontend, orchestration in .NET, execution in Python, and back to the user.

### Key Data Flow Patterns

1. **Request-Response**: Synchronous REST API calls for immediate operations
2. **Streaming**: Server-sent events for long-running agent executions
3. **Pub-Sub**: SignalR for real-time workflow updates
4. **Event-Driven**: Message queue for async background processing
5. **State Persistence**: Checkpointing for workflow resumption

## Workflow Execution Flow

### Complete Workflow Execution

```
┌──────────┐
│   User   │
└────┬─────┘
     │ 1. Click "Execute Workflow"
     ▼
┌────────────────────────────────┐
│  React Frontend                │
│                                │
│  - Validate workflow config    │
│  - Show loading state          │
│  - Establish SignalR conn      │
└────────┬───────────────────────┘
         │ 2. POST /api/v1/workflows/{id}/execute
         │    { parameters: {...} }
         ▼
┌────────────────────────────────┐
│  .NET Orchestration API        │
│                                │
│  ┌──────────────────────────┐ │
│  │ 1. Authenticate user     │ │
│  │ 2. Authorize operation   │ │
│  │ 3. Validate workflow     │ │
│  │ 4. Create execution ID   │ │
│  │ 5. Persist initial state │ │ ◄──┐
│  └──────────────────────────┘ │   │ 3. Write
│                                │   │    execution_id: "exec-123"
│  ┌──────────────────────────┐ │   │    status: "running"
│  │ Workflow Orchestrator    │ │   │    started_at: <timestamp>
│  │                          │ │   │
│  │ For each step:           │ │   ▼
│  │  - Get agent config      │ │ ┌──────────────┐
│  │  - Build exec request    │ │ │  Cosmos DB   │
│  │  - Call Python service   │ │ │              │
│  │  - Save checkpoint       │ │ │ Executions   │
│  │  - Broadcast update      │ │ │ Container    │
│  └──────────┬───────────────┘ │ └──────────────┘
└─────────────┼──────────────────┘
              │ 4. POST /agents/execute
              │    {
              │      agent_id: "agent-1",
              │      agent_type: "analyzer",
              │      parameters: {...},
              │      context: {...}
              │    }
              ▼
┌────────────────────────────────┐
│  Python Agent Service          │
│                                │
│  ┌──────────────────────────┐ │
│  │ 1. Validate request      │ │
│  │ 2. Get agent executor    │ │
│  │ 3. Build LLM prompt      │ │
│  └──────────┬───────────────┘ │
│             │ 5. Chat completion request
│             ▼                  │
│  ┌──────────────────────────┐ │
│  │ Azure OpenAI Integration │ │───┐
│  │                          │ │   │ 6. API call
│  │ - Streaming enabled      │ │   │    model: "gpt-4"
│  │ - Token tracking         │ │   │    messages: [...]
│  │ - Error handling         │ │   │
│  └──────────┬───────────────┘ │   ▼
│             │                  │ ┌──────────────────┐
│             │ 7. Stream chunks │ │  Azure OpenAI    │
│             │    <──────────────┼─┤                  │
│             ▼                  │ └──────────────────┘
│  ┌──────────────────────────┐ │
│  │ 8. Process response      │ │
│  │ 9. Extract result        │ │
│  │ 10. Store artifacts      │ │──┐
│  └──────────┬───────────────┘ │  │ 11. Upload
│             │                  │  │     blob_path: "results/exec-123/step-1.json"
│             │ 12. Return result│  ▼
│             │    {             │ ┌──────────────┐
│             │      status: "completed" │  Blob Storage │
│             │      result: {...}│ │              │
│             │      execution_time: 5.2│ Artifacts    │
│             │    }             │ └──────────────┘
└─────────────┼──────────────────┘
              │ 13. AgentExecutionResult
              ▼
┌────────────────────────────────┐
│  .NET Orchestration API        │
│                                │
│  ┌──────────────────────────┐ │
│  │ 14. Process result       │ │
│  │ 15. Update state         │ │──┐
│  │ 16. Save checkpoint      │ │  │ 16. Update
│  └──────────┬───────────────┘ │  │     step_1_result: {...}
│             │                  │  │     current_step: 2
│             │ 17. Broadcast via SignalR  ▼
│             │    "WorkflowProgress"│ ┌──────────────┐
│             │    {             │ │  Cosmos DB   │
│             │      step: 1,    │ │              │
│             │      status: "completed"│  Checkpoints │
│             │    }             │ └──────────────┘
└─────────────┼──────────────────┘
              │ 18. SignalR message
              ▼
┌────────────────────────────────┐
│  SignalR Service (Azure)       │
│                                │
│  - Connection routing          │
│  - Message broadcasting        │
│  - Connection scaling          │
└────────┬───────────────────────┘
         │ 19. WebSocket push
         ▼
┌────────────────────────────────┐
│  React Frontend                │
│                                │
│  - Receive update via SignalR  │
│  - Update workflow state       │
│  - Render progress UI          │
│  - Append to execution log     │
└────────────────────────────────┘
         │
         │ (Repeat steps 4-19 for each workflow step)
         │
         ▼
┌────────────────────────────────┐
│  .NET Orchestration API        │
│                                │
│  20. All steps completed       │
│  21. Finalize workflow         │
│  22. Send "WorkflowCompleted"  │
└────────┬───────────────────────┘
         │ 23. Final SignalR message
         ▼
┌────────────────────────────────┐
│  React Frontend                │
│                                │
│  - Display completion          │
│  - Show final results          │
│  - Enable result download      │
└────────────────────────────────┘
```

### Detailed Step Breakdown

#### Step 1-2: User Initiates Workflow

**Frontend**:
```typescript
const executeWorkflow = async (workflowId: string, params: Record<string, any>) => {
  const response = await fetch(`/api/v1/workflows/${workflowId}/execute`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${accessToken}`,
    },
    body: JSON.stringify({ parameters: params }),
  });

  const execution = await response.json();
  return execution.id; // "exec-123"
};
```

#### Step 3-5: .NET Creates Execution Record

**.NET Controller**:
```csharp
[HttpPost("{workflowId}/execute")]
public async Task<IActionResult> ExecuteWorkflow(
    string workflowId,
    [FromBody] WorkflowExecutionRequest request)
{
    using var activity = ActivitySource.StartActivity("ExecuteWorkflow");

    // 1. Get workflow definition
    var workflow = await _workflowRepository.GetByIdAsync(workflowId);

    // 2. Create execution record
    var execution = new WorkflowExecution
    {
        Id = Guid.NewGuid().ToString("N"),
        WorkflowId = workflowId,
        Status = ExecutionStatus.Running,
        StartedAt = DateTime.UtcNow,
        Parameters = request.Parameters,
        UserId = User.GetUserId(),
    };

    // 3. Persist to Cosmos DB
    await _executionRepository.CreateAsync(execution);

    // 4. Queue for background execution
    await _executionQueue.EnqueueAsync(execution.Id);

    // 5. Return immediately (async execution)
    return Accepted(new { executionId = execution.Id });
}
```

#### Step 4-12: Python Executes Agent

**Python Agent Execution**:
```python
@app.post("/agents/execute")
async def execute_agent(request: AgentExecutionRequest) -> AgentExecutionResult:
    start_time = time.time()

    with tracer.start_as_current_span("execute_agent") as span:
        span.set_attribute("agent.id", request.agent_id)

        # 1. Get agent configuration
        agent_config = await agent_store.get(request.agent_id)

        # 2. Build LLM messages
        messages = build_messages(agent_config, request.parameters)

        # 3. Call Azure OpenAI
        response = await openai_client.chat.completions.create(
            model=agent_config.model,
            messages=messages,
            temperature=agent_config.temperature,
        )

        # 4. Extract and process result
        result = process_llm_response(response)

        # 5. Store artifacts if needed
        if result.artifacts:
            await blob_storage.upload(
                container="results",
                blob_name=f"{request.execution_id}/{request.agent_id}.json",
                data=json.dumps(result.artifacts),
            )

        execution_time = time.time() - start_time

        return AgentExecutionResult(
            agent_id=request.agent_id,
            status="completed",
            result=result.dict(),
            execution_time=execution_time,
        )
```

#### Step 13-19: .NET Broadcasts Updates

**.NET Background Service**:
```csharp
public class WorkflowExecutionService : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await foreach (var executionId in _executionQueue.DequeueAsync(stoppingToken))
        {
            await ExecuteWorkflowAsync(executionId, stoppingToken);
        }
    }

    private async Task ExecuteWorkflowAsync(string executionId, CancellationToken cancellationToken)
    {
        var execution = await _executionRepository.GetByIdAsync(executionId);
        var workflow = await _workflowRepository.GetByIdAsync(execution.WorkflowId);

        for (int stepIndex = 0; stepIndex < workflow.Steps.Count; stepIndex++)
        {
            var step = workflow.Steps[stepIndex];

            // Broadcast step start
            await _hubContext.Clients
                .Group($"workflow_{execution.WorkflowId}")
                .SendAsync("WorkflowProgress", new
                {
                    ExecutionId = executionId,
                    CurrentStep = stepIndex,
                    TotalSteps = workflow.Steps.Count,
                    Status = "executing",
                    StepName = step.Name,
                }, cancellationToken);

            // Execute step via Python service
            var agentResult = await _pythonClient.ExecuteAgentAsync(new AgentExecutionRequest
            {
                AgentId = step.AgentId,
                AgentType = step.AgentType,
                Parameters = BuildStepParameters(step, execution),
                Context = new { ExecutionId = executionId, StepIndex = stepIndex },
            }, cancellationToken);

            // Save checkpoint
            execution.State.StepResults[stepIndex] = agentResult;
            execution.State.CurrentStep = stepIndex + 1;
            await _executionRepository.UpdateAsync(execution);

            // Broadcast step completion
            await _hubContext.Clients
                .Group($"workflow_{execution.WorkflowId}")
                .SendAsync("WorkflowProgress", new
                {
                    ExecutionId = executionId,
                    CurrentStep = stepIndex,
                    TotalSteps = workflow.Steps.Count,
                    Status = "completed",
                    StepName = step.Name,
                    Result = agentResult,
                }, cancellationToken);
        }

        // Mark execution complete
        execution.Status = ExecutionStatus.Completed;
        execution.CompletedAt = DateTime.UtcNow;
        await _executionRepository.UpdateAsync(execution);

        // Broadcast workflow completion
        await _hubContext.Clients
            .Group($"workflow_{execution.WorkflowId}")
            .SendAsync("WorkflowCompleted", new
            {
                ExecutionId = executionId,
                Status = execution.Status,
                Result = execution.State.StepResults,
                Duration = (execution.CompletedAt - execution.StartedAt).Value.TotalSeconds,
            }, cancellationToken);
    }
}
```

## Agent-to-Agent Communication

### Sequential Workflow Pattern

In a sequential workflow, agents pass data through the orchestrator:

```
Agent A → .NET Orchestrator → Agent B → .NET Orchestrator → Agent C
```

**Data Flow**:
```json
// Step 1: Agent A executes
{
  "agent_id": "analyzer-agent",
  "parameters": { "data": "input data" },
  "result": {
    "analysis": { "sentiment": "positive", "topics": ["tech", "AI"] }
  }
}

// Step 2: .NET maps Agent A output to Agent B input
{
  "agent_id": "processor-agent",
  "parameters": {
    "sentiment": "positive",  // From Agent A result
    "topics": ["tech", "AI"]  // From Agent A result
  },
  "result": {
    "processed_data": { ... }
  }
}

// Step 3: Agent C receives combined context
{
  "agent_id": "validator-agent",
  "parameters": {
    "original_data": "input data",      // From workflow input
    "analysis": { ... },                 // From Agent A
    "processed_data": { ... }            // From Agent B
  }
}
```

### Concurrent Workflow Pattern

In concurrent workflows, agents execute in parallel:

```
            ┌─→ Agent A ─┐
Orchestrator┼─→ Agent B ─┼→ Aggregator Agent
            └─→ Agent C ─┘
```

**Data Flow**:
```csharp
// .NET spawns parallel tasks
var tasks = workflow.Steps.Select(async step =>
{
    var result = await _pythonClient.ExecuteAgentAsync(new AgentExecutionRequest
    {
        AgentId = step.AgentId,
        Parameters = execution.Parameters, // Same input for all
    });

    return (step.Id, result);
}).ToArray();

var results = await Task.WhenAll(tasks);

// Aggregate results
var aggregatedResult = new Dictionary<string, object>();
foreach (var (stepId, result) in results)
{
    aggregatedResult[stepId] = result;
}

// Pass to aggregator agent
var finalResult = await _pythonClient.ExecuteAgentAsync(new AgentExecutionRequest
{
    AgentId = "aggregator-agent",
    Parameters = aggregatedResult,
});
```

### Group Chat Pattern

In group chat, agents communicate through shared context:

```
Agent A ──┐
          ├──→ Shared Context ←──┐
Agent B ──┘                       │
                                  │
Agent C ──→ Moderator Agent ──────┘
```

**Data Flow**:
```python
# Python manages group chat state
class GroupChatState:
    def __init__(self):
        self.messages: List[AgentMessage] = []
        self.context: Dict[str, Any] = {}
        self.turn_order: List[str] = []

async def execute_group_chat(
    agents: List[Agent],
    initial_message: str,
    max_turns: int = 10
) -> GroupChatResult:
    state = GroupChatState()
    state.messages.append(SystemMessage(content=initial_message))

    for turn in range(max_turns):
        # Moderator selects next agent
        next_agent_id = await select_next_speaker(state)

        # Agent processes full conversation history
        agent_response = await agents[next_agent_id].process(
            messages=state.messages,
            context=state.context,
        )

        # Add to shared state
        state.messages.append(agent_response)
        state.context.update(agent_response.context_updates)

        # Check termination condition
        if should_terminate(state):
            break

    return GroupChatResult(
        messages=state.messages,
        final_context=state.context,
        turns_taken=len(state.messages),
    )
```

## State Management Flow

### Workflow State Lifecycle

```
1. Create Execution
   ├─ Generate execution ID
   ├─ Initialize state object
   └─ Persist to Cosmos DB

2. Execute Steps
   ├─ Load current state
   ├─ Execute agent
   ├─ Merge result into state
   ├─ Save checkpoint (superstep)
   └─ Continue to next step

3. Handle Failures
   ├─ Detect failure
   ├─ Load last checkpoint
   ├─ Retry from checkpoint
   └─ Update retry count

4. Complete Workflow
   ├─ Mark execution complete
   ├─ Calculate final metrics
   ├─ Archive state
   └─ Clean up resources
```

### Checkpoint Structure

```json
{
  "execution_id": "exec-12345",
  "workflow_id": "workflow-789",
  "checkpoint_id": "checkpoint-abc",
  "created_at": "2025-10-07T12:34:56Z",
  "state": {
    "current_step": 2,
    "total_steps": 5,
    "step_results": {
      "0": {
        "agent_id": "analyzer-agent",
        "status": "completed",
        "result": { "analysis": {...} },
        "execution_time": 3.2
      },
      "1": {
        "agent_id": "processor-agent",
        "status": "completed",
        "result": { "processed": {...} },
        "execution_time": 5.1
      }
    },
    "context": {
      "user_id": "user-123",
      "organization_id": "org-456",
      "custom_data": {...}
    }
  },
  "metadata": {
    "retry_count": 0,
    "total_execution_time": 8.3
  }
}
```

### State Persistence Strategy

**.NET State Manager**:
```csharp
public class WorkflowStateManager
{
    private readonly IExecutionRepository _repository;
    private readonly IDistributedCache _cache;

    public async Task SaveCheckpointAsync(WorkflowExecution execution)
    {
        // Create checkpoint document
        var checkpoint = new Checkpoint
        {
            Id = Guid.NewGuid().ToString("N"),
            ExecutionId = execution.Id,
            WorkflowId = execution.WorkflowId,
            CreatedAt = DateTime.UtcNow,
            State = execution.State,
        };

        // Persist to Cosmos DB (durable)
        await _repository.CreateCheckpointAsync(checkpoint);

        // Cache in Redis (fast access)
        await _cache.SetAsync(
            $"checkpoint:{execution.Id}:latest",
            checkpoint,
            new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(24)
            });
    }

    public async Task<Checkpoint?> GetLatestCheckpointAsync(string executionId)
    {
        // Try cache first
        var cached = await _cache.GetAsync<Checkpoint>(
            $"checkpoint:{executionId}:latest");

        if (cached != null)
            return cached;

        // Fall back to database
        var checkpoint = await _repository.GetLatestCheckpointAsync(executionId);

        if (checkpoint != null)
        {
            // Populate cache
            await _cache.SetAsync($"checkpoint:{executionId}:latest", checkpoint);
        }

        return checkpoint;
    }
}
```

## Real-time Update Flow

### SignalR Message Flow

```
.NET Service → Azure SignalR Service → All Connected Clients

Routing:
- User-specific: Group = "user_{userId}"
- Workflow-specific: Group = "workflow_{workflowId}"
- Organization-specific: Group = "org_{orgId}"
- Broadcast: All clients
```

### Message Types

**WorkflowProgress**:
```typescript
interface WorkflowProgress {
  executionId: string;
  workflowId: string;
  currentStep: number;
  totalSteps: number;
  status: 'pending' | 'executing' | 'completed' | 'failed';
  stepName: string;
  progress: number; // 0-100
}
```

**AgentMessage**:
```typescript
interface AgentMessage {
  executionId: string;
  agentId: string;
  agentName: string;
  timestamp: string;
  type: 'info' | 'warning' | 'error' | 'result';
  content: string;
  metadata?: Record<string, any>;
}
```

**WorkflowCompleted**:
```typescript
interface WorkflowCompleted {
  executionId: string;
  workflowId: string;
  status: 'completed' | 'failed' | 'cancelled';
  result: Record<string, any>;
  duration: number; // seconds
  metrics: {
    totalTokens: number;
    totalCost: number;
    stepsCompleted: number;
  };
}
```

### Frontend Update Handling

```typescript
// Real-time UI updates
const WorkflowMonitor = ({ executionId }: Props) => {
  const [progress, setProgress] = useState(0);
  const [messages, setMessages] = useState<AgentMessage[]>([]);
  const [result, setResult] = useState<any>(null);

  useEffect(() => {
    // Connect to SignalR
    const connection = new HubConnectionBuilder()
      .withUrl('/hubs/workflow')
      .build();

    connection.on('WorkflowProgress', (update: WorkflowProgress) => {
      setProgress((update.currentStep / update.totalSteps) * 100);
    });

    connection.on('AgentMessage', (message: AgentMessage) => {
      setMessages(prev => [...prev, message]);
    });

    connection.on('WorkflowCompleted', (completed: WorkflowCompleted) => {
      setResult(completed.result);
      setProgress(100);
    });

    connection.start();

    // Subscribe to this execution
    connection.invoke('SubscribeToWorkflow', executionId);

    return () => {
      connection.stop();
    };
  }, [executionId]);

  return (
    <div>
      <ProgressBar value={progress} />
      <MessageLog messages={messages} />
      {result && <ResultDisplay result={result} />}
    </div>
  );
};
```

## Authentication Data Flow

### Token Propagation

```
1. User authenticates with Azure AD
2. Frontend receives JWT access token
3. Frontend includes token in API requests:
   Authorization: Bearer <token>
4. .NET API validates token with Azure AD
5. .NET extracts user claims (user ID, roles, org ID)
6. .NET includes token when calling Python service
7. Python service optionally validates or trusts .NET
```

**.NET Token Validation**:
```csharp
// Automatic validation via middleware
app.UseAuthentication(); // Validates JWT
app.UseAuthorization();  // Checks policies

// Access user claims in controller
var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
var roles = User.FindAll(ClaimTypes.Role).Select(c => c.Value);
var organizationId = User.FindFirst("organization_id")?.Value;
```

**Python Token Forwarding**:
```python
# .NET forwards token to Python
headers = {
    "Authorization": f"Bearer {access_token}",
    "X-User-Id": user_id,
    "X-Organization-Id": organization_id,
}

response = await httpx.post(
    f"{python_service_url}/agents/execute",
    headers=headers,
    json=request_body,
)
```

## Error Propagation Flow

### Error Flow Diagram

```
Python Service (Error occurs)
    │
    │ 1. Catch exception
    │ 2. Log with OpenTelemetry
    │ 3. Return error response (HTTP 500/400)
    │
    ▼
.NET Orchestration API
    │
    │ 4. Receive error response
    │ 5. Parse error details
    │ 6. Log with correlation ID
    │ 7. Decide: retry or fail workflow
    │
    ├─ Retry? → Execute retry with backoff
    │
    └─ Fail? →  8. Update execution status = "failed"
                9. Save error details
                10. Broadcast error via SignalR
                │
                ▼
React Frontend
    │
    │ 11. Receive error notification
    │ 12. Display error to user
    │ 13. Offer retry or cancel
```

### Error Response Format

**Python Error Response**:
```json
{
  "detail": "Agent execution failed: OpenAI API rate limit exceeded",
  "error_type": "RateLimitError",
  "status_code": 429,
  "trace_id": "a1b2c3d4e5f6g7h8i9j0",
  "retry_after": 30,
  "metadata": {
    "agent_id": "analyzer-agent",
    "model": "gpt-4"
  }
}
```

**.NET Error Handling**:
```csharp
try
{
    var result = await _pythonClient.ExecuteAgentAsync(request);
}
catch (PythonServiceException ex) when (ex.StatusCode == 429)
{
    // Rate limit error - retry with backoff
    var retryAfter = ex.RetryAfter ?? 30;
    await Task.Delay(TimeSpan.FromSeconds(retryAfter));
    return await RetryExecutionAsync(request);
}
catch (PythonServiceException ex) when (ex.StatusCode >= 400 && ex.StatusCode < 500)
{
    // Client error - don't retry, fail workflow
    await FailWorkflowAsync(execution.Id, ex.Message);
    throw;
}
catch (HttpRequestException ex)
{
    // Network error - retry with circuit breaker
    _logger.LogWarning("Network error calling Python service, will retry");
    throw;
}
```

## Telemetry and Observability Flow

### Distributed Tracing Flow

```
Frontend (Trace ID generated)
    │
    │ trace_id: abc123
    │ span_id: span-001
    │
    ▼ HTTP Request (trace_id in header)
.NET API (Continues trace)
    │
    │ trace_id: abc123 (same)
    │ span_id: span-002 (new)
    │ parent_span_id: span-001
    │
    ▼ HTTP Request (trace_id forwarded)
Python Service (Continues trace)
    │
    │ trace_id: abc123 (same)
    │ span_id: span-003 (new)
    │ parent_span_id: span-002
    │
    ▼ All spans exported
Application Insights
    │
    └─→ Correlated trace with all spans
```

### OpenTelemetry Context Propagation

**.NET Span Creation**:
```csharp
using var activity = ActivitySource.StartActivity("ExecuteWorkflow");
activity?.SetTag("workflow.id", workflowId);
activity?.SetTag("user.id", userId);

// Trace ID automatically propagated to outgoing HTTP requests
var result = await _httpClient.PostAsJsonAsync("/agents/execute", request);
```

**Python Span Extraction**:
```python
from opentelemetry.propagate import extract

# Extract trace context from incoming request headers
context = extract(request.headers)

with tracer.start_as_current_span(
    "execute_agent",
    context=context  # Continue parent trace
) as span:
    span.set_attribute("agent.id", agent_id)
    # ... execution
```

### Metrics Collection

**Custom Metrics**:
```csharp
// .NET custom metrics
var meter = new Meter("AgentStudio.Workflows");

var executionCounter = meter.CreateCounter<long>(
    "workflow.executions",
    description: "Total workflow executions");

var executionDuration = meter.CreateHistogram<double>(
    "workflow.execution.duration",
    unit: "s",
    description: "Workflow execution duration in seconds");

// Record metrics
executionCounter.Add(1, new("workflow.id", workflowId), new("status", "completed"));
executionDuration.Record(duration, new("workflow.id", workflowId));
```

---

**Related Documentation**:
- [Architecture Overview](ARCHITECTURE.md)
- [Integration Guide](INTEGRATION.md)
- [Deployment Guide](DEPLOYMENT.md)

**Last Updated**: 2025-10-07
**Version**: 1.0.0
