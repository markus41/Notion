# Repository Analyzer - Deployment Guide

**Version:** 1.0.0
**Last Updated:** 2025-10-21
**Target Environment:** Azure Production

## Overview

This guide establishes step-by-step procedures for deploying the Brookside BI Repository Analyzer to Azure Functions with comprehensive validation checkpoints to ensure reliable automated portfolio intelligence.

**Deployment Modes:**
1. ✅ Local CLI (Development) - Immediate
2. ✅ Azure Function (Production) - This guide
3. ✅ GitHub Actions (CI/CD) - Automated

**Estimated Deployment Time:** 30-45 minutes

**Best for:** Production deployment requiring systematic validation and operational handoff.

---

## Prerequisites

### Required Accounts & Permissions

- [ ] **Azure Subscription Access**
  - Subscription ID: `cfacbbe8-a2a3-445f-a188-68b3b35f0c84`
  - Role: Contributor or Owner on resource group
  - Verify: `az account show`

- [ ] **Azure Key Vault Access**
  - Vault: `kv-brookside-secrets`
  - Role: Key Vault Secrets User (minimum)
  - Secrets required: `github-personal-access-token`, `notion-api-key`
  - Verify: `az keyvault secret list --vault-name kv-brookside-secrets`

- [ ] **GitHub Organization Access**
  - Organization: `brookside-bi`
  - PAT Scopes: `repo`, `read:org`, `workflow`
  - Verify: Test with GitHub MCP

- [ ] **Notion Workspace Access**
  - Workspace ID: `81686779-099a-8195-b49e-00037e25c23e`
  - Databases: Example Builds, Software Tracker, Knowledge Vault
  - Permissions: Read/Write on all databases
  - Verify: Test with Notion MCP

### Required Tools

- [ ] **Azure CLI 2.50.0+**
  ```bash
  az --version
  # If not installed: https://docs.microsoft.com/cli/azure/install-azure-cli
  ```

- [ ] **Azure Functions Core Tools 4.x**
  ```bash
  func --version
  # If not installed: npm install -g azure-functions-core-tools@4
  ```

- [ ] **Python 3.11+**
  ```bash
  python --version
  ```

- [ ] **Poetry 1.7+**
  ```bash
  poetry --version
  # If not installed: https://python-poetry.org/docs/#installation
  ```

### Repository Access

- [ ] **Clone repository**
  ```bash
  git clone https://github.com/brookside-bi/brookside-repo-analyzer.git
  cd brookside-repo-analyzer/
  ```

---

## Phase 1: Infrastructure Provisioning (10-15 minutes)

### Step 1.1: Authenticate to Azure

```bash
# Login to Azure (opens browser for authentication)
az login

# Set active subscription
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"

# Verify authentication
az account show
```

**Expected Output:**
```json
{
  "id": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84",
  "name": "Azure subscription 1",
  "state": "Enabled",
  "tenantId": "2930489e-9d8a-456b-9de9-e4787faeab9c"
}
```

**Validation:**
- [ ] Subscription ID matches expected value
- [ ] State is "Enabled"
- [ ] Tenant ID is correct

---

### Step 1.2: Create Resource Group

```bash
# Create resource group in East US 2
az group create \
  --name rg-brookside-repo-analyzer \
  --location eastus2 \
  --tags \
    Environment=prod \
    Project="Brookside BI Innovation Nexus" \
    Component="Repository Analyzer" \
    ManagedBy=Bicep
```

**Expected Output:**
```json
{
  "id": "/subscriptions/.../resourceGroups/rg-brookside-repo-analyzer",
  "location": "eastus2",
  "name": "rg-brookside-repo-analyzer",
  "properties": {
    "provisioningState": "Succeeded"
  }
}
```

**Validation:**
- [ ] Provisioning state is "Succeeded"
- [ ] Location is "eastus2"
- [ ] Tags are applied correctly

---

### Step 1.3: Deploy Bicep Infrastructure

```bash
# Navigate to deployment directory
cd deployment/bicep/

# Validate Bicep template (dry-run)
az deployment group validate \
  --resource-group rg-brookside-repo-analyzer \
  --template-file main.bicep \
  --parameters environment=prod
```

**Expected Output:**
```json
{
  "properties": {
    "provisioningState": "Succeeded",
    "validatedResources": [
      {
        "type": "Microsoft.Storage/storageAccounts",
        "name": "strepoanalyzerprod"
      },
      {
        "type": "Microsoft.Web/sites",
        "name": "func-repo-analyzer-prod"
      },
      ...
    ]
  }
}
```

