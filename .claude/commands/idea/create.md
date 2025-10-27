---
name: idea:create
description: Establish rapid innovation opportunity capture with streamlined entry creation and duplicate prevention
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-create-pages
argument-hint: [description] [--champion=person] [--estimated-cost=amount]
model: claude-sonnet-4-5-20250929
---

# /idea:create

**Category**: Innovation Management
**Related Databases**: Ideas Registry
**Agent Compatibility**: @ideas-capture (for full viability assessment use `/innovation:new-idea`)

## Purpose

Establish streamlined innovation opportunity capture with rapid entry creation, duplicate prevention, and foundational metadata. Drive efficient idea intake by enabling teams to quickly document concepts without the comprehensive viability assessment workflow, supporting agile innovation practices where speed of capture is prioritized over initial analysis depth.

**Best for**: Organizations requiring rapid idea intake workflows, innovation capture during brainstorming sessions, and lightweight concept documentation before formal viability assessment.

---

## Command Parameters

**Required:**
- `description` - Idea description (can be single sentence or detailed paragraph)

**Optional Flags:**
- `--champion=person` - Idea champion/owner (exact name match)
- `--estimated-cost=amount` - Estimated monthly cost in USD (number only)
- `--category=type` - Idea category (Innovation, Cost Optimization, Process Improvement, etc.)
- `--status=value` - Initial status (default: 🔵 Concept)
  - Values: `concept` | `active`
- `--tags=tag1,tag2` - Comma-separated tags for categorization

---

## Workflow

### Step 1: Search for Duplicate Ideas
```javascript
// CRITICAL: Always search before create to prevent duplicates
const existingIdeas = await notionSearch({
  query: description.substring(0, 100), // Use first 100 chars for semantic search
  data_source_url: "collection://984a4038-3e45-4a98-8df4-fd64dd8a1032"
});

if (existingIdeas.results.length > 0) {
  console.log(`⚠️ Similar ideas found:`);
  existingIdeas.results.forEach(idea => {
    const title = idea.properties["Idea Name"]?.title?.[0]?.plain_text;
    const status = idea.properties.Status?.select?.name;
    const viability = idea.properties.Viability?.select?.name;
    console.log(`  - ${title}`);
    console.log(`    Status: ${status}, Viability: ${viability}`);
    console.log(`    ${idea.url}`);
  });

  const proceed = await promptUser("\nCreate new idea anyway? (y/n)");
  if (!proceed) {
    console.log(`\n💡 Consider using existing idea or refining your description`);
    return;
  }
}
```

### Step 2: Extract Idea Title from Description
```javascript
// Generate concise title from description (first sentence or first 50 chars)
let ideaTitle = description;

// If description is long, extract first sentence
const firstSentence = description.match(/^[^.!?]+[.!?]/);
if (firstSentence) {
  ideaTitle = firstSentence[0].trim();
} else if (description.length > 50) {
  ideaTitle = description.substring(0, 50) + "...";
}

// Remove common prefixes if present
ideaTitle = ideaTitle.replace(/^(Idea:|We should|What if|How about)/i, '').trim();

console.log(`📝 Idea title: ${ideaTitle}`);
```

### Step 3: Determine Default Values
```javascript
// Status mapping
const statusMap = {
  'concept': '🔵 Concept',
  'active': '🟢 Active'
};

const finalStatus = statusMap[statusFlag || 'concept'];

// Initial viability (set to "Needs Research" by default for lightweight capture)
const initialViability = '❓ Needs Research';

// Category defaults
const defaultCategory = categoryFlag || 'Innovation';
```

### Step 4: Create Ideas Registry Entry
```javascript
const newIdea = await notionCreatePages({
  parent: { data_source_id: "984a4038-3e45-4a98-8df4-fd64dd8a1032" },
  pages: [{
    properties: {
      "Idea Name": `💡 ${ideaTitle}`,
      "Description": description,
      "Status": finalStatus,
      "Viability": initialViability,
      "Category": defaultCategory,
      "Estimated Monthly Cost": estimatedCostFlag || null,
      "Champion": championFlag ? await getUserId(championFlag) : null,
      "Tags": tagsFlag ? tagsFlag.split(',').map(t => t.trim()) : []
    }
  }]
});

console.log(`\n✅ Idea created successfully: ${ideaTitle}`);
console.log(`🔗 ${newIdea.url}`);
```

### Step 5: Display Confirmation and Next Steps
```javascript
console.log(`\n💡 **${ideaTitle}**`);
console.log(`   Description: ${description.substring(0, 100)}${description.length > 100 ? '...' : ''}`);
console.log(`   Status: ${finalStatus}`);
console.log(`   Viability: ${initialViability} (assessment recommended)`);

if (championFlag) {
  console.log(`   Champion: ${championFlag}`);
}

if (estimatedCostFlag) {
  console.log(`   Est. Cost: $${estimatedCostFlag}/month`);
}

console.log(`\n📌 **Next Steps:**`);
console.log(`1. Assess viability: /idea:assess "${ideaTitle}"`);
console.log(`2. Start research: /innovation:start-research [topic] "${ideaTitle}"`);
console.log(`3. Search related ideas: /idea:search "${ideaTitle}"`);
console.log(`4. Full capture with viability: /innovation:new-idea [description]`);
```

