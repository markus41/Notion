# GitHub MCP Server - API Reference

**Author**: Claude Code Agent (Markdown Expert)
**Date**: October 21, 2025
**Version**: 1.0.0
**Status**: Production Ready

## Overview

Establish secure, scalable version control and repository management through GitHub MCP server integration. This solution is designed for organizations managing distributed codebases across teams who require automated repository operations, code search, and pull request workflows.

**Best for**: Development teams managing Example Builds, prototypes, and production repositories with centralized authentication via Azure Key Vault.

## Table of Contents

- [Authentication Setup](#authentication-setup)
- [Repository Operations](#repository-operations)
- [File Operations](#file-operations)
- [Pull Request Management](#pull-request-management)
- [Issue Tracking](#issue-tracking)
- [Branch Management](#branch-management)
- [Code Search](#code-search)
- [Common Workflows](#common-workflows)
- [Error Handling](#error-handling)
- [Troubleshooting](#troubleshooting)

## Authentication Setup

### Prerequisites

- Azure Key Vault access configured
- GitHub Personal Access Token (PAT) stored in Key Vault
- Claude Code installed with GitHub MCP server enabled

### Configuration

The GitHub MCP server is configured in `.claude.json`:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    }
  }
}
```

### Retrieve PAT from Azure Key Vault

**PowerShell Method** (Recommended):
```powershell
# Set environment variable for current session
$env:GITHUB_PERSONAL_ACCESS_TOKEN = .\scripts\Get-KeyVaultSecret.ps1 `
  -SecretName "github-personal-access-token"

# Verify token retrieved successfully
if ($env:GITHUB_PERSONAL_ACCESS_TOKEN) {
  Write-Host "✓ GitHub PAT configured"
} else {
  Write-Host "✗ Failed to retrieve GitHub PAT"
}
```

**Automated Setup** (Recommended for daily use):
```powershell
# Configure all MCP environment variables including GitHub PAT
.\scripts\Set-MCPEnvironment.ps1

# For persistent environment variables (user-level)
.\scripts\Set-MCPEnvironment.ps1 -Persistent
```

### PAT Permissions Required

Your GitHub Personal Access Token must have these scopes:

- `repo` - Full repository access (read/write)
- `workflow` - GitHub Actions workflow management
- `admin:org` - Organization administration (if managing org repositories)

### Verify Authentication

```bash
# Check MCP server status
claude mcp list

# Expected output:
# ✓ github: Connected
#   Authentication: PAT configured
#   Scopes: repo, workflow, admin:org
```

### Git Configuration

Configure Git to use your credentials:

```bash
# Set user identity
git config --global user.name "Your Name"
git config --global user.email "your.email@brooksidebi.com"

# Enable credential storage
git config --global credential.helper store

# Test authentication
git ls-remote https://github.com/brookside-bi/notion.git
```

## Repository Operations

### Create Repository

**Tool Name**: `github__create_repository`

**Parameters**:
- `name` (string, required): Repository name
- `description` (string, optional): Repository description
- `private` (boolean, optional): Private repository (default: `true`)
- `autoInit` (boolean, optional): Initialize with README (default: `false`)

**Example: Create Private Repository**
```typescript
{
  "name": "cost-dashboard-mvp",
  "description": "Azure-based cost tracking dashboard for Innovation Nexus",
  "private": true,
  "autoInit": true
}
```

**Response**:
```json
{
  "id": 123456789,
  "name": "cost-dashboard-mvp",
  "full_name": "brookside-bi/cost-dashboard-mvp",
  "html_url": "https://github.com/brookside-bi/cost-dashboard-mvp",
  "clone_url": "https://github.com/brookside-bi/cost-dashboard-mvp.git",
  "private": true,
  "created_at": "2025-10-21T12:00:00Z"
}
```

### Search Repositories

**Tool Name**: `github__search_repositories`

**Parameters**:
- `query` (string, required): Search query (GitHub search syntax)
- `page` (number, optional): Page number (default: `1`)
- `perPage` (number, optional): Results per page (default: `30`, max: `100`)

**Example: Search Organization Repositories**
```typescript
{
  "query": "org:brookside-bi language:TypeScript",
  "perPage": 50
}
```

**Example: Search by Topic**
```typescript
{
  "query": "org:brookside-bi topic:azure topic:innovation",
  "page": 1,
  "perPage": 30
}
```

**GitHub Search Syntax**:
- `org:brookside-bi` - Organization repositories
- `user:username` - User repositories
- `language:TypeScript` - Filter by language
- `topic:azure` - Filter by topic
- `stars:>10` - Repositories with more than 10 stars
- `pushed:>2025-10-01` - Recently updated repositories
- `is:public` or `is:private` - Visibility filter

### Fork Repository

**Tool Name**: `github__fork_repository`

**Parameters**:
- `owner` (string, required): Repository owner
- `repo` (string, required): Repository name
- `organization` (string, optional): Organization to fork to (defaults to personal account)

**Example: Fork to Personal Account**
```typescript
{
  "owner": "microsoft",
  "repo": "TypeScript"
}
```

**Example: Fork to Organization**
```typescript
{
  "owner": "azure",
  "repo": "azure-sdk-for-js",
  "organization": "brookside-bi"
}
```

## File Operations

### Get File Contents

**Tool Name**: `github__get_file_contents`

**Parameters**:
- `owner` (string, required): Repository owner
- `repo` (string, required): Repository name
- `path` (string, required): File or directory path
- `branch` (string, optional): Branch name (default: default branch)

**Example: Read README**
```typescript
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "path": "README.md"
}
```

**Example: Read Directory**
```typescript
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "path": "src/components"
}
```

**Response (File)**:
```json
{
  "type": "file",
  "name": "README.md",
  "path": "README.md",
  "content": "IyBDb3N0IERhc2hib2FyZCBNVlAK...",
  "encoding": "base64",
  "size": 1024,
  "sha": "abc123..."
}
```

**Response (Directory)**:
```json
{
  "type": "dir",
  "entries": [
    {
      "type": "file",
      "name": "Button.tsx",
      "path": "src/components/Button.tsx"
    },
    {
      "type": "file",
      "name": "Input.tsx",
      "path": "src/components/Input.tsx"
    }
  ]
}
```

### Create or Update File

**Tool Name**: `github__create_or_update_file`

**Parameters**:
- `owner` (string, required): Repository owner
- `repo` (string, required): Repository name
- `path` (string, required): File path to create/update
- `content` (string, required): File content (plain text, will be base64 encoded)
- `message` (string, required): Commit message
- `branch` (string, required): Target branch
- `sha` (string, optional): SHA of file being replaced (required for updates)

**Example: Create New File**
```typescript
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "path": "src/config/azure.ts",
  "content": `export const azureConfig = {
  tenantId: process.env.AZURE_TENANT_ID,
  subscriptionId: process.env.AZURE_SUBSCRIPTION_ID,
  keyVaultName: process.env.AZURE_KEYVAULT_NAME
};
`,
  "message": "feat: Add Azure configuration module for secure credential management",
  "branch": "main"
}
```

**Example: Update Existing File**
```typescript
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "path": "README.md",
  "content": "# Cost Dashboard MVP\n\nUpdated content here...",
  "message": "docs: Update README with deployment instructions",
  "branch": "main",
  "sha": "abc123def456..." // SHA from get_file_contents
}
```

### Push Multiple Files

**Tool Name**: `github__push_files`

**Parameters**:
- `owner` (string, required): Repository owner
- `repo` (string, required): Repository name
- `branch` (string, required): Target branch
- `files` (array, required): Array of file objects
  - `path` (string): File path
  - `content` (string): File content
- `message` (string, required): Commit message

**Example: Push Multiple Files**
```typescript
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "branch": "main",
  "files": [
    {
      "path": "src/App.tsx",
      "content": "import React from 'react';\n..."
    },
    {
      "path": "src/index.tsx",
      "content": "import ReactDOM from 'react-dom';\n..."
    },
    {
      "path": ".env.example",
      "content": "AZURE_TENANT_ID=\nAZURE_SUBSCRIPTION_ID=\n"
    }
  ],
  "message": "feat: Initialize React application with Azure configuration templates"
}
```

## Pull Request Management

### Create Pull Request

**Tool Name**: `github__create_pull_request`

**Parameters**:
- `owner` (string, required): Repository owner
- `repo` (string, required): Repository name
- `title` (string, required): PR title
- `head` (string, required): Branch with changes
- `base` (string, required): Branch to merge into
- `body` (string, optional): PR description
- `draft` (boolean, optional): Create as draft PR
- `maintainer_can_modify` (boolean, optional): Allow maintainer edits

**Example: Create Feature PR**
```typescript
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "title": "feat: Add cost visualization dashboard",
  "head": "feature/cost-visualization",
  "base": "main",
  "body": `## Summary
- Implement cost breakdown charts using Chart.js
- Add Azure cost API integration
- Create responsive dashboard layout

## Test Plan
- [ ] Verify chart renders correctly
- [ ] Test API integration with mock data
- [ ] Validate responsive design on mobile

🤖 Generated with [Claude Code](https://claude.com/claude-code)
`,
  "draft": false,
  "maintainer_can_modify": true
}
```

### List Pull Requests

**Tool Name**: `github__list_pull_requests`

**Parameters**:
- `owner` (string, required): Repository owner
- `repo` (string, required): Repository name
- `state` (string, optional): `"open"`, `"closed"`, or `"all"` (default: `"open"`)
- `sort` (string, optional): `"created"`, `"updated"`, `"popularity"`, `"long-running"`
- `direction` (string, optional): `"asc"` or `"desc"`
- `page` (number, optional): Page number
- `per_page` (number, optional): Results per page (max: `100`)

**Example: List Open PRs**
```typescript
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "state": "open",
  "sort": "updated",
  "direction": "desc"
}
```

### Get Pull Request Details

**Tool Name**: `github__get_pull_request`

**Parameters**:
- `owner` (string, required): Repository owner
- `repo` (string, required): Repository name
- `pull_number` (number, required): PR number

**Example**:
```typescript
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "pull_number": 42
}
```

### Merge Pull Request

**Tool Name**: `github__merge_pull_request`

**Parameters**:
- `owner` (string, required): Repository owner
- `repo` (string, required): Repository name
- `pull_number` (number, required): PR number
- `merge_method` (string, optional): `"merge"`, `"squash"`, or `"rebase"` (default: `"merge"`)
- `commit_title` (string, optional): Custom merge commit title
- `commit_message` (string, optional): Custom merge commit message

**Example: Squash and Merge**
```typescript
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "pull_number": 42,
  "merge_method": "squash",
  "commit_title": "feat: Add cost visualization dashboard",
  "commit_message": "Implements comprehensive cost breakdown charts with Azure integration"
}
```

## Issue Tracking

### Create Issue

**Tool Name**: `github__create_issue`

**Parameters**:
- `owner` (string, required): Repository owner
- `repo` (string, required): Repository name
- `title` (string, required): Issue title
- `body` (string, optional): Issue description
- `labels` (array, optional): Label names
- `assignees` (array, optional): GitHub usernames
- `milestone` (number, optional): Milestone number

**Example: Create Bug Report**
```typescript
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "title": "Cost chart not rendering in Safari browser",
  "body": `## Description
The cost breakdown chart fails to render in Safari 17+

## Steps to Reproduce
1. Open dashboard in Safari
2. Navigate to cost breakdown page
3. Chart area remains blank

## Expected Behavior
Chart renders correctly as in Chrome

## Environment
- Browser: Safari 17.2
- OS: macOS Sonoma 14.5
`,
  "labels": ["bug", "ui", "priority:high"],
  "assignees": ["alec-fielding"]
}
```

### List Issues

**Tool Name**: `github__list_issues`

**Parameters**:
- `owner` (string, required): Repository owner
- `repo` (string, required): Repository name
- `state` (string, optional): `"open"`, `"closed"`, or `"all"` (default: `"open"`)
- `labels` (array, optional): Filter by labels
- `sort` (string, optional): `"created"`, `"updated"`, `"comments"`
- `direction` (string, optional): `"asc"` or `"desc"`
- `since` (string, optional): ISO 8601 timestamp
- `page` (number, optional): Page number
- `per_page` (number, optional): Results per page

**Example: List High Priority Bugs**
```typescript
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "state": "open",
  "labels": ["bug", "priority:high"],
  "sort": "created",
  "direction": "desc"
}
```

### Update Issue

**Tool Name**: `github__update_issue`

**Parameters**:
- `owner` (string, required): Repository owner
- `repo` (string, required): Repository name
- `issue_number` (number, required): Issue number
- `title` (string, optional): New title
- `body` (string, optional): New description
- `state` (string, optional): `"open"` or `"closed"`
- `labels` (array, optional): New label set
- `assignees` (array, optional): New assignee set

**Example: Close Issue**
```typescript
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "issue_number": 23,
  "state": "closed",
  "body": "Resolved by implementing Safari-specific CSS fixes in #42"
}
```

## Branch Management

### Create Branch

**Tool Name**: `github__create_branch`

**Parameters**:
- `owner` (string, required): Repository owner
- `repo` (string, required): Repository name
- `branch` (string, required): New branch name
- `from_branch` (string, optional): Source branch (default: default branch)

**Example: Create Feature Branch**
```typescript
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "branch": "feature/authentication-integration",
  "from_branch": "main"
}
```

### List Commits

**Tool Name**: `github__list_commits`

**Parameters**:
- `owner` (string, required): Repository owner
- `repo` (string, required): Repository name
- `sha` (string, optional): Branch name or commit SHA
- `page` (number, optional): Page number
- `perPage` (number, optional): Results per page

**Example: List Recent Commits**
```typescript
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "sha": "main",
  "perPage": 10
}
```

## Code Search

### Search Code

**Tool Name**: `github__search_code`

**Parameters**:
- `q` (string, required): Search query
- `sort` (string, optional): Sort by `"indexed"` (default)
- `order` (string, optional): `"asc"` or `"desc"`
- `page` (number, optional): Page number
- `per_page` (number, optional): Results per page (max: `100`)

**Example: Search for Azure Configuration**
```typescript
{
  "q": "org:brookside-bi azureConfig extension:ts",
  "per_page": 50
}
```

**Search Query Syntax**:
- `org:brookside-bi` - Search within organization
- `repo:owner/name` - Search specific repository
- `extension:ts` - Filter by file extension
- `language:TypeScript` - Filter by programming language
- `path:src/config` - Search in specific path
- `filename:azure` - Search file names

### Search Issues and PRs

**Tool Name**: `github__search_issues`

**Parameters**:
- `q` (string, required): Search query
- `sort` (string, optional): Sort field
- `order` (string, optional): `"asc"` or `"desc"`
- `page` (number, optional): Page number
- `per_page` (number, optional): Results per page

**Example: Find Open PRs with Label**
```typescript
{
  "q": "repo:brookside-bi/cost-dashboard-mvp is:pr is:open label:feature",
  "sort": "updated",
  "order": "desc"
}
```

## Common Workflows

### Workflow 1: Create Repository for Example Build

```typescript
// Step 1: Create repository
{
  "name": "azure-openai-integration",
  "description": "POC for Azure OpenAI integration with Power BI",
  "private": true,
  "autoInit": true
}

// Step 2: Create branch for development
{
  "owner": "brookside-bi",
  "repo": "azure-openai-integration",
  "branch": "develop",
  "from_branch": "main"
}

// Step 3: Push initial files
{
  "owner": "brookside-bi",
  "repo": "azure-openai-integration",
  "branch": "develop",
  "files": [
    {
      "path": "README.md",
      "content": "# Azure OpenAI Integration\n\nPOC implementation..."
    },
    {
      "path": ".env.example",
      "content": "AZURE_OPENAI_API_KEY=\nAZURE_OPENAI_ENDPOINT=\n"
    },
    {
      "path": ".gitignore",
      "content": ".env\nnode_modules/\ndist/\n"
    }
  ],
  "message": "chore: Initialize repository structure"
}

// Step 4: Update Notion Build entry with repository URL
// (Use Notion MCP to link GitHub repo)
```

### Workflow 2: Code Review and Merge

```typescript
// Step 1: List open PRs
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "state": "open"
}

// Step 2: Get PR details
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "pull_number": 42
}

// Step 3: Get PR files
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "pull_number": 42
}

// Step 4: Add review comment
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "pull_number": 42,
  "body": "Approved with minor suggestions",
  "event": "APPROVE"
}

// Step 5: Merge PR
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "pull_number": 42,
  "merge_method": "squash"
}
```

### Workflow 3: Issue Triage

```typescript
// Step 1: List new issues
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "state": "open",
  "labels": [],
  "sort": "created",
  "since": "2025-10-20T00:00:00Z"
}

// Step 2: Update issue with labels and assignee
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "issue_number": 23,
  "labels": ["bug", "priority:high", "ui"],
  "assignees": ["alec-fielding"]
}

// Step 3: Add comment
{
  "owner": "brookside-bi",
  "repo": "cost-dashboard-mvp",
  "issue_number": 23,
  "body": "Reproduces on Safari 17.2. Investigating CSS compatibility issue."
}
```

## Error Handling

### Common Errors

**1. Authentication Failure**
```
Error: Bad credentials
```

**Solution**:
```powershell
# Verify PAT is configured
$env:GITHUB_PERSONAL_ACCESS_TOKEN

# If empty, retrieve from Key Vault
$env:GITHUB_PERSONAL_ACCESS_TOKEN = .\scripts\Get-KeyVaultSecret.ps1 `
  -SecretName "github-personal-access-token"

# Restart Claude Code
```

**2. Resource Not Found**
```
Error: Not Found (404)
```

**Solution**:
- Verify owner/repo names are correct
- Check PAT has access to repository
- Ensure repository exists and is not deleted
- Verify branch/file path exists

**3. Permission Denied**
```
Error: Resource not accessible by integration
```

**Solution**:
- Check PAT scopes include required permissions
- Verify organization membership
- Ensure repository isn't archived
- Check branch protection rules

**4. Rate Limit Exceeded**
```
Error: API rate limit exceeded
```

**Solution**:
- Wait for rate limit reset (check `X-RateLimit-Reset` header)
- Implement exponential backoff retry
- Use authenticated requests (higher rate limits)
- Consider GitHub Apps for higher limits

### Error Recovery Patterns

**Retry with Exponential Backoff**:
```typescript
async function retryGitHubOperation(operation, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      if (error.status === 403 && error.message.includes('rate limit')) {
        const resetTime = error.response?.headers?.['x-ratelimit-reset'];
        const waitTime = resetTime ? (resetTime * 1000 - Date.now()) : Math.pow(2, attempt) * 1000;
        await new Promise(resolve => setTimeout(resolve, waitTime));
      } else if (attempt === maxRetries) {
        throw error;
      } else {
        await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempt) * 1000));
      }
    }
  }
}
```

## Troubleshooting

### Issue: MCP Server Not Connected

**Diagnostics**:
```bash
# Check MCP status
claude mcp list

# Verify environment variable
echo $GITHUB_PERSONAL_ACCESS_TOKEN

# Test PAT directly
curl -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN" \
  https://api.github.com/user
```

**Solutions**:
1. Run `.\scripts\Set-MCPEnvironment.ps1`
2. Restart Claude Code
3. Verify PAT not expired in GitHub settings
4. Check `.claude.json` configuration

### Issue: Push Failed

**Symptoms**:
- `push_files` succeeds but changes not visible
- Commit appears in wrong branch
- Conflicts reported

**Solutions**:
- Verify branch name is correct
- Check for branch protection rules
- Pull latest changes before push
- Resolve merge conflicts locally first

### Issue: Search Returns No Results

**Symptoms**:
- Known code not found in search
- Empty result set

**Solutions**:
- Check GitHub search index delay (up to 5 minutes)
- Verify repository is indexed (not private without access)
- Use more specific search terms
- Try repository-specific search instead of organization-wide

## Related Documentation

- [GitHub MCP Integration](../GITHUB_MCP_INTEGRATION.md) - Detailed setup guide
- [Integration Specialist Agent](../../.claude/agents/integration-specialist.md) - GitHub workflow automation
- [Build Architect Agent](../../.claude/agents/build-architect.md) - Repository creation workflows
- [Azure Key Vault Setup](../../CLAUDE.md#azure-key-vault---centralized-secret-management) - PAT storage

## Support

For additional assistance:
- **GitHub API Issues**: Check [GitHub Status](https://www.githubstatus.com/)
- **PAT Problems**: Review GitHub PAT settings and regenerate if needed
- **MCP Configuration**: Engage @integration-specialist agent

---

**Best for**: Development teams requiring secure, automated GitHub operations with centralized credential management, comprehensive error handling, and seamless integration with Innovation Nexus workflows.
