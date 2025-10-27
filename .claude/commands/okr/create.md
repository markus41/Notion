---
name: okr:create
description: Establish quarterly objectives and key results to drive measurable business outcomes and align innovation initiatives with strategic goals
allowed-tools: mcp__notion__notion-create-pages, mcp__notion__notion-search
argument-hint: [objective-title] [--quarter=Q1|Q2|Q3|Q4] [--year=YYYY]
model: claude-sonnet-4-5-20250929
---

# /okr:create

**Category**: Strategic Planning
**Related Databases**: OKRs
**Agent Compatibility**: @claude-main

## Purpose

Establish quarterly objectives and key results to drive measurable business outcomes and align innovation initiatives with strategic goals.

**Best for**: Organizations requiring systematic goal tracking and performance measurement aligned with innovation portfolio.

---

## Command Parameters

**Required:**
- `objective-title` - Clear, ambitious objective statement

**Optional Flags:**
- `--quarter=value` - Target quarter (Q1-Q4, default: current)
- `--year=value` - Target year (default: current)
- `--owner=name` - Responsible team member
- `--key-results=text` - Comma-separated key results (3-5)

---

## Workflow

```javascript
const quarter = quarterFlag || getCurrentQuarter();
const year = yearFlag || new Date().getFullYear();

await notionCreatePages({
  parent: { data_source_id: '[OKR_DATABASE_ID]' },
  pages: [{
    properties: {
      "OKR Title": `${quarter} ${year}: ${objectiveTitle}`,
      "Quarter": quarter,
      "Year": year,
      "Owner": ownerFlag || 'Unassigned',
      "Status": '🔵 Planning',
      "Progress": 0
    }
  }]
});
```

---

## Execution Example

```bash
/okr:create "Achieve 25% cost reduction through Microsoft consolidation" \
  --quarter=Q4 --year=2025 --owner="Brad Wright"
```

**Output:**
```
✅ OKR created: Q4 2025: Achieve 25% cost reduction

**Next Steps:**
1. Add key results: /okr:progress-update
2. Link builds/research to OKR
```

---

## Success Criteria

- ✅ Objective stated
- ✅ Quarter/year set
- ✅ OKR entry created
- ✅ Progress tracking initialized

---

## Related Commands

- `/okr:progress-update` - Update progress
- `/build:link-okr` - Link builds

---

**Last Updated**: 2025-10-26
**Database**: OKRs (Query programmatically)