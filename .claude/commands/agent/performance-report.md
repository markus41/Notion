---
name: agent:performance-report
description: Establish agent effectiveness measurement to drive performance optimization and inform delegation decisions through historical metrics analysis
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-fetch
argument-hint: [agent-name] [--timeframe=7d|30d|all]
model: claude-sonnet-4-5-20250929
---

# /agent:performance-report

**Category**: Analytics & Reporting
**Related Databases**: Agent Registry, Agent Activity Hub, Agent Style Tests
**Agent Compatibility**: @claude-main

## Purpose

Establish comprehensive agent effectiveness measurement to drive performance optimization and inform delegation decisions through historical metrics analysis including completion rates, average duration, quality scores, and output style effectiveness.

**Best for**: Organizations requiring systematic agent performance tracking to optimize delegation patterns and identify improvement opportunities.

---

## Command Parameters

**Required:**
- `agent-name` - Agent to analyze (e.g., @cost-analyst, @build-architect)

**Optional Flags:**
- `--timeframe=value` - Analysis period (7d | 30d | all, default: 30d)
- `--include-styles` - Show output style performance breakdown
- `--show-failures` - Display failed/blocked sessions with root causes

---

## Workflow

### Step 1: Fetch Agent Profile

```javascript
const agentRegistry = await notionSearch({
  query: agentName.replace('@', ''),
  data_source_url: 'collection://5863265b-eeee-45fc-ab1a-4206d8a523c6'
});

if (agentRegistry.results.length === 0) {
  console.error(`❌ Agent not found: ${agentName}`);
  console.log(`\nRegistered agents: Use /agent:list to see all available agents`);
  return;
}

const agent = await notionFetch({ id: agentRegistry.results[0].id });

const agentData = {
  name: agent.properties["Agent Name"]?.title?.[0]?.plain_text,
  specialization: agent.properties["Specialization"]?.select?.name,
  performanceScore: agent.properties["Performance Score"]?.number,
  avgDuration: agent.properties["Average Duration"]?.number,
  totalSessions: agent.properties["Total Sessions"]?.number,
  status: agent.properties["Status"]?.select?.name
};
```

### Step 2: Query Activity Hub

```javascript
const timeframeMap = {
  '7d': 7,
  '30d': 30,
  'all': 36500 // 100 years
};

const daysAgo = timeframeMap[timeframe] || 30;
const cutoffDate = new Date();
cutoffDate.setDate(cutoffDate.getDate() - daysAgo);

const activityHub = await notionSearch({
  query: agentName.replace('@', ''),
  data_source_url: 'collection://7163aa38-f3d9-444b-9c64-7560ea51b257'
});

const sessions = [];
for (const activity of activityHub.results) {
  const details = await notionFetch({ id: activity.id });
  const sessionStart = new Date(details.properties["Session Start"]?.date?.start);

  if (sessionStart >= cutoffDate) {
    sessions.push({
      title: details.properties["Activity Title"]?.title?.[0]?.plain_text,
      status: details.properties["Status"]?.select?.name,
      duration: details.properties["Duration (min)"]?.number,
      deliverables: details.properties["Deliverables"]?.rich_text?.[0]?.plain_text,
      blockers: details.properties["Blocker Description"]?.rich_text?.[0]?.plain_text,
      date: sessionStart
    });
  }
}
```

### Step 3: Calculate Performance Metrics

```javascript
const metrics = {
  totalSessions: sessions.length,
  completed: sessions.filter(s => s.status === '✅ Completed').length,
  blocked: sessions.filter(s => s.status === '🔴 Blocked').length,
  inProgress: sessions.filter(s => s.status === '🟢 In Progress').length,
  avgDuration: sessions.reduce((sum, s) => sum + (s.duration || 0), 0) / sessions.length,
  completionRate: (sessions.filter(s => s.status === '✅ Completed').length / sessions.length * 100).toFixed(1)
};

console.log(`\n# Agent Performance Report: ${agentName}`);
console.log(`**Timeframe**: ${timeframe === 'all' ? 'All Time' : `Last ${daysAgo} days`}`);
console.log(`**Analysis Date**: ${new Date().toLocaleDateString()}\n`);

console.log(`## Summary Metrics\n`);
console.log(`- **Total Sessions**: ${metrics.totalSessions}`);
console.log(`- **Completion Rate**: ${metrics.completionRate}%`);
console.log(`- **Average Duration**: ${metrics.avgDuration.toFixed(1)} minutes`);
console.log(`- **Performance Score**: ${agentData.performanceScore}/100\n`);

console.log(`## Session Status Breakdown\n`);
console.log(`- ✅ Completed: ${metrics.completed} (${(metrics.completed/metrics.totalSessions*100).toFixed(0)}%)`);
console.log(`- 🟢 In Progress: ${metrics.inProgress} (${(metrics.inProgress/metrics.totalSessions*100).toFixed(0)}%)`);
console.log(`- 🔴 Blocked: ${metrics.blocked} (${(metrics.blocked/metrics.totalSessions*100).toFixed(0)}%)\n`);
```

### Step 4: Quality Assessment

```javascript
const recentDeliverables = sessions
  .filter(s => s.status === '✅ Completed' && s.deliverables)
  .slice(0, 5)
  .map(s => ({
    title: s.title,
    deliverables: s.deliverables,
    duration: s.duration
  }));

