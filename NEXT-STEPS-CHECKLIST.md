# Webhook + APIM MCP - Next Steps Checklist

**Status**: Infrastructure 85% complete. Execute these manual steps to complete deployment.

**Estimated Total Time**: 60-75 minutes

---

## ✅ Prerequisites (Already Complete)

- ✅ APIM instance provisioned (`apim-brookside-innovation`)
- ✅ Webhook API imported into APIM
- ✅ Webhook secret stored in Key Vault
- ✅ All code complete and ready to deploy
- ✅ Bicep templates prepared
- ✅ Policy XML designed
- ✅ Documentation complete

---

## 📋 Step-by-Step Execution

### Step 1: Deploy Webhook Azure Function (15-20 min)

**Open PowerShell as Administrator** and execute:

```powershell
# Navigate to infrastructure directory
cd c:\Users\MarkusAhling\Notion\infrastructure

# Deploy Bicep infrastructure
az deployment group create `
  --name webhook-deployment `
  --resource-group rg-brookside-innovation `
  --template-file notion-webhook-function.bicep `
  --parameters @notion-webhook-function.parameters.json `
  --output table

# Wait for deployment (5-10 minutes)
# Expected output: ProvisioningState = Succeeded

# Verify deployment
az functionapp show `
  --name notion-webhook-brookside-prod `
  --resource-group rg-brookside-innovation `
  --query "{Name:name, State:state, DefaultHostName:defaultHostName}" `
  --output table
```

**Checkpoint**: Function App shows `State: Running`

---

### Step 2: Build and Deploy Function Code (5 min)

```powershell
# Navigate to function app directory
cd c:\Users\MarkusAhling\Notion\azure-functions\notion-webhook

# Install dependencies
npm install

# Build TypeScript
npm run build

# Deploy to Azure
func azure functionapp publish notion-webhook-brookside-prod

# Expected output: "Deployment successful"
```

**Checkpoint**: Function code deployed, endpoints listed

---

### Step 3: Test Webhook Endpoint (5 min)

```powershell
# Navigate to repo root
cd c:\Users\MarkusAhling\Notion

# Set webhook secret
$webhookSecret = "16997736f8a1727d23871acc6cb1586e03768f9c1704865c009bb391e608acf0"

# Send test payload
.\.claude\utils\webhook-utilities.ps1 `
  -Operation SendTestPayload `
  -WebhookSecret $webhookSecret

# Expected output:
# ✓ Webhook request successful
# Page URL: https://www.notion.so/<page-id>
```

**Checkpoint**: Notion page created in Agent Activity Hub
- Verify at: https://www.notion.so/72b879f213bd4edb9c59b43089dbef21

---

### Step 4: Apply APIM Policy (5 min)

**Azure Portal Method**:

1. Navigate to [Azure Portal](https://portal.azure.com)
2. Search for `apim-brookside-innovation`
3. Left menu: **APIs** → `notion-activity-webhook`
4. Click **All operations**
5. Click **Policies** button (code icon `</>`)
6. Replace entire policy XML with contents from:
   `c:\Users\MarkusAhling\Notion\infrastructure\apim-webhook-policy.xml`
7. Click **Save**

**Checkpoint**: Policy saved successfully, no validation errors

---

### Step 5: Create APIM MCP Server Export (5 min)

**Azure Portal (Preview Mode Required)**:

1. Navigate to [Portal with MCP Preview](https://portal.azure.com/?feature.canmodifystamps=true&Microsoft_Azure_ApiManagement=mcp)
2. Search for `apim-brookside-innovation`
3. Left menu: **APIs** → **MCP Servers**
4. Click **+ Create MCP server**
5. Select **Expose an API as an MCP server**
6. Configuration:
   - **API**: `notion-activity-webhook`
   - **Operations**: Check `log-activity (POST /NotionWebhook)`
   - **MCP Server Name**: `notion-activity-mcp`
   - **Description**: `Expose Notion webhook for AI agent activity logging`
7. Click **Create**
8. **IMPORTANT**: Copy the Server URL displayed:
   - Should be: `https://apim-brookside-innovation.azure-api.net/notion-activity-mcp/mcp`

