---
name: cost:track-usage
description: Establish software license utilization monitoring to identify underutilized subscriptions and drive cost optimization through data-driven rightsizing decisions
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-fetch, mcp__notion__notion-update-page
argument-hint: [software-name] [--actual-users=N] [--licensed-seats=N]
model: claude-sonnet-4-5-20250929
---

# /cost:track-usage

**Category**: Cost Management
**Related Databases**: Software & Cost Tracker
**Agent Compatibility**: @cost-analyst

## Purpose

Establish comprehensive software license utilization tracking to identify underutilized subscriptions and drive measurable cost savings through data-driven rightsizing recommendations—designed for organizations managing multiple SaaS subscriptions where license waste represents significant annual expenditure.

**Best for**: Organizations with 10+ software subscriptions requiring visibility into actual vs. licensed usage to inform renewal negotiations and cost reduction initiatives.

---

## Command Parameters

**Required:**
- `software-name` - Name or partial match in Software Tracker

**Optional Flags:**
- `--actual-users=N` - Current active user count
- `--licensed-seats=N` - Total licensed seats
- `--utilization=N` - Utilization percentage (auto-calculated if users/seats provided)
- `--usage-notes="text"` - Context about usage patterns

---

## Workflow

### Step 1: Search Software

```javascript
const softwareResults = await notionSearch({
  query: softwareName,
  data_source_url: "collection://13b5e9de-2dd1-45ec-839a-4f3d50cd8d06"
});

if (softwareResults.results.length === 0) {
  console.error(`❌ No software found: "${softwareName}"`);
  console.log(`Add: /cost:add-software "${softwareName}" <cost>`);
  return;
}
```

### Step 2: Calculate Utilization

```javascript
let utilization = utilizationFlag;

if (actualUsersFlag && licensedSeatsFlag && !utilizationFlag) {
  utilization = Math.round((actualUsersFlag / licensedSeatsFlag) * 100);
  console.log(`📊 Calculated utilization: ${utilization}%`);
}

const wastedSeats = licensedSeatsFlag - actualUsersFlag;
const costPerSeat = monthlyCost / licensedSeatsFlag;
const monthlyWaste = wastedSeats * costPerSeat;
const annualWaste = monthlyWaste * 12;
```

### Step 3: Generate Recommendations

```javascript
let recommendations = [];

if (utilization < 50) {
  recommendations.push(`🔻 CRITICAL: ${utilization}% utilization`);
  recommendations.push(`   Downgrade to ${actualUsersFlag} seats → Save $${monthlyWaste}/month`);
} else if (utilization < 70) {
  recommendations.push(`⚠️ MODERATE: ${utilization}% utilization`);
  recommendations.push(`   Review at renewal → Potential $${monthlyWaste}/month savings`);
} else {
  recommendations.push(`✅ OPTIMAL: ${utilization}% utilization`);
}
```

### Step 4: Update Tracker

```javascript
await notionUpdatePage({
  page_id: selectedSoftware.id,
  data: {
    command: "update_properties",
    properties: {
      "Actual Users": actualUsersFlag,
      "Licensed Seats": licensedSeatsFlag,
      "Utilization %": utilization
    }
  }
});

console.log(`✅ Usage tracking updated`);
```

---

## Execution Examples

### Example 1: Critical Underutilization

```bash
/cost:track-usage "GitHub Copilot" --actual-users=12 --licensed-seats=25
```

**Output:**
```
📊 Calculated utilization: 48%

💰 Usage Analysis:
   Licensed: 25 seats
   Active: 12 users
   Utilization: 48%
   Monthly Waste: $624
   Annual Waste: $7,488

✅ Usage tracking updated

🔻 CRITICAL: 48% utilization
   Downgrade to 12 seats → Save $624/month

Next: /cost:identify-waste (find all underutilized software)
```

---

### Example 2: Healthy Utilization

```bash
/cost:track-usage "Power BI Pro" --actual-users=47 --licensed-seats=50
```

**Output:**
```
📊 Calculated utilization: 94%

✅ OPTIMAL: 94% utilization
   No action needed

Monitor monthly: /cost:track-usage "Power BI Pro" --actual-users=X
```

---

## Error Handling

### Error 1: Software Not Found

```
❌ No software found: "Unknown"

Add: /cost:add-software "Unknown" <cost>
```

---

### Error 2: Missing Data

```
⚠️ Insufficient data for utilization calculation

Provide: --actual-users AND --licensed-seats
```

---

## Success Criteria

- ✅ Software located
- ✅ Utilization calculated
- ✅ Waste metrics computed
- ✅ Recommendations provided
- ✅ Tracker updated

---

## Related Commands

- `/cost:add-software [name] [cost]` - Add to tracker
- `/cost:identify-waste` - Find all underutilized software
- `/cost:consolidation-plan` - Develop optimization strategy

---

## Best Practices

1. **Track Monthly** - Update usage data monthly
2. **Act on <50%** - Critical underutilization requires immediate action
3. **Document Context** - Use `--usage-notes` for trends

---

## Notes for Claude Code

**When to use:** User mentions tracking usage, license utilization, or waste identification

**Execution:**
1. Search software
2. Calculate utilization and waste
3. Generate tailored recommendations
4. Update tracker

**Performance:** 5-8 seconds

---

**Last Updated**: 2025-10-26
**Database**: Software & Cost Tracker (13b5e9de-2dd1-45ec-839a-4f3d50cd8d06)
