# Azure AI Foundry MCP Server Setup Guide

**Best for**: Organizations requiring enterprise AI/ML capabilities with Azure AI Foundry integration
**Designed for**: Brookside BI Innovation Nexus - Streamline AI workflows with centralized model access

---

## Overview

This solution is designed to establish seamless integration between Claude Code and Azure AI Foundry, providing unified access to:

- **Models**: Retrieve supported models from Azure AI Foundry catalog
- **Knowledge**: Access state-of-the-art AI models from Microsoft Research
- **Evaluation**: Create and manage text/agent evaluators
- **Deployments**: Deploy models on Azure AI Services
- **Projects**: Manage Azure AI Foundry projects

---

## Prerequisites

### 1. Software Requirements

✅ **UV Package Manager** (installed at `C:\Users\MarkusAhling\AppData\Local\Microsoft\WinGet\Links\uv.exe`)
```powershell
# Verify installation
uv --version
```

✅ **Azure CLI** (authenticated)
```powershell
# Verify authentication
az account show
```

✅ **Claude Code** (version 2.0+)
```bash
# Verify version
claude --version
```

### 2. Azure Resources

✅ **Azure AI Foundry Project**: `Brookside-Bi`
✅ **Resource Group**: `rg-brookside-prod`
✅ **Subscription**: `cfacbbe8-a2a3-445f-a188-68b3b35f0c84`
✅ **Key Vault**: `kv-brookside-secrets` (credentials stored)

---

## Configuration Files Created

### 1. Environment Configuration
**File**: `.env.azure-foundry`
**Purpose**: Stores all Azure AI Foundry credentials and endpoints

Contains:
- Azure AI Foundry endpoint and API key
- Azure OpenAI endpoint and API key
- Azure AI Services endpoint and API key
- Speech services endpoints (STT/TTS)
- Azure subscription and tenant information

**Security Note**: This file contains sensitive credentials. In production, retrieve values from Azure Key Vault using [scripts/Get-KeyVaultSecret.ps1](../scripts/Get-KeyVaultSecret.ps1).

### 2. MCP Server Configuration
**File**: `.mcp.json`
**Purpose**: Configures the Azure AI Foundry MCP server for Claude Code

```json
{
  "mcpServers": {
    "azure-ai-foundry": {
      "type": "stdio",
      "command": "uvx",
      "args": [
        "--prerelease=allow",
        "--from",
        "git+https://github.com/azure-ai-foundry/mcp-foundry.git",
        "run-azure-ai-foundry-mcp",
        "--envFile",
        "${workspaceFolder}/.env.azure-foundry"
      ],
      "env": {}
    }
  }
}
```

---

## Activation Steps

### Step 1: Restart Claude Code

The MCP server configuration requires Claude Code to be restarted to detect the new `.mcp.json` file.

```bash
# Exit current Claude Code session
exit

# Restart Claude Code in the project directory
cd C:\Users\MarkusAhling\Notion
claude
```

### Step 2: Verify MCP Server Connection

After restarting, verify the Azure AI Foundry MCP server is loaded:

```bash
claude mcp list
```

**Expected Output**:
```
Checking MCP server health...

playwright: npx @playwright/mcp@latest --browser msedge --headless - ✓ Connected
notion: https://mcp.notion.com/mcp (HTTP) - ✓ Connected
github: npx -y @modelcontextprotocol/server-github - ✓ Connected
azure: npx -y @azure/mcp@latest server start - ✓ Connected
azure-ai-foundry: uvx --prerelease=allow --from git+https://github.com/azure-ai-foundry/mcp-foundry.git - ✓ Connected
```

### Step 3: Test Azure AI Foundry Integration

Once connected, test the integration:

```bash
# List available models from Azure AI Foundry
# (This will use the MCP server automatically when you ask Claude)

# Example prompts:
"What models are available in Azure AI Foundry?"
"Show me the Azure AI Foundry Labs models"
"Create a new Azure AI Services deployment"
```

---

## Available MCP Tools

The Azure AI Foundry MCP server provides these capabilities:

### Models Management
- **List Supported Models**: Retrieve all models from Azure AI Foundry catalog
- **Get Model Details**: Detailed information for specific models
- **List Labs Models**: Access state-of-the-art models from Microsoft Research

### Deployment Operations
- **Create AI Services Account**: Set up new Azure AI Services accounts
- **Deploy Models**: Deploy models on Azure AI Services
- **Manage Projects**: Create and manage Azure AI Foundry projects

### Evaluation Tools
- **List Text Evaluators**: Available text evaluation tools
- **List Agent Evaluators**: Available agent evaluation tools
- **Run Evaluations**: Execute evaluations on models and agents

---

## Credentials Management

### Option 1: Direct Environment File (Current Setup)

Credentials are stored in `.env.azure-foundry` file (not committed to git).