**Validation:**
- [ ] No validation errors
- [ ] All expected resources listed
- [ ] Resource names follow naming convention

```bash
# Deploy infrastructure
az deployment group create \
  --resource-group rg-brookside-repo-analyzer \
  --template-file main.bicep \
  --parameters environment=prod \
  --query "properties.outputs"
```

**Expected Deployment Time:** 3-5 minutes

**Expected Output:**
```json
{
  "appInsightsConnectionString": {
    "type": "String",
    "value": "InstrumentationKey=..."
  },
  "functionAppName": {
    "type": "String",
    "value": "func-repo-analyzer-prod"
  },
  "functionAppUrl": {
    "type": "String",
    "value": "https://func-repo-analyzer-prod.azurewebsites.net"
  },
  "keyVaultUri": {
    "type": "String",
    "value": "https://kv-brookside-secrets.vault.azure.net/"
  }
}
```

**Validation:**
- [ ] Deployment succeeded without errors
- [ ] Function App URL is accessible (returns default Azure Functions page)
- [ ] All output values are present

---

### Step 1.4: Verify Managed Identity RBAC

```bash
# Get Function App principal ID
PRINCIPAL_ID=$(az functionapp identity show \
  --name func-repo-analyzer-prod \
  --resource-group rg-brookside-repo-analyzer \
  --query principalId \
  --output tsv)

echo "Function App Principal ID: $PRINCIPAL_ID"

# Verify Key Vault role assignment
az role assignment list \
  --assignee $PRINCIPAL_ID \
  --scope /subscriptions/cfacbbe8-a2a3-445f-a188-68b3b35f0c84/resourceGroups/rg-brookside-repo-analyzer/providers/Microsoft.KeyVault/vaults/kv-brookside-secrets \
  --query "[].{Role:roleDefinitionName,Scope:scope}"
```

**Expected Output:**
```json
[
  {
    "Role": "Key Vault Secrets User",
    "Scope": ".../kv-brookside-secrets"
  }
]
```

**Validation:**
- [ ] Principal ID is a valid GUID
- [ ] "Key Vault Secrets User" role is assigned
- [ ] Scope matches Key Vault resource

---

## Phase 2: Function Code Deployment (10-15 minutes)

### Step 2.1: Build Python Package

```bash
# Navigate to repository root
cd ../../

# Install dependencies
poetry install --no-dev

# Build distribution package
poetry build
```

**Expected Output:**
```
Building brookside-repo-analyzer (1.0.0)
  - Building sdist
  - Built brookside-repo-analyzer-1.0.0.tar.gz
  - Building wheel
  - Built brookside_repo_analyzer-1.0.0-py3-none-any.whl
```

**Validation:**
- [ ] Build completes without errors
- [ ] `dist/` directory created with `.whl` and `.tar.gz` files

---

### Step 2.2: Prepare Function App

```bash
# Generate requirements.txt from Poetry
poetry export -f requirements.txt --output requirements.txt --without-hashes
```

**Expected Output:**
```
azure-functions==1.18.0
azure-identity==1.15.0
azure-keyvault-secrets==4.7.0
...
```

**Validation:**
- [ ] `requirements.txt` created with all dependencies
- [ ] No dev dependencies included

---

### Step 2.3: Deploy to Azure Functions

```bash
# Publish function app
func azure functionapp publish func-repo-analyzer-prod
```

**Expected Deployment Time:** 5-8 minutes

**Expected Output:**
```
Getting site publishing info...
Creating archive for current directory...
Uploading 12.34 MB [################################] 100%
Upload completed successfully.
Deployment completed successfully.
Syncing triggers...
Functions in func-repo-analyzer-prod:
    repository_scanner_weekly - [timerTrigger]
    analyze_repository_http - [httpTrigger]

Function App URL: https://func-repo-analyzer-prod.azurewebsites.net
```

**Validation:**
- [ ] Deployment succeeded
- [ ] All functions listed in output
- [ ] Function App URL is accessible

---

### Step 2.4: Configure Application Settings

```bash
# Verify environment variables
az functionapp config appsettings list \
  --name func-repo-analyzer-prod \
  --resource-group rg-brookside-repo-analyzer \
  --query "[?name=='AZURE_KEYVAULT_URI' || name=='GITHUB_ORG' || name=='NOTION_WORKSPACE_ID'].{Name:name,Value:value}"
```

**Expected Output:**
```json
[
  {
    "Name": "AZURE_KEYVAULT_URI",
    "Value": "https://kv-brookside-secrets.vault.azure.net/"
  },
  {
    "Name": "GITHUB_ORG",
    "Value": "brookside-bi"
  },
  {
    "Name": "NOTION_WORKSPACE_ID",
    "Value": "81686779-099a-8195-b49e-00037e25c23e"
  }
]
```

