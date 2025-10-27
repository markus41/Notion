---
name: idea:assess
description: Establish comprehensive viability assessment for existing ideas to drive informed go/no-go decisions through structured evaluation framework
allowed-tools: Task(@viability-assessor:*), mcp__notion__notion-search, mcp__notion__notion-fetch, mcp__notion__notion-update-page
argument-hint: [idea-name] [--force] [--context="additional-info"]
model: claude-sonnet-4-5-20250929
---

# /idea:assess

**Category**: Innovation Lifecycle Management
**Related Databases**: Ideas Registry
**Agent Compatibility**: @viability-assessor

## Purpose

Establish comprehensive viability assessment for existing ideas by evaluating feasibility, impact, effort, team capability, and strategic alignment. Drive measurable outcomes through structured evaluation that produces actionable go/no-go recommendations with numeric scoring (0-100) to support data-driven decision making across the innovation portfolio.

**Best for**: Organizations requiring objective evaluation criteria to prioritize innovation investments, assess strategic fit, and make transparent decisions about which ideas warrant research or build resources.

---

## Command Parameters

**Required:**
- `idea-name` - Name or partial match of existing idea in Ideas Registry

**Optional Flags:**
- `--force` - Re-assess even if recent assessment exists (<7 days)
- `--context="text"` - Additional context for updated evaluation (market changes, new capabilities, budget shifts)
- `--champion=person` - Override champion for capability assessment
- `--update-status` - Auto-update idea Status based on viability score

---

## Workflow

### Step 1: Search and Validate Idea Exists

```javascript
// CRITICAL: Verify idea exists before assessment
const ideaResults = await notionSearch({
  query: ideaName,
  data_source_url: "collection://984a4038-3e45-4a98-8df4-fd64dd8a1032"
});

if (ideaResults.results.length === 0) {
  console.error(`❌ No idea found matching: "${ideaName}"`);
  console.log(`\n💡 **Suggestions:**`);
  console.log(`   - Search broader: /idea:search "${ideaName.split(' ')[0]}"`);
  console.log(`   - Create new idea: /idea:create "${ideaName}"`);
  return;
}

// Handle multiple matches
if (ideaResults.results.length > 1) {
  console.log(`⚠️ Multiple ideas match "${ideaName}":\n`);
  ideaResults.results.forEach((idea, idx) => {
    const title = idea.properties["Idea Name"]?.title?.[0]?.plain_text;
    const status = idea.properties.Status?.select?.name;
    const viability = idea.properties.Viability?.select?.name;
    const lastAssessed = idea.properties["Last Assessed"]?.date?.start;

    console.log(`${idx + 1}. ${title}`);
    console.log(`   Status: ${status} | Viability: ${viability}`);
    console.log(`   Last Assessed: ${lastAssessed || 'Never'}`);
    console.log(`   ${idea.url}\n`);
  });

  const selection = await promptUser("Select idea number to assess:");
  selectedIdea = ideaResults.results[parseInt(selection) - 1];
} else {
  selectedIdea = ideaResults.results[0];
}

console.log(`\n✅ Found: ${selectedIdea.properties["Idea Name"]?.title?.[0]?.plain_text}`);
```

### Step 2: Check Recent Assessment

```javascript
// Prevent redundant assessments
const lastAssessed = selectedIdea.properties["Last Assessed"]?.date?.start;

if (lastAssessed && !forceFlag) {
  const daysSince = Math.floor(
    (Date.now() - new Date(lastAssessed)) / (1000 * 60 * 60 * 24)
  );

  if (daysSince < 7) {
    const currentViability = selectedIdea.properties.Viability?.select?.name;
    const currentScore = selectedIdea.properties["Viability Score"]?.number;

    console.log(`⚠️ Idea assessed ${daysSince} days ago`);
    console.log(`   Current: ${currentViability} (${currentScore}/100)`);
    console.log(`\n💡 **Options:**`);
    console.log(`   A) Re-assess anyway: /idea:assess "${ideaName}" --force`);
    console.log(`   B) View current assessment: ${selectedIdea.url}`);
    console.log(`   C) Cancel and assess later`);

    const proceed = await promptUser("Re-assess now? (y/n)");
    if (!proceed) return;
  }
}
```

