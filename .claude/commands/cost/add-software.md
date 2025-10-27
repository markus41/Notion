---
description: Add new software to Software Tracker with accurate cost data and automatic relation setup
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-create-pages, mcp__notion__notion-fetch
argument-hint: <software-name> <monthly-cost> [--category=type] [--criticality=level]
model: claude-sonnet-4-5-20250929
---

## Context

Streamline software procurement tracking by establishing centralized cost visibility and automated linkage to related work items, designed to drive measurable financial outcomes through transparent expense management.

## Workflow

### Step 1: Search for Duplicates

```javascript
// Prevent duplicate entries
const existingResults = await notionSearch({
  query: softwareName,
  data_source_url: "collection://13b5e9de-2dd1-45ec-839a-4f3d50cd8d06"
});

if (existingResults.results.length > 0) {
  console.log(`⚠️ Found ${existingResults.results.length} existing entries:`);
  existingResults.results.forEach(entry => {
    console.log(`  - ${entry.title} (${entry.properties.Status})`);
  });

  // Ask user if they want to proceed or update existing
  const shouldProceed = await askUser(
    "Software may already exist. Create new entry anyway?"
  );

  if (!shouldProceed) return;
}
```

### Step 2: Gather Software Details

```javascript
// Collect required information
const softwareData = {
  name: args[0],                          // Required: Software name
  cost: parseFloat(args[1]),              // Required: Monthly cost
  category: flags.category || inferCategory(args[0]),
  criticality: flags.criticality || "🟡 Important",
  status: "🟢 Active",
  paymentFrequency: "Monthly",
  vendor: flags.vendor || extractVendor(args[0]),
  authMethod: flags.auth || "API Key",
  purpose: flags.purpose || await askUser("Brief purpose description:"),
  licenses: flags.licenses || 1,
  documentationUrl: flags.docs || ""
};

// Category inference logic
function inferCategory(name) {
  const patterns = {
    "AI/ML": ["OpenAI", "Azure OpenAI", "GPT", "Claude", "AI"],
    "Infrastructure": ["Azure", "AWS", "Docker", "Kubernetes"],
    "Development": ["GitHub", "VS Code", "npm", "Node"],
    "Analytics": ["Power BI", "Tableau", "Looker"],
    "Productivity": ["Notion", "Slack", "Teams", "Office"],
    "Security": ["Auth0", "Okta", "Key Vault"]
  };

  for (const [category, keywords] of Object.entries(patterns)) {
    if (keywords.some(kw => name.includes(kw))) return category;
  }

  return "Productivity"; // Default
}
```

### Step 3: Calculate Totals

```javascript
// Auto-calculate derived fields
const totalMonthlyCost = softwareData.cost * softwareData.licenses;
const annualCost = totalMonthlyCost * 12;

console.log(`\n💰 Cost Summary:`);
console.log(`   Monthly: $${totalMonthlyCost.toFixed(2)}`);
console.log(`   Annual: $${annualCost.toFixed(2)}`);
```

### Step 4: Create Software Tracker Entry

```javascript
const newEntry = await notionCreatePages({
  parent: {
    data_source_id: "13b5e9de-2dd1-45ec-839a-4f3d50cd8d06"
  },
  pages: [{
    properties: {
      "Name": softwareData.name,
      "Cost": softwareData.cost,
      "License Count": softwareData.licenses,
      "Payment Frequency": softwareData.paymentFrequency,
      "Category": softwareData.category,
      "Criticality": softwareData.criticality,
      "Authentication Method": softwareData.authMethod,
      "Status": softwareData.status,
      "Purpose": softwareData.purpose,
      "Vendor": softwareData.vendor,
      "Documentation URL": softwareData.documentationUrl,
      "Subscription Type": "Per Month"
    }
  }]
});

console.log(`\n✅ Created: ${softwareData.name}`);
console.log(`   Entry URL: ${newEntry.pages[0].url}`);
```

### Step 5: Link to Related Work Items (Optional)

```javascript
// If --link-to flag provided, create relations
if (flags.linkTo) {
  const relatedItems = flags.linkTo.split(',');

  for (const itemName of relatedItems) {
    // Search in Ideas, Research, or Builds
    const item = await findWorkItem(itemName);

    if (item) {
      await updateWorkItemSoftwareRelation(item, newEntry.pages[0].id);
      console.log(`   🔗 Linked to: ${item.title}`);
    }
  }
}
```

