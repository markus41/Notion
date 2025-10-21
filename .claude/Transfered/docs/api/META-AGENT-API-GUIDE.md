# Meta-Agent Platform API Guide

## Overview

Complete guide to building applications with the Meta-Agent Platform API. This guide covers all three communication layers:

1. **React ↔ .NET**: REST API + SignalR for frontend communication
2. **.NET ↔ Python**: Control Plane API for agent orchestration
3. **Python ↔ .NET**: Callback API for agent-to-orchestrator communication

---

## Table of Contents

- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Authentication](#authentication)
- [Workflow Patterns](#workflow-patterns)
- [Complete Examples](#complete-examples)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

### 1. Execute Your First Workflow

**Request**:
```bash
curl -X POST https://api.agentstudio.dev/meta-agents/v1/workflows \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "sequential",
    "description": "Build a simple REST API for user management",
    "agents": [
      {
        "type": "architect",
        "config": {
          "focus_areas": ["api_design", "database_schema"]
        }
      },
      {
        "type": "builder",
        "config": {
          "language": "python",
          "framework": "fastapi"
        }
      },
      {
        "type": "validator",
        "config": {
          "test_types": ["unit", "integration"]
        }
      },
      {
        "type": "scribe",
        "config": {
          "output_formats": ["openapi", "markdown"]
        }
      }
    ],
    "context": {
      "requirements": "CRUD operations for users with email validation"
    },
    "timeout_minutes": 20
  }'
```

**Response**:
```json
{
  "workflow_id": "wf_7d8e9f0a1b2c",
  "status": "queued",
  "type": "sequential",
  "agents": [
    {
      "agent_id": "arch_001",
      "type": "architect",
      "status": "pending"
    },
    {
      "agent_id": "build_002",
      "type": "builder",
      "status": "pending"
    },
    {
      "agent_id": "valid_003",
      "type": "validator",
      "status": "pending"
    },
    {
      "agent_id": "scribe_004",
      "type": "scribe",
      "status": "pending"
    }
  ],
  "created_at": "2025-10-07T15:30:00Z",
  "estimated_completion": "2025-10-07T15:50:00Z",
  "status_url": "/meta-agents/v1/workflows/wf_7d8e9f0a1b2c"
}
```

### 2. Monitor Progress in Real-Time

**TypeScript/React**:
```typescript
import { HubConnectionBuilder } from '@microsoft/signalr';

const connection = new HubConnectionBuilder()
  .withUrl('/hubs/meta-agents', {
    accessTokenFactory: () => getAccessToken()
  })
  .withAutomaticReconnect()
  .build();

// Subscribe to workflow
await connection.start();
await connection.invoke('SubscribeToWorkflow', 'wf_7d8e9f0a1b2c');

// Listen for progress
connection.on('WorkflowProgress', (event) => {
  console.log(`${event.progress.percentage}% - ${event.progress.currentStep}`);
});

// Listen for completion
connection.on('WorkflowCompleted', (event) => {
  console.log('Workflow completed!', event);
});
```

### 3. Retrieve Results

**Request**:
```bash
curl https://api.agentstudio.dev/meta-agents/v1/workflows/wf_7d8e9f0a1b2c/results \
  -H "Authorization: Bearer $TOKEN"
```

**Response**:
```json
{
  "workflow_id": "wf_7d8e9f0a1b2c",
  "status": "completed",
  "results": {
    "architect": {
      "decisions": [
        {
          "decision": "Use PostgreSQL for data persistence",
          "rationale": "ACID compliance for user data integrity"
        }
      ],
      "artifacts": [
        {
          "type": "architecture_diagram",
          "url": "/artifacts/wf_7d8e9f0a1b2c/architecture.png"
        }
      ]
    },
    "builder": {
      "code_generated": {
        "files_created": 12,
        "lines_of_code": 856
      },
      "artifacts": [
        {
          "type": "source_code",
          "url": "/artifacts/wf_7d8e9f0a1b2c/source.zip"
        }
      ]
    },
    "validator": {
      "tests_run": 23,
      "tests_passed": 23,
      "coverage_percentage": 94.2
    },
    "scribe": {
      "artifacts": [
        {
          "type": "openapi_spec",
          "url": "/artifacts/wf_7d8e9f0a1b2c/openapi.yaml"
        }
      ]
    }
  },
  "completed_at": "2025-10-07T15:48:32Z",
  "duration_seconds": 1112
}
```

---

## Architecture

### Communication Flow

```
┌──────────────────────────────────────────────────────────────┐
│                      React Frontend                           │
│  - Execute workflows                                          │
│  - Monitor real-time progress                                 │
│  - Download artifacts                                         │
└────────────────┬──────────────────────┬──────────────────────┘
                 │                      │
          REST API                  SignalR
      (CRUD operations)         (Real-time events)
                 │                      │
                 ↓                      ↓
┌─────────────────────────────────────────────────────────────┐
│                  .NET Orchestrator                           │
│  - Workflow management                                       │
│  - Agent coordination                                        │
│  - SignalR hub                                               │
└────────────────┬───────────────────────────────────────────┬┘
                 │                                           │
         Control Plane API                          Callback API
      (.NET → Python)                           (Python → .NET)
                 │                                           │
                 ↓                                           ↑
┌─────────────────────────────────────────────────────────────┐
│                    Python Meta-Agents                        │
│  ┌─────────┐  ┌─────────┐  ┌──────────┐  ┌────────┐        │
│  │Architect│  │ Builder │  │Validator │  │ Scribe │        │
│  └─────────┘  └─────────┘  └──────────┘  └────────┘        │
└─────────────────────────────────────────────────────────────┘
```

### API Layers

| Layer | Protocol | Purpose | Authentication |
|-------|----------|---------|----------------|
| Frontend → Orchestrator | REST + SignalR | Workflow management, real-time updates | JWT Bearer |
| Orchestrator → Agents | REST/gRPC | Task execution, agent control | Agent JWT |
| Agents → Orchestrator | REST/gRPC | Progress callbacks, handoffs | Agent JWT |

---

## Authentication

### JWT Token Format

All API requests require a JWT token in the `Authorization` header:

```http
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Token Structure

```json
{
  "sub": "user_12345",
  "email": "developer@example.com",
  "roles": ["workflow_executor", "artifact_viewer"],
  "scopes": [
    "workflows:read",
    "workflows:write",
    "workflows:execute",
    "artifacts:read",
    "agents:read"
  ],
  "iat": 1696680000,
  "exp": 1696683600,
  "iss": "https://auth.agentstudio.dev",
  "aud": "https://api.agentstudio.dev"
}
```

### Obtaining a Token

**Request**:
```bash
curl -X POST https://auth.agentstudio.dev/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "password",
    "username": "developer@example.com",
    "password": "secure_password",
    "client_id": "meta-agent-client",
    "scope": "workflows:execute artifacts:read"
  }'
```

**Response**:
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "refresh_abc123...",
  "scope": "workflows:execute artifacts:read"
}
```

### Refreshing Tokens

```bash
curl -X POST https://auth.agentstudio.dev/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "refresh_token",
    "refresh_token": "refresh_abc123...",
    "client_id": "meta-agent-client"
  }'
```

---

## Workflow Patterns

### 1. Sequential Workflow

Agents execute one after another: Architect → Builder → Validator → Scribe

**Use Case**: Full software development lifecycle

**Example**:
```json
{
  "type": "sequential",
  "description": "Build microservice with full testing",
  "agents": [
    {
      "type": "architect",
      "config": {
        "focus_areas": ["microservices", "event_driven", "security"]
      }
    },
    {
      "type": "builder",
      "config": {
        "language": "typescript",
        "framework": "nestjs",
        "patterns": ["dependency_injection", "repository_pattern"]
      }
    },
    {
      "type": "validator",
      "config": {
        "test_types": ["unit", "integration", "e2e"],
        "coverage_threshold": 85
      }
    },
    {
      "type": "scribe",
      "config": {
        "output_formats": ["openapi", "markdown", "architecture_diagram"]
      }
    }
  ]
}
```

**Execution Flow**:
```
Architect completes → Builder starts → Builder completes → Validator starts →
Validator completes → Scribe starts → Scribe completes → Workflow done
```

---

### 2. Parallel Workflow

Multiple agents execute simultaneously.

**Use Case**: Building multiple microservices or components in parallel

**Example**:
```json
{
  "type": "parallel",
  "description": "Build multiple microservices for e-commerce platform",
  "agents": [
    {
      "type": "architect",
      "config": {
        "focus_areas": ["microservices", "api_gateway", "service_mesh"]
      }
    },
    {
      "type": "builder",
      "id": "builder_users",
      "config": {
        "service": "users-service",
        "language": "python",
        "framework": "fastapi"
      }
    },
    {
      "type": "builder",
      "id": "builder_orders",
      "config": {
        "service": "orders-service",
        "language": "typescript",
        "framework": "nestjs"
      }
    },
    {
      "type": "builder",
      "id": "builder_payments",
      "config": {
        "service": "payments-service",
        "language": "python",
        "framework": "flask"
      }
    },
    {
      "type": "validator",
      "config": {
        "test_types": ["integration", "contract", "e2e"]
      }
    }
  ],
  "context": {
    "architecture_style": "event-driven microservices",
    "message_broker": "rabbitmq"
  }
}
```

**Execution Flow**:
```
                    ┌──> Builder (users)    ──┐
Architect completes ├──> Builder (orders)   ──┤─> All complete → Validator → Done
                    └──> Builder (payments) ──┘
```

---

### 3. Iterative Workflow

Builder and Validator work in feedback loops until quality threshold is met.

**Use Case**: High-quality code with continuous validation

**Example**:
```json
{
  "type": "iterative",
  "description": "Build with continuous quality feedback",
  "agents": [
    {
      "type": "builder",
      "config": {
        "language": "rust",
        "focus": "performance_critical_code"
      }
    },
    {
      "type": "validator",
      "config": {
        "test_types": ["unit", "integration", "performance"],
        "coverage_threshold": 90,
        "performance_threshold_ms": 100
      }
    }
  ],
  "context": {
    "max_iterations": 3,
    "fail_fast": false,
    "acceptance_criteria": {
      "tests_passed": 100,
      "coverage": 90,
      "performance_p95_ms": 100
    }
  }
}
```

**Execution Flow**:
```
Iteration 1: Builder → Validator (85% coverage) → Feedback to Builder
Iteration 2: Builder → Validator (92% coverage, 1 test failing) → Feedback
Iteration 3: Builder → Validator (94% coverage, all pass) → Success
```

---

### 4. Dynamic Workflow

Workflow path determined at runtime based on agent decisions and handoffs.

**Use Case**: Complex requirements where the optimal agent sequence isn't known upfront

**Example**:
```json
{
  "type": "dynamic",
  "description": "Adaptive workflow based on project complexity",
  "agents": [
    {
      "type": "architect",
      "config": {
        "assess_complexity": true,
        "recommend_agents": true
      }
    }
  ],
  "context": {
    "requirements": "Complex multi-tenant SaaS platform",
    "allow_handoffs": true
  }
}
```

**Execution Flow** (determined dynamically):
```
Architect assesses complexity → Requests multiple Builders →
Builder 1 (API) hands off database design to Architect →
Architect provides schema → Builder 2 (Database) →
Validator finds issues → Hands off to Builder 1 for fixes →
... (continues until completion)
```

---

## Complete Examples

### Example 1: Full-Stack Application

Build a complete full-stack application with React frontend and Node.js backend.

**Workflow Request**:
```json
{
  "type": "sequential",
  "description": "Full-stack task management application",
  "agents": [
    {
      "type": "architect",
      "config": {
        "focus_areas": [
          "full_stack_architecture",
          "api_design",
          "database_schema",
          "authentication",
          "real_time_communication"
        ],
        "tech_stack_recommendation": true
      }
    },
    {
      "type": "builder",
      "id": "backend_builder",
      "config": {
        "language": "typescript",
        "framework": "nestjs",
        "features": [
          "rest_api",
          "websockets",
          "jwt_auth",
          "database_orm"
        ]
      }
    },
    {
      "type": "builder",
      "id": "frontend_builder",
      "config": {
        "language": "typescript",
        "framework": "react",
        "state_management": "zustand",
        "features": [
          "authentication",
          "real_time_updates",
          "responsive_design"
        ]
      }
    },
    {
      "type": "validator",
      "config": {
        "test_types": ["unit", "integration", "e2e"],
        "coverage_threshold": 80,
        "e2e_framework": "playwright"
      }
    },
    {
      "type": "scribe",
      "config": {
        "output_formats": [
          "openapi",
          "markdown",
          "architecture_diagram",
          "user_guide",
          "deployment_guide"
        ]
      }
    }
  ],
  "context": {
    "project_name": "TaskMaster Pro",
    "requirements": {
      "description": "Task management with teams, projects, real-time collaboration",
      "features": [
        "User authentication and authorization",
        "Create/manage teams and projects",
        "Real-time task updates via WebSocket",
        "Task assignments and notifications",
        "Kanban board view",
        "Analytics dashboard"
      ],
      "non_functional": [
        "Responsive design (mobile + desktop)",
        "< 200ms API response time",
        "Support 1000 concurrent users",
        "Secure authentication (JWT + refresh tokens)"
      ]
    }
  },
  "priority": "high",
  "timeout_minutes": 60
}
```

**Monitor with SignalR**:
```typescript
const useTaskMasterWorkflow = (workflowId: string) => {
  const [progress, setProgress] = useState(0);
  const [currentAgent, setCurrentAgent] = useState('');
  const [thoughts, setThoughts] = useState<AgentThought[]>([]);
  const [artifacts, setArtifacts] = useState<Artifact[]>([]);

  useEffect(() => {
    const connection = new HubConnectionBuilder()
      .withUrl('/hubs/meta-agents', {
        accessTokenFactory: () => getAccessToken()
      })
      .withAutomaticReconnect()
      .build();

    connection.on('WorkflowProgress', (event) => {
      setProgress(event.progress.percentage);
      setCurrentAgent(event.progress.currentStep);
    });

    connection.on('AgentThought', (event) => {
      setThoughts(prev => [...prev, event]);
    });

    connection.on('ArtifactGenerated', (event) => {
      setArtifacts(prev => [...prev, event]);

      // Auto-download code artifacts
      if (event.artifactType === 'source_code') {
        downloadArtifact(event.url, event.name);
      }
    });

    connection.on('WorkflowCompleted', (event) => {
      showSuccessNotification('TaskMaster Pro is ready!');
    });

    connection.start().then(() => {
      connection.invoke('SubscribeToWorkflow', workflowId);
      connection.invoke('SubscribeToThoughts', workflowId);
    });

    return () => {
      connection.stop();
    };
  }, [workflowId]);

  return { progress, currentAgent, thoughts, artifacts };
};
```

**Expected Results**:

After ~45 minutes, you'll receive:

1. **Architecture Artifacts**:
   - System architecture diagram
   - Database schema (PostgreSQL)
   - API design (RESTful + WebSocket)
   - Security design (JWT auth flow)

2. **Backend Code** (NestJS):
   - Complete REST API (~25 endpoints)
   - WebSocket gateway for real-time updates
   - JWT authentication module
   - Database entities and repositories
   - ~3,500 lines of TypeScript

3. **Frontend Code** (React):
   - Authentication pages (login, register, password reset)
   - Dashboard with Kanban board
   - Real-time task updates
   - Analytics charts
   - ~4,200 lines of TypeScript + CSS

4. **Tests**:
   - 87 unit tests (backend)
   - 45 unit tests (frontend)
   - 23 integration tests
   - 12 E2E tests (Playwright)
   - 84% code coverage

5. **Documentation**:
   - OpenAPI 3.0 specification
   - README with setup instructions
   - Architecture decision records (ADRs)
   - User guide
   - Deployment guide (Docker + Kubernetes)

---

### Example 2: API-First Development

Build an API with comprehensive documentation and client SDKs.

**Workflow Request**:
```json
{
  "type": "sequential",
  "description": "API-first development for payment processing service",
  "agents": [
    {
      "type": "architect",
      "config": {
        "approach": "api_first",
        "focus_areas": ["api_design", "security", "scalability"],
        "design_principles": [
          "REST best practices",
          "Idempotency",
          "Rate limiting",
          "Versioning"
        ]
      }
    },
    {
      "type": "scribe",
      "id": "api_designer",
      "config": {
        "output_formats": ["openapi"],
        "openapi_version": "3.1",
        "include_examples": true
      }
    },
    {
      "type": "builder",
      "config": {
        "language": "python",
        "framework": "fastapi",
        "generate_from_openapi": true,
        "features": [
          "request_validation",
          "response_serialization",
          "error_handling",
          "rate_limiting",
          "idempotency"
        ]
      }
    },
    {
      "type": "validator",
      "config": {
        "test_types": ["contract", "integration", "security"],
        "contract_testing_tool": "schemathesis",
        "security_scan": true
      }
    },
    {
      "type": "scribe",
      "id": "documentation_writer",
      "config": {
        "output_formats": [
          "api_reference",
          "getting_started_guide",
          "authentication_guide",
          "postman_collection",
          "client_sdk_typescript",
          "client_sdk_python"
        ]
      }
    }
  ],
  "context": {
    "api_domain": "Payment Processing",
    "endpoints_required": [
      "Create payment intent",
      "Confirm payment",
      "Refund payment",
      "List payments",
      "Get payment details",
      "Create customer",
      "Update customer",
      "List customers"
    ],
    "authentication": "API key + OAuth 2.0",
    "rate_limits": {
      "default": "100 req/min",
      "authenticated": "1000 req/min"
    }
  }
}
```

**Retrieve OpenAPI Spec**:
```bash
# Get workflow results
curl https://api.agentstudio.dev/meta-agents/v1/workflows/{workflowId}/results \
  -H "Authorization: Bearer $TOKEN" | jq -r '.results.scribe.artifacts[] | select(.type == "openapi_spec") | .url'

# Download OpenAPI spec
curl https://api.agentstudio.dev/artifacts/{artifactId} \
  -H "Authorization: Bearer $TOKEN" \
  -o payment-api-openapi.yaml

# Generate TypeScript client
npx @openapitools/openapi-generator-cli generate \
  -i payment-api-openapi.yaml \
  -g typescript-fetch \
  -o ./src/api/generated
```

---

### Example 3: Code Modernization

Modernize a legacy codebase to current best practices.

**Workflow Request**:
```json
{
  "type": "iterative",
  "description": "Modernize legacy PHP application to Python microservices",
  "agents": [
    {
      "type": "architect",
      "config": {
        "task": "modernization_strategy",
        "analyze_legacy_code": true,
        "target_architecture": "microservices",
        "migration_approach": "strangler_pattern"
      }
    },
    {
      "type": "builder",
      "config": {
        "task": "refactor_and_migrate",
        "source_language": "php",
        "target_language": "python",
        "target_framework": "fastapi",
        "preserve_functionality": true,
        "improve_code_quality": true
      }
    },
    {
      "type": "validator",
      "config": {
        "test_types": ["unit", "integration", "regression"],
        "compare_with_legacy": true,
        "acceptance_criteria": {
          "functional_parity": 100,
          "performance_improvement": 50,
          "code_quality_score": 80
        }
      }
    }
  ],
  "context": {
    "legacy_codebase_url": "https://github.com/company/legacy-app",
    "max_iterations": 5,
    "modules_to_migrate": [
      "authentication",
      "user_management",
      "reporting"
    ]
  }
}
```

---

## Error Handling

### Standard Error Response

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
    },
    {
      "field": "timeout_minutes",
      "message": "Must be between 1 and 180",
      "code": "RANGE_ERROR"
    }
  ],
  "trace_id": "1a2b3c4d5e6f"
}
```

### Common Error Codes

| HTTP Status | Error Type | Description | Retry? |
|-------------|------------|-------------|--------|
| 400 | `bad-request` | Malformed request | No |
| 401 | `unauthorized` | Invalid/expired token | Yes (refresh token) |
| 403 | `forbidden` | Insufficient permissions | No |
| 404 | `not-found` | Resource not found | No |
| 409 | `conflict` | Resource conflict | Maybe |
| 422 | `validation-error` | Invalid request data | No |
| 429 | `rate-limit-exceeded` | Too many requests | Yes (after delay) |
| 500 | `internal-error` | Server error | Yes (with backoff) |
| 503 | `service-unavailable` | Temporary outage | Yes (with backoff) |

### Retry Logic

**Exponential Backoff**:
```typescript
async function executeWorkflowWithRetry(
  request: WorkflowRequest,
  maxRetries: number = 3
): Promise<WorkflowResponse> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await executeWorkflow(request);
    } catch (error) {
      if (!isRetryable(error) || attempt === maxRetries - 1) {
        throw error;
      }

      const delayMs = Math.min(1000 * Math.pow(2, attempt), 10000);
      await sleep(delayMs);
    }
  }

  throw new Error('Max retries exceeded');
}

