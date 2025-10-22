# MCP Server Deployment Guide

**Purpose**: Standardized deployment procedures to establish consistent MCP infrastructure across all Brookside BI repositories, streamlining secure credential management and driving measurable outcomes through automation.

**Best for**: Organizations scaling innovation workflows across teams who require enterprise-grade security, consistent tooling, and sustainable infrastructure practices.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Deployment Checklist](#deployment-checklist)
3. [New Repository Setup](#new-repository-setup)
4. [Validation Procedures](#validation-procedures)
5. [Troubleshooting Guide](#troubleshooting-guide)
6. [Rollout Plan](#rollout-plan)

---

## Prerequisites

### Required Software

- **Azure CLI** 2.50.0 or higher
- **Node.js** 18.0.0 or higher
- **Git** (any recent version)
- **PowerShell** 7.0 or higher (for Windows)
- **Claude Code** (latest version)

### Required Access

- ✓ Azure subscription access (`cfacbbe8-a2a3-445f-a188-68b3b35f0c84`)
- ✓ Azure Key Vault permissions (kv-brookside-secrets)
  - `Key Vault Secrets User` role minimum
  - Ability to read secrets: `github-personal-access-token`, `notion-api-key`
- ✓ GitHub organization access (github.com/brookside-bi)
- ✓ Notion workspace access (for OAuth authentication)

### Verification Commands

```powershell
# Verify Azure CLI
az --version

# Verify Node.js
node --version

# Verify PowerShell
$PSVersionTable.PSVersion

# Verify Azure authentication
az login
az account show

# Verify Key Vault access
az keyvault secret list --vault-name kv-brookside-secrets
```

---

## Deployment Checklist

Use this checklist for each repository deployment:

### Phase 1: Infrastructure Preparation

- [ ] **Azure Authentication**
  - [ ] Run `az login`
  - [ ] Verify subscription: `az account show`
  - [ ] Confirm Key Vault access: `az keyvault secret list --vault-name kv-brookside-secrets`

- [ ] **Environment Variables**
  - [ ] Run `scripts/Set-MCPEnvironment.ps1` from Innovation Nexus repository
  - [ ] Verify `$env:GITHUB_PERSONAL_ACCESS_TOKEN` is set
  - [ ] Verify `$env:NOTION_API_KEY` is set (if needed)

- [ ] **Repository Clone**
  - [ ] Clone target repository locally
  - [ ] Verify Git remote configured
  - [ ] Checkout appropriate branch (usually `main` or `develop`)

### Phase 2: MCP Configuration Deployment

- [ ] **Run Initialization Script**
  ```powershell
  # From Innovation Nexus repository
  .\scripts\Initialize-MCPConfig.ps1 -TargetRepository "C:\Path\To\Target\Repo"
  ```

- [ ] **Configure Notion Workspace**
  - [ ] Obtain Notion Workspace ID (Settings > Workspace > Workspace ID)
  - [ ] Update `.claude/settings.local.json` if not set during initialization
  - [ ] Verify workspace ID matches target Notion workspace

- [ ] **Review Configuration**
  - [ ] Open `.claude/settings.local.json` in target repository
  - [ ] Verify all 4 MCP servers configured (notion, github, azure, playwright)
  - [ ] Confirm environment variable references use `${}` syntax
  - [ ] Check Notion Workspace ID is set

### Phase 3: Validation

- [ ] **Run Validation Script**
  ```powershell
  .\scripts\Test-MCPServers.ps1
  ```

- [ ] **Verify Results**
  - [ ] Notion MCP: OAuth credentials present (or first-time auth ready)
  - [ ] GitHub MCP: PAT environment variable set
  - [ ] Azure MCP: Azure CLI authenticated
  - [ ] Playwright MCP: Package available

- [ ] **Launch Claude Code**
  ```powershell
  # Navigate to target repository
  cd "C:\Path\To\Target\Repo"

  # Launch Claude Code
  claude
  ```

- [ ] **Complete Authentication Flows**
  - [ ] Notion OAuth (if first time) - follow browser prompt
  - [ ] Verify all servers: `claude mcp list` shows 4 connected servers
  - [ ] Test each server with simple operation

### Phase 4: Documentation

- [ ] **Update Repository Documentation**
  - [ ] Add MCP configuration section to README.md
  - [ ] Document environment setup procedures
  - [ ] Include troubleshooting steps for common issues
  - [ ] Link to this deployment guide

- [ ] **Create Integration Registry Entry** (if using Notion tracking)
  - [ ] Document MCP servers configured
  - [ ] Note authentication methods
  - [ ] Record deployment date and owner
  - [ ] Link to repository

- [ ] **Commit Configuration**
  ```bash
  git add .claude/settings.local.json
  git commit -m "feat: Establish standardized MCP infrastructure for enhanced automation"
  git push
  ```

### Phase 5: Team Enablement

- [ ] **Share Access Instructions**
  - [ ] Provide Azure Key Vault access to team members
  - [ ] Share `Set-MCPEnvironment.ps1` script location
  - [ ] Document daily workflow (run env script before Claude Code)

- [ ] **Conduct Walkthrough**
  - [ ] Demonstrate MCP server usage
  - [ ] Show common operations (Notion queries, GitHub operations, Azure commands)
  - [ ] Answer questions and address concerns

---

## New Repository Setup

### Quick Start (5-10 minutes)

```powershell
# 1. Authenticate to Azure
az login
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"

# 2. Clone Innovation Nexus repository (contains scripts)
git clone https://github.com/brookside-bi/innovation-nexus.git
cd innovation-nexus

# 3. Set environment variables
.\scripts\Set-MCPEnvironment.ps1

# 4. Initialize MCP config in target repository
.\scripts\Initialize-MCPConfig.ps1 -TargetRepository "C:\Path\To\New\Repo"

# 5. Validate configuration
.\scripts\Test-MCPServers.ps1

# 6. Launch Claude Code in target repository
cd "C:\Path\To\New\Repo"
claude
```

### Manual Configuration (if scripts unavailable)

1. **Create `.claude` directory** in repository root

2. **Copy template** from Innovation Nexus:
   ```powershell
   Copy-Item "path\to\innovation-nexus\.claude\templates\mcp-config-template.json" `
             "path\to\target-repo\.claude\settings.local.json"
   ```

3. **Edit configuration**:
   - Remove documentation comments (lines starting with `//`)
   - Update `NOTION_WORKSPACE_ID` to target workspace
   - Save file

4. **Set environment variables manually**:
   ```powershell
   $env:GITHUB_PERSONAL_ACCESS_TOKEN = az keyvault secret show `
       --vault-name kv-brookside-secrets `
       --name github-personal-access-token `
       --query value -o tsv

   $env:NOTION_API_KEY = az keyvault secret show `
       --vault-name kv-brookside-secrets `
       --name notion-api-key `
       --query value -o tsv
   ```

5. **Restart Claude Code** and complete OAuth flows

---

## Validation Procedures

### Automated Validation

```powershell
# Full validation
.\scripts\Test-MCPServers.ps1

# Specific server
.\scripts\Test-MCPServers.ps1 -ServerName azure

# Verbose output
.\scripts\Test-MCPServers.ps1 -Verbose
```

### Manual Validation

```bash
# Launch Claude Code
claude

# In Claude Code session, verify MCP servers
claude mcp list

# Expected output:
# ✓ notion (connected)
# ✓ github (connected)
# ✓ azure (connected)
# ✓ playwright (connected)
```

### Test Operations

**Notion MCP:**
```bash
# Search Notion workspace
notion-search "test query"

# Fetch specific page
notion-fetch "page-url-or-id"
```

**GitHub MCP:**
```bash
# List repositories
gh repo list brookside-bi

# Check authentication
gh auth status
```

**Azure MCP:**
```bash
# List subscriptions
az account list

# List Key Vault secrets
az keyvault secret list --vault-name kv-brookside-secrets
```

**Playwright MCP:**
```bash
# Test browser automation (via Claude Code commands)
# No direct CLI - test through MCP operations in Claude Code
```

---

## Troubleshooting Guide

### Issue: Azure CLI Not Authenticated

**Symptoms:**
- `Test-MCPServers.ps1` shows "Azure CLI not authenticated"
- Azure MCP operations fail

**Resolution:**
```powershell
# Re-authenticate
az login

# Set subscription
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"

# Verify
az account show
```

### Issue: GitHub PAT Not Set

**Symptoms:**
- `Test-MCPServers.ps1` shows "GITHUB_PERSONAL_ACCESS_TOKEN not set"
- GitHub MCP operations fail with authentication errors

**Resolution:**
```powershell
# Run environment setup script
.\scripts\Set-MCPEnvironment.ps1

# Or set manually
$env:GITHUB_PERSONAL_ACCESS_TOKEN = az keyvault secret show `
    --vault-name kv-brookside-secrets `
    --name github-personal-access-token `
    --query value -o tsv

# Verify
echo $env:GITHUB_PERSONAL_ACCESS_TOKEN | Select-String -Pattern '^ghp_'
```

### Issue: Notion OAuth Not Completed

**Symptoms:**
- Notion MCP shows "not connected"
- First MCP operation prompts for authentication

**Resolution:**
1. Launch Claude Code in repository
2. Trigger any Notion operation (e.g., search)
3. Follow browser OAuth prompt
4. Grant workspace access
5. Return to Claude Code - should now show "connected"

### Issue: Node.js Package Not Found

**Symptoms:**
- MCP server fails to start
- Error: "Command not found: npx" or package errors

**Resolution:**
```powershell
# Install/update Node.js (18+)
# Download from: https://nodejs.org/

# Verify installation
node --version
npm --version

# Test package installation
npx -y @azure/mcp@latest --version
```

### Issue: Notion Workspace ID Incorrect

**Symptoms:**
- Notion operations succeed but return no results
- Accessing wrong workspace

**Resolution:**
1. Find correct Workspace ID:
   - Open Notion
   - Settings > Workspace > Workspace ID
2. Update `.claude/settings.local.json`:
   ```json
   {
     "globalSettings": {
       "NOTION_WORKSPACE_ID": "correct-workspace-id-here"
     }
   }
   ```
3. Restart Claude Code

### Issue: Key Vault Access Denied

**Symptoms:**
- `az keyvault secret show` fails with permission error
- Environment setup script fails

**Resolution:**
1. Request access from Azure administrator
2. Required role: `Key Vault Secrets User`
3. Verify permissions:
   ```powershell
   az keyvault secret list --vault-name kv-brookside-secrets
   ```

---

## Rollout Plan

### Phase 1: Proof of Concept (Week 1)

**Target**: Project-Ascension repository

**Objectives**:
- Validate deployment scripts in production environment
- Identify edge cases and issues
- Refine documentation based on real-world usage

**Tasks**:
1. [ ] Deploy MCP config to Project-Ascension
2. [ ] Complete all validation steps
3. [ ] Document any issues encountered
4. [ ] Update scripts/documentation as needed
5. [ ] Get team feedback on setup process
6. [ ] Measure deployment time (target: <10 minutes)

**Success Criteria**:
- All 4 MCP servers connected and functional
- Team can use MCP operations without assistance
- Deployment time ≤ 10 minutes
- Zero credential exposure incidents

---

### Phase 2: Early Adopters (Week 2-3)

**Targets**:
- brookside-cost-tracker
- brookside-repo-analyzer
- Any active development repositories

**Objectives**:
- Scale deployment process to multiple repositories
- Identify common patterns and pain points
- Validate cross-repository consistency

**Tasks**:
1. [ ] Deploy to 3-5 active repositories
2. [ ] Train repository owners on MCP usage
3. [ ] Create reusable templates for common operations
4. [ ] Document repository-specific customizations
5. [ ] Gather usage metrics and feedback
6. [ ] Identify optimization opportunities

**Success Criteria**:
- 100% deployment success rate
- Average deployment time ≤ 10 minutes
- Team reports improved productivity with MCP tools
- No authentication or credential issues

---

### Phase 3: Organization-Wide Rollout (Week 4-6)

**Targets**: All Brookside-Proving-Grounds repositories

**Objectives**:
- Achieve complete MCP standardization across organization
- Establish sustainable maintenance practices
- Create knowledge base for onboarding

**Tasks**:
1. [ ] Audit all repositories for MCP readiness
2. [ ] Batch deploy to remaining repositories
3. [ ] Create organization-wide usage guidelines
4. [ ] Schedule training sessions for all team members
5. [ ] Establish support channels for MCP issues
6. [ ] Document lessons learned and best practices

**Success Criteria**:
- 100% of active repositories have MCP configured
- Team-wide adoption of MCP-powered workflows
- Documented ROI (time savings, reduced errors)
- Knowledge base established for self-service support

---

### Phase 4: Continuous Improvement (Ongoing)

**Objectives**:
- Monitor MCP server reliability and performance
- Update configurations as new servers become available
- Share best practices across organization

**Tasks**:
- [ ] Monthly MCP health checks across all repositories
- [ ] Quarterly script and documentation updates
- [ ] Collect and implement team feedback
- [ ] Track metrics (deployment time, success rate, incidents)
- [ ] Evangelize MCP usage patterns and success stories

**Metrics to Track**:
- **Deployment Efficiency**: Average time to deploy MCP config
- **Reliability**: MCP server uptime and connectivity success rate
- **Adoption**: % of repositories with active MCP usage
- **Security**: Number of credential-related incidents (target: 0)
- **Productivity**: Time saved through MCP automation (vs. manual operations)

---

## Success Metrics

### Deployment Metrics

- **Target Deployment Time**: ≤ 10 minutes per repository
- **Success Rate**: 100% of deployments complete without manual intervention
- **Validation Pass Rate**: 100% of repositories pass `Test-MCPServers.ps1`

### Security Metrics

- **Credential Exposure Incidents**: 0 (all secrets from Azure Key Vault)
- **Key Vault Access Audit**: 100% of team members have appropriate permissions
- **OAuth Completion Rate**: 100% (Notion authentication successful)

### Adoption Metrics

- **Repository Coverage**: 100% of active development repositories
- **Team Member Enablement**: 100% of team members can deploy MCP config independently
- **MCP Usage**: >50% of Claude Code operations leverage MCP servers

### Productivity Metrics

- **Notion Query Time**: 90% faster than manual UI navigation
- **GitHub Operations**: 80% reduction in context switching to web UI
- **Azure Resource Management**: 70% fewer Azure Portal visits

---

## Additional Resources

- **Template File**: `.claude/templates/mcp-config-template.json`
- **Initialization Script**: `scripts/Initialize-MCPConfig.ps1`
- **Environment Setup**: `scripts/Set-MCPEnvironment.ps1`
- **Validation Script**: `scripts/Test-MCPServers.ps1`
- **Azure Key Vault**: `https://kv-brookside-secrets.vault.azure.net/`
- **GitHub Organization**: `https://github.com/brookside-bi`

---

**Best for**: Organizations requiring standardized, secure infrastructure that streamlines development workflows and drives measurable outcomes through automation.

**Designed for**: Brookside BI Innovation Nexus - Enterprise-grade MCP infrastructure for AI-powered development.

**Created**: 2025-10-21
**Author**: Brookside BI
**Version**: 1.0
