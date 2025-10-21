# Circuit-Breaker Pattern

**Best for**: Organizations scaling integrations across Azure, GitHub, and Notion MCP that require resilient failure handling to ensure sustainable operations.

## Problem Statement

When Innovation Nexus builds integrate with external services (Azure APIs, GitHub, Notion MCP), transient failures can cascade into system-wide outages. Repeated calls to failing services waste resources and delay recovery.

**Business Impact**:
- Build deployments fail completely instead of gracefully degrading
- Azure resource provisioning retries exhaust quotas
- Notion database operations block entire workflows
- Team productivity drops during service outages

## When to Use

- **Integration Registry connections**: Azure services, GitHub repos, Notion MCP
- **Cost-sensitive operations**: Avoid excessive API calls that increase Azure/GitHub costs
- **Multi-step build workflows**: Prevent cascading failures in Build creation sagas
- **Rate-limited APIs**: Protect against Notion API, GitHub API rate limit exhaustion

## How It Works

The circuit-breaker acts as a **stateful proxy** between your application and external services, monitoring failure rates and "opening the circuit" when thresholds are exceeded.

### Three States

**CLOSED (Normal Operation)**:
- Requests pass through to service
- Monitor failure rate
- If failures exceed threshold → transition to OPEN

**OPEN (Failing Fast)**:
- Immediately reject requests without calling service
- Return cached response or error
- After timeout period → transition to HALF-OPEN

**HALF-OPEN (Testing Recovery)**:
- Allow limited requests through
- If successful → transition to CLOSED
- If fail → return to OPEN

### State Diagram

```
┌─────────┐  failures > threshold  ┌──────┐
│ CLOSED  │────────────────────────→│ OPEN │
└────┬────┘                         └───┬──┘
     │                                  │
     │ success                   timeout│
     │ ┌────────────┐                  │
     └─│ HALF-OPEN  │←─────────────────┘
       └────────────┘
          │      │
    success│      │failure
          ▼      ▼
```

## Benefits

- **Fast failure**: No wasted time waiting for timeouts
- **Resource protection**: Prevents quota/rate limit exhaustion
- **Self-healing**: Automatically recovers when service restores
- **Cost optimization**: Reduces billable API calls during outages
- **User experience**: Provides immediate feedback instead of hanging

## Tradeoffs

- **False positives**: Healthy requests rejected during OPEN state
- **Configuration complexity**: Threshold tuning requires monitoring
- **State management**: Requires distributed state in multi-instance deployments
- **Delayed recovery**: Timeout period prevents immediate retry after service recovery

## Innovation Nexus Applications

### Azure Resource Provisioning (Example Builds)

**Scenario**: Creating App Service for new build fails due to Azure quota limits

**Without Circuit-Breaker**:
```
Attempt 1: Provision App Service → Quota exceeded (30s timeout)
Attempt 2: Retry → Quota exceeded (30s timeout)
Attempt 3: Retry → Quota exceeded (30s timeout)
Total: 90 seconds wasted, build still fails
```

**With Circuit-Breaker**:
```
Attempt 1: Provision App Service → Quota exceeded → Circuit OPENS
Attempt 2: Circuit-breaker fails fast → Immediate error (0s)
Attempt 3: Circuit-breaker fails fast → Immediate error (0s)
Total: 30 seconds to failure, user notified immediately
After 60s: Circuit → HALF-OPEN, retry succeeds when quota available
```

### GitHub Repository Creation (Build Workflow)

**Scenario**: GitHub API experiencing outage during build creation saga

**Circuit-Breaker Configuration**:
```typescript
const githubCircuitBreaker = {
  failureThreshold: 3,     // Open after 3 consecutive failures
  timeout: 60000,          // Wait 60s before testing recovery
  resetTimeout: 30000      // Stay closed for 30s after recovery
};
```

**Workflow**:
1. Create Notion Build entry → SUCCESS
2. Create GitHub repo → CIRCUIT OPEN (GitHub down)
3. Circuit-breaker fails fast, triggers saga compensation
4. Rollback: Delete Notion Build entry
5. User notified: "GitHub unavailable, build creation paused"
6. After 60s: Circuit → HALF-OPEN, automatic retry succeeds

### Notion MCP Operations (Database Queries)

**Scenario**: Notion API rate limiting during cost analysis

**Circuit-Breaker Protection**:
- Track Notion MCP query failure rate
- Open circuit when rate limit exceeded
- Return cached Software Tracker data from previous successful query
- Resume live queries when rate limit resets

**Business Value**:
- Cost analysis continues with slightly stale data
- Prevents cascading failures across all Notion operations
- Respects Notion API limits, maintains good API citizenship

## Microsoft Azure Implementation

### Using Azure SDK Resilience

