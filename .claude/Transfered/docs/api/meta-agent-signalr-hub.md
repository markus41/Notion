# Meta-Agent SignalR Hub Contract

## Overview

Real-time bidirectional communication between the .NET orchestrator and React frontend for meta-agent workflows. This hub extends the base AgentStudio SignalR hub with meta-agent specific events and methods.

**Hub URL**: `wss://api.agentstudio.dev/hubs/meta-agents`

**Authentication**: JWT Bearer token via query string or headers

**WebSocket Protocol**: SignalR over WebSocket with fallback to Server-Sent Events (SSE) and Long Polling

---

## Connection Setup

### TypeScript/React Client

```typescript
import { HubConnectionBuilder, LogLevel, HubConnection } from '@microsoft/signalr';

class MetaAgentHubClient {
  private connection: HubConnection;

  constructor(accessToken: string) {
    this.connection = new HubConnectionBuilder()
      .withUrl('/hubs/meta-agents', {
        accessTokenFactory: () => accessToken,
        // Optional: Configure transport fallback
        transport: HttpTransportType.WebSockets | HttpTransportType.ServerSentEvents
      })
      .withAutomaticReconnect({
        // Exponential backoff: 0s, 2s, 10s, 30s
        nextRetryDelayInMilliseconds: (retryContext) => {
          if (retryContext.elapsedMilliseconds < 60000) {
            return Math.min(1000 * Math.pow(2, retryContext.previousRetryCount), 30000);
          } else {
            return null; // Stop reconnecting after 1 minute
          }
        }
      })
      .configureLogging(LogLevel.Information)
      .build();

    this.setupEventHandlers();
  }

  private setupEventHandlers() {
    // Workflow events
    this.connection.on('WorkflowStarted', this.onWorkflowStarted);
    this.connection.on('WorkflowCompleted', this.onWorkflowCompleted);
    this.connection.on('WorkflowFailed', this.onWorkflowFailed);
    this.connection.on('WorkflowProgress', this.onWorkflowProgress);

    // Agent events
    this.connection.on('AgentStarted', this.onAgentStarted);
    this.connection.on('AgentCompleted', this.onAgentCompleted);
    this.connection.on('AgentFailed', this.onAgentFailed);
    this.connection.on('AgentThought', this.onAgentThought);

    // Handoff events
    this.connection.on('HandoffRequested', this.onHandoffRequested);
    this.connection.on('HandoffCompleted', this.onHandoffCompleted);

    // Artifact events
    this.connection.on('ArtifactGenerated', this.onArtifactGenerated);

    // System events
    this.connection.on('ErrorOccurred', this.onError);
    this.connection.on('MetricUpdated', this.onMetricUpdated);

    // Reconnection events
    this.connection.onreconnecting((error) => {
      console.warn('SignalR reconnecting...', error);
    });

    this.connection.onreconnected((connectionId) => {
      console.log('SignalR reconnected:', connectionId);
      this.resubscribeToWorkflows();
    });

    this.connection.onclose((error) => {
      console.error('SignalR connection closed:', error);
    });
  }

  async start(): Promise<void> {
    await this.connection.start();
    console.log('Meta-Agent Hub connected');
  }

  async stop(): Promise<void> {
    await this.connection.stop();
  }

  // Event handlers (to be overridden or passed as callbacks)
  private onWorkflowStarted = (event: WorkflowStartedEvent) => {};
  private onWorkflowCompleted = (event: WorkflowCompletedEvent) => {};
  private onWorkflowFailed = (event: WorkflowFailedEvent) => {};
  private onWorkflowProgress = (event: WorkflowProgressEvent) => {};
  private onAgentStarted = (event: AgentStartedEvent) => {};
  private onAgentCompleted = (event: AgentCompletedEvent) => {};
  private onAgentFailed = (event: AgentFailedEvent) => {};
  private onAgentThought = (event: AgentThoughtEvent) => {};
  private onHandoffRequested = (event: HandoffRequestedEvent) => {};
  private onHandoffCompleted = (event: HandoffCompletedEvent) => {};
  private onArtifactGenerated = (event: ArtifactGeneratedEvent) => {};
  private onError = (event: ErrorEvent) => {};
  private onMetricUpdated = (event: MetricUpdateEvent) => {};

  // Client-to-server methods
  async subscribeToWorkflow(workflowId: string): Promise<void> {
    await this.connection.invoke('SubscribeToWorkflow', workflowId);
  }

  async unsubscribeFromWorkflow(workflowId: string): Promise<void> {
    await this.connection.invoke('UnsubscribeFromWorkflow', workflowId);
  }

  async subscribeToAgent(agentId: string): Promise<void> {
    await this.connection.invoke('SubscribeToAgent', agentId);
  }

  async unsubscribeFromAgent(agentId: string): Promise<void> {
    await this.connection.invoke('UnsubscribeFromAgent', agentId);
  }

  async subscribeToThoughts(workflowId: string): Promise<void> {
    await this.connection.invoke('SubscribeToThoughts', workflowId);
  }

  async unsubscribeFromThoughts(workflowId: string): Promise<void> {
    await this.connection.invoke('UnsubscribeFromThoughts', workflowId);
  }

  async getWorkflowStatus(workflowId: string): Promise<WorkflowStatusResponse> {
    return await this.connection.invoke('GetWorkflowStatus', workflowId);
  }

  async getAgentStatus(agentId: string): Promise<AgentStatusResponse> {
    return await this.connection.invoke('GetAgentStatus', agentId);
  }

  private resubscribeToWorkflows() {
    // Re-subscribe to workflows after reconnection
    // Implementation depends on your state management
  }
}
```

