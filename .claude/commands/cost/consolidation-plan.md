---
name: cost:consolidation-plan
description: Establish strategic software consolidation roadmap with Microsoft ecosystem migration paths to drive measurable cost reduction and operational simplification
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-fetch, WebSearch
argument-hint: [--target-savings=amount] [--timeline=months]
model: claude-sonnet-4-5-20250929
---

# /cost:consolidation-plan

**Category**: Cost Management
**Related Databases**: Software & Cost Tracker
**Agent Compatibility**: @cost-analyst

## Purpose

Establish comprehensive software consolidation strategy that identifies Microsoft ecosystem migration opportunities, calculates ROI, and produces actionable implementation roadmap to drive measurable annual cost reduction while maintaining or improving operational capabilities—designed for organizations seeking strategic cost optimization aligned with Microsoft-first principles.

**Best for**: Annual budget planning, cost reduction initiatives, or strategic vendor consolidation where Microsoft 365/Azure alternatives can replace third-party tools with 20-40% cost savings.

---

## Command Parameters

**Optional Flags:**
- `--target-savings=N` - Target annual savings goal (dollars)
- `--timeline=N` - Implementation timeline (months, default: 12)
- `--category=name` - Focus on specific software category
- `--microsoft-only` - Only suggest Microsoft alternatives

---

## Workflow

### Step 1: Analyze Current Portfolio

```javascript
// Fetch all non-Microsoft software
const allSoftware = await notionSearch({
  query: "",
  data_source_url: "collection://13b5e9de-2dd1-45ec-839a-4f3d50cd8d06"
});

const candidates = [];
let totalCurrentCost = 0;

for (const sw of allSoftware.results) {
  const details = await notionFetch({ id: sw.id });

  const name = details.properties.Name?.title?.[0]?.plain_text;
  const cost = details.properties.Cost?.number || 0;
  const category = details.properties.Category?.select?.name;
  const isMicrosoft = details.properties["Microsoft Service"]?.checkbox;
  const criticality = details.properties.Criticality?.select?.name;

  // Skip Microsoft services (already optimized)
  if (isMicrosoft) continue;

  // Apply category filter
  if (categoryFlag && category !== categoryFlag) continue;

  totalCurrentCost += cost;

  candidates.push({
    name,
    cost,
    category,
    criticality
  });
}

console.log(`📊 Analyzing ${candidates.length} consolidation candidates...\n`);
```

### Step 2: Identify Microsoft Alternatives

```javascript
// Microsoft ecosystem replacement mapping
const microsoftAlternatives = {
  // Collaboration & Communication
  'Slack': { service: 'Microsoft Teams', savings: '40-60%', capability: 'Full replacement' },
  'Zoom': { service: 'Microsoft Teams', savings: '30-50%', capability: 'Full replacement' },
  'Asana': { service: 'Microsoft Planner / Project', savings: '20-35%', capability: 'Most features' },
  'Monday.com': { service: 'Microsoft Planner / Lists', savings: '25-40%', capability: 'Core features' },

  // Data & Analytics
  'Snowflake': { service: 'Azure Synapse Analytics', savings: '20-33%', capability: 'Full replacement' },
  'Databricks': { service: 'Azure Databricks', savings: '15-25%', capability: 'Full replacement' },
  'Tableau': { service: 'Power BI', savings: '40-60%', capability: 'Full replacement' },

  // Development & DevOps
  'GitLab': { service: 'Azure DevOps / GitHub', savings: '20-35%', capability: 'Full replacement' },
  'Jenkins': { service: 'Azure Pipelines', savings: '30-45%', capability: 'Full replacement' },

  // Design & Creative
  'Figma': { service: 'Microsoft Designer / PowerPoint', savings: '15-30%', capability: 'Limited' },
  'Adobe Acrobat': { service: 'Microsoft Edge PDF', savings: '100%', capability: 'Basic features' },

  // Storage & File Sharing
  'Dropbox': { service: 'OneDrive / SharePoint', savings: '40-60%', capability: 'Full replacement' },
  'Box': { service: 'SharePoint / OneDrive', savings: '35-55%', capability: 'Full replacement' }
};

const consolidationPlan = [];

for (const candidate of candidates) {
  const alternative = microsoftAlternatives[candidate.name];

  if (alternative) {
    // Calculate savings
    const savingsRange = alternative.savings.split('-');
    const minSavings = (parseInt(savingsRange[0]) / 100) * candidate.cost;
    const maxSavings = (parseInt(savingsRange[1]) / 100) * candidate.cost;
    const avgSavings = (minSavings + maxSavings) / 2;

    consolidationPlan.push({
      current: candidate.name,
      msAlternative: alternative.service,
      currentCost: candidate.cost,
      estimatedSavings: avgSavings,
      annualSavings: avgSavings * 12,
      capability: alternative.capability,
      category: candidate.category,
      criticality: candidate.criticality
    });
  }
}

// Sort by annual savings (highest first)
consolidationPlan.sort((a, b) => b.annualSavings - a.annualSavings);
```