**Pros**:
- Simple setup
- Quick development
- No additional authentication

**Cons**:
- Credentials stored in plain text locally
- Must be manually updated when keys rotate
- Not suitable for team environments

### Option 2: Azure Key Vault Integration (Recommended for Production)

Retrieve secrets dynamically from Azure Key Vault:

```powershell
# Example: Update .env.azure-foundry from Key Vault
$endpoint = .\scripts\Get-KeyVaultSecret.ps1 -SecretName "azure-ai-foundry-endpoint"
$apiKey = .\scripts\Get-KeyVaultSecret.ps1 -SecretName "azure-ai-foundry-api-key"

# Update .env.azure-foundry file with retrieved values
```

**Pros**:
- Centralized secret management
- Automatic rotation support
- Audit logging
- RBAC-based access control
- Team-friendly

**Cons**:
- Requires Azure CLI authentication
- Additional setup complexity

---

## Troubleshooting

### MCP Server Not Showing in `claude mcp list`

**Symptoms**: Azure AI Foundry MCP server doesn't appear after configuration

**Solutions**:
1. Verify `.mcp.json` is in the project root directory
2. Restart Claude Code completely
3. Check UV is installed and in PATH: `where.exe uv`
4. Verify environment file exists: `Test-Path .env.azure-foundry`

### Environment Variable Errors

**Symptoms**: MCP server fails with "environment variable not found" error

**Solutions**:
1. Verify `.env.azure-foundry` contains all required variables
2. Check file path is correct in `.mcp.json` (`${workspaceFolder}/.env.azure-foundry`)
3. Ensure no syntax errors in `.env.azure-foundry`

### Authentication Errors

**Symptoms**: "Unauthorized" or "403 Forbidden" errors

**Solutions**:
1. Verify API keys are correct in `.env.azure-foundry`
2. Check Key Vault for latest credentials:
   ```powershell
   .\scripts\Get-KeyVaultSecret.ps1 -SecretName "azure-ai-foundry-api-key"
   ```
3. Verify Azure subscription and tenant IDs are correct
4. Ensure project resource ID is accurate

### UV Command Not Found

**Symptoms**: "uvx: command not found" or similar error

**Solutions**:
1. Install UV package manager: https://docs.astral.sh/uv/getting-started/installation/
2. Verify UV is in PATH: `where.exe uv`
3. Restart terminal/Claude Code after installation

---

## Security Best Practices

### For Development Environments

✅ Never commit `.env.azure-foundry` to version control
✅ Add to `.gitignore`: `.env.azure-foundry`
✅ Rotate keys regularly (90-day cycle recommended)
✅ Use Azure CLI authentication when possible
✅ Review Key Vault access policies quarterly

### For Production Environments

✅ Use Azure Managed Identities for authentication
✅ Retrieve all secrets from Azure Key Vault dynamically
✅ Implement secret rotation automation
✅ Enable Key Vault audit logging
✅ Use separate environments (dev/staging/prod) with different credentials
✅ Apply principle of least privilege for all access

---

## Integration with Notion Innovation Nexus

The Azure AI Foundry MCP server streamlines workflows across the Innovation Nexus:

### Ideas Registry
- **Use Case**: Quickly validate AI/ML idea feasibility
- **MCP Benefit**: Check model availability before committing to research

### Research Hub
- **Use Case**: Evaluate models during feasibility studies
- **MCP Benefit**: Direct access to model specs and capabilities

### Example Builds
- **Use Case**: Deploy AI models for prototypes
- **MCP Benefit**: Streamlined deployment to Azure AI Services

### Software & Cost Tracker
- **Use Case**: Track Azure AI Foundry service costs
- **MCP Benefit**: Integration with existing cost tracking workflows

---

## Related Resources

### Official Documentation
- [Azure AI Foundry MCP GitHub Repository](https://github.com/azure-ai-foundry/mcp-foundry)
- [Azure AI Foundry Documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)

### Brookside BI Resources
- [Get-KeyVaultSecret.ps1](../scripts/Get-KeyVaultSecret.ps1) - Retrieve secrets from Azure Key Vault
- [CLAUDE.md](../CLAUDE.md) - Project instructions for Claude Code
- [Software Integration Matrix (Notion)](https://notion.so/29386779099a81ed8907c301defc6d94)

### Next Steps
1. Add Azure AI Foundry service to Software & Cost Tracker (Notion)
2. Create Integration Registry entry for this MCP server
3. Document model deployment workflows in Knowledge Vault
4. Set up cost tracking for AI/ML experiments

---

**Created**: 2025-10-21
**Author**: Brookside BI Innovation Team
**Version**: 1.0
**Last Updated**: 2025-10-21

---

**Drive measurable outcomes through structured AI/ML workflows with Azure AI Foundry integration.**
