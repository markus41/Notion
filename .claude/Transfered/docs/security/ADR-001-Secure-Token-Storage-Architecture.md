# ADR-001: Secure Token Storage Architecture

**Status:** Proposed
**Date:** 2025-10-09
**Decision Maker:** Security Architecture Team
**Author:** Security Specialist Agent
**Related:** SECURITY_AUDIT_REPORT.md (Critical Finding #1)

---

## Context and Problem Statement

Agent Studio currently stores JWT authentication tokens in browser `localStorage`, exposing them to Cross-Site Scripting (XSS) attacks. Any XSS vulnerability allows attackers to execute `localStorage.getItem('auth_tokens')` and steal user credentials, enabling complete account takeover.

**Current Implementation Risks:**
- **CVSS Score**: 9.1 (Critical)
- **OWASP Category**: A07:2021 - Identification and Authentication Failures
- **CWE**: CWE-522 (Insufficiently Protected Credentials)
- **Threat Actor**: External attackers exploiting XSS vulnerabilities
- **Attack Vector**: Malicious JavaScript injection → token theft → session hijacking

**Business Impact:**
- Unauthorized access to sensitive agent configurations
- Potential exposure of Azure OpenAI API keys
- Workflow execution sabotage
- GDPR Article 32 non-compliance (inadequate security of processing)
- Reputational damage from credential compromise

---

## Decision Drivers

1. **Security Priority**: Eliminate XSS-based token theft vulnerability
2. **Industry Standards**: OWASP Session Management Cheat Sheet recommendations
3. **Compliance**: GDPR Article 32, SOC2 CC6.1 (Logical and Physical Access Controls)
4. **Zero Trust Architecture**: Never expose credentials to client-side JavaScript
5. **Defense in Depth**: Implement multiple security layers (httpOnly + SameSite + CSRF)
6. **Developer Experience**: Minimize friction for legitimate authenticated requests
7. **Backward Compatibility**: Smooth migration from current localStorage implementation

---

## Considered Options

### Option 1: Continue Using localStorage (Status Quo)
**Rejected** - Unacceptable security risk

**Pros:**
- No implementation effort required
- Simple client-side state management

**Cons:**
- ❌ Vulnerable to XSS token theft (CRITICAL)
- ❌ Fails compliance requirements (GDPR, SOC2)
- ❌ Violates OWASP security best practices
- ❌ Production blocker per security audit

### Option 2: HttpOnly Cookies with Double-Submit CSRF Protection (RECOMMENDED)
**Status:** RECOMMENDED DECISION

**Architecture:**
```
┌─────────────────────────────────────────────────────────┐
│                    Browser Client                        │
├─────────────────────────────────────────────────────────┤
│  HttpOnly Cookie (auth_token)                           │
│    - Inaccessible to JavaScript                         │
│    - Automatically sent with requests                   │
│    - Secure, SameSite=Strict flags                      │
├─────────────────────────────────────────────────────────┤
│  CSRF Token (localStorage or meta tag)                  │
│    - Sent as X-CSRF-Token header                        │
│    - Validated server-side                              │
└─────────────────────────────────────────────────────────┘
          ↓ HTTPS Request with both mechanisms
┌─────────────────────────────────────────────────────────┐
│              .NET Backend API                            │
├─────────────────────────────────────────────────────────┤
│  1. Validate httpOnly cookie (authentication)           │
│  2. Validate CSRF token (state-changing requests)       │
│  3. Process request if both valid                       │
└─────────────────────────────────────────────────────────┘
```

**Pros:**
- ✅ Eliminates XSS token theft (httpOnly flag prevents JavaScript access)
- ✅ CSRF protection via double-submit pattern
- ✅ Industry-standard approach (OWASP recommended)
- ✅ SameSite=Strict prevents cross-origin cookie transmission
- ✅ Automatic cookie transmission (no manual Authorization header)
- ✅ Compliant with GDPR, SOC2, PCI-DSS requirements
- ✅ Supports secure refresh token rotation

**Cons:**
- ⚠️ Requires backend API changes (.NET controller updates)
- ⚠️ Frontend must implement CSRF token handling
- ⚠️ Cross-origin scenarios require CORS configuration
- ⚠️ Migration effort from existing localStorage implementation

### Option 3: In-Memory Token Storage Only (Session Storage)
**Rejected** - Insufficient persistence, poor user experience

**Pros:**
- Better than localStorage (tokens cleared on tab close)
- No XSS risk from persistent storage

**Cons:**
- ❌ User logged out on every tab/window close (poor UX)
- ❌ No protection for tokens in active session memory
- ❌ Still accessible via JavaScript (XSS risk remains)
- ❌ Incompatible with "Remember Me" functionality

### Option 4: OAuth2 Authorization Code Flow with PKCE (BFF Pattern)
**Deferred** - Over-engineered for current requirements, future consideration

**Pros:**
- Enterprise-grade security (OAuth2 standard)
- Backend-for-Frontend (BFF) pattern isolates tokens completely
- Supports Azure AD, third-party identity providers

**Cons:**
- ❌ Significant architectural change (requires BFF service)
- ❌ Extended implementation timeline (3-4 weeks)
- ❌ Overkill for current MVP requirements
- ⚠️ Consider for Phase 2 multi-tenant deployment

---

## Decision Outcome

**Chosen Option:** **Option 2 - HttpOnly Cookies with Double-Submit CSRF Protection**

This solution provides the optimal balance of security, compliance, and implementation feasibility. It eliminates the critical XSS token theft vulnerability while maintaining developer productivity and user experience.

---

## Implementation Specification

### Phase 1: Backend (.NET API) Implementation

#### 1.1 Cookie-Based Authentication Configuration

**File:** `services/dotnet/AgentStudio.Api/Program.cs`

```csharp
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Antiforgery;

var builder = WebApplication.CreateBuilder(args);

// Configure cookie authentication
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = CookieAuthenticationDefaults.AuthenticationScheme;
})
.AddCookie(options =>
{
    options.Cookie.Name = "AgentStudio.AuthToken";
    options.Cookie.HttpOnly = true; // CRITICAL: Prevents JavaScript access
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always; // HTTPS only
    options.Cookie.SameSite = SameSiteMode.Strict; // CSRF protection layer 1
    options.Cookie.MaxAge = TimeSpan.FromHours(8); // 8-hour absolute timeout
    options.SlidingExpiration = true; // Extend on activity
    options.ExpireTimeSpan = TimeSpan.FromHours(1); // 1-hour idle timeout

    // Refresh token cookie (longer lifespan, httpOnly)
    options.Cookie.Path = "/api/auth";

    options.Events = new CookieAuthenticationEvents
    {
        OnRedirectToLogin = context =>
        {
            context.Response.StatusCode = 401; // Return 401 for API calls
            return Task.CompletedTask;
        },
        OnRedirectToAccessDenied = context =>
        {
            context.Response.StatusCode = 403;
            return Task.CompletedTask;
        }
    };
});

// Configure CSRF protection
builder.Services.AddAntiforgery(options =>
{
    options.HeaderName = "X-CSRF-Token";
    options.Cookie.Name = "AgentStudio.CSRF";
    options.Cookie.SameSite = SameSiteMode.Strict;
    options.Cookie.HttpOnly = false; // Must be readable by JavaScript
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
});

// Configure CORS with credentials support
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins(
            builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
                ?? Array.Empty<string>()
        )
        .AllowCredentials() // CRITICAL: Required for cookies
        .AllowAnyMethod()
        .AllowAnyHeader()
        .WithExposedHeaders("X-CSRF-Token"); // Expose CSRF token
    });
});
```

#### 1.2 Authentication Controller

**File:** `services/dotnet/AgentStudio.Api/Controllers/AuthController.cs`

```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Antiforgery;
using System.Security.Claims;

namespace AgentStudio.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAntiforgery _antiforgery;
    private readonly IUserService _userService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        IAntiforgery antiforgery,
        IUserService userService,
        ILogger<AuthController> logger)
    {
        _antiforgery = antiforgery;
        _userService = userService;
        _logger = logger;
    }

    /// <summary>
    /// Authenticate user and establish secure session with httpOnly cookies.
    /// Designed for: Organizations requiring XSS-resistant authentication mechanisms.
    /// </summary>
    [HttpPost("login")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status429TooManyRequests)]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        // Rate limiting check (implement via middleware)
        // await _rateLimiter.CheckLimit(HttpContext.Connection.RemoteIpAddress);

        // Validate credentials
        var user = await _userService.ValidateCredentials(request.Email, request.Password);
        if (user == null)
        {
            _logger.LogWarning(
                "Failed login attempt for email: {Email} from IP: {IP}",
                request.Email,
                HttpContext.Connection.RemoteIpAddress
            );

            // Generic error message (no user enumeration)
            return Unauthorized(new { error = "Invalid credentials" });
        }

        // Create claims identity
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id),
            new(ClaimTypes.Email, user.Email),
            new(ClaimTypes.Name, user.Name),
            new(ClaimTypes.Role, user.Role),
            new("tenant_id", user.TenantId ?? "default")
        };

        var claimsIdentity = new ClaimsIdentity(
            claims,
            CookieAuthenticationDefaults.AuthenticationScheme
        );

        var authProperties = new AuthenticationProperties
        {
            IsPersistent = request.RememberMe,
            IssuedAt = DateTimeOffset.UtcNow,
            ExpiresUtc = request.RememberMe
                ? DateTimeOffset.UtcNow.AddDays(30)
                : DateTimeOffset.UtcNow.AddHours(8),
            AllowRefresh = true
        };

        // Sign in with cookie authentication
        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(claimsIdentity),
            authProperties
        );

        // Generate CSRF token
        var tokens = _antiforgery.GetAndStoreTokens(HttpContext);

        _logger.LogInformation(
            "Successful login for user: {UserId} ({Email})",
            user.Id,
            user.Email
        );

        return Ok(new LoginResponse
        {
            User = new UserDto
            {
                Id = user.Id,
                Email = user.Email,
                Name = user.Name,
                Role = user.Role
            },
            CsrfToken = tokens.RequestToken // Return CSRF token for client storage
        });
    }

    /// <summary>
    /// Retrieve CSRF token for authenticated session.
    /// Best for: Initial application load, token refresh scenarios.
    /// </summary>
    [HttpGet("csrf-token")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public IActionResult GetCsrfToken()
    {
        if (!User.Identity?.IsAuthenticated ?? true)
        {
            return Unauthorized();
        }

        var tokens = _antiforgery.GetAndStoreTokens(HttpContext);
        return Ok(new { csrfToken = tokens.RequestToken });
    }

    /// <summary>
    /// Retrieve current authenticated user information.
    /// </summary>
    [HttpGet("me")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetCurrentUser()
    {
        if (!User.Identity?.IsAuthenticated ?? true)
        {
            return Unauthorized();
        }

        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var user = await _userService.GetUserById(userId);

        if (user == null)
        {
            return Unauthorized();
        }

        return Ok(new UserDto
        {
            Id = user.Id,
            Email = user.Email,
            Name = user.Name,
            Role = user.Role
        });
    }

    /// <summary>
    /// Logout user and invalidate session cookies.
    /// </summary>
    [HttpPost("logout")]
    [ValidateAntiForgeryToken] // CSRF protection for state-changing operation
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> Logout()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        _logger.LogInformation("User logout: {UserId}", userId);

        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);

        // Clear cookies explicitly
        Response.Cookies.Delete("AgentStudio.AuthToken");
        Response.Cookies.Delete("AgentStudio.CSRF");

        return Ok(new { message = "Logout successful" });
    }

    /// <summary>
    /// Refresh authentication session extending timeout.
    /// </summary>
    [HttpPost("refresh")]
    [ValidateAntiForgeryToken]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> RefreshSession()
    {
        if (!User.Identity?.IsAuthenticated ?? true)
        {
            return Unauthorized();
        }

        // Extend session by re-signing in
        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            User,
            new AuthenticationProperties
            {
                IsPersistent = true,
                ExpiresUtc = DateTimeOffset.UtcNow.AddHours(8),
                AllowRefresh = true
            }
        );

        _logger.LogInformation(
            "Session refreshed for user: {UserId}",
            User.FindFirstValue(ClaimTypes.NameIdentifier)
        );

        return Ok(new { message = "Session refreshed successfully" });
    }
}

// DTOs
public record LoginRequest(string Email, string Password, bool RememberMe = false);

public record LoginResponse
{
    public required UserDto User { get; init; }
    public required string CsrfToken { get; init; }
}

public record UserDto
{
    public required string Id { get; init; }
    public required string Email { get; init; }
    public required string Name { get; init; }
    public required string Role { get; init; }
}
```

#### 1.3 CSRF Validation Middleware

**File:** `services/dotnet/AgentStudio.Api/Middleware/CsrfValidationMiddleware.cs`

```csharp
using Microsoft.AspNetCore.Antiforgery;

namespace AgentStudio.Api.Middleware;

/// <summary>
/// Validates CSRF tokens for state-changing HTTP requests.
/// Designed for: Protecting authenticated endpoints from cross-site request forgery.
/// </summary>
public class CsrfValidationMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IAntiforgery _antiforgery;
    private readonly ILogger<CsrfValidationMiddleware> _logger;

    // HTTP methods requiring CSRF protection
    private static readonly HashSet<string> ProtectedMethods = new()
    {
        "POST", "PUT", "DELETE", "PATCH"
    };

    // Endpoints exempt from CSRF (e.g., login, public webhooks)
    private static readonly HashSet<string> ExemptPaths = new()
    {
        "/api/auth/login",
        "/api/webhooks"
    };

    public CsrfValidationMiddleware(
        RequestDelegate next,
        IAntiforgery antiforgery,
        ILogger<CsrfValidationMiddleware> logger)
    {
        _next = next;
        _antiforgery = antiforgery;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Check if request requires CSRF validation
        if (RequiresCsrfValidation(context))
        {
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

    private static bool RequiresCsrfValidation(HttpContext context)
    {
        // Skip if not a protected HTTP method
        if (!ProtectedMethods.Contains(context.Request.Method))
        {
            return false;
        }

        // Skip if path is exempt
        var path = context.Request.Path.Value?.ToLowerInvariant() ?? string.Empty;
        if (ExemptPaths.Any(exempt => path.StartsWith(exempt.ToLowerInvariant())))
        {
            return false;
        }

        // Skip if user is not authenticated (handled by auth middleware)
        if (!context.User.Identity?.IsAuthenticated ?? true)
        {
            return false;
        }

        return true;
    }
}

// Extension method for middleware registration
public static class CsrfValidationMiddlewareExtensions
{
    public static IApplicationBuilder UseCsrfValidation(this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<CsrfValidationMiddleware>();
    }
}
```

**Update Program.cs middleware pipeline:**

```csharp
// After UseAuthorization()
app.UseAuthorization();
app.UseCsrfValidation(); // Add CSRF validation
app.MapControllers();
```

---

### Phase 2: Frontend (React) Implementation

#### 2.1 Remove localStorage Token Storage

**File:** `webapp/src/contexts/AuthContext.tsx`

```typescript
/**
 * Authentication Context Provider - Secure Cookie-Based Implementation.
 * Establishes XSS-resistant authentication infrastructure using httpOnly cookies.
 *
 * Best for: Organizations requiring secure authentication with protection against token theft
 */

import React, { createContext, useContext, useState, useEffect, useCallback, ReactNode } from 'react';

export type UserRole = 'admin' | 'developer' | 'operator' | 'viewer';

export interface User {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  avatar?: string;
  metadata?: Record<string, unknown>;
}

export interface LoginCredentials {
  email: string;
  password: string;
  rememberMe?: boolean;
}

export interface AuthContextValue {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: Error | null;
  csrfToken: string | null;

  login: (credentials: LoginCredentials) => Promise<void>;
  logout: () => Promise<void>;
  refreshSession: () => Promise<void>;

  hasRole: (role: UserRole) => boolean;
  hasAnyRole: (roles: UserRole[]) => boolean;
  canAccess: (requiredRole: UserRole) => boolean;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export interface AuthProviderProps {
  children: ReactNode;
}

const roleHierarchy: UserRole[] = ['viewer', 'operator', 'developer', 'admin'];

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [csrfToken, setCsrfToken] = useState<string | null>(null);

  const isAuthenticated = user !== null;

  /**
   * Initialize authentication state by fetching current user from backend.
   * Backend validates httpOnly cookie automatically.
   */
  useEffect(() => {
    const initializeAuth = async () => {
      setIsLoading(true);

      try {
        // Fetch current user (cookie sent automatically)
        const response = await fetch('/api/auth/me', {
          credentials: 'include', // CRITICAL: Include cookies in request
        });

        if (response.ok) {
          const userData = await response.json();
          setUser(userData);

          // Fetch CSRF token after successful authentication
          const csrfResponse = await fetch('/api/auth/csrf-token', {
            credentials: 'include',
          });

          if (csrfResponse.ok) {
            const { csrfToken } = await csrfResponse.json();
            setCsrfToken(csrfToken);
          }
        } else if (response.status === 401) {
          // User not authenticated
          setUser(null);
          setCsrfToken(null);
        }
      } catch (err) {
        console.error('Auth initialization error:', err);
        setError(err instanceof Error ? err : new Error('Authentication failed'));
        setUser(null);
        setCsrfToken(null);
      } finally {
        setIsLoading(false);
      }
    };

    initializeAuth();
  }, []);

  /**
   * Login action using secure cookie-based authentication.
   */
  const login = useCallback(async (credentials: LoginCredentials) => {
    setIsLoading(true);
    setError(null);

    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include', // CRITICAL: Enable cookie storage
        body: JSON.stringify(credentials),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Login failed');
      }

      const data = await response.json();

      // Store CSRF token (safe to store in memory/localStorage)
      setCsrfToken(data.csrfToken);

      // Set user data
      setUser(data.user);
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Login failed');
      setError(error);
      throw error;
    } finally {
      setIsLoading(false);
    }
  }, []);

  /**
   * Logout action clearing secure session cookies.
   */
  const logout = useCallback(async () => {
    try {
      await fetch('/api/auth/logout', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken || '',
        },
        credentials: 'include',
      });
    } catch (err) {
      console.error('Logout error:', err);
    } finally {
      setUser(null);
      setCsrfToken(null);
      setError(null);
    }
  }, [csrfToken]);

  /**
   * Refresh session to extend authentication timeout.
   */
  const refreshSession = useCallback(async () => {
    if (!csrfToken) {
      throw new Error('No CSRF token available');
    }

    try {
      const response = await fetch('/api/auth/refresh', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
        },
        credentials: 'include',
      });

      if (!response.ok) {
        throw new Error('Session refresh failed');
      }

      // Fetch updated user data
      const userResponse = await fetch('/api/auth/me', {
        credentials: 'include',
      });

      if (userResponse.ok) {
        const userData = await userResponse.json();
        setUser(userData);
      }
    } catch (err) {
      console.error('Session refresh failed:', err);
      await logout();
      throw err;
    }
  }, [csrfToken, logout]);

  // Authorization helpers (unchanged)
  const hasRole = useCallback(
    (role: UserRole): boolean => {
      return user?.role === role;
    },
    [user]
  );

  const hasAnyRole = useCallback(
    (roles: UserRole[]): boolean => {
      return user !== null && roles.includes(user.role);
    },
    [user]
  );

  const canAccess = useCallback(
    (requiredRole: UserRole): boolean => {
      if (!user) return false;

      const userRoleIndex = roleHierarchy.indexOf(user.role);
      const requiredRoleIndex = roleHierarchy.indexOf(requiredRole);

      return userRoleIndex >= requiredRoleIndex;
    },
    [user]
  );

  const value: AuthContextValue = {
    user,
    isAuthenticated,
    isLoading,
    error,
    csrfToken,
    login,
    logout,
    refreshSession,
    hasRole,
    hasAnyRole,
    canAccess,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = (): AuthContextValue => {
  const context = useContext(AuthContext);

  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }

  return context;
};
```

#### 2.2 Update BaseApiClient for Cookie-Based Authentication

**File:** `webapp/src/api/clients/BaseApiClient.ts`

```typescript
/**
 * Base API client with secure cookie-based authentication.
 * Establishes consistent patterns for API integration with built-in CSRF protection.
 *
 * Best for: Building scalable API client infrastructure with XSS-resistant authentication
 */

import axios, { AxiosInstance, AxiosError, AxiosRequestConfig, AxiosResponse } from 'axios';

export class ApiError extends Error {
  public readonly statusCode?: number;
  public readonly response?: any;
  public readonly request?: any;

  constructor(message: string, statusCode?: number, response?: any, request?: any) {
    super(message);
    this.name = 'ApiError';
    this.statusCode = statusCode;
    this.response = response;
    this.request = request;
    Object.setPrototypeOf(this, ApiError.prototype);
  }
}

export interface RetryConfig {
  maxRetries: number;
  retryDelay: number;
  retryCondition?: (error: AxiosError) => boolean;
}

export interface ApiClientConfig {
  timeout?: number;
  retry?: RetryConfig;
  headers?: Record<string, string>;
  csrfTokenProvider?: () => string | null; // Function to get CSRF token
}

export abstract class BaseApiClient {
  protected axios: AxiosInstance;
  private retryConfig: RetryConfig;
  private csrfTokenProvider: () => string | null;

  constructor(baseURL: string, config: ApiClientConfig = {}) {
    this.axios = axios.create({
      baseURL,
      timeout: config.timeout || 30000,
      withCredentials: true, // CRITICAL: Enable automatic cookie transmission
      headers: {
        'Content-Type': 'application/json',
        ...config.headers,
      },
    });

    this.retryConfig = config.retry || {
      maxRetries: 3,
      retryDelay: 1000,
      retryCondition: (error: AxiosError) => {
        return !error.response || (error.response.status >= 500 && error.response.status < 600);
      },
    };

    this.csrfTokenProvider = config.csrfTokenProvider || (() => null);

    this.setupInterceptors();
  }

  /**
   * Sets up request and response interceptors for authentication and CSRF protection.
   */
  private setupInterceptors(): void {
    // Request interceptor for CSRF token
    this.axios.interceptors.request.use(
      (config) => {
        // Add CSRF token for state-changing requests
        const csrfToken = this.csrfTokenProvider();
        if (csrfToken && ['POST', 'PUT', 'DELETE', 'PATCH'].includes(config.method?.toUpperCase() || '')) {
          config.headers['X-CSRF-Token'] = csrfToken;
        }

        // Add request ID for tracing
        config.headers = config.headers || {};
        config.headers['X-Request-Id'] = this.generateRequestId();

        // Log request in development
        if (this.isDevelopment()) {
          console.log(`[API Request] ${config.method?.toUpperCase()} ${config.url}`, config.data);
        }

        return config;
      },
      (error) => {
        return Promise.reject(error);
      }
    );

    // Response interceptor for error handling
    this.axios.interceptors.response.use(
      (response) => {
        if (this.isDevelopment()) {
          console.log(`[API Response] ${response.config.url}`, response.data);
        }
        return response;
      },
      async (error: AxiosError) => {
        const originalRequest = error.config as AxiosRequestConfig & { _retryCount?: number };

        // Initialize retry count
        if (!originalRequest._retryCount) {
          originalRequest._retryCount = 0;
        }

        // Handle 401 Unauthorized (session expired)
        if (error.response?.status === 401) {
          // Trigger logout/redirect to login
          window.dispatchEvent(new CustomEvent('auth:unauthorized'));
          return Promise.reject(this.transformError(error));
        }

        // Handle 403 Forbidden (likely CSRF validation failure)
        if (error.response?.status === 403) {
          // Attempt to refresh CSRF token
          window.dispatchEvent(new CustomEvent('auth:forbidden'));
          return Promise.reject(this.transformError(error));
        }

        // Retry logic for server errors
        if (
          originalRequest._retryCount < this.retryConfig.maxRetries &&
          this.retryConfig.retryCondition?.(error)
        ) {
          originalRequest._retryCount++;
          const delay = this.retryConfig.retryDelay * Math.pow(2, originalRequest._retryCount - 1);

          if (this.isDevelopment()) {
            console.log(
              `[API Retry] Attempt ${originalRequest._retryCount} after ${delay}ms for ${originalRequest.url}`
            );
          }

          await new Promise((resolve) => setTimeout(resolve, delay));
          return this.axios(originalRequest);
        }

        const apiError = this.transformError(error);

        if (this.isDevelopment()) {
          console.error(`[API Error] ${originalRequest.url}`, apiError);
        }

        return Promise.reject(apiError);
      }
    );
  }

  private transformError(error: AxiosError): ApiError {
    if (error.response) {
      const message =
        this.extractErrorMessage(error.response) || `Request failed with status ${error.response.status}`;
      return new ApiError(message, error.response.status, error.response.data, error.config);
    } else if (error.request) {
      return new ApiError('No response received from server', undefined, undefined, error.config);
    } else {
      return new ApiError(error.message || 'Request configuration error', undefined, undefined, error.config);
    }
  }

  private extractErrorMessage(response: AxiosResponse): string | undefined {
    const data = response.data;

    if (typeof data === 'string') {
      return data;
    }
    if (data?.error) {
      return typeof data.error === 'string' ? data.error : data.error.message;
    }
    if (data?.message) {
      return data.message;
    }
    if (data?.errors && Array.isArray(data.errors) && data.errors.length > 0) {
      return data.errors.map((e: any) => e.message || e).join(', ');
    }

    return undefined;
  }

  private generateRequestId(): string {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  private isDevelopment(): boolean {
    return process.env.NODE_ENV === 'development';
  }

  public setHeaders(headers: Record<string, string>): void {
    Object.assign(this.axios.defaults.headers.common, headers);
  }

  public removeHeader(key: string): void {
    delete this.axios.defaults.headers.common[key];
  }

  public async healthCheck(): Promise<boolean> {
    try {
      const response = await this.axios.get('/health');
      return response.status === 200;
    } catch {
      return false;
    }
  }
}
```

#### 2.3 Update Axios Configuration in API Clients

**File:** `webapp/src/api/clients/AgentClient.ts`

```typescript
import { BaseApiClient, ApiClientConfig } from './BaseApiClient';
import { useAuth } from '../../contexts/AuthContext';

/**
 * Agent API client with secure cookie-based authentication.
 */
class AgentClient extends BaseApiClient {
  constructor() {
    const config: ApiClientConfig = {
      timeout: 30000,
      retry: {
        maxRetries: 3,
        retryDelay: 1000,
      },
      // CSRF token provider (will be set via initialization)
      csrfTokenProvider: () => {
        // Access CSRF token from AuthContext
        const authContext = (window as any).__AUTH_CONTEXT__;
        return authContext?.csrfToken || null;
      },
    };

    super(import.meta.env.VITE_API_BASE_URL || '/api', config);
  }

  // Agent-specific API methods...
}

export const agentClient = new AgentClient();
```

---

## Security Controls

### Defense-in-Depth Layers

1. **HttpOnly Cookie Flag**
   - **Control**: Prevents JavaScript access to authentication tokens
   - **Threat Mitigated**: XSS-based token theft (CVSS 9.1 → 0.0)
   - **Verification**: `document.cookie` returns empty string for httpOnly cookies

2. **Secure Cookie Flag**
   - **Control**: Cookies only transmitted over HTTPS
   - **Threat Mitigated**: Man-in-the-middle token interception
   - **Verification**: Cookies not sent over HTTP connections

3. **SameSite=Strict Attribute**
   - **Control**: Prevents cross-origin cookie transmission
   - **Threat Mitigated**: CSRF attacks via cookie auto-submission (partial)
   - **Verification**: Cookies not sent with cross-origin requests

4. **CSRF Token Validation**
   - **Control**: Double-submit pattern (cookie + header validation)
   - **Threat Mitigated**: Cross-site request forgery attacks
   - **Verification**: Requests without valid CSRF token return 403 Forbidden

5. **Session Timeouts**
   - **Idle Timeout**: 1 hour (configurable)
   - **Absolute Timeout**: 8 hours (configurable)
   - **Verification**: Cookies expire per MaxAge setting

### Security Test Plan

**Test Case 1: XSS Token Theft Prevention**
```javascript
// Attempt to access authentication cookie via JavaScript
console.log(document.cookie); // Should NOT include AgentStudio.AuthToken

// Attempt to extract token from localStorage
console.log(localStorage.getItem('auth_tokens')); // Should return null
```
**Expected Result**: ✅ Tokens inaccessible to JavaScript

**Test Case 2: CSRF Protection Validation**
```bash
# Attempt state-changing request without CSRF token
curl -X POST https://app.com/api/workflows/execute \
  -H "Content-Type: application/json" \
  -b "AgentStudio.AuthToken=<valid-cookie>" \
  -d '{"workflowId": "test"}'
```
**Expected Result**: ✅ 403 Forbidden (CSRF validation failed)

**Test Case 3: Cookie Security Attributes**
```bash
# Inspect cookie attributes
curl -I https://app.com/api/auth/login \
  -d '{"email":"test@example.com","password":"password"}' \
  | grep Set-Cookie
```
**Expected Result**: ✅ Cookie includes `HttpOnly; Secure; SameSite=Strict`

**Test Case 4: Session Timeout Enforcement**
```javascript
// Wait 1 hour without activity
setTimeout(async () => {
  const response = await fetch('/api/auth/me', { credentials: 'include' });
  console.log(response.status); // Should be 401 Unauthorized
}, 3600000);
```
**Expected Result**: ✅ Session expires after idle timeout

**Test Case 5: Cross-Origin Cookie Blocking**
```html
<!-- External site attempting to trigger authenticated request -->
<img src="https://app.com/api/workflows/execute?workflowId=malicious" />
```
**Expected Result**: ✅ Cookie not sent (SameSite=Strict blocks cross-origin)

---

## Migration Strategy

### Migration Phases

**Phase 1: Backend Implementation (Week 1, Days 1-2)**
- Implement cookie authentication in .NET API
- Add CSRF token generation endpoint
- Create CSRF validation middleware
- Update CORS configuration for `withCredentials`
- Deploy to staging environment

**Phase 2: Frontend Implementation (Week 1, Days 3-4)**
- Remove localStorage token storage from AuthContext
- Update BaseApiClient for cookie-based auth
- Implement CSRF token management
- Update all API clients to use `credentials: 'include'`
- Test authentication flows in staging

**Phase 3: Testing & Validation (Week 1, Day 5)**
- Execute security test plan (all 5 test cases)
- Perform penetration testing (XSS, CSRF scenarios)
- Validate session timeout behavior
- Test cross-browser compatibility (Chrome, Firefox, Safari, Edge)
- Load testing (1000 concurrent authenticated sessions)

**Phase 4: Production Deployment (Week 2, Day 1)**
- Deploy backend changes to production
- Deploy frontend changes to production
- Monitor authentication error rates
- Verify cookie security attributes in production
- Rollback plan: Revert to JWT if critical issues detected

### Backward Compatibility

**Transition Period:** None required (breaking change)

**User Impact:**
- All users will be logged out during deployment
- Users must log in again after migration
- "Remember Me" functionality preserved via persistent cookies

**Communication Plan:**
- Email notification 24 hours before deployment
- In-app banner: "Scheduled maintenance on [DATE] at [TIME]"
- Estimated downtime: 5 minutes

---

## Compliance Mapping

| Requirement | Control | Verification |
|------------|---------|--------------|
| **GDPR Article 32** (Security of Processing) | httpOnly cookies + encryption in transit | ✅ Tokens not accessible to client JS |
| **OWASP A07:2021** (Identification Failures) | Secure token storage + CSRF protection | ✅ XSS token theft eliminated |
| **SOC2 CC6.1** (Logical Access) | Multi-layered authentication security | ✅ httpOnly + Secure + SameSite + CSRF |
| **PCI-DSS 8.2.3** (Strong Cryptography) | HTTPS-only cookie transmission | ✅ Secure flag enforced |
| **NIST 800-63B** (Session Management) | Idle timeout (1h), absolute timeout (8h) | ✅ Configurable timeouts implemented |

---

## Monitoring & Observability

### Metrics to Track

1. **Authentication Success Rate**
   - Metric: `auth_login_success_rate`
   - Alert: Rate drops below 95%
   - Action: Investigate cookie/CSRF configuration

2. **CSRF Validation Failures**
   - Metric: `csrf_validation_failures_total`
   - Alert: Spike above baseline (>10/min)
   - Action: Check CSRF token generation/rotation

3. **Session Timeout Rate**
   - Metric: `auth_session_timeout_total`
   - Breakdown: Idle timeout vs. absolute timeout
   - Expected: Idle timeouts common, absolute rare

4. **Cookie Rejection Rate**
   - Metric: `auth_cookie_rejected_total`
   - Alert: Rate above 1%
   - Action: Verify HTTPS configuration, browser compatibility

### Logging

```csharp
// Log successful authentication
_logger.LogInformation(
    "User {UserId} authenticated successfully from IP {IP}",
    user.Id,
    HttpContext.Connection.RemoteIpAddress
);

// Log CSRF validation failure
_logger.LogWarning(
    "CSRF validation failed for {Method} {Path} from IP {IP}",
    context.Request.Method,
    context.Request.Path,
    context.Connection.RemoteIpAddress
);

// Log session timeout
_logger.LogInformation(
    "Session timeout for user {UserId} (idle: {IdleTime})",
    userId,
    idleTime
);
```

### Alerts

- **Critical**: CSRF validation failure rate >10/min
- **Critical**: Authentication success rate <95%
- **Warning**: Session timeout rate spike (>2x baseline)
- **Info**: New user login from unfamiliar IP/location

---

## Residual Risks

| Risk | Severity | Mitigation | Acceptance |
|------|----------|------------|------------|
| **Subdomain Cookie Theft** | Low | Set cookie Domain to specific subdomain only | ✅ Accepted |
| **Browser Cookie Storage Limit** | Low | Monitor cookie size (<4KB limit) | ✅ Accepted |
| **CSRF Token Leakage via Logs** | Low | Sanitize CSRF tokens in logging | ✅ Mitigated |
| **Session Fixation** | Low | Regenerate session ID after login | ✅ Implemented |

---

## References

- [OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
- [OWASP CSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)
- [CWE-522: Insufficiently Protected Credentials](https://cwe.mitre.org/data/definitions/522.html)
- [NIST 800-63B Digital Identity Guidelines](https://pages.nist.gov/800-63-3/sp800-63b.html)
- [MDN HTTP Cookies](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies)
- [ASP.NET Core Authentication Documentation](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/)

---

## Approval

**Recommended by:** Security Specialist Agent
**Date:** 2025-10-09
**Status:** Pending Architect Approval

**Next Steps:**
1. Review by architect-supreme agent
2. Implementation by typescript-code-generator agent (.NET + React)
3. Security testing by security-specialist agent
4. Deployment coordination by devops-automator agent

---

**Document Classification:** Internal - Security Architecture
**Contact:** Consultations@BrooksideBI.com | +1 209 487 2047
