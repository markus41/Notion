# Brookside BI Innovation Nexus - Setup Scripts

This directory contains environment setup and configuration scripts for the Innovation Nexus repository.

## Available Scripts

### Linux/macOS

#### `setup-environment.sh`
**Purpose**: Configure complete environment for Claude Code with MCP servers on Linux/Unix systems

**Usage**:
```bash
# Run the setup script
source scripts/setup-environment.sh

# Or make it executable and run
chmod +x scripts/setup-environment.sh
bash scripts/setup-environment.sh
```

**What it does**:
- ✓ Checks prerequisites (Node.js, Git, Azure CLI)
- ✓ Sets environment variables for Azure, Notion, and GitHub
- ✓ Verifies Azure authentication status
- ✓ Checks Git configuration
- ✓ Makes repository hooks executable
- ✓ Validates MCP configuration files

**Environment Variables Set**:
- `AZURE_TENANT_ID` - Azure tenant identifier
- `AZURE_SUBSCRIPTION_ID` - Azure subscription identifier
- `AZURE_KEYVAULT_NAME` - Key Vault name for secrets
- `AZURE_KEYVAULT_URI` - Key Vault endpoint URI
- `NOTION_WORKSPACE_ID` - Notion workspace identifier
- `NOTION_DATABASE_ID_IDEAS` - Ideas Registry database ID
- `NOTION_DATABASE_ID_RESEARCH` - Research Hub database ID
- `NOTION_DATABASE_ID_BUILDS` - Example Builds database ID
- `NOTION_DATABASE_ID_SOFTWARE` - Software & Cost Tracker database ID
- `GITHUB_ORG` - GitHub organization name

### Windows (PowerShell)

#### `Get-KeyVaultSecret.ps1`
**Purpose**: Retrieve individual secrets from Azure Key Vault

**Usage**:
```powershell
# Retrieve GitHub PAT
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token"

# Custom vault name
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "notion-api-key" -VaultName "kv-brookside-secrets"
```

#### `Set-MCPEnvironment.ps1`
**Purpose**: Configure all MCP environment variables from Key Vault

**Usage**:
```powershell
# Set for current PowerShell session
.\scripts\Set-MCPEnvironment.ps1

# Set persistent user-level environment variables
.\scripts\Set-MCPEnvironment.ps1 -Persistent
```

#### `Test-AzureMCP.ps1`
**Purpose**: Validate Azure MCP server configuration

**Usage**:
```powershell
# Test Azure CLI authentication and MCP server
.\scripts\Test-AzureMCP.ps1
```

## Prerequisites

### All Platforms
- **Node.js** 18.0.0 or higher
- **Git** 2.0 or higher
- **Claude Code** (latest version)

### For Azure Integration
- **Azure CLI** 2.50.0 or higher

### Installation Instructions

#### Azure CLI (Linux)
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

For other Linux distributions, see: https://docs.microsoft.com/cli/azure/install-azure-cli-linux

#### Azure CLI (macOS)
```bash
brew update && brew install azure-cli
```

#### Azure CLI (Windows)
Download installer from: https://aka.ms/installazurecliwindows

## Quick Start

### Linux/macOS Setup

1. **Run environment setup**:
   ```bash
   source scripts/setup-environment.sh
   ```

2. **Install Azure CLI** (if not already installed):
   ```bash
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```

3. **Authenticate to Azure**:
   ```bash
   az login
   az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
   ```

4. **Configure Git** (if needed):
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@brooksidebi.com"
   ```

5. **Verify MCP servers**:
   ```bash
   claude mcp list
   ```

### Windows Setup

1. **Authenticate to Azure**:
   ```powershell
   az login
   az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
   ```

2. **Configure MCP environment**:
   ```powershell
   .\scripts\Set-MCPEnvironment.ps1
   ```

3. **Test Azure MCP**:
   ```powershell
   .\scripts\Test-AzureMCP.ps1
   ```

4. **Configure Git**:
   ```powershell
   git config --global user.name "Your Name"
   git config --global user.email "your.email@brooksidebi.com"
   ```

5. **Verify MCP servers**:
   ```powershell
   claude mcp list
   ```

## Troubleshooting

### Azure CLI Not Found
**Linux/macOS**:
```bash
# Install via script
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verify installation
az --version
```

**Windows**:
- Download installer from https://aka.ms/installazurecliwindows
- Run installer and restart terminal

### Azure Authentication Failed
```bash
# Re-authenticate
az login

