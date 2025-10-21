---
title: REST API Reference
description: Streamline workflow integration with comprehensive REST API documentation. Complete endpoint specifications, examples, and best practices.
tags:
  - api
  - rest
  - reference
  - integration
  - openapi
  - documentation
  - workflows
lastUpdated: 2025-10-09
author: Agent Studio Team
audience: developers
---

# REST API Reference

Complete API reference for the Agent Studio Orchestration Platform.

## Overview

The Agent Studio REST API enables you to create, manage, and monitor workflow executions with Python meta-agents. The API follows RESTful principles, uses JSON for request/response bodies, and supports real-time updates via SignalR WebSockets.

### Base URL

```
Production:  https://api.agentstudio.dev
Development: http://localhost:5000
```

### API Version

Current version: **v1**

All endpoints are prefixed with `/api` (e.g., `/api/workflows`).

### Rate Limiting

| Tier | Requests/Minute | Concurrent Workflows |
|------|----------------|---------------------|
| Free | 60 | 2 |
| Developer | 300 | 10 |
| Professional | 1000 | 50 |
| Enterprise | Custom | Custom |

Rate limit headers are included in all responses:
```http
X-RateLimit-Limit: 300
X-RateLimit-Remaining: 287
X-RateLimit-Reset: 1696683600
```

---

## Authentication

All API requests require authentication using JWT Bearer tokens.

### Request Format

```http
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Token Claims

```json
{
  "sub": "user_abc123",
  "email": "developer@example.com",
  "roles": ["workflow_executor"],
  "scopes": ["workflows:read", "workflows:write", "workflows:execute"],
  "iat": 1696680000,
  "exp": 1696683600,
  "iss": "https://auth.agentstudio.dev",
  "aud": "https://api.agentstudio.dev"
}
```

### Obtaining Access Tokens

```bash
curl -X POST https://auth.agentstudio.dev/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "client_credentials",
    "client_id": "your_client_id",
    "client_secret": "your_client_secret",
    "scope": "workflows:execute"
  }'
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "workflows:execute"
}
```

---

## Error Handling

All errors follow the RFC 7807 Problem Details standard.

### Error Response Format

```json
{
  "type": "https://api.agentstudio.dev/errors/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "One or more validation errors occurred",
  "instance": "/api/workflows",
  "traceId": "00-abc123-def456-00",
  "errors": [
    {
      "field": "definition.steps",
      "message": "At least one step is required",
      "code": "REQUIRED_FIELD"
    }
  ]
}
```

### HTTP Status Codes

| Code | Meaning | Retry? |
|------|---------|--------|
| 200 | OK - Request succeeded | N/A |
| 201 | Created - Resource created | N/A |
| 204 | No Content - Success with no response body | N/A |
| 400 | Bad Request - Malformed request | No |
| 401 | Unauthorized - Invalid/expired token | Yes (refresh) |
| 403 | Forbidden - Insufficient permissions | No |
| 404 | Not Found - Resource doesn't exist | No |
| 409 | Conflict - Resource state conflict | Maybe |
| 422 | Unprocessable Entity - Validation failed | No |
| 429 | Too Many Requests - Rate limit exceeded | Yes (exponential backoff) |
| 500 | Internal Server Error - Server error | Yes (exponential backoff) |
| 503 | Service Unavailable - Temporary outage | Yes (exponential backoff) |
| 504 | Gateway Timeout - Request timeout | Yes (exponential backoff) |

### Error Codes

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `REQUIRED_FIELD` | Required field is missing | 422 |
| `INVALID_FORMAT` | Field format is invalid | 422 |
| `RANGE_ERROR` | Value out of acceptable range | 422 |
| `WORKFLOW_NOT_FOUND` | Workflow doesn't exist | 404 |
| `WORKFLOW_ALREADY_RUNNING` | Cannot modify running workflow | 409 |
| `INVALID_WORKFLOW_STATUS` | Operation not allowed in current status | 409 |
| `AGENT_TYPE_NOT_FOUND` | Unknown agent type | 400 |
| `RATE_LIMIT_EXCEEDED` | Too many requests | 429 |
| `INTERNAL_ERROR` | Unexpected server error | 500 |

---

## Endpoints

## Workflow Management

### Create and Start Workflow

Start a new workflow execution asynchronously.

<ApiEndpoint
  method="POST"
  path="/api/workflows"
  description="Create and start a new workflow execution"
/>

**Request Body:**

```json
{
  "definition": {
    "id": "customer-analysis-workflow",
    "name": "Customer Feedback Analysis",
    "description": "Analyze customer feedback and generate insights",
    "pattern": "sequential",
    "steps": [
      {
        "id": "step1",
        "name": "Data Collection",
        "agentType": "data-collector",
        "configuration": {
          "source": "feedback_database",
          "limit": 1000
        },
        "timeout": "00:05:00"
      },
      {
        "id": "step2",
        "name": "Sentiment Analysis",
        "agentType": "sentiment-analyzer",
        "dependsOn": ["step1"],
        "configuration": {
          "model": "bert-base",
          "threshold": 0.7
        }
      },
      {
        "id": "step3",
        "name": "Report Generation",
        "agentType": "report-generator",
        "dependsOn": ["step2"],
        "configuration": {
          "format": "pdf",
          "includeCharts": true
        }
      }
    ],
    "timeout": "00:30:00",
    "maxRetries": 3
  },
  "input": {
    "dateRange": {
      "start": "2025-09-01",
      "end": "2025-10-01"
    },
    "categories": ["product", "service", "support"]
  },
  "initiatedBy": "user@example.com"
}
```

**Request Schema:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `definition` | object | Yes | Workflow definition containing structure and configuration |
| `definition.id` | string | Yes | Unique identifier for the workflow definition |
| `definition.name` | string | Yes | Human-readable workflow name |
| `definition.description` | string | No | Description of what the workflow does |
| `definition.pattern` | enum | Yes | Execution pattern: `sequential`, `parallel`, `iterative`, `dynamic` |
| `definition.steps` | array | Yes | Array of workflow steps (minimum 1) |
| `definition.steps[].id` | string | Yes | Unique step identifier |
| `definition.steps[].name` | string | Yes | Human-readable step name |
| `definition.steps[].agentType` | string | Yes | Type of agent to execute this step |
| `definition.steps[].dependsOn` | array | No | Array of step IDs that must complete first |
| `definition.steps[].configuration` | object | No | Step-specific configuration |
| `definition.steps[].timeout` | string | No | ISO 8601 duration (e.g., "PT5M" for 5 minutes) |
| `definition.timeout` | string | No | Overall workflow timeout (ISO 8601 duration) |
| `definition.maxRetries` | integer | No | Maximum retry attempts (default: 3, range: 0-10) |
| `input` | object | No | Input data for the workflow |
| `initiatedBy` | string | No | User or system that initiated the workflow |

**Success Response (201 Created):**

```json
{
  "id": "wf_7d8e9f0a1b2c",
  "workflowDefinitionId": "customer-analysis-workflow",
  "pattern": "sequential",
  "status": "pending",
  "tasks": [
    {
      "id": "task_001",
      "workflowExecutionId": "wf_7d8e9f0a1b2c",
      "stepDefinitionId": "step1",
      "agentType": "data-collector",
      "status": "pending",
      "createdAt": "2025-10-08T10:30:00Z",
      "retryCount": 0,
      "maxRetries": 3
    },
    {
      "id": "task_002",
      "workflowExecutionId": "wf_7d8e9f0a1b2c",
      "stepDefinitionId": "step2",
      "agentType": "sentiment-analyzer",
      "status": "waiting",
      "createdAt": "2025-10-08T10:30:00Z",
      "retryCount": 0,
      "maxRetries": 3,
      "dependsOn": ["task_001"]
    },
    {
      "id": "task_003",
      "workflowExecutionId": "wf_7d8e9f0a1b2c",
      "stepDefinitionId": "step3",
      "agentType": "report-generator",
      "status": "waiting",
      "createdAt": "2025-10-08T10:30:00Z",
      "retryCount": 0,
      "maxRetries": 3,
      "dependsOn": ["task_002"]
    }
  ],
  "context": {
    "workflowExecutionId": "wf_7d8e9f0a1b2c",
    "state": {},
    "results": {},
    "events": [],
    "progress": 0,
    "createdAt": "2025-10-08T10:30:00Z",
    "lastUpdatedAt": "2025-10-08T10:30:00Z"
  },
  "createdAt": "2025-10-08T10:30:00Z",
  "initiatedBy": "user@example.com",
  "metadata": null,
  "etag": "\"abc123\""
}
```

**Error Responses:**

```json
// 400 Bad Request - Invalid agent type
{
  "type": "https://api.agentstudio.dev/errors/validation-error",
  "title": "Validation Error",
  "status": 400,
  "detail": "Invalid agent type specified",
  "errors": [
    {
      "field": "definition.steps[0].agentType",
      "message": "Agent type 'unknown-agent' not found",
      "code": "AGENT_TYPE_NOT_FOUND"
    }
  ]
}

