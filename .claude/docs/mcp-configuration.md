# MCP Server Configuration

**Purpose**: Establish comprehensive MCP (Model Context Protocol) server setup for Innovation Nexus integrations.

**Best for**: Agents requiring MCP connectivity, troubleshooting integration issues, or understanding available server capabilities.

---

## Active MCP Servers

| Server | Purpose | Authentication | Status |
|--------|---------|---------------|--------|
| **Notion** | Innovation tracking, database operations | OAuth (auto-configured) | ✓ Connected |
| **GitHub** | Repository operations, CI/CD | PAT from Key Vault | ✓ Connected |
| **Azure** | Cloud resource management, deployments | Azure CLI (`az login`) | ✓ Connected |
| **Playwright** | Browser automation, web testing | Local executable | ✓ Connected |
| **Azure APIM** | API gateway with MCP export for tool invocation | Subscription Key | ⏸️ Provisioning |

**Verify Connection**: `claude mcp list` (all should show ✓ Connected)

**Configuration Details**: See [Azure APIM MCP Configuration](azure-apim-mcp-configuration.md) for APIM-specific setup

---

## Notion MCP Server

### Capabilities
- **Search**: Semantic search across workspace and connected sources (Slack, Google Drive, GitHub, etc.)
- **Fetch**: Retrieve page/database content in enhanced Markdown format
- **Create**: Create pages with properties and rich content
- **Update**: Modify page properties and content (replace, insert, append)
- **Databases**: Create/update database schemas, query data
- **Comments**: Add comments to pages
- **Move**: Relocate pages to different parents
- **Duplicate**: Copy pages with all content

### Authentication
**Method**: OAuth (interactive browser authentication)

**Setup**:
```bash
# First-time setup (one-time)
claude mcp add notion

# Follow browser prompts to authenticate
# Grants access to workspace: 81686779-099a-8195-b49e-00037e25c23e
```

**Verification**:
```bash
claude mcp list
# Should show: ✓ Notion (Connected)
```

### Key Operations

#### Search for Content
```typescript
// Semantic search across entire workspace
mcp__notion__notion-search({
  query: "AI cost optimization",
  query_type: "internal"
})

// Search within specific database
mcp__notion__notion-search({
  query: "high viability ideas",
  data_source_url: "collection://984a4038-3e45-4a98-8df4-fd64dd8a1032"
})

// Search with filters
mcp__notion__notion-search({
  query: "completed builds",
  query_type: "internal",
  filters: {
    created_date_range: {
      start_date: "2025-01-01",
      end_date: "2025-10-26"
    },
    created_by_user_ids: ["user-id-here"]
  }
})
```

#### Fetch Page/Database
```typescript
// Fetch page by URL or ID
mcp__notion__notion-fetch({
  id: "https://notion.so/workspace/Page-a1b2c3d4e5f67890"
})

// Fetch database (returns all data sources)
mcp__notion__notion-fetch({
  id: "984a4038-3e45-4a98-8df4-fd64dd8a1032"
})
```

#### Create Page
```typescript
// Create page in database
mcp__notion__notion-create-pages({
  parent: { data_source_id: "984a4038-3e45-4a98-8df4-fd64dd8a1032" },
  pages: [{
    properties: {
      "Idea Name": "AI-powered cost optimization",
      "Status": "Concept",
      "Viability": "Needs Research"
    },
    content: "# Overview\n\nThis idea focuses on..."
  }]
})
```

#### Update Page
```typescript
// Update properties
mcp__notion__notion-update-page({
  page_id: "page-id-here",
  command: "update_properties",
  properties: {
    "Status": "Active",
    "Viability": "High"
  }
})

// Replace content
mcp__notion__notion-update-page({
  page_id: "page-id-here",
  command: "replace_content",
  new_str: "# New Content\n\nUpdated documentation..."
})
```

### Performance Optimization