function isRetryable(error: ApiError): boolean {
  return error.status === 429 || error.status >= 500;
}
```

### Handling Workflow Failures

```typescript
connection.on('WorkflowFailed', async (event) => {
  console.error('Workflow failed:', event.reason);

  if (event.failedAgent) {
    // Agent-specific failure
    const { agentType, error } = event.failedAgent;

    if (error.includes('timeout')) {
      // Retry with longer timeout
      await retryWorkflow(event.workflowId, {
        timeout_minutes: originalTimeout * 1.5
      });
    } else if (error.includes('validation')) {
      // Show validation errors to user for correction
      showValidationErrors(error);
    } else {
      // Log for investigation
      logFailure(event);
    }
  }
});
```

---

## Best Practices

### 1. Workflow Design

**Use Appropriate Workflow Type**:
- **Sequential**: Single-path workflows, dependencies between agents
- **Parallel**: Independent components, faster execution
- **Iterative**: Quality-focused, continuous improvement
- **Dynamic**: Complex requirements, unpredictable paths

**Provide Context**:
```json
{
  "context": {
    "project_name": "Clear, descriptive name",
    "requirements": "Detailed, specific requirements",
    "constraints": ["Performance < 100ms", "Budget: $X"],
    "preferences": {
      "code_style": "Detailed style guide URL",
      "frameworks": ["Preferred frameworks"],
      "avoid": ["Technologies to avoid"]
    }
  }
}
```

### 2. Real-Time Monitoring

**Subscribe Selectively**:
```typescript
// Good: Subscribe only to needed events
await connection.invoke('SubscribeToWorkflow', workflowId);

