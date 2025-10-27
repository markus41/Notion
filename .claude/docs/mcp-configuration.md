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
| **Morningstar** | Financial data, investment research, portfolio analytics | API Key from Key Vault | ⏸️ Provisioning |
| **Bloomberg** | Real-time market data, news, financial analytics | Terminal credentials or BLPAPI | ⏸️ Provisioning |
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
// Basic documentation search
mcp__azure__documentation({
  intent: "search",
  parameters: {
    query: "Azure Functions Python best practices",
    maxResults: 10
  }
})

// Returns: Up to 10 content chunks (500 tokens each)
// from Microsoft Learn and official Azure docs

// Advanced query patterns for specific topics
const azureFunctionsDocs = await mcp__azure__documentation({
  intent: "search",
  parameters: {
    query: "Azure Functions Durable orchestration error handling retry policies",
    maxResults: 5
  }
});

const powerBIDocs = await mcp__azure__documentation({
  intent: "search",
  parameters: {
    query: "Power BI Embedded authentication service principal",
    maxResults: 5
  }
});

const securityDocs = await mcp__azure__documentation({
  intent: "search",
  parameters: {
    query: "Azure Key Vault Managed Identity RBAC best practices",
    maxResults: 5
  }
});
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

### Microsoft Documentation - Advanced Patterns

**Category-Specific Queries**:
```typescript
// Azure Functions - Best for @code-generator, @build-architect
const functionsDocs = await mcp__azure__documentation({
  intent: "search",
  parameters: {
    query: "Azure Functions Python Durable orchestration patterns dependency injection",
    maxResults: 5
  }
});

// Power BI - Best for @integration-specialist
const powerBIDocs = await mcp__azure__documentation({
  intent: "search",
  parameters: {
    query: "Power BI REST API embed report service principal authentication",
    maxResults: 5
  }
});

// Azure DevOps - Best for @deployment-orchestrator
const devOpsDocs = await mcp__azure__documentation({
  intent: "search",
  parameters: {
    query: "Azure DevOps pipelines YAML multi-stage deployment approval gates",
    maxResults: 5
  }
});

// Security & Compliance - Best for @compliance-orchestrator
const securityDocs = await mcp__azure__documentation({
  intent: "search",
  parameters: {
    query: "Azure security baseline zero trust Managed Identity RBAC",
    maxResults: 5
  }
});
```

**Caching Documentation Results**:
```typescript
// ✅ Correct - Cache docs (content rarely changes)
const docCache = new Map();

async function getAzureDocs(topic) {
  const cacheKey = `docs:${topic}`;

  if (docCache.has(cacheKey)) {
    return docCache.get(cacheKey);
  }

  const docs = await mcp__azure__documentation({
    intent: "search",
    parameters: { query: topic, maxResults: 5 }
  });

  docCache.set(cacheKey, docs);
  return docs;
}

// ❌ Wrong - Fetching same docs repeatedly
// Official Microsoft docs don't change frequently
```

**Integration with Code Generation**:
```typescript
// Example: Generate Azure Function with real-time best practices
async function generateAzureFunction(spec) {
  // 1. Get latest best practices from Microsoft
  const bestPractices = await mcp__azure__documentation({
    intent: "search",
    parameters: {
      query: `Azure Functions ${spec.runtime} ${spec.trigger} best practices patterns`,
      maxResults: 3
    }
  });

  // 2. Extract key patterns from docs
  const patterns = extractPatterns(bestPractices);

  // 3. Generate code following Microsoft guidance
  const functionCode = await generateCode({
    spec: spec,
    patterns: patterns,
    framework: "Azure Functions"
  });

  return functionCode;
}
```

**Query Optimization Tips**:
```typescript
// ✅ Best practice - Specific, technical queries
"Azure Functions Durable orchestration error handling retry policies"
"Power BI Embedded row-level security dynamic rules"
"Azure SQL Database serverless auto-pause delay configuration"

// ❌ Avoid - Too broad, ambiguous queries
"Azure best practices"
"How to use Power BI"
"Database setup"

// ✅ Best practice - Include versions/tiers when relevant
"Azure Functions Python 3.11 Durable Functions 2.x patterns"

// ✅ Best practice - Specify authentication/security method
"Azure Key Vault Managed Identity system-assigned RBAC"
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

## Morningstar Financial Data API

### Capabilities
- **Equity Data**: Stock fundamentals, pricing, P/E ratios, market cap
- **Fund Research**: Mutual fund ratings, expense ratios, performance metrics
- **Portfolio Analytics**: Performance tracking, risk metrics, asset allocation
- **ESG Ratings**: Environmental, Social, Governance scores and sustainability data
- **Screening**: Custom security screening with multiple criteria

### Authentication
**Method**: API Key from Azure Key Vault

**Setup**:
```powershell
# Retrieve API key
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "morningstar-api-key" -AsPlainText

# Set environment variable
$env:MORNINGSTAR_API_KEY = "<key-from-vault>"

# Verify (included in Set-MCPEnvironment.ps1)
.\scripts\Set-MCPEnvironment.ps1
```

**Key Vault Details**:
- Secret: `morningstar-api-key`
- Vault: `kv-brookside-secrets`
- Rotation: Quarterly

**Verification**:
```powershell
# Test API connection
.\scripts\Test-FinancialAPIs.ps1 -Service Morningstar
```

### Key Operations

#### Query Stock Fundamentals
```typescript
const stockData = await morningstarAPI.getEquityData({
  ticker: "MSFT",
  fields: ["price", "pe_ratio", "market_cap", "52_week_high", "beta"],
  currency: "USD"
});