// 422 Unprocessable Entity - Validation error
{
  "type": "https://api.agentstudio.dev/errors/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "One or more validation errors occurred",
  "errors": [
    {
      "field": "definition.steps",
      "message": "At least one step is required",
      "code": "REQUIRED_FIELD"
    },
    {
      "field": "definition.timeout",
      "message": "Timeout must be between 1 minute and 180 minutes",
      "code": "RANGE_ERROR"
    }
  ]
}
```

**Example Requests:**

::: code-group

```bash [cURL]
curl -X POST https://api.agentstudio.dev/api/workflows \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "definition": {
      "id": "customer-analysis",
      "name": "Customer Analysis",
      "pattern": "sequential",
      "steps": [
        {
          "id": "collect",
          "name": "Collect Data",
          "agentType": "data-collector"
        },
        {
          "id": "analyze",
          "name": "Analyze Sentiment",
          "agentType": "sentiment-analyzer",
          "dependsOn": ["collect"]
        }
      ]
    },
    "input": {
      "source": "customer_feedback"
    }
  }'
```
```

:::

::: code-group

```typescript [TypeScript]
import { AgentStudioClient } from '@agentstudio/client';

const client = new AgentStudioClient({
  apiKey: process.env.AGENTSTUDIO_API_KEY
});

const workflow = await client.workflows.create({
  definition: {
    id: 'customer-analysis',
    name: 'Customer Analysis',
    pattern: 'sequential',
    steps: [
      {
        id: 'collect',
        name: 'Collect Data',
        agentType: 'data-collector'
      },
      {
        id: 'analyze',
        name: 'Analyze Sentiment',
        agentType: 'sentiment-analyzer',
        dependsOn: ['collect']
      }
    ]
  },
  input: {
    source: 'customer_feedback'
  }
});

console.log(`Workflow started: ${workflow.id}`);
```
```

:::

::: code-group

```python [Python]
from agentstudio import AgentStudioClient

