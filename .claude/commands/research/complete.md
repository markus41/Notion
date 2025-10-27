---
name: research:complete
description: Establish research finalization workflow with comprehensive viability assessment to drive informed build/archive decisions based on investigation outcomes
allowed-tools: Task(@research-coordinator:*), mcp__notion__notion-search, mcp__notion__notion-fetch, mcp__notion__notion-update-page
argument-hint: [research-topic] [--recommendation=value] [--viability-score=N]
model: claude-sonnet-4-5-20250929
---

# /research:complete

**Category**: Research Management
**Related Databases**: Research Hub, Ideas Registry, Example Builds
**Agent Compatibility**: @research-coordinator

## Purpose

Establish comprehensive research completion workflow that finalizes investigation findings, calculates viability scores, and produces actionable recommendations to drive data-driven decisions about building, deferring, or archiving innovation opportunities—designed for organizations requiring transparent research outcomes that inform portfolio prioritization.

**Best for**: Organizations completing feasibility investigations where formal closure with viability assessment ensures research learnings translate into clear go/no-go decisions with stakeholder accountability.

---

## Command Parameters

**Required:**
- `research-topic` - Name or partial match of research in Research Hub

**Optional Flags:**
- `--recommendation=value` - Override recommendation (build | more-research | archive)
- `--viability-score=N` - Override viability score (0-100)
- `--viability=label` - Override viability label (high | medium | low | not-viable)
- `--update-origin-idea` - Auto-update linked origin idea with research results
- `--create-build` - Auto-create build entry if recommendation = build

---

## Workflow

### Step 1: Search and Validate Research

```javascript
// CRITICAL: Verify research exists and is ready to complete
const researchResults = await notionSearch({
  query: researchTopic,
  data_source_url: "collection://91e8beff-af94-4614-90b9-3a6d3d788d4a"
});

if (researchResults.results.length === 0) {
  console.error(`❌ No research found matching: "${researchTopic}"`);
  console.log(`\n💡 **Suggestions:**`);
  console.log(`   - Search: /research:search "${researchTopic}"`);
  console.log(`   - View all active: /autonomous:status`);
  return;
}

// Handle multiple matches
if (researchResults.results.length > 1) {
  console.log(`⚠️ Multiple research threads match "${researchTopic}":\n`);
  researchResults.results.forEach((research, idx) => {
    const title = research.properties["Research Topic"]?.title?.[0]?.plain_text;
    const status = research.properties.Status?.select?.name;
    const progress = research.properties.Progress?.number || 0;

    console.log(`${idx + 1}. ${title}`);
    console.log(`   Status: ${status} | Progress: ${progress}%`);
    console.log(`   ${research.url}\n`);
  });

  const selection = await promptUser("Select research number to complete:");
  selectedResearch = researchResults.results[parseInt(selection) - 1];
} else {
  selectedResearch = researchResults.results[0];
}

console.log(`\n✅ Found: ${selectedResearch.properties["Research Topic"]?.title?.[0]?.plain_text}`);
```

### Step 2: Fetch Complete Research Context

