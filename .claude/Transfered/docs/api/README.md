---
title: Agent Studio API Documentation
description: Build sustainable integrations with production-ready API specifications designed for enterprise AI agent orchestration and management.
tags:
  - api
  - documentation
  - openapi
  - specifications
  - integration
  - developer-experience
lastUpdated: 2025-10-09
author: Agent Studio Team
audience: developers
---

# Agent Studio API Specifications

## Overview

This directory contains comprehensive, production-ready API specifications for the Agent Studio meta-agent platform. All APIs are designed following industry best practices with a focus on developer experience, performance, security, and scalability.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         React Frontend                           │
└───────────────┬─────────────────────────────────┬───────────────┘
                │ REST API (CRUD)                 │ SignalR (Real-time)
                │ OpenAPI 3.1                     │ WebSocket
                ↓                                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                    .NET Orchestrator                             │
│                   (ASP.NET Core 8.0)                             │
└───────────┬─────────────────────────────────────┬───────────────┘
            │ Control Plane                       │ Callback API
            │ (REST/gRPC)                         │ (REST/gRPC)
            ↓                                     ↑
┌─────────────────────────────────────────────────────────────────┐
│                      Python Agents                               │
│                     (FastAPI/gRPC)                               │
└─────────────────────────────────────────────────────────────────┘
```

## API Specifications

### 1. Control Plane API (.NET → Python)

**File**: [`openapi-orchestrator-control-plane.yaml`](./openapi-orchestrator-control-plane.yaml)

**Purpose**: Execute and manage tasks on Python agents

**Key Features**:
- Task execution with async processing
- Agent health monitoring and status checks
- Task cancellation and lifecycle management
- Result retrieval with artifact support
- Log streaming for real-time debugging

**Base URL**: `https://api.agentstudio.dev/v1`

**Authentication**: JWT Bearer Token or API Key

**Key Endpoints**:
```
POST   /tasks                  # Execute new task
GET    /tasks/{taskId}         # Get task status
POST   /tasks/{taskId}/cancel  # Cancel task
GET    /tasks/{taskId}/results # Get task results
GET    /tasks/{taskId}/logs    # Stream task logs
GET    /agents                 # List agents
GET    /agents/{agentId}       # Get agent details
GET    /agents/{agentId}/health # Agent health check
GET    /health                 # System health
```

**Example Usage**:
```bash
# Execute a task
curl -X POST https://api.agentstudio.dev/v1/tasks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "agent_id": "analyst-agent-01",
    "task_type": "analyze",
    "input": {
      "data": "Sample data to analyze"
    },
    "priority": "normal",
    "timeout_seconds": 300
  }'

# Response
{
  "task_id": "task_xyz789",
  "status": "pending",
  "agent_id": "analyst-agent-01",
  "created_at": "2025-10-07T10:30:00Z",
  "status_url": "/v1/tasks/task_xyz789"
}
```

---

### 2. Callback API (Python → .NET)

**File**: [`openapi-agent-callbacks.yaml`](./openapi-agent-callbacks.yaml)

**Purpose**: Agents send progress, completion, and error notifications to orchestrator

**Key Features**:
- Progress updates with metrics
- Completion notifications with results
- Error reporting with retry guidance
- Handoff requests for workflow routing
- Heartbeat signals for health monitoring

**Base URL**: `https://orchestrator.agentstudio.dev/callbacks/v1`

**Authentication**: Agent JWT Token

**Key Endpoints**:
```
POST   /progress    # Report task progress
POST   /completion  # Report task completion
POST   /error       # Report task error
POST   /handoff     # Request agent handoff
POST   /heartbeat   # Send agent heartbeat
```

**Example Usage**:
```python
import requests

# Report progress
response = requests.post(
    "https://orchestrator.agentstudio.dev/callbacks/v1/progress",
    headers={
        "Authorization": f"Bearer {agent_token}",
        "X-Agent-ID": "analyst-agent-01",
        "X-Idempotency-Key": str(uuid.uuid4())
    },
    json={
        "task_id": "task_xyz789",
        "workflow_id": "wf_abc123",
        "timestamp": "2025-10-07T10:31:00Z",
        "progress": {
            "percentage": 45,
            "current_step": "Processing data",
            "message": "Processed 4500 of 10000 items"
        },
        "metrics": {
            "cpu_usage_percent": 67.5,
            "memory_usage_mb": 1024
        }
    }
)
```

---

### 3. SignalR Hub Contract

**File**: [`signalr-hub-contract.md`](./signalr-hub-contract.md)

**Purpose**: Real-time bidirectional communication between .NET and React

**Key Features**:
- Workflow lifecycle events (started, completed)
- Task status changes and progress updates
- Agent status monitoring
- Real-time log streaming
- Performance metric updates
- Error notifications

