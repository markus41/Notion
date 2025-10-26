# Agent Activity Logging - Quick Fix Guide

**Status**: Automatic logging is **80% operational** (Markdown ✅, JSON ✅, Notion ❌)

**Time to Fix**: **5 minutes** (3 critical steps)

---

## The Problem

Your screenshot shows agents in the session list, but they're not actually logging their work. Investigation revealed:

1. ✅ **Hook IS working** - Captures agent starts correctly
2. ❌ **Notion permissions missing** - Database not shared with integration (404 errors)
3. ❌ **No completion tracking** - Sessions stuck in "in-progress" forever
4. ⚠️ **4 stale sessions** from October 22 need cleanup

---

## Quick Fix (5 minutes)

### Step 1: Share Notion Database (2 min) 🔑 CRITICAL

```
1. Open: https://www.notion.so/72b879f213bd4edb9c59b43089dbef21
2. Click "..." menu (top-right) → Connections → Add connection
3. Select your Notion integration (API token in Key Vault as "notion-api-key")
4. Grant access
```

**Why**: Integration can't write to database without permissions. This is causing all 404 errors.

### Step 2: Clean Up Stale Sessions (2 min) 🧹

```powershell
# Preview what will be cleaned (safe)
.\.claude\scripts\Update-StaleSessions.ps1 -DryRun

# Execute cleanup (updates 4 sessions from Oct 22)
.\.claude\scripts\Update-StaleSessions.ps1
```

**What it does**:
- Finds sessions >24 hours old in "in-progress" status
- Moves them to "completed" with "timed-out" status
- Updates statistics and markdown log

### Step 3: Test End-to-End (1 min) ✅

Delegate work to any agent and verify 3-tier logging:

```bash
# Example: Test with viability-assessor
# (Use Task tool via Claude Code or slash command)

# Then check all 3 tiers received the entry:
# 1. Markdown: .claude/logs/AGENT_ACTIVITY_LOG.md (immediate)
# 2. JSON: .claude/data/agent-state.json (immediate)
# 3. Notion: https://www.notion.so/72b879f213bd4edb9c59b43089dbef21 (within 30s)
```

**Expected Result**: New session appears in all 3 locations with status "in-progress"

---

## Why Sessions Don't Complete Automatically

**Root Cause**: The hook only captures agent **START** (Task tool invocation), not **COMPLETION**.

Claude Code doesn't expose completion as a separate event, so we have two options:

### Option A: Manual Completion Logging (Recommended Now)

When agents finish meaningful work, they should log completion:

```bash
/agent:log-activity @agent-name completed "Work description with deliverables"
```

**Use for**:
- Handoffs to other agents/team members
- Blockers requiring external help
- Critical milestones needing visibility
- Work completion with key decisions

### Option B: Automatic Session Expiry (Phase 5 Enhancement)

Create scheduled task to mark inactive sessions as "timed-out" after 2 hours:

```powershell
# Future: Run hourly via Task Scheduler
.\.claude\scripts\Update-StaleSessions.ps1 -ThresholdHours 2
```

**Recommendation**: Use Option A now, implement Option B in Phase 5 for full automation.

---

## Verification Commands

### Check Hook Health
```powershell
# View recent hook activity (should show no 404 errors after Step 1)
Get-Content .\.claude\logs\auto-activity-hook.log -Tail 20
```

### Check Sync Queue
```powershell
# View queued Notion entries (should be empty or processing)
Get-Content .\.claude\data\notion-sync-queue.jsonl
```

### Check Active Sessions
```powershell
# View current active sessions
Get-Content .\.claude\data\agent-state.json | ConvertFrom-Json |
    Select-Object -ExpandProperty activeSessions | Format-Table sessionId, agentName, status, startTime
```

### Check Statistics
```powershell
# View overall activity metrics
Get-Content .\.claude\data\agent-state.json | ConvertFrom-Json |
    Select-Object -ExpandProperty statistics | Format-List
```

---

## What's Fixed

✅ **Documentation**: Comprehensive fix guide at [.claude/docs/agent-activity-logging-fix.md](.claude/docs/agent-activity-logging-fix.md)

✅ **Cleanup Script**: Automated stale session management at [.claude/scripts/Update-StaleSessions.ps1](.claude/scripts/Update-StaleSessions.ps1)

✅ **Completion Tracking**: Manual logging process documented (automatic tracking for Phase 5)

✅ **Queue-Based Sync**: Resilient Notion sync with retry logic (was already implemented, just needs permissions)

⚠️ **Requires Manual Action**: You must complete Step 1 (share database) for Notion tier to work

---

## Success Indicators

After completing Steps 1-3, you should see:

1. ✅ No more 404 errors in `.claude/logs/auto-activity-hook.log`
2. ✅ New sessions appear in Notion Agent Activity Hub within 30 seconds
3. ✅ Active sessions count is accurate (not stuck with old sessions)
4. ✅ All 3 tiers (Markdown, JSON, Notion) stay synchronized
5. ✅ Completion logging works via `/agent:log-activity`

---

## Files Created

| File | Purpose | Status |
|------|---------|--------|
| `.claude/docs/agent-activity-logging-fix.md` | Comprehensive fix documentation | ✅ Created |
| `.claude/scripts/Update-StaleSessions.ps1` | Stale session cleanup automation | ✅ Created |
| `AGENT-LOGGING-FIX-QUICKSTART.md` | This quick-start guide | ✅ Created |

---

## Next Steps After Fix

**Immediate** (today):
1. Execute Steps 1-3 above (5 minutes)
2. Verify all 3 tiers are working
3. Test manual completion logging with `/agent:log-activity`

**Short-Term** (this week):
1. Update agent guidelines to document completion logging requirements
2. Test webhook-based Notion sync (if webhook infrastructure is operational)
3. Monitor for any edge cases or issues

**Phase 5** (autonomous infrastructure):
1. Implement automatic session expiry via scheduled task
2. Investigate Claude Code extension points for automatic completion detection
3. Add session analytics dashboard to Agent Activity Hub
4. Establish ML-based session timeout predictions

---

## Support

**Still seeing issues?**
1. Review detailed documentation: [.claude/docs/agent-activity-logging-fix.md](.claude/docs/agent-activity-logging-fix.md)
2. Check hook log: `.claude/logs/auto-activity-hook.log`
3. Verify database IDs:
   - Database (page) ID: `72b879f2-13bd-4edb-9c59-b43089dbef21` ✓
   - Data Source (collection) ID: `7163aa38-f3d9-444b-9674-bde61868bd2b` ✓
4. Test Notion MCP connection via Claude Code

**Contact**: This is Phase 4 autonomous infrastructure - designed for sustainable, scalable agent activity tracking across your organization.

---

**Last Updated**: 2025-10-26 | **Version**: 1.0.0 | **Status**: Ready for execution
