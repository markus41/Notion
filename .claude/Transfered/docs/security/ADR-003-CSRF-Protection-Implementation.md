# ADR-003: Cross-Site Request Forgery (CSRF) Protection Implementation

**Status:** Proposed
**Date:** 2025-10-09
**Decision Maker:** Security Architecture Team
**Author:** Security Specialist Agent
**Related:** SECURITY_AUDIT_REPORT.md (Critical Finding #3), ADR-001 (Secure Token Storage)

---

## Context and Problem Statement

Agent Studio currently lacks Cross-Site Request Forgery (CSRF) protection for state-changing operations. Attackers can craft malicious websites that trigger authenticated actions (workflow execution, agent deletion, configuration changes) on behalf of logged-in users without their knowledge or consent.

**Current Implementation Risks:**
- **CVSS Score**: 8.1 (Critical)
- **OWASP Category**: A01:2021 - Broken Access Control
- **CWE**: CWE-352 (Cross-Site Request Forgery)
- **Threat Actor**: External attackers leveraging social engineering
- **Attack Vectors**:
  - Malicious websites with auto-submitting forms
  - Phishing emails with embedded attack payloads
  - Compromised third-party websites
  - Malicious browser extensions

**Business Impact:**
- **Unauthorized Workflow Execution**: Malicious agent deployments consuming Azure OpenAI quota
- **Configuration Sabotage**: Deletion of critical agents, workflow definitions
- **Resource Abuse**: Repeated expensive AI operations draining credits
- **Regulatory Non-Compliance**: OWASP Top 10, PCI-DSS Requirement 6.5.9
- **Reputation Damage**: User trust erosion from unauthorized actions

---

## Decision Drivers

1. **Security Priority**: Prevent unauthorized state-changing operations
2. **Industry Standards**: OWASP CSRF Prevention Cheat Sheet
3. **Compliance**: OWASP A01:2021, PCI-DSS 6.5.9, SOC2 CC6.1
4. **Defense in Depth**: Combine multiple CSRF protection mechanisms
5. **Developer Experience**: Minimal friction for legitimate authenticated requests
6. **Browser Compatibility**: Support modern browsers (Chrome 80+, Firefox 76+, Safari 13+)
7. **Integration**: Seamless integration with cookie-based authentication (ADR-001)

---

## Considered Options

### Option 1: No CSRF Protection (Status Quo)
**Rejected** - Unacceptable security risk

**Pros:**
- No implementation effort
- No additional request overhead

**Cons:**
- ❌ Vulnerable to CSRF attacks (CRITICAL)
- ❌ Fails OWASP Top 10 compliance
- ❌ Violates PCI-DSS Requirement 6.5.9
- ❌ Production blocker per security audit

### Option 2: SameSite Cookie Attribute Only
**Rejected** - Insufficient protection (single point of failure)

**Pros:**
- ✅ Simple implementation (already configured)
- ✅ Browser-native protection

**Cons:**
- ❌ Not supported by older browsers (Safari <12, IE 11)
- ❌ Bypassed in certain scenarios (subdomain attacks, DNS rebinding)
- ❌ Fails defense-in-depth principle
- ❌ Insufficient for PCI-DSS compliance alone

### Option 3: Synchronizer Token Pattern (Double-Submit Cookie) - RECOMMENDED
**Status:** RECOMMENDED DECISION

**Architecture:**
```
┌──────────────────────────────────────────────────────────────┐
│                    User Login Flow                            │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ↓
┌──────────────────────────────────────────────────────────────┐
│         .NET Backend - Authentication Endpoint                │
├──────────────────────────────────────────────────────────────┤
│  1. Validate credentials                                      │
│  2. Create authentication session                            │
│  3. Generate CSRF token (cryptographic random)               │
│  4. Store token in server-side session                       │
│  5. Return CSRF token in response body                       │
│  6. Set httpOnly authentication cookie                       │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ↓
┌──────────────────────────────────────────────────────────────┐
│              React Frontend - Token Storage                   │
├──────────────────────────────────────────────────────────────┤
│  1. Receive CSRF token from login response                   │
│  2. Store CSRF token in AuthContext (memory)                 │
│  3. Include token as X-CSRF-Token header in requests         │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ↓
┌──────────────────────────────────────────────────────────────┐
│       State-Changing Request (POST/PUT/DELETE/PATCH)         │
├──────────────────────────────────────────────────────────────┤
│  HTTP Headers:                                                │
│    Cookie: AgentStudio.AuthToken=<httpOnly-cookie>           │
│    X-CSRF-Token: <csrf-token-value>                          │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ↓
┌──────────────────────────────────────────────────────────────┐
│         .NET Backend - CSRF Validation Middleware             │
├──────────────────────────────────────────────────────────────┤
│  1. Extract X-CSRF-Token header                              │
│  2. Retrieve stored CSRF token from session                  │
│  3. Compare tokens (constant-time comparison)                │
│  4. Validate request if tokens match                         │
│  5. Reject with 403 Forbidden if mismatch                    │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ↓
┌──────────────────────────────────────────────────────────────┐
│              Process Request if Valid                         │
│    (Execute workflow, delete agent, update config, etc.)     │
└──────────────────────────────────────────────────────────────┘
```

**Pros:**
- ✅ Industry-standard CSRF protection (OWASP recommended)
- ✅ Server-side token validation (secure)
- ✅ Integrates seamlessly with cookie-based auth (ADR-001)
- ✅ Works across all modern browsers
- ✅ Complies with OWASP A01:2021, PCI-DSS 6.5.9
- ✅ ASP.NET Core built-in support (`AddAntiforgery`)

**Cons:**
- ⚠️ Requires backend middleware (already addressed in ADR-001)
- ⚠️ Frontend must manage CSRF token lifecycle
- ⚠️ Additional request header overhead (minimal: ~50 bytes)

### Option 4: Origin/Referer Header Validation
**Rejected** - Insufficient protection (can be bypassed)

**Pros:**
- Simple implementation (header check)
- No token management required

**Cons:**
- ❌ Referer header can be stripped by proxies/privacy tools
- ❌ Origin header not sent in all scenarios
- ❌ Insufficient for PCI-DSS compliance alone
- ⚠️ Use as defense-in-depth layer only

### Option 5: Custom Request Header (AJAX-only)
**Rejected** - Limited scope (doesn't protect form submissions)

**Pros:**
- Simple for AJAX requests
- SOP prevents cross-origin header injection

**Cons:**
- ❌ Doesn't protect traditional form submissions
- ❌ Requires JavaScript (accessibility concerns)
- ❌ Insufficient coverage for all attack vectors

---

## Decision Outcome

**Chosen Option:** **Option 3 - Synchronizer Token Pattern (Double-Submit Cookie)** with defense-in-depth enhancements

This solution provides robust CSRF protection compliant with OWASP and PCI-DSS requirements while integrating seamlessly with the cookie-based authentication architecture established in ADR-001.

---

## Implementation Specification

### Phase 1: Backend (.NET API) Implementation

#### 1.1 CSRF Token Generation & Validation

**Note:** Implementation already partially covered in ADR-001 (`AuthController.cs`). This section provides comprehensive endpoint coverage.

**File:** `services/dotnet/AgentStudio.Api/Controllers/AuthController.cs`

```csharp
// Already implemented in ADR-001
// Key methods:
// - Login: Generates and returns CSRF token
// - GetCsrfToken: Refreshes CSRF token
// - Logout: Requires CSRF validation via [ValidateAntiForgeryToken]
```

#### 1.2 Workflow Controller with CSRF Protection

**File:** `services/dotnet/AgentStudio.Api/Controllers/WorkflowController.cs`

```csharp
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Antiforgery;

namespace AgentStudio.Api.Controllers;

/// <summary>
/// Workflow management API with CSRF protection for state-changing operations.
/// Designed for: Organizations requiring secure workflow orchestration with multi-layer protection.
/// </summary>
[ApiController]
[Route("api/workflows")]
[Authorize] // Require authentication
public class WorkflowController : ControllerBase
{
    private readonly IWorkflowService _workflowService;
    private readonly ILogger<WorkflowController> _logger;

    public WorkflowController(
        IWorkflowService workflowService,
        ILogger<WorkflowController> logger)
    {
        _workflowService = workflowService;
        _logger = logger;
    }

    /// <summary>
    /// Retrieve all workflows (read-only, no CSRF required).
    /// </summary>
    [HttpGet]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetWorkflows()
    {
        var workflows = await _workflowService.GetAllWorkflowsAsync();
        return Ok(workflows);
    }

    /// <summary>
    /// Retrieve workflow by ID (read-only, no CSRF required).
    /// </summary>
    [HttpGet("{workflowId}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetWorkflow(string workflowId)
    {
        var workflow = await _workflowService.GetWorkflowByIdAsync(workflowId);

        if (workflow == null)
        {
            return NotFound(new { error = "Workflow not found" });
        }

        return Ok(workflow);
    }

    /// <summary>
    /// Execute workflow - REQUIRES CSRF PROTECTION.
    /// Best for: Preventing unauthorized workflow execution via CSRF attacks.
    /// </summary>
    [HttpPost("execute")]
    [ValidateAntiForgeryToken] // CRITICAL: CSRF protection
    [ProducesResponseType(StatusCodes.Status202Accepted)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> ExecuteWorkflow([FromBody] ExecuteWorkflowRequest request)
    {
        if (string.IsNullOrEmpty(request.WorkflowId))
        {
            return BadRequest(new { error = "WorkflowId is required" });
        }

        _logger.LogInformation(
            "User {UserId} executing workflow {WorkflowId}",
            User.FindFirstValue(ClaimTypes.NameIdentifier),
            request.WorkflowId
        );

        var executionId = await _workflowService.ExecuteWorkflowAsync(
            request.WorkflowId,
            request.ContextVariables
        );

        return Accepted(new
        {
            executionId,
            status = "Started",
            message = "Workflow execution initiated successfully"
        });
    }

    /// <summary>
    /// Create new workflow - REQUIRES CSRF PROTECTION.
    /// </summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateWorkflow([FromBody] CreateWorkflowRequest request)
    {
        var workflow = await _workflowService.CreateWorkflowAsync(request);

        _logger.LogInformation(
            "User {UserId} created workflow {WorkflowId}",
            User.FindFirstValue(ClaimTypes.NameIdentifier),
            workflow.Id
        );

        return CreatedAtAction(
            nameof(GetWorkflow),
            new { workflowId = workflow.Id },
            workflow
        );
    }

    /// <summary>
    /// Update existing workflow - REQUIRES CSRF PROTECTION.
    /// </summary>
    [HttpPut("{workflowId}")]
    [ValidateAntiForgeryToken]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateWorkflow(
        string workflowId,
        [FromBody] UpdateWorkflowRequest request)
    {
        var workflow = await _workflowService.UpdateWorkflowAsync(workflowId, request);

        if (workflow == null)
        {
            return NotFound(new { error = "Workflow not found" });
        }

        _logger.LogInformation(
            "User {UserId} updated workflow {WorkflowId}",
            User.FindFirstValue(ClaimTypes.NameIdentifier),
            workflowId
        );

        return Ok(workflow);
    }

    /// <summary>
    /// Delete workflow - REQUIRES CSRF PROTECTION (CRITICAL OPERATION).
    /// </summary>
    [HttpDelete("{workflowId}")]
    [ValidateAntiForgeryToken]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteWorkflow(string workflowId)
    {
        var deleted = await _workflowService.DeleteWorkflowAsync(workflowId);

        if (!deleted)
        {
            return NotFound(new { error = "Workflow not found" });
        }

        _logger.LogWarning(
            "User {UserId} deleted workflow {WorkflowId}",
            User.FindFirstValue(ClaimTypes.NameIdentifier),
            workflowId
        );

        return NoContent();
    }
}

// DTOs
public record ExecuteWorkflowRequest(
    string WorkflowId,
    Dictionary<string, object>? ContextVariables = null
);

public record CreateWorkflowRequest(
    string Name,
    string Description,
    string Pattern,
    List<TaskDefinition> Tasks
);

public record UpdateWorkflowRequest(
    string? Name,
    string? Description,
    List<TaskDefinition>? Tasks
);
```

#### 1.3 Agent Controller with CSRF Protection

**File:** `services/dotnet/AgentStudio.Api/Controllers/AgentController.cs`

```csharp
namespace AgentStudio.Api.Controllers;

[ApiController]
[Route("api/agents")]
[Authorize]
public class AgentController : ControllerBase
{
    private readonly IAgentService _agentService;
    private readonly ILogger<AgentController> _logger;

    public AgentController(IAgentService agentService, ILogger<AgentController> logger)
    {
        _agentService = agentService;
        _logger = logger;
    }

    // GET operations (no CSRF required)
    [HttpGet]
    public async Task<IActionResult> GetAgents() { /* ... */ }

    [HttpGet("{agentId}")]
    public async Task<IActionResult> GetAgent(string agentId) { /* ... */ }

    // State-changing operations (CSRF REQUIRED)

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CreateAgent([FromBody] CreateAgentRequest request)
    {
        var agent = await _agentService.CreateAgentAsync(request);

        _logger.LogInformation(
            "User {UserId} created agent {AgentId} of type {AgentType}",
            User.FindFirstValue(ClaimTypes.NameIdentifier),
            agent.Id,
            agent.Type
        );

        return CreatedAtAction(nameof(GetAgent), new { agentId = agent.Id }, agent);
    }

    [HttpPut("{agentId}")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateAgent(
        string agentId,
        [FromBody] UpdateAgentRequest request)
    {
        var agent = await _agentService.UpdateAgentAsync(agentId, request);

        if (agent == null)
        {
            return NotFound();
        }

        _logger.LogInformation(
            "User {UserId} updated agent {AgentId}",
            User.FindFirstValue(ClaimTypes.NameIdentifier),
            agentId
        );

        return Ok(agent);
    }

    [HttpDelete("{agentId}")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteAgent(string agentId)
    {
        var deleted = await _agentService.DeleteAgentAsync(agentId);

        if (!deleted)
        {
            return NotFound();
        }

        _logger.LogWarning(
            "User {UserId} deleted agent {AgentId}",
            User.FindFirstValue(ClaimTypes.NameIdentifier),
            agentId
        );

        return NoContent();
    }
}
```

#### 1.4 CSRF Validation Middleware Enhancement

**File:** `services/dotnet/AgentStudio.Api/Middleware/CsrfValidationMiddleware.cs`

(Already implemented in ADR-001. Enhancements below for defense-in-depth.)

```csharp
public class CsrfValidationMiddleware
{
    // ... existing implementation from ADR-001

    public async Task InvokeAsync(HttpContext context)
    {
        // Check if request requires CSRF validation
        if (RequiresCsrfValidation(context))
        {
            // Defense-in-Depth Layer 1: Validate Origin/Referer headers
            if (!ValidateOriginHeader(context))
            {
                _logger.LogWarning(
                    "CSRF: Invalid Origin/Referer header for {Method} {Path} from IP {IP}",
                    context.Request.Method,
                    context.Request.Path,
                    context.Connection.RemoteIpAddress
                );

                context.Response.StatusCode = StatusCodes.Status403Forbidden;
                await context.Response.WriteAsJsonAsync(new
                {
                    error = "Invalid request origin"
                });
                return;
            }

            // Defense-in-Depth Layer 2: Validate CSRF token
            try
            {
                await _antiforgery.ValidateRequestAsync(context);
            }
            catch (AntiforgeryValidationException ex)
            {
                _logger.LogWarning(
                    ex,
                    "CSRF validation failed for {Method} {Path} from IP: {IP}",
                    context.Request.Method,
                    context.Request.Path,
                    context.Connection.RemoteIpAddress
                );

                context.Response.StatusCode = StatusCodes.Status403Forbidden;
                await context.Response.WriteAsJsonAsync(new
                {
                    error = "CSRF validation failed",
                    message = "Invalid or missing CSRF token"
                });
                return;
            }
        }

        await _next(context);
    }

    /// <summary>
    /// Defense-in-depth: Validate Origin/Referer headers match expected domain.
    /// </summary>
    private bool ValidateOriginHeader(HttpContext context)
    {
        var origin = context.Request.Headers["Origin"].FirstOrDefault();
        var referer = context.Request.Headers["Referer"].FirstOrDefault();

        // Get allowed origins from configuration
        var allowedOrigins = context.RequestServices
            .GetRequiredService<IConfiguration>()
            .GetSection("Cors:AllowedOrigins")
            .Get<string[]>() ?? Array.Empty<string>();

        // Validate Origin header (preferred)
        if (!string.IsNullOrEmpty(origin))
        {
            return allowedOrigins.Any(allowed =>
                origin.Equals(allowed, StringComparison.OrdinalIgnoreCase));
        }

        // Fallback to Referer header validation
        if (!string.IsNullOrEmpty(referer))
        {
            var refererUri = new Uri(referer);
            var refererOrigin = $"{refererUri.Scheme}://{refererUri.Authority}";

            return allowedOrigins.Any(allowed =>
                refererOrigin.Equals(allowed, StringComparison.OrdinalIgnoreCase));
        }

        // No Origin or Referer header (suspicious, but allow if CSRF token valid)
        _logger.LogWarning(
            "Request missing Origin and Referer headers: {Method} {Path}",
            context.Request.Method,
            context.Request.Path
        );

        return true; // Continue to CSRF token validation
    }

    // ... rest of existing implementation
}
```

---

### Phase 2: Frontend (React) Implementation

#### 2.1 CSRF Token Management in AuthContext

**File:** `webapp/src/contexts/AuthContext.tsx`

(Already implemented in ADR-001. Key additions below for token refresh.)

```typescript
export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [csrfToken, setCsrfToken] = useState<string | null>(null);

  // ... existing implementation

  /**
   * Refresh CSRF token (called after token expiration or on 403 errors).
   */
  const refreshCsrfToken = useCallback(async () => {
    try {
      const response = await fetch('/api/auth/csrf-token', {
        credentials: 'include',
      });

      if (response.ok) {
        const { csrfToken } = await response.json();
        setCsrfToken(csrfToken);
        return csrfToken;
      } else {
        throw new Error('Failed to refresh CSRF token');
      }
    } catch (err) {
      console.error('CSRF token refresh failed:', err);
      throw err;
    }
  }, []);

  // Listen for CSRF validation failures and refresh token
  useEffect(() => {
    const handleCsrfFailure = async () => {
      try {
        await refreshCsrfToken();
      } catch (err) {
        console.error('CSRF token refresh failed, logging out:', err);
        await logout();
      }
    };

    window.addEventListener('auth:forbidden', handleCsrfFailure);

    return () => {
      window.removeEventListener('auth:forbidden', handleCsrfFailure);
    };
  }, [refreshCsrfToken, logout]);

  const value: AuthContextValue = {
    user,
    isAuthenticated,
    isLoading,
    error,
    csrfToken,
    login,
    logout,
    refreshSession,
    refreshCsrfToken, // Expose for manual refresh if needed
    hasRole,
    hasAnyRole,
    canAccess,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
```

#### 2.2 BaseApiClient CSRF Token Injection

(Already implemented in ADR-001. Verification below.)

```typescript
export abstract class BaseApiClient {
  // ... existing implementation

  private setupInterceptors(): void {
    this.axios.interceptors.request.use(
      (config) => {
        // Add CSRF token for state-changing requests
        const csrfToken = this.csrfTokenProvider();
        if (csrfToken && ['POST', 'PUT', 'DELETE', 'PATCH'].includes(config.method?.toUpperCase() || '')) {
          config.headers['X-CSRF-Token'] = csrfToken;
        }

        // ... rest of implementation
        return config;
      },
      (error) => {
        return Promise.reject(error);
      }
    );

    // ... response interceptor handles 403 errors and triggers CSRF refresh
  }
}
```

#### 2.3 Workflow API Client Example

**File:** `webapp/src/api/clients/WorkflowClient.ts`

```typescript
import { BaseApiClient, ApiClientConfig } from './BaseApiClient';

/**
 * Workflow API client with CSRF-protected state-changing operations.
 * Designed for: Secure workflow execution with multi-layer attack protection.
 */
export class WorkflowClient extends BaseApiClient {
  constructor(csrfTokenProvider: () => string | null) {
    const config: ApiClientConfig = {
      timeout: 60000, // Workflow execution may be long-running
      retry: {
        maxRetries: 3,
        retryDelay: 2000,
      },
      csrfTokenProvider,
    };

    super(import.meta.env.VITE_API_BASE_URL || '/api', config);
  }

  /**
   * Execute workflow with CSRF protection.
   */
  async executeWorkflow(
    workflowId: string,
    contextVariables?: Record<string, any>
  ): Promise<{ executionId: string; status: string }> {
    const response = await this.axios.post('/workflows/execute', {
      workflowId,
      contextVariables,
    });

    return response.data;
  }

  /**
   * Create new workflow with CSRF protection.
   */
  async createWorkflow(workflow: {
    name: string;
    description: string;
    pattern: string;
    tasks: any[];
  }): Promise<Workflow> {
    const response = await this.axios.post('/workflows', workflow);
    return response.data;
  }

  /**
   * Update workflow with CSRF protection.
   */
  async updateWorkflow(workflowId: string, updates: Partial<Workflow>): Promise<Workflow> {
    const response = await this.axios.put(`/workflows/${workflowId}`, updates);
    return response.data;
  }

  /**
   * Delete workflow with CSRF protection (CRITICAL OPERATION).
   */
  async deleteWorkflow(workflowId: string): Promise<void> {
    await this.axios.delete(`/workflows/${workflowId}`);
  }

  /**
   * Get all workflows (read-only, no CSRF required).
   */
  async getWorkflows(): Promise<Workflow[]> {
    const response = await this.axios.get('/workflows');
    return response.data;
  }
}

// Initialize with CSRF token provider
export const workflowClient = new WorkflowClient(() => {
  const authContext = (window as any).__AUTH_CONTEXT__;
  return authContext?.csrfToken || null;
});
```

---

## Security Controls

### Defense-in-Depth Layers

| Layer | Control | Threat Mitigated | Strength |
|-------|---------|------------------|----------|
| **Layer 1** | SameSite=Strict cookie attribute | Cross-origin cookie transmission | ✅ HIGH - Browser-native |
| **Layer 2** | Origin/Referer header validation | Cross-origin requests | ✅ MEDIUM - Defense-in-depth |
| **Layer 3** | CSRF token (Synchronizer pattern) | Forged state-changing requests | ✅ CRITICAL - Primary defense |
| **Layer 4** | HTTPS enforcement | Token interception | ✅ HIGH - Transport security |
| **Layer 5** | Session timeout | Stale token usage | ✅ MEDIUM - Time-bound validity |

### CSRF Token Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│  1. LOGIN: Generate CSRF Token                              │
│     - Cryptographically random (256-bit)                    │
│     - Stored server-side in session                         │
│     - Returned to client in response body                   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  2. CLIENT STORAGE: Store in AuthContext                    │
│     - React state (memory-based, not localStorage)          │
│     - Cleared on logout or session timeout                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  3. REQUEST: Include in X-CSRF-Token Header                 │
│     - Automatically added by BaseApiClient                  │
│     - Only for POST/PUT/DELETE/PATCH requests               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  4. VALIDATION: Server-side Token Comparison                │
│     - Retrieve token from session                           │
│     - Compare with X-CSRF-Token header (constant-time)      │
│     - Reject if mismatch (403 Forbidden)                    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  5. REFRESH: On Token Expiration or 403 Error               │
│     - Call /api/auth/csrf-token endpoint                    │
│     - Update token in AuthContext                           │
│     - Retry failed request with new token                   │
└─────────────────────────────────────────────────────────────┘
```

---

## Testing & Validation

### CSRF Test Plan

**Test Case 1: Legitimate State-Changing Request**
```javascript
// User executes workflow with valid CSRF token
const response = await fetch('/api/workflows/execute', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': validCsrfToken,
  },
  credentials: 'include',
  body: JSON.stringify({ workflowId: 'test-workflow' }),
});
```
**Expected Result:** ✅ 202 Accepted (workflow execution started)

**Test Case 2: CSRF Attack Simulation (No Token)**
```html
<!-- Malicious website: attacker.com -->
<form action="https://agentstudio.com/api/workflows/execute" method="POST">
  <input type="hidden" name="workflowId" value="malicious-workflow" />