client = AgentStudioClient(api_key=os.environ['AGENTSTUDIO_API_KEY'])

workflow = client.workflows.create(
    definition={
        'id': 'customer-analysis',
        'name': 'Customer Analysis',
        'pattern': 'sequential',
        'steps': [
            {
                'id': 'collect',
                'name': 'Collect Data',
                'agentType': 'data-collector'
            },
            {
                'id': 'analyze',
                'name': 'Analyze Sentiment',
                'agentType': 'sentiment-analyzer',
                'dependsOn': ['collect']
            }
        ]
    },
    input={
        'source': 'customer_feedback'
    }
)

print(f'Workflow started: {workflow.id}')
```
```

:::

---

### Execute Workflow and Wait

Execute a workflow synchronously and wait for completion (blocks until finished or timeout).

<ApiEndpoint
  method="POST"
  path="/api/workflows/execute"
  description="Execute workflow and wait for completion"
/>

**Request Body:**

```json
{
  "definition": {
    "id": "quick-analysis",
    "name": "Quick Data Analysis",
    "pattern": "sequential",
    "steps": [
      {
        "id": "analyze",
        "name": "Analyze Data",
        "agentType": "data-analyzer",
        "configuration": {
          "model": "fast"
        }
      }
    ],
    "timeout": "00:10:00"
  },
  "input": {
    "data": [1, 2, 3, 4, 5]
  },
  "initiatedBy": "api-client"
}
```

**Success Response (200 OK):**

```json
{
  "workflowId": "wf_abc123",
  "success": true,
  "context": {
    "workflowExecutionId": "wf_abc123",
    "state": {},
    "results": {
      "task_001": {
        "success": true,
        "result": {
          "mean": 3.0,
          "median": 3,
          "stdDev": 1.414
        },
        "thoughts": [
          {
            "timestamp": "2025-10-08T10:35:12Z",
            "type": "observation",
            "content": "Dataset contains 5 numeric values"
          },
          {
            "timestamp": "2025-10-08T10:35:13Z",
            "type": "reasoning",
            "content": "Computing statistical measures"
          }
        ],
        "metadata": {
          "executionTimeMs": 1250
        }
      }
    },
    "events": [
      {
        "type": "TaskCompleted",
        "timestamp": "2025-10-08T10:35:15Z",
        "data": {
          "taskId": "task_001",
          "success": true
        },
        "severity": "Information"
      }
    ],
    "progress": 100,
    "createdAt": "2025-10-08T10:35:00Z",
    "lastUpdatedAt": "2025-10-08T10:35:15Z"
  },
  "duration": "00:00:15.234"
}
```

**Error Responses:**

```json
// 408 Request Timeout - Workflow exceeded timeout
{
  "type": "https://api.agentstudio.dev/errors/workflow-timeout",
  "title": "Workflow Timeout",
  "status": 408,
  "detail": "Workflow execution exceeded the specified timeout",
  "workflowId": "wf_abc123",
  "timeoutSeconds": 600
}

// 499 Client Closed Request - Client cancelled request
{
  "type": "https://api.agentstudio.dev/errors/request-cancelled",
  "title": "Request Cancelled",
  "status": 499,
  "detail": "Workflow execution was cancelled by the client"
}
```

**Example Requests:**

::: code-group

