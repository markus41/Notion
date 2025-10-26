# GitHub MCP Integration - Secure Configuration

**Status:** ✅ Active
**Created:** 2025-10-21
**Last Updated:** 2025-10-21
**Owner:** Markus Ahling

## Overview

This solution establishes secure GitHub integration for Claude Code through the Model Context Protocol (MCP), using Azure Key Vault for credential management. This approach is designed to streamline development workflows while maintaining enterprise-grade security across all Brookside BI innovation projects.

**Best for:** Organizations requiring secure, scalable GitHub integration with centralized secret management.

## Architecture

```
┌─────────────────┐
│  Claude Code    │
│  MCP Client     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────────┐
│  GitHub MCP     │◄─────┤ Environment Var  │
│  Server (stdio) │      │ GITHUB_PAT       │
└────────┬────────┘      └────────┬─────────┘
         │                         │
         │                         │
         ▼                         ▼
┌─────────────────┐      ┌──────────────────┐
│  GitHub API     │      │ Azure Key Vault  │
│  (REST)         │      │ kv-brookside-*   │
└─────────────────┘      └──────────────────┘
```

## GitHub Personal Access Token

### Token Details

- **Name:** kv-brookside-secrets
- **Type:** Personal Access Token (Classic)
- **Expiration:** November 20, 2025
- **Scope:** All repositories in authenticated user's access

### Comprehensive Permissions (30 Total)

This token grants full read/write access across all GitHub repository operations:

#### Repository Content & Code
- **Contents:** Read and write - Clone, commit, push, pull, file operations
- **Commit statuses:** Read and write - Update build/test status indicators
- **Metadata:** Read-only - Repository metadata and webhook signatures

#### Actions & Automation
- **Actions:** Read and write - Manage GitHub Actions workflows
- **Variables:** Read and write - Set repository variables for Actions
- **Workflows:** Read and write - Create, update, delete workflow files
- **Secrets:** Read and write - Manage Actions secrets
- **Environments:** Read and write - Manage deployment environments

#### Collaboration & Project Management
- **Pull requests:** Read and write - Create, review, merge, close PRs
- **Issues:** Read and write - Create, update, close, label issues
- **Discussions:** Read and write - Participate in repository discussions
- **Merge queues:** Read and write - Manage merge queue operations

#### CI/CD & Deployments
- **Deployments:** Read and write - Create and manage deployments
- **Pages:** Read and write - Manage GitHub Pages configuration

#### Security & Compliance
- **Secret scanning alerts:** Read and write - View and manage secret alerts
- **Secret scanning alert dismissal requests:** Read and write
- **Secret scanning push protection bypass requests:** Read and write
- **Code scanning alerts:** Read and write - Manage code analysis alerts
- **Dependabot alerts:** Read and write - View and manage dependency alerts
- **Dependabot secrets:** Read and write - Manage Dependabot credentials
- **Repository security advisories:** Read and write - Create and publish advisories
- **Attestations:** Read and write - Manage artifact attestations

#### Advanced Configuration
- **Administration:** Read and write - Repository settings and configuration
- **Custom properties:** Read and write - Manage custom repository properties
- **Webhooks:** Read and write - Create and manage webhook integrations
- **Artifact metadata:** Read and write - Manage GitHub Actions artifacts

#### Developer Environment
- **Codespaces:** Read and write - Create and manage Codespaces
- **Codespaces lifecycle admin:** Read and write - Full Codespaces management
- **Codespaces metadata:** Read-only - View Codespaces configuration
- **Codespaces secrets:** Read and write - Manage Codespaces secrets

## Azure Key Vault Configuration

### Key Vault Details

- **Name:** kv-brookside-secrets
- **Resource Group:** rg-brookside-prod
- **Location:** West US
- **URI:** https://kv-brookside-secrets.vault.azure.net/
- **Soft Delete:** Enabled (90-day retention)
- **Access Model:** Access policies (RBAC disabled)

### Stored Secrets

| Secret Name | Environment Variable | Purpose | Expiration |
|-------------|---------------------|---------|------------|
| `github-personal-access-token` | `GITHUB_PERSONAL_ACCESS_TOKEN` | GitHub API authentication | 2025-11-20 |

### Access Permissions

**Current User:** Markus@BrooksideBI.com
- Certificates: All permissions
- Keys: All permissions
- Secrets: All permissions
- Storage: All permissions

## Environment Setup

### Persistent Configuration (Recommended)

The environment variable has been set at the User level and persists across sessions:

```powershell
# Already configured - no action needed
$env:GITHUB_PERSONAL_ACCESS_TOKEN
# Value retrieved from: kv-brookside-secrets/secrets/github-personal-access-token
```

### Manual Refresh (If Needed)

To retrieve updated secrets from Key Vault:

