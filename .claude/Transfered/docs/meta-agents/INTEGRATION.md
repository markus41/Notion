# .NET + Python + React Integration Guide

## Table of Contents

- [Overview](#overview)
- [.NET to Python Integration](#net-to-python-integration)
- [Frontend to Backend Integration](#frontend-to-backend-integration)
- [Real-time Communication](#real-time-communication)
- [Authentication Flow](#authentication-flow)
- [Error Handling](#error-handling)
- [Performance Optimization](#performance-optimization)
- [Testing Integration Points](#testing-integration-points)

## Overview

The Meta-Agent Platform integrates three distinct technology stacks:

1. **React Frontend** (TypeScript) - User interface and real-time monitoring
2. **.NET Orchestration Service** (C#) - Workflow coordination and state management
3. **Python Agent Service** (Python) - Agent execution and LLM integration

This guide explains how these components integrate, communicate, and coordinate to deliver a cohesive platform.

### Integration Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    React Frontend (Port 5173)                 │
│                                                               │
│  ├─ REST API Client (fetch/axios)                           │
│  ├─ SignalR Client (real-time updates)                       │
│  ├─ Authentication (Azure AD)                                │
│  └─ State Management (TanStack Query)                        │
└──────────────┬───────────────────────────────┬───────────────┘
               │ HTTP/HTTPS                     │ WebSocket (SignalR)
               ▼                                ▼
┌──────────────────────────────────────────────────────────────┐
│              .NET Orchestration API (Port 5000)              │
│                                                               │
│  ├─ REST API Controllers                                     │
│  ├─ SignalR Hubs                                             │
│  ├─ Workflow Orchestrator                                    │
│  ├─ State Manager (Cosmos DB)                                │
│  └─ Agent Execution Proxy                                    │
└──────────────┬──────────────────────────────────────────────┘
               │ HTTP/HTTPS (with Polly resilience)
               ▼
┌──────────────────────────────────────────────────────────────┐
│              Python Agent Service (Port 8000)                │
│                                                               │
│  ├─ FastAPI Endpoints                                        │
│  ├─ Agent Execution Engine                                   │
│  ├─ LLM Integration (Azure OpenAI)                           │
│  └─ Tool Execution (MCP)                                     │
└──────────────────────────────────────────────────────────────┘
```

## .NET to Python Integration

### Communication Protocol

The .NET service communicates with the Python service using HTTP/REST with JSON payloads.

**Key Characteristics**:
- **Protocol**: HTTP/2 (with fallback to HTTP/1.1)
- **Format**: JSON (with content negotiation)
- **Authentication**: Azure AD JWT tokens passed through
- **Tracing**: OpenTelemetry correlation IDs propagated

### HTTP Client Configuration

#### .NET Side (Producer)

```csharp
// Program.cs - Service registration
builder.Services.AddHttpClient<IPythonAgentClient, PythonAgentClient>(client =>
{
    client.BaseAddress = new Uri(builder.Configuration["PythonService:BaseUrl"]);
    client.Timeout = TimeSpan.FromSeconds(300); // 5 minutes for long-running agents
    client.DefaultRequestHeaders.Add("User-Agent", "AgentStudio-DotNet/1.0");
})
.AddPolicyHandler(GetRetryPolicy())
.AddPolicyHandler(GetCircuitBreakerPolicy())
.AddPolicyHandler(GetTimeoutPolicy());

static IAsyncPolicy<HttpResponseMessage> GetRetryPolicy()
{
    return HttpPolicyExtensions
        .HandleTransientHttpError()
        .OrResult(msg => msg.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
        .WaitAndRetryAsync(
            3,
            retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
            onRetry: (outcome, timespan, retryCount, context) =>
            {
                Log.Warning("Retry {RetryCount} after {Delay}s", retryCount, timespan.TotalSeconds);
            });
}

static IAsyncPolicy<HttpResponseMessage> GetCircuitBreakerPolicy()
{
    return HttpPolicyExtensions
        .HandleTransientHttpError()
        .CircuitBreakerAsync(
            handledEventsAllowedBeforeBreaking: 5,
            durationOfBreak: TimeSpan.FromSeconds(30),
            onBreak: (outcome, duration) =>
            {
                Log.Error("Circuit breaker opened for {Duration}s", duration.TotalSeconds);
            },
            onReset: () =>
            {
                Log.Information("Circuit breaker reset");
            });
}
```

#### Python Agent Client Implementation

```csharp
public interface IPythonAgentClient
{
    Task<AgentExecutionResult> ExecuteAgentAsync(
        AgentExecutionRequest request,
        CancellationToken cancellationToken = default);

    Task<AgentExecutionResult> StreamAgentAsync(
        AgentExecutionRequest request,
        IAsyncEnumerable<AgentStreamChunk> callback,
        CancellationToken cancellationToken = default);
}

public class PythonAgentClient : IPythonAgentClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<PythonAgentClient> _logger;
    private static readonly ActivitySource ActivitySource = new("AgentStudio.PythonClient");

    public PythonAgentClient(HttpClient httpClient, ILogger<PythonAgentClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<AgentExecutionResult> ExecuteAgentAsync(
        AgentExecutionRequest request,
        CancellationToken cancellationToken = default)
    {
        using var activity = ActivitySource.StartActivity("ExecuteAgent");
        activity?.SetTag("agent.id", request.AgentId);
        activity?.SetTag("agent.type", request.AgentType);

        try
        {
            _logger.LogInformation(
                "Executing agent {AgentId} via Python service",
                request.AgentId);

            var response = await _httpClient.PostAsJsonAsync(
                "/agents/execute",
                request,
                cancellationToken);

            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<AgentExecutionResult>(
                cancellationToken: cancellationToken);

            activity?.SetTag("execution.status", result?.Status);

            return result ?? throw new InvalidOperationException("Null response from Python service");
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "HTTP error executing agent {AgentId}", request.AgentId);
            activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
            throw;
        }
        catch (TaskCanceledException ex)
        {
            _logger.LogWarning("Agent execution timeout for {AgentId}", request.AgentId);
            activity?.SetStatus(ActivityStatusCode.Error, "Timeout");
            throw;
        }
    }

    public async Task<AgentExecutionResult> StreamAgentAsync(
        AgentExecutionRequest request,
        IAsyncEnumerable<AgentStreamChunk> callback,
        CancellationToken cancellationToken = default)
    {
        using var activity = ActivitySource.StartActivity("StreamAgent");

        var httpRequest = new HttpRequestMessage(HttpMethod.Post, "/agents/stream")
        {
            Content = JsonContent.Create(request)
        };

        using var response = await _httpClient.SendAsync(
            httpRequest,
            HttpCompletionOption.ResponseHeadersRead,
            cancellationToken);

        response.EnsureSuccessStatusCode();

        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        using var reader = new StreamReader(stream);

        AgentExecutionResult? finalResult = null;

        while (!reader.EndOfStream && !cancellationToken.IsCancellationRequested)
        {
            var line = await reader.ReadLineAsync(cancellationToken);
            if (string.IsNullOrWhiteSpace(line)) continue;

            if (line.StartsWith("data: "))
            {
                var json = line.Substring(6);
                var chunk = JsonSerializer.Deserialize<AgentStreamChunk>(json);

                if (chunk != null)
                {
                    await callback.ProcessChunkAsync(chunk);

                    if (chunk.IsFinal && chunk.FinalResult != null)
                    {
                        finalResult = chunk.FinalResult;
                    }
                }
            }
        }

        return finalResult ?? throw new InvalidOperationException("Stream ended without final result");
    }
}
```

### Python Side (Consumer)

#### FastAPI Endpoint

```python
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, AsyncIterator
from opentelemetry import trace
import asyncio
import json

app = FastAPI()
tracer = trace.get_tracer(__name__)

class AgentExecutionRequest(BaseModel):
    agent_id: str = Field(..., description="Unique agent identifier")
    agent_type: str = Field(..., description="Type of agent to execute")
    parameters: Dict[str, Any] = Field(default_factory=dict)
    context: Optional[Dict[str, Any]] = None
    timeout: int = Field(default=300, description="Timeout in seconds")

class AgentExecutionResult(BaseModel):
    agent_id: str
    status: str  # "completed", "failed", "timeout"
    result: Dict[str, Any]
    execution_time: float
    error: Optional[str] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)

@app.post("/agents/execute", response_model=AgentExecutionResult)
async def execute_agent(request: AgentExecutionRequest) -> AgentExecutionResult:
    """Execute an agent and return the result."""

    with tracer.start_as_current_span("execute_agent") as span:
        span.set_attribute("agent.id", request.agent_id)
        span.set_attribute("agent.type", request.agent_type)

        try:
            # Get agent executor based on type
            executor = get_agent_executor(request.agent_type)

            # Execute agent with timeout
            result = await asyncio.wait_for(
                executor.execute(request),
                timeout=request.timeout
            )

            span.set_attribute("execution.status", "completed")

            return AgentExecutionResult(
                agent_id=request.agent_id,
                status="completed",
                result=result,
                execution_time=result.get("execution_time", 0.0),
                metadata=result.get("metadata", {})
            )

        except asyncio.TimeoutError:
            span.set_attribute("execution.status", "timeout")
            return AgentExecutionResult(
                agent_id=request.agent_id,
                status="timeout",
                result={},
                execution_time=request.timeout,
                error="Agent execution exceeded timeout"
            )

        except Exception as e:
            span.set_attribute("execution.status", "failed")
            span.record_exception(e)

            return AgentExecutionResult(
                agent_id=request.agent_id,
                status="failed",
                result={},
                execution_time=0.0,
                error=str(e)
            )

@app.post("/agents/stream")
async def stream_agent(request: AgentExecutionRequest) -> StreamingResponse:
    """Execute an agent and stream results."""

    async def generate_stream() -> AsyncIterator[str]:
        with tracer.start_as_current_span("stream_agent") as span:
            span.set_attribute("agent.id", request.agent_id)

            executor = get_agent_executor(request.agent_type)

            async for chunk in executor.stream(request):
                yield f"data: {json.dumps(chunk.dict())}\n\n"

    return StreamingResponse(
        generate_stream(),
        media_type="text/event-stream"
    )
```

### Request/Response Models

#### Agent Execution Request

```json
{
  "agent_id": "agent-12345",
  "agent_type": "code_review",
  "parameters": {
    "repository": "org/repo",
    "pull_request": 123,
    "focus_areas": ["security", "performance"]
  },
  "context": {
    "user_id": "user-789",
    "organization_id": "org-456"
  },
  "timeout": 300
}
```

#### Agent Execution Result

```json
{
  "agent_id": "agent-12345",
  "status": "completed",
  "result": {
    "findings": [
      {
        "type": "security",
        "severity": "high",
        "message": "Potential SQL injection vulnerability",
        "file": "src/database.ts",
        "line": 45
      }
    ],
    "summary": "Found 3 issues requiring attention"
  },
  "execution_time": 12.34,
  "error": null,
  "metadata": {
    "model_used": "gpt-4",
    "tokens_consumed": 1234
  }
}
```

### Error Handling

#### .NET Error Mapping

```csharp
public class PythonServiceException : Exception
{
    public string PythonErrorType { get; }
    public int? StatusCode { get; }

    public PythonServiceException(string message, string errorType, int? statusCode = null)
        : base(message)
    {
        PythonErrorType = errorType;
        StatusCode = statusCode;
    }
}

private async Task<AgentExecutionResult> HandlePythonResponseAsync(HttpResponseMessage response)
{
    if (!response.IsSuccessStatusCode)
    {
        var errorContent = await response.Content.ReadAsStringAsync();
        var errorResponse = JsonSerializer.Deserialize<PythonErrorResponse>(errorContent);

        throw new PythonServiceException(
            errorResponse?.Detail ?? "Unknown Python service error",
            errorResponse?.ErrorType ?? "UnknownError",
            (int)response.StatusCode
        );
    }

    return await response.Content.ReadFromJsonAsync<AgentExecutionResult>();
}
```

#### Python Error Responses

```python
from fastapi import HTTPException, status
from pydantic import BaseModel

class ErrorResponse(BaseModel):
    detail: str
    error_type: str
    trace_id: Optional[str] = None

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    trace_id = trace.get_current_span().get_span_context().trace_id

    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=ErrorResponse(
            detail=str(exc),
            error_type=type(exc).__name__,
            trace_id=format(trace_id, '032x') if trace_id else None
        ).dict()
    )
```

## Frontend to Backend Integration

### REST API Integration

#### TypeScript API Client

```typescript
// src/api/client.ts
import { QueryClient } from '@tanstack/react-query';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000';

interface ApiConfig {
  baseUrl: string;
  timeout: number;
  headers: Record<string, string>;
}

class ApiClient {
  private config: ApiConfig;

  constructor(config: Partial<ApiConfig> = {}) {
    this.config = {
      baseUrl: config.baseUrl || API_BASE_URL,
      timeout: config.timeout || 30000,
      headers: {
        'Content-Type': 'application/json',
        ...config.headers,
      },
    };
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${this.config.baseUrl}${endpoint}`;

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.config.timeout);

    try {
      const response = await fetch(url, {
        ...options,
        headers: {
          ...this.config.headers,
          ...options.headers,
        },
        signal: controller.signal,
      });

      if (!response.ok) {
        const error = await response.json();
        throw new ApiError(error.message, response.status, error);
      }

      return response.json();
    } finally {
      clearTimeout(timeoutId);
    }
  }

  async get<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: 'GET' });
  }

  async post<T>(endpoint: string, data: unknown): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async put<T>(endpoint: string, data: unknown): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  async delete<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: 'DELETE' });
  }
}

export const apiClient = new ApiClient();

class ApiError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public details?: unknown
  ) {
    super(message);
    this.name = 'ApiError';
  }
}
```

#### Agent API Service

```typescript
// src/api/agents.ts
import { apiClient } from './client';
import { Agent, AgentConfig, AgentExecutionRequest, AgentExecutionResult } from '../types';

export const agentsApi = {
  list: () => apiClient.get<Agent[]>('/api/v1/agents'),

  get: (id: string) => apiClient.get<Agent>(`/api/v1/agents/${id}`),

  create: (config: AgentConfig) =>
    apiClient.post<Agent>('/api/v1/agents', config),

  update: (id: string, config: Partial<AgentConfig>) =>
    apiClient.put<Agent>(`/api/v1/agents/${id}`, config),

  delete: (id: string) =>
    apiClient.delete<void>(`/api/v1/agents/${id}`),

  execute: (id: string, request: AgentExecutionRequest) =>
    apiClient.post<AgentExecutionResult>(
      `/api/v1/agents/${id}/execute`,
      request
    ),
};
```

#### React Query Integration

```typescript
// src/hooks/useAgents.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { agentsApi } from '../api/agents';
import { AgentConfig } from '../types';

export const useAgents = () => {
  return useQuery({
    queryKey: ['agents'],
    queryFn: agentsApi.list,
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
};

export const useAgent = (id: string) => {
  return useQuery({
    queryKey: ['agents', id],
    queryFn: () => agentsApi.get(id),
    enabled: !!id,
  });
};

export const useCreateAgent = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (config: AgentConfig) => agentsApi.create(config),
    onSuccess: () => {
      // Invalidate and refetch agents list
      queryClient.invalidateQueries({ queryKey: ['agents'] });
    },
  });
};

export const useExecuteAgent = () => {
  return useMutation({
    mutationFn: ({ id, request }: { id: string; request: AgentExecutionRequest }) =>
      agentsApi.execute(id, request),
  });
};
```

#### Component Usage

```typescript
// src/components/AgentList.tsx
import React from 'react';
import { useAgents, useCreateAgent } from '../hooks/useAgents';

export const AgentList: React.FC = () => {
  const { data: agents, isLoading, error } = useAgents();
  const createAgent = useCreateAgent();

  const handleCreate = async () => {
    await createAgent.mutateAsync({
      name: 'New Agent',
      type: 'code_review',
      description: 'Code review agent',
    });
  };

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div>
      <button onClick={handleCreate}>Create Agent</button>
      <ul>
        {agents?.map(agent => (
          <li key={agent.id}>{agent.name}</li>
        ))}
      </ul>
    </div>
  );
};
```

## Real-time Communication

### SignalR Integration

#### .NET SignalR Hub

```csharp
// Hubs/WorkflowHub.cs
using Microsoft.AspNetCore.SignalR;
using Microsoft.AspNetCore.Authorization;

[Authorize]
public class WorkflowHub : Hub
{
    private readonly ILogger<WorkflowHub> _logger;
    private readonly IWorkflowService _workflowService;

    public WorkflowHub(ILogger<WorkflowHub> logger, IWorkflowService workflowService)
    {
        _logger = logger;
        _workflowService = workflowService;
    }

    public override async Task OnConnectedAsync()
    {
        var userId = Context.UserIdentifier;
        _logger.LogInformation("User {UserId} connected to WorkflowHub", userId);

        await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");
        await base.OnConnectedAsync();
    }

    public async Task SubscribeToWorkflow(string workflowId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"workflow_{workflowId}");
        _logger.LogInformation(
            "Connection {ConnectionId} subscribed to workflow {WorkflowId}",
            Context.ConnectionId,
            workflowId);
    }

    public async Task UnsubscribeFromWorkflow(string workflowId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"workflow_{workflowId}");
    }
}

// Service to send updates
public class WorkflowNotificationService
{
    private readonly IHubContext<WorkflowHub> _hubContext;

    public WorkflowNotificationService(IHubContext<WorkflowHub> hubContext)
    {
        _hubContext = hubContext;
    }

    public async Task SendWorkflowProgressAsync(string workflowId, WorkflowProgress progress)
    {
        await _hubContext.Clients
            .Group($"workflow_{workflowId}")
            .SendAsync("WorkflowProgress", progress);
    }

    public async Task SendAgentMessageAsync(string workflowId, AgentMessage message)
    {
        await _hubContext.Clients
            .Group($"workflow_{workflowId}")
            .SendAsync("AgentMessage", message);
    }

    public async Task SendWorkflowCompletedAsync(string workflowId, WorkflowResult result)
    {
        await _hubContext.Clients
            .Group($"workflow_{workflowId}")
            .SendAsync("WorkflowCompleted", result);
    }
}
```

#### React SignalR Client

```typescript
// src/services/signalr.ts
import * as signalR from '@microsoft/signalr';

export class SignalRService {
  private connection: signalR.HubConnection | null = null;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;

  async connect(hubUrl: string, accessToken: string): Promise<void> {
    this.connection = new signalR.HubConnectionBuilder()
      .withUrl(hubUrl, {
        accessTokenFactory: () => accessToken,
      })
      .withAutomaticReconnect({
        nextRetryDelayInMilliseconds: (retryContext) => {
          if (retryContext.previousRetryCount >= this.maxReconnectAttempts) {
            return null; // Stop reconnecting
          }
          return Math.min(1000 * Math.pow(2, retryContext.previousRetryCount), 30000);
        },
      })
      .configureLogging(signalR.LogLevel.Information)
      .build();

    this.connection.onreconnecting((error) => {
      console.warn('SignalR reconnecting', error);
    });

    this.connection.onreconnected((connectionId) => {
      console.log('SignalR reconnected', connectionId);
      this.reconnectAttempts = 0;
    });

    this.connection.onclose((error) => {
      console.error('SignalR connection closed', error);
    });

    await this.connection.start();
    console.log('SignalR connected');
  }

  async disconnect(): Promise<void> {
    if (this.connection) {
      await this.connection.stop();
      this.connection = null;
    }
  }

  on<T>(eventName: string, callback: (data: T) => void): void {
    if (!this.connection) {
      throw new Error('SignalR connection not established');
    }
    this.connection.on(eventName, callback);
  }

  off(eventName: string): void {
    if (this.connection) {
      this.connection.off(eventName);
    }
  }

  async invoke<T>(methodName: string, ...args: unknown[]): Promise<T> {
    if (!this.connection) {
      throw new Error('SignalR connection not established');
    }
    return this.connection.invoke<T>(methodName, ...args);
  }
}

export const signalRService = new SignalRService();
```

#### React Hook for SignalR

```typescript
// src/hooks/useWorkflowUpdates.ts
import { useEffect, useState } from 'react';
import { signalRService } from '../services/signalr';
import { WorkflowProgress, AgentMessage, WorkflowResult } from '../types';

interface WorkflowUpdates {
  progress: WorkflowProgress | null;
  messages: AgentMessage[];
  result: WorkflowResult | null;
  isConnected: boolean;
}

export const useWorkflowUpdates = (workflowId: string): WorkflowUpdates => {
  const [progress, setProgress] = useState<WorkflowProgress | null>(null);
  const [messages, setMessages] = useState<AgentMessage[]>([]);
  const [result, setResult] = useState<WorkflowResult | null>(null);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    let isSubscribed = true;

    const setupConnection = async () => {
      try {
        const accessToken = await getAccessToken(); // Your auth function
        await signalRService.connect('/hubs/workflow', accessToken);

        if (!isSubscribed) return;

        // Subscribe to workflow-specific updates
        await signalRService.invoke('SubscribeToWorkflow', workflowId);

        // Register event handlers
        signalRService.on<WorkflowProgress>('WorkflowProgress', (data) => {
          if (isSubscribed) setProgress(data);
        });

        signalRService.on<AgentMessage>('AgentMessage', (data) => {
          if (isSubscribed) {
            setMessages((prev) => [...prev, data]);
          }
        });

        signalRService.on<WorkflowResult>('WorkflowCompleted', (data) => {
          if (isSubscribed) setResult(data);
        });

        setIsConnected(true);
      } catch (error) {
        console.error('Failed to setup SignalR connection', error);
        setIsConnected(false);
      }
    };

    setupConnection();

    return () => {
      isSubscribed = false;
      signalRService.invoke('UnsubscribeFromWorkflow', workflowId);
      signalRService.off('WorkflowProgress');
      signalRService.off('AgentMessage');
      signalRService.off('WorkflowCompleted');
    };
  }, [workflowId]);

  return { progress, messages, result, isConnected };
};
```

#### Component Usage

```typescript
// src/components/WorkflowMonitor.tsx
import React from 'react';
import { useWorkflowUpdates } from '../hooks/useWorkflowUpdates';

interface Props {
  workflowId: string;
}

export const WorkflowMonitor: React.FC<Props> = ({ workflowId }) => {
  const { progress, messages, result, isConnected } = useWorkflowUpdates(workflowId);

  return (
    <div>
      <div>Status: {isConnected ? 'Connected' : 'Disconnected'}</div>

      {progress && (
        <div>
          <h3>Progress</h3>
          <p>Step: {progress.currentStep} / {progress.totalSteps}</p>
          <p>Status: {progress.status}</p>
        </div>
      )}

      <div>
        <h3>Messages</h3>
        {messages.map((msg, idx) => (
          <div key={idx}>
            <strong>{msg.agentName}:</strong> {msg.content}
          </div>
        ))}
      </div>

      {result && (
        <div>
          <h3>Result</h3>
          <p>Status: {result.status}</p>
          <pre>{JSON.stringify(result.output, null, 2)}</pre>
        </div>
      )}
    </div>
  );
};
```

## Authentication Flow

### Azure AD OAuth 2.0 Flow

```
1. User clicks "Sign In" → Frontend
2. Frontend redirects to Azure AD login
3. User authenticates with Azure AD
4. Azure AD redirects back with authorization code
5. Frontend exchanges code for access token
6. Frontend stores token securely (memory, not localStorage)
7. Frontend includes token in API requests (Authorization: Bearer <token>)
8. .NET API validates token with Azure AD
9. .NET API extracts user claims (user ID, roles)
10. .NET API includes token when calling Python service
11. Python service validates token (optional, trusts .NET)
```

### Frontend Authentication

```typescript
// src/auth/AuthProvider.tsx
import { MsalProvider, useMsal } from '@azure/msal-react';
import { PublicClientApplication } from '@azure/msal-browser';

const msalConfig = {
  auth: {
    clientId: import.meta.env.VITE_AZURE_CLIENT_ID,
    authority: `https://login.microsoftonline.com/${import.meta.env.VITE_AZURE_TENANT_ID}`,
    redirectUri: window.location.origin,
  },
};

const msalInstance = new PublicClientApplication(msalConfig);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return <MsalProvider instance={msalInstance}>{children}</MsalProvider>;
};

export const useAuth = () => {
  const { instance, accounts } = useMsal();

  const getAccessToken = async (): Promise<string> => {
    const request = {
      scopes: ['api://agent-studio-api/access'],
      account: accounts[0],
    };

    try {
      const response = await instance.acquireTokenSilent(request);
      return response.accessToken;
    } catch (error) {
      const response = await instance.acquireTokenPopup(request);
      return response.accessToken;
    }
  };

  return {
    isAuthenticated: accounts.length > 0,
    user: accounts[0],
    getAccessToken,
    signIn: () => instance.loginPopup(),
    signOut: () => instance.logoutPopup(),
  };
};
```

### .NET Authentication Middleware

```csharp
// Program.cs
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AgentExecute", policy =>
        policy.RequireRole("Developer", "Admin"));

    options.AddPolicy("AdminOnly", policy =>
        policy.RequireRole("Admin"));
});

app.UseAuthentication();
app.UseAuthorization();
```

## Error Handling

### Centralized Error Handling

#### .NET Global Exception Handler

```csharp
app.UseExceptionHandler(errorApp =>
{
    errorApp.Run(async context =>
    {
        var exceptionHandlerFeature = context.Features.Get<IExceptionHandlerFeature>();
        var exception = exceptionHandlerFeature?.Error;

        var problemDetails = new ProblemDetails
        {
            Title = "An error occurred",
            Status = StatusCodes.Status500InternalServerError,
            Detail = exception?.Message,
            Instance = context.Request.Path
        };

        if (exception is PythonServiceException pythonEx)
        {
            problemDetails.Status = pythonEx.StatusCode ?? 500;
            problemDetails.Extensions["pythonErrorType"] = pythonEx.PythonErrorType;
        }

        context.Response.StatusCode = problemDetails.Status.Value;
        context.Response.ContentType = "application/problem+json";

        await context.Response.WriteAsJsonAsync(problemDetails);
    });
});
```

#### React Error Boundary

```typescript
// src/components/ErrorBoundary.tsx
import React, { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: (error: Error) => ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('ErrorBoundary caught error:', error, errorInfo);
    // Send to error tracking service (e.g., Application Insights)
  }

  render() {
    if (this.state.hasError && this.state.error) {
      if (this.props.fallback) {
        return this.props.fallback(this.state.error);
      }

      return (
        <div>
          <h1>Something went wrong</h1>
          <p>{this.state.error.message}</p>
        </div>
      );
    }

    return this.props.children;
  }
}
```

## Performance Optimization

### Response Caching

#### .NET Response Caching

```csharp
builder.Services.AddResponseCaching();
builder.Services.AddMemoryCache();

app.UseResponseCaching();

// Controller
[HttpGet("{id}")]
[ResponseCache(Duration = 300)] // 5 minutes
public async Task<IActionResult> GetAgent(string id)
{
    var agent = await _agentService.GetByIdAsync(id);
    return Ok(agent);
}
```

### Connection Pooling

```csharp
// HTTP client with connection pooling (default behavior)
builder.Services.AddHttpClient<IPythonAgentClient, PythonAgentClient>()
    .SetHandlerLifetime(TimeSpan.FromMinutes(5)); // Rotate handlers every 5 min
```

### React Performance

```typescript
// Memoization
import { memo, useMemo } from 'react';

export const AgentCard = memo<Props>(({ agent }) => {
  const displayName = useMemo(
    () => formatAgentName(agent),
    [agent.id, agent.name]
  );

  return <div>{displayName}</div>;
});

// Virtual scrolling for large lists
import { useVirtualizer } from '@tanstack/react-virtual';

export const AgentList: React.FC<{ agents: Agent[] }> = ({ agents }) => {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: agents.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 100,
  });

  return (
    <div ref={parentRef} style={{ height: '600px', overflow: 'auto' }}>
      <div style={{ height: `${virtualizer.getTotalSize()}px` }}>
        {virtualizer.getVirtualItems().map(virtualRow => (
          <div key={virtualRow.key} style={{ height: virtualRow.size }}>
            <AgentCard agent={agents[virtualRow.index]} />
          </div>
        ))}
      </div>
    </div>
  );
};
```

## Testing Integration Points

### .NET Integration Tests

```csharp
public class PythonAgentClientTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly MockHttpMessageHandler _mockHandler;

    public PythonAgentClientTests(WebApplicationFactory<Program> factory)
    {
        _mockHandler = new MockHttpMessageHandler();
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task ExecuteAgent_Success_ReturnsResult()
    {
        // Arrange
        var request = new AgentExecutionRequest
        {
            AgentId = "test-agent",
            AgentType = "code_review",
            Parameters = new Dictionary<string, object> { ["test"] = "value" }
        };

        var expectedResult = new AgentExecutionResult
        {
            AgentId = "test-agent",
            Status = "completed",
            Result = new Dictionary<string, object>(),
            ExecutionTime = 1.0
        };

        _mockHandler.When("/agents/execute")
            .Respond("application/json", JsonSerializer.Serialize(expectedResult));

        // Act
        var response = await _client.PostAsJsonAsync("/api/v1/agents/test-agent/execute", request);

        // Assert
        response.EnsureSuccessStatusCode();
        var result = await response.Content.ReadFromJsonAsync<AgentExecutionResult>();
        Assert.Equal("completed", result.Status);
    }
}
```

### React Component Tests

```typescript
// src/__tests__/AgentList.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AgentList } from '../components/AgentList';
import { agentsApi } from '../api/agents';

jest.mock('../api/agents');

describe('AgentList', () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });

  it('displays agents after loading', async () => {
    const mockAgents = [
      { id: '1', name: 'Agent 1', type: 'code_review' },
      { id: '2', name: 'Agent 2', type: 'documentation' },
    ];

    (agentsApi.list as jest.Mock).mockResolvedValue(mockAgents);

    render(
      <QueryClientProvider client={queryClient}>
        <AgentList />
      </QueryClientProvider>
    );

    await waitFor(() => {
      expect(screen.getByText('Agent 1')).toBeInTheDocument();
      expect(screen.getByText('Agent 2')).toBeInTheDocument();
    });
  });
});
```

---

**Related Documentation**:
- [Architecture Overview](ARCHITECTURE.md)
- [Data Flow](DATA_FLOW.md)
- [API Reference](../api/META_AGENTS_API.md)
- [SignalR Hubs](../api/SIGNALR_HUBS.md)

**Last Updated**: 2025-10-07
**Version**: 1.0.0
