---
description: Generate performance analytics reports for output styles. Query historical test data from Notion Agent Style Tests database and provide trend analysis, top/bottom performers, and optimization recommendations.
allowed-tools: mcp__notion__*
argument-hint: [--agent=name] [--style=name] [--timeframe=7d|30d|all]
model: claude-sonnet-4-5-20250929
---

## Context

Establish data-driven style optimization through comprehensive performance analytics, enabling continuous improvement based on empirical effectiveness patterns across agent+style combinations.

**Best for**: Organizations requiring systematic communication optimization with performance tracking, trend analysis, and evidence-based refinement strategies.

---

## Command Syntax

```bash
/style:report [options]

# Options (at least one required):
--agent=name         - Report for specific agent (e.g., @cost-analyst)
--style=name         - Report for specific style across all agents
--timeframe=period   - Time window: 7d, 30d, 90d, all (default: 30d)
--format=type        - Output format: summary|detailed|executive (default: summary)
--export=path        - Export to markdown file
```

---

## Usage Examples

### Agent Performance Report
```bash
/style:report --agent=@cost-analyst --timeframe=30d
```
**Output**: Shows cost-analyst performance across all 5 styles over last 30 days

### Style Performance Report
```bash
/style:report --style=strategic-advisor --timeframe=90d
```
**Output**: Shows strategic-advisor performance across all agents over last 90 days

### Portfolio-Wide Report
```bash
/style:report --timeframe=all --format=executive
```
**Output**: High-level trends across entire style testing portfolio

---

## Report Components

### 1. Performance Summary

```
Output Style Performance Report
Agent: @cost-analyst | Period: Last 30 Days | Tests: 12

Overall Statistics:
  • Average Effectiveness: 82/100 (+5 vs previous period)
  • Best Performing Style: Strategic Advisor (94/100 avg)
  • Worst Performing Style: Compliance Auditor (55/100 avg)
  • Most Used Style: Strategic Advisor (6 tests, 50%)
  • Recommendation Accuracy: 92% (11/12 matches predicted optimal)
```

### 2. Style Breakdown Table

```
| Style | Tests | Avg Effectiveness | Avg Satisfaction | Trend | Status |
|-------|-------|------------------|------------------|-------|--------|
| Strategic Advisor | 6 | 94/100 | 4.8/5 | ↗ +8 | ✅ Optimal |
| Visual Architect | 3 | 82/100 | 4.3/5 | → 0 | ✅ Good |
| Technical Impl. | 2 | 71/100 | 4.0/5 | ↘ -5 | ⚠️ Review |
| Interactive Teacher | 1 | 68/100 | 4.0/5 | - | - |
| Compliance Auditor | 0 | N/A | N/A | - | - |
```

### 3. Trend Analysis

```
Performance Trends (30-day comparison):
  • Strategic Advisor: 86 → 94 (+8 points) 📈 Strong improvement
  • Technical Implementer: 76 → 71 (-5 points) 📉 Declining, investigate
  • Visual Architect: 82 → 82 (0 change) ➡️ Stable performer

Contributing Factors:
  • Strategic Advisor improvement correlates with more executive-focused tasks
  • Technical Implementer decline coincides with mixed-audience tasks (poor fit)
```

### 4. Recommendations

```
Actionable Recommendations:

🎯 High Priority (Implement Immediately):
  1. Default to Strategic Advisor for @cost-analyst executive tasks (94% avg effectiveness)
  2. Avoid Compliance Auditor for @cost-analyst (untested, likely poor fit)
  3. Investigate Technical Implementer decline (-5 trend over 30d)

💡 Medium Priority (Consider for Q1 2026):
  4. Test Interactive Teacher + @cost-analyst combination (only 1 test, inconclusive)
  5. Run UltraThink analysis on top 3 combinations to identify optimization opportunities

📊 Low Priority (Monitor):
  6. Visual Architect stable at 82/100 - acceptable backup option
```

### 5. Historical Comparison

```
Quarter-over-Quarter Comparison:

Q3 2025:
  • Tests Run: 8
  • Avg Effectiveness: 77/100
  • Top Style: Strategic Advisor (86/100)

Q4 2025:
  • Tests Run: 12 (+50%)
  • Avg Effectiveness: 82/100 (+5 points)
  • Top Style: Strategic Advisor (94/100, +8 improvement)

Analysis: Testing volume increased 50%, effectiveness improved across board. Strategic Advisor optimization efforts paying off.
```

---

## Notion Database Queries

**Query Logic:**

```javascript
// Agent-specific report
const tests = await queryNotion('Agent Style Tests', {
  filter: {
    and: [
      { property: 'Agent', relation: { contains: agentId } },
      { property: 'Test Date', date: { after: startDate } }
    ]
  },
  sorts: [{ property: 'Test Date', direction: 'descending' }]
});

// Calculate metrics
const avgEffectiveness = mean(tests.map(t => t['Overall Effectiveness']));
const avgSatisfaction = mean(tests.map(t => t['User Satisfaction']));
const trend = calculateTrend(tests, 'Overall Effectiveness');
```

---

## Export Options

**Markdown Export:**
```bash
/style:report --agent=@cost-analyst --export=.claude/reports/cost-analyst-performance.md
```

**Generated File:**
```markdown
# @cost-analyst Output Style Performance Report
Generated: 2025-10-23

[Full report content with charts, tables, and recommendations]
```

---

## Integration with Continuous Improvement

**Quarterly Review Workflow:**

```bash
# 1. Generate portfolio report
/style:report --timeframe=90d --format=executive

# 2. Identify underperformers
# Look for combinations with <60 effectiveness or declining trends

# 3. Deep-dive on specific issues
/style:report --agent=@problem-agent --format=detailed

# 4. Run targeted re-tests
/test-agent-style @problem-agent problem-style --ultrathink --interactive

# 5. Document findings and update style definitions
# Update .claude/styles/[style].md based on insights
```

---

**Best for**: Organizations requiring systematic performance tracking where data-driven insights enable continuous communication optimization through trend analysis, comparative benchmarking, and evidence-based style refinement strategies.