```javascript
// Get full research details to inform completion
const researchDetails = await notionFetch({
  id: selectedResearch.id
});

// Extract research context
const researchContext = {
  topic: researchDetails.properties["Research Topic"]?.title?.[0]?.plain_text,
  status: researchDetails.properties.Status?.select?.name,
  progress: researchDetails.properties.Progress?.number || 0,
  methodology: researchDetails.properties.Methodology?.select?.name,
  findings: researchDetails.properties.Findings?.rich_text?.[0]?.plain_text || "",
  hypothesis: researchDetails.properties.Hypothesis?.rich_text?.[0]?.plain_text || "",
  nextSteps: researchDetails.properties["Next Steps"]?.rich_text?.[0]?.plain_text || "",
  researchType: researchDetails.properties["Research Type"]?.select?.name,
  originIdea: researchDetails.properties["Origin Idea"]?.relation?.[0]?.id,
  startDate: researchDetails.properties["Start Date"]?.date?.start,
  completedDate: researchDetails.properties["Completed Date"]?.date?.start,
  viabilityScore: researchDetails.properties["Viability Score"]?.number,
  viability: researchDetails.properties.Viability?.select?.name,
  url: researchDetails.url
};

console.log(`\n📊 **Research Context:**`);
console.log(`   Status: ${researchContext.status}`);
console.log(`   Progress: ${researchContext.progress}%`);
console.log(`   Methodology: ${researchContext.methodology}`);
console.log(`   Findings Length: ${researchContext.findings.length} chars\n`);

// Validate readiness to complete
if (researchContext.status === "✅ Completed") {
  console.log(`⚠️ Research already marked as Completed`);
  const reprocess = await promptUser("Re-process completion anyway? (y/n)");
  if (!reprocess) return;
}

if (researchContext.progress < 80 && !viabilityScoreFlag) {
  console.log(`⚠️ Research progress is ${researchContext.progress}% (typically 80%+ before completion)`);
  console.log(`   Consider: /research:update-findings "${researchContext.topic}" --progress=X`);
  const proceedAnyway = await promptUser("Complete research anyway? (y/n)");
  if (!proceedAnyway) return;
}

if (!researchContext.findings || researchContext.findings.length < 100) {
  console.log(`⚠️ Findings are sparse (${researchContext.findings.length} chars)`);
  console.log(`   Recommendation quality may be reduced`);
  const continueWithSparse = await promptUser("Continue with sparse findings? (y/n)");
  if (!continueWithSparse) return;
}
```

### Step 3: Calculate Viability Score (if not provided)

```javascript
// Determine viability score via agent or manual override
let finalViabilityScore = viabilityScoreFlag || researchContext.viabilityScore;
let finalViabilityLabel = viabilityFlag;
let finalRecommendation = recommendationFlag;

if (!finalViabilityScore && !viabilityScoreFlag) {
  // No score provided: invoke research-coordinator agent for assessment
  console.log(`\n⚙️ Engaging @research-coordinator agent for viability assessment...`);

  const assessment = await Task({
    subagent_type: "research-coordinator",
    description: "Calculate research viability score",
    prompt: `
Analyze the following research investigation and calculate a comprehensive viability score (0-100):

**Research Topic**: ${researchContext.topic}
**Methodology**: ${researchContext.methodology}
**Hypothesis**: ${researchContext.hypothesis}

**Findings** (${researchContext.findings.length} chars):
${researchContext.findings}

**Research Type**: ${researchContext.researchType}
**Origin Idea**: ${researchContext.originIdea ? 'Linked' : 'None'}

**Assessment Criteria**:
1. **Technical Feasibility** (0-100): Can this be built with current capabilities?
2. **Business Impact** (0-100): Does this solve significant problems?
3. **Cost Viability** (0-100): Is the cost-benefit ratio favorable?
4. **Risk Assessment** (0-100): Are risks manageable? (inverse: low risk = high score)
5. **Strategic Alignment** (0-100): Does this fit organizational priorities?