```typescript [TypeScript]
const result = await client.workflows.execute({
  definition: {
    id: 'quick-analysis',
    name: 'Quick Analysis',
    pattern: 'sequential',
    steps: [
      {
        id: 'analyze',
        name: 'Analyze',
        agentType: 'data-analyzer'
      }
    ]
  },
  input: {
    data: [1, 2, 3, 4, 5]
  }
});

console.log('Result:', result.context.results);
```
```

:::

---

### Get Workflow Details

Retrieve detailed information about a workflow execution.

<ApiEndpoint
  method="GET"
  path="/api/workflows/{id}"
  description="Get workflow execution details"
/>

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Workflow execution ID |

**Success Response (200 OK):**

```json
{
  "id": "wf_7d8e9f0a1b2c",
  "workflowDefinitionId": "customer-analysis-workflow",
  "pattern": "sequential",
  "status": "running",
  "tasks": [
    {
      "id": "task_001",
      "workflowExecutionId": "wf_7d8e9f0a1b2c",
      "stepDefinitionId": "step1",
      "agentType": "data-collector",
      "status": "completed",
      "createdAt": "2025-10-08T10:30:00Z",
      "startedAt": "2025-10-08T10:30:05Z",
      "completedAt": "2025-10-08T10:32:15Z",
      "retryCount": 0,
      "maxRetries": 3,
      "response": {
        "success": true,
        "result": {
          "recordsCollected": 1000
        },
        "metadata": {
          "executionTimeMs": 130000
        }
      }
    },
    {
      "id": "task_002",
      "workflowExecutionId": "wf_7d8e9f0a1b2c",
      "stepDefinitionId": "step2",
      "agentType": "sentiment-analyzer",
      "status": "running",
      "createdAt": "2025-10-08T10:30:00Z",
      "startedAt": "2025-10-08T10:32:20Z",
      "retryCount": 0,
      "maxRetries": 3,
      "dependsOn": ["task_001"]
    },
    {
      "id": "task_003",
      "workflowExecutionId": "wf_7d8e9f0a1b2c",
      "stepDefinitionId": "step3",
      "agentType": "report-generator",
      "status": "waiting",
      "createdAt": "2025-10-08T10:30:00Z",
      "retryCount": 0,
      "maxRetries": 3,
      "dependsOn": ["task_002"]
    }
  ],
  "context": {
    "workflowExecutionId": "wf_7d8e9f0a1b2c",
    "state": {
      "currentStep": 2,
      "totalSteps": 3
    },
    "results": {
      "task_001": {
        "success": true,
        "result": {
          "recordsCollected": 1000
        }
      }
    },
    "events": [
      {
        "type": "WorkflowStarted",
        "timestamp": "2025-10-08T10:30:00Z",
        "severity": "Information"
      },
      {
        "type": "TaskCompleted",
        "timestamp": "2025-10-08T10:32:15Z",
        "data": {
          "taskId": "task_001",
          "success": true
        },
        "severity": "Information"
      },
      {
        "type": "TaskStarted",
        "timestamp": "2025-10-08T10:32:20Z",
        "data": {
          "taskId": "task_002"
        },
        "severity": "Information"
      }
    ],
    "progress": 33.33,
    "createdAt": "2025-10-08T10:30:00Z",
    "lastUpdatedAt": "2025-10-08T10:32:20Z"
  },
  "createdAt": "2025-10-08T10:30:00Z",
  "startedAt": "2025-10-08T10:30:05Z",
  "initiatedBy": "user@example.com",
  "etag": "\"def456\""
}
```

**Error Response (404 Not Found):**

```json
{
  "type": "https://api.agentstudio.dev/errors/not-found",
  "title": "Not Found",
  "status": 404,
  "detail": "Workflow 'wf_invalid' not found"
}
```

**Example Requests:**

::: code-group

```bash [cURL]
curl https://api.agentstudio.dev/api/workflows/wf_7d8e9f0a1b2c \
  -H "Authorization: Bearer $TOKEN"
```
```

:::

::: code-group

```typescript [TypeScript]
const workflow = await client.workflows.get('wf_7d8e9f0a1b2c');
console.log(`Status: ${workflow.status}, Progress: ${workflow.context.progress}%`);
```
```

:::

---

### List Workflows

List workflow executions with optional filtering and pagination.

<ApiEndpoint
  method="GET"
  path="/api/workflows"
  description="List workflow executions"
/>

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `status` | enum | No | - | Filter by status: `pending`, `running`, `completed`, `failed`, `cancelled`, `paused` |
| `limit` | integer | No | 100 | Maximum results to return (range: 1-1000) |
| `offset` | integer | No | 0 | Number of results to skip for pagination |
| `sortBy` | enum | No | `createdAt` | Sort field: `createdAt`, `startedAt`, `completedAt` |
| `sortOrder` | enum | No | `desc` | Sort order: `asc`, `desc` |

**Success Response (200 OK):**

```json
{
  "items": [
    {
      "id": "wf_7d8e9f0a1b2c",
      "workflowDefinitionId": "customer-analysis-workflow",
      "pattern": "sequential",
      "status": "running",
      "createdAt": "2025-10-08T10:30:00Z",
      "startedAt": "2025-10-08T10:30:05Z",
      "initiatedBy": "user@example.com",
      "context": {
        "progress": 33.33
      }
    },
    {
      "id": "wf_abc123def456",
      "workflowDefinitionId": "data-processing",
      "pattern": "parallel",
      "status": "completed",
      "createdAt": "2025-10-08T09:15:00Z",
      "startedAt": "2025-10-08T09:15:02Z",
      "completedAt": "2025-10-08T09:45:30Z",
      "initiatedBy": "system",
      "context": {
        "progress": 100
      }
    }
  ],
  "total": 2,
  "limit": 100,
  "offset": 0,
  "hasMore": false
}
```

**Example Requests:**

::: code-group

```bash [cURL]
# List all running workflows
curl "https://api.agentstudio.dev/api/workflows?status=running&limit=50" \
  -H "Authorization: Bearer $TOKEN"

# List completed workflows, most recent first
curl "https://api.agentstudio.dev/api/workflows?status=completed&sortBy=completedAt&sortOrder=desc" \
  -H "Authorization: Bearer $TOKEN"
```
```

:::

::: code-group

