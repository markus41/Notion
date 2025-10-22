# Quick Start Guide - Linux Environment

This guide establishes a fully configured development environment for the Brookside BI Innovation Nexus on Linux systems.

## Prerequisites Check

Run this command to verify your system:

```bash
# Check all prerequisites at once
echo "Node.js: $(node --version 2>&1)"
echo "Git: $(git --version 2>&1)"
echo "Azure CLI: $(az --version 2>&1 | head -1)"
```

**Required Versions**:
- Node.js: 18.0.0 or higher
- Git: 2.0 or higher
- Azure CLI: 2.50.0 or higher

## Step-by-Step Setup

### Step 1: Install Azure CLI (if not already installed)

```bash
# Ubuntu/Debian
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verify installation
az --version
```

For other distributions, see: https://docs.microsoft.com/cli/azure/install-azure-cli-linux

### Step 2: Run Environment Setup Script

```bash
# Navigate to repository
cd /home/user/Notion

# Run setup script
source scripts/setup-environment.sh
```

This script will:
- Check all prerequisites
- Set environment variables for Azure, Notion, and GitHub
- Verify Git configuration
- Make repository hooks executable
- Validate MCP configuration

### Step 3: Authenticate to Azure

```bash
# Login to Azure (opens browser)
az login

# Set active subscription
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"

# Verify authentication
az account show

# Test Key Vault access
az keyvault secret list --vault-name kv-brookside-secrets
```

### Step 4: Configure Git (if needed)

```bash
# Set your Git identity
git config --global user.name "Your Name"
git config --global user.email "your.email@brooksidebi.com"

# Verify configuration
git config --global --list
```

### Step 5: Retrieve GitHub Personal Access Token

```bash
# Retrieve GitHub PAT from Azure Key Vault
export GITHUB_PERSONAL_ACCESS_TOKEN=$(az keyvault secret show \
  --vault-name kv-brookside-secrets \
  --name github-personal-access-token \
  --query value -o tsv)

# Verify it's set (don't display the full token)
echo "GitHub PAT length: ${#GITHUB_PERSONAL_ACCESS_TOKEN} characters"
```

### Step 6: Verify MCP Server Connectivity

```bash
# Check MCP server status
claude mcp list
```

**Expected MCP Servers**:
- ✓ azure-ai-foundry (configured in `.mcp.json`)
- ✓ Additional servers may be configured

### Step 7: Test Repository Hooks

```bash
# Test pre-commit validation
bash .claude/hooks/pre-commit-validation.sh

# Test commit message validation
bash .claude/hooks/commit-message-validator.sh

# Test branch protection
bash .claude/hooks/branch-protection.sh check-push
```

## Environment Variables

The setup script configures these environment variables:

```bash
# Azure Configuration
export AZURE_TENANT_ID="2930489e-9d8a-456b-9de9-e4787faeab9c"
export AZURE_SUBSCRIPTION_ID="cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
export AZURE_KEYVAULT_NAME="kv-brookside-secrets"
export AZURE_KEYVAULT_URI="https://kv-brookside-secrets.vault.azure.net/"

# Notion Configuration
export NOTION_WORKSPACE_ID="81686779-099a-8195-b49e-00037e25c23e"
export NOTION_DATABASE_ID_IDEAS="984a4038-3e45-4a98-8df4-fd64dd8a1032"
export NOTION_DATABASE_ID_RESEARCH="91e8beff-af94-4614-90b9-3a6d3d788d4a"
export NOTION_DATABASE_ID_BUILDS="a1cd1528-971d-4873-a176-5e93b93555f6"
export NOTION_DATABASE_ID_SOFTWARE="13b5e9de-2dd1-45ec-839a-4f3d50cd8d06"

# GitHub Configuration
export GITHUB_ORG="brookside-bi"
```

To make these persistent, add them to your `~/.bashrc` or `~/.bash_profile`:

```bash
# Add to ~/.bashrc
echo 'source /home/user/Notion/scripts/setup-environment.sh' >> ~/.bashrc

# Reload
source ~/.bashrc
```

## Verify Complete Setup

Run this verification checklist:

```bash
# 1. Check Azure authentication
az account show

# 2. Test Key Vault access
az keyvault secret list --vault-name kv-brookside-secrets

# 3. Verify environment variables
env | grep -E "AZURE|NOTION|GITHUB" | grep -v TOKEN

# 4. Check Git configuration
git config --global --list

# 5. Test repository hooks
bash .claude/hooks/pre-commit-validation.sh

# 6. Check MCP connectivity
claude mcp list

# 7. View repository status
git status
```

## Daily Workflow

**Every time you start a new session**:

```bash
# 1. Navigate to repository
cd /home/user/Notion

# 2. Ensure Azure authentication is active
az account show

# 3. Set environment variables (if not in ~/.bashrc)
source scripts/setup-environment.sh

# 4. Start working
git status
git branch
```

## Retrieving Secrets from Key Vault

### GitHub Personal Access Token

```bash
# Retrieve and export
export GITHUB_PERSONAL_ACCESS_TOKEN=$(az keyvault secret show \
  --vault-name kv-brookside-secrets \
  --name github-personal-access-token \
  --query value -o tsv)
```

### Notion API Key (when needed)

