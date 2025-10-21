# Retry with Exponential Backoff Pattern

**Best for**: Organizations scaling cloud integrations that require graceful handling of transient failures to ensure reliable operations across Azure, GitHub, and Notion platforms.

## Problem Statement

External service calls fail intermittently due to network blips, rate limiting, or temporary service degradation. Immediate retries often fail for the same reason, while permanent abandonment wastes successful partial work and requires costly manual intervention.

**Business Impact**:
- Build deployments fail due to transient Azure timeouts, blocking innovation delivery
- GitHub repository operations abandoned unnecessarily, disrupting development workflows
- Notion database updates lost during brief API unavailability, compromising data integrity
- Increased operational costs from re-running entire workflows instead of recovering gracefully

## When to Use

This pattern establishes resilient operations for:

- **Network operations**: Azure API calls, GitHub operations, Notion MCP queries
- **Rate-limited APIs**: GitHub (5000 req/hr), Notion (3 req/s), Azure (subscription limits)
- **Cloud deployments**: Resource provisioning with occasional quota conflicts
- **Database operations**: Cosmos DB throttling, SQL connection pool exhaustion
- **Webhook deliveries**: Event notifications that may experience network congestion
- **File uploads**: Large artifact transfers to Azure Storage or GitHub

## How It Works

Retry failed operations with progressively longer waits between attempts, adding random jitter to prevent thundering herd scenarios where multiple clients retry simultaneously.

### Core Algorithm

```
Base Delay: 1 second
Max Delay: 64 seconds
Max Retries: 5
Jitter: ±25%

Attempt 1: Execute → Fail → Wait 1s  (2^0 = 1s)
Attempt 2: Execute → Fail → Wait 2s  (2^1 = 2s)
Attempt 3: Execute → Fail → Wait 4s  (2^2 = 4s)
Attempt 4: Execute → Fail → Wait 8s  (2^3 = 8s)
Attempt 5: Execute → Fail → Wait 16s (2^4 = 16s)
Attempt 6: Execute → SUCCESS or FAIL PERMANENTLY
```

### With Jitter (Recommended)

```
Attempt 3 without jitter: Always wait exactly 4s
Attempt 3 with jitter: Wait 3s-5s (random within ±25%)

Why jitter matters:
- 100 clients retry simultaneously → All hit server at exact same time → Server overwhelmed
- With jitter → Retries spread across 3-5s window → Server load distributed → Higher success rate
```

## Benefits

This pattern drives measurable outcomes through:

- **High success rate**: 95%+ transient failures resolve within 5 retries
- **Distributed load**: Jitter prevents retry storms that can overwhelm services
- **Cost optimization**: Avoids re-executing expensive successful operations
- **Self-healing**: Automatically recovers without human intervention
- **Predictable behavior**: Deterministic retry logic simplifies debugging

## Tradeoffs

Consider these implications when implementing:

- **Increased latency**: Total wait time up to 2 minutes (1+2+4+8+16+32s)
- **Masks systemic issues**: Can hide chronic performance problems requiring root cause analysis
- **Resource holding**: Connections/locks held during retry wait periods
- **Complexity**: Requires careful configuration per service type and operation
- **Memory pressure**: Pending retries consume memory/threads during wait periods

## Innovation Nexus Applications

### Azure Resource Group Creation

**Scenario**: Creating resource group for new Example Build during concurrent deployments

**Retry Configuration**:
```typescript
const azureRetryPolicy = {
  maxRetries: 5,
  baseDelay: 1000,
  maxDelay: 32000,
  jitterPercent: 25,
  retryableErrors: [
    'ResourceGroupConflict',      // Temporary naming collision
    'ThrottlingException',         // Rate limit hit
    'ServiceUnavailable',          // Azure region issue
    'RequestTimeout',              // Network timeout
    'TooManyRequests'             // Subscription throttling
  ],
  nonRetryableErrors: [
    'InvalidSubscriptionId',       // Configuration error
    'AuthorizationFailed',         // Permission issue
    'QuotaExceeded',              // Hard limit reached
    'InvalidResourceGroup'         // Naming convention violation
  ]
};
```