// Avoid: Don't subscribe to thoughts for all workflows (high volume)
// Only subscribe when viewing detailed workflow view
if (showDetailedView) {
  await connection.invoke('SubscribeToThoughts', workflowId);
}
```

**Handle Reconnection**:
```typescript
connection.onreconnected(async (connectionId) => {
  // Resubscribe to active workflows
  for (const workflowId of activeWorkflowIds) {
    await connection.invoke('SubscribeToWorkflow', workflowId);
  }

  // Fetch latest status to catch up on missed events
  for (const workflowId of activeWorkflowIds) {
    const status = await connection.invoke('GetWorkflowStatus', workflowId);
    updateWorkflowState(workflowId, status);
  }
});
```

### 3. Artifact Management

**Download Large Artifacts Asynchronously**:
```typescript
connection.on('ArtifactGenerated', async (event) => {
  if (event.sizeBytes > 10_000_000) { // > 10MB
    // Queue for background download
    queueDownload({
      url: event.url,
      name: event.name,
      workflowId: event.workflowId
    });
  } else {
    // Download immediately
    await downloadArtifact(event.url, event.name);
  }
});
```

### 4. Error Handling

**Validate Before Submission**:
```typescript
function validateWorkflowRequest(request: WorkflowRequest): ValidationResult {
  const errors: ValidationError[] = [];

  if (!request.description || request.description.length < 10) {
    errors.push({
      field: 'description',
      message: 'Description must be at least 10 characters'
    });
  }

  if (request.agents.length === 0) {
    errors.push({
      field: 'agents',
      message: 'At least one agent is required'
    });
  }

  // Check for duplicate agent IDs
  const agentIds = request.agents.filter(a => a.id).map(a => a.id);
  const duplicates = agentIds.filter((id, index) => agentIds.indexOf(id) !== index);
  if (duplicates.length > 0) {
    errors.push({
      field: 'agents',
      message: `Duplicate agent IDs: ${duplicates.join(', ')}`
    });
  }

  return {
    valid: errors.length === 0,
    errors
  };
}
```

### 5. Rate Limiting

**Respect Rate Limits**:
```typescript
class RateLimitedClient {
  private requestCount = 0;
  private resetTime = Date.now() + 60_000;