```bash
# Retrieve Notion API key
export NOTION_API_KEY=$(az keyvault secret show \
  --vault-name kv-brookside-secrets \
  --name notion-api-key \
  --query value -o tsv)
```

### Azure OpenAI Key (when configured)

```bash
# Retrieve Azure OpenAI key
export AZURE_OPENAI_API_KEY=$(az keyvault secret show \
  --vault-name kv-brookside-secrets \
  --name azure-openai-api-key \
  --query value -o tsv)

# Retrieve Azure OpenAI endpoint
export AZURE_OPENAI_ENDPOINT=$(az keyvault secret show \
  --vault-name kv-brookside-secrets \
  --name azure-openai-endpoint \
  --query value -o tsv)
```

## Troubleshooting

### Issue: Azure CLI Not Found

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verify installation
az --version
```

### Issue: Azure Authentication Failed

```bash
# Re-authenticate
az login

# Set subscription
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"

# Verify
az account show
```

### Issue: Key Vault Access Denied

```bash
# Check current account
az account show

# Verify Key Vault exists
az keyvault show --name kv-brookside-secrets

# If access denied, contact Azure administrator
```

### Issue: Git Not Configured

```bash
# Configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@brooksidebi.com"

# Verify
git config --global --list
```

### Issue: MCP Servers Not Connecting

```bash
# Check configuration files
cat .mcp.json
cat .claude/settings.local.json

# Verify environment variables are set
env | grep -E "AZURE|NOTION|GITHUB"

# Re-run setup script
source scripts/setup-environment.sh

# Test MCP connectivity
claude mcp list
```

### Issue: Repository Hooks Not Working

```bash
# Make hooks executable
chmod +x .claude/hooks/*.sh

# Verify permissions
ls -la .claude/hooks/

# Test individual hooks
bash .claude/hooks/pre-commit-validation.sh
bash .claude/hooks/commit-message-validator.sh
bash .claude/hooks/branch-protection.sh check-push
```

## Additional Configuration

### Persistent Environment Variables

To avoid running the setup script every session:

```bash
# Add to ~/.bashrc
cat >> ~/.bashrc << 'EOF'

# Brookside BI Innovation Nexus Environment
export AZURE_TENANT_ID="2930489e-9d8a-456b-9de9-e4787faeab9c"
export AZURE_SUBSCRIPTION_ID="cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
export AZURE_KEYVAULT_NAME="kv-brookside-secrets"
export AZURE_KEYVAULT_URI="https://kv-brookside-secrets.vault.azure.net/"
export NOTION_WORKSPACE_ID="81686779-099a-8195-b49e-00037e25c23e"
export NOTION_DATABASE_ID_IDEAS="984a4038-3e45-4a98-8df4-fd64dd8a1032"
export NOTION_DATABASE_ID_RESEARCH="91e8beff-af94-4614-90b9-3a6d3d788d4a"
export NOTION_DATABASE_ID_BUILDS="a1cd1528-971d-4873-a176-5e93b93555f6"
export NOTION_DATABASE_ID_SOFTWARE="13b5e9de-2dd1-45ec-839a-4f3d50cd8d06"
export GITHUB_ORG="brookside-bi"
EOF

# Reload
source ~/.bashrc
```

### Shell Completion for Azure CLI

```bash
# Enable Azure CLI completion for bash
echo 'source /etc/bash_completion.d/azure-cli' >> ~/.bashrc
source ~/.bashrc
```

## Next Steps

After completing the setup:

1. **Review Project Documentation**:
   ```bash
   cat CLAUDE.md
   ```

2. **Explore Available Commands**:
   ```bash
   ls .claude/commands/
   ```

3. **Review Slash Commands**:
   ```bash
   cat .claude/SLASH_COMMANDS_GUIDE.md
   ```

4. **Check Repository Status**:
   ```bash
   git status
   git branch
   ```

5. **Start Using Claude Code**:
   ```bash
   claude
   ```

## Security Best Practices

**DO**:
- ✓ Use `az keyvault secret show` to retrieve secrets
- ✓ Reference Key Vault in documentation, never actual values
- ✓ Use environment variables from setup scripts
- ✓ Authenticate with `az login` before accessing Key Vault
- ✓ Keep Azure CLI and Node.js up to date

**DON'T**:
- ✗ Never commit secrets to Git
- ✗ Never display secrets in output or logs (use `--query value -o tsv`)
- ✗ Never hardcode credentials in code or documentation
- ✗ Never share Key Vault secrets via chat or email

## Repository Hooks

The repository includes automatic validation hooks:

- **Pre-commit validation**: Checks for secrets, large files, protected branches
- **Commit message validation**: Enforces Conventional Commits format
- **Branch protection**: Prevents force push to main/master/production
- **Destructive operation warnings**: Warns before dangerous git commands

These hooks execute automatically when using Claude Code and help maintain code quality and security.

## Resources

- **Main Documentation**: `CLAUDE.md` - Comprehensive project guide
- **Scripts Documentation**: `scripts/README.md` - Setup script reference
- **Hook Documentation**: `.claude/hooks/README.md` - Repository hooks guide
- **Slash Commands**: `.claude/SLASH_COMMANDS_GUIDE.md` - Available commands

---

**Brookside BI Innovation Nexus** - Streamline innovation workflows through structured approaches that drive measurable outcomes.

**Environment**: Linux | **Status**: Ready for Development | **Security**: Azure Key Vault Integrated
