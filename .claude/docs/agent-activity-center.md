# Agent Activity Center

**Purpose**: Establish centralized tracking for Claude Code agent work to drive transparency, workflow continuity, and productivity analytics.

**Best for**: Activity logging, team coordination, handoffs, productivity measurement, and workflow transparency.

---

## Overview

The Agent Activity Center provides 3-tier tracking for all Claude Code agent work:

1. **Notion Database** (Primary): Team-accessible source of truth with relations
2. **Markdown Log** (Reference): Human-readable chronological log
3. **JSON State** (Programmatic): Machine-readable for automation

---

## 3-Tier Tracking System

### 1. Notion Database (Primary)

**Database**: Agent Activity Hub
**Data Source ID**: `7163aa38-f3d9-444b-9674-bde61868bd2b`
**URL**: https://www.notion.so/72b879f213bd4edb9c59b43089dbef21

**Properties**:
```yaml
Activity Title: Title (AgentName - Work Description - YYYYMMDD)
Agent: Relation → Agent Registry (required)
Status: Select (In Progress | Completed | Blocked | Handed Off)
Work Description: Text
Session Start: Date & Time
Session End: Date & Time
Duration: Formula (Session End - Session Start)
Files Created: Number
Files Updated: Number
Lines Generated: Number (estimated)
Related Idea: Relation → Ideas Registry
Related Research: Relation → Research Hub
Related Build: Relation → Example Builds
Deliverables: Text (organized by category with file paths)
Next Steps: Text
Blockers: Text (if status = Blocked)
Notes: Text
```

**Benefits**:
- Team visibility into all agent work
- Relations to Ideas/Research/Builds preserve context
- Queryable for analytics and reporting
- Supports workflow continuity across sessions

### 2. Markdown Log (Reference)

**File**: `.claude/logs/AGENT_ACTIVITY_LOG.md`

**Format**:
```markdown
# Agent Activity Log

## 2025-10-26

### @cost-analyst - Quarterly Spend Analysis
**Status**: Completed
**Duration**: 35 minutes
**Session**: 10:15 AM - 10:50 AM

**Work Completed**:
- Analyzed Q4 software spending across all databases
- Identified 3 unused tools ($450/month savings opportunity)
- Generated cost optimization recommendations

**Deliverables**:
- Analysis report in Notion
- Cost reduction recommendations
- Microsoft alternatives documentation

**Next Steps**: Present findings to leadership

---
```

**Benefits**:
- Quick reference without opening Notion
- Git-versioned for history tracking
- Searchable via text search
- Supports offline access

### 3. JSON State (Programmatic)

**File**: `.claude/data/agent-state.json`

**Format**:
```json
{
  "activities": [
    {
      "id": "activity-20251026-cost-analyst",
      "agent": "@cost-analyst",
      "status": "completed",
      "description": "Quarterly spend analysis",
      "sessionStart": "2025-10-26T10:15:00Z",
      "sessionEnd": "2025-10-26T10:50:00Z",
      "duration": 35,
      "filesCreated": 0,
      "filesUpdated": 2,
      "linesGenerated": 450,
      "deliverables": ["Analysis report", "Recommendations"],
      "relatedItems": {
        "ideas": [],
        "research": [],
        "builds": []
      }
    }
  ],
  "lastUpdated": "2025-10-26T10:50:00Z"
}
```

**Benefits**:
- Machine-readable for automation
- Supports scripting and analysis
- Fast queries for metrics
- Integration with other tools

---

## Logging Operations

### Manual Logging

**Command**: `/agent:log-activity [agent-name] [status] [work-description]`

**Example**:
```bash
/agent:log-activity @cost-analyst completed "Quarterly spend analysis and optimization recommendations"
```

**What Happens**:
1. Creates Notion database entry
2. Appends to Markdown log
3. Updates JSON state
4. Links to related Notion items (if provided)

### Automatic Logging (Phase 4)

**Status**: Implemented October 22, 2025

**Architecture**:
```
Task Tool Invocation (Agent Delegation)
    ↓
Hook Trigger (.claude/hooks/auto-log-agent-activity.ps1)
    ↓
Intelligent Filtering (duration >2min, files changed, approved agents)
    ↓
@activity-logger Agent (parse deliverables, calculate metrics)
    ↓
3-Tier Update (Notion + Markdown + JSON)
```

**Components**:
- **Hook Script**: `.claude/hooks/auto-log-agent-activity.ps1`
- **Activity Logger Agent**: `@activity-logger` (specialized agent)
- **Session Parser**: `.claude/utils/session-parser.ps1`
- **Hook Configuration**: `.claude/settings.local.json` (Tool-call-hook)

#### Filtering Rules