**Cache Database Schemas**:
```typescript
// ✅ Correct - fetch schema once, reuse
const ideasSchema = await fetchDatabase("984a4038...");
// Use schema for multiple operations

// ❌ Wrong - fetch schema repeatedly
for (const idea of ideas) {
  const schema = await fetchDatabase("984a4038..."); // Wasteful
}
```

**Batch Search Results**:
```typescript
// ✅ Correct - single search with broad query
const results = await notionSearch({ query: "cost optimization" });
// Filter results in code

// ❌ Wrong - multiple narrow searches
const results1 = await notionSearch({ query: "Azure cost" });
const results2 = await notionSearch({ query: "cost optimization" });
const results3 = await notionSearch({ query: "spend analysis" });
```

**Reuse Relation IDs**:
```typescript
// ✅ Correct - search once, cache IDs
const azureOpenAI = await searchSoftware("Azure OpenAI");
const azureOpenAIId = azureOpenAI.id;
// Use azureOpenAIId in multiple create operations

// ❌ Wrong - search every time
for (const build of builds) {
  const software = await searchSoftware("Azure OpenAI"); // Wasteful
}
```

---

## GitHub MCP Server

### Capabilities
- **Repositories**: Create, search, fork repositories
- **Files**: Read, create, update, push files
- **Issues**: Create, list, update issues and comments
- **Pull Requests**: Create, list, review, merge PRs
- **Branches**: Create branches, manage branch protection
- **Commits**: List commits, get commit details

### Authentication
**Method**: Personal Access Token (PAT) from Azure Key Vault

**Setup**:
```bash
# First-time setup
claude mcp add github

# Configure token from Key Vault
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token" -AsPlainText

# Set environment variable
$env:GITHUB_PERSONAL_ACCESS_TOKEN = "<token-value>"
```

**Required Scopes**:
- `repo` (full control of repositories)
- `workflow` (update GitHub Actions workflows)
- `admin:org` (read org data for multi-repo operations)

**Verification**:
```bash
claude mcp list
# Should show: ✓ GitHub (Connected)

# Test with query
gh auth status
```

### Key Operations

#### Create Repository
```typescript
mcp__github__create_repository({
  name: "ai-cost-optimizer",
  description: "AI-powered Azure cost optimization platform",
  private: false,
  autoInit: true  // Creates with README
})
```

#### Push Files (Single Commit)
```typescript
mcp__github__push_files({
  owner: "brookside-bi",
  repo: "ai-cost-optimizer",
  branch: "main",
  files: [
    { path: "README.md", content: "# AI Cost Optimizer\n..." },
    { path: "src/main.py", content: "#!/usr/bin/env python3\n..." },
    { path: ".gitignore", content: "*.pyc\n__pycache__/\n..." }
  ],
  message: "feat: Initial commit with project structure\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)"
})
```

#### Create Pull Request
```typescript
mcp__github__create_pull_request({
  owner: "brookside-bi",
  repo: "ai-cost-optimizer",
  title: "feat: Add cost analysis dashboard",
  head: "feature/cost-dashboard",
  base: "main",
  body: `## Summary
- Implemented real-time cost visualization
- Added Azure Resource Manager integration
- Created interactive filtering

## Test Plan
- [ ] Verify dashboard loads with sample data
- [ ] Test filters and date range selection
- [ ] Validate Azure authentication

🤖 Generated with [Claude Code](https://claude.com/claude-code)`
})
```

#### Search Repositories
```typescript
mcp__github__search_repositories({
  query: "org:brookside-bi language:python topic:azure",
  page: 1,
  perPage: 30
})
```

### Performance Optimization

**Batch File Operations**:
```typescript
// ✅ Correct - single commit with multiple files
await pushFiles({
  files: [
    { path: "file1.py", content: "..." },
    { path: "file2.py", content: "..." },
    { path: "file3.py", content: "..." }
  ]
});

