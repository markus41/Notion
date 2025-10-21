#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Comprehensive GitHub Portfolio Analyzer - Scans all organizations and personal repositories
.DESCRIPTION
    Streamlines portfolio-wide repository analysis across multiple GitHub organizations
    and personal accounts. Establishes automated viability assessment, Claude Code
    integration detection, and optional Notion synchronization to drive measurable
    outcomes through centralized knowledge management.
.PARAMETER Full
    Run full deep analysis (slower but more comprehensive)
.PARAMETER Sync
    Sync results to Notion Innovation Nexus (requires notion-api-key in Key Vault)
.PARAMETER OrgList
    Comma-separated list of specific organizations to scan (defaults to all accessible orgs)
.EXAMPLE
    .\run-all-orgs-scan.ps1
    Quick scan of all organizations and personal repos
.EXAMPLE
    .\run-all-orgs-scan.ps1 -Full -Sync
    Deep analysis with Notion synchronization
.EXAMPLE
    .\run-all-orgs-scan.ps1 -OrgList "Advisor-OS,Brookside-Proving-Grounds" -Full
    Scan specific organizations only
#>

param(
    [switch]$Full,
    [switch]$Sync,
    [string]$OrgList = $null
)

# Set UTF-8 encoding for console output
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:PYTHONIOENCODING = "utf-8"

# Change to the analyzer directory
Push-Location $PSScriptRoot

try {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  Brookside BI Portfolio Analyzer" -ForegroundColor Cyan
    Write-Host "  Comprehensive Multi-Organization Repository Analysis" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

    # Define all accessible organizations
    $allOrganizations = @(
        "markus41",                          # Personal account
        "Advisor-OS",                        # Organization 1
        "The-Chronicle-of-Realm-Works",      # Organization 2
        "Densbys-MVPs",                      # Organization 3
        "Brookside-Proving-Grounds"          # Organization 4
    )

    # Override with user-specified list if provided
    if ($OrgList) {
        $organizations = $OrgList -split ',' | ForEach-Object { $_.Trim() }
        Write-Host "Scanning specific organizations: $($organizations -join ', ')" -ForegroundColor Yellow
    } else {
        $organizations = $allOrganizations
        Write-Host "Scanning all accessible organizations and personal repos" -ForegroundColor Yellow
    }

    Write-Host "Total organizations to scan: $($organizations.Count)" -ForegroundColor Yellow
    Write-Host "Analysis Mode: $(if ($Full) { 'FULL (Deep Analysis)' } else { 'QUICK' })" -ForegroundColor Yellow
    Write-Host "Notion Sync: $(if ($Sync) { 'ENABLED' } else { 'DISABLED' })" -ForegroundColor Yellow
    Write-Host ""

    # Initialize aggregate results
    $totalRepos = 0
    $totalCosts = 0
    $scanResults = @()

    # Scan each organization
    foreach ($org in $organizations) {
        $orgNumber = $organizations.IndexOf($org) + 1

        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
        Write-Host "[$orgNumber/$($organizations.Count)] Scanning: $org" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
        Write-Host ""

        # Build command arguments for this organization
        $analyzerArgs = @(
            "run", "brookside-analyze", "scan",
            "--org", $org
        )

        if ($Full) { $analyzerArgs += "--full" }
        if (-not $Sync) { $analyzerArgs += "--no-sync" }

        # Execute scan
        $startTime = Get-Date
        & 'C:\Users\MarkusAhling\AppData\Roaming\Python\Scripts\poetry.exe' @analyzerArgs
        $duration = (Get-Date) - $startTime

        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n[OK] $org scan completed in $($duration.TotalSeconds.ToString('F1'))s" -ForegroundColor Green
            $scanResults += [PSCustomObject]@{
                Organization = $org
                Status = "Success"
                Duration = $duration.TotalSeconds
            }
        } else {
            Write-Host "`n[FAIL] $org scan failed with exit code: $LASTEXITCODE" -ForegroundColor Red
            $scanResults += [PSCustomObject]@{
                Organization = $org
                Status = "Failed"
                Duration = $duration.TotalSeconds
            }
        }

        Write-Host ""
    }

    # Display comprehensive summary
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  Portfolio Analysis Summary" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

    $successCount = ($scanResults | Where-Object { $_.Status -eq "Success" }).Count
    $failedCount = ($scanResults | Where-Object { $_.Status -eq "Failed" }).Count
    $totalDuration = ($scanResults | Measure-Object -Property Duration -Sum).Sum

    Write-Host "Organizations Scanned: $($organizations.Count)" -ForegroundColor White
    Write-Host "  [OK] Successful: $successCount" -ForegroundColor Green
    if ($failedCount -gt 0) {
        Write-Host "  [FAIL] Failed: $failedCount" -ForegroundColor Red
    }
    Write-Host "Total Scan Duration: $($totalDuration.ToString('F1'))s`n" -ForegroundColor White

    # Display per-organization results
    Write-Host "Scan Results by Organization:" -ForegroundColor Yellow
    foreach ($result in $scanResults) {
        $statusSymbol = if ($result.Status -eq "Success") { "[OK]" } else { "[FAIL]" }
        $statusColor = if ($result.Status -eq "Success") { "Green" } else { "Red" }

        Write-Host "  $statusSymbol " -NoNewline -ForegroundColor $statusColor
        Write-Host "$($result.Organization.PadRight(35)) " -NoNewline -ForegroundColor White
        Write-Host "$($result.Duration.ToString('F1'))s" -ForegroundColor DarkGray
    }

    Write-Host ""

    if ($Sync) {
        Write-Host "All results synced to Notion Innovation Nexus" -ForegroundColor Green
        Write-Host "View Example Builds: https://www.notion.so/a1cd152897d...`n" -ForegroundColor Blue
    }

    if ($failedCount -eq 0) {
        Write-Host "Portfolio analysis complete! All organizations scanned successfully." -ForegroundColor Green
        exit 0
    } else {
        Write-Host "Portfolio analysis completed with some failures. Review errors above." -ForegroundColor Yellow
        exit 1
    }

} finally {
    # Return to original directory
    Pop-Location
}
