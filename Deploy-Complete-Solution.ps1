<#
.SYNOPSIS
    Complete webhook + APIM MCP deployment for Innovation Nexus

.DESCRIPTION
    Establishes end-to-end deployment of webhook infrastructure and APIM MCP server
    configuration for real-time agent activity tracking.

.NOTES
    Run this script in PowerShell with Administrator privileges
    Prerequisites: Azure CLI authenticated, Azure Function Core Tools installed
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$SkipWebhookDeploy,

    [Parameter(Mandatory=$false)]
    [switch]$SkipAPIMConfig,

    [Parameter(Mandatory=$false)]
    [switch]$TestOnly
)

$ErrorActionPreference = "Continue"
$repoRoot = "c:\Users\MarkusAhling\Notion"
$resourceGroup = "rg-brookside-innovation"
$location = "eastus"
$webhookSecret = "16997736f8a1727d23871acc6cb1586e03768f9c1704865c009bb391e608acf0"

# Color output functions
function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✓ $Message" -ForegroundColor Green
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "  ⚠ $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "  ✗ $Message" -ForegroundColor Red
}

# Verify prerequisites
Write-Step "Verifying Prerequisites"

# Check Azure CLI
try {
    $account = az account show | ConvertFrom-Json
    Write-Success "Azure CLI authenticated as $($account.user.name)"
} catch {
    Write-Error-Custom "Azure CLI not authenticated. Run: az login"
    exit 1
}

# Check Function Core Tools
try {
    $funcVersion = func --version
    Write-Success "Azure Function Core Tools installed: $funcVersion"
} catch {
    Write-Warning-Custom "Azure Function Core Tools not found. Install from: https://aka.ms/func-install"
}

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Success "Node.js installed: $nodeVersion"
} catch {
    Write-Error-Custom "Node.js not installed. Install from: https://nodejs.org"
    exit 1
}

#
# SECTION 1: Deploy Webhook Infrastructure
#
if (-not $SkipWebhookDeploy -and -not $TestOnly) {
    Write-Step "Deploying Webhook Infrastructure"

    Set-Location "$repoRoot\infrastructure"

    # Deploy Bicep template
    Write-Host "  Deploying Bicep template (5-10 minutes)..." -ForegroundColor Yellow

    $deploymentResult = az deployment group create `
        --name "webhook-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')" `
        --resource-group $resourceGroup `
        --template-file "notion-webhook-function.bicep" `
        --parameters "@notion-webhook-function.parameters.json" `
        --output json 2>&1

    if ($LASTEXITCODE -eq 0) {
        $deployment = $deploymentResult | ConvertFrom-Json
        Write-Success "Infrastructure deployed successfully"

        $functionAppUrl = $deployment.properties.outputs.functionAppUrl.value
        $webhookEndpoint = $deployment.properties.outputs.webhookEndpoint.value
        $principalId = $deployment.properties.outputs.functionAppPrincipalId.value

        Write-Host "    Function App URL: $functionAppUrl" -ForegroundColor Gray
        Write-Host "    Webhook Endpoint: $webhookEndpoint" -ForegroundColor Gray
        Write-Host "    Managed Identity: $principalId" -ForegroundColor Gray
    } else {
        Write-Error-Custom "Bicep deployment failed"
        Write-Host $deploymentResult -ForegroundColor Red
        Write-Host "`nPlease deploy manually using commands from DEPLOYMENT-MANUAL.md" -ForegroundColor Yellow
        $SkipWebhookDeploy = $true
    }

    if (-not $SkipWebhookDeploy) {
        # Build and deploy function code
        Write-Step "Building and Deploying Function Code"

        Set-Location "$repoRoot\azure-functions\notion-webhook"

        Write-Host "  Installing npm dependencies..." -ForegroundColor Yellow
        npm install

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Dependencies installed"
        } else {
            Write-Error-Custom "npm install failed"
            exit 1
        }

        Write-Host "  Building TypeScript..." -ForegroundColor Yellow
        npm run build

        if ($LASTEXITCODE -eq 0) {
            Write-Success "TypeScript compiled successfully"
        } else {
            Write-Error-Custom "TypeScript build failed"
            exit 1
        }

        Write-Host "  Deploying to Azure Function App..." -ForegroundColor Yellow
        func azure functionapp publish notion-webhook-brookside-prod

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Function code deployed"
        } else {
            Write-Error-Custom "Function deployment failed"
            exit 1
        }
    }
}

#
# SECTION 2: Test Webhook Endpoint
#
if (-not $TestOnly) {
    Write-Step "Testing Webhook Endpoint"

    Set-Location $repoRoot

    # Test webhook with utilities script
    Write-Host "  Sending test payload..." -ForegroundColor Yellow

    try {
        .\.claude\utils\webhook-utilities.ps1 -Operation SendTestPayload -WebhookSecret $webhookSecret
        Write-Success "Webhook test passed - check Agent Activity Hub for new page"
        Write-Host "    Verify at: https://www.notion.so/72b879f213bd4edb9c59b43089dbef21" -ForegroundColor Gray
    } catch {
        Write-Error-Custom "Webhook test failed: $_"
    }
}