**Execution Flow**:
```
Attempt 1: Create RG "rg-brookside-build-123"
  → ResourceGroupConflict (another deployment using same name)
  → Wait 1s ± 250ms

Attempt 2: Create RG "rg-brookside-build-123"
  → ResourceGroupConflict (deployment still in progress)
  → Wait 2s ± 500ms

Attempt 3: Create RG "rg-brookside-build-123"
  → SUCCESS (previous deployment completed)

Total time: ~4s (vs. failing immediately and requiring manual intervention)
Business Value: Build deployment succeeds automatically, no developer interruption
```

### GitHub Repository Creation with Rate Limiting

**Scenario**: Creating repositories during organization-wide Innovation Nexus scan

**Intelligent Retry with Rate Limit Awareness**:
```typescript
async function createGitHubRepo(repoName: string): Promise<Repository> {
  const retryPolicy = {
    maxRetries: 10,  // Higher for rate limits
    baseDelay: 5000, // Start with 5s (GitHub recommendation)
    maxDelay: 300000, // Up to 5 minutes
    shouldRetry: (error: GitHubError) => {
      // Respect rate limit headers
      if (error.status === 403 && error.headers['x-ratelimit-remaining'] === '0') {
        const resetTime = parseInt(error.headers['x-ratelimit-reset']) * 1000;
        const waitTime = Math.max(0, resetTime - Date.now());
        console.log(`Rate limited. Waiting ${waitTime/1000}s until reset`);
        return { retry: true, waitTime };
      }

      // Retry server errors with exponential backoff
      if (error.status >= 500) {
        return { retry: true, waitTime: null };
      }

      // Don't retry client errors
      return { retry: false, waitTime: null };
    }
  };

  return await retryWithBackoff(
    () => githubClient.repos.create({
      name: repoName,
      private: true,
      auto_init: true
    }),
    retryPolicy
  );
}
```

**Business Value**:
- Repository creation succeeds even during peak API usage
- No manual intervention required for rate limit handling
- Predictable behavior enables reliable automation

### Notion Database Query with Transient Failures

**Scenario**: Querying Software & Cost Tracker for monthly spend analysis

**Fast Recovery Configuration**:
```typescript
const notionRetryPolicy = {
  maxRetries: 3,  // Notion usually recovers quickly
  baseDelay: 500, // Start fast (500ms)
  maxDelay: 4000, // Max 4s
  jitterPercent: 50, // High jitter (±50%) to spread load
  retryableErrors: [
    'rate_limited',         // Notion rate limit (3 req/s)
    'service_unavailable',  // Notion outage
    'gateway_timeout',      // Network issue
    'conflict_error'        // Concurrent modification
  ],
  onRetry: (attempt, error, nextDelay) => {
    console.log(`Notion retry ${attempt}: ${error.code}, waiting ${nextDelay}ms`);
    // Could send telemetry here
  }
};
```

**Execution with High Jitter**:
```
Attempt 1: Query Software Tracker → rate_limited
  → Wait 500ms ± 250ms (actual: 375ms)

Attempt 2: Query Software Tracker → rate_limited
  → Wait 1000ms ± 500ms (actual: 1250ms)

Attempt 3: Query Software Tracker → SUCCESS
Total time: ~1.6s (vs. failing immediately and losing cost visibility)
```

### Azure Function Deployment with Quota Issues

**Scenario**: Deploying serverless functions for Innovation Nexus automation

**Quota-Aware Retry**:
```typescript
async function deployAzureFunction(functionApp: FunctionAppConfig) {
  const retryPolicy = {
    maxRetries: 8,
    baseDelay: 2000,
    maxDelay: 60000,
    shouldRetry: (error: AzureError) => {
      // Temporary quota exceeded - retry with longer delay
      if (error.code === 'QuotaTemporarilyExceeded') {
        return { retry: true, waitTime: 30000 }; // Wait 30s minimum
      }

      // Deployment conflict - another deployment in progress
      if (error.code === 'DeploymentInProgress') {
        return { retry: true, waitTime: null }; // Use exponential backoff
      }

      // Permanent quota exceeded - don't retry
      if (error.code === 'QuotaExceeded') {
        return { retry: false, waitTime: null };
      }

      // Default: retry transient errors
      return { retry: error.isTransient, waitTime: null };
    }
  };

  return await retryWithBackoff(
    () => azureClient.webApps.createOrUpdate(functionApp),
    retryPolicy
  );
}
```

