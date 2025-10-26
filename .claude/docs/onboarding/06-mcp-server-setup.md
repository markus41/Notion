# MCP Server Configuration

**Brookside BI Innovation Nexus MCP Integration** - Establish seamless connectivity between Claude Code and external systems through Model Context Protocol servers, enabling autonomous operations across Notion databases, GitHub repositories, Azure infrastructure, and browser automation.

**Best for**: New team members requiring comprehensive understanding of MCP architecture, daily authentication workflows, and troubleshooting strategies to maintain reliable integration across all Innovation Nexus automation.

---

## Overview

### What is MCP (Model Context Protocol)?

**Model Context Protocol (MCP)** is an open standard that enables AI assistants like Claude Code to securely interact with external systems through standardized server implementations. MCP servers act as bridges between Claude's reasoning capabilities and real-world data sources and tools.

**Key Benefits**:
- **Unified Interface**: Single protocol for diverse integrations (databases, APIs, file systems)
- **Security**: Credential isolation, permission-based access, audit logging
- **Extensibility**: Custom MCP servers for proprietary systems
- **Real-Time Data**: Direct access to live data without manual copy/paste
- **Autonomous Workflows**: Claude can execute multi-step operations across systems

### Innovation Nexus MCP Architecture

```mermaid
graph TB
    subgraph "Claude Code Agent"
        CLAUDE[Claude Sonnet 4.5]
        MCP_CLIENT[MCP Client]
    end

    subgraph "MCP Servers (Local Process)"
        MCP_NOTION[Notion MCP Server]
        MCP_GITHUB[GitHub MCP Server]
        MCP_AZURE[Azure MCP Server]
        MCP_PLAYWRIGHT[Playwright MCP Server]
    end

    subgraph "External Systems"
        NOTION_API[Notion API]
        GITHUB_API[GitHub REST/GraphQL API]
        AZURE_ARM[Azure Resource Manager]
        BROWSER[Chromium Browser]
    end

    subgraph "Authentication Layer"
        KV[Azure Key Vault]
        ENV[Environment Variables]
        AZCLI[Azure CLI Token Cache]
    end

    CLAUDE -->|Tool Calls| MCP_CLIENT
    MCP_CLIENT -->|JSON-RPC| MCP_NOTION
    MCP_CLIENT -->|JSON-RPC| MCP_GITHUB
    MCP_CLIENT -->|JSON-RPC| MCP_AZURE
    MCP_CLIENT -->|JSON-RPC| MCP_PLAYWRIGHT

    MCP_NOTION -->|HTTPS + Bearer Token| NOTION_API
    MCP_GITHUB -->|HTTPS + PAT| GITHUB_API
    MCP_AZURE -->|HTTPS + OAuth| AZURE_ARM
    MCP_PLAYWRIGHT -->|CDP Protocol| BROWSER

    ENV -->|Credentials| MCP_NOTION
    ENV -->|Credentials| MCP_GITHUB
    AZCLI -->|Token| MCP_AZURE

    KV -.->|Populate| ENV

    style CLAUDE fill:#0078d4,color:#fff
    style MCP_CLIENT fill:#50e6ff,color:#000
    style KV fill:#d13438,color:#fff
```

**Communication Flow**:
1. Claude reasons about task requiring external data (e.g., "Create Notion page")
2. Claude invokes MCP tool via JSON-RPC: `mcp__notion__notion-create-pages`
3. MCP Client routes request to Notion MCP Server
4. Notion MCP Server authenticates via environment variable `NOTION_API_KEY`
5. Server makes HTTPS call to Notion API with bearer token
6. Notion API returns data, MCP Server formats response
7. Claude receives structured data and continues reasoning

---

## Active MCP Servers

### 1. Notion MCP Server

**Purpose**: Bidirectional integration with Notion workspace for Innovation Nexus database operations (Ideas, Research, Builds, Cost Tracking, Agent Activity).

**Status**: Production (OAuth-authenticated)

**Connection Details**:
```yaml
Server Name: notion
Protocol: MCP v1.0
Authentication: OAuth 2.0 (auto-configured)
Workspace ID: 81686779-099a-8195-b49e-00037e25c23e
Permissions:
  - Read content
  - Update content
  - Insert content
  - Create databases
  - Search
Rate Limits: 3 requests/second (Notion API limit)
```

**Available Operations** (58 total tools):

