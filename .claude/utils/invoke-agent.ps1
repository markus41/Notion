<#
.SYNOPSIS
    Agent Invocation Wrapper - Execute agents with output style testing and metrics calculation

.DESCRIPTION
    Establish intelligent agent invocation layer that captures agent output, calculates behavioral
    metrics, and synchronizes results to Notion Agent Style Tests database. Designed for organizations
    scaling agent communication optimization through systematic testing and data-driven style selection.

.PARAMETER AgentName
    Name of agent to invoke (with or without @ prefix)

.PARAMETER StyleId
    Output style identifier (technical-implementer, strategic-advisor, visual-architect,
    interactive-teacher, compliance-auditor) or "?" to test all styles

.PARAMETER TaskDescription
    Custom task for agent to perform. If omitted, uses default task from default-tasks.json

.PARAMETER Interactive
    Enable interactive mode with real-time feedback prompts during test execution

.PARAMETER UltraThink
    Enable deep analysis with extended reasoning and tier classification

.PARAMETER Sync
    Immediately sync results to Notion (default: queue for async processing)

.PARAMETER MetricsOnly
    Skip full output capture, return only calculated metrics

.EXAMPLE
    .\invoke-agent.ps1 -AgentName "@cost-analyst" -StyleId "strategic-advisor"

.EXAMPLE
    .\invoke-agent.ps1 -AgentName "database-architect" -StyleId "?" -UltraThink -Sync

.EXAMPLE
    .\invoke-agent.ps1 -AgentName "@viability-assessor" -StyleId "technical-implementer" -TaskDescription "Assess AI cost platform" -Interactive

.NOTES
    Author: Brookside BI Innovation Nexus
    Purpose: Agent testing infrastructure for output styles optimization
    Best for: Teams requiring empirical style effectiveness data with minimal manual overhead
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$AgentName,

    [Parameter(Mandatory = $true)]
    [string]$StyleId,

    [Parameter(Mandatory = $false)]
    [string]$TaskDescription = "",

    [Parameter(Mandatory = $false)]
    [switch]$Interactive,

    [Parameter(Mandatory = $false)]
    [switch]$UltraThink,

    [Parameter(Mandatory = $false)]
    [switch]$Sync,

    [Parameter(Mandatory = $false)]
    [switch]$MetricsOnly
)

# Script configuration
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path $ScriptDir "..\logs\invoke-agent.log"
$DefaultTasksFile = Join-Path $ScriptDir "default-tasks.json"
$StylesDir = Join-Path $ScriptDir "..\styles"

# Import utilities
. (Join-Path $ScriptDir "style-metrics.ps1")
. (Join-Path $ScriptDir "notion-style-db.ps1")

# Initialize logging
function Write-InvokeLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [InvokeAgent] [$Level] $Message"

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
    Normalize agent name format
#>
function Get-NormalizedAgentName {
    param([string]$Name)

    # Ensure @ prefix
    if (-not $Name.StartsWith("@")) {
        return "@$Name"
    }
    return $Name
}

<#
.SYNOPSIS
    Load default task for agent from default-tasks.json
#>
function Get-DefaultTask {
    param([string]$AgentName)

    Write-InvokeLog "Loading default task for $AgentName" -Level DEBUG

    if (-not (Test-Path $DefaultTasksFile)) {
        Write-InvokeLog "Default tasks file not found: $DefaultTasksFile" -Level WARNING
        return "Perform your primary specialized function with comprehensive output"
    }

    try {
        $tasks = Get-Content $DefaultTasksFile -Raw | ConvertFrom-Json -AsHashtable

        if ($tasks.ContainsKey($AgentName)) {
            Write-InvokeLog "Found default task for $AgentName" -Level DEBUG
            return $tasks[$AgentName]
        }
        else {
            Write-InvokeLog "No default task found for $AgentName, using generic task" -Level WARNING
            return "Perform your primary specialized function with comprehensive output"
        }
    }
    catch {
        Write-InvokeLog "Failed to load default tasks: $_" -Level ERROR
        return "Perform your primary specialized function with comprehensive output"
    }
}

<#
.SYNOPSIS
    Load style definition from .claude/styles/[style-id].md
