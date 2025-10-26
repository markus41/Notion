# Agent Activity Logging Fix Guide

**Issue Summary**: Automatic agent activity logging is partially working (Markdown + JSON) but failing to sync to Notion due to database permissions and missing completion tracking.

**Status**: 3 critical issues identified with comprehensive solutions provided below.

---

## Issue 1: Notion Database Permissions ⚠️ CRITICAL

### Problem
The Notion integration doesn't have access to the Agent Activity Hub database, causing all Notion sync attempts to fail with error 404.

### Evidence
```
[2025-10-22 05:08:20] [WARNING] Failed to create Notion entry:
{"object":"error","status":404","code":"object_not_found",
"message":"Could not find database with ID: 7163aa38-f3d9-444b-9674-bde61868bd2b.
Make sure the relevant pages and databases are shared with your integration."}
```

### Solution (2 minutes)

1. **Open Agent Activity Hub in Notion**:
   - Navigate to: https://www.notion.so/72b879f213bd4edb9c59b43089dbef21

2. **Share with Integration**:
   - Click "..." menu (top-right) → "Connections" → "Add connection"
   - Select your Notion integration (the one whose API token is in Key Vault as `notion-api-key`)
   - Grant access to the database

3. **Verify Access**:
   ```powershell
   # Test Notion MCP access
   # This should return database schema without errors
   # (Use Claude Code with Notion MCP to test fetch operation)
   ```

4. **Expected Result**:
   - ✅ Future agent sessions sync to Notion automatically
   - ✅ Queue processor can retry failed entries

---

## Issue 2: No Completion Tracking ⏱️ HIGH PRIORITY

### Problem
The hook only fires when agents START (Task tool invocation), never when they COMPLETE. This causes sessions to remain stuck in "in-progress" status indefinitely.

**Evidence**: 4+ sessions from October 22 still marked "in-progress" on October 26.

### Root Cause
The hook configuration in `.claude/settings.local.json` only triggers on `Task` tool calls:
```json
{
  "match": {
    "tools": ["Task"],
    "pattern": ".*"
  }
}
```

This captures agent delegation but misses completion. Claude Code doesn't expose agent completion as a separate event.

### Solution Options

#### Option A: Manual Completion Logging (Recommended for Now)
Agents should explicitly log completion using `/agent:log-activity`:

```bash
# When agent completes work
/agent:log-activity @agent-name completed "Work description with deliverables and outcomes"
```

**Best Practice**: Update agent guidelines to require completion logging for:
- Handoffs to other agents/team members
- Blockers requiring external help
- Critical milestones needing visibility
- Work completion with key decisions

#### Option B: Automatic Session Expiry (Future Enhancement)
Add a scheduled task to mark sessions as "timed-out" if inactive >2 hours:

```powershell
# .claude/utils/expire-stale-sessions.ps1 (TO BE CREATED)
# Run hourly via Task Scheduler or cron
```

#### Option C: Response-Based Completion Detection (Complex)
Hook into agent response completion - requires Claude Code extension point that may not exist yet.

### Immediate Action
**For now**: Use Option A (manual `/agent:log-activity` on completion) while we investigate Option B/C for Phase 5 automation.

---

## Issue 3: Queue Processing & Retry Logic 📋 MEDIUM PRIORITY

### Problem
The Notion sync queue (`.claude/data/notion-sync-queue.jsonl`) is empty, suggesting:
- Entries are failing silently due to permissions (Issue #1)
- OR queue processor hasn't been run

### Solution

1. **Fix permissions first** (Issue #1)

2. **Run queue processor manually**:
   ```powershell
   # Process any queued entries
   .\.claude\utils\process-notion-queue.ps1
   ```

3. **Verify queue processing**:
   - Check queue file is empty: `.claude/data/notion-sync-queue.jsonl`
   - Check hook log for success: `.claude/logs/auto-activity-hook.log`
   - Verify entries appear in Notion Agent Activity Hub

4. **Expected Result**:
   - ✅ Historical queued entries sync to Notion
   - ✅ Future entries sync in real-time via webhook (if webhook is operational)
   - ✅ Queue provides resilience for transient failures

---

## Clean Up Stale Sessions

### Problem
Sessions from October 22 are stuck in "in-progress" with no way to complete them.

### Solution Script

Create `.claude/scripts/Update-StaleSessions.ps1`:

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Update stale agent sessions that are stuck in "in-progress" status.

.DESCRIPTION
    This script identifies sessions older than a specified threshold (default: 24 hours)
    and updates them to "timed-out" status with appropriate metadata.

.PARAMETER ThresholdHours
    Number of hours after which a session is considered stale (default: 24)

.PARAMETER DryRun
    If specified, shows what would be updated without making changes
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

# Validate state file exists
if (-not (Test-Path $stateFile)) {
    Write-Error "State file not found: $stateFile"
    exit 1
}

# Read current state
$state = Get-Content $stateFile -Raw | ConvertFrom-Json

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
    exit 0
}

# Update stale sessions
Write-Host "`nUpdating stale sessions..." -ForegroundColor Cyan

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
        }
    }

    # Move to completed sessions
    $state.completedSessions += $session

    Write-Host "  ✅ Updated: $($session.sessionId)" -ForegroundColor Green
}

# Remove stale sessions from active list
$state.activeSessions = $state.activeSessions | Where-Object {
    $_.sessionId -notin $staleSessions.sessionId
}