**Validation:**
- [ ] All required environment variables are present
- [ ] Values match expected configuration

---

## Phase 3: Integration Testing (10-15 minutes)

### Step 3.1: Test Key Vault Access

```bash
# Test Function App can retrieve secrets
az functionapp deployment source config-zip \
  --name func-repo-analyzer-prod \
  --resource-group rg-brookside-repo-analyzer \
  --src deployment/test-keyvault.zip
```

**Create test function:**
```python
# deployment/test-keyvault/function_app.py
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
import os

app = func.FunctionApp()

@app.route(route="test-keyvault", auth_level=func.AuthLevel.ANONYMOUS)
def test_keyvault(req: func.HttpRequest) -> func.HttpResponse:
    try:
        kv_uri = os.environ['AZURE_KEYVAULT_URI']
        credential = DefaultAzureCredential()
        client = SecretClient(vault_url=kv_uri, credential=credential)

        # Test retrieval
        github_token = client.get_secret("github-personal-access-token")

        return func.HttpResponse(
            "Key Vault access successful",
            status_code=200
        )
    except Exception as e:
        return func.HttpResponse(
            f"Key Vault access failed: {str(e)}",
            status_code=500
        )
```

```bash
# Invoke test endpoint
curl https://func-repo-analyzer-prod.azurewebsites.net/api/test-keyvault
```

**Expected Output:**
```
Key Vault access successful
```

**Validation:**
- [ ] HTTP 200 response
- [ ] No authentication errors
- [ ] Secrets retrieved successfully

---

### Step 3.2: Test GitHub MCP Integration

```bash
# Manual test: Analyze single repository
curl -X POST https://func-repo-analyzer-prod.azurewebsites.net/api/analyze/repo-analyzer \
  -H "Content-Type: application/json" \
  -d '{"deep": false, "sync": false}'
```

**Expected Output:**
```json
{
  "repository": "repo-analyzer",
  "viability_score": 85,
  "claude_maturity": "EXPERT",
  "monthly_cost": 7.0,
  "reusability": "Highly Reusable"
}
```

**Validation:**
- [ ] HTTP 200 response
- [ ] Valid JSON response
- [ ] All expected fields present
- [ ] Viability score is 0-100

---

### Step 3.3: Test Notion MCP Integration

```bash
# Test with sync enabled
curl -X POST https://func-repo-analyzer-prod.azurewebsites.net/api/analyze/repo-analyzer \
  -H "Content-Type: application/json" \
  -d '{"deep": true, "sync": true}'
```

**Expected Output:**
```json
{
  "repository": "repo-analyzer",
  "viability_score": 85,
  "claude_maturity": "EXPERT",
  "monthly_cost": 7.0,
  "reusability": "Highly Reusable",
  "notion_sync": {
    "build_entry_id": "a1cd1528-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "synced_at": "2025-10-21T12:34:56Z"
  }
}
```

**Validation:**
- [ ] HTTP 200 response
- [ ] `notion_sync` object present
- [ ] Valid Notion page ID returned
- [ ] Check Notion Example Builds database for new entry

**Manual Validation in Notion:**
1. Open Example Builds database
2. Search for "repo-analyzer"
3. Verify entry exists with:
   - Viability score = 85
   - Claude Maturity = EXPERT
   - GitHub Repository URL populated
   - Total Cost rollup displayed

---

### Step 3.4: Test Weekly Timer Trigger

```bash
# Manually trigger timer function (bypasses schedule)
az functionapp function start \
  --name func-repo-analyzer-prod \
  --resource-group rg-brookside-repo-analyzer \
  --function-name repository_scanner_weekly
```

**Expected Execution Time:** 3-5 minutes

**Monitor Execution:**
```bash
# Stream logs in real-time
az functionapp logs tail \
  --name func-repo-analyzer-prod \
  --resource-group rg-brookside-repo-analyzer
```

**Expected Log Output:**
```
[2025-10-21T12:30:00Z] Executing 'Functions.repository_scanner_weekly'
[2025-10-21T12:30:05Z] Weekly scan triggered at 2025-10-21 12:30:00
[2025-10-21T12:30:10Z] Scanning organization: brookside-bi
[2025-10-21T12:32:45Z] Found 52 repositories
[2025-10-21T12:34:30Z] Synced 52 entries to Notion
[2025-10-21T12:34:35Z] Scan complete: 52 repositories analyzed
[2025-10-21T12:34:35Z] Executed 'Functions.repository_scanner_weekly' (Succeeded, Duration=274s)
```

