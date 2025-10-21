# SignalR Hub Contract Specification

## Overview

The SignalR Hub provides real-time, bidirectional communication between the .NET Orchestrator and React frontend clients. It enables live updates for workflow execution, agent status changes, log streaming, and performance metrics.

## Hub Information

- **Hub Name**: `AgentStudioHub`
- **Hub URL**: `/hubs/agentstudio`
- **Protocol**: SignalR (WebSocket with fallback to Server-Sent Events and Long Polling)
- **Message Format**: JSON
- **Authentication**: JWT Bearer Token (via query string or headers)

## Connection Management

### Connection URL

```
wss://api.agentstudio.dev/hubs/agentstudio?access_token={JWT_TOKEN}
```

### Connection Lifecycle

```typescript
// Client-side connection setup
import { HubConnectionBuilder, LogLevel } from '@microsoft/signalr';

const connection = new HubConnectionBuilder()
  .withUrl('/hubs/agentstudio', {
    accessTokenFactory: () => getAccessToken(),
  })
  .withAutomaticReconnect({
    nextRetryDelayInMilliseconds: (retryContext) => {
      // Exponential backoff: 0s, 2s, 10s, 30s, then 30s
      if (retryContext.previousRetryCount === 0) return 0;
      if (retryContext.previousRetryCount === 1) return 2000;
      if (retryContext.previousRetryCount === 2) return 10000;
      return 30000;
    }
  })
  .configureLogging(LogLevel.Information)
  .build();

await connection.start();
```

### Connection Events

| Event | Description |
|-------|-------------|
| `onconnected` | Client successfully connected to hub |
| `onreconnecting` | Client attempting to reconnect |
| `onreconnected` | Client successfully reconnected |
| `onclose` | Connection closed (check error parameter) |

---

## Server-to-Client Methods (Push from Hub)

These methods are invoked by the server and handled by connected clients.

### 1. WorkflowStarted

**Description**: Notified when a workflow execution begins.

**Signature**:
```csharp
Task WorkflowStarted(WorkflowStartedEvent event)
```

**TypeScript Handler**:
```typescript
connection.on('WorkflowStarted', (event: WorkflowStartedEvent) => {
  console.log(`Workflow ${event.workflowId} started`);
  // Update UI to show workflow is running
});
```

**Event Schema**:
```typescript
interface WorkflowStartedEvent {
  workflowId: string;
  name: string;
  triggeredBy: string;
  startedAt: string; // ISO 8601 timestamp
  estimatedDuration?: number; // seconds
  metadata: Record<string, any>;
  traceId: string;
}
```

**Example Payload**:
```json
{
  "workflowId": "wf_abc123",
  "name": "Customer Data Analysis",
  "triggeredBy": "user@example.com",
  "startedAt": "2025-10-07T10:30:00Z",
  "estimatedDuration": 300,
  "metadata": {
    "priority": "high",
    "department": "analytics"
  },
  "traceId": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
}
```

---

### 2. WorkflowCompleted

**Description**: Notified when a workflow execution completes (success or failure).

**Signature**:
```csharp
Task WorkflowCompleted(WorkflowCompletedEvent event)
```

**TypeScript Handler**:
```typescript
connection.on('WorkflowCompleted', (event: WorkflowCompletedEvent) => {
  console.log(`Workflow ${event.workflowId} completed with status: ${event.status}`);
  // Update UI and show results
});
```

**Event Schema**:
```typescript
interface WorkflowCompletedEvent {
  workflowId: string;
  status: 'completed' | 'failed' | 'cancelled';
  completedAt: string;
  duration: number; // seconds
  resultSummary?: string;
  errorMessage?: string;
  metrics: WorkflowMetrics;
  traceId: string;
}

interface WorkflowMetrics {
  totalTasks: number;
  successfulTasks: number;
  failedTasks: number;
  averageTaskDuration: number;
  totalTokensUsed?: number;
  totalCost?: number;
}
```

