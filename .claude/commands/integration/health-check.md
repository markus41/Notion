---
name: integration:health-check
description: Establish comprehensive integration health monitoring to maintain operational reliability and drive proactive issue resolution across your connectivity ecosystem
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-fetch
argument-hint: [--format=table|json] [--filter=status]
model: claude-sonnet-4-5-20250929
---

# /integration:health-check

**Category**: Integration Management
**Related Databases**: Integration Registry

## Purpose

Establish systematic integration health monitoring to maintain operational reliability and drive proactive issue resolution across your entire connectivity ecosystem.

**Best for**: Organizations managing multiple integrations (APIs, webhooks, MCP servers, Azure services) that require real-time health visibility, proactive failure detection, and consolidated status reporting to support sustainable multi-system operations.

---

## Parameters

- `--format=value` - Output format (table | json | summary) [default: table]
- `--filter=status` - Filter by status (active | inactive | degraded | failing)
- `--type=value` - Filter by integration type (api | webhook | mcp-server | azure-service)
- `--verbose` - Include detailed connection metrics and last-tested timestamp

---

## Health Check Workflow

**Visual Process Overview**:

```mermaid
flowchart TD
    A[/integration:health-check invoked] --> B[Query Integration Registry]
    B --> C{Retrieve all<br/>integrations}

    C --> D[Filter by parameters]
    D --> E{Format output}

    E -->|Table| F[Generate ASCII table]
    E -->|JSON| G[Generate JSON array]
    E -->|Summary| H[Generate summary stats]

    F --> I[Display to user]
    G --> I
    H --> I

    I --> J{Issues detected?}
    J -->|Yes| K[⚠️ Highlight failing integrations]
    J -->|No| L[✅ All systems operational]

    K --> M[Recommend remediation actions]
    M --> N[Return health report]
    L --> N

    style A fill:#3B82F6,color:#fff
    style K fill:#EF4444,color:#fff
    style L fill:#10B981,color:#fff
    style N fill:#10B981,color:#fff
```

*Figure: Integration health check workflow with automatic status aggregation, issue detection, and actionable remediation recommendations.*

---

## Implementation

```javascript
// Query all integrations from Integration Registry
const integrations = await notionSearch({
  query: '',
  database: 'Integration Registry',
  filters: typeFilter ? { Type: typeFilter } : undefined
});

// Check each integration health
const healthReport = integrations.map(integration => ({
  name: integration.properties['Integration Name'],
  type: integration.properties['Type'],
  status: integration.properties['Status'],
  endpoint: integration.properties['Endpoint'],
  authMethod: integration.properties['Auth Method'],
  lastTested: integration.properties['Last Tested'] || 'Never',
  healthStatus: determineHealthStatus(integration)
}));

// Format and display results
displayHealthReport(healthReport, format);
```

---

## Examples

### Basic Health Check (All Integrations)

```bash
# Display all integrations in table format
/integration:health-check

# Expected Output:
# ┌──────────────────────────────┬─────────────┬──────────┬─────────────────────────────┐
# │ Integration Name             │ Type        │ Status   │ Health                      │
# ├──────────────────────────────┼─────────────┼──────────┼─────────────────────────────┤
# │ Azure OpenAI API             │ api         │ 🟢 Active │ ✅ Healthy                  │
# │ Notion Database Webhook      │ webhook     │ 🟢 Active │ ✅ Healthy                  │
# │ Microsoft Graph API          │ api         │ 🟡 Active │ ⚠️ Degraded (slow response) │
# │ Azure Key Vault              │ azure-svc   │ 🟢 Active │ ✅ Healthy                  │
# │ Legacy SOAP Service          │ api         │ 🔴 Inactive│ ❌ Failing (timeout)       │
# └──────────────────────────────┴─────────────┴──────────┴─────────────────────────────┘
```

### Filtered Health Check (Active Only)

```bash
# Show only active integrations
/integration:health-check --filter=active

# Show only API integrations
/integration:health-check --type=api
```

### Verbose Health Check (Detailed Metrics)

```bash
# Include connection metrics and timestamps
/integration:health-check --verbose

# Expected Output includes:
# - Last connection test timestamp
# - Response time metrics (ms)
# - Success/failure rate (last 24h)
# - Authentication method validation
```

### JSON Output (Programmatic Use)

```bash
# Export health data as JSON for automation
/integration:health-check --format=json

# Use case: Pipe to monitoring dashboard or alerting system
```

### Summary Report (Executive Overview)