### Step 6: Check for Microsoft Alternatives

```javascript
// Proactive Microsoft ecosystem check
if (!softwareData.name.includes("Microsoft") &&
    !softwareData.name.includes("Azure") &&
    !softwareData.name.includes("M365")) {

  const msAlternative = await checkMicrosoftAlternative(
    softwareData.name,
    softwareData.category
  );

  if (msAlternative) {
    console.log(`\n💡 Microsoft Alternative Available:`);
    console.log(`   ${msAlternative.name} - ${msAlternative.service}`);
    console.log(`   Estimated cost: $${msAlternative.cost}/month`);
    console.log(`   Run: /cost:microsoft-alternatives "${softwareData.name}"`);
  }
}
```

### Step 7: Summary Report

```javascript
console.log(`\n📊 Software Added Successfully\n`);
console.log(`**${softwareData.name}**`);
console.log(`Category: ${softwareData.category}`);
console.log(`Monthly Cost: $${totalMonthlyCost} (${softwareData.licenses} licenses)`);
console.log(`Annual Cost: $${annualCost}`);
console.log(`Criticality: ${softwareData.criticality}`);
console.log(`Status: ${softwareData.status}`);
console.log(`\n**Next Steps:**`);
console.log(`- Link to active Ideas/Research/Builds: /build:link-software`);
console.log(`- View total spend impact: /cost:monthly-spend`);
console.log(`- Check for consolidation: /cost:consolidation-opportunities`);
```

---

## Parameters

**Required:**
- `<software-name>` - Name of the software/service
- `<monthly-cost>` - Cost per license per month (numeric)

**Optional Flags:**
- `--category=type` - Category (AI/ML, Infrastructure, Development, etc.)
- `--criticality=level` - Criticality (🔴 Critical | 🟡 Important | 🟢 Nice to Have)
- `--licenses=N` - Number of licenses (default: 1)
- `--vendor=name` - Vendor/provider name
- `--auth=method` - Authentication method (API Key, OAuth, SSO, etc.)
- `--purpose="description"` - Brief purpose statement
- `--docs=url` - Documentation URL
- `--link-to="item1,item2"` - Comma-separated list of Ideas/Research/Builds to link

---

## Examples

### Example 1: Basic Software Addition

```bash
/cost:add-software "Webflow" 74
```

**Expected Output:**
```
🔍 Checking for existing entries...
✅ No duplicates found

💰 Cost Summary:
   Monthly: $74.00
   Annual: $888.00

✅ Created: Webflow
   Entry URL: https://www.notion.so/...

💡 Microsoft Alternative Available:
   Azure Static Web Apps - Azure
   Estimated cost: $9/month
   Run: /cost:microsoft-alternatives "Webflow"

📊 Software Added Successfully

**Webflow**
Category: Productivity
Monthly Cost: $74 (1 licenses)
Annual Cost: $888
Criticality: 🟡 Important
Status: 🟢 Active

**Next Steps:**
- Link to active Ideas/Research/Builds: /build:link-software
- View total spend impact: /cost:monthly-spend
- Check for consolidation: /cost:consolidation-opportunities
```

### Example 2: Software with Full Metadata

```bash
/cost:add-software "Azure OpenAI" 0.50 \
  --category="AI/ML" \
  --criticality="🔴 Critical" \
  --licenses=1 \
  --vendor="Microsoft" \
  --auth="API Key" \
  --purpose="AI-powered content generation for blog automation" \
  --docs="https://learn.microsoft.com/azure/ai-services/openai/" \
  --link-to="Blog Automation Build"
```

**Expected Output:**
```
🔍 Checking for existing entries...
✅ No duplicates found

💰 Cost Summary:
   Monthly: $0.50
   Annual: $6.00

✅ Created: Azure OpenAI
   Entry URL: https://www.notion.so/...
   🔗 Linked to: Blog Automation Build

📊 Software Added Successfully

**Azure OpenAI**
Category: AI/ML
Monthly Cost: $0.50 (1 licenses)
Annual Cost: $6
Criticality: 🔴 Critical
Status: 🟢 Active

**Next Steps:**
- Link to active Ideas/Research/Builds: /build:link-software
- View total spend impact: /cost:monthly-spend
- Check for consolidation: /cost:consolidation-opportunities
```

