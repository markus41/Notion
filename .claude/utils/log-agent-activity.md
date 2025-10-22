# Agent Activity Logger - Template & Instructions

**Purpose**: Standardized template for Claude Code agents to log their work across all 3 tracking tiers (Notion, Markdown, JSON) to establish continuity, enable handoffs, and maintain institutional memory.

**Best for**: Specialized agents completing work in the Innovation Nexus ecosystem who need to document progress, communicate next steps, and facilitate seamless handoffs to other agents.

---

## Quick Log Template

Use this template when logging agent activity:

```markdown
### Session: [Generate ID: agent-name-YYYY-MM-DD-HHMM]

**Agent**: [@agent-name]
**Status**: [In Progress | Completed | Blocked | Handed Off]
**Started**: [YYYY-MM-DD HH:MM:SS UTC]
**Completed**: [YYYY-MM-DD HH:MM:SS UTC | N/A if in progress]
**Duration**: [X minutes Y seconds | Estimated if in progress]

#### Work Description

[1-2 sentence summary of work accomplished or in progress]

**Command/Trigger**: [Slash command or manual invocation that started this work]

#### Deliverables

- [File, database entry, or outcome 1]
- [File, database entry, or outcome 2]
- [File, database entry, or outcome 3]

#### Next Steps

1. [Specific action 1 with owner if known]
2. [Specific action 2 with owner if known]
3. [Specific action 3 with owner if known]

#### Blockers

[None | Describe blocker with severity and impact]

**Severity**: [Low | Medium | High | Critical]
**Impact**: [Description of what's blocked]
**Escalation**: [Contact or action needed to unblock]

#### Handoff To

[@next-agent-name | None]

**Handoff Context**: [What the next agent needs to know]
**Handoff Dependencies**: [Files, data, or state required]

#### Performance Metrics

- **Duration**: [X minutes]
- **Files Created**: [N]
- **Files Updated**: [N]
- **Lines Generated**: [N]
- **Success Rate**: [X%]
- **Tokens Used**: [N] (optional)
- **Custom Metrics**: [Agent-specific metrics]

#### Related Work

- **Idea**: [Notion Ideas Registry link | None]
- **Research**: [Notion Research Hub link | None]
- **Build**: [Notion Example Builds link | None]
- **Workflow**: [Parent workflow ID if part of orchestration]
- **Parent Command**: [Original slash command or user request]

#### Files Modified

**Created**:
- `path/to/file1.md`
- `path/to/file2.json`

**Updated**:
- `path/to/existing-file.md` (section X updated)
- `path/to/config.json` (property Y changed)

**Deleted**:
- `path/to/obsolete-file.md` (reason: replaced by new structure)

#### Outcome

[Success | Partial Success | Blocked | Failed]

**Summary**: [1-2 sentence outcome summary]

**Impact**: [Measurable outcome or benefit delivered]

**Quality Metrics**:
- Brand Voice Compliance: [X%]
- Technical Accuracy: [X%]
- Security Compliance: [Pass | Fail with details]
```

---

## Logging Procedures

### 1. Determine Session ID

**Format**: `agent-name-YYYY-MM-DD-HHMM`

**Examples**:
- `markdown-expert-2025-10-21-1545`
- `cost-analyst-2025-10-22-0930`
- `orch-2025-10-21-1545` (for orchestration workflows)

### 2. Update All 3 Tiers

**Tier 1: Notion Database** (Primary Source of Truth)
- Create entry in "🤖 Agent Activity Hub" database
- Link to related Ideas/Research/Builds if applicable
- Set status and populate all properties

**Tier 2: Markdown Log** (Quick Reference)
- Append entry to `.claude/logs/AGENT_ACTIVITY_LOG.md`
- Place in "Active Sessions" if in progress
- Move to "Completed Sessions" when done

**Tier 3: JSON State** (Programmatic Access)
- Add to `activeSessions` array in `.claude/data/agent-state.json` if in progress
- Move to `completedSessions` array when done
- Update statistics object

### 3. Status Transitions

**In Progress** → **Completed**:
- Update completion timestamp
- Add final metrics
- Document outcomes
- Move from Active to Completed in all tiers

**In Progress** → **Blocked**:
- Document blocker with severity
- Provide escalation path
- Keep in Active Sessions with alert

**In Progress** → **Handed Off**:
- Specify next agent
- Provide handoff context
- Add to handoff queue in JSON