**Output Requirements**:
- Overall Viability Score (0-100): Weighted average of criteria
- Viability Label: High (75-100) | Medium (60-74) | Low (40-59) | Not Viable (0-39)
- Recommendation: Build Example | More Research | Archive with Learnings
- Justification: 2-3 sentences explaining the score and recommendation
- Key Risks: Top 3 concerns
- Success Factors: Top 3 enablers
    `
  });

  finalViabilityScore = assessment.viabilityScore;
  finalViabilityLabel = assessment.viabilityLabel;
  finalRecommendation = assessment.recommendation;

  console.log(`✅ Viability assessment complete`);
  console.log(`   Score: ${finalViabilityScore}/100 (${finalViabilityLabel})`);
  console.log(`   Recommendation: ${finalRecommendation}\n`);
} else if (viabilityScoreFlag) {
  // Manual score provided: derive label and recommendation
  if (finalViabilityScore >= 75) {
    finalViabilityLabel = "high";
    finalRecommendation = finalRecommendation || "build";
  } else if (finalViabilityScore >= 60) {
    finalViabilityLabel = "medium";
    finalRecommendation = finalRecommendation || "more-research";
  } else if (finalViabilityScore >= 40) {
    finalViabilityLabel = "low";
    finalRecommendation = finalRecommendation || "archive";
  } else {
    finalViabilityLabel = "not-viable";
    finalRecommendation = "archive";
  }

  console.log(`📊 Manual viability score: ${finalViabilityScore}/100`);
  console.log(`   Derived label: ${finalViabilityLabel}`);
  console.log(`   Default recommendation: ${finalRecommendation}\n`);
}

// Map label to emoji format
const viabilityEmojiMap = {
  'high': '💎 Highly Viable',
  'medium': '⚡ Moderately Viable',
  'low': '🔻 Low Viability',
  'not-viable': '❌ Not Viable'
};

const finalViabilityEmoji = viabilityEmojiMap[finalViabilityLabel];
```

### Step 4: Update Research Hub Entry

```javascript
// Update research with completion data
const completionDate = new Date().toISOString().split('T')[0];

await notionUpdatePage({
  page_id: selectedResearch.id,
  data: {
    command: "update_properties",
    properties: {
      "Status": "✅ Completed",
      "Progress": 100,
      "Completed Date": completionDate,
      "Viability Score": finalViabilityScore,
      "Viability": finalViabilityEmoji,
      "Next Steps": `Recommendation: ${finalRecommendation}`
    }
  }
});

console.log(`✅ Research marked as Completed in Research Hub`);
console.log(`🔗 ${researchContext.url}\n`);
```

### Step 5: Update Origin Idea (if linked)

```javascript
// Optionally propagate results to origin idea
if (researchContext.originIdea && updateOriginIdeaFlag) {
  console.log(`🔗 Updating origin idea with research results...`);

  await notionUpdatePage({
    page_id: researchContext.originIdea,
    data: {
      command: "update_properties",
      properties: {
        "Viability": finalViabilityEmoji,
        "Viability Score": finalViabilityScore,
        "Status": finalRecommendation === "build" ? "🟢 Active" : "🔵 Concept"
      }
    }
  });

  console.log(`   ✅ Origin idea updated with viability results\n`);
} else if (researchContext.originIdea) {
  console.log(`💡 Origin idea linked but not updated (use --update-origin-idea to sync)\n`);
}
```

### Step 6: Present Completion Report

```javascript
const durationDays = researchContext.startDate
  ? Math.floor((new Date() - new Date(researchContext.startDate)) / (1000 * 60 * 60 * 24))
  : null;

console.log(`\n╔══════════════════════════════════════════════════════════════════╗`);
console.log(`║            RESEARCH COMPLETION REPORT                            ║`);
console.log(`╚══════════════════════════════════════════════════════════════════╝\n`);

console.log(`**Research**: ${researchContext.topic}\n`);

console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

console.log(`📊 **Viability Assessment**:`);
console.log(`   Score: ${finalViabilityScore}/100`);
console.log(`   Classification: ${finalViabilityEmoji}`);
console.log(`   Methodology: ${researchContext.methodology}`);
console.log(`   Research Type: ${researchContext.researchType}\n`);

console.log(`⏱️  **Timeline**:`);
if (durationDays) {
  console.log(`   Duration: ${durationDays} days`);
}
console.log(`   Started: ${researchContext.startDate || 'Unknown'}`);
console.log(`   Completed: ${completionDate}\n`);

console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

console.log(`📋 **Recommendation**: ${finalRecommendation}\n`);

// Display recommendation-specific next steps
if (finalRecommendation === "build") {
  console.log(`✅ **HIGH VIABILITY - Proceed to Build**\n`);
  console.log(`**Immediate Next Steps:**`);
  console.log(`   1. Create Build: /build:create "${researchContext.topic}"`);
  console.log(`   2. Or Fast-Track: /autonomous:enable-idea "${researchContext.topic}"`);
  console.log(`   3. Link Software: /build:link-software\n`);

} else if (finalRecommendation === "more-research") {
  console.log(`⚡ **MODERATE VIABILITY - Additional Research Needed**\n`);
  console.log(`**Next Steps:**`);
  console.log(`   1. Start Phase 2: /innovation:start-research "${researchContext.topic} - Phase 2"`);
  console.log(`   2. Or defer: /knowledge:archive "${researchContext.topic}" research\n`);

} else {
  console.log(`🔻 **LOW/NOT VIABLE - Archive with Learnings**\n`);
  console.log(`**Next Steps:**`);
  console.log(`   1. Archive: /knowledge:archive "${researchContext.topic}" research`);
  console.log(`   2. Document learnings to prevent future redundant investments\n`);
}

console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

console.log(`📅 **Completed**: ${completionDate}`);
console.log(`🔗 **View in Notion**: ${researchContext.url}`);
```

