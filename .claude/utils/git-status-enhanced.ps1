<#
.SYNOPSIS
    Enhanced Git Status - Rich repository context for statusline

.DESCRIPTION
    Provides comprehensive Git repository status including branch info,
    change statistics, ahead/behind tracking, PR readiness checks, and
    commit quality indicators for the Innovation Nexus statusline.

.NOTES
    Author: Brookside BI Innovation Nexus
    Version: 1.0.0
    Dependencies: Git
    Best for: Git-aware statusline with PR readiness and branch hygiene
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$RepositoryPath = ".",

    [Parameter()]
    [ValidateSet('compact', 'detailed', 'pr-ready')]
    [string]$Format = 'compact',

    [Parameter()]
    [switch]$IncludeRemote
)

$ErrorActionPreference = 'SilentlyContinue'

# ============================================================================
# Git Query Functions
# ============================================================================

function Test-GitRepository {
    <#
    .SYNOPSIS
        Check if current directory is a Git repository
    #>
    try {
        $gitRoot = git -C $RepositoryPath rev-parse --show-toplevel 2>$null
        return $null -ne $gitRoot
    }
    catch {
        return $false
    }
}

function Get-CurrentBranch {
    <#
    .SYNOPSIS
        Get current branch name or HEAD state
    #>
    try {
        $branch = git -C $RepositoryPath branch --show-current 2>$null
        if ($branch) {
            return $branch
        }

        # Check if detached HEAD
        $head = git -C $RepositoryPath rev-parse --short HEAD 2>$null
        if ($head) {
            return "HEAD@$head"
        }

        return "unknown"
    }
    catch {
        return "unknown"
    }
}

function Get-ChangeStatistics {
    <#
    .SYNOPSIS
        Get detailed change statistics
    #>
    try {
        $status = git -C $RepositoryPath status --porcelain 2>$null

        $stats = @{
            Modified = 0
            Added = 0
            Deleted = 0
            Renamed = 0
            Untracked = 0
            Staged = 0
            Unstaged = 0
        }

        foreach ($line in $status) {
            $xy = $line.Substring(0, 2)

            # Staged changes
            switch ($xy[0]) {
                'M' { $stats.Staged++; $stats.Modified++ }
                'A' { $stats.Staged++; $stats.Added++ }
                'D' { $stats.Staged++; $stats.Deleted++ }
                'R' { $stats.Staged++; $stats.Renamed++ }
            }

            # Unstaged changes
            switch ($xy[1]) {
                'M' { $stats.Unstaged++; if ($xy[0] -ne 'M') { $stats.Modified++ } }
                'D' { $stats.Unstaged++; if ($xy[0] -ne 'D') { $stats.Deleted++ } }
            }

            # Untracked
            if ($xy -eq '??') {
                $stats.Untracked++
            }
        }

        $stats.HasChanges = (
            $stats.Modified + $stats.Added + $stats.Deleted +
            $stats.Renamed + $stats.Untracked
        ) -gt 0

        return $stats
    }
    catch {
        return @{
            Modified = 0
            Added = 0
            Deleted = 0
            Renamed = 0
            Untracked = 0
            Staged = 0
            Unstaged = 0
            HasChanges = $false
        }
    }
}

function Get-AheadBehindCount {
    <#
    .SYNOPSIS
        Get commits ahead/behind upstream
    #>
    try {
        $output = git -C $RepositoryPath rev-list --left-right --count '@{upstream}...HEAD' 2>$null

        if ($output -match '(\d+)\s+(\d+)') {
            return @{
                Behind = [int]$matches[1]
                Ahead = [int]$matches[2]
            }
        }

        return @{
            Behind = 0
            Ahead = 0
        }
    }
    catch {
        return @{
            Behind = 0
            Ahead = 0
        }
    }
}