### 4. Use Slash Command (Recommended)

```bash
/agent:log-activity [agent-name] [status] [work-description]
```

This command automatically:
- Generates session ID
- Updates all 3 tiers simultaneously
- Creates Notion entry
- Appends to markdown log
- Updates JSON state
- Links to related Innovation Nexus items

---

## Status Definitions

**In Progress**:
- Work actively underway
- Agent has not completed all deliverables
- May have partial deliverables

**Completed**:
- All deliverables finished
- Next steps documented
- No blockers remaining
- Ready for handoff or closure

**Blocked**:
- Work cannot proceed due to external dependency
- Blocker documented with severity
- Escalation path identified
- Agent waiting for resolution

**Handed Off**:
- Work passed to another specialized agent
- Handoff context provided
- Dependencies clearly stated
- Next agent identified

---

## Agent-Specific Logging Examples

### Example 1: @markdown-expert (Documentation Work)

```markdown
### Session: markdown-expert-2025-10-21-1615

**Agent**: @markdown-expert
**Status**: Completed
**Started**: 2025-10-21 16:15:00 UTC
**Completed**: 2025-10-21 16:43:00 UTC
**Duration**: 28 minutes

#### Work Description

Performed comprehensive documentation audit of 147 markdown files across Innovation Nexus repository, evaluating syntax correctness, structural consistency, brand voice compliance, link validity, content accuracy, and AI-agent readability.

**Command/Trigger**: `/innovation:orchestrate-complex` (Wave 1, Agent 1)

#### Deliverables

- `DOCUMENTATION_AUDIT_REPORT.md` - Comprehensive audit report with quality scores

#### Next Steps

1. Fix 22 broken internal links identified in audit
2. Remove 42 duplicate files in mcp-foundry directories
3. Modularize CLAUDE.md to reduce token count

#### Blockers

None

#### Handoff To

None (parallel execution with other agents)

#### Performance Metrics

- **Duration**: 28 minutes
- **Files Audited**: 147
- **Files Created**: 1 (audit report)
- **Overall Health Score**: 85/100
- **Recommendations Generated**: 15+ prioritized items

#### Related Work

- **Workflow**: orch-2025-10-21-1545
- **Parent Command**: `/innovation:orchestrate-complex do all 4 parallel --effort=ultrathink`

#### Outcome

Success - Established baseline documentation quality assessment with actionable recommendations organized by priority (Critical, High, Medium, Low).
```

### Example 2: @cost-analyst (Cost Analysis)

```markdown
### Session: cost-analyst-2025-10-22-0930

**Agent**: @cost-analyst
**Status**: Completed
**Started**: 2025-10-22 09:30:00 UTC
**Completed**: 2025-10-22 09:42:00 UTC
**Duration**: 12 minutes

#### Work Description

Analyzed monthly software spend across Innovation Nexus ecosystem, identified unused tools, detected consolidation opportunities, and recommended Microsoft ecosystem alternatives for cost optimization.

**Command/Trigger**: `/cost:analyze all`

#### Deliverables

- Cost analysis report (inline output)
- Recommendations for $1,200/month savings

#### Next Steps

1. Present findings to leadership for approval
2. Cancel 3 identified unused tools (immediate $400/month savings)
3. Migrate Slack → Microsoft Teams (3-month timeline, $800/month savings)

#### Blockers

None

#### Handoff To

@workflow-router (for team assignments on migration tasks)

**Handoff Context**: Cost optimization approved, need team assignments for Teams migration
**Handoff Dependencies**: Leadership approval (expected within 48 hours)

#### Performance Metrics

- **Duration**: 12 minutes
- **Software Entries Analyzed**: 47
- **Unused Tools Identified**: 3
- **Consolidation Opportunities**: 2
- **Potential Monthly Savings**: $1,200
- **Potential Annual Savings**: $14,400

#### Related Work

- **Idea**: None
- **Research**: None
- **Build**: None
- **Workflow**: cost-review-2025-10-22
- **Parent Command**: `/cost:analyze all`

#### Outcome

Success - Identified $14,400 annual savings opportunity with clear implementation plan and stakeholder approval path.
```

### Example 3: @build-architect (Blocked Status)

