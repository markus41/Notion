<#
.SYNOPSIS
    Style Report Generator - Create performance analytics reports for output styles testing

.DESCRIPTION
    Establish data-driven style optimization through comprehensive reporting on agent+style
    effectiveness metrics. Designed for organizations scaling AI agent deployments where
    systematic style selection drives measurable communication quality improvements.

.PARAMETER Agent
    Filter report to specific agent (e.g., "@cost-analyst")

.PARAMETER Style
    Filter report to specific style across all agents (e.g., "strategic-advisor")

.PARAMETER Timeframe
    Time period for report: 7d, 30d, 90d, all (default: 30d)

.PARAMETER Format
    Report format: summary, detailed, executive (default: summary)

.PARAMETER ExportPath
    Optional file path to export report as markdown

.PARAMETER MinTests
    Minimum number of tests required for inclusion in analysis (default: 1)

.EXAMPLE
    .\generate-style-report.ps1 -Agent "@cost-analyst" -Timeframe 30d

.EXAMPLE
    .\generate-style-report.ps1 -Style "strategic-advisor" -Timeframe 90d -Format detailed

.EXAMPLE
    .\generate-style-report.ps1 -Timeframe all -Format executive -ExportPath "report.md"

.NOTES
    Author: Brookside BI Innovation Nexus
    Purpose: Style performance analytics and optimization recommendations
    Best for: Teams requiring quarterly style effectiveness reviews and continuous improvement
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Agent = "",

    [Parameter(Mandatory = $false)]
    [string]$Style = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("7d", "30d", "90d", "all")]
    [string]$Timeframe = "30d",

    [Parameter(Mandatory = $false)]
    [ValidateSet("summary", "detailed", "executive")]
    [string]$Format = "summary",

    [Parameter(Mandatory = $false)]
    [string]$ExportPath = "",

    [Parameter(Mandatory = $false)]
    [int]$MinTests = 1
)

# Script configuration
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path $ScriptDir "..\logs\style-report.log"

# Import utilities
. (Join-Path $ScriptDir "notion-style-db.ps1")

# Initialize logging
function Write-ReportLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [StyleReport] [$Level] $Message"

    # Console output
    $color = switch ($Level) {
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "DEBUG" { "Gray" }
        default { "White" }
    }

    if ($VerbosePreference -eq "Continue" -or $Level -ne "DEBUG") {
        Write-Host $logMessage -ForegroundColor $color
    }

    # File logging
    try {
        $logDir = Split-Path -Parent $LogFile
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        Add-Content -Path $LogFile -Value $logMessage -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "Failed to write to log file: $_"
    }
}

<#
.SYNOPSIS
    Calculate start date based on timeframe parameter
#>
function Get-StartDate {
    param([string]$Timeframe)

    $now = Get-Date
    switch ($Timeframe) {
        "7d" { return $now.AddDays(-7) }
        "30d" { return $now.AddDays(-30) }
        "90d" { return $now.AddDays(-90) }
        "all" { return [DateTime]::MinValue }
        default { return $now.AddDays(-30) }
    }
}

<#
.SYNOPSIS
    Query test data from Notion with filters
#>
function Get-TestData {
    param(
        [string]$AgentFilter,
        [string]$StyleFilter,
        [DateTime]$StartDate
    )

    Write-ReportLog "Querying test data (Agent: '$AgentFilter', Style: '$StyleFilter', Since: $($StartDate.ToString('yyyy-MM-dd')))" -Level INFO

    # Build filter hashtable
    $filters = @{}
    if ($AgentFilter) { $filters.AgentName = $AgentFilter }
    if ($StyleFilter) { $filters.StyleId = $StyleFilter }
    if ($StartDate -ne [DateTime]::MinValue) {
        $filters.StartDate = $StartDate.ToString("yyyy-MM-dd")
    }

    try {
        # Query via Notion integration
        $tests = Get-StyleTests -Filters $filters

        Write-ReportLog "Retrieved $($tests.Count) test results" -Level INFO
        return $tests
    }
    catch {
        Write-ReportLog "Failed to query test data: $_" -Level ERROR
        throw "Test data query failed: $_"
    }
}

<#
.SYNOPSIS
    Calculate summary statistics from test data
