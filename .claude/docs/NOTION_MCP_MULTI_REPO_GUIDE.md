# Notion MCP Multi-Repository Configuration Guide

**Purpose**: Establish scalable Notion MCP authentication and configuration patterns for organizations managing multiple repositories with shared workspace access.

**Best for**: Teams requiring consistent Notion integration across multiple codebases with centralized authentication, database access patterns, and enterprise-grade security.

---

## Executive Summary

**Key Finding**: Notion MCP uses **global OAuth authentication** stored in `~/.claude/mcp-credentials.json`, enabling **one-time authentication for all repositories** on the same machine.

**Critical Implications**:
- ✅ **No per-repository authentication** - Configure once, use everywhere
- ✅ **Consistent workspace access** - Same permissions across all repositories
- ✅ **Team-friendly** - Each developer authenticates once on their machine
- ⚠️ **OAuth token security** - Tokens stored locally, not in repository
- ⚠️ **Per-developer authentication** - Cannot share tokens across team members

---

## Table of Contents

1. [Notion MCP Authentication Architecture](#notion-mcp-authentication-architecture)
2. [Multi-Repository Setup](#multi-repository-setup)
3. [Configuration Best Practices](#configuration-best-practices)
4. [Database Access Patterns](#database-access-patterns)
5. [Security Considerations](#security-considerations)
6. [Troubleshooting Guide](#troubleshooting-guide)
7. [Testing & Validation](#testing--validation)

---

## Notion MCP Authentication Architecture

### OAuth Flow Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│ Developer Machine (One-Time Setup)                              │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Step 1: Claude Code Launch                                     │
│  ┌─────────────────┐                                            │
│  │ claude          │────┐                                        │
│  └─────────────────┘    │                                        │
│                         │                                        │
│  Step 2: MCP Server Initialization                              │
│  ┌─────────────────────────────────────────┐                    │
│  │ Read: ~/.config/claude-code/            │                    │
│  │   - mcp_config.json (global servers)    │                    │
│  │   - .mcp.json (project servers)         │                    │
│  └─────────────────────────────────────────┘                    │
│                         │                                        │
│  Step 3: Notion OAuth (First Time Only)                         │
│  ┌─────────────────────────────────────────┐                    │
│  │ Browser Opens: mcp.notion.com/auth      │                    │
│  │ User grants workspace access            │                    │
│  │ OAuth token returned to Claude Code     │                    │
│  └─────────────────────────────────────────┘                    │
│                         │                                        │
│  Step 4: Token Storage                                          │
│  ┌─────────────────────────────────────────┐                    │
│  │ Write: ~/.claude/mcp-credentials.json   │                    │
│  │ {                                       │                    │
│  │   "notion": {                           │                    │
│  │     "oauth_token": "secret_...",        │                    │
│  │     "workspace_id": "81686779-...",     │                    │
│  │     "expires_at": "2025-11-21T...",     │                    │
│  │     "refresh_token": "..."              │                    │
│  │   }                                     │                    │
│  │ }                                       │                    │
│  └─────────────────────────────────────────┘                    │
│                         │                                        │
│  Step 5: All Future Sessions                                    │
│  ┌─────────────────────────────────────────┐                    │
│  │ Read mcp-credentials.json → Auto-auth   │                    │
│  │ ✓ Innovation Nexus repo                 │                    │
│  │ ✓ Project-Ascension repo                │                    │
│  │ ✓ Any other repo with Notion MCP        │                    │
│  └─────────────────────────────────────────┘                    │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

External Dependencies:
┌─────────────────────┐      ┌──────────────────────┐
│ Notion OAuth Server │      │ Brookside BI         │
│ mcp.notion.com      │◄────►│ Workspace            │
│                     │      │ ID: 81686779-099a... │
└─────────────────────┘      └──────────────────────┘
```

### Authentication Lifecycle

**Initial Authentication** (First Launch):
1. Claude Code detects Notion MCP server configured
2. No credentials found in `~/.claude/mcp-credentials.json`
3. Browser opens to `https://mcp.notion.com/auth`
4. User selects workspace and grants permissions
5. OAuth token stored globally (NOT in repository)
6. Token automatically refreshed when approaching expiration

**Subsequent Sessions** (All Repositories):
1. Claude Code reads `~/.claude/mcp-credentials.json`
2. Validates token expiration date
3. If expired: Auto-refresh using refresh token
4. If refresh fails: Trigger re-authentication
5. Connection established to Brookside BI workspace

**Token Expiration**: Notion OAuth tokens typically last **90 days**, with automatic refresh 7 days before expiration.

---

## Multi-Repository Setup

### Configuration Strategy: Global + Project-Specific

Notion MCP uses a **two-tier configuration system**:

1. **Global MCP Config** (`~/.config/claude-code/mcp_config.json`)
   - Applies to ALL Claude Code sessions
   - Stores authentication credentials
   - Not committed to Git

2. **Project MCP Config** (`.mcp.json` in repository root)
   - Repository-specific MCP servers
   - Can override global settings
   - Should NOT be committed (add to `.gitignore`)

### Recommended Configuration: Project-Specific `.mcp.json`

**Why Project-Specific?**
- ✅ Each repository explicitly declares dependencies
- ✅ Team members know what MCP servers are required
- ✅ Version control tracks configuration changes
- ✅ No reliance on global configuration across machines
- ⚠️ Requires each repository to define Notion MCP

**Option 1: Committed `.mcp.json` (Recommended for Innovation Nexus)**

```json
{
  "mcpServers": {
    "notion": {
      "url": "https://mcp.notion.com/mcp",
      "transport": "http"
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    },
    "azure": {
      "command": "npx",
      "args": ["-y", "@azure/mcp@latest", "server", "start"]
    },
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest", "--browser", "msedge", "--headless"]
    }
  }
}
```

**Add to `.gitignore`**:
```bash
# Keep .mcp.json out of version control (contains environment-specific config)
.mcp.json

# Keep credentials out of version control
.claude/mcp-credentials.json
~/.claude/mcp-credentials.json
```

**Option 2: Global Configuration (Alternative)**

If you want Notion MCP available to **all repositories** automatically:

1. Add to global config:
   ```bash
   # Location: ~/.config/claude-code/mcp_config.json
   {
     "mcpServers": {
       "notion": {
         "url": "https://mcp.notion.com/mcp",
         "transport": "http"
       }
     }
   }
   ```

2. Each repository can still override or extend with `.mcp.json`

### Setting Up Project-Ascension Repository

**Step-by-Step Configuration**:

1. **Create `.mcp.json` in Project-Ascension root**:
   ```bash
   cd /path/to/Project-Ascension

   # Copy from Innovation Nexus (or create manually)
   cat > .mcp.json << 'EOF'
   {
     "mcpServers": {
       "notion": {
         "url": "https://mcp.notion.com/mcp",
         "transport": "http"
       }
     }
   }
   EOF
   ```

2. **Add workspace ID to environment** (optional, for database queries):
   ```bash
   # Option A: Project-specific .env file
   echo "NOTION_WORKSPACE_ID=81686779-099a-8195-b49e-00037e25c23e" >> .env

   # Option B: .claude/settings.local.json
   {
     "env": {
       "NOTION_WORKSPACE_ID": "81686779-099a-8195-b49e-00037e25c23e"
     }
   }
   ```

3. **Launch Claude Code**:
   ```bash
   claude
   ```

4. **First Launch Authentication** (one-time):
   - Claude Code detects Notion MCP server
   - Browser opens for OAuth authentication
   - Select "Brookside BI" workspace
   - Grant permissions
   - ✓ Token stored globally in `~/.claude/mcp-credentials.json`

5. **Verify Connection**:
   ```bash
   claude mcp list
   # Expected: notion: https://mcp.notion.com/mcp (HTTP) - ✓ Connected
   ```

6. **Test Database Access**:
   ```bash
   # In Claude Code session
   notion-search "query: Ideas Registry"
   # Should return results from Brookside BI workspace
   ```

### Team Member Onboarding

**Each team member must authenticate individually**:

1. **Clone repository**:
   ```bash
   git clone https://github.com/brookside-bi/Project-Ascension
   cd Project-Ascension
   ```

2. **Verify `.mcp.json` exists**:
   ```bash
   cat .mcp.json
   # Should show Notion MCP configuration
   ```

3. **Launch Claude Code**:
   ```bash
   claude
   ```

4. **Authenticate when prompted**:
   - Browser opens automatically
   - Select "Brookside BI" workspace
   - Grant permissions
   - ✓ Token stored on developer's machine

5. **Verify connection**:
   ```bash
   claude mcp list
   notion-search "test query"
   ```

**Important**: OAuth tokens are **per-developer**, not shared. Each team member authenticates with their own Notion account credentials.

---

## Configuration Best Practices

### Database ID Management

**Three Storage Strategies**:

| Strategy | Location | Best For | Example |
|----------|----------|----------|---------|
| **Environment Variables** | `.env` or `.claude/settings.local.json` | Dynamic IDs, multiple workspaces | `NOTION_DB_IDEAS=984a4038-...` |
| **Documentation** | `CLAUDE.md` or `README.md` | Reference lookup, onboarding | See "Notion Database IDs" section |
| **Code Constants** | Agent files, slash commands | Direct programmatic access | `IDEAS_REGISTRY = "984a4038-..."` |

**Recommended: Documentation + Environment Variables**

```markdown
<!-- In CLAUDE.md -->
## Notion Database IDs

**💡 Ideas Registry:**
- Database URL: `https://www.notion.so/c17ec2eb9555449eaa34edba4f0c7b60`
- Data Source ID: `984a4038-3e45-4a98-8df4-fd64dd8a1032`
- Collection URL: `collection://984a4038-3e45-4a98-8df4-fd64dd8a1032`

**🔬 Research Hub:**
- Data Source ID: `91e8beff-af94-4614-90b9-3a6d3d788d4a`
- Collection URL: `collection://91e8beff-af94-4614-90b9-3a6d3d788d4a`

**🛠️ Example Builds:**
- Data Source ID: `a1cd1528-971d-4873-a176-5e93b93555f6`
- Collection URL: `collection://a1cd1528-971d-4873-a176-5e93b93555f6`

**💰 Software & Cost Tracker:**
- Data Source ID: `13b5e9de-2dd1-45ec-839a-4f3d50cd8d06`
- Collection URL: `collection://13b5e9de-2dd1-45ec-839a-4f3d50cd8d06`
```

```json
// In .claude/settings.local.json
{
  "env": {
    "NOTION_WORKSPACE_ID": "81686779-099a-8195-b49e-00037e25c23e",
    "NOTION_DB_IDEAS": "984a4038-3e45-4a98-8df4-fd64dd8a1032",
    "NOTION_DB_RESEARCH": "91e8beff-af94-4614-90b9-3a6d3d788d4a",
    "NOTION_DB_BUILDS": "a1cd1528-971d-4873-a176-5e93b93555f6",
    "NOTION_DB_SOFTWARE": "13b5e9de-2dd1-45ec-839a-4f3d50cd8d06"
  }
}
```

### Transport Configuration: HTTP vs. Stdio

**Notion MCP Uses HTTP Transport** (Official Server):

```json
{
  "notion": {
    "url": "https://mcp.notion.com/mcp",
    "transport": "http"  // NOT "stdio"
  }
}
```

**Why HTTP?**
- ✅ Notion's official MCP server uses HTTP transport
- ✅ OAuth authentication requires browser interaction
- ✅ Managed by Notion, no local server process
- ✅ Automatic credential refresh
- ❌ Requires internet connection (no offline mode)

**Comparison to Stdio Transport** (GitHub, Azure):

| Aspect | HTTP (Notion) | Stdio (GitHub/Azure) |
|--------|---------------|----------------------|
| **Server Location** | Notion-hosted (mcp.notion.com) | Local process (npx) |
| **Authentication** | OAuth via browser | Environment variables |
| **Credentials** | Stored in `~/.claude/mcp-credentials.json` | Passed via `env` object |
| **Offline Support** | ❌ Requires internet | ✅ Works offline (if cached) |
| **Token Refresh** | ✅ Automatic | ❌ Manual rotation |

### Workspace ID Configuration

**Where to Store Workspace ID**:

1. **Option A: Environment Variable** (Recommended for automation):
   ```json
   // .claude/settings.local.json
   {
     "env": {
       "NOTION_WORKSPACE_ID": "81686779-099a-8195-b49e-00037e25c23e"
     }
   }
   ```

2. **Option B: Documentation Only** (Manual reference):
   ```markdown
   <!-- CLAUDE.md -->
   **Workspace**: Brookside BI (ID: 81686779-099a-8195-b49e-00037e25c23e)
   ```

3. **Option C: Both** (Best for team consistency):
   - Environment variable for programmatic access
   - Documentation for human reference and onboarding

**When is Workspace ID Needed?**
- ⚠️ **Rarely required** - Most Notion MCP operations use database IDs
- ✅ **Workspace-level queries** - Listing all databases, searching globally
- ✅ **Multi-workspace scenarios** - If team has multiple Notion workspaces
- ❌ **Not needed for standard operations** - Database queries work without it

---

## Database Access Patterns

### Data Source URL Format

Notion databases use **data source URLs** (not page URLs) for MCP operations:

```
Format: collection://<data-source-id>

Example:
- Page URL:         https://www.notion.so/c17ec2eb9555449eaa34edba4f0c7b60
- Data Source URL:  collection://984a4038-3e45-4a98-8df4-fd64dd8a1032
                                 └──────────────┬───────────────────┘
                                          Use this for MCP queries
```

**How to Extract Data Source ID**:

1. **Fetch the database page**:
   ```bash
   notion-fetch "https://www.notion.so/c17ec2eb9555449eaa34edba4f0c7b60"
   ```

2. **Look for `<data-source url="collection://...">` tags** in response:
   ```markdown
   <database url="https://www.notion.so/c17ec2eb9555449eaa34edba4f0c7b60">
     <data-source url="collection://984a4038-3e45-4a98-8df4-fd64dd8a1032">
       <!-- This is the ID you need -->
     </data-source>
   </database>
   ```

3. **Extract the UUID**:
   ```
   collection://984a4038-3e45-4a98-8df4-fd64dd8a1032
                └──────────────┬───────────────────┘
                        Data Source ID
   ```

### Efficient Database Queries

**Query Strategies**:

| Operation | Use Case | MCP Tool | Performance Notes |
|-----------|----------|----------|-------------------|
| **Search** | Find existing content | `notion-search` | Semantic search with AI, slower but flexible |
| **Fetch** | Get specific page/database | `notion-fetch` | Fast, direct ID lookup |
| **Create** | Add new database entry | `notion-create-pages` | Requires parent database ID |
| **Update** | Modify existing entry | `notion-update-page` | Requires page ID |

**Performance Best Practices**:

1. **Cache Database IDs** - Store in environment variables, not repeated fetch
2. **Batch Operations** - Create multiple pages in single `notion-create-pages` call
3. **Specific Queries** - Use `notion-fetch` with exact IDs instead of search
4. **Search-First Protocol** - Always search before creating to prevent duplicates

**Example: Efficient Idea Creation**

```python
# ❌ INEFFICIENT: Search every time
def create_idea(title):
    # Search for database structure
    db = notion_fetch("https://www.notion.so/c17ec2eb9555449eaa34edba4f0c7b60")

    # Extract data source ID
    data_source_id = parse_data_source(db)

    # Search for duplicates
    duplicates = notion_search(f"Ideas Registry {title}")

    if not duplicates:
        notion_create_pages(parent={"data_source_id": data_source_id}, ...)

# ✅ EFFICIENT: Use cached IDs
IDEAS_REGISTRY_DS = "984a4038-3e45-4a98-8df4-fd64dd8a1032"

def create_idea(title):
    # Search for duplicates (required)
    duplicates = notion_search(f"Ideas Registry {title}")

    if not duplicates:
        notion_create_pages(
            parent={"data_source_id": IDEAS_REGISTRY_DS},
            pages=[{
                "properties": {"title": title, "Status": "Concept"},
                "content": "..."
            }]
        )
```

### Rate Limiting

**Notion API Rate Limits**:
- **3 requests per second** per integration (per OAuth token)
- **Bursts allowed**: Up to 10 requests in 1 second, then throttled
- **429 Status Code**: Too Many Requests (wait 1 second, retry)

**Retry Pattern** (from architectural patterns):

```python
import time
from typing import Callable, Any

def notion_retry_with_backoff(
    operation: Callable,
    max_retries: int = 3,
    initial_delay: float = 1.0,
    max_delay: float = 10.0
) -> Any:
    """
    Execute Notion API operation with exponential backoff retry.

    Best for: Handling transient failures and rate limiting in Notion MCP operations.
    """
    delay = initial_delay

    for attempt in range(max_retries):
        try:
            return operation()
        except Exception as e:
            if "429" in str(e) or "rate limit" in str(e).lower():
                if attempt < max_retries - 1:
                    wait_time = min(delay, max_delay)
                    print(f"Rate limited. Retrying in {wait_time}s...")
                    time.sleep(wait_time)
                    delay *= 2  # Exponential backoff
                else:
                    raise  # Max retries exceeded
            else:
                raise  # Non-rate-limit error

# Usage:
result = notion_retry_with_backoff(
    lambda: notion_search("Ideas Registry")
)
```

**Circuit-Breaker Pattern** (prevent cascading failures):

```python
from enum import Enum
from datetime import datetime, timedelta

class CircuitState(Enum):
    CLOSED = "closed"    # Normal operation
    OPEN = "open"        # Failing fast
    HALF_OPEN = "half_open"  # Testing recovery

class NotionCircuitBreaker:
    """
    Prevent cascading Notion MCP failures by failing fast when errors exceed threshold.

    Best for: Protecting application from Notion API outages or degraded performance.
    """
    def __init__(self, failure_threshold: int = 5, timeout: int = 60):
        self.state = CircuitState.CLOSED
        self.failure_count = 0
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.last_failure_time = None

    def call(self, operation: Callable) -> Any:
        if self.state == CircuitState.OPEN:
            if datetime.now() - self.last_failure_time > timedelta(seconds=self.timeout):
                self.state = CircuitState.HALF_OPEN
            else:
                raise Exception("Circuit breaker OPEN - Notion MCP unavailable")

        try:
            result = operation()
            if self.state == CircuitState.HALF_OPEN:
                self.state = CircuitState.CLOSED
                self.failure_count = 0
            return result
        except Exception as e:
            self.failure_count += 1
            self.last_failure_time = datetime.now()

            if self.failure_count >= self.failure_threshold:
                self.state = CircuitState.OPEN

            raise

# Usage:
notion_breaker = NotionCircuitBreaker()

try:
    result = notion_breaker.call(lambda: notion_search("test"))
except Exception as e:
    print(f"Notion MCP unavailable: {e}")
    # Fallback: Use cached data or skip operation
```

---

## Security Considerations

### OAuth Token Security

**Token Storage Location**:
```
~/.claude/mcp-credentials.json

{
  "notion": {
    "oauth_token": "secret_AbCd1234...",  // 90-day expiration
    "refresh_token": "secret_XyZ9876...", // Used for auto-refresh
    "workspace_id": "81686779-099a-8195-b49e-00037e25c23e",
    "expires_at": "2025-11-21T00:00:00Z"
  }
}
```

**Security Best Practices**:

1. **Never Commit Tokens**:
   ```bash
   # Add to .gitignore (all repositories)
   .claude/mcp-credentials.json
   ~/.claude/mcp-credentials.json
   ```

2. **File Permissions** (Unix/Linux/macOS):
   ```bash
   chmod 600 ~/.claude/mcp-credentials.json
   # Only owner can read/write
   ```

3. **Windows ACLs**:
   ```powershell
   # Restrict access to current user only
   icacls "$env:USERPROFILE\.claude\mcp-credentials.json" /inheritance:r /grant:r "$env:USERNAME:F"
   ```

4. **Token Expiration Monitoring**:
   - Notion OAuth tokens expire in **90 days**
   - Claude Code auto-refreshes 7 days before expiration
   - If refresh fails: Re-authenticate via browser

5. **Workspace Permissions**:
   - OAuth token inherits **user's Notion permissions**
   - Cannot elevate privileges beyond user's access
   - Team members have individual permission levels

### Workspace Access Permissions

**What Notion MCP Token Allows**:

✅ **Granted Permissions** (via OAuth):
- Read all pages/databases user has access to
- Create pages in databases user can edit
- Update pages user can edit
- Search workspace content user can view
- Query database schemas user can access

❌ **Denied Operations** (require workspace admin):
- Delete pages (intentionally restricted by Notion)
- Modify workspace settings
- Manage team members
- Change database schemas (add/remove properties)
- Modify integration settings

**Permission Inheritance**:
```
User Notion Account Permissions
        ↓
OAuth Token Permissions (subset of user permissions)
        ↓
Notion MCP Operations (limited by token)
```

**Example**:
- User has "Can Edit" on Ideas Registry → MCP can create/update entries
- User has "Can View" on Financial Data → MCP can read but not modify
- User has no access to HR Database → MCP cannot see it

### Database-Level Permissions

**Notion Permission Levels**:

| Level | Read | Create | Update | Delete | Schema Changes |
|-------|------|--------|--------|--------|----------------|
| **Full Access** | ✅ | ✅ | ✅ | ❌* | ❌** |
| **Can Edit** | ✅ | ✅ | ✅ | ❌* | ❌** |
| **Can Comment** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Can View** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **No Access** | ❌ | ❌ | ❌ | ❌ | ❌ |

*Delete intentionally not supported via API
**Schema changes require workspace admin

**Recommended Team Permissions** (Innovation Nexus):

| Database | Developers | Managers | Finance | Executives |
|----------|-----------|----------|---------|------------|
| **Ideas Registry** | Can Edit | Full Access | Can View | Can View |
| **Research Hub** | Can Edit | Can Edit | Can View | Can View |
| **Example Builds** | Can Edit | Can Edit | Can View | Can View |
| **Software & Cost Tracker** | Can Edit | Full Access | Full Access | Can View |
| **Knowledge Vault** | Can Edit | Can Edit | Can View | Can View |

### Audit Logging

**Notion Activity Log** (Workspace Settings):
- All MCP operations logged as user actions
- Visible in workspace activity feed
- Includes: Create, update, search operations
- Retains 90 days of history (Team plan)

**Monitoring MCP Operations**:

```python
import logging
from datetime import datetime

# Configure logging for Notion MCP operations
logging.basicConfig(
    filename=f'notion_mcp_{datetime.now().strftime("%Y%m%d")}.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def notion_create_with_logging(parent, pages):
    """
    Create Notion pages with audit trail logging.

    Best for: Compliance tracking and operational monitoring.
    """
    try:
        logging.info(f"Creating {len(pages)} pages in {parent}")
        result = notion_create_pages(parent=parent, pages=pages)
        logging.info(f"Successfully created pages: {result}")
        return result
    except Exception as e:
        logging.error(f"Failed to create pages: {e}", exc_info=True)
        raise
```

**Compliance Considerations**:
- Notion MCP operations count as "user actions" for GDPR/CCPA
- Audit logs show who (OAuth user) performed what action
- Database changes tracked in Notion page history
- Cannot bypass Notion's built-in audit trail

---

## Troubleshooting Guide

### Common Issues & Resolutions

#### Issue 1: "Notion MCP Not Connected"

**Symptoms**:
```bash
$ claude mcp list
notion: https://mcp.notion.com/mcp (HTTP) - ✗ Disconnected
```

**Root Causes & Solutions**:

1. **First-time setup, no OAuth token**:
   ```bash
   # Solution: Launch Claude Code, authenticate when prompted
   claude
   # Browser opens → Grant workspace access → Token stored
   ```

2. **OAuth token expired**:
   ```bash
   # Solution: Re-authenticate
   rm ~/.claude/mcp-credentials.json
   claude  # Triggers new OAuth flow
   ```

3. **Network connectivity issue**:
   ```bash
   # Verify internet connection
   curl -I https://mcp.notion.com/mcp

   # Expected: HTTP/2 200 or 401 (401 = server reachable but auth needed)
   # If timeout or DNS error → Network issue
   ```

4. **Workspace permissions revoked**:
   - Check Notion → Settings & Members → Integrations
   - Verify "Claude Code" integration is active
   - Re-grant permissions if removed

#### Issue 2: "Database Not Found" or "Access Denied"

**Symptoms**:
```bash
notion-fetch "collection://984a4038-3e45-4a98-8df4-fd64dd8a1032"
Error: Database not found or insufficient permissions
```

**Root Causes & Solutions**:

1. **Wrong data source ID**:
   ```bash
   # Verify database exists and you have access
   notion-search "Ideas Registry"
   # Use notion-fetch on page URL to extract correct data source ID
   notion-fetch "https://www.notion.so/c17ec2eb9555449eaa34edba4f0c7b60"
   ```

2. **User lacks database permissions**:
   - Check Notion → Database → Share settings
   - Verify your account has at least "Can View" permission
   - Contact workspace admin to grant access

3. **Database deleted or archived**:
   - Search Notion workspace manually
   - Check trash/archive for database
   - Update documentation if database moved

#### Issue 3: "Rate Limit Exceeded" (429 Error)

**Symptoms**:
```bash
Error: Too Many Requests (429)
```

**Root Causes & Solutions**:

1. **Too many rapid requests**:
   ```python
   # Implement retry with exponential backoff
   import time

   def safe_notion_query(query, max_retries=3):
       for attempt in range(max_retries):
           try:
               return notion_search(query)
           except Exception as e:
               if "429" in str(e):
                   wait = 2 ** attempt  # 1s, 2s, 4s
                   time.sleep(wait)
               else:
                   raise
   ```

2. **Multiple processes using same OAuth token**:
   - Limit to 3 requests/second across all processes
   - Coordinate between team members if sharing workspace
   - Consider batching operations

3. **Large batch operations**:
   ```python
   # Split large operations
   items = [...1000 items...]

   # ❌ Single large request
   notion_create_pages(pages=items)

   # ✅ Batched requests
   batch_size = 10
   for i in range(0, len(items), batch_size):
       batch = items[i:i+batch_size]
       notion_create_pages(pages=batch)
       time.sleep(0.5)  # Rate limiting
   ```

#### Issue 4: "OAuth Token Refresh Failed"

**Symptoms**:
```bash
Warning: Failed to refresh Notion OAuth token
Please re-authenticate
```

**Root Causes & Solutions**:

1. **Refresh token expired**:
   ```bash
   # Delete credentials, re-authenticate
   rm ~/.claude/mcp-credentials.json
   claude  # Triggers OAuth flow
   ```

2. **Workspace integration revoked**:
   - Check Notion → Settings & Members → Integrations
   - Look for "Claude Code" integration
   - If removed: Re-authenticate to re-grant

3. **Network issue during refresh**:
   ```bash
   # Verify Notion API reachable
   curl -I https://api.notion.com

   # If timeout: Network issue, try again when connection restored
   ```

#### Issue 5: "Multiple Repositories Not Sharing Authentication"

**Symptoms**:
- Innovation Nexus repository: Notion MCP works ✅
- Project-Ascension repository: Notion MCP requires re-auth ❌

**Root Causes & Solutions**:

1. **Different machine/user profile**:
   - OAuth tokens stored in `~/.claude/mcp-credentials.json`
   - If different home directory → Different credentials
   - Solution: Authenticate on each machine

2. **Corrupted credentials file**:
   ```bash
   # Verify credentials file exists and is readable
   cat ~/.claude/mcp-credentials.json

   # If corrupted or missing: Re-authenticate
   rm ~/.claude/mcp-credentials.json
   claude
   ```

3. **Repository-specific MCP config overriding global**:
   ```bash
   # Check for conflicting .mcp.json
   cat .mcp.json

   # Ensure Notion MCP uses HTTP transport, not stdio
   # Correct: "url": "https://mcp.notion.com/mcp"
   # Incorrect: "command": "notion-mcp" (doesn't exist)
   ```

#### Issue 6: "Search Returns No Results"

**Symptoms**:
```bash
notion-search "Ideas Registry"
# Returns empty results despite database existing
```

**Root Causes & Solutions**:

1. **Search query too specific**:
   ```bash
   # ❌ Too specific
   notion-search "Ideas Registry New Idea Title Exact Match"

   # ✅ Broader query
   notion-search "Ideas Registry"
   ```

2. **Database not indexed**:
   - Notion search may take time to index new databases
   - Try `notion-fetch` with exact database URL instead

3. **User permissions insufficient**:
   - Can only search content you have access to
   - Check database share settings

### Diagnostic Commands

**Comprehensive Health Check**:

```bash
# 1. Verify MCP servers connected
claude mcp list

# Expected Output:
# notion: https://mcp.notion.com/mcp (HTTP) - ✓ Connected
# github: npx -y @modelcontextprotocol/server-github - ✓ Connected
# azure: npx -y @azure/mcp@latest server start - ✓ Connected
# playwright: npx @playwright/mcp@latest --browser msedge --headless - ✓ Connected

# 2. Test Notion connectivity
notion-search "test query"

# 3. Verify workspace access
notion-search "Ideas Registry"
notion-search "Research Hub"
notion-search "Example Builds"

# 4. Test database fetch
notion-fetch "collection://984a4038-3e45-4a98-8df4-fd64dd8a1032"

# 5. Check credentials file
ls -la ~/.claude/mcp-credentials.json

# 6. Test create operation (if permissions allow)
# (Manual test in Claude Code session)
```

**Log Collection** (for debugging):

```bash
# Enable verbose MCP logging
export MCP_DEBUG=1

# Launch Claude Code
claude

# Check Claude Code logs (location varies by OS)
# macOS/Linux: ~/.local/state/claude-code/logs/
# Windows: %APPDATA%\Claude Code\logs\

# Look for Notion MCP connection logs
grep -i "notion" ~/.local/state/claude-code/logs/mcp-*.log
```

---

## Testing & Validation

### Test Suite: Notion MCP Connectivity

Create this test script to validate Notion MCP setup across repositories:

```bash
# File: .claude/utils/test-notion-mcp.sh

#!/bin/bash
# Notion MCP Connectivity Test Suite
# Purpose: Validate Notion MCP authentication and database access

set -e  # Exit on error

echo "🧪 Notion MCP Connectivity Test Suite"
echo "======================================"
echo ""

# Test 1: MCP Server Connection
echo "Test 1: MCP Server Connection Status"
if claude mcp list | grep -q "notion.*✓ Connected"; then
    echo "✅ PASS: Notion MCP server connected"
else
    echo "❌ FAIL: Notion MCP server not connected"
    echo "   Solution: Run 'claude' and authenticate when prompted"
    exit 1
fi
echo ""

# Test 2: Workspace Search
echo "Test 2: Workspace-Level Search"
if notion-search "Ideas Registry" | grep -q "Ideas"; then
    echo "✅ PASS: Workspace search functional"
else
    echo "⚠️  WARN: No results for 'Ideas Registry' search"
    echo "   This may be expected if database doesn't exist yet"
fi
echo ""

# Test 3: Database Fetch (Ideas Registry)
echo "Test 3: Ideas Registry Database Access"
IDEAS_DS="collection://984a4038-3e45-4a98-8df4-fd64dd8a1032"
if notion-fetch "$IDEAS_DS" | grep -q "Ideas"; then
    echo "✅ PASS: Ideas Registry accessible"
else
    echo "❌ FAIL: Cannot access Ideas Registry"
    echo "   Verify data source ID and permissions"
fi
echo ""

# Test 4: Research Hub Database
echo "Test 4: Research Hub Database Access"
RESEARCH_DS="collection://91e8beff-af94-4614-90b9-3a6d3d788d4a"
if notion-fetch "$RESEARCH_DS" | grep -q "Research"; then
    echo "✅ PASS: Research Hub accessible"
else
    echo "⚠️  WARN: Cannot access Research Hub"
fi
echo ""

# Test 5: Example Builds Database
echo "Test 5: Example Builds Database Access"
BUILDS_DS="collection://a1cd1528-971d-4873-a176-5e93b93555f6"
if notion-fetch "$BUILDS_DS" | grep -q "Build"; then
    echo "✅ PASS: Example Builds accessible"
else
    echo "⚠️  WARN: Cannot access Example Builds"
fi
echo ""

# Test 6: Software & Cost Tracker
echo "Test 6: Software & Cost Tracker Database Access"
SOFTWARE_DS="collection://13b5e9de-2dd1-45ec-839a-4f3d50cd8d06"
if notion-fetch "$SOFTWARE_DS" | grep -q "Software"; then
    echo "✅ PASS: Software & Cost Tracker accessible"
else
    echo "⚠️  WARN: Cannot access Software & Cost Tracker"
fi
echo ""

# Test 7: OAuth Token Expiration Check
echo "Test 7: OAuth Token Expiration Status"
if [ -f ~/.claude/mcp-credentials.json ]; then
    EXPIRES_AT=$(grep -oP '"expires_at":\s*"\K[^"]+' ~/.claude/mcp-credentials.json | head -1)
    if [ -n "$EXPIRES_AT" ]; then
        echo "✅ PASS: Token expires at $EXPIRES_AT"

        # Check if expiring soon (within 7 days)
        EXPIRES_EPOCH=$(date -d "$EXPIRES_AT" +%s 2>/dev/null || echo "0")
        NOW_EPOCH=$(date +%s)
        DAYS_UNTIL_EXPIRY=$(( ($EXPIRES_EPOCH - $NOW_EPOCH) / 86400 ))

        if [ $DAYS_UNTIL_EXPIRY -lt 7 ]; then
            echo "⚠️  WARN: Token expiring in $DAYS_UNTIL_EXPIRY days"
            echo "   Claude Code will auto-refresh soon"
        fi
    else
        echo "⚠️  WARN: Cannot parse token expiration"
    fi
else
    echo "❌ FAIL: No credentials file found"
    echo "   Run 'claude' to authenticate"
    exit 1
fi
echo ""

# Summary
echo "======================================"
echo "✅ Test Suite Complete"
echo ""
echo "Next Steps:"
echo "  - If all tests passed: Notion MCP fully operational"
echo "  - If warnings: Check database permissions in Notion"
echo "  - If failures: Re-authenticate with 'claude' command"
echo ""
```

**Usage**:

```bash
# Make executable
chmod +x .claude/utils/test-notion-mcp.sh

# Run test suite
./.claude/utils/test-notion-mcp.sh
```

### Integration Test: Create Test Idea

```python
# File: .claude/utils/test_notion_integration.py

"""
Notion MCP Integration Test
Purpose: Validate end-to-end create/search/update operations
"""

import subprocess
import json
from datetime import datetime

def run_notion_command(command: str) -> dict:
    """Execute Notion MCP command via Claude Code"""
    result = subprocess.run(
        ["claude", "mcp", "call", "notion", command],
        capture_output=True,
        text=True
    )
    return json.loads(result.stdout) if result.returncode == 0 else None

def test_create_search_update():
    """Test full CRUD workflow"""

    print("🧪 Notion MCP Integration Test: Create → Search → Update")
    print("=" * 60)

    # Test data
    test_title = f"Test Idea {datetime.now().strftime('%Y%m%d-%H%M%S')}"
    ideas_ds = "984a4038-3e45-4a98-8df4-fd64dd8a1032"

    # Step 1: Create test idea
    print("\n1️⃣  Creating test idea...")
    create_result = run_notion_command(f"""
        notion-create-pages --parent '{{"data_source_id": "{ideas_ds}"}}' --pages '[{{
            "properties": {{"title": "{test_title}", "Status": "Concept"}},
            "content": "Automated test idea - safe to delete"
        }}]'
    """)

    if create_result:
        print(f"   ✅ Created: {test_title}")
        page_id = create_result.get("id")
    else:
        print("   ❌ FAIL: Could not create test idea")
        return False

    # Step 2: Search for created idea
    print("\n2️⃣  Searching for test idea...")
    search_result = run_notion_command(f'notion-search "{test_title}"')

    if search_result and len(search_result.get("results", [])) > 0:
        print(f"   ✅ Found: {test_title}")
    else:
        print("   ❌ FAIL: Could not find created idea")
        return False

    # Step 3: Update idea status
    print("\n3️⃣  Updating idea status...")
    update_result = run_notion_command(f"""
        notion-update-page --page-id "{page_id}" --data '{{
            "command": "update_properties",
            "properties": {{"Status": "Archived"}}
        }}'
    """)

    if update_result:
        print("   ✅ Updated status to Archived")
    else:
        print("   ❌ FAIL: Could not update idea")
        return False

    # Step 4: Verify update
    print("\n4️⃣  Verifying update...")
    verify_result = run_notion_command(f'notion-fetch "{page_id}"')

    if verify_result and "Archived" in str(verify_result):
        print("   ✅ Verified: Status = Archived")
    else:
        print("   ⚠️  WARN: Could not verify update")

    print("\n" + "=" * 60)
    print("✅ Integration Test Complete")
    print(f"\n📝 Test idea created: {test_title}")
    print(f"   Status: Archived (safe to delete manually)")
    print(f"   Page ID: {page_id}")

    return True

if __name__ == "__main__":
    success = test_create_search_update()
    exit(0 if success else 1)
```

**Usage**:

```bash
# Run integration test
python .claude/utils/test_notion_integration.py
```

---

## Quick Reference

### Essential Commands

```bash
# Verify MCP connection
claude mcp list

# Search workspace
notion-search "query text"

# Fetch database
notion-fetch "collection://<data-source-id>"

# Create database entry
notion-create-pages --parent '{"data_source_id": "..."}' --pages '[...]'

# Update page
notion-update-page --page-id "..." --data '{"command": "update_properties", ...}'

# Test suite
./.claude/utils/test-notion-mcp.sh
```

### Database IDs (Brookside BI Workspace)

```
Ideas Registry:    984a4038-3e45-4a98-8df4-fd64dd8a1032
Research Hub:      91e8beff-af94-4614-90b9-3a6d3d788d4a
Example Builds:    a1cd1528-971d-4873-a176-5e93b93555f6
Software Tracker:  13b5e9de-2dd1-45ec-839a-4f3d50cd8d06
```

### Configuration Files

```
Global MCP:            ~/.config/claude-code/mcp_config.json
Global Credentials:    ~/.claude/mcp-credentials.json
Project MCP:           .mcp.json (repository root)
Claude Settings:       .claude/settings.local.json
Database IDs:          CLAUDE.md (documentation)
```

### Troubleshooting Checklist

- [ ] Run `claude mcp list` - All servers ✓ Connected?
- [ ] Check `~/.claude/mcp-credentials.json` exists
- [ ] Verify internet connection to mcp.notion.com
- [ ] Confirm Notion workspace permissions
- [ ] Test with `notion-search "test query"`
- [ ] Re-authenticate if token expired: `rm ~/.claude/mcp-credentials.json && claude`

---

## Conclusion

**Key Takeaways**:

✅ **One-Time Authentication** - OAuth token stored globally, works for all repositories
✅ **Per-Developer Setup** - Each team member authenticates individually on their machine
✅ **Workspace Permissions** - MCP inherits user's Notion access level
✅ **Secure by Default** - Tokens never committed to Git, automatic refresh
✅ **Rate Limiting** - 3 requests/second, implement retry logic for robust operations

**Next Steps**:

1. **Innovation Nexus** (current repo): Already configured ✅
2. **Project-Ascension**: Copy `.mcp.json`, authenticate on first launch
3. **Future Repositories**: Reuse same `.mcp.json` template
4. **Team Onboarding**: Share this guide, each member authenticates individually

**Best for**: Organizations requiring scalable Notion integration across multiple codebases with centralized workspace access, enterprise-grade security, and consistent database operations.

---

**Document Version**: 1.0
**Last Updated**: October 21, 2025
**Maintained by**: Innovation Nexus Team
**Related Resources**:
- [Notion MCP Official Docs](https://mcp.notion.com/docs)
- [CLAUDE.md - Notion Database IDs](../CLAUDE.md#notion-workspace-configuration)
- [Architectural Patterns - Circuit Breaker](.claude/docs/patterns/circuit-breaker.md)
- [Architectural Patterns - Retry with Exponential Backoff](.claude/docs/patterns/retry-exponential-backoff.md)