---

## Execution Examples

### Example 1: Complete High-Viability Research

```bash
/research:complete "Azure OpenAI feasibility" --update-origin-idea
```

**Expected Output:**

```
🔍 Searching for research...
✅ Found: 🔬 Azure OpenAI feasibility

📊 **Research Context:**
   Status: 🟢 Active
   Progress: 95%
   Methodology: Technical Spike
   Findings Length: 1,847 chars

⚙️ Engaging @research-coordinator agent for viability assessment...
✅ Viability assessment complete
   Score: 92/100 (high)
   Recommendation: build

✅ Research marked as Completed in Research Hub
🔗 https://www.notion.so/abc123

🔗 Updating origin idea with research results...
   ✅ Origin idea updated with viability results

╔══════════════════════════════════════════════════════════════════╗
║            RESEARCH COMPLETION REPORT                            ║
╚══════════════════════════════════════════════════════════════════╝

**Research**: Azure OpenAI feasibility

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 **Viability Assessment**:
   Score: 92/100
   Classification: 💎 Highly Viable
   Methodology: Technical Spike
   Research Type: Technical Feasibility

⏱️  **Timeline**:
   Duration: 12 days
   Started: 2025-10-14
   Completed: 2025-10-26

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 **Recommendation**: build

✅ **HIGH VIABILITY - Proceed to Build**

**Immediate Next Steps:**
   1. Create Build: /build:create "Azure OpenAI feasibility"
   2. Or Fast-Track: /autonomous:enable-idea "Azure OpenAI feasibility"
   3. Link Software: /build:link-software

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 **Completed**: 2025-10-26
🔗 **View in Notion**: https://www.notion.so/abc123
```

---

### Example 2: Complete with Manual Score Override

```bash
/research:complete "Customer feedback automation" --viability-score=68
```

**Expected Output:**

```
🔍 Searching for research...
✅ Found: 🔬 Customer feedback automation

📊 **Research Context:**
   Status: 🟢 Active
   Progress: 85%
   Methodology: Market Analysis
   Findings Length: 1,203 chars

📊 Manual viability score: 68/100
   Derived label: medium
   Default recommendation: more-research

✅ Research marked as Completed in Research Hub
🔗 https://www.notion.so/def456

╔══════════════════════════════════════════════════════════════════╗
║            RESEARCH COMPLETION REPORT                            ║
╚══════════════════════════════════════════════════════════════════╝

**Research**: Customer feedback automation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 **Viability Assessment**:
   Score: 68/100
   Classification: ⚡ Moderately Viable
   Methodology: Market Analysis
   Research Type: Market Validation

⏱️  **Timeline**:
   Duration: 8 days
   Started: 2025-10-18
   Completed: 2025-10-26

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 **Recommendation**: more-research

⚡ **MODERATE VIABILITY - Additional Research Needed**

**Next Steps:**
   1. Start Phase 2: /innovation:start-research "Customer feedback automation - Phase 2"
   2. Or defer: /knowledge:archive "Customer feedback automation" research

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 **Completed**: 2025-10-26
🔗 **View in Notion**: https://www.notion.so/def456
```