**Example Payload**:
```json
{
  "workflowId": "wf_abc123",
  "status": "completed",
  "completedAt": "2025-10-07T10:35:30Z",
  "duration": 330,
  "resultSummary": "Analysis completed successfully with 95% confidence",
  "metrics": {
    "totalTasks": 12,
    "successfulTasks": 12,
    "failedTasks": 0,
    "averageTaskDuration": 27.5,
    "totalTokensUsed": 45000,
    "totalCost": 0.12
  },
  "traceId": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
}
```

---

### 3. TaskStatusChanged

**Description**: Notified when a task status changes (pending → running → completed/failed).

**Signature**:
```csharp
Task TaskStatusChanged(TaskStatusChangedEvent event)
```

**TypeScript Handler**:
```typescript
connection.on('TaskStatusChanged', (event: TaskStatusChangedEvent) => {
  console.log(`Task ${event.taskId} is now ${event.status}`);
  // Update task card in UI
});
```

**Event Schema**:
```typescript
interface TaskStatusChangedEvent {
  taskId: string;
  workflowId: string;
  agentId: string;
  previousStatus: TaskStatus;
  currentStatus: TaskStatus;
  timestamp: string;
  progress?: TaskProgress;
  traceId: string;
}

type TaskStatus = 'pending' | 'queued' | 'running' | 'completed' | 'failed' | 'cancelled';

interface TaskProgress {
  percentage: number;
  currentStep?: string;
  totalSteps?: number;
  completedSteps?: number;
  estimatedCompletion?: string;
}
```

**Example Payload**:
```json
{
  "taskId": "task_xyz789",
  "workflowId": "wf_abc123",
  "agentId": "analyst-agent-01",
  "previousStatus": "queued",
  "currentStatus": "running",
  "timestamp": "2025-10-07T10:30:15Z",
  "progress": {
    "percentage": 0,
    "currentStep": "Initializing",
    "totalSteps": 5,
    "completedSteps": 0
  },
  "traceId": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
}
```

---

### 4. TaskProgressUpdated

**Description**: Notified when task progress is updated (during execution).

**Signature**:
```csharp
Task TaskProgressUpdated(TaskProgressUpdatedEvent event)
```

**TypeScript Handler**:
```typescript
connection.on('TaskProgressUpdated', (event: TaskProgressUpdatedEvent) => {
  console.log(`Task ${event.taskId} progress: ${event.progress.percentage}%`);
  // Update progress bar
});
```

**Event Schema**:
```typescript
interface TaskProgressUpdatedEvent {
  taskId: string;
  workflowId: string;
  timestamp: string;
  progress: TaskProgress;
  metrics?: TaskMetrics;
  traceId: string;
}

interface TaskMetrics {
  cpuUsagePercent?: number;
  memoryUsageMb?: number;
  itemsProcessed?: number;
  itemsTotal?: number;
  throughputPerSecond?: number;
}
```

**Example Payload**:
```json
{
  "taskId": "task_xyz789",
  "workflowId": "wf_abc123",
  "timestamp": "2025-10-07T10:31:00Z",
  "progress": {
    "percentage": 45,
    "currentStep": "Analyzing sentiment",
    "totalSteps": 5,
    "completedSteps": 2,
    "estimatedCompletion": "2025-10-07T10:35:00Z"
  },
  "metrics": {
    "cpuUsagePercent": 67.5,
    "memoryUsageMb": 1024,
    "itemsProcessed": 4500,
    "itemsTotal": 10000,
    "throughputPerSecond": 125
  },
  "traceId": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
}
```

---

### 5. AgentStatusChanged

**Description**: Notified when an agent's status changes (online, offline, degraded).

**Signature**:
```csharp
Task AgentStatusChanged(AgentStatusChangedEvent event)
```

**TypeScript Handler**:
```typescript
connection.on('AgentStatusChanged', (event: AgentStatusChangedEvent) => {
  console.log(`Agent ${event.agentId} is now ${event.status}`);
  // Update agent status indicator
});
```

