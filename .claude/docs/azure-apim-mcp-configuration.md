# Azure API Management MCP Server Configuration

**Purpose**: Establish AI agent access to REST APIs through Azure API Management Model Context Protocol (MCP) server export. Organizations scaling API-driven workflows benefit from centralized governance, policy-based authentication, and intelligent rate limiting while enabling AI agents to invoke APIs as native tools.

**Best for**: Teams requiring controlled AI agent access to production APIs with comprehensive audit trails, security policies, and cost optimization.

---

## Architecture

```
AI Agent (Claude Code)
    ↓ MCP Tool Invocation (JSON-RPC)
    ↓
Azure API Management (Gateway)
    ↓ Policy Layer (Auth, Rate Limit, Transform)
    ↓
Backend REST API (Azure Function)
    ↓ Business Logic Execution
    ↓
Data Store (Notion, Database, etc.)
```

**Key Components**:
- **MCP Server Export**: Exposes APIM-managed APIs as MCP tools for AI agent consumption
- **Policy Engine**: XML-based policies for authentication, rate limiting, caching, transformation
- **Subscription Keys**: API governance through key-based access control
- **Application Insights**: Comprehensive telemetry and diagnostics for API usage
- **Consumption Tier**: Auto-scaling, pay-per-call pricing ($0-5/month for Innovation Nexus scale)

---

## Current Configuration

### APIM Instance Details

```bash
Name: apim-brookside-innovation
Resource Group: rg-brookside-innovation
Location: East US
Tier: Consumption (Serverless)
Publisher: Brookside BI (Consultations@BrooksideBI.com)
Gateway URL: https://apim-brookside-innovation.azure-api.net
```

### Managed APIs

| API Name | Backend | MCP Exposed | Status |
|----------|---------|-------------|--------|
| **Notion Activity Webhook** | Azure Function | ✓ Yes | Pending Import |
| Queue Processor API | Azure Function | ⏸️ Phase 2 | Not Created |
| Cost Analytics API | Azure Function | ⏸️ Phase 2 | Not Created |
| Repository Analyzer | Python FastAPI | ⏸️ Phase 2 | Not Created |

### MCP Server Endpoints

```
Notion Activity MCP Server:
  URL: https://apim-brookside-innovation.azure-api.net/notion-activity-mcp/mcp
  Protocol: HTTP/SSE (Server-Sent Events)
  Authentication: Subscription Key (Ocp-Apim-Subscription-Key header)
```

---

## Prerequisites

### Azure Resources (Required)

- ✅ **Azure Subscription**: Active subscription with resource group
- ✅ **APIM Instance**: Provisioned and activated (30-45 min wait time)
- ⏸️ **Backend API Deployed**: Webhook Azure Function must be running
- ✅ **Azure CLI Authenticated**: `az login` completed

### Portal Access (Required)

