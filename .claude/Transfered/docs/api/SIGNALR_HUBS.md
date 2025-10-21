# SignalR Hubs Documentation

## Table of Contents

- [Overview](#overview)
- [Connection](#connection)
- [Workflow Hub](#workflow-hub)
- [Agent Hub](#agent-hub)
- [Notifications Hub](#notifications-hub)
- [Error Handling](#error-handling)

## Overview

SignalR provides real-time, bidirectional communication between the server and clients for workflow execution updates, agent messages, and system notifications.

**Protocol**: WebSocket (with Long Polling fallback)
**Hub Base URL**: `https://api.agentstudio.com/hubs`

## Connection

### Establishing Connection

**.NET Client (C#)**:
```csharp
var connection = new HubConnectionBuilder()
    .WithUrl("https://api.agentstudio.com/hubs/workflow", options =>
    {
        options.AccessTokenProvider = async () => await GetAccessToken();
    })
    .WithAutomaticReconnect()
    .Build();

await connection.StartAsync();
```

**JavaScript/TypeScript Client**:
```typescript
import * as signalR from '@microsoft/signalr';

const connection = new signalR.HubConnectionBuilder()
    .withUrl('https://api.agentstudio.com/hubs/workflow', {
        accessTokenFactory: () => getAccessToken()
    })
    .withAutomaticReconnect()
    .build();

await connection.start();
```

### Connection Events

```typescript
connection.onreconnecting((error) => {
    console.log('Reconnecting...', error);
});

connection.onreconnected((connectionId) => {
    console.log('Reconnected', connectionId);
});

connection.onclose((error) => {
    console.log('Connection closed', error);
});
```

## Workflow Hub

**Hub URL**: `/hubs/workflow`

### Server Methods (Client → Server)

#### SubscribeToWorkflow

Subscribe to updates for a specific workflow execution.

```typescript
await connection.invoke('SubscribeToWorkflow', workflowId);
```

**Parameters**:
- `workflowId` (string): Workflow identifier

#### UnsubscribeFromWorkflow

Unsubscribe from workflow updates.

```typescript
await connection.invoke('UnsubscribeFromWorkflow', workflowId);
```

### Client Methods (Server → Client)

#### WorkflowProgress

Receive workflow execution progress updates.

```typescript
connection.on('WorkflowProgress', (update: WorkflowProgress) => {
    console.log('Progress:', update);
    updateUI(update);
});
```

**Update Object**:
```typescript
interface WorkflowProgress {
    executionId: string;
    workflowId: string;
    currentStep: number;
    totalSteps: number;
    status: 'pending' | 'running' | 'completed' | 'failed';
    stepName: string;
    percentage: number;
    timestamp: string;
}
```

**Example Update**:
```json
{
    "executionId": "exec-123",
    "workflowId": "workflow-456",
    "currentStep": 2,
    "totalSteps": 5,
    "status": "running",
    "stepName": "Security Scan",
    "percentage": 40,
    "timestamp": "2025-10-07T12:30:45Z"
}
```

#### AgentMessage

Receive messages from agents during execution.

```typescript
connection.on('AgentMessage', (message: AgentMessage) => {
    appendToLog(message);
});
```

**Message Object**:
```typescript
interface AgentMessage {
    executionId: string;
    agentId: string;
    agentName: string;
    timestamp: string;
    level: 'info' | 'warning' | 'error';
    content: string;
    metadata?: Record<string, any>;
}
```

**Example Message**:
```json
{
    "executionId": "exec-123",
    "agentId": "agent-789",
    "agentName": "Code Analyzer",
    "timestamp": "2025-10-07T12:31:00Z",
    "level": "warning",
    "content": "High complexity detected in calculateMetrics()",
    "metadata": {
        "file": "src/metrics.ts",
        "line": 45,
        "complexity": 15
    }
}
```

#### WorkflowCompleted

Receive notification when workflow execution completes.

```typescript
connection.on('WorkflowCompleted', (result: WorkflowResult) => {
    showResults(result);
});
```

**Result Object**:
```typescript
interface WorkflowResult {
    executionId: string;
    workflowId: string;
    status: 'completed' | 'failed' | 'cancelled';
    duration: number;  // seconds
    result: Record<string, any>;
    metrics: {
        totalTokens: number;
        totalCost: number;
        stepsCompleted: number;
        stepsFailed: number;
    };
    timestamp: string;
}
```

**Example Result**:
```json
{
    "executionId": "exec-123",
    "workflowId": "workflow-456",
    "status": "completed",
    "duration": 325.5,
    "result": {
        "analysis": { ... },
        "recommendations": [ ... ]
    },
    "metrics": {
        "totalTokens": 15000,
        "totalCost": 0.45,
        "stepsCompleted": 5,
        "stepsFailed": 0
    },
    "timestamp": "2025-10-07T12:35:00Z"
}
```

#### WorkflowFailed

Receive notification when workflow execution fails.

```typescript
connection.on('WorkflowFailed', (failure: WorkflowFailure) => {
    handleError(failure);
});
```

**Failure Object**:
```typescript
interface WorkflowFailure {
    executionId: string;
    workflowId: string;
    failedStep: number;
    stepName: string;
    error: {
        message: string;
        type: string;
        stackTrace?: string;
    };
    timestamp: string;
}
```

## Agent Hub

**Hub URL**: `/hubs/agents`

### Server Methods

#### StreamAgentExecution

Stream agent execution in real-time.

```typescript
await connection.invoke('StreamAgentExecution', {
    agentId: 'agent-123',
    parameters: { ... }
});
```

### Client Methods

#### AgentStreamChunk

Receive streaming chunks from agent execution.

```typescript
connection.on('AgentStreamChunk', (chunk: StreamChunk) => {
    appendToOutput(chunk.content);
});
```

**Chunk Object**:
```typescript
interface StreamChunk {
    executionId: string;
    agentId: string;
    sequence: number;
    type: 'token' | 'metadata' | 'complete';
    content: string;
    metadata?: Record<string, any>;
    isFinal: boolean;
}
```

#### AgentExecutionComplete

Receive notification when streaming completes.

```typescript
connection.on('AgentExecutionComplete', (result: AgentResult) => {
    processResult(result);
});
```

## Notifications Hub

**Hub URL**: `/hubs/notifications`

### Client Methods

#### SystemNotification

Receive system-wide notifications.

```typescript
connection.on('SystemNotification', (notification: Notification) => {
    showNotification(notification);
});
```

**Notification Object**:
```typescript
interface Notification {
    id: string;
    type: 'info' | 'warning' | 'error' | 'success';
    title: string;
    message: string;
    timestamp: string;
    actionUrl?: string;
    dismissible: boolean;
}
```

#### UserNotification

Receive user-specific notifications.

```typescript
connection.on('UserNotification', (notification: UserNotification) => {
    showUserNotification(notification);
});
```

## Error Handling

### Connection Errors

```typescript
connection.onclose((error) => {
    if (error) {
        console.error('Connection closed with error:', error);
        // Attempt reconnection
        setTimeout(() => startConnection(), 5000);
    }
});
```

### Invocation Errors

```typescript
try {
    await connection.invoke('SubscribeToWorkflow', workflowId);
} catch (error) {
    console.error('Error subscribing to workflow:', error);
}
```

### Server Error Events

```typescript
connection.on('Error', (error: ServerError) => {
    console.error('Server error:', error);
});
```

**Error Object**:
```typescript
interface ServerError {
    message: string;
    code: string;
    details?: Record<string, any>;
}
```

---

**Related Documentation**:
- [REST API Reference](META_AGENTS_API.md)
- [Python Agents API](PYTHON_AGENTS_API.md)
- [Integration Guide](../meta-agents/INTEGRATION.md)

**Last Updated**: 2025-10-07
**Version**: 1.0.0