</form>
<script>document.forms[0].submit();</script>
```
**Expected Result:** ✅ 403 Forbidden (CSRF token missing)

**Test Case 3: CSRF Attack with Stolen/Invalid Token**
```bash
curl -X POST https://agentstudio.com/api/workflows/execute \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: invalid-or-stolen-token" \
  -b "AgentStudio.AuthToken=<valid-cookie>" \
  -d '{"workflowId":"malicious"}'
```
**Expected Result:** ✅ 403 Forbidden (CSRF token validation failed)

**Test Case 4: Read-Only Request (No CSRF Required)**
```javascript
const response = await fetch('/api/workflows', {
  method: 'GET',
  credentials: 'include',
});
```
**Expected Result:** ✅ 200 OK (no CSRF token required for GET)

**Test Case 5: CSRF Token Refresh After Expiration**
```javascript
// Simulate token expiration
const oldToken = csrfToken;

// Attempt request with expired token
try {
  await workflowClient.deleteWorkflow('test-id');
} catch (error) {
  // Should trigger automatic token refresh
}

// Verify new token obtained
expect(csrfToken).not.toBe(oldToken);
```
**Expected Result:** ✅ Token refreshed automatically, request succeeds

**Test Case 6: Cross-Origin Request Blocking**
```javascript
// Attacker's website attempting to execute workflow
fetch('https://agentstudio.com/api/workflows/execute', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': 'any-value', // Attacker cannot obtain valid token
  },
  credentials: 'include', // Attempt to send victim's cookies
  body: JSON.stringify({ workflowId: 'malicious' }),
});
```
**Expected Result:** ✅ Blocked by CORS policy (preflight fails) + 403 Forbidden (invalid Origin header)

### Automated Testing

```typescript
// webapp/src/__tests__/csrf-protection.test.ts
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { workflowClient } from '../api/clients/WorkflowClient';

