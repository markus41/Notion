---
description: Route work to appropriate team member based on specialization and workload
allowed-tools: SlashCommand(@workflow-router:*)
argument-hint: [work-description] [database: idea|research|build]
model: claude-sonnet-4-5-20250929
---

## Context
Drive measurable outcomes through strategic team alignment, ensuring work is assigned to members with appropriate expertise while balancing workload distribution.

## Workflow

Invoke @workflow-router agent to analyze and assign work:

1. **Analyze work nature** from description
   - Input: "$1" (work description)
   - Extract keywords: Technology, domain, function
   - Categorize: Engineering | Operations | Sales | Business | DevOps | ML | AI | Infrastructure | Security | Research | Finance | Marketing

2. **Match to team specializations**

**Team Member Expertise**:
- **Markus Ahling**: Engineering, Operations, AI, Infrastructure
- **Brad Wright**: Sales, Business, Finance, Marketing
- **Stephan Densby**: Operations, Continuous Improvement, Research
- **Alec Fielding**: DevOps, Engineering, Security, Integrations, R&D, Infrastructure
- **Mitch Bisbee**: DevOps, Engineering, ML, Master Data, Quality

**Matching Logic**:
   - Primary match: Strongest specialization alignment
   - Secondary match: Adjacent skill areas
   - Multi-person: If work requires multiple specializations

3. **Check current workload** for recommended assignee(s)
   - Query: Count active items by assignee
     - Ideas: Status = "Active" AND Champion = [Person]
     - Research: Status = "Active" AND Researchers contains [Person]
     - Builds: Status = "Active" AND (Lead Builder = [Person] OR Core Team contains [Person])
   - Calculate: Total active items per person
   - Threshold: Flag if person has > 5 active items

4. **Generate assignment recommendation**
   - Recommended Champion/Lead: [Name]
   - Rationale: [Specialization match explanation]
   - Workload: [N] active items (⚠️ if > 5)
   - Alternative: [Name] if primary is overloaded
   - Supporting Team: [Names] if multi-person work

5. **Locate and update item** if database specified
   - Database: ${2:-none}  # Optional parameter
   - Search: "$1" in specified database
   - Update: Champion/Lead Builder/Researchers field
   - Notify: Assigned person(s)

6. **Report assignment**

```
## Team Assignment Recommendation

**Work**: $1
**Type**: [Inferred category]

### Recommended Assignment
**Primary**: [Name]
- **Specializations**: [Matching areas]
- **Current Workload**: [N] active items
- **Rationale**: [Why this person is best fit]

**Supporting Team** (if applicable):
- [Name]: [Role/reason]
- [Name]: [Role/reason]

### Alternative Options
**If primary overloaded**:
- [Name]: [Specialization match, workload]

### Workload Overview
- Markus Ahling: [N] active
- Brad Wright: [N] active
- Stephan Densby: [N] active
- Alec Fielding: [N] active
- Mitch Bisbee: [N] active

⚠️ **Overloaded**: [Names with > 5 active items]
```

## Parameters

- `$1`: Work description (title or detailed description)
- `$2`: (Optional) Database type to update (idea | research | build)

## Examples

```
/team:assign "Azure OpenAI integration with Power BI for real-time insights" build
/team:assign "Sales process optimization research" research
/team:assign "Cost reduction initiative for Microsoft 365 licenses"
/team:assign "Machine learning model for demand forecasting" idea
```

## Related Commands

- `/team:workload` - View current team workload distribution
- `/innovation:new-idea` - Create idea with automatic champion assignment
- `/innovation:start-research` - Create research with automatic researcher assignment

## Verification Steps

```
# Verify assignment if database was specified
/notion:search "$1"
# Check: Champion/Lead Builder/Researchers field populated

# Check workload distribution
# Query each database for Status = "Active", group by assignee
```