function Get-LastCommitInfo {
    <#
    .SYNOPSIS
        Get last commit message and age
    #>
    try {
        $message = git -C $RepositoryPath log -1 --pretty=format:'%s' 2>$null
        $timestamp = git -C $RepositoryPath log -1 --pretty=format:'%at' 2>$null

        if ($timestamp) {
            $commitDate = [DateTimeOffset]::FromUnixTimeSeconds([long]$timestamp).DateTime
            $age = (Get-Date) - $commitDate

            return @{
                Message = $message
                Age = $age
                Timestamp = $commitDate
            }
        }

        return $null
    }
    catch {
        return $null
    }
}

function Get-RemoteStatus {
    <#
    .SYNOPSIS
        Check remote connection and fetch status
    #>
    try {
        # Get remote URL
        $remoteUrl = git -C $RepositoryPath config --get remote.origin.url 2>$null

        if (-not $remoteUrl) {
            return @{
                HasRemote = $false
                Url = $null
                NeedsFetch = $false
            }
        }

        # Check last fetch time
        $fetchHeadFile = git -C $RepositoryPath rev-parse --git-dir 2>$null
        if ($fetchHeadFile) {
            $fetchHeadPath = Join-Path $fetchHeadFile "FETCH_HEAD"
            if (Test-Path $fetchHeadPath) {
                $lastFetch = (Get-Item $fetchHeadPath).LastWriteTime
                $needsFetch = ((Get-Date) - $lastFetch).TotalHours -gt 1
            }
            else {
                $needsFetch = $true
            }
        }
        else {
            $needsFetch = $true
        }

        return @{
            HasRemote = $true
            Url = $remoteUrl
            NeedsFetch = $needsFetch
        }
    }
    catch {
        return @{
            HasRemote = $false
            Url = $null
            NeedsFetch = $false
        }
    }
}

function Test-PRReadiness {
    <#
    .SYNOPSIS
        Check if branch is ready for PR
    #>
    try {
        $status = Get-ChangeStatistics
        $aheadBehind = Get-AheadBehindCount
        $lastCommit = Get-LastCommitInfo

        $checks = @{
            NoUncommittedChanges = -not $status.HasChanges
            HasCommits = $aheadBehind.Ahead -gt 0
            NotTooFarBehind = $aheadBehind.Behind -le 5
            RecentActivity = $lastCommit -and $lastCommit.Age.TotalDays -le 7
        }

        $checks.Ready = (
            $checks.NoUncommittedChanges -and
            $checks.HasCommits -and
            $checks.NotTooFarBehind
        )

        return $checks
    }
    catch {
        return @{
            Ready = $false
            NoUncommittedChanges = $false
            HasCommits = $false
            NotTooFarBehind = $false
            RecentActivity = $false
        }
    }
}

# ============================================================================
# Formatting Functions
# ============================================================================

function Format-CompactStatus {
    <#
    .SYNOPSIS
        Format compact Git status for statusline
    #>
    param($GitInfo)

    $parts = @()

    # Branch with emoji
    $parts += "🎯 $($GitInfo.Branch)"

    # Ahead/behind
    if ($GitInfo.AheadBehind.Ahead -gt 0) {
        $parts += "⚡$($GitInfo.AheadBehind.Ahead)↑"
    }
    if ($GitInfo.AheadBehind.Behind -gt 0) {
        $parts += "⬇$($GitInfo.AheadBehind.Behind)"
    }

    # Changes
    if ($GitInfo.Changes.HasChanges) {
        $changeParts = @()
        if ($GitInfo.Changes.Modified -gt 0) { $changeParts += "$($GitInfo.Changes.Modified)M" }
        if ($GitInfo.Changes.Added -gt 0) { $changeParts += "$($GitInfo.Changes.Added)A" }
        if ($GitInfo.Changes.Deleted -gt 0) { $changeParts += "$($GitInfo.Changes.Deleted)D" }
        if ($GitInfo.Changes.Untracked -gt 0) { $changeParts += "$($GitInfo.Changes.Untracked)?" }

        $parts += "📝 $($changeParts -join ' ')"
    }

    # PR readiness
    if ($GitInfo.PRReady.Ready) {
        $parts += "🔀 Ready"
    }

    return $parts -join " | "
}

