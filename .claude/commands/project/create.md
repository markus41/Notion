---
name: project:create
description: Establish project tracking entry with GitHub integration and team assignments to drive coordinated multi-build initiatives
allowed-tools: mcp__notion__notion-create-pages
argument-hint: [project-name] [--github-org=name] [--lead=person]
model: claude-sonnet-4-5-20250929
---

# /project:create

**Category**: Project Management
**Related Databases**: Projects
**Agent Compatibility**: @build-architect

## Purpose

Establish project tracking for multi-build initiatives with GitHub organization integration and team assignments—designed for organizations coordinating complex projects spanning multiple repositories, builds, and team members.

**Best for**: Large initiatives requiring coordination across multiple builds, GitHub repositories, or team members where centralized project tracking drives alignment and progress visibility.

---

## Command Parameters

**Required:**
- `project-name` - Name of project

**Optional Flags:**
- `--github-org=name` - GitHub organization name
- `--lead=person` - Project lead name
- `--description="text"` - Project description
- `--status=value` - Initial status (planning | active | completed, default: planning)

---

## Workflow

### Step 1: Create Project Entry

```javascript
const projectData = {
  name: `📦 ${projectName}`,
  status: statusMap[statusFlag || 'planning'] || '📋 Planning',
  description: descriptionFlag || '',
  githubOrg: githubOrgFlag || null,
  lead: leadFlag ? await getUserId(leadFlag) : null,
  startDate: new Date().toISOString().split('T')[0]
};

await notionCreatePages({
  parent: { data_source_id: "9f75999b-62d2-4c78-943e-c3e0debccfcd" },
  pages: [{
    properties: {
      "Project Name": projectData.name,
      "Status": projectData.status,
      "Description": projectData.description,
      "GitHub Organization": projectData.githubOrg,
      "Project Lead": projectData.lead,
      "Start Date": projectData.startDate
    }
  }]
});

console.log(`✅ Project created: ${projectData.name}`);
```

### Step 2: Present Next Steps

```javascript
console.log(`\n**Next Steps:**`);
console.log(`   1. Link builds: Add relation in Notion`);
console.log(`   2. Sync GitHub: /project:sync-github "${projectName}"`);
console.log(`   3. Assign team: /team:assign "${projectName}" project`);
```

---

## Execution Examples

### Example: Create Customer Platform Project

```bash
/project:create "Customer Analytics Platform" \
  --github-org="brookside" \
  --lead="Markus Ahling" \
  --description="Unified customer data platform with ML insights"
```

**Output:**
```
✅ Project created: 📦 Customer Analytics Platform

**Next Steps:**
   1. Link builds: Add relation in Notion
   2. Sync GitHub: /project:sync-github "Customer Analytics Platform"
   3. Assign team: /team:assign "Customer Analytics Platform" project
```

---

## Success Criteria

- ✅ Project entry created in Projects database
- ✅ GitHub organization linked (if provided)
- ✅ Project lead assigned (if provided)
- ✅ Status set appropriately

---

## Related Commands

- `/project:sync-github [name]` - Sync GitHub repos
- `/project:update-status [name] [status]` - Update project status
- `/build:create [name]` - Create related builds

---

**Last Updated**: 2025-10-26
**Database**: Projects (9f75999b-62d2-4c78-943e-c3e0debccfcd)