### C# .NET Server Hub

```csharp
using Microsoft.AspNetCore.SignalR;
using Microsoft.AspNetCore.Authorization;
using AgentStudio.Api.Models.MetaAgent;

namespace AgentStudio.Api.Hubs;

/// <summary>
/// SignalR hub for meta-agent real-time communication
/// </summary>
[Authorize]
public class MetaAgentHub : Hub
{
    private readonly ILogger<MetaAgentHub> _logger;
    private readonly IWorkflowService _workflowService;
    private readonly IAgentService _agentService;

    public MetaAgentHub(
        ILogger<MetaAgentHub> logger,
        IWorkflowService workflowService,
        IAgentService agentService)
    {
        _logger = logger;
        _workflowService = workflowService;
        _agentService = agentService;
    }

    /// <summary>
    /// Subscribe to all events for a specific workflow
    /// </summary>
    public async Task SubscribeToWorkflow(string workflowId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"workflow:{workflowId}");
        _logger.LogInformation("Client {ConnectionId} subscribed to workflow {WorkflowId}",
            Context.ConnectionId, workflowId);
    }

    /// <summary>
    /// Unsubscribe from workflow events
    /// </summary>
    public async Task UnsubscribeFromWorkflow(string workflowId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"workflow:{workflowId}");
        _logger.LogInformation("Client {ConnectionId} unsubscribed from workflow {WorkflowId}",
            Context.ConnectionId, workflowId);
    }

    /// <summary>
    /// Subscribe to specific agent events
    /// </summary>
    public async Task SubscribeToAgent(string agentId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"agent:{agentId}");
        _logger.LogInformation("Client {ConnectionId} subscribed to agent {AgentId}",
            Context.ConnectionId, agentId);
    }

    /// <summary>
    /// Unsubscribe from agent events
    /// </summary>
    public async Task UnsubscribeFromAgent(string agentId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"agent:{agentId}");
    }

    /// <summary>
    /// Subscribe to agent thought stream for a workflow
    /// </summary>
    public async Task SubscribeToThoughts(string workflowId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"thoughts:{workflowId}");
        _logger.LogInformation("Client {ConnectionId} subscribed to thoughts for workflow {WorkflowId}",
            Context.ConnectionId, workflowId);
    }

    /// <summary>
    /// Unsubscribe from thought stream
    /// </summary>
    public async Task UnsubscribeFromThoughts(string workflowId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"thoughts:{workflowId}");
    }

    /// <summary>
    /// Get current workflow status (synchronous query)
    /// </summary>
    public async Task<WorkflowStatusResponse> GetWorkflowStatus(string workflowId)
    {
        var workflow = await _workflowService.GetWorkflowAsync(workflowId);
        return new WorkflowStatusResponse(
            workflow.WorkflowId,
            workflow.Status,
            workflow.Progress,
            workflow.Agents.Select(a => new AgentStatusInfo(a.AgentId, a.Status)).ToList()
        );
    }

    /// <summary>
    /// Get current agent status (synchronous query)
    /// </summary>
    public async Task<AgentStatusResponse> GetAgentStatus(string agentId)
    {
        var agent = await _agentService.GetAgentAsync(agentId);
        return new AgentStatusResponse(
            agent.AgentId,
            agent.Type,
            agent.Status,
            agent.CurrentTask
        );
    }

    public override async Task OnConnectedAsync()
    {
        _logger.LogInformation("Client connected: {ConnectionId}, User: {User}",
            Context.ConnectionId, Context.User?.Identity?.Name);
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        _logger.LogInformation("Client disconnected: {ConnectionId}, Reason: {Exception}",
            Context.ConnectionId, exception?.Message);
        await base.OnDisconnectedAsync(exception);
    }
}
```

