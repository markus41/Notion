# Azure Infrastructure

**Purpose**: Establish centralized Azure resource configuration and security best practices for the Innovation Nexus environment.

**Best for**: Agents performing Azure operations, deployments, or credential management.

---

## Active Configuration

### Subscription & Tenant

```bash
# Azure Subscription
Subscription ID: cfacbbe8-a2a3-445f-a188-68b3b35f0c84
Subscription Name: Brookside BI Production
Tenant ID: 2930489e-9d8a-456b-9de9-e4787faeab9c
Tenant Name: Brookside BI
```

**Verification**:
```powershell
az account show
# Should display above subscription as active
```

---

## Azure Key Vault (Centralized Secrets)

### Configuration

```bash
Vault Name: kv-brookside-secrets
Vault URI: https://kv-brookside-secrets.vault.azure.net/
Resource Group: rg-brookside-core
Location: westus2
SKU: Standard
```

### Stored Secrets

| Secret Name | Purpose | Used By |
|-------------|---------|---------|
| `github-personal-access-token` | GitHub repository operations | GitHub MCP, CI/CD pipelines |
| `notion-api-key` | Notion database operations | Notion MCP |
| `azure-openai-api-key` | Azure OpenAI service access | AI/ML builds, research agents |
| `azure-openai-endpoint` | Azure OpenAI endpoint URL | AI/ML builds, research agents |
| `morningstar-api-key` | Morningstar Financial Data API | @cost-analyst, @research-coordinator, @viability-assessor, @market-researcher |
| `bloomberg-api-username` | Bloomberg Terminal/BLPAPI username | @cost-analyst, @research-coordinator, @viability-assessor, @market-researcher |
| `bloomberg-api-password` | Bloomberg Terminal/BLPAPI password | @cost-analyst, @research-coordinator, @viability-assessor, @market-researcher |
| `cosmosdb-connection-string` | Cosmos DB access (if used) | Database builds |
| `sql-connection-string` | Azure SQL access (if used) | Database builds |
| `storage-connection-string` | Azure Storage access (if used) | File storage builds |

**Access Policy**: Managed via Azure RBAC with principle of least privilege

### Adding Financial API Secrets

**Initial Setup** (One-time configuration for new financial API credentials):

```powershell
# Add Morningstar API Key
az keyvault secret set `
  --vault-name kv-brookside-secrets `
  --name morningstar-api-key `
  --value "<your-morningstar-api-key>"

# Add Bloomberg Terminal Credentials
az keyvault secret set `
  --vault-name kv-brookside-secrets `
  --name bloomberg-api-username `
  --value "<your-bloomberg-username>"

az keyvault secret set `
  --vault-name kv-brookside-secrets `
  --name bloomberg-api-password `
  --value "<your-bloomberg-password>"
```

**Verification**:
```powershell
# List all secrets
az keyvault secret list --vault-name kv-brookside-secrets --query "[].name"

# Verify specific secret exists (without revealing value)
az keyvault secret show --vault-name kv-brookside-secrets --name morningstar-api-key --query "attributes"
```

**Best for**: Initial configuration when onboarding Morningstar and Bloomberg data sources. Requires appropriate Key Vault permissions (Key Vault Secrets Officer or equivalent).

---

## Secret Retrieval

### PowerShell Scripts

#### 1. Get Individual Secret
```powershell
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token"

# Parameters:
#   -SecretName: Name of the secret to retrieve
#   -VaultName: (Optional) Override default vault name
#   -AsPlainText: (Optional) Return plain text instead of SecureString

# Returns: SecureString or plain text value
```

**Example Output**:
```
Retrieving secret 'github-personal-access-token' from Key Vault 'kv-brookside-secrets'...
✓ Secret retrieved successfully
[SecureString object or plain text value]
```

#### 2. Configure All MCP Environment Variables
```powershell
.\scripts\Set-MCPEnvironment.ps1 [-Persistent]

# Parameters:
#   -Persistent: (Optional) Set system-level environment variables (requires admin)

# Actions:
#   1. Authenticates to Azure (if not already authenticated)
#   2. Retrieves all secrets from Key Vault
#   3. Sets environment variables for current session
#   4. Optionally sets persistent environment variables

