# Configuration & Environment

**Purpose**: Establish complete environment configuration for Innovation Nexus operations.

**Best for**: Initial setup, troubleshooting environment issues, or configuring new development machines.

---

## Claude Code Settings

### Recommended Configuration

**File**: `.claude/settings.local.json` (git-ignored)

```json
{
  "model": "claude-sonnet-4-5-20250929",
  "cleanupPeriodDays": 90,
  "includeCoAuthoredBy": true,
  "hooks": {
    "Notification": [{"hooks": [{"type": "command", "command": "echo -e '\\a'"}]}],
    "Stop": [{"hooks": [{"type": "command", "command": "echo -e '\\a'"}]}],
    "Tool-call": [{
      "filter": {"toolName": "Task"},
      "hooks": [{"type": "powershell", "command": ".claude/hooks/auto-log-agent-activity.ps1"}]
    }]
  },
  "permissions": {
    "allow": [
      "Bash(claude mcp add:*)",
      "Bash(claude mcp list:*)",
      "Read(C:/Users/MarkusAhling/**)"
    ]
  }
}
```

**Benefits**:
- Terminal bell notifications on completion/stop
- Extended chat history (90 days)
- Co-authored-by attribution in commits
- Pre-approved MCP commands
- Automatic agent activity logging (Phase 4)

---

## Environment Variables

### Required Variables

```bash
# Azure Configuration
AZURE_TENANT_ID=2930489e-9d8a-456b-9de9-e4787faeab9c
AZURE_SUBSCRIPTION_ID=cfacbbe8-a2a3-445f-a188-68b3b35f0c84
AZURE_KEYVAULT_NAME=kv-brookside-secrets

# GitHub Configuration
GITHUB_ORG=brookside-bi
GITHUB_PERSONAL_ACCESS_TOKEN=[From Key Vault - auto-configured]

# Notion Configuration
NOTION_WORKSPACE_ID=81686779-099a-8195-b49e-00037e25c23e
NOTION_API_KEY=[From Key Vault - auto-configured or OAuth]

# Azure OpenAI (if applicable)
AZURE_OPENAI_API_KEY=[From Key Vault - auto-configured]
AZURE_OPENAI_ENDPOINT=[From Key Vault - auto-configured]
```

### Auto-Configuration

**Script**: `.\scripts\Set-MCPEnvironment.ps1`

**Usage**:
```powershell
# Set for current session
.\scripts\Set-MCPEnvironment.ps1

# Set persistently (requires admin)
.\scripts\Set-MCPEnvironment.ps1 -Persistent
```

**What it does**:
1. Authenticates to Azure (if needed)
2. Retrieves all secrets from Key Vault
3. Sets environment variables for current session
4. Optionally sets system-level variables

---

## Repository Hooks

### Phase 3: Repository Safety Hooks

**Purpose**: Prevent security issues and enforce quality standards

#### 1. Pre-Commit Hook
**Location**: `.github/hooks/pre-commit`

**Protections**:
- Secret detection (15+ patterns):
  - Azure connection strings
  - Storage account keys
  - Notion API tokens
  - GitHub PATs
  - Generic API keys (32+ hex chars)
  - Private keys (PEM format)
  - Database connection strings
  - JWT tokens
- Large file prevention (>10MB)
- Binary file warnings

**Auto-install**: Triggered on first commit via `.github/hooks/install-hooks.sh`

#### 2. Commit-Msg Hook
**Location**: `.github/hooks/commit-msg`

**Enforces**:
- Conventional Commits format
- Brookside BI brand voice
- Co-Authored-By attribution
- Claude Code generation attribution

**Format**:
```
<type>(<scope>): <description>

<body>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

#### 3. Tool-Call Hook (Phase 4)
**Location**: `.claude/hooks/auto-log-agent-activity.ps1`

**Purpose**: Automatic agent activity logging

**Triggers**: On Task tool invocations (agent delegations)

**Filtering**:
- ✅ Agent in approved list (27+ specialized agents)
- ✅ Work duration >2 minutes OR files created/updated
- ✅ Not already logged in current session (5-min deduplication)
- ✅ TodoWrite shows meaningful work completion

**Captured Metrics**:
- Files created/updated (categorized)
- Lines generated (estimated)
- Session duration
- Deliverables (organized by category)
- Related Notion items
- Next steps

---

## Database IDs Reference

### Core Databases

```yaml
Ideas Registry:        984a4038-3e45-4a98-8df4-fd64dd8a1032
Research Hub:          91e8beff-af94-4614-90b9-3a6d3d788d4a
Example Builds:        a1cd1528-971d-4873-a176-5e93b93555f6
Software Tracker:      13b5e9de-2dd1-45ec-839a-4f3d50cd8d06
Agent Registry:        5863265b-eeee-45fc-ab1a-4206d8a523c6
Agent Activity Hub:    7163aa38-f3d9-444b-9674-bde61868bd2b
Output Styles Registry: 199a7a80-224c-470b-9c64-7560ea51b257
Agent Style Tests:     b109b417-2e3f-4eba-bab1-9d4c047a65c4

