<#
.SYNOPSIS
    Diagnostic script to identify dependency linking failures

.DESCRIPTION
    Systematically tests each component of the dependency linking process to isolate
    the failure point and provide actionable troubleshooting steps.

.NOTES
    Author: Brookside BI Innovation Nexus
    Date: 2025-10-26
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"

$KeyVaultName = "kv-brookside-secrets"
$SecretName = "notion-api-key"
$TestPageId = "29886779-099a-8175-8e1c-f09c7ad4788b"  # Repository Analyzer

function Write-TestHeader {
    param([string]$Text)
    Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
    Write-Host "  TEST: $Text" -ForegroundColor Cyan
    Write-Host "$('=' * 70)" -ForegroundColor Cyan
}

function Write-TestResult {
    param(
        [bool]$Success,
        [string]$Message,
        [string]$Detail = ""
    )

    if ($Success) {
        Write-Host "[PASS] $Message" -ForegroundColor Green
        if ($Detail) {
            Write-Host "  $Detail" -ForegroundColor Gray
        }
    } else {
        Write-Host "[FAIL] $Message" -ForegroundColor Red
        if ($Detail) {
            Write-Host "  $Detail" -ForegroundColor Yellow
        }
    }
}

function Test-AzureAuthentication {
    Write-TestHeader "Azure CLI Authentication"

    try {
        $account = az account show 2>&1 | ConvertFrom-Json
        if ($LASTEXITCODE -ne 0) {
            throw "Not authenticated"
        }

        Write-TestResult -Success $true -Message "Azure CLI authenticated" -Detail "User: $($account.user.name), Subscription: $($account.name)"
        return $true
    }
    catch {
        Write-TestResult -Success $false -Message "Azure CLI not authenticated" -Detail "Run: az login"
        return $false
    }
}

function Test-KeyVaultAccess {
    Write-TestHeader "Key Vault Access"

    try {
        # Test list access
        Write-Host "Testing Key Vault list permissions..." -ForegroundColor Gray
        $secrets = az keyvault secret list --vault-name $KeyVaultName 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Cannot list secrets in Key Vault"
        }

        Write-TestResult -Success $true -Message "Key Vault accessible" -Detail "Vault: $KeyVaultName"

        # Test specific secret retrieval
        Write-Host "`nTesting secret retrieval..." -ForegroundColor Gray
        $secret = az keyvault secret show --name $SecretName --vault-name $KeyVaultName --query value -o tsv 2>&1
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($secret)) {
            throw "Cannot retrieve secret: $SecretName"
        }

        Write-TestResult -Success $true -Message "Notion API key retrieved" -Detail "Length: $($secret.Length) characters"
        return $secret
    }
    catch {
        Write-TestResult -Success $false -Message "Key Vault access failed" -Detail "$_"
        Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
        Write-Host "  1. Check RBAC: az role assignment list --assignee `$(az account show --query user.name -o tsv) --scope /subscriptions/`$(az account show --query id -o tsv)" -ForegroundColor Gray
        Write-Host "  2. Verify Key Vault exists: az keyvault show --name $KeyVaultName" -ForegroundColor Gray
        Write-Host "  3. Check access policy: az keyvault show --name $KeyVaultName --query properties.accessPolicies" -ForegroundColor Gray
        return $null
    }
}

