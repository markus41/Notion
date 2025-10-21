# Deployment Script for Autonomous Innovation Platform
# Establishes Azure infrastructure with validation and monitoring

<#
.SYNOPSIS
    Deploys autonomous innovation platform infrastructure to Azure

.DESCRIPTION
    This solution is designed to establish scalable automation infrastructure that
    streamlines innovation workflows from concept to production. Deploys Function Apps,
    Cosmos DB pattern database, and monitoring resources.

.PARAMETER Environment
    Deployment environment (dev, staging, prod). Default: dev

.PARAMETER Location
    Azure region for resources. Default: eastus

.PARAMETER ResourceGroupName
    Resource group name. Default: rg-brookside-innovation-automation

.PARAMETER WhatIf
    Preview deployment without making changes

.EXAMPLE
    .\deploy.ps1 -Environment dev

.EXAMPLE
    .\deploy.ps1 -Environment prod -WhatIf
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment = 'dev',

    [Parameter()]
    [string]$Location = 'eastus',

    [Parameter()]
    [string]$ResourceGroupName = 'rg-brookside-innovation-automation',

    [Parameter()]
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Step {
    param([string]$Message)
    Write-Host "`n===> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Failure {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

# ============================================================================
# PRE-DEPLOYMENT VALIDATION
# ============================================================================

Write-Step "Pre-Deployment Validation"

# Check Azure CLI installation
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Success "Azure CLI version: $($azVersion.'azure-cli')"
} catch {
    Write-Failure "Azure CLI not found. Install from: https://aka.ms/InstallAzureCLI"
    exit 1
}

# Check authentication
Write-Step "Verifying Azure Authentication"
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Success "Authenticated as: $($account.user.name)"
    Write-Success "Subscription: $($account.name) ($($account.id))"
} catch {
    Write-Failure "Not authenticated to Azure. Run: az login"
    exit 1
}

# Verify Key Vault access
Write-Step "Verifying Key Vault Access"
$keyVaultName = "kv-brookside-secrets"
try {
    az keyvault secret list --vault-name $keyVaultName --output none
    Write-Success "Key Vault access verified: $keyVaultName"
} catch {
    Write-Failure "Cannot access Key Vault: $keyVaultName"
    Write-Warning "Ensure you have 'Key Vault Secrets User' role or higher"
    exit 1
}

# Verify required secrets exist
$requiredSecrets = @('notion-api-key', 'github-personal-access-token')
foreach ($secretName in $requiredSecrets) {
    try {
        az keyvault secret show --vault-name $keyVaultName --name $secretName --output none
        Write-Success "Secret found: $secretName"
    } catch {
        Write-Failure "Required secret not found: $secretName"
        Write-Warning "Create secret: az keyvault secret set --vault-name $keyVaultName --name $secretName --value '<value>'"
        exit 1
    }
}

# ============================================================================
# RESOURCE GROUP CREATION
# ============================================================================