---

## Execution Examples

### Example 1: Quick Concept Capture During Meeting
```bash
/idea:create "Azure OpenAI integration for customer support automation to reduce response times"
```

**Expected Output:**
```
🔍 Checking for duplicate ideas...
✅ No similar ideas found

📝 Idea title: Azure OpenAI integration for customer support automation to reduce response times

✅ Idea created successfully

💡 **Azure OpenAI integration for customer support automation to reduce response times**
   Description: Azure OpenAI integration for customer support automation to reduce response times
   Status: 🔵 Concept
   Viability: ❓ Needs Research (assessment recommended)

🔗 https://notion.so/...

📌 **Next Steps:**
1. Assess viability: /idea:assess "Azure OpenAI integration for customer support automation"
2. Start research: /innovation:start-research "Azure OpenAI feasibility" "Azure OpenAI integration"
3. Search related ideas: /idea:search "Azure OpenAI"
4. Full capture with viability: /innovation:new-idea [description]
```

### Example 2: With Champion and Cost Estimate
```bash
/idea:create "Power BI embedded analytics for client portals" --champion="Brad Wright" --estimated-cost=500 --category="Business Intelligence"
```

**Expected Output:**
```
🔍 Checking for duplicate ideas...
✅ No similar ideas found

📝 Idea title: Power BI embedded analytics for client portals

✅ Idea created successfully

💡 **Power BI embedded analytics for client portals**
   Description: Power BI embedded analytics for client portals
   Status: 🔵 Concept
   Viability: ❓ Needs Research (assessment recommended)
   Champion: Brad Wright
   Est. Cost: $500/month
   Category: Business Intelligence

🔗 https://notion.so/...

📌 **Next Steps:**
1. Assess viability: /idea:assess "Power BI embedded analytics"
2. Start research: /innovation:start-research "Power BI embedding" "Power BI embedded analytics"
3. Link software: Ensure Power BI tracked in Software & Cost Tracker
```

### Example 3: Duplicate Detection
```bash
/idea:create "Real-time collaboration with SignalR"
```

**Expected Output:**
```
🔍 Checking for duplicate ideas...
⚠️ Similar ideas found:
  - 💡 Real-time Collaboration with Azure SignalR
    Status: 🔵 Concept, Viability: ❓ Needs Research
    https://notion.so/...

  - 💡 Azure SignalR Integration for Live Updates
    Status: 🟢 Active, Viability: 💎 High
    https://notion.so/...

Create new idea anyway? (y/n)

[User enters 'n']

💡 Consider using existing idea or refining your description
   Existing ideas cover similar concepts - review before creating duplicate
```

### Example 4: Active Status for Immediate Work
```bash
/idea:create "Standardize Git branching strategy across teams" --status=active --champion="Alec Fielding"
```

**Expected Output:**
```
🔍 Checking for duplicate ideas...
✅ No similar ideas found

📝 Idea title: Standardize Git branching strategy across teams

✅ Idea created successfully

💡 **Standardize Git branching strategy across teams**
   Description: Standardize Git branching strategy across teams
   Status: 🟢 Active (ready for immediate work)
   Viability: ❓ Needs Research (assessment recommended)
   Champion: Alec Fielding

🔗 https://notion.so/...

📌 **Next Steps:**
1. Document current branching practices (research phase)
2. Assess viability and effort: /idea:assess "Standardize Git branching"
3. Create implementation plan if viable
```

---

## Error Handling

### Error 1: Ideas Registry Not Accessible
**Scenario**: Notion MCP lacks access to Ideas Registry database
**Response**:
```
❌ Cannot access Ideas Registry database

💡 **Resolution:**
1. Verify Notion MCP has write access to Ideas Registry
2. Check data source ID: 984a4038-3e45-4a98-8df4-fd64dd8a1032
3. Ensure workspace permissions are correct
4. See .claude/docs/notion-schema.md lines 40-99 for schema

**Required Permissions**: Editor or Owner
```

### Error 2: Empty Description
**Scenario**: User provides empty or whitespace-only description
**Response**:
```
❌ Description cannot be empty

💡 **Requirements:**
- Provide meaningful idea description (at least 10 characters)
- Description should explain what, why, or how

**Examples:**
- Good: "Automate report generation with Power BI to save 10 hours/week"
- Good: "Azure Function cost tracker to monitor spending trends"
- Bad: "idea" (too vague)
- Bad: "stuff" (not descriptive)

Usage: /idea:create "Clear description of innovation concept"
```