  async executeWorkflow(request: WorkflowRequest): Promise<WorkflowResponse> {
    // Check if we're at limit
    if (this.requestCount >= 100 && Date.now() < this.resetTime) {
      const waitMs = this.resetTime - Date.now();
      await sleep(waitMs);
      this.requestCount = 0;
      this.resetTime = Date.now() + 60_000;
    }

    const response = await fetch('/meta-agents/v1/workflows', {
      method: 'POST',
      body: JSON.stringify(request),
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });

    // Update rate limit tracking from headers
    this.requestCount = parseInt(response.headers.get('X-RateLimit-Remaining') || '0');
    const resetHeader = response.headers.get('X-RateLimit-Reset');
    if (resetHeader) {
      this.resetTime = parseInt(resetHeader) * 1000;
    }

    return await response.json();
  }
}
```

---

## Troubleshooting

### Workflow Stuck in "Queued" Status

**Symptom**: Workflow remains in `queued` status for extended period.

**Possible Causes**:
1. All agents are busy (capacity issue)
2. Agent with required capabilities is offline
3. System maintenance/degraded performance

**Solutions**:
```bash
# Check system health
curl https://api.agentstudio.dev/meta-agents/v1/health

# Check agent availability
curl https://api.agentstudio.dev/meta-agents/v1/agents?type=architect&status=available