| Category | Tool Examples | Use Cases |
|----------|---------------|-----------|
| **Search** | `notion-search`, `notion-fetch` | Find existing ideas/research/builds before creating duplicates |
| **Page Operations** | `notion-create-pages`, `notion-update-page`, `notion-move-pages` | Create Ideas Registry entries, update build status |
| **Database Operations** | `notion-create-database`, `notion-update-database` | Initialize new tracking databases |
| **Comments** | `notion-create-comment`, `notion-get-comments` | Add collaboration notes to research entries |
| **Users/Teams** | `notion-get-users`, `notion-get-teams` | Lookup team member IDs for assignment |

**Authentication Setup**:
```bash
# Notion uses OAuth - no environment variables needed
# Authentication is handled via Claude Code's MCP configuration
claude mcp list
# Expected Output: ✓ notion (Connected via OAuth)
```

**Configuration File**: `C:/Users/MarkusAhling/.claude/mcp.json` (auto-managed)

**Test Connection**:
```bash
# Inside Claude Code session
Task "Search Notion for 'AI Cost Optimization' in Ideas Registry"

# Expected: Returns matching Ideas Registry entries with page IDs and properties
```

### 2. GitHub MCP Server

**Purpose**: Repository operations including file management, branch creation, pull requests, issues, and CI/CD workflow triggering for autonomous build deployments.

**Status**: Production (PAT-authenticated)

**Connection Details**:
```yaml
Server Name: github
Protocol: MCP v1.0
Authentication: Personal Access Token (PAT)
Organization: brookside-bi
Permissions (PAT):
  - repo (full control of private repositories)
  - workflow (update GitHub Actions workflows)
  - admin:org (read organization data)
  - write:packages (publish to GitHub Packages)
Rate Limits: 5000 requests/hour (GitHub API limit)
```

**Available Operations** (32 total tools):

| Category | Tool Examples | Use Cases |
|----------|---------------|-----------|
| **Repository** | `create_repository`, `fork_repository`, `search_repositories` | Initialize autonomous build repos |
| **Files** | `create_or_update_file`, `push_files`, `get_file_contents` | Deploy code to GitHub |
| **Branches** | `create_branch`, `list_commits` | Feature branch creation for builds |
| **Pull Requests** | `create_pull_request`, `merge_pull_request`, `get_pull_request_status` | Automated PR workflows |
| **Issues** | `create_issue`, `list_issues`, `add_issue_comment` | Bug tracking, feature requests |

**Authentication Setup**:
```powershell
# Method 1: Retrieve from Key Vault (recommended)
.\scripts\Set-MCPEnvironment.ps1

# Method 2: Manual retrieval
$env:GITHUB_PERSONAL_ACCESS_TOKEN = (.\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token")

# Verify environment variable set
$env:GITHUB_PERSONAL_ACCESS_TOKEN
# Expected Output: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Configuration File**: `C:/Users/MarkusAhling/.claude/mcp.json`
```json
{
  "mcpServers": {
    "github": {
      "command": "mcp-server-github",
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    }
  }
}
```

**Test Connection**:
```bash
# Inside Claude Code session
Task "List repositories in brookside-bi organization"

# Expected: Returns list of repositories with names, URLs, visibility
```

### 3. Azure MCP Server

**Purpose**: Cloud infrastructure management including resource provisioning, Key Vault secret retrieval, deployment execution, and cost analysis for autonomous build deployments.

**Status**: Production (Azure CLI token-authenticated)

**Connection Details**:
```yaml
Server Name: azure
Protocol: MCP v1.0
Authentication: Azure CLI (interactive login)
Subscription ID: cfacbbe8-a2a3-445f-a188-68b3b35f0c84
Tenant ID: 2930489e-9d8a-456b-9de9-e4787faeab9c
Token Lifetime: 1 hour (auto-refresh via Azure CLI)
Permissions: Inherited from user's Azure AD roles
Rate Limits: Varies by Azure service (typically 12,000/hour for ARM)
```

**Available Operations** (120+ total tools across 35 service categories):

| Category | Tool Examples | Use Cases |
|----------|---------------|-----------|
| **Resource Groups** | `group_list`, `subscription_list` | Discover deployment targets |
| **App Services** | `appservice` (create, list, configure) | Deploy web applications |
| **Functions** | `functionapp` (create, deploy, logs) | Deploy serverless builds |
| **Key Vault** | `keyvault` (get secrets, list vaults) | Retrieve credentials for MCP servers |
| **Databases** | `cosmos`, `sql`, `postgres`, `mysql` | Provision data layers |
| **Monitoring** | `monitor` (logs, metrics, alerts) | Application Insights queries |
| **Cost** | `quota` (usage, regions, limits) | Cost analysis and optimization |

**Authentication Setup**:
```bash
# Required daily (1-hour token expiration)
az login

