---
title: Monitoring & Observability Guide
description: Ensure system reliability with comprehensive monitoring. Implement distributed tracing, metrics collection, and proactive alerting for 99.9%+ uptime.
tags:
  - monitoring
  - observability
  - azure-monitor
  - metrics
  - alerting
  - reliability
  - kql
lastUpdated: 2025-10-09
author: Agent Studio Team
audience: operators
---

# Monitoring & Observability

Comprehensive guide for monitoring Agent Studio's health, performance, and business metrics in production.

## Overview

Agent Studio uses a multi-layer observability stack built on Azure Monitor and OpenTelemetry:

- **Distributed Tracing** - End-to-end request tracking across services
- **Metrics Collection** - Performance, business, and infrastructure metrics
- **Structured Logging** - Centralized log aggregation with Log Analytics
- **Real-Time Dashboards** - Live monitoring with SignalR and Application Insights
- **Automated Alerting** - Proactive incident detection and response

## Architecture

```
Application → OpenTelemetry SDK → Application Insights → Azure Monitor
                                        ↓
                            Dashboards, Alerts, Workbooks
```

### Key Components

| Component | Purpose | Retention |
|-----------|---------|-----------|
| **Application Insights** | APM, traces, exceptions | 90 days |
| **Log Analytics** | Structured logs, KQL queries | 90 days |
| **Azure Monitor Metrics** | Time-series metrics | 93 days |
| **Workspace Insights** | Custom workbooks | Unlimited |

## Distributed Tracing

### Trace Context Propagation

Agent Studio uses W3C Trace Context for correlation across services:

```
traceparent: 00-{trace-id}-{span-id}-{trace-flags}
```

**Example trace flow:**
1. User request → React app (span 1)
2. API call → .NET Orchestration API (span 2)
3. Agent invocation → Python Agent Runtime (span 3)
4. AI inference → Azure OpenAI (span 4)

### Viewing Traces

**Application Insights - End-to-End Transaction:**
```kql
requests
| where timestamp > ago(1h)
| where name == "POST /api/workflows/execute"
| project operation_Id, timestamp, duration, resultCode
| join kind=inner (
    dependencies
    | where timestamp > ago(1h)
) on operation_Id
| project timestamp, duration, resultCode, dependency=name, dependencyDuration=duration
| order by timestamp desc
```

**Trace Waterfall View:**
```kql
let traceId = "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01";
union requests, dependencies, traces, exceptions
| where operation_Id == traceId
| project timestamp, itemType, name, duration, success
| order by timestamp asc
```

## Key Metrics

### Application Metrics

#### **Request Metrics**
- **Request Rate** - Requests per second
- **Response Time** - P50, P95, P99 latency
- **Error Rate** - 5xx errors per second
- **Success Rate** - Percentage of successful requests

**KQL Query:**
```kql
requests
| where timestamp > ago(1h)
| summarize
    RequestCount = count(),
    P50 = percentile(duration, 50),
    P95 = percentile(duration, 95),
    P99 = percentile(duration, 99),
    ErrorRate = countif(resultCode >= 500) * 100.0 / count()
by bin(timestamp, 5m)
| render timechart
```

#### **Workflow Metrics**
- **Workflows Started** - Total workflow executions
- **Workflows Completed** - Successfully finished
- **Workflows Failed** - Failed with errors
- **Average Execution Time** - Mean workflow duration
- **Active Workflows** - Currently running

