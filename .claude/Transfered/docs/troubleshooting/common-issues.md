---
title: Common Issues & Troubleshooting
description: Resolve production issues quickly with proven diagnostic procedures. Comprehensive troubleshooting guide covering frequent operational challenges.
tags:
  - troubleshooting
  - debugging
  - incident-response
  - diagnostics
  - runbooks
  - operations
  - production
lastUpdated: 2025-10-09
author: Agent Studio Team
audience: operators
---

# Troubleshooting Guide

## Table of Contents

- [Overview](#overview)
- [General Troubleshooting](#general-troubleshooting)
- [Workflow Issues](#workflow-issues)
- [Agent Issues](#agent-issues)
- [API Issues](#api-issues)
- [Database Issues](#database-issues)
- [Infrastructure Issues](#infrastructure-issues)
- [Integration Issues](#integration-issues)
- [Performance Issues](#performance-issues)
- [Data Issues](#data-issues)
- [Getting Help](#getting-help)

## Overview

This guide helps developers, DevOps engineers, and operators quickly diagnose and resolve common issues in Agent Studio. Each problem includes symptoms, root causes, diagnostic procedures, and step-by-step solutions.

### How to Use This Guide

1. **Identify the Problem Category**: Navigate to the relevant section based on the type of issue
2. **Match Symptoms**: Find the problem that matches your observed symptoms
3. **Run Diagnostics**: Execute the diagnostic commands to confirm the issue
4. **Apply Solutions**: Follow the step-by-step resolution procedures
5. **Prevent Recurrence**: Implement the prevention tips provided

### Escalation Path

- **P2 (Low)**: Document issue, attempt resolution using this guide
- **P1 (Medium)**: Notify team lead, escalate after 1 hour if unresolved
- **P0 (Critical)**: Immediately escalate to on-call engineer via PagerDuty

## General Troubleshooting

### Gathering Diagnostic Information

Before diving into specific issues, collect the following diagnostic information:

#### Application Logs

**Azure Container Apps**:
```bash
# View recent logs
az containerapp logs show \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --follow

# Filter by time range
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "ContainerAppConsoleLogs_CL | where TimeGenerated > ago(1h)"
```

**Application Insights**:
```bash
# Query recent exceptions
az monitor app-insights query \
  --app <app-insights-id> \
  --analytics-query "exceptions | where timestamp > ago(1h) | order by timestamp desc"

# Query request failures
az monitor app-insights query \
  --app <app-insights-id> \
  --analytics-query "requests | where success == false | where timestamp > ago(1h)"
```

#### Health Checks

```bash
# Check API health
curl https://api.agentstudio.com/health

# Check individual components
curl https://api.agentstudio.com/health/ready
curl https://api.agentstudio.com/health/live
```

#### Trace IDs

Every request generates a trace ID for distributed tracing. Include the trace ID when troubleshooting:

**From HTTP Response Headers**:
```bash
curl -v https://api.agentstudio.com/api/workflows | grep -i "traceparent"
```

**From Application Insights**:
```kusto
requests
| where timestamp > ago(1h)
| project timestamp, operation_Id, name, resultCode, duration
| order by timestamp desc
```

### Using Application Insights

#### Common KQL Queries

**Error Rate Analysis**:
```kusto
requests
| where timestamp > ago(1h)
| summarize
    Total = count(),
    Failed = countif(success == false),
    ErrorRate = 100.0 * countif(success == false) / count()
  by bin(timestamp, 5m)
| render timechart
```

**Slow Request Detection**:
```kusto
requests
| where timestamp > ago(1h)
| where duration > 5000  // Over 5 seconds
| project timestamp, name, duration, resultCode, operation_Id
| order by duration desc
```

**Dependency Failures**:
```kusto
dependencies
| where timestamp > ago(1h)
| where success == false
| summarize count() by type, target, resultCode
| order by count_ desc
```

**Exception Pattern Analysis**:
```kusto
exceptions
| where timestamp > ago(24h)
| summarize count() by type, outerMessage
| order by count_ desc
| take 10
```

## Workflow Issues

### Problem: Workflow Fails to Start

#### Symptoms
- API returns 400 Bad Request when starting workflow
- Error message: "Invalid workflow definition"
- Workflow remains in "Pending" state indefinitely

#### Common Causes
1. Invalid workflow definition schema
2. Missing required agent dependencies
3. Cosmos DB connection failure
4. Insufficient permissions

#### Diagnostic Steps

1. **Validate Workflow Definition**:
```bash
# Check workflow definition format
curl -X POST https://api.agentstudio.com/api/workflows \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @workflow-definition.json

# Expected error will indicate specific validation issues
```

2. **Check Application Logs**:
```kusto
traces
| where timestamp > ago(30m)
| where message contains "workflow" and message contains "validation"
| project timestamp, severityLevel, message
```

3. **Verify Database Connectivity**:
```bash
# Check Cosmos DB availability
az cosmosdb show \
  --name cosmos-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --query "writeLocations[0].provisioningState"
```

#### Solutions

**Invalid Schema**:
```bash
# Validate against schema
# Schema location: docs/api/workflow-schema.json

# Example valid workflow:
{
  "definition": {
    "id": "code-review-workflow",
    "name": "Code Review Workflow",
    "version": "1.0",
    "tasks": [
      {
        "id": "security-scan",
        "agentId": "security-agent",
        "dependencies": []
      }
    ]
  },
  "input": {
    "repository": "https://github.com/org/repo"
  },
  "initiatedBy": "user@example.com"
}
```

**Database Connection Issue**:
```bash
# Restart Container App
az containerapp revision restart \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --revision <latest-revision>

# Check connection string in Key Vault
az keyvault secret show \
  --vault-name kv-agentstudio-prod \
  --name CosmosDbConnectionString
```

#### Prevention
- Validate workflow definitions before submission
- Implement schema validation in CI/CD pipeline
- Monitor Cosmos DB connection pool metrics
- Set up alerts for workflow start failures

### Problem: Workflow Stuck in Pending

#### Symptoms
- Workflow status remains "Pending" for more than 5 minutes
- No task execution initiated
- No error messages in logs

#### Common Causes
1. Agent service unavailable
2. Message queue backlog
3. Deadlock in task dependency resolution
4. Missing checkpoint data

#### Diagnostic Steps

1. **Check Workflow Status**:
```bash
curl https://api.agentstudio.com/api/workflows/{workflow-id} \
  -H "Authorization: Bearer $TOKEN"
```

2. **Check Agent Service Health**:
```bash
# Python agent service
curl https://agents.agentstudio.com/health

# Check container app status
az containerapp show \
  --name agentstudio-agents \
  --resource-group rg-agentstudio-prod \
  --query "properties.runningStatus"
```

3. **Inspect Orchestrator Logs**:
```kusto
traces
| where timestamp > ago(1h)
| where customDimensions.WorkflowId == "{workflow-id}"
| where message contains "orchestrat" or message contains "pending"
| order by timestamp desc
```

#### Solutions

**Agent Service Down**:
```bash
# Restart agent service
az containerapp revision restart \
  --name agentstudio-agents \
  --resource-group rg-agentstudio-prod

# Scale up if needed
az containerapp update \
  --name agentstudio-agents \
  --resource-group rg-agentstudio-prod \
  --min-replicas 3 \
  --max-replicas 10
```

**Task Dependency Deadlock**:
```bash
# Cancel stuck workflow
curl -X POST https://api.agentstudio.com/api/workflows/{workflow-id}/cancel \
  -H "Authorization: Bearer $TOKEN"

# Review and fix dependency graph
# Check for circular dependencies in workflow definition
```

**Missing Checkpoint**:
```bash
# Check checkpoint data
curl https://api.agentstudio.com/api/workflows/{workflow-id}/checkpoints \
  -H "Authorization: Bearer $TOKEN"

# If no checkpoints, delete and restart workflow
curl -X DELETE https://api.agentstudio.com/api/workflows/{workflow-id} \
  -H "Authorization: Bearer $TOKEN"
```

#### Prevention
- Set workflow timeout limits
- Implement dependency cycle detection
- Monitor agent service availability
- Set up alerts for long-pending workflows

### Problem: Tasks Timing Out

#### Symptoms
- Tasks fail with "Timeout exceeded" error
- Duration exceeds configured limit (default 5 minutes)
- Partial results returned

#### Common Causes
1. Agent processing too slow
2. External API latency
3. Insufficient compute resources
4. Network connectivity issues

#### Diagnostic Steps

1. **Check Task Duration**:
```kusto
customEvents
| where timestamp > ago(1h)
| where name == "TaskCompleted" or name == "TaskFailed"
| extend WorkflowId = tostring(customDimensions.WorkflowId)
| extend TaskId = tostring(customDimensions.TaskId)
| extend Duration = todouble(customDimensions.Duration)
| where Duration > 300000  // Over 5 minutes (ms)
| project timestamp, WorkflowId, TaskId, Duration
```

2. **Analyze Agent Performance**:
```kusto
dependencies
| where timestamp > ago(1h)
| where type == "HTTP" and target contains "agent"
| summarize avg(duration), max(duration), count() by name
| order by avg_duration desc
```

3. **Check Resource Utilization**:
```bash
# Container App metrics
az monitor metrics list \
  --resource /subscriptions/{sub}/resourceGroups/rg-agentstudio-prod/providers/Microsoft.App/containerApps/agentstudio-agents \
  --metric "CpuUsage" \
  --start-time 2025-10-09T00:00:00Z \
  --end-time 2025-10-09T23:59:59Z \
  --aggregation Average
```

#### Solutions

**Increase Timeout**:
```json
// Update workflow definition
{
  "definition": {
    "tasks": [
      {
        "id": "long-running-task",
        "agentId": "analysis-agent",
        "timeout": "00:15:00"  // 15 minutes
      }
    ]
  }
}
```

**Scale Agent Resources**:
```bash
# Increase CPU and memory
az containerapp update \
  --name agentstudio-agents \
  --resource-group rg-agentstudio-prod \
  --cpu 2.0 \
  --memory 4Gi
```

**Optimize Agent Code**:
```python
# Python agent optimization example
import asyncio
from concurrent.futures import ThreadPoolExecutor

async def process_with_timeout(data, timeout=300):
    try:
        return await asyncio.wait_for(
            process_data(data),
            timeout=timeout
        )
    except asyncio.TimeoutError:
        # Return partial results
        return {"status": "partial", "data": get_intermediate_results()}
```

#### Prevention
- Profile agent performance regularly
- Set appropriate timeout values per task type
- Implement progress checkpoints for long tasks
- Monitor task duration metrics

### Problem: Quality Gates Failing

#### Symptoms
- Workflow completes but quality gate prevents progression
- Error: "Quality threshold not met"
- Specific metrics below required levels

#### Common Causes
1. Quality metrics below thresholds
2. Missing required artifacts
3. Test failures
4. Code coverage insufficient

#### Diagnostic Steps

1. **Review Quality Gate Results**:
```bash
curl https://api.agentstudio.com/api/workflows/{workflow-id} \
  -H "Authorization: Bearer $TOKEN" \
  | jq '.result.qualityGates'
```

2. **Check Specific Metrics**:
```kusto
customEvents
| where timestamp > ago(1h)
| where name == "QualityGateEvaluation"
| extend WorkflowId = tostring(customDimensions.WorkflowId)
| extend Gate = tostring(customDimensions.GateName)
| extend Result = tostring(customDimensions.Result)
| extend ActualValue = todouble(customDimensions.ActualValue)
| extend Threshold = todouble(customDimensions.Threshold)
| where Result == "Failed"
```

#### Solutions

**Adjust Thresholds**:
```json
// Workflow definition with quality gates
{
  "definition": {
    "qualityGates": [
      {
        "name": "code-coverage",
        "threshold": 80,  // Reduce from 90
        "metric": "coverage.percentage"
      },
      {
        "name": "security-issues",
        "threshold": 0,
        "metric": "security.highSeverity.count",
        "condition": "lessThanOrEqual"
      }
    ]
  }
}
```

**Override Quality Gate** (Emergency Only):
```bash
curl -X POST https://api.agentstudio.com/api/workflows/{workflow-id}/override-quality-gate \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "gateName": "code-coverage",
    "reason": "Emergency deployment - ticket #1234",
    "approvedBy": "manager@example.com"
  }'
```

#### Prevention
- Set realistic quality thresholds
- Monitor quality trend over time
- Implement gradual threshold increases
- Provide clear quality metric documentation

## Agent Issues

### Problem: Agent Not Responding

#### Symptoms
- Agent requests timeout
- No response from agent endpoint
- Health check fails for specific agent

#### Common Causes
1. Agent service crashed
2. Container out of memory
3. Network connectivity issue
4. Agent initialization failure

#### Diagnostic Steps

1. **Check Agent Health**:
```bash
# Direct health check
curl https://agents.agentstudio.com/health/agent/{agent-id}

# Check from Application Insights
az monitor app-insights query \
  --app <app-insights-id> \
  --analytics-query "requests | where url contains 'agent' and resultCode != 200"
```

2. **Review Agent Logs**:
```bash
az containerapp logs show \
  --name agentstudio-agents \
  --resource-group rg-agentstudio-prod \
  --follow \
  --tail 100
```

3. **Check Resource Usage**:
```kusto
performanceCounters
| where timestamp > ago(1h)
| where counter == "Memory Usage" or counter == "CPU Usage"
| summarize avg(value) by bin(timestamp, 5m), counter
| render timechart
```

#### Solutions

**Restart Agent Service**:
```bash
# Graceful restart
az containerapp revision restart \
  --name agentstudio-agents \
  --resource-group rg-agentstudio-prod

# Force restart if unresponsive
az containerapp revision deactivate \
  --name agentstudio-agents \
  --resource-group rg-agentstudio-prod \
  --revision <current-revision>
```

**Memory Issue**:
```bash
# Increase memory allocation
az containerapp update \
  --name agentstudio-agents \
  --resource-group rg-agentstudio-prod \
  --memory 8Gi

# Check for memory leaks
# Download heap dump and analyze
```

**Network Issue**:
```bash
# Test connectivity from API to agent service
az containerapp exec \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --command "curl -v https://agents.agentstudio.com/health"

# Check VNet/subnet configuration
az network vnet show \
  --name vnet-agentstudio-prod \
  --resource-group rg-agentstudio-prod
```

#### Prevention
- Implement agent health monitoring
- Set up auto-restart policies
- Configure resource limits appropriately
- Monitor agent initialization time

### Problem: Agent Returns Errors

#### Symptoms
- Agent returns 500 Internal Server Error
- Error messages in agent responses
- Inconsistent behavior across requests

#### Common Causes
1. Invalid input parameters
2. Missing dependencies
3. API quota exceeded (Azure OpenAI)
4. Configuration error

#### Diagnostic Steps

1. **Check Error Details**:
```bash
# Get recent errors
curl https://api.agentstudio.com/api/workflows/{workflow-id} \
  -H "Authorization: Bearer $TOKEN" \
  | jq '.tasks[] | select(.status == "Failed") | .error'
```

2. **Review Exception Logs**:
```kusto
exceptions
| where timestamp > ago(1h)
| where cloud_RoleName == "agentstudio-agents"
| project timestamp, type, outerMessage, innermostMessage
| order by timestamp desc
```

3. **Validate Agent Configuration**:
```bash
# Check configuration in Key Vault
az keyvault secret show \
  --vault-name kv-agentstudio-prod \
  --name AgentConfiguration

# Verify Azure OpenAI deployment
az cognitiveservices account deployment show \
  --name openai-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --deployment-name gpt-4
```

#### Solutions

**Invalid Input**:
```python
# Add input validation to agent
from pydantic import BaseModel, validator

class AgentInput(BaseModel):
    text: str
    parameters: dict

    @validator('text')
    def validate_text(cls, v):
        if not v or len(v.strip()) == 0:
            raise ValueError("Text cannot be empty")
        return v

# Use in agent
try:
    validated_input = AgentInput(**request_data)
except ValidationError as e:
    return {"error": str(e), "status": "invalid_input"}
```

**Configuration Fix**:
```bash
# Update agent configuration
az keyvault secret set \
  --vault-name kv-agentstudio-prod \
  --name AgentConfiguration \
  --value '{
    "azure_openai_endpoint": "https://openai-prod.openai.azure.com/",
    "deployment_name": "gpt-4",
    "api_version": "2024-02-15-preview"
  }'

# Restart to pick up changes
az containerapp revision restart \
  --name agentstudio-agents \
  --resource-group rg-agentstudio-prod
```

**Quota Exceeded**:
```bash
# Check current quota usage
az cognitiveservices account deployment show \
  --name openai-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --deployment-name gpt-4 \
  --query "properties.rateLimits"

# Implement retry with exponential backoff
```

#### Prevention
- Implement robust input validation
- Monitor API quota usage
- Use circuit breaker pattern
- Log detailed error context

### Problem: Agent Performance Degradation

#### Symptoms
- Response times increasing over time
- Throughput decreasing
- CPU usage climbing steadily

#### Common Causes
1. Memory leak
2. Connection pool exhaustion
3. Inefficient processing logic
4. External API slowdown

#### Diagnostic Steps

1. **Monitor Performance Trends**:
```kusto
requests
| where timestamp > ago(24h)
| where url contains "agent"
| summarize
    avg_duration = avg(duration),
    p95_duration = percentile(duration, 95),
    count = count()
  by bin(timestamp, 1h)
| render timechart
```

2. **Check Memory Usage**:
```bash
# View memory metrics
az monitor metrics list \
  --resource /subscriptions/{sub}/resourceGroups/rg-agentstudio-prod/providers/Microsoft.App/containerApps/agentstudio-agents \
  --metric "WorkingSetBytes" \
  --aggregation Average \
  --interval PT1H
```

3. **Profile Agent Code**:
```python
# Add profiling to agent
import cProfile
import pstats
from io import StringIO

def profile_agent_execution():
    profiler = cProfile.Profile()
    profiler.enable()

    # Agent execution
    result = execute_agent_task()

    profiler.disable()
    s = StringIO()
    stats = pstats.Stats(profiler, stream=s).sort_stats('cumulative')
    stats.print_stats()

    print(s.getvalue())
    return result
```

#### Solutions

**Memory Leak**:
```python
# Fix common memory leak patterns
import gc
import weakref

class Agent:
    def __init__(self):
        self._cache = weakref.WeakValueDictionary()

    def process(self, data):
        result = self._expensive_operation(data)

        # Explicitly clean up
        del data
        gc.collect()

        return result
```

**Connection Pool**:
```python
# Configure connection pooling properly
import httpx

# Reuse client across requests
http_client = httpx.AsyncClient(
    limits=httpx.Limits(
        max_keepalive_connections=20,
        max_connections=100,
        keepalive_expiry=30
    )
)

async def call_api(url, data):
    async with http_client:
        response = await http_client.post(url, json=data)
        return response.json()
```

**Scale Horizontally**:
```bash
# Increase replica count
az containerapp update \
  --name agentstudio-agents \
  --resource-group rg-agentstudio-prod \
  --min-replicas 5 \
  --max-replicas 20
```

#### Prevention
- Regular performance testing
- Memory profiling in staging
- Implement resource cleanup
- Monitor key performance indicators

## API Issues

### Problem: 401 Unauthorized

#### Symptoms
- API returns 401 status code
- Error: "Authentication failed"
- Requests rejected immediately

#### Common Causes
1. Missing or invalid access token
2. Token expired
3. Incorrect authentication header format
4. Azure AD configuration issue

#### Diagnostic Steps

1. **Verify Token Format**:
```bash
# Decode JWT token
echo $TOKEN | cut -d. -f2 | base64 -d | jq

# Check expiration
jq -r '.exp' <<< $(echo $TOKEN | cut -d. -f2 | base64 -d)
date -d @$(jq -r '.exp' <<< $(echo $TOKEN | cut -d. -f2 | base64 -d))
```

2. **Check Authentication Logs**:
```kusto
requests
| where timestamp > ago(1h)
| where resultCode == 401
| project timestamp, url, client_IP, operation_Id
| order by timestamp desc
```

3. **Verify Azure AD Configuration**:
```bash
# Check app registration
az ad app show --id <app-id>

# Verify API permissions
az ad app permission list --id <app-id>
```

#### Solutions

**Obtain New Token**:
```bash
# Get token using Azure CLI
az account get-access-token \
  --resource https://api.agentstudio.com \
  --query accessToken -o tsv

# Or using client credentials
curl -X POST https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id={client-id}" \
  -d "client_secret={client-secret}" \
  -d "scope=api://agentstudio/.default" \
  -d "grant_type=client_credentials"
```

**Correct Header Format**:
```bash
# Correct format
curl https://api.agentstudio.com/api/workflows \
  -H "Authorization: Bearer $TOKEN"

# NOT "Authorization: $TOKEN"
# NOT "Authorization: Bearer: $TOKEN"
```

**Fix Azure AD Configuration**:
```bash
# Grant API permissions
az ad app permission add \
  --id <app-id> \
  --api <api-id> \
  --api-permissions <permission-id>=Scope

# Admin consent
az ad app permission admin-consent --id <app-id>
```

#### Prevention
- Implement token refresh logic
- Monitor token expiration
- Document authentication requirements
- Set up test credentials in CI/CD

### Problem: 403 Forbidden

#### Symptoms
- API returns 403 status code
- Error: "Insufficient permissions"
- Authenticated but cannot access resource

#### Common Causes
1. Missing role assignment
2. Insufficient API permissions
3. Resource-level access restriction
4. Conditional access policy blocking request

#### Diagnostic Steps

1. **Check User Roles**:
```bash
# List role assignments
az role assignment list \
  --assignee <user-or-app-id> \
  --resource-group rg-agentstudio-prod

# Check specific resource
az role assignment list \
  --scope /subscriptions/{sub}/resourceGroups/rg-agentstudio-prod/providers/Microsoft.App/containerApps/agentstudio-api
```

2. **Review Authorization Logs**:
```kusto
requests
| where timestamp > ago(1h)
| where resultCode == 403
| extend UserId = tostring(customDimensions.UserId)
| extend Resource = tostring(customDimensions.Resource)
| project timestamp, UserId, Resource, url
```

#### Solutions

**Grant Role Assignment**:
```bash
# Assign Contributor role
az role assignment create \
  --assignee <user-or-app-id> \
  --role "Contributor" \
  --resource-group rg-agentstudio-prod

# Or custom role
az role assignment create \
  --assignee <user-or-app-id> \
  --role "Agent Studio Operator" \
  --resource-group rg-agentstudio-prod
```

**Update API Permissions**:
```bash
# Check required permissions in app manifest
az ad app show --id <app-id> --query "requiredResourceAccess"

# Add missing permissions
az ad app permission add \
  --id <app-id> \
  --api 00000003-0000-0000-c000-000000000000 \
  --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope
```

#### Prevention
- Document required roles and permissions
- Implement least privilege access
- Regular access reviews
- Clear error messages for authorization failures

### Problem: 429 Too Many Requests

#### Symptoms
- API returns 429 status code
- Error: "Rate limit exceeded"
- Retry-After header present in response

#### Common Causes
1. Exceeded API rate limits
2. Too many concurrent requests
3. Inefficient API usage pattern
4. Missing rate limit handling

#### Diagnostic Steps

1. **Check Rate Limit Headers**:
```bash
curl -v https://api.agentstudio.com/api/workflows \
  -H "Authorization: Bearer $TOKEN" \
  | grep -i "x-rate-limit"

# Response headers:
# X-RateLimit-Limit: 1000
# X-RateLimit-Remaining: 0
# X-RateLimit-Reset: 1696780800
# Retry-After: 60
```

2. **Analyze Request Patterns**:
```kusto
requests
| where timestamp > ago(1h)
| where resultCode == 429
| summarize count() by bin(timestamp, 1m), client_IP
| render timechart
```

#### Solutions

**Implement Retry Logic**:
```typescript
// TypeScript example with exponential backoff
async function callApiWithRetry(url: string, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(url);

      if (response.status === 429) {
        const retryAfter = parseInt(response.headers.get('Retry-After') || '60');
        await sleep(retryAfter * 1000);
        continue;
      }

      return response;
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await sleep(Math.pow(2, i) * 1000);
    }
  }
}
```

**Optimize Request Pattern**:
```typescript
// Batch requests instead of individual calls
async function batchGetWorkflows(workflowIds: string[]) {
  // Instead of: workflowIds.map(id => fetch(`/api/workflows/${id}`))

  const response = await fetch('/api/workflows/batch', {
    method: 'POST',
    body: JSON.stringify({ ids: workflowIds })
  });

  return response.json();
}
```

**Request Rate Limit Increase**:
```bash
# Contact support or update configuration
az containerapp update \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --set-env-vars "RATE_LIMIT_REQUESTS_PER_MINUTE=5000"
```

#### Prevention
- Implement client-side rate limiting
- Use batch endpoints when available
- Cache responses appropriately
- Monitor rate limit metrics

### Problem: 500 Internal Server Error

#### Symptoms
- API returns 500 status code
- Generic error message
- Intermittent failures

#### Common Causes
1. Unhandled exception in code
2. Database connection failure
3. External service unavailable
4. Memory or resource exhaustion

#### Diagnostic Steps

1. **Find Exception Details**:
```kusto
exceptions
| where timestamp > ago(1h)
| where cloud_RoleName == "agentstudio-api"
| project timestamp, type, outerMessage, innermostMessage, operation_Id
| order by timestamp desc
| take 20
```

2. **Check Dependencies**:
```kusto
dependencies
| where timestamp > ago(1h)
| where success == false
| summarize count() by type, target, resultCode
```

3. **Review Request Context**:
```kusto
requests
| where timestamp > ago(1h)
| where resultCode == 500
| join kind=leftouter exceptions on operation_Id
| project timestamp, url, duration, type, outerMessage
```

#### Solutions

**Unhandled Exception**:
```csharp
// Add global exception handling
app.UseExceptionHandler(errorApp =>
{
    errorApp.Run(async context =>
    {
        var exceptionHandler = context.Features.Get<IExceptionHandlerFeature>();
        var error = exceptionHandler?.Error;

        _logger.LogError(error, "Unhandled exception");

        context.Response.StatusCode = 500;
        await context.Response.WriteAsJsonAsync(new
        {
            error = "An internal error occurred",
            traceId = Activity.Current?.Id
        });
    });
});
```

**Database Connection**:
```bash
# Check Cosmos DB status
az cosmosdb show \
  --name cosmos-agentstudio-prod \
  --resource-group rg-agentstudio-prod

# Test connectivity
az containerapp exec \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --command "curl https://cosmos-agentstudio-prod.documents.azure.com"

# Restart if connection pool exhausted
az containerapp revision restart \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod
```

#### Prevention
- Implement comprehensive error handling
- Add health checks for dependencies
- Monitor exception rates
- Set up alerting for 500 errors

## Database Issues

### Problem: Cosmos DB Throttling (429)

#### Symptoms
- 429 status codes from Cosmos DB
- Error: "Request rate is large"
- Increased request latency
- Failed database operations

#### Common Causes
1. Exceeded provisioned RU/s
2. Hot partition key
3. Inefficient queries
4. Burst traffic patterns

#### Diagnostic Steps

1. **Check RU Consumption**:
```bash
# View RU metrics
az monitor metrics list \
  --resource /subscriptions/{sub}/resourceGroups/rg-agentstudio-prod/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-agentstudio-prod \
  --metric "TotalRequests" \
  --filter "StatusCode eq '429'" \
  --aggregation Count
```

2. **Analyze Query Performance**:
```kusto
dependencies
| where timestamp > ago(1h)
| where type == "Azure DocumentDB"
| where resultCode == 429
| extend RequestCharge = todouble(customDimensions.requestCharge)
| summarize
    count(),
    avg(RequestCharge),
    max(RequestCharge)
  by target, data
```

3. **Check Partition Distribution**:
```bash
# Query partition metrics
az cosmosdb sql container show \
  --account-name cosmos-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --database-name agentstudio \
  --name workflows \
  --query "resource.partitionKey"
```

#### Solutions

**Increase Throughput**:
```bash
# Increase manual throughput
az cosmosdb sql database throughput update \
  --account-name cosmos-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --name agentstudio \
  --throughput 10000

# Or enable autoscale
az cosmosdb sql database throughput update \
  --account-name cosmos-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --name agentstudio \
  --max-throughput 10000
```

**Optimize Queries**:
```csharp
// Add proper indexing
var indexingPolicy = new IndexingPolicy
{
    IndexingMode = IndexingMode.Consistent,
    IncludedPaths = { new IncludedPath { Path = "/*" } },
    ExcludedPaths = {
        new ExcludedPath { Path = "/metadata/*" },
        new ExcludedPath { Path = "/_etag/?" }
    }
};

// Use efficient query patterns
var query = container.GetItemQueryIterator<Workflow>(
    new QueryDefinition("SELECT * FROM c WHERE c.status = @status AND c.createdAt > @date")
        .WithParameter("@status", "Running")
        .WithParameter("@date", DateTime.UtcNow.AddDays(-1)),
    requestOptions: new QueryRequestOptions
    {
        PartitionKey = new PartitionKey(workflowId),
        MaxItemCount = 100
    }
);
```

**Fix Hot Partition**:
```csharp
// Use compound partition key
// Instead of: partitionKey: /userId
// Use: partitionKey: /userId/date

public class Workflow
{
    [JsonProperty("id")]
    public string Id { get; set; }

    [JsonProperty("userId")]
    public string UserId { get; set; }

    [JsonProperty("date")]
    public string Date { get; set; }  // YYYY-MM-DD

    // Computed partition key
    [JsonProperty("partitionKey")]
    public string PartitionKey => $"{UserId}/{Date}";
}
```

**Implement Retry Logic**:
```csharp
// Handle throttling with exponential backoff
var cosmosClientOptions = new CosmosClientOptions
{
    MaxRetryAttemptsOnRateLimitedRequests = 9,
    MaxRetryWaitTimeOnRateLimitedRequests = TimeSpan.FromSeconds(30)
};

var client = new CosmosClient(connectionString, cosmosClientOptions);
```

#### Prevention
- Monitor RU consumption trends
- Design appropriate partition keys
- Index only required fields
- Use autoscale throughput
- Set up RU alerts

### Problem: Slow Queries

#### Symptoms
- Query execution time > 1 second
- High RU consumption
- Timeout errors on complex queries

#### Common Causes
1. Missing or inefficient indexes
2. Cross-partition queries
3. Large result sets without pagination
4. Complex JOIN operations

#### Diagnostic Steps

1. **Identify Slow Queries**:
```kusto
dependencies
| where timestamp > ago(1h)
| where type == "Azure DocumentDB"
| where duration > 1000  // Over 1 second
| extend Query = tostring(customDimensions.query)
| extend RequestCharge = todouble(customDimensions.requestCharge)
| project timestamp, duration, RequestCharge, Query
| order by duration desc
```

2. **Analyze Query Plan**:
```csharp
// Enable query metrics
var queryRequestOptions = new QueryRequestOptions
{
    PopulateIndexMetrics = true
};

FeedIterator<Workflow> iterator = container.GetItemQueryIterator<Workflow>(
    queryDefinition,
    requestOptions: queryRequestOptions
);

while (iterator.HasMoreResults)
{
    FeedResponse<Workflow> response = await iterator.ReadNextAsync();
    Console.WriteLine($"Index Metrics: {response.IndexMetrics}");
    Console.WriteLine($"Request Charge: {response.RequestCharge}");
}
```

#### Solutions

**Add Composite Indexes**:
```json
// Cosmos DB indexing policy
{
  "indexingPolicy": {
    "compositeIndexes": [
      [
        { "path": "/status", "order": "ascending" },
        { "path": "/createdAt", "order": "descending" }
      ],
      [
        { "path": "/userId", "order": "ascending" },
        { "path": "/status", "order": "ascending" }
      ]
    ]
  }
}
```

**Optimize Query**:
```csharp
// BAD: Cross-partition query
var workflows = await container.GetItemQueryIterator<Workflow>(
    "SELECT * FROM c WHERE c.status = 'Running'"
).ReadNextAsync();

// GOOD: Single partition query with projection
var workflows = await container.GetItemQueryIterator<WorkflowSummary>(
    new QueryDefinition("SELECT c.id, c.status, c.createdAt FROM c WHERE c.status = @status")
        .WithParameter("@status", "Running"),
    requestOptions: new QueryRequestOptions
    {
        PartitionKey = new PartitionKey(userId),
        MaxItemCount = 50
    }
).ReadNextAsync();
```

**Implement Pagination**:
```csharp
// Proper pagination
public async Task<PagedResult<Workflow>> GetWorkflowsAsync(
    string continuationToken = null,
    int pageSize = 100)
{
    var queryRequestOptions = new QueryRequestOptions
    {
        MaxItemCount = pageSize
    };

    var query = container.GetItemQueryIterator<Workflow>(
        queryDefinition,
        continuationToken: continuationToken,
        requestOptions: queryRequestOptions
    );

    var response = await query.ReadNextAsync();

    return new PagedResult<Workflow>
    {
        Items = response.ToList(),
        ContinuationToken = response.ContinuationToken
    };
}
```

#### Prevention
- Design queries with indexing in mind
- Always use pagination
- Avoid SELECT *
- Monitor query performance metrics

### Problem: Connection Failures

#### Symptoms
- "Could not connect to Cosmos DB" errors
- Intermittent connection timeouts
- Operations fail with network errors

#### Common Causes
1. Network connectivity issues
2. Firewall blocking connections
3. Invalid connection string
4. SSL/TLS certificate issues

#### Diagnostic Steps

1. **Test Connectivity**:
```bash
# From container app
az containerapp exec \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --command "curl -v https://cosmos-agentstudio-prod.documents.azure.com"

# Check DNS resolution
az containerapp exec \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --command "nslookup cosmos-agentstudio-prod.documents.azure.com"
```

2. **Verify Firewall Rules**:
```bash
# Check Cosmos DB firewall
az cosmosdb show \
  --name cosmos-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --query "ipRules"

# Check virtual network rules
az cosmosdb show \
  --name cosmos-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --query "virtualNetworkRules"
```

3. **Validate Connection String**:
```bash
# Get connection string from Key Vault
az keyvault secret show \
  --vault-name kv-agentstudio-prod \
  --name CosmosDbConnectionString \
  --query "value" -o tsv

# Test connection with Azure CLI
az cosmosdb sql database list \
  --account-name cosmos-agentstudio-prod \
  --resource-group rg-agentstudio-prod
```

#### Solutions

**Update Firewall Rules**:
```bash
# Add IP address to allow list
az cosmosdb update \
  --name cosmos-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --ip-range-filter "40.112.0.0/16,13.65.0.0/16"

# Or allow all Azure services
az cosmosdb update \
  --name cosmos-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --enable-public-network true
```

**Fix Connection String**:
```bash
# Update connection string in Key Vault
NEW_CONNECTION_STRING=$(az cosmosdb keys list \
  --name cosmos-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --type connection-strings \
  --query "connectionStrings[0].connectionString" -o tsv)

az keyvault secret set \
  --vault-name kv-agentstudio-prod \
  --name CosmosDbConnectionString \
  --value "$NEW_CONNECTION_STRING"

# Restart app to pick up new value
az containerapp revision restart \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod
```

**Configure Private Endpoint** (Production):
```bash
# Create private endpoint
az network private-endpoint create \
  --name pe-cosmos-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --vnet-name vnet-agentstudio-prod \
  --subnet snet-data \
  --private-connection-resource-id $(az cosmosdb show -n cosmos-agentstudio-prod -g rg-agentstudio-prod --query id -o tsv) \
  --group-id Sql \
  --connection-name cosmos-connection
```

#### Prevention
- Use private endpoints in production
- Monitor connection health
- Implement connection retry logic
- Regular connection string rotation

## Infrastructure Issues

### Problem: Container App Not Starting

#### Symptoms
- Container app stuck in "Provisioning" state
- Pods fail to start
- Health checks failing
- Application not accessible

#### Common Causes
1. Image pull failures
2. Insufficient resources
3. Configuration errors
4. Health check misconfiguration

#### Diagnostic Steps

1. **Check Container App Status**:
```bash
# View app status
az containerapp show \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --query "properties.runningStatus"

# Check revisions
az containerapp revision list \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --query "[].{Name:name, Status:properties.healthState, Replicas:properties.replicas}"
```

2. **View Container Logs**:
```bash
# Get startup logs
az containerapp logs show \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --tail 100

# Check system logs
az containerapp logs show \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --type system
```

3. **Check Events**:
```bash
# View events via Azure Monitor
az monitor activity-log list \
  --resource-group rg-agentstudio-prod \
  --offset 1h \
  --query "[?contains(resourceId, 'agentstudio-api')]"
```

#### Solutions

**Image Pull Failure**:
```bash
# Verify container registry access
az acr login --name acragentstudioprod

# Check image exists
az acr repository show-tags \
  --name acragentstudioprod \
  --repository agentstudio/api \
  --orderby time_desc \
  --top 5

# Grant managed identity pull access
az role assignment create \
  --assignee $(az containerapp show -n agentstudio-api -g rg-agentstudio-prod --query "identity.principalId" -o tsv) \
  --role AcrPull \
  --scope $(az acr show -n acragentstudioprod --query id -o tsv)
```

**Resource Limits**:
```bash
# Increase resources
az containerapp update \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --cpu 2.0 \
  --memory 4Gi

# Check quota limits
az containerapp env show \
  --name env-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --query "properties.workloadProfiles"
```

**Health Check Configuration**:
```bash
# Update health probes
az containerapp update \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --set-env-vars "ASPNETCORE_URLS=http://+:8080" \
  --ingress-transport http \
  --target-port 8080

# Configure health probes via ARM template or Bicep
```

#### Prevention
- Test images before deployment
- Set appropriate resource limits
- Configure graceful startup periods
- Monitor container app health

### Problem: High Memory Usage

#### Symptoms
- Memory usage > 80% consistently
- OutOfMemory errors
- Container restarts due to OOM
- Performance degradation

#### Common Causes
1. Memory leaks in application code
2. Large object retention
3. Inefficient caching
4. Undersized container

#### Diagnostic Steps

1. **Monitor Memory Trends**:
```bash
# View memory metrics
az monitor metrics list \
  --resource /subscriptions/{sub}/resourceGroups/rg-agentstudio-prod/providers/Microsoft.App/containerApps/agentstudio-api \
  --metric "WorkingSetBytes" \
  --aggregation Average Maximum \
  --interval PT1H
```

2. **Check for Memory Leaks**:
```kusto
performanceCounters
| where timestamp > ago(24h)
| where counter == "Private Bytes" or counter == "Gen 2 heap size"
| summarize avg(value), max(value) by bin(timestamp, 1h), counter
| render timechart
```

3. **Analyze Memory Dump**:
```bash
# For .NET applications
# Enable dumps on OOM
az containerapp update \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --set-env-vars "COMPlus_DbgEnableMiniDump=1" "COMPlus_DbgMiniDumpType=4"

# Analyze with dotnet-dump
dotnet-dump analyze <dump-file>
> dumpheap -stat
> gcroot <address>
```

#### Solutions

**Fix Memory Leak**:
```csharp
// Common leak pattern: Event handlers
public class WorkflowService : IDisposable
{
    private readonly IEventBus _eventBus;

    public WorkflowService(IEventBus eventBus)
    {
        _eventBus = eventBus;
        _eventBus.OnWorkflowCompleted += HandleWorkflowCompleted;
    }

    public void Dispose()
    {
        // Important: Unsubscribe!
        _eventBus.OnWorkflowCompleted -= HandleWorkflowCompleted;
    }
}
```

**Optimize Caching**:
```csharp
// Use memory cache with size limits
services.AddMemoryCache(options =>
{
    options.SizeLimit = 1024; // Limit to 1024 items
    options.CompactionPercentage = 0.25; // Compact 25% when limit reached
});

// Set size on cache entries
_cache.Set(key, value, new MemoryCacheEntryOptions
{
    Size = 1,
    SlidingExpiration = TimeSpan.FromMinutes(5),
    AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(1)
});
```

**Increase Memory**:
```bash
# Scale up container
az containerapp update \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --memory 8Gi
```

**Enable GC Server Mode** (.NET):
```xml
<!-- In .csproj -->
<PropertyGroup>
  <ServerGarbageCollection>true</ServerGarbageCollection>
  <ConcurrentGarbageCollection>true</ConcurrentGarbageCollection>
</PropertyGroup>
```

#### Prevention
- Regular memory profiling
- Implement proper dispose patterns
- Use weak references for caches
- Monitor GC metrics

### Problem: High CPU Usage

#### Symptoms
- CPU usage > 80% sustained
- Slow request processing
- Increased latency
- Throttling or timeouts

#### Common Causes
1. Inefficient algorithms
2. Synchronous blocking operations
3. Excessive logging
4. CPU-bound operations

#### Diagnostic Steps

1. **Monitor CPU Metrics**:
```bash
az monitor metrics list \
  --resource /subscriptions/{sub}/resourceGroups/rg-agentstudio-prod/providers/Microsoft.App/containerApps/agentstudio-api \
  --metric "CpuUsage" \
  --aggregation Average Maximum
```

2. **Profile Application**:
```csharp
// Add performance counters
using System.Diagnostics;

var cpuCounter = new PerformanceCounter(
    "Processor",
    "% Processor Time",
    "_Total"
);

_logger.LogInformation("CPU Usage: {CpuUsage}%", cpuCounter.NextValue());
```

3. **Identify Hot Paths**:
```kusto
requests
| where timestamp > ago(1h)
| where duration > 1000
| summarize count(), avg(duration) by name
| order by count_ desc
```

#### Solutions

**Optimize Code**:
```csharp
// BAD: Synchronous blocking
var result = HttpClient.GetStringAsync(url).Result;  // Blocks thread

// GOOD: Async all the way
var result = await HttpClient.GetStringAsync(url);

// BAD: Inefficient LINQ
var items = allItems.Where(x => x.IsActive).ToList()
                   .Where(x => x.Priority > 5).ToList();

// GOOD: Single enumeration
var items = allItems
    .Where(x => x.IsActive && x.Priority > 5)
    .ToList();
```

**Reduce Logging Overhead**:
```json
// appsettings.json
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning",  // Changed from Information
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
```

**Scale Horizontally**:
```bash
# Add more replicas
az containerapp update \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --min-replicas 3 \
  --max-replicas 10
```

**Offload CPU Work**:
```csharp
// Move CPU-intensive work to background
services.AddHostedService<WorkflowProcessorService>();

public class WorkflowProcessorService : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await foreach (var workflow in _queue.Reader.ReadAllAsync(stoppingToken))
        {
            await ProcessWorkflowAsync(workflow);
        }
    }
}
```

#### Prevention
- Performance testing in staging
- Code reviews for performance
- Async patterns throughout
- Monitor CPU trends

### Problem: Network Connectivity

#### Symptoms
- Intermittent connection failures
- DNS resolution errors
- Timeouts connecting to services
- SSL/TLS handshake failures

#### Common Causes
1. VNet misconfiguration
2. NSG blocking traffic
3. DNS issues
4. Service endpoint problems

#### Diagnostic Steps

1. **Test Connectivity**:
```bash
# From container app
az containerapp exec \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --command "curl -v https://cosmos-agentstudio-prod.documents.azure.com"

# Test DNS
az containerapp exec \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --command "nslookup cosmos-agentstudio-prod.documents.azure.com"

# Trace route
az containerapp exec \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --command "traceroute cosmos-agentstudio-prod.documents.azure.com"
```

2. **Check NSG Rules**:
```bash
# List NSG rules
az network nsg rule list \
  --nsg-name nsg-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --query "[].{Name:name, Priority:priority, Access:access, Direction:direction, DestinationPortRange:destinationPortRange}"
```

3. **Verify VNet Configuration**:
```bash
# Check VNet integration
az containerapp show \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --query "properties.vnetConfiguration"

# Check subnet
az network vnet subnet show \
  --vnet-name vnet-agentstudio-prod \
  --name snet-apps \
  --resource-group rg-agentstudio-prod
```

#### Solutions

**Fix NSG Rules**:
```bash
# Add allow rule for Cosmos DB
az network nsg rule create \
  --nsg-name nsg-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --name AllowCosmosDB \
  --priority 100 \
  --direction Outbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 443 \
  --destination-address-prefixes "AzureCosmosDB"
```

**Configure Service Endpoints**:
```bash
# Enable service endpoint on subnet
az network vnet subnet update \
  --vnet-name vnet-agentstudio-prod \
  --name snet-apps \
  --resource-group rg-agentstudio-prod \
  --service-endpoints "Microsoft.AzureCosmosDB" "Microsoft.Storage" "Microsoft.KeyVault"
```

**Fix DNS**:
```bash
# Check DNS servers
az network vnet show \
  --name vnet-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --query "dhcpOptions"

# Use Azure DNS
az network vnet update \
  --name vnet-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --dns-servers ""  # Empty = use Azure DNS
```

#### Prevention
- Document network architecture
- Test connectivity in staging
- Monitor network metrics
- Regular security reviews

## Integration Issues

### Problem: Azure OpenAI Errors

#### Symptoms
- 401/403 errors from Azure OpenAI
- Rate limit (429) errors
- Model not found errors
- Timeout on completion requests

#### Common Causes
1. Invalid API key
2. Quota exceeded
3. Wrong deployment name
4. Region capacity issues

#### Diagnostic Steps

1. **Verify Configuration**:
```bash
# Check OpenAI resource
az cognitiveservices account show \
  --name openai-agentstudio-prod \
  --resource-group rg-agentstudio-prod

# List deployments
az cognitiveservices account deployment list \
  --name openai-agentstudio-prod \
  --resource-group rg-agentstudio-prod
```

2. **Check Quota Usage**:
```bash
# View quota
az cognitiveservices usage list \
  --name openai-agentstudio-prod \
  --resource-group rg-agentstudio-prod

# Check metrics
az monitor metrics list \
  --resource /subscriptions/{sub}/resourceGroups/rg-agentstudio-prod/providers/Microsoft.CognitiveServices/accounts/openai-agentstudio-prod \
  --metric "TokenTransaction" \
  --aggregation Total
```

3. **Test API Call**:
```bash
# Get API key
API_KEY=$(az cognitiveservices account keys list \
  --name openai-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --query "key1" -o tsv)

# Test completion
curl https://openai-agentstudio-prod.openai.azure.com/openai/deployments/gpt-4/chat/completions?api-version=2024-02-15-preview \
  -H "Content-Type: application/json" \
  -H "api-key: $API_KEY" \
  -d '{
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 50
  }'
```

#### Solutions

**Update API Configuration**:
```csharp
// Correct configuration
var openAIClient = new OpenAIClient(
    new Uri("https://openai-agentstudio-prod.openai.azure.com/"),
    new AzureKeyCredential(apiKey)
);

var chatClient = openAIClient.GetChatClient("gpt-4");  // Deployment name
```

**Handle Rate Limits**:
```csharp
// Implement retry with exponential backoff
public async Task<ChatCompletion> GetCompletionWithRetryAsync(
    ChatClient client,
    IEnumerable<ChatMessage> messages,
    int maxRetries = 3)
{
    for (int i = 0; i < maxRetries; i++)
    {
        try
        {
            return await client.CompleteChatAsync(messages);
        }
        catch (RequestFailedException ex) when (ex.Status == 429)
        {
            var retryAfter = ex.Response.Headers.TryGetValue("Retry-After", out var value)
                ? int.Parse(value)
                : (int)Math.Pow(2, i);

            await Task.Delay(TimeSpan.FromSeconds(retryAfter));
        }
    }

    throw new Exception("Max retries exceeded");
}
```

**Request Quota Increase**:
```bash
# Contact Azure support or use portal
# Navigate to: Azure OpenAI > Quotas > Request quota increase
```

#### Prevention
- Monitor token usage trends
- Implement rate limiting
- Use multiple deployments for failover
- Cache responses when appropriate

### Problem: SignalR Connection Failures

#### Symptoms
- WebSocket connection fails
- Falling back to long polling
- "Cannot connect to SignalR hub" errors
- CORS errors in browser

#### Common Causes
1. CORS misconfiguration
2. Authentication token issues
3. SignalR service unavailable
4. Client library version mismatch

#### Diagnostic Steps

1. **Check SignalR Service**:
```bash
# View service status
az signalr show \
  --name signalr-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --query "provisioningState"

# Check connection strings
az signalr key list \
  --name signalr-agentstudio-prod \
  --resource-group rg-agentstudio-prod
```

2. **Test WebSocket**:
```javascript
// Browser console
const connection = new signalR.HubConnectionBuilder()
    .withUrl("https://api.agentstudio.com/hubs/workflow", {
        skipNegotiation: true,
        transport: signalR.HttpTransportType.WebSockets
    })
    .configureLogging(signalR.LogLevel.Trace)
    .build();

await connection.start();
```

3. **Check CORS**:
```bash
# Test preflight request
curl -X OPTIONS https://api.agentstudio.com/hubs/workflow \
  -H "Origin: https://app.agentstudio.com" \
  -H "Access-Control-Request-Method: POST" \
  -v
```

#### Solutions

**Fix CORS Configuration**:
```csharp
// Program.cs
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins(
                "https://app.agentstudio.com",
                "https://localhost:3000"
            )
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials();  // Required for SignalR
    });
});

app.UseCors();  // Before UseAuthorization
app.UseAuthorization();
```

**Fix Authentication**:
```typescript
// Client-side token provider
const connection = new signalR.HubConnectionBuilder()
    .withUrl("https://api.agentstudio.com/hubs/workflow", {
        accessTokenFactory: async () => {
            const token = await getAccessToken();
            return token;
        }
    })
    .withAutomaticReconnect()
    .build();
```

**Configure SignalR Service**:
```bash
# Update CORS on SignalR service
az signalr cors add \
  --name signalr-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --allowed-origins "https://app.agentstudio.com"

# Enable WebSocket
az signalr update \
  --name signalr-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --service-mode Default
```

#### Prevention
- Test SignalR in all browsers
- Monitor connection success rate
- Document CORS requirements
- Version client and server libraries together

### Problem: Redis Connection Issues

#### Symptoms
- "Unable to connect to Redis" errors
- Timeout on cache operations
- Intermittent cache misses
- Connection pool exhausted

#### Common Causes
1. Redis service unavailable
2. Connection string incorrect
3. Network connectivity
4. SSL/TLS configuration

#### Diagnostic Steps

1. **Check Redis Status**:
```bash
# View Redis cache status
az redis show \
  --name redis-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --query "provisioningState"

# Check metrics
az monitor metrics list \
  --resource /subscriptions/{sub}/resourceGroups/rg-agentstudio-prod/providers/Microsoft.Cache/redis/redis-agentstudio-prod \
  --metric "connectedclients" \
  --aggregation Average
```

2. **Test Connection**:
```bash
# Get connection info
az redis list-keys \
  --name redis-agentstudio-prod \
  --resource-group rg-agentstudio-prod

# Test with redis-cli
redis-cli -h redis-agentstudio-prod.redis.cache.windows.net \
  -p 6380 \
  -a <access-key> \
  --tls \
  PING
```

3. **Check Application Logs**:
```kusto
traces
| where timestamp > ago(1h)
| where message contains "redis" or message contains "cache"
| where severityLevel >= 3
| project timestamp, message, severityLevel
```

#### Solutions

**Fix Connection String**:
```csharp
// Correct configuration
services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = "redis-agentstudio-prod.redis.cache.windows.net:6380,password={key},ssl=True,abortConnect=False";
    options.InstanceName = "agentstudio:";
});
```

**Increase Connection Pool**:
```csharp
// Configure connection multiplexer
var configurationOptions = ConfigurationOptions.Parse(
    "redis-agentstudio-prod.redis.cache.windows.net:6380"
);
configurationOptions.Password = redisKey;
configurationOptions.Ssl = true;
configurationOptions.AbortOnConnectFail = false;
configurationOptions.ConnectTimeout = 5000;
configurationOptions.SyncTimeout = 5000;

var multiplexer = await ConnectionMultiplexer.ConnectAsync(configurationOptions);
```

**Handle Transient Failures**:
```csharp
// Graceful degradation
public async Task<T> GetFromCacheAsync<T>(string key)
{
    try
    {
        var value = await _cache.GetStringAsync(key);
        return value != null ? JsonSerializer.Deserialize<T>(value) : default;
    }
    catch (RedisConnectionException ex)
    {
        _logger.LogWarning(ex, "Redis unavailable, falling back to database");
        return await _database.GetAsync<T>(key);
    }
}
```

#### Prevention
- Monitor Redis connection metrics
- Implement circuit breaker
- Configure connection resilience
- Regular failover testing

## Performance Issues

### Problem: Slow Response Times

#### Symptoms
- API response times > 2 seconds
- P95 latency increasing
- User complaints about slowness
- Timeout errors

#### Common Causes
1. Database query performance
2. External API latency
3. Inefficient code paths
4. Missing caching

#### Diagnostic Steps

1. **Identify Slow Endpoints**:
```kusto
requests
| where timestamp > ago(24h)
| summarize
    avg_duration = avg(duration),
    p95_duration = percentile(duration, 95),
    count = count()
  by name
| where p95_duration > 2000  // Over 2 seconds
| order by p95_duration desc
```

2. **Analyze Request Timeline**:
```kusto
requests
| where timestamp > ago(1h)
| where name == "POST /api/workflows/execute"
| join kind=leftouter (
    dependencies
    | where timestamp > ago(1h)
) on operation_Id
| project
    timestamp,
    request_duration = duration,
    dependency_type = type1,
    dependency_target = target,
    dependency_duration = duration1
| order by timestamp desc
```

3. **Check Database Performance**:
```kusto
dependencies
| where timestamp > ago(1h)
| where type == "Azure DocumentDB"
| extend RequestCharge = todouble(customDimensions.requestCharge)
| summarize
    avg_duration = avg(duration),
    avg_ru = avg(RequestCharge),
    count = count()
  by data
| order by avg_duration desc
```

#### Solutions

**Implement Caching**:
```csharp
// Response caching
[ResponseCache(Duration = 60, VaryByQueryKeys = new[] { "status" })]
[HttpGet]
public async Task<ActionResult<IReadOnlyList<Workflow>>> GetWorkflows(
    [FromQuery] string? status = null)
{
    return Ok(await _orchestrator.ListWorkflowsAsync(status));
}

// Distributed caching
public async Task<Workflow> GetWorkflowAsync(string id)
{
    var cacheKey = $"workflow:{id}";

    var cached = await _cache.GetStringAsync(cacheKey);
    if (cached != null)
    {
        return JsonSerializer.Deserialize<Workflow>(cached);
    }

    var workflow = await _orchestrator.GetWorkflowStatusAsync(id);

    await _cache.SetStringAsync(
        cacheKey,
        JsonSerializer.Serialize(workflow),
        new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5)
        }
    );

    return workflow;
}
```

**Optimize Database Queries** (see Database Issues section)

**Implement Parallel Processing**:
```csharp
// Sequential (slow)
foreach (var task in workflow.Tasks)
{
    await ProcessTaskAsync(task);
}

// Parallel (fast)
await Task.WhenAll(
    workflow.Tasks
        .Where(t => t.CanRunInParallel)
        .Select(t => ProcessTaskAsync(t))
);
```

**Add CDN for Static Assets**:
```bash
# Configure Azure CDN
az cdn endpoint create \
  --name cdn-agentstudio-prod \
  --profile-name cdn-profile-agentstudio \
  --resource-group rg-agentstudio-prod \
  --origin app.agentstudio.com \
  --origin-host-header app.agentstudio.com
```

#### Prevention
- Set performance budgets
- Regular performance testing
- Monitor P95/P99 latency
- Implement performance SLOs

### Problem: Low Throughput

#### Symptoms
- Requests per second declining
- Queue length increasing
- Long wait times for processing
- Concurrent request limit reached

#### Common Causes
1. Insufficient replicas
2. Thread pool exhaustion
3. Synchronous blocking operations
4. Database connection pool limits

#### Diagnostic Steps

1. **Measure Throughput**:
```kusto
requests
| where timestamp > ago(24h)
| summarize rps = count() by bin(timestamp, 1m)
| render timechart
```

2. **Check Concurrency**:
```kusto
customMetrics
| where timestamp > ago(1h)
| where name == "ActiveRequests"
| summarize avg(value), max(value) by bin(timestamp, 5m)
| render timechart
```

3. **Analyze Thread Pool**:
```csharp
// Add metrics
ThreadPool.GetAvailableThreads(out int workerThreads, out int completionPortThreads);
_logger.LogInformation(
    "Available threads - Worker: {Worker}, IO: {IO}",
    workerThreads,
    completionPortThreads
);
```

#### Solutions

**Scale Out**:
```bash
# Increase replicas
az containerapp update \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --min-replicas 5 \
  --max-replicas 20 \
  --scale-rule-name http-rule \
  --scale-rule-type http \
  --scale-rule-http-concurrency 10
```

**Optimize Thread Usage**:
```csharp
// Avoid blocking async
// BAD
public IActionResult GetWorkflow(string id)
{
    var workflow = _orchestrator.GetWorkflowStatusAsync(id).Result;  // Blocks
    return Ok(workflow);
}

// GOOD
public async Task<IActionResult> GetWorkflow(string id)
{
    var workflow = await _orchestrator.GetWorkflowStatusAsync(id);
    return Ok(workflow);
}
```

**Increase Connection Pools**:
```csharp
// HTTP client
services.AddHttpClient("agents", client =>
{
    client.BaseAddress = new Uri("https://agents.agentstudio.com");
})
.ConfigurePrimaryHttpMessageHandler(() => new SocketsHttpHandler
{
    PooledConnectionLifetime = TimeSpan.FromMinutes(2),
    PooledConnectionIdleTimeout = TimeSpan.FromMinutes(1),
    MaxConnectionsPerServer = 100
});

// Database
services.AddDbContext<AppDbContext>(options =>
{
    options.UseNpgsql(connectionString, npgsqlOptions =>
    {
        npgsqlOptions.MaxBatchSize(100);
        npgsqlOptions.EnableRetryOnFailure(3);
    });
});
```

#### Prevention
- Load testing before production
- Monitor throughput metrics
- Auto-scaling configuration
- Capacity planning

### Problem: Memory Pressure

#### Symptoms
- Frequent garbage collections
- GC pause times > 100ms
- Gen 2 collections increasing
- Memory allocation rate high

#### Common Causes
1. Large object allocations
2. String concatenation in loops
3. Boxing/unboxing
4. Inefficient collections usage

#### Diagnostic Steps

1. **Monitor GC Metrics**:
```kusto
performanceCounters
| where timestamp > ago(1h)
| where counter contains "GC"
| summarize avg(value) by bin(timestamp, 5m), counter
| render timechart
```

2. **Analyze Allocations**:
```csharp
// Use dotnet-counters
// dotnet-counters monitor --process-id <pid> --counters System.Runtime

// Key metrics:
// - Allocation Rate (MB/sec)
// - GC Heap Size
// - Gen 0/1/2 GC Count
```

#### Solutions

**Reduce Allocations**:
```csharp
// BAD: Allocates string per iteration
string result = "";
foreach (var item in items)
{
    result += item.ToString();  // New string allocated each time
}

// GOOD: Single allocation
var sb = new StringBuilder();
foreach (var item in items)
{
    sb.Append(item.ToString());
}
string result = sb.ToString();

// BETTER: Use string.Join
string result = string.Join("", items.Select(i => i.ToString()));
```

**Use Object Pooling**:
```csharp
// Configure array pool
services.AddSingleton<ArrayPool<byte>>(ArrayPool<byte>.Shared);

// Use in code
public async Task ProcessDataAsync(byte[] data)
{
    var buffer = ArrayPool<byte>.Shared.Rent(4096);
    try
    {
        // Use buffer
        await ProcessBufferAsync(buffer);
    }
    finally
    {
        ArrayPool<byte>.Shared.Return(buffer);
    }
}
```

**Optimize LINQ**:
```csharp
// BAD: Multiple enumerations
var activeItems = items.Where(x => x.IsActive).ToList();
var count = activeItems.Count();
var first = activeItems.FirstOrDefault();

// GOOD: Single enumeration
var activeItems = items.Where(x => x.IsActive).ToList();
var count = activeItems.Count;
var first = activeItems.FirstOrDefault();

// BETTER: Avoid ToList when possible
var count = items.Count(x => x.IsActive);
var first = items.FirstOrDefault(x => x.IsActive);
```

#### Prevention
- Allocation profiling in development
- Code reviews for allocations
- Benchmark hot paths
- Monitor GC metrics

## Data Issues

### Problem: Data Inconsistency

#### Symptoms
- Workflow shows different status across queries
- Missing task results
- Duplicate entries
- Stale data displayed

#### Common Causes
1. Eventual consistency in Cosmos DB
2. Cache invalidation issues
3. Concurrent update conflicts
4. Missing transactions

#### Diagnostic Steps

1. **Check Consistency Level**:
```bash
# Verify Cosmos DB consistency
az cosmosdb show \
  --name cosmos-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --query "consistencyPolicy"
```

2. **Identify Conflicts**:
```kusto
traces
| where timestamp > ago(1h)
| where message contains "conflict" or message contains "etag"
| project timestamp, severityLevel, message
```

3. **Check Cache Staleness**:
```csharp
// Log cache age
public async Task<Workflow> GetWorkflowAsync(string id)
{
    var cached = await _cache.GetAsync<CachedWorkflow>($"workflow:{id}");
    if (cached != null)
    {
        var age = DateTime.UtcNow - cached.CachedAt;
        _logger.LogInformation("Cache hit, age: {Age}s", age.TotalSeconds);

        if (age.TotalSeconds > 60)
        {
            _logger.LogWarning("Stale cache data for workflow {Id}", id);
        }
    }
}
```

#### Solutions

**Use Stronger Consistency**:
```csharp
// Configure session consistency for read-your-writes
var cosmosClientOptions = new CosmosClientOptions
{
    ConsistencyLevel = ConsistencyLevel.Session
};

var client = new CosmosClient(connectionString, cosmosClientOptions);

// Or strong consistency for critical reads
var response = await container.ReadItemAsync<Workflow>(
    id,
    new PartitionKey(partitionKey),
    new ItemRequestOptions
    {
        ConsistencyLevel = ConsistencyLevel.Strong
    }
);
```

**Implement Optimistic Concurrency**:
```csharp
// Use ETags for conflict detection
public async Task<Workflow> UpdateWorkflowAsync(Workflow workflow)
{
    try
    {
        var response = await container.ReplaceItemAsync(
            workflow,
            workflow.Id,
            new PartitionKey(workflow.PartitionKey),
            new ItemRequestOptions
            {
                IfMatchEtag = workflow.ETag  // Only update if ETag matches
            }
        );

        return response.Resource;
    }
    catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.PreconditionFailed)
    {
        // ETag mismatch - conflict
        _logger.LogWarning("Concurrent update conflict for workflow {Id}", workflow.Id);

        // Re-read and retry
        var current = await GetWorkflowAsync(workflow.Id);
        var merged = MergeWorkflows(current, workflow);
        return await UpdateWorkflowAsync(merged);
    }
}
```

**Cache Invalidation Strategy**:
```csharp
// Invalidate cache on updates
public async Task UpdateWorkflowAsync(Workflow workflow)
{
    await _repository.UpdateAsync(workflow);

    // Invalidate cache
    await _cache.RemoveAsync($"workflow:{workflow.Id}");

    // Or update cache
    await _cache.SetAsync(
        $"workflow:{workflow.Id}",
        workflow,
        TimeSpan.FromMinutes(5)
    );
}
```

#### Prevention
- Understand consistency tradeoffs
- Implement proper concurrency control
- Document cache invalidation strategy
- Monitor data consistency metrics

### Problem: Missing Data

#### Symptoms
- 404 errors for existing resources
- Workflow results not found
- Task outputs missing
- Historical data unavailable

#### Common Causes
1. Accidental deletion
2. Retention policy triggered
3. Replication lag
4. Backup restoration needed

#### Diagnostic Steps

1. **Check Soft Delete**:
```bash
# Check if soft delete is enabled
az cosmosdb show \
  --name cosmos-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --query "backupPolicy"

# Check deleted items (if soft delete enabled)
# Query with SDK using change feed
```

2. **Review Activity Logs**:
```bash
# Check for deletion events
az monitor activity-log list \
  --resource-group rg-agentstudio-prod \
  --offset 24h \
  --query "[?contains(operationName.value, 'delete')]"
```

3. **Check Retention Policy**:
```csharp
// Review TTL settings
var containerProperties = await container.ReadContainerAsync();
Console.WriteLine($"TTL: {containerProperties.Resource.DefaultTimeToLive}");
```

#### Solutions

**Restore from Backup**:
```bash
# List available backups
az cosmosdb sql container retrieve-latest-backup-time \
  --account-name cosmos-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --database-name agentstudio \
  --container-name workflows \
  --location "East US"

# Restore (contact Azure support for full restore)
# Or use point-in-time restore if enabled
```

**Disable TTL for Critical Data**:
```csharp
// Update container to disable TTL
var containerProperties = new ContainerProperties
{
    Id = "workflows",
    PartitionKeyPath = "/id",
    DefaultTimeToLive = -1  // Disable TTL
};

await database.CreateContainerIfNotExistsAsync(containerProperties);
```

**Implement Soft Delete Pattern**:
```csharp
// Instead of deleting, mark as deleted
public class Workflow
{
    public string Id { get; set; }
    public bool IsDeleted { get; set; }
    public DateTime? DeletedAt { get; set; }
}

public async Task DeleteWorkflowAsync(string id)
{
    var workflow = await GetWorkflowAsync(id);
    workflow.IsDeleted = true;
    workflow.DeletedAt = DateTime.UtcNow;

    await container.ReplaceItemAsync(
        workflow,
        id,
        new PartitionKey(workflow.PartitionKey)
    );
}

// Cleanup job to permanently delete after retention period
public async Task CleanupDeletedWorkflowsAsync()
{
    var cutoff = DateTime.UtcNow.AddDays(-30);

    var query = container.GetItemQueryIterator<Workflow>(
        new QueryDefinition(
            "SELECT * FROM c WHERE c.isDeleted = true AND c.deletedAt < @cutoff"
        ).WithParameter("@cutoff", cutoff)
    );

    while (query.HasMoreResults)
    {
        var response = await query.ReadNextAsync();
        foreach (var workflow in response)
        {
            await container.DeleteItemAsync<Workflow>(
                workflow.Id,
                new PartitionKey(workflow.PartitionKey)
            );
        }
    }
}
```

#### Prevention
- Enable continuous backup
- Implement soft delete
- Regular backup verification
- Document retention policies

### Problem: Data Migration Failures

#### Symptoms
- Migration script errors
- Partial data migration
- Schema validation failures
- Rollback needed

#### Common Causes
1. Schema incompatibility
2. Data transformation errors
3. Insufficient RU capacity
4. Network timeouts

#### Diagnostic Steps

1. **Validate Schema**:
```csharp
// Check data compatibility
public async Task<bool> ValidateSchemaAsync()
{
    var query = container.GetItemQueryIterator<dynamic>(
        "SELECT TOP 10 * FROM c"
    );

    var response = await query.ReadNextAsync();
    foreach (var item in response)
    {
        try
        {
            var workflow = JsonSerializer.Deserialize<Workflow>(
                item.ToString()
            );
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Schema validation failed: {Item}", item);
            return false;
        }
    }

    return true;
}
```

2. **Check Migration Logs**:
```kusto
traces
| where timestamp > ago(1h)
| where message contains "migration"
| order by timestamp desc
```

#### Solutions

**Implement Safe Migration**:
```csharp
public async Task MigrateWorkflowsAsync()
{
    var query = container.GetItemQueryIterator<dynamic>(
        "SELECT * FROM c WHERE NOT IS_DEFINED(c.version) OR c.version < 2"
    );

    var migratedCount = 0;
    var failedCount = 0;

    while (query.HasMoreResults)
    {
        var response = await query.ReadNextAsync();

        foreach (var item in response)
        {
            try
            {
                var migrated = MigrateToV2(item);

                await container.UpsertItemAsync(
                    migrated,
                    new PartitionKey(migrated.PartitionKey)
                );

                migratedCount++;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to migrate item {Id}", item.id);
                failedCount++;
            }
        }

        // Rate limiting to avoid throttling
        await Task.Delay(100);
    }

    _logger.LogInformation(
        "Migration complete. Migrated: {Migrated}, Failed: {Failed}",
        migratedCount,
        failedCount
    );
}

private dynamic MigrateToV2(dynamic oldVersion)
{
    return new
    {
        id = oldVersion.id,
        version = 2,
        status = oldVersion.state ?? "Unknown",  // Renamed field
        tasks = oldVersion.steps ?? new List<object>(),  // Renamed field
        createdAt = oldVersion.timestamp ?? DateTime.UtcNow
    };
}
```

**Rollback Procedure**:
```csharp
// Keep backup before migration
public async Task BackupBeforeMigrationAsync()
{
    var backupContainer = database.GetContainer("workflows_backup");

    var query = container.GetItemQueryIterator<dynamic>(
        "SELECT * FROM c"
    );

    while (query.HasMoreResults)
    {
        var response = await query.ReadNextAsync();

        foreach (var item in response)
        {
            await backupContainer.CreateItemAsync(
                item,
                new PartitionKey(item.partitionKey)
            );
        }
    }
}

// Rollback if migration fails
public async Task RollbackMigrationAsync()
{
    var backupContainer = database.GetContainer("workflows_backup");

    var query = backupContainer.GetItemQueryIterator<dynamic>(
        "SELECT * FROM c"
    );

    while (query.HasMoreResults)
    {
        var response = await query.ReadNextAsync();

        foreach (var item in response)
        {
            await container.UpsertItemAsync(
                item,
                new PartitionKey(item.partitionKey)
            );
        }
    }
}
```

#### Prevention
- Test migrations in staging
- Implement schema versioning
- Always backup before migration
- Use feature flags for gradual rollout

## Getting Help

### When to Escalate

#### Severity Levels

**P0 - Critical (Immediate Escalation)**
- Complete service outage
- Data loss or corruption
- Security breach
- Financial impact

**Actions**:
- Page on-call engineer immediately
- Create incident channel: `/incident create P0 [description]`
- Notify leadership
- Follow incident response runbook

**P1 - High (Escalate within 15 minutes)**
- Major functionality degraded
- Multiple component failures
- Significant performance degradation
- Security vulnerability detected

**Actions**:
- Notify on-call engineer
- Create incident channel
- Post in #incidents Slack channel
- Update status page

**P2 - Medium (Escalate within 1 hour)**
- Minor functionality impaired
- Single component failure
- Elevated error rates
- Non-critical bug

**Actions**:
- Attempt resolution using this guide
- Document troubleshooting steps
- Escalate if unresolved after 1 hour
- Create GitHub issue for tracking

### Support Resources

#### Documentation
- **Architecture Docs**: `docs/architecture.md`
- **API Reference**: `docs/api/rest-api.md`
- **Deployment Guide**: `docs/runbooks/deployment-procedures.md`
- **Runbooks**: `operations/runbooks/`

#### Monitoring Dashboards
- **Application Insights**: https://portal.azure.com → Application Insights
- **Azure Portal**: https://portal.azure.com → Resource Groups → rg-agentstudio-prod
- **Grafana**: https://grafana.agentstudio.com
- **Status Page**: https://status.agentstudio.com

#### Communication Channels
- **Slack - #incidents**: Critical issues and outages
- **Slack - #engineering**: General engineering questions
- **Slack - #oncall**: On-call engineer direct line
- **GitHub Issues**: Bug tracking and feature requests
- **Email - engineering@agentstudio.com**: Engineering team

#### Emergency Contacts
- **On-call Engineer**: PagerDuty (24/7)
- **Engineering Manager**: manager@agentstudio.com
- **DevOps Lead**: devops-lead@agentstudio.com
- **Security Team**: security@agentstudio.com

### Providing Information for Support

When escalating an issue, include the following information:

#### Required Information
1. **Problem Description**
   - What is happening?
   - When did it start?
   - What is the business impact?

2. **Diagnostic Data**
   ```
   - Trace ID or Operation ID
   - Timestamp of failure
   - User/account affected
   - Error messages and stack traces
   ```

3. **Reproduction Steps**
   ```
   1. Step-by-step actions to reproduce
   2. Expected behavior
   3. Actual behavior
   4. Frequency (always/intermittent)
   ```

4. **Environment Details**
   ```
   - Environment (dev/staging/prod)
   - Component/service affected
   - Recent changes or deployments
   - Current resource utilization
   ```

5. **Troubleshooting Attempted**
   ```
   - Steps already taken
   - Results of diagnostic commands
   - Relevant log excerpts
   - Configuration checked
   ```

#### Helpful Commands for Gathering Information

```bash
# Get trace information
az monitor app-insights query \
  --app <app-insights-id> \
  --analytics-query "requests | where operation_Id == '{trace-id}'" \
  --output table

# Recent errors
az monitor app-insights query \
  --app <app-insights-id> \
  --analytics-query "exceptions | where timestamp > ago(1h) | take 20" \
  --output json > errors.json

# System health snapshot
az containerapp show \
  --name agentstudio-api \
  --resource-group rg-agentstudio-prod \
  --query "{Status:properties.runningStatus, Health:properties.healthState, Replicas:properties.latestRevisionFdr}" \
  --output json > health.json

# Resource metrics
az monitor metrics list \
  --resource /subscriptions/{sub}/resourceGroups/rg-agentstudio-prod/providers/Microsoft.App/containerApps/agentstudio-api \
  --metric "CpuUsage" "WorkingSetBytes" \
  --aggregation Average \
  --interval PT5M \
  --output table
```

### Knowledge Base Articles

For detailed solutions to specific scenarios, refer to:

- [Workflow Execution Patterns](../guides/developer/workflow-creation.md)
- [Performance Optimization Guide](../performance/PERFORMANCE_ANALYSIS.md)
- [Security Best Practices](../guides/developer/security-implementation.md)
- [Database Query Optimization](../database/query-patterns.md)
- [Incident Response Runbook](../../operations/runbooks/incident-response.md)

### Creating Support Tickets

**Internal (GitHub Issues)**:
```bash
# Use GitHub CLI
gh issue create \
  --title "Production: Workflow API slow response times" \
  --body "$(cat issue-template.md)" \
  --label "bug,production,p1"
```

**External (Azure Support)**:
```bash
# Create support request via CLI
az support tickets create \
  --ticket-name "workflow-api-performance" \
  --title "Performance degradation in Container App" \
  --description "API response times increased from 200ms to 5s" \
  --severity "2" \
  --problem-classification "/subscriptions/{sub}/providers/Microsoft.Support/services/container_app_service/problemClassifications/performance"
```

---

## Quick Reference Card

### Common Commands

```bash
# Health check
curl https://api.agentstudio.com/health

# View logs
az containerapp logs show -n agentstudio-api -g rg-agentstudio-prod --follow

# Restart service
az containerapp revision restart -n agentstudio-api -g rg-agentstudio-prod

# Check metrics
az monitor metrics list --resource <resource-id> --metric "CpuUsage"

# Query Application Insights
az monitor app-insights query --app <id> --analytics-query "exceptions | take 20"
```

### Emergency Procedures

1. **Service Down**: Restart → Check logs → Verify dependencies → Escalate
2. **High Error Rate**: Check exceptions → Review recent changes → Rollback if needed
3. **Performance Issue**: Check metrics → Scale out → Optimize queries → Add caching
4. **Security Incident**: Isolate → Preserve evidence → Notify security → Follow runbook

### Key Metrics to Monitor

- **Availability**: > 99.9%
- **P95 Latency**: < 2 seconds
- **Error Rate**: < 1%
- **CPU Usage**: < 70%
- **Memory Usage**: < 80%
- **Database RU/s**: Within provisioned limits

---

**Last Updated**: 2025-10-09
**Version**: 1.0.0
**Maintained By**: Engineering Team

For urgent production issues, contact the on-call engineer via PagerDuty immediately.