describe('CSRF Protection', () => {
  let mockCsrfToken: string;

  beforeEach(() => {
    mockCsrfToken = 'test-csrf-token-123';
    (window as any).__AUTH_CONTEXT__ = { csrfToken: mockCsrfToken };
  });

  it('should include CSRF token in POST requests', async () => {
    const interceptor = vi.fn((config) => {
      expect(config.headers['X-CSRF-Token']).toBe(mockCsrfToken);
      return config;
    });

    workflowClient.axios.interceptors.request.use(interceptor);

    try {
      await workflowClient.executeWorkflow('test-workflow');
    } catch {
      // Ignore network errors in test
    }

    expect(interceptor).toHaveBeenCalled();
  });

  it('should NOT include CSRF token in GET requests', async () => {
    const interceptor = vi.fn((config) => {
      expect(config.headers['X-CSRF-Token']).toBeUndefined();
      return config;
    });

    workflowClient.axios.interceptors.request.use(interceptor);

    try {
      await workflowClient.getWorkflows();
    } catch {
      // Ignore network errors in test
    }

    expect(interceptor).toHaveBeenCalled();
  });

  it('should refresh CSRF token on 403 Forbidden', async () => {
    const refreshSpy = vi.fn();
    (window as any).__AUTH_CONTEXT__.refreshCsrfToken = refreshSpy;

    // Simulate 403 error
    window.dispatchEvent(new CustomEvent('auth:forbidden'));

    expect(refreshSpy).toHaveBeenCalled();
  });
});
```

---

## Monitoring & Observability

### CSRF Metrics

```csharp
// Track CSRF validation failures
_metrics.IncrementCounter(
    "csrf.validation.failures",
    new Dictionary<string, object>
    {
        { "endpoint", context.Request.Path },
        { "method", context.Request.Method },
        { "user_id", context.User.FindFirstValue(ClaimTypes.NameIdentifier) }
    }
);
```

### Alerts

- **Critical**: CSRF validation failures > 10/min per user (potential attack)
- **Warning**: CSRF validation failures > 50/hour globally (misconfiguration or attack)
- **Info**: CSRF token refresh rate spike (>2x baseline)

### Dashboard Queries (Application Insights)

```kusto
// CSRF validation failures by endpoint
traces
| where message contains "CSRF validation failed"
| extend endpoint = extract("Path: ([^ ]+)", 1, message)
| summarize failures = count() by endpoint
| top 10 by failures desc