# Verify authentication
az account show
# Expected Output:
# {
#   "id": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84",
#   "name": "Brookside BI Production",
#   "state": "Enabled",
#   "isDefault": true
# }
```

**Configuration File**: `C:/Users/MarkusAhling/.claude/mcp.json`
```json
{
  "mcpServers": {
    "azure": {
      "command": "mcp-server-azure",
      "args": ["--subscription-id", "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"]
    }
  }
}
```

**Test Connection**:
```bash
# Inside Claude Code session
Task "List Azure resource groups in subscription"

# Expected: Returns rg-brookside-shared, rg-brookside-dev, rg-brookside-staging, rg-brookside-prod
```

### 4. Playwright MCP Server

**Purpose**: Browser automation for web scraping, UI testing, screenshot capture, and interaction with web-based admin interfaces during research and build validation.

**Status**: Production (local process, no authentication)

**Connection Details**:
```yaml
Server Name: playwright
Protocol: MCP v1.0
Authentication: None (local Chromium process)
Browser: Chromium (headless by default)
Network: Direct internet access (respects system proxy)
Permissions: Filesystem read/write for screenshots
```

**Available Operations** (22 total tools):

| Category | Tool Examples | Use Cases |
|----------|---------------|-----------|
| **Navigation** | `browser_navigate`, `browser_navigate_back` | Load web pages for research |
| **Interaction** | `browser_click`, `browser_type`, `browser_fill_form` | Automate web forms |
| **Data Extraction** | `browser_snapshot`, `browser_take_screenshot` | Capture competitive research |
| **Testing** | `browser_evaluate`, `browser_wait_for` | Validate deployed builds |
| **Network** | `browser_network_requests`, `browser_console_messages` | Debug web applications |

**Authentication Setup**:
```bash
# No environment variables needed
# Ensure Playwright browsers installed:
npx playwright install chromium

# Verify installation
npx playwright --version
# Expected Output: Version 1.40.0 or later
```

**Configuration File**: `C:/Users/MarkusAhling/.claude/mcp.json`
```json
{
  "mcpServers": {
    "playwright": {
      "command": "mcp-server-playwright",
      "args": ["--headless"]
    }
  }
}
```

**Test Connection**:
```bash
# Inside Claude Code session
Task "Navigate to https://www.brooksidebi.com and take screenshot"

# Expected: Returns screenshot file path, page title
```

---

## Daily Authentication Workflow

### Morning Setup (5 minutes)

**Goal**: Establish authenticated MCP connectivity for full-day Innovation Nexus operations

**Step-by-Step**:

```powershell
# Terminal 1: PowerShell (run as Administrator recommended)

# Step 1: Authenticate to Azure (required daily)
az login
# Opens browser window for interactive login
# Select your Brookside BI account: your-email@brooksidebi.com
# Close browser after "You have logged in to Microsoft Azure!"

# Step 2: Verify Azure subscription
az account show
# Confirm output shows:
#   "id": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
#   "name": "Brookside BI Production"

# Step 3: Configure MCP environment variables from Key Vault
.\scripts\Set-MCPEnvironment.ps1

# Output should show:
# ✓ Retrieved github-personal-access-token
# ✓ Retrieved notion-api-key
# ✓ Retrieved azure-openai-api-key
# ✓ Retrieved azure-openai-endpoint
# ✓ Set GITHUB_PERSONAL_ACCESS_TOKEN
# ✓ Set NOTION_API_KEY
# ✓ Set AZURE_OPENAI_API_KEY
# ✓ Set AZURE_OPENAI_ENDPOINT
# MCP environment configured successfully!

# Step 4: Launch Claude Code
claude

# Wait for initialization (15-30 seconds)
```

### MCP Connection Verification

**Inside Claude Code session**:
```bash
# Command 1: List all MCP servers
claude mcp list

# Expected Output:
✓ notion      (Connected via OAuth)
✓ github      (Connected via PAT)
✓ azure       (Connected via Azure CLI)
✓ playwright  (Connected - Local)