**Only log when ALL conditions met**:
1. ✅ Agent in approved list (27+ specialized agents)
2. ✅ Work duration >2 minutes OR files created/updated
3. ✅ Not already logged in current session (5-minute deduplication)
4. ✅ TodoWrite shows meaningful work completion

**Skipped Scenarios**:
- Quick queries (<2 min, no files changed)
- Generic agents (not in approved list)
- Duplicate logging within 5-minute window

#### Auto-Captured Metrics

**File Operations**:
- Files created (categorized: Code, Docs, Infrastructure, Tests, Scripts)
- Files updated (with paths)
- Lines generated (estimated from file sizes)

**Session Data**:
- Start time (Task tool invocation)
- End time (agent completion)
- Duration (calculated)

**Deliverables** (organized by category):
- Code files (*.py, *.ts, *.cs, *.js)
- Documentation (*.md, *.txt)
- Infrastructure (*.bicep, *.tf, *.yaml)
- Tests (*.test.*, *.spec.*)
- Scripts (*.ps1, *.sh)

**Context**:
- Related Notion items (Ideas, Research, Builds)
- Work description (from TodoWrite)
- Next steps (inferred from context)

---

## Activity Reports

### Generate Summary

**Command**: `/agent:activity-summary [timeframe] [agent-name]`

**Timeframes**: `today`, `week`, `month`, `all`

**Example**:
```bash
# All activity today
/agent:activity-summary today

# Specific agent this week
/agent:activity-summary week @cost-analyst

# All agents this month
/agent:activity-summary month
```

**Output**:
```markdown
## Agent Activity Summary (October 2025)

**Total Sessions**: 47
**Total Duration**: 18.5 hours
**Files Created**: 23
**Files Updated**: 64
**Lines Generated**: ~12,400

### Top Agents by Activity
1. @build-architect - 12 sessions (5.2 hours)
2. @cost-analyst - 8 sessions (3.1 hours)
3. @research-coordinator - 7 sessions (2.8 hours)

### Key Deliverables
- 5 new builds deployed to Azure
- 3 research threads completed
- 2 cost optimization initiatives
- 1 knowledge vault archival

### Status Breakdown
- Completed: 42 (89%)
- In Progress: 3 (7%)
- Blocked: 2 (4%)
```

---

## Status Workflow

### Status Progression

```
In Progress → Completed / Blocked / Handed Off
```

**Status Definitions**:
- **In Progress**: Agent actively working on task
- **Completed**: Work finished successfully
- **Blocked**: Waiting for external input/decision
- **Handed Off**: Transferred to another agent or team member

### When to Update Status

**In Progress**:
- Set automatically when agent starts work (via automatic logging)
- Remains until work completes or blocks

**Completed**:
- Agent finishes all deliverables
- Tests pass (if applicable)
- No blockers remaining

**Blocked**:
- Missing information needed to proceed
- Waiting for external dependency
- Technical blocker requires investigation
- **Always document blocker in Notes field**

**Handed Off**:
- Work transferred to another agent
- Context documented for continuity
- New agent assigned

---

## Handoff Procedures

### When Handing Off Work

**Required Information**:
1. **Context**: What was the original request?
2. **Progress**: What's been completed so far?
3. **Blockers**: Any issues or dependencies?
4. **Next Steps**: What needs to happen next?
5. **Files**: Links to all relevant documentation/code
6. **Decisions**: Key decisions made and rationale

**Process**:
1. Update Agent Activity Hub status to "Handed Off"
2. Add comprehensive handoff notes
3. Create new activity entry for receiving agent
4. Link both activities for continuity
5. Direct message receiving team member

**Example Handoff**:
```markdown
## Handoff: AI Cost Optimizer Research

**From**: @research-coordinator (Markus Ahling)
**To**: @cost-analyst (Brad Wright)
**Date**: 2025-10-26

**Context**: Research on AI-powered Azure cost optimization platform.
Technical feasibility confirmed (90/100 viability).

**Progress Completed**:
- ✅ Market research (competitor analysis)
- ✅ Technical architecture designed
- ✅ Azure services identified

**Next Steps** (assigned to @cost-analyst):
1. Detailed cost-benefit analysis
2. ROI projections (1-year, 3-year)
3. Pricing model recommendation
4. Go-to-market cost structure

**Relevant Files**:
- Research Hub: [Link]
- Origin Idea: [Link]
- Architecture diagram: [Link]

**Blockers**: None

**Decisions Made**:
- Azure Functions for compute (cost efficiency)
- Cosmos DB for data storage (flexible schema)
```

---

## Productivity Analytics

### Key Metrics

**Agent Utilization**:
- Sessions per week/month
- Average session duration
- Files generated per session
- Completion rate

