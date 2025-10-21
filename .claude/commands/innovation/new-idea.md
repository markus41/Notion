---
description: Capture and structure new innovation opportunity with viability assessment
allowed-tools: SlashCommand(@ideas-capture:*)
argument-hint: [idea description]
model: claude-sonnet-4-5-20250929
---

## Context
Streamline the process of capturing innovation opportunities while ensuring duplicate prevention, cost awareness, and proper team assignment.

## Workflow

Invoke @ideas-capture agent to execute this workflow:

1. **Search for existing similar ideas** in Ideas Registry
   - Query: Extract key concepts from "$ARGUMENTS"
   - If duplicates found: Present to user, ask to proceed or link to existing

2. **Create Ideas Registry entry** if no duplicates:
   - Title: $ARGUMENTS
   - Status: Concept (default)
   - Viability: Needs Research (will be assessed)
   - Innovation Type: [Infer from description: Process Improvement / Technical / Business Model / Product]
   - Champion: [Assign based on team member specialization]
   - Effort: [Estimate: XS/S/M/L/XL]
   - Impact Score: [Rate 1-10 based on description]

3. **Link related software** from Software Tracker
   - Identify: Tools/platforms mentioned in description
   - Search: Software Tracker for existing entries
   - Link: Create relations to Ideas Registry
   - Display: Estimated monthly cost from rollup

4. **Check for research needs**
   - Ask: "Does this idea need research before building?"
   - If yes: Offer to run `/innovation:start-research`
   - If no: Offer to run `/innovation:create-build`

5. **Report creation confirmation**
   - Format: "Created idea '[$ARGUMENTS]' with [Champion] as champion. Estimated cost: $X/month. Viability: [Assessment]. Next step: [Research/Build]?"

## Parameters

- `$ARGUMENTS`: Full idea description (title and details)

## Examples

```
/innovation:new-idea Automated Power BI deployment pipeline using Azure DevOps
/innovation:new-idea Real-time cost tracking dashboard for all Microsoft subscriptions
/innovation:new-idea AI-powered documentation generator from code comments
```

## Related Commands

- `/innovation:start-research` - Begin feasibility investigation for idea
- `/innovation:create-build` - Create prototype/example directly
- `/cost:add-software` - Add new software tool to tracker

## Verification Steps

```
# Verify idea was created
/notion:search "$ARGUMENTS"

# Check cost rollup
# View Ideas Registry entry, verify "Estimated Cost" rollup displays
```
