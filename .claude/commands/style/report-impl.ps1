<#
.SYNOPSIS
    Implementation wrapper for /style:report slash command

.DESCRIPTION
    Establish performance analytics reporting for output styles testing.
    Queries historical test data and generates trend analysis with optimization recommendations.

.NOTES
    This script is called by Claude Code when /style:report command is invoked.
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
        Options = @{
            Agent = ""
            Style = ""
            Timeframe = "30d"  # 7d|30d|90d|all
            Format = "summary"  # summary|detailed|executive
            Export = ""
        }
    }

    $i = 0
    while ($i -lt $Args.Count) {
        $arg = $Args[$i]

        if ($arg.StartsWith("--agent=")) {
            $result.Options.Agent = $arg.Substring(8).Trim('"', "'")
        }
        elseif ($arg.StartsWith("--style=")) {
            $result.Options.Style = $arg.Substring(8).Trim('"', "'")
        }
        elseif ($arg.StartsWith("--timeframe=")) {
            $result.Options.Timeframe = $arg.Substring(12).Trim('"', "'")
        }
        elseif ($arg.StartsWith("--format=")) {
            $result.Options.Format = $arg.Substring(9).Trim('"', "'")
        }
        elseif ($arg.StartsWith("--export=")) {
            $result.Options.Export = $arg.Substring(9).Trim('"', "'")
        }

        $i++
    }

    return $result
}

<#
.SYNOPSIS
    Main execution function
#>
function Invoke-Main {
    Write-Host "`n📊 Output Styles Performance Report" -ForegroundColor Magenta
    Write-Host "$('=' * 80)" -ForegroundColor Gray

    try {
        # Parse arguments
        $params = Parse-CommandArguments -Args $Arguments

        # Validate at least one filter
        if (-not $params.Options.Agent -and -not $params.Options.Style) {
            Write-Host "`n⚠️  Note: No filters specified - generating portfolio-wide report" -ForegroundColor Yellow
        }

        Write-Host "`nReport Configuration:" -ForegroundColor Cyan
        if ($params.Options.Agent) {
            Write-Host "  Agent Filter: $($params.Options.Agent)"
        }
        if ($params.Options.Style) {
            Write-Host "  Style Filter: $($params.Options.Style)"
        }
        Write-Host "  Timeframe: $($params.Options.Timeframe)"
        Write-Host "  Format: $($params.Options.Format)"
        if ($params.Options.Export) {
            Write-Host "  Export Path: $($params.Options.Export)"
        }
        Write-Host ""

        # Build generate-style-report.ps1 parameters
        $reportParams = @(
            "-Timeframe", $params.Options.Timeframe,
            "-Format", $params.Options.Format
        )

        if ($params.Options.Agent) {
            $reportParams += @("-Agent", $params.Options.Agent)
        }

        if ($params.Options.Style) {
            $reportParams += @("-Style", $params.Options.Style)
        }

        if ($params.Options.Export) {
            $reportParams += @("-ExportPath", $params.Options.Export)
        }

        # Execute report generation
        $reportPath = Join-Path $UtilsDir "generate-style-report.ps1"

        if (-not (Test-Path $reportPath)) {
            throw "Report generator utility not found: $reportPath"
        }

        Write-Host "Generating report..." -ForegroundColor Yellow

        $result = & $reportPath @reportParams

        if (-not $result.Success) {
            if ($result.Reason -eq "InsufficientData") {
                Write-Host "`n⚠️  Insufficient test data for meaningful analysis" -ForegroundColor Yellow
                Write-Host "Found: $($result.TestCount) tests | Required: $($result.MinRequired) tests" -ForegroundColor Yellow
                Write-Host "`nSuggestion: Run additional tests using /test-agent-style command" -ForegroundColor Cyan
                Write-Host "Example: /test-agent-style @cost-analyst ? --ultrathink --sync" -ForegroundColor Cyan
                return
            }
            else {
                throw "Report generation failed: $($result.Error)"
            }
        }

        # Report already displayed by utility, just add closing remarks
        Write-Host "`n✅ Report generation complete!" -ForegroundColor Green

        if ($params.Options.Export) {
            Write-Host "📄 Report exported to: $($result.ExportPath)" -ForegroundColor Green
        }

        Write-Host "`nNext steps:" -ForegroundColor Cyan
        if ($result.Statistics.PassRate -lt 75) {
            Write-Host "  • Investigate low-performing combinations" -ForegroundColor Yellow
            Write-Host "  • Run detailed tests: /test-agent-style [agent] ? --ultrathink" -ForegroundColor Cyan
        }
        elseif ($result.Statistics.Trend -lt -5) {
            Write-Host "  • Review recent style definition changes" -ForegroundColor Yellow
            Write-Host "  • Compare current vs historical tests" -ForegroundColor Cyan
        }
        else {
            Write-Host "  • Continue quarterly optimization reviews" -ForegroundColor Green
            Write-Host "  • Expand testing coverage to new agent combinations" -ForegroundColor Cyan
        }
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
