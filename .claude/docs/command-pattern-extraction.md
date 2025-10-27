# Command Pattern Extraction - Existing Command Analysis
**Wave 1.4: Pattern Identification for Standardization**

**Purpose**: Extract reusable patterns from 18 existing command files to inform Wave 2 command implementation.

**Analysis Date**: 2025-10-26
**Scope**: All commands in `.claude/commands/` directory

---

## File Structure Patterns

### Pattern 1: Frontmatter YAML (Complex Commands)

**Used By**: `/innovation:project-plan`, `/autonomous:status`, `/innovation:orchestrate-complex`

```yaml
---
name: command:action
description: Single-sentence purpose statement
allowed-tools: Task(@agent-name:*), Tool(specific-tools)
argument-hint: [param1] [--flag=value]
model: claude-sonnet-4-5-20250929
---
```

**When to Use**:
- Commands that orchestrate multiple agents
- Commands requiring specific model capabilities
- Commands with complex parameter patterns
- Commands needing tool restrictions

### Pattern 2: No Frontmatter (Simple Commands)

**Used By**: `/cost:monthly-spend`, `/cost:unused-software`, `/cost:expiring-contracts`

**When to Use**:
- Simple query/analysis commands
- Commands with minimal parameters
- Commands that don't invoke agents
- Straightforward Notion MCP operations

**Recommendation**: Use Pattern 1 (frontmatter) for **all** Wave 2 commands to ensure consistency and enable future orchestration capabilities.

---

## Title & Header Patterns

### Standard Title Format

```markdown
# /category:action - Brief Description
```

**Examples**:
- `# /monthly-spend - Total Monthly Software Spend Analysis`
- `# /project-plan - Innovation Nexus Project Planning`
- `# /autonomous:status`

**Rules**:
- Category = database or domain (`cost`, `innovation`, `autonomous`, `idea`, `research`, `build`)
- Action = verb (`analyze`, `create`, `update`, `archive`, `status`)
- Description = outcome-focused (what it achieves, not how)

---

## Purpose Statement Patterns

### Pattern A: Outcome-Focused (Preferred)

```markdown
**Purpose**: [Verb] [object] to [outcome] through [approach].

**Best for**: Organizations [scaling/requiring/managing] [context] who need [specific benefit].
```

**Examples**:
- "Establish comprehensive project plans that streamline innovation workflows from concept through knowledge preservation, designed to drive measurable outcomes through structured approaches aligned with Microsoft ecosystem best practices."
- "Analyze total monthly software spending across all active subscriptions to establish transparent cost visibility and drive informed budget decisions."

**Brand Voice Elements**:
- "Establish" (not "create")
- "Drive measurable outcomes"
- "Designed to"
- "Organizations scaling/requiring"
- "Through structured approaches"

### Pattern B: Direct Description (Acceptable)

```markdown
**Purpose**: Provide [what] with [context].
```

**Example**:
- "Provide comprehensive visibility into autonomous innovation pipelines with real-time automation status, agent activity tracking, and decision queue monitoring."

**When to Use Pattern A vs B**:
- Pattern A: Commands creating/modifying data (create, update, archive)
- Pattern B: Commands querying/displaying data (status, analyze, search)

---

## Parameter Documentation Patterns

### Standard Parameter Section

```markdown
## Command Parameters

**Basic Syntax**:
\```bash
/command:action [required-param]
\```

**Advanced Syntax**:
\```bash
/command:action [required-param] --flag=[option] --another-flag=[value]
\```

### Parameters

**`parameter-name`** (required)
- Description of what this parameter does
- Options: `option1` | `option2` | `option3`
- Default: `default-value`
- Examples: "example-value", "another-example"

**`--flag-name`** (optional)
- Description of flag behavior
- Options: `value1` | `value2`
- Default: `default-value`
```

**Consistency Rules**:
- Required parameters: lowercase, no dashes
- Optional parameters: `--kebab-case`
- Always specify type: string, number, select, boolean
- Always provide examples (min 2)
- Document defaults explicitly

---

## Example Section Patterns

### Pattern A: Multiple Scenarios (Complex Commands)

```markdown
## Execution Examples

### Example 1: [Scenario Name]

\```bash
/command:action "value" --flag=option
\```

**Generated Plan**:
\```
[Multi-line formatted output showing what the command produces]
\```

**Expected Outcome**: [What happens in Notion/GitHub/Azure]
**Notion Updates**: [Which databases modified]
**Deliverables**: [What artifacts created]

### Example 2: [Different Scenario]
[Repeat pattern...]
```