# Verify account
az account show

# Check Key Vault access
az keyvault secret list --vault-name kv-brookside-secrets
```

### Git Configuration Missing
```bash
# Set user information
git config --global user.name "Your Name"
git config --global user.email "your.email@brooksidebi.com"

# Verify configuration
git config --global --list
```

### MCP Servers Not Connecting
1. **Check configuration files**:
   ```bash
   cat .mcp.json
   cat .claude/settings.local.json
   ```

2. **Verify environment variables**:
   ```bash
   # Linux/macOS
   env | grep -E "AZURE|NOTION|GITHUB"

   # Windows
   Get-ChildItem Env: | Where-Object { $_.Name -match "AZURE|NOTION|GITHUB" }
   ```

3. **Test MCP connectivity**:
   ```bash
   claude mcp list
   ```

### Repository Hooks Not Working
```bash
# Make hooks executable (Linux/macOS)
chmod +x .claude/hooks/*.sh

# Verify hooks are executable
ls -la .claude/hooks/
```

## Environment Variables Reference

| Variable | Purpose | Example Value |
|----------|---------|---------------|
| `AZURE_TENANT_ID` | Azure AD tenant identifier | `2930489e-9d8a-456b-9de9-e4787faeab9c` |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription identifier | `cfacbbe8-a2a3-445f-a188-68b3b35f0c84` |
| `AZURE_KEYVAULT_NAME` | Key Vault name | `kv-brookside-secrets` |
| `AZURE_KEYVAULT_URI` | Key Vault endpoint | `https://kv-brookside-secrets.vault.azure.net/` |
| `NOTION_WORKSPACE_ID` | Notion workspace identifier | `81686779-099a-8195-b49e-00037e25c23e` |
| `NOTION_DATABASE_ID_IDEAS` | Ideas Registry database | `984a4038-3e45-4a98-8df4-fd64dd8a1032` |
| `NOTION_DATABASE_ID_RESEARCH` | Research Hub database | `91e8beff-af94-4614-90b9-3a6d3d788d4a` |
| `NOTION_DATABASE_ID_BUILDS` | Example Builds database | `a1cd1528-971d-4873-a176-5e93b93555f6` |
| `NOTION_DATABASE_ID_SOFTWARE` | Software Tracker database | `13b5e9de-2dd1-45ec-839a-4f3d50cd8d06` |
| `GITHUB_ORG` | GitHub organization | `brookside-bi` |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | GitHub PAT (from Key Vault) | Retrieved dynamically |

## Security Notes

### Credential Management

**DO**:
- ✓ Use `scripts/Get-KeyVaultSecret.ps1` to retrieve secrets (Windows)
- ✓ Use `az keyvault secret show` to retrieve secrets (Linux)
- ✓ Reference Key Vault in documentation, never actual values
- ✓ Use environment variables from setup scripts
- ✓ Authenticate with `az login` before accessing Key Vault

**DON'T**:
- ✗ Never commit secrets to Git
- ✗ Never display secrets in output or logs
- ✗ Never hardcode credentials in code or documentation
- ✗ Never store secrets in plain text files

### Repository Hooks

The repository includes security hooks that automatically:
- **Pre-commit validation**: Check for secrets, large files, protected branches
- **Commit message validation**: Enforce Conventional Commits and Brookside BI branding
- **Branch protection**: Prevent force push to main/master/production
- **Destructive operation warnings**: Warn before reset --hard, clean -fd, etc.

These hooks are configured in `.claude/settings.local.json` and execute automatically when using Claude Code.

## Additional Resources

- **Main Documentation**: `CLAUDE.md` - Comprehensive project overview
- **Hook Documentation**: `.claude/hooks/README.md` - Repository hooks guide
- **Quick Reference**: `.claude/hooks/QUICK-REFERENCE.md` - Common operations

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review `CLAUDE.md` for detailed configuration
3. Verify prerequisites are installed and up to date
4. Check `.claude/settings.local.json` for hook configurations

---

**Brookside BI Innovation Nexus** - Streamline innovation workflows with structured approaches that drive measurable outcomes.
