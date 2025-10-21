# Meta-Agent Platform Architecture

## Table of Contents

- [System Overview](#system-overview)
- [Architecture Diagram](#architecture-diagram)
- [Component Architecture](#component-architecture)
- [Technology Stack](#technology-stack)
- [Integration Patterns](#integration-patterns)
- [Scalability Considerations](#scalability-considerations)
- [Security Architecture](#security-architecture)
- [Data Architecture](#data-architecture)

## System Overview

The Meta-Agent Platform (Agent Studio) is a cloud-native, enterprise-grade SaaS platform for building, deploying, and managing AI agent workflows. The platform leverages Microsoft's Agentic Framework to enable sophisticated multi-agent coordination, orchestration, and execution at scale.

### Core Value Propositions

- **Multi-Agent Orchestration**: Coordinate multiple AI agents in complex workflows with sequential, concurrent, and group chat patterns
- **Enterprise-Ready**: Azure-native design with comprehensive security, observability, and compliance
- **Developer Experience**: Rich tooling for agent development, testing, and deployment
- **Scalability**: Designed to scale from development to production workloads
- **Observability**: Built-in OpenTelemetry instrumentation for distributed tracing and monitoring

### Design Principles

1. **Cloud-Native First**: Built for Azure, leveraging managed services for resilience and scalability
2. **Polyglot Architecture**: Leverage the best language for each concern (.NET, Python, TypeScript)
3. **API-First Design**: All functionality exposed through well-defined REST and SignalR APIs
4. **Observable by Default**: OpenTelemetry instrumentation throughout the stack
5. **Security by Design**: Azure AD, Key Vault, RBAC, and defense-in-depth security
6. **DevOps Automation**: CI/CD pipelines, IaC, and automated testing baked in

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Client Applications                             │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐     │
│  │   Web UI         │  │   CLI Tools      │  │   External APIs  │     │
│  │   (React)        │  │                  │  │                  │     │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘     │
└───────────┼─────────────────────┼─────────────────────┼───────────────┘
            │                     │                     │
            └─────────────────────┴─────────────────────┘
                                  │
                         ┌────────▼────────┐
                         │   Azure Front   │
                         │      Door       │
                         └────────┬────────┘
                                  │
            ┌─────────────────────┼─────────────────────┐
            │                     │                     │
   ┌────────▼────────┐   ┌───────▼────────┐   ┌───────▼────────┐
   │   API Gateway    │   │   SignalR      │   │   CDN          │
   │   (APIM)         │   │   Service      │   │   (Static      │
   └────────┬─────────┘   └───────┬────────┘   │   Assets)      │
            │                     │             └────────────────┘
            │                     │
    ┌───────┴────────────────────┴───────┐
    │        Application Layer            │
    │                                     │
    │  ┌─────────────────────────────┐   │
    │  │   .NET Orchestration API    │   │
    │  │   (ASP.NET Core 8.0)        │   │
    │  │                             │   │
    │  │  - Agent Management         │   │
    │  │  - Workflow Orchestration   │   │
    │  │  - State Management         │   │
    │  │  - SignalR Hubs             │   │
    │  │  - OpenTelemetry            │   │
    │  └──────────┬──────────────────┘   │
    │             │                       │
    │  ┌──────────▼──────────────────┐   │
    │  │   Python Agent Service      │   │
    │  │   (FastAPI)                 │   │
    │  │                             │   │
    │  │  - Agent Execution          │   │
    │  │  - ML Model Integration     │   │
    │  │  - LLM Orchestration        │   │
    │  │  - Tool Execution           │   │
    │  │  - OpenTelemetry            │   │
    │  └──────────┬──────────────────┘   │
    └─────────────┼──────────────────────┘
                  │
    ┌─────────────┴──────────────────────┐
    │       Integration Layer             │
    │                                     │
    │  ┌──────────────┐  ┌────────────┐  │
    │  │ MCP Tools    │  │ Azure      │  │
    │  │ (Node.js)    │  │ OpenAI     │  │
    │  └──────────────┘  └────────────┘  │
    └─────────────────────────────────────┘
                  │
    ┌─────────────┴──────────────────────┐
    │         Data & State Layer          │
    │                                     │
    │  ┌─────────────┐  ┌─────────────┐  │
    │  │  Cosmos DB  │  │  Azure      │  │
    │  │  (State,    │  │  Storage    │  │
    │  │  Metadata)  │  │  (Artifacts)│  │
    │  └─────────────┘  └─────────────┘  │
    │                                     │
    │  ┌─────────────┐  ┌─────────────┐  │
    │  │  Redis      │  │  Vector DB  │  │
    │  │  (Cache,    │  │  (Semantic  │  │
    │  │  Sessions)  │  │  Search)    │  │
    │  └─────────────┘  └─────────────┘  │
    └─────────────────────────────────────┘
                  │
    ┌─────────────┴──────────────────────┐
    │    Platform & Observability Layer   │
    │                                     │
    │  ┌─────────────┐  ┌─────────────┐  │
    │  │ Application │  │  Azure      │  │
    │  │  Insights   │  │  Monitor    │  │
    │  └─────────────┘  └─────────────┘  │
    │                                     │
    │  ┌─────────────┐  ┌─────────────┐  │
    │  │  Key Vault  │  │  Azure AD   │  │
    │  │  (Secrets)  │  │  (Identity) │  │
    │  └─────────────┘  └─────────────┘  │
    └─────────────────────────────────────┘
```

## Component Architecture

### Frontend Layer (React + TypeScript)

**Purpose**: User interface for agent and workflow management

**Responsibilities**:
- Agent configuration and deployment UI
- Workflow designer and visualization
- Real-time execution monitoring (via SignalR)
- Dashboard and analytics
- User authentication and authorization

**Technology Stack**:
- React 18 with TypeScript 5
- Vite 5 for build tooling
- Tailwind CSS 3 for styling
- TanStack Query for data fetching
- SignalR client for real-time updates
- React Router for navigation

**Key Design Patterns**:
- Component composition with hooks
- State management with React Context and TanStack Query
- Real-time updates via SignalR subscriptions
- Optimistic UI updates for better UX
- Error boundaries for fault isolation

### .NET Orchestration Service (ASP.NET Core 8.0)

**Purpose**: Workflow orchestration, state management, and coordination

**Responsibilities**:
- Workflow lifecycle management (create, start, stop, monitor)
- Agent coordination and handoff logic
- State persistence and checkpointing
- Real-time communication via SignalR
- API gateway for frontend and external integrations
- Authentication and authorization enforcement

**Technology Stack**:
- ASP.NET Core 8.0 Web API
- SignalR for real-time communication
- Entity Framework Core for data access
- OpenTelemetry for observability
- Azure SDK for service integration

**Key Design Patterns**:
- Repository pattern for data access
- Mediator pattern (MediatR) for CQRS
- Strategy pattern for workflow execution strategies
- State Machine pattern for workflow state management
- Circuit breaker for resilience (Polly)

**API Endpoints**:
```
POST   /api/v1/agents                 - Create agent
GET    /api/v1/agents                 - List agents
GET    /api/v1/agents/{id}            - Get agent details
PUT    /api/v1/agents/{id}            - Update agent
DELETE /api/v1/agents/{id}            - Delete agent

POST   /api/v1/workflows              - Create workflow
GET    /api/v1/workflows              - List workflows
GET    /api/v1/workflows/{id}         - Get workflow
POST   /api/v1/workflows/{id}/execute - Execute workflow
GET    /api/v1/workflows/{id}/status  - Get execution status
POST   /api/v1/workflows/{id}/cancel  - Cancel execution
```

### Python Agent Service (FastAPI)

**Purpose**: Agent execution, LLM integration, and ML model serving

**Responsibilities**:
- Agent execution engine
- LLM API integration (Azure OpenAI, OpenAI)
- Tool execution (MCP tools, custom tools)
- Prompt management and optimization
- Embedding generation and vector operations
- ML model inference

**Technology Stack**:
- FastAPI for high-performance async API
- Pydantic for data validation
- LangChain/Semantic Kernel for LLM orchestration
- OpenTelemetry for observability
- httpx for async HTTP requests

**Key Design Patterns**:
- Dependency injection for service composition
- Chain of Responsibility for agent processing pipeline
- Strategy pattern for different agent types
- Observer pattern for execution monitoring
- Adapter pattern for LLM provider abstraction

**API Endpoints**:
```
POST   /agents/execute              - Execute single agent
POST   /agents/stream               - Stream agent execution
POST   /tools/execute               - Execute tool
GET    /models/list                 - List available models
POST   /embeddings/generate         - Generate embeddings
```

### Model Context Protocol (MCP) Tools (Node.js)

**Purpose**: Standardized tool interface for agent capabilities

**Responsibilities**:
- Tool registration and discovery
- Tool execution and validation
- Schema-based tool definitions
- Parameter validation and transformation
- Tool versioning and compatibility

**Technology Stack**:
- Node.js 20 with TypeScript
- Model Context Protocol specification
- JSON Schema for validation
- OpenAPI for documentation

### Data Layer

#### Cosmos DB (NoSQL Database)

**Purpose**: Agent metadata, workflow state, and execution history

**Data Models**:
- **Agents**: Agent configurations and capabilities
- **Workflows**: Workflow definitions and templates
- **Executions**: Workflow execution history and results
- **Checkpoints**: Workflow state snapshots for recovery
- **Users**: User profiles and preferences

**Partitioning Strategy**:
- Agents: Partitioned by `organizationId`
- Workflows: Partitioned by `organizationId`
- Executions: Partitioned by `workflowId`

**Consistency Model**: Eventual consistency with session consistency for user operations

#### Azure Blob Storage

**Purpose**: Large artifact storage (models, datasets, results)

**Storage Containers**:
- `agent-artifacts`: Agent-specific files and resources
- `workflow-results`: Execution outputs and reports
- `model-cache`: Cached model files
- `user-uploads`: User-uploaded files

#### Redis Cache

**Purpose**: Session state, distributed locks, and caching

**Use Cases**:
- Session management for SignalR connections
- Distributed locks for workflow execution coordination
- Cache for frequently accessed agent configurations
- Rate limiting state
- Real-time execution metrics

#### Vector Database (Azure Cognitive Search / Pinecone)

**Purpose**: Semantic search over agents, workflows, and documentation

**Indexed Content**:
- Agent descriptions and capabilities
- Workflow templates and examples
- Execution logs for similarity search
- Tool documentation

## Technology Stack

### Frontend
| Technology | Version | Purpose |
|------------|---------|---------|
| React | 18.x | UI framework |
| TypeScript | 5.x | Type-safe JavaScript |
| Vite | 5.x | Build tool |
| Tailwind CSS | 3.x | Utility-first CSS |
| TanStack Query | 5.x | Data fetching and caching |
| SignalR Client | Latest | Real-time communication |

### Backend (.NET)
| Technology | Version | Purpose |
|------------|---------|---------|
| ASP.NET Core | 8.0 | Web API framework |
| SignalR | 8.0 | Real-time communication |
| EF Core | 8.0 | ORM for data access |
| MediatR | 12.x | Mediator pattern (CQRS) |
| Polly | 8.x | Resilience and fault handling |
| OpenTelemetry | 1.x | Observability |

### Backend (Python)
| Technology | Version | Purpose |
|------------|---------|---------|
| FastAPI | 0.115+ | Async web framework |
| Pydantic | 2.10+ | Data validation |
| LangChain | Latest | LLM orchestration |
| httpx | 0.28+ | Async HTTP client |
| OpenTelemetry | 1.30+ | Observability |

### Infrastructure (Azure)
| Service | Purpose |
|---------|---------|
| Azure App Service | Application hosting |
| Azure Cosmos DB | NoSQL database |
| Azure Blob Storage | Artifact storage |
| Azure Cache for Redis | Distributed cache |
| Azure Cognitive Search | Vector database |
| Azure Key Vault | Secrets management |
| Azure AD | Authentication/Authorization |
| Azure Monitor | Logging and metrics |
| Application Insights | APM and tracing |
| Azure Front Door | Global load balancing |
| Azure API Management | API gateway |

## Integration Patterns

### .NET to Python Communication

**Pattern**: HTTP-based microservices communication with circuit breaker

```csharp
// .NET -> Python agent execution
public async Task<AgentResult> ExecuteAgentAsync(AgentRequest request)
{
    using var activity = ActivitySource.StartActivity("ExecuteAgent");
    activity?.SetTag("agent.id", request.AgentId);

    var response = await _httpClient.PostAsJsonAsync(
        "/agents/execute",
        request,
        cancellationToken
    );

    response.EnsureSuccessStatusCode();
    return await response.Content.ReadFromJsonAsync<AgentResult>();
}
```

**Resilience**:
- Circuit breaker pattern with Polly
- Retry with exponential backoff
- Timeout policies (30s default)
- Bulkhead isolation for different agent types

### Frontend to Backend Communication

**Pattern**: REST API + SignalR for real-time updates

**REST API** (Request/Response):
```typescript
// Agent creation
const createAgent = async (agent: AgentConfig): Promise<Agent> => {
  const response = await fetch('/api/v1/agents', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(agent),
  });
  return response.json();
};
```

**SignalR** (Real-time updates):
```typescript
// Workflow execution updates
connection.on('WorkflowProgress', (update: WorkflowUpdate) => {
  updateWorkflowState(update);
});

connection.on('AgentMessage', (message: AgentMessage) => {
  appendToExecutionLog(message);
});
```

### Agent-to-Agent Communication

**Pattern**: Message-based coordination via .NET orchestrator

1. **Sequential**: Orchestrator passes output of Agent A to Agent B
2. **Concurrent**: Orchestrator spawns multiple agents in parallel
3. **Group Chat**: Agents communicate via shared context, orchestrator moderates

```
Agent A → Orchestrator → Agent B → Orchestrator → Agent C
                ↓
         [State Store]
```

### External Service Integration

**Azure OpenAI**:
```python
# Python service integrates with Azure OpenAI
from openai import AzureOpenAI

client = AzureOpenAI(
    api_key=config.azure_openai_key,
    api_version="2024-02-01",
    azure_endpoint=config.azure_openai_endpoint
)

response = await client.chat.completions.create(
    model="gpt-4",
    messages=messages,
    stream=True
)
```

**MCP Tools**:
```typescript
// Node.js MCP tool execution
interface MCPTool {
  name: string;
  description: string;
  inputSchema: JSONSchema;
  execute(params: unknown): Promise<ToolResult>;
}
```

## Scalability Considerations

### Horizontal Scaling

**Application Layer**:
- Stateless .NET and Python services scale independently
- Azure App Service auto-scaling based on CPU, memory, request count
- Minimum 2 instances per service for HA

**Data Layer**:
- Cosmos DB auto-scales based on RU/s consumption
- Redis clustered mode for distributed cache
- Blob Storage scales automatically

### Vertical Scaling

**Compute Tiers**:
- **Development**: B1 (1 core, 1.75GB RAM)
- **Staging**: P1v3 (2 cores, 8GB RAM)
- **Production**: P2v3 (4 cores, 16GB RAM)

### Performance Optimization

**Caching Strategy**:
- Redis cache for agent configurations (TTL: 5 minutes)
- HTTP response caching for static data
- SignalR connection scaling with Azure SignalR Service

**Database Optimization**:
- Cosmos DB indexing for common queries
- Query pagination with continuation tokens
- Batch operations for bulk writes

**Asynchronous Processing**:
- Azure Service Bus for background jobs
- Long-running workflows executed asynchronously
- Queue-based load leveling for burst traffic

### Load Distribution

**Geographic Distribution**:
- Azure Front Door for global routing
- Multi-region deployment (primary + secondary)
- Geo-replication for Cosmos DB

## Security Architecture

### Authentication & Authorization

**Azure AD Integration**:
- OAuth 2.0 / OpenID Connect for user authentication
- JWT bearer tokens for API authentication
- Managed Identity for service-to-service authentication

**RBAC Model**:
```
Roles:
- Platform Admin: Full system access
- Organization Admin: Manage organization agents and workflows
- Developer: Create and test agents
- Viewer: Read-only access

Permissions:
- agents:read, agents:write, agents:execute
- workflows:read, workflows:write, workflows:execute
- system:admin
```

### Secrets Management

**Azure Key Vault**:
- API keys (OpenAI, external services)
- Database connection strings
- Service principal credentials
- Encryption keys

**Managed Identity**:
- Services access Key Vault via Managed Identity
- No secrets in application code or configuration
- Automatic credential rotation

### Network Security

**Defense in Depth**:
```
Internet
    ↓
Azure Front Door (DDoS, WAF)
    ↓
API Management (Throttling, IP filtering)
    ↓
VNet (Network isolation)
    ↓
App Services (Private endpoints)
    ↓
Data Services (Firewall rules, Private Link)
```

**Network Isolation**:
- VNet integration for App Services
- Private endpoints for Cosmos DB, Storage, Redis
- Network security groups for fine-grained control
- Azure Firewall for egress filtering

### Data Security

**Encryption**:
- Data at rest: Azure Storage Service Encryption (256-bit AES)
- Data in transit: TLS 1.2+ for all connections
- Key management: Customer-managed keys in Key Vault

**Data Privacy**:
- GDPR compliance with data residency controls
- PII detection and masking in logs
- Data retention policies (90 days for logs, configurable for data)

### Security Monitoring

**Threat Detection**:
- Azure Security Center continuous monitoring
- Azure Sentinel for SIEM
- Anomaly detection on API usage patterns

**Audit Logging**:
- All API operations logged to Application Insights
- Security events logged to Azure Monitor
- Compliance reports generated monthly

## Data Architecture

### Data Flow Patterns

**Agent Execution Flow**:
```
1. User initiates workflow → .NET API
2. .NET API creates execution record → Cosmos DB
3. .NET API calls Python service → HTTP
4. Python service executes agent → Azure OpenAI
5. Python service stores results → Blob Storage
6. Python service returns summary → .NET API
7. .NET API updates execution → Cosmos DB
8. .NET API pushes update → SignalR → Frontend
```

**State Management**:
- **Optimistic Concurrency**: ETag-based versioning in Cosmos DB
- **Checkpointing**: Workflow state snapshots every superstep
- **Recovery**: Workflows resume from last checkpoint on failure

### Data Consistency

**Consistency Levels**:
- **Strong Consistency**: User profile updates, billing operations
- **Session Consistency**: User-facing read-after-write scenarios
- **Eventual Consistency**: Analytics, reporting, audit logs

**Distributed Transactions**:
- Saga pattern for cross-service transactions
- Compensation logic for rollback scenarios
- Idempotency keys for retry safety

### Data Retention

| Data Type | Retention | Archive |
|-----------|-----------|---------|
| Execution logs | 90 days | 1 year in cold storage |
| Agent configurations | Indefinite | N/A |
| Workflow results | 1 year | 3 years in cold storage |
| Audit logs | 7 years | Compliant archive |
| Metrics/Telemetry | 30 days | Aggregated data 1 year |

---

**Related Documentation**:
- [Integration Guide](INTEGRATION.md)
- [Data Flow](DATA_FLOW.md)
- [Deployment Guide](DEPLOYMENT.md)
- [API Reference](../api/META_AGENTS_API.md)

**Last Updated**: 2025-10-07
**Version**: 1.0.0