# If all agents busy, wait or cancel and retry later
curl -X DELETE https://api.agentstudio.dev/meta-agents/v1/workflows/{workflowId}
```

### SignalR Connection Drops

**Symptom**: Real-time events stop arriving.

**Solutions**:
```typescript
// Monitor connection state
connection.onclose((error) => {
  console.error('Connection closed:', error);

  // Attempt manual reconnection
  setTimeout(async () => {
    try {
      await connection.start();
      console.log('Reconnected successfully');
    } catch (err) {
      console.error('Reconnection failed:', err);
    }
  }, 5000);
});

// Use longer reconnect delays for stable connections
.withAutomaticReconnect([0, 2000, 10000, 30000, 60000])
```

### Workflow Timeout

**Symptom**: Workflow fails with "Workflow timeout exceeded" error.

**Solutions**:
1. **Increase timeout**: Set `timeout_minutes` higher
2. **Simplify workflow**: Break into smaller workflows
3. **Check agent performance**: Some agents may be slower than expected

```json
{
  "timeout_minutes": 60, // Increased from 30
  "context": {
    "performance_hint": "prioritize_speed_over_quality"
  }
}
```

### Agent Handoff Rejected

**Symptom**: `HandoffCompleted` event shows `status: rejected`.

**Cause**: Target agent unavailable or orchestrator determined handoff is unnecessary.

**Solution**: Review handoff reason, ensure context is clear:

```json
{
  "reason": "Need database schema design expertise",
  "context": {
    "current_task": "Implementing user authentication",
    "specific_question": "Should we use separate table for user roles or JSONB column?",
    "considerations": [
      "Expecting 100K users",
      "5-10 roles per user max",
      "Role-based access control (RBAC)"
    ]
  }
}
```

---

## Summary

The Meta-Agent Platform API provides:

- **REST API** for workflow management
- **SignalR Hub** for real-time updates
- **4 workflow patterns** for different use cases
- **4 meta-agent types** (Architect, Builder, Validator, Scribe)
- **Comprehensive error handling** with retry guidance
- **Artifact management** for generated code/docs
- **Agent thought tracking** for transparency

**Key Files**:
- OpenAPI Spec: `/docs/api/meta-agents-api.yaml`
- SignalR Contract: `/docs/api/meta-agent-signalr-hub.md`
- Python Schemas: `/src/python/meta_agents/api/schemas.py`
- .NET Models: `/services/dotnet/AgentStudio.Api/Models/MetaAgent/`

For more details, see the [API Reference Documentation](https://docs.agentstudio.dev/meta-agents).