### Step 3: Calculate ROI and Timeline

```javascript
const totalAnnualSavings = consolidationPlan.reduce((sum, item) => sum + item.annualSavings, 0);
const timelineMonths = timelineFlag || 12;
const targetSavings = targetSavingsFlag || totalAnnualSavings;

// Estimate migration costs (10-15% of first year savings for planning/training)
const estimatedMigrationCost = totalAnnualSavings * 0.125;
const netFirstYearSavings = totalAnnualSavings - estimatedMigrationCost;
const roi = ((netFirstYearSavings / estimatedMigrationCost) * 100).toFixed(0);

console.log(`╔══════════════════════════════════════════════════════════════════╗`);
console.log(`║        SOFTWARE CONSOLIDATION PLAN                              ║`);
console.log(`╚══════════════════════════════════════════════════════════════════╝\n`);

console.log(`📊 **Portfolio Analysis:**`);
console.log(`   Current Tools: ${candidates.length}`);
console.log(`   Consolidation Opportunities: ${consolidationPlan.length}`);
console.log(`   Current Annual Cost: $${(totalCurrentCost * 12).toFixed(2)}\n`);

console.log(`💰 **Financial Projections:**`);
console.log(`   Total Annual Savings: $${totalAnnualSavings.toFixed(2)}`);
console.log(`   Estimated Migration Cost: $${estimatedMigrationCost.toFixed(2)}`);
console.log(`   Net Year 1 Savings: $${netFirstYearSavings.toFixed(2)}`);
console.log(`   ROI: ${roi}%`);
console.log(`   Payback Period: ${(estimatedMigrationCost / (totalAnnualSavings / 12)).toFixed(1)} months\n`);

console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);
```

### Step 4: Present Migration Roadmap

```javascript
console.log(`🗺️ **MIGRATION ROADMAP** (${timelineMonths}-Month Plan):\n`);

// Phase 1: Quick wins (Month 1-3)
console.log(`**Phase 1: Quick Wins** (Months 1-3)\n`);

const phase1 = consolidationPlan.filter(item =>
  item.capability === 'Full replacement' &&
  item.criticality !== 'Mission Critical'
).slice(0, 3);

phase1.forEach((item, idx) => {
  console.log(`${idx + 1}. Migrate: ${item.current} → ${item.msAlternative}`);
  console.log(`   Savings: $${item.annualSavings.toFixed(2)}/year`);
  console.log(`   Complexity: Low (${item.capability})\n`);
});

// Phase 2: Core migrations (Month 4-8)
console.log(`**Phase 2: Core Migrations** (Months 4-8)\n`);

const phase2 = consolidationPlan.filter(item =>
  !phase1.includes(item) &&
  item.capability === 'Full replacement'
).slice(0, 3);

phase2.forEach((item, idx) => {
  console.log(`${idx + 1}. Migrate: ${item.current} → ${item.msAlternative}`);
  console.log(`   Savings: $${item.annualSavings.toFixed(2)}/year`);
  console.log(`   Notes: ${item.criticality} - Plan carefully\n`);
});

// Phase 3: Complex migrations (Month 9-12)
console.log(`**Phase 3: Complex Migrations** (Months 9-12)\n`);

const phase3 = consolidationPlan.filter(item =>
  !phase1.includes(item) && !phase2.includes(item)
).slice(0, 3);

phase3.forEach((item, idx) => {
  console.log(`${idx + 1}. Evaluate: ${item.current} → ${item.msAlternative}`);
  console.log(`   Savings: $${item.annualSavings.toFixed(2)}/year`);
  console.log(`   Capability: ${item.capability} - May require feature gaps assessment\n`);
});

console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);
```

### Step 5: Generate Action Items

```javascript
console.log(`📋 **IMMEDIATE ACTIONS:**\n`);

console.log(`**This Month:**`);
console.log(`   1. Review Microsoft licensing: Ensure M365/Azure capacity`);
console.log(`   2. Pilot top migration: ${phase1[0]?.current || 'TBD'} → ${phase1[0]?.msAlternative || 'TBD'}`);
console.log(`   3. Document current workflows in ${phase1[0]?.current || 'target tool'}`);

console.log(`\n**Next Quarter:**`);
console.log(`   1. Complete Phase 1 migrations (Quick Wins)`);
console.log(`   2. Begin Phase 2 planning and user training`);
console.log(`   3. Track actual vs. projected savings`);

console.log(`\n**This Year:**`);
console.log(`   1. Complete all ${timelineMonths}-month roadmap phases`);
console.log(`   2. Achieve target savings: $${targetSavings.toFixed(2)}/year`);
console.log(`   3. Document lessons learned for continuous optimization\n`);

console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

console.log(`**Success Metrics:**`);
console.log(`   - Annual cost reduction: $${totalAnnualSavings.toFixed(2)}`);
console.log(`   - Tools consolidated: ${consolidationPlan.length}`);
console.log(`   - Microsoft ecosystem alignment: ${((consolidationPlan.length / candidates.length) * 100).toFixed(0)}%`);
console.log(`   - ROI: ${roi}% (payback in ${(estimatedMigrationCost / (totalAnnualSavings / 12)).toFixed(1)} months)\n`);
```