// Returns: price, P/E ratio, market cap, highs/lows, volatility
```

#### Fund Research
```typescript
const fundAnalysis = await morningstarAPI.getFundRating({
  ticker: "VFIAX",
  includeESG: true,
  includePerformance: true,
  timePeriod: "5Y"
});

// Returns: Morningstar rating, expense ratio, ESG score, returns
```

#### Portfolio Performance
```typescript
const portfolioMetrics = await morningstarAPI.getPortfolioPerformance({
  holdings: [
    { ticker: "MSFT", quantity: 1000 },
    { ticker: "AAPL", quantity: 500 }
  ],
  benchmarkIndex: "SP500",
  startDate: "2024-01-01",
  endDate: "2025-10-27"
});

// Returns: total value, return %, alpha, Sharpe ratio, sector allocation
```

### Performance Optimization

**Batch Queries**:
```typescript
// ✅ Correct - Single request for multiple tickers
const data = await morningstarAPI.getBatchEquityData({
  tickers: ["MSFT", "AAPL", "GOOGL"],
  fields: ["price", "pe_ratio"]
});

// ❌ Wrong - Separate requests
for (const ticker of tickers) {
  await morningstarAPI.getEquityData({ ticker });  // Rate limit risk
}
```

**Cache Low-Volatility Data**:
```typescript
// ✅ Correct - Cache fundamentals (update daily)
const cached = cache.get(`fundamentals:${ticker}:${today}`);

// ❌ Wrong - Fetch fundamentals repeatedly (wasteful)
```

**Rate Limits**:
- Direct API: 10 requests/second, 100,000 requests/month
- Cloud API: 5 requests/second, 10,000 requests/month
- Implement exponential backoff for 429 errors

---

## Bloomberg Terminal/API

### Capabilities
- **Real-Time Market Data**: Live prices, volume, quotes for global securities
- **Historical Data**: Time series pricing, fundamentals, corporate actions
- **News & Research**: Bloomberg News, analyst reports, market commentary
- **Industry Analytics**: Market size, growth rates, competitive landscape
- **Excel Integration**: BDP, BDH, BDS functions for data retrieval

### Authentication
**Method**: Bloomberg Terminal credentials or BLPAPI authentication

**Setup Option 1 - Bloomberg Terminal**:
```powershell
# Launch terminal
Start-Process "C:\blp\API\Bloomberg.exe"

# Authenticate via Bloomberg Anywhere
# User: <bloomberg-username>@brookside-bi
# Password: <from-key-vault>
```

**Setup Option 2 - BLPAPI** (programmatic):
```powershell
# Retrieve credentials
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "bloomberg-api-username" -AsPlainText
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "bloomberg-api-password" -AsPlainText

# Set environment variables
$env:BLOOMBERG_USERNAME = "<username-from-vault>"
$env:BLOOMBERG_PASSWORD = "<password-from-vault>"

# Install SDK (if using Python)
pip install blpapi
```

**Key Vault Details**:
- Secrets: `bloomberg-api-username`, `bloomberg-api-password`
- Vault: `kv-brookside-secrets`
- Rotation: Monthly

**Verification**:
```powershell
# Test connection
.\scripts\Test-FinancialAPIs.ps1 -Service Bloomberg
```

### Key Operations

#### Real-Time Market Data
```typescript
const marketData = await bloombergAPI.getSecurityData({
  securities: ["MSFT US Equity", "AAPL US Equity"],
  fields: ["PX_LAST", "VOLUME", "PE_RATIO", "MARKET_CAP"]
});

// Returns: Current price, volume, P/E, market cap for each security
```

#### Historical Price Data
```typescript
const priceHistory = await bloombergAPI.getHistoricalData({
  security: "MSFT US Equity",
  fields: ["PX_LAST", "PX_OPEN", "PX_HIGH", "PX_LOW"],
  startDate: "20241027",
  endDate: "20251027",
  periodicitySelection: "DAILY"
});

// Returns: Daily OHLC prices for 1 year
```

#### News Monitoring
```typescript
const newsResults = await bloombergAPI.getNews({
  topic: "Cloud Computing",
  companies: ["MSFT", "AMZN", "GOOGL"],
  timeRange: "24h",
  limit: 50
});

// Returns: Recent articles with headlines, sentiment, categories
```

#### Industry Analytics
```typescript
const industryData = await bloombergAPI.getIndustryAnalysis({
  industry: "Cloud Services",
  metrics: ["MARKET_SIZE", "GROWTH_RATE_5Y", "TOP_PLAYERS"],
  region: "Global"
});

// Returns: Market size, growth rate, top companies, market share
```

### Performance Optimization

**Request Multiple Fields**:
```typescript
// ✅ Correct - Single request with all fields
const data = await bloomberg.getSecurityData({
  securities: ["MSFT"],
  fields: ["PX_LAST", "VOLUME", "PE_RATIO", "MARKET_CAP"]
});

// ❌ Wrong - Separate requests per field
const price = await bloomberg.getSecurityData({ securities: ["MSFT"], fields: ["PX_LAST"] });
const volume = await bloomberg.getSecurityData({ securities: ["MSFT"], fields: ["VOLUME"] });
```

**Rate Limits**:
- Terminal: ~100 requests/minute (Excel API)
- BLPAPI Reference Data: 50 requests/second
- BLPAPI Market Data: Real-time streaming (no limit)
- Historical Data: 1000 data points per request recommended

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
.\scripts\Test-FinancialAPIs.ps1  # Test Morningstar + Bloomberg
claude mcp list

# 4. Launch Claude Code
claude
```

**Frequency**: Daily (or after system restart)

**Financial APIs Note**: Morningstar and Bloomberg credentials are retrieved from Azure Key Vault during `Set-MCPEnvironment.ps1` execution. No additional authentication required beyond Azure login.

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
