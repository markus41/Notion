#Requires -Version 5.1
<#
.SYNOPSIS
    Automatic Agent Activity Logging Hook for Brookside BI Innovation Nexus

.DESCRIPTION
    This hook script automatically captures agent work and logs it to a 3-tier
    tracking system when agents complete their responses:

    - Tier 2 (Markdown): Immediate append to AGENT_ACTIVITY_LOG.md
    - Tier 3 (JSON): Immediate update to agent-state.json
    - Tier 1 (Notion): Queued for async sync via Notion MCP

    The queue-based Notion sync provides resilience and leverages existing
    Notion MCP authentication without permission issues.

    Designed for: Organizations requiring transparent AI agent activity tracking
    to establish workflow continuity and enable data-driven productivity insights.

.NOTES
    Author: Brookside BI - Claude Code Integration
    Version: 1.0.0
    Last Modified: 2025-10-22

.PARAMETER ToolName
    The name of the tool that was invoked (from Claude Code hook context)

.PARAMETER ToolParameters
    The parameters passed to the tool (JSON format)

.PARAMETER SessionContext
    Full session context from Claude Code (optional, for enhanced parsing)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ToolName = $env:CLAUDE_TOOL_NAME,

    [Parameter(Mandatory = $false)]
    [string]$ToolParameters = $env:CLAUDE_TOOL_PARAMS,

    [Parameter(Mandatory = $false)]
    [string]$SessionContext = $env:CLAUDE_SESSION_CONTEXT
)

# Configuration
$script:Config = @{
    MinDurationSeconds = 120  # Only log work that takes >2 minutes
    LogFile = Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "logs") "auto-activity-hook.log"
    StateFile = Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "data") "agent-state.json"
    ActivityLogFile = Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "logs") "AGENT_ACTIVITY_LOG.md"
    QueueFile = Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "data") "notion-sync-queue.jsonl"
    FilteredAgents = @(
        "@ideas-capture",
        "@research-coordinator",
        "@build-architect",
        "@build-architect-v2",
        "@code-generator",
        "@deployment-orchestrator",
        "@cost-analyst",
        "@knowledge-curator",
        "@archive-manager",
        "@schema-manager",
        "@integration-specialist",
        "@workflow-router",
        "@viability-assessor",
        "@orchestration-coordinator",
        "@market-researcher",
        "@technical-analyst",
        "@cost-feasibility-analyst",
        "@risk-assessor"
    )
}

# Initialize logging
function Write-HookLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Ensure log directory exists
    $logDir = Split-Path -Parent $script:Config.LogFile
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    Add-Content -Path $script:Config.LogFile -Value $logMessage

    # Also write to console for debugging
    if ($VerbosePreference -eq "Continue" -or $Level -eq "ERROR") {
        Write-Host $logMessage
    }
}

# Parse agent information from tool parameters
function Get-AgentContext {
    param(
        [Parameter(Mandatory = $false)]
        [string]$ToolName,

        [Parameter(Mandatory = $false)]
        [string]$ToolParams
    )

    Write-HookLog "Parsing agent context from tool: $ToolName" -Level DEBUG

    # Default context
    $context = @{
        AgentName = $null
        IsAgentInvocation = $false
        StartTime = Get-Date
        WorkDescription = $null
    }

    # Check if this is a Task tool invocation (agent delegation)
    if ($ToolName -eq "Task") {
        try {
            $params = $ToolParams | ConvertFrom-Json -ErrorAction Stop

            if ($params.subagent_type) {
                $context.AgentName = "@$($params.subagent_type)"
                $context.IsAgentInvocation = $true
                $context.WorkDescription = $params.description

                Write-HookLog "Detected agent invocation: $($context.AgentName)" -Level INFO
            }
        }
        catch {
            Write-HookLog "Failed to parse Task tool parameters: $_" -Level WARNING
        }
    }

    return $context
}

# Check if agent should be logged based on filtering rules
function Test-ShouldLogAgent {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AgentContext
    )

    # Rule 1: Must be an agent invocation
    if (-not $AgentContext.IsAgentInvocation) {
        Write-HookLog "Skipping: Not an agent invocation" -Level DEBUG
        return $false
    }

    # Rule 2: Must be in filtered agents list
    if ($AgentContext.AgentName -notin $script:Config.FilteredAgents) {
        Write-HookLog "Skipping: Agent $($AgentContext.AgentName) not in filtered list" -Level DEBUG
        return $false
    }

    # Rule 3: Check for duplicate logging in current session
    if (Test-AlreadyLogged -AgentName $AgentContext.AgentName) {
        Write-HookLog "Skipping: Agent $($AgentContext.AgentName) already logged in this session" -Level DEBUG
        return $false
    }

    Write-HookLog "Agent $($AgentContext.AgentName) passes all filtering rules" -Level INFO
    return $true
}

