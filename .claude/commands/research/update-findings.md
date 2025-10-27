---
name: research:update-findings
description: Establish incremental research documentation to capture intermediate findings and maintain momentum during active investigations
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-fetch, mcp__notion__notion-update-page
argument-hint: [research-topic] [--finding="text"] [--append] [--progress=percentage]
model: claude-sonnet-4-5-20250929
---

# /research:update-findings

**Category**: Research Management
**Related Databases**: Research Hub
**Agent Compatibility**: @research-coordinator

## Purpose

Establish structured incremental documentation for active research investigations by capturing intermediate findings, progress updates, and evolving insights. Drive measurable outcomes by maintaining research momentum, enabling team visibility, and preserving context that informs final recommendations—designed for organizations requiring transparent research workflows across distributed teams.

**Best for**: Multi-week research investigations where interim findings guide next steps, stakeholder communication requires progress visibility, or team members need to collaborate asynchronously on research threads.

---

## Command Parameters

**Required:**
- `research-topic` - Name or partial match of active research in Research Hub

**Optional Flags:**
- `--finding="text"` - Specific finding to document (single observation or insight)
- `--append` - Add to existing findings (default: replace)
- `--progress=N` - Update progress percentage (0-100)
- `--status=value` - Update research status (Active | Paused | Blocked)
- `--next-steps="text"` - Document immediate next actions
- `--blocker="text"` - Flag blocking issue requiring attention

---

## Workflow

### Step 1: Search and Validate Research Exists

```javascript
// CRITICAL: Verify research entry exists and is active
const researchResults = await notionSearch({
  query: researchTopic,
  data_source_url: "collection://91e8beff-af94-4614-90b9-3a6d3d788d4a"
});

if (researchResults.results.length === 0) {
  console.error(`❌ No research found matching: "${researchTopic}"`);
  console.log(`\n💡 **Suggestions:**`);
  console.log(`   - Search: /research:search "${researchTopic}"`);
  console.log(`   - Start new: /innovation:start-research "${researchTopic}"`);
  return;
}

// Handle multiple matches
if (researchResults.results.length > 1) {
  console.log(`⚠️ Multiple research threads match "${researchTopic}":\n`);
  researchResults.results.forEach((research, idx) => {
    const title = research.properties["Research Topic"]?.title?.[0]?.plain_text;
    const status = research.properties.Status?.select?.name;
    const progress = research.properties.Progress?.number || 0;
    const lastUpdated = research.properties["Last Updated"]?.last_edited_time;

    console.log(`${idx + 1}. ${title}`);
    console.log(`   Status: ${status} | Progress: ${progress}%`);
    console.log(`   Last Updated: ${new Date(lastUpdated).toLocaleDateString()}`);
    console.log(`   ${research.url}\n`);
  });

  const selection = await promptUser("Select research number to update:");
  selectedResearch = researchResults.results[parseInt(selection) - 1];
} else {
  selectedResearch = researchResults.results[0];
}

const researchTitle = selectedResearch.properties["Research Topic"]?.title?.[0]?.plain_text;
console.log(`\n✅ Found: ${researchTitle}`);
```

### Step 2: Fetch Current Research State

```javascript
// Get complete context to inform update
const researchDetails = await notionFetch({
  id: selectedResearch.id
});

// Extract current state
const currentState = {
  topic: researchDetails.properties["Research Topic"]?.title?.[0]?.plain_text,
  status: researchDetails.properties.Status?.select?.name || "Active",
  progress: researchDetails.properties.Progress?.number || 0,
  methodology: researchDetails.properties.Methodology?.select?.name,
  currentFindings: researchDetails.properties.Findings?.rich_text?.[0]?.plain_text || "",
  nextSteps: researchDetails.properties["Next Steps"]?.rich_text?.[0]?.plain_text || "",
  hypothesis: researchDetails.properties.Hypothesis?.rich_text?.[0]?.plain_text || "",
  viabilityScore: researchDetails.properties["Viability Score"]?.number,
  researchType: researchDetails.properties["Research Type"]?.select?.name,
  lastUpdated: researchDetails.properties["Last Updated"]?.last_edited_time,
  url: researchDetails.url
};

console.log(`\n📊 **Current Research State:**`);
console.log(`   Status: ${currentState.status}`);
console.log(`   Progress: ${currentState.progress}%`);
console.log(`   Methodology: ${currentState.methodology}`);
console.log(`   Last Updated: ${new Date(currentState.lastUpdated).toLocaleDateString()}\n`);

// Warn if research not active
if (currentState.status !== "🟢 Active") {
  console.log(`⚠️ Research status is "${currentState.status}" (not Active)`);
  console.log(`   Updates typically target active research.`);
  const proceed = await promptUser("Continue update anyway? (y/n)");
  if (!proceed) return;
}
```