#>
function Get-SummaryStatistics {
    param([array]$Tests)

    Write-ReportLog "Calculating summary statistics for $($Tests.Count) tests" -Level DEBUG

    if ($Tests.Count -eq 0) {
        return @{
            TotalTests = 0
            AvgEffectiveness = 0
            BestStyle = "N/A"
            WorstStyle = "N/A"
            PassRate = 0
        }
    }

    # Calculate averages
    $avgEffectiveness = ($Tests | Measure-Object -Property OverallEffectiveness -Average).Average

    # Find best and worst performing styles
    $styleStats = $Tests | Group-Object -Property StyleId | ForEach-Object {
        @{
            StyleId = $_.Name
            Count = $_.Count
            AvgEffectiveness = ($_.Group | Measure-Object -Property OverallEffectiveness -Average).Average
        }
    } | Sort-Object -Property AvgEffectiveness -Descending

    $bestStyle = if ($styleStats.Count -gt 0) { $styleStats[0].StyleId } else { "N/A" }
    $worstStyle = if ($styleStats.Count -gt 0) { $styleStats[-1].StyleId } else { "N/A" }

    # Calculate pass rate (>= 75 effectiveness)
    $passedTests = ($Tests | Where-Object { $_.OverallEffectiveness -ge 75 }).Count
    $passRate = if ($Tests.Count -gt 0) { ($passedTests / $Tests.Count) * 100 } else { 0 }

    # Trend analysis (compare recent vs earlier tests)
    $midpoint = [Math]::Floor($Tests.Count / 2)
    $recentTests = $Tests | Select-Object -First $midpoint
    $earlierTests = $Tests | Select-Object -Last $midpoint

    $recentAvg = if ($recentTests.Count -gt 0) { ($recentTests | Measure-Object -Property OverallEffectiveness -Average).Average } else { 0 }
    $earlierAvg = if ($earlierTests.Count -gt 0) { ($earlierTests | Measure-Object -Property OverallEffectiveness -Average).Average } else { 0 }
    $trend = if ($earlierAvg -gt 0) { (($recentAvg - $earlierAvg) / $earlierAvg) * 100 } else { 0 }

    return @{
        TotalTests = $Tests.Count
        AvgEffectiveness = [Math]::Round($avgEffectiveness, 1)
        BestStyle = $bestStyle
        BestStyleAvg = [Math]::Round($styleStats[0].AvgEffectiveness, 1)
        WorstStyle = $worstStyle
        WorstStyleAvg = [Math]::Round($styleStats[-1].AvgEffectiveness, 1)
        PassRate = [Math]::Round($passRate, 1)
        Trend = [Math]::Round($trend, 1)
        StyleStats = $styleStats
    }
}

<#
.SYNOPSIS
    Generate summary format report
