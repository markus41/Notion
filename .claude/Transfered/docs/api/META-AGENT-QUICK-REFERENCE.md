# Meta-Agent Platform API - Quick Reference

## Quick Links

- **OpenAPI Spec**: [meta-agents-api.yaml](./meta-agents-api.yaml)
- **SignalR Hub**: [meta-agent-signalr-hub.md](./meta-agent-signalr-hub.md)
- **Developer Guide**: [META-AGENT-API-GUIDE.md](./META-AGENT-API-GUIDE.md)
- **Full Summary**: [META-AGENT-API-SUMMARY.md](./META-AGENT-API-SUMMARY.md)

---

## Base URLs

```
Production:  https://api.agentstudio.dev/meta-agents/v1
Staging:     https://staging-api.agentstudio.dev/meta-agents/v1
Local:       http://localhost:5000/meta-agents/v1
SignalR Hub: wss://api.agentstudio.dev/hubs/meta-agents
```

---

## Authentication

```bash
# All requests require JWT Bearer token
curl -H "Authorization: Bearer $TOKEN" https://api.agentstudio.dev/...
```

---

## REST API Endpoints

### Workflows

```http
POST   /workflows                       # Execute new workflow
GET    /workflows                       # List workflows (paginated)
GET    /workflows/{workflowId}          # Get workflow status
DELETE /workflows/{workflowId}          # Cancel workflow
GET    /workflows/{workflowId}/results  # Get workflow results
GET    /workflows/{workflowId}/thoughts # Get agent thoughts
```

### Handoffs

```http
POST   /handoffs                        # Request agent handoff
```

### Artifacts

```http
GET    /artifacts                       # List artifacts
GET    /artifacts/{artifactId}          # Download artifact
```

### Agents

```http
GET    /agents                          # List registered meta-agents
GET    /agents/{agentId}/health         # Get agent health
```

### System

```http
GET    /health                          # System health check (no auth)
```

---

## Workflow Types

| Type | Use Case | Example |
|------|----------|---------|
| `sequential` | Step-by-step SDLC | Architect → Builder → Validator → Scribe |
| `parallel` | Multiple components | 3 builders working on different services |
| `iterative` | Quality-focused | Builder ↔ Validator feedback loop |
| `dynamic` | Complex, adaptive | Runtime-determined agent sequence |

---

## Agent Types

| Type | Role | Outputs |
|------|------|---------|
| `architect` | System design | Diagrams, specs, schemas |
| `builder` | Code generation | Source code, configs |
| `validator` | Testing, QA | Tests, reports, coverage |
| `scribe` | Documentation | OpenAPI, README, guides |

---

## Execute Workflow (Quick)

```bash
curl -X POST https://api.agentstudio.dev/meta-agents/v1/workflows \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "sequential",
    "description": "Build a REST API with authentication",
    "agents": [
      {"type": "architect"},
      {"type": "builder", "config": {"language": "python"}},
      {"type": "validator"},
      {"type": "scribe"}
    ],
    "timeout_minutes": 20
  }'
```

**Response**:
```json
{
  "workflow_id": "wf_abc123",
  "status": "queued",
  "status_url": "/meta-agents/v1/workflows/wf_abc123"
}
```

---

## SignalR Events (Server → Client)

```typescript
connection.on('WorkflowStarted', (event) => { /* ... */ });
connection.on('WorkflowCompleted', (event) => { /* ... */ });
connection.on('WorkflowFailed', (event) => { /* ... */ });
connection.on('WorkflowProgress', (event) => { /* ... */ });
connection.on('AgentStarted', (event) => { /* ... */ });
connection.on('AgentCompleted', (event) => { /* ... */ });
connection.on('AgentFailed', (event) => { /* ... */ });
connection.on('AgentThought', (event) => { /* ... */ });
connection.on('HandoffRequested', (event) => { /* ... */ });
connection.on('HandoffCompleted', (event) => { /* ... */ });
connection.on('ArtifactGenerated', (event) => { /* ... */ });
connection.on('ErrorOccurred', (event) => { /* ... */ });
connection.on('MetricUpdated', (event) => { /* ... */ });
```

---

## SignalR Methods (Client → Server)

```typescript
await connection.invoke('SubscribeToWorkflow', workflowId);
await connection.invoke('UnsubscribeFromWorkflow', workflowId);
await connection.invoke('SubscribeToAgent', agentId);
await connection.invoke('UnsubscribeFromAgent', agentId);
await connection.invoke('SubscribeToThoughts', workflowId);
await connection.invoke('UnsubscribeFromThoughts', workflowId);
const status = await connection.invoke('GetWorkflowStatus', workflowId);
const agent = await connection.invoke('GetAgentStatus', agentId);
```

---

## Common Workflow Patterns

### 1. Simple REST API

