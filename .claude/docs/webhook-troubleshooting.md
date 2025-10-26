# Webhook Troubleshooting Guide

**Purpose**: Systematic diagnostic procedures for resolving webhook integration issues in agent activity synchronization. Establishes structured approach to identifying root causes and implementing sustainable fixes.

**Best for**: Operations teams managing webhook infrastructure requiring rapid issue resolution with minimal downtime.

---

## Quick Diagnostic Checklist

Before deep-diving, run this 2-minute health check:

```powershell
# 1. Test endpoint accessibility
.\. claude\utils\webhook-utilities.ps1 -Operation TestEndpoint

# 2. Check recent queue processor logs
Get-Content .\.claude\logs\notion-queue-processor.log -Tail 20

# 3. Verify Azure Function status
az functionapp show --name notion-webhook-brookside-prod --resource-group rg-brookside-innovation --query state

# 4. Check Application Insights for errors (last hour)
az monitor app-insights query --app ai-notion-webhook-prod --analytics-query "exceptions | where timestamp > ago(1h)"
```

**If all pass**: Issue likely transient, monitor for recurrence.
**If any fail**: Proceed with targeted troubleshooting below.

---

## Issue 1: Webhook Returns 401 Unauthorized

### Symptoms
- Hook logs show: "Webhook sync failed: 401 Unauthorized"
- Azure Function logs: "Invalid webhook signature - rejecting request"
- Activities queue for processor retry (webhookSynced=false)

### Root Cause
Signature mismatch between local hook and Azure Function webhook secret.

### Diagnostic Steps

**Step 1: Verify webhook secret in Key Vault**
```powershell
$vaultSecret = az keyvault secret show --vault-name kv-brookside-secrets --name notion-webhook-secret --query value -o tsv
Write-Host "Vault secret (first 8 chars): $($vaultSecret.Substring(0, 8))..."
```

**Step 2: Check hook configuration**
```powershell
# Open hook script and verify WebhookEndpoint matches deployed function
Get-Content .\.claude\hooks\auto-log-agent-activity.ps1 | Select-String "WebhookEndpoint"
```

**Step 3: Test signature generation manually**
```powershell
.\. claude\utils\webhook-utilities.ps1 -Operation GenerateSecret
# Compare output format with vault secret - should be 64 hex characters
```

**Step 4: Examine Application Insights logs**
```kusto
traces
| where timestamp > ago(1h)
| where message contains "signature"
| order by timestamp desc
```

### Solutions

**Solution A: Secret mismatch** (most common)
```powershell
# Regenerate webhook secret
$newSecret = .\. claude\utils\webhook-utilities.ps1 -Operation GenerateSecret

# Update Key Vault
az keyvault secret set --vault-name kv-brookside-secrets --name notion-webhook-secret --value "$newSecret"

# Restart Azure Function to clear cached secret
az functionapp restart --name notion-webhook-brookside-prod --resource-group rg-brookside-innovation

# Wait 30 seconds for restart, then test
Start-Sleep -Seconds 30
.\. claude\utils\webhook-utilities.ps1 -Operation SendTestPayload -WebhookSecret "$newSecret"
```

**Solution B: Signature format error**
```powershell
# Verify signature header format
# Correct:   Notion-Signature: v1=<64_hex_chars>
# Incorrect: Notion-Signature: <64_hex_chars>  (missing "v1=" prefix)

# Check hook script line ~466 for signature generation
Get-Content .\.claude\hooks\auto-log-agent-activity.ps1 -TotalCount 475 | Select-Object -Last 10
```

**Solution C: Key Vault access issue**
```powershell
# Verify Managed Identity has Key Vault permissions
az functionapp identity show --name notion-webhook-brookside-prod --resource-group rg-brookside-innovation

# Check access policy (should show "get" and "list" secrets)
az keyvault show --name kv-brookside-secrets --query properties.accessPolicies
```

### Prevention
- Store webhook secret in password manager for backup
- Document secret rotation procedure with runbook
- Configure Application Insights alert for >5 401 errors per hour

---

## Issue 2: Webhook Returns 500 Internal Server Error