```typescript [TypeScript]
// List running workflows
const runningWorkflows = await client.workflows.list({
  status: 'running',
  limit: 50
});

// List completed workflows with pagination
const completedWorkflows = await client.workflows.list({
  status: 'completed',
  sortBy: 'completedAt',
  sortOrder: 'desc',
  offset: 0,
  limit: 20
});

for (const workflow of completedWorkflows.items) {
  console.log(`${workflow.id}: ${workflow.status}`);
}
```
```

:::

---

### Resume Workflow

Resume a paused or failed workflow from the latest checkpoint.

<ApiEndpoint
  method="POST"
  path="/api/workflows/{id}/resume"
  description="Resume workflow from checkpoint"
/>

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Workflow execution ID |

**Success Response (200 OK):**

```json
{
  "workflowId": "wf_7d8e9f0a1b2c",
  "success": true,
  "context": {
    "workflowExecutionId": "wf_7d8e9f0a1b2c",
    "progress": 100,
    "results": {
      "task_001": {
        "success": true,
        "result": { "data": "completed" }
      },
      "task_002": {
        "success": true,
        "result": { "analysis": "positive sentiment" }
      }
    }
  },
  "duration": "00:05:23.456"
}
```

**Error Response (404 Not Found):**

```json
{
  "type": "https://api.agentstudio.dev/errors/not-found",
  "title": "Not Found",
  "status": 404,
  "detail": "Workflow 'wf_invalid' not found"
}
```

**Example Requests:**

::: code-group

```bash [cURL]
curl -X POST https://api.agentstudio.dev/api/workflows/wf_7d8e9f0a1b2c/resume \
  -H "Authorization: Bearer $TOKEN"
```
```

:::

::: code-group

```typescript [TypeScript]
const result = await client.workflows.resume('wf_7d8e9f0a1b2c');
console.log(`Workflow resumed and ${result.success ? 'completed' : 'failed'}`);
```
```

:::

---

### Cancel Workflow

Cancel a running or pending workflow execution.

<ApiEndpoint
  method="POST"
  path="/api/workflows/{id}/cancel"
  description="Cancel a running workflow"
/>

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Workflow execution ID |

**Success Response (200 OK):**

```json
{
  "message": "Workflow 'wf_7d8e9f0a1b2c' cancelled successfully"
}
```

**Error Responses:**

```json
// 404 Not Found - Workflow not found or not cancellable
{
  "type": "https://api.agentstudio.dev/errors/not-found",
  "title": "Not Found",
  "status": 404,
  "detail": "Workflow 'wf_7d8e9f0a1b2c' not found or not running"
}

// 409 Conflict - Workflow cannot be cancelled in current state
{
  "type": "https://api.agentstudio.dev/errors/invalid-operation",
  "title": "Invalid Operation",
  "status": 409,
  "detail": "Cannot cancel workflow in 'completed' status"
}
```

---

### Pause Workflow

Pause a running workflow execution (creates checkpoint).

<ApiEndpoint
  method="POST"
  path="/api/workflows/{id}/pause"
  description="Pause a running workflow"
/>

**Success Response (200 OK):**

```json
{
  "message": "Workflow 'wf_7d8e9f0a1b2c' paused successfully"
}
```

---

### Delete Workflow

Delete a workflow execution and all its checkpoints.

<ApiEndpoint
  method="DELETE"
  path="/api/workflows/{id}"
  description="Delete workflow and checkpoints"
/>

**Success Response (200 OK):**

```json
{
  "message": "Workflow 'wf_7d8e9f0a1b2c' deleted successfully"
}
```

**Error Response (404 Not Found):**

```json
{
  "type": "https://api.agentstudio.dev/errors/not-found",
  "title": "Not Found",
  "status": 404,
  "detail": "Workflow 'wf_invalid' not found"
}
```

---

### Get Workflow Checkpoints

Retrieve all checkpoints for a workflow execution.

<ApiEndpoint
  method="GET"
  path="/api/workflows/{id}/checkpoints"
  description="Get workflow checkpoints"
/>

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Workflow execution ID |

**Success Response (200 OK):**

```json
[
  {
    "id": "cp_001",
    "workflowExecutionId": "wf_7d8e9f0a1b2c",
    "sequenceNumber": 1,
    "type": "automatic",
    "completedTaskId": "task_001",
    "nextTaskId": "task_002",
    "contextSnapshot": {
      "workflowExecutionId": "wf_7d8e9f0a1b2c",
      "state": {
        "currentStep": 1
      },
      "results": {
        "task_001": {
          "success": true,
          "result": { "data": "collected" }
        }
      },
      "progress": 33.33,
      "timestamp": "2025-10-08T10:32:15Z"
    },
    "createdAt": "2025-10-08T10:32:15Z",
    "isRecoverable": true,
    "etag": "\"abc123\""
  },
  {
    "id": "cp_002",
    "workflowExecutionId": "wf_7d8e9f0a1b2c",
    "sequenceNumber": 2,
    "type": "automatic",
    "completedTaskId": "task_002",
    "nextTaskId": "task_003",
    "contextSnapshot": {
      "workflowExecutionId": "wf_7d8e9f0a1b2c",
      "state": {
        "currentStep": 2
      },
      "results": {
        "task_001": {
          "success": true,
          "result": { "data": "collected" }
        },
        "task_002": {
          "success": true,
          "result": { "analysis": "completed" }
        }
      },
      "progress": 66.67,
      "timestamp": "2025-10-08T10:35:42Z"
    },
    "createdAt": "2025-10-08T10:35:42Z",
    "isRecoverable": true,
    "etag": "\"def456\""
  }
]
```

---

## Agent Management

### Get Available Agent Types

List all available agent types in the system.

<ApiEndpoint
  method="GET"
  path="/api/meta-agent/types"
  description="Get available agent types"
/>

**Success Response (200 OK):**

```json
[
  "data-collector",
  "sentiment-analyzer",
  "report-generator",
  "code-analyzer",
  "test-runner"
]
```

**Example Requests:**

::: code-group

```bash [cURL]
curl https://api.agentstudio.dev/api/meta-agent/types \
  -H "Authorization: Bearer $TOKEN"
