<#
.SYNOPSIS
    Agent Activity Widget - Real-time visibility into agent work sessions

.DESCRIPTION
    Provides focused display of current agent activity, recent completions,
    blockers, and handoffs for the Innovation Nexus statusline system.
    Establishes transparent agent work tracking with actionable alerts.

.NOTES
    Author: Brookside BI Innovation Nexus
    Version: 1.0.0
    Dependencies: agent-state.json, AGENT_ACTIVITY_LOG.md
    Best for: Real-time agent work monitoring and workflow continuity
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('current', 'recent', 'blocked', 'summary')]
    [string]$View = 'current',

    [Parameter()]
    [int]$RecentHours = 4
)

$ErrorActionPreference = 'SilentlyContinue'

# ============================================================================
# Configuration
# ============================================================================

$script:StateFile = Join-Path $PSScriptRoot ".." "data" "agent-state.json"
$script:LogFile = Join-Path $PSScriptRoot ".." "logs" "AGENT_ACTIVITY_LOG.md"

# Status colors
$script:StatusColors = @{
    'in-progress' = "`e[38;2;46;204;113m"  # Green
    'completed' = "`e[38;2;41;128;185m"    # Blue
    'blocked' = "`e[38;2;231;76;60m"       # Red
    'handed-off' = "`e[38;2;241;196;15m"   # Yellow
}

$script:ResetColor = "`e[0m"

# ============================================================================
# Data Loading Functions
# ============================================================================

function Get-AgentState {
    <#
    .SYNOPSIS
        Load current agent state from JSON
    #>
    if (-not (Test-Path $script:StateFile)) {
        return @{
            lastUpdated = (Get-Date).ToString('o')
            activeSessions = @()
        }
    }

    try {
        return Get-Content $script:StateFile -Raw | ConvertFrom-Json
    }
    catch {
        return @{
            lastUpdated = (Get-Date).ToString('o')
            activeSessions = @()
        }
    }
}

function Get-CurrentSession {
    <#
    .SYNOPSIS
        Get the most recent active session
    #>
    $state = Get-AgentState

    $activeSessions = $state.activeSessions | Where-Object {
        $_.status -in @('in-progress', 'blocked', 'handed-off')
    }

    if ($activeSessions) {
        # Return most recent
        return $activeSessions | Sort-Object {
            [datetime]$_.startTime
        } -Descending | Select-Object -First 1
    }

    return $null
}

function Get-RecentCompletions {
    <#
    .SYNOPSIS
        Get recently completed agent sessions
    #>
    param([int]$Hours = 4)

    $state = Get-AgentState
    $cutoff = (Get-Date).AddHours(-$Hours)

    $completed = $state.activeSessions | Where-Object {
        $_.status -eq 'completed' -and
        (([datetime]$_.endTime) -gt $cutoff)
    }

    return $completed | Sort-Object {
        [datetime]$_.endTime
    } -Descending
}

function Get-BlockedSessions {
    <#
    .SYNOPSIS
        Get all sessions with blockers
    #>
    $state = Get-AgentState

    return $state.activeSessions | Where-Object {
        $_.status -eq 'blocked' -or
        ($_.blockers -and $_.blockers.Count -gt 0)
    }
}

function Get-HandoffSessions {
    <#
    .SYNOPSIS
        Get sessions awaiting handoff
    #>
    $state = Get-AgentState

    return $state.activeSessions | Where-Object {
        $_.status -eq 'handed-off'
    }
}

# ============================================================================
# Formatting Functions
# ============================================================================

function Format-Duration {
    <#
    .SYNOPSIS
        Format timespan into human-readable duration
    #>
    param([TimeSpan]$Duration)

    if ($Duration.TotalHours -ge 1) {
        return "$([math]::Round($Duration.TotalHours, 1))h"
    }
    elseif ($Duration.TotalMinutes -ge 1) {
        return "$([math]::Round($Duration.TotalMinutes))m"
    }
    else {
        return "$([math]::Round($Duration.TotalSeconds))s"
    }
}

function Format-SessionStatus {
    <#
    .SYNOPSIS
        Format session status with color and icon
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Status
    )

    $color = $script:StatusColors[$Status]
    $icon = switch ($Status) {
        'in-progress' { '⚙️' }
        'completed' { '✅' }
        'blocked' { '🚫' }
        'handed-off' { '🔄' }
        default { '📋' }
    }

    return "$icon $color$Status$($script:ResetColor)"
}