```json
{
  "type": "sequential",
  "description": "Build REST API with CRUD operations",
  "agents": [
    {"type": "architect"},
    {"type": "builder", "config": {"language": "python", "framework": "fastapi"}},
    {"type": "validator", "config": {"test_types": ["unit", "integration"]}},
    {"type": "scribe", "config": {"output_formats": ["openapi"]}}
  ]
}
```

### 2. Parallel Microservices

```json
{
  "type": "parallel",
  "description": "Build 3 microservices simultaneously",
  "agents": [
    {"type": "architect"},
    {"type": "builder", "id": "users", "config": {"service": "users-service"}},
    {"type": "builder", "id": "orders", "config": {"service": "orders-service"}},
    {"type": "builder", "id": "payments", "config": {"service": "payments-service"}},
    {"type": "validator"}
  ]
}
```

### 3. Quality-Focused Development

```json
{
  "type": "iterative",
  "description": "Build with continuous validation",
  "agents": [
    {"type": "builder"},
    {"type": "validator", "config": {"coverage_threshold": 90}}
  ],
  "context": {
    "max_iterations": 3
  }
}
```

---

## Agent Configuration Examples

### Architect

```json
{
  "type": "architect",
  "config": {
    "focus_areas": ["api_design", "security", "scalability"],
    "design_principles": ["SOLID", "DRY"],
    "tech_stack_recommendation": true
  }
}
```

### Builder

```json
{
  "type": "builder",
  "config": {
    "language": "typescript",
    "framework": "nestjs",
    "features": ["rest_api", "websockets", "jwt_auth"],
    "patterns": ["dependency_injection"]
  }
}
```

### Validator

```json
{
  "type": "validator",
  "config": {
    "test_types": ["unit", "integration", "e2e"],
    "coverage_threshold": 85,
    "test_framework": "jest",
    "security_scan": true
  }
}
```

### Scribe

```json
{
  "type": "scribe",
  "config": {
    "output_formats": ["openapi", "markdown", "html"],
    "include_examples": true,
    "diagram_format": "mermaid"
  }
}
```

---

## Error Codes (RFC 7807)

| Status | Type | Retry? |
|--------|------|--------|
| 400 | `bad-request` | No |
| 401 | `unauthorized` | Yes (refresh token) |
| 403 | `forbidden` | No |
| 404 | `not-found` | No |
| 409 | `conflict` | Maybe |
| 422 | `validation-error` | No |
| 429 | `rate-limit-exceeded` | Yes (after delay) |
| 500 | `internal-error` | Yes (with backoff) |
| 503 | `service-unavailable` | Yes (with backoff) |

---

## Rate Limits

| Tier | Workflows/hour | Requests/min | Concurrent Workflows |
|------|----------------|--------------|---------------------|
| Free | 10 | 100 | 1 |
| Developer | 50 | 500 | 3 |
| Team | 200 | 2,000 | 10 |
| Enterprise | Unlimited | Custom | Custom |

**Headers**:
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 85
X-RateLimit-Reset: 1696683600
Retry-After: 45
```

---

## Response Times (p95)

| Operation | Target |
|-----------|--------|
| POST /workflows | < 200ms |
| GET /workflows/{id} | < 50ms |
| SignalR events | < 100ms |

---

## Workflow Execution Times

| Type | Complexity | Duration |
|------|------------|----------|
| Simple REST API | Low | 15-20 min |
| Full-stack app | Medium | 45-60 min |
| Microservices (3) | Medium | 30-40 min |
| Complex migration | High | 90-120 min |

---

## Common cURL Commands

### Execute Workflow
```bash
curl -X POST https://api.agentstudio.dev/meta-agents/v1/workflows \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @workflow-request.json
```

### Get Status
```bash
curl https://api.agentstudio.dev/meta-agents/v1/workflows/wf_abc123 \
  -H "Authorization: Bearer $TOKEN"
```

### Get Results
```bash
curl https://api.agentstudio.dev/meta-agents/v1/workflows/wf_abc123/results \
  -H "Authorization: Bearer $TOKEN"
```

### Cancel Workflow
```bash
curl -X DELETE https://api.agentstudio.dev/meta-agents/v1/workflows/wf_abc123 \
  -H "Authorization: Bearer $TOKEN"
```

### Download Artifact
```bash
curl https://api.agentstudio.dev/artifacts/art_xyz789 \
  -H "Authorization: Bearer $TOKEN" \
  -o output.zip
```

### List Workflows
```bash
curl "https://api.agentstudio.dev/meta-agents/v1/workflows?status=completed&limit=20" \
  -H "Authorization: Bearer $TOKEN"