## Microsoft Azure Best Practices

### Azure SDK Built-in Retry

Azure SDKs include sophisticated retry policies by default:

```csharp
// Configure retry policy for Azure App Service operations
var options = new WebSiteManagementClientOptions
{
    Retry = {
        MaxRetries = 5,
        Mode = RetryMode.Exponential,
        Delay = TimeSpan.FromSeconds(1),
        MaxDelay = TimeSpan.FromSeconds(32),
        NetworkTimeout = TimeSpan.FromSeconds(100)
    }
};

var client = new WebSiteManagementClient(subscriptionId, credentials, options);

// The SDK automatically handles:
// - Exponential backoff calculation
// - Jitter addition
// - Transient error detection
// - Rate limit respect
```

### Polly for Custom Retry Logic

For complex scenarios requiring custom retry behavior:

```csharp
var retryPolicy = Policy
    .Handle<HttpRequestException>()
    .Or<TaskCanceledException>()
    .Or<TimeoutException>()
    .WaitAndRetryAsync(
        retryCount: 5,
        sleepDurationProvider: attempt =>
            TimeSpan.FromSeconds(Math.Pow(2, attempt))
            + TimeSpan.FromMilliseconds(Random.Shared.Next(0, 500)),
        onRetry: (exception, timeSpan, attempt, context) =>
        {
            // Log to Application Insights
            telemetryClient.TrackEvent("RetryAttempt", new Dictionary<string, string>
            {
                ["Operation"] = context.OperationKey,
                ["Attempt"] = attempt.ToString(),
                ["WaitTime"] = timeSpan.TotalSeconds.ToString(),
                ["Error"] = exception.Message
            });

            logger.LogWarning(
                "Retry {Attempt} after {WaitTime}s for {Operation}: {Error}",
                attempt, timeSpan.TotalSeconds, context.OperationKey, exception.Message
            );
        }
    );

// Execute with retry policy
var result = await retryPolicy.ExecuteAsync(
    async (context) => await PerformOperation(),
    new Context("CreateExampleBuild")
);
```

### Azure Functions with Durable Functions Retry

For serverless orchestrations:

```csharp
[FunctionName("ProcessInnovationWorkflow")]
public static async Task<bool> ProcessInnovation(
    [OrchestrationTrigger] IDurableOrchestrationContext context)
{
    var retryOptions = new RetryOptions(
        firstRetryInterval: TimeSpan.FromSeconds(1),
        maxNumberOfAttempts: 5)
    {
        MaxRetryInterval = TimeSpan.FromSeconds(30),
        BackoffCoefficient = 2.0,
        RetryTimeout = TimeSpan.FromMinutes(5)
    };

    try
    {
        // Retry Notion database update
        await context.CallActivityWithRetryAsync<bool>(
            "UpdateNotionDatabase",
            retryOptions,
            innovationData);

        // Retry GitHub repository creation
        await context.CallActivityWithRetryAsync<string>(
            "CreateGitHubRepository",
            retryOptions,
            repoConfig);

        return true;
    }
    catch (FunctionFailedException ex)
    {
        // All retries exhausted
        await context.CallActivityAsync("NotifyTeam",
            $"Innovation workflow failed after retries: {ex.Message}");
        return false;
    }
}
```

## Configuration by Service Type

Establish service-specific retry configurations for optimal performance:

| Service | Max Retries | Base Delay | Max Delay | Jitter | Notes |
|---------|-------------|------------|-----------|--------|-------|
| **Azure Resource APIs** | 5 | 1s | 32s | ±25% | Default Azure SDK configuration |
| **Azure Storage** | 4 | 2s | 16s | ±20% | Built-in retry in Storage SDK |
| **GitHub API** | 10 | 5s | 300s | ±50% | Respect rate limit headers |
| **Notion MCP** | 3 | 500ms | 4s | ±50% | Fast recovery, high jitter |
| **Custom APIs** | 3 | 2s | 16s | ±25% | Conservative default |
| **Database queries** | 5 | 100ms | 2s | ±10% | Fast retry for transient locks |
| **Webhook delivery** | 6 | 1s | 60s | ±30% | Account for network congestion |
| **Email services** | 3 | 5s | 30s | ±20% | Avoid spam triggers |

## Monitoring & Tuning