function Test-NotionApiConnectivity {
    param([string]$ApiKey)

    Write-TestHeader "Notion API Connectivity"

    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        Write-TestResult -Success $false -Message "No API key provided" -Detail "Cannot test Notion API"
        return $false
    }

    $headers = @{
        "Authorization" = "Bearer $ApiKey"
        "Notion-Version" = "2022-06-28"
        "Content-Type" = "application/json"
    }

    try {
        Write-Host "Testing page read access..." -ForegroundColor Gray
        $response = Invoke-RestMethod -Uri "https://api.notion.com/v1/pages/$TestPageId" -Headers $headers -Method Get

        if ($response.object -eq "page") {
            Write-TestResult -Success $true -Message "Notion API accessible" -Detail "Test page: $($response.properties.'Title'.title[0].plain_text)"

            # Check relation property
            $relationProperty = $response.properties.'Software/Tools Used'
            if ($relationProperty) {
                $currentCount = $relationProperty.relation.Count
                Write-Host "  Current relations: $currentCount" -ForegroundColor Gray
                return $true
            } else {
                Write-TestResult -Success $false -Message "Relation property 'Software/Tools Used' not found" -Detail "Check database schema"
                return $false
            }
        } else {
            throw "Unexpected response type: $($response.object)"
        }
    }
    catch {
        Write-TestResult -Success $false -Message "Notion API request failed" -Detail "$_"

        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "`nHTTP Status: $statusCode" -ForegroundColor Yellow

            $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "Response: $responseBody" -ForegroundColor Red
        }

        return $false
    }
}

function Test-NotionRelationUpdate {
    param([string]$ApiKey)

    Write-TestHeader "Notion Relation Update (Test)"

    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        Write-TestResult -Success $false -Message "No API key provided" -Detail "Cannot test relation update"
        return $false
    }

    $headers = @{
        "Authorization" = "Bearer $ApiKey"
        "Notion-Version" = "2022-06-28"
        "Content-Type" = "application/json"
    }

    try {
        # First, get current relations
        Write-Host "Fetching current relations..." -ForegroundColor Gray
        $pageResponse = Invoke-RestMethod -Uri "https://api.notion.com/v1/pages/$TestPageId" -Headers $headers -Method Get
        $currentRelations = $pageResponse.properties.'Software/Tools Used'.relation | ForEach-Object { $_.id }

        Write-Host "  Current relation count: $($currentRelations.Count)" -ForegroundColor Gray

        # Test update by writing back the same relations (no actual change)
        Write-Host "Testing relation update (no change test)..." -ForegroundColor Gray

        $relations = $currentRelations | ForEach-Object { @{ id = $_ } }
        $body = @{
            properties = @{
                'Software/Tools Used' = @{
                    relation = $relations
                }
            }
        } | ConvertTo-Json -Depth 10

        $updateResponse = Invoke-RestMethod -Uri "https://api.notion.com/v1/pages/$TestPageId" -Headers $headers -Method Patch -Body $body

        if ($updateResponse.object -eq "page") {
            Write-TestResult -Success $true -Message "Relation update successful" -Detail "Can write relations to Notion pages"
            return $true
        } else {
            throw "Unexpected response type: $($updateResponse.object)"
        }
    }
    catch {
        Write-TestResult -Success $false -Message "Relation update failed" -Detail "$_"

        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "`nHTTP Status: $statusCode" -ForegroundColor Yellow

            switch ($statusCode) {
                400 { Write-Host "Bad Request - Check relation property name and format" -ForegroundColor Yellow }
                401 { Write-Host "Unauthorized - API key may be invalid or expired" -ForegroundColor Yellow }
                403 { Write-Host "Forbidden - Integration lacks permission to update this page" -ForegroundColor Yellow }
                404 { Write-Host "Not Found - Page ID may be incorrect" -ForegroundColor Yellow }
                429 { Write-Host "Rate Limited - Too many requests to Notion API" -ForegroundColor Yellow }
            }

            try {
                $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                Write-Host "Response: $responseBody" -ForegroundColor Red
            } catch {}
        }

        return $false
    }
}

function Test-SoftwareIds {
    Write-TestHeader "Software ID Validation"

    $testIds = @(
        "29586779-099a-81aa-b696-e1487cb6c70b",  # poetry
        "29586779-099a-81ac-9ff0-ced75e246868",  # python
        "29586779-099a-8151-aa47-e7a707c12230"   # Azure Key Vault
    )

    $validCount = 0
    $invalidCount = 0

    foreach ($id in $testIds) {
        # Check if ID format is valid (UUID)
        if ($id -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
            $validCount++
        } else {
            $invalidCount++
            Write-Host "  Invalid ID format: $id" -ForegroundColor Red
        }
    }

    if ($invalidCount -eq 0) {
        Write-TestResult -Success $true -Message "Software IDs format valid" -Detail "Tested $validCount sample IDs"
        return $true
    } else {
        Write-TestResult -Success $false -Message "Invalid software IDs found" -Detail "$invalidCount invalid, $validCount valid"
        return $false
    }
}

