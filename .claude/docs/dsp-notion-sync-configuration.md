# DSP Command Center - Notion Sync Configuration

**Purpose**: Establish Notion database structure and synchronization configuration for DSP Command Central project tracking, enabling stakeholder visibility into development progress, deployment status, and documentation without requiring GitHub access.

**Best for**: Organizations maintaining technical projects in GitHub while providing non-technical stakeholders with accessible Notion interface for progress tracking and documentation review.

---

## Database Structure

### DSP Command Center Database

**Database Name**: `🚚 DSP Command Center`
**Parent**: Innovation Nexus workspace (or dedicated DSP workspace)
**Purpose**: Central hub for DSP project documentation, build tracking, agent activity, and deployment records

---

## Property Schema

### Core Properties

| Property Name | Type | Purpose | Example Value |
|--------------|------|---------|--------------|
| **Title** | Title | Document/page name | "VTO Acceptance Workflow" |
| **Type** | Select | Content classification | Documentation, Agent Activity, Build Record, ADR, Deployment Record |
| **Status** | Select | Development status | Draft, In Progress, Completed, Archived |
| **Priority** | Select | Importance level | Critical, High, Medium, Low |
| **Last Synced** | Date | GitHub sync timestamp | 2025-10-26 14:30 UTC |
| **GitHub Path** | URL | Source file in repository | dsp-command-central/docs/vto-workflow.md |
| **Content Hash** | Text | MD5 hash for change detection | a1b2c3d4e5f6... |
| **Sync Direction** | Select | Last sync direction | GitHub→Notion, Notion→GitHub, Conflict |

### Relational Properties

| Property Name | Type | Relation Target | Purpose |
|--------------|------|----------------|---------|
| **Assigned Agent** | Relation | Agent Registry | Link to responsible specialist agent |
| **Related Build** | Relation | Example Builds | Connect to DSP Command Central build entry |
| **Related Idea** | Relation | Ideas Registry | Link to originating innovation idea |
| **Software Used** | Relation | Software & Cost Tracker | Track tools/services required |

### Technical Properties

| Property Name | Type | Purpose | Example Value |
|--------------|------|---------|--------------|
| **Azure Environment** | Select | Deployment target | Demo, Staging, Production |
| **Deployment URL** | URL | Live application URL | https://app-dsp-dashboard-demo.azurewebsites.net |
| **Cost Impact** | Number | Monthly cost ($) | 54.00 |
| **Lines of Code** | Number | Documentation size | 2450 |
| **Test Coverage** | Number | Code coverage % | 87.5 |

### Metadata Properties

| Property Name | Type | Purpose | Example Value |
|--------------|------|---------|--------------|
| **Created By** | Created by | Auto-populated | Markus Ahling |
| **Created Time** | Created time | Auto-populated | 2025-10-26 10:00 |
| **Last Edited By** | Last edited by | Auto-populated | Claude AI |
| **Last Edited Time** | Last edited time | Auto-populated | 2025-10-26 14:30 |

---

## Select Options Configuration

### Type (Select)
- 📄 **Documentation** - Technical guides, architecture docs, user manuals
- 🤖 **Agent Activity** - Logged agent work sessions and deliverables
- 🛠️ **Build Record** - Build artifacts, deployment logs, release notes
- 📋 **ADR** - Architecture Decision Records
- 🚀 **Deployment Record** - Azure deployment summaries with URLs and costs
- 🧪 **Test Report** - Testing results (E2E, integration, performance)

### Status (Select)
- 🔵 **Draft** - Work in progress, not ready for review
- 🟡 **In Progress** - Actively being developed/written
- 🟢 **Completed** - Finished and synced to GitHub
- 🔴 **Blocked** - Waiting on dependencies or external input
- ⚫ **Archived** - Historical reference, no longer active

### Priority (Select)
- 🔴 **Critical** - Blocking deployment or essential feature
- 🟠 **High** - Important for next milestone
- 🟡 **Medium** - Scheduled but not urgent
- 🟢 **Low** - Nice-to-have or future consideration

