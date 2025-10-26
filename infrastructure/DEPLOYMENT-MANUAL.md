# Manual Deployment Instructions

Due to Azure CLI response handling issues in the automated environment, please execute these commands manually to complete the webhook deployment.

## Prerequisites Completed ✓

- ✅ Azure authentication verified (Azure subscription 1)
- ✅ Resource group created: `rg-brookside-innovation`
- ✅ Webhook secret generated and stored in Key Vault: `kv-brookside-secrets/notion-webhook-secret`
- ✅ All code implementation complete (TypeScript, PowerShell, Bicep)

## Step 1: Deploy Bicep Infrastructure

Open PowerShell or Azure Cloud Shell and run:

```powershell
# Navigate to infrastructure directory
cd c:\Users\MarkusAhling\Notion\infrastructure

# Deploy Bicep template
az deployment group create `
  --name webhook-deployment `
  --resource-group rg-brookside-innovation `
  --template-file notion-webhook-function.bicep `
  --parameters @notion-webhook-function.parameters.json `
  --output table

# Expected output:
# Name                 ResourceGroup           State      Timestamp
# -------------------  ----------------------  ---------  --------------------
# webhook-deployment   rg-brookside-innovation  Succeeded  2025-10-26T...
```

**Deployment creates**:
- Storage Account: `stnotionwebhookprod`
- Application Insights: `ai-notion-webhook-prod`
- App Service Plan: `asp-notion-webhook-prod` (Consumption Y1)
- Function App: `notion-webhook-brookside-prod`
- Managed Identity with Key Vault access

**Estimated time**: 3-5 minutes

## Step 2: Verify Deployment

```powershell
# Check function app status
az functionapp show `
  --name notion-webhook-brookside-prod `
  --resource-group rg-brookside-innovation `
  --query "{Name:name, State:state, DefaultHostName:defaultHostName}" `
  --output table

# Verify Managed Identity
az functionapp identity show `
  --name notion-webhook-brookside-prod `
  --resource-group rg-brookside-innovation `
  --query "principalId" -o tsv

# Check Key Vault access (should show the principal ID)
az keyvault show --name kv-brookside-secrets `
  --query "properties.accessPolicies[].objectId" -o tsv
```

## Step 3: Build Function Code

```powershell
# Navigate to function project
cd c:\Users\MarkusAhling\Notion\azure-functions\notion-webhook

# Install dependencies
npm install

# Build TypeScript
npm run build

# Expected output:
# > notion-webhook@1.0.0 build
# > tsc
#
# (No errors - clean build)
```

## Step 4: Deploy Function Code

```powershell
# Still in azure-functions/notion-webhook directory
func azure functionapp publish notion-webhook-brookside-prod

# Expected output:
# Getting site publishing info...
# Preparing archive...
# Uploading content...
# Upload completed successfully.
# Deployment completed successfully.
# Syncing triggers...
# Functions in notion-webhook-brookside-prod:
#     NotionWebhook - [httpTrigger]
#         Invoke url: https://notion-webhook-brookside-prod.azurewebsites.net/api/NotionWebhook
```

**Copy the Invoke URL** - you'll need it for testing.

## Step 5: Test Webhook Endpoint

```powershell
# Navigate back to root
cd c:\Users\MarkusAhling\Notion

# Test endpoint accessibility
.\. claude\utils\webhook-utilities.ps1 -Operation TestEndpoint

# Get webhook secret from Key Vault
$webhookSecret = az keyvault secret show `
  --vault-name kv-brookside-secrets `
  --name notion-webhook-secret `
  --query value -o tsv

# Send test payload
.\. claude\utils\webhook-utilities.ps1 `
  -Operation SendTestPayload `
  -WebhookSecret $webhookSecret

# Expected output:
# [SUCCESS] Webhook request successful!
#
# Response Details:
#   Success: True
#   Message: Agent activity logged successfully
#   Page ID: <notion-page-id>
#   Page URL: https://notion.so/...
#   Duration: 450ms
```

