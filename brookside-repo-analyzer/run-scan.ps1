#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run Brookside BI Repository Analyzer with proper encoding
.DESCRIPTION
    Wrapper script to run the analyzer with UTF-8 encoding to display emojis properly.
    Supports single-organization or multi-organization scanning with automatic discovery.
.PARAMETER Org
    GitHub organization or username to scan (default: markus41)
    Ignored if -AllOrgs is specified
.PARAMETER AllOrgs
    Scan all organizations the authenticated user belongs to (automatic discovery)
.PARAMETER Full
    Run full deep analysis (slower but more comprehensive)
.PARAMETER Sync
    Sync results to Notion (requires Notion API key in Key Vault)
.EXAMPLE
    .\run-scan.ps1
    Scan default organization (markus41) with quick analysis
.EXAMPLE
    .\run-scan.ps1 -Org "my-org" -Full -Sync
    Scan specific organization with full analysis and Notion sync
.EXAMPLE
    .\run-scan.ps1 -AllOrgs -Full
    Scan all accessible organizations with deep analysis
.EXAMPLE
    .\run-scan.ps1 -AllOrgs -Quick -NoSync
    Quick scan across all organizations without Notion sync
#>

param(
    [string]$Org = "markus41",
    [switch]$AllOrgs,
    [switch]$Full,
    [switch]$Sync
)

# Set UTF-8 encoding for console output
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:PYTHONIOENCODING = "utf-8"

# Change to the analyzer directory
Push-Location $PSScriptRoot

try {
    # Build command arguments
    $analyzerArgs = @("run", "brookside-analyze", "scan")

    # Add organization parameters
    if ($AllOrgs) {
        $analyzerArgs += "--all-orgs"
    } else {
        $analyzerArgs += "--org", $Org
    }

    # Add analysis mode
    if ($Full) {
        $analyzerArgs += "--full"
    } else {
        $analyzerArgs += "--quick"
    }

    # Add sync parameter
    if (-not $Sync) {
        $analyzerArgs += "--no-sync"
    }

    Write-Host "`nBrookside BI Repository Analyzer" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan

    if ($AllOrgs) {
        Write-Host "Scope: All Organizations (auto-discovery)" -ForegroundColor Yellow
    } else {
        Write-Host "Organization: $Org" -ForegroundColor Yellow
    }

    Write-Host "Analysis Mode: $(if ($Full) { 'FULL (Deep)' } else { 'QUICK' })" -ForegroundColor Yellow
    Write-Host "Notion Sync: $(if ($Sync) { 'ENABLED' } else { 'DISABLED' })" -ForegroundColor Yellow
    Write-Host ""

    # Run the analyzer
    & 'C:\Users\MarkusAhling\AppData\Roaming\Python\Scripts\poetry.exe' @analyzerArgs

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nAnalysis complete! Check the output above for results." -ForegroundColor Green
    } else {
        Write-Host "`nAnalysis failed with exit code: $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
} finally {
    # Return to original directory
    Pop-Location
}