```bash
# High-level health summary for stakeholders
/integration:health-check --format=summary

# Expected Output:
# Integration Health Summary
# ═════════════════════════════
# Total Integrations: 12
# ✅ Healthy: 9 (75%)
# ⚠️ Degraded: 2 (17%)
# ❌ Failing: 1 (8%)
#
# Action Required: 1 integration requires immediate attention
```

---

## Expected Outcomes

**Successful Health Check**:
1. ✅ All integrations retrieved from Integration Registry
2. ✅ Current health status determined for each integration
3. ✅ Results formatted according to --format parameter
4. ✅ Failing integrations highlighted with ⚠️ or ❌ indicators
5. ✅ Actionable recommendations provided for degraded/failing integrations

**Health Status Indicators**:
- ✅ **Healthy**: Integration active, responding normally, authentication valid
- ⚠️ **Degraded**: Integration active but experiencing issues (slow response, intermittent failures)
- ❌ **Failing**: Integration inactive or consistently failing (timeout, auth error, endpoint unreachable)
- 🔵 **Unknown**: Integration registered but never tested

---

## Health Determination Logic

**Automatic Health Assessment**:

```javascript
function determineHealthStatus(integration) {
  // Check basic availability
  if (integration.status !== '🟢 Active') {
    return { health: '❌ Failing', reason: 'Integration marked inactive' };
  }

  // Check last tested timestamp
  const lastTested = integration['Last Tested'];
  if (!lastTested || isOlderThan(lastTested, 7, 'days')) {
    return { health: '🔵 Unknown', reason: 'Not tested in last 7 days' };
  }

  // Check response time metrics
  const avgResponseTime = integration['Avg Response Time (ms)'];
  if (avgResponseTime > 5000) {
    return { health: '⚠️ Degraded', reason: `Slow response (${avgResponseTime}ms)` };
  }

  // Check success rate
  const successRate = integration['Success Rate (24h)'];
  if (successRate < 95) {
    return { health: '⚠️ Degraded', reason: `Low success rate (${successRate}%)` };
  }

  // All checks passed
  return { health: '✅ Healthy', reason: null };
}
```

---

## Verification Steps

**Validate Health Check Accuracy**:

```bash
# 1. Run health check with verbose output
/integration:health-check --verbose

# 2. Verify health indicators match actual integration performance
# - Check Azure Portal for Azure service health
# - Test API endpoints manually with curl/Postman
# - Review webhook delivery logs
# - Validate MCP server connectivity

# 3. Compare health check results with monitoring dashboards
# - Azure Application Insights
# - Datadog monitors
# - Custom monitoring solutions

# 4. Test remediation recommendations
# For failing integrations, follow suggested actions:
# - Re-authenticate if auth error detected
# - Update endpoint URL if unreachable
# - Increase timeout thresholds if slow response
# - Deactivate if permanently deprecated
```

---

## Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| All integrations show 🔵 Unknown | No test data recorded | Implement `/integration:test` command to establish baseline |
| False positives (healthy marked as failing) | Stale test data | Increase test frequency or run `/integration:test [name]` manually |
| Missing integrations in report | Integration not registered | Use `/integration:register` to add missing integrations |
| Cannot determine health status | Missing required properties | Update Integration Registry schema to include health metrics |
| Slow health check execution | Too many integrations queried | Use --filter or --type parameters to narrow scope |

---

## Integration with Monitoring Systems

**Automation Workflows**:

```bash
# Schedule daily health checks (PowerShell)
$dailyHealth = Invoke-ClaudeCommand "/integration:health-check --format=json"
Send-ToMonitoringDashboard $dailyHealth

# Alert on failing integrations (Azure Function)
$health = Get-IntegrationHealth
$failing = $health | Where-Object { $_.health -eq 'Failing' }
if ($failing.Count -gt 0) {
    Send-AlertToTeams "⚠️ Integration Health Alert: $($failing.Count) integrations failing"
}

# Weekly executive summary (automated report)
$summary = Invoke-ClaudeCommand "/integration:health-check --format=summary"
Send-EmailReport -To "leadership@brooksidebi.com" -Subject "Weekly Integration Health" -Body $summary
```

---

## Related Commands

**Complete Integration Management Workflow**:

1. **Register Integration**: `/integration:register [name] [type]`
2. **Test Connection**: `/integration:test [integration-name]` *(P1 - create next)*
3. **Check Health**: `/integration:health-check` *(this command)*
4. **Update Status**: `/integration:update-status [integration-name] [status]`
5. **Search Integrations**: `/integration:search [query]`
6. **View Analytics**: `/integration:stats`

---

**Last Updated**: 2025-10-26
**Priority**: P1 (High)
**Status**: Specification Complete - Ready for Implementation
