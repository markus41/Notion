<#
.SYNOPSIS
    Execute automated dependency linking for Brookside BI Innovation Nexus

.DESCRIPTION
    Orchestrates Claude Code to perform dependency linking via Notion MCP.
    This script coordinates the linking of 258 software dependencies across
    5 Example Builds, delegating actual Notion operations to Claude Code.

.PARAMETER DryRun
    Preview mode - generates linking plan without executing

.PARAMETER BuildName
    Optional: Link dependencies for a specific build only

.EXAMPLE
    .\Execute-DependencyLinking.ps1 -DryRun
    Preview linking plan without execution

.EXAMPLE
    .\Execute-DependencyLinking.ps1
    Execute full dependency linking for all 5 builds
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$BuildName
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=================================================================================" -ForegroundColor Cyan
Write-Host "AUTOMATED DEPENDENCY LINKING ORCHESTRATION" -ForegroundColor Cyan
Write-Host "=================================================================================" -ForegroundColor Cyan
Write-Host "Mode: $(if ($DryRun) { 'DRY-RUN (Preview Only)' } else { 'PRODUCTION (Live Changes)' })" -ForegroundColor $(if ($DryRun) { 'Yellow' } else { 'Green' })
Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Load dependency mapping
$mappingPath = Join-Path $PSScriptRoot "..\data\dependency-mapping.json"

if (-not (Test-Path $mappingPath)) {
    Write-Host "ERROR: Dependency mapping not found at: $mappingPath" -ForegroundColor Red
    exit 1
}

try {
    $mapping = Get-Content $mappingPath -Raw | ConvertFrom-Json
    Write-Host "✓ Loaded dependency mapping: $($mapping.metadata.totalDependencies) dependencies across $($mapping.metadata.totalBuilds) builds" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to load dependency mapping: $_" -ForegroundColor Red
    exit 1
}

# Build page IDs (created in previous step)
$buildPageIds = @{
    "Repository Analyzer" = "29886779-099a-8175-8e1c-f09c7ad4788b"
    "Cost Optimization Dashboard" = "29886779-099a-81b2-928f-cb4c1d9e17c6"
    "Azure OpenAI Integration" = "29886779-099a-8120-8ac4-d19aa00456b6"
    "Documentation Automation" = "29886779-099a-813c-833f-ccfb4a86e5c7"
    "ML Deployment Pipeline" = "29886779-099a-81a9-96b5-f04a02e92d9b"
}

# Filter builds if specific build requested
$buildsToProcess = if ($BuildName) {
    $mapping.builds | Where-Object { $_.name -eq $BuildName }
} else {
    $mapping.builds
}

if ($buildsToProcess.Count -eq 0) {
    Write-Host "ERROR: No builds found matching filter: $BuildName" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Builds to process: $($buildsToProcess.Count)" -ForegroundColor Yellow
Write-Host ""

# Generate linking instructions for Claude Code
$linkingPlan = @()

foreach ($build in $buildsToProcess) {
    $buildPageId = $buildPageIds[$build.name]

    if (-not $buildPageId) {
        Write-Host "WARNING: No page ID found for build: $($build.name)" -ForegroundColor Yellow
        continue
    }

    # Collect all dependencies for this build
    $allDependencies = @()
    foreach ($category in $build.categories.PSObject.Properties) {
        $allDependencies += $category.Value
    }

    $linkingPlan += [PSCustomObject]@{
        BuildName = $build.name
        BuildPageId = $buildPageId
        ExpectedCount = $build.expectedDependencies
        ActualCount = $allDependencies.Count
        Dependencies = $allDependencies
    }

    Write-Host "✓ Prepared linking plan for: $($build.name)" -ForegroundColor Green
    Write-Host "  Page ID: $buildPageId" -ForegroundColor Gray
    Write-Host "  Dependencies: $($allDependencies.Count)" -ForegroundColor Gray
    Write-Host ""
}

if ($DryRun) {
    Write-Host "=================================================================================" -ForegroundColor Cyan
    Write-Host "DRY-RUN SUMMARY" -ForegroundColor Cyan
    Write-Host "=================================================================================" -ForegroundColor Cyan
    Write-Host ""

    foreach ($plan in $linkingPlan) {
        Write-Host "Build: $($plan.BuildName)" -ForegroundColor Yellow
        Write-Host "  Page ID: $($plan.BuildPageId)" -ForegroundColor Gray
        Write-Host "  Dependencies to link: $($plan.ActualCount)" -ForegroundColor Gray
        Write-Host "  Sample dependencies:" -ForegroundColor Gray
        $plan.Dependencies | Select-Object -First 5 | ForEach-Object {
            Write-Host "    - $_" -ForegroundColor DarkGray
        }
        if ($plan.Dependencies.Count -gt 5) {
            Write-Host "    ... and $($plan.Dependencies.Count - 5) more" -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    Write-Host "To execute linking, run without -DryRun flag" -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

# Production execution - delegate to Claude Code
Write-Host "=================================================================================" -ForegroundColor Cyan
Write-Host "DELEGATING TO CLAUDE CODE FOR NOTION MCP OPERATIONS" -ForegroundColor Cyan
Write-Host "=================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script has prepared the linking plan. Claude Code will now:" -ForegroundColor Yellow
Write-Host "  1. Search Software Tracker for each of the $($mapping.metadata.totalDependencies) dependencies" -ForegroundColor Gray
Write-Host "  2. Update each build's 'Software & Tools' relation property" -ForegroundColor Gray
Write-Host "  3. Handle rate limiting (~3 requests/second)" -ForegroundColor Gray
Write-Host "  4. Log all operations for validation" -ForegroundColor Gray
Write-Host ""

# Export linking plan for Claude Code consumption
$planPath = Join-Path $PSScriptRoot "..\data\linking-plan.json"
$linkingPlan | ConvertTo-Json -Depth 10 | Out-File -FilePath $planPath -Encoding UTF8

Write-Host "✓ Linking plan exported to: $planPath" -ForegroundColor Green
Write-Host ""
Write-Host "Ready for Claude Code execution." -ForegroundColor Green
Write-Host ""