**Event Schema**:
```typescript
interface AgentStatusChangedEvent {
  agentId: string;
  previousStatus: AgentStatus;
  currentStatus: AgentStatus;
  timestamp: string;
  reason?: string;
  healthMetrics?: AgentHealthMetrics;
}

type AgentStatus = 'online' | 'offline' | 'degraded' | 'maintenance';

interface AgentHealthMetrics {
  cpuUsagePercent: number;
  memoryUsageMb: number;
  activeTaskCount: number;
  queueDepth: number;
  lastHeartbeat: string;
}
```

**Example Payload**:
```json
{
  "agentId": "analyst-agent-01",
  "previousStatus": "online",
  "currentStatus": "degraded",
  "timestamp": "2025-10-07T10:32:00Z",
  "reason": "High memory usage detected",
  "healthMetrics": {
    "cpuUsagePercent": 92.5,
    "memoryUsageMb": 3850,
    "activeTaskCount": 5,
    "queueDepth": 12,
    "lastHeartbeat": "2025-10-07T10:31:55Z"
  }
}
```

---

### 6. LogMessageReceived

**Description**: Real-time log streaming for tasks and workflows.

**Signature**:
```csharp
Task LogMessageReceived(LogMessage message)
```

**TypeScript Handler**:
```typescript
connection.on('LogMessageReceived', (message: LogMessage) => {
  console.log(`[${message.level}] ${message.message}`);
  // Append to log viewer
});
```

**Event Schema**:
```typescript
interface LogMessage {
  taskId?: string;
  workflowId?: string;
  agentId?: string;
  timestamp: string;
  level: LogLevel;
  message: string;
  source?: string;
  metadata?: Record<string, any>;
  traceId?: string;
  spanId?: string;
}

type LogLevel = 'debug' | 'info' | 'warning' | 'error' | 'critical';
```

**Example Payload**:
```json
{
  "taskId": "task_xyz789",
  "workflowId": "wf_abc123",
  "agentId": "analyst-agent-01",
  "timestamp": "2025-10-07T10:31:30Z",
  "level": "info",
  "message": "Processing batch 45 of 100",
  "source": "SentimentAnalyzer",
  "metadata": {
    "batchSize": 100,
    "averageConfidence": 0.87
  },
  "traceId": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01",
  "spanId": "00f067aa0ba902b7"
}
```

---

### 7. MetricUpdated

**Description**: Real-time performance metrics updates.

**Signature**:
```csharp
Task MetricUpdated(MetricUpdate update)
```

**TypeScript Handler**:
```typescript
connection.on('MetricUpdated', (update: MetricUpdate) => {
  console.log(`Metric ${update.name}: ${update.value}`);
  // Update dashboard chart
});
```

**Event Schema**:
```typescript
interface MetricUpdate {
  metricName: string;
  value: number;
  unit: string;
  timestamp: string;
  tags?: Record<string, string>;
  aggregation?: 'sum' | 'avg' | 'min' | 'max' | 'count';
}
```

**Example Payload**:
```json
{
  "metricName": "tasks.completed",
  "value": 156,
  "unit": "count",
  "timestamp": "2025-10-07T10:30:00Z",
  "tags": {
    "agent": "analyst-agent-01",
    "status": "success"
  },
  "aggregation": "count"
}
```

---

### 8. ErrorOccurred

**Description**: Real-time error notifications.

**Signature**:
```csharp
Task ErrorOccurred(ErrorEvent error)
```

**TypeScript Handler**:
```typescript
connection.on('ErrorOccurred', (error: ErrorEvent) => {
  console.error(`Error in ${error.source}: ${error.message}`);
  // Show error notification
});
```

**Event Schema**:
```typescript
interface ErrorEvent {
  errorId: string;
  taskId?: string;
  workflowId?: string;
  agentId?: string;
  timestamp: string;
  severity: ErrorSeverity;
  code: string;
  message: string;
  source: string;
  retryable: boolean;
  traceId?: string;
}

type ErrorSeverity = 'warning' | 'error' | 'critical';
```

