# Agent Studio - Complete API Reference

> **Establish comprehensive AI agent orchestration to streamline complex workflows and drive measurable outcomes across your business environment.**

**Last Updated:** 2025-10-09
**API Version:** 1.0.0
**Status:** Production Ready

---

## Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
  - [Authentication](#authentication)
  - [Base URLs](#base-urls)
  - [Quick Start Example](#quick-start-example)
- [API Architecture](#api-architecture)
- [Orchestration API (.NET)](#orchestration-api-net)
  - [Meta-Agent Endpoints](#meta-agent-endpoints)
  - [Workflow Management](#workflow-management)
- [Python Agents API](#python-agents-api)
  - [Individual Agent Execution](#individual-agent-execution)
  - [Multi-Agent Workflows](#multi-agent-workflows)
- [SignalR Real-Time Hub](#signalr-real-time-hub)
  - [Connection Setup](#connection-setup)
  - [Server Events](#server-events)
  - [Client Methods](#client-methods)
- [Common Patterns](#common-patterns)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [SDK and Client Libraries](#sdk-and-client-libraries)
- [Support](#support)

---

## Overview

Agent Studio provides three complementary APIs to establish comprehensive AI agent orchestration across your business environment:

### 1. Orchestration API (.NET)

**Purpose:** High-level workflow management and orchestration control plane

**Base URL:** `https://api.agentstudio.com`

**Best for:** Organizations requiring enterprise-grade workflow orchestration with advanced features like checkpointing, resume capabilities, and multi-pattern execution (sequential, parallel, iterative, dynamic).

**Key Features:**
- Workflow lifecycle management (start, pause, resume, cancel)
- Checkpoint-based state persistence and recovery
- Multiple execution patterns (sequential, parallel, iterative, dynamic)
- Circuit breaker and retry policies for resilience
- SignalR integration for real-time updates

### 2. Python Agents API

**Purpose:** Direct AI agent task execution with specialized meta-agents

**Base URL:** `https://agents.agentstudio.com`

**Best for:** Organizations requiring direct access to specialized AI agents with fine-grained control over individual task execution and agent-to-agent handoffs.

**Key Features:**
- Four specialized meta-agents (Architect, Builder, Validator, Scribe)
- Automatic agent-to-agent handoffs
- Context preservation across workflow steps
- Azure OpenAI integration with multiple models
- Comprehensive execution metadata and tracing

### 3. SignalR Real-Time Hub

**Purpose:** Real-time bidirectional communication for workflow updates

**Hub URL:** `wss://api.agentstudio.com/hubs/meta-agent`

**Best for:** Organizations requiring real-time visibility into workflow execution with live updates on agent thoughts, task progress, and execution status.

**Key Features:**
- WebSocket-based real-time communication
- Agent thought streaming
- Workflow progress updates
- Automatic reconnection with exponential backoff
- Subscription-based event routing

---

## Getting Started

### Authentication

All Agent Studio APIs require authentication to ensure secure access across your business environment.

#### Development Authentication (API Key)

For development and testing environments, use API key authentication:

```bash
# Using X-API-Key header
curl -H "X-API-Key: your-api-key-here" \
  https://api.agentstudio.com/api/MetaAgent/types
```

#### Production Authentication (OAuth2)

For production deployments, use OAuth2 Bearer Token authentication:

```bash
# Using Authorization Bearer header
curl -H "Authorization: Bearer your-oauth-token-here" \
  https://api.agentstudio.com/api/Workflow
```

**OAuth2 Configuration:**
- **Authorization URL:** `https://auth.agentstudio.com/oauth/authorize`
- **Token URL:** `https://auth.agentstudio.com/oauth/token`
- **Scopes:**
  - `agents.execute` - Execute agent tasks
  - `agents.read` - Read agent information
  - `workflows.execute` - Execute and manage workflows
  - `workflows.read` - Read workflow status
  - `admin` - Administrative operations

#### Obtaining API Keys

Contact **consultations@brooksidebi.com** or call **+1 209 487 2047** to obtain API keys and discuss production OAuth2 setup.

### Base URLs

| Environment | Orchestration API | Python Agents API | SignalR Hub |
|------------|------------------|------------------|-------------|
| **Development** | `http://localhost:5000` | `http://localhost:8000` | `ws://localhost:5000/hubs/meta-agent` |
| **Staging** | `https://staging-api.agentstudio.com` | `https://agents-staging.agentstudio.com` | `wss://staging-api.agentstudio.com/hubs/meta-agent` |
| **Production** | `https://api.agentstudio.com` | `https://agents.agentstudio.com` | `wss://api.agentstudio.com/hubs/meta-agent` |

### Quick Start Example

Execute your first AI agent task in under 2 minutes:

```bash
# 1. List available agent types
curl -X GET "https://api.agentstudio.com/api/MetaAgent/types" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Response:
# ["architect", "builder", "validator", "scribe"]

# 2. Execute architecture design task
curl -X POST "https://api.agentstudio.com/api/MetaAgent/architect/execute" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "task": "Design microservices architecture for e-commerce platform with 100K daily users",
    "parameters": {
      "scale": "100K users/day",
      "cloud_provider": "Azure",
      "requirements": ["high availability", "scalability"]
    }
  }'

# Response:
# {
#   "taskId": "task-550e8400",
#   "status": "completed",
#   "result": "Microservices architecture designed with 5 core services...",
#   "thoughts": [
#     {"step": 1, "content": "Analyzing scale requirements for 100K users..."},
#     {"step": 2, "content": "Designing service boundaries and communication patterns..."}
#   ],
#   "completedAt": "2025-10-09T10:30:00Z"
# }
```

---

## API Architecture

Agent Studio employs a three-layer architecture to establish scalable, resilient orchestration:

```
┌─────────────────────────────────────────────────────┐
│           React Frontend (Port 3000)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │
│  │   Design     │  │   Traces     │  │  Agents   │ │
│  │    View      │  │    View      │  │   View    │ │
│  └──────────────┘  └──────────────┘  └───────────┘ │
└─────────────────────────────────────────────────────┘
                       │
                       │ HTTP/REST + SignalR WebSocket
                       ▼
┌─────────────────────────────────────────────────────┐
│    .NET Orchestration Layer (Port 5000)             │
│  ┌──────────────────────────────────────────────┐  │
│  │       MetaAgentOrchestrator                   │  │
│  │  • Workflow execution (4 patterns)            │  │
│  │  • State management (Cosmos DB)               │  │
│  │  • Checkpoint/resume capabilities             │  │
│  │  • Circuit breaker + retry policies           │  │
│  └──────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────┐  │
│  │       SignalR MetaAgentHub                    │  │
│  │  • Real-time workflow updates                 │  │
│  │  • Agent thought streaming                    │  │
│  │  • Subscription management                    │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
                       │
                       │ HTTP/REST with Polly resilience
                       ▼
┌─────────────────────────────────────────────────────┐
│    Python Agents Layer (Port 8000)                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────┐│
│  │Architect │  │ Builder  │  │Validator │  │Scribe││
│  │  Agent   │  │  Agent   │  │  Agent   │  │Agent││
│  └──────────┘  └──────────┘  └──────────┘  └─────┘│
│                                                      │
│  Azure OpenAI Integration (GPT-4, GPT-3.5-Turbo)   │
└─────────────────────────────────────────────────────┘
```

**Key Architectural Principles:**
- **Separation of Concerns:** Orchestration logic (.NET) separated from agent execution (Python)
- **Resilience:** Circuit breaker patterns, retry policies, graceful degradation
- **Observability:** OpenTelemetry integration, distributed tracing, structured logging
- **Scalability:** Stateless agents, horizontal scaling, async execution
- **Real-time:** SignalR for live updates without polling overhead

---

## Orchestration API (.NET)

The .NET Orchestration API provides enterprise-grade workflow management with advanced orchestration capabilities.

### Meta-Agent Endpoints

#### List Available Agent Types

**Endpoint:** `GET /api/MetaAgent/types`

**Description:** Retrieve list of available agent types for task execution.

**Response:**
```json
["architect", "builder", "validator", "scribe"]
```

**Example:**
```bash
curl -X GET "https://api.agentstudio.com/api/MetaAgent/types" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

#### Execute Agent Task

**Endpoint:** `POST /api/MetaAgent/{agentType}/execute`

**Description:** Execute task with specified agent type and receive comprehensive results.

**Path Parameters:**
- `agentType` (required): Agent type (`architect`, `builder`, `validator`, `scribe`)

**Request Body:**
```json
{
  "task": "Design microservices architecture for e-commerce platform",
  "parameters": {
    "scale": "100K users/day",
    "cloud_provider": "Azure",
    "architecture_style": "microservices"
  }
}
```

**Response (200 OK):**
```json
{
  "taskId": "task-550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "result": "Microservices architecture designed with 5 core services: User Service (authentication/authorization), Product Service (catalog management), Order Service (transaction processing), Payment Service (gateway integration), Notification Service (event-driven messaging).",
  "thoughts": [
    {
      "step": 1,
      "content": "Analyzing requirements for 100K daily users and Azure cloud environment..."
    },
    {
      "step": 2,
      "content": "Designing service boundaries using domain-driven design principles..."
    },
    {
      "step": 3,
      "content": "Planning inter-service communication with event-driven patterns..."
    }
  ],
  "completedAt": "2025-10-09T10:30:00Z",
  "executionTimeMs": 3500
}
```

**Error Responses:**

| Status Code | Error Type | Description |
|------------|-----------|-------------|
| 400 | Bad Request | Invalid agent type or missing required fields |
| 502 | Bad Gateway | Error communicating with Python agent service |
| 504 | Gateway Timeout | Agent task exceeded timeout (default 60s) |
| 500 | Internal Server Error | Unexpected orchestration error |

**Example:**
```bash
curl -X POST "https://api.agentstudio.com/api/MetaAgent/architect/execute" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "task": "Design microservices architecture for e-commerce platform with 100K daily users",
    "parameters": {
      "scale": "100K users/day",
      "cloud_provider": "Azure",
      "requirements": ["high availability", "scalability", "cost optimization"]
    }
  }'
```

---

#### Stream Agent Execution (Server-Sent Events)

**Endpoint:** `POST /api/MetaAgent/{agentType}/execute/stream`

**Description:** Execute agent task with real-time streaming of agent thoughts and final response using Server-Sent Events (SSE).

**Response Format:** `text/event-stream`

**Event Types:**
- `thought` - Agent reasoning step
- `response` - Final task result
- `[DONE]` - Stream completion marker

**Example:**
```typescript
const eventSource = new EventSource(
  'https://api.agentstudio.com/api/MetaAgent/architect/execute/stream',
  {
    headers: {
      'Authorization': 'Bearer YOUR_TOKEN',
      'Content-Type': 'application/json'
    }
  }
);

eventSource.addEventListener('thought', (event) => {
  const thought = JSON.parse(event.data);
  console.log(`Agent thinking (step ${thought.step}): ${thought.content}`);
});

eventSource.addEventListener('response', (event) => {
  const response = JSON.parse(event.data);
  console.log('Final result:', response.result);
  eventSource.close();
});

eventSource.addEventListener('error', (error) => {
  console.error('Stream error:', error);
  eventSource.close();
});
```

---

#### Check Agent Service Health

**Endpoint:** `GET /api/MetaAgent/health`

**Description:** Verify Python agent service availability and health status.

**Response (200 OK):**
```json
{
  "status": "healthy",
  "timestamp": "2025-10-09T10:30:00Z",
  "agentsAvailable": ["architect", "builder", "validator", "scribe"],
  "responseTimeMs": 45
}
```

**Response (503 Service Unavailable):**
```json
{
  "status": "unhealthy",
  "timestamp": "2025-10-09T10:30:00Z",
  "error": "Unable to connect to Python agent service",
  "agentsAvailable": []
}
```

---

#### Cancel Running Task

**Endpoint:** `POST /api/MetaAgent/tasks/{taskId}/cancel`

**Description:** Cancel a currently executing agent task.

**Path Parameters:**
- `taskId` (required): Task identifier to cancel

**Response (200 OK):**
```json
{
  "message": "Task 'task-550e8400' cancelled successfully",
  "cancelledAt": "2025-10-09T10:31:00Z"
}
```

**Response (404 Not Found):**
```json
{
  "error": "Task 'task-550e8400' not found or already completed"
}
```

---

### Workflow Management

#### Start Workflow Execution

**Endpoint:** `POST /api/Workflow`

**Description:** Start new workflow execution asynchronously. Returns immediately with workflow ID for status tracking.

**Request Body:**
```json
{
  "definition": {
    "id": "ecommerce-build-workflow",
    "name": "E-commerce Platform Build Workflow",
    "version": "1.0",
    "pattern": "sequential",
    "tasks": [
      {
        "id": "design-architecture",
        "agentType": "architect",
        "task": "Design microservices architecture for e-commerce platform",
        "parameters": {
          "scale": "100K users/day",
          "cloud_provider": "Azure"
        }
      },
      {
        "id": "implement-services",
        "agentType": "builder",
        "task": "Implement core microservices based on architecture design",
        "dependencies": ["design-architecture"]
      },
      {
        "id": "validate-implementation",
        "agentType": "validator",
        "task": "Validate implementation quality and security",
        "dependencies": ["implement-services"]
      },
      {
        "id": "generate-documentation",
        "agentType": "scribe",
        "task": "Generate comprehensive documentation",
        "dependencies": ["validate-implementation"]
      }
    ]
  },
  "input": {
    "project_name": "My E-commerce Platform",
    "target_environment": "Azure",
    "compliance_requirements": ["GDPR", "PCI-DSS"]
  },
  "initiatedBy": "user@example.com"
}
```

**Response (201 Created):**
```json
{
  "id": "wf-550e8400-e29b-41d4-a716-446655440000",
  "status": "running",
  "definitionId": "ecommerce-build-workflow",
  "startedAt": "2025-10-09T10:30:00Z",
  "initiatedBy": "user@example.com",
  "currentTask": "design-architecture",
  "progress": {
    "completedTasks": 0,
    "totalTasks": 4,
    "percentage": 0
  }
}
```

**Workflow Patterns:**

| Pattern | Description | Use Case |
|---------|-------------|----------|
| **Sequential** | Tasks execute in order (step-1 → step-2 → step-3) | Linear workflows with dependencies |
| **Parallel** | Independent tasks run concurrently | Independent operations that can execute simultaneously |
| **Iterative** | Loop with validator feedback until completion | Code generation with validation loops |
| **Dynamic** | Runtime-determined execution with agent handoffs | Adaptive workflows with conditional logic |

---

#### Execute Workflow Synchronously

**Endpoint:** `POST /api/Workflow/execute`

**Description:** Execute workflow and wait for completion. Blocks until workflow finishes or times out.

**Request Body:** (Same as Start Workflow)

**Response (200 OK):**
```json
{
  "workflowId": "wf-550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "result": {
    "finalOutput": "E-commerce platform fully implemented with 5 microservices, comprehensive tests (92% coverage), and documentation.",
    "taskResults": [
      {
        "taskId": "design-architecture",
        "status": "completed",
        "result": "Microservices architecture designed with 5 services...",
        "executionTimeMs": 3500
      },
      {
        "taskId": "implement-services",
        "status": "completed",
        "result": "Implementation complete with unit tests...",
        "executionTimeMs": 8200
      },
      {
        "taskId": "validate-implementation",
        "status": "completed",
        "result": "Validation passed. Code quality: 9.2/10...",
        "executionTimeMs": 4800
      },
      {
        "taskId": "generate-documentation",
        "status": "completed",
        "result": "Documentation generated with API specs...",
        "executionTimeMs": 3200
      }
    ]
  },
  "completedAt": "2025-10-09T10:45:00Z",
  "totalExecutionTimeMs": 19700
}
```

---

#### Get Workflow Status

**Endpoint:** `GET /api/Workflow/{id}`

**Description:** Retrieve current workflow execution status and progress.

**Path Parameters:**
- `id` (required): Workflow execution ID

**Response (200 OK):**
```json
{
  "id": "wf-550e8400-e29b-41d4-a716-446655440000",
  "status": "running",
  "definitionId": "ecommerce-build-workflow",
  "startedAt": "2025-10-09T10:30:00Z",
  "currentTask": "implement-services",
  "progress": {
    "completedTasks": 1,
    "totalTasks": 4,
    "percentage": 25
  },
  "tasks": [
    {
      "taskId": "design-architecture",
      "status": "completed",
      "startedAt": "2025-10-09T10:30:00Z",
      "completedAt": "2025-10-09T10:30:30Z"
    },
    {
      "taskId": "implement-services",
      "status": "running",
      "startedAt": "2025-10-09T10:30:35Z"
    },
    {
      "taskId": "validate-implementation",
      "status": "pending"
    },
    {
      "taskId": "generate-documentation",
      "status": "pending"
    }
  ]
}
```

**Workflow Status Values:**
- `pending` - Workflow queued, not yet started
- `running` - Workflow currently executing
- `paused` - Workflow paused (can be resumed)
- `completed` - Workflow finished successfully
- `failed` - Workflow failed with error
- `cancelled` - Workflow cancelled by user

---

#### List Workflows

**Endpoint:** `GET /api/Workflow`

**Description:** List workflow executions with optional filtering.

**Query Parameters:**
- `status` (optional): Filter by status (`running`, `completed`, `failed`, etc.)
- `limit` (optional): Maximum results (default 100, max 500)
- `offset` (optional): Pagination offset

**Response (200 OK):**
```json
{
  "workflows": [
    {
      "id": "wf-550e8400-e29b-41d4-a716-446655440000",
      "status": "completed",
      "definitionId": "ecommerce-build-workflow",
      "startedAt": "2025-10-09T10:30:00Z",
      "completedAt": "2025-10-09T10:45:00Z",
      "initiatedBy": "user@example.com"
    },
    {
      "id": "wf-650e8400-e29b-41d4-a716-446655440001",
      "status": "running",
      "definitionId": "api-development-workflow",
      "startedAt": "2025-10-09T11:00:00Z",
      "initiatedBy": "admin@example.com"
    }
  ],
  "total": 2,
  "limit": 100,
  "offset": 0
}
```

---

#### Resume Workflow from Checkpoint

**Endpoint:** `POST /api/Workflow/{id}/resume`

**Description:** Resume paused or failed workflow from latest checkpoint.

**Path Parameters:**
- `id` (required): Workflow execution ID

**Query Parameters:**
- `checkpointId` (optional): Specific checkpoint ID to resume from (defaults to latest)

**Response (200 OK):**
```json
{
  "workflowId": "wf-550e8400-e29b-41d4-a716-446655440000",
  "status": "running",
  "resumedFrom": "checkpoint-3",
  "resumedAt": "2025-10-09T11:00:00Z",
  "currentTask": "validate-implementation"
}
```

**Best for:** Organizations requiring resilient workflows with recovery capabilities after transient failures or manual intervention.

---

#### Pause Workflow

**Endpoint:** `POST /api/Workflow/{id}/pause`

**Description:** Pause running workflow. Creates checkpoint for later resumption.

**Response (200 OK):**
```json
{
  "message": "Workflow 'wf-550e8400' paused successfully",
  "checkpointId": "checkpoint-2",
  "pausedAt": "2025-10-09T10:35:00Z"
}
```

---

#### Cancel Workflow

**Endpoint:** `POST /api/Workflow/{id}/cancel`

**Description:** Cancel running workflow. Workflow cannot be resumed after cancellation.

**Response (200 OK):**
```json
{
  "message": "Workflow 'wf-550e8400' cancelled successfully",
  "cancelledAt": "2025-10-09T10:35:00Z"
}
```

---

#### Delete Workflow

**Endpoint:** `DELETE /api/Workflow/{id}`

**Description:** Delete workflow execution and all associated checkpoints.

**Response (200 OK):**
```json
{
  "message": "Workflow 'wf-550e8400' deleted successfully"
}
```

---

#### Get Workflow Checkpoints

**Endpoint:** `GET /api/Workflow/{id}/checkpoints`

**Description:** Retrieve all checkpoints for workflow execution.

**Response (200 OK):**
```json
{
  "workflowId": "wf-550e8400-e29b-41d4-a716-446655440000",
  "checkpoints": [
    {
      "id": "checkpoint-1",
      "createdAt": "2025-10-09T10:30:30Z",
      "type": "automatic",
      "taskId": "design-architecture",
      "description": "Completed design-architecture task"
    },
    {
      "id": "checkpoint-2",
      "createdAt": "2025-10-09T10:35:00Z",
      "type": "manual",
      "taskId": "implement-services",
      "description": "Manual checkpoint before validation"
    },
    {
      "id": "checkpoint-3",
      "createdAt": "2025-10-09T10:40:00Z",
      "type": "failure",
      "taskId": "validate-implementation",
      "description": "Checkpoint created before failure recovery"
    }
  ]
}
```

**Checkpoint Types:**
- `automatic` - Created after each successful task
- `manual` - Explicitly created by user or system
- `failure` - Created before error recovery attempt
- `paused` - Created when workflow is paused

---

## Python Agents API

The Python Agents API provides direct access to specialized AI agents for fine-grained task execution control.

### Individual Agent Execution

#### Health Check

**Endpoint:** `GET /health`

**Description:** Verify agent service health and list available agents.

**OpenAPI Specification:** [openapi-python-agents.yaml](./openapi-python-agents.yaml)

**Response (200 OK):**
```json
{
  "status": "healthy",
  "version": "0.1.0",
  "agents": ["architect", "builder", "validator", "scribe"],
  "timestamp": "2025-10-09T10:30:00Z"
}
```

---

#### Execute Architect Agent Task

**Endpoint:** `POST /architect/task`

**Description:** Execute system architecture design task.

**Request Body:**
```json
{
  "content": "Design microservices architecture for e-commerce platform with 100K daily users",
  "context": {
    "scale": "100K users/day",
    "cloud_provider": "Azure",
    "requirements": ["high availability", "scalability", "cost optimization"]
  },
  "auto_handoff": true
}
```

**Response (200 OK):**
```json
{
  "task_id": "task-550e8400-e29b-41d4-a716-446655440000",
  "agent_name": "SystemArchitect",
  "agent_role": "architect",
  "content": "Microservices architecture designed with 5 core services following domain-driven design principles. Services: User Service (authentication/authorization), Product Service (catalog management), Order Service (transaction processing), Payment Service (gateway integration), Notification Service (event-driven messaging). Each service uses dedicated PostgreSQL database with event sourcing for order processing.",
  "success": true,
  "metadata": {
    "execution_time_ms": 3500,
    "model_used": "gpt-4",
    "architecture_patterns": ["microservices", "event-driven", "domain-driven-design"]
  },
  "handoff_to": "builder",
  "timestamp": "2025-10-09T10:30:00Z"
}
```

**Architect Agent Specializations:**
- System design (microservices, monolithic, serverless, event-driven)
- Technology stack recommendations
- Scalability planning (load balancing, caching, horizontal/vertical scaling)
- Cloud infrastructure design (Azure, AWS, GCP)
- Architecture patterns (CQRS, Event Sourcing, DDD, Clean Architecture)
- Integration strategy (API design, message queuing, service mesh)

---

#### Execute Builder Agent Task

**Endpoint:** `POST /builder/task`

**Description:** Execute code implementation task.

**Builder Agent Specializations:**
- Full-stack development (Python, TypeScript, C#, Java)
- API development (REST, GraphQL, gRPC)
- Database implementation (schema, migrations, ORM)
- Authentication systems (OAuth2, JWT, SAML)
- Unit and integration tests (85%+ coverage)
- DevOps integration (Docker, CI/CD, deployment scripts)

---

#### Execute Validator Agent Task

**Endpoint:** `POST /validator/task`

**Description:** Execute quality assurance and validation task.

**Validator Agent Specializations:**
- Code quality review (static analysis, code smells, vulnerabilities)
- Test coverage analysis (unit test completeness, edge cases)
- Performance validation (load testing, bottleneck identification)
- Security assessment (OWASP Top 10, authentication flaws)
- Compliance verification (GDPR, HIPAA, SOC2)
- Integration testing (API contracts, end-to-end workflows)

---

#### Execute Scribe Agent Task

**Endpoint:** `POST /scribe/task`

**Description:** Execute documentation generation task.

**Scribe Agent Specializations:**
- API documentation (OpenAPI/Swagger specifications)
- Technical guides (ADRs, setup instructions, troubleshooting)
- Code documentation (inline comments, docstrings, README files)
- User manuals (feature descriptions, workflows, FAQ)
- Runbooks (operational procedures, incident response)
- Knowledge base (best practices, design patterns, lessons learned)

---

### Multi-Agent Workflows

#### Execute Multi-Agent Workflow

**Endpoint:** `POST /workflow/execute`

**Description:** Execute coordinated multi-agent workflow with automatic handoffs.

**Request Body:**
```json
{
  "initial_task": "Build complete e-commerce platform with microservices architecture supporting 100K daily users",
  "starting_agent": "architect",
  "max_iterations": 10,
  "context": {
    "scale": "100K users/day",
    "tech_stack": ["Python", "FastAPI", "React", "Azure"],
    "requirements": ["high availability", "scalability", "GDPR compliance"],
    "constraints": ["cost optimization", "6-month delivery timeline"]
  }
}
```

**Response (200 OK):**
```json
{
  "workflow_id": "wf-550e8400-e29b-41d4-a716-446655440000",
  "steps": [
    {
      "step_number": 1,
      "agent_role": "architect",
      "agent_name": "SystemArchitect",
      "content": "Architecture designed with 5 microservices. Handing off to Builder.",
      "success": true,
      "timestamp": "2025-10-09T10:30:00Z"
    },
    {
      "step_number": 2,
      "agent_role": "builder",
      "agent_name": "CodeBuilder",
      "content": "Implementation complete with 92% test coverage. Handing off to Validator.",
      "success": true,
      "timestamp": "2025-10-09T10:35:00Z"
    },
    {
      "step_number": 3,
      "agent_role": "validator",
      "agent_name": "QualityValidator",
      "content": "Validation complete. No critical issues found. Handing off to Scribe.",
      "success": true,
      "timestamp": "2025-10-09T10:40:00Z"
    },
    {
      "step_number": 4,
      "agent_role": "scribe",
      "agent_name": "DocumentationScribe",
      "content": "Comprehensive documentation generated with API specs and guides.",
      "success": true,
      "timestamp": "2025-10-09T10:45:00Z"
    }
  ],
  "final_output": "E-commerce platform fully implemented with 5 microservices, comprehensive tests (92% coverage), and documentation. Platform ready for deployment to Azure.",
  "success": true,
  "total_iterations": 4,
  "metadata": {
    "initial_task": "Build complete e-commerce platform",
    "starting_agent": "architect",
    "total_execution_time_ms": 18500,
    "agents_involved": ["architect", "builder", "validator", "scribe"],
    "total_tokens_used": 12400
  }
}
```

**Workflow Execution Pattern:**

1. **Architect** → Analyzes requirements and creates system design
2. **Builder** → Implements code based on architecture specifications
3. **Validator** → Tests and validates implementation quality
4. **Scribe** → Documents the complete solution

**Performance:** Typical workflow with 4 agents completes in 15-30 seconds depending on task complexity.

---

## SignalR Real-Time Hub

The SignalR Hub provides real-time bidirectional communication for live workflow updates.

### Connection Setup

#### TypeScript Client Example

```typescript
import * as signalR from '@microsoft/signalr';

// Create connection with automatic reconnection
const connection = new signalR.HubConnectionBuilder()
  .withUrl('https://api.agentstudio.com/hubs/meta-agent', {
    accessTokenFactory: () => getAccessToken()
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
  .configureLogging(signalR.LogLevel.Information)
  .build();

// Connection lifecycle handlers
connection.onreconnecting((error) => {
  console.log('Connection lost, reconnecting...', error);
});

connection.onreconnected((connectionId) => {
  console.log('Connection reestablished:', connectionId);
});

connection.onclose((error) => {
  console.error('Connection closed:', error);
});

// Start connection
await connection.start();
console.log('SignalR connected');
```

---

### Server Events

#### ReceiveAgentThought

**Description:** Receive real-time agent reasoning steps as they occur.

**Event Handler:**
```typescript
connection.on('ReceiveAgentThought', (workflowId: string, thought: AgentThought) => {
  console.log(`Workflow ${workflowId} - Agent thinking:`, thought.content);

  // Update UI with agent reasoning
  updateAgentThoughtUI(thought);
});
```

**Event Payload:**
```typescript
interface AgentThought {
  step: number;
  agentType: string;
  content: string;
  timestamp: string;
}
```

**Example Payload:**
```json
{
  "step": 1,
  "agentType": "architect",
  "content": "Analyzing scale requirements for 100K users/day. Considering Azure cloud capabilities and cost optimization constraints.",
  "timestamp": "2025-10-09T10:30:05Z"
}
```

---

#### ReceiveProgress

**Description:** Receive workflow execution progress updates.

**Event Handler:**
```typescript
connection.on('ReceiveProgress', (workflowId: string, progress: WorkflowProgress) => {
  console.log(`Workflow ${workflowId} progress: ${progress.percentage}%`);

  // Update progress bar
  updateProgressBar(progress);
});
```

**Event Payload:**
```typescript
interface WorkflowProgress {
  completedTasks: number;
  totalTasks: number;
  percentage: number;
  currentTask: string;
  estimatedTimeRemaining?: number; // seconds
}
```

---

#### ReceiveTaskStarted

**Description:** Notified when workflow task begins execution.

**Event Handler:**
```typescript
connection.on('ReceiveTaskStarted', (workflowId: string, task: TaskStartedEvent) => {
  console.log(`Task ${task.taskId} started in workflow ${workflowId}`);
});
```

---

#### ReceiveTaskCompleted

**Description:** Notified when workflow task completes.

**Event Handler:**
```typescript
connection.on('ReceiveTaskCompleted', (workflowId: string, task: TaskCompletedEvent) => {
  console.log(`Task ${task.taskId} completed with status: ${task.status}`);

  if (task.status === 'failed') {
    console.error('Task error:', task.error);
  }
});
```

---

#### ReceiveWorkflowStarted

**Description:** Notified when workflow execution begins.

**Event Handler:**
```typescript
connection.on('ReceiveWorkflowStarted', (workflow: WorkflowStartedEvent) => {
  console.log(`Workflow ${workflow.workflowId} started`);
});
```

---

#### ReceiveWorkflowCompleted

**Description:** Notified when workflow execution completes.

**Event Handler:**
```typescript
connection.on('ReceiveWorkflowCompleted', (workflow: WorkflowCompletedEvent) => {
  console.log(`Workflow ${workflow.workflowId} completed with status: ${workflow.status}`);

  if (workflow.status === 'completed') {
    console.log('Final output:', workflow.result.finalOutput);
  } else if (workflow.status === 'failed') {
    console.error('Workflow error:', workflow.error);
  }
});
```

---

### Client Methods

#### SubscribeToWorkflow

**Description:** Subscribe to real-time updates for specific workflow.

**Method:**
```typescript
await connection.invoke('SubscribeToWorkflow', workflowId);
console.log(`Subscribed to workflow ${workflowId}`);
```

---

#### UnsubscribeFromWorkflow

**Description:** Unsubscribe from workflow updates.

**Method:**
```typescript
await connection.invoke('UnsubscribeFromWorkflow', workflowId);
console.log(`Unsubscribed from workflow ${workflowId}`);
```

---

### Complete Usage Example

```typescript
import * as signalR from '@microsoft/signalr';

class WorkflowMonitor {
  private connection: signalR.HubConnection;

  async initialize() {
    // Create connection
    this.connection = new signalR.HubConnectionBuilder()
      .withUrl('https://api.agentstudio.com/hubs/meta-agent', {
        accessTokenFactory: () => this.getAccessToken()
      })
      .withAutomaticReconnect()
      .build();

    // Register event handlers
    this.connection.on('ReceiveAgentThought', this.onAgentThought.bind(this));
    this.connection.on('ReceiveProgress', this.onProgress.bind(this));
    this.connection.on('ReceiveTaskStarted', this.onTaskStarted.bind(this));
    this.connection.on('ReceiveTaskCompleted', this.onTaskCompleted.bind(this));
    this.connection.on('ReceiveWorkflowStarted', this.onWorkflowStarted.bind(this));
    this.connection.on('ReceiveWorkflowCompleted', this.onWorkflowCompleted.bind(this));

    // Start connection
    await this.connection.start();
    console.log('SignalR connection established');
  }

  async monitorWorkflow(workflowId: string) {
    // Subscribe to workflow updates
    await this.connection.invoke('SubscribeToWorkflow', workflowId);
    console.log(`Now monitoring workflow: ${workflowId}`);
  }

  async stopMonitoring(workflowId: string) {
    await this.connection.invoke('UnsubscribeFromWorkflow', workflowId);
    console.log(`Stopped monitoring workflow: ${workflowId}`);
  }

  private onAgentThought(workflowId: string, thought: any) {
    console.log(`[${workflowId}] Agent thought:`, thought.content);
  }

  private onProgress(workflowId: string, progress: any) {
    console.log(`[${workflowId}] Progress: ${progress.percentage}%`);
  }

  private onTaskStarted(workflowId: string, task: any) {
    console.log(`[${workflowId}] Task started: ${task.taskId}`);
  }

  private onTaskCompleted(workflowId: string, task: any) {
    console.log(`[${workflowId}] Task completed: ${task.taskId} (${task.status})`);
  }

  private onWorkflowStarted(workflow: any) {
    console.log(`Workflow started: ${workflow.workflowId}`);
  }

  private onWorkflowCompleted(workflow: any) {
    console.log(`Workflow completed: ${workflow.workflowId} (${workflow.status})`);

    if (workflow.status === 'completed') {
      console.log('Success! Final output:', workflow.result.finalOutput);
    } else {
      console.error('Workflow failed:', workflow.error);
    }
  }

  private getAccessToken(): string {
    // Retrieve OAuth token from your auth service
    return localStorage.getItem('access_token') || '';
  }
}

// Usage
const monitor = new WorkflowMonitor();
await monitor.initialize();
await monitor.monitorWorkflow('wf-550e8400-e29b-41d4-a716-446655440000');
```

---

## Common Patterns

### Pattern 1: Simple Agent Task Execution

Execute single agent task with the .NET Orchestration API:

```bash
curl -X POST "https://api.agentstudio.com/api/MetaAgent/architect/execute" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "task": "Design REST API for user management system",
    "parameters": {
      "features": ["registration", "authentication", "profile management"],
      "auth_type": "JWT",
      "database": "PostgreSQL"
    }
  }'
```

---

### Pattern 2: Multi-Agent Workflow with Real-time Updates

Execute workflow with live monitoring via SignalR:

```typescript
// 1. Connect to SignalR hub
const connection = await connectToHub();

// 2. Subscribe to workflow events
connection.on('ReceiveAgentThought', (workflowId, thought) => {
  console.log('Agent thinking:', thought.content);
});

connection.on('ReceiveProgress', (workflowId, progress) => {
  console.log(`Progress: ${progress.percentage}%`);
});

connection.on('ReceiveWorkflowCompleted', (workflow) => {
  console.log('Workflow complete:', workflow.result.finalOutput);
});

// 3. Start workflow via REST API
const response = await fetch('https://api.agentstudio.com/api/Workflow', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    definition: workflowDefinition,
    input: workflowInput
  })
});

const { id: workflowId } = await response.json();

// 4. Subscribe to workflow updates
await connection.invoke('SubscribeToWorkflow', workflowId);

// 5. Monitor workflow execution in real-time
// (Events automatically received via SignalR)
```

---

### Pattern 3: Workflow with Checkpoint Recovery

Execute long-running workflow with resilient recovery:

```typescript
async function executeResilientWorkflow() {
  try {
    // Start workflow
    const response = await fetch('https://api.agentstudio.com/api/Workflow', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer YOUR_TOKEN',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        definition: complexWorkflowDefinition,
        input: workflowInput
      })
    });

    const workflow = await response.json();

    // Poll for completion
    const result = await pollWorkflowStatus(workflow.id);

    if (result.status === 'failed') {
      // Resume from last checkpoint
      console.log('Workflow failed, resuming from checkpoint...');

      const resumeResponse = await fetch(
        `https://api.agentstudio.com/api/Workflow/${workflow.id}/resume`,
        {
          method: 'POST',
          headers: { 'Authorization': 'Bearer YOUR_TOKEN' }
        }
      );

      const resumed = await resumeResponse.json();

      // Continue monitoring resumed workflow
      return await pollWorkflowStatus(resumed.workflowId);
    }

    return result;
  } catch (error) {
    console.error('Workflow execution error:', error);
    throw error;
  }
}

async function pollWorkflowStatus(workflowId: string) {
  while (true) {
    const response = await fetch(
      `https://api.agentstudio.com/api/Workflow/${workflowId}`,
      {
        headers: { 'Authorization': 'Bearer YOUR_TOKEN' }
      }
    );

    const workflow = await response.json();

    if (['completed', 'failed', 'cancelled'].includes(workflow.status)) {
      return workflow;
    }

    // Wait 2 seconds before next poll
    await new Promise(resolve => setTimeout(resolve, 2000));
  }
}
```

---

### Pattern 4: Direct Python Agent Workflow

Execute multi-agent workflow directly via Python Agents API:

```python
import requests

API_BASE = "https://agents.agentstudio.com"
HEADERS = {"Authorization": "Bearer YOUR_TOKEN"}

# Execute multi-agent workflow
response = requests.post(
    f"{API_BASE}/workflow/execute",
    headers=HEADERS,
    json={
        "initial_task": "Build REST API for user authentication with JWT",
        "starting_agent": "architect",
        "max_iterations": 5,
        "context": {
            "framework": "FastAPI",
            "database": "PostgreSQL",
            "requirements": ["OAuth2 support", "rate limiting"]
        }
    }
)

workflow = response.json()

print(f"Workflow ID: {workflow['workflow_id']}")
print(f"Status: {workflow['success']}")
print(f"Total iterations: {workflow['total_iterations']}")

# Display each workflow step
for step in workflow['steps']:
    print(f"\nStep {step['step_number']} - {step['agent_role']}:")
    print(f"  {step['content']}")

print(f"\nFinal Output:")
print(workflow['final_output'])
```

---

## Error Handling

All Agent Studio APIs follow RFC 7807 Problem Details for HTTP APIs standard for consistent error responses.

### Error Response Format

```json
{
  "error": "ValidationError",
  "message": "Invalid agent type 'unknown'. Supported types: architect, builder, validator, scribe",
  "details": {
    "field": "agentType",
    "provided_value": "unknown",
    "allowed_values": ["architect", "builder", "validator", "scribe"],
    "trace_id": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
  },
  "timestamp": "2025-10-09T10:30:00Z"
}
```

### Standard HTTP Status Codes

| Status Code | Error Type | Description | Recommended Action |
|------------|-----------|-------------|-------------------|
| **200 OK** | - | Request successful | Continue |
| **201 Created** | - | Resource created | Use returned resource ID |
| **400 Bad Request** | ValidationError | Invalid request data | Check request format and required fields |
| **401 Unauthorized** | AuthenticationError | Missing or invalid authentication | Verify API key or OAuth token |
| **403 Forbidden** | AuthorizationError | Insufficient permissions | Check API scopes and user permissions |
| **404 Not Found** | ResourceNotFound | Resource does not exist | Verify resource ID |
| **409 Conflict** | ConflictError | Resource conflict (e.g., duplicate) | Check existing resources |
| **422 Unprocessable Entity** | ValidationError | Semantic validation failed | Review business rules and constraints |
| **429 Too Many Requests** | RateLimitExceeded | Rate limit exceeded | Implement exponential backoff |
| **500 Internal Server Error** | InternalError | Server error | Retry with exponential backoff |
| **502 Bad Gateway** | ServiceUnavailable | Upstream service error | Check service health, retry |
| **503 Service Unavailable** | ServiceUnavailable | Service temporarily unavailable | Wait and retry |
| **504 Gateway Timeout** | TimeoutError | Request timeout | Increase timeout or optimize request |

### Common Error Types

#### ValidationError (400, 422)

**Cause:** Invalid request data or business rule violation

**Example:**
```json
{
  "error": "ValidationError",
  "message": "Task content is required and cannot be empty",
  "details": {
    "field": "content",
    "validation_rule": "required",
    "provided_value": null
  },
  "timestamp": "2025-10-09T10:30:00Z"
}
```

**Recommended Action:**
- Review API documentation for required fields
- Validate request payload before sending
- Check field formats and constraints

---

#### AuthenticationError (401)

**Cause:** Missing, invalid, or expired authentication token

**Example:**
```json
{
  "error": "AuthenticationError",
  "message": "Invalid or expired authentication token",
  "timestamp": "2025-10-09T10:30:00Z"
}
```

**Recommended Action:**
- Verify API key or OAuth token is valid
- Refresh expired OAuth tokens
- Ensure Authorization header is properly formatted

---

#### RateLimitExceeded (429)

**Cause:** Too many requests in time window

**Example:**
```json
{
  "error": "RateLimitExceeded",
  "message": "Rate limit of 100 requests per minute exceeded",
  "details": {
    "limit": 100,
    "window": "60s",
    "retry_after": 45
  },
  "timestamp": "2025-10-09T10:30:00Z"
}
```

**Response Headers:**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1696860645
Retry-After: 45
```

**Recommended Action:**
- Implement exponential backoff with jitter
- Use Retry-After header to determine wait time
- Consider upgrading to higher rate limit tier

---

#### ServiceUnavailable (502, 503)

**Cause:** Agent service temporarily unavailable or upstream error

**Example:**
```json
{
  "error": "ServiceUnavailable",
  "message": "Python agent service temporarily unavailable. Please retry in a few moments.",
  "details": {
    "service": "python-agents",
    "health_status": "degraded",
    "retry_after": 30
  },
  "timestamp": "2025-10-09T10:30:00Z"
}
```

**Recommended Action:**
- Check service health endpoint
- Retry with exponential backoff (2s, 4s, 8s, 16s, 32s)
- Monitor status page for incidents

---

#### TimeoutError (504)

**Cause:** Agent task execution exceeded timeout limit

**Example:**
```json
{
  "error": "TimeoutError",
  "message": "Agent task execution exceeded timeout limit of 60 seconds",
  "details": {
    "task_id": "task-550e8400",
    "elapsed_time_ms": 60500,
    "timeout_ms": 60000
  },
  "timestamp": "2025-10-09T10:31:00Z"
}
```

**Recommended Action:**
- Break down large tasks into smaller subtasks
- Increase timeout parameter if justified
- Optimize task complexity
- Consider async workflow for long-running operations

---

### Error Handling Best Practices

**1. Implement Retry Logic with Exponential Backoff:**

```typescript
async function executeWithRetry<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3
): Promise<T> {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      const isRetryable = error.status >= 500 || error.status === 429;
      const isLastAttempt = attempt === maxRetries;

      if (!isRetryable || isLastAttempt) {
        throw error;
      }

      // Exponential backoff with jitter
      const baseDelay = 1000 * Math.pow(2, attempt);
      const jitter = Math.random() * 1000;
      const delay = baseDelay + jitter;

      console.log(`Retry attempt ${attempt + 1} after ${delay}ms`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw new Error('Max retries exceeded');
}
```

**2. Handle Rate Limiting Gracefully:**

```typescript
async function executeWithRateLimit<T>(fn: () => Promise<T>): Promise<T> {
  try {
    return await fn();
  } catch (error) {
    if (error.status === 429) {
      const retryAfter = error.headers['retry-after'];
      const waitTime = parseInt(retryAfter) * 1000;

      console.log(`Rate limited. Waiting ${retryAfter}s before retry...`);
      await new Promise(resolve => setTimeout(resolve, waitTime));

      return await fn();
    }

    throw error;
  }
}
```

**3. Provide User-Friendly Error Messages:**

```typescript
function getUserFriendlyMessage(error: any): string {
  const messages: Record<string, string> = {
    ValidationError: 'Please check your input and try again.',
    AuthenticationError: 'Please log in and try again.',
    AuthorizationError: 'You do not have permission to perform this action.',
    ResourceNotFound: 'The requested resource was not found.',
    RateLimitExceeded: 'Too many requests. Please wait a moment and try again.',
    ServiceUnavailable: 'Service temporarily unavailable. Please try again later.',
    TimeoutError: 'Request timed out. Please try again with a smaller request.',
    InternalError: 'An unexpected error occurred. Please contact support.'
  };

  return messages[error.error] || error.message || 'An error occurred';
}
```

---

## Rate Limiting

Agent Studio implements fair usage rate limiting to ensure service availability for all customers.

### Rate Limit Tiers

| Tier | Requests/Minute | Requests/Hour | Concurrent Workflows | Notes |
|------|----------------|---------------|---------------------|-------|
| **Development** | 100 | 1,000 | 5 | Free tier for testing |
| **Professional** | 1,000 | 10,000 | 20 | Recommended for small teams |
| **Enterprise** | 10,000 | 100,000 | 100 | Custom limits available |
| **Enterprise Plus** | Custom | Custom | Custom | Contact sales |

### Rate Limit Headers

All API responses include rate limit headers:

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 950
X-RateLimit-Reset: 1696860645
X-RateLimit-Window: 60
```

**Header Descriptions:**
- `X-RateLimit-Limit` - Total requests allowed in window
- `X-RateLimit-Remaining` - Remaining requests in current window
- `X-RateLimit-Reset` - Unix timestamp when limit resets
- `X-RateLimit-Window` - Window size in seconds

### Rate Limit Response

When rate limit exceeded (429 Too Many Requests):

```http
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1696860645
Retry-After: 45

{
  "error": "RateLimitExceeded",
  "message": "Rate limit of 1000 requests per minute exceeded",
  "details": {
    "limit": 1000,
    "window": "60s",
    "retry_after": 45
  },
  "timestamp": "2025-10-09T10:30:00Z"
}
```

### Best Practices

**1. Monitor Rate Limit Headers:**

```typescript
async function makeRequest(url: string, options: RequestInit) {
  const response = await fetch(url, options);

  // Log rate limit info
  const limit = response.headers.get('X-RateLimit-Limit');
  const remaining = response.headers.get('X-RateLimit-Remaining');
  const reset = response.headers.get('X-RateLimit-Reset');

  console.log(`Rate limit: ${remaining}/${limit} (resets at ${new Date(parseInt(reset) * 1000)})`);

  // Warn if approaching limit
  if (parseInt(remaining) < parseInt(limit) * 0.1) {
    console.warn('Approaching rate limit!');
  }

  return response;
}
```

**2. Implement Request Queuing:**

```typescript
class RateLimitedQueue {
  private queue: Array<() => Promise<any>> = [];
  private processing = false;
  private requestsPerMinute: number;
  private requestTimestamps: number[] = [];

  constructor(requestsPerMinute: number) {
    this.requestsPerMinute = requestsPerMinute;
  }

  async enqueue<T>(fn: () => Promise<T>): Promise<T> {
    return new Promise((resolve, reject) => {
      this.queue.push(async () => {
        try {
          const result = await fn();
          resolve(result);
        } catch (error) {
          reject(error);
        }
      });

      this.processQueue();
    });
  }

  private async processQueue() {
    if (this.processing || this.queue.length === 0) {
      return;
    }

    this.processing = true;

    while (this.queue.length > 0) {
      // Clean up old timestamps
      const now = Date.now();
      this.requestTimestamps = this.requestTimestamps.filter(
        ts => now - ts < 60000
      );

      // Check if we can make another request
      if (this.requestTimestamps.length >= this.requestsPerMinute) {
        // Wait until oldest request expires
        const oldestTimestamp = Math.min(...this.requestTimestamps);
        const waitTime = 60000 - (now - oldestTimestamp);
        await new Promise(resolve => setTimeout(resolve, waitTime));
        continue;
      }

      // Process next request
      const fn = this.queue.shift();
      if (fn) {
        this.requestTimestamps.push(Date.now());
        await fn();
      }
    }

    this.processing = false;
  }
}
```

**3. Use Batch Endpoints:**

Instead of individual requests, use batch endpoints when available:

```typescript
// ❌ Bad: Multiple individual requests
for (const task of tasks) {
  await executeAgentTask(task);
}

// ✅ Good: Single batch request
await executeWorkflow({
  tasks: tasks,
  pattern: 'parallel'
});
```

---

## SDK and Client Libraries

Agent Studio provides official SDK libraries to streamline integration and reduce boilerplate code.

### TypeScript SDK

**Installation:**
```bash
npm install @agentstudio/client
```

**Usage:**
```typescript
import { AgentStudioClient } from '@agentstudio/client';

// Initialize client
const client = new AgentStudioClient({
  apiKey: process.env.AGENT_STUDIO_API_KEY,
  baseUrl: 'https://api.agentstudio.com',
  timeout: 60000
});

// Execute agent task
const result = await client.agents.execute('architect', {
  task: 'Design microservices architecture for e-commerce platform',
  parameters: {
    scale: '100K users/day',
    cloud_provider: 'Azure'
  }
});

console.log('Architecture design:', result.result);

// Execute workflow
const workflow = await client.workflows.start({
  definition: workflowDefinition,
  input: workflowInput
});

// Monitor workflow with SignalR
await client.workflows.monitor(workflow.id, {
  onProgress: (progress) => {
    console.log(`Progress: ${progress.percentage}%`);
  },
  onThought: (thought) => {
    console.log('Agent thinking:', thought.content);
  },
  onComplete: (result) => {
    console.log('Workflow complete:', result.finalOutput);
  }
});
```

---

### Python SDK

**Installation:**
```bash
pip install agentstudio-client
```

**Usage:**
```python
from agentstudio import AgentStudioClient

# Initialize client
client = AgentStudioClient(
    api_key=os.getenv('AGENT_STUDIO_API_KEY'),
    base_url='https://api.agentstudio.com'
)

# Execute agent task
result = client.agents.execute(
    agent_type='architect',
    task='Design microservices architecture for e-commerce platform',
    parameters={
        'scale': '100K users/day',
        'cloud_provider': 'Azure'
    }
)

print(f'Architecture design: {result.result}')

# Execute workflow
workflow = client.workflows.start(
    definition=workflow_definition,
    input=workflow_input
)

# Poll for completion
result = client.workflows.wait(workflow.id, timeout=300)

print(f'Workflow complete: {result.final_output}')
```

---

### .NET SDK

**Installation:**
```bash
dotnet add package AgentStudio.Client
```

**Usage:**
```csharp
using AgentStudio.Client;

// Initialize client
var client = new AgentStudioClient(new AgentStudioClientOptions
{
    ApiKey = Environment.GetEnvironmentVariable("AGENT_STUDIO_API_KEY"),
    BaseUrl = "https://api.agentstudio.com",
    Timeout = TimeSpan.FromSeconds(60)
});

// Execute agent task
var result = await client.Agents.ExecuteAsync("architect", new AgentTaskRequest
{
    Task = "Design microservices architecture for e-commerce platform",
    Parameters = new Dictionary<string, object>
    {
        ["scale"] = "100K users/day",
        ["cloud_provider"] = "Azure"
    }
});

Console.WriteLine($"Architecture design: {result.Result}");

// Execute workflow
var workflow = await client.Workflows.StartAsync(new StartWorkflowRequest
{
    Definition = workflowDefinition,
    Input = workflowInput
});

// Monitor workflow with SignalR
await client.Workflows.MonitorAsync(workflow.Id, new WorkflowMonitorOptions
{
    OnProgress = progress => Console.WriteLine($"Progress: {progress.Percentage}%"),
    OnThought = thought => Console.WriteLine($"Agent thinking: {thought.Content}"),
    OnComplete = result => Console.WriteLine($"Complete: {result.FinalOutput}")
});
```

---

## Support

### Documentation Resources

- **API Reference:** [https://docs.agentstudio.com/api](https://docs.agentstudio.com/api)
- **OpenAPI Specifications:**
  - [Orchestration API](./openapi-orchestration-api.yaml) (Coming soon)
  - [Python Agents API](./openapi-python-agents.yaml)
  - [Agent Callbacks](./openapi-agent-callbacks.yaml)
- **SignalR Hub Contract:** [signalr-hub-contract.md](./signalr-hub-contract.md)
- **Tutorials:** [https://docs.agentstudio.com/tutorials](https://docs.agentstudio.com/tutorials)
- **GitHub Repository:** [https://github.com/Brookside-Proving-Grounds/Project-Ascension](https://github.com/Brookside-Proving-Grounds/Project-Ascension)

### Getting Help

**For Technical Questions:**
- GitHub Discussions: [https://github.com/Brookside-Proving-Grounds/Project-Ascension/discussions](https://github.com/Brookside-Proving-Grounds/Project-Ascension/discussions)
- GitHub Issues: [https://github.com/Brookside-Proving-Grounds/Project-Ascension/issues](https://github.com/Brookside-Proving-Grounds/Project-Ascension/issues)

**For Business Inquiries:**
- **Email:** consultations@brooksidebi.com
- **Phone:** +1 209 487 2047
- **Website:** [https://brooksidebi.com](https://brooksidebi.com)

### Enterprise Support

Enterprise customers receive:
- Dedicated support engineer
- 24/7 priority support via phone and email
- Custom SLA agreements (99.9%+ uptime)
- Architecture review and consultation
- Onboarding and training sessions
- Custom rate limits and quotas

**Contact us** to discuss enterprise support options: consultations@brooksidebi.com

---

## Changelog

### Version 1.0.0 (2025-10-09)

**Initial Production Release**

- ✅ Orchestration API with workflow management
- ✅ Python Agents API with 4 specialized agents
- ✅ SignalR real-time hub for workflow updates
- ✅ OAuth2 authentication support
- ✅ Rate limiting (100-10,000 req/min)
- ✅ Checkpoint-based workflow recovery
- ✅ Multiple execution patterns (sequential, parallel, iterative, dynamic)
- ✅ Comprehensive error handling (RFC 7807)
- ✅ OpenTelemetry observability integration
- ✅ TypeScript, Python, and .NET SDKs

---

**Established by Brookside BI** | Building sustainable, scalable AI orchestration platforms that drive measurable outcomes across multi-team operations.