// CSRF validation failures by user
traces
| where message contains "CSRF validation failed"
| extend userId = extract("User: ([^ ]+)", 1, message)
| summarize failures = count() by userId
| where failures > 5 // Users with >5 failures
| top 10 by failures desc
```

---

## Compliance Mapping

| Requirement | Control | Verification |
|------------|---------|--------------|
| **OWASP A01:2021** (Broken Access Control) | CSRF token validation for state-changing ops | ✅ [ValidateAntiForgeryToken] attribute |
| **PCI-DSS 6.5.9** (CSRF Protection) | Synchronizer token pattern | ✅ ASP.NET Core antiforgery |
| **CWE-352** (CSRF) | Multi-layer CSRF defense | ✅ Token + SameSite + Origin validation |
| **SOC2 CC6.1** (Logical Access) | Prevent unauthorized state changes | ✅ CSRF + authentication required |

---

## Residual Risks

| Risk | Severity | Mitigation | Acceptance |
|------|----------|------------|------------|
| **CSRF Token Leakage in Logs** | Low | Sanitize logs, exclude CSRF tokens | ✅ Mitigated |
| **Subdomain CSRF (if future subdomains added)** | Low | Strict cookie domain configuration | ✅ Monitored |
| **User Confusion (Token Refresh)** | Low | Automatic refresh, clear error messages | ✅ Accepted |
| **Browser Extensions Injecting Tokens** | Low | User education, CSP protection | ✅ Accepted |

---

## References

- [OWASP CSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)
- [CWE-352: Cross-Site Request Forgery](https://cwe.mitre.org/data/definitions/352.html)
- [ASP.NET Core Antiforgery Documentation](https://learn.microsoft.com/en-us/aspnet/core/security/anti-request-forgery)
- [OWASP A01:2021 - Broken Access Control](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)

---

**Document Classification:** Internal - Security Architecture
**Contact:** Consultations@BrooksideBI.com | +1 209 487 2047
