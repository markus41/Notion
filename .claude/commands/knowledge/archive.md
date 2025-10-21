---
description: Complete work lifecycle with learnings documentation and knowledge preservation
allowed-tools: SlashCommand(@archive-manager:*), SlashCommand(@knowledge-curator:*)
argument-hint: [item-name] [database: idea|research|build]
model: claude-sonnet-4-5-20250929
---

## Context
Build sustainable practices by ensuring completed work transitions properly to archived state with documented learnings preserved for future reference.

## Workflow

Invoke @archive-manager and @knowledge-curator agents to complete lifecycle:

1. **Locate item to archive**
   - Item name: "$1"
   - Database: ${2:-build}  # Default to "build"
   - Options: idea | research | build
   - Search: Appropriate database for exact or fuzzy match
   - If multiple matches: Present to user for selection

2. **Verify learnings are documented**
   - Check required completion fields based on database:
     - **Ideas**: Final viability assessment recorded?
     - **Research**: Key findings and viability assessment completed?
     - **Builds**: Lessons learned captured? Post-mortem documented?
   - If missing: Prompt user to provide before archiving

3. **Assess Knowledge Vault worthiness**
   - Criteria for archiving to Knowledge Vault:
     - Reusable patterns or templates created
     - Novel problems solved with documented solutions
     - Failed experiments with valuable learnings
     - Process improvements that could benefit future work
   - Ask user: "Should we create Knowledge Vault entry for this?"

4. **Create Knowledge Vault entry** (if approved)
   - Invoke @knowledge-curator agent
   - Content Type: [Post-Mortem | Case Study | Technical Doc | Process | Template | Reference]
   - Evergreen/Dated: [Assess longevity of content]
   - Link to archived item: [Relation to original database entry]
   - Key Learnings: [Extract from item documentation]
   - Reusable Artifacts: [Link to GitHub repos, templates, documents]

5. **Update item status to archived**
   - Status: Archived (for Ideas/Knowledge) or Not Active (for Research/Builds)
   - Archive Date: [Today's date]
   - Add note: "Archived on [Date]. Learnings captured in Knowledge Vault: [Link]"

6. **Verify link preservation**
   - Check all external links still accessible:
     - GitHub repositories: URLs valid and repos not deleted
     - SharePoint/OneNote: Document locations recorded
     - Azure resources: DevOps boards, deployed services documented
     - Teams channels: Links preserved
   - Software/tool relations: Maintained for historical cost tracking

7. **Update dependent items**
   - Ideas with no active research/builds: Update status to "Not Active"
   - Research with completed builds: Update status to "Completed"
   - Notify: Users watching or assigned to item

8. **Generate archive report**

```
## Archive Summary: [$1]

**Archived**: [Date]
**Original Status**: [Previous status] → **New Status**: [Archived/Not Active]
**Database**: [Ideas Registry | Research Hub | Example Builds]

### Key Information Preserved
- Links: [GitHub | SharePoint | Teams | Azure DevOps]
- Cost Data: $X/month ([N] tools tracked)
- Team Members: [Names]
- Duration: [Start date] to [End date]

### Learnings Documented
[Yes/No - If yes, link to Knowledge Vault entry]

### Knowledge Vault Entry
**Title**: [Entry name if created]
**Type**: [Content type]
**Link**: [Notion page URL]
**Reusability**: [Assessment]

### Next Steps
- [Recommendations for similar future work]
- [Related active items to consider]
```

## Parameters

- `$1`: Item name/title to archive
- `$2`: Database type (idea | research | build) - Default: build

## Examples

```
/knowledge:archive "AI-powered documentation generator" build
/knowledge:archive "Azure OpenAI integration research" research
/knowledge:archive "Real-time cost dashboard" idea
```

## Related Commands

- `/knowledge:document` - Create Knowledge Vault entry manually
- `/notion:search` - Find items to archive
- `/cost:analyze` - Review costs before archiving builds

## Verification Steps

```
# Verify status updated
/notion:search "$1"
# Check: Status = "Archived" or "Not Active"

# Confirm Knowledge Vault entry created
/notion:search "Knowledge Vault"
# Search for: "$1" in Knowledge Vault database

# Check link preservation
# View archived item → Verify all URLs still populated
```