**Used By**: `/innovation:project-plan`, `/innovation:orchestrate-complex`

### Pattern B: Output Format Template (Analysis Commands)

```markdown
## Output Format

\```
[ASCII art box or formatted output template]

**Metric Name**: $X,XXX
**Another Metric**: X items

### Category Breakdown
- Subcategory 1: $XXX (XX%)
- Subcategory 2: $XXX (XX%)

### Top Items List
1. **Item Name** - $XXX/month
   - Detail 1: Value
   - Detail 2: Value
\```
```

**Used By**: `/cost:monthly-spend`, `/autonomous:status`

**Rules for Examples**:
- Minimum 3 examples for complex commands
- Minimum 1 example + output template for analysis commands
- Use **real values** (not "your-value-here" placeholders)
- Show Notion URLs where applicable
- Include expected failures/error handling

---

## Brand Voice Language Patterns

### Core Patterns Extracted

**"Establish" Language** (appears in 12 of 18 commands):
- "Establish comprehensive project plans"
- "Establish transparent cost visibility"
- "Establish scalable data structure"
- ✅ **Use "Establish" instead of "Create/Build/Make"**

**"Drive Measurable Outcomes"** (appears in 8 of 18 commands):
- "Drive measurable outcomes through structured approaches"
- "Drive informed budget decisions"
- ✅ **Always connect actions to business outcomes**

**"Best for: Organizations..."** (appears in 14 of 18 commands):
- "Best for: Organizations requiring..."
- "Best for: Organizations scaling..."
- "Best for: Organizations managing..."
- ✅ **End every purpose statement with "Best for:" qualifier**

**"Designed to..."** (appears in 6 of 18 commands):
- "Designed to drive measurable outcomes"
- "Designed for organizations scaling"
- ✅ **Use when describing system-level capabilities**

**Microsoft Ecosystem Emphasis** (appears in 10 of 18 commands):
- "Microsoft ecosystem best practices"
- "Microsoft-first strategy"
- "Azure deployment"
- "M365 integration"
- ✅ **Reference Microsoft ecosystem where relevant**

### Anti-Patterns to Avoid

❌ **Avoid**:
- "This command will help you..." (too casual)
- "Simply run this to..." (diminishes complexity)
- "Just..." (minimizes effort)
- Technical jargon without context
- "Create/make/build" (use "Establish" instead)
- Timeline language ("Week 1", "by Friday", "Q1 2025")

---

## Integration Documentation Patterns

### Pattern A: Related Commands Section

```markdown
## Integration with Other Commands

**Pre-Execution**:
- `/command1` - Purpose
- `/command2` - Purpose

**During Execution**:
- `/command3` - When to use
- `/command4` - Complementary operation

**Post-Execution**:
- `/command5` - Next logical step
- `/command6` - Validation/verification
```

### Pattern B: Workflow Sequences

```markdown
**Common Workflow**:
1. `/command1` - Initial setup
2. `/command2` - Core operation
3. `/command3` - Verification
4. `/command4` - Archival/cleanup
```

**When to Use**:
- Pattern A: Commands that fit into larger workflows
- Pattern B: Commands that require specific execution order

---

## Notes for Claude Code Section

### Standard Template

```markdown
## Notes for Claude Code

**When to Use This Command**:
- ✓ Keyword trigger patterns
- ✓ Specific scenarios
- ✓ User intent indicators

**When NOT to Use**:
- ✗ Alternative scenarios
- ✗ Edge cases where different command better

**Command Execution Approach**:
1. Step 1: Parse and validate parameters
2. Step 2: Query Notion databases
3. Step 3: Perform calculations/analysis
4. Step 4: Invoke agents if needed
5. Step 5: Format and display output
6. Step 6: Update Notion entries
7. Step 7: Suggest next actions

**Output Format**: Always include:
- [Required output elements]
```

**Found in**: 11 of 18 commands (consistent pattern)

---

## Output Format Patterns

### Pattern A: ASCII Box Dashboard

```markdown
╔══════════════════════════════════════════════════════════════════════════╗
║                          DASHBOARD TITLE                                 ║
╚══════════════════════════════════════════════════════════════════════════╝

📊 SECTION NAME
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Metric: Value
  Another: Value
```

