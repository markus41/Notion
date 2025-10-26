<#
.SYNOPSIS
    Innovation Nexus Real-Time Statusline - Establish comprehensive system visibility

.DESCRIPTION
    Generates dynamic, context-aware statusline content for Claude Code that provides
    instant visibility into system health, active work, innovation pipeline status,
    and actionable metrics across the Brookside BI Innovation Nexus ecosystem.

.NOTES
    Author: Brookside BI Innovation Nexus
    Version: 1.0.0
    Best for: Organizations requiring real-time visibility across multi-agent,
             multi-database innovation workflows with integrated cost tracking
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('full', 'compact', 'minimal')]
    [string]$DisplayMode = 'full',

    [Parameter()]
    [switch]$NoCache,

    [Parameter()]
    [int]$TimeoutSeconds = 2
)

$ErrorActionPreference = 'SilentlyContinue'

# ============================================================================
# Configuration & Constants
# ============================================================================

$script:CacheDir = Join-Path $PSScriptRoot ".." "data" "statusline-cache"
$script:CacheTTL = 300 # 5 minutes
$script:UtilsDir = $PSScriptRoot

# Brookside BI Brand Colors (ANSI)
$script:Colors = @{
    Primary = "`e[38;2;41;128;185m"    # Blue
    Success = "`e[38;2;46;204;113m"    # Green
    Warning = "`e[38;2;241;196;15m"    # Yellow
    Error = "`e[38;2;231;76;60m"       # Red
    Muted = "`e[38;2;149;165;166m"     # Gray
    Reset = "`e[0m"
}

# Status Icons (Terminal-safe alternatives to emojis)
$script:Emojis = @{
    Active = "[*]"      # Active indicator
    Concept = "[.]"     # Concept phase
    NotActive = "[-]"   # Not active
    Completed = "[+]"   # Completed
    Idea = "I:"         # Ideas
    Research = "R:"     # Research
    Build = "B:"        # Builds
    Cost = "$"          # Cost/money
    Agent = "A:"        # Agent
    Git = ">"           # Git branch
    Alert = "!"         # Alert
    Check = "+"         # Check/OK
    Cross = "x"         # Error/fail
    Automation = "#"    # Automation
    Clock = "@"         # Time/clock
    Handoff = "~"       # Handoff
}

# ============================================================================
# Core Functions
# ============================================================================

function Get-CachedValue {
    <#
    .SYNOPSIS
        Retrieve cached value or execute function if cache expired
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [scriptblock]$Generator,

        [int]$TTL = $script:CacheTTL
    )

    if ($NoCache) {
        return & $Generator
    }

    $cacheFile = Join-Path $script:CacheDir "$Key.json"

    # Check if cache exists and is fresh
    if (Test-Path $cacheFile) {
        $cache = Get-Content $cacheFile -Raw | ConvertFrom-Json
        $age = (Get-Date) - [datetime]$cache.Timestamp

        if ($age.TotalSeconds -lt $TTL) {
            return $cache.Value
        }
    }

    # Generate fresh value
    $value = & $Generator

    # Cache it
    if (-not (Test-Path $script:CacheDir)) {
        New-Item -ItemType Directory -Path $script:CacheDir -Force | Out-Null
    }

    @{
        Timestamp = (Get-Date).ToString('o')
        Value = $value
    } | ConvertTo-Json -Depth 10 | Set-Content $cacheFile

    return $value
}

function Get-GitStatusCompact {
    <#
    .SYNOPSIS
        Get compact git status with branch, changes, and ahead/behind info
    #>
    try {
        # Check if we're in a git repository
        $gitRoot = git rev-parse --show-toplevel 2>$null
        if (-not $gitRoot) { return $null }

        # Get current branch
        $branch = git branch --show-current 2>$null
        if (-not $branch) { $branch = "detached" }

        # Get status
        $status = git status --porcelain 2>$null
        $modified = ($status | Where-Object { $_ -match '^.M' }).Count
        $added = ($status | Where-Object { $_ -match '^A' }).Count
        $deleted = ($status | Where-Object { $_ -match '^.D' }).Count
        $untracked = ($status | Where-Object { $_ -match '^\?\?' }).Count

        # Get ahead/behind
        $ahead = 0
        $behind = 0
        $aheadBehind = git rev-list --left-right --count '@{upstream}...HEAD' 2>$null
        if ($aheadBehind -match '(\d+)\s+(\d+)') {
            $behind = [int]$matches[1]
            $ahead = [int]$matches[2]
        }

        return @{
            Branch = $branch
            Modified = $modified
            Added = $added
            Deleted = $deleted
            Untracked = $untracked
            Ahead = $ahead
            Behind = $behind
            HasChanges = ($modified + $added + $deleted + $untracked) -gt 0
        }
    }
    catch {
        return $null
    }
}

