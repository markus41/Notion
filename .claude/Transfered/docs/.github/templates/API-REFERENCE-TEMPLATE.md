---
title: "[API Name] Reference"
description: "Complete API specification for [feature], designed to enable [business outcome]"
audience: [developer]
version: "2.0"
openapi_spec: "/api/specs/[api-name]-openapi.yaml"
authentication: "Bearer token (Azure AD)"
rate_limits: "100 requests/minute per tenant"
base_url: "https://api.agentstudio.io/v2"
last_updated: "2025-10-14"
tags: [api, rest, reference]
related_docs:
  - "/guides/developer/integration-guide"
  - "/architecture/api-architecture"
---

# [API Name] Reference

> **Best for:** Organizations building programmatic integrations with Agent Studio to automate [workflow/process]

## Overview

The [API Name] enables you to [primary capability], designed to streamline [workflow] and improve [business outcome]. This API is built on RESTful principles with JSON request/response formats.

**Key Capabilities:**
- **[Capability 1]:** [Description and benefit]
- **[Capability 2]:** [Description and benefit]
- **[Capability 3]:** [Description and benefit]

::: tip Business Value
Establish automated workflows by integrating the [API Name] with your existing systems, designed to reduce manual intervention and improve operational efficiency.
:::

---

## Getting Started

### Base URL

```
https://api.agentstudio.io/v2
```

**Regional Endpoints:**
- North America: `https://na.api.agentstudio.io/v2`
- Europe: `https://eu.api.agentstudio.io/v2`
- Asia Pacific: `https://ap.api.agentstudio.io/v2`

### Authentication

All API requests require authentication using Azure AD Bearer tokens:

```bash
# Obtain access token
curl -X POST https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id={client-id}" \
  -d "client_secret={client-secret}" \
  -d "scope=https://api.agentstudio.io/.default" \
  -d "grant_type=client_credentials"
```

**Response:**
```json
{
  "token_type": "Bearer",
  "expires_in": 3600,
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6..."
}
```

**Using the Token:**
```bash
curl -X GET https://api.agentstudio.io/v2/[endpoint] \
  -H "Authorization: Bearer {access-token}" \
  -H "Content-Type: application/json"
```

::: warning Token Expiration
Access tokens expire after 1 hour. Implement token refresh logic to ensure uninterrupted API access.
:::

### Rate Limiting

| Tier | Requests per Minute | Requests per Hour | Burst Limit |
|------|--------------------|--------------------|-------------|
| Free | 10 | 500 | 20 |
| Standard | 100 | 5,000 | 200 |
| Premium | 1,000 | 50,000 | 2,000 |
| Enterprise | Custom | Custom | Custom |

**Rate Limit Headers:**
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1735689600
```

**Rate Limit Exceeded Response:**
```json
{
  "error": {
    "code": "rate_limit_exceeded",
    "message": "Rate limit exceeded. Retry after 45 seconds.",
    "retry_after": 45
  }
}
```

---

## Common Patterns

### Pagination

List endpoints support cursor-based pagination:

**Request:**
```bash
GET /v2/[resource]?limit=50&cursor={next-cursor}
```

**Response:**
```json
{
  "data": [ /* items */ ],
  "pagination": {
    "limit": 50,
    "has_more": true,
    "next_cursor": "eyJpZCI6MTIzNDU2fQ=="
  }
}
```

**Implementation:**
```typescript
// Establish paginated data retrieval to streamline large dataset processing
async function* fetchAllItems() {
  let cursor: string | null = null;

  do {
    const params = new URLSearchParams({ limit: '100' });
    if (cursor) params.set('cursor', cursor);

    const response = await fetch(`/v2/[resource]?${params}`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });

    const data = await response.json();
    yield* data.data;

    cursor = data.pagination.has_more ? data.pagination.next_cursor : null;
  } while (cursor);
}
```

### Filtering and Sorting

**Filtering:**
```bash
GET /v2/[resource]?filter[status]=active&filter[created_after]=2025-01-01
```

**Sorting:**
```bash
GET /v2/[resource]?sort=-created_at,name
```

**Supported Filter Operators:**
- `eq`: Equals (default)
- `ne`: Not equals
- `gt`: Greater than
- `gte`: Greater than or equal
- `lt`: Less than
- `lte`: Less than or equal
- `in`: In array
- `contains`: Contains substring

### Error Handling

All errors follow RFC 7807 (Problem Details):

```json
{
  "type": "https://docs.agentstudio.io/errors/validation-error",
  "title": "Validation Error",
  "status": 400,
  "detail": "The request body contains invalid fields",
  "instance": "/v2/workflows/abc123",
  "errors": [
    {
      "field": "tasks[0].agent",
      "message": "Agent 'invalid-agent' does not exist",
      "code": "invalid_reference"
    }
  ],
  "request_id": "req_1234567890"
}
```

**Standard Error Codes:**

| Status | Code | Description |
|--------|------|-------------|
| 400 | `validation_error` | Request validation failed |
| 401 | `authentication_required` | Missing or invalid authentication |
| 403 | `forbidden` | Insufficient permissions |
| 404 | `not_found` | Resource not found |
| 409 | `conflict` | Resource state conflict |
| 429 | `rate_limit_exceeded` | Rate limit exceeded |
| 500 | `internal_error` | Server error |
| 503 | `service_unavailable` | Service temporarily unavailable |

**Error Handling Implementation:**
```typescript
// Establish robust error handling to improve reliability
async function apiRequest(endpoint: string, options: RequestInit) {
  try {
    const response = await fetch(endpoint, options);

    if (!response.ok) {
      const error = await response.json();
      throw new ApiError(error);
    }

    return await response.json();
  } catch (error) {
    if (error instanceof ApiError) {
      console.error(`API Error [${error.status}]:`, error.detail);

      // Implement retry logic for transient errors
      if (error.status === 429 || error.status >= 500) {
        return retryWithBackoff(() => apiRequest(endpoint, options));
      }

      throw error;
    }

    throw new NetworkError('Failed to connect to API');
  }
}
```

---

## API Endpoints

### [Resource 1] Endpoints

#### List [Resources]

Retrieve a paginated list of [resources].

**Endpoint:**
```
GET /v2/[resources]
```

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `limit` | integer | No | Number of items per page (1-100, default: 50) |
| `cursor` | string | No | Pagination cursor |
| `filter[field]` | string | No | Filter by field value |
| `sort` | string | No | Sort order (e.g., `-created_at,name`) |

**Request Example:**
```bash
curl -X GET "https://api.agentstudio.io/v2/[resources]?limit=20&filter[status]=active" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json"
```

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": "res_1234567890",
      "name": "Example Resource",
      "status": "active",
      "created_at": "2025-01-15T10:30:00Z",
      "updated_at": "2025-01-15T10:30:00Z",
      "metadata": {
        "custom_field": "value"
      }
    }
  ],
  "pagination": {
    "limit": 20,
    "has_more": false,
    "next_cursor": null
  }
}
```