### Step 3: Prepare Findings Update

```javascript
// Determine update mode: append vs replace
let updatedFindings = "";

if (findingFlag) {
  // User provided specific finding via --finding flag
  if (appendFlag) {
    // Append to existing findings
    const timestamp = new Date().toLocaleDateString();
    const findingEntry = `\n\n**Update (${timestamp}):**\n${findingFlag}`;
    updatedFindings = currentState.currentFindings + findingEntry;

    console.log(`✅ Appending finding to existing research notes`);
  } else {
    // Replace existing findings
    updatedFindings = findingFlag;

    console.log(`⚠️ Replacing existing findings (use --append to preserve previous notes)`);
    const confirm = await promptUser("Replace all findings? (y/n)");
    if (!confirm) {
      console.log(`   Switching to append mode...`);
      const timestamp = new Date().toLocaleDateString();
      updatedFindings = currentState.currentFindings + `\n\n**Update (${timestamp}):**\n${findingFlag}`;
    }
  }
} else {
  // No --finding flag: prompt user for findings
  console.log(`\n📝 **Enter Research Findings** (current length: ${currentState.currentFindings.length} chars):`);
  console.log(`   Options: Type new findings, or press Enter to skip\n`);

  const userInput = await promptUser("Findings:");

  if (userInput && userInput.trim()) {
    if (appendFlag) {
      const timestamp = new Date().toLocaleDateString();
      updatedFindings = currentState.currentFindings + `\n\n**Update (${timestamp}):**\n${userInput}`;
    } else {
      updatedFindings = userInput;
    }
  } else {
    // User skipped findings, keep existing
    updatedFindings = currentState.currentFindings;
    console.log(`   Keeping existing findings unchanged`);
  }
}
```

### Step 4: Validate Progress Update

```javascript
// Calculate or validate progress
let updatedProgress = currentState.progress;

if (progressFlag !== undefined) {
  // User provided --progress flag
  const progressValue = parseInt(progressFlag);

  if (isNaN(progressValue) || progressValue < 0 || progressValue > 100) {
    console.error(`❌ Invalid progress value: "${progressFlag}"`);
    console.log(`   Progress must be 0-100`);
    return;
  }

  // Validate progress doesn't decrease (warn only, allow override)
  if (progressValue < currentState.progress) {
    console.log(`⚠️ Progress decreased: ${currentState.progress}% → ${progressValue}%`);
    const confirm = await promptUser("This is unusual. Continue? (y/n)");
    if (!confirm) return;
  }

  updatedProgress = progressValue;
  console.log(`   Progress updated: ${currentState.progress}% → ${updatedProgress}%`);
} else if (findingFlag || updatedFindings !== currentState.currentFindings) {
  // Findings changed but no explicit progress: suggest increment
  const suggestedProgress = Math.min(100, currentState.progress + 10);

  if (suggestedProgress > currentState.progress) {
    console.log(`\n💡 Findings updated. Suggest progress: ${currentState.progress}% → ${suggestedProgress}%`);
    const autoIncrement = await promptUser("Auto-increment progress? (y/n)");

    if (autoIncrement) {
      updatedProgress = suggestedProgress;
    }
  }
}
```

### Step 5: Handle Blockers and Status Changes