# Sets:
#   GITHUB_PERSONAL_ACCESS_TOKEN
#   NOTION_API_KEY
#   AZURE_OPENAI_API_KEY
#   AZURE_OPENAI_ENDPOINT
#   MORNINGSTAR_API_KEY
#   BLOOMBERG_API_USERNAME
#   BLOOMBERG_API_PASSWORD
#   (+ any other secrets configured)
```

**Example Output**:
```
Setting MCP environment variables from Key Vault...
✓ Authenticated to Azure
✓ Retrieved 7 secrets from kv-brookside-secrets
✓ Set GITHUB_PERSONAL_ACCESS_TOKEN
✓ Set NOTION_API_KEY
✓ Set AZURE_OPENAI_API_KEY
✓ Set AZURE_OPENAI_ENDPOINT
✓ Set MORNINGSTAR_API_KEY
✓ Set BLOOMBERG_API_USERNAME
✓ Set BLOOMBERG_API_PASSWORD
Environment configured successfully.
```

#### 3. Test Azure MCP Connectivity
```powershell
.\scripts\Test-AzureMCP.ps1

# Actions:
#   1. Verifies Azure CLI authentication
#   2. Tests Key Vault access
#   3. Validates environment variables
#   4. Checks MCP server connectivity

# Returns: Pass/Fail status with diagnostic information
```

**Example Output**:
```
Testing Azure MCP configuration...
✓ Azure CLI authenticated (subscription: cfacbbe8...)
✓ Key Vault accessible (kv-brookside-secrets)
✓ Environment variables configured
✓ MCP servers responsive
All checks passed.
```

---

## Security Best Practices

### ✅ DO: Credential Handling

1. **Use Key Vault for All Secrets**
   ```powershell
   # Retrieve secrets via script
   $pat = .\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token" -AsPlainText

   # Use in operations
   gh auth login --with-token <<< $pat
   ```

2. **Reference Key Vault in Documentation**
   ```markdown
   ## Authentication

   This integration requires a GitHub Personal Access Token.

   **Secret Location**: Azure Key Vault `kv-brookside-secrets` → `github-personal-access-token`

   **Retrieve via**:
   ```powershell
   .\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token"
   ```
   ```

3. **Use Environment Variables from Set-MCPEnvironment.ps1**
   ```typescript
   // ✅ Correct - references environment variable
   const apiKey = process.env.AZURE_OPENAI_API_KEY;

   // ❌ Wrong - hardcoded secret
   const apiKey = "sk-proj-abc123...";
   ```

4. **Use Managed Identity When Possible**
   ```typescript
   // ✅ Preferred - Managed Identity
   import { DefaultAzureCredential } from "@azure/identity";
   const credential = new DefaultAzureCredential();
   const client = new SecretClient(vaultUrl, credential);

   // ⚠️ Fallback - Key Vault secret reference
   const connectionString = process.env.SQL_CONNECTION_STRING;
   ```

### ❌ DON'T: Security Anti-Patterns

1. **Never Display Actual Secret Values**
   ```typescript
   // ❌ Wrong - exposes secret in logs
   console.log(`Using API key: ${apiKey}`);

   // ✅ Correct - masks sensitive data
   console.log(`Using API key: ${apiKey.substring(0, 4)}...`);
   ```

2. **Never Commit Secrets to Git**
   ```bash
   # ❌ Wrong - hardcoded in code
   const connectionString = "Server=tcp:sql.database.windows.net..."

   # ✅ Correct - environment variable
   const connectionString = process.env.SQL_CONNECTION_STRING;
   ```

   **Protection**: Repository hooks detect 15+ secret patterns and block commits

3. **Never Hardcode Credentials in Documentation**
   ```markdown
   <!-- ❌ Wrong -->
   API Key: sk-proj-abc123def456...

   <!-- ✅ Correct -->
   API Key: Stored in Azure Key Vault `kv-brookside-secrets` → `service-api-key`
   ```

4. **Never Use Connection Strings in Code (Prefer Managed Identity)**
   ```csharp
   // ❌ Wrong - connection string in code
   var connectionString = Environment.GetEnvironmentVariable("SQL_CONNECTION_STRING");
   var connection = new SqlConnection(connectionString);

   // ✅ Correct - Managed Identity
   var credential = new DefaultAzureCredential();
   var connection = new SqlConnection($"Server={serverName}.database.windows.net;Database={dbName};Authentication=Active Directory Default;");
   ```

---

## Azure Deployment Best Practices

### Resource Naming Conventions

```bash
# Resource Group
rg-[project]-[environment]
Example: rg-ai-cost-optimizer-dev, rg-ai-cost-optimizer-prod

