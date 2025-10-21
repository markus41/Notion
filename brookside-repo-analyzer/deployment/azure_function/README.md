# Azure Function Deployment for Repository Analyzer

This solution establishes serverless, scheduled execution of repository analysis to streamline portfolio management through automated weekly scans.

## Overview

**Deployment Model**: Azure Functions (Consumption Plan)
**Schedule**: Weekly on Sunday at 00:00 UTC
**Estimated Cost**: $5-10/month
**Runtime**: Python 3.11

## Architecture

```
┌─────────────────────────────────────┐
│   Azure Function App                │
│   (Consumption Plan)                │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐ │
│  │  Timer Trigger (Weekly)       │ │
│  │  Schedule: 0 0 0 * * 0        │ │
│  └───────────┬───────────────────┘ │
│              │                       │
│  ┌───────────▼───────────────────┐ │
│  │  Repository Scanner           │ │
│  │  - List org repos             │ │
│  │  - Analyze each repo          │ │
│  │  - Extract patterns           │ │
│  │  - Calculate costs            │ │
│  └───────────┬───────────────────┘ │
│              │                       │
│  ┌───────────▼───────────────────┐ │
│  │  Notion Sync                  │ │
│  │  - Create Build entries       │ │
│  │  - Update Knowledge Vault     │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
          │           │
          │           └──────> Notion API
          └──────────────────> GitHub API
                               Azure Key Vault
```

## Prerequisites

1. **Azure CLI**: `az --version` >= 2.77.0
2. **Azure Functions Core Tools**: `func --version` >= 4.0.0
3. **Python**: 3.11
4. **Poetry** (for local development): >= 1.7.0

## Local Development

### Setup

```bash
# Navigate to function directory
cd deployment/azure_function

# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy local settings template
cp local.settings.json.example local.settings.json

# Edit local.settings.json with your credentials
# IMPORTANT: Never commit local.settings.json to git
```

### Configuration (local.settings.json)

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "AZURE_KEYVAULT_NAME": "kv-brookside-secrets",
    "AZURE_TENANT_ID": "your-tenant-id",
    "AZURE_SUBSCRIPTION_ID": "your-subscription-id",
    "GITHUB_ORG": "brookside-bi",
    "NOTION_WORKSPACE_ID": "your-workspace-id",
    "ANALYSIS_CACHE_TTL_HOURS": "168",
    "MAX_CONCURRENT_ANALYSES": "10",
    "DEEP_ANALYSIS_ENABLED": "true",
    "DETECT_CLAUDE_CONFIGS": "true",
    "CALCULATE_COSTS": "true"
  }
}
```

### Run Locally

```bash
# Start Azure Functions runtime
func start

# Test health endpoint
curl http://localhost:7071/api/health

# Trigger manual scan (requires auth)
curl -X POST http://localhost:7071/api/manual-scan \
  -H "Content-Type: application/json" \
  -d '{"deep_analysis": true, "sync_to_notion": false}'
```

## Azure Deployment

### Step 1: Create Azure Resources

```bash
# Set variables
RESOURCE_GROUP="rg-brookside-prod"
LOCATION="eastus"
STORAGE_ACCOUNT="stbrooksideanalyzer"
FUNCTION_APP="func-repo-analyzer"
APP_INSIGHTS="ai-repo-analyzer"

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS

# Create Application Insights
az monitor app-insights component create \
  --app $APP_INSIGHTS \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# Get instrumentation key
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app $APP_INSIGHTS \
  --resource-group $RESOURCE_GROUP \
  --query instrumentationKey -o tsv)

# Create Function App
az functionapp create \
  --resource-group $RESOURCE_GROUP \
  --name $FUNCTION_APP \
  --storage-account $STORAGE_ACCOUNT \
  --runtime python \
  --runtime-version 3.11 \
  --functions-version 4 \
  --os-type Linux \
  --consumption-plan-location $LOCATION \
  --app-insights $APP_INSIGHTS

# Configure managed identity
az functionapp identity assign \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP

# Get managed identity principal ID
PRINCIPAL_ID=$(az functionapp identity show \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --query principalId -o tsv)
```

### Step 2: Configure Key Vault Access

```bash
# Grant Function App access to Key Vault
az keyvault set-policy \
  --name kv-brookside-secrets \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get list