### Symptoms
- Hook logs show: "Webhook sync failed: 500 Internal Server Error"
- Activities successfully queue for retry
- Application Insights shows exception traces

### Root Cause
Azure Function runtime error (Notion API failure, database access issue, code bug).

### Diagnostic Steps

**Step 1: Retrieve detailed error from Application Insights**
```kusto
exceptions
| where timestamp > ago(24h)
| where cloud_RoleName == "notion-webhook-brookside-prod"
| project timestamp, problemId, outerMessage, innermostMessage
| order by timestamp desc
| take 10
```

**Step 2: Check Azure Function logs (live tail)**
```powershell
func azure functionapp logstream notion-webhook-brookside-prod
# Or via Azure Portal: Function App > Log Stream
```

**Step 3: Test Notion API connectivity from Azure**
```powershell
# From local machine (simulating Azure Function environment)
$notionKey = az keyvault secret show --vault-name kv-brookside-secrets --name notion-api-key --query value -o tsv

$headers = @{
    "Authorization" = "Bearer $notionKey"
    "Notion-Version" = "2022-06-28"
}

Invoke-RestMethod -Uri "https://api.notion.com/v1/users/me" -Headers $headers
# Should return user object, not 401/403
```

### Common Error Messages and Solutions

#### Error: "object_not_found: Could not find database with ID"
**Cause**: Notion integration not shared with Agent Activity Hub database.

**Solution**:
```
1. Navigate to Agent Activity Hub: https://www.notion.so/72b879f213bd4edb9c59b43089dbef21
2. Click "..." (three dots) → "Connections"
3. Click "+ Add connection"
4. Select your Notion integration
5. Confirm access
6. Retry webhook test
```

**Verification**:
```powershell
# Test page creation with notion-mcp (should succeed if connection established)
notion-mcp create-page --database-id "72b879f213bd4edb9c59b43089dbef21" --title "Test Page"
```

#### Error: "validation_error: body.properties.X is not a supported property"
**Cause**: Property name mismatch between payload and database schema.

**Solution**:
```powershell
# 1. Fetch current database schema
notion-mcp fetch --id "72b879f213bd4edb9c59b43089dbef21"

# 2. Compare property names in azure-functions/notion-webhook/shared/notionClient.ts
#    with actual database properties

# 3. Update transformToNotionProperties function to match exact property names

# Example fix:
# Database has: "Agent Name"
# Code sent:    "AgentName"  ← Mismatch!
# Corrected:    "Agent Name"  ← Must match exactly
```

#### Error: "rate_limited: API rate limit exceeded"
**Cause**: Too many requests to Notion API (unlikely with ~200 activities/month).

**Solution**:
```powershell
# Implement exponential backoff in notionClient.ts (future enhancement)
# Current workaround: Queue processor retries automatically with delay

# Check Application Insights for rate limit frequency
# If >5/day: Consider batch processing or request throttling
```

#### Error: "ECONNREFUSED" or "ETIMEDOUT"
**Cause**: Network connectivity issue from Azure to Notion API.

**Solution**:
```powershell
# 1. Check Azure Function outbound network rules (should allow all by default)

# 2. Verify Notion API status: https://status.notion.so

# 3. Test connectivity from Azure CLI (Cloud Shell in same region as Function)
curl -I https://api.notion.com/v1/users/me

# 4. If persistent: Contact Azure Support (potential regional network issue)
```

### Prevention
- Configure Application Insights alert for >3 exceptions per hour
- Monitor Notion API status page for planned maintenance
- Implement retry logic with exponential backoff (code enhancement)

---

## Issue 3: Cold Start Latency >10 Seconds (Timeout)

### Symptoms
- First webhook request after idle period times out
- Hook logs: "Webhook sync failed: Connection timeout"
- Subsequent requests succeed (warm starts)

### Root Cause
Azure Function Consumption plan cold starts (initialize Node.js runtime, load dependencies).

### Diagnostic Steps

**Step 1: Measure cold start frequency**
```kusto
requests
| where timestamp > ago(7d)
| where name == "NotionWebhook"
| extend IsColdStart = duration > 2000
| summarize ColdStarts = countif(IsColdStart), TotalRequests = count()
| project ColdStartRate = 100.0 * ColdStarts / TotalRequests
```

