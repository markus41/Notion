# Meta-Agent Platform API Documentation

Complete API specifications and documentation for the Meta-Agent Platform's multi-layer architecture.

## Overview

The Meta-Agent Platform enables orchestration of specialized AI agents (Architect, Builder, Validator, Scribe) to collaboratively design, build, validate, and document software through a sophisticated multi-layer API architecture.

```
React Frontend (UI) ←→ .NET Orchestrator (API + SignalR) ←→ Python Meta-Agents (Workers)
```

---

## Quick Navigation

### Core Specifications

| File | Purpose | Lines | Status |
|------|---------|-------|--------|
| [meta-agents-api.yaml](./meta-agents-api.yaml) | OpenAPI 3.1 REST API specification | 1,800+ | ✅ Complete |
| [meta-agent-signalr-hub.md](./meta-agent-signalr-hub.md) | SignalR real-time communication contract | 680 | ✅ Complete |
| [META-AGENT-API-GUIDE.md](./META-AGENT-API-GUIDE.md) | Developer guide with examples | 1,500+ | ✅ Complete |
| [META-AGENT-API-SUMMARY.md](./META-AGENT-API-SUMMARY.md) | Comprehensive summary document | 1,200+ | ✅ Complete |

### Implementation Files

| File | Purpose | Lines | Status |
|------|---------|-------|--------|
| [../src/python/meta_agents/api/schemas.py](../../src/python/meta_agents/api/schemas.py) | Python Pydantic schemas | 900+ | ✅ Complete |
| [../services/dotnet/AgentStudio.Api/Models/MetaAgent/*.cs](../../services/dotnet/AgentStudio.Api/Models/MetaAgent/) | .NET C# models (6 files) | 650+ | ✅ Complete |

---

## Getting Started

### 1. Explore the API

**View OpenAPI Specification**:
```bash
# Using Swagger Editor online
open https://editor.swagger.io

# Import: docs/api/meta-agents-api.yaml
```

**Run Mock Server (for testing)**:
```bash
# Install Prism
npm install -g @stoplight/prism-cli

# Start mock server
cd docs/api
prism mock meta-agents-api.yaml -p 4010

# Test endpoint
curl http://localhost:4010/meta-agents/v1/health
```

### 2. Execute Your First Workflow

```bash
# Set authentication token
export TOKEN="your-jwt-token-here"

# Execute a simple workflow
curl -X POST https://api.agentstudio.dev/meta-agents/v1/workflows \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "sequential",
    "description": "Build a simple REST API",
    "agents": [
      {"type": "architect"},
      {"type": "builder", "config": {"language": "python", "framework": "fastapi"}},
      {"type": "validator", "config": {"test_types": ["unit", "integration"]}},
      {"type": "scribe", "config": {"output_formats": ["openapi", "markdown"]}}
    ],
    "timeout_minutes": 20
  }'

# Response includes workflow_id
# {
#   "workflow_id": "wf_abc123",
#   "status": "queued",
#   ...
# }

# Check status
curl https://api.agentstudio.dev/meta-agents/v1/workflows/wf_abc123 \
  -H "Authorization: Bearer $TOKEN"

# Get results when completed
curl https://api.agentstudio.dev/meta-agents/v1/workflows/wf_abc123/results \
  -H "Authorization: Bearer $TOKEN"
```

### 3. Monitor in Real-Time (React/TypeScript)

```typescript
import { HubConnectionBuilder } from '@microsoft/signalr';

// Connect to SignalR hub
const connection = new HubConnectionBuilder()
  .withUrl('/hubs/meta-agents', {
    accessTokenFactory: () => getAccessToken()
  })
  .withAutomaticReconnect()
  .build();

// Subscribe to events
connection.on('WorkflowProgress', (event) => {
  console.log(`Progress: ${event.progress.percentage}%`);
  console.log(`Current step: ${event.progress.currentStep}`);
});

connection.on('WorkflowCompleted', (event) => {
  console.log('Workflow completed!');
  fetchResults(event.workflowId);
});

// Start connection and subscribe
await connection.start();
await connection.invoke('SubscribeToWorkflow', 'wf_abc123');
```

---

## Architecture

### Communication Layers

```
┌───────────────────────────────────────────────────┐
│              React Frontend (Layer 3)              │
│  - Workflow execution UI                           │
│  - Real-time progress monitoring                   │
│  - Artifact downloads                              │
└─────────────────┬──────────────────┬──────────────┘
                  │                  │
           REST API             SignalR
      (CRUD operations)    (Real-time events)
                  │                  │
                  ↓                  ↓
┌───────────────────────────────────────────────────┐
│        .NET Orchestrator (Layer 1)                 │
│  - Workflow orchestration                          │
│  - Agent coordination                              │
│  - SignalR hub                                     │
│  - State machine execution                         │
└─────────────────┬──────────────────┬──────────────┘
                  │                  │
        Control Plane API    Callback API
       (.NET → Python)     (Python → .NET)
                  │                  │
                  ↓                  ↑
┌───────────────────────────────────────────────────┐
│         Python Meta-Agents (Layer 2)               │
│  ┌──────────┐ ┌─────────┐ ┌──────────┐ ┌───────┐ │
│  │Architect │ │ Builder │ │Validator │ │Scribe │ │
│  └──────────┘ └─────────┘ └──────────┘ └───────┘ │
└───────────────────────────────────────────────────┘
```

### API Layers

| Layer | Protocol | Purpose | Files |
|-------|----------|---------|-------|
| **React ↔ .NET** | REST + SignalR | Frontend UI operations, real-time updates | `meta-agents-api.yaml`, `meta-agent-signalr-hub.md` |
| **.NET ↔ Python** | REST/gRPC | Agent task execution and control | `openapi-orchestrator-control-plane.yaml` |
| **Python ↔ .NET** | REST/gRPC | Progress callbacks, handoffs | `openapi-agent-callbacks.yaml` |

---

## Meta-Agent Types

### 1. Architect
- **Role**: System design and architecture
- **Outputs**: Architecture diagrams, technical specs, database schemas
- **Config**: `focus_areas`, `design_principles`, `tech_stack_recommendation`

### 2. Builder
- **Role**: Code generation and implementation
- **Outputs**: Source code, configuration files, migrations
- **Config**: `language`, `framework`, `features`, `patterns`

### 3. Validator
- **Role**: Testing and quality assurance
- **Outputs**: Tests, test reports, coverage reports
- **Config**: `test_types`, `coverage_threshold`, `security_scan`

### 4. Scribe
- **Role**: Documentation generation
- **Outputs**: OpenAPI specs, README files, API docs
- **Config**: `output_formats`, `include_examples`, `diagram_format`

---

## Workflow Patterns

### 1. Sequential
**Pattern**: Architect → Builder → Validator → Scribe

**Use Case**: Full SDLC, step-by-step processes

**Example**: Building a complete REST API with tests and docs

### 2. Parallel
**Pattern**: Agents execute simultaneously

**Use Case**: Building multiple microservices, independent components

**Example**: Building users, orders, and payments services in parallel

### 3. Iterative
**Pattern**: Builder ↔ Validator feedback loop

**Use Case**: Quality-focused development, continuous improvement

**Example**: Test-driven development with multiple refinement iterations

### 4. Dynamic
**Pattern**: Runtime-determined workflow path

**Use Case**: Complex requirements, adaptive workflows

**Example**: Architect assesses complexity and requests appropriate agents

---

## Key Features

### Agent Thoughts
Track real-time reasoning and decisions from agents:
```typescript
connection.on('AgentThought', (event) => {
  console.log(`${event.agentType}: ${event.content}`);
  console.log(`Confidence: ${event.confidence * 100}%`);
});
```

### Agent Handoffs
Agents can request help from other agents:
```json
{
  "from_agent_type": "builder",
  "to_agent_type": "architect",
  "reason": "Need database schema guidance"
}
```

### Artifact Management
All generated artifacts (code, docs, diagrams) are tracked and downloadable:
```bash
curl https://api.agentstudio.dev/artifacts/{artifactId} \
  -H "Authorization: Bearer $TOKEN" \
  -o output.zip
```

### Real-Time Progress
Monitor workflow execution via SignalR events:
- `WorkflowProgress`: Progress updates
- `AgentStarted`: Agent begins work
- `AgentCompleted`: Agent finishes
- `ArtifactGenerated`: New artifact created

---

## Complete Examples

### Example 1: Simple REST API (20 minutes)
Build a basic CRUD API with authentication.

**See**: [META-AGENT-API-GUIDE.md](./META-AGENT-API-GUIDE.md#quick-start) for complete example

### Example 2: Full-Stack Application (60 minutes)
Build a complete task management app with React + NestJS.

**See**: [META-AGENT-API-GUIDE.md](./META-AGENT-API-GUIDE.md#example-1-full-stack-application) for complete example

### Example 3: API-First Development (45 minutes)
Design OpenAPI spec first, then generate code and SDKs.

**See**: [META-AGENT-API-GUIDE.md](./META-AGENT-API-GUIDE.md#example-2-api-first-development) for complete example

---

## Implementation Guide

### For Frontend Developers (React/TypeScript)

1. **Read**: [meta-agent-signalr-hub.md](./meta-agent-signalr-hub.md)
2. **Use**: SignalR TypeScript client examples
3. **Generate**: TypeScript SDK from OpenAPI spec:
   ```bash
   npx @openapitools/openapi-generator-cli generate \
     -i meta-agents-api.yaml \
     -g typescript-fetch \
     -o src/api/generated
   ```

### For Backend Developers (.NET/C#)

1. **Read**: [meta-agents-api.yaml](./meta-agents-api.yaml)
2. **Use**: C# models in `services/dotnet/AgentStudio.Api/Models/MetaAgent/`
3. **Implement**: SignalR Hub from [meta-agent-signalr-hub.md](./meta-agent-signalr-hub.md)

### For Agent Developers (Python)

1. **Read**: [META-AGENT-API-GUIDE.md](./META-AGENT-API-GUIDE.md)
2. **Use**: Pydantic schemas in `src/python/meta_agents/api/schemas.py`
3. **Implement**: Agent logic using provided schemas

---

## API Reference

### REST API Endpoints

```
# Workflows
POST   /workflows                       # Execute workflow
GET    /workflows                       # List workflows
GET    /workflows/{id}                  # Get workflow status
DELETE /workflows/{id}                  # Cancel workflow
GET    /workflows/{id}/results          # Get results
GET    /workflows/{id}/thoughts         # Get agent thoughts

# Handoffs
POST   /handoffs                        # Request handoff

# Artifacts
GET    /artifacts                       # List artifacts
GET    /artifacts/{id}                  # Download artifact

# Agents
GET    /agents                          # List agents
GET    /agents/{id}/health              # Agent health

# System
GET    /health                          # System health
```

### SignalR Events (Server → Client)

```typescript
WorkflowStarted          // Workflow begins
WorkflowCompleted        // Workflow succeeds
WorkflowFailed           // Workflow fails
WorkflowProgress         // Progress updates
AgentStarted             // Agent begins
AgentCompleted           // Agent completes
AgentFailed              // Agent fails
AgentThought             // Agent reasoning
HandoffRequested         // Handoff initiated
HandoffCompleted         // Handoff resolved
ArtifactGenerated        // Artifact created
ErrorOccurred            // System error
MetricUpdated            // Performance metrics
```

### SignalR Methods (Client → Server)

```typescript
SubscribeToWorkflow      // Subscribe to workflow events
UnsubscribeFromWorkflow  // Unsubscribe
SubscribeToAgent         // Subscribe to agent events
UnsubscribeFromAgent     // Unsubscribe
SubscribeToThoughts      // Subscribe to thought stream
UnsubscribeFromThoughts  // Unsubscribe
GetWorkflowStatus        // Query workflow status
GetAgentStatus           // Query agent status
```

---

## Authentication

All API requests require JWT authentication:

```http
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Obtain Token**:
```bash
curl -X POST https://auth.agentstudio.dev/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "password",
    "username": "user@example.com",
    "password": "password",
    "client_id": "meta-agent-client",
    "scope": "workflows:execute"
  }'
```

---

## Error Handling

All errors follow RFC 7807 Problem Details:

```json
{
  "type": "https://api.agentstudio.dev/problems/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "Request validation failed",
  "instance": "/meta-agents/v1/workflows",
  "errors": [
    {
      "field": "agents",
      "message": "At least one agent is required",
      "code": "MIN_ITEMS"
    }
  ],
  "trace_id": "1a2b3c4d5e6f"
}
```

---

## Rate Limiting

Rate limits apply per tier:

| Tier | Workflows/hour | Requests/min |
|------|----------------|--------------|
| Free | 10 | 100 |
| Developer | 50 | 500 |
| Team | 200 | 2,000 |
| Enterprise | Unlimited | Custom |

**Headers**:
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 85
X-RateLimit-Reset: 1696683600
Retry-After: 45
```

---

## Performance

### Latency Targets (p95)

| Operation | Target |
|-----------|--------|
| POST /workflows | < 200ms |
| GET /workflows/{id} | < 50ms |
| SignalR events | < 100ms |

### Workflow Execution Times

| Workflow Type | Complexity | Duration |
|---------------|------------|----------|
| Simple REST API | Low | 15-20 min |
| Full-stack app | Medium | 45-60 min |
| Microservices | Medium | 30-40 min |
| Complex migration | High | 90-120 min |

---

## Development Tools

### Mock Server (Testing)

```bash
# Install Prism
npm install -g @stoplight/prism-cli

# Start mock server
prism mock meta-agents-api.yaml -p 4010

# Test endpoints
curl http://localhost:4010/meta-agents/v1/workflows
```

### OpenAPI Validation

```bash
# Install Spectral
npm install -g @stoplight/spectral-cli

# Validate OpenAPI spec
spectral lint meta-agents-api.yaml
```

### SDK Generation

**TypeScript**:
```bash
npx @openapitools/openapi-generator-cli generate \
  -i meta-agents-api.yaml \
  -g typescript-fetch \
  -o src/api/generated
```

**Python**:
```bash
pip install openapi-python-client

openapi-python-client generate \
  --path meta-agents-api.yaml \
  --output-path ./client
```

**C#**:
```bash
dotnet add package NSwag.MSBuild

# Add to .csproj:
# <OpenApiReference Include="meta-agents-api.yaml" />
```

---

## Testing

### Contract Testing

Validate all requests/responses against OpenAPI schema:

```typescript
import { validateAgainstSchema } from 'openapi-validator-middleware';

test('POST /workflows matches schema', async () => {
  const response = await executeWorkflow(request);
  const validation = validateAgainstSchema(
    response,
    'meta-agents-api.yaml',
    '/workflows',
    'post'
  );
  expect(validation.valid).toBe(true);
});
```

### Integration Testing

```bash
# Start services
docker-compose up -d

# Run integration tests
npm run test:integration

# Test specific workflow
npm run test:workflow:sequential
```

### Load Testing

```bash
# Using k6
k6 run --vus 100 --duration 30s load-test-workflows.js
```

---

## Troubleshooting

### Workflow Stuck in "Queued"
**Cause**: All agents busy
**Solution**: Check agent availability at `/agents?status=available`

### SignalR Connection Drops
**Cause**: Network issues, timeout
**Solution**: Use automatic reconnection with exponential backoff

### Workflow Timeout
**Cause**: Complex workflow, slow agents
**Solution**: Increase `timeout_minutes` or break into smaller workflows

### Agent Handoff Rejected
**Cause**: Target agent unavailable
**Solution**: Provide more context in handoff request

See [META-AGENT-API-GUIDE.md](./META-AGENT-API-GUIDE.md#troubleshooting) for complete troubleshooting guide.

---

## Best Practices

1. **Use appropriate workflow type** for your use case
2. **Provide detailed context** in workflow requests
3. **Subscribe selectively** to SignalR events
4. **Handle reconnection** gracefully
5. **Validate requests** before submission
6. **Respect rate limits** with proper throttling
7. **Implement retry logic** with exponential backoff
8. **Monitor workflows** in real-time for better UX

See [META-AGENT-API-GUIDE.md](./META-AGENT-API-GUIDE.md#best-practices) for detailed best practices.

---

## Related Documentation

### Existing API Specifications

The Meta-Agent API builds upon the existing Agent Studio API infrastructure:

- [openapi-orchestrator-control-plane.yaml](./openapi-orchestrator-control-plane.yaml) - Control Plane API (.NET → Python)
- [openapi-agent-callbacks.yaml](./openapi-agent-callbacks.yaml) - Callback API (Python → .NET)
- [openapi-frontend-api.yaml](./openapi-frontend-api.yaml) - Frontend API (React → .NET)
- [signalr-hub-contract.md](./signalr-hub-contract.md) - Base SignalR Hub
- [message-schemas.proto](./message-schemas.proto) - Protocol Buffers definitions
- [API-DESIGN-GUIDE.md](./API-DESIGN-GUIDE.md) - API design principles

### Architecture Documentation

- [ARCHITECTURE.md](../../ARCHITECTURE.md) - Overall platform architecture
- [DATA_LAYER_DESIGN.md](../DATA_LAYER_DESIGN.md) - Database and data layer design

---

## Support

### Documentation

- **API Reference**: https://docs.agentstudio.dev/meta-agents
- **Developer Portal**: https://developers.agentstudio.dev
- **Changelog**: https://docs.agentstudio.dev/changelog

### Community

- **GitHub**: https://github.com/agentstudio/meta-agents
- **Discord**: https://discord.gg/agentstudio
- **Stack Overflow**: Tag `meta-agents`

### Contact

- **Technical Support**: api-support@agentstudio.dev
- **Security Issues**: security@agentstudio.dev

---

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for contribution guidelines.

When contributing to the API:
1. Follow existing patterns and conventions
2. Update OpenAPI spec for any endpoint changes
3. Update schemas in both Python and C#
4. Add examples to documentation
5. Write contract tests
6. Update changelog

---

## Changelog

### Version 1.0.0 (2025-10-07)

**Added**:
- Complete Meta-Agent REST API specification
- SignalR Hub contract for real-time communication
- Python Pydantic schemas (40+ models)
- .NET C# models (35+ types)
- Comprehensive developer guide with examples
- 4 workflow patterns (sequential, parallel, iterative, dynamic)
- 4 meta-agent types (Architect, Builder, Validator, Scribe)
- Agent thought tracking
- Agent handoff coordination
- Artifact management
- System health monitoring

**Status**: ✅ **READY FOR IMPLEMENTATION**

---

## License

MIT License - See [LICENSE](../../LICENSE) for details.

---

**Last Updated**: 2025-10-07
**Version**: 1.0.0
**Maintainers**: Agent Studio API Team