# App Service / Function App
app-[project]-[environment]
Example: app-ai-cost-optimizer-dev, func-ai-cost-optimizer-prod

# Storage Account (24 chars max, no hyphens)
st[project][environment][random]
Example: stcostoptimizerdevxyz, stcostoptimizerprod123

# Key Vault
kv-[project]-[environment]
Example: kv-ai-cost-optimizer-dev, kv-brookside-secrets

# Application Insights
appi-[project]-[environment]
Example: appi-ai-cost-optimizer-dev

# Cosmos DB / SQL Database
cosmos-[project]-[environment]
sql-[project]-[environment]
Example: cosmos-ai-cost-optimizer-prod
```

### Environment-Based SKU Selection

**Purpose**: Optimize costs by using lower SKUs for dev/test environments

```typescript
// ✅ Correct - environment-based SKU selection
const skuTier = environment === 'prod' ? 'Standard' : 'Basic';
const skuName = environment === 'prod' ? 'S1' : 'B1';

// Cost comparison:
// - Dev (B1): ~$20/month
// - Prod (S1): ~$157/month
// Savings: 87% for non-production environments
```

**SKU Recommendations by Environment**:

| Service | Development | Production |
|---------|-------------|------------|
| App Service | B1 (Basic) | S1 (Standard) or P1V2 (Premium) |
| Function App | Y1 (Consumption) | EP1 (Elastic Premium) |
| SQL Database | Basic (5 DTU) | S2 (50 DTU) or higher |
| Cosmos DB | Serverless | Provisioned (400 RU/s min) |
| Storage | LRS | GRS or ZRS |
| Application Insights | 1 GB/day cap | No cap (pay-as-you-go) |

### Bicep Template Structure

```bicep
// ✅ Recommended structure
@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Location for all resources')
param location string = resourceGroup().location

// Environment-specific SKU selection
var appServicePlanSku = environment == 'prod' ? {
  name: 'S1'
  tier: 'Standard'
  capacity: 2
} : {
  name: 'B1'
  tier: 'Basic'
  capacity: 1
}

// Managed Identity enabled by default
resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: 'app-${projectName}-${environment}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    // ... additional properties
  }
}

// Key Vault access via Managed Identity
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: '${keyVault.name}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: appService.identity.principalId
        permissions: {
          secrets: ['get', 'list']
        }
      }
    ]
  }
}
```

### Managed Identity Configuration

**Setup Process**:
1. Enable System-Assigned Managed Identity on Azure resource
2. Grant Key Vault access policy (Get, List secrets)
3. Use DefaultAzureCredential in application code
4. No connection strings or API keys needed

**Example Configuration**:
```typescript
// Application code (no secrets required)
import { DefaultAzureCredential } from "@azure/identity";
import { SecretClient } from "@azure/keyvault-secrets";

const credential = new DefaultAzureCredential();
const keyVaultUrl = `https://${process.env.KEY_VAULT_NAME}.vault.azure.net/`;
const client = new SecretClient(keyVaultUrl, credential);

// Retrieve secrets at runtime
const secret = await client.getSecret("database-connection-string");
```

---

## Cost Optimization Strategies

### 1. Auto-Scaling Configuration
```bicep
// Scale down to zero during off-hours (dev environments)
resource autoScaleSettings 'Microsoft.Insights/autoscalesettings@2022-10-01' = if (environment == 'dev') {
  name: 'auto-scale-${appService.name}'
  location: location
  properties: {
    enabled: true
    profiles: [
      {
        name: 'Business hours'
        capacity: {
          minimum: '1'
          maximum: '2'
          default: '1'
        }
        rules: []
        recurrence: {
          frequency: 'Week'
          schedule: {
            timeZone: 'Pacific Standard Time'
            days: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
            hours: [8]
            minutes: [0]
          }
        }
      }
      {
        name: 'Off hours'
        capacity: {
          minimum: '0'
          maximum: '0'
          default: '0'
        }
        recurrence: {
          frequency: 'Week'
          schedule: {
            timeZone: 'Pacific Standard Time'
            days: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
            hours: [18]
            minutes: [0]
          }
        }
      }
    ]
  }
}
```

### 2. Resource Tagging for Cost Tracking
```bicep
// Apply tags to all resources
var commonTags = {
  Environment: environment
  Project: projectName
  ManagedBy: 'Bicep'
  CostCenter: 'Innovation'
  Owner: 'brookside-bi'
}

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: 'app-${projectName}-${environment}'
  location: location
  tags: commonTags
  // ...
}
```

### 3. Application Insights Sampling
```bicep
// Reduce Application Insights costs via sampling
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${projectName}-${environment}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    SamplingPercentage: environment == 'prod' ? 100 : 20  // 20% sampling for dev
    DailyQuota: environment == 'dev' ? 1 : null  // 1 GB/day cap for dev
  }
}
```

### 4. Serverless Options
```bash
# Prefer serverless for intermittent workloads
Azure Functions (Consumption Plan): Pay per execution
Cosmos DB Serverless: Pay per operation (no provisioned throughput)
Azure SQL Serverless: Auto-pause after inactivity

