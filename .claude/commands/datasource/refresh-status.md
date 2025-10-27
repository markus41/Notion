---
name: datasource:refresh-status
description: Establish data source status refresh to maintain accurate health indicators across integration portfolio
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-update-page
argument-hint: [name] <status>
model: claude-sonnet-4-5-20250929
---

# /datasource:refresh-status

**Category**: Integration Management
**Related Databases**: Data Sources
**Agent Compatibility**: @integration-specialist

## Purpose

Establish systematic data source status refresh to maintain accurate health indicators and drive visibility into integration portfolio reliability.

**Best for**: Updating connection status after maintenance, failure remediation, or routine health checks.

---

## Command Parameters

**Required:**
- `name` - Data source name
- `status` - Status (active | inactive | degraded | failed)

---

## Workflow

### Step 1: Update Status

```javascript
const statusMap = {
  'active': '✅ Active',
  'inactive': '⚫ Inactive',
  'degraded': '🟡 Degraded',
  'failed': '❌ Failed'
};

await notionUpdatePage({
  page_id: dataSourceId,
  data: {
    command: "update_properties",
    properties: {
      "Status": statusMap[status.toLowerCase()],
      "Last Checked": new Date().toISOString().split('T')[0]
    }
  }
});

console.log(`✅ Status updated: ${statusMap[status.toLowerCase()]}`);
```

---

## Execution Example

```bash
/datasource:refresh-status "Snowflake Analytics" active
```

**Output:**
```
✅ Status updated: ✅ Active
Last Checked: 2025-10-26
```

---

**Last Updated**: 2025-10-26
**Database**: Data Sources (092940f4-1e6d-4321-b06a-1c0a9ee79445)