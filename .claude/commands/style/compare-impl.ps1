<#
.SYNOPSIS
    Implementation wrapper for /style:compare slash command

.DESCRIPTION
    Establish side-by-side style comparison for same agent+task combination.
    Executes multiple styles and generates comparative effectiveness analysis.

.NOTES
    This script is called by Claude Code when /style:compare command is invoked.
#>

param(
    [Parameter(Mandatory = $false)]
    [string[]]$Arguments = @()
)

# Script configuration
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$UtilsDir = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) "utils"

<#
.SYNOPSIS
    Parse command arguments
#>
function Parse-CommandArguments {
    param([string[]]$Args)

    $result = @{
        AgentName = ""
        TaskDescription = ""
        Options = @{
            Styles = @()  # Empty = all 5 styles
            UltraThink = $false
            Sync = $false
            Format = "table"  # table|detailed|summary
        }
    }

    # Extract positional and named arguments
    $positional = @()
    $i = 0

    while ($i -lt $Args.Count) {
        $arg = $Args[$i]

        if ($arg.StartsWith("--")) {
            if ($arg -eq "--ultrathink") {
                $result.Options.UltraThink = $true
            }
            elseif ($arg -eq "--sync") {
                $result.Options.Sync = $true
            }
            elseif ($arg.StartsWith("--styles=")) {
                $stylesStr = $arg.Substring(9).Trim('"', "'")
                $result.Options.Styles = $stylesStr -split "," | ForEach-Object { $_.Trim() }
            }
            elseif ($arg.StartsWith("--format=")) {
                $result.Options.Format = $arg.Substring(9).Trim('"', "'")
            }
        }
        else {
            $positional += $arg
        }

        $i++
    }

    # Assign positional arguments
    if ($positional.Count -gt 0) { $result.AgentName = $positional[0] }
    if ($positional.Count -gt 1) { $result.TaskDescription = $positional[1] }

    # Default to all styles if none specified
    if ($result.Options.Styles.Count -eq 0) {
        $result.Options.Styles = @(
            "technical-implementer",
            "strategic-advisor",
            "visual-architect",
            "interactive-teacher",
            "compliance-auditor"
        )
    }

    return $result
}

<#
.SYNOPSIS
    Display comparative results table