```javascript
// Process blocker flag
let blockerUpdate = null;

if (blockerFlag) {
  blockerUpdate = {
    status: "🔴 Blocked",
    blockerDescription: blockerFlag,
    blockedDate: new Date().toISOString().split('T')[0]
  };

  console.log(`\n⚠️ **BLOCKER FLAGGED**:`);
  console.log(`   ${blockerFlag}`);
  console.log(`   Status will change to: 🔴 Blocked`);
  console.log(`\n💡 **Next Steps:**`);
  console.log(`   1. Document blocker in research notes`);
  console.log(`   2. Assign owner to resolve blocker`);
  console.log(`   3. Resume when cleared: /research:update-findings "${currentState.topic}" --status=Active`);
}

// Process status override
let updatedStatus = currentState.status;

if (statusFlag) {
  const validStatuses = ["Active", "Paused", "Blocked", "Completed"];
  const statusInput = statusFlag.charAt(0).toUpperCase() + statusFlag.slice(1).toLowerCase();

  if (!validStatuses.includes(statusInput)) {
    console.error(`❌ Invalid status: "${statusFlag}"`);
    console.log(`   Valid values: Active | Paused | Blocked | Completed`);
    return;
  }

  const statusMap = {
    'Active': '🟢 Active',
    'Paused': '🟡 Paused',
    'Blocked': '🔴 Blocked',
    'Completed': '✅ Completed'
  };

  updatedStatus = statusMap[statusInput];
  console.log(`   Status updated: ${currentState.status} → ${updatedStatus}`);
} else if (blockerUpdate) {
  // Blocker flag overrides status
  updatedStatus = blockerUpdate.status;
}
```

### Step 6: Update Research Entry in Notion

```javascript
// Build update payload
const updatePayload = {
  page_id: selectedResearch.id,
  data: {
    command: "update_properties",
    properties: {}
  }
};

// Add findings if changed
if (updatedFindings !== currentState.currentFindings) {
  updatePayload.data.properties["Findings"] = updatedFindings;
}

// Add progress if changed
if (updatedProgress !== currentState.progress) {
  updatePayload.data.properties["Progress"] = updatedProgress;
}

// Add status if changed
if (updatedStatus !== currentState.status) {
  updatePayload.data.properties["Status"] = updatedStatus;
}

// Add next steps if provided
if (nextStepsFlag) {
  updatePayload.data.properties["Next Steps"] = nextStepsFlag;
}

// Add blocker details if flagged
if (blockerUpdate) {
  updatePayload.data.properties["Blocker Description"] = blockerUpdate.blockerDescription;
  updatePayload.data.properties["Blocked Date"] = blockerUpdate.blockedDate;
}

// Execute update
if (Object.keys(updatePayload.data.properties).length > 0) {
  await notionUpdatePage(updatePayload);

  console.log(`\n✅ Research updated successfully`);
  console.log(`🔗 ${currentState.url}`);
} else {
  console.log(`\n⚠️ No changes detected - nothing to update`);
  console.log(`💡 Provide --finding, --progress, or --status to make updates`);
  return;
}
```

### Step 7: Present Update Summary

