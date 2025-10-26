# Azure OpenAI Monitoring & Operations

Establish operational excellence for Azure OpenAI Service integration with Brookside BI Innovation Nexus through comprehensive health monitoring, performance tracking, and automated incident response.

**Best for**: Operations teams, SREs, and DevOps engineers maintaining Azure OpenAI infrastructure with 99.9% availability targets.

**Version**: 1.0.0
**Last Updated**: 2025-10-26
**SLA Target**: 99.9% availability

---

## Table of Contents

1. [Health Checks](#health-checks)
2. [Performance Metrics](#performance-metrics)
3. [Log Analytics Queries](#log-analytics-queries)
4. [Alerting Rules](#alerting-rules)
5. [Dashboards](#dashboards)
6. [Maintenance Procedures](#maintenance-procedures)

---

## Health Checks

### Endpoint Availability Monitoring

**PowerShell Health Check Script**:
```powershell
# Script: Test-AzureOpenAIHealth.ps1
# Purpose: Validate Azure OpenAI endpoint availability and authentication

param(
    [Parameter(Mandatory=$true)]
    [string]$Environment # dev | staging | prod
)

$ErrorActionPreference = "Stop"

# Load environment-specific configuration
$config = @{
    dev = @{
        Endpoint = "https://aoai-brookside-dev-eastus.openai.azure.com/"
        DeploymentName = "gpt-4-turbo"
        ResourceGroup = "rg-brookside-aoai-dev"
        ServiceName = "aoai-brookside-dev-eastus"
    }
    staging = @{
        Endpoint = "https://aoai-brookside-staging-eastus.openai.azure.com/"
        DeploymentName = "gpt-4-turbo"
        ResourceGroup = "rg-brookside-aoai-staging"
        ServiceName = "aoai-brookside-staging-eastus"
    }
    prod = @{
        Endpoint = "https://aoai-brookside-prod-eastus.openai.azure.com/"
        DeploymentName = "gpt-4-turbo"
        ResourceGroup = "rg-brookside-aoai-prod"
        ServiceName = "aoai-brookside-prod-eastus"
    }
}

$cfg = $config[$Environment]
$healthStatus = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Environment = $Environment
    Checks = @()
}

# Check 1: Azure Resource Exists
Write-Host "`n[1/5] Checking Azure resource existence..." -ForegroundColor Cyan
try {
    $resource = az cognitiveservices account show `
        --name $cfg.ServiceName `
        --resource-group $cfg.ResourceGroup `
        --query "{name:name, provisioningState:properties.provisioningState, publicNetworkAccess:properties.publicNetworkAccess}" `
        -o json | ConvertFrom-Json

    if ($resource.provisioningState -eq "Succeeded") {
        $healthStatus.Checks += @{
            Name = "Resource Existence"
            Status = "Pass"
            Details = "Resource found and provisioned successfully"
        }
        Write-Host "   ✅ Resource exists and is provisioned" -ForegroundColor Green
    } else {
        throw "Resource provisioning state: $($resource.provisioningState)"
    }
} catch {
    $healthStatus.Checks += @{
        Name = "Resource Existence"
        Status = "Fail"
        Details = $_.Exception.Message
    }
    Write-Host "   ❌ Resource check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Check 2: Network Connectivity
Write-Host "`n[2/5] Checking network connectivity..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri $cfg.Endpoint -Method HEAD -TimeoutSec 10
    if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 401) {
        $healthStatus.Checks += @{
            Name = "Network Connectivity"
            Status = "Pass"
            Details = "Endpoint reachable (HTTP $($response.StatusCode))"
        }
        Write-Host "   ✅ Endpoint reachable" -ForegroundColor Green
    }
} catch {
    $healthStatus.Checks += @{
        Name = "Network Connectivity"
        Status = "Fail"
        Details = $_.Exception.Message
    }
    Write-Host "   ❌ Network connectivity failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Check 3: Authentication
Write-Host "`n[3/5] Checking authentication..." -ForegroundColor Cyan
try {
    $token = az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken -o tsv

    if ($token) {
        $healthStatus.Checks += @{
            Name = "Authentication"
            Status = "Pass"
            Details = "Azure AD token obtained successfully"
        }
        Write-Host "   ✅ Authentication successful" -ForegroundColor Green
    }
} catch {
    $healthStatus.Checks += @{
        Name = "Authentication"
        Status = "Fail"
        Details = $_.Exception.Message
    }
    Write-Host "   ❌ Authentication failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Check 4: Model Deployment Status
Write-Host "`n[4/5] Checking model deployment status..." -ForegroundColor Cyan
try {
    $deployments = az cognitiveservices account deployment list `
        --name $cfg.ServiceName `
        --resource-group $cfg.ResourceGroup `
        --query "[].{name:name, provisioningState:properties.provisioningState, capacity:properties.sku.capacity}" `
        -o json | ConvertFrom-Json

    $targetDeployment = $deployments | Where-Object { $_.name -eq $cfg.DeploymentName }

    if ($targetDeployment -and $targetDeployment.provisioningState -eq "Succeeded") {
        $healthStatus.Checks += @{
            Name = "Model Deployment"
            Status = "Pass"
            Details = "Deployment '$($cfg.DeploymentName)' active (capacity: $($targetDeployment.capacity))"
        }
        Write-Host "   ✅ Model deployment active" -ForegroundColor Green
    } else {
        throw "Deployment not found or not ready"
    }
} catch {
    $healthStatus.Checks += @{
        Name = "Model Deployment"
        Status = "Fail"
        Details = $_.Exception.Message
    }
    Write-Host "   ❌ Model deployment check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Check 5: End-to-End API Test
Write-Host "`n[5/5] Running end-to-end API test..." -ForegroundColor Cyan
try {
    $token = az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken -o tsv

    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }

    $body = @{
        messages = @(
            @{ role = "system"; content = "You are a health check assistant." },
            @{ role = "user"; content = "Respond with 'OK' if operational." }
        )
        max_tokens = 10
        temperature = 0.0
    } | ConvertTo-Json -Depth 10

    $uri = "$($cfg.Endpoint)/openai/deployments/$($cfg.DeploymentName)/chat/completions?api-version=2024-02-15-preview"
    $startTime = Get-Date
    $response = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
    $duration = (Get-Date) - $startTime

    if ($response.choices[0].message.content -match "OK") {
        $healthStatus.Checks += @{
            Name = "End-to-End API Test"
            Status = "Pass"
            Details = "API responded in $($duration.TotalMilliseconds)ms"
        }
        Write-Host "   ✅ API test passed (latency: $($duration.TotalMilliseconds)ms)" -ForegroundColor Green
    }
} catch {
    $healthStatus.Checks += @{
        Name = "End-to-End API Test"
        Status = "Fail"
        Details = $_.Exception.Message
    }
    Write-Host "   ❌ API test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Health Check Summary - $Environment Environment" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$passCount = ($healthStatus.Checks | Where-Object { $_.Status -eq "Pass" }).Count
$totalChecks = $healthStatus.Checks.Count
$healthPercentage = [math]::Round(($passCount / $totalChecks) * 100, 1)

$healthStatus.Checks | ForEach-Object {
    $icon = if ($_.Status -eq "Pass") { "✅" } else { "❌" }
    Write-Host "$icon $($_.Name): $($_.Status)" -ForegroundColor $(if ($_.Status -eq "Pass") { "Green" } else { "Red" })
}

Write-Host "`nOverall Health: $passCount/$totalChecks checks passed ($healthPercentage%)" -ForegroundColor $(if ($healthPercentage -eq 100) { "Green" } else { "Yellow" })

# Export results
$healthStatus | ConvertTo-Json -Depth 10 | Out-File "health-check-$Environment-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

# Exit with appropriate code
exit $(if ($healthPercentage -eq 100) { 0 } else { 1 })
```

**Automated Health Check Schedule**:
```yaml
# Azure DevOps Pipeline: health-check-schedule.yml
trigger: none

schedules:
- cron: "*/15 * * * *" # Every 15 minutes
  displayName: Health Check - All Environments
  branches:
    include:
    - main
  always: true

jobs:
- job: HealthCheck_Dev
  pool:
    vmImage: 'ubuntu-latest'
  steps:
  - pwsh: |
      .\Test-AzureOpenAIHealth.ps1 -Environment dev
    displayName: 'Development Health Check'

- job: HealthCheck_Staging
  pool:
    vmImage: 'ubuntu-latest'
  steps:
  - pwsh: |
      .\Test-AzureOpenAIHealth.ps1 -Environment staging
    displayName: 'Staging Health Check'

- job: HealthCheck_Prod
  pool:
    vmImage: 'ubuntu-latest'
  steps:
  - pwsh: |
      .\Test-AzureOpenAIHealth.ps1 -Environment prod
    displayName: 'Production Health Check'
    continueOnError: false # Alert on failure
```

---

## Performance Metrics

### Key Performance Indicators

| Metric | Target | Warning Threshold | Critical Threshold | Measurement |
|--------|--------|-------------------|-------------------|-------------|
| **API Latency (P95)** | <2s | >3s | >5s | Application Insights |
| **API Latency (P99)** | <4s | >6s | >10s | Application Insights |
| **Error Rate** | <1% | >3% | >5% | Log Analytics |
| **Token Usage/Day** | <30K | >40K | >50K | Cost Management |
| **Cache Hit Rate** | >40% | <30% | <20% | Application Insights |
| **Availability** | 99.9% | <99.5% | <99% | Azure Service Health |

---

### Custom Metrics Collection

**TypeScript Metrics Collector**:
```typescript
import { ApplicationInsights } from '@azure/applicationinsights-web';

/**
 * Collect comprehensive Azure OpenAI performance metrics.
 * Enables real-time monitoring and historical trend analysis.
 */
export class OpenAIMetricsCollector {
  private appInsights: ApplicationInsights;
  private readonly sampleRate: number;

  constructor(
    connectionString: string,
    sampleRate: number = 1.0 // 1.0 = 100% sampling
  ) {
    this.appInsights = new ApplicationInsights({
      config: {
        connectionString,
        enableAutoRouteTracking: true,
        samplingPercentage: sampleRate * 100
      }
    });
    this.appInsights.loadAppInsights();
    this.sampleRate = sampleRate;
  }

  /**
   * Track request metrics with detailed dimensions.
   */
  trackRequest(
    workflow: string,
    operation: string,
    success: boolean,
    duration: number,
    statusCode: number,
    promptTokens: number,
    completionTokens: number,
    cached: boolean
  ): void {
    // Track request
    this.appInsights.trackDependency({
      target: 'Azure OpenAI',
      name: operation,
      data: workflow,
      duration,
      success,
      resultCode: statusCode
    });

    // Track token usage metrics
    this.appInsights.trackMetric({
      name: 'OpenAI_PromptTokens',
      average: promptTokens,
      properties: { workflow, cached: cached.toString() }
    });

    this.appInsights.trackMetric({
      name: 'OpenAI_CompletionTokens',
      average: completionTokens,
      properties: { workflow, cached: cached.toString() }
    });

    this.appInsights.trackMetric({
      name: 'OpenAI_TotalTokens',
      average: promptTokens + completionTokens,
      properties: { workflow, cached: cached.toString() }
    });

    // Track latency distribution
    this.appInsights.trackMetric({
      name: 'OpenAI_Latency',
      average: duration,
      properties: { workflow, cached: cached.toString() }
    });

    // Track cache effectiveness
    this.appInsights.trackMetric({
      name: 'OpenAI_CacheHit',
      average: cached ? 1 : 0,
      properties: { workflow }
    });

    // Calculate cost
    const cost = this.calculateCost(promptTokens, completionTokens, cached);
    this.appInsights.trackMetric({
      name: 'OpenAI_Cost',
      average: cost,
      properties: { workflow, cached: cached.toString() }
    });
  }

  /**
   * Track error with contextual information.
   */
  trackError(
    error: Error,
    workflow: string,
    operation: string,
    statusCode: number,
    retryAttempt: number = 0
  ): void {
    this.appInsights.trackException({
      exception: error,
      properties: {
        workflow,
        operation,
        statusCode: statusCode.toString(),
        retryAttempt: retryAttempt.toString(),
        isRetryable: this.isRetryable(statusCode).toString()
      },
      severityLevel: this.getSeverityLevel(statusCode)
    });
  }

  /**
   * Track circuit breaker state changes.
   */
  trackCircuitBreakerState(
    state: 'CLOSED' | 'OPEN' | 'HALF_OPEN',
    failureCount: number,
    successCount: number
  ): void {
    this.appInsights.trackEvent({
      name: 'OpenAI_CircuitBreakerState',
      properties: {
        state,
        failureCount: failureCount.toString(),
        successCount: successCount.toString()
      }
    });

    if (state === 'OPEN') {
      this.appInsights.trackTrace({
        message: `Circuit breaker OPEN: ${failureCount} consecutive failures`,
        severityLevel: 3 // Error
      });
    }
  }

  private calculateCost(
    promptTokens: number,
    completionTokens: number,
    cached: boolean
  ): number {
    if (cached) return 0;
    return (promptTokens / 1000) * 0.01 + (completionTokens / 1000) * 0.03;
  }

  private isRetryable(statusCode: number): boolean {
    return [429, 500, 502, 503, 504].includes(statusCode);
  }

  private getSeverityLevel(statusCode: number): number {
    if (statusCode >= 500) return 3; // Error
    if (statusCode === 429) return 2; // Warning
    if (statusCode >= 400) return 1; // Informational
    return 0; // Verbose
  }
}
```

---

## Log Analytics Queries

### Pre-Built KQL Queries

#### Query 1: Request Volume by Workflow

```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
| where Category == "RequestResponse"
| where TimeGenerated > ago(24h)
| extend Workflow = tostring(Properties.workflow)
| summarize RequestCount = count() by Workflow, bin(TimeGenerated, 1h)
| render timechart
```

#### Query 2: Latency Percentiles

```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
| where Category == "RequestResponse"
| where TimeGenerated > ago(24h)
| extend DurationMs = toint(DurationMs)
| summarize
    P50 = percentile(DurationMs, 50),
    P95 = percentile(DurationMs, 95),
    P99 = percentile(DurationMs, 99),
    Max = max(DurationMs)
  by bin(TimeGenerated, 5m)
| render timechart
```

#### Query 3: Error Rate Analysis

```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
| where Category == "RequestResponse"
| where TimeGenerated > ago(24h)
| extend IsError = ResultType == "Failed"
| summarize
    TotalRequests = count(),
    ErrorRequests = countif(IsError),
    ErrorRate = (todouble(countif(IsError)) / count()) * 100
  by bin(TimeGenerated, 5m)
| render timechart
```

#### Query 4: Token Consumption Trends

```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
| where Category == "RequestResponse"
| where TimeGenerated > ago(7d)
| extend PromptTokens = toint(Properties.promptTokens)
| extend CompletionTokens = toint(Properties.completionTokens)
| extend TotalTokens = PromptTokens + CompletionTokens
| summarize
    AvgPromptTokens = avg(PromptTokens),
    AvgCompletionTokens = avg(CompletionTokens),
    AvgTotalTokens = avg(TotalTokens),
    TotalDailyTokens = sum(TotalTokens)
  by bin(TimeGenerated, 1d)
| render timechart
```

#### Query 5: Top Expensive Workflows

```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
| where Category == "RequestResponse"
| where TimeGenerated > ago(30d)
| extend Workflow = tostring(Properties.workflow)
| extend PromptTokens = toint(Properties.promptTokens)
| extend CompletionTokens = toint(Properties.completionTokens)
| extend Cost = (PromptTokens / 1000.0) * 0.01 + (CompletionTokens / 1000.0) * 0.03
| summarize
    TotalCost = sum(Cost),
    RequestCount = count(),
    AvgCostPerRequest = avg(Cost)
  by Workflow
| order by TotalCost desc
| take 10
```

#### Query 6: Cache Effectiveness

```kusto
customMetrics
| where name == "OpenAI_CacheHit"
| where timestamp > ago(7d)
| extend Workflow = tostring(customDimensions.workflow)
| summarize
    TotalRequests = count(),
    CacheHits = countif(value == 1),
    HitRate = (todouble(countif(value == 1)) / count()) * 100
  by Workflow
| order by HitRate desc
```

---

## Alerting Rules

### Critical Alerts (P0)

**Alert 1: Service Availability**
```yaml
Alert Name: Azure OpenAI - Service Unavailable
Severity: Critical (P0)
Condition: |
  AzureDiagnostics
  | where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
  | where ResultType == "Failed"
  | where ResultSignature contains "503" or ResultSignature contains "504"
  | summarize FailureCount = count() by bin(TimeGenerated, 5m)
  | where FailureCount > 10
Frequency: Every 5 minutes
Threshold: >10 failures in 5 minutes
Actions:
  - Email: consultations@brooksidebi.com
  - SMS: +1 209 487 2047
  - Teams: #innovation-nexus-alerts
  - PagerDuty: High urgency
```

**Alert 2: Authentication Failures**
```yaml
Alert Name: Azure OpenAI - Authentication Failures
Severity: Critical (P0)
Condition: |
  AzureDiagnostics
  | where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
  | where Category == "Audit"
  | where ResultType == "Failed"
  | where OperationName contains "Authentication"
  | summarize FailureCount = count() by CallerIpAddress, bin(TimeGenerated, 10m)
  | where FailureCount > 5
Frequency: Every 10 minutes
Threshold: >5 failures from same IP
Actions:
  - Email: security@brooksidebi.com
  - Block IP via NSG
  - Create Sentinel incident
```

---

### High Alerts (P1)

**Alert 3: High Latency**
```yaml
Alert Name: Azure OpenAI - High Latency (P95)
Severity: High (P1)
Condition: |
  AzureDiagnostics
  | where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
  | where Category == "RequestResponse"
  | summarize P95Latency = percentile(DurationMs, 95) by bin(TimeGenerated, 5m)
  | where P95Latency > 5000
Frequency: Every 5 minutes
Threshold: P95 latency >5 seconds
Actions:
  - Email: consultations@brooksidebi.com
  - Teams: #innovation-nexus-alerts
```

**Alert 4: Token Limit Exceeded**
```yaml
Alert Name: Azure OpenAI - Daily Token Limit
Severity: High (P1)
Condition: |
  AzureDiagnostics
  | where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
  | where TimeGenerated > ago(1d)
  | extend TotalTokens = toint(Properties.totalTokens)
  | summarize DailyTokens = sum(TotalTokens)
  | where DailyTokens > 40000
Frequency: Every 1 hour
Threshold: >40,000 tokens per day
Actions:
  - Email: consultations@brooksidebi.com
  - Throttle low-priority requests
```

---

### Medium Alerts (P2)

**Alert 5: Cache Performance Degradation**
```yaml
Alert Name: Azure OpenAI - Low Cache Hit Rate
Severity: Medium (P2)
Condition: |
  customMetrics
  | where name == "OpenAI_CacheHit"
  | where timestamp > ago(1h)
  | summarize HitRate = (todouble(countif(value == 1)) / count()) * 100
  | where HitRate < 30
Frequency: Every 1 hour
Threshold: <30% cache hit rate
Actions:
  - Email: consultations@brooksidebi.com
  - Review cache configuration
```

---

## Dashboards

### Azure Monitor Workbook Template

**Workbook JSON Configuration**:
```json
{
  "version": "Notebook/1.0",
  "items": [
    {
      "type": 1,
      "content": {
        "json": "# Azure OpenAI - Operations Dashboard\n\n**Environment**: {Environment}\n**Time Range**: {TimeRange}"
      }
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "AzureDiagnostics\n| where ResourceProvider == 'MICROSOFT.COGNITIVESERVICES'\n| where TimeGenerated > {TimeRange:start}\n| summarize\n    TotalRequests = count(),\n    SuccessRequests = countif(ResultType == 'Success'),\n    FailedRequests = countif(ResultType == 'Failed'),\n    AvgLatency = avg(DurationMs),\n    P95Latency = percentile(DurationMs, 95)\n| extend SuccessRate = (SuccessRequests * 100.0) / TotalRequests",
        "size": 4,
        "title": "Request Summary",
        "queryType": 0,
        "visualization": "tiles"
      }
    },
    {
      "type": 3,
      "content": {
        "query": "AzureDiagnostics\n| where ResourceProvider == 'MICROSOFT.COGNITIVESERVICES'\n| where TimeGenerated > {TimeRange:start}\n| summarize RequestCount = count() by bin(TimeGenerated, 5m)\n| render timechart",
        "title": "Request Volume Over Time"
      }
    },
    {
      "type": 3,
      "content": {
        "query": "AzureDiagnostics\n| where ResourceProvider == 'MICROSOFT.COGNITIVESERVICES'\n| where TimeGenerated > {TimeRange:start}\n| extend TotalTokens = toint(Properties.totalTokens)\n| summarize TotalDailyTokens = sum(TotalTokens), Cost = sum(TotalTokens) * 0.00002 by bin(TimeGenerated, 1d)\n| render timechart",
        "title": "Token Usage & Daily Cost"
      }
    }
  ]
}
```

**Dashboard Components**:
1. **Request Summary Tiles**: Total requests, success rate, avg latency, P95 latency
2. **Request Volume Chart**: Time series of requests per 5 minutes
3. **Token Usage Chart**: Daily token consumption with cost projection
4. **Latency Distribution**: Histogram of P50, P95, P99 latencies
5. **Error Rate Trend**: Error percentage over time
6. **Cache Performance**: Hit rate, savings, top cached queries
7. **Cost Analysis**: Daily/monthly spend with budget comparison

---

## Maintenance Procedures

### Monthly Maintenance Checklist

**Week 1: Performance Review**
- [ ] Review average latency trends (target: <2s P95)
- [ ] Analyze cache hit rate (target: >40%)
- [ ] Check token usage vs budget (target: <90% utilization)
- [ ] Review top 10 expensive workflows
- [ ] Optimize inefficient prompts (>3000 tokens)

**Week 2: Security Audit**
- [ ] Review RBAC role assignments (least privilege)
- [ ] Check diagnostic logging configuration (90-day retention)
- [ ] Verify network security rules (IP allowlist current)
- [ ] Test authentication flow (Managed Identity)
- [ ] Review failed authentication attempts

**Week 3: Capacity Planning**
- [ ] Analyze request volume growth (month-over-month)
- [ ] Forecast token usage for next quarter
- [ ] Evaluate model capacity (TPM limits)
- [ ] Review deployment scaling thresholds
- [ ] Plan reserved capacity purchase (if applicable)

**Week 4: Incident Response**
- [ ] Review incident response playbook
- [ ] Test alert notification channels
- [ ] Verify backup/rollback procedures
- [ ] Update on-call rotation
- [ ] Document lessons learned from previous month

---

### Model Capacity Scaling

**Manual Scaling**:
```bash
# Scale up deployment capacity (TPM)
az cognitiveservices account deployment update \
  --name aoai-brookside-prod-eastus \
  --resource-group rg-brookside-aoai-prod \
  --deployment-name gpt-4-turbo \
  --sku-capacity 50  # Increase from 30 to 50 TPM

# Verify scaling
az cognitiveservices account deployment show \
  --name aoai-brookside-prod-eastus \
  --resource-group rg-brookside-aoai-prod \
  --deployment-name gpt-4-turbo \
  --query "properties.sku.capacity"
```

**Auto-Scaling (via Azure Functions)**:
```csharp
// Azure Function: Auto-scale based on token usage
[FunctionName("AutoScaleOpenAI")]
public static async Task Run(
    [TimerTrigger("0 */5 * * * *")] TimerInfo timer,
    ILogger log)
{
    // Query token usage for last 5 minutes
    var usage = await GetTokenUsage(TimeSpan.FromMinutes(5));
    var currentCapacity = await GetCurrentCapacity();

    // Scale up if >80% utilization
    if (usage.UtilizationPercent > 80 && currentCapacity < 100)
    {
        var newCapacity = Math.Min(currentCapacity + 10, 100);
        await ScaleDeployment(newCapacity);
        log.LogInformation($"Scaled up to {newCapacity} TPM");
    }

    // Scale down if <30% utilization
    else if (usage.UtilizationPercent < 30 && currentCapacity > 10)
    {
        var newCapacity = Math.Max(currentCapacity - 10, 10);
        await ScaleDeployment(newCapacity);
        log.LogInformation($"Scaled down to {newCapacity} TPM");
    }
}
```

---

### Disaster Recovery

**Backup Strategy**:
- Azure OpenAI configurations stored in Git (Infrastructure-as-Code)
- Application cache can be rebuilt (semantic embeddings regenerated)
- Log Analytics data retained for 90 days (sufficient for audits)

**Recovery Time Objective (RTO)**: 1 hour
**Recovery Point Objective (RPO)**: 0 (stateless service)

**Disaster Recovery Steps**:
```bash
# 1. Failover to alternate region (manual)
az cognitiveservices account create \
  --name aoai-brookside-prod-westus \
  --resource-group rg-brookside-aoai-prod \
  --location westus \
  --kind OpenAI \
  --sku S0 \
  --custom-domain aoai-brookside-prod-westus \
  --assign-identity \
  --identity-type UserAssigned

# 2. Deploy model
az cognitiveservices account deployment create \
  --name aoai-brookside-prod-westus \
  --resource-group rg-brookside-aoai-prod \
  --deployment-name gpt-4-turbo \
  --model-name gpt-4 \
  --model-version turbo-2024-04-09 \
  --sku-capacity 30 \
  --sku-name Standard

# 3. Update application endpoint
az keyvault secret set \
  --vault-name kv-brookside-secrets \
  --name azure-openai-endpoint-prod \
  --value "https://aoai-brookside-prod-westus.openai.azure.com/"

# 4. Verify health
.\Test-AzureOpenAIHealth.ps1 -Environment prod
```

---

## Additional Resources

### Official Documentation
- [Azure Monitor Overview](https://learn.microsoft.com/en-us/azure/azure-monitor/)
- [Log Analytics Queries](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/get-started-queries)
- [Application Insights Metrics](https://learn.microsoft.com/en-us/azure/azure-monitor/app/metrics-explorer)

### Brookside BI Resources
- **Integration Guide**: [integration-guide.md](./integration-guide.md)
- **API Reference**: [api-reference.md](./api-reference.md)
- **Security & Compliance**: [security-compliance.md](./security-compliance.md)
- **Cost Optimization**: [cost-optimization.md](./cost-optimization.md)

### Support
- **Email**: consultations@brooksidebi.com
- **Phone**: +1 209 487 2047
- **On-Call**: +1 209 487 2047 (24/7 for P0/P1 incidents)

---

**Document Version**: 1.0.0
**Last Reviewed**: 2025-10-26
**Next Review**: 2026-01-26
**Owner**: Brookside BI Operations Team

*This operations guide establishes comprehensive monitoring, alerting, and maintenance procedures for Azure OpenAI integration, ensuring 99.9% availability and proactive incident response across Innovation Nexus workflows.*