# Command 2: Test each server individually
Task "Test Notion MCP: Search for 'Cost Optimization' in Ideas Registry"
Task "Test GitHub MCP: List repositories in brookside-bi organization"
Task "Test Azure MCP: List resource groups"
Task "Test Playwright MCP: Navigate to https://example.com and get page title"
```

**Success Criteria**:
- All 4 servers show ✓ Connected
- Search/list operations return valid data
- No authentication errors in Claude Code logs

**If ANY server shows ✗ Disconnected**, proceed to [Troubleshooting](#common-issues-and-troubleshooting).

---

## Environment Variables Reference

### Complete List

| Variable Name | Source | Required By | Example Value | Security Level |
|---------------|--------|-------------|---------------|----------------|
| `GITHUB_PERSONAL_ACCESS_TOKEN` | Key Vault | GitHub MCP | `ghp_abc123...` | Secret (never log) |
| `NOTION_API_KEY` | Key Vault | Notion MCP | `secret_xyz789...` | Secret (never log) |
| `AZURE_OPENAI_API_KEY` | Key Vault | Build deployments | `sk-abc...` | Secret (never log) |
| `AZURE_OPENAI_ENDPOINT` | Key Vault | Build deployments | `https://brookside-openai.openai.azure.com/` | Public (safe to log) |
| `AZURE_SUBSCRIPTION_ID` | Manual | Azure MCP (fallback) | `cfacbbe8-a2a3-...` | Public (safe to log) |
| `AZURE_TENANT_ID` | Manual | Azure MCP (fallback) | `2930489e-9d8a-...` | Public (safe to log) |
| `NOTION_WORKSPACE_ID` | Manual | Notion queries | `81686779-099a-...` | Public (safe to log) |
| `GITHUB_ORG` | Manual | GitHub queries | `brookside-bi` | Public (safe to log) |

### Persistent vs Session Variables

**Session Variables** (default behavior of `Set-MCPEnvironment.ps1`):
- Valid for current PowerShell session only
- Cleared when terminal closes
- **Best for**: Daily work, developer workstations
- **Security**: Higher (credentials not persisted to disk)

**Persistent Variables** (optional `-Persistent` flag):
- Stored in Windows Environment Variables (User scope)
- Valid across terminal sessions and reboots
- **Best for**: Dedicated build servers, CI/CD agents
- **Security**: Lower (credentials persisted in registry)

**Recommendation**: Use session variables on developer workstations, persistent on automated systems only.

### Setting Variables Manually

**PowerShell**:
```powershell
# Session variable (preferred)
$env:GITHUB_PERSONAL_ACCESS_TOKEN = "ghp_abc123..."

# Persistent variable (use cautiously)
[System.Environment]::SetEnvironmentVariable("GITHUB_PERSONAL_ACCESS_TOKEN", "ghp_abc123...", "User")
```

**Bash/Linux**:
```bash
# Session variable
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_abc123..."

# Persistent variable (add to ~/.bashrc or ~/.zshrc)
echo 'export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_abc123..."' >> ~/.bashrc
source ~/.bashrc
```

### Security Best Practices

**✅ DO**:
- Use `Set-MCPEnvironment.ps1` to retrieve secrets from Key Vault
- Use session variables on developer workstations
- Clear variables when switching contexts: `$env:GITHUB_PERSONAL_ACCESS_TOKEN = $null`
- Verify variables are set before launching Claude Code: `$env:GITHUB_PERSONAL_ACCESS_TOKEN`

**❌ NEVER**:
- Hardcode secrets in scripts: `$env:TOKEN = "ghp_abc123..."`
- Echo secret values to console: `Write-Host $env:GITHUB_PERSONAL_ACCESS_TOKEN`
- Commit `.env` files with real values to Git
- Share environment variables via Slack/email

---

## MCP Configuration Files

### Location

**Primary Configuration**: `C:/Users/MarkusAhling/.claude/mcp.json`

**Purpose**: Defines MCP server connection parameters, authentication methods, and startup arguments for Claude Code.

### Structure

```json
{
  "mcpServers": {
    "notion": {
      "command": "npx",
      "args": [
        "-y",
        "@anthropic/mcp-server-notion"
      ],
      "env": {
        "NOTION_API_KEY": "${NOTION_API_KEY}"
      }
    },
    "github": {
      "command": "npx",
      "args": [
        "-y",
        "@anthropic/mcp-server-github"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    },
    "azure": {
      "command": "npx",
      "args": [
        "-y",
        "@anthropic/mcp-server-azure",
        "--subscription-id",
        "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
      ]
    },
    "playwright": {
      "command": "npx",
      "args": [
        "-y",
        "@anthropic/mcp-server-playwright",
        "--headless"
      ]
    }
  }
}
```

**Key Components**:
- `command`: Executable to launch MCP server (usually `npx` for Node.js packages)
- `args`: Command-line arguments (package name, server-specific flags)
- `env`: Environment variables passed to server process (credentials via `${VAR_NAME}` substitution)

### Editing Configuration