### Metrics to Track (Application Insights)

Establish comprehensive monitoring to optimize retry configurations:

```csharp
public class RetryMetrics
{
    private readonly TelemetryClient telemetryClient;

    public void RecordRetryAttempt(string operation, int attempt, TimeSpan waitTime)
    {
        telemetryClient.TrackMetric($"Retry.{operation}.Attempt", attempt);
        telemetryClient.TrackMetric($"Retry.{operation}.WaitTime", waitTime.TotalMilliseconds);
    }

    public void RecordRetrySuccess(string operation, int totalAttempts)
    {
        telemetryClient.TrackMetric($"Retry.{operation}.Success", 1);
        telemetryClient.TrackMetric($"Retry.{operation}.TotalAttempts", totalAttempts);
    }

    public void RecordRetryFailure(string operation, int totalAttempts)
    {
        telemetryClient.TrackMetric($"Retry.{operation}.Failure", 1);
        telemetryClient.TrackMetric($"Retry.{operation}.Exhausted", totalAttempts);
    }
}
```

**Key Metrics**:
- **Retry attempt distribution**: How many operations succeed on attempt 1, 2, 3, etc.?
- **Total retry time**: Cumulative time spent waiting across all retries
- **Success rate after retries**: Percentage of operations that eventually succeed
- **Permanent failure rate**: Percentage of operations that exhaust all retries
- **P95 latency with retries**: 95th percentile total operation time

### Tuning Guidelines

**Increase base delay if**:
- Server load increases with retries (retries causing more harm)
- Retry attempts cluster together (need more jitter)
- Error logs show "too many requests" patterns

**Decrease base delay if**:
- Most failures resolve within 1-2 seconds
- User experience suffers from high latency
- Monitoring shows quick recovery patterns

**Increase max retries if**:
- High permanent failure rate but manual retries often succeed
- Service has known long recovery times (e.g., Azure region failovers)
- Cost of failure exceeds cost of waiting

**Decrease max retries if**:
- Retries never succeed (indicates systemic issue, not transient)
- Total latency becomes unacceptable for user experience
- Downstream timeouts triggered by cumulative retry time

### Adaptive Retry (Advanced)

Dynamically adjust retry parameters based on observed behavior:

```typescript
class AdaptiveRetryPolicy {
  private successRateWindow = new RollingWindow(100);
  private avgRecoveryTime = new RollingAverage(50);

  adjust(): RetryConfig {
    const successRate = this.successRateWindow.calculate();
    const avgTime = this.avgRecoveryTime.calculate();

    // If most succeed quickly, reduce delay
    if (successRate > 0.9 && avgTime < 2000) {
      return { baseDelay: 500, maxRetries: 3 };
    }

    // If success rate low, increase retries
    if (successRate < 0.7) {
      return { baseDelay: 2000, maxRetries: 7 };
    }

    // Default configuration
    return { baseDelay: 1000, maxRetries: 5 };
  }
}
```

## Implementation Examples

### TypeScript/JavaScript Implementation

Complete retry implementation with exponential backoff and jitter:

```typescript
interface RetryOptions {
  maxRetries: number;
  baseDelay: number;
  maxDelay: number;
  jitterPercent: number;
  retryableErrors?: string[];
  onRetry?: (attempt: number, error: Error, delay: number) => void;
}

async function retryWithBackoff<T>(
  operation: () => Promise<T>,
  options: RetryOptions
): Promise<T> {
  let lastError: Error;

  for (let attempt = 1; attempt <= options.maxRetries + 1; attempt++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error as Error;

      // Check if error is retryable
      if (options.retryableErrors &&
          !options.retryableErrors.includes(error.code || error.name)) {
        throw error; // Non-retryable error
      }

      // Check if we've exhausted retries
      if (attempt > options.maxRetries) {
        throw new Error(
          `Operation failed after ${options.maxRetries} retries: ${lastError.message}`
        );
      }

      // Calculate exponential backoff with jitter
      const exponentialDelay = Math.min(
        options.baseDelay * Math.pow(2, attempt - 1),
        options.maxDelay
      );

      const jitter = exponentialDelay * (options.jitterPercent / 100);
      const actualDelay = exponentialDelay + (Math.random() - 0.5) * 2 * jitter;

      // Notify retry handler if provided
      if (options.onRetry) {
        options.onRetry(attempt, error, actualDelay);
      }

      // Wait before retrying
      await new Promise(resolve => setTimeout(resolve, actualDelay));
    }
  }

  throw lastError!;
}

// Usage example for Innovation Nexus
const createBuildWithRetry = async (buildData: BuildData) => {
  return await retryWithBackoff(
    async () => {
      const response = await fetch('/api/builds', {
        method: 'POST',
        body: JSON.stringify(buildData)
      });

      if (!response.ok) {
        const error = new Error(`HTTP ${response.status}`);
        error.code = response.status.toString();
        throw error;
      }

      return response.json();
    },
    {
      maxRetries: 5,
      baseDelay: 1000,
      maxDelay: 32000,
      jitterPercent: 25,
      retryableErrors: ['500', '502', '503', '504', '429'],
      onRetry: (attempt, error, delay) => {
        console.log(`Attempt ${attempt} failed: ${error.message}. Retrying in ${delay}ms`);
      }
    }
  );
};
```