**Checkpoint**: MCP server created, URL copied to clipboard

---

### Step 6: Get and Store APIM Subscription Key (5 min)

```powershell
# Get APIM subscription key
$apimKey = az apim subscription show `
  --resource-group rg-brookside-innovation `
  --service-name apim-brookside-innovation `
  --subscription-id master `
  --query "primaryKey" `
  --output tsv

# Store in Key Vault
az keyvault secret set `
  --vault-name kv-brookside-secrets `
  --name apim-subscription-key `
  --value $apimKey

# Verify storage
az keyvault secret show `
  --vault-name kv-brookside-secrets `
  --name apim-subscription-key `
  --query "name"
```

**Checkpoint**: Secret stored in Key Vault

---

### Step 7: Configure Claude Code MCP Client (10 min)

**Edit Claude Configuration File**:

```powershell
# Open config file in editor
notepad "$env:APPDATA\Claude\claude_desktop_config.json"
```

**Add APIM MCP Server** to the `mcpServers` section:

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

**Set Environment Variable**:

```powershell
# Retrieve key from Key Vault
$apimKey = az keyvault secret show `
  --vault-name kv-brookside-secrets `
  --name apim-subscription-key `
  --query value `
  --output tsv

# Set user-level environment variable
[System.Environment]::SetEnvironmentVariable('APIM_SUBSCRIPTION_KEY', $apimKey, 'User')

# Verify variable set
$env:APIM_SUBSCRIPTION_KEY
```

**Restart Claude Code**:
- Close Claude Code application completely
- Reopen Claude Code

**Checkpoint**: Claude Code restarted successfully

---

### Step 8: Verify MCP Connection (2 min)

**In PowerShell**:

```powershell
# List all MCP servers
claude mcp list

# Expected output should include:
# ✓ azure-apim-innovation (Connected)
#   URL: https://apim-brookside-innovation.azure-api.net/notion-activity-mcp/mcp
#   Tools: log-activity
```

**Checkpoint**: APIM MCP server shows as connected with `log-activity` tool

---

### Step 9: End-to-End Testing (15 min)

**Test 1: Direct Webhook (via Hook)**

```powershell
# Trigger any agent that modifies files
# Example: Ask Claude to create a test file
# The auto-log hook should invoke webhook automatically

# Check hook logs
Get-Content .\.claude\logs\agent-hook-debug.log -Tail 20

# Look for: "Successfully synced via webhook" message

# Verify page in Notion Agent Activity Hub
# URL: https://www.notion.so/72b879f213bd4edb9c59b43089dbef21
```

**Test 2: MCP Tool Invocation (via APIM)**

**In Claude Code conversation**:

```
User: "Use the azure-apim-innovation MCP server to log a test agent activity to Notion with these details:
- Session ID: mcp-test-20251026
- Agent: @apim-test-agent
- Status: completed
- Work Description: End-to-end MCP tool invocation test via APIM gateway"

