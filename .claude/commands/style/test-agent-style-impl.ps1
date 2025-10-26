<#
.SYNOPSIS
    Implementation wrapper for /test-agent-style slash command

.DESCRIPTION
    Establish connection between slash command interface and agent invocation infrastructure.
    Parses command arguments, invokes PowerShell utilities, and formats results for user presentation.

.NOTES
    This script is called by Claude Code when /test-agent-style command is invoked.
    It acts as the integration layer between command specification and utility implementation.
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
    Parse command arguments into structured parameters
#>
function Parse-CommandArguments {
    param([string[]]$Args)

    # Initialize result
    $result = @{
        AgentName = ""
        StyleId = ""
        Options = @{
            Task = ""
            Interactive = $false
            UltraThink = $false
            Sync = $false
            Report = $false
        }
    }

    # Extract positional arguments
    $positional = @()
    $i = 0

    while ($i -lt $Args.Count) {
        $arg = $Args[$i]

        if ($arg.StartsWith("--")) {
            # Named option
            if ($arg -eq "--interactive") {
                $result.Options.Interactive = $true
            }
            elseif ($arg -eq "--ultrathink") {
                $result.Options.UltraThink = $true
            }
            elseif ($arg -eq "--sync") {
                $result.Options.Sync = $true
            }
            elseif ($arg -eq "--report") {
                $result.Options.Report = $true
            }
            elseif ($arg.StartsWith("--task=")) {
                $result.Options.Task = $arg.Substring(7).Trim('"', "'")
            }
            elseif ($arg -eq "--task" -and ($i + 1) -lt $Args.Count) {
                $i++
                $result.Options.Task = $Args[$i].Trim('"', "'")
            }
        }
        else {
            # Positional argument
            $positional += $arg
        }

        $i++
    }

    # Assign positional arguments
    if ($positional.Count -gt 0) { $result.AgentName = $positional[0] }
    if ($positional.Count -gt 1) { $result.StyleId = $positional[1] }

    return $result
}

<#
.SYNOPSIS
    Display formatted test results