**Hub URL**: `wss://api.agentstudio.dev/hubs/agentstudio`

**Authentication**: JWT via query string or headers

**Server-to-Client Events**:
```typescript
connection.on('WorkflowStarted', (event) => { /* ... */ });
connection.on('WorkflowCompleted', (event) => { /* ... */ });
connection.on('TaskStatusChanged', (event) => { /* ... */ });
connection.on('TaskProgressUpdated', (event) => { /* ... */ });
connection.on('AgentStatusChanged', (event) => { /* ... */ });
connection.on('LogMessageReceived', (message) => { /* ... */ });
connection.on('MetricUpdated', (update) => { /* ... */ });
connection.on('ErrorOccurred', (error) => { /* ... */ });
```

**Client-to-Server Methods**:
```typescript
await connection.invoke('SubscribeToWorkflow', workflowId);
await connection.invoke('SubscribeToTask', taskId);
await connection.invoke('SubscribeToAgent', agentId);
await connection.invoke('SubscribeToLogs', { taskId, minLevel: 'info' });
```

**Example Usage**:
```typescript
import { HubConnectionBuilder } from '@microsoft/signalr';

const connection = new HubConnectionBuilder()
  .withUrl('/hubs/agentstudio', {
    accessTokenFactory: () => getAccessToken()
  })
  .withAutomaticReconnect()
  .build();

// Subscribe to workflow events
connection.on('TaskProgressUpdated', (event) => {
  console.log(`Task ${event.taskId}: ${event.progress.percentage}%`);
  updateProgressBar(event.progress.percentage);
});

await connection.start();
await connection.invoke('SubscribeToWorkflow', 'wf_abc123');
```

---

### 4. Frontend API (React → .NET)

**File**: [`openapi-frontend-api.yaml`](./openapi-frontend-api.yaml)

**Purpose**: CRUD operations for workflows, agents, executions, and settings

**Key Features**:
- Workflow management (create, update, delete, clone)
- Workflow execution and validation
- Agent registration and monitoring
- Execution history and analytics
- User settings and preferences

**Base URL**: `https://app.agentstudio.dev/api/v1`

**Authentication**: JWT Bearer Token

**Key Endpoints**:
```
# Workflows
GET    /workflows              # List workflows
POST   /workflows              # Create workflow
GET    /workflows/{id}         # Get workflow
PUT    /workflows/{id}         # Update workflow (full)
PATCH  /workflows/{id}         # Update workflow (partial)
DELETE /workflows/{id}         # Delete/archive workflow
POST   /workflows/{id}/execute # Execute workflow
POST   /workflows/{id}/validate # Validate workflow
POST   /workflows/{id}/clone   # Clone workflow

# Agents
GET    /agents                 # List agents
POST   /agents                 # Register agent
GET    /agents/{id}            # Get agent
PUT    /agents/{id}            # Update agent
DELETE /agents/{id}            # Unregister agent
GET    /agents/{id}/metrics    # Get agent metrics

# Executions
GET    /executions             # List executions
GET    /executions/{id}        # Get execution
DELETE /executions/{id}        # Cancel execution
GET    /executions/{id}/traces # Get execution traces

# Settings
GET    /settings               # Get settings
PUT    /settings               # Update settings

# Analytics
GET    /analytics/summary      # Get analytics summary
```

**Example Usage**:
```typescript
// Create a workflow
const response = await fetch('https://app.agentstudio.dev/api/v1/workflows', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    name: 'Customer Feedback Analysis',
    description: 'Analyze customer feedback and generate insights',
    type: 'sequential',
    steps: [
      {
        id: 'step1',
        name: 'Gather Feedback',
        agent_id: 'data-collector-01',
        task_type: 'collect',
        config: { source: 'customer_feedback_db' }
      },
      {
        id: 'step2',
        name: 'Analyze Sentiment',
        agent_id: 'analyst-agent-01',
        task_type: 'analyze',
        depends_on: ['step1']
      }
    ],
    tags: ['analytics', 'customer-service'],
    timeout_seconds: 600
  })
});

const workflow = await response.json();
console.log(`Created workflow: ${workflow.id}`);
```

---

### 5. Message Schemas (Protocol Buffers)

**File**: [`message-schemas.proto`](./message-schemas.proto)

**Purpose**: Strongly-typed message definitions for gRPC and efficient binary serialization

**Key Features**:
- Complete message schemas for all data types
- gRPC service definitions (optional)
- Support for both REST (JSON) and gRPC (Protobuf)
- Backward compatibility versioning

**Usage**:

**C# Code Generation**:
```bash
dotnet add package Grpc.Tools
dotnet add package Google.Protobuf
dotnet add package Grpc.Net.Client

# Add to .csproj
<ItemGroup>
  <Protobuf Include="message-schemas.proto" GrpcServices="Client" />
</ItemGroup>
```

**Python Code Generation**:
```bash
pip install grpcio grpcio-tools

python -m grpc_tools.protoc \
  --python_out=. \
  --grpc_python_out=. \
  message-schemas.proto
```

**Example Usage (C#)**:
```csharp
using AgentStudio.Messages.V1;
using Grpc.Net.Client;

var channel = GrpcChannel.ForAddress("https://api.agentstudio.dev");
var client = new AgentControlService.AgentControlServiceClient(channel);

var request = new TaskRequest
{
    TaskId = "task_xyz789",
    AgentId = "analyst-agent-01",
    TaskType = "analyze",
    Priority = Priority.Normal,
    Timeout = Duration.FromTimeSpan(TimeSpan.FromMinutes(5))
};

var response = await client.ExecuteTaskAsync(request);
Console.WriteLine($"Task queued: {response.TaskId}");
```

**Example Usage (Python)**:
```python
import grpc
from agentstudio.v1 import agent_control_pb2, agent_control_pb2_grpc

channel = grpc.insecure_channel('api.agentstudio.dev:443')
stub = agent_control_pb2_grpc.AgentControlServiceStub(channel)

request = agent_control_pb2.TaskRequest(
    task_id='task_xyz789',
    agent_id='analyst-agent-01',
    task_type='analyze',
    priority=agent_control_pb2.PRIORITY_NORMAL
)

response = stub.ExecuteTask(request)
print(f'Task queued: {response.task_id}')
```

---

## API Design Guide

**File**: [`API-DESIGN-GUIDE.md`](./API-DESIGN-GUIDE.md)

Comprehensive guide covering:

1. **Error Handling Patterns**
   - RFC 7807 Problem Details standard
   - Error code taxonomy
   - Transient vs permanent error classification
   - Client retry strategies

2. **API Versioning Strategy**
   - URL path versioning (`/v1/`, `/v2/`)
   - 18-month deprecation lifecycle
   - Backward compatibility rules
   - Migration guides

3. **Authentication & Authorization**
   - JWT Bearer tokens (primary)
   - API keys (service-to-service)
   - OAuth 2.0 flows (Authorization Code + PKCE, Client Credentials)
   - RBAC and scope-based permissions

4. **Rate Limiting & Throttling**
   - Token bucket algorithm
   - Per-user and per-endpoint limits
   - Adaptive rate limiting based on load
   - Fair queuing strategies

5. **gRPC vs REST Evaluation**
   - Decision matrix
   - Hybrid architecture recommendation
   - Implementation roadmap
   - Performance benchmarks

6. **Performance Optimization**
   - HTTP/2 and HTTP/3 support
   - Compression strategies (gzip, Brotli)
   - Caching patterns (HTTP cache, CDN)
   - Database query optimization

7. **Security Best Practices**
   - Input validation
   - SQL injection prevention
   - CORS configuration
   - Content Security Policy

8. **Monitoring & Observability**
   - OpenTelemetry integration
   - Metrics collection
   - Structured logging
   - Health check endpoints

---

## Quick Start

### 1. Explore API Specifications

All OpenAPI specs can be viewed in:
- **Swagger UI**: Import YAML files into https://editor.swagger.io
- **Postman**: Import OpenAPI specs as collections
- **VS Code**: Use REST Client or OpenAPI extensions

### 2. Generate Client SDKs

**TypeScript (Frontend)**:
```bash
npm install @openapitools/openapi-generator-cli

openapi-generator-cli generate \
  -i openapi-frontend-api.yaml \
  -g typescript-fetch \
  -o src/api/generated
```

**C# (.NET)**:
```bash
dotnet add package NSwag.MSBuild

# Add to .csproj
<ItemGroup>
  <OpenApiReference Include="openapi-orchestrator-control-plane.yaml"
    Namespace="AgentStudio.ControlPlane.Client" />
</ItemGroup>
```

**Python (Agents)**:
```bash
pip install openapi-python-client

openapi-python-client generate \
  --path openapi-agent-callbacks.yaml \
  --config python-client-config.yaml
```

### 3. Run Mock Servers (Development)

**Using Prism**:
```bash
npm install -g @stoplight/prism-cli

# Mock Control Plane API
prism mock openapi-orchestrator-control-plane.yaml -p 4010

# Mock Callback API
prism mock openapi-agent-callbacks.yaml -p 4011

# Mock Frontend API
prism mock openapi-frontend-api.yaml -p 4012
```

### 4. Validate Requests/Responses

**Using Spectral (OpenAPI Linter)**:
```bash
npm install -g @stoplight/spectral-cli

spectral lint openapi-*.yaml
```

---

## Testing Strategy

### Contract Testing

Use OpenAPI specifications as the source of truth for contract tests:

```typescript
import { validateAgainstSchema } from 'openapi-validator-middleware';

describe('Task API', () => {
  it('should match OpenAPI schema for POST /tasks', async () => {
    const response = await fetch('/v1/tasks', {
      method: 'POST',
      body: JSON.stringify(taskRequest)
    });

    const validation = await validateAgainstSchema(
      response,
      'openapi-orchestrator-control-plane.yaml',
      '/tasks',
      'post'
    );

    expect(validation.valid).toBe(true);
  });
});
```

### Integration Testing

Test full workflows using actual API implementations:

```bash
# Start services
docker-compose up -d

# Run integration tests
npm run test:integration
```

### Load Testing

Test performance under load:

```bash
# Using k6
k6 run --vus 100 --duration 30s load-test-tasks.js

# Using Apache Bench
ab -n 10000 -c 100 -H "Authorization: Bearer $TOKEN" \
  https://api.agentstudio.dev/v1/tasks
```

---

## Implementation Checklist

### Phase 1: REST APIs (Week 1-2)

- [ ] Implement Control Plane REST API (.NET)
- [ ] Implement Callback REST API (.NET)
- [ ] Implement Frontend CRUD API (.NET)
- [ ] Create Python agent client library
- [ ] Set up API documentation (Swagger UI)
- [ ] Configure authentication (JWT)
- [ ] Implement basic rate limiting
- [ ] Add health check endpoints

### Phase 2: Real-time Communication (Week 3)

- [ ] Implement SignalR Hub (.NET)
- [ ] Create React SignalR client
- [ ] Set up event subscriptions
- [ ] Implement connection management
- [ ] Add reconnection logic
- [ ] Test real-time event flow

### Phase 3: gRPC Migration (Week 4-5)

- [ ] Generate gRPC code from .proto
- [ ] Implement gRPC Control Plane service
- [ ] Implement gRPC Callback service
- [ ] Create Python gRPC clients
- [ ] Performance testing (gRPC vs REST)
- [ ] Load testing and optimization

### Phase 4: Production Hardening (Week 6)

- [ ] Implement comprehensive error handling
- [ ] Add OpenTelemetry instrumentation
- [ ] Set up monitoring dashboards
- [ ] Configure rate limiting per tier
- [ ] Security audit and penetration testing
- [ ] Create runbooks for operations
- [ ] Write migration guides
- [ ] API documentation review

---

## API Metrics and SLAs

### Availability

- **Target**: 99.9% uptime (8.76 hours downtime/year)
- **Monitoring**: Health checks every 30 seconds
- **Alerting**: PagerDuty for < 99.5% in 5-minute window

### Performance

| Operation | Target Latency (p95) | Target Throughput |
|-----------|---------------------|-------------------|
| POST /tasks | < 200ms | 1000 req/sec |
| GET /tasks/{id} | < 50ms | 5000 req/sec |
| SignalR events | < 100ms | 10000 events/sec |
| gRPC ExecuteTask | < 100ms | 5000 req/sec |

### Rate Limits

See [API Design Guide - Rate Limiting](./API-DESIGN-GUIDE.md#rate-limiting--throttling) for detailed limits per tier.

---

## Security

### Authentication

All APIs require authentication except:
- `GET /health` (system health check)
- OpenAPI spec endpoints

### Authorization

Access control via:
- **RBAC**: Role-based permissions (viewer, executor, editor, admin)
- **Scopes**: Fine-grained permissions (workflows:read, tasks:execute, etc.)
- **Resource Ownership**: Users can only access their own resources

### Data Protection

- **Encryption in Transit**: TLS 1.3
- **Encryption at Rest**: AES-256
- **PII Handling**: Automatic redaction in logs
- **Audit Logging**: All API calls logged with user context

---

## Support and Resources

### Documentation

- **API Reference**: https://docs.agentstudio.dev/api
- **Developer Portal**: https://developers.agentstudio.dev
- **Changelog**: https://docs.agentstudio.dev/changelog

### Community

- **Discord**: https://discord.gg/agentstudio
- **GitHub Discussions**: https://github.com/agentstudio/api/discussions
- **Stack Overflow**: Tag `agent-studio`

### Support

- **Email**: api-support@agentstudio.dev
- **Response Time**: 24 hours (business days)
- **Priority Support**: Available for Enterprise tier

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-10-07 | Initial release of all API specifications |

---

## License

All API specifications are released under the MIT License. See [LICENSE](../../LICENSE) for details.