### Sync Direction (Select)
- ⬇️ **GitHub→Notion** - Latest content from GitHub repository
- ⬆️ **Notion→GitHub** - Updated by stakeholder in Notion, needs Git commit
- ⚠️ **Conflict** - Both modified since last sync, requires manual resolution
- 🔄 **Bidirectional** - Regular sync in both directions

### Azure Environment (Select)
- 💻 **Demo** - B1/C0 SKUs (~$54/month) for demonstrations
- 🧪 **Staging** - S1/C1 SKUs (~$180/month) for pre-production testing
- 🏭 **Production** - P1v2/C2 SKUs (~$280/month) for live operations

---

## Database Views

### View 1: Active Documentation (Default)

**Purpose**: Show all active documentation and build records

**Filter**:
```
Status is "In Progress" OR Status is "Completed"
AND
Type is "Documentation" OR Type is "Build Record" OR Type is "ADR"
```

**Sort**:
- Primary: Last Edited Time (descending)
- Secondary: Priority (Critical → Low)

**Displayed Properties**:
- Title
- Type
- Status
- Priority
- Assigned Agent (relation)
- Last Synced
- GitHub Path (URL)

**Layout**: Table

---

### View 2: Agent Activity Log

**Purpose**: Track all agent work sessions chronologically

**Filter**:
```
Type is "Agent Activity"
```

**Sort**:
- Created Time (descending)

**Displayed Properties**:
- Title (agent name + timestamp)
- Assigned Agent (relation)
- Status
- Lines of Code
- Related Build (relation)
- Created Time

**Layout**: Timeline (by Created Time)

---

### View 3: Deployment History

**Purpose**: Track all Azure deployments with URLs and costs

**Filter**:
```
Type is "Deployment Record"
```

**Sort**:
- Created Time (descending)

**Displayed Properties**:
- Title (deployment name + environment)
- Azure Environment
- Deployment URL
- Cost Impact
- Status
- Last Synced
- Created Time

**Layout**: Table

**Grouping**: Group by Azure Environment

---

### View 4: GitHub Sync Queue

**Purpose**: Identify content needing synchronization

**Filter**:
```
Sync Direction is "Notion→GitHub" OR Sync Direction is "Conflict"
```

**Sort**:
- Priority (Critical → Low)
- Last Edited Time (oldest first)

**Displayed Properties**:
- Title
- Type
- Sync Direction
- GitHub Path
- Last Synced
- Last Edited Time

**Layout**: Table

**Color Coding**:
- Red: Sync Direction = "Conflict"
- Orange: Sync Direction = "Notion→GitHub"

---

### View 5: Cost Tracking

**Purpose**: Monitor DSP-related software and infrastructure costs

**Filter**:
```
Cost Impact is not empty
```

**Sort**:
- Cost Impact (descending)

**Displayed Properties**:
- Title
- Type
- Azure Environment
- Cost Impact
- Software Used (relation → rollup to total software cost)
- Status

**Layout**: Table

**Formula Property** (Total Monthly Cost):
```
prop("Cost Impact") + prop("Software Used Rollup")
```

---

## Notion Database Creation Script

### Using Notion MCP Server