### Python Implementation (for Repository Analyzer)

```python
import asyncio
import random
import time
from typing import TypeVar, Callable, Optional, List, Any
from functools import wraps

T = TypeVar('T')

class RetryConfig:
    def __init__(
        self,
        max_retries: int = 5,
        base_delay: float = 1.0,
        max_delay: float = 32.0,
        jitter_percent: float = 25.0,
        retryable_exceptions: Optional[List[type]] = None
    ):
        self.max_retries = max_retries
        self.base_delay = base_delay
        self.max_delay = max_delay
        self.jitter_percent = jitter_percent
        self.retryable_exceptions = retryable_exceptions or [Exception]

def retry_with_backoff(config: RetryConfig):
    """Decorator for adding retry with exponential backoff"""
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @wraps(func)
        async def async_wrapper(*args, **kwargs) -> T:
            last_exception = None

            for attempt in range(1, config.max_retries + 2):
                try:
                    return await func(*args, **kwargs)
                except Exception as e:
                    last_exception = e

                    # Check if exception is retryable
                    if not any(isinstance(e, exc_type)
                              for exc_type in config.retryable_exceptions):
                        raise

                    # Check if we've exhausted retries
                    if attempt > config.max_retries:
                        raise Exception(
                            f"Operation failed after {config.max_retries} retries"
                        ) from e

                    # Calculate delay with exponential backoff
                    exponential_delay = min(
                        config.base_delay * (2 ** (attempt - 1)),
                        config.max_delay
                    )

                    # Add jitter
                    jitter_range = exponential_delay * (config.jitter_percent / 100)
                    actual_delay = exponential_delay + random.uniform(
                        -jitter_range, jitter_range
                    )

                    print(f"Attempt {attempt} failed: {str(e)}. "
                          f"Retrying in {actual_delay:.2f}s")

                    await asyncio.sleep(actual_delay)

            raise last_exception

        @wraps(func)
        def sync_wrapper(*args, **kwargs) -> T:
            # Synchronous version for non-async functions
            last_exception = None

            for attempt in range(1, config.max_retries + 2):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    last_exception = e

                    if not any(isinstance(e, exc_type)
                              for exc_type in config.retryable_exceptions):
                        raise

                    if attempt > config.max_retries:
                        raise Exception(
                            f"Operation failed after {config.max_retries} retries"
                        ) from e

                    exponential_delay = min(
                        config.base_delay * (2 ** (attempt - 1)),
                        config.max_delay
                    )

                    jitter_range = exponential_delay * (config.jitter_percent / 100)
                    actual_delay = exponential_delay + random.uniform(
                        -jitter_range, jitter_range
                    )

                    print(f"Attempt {attempt} failed: {str(e)}. "
                          f"Retrying in {actual_delay:.2f}s")

                    time.sleep(actual_delay)

            raise last_exception

        # Return appropriate wrapper based on function type
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper

    return decorator

# Usage in Repository Analyzer
@retry_with_backoff(RetryConfig(
    max_retries=3,
    base_delay=0.5,
    max_delay=4.0,
    jitter_percent=50,
    retryable_exceptions=[ConnectionError, TimeoutError]
))
async def query_notion_database(database_id: str) -> dict:
    """Query Notion database with automatic retry"""
    response = await notion_client.databases.query(database_id)
    if response.status_code == 429:  # Rate limited
        raise ConnectionError("Rate limited by Notion API")
    return response.json()
```