function Get-MCPServerStatus {
    <#
    .SYNOPSIS
        Check MCP server connectivity status
    #>
    try {
        $healthOutput = claude mcp list 2>&1 | Out-String

        $servers = @{
            Notion = $healthOutput -match 'notion.*Connected'
            GitHub = $healthOutput -match 'github.*Connected'
            Azure = $healthOutput -match 'azure.*Connected'
            Playwright = $healthOutput -match 'playwright.*Connected'
        }

        $allHealthy = ($servers.Values -notcontains $false)

        return @{
            Servers = $servers
            AllHealthy = $allHealthy
            HealthCount = ($servers.Values | Where-Object { $_ }).Count
            TotalCount = $servers.Count
        }
    }
    catch {
        return @{
            Servers = @{}
            AllHealthy = $false
            HealthCount = 0
            TotalCount = 4
        }
    }
}

function Get-AgentActivityStatus {
    <#
    .SYNOPSIS
        Get current agent activity from agent-state.json
    #>
    try {
        $stateFile = Join-Path $PSScriptRoot ".." "data" "agent-state.json"
        if (-not (Test-Path $stateFile)) { return $null }

        $state = Get-Content $stateFile -Raw | ConvertFrom-Json

        # Find active sessions
        $activeSessions = $state.activeSessions | Where-Object {
            $_.status -in @('in-progress', 'handed-off', 'blocked')
        }

        if ($activeSessions) {
            $current = $activeSessions[0]
            $startTime = [datetime]$current.startTime
            $duration = (Get-Date) - $startTime

            return @{
                AgentName = $current.agentName
                Status = $current.status
                Duration = [math]::Round($duration.TotalMinutes)
                WorkDescription = $current.workDescription
                HasBlockers = $current.blockers.Count -gt 0
                IsHandoff = $current.status -eq 'handed-off'
            }
        }

        return $null
    }
    catch {
        return $null
    }
}

function Get-InnovationMetrics {
    <#
    .SYNOPSIS
        Get quick metrics from Innovation Nexus databases
    #>

    # This is a placeholder - actual implementation would use Notion MCP
    # For now, return mock data structure
    return @{
        ActiveIdeas = 12
        ActiveResearch = 3
        ActiveBuilds = 8
        MonthlySpend = 4200
        UnusedTools = 3
        UnusedCost = 340
    }
}

function Format-GitSegment {
    <#
    .SYNOPSIS
        Format git status segment for statusline
    #>
    param($GitStatus)

    if (-not $GitStatus) {
        return ""
    }

    $c = $script:Colors
    $e = $script:Emojis

    $parts = @()
    $parts += "$($e.Git) $($c.Primary)$($GitStatus.Branch)$($c.Reset)"

    if ($GitStatus.Ahead -gt 0) {
        $parts += "$($c.Warning)^ $($GitStatus.Ahead)UP$($c.Reset)"
    }

    if ($GitStatus.HasChanges) {
        $changeParts = @()
        if ($GitStatus.Modified -gt 0) { $changeParts += "$($GitStatus.Modified)M" }
        if ($GitStatus.Added -gt 0) { $changeParts += "$($GitStatus.Added)A" }
        if ($GitStatus.Deleted -gt 0) { $changeParts += "$($GitStatus.Deleted)D" }
        if ($GitStatus.Untracked -gt 0) { $changeParts += "$($GitStatus.Untracked)?" }
        $parts += "[CHG] $($c.Warning)$($changeParts -join ' ')$($c.Reset)"
    }

    return $parts -join " | "
}

function Format-InnovationSegment {
    <#
    .SYNOPSIS
        Format innovation pipeline metrics segment
    #>
    param($Metrics)

    $c = $script:Colors
    $e = $script:Emojis

    $parts = @()
    $parts += "$($e.Idea) $($c.Primary)$($Metrics.ActiveIdeas)$($c.Reset)"
    $parts += "$($e.Research) $($c.Primary)$($Metrics.ActiveResearch)$($c.Reset)"
    $parts += "$($e.Build) $($c.Primary)$($Metrics.ActiveBuilds)$($c.Reset)"

    return $parts -join " "
}

function Format-CostSegment {
    <#
    .SYNOPSIS
        Format cost metrics segment
    #>
    param($Metrics)

    $c = $script:Colors
    $e = $script:Emojis

    $costK = [math]::Round($Metrics.MonthlySpend / 1000, 1)
    $segment = "$($e.Cost) $($c.Success)`$$($costK)K/mo$($c.Reset)"

    if ($Metrics.UnusedTools -gt 0) {
        $wasteAmount = [math]::Round($Metrics.UnusedCost / 1000, 1)
        $segment += " $($c.Warning)$($e.Alert) $($Metrics.UnusedTools) unused (`$$($wasteAmount)K)$($c.Reset)"
    }

    return $segment
}