## Step 6: Verify in Notion

1. Navigate to Agent Activity Hub: https://www.notion.so/72b879f213bd4edb9c59b43089dbef21
2. Look for test entry with Session ID: `test-webhook-<timestamp>`
3. Verify all properties populated correctly

## Step 7: Trigger Real Agent Activity

```powershell
# Trigger a real agent (any agent that does meaningful work)
# For example, analyze costs:
claude

# In Claude Code, run:
# /cost:analyze all
```

The hook should now attempt webhook sync first, then queue as backup:

```
Hook logs (.claude/logs/auto-activity-hook.log):
[2025-10-26 ...] [INFO] Attempting webhook sync to: https://notion-webhook-brookside-prod.azurewebsites.net/api/NotionWebhook
[2025-10-26 ...] [SUCCESS] Webhook sync successful - Page created: https://notion.so/...
[2025-10-26 ...] [SUCCESS] Successfully synced via webhook + queued as backup: cost-analyst-...
```

Queue processor will skip this entry on next run:
```
Queue processor logs (.claude/logs/notion-queue-processor.log):
[2025-10-26 ...] [DEBUG] Skipping entry 1 (SessionId=cost-analyst-...) - Already synced via webhook
[2025-10-26 ...] [INFO] Skipped 1 entries already synced via webhook
```

## Step 8: Monitor with Application Insights

```powershell
# View recent requests
az monitor app-insights query `
  --app ai-notion-webhook-prod `
  --resource-group rg-brookside-innovation `
  --analytics-query "requests | where timestamp > ago(1h) | project timestamp, name, success, duration" `
  --output table

# View errors (should be empty)
az monitor app-insights query `
  --app ai-notion-webhook-prod `
  --resource-group rg-brookside-innovation `
  --analytics-query "exceptions | where timestamp > ago(1h) | project timestamp, outerMessage" `
  --output table
```

## Troubleshooting

If webhook test fails with 401 Unauthorized:
```powershell
# Verify secrets match
$vaultSecret = az keyvault secret show --vault-name kv-brookside-secrets --name notion-webhook-secret --query value -o tsv
Write-Host "Vault secret (first 8 chars): $($vaultSecret.Substring(0, 8))..."

# Restart function app to clear cached secrets
az functionapp restart --name notion-webhook-brookside-prod --resource-group rg-brookside-innovation

# Wait 30 seconds, then retry test
```

If webhook test fails with 500 Internal Server Error:
```powershell
# Check function app logs
func azure functionapp logstream notion-webhook-brookside-prod

# Or view in Azure Portal:
# Function App → Monitor → Log stream
```

If Notion page not created:
```powershell
# Verify Notion integration shared with database
# 1. Go to: https://www.notion.so/7163aa38-f3d9-444b-9674-bde61868bd2b
# 2. Click "..." → "Connections"
# 3. Add your Notion integration
```

## Success Criteria

✅ Infrastructure deployed (all Azure resources created)
✅ Function code deployed (NotionWebhook endpoint available)
✅ Test payload succeeds (200 OK response with Notion page URL)
✅ Test page appears in Agent Activity Hub
✅ Real agent activity triggers webhook sync
✅ Queue processor skips webhook-synced entries
✅ Application Insights shows successful requests

## Reference

- **Webhook Architecture**: [.claude/docs/webhook-architecture.md](.claude/docs/webhook-architecture.md)
- **Troubleshooting Guide**: [.claude/docs/webhook-troubleshooting.md](.claude/docs/webhook-troubleshooting.md)
- **Azure Portal**: https://portal.azure.com/#@2930489e-9d8a-456b-9de9-e4787faeab9c/resource/subscriptions/cfacbbe8-a2a3-445f-a188-68b3b35f0c84/resourceGroups/rg-brookside-innovation/overview

---

**Generated**: 2025-10-26
**Webhook Secret Stored**: kv-brookside-secrets/notion-webhook-secret
**Resource Group**: rg-brookside-innovation
**Function App**: notion-webhook-brookside-prod