**Validation:**
- [ ] Function executes without errors
- [ ] All 52 repositories scanned
- [ ] Notion sync completes successfully
- [ ] Execution duration <10 minutes (timeout threshold)

---

## Phase 4: Monitoring & Alerts Setup (5-10 minutes)

### Step 4.1: Configure Application Insights

```bash
# Get Application Insights instrumentation key
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app appi-repo-analyzer-prod \
  --resource-group rg-brookside-repo-analyzer \
  --query instrumentationKey \
  --output tsv)

echo "Application Insights Key: $INSTRUMENTATION_KEY"
```

**Validation:**
- [ ] Instrumentation key is a valid GUID
- [ ] Application Insights workspace is active

---

### Step 4.2: Verify Metric Alerts

```bash
# List configured alerts
az monitor metrics alert list \
  --resource-group rg-brookside-repo-analyzer \
  --query "[].{Name:name,Enabled:enabled,Severity:severity}"
```

**Expected Output:**
```json
[
  {
    "Name": "alert-func-repo-analyzer-prod-failures",
    "Enabled": true,
    "Severity": 2
  },
  {
    "Name": "alert-func-repo-analyzer-prod-long-execution",
    "Enabled": true,
    "Severity": 3
  }
]
```

**Validation:**
- [ ] Function failure alert is enabled
- [ ] Long execution alert is enabled
- [ ] Alert recipients configured (via Action Group)

---

### Step 4.3: Create Monitoring Dashboard

```bash
# Create Application Insights dashboard
az portal dashboard create \
  --resource-group rg-brookside-repo-analyzer \
  --name dashboard-repo-analyzer \
  --input-path deployment/dashboard.json
```

**Dashboard Widgets:**
- Function execution count (daily)
- Average execution duration
- Error rate
- Notion sync success rate
- Repository viability distribution

**Validation:**
- [ ] Dashboard created successfully
- [ ] All widgets display data
- [ ] Accessible via Azure Portal

---

## Phase 5: Operational Handoff (5 minutes)

### Step 5.1: Document Production Configuration

Create runbook entry:

```markdown
# Repository Analyzer - Production Runbook

**Environment:** Production
**Azure Subscription:** cfacbbe8-a2a3-445f-a188-68b3b35f0c84
**Resource Group:** rg-brookside-repo-analyzer

## Resources

| Resource | Name | Purpose |
|----------|------|---------|
| Function App | func-repo-analyzer-prod | Weekly scans |
| Storage | strepoanalyzerprod | Results cache |
| App Insights | appi-repo-analyzer-prod | Monitoring |
| Key Vault | kv-brookside-secrets | Secrets |

## Schedule

**Execution:** Every Sunday at 00:00 UTC
**Duration:** 3-5 minutes (52 repositories)
**Timeout:** 10 minutes

## Monitoring

**Dashboard:** [Link to Azure Portal]
**Alerts:** consultations@brooksidebi.com
**Logs:** Application Insights

## Support

**Primary:** Alec Fielding
**Secondary:** Markus Ahling
**Escalation:** consultations@brooksidebi.com
```

---

### Step 5.2: Validate Weekly Schedule

```bash
# Check timer trigger configuration
az functionapp function show \
  --name func-repo-analyzer-prod \
  --resource-group rg-brookside-repo-analyzer \
  --function-name repository_scanner_weekly \
  --query "config.bindings[?type=='timerTrigger'].schedule"
```

**Expected Output:**
```json
[
  "0 0 * * 0"
]
```

**Validation:**
- [ ] Cron expression is correct (Sunday midnight UTC)
- [ ] Next scheduled run is upcoming Sunday

---

### Step 5.3: Create Knowledge Vault Entry

Document in Notion Knowledge Vault:

**Title:** 📚 Repository Analyzer - Deployment & Operations Guide

**Content:**
- Architecture overview
- Deployment steps
- Monitoring procedures
- Troubleshooting guide
- Cost tracking
- Contact information

**Validation:**
- [ ] Knowledge Vault entry created
- [ ] Linked to Example Builds entry for analyzer
- [ ] Tagged as "Technical Doc" and "Reference"

---

## Success Criteria Checklist

### Infrastructure

- [ ] Resource group created with correct tags
- [ ] All Azure resources provisioned successfully
- [ ] Managed Identity configured with Key Vault access
- [ ] Application Insights enabled and collecting data
- [ ] Budget alerts configured ($10/month threshold)

### Functionality