Write-Step "Ensuring Resource Group Exists"
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq 'false') {
    Write-Host "Creating resource group: $ResourceGroupName in $Location"

    if (-not $WhatIf) {
        az group create `
            --name $ResourceGroupName `
            --location $Location `
            --tags "Environment=$Environment" "Project=Autonomous Innovation Platform" "ManagedBy=Bicep"

        Write-Success "Resource group created: $ResourceGroupName"
    } else {
        Write-Warning "[WHATIF] Would create resource group: $ResourceGroupName"
    }
} else {
    Write-Success "Resource group exists: $ResourceGroupName"
}

# ============================================================================
# BICEP DEPLOYMENT
# ============================================================================

Write-Step "Deploying Infrastructure via Bicep"

$deploymentName = "autonomous-platform-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$templateFile = Join-Path $PSScriptRoot "main.bicep"
$parametersFile = Join-Path $PSScriptRoot "parameters.json"

# Validate template
Write-Host "Validating Bicep template..."
try {
    az deployment group validate `
        --resource-group $ResourceGroupName `
        --template-file $templateFile `
        --parameters $parametersFile `
        --parameters environment=$Environment `
        --output none

    Write-Success "Template validation passed"
} catch {
    Write-Failure "Template validation failed"
    Write-Host $_.Exception.Message
    exit 1
}

# Deploy (or show what-if)
if ($WhatIf) {
    Write-Warning "[WHATIF] Showing deployment changes..."
    az deployment group what-if `
        --resource-group $ResourceGroupName `
        --template-file $templateFile `
        --parameters $parametersFile `
        --parameters environment=$Environment

    Write-Warning "[WHATIF] No resources were deployed"
    exit 0
}

Write-Host "Deploying infrastructure (this may take 5-10 minutes)..."
try {
    $deployment = az deployment group create `
        --resource-group $ResourceGroupName `
        --name $deploymentName `
        --template-file $templateFile `
        --parameters $parametersFile `
        --parameters environment=$Environment `
        --output json | ConvertFrom-Json

    Write-Success "Infrastructure deployed successfully"
} catch {
    Write-Failure "Deployment failed"
    Write-Host $_.Exception.Message
    exit 1
}

# ============================================================================
# POST-DEPLOYMENT VERIFICATION
# ============================================================================

Write-Step "Post-Deployment Verification"

# Extract outputs
$outputs = $deployment.properties.outputs
$functionAppName = $outputs.functionAppName.value
$webhookEndpoint = $outputs.webhookEndpoint.value
$cosmosDbEndpoint = $outputs.cosmosDbEndpoint.value

Write-Success "Function App: $functionAppName"
Write-Success "Webhook Endpoint: $webhookEndpoint"
Write-Success "Cosmos DB Endpoint: $cosmosDbEndpoint"

# Verify Function App is running
Write-Host "Verifying Function App status..."
$functionApp = az functionapp show `
    --name $functionAppName `
    --resource-group $ResourceGroupName `
    --output json | ConvertFrom-Json

if ($functionApp.state -eq 'Running') {
    Write-Success "Function App is running"
} else {
    Write-Warning "Function App state: $($functionApp.state)"
}

# ============================================================================
# CONFIGURATION SUMMARY
# ============================================================================

Write-Step "Deployment Summary"

$summary = @"

╔══════════════════════════════════════════════════════════════════════════╗
║              AUTONOMOUS INNOVATION PLATFORM DEPLOYED                     ║
╚══════════════════════════════════════════════════════════════════════════╝

Environment:         $Environment
Resource Group:      $ResourceGroupName
Location:            $Location

ENDPOINTS:
  Webhook Receiver:  $webhookEndpoint
  Cosmos DB:         $cosmosDbEndpoint
  Function App:      https://$functionAppName.azurewebsites.net

NEXT STEPS:
  1. Deploy Function App code:
     cd ../functions
     func azure functionapp publish $functionAppName

  2. Configure Notion webhooks:
     - Navigate to Notion workspace settings
     - Add webhook URL: $webhookEndpoint
     - Subscribe to database property changes

  3. Test webhook delivery:
     - Create a new idea in Notion Ideas Registry
     - Check Function App logs in Azure Portal

  4. Monitor execution:
     - Azure Portal → $functionAppName → Monitor → Live Metrics
     - Application Insights for detailed logs

COST ESTIMATE:
  Monthly: ~`$50-100 (Consumption plan + Cosmos DB serverless)

DOCUMENTATION:
  README.md:           ../README.md
  Architecture:        ../docs/ARCHITECTURE.md
  Troubleshooting:     ../docs/TROUBLESHOOTING.md

"@

Write-Host $summary -ForegroundColor Cyan

# ============================================================================
# SAVE DEPLOYMENT INFO
# ============================================================================

$deploymentInfo = @{
    DeploymentName = $deploymentName
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Environment = $Environment
    ResourceGroup = $ResourceGroupName
    FunctionAppName = $functionAppName
    WebhookEndpoint = $webhookEndpoint
    CosmosDbEndpoint = $cosmosDbEndpoint
}

$deploymentInfoPath = Join-Path $PSScriptRoot "deployment-info-$Environment.json"
$deploymentInfo | ConvertTo-Json | Out-File $deploymentInfoPath

Write-Success "Deployment info saved: $deploymentInfoPath"
Write-Success "Deployment complete! 🚀"