```
```

:::

::: code-group

```typescript [TypeScript]
const agentTypes = await client.agents.getTypes();
console.log('Available agents:', agentTypes);
```
```

:::

---

### Execute Agent Task

Execute a single task with a specific agent (without creating a workflow).

<ApiEndpoint
  method="POST"
  path="/api/meta-agent/{agentType}/execute"
  description="Execute task with specific agent"
/>

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `agentType` | string | Yes | Type of agent to execute |

**Request Body:**

```json
{
  "task": "Analyze the sentiment of customer reviews",
  "input": {
    "reviews": [
      "Great product! Highly recommend.",
      "Terrible experience, would not buy again.",
      "It's okay, nothing special."
    ]
  },
  "context": {
    "language": "en",
    "domain": "e-commerce"
  },
  "configuration": {
    "model": "bert-base-uncased",
    "temperature": 0.7,
    "maxTokens": 1000
  },
  "timeout": "00:05:00"
}
```

**Success Response (200 OK):**

```json
{
  "success": true,
  "result": {
    "sentiments": [
      {
        "text": "Great product! Highly recommend.",
        "sentiment": "positive",
        "confidence": 0.95
      },
      {
        "text": "Terrible experience, would not buy again.",
        "sentiment": "negative",
        "confidence": 0.92
      },
      {
        "text": "It's okay, nothing special.",
        "sentiment": "neutral",
        "confidence": 0.78
      }
    ],
    "overallSentiment": "mixed",
    "summary": "2 positive, 1 negative, 1 neutral"
  },
  "thoughts": [
    {
      "timestamp": "2025-10-08T10:40:00Z",
      "type": "observation",
      "content": "Received 3 customer reviews for sentiment analysis"
    },
    {
      "timestamp": "2025-10-08T10:40:01Z",
      "type": "reasoning",
      "content": "Using BERT model for multi-class sentiment classification"
    },
    {
      "timestamp": "2025-10-08T10:40:03Z",
      "type": "action",
      "content": "Computing sentiment scores for each review"
    }
  ],
  "metadata": {
    "model": "bert-base-uncased",
    "executionTimeMs": 3250,
    "tokensUsed": 156
  }
}
```

**Error Responses:**

```json
// 400 Bad Request - Invalid agent type
{
  "type": "https://api.agentstudio.dev/errors/validation-error",
  "title": "Validation Error",
  "status": 400,
  "detail": "Invalid agent type 'unknown-agent'"
}

// 502 Bad Gateway - Agent service error
{
  "type": "https://api.agentstudio.dev/errors/agent-error",
  "title": "Agent Service Error",
  "status": 502,
  "detail": "Error communicating with agent service",
  "agentType": "sentiment-analyzer"
}

// 504 Gateway Timeout - Agent timeout
{
  "type": "https://api.agentstudio.dev/errors/agent-timeout",
  "title": "Agent Timeout",
  "status": 504,
  "detail": "Agent task timed out after 5 minutes",
  "agentType": "sentiment-analyzer"
}
```

**Example Requests:**

::: code-group

```typescript [TypeScript]
const response = await client.agents.execute('sentiment-analyzer', {
  task: 'Analyze customer sentiment',
  input: {
    reviews: [
      'Great product!',
      'Terrible experience.',
      'It\'s okay.'
    ]
  }
});

console.log('Overall sentiment:', response.result.overallSentiment);
```
```

:::

---

### Execute Agent Task (Streaming)

Execute a task with streaming responses (Server-Sent Events).

<ApiEndpoint
  method="POST"
  path="/api/meta-agent/{agentType}/execute/stream"
  description="Execute task with streaming updates"
/>

**Response Format (text/event-stream):**

```
data: {"type":"thought","thought":{"timestamp":"2025-10-08T10:40:00Z","type":"observation","content":"Analyzing data"}}

data: {"type":"thought","thought":{"timestamp":"2025-10-08T10:40:01Z","type":"reasoning","content":"Computing statistics"}}

data: {"type":"response","response":{"success":true,"result":{"mean":3.5}}}

data: [DONE]
```

**Example Requests:**

::: code-group