**Example Payload**:
```json
{
  "errorId": "err_def456",
  "taskId": "task_xyz789",
  "workflowId": "wf_abc123",
  "agentId": "analyst-agent-01",
  "timestamp": "2025-10-07T10:32:15Z",
  "severity": "error",
  "code": "RATE_LIMIT_EXCEEDED",
  "message": "API rate limit exceeded. Retrying in 60 seconds.",
  "source": "ExternalAPIClient",
  "retryable": true,
  "traceId": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
}
```

---

## Client-to-Server Methods (Invoke from Client)

These methods are invoked by clients and handled by the server.

### 1. SubscribeToWorkflow

**Description**: Subscribe to real-time updates for a specific workflow.

**Signature**:
```csharp
Task<bool> SubscribeToWorkflow(string workflowId)
```

**TypeScript Invocation**:
```typescript
const subscribed = await connection.invoke<boolean>('SubscribeToWorkflow', 'wf_abc123');
console.log(`Subscribed to workflow: ${subscribed}`);
```

**Parameters**:
- `workflowId` (string): The workflow ID to subscribe to

**Returns**: `boolean` - True if subscription successful

---

### 2. UnsubscribeFromWorkflow

**Description**: Unsubscribe from workflow updates.

**Signature**:
```csharp
Task<bool> UnsubscribeFromWorkflow(string workflowId)
```

**TypeScript Invocation**:
```typescript
await connection.invoke('UnsubscribeFromWorkflow', 'wf_abc123');
```

**Parameters**:
- `workflowId` (string): The workflow ID to unsubscribe from

**Returns**: `boolean` - True if unsubscription successful

---

### 3. SubscribeToTask

**Description**: Subscribe to real-time updates for a specific task.

**Signature**:
```csharp
Task<bool> SubscribeToTask(string taskId)
```

**TypeScript Invocation**:
```typescript
await connection.invoke('SubscribeToTask', 'task_xyz789');
```

**Parameters**:
- `taskId` (string): The task ID to subscribe to

**Returns**: `boolean` - True if subscription successful

---

### 4. UnsubscribeFromTask

**Description**: Unsubscribe from task updates.

**Signature**:
```csharp
Task<bool> UnsubscribeFromTask(string taskId)
```

**TypeScript Invocation**:
```typescript
await connection.invoke('UnsubscribeFromTask', 'task_xyz789');
```

---

### 5. SubscribeToAgent

**Description**: Subscribe to real-time updates for a specific agent.

**Signature**:
```csharp
Task<bool> SubscribeToAgent(string agentId)
```

**TypeScript Invocation**:
```typescript
await connection.invoke('SubscribeToAgent', 'analyst-agent-01');
```

**Parameters**:
- `agentId` (string): The agent ID to subscribe to

**Returns**: `boolean` - True if subscription successful

---

### 6. UnsubscribeFromAgent

**Description**: Unsubscribe from agent updates.

**Signature**:
```csharp
Task<bool> UnsubscribeFromAgent(string agentId)
```

**TypeScript Invocation**:
```typescript
await connection.invoke('UnsubscribeFromAgent', 'analyst-agent-01');
```

---

### 7. SubscribeToLogs

**Description**: Subscribe to real-time log streaming for a task or workflow.

**Signature**:
```csharp
Task<bool> SubscribeToLogs(LogSubscriptionRequest request)
```

**TypeScript Invocation**:
```typescript
interface LogSubscriptionRequest {
  taskId?: string;
  workflowId?: string;
  agentId?: string;
  minLevel?: LogLevel;
  tailLines?: number; // Get last N lines before streaming
}

await connection.invoke('SubscribeToLogs', {
  taskId: 'task_xyz789',
  minLevel: 'info',
  tailLines: 100
});
```

**Parameters**:
- `request` (LogSubscriptionRequest): Subscription configuration