```javascript
console.log(`\n╔══════════════════════════════════════════════════════════════════╗`);
console.log(`║              RESEARCH UPDATE SUMMARY                             ║`);
console.log(`╚══════════════════════════════════════════════════════════════════╝\n`);

console.log(`**Research**: ${currentState.topic}\n`);

console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

// Show changes
const changes = [];

if (updatedStatus !== currentState.status) {
  changes.push(`Status: ${currentState.status} → ${updatedStatus}`);
}

if (updatedProgress !== currentState.progress) {
  changes.push(`Progress: ${currentState.progress}% → ${updatedProgress}%`);
}

if (updatedFindings !== currentState.currentFindings) {
  const findingsChange = appendFlag ? "Appended" : "Updated";
  changes.push(`Findings: ${findingsChange} (${updatedFindings.length} chars)`);
}

if (nextStepsFlag) {
  changes.push(`Next Steps: Updated`);
}

if (blockerUpdate) {
  changes.push(`Blocker: Flagged`);
}

if (changes.length > 0) {
  console.log(`**Changes Applied:**`);
  changes.forEach(change => {
    console.log(`  ✅ ${change}`);
  });
} else {
  console.log(`⚠️ No changes applied`);
}

console.log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

// Display current findings (truncated)
if (updatedFindings) {
  const findingsPreview = updatedFindings.length > 300
    ? updatedFindings.substring(0, 300) + "..."
    : updatedFindings;

  console.log(`**Current Findings**:`);
  console.log(findingsPreview);
  console.log();
}

// Display blocker if present
if (blockerUpdate) {
  console.log(`⚠️ **BLOCKER**: ${blockerUpdate.blockerDescription}`);
  console.log(`   Flagged: ${blockerUpdate.blockedDate}\n`);
}

// Suggest next actions based on progress
console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

if (updatedProgress >= 90 && updatedStatus === "🟢 Active") {
  console.log(`💡 **Research Nearly Complete** (${updatedProgress}%):`);
  console.log(`   Next: /research:complete "${currentState.topic}"`);
  console.log(`   This will finalize findings and calculate viability score`);
} else if (updatedStatus === "🔴 Blocked") {
  console.log(`⚠️ **Research Blocked** - Action Required:`);
  console.log(`   1. Assign owner to resolve blocker`);
  console.log(`   2. Track resolution in research notes`);
  console.log(`   3. Resume: /research:update-findings "${currentState.topic}" --status=Active`);
} else if (updatedProgress < 50) {
  console.log(`📊 **Research In Progress** (${updatedProgress}%):`);
  console.log(`   Continue documenting findings as you discover them`);
  console.log(`   Update: /research:update-findings "${currentState.topic}" --finding="new insight"`);
} else {
  console.log(`📊 **Research Progressing** (${updatedProgress}%):`);
  console.log(`   Update: /research:update-findings "${currentState.topic}" --finding="text"`);
  console.log(`   Complete: /research:complete "${currentState.topic}"` (when ready)`);
}

console.log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);
console.log(`📅 **Updated**: ${new Date().toLocaleDateString()}`);
console.log(`🔗 **View in Notion**: ${currentState.url}`);
```

---

## Execution Examples

### Example 1: Append Incremental Finding

```bash
/research:update-findings "Azure OpenAI feasibility" \
  --finding="Tested GPT-4 with 500-token context: 95% accuracy on domain-specific queries" \
  --append \
  --progress=45
```

**Expected Output:**

```
🔍 Searching for research...
✅ Found: 🔬 Azure OpenAI feasibility

📊 **Current Research State:**
   Status: 🟢 Active
   Progress: 30%
   Methodology: Technical Spike
   Last Updated: 10/20/2025

✅ Appending finding to existing research notes
   Progress updated: 30% → 45%

✅ Research updated successfully
🔗 https://www.notion.so/abc123

╔══════════════════════════════════════════════════════════════════╗
║              RESEARCH UPDATE SUMMARY                             ║
╚══════════════════════════════════════════════════════════════════╝

**Research**: Azure OpenAI feasibility

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Changes Applied:**
  ✅ Progress: 30% → 45%
  ✅ Findings: Appended (687 chars)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Current Findings**:
[Previous findings from 10/15/2025...]

**Update (10/26/2025):**
Tested GPT-4 with 500-token context: 95% accuracy on domain-specific queries

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 **Research In Progress** (45%):
   Continue documenting findings as you discover them
   Update: /research:update-findings "Azure OpenAI feasibility" --finding="new insight"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 **Updated**: 10/26/2025
🔗 **View in Notion**: https://www.notion.so/abc123
```

---

### Example 2: Flag Blocker

```bash
/research:update-findings "Real-time collaboration SignalR" \
  --blocker="Azure subscription lacks SignalR quota - waiting on procurement approval" \
  --next-steps="Follow up with procurement team, estimate 3-5 business days"
```

**Expected Output:**

```
🔍 Searching for research...
✅ Found: 🔬 Real-time collaboration using Azure SignalR

