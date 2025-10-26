#Requires -Version 5.1
<#
.SYNOPSIS
    Update stale agent sessions that are stuck in "in-progress" status.

.DESCRIPTION
    Establishes accurate activity tracking by identifying sessions older than a
    specified threshold (default: 24 hours) and updating them to "timed-out" status
    with appropriate metadata. Designed for organizations requiring transparent AI
    agent activity tracking to maintain workflow continuity and enable data-driven
    productivity insights.

    Best for: Maintaining accurate session state when agents don't explicitly log
    completion or encounter unexpected termination.

.PARAMETER ThresholdHours
    Number of hours after which a session is considered stale (default: 24)

.PARAMETER DryRun
    If specified, shows what would be updated without making changes

.EXAMPLE
    .\Update-StaleSessions.ps1 -DryRun
    Preview what would be updated (safe)

.EXAMPLE
    .\Update-StaleSessions.ps1
    Update stale sessions (>24 hours old)

.EXAMPLE
    .\Update-StaleSessions.ps1 -ThresholdHours 48
    Update sessions older than 48 hours

.NOTES
    Author: Brookside BI - Claude Code Integration
    Version: 1.0.0
    Last Modified: 2025-10-26
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [int]$ThresholdHours = 24,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

# Configuration
$stateFile = Join-Path $PSScriptRoot "..\data\agent-state.json"
$activityLogFile = Join-Path $PSScriptRoot "..\logs\AGENT_ACTIVITY_LOG.md"

Write-Host "`n=== Stale Session Cleanup ===" -ForegroundColor Cyan
Write-Host "Threshold: $ThresholdHours hours" -ForegroundColor Cyan
Write-Host "Mode: $(if ($DryRun) { 'DRY RUN (no changes)' } else { 'LIVE (will update)' })" -ForegroundColor $(if ($DryRun) { 'Magenta' } else { 'Yellow' })
Write-Host ""

# Validate state file exists
if (-not (Test-Path $stateFile)) {
    Write-Error "State file not found: $stateFile"
    exit 1
}

# Read current state
try {
    $state = Get-Content $stateFile -Raw | ConvertFrom-Json
}
catch {
    Write-Error "Failed to parse state file: $_"
    exit 1
}

# Calculate cutoff time
$cutoffTime = (Get-Date).AddHours(-$ThresholdHours)
Write-Host "Identifying sessions started before: $($cutoffTime.ToString('yyyy-MM-dd HH:mm:ss UTC'))" -ForegroundColor Cyan

# Find stale sessions
$staleSessions = $state.activeSessions | Where-Object {
    $_.status -eq "in-progress" -and
    [DateTime]::Parse($_.startTime) -lt $cutoffTime
}

if ($staleSessions.Count -eq 0) {
    Write-Host "`n✅ No stale sessions found. All sessions are current." -ForegroundColor Green
    exit 0
}

Write-Host "`nFound $($staleSessions.Count) stale session(s):" -ForegroundColor Yellow
foreach ($session in $staleSessions) {
    $startTime = [DateTime]::Parse($session.startTime)
    $age = (Get-Date) - $startTime
    Write-Host "  - $($session.sessionId) ($($session.agentName)): $([Math]::Round($age.TotalHours, 1)) hours old" -ForegroundColor Yellow
}

if ($DryRun) {
    Write-Host "`n🔍 DRY RUN: No changes will be made." -ForegroundColor Magenta
    Write-Host "   Run without -DryRun to apply updates." -ForegroundColor Magenta
    exit 0
}

# Confirm before proceeding
Write-Host "`n⚠️  This will update $($staleSessions.Count) session(s) to 'timed-out' status." -ForegroundColor Yellow
$confirmation = Read-Host "Proceed? (y/N)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "❌ Cancelled by user." -ForegroundColor Red
    exit 0
}

# Update stale sessions
Write-Host "`nUpdating stale sessions..." -ForegroundColor Cyan

$updatedSessions = @()