function Format-CurrentSession {
    <#
    .SYNOPSIS
        Format current active session for display
    #>
    param($Session)

    if (-not $Session) {
        return "No active agent sessions"
    }

    $startTime = [datetime]$Session.startTime
    $duration = (Get-Date) - $startTime
    $durationStr = Format-Duration -Duration $duration

    $status = Format-SessionStatus -Status $Session.status
    $workDesc = $Session.workDescription
    if ($workDesc.Length -gt 60) {
        $workDesc = $workDesc.Substring(0, 57) + "..."
    }

    $output = @"
🤖 $($Session.agentName) | $status | $durationStr
   $workDesc
"@

    # Add blockers if present
    if ($Session.blockers -and $Session.blockers.Count -gt 0) {
        $output += "`n   🚫 $($Session.blockers.Count) blocker(s)"
    }

    # Add handoff info if present
    if ($Session.handoff) {
        $handoffTo = $Session.handoff.handoffTo
        if ($handoffTo.Length -gt 40) {
            $handoffTo = $handoffTo.Substring(0, 37) + "..."
        }
        $output += "`n   🔄 Handoff: $handoffTo"
    }

    return $output
}

function Format-RecentCompletion {
    <#
    .SYNOPSIS
        Format recent completion for display
    #>
    param($Session)

    $endTime = [datetime]$Session.endTime
    $age = (Get-Date) - $endTime
    $ageStr = Format-Duration -Duration $age

    $deliverableCount = 0
    if ($Session.deliverables) {
        $deliverableCount = $Session.deliverables.count
    }

    return "✅ $($Session.agentName) - $($deliverableCount) deliverables ($ageStr ago)"
}

function Format-BlockedSession {
    <#
    .SYNOPSIS
        Format blocked session for display
    #>
    param($Session)

    $blockerText = "unknown issue"
    if ($Session.blockers -and $Session.blockers.Count -gt 0) {
        $blocker = $Session.blockers[0]
        $blockerText = $blocker.description
        if ($blockerText.Length -gt 50) {
            $blockerText = $blockerText.Substring(0, 47) + "..."
        }
    }

    return "🚫 $($Session.agentName) - BLOCKED: $blockerText"
}

# ============================================================================
# View Renderers
# ============================================================================

function Show-CurrentView {
    <#
    .SYNOPSIS
        Show current agent activity
    #>
    $session = Get-CurrentSession

    if ($session) {
        return Format-CurrentSession -Session $session
    }
    else {
        return "No active agent sessions"
    }
}

function Show-RecentView {
    <#
    .SYNOPSIS
        Show recent completions
    #>
    param([int]$Hours)

    $completions = Get-RecentCompletions -Hours $Hours

    if ($completions.Count -eq 0) {
        return "No agent completions in last $Hours hours"
    }

    $output = "Recent Completions (last $Hours hours):`n"
    $completions | ForEach-Object {
        $output += "  " + (Format-RecentCompletion -Session $_) + "`n"
    }

    return $output.TrimEnd()
}

function Show-BlockedView {
    <#
    .SYNOPSIS
        Show blocked sessions
    #>
    $blocked = Get-BlockedSessions

    if ($blocked.Count -eq 0) {
        return "No blocked agent sessions"
    }

    $output = "Blocked Sessions (ACTION REQUIRED):`n"
    $blocked | ForEach-Object {
        $output += "  " + (Format-BlockedSession -Session $_) + "`n"
    }

    return $output.TrimEnd()
}

function Show-SummaryView {
    <#
    .SYNOPSIS
        Show summary of all agent activity
    #>
    $state = Get-AgentState

    $inProgress = @($state.activeSessions | Where-Object { $_.status -eq 'in-progress' }).Count
    $blocked = @($state.activeSessions | Where-Object { $_.status -eq 'blocked' }).Count
    $handoff = @($state.activeSessions | Where-Object { $_.status -eq 'handed-off' }).Count
    $completed24h = @($state.activeSessions | Where-Object {
        $_.status -eq 'completed' -and
        (([datetime]$_.endTime) -gt (Get-Date).AddHours(-24))
    }).Count

    $output = @"
Agent Activity Summary:
  ⚙️  In Progress: $inProgress
  🚫 Blocked: $blocked
  🔄 Handoff: $handoff
  ✅ Completed (24h): $completed24h
"@

    # Add current session if present
    $current = Get-CurrentSession
    if ($current) {
        $output += "`n`nCurrent:`n"
        $output += "  " + (Format-CurrentSession -Session $current)
    }

    # Add alerts if present
    if ($blocked -gt 0 -or $handoff -gt 0) {
        $output += "`n`n⚠️  ACTION NEEDED: $($blocked + $handoff) session(s) require attention"
    }

    return $output
}

# ============================================================================
# Main Execution
# ============================================================================

try {
    $output = switch ($View) {
        'current' { Show-CurrentView }
        'recent' { Show-RecentView -Hours $RecentHours }
        'blocked' { Show-BlockedView }
        'summary' { Show-SummaryView }
        default { Show-CurrentView }
    }

    Write-Output $output
}
catch {
    Write-Error "Failed to generate agent widget: $_"
    exit 1
}