function Format-DetailedStatus {
    <#
    .SYNOPSIS
        Format detailed Git status
    #>
    param($GitInfo)

    $output = @"
Git Repository Status:

Branch: $($GitInfo.Branch)
"@

    # Changes
    if ($GitInfo.Changes.HasChanges) {
        $output += "`nChanges:"
        if ($GitInfo.Changes.Staged -gt 0) {
            $output += "`n  Staged: $($GitInfo.Changes.Staged)"
        }
        if ($GitInfo.Changes.Unstaged -gt 0) {
            $output += "`n  Unstaged: $($GitInfo.Changes.Unstaged)"
        }
        if ($GitInfo.Changes.Untracked -gt 0) {
            $output += "`n  Untracked: $($GitInfo.Changes.Untracked)"
        }
    }
    else {
        $output += "`nChanges: None (clean working tree)"
    }

    # Ahead/Behind
    if ($GitInfo.AheadBehind.Ahead -gt 0 -or $GitInfo.AheadBehind.Behind -gt 0) {
        $output += "`nSync:"
        if ($GitInfo.AheadBehind.Ahead -gt 0) {
            $output += "`n  Ahead: $($GitInfo.AheadBehind.Ahead) commits"
        }
        if ($GitInfo.AheadBehind.Behind -gt 0) {
            $output += "`n  Behind: $($GitInfo.AheadBehind.Behind) commits"
        }
    }

    # Last commit
    if ($GitInfo.LastCommit) {
        $ageStr = if ($GitInfo.LastCommit.Age.TotalHours -lt 24) {
            "$([math]::Round($GitInfo.LastCommit.Age.TotalHours))h ago"
        }
        else {
            "$([math]::Round($GitInfo.LastCommit.Age.TotalDays))d ago"
        }

        $output += "`nLast Commit: $($GitInfo.LastCommit.Message) ($ageStr)"
    }

    return $output
}

function Format-PRReadinessStatus {
    <#
    .SYNOPSIS
        Format PR readiness checklist
    #>
    param($GitInfo)

    $checks = $GitInfo.PRReady

    $output = "PR Readiness Checklist:`n"
    $output += "  $(if ($checks.NoUncommittedChanges) {'✅'} else {'❌'}) No uncommitted changes`n"
    $output += "  $(if ($checks.HasCommits) {'✅'} else {'❌'}) Has commits to push`n"
    $output += "  $(if ($checks.NotTooFarBehind) {'✅'} else {'❌'}) Not too far behind (≤5 commits)`n"
    $output += "  $(if ($checks.RecentActivity) {'✅'} else {'⚠️'}) Recent activity (≤7 days)`n"
    $output += "`n"

    if ($checks.Ready) {
        $output += "✅ Ready to create PR!"
    }
    else {
        $output += "❌ Not ready for PR yet"
    }

    return $output
}

# ============================================================================
# Main Execution
# ============================================================================

try {
    # Check if Git repository
    if (-not (Test-GitRepository)) {
        Write-Output "Not a Git repository"
        exit 0
    }

    # Gather all Git info
    $gitInfo = @{
        Branch = Get-CurrentBranch
        Changes = Get-ChangeStatistics
        AheadBehind = Get-AheadBehindCount
        LastCommit = Get-LastCommitInfo
        PRReady = Test-PRReadiness
    }

    if ($IncludeRemote) {
        $gitInfo.Remote = Get-RemoteStatus
    }

    # Format output based on requested format
    $output = switch ($Format) {
        'compact' { Format-CompactStatus -GitInfo $gitInfo }
        'detailed' { Format-DetailedStatus -GitInfo $gitInfo }
        'pr-ready' { Format-PRReadinessStatus -GitInfo $gitInfo }
        default { Format-CompactStatus -GitInfo $gitInfo }
    }

    Write-Output $output
}
catch {
    Write-Error "Failed to get Git status: $_"
    exit 1
}
