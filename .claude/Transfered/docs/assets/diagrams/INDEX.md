# Agent Studio Mermaid Diagrams Catalog

Comprehensive catalog of 100+ Mermaid diagrams for Agent Studio documentation. This visual library streamlines knowledge transfer and improves data visibility across all team operations.

## Quick Navigation

- [Architecture Diagrams](#architecture-diagrams) (15 diagrams)
- [Workflow Patterns](#workflow-patterns) (12 diagrams)
- [Data Flows](#data-flows) (20 diagrams)
- [Integration Patterns](#integration-patterns) (15 diagrams)
- [Security Diagrams](#security-diagrams) (10 diagrams)
- [Deployment Pipeline](#deployment-pipeline) (8 diagrams)
- [Database Schemas](#database-schemas) (12 diagrams)
- [Monitoring & Observability](#monitoring--observability) (8 diagrams)

---

## Architecture Diagrams

Comprehensive system architecture visualizations showing C4 models, deployment topologies, and service communication patterns.

### C4 Model Diagrams

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [c4-context.mmd](architecture/c4-context.mmd) | System context diagram | Shows Agent Studio in context with external users and systems | 2025-10-14 |
| [c4-container.mmd](architecture/c4-container.mmd) | Container-level architecture | Displays all major components and their interactions | 2025-10-14 |
| [c4-component-orchestrator.mmd](architecture/c4-component-orchestrator.mmd) | .NET orchestrator internals | Deep dive into orchestration service components | 2025-10-14 |
| [c4-component-agents.mmd](architecture/c4-component-agents.mmd) | Python agent service components | Internal architecture of meta-agents service | 2025-10-14 |
| [c4-component-frontend.mmd](architecture/c4-component-frontend.mmd) | React frontend architecture | Component structure of web application | 2025-10-14 |

### Deployment Topologies

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [deployment-local.mmd](architecture/deployment-local.mmd) | Local development setup | Docker-based local development environment | 2025-10-14 |
| [deployment-azure-basic.mmd](architecture/deployment-azure-basic.mmd) | Basic Azure deployment | Single-region deployment for dev/staging | 2025-10-14 |
| [deployment-azure-ha.mmd](architecture/deployment-azure-ha.mmd) | High-availability deployment | Production-grade multi-AZ deployment | 2025-10-14 |
| [deployment-multi-region.mmd](architecture/deployment-multi-region.mmd) | Global multi-region setup | Worldwide distribution for enterprise scale | 2025-10-14 |
| [deployment-topology.mmd](architecture/deployment-topology.mmd) | General deployment patterns | Overview of deployment strategies | 2025-10-14 |

### Service Communication

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [service-mesh.mmd](architecture/service-mesh.mmd) | Service mesh architecture | Istio/Linkerd service communication | 2025-10-14 |
| [api-gateway-pattern.mmd](architecture/api-gateway-pattern.mmd) | API gateway pattern | Single entry point for microservices | 2025-10-14 |
| [event-driven-architecture.mmd](architecture/event-driven-architecture.mmd) | Event-driven patterns | Asynchronous event-based communication | 2025-10-14 |
| [pub-sub-pattern.mmd](architecture/pub-sub-pattern.mmd) | Publish-subscribe architecture | Decoupled message distribution | 2025-10-14 |
| [microservices-boundaries.mmd](architecture/microservices-boundaries.mmd) | Service boundaries | Domain contexts and dependencies | 2025-10-14 |

### Infrastructure & Networking

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [network-topology.mmd](architecture/network-topology.mmd) | Network architecture | VNet, subnets, and security zones | 2025-10-14 |
| [scaling-architecture.mmd](architecture/scaling-architecture.mmd) | Scaling patterns | Horizontal and vertical scaling strategies | 2025-10-14 |
| [integration-patterns.mmd](architecture/integration-patterns.mmd) | Integration overview | External system integration patterns | 2025-10-14 |

---

## Workflow Patterns

Detailed workflow execution patterns showing sequential, parallel, and complex orchestration scenarios.

### Basic Patterns

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [sequential-basic.mmd](workflows/sequential-basic.mmd) | Simple sequential flow | Linear task execution | 2025-10-14 |
| [sequential-with-checkpoints.mmd](workflows/sequential-with-checkpoints.mmd) | Sequential with recovery | Checkpoint creation and recovery | 2025-10-14 |
| [sequential-workflow.mmd](workflows/sequential-workflow.mmd) | Advanced sequential | Complex sequential patterns | 2025-10-14 |
| [parallel-basic.mmd](workflows/parallel-basic.mmd) | Basic parallel execution | Independent task parallelization | 2025-10-14 |
| [parallel-with-dependencies.mmd](workflows/parallel-with-dependencies.mmd) | Parallel with dependencies | Complex dependency management | 2025-10-14 |
| [parallel-workflow.mmd](workflows/parallel-workflow.mmd) | Advanced parallel patterns | Multi-level parallelization | 2025-10-14 |

### Advanced Patterns

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [saga-pattern.mmd](workflows/saga-pattern.mmd) | Saga pattern template | Distributed transactions with compensation | 2025-10-14 |
| [saga-example.mmd](workflows/saga-example.mmd) | Real-world saga example | Order processing with rollback | 2025-10-14 |
| [event-driven-workflow.mmd](workflows/event-driven-workflow.mmd) | Event-driven orchestration | Reactive workflow execution | 2025-10-14 |
| [dynamic-workflow.mmd](workflows/dynamic-workflow.mmd) | Dynamic routing | Runtime-determined execution paths | 2025-10-14 |
| [iterative-feedback.mmd](workflows/iterative-feedback.mmd) | Iterative improvement | Feedback loops with validators | 2025-10-14 |
| [group-chat-pattern.mmd](workflows/group-chat-pattern.mmd) | Multi-agent collaboration | Group chat coordination pattern | 2025-10-14 |
| [handoff-pattern.mmd](workflows/handoff-pattern.mmd) | Agent handoff | Task delegation between agents | 2025-10-14 |
| [workflow-state-machine.mmd](workflows/workflow-state-machine.mmd) | State machine | Complete workflow state transitions | 2025-10-14 |

---

## Data Flows

Comprehensive data flow diagrams showing how information moves through the system.

### Agent Execution Flows

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [agent-execution-simple.mmd](data-flows/agent-execution-simple.mmd) | Basic agent execution | Simple task processing flow | 2025-10-14 |
| [agent-execution-with-llm.mmd](data-flows/agent-execution-with-llm.mmd) | LLM integration flow | Agent with AI model calls | 2025-10-14 |
| [agent-execution-streaming.mmd](data-flows/agent-execution-streaming.mmd) | Streaming responses | Server-sent events flow | 2025-10-14 |
| [agent-execution-error-handling.mmd](data-flows/agent-execution-error-handling.mmd) | Error handling flow | Failure recovery patterns | 2025-10-14 |
| [agent-context-passing.mmd](data-flows/agent-context-passing.mmd) | Context propagation | Inter-agent context flow | 2025-10-14 |
| [agent-memory-persistence.mmd](data-flows/agent-memory-persistence.mmd) | Memory management | Agent state persistence | 2025-10-14 |

### Real-time Communication

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [signalr-connection-lifecycle.mmd](data-flows/signalr-connection-lifecycle.mmd) | SignalR lifecycle | Connection management flow | 2025-10-14 |
| [signalr-event-flow.mmd](data-flows/signalr-event-flow.mmd) | Event propagation | Real-time update distribution | 2025-10-14 |
| [signalr-reconnection.mmd](data-flows/signalr-reconnection.mmd) | Reconnection logic | Automatic reconnection handling | 2025-10-14 |
| [signalr-group-management.mmd](data-flows/signalr-group-management.mmd) | Group subscriptions | Workflow subscription management | 2025-10-14 |

### State Management

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [state-initialization.mmd](data-flows/state-initialization.mmd) | State initialization | Workflow state setup | 2025-10-14 |
| [state-checkpoint-creation.mmd](data-flows/state-checkpoint-creation.mmd) | Checkpoint creation | Recovery point creation | 2025-10-14 |
| [state-recovery.mmd](data-flows/state-recovery.mmd) | Recovery flow | Checkpoint restoration | 2025-10-14 |
| [state-concurrency-control.mmd](data-flows/state-concurrency-control.mmd) | Concurrency control | Optimistic locking flow | 2025-10-14 |
| [state-versioning.mmd](data-flows/state-versioning.mmd) | Version management | State version control | 2025-10-14 |

### Event Sourcing

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [event-sourcing-write.mmd](data-flows/event-sourcing-write.mmd) | Event write flow | Append-only event storage | 2025-10-14 |
| [event-sourcing-read.mmd](data-flows/event-sourcing-read.mmd) | Event read projection | Materialized view creation | 2025-10-14 |
| [event-sourcing-replay.mmd](data-flows/event-sourcing-replay.mmd) | Event replay | State reconstruction from events | 2025-10-14 |
| [event-store-architecture.mmd](data-flows/event-store-architecture.mmd) | Event store design | Complete event storage architecture | 2025-10-14 |
| [cqrs-pattern.mmd](data-flows/cqrs-pattern.mmd) | CQRS implementation | Command-query separation | 2025-10-14 |

---

## Integration Patterns

External service integration patterns and API communication flows.

### Azure Service Integrations

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [azure-openai-integration.mmd](integrations/azure-openai-integration.mmd) | Azure OpenAI integration | LLM service integration | 2025-10-14 |
| [azure-cosmos-db.mmd](integrations/azure-cosmos-db.mmd) | Cosmos DB patterns | Data access patterns | 2025-10-14 |
| [azure-key-vault.mmd](integrations/azure-key-vault.mmd) | Key Vault integration | Secrets management flow | 2025-10-14 |
| [azure-redis-cache.mmd](integrations/azure-redis-cache.mmd) | Redis caching | Cache-aside pattern | 2025-10-14 |
| [azure-blob-storage.mmd](integrations/azure-blob-storage.mmd) | Blob storage | Artifact storage patterns | 2025-10-14 |
| [azure-signalr-service.mmd](integrations/azure-signalr-service.mmd) | SignalR Service | Real-time communication | 2025-10-14 |
| [azure-app-insights.mmd](integrations/azure-app-insights.mmd) | Application Insights | Telemetry integration | 2025-10-14 |

### External API Patterns

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [external-api-pattern.mmd](integrations/external-api-pattern.mmd) | External API integration | Third-party API patterns | 2025-10-14 |
| [webhook-receiver.mmd](integrations/webhook-receiver.mmd) | Webhook reception | Incoming webhook handling | 2025-10-14 |
| [webhook-sender.mmd](integrations/webhook-sender.mmd) | Webhook dispatch | Outgoing webhook with retry | 2025-10-14 |
| [oauth-flow.mmd](integrations/oauth-flow.mmd) | OAuth 2.0 flow | Authentication integration | 2025-10-14 |
| [third-party-llm.mmd](integrations/third-party-llm.mmd) | Multi-LLM support | Provider abstraction | 2025-10-14 |

### Notification Integrations

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [slack-notifications.mmd](integrations/slack-notifications.mmd) | Slack integration | Team notifications | 2025-10-14 |
| [github-webhook.mmd](integrations/github-webhook.mmd) | GitHub webhooks | CI/CD triggers | 2025-10-14 |
| [email-notifications.mmd](integrations/email-notifications.mmd) | Email flow | Multi-channel notifications | 2025-10-14 |

---

## Security Diagrams

Security architecture, authentication flows, and compliance patterns.

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [authentication-flow.mmd](security/authentication-flow.mmd) | Complete auth flow | User authentication process | 2025-10-14 |
| [authorization-rbac.mmd](security/authorization-rbac.mmd) | RBAC model | Role-based access control | 2025-10-14 |
| [jwt-token-lifecycle.mmd](security/jwt-token-lifecycle.mmd) | Token management | JWT lifecycle and refresh | 2025-10-14 |
| [secrets-management.mmd](security/secrets-management.mmd) | Secrets rotation | Key rotation and management | 2025-10-14 |
| [threat-model.mmd](security/threat-model.mmd) | Threat modeling | Security threat analysis | 2025-10-14 |
| [zero-trust-architecture.mmd](security/zero-trust-architecture.mmd) | Zero trust model | Never trust, always verify | 2025-10-14 |
| [data-encryption.mmd](security/data-encryption.mmd) | Encryption flows | At-rest and in-transit | 2025-10-14 |
| [audit-logging.mmd](security/audit-logging.mmd) | Audit trail | Compliance logging | 2025-10-14 |
| [compliance-controls.mmd](security/compliance-controls.mmd) | SOC 2 controls | Compliance framework | 2025-10-14 |
| [incident-response.mmd](security/incident-response.mmd) | Incident handling | Security response flow | 2025-10-14 |

---

## Deployment Pipeline

CI/CD pipelines and deployment automation patterns.

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [cicd-overview.mmd](deployment/cicd-overview.mmd) | Complete pipeline | End-to-end CI/CD flow | 2025-10-14 |
| [build-stage.mmd](deployment/build-stage.mmd) | Build process | Compilation and testing | 2025-10-14 |
| [security-scanning.mmd](deployment/security-scanning.mmd) | Security checks | Vulnerability scanning | 2025-10-14 |
| [docker-build.mmd](deployment/docker-build.mmd) | Container build | Docker image creation | 2025-10-14 |
| [deployment-stages.mmd](deployment/deployment-stages.mmd) | Multi-stage deploy | Dev/staging/prod flow | 2025-10-14 |
| [blue-green-deployment.mmd](deployment/blue-green-deployment.mmd) | Blue-green pattern | Zero-downtime deployment | 2025-10-14 |
| [canary-deployment.mmd](deployment/canary-deployment.mmd) | Canary releases | Gradual rollout pattern | 2025-10-14 |
| [rollback-procedure.mmd](deployment/rollback-procedure.mmd) | Rollback flow | Emergency rollback process | 2025-10-14 |

---

## Database Schemas

Database design patterns and query optimization strategies.

### Entity Relationship Diagrams

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [erd-complete.mmd](database/erd-complete.mmd) | Complete schema | Full database ERD | 2025-10-14 |
| [erd-workflows.mmd](database/erd-workflows.mmd) | Workflow tables | Workflow-related entities | 2025-10-14 |
| [erd-agents.mmd](database/erd-agents.mmd) | Agent tables | Agent configuration schema | 2025-10-14 |
| [erd-executions.mmd](database/erd-executions.mmd) | Execution tables | Task execution schema | 2025-10-14 |
| [erd-audit.mmd](database/erd-audit.mmd) | Audit tables | Audit and event logging | 2025-10-14 |

### Query Patterns

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [query-pattern-workflow-list.mmd](database/query-pattern-workflow-list.mmd) | Workflow queries | Listing and filtering | 2025-10-14 |
| [query-pattern-execution-detail.mmd](database/query-pattern-execution-detail.mmd) | Execution queries | Detailed execution data | 2025-10-14 |
| [query-pattern-checkpoint-recovery.mmd](database/query-pattern-checkpoint-recovery.mmd) | Recovery queries | Checkpoint retrieval | 2025-10-14 |
| [query-pattern-agent-performance.mmd](database/query-pattern-agent-performance.mmd) | Performance queries | Agent metrics aggregation | 2025-10-14 |

### Optimization Strategies

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [indexing-strategy.mmd](database/indexing-strategy.mmd) | Index design | Optimal index placement | 2025-10-14 |
| [partitioning-strategy.mmd](database/partitioning-strategy.mmd) | Data partitioning | Cosmos DB partitioning | 2025-10-14 |
| [change-feed-processing.mmd](database/change-feed-processing.mmd) | Change feeds | Real-time data processing | 2025-10-14 |

---

## Monitoring & Observability

Comprehensive monitoring, metrics, and observability patterns.

| Diagram | Description | Purpose | Last Updated |
|---------|-------------|---------|--------------|
| [distributed-tracing.mmd](monitoring/distributed-tracing.mmd) | OpenTelemetry tracing | End-to-end request tracing | 2025-10-14 |
| [metrics-collection.mmd](monitoring/metrics-collection.mmd) | Metrics pipeline | Prometheus metrics flow | 2025-10-14 |
| [logging-aggregation.mmd](monitoring/logging-aggregation.mmd) | Log aggregation | Centralized logging architecture | 2025-10-14 |
| [alerting-pipeline.mmd](monitoring/alerting-pipeline.mmd) | Alert flow | Alert routing and escalation | 2025-10-14 |
| [dashboard-architecture.mmd](monitoring/dashboard-architecture.mmd) | Dashboard design | Grafana dashboard architecture | 2025-10-14 |
| [health-checks.mmd](monitoring/health-checks.mmd) | Health monitoring | Liveness and readiness probes | 2025-10-14 |
| [performance-profiling.mmd](monitoring/performance-profiling.mmd) | Performance analysis | Application profiling flow | 2025-10-14 |
| [cost-monitoring.mmd](monitoring/cost-monitoring.mmd) | Cost tracking | Azure cost analysis | 2025-10-14 |

---

## Usage Guidelines

### Embedding in Documentation

```markdown
![Workflow Pattern](./assets/diagrams/workflows/sequential-basic.mmd)
```

### Viewing in VS Code

Install the "Mermaid Preview" extension for real-time diagram preview.

### Generating Images

```bash
# Generate PNG
mmdc -i diagram.mmd -o diagram.png -t default -b transparent

# Generate SVG
mmdc -i diagram.mmd -o diagram.svg -t default
```

### Best Practices

1. **Always reference diagrams by relative path** from documentation
2. **Include diagram purpose** in surrounding documentation
3. **Update Last Modified date** when making changes
4. **Follow color conventions** from mermaid-standards.md
5. **Test rendering** in both light and dark themes

## Contributing

When adding new diagrams:

1. Place in appropriate category folder
2. Follow naming conventions: `category-specific-name.mmd`
3. Include header comments with version and purpose
4. Update this INDEX.md with diagram entry
5. Test diagram rendering before committing

## Support

For questions or issues with diagrams:
- Consultations@BrooksideBI.com
- Internal documentation team
- Create issue in project repository

---

*This catalog is maintained to streamline knowledge transfer and improve data visibility across all Agent Studio operations. Last updated: 2025-10-14*