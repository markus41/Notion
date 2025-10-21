# Meta-Agents REST API Reference

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [Base URL](#base-url)
- [Common Headers](#common-headers)
- [Error Handling](#error-handling)
- [Agents API](#agents-api)
- [Workflows API](#workflows-api)
- [Executions API](#executions-api)
- [Tools API](#tools-api)
- [Rate Limiting](#rate-limiting)

## Overview

The Meta-Agents API provides programmatic access to the Agent Studio platform for creating, managing, and executing AI agent workflows.

**API Version**: v1
**Protocol**: REST over HTTPS
**Data Format**: JSON
**Authentication**: OAuth 2.0 (Azure AD)

## Authentication

All API requests require authentication using Azure AD OAuth 2.0.

### Obtaining an Access Token

```bash
# Client credentials flow (service-to-service)
curl -X POST https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id={client-id}" \
  -d "client_secret={client-secret}" \
  -d "scope=api://agentstudio/.default" \
  -d "grant_type=client_credentials"
```

### Using the Access Token

```bash
curl -X GET https://api.agentstudio.com/api/v1/agents \
  -H "Authorization: Bearer {access-token}"
```

### Token Expiration

- Access tokens expire after 1 hour
- Refresh tokens before expiration for continuous access
- Implement token refresh logic in your client

## Base URL

| Environment | Base URL |
|-------------|----------|
| Production  | `https://api.agentstudio.com` |
| Staging     | `https://api-staging.agentstudio.com` |
| Development | `https://api-dev.agentstudio.com` |
| Local       | `http://localhost:5000` |

## Common Headers

All requests should include:

```http
Content-Type: application/json
Authorization: Bearer {access-token}
X-Correlation-ID: {uuid}  # Optional, for request tracing
Accept: application/json
```

## Error Handling

### Error Response Format

```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.1",
  "title": "One or more validation errors occurred.",
  "status": 400,
  "traceId": "00-a1b2c3d4e5f6-0123456789ab-01",
  "errors": {
    "name": ["The name field is required."],
    "type": ["Invalid agent type."]
  }
}
```

### HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request succeeded |
| 201 | Created | Resource created successfully |
| 202 | Accepted | Request accepted for async processing |
| 400 | Bad Request | Invalid request parameters |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource conflict (duplicate name, etc.) |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | Service temporarily unavailable |

## Agents API

### List Agents

Retrieve a list of all agents.

**Endpoint**: `GET /api/v1/agents`

**Query Parameters**:
```
page         integer  Page number (default: 1)
pageSize     integer  Items per page (default: 20, max: 100)
type         string   Filter by agent type
status       string   Filter by status (active, inactive)
search       string   Search by name or description
sortBy       string   Sort field (name, created_at, updated_at)
sortOrder    string   Sort order (asc, desc)
```

**Example Request**:
```bash
GET /api/v1/agents?page=1&pageSize=20&type=code_review&status=active
```

**Example Response** (200 OK):
```json
{
  "data": [
    {
      "id": "agent-12345",
      "name": "Code Review Agent",
      "description": "Automatically reviews pull requests for code quality",
      "type": "code_review",
      "status": "active",
      "configuration": {
        "model": "gpt-4",
        "temperature": 0.3,
        "max_tokens": 3000
      },
      "capabilities": [
        "code_analysis",
        "security_scanning",
        "best_practices"
      ],
      "created_at": "2025-10-01T10:30:00Z",
      "updated_at": "2025-10-05T14:22:00Z",
      "created_by": "user-789",
      "tags": ["pr-review", "automated"]
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalItems": 45,
    "totalPages": 3
  }
}
```

### Get Agent

Retrieve a specific agent by ID.

**Endpoint**: `GET /api/v1/agents/{agentId}`

**Path Parameters**:
- `agentId` (string, required): Agent identifier

**Example Request**:
```bash
GET /api/v1/agents/agent-12345
```

**Example Response** (200 OK):
```json
{
  "id": "agent-12345",
  "name": "Code Review Agent",
  "description": "Automatically reviews pull requests for code quality",
  "type": "code_review",
  "status": "active",
  "configuration": {
    "model": "gpt-4",
    "temperature": 0.3,
    "max_tokens": 3000,
    "system_prompt": "You are an expert code reviewer...",
    "tools": ["git", "linter", "security_scanner"]
  },
  "capabilities": [
    "code_analysis",
    "security_scanning",
    "best_practices"
  ],
  "metadata": {
    "version": "1.2.0",
    "author": "team@example.com"
  },
  "created_at": "2025-10-01T10:30:00Z",
  "updated_at": "2025-10-05T14:22:00Z",
  "created_by": "user-789"
}
```

### Create Agent

Create a new agent.

**Endpoint**: `POST /api/v1/agents`

**Request Body**:
```json
{
  "name": "Documentation Agent",
  "description": "Generates technical documentation from code",
  "type": "documentation",
  "status": "active",
  "configuration": {
    "model": "gpt-4",
    "temperature": 0.5,
    "max_tokens": 4000,
    "system_prompt": "You are a technical documentation expert...",
    "tools": ["file_reader", "markdown_generator"]
  },
  "capabilities": [
    "code_analysis",
    "documentation_generation",
    "api_documentation"
  ],
  "tags": ["docs", "automated"]
}
```

**Example Response** (201 Created):
```json
{
  "id": "agent-67890",
  "name": "Documentation Agent",
  "description": "Generates technical documentation from code",
  "type": "documentation",
  "status": "active",
  "configuration": {
    "model": "gpt-4",
    "temperature": 0.5,
    "max_tokens": 4000
  },
  "created_at": "2025-10-07T09:15:00Z",
  "created_by": "user-789"
}
```

### Update Agent

Update an existing agent.

**Endpoint**: `PUT /api/v1/agents/{agentId}`

**Path Parameters**:
- `agentId` (string, required): Agent identifier

**Request Body**: Same as Create Agent (partial updates supported)

**Example Response** (200 OK): Returns updated agent object

### Delete Agent

Delete an agent.

**Endpoint**: `DELETE /api/v1/agents/{agentId}`

**Path Parameters**:
- `agentId` (string, required): Agent identifier

**Example Response** (204 No Content)

### Execute Agent

Execute an agent with specific parameters.

**Endpoint**: `POST /api/v1/agents/{agentId}/execute`

**Path Parameters**:
- `agentId` (string, required): Agent identifier

**Request Body**:
```json
{
  "parameters": {
    "repository": "org/repo",
    "pull_request": 123,
    "focus_areas": ["security", "performance"]
  },
  "context": {
    "user_id": "user-789",
    "custom_data": {}
  },
  "timeout": 300
}
```

**Example Response** (202 Accepted):
```json
{
  "execution_id": "exec-abc123",
  "agent_id": "agent-12345",
  "status": "queued",
  "created_at": "2025-10-07T10:00:00Z",
  "estimated_completion": "2025-10-07T10:05:00Z"
}
```

## Workflows API

### List Workflows

**Endpoint**: `GET /api/v1/workflows`

**Query Parameters**: Same as List Agents

**Example Response** (200 OK):
```json
{
  "data": [
    {
      "id": "workflow-123",
      "name": "PR Review Pipeline",
      "description": "Complete PR review workflow",
      "type": "sequential",
      "version": "1.0.0",
      "steps": [
        {
          "id": "step-1",
          "name": "Analyze Code",
          "agent_id": "agent-analyzer",
          "order": 1
        },
        {
          "id": "step-2",
          "name": "Security Scan",
          "agent_id": "agent-security",
          "order": 2
        }
      ],
      "created_at": "2025-10-01T08:00:00Z",
      "updated_at": "2025-10-06T12:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalItems": 12,
    "totalPages": 1
  }
}
```

### Get Workflow

**Endpoint**: `GET /api/v1/workflows/{workflowId}`

**Example Response** (200 OK):
```json
{
  "id": "workflow-123",
  "name": "PR Review Pipeline",
  "description": "Complete PR review workflow",
  "type": "sequential",
  "version": "1.0.0",
  "steps": [
    {
      "id": "step-1",
      "name": "Analyze Code",
      "agent_id": "agent-analyzer",
      "agent_type": "code_analysis",
      "order": 1,
      "input_mapping": {
        "code": "$.input.files",
        "language": "$.input.language"
      },
      "output_mapping": {
        "analysis_result": "$.output"
      },
      "timeout": 300,
      "retry_policy": {
        "max_retries": 3,
        "backoff_multiplier": 2
      }
    },
    {
      "id": "step-2",
      "name": "Security Scan",
      "agent_id": "agent-security",
      "agent_type": "security",
      "order": 2,
      "input_mapping": {
        "code": "$.input.files",
        "previous_analysis": "$.steps.step-1.output"
      }
    }
  ],
  "error_handling": {
    "strategy": "retry_with_backoff",
    "max_retries": 3
  },
  "monitoring": {
    "telemetry_enabled": true,
    "trace_sampling": 1.0
  },
  "created_at": "2025-10-01T08:00:00Z",
  "created_by": "user-789"
}
```

### Create Workflow

**Endpoint**: `POST /api/v1/workflows`

**Request Body**:
```json
{
  "name": "Data Processing Pipeline",
  "description": "Sequential data analysis and validation",
  "type": "sequential",
  "version": "1.0.0",
  "steps": [
    {
      "name": "Analyze Data",
      "agent_id": "agent-analyzer",
      "order": 1,
      "input_mapping": {
        "data": "$.input.data"
      }
    },
    {
      "name": "Validate Results",
      "agent_id": "agent-validator",
      "order": 2,
      "input_mapping": {
        "data": "$.steps.step-1.output"
      }
    }
  ],
  "error_handling": {
    "strategy": "retry_with_backoff",
    "max_retries": 3
  }
}
```

**Example Response** (201 Created): Returns created workflow object

### Update Workflow

**Endpoint**: `PUT /api/v1/workflows/{workflowId}`

**Example Response** (200 OK): Returns updated workflow object

### Delete Workflow

**Endpoint**: `DELETE /api/v1/workflows/{workflowId}`

**Example Response** (204 No Content)

### Execute Workflow

**Endpoint**: `POST /api/v1/workflows/{workflowId}/execute`

**Request Body**:
```json
{
  "parameters": {
    "data": {
      "file_path": "s3://bucket/data.csv",
      "format": "csv"
    },
    "options": {
      "validate": true,
      "save_intermediate": true
    }
  },
  "context": {
    "user_id": "user-789",
    "organization_id": "org-456"
  }
}
```

**Example Response** (202 Accepted):
```json
{
  "execution_id": "exec-xyz789",
  "workflow_id": "workflow-123",
  "status": "running",
  "started_at": "2025-10-07T11:00:00Z",
  "estimated_completion": "2025-10-07T11:10:00Z",
  "progress": {
    "current_step": 1,
    "total_steps": 5,
    "percentage": 20
  }
}
```

## Executions API

### List Executions

**Endpoint**: `GET /api/v1/executions`

**Query Parameters**:
```
workflow_id  string   Filter by workflow ID
status       string   Filter by status (running, completed, failed)
from         datetime Start date filter
to           datetime End date filter
page         integer  Page number
pageSize     integer  Items per page
```

**Example Response** (200 OK):
```json
{
  "data": [
    {
      "id": "exec-xyz789",
      "workflow_id": "workflow-123",
      "status": "completed",
      "started_at": "2025-10-07T11:00:00Z",
      "completed_at": "2025-10-07T11:08:30Z",
      "duration": 510.5,
      "steps_completed": 5,
      "steps_failed": 0,
      "result_summary": {
        "status": "success",
        "findings": 12,
        "issues": 3
      }
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalItems": 156,
    "totalPages": 8
  }
}
```

### Get Execution

**Endpoint**: `GET /api/v1/executions/{executionId}`

**Example Response** (200 OK):
```json
{
  "id": "exec-xyz789",
  "workflow_id": "workflow-123",
  "workflow_name": "PR Review Pipeline",
  "status": "completed",
  "started_at": "2025-10-07T11:00:00Z",
  "completed_at": "2025-10-07T11:08:30Z",
  "duration": 510.5,
  "steps": [
    {
      "step_id": "step-1",
      "step_name": "Analyze Code",
      "agent_id": "agent-analyzer",
      "status": "completed",
      "started_at": "2025-10-07T11:00:00Z",
      "completed_at": "2025-10-07T11:03:00Z",
      "duration": 180.0,
      "result": {
        "analysis": {
          "complexity": "medium",
          "issues": 5
        }
      }
    },
    {
      "step_id": "step-2",
      "step_name": "Security Scan",
      "agent_id": "agent-security",
      "status": "completed",
      "started_at": "2025-10-07T11:03:00Z",
      "completed_at": "2025-10-07T11:08:30Z",
      "duration": 330.5,
      "result": {
        "vulnerabilities": []
      }
    }
  ],
  "final_result": {
    "status": "approved",
    "issues": 5,
    "critical_issues": 0,
    "recommendation": "Merge with minor fixes"
  },
  "metadata": {
    "total_tokens": 15000,
    "total_cost": 0.45,
    "user_id": "user-789"
  }
}
```

### Get Execution Status

**Endpoint**: `GET /api/v1/executions/{executionId}/status`

**Example Response** (200 OK):
```json
{
  "execution_id": "exec-xyz789",
  "status": "running",
  "progress": {
    "current_step": 3,
    "total_steps": 5,
    "percentage": 60,
    "current_step_name": "Validate Results"
  },
  "elapsed_time": 180.5,
  "estimated_remaining": 120.0
}
```

### Cancel Execution

**Endpoint**: `POST /api/v1/executions/{executionId}/cancel`

**Example Response** (200 OK):
```json
{
  "execution_id": "exec-xyz789",
  "status": "cancelled",
  "cancelled_at": "2025-10-07T11:05:00Z"
}
```

### Get Execution Logs

**Endpoint**: `GET /api/v1/executions/{executionId}/logs`

**Query Parameters**:
```
level       string   Filter by log level (info, warning, error)
from        datetime Start timestamp
to          datetime End timestamp
```

**Example Response** (200 OK):
```json
{
  "execution_id": "exec-xyz789",
  "logs": [
    {
      "timestamp": "2025-10-07T11:00:05Z",
      "level": "info",
      "message": "Starting step: Analyze Code",
      "step_id": "step-1",
      "metadata": {}
    },
    {
      "timestamp": "2025-10-07T11:02:30Z",
      "level": "warning",
      "message": "High complexity detected in function calculateMetrics()",
      "step_id": "step-1",
      "metadata": {
        "file": "src/metrics.ts",
        "line": 45
      }
    }
  ]
}
```

## Tools API

### List Tools

**Endpoint**: `GET /api/v1/tools`

**Example Response** (200 OK):
```json
{
  "data": [
    {
      "id": "tool-git",
      "name": "Git Integration",
      "description": "Access Git repositories and perform operations",
      "category": "version_control",
      "capabilities": ["clone", "diff", "blame"],
      "input_schema": {
        "type": "object",
        "properties": {
          "repository": { "type": "string" },
          "operation": { "type": "string", "enum": ["clone", "diff"] }
        }
      }
    }
  ]
}
```

### Execute Tool

**Endpoint**: `POST /api/v1/tools/{toolId}/execute`

**Request Body**:
```json
{
  "parameters": {
    "repository": "https://github.com/org/repo",
    "operation": "diff",
    "base": "main",
    "head": "feature-branch"
  }
}
```

**Example Response** (200 OK):
```json
{
  "tool_id": "tool-git",
  "status": "completed",
  "result": {
    "diff": "...",
    "files_changed": 5,
    "insertions": 120,
    "deletions": 45
  },
  "execution_time": 2.5
}
```

## Rate Limiting

### Rate Limit Headers

All API responses include rate limit information:

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 998
X-RateLimit-Reset: 1696684800
```

### Rate Limits by Tier

| Tier | Requests/Hour | Concurrent Executions |
|------|---------------|----------------------|
| Free | 100 | 1 |
| Basic | 1,000 | 5 |
| Pro | 10,000 | 20 |
| Enterprise | Custom | Custom |

### Rate Limit Exceeded Response

```json
{
  "type": "https://tools.ietf.org/html/rfc6585#section-4",
  "title": "Rate limit exceeded",
  "status": 429,
  "detail": "API rate limit exceeded. Retry after 300 seconds.",
  "retry_after": 300
}
```

---

**Related Documentation**:
- [SignalR Hubs API](SIGNALR_HUBS.md)
- [Python Agents API](PYTHON_AGENTS_API.md)
- [API Examples](EXAMPLES.md)
- [Authentication Guide](../guides/authentication.md)

**Last Updated**: 2025-10-07
**API Version**: 1.0.0