#>
function Get-StyleDefinition {
    param([string]$StyleId)

    Write-InvokeLog "Loading style definition: $StyleId" -Level DEBUG

    $styleFile = Join-Path $StylesDir "$StyleId.md"

    if (-not (Test-Path $styleFile)) {
        Write-InvokeLog "Style file not found: $styleFile" -Level ERROR
        throw "Style definition not found: $StyleId"
    }

    try {
        $content = Get-Content $styleFile -Raw
        Write-InvokeLog "Successfully loaded style definition: $StyleId" -Level DEBUG
        return $content
    }
    catch {
        Write-InvokeLog "Failed to load style definition: $_" -Level ERROR
        throw "Failed to load style definition: $StyleId"
    }
}

<#
.SYNOPSIS
    Build prompt for agent invocation with style instructions
#>
function Build-AgentPrompt {
    param(
        [string]$AgentName,
        [string]$StyleDefinition,
        [string]$TaskDescription,
        [bool]$EnableUltraThink,
        [bool]$EnableInteractive
    )

    Write-InvokeLog "Building agent prompt for $AgentName" -Level DEBUG

    $prompt = @"
You are executing in OUTPUT STYLE TESTING MODE.

## Agent Being Tested
$AgentName

## Task to Perform
$TaskDescription

## Output Style Requirements
$StyleDefinition

## Testing Parameters
"@

    if ($EnableUltraThink) {
        $prompt += @"

- **UltraThink Mode**: ENABLED
  - Provide extended reasoning with comprehensive justification
  - Include tier classification analysis (Gold/Silver/Bronze/Needs Improvement)
  - Evaluate semantic appropriateness, audience alignment, brand consistency, practical effectiveness, and innovation potential
"@
    }

    if ($EnableInteractive) {
        $prompt += @"

- **Interactive Mode**: ENABLED
  - Pause for user feedback at key decision points
  - Request clarification when requirements are ambiguous
  - Provide real-time progress updates
"@
    }

    $prompt += @"


## Important Instructions
1. Apply the specified output style consistently throughout your response
2. Complete the task as if you were the $AgentName agent
3. Generate output that would be typical for this agent performing this task
4. Do NOT reference this testing context in your output
5. Produce natural, production-quality output suitable for the specified style and audience

Begin your response now:
"@

    return $prompt
}

<#
.SYNOPSIS
    Invoke agent via Claude Code Task tool (simulation for testing)
#>
function Invoke-AgentWithStyle {
    param(
        [string]$AgentName,
        [string]$Prompt,
        [int]$TimeoutSeconds = 300
    )

    Write-InvokeLog "Invoking agent: $AgentName" -Level INFO

    # NOTE: In production, this would use the Task tool through Claude Code API
    # For now, this is a placeholder that simulates agent invocation
    # Actual implementation requires integration with Claude Code's Task tool

    # Placeholder simulation
    $startTime = Get-Date

    Write-InvokeLog "PLACEHOLDER: Actual agent invocation would occur here via Task tool" -Level WARNING
    Write-InvokeLog "Task tool parameters: subagent_type='$AgentName', prompt='$Prompt'" -Level DEBUG

    # Simulate processing time
    Start-Sleep -Milliseconds 500

    # Return mock output for testing infrastructure
    $mockOutput = @"
# Strategic Cost Analysis: Q4 Software Spending Optimization

## Executive Summary

Our comprehensive analysis of Q4 software expenditures reveals significant optimization opportunities totaling `$47,850 in potential annual savings through strategic consolidation and Microsoft ecosystem alignment.

## Key Findings

**Current Spending Profile**:
- Total Q4 Software Spend: `$125,430
- Number of Active Licenses: 247
- Average Cost per User: `$508/year
- Microsoft Services: 62% of budget
- Third-party Tools: 38% of budget

**Optimization Opportunities**:
1. **Duplicate Functionality**: 12 tools with overlapping capabilities (`$23,400 potential savings)
2. **Unused Licenses**: 34 inactive accounts across 8 platforms (`$15,750 waste)
3. **Microsoft Alternatives**: 5 third-party tools replaceable with M365/Azure services (`$8,700 savings)

## Strategic Recommendations