```typescript
/**
 * Establish DSP Command Center database in Notion with complete schema.
 * Designed for programmatic creation via Notion MCP server.
 */
import { NotionClient } from '@notionhq/client';

async function createDSPCommandCenterDatabase() {
  const notion = new NotionClient({
    auth: process.env.NOTION_API_KEY
  });

  const database = await notion.databases.create({
    parent: {
      type: 'page_id',
      page_id: process.env.DSP_PARENT_PAGE_ID // Or workspace ID
    },
    title: [
      {
        type: 'text',
        text: { content: '🚚 DSP Command Center' }
      }
    ],
    properties: {
      // Title property (required)
      'Title': {
        title: {}
      },

      // Core properties
      'Type': {
        select: {
          options: [
            { name: '📄 Documentation', color: 'blue' },
            { name: '🤖 Agent Activity', color: 'purple' },
            { name: '🛠️ Build Record', color: 'orange' },
            { name: '📋 ADR', color: 'green' },
            { name: '🚀 Deployment Record', color: 'red' },
            { name: '🧪 Test Report', color: 'yellow' }
          ]
        }
      },

      'Status': {
        select: {
          options: [
            { name: '🔵 Draft', color: 'blue' },
            { name: '🟡 In Progress', color: 'yellow' },
            { name: '🟢 Completed', color: 'green' },
            { name: '🔴 Blocked', color: 'red' },
            { name: '⚫ Archived', color: 'gray' }
          ]
        }
      },

      'Priority': {
        select: {
          options: [
            { name: '🔴 Critical', color: 'red' },
            { name: '🟠 High', color: 'orange' },
            { name: '🟡 Medium', color: 'yellow' },
            { name: '🟢 Low', color: 'green' }
          ]
        }
      },

      'Last Synced': {
        date: {}
      },

      'GitHub Path': {
        url: {}
      },

      'Content Hash': {
        rich_text: {}
      },

      'Sync Direction': {
        select: {
          options: [
            { name: '⬇️ GitHub→Notion', color: 'blue' },
            { name: '⬆️ Notion→GitHub', color: 'orange' },
            { name: '⚠️ Conflict', color: 'red' },
            { name: '🔄 Bidirectional', color: 'green' }
          ]
        }
      },

      // Relational properties
      'Assigned Agent': {
        relation: {
          database_id: AGENT_REGISTRY_DATABASE_ID,
          type: 'single_property'
        }
      },

      'Related Build': {
        relation: {
          database_id: EXAMPLE_BUILDS_DATABASE_ID,
          type: 'single_property'
        }
      },

      'Related Idea': {
        relation: {
          database_id: IDEAS_REGISTRY_DATABASE_ID,
          type: 'single_property'
        }
      },

      'Software Used': {
        relation: {
          database_id: SOFTWARE_TRACKER_DATABASE_ID,
          type: 'dual_property',
          dual_property: {
            synced_property_name: 'DSP Usage'
          }
        }
      },

      // Technical properties
      'Azure Environment': {
        select: {
          options: [
            { name: '💻 Demo', color: 'blue' },
            { name: '🧪 Staging', color: 'yellow' },
            { name: '🏭 Production', color: 'red' }
          ]
        }
      },

      'Deployment URL': {
        url: {}
      },

      'Cost Impact': {
        number: {
          format: 'dollar'
        }
      },

      'Lines of Code': {
        number: {
          format: 'number'
        }
      },

      'Test Coverage': {
        number: {
          format: 'percent'
        }
      }
    }
  });

  console.log(`✅ DSP Command Center created: ${database.url}`);
  return database;
}
```

---

## Automated Sync Configuration

### Sync Schedule

**Frequency**: Daily at 2:00 AM UTC (via GitHub Actions)
**Trigger**: Also runs on every push to `main` branch in `dsp-command-central/` directory
**Scope**: All documentation files, agent activity logs, deployment records

### Sync Workflow (GitHub Actions)

```yaml
name: Sync DSP Docs to Notion

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
  push:
    branches: [main]
    paths:
      - 'dsp-command-central/**/*.md'
      - '.claude/agents/dsp-*.md'
      - '.claude/logs/AGENT_ACTIVITY_LOG.md'

jobs:
  sync-notion:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20.x'

      - name: Configure Notion MCP
        env:
          NOTION_API_KEY: ${{ secrets.NOTION_API_KEY }}
          NOTION_WORKSPACE_ID: ${{ secrets.NOTION_WORKSPACE_ID }}
        run: |
          echo "NOTION_API_KEY=$NOTION_API_KEY" >> $GITHUB_ENV
          echo "NOTION_WORKSPACE_ID=$NOTION_WORKSPACE_ID" >> $GITHUB_ENV

      - name: Run Bidirectional Sync
        run: |
          /dsp:sync-notion \
            --direction bidirectional \
            --scope all

      - name: Commit Notion Updates (if any)
        run: |
          git config --global user.name "DSP Notion Sync Bot"
          git config --global user.email "noreply@brooksidebi.com"

          if [ -n "$(git status --porcelain)" ]; then
            git add .
            git commit -m "docs: Sync Notion stakeholder updates to GitHub

            🔄 Automated bidirectional sync from DSP Command Center

            Co-Authored-By: Claude <noreply@anthropic.com>"

            git push origin main
          else
            echo "No changes to commit"
          fi

      - name: Upload Sync Report
        uses: actions/upload-artifact@v3
        with:
          name: notion-sync-report
          path: /tmp/notion-sync-report-*.md
```