## Related Patterns

Combine with these patterns for comprehensive resilience:

- **[Circuit-Breaker](./circuit-breaker.md)**: Stop retrying when service clearly down (prevents retry storms)
- **[Timeout Pattern](./timeout.md)**: Enforce maximum time per retry attempt (prevents hanging)
- **[Bulkhead](./bulkhead.md)**: Limit concurrent retry operations to prevent resource exhaustion
- **[Fallback](./fallback.md)**: Return cached/default data after retry exhaustion
- **[Queue-Based Load Leveling](./queue-load-leveling.md)**: Buffer requests during high load periods

## Anti-Patterns to Avoid

### Immediate Retry (Bad)

```typescript
// ❌ Don't do this - hammers the service
for (let i = 0; i < 5; i++) {
  try {
    return await operation();
  } catch (error) {
    // No delay - immediately retries
  }
}
```

### Linear Backoff (Suboptimal)

```typescript
// ❌ Suboptimal - doesn't account for recovery time patterns
for (let i = 0; i < 5; i++) {
  try {
    return await operation();
  } catch (error) {
    await sleep(1000 * i); // Linear: 0s, 1s, 2s, 3s, 4s
  }
}
```

### No Jitter (Problematic at Scale)

```typescript
// ❌ Causes thundering herd problem
await sleep(Math.pow(2, attempt) * 1000); // Exact delays, no randomization
```

### Infinite Retry (Dangerous)

```typescript
// ❌ Never give up - can cause infinite loops
while (true) {
  try {
    return await operation();
  } catch (error) {
    await sleep(1000);
  }
}
```

## Testing Strategies

### Unit Testing Retry Logic

```typescript
describe('RetryWithBackoff', () => {
  it('should succeed on third attempt', async () => {
    let attempts = 0;
    const operation = jest.fn(async () => {
      attempts++;
      if (attempts < 3) {
        throw new Error('Transient error');
      }
      return 'success';
    });

    const result = await retryWithBackoff(operation, {
      maxRetries: 5,
      baseDelay: 10, // Short delays for testing
      maxDelay: 100,
      jitterPercent: 0 // No jitter for predictable tests
    });

    expect(result).toBe('success');
    expect(operation).toHaveBeenCalledTimes(3);
  });

  it('should respect max retries', async () => {
    const operation = jest.fn(async () => {
      throw new Error('Persistent error');
    });

    await expect(
      retryWithBackoff(operation, {
        maxRetries: 3,
        baseDelay: 10,
        maxDelay: 100,
        jitterPercent: 0
      })
    ).rejects.toThrow('Operation failed after 3 retries');

    expect(operation).toHaveBeenCalledTimes(4); // Initial + 3 retries
  });
});
```

### Integration Testing with Chaos Engineering

```typescript
// Simulate transient failures in test environment
class ChaosProxy {
  constructor(
    private target: any,
    private failureRate: number = 0.3
  ) {}

  async execute(operation: string, ...args: any[]) {
    if (Math.random() < this.failureRate) {
      throw new Error('Simulated transient failure');
    }
    return this.target[operation](...args);
  }
}

// Test with simulated failures
const chaosClient = new ChaosProxy(realClient, 0.5); // 50% failure rate
const resilientOperation = retryWithBackoff(
  () => chaosClient.execute('createResource'),
  retryConfig
);
```

## References

- [Azure Architecture Center: Retry Pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/retry)
- [Polly .NET Resilience Library](https://github.com/App-vNext/Polly)
- [AWS Architecture Blog: Exponential Backoff and Jitter](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/)
- [Google Cloud: Implementing Exponential Backoff](https://cloud.google.com/storage/docs/exponential-backoff)
- [Martin Fowler: Circuit Breaker](https://martinfowler.com/bliki/CircuitBreaker.html)

---

**Status**: Reference Documentation
**Content Type**: Technical Pattern
**Evergreen**: Yes (timeless resilience pattern)
**Reusability**: Highly Reusable across all external API integrations
**Last Updated**: 2025-01-21
**Applies To**: Innovation Nexus, Repository Analyzer, All Azure/GitHub/Notion integrations