---

## Error Handling

### Error 1: Research Not Found

**Scenario**: User provides name that doesn't match any research

**Response:**
```
❌ No research found matching: "Nonexistent Research"

💡 **Suggestions:**
   - Search: /research:search "Nonexistent"
   - View all active: /autonomous:status
```

---

### Error 2: Research Progress Too Low

**Scenario**: Research progress <80% without manual viability override

**Response:**
```
⚠️ Research progress is 45% (typically 80%+ before completion)
   Consider: /research:update-findings "topic" --progress=X

Complete research anyway? (y/n)
```

---

### Error 3: Sparse Findings Warning

**Scenario**: Findings length <100 characters

**Response:**
```
⚠️ Findings are sparse (67 chars)
   Recommendation quality may be reduced

Continue with sparse findings? (y/n)
```

---

### Error 4: Agent Assessment Failure

**Scenario**: @research-coordinator agent fails during viability assessment

**Response:**
```
❌ Viability assessment failed: Agent timeout

**Temporary Workaround:**
Complete research with manual viability score:

   /research:complete "topic" --viability-score=75 --recommendation=build
```

---

## Success Criteria

After successful execution, verify:

- ✅ Research status updated to ✅ Completed
- ✅ Progress set to 100%
- ✅ Completed Date populated with current date
- ✅ Viability Score calculated or validated (0-100)
- ✅ Viability label assigned (Highly Viable | Moderately Viable | Low Viability | Not Viable)
- ✅ Clear recommendation provided (build | more-research | archive)
- ✅ Origin idea updated with viability (if flag provided)
- ✅ User receives comprehensive completion report with actionable next steps

---

## Related Commands

**Before this command:**
- `/innovation:start-research [topic]` - Initiate research
- `/research:update-findings [topic]` - Document interim findings

**After this command (based on recommendation):**
- **If build**: `/build:create [name] --related-research=[topic]`
- **If more-research**: `/innovation:start-research "[topic] - Phase 2"`
- **If archive**: `/knowledge:archive [topic] research`

**Related workflows:**
- `/autonomous:enable-idea [name]` - Fast-track high-viability idea
- `/team:assign [topic] research` - Route to champion for review

---

## Best Practices

### 1. Complete When Progress ≥80%
Ensure sufficient investigation depth before completing.

### 2. Always Update Origin Idea
Use `--update-origin-idea` to maintain innovation lineage integrity.

### 3. Preserve Learnings for Low-Viability Research
Archive with `/knowledge:archive` to prevent redundant future investigations.

### 4. Fast-Track High-Viability Builds
For scores ≥85, use `/autonomous:enable-idea` for full automation.

### 5. Document Phase 2 Research Clearly
When recommendation = more-research, explicitly define gaps in Next Steps.

---

## Notes for Claude Code

**When to use this command:**
- User says "finish research" or "complete research for [topic]"
- Research progress reaches 90-100%
- User asks "what's the research conclusion for [topic]"
- Autonomous research swarm completes

**Execution approach:**
1. Validate research readiness (progress, findings length)
2. Invoke @research-coordinator for viability assessment (if not manually provided)
3. Update Research Hub with completion data
4. Optionally propagate to origin idea
5. Present comprehensive report with clear next steps

**Common mistakes to avoid:**
- Completing research <80% progress without validation
- Not updating origin idea (breaks lineage tracking)
- Skipping knowledge preservation recommendation
- Providing generic next steps (tailor to viability score)

**Performance expectations:**
- Search: ~2 seconds
- Fetch: ~2 seconds
- Agent assessment: 30-60 seconds
- Update: ~5 seconds
- Total: 40-70 seconds end-to-end

---

**Last Updated**: 2025-10-26
**Command Version**: 1.0.0
**Database**: Research Hub (91e8beff-af94-4614-90b9-3a6d3d788d4a)