```markdown
### Session: build-architect-2025-10-22-1100

**Agent**: @build-architect
**Status**: Blocked
**Started**: 2025-10-22 11:00:00 UTC
**Completed**: N/A
**Duration**: Estimated 45 minutes (20 minutes elapsed)

#### Work Description

Creating Example Build for Azure OpenAI integration with Notion MCP. Completed architecture design and GitHub repository setup. Blocked on Azure OpenAI quota limitation.

**Command/Trigger**: `/innovation:create-build "Azure OpenAI Notion Integration" poc`

#### Deliverables (Partial)

- Example Build entry created in Notion
- GitHub repository: `github.com/brookside-bi/azure-openai-notion-integration`
- Architecture documentation (draft)

#### Next Steps (Pending Unblock)

1. Provision Azure OpenAI resource (blocked)
2. Create API integration layer
3. Deploy to Azure App Service
4. Link all software costs to build

#### Blockers

**Severity**: High
**Impact**: Cannot provision Azure OpenAI resource due to quota limit in subscription. Blocks 60% of remaining work.
**Escalation**: Contact Azure administrator to request quota increase for GPT-4 deployments in East US region.
**Expected Resolution**: 2-4 business days

#### Handoff To

None (waiting for quota increase)

#### Performance Metrics

- **Duration (so far)**: 20 minutes
- **Files Created**: 3 (Notion entry, GitHub README, architecture draft)
- **Progress**: 40% complete

#### Related Work

- **Idea**: [Link to "AI-Powered Documentation Generator" idea]
- **Research**: [Link to "Azure OpenAI Feasibility" research]
- **Build**: [Link to this build entry]
- **Workflow**: build-aoai-notion-2025-10-22

#### Outcome

Partial Success - Architecture and repository established. Awaiting Azure quota increase to proceed with OpenAI provisioning.
```

---

## Best Practices

### Do's

✅ **Log immediately after completing work** - Don't batch logs, update as you go
✅ **Be specific in deliverables** - List actual files and outcomes, not vague descriptions
✅ **Document blockers with severity** - Help prioritize unblocking efforts
✅ **Provide clear next steps** - Actionable items with owners when known
✅ **Link to related Innovation Nexus items** - Enable traceability
✅ **Use consistent session ID format** - Enables programmatic querying
✅ **Update all 3 tiers** - Ensure consistency across Notion, markdown, JSON
✅ **Include metrics** - Quantify work for performance tracking

### Don'ts

❌ **Don't skip logging** - Even small work should be logged for continuity
❌ **Don't use vague descriptions** - "Updated some files" → List specific files
❌ **Don't forget to update status** - Mark as completed when done, not days later
❌ **Don't omit next steps** - Always document what should happen next
❌ **Don't log without session ID** - Required for tracking and querying
❌ **Don't mix multiple sessions** - One log entry per distinct work session
❌ **Don't forget handoff context** - If handing off, explain what next agent needs

---

## Automation Helpers

### Quick Log Script (PowerShell)

```powershell
# Quick log helper for manual logging
function Log-AgentActivity {
    param(
        [string]$AgentName,
        [string]$Status,
        [string]$WorkDescription,
        [string[]]$Deliverables,
        [string[]]$NextSteps
    )

    $SessionId = "$AgentName-$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    Write-Host "Session ID: $SessionId"
    Write-Host "Logging to all 3 tiers..."

    # TODO: Implement updates to Notion, Markdown, JSON
}
```

### Slash Command (Recommended)

```bash
# Use this for automatic 3-tier logging
/agent:log-activity @markdown-expert completed "Documentation audit of 147 files"
```

---

## Related Resources

- [Agent Activity Log (Markdown)](./.claude/logs/AGENT_ACTIVITY_LOG.md) - Human-readable log
- [Agent State (JSON)](./.claude/data/agent-state.json) - Programmatic state tracking
- [Agent Activity Hub (Notion)](https://notion.so) - Centralized database *(to be created)*
- [Slash Command: /agent:log-activity](./.claude/commands/agent/log-activity.md)
- [Slash Command: /agent:activity-summary](./.claude/commands/agent/activity-summary.md)
- [CLAUDE.md - Agent Activity Center](../../CLAUDE.md#agent-activity-center)

---

**🤖 Maintained for Brookside BI Innovation Nexus Agent Ecosystem**
**Best for**: Organizations establishing transparent, trackable AI agent workflows with seamless handoffs and institutional knowledge preservation.