### Error 3: Invalid Champion Name
**Scenario**: Champion name doesn't match any workspace users
**Response**:
```
⚠️ Champion "John Smith" not found in workspace

💡 **Options:**
A) Proceed without champion (idea remains unassigned)
B) Use different name (check spelling/capitalization)
C) Cancel operation

**Valid Champions:**
- Markus Ahling
- Brad Wright
- Stephan Densby
- Alec Fielding
- Mitch Bisbee

Which option? (A/B/C)
```

### Error 4: Invalid Status Value
**Scenario**: User provides status not in allowed list
**Response**:
```
❌ Invalid status value: "in-progress"

💡 **Valid Status Values:**
- concept (🔵 Concept) - Default for new ideas
- active (🟢 Active) - Ready for immediate work

**Usage:**
/idea:create "description" --status=concept
/idea:create "description" --status=active

Note: For full status workflow, use /innovation:new-idea instead
```

---

## Success Criteria

After successful execution, verify:

- ✅ Ideas Registry entry created with unique idea name
- ✅ Description captured in full
- ✅ Status set appropriately (default: Concept)
- ✅ Viability set to "Needs Research" (lightweight capture default)
- ✅ Champion linked if provided
- ✅ Estimated cost set if provided
- ✅ Category and tags applied if provided
- ✅ Idea name formatted with 💡 emoji prefix
- ✅ No duplicate entries created unintentionally
- ✅ User receives clear next steps (viability assessment)

**Follow-Up Required:**
Within 1 week, assess viability using `/idea:assess [idea-name]` or start research with `/innovation:start-research` to determine next steps (build vs archive).

---

## Related Commands

**Before this command:**
- `/idea:search [query]` - Check for duplicates before creating

**Alternative to this command:**
- `/innovation:new-idea [description]` - Full idea capture WITH viability assessment (uses @ideas-capture agent)

**After this command:**
- `/idea:assess [idea-name]` - Run viability assessment on captured idea
- `/innovation:start-research [topic] [idea-name]` - Begin feasibility investigation
- `/idea:search [query]` - Find related ideas for comparison

**Related workflows:**
- Quick capture: `/idea:create` → `/idea:assess` → Decision
- Full capture: `/innovation:new-idea` (includes viability assessment automatically)
- Research-first: `/idea:create` → `/innovation:start-research` → `/research:complete`

---

## Best Practices

### 1. Use for Rapid Capture, Not Deep Analysis
This command prioritizes speed over thoroughness. Use during brainstorming sessions, meetings, or when capturing fleeting ideas. For comprehensive capture with immediate viability assessment, use `/innovation:new-idea` instead.

### 2. Always Search Before Creating
Duplicate ideas fragment the innovation pipeline and create confusion. ALWAYS run `/idea:search` or use the built-in duplicate detection before creating new entries.

### 3. Follow Up Within 1 Week
Ideas without viability assessments languish. Set calendar reminder to run `/idea:assess` within 7 days of creation to determine if idea should progress to research, build, or archive.

### 4. Provide Context in Description
Don't just state "what" - explain "why" and "how":
- ❌ Bad: "Power BI thing"
- ✅ Good: "Power BI embedded analytics to provide client-facing dashboards, reducing custom report requests by 50%"

### 5. Assign Champions Immediately When Known
Ideas without owners have 3x higher abandonment rate. If you know who should own the idea, assign them during creation with `--champion=name`.

---

## Notes for Claude Code

**When to use this command:**
- User says "I have an idea..." during conversation
- Brainstorming session needs quick capture
- User wants lightweight entry without full viability workflow
- Speed prioritized over comprehensiveness

**When NOT to use (use `/innovation:new-idea` instead):**
- User wants viability assessment included
- Strategic idea requiring immediate analysis
- Quarterly planning with OKR linkage needed
- Formal innovation proposal submission

**Execution approach:**
1. ALWAYS search for duplicates first (avoid creating duplicates)
2. Extract concise title from description (first sentence or 50 chars)
3. Set viability to "Needs Research" by default (lightweight capture)
4. Prompt for champion if not provided (ownership critical)
5. Emphasize `/idea:assess` as critical next step

**Difference from `/innovation:new-idea`:**
- `/idea:create`: Fast, minimal metadata, no viability assessment
- `/innovation:new-idea`: Comprehensive, invokes @ideas-capture agent, includes viability scoring

**Common mistakes to avoid:**
- Creating without searching for duplicates first
- Accepting vague descriptions ("idea", "stuff", "thing")
- Not emphasizing viability assessment as next step
- Forgetting to suggest related commands
- Using when user clearly wants full viability workflow

---

**Last Updated**: 2025-10-26
**Command Version**: 1.0.0
**Automation Coverage Impact**: Enables rapid innovation intake for agile organizations