```csharp
// Establish resilient Azure service connections that support sustainable operations
// Azure SDK includes built-in circuit-breaker capabilities via Polly integration

using Polly;
using Polly.CircuitBreaker;
using Microsoft.Azure.Management.WebSites;

// Define circuit-breaker policy to protect Azure resource provisioning operations
var circuitBreakerPolicy = Policy
    .Handle<HttpRequestException>()
    .Or<AzureException>()
    .CircuitBreakerAsync(
        handledEventsAllowedBeforeBreaking: 3,
        durationOfBreak: TimeSpan.FromSeconds(60),
        onBreak: (exception, duration) =>
        {
            // Log circuit state transition to Application Insights
            telemetry.TrackEvent("CircuitBreakerOpen", new Dictionary<string, string>
            {
                { "Service", "Azure App Service" },
                { "Duration", duration.TotalSeconds.ToString() }
            });
        },
        onReset: () =>
        {
            // Log successful recovery for monitoring sustainable service health
            telemetry.TrackEvent("CircuitBreakerClosed", new Dictionary<string, string>
            {
                { "Service", "Azure App Service" }
            });
        }
    );

// Apply circuit-breaker policy to Azure management clients
var appServiceClient = await Policy
    .WrapAsync(circuitBreakerPolicy, retryPolicy)
    .ExecuteAsync(async () =>
    {
        var client = new WebSiteManagementClient(credentials);
        return client;
    });
```

### Azure Front Door Circuit-Breaker

For public-facing Innovation Nexus deployments, establish automated traffic management:

**Configuration**:
- Configure Azure Front Door health probes (HTTP 200 check every 30s)
- Set circuit-breaker on backend pools (3 consecutive failures)
- Automatic traffic shifting to healthy instances
- Integration with Application Insights for measurable observability

**Business Value**:
- Zero-downtime deployments for Example Builds
- Automatic failover during Azure region outages
- Cost optimization through intelligent traffic routing

## Configuration Guidelines

### Threshold Settings

Establish service-specific thresholds based on failure characteristics and recovery patterns:

| Service | Failures Before Open | Timeout Duration | Notes |
|---------|---------------------|------------------|-------|
| Azure Resource APIs | 3 | 60s | Quota errors unlikely to resolve quickly |
| GitHub API | 5 | 30s | Transient failures common, recovers fast |
| Notion MCP | 3 | 15s | Rate limits reset quickly, aggressive recovery |
| Custom Integrations | 2 | 120s | Conservative for unknown service behavior |
| Azure Key Vault | 2 | 45s | Critical path, fail quickly to trigger fallback |

### Monitoring Metrics

Track these circuit-breaker metrics in Application Insights to drive measurable improvements:

**Primary Metrics**:
- Circuit state transitions (CLOSED → OPEN → HALF-OPEN)
- Rejection rate during OPEN state (requests/second)
- Mean time to recovery (MTTR) per service
- False positive rate (healthy requests rejected)

**Custom Events**:
```csharp
// Establish structured telemetry for circuit-breaker state changes
telemetry.TrackEvent("CircuitBreakerStateChange", new Dictionary<string, string>
{
    { "Service", "GitHub API" },
    { "FromState", "CLOSED" },
    { "ToState", "OPEN" },
    { "FailureCount", "3" },
    { "LastError", exception.Message }
});
```

**Alerts**:
- Circuit OPEN for > 5 minutes: Escalate to on-call
- False positive rate > 10%: Tune thresholds
- Recovery time increasing trend: Investigate service health

## Implementation Checklist

When implementing circuit-breaker pattern for Integration Registry connections:

- [ ] Define failure thresholds based on service SLA
- [ ] Configure timeout durations appropriate to service recovery time
- [ ] Implement Application Insights telemetry for state transitions
- [ ] Create fallback behavior (cached data, default values, graceful degradation)
- [ ] Document expected behavior in ARCHITECTURE.md for AI agents
- [ ] Add circuit-breaker state to health check endpoints
- [ ] Configure alerts for prolonged OPEN state
- [ ] Test circuit-breaker behavior in staging environment
- [ ] Plan rollback strategy if circuit-breaker causes issues
- [ ] Update Integration Registry entry with circuit-breaker configuration

## Related Patterns

Combine circuit-breaker with these complementary resilience patterns:

- **Retry with Exponential Backoff**: Use BEFORE circuit-breaker opens to handle transient failures
- **Timeout Pattern**: Enforces maximum wait time per request, prevents hanging
- **Bulkhead Isolation**: Prevents one failing integration from blocking others through resource pooling
- **Fallback Pattern**: Return cached/default data when circuit OPEN to maintain partial functionality
- **Health Check Pattern**: Circuit-breaker state feeds into health endpoint for load balancer decisions

## Success Criteria

You are achieving measurable outcomes when:

- Mean time to detect failures < 5 seconds (immediate OPEN state)
- False positive rate < 5% (healthy requests rarely rejected)
- Service calls reduced by 80%+ during outages (fast-fail effectiveness)
- Mean time to recovery decreases by 50%+ (self-healing works)
- Zero cascading failures during external service outages
- Cost optimization: 30%+ reduction in wasted API calls during failures
- Team productivity maintained through graceful degradation

## References

- [Azure Architecture Center: Circuit Breaker Pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker)
- [Polly .NET Resilience Library](https://github.com/App-vNext/Polly)
- [Martin Fowler: Circuit Breaker](https://martinfowler.com/bliki/CircuitBreaker.html)
- [Azure Front Door Health Probes](https://learn.microsoft.com/en-us/azure/frontdoor/health-probes)
- [Application Insights Custom Events](https://learn.microsoft.com/en-us/azure/azure-monitor/app/api-custom-events-metrics)

---

**Status**: Reference Documentation
**Content Type**: Technical Pattern
**Evergreen**: Yes (timeless resilience pattern)
**Reusability**: Highly Reusable across all external integrations
**Related Knowledge Vault Entries**: Retry Patterns, Saga Pattern, Timeout Configuration, Azure SDK Best Practices
