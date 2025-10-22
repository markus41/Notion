#!/bin/bash
# Brookside BI Innovation Nexus - Linux Environment Setup
# Purpose: Configure environment for Claude Code with MCP servers
# Usage: source scripts/setup-environment.sh

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Brookside BI Innovation Nexus - Environment Setup        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Check Prerequisites
echo -e "${GREEN}📋 Step 1: Checking Prerequisites...${NC}"
echo ""

check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $1 ($(command -v $1))"
        return 0
    else
        echo -e "  ${RED}✗${NC} $1 (not found)"
        return 1
    fi
}

# Check Node.js
if check_command node; then
    NODE_VERSION=$(node --version)
    echo -e "    Version: ${NODE_VERSION}"
fi

# Check Git
if check_command git; then
    GIT_VERSION=$(git --version)
    echo -e "    Version: ${GIT_VERSION}"
fi

# Check Azure CLI
if ! check_command az; then
    echo -e "${YELLOW}⚠️  Azure CLI not found${NC}"
    echo ""
    echo "To install Azure CLI on Linux:"
    echo "  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    echo ""
    echo "Or visit: https://docs.microsoft.com/cli/azure/install-azure-cli-linux"
    echo ""
    AZURE_CLI_MISSING=1
else
    AZ_VERSION=$(az --version 2>&1 | head -1)
    echo -e "    Version: ${AZ_VERSION}"
    AZURE_CLI_MISSING=0
fi

echo ""

# Step 2: Set Environment Variables
echo -e "${GREEN}📦 Step 2: Setting Environment Variables...${NC}"
echo ""

# Azure Configuration (from CLAUDE.md)
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

echo -e "  ${GREEN}✓${NC} AZURE_TENANT_ID"
echo -e "  ${GREEN}✓${NC} AZURE_SUBSCRIPTION_ID"
echo -e "  ${GREEN}✓${NC} AZURE_KEYVAULT_NAME"
echo -e "  ${GREEN}✓${NC} NOTION_WORKSPACE_ID"
echo -e "  ${GREEN}✓${NC} NOTION_DATABASE_IDs (4 databases)"
echo -e "  ${GREEN}✓${NC} GITHUB_ORG"

echo ""

# Step 3: Azure Authentication (if available)
if [ $AZURE_CLI_MISSING -eq 0 ]; then
    echo -e "${GREEN}🔐 Step 3: Checking Azure Authentication...${NC}"
    echo ""

    if az account show &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} Already authenticated to Azure"
        AZURE_ACCOUNT=$(az account show --query "name" -o tsv)
        echo -e "    Account: ${AZURE_ACCOUNT}"
    else
        echo -e "  ${YELLOW}⚠️${NC}  Not authenticated to Azure"
        echo ""
        echo "To authenticate, run:"
        echo "  az login"
        echo ""
        echo "Then set your subscription:"
        echo "  az account set --subscription \"$AZURE_SUBSCRIPTION_ID\""
        echo ""
    fi
else
    echo -e "${YELLOW}⚠️  Skipping Azure authentication check (Azure CLI not installed)${NC}"
fi

echo ""

# Step 4: Check Git Configuration
echo -e "${GREEN}🔧 Step 4: Checking Git Configuration...${NC}"
echo ""

GIT_USER=$(git config --global user.name 2>/dev/null || echo "Not set")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "Not set")

if [ "$GIT_USER" = "Not set" ] || [ "$GIT_EMAIL" = "Not set" ]; then
    echo -e "  ${YELLOW}⚠️${NC}  Git user configuration incomplete"
    echo ""
    echo "To configure Git, run:"
    echo "  git config --global user.name \"Your Name\""
    echo "  git config --global user.email \"your.email@brooksidebi.com\""
    echo ""
else
    echo -e "  ${GREEN}✓${NC} Git user.name: ${GIT_USER}"
    echo -e "  ${GREEN}✓${NC} Git user.email: ${GIT_EMAIL}"
fi

echo ""

# Step 5: Repository Hooks
echo -e "${GREEN}🪝 Step 5: Checking Repository Hooks...${NC}"
echo ""

if [ -f ".claude/hooks/pre-commit-validation.sh" ]; then
    if [ -x ".claude/hooks/pre-commit-validation.sh" ]; then
        echo -e "  ${GREEN}✓${NC} Pre-commit validation hook available and executable"
    else
        echo -e "  ${YELLOW}⚠️${NC}  Pre-commit validation hook not executable"
        echo "    Making hooks executable..."
        chmod +x .claude/hooks/*.sh
        echo -e "  ${GREEN}✓${NC} Hooks made executable"
    fi
else
    echo -e "  ${RED}✗${NC} Pre-commit validation hook not found"
fi

echo ""

# Step 6: MCP Configuration
echo -e "${GREEN}🔌 Step 6: Checking MCP Configuration...${NC}"
echo ""

if [ -f ".mcp.json" ]; then
    echo -e "  ${GREEN}✓${NC} .mcp.json found"

    # Check for azure-ai-foundry configuration
    if grep -q "azure-ai-foundry" .mcp.json; then
        echo -e "  ${GREEN}✓${NC} Azure AI Foundry MCP server configured"
    fi
else
    echo -e "  ${YELLOW}⚠️${NC}  .mcp.json not found"
fi

if [ -f ".claude/settings.local.json" ]; then
    echo -e "  ${GREEN}✓${NC} .claude/settings.local.json found"
else
    echo -e "  ${YELLOW}⚠️${NC}  .claude/settings.local.json not found"
fi

echo ""

# Step 7: Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Environment Setup Summary                                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}✅ Completed Steps:${NC}"
echo "  • Environment variables configured"
echo "  • Repository hooks checked"
echo "  • MCP configuration verified"
echo ""

if [ $AZURE_CLI_MISSING -eq 1 ] || [ "$GIT_USER" = "Not set" ]; then
    echo -e "${YELLOW}⚠️  Action Required:${NC}"

    if [ $AZURE_CLI_MISSING -eq 1 ]; then
        echo "  • Install Azure CLI for Key Vault access"
    fi

    if [ "$GIT_USER" = "Not set" ]; then
        echo "  • Configure Git user information"
    fi
    echo ""
fi

echo -e "${BLUE}📚 Next Steps:${NC}"
echo "  1. If Azure CLI is installed, authenticate:"
echo "     az login"
echo ""
echo "  2. Verify MCP server connectivity:"
echo "     claude mcp list"
echo ""
echo "  3. Start using the repository:"
echo "     git status"
echo "     git branch"
echo ""
echo -e "${GREEN}🎉 Environment setup script completed!${NC}"
echo ""
echo "To run this setup again, use:"
echo "  source scripts/setup-environment.sh"
echo ""
