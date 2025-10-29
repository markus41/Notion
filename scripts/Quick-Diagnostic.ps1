# Quick Dependency Linking Diagnostic
# Simple ASCII-only version for clear output

$ErrorActionPreference = "Continue"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Quick Diagnostic - Dependency Linking" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: Azure CLI
Write-Host "[TEST 1] Azure CLI Authentication..." -ForegroundColor Yellow
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -eq 0 -and $account.user) {
        Write-Host "  [PASS] Authenticated as: $($account.user.name)" -ForegroundColor Green
        Write-Host "  Subscription: $($account.name)" -ForegroundColor Gray
        $azureOk = $true
    } else {
        throw "Not authenticated"
    }
} catch {
    Write-Host "  [FAIL] Not logged in" -ForegroundColor Red
    Write-Host "  Action: Run 'az login'" -ForegroundColor Yellow
    $azureOk = $false
}

# Test 2: Key Vault Access
if ($azureOk) {
    Write-Host "`n[TEST 2] Key Vault Access..." -ForegroundColor Yellow
    try {
        $secret = az keyvault secret show --name notion-api-key --vault-name kv-brookside-secrets --query value -o tsv 2>&1
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($secret)) {
            Write-Host "  [PASS] API key retrieved (length: $($secret.Length))" -ForegroundColor Green
            $kvOk = $true
            $apiKey = $secret
        } else {
            throw "Cannot retrieve secret"
        }
    } catch {
        Write-Host "  [FAIL] Cannot access Key Vault or secret" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Gray
        Write-Host "  Action: Verify Key Vault permissions" -ForegroundColor Yellow
        $kvOk = $false
    }
} else {
    Write-Host "`n[TEST 2] Key Vault Access... [SKIP - Azure not authenticated]" -ForegroundColor Gray
    $kvOk = $false
}

# Test 3: Notion API
if ($kvOk) {
    Write-Host "`n[TEST 3] Notion API Connectivity..." -ForegroundColor Yellow
    try {
        $headers = @{
            "Authorization" = "Bearer $apiKey"
            "Notion-Version" = "2022-06-28"
        }
        $response = Invoke-RestMethod -Uri "https://api.notion.com/v1/pages/29886779-099a-8175-8e1c-f09c7ad4788b" -Headers $headers -Method Get

        if ($response.object -eq "page") {
            Write-Host "  [PASS] Notion API accessible" -ForegroundColor Green
            $pageTitle = $response.properties.'Title'.title[0].plain_text
            Write-Host "  Test page: $pageTitle" -ForegroundColor Gray

            # Check relation property
            $relations = $response.properties.'Software/Tools Used'.relation
            Write-Host "  Current relations: $($relations.Count)" -ForegroundColor Gray
            $notionOk = $true
        } else {
            throw "Unexpected response"
        }
    } catch {
        Write-Host "  [FAIL] Cannot connect to Notion API" -ForegroundColor Red
        if ($_.Exception.Response) {
            Write-Host "  HTTP Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Gray
        }
        Write-Host "  Action: Verify API key validity and page access" -ForegroundColor Yellow
        $notionOk = $false
    }
} else {
    Write-Host "`n[TEST 3] Notion API Connectivity... [SKIP - No API key]" -ForegroundColor Gray
    $notionOk = $false
}

# Test 4: Write Permission Test
if ($notionOk) {
    Write-Host "`n[TEST 4] Notion Write Permissions..." -ForegroundColor Yellow
    try {
        # Get current relations
        $headers = @{
            "Authorization" = "Bearer $apiKey"
            "Notion-Version" = "2022-06-28"
            "Content-Type" = "application/json"
        }
        $page = Invoke-RestMethod -Uri "https://api.notion.com/v1/pages/29886779-099a-8175-8e1c-f09c7ad4788b"  -Headers $headers -Method Get
        $currentRelations = $page.properties.'Software/Tools Used'.relation | ForEach-Object { $_.id }

        # Try to update with same data (no change)
        $relations = $currentRelations | ForEach-Object { @{ id = $_ } }
        $body = @{
            properties = @{
                'Software/Tools Used' = @{ relation = $relations }
            }
        } | ConvertTo-Json -Depth 10

        $update = Invoke-RestMethod -Uri "https://api.notion.com/v1/pages/29886779-099a-8175-8e1c-f09c7ad4788b" -Headers $headers -Method Patch -Body $body

        if ($update.object -eq "page") {
            Write-Host "  [PASS] Can update relation properties" -ForegroundColor Green
            $writeOk = $true
        } else {
            throw "Unexpected response"
        }
    } catch {
        Write-Host "  [FAIL] Cannot update Notion pages" -ForegroundColor Red
        if ($_.Exception.Response) {
            $status = $_.Exception.Response.StatusCode.value__
            Write-Host "  HTTP Status: $status" -ForegroundColor Gray
            if ($status -eq 403) {
                Write-Host "  Action: Grant integration write access to database" -ForegroundColor Yellow
            }
        }
        $writeOk = $false
    }
} else {
    Write-Host "`n[TEST 4] Notion Write Permissions... [SKIP - API not accessible]" -ForegroundColor Gray
    $writeOk = $false
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$testResults = @(
    @{ Name = "Azure CLI"; Status = $azureOk },
    @{ Name = "Key Vault"; Status = $kvOk },
    @{ Name = "Notion API"; Status = $notionOk },
    @{ Name = "Write Permissions"; Status = $writeOk }
)

foreach ($test in $testResults) {
    $status = if ($test.Status) { "[PASS]" } else { "[FAIL]" }
    $color = if ($test.Status) { "Green" } else { "Red" }
    Write-Host "  $($test.Name): " -NoNewline
    Write-Host $status -ForegroundColor $color
}

$allPass = $testResults | Where-Object { -not $_.Status } | Measure-Object | Select-Object -ExpandProperty Count

Write-Host "`nOverall: " -NoNewline
if ($allPass -eq 0) {
    Write-Host "[READY] All systems operational" -ForegroundColor Green
    Write-Host "`nNext: Run .\scripts\Link-AllBuildDependencies.ps1 -DryRun" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "[$allPass test(s) failed]" -ForegroundColor Red
    Write-Host "`nFix the failed tests above before proceeding." -ForegroundColor Yellow
    exit 1
}