- ✅ **Azure Portal Preview Mode**: Required for MCP server creation UI
  - Navigate to [https://portal.azure.com/?feature.canmodifystamps=true&Microsoft_Azure_ApiManagement=mcp](https://portal.azure.com/?feature.canmodifystamps=true&Microsoft_Azure_ApiManagement=mcp)
  - Feature flag: `Microsoft_Azure_ApiManagement=mcp`

### MCP Client Configuration (Claude Code)

- ✅ **Claude Code Installed**: Latest version with MCP support
- ✅ **MCP Configuration File**: `%APPDATA%\Claude\claude_desktop_config.json` (Windows)

---

## Configuration Steps

### Step 1: Verify APIM Provisioning Complete

Wait for APIM instance to reach `ProvisioningState: Succeeded` (30-45 minutes for Consumption tier).

```bash
# Check provisioning status
az apim show \
  --name apim-brookside-innovation \
  --resource-group rg-brookside-innovation \
  --query "{Name:name, State:provisioningState, Gateway:gatewayUrl}" \
  --output table

# Expected output:
# Name                       State      Gateway
# -------------------------  ---------  --------------------------------------------
# apim-brookside-innovation  Succeeded  https://apim-brookside-innovation.azure-api.net
```

### Step 2: Import Webhook API into APIM

**Option A: Azure Portal (Recommended for First-Time Setup)**

1. Navigate to [Azure Portal](https://portal.azure.com) → APIM instance
2. Left menu: **APIs** → **+ Add API**
3. Select **HTTP** (manual API definition)
4. Configure API:
   - **Display name**: `Notion Activity Webhook`
   - **Name**: `notion-activity-webhook`
   - **Web service URL**: `https://notion-webhook-brookside-prod.azurewebsites.net/api`
   - **API URL suffix**: `webhook` (results in `/webhook/*` paths)
5. Click **Create**

6. Add POST operation:
   - Click **+ Add operation**
   - **Display name**: `Log Agent Activity`
   - **Name**: `log-activity`
   - **URL**: `POST /NotionWebhook`
   - **Request**:
     - Add header: `Notion-Signature` (string, required)
     - Body: JSON schema for `AgentActivityEvent`
   - **Response**: 200 OK with `{success, message, pageId, pageUrl, duration}`
7. Click **Save**

**Option B: Azure CLI (Faster for Automation)**

```bash
# Create API
az apim api create \
  --resource-group rg-brookside-innovation \
  --service-name apim-brookside-innovation \
  --api-id notion-activity-webhook \
  --path webhook \
  --display-name "Notion Activity Webhook" \
  --service-url "https://notion-webhook-brookside-prod.azurewebsites.net/api" \
  --protocols https

# Add POST operation
az apim api operation create \
  --resource-group rg-brookside-innovation \
  --service-name apim-brookside-innovation \
  --api-id notion-activity-webhook \
  --operation-id log-activity \
  --display-name "Log Agent Activity" \
  --method POST \
  --url-template "/NotionWebhook"
```

### Step 3: Create MCP Server Export

**Azure Portal (Preview Mode Required)**:

1. Navigate to [Portal with MCP Feature Flag](https://portal.azure.com/?feature.canmodifystamps=true&Microsoft_Azure_ApiManagement=mcp)
2. Go to: APIM instance → **APIs** → **MCP Servers**
3. Click **+ Create MCP server**
4. Select **Expose an API as an MCP server**
5. Configuration:
   - **API**: Select `notion-activity-webhook`
   - **Operations to expose**: Check `log-activity (POST /NotionWebhook)`
   - **MCP Server Name**: `notion-activity-mcp`
   - **Description**: `Expose Notion webhook for AI agent activity logging`
6. Click **Create**
7. **Copy Server URL**: `https://apim-brookside-innovation.azure-api.net/notion-activity-mcp/mcp`

**Note**: MCP server export is currently a preview feature and may not have CLI support. Portal configuration is recommended.

### Step 4: Configure APIM Policies

Apply policies at API or operation level for governance.

**Navigate**: APIM → APIs → `notion-activity-webhook` → **All operations** → **Policies** (code view)

**Recommended Policy Configuration**:

```xml
<policies>
    <inbound>
        <!-- Base policies -->
        <base />

        <!-- Rate limiting: 100 calls per minute per subscription -->
        <rate-limit calls="100" renewal-period="60" />

        <!-- Quota: 10,000 calls per month -->
        <quota calls="10000" renewal-period="2592000" />

        <!-- Validate subscription key (auto-applied) -->
        <check-header name="Ocp-Apim-Subscription-Key" failed-check-httpcode="401" failed-check-error-message="Subscription key required" />

        <!-- Generate webhook signature (if not provided by client) -->
        <set-variable name="webhookSecret" value="{{notion-webhook-secret}}" />
        <set-variable name="requestBody" value="@(context.Request.Body.As<string>(preserveContent: true))" />
        <set-header name="Notion-Signature" exists-action="skip">
            <value>@{
                var secret = (string)context.Variables["webhookSecret"];
                var body = (string)context.Variables["requestBody"];
                using (var hmac = new System.Security.Cryptography.HMACSHA256(System.Text.Encoding.UTF8.GetBytes(secret)))
                {
                    var hash = hmac.ComputeHash(System.Text.Encoding.UTF8.GetBytes(body));
                    return "v1=" + BitConverter.ToString(hash).Replace("-", "").ToLower();
                }
            }</value>
        </set-header>

        <!-- Add correlation ID for tracing -->
        <set-header name="X-Correlation-Id" exists-action="override">
            <value>@(Guid.NewGuid().ToString())</value>
        </set-header>
    </inbound>

    <backend>
        <!-- Forward to Azure Function -->
        <base />
    </backend>

    <outbound>
        <!-- DO NOT access context.Response.Body - breaks streaming -->
        <base />

        <!-- Add CORS headers if needed -->
        <cors allow-credentials="false">
            <allowed-origins>
                <origin>*</origin>
            </allowed-origins>
            <allowed-methods>
                <method>POST</method>
                <method>OPTIONS</method>
            </allowed-methods>
            <allowed-headers>
                <header>*</header>
            </allowed-headers>
        </cors>
    </outbound>

    <on-error>
        <base />

        <!-- Log errors to Application Insights -->
        <trace source="apim-error" severity="error">
            <message>@($"APIM Error: {context.LastError.Message}")</message>
        </trace>
    </on-error>
</policies>
```

**Store Webhook Secret as Named Value**:

```bash
# Create named value for policy reference
az apim nv create \
  --resource-group rg-brookside-innovation \
  --service-name apim-brookside-innovation \
  --named-value-id notion-webhook-secret \
  --display-name "notion-webhook-secret" \
  --value "16997736f8a1727d23871acc6cb1586e03768f9c1704865c009bb391e608acf0" \
  --secret true
```

### Step 5: Get Subscription Key

APIM requires subscription key for API access.

```bash
# List subscriptions
az apim subscription list \
  --resource-group rg-brookside-innovation \
  --service-name apim-brookside-innovation \
  --query "[].{Name:displayName, Scope:scope, State:state}" \
  --output table

# Get primary key for default subscription
az apim subscription show \
  --resource-group rg-brookside-innovation \
  --service-name apim-brookside-innovation \
  --subscription-id master \
  --query "primaryKey" \
  --output tsv
```

**Store in Key Vault**:

```bash
# Store subscription key securely
APIM_KEY=$(az apim subscription show \
  --resource-group rg-brookside-innovation \
  --service-name apim-brookside-innovation \
  --subscription-id master \
  --query "primaryKey" \
  --output tsv)

az keyvault secret set \
  --vault-name kv-brookside-secrets \
  --name apim-subscription-key \
  --value "$APIM_KEY"
```

### Step 6: Configure Claude Code MCP Client

Edit `%APPDATA%\Claude\claude_desktop_config.json` (Windows) or `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS):

```json
{
  "mcpServers": {
    "notion": {
      "disabled": false
    },
    "github": {
      "disabled": false
    },
    "azure": {
      "disabled": false
    },
    "playwright": {
      "disabled": false
    },
    "azure-apim-innovation": {
      "type": "sse",
      "url": "https://apim-brookside-innovation.azure-api.net/notion-activity-mcp/mcp",
      "headers": {
        "Ocp-Apim-Subscription-Key": "{{APIM_SUBSCRIPTION_KEY}}"
      }
    }
  }
}
```

**Retrieve and Set Subscription Key**:

```powershell
# PowerShell: Get key from Key Vault and set environment variable
$apimKey = az keyvault secret show --vault-name kv-brookside-secrets --name apim-subscription-key --query value -o tsv
[System.Environment]::SetEnvironmentVariable('APIM_SUBSCRIPTION_KEY', $apimKey, 'User')

# Restart Claude Code to load new environment variable
```

**Alternative: Store Key Directly in Config** (less secure):

```json
{
  "azure-apim-innovation": {
    "type": "sse",
    "url": "https://apim-brookside-innovation.azure-api.net/notion-activity-mcp/mcp",
    "headers": {
      "Ocp-Apim-Subscription-Key": "your-actual-subscription-key-here"
    }
  }
}
```

### Step 7: Restart Claude Code and Verify Connection

```bash
# Restart Claude Code application
# Then verify MCP server connection

claude mcp list

# Expected output should include:
# ✓ azure-apim-innovation (Connected)
#   URL: https://apim-brookside-innovation.azure-api.net/notion-activity-mcp/mcp
#   Tools: log-activity
```

---

## Testing

### Test 1: Direct APIM API Invocation

```powershell
# Get subscription key
$apimKey = az keyvault secret show --vault-name kv-brookside-secrets --name apim-subscription-key --query value -o tsv

# Test payload
$testPayload = @{
    sessionId = "apim-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    agentName = "@apim-test-agent"
    status = "completed"
    workDescription = "APIM MCP integration test via direct API invocation"
    startTime = (Get-Date).AddMinutes(-3).ToString('yyyy-MM-ddTHH:mm:ssZ')
    endTime = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
    durationMinutes = 3
    queuedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
    syncStatus = "pending"
    retryCount = 0
} | ConvertTo-Json

# Invoke via APIM gateway
Invoke-RestMethod `
    -Uri "https://apim-brookside-innovation.azure-api.net/webhook/NotionWebhook" `
    -Method Post `
    -Headers @{
        "Ocp-Apim-Subscription-Key" = $apimKey
        "Content-Type" = "application/json"
    } `
    -Body $testPayload

# Expected response:
# success  : True
# message  : Agent activity logged successfully
# pageId   : <notion-page-id>
# pageUrl  : https://www.notion.so/<page-id>
# duration : 450
```

### Test 2: MCP Tool Invocation from Claude Code

**In Claude Code conversation**:

```
User: "Use the APIM MCP server to log a test agent activity to Notion"

Expected: Claude Code invokes the azure-apim-innovation MCP server's log-activity tool,
which routes through APIM policies, then to Azure Function, then creates Notion page.

Verify:
1. MCP tool appears in Claude's available tools
2. Tool invocation succeeds
3. Notion page created in Agent Activity Hub
4. APIM Application Insights shows request trace
```

### Test 3: Policy Enforcement Verification

```powershell
# Test rate limiting - send 101 requests in 60 seconds (should get 429 on 101st)
1..101 | ForEach-Object {
    try {
        $result = Invoke-RestMethod `
            -Uri "https://apim-brookside-innovation.azure-api.net/webhook/NotionWebhook" `
            -Method Post `
            -Headers @{"Ocp-Apim-Subscription-Key" = $apimKey; "Content-Type" = "application/json"} `
            -Body $testPayload
        Write-Host "$_`: Success" -ForegroundColor Green
    } catch {
        Write-Host "$_`: Rate limited - $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 500
}

# Expected: First 100 succeed, 101st returns 429 Too Many Requests
```

---

## Monitoring

### Application Insights Queries

```kql
// APIM request traces (last 24 hours)
requests
| where timestamp > ago(24h)
| where cloud_RoleName == "apim-brookside-innovation"
| project timestamp, name, resultCode, duration, operation_Id
| order by timestamp desc

// Failed requests
requests
| where timestamp > ago(24h)
| where cloud_RoleName == "apim-brookside-innovation"
| where success == false
| project timestamp, name, resultCode, customDimensions
| order by timestamp desc

// Rate limiting events
traces
| where timestamp > ago(24h)
| where message contains "rate-limit"
| project timestamp, severityLevel, message
| order by timestamp desc

// Backend dependency calls (APIM → Azure Function)
dependencies
| where timestamp > ago(24h)
| where target contains "notion-webhook"
| project timestamp, name, duration, success, resultCode
| order by timestamp desc
```

### APIM Analytics Dashboard

**Navigate**: Azure Portal → APIM → **Analytics**

**Key Metrics**:
- **Request volume**: Total API calls per hour/day
- **Response codes**: Distribution of 2xx, 4xx, 5xx responses
- **Latency**: P50, P95, P99 response times
- **Top consumers**: Subscription keys with highest usage
- **Error rate**: Failed requests / total requests

---

## Troubleshooting

### Issue 1: MCP Server Not Appearing in Claude Code

**Symptoms**: `claude mcp list` doesn't show `azure-apim-innovation` server

**Diagnosis**:
```powershell
# Check config file exists and is valid JSON
$configPath = "$env:APPDATA\Claude\claude_desktop_config.json"
if (Test-Path $configPath) {
    Get-Content $configPath | ConvertFrom-Json | ConvertTo-Json -Depth 10
} else {
    Write-Host "Config file not found at $configPath" -ForegroundColor Red
}
```

**Solutions**:
- ✅ Verify config file syntax (trailing commas break JSON)
- ✅ Restart Claude Code application completely
- ✅ Check `claude_desktop_config.json` is in correct location (platform-specific)
- ✅ Ensure APIM URL is correct (check for typos)

### Issue 2: 401 Unauthorized from APIM

**Symptoms**: API calls return `401 Unauthorized`

**Diagnosis**:
```bash
# Test subscription key validity
curl -X POST \
  "https://apim-brookside-innovation.azure-api.net/webhook/NotionWebhook" \
  -H "Ocp-Apim-Subscription-Key: $APIM_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sessionId":"test","agentName":"@test","status":"completed","startTime":"2025-01-01T00:00:00Z","queuedAt":"2025-01-01T00:00:00Z","syncStatus":"pending","retryCount":0}'

# Check subscription status
az apim subscription show \
  --resource-group rg-brookside-innovation \
  --service-name apim-brookside-innovation \
  --subscription-id master \
  --query "{State:state, PrimaryKey:primaryKey}"
```

**Solutions**:
- ✅ Verify subscription key in Claude config matches APIM subscription
- ✅ Check subscription state is `Active` (not `Suspended` or `Expired`)
- ✅ Regenerate subscription key if compromised
- ✅ Ensure header name is exactly `Ocp-Apim-Subscription-Key` (case-sensitive)

### Issue 3: 500 Internal Server Error from Backend

**Symptoms**: APIM returns 200, but backend (Azure Function) returns 500

**Diagnosis**:
```bash
# Check backend function logs
az functionapp log tail \
  --name notion-webhook-brookside-prod \
  --resource-group rg-brookside-innovation

# Check APIM → Function dependency health
az apim api operation show \
  --resource-group rg-brookside-innovation \
  --service-name apim-brookside-innovation \
  --api-id notion-activity-webhook \
  --operation-id log-activity
```

**Solutions**:
- ✅ Verify Azure Function is running (`az functionapp show --query state`)
- ✅ Check Function App logs for errors (Application Insights or Live Metrics)
- ✅ Ensure APIM backend URL matches Function URL
- ✅ Test Function directly (bypass APIM) to isolate issue

### Issue 4: Policy Execution Errors

**Symptoms**: APIM policy errors in Application Insights traces

**Diagnosis**:
```kql
traces
| where timestamp > ago(1h)
| where message contains "policy"
| where severityLevel >= 3  // Warning or Error
| project timestamp, message, customDimensions
| order by timestamp desc
```

**Solutions**:
- ✅ Validate XML policy syntax (Azure Portal shows errors)
- ✅ Check named values exist (`az apim nv list`)
- ✅ Verify policy expressions compile (C# syntax check)
- ✅ Avoid accessing `context.Response.Body` (breaks streaming)
- ✅ Test policies incrementally (add one at a time)

### Issue 5: Rate Limiting Too Aggressive

**Symptoms**: Legitimate requests getting 429 errors

**Diagnosis**:
```kql
requests
| where timestamp > ago(1h)
| where resultCode == 429
| summarize Count=count() by bin(timestamp, 5m), cloud_RoleInstance
| order by timestamp desc
```

**Solutions**:
- ✅ Increase rate limit in policy (`<rate-limit calls="200" renewal-period="60" />`)
- ✅ Create separate subscriptions for different consumers (individual limits)
- ✅ Use quota for longer-term limits instead of short-term rate limits
- ✅ Implement retry logic in client with exponential backoff

---

## Cost Optimization

### Current Configuration Cost Breakdown

**APIM Consumption Tier**:
- **Base**: $0.035 per 10,000 calls
- **Expected usage**: ~200 agent activities/month = 200 calls
- **Monthly cost**: $0.001 (within free tier: 1M calls/month free for first 12 months)
- **After free tier**: ~$0.01/month

**Azure Function** (existing webhook cost):
- **Executions**: ~200/month
- **Duration**: ~500ms average
- **Monthly cost**: $0.20-$2.00/month (within free tier)

**Application Insights** (shared with Function):
- **Data ingestion**: ~10 MB/month (APIM traces)
- **Monthly cost**: $0.23/month ($2.30/GB)

**Total Monthly Cost**:
- **During free tier** (first 12 months): $0.23-$2.23/month
- **After free tier**: $0.24-$2.24/month

### Cost Optimization Strategies

1. **Use Consumption Tier for Low-Volume APIs** ($0 vs $50+ for Basic tier)
2. **Set Realistic Rate Limits** (prevent abuse, reduce costs)
3. **Monitor and Alert on Usage Spikes** (detect anomalies early)
4. **Leverage Free Tier** (1M APIM calls/month for first 12 months)
5. **Cache Responses When Appropriate** (reduce backend calls)
6. **Use Quota Policies** (hard monthly limits to prevent runaway costs)

---

## Security Considerations

### Authentication Layers

1. **Subscription Key** (APIM gateway)
   - Primary authentication for APIM access
   - Stored in Key Vault, referenced in Claude config
   - Regenerate periodically (90 days recommended)

2. **Webhook Signature** (Backend validation)
   - HMAC-SHA256 signature verification in Azure Function
   - APIM policy auto-generates signature if client omits
   - Prevents unauthorized direct Function access (bypass APIM)

3. **Managed Identity** (Azure Function → Key Vault)
   - No credentials in code or environment variables
   - Function retrieves secrets from Key Vault via Managed Identity

### Security Best Practices

- ✅ **Store subscription keys in Key Vault** (not plaintext in config)
- ✅ **Use HTTPS only** (enforced by APIM and Function)
- ✅ **Enable CORS restrictively** (whitelist origins if possible)
- ✅ **Monitor for suspicious patterns** (sudden traffic spikes, new geolocations)
- ✅ **Rotate subscription keys quarterly** (scheduled Key Vault rotation)
- ✅ **Audit APIM logs regularly** (Application Insights anomaly detection)
- ✅ **Use separate subscriptions for dev/prod** (environment isolation)

### Network Security (Future Enhancement)

**Phase 2 Considerations**:
- **Virtual Network Integration**: Deploy APIM in VNet for private connectivity
- **Private Endpoints**: Function accessible only via APIM (not public internet)
- **IP Restrictions**: Whitelist specific IP ranges for APIM access
- **Azure Firewall**: Centralized network security for all Azure resources

---

## Phase 2: Additional APIs

### Planned API Expansions

1. **Queue Processor Trigger API**
   - Endpoint: `POST /api/queue/process`
   - Purpose: Manually trigger queue processing (sync pending activities)
   - Use case: Agent needs to force-sync activities on demand

2. **Cost Analytics API**
   - Endpoint: `GET /api/costs/summary`
   - Purpose: Retrieve software spend analysis programmatically
   - Use case: Agent generates cost reports, identifies unused tools

3. **Repository Analyzer API**
   - Endpoint: `POST /api/repos/analyze`
   - Purpose: Trigger repository viability analysis
   - Use case: Agent analyzes new repos, updates Notion Example Builds

4. **Power BI Integration API** (if applicable)
   - Endpoint: `GET /api/powerbi/datasets`
   - Purpose: List datasets, refresh schedules, usage metrics
   - Use case: Agent monitors Power BI governance

### Implementation Strategy

For each new API:
1. Deploy backend service (Azure Function, Container App, etc.)
2. Import API into APIM (`az apim api create`)
3. Configure policies (auth, rate limit, caching)
4. Create MCP server export
5. Update Claude Code config
6. Test end-to-end invocation
7. Document in this guide

---

## Related Documentation

- **[Webhook Architecture](.claude/docs/webhook-architecture.md)** - Backend API design
- **[MCP Configuration](.claude/docs/mcp-configuration.md)** - All MCP servers setup
- **[Azure Infrastructure](.claude/docs/azure-infrastructure.md)** - Resource overview
- **[Troubleshooting Webhook](.claude/docs/webhook-troubleshooting.md)** - Backend debugging

---

**Brookside BI Innovation Nexus** - Establish AI agent access to production APIs through enterprise-grade governance and security.
