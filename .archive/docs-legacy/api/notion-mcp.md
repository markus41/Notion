# Notion MCP Server - API Reference

**Author**: Claude Code Agent (Markdown Expert)
**Date**: October 21, 2025
**Version**: 1.0.0
**Status**: Production Ready

## Overview

Establish seamless integration with Notion workspace to streamline innovation management workflows through programmatic access to pages, databases, and content. This solution is designed for organizations scaling innovation tracking across teams who require centralized knowledge management.

**Best for**: Teams managing Ideas Registry, Research Hub, Example Builds, and Knowledge Vault databases through automated workflows.

## Table of Contents

- [Authentication Setup](#authentication-setup)
- [Core Operations](#core-operations)
  - [Search Operations](#search-operations)
  - [Fetch Operations](#fetch-operations)
  - [Create Operations](#create-operations)
  - [Update Operations](#update-operations)
- [Database Operations](#database-operations)
- [Common Workflows](#common-workflows)
- [Error Handling](#error-handling)
- [Troubleshooting](#troubleshooting)

## Authentication Setup

### Prerequisites

- Claude Code installed and configured
- Notion workspace access with appropriate permissions
- MCP server configuration in `.claude.json`

### Configuration

The Notion MCP server is configured via HTTP transport in `.claude.json`:

```json
{
  "mcpServers": {
    "notion": {
      "url": "https://mcp.notion.com/mcp",
      "transport": "http"
    }
  }
}
```

### Authentication Flow

**Step 1: Restart Claude Code**
```bash
# Close Claude Code completely
# Relaunch Claude Code to trigger OAuth flow
```

**Step 2: Authenticate via Browser**
- Browser window opens automatically
- Login to Notion account
- Grant workspace access to Claude Code
- Confirm permissions for databases and pages

**Step 3: Verify Connection**
```bash
# In Claude Code terminal or via command
claude mcp list
```

**Expected Output**:
```
✓ notion: Connected
  Workspace: Brookside BI (81686779-099a-8195-b49e-00037e25c23e)
  Access: Full workspace access
```

### Environment Variables

While Notion MCP uses OAuth, you may need these environment variables for programmatic access:

```bash
# Optional: For direct API access outside Claude Code
NOTION_API_KEY=ntn_...           # Integration token
NOTION_WORKSPACE_ID=81686779-099a-8195-b49e-00037e25c23e
```

**Retrieve from Azure Key Vault** (if storing API key):
```powershell
$env:NOTION_API_KEY = .\scripts\Get-KeyVaultSecret.ps1 -SecretName "notion-api-key"
```

## Core Operations

### Search Operations

#### Semantic Search Across Workspace

Search entire workspace using AI-powered semantic search to find relevant content across all databases and pages.

**Tool Name**: `notion-search`

**Parameters**:
- `query` (string, required): Search query
- `query_type` (string, optional): `"internal"` (default) or `"user"`
- `page_url` (string, optional): Restrict search to specific page
- `data_source_url` (string, optional): Search within specific database data source
- `teamspace_id` (string, optional): Restrict to teamspace
- `filters` (object, optional): Created date range, creator user IDs

**Example: Basic Search**
```typescript
// Search for ideas related to Azure OpenAI
{
  "query": "Azure OpenAI integration",
  "query_type": "internal"
}
```

**Example: Search Within Database**
```typescript
// Search within Ideas Registry database
{
  "query": "automation",
  "data_source_url": "collection://984a4038-3e45-4a98-8df4-fd64dd8a1032"
}
```

**Example: Search with Filters**
```typescript
// Find recent research created by Markus
{
  "query": "machine learning feasibility",
  "filters": {
    "created_date_range": {
      "start_date": "2025-01-01",
      "end_date": "2025-10-21"
    },
    "created_by_user_ids": ["user-id-here"]
  }
}
```

**Example: User Search**
```typescript
// Find team members by name or email
{
  "query": "markus",
  "query_type": "user"
}
```

### Fetch Operations

#### Retrieve Page or Database Details

Fetch complete details about a Notion page or database including content, properties, and schema.

**Tool Name**: `notion-fetch`

**Parameters**:
- `id` (string, required): Page URL or ID (UUIDv4 with or without dashes)

**Example: Fetch Page by URL**
```typescript
{
  "id": "https://notion.so/workspace/Page-a1b2c3d4e5f67890"
}
```

**Example: Fetch Page by ID**
```typescript
{
  "id": "12345678-90ab-cdef-1234-567890abcdef"
}
```

**Example: Fetch Database**
```typescript
{
  "id": "984a4038-3e45-4a98-8df4-fd64dd8a1032"
}
```

**Response Structure** (Page):
```markdown
# Page Title

Page content in Notion-flavored Markdown format...

## Properties
- Status: Active
- Viability: High
- Champion: Markus Ahling
```

**Response Structure** (Database):
```markdown
# Database Title

<database url="..." data-source-url="collection://...">
  <schema>
    <!-- Property definitions -->
    <property name="Status" type="select">
      <options>
        <option name="Active" color="green"/>
        <option name="Not Active" color="gray"/>
      </options>
    </property>
  </schema>
</database>
```

### Create Operations

#### Create New Pages

Create one or more pages in Notion workspace with properties and content.

**Tool Name**: `notion-create-pages`

**Parameters**:
- `pages` (array, required): Array of page objects to create
  - `properties` (object, required): Page properties (title, status, etc.)
  - `content` (string, optional): Page content in Notion-flavored Markdown
- `parent` (object, optional): Parent location
  - `page_id` (string): Parent page ID
  - `database_id` (string): Parent database ID
  - `data_source_id` (string): Data source ID (for multi-source databases)

**Example: Create Standalone Page**
```typescript
{
  "pages": [
    {
      "properties": {
        "title": "Azure OpenAI Integration Research"
      },
      "content": `# Research Overview

This research investigates the viability of integrating Azure OpenAI services into existing Power BI solutions.

## Hypothesis
Azure OpenAI can enhance data insights through natural language querying.

## Methodology
1. Literature review of Azure OpenAI capabilities
2. Proof-of-concept implementation
3. Cost-benefit analysis
`
    }
  ]
}
```

**Example: Create Idea in Ideas Registry**
```typescript
{
  "parent": {
    "data_source_id": "984a4038-3e45-4a98-8df4-fd64dd8a1032"
  },
  "pages": [
    {
      "properties": {
        "Idea Title": "Automated Cost Tracking Dashboard",
        "Status": "Concept",
        "Viability": "Needs Research",
        "Innovation Type": "Internal Tool",
        "Effort": "M",
        "Impact Score": 8,
        "Champion": "Markus Ahling"
      }
    }
  ]
}
```

**Example: Create Build with Content**
```typescript
{
  "parent": {
    "data_source_id": "a1cd1528-971d-4873-a176-5e93b93555f6"
  },
  "pages": [
    {
      "properties": {
        "Build Name": "Cost Dashboard MVP",
        "Status": "Active",
        "Build Type": "MVP",
        "Viability": "Needs Work",
        "Reusability": "Highly Reusable",
        "Lead Builder": "Alec Fielding"
      },
      "content": `# Technical Architecture

Built with Azure App Service and React frontend.

## Setup Instructions
\`\`\`bash
git clone https://github.com/brookside-bi/cost-dashboard
cd cost-dashboard
npm install
npm run dev
\`\`\`
`
    }
  ]
}
```

### Update Operations

#### Update Page Properties or Content

Modify existing page properties or content through various update commands.

**Tool Name**: `notion-update-page`

**Parameters**:
- `data` (object, required):
  - `page_id` (string, required): Page ID to update
  - `command` (string, required): Update command type
  - Additional parameters based on command

**Update Commands**:

**1. Update Properties**
```typescript
{
  "data": {
    "page_id": "f336d0bc-b841-465b-8045-024475c079dd",
    "command": "update_properties",
    "properties": {
      "Status": "Active",
      "Viability": "High",
      "Impact Score": 9
    }
  }
}
```

**2. Replace Entire Content**
```typescript
{
  "data": {
    "page_id": "f336d0bc-b841-465b-8045-024475c079dd",
    "command": "replace_content",
    "new_str": "# Updated Content\n\nThis replaces all existing content."
  }
}
```

**3. Replace Content Range**
```typescript
{
  "data": {
    "page_id": "f336d0bc-b841-465b-8045-024475c079dd",
    "command": "replace_content_range",
    "selection_with_ellipsis": "## Old Section...end of section",
    "new_str": "## New Section\nUpdated content here"
  }
}
```

**4. Insert Content After**
```typescript
{
  "data": {
    "page_id": "f336d0bc-b841-465b-8045-024475c079dd",
    "command": "insert_content_after",
    "selection_with_ellipsis": "## Previous section...",
    "new_str": "\n## New Section\nInserted content"
  }
}
```

## Database Operations

### Query Database Entries

Search and filter database entries using semantic search within specific data sources.

**Tool Name**: `notion-search`

**Example: Query Ideas Registry**
```typescript
{
  "query": "Azure integration",
  "data_source_url": "collection://984a4038-3e45-4a98-8df4-fd64dd8a1032",
  "filters": {
    "created_date_range": {
      "start_date": "2025-10-01"
    }
  }
}
```

### Create Database

Create new database with schema definition.

**Tool Name**: `notion-create-database`

**Example: Create Task Database**
```typescript
{
  "parent": {
    "page_id": "parent-page-id"
  },
  "title": [
    {
      "type": "text",
      "text": {
        "content": "Tasks"
      }
    }
  ],
  "properties": {
    "Task Name": {
      "type": "title",
      "title": {}
    },
    "Status": {
      "type": "select",
      "select": {
        "options": [
          {"name": "To Do", "color": "red"},
          {"name": "In Progress", "color": "yellow"},
          {"name": "Done", "color": "green"}
        ]
      }
    },
    "Due Date": {
      "type": "date",
      "date": {}
    }
  }
}
```

### Update Database Schema

Modify database properties, add/remove columns, or rename properties.

**Tool Name**: `notion-update-database`

**Example: Add Priority Property**
```typescript
{
  "database_id": "f336d0bc-b841-465b-8045-024475c079dd",
  "properties": {
    "Priority": {
      "select": {
        "options": [
          {"name": "High", "color": "red"},
          {"name": "Medium", "color": "yellow"},
          {"name": "Low", "color": "green"}
        ]
      }
    }
  }
}
```

**Example: Rename Property**
```typescript
{
  "database_id": "f336d0bc-b841-465b-8045-024475c079dd",
  "properties": {
    "Status": {
      "name": "Project Status"
    }
  }
}
```

## Common Workflows

### Workflow 1: Create Idea with Cost Estimation

```typescript
// Step 1: Search for duplicates
{
  "query": "automated reporting dashboard",
  "data_source_url": "collection://984a4038-3e45-4a98-8df4-fd64dd8a1032"
}

// Step 2: If no duplicates, create idea
{
  "parent": {
    "data_source_id": "984a4038-3e45-4a98-8df4-fd64dd8a1032"
  },
  "pages": [
    {
      "properties": {
        "Idea Title": "Automated Reporting Dashboard",
        "Status": "Concept",
        "Viability": "Needs Research",
        "Champion": "Markus Ahling",
        "Innovation Type": "Internal Tool",
        "Effort": "L",
        "Impact Score": 8
      }
    }
  ]
}

// Step 3: Search Software Tracker for required tools
{
  "query": "Power BI",
  "data_source_url": "collection://13b5e9de-2dd1-45ec-839a-4f3d50cd8d06"
}

// Step 4: Link software to idea (via relation property update)
```

### Workflow 2: Archive Build with Knowledge Capture

```typescript
// Step 1: Fetch existing build
{
  "id": "build-page-id"
}

// Step 2: Create Knowledge Vault entry
{
  "parent": {
    "data_source_id": "knowledge-vault-data-source-id"
  },
  "pages": [
    {
      "properties": {
        "Title": "Cost Dashboard MVP - Lessons Learned",
        "Content Type": "Post-Mortem",
        "Status": "Published",
        "Evergreen/Dated": "Evergreen"
      },
      "content": `# Lessons Learned

## What Worked
- Azure App Service provided excellent scalability
- React hooks simplified state management

## Challenges
- Initial cost estimation was 30% under actual
- Authentication took longer than expected

## Recommendations
- Budget 40% buffer for Azure services
- Implement OAuth from day 1
`
    }
  ]
}

// Step 3: Update build status to Archived
{
  "data": {
    "page_id": "build-page-id",
    "command": "update_properties",
    "properties": {
      "Status": "Archived"
    }
  }
}
```

### Workflow 3: Update Research Findings

```typescript
// Step 1: Fetch current research entry
{
  "id": "research-page-id"
}

// Step 2: Insert new findings section
{
  "data": {
    "page_id": "research-page-id",
    "command": "insert_content_after",
    "selection_with_ellipsis": "## Methodology...",
    "new_str": `

## Key Findings

1. **Azure OpenAI Integration**: Feasible with existing Power BI architecture
2. **Cost Projection**: $500-800/month for moderate usage
3. **Timeline**: 2-3 months for POC implementation
`
  }
}

// Step 3: Update viability assessment
{
  "data": {
    "page_id": "research-page-id",
    "command": "update_properties",
    "properties": {
      "Viability Assessment": "Highly Viable",
      "Next Steps": "Build Example"
    }
  }
}
```

## Error Handling

### Common Errors

**1. Authentication Failure**
```
Error: Notion MCP not authenticated
```

**Solution**:
```bash
# Restart Claude Code to trigger OAuth
# Ensure browser allows popups from Claude Code
# Check workspace permissions in Notion
```

**2. Database Not Found**
```
Error: Could not find database with ID: ...
```

**Solution**:
```typescript
// Verify data source ID is correct
// Use notion-fetch to get current database schema
{
  "id": "database-url-or-id"
}
```

**3. Invalid Property Name**
```
Error: Property "Status" does not exist in database
```

**Solution**:
```typescript
// Fetch database schema first to get exact property names
{
  "id": "database-id"
}
// Use exact property names from schema
```

**4. Permission Denied**
```
Error: Insufficient permissions to create page
```

**Solution**:
- Check Notion workspace permissions
- Ensure integration has access to target database
- Verify parent page/database is shared with integration

### Error Recovery Patterns

**Retry with Exponential Backoff** (for transient errors):
```typescript
async function retryNotionOperation(operation, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      if (attempt === maxRetries) throw error;
      const delay = Math.pow(2, attempt) * 1000; // 2s, 4s, 8s
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}
```

**Circuit Breaker** (for Notion API failures):
- After 5 consecutive failures, pause operations for 5 minutes
- Test with single fetch before resuming full operations
- See [.claude/docs/patterns/circuit-breaker.md](../.claude/docs/patterns/circuit-breaker.md)

## Troubleshooting

### Issue: MCP Server Not Connected

**Symptoms**:
- `claude mcp list` shows notion as disconnected
- Commands fail with "MCP not available"

**Diagnostics**:
```bash
# Check MCP configuration
cat .claude.json | grep -A 5 "notion"

# Verify network connectivity
curl -I https://mcp.notion.com/mcp
```

**Solutions**:
1. Restart Claude Code completely
2. Clear browser cache and retry OAuth
3. Check firewall/proxy settings
4. Verify `.claude.json` configuration matches documentation

### Issue: Slow Search Performance

**Symptoms**:
- Search queries take > 10 seconds
- Timeout errors on large workspaces

**Solutions**:
- Use `data_source_url` to restrict search scope
- Add date filters to limit result set
- Search within specific pages instead of entire workspace
- Consider caching frequently accessed results

### Issue: Property Updates Not Working

**Symptoms**:
- Update succeeds but properties unchanged
- Property values revert after update

**Diagnostics**:
```typescript
// Fetch page immediately after update
{
  "id": "page-id"
}
// Compare properties with expected values
```

**Solutions**:
1. Verify property names exactly match database schema
2. Check property types (select vs. text, etc.)
3. Ensure relations reference valid page IDs
4. For date properties, use expanded format (`date:PropertyName:start`)

### Issue: Database Relations Not Linking

**Symptoms**:
- Relations created but not visible in Notion
- Rollup formulas show zero

**Solutions**:
- Verify both pages exist before creating relation
- Use exact page IDs (not URLs) for relations
- Check relation property is configured for correct database
- Ensure target database allows relations from source database

## Related Documentation

- [Notion MCP Specialist Agent](../../.claude/agents/notion-mcp-specialist.md) - Expert troubleshooting
- [Schema Manager Agent](../../.claude/agents/schema-manager.md) - Database schema modifications
- [CLAUDE.md](../../CLAUDE.md) - Complete Notion database architecture
- [Notion Markdown Specification](https://mcp.notion.com/markdown-spec) - Content formatting reference

## Support

For additional assistance:
- **Notion MCP Issues**: Contact Notion support or check MCP server status
- **Innovation Nexus Questions**: Review CLAUDE.md or engage @notion-mcp-specialist agent
- **Complex Workflows**: Use @notion-orchestrator agent for multi-step operations

---

**Best for**: Teams requiring comprehensive programmatic access to Notion workspace with automated workflows, error resilience, and cost-transparent operations that support sustainable growth.
