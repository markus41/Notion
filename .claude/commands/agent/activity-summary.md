# Agent Activity Summary - Slash Command

**Purpose**: Generate comprehensive activity reports across agent work sessions to establish visibility into progress, identify bottlenecks, and drive measurable outcomes through data-driven insights.

**Best for**: Team leads, project managers, and stakeholders seeking to understand agent productivity, workflow health, and resource allocation across the Innovation Nexus ecosystem.

---

## Command Syntax

```bash
/agent:activity-summary [timeframe] [agent-filter]
```

**Parameters:**
- `timeframe` (optional): Time window for analysis - `today`, `week`, `month`, `all` (default: `week`)
- `agent-filter` (optional): Specific agent name or `all` (default: `all`)

**Examples:**
```bash
# All agents, last 7 days (default)
/agent:activity-summary

# All agents today
/agent:activity-summary today

# Specific agent, last 30 days
/agent:activity-summary month @cost-analyst

# All time for specific agent
/agent:activity-summary all @markdown-expert

# Last week for all agents (explicit)
/agent:activity-summary week all
```

---

## What This Command Does

**Multi-Source Analysis:**

1. **Queries All 3 Tracking Tiers:**
   - Notion Database: "🤖 Agent Activity Hub" (primary source)
   - Markdown Log: `.claude/logs/AGENT_ACTIVITY_LOG.md` (quick reference)
   - JSON State: `.claude/data/agent-state.json` (programmatic data)

2. **Aggregates Key Metrics:**
   - Total sessions (active, completed, blocked, handed-off)
   - Total work duration across all sessions
   - Files created and updated
   - Success rate and completion percentage
   - Average session duration
   - Agent utilization and workload distribution

3. **Identifies Workflow Health:**
   - Active sessions requiring attention
   - Blocked sessions with escalation needs
   - Pending handoffs in queue
   - Long-running sessions (>7 days active)
   - Completed sessions with impact metrics

---

## Output Formats

### Summary Report (Default)

```
📊 Agent Activity Summary - Last 7 Days
═══════════════════════════════════════════════════════════

Overview:
  Total Sessions: 12
  ├─ ✅ Completed: 8 (66.7%)
  ├─ 🔵 In Progress: 3 (25.0%)
  ├─ ⚠️ Blocked: 1 (8.3%)
  └─ 🔄 Handed Off: 0 (0.0%)

Productivity Metrics:
  Total Work Duration: 4 hours 23 minutes
  Average Session Duration: 21.9 minutes
  Files Created: 47
  Files Updated: 12
  Success Rate: 100%

Agent Breakdown:
  @markdown-expert: 5 sessions (1h 45m)
  @cost-analyst: 3 sessions (52m)
  @build-architect: 2 sessions (1h 12m)
  @knowledge-curator: 1 session (28m)
  @workflow-router: 1 session (6m)

Active Sessions (Requiring Attention):
  1. @cost-analyst - "Monthly spend optimization" (in-progress, 2h 15m elapsed)
  2. @build-architect - "Azure Function deployment" (in-progress, 45m elapsed)
  3. @integration-specialist - "SharePoint integration" (blocked, 3h 22m elapsed)

Blocked Sessions (Need Escalation):
  ⚠️ HIGH PRIORITY
  └─ @integration-specialist - "SharePoint integration"
     Blocked by: SharePoint API quota exceeded
     Impact: Cannot complete Teams integration setup
     Escalation: Contact Microsoft support for quota increase
     Duration: 3h 22m blocked

Completed Sessions (Recent):
  ✓ @markdown-expert - "API documentation review" (28m, 100% quality)
  ✓ @cost-analyst - "Q3 software audit" (47m, $1,200 savings identified)
  ✓ @build-architect - "Cost dashboard MVP" (1h 12m, deployed to Azure)
  ✓ @knowledge-curator - "Research findings archive" (28m, 3 vault entries)
  ✓ @markdown-expert - "CHANGELOG update" (18m)

Top Performers (By Impact):
  1. @cost-analyst - $1,200/month savings identified
  2. @build-architect - 2 builds deployed to production
  3. @markdown-expert - 147 files audited, 85/100 health score
  4. @knowledge-curator - 3 Knowledge Vault entries created

Next Steps:
  1. Resolve SharePoint API quota blocker (HIGH PRIORITY)
  2. Monitor @cost-analyst's monthly optimization (in-progress 2h+)
  3. Review completed work for knowledge capture opportunities
  4. Rebalance workload - @markdown-expert has 5 sessions vs. avg 2.4
```

### Detailed Report (With `--detailed` Flag)

```bash
/agent:activity-summary week all --detailed
```

**Additional Details:**
- Full session breakdown with timestamps
- Deliverables list for each session
- Next steps for in-progress work
- Complete blocker descriptions
- Handoff queue with context
- Quality metrics and compliance scores
- Related Innovation Nexus items (Ideas/Research/Builds)

### Agent-Specific Report

```bash
/agent:activity-summary month @cost-analyst
```

