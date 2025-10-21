#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run Brookside BI Repository Analyzer with proper encoding
.DESCRIPTION
    Wrapper script to run the analyzer with UTF-8 encoding to display emojis properly
.PARAMETER Org
    GitHub organization or username to scan (default: markus41)
.PARAMETER Full
    Run full deep analysis (slower but more comprehensive)
.PARAMETER Sync
    Sync results to Notion (requires Notion API key in Key Vault)
.EXAMPLE
    .\run-scan.ps1
    .\run-scan.ps1 -Org "my-org" -Full -Sync
#>

param(
    [string]$Org = "markus41",
    [switch]$Full,
    [switch]$Sync
)

# Set UTF-8 encoding for console output
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:PYTHONIOENCODING = "utf-8"

# Build command arguments
$args = @("run", "brookside-analyze", "scan", "--org", $Org)
if ($Full) { $args += "--full" }
if (-not $Sync) { $args += "--no-sync" }

Write-Host "Brookside BI Repository Analyzer" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Run the analyzer
& 'C:\Users\MarkusAhling\AppData\Roaming\Python\Scripts\poetry.exe' @args

Write-Host ""
Write-Host "Analysis complete! Check the output above for results." -ForegroundColor Green
