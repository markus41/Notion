# ADR 002: Meta-Agent Architecture

## Status

Accepted

## Context

We need to design a scalable, maintainable architecture for orchestrating multiple AI agents in complex workflows. The system must support sequential, concurrent, and group chat patterns while maintaining state, ensuring reliability, and providing real-time observability.

### Key Requirements

1. **Multi-Agent Coordination**: Orchestrate multiple AI agents working together
2. **Workflow Patterns**: Support sequential, concurrent, and group chat execution
3. **State Management**: Maintain and checkpoint workflow state for recovery
4. **Real-time Updates**: Provide live progress updates to users
5. **Scalability**: Handle multiple concurrent workflow executions
6. **Technology Diversity**: Leverage .NET, Python, and React for their strengths
7. **Cloud-Native**: Deploy to Azure with managed services

### Constraints

- Must integrate with Azure OpenAI for LLM capabilities
- Must support long-running workflows (> 5 minutes)
- Must be cost-effective at scale
- Must provide enterprise-grade security and compliance

## Decision

We will implement a **polyglot microservices architecture** with the following components:

### Architecture Components

1. **.NET Orchestration Service** (C# / ASP.NET Core)
   - **Role**: Workflow orchestration and coordination
   - **Rationale**: .NET excels at coordination, state management, and integration with Azure services. Strong type safety and performance for orchestration logic.
   - **Responsibilities**:
     - Workflow lifecycle management
     - State persistence and checkpointing
     - Agent coordination and handoffs
     - Real-time communication via SignalR
     - Authentication and authorization

2. **Python Agent Service** (Python / FastAPI)
   - **Role**: Agent execution and LLM integration
   - **Rationale**: Python is the de facto standard for AI/ML work with rich ecosystem (LangChain, Semantic Kernel, etc.). Async support via FastAPI for high concurrency.
   - **Responsibilities**:
     - LLM API integration (Azure OpenAI, OpenAI)
     - Agent execution logic
     - Prompt management and optimization
     - Tool execution (MCP tools)
     - Embedding generation

3. **React Frontend** (TypeScript / React)
   - **Role**: User interface and real-time monitoring
   - **Rationale**: React provides excellent developer experience and component ecosystem. TypeScript adds type safety.
   - **Responsibilities**:
     - Agent and workflow configuration UI
     - Real-time execution monitoring
     - Dashboard and analytics
     - SignalR client for live updates

4. **Data Layer**
   - **Cosmos DB**: Agent metadata, workflow definitions, execution history
   - **Azure Blob Storage**: Large artifacts (results, logs, models)
   - **Azure Cache for Redis**: Session state, distributed locks, caching
   - **Azure Cognitive Search**: Semantic search over agents and workflows

### Communication Patterns

1. **REST API**: Synchronous request/response for CRUD operations
2. **SignalR**: Real-time bidirectional communication for workflow updates
3. **HTTP Streaming**: Server-sent events for long-running agent executions
4. **Message Queue**: Azure Service Bus for async background processing (future)

### Workflow Execution Flow

```
User → Frontend → .NET API → Cosmos DB (create execution)
                           ↓
                    Background Service (orchestrator)
                           ↓
                    Python Service (execute agent) → Azure OpenAI
                           ↓
                    Cosmos DB (save checkpoint)
                           ↓
                    SignalR → Frontend (update UI)
```

## Consequences

### Positive

1. **Best Tool for Each Job**
   - .NET for orchestration and state management
   - Python for AI/ML workloads
   - React for modern UI

2. **Scalability**
   - Services scale independently
   - Stateless design enables horizontal scaling
   - Checkpointing enables workflow recovery

3. **Developer Productivity**
   - Teams can work in their preferred languages
   - Rich ecosystem for each technology
   - Type safety in .NET and TypeScript reduces bugs

4. **Observability**
   - OpenTelemetry distributed tracing across all services
   - SignalR provides real-time visibility
   - Structured logging with correlation IDs

5. **Azure Integration**
   - First-class support for Azure services
   - Managed identity for authentication
   - Native Azure monitoring and diagnostics

### Negative

1. **Complexity**
   - Multiple languages and runtimes to maintain
   - Inter-service communication adds latency
   - More moving parts to debug

2. **Operational Overhead**
   - Multiple deployment pipelines
   - Coordinated version management
   - Distributed system challenges (network partitions, etc.)

3. **Learning Curve**
   - Developers need familiarity with multiple stacks
   - Integration testing is more complex
   - Debugging spans multiple services

4. **Cost**
   - Multiple App Services
   - Always-on Cosmos DB and Redis
   - SignalR service costs for scale

### Mitigations

1. **Complexity**: Comprehensive documentation, clear service boundaries, well-defined APIs
2. **Operational Overhead**: CI/CD automation, infrastructure as code, centralized logging
3. **Learning Curve**: Developer guides, code samples, pair programming
4. **Cost**: Auto-scaling, resource right-sizing, consumption-based pricing where possible

## Alternatives Considered

### Monolith (.NET Only)

**Pros**: Simpler deployment, single codebase, easier debugging
**Cons**: Miss out on Python AI/ML ecosystem, harder to scale individual concerns
**Rejected**: Python ecosystem too valuable for AI agent development

### Monolith (Python Only)

**Pros**: Single language, great for ML
**Cons**: Less ideal for orchestration, weaker typing, slower than .NET for coordination
**Rejected**: .NET better suited for workflow orchestration and state management

### Serverless (Azure Functions)

**Pros**: Pay-per-execution, infinite scale, no server management
**Cons**: Cold start latency, complex state management, difficult to debug long-running workflows
**Rejected**: Long-running workflows not well-suited to serverless constraints

### Kubernetes-based (all containers)

**Pros**: Maximum flexibility, portability across clouds
**Cons**: Operational complexity, team expertise required, overhead for our scale
**Deferred**: May adopt as scale grows, but Azure App Service sufficient initially

## Implementation Notes

### Phase 1: Core Architecture (Current)
- .NET API with basic workflow orchestration
- Python service with agent execution
- React frontend with basic UI
- Cosmos DB and Redis integration
- SignalR for real-time updates

### Phase 2: Advanced Features (Next 3 months)
- Group chat workflow pattern
- Advanced checkpointing strategies
- Vector database integration
- Cost tracking and optimization
- Multi-region deployment

### Phase 3: Enterprise Features (6-12 months)
- Multi-tenancy support
- Advanced RBAC and audit logging
- Custom agent marketplace
- Workflow templates and versioning
- Performance optimization at scale

## References

- [Architecture Overview](../meta-agents/ARCHITECTURE.md)
- [Integration Guide](../meta-agents/INTEGRATION.md)
- [Microsoft Agentic Framework](https://github.com/microsoft/autogen)
- [Azure Architecture Center](https://docs.microsoft.com/azure/architecture/)

---

**Date**: 2025-10-01
**Authors**: Architecture Team
**Reviewers**: Engineering Leadership
**Status**: Accepted and Implemented