```

### Step 3: Configure Application Settings

```bash
# Set environment variables
az functionapp config appsettings set \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --settings \
    AZURE_KEYVAULT_NAME="kv-brookside-secrets" \
    AZURE_TENANT_ID="2930489e-9d8a-456b-9de9-e4787faeab9c" \
    AZURE_SUBSCRIPTION_ID="cfacbbe8-a2a3-445f-a188-68b3b35f0c84" \
    GITHUB_ORG="brookside-bi" \
    NOTION_WORKSPACE_ID="81686779-099a-8195-b49e-00037e25c23e" \
    ANALYSIS_CACHE_TTL_HOURS="168" \
    MAX_CONCURRENT_ANALYSES="10" \
    DEEP_ANALYSIS_ENABLED="true" \
    DETECT_CLAUDE_CONFIGS="true" \
    CALCULATE_COSTS="true"
```

### Step 4: Deploy Function Code

```bash
# From repository root
cd c:\Users\MarkusAhling\Notion\brookside-repo-analyzer

# Deploy via Azure Functions Core Tools
func azure functionapp publish $FUNCTION_APP

# OR deploy via Azure CLI
az functionapp deployment source config-zip \
  --resource-group $RESOURCE_GROUP \
  --name $FUNCTION_APP \
  --src deployment/azure_function.zip
```

### Step 5: Verify Deployment

```bash
# Check function status
az functionapp show \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --query state

# Test health endpoint
FUNCTION_URL=$(az functionapp show \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --query defaultHostName -o tsv)

curl "https://$FUNCTION_URL/api/health"

# View logs
az functionapp log tail \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP
```

## Monitoring

### Application Insights

```bash
# View recent executions
az monitor app-insights metrics show \
  --app $APP_INSIGHTS \
  --resource-group $RESOURCE_GROUP \
  --metric "requests/count" \
  --interval PT1H

# Query execution logs
az monitor app-insights query \
  --app $APP_INSIGHTS \
  --analytics-query "requests | where timestamp > ago(24h) | project timestamp, name, resultCode, duration"
```

### Function Logs

```bash
# Stream live logs
func azure functionapp logstream $FUNCTION_APP

# View execution history
az functionapp function show \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --function-name weekly_repository_scan
```

## Troubleshooting

### Common Issues

**Issue**: "Key Vault access denied"
```bash
# Solution: Verify managed identity has correct permissions
az keyvault show-policy \
  --name kv-brookside-secrets \
  --object-id $PRINCIPAL_ID
```

**Issue**: "Module not found" errors
```bash
# Solution: Ensure requirements.txt includes all dependencies
# Redeploy function app
func azure functionapp publish $FUNCTION_APP --build remote
```

**Issue**: "Function timeout"
```bash
# Solution: Increase timeout in host.json
# Current: "functionTimeout": "00:10:00" (10 minutes)
# Max for Consumption: 10 minutes
# Consider Premium plan for longer executions
```

## Cost Optimization

**Current Costs** (Consumption Plan):
- **Executions**: 4 per month (weekly) × $0.20 = ~$0.80/month
- **Execution Time**: ~10 min/execution × 4 = 40 min/month = ~$2.00/month
- **Storage**: Minimal (~$0.50/month)
- **Application Insights**: ~$2.00/month
- **Total**: ~$5-7/month

**Optimization Tips**:
1. Use shallow analysis for less critical repos
2. Implement result caching to reduce execution time
3. Filter out archived/inactive repos
4. Consider Azure Functions Premium for cost predictability at scale

## Security

**Best Practices**:
- ✅ Use Managed Identity (no credential storage)
- ✅ Store secrets in Azure Key Vault
- ✅ Function-level auth for manual triggers
- ✅ HTTPS-only connections
- ✅ Application Insights for audit logging

**Secrets Management**:
```bash
# Add new secret to Key Vault
az keyvault secret set \
  --vault-name kv-brookside-secrets \
  --name new-secret-name \
  --value "secret_value"

# Function app will automatically access via managed identity
```

## Maintenance

### Update Function Code

```bash
# Make code changes
# Test locally with: func start
# Deploy update
func azure functionapp publish $FUNCTION_APP
```

### Update Configuration

```bash
# Update app settings
az functionapp config appsettings set \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --settings NEW_SETTING="value"
```

### Scale Configuration

```bash
# For higher volume, upgrade to Premium plan
az functionapp plan create \
  --name premium-plan \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku EP1

az functionapp update \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --plan premium-plan
```

## CI/CD Integration

See `../github_actions/deploy-function.yml` for automated deployment workflow.

## Related Resources

- **Main Project**: [Repository Root](../../README.md)
- **Azure Functions Docs**: https://learn.microsoft.com/azure/azure-functions/
- **Python Function Reference**: https://learn.microsoft.com/azure/azure-functions/functions-reference-python

---

**Brookside BI Innovation Nexus** - Establish automated repository intelligence to streamline portfolio management and drive measurable outcomes through scheduled analysis execution.