#
# SECTION 3: Configure APIM
#
if (-not $SkipAPIMConfig -and -not $TestOnly) {
    Write-Step "Configuring APIM (Subscription Key)"

    # Get APIM subscription key using REST API
    Write-Host "  Retrieving APIM subscription key..." -ForegroundColor Yellow

    $subscriptionId = "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
    $apimName = "apim-brookside-innovation"

    # Use Azure REST API to get subscription key
    $token = az account get-access-token --query accessToken -o tsv
    $apiVersion = "2021-08-01"
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.ApiManagement/service/$apimName/subscriptions/master/listSecrets?api-version=$apiVersion"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{
            Authorization = "Bearer $token"
            "Content-Type" = "application/json"
        }

        $apimKey = $response.primaryKey
        Write-Success "APIM subscription key retrieved"

        # Store in Key Vault
        Write-Host "  Storing in Key Vault..." -ForegroundColor Yellow
        az keyvault secret set `
            --vault-name kv-brookside-secrets `
            --name apim-subscription-key `
            --value $apimKey `
            --output none

        if ($LASTEXITCODE -eq 0) {
            Write-Success "APIM key stored in Key Vault"
        } else {
            Write-Error-Custom "Failed to store APIM key in Key Vault"
        }

    } catch {
        Write-Error-Custom "Failed to retrieve APIM subscription key: $_"
        Write-Host "  You can get it manually from Azure Portal: APIM → Subscriptions → master" -ForegroundColor Yellow
    }
}

#
# SECTION 4: Configure Claude Code MCP Client
#
if (-not $TestOnly) {
    Write-Step "Configuring Claude Code MCP Client"

    # Get APIM key from Key Vault
    Write-Host "  Retrieving APIM key from Key Vault..." -ForegroundColor Yellow
    $apimKey = az keyvault secret show --vault-name kv-brookside-secrets --name apim-subscription-key --query value -o tsv

    if ($apimKey) {
        Write-Success "APIM key retrieved from Key Vault"

        # Set environment variable
        Write-Host "  Setting APIM_SUBSCRIPTION_KEY environment variable..." -ForegroundColor Yellow
        [System.Environment]::SetEnvironmentVariable('APIM_SUBSCRIPTION_KEY', $apimKey, 'User')
        $env:APIM_SUBSCRIPTION_KEY = $apimKey
        Write-Success "Environment variable set (restart Claude Code to load)"

        # Prepare Claude config
        $configPath = "$env:APPDATA\Claude\claude_desktop_config.json"

        if (Test-Path $configPath) {
            Write-Host "`n  Claude config file exists at: $configPath" -ForegroundColor Gray
            Write-Host "  Add this to mcpServers section:" -ForegroundColor Yellow

            $apimConfig = @"

    "azure-apim-innovation": {
      "type": "sse",
      "url": "https://apim-brookside-innovation.azure-api.net/notion-activity-mcp/mcp",
      "headers": {
        "Ocp-Apim-Subscription-Key": "{{APIM_SUBSCRIPTION_KEY}}"
      }
    }
"@
            Write-Host $apimConfig -ForegroundColor Cyan

        } else {
            Write-Warning-Custom "Claude config not found. Create it manually at: $configPath"
        }

    } else {
        Write-Warning-Custom "Could not retrieve APIM key from Key Vault"
    }
}

#
# SECTION 5: Summary and Next Steps
#
Write-Step "Deployment Summary"

if (-not $TestOnly) {
    Write-Host "`nCompleted Steps:" -ForegroundColor Green
    Write-Host "  ✓ Webhook infrastructure deployed (if successful)" -ForegroundColor Green
    Write-Host "  ✓ Function code built and deployed" -ForegroundColor Green
    Write-Host "  ✓ Webhook endpoint tested" -ForegroundColor Green
    Write-Host "  ✓ APIM subscription key stored in Key Vault" -ForegroundColor Green
    Write-Host "  ✓ Environment variable set for Claude Code" -ForegroundColor Green
}

Write-Host "`nRemaining Manual Steps:" -ForegroundColor Yellow
Write-Host "  1. Apply APIM Policy (Azure Portal):" -ForegroundColor Yellow
Write-Host "     - Portal → apim-brookside-innovation → APIs → notion-activity-webhook" -ForegroundColor Gray
Write-Host "     - Click 'All operations' → 'Policies' → Paste XML from infrastructure/apim-webhook-policy.xml" -ForegroundColor Gray

Write-Host "`n  2. Create APIM MCP Server Export (Portal with Preview):" -ForegroundColor Yellow
Write-Host "     - Navigate to: https://portal.azure.com/?feature.canmodifystamps=true&Microsoft_Azure_ApiManagement=mcp" -ForegroundColor Gray
Write-Host "     - Go to: apim-brookside-innovation → APIs → MCP Servers → + Create MCP server" -ForegroundColor Gray
Write-Host "     - API: notion-activity-webhook, Operations: log-activity, Name: notion-activity-mcp" -ForegroundColor Gray

Write-Host "`n  3. Update Claude Code Config:" -ForegroundColor Yellow
Write-Host "     - Edit: $env:APPDATA\Claude\claude_desktop_config.json" -ForegroundColor Gray
Write-Host "     - Add azure-apim-innovation server (config shown above)" -ForegroundColor Gray

Write-Host "`n  4. Restart Claude Code and verify:" -ForegroundColor Yellow
Write-Host "     - Run: claude mcp list" -ForegroundColor Gray
Write-Host "     - Should show: ✓ azure-apim-innovation (Connected)" -ForegroundColor Gray

Write-Host "`n  5. Test end-to-end:" -ForegroundColor Yellow
Write-Host "     - Trigger agent work → Check hook logs for 'Successfully synced via webhook'" -ForegroundColor Gray
Write-Host "     - Invoke MCP tool from Claude → Verify Notion page creation" -ForegroundColor Gray

Write-Host "`nDetailed instructions: NEXT-STEPS-CHECKLIST.md" -ForegroundColor Cyan
Write-Host "Full status report: WEBHOOK-APIM-IMPLEMENTATION-STATUS.md" -ForegroundColor Cyan

Write-Host "`n=== Deployment Script Complete ===" -ForegroundColor Green
