---
name: cost:identify-waste
description: Establish comprehensive software waste identification across portfolio to surface underutilized subscriptions and drive immediate cost reduction opportunities
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-fetch
argument-hint: [--threshold=percentage] [--min-cost=amount]
model: claude-sonnet-4-5-20250929
---

# /cost:identify-waste

**Category**: Cost Management
**Related Databases**: Software & Cost Tracker
**Agent Compatibility**: @cost-analyst

## Purpose

Establish systematic identification of underutilized software subscriptions across the entire portfolio to surface immediate cost optimization opportunities and drive measurable annual savings through subscription rightsizing, consolidation, or cancellation—designed for organizations seeking data-driven cost reduction without impacting operations.

**Best for**: Quarterly cost reviews, budget planning cycles, or rapid cost reduction initiatives requiring portfolio-wide visibility into license waste and optimization potential.

---

## Command Parameters

**Optional Flags:**
- `--threshold=N` - Utilization threshold % for "waste" classification (default: 70%)
- `--min-cost=N` - Minimum monthly cost to include (filter out low-value items)
- `--category=name` - Filter by software category
- `--exclude-critical` - Exclude Mission Critical software from analysis

---

## Workflow

### Step 1: Fetch All Software Entries

```javascript
// Get complete Software Tracker
const allSoftware = await notionSearch({
  query: "",
  data_source_url: "collection://13b5e9de-2dd1-45ec-839a-4f3d50cd8d06"
});

console.log(`📊 Analyzing ${allSoftware.results.length} software entries...\n`);
```

### Step 2: Filter and Analyze Utilization

```javascript
const threshold = thresholdFlag || 70;
const minCost = minCostFlag || 0;

const wasteAnalysis = [];

for (const sw of allSoftware.results) {
  const details = await notionFetch({ id: sw.id });

  const name = details.properties.Name?.title?.[0]?.plain_text;
  const cost = details.properties.Cost?.number || 0;
  const utilization = details.properties["Utilization %"]?.number;
  const licensedSeats = details.properties["Licensed Seats"]?.number;
  const actualUsers = details.properties["Actual Users"]?.number;
  const category = details.properties.Category?.select?.name;
  const criticality = details.properties.Criticality?.select?.name;

  // Skip if no utilization data
  if (utilization === null || utilization === undefined) continue;

  // Apply filters
  if (cost < minCost) continue;
  if (categoryFlag && category !== categoryFlag) continue;
  if (excludeCriticalFlag && criticality === "Mission Critical") continue;

  // Identify waste
  if (utilization < threshold) {
    const wastedSeats = licensedSeats - actualUsers;
    const costPerSeat = licensedSeats > 0 ? cost / licensedSeats : 0;
    const monthlyWaste = wastedSeats * costPerSeat;
    const annualWaste = monthlyWaste * 12;

    wasteAnalysis.push({
      name,
      cost,
      utilization,
      licensedSeats,
      actualUsers,
      wastedSeats,
      monthlyWaste,
      annualWaste,
      category,
      criticality,
      severity: utilization < 50 ? 'CRITICAL' : 'MODERATE'
    });
  }
}

// Sort by annual waste (highest first)
wasteAnalysis.sort((a, b) => b.annualWaste - a.annualWaste);
```

### Step 3: Calculate Portfolio Metrics

```javascript
const totalMonthlyWaste = wasteAnalysis.reduce((sum, item) => sum + item.monthlyWaste, 0);
const totalAnnualWaste = totalMonthlyWaste * 12;
const criticalCount = wasteAnalysis.filter(item => item.severity === 'CRITICAL').length;
const moderateCount = wasteAnalysis.filter(item => item.severity === 'MODERATE').length;

console.log(`╔══════════════════════════════════════════════════════════════════╗`);
console.log(`║          SOFTWARE WASTE IDENTIFICATION REPORT                   ║`);
console.log(`╚══════════════════════════════════════════════════════════════════╝\n`);

console.log(`📊 **Portfolio Summary:**`);
console.log(`   Total Underutilized: ${wasteAnalysis.length} subscriptions`);
console.log(`   Critical (<50%): ${criticalCount}`);
console.log(`   Moderate (50-${threshold}%): ${moderateCount}\n`);

console.log(`💰 **Waste Metrics:**`);
console.log(`   Monthly Waste: $${totalMonthlyWaste.toFixed(2)}`);
console.log(`   Annual Waste: $${totalAnnualWaste.toFixed(2)}\n`);

console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);
```