// ❌ Wrong - multiple commits
await createOrUpdateFile({ path: "file1.py", content: "..." });
await createOrUpdateFile({ path: "file2.py", content: "..." });
await createOrUpdateFile({ path: "file3.py", content: "..." });
```

---

## Azure MCP Server

### Capabilities
- **Subscriptions & Resource Groups**: List subscriptions, resource groups
- **Documentation Search**: Search official Microsoft/Azure docs
- **AKS Operations**: Manage Kubernetes clusters
- **App Services**: Manage web apps, function apps
- **Databases**: SQL, Cosmos DB, PostgreSQL, MySQL operations
- **Storage**: Blob storage operations
- **Monitoring**: Query Azure Monitor logs and metrics
- **Key Vault**: Secret management (read operations)
- **Cost Management**: Query spending and usage data

### Authentication
**Method**: Azure CLI authentication (`az login`)

**Setup**:
```powershell
# Authenticate to Azure
az login

# Set subscription
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"

# Verify
az account show
```

**Verification**:
```bash
claude mcp list
# Should show: ✓ Azure (Connected)

# Test with query
az account show
```

### Key Operations

#### Search Azure Documentation
```typescript
mcp__azure__documentation({
  intent: "search",
  parameters: {
    query: "Azure Functions Python best practices",
    maxResults: 10
  }
})
```

#### List Resource Groups
```typescript
mcp__azure__group_list({
  subscription: "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
})
```

#### Query Azure Monitor Logs
```typescript
mcp__azure__monitor({
  intent: "query logs",
  parameters: {
    query: "AppRequests | where TimeGenerated > ago(1h) | summarize count() by bin(TimeGenerated, 5m)",
    workspace: "log-analytics-workspace-id",
    timeRange: "PT1H"
  }
})
```

#### Get Best Practices
```typescript
mcp__azure__get_bestpractices({
  intent: "get best practices",
  parameters: {
    resource: "azure-functions",
    action: "deployment"
  }
})
```

### Performance Optimization

**Reuse Authentication**:
```typescript
// ✅ Correct - authenticate once per session
az login  // Run once at start of day
// All Azure MCP operations use same auth

// ❌ Wrong - don't re-authenticate repeatedly
// Azure CLI tokens last 24 hours
```

**Cache Resource Lists**:
```typescript
// ✅ Correct - list once, filter in code
const allResources = await listResources();
const webApps = allResources.filter(r => r.type === 'Microsoft.Web/sites');

// ❌ Wrong - multiple specific queries
const webApps = await listWebApps();
const functionApps = await listFunctionApps();
```

---

## Playwright MCP Server

### Capabilities
- **Browser Automation**: Navigate, click, type, fill forms
- **Testing**: Screenshots, snapshots, console logs, network requests
- **Interaction**: Handle dialogs, file uploads, keyboard/mouse events
- **Evaluation**: Execute JavaScript in browser context

### Authentication
**Method**: Local executable (no credentials required)

**Setup**:
```bash
# First-time setup
claude mcp add playwright

# Install browsers
playwright install
```

**Verification**:
```bash
claude mcp list
# Should show: ✓ Playwright (Connected)
```

### Key Operations

#### Navigate and Capture
```typescript
// Navigate to URL
mcp__playwright__browser_navigate({
  url: "https://azure.microsoft.com"
})

// Take screenshot
mcp__playwright__browser_take_screenshot({
  filename: "azure-homepage.png",
  fullPage: true
})

// Get page snapshot (better than screenshot for actions)
mcp__playwright__browser_snapshot()
```

#### Interact with Elements
```typescript
// Click element
mcp__playwright__browser_click({
  element: "Sign in button",
  ref: "button[data-bi-name='signin']"
})

// Type text
mcp__playwright__browser_type({
  element: "Email input",
  ref: "input[type='email']",
  text: "user@example.com",
  submit: false
})

// Fill form
mcp__playwright__browser_fill_form({
  fields: [
    { name: "Email", type: "textbox", ref: "input[name='email']", value: "user@example.com" },
    { name: "Password", type: "textbox", ref: "input[name='password']", value: "password123" },
    { name: "Remember me", type: "checkbox", ref: "input[name='remember']", value: "true" }
  ]
})
```

#### Get Console Logs
```typescript
mcp__playwright__browser_console_messages({
  onlyErrors: true  // Filter to errors only
})
```

### Performance Optimization

**Reuse Browser Sessions**:
```typescript
// ✅ Correct - navigate once, interact multiple times
await navigate({ url: "https://example.com" });
await click({ element: "Link 1" });
await click({ element: "Link 2" });
await takeScreenshot();
await close();