**Response Schema:**
```typescript
interface ListResourcesResponse {
  data: Resource[];
  pagination: {
    limit: number;
    has_more: boolean;
    next_cursor: string | null;
  };
}

interface Resource {
  id: string;                    // Unique resource identifier
  name: string;                  // Resource name
  status: 'active' | 'inactive' | 'archived';
  created_at: string;            // ISO 8601 timestamp
  updated_at: string;            // ISO 8601 timestamp
  metadata: Record<string, any>; // Custom metadata
}
```

---

#### Create [Resource]

Create a new [resource] instance.

**Endpoint:**
```
POST /v2/[resources]
```

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Resource name (3-100 characters) |
| `description` | string | No | Resource description (max 500 characters) |
| `metadata` | object | No | Custom metadata key-value pairs |

**Request Example:**
```bash
curl -X POST "https://api.agentstudio.io/v2/[resources]" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Production Workflow",
    "description": "Automated deployment workflow for production environment",
    "metadata": {
      "environment": "production",
      "team": "platform-engineering"
    }
  }'
```

**Response:** `201 Created`
```json
{
  "id": "res_1234567890",
  "name": "Production Workflow",
  "description": "Automated deployment workflow for production environment",
  "status": "active",
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z",
  "metadata": {
    "environment": "production",
    "team": "platform-engineering"
  }
}
```

**Error Responses:**

`400 Bad Request` - Validation error
```json
{
  "type": "https://docs.agentstudio.io/errors/validation-error",
  "title": "Validation Error",
  "status": 400,
  "detail": "The request body contains invalid fields",
  "errors": [
    {
      "field": "name",
      "message": "Name must be at least 3 characters",
      "code": "min_length"
    }
  ]
}
```

---

#### Retrieve [Resource]

Retrieve a specific [resource] by ID.

**Endpoint:**
```
GET /v2/[resources]/{id}
```

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Resource identifier |

**Request Example:**
```bash
curl -X GET "https://api.agentstudio.io/v2/[resources]/res_1234567890" \
  -H "Authorization: Bearer {token}"
```

**Response:** `200 OK`
```json
{
  "id": "res_1234567890",
  "name": "Production Workflow",
  "description": "Automated deployment workflow",
  "status": "active",
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z"
}
```

**Error Responses:**

`404 Not Found`
```json
{
  "type": "https://docs.agentstudio.io/errors/not-found",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "The requested resource does not exist",
  "instance": "/v2/[resources]/res_invalid"
}
```

---

#### Update [Resource]

Update an existing [resource].

**Endpoint:**
```
PATCH /v2/[resources]/{id}
```

**Request Body:** (All fields optional)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Updated resource name |
| `description` | string | Updated description |
| `status` | string | Updated status (active, inactive, archived) |
| `metadata` | object | Partial metadata update (merged with existing) |

**Request Example:**
```bash
curl -X PATCH "https://api.agentstudio.io/v2/[resources]/res_1234567890" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "inactive",
    "metadata": {
      "archived_reason": "Replaced by new workflow"
    }
  }'
```

**Response:** `200 OK`
```json
{
  "id": "res_1234567890",
  "name": "Production Workflow",
  "status": "inactive",
  "updated_at": "2025-01-16T14:20:00Z",
  "metadata": {
    "environment": "production",
    "team": "platform-engineering",
    "archived_reason": "Replaced by new workflow"
  }
}
```