```
📊 @cost-analyst Activity - Last 30 Days
═══════════════════════════════════════════════════════════

Sessions: 8 total
  ✅ Completed: 6 (75%)
  🔵 In Progress: 2 (25%)
  ⚠️ Blocked: 0
  🔄 Handed Off: 0

Work Duration: 5 hours 47 minutes
  Average: 43.4 minutes per session
  Longest: 1h 23m (Q4 cost optimization)
  Shortest: 12m (Expiring contracts check)

Deliverables:
  Cost Analysis Reports: 6
  Savings Identified: $3,840/month ($46,080/year)
  Software Entries Reviewed: 127
  Consolidation Opportunities: 4
  Microsoft Alternatives Suggested: 8

Key Outcomes:
  ✓ Identified $3,840/month in potential savings
  ✓ Detected 7 unused tools worth $680/month
  ✓ Recommended 4 consolidation opportunities
  ✓ Prevented 2 unnecessary software purchases ($240/month)
  ✓ Negotiated 3 contract renewals (15% average discount)

Active Sessions:
  1. "Monthly spend optimization" (in-progress, started 2h 15m ago)
     Next Steps: Review with leadership, cancel unused tools
  2. "Azure service cost modeling" (in-progress, started 45m ago)
     Next Steps: Compare App Service vs. Functions pricing

Related Innovation Nexus Items:
  Ideas: 3 cost optimization ideas created
  Builds: 2 builds with cost tracking linked
  Software Tracker: 127 entries analyzed

Performance Trends:
  Week 1: 2 sessions, 1h 34m, $840 savings
  Week 2: 3 sessions, 2h 12m, $1,200 savings
  Week 3: 1 session, 47m, $680 savings
  Week 4: 2 sessions, 1h 14m, $1,120 savings
  ↗️ Trending up: Savings/hour increasing (18% vs. baseline)
```

---

## Timeframe Definitions

| Timeframe | Description | Typical Use Case |
|-----------|-------------|------------------|
| `today` | Current calendar day (00:00 - 23:59 local time) | Daily standup, immediate priorities |
| `week` | Last 7 days (rolling window) | Weekly team sync, sprint review |
| `month` | Last 30 days (rolling window) | Monthly retrospective, trend analysis |
| `all` | Complete activity history | Annual review, historical analysis |

---

## Filtering Options

**By Agent:**
```bash
# Single agent
/agent:activity-summary week @cost-analyst

# All agents (default)
/agent:activity-summary week all
```

**By Status:**
```bash
# Only blocked sessions
/agent:activity-summary week all --status=blocked

# Only active sessions
/agent:activity-summary week all --status=in-progress

# Only completed sessions
/agent:activity-summary week all --status=completed
```

**By Related Work:**
```bash
# Sessions linked to specific idea
/agent:activity-summary all all --idea="AI Documentation Generator"

# Sessions linked to specific build
/agent:activity-summary month all --build="Cost Dashboard MVP"
```

**Output Format:**
```bash
# Markdown table format (good for copying to Notion)
/agent:activity-summary week all --format=table

# JSON format (for programmatic processing)
/agent:activity-summary week all --format=json

# Chart format (visual progress bars)
/agent:activity-summary week all --format=chart
```

---

## Alert Thresholds

**Automatic Warnings Triggered:**

⚠️ **Long-Running Sessions** (in-progress > 7 days):
```
⚠️ ATTENTION NEEDED
Session "Research Azure OpenAI integration" has been active for 9 days
Agent: @research-coordinator
Recommendation: Check if session should be completed or archived
```

🔴 **Critical Blockers** (severity = Critical):
```
🔴 CRITICAL BLOCKER
Session "Production deployment pipeline" blocked for 2 days
Agent: @build-architect
Impact: Cannot deploy updates to production environment
Escalation: Immediate action required
```

📊 **Workload Imbalance** (agent has >3x avg sessions):
```
📊 WORKLOAD WARNING
@markdown-expert has 12 active sessions (avg: 3.2 across all agents)
Recommendation: Consider redistributing work or prioritizing critical tasks
```

⏰ **Stalled Sessions** (no updates in 48+ hours):
```
⏰ STALE SESSION
Session "Knowledge Vault cleanup" last updated 72 hours ago
Agent: @knowledge-curator
Status: In Progress
Recommendation: Check with agent for status update
```

---

## Integration with Innovation Nexus

**Cross-Database Insights:**

The summary automatically correlates agent activity with:

1. **Ideas Registry:**
   - Ideas championed by each agent
   - Ideas requiring research or builds
   - Viability assessments in progress

2. **Research Hub:**
   - Active research threads
   - Viability assessments completed
   - Research requiring builds

3. **Example Builds:**
   - Builds in development
   - Deployment status tracking
   - Cost tracking linked to builds

4. **Software & Cost Tracker:**
   - Tools used in sessions
   - Cost optimization progress
   - Savings identified

5. **Knowledge Vault:**
   - Documentation created
   - Learnings archived
   - Reusability assessments

