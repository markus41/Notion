# Azure AI Foundry MCP - Quick Start Guide

**🎯 Purpose**: Streamline Azure AI Foundry workflows directly from Claude Code
**⏱️ Setup Time**: 5 minutes (configuration complete!)
**🔒 Security**: Credentials stored in Azure Key Vault

---

## ✅ Setup Complete

Your Azure AI Foundry MCP server is configured and ready to use!

### Files Created

| File | Purpose |
|------|---------|
| `.mcp.json` | MCP server configuration |
| `.env.azure-foundry` | Credentials (gitignored) |
| `docs/AZURE_AI_FOUNDRY_MCP_SETUP.md` | Full setup guide |

---

## 🚀 Activation (Next Step)

**Restart Claude Code to activate the MCP server:**

```bash
# Exit current session
exit

# Navigate to project directory
cd C:\Users\MarkusAhling\Notion

# Restart Claude Code
claude
```

**Verify activation:**

```bash
claude mcp list
```

You should see `azure-ai-foundry: ✓ Connected`

---

## 💡 Example Use Cases

### 1. Explore Available AI Models

**Prompt Claude:**
```
"What models are available in Azure AI Foundry?"
```

**What happens:**
- Claude uses the Azure AI Foundry MCP server
- Retrieves current model catalog
- Shows model capabilities and pricing

---

### 2. Deploy a Model

**Prompt Claude:**
```
"Deploy GPT-4 to Azure AI Services in the West US region"
```

**What happens:**
- Creates deployment configuration
- Provisions Azure resources
- Returns deployment endpoint

---

### 3. Evaluate Model Performance

**Prompt Claude:**
```
"List available text evaluators for quality assessment"
```

**What happens:**
- Retrieves evaluator tools
- Shows evaluation capabilities
- Suggests evaluation workflows

---

## 🔑 Credentials Reference

All credentials are stored in Azure Key Vault: `kv-brookside-secrets`

### Retrieve Secrets

```powershell
# Get Azure AI Foundry endpoint
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "azure-ai-foundry-endpoint"

# Get API key
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "azure-ai-foundry-api-key"
```

### Key Vault Secrets Created

| Secret Name | Description |
|-------------|-------------|
| `azure-ai-foundry-endpoint` | AI Foundry project endpoint |
| `azure-ai-foundry-api-key` | Authentication key |
| `azure-openai-endpoint` | Azure OpenAI endpoint |
| `azure-openai-api-key` | OpenAI authentication |
| `azure-ai-services-endpoint` | AI Services endpoint |
| `azure-ai-services-api-key` | AI Services authentication |
| `azure-speech-stt-endpoint` | Speech-to-Text endpoint |
| `azure-speech-tts-endpoint` | Text-to-Speech endpoint |
| `azure-ai-foundry-resource-id` | Full resource ID |

---

## 🛠️ Troubleshooting

### MCP Server Not Connected

**Check installation:**
```bash
# Verify UV is installed
uv --version

# Check environment file exists
dir .env.azure-foundry
```

**Restart Claude Code:**
```bash
exit
claude
```

---

### Authentication Errors

**Update credentials from Key Vault:**
```powershell
# Retrieve latest API key
$apiKey = .\scripts\Get-KeyVaultSecret.ps1 -SecretName "azure-ai-foundry-api-key"

# Manually update .env.azure-foundry if needed
```

---

## 📚 Integration with Innovation Nexus

### Ideas Registry
✅ Validate AI/ML feasibility with model availability checks

### Research Hub
✅ Evaluate models during technical research

### Example Builds
✅ Deploy models for prototypes and POCs

### Software & Cost Tracker
✅ Track Azure AI services costs

---

## 🔗 Related Documentation

- [Full Setup Guide](./AZURE_AI_FOUNDRY_MCP_SETUP.md)
- [Azure AI Foundry Docs](https://learn.microsoft.com/en-us/azure/ai-foundry/)
- [MCP GitHub Repository](https://github.com/azure-ai-foundry/mcp-foundry)

---

## 🎓 Pro Tips

1. **Ask for specific model types**: "Show me vision models in Azure AI Foundry"
2. **Check pricing before deployment**: "What's the cost of deploying GPT-4 Turbo?"
3. **Use evaluation tools**: "Run quality evaluation on my deployed model"
4. **Integrate with builds**: "Add this model to my current prototype"

---

**🎯 Next Action**: Restart Claude Code to activate the Azure AI Foundry MCP server!

---

**Created**: 2025-10-21 | **Version**: 1.0