### Immediate Actions (Next 30 Days)
- Consolidate project management tools: Migrate from Asana + Monday.com to Microsoft Planner/Project (`$8,400/year savings)
- Deactivate unused licenses in Salesforce, Adobe Creative Cloud, Slack Premium (34 accounts, `$15,750/year recovery)
- Cancel redundant storage: Box.com overlap with OneDrive/SharePoint (`$3,600/year savings)

### Medium-term Initiatives (60-90 Days)
- Replace third-party BI tools with Power BI Premium capacity optimization
- Migrate collaboration workflows from Atlassian suite to Microsoft 365 ecosystem
- Consolidate cloud infrastructure: Review multi-cloud strategy vs. Azure-first approach

## Financial Impact

| Initiative | Annual Savings | Implementation Effort | Risk Level |
|-----------|---------------|----------------------|------------|
| License cleanup | `$15,750 | Low (1-2 weeks) | Minimal |
| Tool consolidation | `$23,400 | Medium (4-6 weeks) | Moderate |
| Microsoft alignment | `$8,700 | Medium (6-8 weeks) | Low |
| **Total** | **`$47,850** | **12-16 weeks** | **Manageable** |

## Implementation Roadmap

**Phase 1** (Weeks 1-4): License audit and deactivation
- Identify all inactive accounts across platforms
- Coordinate with HR for offboarding verification
- Execute license downgrades and cancellations
- Validate cost reductions in invoices

**Phase 2** (Weeks 5-10): Tool consolidation
- Migrate project management to Microsoft ecosystem
- Archive historical data from legacy platforms
- Train teams on consolidated toolset
- Monitor adoption and address resistance

**Phase 3** (Weeks 11-16): Microsoft ecosystem optimization
- Replace third-party services with Azure/M365 alternatives
- Optimize licensing tiers based on actual usage patterns
- Establish governance policies to prevent future sprawl
- Implement quarterly cost review process

## Risk Mitigation

**User Adoption Concerns**: Provide comprehensive training and change management support
**Data Migration Complexity**: Pilot migrations with non-critical data first
**Vendor Lock-in**: Maintain strategic relationships while optimizing costs
**Service Disruption**: Execute migrations during maintenance windows with rollback plans

## Governance Framework

Establish structure and rules for sustainable cost management:
- Quarterly software spend reviews with stakeholder engagement
- Approval workflow for new tool purchases (Microsoft-first evaluation)
- Automated license utilization monitoring with alerts
- Annual vendor contract renegotiation strategy

---

**Next Steps**: Schedule stakeholder alignment meeting to approve Phase 1 execution (target: within 7 business days)

**Contact**: Cost Optimization Team | Consultations@BrooksideBI.com | +1 209 487 2047
"@

    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds

    Write-InvokeLog "Agent invocation completed in $duration ms" -Level INFO

    return @{
        Success = $true
        Output = $mockOutput
        DurationMs = $duration
        StartTime = $startTime
        EndTime = $endTime
    }
}

<#
.SYNOPSIS
    Process test results and calculate metrics
#>
function Process-TestResults {
    param(
        [hashtable]$InvocationResult,
        [string]$AgentName,
        [string]$StyleId,
        [string]$TaskDescription,
        [bool]$EnableUltraThink
    )

    Write-InvokeLog "Processing test results for $AgentName + $StyleId" -Level INFO

    try {
        # Calculate comprehensive metrics
        $metrics = Get-ComprehensiveMetrics -Text $InvocationResult.Output

        # Add additional metadata
        $metrics.GenerationTimeMs = $InvocationResult.DurationMs

        # Build test data structure
        $testData = @{
            AgentName = $AgentName
            StyleId = $StyleId
            TaskDescription = $TaskDescription
            TestOutput = $InvocationResult.Output
            Metrics = $metrics
            StartTime = $InvocationResult.StartTime
            EndTime = $InvocationResult.EndTime
        }

        # Add UltraThink analysis if enabled
        if ($EnableUltraThink) {
            Write-InvokeLog "Performing UltraThink tier classification" -Level INFO
            $tierAnalysis = Get-UltraThinkTierClassification -Metrics $metrics -Output $InvocationResult.Output
            $testData.UltraThinkTier = $tierAnalysis.Tier
            $testData.TierJustification = $tierAnalysis.Justification
            $testData.Notes = $tierAnalysis.DetailedAnalysis
        }

        Write-InvokeLog "Successfully processed test results" -Level INFO
        return $testData

    }
    catch {
        Write-InvokeLog "Failed to process test results: $_" -Level ERROR
        throw "Test results processing failed: $_"
    }
}

<#
.SYNOPSIS
    Perform UltraThink tier classification analysis
#>
function Get-UltraThinkTierClassification {
    param(
        [hashtable]$Metrics,
        [string]$Output
    )

    Write-InvokeLog "Calculating UltraThink tier classification" -Level DEBUG

    # Calculate tier score (weighted average)
    $effectiveness = $Metrics.OverallEffectiveness / 100
    $technicalBalance = 1 - [Math]::Abs(0.5 - $Metrics.TechnicalDensity)  # Optimal at 0.5
    $clarityScore = $Metrics.ClarityScore
    $formalityBalance = 1 - [Math]::Abs(0.6 - $Metrics.FormalityScore)  # Optimal at 0.6 for business

    $tierScore = (0.40 * $effectiveness) +
                 (0.25 * $clarityScore) +
                 (0.20 * $technicalBalance) +
                 (0.15 * $formalityBalance)

    # Determine tier
    $tier = if ($tierScore -ge 0.90) { "Gold" }
            elseif ($tierScore -ge 0.75) { "Silver" }
            elseif ($tierScore -ge 0.60) { "Bronze" }
            else { "Needs Improvement" }

    # Build justification
    $justification = @"
Tier Score: $([Math]::Round($tierScore * 100))/100
- Effectiveness: $($Metrics.OverallEffectiveness)/100
- Clarity: $([Math]::Round($clarityScore * 100))%
- Technical Balance: $([Math]::Round($technicalBalance * 100))%
- Formality Balance: $([Math]::Round($formalityBalance * 100))%
"@

    # Detailed analysis
    $detailedAnalysis = @"
## UltraThink Deep Analysis

### Semantic Appropriateness ($([Math]::Round($effectiveness * 100))/100)
Content demonstrates $(if ($effectiveness -ge 0.8) { "strong" } elseif ($effectiveness -ge 0.6) { "acceptable" } else { "limited" }) alignment with task requirements and audience expectations.

### Audience Alignment ($([Math]::Round($Metrics.AudienceAppropriateness * 100))/100)
Tone, complexity, and terminology are $(if ($Metrics.AudienceAppropriateness -ge 0.8) { "well-suited" } elseif ($Metrics.AudienceAppropriateness -ge 0.6) { "adequately matched" } else { "poorly aligned" }) for target audience.

### Brand Consistency
Output $(if ($Metrics.FormalityScore -ge 0.5 -and $Metrics.FormalityScore -le 0.75) { "maintains" } else { "deviates from" }) Brookside BI professional tone and solution-focused language patterns.

### Practical Effectiveness
Content provides $(if ($Metrics.GoalAchievement -ge 0.8) { "highly actionable" } elseif ($Metrics.GoalAchievement -ge 0.6) { "moderately useful" } else { "limited practical" }) guidance with clear next steps.

### Innovation Potential
Approach demonstrates $(if ($Metrics.VisualElementsCount -gt 3) { "strong" } elseif ($Metrics.VisualElementsCount -gt 1) { "moderate" } else { "minimal" }) use of visual elements and structural innovation.
"@

    return @{
        Tier = $tier
        TierScore = $tierScore
        Justification = $justification
        DetailedAnalysis = $detailedAnalysis
    }
}

<#
.SYNOPSIS
    Sync test results to Notion or queue for async processing
#>
function Sync-TestResults {
    param(
        [hashtable]$TestData,
        [bool]$ImmediateSync
    )

    Write-InvokeLog "Syncing test results to Notion (immediate: $ImmediateSync)" -Level INFO

    try {
        if ($ImmediateSync) {
            # Direct Notion sync via MCP
            $result = New-StyleTestEntry -TestData $TestData

            if ($result.Success) {
                Write-InvokeLog "Successfully synced to Notion: $($result.PageUrl)" -Level INFO
                return @{
                    Success = $true
                    Method = "Immediate"
                    PageUrl = $result.PageUrl
                    TestName = $result.TestName
                }
            }
            else {
                throw "Notion sync failed: $($result.Error)"
            }
        }
        else {
            # Queue for async processing
            $queueFile = Join-Path $ScriptDir "..\data\notion-sync-queue.jsonl"
            $queueDir = Split-Path -Parent $queueFile

            if (-not (Test-Path $queueDir)) {
                New-Item -ItemType Directory -Path $queueDir -Force | Out-Null
            }

            $queueEntry = @{
                Type = "StyleTest"
                Timestamp = (Get-Date).ToString("o")
                Data = $TestData
            } | ConvertTo-Json -Compress -Depth 10

            Add-Content -Path $queueFile -Value $queueEntry
            Write-InvokeLog "Queued test results for async processing" -Level INFO

            return @{
                Success = $true
                Method = "Queued"
                QueueFile = $queueFile
            }
        }
    }
    catch {
        Write-InvokeLog "Failed to sync test results: $_" -Level ERROR
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Main execution function
#>
function Invoke-Main {
    Write-InvokeLog "========== Agent Invocation Started ==========" -Level INFO
    Write-InvokeLog "Agent: $AgentName | Style: $StyleId" -Level INFO

    try {
        # Normalize agent name
        $normalizedAgent = Get-NormalizedAgentName -Name $AgentName
        Write-InvokeLog "Normalized agent name: $normalizedAgent" -Level DEBUG

        # Determine task
        $task = if ($TaskDescription) { $TaskDescription } else { Get-DefaultTask -AgentName $normalizedAgent }
        Write-InvokeLog "Task: $task" -Level INFO

        # Handle "test all styles" scenario
        $stylesToTest = if ($StyleId -eq "?") {
            @("technical-implementer", "strategic-advisor", "visual-architect", "interactive-teacher", "compliance-auditor")
        }
        else {
            @($StyleId)
        }

        Write-InvokeLog "Testing $($stylesToTest.Count) style(s)" -Level INFO

        $allResults = @()

        foreach ($style in $stylesToTest) {
            Write-InvokeLog "--- Testing style: $style ---" -Level INFO

            # Load style definition
            $styleDefinition = Get-StyleDefinition -StyleId $style

            # Build prompt
            $prompt = Build-AgentPrompt -AgentName $normalizedAgent `
                                       -StyleDefinition $styleDefinition `
                                       -TaskDescription $task `
                                       -EnableUltraThink $UltraThink.IsPresent `
                                       -EnableInteractive $Interactive.IsPresent

            # Invoke agent
            $invocationResult = Invoke-AgentWithStyle -AgentName $normalizedAgent `
                                                      -Prompt $prompt `
                                                      -TimeoutSeconds 300

            if (-not $invocationResult.Success) {
                Write-InvokeLog "Agent invocation failed for style $style" -Level ERROR
                continue
            }

            # Process results
            $testData = Process-TestResults -InvocationResult $invocationResult `
                                           -AgentName $normalizedAgent `
                                           -StyleId $style `
                                           -TaskDescription $task `
                                           -EnableUltraThink $UltraThink.IsPresent

            # Sync to Notion (unless metrics-only mode)
            if (-not $MetricsOnly.IsPresent) {
                $syncResult = Sync-TestResults -TestData $testData -ImmediateSync $Sync.IsPresent
                $testData.SyncResult = $syncResult
            }

            $allResults += $testData
        }

        Write-InvokeLog "========== Agent Invocation Completed ==========" -Level INFO
        Write-InvokeLog "Total tests executed: $($allResults.Count)" -Level INFO

        # Return results
        return @{
            Success = $true
            TestCount = $allResults.Count
            Results = $allResults
        }
    }
    catch {
        Write-InvokeLog "Agent invocation failed: $_" -Level ERROR
        Write-InvokeLog "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG

        return @{
            Success = $false
            Error = $_.Exception.Message
            StackTrace = $_.ScriptStackTrace
        }
    }
}

# Execute main function and return results
Invoke-Main