**When to Edit**:
- Adding new MCP server (e.g., custom Salesforce integration)
- Changing Azure subscription ID
- Enabling debug logging: `"args": ["--verbose"]`
- Switching Playwright to headed mode: `"args": ["--headless", "false"]`

**How to Edit**:
```powershell
# 1. Close Claude Code (if running)
# 2. Open configuration in text editor
code C:/Users/MarkusAhling/.claude/mcp.json

# 3. Make changes (validate JSON syntax)
# 4. Save file
# 5. Relaunch Claude Code
claude
```

**Validation**:
```bash
# Inside Claude Code session
claude mcp list
# Verify all servers reconnect successfully
```

### Backup and Versioning

**Recommended**: Version control `mcp.json` in private repository (with sanitized credentials)

```bash
# Create backup before editing
cp C:/Users/MarkusAhling/.claude/mcp.json C:/Users/MarkusAhling/.claude/mcp.json.backup

# Restore from backup if needed
cp C:/Users/MarkusAhling/.claude/mcp.json.backup C:/Users/MarkusAhling/.claude/mcp.json
```

---

## Connection Verification and Health Checks

### Real-Time Status Monitoring

**PowerShell Health Check Script**: `C:/Users/MarkusAhling/Notion/.claude/utils/mcp-health.ps1`

```powershell
# Run comprehensive MCP health check
.\\.claude\utils\mcp-health.ps1

# Expected Output:
=== MCP Server Health Check ===
Date: 2025-10-26 10:30:15

Environment Variables:
  ✓ GITHUB_PERSONAL_ACCESS_TOKEN is set (length: 40)
  ✓ NOTION_API_KEY is set (length: 50)
  ✓ AZURE_OPENAI_API_KEY is set (length: 32)
  ✓ AZURE_OPENAI_ENDPOINT is set

Azure CLI Authentication:
  ✓ Authenticated to tenant 2930489e-9d8a-456b-9de9-e4787faeab9c
  ✓ Using subscription cfacbbe8-a2a3-445f-a188-68b3b35f0c84

MCP Server Status:
  ✓ notion      Connected (latency: 145ms)
  ✓ github      Connected (latency: 89ms)
  ✓ azure       Connected (latency: 210ms)
  ✓ playwright  Connected (latency: 52ms)

Overall Status: HEALTHY
```

**Schedule**: Run this daily before starting Innovation Nexus work to catch authentication issues early.

### Manual Connection Tests

**Test 1: Notion MCP**
```bash
# Inside Claude Code
Task "Search Notion for pages created in last 7 days"

# Success Indicators:
# - Returns list of pages with dates
# - No "401 Unauthorized" errors
# - No "Rate limit exceeded" warnings
```

**Test 2: GitHub MCP**
```bash
# Inside Claude Code
Task "List open pull requests in brookside-bi/innovation-nexus repository"

# Success Indicators:
# - Returns list of PRs with titles, authors, status
# - No "Bad credentials" errors
# - No "API rate limit exceeded" errors
```

**Test 3: Azure MCP**
```bash
# Inside Claude Code
Task "Retrieve secret 'github-personal-access-token' from Key Vault kv-brookside-secrets"

# Success Indicators:
# - Returns secret value (Claude will mask it in output)
# - No "Unauthorized" errors
# - No "Resource not found" errors
```

**Test 4: Playwright MCP**
```bash
# Inside Claude Code
Task "Navigate to https://github.com/brookside-bi and capture screenshot"

# Success Indicators:
# - Returns screenshot file path
# - Image shows GitHub organization page
# - No browser launch errors
```

### Automated Health Monitoring (Planned)

**Future Enhancement**: Scheduled PowerShell task runs `mcp-health.ps1` every 6 hours, sends email alert if any server unhealthy.

**Planned Configuration**:
```yaml
Schedule: Every 6 hours (6am, 12pm, 6pm, 12am)
Alert Recipients: Alec Fielding, Markus Ahling
Alert Conditions:
  - Any MCP server disconnected
  - Azure CLI token expired (<10 minutes remaining)
  - Environment variable missing or empty
  - Latency >2 seconds for any server
Alert Method: Email + Teams notification
```

---

## Rate Limits and Performance Optimization

### MCP Server Rate Limits