---

#### Delete [Resource]

Delete a [resource] permanently.

**Endpoint:**
```
DELETE /v2/[resources]/{id}
```

**Request Example:**
```bash
curl -X DELETE "https://api.agentstudio.io/v2/[resources]/res_1234567890" \
  -H "Authorization: Bearer {token}"
```

**Response:** `204 No Content`

**Error Responses:**

`409 Conflict` - Resource cannot be deleted
```json
{
  "type": "https://docs.agentstudio.io/errors/conflict",
  "title": "Conflict",
  "status": 409,
  "detail": "Cannot delete resource with active dependencies",
  "errors": [
    {
      "code": "active_dependencies",
      "message": "Resource has 3 active child resources"
    }
  ]
}
```

---

## Webhooks

Subscribe to real-time events via webhooks.

### Webhook Events

| Event | Description |
|-------|-------------|
| `[resource].created` | Fired when a resource is created |
| `[resource].updated` | Fired when a resource is updated |
| `[resource].deleted` | Fired when a resource is deleted |
| `[resource].status_changed` | Fired when resource status changes |

### Webhook Payload

```json
{
  "id": "evt_1234567890",
  "type": "[resource].created",
  "created_at": "2025-01-15T10:30:00Z",
  "data": {
    "object": {
      "id": "res_1234567890",
      "name": "Production Workflow",
      "status": "active"
    },
    "previous": null
  }
}
```

### Webhook Security

Verify webhook authenticity using HMAC signatures:

```typescript
// Establish webhook signature verification to ensure secure event processing
import crypto from 'crypto';

function verifyWebhookSignature(
  payload: string,
  signature: string,
  secret: string
): boolean {
  const hmac = crypto.createHmac('sha256', secret);
  const expectedSignature = hmac.update(payload).digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}

// Express middleware example
app.post('/webhooks', (req, res) => {
  const signature = req.headers['x-agentstudio-signature'];
  const isValid = verifyWebhookSignature(
    JSON.stringify(req.body),
    signature,
    process.env.WEBHOOK_SECRET
  );

  if (!isValid) {
    return res.status(401).json({ error: 'Invalid signature' });
  }

  // Process webhook event
  const event = req.body;
  console.log(`Received ${event.type}:`, event.data);

  res.status(200).json({ received: true });
});
```

---

## SDK and Client Libraries

### Official SDKs

#### TypeScript/JavaScript
```bash
npm install @agentstudio/api-client
```

```typescript
import { AgentStudioClient } from '@agentstudio/api-client';

const client = new AgentStudioClient({
  apiKey: process.env.AGENT_STUDIO_API_KEY,
  baseUrl: 'https://api.agentstudio.io/v2'
});

// List resources
const resources = await client.resources.list({
  limit: 50,
  filter: { status: 'active' }
});

// Create resource
const newResource = await client.resources.create({
  name: 'My Workflow',
  metadata: { env: 'production' }
});
```

#### Python
```bash
pip install agentstudio-api
```

```python
from agentstudio import AgentStudioClient

client = AgentStudioClient(
    api_key=os.getenv('AGENT_STUDIO_API_KEY'),
    base_url='https://api.agentstudio.io/v2'
)

# List resources
resources = client.resources.list(limit=50, filter={'status': 'active'})

# Create resource
new_resource = client.resources.create(
    name='My Workflow',
    metadata={'env': 'production'}
)
```

---

## OpenAPI Specification

Download the complete OpenAPI 3.0 specification:

- [OpenAPI YAML](/api/specs/[api-name]-openapi.yaml)
- [OpenAPI JSON](/api/specs/[api-name]-openapi.json)
- [Interactive API Explorer](/api/explorer)

---

## Best Practices

### Authentication
- ✅ Rotate API keys regularly (every 90 days)
- ✅ Store credentials in secure vaults (Azure Key Vault)
- ✅ Implement token refresh logic
- ✅ Use least-privilege access policies

### Error Handling
- ✅ Implement exponential backoff for retries
- ✅ Log request IDs for debugging
- ✅ Handle rate limits gracefully
- ✅ Validate request payloads before sending

### Performance
- ✅ Use pagination for large result sets
- ✅ Implement response caching where appropriate
- ✅ Batch operations when possible
- ✅ Monitor API latency and optimize

---

## Changelog

### Version 2.0 (2025-01-15)
- Added cursor-based pagination
- Introduced webhook event subscriptions
- Enhanced error response format (RFC 7807)
- Added regional endpoints

### Version 1.5 (2024-11-01)
- Added filtering and sorting
- Improved rate limiting headers
- Added metadata support

---

## Additional Resources

- [Integration Guide](/guides/developer/api-integration)
- [Authentication Guide](/guides/developer/authentication)
- [API Changelog](/api/changelog)
- [Status Page](https://status.agentstudio.io)
- [Support](mailto:support@agentstudio.io)

---

**Last Updated:** 2025-10-14 | **Version:** 2.0 | **API Stability:** Stable