#>
function Show-ComparisonTable {
    param(
        [array]$Results,
        [string]$Format
    )

    $sorted = $Results | Sort-Object { $_.Metrics.OverallEffectiveness } -Descending

    Write-Host "`n$('=' * 100)" -ForegroundColor Gray
    Write-Host "📊 Style Comparison Results" -ForegroundColor Yellow
    Write-Host "$('=' * 100)" -ForegroundColor Gray

    if ($Format -eq "table") {
        Write-Host "`n| Style | Effectiveness | Clarity | Technical | Formality | Time | Tier |"
        Write-Host "|-------|--------------|---------|-----------|-----------|------|------|"

        foreach ($test in $sorted) {
            $tier = if ($test.UltraThinkTier) { $test.UltraThinkTier } else { "N/A" }
            $tierEmoji = switch ($tier) {
                "Gold" { "🥇" }
                "Silver" { "🥈" }
                "Bronze" { "🥉" }
                default { "-" }
            }

            Write-Host ("| {0,-20} | {1,13} | {2,7} | {3,9} | {4,9} | {5,5} | {6,-5} |" -f `
                $test.StyleId, `
                "$($test.Metrics.OverallEffectiveness)/100", `
                "$([Math]::Round($test.Metrics.ClarityScore * 100))%", `
                "$([Math]::Round($test.Metrics.TechnicalDensity * 100))%", `
                "$([Math]::Round($test.Metrics.FormalityScore * 100))%", `
                "$([Math]::Round($test.Metrics.GenerationTimeMs / 1000, 1))s", `
                "$tierEmoji $tier"
            )
        }
    }
    elseif ($Format -eq "detailed") {
        foreach ($test in $sorted) {
            Write-Host "`n### $($test.StyleId)" -ForegroundColor Cyan
            Write-Host "Effectiveness: $($test.Metrics.OverallEffectiveness)/100" -ForegroundColor Green
            Write-Host "Technical Density: $([Math]::Round($test.Metrics.TechnicalDensity * 100, 1))%"
            Write-Host "Formality: $([Math]::Round($test.Metrics.FormalityScore * 100, 1))%"
            Write-Host "Clarity: $([Math]::Round($test.Metrics.ClarityScore * 100, 1))%"
            Write-Host "Visual Elements: $($test.Metrics.VisualElementsCount)"
            Write-Host "Generation Time: $([Math]::Round($test.Metrics.GenerationTimeMs / 1000, 2))s"

            if ($test.UltraThinkTier) {
                Write-Host "UltraThink Tier: $($test.UltraThinkTier)" -ForegroundColor Magenta
            }

            Write-Host ""
        }
    }

    Write-Host "`n🎯 Recommendation: $($sorted[0].StyleId)" -ForegroundColor Green
    Write-Host "   → Best for: $(Get-StyleUseCase -StyleId $sorted[0].StyleId)" -ForegroundColor Green
    Write-Host "   → Effectiveness: $($sorted[0].Metrics.OverallEffectiveness)/100" -ForegroundColor Green

    if ($sorted.Count -gt 1) {
        Write-Host "`n💡 Runner-Up: $($sorted[1].StyleId)" -ForegroundColor Cyan
        Write-Host "   → Best for: $(Get-StyleUseCase -StyleId $sorted[1].StyleId)" -ForegroundColor Cyan
        Write-Host "   → Effectiveness: $($sorted[1].Metrics.OverallEffectiveness)/100" -ForegroundColor Cyan
    }

    Write-Host "`n$('=' * 100)`n" -ForegroundColor Gray
}

<#
.SYNOPSIS
    Get style use case description
#>
function Get-StyleUseCase {
    param([string]$StyleId)

    $useCases = @{
        "technical-implementer" = "Developer-focused technical guidance with executable code"
        "strategic-advisor" = "Executive-ready business insights with ROI analysis"
        "visual-architect" = "Diagram-rich communication for cross-functional teams"
        "interactive-teacher" = "Educational content for onboarding and training"
        "compliance-auditor" = "Formal audit-ready documentation with evidence"
    }

    return $useCases[$StyleId]
}

<#
.SYNOPSIS
    Main execution function
#>
function Invoke-Main {
    Write-Host "`n🔄 Output Styles Comparison - Side-by-Side Analysis" -ForegroundColor Magenta
    Write-Host "$('=' * 100)" -ForegroundColor Gray

    try {
        # Parse arguments
        $params = Parse-CommandArguments -Args $Arguments

        if (-not $params.AgentName) {
            throw "Agent name required. Usage: /style:compare <agent-name> ""<task-description>"" [options]"
        }

        if (-not $params.TaskDescription) {
            throw "Task description required. Usage: /style:compare <agent-name> ""<task-description>"" [options]"
        }

        Write-Host "`nConfiguration:" -ForegroundColor Cyan
        Write-Host "  Agent: $($params.AgentName)"
        Write-Host "  Task: $($params.TaskDescription)"
        Write-Host "  Styles to Compare: $($params.Options.Styles.Count) ($($params.Options.Styles -join ', '))"
        Write-Host "  UltraThink: $($params.Options.UltraThink)"
        Write-Host "  Sync: $($params.Options.Sync)"
        Write-Host "  Format: $($params.Options.Format)"
        Write-Host ""

        # Execute tests for each style
        $allResults = @()
        $totalStyles = $params.Options.Styles.Count
        $currentStyle = 0

        foreach ($style in $params.Options.Styles) {
            $currentStyle++
            Write-Host "`n[$currentStyle/$totalStyles] Testing style: $style" -ForegroundColor Yellow

            # Build invoke-agent.ps1 parameters
            $invokeParams = @(
                "-AgentName", $params.AgentName,
                "-StyleId", $style,
                "-TaskDescription", $params.TaskDescription
            )

            if ($params.Options.UltraThink) {
                $invokeParams += "-UltraThink"
            }

            if ($params.Options.Sync) {
                $invokeParams += "-Sync"
            }

            # Execute test
            $invokePath = Join-Path $UtilsDir "invoke-agent.ps1"

            if (-not (Test-Path $invokePath)) {
                throw "Invoke-agent utility not found: $invokePath"
            }

            $result = & $invokePath @invokeParams

            if ($result.Success -and $result.Results.Count -gt 0) {
                $allResults += $result.Results[0]
                Write-Host "✅ Completed" -ForegroundColor Green
            }
            else {
                Write-Host "❌ Failed: $($result.Error)" -ForegroundColor Red
            }
        }

        if ($allResults.Count -eq 0) {
            throw "All tests failed - no results to compare"
        }

        # Display comparison
        Show-ComparisonTable -Results $allResults -Format $params.Options.Format

        Write-Host "✅ Comparison complete!" -ForegroundColor Green
        Write-Host "`nNext steps:" -ForegroundColor Cyan
        Write-Host "  • Use recommended style for production work"
        Write-Host "  • Test runner-up for alternative contexts"
        Write-Host "  • Generate detailed report: /style:report --agent=$($params.AgentName)" -ForegroundColor Cyan
        Write-Host ""

    }
    catch {
        Write-Host "`n❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
        exit 1
    }
}

# Execute main function
Invoke-Main