# Check if agent was already logged in current session
function Test-AlreadyLogged {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentName
    )

    # Read current state file
    if (-not (Test-Path $script:Config.StateFile)) {
        return $false
    }

    try {
        $state = Get-Content $script:Config.StateFile -Raw | ConvertFrom-Json

        # Check active sessions for this agent
        $activeSession = $state.activeSessions | Where-Object { $_.agentName -eq $AgentName }

        if ($activeSession) {
            # Check if session started within last 5 minutes (likely same session)
            $sessionStart = [DateTime]::Parse($activeSession.startTime)
            $elapsed = (Get-Date) - $sessionStart

            if ($elapsed.TotalMinutes -lt 5) {
                return $true
            }
        }

        return $false
    }
    catch {
        Write-HookLog "Error checking duplicate logging: $_" -Level WARNING
        return $false
    }
}

# Update Markdown activity log with new session entry
function Update-MarkdownLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SessionId,

        [Parameter(Mandatory = $true)]
        [hashtable]$AgentContext
    )

    Write-HookLog "Updating Markdown log for: $SessionId" -Level DEBUG

    # Ensure log directory exists
    $logDir = Split-Path -Parent $script:Config.ActivityLogFile
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    # Build markdown entry
    $entry = @"

---

### $SessionId

**Agent**: $($AgentContext.AgentName)
**Status**: 🟢 In Progress (Auto-logged)
**Started**: $($AgentContext.StartTime.ToString('yyyy-MM-dd HH:mm:ss UTC'))

**Work Description**: $($AgentContext.WorkDescription)

**Trigger**: Automatic hook detection
**Next Steps**: Work in progress - agent completing assigned task

"@

    try {
        Add-Content -Path $script:Config.ActivityLogFile -Value $entry -ErrorAction Stop
        Write-HookLog "Successfully updated Markdown log" -Level INFO
        return $true
    }
    catch {
        Write-HookLog "Failed to update Markdown log: $_" -Level WARNING
        return $false
    }
}

# Update JSON state file with new active session
function Update-JsonState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SessionId,

        [Parameter(Mandatory = $true)]
        [hashtable]$AgentContext
    )

    Write-HookLog "Updating JSON state for: $SessionId" -Level DEBUG

    try {
        # Ensure state directory exists
        $stateDir = Split-Path -Parent $script:Config.StateFile
        if (-not (Test-Path $stateDir)) {
            New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
        }

        # Read existing state or create new
        if (Test-Path $script:Config.StateFile) {
            $state = Get-Content $script:Config.StateFile -Raw | ConvertFrom-Json
        }
        else {
            $state = @{
                lastUpdated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
                activeSessions = @()
                completedSessions = @()
                handoffQueue = @()
                statistics = @{
                    totalSessions = 0
                    completedSessions = 0
                    activeSessions = 0
                    blockedSessions = 0
                    handedOffSessions = 0
                    successRate = 1.0
                    avgDurationMinutes = 0
                    totalWorkDurationMinutes = 0
                    totalDeliverablesCreated = 0
                    totalLinesGenerated = 0
                }
            }
        }

        # Build new session entry
        $newSession = @{
            sessionId = $SessionId
            agentName = $AgentContext.AgentName
            status = "in-progress"
            startTime = $AgentContext.StartTime.ToString('yyyy-MM-ddTHH:mm:ssZ')
            workDescription = $AgentContext.WorkDescription
            triggerSource = "automatic-hook"
            deliverables = @{
                count = 0
            }
            nextSteps = @(
                "Work in progress - agent completing assigned task"
            )
            blockers = @()
        }

        # Add to active sessions
        $state.activeSessions += $newSession

        # Update statistics
        $state.statistics.totalSessions++
        $state.statistics.activeSessions = $state.activeSessions.Count
        $state.lastUpdated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")

        # Write back to file
        $state | ConvertTo-Json -Depth 10 | Set-Content $script:Config.StateFile -ErrorAction Stop

        Write-HookLog "Successfully updated JSON state" -Level INFO
        return $true
    }
    catch {
        Write-HookLog "Failed to update JSON state: $_" -Level WARNING
        return $false
    }
}

