# ============================================================================
# COPY AND PASTE THESE COMMANDS INTO YOUR POWERSHELL WINDOW
# (Run PowerShell as Administrator)
# ============================================================================

# Navigate to infrastructure directory
cd c:\Users\MarkusAhling\Notion\infrastructure

# COMMAND 1: Deploy Infrastructure (5-10 minutes)
az deployment group create --name webhook-deployment --resource-group rg-brookside-innovation --template-file notion-webhook-function.bicep --parameters "@notion-webhook-function.parameters.json" --output table

# COMMAND 2: Verify deployment
az functionapp show --name notion-webhook-brookside-prod --resource-group rg-brookside-innovation --query "{Name:name, State:state, DefaultHostName:defaultHostName}" --output table

# COMMAND 3: Build function code
cd c:\Users\MarkusAhling\Notion\azure-functions\notion-webhook
npm install
npm run build

# COMMAND 4: Deploy function code
func azure functionapp publish notion-webhook-brookside-prod

# COMMAND 5: Test webhook
cd c:\Users\MarkusAhling\Notion
$webhookSecret = "16997736f8a1727d23871acc6cb1586e03768f9c1704865c009bb391e608acf0"
.\.claude\utils\webhook-utilities.ps1 -Operation SendTestPayload -WebhookSecret $webhookSecret

# COMMAND 6: Get APIM subscription key
$subscriptionId = "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
$resourceGroup = "rg-brookside-innovation"
$apimName = "apim-brookside-innovation"
$token = az account get-access-token --query accessToken -o tsv
$uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.ApiManagement/service/$apimName/subscriptions/master/listSecrets?api-version=2021-08-01"
$response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{Authorization = "Bearer $token"; "Content-Type" = "application/json"}
$apimKey = $response.primaryKey
Write-Host "APIM Subscription Key: $apimKey"

# COMMAND 7: Store in Key Vault
az keyvault secret set --vault-name kv-brookside-secrets --name apim-subscription-key --value $apimKey

# COMMAND 8: Set environment variable
[System.Environment]::SetEnvironmentVariable('APIM_SUBSCRIPTION_KEY', $apimKey, 'User')
$env:APIM_SUBSCRIPTION_KEY = $apimKey
Write-Host "Environment variable set: APIM_SUBSCRIPTION_KEY"

# ============================================================================
# AFTER RUNNING THESE COMMANDS, COMPLETE THESE PORTAL STEPS:
# ============================================================================
#
# STEP 1: Apply APIM Policy
#   - Open: https://portal.azure.com
#   - Navigate to: apim-brookside-innovation -> APIs -> notion-activity-webhook
#   - Click: All operations -> Policies (</> icon)
#   - Copy XML from: c:\Users\MarkusAhling\Notion\infrastructure\apim-webhook-policy.xml
#   - Paste and Save
#
# STEP 2: Create MCP Server Export
#   - Open: https://portal.azure.com/?feature.canmodifystamps=true&Microsoft_Azure_ApiManagement=mcp
#   - Navigate to: apim-brookside-innovation -> APIs -> MCP Servers
#   - Click: + Create MCP server
#   - Select: Expose an API as an MCP server
#   - API: notion-activity-webhook
#   - Operations: Check "log-activity"
#   - Name: notion-activity-mcp
#   - Click: Create
#   - COPY THE SERVER URL SHOWN
#
# STEP 3: Configure Claude Code
#   - Edit: C:\Users\MarkusAhling\AppData\Roaming\Claude\claude_desktop_config.json
#   - Add to mcpServers section:
#
#       "azure-apim-innovation": {
#         "type": "sse",
#         "url": "https://apim-brookside-innovation.azure-api.net/notion-activity-mcp/mcp",
#         "headers": {
#           "Ocp-Apim-Subscription-Key": "{{APIM_SUBSCRIPTION_KEY}}"
#         }
#       }
#
# STEP 4: Restart Claude Code
#   - Close Claude Code completely
#   - Reopen
#   - Verify: claude mcp list (should show azure-apim-innovation Connected)
#
# ============================================================================
# TESTING
# ============================================================================
#
# Test 1: Direct webhook
#   - Trigger any agent that modifies files
#   - Check .\.claude\logs\agent-hook-debug.log for "Successfully synced via webhook"
#   - Verify page in: https://www.notion.so/72b879f213bd4edb9c59b43089dbef21
#
# Test 2: MCP tool invocation
#   - In Claude: "Use azure-apim-innovation to log a test activity"
#   - Verify Notion page created
#
# ============================================================================