📊 **Current Research State:**
   Status: 🟢 Active
   Progress: 60%
   Methodology: Proof of Concept
   Last Updated: 10/25/2025

⚠️ **BLOCKER FLAGGED**:
   Azure subscription lacks SignalR quota - waiting on procurement approval
   Status will change to: 🔴 Blocked

💡 **Next Steps:**
   1. Document blocker in research notes
   2. Assign owner to resolve blocker
   3. Resume when cleared: /research:update-findings "Real-time collaboration SignalR" --status=Active

✅ Research updated successfully
🔗 https://www.notion.so/def456

╔══════════════════════════════════════════════════════════════════╗
║              RESEARCH UPDATE SUMMARY                             ║
╚══════════════════════════════════════════════════════════════════╝

**Research**: Real-time collaboration using Azure SignalR

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Changes Applied:**
  ✅ Status: 🟢 Active → 🔴 Blocked
  ✅ Next Steps: Updated
  ✅ Blocker: Flagged

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ **BLOCKER**: Azure subscription lacks SignalR quota - waiting on procurement approval
   Flagged: 10/26/2025

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ **Research Blocked** - Action Required:
   1. Assign owner to resolve blocker
   2. Track resolution in research notes
   3. Resume: /research:update-findings "Real-time collaboration SignalR" --status=Active

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 **Updated**: 10/26/2025
🔗 **View in Notion**: https://www.notion.so/def456
```

---

### Example 3: Near-Completion Update

```bash
/research:update-findings "ML cost prediction" \
  --finding="Final accuracy: 87% on validation set. Ready for production recommendation." \
  --append \
  --progress=95
```

**Expected Output:**

```
🔍 Searching for research...
✅ Found: 🔬 ML cost prediction dashboard feasibility

📊 **Current Research State:**
   Status: 🟢 Active
   Progress: 80%
   Methodology: Autonomous Parallel Swarm
   Last Updated: 10/24/2025

✅ Appending finding to existing research notes
   Progress updated: 80% → 95%

✅ Research updated successfully
🔗 https://www.notion.so/ghi789

╔══════════════════════════════════════════════════════════════════╗
║              RESEARCH UPDATE SUMMARY                             ║
╚══════════════════════════════════════════════════════════════════╝

**Research**: ML cost prediction dashboard feasibility

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Changes Applied:**
  ✅ Progress: 80% → 95%
  ✅ Findings: Appended (1,240 chars)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Current Findings**:
[... previous research findings ...]

**Update (10/26/2025):**
Final accuracy: 87% on validation set. Ready for production recommendation.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 **Research Nearly Complete** (95%):
   Next: /research:complete "ML cost prediction"
   This will finalize findings and calculate viability score

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 **Updated**: 10/26/2025
🔗 **View in Notion**: https://www.notion.so/ghi789
```

---

## Error Handling

### Error 1: Research Not Found

**Scenario**: User provides name that doesn't match any research entries

**Response:**
```
❌ No research found matching: "Nonexistent Research"

💡 **Suggestions:**
   - Search: /research:search "Nonexistent"
   - Start new: /innovation:start-research "Nonexistent Research"

**Active Research for Reference:**
1. Azure OpenAI feasibility (45% complete)
2. Real-time collaboration SignalR (Blocked)
3. ML cost prediction (95% complete)
```

---

### Error 2: Invalid Progress Value

**Scenario**: User provides non-numeric or out-of-range progress

**Response:**
```
❌ Invalid progress value: "one hundred fifty"

   Progress must be 0-100

💡 **Examples:**
   /research:update-findings "topic" --progress=75
   /research:update-findings "topic" --progress=100
```

---

### Error 3: Completed Research Cannot Be Updated

**Scenario**: User attempts to update research with Status = ✅ Completed

**Response:**
```
⚠️ Research status is "✅ Completed" (not Active)
   Updates typically target active research.

Continue update anyway? (y/n) n

❌ Update cancelled