### Example 3: Multiple Licenses

```bash
/cost:add-software "GitHub Copilot" 10 \
  --licenses=5 \
  --category="Development" \
  --criticality="🟡 Important"
```

**Expected Output:**
```
💰 Cost Summary:
   Monthly: $50.00 (5 licenses × $10)
   Annual: $600.00

✅ Created: GitHub Copilot
   Entry URL: https://www.notion.so/...

📊 Software Added Successfully

**GitHub Copilot**
Category: Development
Monthly Cost: $50 (5 licenses)
Annual Cost: $600
Criticality: 🟡 Important
Status: 🟢 Active
```

---

## Error Handling

### Error 1: Duplicate Entry Detected

**Scenario**: Software name already exists in Software Tracker

**Response:**
```
⚠️ Found 1 existing entry:
  - Webflow (🟢 Active)

❓ Software may already exist. Create new entry anyway? (y/n)
```

**Resolution**: User confirms or cancels operation

### Error 2: Invalid Cost Format

**Scenario**: Non-numeric cost provided

**Response:**
```
❌ Invalid cost format: "seventy-four"

💡 **Correct Format:**
   /cost:add-software "Webflow" 74

Cost must be a numeric value (monthly cost per license).
```

### Error 3: Missing Required Parameters

**Scenario**: Software name or cost not provided

**Response:**
```
❌ Missing required parameters

**Usage:**
   /cost:add-software <software-name> <monthly-cost> [flags]

**Example:**
   /cost:add-software "Notion" 8 --licenses=5

See command documentation for full parameter list.
```

---

## Success Criteria

After successful execution, verify:

- ✅ New entry created in Software Tracker database
- ✅ Cost fields calculated correctly (Total Monthly Cost, Annual Cost)
- ✅ Category inferred or set appropriately
- ✅ No duplicate entries created
- ✅ Related work items linked (if specified)
- ✅ Microsoft alternative flagged (if applicable)
- ✅ Entry URL returned for verification

---

## Related Commands

**Before this command:**
- `/cost:monthly-spend` - Check current total before adding
- `/cost:consolidation-opportunities` - Verify no duplicates exist

**After this command:**
- `/build:link-software [build-name] [software-name]` - Link to builds
- `/cost:monthly-spend` - View updated total
- `/cost:microsoft-alternatives [software-name]` - Check ecosystem options

**Maintenance workflow:**
- Run `/cost:unused-software` quarterly to identify optimization opportunities
- Run `/cost:consolidation-opportunities` after adding multiple tools

---

## Best Practices

### 1. Search First, Create Second
Always verify software doesn't already exist. Duplicate entries corrupt cost rollups and analytics.

### 2. Use Accurate Monthly Costs
Enter the actual per-license monthly cost, not total cost. The command will calculate totals based on license count.

### 3. Link to Work Items Immediately
Use `--link-to` flag or run `/build:link-software` right after creation to establish cost tracking for projects.

### 4. Check Microsoft Alternatives
For third-party tools, review suggested Microsoft alternatives to align with ecosystem strategy and potentially reduce costs.

### 5. Document Purpose Clearly
Provide meaningful purpose descriptions that explain business value, not just technical function.

---

## Notes for Claude Code

**When to use this command:**
- User mentions purchasing new software
- User asks to "add [software] to cost tracker"
- User wants to track new subscription or service
- During build planning when new tools are identified

**Execution approach:**
1. Confirm software name and monthly cost with user
2. Search for duplicates (CRITICAL - prevents data corruption)
3. Infer category from software name patterns
4. Create entry with complete metadata
5. Suggest immediate linking to related work items
6. Flag Microsoft alternatives for third-party tools

**Common mistakes to avoid:**
- Creating duplicates (always search first)
- Confusing total cost with per-license cost
- Skipping purpose documentation
- Not linking to related work items
- Missing Microsoft alternative checks

**Performance Considerations:**
- Duplicate search: ~2 seconds
- Entry creation: ~3 seconds
- Total execution: ~5-10 seconds
- Linking work items: +2 seconds per item

---

**Last Updated**: 2025-10-26
**Command Version**: 1.0.0
**Database**: Software & Cost Tracker (13b5e9de-2dd1-45ec-839a-4f3d50cd8d06)