| MCP Server | Rate Limit | Quota Window | Exceeded Behavior | Mitigation Strategy |
|------------|------------|--------------|-------------------|---------------------|
| **Notion** | 3 req/sec | Rolling 1 second | 429 Too Many Requests, retry after 1s | Batch operations, cache results |
| **GitHub** | 5,000 req/hour | Rolling 1 hour | 403 Forbidden, reset at top of hour | Use GraphQL for bulk queries, cache repo metadata |
| **Azure** | 12,000 req/hour (ARM) | Rolling 1 hour | 429 Too Many Requests, retry with exponential backoff | Use Azure Resource Graph for bulk queries |
| **Playwright** | No API limit | N/A | Local resource constraints (CPU/memory) | Close browser sessions after use |

### Performance Best Practices

#### 1. Batch Operations (Notion)

**❌ Inefficient** (3 separate API calls):
```bash
Task "Create Notion page for Idea 1"
Task "Create Notion page for Idea 2"
Task "Create Notion page for Idea 3"
```

**✅ Efficient** (1 API call for up to 100 pages):
```bash
Task "Create 3 Notion pages in Ideas Registry: [Idea 1 details], [Idea 2 details], [Idea 3 details]"
```

**Savings**: 67% fewer API calls, 75% faster execution

#### 2. Cache Frequently Accessed Data

**Example**: Notion database schema queries

```typescript
// ❌ Query schema every time (slow)
async function createIdea(title: string) {
  const schema = await notionMCP.fetchDatabase("984a4038-3e45-4a98-8df4-fd64dd8a1032");
  // Use schema to validate properties...
}

// ✅ Cache schema for 1 hour (fast)
let cachedSchema = null;
let cacheTime = null;

async function createIdea(title: string) {
  if (!cachedSchema || Date.now() - cacheTime > 3600000) {
    cachedSchema = await notionMCP.fetchDatabase("984a4038-3e45-4a98-8df4-fd64dd8a1032");
    cacheTime = Date.now();
  }
  // Use cached schema...
}
```

**Savings**: 95% reduction in Notion API calls for schema queries

#### 3. Use GraphQL for GitHub (Fewer API Calls)

**❌ REST API** (3 API calls to get repo + latest commit + open issues count):
```bash
GET /repos/brookside-bi/innovation-nexus
GET /repos/brookside-bi/innovation-nexus/commits/main
GET /repos/brookside-bi/innovation-nexus/issues?state=open
```

**✅ GraphQL** (1 API call):
```graphql
query {
  repository(owner: "brookside-bi", name: "innovation-nexus") {
    name
    defaultBranchRef {
      target {
        ... on Commit {
          oid
          messageHeadline
        }
      }
    }
    issues(states: OPEN) {
      totalCount
    }
  }
}
```

**Savings**: 67% fewer API calls, 80% faster for complex queries

#### 4. Reuse Playwright Browser Sessions

**❌ Launch new browser for each task**:
```bash
Task "Navigate to https://site1.com and get title"
Task "Navigate to https://site2.com and get title"
# Launches 2 separate Chromium processes (slow startup)
```

**✅ Reuse single browser session**:
```bash
Task "Launch browser, navigate to https://site1.com and get title, then navigate to https://site2.com and get title"
# Single Chromium process, faster navigation
```

**Savings**: 5-10 seconds per browser launch avoided

---

## Common Issues and Troubleshooting

### Issue 1: "MCP Server Disconnected" Error

**Symptom**: Claude Code shows `✗ notion (Disconnected)` or similar

**Diagnosis**:
```powershell
# Step 1: Check environment variables
$env:NOTION_API_KEY
$env:GITHUB_PERSONAL_ACCESS_TOKEN

# If blank, credentials not loaded
# Step 2: Verify Azure CLI authentication (for Azure MCP)
az account show

# Step 3: Check MCP configuration file
cat C:/Users/MarkusAhling/.claude/mcp.json
```

**Resolution**:
```powershell
# Method 1: Reconfigure environment variables
.\scripts\Set-MCPEnvironment.ps1

# Method 2: Manual Azure login (if Azure MCP disconnected)
az login

# Method 3: Restart Claude Code
# Close existing Claude session, relaunch:
claude

# Step 4: Verify reconnection
claude mcp list
```

**Root Causes**:
- Environment variable cleared (terminal session ended)
- Azure CLI token expired (>1 hour since `az login`)
- Key Vault access denied (RBAC permissions changed)
- MCP configuration file corrupted (invalid JSON)

### Issue 2: "Rate Limit Exceeded" Error

**Symptom**: Notion/GitHub operations fail with `429 Too Many Requests`

**Diagnosis**:
```bash
# Notion: Check if making >3 requests/second
# GitHub: Check if approaching 5,000 requests/hour

# View current GitHub rate limit status
Task "Query GitHub API for current rate limit: https://api.github.com/rate_limit"
```

