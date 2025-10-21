---
name: autonomous:status
description: Display real-time status of autonomous innovation pipelines across Ideas Registry, Research Hub, and Example Builds. Shows automation progress, agent activity, viability scores, and pending human decisions. Use when user wants visibility into autonomous workflow execution or needs to monitor pipeline health.

allowed-tools: SlashCommand(@notion-orchestrator:status-dashboard)
---

# /autonomous:status

**Purpose**: Provide comprehensive visibility into autonomous innovation pipelines with real-time automation status, agent activity tracking, and decision queue monitoring.

**Best for**: Organizations scaling innovation management across teams requiring transparent, real-time visibility into autonomous workflow execution and human intervention needs.

---

## Command Execution

When this command is invoked, execute the following workflow:

### Step 1: Query Notion Databases for Automation Status

**Ideas Registry** (Ideas with automation enabled):
```javascript
// Search for ideas in automation pipeline
const activeAutomation = await notionSearch({
  database: "Ideas Registry",
  filter: {
    "Automation Status": ["In Progress", "Pending", "Requires Review", "Complete"],
    "Status": ["Concept", "Active"]
  },
  sort: {
    "Last Automation Event": "descending"
  }
});
```

**Research Hub** (Autonomous research in progress):
```javascript
// Search for active autonomous research
const activeResearch = await notionSearch({
  database: "Research Hub",
  filter: {
    "Research Type": "Autonomous Parallel Swarm",
    "Status": ["Active", "Completed"],
    "Last Updated": "within_7_days"
  },
  sort: {
    "Last Updated": "descending"
  }
});
```

**Example Builds** (Autonomous build pipeline):
```javascript
// Search for builds in autonomous pipeline
const activeBuilds = await notionSearch({
  database: "Example Builds",
  filter: {
    "Automation Stage": ["Planning", "Development", "Testing", "Deployment", "Live"],
    "Status": ["Active", "Concept"]
  },
  sort: {
    "Last Automation Event": "descending"
  }
});
```

### Step 2: Aggregate Automation Metrics

**Calculate Pipeline Metrics**:
```javascript
const metrics = {
  // Ideas in automation
  totalIdeasInPipeline: activeAutomation.length,
  ideasPending: filter(activeAutomation, status === "Pending").length,
  ideasInProgress: filter(activeAutomation, status === "In Progress").length,
  ideasRequireReview: filter(activeAutomation, status === "Requires Review").length,
  ideasComplete: filter(activeAutomation, status === "Complete", last7days).length,

  // Research swarm activity
  activeResearchSwarms: filter(activeResearch, status === "Active").length,
  completedResearch: filter(activeResearch, status === "Completed", last7days).length,
  avgResearchDuration: average(activeResearch, "Research Duration"),

  // Build pipeline
  buildsInPipeline: activeBuilds.length,
  buildsByStage: {
    planning: filter(activeBuilds, stage === "Planning").length,
    development: filter(activeBuilds, stage === "Development").length,
    testing: filter(activeBuilds, stage === "Testing").length,
    deployment: filter(activeBuilds, stage === "Deployment").length,
    live: filter(activeBuilds, stage === "Live").length
  },

  // Human intervention queue
  decisionsNeeded: ideasRequireReview.length,
  avgDecisionAge: average(ideasRequireReview, daysSinceLastEvent)
};
```

### Step 3: Check Agent Activity

**Recent Agent Invocations** (if tracking available):
```javascript
const agentActivity = {
  last24Hours: {
    marketResearcher: [X invocations],
    technicalAnalyst: [X invocations],
    costAnalyst: [X invocations],
    riskAssessor: [X invocations],
    buildArchitect: [X invocations]
  },
  avgExecutionTime: {
    researchSwarm: "[X] minutes",
    viabilityAssessment: "[X] minutes",
    buildInitiation: "[X] minutes"
  }
};
```

### Step 4: Present Status Dashboard

Display comprehensive status dashboard to user using the format below.

---

## Output Format

