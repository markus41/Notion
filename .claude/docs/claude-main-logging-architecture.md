# Claude Main Agent Logging Architecture

**Purpose**: Establish comprehensive activity tracking for ALL work - both Claude's direct work and delegated subagent work - to ensure transparent operation tracking and eliminate logging blind spots.

**Generated**: 2025-10-26
**Status**: Architectural Solution Design
**Priority**: High - Critical gap in current logging system

---

## Problem Statement

**Current State**: The automatic logging system only captures **subagent work** triggered via Task tool invocations.

**Gap Identified**: When Claude (main assistant) performs work directly without delegating to specialized agents, that work goes completely untracked unless manually logged.

**Impact**:
- Significant work invisible to team and stakeholders
- Incomplete activity records in Agent Activity Hub
- Manual logging burden on main agent
- Inconsistent tracking standards (automated for subagents, manual for main agent)

**Example**: Git structure documentation (35 min, 1,200 lines, 3 files created) - valuable work that would have gone unrecorded.

---

## Root Cause Analysis

### Current Hook Architecture

**Trigger**: PowerShell hook on Task tool invocation
- **Location**: [.claude/hooks/tool-call.ps1](.claude/hooks/tool-call.ps1)
- **Activation**: Only when `toolName -eq "Task"` (subagent delegation)
- **Coverage**: 38 specialized agents when invoked via Task tool
- **Blind Spot**: All work performed directly by Claude without Task tool

### Why Only Subagents Were Tracked

**Design Assumption**: Specialized agents handle most complex work
- ✅ Valid for autonomous build pipeline (research swarm, code generation, deployment)
- ✅ Valid for specialized analysis (cost analysis, viability assessment, repo scanning)
- ❌ Invalid for general work (documentation, troubleshooting, direct requests)

**Technical Constraint**: No equivalent "Claude completed work" signal
- Task tool has clear start/end lifecycle
- File operations (Read, Write, Edit) don't indicate work completion
- No native "session end" event in Claude Code

---

## Solution Options

### Option 1: Post-Session Summary Prompt (Recommended)

**Approach**: Automatically prompt Claude to log work at natural break points

**Implementation**:
```
After completing user request:
1. Detect work completion (user says "thanks", starts new topic, closes session)
2. Trigger internal prompt: "Log this session to Agent Activity Log?"
3. If yes, execute /agent:log-activity @claude-main completed [auto-summary]
4. Auto-populate deliverables from file operations during session
```

**Pros**:
- ✅ Captures all work automatically
- ✅ Minimal user disruption (background operation)
- ✅ Consistent with existing logging format
- ✅ Can infer metrics from session context (files created, time elapsed)

**Cons**:
- ⚠️ Requires Claude Code platform support (may not be immediately available)
- ⚠️ Need clear "session end" detection logic

**Effort**: Medium (2-3 hours if Claude Code adds session lifecycle hooks)

---

### Option 2: Manual Logging Protocol (Interim Solution)

**Approach**: Establish clear protocol for Claude to self-log after significant work

**Protocol**:
```
After completing work that meets criteria:
- Duration >10 minutes
- Files created/updated >2
- User request marked as complete
- Significant deliverables produced

Claude MUST execute:
/agent:log-activity @claude-main completed [work-description]
```

**Enforcement**:
- Add to [CLAUDE.md](../../CLAUDE.md) as mandatory behavior
- Include in Brookside BI brand guidelines
- Track compliance via periodic audit

**Pros**:
- ✅ Immediately implementable (today)
- ✅ No technical dependencies
- ✅ Full control over logging granularity

**Cons**:
- ❌ Relies on Claude self-discipline (not automated)
- ❌ Potential for forgotten logging
- ❌ Inconsistent with subagent automatic logging

**Effort**: Low (30 minutes to document protocol)

---

### Option 3: Git Commit Hook Integration

**Approach**: Capture work via commit messages when changes are committed

**Implementation**:
```powershell
# Enhanced commit-msg hook
# After validating commit message:

# Extract session context
$filesChanged = git diff --cached --name-only
$linesChanged = git diff --cached --stat | Select-String "insertions|deletions"

# Create activity log entry
$sessionData = @{
    agentName = "@claude-main"
    status = "completed"
    workDescription = $commitMessage
    deliverables = @{
        filesModified = $filesChanged.Count
        linesChanged = $linesChanged
    }
    triggerSource = "git-commit"
}

# Append to agent-state.json
```

**Pros**:
- ✅ Leverages existing git workflow
- ✅ Captures work when it matters (at commit time)
- ✅ No additional Claude effort required
- ✅ Ties logging to actual deliverables

**Cons**:
- ❌ Only captures work that gets committed
- ❌ Multiple commits = multiple log entries (granularity issues)
- ❌ Doesn't capture research/analysis work without file changes

**Effort**: Medium (2-4 hours to enhance commit-msg hook)

---

### Option 4: File Operation Tracking (Complex)

**Approach**: Track Write, Edit, Create operations and aggregate into sessions

**Implementation**:
```
Hook on file operations:
- Write tool → Track file created
- Edit tool → Track file modified
- Track timestamps

When session ends (user idle 5+ min):
- Aggregate all operations since last session end
- Create activity log entry with file-based deliverables
```

**Pros**:
- ✅ Fully automated
- ✅ Captures all file-based work
- ✅ No Claude effort required

