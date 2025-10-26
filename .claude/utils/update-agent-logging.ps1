<#
.SYNOPSIS
    Batch-add Activity Logging section to all agent specification files

.DESCRIPTION
    Applies the standardized Activity Logging template from .claude/templates/agent-logging-template.md
    to all agent files in .claude/agents/ directory. Customizes {AGENT-NAME} placeholder for each agent.

.PARAMETER DryRun
    Preview changes without modifying files (default: $false)

.PARAMETER AgentName
    Update specific agent only (default: all agents)

.PARAMETER Force
    Overwrite existing Activity Logging sections (default: skip if exists)

.EXAMPLE
    # Preview changes for all agents
    .\update-agent-logging.ps1 -DryRun

.EXAMPLE
    # Update all agents
    .\update-agent-logging.ps1

.EXAMPLE
    # Update specific agent only
    .\update-agent-logging.ps1 -AgentName "cost-analyst"

.EXAMPLE
    # Force update (replace existing sections)
    .\update-agent-logging.ps1 -Force

.NOTES
    Author: Claude Code Agent (documentation-orchestrator)
    Last Updated: 2025-10-26
    Purpose: Standardize activity logging guidance across Innovation Nexus agents
#>

param(
    [switch]$DryRun = $false,
    [string]$AgentName = "",
    [switch]$Force = $false
)

# Establish script configuration
$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $PSScriptRoot
$agentsPath = Join-Path $scriptRoot "agents"
$templatesDir = Join-Path $scriptRoot "templates"
$templatePath = Join-Path $templatesDir "agent-logging-template.md"

Write-Host "`n=== Agent Activity Logging Batch Update ===" -ForegroundColor Cyan
Write-Host "Purpose: Apply standardized logging guidance to all agent specifications`n" -ForegroundColor Gray

# Validate paths
if (-not (Test-Path $agentsPath)) {
    Write-Error "Agents directory not found: $agentsPath"
    exit 1
}

if (-not (Test-Path $templatePath)) {
    Write-Error "Template file not found: $templatePath"
    exit 1
}

# Read template content
$templateContent = Get-Content -Path $templatePath -Raw

# Extract template section (between specific markers)
$startMarker = "## Template Content \(Copy from here\)"
$endMarker = "## Template Usage Instructions"

if ($templateContent -match "(?s)$startMarker(.*?)$endMarker") {
    $templateSection = $Matches[1].Trim()
    # Remove the first "---" separator that's part of the marker
    $templateSection = $templateSection -replace "^---\s*", ""
} else {
    Write-Error "Could not extract template section from template file"
    exit 1
}

Write-Host "Template loaded: $($templateSection.Length) characters`n" -ForegroundColor Green

# Get agent files
if ($AgentName) {
    $agentFiles = Get-ChildItem -Path (Join-Path $agentsPath "$AgentName.md") -File -ErrorAction SilentlyContinue
    if (-not $agentFiles) {
        Write-Error "Agent file not found: $AgentName.md"
        exit 1
    }
} else {
    $agentFiles = Get-ChildItem -Path (Join-Path $agentsPath "*.md") -File
}

Write-Host "Found $($agentFiles.Count) agent file(s) to process`n" -ForegroundColor Cyan

# Statistics
$stats = @{
    Total = $agentFiles.Count
    Updated = 0
    Skipped = 0
    AlreadyExists = 0
    Errors = 0
}