```
╔══════════════════════════════════════════════════════════════════════════╗
║           AUTONOMOUS INNOVATION PLATFORM - STATUS DASHBOARD              ║
╚══════════════════════════════════════════════════════════════════════════╝

📊 PIPELINE OVERVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Ideas in Automation Pipeline:     [X] total
    ⏸️  Pending (awaiting trigger):   [X]
    ⚙️  In Progress (active agents):  [X]
    ⚠️  Requires Review (human):      [X]
    ✅ Completed (last 7 days):       [X]

  Active Research Swarms:            [X] running
  Completed Research (last 7 days):  [X]
  Avg Research Duration:             [X] minutes

  Builds in Pipeline:                [X] total
    📋 Planning:                      [X]
    💻 Development:                   [X]
    🧪 Testing:                       [X]
    🚀 Deployment:                    [X]
    🟢 Live:                          [X]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤖 AGENT ACTIVITY (Last 24 Hours)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @market-researcher:          [X] invocations
  @technical-analyst:          [X] invocations
  @cost-feasibility-analyst:   [X] invocations
  @risk-assessor:              [X] invocations
  @build-architect:            [X] invocations
  @research-coordinator:       [X] invocations (swarm orchestration)

  Avg Execution Times:
    Research Swarm:            [X] minutes
    Viability Assessment:      [X] minutes
    Build Initiation:          [X] minutes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  HUMAN DECISIONS NEEDED: [X] items
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[If decisionsNeeded > 0:]

  1. 💡 "[Idea Title]" - Viability: [X]/100 (Moderately Viable)
     Champion: [Name]
     Waiting: [X] days
     Reason: [Score 60-85 requires champion approval]
     → View: [Notion URL]

  2. 💡 "[Idea Title]" - Viability: [X]/100
     [Continue for all items requiring review...]

[If decisionsNeeded === 0:]
  ✅ No pending decisions - all pipelines flowing smoothly!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔄 ACTIVE AUTOMATION WORKFLOWS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[For each idea/research/build in active automation:]

  🔬 Research: "[Research Topic]"
     Stage: [Market Analysis ✅ | Technical Analysis ⏳ | Cost Analysis ⏸️  | Risk Analysis ⏸️]
     Duration: [X] minutes elapsed
     Estimated Completion: [X] minutes remaining
     → View: [Research Hub URL]

  🛠️  Build: "[Build Name]"
     Stage: [Development] ([X]% progress)
     Team: [Lead builder + supporting team]
     Timeline: Week [X] of [Y]
     Next Milestone: [Description] in [X] days
     → View: [Example Build URL]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📈 RECENT COMPLETIONS (Last 7 Days)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ✅ Research: "[Topic]" - Completed in [X] min
     Result: [Highly Viable (92/100)] → Auto-approved for build
     → View: [URL]

  ✅ Build: "[Name]" - Deployed to Production
     Timeline: [X] weeks (on schedule)
     Cost: $[X]/month (within budget)
     → View: [URL]

  ⚠️ Research: "[Topic]" - Completed in [X] min
     Result: [Low Viability (45/100)] → Auto-archived with learnings
     → Knowledge Vault: [URL]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 QUICK ACTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Enable automation for new idea:   /autonomous:enable-idea [idea-name]
  Review pending decisions:         [Open Notion view with filtered list]
  View detailed agent logs:         [Link to Application Insights dashboard]
  Pause automation for idea:        [Command to suspend automation]
  Resume automation for idea:       [Command to restart automation]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 SYSTEM HEALTH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Automation Success Rate:      [X]% (last 30 days)
  Avg Time to Decision:         [X] hours (auto) | [X] days (human review)
  Innovation Velocity:          [X] ideas → production per month
  Cost Optimization:            $[X] saved through automated analysis

  ✅ All systems operational
  [or]
  ⚠️  [X] agents experiencing delays (check logs)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Last Updated: [Timestamp]
Refresh: Run /autonomous:status again for latest data
```

---

## Example Usage Scenarios

### Scenario 1: Daily Standup Check

