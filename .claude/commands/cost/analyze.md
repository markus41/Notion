---
description: Comprehensive software spend analysis with optimization recommendations
allowed-tools: SlashCommand(@cost-analyst:*)
argument-hint: [scope: all|active|unused|expiring]
model: claude-sonnet-4-5-20250929
---

## Context
Drive measurable cost outcomes through structured analysis of software spend, identifying optimization opportunities and tracking contract renewals.

## Workflow

Invoke @cost-analyst agent to execute comprehensive cost analysis:

1. **Query Software Tracker** based on scope parameter
   - Scope: ${1:-all}  # Default to "all" if not specified
   - Filters:
     - `all`: All software entries
     - `active`: Status = "Active"
     - `unused`: Status = "Active" AND no relations to Ideas/Research/Builds
     - `expiring`: Contract End Date within 60 days AND Status = "Active"

2. **Calculate spending metrics**
   - Total Monthly Spend: SUM(Total Monthly Cost where Status = "Active")
   - Annual Projection: Total Monthly Spend × 12
   - Top 5 Expenses: Sort by Total Monthly Cost DESC, limit 5
   - Category Breakdown: Group by Category, sum Total Monthly Cost

3. **Identify optimization opportunities**
   - Unused tools: Software with zero active relations
   - Duplicate capabilities: Multiple tools in same category
   - Overprovisioned licenses: License Count > Users count
   - Trial software: Status = "Trial" for > 30 days

4. **Check expiring contracts**
   - Query: Contract End Date between now and +60 days
   - Sort: By Contract End Date ASC
   - Alert: Flag renewals requiring decisions

5. **Generate recommendations report**
   - Prioritize by potential savings (high to low)
   - Include: Action items, responsible owner, estimated savings
   - Format: Structured markdown with cost breakdowns

6. **Present findings**

```
## Software Spend Analysis - [Date]

**Total Monthly Spend**: $X,XXX
**Annual Projection**: $XX,XXX

### Top 5 Expenses
1. [Software Name] - $X,XXX/month ([N] licenses) - [Category]
2. [Software Name] - $XXX/month ([N] licenses) - [Category]
...

### Category Breakdown
- Development: $X,XXX/month ([N] tools)
- Infrastructure: $X,XXX/month ([N] tools)
- Productivity: $XXX/month ([N] tools)
...

### Optimization Opportunities (Potential Savings: $X,XXX/month)

#### Unused Software
- [Tool Name]: $XXX/month - No active links to Ideas/Research/Builds
  - Action: Review with [Owner], consider cancellation
  - Savings: $XXX/month

#### Duplicate Capabilities
- [Category]: [N] tools serving similar purpose
  - Tools: [Tool A] ($X/month), [Tool B] ($Y/month)
  - Action: Evaluate consolidation to single platform
  - Savings: $XXX/month

#### Overprovisioned Licenses
- [Tool Name]: [N] licenses, [M] users (Excess: [N-M])
  - Action: Reduce license count or expand usage
  - Savings: $XXX/month

### Expiring Contracts (Next 60 Days)
- [Software Name] - Expires [Date] - $XXX/month
  - Owner: [Name]
  - Action Required: Renewal decision by [Date-14 days]
```

## Parameters

- `$1`: Analysis scope (all | active | unused | expiring) - Default: all

## Examples

```
/cost:analyze
/cost:analyze active
/cost:analyze unused
/cost:analyze expiring
```

## Related Commands

- `/cost:add-software` - Add new software entry to tracker
- `/cost:optimize` - Interactive cost reduction workflow
- `/notion:search` - Search for specific software entries

## Verification Steps

```
# Verify total spend calculation
# Check Software Tracker → Status = "Active" → Sum "Total Monthly Cost"

# Verify unused software detection
# For each flagged tool, check Ideas/Research/Builds relations = 0
```