**Work Distribution**:
- Agent activity breakdown
- Team member assignments
- Specialization alignment

**Efficiency**:
- Time to completion
- Blocker resolution time
- Handoff success rate

**Quality**:
- Deliverable completeness
- Rework instances
- User satisfaction (if tracked)

### Analytics Queries

**Notion Formula Examples**:
```
# Average session duration
rollup(Agent Activity Hub, Duration, average)

# Completion rate
count(Status = Completed) / count(All Activities) * 100

# Files per session
rollup(Agent Activity Hub, Files Created + Files Updated, average)
```

**PowerShell Script**: `.claude/utils/agent-analytics.ps1`
```powershell
# Generate monthly analytics report
.\utils\agent-analytics.ps1 -Month 10 -Year 2025
```

---

## Phase 4 Enhancements

### Implemented (October 2025)

✅ **Automatic Activity Logging**
- Hook-based capture on Task tool invocations
- Intelligent filtering (approved agents, duration, file changes)
- Zero manual overhead for agents

✅ **Comprehensive Metrics**
- File operations categorized
- Lines generated estimated
- Deliverables organized by type
- Context preserved (related Notion items)

### Phase 2 Enhancements (Planned)

🔮 **Machine Learning Duration Prediction**
- Predict session duration based on task description
- Flag unusually long sessions for review

🔮 **Anomaly Detection**
- Identify patterns in blocked work
- Detect efficiency degradation

🔮 **Automated Cost Attribution**
- Link agent work to Azure resource costs
- Calculate ROI per agent/project

🔮 **Real-Time Activity Dashboard**
- Live view of agent activity
- Team workload visualization
- Blocker alerts

🔮 **Quality Scoring**
- Automated assessment of deliverables
- Feedback loop for agent improvement

---

## Best Practices

### ✅ DO

- **Log Significant Work**: Sessions >2 minutes or with file changes
- **Provide Context**: Link to related Ideas/Research/Builds
- **Document Blockers**: Clearly explain what's blocking progress
- **Update Status Promptly**: Reflect current work state
- **Complete Handoffs**: Provide full context for continuity

### ❌ DON'T

- **Log Trivial Tasks**: Quick queries or minor edits
- **Skip Relations**: Always link to related Notion items
- **Leave Status Stale**: Update when work state changes
- **Incomplete Handoffs**: Missing context causes delays
- **Ignore Blockers**: Document and escalate promptly

---

## Troubleshooting

### Common Issues & Quick Fixes

#### Issue: Agents Not Logging to Notion (404 Errors)

**Symptoms**:
- Markdown and JSON tiers work correctly
- Notion tier shows 404 errors in logs
- Pages not appearing in Agent Activity Hub

**Root Cause**: Notion database not shared with integration

**Fix** (2 minutes):
```
1. Open: https://www.notion.so/72b879f213bd4edb9c59b43089dbef21
2. Click "..." menu (top-right) → Connections → Add connection
3. Select your Notion integration (API token: kv-brookside-secrets/notion-api-key)
4. Grant access
```