# ============================================================================
# MAIN DIAGNOSTICS
# ============================================================================

Write-Host "`n╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        Dependency Linking Setup Diagnostics                       ║" -ForegroundColor Cyan
Write-Host "║        Brookside BI Innovation Nexus                              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$results = @{
    AzureAuth = $false
    KeyVaultAccess = $false
    NotionApi = $false
    RelationUpdate = $false
    SoftwareIds = $false
}

# Run tests
$results.AzureAuth = Test-AzureAuthentication

if ($results.AzureAuth) {
    $apiKey = Test-KeyVaultAccess
    $results.KeyVaultAccess = -not [string]::IsNullOrWhiteSpace($apiKey)

    if ($results.KeyVaultAccess) {
        $results.NotionApi = Test-NotionApiConnectivity -ApiKey $apiKey

        if ($results.NotionApi) {
            $results.RelationUpdate = Test-NotionRelationUpdate -ApiKey $apiKey
        }
    }
}

$results.SoftwareIds = Test-SoftwareIds

# Summary
Write-Host "`n╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                      DIAGNOSTIC SUMMARY                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`nTest Results:" -ForegroundColor White
Write-Host "  Azure Authentication:   " -NoNewline
Write-Host $(if ($results.AzureAuth) { "[PASS]" } else { "[FAIL]" }) -ForegroundColor $(if ($results.AzureAuth) { "Green" } else { "Red" })

Write-Host "  Key Vault Access:       " -NoNewline
Write-Host $(if ($results.KeyVaultAccess) { "[PASS]" } else { "[FAIL]" }) -ForegroundColor $(if ($results.KeyVaultAccess) { "Green" } else { "Red" })

Write-Host "  Notion API Connectivity:" -NoNewline
Write-Host $(if ($results.NotionApi) { "[PASS]" } else { "[FAIL]" }) -ForegroundColor $(if ($results.NotionApi) { "Green" } else { "Red" })

Write-Host "  Relation Update:        " -NoNewline
Write-Host $(if ($results.RelationUpdate) { "[PASS]" } else { "[FAIL]" }) -ForegroundColor $(if ($results.RelationUpdate) { "Green" } else { "Red" })

Write-Host "  Software IDs:           " -NoNewline
Write-Host $(if ($results.SoftwareIds) { "[PASS]" } else { "[FAIL]" }) -ForegroundColor $(if ($results.SoftwareIds) { "Green" } else { "Red" })

$allPassed = $results.Values | Where-Object { $_ -eq $false } | Measure-Object | Select-Object -ExpandProperty Count

Write-Host "`nOverall Status: " -NoNewline
if ($allPassed -eq 0) {
    Write-Host "[PASS] ALL TESTS PASSED - Ready to run Link-AllBuildDependencies.ps1" -ForegroundColor Green
} else {
    Write-Host "[FAIL] $allPassed TEST(S) FAILED - Review failures above" -ForegroundColor Red

    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    if (-not $results.AzureAuth) {
        Write-Host "  1. Run: az login" -ForegroundColor Gray
    }
    if (-not $results.KeyVaultAccess) {
        Write-Host "  2. Verify Key Vault permissions and secret existence" -ForegroundColor Gray
    }
    if (-not $results.NotionApi) {
        Write-Host "  3. Check Notion API key validity and page access" -ForegroundColor Gray
    }
    if (-not $results.RelationUpdate) {
        Write-Host "  4. Verify Notion integration has write permissions" -ForegroundColor Gray
    }
}

Write-Host "`n$('=' * 70)`n" -ForegroundColor Cyan

# Return exit code
if ($allPassed -eq 0) {
    exit 0
} else {
    exit 1
}