- [ ] Function App deploys without errors
- [ ] Timer trigger configured (Sunday 00:00 UTC)
- [ ] HTTP trigger accessible and functional
- [ ] Key Vault secrets retrievable via Managed Identity
- [ ] GitHub MCP integration working
- [ ] Notion MCP integration working

### Validation

- [ ] Single repository analysis successful
- [ ] Full organization scan completes in <10 minutes
- [ ] Notion database sync creates/updates entries correctly
- [ ] Software Tracker relations established
- [ ] Cost rollups display in Notion
- [ ] Pattern extraction identifies 5+ patterns

### Operations

- [ ] Monitoring dashboard accessible
- [ ] Metric alerts firing correctly
- [ ] Logs streaming to Application Insights
- [ ] Runbook documented
- [ ] Knowledge Vault entry created
- [ ] Team trained on monitoring procedures

---

## Rollback Procedure

If deployment fails or critical issues discovered:

```bash
# Delete resource group (removes all resources)
az group delete \
  --name rg-brookside-repo-analyzer \
  --yes --no-wait

# Verify deletion
az group show --name rg-brookside-repo-analyzer
# Expected: ResourceGroupNotFound error
```

**Note:** This is a clean deployment. No existing data will be lost as Notion databases are external.

---

## Post-Deployment Monitoring (First 7 Days)

### Daily Checks

- [ ] **Day 1:** Verify first scheduled scan executed successfully
- [ ] **Day 2:** Check Application Insights for errors
- [ ] **Day 3:** Review Notion sync success rate
- [ ] **Day 4:** Validate cost tracking accuracy
- [ ] **Day 5:** Monitor execution duration trends
- [ ] **Day 6:** Review pattern extraction results
- [ ] **Day 7:** Generate weekly summary report

### Weekly Review

**Metrics to Track:**
- Function execution success rate (target: 100%)
- Average execution duration (target: <5 minutes)
- Notion sync success rate (target: >95%)
- Actual Azure costs vs. budget
- Number of repositories analyzed
- Pattern reusability scores

**Action Items:**
- Adjust alert thresholds if needed
- Optimize execution time if approaching timeout
- Review and categorize any errors
- Update documentation based on learnings

---

## Troubleshooting Guide

### Issue: Function execution fails with Key Vault access error

**Symptoms:**
```
Unable to retrieve secret: Access denied
```

**Solution:**
```bash
# Verify Managed Identity has correct role
az role assignment list \
  --assignee $(az functionapp identity show \
    --name func-repo-analyzer-prod \
    --resource-group rg-brookside-repo-analyzer \
    --query principalId -o tsv) \
  --scope /subscriptions/.../kv-brookside-secrets

# If missing, re-run Bicep deployment to recreate role assignment
az deployment group create \
  --resource-group rg-brookside-repo-analyzer \
  --template-file deployment/bicep/main.bicep \
  --parameters environment=prod
```

---

### Issue: GitHub API rate limiting

**Symptoms:**
```
API rate limit exceeded (403)
```

**Solution:**
```bash
# Check GitHub PAT has correct scopes
# Verify rate limit status
curl -H "Authorization: token $(az keyvault secret show \
  --vault-name kv-brookside-secrets \
  --name github-personal-access-token \
  --query value -o tsv)" \
  https://api.github.com/rate_limit

# If consistently hitting limits, consider:
# 1. Increase scan interval (bi-weekly instead of weekly)
# 2. Implement caching for repository metadata
# 3. Use GitHub GraphQL API for fewer requests
```

---

### Issue: Notion sync creates duplicate entries

**Symptoms:**
```
Multiple entries for same repository in Example Builds
```

**Solution:**
```bash
# Check search-before-create logic
# Verify GitHub Repository URL property is unique
# Manual cleanup required in Notion database

# Prevention: Ensure unique constraint on GitHub Repository property
```

---

## Conclusion

Deployment complete. The Repository Analyzer is now operational and will execute weekly scans every Sunday at midnight UTC.

**Next Steps:**
1. Monitor first scheduled execution
2. Review Notion databases for accuracy
3. Validate cost tracking
4. Archive deployment notes to Knowledge Vault

**Support:**
- Email: consultations@brooksidebi.com
- Phone: +1 209 487 2047
- Documentation: [Link to Knowledge Vault]

---

**Document Version:** 1.0.0
**Deployment Status:** ✅ Production Ready
**Last Validated:** 2025-10-21

🤖 Generated with Claude Code - Deployment guide designed for autonomous execution

**Deployed by:** Alec Fielding (Lead Builder) | **Reviewed by:** Markus Ahling (Operations)
