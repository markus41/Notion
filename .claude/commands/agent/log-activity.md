# Agent Activity Logger - Slash Command

**Purpose**: Streamline agent work logging across all 3 tracking tiers (Notion, Markdown, JSON) to establish transparent activity tracking and enable seamless agent handoffs.

**Best for**: Specialized agents completing work who need to document progress, communicate next steps, and facilitate workflow continuity.

---

## Command Syntax

```bash
/agent:log-activity [agent-name] [status] [work-description]
```

**Parameters:**
- `agent-name` (required): Name of the agent (e.g., `@markdown-expert`, `@cost-analyst`)
- `status` (required): Current status - `in-progress`, `completed`, `blocked`, `handed-off`
- `work-description` (required): Brief description of work accomplished or in progress

**Examples:**
```bash
/agent:log-activity @markdown-expert completed "Documentation audit of 147 markdown files"
/agent:log-activity @cost-analyst in-progress "Monthly software spend analysis"
/agent:log-activity @build-architect blocked "Azure OpenAI resource provisioning"
```

---

## What This Command Does

**Automated 3-Tier Logging:**

1. **Tier 1 - Notion Database** (Primary Source of Truth)
   - Creates or updates entry in "🤖 Agent Activity Hub" database
   - Populates all properties: Status, Duration, Deliverables, Metrics
   - Links to related Ideas/Research/Builds if applicable
   - Database ID: `[To be created]`

2. **Tier 2 - Markdown Log** (Quick Reference)
   - Appends formatted entry to `.claude/logs/AGENT_ACTIVITY_LOG.md`
   - Places in "Active Sessions" section if `in-progress` or `blocked`
   - Moves to "Completed Sessions" when status = `completed` or `handed-off`
   - Updates activity summary statistics

3. **Tier 3 - JSON State** (Programmatic Access)
   - Updates `.claude/data/agent-state.json`
   - Adds to `activeSessions` array if in progress
   - Moves to `completedSessions` array when done
   - Updates global statistics counters

**Session ID Generation:**
- Format: `agent-name-YYYY-MM-DD-HHMM`
- Example: `cost-analyst-2025-10-21-1630`
- Ensures uniqueness and chronological ordering

---

## Interactive Prompts

The command will guide you through required information:

**For All Sessions:**
1. Deliverables (files, database entries, outcomes)
2. Next steps (specific actions with owners if known)
3. Performance metrics (duration, files created/updated, etc.)
4. Related work (Idea ID, Research ID, Build ID, Workflow ID)

**For Blocked Status:**
- Blocker description
- Severity: Low | Medium | High | Critical
- Impact on workflow
- Escalation contact or action needed

**For Handed Off Status:**
- Next agent name
- Handoff context (what they need to know)
- Handoff dependencies (files, data, state required)

**For Completed Status:**
- Final outcome summary
- Measurable impact delivered
- Quality metrics (brand voice compliance, technical accuracy, etc.)

---

## Session Status Workflow

```
┌─────────────┐
│ In Progress │ ◄─── Initial state when work begins
└──────┬──────┘
       │
       ├──► ┌───────────┐
       │    │ Completed │  All deliverables finished, ready for closure
       │    └───────────┘
       │
       ├──► ┌─────────┐
       │    │ Blocked │  Cannot proceed, waiting for resolution
       │    └─────────┘
       │
       └──► ┌─────────────┐
            │ Handed Off  │  Work passed to another specialized agent
            └─────────────┘
```

**Status Definitions:**

- **In Progress**: Work actively underway, agent has not completed all deliverables
- **Completed**: All deliverables finished, next steps documented, no blockers
- **Blocked**: Work cannot proceed due to external dependency, escalation identified
- **Handed Off**: Work passed to another agent with context and dependencies

---

## Output Format

After execution, the command will:

1. **Confirm Session Created:**
   ```
   ✅ Session logged: cost-analyst-2025-10-21-1630
   📊 Status: In Progress
   📝 Work: Monthly software spend analysis
   ```

2. **Display Tracking Locations:**
   ```
   Updated 3 tracking tiers:
   ✓ Notion: 🤖 Agent Activity Hub (entry created)
   ✓ Markdown: .claude/logs/AGENT_ACTIVITY_LOG.md (entry appended)
   ✓ JSON: .claude/data/agent-state.json (state updated)
   ```

3. **Show Next Steps** (if provided):
   ```
   Next Steps:
   1. Review findings with leadership for approval
   2. Cancel 3 identified unused tools (immediate $400/month savings)
   3. Migrate Slack → Microsoft Teams (3-month timeline)
   ```

4. **Alert on Blockers** (if status = `blocked`):
   ```
   ⚠️ BLOCKER DETECTED
   Severity: High
   Impact: Cannot provision Azure OpenAI resource due to quota limit
   Escalation: Contact Azure administrator to request quota increase
   ```

5. **Confirm Handoff** (if status = `handed-off`):
   ```
   🔄 Work handed off to: @workflow-router
   Context: Cost optimization approved, need team assignments for migration
   Dependencies: Leadership approval (expected within 48 hours)
   ```

---

## Updating Existing Sessions

**To update a session status:**

```bash
# Transition from In Progress → Completed
/agent:log-activity @cost-analyst completed "Monthly software spend analysis"

# Same session ID will be matched, entry will be updated
# Markdown entry moved from Active → Completed
# JSON entry moved from activeSessions → completedSessions
# Notion entry status updated
```

