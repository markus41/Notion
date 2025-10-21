---
description: Begin structured feasibility investigation with hypothesis and methodology
allowed-tools: SlashCommand(@research-coordinator:*)
argument-hint: [research topic] [originating-idea-title]
model: claude-sonnet-4-5-20250929
---

## Context
Establish structured research approaches to assess innovation viability before committing to build efforts, ensuring sustainable decision-making.

## Workflow

Invoke @research-coordinator agent to structure research initiative:

1. **Search for existing research** on similar topics
   - Query: Extract key terms from "$1" (research topic)
   - Database: Research Hub
   - If duplicates: Present to user, offer to link instead of creating new

2. **Locate originating idea** if provided
   - Search: Ideas Registry for "$2" (idea title)
   - Verify: Idea exists and is in appropriate state (Viability = "Needs Research")
   - If not found: Ask user to provide Notion page URL

3. **Create Research Hub entry**
   - Topic: $1
   - Status: Active
   - Hypothesis: [Prompt user to provide clear hypothesis statement]
   - Methodology: [Prompt user to describe research approach]
   - Researchers: [Assign based on topic specialization]
   - Link to Origin Idea: [Relation to Ideas Registry entry]
   - Expected Completion: [Ask user for target timeframe, if any]

4. **Link software/tools** being used for research
   - Identify: Tools mentioned in methodology
   - Search: Software Tracker
   - Create relations: Link all identified tools
   - Display: "Research cost: $X/month from [N] tools"

5. **Set up documentation infrastructure**
   - SharePoint: Create or link to research document library
   - OneNote: Create or link to research notebook
   - Teams: Suggest creating channel for collaboration (optional)
   - Store links in Research Hub entry

6. **Update originating idea status**
   - If linked to idea: Update Idea status to "Active"
   - Add note: "Research initiated: [Research Hub entry link]"

7. **Provide research guidance**
   - Remind about key outputs:
     - Key Findings (to be documented)
     - Viability Assessment (Highly Viable | Moderately Viable | Not Viable | Inconclusive)
     - Next Steps (Build Example | More Research | Archive | Abandon)
   - Suggest: Regular check-ins, documentation in SharePoint/OneNote

8. **Report creation confirmation**
   - Format: "Research '[Topic]' initiated. Researchers: [Names]. Origin Idea: [Link]. Documentation: [SharePoint/OneNote links]. Estimated research cost: $X/month."

## Parameters

- `$1`: Research topic/title
- `$2`: (Optional) Originating idea title for automatic linking

## Examples

```
/innovation:start-research "Azure OpenAI integration patterns for Power BI" "AI-powered BI insights"
/innovation:start-research "Cost optimization strategies for Microsoft 365"
/innovation:start-research "Notion API automation capabilities"
```

## Related Commands

- `/innovation:new-idea` - Create idea that may need research
- `/innovation:create-build` - Create example build from research findings
- `/knowledge:document` - Archive research findings to Knowledge Vault

## Verification Steps

```
# Verify research entry created
/notion:search "$1"

# Check relation to idea
# View Research Hub entry → Verify "Origin Idea" relation exists

# Verify cost rollup
# View Research Hub entry → Verify "Estimated Cost" displays from software links
```