### Step 3: Fetch Complete Idea Details

```javascript
// Get full context for assessment
const ideaDetails = await notionFetch({
  id: selectedIdea.id
});

// Extract assessment inputs
const assessmentInputs = {
  ideaName: ideaDetails.properties["Idea Name"]?.title?.[0]?.plain_text,
  description: ideaDetails.properties.Description?.rich_text?.[0]?.plain_text || "",
  champion: ideaDetails.properties.Champion?.people?.[0]?.name || "Unassigned",
  estimatedCost: ideaDetails.properties["Estimated Monthly Cost"]?.number || 0,
  category: ideaDetails.properties.Category?.select?.name || "Other",
  strategicAlignment: ideaDetails.properties["Strategic Alignment"]?.select?.name,
  currentStatus: ideaDetails.properties.Status?.select?.name,
  additionalContext: contextFlag || "",
  ideaUrl: ideaDetails.url
};

console.log(`\n🔍 **Assessment Inputs:**`);
console.log(`   Idea: ${assessmentInputs.ideaName}`);
console.log(`   Champion: ${assessmentInputs.champion}`);
console.log(`   Estimated Cost: $${assessmentInputs.estimatedCost}/month`);
console.log(`   Category: ${assessmentInputs.category}`);
if (contextFlag) {
  console.log(`   Additional Context: ${contextFlag}`);
}
```

### Step 4: Invoke Viability Assessor Agent

```javascript
// Delegate to specialized agent
console.log(`\n⚙️ Engaging @viability-assessor agent...`);

const assessment = await Task({
  subagent_type: "viability-assessor",
  description: "Assess idea viability",
  prompt: `
Assess the viability of this innovation idea using the structured evaluation framework:

**Idea Details:**
- Name: ${assessmentInputs.ideaName}
- Description: ${assessmentInputs.description}
- Champion: ${assessmentInputs.champion}
- Estimated Monthly Cost: $${assessmentInputs.estimatedCost}
- Category: ${assessmentInputs.category}
- Strategic Alignment: ${assessmentInputs.strategicAlignment || 'Not specified'}
- Current Status: ${assessmentInputs.currentStatus}
${contextFlag ? `- Updated Context: ${contextFlag}` : ''}

**Required Assessment Dimensions:**
1. **Feasibility** (0-100): Technical viability, Microsoft ecosystem fit, resource availability
2. **Impact** (0-100): Business value, user benefit, strategic importance
3. **Effort** (0-100): Complexity, timeline, resource requirements (inverse score: low effort = high score)
4. **Team Capability** (0-100): Skills match, champion strength, capacity
5. **Strategic Fit** (0-100): Alignment with org goals, Microsoft priorities, innovation roadmap

**Output Requirements:**
- Overall Viability Score (0-100): Weighted average
- Recommendation: High Viability (75-100) | Moderately Viable (60-74) | Low Viability (40-59) | Not Viable (0-39)
- Next Steps: Build Example | Needs Research | Archive with Learnings
- Justification: 2-3 sentences explaining the score
- Risks & Concerns: Top 3 risk factors
- Success Factors: Top 3 enablers
  `
});

console.log(`✅ Assessment complete`);
```

### Step 5: Parse Assessment Results