---

## Server-to-Client Events

### 1. WorkflowStarted

Sent when a workflow begins execution.

**Event Name**: `WorkflowStarted`

**Payload**:
```typescript
interface WorkflowStartedEvent {
  workflowId: string;
  type: 'sequential' | 'parallel' | 'iterative' | 'dynamic';
  description: string;
  agents: Array<{
    agentId: string;
    type: 'architect' | 'builder' | 'validator' | 'scribe';
    status: 'pending';
  }>;
  startedAt: string; // ISO 8601 datetime
  estimatedCompletion?: string; // ISO 8601 datetime
}
```

**Example**:
```typescript
connection.on('WorkflowStarted', (event: WorkflowStartedEvent) => {
  console.log(`Workflow ${event.workflowId} started`);
  updateWorkflowStatus(event.workflowId, 'running');
  showNotification(`Started: ${event.description}`);
});
```

---

### 2. WorkflowCompleted

Sent when a workflow completes successfully.

**Event Name**: `WorkflowCompleted`

**Payload**:
```typescript
interface WorkflowCompletedEvent {
  workflowId: string;
  status: 'completed';
  completedAt: string;
  durationSeconds: number;
  summary: {
    totalAgents: number;
    successfulAgents: number;
    artifactsGenerated: number;
  };
  results?: Record<string, any>; // Optional results preview
}
```

---

### 3. WorkflowFailed

Sent when a workflow fails.

**Event Name**: `WorkflowFailed`

**Payload**:
```typescript
interface WorkflowFailedEvent {
  workflowId: string;
  status: 'failed';
  failedAt: string;
  reason: string;
  failedAgent?: {
    agentId: string;
    agentType: string;
    error: string;
  };
}
```

---

### 4. WorkflowProgress

Sent periodically during workflow execution (throttled to max 1/second).

**Event Name**: `WorkflowProgress`

**Payload**:
```typescript
interface WorkflowProgressEvent {
  workflowId: string;
  timestamp: string;
  progress: {
    percentage: number; // 0-100
    currentStep: string;
    completedAgents: string[];
    pendingAgents: string[];
  };
}
```

**Example**:
```typescript
connection.on('WorkflowProgress', (event: WorkflowProgressEvent) => {
  updateProgressBar(event.workflowId, event.progress.percentage);
  updateCurrentStep(event.progress.currentStep);
});
```

---

### 5. AgentStarted

Sent when an agent begins execution within a workflow.

**Event Name**: `AgentStarted`

**Payload**:
```typescript
interface AgentStartedEvent {
  workflowId: string;
  agentId: string;
  agentType: 'architect' | 'builder' | 'validator' | 'scribe';
  taskId: string;
  startedAt: string;
  estimatedDurationSeconds?: number;
}
```

---

### 6. AgentCompleted

Sent when an agent completes its task.

**Event Name**: `AgentCompleted`

**Payload**:
```typescript
interface AgentCompletedEvent {
  workflowId: string;
  agentId: string;
  agentType: 'architect' | 'builder' | 'validator' | 'scribe';
  taskId: string;
  completedAt: string;
  durationSeconds: number;
  outputSummary: string;
  artifactsGenerated: string[]; // Artifact IDs
}
```

---

### 7. AgentFailed

Sent when an agent fails to complete its task.

**Event Name**: `AgentFailed`

**Payload**:
```typescript
interface AgentFailedEvent {
  workflowId: string;
  agentId: string;
  agentType: 'architect' | 'builder' | 'validator' | 'scribe';
  taskId: string;
  failedAt: string;
  errorType: string;
  errorMessage: string;
  isRetryable: boolean;
}
```

---

### 8. AgentThought

Sent when an agent generates a thought/reasoning step (throttled, batch delivered).

**Event Name**: `AgentThought`

**Payload**:
```typescript
interface AgentThoughtEvent {
  workflowId: string;
  agentId: string;
  agentType: 'architect' | 'builder' | 'validator' | 'scribe';
  timestamp: string;
  thoughtType: 'decision' | 'observation' | 'question' | 'implementation' | 'validation';
  content: string;
  confidence: number; // 0-1
  reasoning?: string;
}
```