### Step 4: Present Detailed Findings

```javascript
console.log(`🔻 **CRITICAL UNDERUTILIZATION** (<50%):\n`);

const critical = wasteAnalysis.filter(item => item.severity === 'CRITICAL');
critical.forEach((item, idx) => {
  console.log(`${idx + 1}. **${item.name}** (${item.category})`);
  console.log(`   Utilization: ${item.utilization}%`);
  console.log(`   Licensed: ${item.licensedSeats} | Active: ${item.actualUsers}`);
  console.log(`   Monthly Cost: $${item.cost} | Waste: $${item.monthlyWaste.toFixed(2)}/month`);
  console.log(`   **Annual Waste**: $${item.annualWaste.toFixed(2)}`);
  console.log(`   → **Action**: Immediate downgrade to ${item.actualUsers} seats\n`);
});

console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

console.log(`⚠️ **MODERATE UNDERUTILIZATION** (50-${threshold}%):\n`);

const moderate = wasteAnalysis.filter(item => item.severity === 'MODERATE');
moderate.slice(0, 5).forEach((item, idx) => {
  console.log(`${idx + 1}. ${item.name} - ${item.utilization}% → Save $${item.annualWaste.toFixed(2)}/year`);
});

if (moderate.length > 5) {
  console.log(`   ... plus ${moderate.length - 5} more\n`);
}
```

### Step 5: Generate Action Plan

```javascript
console.log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

console.log(`📋 **RECOMMENDED ACTIONS:**\n`);

console.log(`**Immediate (This Month):**`);
critical.slice(0, 3).forEach((item, idx) => {
  console.log(`   ${idx + 1}. Downgrade ${item.name}: ${item.licensedSeats} → ${item.actualUsers} seats`);
  console.log(`      Savings: $${item.monthlyWaste.toFixed(2)}/month ($${item.annualWaste.toFixed(2)}/year)`);
});

console.log(`\n**Next Renewal:**`);
moderate.slice(0, 3).forEach((item, idx) => {
  console.log(`   ${idx + 1}. Review ${item.name} utilization before renewal`);
});

console.log(`\n**Total Potential Savings:** $${totalAnnualWaste.toFixed(2)}/year\n`);

console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

console.log(`**Next Steps:**`);
console.log(`   1. Develop plan: /cost:consolidation-plan`);
console.log(`   2. Update usage: /cost:track-usage "software-name" --actual-users=X`);
console.log(`   3. Review quarterly to maintain optimization\n`);
```

---

## Execution Examples

### Example 1: Standard Waste Identification

```bash
/cost:identify-waste
```

