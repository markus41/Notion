---
name: project:sync-github
description: Establish GitHub repository synchronization for projects to maintain accurate repository counts and integration health
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-fetch, mcp__notion__notion-update-page, mcp__github__search_repositories
argument-hint: [project-name]
model: claude-sonnet-4-5-20250929
---

# /project:sync-github

**Category**: Project Management
**Related Databases**: Projects
**Agent Compatibility**: @build-architect

## Purpose

Establish automated GitHub repository synchronization for projects to maintain accurate repository counts, detect integration health, and drive visibility into development activity across project scope.

**Best for**: Projects with multiple GitHub repositories requiring automated synchronization of repository metadata and health indicators.

---

## Command Parameters

**Required:**
- `project-name` - Name of project to sync

---

## Workflow

### Step 1: Fetch Project Details

```javascript
const projectResults = await notionSearch({
  query: projectName,
  data_source_url: "collection://9f75999b-62d2-4c78-943e-c3e0debccfcd"
});

const project = await notionFetch({ id: projectResults.results[0].id });
const githubOrg = project.properties["GitHub Organization"]?.rich_text?.[0]?.plain_text;

if (!githubOrg) {
  console.error(`❌ No GitHub organization linked to project`);
  return;
}
```

### Step 2: Fetch GitHub Repositories

```javascript
const repos = await mcp__github__search_repositories({
  query: `org:${githubOrg}`
});

console.log(`✅ Found ${repos.items.length} repositories in ${githubOrg}`);
```

### Step 3: Update Project

```javascript
await notionUpdatePage({
  page_id: project.id,
  data: {
    command: "update_properties",
    properties: {
      "Repository Count": repos.items.length,
      "Last Synced": new Date().toISOString().split('T')[0]
    }
  }
});

console.log(`✅ Project synced with GitHub`);
```

---

## Execution Example

```bash
/project:sync-github "Customer Analytics Platform"
```

**Output:**
```
✅ Found 12 repositories in brookside
✅ Project synced with GitHub

Repository Count: 12
Last Synced: 2025-10-26
```

---

## Success Criteria

- ✅ Project located
- ✅ GitHub organization identified
- ✅ Repositories fetched
- ✅ Counts updated in Notion

---

**Last Updated**: 2025-10-26
**Database**: Projects (9f75999b-62d2-4c78-943e-c3e0debccfcd)