#>
function Show-TestResults {
    param([hashtable]$Results)

    if (-not $Results.Success) {
        Write-Host "`n❌ Test execution failed" -ForegroundColor Red
        Write-Host "Error: $($Results.Error)" -ForegroundColor Red
        return
    }

    Write-Host "`n✅ Test execution completed successfully" -ForegroundColor Green
    Write-Host "Total tests executed: $($Results.TestCount)" -ForegroundColor Cyan

    foreach ($test in $Results.Results) {
        Write-Host "`n$('=' * 80)" -ForegroundColor Gray
        Write-Host "📊 Results: $($test.AgentName) + $($test.StyleId)" -ForegroundColor Yellow
        Write-Host "$('=' * 80)" -ForegroundColor Gray

        Write-Host "`nBehavioral Metrics:" -ForegroundColor Cyan
        Write-Host "  • Output Length: $($test.Metrics.OutputLength) tokens"
        Write-Host "  • Technical Density: $([Math]::Round($test.Metrics.TechnicalDensity * 100, 1))%"
        Write-Host "  • Formality Score: $([Math]::Round($test.Metrics.FormalityScore * 100, 1))%"
        Write-Host "  • Clarity Score: $([Math]::Round($test.Metrics.ClarityScore * 100, 1))%"
        Write-Host "  • Visual Elements: $($test.Metrics.VisualElementsCount)"
        Write-Host "  • Code Blocks: $($test.Metrics.CodeBlocksCount)"

        Write-Host "`nPerformance Metrics:" -ForegroundColor Cyan
        Write-Host "  • Generation Time: $([Math]::Round($test.Metrics.GenerationTimeMs / 1000, 2))s"

        if ($test.Metrics.GoalAchievement) {
            Write-Host "`nEffectiveness Metrics:" -ForegroundColor Cyan
            Write-Host "  • Goal Achievement: $([Math]::Round($test.Metrics.GoalAchievement * 100, 1))%"
            Write-Host "  • Audience Appropriateness: $([Math]::Round($test.Metrics.AudienceAppropriateness * 100, 1))%"
            Write-Host "  • Style Consistency: $([Math]::Round($test.Metrics.StyleConsistency * 100, 1))%"
            Write-Host "  • User Satisfaction: $('⭐' * $test.Metrics.UserSatisfaction) ($($test.Metrics.UserSatisfaction)/5)"
        }

        Write-Host "`n🎯 Overall Effectiveness: $($test.Metrics.OverallEffectiveness)/100" -ForegroundColor Green

        if ($test.UltraThinkTier) {
            $tierEmoji = switch ($test.UltraThinkTier) {
                "Gold" { "🥇" }
                "Silver" { "🥈" }
                "Bronze" { "🥉" }
                default { "⚪" }
            }
            Write-Host "`n🏆 UltraThink Tier: $tierEmoji $($test.UltraThinkTier)" -ForegroundColor Magenta
        }

        if ($test.SyncResult -and $test.SyncResult.Success) {
            if ($test.SyncResult.Method -eq "Immediate") {
                Write-Host "`n✅ Synced to Notion: $($test.SyncResult.PageUrl)" -ForegroundColor Green
            }
            else {
                Write-Host "`n📋 Queued for Notion sync" -ForegroundColor Yellow
            }
        }
    }

    # Comparative analysis if multiple styles tested
    if ($Results.TestCount -gt 1) {
        Write-Host "`n$('=' * 80)" -ForegroundColor Gray
        Write-Host "📊 Comparative Analysis" -ForegroundColor Yellow
        Write-Host "$('=' * 80)" -ForegroundColor Gray

        $sorted = $Results.Results | Sort-Object { $_.Metrics.OverallEffectiveness } -Descending

        Write-Host "`n| Style | Effectiveness | Clarity | Technical | Formality | Time |"
        Write-Host "|-------|--------------|---------|-----------|-----------|------|"

        foreach ($test in $sorted) {
            $style = $test.StyleId.PadRight(20)
            $eff = "$($test.Metrics.OverallEffectiveness)/100".PadRight(13)
            $clarity = "$([Math]::Round($test.Metrics.ClarityScore * 100))%".PadRight(8)
            $tech = "$([Math]::Round($test.Metrics.TechnicalDensity * 100))%".PadRight(10)
            $formal = "$([Math]::Round($test.Metrics.FormalityScore * 100))%".PadRight(10)
            $time = "$([Math]::Round($test.Metrics.GenerationTimeMs / 1000, 1))s".PadRight(5)

            Write-Host "| $style | $eff | $clarity | $tech | $formal | $time |"
        }

        Write-Host "`n🎯 Top Recommendation: $($sorted[0].StyleId)" -ForegroundColor Green
        Write-Host "   → $($sorted[0].Metrics.OverallEffectiveness)/100 effectiveness" -ForegroundColor Green

        if ($sorted.Count -gt 1) {
            Write-Host "`n💡 Alternative: $($sorted[1].StyleId)" -ForegroundColor Cyan
            Write-Host "   → $($sorted[1].Metrics.OverallEffectiveness)/100 effectiveness" -ForegroundColor Cyan
        }
    }

    Write-Host "`n$('=' * 80)`n" -ForegroundColor Gray
}

<#
.SYNOPSIS
    Main execution function