**Used By**: `/autonomous:status`
**When to Use**: Status dashboards, monitoring displays, real-time data

### Pattern B: Markdown Hierarchy

```markdown
**Total Monthly Spend**: $X,XXX
**Annual Projection**: $XX,XXX

---

### Spending by Category
- Development: $X,XXX/month (XX%)
- Infrastructure: $X,XXX/month (XX%)

### Top 5 Most Expensive Tools
1. **Tool Name** - $XXX/month
   - Licenses: X seats
   - Category: Category name
```

**Used By**: `/cost:monthly-spend`, `/cost:annual-projection`
**When to Use**: Analysis outputs, reports, summaries

### Pattern C: Structured Documents

```markdown
# Project Charter: [Name]

**Champion**: [Person]
**Status**: [Status]

---

## Executive Summary
[Content]

## Section 2
[Content]
```

**Used By**: `/innovation:project-plan`
**When to Use**: Deliverable documents, charters, specifications

---

## Error Handling Patterns

### Common Error Scenarios (Extracted from 18 commands)

**1. Missing Required Parameter**:
```markdown
Error: Required parameter [name] not provided
Usage: /command:action [param] --flag=value
```

**2. Invalid Parameter Value**:
```markdown
Error: Invalid value for --flag
Valid options: option1 | option2 | option3
```

**3. Notion Database Not Found**:
```markdown
Error: Could not find [Database Name]
Verify database ID or use notion-search to locate
```

**4. No Results Found**:
```markdown
No active software subscriptions found
Run /cost:add-software to register tools
```

**5. Calculation Error**:
```markdown
Warning: Cost rollup incomplete - verify relations
Missing software links in [X] builds
```

---

## Calculation & Logic Patterns

### Cost Analysis Pattern (Universal)

```javascript
// Used in: /cost:monthly-spend, /cost:annual-projection, /cost:build-costs

1. Query Software Tracker database
2. Filter WHERE Status = "Active"
3. Calculate: SUM(Total Monthly Cost) for relevant entries
4. Group by:
   - Category
   - Microsoft Service (Azure, M365, Power Platform, GitHub, None)
   - Criticality
5. Calculate percentages for each grouping
6. Sort by cost descending
7. Format with currency symbols and percentages
```

### Viability Assessment Pattern

```javascript
// Used in: /innovation:project-plan, research commands

1. Invoke @viability-assessor agent
2. Evaluate:
   - Effort vs. Impact (0-100)
   - Business value (0-100)
   - Technical feasibility (0-100)
   - Risk level (0-100, inverse)
3. Calculate aggregate score: Average(all metrics)
4. Classify:
   - HIGH: 75-100 (auto-approve for build)
   - MEDIUM: 50-74 (requires review)
   - LOW: 0-49 (archive with learnings)
5. Provide go/no-go recommendation
```

### Database Relation Pattern

```javascript
// Used in: All commands that create Notion entries

1. Search for existing duplicates
2. Fetch originating idea/research/build
3. Search Software Tracker for tools mentioned
4. Create entry with properties object
5. Link relations:
   - Origin Idea (required if research/build)
   - Related Research (if applicable)
   - Software & Tools (all tools used)
6. Verify rollup formulas calculate
```

---

## Agent Orchestration Patterns

### Pattern A: Single Agent Delegation

```markdown
**Delegate to**: `@agent-name`
**Task**: Specific operation
**Input**: Parameters and context
**Output**: Expected deliverable
```

**Example**:
```markdown
Delegate to: @cost-analyst
Task: Analyze monthly software spending
Input: Software Tracker database
Output: Spending breakdown by category
```

### Pattern B: Multi-Agent Parallel Execution

```markdown
**Wave 1** (Parallel):
- @agent-1: Task A
- @agent-2: Task B
- @agent-3: Task C

**Wave 2** (Depends on Wave 1):
- @agent-4: Task D (uses output from agent-1)
- @agent-5: Task E (uses output from agent-2)

**Wave 3** (Integration):
- Primary orchestrator: Combine results
```

**Used By**: `/innovation:orchestrate-complex`, `/innovation:project-plan`

---

## Notion MCP Operation Patterns

### Create Entry Pattern