// ❌ Wrong - open/close browser repeatedly
await navigate({ url: "https://example.com" });
await close();
await navigate({ url: "https://example.com" });  // Reopens browser
```

---

## Environment Setup (Daily Workflow)

### Complete Setup Sequence

```powershell
# 1. Authenticate to Azure (tokens expire after 24 hours)
az login
az account show  # Verify: cfacbbe8-a2a3-445f-a188-68b3b35f0c84

# 2. Configure MCP environment variables
.\scripts\Set-MCPEnvironment.ps1

# 3. Verify all MCP servers
.\scripts\Test-AzureMCP.ps1
claude mcp list

# 4. Launch Claude Code
claude
```

**Frequency**: Daily (or after system restart)

---

## Troubleshooting

### Issue: "MCP server not responding"
**Possible Causes**:
1. Server not authenticated
2. Network connectivity issues
3. Environment variables not set
4. Server process crashed

**Solutions**:
```bash
# 1. Check server status
claude mcp list

# 2. Restart specific server
claude mcp restart [server-name]

# 3. Re-authenticate
az login  # For Azure
.\scripts\Set-MCPEnvironment.ps1  # For GitHub/Notion

# 4. Test connectivity
.\scripts\Test-AzureMCP.ps1
```

### Issue: "Permission denied" or "Unauthorized"
**Possible Causes**:
1. Invalid or expired credentials
2. Insufficient permissions
3. Wrong subscription/workspace

**Solutions**:
```bash
# Azure: Verify subscription
az account show

# GitHub: Check token scopes
gh auth status

# Notion: Re-authenticate
claude mcp remove notion
claude mcp add notion
```

### Issue: "Rate limit exceeded"
**Possible Causes**:
1. Too many API requests in short time
2. Inefficient query patterns

**Solutions**:
- **Notion**: Cache database schemas, batch operations
- **GitHub**: Use push_files instead of multiple create_or_update_file calls
- **Azure**: Cache resource lists, filter locally
- **Implement retry with exponential backoff**

---

## MCP Server Health Monitoring

### Check All Servers
```powershell
# Use dedicated health check script
.\scripts\Test-AzureMCP.ps1

# Or manually check each
claude mcp list
az account show
gh auth status
```

### Expected Output (Healthy State)
```
MCP Server Health Check
=======================
✓ Azure CLI authenticated (cfacbbe8-a2a3-445f-a188-68b3b35f0c84)
✓ GitHub authenticated (brookside-bi)
✓ Notion connected (81686779-099a-8195-b49e-00037e25c23e)
✓ Playwright installed (browsers ready)

Environment Variables:
✓ GITHUB_PERSONAL_ACCESS_TOKEN
✓ NOTION_API_KEY
✓ AZURE_OPENAI_API_KEY
✓ AZURE_OPENAI_ENDPOINT

All systems operational.
```

---

## Related Resources

**Scripts**:
- [Set-MCPEnvironment.ps1](../scripts/Set-MCPEnvironment.ps1)
- [Test-AzureMCP.ps1](../scripts/Test-AzureMCP.ps1)
- [Get-KeyVaultSecret.ps1](../scripts/Get-KeyVaultSecret.ps1)

**Documentation**:
- [Azure Infrastructure](./azure-infrastructure.md)
- [Configuration & Environment](./configuration.md)
- [Agent Guidelines](./agent-guidelines.md)

**External**:
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Notion API Documentation](https://developers.notion.com/)
- [GitHub API Documentation](https://docs.github.com/en/rest)
- [Azure CLI Documentation](https://learn.microsoft.com/en-us/cli/azure/)

---

**Last Updated**: 2025-10-26