```javascript
// Extract structured data from agent response
const viabilityData = {
  score: assessment.overallScore, // 0-100
  recommendation: assessment.recommendation,
  nextSteps: assessment.nextSteps,
  justification: assessment.justification,

  // Dimension scores
  feasibility: assessment.dimensions.feasibility,
  impact: assessment.dimensions.impact,
  effort: assessment.dimensions.effort,
  teamCapability: assessment.dimensions.teamCapability,
  strategicFit: assessment.dimensions.strategicFit,

  // Risk analysis
  risks: assessment.risks, // Array of top 3
  successFactors: assessment.successFactors, // Array of top 3

  // Metadata
  assessedDate: new Date().toISOString().split('T')[0],
  assessedBy: "viability-assessor agent"
};

// Map score to viability label
const viabilityMap = {
  high: { min: 75, label: "💎 Highly Viable", emoji: "💎" },
  medium: { min: 60, label: "⚡ Moderately Viable", emoji: "⚡" },
  low: { min: 40, label: "🔻 Low Viability", emoji: "🔻" },
  notViable: { min: 0, label: "❌ Not Viable", emoji: "❌" }
};

let viabilityLabel = "";
if (viabilityData.score >= 75) viabilityLabel = viabilityMap.high.label;
else if (viabilityData.score >= 60) viabilityLabel = viabilityMap.medium.label;
else if (viabilityData.score >= 40) viabilityLabel = viabilityMap.low.label;
else viabilityLabel = viabilityMap.notViable.label;
```

### Step 6: Update Idea in Notion

```javascript
// Update Ideas Registry with assessment results
const updateResult = await notionUpdatePage({
  page_id: selectedIdea.id,
  data: {
    command: "update_properties",
    properties: {
      "Viability": viabilityLabel,
      "Viability Score": viabilityData.score,
      "Last Assessed": viabilityData.assessedDate,

      // Dimension scores (if properties exist)
      "Feasibility Score": viabilityData.feasibility,
      "Impact Score": viabilityData.impact,
      "Effort Score": viabilityData.effort,
      "Team Capability Score": viabilityData.teamCapability,
      "Strategic Fit Score": viabilityData.strategicFit
    }
  }
});

// Optionally update status based on score
if (updateStatusFlag) {
  let newStatus = null;
  if (viabilityData.score >= 75) {
    newStatus = "🟢 Active"; // High viability → activate
  } else if (viabilityData.score < 40) {
    newStatus = "⚫ Not Active"; // Not viable → deactivate
  }
  // Medium viability (40-74) keeps current status

  if (newStatus) {
    await notionUpdatePage({
      page_id: selectedIdea.id,
      data: {
        command: "update_properties",
        properties: { "Status": newStatus }
      }
    });
    console.log(`   Status updated: ${newStatus}`);
  }
}

console.log(`\n✅ Idea updated with assessment results`);
console.log(`🔗 ${ideaDetails.url}`);
```

### Step 7: Present Assessment Summary