💡 **Options:**
   A) Reopen research: /research:update-findings "topic" --status=Active
   B) Start new related research: /innovation:start-research "topic v2"
   C) View archived findings: https://www.notion.so/abc123
```

---

### Error 4: No Changes Detected

**Scenario**: User runs command without providing any update flags

**Response:**
```
⚠️ No changes detected - nothing to update

💡 Provide --finding, --progress, or --status to make updates

**Usage Examples:**
   /research:update-findings "topic" --finding="new insight" --append
   /research:update-findings "topic" --progress=60
   /research:update-findings "topic" --status=Paused
   /research:update-findings "topic" --blocker="description"
```

---

## Success Criteria

After successful execution, verify:

- ✅ Research entry located in Research Hub
- ✅ At least one property updated (Findings, Progress, Status, Next Steps, or Blocker)
- ✅ Findings appended correctly if `--append` flag used
- ✅ Progress percentage within valid range (0-100) and logically consistent
- ✅ Status transition valid (Active, Paused, Blocked, Completed)
- ✅ Blocker details captured if `--blocker` flag used
- ✅ Last Updated timestamp refreshed automatically
- ✅ User receives clear summary of changes applied
- ✅ Actionable next steps provided based on current progress/status

---

## Related Commands

**Before this command:**
- `/innovation:start-research [topic]` - Initiate research investigation
- `/research:search [criteria]` - Find research to update

**After this command:**
- `/research:update-findings [topic]` - Continue adding findings (iterative)
- `/research:complete [topic]` - Finalize research with recommendations
- `/team:assign [topic] research` - Assign to researcher if blocked

**Related workflows:**
- `/autonomous:status` - View all active research progress
- `/knowledge:archive [topic] research` - Archive completed research

---

## Best Practices

### 1. Update Frequently with Small Findings
Prefer frequent small updates over infrequent large dumps:
```bash
# ✅ Good: Incremental daily updates
/research:update-findings "topic" --finding="Tested approach X: 85% success rate" --append

# ❌ Avoid: Waiting weeks to document everything at once
```

### 2. Always Use --append for Incremental Updates
Unless you're completely rewriting findings, preserve history:
```bash
/research:update-findings "topic" --finding="new insight" --append
```

### 3. Update Progress Realistically
Progress should reflect actual research completion, not time elapsed:
- 0-25%: Initial exploration, hypothesis formation
- 26-50%: Primary data collection, prototyping
- 51-75%: Analysis, validation, pattern identification
- 76-99%: Finalization, recommendation drafting
- 100%: Research complete (use `/research:complete` instead)

### 4. Flag Blockers Immediately
Don't let blocked research linger in Active status:
```bash
/research:update-findings "topic" --blocker="Waiting on API access" --status=Blocked
```

### 5. Document Next Steps
Maintain momentum by always knowing what comes next:
```bash
/research:update-findings "topic" \
  --finding="Phase 1 complete" \
  --next-steps="Phase 2: Load testing with 1000 concurrent users" \
  --append
```

---

## Notes for Claude Code

**When to use this command:**
- User says "update research findings for [topic]"
- User mentions documenting interim research results
- User needs to track research progress incrementally
- User wants to flag research blockers

**Execution approach:**
1. Search with flexibility (handle partial matches, multiple results)
2. Fetch current state to inform update (validate changes make sense)
3. Default to --append mode (preserve history unless explicitly replacing)
4. Auto-suggest progress increments when findings updated
5. Flag near-completion research (≥90%) for finalization

**Common mistakes to avoid:**
- Replacing findings when user intended to append (default to append)
- Allowing invalid progress values (validate 0-100 range)
- Not warning when progress decreases (unusual, ask for confirmation)
- Updating completed research without explicit user confirmation
- Ignoring blocker flags (these should change status to Blocked)

**Performance expectations:**
- Search: ~2 seconds
- Fetch: ~2 seconds
- Update: ~3 seconds
- Total: 7-10 seconds end-to-end

---

**Last Updated**: 2025-10-26
**Command Version**: 1.0.0
**Database**: Research Hub (91e8beff-af94-4614-90b9-3a6d3d788d4a)