```
User: /autonomous:status

Output:
╔══════════════════════════════════════════════════════════════════════════╗
║           AUTONOMOUS INNOVATION PLATFORM - STATUS DASHBOARD              ║
╚══════════════════════════════════════════════════════════════════════════╝

📊 PIPELINE OVERVIEW

  Ideas in Automation Pipeline:     12 total
    ⏸️  Pending (awaiting trigger):   3
    ⚙️  In Progress (active agents):  4
    ⚠️  Requires Review (human):      3
    ✅ Completed (last 7 days):       2

  Active Research Swarms:            2 running
  Completed Research (last 7 days):  5
  Avg Research Duration:             24 minutes

  Builds in Pipeline:                8 total
    📋 Planning:                      2
    💻 Development:                   3
    🧪 Testing:                       2
    🚀 Deployment:                    1
    🟢 Live:                          0

⚠️  HUMAN DECISIONS NEEDED: 3 items

  1. 💡 "Real-time collaboration using Azure SignalR" - Viability: 78/100
     Champion: Alec Fielding
     Waiting: 2 days
     Reason: Moderately Viable (60-85) requires technical lead approval
     → View: https://notion.so/abc123

  2. 💡 "ML cost prediction dashboard" - Viability: 72/100
     Champion: Markus Ahling
     Waiting: 1 day
     Reason: Monthly cost $650 exceeds $500 auto-approval threshold
     → View: https://notion.so/def456

  3. 💡 "Power BI governance automation" - Viability: 68/100
     Champion: Brad Wright
     Waiting: 3 days
     Reason: Moderate business risk requires stakeholder review
     → View: https://notion.so/ghi789
```

### Scenario 2: Empty Pipeline (All Clear)

```
User: /autonomous:status

Output:
📊 PIPELINE OVERVIEW

  Ideas in Automation Pipeline:     0 total
  Active Research Swarms:            0 running
  Builds in Pipeline:                3 total (all in Live stage)

⚠️  HUMAN DECISIONS NEEDED: 0 items
  ✅ No pending decisions - all pipelines flowing smoothly!

🎯 SYSTEM HEALTH
  ✅ All systems operational
  Innovation Velocity: 8 ideas → production last month
```

### Scenario 3: High Activity Period

```
User: /autonomous:status

Output:
📊 PIPELINE OVERVIEW

  Ideas in Automation Pipeline:     28 total
    ⚙️  In Progress (active agents):  12
    ⚠️  Requires Review (human):      8

🤖 AGENT ACTIVITY (Last 24 Hours)

  @market-researcher:          18 invocations
  @technical-analyst:          18 invocations
  @cost-feasibility-analyst:   18 invocations
  @risk-assessor:              18 invocations
  @research-coordinator:       18 invocations (swarm orchestration)

  Avg Execution Times:
    Research Swarm:            26 minutes
    Viability Assessment:      28 minutes

⚠️  HUMAN DECISIONS NEEDED: 8 items
  [High volume - showing top 5 by urgency...]
```

---

## Additional Commands (Future Enhancements)

**Drill-down commands for detailed views**:
- `/autonomous:status ideas` - Show only Ideas pipeline
- `/autonomous:status research` - Show only Research swarms
- `/autonomous:status builds` - Show only Build pipeline
- `/autonomous:status decisions` - Show only pending human decisions
- `/autonomous:status agent [agent-name]` - Show specific agent activity

**Pipeline management commands**:
- `/autonomous:pause [idea-name]` - Suspend automation for specific idea
- `/autonomous:resume [idea-name]` - Restart automation for specific idea
- `/autonomous:approve [idea-name]` - Manually approve pending decision
- `/autonomous:reject [idea-name]` - Decline idea and archive with reason

---

## Implementation Notes

**Data Refresh**:
- Query Notion databases in real-time when command invoked
- Display timestamp of last update
- Recommend refresh frequency: Every 15-30 minutes for active monitoring

**Performance Optimization**:
- Cache database query results for 5 minutes
- Use incremental updates for high-frequency monitoring
- Aggregate metrics calculation optimized for speed

**Accessibility**:
- Provide clickable Notion URLs for all referenced items
- Include command suggestions for common next actions
- Support color-coded status indicators (if terminal supports)

**Future Integration**:
- Application Insights dashboard link for detailed agent logs
- Azure Function execution history
- Cost tracking integration with Software & Cost Tracker
- Real-time WebSocket updates for live dashboard

---

## Success Metrics

This command drives measurable outcomes through:
- **Transparency**: Real-time visibility into all autonomous workflows
- **Efficiency**: Quick identification of bottlenecks and human intervention needs
- **Accountability**: Clear tracking of decision timelines and agent performance
- **Optimization**: Data-driven insights for process improvement

**Best for**: Organizations scaling innovation management requiring transparent, real-time monitoring of autonomous pipeline execution to ensure sustainable growth and continuous improvement.