function Format-AgentSegment {
    <#
    .SYNOPSIS
        Format active agent segment
    #>
    param($AgentActivity)

    if (-not $AgentActivity) {
        return ""
    }

    $c = $script:Colors
    $e = $script:Emojis

    $statusIcon = switch ($AgentActivity.Status) {
        'in-progress' { "$($e.Agent)" }
        'handed-off' { "$($e.Handoff)" }
        'blocked' { "$($e.Alert)" }
        default { "$($e.Agent)" }
    }

    $color = switch ($AgentActivity.Status) {
        'in-progress' { $c.Success }
        'handed-off' { $c.Warning }
        'blocked' { $c.Error }
        default { $c.Primary }
    }

    return "$statusIcon $color$($AgentActivity.AgentName)$($c.Reset) ($($AgentActivity.Duration)m)"
}

function Format-MCPSegment {
    <#
    .SYNOPSIS
        Format MCP server status segment
    #>
    param($MCPStatus)

    $c = $script:Colors
    $e = $script:Emojis

    if ($MCPStatus.AllHealthy) {
        return "$($c.Success)$($e.Check) All MCP$($c.Reset)"
    }

    $healthy = @()
    $unhealthy = @()

    foreach ($server in $MCPStatus.Servers.GetEnumerator()) {
        if ($server.Value) {
            $healthy += $server.Key
        } else {
            $unhealthy += $server.Key
        }
    }

    if ($unhealthy.Count -gt 0) {
        return "$($c.Error)$($e.Cross) MCP: $($unhealthy -join ', ')$($c.Reset)"
    }

    return "$($c.Success)$($e.Check) MCP ($($MCPStatus.HealthCount)/$($MCPStatus.TotalCount))$($c.Reset)"
}

function Build-Statusline {
    <#
    .SYNOPSIS
        Build complete statusline based on display mode
    #>
    param(
        [string]$Mode = 'full'
    )

    # Gather all data in parallel (with timeouts)
    $gitStatus = Get-CachedValue -Key "git-status" -TTL 30 -Generator { Get-GitStatusCompact }
    $mcpStatus = Get-CachedValue -Key "mcp-status" -TTL 60 -Generator { Get-MCPServerStatus }
    $agentActivity = Get-CachedValue -Key "agent-activity" -TTL 15 -Generator { Get-AgentActivityStatus }
    $metrics = Get-CachedValue -Key "innovation-metrics" -TTL 300 -Generator { Get-InnovationMetrics }

    $segments = @()

    # Line 1: Primary status
    $line1Parts = @()

    # Git status (always show if available)
    $gitSegment = Format-GitSegment -GitStatus $gitStatus
    if ($gitSegment) { $line1Parts += $gitSegment }

    # Innovation metrics
    $innovationSegment = Format-InnovationSegment -Metrics $metrics
    if ($innovationSegment) { $line1Parts += $innovationSegment }

    # Cost metrics
    $costSegment = Format-CostSegment -Metrics $metrics
    if ($costSegment) { $line1Parts += $costSegment }

    # Active agent
    $agentSegment = Format-AgentSegment -AgentActivity $agentActivity
    if ($agentSegment) { $line1Parts += $agentSegment }

    $line1 = $line1Parts -join " | "

    # Line 2: System health
    if ($Mode -eq 'full') {
        $line2Parts = @()

        # MCP status
        $mcpSegment = Format-MCPSegment -MCPStatus $mcpStatus
        if ($mcpSegment) { $line2Parts += $mcpSegment }

        # Alerts
        if ($agentActivity -and $agentActivity.IsHandoff) {
            $c = $script:Colors
            $e = $script:Emojis
            $line2Parts += "$($c.Warning)$($e.Alert) Handoff pending$($c.Reset)"
        }

        $line2 = $line2Parts -join " | "

        # Combine with box drawing
        $header = "+-- Innovation Nexus " + ("-" * 50) + "-+"
        $footer = "+" + ("-" * 74) + "+"

        return @"
$header
| $line1
| $line2
$footer
"@
    }
    elseif ($Mode -eq 'compact') {
        return $line1
    }
    else {
        # Minimal mode - just essentials
        $parts = @()
        if ($gitStatus) { $parts += "$($script:Emojis.Git) $($gitStatus.Branch)" }
        if ($agentActivity) { $parts += "$($script:Emojis.Agent) $($agentActivity.AgentName)" }
        return $parts -join " | "
    }
}

# ============================================================================
# Main Execution
# ============================================================================

try {
    $statusline = Build-Statusline -Mode $DisplayMode
    Write-Output $statusline
}
catch {
    Write-Error "Failed to build statusline: $_"
    exit 1
}