Workspace ID: 81686779-099a-8195-b49e-00037e25c23e
```

**Usage**: Reference these IDs for direct Notion MCP operations

---

## Daily Startup Routine

### Complete Setup (3-5 minutes)

```powershell
# 1. Authenticate to Azure (tokens expire after 24 hours)
az login
az account show  # Verify: cfacbbe8-a2a3-445f-a188-68b3b35f0c84

# 2. Configure MCP environment variables
.\scripts\Set-MCPEnvironment.ps1

# 3. Verify all MCP servers (optional)
.\scripts\Test-AzureMCP.ps1
claude mcp list

# 4. Launch Claude Code
claude
```

**Expected State**:
- ✓ Azure CLI authenticated
- ✓ All environment variables set
- ✓ MCP servers connected (Notion, GitHub, Azure, Playwright)
- ✓ Claude Code ready

---

## PowerShell Scripts

### Available Utilities

| Script | Purpose | Usage |
|--------|---------|-------|
| **Get-KeyVaultSecret.ps1** | Retrieve individual secrets | `.\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token"` |
| **Set-MCPEnvironment.ps1** | Configure all MCP env vars | `.\scripts\Set-MCPEnvironment.ps1 [-Persistent]` |
| **Test-AzureMCP.ps1** | Validate MCP connectivity | `.\scripts\Test-AzureMCP.ps1` |
| **session-parser.ps1** | Parse Claude session context | Used by auto-log-agent-activity.ps1 |
| **invoke-agent.ps1** | Manually invoke agents | `.\scripts\invoke-agent.ps1 -AgentName "cost-analyst"` |
| **statusline.ps1** | Custom status line widget | Configure in settings.json |
| **notion-queries.ps1** | Common Notion queries | `.\scripts\notion-queries.ps1 -Query "unused-software"` |
| **git-status-enhanced.ps1** | Enhanced git status | `.\scripts\git-status-enhanced.ps1` |

---

## Troubleshooting

### Issue: Environment variables not persisting
**Solution**:
```powershell
# Use -Persistent flag (requires admin)
.\scripts\Set-MCPEnvironment.ps1 -Persistent

# Or manually set in system environment variables
```

### Issue: Hooks not executing
**Solution**:
```bash
# Re-install hooks
.github/hooks/install-hooks.sh

# Verify hook permissions (Linux/Mac)
chmod +x .github/hooks/*

# Check hook configuration in settings.local.json
```

### Issue: Azure CLI authentication expired
**Solution**:
```powershell
# Re-authenticate
az login
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
```

### Issue: MCP server not connecting
**Solution**:
```bash
# Check MCP server status
claude mcp list

# Restart specific server
claude mcp restart [server-name]

# Re-authenticate if needed
az login  # For Azure
.\scripts\Set-MCPEnvironment.ps1  # For GitHub/Notion
```

---

## Quick Reference

### Status Emojis
- 🔵 **Concept** - Initial idea capture
- 🟢 **Active** - Currently working
- ⚫ **Not Active** - Paused/on-hold
- ✅ **Completed/Archived** - Finished work

### Viability Emojis
- 💎 **High** - Production ready (75-100)
- ⚡ **Medium** - Needs work (50-74)
- 🔻 **Low** - Reference only (0-49)
- ❓ **Needs Research** - Insufficient data

### Database Formatting
- Ideas: `💡 [Idea Name]`
- Research: `🔬 [Research Topic]`
- Builds: `🛠️ [Build Name]`
- Knowledge: `📚 [Article Name]`

### Cost Analysis Shortcuts
```bash
/cost:monthly-spend                    # Quick total
/cost:annual-projection                # Yearly forecast
/cost:top-expenses                     # Top 5 tools
/cost:microsoft-alternatives [tool]    # M365/Azure replacements
```

---

## Related Resources

**Documentation**:
- [Azure Infrastructure](./azure-infrastructure.md)
- [MCP Configuration](./mcp-configuration.md)
- [Common Workflows](./common-workflows.md)

**Scripts Directory**: `./scripts/`

**Hooks Directory**: `.github/hooks/` (Git hooks), `.claude/hooks/` (Claude hooks)

---

**Last Updated**: 2025-10-26