```javascript
console.log(`\n╔══════════════════════════════════════════════════════════════════╗`);
console.log(`║              VIABILITY ASSESSMENT RESULTS                        ║`);
console.log(`╚══════════════════════════════════════════════════════════════════╝\n`);

console.log(`**Idea**: ${assessmentInputs.ideaName}`);
console.log(`**Champion**: ${assessmentInputs.champion}\n`);

console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

console.log(`🎯 **Overall Viability**: ${viabilityLabel}`);
console.log(`📊 **Score**: ${viabilityData.score}/100\n`);

console.log(`**Dimension Breakdown:**`);
console.log(`  🔧 Feasibility:       ${viabilityData.feasibility}/100`);
console.log(`  💼 Impact:            ${viabilityData.impact}/100`);
console.log(`  ⚙️  Effort:            ${viabilityData.effort}/100 (inverse: lower effort = higher score)`);
console.log(`  👥 Team Capability:   ${viabilityData.teamCapability}/100`);
console.log(`  🎯 Strategic Fit:     ${viabilityData.strategicFit}/100\n`);

console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

console.log(`📋 **Recommendation**: ${viabilityData.recommendation}\n`);
console.log(`**Next Steps**: ${viabilityData.nextSteps}\n`);

console.log(`**Justification**:`);
console.log(`${viabilityData.justification}\n`);

console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

console.log(`⚠️  **Top Risks:**`);
viabilityData.risks.forEach((risk, idx) => {
  console.log(`   ${idx + 1}. ${risk}`);
});

console.log(`\n✅ **Success Factors:**`);
viabilityData.successFactors.forEach((factor, idx) => {
  console.log(`   ${idx + 1}. ${factor}`);
});

console.log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

// Actionable next steps based on score
if (viabilityData.score >= 75) {
  console.log(`💡 **Recommended Actions** (High Viability):`);
  console.log(`   1. Start Research: /innovation:start-research "${assessmentInputs.ideaName}"`);
  console.log(`   2. Or Fast-Track Build: /autonomous:enable-idea "${assessmentInputs.ideaName}"`);
  console.log(`   3. Assign Champion: Ensure ${assessmentInputs.champion} has capacity`);
} else if (viabilityData.score >= 60) {
  console.log(`💡 **Recommended Actions** (Moderately Viable):`);
  console.log(`   1. Conduct Research: /innovation:start-research "${assessmentInputs.ideaName}"`);
  console.log(`   2. Address Risks: Focus on top 3 concerns identified above`);
  console.log(`   3. Re-assess after research: /idea:assess "${assessmentInputs.ideaName}" --force`);
} else if (viabilityData.score >= 40) {
  console.log(`💡 **Recommended Actions** (Low Viability):`);
  console.log(`   1. Defer or Pivot: Consider alternative approaches`);
  console.log(`   2. Archive with Learnings: /knowledge:archive "${assessmentInputs.ideaName}" idea`);
  console.log(`   3. Or Re-scope: Reduce scope and re-assess`);
} else {
  console.log(`💡 **Recommended Actions** (Not Viable):`);
  console.log(`   1. Archive Immediately: /knowledge:archive "${assessmentInputs.ideaName}" idea`);
  console.log(`   2. Document Why: Capture learnings to prevent future similar proposals`);
  console.log(`   3. Communicate: Inform stakeholders of decision with clear rationale`);
}

console.log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);
console.log(`📅 **Assessed**: ${viabilityData.assessedDate}`);
console.log(`🔗 **View in Notion**: ${ideaDetails.url}`);
```

---

## Execution Examples

### Example 1: Assess High-Viability Idea

```bash
/idea:assess "Real-time collaboration using Azure SignalR"
```

**Expected Output:**

```
🔍 Searching for idea...
✅ Found: 💡 Real-time collaboration using Azure SignalR

🔍 **Assessment Inputs:**
   Idea: Real-time collaboration using Azure SignalR
   Champion: Alec Fielding
   Estimated Cost: $50/month
   Category: Development Tools

⚙️ Engaging @viability-assessor agent...
✅ Assessment complete

✅ Idea updated with assessment results
🔗 https://www.notion.so/abc123

╔══════════════════════════════════════════════════════════════════╗
║              VIABILITY ASSESSMENT RESULTS                        ║
╚══════════════════════════════════════════════════════════════════╝

**Idea**: Real-time collaboration using Azure SignalR
**Champion**: Alec Fielding

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 **Overall Viability**: 💎 Highly Viable
📊 **Score**: 87/100

**Dimension Breakdown:**
  🔧 Feasibility:       92/100
  💼 Impact:            85/100
  ⚙️  Effort:            78/100 (inverse: lower effort = higher score)
  👥 Team Capability:   90/100
  🎯 Strategic Fit:     88/100

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 **Recommendation**: Highly Viable - Proceed to Build

**Next Steps**: Build Example

**Justification**:
Azure SignalR provides production-ready real-time capabilities with strong Microsoft ecosystem integration. Team has demonstrated DevOps expertise, and estimated cost ($50/month) is well within budget. Strong strategic fit with organization's Azure-first approach and demonstrated user demand for collaborative features.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  **Top Risks:**
   1. WebSocket complexity may extend initial development timeline
   2. Scaling costs could increase with high concurrent connections
   3. Browser compatibility testing needed for legacy clients

✅ **Success Factors:**
   1. Azure SignalR is fully managed, reducing operational overhead
   2. Champion (Alec) has proven DevOps and integration expertise
   3. Clear Microsoft ecosystem alignment with existing Azure infrastructure

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 **Recommended Actions** (High Viability):
   1. Start Research: /innovation:start-research "Real-time collaboration using Azure SignalR"
   2. Or Fast-Track Build: /autonomous:enable-idea "Real-time collaboration using Azure SignalR"
   3. Assign Champion: Ensure Alec Fielding has capacity

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 **Assessed**: 2025-10-26
🔗 **View in Notion**: https://www.notion.so/abc123
```