**Example**:
```typescript
connection.on('AgentThought', (event: AgentThoughtEvent) => {
  addThoughtToTimeline({
    agent: event.agentType,
    time: event.timestamp,
    thought: event.content,
    confidence: event.confidence
  });
});
```

**Note**: Thoughts are batched and delivered every 2 seconds to prevent overwhelming the client.

---

### 9. HandoffRequested

Sent when an agent requests a handoff to another agent.

**Event Name**: `HandoffRequested`

**Payload**:
```typescript
interface HandoffRequestedEvent {
  workflowId: string;
  handoffId: string;
  fromAgentId: string;
  fromAgentType: string;
  toAgentType: string;
  reason: string;
  timestamp: string;
}
```

---

### 10. HandoffCompleted

Sent when a handoff is completed.

**Event Name**: `HandoffCompleted`

**Payload**:
```typescript
interface HandoffCompletedEvent {
  workflowId: string;
  handoffId: string;
  status: 'approved' | 'rejected';
  targetAgentId?: string;
  completedAt: string;
  message?: string;
}
```

---

### 11. ArtifactGenerated

Sent when an agent generates an artifact.

**Event Name**: `ArtifactGenerated`

**Payload**:
```typescript
interface ArtifactGeneratedEvent {
  workflowId: string;
  agentId: string;
  agentType: string;
  artifactId: string;
  artifactType: 'source_code' | 'test_report' | 'documentation' | 'diagram' | 'specification' | 'configuration';
  name: string;
  description?: string;
  url: string; // Download URL
  sizeBytes: number;
  createdAt: string;
}
```

**Example**:
```typescript
connection.on('ArtifactGenerated', (event: ArtifactGeneratedEvent) => {
  addArtifactToList({
    id: event.artifactId,
    name: event.name,
    type: event.artifactType,
    agent: event.agentType,
    url: event.url
  });

  // Show notification
  showNotification(`${event.agentType} generated ${event.name}`, {
    action: 'Download',
    onClick: () => downloadArtifact(event.url)
  });
});
```

---

### 12. ErrorOccurred

Sent when a system error occurs.

**Event Name**: `ErrorOccurred`

**Payload**:
```typescript
interface ErrorEvent {
  workflowId?: string;
  agentId?: string;
  timestamp: string;
  errorType: string;
  errorMessage: string;
  errorCode?: string;
  severity: 'warning' | 'error' | 'critical';
  traceId?: string;
}
```

---

### 13. MetricUpdated

Sent periodically with system/agent metrics (throttled to max 1/5 seconds).

**Event Name**: `MetricUpdated`

**Payload**:
```typescript
interface MetricUpdateEvent {
  timestamp: string;
  metricType: 'agent_health' | 'system_load' | 'task_queue';
  data: {
    agentId?: string;
    values: Record<string, number>;
  };
}
```

---

## Client-to-Server Methods

### 1. SubscribeToWorkflow

Subscribe to all events for a specific workflow.

**Method**: `SubscribeToWorkflow`

**Parameters**:
```typescript
workflowId: string
```

**Returns**: `Promise<void>`

**Example**:
```typescript
await connection.invoke('SubscribeToWorkflow', 'wf_abc123');
```

---

### 2. UnsubscribeFromWorkflow

Unsubscribe from workflow events.

**Method**: `UnsubscribeFromWorkflow`

**Parameters**:
```typescript
workflowId: string
```

**Returns**: `Promise<void>`

---

### 3. SubscribeToAgent

Subscribe to events for a specific agent.

**Method**: `SubscribeToAgent`

**Parameters**:
```typescript
agentId: string
```

**Returns**: `Promise<void>`

---

### 4. UnsubscribeFromAgent

Unsubscribe from agent events.

**Method**: `UnsubscribeFromAgent`

**Parameters**:
```typescript
agentId: string
```

**Returns**: `Promise<void>`

---

### 5. SubscribeToThoughts

Subscribe to agent thought stream for a workflow.

**Method**: `SubscribeToThoughts`

**Parameters**:
```typescript
workflowId: string
```

**Returns**: `Promise<void>`

**Note**: Thoughts are batched and throttled to prevent overwhelming the client.

---

### 6. UnsubscribeFromThoughts

Unsubscribe from thought stream.

**Method**: `UnsubscribeFromThoughts`

**Parameters**:
```typescript
workflowId: string
```

**Returns**: `Promise<void>`

---

### 7. GetWorkflowStatus

Synchronously query current workflow status.