---

## Manual Sync Operations

### Sync All Documentation to Notion

```bash
# One-time sync of all DSP documentation
/dsp:sync-notion --direction github-to-notion --scope docs
```

### Sync Agent Activity Logs

```bash
# Sync agent activity to Notion Agent Activity Hub
/dsp:sync-notion --direction github-to-notion --scope activity
```

### Pull Stakeholder Edits from Notion

```bash
# Retrieve documentation updates made in Notion UI
/dsp:sync-notion --direction notion-to-github --scope docs

# Review changes before committing
git diff

# Commit if approved
git commit -m "docs: Apply stakeholder feedback from Notion"
git push
```

### Dry Run (Validation Only)

```bash
# Preview sync without executing
/dsp:sync-notion --direction bidirectional --scope all --dry-run
```

---

## Access Permissions & Sharing

### Recommended Access Levels

| Role | Access Level | Permissions | Use Case |
|------|-------------|-------------|----------|
| **DSP Owner** | Full Access | View, Comment, Edit | Primary stakeholder reviewing all documentation |
| **Dispatchers** | View & Comment | View, Comment | Operational staff providing feedback on workflows |
| **Development Team** | Full Access | View, Comment, Edit | Technical team making documentation updates |
| **External Consultants** | View Only | View | Third-party reviewers requiring read-only access |

### Sharing Configuration

**Workspace Sharing**: Private (DSP team members only)
**Public Link**: Disabled (sensitive operational data)
**Guest Access**: Allowed for DSP owner (if not in Brookside BI workspace)

---

## Integration with Existing Databases

### Link to Example Builds

**Relation**: DSP Command Center → Example Builds
**Purpose**: Connect documentation pages to the main DSP Command Central build entry
**Rollup**: Calculate total software costs from linked Software Tracker items

**Example**:
```
DSP Command Center Page: "VTO Acceptance Workflow Documentation"
  └─ Related Build: "DSP Command Central" (from Example Builds)
      └─ Software Used: NestJS, PostgreSQL, Redis, Azure App Services
          └─ Total Monthly Cost: $280 (production tier)
```

---

### Link to Software & Cost Tracker

**Relation**: DSP Command Center → Software & Cost Tracker
**Purpose**: Track all tools and services required for DSP operations
**Rollup Formula** (Total Software Cost):
```
sum(prop("Software Used", "Monthly Cost"))
```

**Software Items to Link**:
- NestJS (Free - open source)
- PostgreSQL Azure (Variable: $25-$150/month based on tier)
- Redis Azure (Variable: $16-$55/month based on tier)
- Azure App Services (Variable: $13-$150/month based on tier)
- Expo (Free for basic, $99/month for production features)
- GitHub (Team plan: $4/user/month)

---

### Link to Agent Registry

**Relation**: DSP Command Center → Agent Registry
**Purpose**: Track which specialized agent is responsible for each documentation entry
**Filter**: Only show DSP-specific agents (dsp-operations-architect, dsp-backend-api-architect, etc.)

**Example Assignments**:
- "Rescue Scoring Algorithm" → Assigned Agent: @dsp-operations-architect
- "NestJS API Documentation" → Assigned Agent: @dsp-backend-api-architect
- "Azure Infrastructure Bicep Templates" → Assigned Agent: @dsp-azure-devops-specialist

---

## Notion Page Templates

### Template 1: Documentation Page

```markdown
# [Document Title]

**Type**: 📄 Documentation
**Status**: 🟡 In Progress
**Assigned Agent**: [@agent-name]
**GitHub Path**: dsp-command-central/docs/[filename].md

---

## Overview

[Brief description of what this document covers]

## Prerequisites

- [Requirement 1]
- [Requirement 2]

## Step-by-Step Guide

### Step 1: [Action]

[Detailed instructions]

```bash
# Code example
```

### Step 2: [Action]

[Detailed instructions]

## Troubleshooting

### Issue: [Problem]
**Solution**: [Resolution steps]

## Related Documentation

- <mention-page url="[related-doc-url]">Related Doc</mention-page>

---

**Last Updated**: [Auto-populated by Notion]
**Synced from GitHub**: [Last Synced timestamp]
```