foreach ($session in $staleSessions) {
    # Calculate session duration
    $startTime = [DateTime]::Parse($session.startTime)
    $durationMinutes = [Math]::Round(((Get-Date) - $startTime).TotalMinutes, 0)

    # Update session status
    $session.status = "timed-out"
    $session.endTime = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
    $session.durationMinutes = $durationMinutes

    # Add timeout metadata
    if (-not $session.PSObject.Properties['metadata']) {
        $session | Add-Member -NotePropertyName 'metadata' -NotePropertyValue @{
            timeoutReason = "Session exceeded $ThresholdHours hour threshold without completion"
            timeoutTimestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
            originalStatus = "in-progress"
            cleanupScriptVersion = "1.0.0"
        } -Force
    }

    # Move to completed sessions
    $state.completedSessions += $session
    $updatedSessions += $session

    Write-Host "  ✅ Updated: $($session.sessionId)" -ForegroundColor Green
}

# Remove stale sessions from active list
$state.activeSessions = $state.activeSessions | Where-Object {
    $_.sessionId -notin $staleSessions.sessionId
}

# Update statistics
$state.statistics.activeSessions = $state.activeSessions.Count
$state.statistics.completedSessions = $state.completedSessions.Count
if (-not $state.statistics.PSObject.Properties['timedOutSessions']) {
    $state.statistics | Add-Member -NotePropertyName 'timedOutSessions' -NotePropertyValue 0 -Force
}
$state.statistics.timedOutSessions = ($state.completedSessions | Where-Object { $_.status -eq "timed-out" }).Count
$state.lastUpdated = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')

# Write updated state back to file
try {
    $state | ConvertTo-Json -Depth 10 | Set-Content $stateFile -ErrorAction Stop
    Write-Host "`n✅ Successfully updated $($staleSessions.Count) stale session(s)" -ForegroundColor Green
}
catch {
    Write-Error "Failed to write state file: $_"
    exit 1
}

Write-Host "   Active sessions: $($state.statistics.activeSessions)" -ForegroundColor Cyan
Write-Host "   Completed sessions: $($state.statistics.completedSessions)" -ForegroundColor Cyan
Write-Host "   Timed-out sessions: $($state.statistics.timedOutSessions)" -ForegroundColor Cyan

# Update Markdown log
Write-Host "`nUpdating Markdown log..." -ForegroundColor Cyan

# Ensure log directory exists
$logDir = Split-Path -Parent $activityLogFile
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$logUpdate = @"

---

## Stale Session Cleanup - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')

**Cleanup Summary**: Updated $($staleSessions.Count) stale session(s) that exceeded $ThresholdHours hour threshold

**Sessions Updated**:
$($updatedSessions | ForEach-Object {
    "- **$($_.sessionId)** ($($_.agentName)): $([Math]::Round(([DateTime]::Parse($_.endTime) - [DateTime]::Parse($_.startTime)).TotalHours, 1)) hours total → timed-out"
} | Out-String)

**Reason**: Sessions remained in "in-progress" status without completion logging. Marked as "timed-out" to maintain accurate activity metrics.

**Next Steps**:
- ✅ Verify agent completion logging is functioning correctly
- ✅ Ensure agents use `/agent:log-activity` for critical milestones and completions
- ⚡ Consider implementing automatic session expiry for Phase 5 automation

**Statistics After Cleanup**:
- Active sessions: $($state.statistics.activeSessions)
- Completed sessions: $($state.statistics.completedSessions)
- Timed-out sessions: $($state.statistics.timedOutSessions)
- Success rate: $([Math]::Round($state.statistics.successRate * 100, 1))%

---

"@

try {
    Add-Content -Path $activityLogFile -Value $logUpdate -ErrorAction Stop
    Write-Host "✅ Markdown log updated: $activityLogFile" -ForegroundColor Green
}
catch {
    Write-Warning "Failed to update Markdown log: $_"
}

# Summary
Write-Host "`n🎉 Stale session cleanup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "   - Sessions updated: $($staleSessions.Count)" -ForegroundColor White
Write-Host "   - Total duration cleaned: $([Math]::Round(($updatedSessions | ForEach-Object { $_.durationMinutes } | Measure-Object -Sum).Sum / 60, 1)) hours" -ForegroundColor White
Write-Host "   - Active sessions remaining: $($state.statistics.activeSessions)" -ForegroundColor White
Write-Host ""
Write-Host "📍 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Verify Notion database permissions (if Tier 1 sync failing)" -ForegroundColor White
Write-Host "   2. Test new agent delegation to ensure logging works end-to-end" -ForegroundColor White
Write-Host "   3. Review .claude/docs/agent-activity-logging-fix.md for comprehensive fixes" -ForegroundColor White
Write-Host ""