# Process each agent file
foreach ($agentFile in $agentFiles) {
    $agentName = $agentFile.BaseName
    $displayName = "@$agentName"

    try {
        $content = Get-Content -Path $agentFile.FullName -Raw

        # Check if agent already has Activity Logging section
        $hasLoggingSection = $content -match "## Activity Logging"

        if ($hasLoggingSection -and -not $Force) {
            Write-Host "[SKIP] $displayName - Activity Logging section already exists" -ForegroundColor Yellow
            $stats.AlreadyExists++
            $stats.Skipped++
            continue
        }

        # Customize template for this specific agent
        $customizedTemplate = $templateSection -replace '\{AGENT-NAME\}', $displayName

        # Generate agent-specific example based on agent type
        $agentSpecificExample = switch -Wildcard ($agentName) {
            "cost-*" { "Q4 spend analysis complete - identified `$450/month savings via Microsoft consolidation. Recommendations in Software Tracker with 12-month ROI." }
            "build-*" { "Architecture complete, transferring to @code-generator. ADR-2025-10-26-Azure-Functions documents all technical decisions. Bicep templates ready for implementation." }
            "research-*" { "Research swarm complete: Market 78/100, Technical 92/100, Cost 81/100, Risk 85/100. Overall viability: 84/100 (High). Recommend immediate build approval." }
            "deployment-*" { "Production deployment successful - https://app.example.com live. Zero-downtime migration, all health checks green. Cost: `$12.40/month (F1 tier)." }
            "viability-*" { "Assessment complete: 87/100 (High). Recommend immediate build approval. Key decision: Selected Azure Functions over Container Apps due to cost efficiency." }
            "knowledge-*" { "Knowledge archival complete: 3 technical docs, 2 ADRs, 1 runbook created from Build-2025-10-21. All linked to Knowledge Vault with searchable tags." }
            "*-architect" { "Architecture design complete with ADR documentation. Transferring to implementation team with comprehensive technical specifications and cost projections." }
            default { "Work completed successfully with comprehensive documentation of decisions, rationale, and next steps for workflow continuity." }
        }

        $customizedTemplate = $customizedTemplate -replace '\{Agent-specific work description with context, decisions, and next steps\}', $agentSpecificExample

        # Determine insertion point
        $updatedContent = ""

        if ($Force -and $hasLoggingSection) {
            # Remove existing Activity Logging section and replace
            $updatedContent = $content -replace "(?s)## Activity Logging.*?(?=##|$)", $customizedTemplate + "`n`n"
            Write-Host "[REPLACE] $displayName - Replacing existing Activity Logging section" -ForegroundColor Magenta
        } elseif ($content -match "## Related Resources") {
            # Insert before Related Resources
            $updatedContent = $content -replace "(## Related Resources)", "$customizedTemplate`n`n`$1"
            Write-Host "[INSERT] $displayName - Adding before Related Resources section" -ForegroundColor Green
        } else {
            # Add at end before final separator
            $updatedContent = $content.TrimEnd() + "`n`n$customizedTemplate`n"
            Write-Host "[APPEND] $displayName - Adding at end of file" -ForegroundColor Green
        }

        if ($DryRun) {
            Write-Host "  → DRY RUN: Would update $($agentFile.Name) ($($customizedTemplate.Length) chars added)" -ForegroundColor Yellow
            $stats.Skipped++
        } else {
            # Write updated content
            Set-Content -Path $agentFile.FullName -Value $updatedContent -NoNewline
            $stats.Updated++
        }

    } catch {
        Write-Host "[ERROR] $displayName - $($_.Exception.Message)" -ForegroundColor Red
        $stats.Errors++
    }
}

# Display summary
Write-Host "`n=== Batch Update Summary ===" -ForegroundColor Cyan
Write-Host "Total files processed: $($stats.Total)" -ForegroundColor White
Write-Host "Updated successfully:  $($stats.Updated)" -ForegroundColor Green
Write-Host "Skipped (dry run):     $($stats.Skipped)" -ForegroundColor Yellow
Write-Host "Already exists:        $($stats.AlreadyExists)" -ForegroundColor Yellow
Write-Host "Errors encountered:    $($stats.Errors)" -ForegroundColor $(if ($stats.Errors -gt 0) { "Red" } else { "Gray" })

if ($DryRun) {
    Write-Host "`n[INFO] This was a DRY RUN - no files were modified" -ForegroundColor Yellow
    Write-Host "       Run without -DryRun flag to apply changes`n" -ForegroundColor Gray
} else {
    Write-Host "`n[SUCCESS] Batch update complete!" -ForegroundColor Green
}

# Return statistics for programmatic use
return $stats