**→ See [Webhook README: Notion Workspace Configuration](../../azure-functions/notion-webhook/README.md#notion-workspace-configuration) for complete setup instructions including integration creation, database verification, and testing**

**Verification**:
```powershell
# Check hook logs for successful sync
Get-Content .\.claude\logs\auto-activity-hook.log -Tail 20
# Should show no 404 errors after fix
```

---

#### Issue: Stale Sessions Stuck "In Progress"

**Symptoms**:
- Sessions show "in-progress" status for days
- Active sessions count inflated
- Old sessions from October 22+ never completed

**Root Cause**: Hook captures START only, not completion

**Fix** (2 minutes):
```powershell
# Preview stale sessions (safe check)
.\.claude\scripts\Update-StaleSessions.ps1 -DryRun

# Clean up sessions >24 hours old
.\.claude\scripts\Update-StaleSessions.ps1

# Custom threshold (e.g., 2 hours)
.\.claude\scripts\Update-StaleSessions.ps1 -ThresholdHours 2
```

**Prevention**: Use manual completion logging for meaningful work:
```bash
/agent:log-activity @agent-name completed "Work description with deliverables"
```

---

#### Issue: Webhook Sync Failing

**Symptoms**:
- Queue entries with `webhookSynced=false`
- Delays in Notion page creation (5-15 min instead of <30 sec)
- Webhook error messages in logs

**Diagnostic**:
```powershell
# Check webhook endpoint health
.\.claude\utils\webhook-utilities.ps1 -Operation HealthCheck -WebhookSecret $(az keyvault secret show --vault-name kv-brookside-secrets --name notion-webhook-secret --query value -o tsv)

# Check Azure Function status
az functionapp show --name notion-webhook-brookside-prod --resource-group rg-brookside-innovation --query "{State:state, DefaultHostName:defaultHostName}"
```

**Common Fixes**:
1. **Function not deployed**: Deploy via `infrastructure/DEPLOYMENT-MANUAL.md` steps
2. **Cold start timeout**: First request after idle takes 2-5 sec (normal)
3. **Invalid signature**: Verify webhook secret matches Key Vault value
4. **Azure outage**: Queue fallback ensures zero data loss

---

#### Issue: Missing Session Data in Notion

**Symptoms**:
- Session ID created but properties empty
- "Work Description" or "Agent Name" missing
- Incomplete activity records

**Root Cause**: Agent didn't trigger completion criteria

**Automatic Logging Criteria** (ALL must be met):
- ✅ Agent in approved list (38 specialized agents)
- ✅ Work duration >2 minutes OR files created/updated
- ✅ Not already logged in current session (5-min deduplication)
- ✅ TodoWrite shows meaningful work completion

**Manual Override**:
```bash
# When criteria not met but work is valuable
/agent:log-activity @agent-name completed "Detailed work description with specific deliverables and decisions"
```

---

### Verification Commands

**Check Hook Health**:
```powershell
# View recent hook executions
Get-Content .\.claude\logs\auto-activity-hook.log -Tail 50

# Look for:
# ✅ "Successfully captured agent activity"
# ✅ "Successfully synced via webhook"
# ❌ "ERROR" or "404" messages
```

**Check Sync Queue**:
```powershell
# View pending Notion entries
Get-Content .\.claude\data\notion-sync-queue.jsonl

# Empty file = all synced
# Entries present = waiting for processor or webhook retry
```

**Check Active Sessions**:
```powershell
# View current sessions in JSON state
Get-Content .\.claude\data\agent-state.json | ConvertFrom-Json |
    Select-Object -ExpandProperty activeSessions |
    Format-Table sessionId, agentName, status, startTime
```

**Check Overall Statistics**:
```powershell
# View metrics
Get-Content .\.claude\data\agent-state.json | ConvertFrom-Json |
    Select-Object -ExpandProperty statistics | Format-List

# Key metrics:
# - totalSessions: All-time session count
# - activeSessions: Currently in-progress (should be low)
# - completedSessions: Successfully finished work
```

---

### Database ID Verification

If Notion integration fails, verify correct database IDs:

**Agent Activity Hub**:
- **Database (page) ID**: `72b879f2-13bd-4edb-9c59-b43089dbef21` ✓
- **Data Source (collection) ID**: `7163aa38-f3d9-444b-9674-bde61868bd2b` ✓
- **URL**: https://www.notion.so/72b879f213bd4edb9c59b43089dbef21

**Verification**:
```powershell
# Test Notion MCP connection
# In Claude Code, ask: "Use Notion MCP to fetch the Agent Activity Hub database"
# Should return database properties without errors
```

---

### Support & Escalation

**Quick Fixes (5-10 minutes)**:
1. Share Notion database with integration (most common issue)
2. Clean up stale sessions via Update-StaleSessions.ps1
3. Verify webhook secret matches Key Vault

**Detailed Troubleshooting**:
- Review comprehensive fix guide: [.claude/docs/agent-activity-logging-fix.md](.claude/docs/agent-activity-logging-fix.md)
- Check webhook architecture: [.claude/docs/webhook-architecture.md](.claude/docs/webhook-architecture.md)
- Review queue processor logs: [.claude/logs/notion-queue-processor.log](.claude/logs/notion-queue-processor.log)

**Still Blocked?**
- Consultations@BrooksideBI.com | +1 209 487 2047
- Reference: Phase 4 Autonomous Infrastructure implementation

---

## Related Resources

**Databases**:
- [Agent Activity Hub](https://www.notion.so/72b879f213bd4edb9c59b43089dbef21)
- [Agent Registry](https://www.notion.so/Agent-Registry-5863265b-eeee-45fc-ab1a-4206d8a523c6)

**Files**:
- [AGENT_ACTIVITY_LOG.md](./../logs/AGENT_ACTIVITY_LOG.md)
- [agent-state.json](./../data/agent-state.json)
- [auto-log-agent-activity.ps1](./../hooks/auto-log-agent-activity.ps1)

**Documentation**:
- [Innovation Workflow](./innovation-workflow.md)
- [Team Structure](./team-structure.md)
- [Success Metrics](./success-metrics.md)
- [Webhook Architecture](./webhook-architecture.md)
- [Agent Activity Logging Fix](./../docs/agent-activity-logging-fix.md)

---

**Last Updated**: 2025-10-26