**Returns**: `boolean` - True if subscription successful

---

### 8. UnsubscribeFromLogs

**Description**: Unsubscribe from log streaming.

**Signature**:
```csharp
Task<bool> UnsubscribeFromLogs(string subscriptionId)
```

**TypeScript Invocation**:
```typescript
await connection.invoke('UnsubscribeFromLogs', 'subscription_id');
```

---

### 9. GetConnectionInfo

**Description**: Get information about the current connection.

**Signature**:
```csharp
Task<ConnectionInfo> GetConnectionInfo()
```

**TypeScript Invocation**:
```typescript
interface ConnectionInfo {
  connectionId: string;
  userId: string;
  connectedAt: string;
  subscriptions: string[];
}

const info = await connection.invoke<ConnectionInfo>('GetConnectionInfo');
console.log(`Connection ID: ${info.connectionId}`);
```

**Returns**: `ConnectionInfo` - Connection details

---

## Groups and Filtering

The hub uses SignalR groups to efficiently route messages to interested clients.

### Group Naming Conventions

| Group Name | Description |
|------------|-------------|
| `workflow:{workflowId}` | All events for a specific workflow |
| `task:{taskId}` | All events for a specific task |
| `agent:{agentId}` | All events for a specific agent |
| `logs:{resourceId}` | Log messages for a resource |
| `user:{userId}` | All events for a specific user |

### Automatic Group Management

Clients are automatically added to relevant groups based on:
- Authentication context (user groups)
- Explicit subscriptions (SubscribeToWorkflow, etc.)
- Resource ownership and permissions

---

## Error Handling

### Connection Errors

```typescript
connection.onclose((error) => {
  if (error) {
    console.error('Connection closed with error:', error);
    // Implement reconnection logic
  } else {
    console.log('Connection closed gracefully');
  }
});
```

### Invocation Errors

```typescript
try {
  await connection.invoke('SubscribeToWorkflow', 'wf_abc123');
} catch (error) {
  console.error('Failed to subscribe:', error);
  // Handle subscription failure
}
```

### Hub Method Exceptions

The hub sends error events via the `ErrorOccurred` method for runtime errors.

---

## Authentication and Authorization

### JWT Token Requirements

The JWT token must include:
- `sub`: User ID
- `name`: User name or email
- `role`: User role(s)
- `exp`: Expiration timestamp

### Authorization Rules

| Method | Required Permission |
|--------|-------------------|
| SubscribeToWorkflow | `workflows:read` or workflow ownership |
| SubscribeToTask | `tasks:read` or task ownership |
| SubscribeToAgent | `agents:read` |
| SubscribeToLogs | `logs:read` and resource access |

---

## Performance Considerations

### Rate Limiting

- **Per Connection**: 100 method invocations per minute
- **Per User**: 1000 messages per minute across all connections
- **Global**: Configurable throttle for system protection

### Message Batching

High-frequency events (logs, metrics) are batched every 100ms or 10 messages, whichever comes first.

### Backpressure

If a client cannot keep up with messages:
1. Warning sent after 1000 queued messages
2. Subscription paused after 5000 queued messages
3. Connection dropped after 10000 queued messages

---

## Best Practices

### 1. Connection Management

```typescript
// Always handle reconnection
connection.onreconnecting(() => {
  showReconnectingIndicator();
});

connection.onreconnected(() => {
  hideReconnectingIndicator();
  // Re-subscribe to necessary resources
  resubscribeToActiveResources();
});
```

### 2. Subscription Cleanup

```typescript
// Unsubscribe when component unmounts
useEffect(() => {
  connection.invoke('SubscribeToWorkflow', workflowId);

  return () => {
    connection.invoke('UnsubscribeFromWorkflow', workflowId);
  };
}, [workflowId]);
```

### 3. Error Resilience

```typescript
// Implement retry logic for critical subscriptions
async function subscribeWithRetry(workflowId: string, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      await connection.invoke('SubscribeToWorkflow', workflowId);
      return;
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await delay(2 ** i * 1000); // Exponential backoff
    }
  }
}
```

