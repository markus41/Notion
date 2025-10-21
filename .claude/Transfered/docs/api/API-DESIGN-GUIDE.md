# Agent Studio API Design Guide

## Table of Contents

1. [Error Handling Patterns](#error-handling-patterns)
2. [API Versioning Strategy](#api-versioning-strategy)
3. [Authentication & Authorization](#authentication--authorization)
4. [Rate Limiting & Throttling](#rate-limiting--throttling)
5. [gRPC vs REST Evaluation](#grpc-vs-rest-evaluation)
6. [Performance Optimization](#performance-optimization)
7. [Security Best Practices](#security-best-practices)
8. [Monitoring & Observability](#monitoring--observability)

---

## Error Handling Patterns

### RFC 7807 Problem Details Standard

All APIs use RFC 7807 Problem Details for JSON format for consistent error responses.

#### Error Response Structure

```json
{
  "type": "https://api.agentstudio.dev/errors/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "The 'agent_id' field is required and must be a valid agent identifier",
  "instance": "/v1/tasks",
  "errors": [
    {
      "field": "agent_id",
      "message": "Agent ID is required",
      "code": "REQUIRED_FIELD"
    },
    {
      "field": "timeout_seconds",
      "message": "Timeout must be between 1 and 3600 seconds",
      "code": "OUT_OF_RANGE",
      "provided_value": "5000"
    }
  ],
  "trace_id": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
}
```

### Error Code Taxonomy

#### Top-Level Error Categories

| Category | HTTP Status | Description |
|----------|-------------|-------------|
| `validation-error` | 400/422 | Request validation failed |
| `authentication-error` | 401 | Authentication failed or missing |
| `authorization-error` | 403 | Insufficient permissions |
| `not-found` | 404 | Resource not found |
| `conflict` | 409 | Resource state conflict |
| `rate-limit-exceeded` | 429 | Too many requests |
| `internal-error` | 500 | Internal server error |
| `service-unavailable` | 503 | Service temporarily unavailable |

#### Application-Specific Error Codes

**Namespace Pattern**: `CATEGORY_SPECIFIC_ERROR`

```typescript
// Task Errors
const TASK_NOT_FOUND = "TASK_NOT_FOUND";
const TASK_ALREADY_COMPLETED = "TASK_ALREADY_COMPLETED";
const TASK_CANCELLED = "TASK_CANCELLED";
const TASK_TIMEOUT = "TASK_TIMEOUT";

// Agent Errors
const AGENT_NOT_FOUND = "AGENT_NOT_FOUND";
const AGENT_OFFLINE = "AGENT_OFFLINE";
const AGENT_OVERLOADED = "AGENT_OVERLOADED";
const AGENT_MISSING_CAPABILITY = "AGENT_MISSING_CAPABILITY";

// Workflow Errors
const WORKFLOW_INVALID = "WORKFLOW_INVALID";
const WORKFLOW_VALIDATION_FAILED = "WORKFLOW_VALIDATION_FAILED";
const WORKFLOW_CIRCULAR_DEPENDENCY = "WORKFLOW_CIRCULAR_DEPENDENCY";

// Input Errors
const INVALID_INPUT = "INVALID_INPUT";
const REQUIRED_FIELD = "REQUIRED_FIELD";
const OUT_OF_RANGE = "OUT_OF_RANGE";
const INVALID_FORMAT = "INVALID_FORMAT";

// External Errors
const EXTERNAL_API_ERROR = "EXTERNAL_API_ERROR";
const RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED";
const NETWORK_ERROR = "NETWORK_ERROR";
```

### Error Classification

#### Transient Errors (Retryable)

- Network timeouts
- Service temporarily unavailable (503)
- Rate limits (429)
- Temporary agent unavailability

**Response Pattern**:
```json
{
  "type": "https://api.agentstudio.dev/errors/transient",
  "title": "Service Temporarily Unavailable",
  "status": 503,
  "detail": "The agent is temporarily unavailable. Please retry after the specified delay.",
  "retry_after_seconds": 60,
  "retryable": true
}
```

#### Permanent Errors (Non-Retryable)

- Validation errors (400, 422)
- Authentication errors (401)
- Not found errors (404)
- Business logic violations

**Response Pattern**:
```json
{
  "type": "https://api.agentstudio.dev/errors/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "The provided input does not meet validation requirements",
  "retryable": false,
  "errors": [...]
}
```

### Client Error Handling Strategy

```typescript
class ApiClient {
  async executeWithRetry<T>(
    request: () => Promise<T>,
    maxRetries = 3
  ): Promise<T> {
    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await request();
      } catch (error) {
        if (!this.isRetryable(error) || attempt === maxRetries) {
          throw error;
        }

        const delay = this.calculateBackoff(error, attempt);
        await this.delay(delay);
      }
    }
    throw new Error('Max retries exceeded');
  }

  private isRetryable(error: ApiError): boolean {
    // Check if error is marked as retryable
    if (error.retryable !== undefined) {
      return error.retryable;
    }

    // Fallback to status code check
    const retryableStatuses = [408, 429, 500, 502, 503, 504];
    return retryableStatuses.includes(error.status);
  }

  private calculateBackoff(error: ApiError, attempt: number): number {
    // Use Retry-After header if available
    if (error.retry_after_seconds) {
      return error.retry_after_seconds * 1000;
    }

    // Exponential backoff with jitter
    const baseDelay = 1000; // 1 second
    const maxDelay = 60000; // 60 seconds
    const exponentialDelay = baseDelay * Math.pow(2, attempt);
    const jitter = Math.random() * 1000;

    return Math.min(exponentialDelay + jitter, maxDelay);
  }
}
```

---

## API Versioning Strategy

### Versioning Approach

**Primary Strategy**: URL Path Versioning

- **Format**: `/v{major}/resource`
- **Example**: `/v1/tasks`, `/v2/workflows`
- **Rationale**: Clear, explicit, easy to route and cache

### Version Lifecycle

#### Version States

1. **Preview** (`/preview/resource`): Experimental features, breaking changes possible
2. **Current** (`/v1/resource`): Stable, production-ready
3. **Deprecated** (`/v1/resource` with `Sunset` header): Still supported, migration recommended
4. **Retired**: No longer available

#### Deprecation Timeline

```
Version Release
      ↓
  6 months → Deprecation Announcement (Sunset header added)
      ↓
  6 months → Deprecation Notice Period (warnings in responses)
      ↓
  6 months → Version Retirement (returns 410 Gone)
```

### Backward Compatibility Rules

#### Safe Changes (No Version Bump)

- Adding new optional fields to requests
- Adding new fields to responses
- Adding new endpoints
- Adding new enum values (with default handling)
- Making required fields optional

#### Breaking Changes (Version Bump Required)

- Removing or renaming fields
- Changing field types
- Changing validation rules (more restrictive)
- Removing endpoints
- Changing authentication requirements
- Changing error response formats

### Version Negotiation

#### Request Headers

```http
GET /v1/tasks HTTP/1.1
Host: api.agentstudio.dev
Accept: application/json
API-Version: 1.0
```

#### Response Headers

```http
HTTP/1.1 200 OK
API-Version: 1.0
Sunset: Sat, 31 Dec 2025 23:59:59 GMT
Link: </v2/tasks>; rel="successor-version"
Deprecation: true
```

### Migration Guides

Each major version includes:

1. **Migration Documentation**: Detailed guide for upgrading
2. **Changelog**: List of breaking and non-breaking changes
3. **Code Examples**: Before/after comparisons
4. **Automated Migration Tools**: Scripts to assist migration
5. **Parallel Running Period**: Support for both versions simultaneously

#### Example Migration Guide Structure

```markdown
# Migration Guide: v1 to v2

## Breaking Changes

### 1. Task Status Enum Changed

**v1**:
```json
{ "status": "done" }
```

**v2**:
```json
{ "status": "completed" }
```

**Migration**: Replace `done` with `completed` in all task status checks.

## New Features

### 1. Batch Task Execution

v2 introduces batch execution endpoints...

## Deprecated Features

### 1. Synchronous Task Execution

The `/v1/tasks/execute-sync` endpoint is deprecated...
```

---

## Authentication & Authorization

### Authentication Mechanisms

#### 1. JWT Bearer Tokens (Primary)

**Use Case**: User authentication, frontend-to-backend

**Token Structure**:
```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT",
    "kid": "key-2025-01"
  },
  "payload": {
    "iss": "https://auth.agentstudio.dev",
    "sub": "user_12345",
    "aud": "https://api.agentstudio.dev",
    "exp": 1735689600,
    "iat": 1735686000,
    "name": "Jane Doe",
    "email": "jane.doe@example.com",
    "roles": ["admin", "workflow_editor"],
    "scopes": [
      "workflows:read",
      "workflows:write",
      "tasks:read",
      "tasks:execute"
    ]
  }
}
```

**Request Example**:
```http
POST /v1/tasks HTTP/1.1
Host: api.agentstudio.dev
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
```

**Token Lifecycle**:
- **Access Token**: 15-60 minutes
- **Refresh Token**: 7-30 days
- **Refresh Endpoint**: `POST /auth/refresh`

#### 2. API Keys (Secondary)

**Use Case**: Service-to-service authentication, agents, automation

**Key Format**: `ask_live_1234567890abcdef` (prefix indicates environment and type)

**Request Example**:
```http
POST /v1/tasks HTTP/1.1
Host: api.agentstudio.dev
X-API-Key: ask_live_1234567890abcdef
Content-Type: application/json
```

**Key Management**:
- Generate keys via Dashboard or API
- Support for multiple keys per service
- Key rotation policies
- Automatic expiration after configurable period
- Rate limiting per key

### Authorization Model

#### Role-Based Access Control (RBAC)

**Roles**:

| Role | Description | Permissions |
|------|-------------|-------------|
| `viewer` | Read-only access | `*:read` |
| `executor` | Can execute workflows | `*:read`, `tasks:execute`, `workflows:execute` |
| `editor` | Can create/edit workflows | `*:read`, `*:write` (excluding settings) |
| `admin` | Full system access | `*:*` |

#### Scope-Based Permissions

**Scope Format**: `resource:action`

**Examples**:
```
workflows:read          # Read workflows
workflows:write         # Create/update workflows
workflows:delete        # Delete workflows
workflows:execute       # Execute workflows
tasks:read              # Read tasks
tasks:execute           # Execute tasks
tasks:cancel            # Cancel tasks
agents:read             # Read agent info
agents:write            # Configure agents
agents:delete           # Unregister agents
settings:read           # Read settings
settings:write          # Update settings
```

#### Resource-Level Authorization

**Ownership Model**: Users can only access resources they own or have been granted access to.

```csharp
// Example authorization check
public async Task<Workflow> GetWorkflow(string workflowId, ClaimsPrincipal user)
{
    var workflow = await _repository.GetWorkflow(workflowId);

    if (workflow == null)
        throw new NotFoundException("Workflow not found");

    // Check ownership or shared access
    if (!await _authzService.CanAccessWorkflow(user, workflow))
        throw new ForbiddenException("You do not have access to this workflow");

    return workflow;
}
```

### OAuth 2.0 Flows

#### Authorization Code Flow (with PKCE)

**Recommended For**: Web applications, mobile apps

```
1. Client initiates auth: GET /oauth/authorize?
   response_type=code&
   client_id=CLIENT_ID&
   redirect_uri=CALLBACK_URL&
   scope=workflows:read workflows:write&
   state=RANDOM_STATE&
   code_challenge=CHALLENGE&
   code_challenge_method=S256

2. User authenticates and authorizes

3. Callback: GET callback_url?code=AUTH_CODE&state=RANDOM_STATE

4. Exchange code for token: POST /oauth/token
   {
     "grant_type": "authorization_code",
     "code": "AUTH_CODE",
     "redirect_uri": "CALLBACK_URL",
     "client_id": "CLIENT_ID",
     "code_verifier": "VERIFIER"
   }

5. Response:
   {
     "access_token": "...",
     "refresh_token": "...",
     "expires_in": 3600,
     "token_type": "Bearer"
   }
```

#### Client Credentials Flow

**Recommended For**: Service-to-service communication

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&
client_id=SERVICE_CLIENT_ID&
client_secret=SERVICE_CLIENT_SECRET&
scope=tasks:execute agents:read
```

### Security Best Practices

1. **Always use HTTPS** in production
2. **Validate JWT signatures** using public key rotation
3. **Implement token revocation** via blacklist or short expiration
4. **Use PKCE** for all public clients (web, mobile)
5. **Rate limit authentication endpoints** to prevent brute force
6. **Log authentication events** for audit trails
7. **Rotate API keys** every 90 days
8. **Never log tokens** or credentials

---

## Rate Limiting & Throttling

### Rate Limiting Strategy

#### Per-User Limits

| Tier | Requests/Minute | Requests/Hour | Requests/Day |
|------|----------------|---------------|--------------|
| Free | 60 | 1,000 | 10,000 |
| Pro | 600 | 10,000 | 100,000 |
| Enterprise | 3,000 | 100,000 | Unlimited |

#### Per-Endpoint Limits

| Endpoint Type | Limit | Window |
|---------------|-------|--------|
| Read Operations (GET) | 100/min | 1 minute |
| Write Operations (POST/PUT/PATCH) | 30/min | 1 minute |
| Delete Operations | 10/min | 1 minute |
| Task Execution | 20/min | 1 minute |
| Webhook Callbacks | 1000/min | 1 minute |

### Rate Limiting Algorithm

**Token Bucket Algorithm** (Recommended)

```csharp
public class TokenBucketRateLimiter
{
    private readonly int _capacity;
    private readonly int _refillRate; // tokens per second
    private int _tokens;
    private DateTime _lastRefill;

    public async Task<bool> TryConsumeAsync(int tokensRequired = 1)
    {
        await RefillBucketAsync();

        if (_tokens >= tokensRequired)
        {
            _tokens -= tokensRequired;
            return true;
        }

        return false;
    }

    private async Task RefillBucketAsync()
    {
        var now = DateTime.UtcNow;
        var elapsed = (now - _lastRefill).TotalSeconds;
        var tokensToAdd = (int)(elapsed * _refillRate);

        _tokens = Math.Min(_capacity, _tokens + tokensToAdd);
        _lastRefill = now;
    }
}
```

### Rate Limit Headers

**Response Headers** (all requests):

```http
HTTP/1.1 200 OK
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 42
X-RateLimit-Reset: 1735689600
X-RateLimit-Policy: 60;w=60
```

**429 Response** (rate limit exceeded):

```http
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1735689600
Retry-After: 45
Content-Type: application/json

{
  "type": "https://api.agentstudio.dev/errors/rate-limit-exceeded",
  "title": "Rate Limit Exceeded",
  "status": 429,
  "detail": "You have exceeded the rate limit of 60 requests per minute",
  "retry_after_seconds": 45,
  "limit": 60,
  "window_seconds": 60
}
```

### Throttling Strategies

#### 1. Request Queuing

For burst traffic, queue requests instead of rejecting immediately.

```typescript
class ThrottledQueue {
  private queue: Array<() => Promise<any>> = [];
  private processing = false;

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
    if (this.processing || this.queue.length === 0) return;

    this.processing = true;

    while (this.queue.length > 0) {
      const task = this.queue.shift()!;
      await task();
      await this.delay(100); // 100ms between requests
    }

    this.processing = false;
  }
}
```

#### 2. Adaptive Rate Limiting

Adjust limits based on system load.

```csharp
public class AdaptiveRateLimiter
{
    public int CalculateLimit(SystemMetrics metrics)
    {
        var baseLimit = 100;
        var loadFactor = 1.0;

        // Reduce limit under high load
        if (metrics.CpuUsagePercent > 80)
            loadFactor *= 0.5;
        else if (metrics.CpuUsagePercent > 60)
            loadFactor *= 0.75;

        // Reduce limit under memory pressure
        if (metrics.MemoryUsagePercent > 80)
            loadFactor *= 0.5;

        return (int)(baseLimit * loadFactor);
    }
}
```

#### 3. Fair Queuing

Prevent one user from monopolizing resources.

```python
class FairQueue:
    def __init__(self):
        self.user_queues = {}
        self.round_robin_index = 0

    def dequeue(self):
        # Round-robin across user queues
        non_empty_queues = [q for q in self.user_queues.values() if q]

        if not non_empty_queues:
            return None

        queue = non_empty_queues[self.round_robin_index % len(non_empty_queues)]
        self.round_robin_index += 1

        return queue.pop(0)
```

### Cost-Based Rate Limiting

Different operations have different costs:

```typescript
const OPERATION_COSTS = {
  'GET /tasks': 1,
  'POST /tasks': 5,
  'POST /workflows/execute': 10,
  'GET /analytics/summary': 20,
};

async function consumeTokens(operation: string): Promise<boolean> {
  const cost = OPERATION_COSTS[operation] || 1;
  return await rateLimiter.tryConsume(cost);
}
```

---

## gRPC vs REST Evaluation

### Decision Matrix

| Criteria | REST | gRPC | Winner |
|----------|------|------|--------|
| **Browser Compatibility** | ✅ Native | ⚠️ Requires grpc-web | REST |
| **Performance (Latency)** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | gRPC |
| **Performance (Throughput)** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | gRPC |
| **Streaming Support** | ⚠️ Limited | ✅ Native | gRPC |
| **Binary Efficiency** | ⭐⭐ (JSON) | ⭐⭐⭐⭐⭐ (Protobuf) | gRPC |
| **Developer Tooling** | ✅ Excellent | ✅ Good | Tie |
| **Debugging** | ✅ Easy (curl, Postman) | ⚠️ Harder | REST |
| **Schema Validation** | ⚠️ OpenAPI (optional) | ✅ Protobuf (required) | gRPC |
| **Learning Curve** | ✅ Low | ⚠️ Moderate | REST |
| **Caching** | ✅ HTTP cache | ❌ Limited | REST |
| **Load Balancing** | ✅ L7 widely supported | ⚠️ Requires L7 | REST |

### Recommendation by Use Case

#### Use REST for:

1. **Frontend ↔ Backend** (React → .NET API)
   - Browser-native support
   - Easy debugging with DevTools
   - HTTP caching benefits
   - HATEOAS for discoverability

2. **Public APIs**
   - Wider compatibility
   - Better documentation tools (Swagger)
   - Familiar to developers

3. **Request-Response Patterns**
   - CRUD operations
   - Simple queries
   - Occasional API calls

#### Use gRPC for:

1. **Orchestrator ↔ Agents** (Control Plane)
   - High throughput (thousands of tasks/sec)
   - Low latency critical
   - Strong typing required
   - Binary efficiency matters

2. **Agent ↔ Orchestrator** (Callbacks)
   - High-frequency updates (progress, logs)
   - Streaming support needed
   - Structured data with versioning

3. **Service-to-Service** Communication
   - Microservices architecture
   - Internal APIs
   - Performance-critical paths

### Hybrid Architecture (Recommended)

```
┌─────────────────────────────────────────────────────────┐
│                      React Frontend                      │
└────────────────────┬────────────────────────────────────┘
                     │ REST API (OpenAPI)
                     │ + SignalR (WebSocket)
                     ↓
┌─────────────────────────────────────────────────────────┐
│                   .NET Orchestrator                      │
└─────────┬──────────────────────────────────┬────────────┘
          │ gRPC (Control Plane)             │ gRPC (Callbacks)
          ↓                                  ↑
┌─────────────────────────────────────────────────────────┐
│                    Python Agents                         │
└─────────────────────────────────────────────────────────┘
```

**Benefits**:
- REST for frontend (best browser support)
- gRPC for internal services (best performance)
- SignalR for real-time updates (best for browser push)

### Implementation Strategy

#### Phase 1: REST First (MVP)

Start with REST APIs for all communication:

```
Frontend ─REST─> Orchestrator ─REST─> Agents
                       ↑               │
                       └───REST Callbacks
```

**Pros**: Faster to implement, easier to debug

#### Phase 2: gRPC for Control Plane

Migrate high-traffic internal APIs to gRPC:

```
Frontend ─REST─> Orchestrator ─gRPC─> Agents
                       ↑               │
                       └───REST Callbacks
```

**Pros**: Improved performance where it matters most

#### Phase 3: gRPC for Callbacks (Optional)

If callback volume is high, migrate to gRPC:

```
Frontend ─REST─> Orchestrator ─gRPC─> Agents
                       ↑               │
                       └───gRPC Callbacks
```

**Pros**: Full performance optimization

### gRPC Implementation Example

**Service Definition** (from message-schemas.proto):

```protobuf
service AgentControlService {
  rpc ExecuteTask(TaskRequest) returns (TaskResponse);
  rpc GetTaskStatus(TaskStatusRequest) returns (TaskDetail);
  rpc StreamTaskLogs(TaskLogsRequest) returns (stream LogMessage);
}
```

**Server Implementation (.NET)**:

```csharp
public class AgentControlService : AgentControl.AgentControlBase
{
    public override async Task<TaskResponse> ExecuteTask(
        TaskRequest request,
        ServerCallContext context)
    {
        // Execute task
        var task = await _orchestrator.ExecuteTaskAsync(request);

        return new TaskResponse
        {
            TaskId = task.Id,
            Status = TaskStatus.Queued,
            AgentId = request.AgentId,
            CreatedAt = Timestamp.FromDateTime(task.CreatedAt)
        };
    }

    public override async Task StreamTaskLogs(
        TaskLogsRequest request,
        IServerStreamWriter<LogMessage> responseStream,
        ServerCallContext context)
    {
        await foreach (var log in _logStream.GetLogsAsync(request.TaskId))
        {
            await responseStream.WriteAsync(new LogMessage
            {
                TaskId = request.TaskId,
                Timestamp = Timestamp.FromDateTime(log.Timestamp),
                Level = log.Level,
                Message = log.Message
            });
        }
    }
}
```

**Client Implementation (Python)**:

```python
import grpc
from agentstudio.v1 import agent_control_pb2, agent_control_pb2_grpc

class AgentControlClient:
    def __init__(self, address: str):
        self.channel = grpc.insecure_channel(address)
        self.stub = agent_control_pb2_grpc.AgentControlServiceStub(self.channel)

    async def execute_task(self, task_request):
        response = await self.stub.ExecuteTask(task_request)
        return response

    async def stream_logs(self, task_id: str):
        request = agent_control_pb2.TaskLogsRequest(task_id=task_id, follow=True)

        async for log in self.stub.StreamTaskLogs(request):
            print(f"[{log.level}] {log.message}")
```

---

## Performance Optimization

### HTTP/2 and HTTP/3

- **Enable HTTP/2**: Multiplexing, header compression
- **Consider HTTP/3**: QUIC protocol for better mobile performance

### Compression

```http
# Request
Accept-Encoding: gzip, br

# Response
Content-Encoding: br
Vary: Accept-Encoding
```

**Compression Thresholds**:
- Enable for responses > 1KB
- Skip for already-compressed content (images, video)
- Use Brotli (br) for static content
- Use gzip for dynamic content

### Caching Strategy

#### HTTP Caching Headers

```http
# Immutable resources
Cache-Control: public, max-age=31536000, immutable

# Frequently updated resources
Cache-Control: public, max-age=300, must-revalidate
ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"

# Private resources
Cache-Control: private, max-age=60

# No caching
Cache-Control: no-store
```

#### CDN Strategy

- Serve OpenAPI specs via CDN
- Cache public agent/workflow metadata
- Use geo-distributed edge locations

### Database Optimization

```csharp
// Use projection to select only needed fields
var workflows = await _context.Workflows
    .Where(w => w.Status == WorkflowStatus.Active)
    .Select(w => new WorkflowSummary
    {
        Id = w.Id,
        Name = w.Name,
        Status = w.Status
    })
    .ToListAsync();

// Use AsNoTracking for read-only queries
var workflow = await _context.Workflows
    .AsNoTracking()
    .FirstOrDefaultAsync(w => w.Id == workflowId);

// Batch operations
await _context.BulkInsertAsync(tasks);
```

---

## Security Best Practices

### Input Validation

```csharp
public class TaskRequestValidator : AbstractValidator<TaskRequest>
{
    public TaskRequestValidator()
    {
        RuleFor(x => x.AgentId)
            .NotEmpty()
            .MaximumLength(100)
            .Matches("^[a-zA-Z0-9-]+$");

        RuleFor(x => x.TaskType)
            .NotEmpty()
            .Must(BeValidTaskType);

        RuleFor(x => x.TimeoutSeconds)
            .InclusiveBetween(1, 3600);
    }
}
```

### SQL Injection Prevention

```csharp
// ✅ Good: Parameterized query
var workflow = await _context.Workflows
    .Where(w => w.Id == workflowId)
    .FirstOrDefaultAsync();

// ❌ Bad: String concatenation
var sql = $"SELECT * FROM Workflows WHERE Id = '{workflowId}'";
```

### CORS Configuration

```csharp
services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", builder =>
    {
        builder.WithOrigins("https://app.agentstudio.dev")
               .AllowAnyMethod()
               .AllowAnyHeader()
               .AllowCredentials();
    });
});
```

### Content Security Policy

```http
Content-Security-Policy: default-src 'self';
  script-src 'self' 'unsafe-inline' 'unsafe-eval';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  font-src 'self' data:;
  connect-src 'self' https://api.agentstudio.dev wss://api.agentstudio.dev;
```

---

## Monitoring & Observability

### OpenTelemetry Integration

**Trace All Requests**:

```csharp
using var activity = _activitySource.StartActivity("ExecuteTask");
activity?.SetTag("task.id", taskId);
activity?.SetTag("agent.id", agentId);

try
{
    var result = await ExecuteTaskAsync(request);
    activity?.SetStatus(ActivityStatusCode.Ok);
    return result;
}
catch (Exception ex)
{
    activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
    activity?.RecordException(ex);
    throw;
}
```

### Metrics Collection

```csharp
// Counter: Total requests
_meter.CreateCounter<long>("api.requests.total")
    .Add(1, new KeyValuePair<string, object>("endpoint", "/v1/tasks"));

// Histogram: Request duration
_meter.CreateHistogram<double>("api.request.duration")
    .Record(elapsedMs, new KeyValuePair<string, object>("endpoint", "/v1/tasks"));

// Gauge: Active connections
_meter.CreateObservableGauge("api.connections.active", () => _activeConnections);
```

### Logging Standards

```json
{
  "timestamp": "2025-10-07T10:30:00.123Z",
  "level": "info",
  "message": "Task execution started",
  "task_id": "task_xyz789",
  "agent_id": "analyst-agent-01",
  "workflow_id": "wf_abc123",
  "trace_id": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01",
  "span_id": "00f067aa0ba902b7",
  "user_id": "user_12345"
}
```

### Health Check Endpoints

```csharp
app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        var result = JsonSerializer.Serialize(new
        {
            status = report.Status.ToString(),
            checks = report.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString(),
                description = e.Value.Description,
                duration = e.Value.Duration.TotalMilliseconds
            })
        });
        await context.Response.WriteAsync(result);
    }
});
```

---

## Summary

This API design guide provides production-ready patterns for:

1. **Error Handling**: RFC 7807 compliance, retryable classification
2. **Versioning**: URL-based with 18-month deprecation cycle
3. **Authentication**: JWT + API keys with OAuth 2.0 flows
4. **Rate Limiting**: Token bucket with adaptive throttling
5. **gRPC vs REST**: Hybrid approach for optimal performance
6. **Security**: Input validation, SQL injection prevention, CORS
7. **Observability**: OpenTelemetry tracing, metrics, structured logging

**Recommended Architecture**:
- **React ↔ .NET**: REST + SignalR
- **.NET ↔ Python**: gRPC (with REST fallback for MVP)
- **Public APIs**: REST with OpenAPI
- **Real-time**: SignalR WebSocket

This design balances developer experience, performance, and maintainability.