**Cons**:
- ❌ Very complex to implement
- ❌ High noise (every file operation tracked)
- ❌ Difficult to determine "work complete" vs "work in progress"
- ❌ Doesn't capture non-file work (analysis, research, recommendations)

**Effort**: High (8-12 hours to build robust session detection)

---

## Recommended Implementation Plan

**Phase 1: Immediate (Today)** - Manual Protocol
1. ✅ **COMPLETED**: Document manual logging protocol in CLAUDE.md
2. ✅ **COMPLETED**: Add to agent guidelines as mandatory behavior
3. Create quick-reference card for `/agent:log-activity` usage
4. Demonstrate with git structure work (already logged)

**Phase 2: Short-term (1-2 weeks)** - Git Integration
1. Enhance commit-msg hook to capture session data
2. Add commit-time logging as secondary safety net
3. Test with real commits over 1-week period
4. Validate completeness vs. manual protocol

**Phase 3: Long-term (Phase 5)** - Platform Integration
1. Request session lifecycle hooks from Claude Code team
2. Implement post-session summary prompts
3. Transition from manual to automatic logging
4. Deprecate manual protocol once automation validates

---

## Success Metrics

**Short-term** (30 days):
- ✅ 100% of Claude work sessions logged (manual protocol compliance)
- ✅ 0 work sessions >20 minutes without activity log entry
- ✅ Agent Activity Hub shows complete work record (main + subagents)

**Medium-term** (90 days):
- ✅ Git commit integration operational
- ✅ 80% of commits auto-generate activity log entries
- ✅ Manual logging reduced by 50% through commit automation

**Long-term** (180 days):
- ✅ Platform-level session lifecycle hooks implemented
- ✅ 100% automatic logging (no manual intervention)
- ✅ Consistent tracking across all agent types

---

## Updated CLAUDE.md Protocol

**Add to Agent Guidelines Section**:

```markdown
### Claude Main Agent Logging (Mandatory)

**When to Log**:
After completing work that meets ANY of these criteria:
- Duration >10 minutes
- Files created or updated >2
- Significant deliverables produced (documentation, analysis, architecture)
- User request marked as complete with tangible outcomes

**How to Log**:
Execute `/agent:log-activity @claude-main completed [work-description]`

**What to Include**:
- Clear work description (benefit-focused, Brookside BI brand voice)
- All deliverables (files created, updated, analysis provided)
- Performance metrics (duration, lines generated, scope)
- Next steps (what should happen next)
- Related work (Ideas, Research, Builds, or projects)

**Example**:
```bash
/agent:log-activity @claude-main completed "Git structure documentation - Established comprehensive branching strategy, commit conventions, folder hierarchy, PR templates, and workflow examples"
# Then answer prompts for deliverables, metrics, next steps
```

**Compliance**: This is not optional. All significant work must be logged to maintain transparency and enable team coordination.
```

---

## Deliverables

**From This Analysis**:
1. ✅ Architectural gap diagnosed and documented
2. ✅ 4 solution options evaluated with pros/cons
3. ✅ 3-phase implementation plan created
4. ✅ Success metrics defined
5. ✅ CLAUDE.md update protocol drafted

**Next Actions**:
1. Update [CLAUDE.md](../../CLAUDE.md) with mandatory logging protocol
2. Create quick-reference card for `/agent:log-activity`
3. Track manual protocol compliance for 2 weeks
4. Begin Phase 2 git integration development

---

## Technical Specifications

### Manual Logging Template

```bash
/agent:log-activity @claude-main completed "[work-description]"

# Prompts will request:
- Deliverables: [list files, analysis, decisions made]
- Metrics: [duration, lines generated, scope covered]
- Next steps: [specific actions with owners]
- Related work: [Notion page IDs or project names]
- Trigger source: "user-request" (default for Claude main work)
```

### Git Commit Hook Enhancement (Phase 2)

```powershell
# File: .claude/hooks/commit-msg (line ~50, after validation)

# Extract commit context
$commitMessage = Get-Content $args[0]
$filesChanged = git diff --cached --name-only
$stats = git diff --cached --stat | Select-String "(\d+) insertions?\(.*?\), (\d+) deletions?"

if ($stats -match "(\d+) insertion") {
    $insertions = [int]$Matches[1]
} else {
    $insertions = 0
}

if ($stats -match "(\d+) deletion") {
    $deletions = [int]$Matches[1]
} else {
    $deletions = 0
}

# Only log if significant work (>50 lines or >3 files)
if ($insertions + $deletions -gt 50 -or $filesChanged.Count -gt 3) {
    # Queue for Notion sync
    $sessionData = @{
        sessionId = "claude-main-$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
        agentName = "@claude-main"
        status = "completed"
        workDescription = $commitMessage.Split("`n")[0]  # First line only
        deliverables = @{
            filesModified = $filesChanged.Count
            insertions = $insertions
            deletions = $deletions
        }
        queuedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        syncStatus = "pending"
        triggerSource = "git-commit"
    } | ConvertTo-Json -Compress

    Add-Content -Path ".claude\data\notion-sync-queue.jsonl" -Value $sessionData
}
```

---

**Brookside BI Innovation Nexus** - *Establishing comprehensive activity tracking to drive transparent operations and enable sustainable multi-agent coordination*

**Last Updated**: 2025-10-26