---

### Example 2: Assess Moderately Viable Idea

```bash
/idea:assess "ML cost prediction dashboard" --context="Budget increased to $1000/month for AI initiatives"
```

**Expected Output:**

```
🔍 Searching for idea...
✅ Found: 💡 ML cost prediction dashboard

🔍 **Assessment Inputs:**
   Idea: ML cost prediction dashboard
   Champion: Markus Ahling
   Estimated Cost: $650/month
   Category: AI & Machine Learning
   Additional Context: Budget increased to $1000/month for AI initiatives

⚙️ Engaging @viability-assessor agent...
✅ Assessment complete

✅ Idea updated with assessment results
🔗 https://www.notion.so/def456

╔══════════════════════════════════════════════════════════════════╗
║              VIABILITY ASSESSMENT RESULTS                        ║
╚══════════════════════════════════════════════════════════════════╝

**Idea**: ML cost prediction dashboard
**Champion**: Markus Ahling

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 **Overall Viability**: ⚡ Moderately Viable
📊 **Score**: 72/100

**Dimension Breakdown:**
  🔧 Feasibility:       78/100
  💼 Impact:            82/100
  ⚙️  Effort:            58/100 (moderate complexity, significant data prep needed)
  👥 Team Capability:   75/100
  🎯 Strategic Fit:     70/100

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 **Recommendation**: Moderately Viable - Needs Research

**Next Steps**: Needs Research

**Justification**:
ML cost prediction shows strong business impact potential, and updated budget context ($1000/month) resolves previous cost concerns. However, significant effort required for data quality, feature engineering, and model training. Research phase recommended to validate data availability, define accuracy targets, and prototype MVP approach before full build commitment.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  **Top Risks:**
   1. Historical cost data quality may be insufficient for accurate predictions
   2. Model drift could require ongoing retraining and monitoring
   3. User adoption uncertain without clear integration into existing workflows

✅ **Success Factors:**
   1. Champion (Markus) has strong AI/ML and engineering expertise
   2. Budget increase enables Azure OpenAI + Azure ML resources
   3. Clear business need for proactive cost management

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 **Recommended Actions** (Moderately Viable):
   1. Conduct Research: /innovation:start-research "ML cost prediction dashboard"
   2. Address Risks: Focus on top 3 concerns identified above
   3. Re-assess after research: /idea:assess "ML cost prediction dashboard" --force

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 **Assessed**: 2025-10-26
🔗 **View in Notion**: https://www.notion.so/def456
```

---

### Example 3: Re-assess Idea with Force Flag

```bash
/idea:assess "Power BI governance automation" --force
```

**Expected Output:**

```
🔍 Searching for idea...
✅ Found: 💡 Power BI governance automation

⚠️ Idea assessed 3 days ago
   Current: ⚡ Moderately Viable (68/100)

💡 **Options:**
   A) Re-assess anyway: /idea:assess "Power BI governance automation" --force
   B) View current assessment: https://www.notion.so/ghi789
   C) Cancel and assess later

Re-assess now? (y/n) [--force flag detected, proceeding automatically]

🔍 **Assessment Inputs:**
   Idea: Power BI governance automation
   Champion: Brad Wright
   Estimated Cost: $200/month
   Category: Business Intelligence

⚙️ Engaging @viability-assessor agent...
✅ Assessment complete

[Assessment results displayed as in previous examples...]
```

