<#
.SYNOPSIS
    MCP Server Health Checker - Verify Innovation Nexus MCP connectivity

.DESCRIPTION
    Establishes comprehensive health monitoring for all MCP servers
    (Notion, GitHub, Azure, Playwright) with detailed diagnostics and
    actionable recommendations for connection issues.

.NOTES
    Author: Brookside BI Innovation Nexus
    Version: 1.0.0
    Dependencies: Claude Code MCP infrastructure
    Best for: Proactive detection of MCP connectivity issues
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('all', 'notion', 'github', 'azure', 'playwright')]
    [string]$Server = 'all',

    [Parameter()]
    [switch]$Detailed,

    [Parameter()]
    [switch]$QuickCheck
)

$ErrorActionPreference = 'SilentlyContinue'

# ============================================================================
# Configuration
# ============================================================================

$script:ExpectedServers = @('notion', 'github', 'azure', 'playwright')

$script:ServerInfo = @{
    notion = @{
        Name = 'Notion'
        Type = 'HTTP'
        Purpose = 'Innovation tracking, database operations'
        Critical = $true
    }
    github = @{
        Name = 'GitHub'
        Type = 'npx'
        Purpose = 'Repository operations, CI/CD'
        Critical = $true
    }
    azure = @{
        Name = 'Azure'
        Type = 'npx'
        Purpose = 'Cloud resource management, deployments'
        Critical = $true
    }
    playwright = @{
        Name = 'Playwright'
        Type = 'npx'
        Purpose = 'Browser automation, web testing'
        Critical = $false
    }
}

# ============================================================================
# Health Check Functions
# ============================================================================

function Get-MCPServerList {
    <#
    .SYNOPSIS
        Get list of MCP servers from claude mcp list
    #>
    try {
        $output = claude mcp list 2>&1 | Out-String
        return $output
    }
    catch {
        return ""
    }
}

function Test-ServerConnection {
    <#
    .SYNOPSIS
        Test connection to a specific MCP server
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ServerName
    )

    $listOutput = Get-MCPServerList

    # Check if server appears in list
    $found = $listOutput -match $ServerName

    if (-not $found) {
        return @{
            Server = $ServerName
            Connected = $false
            Status = 'Not Found'
            Message = "Server not listed in MCP configuration"
        }
    }

    # Check if connected
    $connected = $listOutput -match "$ServerName.*✓ Connected"

    if ($connected) {
        return @{
            Server = $ServerName
            Connected = $true
            Status = 'Healthy'
            Message = "Server operational"
        }
    }

    # Server found but not connected
    return @{
        Server = $ServerName
        Connected = $false
        Status = 'Disconnected'
        Message = "Server configured but not connected"
    }
}

function Get-ServerHealth {
    <#
    .SYNOPSIS
        Get comprehensive health status for all or specific server
    #>
    param([string]$TargetServer = 'all')

    $results = @{}

    if ($TargetServer -eq 'all') {
        $serversToCheck = $script:ExpectedServers
    }
    else {
        $serversToCheck = @($TargetServer)
    }

    foreach ($server in $serversToCheck) {
        $health = Test-ServerConnection -ServerName $server
        $info = $script:ServerInfo[$server]

        $results[$server] = @{
            Name = $info.Name
            Connected = $health.Connected
            Status = $health.Status
            Message = $health.Message
            Critical = $info.Critical
            Purpose = $info.Purpose
            Type = $info.Type
        }
    }

    return $results
}

