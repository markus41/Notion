# MCP Server Quick Reference Card

**Purpose**: Fast-access reference for daily MCP operations and troubleshooting.

---

## Daily Workflow

```powershell
# 1. Authenticate to Azure (once per session)
az login

# 2. Set environment variables (before launching Claude Code)
.\scripts\Set-MCPEnvironment.ps1

# 3. Launch Claude Code
cd C:\Path\To\Your\Repository
claude

# 4. Verify MCP connectivity (in Claude Code)
claude mcp list
```

---

## Common Operations

### Notion MCP

```bash
# Search workspace
notion-search "search query"

# Fetch specific page
notion-fetch "page-url-or-id"

# Create page
notion-create-page --parent "parent-id" --title "Page Title"

# Update page
notion-update-page "page-id" --content "Updated content"
```

### GitHub MCP

```bash
# List repositories
gh repo list brookside-bi

# Create repository
gh repo create brookside-bi/new-repo --private

# View file contents
gh api repos/brookside-bi/repo-name/contents/path/to/file

# Create pull request
gh pr create --title "PR Title" --body "Description"
```

### Azure MCP

```bash
# List subscriptions
az account list

# Show current subscription
az account show

# List resource groups
az group list

# Get Key Vault secret
az keyvault secret show --vault-name kv-brookside-secrets --name secret-name
```

### Playwright MCP

```bash
# Browser operations executed via Claude Code MCP interface
# Navigate to URL
# Take screenshot
# Fill form
# Click element
```

---

## Troubleshooting

### MCP Server Not Connected

```powershell
# Check MCP status
claude mcp list

# If any show "not connected":

# 1. Restart Claude Code
exit
claude

# 2. Re-authenticate if needed
az login                          # Azure
.\scripts\Set-MCPEnvironment.ps1  # GitHub

# 3. Complete OAuth flow (Notion - follow browser prompt)
```

### GitHub PAT Not Working

```powershell
# Re-retrieve from Key Vault
$env:GITHUB_PERSONAL_ACCESS_TOKEN = az keyvault secret show `
    --vault-name kv-brookside-secrets `
    --name github-personal-access-token `
    --query value -o tsv

# Verify it's set
echo $env:GITHUB_PERSONAL_ACCESS_TOKEN

# Restart Claude Code
```

### Azure CLI Not Authenticated

```powershell
# Re-login
az login

# Set subscription
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"

# Verify
az account show
```

### Notion OAuth Expired

```
1. Trigger any Notion operation in Claude Code
2. Follow browser OAuth prompt
3. Grant workspace access
4. Return to Claude Code
```

---

## Script Locations

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/Initialize-MCPConfig.ps1` | Deploy MCP to new repository | `.\Initialize-MCPConfig.ps1 -TargetRepository "path"` |
| `scripts/Set-MCPEnvironment.ps1` | Set environment variables | `.\Set-MCPEnvironment.ps1` |
| `scripts/Test-MCPServers.ps1` | Validate MCP connectivity | `.\Test-MCPServers.ps1` |
| `scripts/Get-KeyVaultSecret.ps1` | Get single secret | `.\Get-KeyVaultSecret.ps1 -SecretName "name"` |

---

## Environment Variables

| Variable | Source | Used By |
|----------|--------|---------|
| `GITHUB_PERSONAL_ACCESS_TOKEN` | Key Vault | GitHub MCP |
| `NOTION_API_KEY` | Key Vault | Notion MCP (fallback) |
| `NOTION_WORKSPACE_ID` | Config file | Notion MCP |
| `AZURE_TENANT_ID` | Config file | Azure MCP |
| `AZURE_SUBSCRIPTION_ID` | Config file | Azure MCP |

---

## Configuration Files

| File | Location | Purpose |
|------|----------|---------|
| `.claude/settings.local.json` | Repository root | MCP server configuration |
| `.claude/.credentials.json` | User home (~/.claude/) | OAuth tokens (auto-managed) |
| `.claude/templates/mcp-config-template.json` | Innovation Nexus | Template for new deployments |

---

## Support Resources

- **Deployment Guide**: `.claude/docs/MCP_DEPLOYMENT_GUIDE.md`
- **Strategy Document**: `.claude/docs/MCP_STANDARDIZATION_STRATEGY.md`
- **Azure Key Vault**: `https://kv-brookside-secrets.vault.azure.net/`
- **GitHub Organization**: `https://github.com/brookside-bi`

---

## Emergency Contacts

- **Azure Administrator**: [Contact Info]
- **GitHub Admin**: [Contact Info]
- **DevOps Lead**: [Contact Info]

---

**Best for**: Quick reference during daily development work.
**Designed for**: Brookside BI team members using MCP-enabled repositories.
