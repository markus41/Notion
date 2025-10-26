# Azure MCP Server - API Reference

**Author**: Claude Code Agent (Markdown Expert)
**Date**: October 21, 2025
**Version**: 1.0.0
**Status**: Production Ready

## Overview

Establish comprehensive Azure cloud operations through MCP server integration to streamline resource management, deployment workflows, and cost optimization. This solution is designed for organizations scaling cloud infrastructure across teams who require programmatic access to Azure services, Key Vault secrets, and operational monitoring.

**Best for**: Development and operations teams managing Azure deployments, Example Build infrastructure, and centralized secret management through Key Vault.

## Table of Contents

- [Authentication Setup](#authentication-setup)
- [Subscription Management](#subscription-management)
- [Resource Group Operations](#resource-group-operations)
- [Key Vault Operations](#key-vault-operations)
- [Resource Management](#resource-management)
- [Cost Analysis](#cost-analysis)
- [Monitoring & Health](#monitoring--health)
- [Common Workflows](#common-workflows)
- [Error Handling](#error-handling)
- [Troubleshooting](#troubleshooting)

## Authentication Setup

### Prerequisites

- Azure CLI 2.50.0 or higher installed
- Access to Azure subscription
- Appropriate RBAC permissions (Contributor or Owner)

### Azure CLI Authentication

**Interactive Login** (Recommended for development):
```bash
# Login with browser authentication
az login

# Verify authentication
az account show

# Expected output:
# {
#   "id": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84",
#   "name": "Azure subscription 1",
#   "tenantId": "2930489e-9d8a-456b-9de9-e4787faeab9c",
#   "state": "Enabled",
#   "isDefault": true
# }
```

**Set Active Subscription** (if multiple subscriptions):
```bash
# Set by subscription ID
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"

# OR set by name
az account set --subscription "Azure subscription 1"

# Verify active subscription
az account show --query "{Name:name, SubscriptionId:id, TenantId:tenantId}"
```

### MCP Server Configuration

The Azure MCP server is configured in `.claude.json`:

```json
{
  "mcpServers": {
    "azure": {
      "command": "npx",
      "args": ["-y", "@azure/mcp@latest", "server", "start"]
    }
  }
}
```

**Authentication Method**: Azure MCP uses Azure CLI credentials automatically. No additional environment variables required.

### Verify MCP Connection

```bash
# Check MCP server status
claude mcp list

# Expected output:
# ✓ azure: Connected
#   Subscription: Azure subscription 1 (cfacbbe8-a2a3-445f-a188-68b3b35f0c84)
#   Tenant: Personal Portfolio (2930489e-9d8a-456b-9de9-e4787faeab9c)
#   Authentication: Azure CLI
```

### Test Azure MCP Server

```powershell
# Comprehensive MCP server test
.\scripts\Test-AzureMCP.ps1

# Expected output:
# ✓ Azure CLI authenticated
# ✓ Subscription access confirmed
# ✓ Key Vault access verified
# ✓ MCP server responds successfully
```

## Subscription Management

### List Subscriptions

**Tool Name**: `azure__subscription_list`

**Parameters**: None

**Example**:
```typescript
{
  // No parameters required
}
```

**Response**:
```json
{
  "subscriptions": [
    {
      "subscriptionId": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84",
      "displayName": "Azure subscription 1",
      "state": "Enabled",
      "tenantId": "2930489e-9d8a-456b-9de9-e4787faeab9c",
      "isDefault": true
    }
  ]
}
```

**Use Cases**:
- Verify subscription access before operations
- List all subscriptions for multi-subscription management
- Confirm active subscription context

## Resource Group Operations

### List Resource Groups

**Tool Name**: `azure__group_list`

**Parameters**:
- `subscription` (string, optional): Subscription ID or name (defaults to active subscription)
- `tenant` (string, optional): Tenant ID or name

**Example: List All Resource Groups**
```typescript
{
  "subscription": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
}
```

**Response**:
```json
{
  "resourceGroups": [
    {
      "id": "/subscriptions/.../resourceGroups/rg-brookside-production",
      "name": "rg-brookside-production",
      "location": "eastus",
      "tags": {
        "Environment": "Production",
        "ManagedBy": "Innovation Nexus"
      },
      "provisioningState": "Succeeded"
    },
    {
      "id": "/subscriptions/.../resourceGroups/rg-brookside-development",
      "name": "rg-brookside-development",
      "location": "eastus",
      "tags": {
        "Environment": "Development"
      },
      "provisioningState": "Succeeded"
    }
  ]
}
```

**Use Cases**:
- Discover existing resource groups before deployment
- Verify resource group naming conventions
- Audit resource organization

## Key Vault Operations

### List Key Vaults

**Tool Name**: `azure__keyvault` (with list command)

**Parameters**:
- `intent` (string, required): Operation intent (e.g., "list key vaults")
- `subscription` (string, optional): Subscription ID

**Example: List Key Vaults**
```typescript
{
  "intent": "list key vaults in subscription",
  "subscription": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
}
```

**Response**:
```json
{
  "keyVaults": [
    {
      "id": "/subscriptions/.../vaults/kv-brookside-secrets",
      "name": "kv-brookside-secrets",
      "location": "eastus",
      "vaultUri": "https://kv-brookside-secrets.vault.azure.net/",
      "tenantId": "2930489e-9d8a-456b-9de9-e4787faeab9c",
      "sku": "standard",
      "enabledForDeployment": true,
      "enabledForTemplateDeployment": true,
      "enableRbacAuthorization": true
    }
  ]
}
```

### Retrieve Secret

**PowerShell Method** (Recommended):
```powershell
# Retrieve single secret
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token"

# Custom vault
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "notion-api-key" -VaultName "kv-brookside-secrets"
```

**Azure CLI Method**:
```bash
# Get secret value
az keyvault secret show \
  --vault-name kv-brookside-secrets \
  --name github-personal-access-token \
  --query value \
  --output tsv

# List all secrets
az keyvault secret list \
  --vault-name kv-brookside-secrets \
  --query "[].{Name:name, Enabled:attributes.enabled}" \
  --output table
```

### Set Secret

```bash
# Create or update secret
az keyvault secret set \
  --vault-name kv-brookside-secrets \
  --name "new-api-key" \
  --value "secret-value-here"

# Set secret with expiration
az keyvault secret set \
  --vault-name kv-brookside-secrets \
  --name "temp-api-key" \
  --value "secret-value" \
  --expires "2026-12-31T23:59:59Z"
```

**Security Best Practice**: Always reference Key Vault in code, never hardcode secrets:

```typescript
// ✓ Correct: Reference Key Vault
const apiKey = await getKeyVaultSecret('kv-brookside-secrets', 'api-key-name');

// ✗ Incorrect: Hardcoded secret
const apiKey = 'abc123def456';
```

## Resource Management

### List Resources

**Tool Name**: Azure MCP intent-based operations

**Example: List App Services**
```typescript
{
  "intent": "list app services in resource group rg-brookside-production",
  "subscription": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
}
```

**Example: List Storage Accounts**
```typescript
{
  "intent": "list storage accounts in subscription",
  "subscription": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
}
```

**Example: List Cosmos DB Accounts**
```typescript
{
  "intent": "list cosmos db accounts",
  "subscription": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
}
```

### Resource Health Check

**Tool Name**: `azure__resourcehealth`

**Parameters**:
- `intent` (string, required): Health check operation
- `parameters` (object, optional): Resource-specific parameters

**Example: Check Resource Health**
```typescript
{
  "intent": "check health of app service cost-dashboard-api",
  "parameters": {
    "resource-group": "rg-brookside-production",
    "subscription": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
  }
}
```

**Response**:
```json
{
  "availabilityState": "Available",
  "summary": "Resource is running normally",
  "detailedStatus": "All health checks passed",
  "occuredTime": "2025-10-21T12:00:00Z"
}
```

## Cost Analysis

### Analyze Costs

**Tool Name**: `azure__quota` (with cost intent)

**Parameters**:
- `intent` (string, required): Cost analysis operation
- `parameters` (object, optional): Scope and filters

**Example: Monthly Cost Summary**
```typescript
{
  "intent": "analyze monthly costs for subscription",
  "parameters": {
    "subscription": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84",
    "time-frame": "MonthToDate"
  }
}
```

**Example: Resource Group Costs**
```typescript
{
  "intent": "calculate costs for resource group rg-brookside-production",
  "parameters": {
    "subscription": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84",
    "resource-group": "rg-brookside-production",
    "granularity": "Daily"
  }
}
```

**Response**:
```json
{
  "costs": [
    {
      "date": "2025-10-21",
      "cost": 125.43,
      "currency": "USD"
    }
  ],
  "total": 3875.20,
  "forecast": 4200.00,
  "breakdown": {
    "Compute": 2100.00,
    "Storage": 850.00,
    "Networking": 450.00,
    "Database": 475.20
  }
}
```

### Check Resource Quota

**Tool Name**: `azure__quota`

**Parameters**:
- `intent` (string, required): Quota check operation
- `parameters` (object): Resource type and location

**Example: Check VM Quota**
```typescript
{
  "intent": "check virtual machine quota in eastus",
  "parameters": {
    "subscription": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84",
    "location": "eastus",
    "resource-type": "Microsoft.Compute/virtualMachines"
  }
}
```

**Response**:
```json
{
  "quota": {
    "limit": 100,
    "current": 23,
    "available": 77,
    "unit": "Count"
  }
}
```

## Monitoring & Health

### Query Application Insights

**Tool Name**: `azure__monitor`

**Parameters**:
- `intent` (string, required): Monitoring query intent
- `parameters` (object): Query parameters

**Example: Query Application Logs**
```typescript
{
  "intent": "query application insights logs for cost-dashboard",
  "parameters": {
    "resource-group": "rg-brookside-production",
    "app-insights-name": "ai-cost-dashboard",
    "query": "traces | where severityLevel >= 3 | take 50",
    "timespan": "PT1H"
  }
}
```

**Example: Get Performance Metrics**
```typescript
{
  "intent": "get performance metrics for app service",
  "parameters": {
    "resource-id": "/subscriptions/.../providers/Microsoft.Web/sites/cost-dashboard-api",
    "metric-names": ["CpuPercentage", "MemoryPercentage", "HttpResponseTime"],
    "timespan": "PT24H",
    "interval": "PT1H"
  }
}
```

### Resource Diagnostics

**Tool Name**: `azure__applens`

**Parameters**:
- `intent` (string, required): Diagnostic operation
- `parameters` (object): Resource details

**Example: Diagnose App Service Issues**
```typescript
{
  "intent": "diagnose issues with app service cost-dashboard-api",
  "parameters": {
    "resource-group": "rg-brookside-production",
    "resource-name": "cost-dashboard-api",
    "subscription": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
  }
}
```

**Use Cases**:
- Troubleshoot performance degradation
- Identify resource health issues
- Root cause analysis for failures
- Proactive issue detection

## Common Workflows

### Workflow 1: Deploy Example Build to Azure

```typescript
// Step 1: Verify subscription access
{
  // List subscriptions
}

// Step 2: Check resource group exists
{
  "subscription": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
}

// Step 3: Check quota availability
{
  "intent": "check app service quota in eastus",
  "parameters": {
    "subscription": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84",
    "location": "eastus"
  }
}

// Step 4: Deploy app service (via Azure CLI or ARM template)
// Step 5: Configure Key Vault references
// Step 6: Enable Application Insights monitoring
// Step 7: Update Notion Build entry with Azure URLs
```

### Workflow 2: Secret Management Setup

```powershell
# Step 1: Authenticate to Azure
az login

# Step 2: Set active subscription
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"

# Step 3: Verify Key Vault access
az keyvault show --name kv-brookside-secrets

# Step 4: Store new secret
az keyvault secret set \
  --vault-name kv-brookside-secrets \
  --name "new-service-api-key" \
  --value "secure-api-key-value"

# Step 5: Configure MCP environment
.\scripts\Set-MCPEnvironment.ps1

# Step 6: Verify secret retrieval
$secret = .\scripts\Get-KeyVaultSecret.ps1 -SecretName "new-service-api-key"
if ($secret) { Write-Host "✓ Secret configured successfully" }
```

### Workflow 3: Cost Optimization Analysis

```typescript
// Step 1: Get monthly cost summary
{
  "intent": "analyze monthly costs for subscription",
  "parameters": {
    "subscription": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84",
    "time-frame": "MonthToDate"
  }
}

// Step 2: Break down by resource group
{
  "intent": "calculate costs by resource group",
  "parameters": {
    "subscription": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
  }
}

// Step 3: Identify underutilized resources
{
  "intent": "find underutilized resources",
  "parameters": {
    "subscription": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84",
    "threshold": "10"  // Less than 10% utilization
  }
}

// Step 4: Recommend cost optimizations
// Step 5: Update Software & Cost Tracker in Notion
// Step 6: Track savings over time
```

### Workflow 4: Health Monitoring & Alerting

```typescript
// Step 1: Check resource health
{
  "intent": "check health of all resources in rg-brookside-production",
  "parameters": {
    "resource-group": "rg-brookside-production",
    "subscription": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
  }
}

// Step 2: Query Application Insights for errors
{
  "intent": "query application insights for errors",
  "parameters": {
    "app-insights-name": "ai-cost-dashboard",
    "query": "exceptions | where timestamp > ago(1h) | summarize count() by type",
    "timespan": "PT1H"
  }
}

// Step 3: Diagnose specific issues (if health degraded)
{
  "intent": "diagnose issues with app service cost-dashboard-api",
  "parameters": {
    "resource-name": "cost-dashboard-api",
    "resource-group": "rg-brookside-production"
  }
}

// Step 4: Generate incident report
// Step 5: Update runbook with resolution steps
```

## Error Handling

### Common Errors

**1. Authentication Failure**
```
Error: Please run 'az login' to setup account
```

**Solution**:
```bash
# Login to Azure
az login

# Verify authentication
az account show

# Restart Claude Code to refresh MCP connection
```

**2. Insufficient Permissions**
```
Error: The client does not have authorization to perform action
```

**Solution**:
- Check RBAC role assignments: `az role assignment list --assignee <user-principal-id>`
- Request Contributor or Owner role for subscription/resource group
- Verify subscription access: `az account list`

**3. Resource Not Found**
```
Error: The Resource 'Microsoft.KeyVault/vaults/kv-name' not found
```

**Solution**:
- Verify resource name is correct
- Check resource is in correct subscription
- Ensure resource hasn't been deleted
- List all resources: `az resource list`

**4. Quota Exceeded**
```
Error: Operation could not be completed as it results in exceeding quota limit
```

**Solution**:
```typescript
// Check current quota
{
  "intent": "check quota for resource type",
  "parameters": {
    "subscription": "subscription-id",
    "location": "eastus",
    "resource-type": "Microsoft.Compute/virtualMachines"
  }
}

// Request quota increase through Azure portal
// Or deploy to different region with available quota
```

### Error Recovery Patterns

**Circuit Breaker for Azure Operations**:
```typescript
class AzureCircuitBreaker {
  private failureCount = 0;
  private readonly threshold = 5;
  private state: 'CLOSED' | 'OPEN' | 'HALF_OPEN' = 'CLOSED';

  async execute<T>(operation: () => Promise<T>): Promise<T> {
    if (this.state === 'OPEN') {
      throw new Error('Circuit breaker is OPEN - Azure operations paused');
    }

    try {
      const result = await operation();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess() {
    this.failureCount = 0;
    if (this.state === 'HALF_OPEN') {
      this.state = 'CLOSED';
    }
  }

  private onFailure() {
    this.failureCount++;
    if (this.failureCount >= this.threshold) {
      this.state = 'OPEN';
      setTimeout(() => { this.state = 'HALF_OPEN'; }, 60000); // 1 minute
    }
  }
}
```

## Troubleshooting

### Issue: MCP Server Not Responding

**Symptoms**:
- Azure MCP commands timeout
- `claude mcp list` shows azure as disconnected

**Diagnostics**:
```bash
# Check Azure CLI works
az account show

# Test subscription access
az group list --output table

# Verify MCP server process
npx @azure/mcp@latest server start
```

**Solutions**:
1. Restart Claude Code
2. Update Azure MCP: `npm install -g @azure/mcp@latest`
3. Re-authenticate: `az login`
4. Check network connectivity to Azure

### Issue: Key Vault Access Denied

**Symptoms**:
- Cannot retrieve secrets from Key Vault
- "403 Forbidden" errors

**Diagnostics**:
```bash
# Check Key Vault access policies
az keyvault show --name kv-brookside-secrets --query properties.accessPolicies

# List your permissions
az keyvault secret list --vault-name kv-brookside-secrets
```

**Solutions**:
1. Enable RBAC authorization on Key Vault
2. Assign "Key Vault Secrets User" role:
   ```bash
   az role assignment create \
     --role "Key Vault Secrets User" \
     --assignee <user-principal-id> \
     --scope /subscriptions/.../vaults/kv-brookside-secrets
   ```
3. Wait 5-10 minutes for permissions to propagate

### Issue: Slow Query Performance

**Symptoms**:
- Cost analysis queries take > 30 seconds
- Monitoring queries timeout

**Solutions**:
- Reduce query timespan (use PT1H instead of P7D)
- Add specific filters to limit result set
- Use summary/aggregation instead of raw data
- Query during off-peak hours

### Issue: Deployment Failures

**Symptoms**:
- ARM template deployment fails
- Resource provisioning errors

**Diagnostics**:
```bash
# Get deployment status
az deployment group list \
  --resource-group rg-brookside-production \
  --query "[0].{Name:name, State:properties.provisioningState, Error:properties.error}" \
  --output table

# View deployment logs
az deployment operation group list \
  --resource-group rg-brookside-production \
  --name deployment-name
```

**Solutions**:
1. Check quota availability before deployment
2. Verify naming conventions (no special characters)
3. Ensure location supports requested SKU/size
4. Review detailed error message in deployment operation

## Related Documentation

- [Azure Key Vault Setup](../../CLAUDE.md#azure-key-vault---centralized-secret-management) - Secret management configuration
- [PowerShell Scripts](../../scripts/) - Automated secret retrieval scripts
- [Integration Specialist Agent](../../.claude/agents/integration-specialist.md) - Azure deployment workflows
- [Circuit Breaker Pattern](../../.claude/docs/patterns/circuit-breaker.md) - Resilient Azure operations

## Support

For additional assistance:
- **Azure CLI Issues**: Update to latest version or check [Azure CLI Documentation](https://docs.microsoft.com/cli/azure/)
- **Key Vault Problems**: Engage @integration-specialist agent
- **Cost Optimization**: Use @cost-analyst agent with Azure cost data

---

**Best for**: Teams managing Azure infrastructure at scale with secure secret management, comprehensive monitoring, and cost-transparent operations that support sustainable cloud practices.