# Queue Notion sync operation for later processing via Notion MCP
function Queue-NotionSync {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SessionId,

        [Parameter(Mandatory = $true)]
        [hashtable]$AgentContext
    )

    Write-HookLog "Queueing Notion sync for: $SessionId" -Level DEBUG

    try {
        # Queue file path
        $queueFile = Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "data") "notion-sync-queue.jsonl"

        # Ensure queue directory exists
        $queueDir = Split-Path -Parent $queueFile
        if (-not (Test-Path $queueDir)) {
            New-Item -ItemType Directory -Path $queueDir -Force | Out-Null
        }

        # Build queue entry (JSONL format - one JSON object per line)
        $queueEntry = @{
            sessionId = $SessionId
            agentName = $AgentContext.AgentName
            status = "in-progress"
            workDescription = $AgentContext.WorkDescription
            startTime = $AgentContext.StartTime.ToString('yyyy-MM-ddTHH:mm:ssZ')
            queuedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
            syncStatus = "pending"
            retryCount = 0
        } | ConvertTo-Json -Compress

        # Append to queue file (JSONL format)
        Add-Content -Path $queueFile -Value $queueEntry -ErrorAction Stop

        Write-HookLog "Successfully queued Notion sync: $SessionId" -Level INFO
        return $true
    }
    catch {
        Write-HookLog "Failed to queue Notion sync: $_" -Level WARNING
        # Don't fail entire hook if queue operation fails
        return $false
    }
}

# Invoke 3-tier activity logging system (Markdown + JSON immediate, Notion queued)
function Invoke-ActivityLogger {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AgentContext
    )

    Write-HookLog "Invoking 3-tier activity logging for: $($AgentContext.AgentName)" -Level INFO

    # Generate unique session ID
    $timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
    $agentShortName = $AgentContext.AgentName.TrimStart('@')
    $sessionId = "$agentShortName-$timestamp"

    Write-HookLog "Session ID: $sessionId" -Level DEBUG

    # Track success of each tier
    $results = @{
        Markdown = $false
        Json = $false
        Notion = $false
    }

    # Tier 2: Update Markdown log
    $results.Markdown = Update-MarkdownLog -SessionId $sessionId -AgentContext $AgentContext

    # Tier 3: Update JSON state
    $results.Json = Update-JsonState -SessionId $sessionId -AgentContext $AgentContext

    # Tier 1: Queue Notion sync (processed later via Notion MCP)
    $results.NotionQueue = Queue-NotionSync -SessionId $sessionId -AgentContext $AgentContext

    # Determine overall success
    $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count
    $totalTiers = $results.Count

    if ($successCount -eq $totalTiers) {
        Write-HookLog "Successfully logged to all tiers: $sessionId" -Level INFO
        return @{
            Success = $true
            Message = "Activity logged: Markdown + JSON (immediate), Notion (queued): $sessionId"
            SessionId = $sessionId
            TierResults = $results
        }
    }
    elseif ($successCount -gt 0) {
        Write-HookLog "Partial success: $successCount/$totalTiers tiers updated for $sessionId" -Level WARNING
        return @{
            Success = $true
            Message = "Partially logged to $successCount/$totalTiers tiers: $sessionId"
            SessionId = $sessionId
            TierResults = $results
        }
    }
    else {
        Write-HookLog "Failed to log to any tier: $sessionId" -Level ERROR
        return @{
            Success = $false
            Message = "Failed to log activity for $sessionId"
            SessionId = $sessionId
            TierResults = $results
        }
    }
}

# Main execution flow
function Main {
    try {
        Write-HookLog "Auto-log agent activity hook triggered" -Level INFO

        # Parse agent context from tool invocation
        $agentContext = Get-AgentContext -ToolName $ToolName -ToolParams $ToolParameters

        # Apply intelligent filtering
        if (-not (Test-ShouldLogAgent -AgentContext $agentContext)) {
            Write-HookLog "Agent activity logging skipped (filtering rules)" -Level DEBUG
            exit 0
        }

        # Invoke activity logger agent
        $result = Invoke-ActivityLogger -AgentContext $agentContext

        if ($result.Success) {
            Write-HookLog "Activity logging completed successfully: $($result.Message)" -Level INFO
            exit 0
        }
        else {
            Write-HookLog "Activity logging failed: $($result.Message)" -Level ERROR
            exit 1
        }
    }
    catch {
        Write-HookLog "Unhandled error in auto-log hook: $_" -Level ERROR
        Write-HookLog "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
        exit 1
    }
}

# Execute main flow
Main