**Example Cross-Database Summary:**
```
Innovation Pipeline Health:
  Ideas: 12 active (5 need research, 3 ready to build)
  Research: 4 active (2 highly viable, 1 needs more investigation)
  Builds: 6 active (3 deployed, 2 in development, 1 blocked)
  Knowledge: 8 new entries this week

Agent Contributions:
  Ideas captured: 12 (@ideas-capture: 8, @research-coordinator: 4)
  Research completed: 2 (@research-coordinator: 2)
  Builds delivered: 3 (@build-architect: 2, @integration-specialist: 1)
  Knowledge archived: 8 (@knowledge-curator: 5, @markdown-expert: 3)
```

---

## Export Options

**Save Report:**
```bash
# Save as markdown file
/agent:activity-summary month all --save=reports/agent-activity-2025-10.md

# Save as JSON for analysis
/agent:activity-summary month all --format=json --save=reports/agent-activity-2025-10.json

# Save to Notion page
/agent:activity-summary month all --save-to-notion
```

**Schedule Reports:**
```bash
# Weekly email digest (future feature)
/agent:activity-summary week all --schedule=weekly --email=team@brooksidebi.com

# Monthly Teams notification (future feature)
/agent:activity-summary month all --schedule=monthly --teams-channel="Innovation Updates"
```

---

## Performance Benchmarks

**Typical Execution Times:**
- `today` with 1-5 sessions: <1 second
- `week` with 10-20 sessions: 1-2 seconds
- `month` with 50-100 sessions: 2-4 seconds
- `all` with 500+ sessions: 5-10 seconds

**Data Sources Queried:**
1. JSON (fastest): `.claude/data/agent-state.json`
2. Markdown (fast): `.claude/logs/AGENT_ACTIVITY_LOG.md`
3. Notion (slower): API calls to Agent Activity Hub database

**Optimization**: Command prioritizes JSON for speed, falls back to Markdown, validates against Notion for accuracy.

---

## Use Cases

**Daily Standup:**
```bash
/agent:activity-summary today all
# Quick overview of what agents accomplished today
# Identify blockers requiring immediate attention
```

**Weekly Team Sync:**
```bash
/agent:activity-summary week all --detailed
# Comprehensive review of all agent work
# Identify trends, blockers, and workload balance
```

**Monthly Retrospective:**
```bash
/agent:activity-summary month all --format=chart
# Visual progress tracking
# Identify top performers and bottlenecks
```

**Individual Performance Review:**
```bash
/agent:activity-summary all @cost-analyst --detailed
# Complete history for specific agent
# Quantify impact and productivity
```

**Pipeline Health Check:**
```bash
/agent:activity-summary week all --status=blocked
# Focus on blockers only
# Prioritize escalation and resolution
```

**Innovation Metrics:**
```bash
/agent:activity-summary month all
# Track Ideas → Research → Builds → Knowledge flow
# Measure innovation velocity and throughput
```

---

## Related Commands

- `/agent:log-activity [agent] [status] [description]` - Log agent work
- `/agent:handoff-queue` - View pending handoffs
- `/agent:blocker-report` - Detailed blocker analysis
- `/agent:performance-trends` - Long-term trend analysis (future)

---

## Example Workflow

**Weekly Review Process:**

```bash
# Step 1: Generate weekly summary
/agent:activity-summary week all --detailed

# Step 2: Review blockers
/agent:activity-summary week all --status=blocked

# Step 3: Check workload distribution
/agent:activity-summary week all --format=chart

# Step 4: Save report for stakeholders
/agent:activity-summary week all --save=reports/weekly-$(date +%Y-%m-%d).md

# Step 5: Share in Teams
# [Copy markdown output to Teams channel]

# Step 6: Create action items for next week
# [Based on blockers and in-progress sessions]
```

---

## Technical Implementation

**Data Sources:**
- Primary: `.claude/data/agent-state.json` (programmatic)
- Secondary: `.claude/logs/AGENT_ACTIVITY_LOG.md` (human-readable)
- Tertiary: Notion "🤖 Agent Activity Hub" (source of truth)

**Calculation Methods:**
- Duration: Sum of `completedAt - startedAt` for completed sessions
- Success Rate: `completedSessions / totalSessions × 100`
- Average Duration: `totalDuration / sessionCount`
- Workload Balance: Compare agent session count vs. mean

**Caching:**
- Today's data: No caching (always fresh)
- Week/month: 5-minute cache
- All-time: 15-minute cache
- Cache invalidated on new session logged

---

## Error Handling

**Common Issues:**

1. **No activity in timeframe:**
   ```
   ℹ️ No agent activity found for timeframe: week
   Try: /agent:activity-summary month all
   ```

2. **Unknown agent:**
   ```
   ⚠️ Agent not found: @invalid-agent
   Available agents: @cost-analyst, @markdown-expert, @build-architect, ...
   ```

3. **Notion database unavailable:**
   ```
   ⚠️ Notion database unavailable, using local data sources
   Summary generated from JSON and Markdown logs only
   ```

4. **Invalid timeframe:**
   ```
   ⚠️ Invalid timeframe: "yesterday"
   Valid options: today, week, month, all
   ```

---

**🤖 Maintained for Brookside BI Innovation Nexus Agent Ecosystem**

**Best for**: Organizations establishing data-driven agent management to ensure transparent progress tracking, proactive blocker resolution, and optimal resource allocation across innovation workflows.
