# Deploy Notion Webhook Azure Function Infrastructure
# Establishes serverless webhook endpoint with Key Vault integration

param(
    [string]$ResourceGroup = "rg-brookside-innovation",
    [string]$Location = "eastus"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Webhook Infrastructure Deployment ===" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "Location: $Location`n" -ForegroundColor White

# Verify resource group exists
Write-Host "[1/3] Verifying resource group..." -ForegroundColor Yellow
$rg = az group show --name $ResourceGroup 2>$null | ConvertFrom-Json
if (-not $rg) {
    Write-Host "  Creating resource group..." -ForegroundColor Gray
    az group create --name $ResourceGroup --location $Location | Out-Null
    Write-Host "  ✓ Resource group created" -ForegroundColor Green
} else {
    Write-Host "  ✓ Resource group exists" -ForegroundColor Green
}

# Deploy Bicep template
Write-Host "`n[2/3] Deploying Bicep template..." -ForegroundColor Yellow
Write-Host "  This may take 3-5 minutes..." -ForegroundColor Gray

$deploymentName = "webhook-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$templateFile = Join-Path $PSScriptRoot "notion-webhook-function.bicep"
$parametersFile = Join-Path $PSScriptRoot "notion-webhook-function.parameters.json"

try {
    # Start deployment (synchronous)
    $deployment = az deployment group create `
        --name $deploymentName `
        --resource-group $ResourceGroup `
        --template-file $templateFile `
        --parameters "@$parametersFile" `
        --output json | ConvertFrom-Json

    if ($deployment.properties.provisioningState -eq "Succeeded") {
        Write-Host "  ✓ Infrastructure deployed successfully" -ForegroundColor Green

        # Extract outputs
        Write-Host "`n  Deployment Outputs:" -ForegroundColor Cyan
        Write-Host "    Function App URL: $($deployment.properties.outputs.functionAppUrl.value)" -ForegroundColor White
        Write-Host "    Webhook Endpoint: $($deployment.properties.outputs.webhookEndpoint.value)" -ForegroundColor White
        Write-Host "    Principal ID: $($deployment.properties.outputs.functionAppPrincipalId.value)" -ForegroundColor Gray

        # Save outputs to file for later use
        $outputs = @{
            FunctionAppUrl = $deployment.properties.outputs.functionAppUrl.value
            WebhookEndpoint = $deployment.properties.outputs.webhookEndpoint.value
            PrincipalId = $deployment.properties.outputs.functionAppPrincipalId.value
            DeploymentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        $outputs | ConvertTo-Json | Out-File (Join-Path $PSScriptRoot "deployment-outputs.json")

        Write-Host "`n  ✓ Deployment outputs saved to deployment-outputs.json" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Deployment failed" -ForegroundColor Red
        Write-Host "  Status: $($deployment.properties.provisioningState)" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "  ✗ Deployment error: $_" -ForegroundColor Red
    exit 1
}

# Verify Key Vault access
Write-Host "`n[3/3] Verifying Key Vault access..." -ForegroundColor Yellow

try {
    $functionAppName = "notion-webhook-brookside-prod"
    $keyVaultName = "kv-brookside-secrets"

    # Get function app identity
    $identity = az functionapp identity show `
        --name $functionAppName `
        --resource-group $ResourceGroup `
        --output json | ConvertFrom-Json

    if ($identity.principalId) {
        Write-Host "  ✓ Managed Identity configured" -ForegroundColor Green
        Write-Host "    Principal ID: $($identity.principalId)" -ForegroundColor Gray

        # Verify Key Vault access policy
        $vault = az keyvault show --name $keyVaultName --output json | ConvertFrom-Json
        $hasAccess = $vault.properties.accessPolicies | Where-Object { $_.objectId -eq $identity.principalId }

        if ($hasAccess) {
            Write-Host "  ✓ Key Vault access policy configured" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Warning: Key Vault access policy not found" -ForegroundColor Yellow
            Write-Host "    The Bicep template should have created this" -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Host "  ⚠ Warning: Could not verify Key Vault access: $_" -ForegroundColor Yellow
}

Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Build function code: cd azure-functions/notion-webhook && npm install && npm run build" -ForegroundColor White
Write-Host "  2. Deploy code: func azure functionapp publish notion-webhook-brookside-prod" -ForegroundColor White
Write-Host "  3. Test webhook: .\\.claude\\utils\\webhook-utilities.ps1 -Operation HealthCheck`n" -ForegroundColor White
