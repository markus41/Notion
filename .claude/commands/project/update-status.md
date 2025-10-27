---
name: project:update-status
description: Establish project status tracking to maintain portfolio visibility and drive stakeholder communication
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-update-page
argument-hint: [project-name] <status>
model: claude-sonnet-4-5-20250929
---

# /project:update-status

**Category**: Project Management
**Related Databases**: Projects
**Agent Compatibility**: @build-architect

## Purpose

Establish systematic project status tracking to maintain portfolio health visibility and drive transparent stakeholder communication through lifecycle phase management.

**Best for**: Project status transitions requiring consistent tracking and stakeholder updates across multi-build initiatives.

---

## Command Parameters

**Required:**
- `project-name` - Project to update
- `status` - Target status (planning | active | completed | on-hold)

---

## Workflow

### Step 1: Search Project

```javascript
const projectResults = await notionSearch({
  query: projectName,
  data_source_url: "collection://9f75999b-62d2-4c78-943e-c3e0debccfcd"
});

if (projectResults.results.length === 0) {
  console.error(`❌ Project not found: "${projectName}"`);
  return;
}
```

### Step 2: Update Status

```javascript
const statusMap = {
  'planning': '📋 Planning',
  'active': '🟢 Active',
  'completed': '✅ Completed',
  'on-hold': '🟡 On Hold'
};

await notionUpdatePage({
  page_id: projectResults.results[0].id,
  data: {
    command: "update_properties",
    properties: {
      "Status": statusMap[status.toLowerCase()]
    }
  }
});

console.log(`✅ Project status updated: ${statusMap[status.toLowerCase()]}`);
```

---

## Execution Example

```bash
/project:update-status "Customer Analytics Platform" active
```

**Output:**
```
✅ Project status updated: 🟢 Active
```

---

**Last Updated**: 2025-10-26
**Database**: Projects (9f75999b-62d2-4c78-943e-c3e0debccfcd)