**Resolution**:
```bash
# Immediate: Wait for rate limit reset
# Notion: Wait 1 second, retry
# GitHub: Wait until top of hour (shown in rate limit response)

# Long-term: Optimize operations
# - Batch Notion page creation (up to 100 pages/call)
# - Use GitHub GraphQL instead of REST
# - Cache frequently accessed data (database schemas, repo metadata)
```

**Prevention**:
- Implement exponential backoff in automation scripts
- Use caching for static data (schemas, reference lists)
- Batch operations when creating multiple entities

### Issue 3: Azure CLI Token Expired

**Symptom**: Azure MCP operations fail with `401 Unauthorized` or `Authentication token expired`

**Diagnosis**:
```bash
# Check current token expiration
az account get-access-token --query expiresOn --output tsv

# If <10 minutes remaining, token will expire soon
```

**Resolution**:
```bash
# Option 1: Refresh token
az account get-access-token --query accessToken --output tsv

# Option 2: Full re-authentication
az login

# Verify new token
az account show
```

**Prevention**:
- Run `az login` at start of each work day
- Configure Azure CLI token lifetime extension (up to 8 hours):
  ```bash
  az config set core.login_experience_v2=off
  ```

### Issue 4: Notion OAuth Token Revoked

**Symptom**: Notion MCP fails with `401 Unauthorized`, even after restarting Claude Code

**Diagnosis**:
```bash
# Check Notion integration status
# Visit: https://www.notion.so/my-integrations
# Verify "Innovation Nexus Claude Integration" shows "Active"
```

**Resolution**:
```bash
# Step 1: Re-authenticate Claude Code to Notion
# Close Claude Code
# Delete OAuth cache: rm -rf C:/Users/MarkusAhling/.claude/cache/notion-oauth

# Step 2: Relaunch Claude Code (will prompt for Notion re-authentication)
claude

# Step 3: Follow OAuth flow in browser
# Grant access to all required databases
```

**Root Causes**:
- Notion workspace administrator revoked integration access
- OAuth token manually deleted from Notion settings
- Workspace permission changes (integration no longer has access to databases)

### Issue 5: GitHub PAT Insufficient Permissions

**Symptom**: GitHub operations fail with `403 Forbidden` or `Requires write access to repository`

**Diagnosis**:
```bash
# Check current PAT scopes
# Visit: https://github.com/settings/tokens
# Find token "Claude Code MCP Integration"
# Verify scopes include: repo, workflow, admin:org
```

**Resolution**:
```bash
# Step 1: Generate new PAT with correct scopes
# Navigate to https://github.com/settings/tokens/new
# Select scopes: repo, workflow, admin:org, write:packages
# Generate token, copy to clipboard

# Step 2: Update Key Vault secret
az keyvault secret set \
  --vault-name kv-brookside-secrets \
  --name github-personal-access-token \
  --value "ghp_NEW_TOKEN_HERE"

# Step 3: Reconfigure MCP environment
.\scripts\Set-MCPEnvironment.ps1

# Step 4: Restart Claude Code
```

**Prevention**:
- Use fine-grained PAT with specific repository access (more secure)
- Set PAT expiration to 90 days, calendar reminder to rotate
- Document required scopes in Key Vault secret tags

### Issue 6: Playwright Browser Launch Failure

**Symptom**: Playwright operations fail with `Browser launch failed: Executable not found`

**Diagnosis**:
```bash
# Check if Chromium installed
npx playwright --version

# Check for Chromium executable
ls C:/Users/MarkusAhling/AppData/Local/ms-playwright/chromium-*/chrome-win/chrome.exe
```

**Resolution**:
```bash
# Install Playwright browsers
npx playwright install chromium

# If above fails, install all browsers
npx playwright install

# Verify installation
npx playwright --version
# Expected: Version 1.40.0 or later
```

**Root Causes**:
- Playwright package updated but browsers not reinstalled
- Antivirus quarantined Chromium executable
- Insufficient disk space for browser installation (requires ~300 MB)

---

## Advanced MCP Topics

### Custom MCP Server Development (Future)

**Use Case**: Integrate proprietary systems (Salesforce, internal APIs) with Claude Code

**Architecture**:
```mermaid
graph LR
    CLAUDE[Claude Code] -->|JSON-RPC| CUSTOM_MCP[Custom MCP Server]
    CUSTOM_MCP -->|HTTPS| SALESFORCE[Salesforce API]
    CUSTOM_MCP -->|HTTPS| INTERNAL_API[Internal CRM API]
```