console.log(`## Recent Deliverables (Last 5)\n`);
recentDeliverables.forEach((d, idx) => {
  console.log(`${idx + 1}. **${d.title}**`);
  console.log(`   - Deliverables: ${d.deliverables}`);
  console.log(`   - Duration: ${d.duration} min\n`);
});
```

### Step 5: Style Performance (if flag set)

```javascript
if (includeStylesFlag) {
  const styleTests = await notionSearch({
    query: agentName.replace('@', ''),
    data_source_url: 'collection://b109b417-2e3f-4eba-bab1-9d4c047a65c4'
  });

  const stylePerformance = {};
  for (const test of styleTests.results) {
    const details = await notionFetch({ id: test.id });
    const styleName = details.properties["Style"]?.relation?.[0]?.id; // Would need to fetch style name
    const effectiveness = details.properties["Effectiveness Score"]?.number;

    if (!stylePerformance[styleName]) stylePerformance[styleName] = [];
    stylePerformance[styleName].push(effectiveness);
  }

  console.log(`## Output Style Effectiveness\n`);
  Object.entries(stylePerformance).forEach(([style, scores]) => {
    const avgScore = (scores.reduce((a, b) => a + b, 0) / scores.length).toFixed(1);
    console.log(`- **${style}**: ${avgScore}/100 (${scores.length} tests)`);
  });
}
```

---

## Execution Example

```bash
/agent:performance-report @cost-analyst --timeframe=30d
```

**Output:**
```
# Agent Performance Report: @cost-analyst
**Timeframe**: Last 30 days
**Analysis Date**: 2025-10-26

## Summary Metrics

- **Total Sessions**: 18
- **Completion Rate**: 94.4%
- **Average Duration**: 12.3 minutes
- **Performance Score**: 92/100

## Session Status Breakdown

- ✅ Completed: 17 (94%)
- 🟢 In Progress: 0 (0%)
- 🔴 Blocked: 1 (6%)

## Recent Deliverables (Last 5)

1. **Q4 Software Spend Analysis - 20251024**
   - Deliverables: Excel cost breakdown, top 5 waste opportunities, consolidation plan
   - Duration: 15 min

2. **Monthly Utilization Review - 20251022**
   - Deliverables: Utilization metrics for 12 software tools, 3 downgrade recommendations
   - Duration: 10 min

3. **Microsoft Alternatives Analysis - 20251020**
   - Deliverables: Comparison matrix for Slack vs Teams, $47K annual savings projection
   - Duration: 18 min

4. **License Waste Identification - 20251018**
   - Deliverables: 8 tools with <60% utilization, $23K annual waste identified
   - Duration: 8 min

5. **ROI Calculation for Consolidation - 20251015**
   - Deliverables: 3-year TCO model, payback analysis, executive summary
   - Duration: 22 min

## Blockers & Issues

**1 Blocked Session:**
- **Session**: Cost tracking for legacy system (20251012)
- **Blocker**: Missing API access to legacy billing platform
- **Resolution**: Pending procurement team credentials
```

---

## Error Handling

**Error 1: Agent Not Found**
```
Input: /agent:performance-report @nonexistent-agent
Output: ❌ Agent not found: @nonexistent-agent

        Registered agents: Use /agent:list to see all available agents
```

**Error 2: No Activity Data**
```
Input: /agent:performance-report @new-agent --timeframe=30d
Output: ⚠️ No activity data found for @new-agent in last 30 days

        Agent registered: 2025-10-25
        Sessions logged: 0

        Recommendations:
        - Extend timeframe: --timeframe=all
        - Check agent has been invoked via Task tool
        - Verify Agent Activity Hub logging is enabled
```

**Error 3: Invalid Timeframe**
```
Input: /agent:performance-report @cost-analyst --timeframe=90d
Output: ❌ Invalid timeframe: 90d
        Valid options: 7d | 30d | all
```

---

## Success Criteria

- ✅ Agent profile retrieved from Agent Registry
- ✅ Activity sessions fetched within timeframe
- ✅ Performance metrics calculated (completion rate, avg duration)
- ✅ Recent deliverables displayed (top 5)
- ✅ Blockers identified (if any)
- ✅ Style performance shown (if flag set)

---

## Related Commands

- `/agent:assign-work` - Use performance data to inform agent selection
- `/style:effectiveness-report` - Detailed output style analytics
- `/agent:register` - Add new agents to registry

---

## Best Practices

**Do:**
- ✅ Review performance reports before critical delegations
- ✅ Compare multiple agents for same work type
- ✅ Track performance trends over time (monthly reports)
- ✅ Use reports to identify training/improvement needs

**Don't:**
- ❌ Solely rely on aggregate scores without reviewing deliverables
- ❌ Compare agents across different specializations
- ❌ Ignore blocked sessions (indicate systemic issues)

---

## Notes for Claude Code

**Automatic Execution**: This command executes immediately without requiring user approval for Notion MCP operations (search, fetch).

**Performance**: Typical execution time 8-15 seconds (depends on activity volume and timeframe).

**Caching**: Agent Registry data can be cached for faster subsequent queries.

---

**Last Updated**: 2025-10-26
**Databases**:
- Agent Registry: `5863265b-eeee-45fc-ab1a-4206d8a523c6`
- Agent Activity Hub: `7163aa38-f3d9-444b-9c64-7560ea51b257`
- Agent Style Tests: `b109b417-2e3f-4eba-bab1-9d4c047a65c4`