function Get-DiagnosticRecommendations {
    <#
    .SYNOPSIS
        Get actionable recommendations for connection issues
    #>
    param($HealthResults)

    $recommendations = @()

    $disconnected = $HealthResults.GetEnumerator() | Where-Object {
        -not $_.Value.Connected
    }

    if ($disconnected.Count -eq 0) {
        return @("✅ All MCP servers operational - no action needed")
    }

    # Check if all servers are down
    if ($disconnected.Count -eq $HealthResults.Count) {
        $recommendations += "⚠️  All MCP servers disconnected - Claude Code MCP may not be running"
        $recommendations += "   → Run: claude mcp list"
        $recommendations += "   → Check Claude Code service status"
        return $recommendations
    }

    # Specific server issues
    foreach ($server in $disconnected) {
        $serverName = $server.Value.Name
        $critical = $server.Value.Critical

        if ($critical) {
            $recommendations += "🚨 CRITICAL: $serverName MCP disconnected"
        }
        else {
            $recommendations += "⚠️  $serverName MCP disconnected"
        }

        # Server-specific recommendations
        switch ($server.Key) {
            'notion' {
                $recommendations += "   → Verify Notion OAuth token: https://mcp.notion.com/"
                $recommendations += "   → Check NOTION_WORKSPACE_ID in environment"
            }
            'github' {
                $recommendations += "   → Verify GitHub PAT in Azure Key Vault"
                $recommendations += "   → Run: .\scripts\Get-KeyVaultSecret.ps1 -SecretName 'github-personal-access-token'"
            }
            'azure' {
                $recommendations += "   → Authenticate to Azure: az login"
                $recommendations += "   → Verify: az account show"
            }
            'playwright' {
                $recommendations += "   → Install Playwright: npx playwright install msedge"
            }
        }
    }

    return $recommendations
}

# ============================================================================
# Formatting Functions
# ============================================================================

function Format-HealthSummary {
    <#
    .SYNOPSIS
        Format health summary for display
    #>
    param($HealthResults)

    $total = $HealthResults.Count
    $connected = ($HealthResults.Values | Where-Object { $_.Connected }).Count
    $critical = ($HealthResults.Values | Where-Object { $_.Critical -and -not $_.Connected }).Count

    $color = if ($connected -eq $total) {
        "`e[38;2;46;204;113m" # Green
    }
    elseif ($critical -gt 0) {
        "`e[38;2;231;76;60m"  # Red
    }
    else {
        "`e[38;2;241;196;15m" # Yellow
    }

    $reset = "`e[0m"

    return "$color$connected/$total$reset MCP servers connected"
}

function Format-DetailedStatus {
    <#
    .SYNOPSIS
        Format detailed status for all servers
    #>
    param($HealthResults)

    $output = "MCP Server Health Status:`n`n"

    foreach ($server in $HealthResults.GetEnumerator() | Sort-Object { $_.Value.Critical } -Descending) {
        $name = $server.Value.Name
        $connected = $server.Value.Connected
        $purpose = $server.Value.Purpose
        $critical = $server.Value.Critical

        $icon = if ($connected) { '✅' } else { '❌' }
        $criticalBadge = if ($critical) { '[CRITICAL]' } else { '' }

        $output += "$icon $name $criticalBadge`n"
        $output += "   Status: $($server.Value.Status)`n"
        $output += "   Purpose: $purpose`n"
        $output += "   Type: $($server.Value.Type)`n"

        if (-not $connected) {
            $output += "   Message: $($server.Value.Message)`n"
        }

        $output += "`n"
    }

    return $output.TrimEnd()
}

# ============================================================================
# Main Execution
# ============================================================================

try {
    # Quick check mode - just return connected/total
    if ($QuickCheck) {
        $health = Get-ServerHealth -TargetServer $Server
        $connected = ($health.Values | Where-Object { $_.Connected }).Count
        $total = $health.Count
        Write-Output "$connected/$total"
        exit 0
    }

    # Get health status
    $health = Get-ServerHealth -TargetServer $Server

    # Format output
    if ($Detailed) {
        $output = Format-DetailedStatus -HealthResults $health

        # Add recommendations
        $recommendations = Get-DiagnosticRecommendations -HealthResults $health
        if ($recommendations.Count -gt 0) {
            $output += "`n`nRecommendations:`n"
            $recommendations | ForEach-Object {
                $output += "$_`n"
            }
        }

        Write-Output $output.TrimEnd()
    }
    else {
        # Compact summary
        $summary = Format-HealthSummary -HealthResults $health
        Write-Output $summary
    }
}
catch {
    Write-Error "Failed to check MCP health: $_"
    exit 1
}
