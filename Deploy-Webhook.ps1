# Deploy Webhook Infrastructure and Configuration
# Run with: .\Deploy-Webhook.ps1

$ErrorActionPreference = "Stop"
$repoRoot = "c:\Users\MarkusAhling\Notion"
$resourceGroup = "rg-brookside-innovation"

Write-Host "`n=== Webhook Deployment Script ===" -ForegroundColor Cyan

# Step 1: Deploy Infrastructure
Write-Host "`n[1/5] Deploying Bicep Infrastructure..." -ForegroundColor Yellow
Set-Location "$repoRoot\infrastructure"

az deployment group create `
    --name "webhook-$(Get-Date -Format 'yyyyMMddHHmmss')" `
    --resource-group $resourceGroup `
    --template-file notion-webhook-function.bicep `
    --parameters "@notion-webhook-function.parameters.json" `
    --output table

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Infrastructure deployed successfully" -ForegroundColor Green
} else {
    Write-Host "  Infrastructure deployment failed - check error above" -ForegroundColor Red
    exit 1
}

# Step 2: Build Function Code
Write-Host "`n[2/5] Building Function Code..." -ForegroundColor Yellow
Set-Location "$repoRoot\azure-functions\notion-webhook"

npm install
npm run build

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Build successful" -ForegroundColor Green
} else {
    Write-Host "  Build failed" -ForegroundColor Red
    exit 1
}

# Step 3: Deploy Function
Write-Host "`n[3/5] Deploying to Azure Function App..." -ForegroundColor Yellow
func azure functionapp publish notion-webhook-brookside-prod

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Function deployed successfully" -ForegroundColor Green
} else {
    Write-Host "  Function deployment failed" -ForegroundColor Red
    exit 1
}

# Step 4: Test Webhook
Write-Host "`n[4/5] Testing Webhook Endpoint..." -ForegroundColor Yellow
Set-Location $repoRoot

$webhookSecret = "16997736f8a1727d23871acc6cb1586e03768f9c1704865c009bb391e608acf0"
.\.claude\utils\webhook-utilities.ps1 -Operation SendTestPayload -WebhookSecret $webhookSecret

Write-Host "  Check Agent Activity Hub for new page" -ForegroundColor Green
Write-Host "  URL: https://www.notion.so/72b879f213bd4edb9c59b43089dbef21" -ForegroundColor Gray

# Step 5: APIM Subscription Key
Write-Host "`n[5/5] Configuring APIM Subscription Key..." -ForegroundColor Yellow

$subscriptionId = "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
$apimName = "apim-brookside-innovation"
$token = az account get-access-token --query accessToken -o tsv
$uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.ApiManagement/service/$apimName/subscriptions/master/listSecrets?api-version=2021-08-01"

try {
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{
        Authorization = "Bearer $token"
        "Content-Type" = "application/json"
    }

    $apimKey = $response.primaryKey

    # Store in Key Vault
    az keyvault secret set --vault-name kv-brookside-secrets --name apim-subscription-key --value $apimKey --output none

    # Set environment variable
    [System.Environment]::SetEnvironmentVariable('APIM_SUBSCRIPTION_KEY', $apimKey, 'User')
    $env:APIM_SUBSCRIPTION_KEY = $apimKey

    Write-Host "  APIM key configured successfully" -ForegroundColor Green

} catch {
    Write-Host "  Warning: Could not retrieve APIM key automatically" -ForegroundColor Yellow
    Write-Host "  Get it manually from Portal: APIM -> Subscriptions -> master" -ForegroundColor Gray
}

Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Apply APIM policy (Portal: APIM -> APIs -> Policies)" -ForegroundColor White
Write-Host "   File: infrastructure\apim-webhook-policy.xml" -ForegroundColor Gray
Write-Host "2. Create MCP server export (Portal with preview mode)" -ForegroundColor White
Write-Host "3. Update Claude config: $env:APPDATA\Claude\claude_desktop_config.json" -ForegroundColor White
Write-Host "4. Restart Claude Code" -ForegroundColor White
Write-Host "`nSee NEXT-STEPS-CHECKLIST.md for detailed instructions" -ForegroundColor Cyan