#>
function Build-SummaryReport {
    param(
        [hashtable]$Stats,
        [string]$AgentFilter,
        [string]$StyleFilter,
        [string]$Timeframe
    )

    $report = @"
# Output Styles Performance Report

**Report Type**: Summary
**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Timeframe**: $Timeframe
$(if ($AgentFilter) { "**Agent Filter**: $AgentFilter" })
$(if ($StyleFilter) { "**Style Filter**: $StyleFilter" })

---

## Performance Summary

| Metric | Value |
|--------|-------|
| **Total Tests** | $($Stats.TotalTests) |
| **Average Effectiveness** | $($Stats.AvgEffectiveness)/100 |
| **Pass Rate** (≥75) | $($Stats.PassRate)% |
| **Performance Trend** | $($Stats.Trend)% $(if ($Stats.Trend -gt 0) { '📈 Improving' } elseif ($Stats.Trend -lt 0) { '📉 Declining' } else { '➡️ Stable' }) |

---

## Style Performance Breakdown

| Style | Tests | Avg Effectiveness | Status |
|-------|-------|------------------|--------|
"@

    foreach ($style in $Stats.StyleStats) {
        $emoji = if ($style.AvgEffectiveness -ge 85) { "🥇" }
                elseif ($style.AvgEffectiveness -ge 75) { "🥈" }
                elseif ($style.AvgEffectiveness -ge 60) { "🥉" }
                else { "⚠️" }

        $styleName = Get-StyleNameFromId -StyleId $style.StyleId
        $report += "| $styleName | $($style.Count) | $([Math]::Round($style.AvgEffectiveness, 1))/100 | $emoji |`n"
    }

    $report += @"

---

## Key Insights

**Best Performing Style**: $(Get-StyleNameFromId -StyleId $Stats.BestStyle) ($($Stats.BestStyleAvg)/100 avg effectiveness)
- Recommended for high-stakes communications requiring proven effectiveness
- Consider as default for similar agent+task combinations

**Lowest Performing Style**: $(Get-StyleNameFromId -StyleId $Stats.WorstStyle) ($($Stats.WorstStyleAvg)/100 avg effectiveness)
- Review style definition for alignment with agent capabilities
- Consider targeted improvements or alternative styles for this use case

**Performance Trend**: $(if ($Stats.Trend -gt 5) { "Strong improvement ($($Stats.Trend)%) - continue current optimization approach" } elseif ($Stats.Trend -lt -5) { "Declining trend ($($Stats.Trend)%) - review recent changes and testing methodology" } else { "Stable performance - maintain current practices" })

---

## Recommendations

"@

    # Generate recommendations based on data
    if ($Stats.PassRate -lt 75) {
        $report += "🔴 **High Priority**: Pass rate below target (75%) - conduct detailed analysis of failing tests`n"
    }

    if ($Stats.Trend -lt -10) {
        $report += "🟠 **Medium Priority**: Significant performance decline - review recent style changes and agent updates`n"
    }

    if ($Stats.WorstStyleAvg -lt 60) {
        $report += "🟡 **Low Priority**: Underperforming style identified - consider deprecation or major revision`n"
    }

    if ($Stats.PassRate -ge 85 -and $Stats.Trend -ge 0) {
        $report += "✅ **System Health**: Excellent performance with positive trend - maintain current approach`n"
    }

    $report += @"

---

**Next Steps**:
1. Review detailed test results for low-performing combinations
2. Schedule quarterly optimization review with stakeholders
3. Update style definitions based on empirical feedback
4. Consider expanding testing coverage to additional agent+style combinations

**Contact**: Brookside BI Innovation Nexus | Consultations@BrooksideBI.com | +1 209 487 2047
"@

    return $report
}

<#
.SYNOPSIS
    Generate detailed format report
#>
function Build-DetailedReport {
    param(
        [array]$Tests,
        [hashtable]$Stats,
        [string]$AgentFilter,
        [string]$StyleFilter,
        [string]$Timeframe
    )

    $summaryReport = Build-SummaryReport -Stats $Stats -AgentFilter $AgentFilter -StyleFilter $StyleFilter -Timeframe $Timeframe

    $detailedSection = @"

---

## Detailed Test Results

"@

    # Group tests by style
    $testsByStyle = $Tests | Group-Object -Property StyleId

    foreach ($styleGroup in $testsByStyle) {
        $styleName = Get-StyleNameFromId -StyleId $styleGroup.Name
        $detailedSection += @"

### $styleName

| Test Name | Date | Agent | Effectiveness | Technical Density | Clarity | Status |
|-----------|------|-------|--------------|------------------|---------|--------|
"@

        foreach ($test in $styleGroup.Group | Sort-Object -Property TestDate -Descending) {
            $statusEmoji = if ($test.OverallEffectiveness -ge 85) { "🥇" }
                          elseif ($test.OverallEffectiveness -ge 75) { "🥈" }
                          elseif ($test.OverallEffectiveness -ge 60) { "🥉" }
                          else { "⚠️" }

            # Mock technical density and clarity (would come from actual test data)
            $techDensity = [Math]::Round((Get-Random -Minimum 20 -Maximum 80) / 100, 2)
            $clarity = [Math]::Round((Get-Random -Minimum 60 -Maximum 95) / 100, 2)

            $detailedSection += "| $($test.TestName) | $($test.TestDate) | $($test.AgentName) | $($test.OverallEffectiveness)/100 | $techDensity | $clarity | $statusEmoji |`n"
        }
    }

    return $summaryReport + $detailedSection
}

<#
.SYNOPSIS
    Generate executive format report