**Implementation Steps** (high-level):
1. Create Node.js package implementing MCP protocol
2. Define tools (e.g., `salesforce-create-lead`, `salesforce-query-opportunities`)
3. Handle authentication (OAuth or API key)
4. Package as npm module: `@brooksidebi/mcp-server-salesforce`
5. Add to `.claude/mcp.json` configuration
6. Test connection: `claude mcp list`

**Reference**: Anthropic MCP SDK documentation (https://github.com/anthropics/mcp)

### MCP Server Logging and Debugging

**Enable Debug Logs**:
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-github", "--log-level", "debug"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    }
  }
}
```

**Log Locations**:
```bash
# Claude Code main log
C:/Users/MarkusAhling/.claude/logs/claude-code.log

# MCP server stdout/stderr (if redirected)
C:/Users/MarkusAhling/.claude/logs/mcp-github.log
```

**Analyzing Logs**:
```bash
# View last 50 lines of Claude Code log
tail -n 50 C:/Users/MarkusAhling/.claude/logs/claude-code.log

# Search for errors
grep -i "error" C:/Users/MarkusAhling/.claude/logs/claude-code.log

# Filter for specific MCP server
grep "mcp-server-github" C:/Users/MarkusAhling/.claude/logs/claude-code.log
```

### MCP Performance Profiling

**Measure MCP Call Latency**:
```bash
# Inside Claude Code with debug logging enabled
Task "Profile performance of Notion search query"

# Check logs for timing information:
# [mcp-server-notion] Request: notion-search (123ms)
# [mcp-server-notion] Response: 5 results (456ms total)
```

**Optimize Slow Operations**:
1. **Identify bottleneck**: Check if latency is network (API call) or compute (MCP server processing)
2. **Cache static data**: Database schemas, reference lists (reduce API calls)
3. **Batch requests**: Combine multiple operations into single API call
4. **Use pagination**: For large result sets, fetch incrementally

---

## MCP Security and Compliance

### Credential Storage Best Practices

**✅ Secure Storage**:
- Azure Key Vault (primary, enterprise-grade encryption)
- Environment variables (session-scoped, not persisted)
- Encrypted configuration files (if MCP server supports)

**❌ Insecure Storage**:
- Plaintext `.env` files in Git repositories
- Hardcoded secrets in `mcp.json` (even if Git-ignored)
- Browser localStorage (vulnerable to XSS attacks)

### Audit Logging

**Key Vault Access Logs** (all secret retrievals logged):
```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.KEYVAULT"
| where OperationName == "SecretGet"
| where ResourceId contains "kv-brookside-secrets"
| project TimeGenerated, CallerIPAddress, ResultType, identity_claim_upn_s
| order by TimeGenerated desc
```

**GitHub Audit Logs** (PAT usage tracked):
```bash
# View PAT usage
# Navigate to: https://github.com/settings/security-log
# Filter: "Action: oauth_access"
```

**Notion Audit Logs** (integration access tracked):
```bash
# View integration activity
# Navigate to: Notion Settings > Integrations > Innovation Nexus Claude Integration > Activity
```

### Principle of Least Privilege

**MCP Server Permissions** (recommended):

| MCP Server | Required Permission | Avoid Granting |
|------------|---------------------|----------------|
| **Notion** | Read content, Update content, Insert content | Create workspaces, Delete workspaces |
| **GitHub** | `repo`, `workflow` | `admin:org:write`, `delete_repo` |
| **Azure** | Contributor (resource groups only) | Owner (subscription), Billing Administrator |
| **Playwright** | Filesystem read/write (screenshots only) | Network admin, System admin |

**Review Permissions Quarterly**: Ensure MCP integrations haven't accumulated unnecessary privileges.

---

## Next Steps

**You've completed MCP Server Configuration. Continue to:**

- **[Common Workflows](07-common-workflows.md)**: Master Innovation Lifecycle, Cost Optimization, and Repository Intelligence workflows with MCP integrations
- **[Troubleshooting FAQ](08-troubleshooting-faq.md)**: Resolve advanced MCP, Notion, and Azure integration issues
- **[Azure Infrastructure Setup](05-azure-infrastructure-setup.md)**: Return to review Key Vault configuration if credentials need rotation

---

**Document Information**:
- **Last Updated**: October 26, 2025
- **Maintained By**: Markus Ahling (Architecture), Alec Fielding (Infrastructure)
- **Review Schedule**: Quarterly (MCP server updates), As-needed (authentication changes)
- **Feedback**: Submit improvements to Innovation Nexus Ideas Registry with tag "Documentation"