---

## Execution Examples

### Example 1: Full Consolidation Plan

```bash
/cost:consolidation-plan
```

**Output:**
```
📊 Analyzing 18 consolidation candidates...

╔══════════════════════════════════════════════════════════════════╗
║        SOFTWARE CONSOLIDATION PLAN                              ║
╚══════════════════════════════════════════════════════════════════╝

📊 **Portfolio Analysis:**
   Current Tools: 18
   Consolidation Opportunities: 12
   Current Annual Cost: $87,600.00

💰 **Financial Projections:**
   Total Annual Savings: $31,440.00
   Estimated Migration Cost: $3,930.00
   Net Year 1 Savings: $27,510.00
   ROI: 700%
   Payback Period: 1.5 months

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🗺️ **MIGRATION ROADMAP** (12-Month Plan):

**Phase 1: Quick Wins** (Months 1-3)

1. Migrate: Slack → Microsoft Teams
   Savings: $8,640.00/year
   Complexity: Low (Full replacement)

2. Migrate: Dropbox → OneDrive / SharePoint
   Savings: $4,800.00/year
   Complexity: Low (Full replacement)

3. Migrate: Tableau → Power BI
   Savings: $7,200.00/year
   Complexity: Low (Full replacement)

**Phase 2: Core Migrations** (Months 4-8)

1. Migrate: Snowflake → Azure Synapse Analytics
   Savings: $6,720.00/year
   Notes: Important - Plan carefully

2. Migrate: GitLab → Azure DevOps
   Savings: $2,880.00/year
   Notes: Important - Plan carefully

[... continues with Phase 3 ...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 **IMMEDIATE ACTIONS:**

**This Month:**
   1. Review Microsoft licensing: Ensure M365/Azure capacity
   2. Pilot top migration: Slack → Microsoft Teams
   3. Document current workflows in Slack

**Next Quarter:**
   1. Complete Phase 1 migrations (Quick Wins)
   2. Begin Phase 2 planning and user training
   3. Track actual vs. projected savings

**This Year:**
   1. Complete all 12-month roadmap phases
   2. Achieve target savings: $31,440.00/year
   3. Document lessons learned for continuous optimization

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Success Metrics:**
   - Annual cost reduction: $31,440.00
   - Tools consolidated: 12
   - Microsoft ecosystem alignment: 67%
   - ROI: 700% (payback in 1.5 months)
```

---

### Example 2: Targeted Savings Goal

```bash
/cost:consolidation-plan --target-savings=25000 --timeline=6
```

**Output:**
```
[... accelerated 6-month plan focused on reaching $25,000 savings ...]

**Phase 1: Aggressive Quick Wins** (Months 1-2)
   Focus on highest-savings opportunities to reach target

**Phase 2: Rapid Deployment** (Months 3-6)
   Parallel migrations to compress timeline
```

---

## Error Handling

### Error 1: No Consolidation Opportunities

```
⚠️ No Microsoft consolidation opportunities found

All software is either:
- Already Microsoft services
- No known Microsoft alternative

Consider: Custom analysis for niche tools
```

---

### Error 2: Insufficient Portfolio Data

```
❌ Insufficient software entries for consolidation analysis

Add more software: /cost:add-software "name" <cost>
Current entries: 3 (recommend 10+ for meaningful analysis)
```

---

## Success Criteria

- ✅ Portfolio analyzed for consolidation
- ✅ Microsoft alternatives identified
- ✅ Financial projections calculated (savings, ROI, payback)
- ✅ Phased migration roadmap generated
- ✅ Action items with timeline provided

---

## Related Commands

- `/cost:identify-waste` - Find underutilized software first
- `/cost:track-usage [name]` - Monitor usage before migration
- `/cost:add-software [name]` - Add Microsoft alternatives after migration

---

## Best Practices

1. **Pilot First** - Test Microsoft alternative with small team
2. **Document Workflows** - Capture current processes before migration
3. **Train Users** - Invest in adoption to realize full value
4. **Track Actual Savings** - Measure results vs. projections

---

## Notes for Claude Code

**When to use:** User asks about consolidation, Microsoft migration, or cost reduction strategy

**Execution:**
1. Analyze non-Microsoft software
2. Map to Microsoft alternatives
3. Calculate savings and ROI
4. Generate phased roadmap
5. Provide actionable next steps

**Performance:** 20-40 seconds (depends on portfolio size and web research)

---

**Last Updated**: 2025-10-26
**Database**: Software & Cost Tracker (13b5e9de-2dd1-45ec-839a-4f3d50cd8d06)