**Step 2: Analyze cold start duration**
```kusto
requests
| where timestamp > ago(7d)
| where name == "NotionWebhook"
| where duration > 2000
| summarize avg(duration), max(duration), percentile(duration, 95)
```

### Solutions

**Solution A: Increase hook timeout** (quick fix)
```powershell
# Edit .claude/hooks/auto-log-agent-activity.ps1 line 57
# Change: WebhookTimeoutSeconds = 10
# To:     WebhookTimeoutSeconds = 30

# Rationale: <30 second SLO still met, accommodates cold starts
```

**Solution B: Keep function warm** (proactive monitoring)
```powershell
# Schedule periodic health check (Task Scheduler / cron)
# Every 5 minutes during business hours to maintain warm instances

0 */5 8-18 * * .\. claude\utils\webhook-utilities.ps1 -Operation TestEndpoint
```

**Solution C: Upgrade to Premium plan** (cost-benefit analysis)
**Current**: Consumption plan ($0-5/month, cold starts)
**Premium**: EP1 plan ($150/month, always-on instances)

**Decision criteria**: Only if cold start rate >50% AND latency-critical use case.
**Recommendation**: Stay on Consumption plan - <30 second SLO met 95%+ of time.

**Solution D: Optimize cold start performance** (code improvement)
```typescript
// azure-functions/notion-webhook/shared/keyVaultClient.ts
// Current: Retrieve secrets on every cold start (~500ms)
// Enhanced: Pre-warm secrets during function initialization

// Add module-level initialization
import { DefaultAzureCredential } from '@azure/identity';

const credential = new DefaultAzureCredential(); // ← Initialize once
let secretsCache: KeyVaultSecrets | null = null;

// Secrets retrieved only once per instance lifetime
```

### Prevention
- Monitor cold start rate weekly via Application Insights dashboard
- Document acceptable latency SLO (<30 seconds)
- Evaluate Premium plan upgrade if business requirements change

---

## Issue 4: Activities Not Appearing in Notion

### Symptoms
- Hook logs show: "Successfully synced via webhook + queued as backup"
- Webhook returns 200 OK
- Page URL returned but clicking shows "Page not found"
- Queue processor also shows success

### Root Cause
Database permissions, wrong database ID, or page created in different workspace.

### Diagnostic Steps

**Step 1: Verify database ID configuration**
```powershell
# Check Azure Function app settings
az functionapp config appsettings list --name notion-webhook-brookside-prod --resource-group rg-brookside-innovation --query "[?name=='AGENT_ACTIVITY_HUB_ID'].value" -o tsv

# Should match: 72b879f213bd4edb9c59b43089dbef21 (Agent Activity Hub data source ID)
```

**Step 2: Check Notion workspace context**
```powershell
# Verify API key workspace
$notionKey = az keyvault secret show --vault-name kv-brookside-secrets --name notion-api-key --query value -o tsv

$headers = @{
    "Authorization" = "Bearer $notionKey"
    "Notion-Version" = "2022-06-28"
}

$workspaceInfo = Invoke-RestMethod -Uri "https://api.notion.com/v1/search" -Headers $headers -Method Post -Body '{"filter":{"property":"object","value":"database"}}' -ContentType "application/json"

$workspaceInfo.results | Where-Object { $_.id -eq "72b879f213bd4edb9c59b43089dbef21" }
# Should return database object; if empty, wrong workspace
```

**Step 3: Retrieve page from Application Insights response**
```kusto
traces
| where timestamp > ago(1h)
| where message contains "Page created successfully"
| project timestamp, message
| order by timestamp desc
```

**Step 4: Attempt direct page fetch**
```powershell
# Extract page ID from Application Insights log
$pageId = "..." # From logs

notion-mcp fetch --id $pageId
# If 404: Page doesn't exist or no access
# If 200: Page exists, check if it's in correct database
```

### Solutions