# Cost comparison (monthly):
# - Function App (Consumption): $0-50
# - Function App (Premium EP1): $157
# Savings: 68-100% for low-traffic scenarios
```

---

## Daily Workflow

### 1. Authenticate to Azure
```powershell
# Login to Azure CLI
az login

# Verify correct subscription
az account show

# If wrong subscription, set it
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
```

### 2. Configure MCP Environment
```powershell
# Set environment variables from Key Vault
.\scripts\Set-MCPEnvironment.ps1

# Verify configuration
.\scripts\Test-AzureMCP.ps1
```

### 3. Launch Claude Code
```powershell
# With environment configured, start Claude
claude
```

**Frequency**: Repeat authentication daily (Azure CLI tokens expire after 24 hours)

---

## Troubleshooting

### Issue: "az account show" returns error or empty
**Cause**: Not authenticated to Azure CLI
**Solution**:
```powershell
az login
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
```

### Issue: Key Vault access denied
**Cause**: Insufficient permissions or wrong Key Vault name
**Solution**:
1. Verify Key Vault name: `kv-brookside-secrets`
2. Check permissions: `az keyvault show --name kv-brookside-secrets`
3. Request access from Key Vault administrator

### Issue: MCP servers can't connect to Azure
**Cause**: Environment variables not set or Azure CLI not authenticated
**Solution**:
```powershell
# Re-authenticate
az login

# Re-configure environment
.\scripts\Set-MCPEnvironment.ps1

# Test connectivity
.\scripts\Test-AzureMCP.ps1
```

### Issue: Deployment fails with "Quota exceeded"
**Cause**: Subscription limits reached for specific resource type
**Solution**:
1. Check quota: `az vm list-usage --location westus2 --output table`
2. Request quota increase via Azure Portal
3. Consider alternative regions with available capacity

---

## Resource Management

### List All Resources in Subscription
```bash
az resource list --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84" --output table
```

### List Resources by Tag
```bash
az resource list --tag Environment=prod --output table
az resource list --tag Project=ai-cost-optimizer --output table
```

### Get Resource Costs (Monthly)
```bash
# Via Azure Cost Management
az costmanagement query \
  --type Usage \
  --timeframe MonthToDate \
  --dataset-aggregation '{"totalCost":{"name":"PreTaxCost","function":"Sum"}}' \
  --dataset-grouping name="ResourceGroup" type="Dimension"
```

### Delete Resource Group (Use with Caution)
```bash
# Only for development/test environments
az group delete --name rg-[project]-dev --yes --no-wait
```

---

## Related Resources

**Scripts**:
- [Get-KeyVaultSecret.ps1](../scripts/Get-KeyVaultSecret.ps1)
- [Set-MCPEnvironment.ps1](../scripts/Set-MCPEnvironment.ps1)
- [Test-AzureMCP.ps1](../scripts/Test-AzureMCP.ps1)

**Documentation**:
- [MCP Configuration](./mcp-configuration.md)
- [Innovation Workflow](./innovation-workflow.md)
- [Configuration & Environment](./configuration.md)

**External**:
- [Azure CLI Documentation](https://learn.microsoft.com/en-us/cli/azure/)
- [Azure Key Vault Best Practices](https://learn.microsoft.com/en-us/azure/key-vault/general/best-practices)
- [Managed Identity Overview](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview)

---

**Last Updated**: 2025-10-26