---

### Example 4: Multiple Match Selection

```bash
/idea:assess "customer"
```

**Expected Output:**

```
🔍 Searching for idea...

⚠️ Multiple ideas match "customer":

1. 💡 Customer segmentation AI
   Status: 🟢 Active | Viability: 💎 Highly Viable
   Last Assessed: 2025-10-15
   https://www.notion.so/abc123

2. 💡 Customer feedback automation
   Status: 🔵 Concept | Viability: ❓ Needs Research
   Last Assessed: Never
   https://www.notion.so/def456

3. 💡 Customer onboarding Power App
   Status: ⚫ Not Active | Viability: 🔻 Low Viability
   Last Assessed: 2025-09-20
   https://www.notion.so/ghi789

Select idea number to assess: 2

✅ Found: 💡 Customer feedback automation

[Proceeding with assessment...]
```

---

## Error Handling

### Error 1: Idea Not Found

**Scenario**: User provides name that doesn't match any existing ideas

**Response:**
```
❌ No idea found matching: "Nonexistent Idea"

💡 **Suggestions:**
   - Search broader: /idea:search "Nonexistent"
   - Create new idea: /idea:create "Nonexistent Idea"

**Recent Ideas for Reference:**
1. Customer segmentation AI (Highly Viable)
2. Real-time collaboration using Azure SignalR (Moderately Viable)
3. ML cost prediction dashboard (Moderately Viable)

Run /idea:search for full list of ideas.
```

---

### Error 2: Assessment Too Recent

**Scenario**: Idea was assessed within last 7 days, no `--force` flag provided

**Response:**
```
⚠️ Idea assessed 3 days ago
   Current: ⚡ Moderately Viable (72/100)

💡 **Options:**
   A) Re-assess anyway: /idea:assess "ML cost prediction dashboard" --force
   B) View current assessment: https://www.notion.so/def456
   C) Cancel and assess later

Re-assess now? (y/n)
```

**Resolution**: User provides confirmation or uses `--force` flag

---

### Error 3: Viability Assessor Agent Unavailable

**Scenario**: @viability-assessor agent fails or times out

**Response:**
```
❌ Viability assessment failed: @viability-assessor agent timeout

**Possible Causes:**
- Network connectivity issues
- Agent service temporarily unavailable
- Excessive concurrent agent invocations

💡 **Resolution:**
1. Wait 2-3 minutes and retry: /idea:assess "idea-name"
2. Check agent availability: /agent:performance-report
3. Manual assessment: Review idea in Notion and set viability manually

**Temporary Workaround**:
Navigate to Notion and manually update viability based on these criteria:
- Feasibility: Can we build this with current capabilities?
- Impact: Does this solve a significant business problem?
- Effort: Is the effort justified by the impact?
- Team Capability: Do we have the right skills and capacity?
- Strategic Fit: Does this align with organizational priorities?
```

---

### Error 4: Missing Required Properties

**Scenario**: Ideas Registry is missing required properties for assessment

**Response:**
```
❌ Cannot complete assessment: Missing required database properties

**Missing Properties:**
- "Viability Score" (number property)
- "Feasibility Score" (number property)
- "Impact Score" (number property)
- "Last Assessed" (date property)

💡 **Resolution:**
Add missing properties to Ideas Registry database:
1. Open Ideas Registry: https://www.notion.so/984a4038...
2. Click "..." → "Customize database"
3. Add properties with exact names above
4. Retry assessment: /idea:assess "idea-name"

**Or contact workspace admin** to update database schema.

See .claude/docs/notion-schema.md for complete Ideas Registry schema.
```

---

## Success Criteria

After successful execution, verify:

- ✅ Idea located in Ideas Registry (with duplicate handling if needed)
- ✅ @viability-assessor agent invoked successfully
- ✅ Viability score calculated (0-100 numeric)
- ✅ Viability label updated (Highly Viable | Moderately Viable | Low Viability | Not Viable)
- ✅ Dimension scores captured (Feasibility, Impact, Effort, Team Capability, Strategic Fit)
- ✅ Last Assessed date updated to current date
- ✅ Risks and success factors documented
- ✅ Clear next steps provided based on viability score
- ✅ User receives actionable recommendations
- ✅ Assessment results visible in Notion

---

## Related Commands

**Before this command:**
- `/idea:search [criteria]` - Find ideas to assess
- `/idea:create [description]` - Create new idea if none exists

**After this command:**
- **High Viability (75-100)**:
  - `/innovation:start-research [idea-name]` - Validate via research
  - `/autonomous:enable-idea [idea-name]` - Fast-track to build

- **Moderately Viable (60-74)**:
  - `/innovation:start-research [idea-name]` - Required before build
  - `/idea:assess [idea-name] --force` - Re-assess after addressing concerns

- **Low/Not Viable (0-59)**:
  - `/knowledge:archive [idea-name] idea` - Preserve learnings
  - Update idea manually with pivot/rescope

**Related workflows:**
- `/innovation:project-plan [idea-name]` - Full lifecycle planning
- `/team:assign [idea-name] idea` - Route to appropriate champion

---

## Best Practices

### 1. Assess at Key Decision Points
Run assessments when:
- Idea transitions from Concept to Active
- Budget, team, or strategic context changes materially
- Quarterly portfolio reviews
- Before committing research or build resources

### 2. Use Additional Context Flag
Provide `--context` when circumstances have changed since last assessment:
```bash
/idea:assess "idea-name" --context="New Azure OpenAI capabilities now available"
```

### 3. Don't Over-Assess
Avoid redundant assessments within 7-day window unless material changes occurred. Use `--force` sparingly.

### 4. Act on Results Immediately
High-viability ideas should progress to research or build within 2 weeks. Don't let assessed ideas stagnate.

### 5. Document Rationale for Overrides
If you disagree with agent assessment, document reasoning in idea Description field and manually adjust viability.

### 6. Use Assessment for Portfolio Management
Run quarterly batch assessments to:
- Identify stale Concept ideas for archival
- Re-prioritize Active ideas based on updated scores
- Ensure resources allocated to highest-viability opportunities

---

## Notes for Claude Code

**When to use this command:**
- User asks to "assess viability of [idea]"
- User mentions "re-evaluate [idea]"
- User questions whether an idea is worth pursuing
- User requests "should we build [idea]?"
- During portfolio reviews or quarterly planning

**Execution approach:**
1. Search for idea with flexibility (partial matches, multiple results)
2. Check for recent assessment (prevent redundant work)
3. Gather complete context (fetch full idea details)
4. Invoke @viability-assessor agent with structured prompt
5. Parse and validate agent response
6. Update Notion with comprehensive results
7. Present clear, actionable recommendations

**Common mistakes to avoid:**
- Assessing without checking for recent assessment (wastes resources)
- Not handling multiple search matches gracefully
- Failing to provide context for assessment (leads to generic scores)
- Not translating scores into clear next steps
- Skipping dimension-level detail (users need to understand "why")

**Agent delegation:**
ALWAYS delegate assessment logic to @viability-assessor agent. This command is orchestration only—do not attempt to calculate viability scores directly.

**Performance expectations:**
- Search: ~2 seconds
- Agent assessment: 30-90 seconds (includes 5 dimensions + analysis)
- Update Notion: ~3 seconds
- Total: 40-100 seconds end-to-end

---

**Last Updated**: 2025-10-26
**Command Version**: 1.0.0
**Database**: Ideas Registry (984a4038-3e45-4a98-8df4-fd64dd8a1032)