```typescript [TypeScript]
const stream = await client.agents.executeStreaming('data-analyzer', {
  task: 'Analyze dataset',
  input: { data: [1, 2, 3, 4, 5, 6] }
});

for await (const event of stream) {
  if (event.type === 'thought') {
    console.log(`[${event.thought.type}] ${event.thought.content}`);
  } else if (event.type === 'response') {
    console.log('Final result:', event.response.result);
  }
}
```
```

:::

---

### Check Agent Health

Check the health status of the Python agent service.

<ApiEndpoint
  method="GET"
  path="/api/meta-agent/health"
  description="Check agent service health"
/>

**Success Response (200 OK):**

```json
{
  "status": "healthy",
  "timestamp": "2025-10-08T10:45:00Z"
}
```

**Error Response (503 Service Unavailable):**

```json
{
  "status": "unhealthy",
  "error": "Connection to agent service failed",
  "timestamp": "2025-10-08T10:45:00Z"
}
```

---

### Cancel Agent Task

Cancel a running agent task.

<ApiEndpoint
  method="POST"
  path="/api/meta-agent/tasks/{taskId}/cancel"
  description="Cancel a running agent task"
/>

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `taskId` | string | Yes | Agent task ID |

**Success Response (200 OK):**

```json
{
  "message": "Task 'task_abc123' cancelled successfully"
}
```

**Error Response (404 Not Found):**

```json
{
  "type": "https://api.agentstudio.dev/errors/not-found",
  "title": "Not Found",
  "status": 404,
  "detail": "Task 'task_invalid' not found or already completed"
}
```

---

## Real-Time Communication (SignalR)

For real-time workflow updates, use SignalR WebSocket connections.

See the complete [SignalR Hub Reference](./signalr-hub-contract.md) for detailed documentation on:

- Connection setup and authentication
- Server-to-client events (`WorkflowStarted`, `WorkflowCompleted`, `TaskStatusChanged`, etc.)
- Client-to-server methods (`SubscribeToWorkflow`, `SubscribeToTask`, etc.)
- Reconnection handling
- Event filtering

### Quick Example

::: code-group

```typescript [TypeScript]
import { HubConnectionBuilder } from '@microsoft/signalr';

const connection = new HubConnectionBuilder()
  .withUrl('/hubs/agentstudio', {
    accessTokenFactory: () => getAccessToken()
  })
  .withAutomaticReconnect()
  .build();

// Subscribe to workflow events
connection.on('WorkflowProgress', (event) => {
  console.log(`Progress: ${event.progress.percentage}%`);
});

connection.on('WorkflowCompleted', (event) => {
  console.log('Workflow completed!', event);
});

await connection.start();
await connection.invoke('SubscribeToWorkflow', workflowId);
```
```

:::

---

## Data Models

### WorkflowExecution

```typescript
interface WorkflowExecution {
  id: string;
  workflowDefinitionId: string;
  pattern: 'sequential' | 'parallel' | 'iterative' | 'dynamic';
  status: 'pending' | 'running' | 'completed' | 'failed' | 'cancelled' | 'paused';
  tasks: AgentTask[];
  context: ExecutionContext;
  createdAt: string; // ISO 8601
  startedAt?: string;
  completedAt?: string;
  errorMessage?: string;
  initiatedBy: string;
  metadata?: Record<string, any>;
  etag?: string;
}
```

### WorkflowDefinition

```typescript
interface WorkflowDefinition {
  id: string;
  name: string;
  description?: string;
  pattern: 'sequential' | 'parallel' | 'iterative' | 'dynamic';
  steps: WorkflowStepDefinition[];
  timeout?: string; // ISO 8601 duration
  maxRetries?: number; // 0-10
}
```

### WorkflowStepDefinition

```typescript
interface WorkflowStepDefinition {
  id: string;
  name: string;
  agentType: string;
  dependsOn?: string[];
  configuration?: Record<string, any>;
  timeout?: string; // ISO 8601 duration
}
```

### AgentTask

```typescript
interface AgentTask {
  id: string;
  workflowExecutionId: string;
  stepDefinitionId: string;
  agentType: string;
  status: 'pending' | 'running' | 'completed' | 'failed' | 'skipped' | 'waiting';
  request: AgentRequest;
  response?: AgentResponse;
  createdAt: string;
  startedAt?: string;
  completedAt?: string;
  errorMessage?: string;
  retryCount: number;
  maxRetries: number;
  dependsOn?: string[];
}
```

### AgentRequest

```typescript
interface AgentRequest {
  task: string;
  input?: Record<string, any>;
  context?: Record<string, any>;
  configuration?: AgentConfiguration;
  timeout?: string; // ISO 8601 duration
}
```

### AgentResponse

```typescript
interface AgentResponse {
  success: boolean;
  result: Record<string, any>;
  thoughts?: AgentThought[];
  handoff?: AgentHandoff;
  errorMessage?: string;
  metadata?: Record<string, any>;
}
```

### AgentThought

```typescript
interface AgentThought {
  timestamp: string; // ISO 8601
  type: string; // e.g., 'observation', 'reasoning', 'action'
  content: string;
  metadata?: Record<string, any>;
}
```

### ExecutionContext

```typescript
interface ExecutionContext {
  workflowExecutionId: string;
  state: Record<string, any>;
  results: Record<string, AgentResponse>;
  events: ExecutionEvent[];
  progress: number; // 0-100
  createdAt: string;
  lastUpdatedAt: string;
}
```

### CheckpointData

```typescript
interface CheckpointData {
  id: string;
  workflowExecutionId: string;
  sequenceNumber: number;
  type: 'automatic' | 'manual' | 'preOperation' | 'postOperation' | 'failure' | 'paused';
  workflowSnapshot: WorkflowExecution;
  contextSnapshot: ExecutionContextSnapshot;
  createdAt: string;
  completedTaskId?: string;
  nextTaskId?: string;
  reason?: string;
  metadata?: Record<string, any>;
  etag?: string;
  isRecoverable: boolean;
  expiresAt?: string;
}
```