**Matching Logic:**
- Command searches for most recent session with matching agent name
- If found within last 24 hours and status was `in-progress` or `blocked`, updates that session
- Otherwise, creates new session

---

## Integration with Innovation Nexus

**Automatic Relation Linking:**

When you provide work context, the command will:

1. **Search Ideas Registry** if you mention an idea
2. **Search Research Hub** if you mention research
3. **Search Example Builds** if you mention a build
4. **Link Software Tracker** if you mention tools/costs

**Example:**
```bash
/agent:log-activity @build-architect completed "Azure OpenAI integration prototype"

# Command will:
# - Search Example Builds for "Azure OpenAI integration"
# - Link found build to agent activity entry
# - Populate "Related Work" section automatically
```

---

## Best Practices

**When to Log:**
- ✅ Immediately when starting new work (status: in-progress)
- ✅ When encountering blockers (status: blocked)
- ✅ When completing deliverables (status: completed)
- ✅ When handing off to another agent (status: handed-off)
- ✅ At significant milestones during long-running work

**What to Include:**
- ✅ Specific deliverables (file paths, database entries, URLs)
- ✅ Actionable next steps with owners when known
- ✅ Quantifiable metrics (files created, lines generated, time saved)
- ✅ Links to related Innovation Nexus items
- ✅ Blocker severity and impact if blocked

**What to Avoid:**
- ❌ Vague descriptions ("updated some files")
- ❌ Missing next steps
- ❌ Forgetting to update status when work completes
- ❌ Logging without actual work progress
- ❌ Omitting handoff context when delegating

---

## Error Handling

**Common Issues:**

1. **Agent name not recognized:**
   ```
   ⚠️ Unknown agent: @invalid-agent
   Did you mean: @cost-analyst, @markdown-expert, @build-architect?
   ```

2. **Invalid status:**
   ```
   ⚠️ Invalid status: "done"
   Valid options: in-progress, completed, blocked, handed-off
   ```

3. **Notion database not created yet:**
   ```
   ⚠️ Notion database "🤖 Agent Activity Hub" not found
   Logging to Markdown and JSON only. Create database to enable Notion tracking.
   ```

4. **Missing required fields:**
   ```
   ⚠️ Work description is required
   Usage: /agent:log-activity [agent-name] [status] [work-description]
   ```

---

## Performance Metrics Tracked

**Automatically Calculated:**
- Duration (start to completion timestamp)
- Files Created (count)
- Files Updated (count)
- Lines Generated (if applicable)
- Success Rate (% of tasks completed vs. total)
- Tokens Used (if available from API)

**Custom Metrics** (agent-specific):
- @cost-analyst: Potential savings identified, tools analyzed
- @markdown-expert: Files audited, quality score
- @build-architect: Architecture decisions documented, deployments
- @knowledge-curator: Knowledge Vault entries created, reusability score

---

## Related Commands

- `/agent:activity-summary [timeframe] [agent]` - View activity summaries
- `/agent:handoff-queue` - See pending handoffs requiring attention
- `/agent:blocker-report` - List all blocked sessions with escalation paths

---

## Technical Implementation

**File Locations:**
- Notion Database: `🤖 Agent Activity Hub` (database ID: TBD)
- Markdown Log: `.claude/logs/AGENT_ACTIVITY_LOG.md`
- JSON State: `.claude/data/agent-state.json`
- Template: `.claude/utils/log-agent-activity.md`

**Agents Involved:**
- This command delegates to appropriate logging agent based on context
- May invoke `@notion-mcp-specialist` for database operations
- May invoke `@markdown-expert` for log formatting

**Data Persistence:**
- Markdown: Append-only, never deletes entries
- JSON: Active sessions array, completed sessions array
- Notion: Primary source of truth, editable by team

---

## Example Workflow

**Complete Session Lifecycle:**

```bash
# Step 1: Start work
/agent:log-activity @cost-analyst in-progress "Analyzing Q4 software spend"

# Output:
# ✅ Session logged: cost-analyst-2025-10-21-1630
# 📊 Status: In Progress
# [Prompts for deliverables, next steps, etc.]

# Step 2: Work continues...
# [Agent performs analysis]

# Step 3: Encounter blocker
/agent:log-activity @cost-analyst blocked "Analyzing Q4 software spend"

# Output:
# ⚠️ Session updated: cost-analyst-2025-10-21-1630
# 📊 Status: Blocked
# [Prompts for blocker details, severity, escalation]

# Step 4: Blocker resolved, work resumes
/agent:log-activity @cost-analyst in-progress "Analyzing Q4 software spend"

# Step 5: Complete work
/agent:log-activity @cost-analyst completed "Analyzing Q4 software spend"

# Output:
# ✅ Session completed: cost-analyst-2025-10-21-1630
# ⏱️ Duration: 47 minutes
# 📊 Status: Completed
# [Prompts for final outcomes, impact, quality metrics]
```

---

**🤖 Maintained for Brookside BI Innovation Nexus Agent Ecosystem**

**Best for**: Organizations requiring transparent AI agent workflows with systematic activity tracking, seamless handoffs, and institutional knowledge preservation to drive measurable outcomes through structured agent coordination.