---

### Template 2: Deployment Record

```markdown
# Deployment: [Environment] - [Date]

**Type**: 🚀 Deployment Record
**Azure Environment**: [Demo/Staging/Production]
**Status**: 🟢 Completed
**Cost Impact**: $[amount]/month

---

## Deployment Summary

- **Backend API**: [URL]
- **Web Dashboard**: [URL]
- **Mobile App**: Expo OTA Channel: [channel-name]
- **Deployment Duration**: [X] minutes

## Resources Provisioned

| Resource | SKU | Cost/Month |
|----------|-----|------------|
| App Service Plan | [B1/S1/P1v2] | $[amount] |
| PostgreSQL | [B1ms/GP D2s_v3] | $[amount] |
| Redis | [C0/C1/C2] | $[amount] |
| **Total** | | **$[total]** |

## Health Checks

- ✅ Backend API responsive (200 OK)
- ✅ Database migrations applied
- ✅ Dashboard accessible
- ✅ WebSocket connections functional

## Next Steps

1. [Action item 1]
2. [Action item 2]

---

**Deployed By**: [Assigned Agent]
**GitHub Commit**: [commit-hash]
```

---

## Troubleshooting Sync Issues

### Issue: Content Hash Mismatches

**Symptom**: Sync validation report shows hash discrepancies between GitHub and Notion

**Causes**:
1. Manual edits in both GitHub and Notion without syncing
2. Line ending differences (CRLF vs LF)
3. Trailing whitespace inconsistencies

**Resolution**:
```bash
# Review differences
git diff [file-path]

# Manually resolve conflicts
# Option 1: Accept GitHub version
git checkout HEAD -- [file-path]

# Option 2: Accept Notion version
/dsp:sync-notion --direction notion-to-github --scope docs

# Re-sync after resolution
/dsp:sync-notion --direction bidirectional --scope all
```

---

### Issue: Missing GitHub Path Property

**Symptom**: Notion pages cannot be matched to GitHub files during sync

**Causes**:
1. Pages created manually in Notion without automation
2. GitHub files moved/renamed without updating Notion
3. Sync metadata corruption

**Resolution**:
```typescript
// Manually populate GitHub Path for orphaned pages
async function fixOrphanedPages() {
  const orphanedPages = await notion.databases.query({
    database_id: DSP_COMMAND_CENTER_DB_ID,
    filter: {
      property: 'GitHub Path',
      url: { is_empty: true }
    }
  });

  for (const page of orphanedPages.results) {
    const title = page.properties.Title.title[0].plain_text;

    // Infer GitHub path from title
    const githubPath = inferGithubPath(title);

    await notion.pages.update({
      page_id: page.id,
      properties: {
        'GitHub Path': { url: githubPath }
      }
    });
  }
}
```

---

## Success Metrics

**Sync configuration is successful when:**

✅ All DSP documentation synced to Notion within 5 minutes of GitHub commit
✅ Stakeholders can view latest docs without GitHub account
✅ Agent activity logs visible in Notion Agent Activity Hub
✅ Deployment records auto-populated with URLs and costs
✅ Notion edits sync back to GitHub within 24 hours
✅ Conflict detection prevents accidental overwrites
✅ Content hash validation passes >95% of time
✅ DSP owner reports improved visibility into project progress

---

## Related Documentation

- [/dsp:sync-notion Command](./.claude/commands/dsp/sync-notion.md)
- [Agent Activity Center](./.claude/docs/agent-activity-center.md)
- [Notion Schema Reference](./.claude/docs/notion-schema.md)
- [DSP Agent Coordination Guide](./.claude/docs/dsp-agent-coordination.md)

---

**Brookside BI** - *Driving measurable outcomes through unified documentation ecosystems*