---

## Best Practices

### 1. Workflow Design

**Use Appropriate Patterns:**
- **Sequential**: Steps must execute in order with dependencies
- **Parallel**: Independent steps that can run concurrently
- **Iterative**: Quality-focused with feedback loops
- **Dynamic**: Complex requirements where path is determined at runtime

**Design for Failure:**
```typescript
const workflow = await client.workflows.create({
  definition: {
    steps: [...],
    timeout: "01:00:00", // Set realistic timeouts
    maxRetries: 3 // Enable automatic retries
  }
});
```

**Use Checkpoints:**
Workflows automatically create checkpoints after each task. You can resume failed workflows:
```typescript
try {
  await client.workflows.execute(definition);
} catch (error) {
  // Resume from last checkpoint
  const result = await client.workflows.resume(workflowId);
}
```

### 2. Error Handling

**Implement Retry Logic:**
```typescript
async function executeWithRetry(
  request: WorkflowRequest,
  maxRetries: number = 3
): Promise<WorkflowResult> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await client.workflows.execute(request);
    } catch (error) {
      if (!isRetryableError(error) || attempt === maxRetries - 1) {
        throw error;
      }

      const delayMs = Math.min(1000 * Math.pow(2, attempt), 30000);
      await sleep(delayMs);
    }
  }
  throw new Error('Max retries exceeded');
}

function isRetryableError(error: ApiError): boolean {
  return error.status >= 500 || error.status === 429;
}
```

### 3. Real-Time Monitoring

**Subscribe Selectively:**
```typescript
// Good: Subscribe only to workflows you're actively monitoring
await connection.invoke('SubscribeToWorkflow', activeWorkflowId);

// Avoid: Don't subscribe to all workflows or high-frequency events unnecessarily
```

**Handle Reconnection:**
```typescript
connection.onreconnected(async () => {
  // Resubscribe to active workflows
  for (const id of activeWorkflowIds) {
    await connection.invoke('SubscribeToWorkflow', id);
  }

  // Fetch latest status to catch up on missed events
  const status = await client.workflows.get(id);
  updateUI(status);
});
```

### 4. Rate Limiting

**Respect Rate Limits:**
```typescript
class RateLimitedClient {
  private remaining = Infinity;
  private resetTime = 0;

  async request(method: string, path: string, body?: any) {
    // Wait if we've hit the limit
    if (this.remaining <= 0 && Date.now() < this.resetTime) {
      await sleep(this.resetTime - Date.now());
    }

    const response = await fetch(path, { method, body });

    // Update rate limit tracking
    this.remaining = parseInt(response.headers.get('X-RateLimit-Remaining') || '0');
    this.resetTime = parseInt(response.headers.get('X-RateLimit-Reset') || '0') * 1000;

    return response;
  }
}
```

### 5. Performance Optimization

**Use Parallel Workflows:**
```typescript
// Good: Run independent workflows in parallel
const [results1, results2, results3] = await Promise.all([
  client.workflows.execute(workflow1),
  client.workflows.execute(workflow2),
  client.workflows.execute(workflow3)
]);
```

**Batch Operations:**
```typescript
// Use workflow lists to monitor multiple workflows efficiently
const workflows = await client.workflows.list({
  status: 'running',
  limit: 100
});
```

---

## Migration Guide

### From v1 to v2 (Future)

Version 2 is planned for Q2 2026. Migration guide will include:
- Deprecated endpoints and replacements
- Breaking changes
- Migration timeline (12-month deprecation period)
- Automated migration tools

---

## SDK Support

Official SDKs are available for:

### TypeScript/JavaScript
```bash
npm install @agentstudio/client
```

### Python
```bash
pip install agentstudio-client
```

### .NET
```bash
dotnet add package AgentStudio.Client
```

See [SDK Documentation](https://docs.agentstudio.dev/sdks) for complete guides.

---

## OpenAPI Specification

Download the complete OpenAPI 3.1 specification:

- **Production**: https://api.agentstudio.dev/swagger/v1/swagger.json
- **Interactive Docs**: https://api.agentstudio.dev/swagger

Import into:
- Swagger Editor: https://editor.swagger.io
- Postman: File → Import → Paste OpenAPI URL
- Insomnia: Create → Import → From URL

---

## Support

### Documentation
- **API Reference**: https://docs.agentstudio.dev/api
- **Guides**: https://docs.agentstudio.dev/guides
- **Changelog**: https://docs.agentstudio.dev/changelog

### Community
- **Discord**: https://discord.gg/agentstudio
- **GitHub**: https://github.com/agentstudio/api
- **Stack Overflow**: Tag `agent-studio`

### Commercial Support
- **Email**: api-support@agentstudio.dev
- **Response Time**: 24 hours (business days)
- **Enterprise Support**: Priority support with SLA

---

## Changelog

### v1.0.0 (2025-10-08)
- Initial release
- Workflow management endpoints
- Agent execution endpoints
- SignalR real-time communication
- Checkpoint and resume functionality

---

## License

Agent Studio API is proprietary software. See [Terms of Service](https://agentstudio.dev/terms) for usage terms.