```

### Health Check
```bash
curl https://api.agentstudio.dev/meta-agents/v1/health
```

---

## TypeScript Quick Start

### Execute Workflow

```typescript
const response = await fetch('/meta-agents/v1/workflows', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    type: 'sequential',
    description: 'Build REST API',
    agents: [
      { type: 'architect' },
      { type: 'builder', config: { language: 'python' } },
      { type: 'validator' },
      { type: 'scribe' }
    ]
  })
});

const workflow = await response.json();
console.log('Workflow ID:', workflow.workflow_id);
```

### SignalR Connection

```typescript
import { HubConnectionBuilder } from '@microsoft/signalr';

const connection = new HubConnectionBuilder()
  .withUrl('/hubs/meta-agents', {
    accessTokenFactory: () => getAccessToken()
  })
  .withAutomaticReconnect()
  .build();

connection.on('WorkflowProgress', (event) => {
  console.log(`Progress: ${event.progress.percentage}%`);
});

await connection.start();
await connection.invoke('SubscribeToWorkflow', workflowId);
```

---

## Python Quick Start

### Execute Workflow

```python
import requests

response = requests.post(
    'https://api.agentstudio.dev/meta-agents/v1/workflows',
    headers={'Authorization': f'Bearer {token}'},
    json={
        'type': 'sequential',
        'description': 'Build REST API',
        'agents': [
            {'type': 'architect'},
            {'type': 'builder', 'config': {'language': 'python'}},
            {'type': 'validator'},
            {'type': 'scribe'}
        ]
    }
)

workflow = response.json()
print(f"Workflow ID: {workflow['workflow_id']}")
```

### Using Pydantic Schemas

```python
from meta_agents.api.schemas import WorkflowRequest, AgentConfig, WorkflowType, AgentType

request = WorkflowRequest(
    type=WorkflowType.SEQUENTIAL,
    description='Build REST API',
    agents=[
        AgentConfig(type=AgentType.ARCHITECT),
        AgentConfig(type=AgentType.BUILDER, config={'language': 'python'}),
        AgentConfig(type=AgentType.VALIDATOR),
        AgentConfig(type=AgentType.SCRIBE)
    ]
)

# Validate and serialize
request_json = request.model_dump_json()
```

---

## C# Quick Start

### Execute Workflow

```csharp
using AgentStudio.Api.Models.MetaAgent;

var request = new WorkflowRequest(
    Type: WorkflowType.Sequential,
    Description: "Build REST API",
    Agents: new List<AgentConfig>
    {
        new AgentConfig(AgentType.Architect),
        new AgentConfig(AgentType.Builder, Config: new Dictionary<string, object>
        {
            ["language"] = "python"
        }),
        new AgentConfig(AgentType.Validator),
        new AgentConfig(AgentType.Scribe)
    }
);

var response = await httpClient.PostAsJsonAsync("/meta-agents/v1/workflows", request);
var workflow = await response.Content.ReadFromJsonAsync<WorkflowResponse>();
Console.WriteLine($"Workflow ID: {workflow.WorkflowId}");
```

---

## Troubleshooting

### Workflow Stuck
```bash
# Check agent availability
curl https://api.agentstudio.dev/meta-agents/v1/agents?status=available \
  -H "Authorization: Bearer $TOKEN"
```

### Rate Limited
```bash
# Check rate limit headers
curl -I https://api.agentstudio.dev/meta-agents/v1/workflows \
  -H "Authorization: Bearer $TOKEN"

# Wait for reset time (X-RateLimit-Reset header)
```

### SignalR Disconnected
```typescript
// Reconnect manually
await connection.stop();
await connection.start();

// Resubscribe to workflows
await connection.invoke('SubscribeToWorkflow', workflowId);
```

---

## File Locations

### API Specifications
- `docs/api/meta-agents-api.yaml` - OpenAPI 3.1 spec
- `docs/api/meta-agent-signalr-hub.md` - SignalR contract

### Python Implementation
- `src/python/meta_agents/api/schemas.py` - Pydantic schemas

### .NET Implementation
- `services/dotnet/AgentStudio.Api/Models/MetaAgent/WorkflowModels.cs`
- `services/dotnet/AgentStudio.Api/Models/MetaAgent/AgentModels.cs`
- `services/dotnet/AgentStudio.Api/Models/MetaAgent/HandoffModels.cs`
- `services/dotnet/AgentStudio.Api/Models/MetaAgent/ArtifactModels.cs`
- `services/dotnet/AgentStudio.Api/Models/MetaAgent/CallbackModels.cs`
- `services/dotnet/AgentStudio.Api/Models/MetaAgent/SystemModels.cs`

---

## Support

- **Docs**: https://docs.agentstudio.dev/meta-agents
- **Discord**: https://discord.gg/agentstudio
- **Email**: api-support@agentstudio.dev

---

## Version

**Version**: 1.0.0
**Last Updated**: 2025-10-07
**Status**: ✅ Ready for Implementation