#>
function Invoke-Main {
    Write-Host "`n🧪 Output Styles Testing - Agent+Style Combination Analysis" -ForegroundColor Magenta
    Write-Host "$('=' * 80)" -ForegroundColor Gray

    try {
        # Parse arguments
        $params = Parse-CommandArguments -Args $Arguments

        if (-not $params.AgentName) {
            throw "Agent name required. Usage: /test-agent-style <agent-name> <style-id> [options]"
        }

        if (-not $params.StyleId) {
            throw "Style ID required. Usage: /test-agent-style <agent-name> <style-id|?> [options]"
        }

        Write-Host "`nConfiguration:" -ForegroundColor Cyan
        Write-Host "  Agent: $($params.AgentName)"
        Write-Host "  Style: $($params.StyleId)"
        if ($params.Options.Task) {
            Write-Host "  Task: $($params.Options.Task)"
        }
        Write-Host "  Interactive: $($params.Options.Interactive)"
        Write-Host "  UltraThink: $($params.Options.UltraThink)"
        Write-Host "  Sync: $($params.Options.Sync)"
        Write-Host "  Report: $($params.Options.Report)"
        Write-Host ""

        # Build invoke-agent.ps1 parameters
        $invokeParams = @(
            "-AgentName", $params.AgentName,
            "-StyleId", $params.StyleId
        )

        if ($params.Options.Task) {
            $invokeParams += @("-TaskDescription", $params.Options.Task)
        }

        if ($params.Options.Interactive) {
            $invokeParams += "-Interactive"
        }

        if ($params.Options.UltraThink) {
            $invokeParams += "-UltraThink"
        }

        if ($params.Options.Sync) {
            $invokeParams += "-Sync"
        }

        # Execute agent invocation
        $invokePath = Join-Path $UtilsDir "invoke-agent.ps1"

        if (-not (Test-Path $invokePath)) {
            throw "Invoke-agent utility not found: $invokePath"
        }

        Write-Host "Executing agent tests..." -ForegroundColor Yellow

        $results = & $invokePath @invokeParams

        # Display results
        Show-TestResults -Results $results

        # Generate report if requested
        if ($params.Options.Report -and $results.Success) {
            Write-Host "`n📄 Generating detailed report..." -ForegroundColor Yellow

            $reportPath = Join-Path $ScriptDir "..\..\reports"
            if (-not (Test-Path $reportPath)) {
                New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
            }

            $reportFile = Join-Path $reportPath "style-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"

            # Build report content
            $reportContent = "# Output Styles Test Report`n`n"
            $reportContent += "**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
            $reportContent += "**Agent**: $($params.AgentName)`n"
            $reportContent += "**Style(s)**: $($params.StyleId)`n"
            if ($params.Options.Task) {
                $reportContent += "**Task**: $($params.Options.Task)`n"
            }
            $reportContent += "`n---`n`n"

            foreach ($test in $results.Results) {
                $reportContent += "## Test: $($test.AgentName) + $($test.StyleId)`n`n"
                $reportContent += "### Metrics`n`n"
                $reportContent += "| Metric | Value |`n"
                $reportContent += "|--------|-------|`n"
                $reportContent += "| Overall Effectiveness | $($test.Metrics.OverallEffectiveness)/100 |`n"
                $reportContent += "| Technical Density | $([Math]::Round($test.Metrics.TechnicalDensity * 100, 1))% |`n"
                $reportContent += "| Formality Score | $([Math]::Round($test.Metrics.FormalityScore * 100, 1))% |`n"
                $reportContent += "| Clarity Score | $([Math]::Round($test.Metrics.ClarityScore * 100, 1))% |`n"
                $reportContent += "| Generation Time | $([Math]::Round($test.Metrics.GenerationTimeMs / 1000, 2))s |`n"

                if ($test.UltraThinkTier) {
                    $reportContent += "| UltraThink Tier | $($test.UltraThinkTier) |`n"
                }

                $reportContent += "`n### Test Output`n`n"
                $reportContent += "``````markdown`n$($test.TestOutput)`n```````n`n"

                if ($test.TierJustification) {
                    $reportContent += "### UltraThink Analysis`n`n"
                    $reportContent += $test.TierJustification
                    $reportContent += "`n`n"
                }

                $reportContent += "---`n`n"
            }

            Set-Content -Path $reportFile -Value $reportContent
            Write-Host "✅ Report saved: $reportFile" -ForegroundColor Green
        }

        Write-Host "`n✅ Testing complete!" -ForegroundColor Green

    }
    catch {
        Write-Host "`n❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
        exit 1
    }
}

# Execute main function
Invoke-Main