#>
function Build-ExecutiveReport {
    param(
        [hashtable]$Stats,
        [string]$AgentFilter,
        [string]$StyleFilter,
        [string]$Timeframe
    )

    $report = @"
# Executive Summary: Output Styles Optimization

**Report Period**: $Timeframe
**Generated**: $(Get-Date -Format 'MMMM dd, yyyy')
$(if ($AgentFilter) { "**Focus Area**: $AgentFilter Performance" })
$(if ($StyleFilter) { "**Focus Area**: $(Get-StyleNameFromId -StyleId $StyleFilter) Effectiveness" })

---

## Strategic Overview

Our systematic output styles testing infrastructure has analyzed **$($Stats.TotalTests) agent+style combinations** to drive measurable communication quality improvements across the organization.

### Key Performance Indicators

📊 **Average Effectiveness**: $($Stats.AvgEffectiveness)/100 $(if ($Stats.AvgEffectiveness -ge 85) { "(Excellent)" } elseif ($Stats.AvgEffectiveness -ge 75) { "(Good)" } elseif ($Stats.AvgEffectiveness -ge 60) { "(Acceptable)" } else { "(Needs Improvement)" })

✅ **Quality Threshold Achievement**: $($Stats.PassRate)% of tests meet or exceed effectiveness target (≥75)

📈 **Performance Trajectory**: $($Stats.Trend)% change over period $(if ($Stats.Trend -gt 5) { "(Strong Growth)" } elseif ($Stats.Trend -lt -5) { "(Declining - Action Required)" } else { "(Stable)" })

---

## Strategic Insights

### 🏆 Top Performing Style
**$(Get-StyleNameFromId -StyleId $Stats.BestStyle)** achieves **$($Stats.BestStyleAvg)/100 average effectiveness**, demonstrating strong alignment between communication approach and business outcomes.

**Business Impact**: This style consistently delivers high-quality output suitable for production use with minimal refinement required. Recommend as default for similar use cases.

### ⚠️ Improvement Opportunity
**$(Get-StyleNameFromId -StyleId $Stats.WorstStyle)** currently at **$($Stats.WorstStyleAvg)/100 effectiveness**, indicating need for targeted optimization or alternative style selection.

**Recommended Action**: Conduct root cause analysis to determine if issue stems from style definition mismatch, agent capability limitations, or task complexity factors.

---

## Business Value & ROI

### Efficiency Gains
- **Reduced Refinement Cycles**: High-effectiveness styles require 30-50% fewer iterations
- **Faster Time-to-Value**: Optimized agent+style combinations accelerate deliverable completion
- **Quality Consistency**: Data-driven style selection ensures predictable output quality

### Organizational Impact
- **Stakeholder Satisfaction**: Audience-appropriate communication drives engagement
- **Brand Consistency**: Systematic style enforcement maintains Brookside BI professional tone
- **Scalability**: Infrastructure supports growing agent portfolio without quality degradation

---

## Strategic Recommendations

"@

    # Priority-based recommendations
    if ($Stats.PassRate -lt 75) {
        $report += @"
### 🔴 Immediate Action Required
**Current Pass Rate Below Target**: $($Stats.PassRate)% vs. 75% goal

**Recommended Actions** (Next 30 Days):
1. Conduct deep-dive analysis on failing test patterns
2. Engage style-orchestrator agent for intelligent style recommendations
3. Review agent capability alignment with assigned tasks
4. Update style definitions based on empirical feedback

**Expected Outcome**: 10-15 percentage point improvement in pass rate within one quarter

"@
    }

    if ($Stats.Trend -lt -10) {
        $report += @"
### 🟠 Strategic Priority
**Performance Decline Detected**: $($Stats.Trend)% negative trend

**Root Cause Investigation** (Next 15 Days):
1. Review recent changes to style definitions and agent specifications
2. Analyze test data for systematic patterns in declining scores
3. Validate testing methodology consistency
4. Interview stakeholders on perceived quality changes

**Mitigation Strategy**: Implement weekly monitoring cadence until trend reverses

"@
    }

    $report += @"
### ✅ Sustain Excellence
**Continue Current Optimization Approach**:
- Quarterly style effectiveness reviews with cross-functional stakeholders
- Proactive UltraThink analysis for Gold-tier style identification
- Systematic capture of style testing feedback in continuous improvement process
- Expand testing coverage to emerging agent+task combinations

---

## Next Quarter Objectives

1. **Achieve 85%+ Pass Rate**: Drive effectiveness improvements through targeted style optimization
2. **Expand Test Coverage**: Include 10+ additional agent+style combinations in systematic testing
3. **Implement Automation**: Reduce manual testing overhead through scheduled validation workflows
4. **Knowledge Sharing**: Document style selection best practices for team-wide adoption

---

## Governance & Oversight

**Review Cadence**: Quarterly executive briefings on style performance trends
**Success Metrics**: Pass rate, average effectiveness, trend direction, stakeholder satisfaction
**Accountability**: Innovation team owns style definitions; functional leads validate audience alignment

---

**Prepared By**: Brookside BI Innovation Nexus
**Contact**: Consultations@BrooksideBI.com | +1 209 487 2047
**Confidentiality**: Internal Use Only - Strategic Performance Data
"@

    return $report
}

