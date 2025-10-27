---
name: okr:progress-update
description: Establish systematic OKR progress tracking to drive accountability and maintain visibility into quarterly goal achievement
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-update-page
argument-hint: [okr-title] [--progress=percentage]
model: claude-sonnet-4-5-20250929
---

# /okr:progress-update

**Category**: Strategic Planning
**Related Databases**: OKRs

## Purpose

Establish systematic OKR progress tracking to drive accountability and maintain visibility into quarterly goal achievement.

---

## Parameters

- `okr-title` - OKR to update
- `--progress=value` - Progress percentage (0-100)
- `--status=value` - Status (active | at-risk | completed)

---

## Workflow

```javascript
const okr = await notionSearch({ query: okrTitle });
await notionUpdatePage({
  page_id: okr.id,
  data: { command: 'update_properties', properties: { "Progress": progressFlag } }
});
```

---

## Example

```bash
/okr:progress-update "Q4 2025: Cost reduction" --progress=65
```

---

**Last Updated**: 2025-10-26