Expected: Claude invokes the log-activity tool, which routes through APIM policies,
then to Azure Function, then creates Notion page in Agent Activity Hub
```

**Verify**:
1. Claude responds with success message and Notion page URL
2. Page visible in Agent Activity Hub
3. Application Insights shows request trace from APIM

**Test 3: Rate Limiting Validation**

```powershell
# Send 101 requests rapidly (should get 429 on 101st)
1..101 | ForEach-Object {
    try {
        $result = Invoke-RestMethod `
            -Uri "https://apim-brookside-innovation.azure-api.net/webhook/NotionWebhook" `
            -Method Post `
            -Headers @{
                "Ocp-Apim-Subscription-Key" = $env:APIM_SUBSCRIPTION_KEY
                "Content-Type" = "application/json"
            } `
            -Body '{"sessionId":"rate-test","agentName":"@test","status":"completed","startTime":"2025-01-01T00:00:00Z","queuedAt":"2025-01-01T00:00:00Z","syncStatus":"pending","retryCount":0}'
        Write-Host "$_: Success" -ForegroundColor Green
    } catch {
        Write-Host "$_: Rate limited - $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 500
}

# Expected: First 100 succeed, 101st returns 429 Too Many Requests
```

**Checkpoint**: All 3 tests pass successfully

---

## ✅ Success Criteria

You've successfully completed deployment when:

- ✅ Webhook Azure Function deployed and running
- ✅ Test payload creates Notion page via direct webhook call
- ✅ APIM policies applied (visible in portal)
- ✅ MCP server export created and URL obtained
- ✅ Claude Code MCP client configured with APIM server
- ✅ `claude mcp list` shows `azure-apim-innovation` as Connected
- ✅ Agent hook triggers create Notion pages automatically
- ✅ MCP tool invocation from Claude creates Notion pages via APIM
- ✅ Rate limiting enforced (429 errors after 100 calls/minute)
- ✅ Application Insights shows telemetry from both webhook and APIM

---

## 🚨 Troubleshooting

### Issue: Bicep Deployment Fails

**Check**:
```powershell
# Verify authentication
az account show

# Check resource group exists
az group show --name rg-brookside-innovation
```

**Fix**: Re-authenticate with `az login` if needed

---

### Issue: Function Deployment Fails

**Check**:
```powershell
# Verify Function App exists
az functionapp show --name notion-webhook-brookside-prod --resource-group rg-brookside-innovation

# Check build succeeded
npm run build
# Should show no TypeScript errors
```

**Fix**: Review error messages, ensure `npm install` completed successfully

---

### Issue: Webhook Test Returns 401 Unauthorized

**Check**:
```powershell
# Verify secret matches
az keyvault secret show --vault-name kv-brookside-secrets --name notion-webhook-secret --query value
```

**Fix**: Regenerate signature with correct secret value

---

### Issue: Webhook Test Returns 500 Internal Server Error

**Check**:
```powershell
# View function logs
az functionapp log tail --name notion-webhook-brookside-prod --resource-group rg-brookside-innovation

# Check Application Insights
# Portal: apim-brookside-innovation → Application Insights → Logs
# Query: exceptions | where timestamp > ago(1h)
```

**Fix**: Review detailed error in logs, check Notion API key and database permissions

---

### Issue: MCP Server Not Showing as Connected

**Check**:
```powershell
# Verify environment variable set
$env:APIM_SUBSCRIPTION_KEY
# Should output the subscription key

# Check config file syntax
Get-Content "$env:APPDATA\Claude\claude_desktop_config.json" | ConvertFrom-Json
# Should parse without errors
```

**Fix**:
- Restart Claude Code completely
- Verify no trailing commas in JSON config
- Ensure subscription key is correct

---

### Issue: MCP Tool Invocation Returns 401

**Check**:
```powershell
# Test subscription key directly
curl -X POST "https://apim-brookside-innovation.azure-api.net/webhook/NotionWebhook" `
  -H "Ocp-Apim-Subscription-Key: $env:APIM_SUBSCRIPTION_KEY" `
  -H "Content-Type: application/json" `
  -d '{"sessionId":"test","agentName":"@test","status":"completed","startTime":"2025-01-01T00:00:00Z","queuedAt":"2025-01-01T00:00:00Z","syncStatus":"pending","retryCount":0}'
```

**Fix**: Regenerate subscription key if invalid, update Key Vault and environment variable

---

## 📚 Documentation Reference

- **Full Status Report**: `WEBHOOK-APIM-IMPLEMENTATION-STATUS.md`
- **Manual Deployment Guide**: `infrastructure/DEPLOYMENT-MANUAL.md`
- **APIM MCP Configuration**: `.claude/docs/azure-apim-mcp-configuration.md`
- **Webhook Troubleshooting**: `.claude/docs/webhook-troubleshooting.md`
- **Webhook Architecture**: `.claude/docs/webhook-architecture.md`

---

## 📞 Support

**Stuck on any step?**
- Review detailed documentation in files above
- Check Application Insights logs for errors
- Contact: Consultations@BrooksideBI.com | +1 209 487 2047

---

**Brookside BI Innovation Nexus** - Complete these 9 steps to activate real-time agent activity tracking with AI-native API invocation through Azure APIM MCP server.