```powershell
# Run from repository root
.\scripts\Set-MCPEnvironment.ps1 -Persistent
```

### Session-Only Setup (Development)

For temporary session-only variables:

```powershell
.\scripts\Set-MCPEnvironment.ps1
```

## MCP Server Configuration

### Current Configuration

The GitHub MCP server is configured in `.claude.json` (project-specific):

```json
{
  "mcpServers": {
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {}
    }
  }
}
```

**Note:** Empty `env` object allows inheritance of system environment variables.

### Verification

Check MCP server health:

```bash
claude mcp list
```

Expected output:
```
github: npx -y @modelcontextprotocol/server-github (stdio) - ✓ Connected
notion: https://mcp.notion.com/mcp (HTTP) - ✓ Connected
```

## GitHub MCP Capabilities

With the comprehensive token permissions, the GitHub MCP can perform:

### Repository Operations
- Clone, fork, and create repositories
- Read and write file contents
- Commit changes and push to branches
- Create and manage branches and tags

### Pull Request Workflow
- Create pull requests
- Review and comment on PRs
- Approve or request changes
- Merge pull requests
- Manage PR labels and assignees

### Issue Management
- Create and update issues
- Add labels, milestones, assignees
- Close and reopen issues
- Search and filter issues

### GitHub Actions Integration
- Read workflow definitions
- Trigger workflow runs
- View workflow status and logs
- Manage secrets and variables
- Configure deployment environments

### Security Operations
- View and manage security alerts
- Access Dependabot findings
- Review code scanning results
- Manage secret scanning alerts
- Create security advisories

### Advanced Features
- Manage GitHub Pages deployments
- Configure webhooks
- Manage Codespaces
- Handle artifact metadata
- Set custom repository properties

## Security Considerations

### Token Rotation

**⚠️ Important:** Token expires on November 20, 2025

Renewal procedure:
1. Generate new GitHub Personal Access Token
2. Update Key Vault secret:
   ```bash
   az keyvault secret set \
     --vault-name kv-brookside-secrets \
     --name github-personal-access-token \
     --value "<new-token>"
   ```
3. Refresh environment variable:
   ```powershell
   .\scripts\Set-MCPEnvironment.ps1 -Persistent
   ```
4. Restart Claude Code

### Access Control

- Key Vault access controlled via Azure AD
- Only authorized users can retrieve secrets
- Audit logs available in Azure Monitor
- Soft delete prevents accidental loss

### Best Practices

✅ **Do:**
- Store all sensitive credentials in Key Vault
- Use managed identities when possible
- Rotate tokens before expiration
- Monitor Key Vault access logs
- Limit token scopes to minimum required

❌ **Don't:**
- Hardcode tokens in configuration files
- Share tokens via email or chat
- Commit tokens to version control
- Use the same token across multiple environments
- Ignore expiration warnings

## Troubleshooting

### GitHub MCP Not Connecting

1. **Verify environment variable is set:**
   ```powershell
   $env:GITHUB_PERSONAL_ACCESS_TOKEN
   ```

2. **Check Key Vault access:**
   ```bash
   az keyvault secret show \
     --vault-name kv-brookside-secrets \
     --name github-personal-access-token \
     --query "value"
   ```

3. **Refresh environment variable:**
   ```powershell
   .\scripts\Set-MCPEnvironment.ps1 -Persistent
   ```

4. **Restart Claude Code completely**

### Azure CLI Authentication

If Azure CLI is not authenticated:

```bash
az login
az account set --subscription "Azure subscription 1"
```

### MCP Server Errors

Check MCP server logs:
```bash
claude mcp list --verbose
```

## Integration with Notion MCP

Both MCPs work together to enable:
- Sync GitHub issues to Notion database
- Link GitHub repositories to Example Builds
- Track GitHub commits in Innovation workflow
- Document code in Knowledge Vault

## Future Enhancements

Planned improvements:
- [ ] Add service principal authentication for automation
- [ ] Implement token auto-rotation via Azure Automation
- [ ] Create GitHub webhook → Notion automation
- [ ] Add GitHub Projects integration
- [ ] Set up automated security scanning results sync

## Related Documentation

- [Azure Key Vault Setup](./.claude/NOTION_DATABASE_SETUP.md)
- [Notion MCP Configuration](../CLAUDE.md)
- [Integration Registry](../CLAUDE.md#integration-registry)
- [MCP Server Documentation](https://modelcontextprotocol.io/)

## Support

For issues or questions:
- **Internal:** Markus Ahling (Markus@BrooksideBI.com)
- **GitHub MCP:** https://github.com/modelcontextprotocol/servers
- **Azure Support:** Azure Portal support tickets

---

**Brookside BI Innovation Nexus** - Establish secure, scalable integration infrastructure to streamline development workflows and drive measurable outcomes through structured approaches.