**Custom Metrics (C#):**
```csharp
using System.Diagnostics.Metrics;

public class WorkflowMetrics
{
    private readonly Meter _meter;
    private readonly Counter<long> _workflowsStarted;
    private readonly Counter<long> _workflowsCompleted;
    private readonly Counter<long> _workflowsFailed;
    private readonly Histogram<double> _executionDuration;

    public WorkflowMetrics(IMeterFactory meterFactory)
    {
        _meter = meterFactory.Create("AgentStudio.Workflows");

        _workflowsStarted = _meter.CreateCounter<long>(
            "workflows.started",
            description: "Total workflows started");

        _workflowsCompleted = _meter.CreateCounter<long>(
            "workflows.completed",
            description: "Total workflows completed successfully");

        _workflowsFailed = _meter.CreateCounter<long>(
            "workflows.failed",
            description: "Total workflows failed");

        _executionDuration = _meter.CreateHistogram<double>(
            "workflows.execution.duration",
            unit: "ms",
            description: "Workflow execution duration");
    }

    public void RecordWorkflowStarted(string workflowType, string workspaceId)
    {
        _workflowsStarted.Add(1,
            new KeyValuePair<string, object?>("workflow.type", workflowType),
            new KeyValuePair<string, object?>("workspace.id", workspaceId));
    }

    public void RecordWorkflowCompleted(string workflowType, double durationMs)
    {
        _workflowsCompleted.Add(1,
            new KeyValuePair<string, object?>("workflow.type", workflowType));
        _executionDuration.Record(durationMs,
            new KeyValuePair<string, object?>("workflow.type", workflowType));
    }
}
```

#### **Agent Metrics**
- **Agent Invocations** - Total agent calls
- **Agent Success Rate** - Percentage successful
- **Agent Response Time** - P95 latency
- **Active Agents** - Currently executing

#### **AI Service Metrics**
- **LLM Requests** - Total inference calls
- **Token Usage** - Input + output tokens
- **Cost per Request** - Estimated cost
- **Response Time** - LLM latency

### Infrastructure Metrics

#### **Container Apps**
- **CPU Usage** - Percentage utilization
- **Memory Usage** - MB used / available
- **Replica Count** - Number of instances
- **HTTP Request Queue** - Queued requests

**Metrics Explorer Query:**
```
Resource: Container App (capp-agent-orchestrator)
Metric: CPU Usage
Aggregation: Average
Split by: Revision
Time range: Last 24 hours
```

#### **Cosmos DB**
- **Request Units** - RU/s consumed
- **Throttled Requests** - 429 errors
- **Request Latency** - P99 latency
- **Document Count** - Total documents

**KQL Query:**
```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.DOCUMENTDB"
| where Category == "DataPlaneRequests"
| where statusCode_s == 429 // Throttled
| summarize ThrottledCount = count() by bin(TimeGenerated, 5m)
| render timechart
```

#### **Redis Cache**
- **Cache Hits** - Successful cache reads
- **Cache Misses** - Cache read failures
- **Hit Rate** - Percentage of hits
- **Evicted Keys** - Keys removed due to memory

### Business Metrics

#### **User Engagement**
- **Daily Active Users** - Unique users per day
- **Workflows per User** - Average usage
- **Session Duration** - Time spent in app

#### **System Health**
- **Availability** - Uptime percentage (target: 99.9%)
- **MTBF** - Mean time between failures
- **MTTR** - Mean time to recovery

## Dashboards

### 1. Real-Time Operations Dashboard

**Application Insights - Live Metrics:**
- Incoming Request Rate (req/sec)
- Outgoing Request Rate (req/sec)
- Overall Health (CPU, Memory, Network)
- Sample Telemetry (recent requests, dependencies, exceptions)

**Access:** Azure Portal → Application Insights → Live Metrics

### 2. Workflow Execution Dashboard

**Custom Workbook** (`workbooks/workflow-execution.json`):

```json
{
  "version": "Notebook/1.0",
  "items": [
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "customMetrics\n| where name == 'workflows.started'\n| summarize Count = sum(value) by bin(timestamp, 5m)\n| render timechart",
        "size": 0,
        "title": "Workflows Started (5-minute intervals)",
        "timeContext": { "durationMs": 3600000 }
      }
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "customMetrics\n| where name == 'workflows.execution.duration'\n| summarize P50=percentile(value, 50), P95=percentile(value, 95), P99=percentile(value, 99) by bin(timestamp, 5m)\n| render timechart",
        "size": 0,
        "title": "Workflow Execution Duration (P50/P95/P99)",
        "timeContext": { "durationMs": 3600000 }
      }
    }
  ]
}
```

### 3. Cost Monitoring Dashboard

**Azure OpenAI Token Usage:**
```kql
dependencies
| where type == "HTTP"
| where target contains "openai.azure.com"
| extend model = tostring(customDimensions.model)
| extend inputTokens = toint(customDimensions.inputTokens)
| extend outputTokens = toint(customDimensions.outputTokens)
| summarize
    TotalCalls = count(),
    TotalInputTokens = sum(inputTokens),
    TotalOutputTokens = sum(outputTokens),
    EstimatedCost = sum(inputTokens) * 0.00001 + sum(outputTokens) * 0.00003
by bin(timestamp, 1h), model
| render timechart
```

## Alerting

### Alert Rules

#### **High Error Rate Alert**

```bicep
resource highErrorRateAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'High-Error-Rate'
  location: 'global'
  properties: {
    description: 'Triggers when error rate exceeds 5% over 5 minutes'
    severity: 2
    enabled: true
    scopes: [applicationInsights.id]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'ErrorRate'
          metricName: 'requests/failed'
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}
```

#### **Slow Response Time Alert**

```bicep
resource slowResponseAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'Slow-Response-Time'
  location: 'global'
  properties: {
    description: 'Triggers when P95 response time > 1000ms'
    severity: 3
    enabled: true
    scopes: [applicationInsights.id]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'P95ResponseTime'
          metricName: 'requests/duration'
          operator: 'GreaterThan'
          threshold: 1000
          timeAggregation: 'Percentile95'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}
```

#### **Cosmos DB Throttling Alert**

```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.DOCUMENTDB"
| where statusCode_s == "429"
| summarize ThrottledCount = count() by bin(TimeGenerated, 5m)
| where ThrottledCount > 10
```

### Action Groups

**Email + SMS + Webhook:**
```bicep
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'agent-studio-alerts'
  location: 'global'
  properties: {
    groupShortName: 'AgentStudio'
    enabled: true
    emailReceivers: [
      {
        name: 'DevOps Team'
        emailAddress: 'devops@company.com'
        useCommonAlertSchema: true
      }
    ]
    smsReceivers: [
      {
        name: 'On-Call Engineer'
        countryCode: '1'
        phoneNumber: '5555551234'
      }
    ]
    webhookReceivers: [
      {
        name: 'Slack Webhook'
        serviceUri: 'https://hooks.slack.com/services/xxx/yyy/zzz'
        useCommonAlertSchema: true
      }
    ]
  }
}
```

## Log Analysis

### Common KQL Queries

#### **Top 10 Slowest Requests**
```kql
requests
| where timestamp > ago(24h)
| top 10 by duration desc
| project timestamp, name, duration, resultCode, url
```

#### **Error Distribution by Type**
```kql
exceptions
| where timestamp > ago(24h)
| summarize Count = count() by type, outerMessage
| order by Count desc
```

#### **Agent Performance by Type**
```kql
dependencies
| where type == "HTTP"
| where name contains "meta-agent"
| extend agentType = tostring(customDimensions.agentType)
| summarize
    Count = count(),
    AvgDuration = avg(duration),
    P95Duration = percentile(duration, 95),
    SuccessRate = countif(success == true) * 100.0 / count()
by agentType
| order by Count desc
```

## Troubleshooting

### High CPU Usage

**Diagnosis:**
```kql
performanceCounters
| where name == "% Processor Time"
| where timestamp > ago(1h)
| summarize AvgCPU = avg(value) by bin(timestamp, 5m), cloud_RoleInstance
| render timechart
```

**Mitigation:**
1. Check for CPU-intensive operations (regex, JSON parsing)
2. Review async/await patterns
3. Scale horizontally (increase replicas)
4. Optimize hot paths

### Memory Leaks

**Diagnosis:**
```kql
performanceCounters
| where name == "Private Bytes"
| where timestamp > ago(24h)
| summarize AvgMemory = avg(value) / 1024 / 1024 by bin(timestamp, 1h)
| render timechart
```

**Mitigation:**
1. Review object disposal (IDisposable)
2. Check event handler subscriptions
3. Analyze large object allocations
4. Use memory profilers (dotMemory, Chrome DevTools)

### Dependency Failures

**Diagnosis:**
```kql
dependencies
| where success == false
| where timestamp > ago(1h)
| summarize Count = count() by target, resultCode
| order by Count desc
```

**Mitigation:**
1. Check network connectivity
2. Verify authentication tokens
3. Review rate limiting
4. Implement circuit breakers

## Best Practices

### 1. Instrumentation Standards

**Add custom dimensions:**
```csharp
Activity.Current?.SetTag("workflow.id", workflowId);
Activity.Current?.SetTag("workspace.id", workspaceId);
Activity.Current?.SetTag("user.id", userId);
```

**Log correlation:**
```typescript
const trace = context.traceContext;
logger.info('Workflow started', {
  traceId: trace.traceId,
  spanId: trace.spanId,
  workflowId: workflow.id,
});
```

### 2. Alert Hygiene

- **Actionable** - Every alert should require action
- **Meaningful** - Avoid alert fatigue
- **Prioritized** - Use severity levels appropriately
- **Documented** - Include runbook links

### 3. Dashboard Design

- **Audience-specific** - Business vs. operations vs. engineering
- **Hierarchical** - Overview → Detail drill-downs
- **Timely** - Real-time for operations, historical for analysis
- **Contextual** - Link to logs, traces, metrics

## Resources

- [Application Insights Documentation](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [KQL Reference](https://learn.microsoft.com/azure/data-explorer/kusto/query/)
- [OpenTelemetry .NET](https://opentelemetry.io/docs/languages/net/)
- [Monitoring Best Practices](/runbooks/monitoring-best-practices)

---

*For incident response procedures, see [Incident Response Runbook](/runbooks/incident-response).*
