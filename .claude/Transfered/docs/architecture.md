---
title: Agent Studio Architecture
description: Understand the scalable, cloud-native architecture designed to support enterprise AI agent orchestration across multi-team environments.
tags:
  - architecture
  - system-design
  - cloud-native
  - azure
  - microservices
  - scalability
lastUpdated: 2025-10-09
author: Agent Studio Team
audience: architects
---

# Agent Studio Architecture

## Overview

Agent Studio is a cloud-native Azure SaaS platform for building, deploying, and managing AI agents using Microsoft's Agentic Framework. The system is designed as a monorepo with multiple services working together.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Client Layer                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  React + TypeScript Web Application (Vite)           │  │
│  │  - Agent Management UI                                │  │
│  │  - Workflow Designer                                  │  │
│  │  - Monitoring Dashboard                               │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       API Gateway                            │
│                    (Azure App Service)                       │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  .NET Service   │  │ Python Service  │  │  MCP Tools      │
│  (C# API)       │  │  (FastAPI)      │  │  (Node.js)      │
│  - Orchestration│  │  - Agent Exec   │  │  - Tool Stubs   │
│  - Business     │  │  - ML Tasks     │  │  - Integrations │
│    Logic        │  │  - Data Proc    │  │                 │
└─────────────────┘  └─────────────────┘  └─────────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Cosmos DB   │  │  Blob Storage│  │  Key Vault   │     │
│  │  - Agents    │  │  - Artifacts │  │  - Secrets   │     │
│  │  - Workflows │  │  - Logs      │  │  - Keys      │     │
│  │  - Results   │  │  - Data      │  │  - Certs     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 Observability Layer                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Application Insights + OpenTelemetry                 │  │
│  │  - Distributed Tracing                                │  │
│  │  - Metrics Collection                                 │  │
│  │  - Log Aggregation                                    │  │
│  │  - Performance Monitoring                             │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### Frontend (webapp/)

**Technology Stack:**
- React 18
- TypeScript
- Vite (build tool)
- Tailwind CSS (styling)
- React Router (routing)
- TanStack Query (data fetching)

**Responsibilities:**
- User interface for agent and workflow management
- Real-time monitoring dashboard
- Configuration management
- User authentication and authorization

### .NET Service (services/dotnet/)

**Technology Stack:**
- .NET 8
- ASP.NET Core Web API
- Entity Framework Core
- OpenTelemetry

**Responsibilities:**
- Business logic orchestration
- Workflow execution coordination
- Agent lifecycle management
- Integration with Azure services
- API gateway functionality

### Python Service (services/python/)

**Technology Stack:**
- Python 3.12
- FastAPI
- Pydantic
- OpenTelemetry
- httpx

**Responsibilities:**
- Agent execution engine
- ML/AI task processing
- Data transformation and ETL
- Integration with AI/ML frameworks
- Real-time agent communication

### MCP Tools (tools/mcp-tool-stub/)

**Technology Stack:**
- Node.js 20
- TypeScript
- Model Context Protocol SDK

**Responsibilities:**
- Standardized tool interface for AI agents
- External system integrations
- API wrappers
- Custom tool implementations

## Data Flow

### Agent Execution Flow

1. **User Action**: User triggers agent execution via UI
2. **API Request**: Frontend sends request to .NET service
3. **Orchestration**: .NET service validates and queues the request
4. **Execution**: Python service receives execution task
5. **Tool Invocation**: Agent uses MCP tools to perform actions
6. **Results**: Results are stored in Cosmos DB
7. **Notification**: User is notified of completion
8. **Telemetry**: All steps are traced via OpenTelemetry

### Workflow Execution Flow

1. **Trigger**: Event or schedule triggers workflow
2. **Validation**: .NET service validates workflow definition
3. **Coordination**: Orchestrator manages agent execution order
4. **Parallel Execution**: Independent agents run in parallel
5. **Result Aggregation**: Results collected and stored
6. **Completion**: Final workflow status updated

## Security Architecture

### Authentication & Authorization

- **Azure Active Directory** for user authentication
- **Managed Identity** for service-to-service auth
- **RBAC** for resource access control
- **JWT tokens** for API authentication

### Secrets Management

- **Azure Key Vault** for all secrets
- **Managed Identities** to access Key Vault
- **Environment-specific** secret configurations
- **Automatic rotation** for sensitive credentials

### Network Security

- **HTTPS only** for all communications
- **CORS policies** properly configured
- **Virtual Network** integration (production)
- **Private Endpoints** for Azure services

## Scalability

### Horizontal Scaling

- **App Service** auto-scaling based on metrics
- **Cosmos DB** serverless or provisioned throughput
- **Storage** automatic scaling
- **Queue-based** processing for async tasks

### Performance Optimization

- **CDN** for static assets
- **Response caching** where appropriate
- **Database indexing** for common queries
- **Connection pooling** for database connections

## Monitoring & Observability

### OpenTelemetry Integration

All services implement OpenTelemetry for:
- **Distributed tracing** across services
- **Metrics collection** (counters, gauges, histograms)
- **Log correlation** with trace context
- **Custom instrumentation** for business metrics

### Application Insights

- **Request tracking** with timing
- **Dependency tracking** (DB, HTTP, etc.)
- **Exception logging** with stack traces
- **Custom events** for business metrics
- **Availability tests** for uptime monitoring

### Alerting

- **Availability alerts** for downtime
- **Performance alerts** for slow requests
- **Error rate alerts** for failures
- **Custom metric alerts** for business KPIs

## Deployment Architecture

### Environments

- **Development**: Single instance, serverless services
- **Staging**: Production-like, reduced capacity
- **Production**: Multi-region, high availability

### CI/CD Pipeline

1. **Source Control**: GitHub
2. **Build**: GitHub Actions
3. **Test**: Automated test suites
4. **Security Scan**: Dependency and vulnerability scanning
5. **Infrastructure**: Bicep templates
6. **Deployment**: Azure App Service deployment slots
7. **Verification**: Smoke tests
8. **Release**: Slot swap for zero-downtime

## Best Practices

### Code Organization

- **Monorepo** structure for related services
- **Shared types** and contracts
- **Independent deployment** per service
- **Consistent naming** conventions

### Error Handling

- **Structured logging** with context
- **Graceful degradation** for failures
- **Retry policies** with exponential backoff
- **Circuit breakers** for external dependencies

### Testing

- **Unit tests** for business logic
- **Integration tests** for API endpoints
- **E2E tests** for critical paths
- **Load tests** for performance validation

## Future Enhancements

- Multi-region deployment
- GraphQL API layer
- Real-time websocket communication
- Advanced ML model hosting
- Kubernetes orchestration option