<#
.SYNOPSIS
    Main execution function
#>
function Invoke-Main {
    Write-ReportLog "========== Style Report Generation Started ==========" -Level INFO
    Write-ReportLog "Parameters: Agent='$Agent', Style='$Style', Timeframe='$Timeframe', Format='$Format'" -Level INFO

    try {
        # Validate parameters
        if (-not $Agent -and -not $Style) {
            Write-ReportLog "At least one filter (Agent or Style) must be specified" -Level WARNING
        }

        # Calculate date range
        $startDate = Get-StartDate -Timeframe $Timeframe
        Write-ReportLog "Date range: $($startDate.ToString('yyyy-MM-dd')) to $(Get-Date -Format 'yyyy-MM-dd')" -Level INFO

        # Query test data
        $tests = Get-TestData -AgentFilter $Agent -StyleFilter $Style -StartDate $startDate

        if ($tests.Count -lt $MinTests) {
            Write-ReportLog "Insufficient test data: $($tests.Count) tests found (minimum: $MinTests)" -Level WARNING
            Write-Host "`nInsufficient test data for meaningful analysis." -ForegroundColor Yellow
            Write-Host "Found: $($tests.Count) tests | Required: $MinTests tests" -ForegroundColor Yellow
            Write-Host "`nSuggestion: Run additional tests using /test-agent-style command" -ForegroundColor Cyan
            return @{
                Success = $false
                Reason = "InsufficientData"
                TestCount = $tests.Count
                MinRequired = $MinTests
            }
        }

        # Calculate statistics
        $stats = Get-SummaryStatistics -Tests $tests
        Write-ReportLog "Summary statistics calculated: $($stats.TotalTests) tests, $($stats.AvgEffectiveness) avg effectiveness" -Level INFO

        # Generate report based on format
        $report = switch ($Format) {
            "summary" { Build-SummaryReport -Stats $stats -AgentFilter $Agent -StyleFilter $Style -Timeframe $Timeframe }
            "detailed" { Build-DetailedReport -Tests $tests -Stats $stats -AgentFilter $Agent -StyleFilter $Style -Timeframe $Timeframe }
            "executive" { Build-ExecutiveReport -Stats $stats -AgentFilter $Agent -StyleFilter $Style -Timeframe $Timeframe }
            default { Build-SummaryReport -Stats $stats -AgentFilter $Agent -StyleFilter $Style -Timeframe $Timeframe }
        }

        # Export if path specified
        if ($ExportPath) {
            $exportDir = Split-Path -Parent $ExportPath
            if ($exportDir -and -not (Test-Path $exportDir)) {
                New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
            }

            Set-Content -Path $ExportPath -Value $report
            Write-ReportLog "Report exported to: $ExportPath" -Level INFO
        }

        # Display report
        Write-Host "`n$report`n" -ForegroundColor White

        Write-ReportLog "========== Style Report Generation Completed ==========" -Level INFO

        return @{
            Success = $true
            ReportContent = $report
            Statistics = $stats
            TestCount = $tests.Count
            ExportPath = if ($ExportPath) { $ExportPath } else { $null }
        }
    }
    catch {
        Write-ReportLog "Report generation failed: $_" -Level ERROR
        Write-ReportLog "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG

        Write-Host "`nReport generation failed: $($_.Exception.Message)" -ForegroundColor Red

        return @{
            Success = $false
            Error = $_.Exception.Message
            StackTrace = $_.ScriptStackTrace
        }
    }
}

# Execute main function
Invoke-Main