# Update statistics
$state.statistics.activeSessions = $state.activeSessions.Count
$state.statistics.completedSessions = $state.completedSessions.Count
$state.statistics.timedOutSessions = ($state.completedSessions | Where-Object { $_.status -eq "timed-out" }).Count
$state.lastUpdated = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')

# Write updated state back to file
$state | ConvertTo-Json -Depth 10 | Set-Content $stateFile

Write-Host "`n✅ Successfully updated $($staleSessions.Count) stale session(s)" -ForegroundColor Green
Write-Host "   Active sessions: $($state.statistics.activeSessions)" -ForegroundColor Cyan
Write-Host "   Completed sessions: $($state.statistics.completedSessions)" -ForegroundColor Cyan
Write-Host "   Timed-out sessions: $($state.statistics.timedOutSessions)" -ForegroundColor Cyan

# Update Markdown log
Write-Host "`nUpdating Markdown log..." -ForegroundColor Cyan

$logUpdate = @"

---

## Stale Session Cleanup - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')

**Cleanup Summary**: Updated $($staleSessions.Count) stale session(s) that exceeded $ThresholdHours hour threshold

**Sessions Updated**:
$($staleSessions | ForEach-Object {
    "- $($_.sessionId) ($($_.agentName)): $([Math]::Round(([DateTime]::Now - [DateTime]::Parse($_.startTime)).TotalHours, 1)) hours old → timed-out"
} | Out-String)

**Reason**: Sessions remained in "in-progress" status without completion logging. Marked as "timed-out" to maintain accurate activity metrics.

**Next Steps**:
- Verify agent completion logging is functioning correctly
- Ensure agents use `/agent:log-activity` for critical milestones and completions
- Consider implementing automatic session expiry for Phase 5 automation

---

"@

Add-Content -Path $activityLogFile -Value $logUpdate

Write-Host "✅ Markdown log updated: $activityLogFile" -ForegroundColor Green

Write-Host "`n🎉 Stale session cleanup complete!" -ForegroundColor Green
```

**Usage**:
```powershell
# Preview what would be updated (safe)
.\.claude\scripts\Update-StaleSessions.ps1 -DryRun

# Actually update stale sessions (>24 hours old)
.\.claude\scripts\Update-StaleSessions.ps1

# Update sessions older than 48 hours
.\.claude\scripts\Update-StaleSessions.ps1 -ThresholdHours 48
```

---

## Verification Checklist

After implementing fixes, verify each tier is working:

### ✅ Tier 1: Notion Database
```powershell
# 1. Verify integration has access
# (Open Notion → Agent Activity Hub → Check "Connections" includes your integration)

# 2. Test Notion MCP access via Claude Code
# (Use mcp__notion__notion-fetch with database ID)

# 3. Check Agent Activity Hub for recent entries
# https://www.notion.so/72b879f213bd4edb9c59b43089dbef21
```

### ✅ Tier 2: Markdown Log
```powershell
# Verify recent entries exist
Get-Content .\.claude\logs\AGENT_ACTIVITY_LOG.md -Tail 50
```

### ✅ Tier 3: JSON State
```powershell
# Verify statistics are current
Get-Content .\.claude\data\agent-state.json | ConvertFrom-Json |
    Select-Object -ExpandProperty statistics | Format-List
```

### ✅ Hook Execution
```powershell
# Check recent hook activity
Get-Content .\.claude\logs\auto-activity-hook.log -Tail 20

# Should show "Successfully updated Markdown log" and "Successfully updated JSON state"
# Should NOT show "404" errors for Notion after permissions fix
```

### ✅ End-to-End Test
```powershell
# 1. Delegate work to a test agent
# (Use Claude Code Task tool with any approved agent)

# 2. Verify entry appears in all 3 tiers:
#    - Markdown log (immediate)
#    - JSON state (immediate)
#    - Notion database (within 30 seconds via webhook, or via queue processor)

# 3. Complete the session manually
/agent:log-activity @test-agent completed "Test session completed successfully"

# 4. Verify status updated to "completed" in JSON state and Notion
```

---

## Summary of Actions

**Immediate (5 minutes)**:
1. ✅ Share Agent Activity Hub database with Notion integration
2. ✅ Run `.claude/scripts/Update-StaleSessions.ps1` to clean up October 22 sessions
3. ✅ Test Notion sync with new agent delegation
4. ✅ Verify all 3 tiers are receiving updates

**Short-Term (Phase 4 continuation)**:
1. Document completion logging requirements in agent guidelines
2. Create scheduled task for automatic session expiry (`.claude/utils/expire-stale-sessions.ps1`)
3. Monitor webhook latency vs. queue processor performance
4. Consider retention policy for completed sessions (archive after 90 days)

**Long-Term (Phase 5)**:
1. Investigate Claude Code extension points for automatic completion detection
2. Implement ML-based session timeout predictions (predict completion time based on work description)
3. Add session analytics dashboard to Agent Activity Hub
4. Establish cross-repository activity tracking (agent work across multiple projects)

---

## Support

**If issues persist**:
1. Check `.claude/logs/auto-activity-hook.log` for detailed error messages
2. Verify Notion integration token is valid (test with Notion MCP)
3. Confirm database IDs match:
   - Database (page) ID: `72b879f2-13bd-4edb-9c59-b43089dbef21`
   - Data Source (collection) ID: `7163aa38-f3d9-444b-9674-bde61868bd2b`
4. Review webhook status (if using webhook-based sync): `.claude/docs/webhook-architecture.md`

**Last Updated**: 2025-10-26
**Version**: 1.0.0
**Status**: Production-ready fixes for Phase 4 autonomous infrastructure