### 4. State Synchronization

```typescript
// Poll for state after reconnection to ensure consistency
connection.onreconnected(async () => {
  const latestWorkflow = await fetchWorkflowState(workflowId);
  updateLocalState(latestWorkflow);
});
```

---

## Message Size Limits

- **Maximum message size**: 32 KB
- **Large payloads**: Use message chunking or reference URLs

---

## Monitoring and Debugging

### Client-Side Logging

```typescript
import { LogLevel } from '@microsoft/signalr';

const connection = new HubConnectionBuilder()
  .withUrl('/hubs/agentstudio')
  .configureLogging(LogLevel.Debug) // Enable debug logging
  .build();
```

### Server-Side Telemetry

All hub activities are traced using OpenTelemetry:
- Connection events
- Method invocations
- Group subscriptions
- Message deliveries

---

## Complete TypeScript Example

```typescript
import { HubConnectionBuilder, HubConnection, LogLevel } from '@microsoft/signalr';

class AgentStudioHubClient {
  private connection: HubConnection;

  constructor(private accessToken: string) {
    this.connection = new HubConnectionBuilder()
      .withUrl('/hubs/agentstudio', {
        accessTokenFactory: () => this.accessToken,
      })
      .withAutomaticReconnect()
      .configureLogging(LogLevel.Information)
      .build();

    this.setupEventHandlers();
  }

  private setupEventHandlers() {
    this.connection.on('WorkflowStarted', this.onWorkflowStarted);
    this.connection.on('WorkflowCompleted', this.onWorkflowCompleted);
    this.connection.on('TaskStatusChanged', this.onTaskStatusChanged);
    this.connection.on('TaskProgressUpdated', this.onTaskProgressUpdated);
    this.connection.on('AgentStatusChanged', this.onAgentStatusChanged);
    this.connection.on('LogMessageReceived', this.onLogMessageReceived);
    this.connection.on('MetricUpdated', this.onMetricUpdated);
    this.connection.on('ErrorOccurred', this.onErrorOccurred);
  }

  async start() {
    await this.connection.start();
    console.log('Connected to AgentStudioHub');
  }

  async stop() {
    await this.connection.stop();
  }

  async subscribeToWorkflow(workflowId: string) {
    return await this.connection.invoke<boolean>('SubscribeToWorkflow', workflowId);
  }

  async unsubscribeFromWorkflow(workflowId: string) {
    return await this.connection.invoke<boolean>('UnsubscribeFromWorkflow', workflowId);
  }

  async subscribeToLogs(request: LogSubscriptionRequest) {
    return await this.connection.invoke<boolean>('SubscribeToLogs', request);
  }

  private onWorkflowStarted = (event: WorkflowStartedEvent) => {
    console.log('Workflow started:', event);
  };

  private onWorkflowCompleted = (event: WorkflowCompletedEvent) => {
    console.log('Workflow completed:', event);
  };

  private onTaskStatusChanged = (event: TaskStatusChangedEvent) => {
    console.log('Task status changed:', event);
  };

  private onTaskProgressUpdated = (event: TaskProgressUpdatedEvent) => {
    console.log('Task progress:', event.progress.percentage + '%');
  };

  private onAgentStatusChanged = (event: AgentStatusChangedEvent) => {
    console.log('Agent status changed:', event);
  };

  private onLogMessageReceived = (message: LogMessage) => {
    console.log(`[${message.level}] ${message.message}`);
  };

  private onMetricUpdated = (update: MetricUpdate) => {
    console.log('Metric updated:', update);
  };

  private onErrorOccurred = (error: ErrorEvent) => {
    console.error('Error occurred:', error);
  };
}

// Usage
const hubClient = new AgentStudioHubClient(getAccessToken());
await hubClient.start();
await hubClient.subscribeToWorkflow('wf_abc123');
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-10-07 | Initial specification |