**Method**: `GetWorkflowStatus`

**Parameters**:
```typescript
workflowId: string
```

**Returns**: `Promise<WorkflowStatusResponse>`

```typescript
interface WorkflowStatusResponse {
  workflowId: string;
  status: 'queued' | 'running' | 'completed' | 'failed' | 'cancelled';
  progress?: {
    percentage: number;
    currentStep: string;
  };
  agents: Array<{
    agentId: string;
    status: string;
  }>;
}
```

---

### 8. GetAgentStatus

Synchronously query current agent status.

**Method**: `GetAgentStatus`

**Parameters**:
```typescript
agentId: string
```

**Returns**: `Promise<AgentStatusResponse>`

```typescript
interface AgentStatusResponse {
  agentId: string;
  type: 'architect' | 'builder' | 'validator' | 'scribe';
  status: 'available' | 'busy' | 'offline';
  currentTask?: string;
}
```

---

## Group-Based Message Routing

The hub uses SignalR groups to efficiently route messages to interested clients:

| Group Pattern | Purpose | Events Sent |
|---------------|---------|-------------|
| `workflow:{workflowId}` | All workflow events | WorkflowStarted, WorkflowCompleted, WorkflowFailed, WorkflowProgress, AgentStarted, AgentCompleted, AgentFailed, HandoffRequested, HandoffCompleted, ArtifactGenerated |
| `agent:{agentId}` | Specific agent events | AgentStarted, AgentCompleted, AgentFailed, ArtifactGenerated |
| `thoughts:{workflowId}` | Agent thought stream | AgentThought (batched) |

**Server-side group broadcasting**:
```csharp
// Broadcast to all clients subscribed to a workflow
await Clients.Group($"workflow:{workflowId}").SendAsync("WorkflowProgress", progressEvent);

// Broadcast to all clients subscribed to an agent
await Clients.Group($"agent:{agentId}").SendAsync("AgentCompleted", completedEvent);

// Broadcast batched thoughts
await Clients.Group($"thoughts:{workflowId}").SendAsync("AgentThought", thoughtEvent);
```

---

## Performance Considerations

### Event Throttling

To prevent overwhelming clients, certain events are throttled:

- **WorkflowProgress**: Max 1 event/second per workflow
- **AgentThought**: Batched every 2 seconds (max 50 thoughts per batch)
- **MetricUpdated**: Max 1 event/5 seconds per metric type

### Message Batching

High-frequency events (thoughts, metrics) are batched:

```typescript
// Server-side batching example
private readonly Dictionary<string, List<AgentThought>> _thoughtBuffer = new();
private readonly Timer _thoughtBatchTimer;

public MetaAgentHub()
{
    _thoughtBatchTimer = new Timer(FlushThoughts, null, TimeSpan.FromSeconds(2), TimeSpan.FromSeconds(2));
}

private async void FlushThoughts(object? state)
{
    foreach (var (workflowId, thoughts) in _thoughtBuffer)
    {
        if (thoughts.Count > 0)
        {
            await Clients.Group($"thoughts:{workflowId}")
                .SendAsync("AgentThought", new ThoughtBatchEvent
                {
                    WorkflowId = workflowId,
                    Thoughts = thoughts.Take(50).ToList()
                });

            thoughts.Clear();
        }
    }
}
```

### Backpressure Handling

If a client cannot keep up with events, the server will:
1. Drop low-priority events (thoughts, metrics)
2. Throttle medium-priority events (progress updates)
3. Always deliver high-priority events (workflow completion, errors)

---

## Connection Management

### Automatic Reconnection

The client library handles reconnection automatically with exponential backoff:

```typescript
.withAutomaticReconnect({
  nextRetryDelayInMilliseconds: (retryContext) => {
    // Retry pattern: 0s, 2s, 10s, 30s
    if (retryContext.elapsedMilliseconds < 60000) {
      return Math.min(1000 * Math.pow(2, retryContext.previousRetryCount), 30000);
    }
    return null; // Stop after 1 minute
  }
})
```

### Resubscription After Reconnection

After reconnecting, clients must resubscribe to groups:

```typescript
connection.onreconnected((connectionId) => {
  // Resubscribe to all active workflows
  activeWorkflows.forEach(workflowId => {
    connection.invoke('SubscribeToWorkflow', workflowId);
  });
});
```

---

## Error Handling

### Server-Side Errors

If a hub method throws an exception, the client receives an error:

```typescript
try {
  await connection.invoke('GetWorkflowStatus', 'invalid-id');
} catch (error) {
  console.error('Hub method error:', error);
  // Error message from server
}
```

### Connection Errors

```typescript
connection.onclose((error) => {
  if (error) {
    console.error('Connection closed with error:', error);
    // Attempt manual reconnection or show offline UI
  }
});
```

---

## Security

### Authentication

All hub connections require JWT authentication:

```typescript
.withUrl('/hubs/meta-agents', {
  accessTokenFactory: () => getAccessToken()
})
```

### Authorization

Hub methods check user permissions:

```csharp
[Authorize(Policy = "WorkflowAccess")]
public async Task SubscribeToWorkflow(string workflowId)
{
    // Verify user has access to this workflow
    if (!await _authService.UserCanAccessWorkflow(Context.User, workflowId))
    {
        throw new HubException("Access denied to workflow");
    }

    await Groups.AddToGroupAsync(Context.ConnectionId, $"workflow:{workflowId}");
}
```

### Rate Limiting

Connections are rate-limited per user:
- Max 5 concurrent connections per user
- Max 100 method invocations per minute per connection

---

## Monitoring

### Hub Metrics

The hub emits OpenTelemetry metrics:

- `signalr.connections.active`: Active connection count
- `signalr.connections.total`: Total connections (lifetime)
- `signalr.messages.sent`: Messages sent to clients
- `signalr.messages.received`: Messages received from clients
- `signalr.method.duration`: Hub method execution time

### Logging

All hub activities are logged:

```csharp
_logger.LogInformation(
    "Client {ConnectionId} subscribed to workflow {WorkflowId}",
    Context.ConnectionId,
    workflowId
);
```

---

## Testing

### Mock Server for Development

Use `@microsoft/signalr-protocol-msgpack` for testing:

```typescript
import { HubConnectionBuilder } from '@microsoft/signalr';

// Connect to mock server
const connection = new HubConnectionBuilder()
  .withUrl('http://localhost:5000/hubs/meta-agents')
  .build();

// Emit mock events for UI testing
connection.on('WorkflowProgress', (event) => {
  console.log('Mock progress:', event);
});
```

---

## Complete React Hook Example

```typescript
import { useEffect, useState } from 'react';
import { HubConnection, HubConnectionBuilder } from '@microsoft/signalr';

export function useMetaAgentHub(workflowId: string | null) {
  const [connection, setConnection] = useState<HubConnection | null>(null);
  const [workflowStatus, setWorkflowStatus] = useState<WorkflowStatus | null>(null);
  const [thoughts, setThoughts] = useState<AgentThought[]>([]);
  const [artifacts, setArtifacts] = useState<Artifact[]>([]);

  useEffect(() => {
    const conn = new HubConnectionBuilder()
      .withUrl('/hubs/meta-agents', {
        accessTokenFactory: () => getAccessToken()
      })
      .withAutomaticReconnect()
      .build();

    // Event handlers
    conn.on('WorkflowProgress', (event) => {
      setWorkflowStatus(prev => ({
        ...prev,
        progress: event.progress
      }));
    });

    conn.on('AgentThought', (event) => {
      setThoughts(prev => [...prev, event]);
    });

    conn.on('ArtifactGenerated', (event) => {
      setArtifacts(prev => [...prev, event]);
    });

    conn.start()
      .then(() => {
        console.log('Connected to Meta-Agent Hub');
        setConnection(conn);
      })
      .catch(err => console.error('Connection error:', err));

    return () => {
      conn.stop();
    };
  }, []);

  useEffect(() => {
    if (connection && workflowId) {
      connection.invoke('SubscribeToWorkflow', workflowId);
      connection.invoke('SubscribeToThoughts', workflowId);

      return () => {
        connection.invoke('UnsubscribeFromWorkflow', workflowId);
        connection.invoke('UnsubscribeFromThoughts', workflowId);
      };
    }
  }, [connection, workflowId]);

  return {
    workflowStatus,
    thoughts,
    artifacts,
    isConnected: connection?.state === 'Connected'
  };
}
```

---

## Summary

The Meta-Agent SignalR Hub provides:

- **13 server-to-client events** for real-time updates
- **8 client-to-server methods** for subscriptions and queries
- **Group-based routing** for efficient message delivery
- **Automatic reconnection** with exponential backoff
- **Event throttling and batching** for performance
- **JWT authentication** and authorization
- **OpenTelemetry integration** for monitoring

This enables the React frontend to provide real-time visibility into meta-agent workflow execution with minimal latency and optimal performance.