**Output:**
```
📊 Analyzing 32 software entries...

╔══════════════════════════════════════════════════════════════════╗
║          SOFTWARE WASTE IDENTIFICATION REPORT                   ║
╚══════════════════════════════════════════════════════════════════╝

📊 **Portfolio Summary:**
   Total Underutilized: 8 subscriptions
   Critical (<50%): 3
   Moderate (50-70%): 5

💰 **Waste Metrics:**
   Monthly Waste: $1,847.00
   Annual Waste: $22,164.00

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔻 **CRITICAL UNDERUTILIZATION** (<50%):

1. **GitHub Copilot** (Development Tools)
   Utilization: 48%
   Licensed: 25 | Active: 12
   Monthly Cost: $1,300 | Waste: $624.00/month
   **Annual Waste**: $7,488.00
   → **Action**: Immediate downgrade to 12 seats

2. **Figma Professional** (Design & Creative)
   Utilization: 35%
   Licensed: 20 | Active: 7
   Monthly Cost: $900 | Waste: $585.00/month
   **Annual Waste**: $7,020.00
   → **Action**: Immediate downgrade to 7 seats

3. **Snowflake** (Data & Analytics)
   Utilization: 42%
   Licensed: 15 | Active: 6
   Monthly Cost: $2,100 | Waste: $810.00/month
   **Annual Waste**: $9,720.00
   → **Action**: Immediate downgrade to 6 seats

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ **MODERATE UNDERUTILIZATION** (50-70%):

1. Tableau - 62% → Save $3,456.00/year
2. Datadog - 58% → Save $2,880.00/year
3. Slack Enterprise - 65% → Save $1,920.00/year
4. Adobe Creative Cloud - 68% → Save $1,440.00/year
5. Zoom Webinar - 55% → Save $1,200.00/year

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 **RECOMMENDED ACTIONS:**

**Immediate (This Month):**
   1. Downgrade GitHub Copilot: 25 → 12 seats
      Savings: $624.00/month ($7,488.00/year)
   2. Downgrade Figma Professional: 20 → 7 seats
      Savings: $585.00/month ($7,020.00/year)
   3. Downgrade Snowflake: 15 → 6 seats
      Savings: $810.00/month ($9,720.00/year)

**Next Renewal:**
   1. Review Tableau utilization before renewal
   2. Review Datadog utilization before renewal
   3. Review Slack Enterprise utilization before renewal

**Total Potential Savings:** $22,164.00/year

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Next Steps:**
   1. Develop plan: /cost:consolidation-plan
   2. Update usage: /cost:track-usage "software-name" --actual-users=X
   3. Review quarterly to maintain optimization
```

---

### Example 2: High-Value Waste Only

```bash
/cost:identify-waste --min-cost=500 --threshold=60
```

**Output:**
```
📊 Analyzing 32 software entries...
   Filtering: Cost ≥ $500, Utilization < 60%

[... report showing only high-cost, underutilized software ...]

💰 **Waste Metrics:**
   Monthly Waste: $2,019.00
   Annual Waste: $24,228.00

[... focused on top savings opportunities ...]
```

---

### Example 3: Exclude Critical Software

```bash
/cost:identify-waste --exclude-critical
```

**Output:**
```
📊 Analyzing 32 software entries...
   Excluding: Mission Critical software

[... report excluding critical business systems ...]
```

---

## Error Handling

### Error 1: No Software Entries

```
❌ No software entries in tracker

Add software: /cost:add-software "name" <cost>
```

---

### Error 2: No Utilization Data

```
⚠️ No software entries have utilization data tracked

Track usage first:
   /cost:track-usage "software-name" --actual-users=X --licensed-seats=Y

Then retry: /cost:identify-waste
```

---

## Success Criteria

- ✅ Portfolio analyzed for utilization
- ✅ Waste metrics calculated (monthly and annual)
- ✅ Critical vs. moderate underutilization categorized
- ✅ Action plan with prioritized recommendations
- ✅ Total savings potential quantified

---

## Related Commands

- `/cost:track-usage [name]` - Update utilization data
- `/cost:consolidation-plan` - Develop optimization strategy
- `/cost:analyze active` - View all active subscriptions

---

## Best Practices

1. **Run Quarterly** - Identify waste every 3 months
2. **Act on Critical** - Prioritize <50% utilization
3. **Document Decisions** - Track why you kept underutilized software
4. **Track Before/After** - Measure actual savings achieved

---

## Notes for Claude Code

**When to use:** User asks to find waste, identify underutilized software, or reduce costs

**Execution:**
1. Fetch all software from tracker
2. Filter by utilization threshold
3. Calculate waste metrics
4. Sort by savings potential
5. Generate prioritized action plan

**Performance:** 15-30 seconds (depends on portfolio size)

---

**Last Updated**: 2025-10-26
**Database**: Software & Cost Tracker (13b5e9de-2dd1-45ec-839a-4f3d50cd8d06)
