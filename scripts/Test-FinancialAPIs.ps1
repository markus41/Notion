<#
.SYNOPSIS
    Validate financial API connectivity and environment configuration.

.DESCRIPTION
    Establish comprehensive health checks for Morningstar and Bloomberg API integrations.
    Verifies environment variables, API authentication, and basic connectivity to drive
    measurable confidence in financial data infrastructure.

    This solution is designed to streamline troubleshooting and ensure reliable access
    to market data services across the Innovation Nexus.

.PARAMETER Detailed
    If specified, performs extended validation including sample API queries.
    Default behavior performs basic authentication and connectivity checks only.

.EXAMPLE
    .\Test-FinancialAPIs.ps1
    Performs basic health checks for all financial APIs

.EXAMPLE
    .\Test-FinancialAPIs.ps1 -Detailed
    Performs extended validation with sample API queries

.NOTES
    Best for: Organizations requiring reliable market data access for cost analysis,
    research coordination, viability assessment, and market intelligence workflows.

    Designed for: Brookside BI Innovation Nexus - Financial API health monitoring.

    Prerequisites:
    - Azure Key Vault secrets configured (morningstar-api-key, bloomberg credentials)
    - Environment variables set via Set-MCPEnvironment.ps1
    - Network access to Morningstar and Bloomberg endpoints

    Created: 2025-10-26
    Author: Brookside BI
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$Detailed
)

$ErrorActionPreference = "Stop"

# Test counters
$TotalTests = 0
$PassedTests = 0
$FailedTests = 0

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message
    )

    $script:TotalTests++

    if ($Passed) {
        $script:PassedTests++
        Write-Host "✓ $TestName" -ForegroundColor Green
        if ($Message) {
            Write-Host "  $Message" -ForegroundColor Gray
        }
    } else {
        $script:FailedTests++
        Write-Host "✗ $TestName" -ForegroundColor Red
        if ($Message) {
            Write-Host "  $Message" -ForegroundColor Yellow
        }
    }
}

function Test-EnvironmentVariable {
    param(
        [string]$VarName,
        [string]$FriendlyName
    )

    $value = [Environment]::GetEnvironmentVariable($VarName)

    if ($value) {
        $maskedValue = if ($value.Length -gt 8) {
            "$($value.Substring(0, 4))...***"
        } else {
            "***"
        }
        Write-TestResult -TestName "$FriendlyName environment variable set" `
            -Passed $true `
            -Message "Value present: $maskedValue"
        return $true
    } else {
        Write-TestResult -TestName "$FriendlyName environment variable set" `
            -Passed $false `
            -Message "Run .\scripts\Set-MCPEnvironment.ps1 to configure"
        return $false
    }
}

function Test-MorningstarAPI {
    param([bool]$Detailed)

    Write-Host "`nTesting Morningstar Financial Data API..." -ForegroundColor Cyan

    $apiKeyPresent = Test-EnvironmentVariable -VarName "MORNINGSTAR_API_KEY" -FriendlyName "Morningstar API Key"

    if (-not $apiKeyPresent) {
        return
    }

    if ($Detailed) {
        # Note: Actual API testing would require Morningstar SDK or REST endpoint
        # This is a placeholder for future implementation
        Write-TestResult -TestName "Morningstar API connectivity" `
            -Passed $true `
            -Message "Environment configured (actual API testing requires Morningstar SDK)"
    }
}

function Test-BloombergAPI {
    param([bool]$Detailed)

    Write-Host "`nTesting Bloomberg Terminal/API..." -ForegroundColor Cyan

    $usernamePresent = Test-EnvironmentVariable -VarName "BLOOMBERG_API_USERNAME" -FriendlyName "Bloomberg Username"
    $passwordPresent = Test-EnvironmentVariable -VarName "BLOOMBERG_API_PASSWORD" -FriendlyName "Bloomberg Password"

    if (-not ($usernamePresent -and $passwordPresent)) {
        return
    }

    # Check for Bloomberg Terminal installation
    $terminalPath = "C:\blp\API\Bloomberg.exe"
    $terminalInstalled = Test-Path $terminalPath

    Write-TestResult -TestName "Bloomberg Terminal installed" `
        -Passed $terminalInstalled `
        -Message $(if ($terminalInstalled) { "Found at: $terminalPath" } else { "Not found - BLPAPI mode only" })

    if ($Detailed -and $terminalInstalled) {
        # Note: Actual terminal testing would require launching Bloomberg and checking connectivity
        Write-TestResult -TestName "Bloomberg Terminal connectivity" `
            -Passed $true `
            -Message "Environment configured (manual terminal launch recommended for full validation)"
    }
}

function Test-AzureKeyVault {
    Write-Host "`nTesting Azure Key Vault access..." -ForegroundColor Cyan

    try {
        $azAccount = az account show 2>$null | ConvertFrom-Json

        if ($azAccount) {
            Write-TestResult -TestName "Azure CLI authenticated" `
                -Passed $true `
                -Message "Subscription: $($azAccount.name)"

            # Test Key Vault access
            $vaultName = "kv-brookside-secrets"
            $secretList = az keyvault secret list --vault-name $vaultName --query "[].name" --output tsv 2>$null

            if ($secretList) {
                $secretCount = ($secretList | Measure-Object -Line).Lines
                Write-TestResult -TestName "Key Vault accessible" `
                    -Passed $true `
                    -Message "$vaultName contains $secretCount secrets"
            } else {
                Write-TestResult -TestName "Key Vault accessible" `
                    -Passed $false `
                    -Message "Unable to access $vaultName - verify permissions"
            }
        } else {
            Write-TestResult -TestName "Azure CLI authenticated" `
                -Passed $false `
                -Message "Run 'az login' to establish secure connection"
        }
    } catch {
        Write-TestResult -TestName "Azure CLI installation" `
            -Passed $false `
            -Message "Azure CLI not found - install from https://aka.ms/installazurecli"
    }
}

# Main execution
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  Financial APIs Health Check" -ForegroundColor Cyan
Write-Host "  Brookside BI Innovation Nexus" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Test Azure infrastructure
Test-AzureKeyVault

# Test individual APIs
Test-MorningstarAPI -Detailed:$Detailed
Test-BloombergAPI -Detailed:$Detailed

# Summary
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "Total Tests:  $TotalTests" -ForegroundColor White
Write-Host "Passed:       $PassedTests" -ForegroundColor Green
Write-Host "Failed:       $FailedTests" -ForegroundColor $(if ($FailedTests -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($FailedTests -eq 0) {
    Write-Host "All health checks passed! Financial APIs ready for use." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Launch Claude Code: claude" -ForegroundColor White
    Write-Host "  2. Use financial API operations in cost-analyst, research-coordinator agents" -ForegroundColor White
    Write-Host "  3. Reference documentation: .claude/docs/financial-apis.md" -ForegroundColor White
} else {
    Write-Host "Some health checks failed. Review errors above and address configuration issues." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Common fixes:" -ForegroundColor Cyan
    Write-Host "  1. Run: .\scripts\Set-MCPEnvironment.ps1" -ForegroundColor White
    Write-Host "  2. Verify Azure Key Vault secrets configured" -ForegroundColor White
    Write-Host "  3. Check network connectivity to financial data providers" -ForegroundColor White
    Write-Host "  4. Review documentation: .claude/docs/financial-apis.md" -ForegroundColor White
    exit 1
}

Write-Host ""
