---
name: style:effectiveness-report
description: Establish output style performance analytics to drive documentation quality optimization and audience engagement measurement
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-fetch
argument-hint: [--style=name] [--agent=name] [--timeframe=7d|30d|all]
model: claude-sonnet-4-5-20250929
---

# /style:effectiveness-report

**Category**: Analytics & Reporting
**Related Databases**: Agent Style Tests, Output Styles Registry
**Agent Compatibility**: @claude-main

## Purpose

Establish comprehensive output style performance analytics to drive documentation quality optimization through historical effectiveness scoring and agent-style pairing analysis.

**Best for**: Organizations requiring data-driven style selection and continuous documentation quality improvement.

---

## Command Parameters

**Optional Flags:**
- `--style=name` - Filter by specific output style
- `--agent=name` - Filter by specific agent
- `--timeframe=value` - Analysis period (7d | 30d | all, default: 30d)

---

## Workflow

### Step 1: Fetch and Analyze Tests

```javascript
const styleTests = await notionSearch({
  query: styleFlag || agentFlag || '',
  data_source_url: 'collection://b109b417-2e3f-4eba-bab1-9d4c047a65c4'
});

const metrics = {
  totalTests: tests.length,
  avgEffectiveness: calculateAverage(tests),
  tierDistribution: calculateTiers(tests)
};
```

### Step 2: Generate Report

```javascript
console.log(`# Output Style Effectiveness Report`);
console.log(`**Timeframe**: ${timeframe}`);
console.log(`\n## Summary Metrics`);
console.log(`- Total Tests: ${metrics.totalTests}`);
console.log(`- Average Effectiveness: ${metrics.avgEffectiveness}/100`);
```

---

## Execution Example

```bash
/style:effectiveness-report --timeframe=30d
```

**Output:**
```
# Output Style Effectiveness Report
**Timeframe**: Last 30 days

## Summary Metrics
- Total Tests: 47
- Average Effectiveness: 82.3/100

## Top Performing Styles
1. brookside-professional: 88.7/100
2. technical-deep-dive: 85.2/100
```

---

## Success Criteria

- ✅ Style tests fetched
- ✅ Metrics calculated
- ✅ Report generated

---

## Related Commands

- `/test-agent-style` - Run new tests
- `/style:assign-default` - Set build default

---

**Last Updated**: 2025-10-26
**Database**: Agent Style Tests (`b109b417-2e3f-4eba-bab1-9d4c047a65c4`)