```typescript
// Standard create pattern across all commands

await notionCreatePages({
  parent: {
    data_source_id: "[database-data-source-id]"
  },
  pages: [{
    properties: {
      "Title Property": "Value",
      "Status": "Select value",
      "Relation Property": [{ id: "related-page-id" }],
      "Number Property": 123,
      "Date Property Start": "2025-10-26",
      "Date Property is_datetime": 0
    }
  }]
});
```

### Search Before Create Pattern

```typescript
// Always search for duplicates first

// Step 1: Search
const existing = await notionSearch({
  query: "search term",
  data_source_url: "collection://[data-source-id]"
});

// Step 2: Check results
if (existing.results.length > 0) {
  // Duplicate found - inform user
  return "Duplicate exists: [URL]";
}

// Step 3: Create if no duplicates
await notionCreatePages({...});
```

### Fetch for Context Pattern

```typescript
// Fetch related items before creating/updating

// Fetch origin idea
const ideaData = await notionFetch({
  id: "idea-page-id"
});

// Extract champion, cost, context
const champion = ideaData.properties.Champion;
const software = ideaData.properties["Software Needed"];

// Use context in new entry
await notionCreatePages({
  properties: {
    "Origin Idea": [{ id: ideaData.id }],
    "Champion": champion,  // Inherit from idea
    ...
  }
});
```

---

## Success Criteria Patterns

### Standard Checklist Format

```markdown
## Success Criteria

**Automation Coverage**:
- ✅ Criterion 1 with specific metric
- ✅ Criterion 2 with verifiable outcome
- ✅ Criterion 3 with threshold

**Data Quality**:
- ✅ Quality criterion with measurement
- ✅ Integrity criterion with validation method

**System Performance**:
- ✅ Performance metric with target (<5 sec, >95%, etc.)

**Documentation**:
- ✅ Documentation requirement with completeness check
```

**Found in**: 9 of 18 commands
**Recommendation**: Include in all Wave 2 commands

---

## Key Findings Summary

### Universal Patterns (Apply to ALL Commands)

1. ✅ **Use frontmatter YAML** for consistency and future orchestration
2. ✅ **Lead with outcomes** in purpose statements
3. ✅ **Include "Best for:" qualifier** targeting organizations
4. ✅ **Document 3+ examples** with real values
5. ✅ **Search before create** (duplicate prevention)
6. ✅ **Include success criteria** with measurable outcomes
7. ✅ **Reference related commands** (pre/during/post workflow)
8. ✅ **Add "Notes for Claude Code"** section for implementation guidance

### Category-Specific Patterns

**Cost Commands**:
- Always group by Category, Microsoft Service, Criticality
- Calculate percentages for visibility
- Show top N items (usually top 5)
- Format currency: `$X,XXX/month ($XX,XXX/year)`

**Innovation Commands**:
- Always link to Ideas Registry (origin)
- Delegate to specialized agents (@viability-assessor, @build-architect, etc.)
- Include Microsoft ecosystem alignment check
- Provide viability classification (HIGH/MEDIUM/LOW)

**Status/Monitoring Commands**:
- Use ASCII box dashboards for visual impact
- Include real-time metrics with timestamps
- Show pending human decisions prominently
- Suggest quick actions for common next steps

---

## Recommendations for Wave 2

### Mandatory Elements (All 34+ Commands)

1. **Frontmatter YAML** with description, argument-hint
2. **Purpose statement** with outcome + "Best for:" qualifier
3. **Parameters section** with required/optional clearly marked
4. **Minimum 3 examples** with actual values (no placeholders)
5. **Integration with other commands** section
6. **Notes for Claude Code** implementation guidance
7. **Success criteria** checklist

### Optional Elements (Use When Applicable)

8. **Agent orchestration** (if command delegates)
9. **Notion MCP operations** (if creating/updating databases)
10. **Error handling scenarios** (if validation-heavy)
11. **Output format template** (if analysis/reporting command)

### Brand Voice Enforcement

- **Replace**: "create" → "establish"
- **Add**: "drive measurable outcomes through..."
- **Include**: Microsoft ecosystem references
- **Emphasize**: Organizations scaling, requiring, managing
- **Target**: Professional but approachable tone

---

**Next Steps**: Use this pattern extraction to inform Wave 2 command implementation. All new commands should follow these proven patterns for consistency and quality.

**Pattern Compliance Target**: 100% of Wave 2 commands follow extracted patterns.

**Last Updated**: 2025-10-26 (Wave 1.4)