**Solution A: Wrong database ID**
```powershell
# Correct data source ID: 7163aa38-f3d9-444b-9674-bde61868bd2b
# NOT the database page ID: 72b879f213bd4edb9c59b43089dbef21

# Update Azure Function app setting
az functionapp config appsettings set --name notion-webhook-brookside-prod --resource-group rg-brookside-innovation --settings AGENT_ACTIVITY_HUB_ID="7163aa38-f3d9-444b-9674-bde61868bd2b"

# Restart function
az functionapp restart --name notion-webhook-brookside-prod --resource-group rg-brookside-innovation
```

**Solution B: Database not shared with integration**
See Issue 2 - Error: "object_not_found" solution.

**Solution C: Pages in different database**
```powershell
# Search all databases for recent pages
$recentPages = Invoke-RestMethod -Uri "https://api.notion.com/v1/search" -Headers $headers -Method Post -Body '{"filter":{"property":"object","value":"page"},"sort":{"direction":"descending","timestamp":"last_edited_time"}}' -ContentType "application/json"

$recentPages.results | Select-Object -First 10 | ForEach-Object {
    Write-Host "Page: $($_.properties.'Session ID'.title[0].text.content) - Database: $($_.parent.database_id)"
}

# If pages in wrong database: Update AGENT_ACTIVITY_HUB_ID
```

### Prevention
- Document correct database IDs in CLAUDE.md
- Add database ID validation to webhook utilities
- Configure monitoring alert if page creation count diverges from expected

---

## Issue 5: Queue Processor Not Skipping Webhook-Synced Entries

### Symptoms
- Duplicate pages created in Notion
- Queue processor logs show processing of webhookSynced=true entries
- Increased Notion API usage

### Root Cause
Queue processor filtering logic not working correctly.

### Diagnostic Steps

**Step 1: Inspect queue file contents**
```powershell
# View recent queue entries
Get-Content .\.claude\data\notion-sync-queue.jsonl -Tail 5 | ForEach-Object {
    $entry = $_ | ConvertFrom-Json
    Write-Host "SessionId: $($entry.sessionId) - webhookSynced: $($entry.webhookSynced)"
}
```

**Step 2: Check processor filtering logic**
```powershell
# Verify filter is active in Get-QueueEntries function
Get-Content .\.claude\utils\process-notion-queue.ps1 | Select-String "webhookSynced" -Context 2
```

**Step 3: Test processor with dry run**
```powershell
# Run processor in dry-run mode to see what would be processed
.\. claude\utils\process-notion-queue.ps1 -DryRun
# Output should show: "Skipped X entries already synced via webhook"
```

### Solutions

**Solution A: Filtering logic missing**
```powershell
# Ensure filter exists in Get-QueueEntries function (lines 135-148)
# If missing: Re-apply code from implementation commit

# Verify presence:
Get-Content .\.claude\utils\process-notion-queue.ps1 -TotalCount 150 | Select-Object -Last 20
# Should see: "Filter out entries already synced via webhook"
```

**Solution B: Boolean comparison issue**
```powershell
# PowerShell boolean comparison can be tricky
# Ensure filter uses strict equality:

# Correct:   if ($_.webhookSynced -eq $true)
# Incorrect: if ($_.webhookSynced)  ← May evaluate incorrectly with string "false"
```

**Solution C: Legacy queue entries without webhookSynced field**
```powershell
# Queue entries created before webhook implementation don't have field
# Add null check to filter:

# Enhanced filter (lines 137-142):
$entries = $entries | Where-Object {
    # Treat missing field as false (legacy entries should be processed)
    if ($null -ne $_.webhookSynced -and $_.webhookSynced -eq $true) {
        Write-ProcessorLog "Skipping entry ..." -Level DEBUG
        return $false
    }
    return $true
}
```

### Prevention
- Test processor with both webhook-synced and legacy entries
- Monitor duplicate page creation via Notion database query
- Version queue entry schema with migration script for major changes

---

## Advanced Diagnostics

### Webhook Request Tracing

Enable detailed request logging in Azure Function for root cause analysis:

**Step 1: Configure trace logging**
```powershell
# Update host.json logging level
# azure-functions/notion-webhook/host.json

"logging": {
  "logLevel": {
    "default": "Information",
    "Host.Results": "Information",
    "Function": "Debug"  ← Change to Debug
  }
}

# Redeploy function
func azure functionapp publish notion-webhook-brookside-prod
```

**Step 2: Capture full request details**
```kusto
traces
| where timestamp > ago(1h)
| where severityLevel >= 2  // Info and above
| where message contains "Notion webhook triggered" or message contains "Signature"
| project timestamp, severityLevel, message
| order by timestamp desc
```

**Step 3: Correlate with hook logs**
```powershell
# Match sessionId between hook logs and Application Insights
$sessionId = "test-agent-20251026-1430"

# Hook logs
Get-Content .\.claude\logs\auto-activity-hook.log | Select-String $sessionId

# Application Insights
# Use same sessionId in Kusto query to trace full flow
```

---

### Network Diagnostics

If webhook connectivity issues persist, validate network path:

**Step 1: Test DNS resolution**
```powershell
Resolve-DnsName notion-webhook-brookside-prod.azurewebsites.net
# Should return Azure IP address (e.g., 20.X.X.X)
```

**Step 2: Test TCP connectivity**
```powershell
Test-NetConnection -ComputerName notion-webhook-brookside-prod.azurewebsites.net -Port 443
# TcpTestSucceeded should be True
```

**Step 3: Trace HTTP request**
```powershell
# Use Invoke-WebRequest with -Verbose for detailed trace
Invoke-WebRequest -Uri "https://notion-webhook-brookside-prod.azurewebsites.net/api/NotionWebhook" -Method Post -Verbose -ErrorAction SilentlyContinue
# Check response headers, redirect chains, SSL certificate validation
```

---

## Escalation Procedures

### When to Escalate

**Escalate to Azure Support if**:
- Persistent 500 errors with no actionable error message in Application Insights
- Network connectivity failures from multiple networks
- Managed Identity authentication failures after verifying Key Vault access
- Function runtime crashes (process exit codes)

**Escalate to Notion Support if**:
- API rate limiting despite low request volume (<10/minute)
- Database access issues despite correct permissions
- Inconsistent API behavior (same request succeeds/fails intermittently)

### Escalation Information to Collect

**For Azure Support**:
```powershell
# 1. Deployment details
az functionapp show --name notion-webhook-brookside-prod --resource-group rg-brookside-innovation --output json > azure-function-details.json

# 2. Recent logs
az functionapp log download --name notion-webhook-brookside-prod --resource-group rg-brookside-innovation --output-path function-logs.zip

# 3. Application Insights trace
# Export query results for last 24 hours

# 4. Bicep template used for deployment
Get-Content infrastructure\notion-webhook-function.bicep
```

**For Notion Support**:
- Notion integration ID
- Database ID (7163aa38-f3d9-444b-9674-bde61868bd2b)
- Example failing request (anonymize sensitive data)
- Notion-Request-Id header from failed response (if available)

---

## Monitoring Dashboard Setup

Create Application Insights dashboard for proactive monitoring:

**Recommended Tiles**:
1. **Success Rate (Last 24h)** - Target: >95%
2. **Average Latency (P95)** - Target: <2 seconds
3. **Error Count (Last Hour)** - Threshold: Alert if >5
4. **Cold Start Frequency (Last 7d)** - Baseline tracking
5. **Webhook vs Queue Sync Ratio** - Expect 80%+ webhook success

**Dashboard Creation**:
```powershell
# Azure Portal: Monitor → Application Insights → Dashboards → New Dashboard
# Add tiles with Kusto queries from "Operational Monitoring" section in architecture doc
```

---

## Related Documentation

- [Webhook Architecture](webhook-architecture.md) - System design and data flow
- [Webhook README](../azure-functions/notion-webhook/README.md) - Deployment guide
- [Agent Activity Center](agent-activity-center.md) - Overall logging architecture
- [Webhook Utilities Script](../utils/webhook-utilities.ps1) - Testing tools

---

**Brookside BI Innovation Nexus** - Sustainable webhook operations through systematic diagnostics and proactive monitoring.
