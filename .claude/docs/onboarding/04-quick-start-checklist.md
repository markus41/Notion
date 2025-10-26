# Quick Start Checklist

**Brookside BI Innovation Nexus Quick Start** - Establish productive workflows within your first week through structured, hands-on tasks that build practical competency with Ideas, Research, Builds, and Cost Management.

**Best for**: New team members seeking immediate productivity with clear, executable tasks that demonstrate Innovation Nexus capabilities while contributing real value to the organization.

---

## Overview

This checklist guides you through your first week with Innovation Nexus, progressing from basic environment setup to autonomous builds and cost optimization. Each day focuses on specific competencies with hands-on exercises and success criteria.

**Time Commitment**:
- Day 1: 2-3 hours (environment setup and verification)
- Day 2: 1-2 hours (idea capture and research coordination)
- Day 3: 1-2 hours (cost analysis and repository intelligence)
- Week 1: 3-4 hours (first build creation)
- Week 2: 2-3 hours (knowledge contribution and optimization)

**Total Investment**: 9-14 hours over 2 weeks for comprehensive Innovation Nexus competency

---

## Pre-Onboarding: Access Requests

**Complete BEFORE Day 1** (coordinate with team leads):

### Azure Subscription Access

**Required Role**: Contributor (minimum) on subscription `cfacbbe8-a2a3-445f-a188-68b3b35f0c84`

**Request From**: Alec Fielding (DevOps Lead)

**Verification**:
```bash
az login
az account show
# Expected output should show:
# "id": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
# "name": "Brookside BI Production"
```

**Key Vault Access**: Request Reader role on `kv-brookside-secrets` (required for MCP environment setup)

### Notion Workspace Access

**Required Role**: Member (with edit permissions on core databases)

**Request From**: Brad Wright or Markus Ahling

**Workspace ID**: `81686779-099a-8195-b49e-00037e25c23e`

**Verification**: Visit https://www.notion.so/81686779-099a-8195-b49e-00037e25c23e and confirm access to:
- 💡 Ideas Registry
- 🔬 Research Hub
- 🛠️ Example Builds
- 💰 Software & Cost Tracker

### GitHub Organization Access

**Required Role**: Member of `brookside-bi` organization

**Request From**: Markus Ahling

**Verification**: Visit https://github.com/brookside-bi and confirm organization visibility

### Claude Code Installation

**Required Version**: Latest stable release (Claude Code with Sonnet 4.5)

**Installation Guide**: https://docs.anthropic.com/claude/docs/claude-code

**Verification**:
```bash
claude --version
# Expected: Claude Code v[latest]
```

---

## Day 1: Environment Setup and Verification

**Goal**: Establish complete Innovation Nexus development environment with verified MCP connectivity and secure access to all systems.

**Time Estimate**: 2-3 hours

### Task 1.1: Azure CLI Authentication

**Purpose**: Authenticate to Azure for resource management and Key Vault access

**Steps**:
```bash
# 1. Install Azure CLI (if not already installed)
# Windows: winget install Microsoft.AzureCLI
# macOS: brew install azure-cli
# Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# 2. Authenticate
az login

# 3. Verify correct subscription
az account show

# 4. List accessible Key Vaults (verify access)
az keyvault list --output table
# Expected: kv-brookside-secrets should appear

# 5. Test Key Vault secret retrieval
az keyvault secret show --vault-name kv-brookside-secrets --name github-personal-access-token --query value -o tsv
# Expected: PAT token value (do not share publicly)
```

**Success Criteria**:
- ✅ `az account show` displays Brookside BI subscription
- ✅ Key Vault secrets are accessible
- ✅ No authentication errors

**Troubleshooting**:
- **Error: "No subscriptions found"** → Request subscription access from Alec Fielding
- **Error: "Access denied to Key Vault"** → Request Reader role on kv-brookside-secrets
- **Error: "Azure CLI not found"** → Install via package manager above

### Task 1.2: MCP Environment Configuration

**Purpose**: Configure environment variables for Notion, GitHub, and Azure MCP servers

**Steps**:
```powershell
# 1. Navigate to repository root
cd C:\Users\[YourUsername]\Notion

# 2. Run MCP environment setup script
.\scripts\Set-MCPEnvironment.ps1

# 3. Verify environment variables set
$env:AZURE_SUBSCRIPTION_ID
$env:GITHUB_ORG
$env:NOTION_WORKSPACE_ID
# Expected: All should display values (not empty)

# 4. For persistent configuration (optional but recommended):
.\scripts\Set-MCPEnvironment.ps1 -Persistent
```

**Success Criteria**:
- ✅ All environment variables populated
- ✅ Script completes without errors
- ✅ Variables persist across terminal sessions (if -Persistent used)

**Troubleshooting**:
- **Error: "Script not found"** → Verify you're in repository root (should contain `.claude/` directory)
- **Error: "Key Vault access denied"** → Re-run `az login` and verify subscription
- **Warning: "Variable already set"** → Safe to ignore (existing values preserved)

### Task 1.3: MCP Server Connectivity Test

**Purpose**: Validate all 4 MCP servers (Notion, GitHub, Azure, Playwright) are connected and functional

**Steps**:
```bash
# 1. Launch Claude Code
claude

# 2. In Claude Code, list MCP servers:
claude mcp list

# Expected output:
# ✓ Notion - Connected
# ✓ GitHub - Connected
# ✓ Azure - Connected
# ✓ Playwright - Connected

# 3. Test each MCP server:

# Test Notion (search Ideas Registry)
mcp__notion__notion-search {
  "query": "test",
  "query_type": "internal",
  "data_source_url": "collection://984a4038-3e45-4a98-8df4-fd64dd8a1032"
}

# Test GitHub (list repositories)
mcp__github__search_repositories {
  "query": "org:brookside-bi"
}

# Test Azure (list resource groups)
mcp__azure__group_list {}
```

**Success Criteria**:
- ✅ All 4 MCP servers show "Connected" status
- ✅ Test queries return results without errors
- ✅ No authentication warnings

**Troubleshooting**:
- **Notion: "OAuth not configured"** → Re-authenticate via Claude Code settings
- **GitHub: "401 Unauthorized"** → Verify PAT in Key Vault has correct scopes (repo, admin:org)
- **Azure: "Subscription not found"** → Run `az login` and verify active subscription
- **Playwright: "Browser not installed"** → Run `/browser:install` command

### Task 1.4: Repository Structure Familiarization

**Purpose**: Understand Innovation Nexus repository organization and locate key resources

**Steps**:
```bash
# 1. Explore repository structure
tree -L 2 .claude/
# OR on Windows without tree:
Get-ChildItem .claude -Recurse -Depth 2

# 2. Review key directories:
# - .claude/agents/         → 38+ agent specifications
# - .claude/commands/       → Slash command implementations
# - .claude/docs/           → Documentation (including this onboarding!)
# - .claude/templates/      → ADR, Runbook, Research templates
# - .claude/logs/           → Agent Activity Log (reference)
# - .claude/utils/          → PowerShell utilities (Key Vault, MCP, etc.)

# 3. Read master reference documentation
# Open in VS Code or preferred markdown viewer:
code .claude/CLAUDE.md
```

**Success Criteria**:
- ✅ Located agent specifications directory (`.claude/agents/`)
- ✅ Found slash command directory (`.claude/commands/`)
- ✅ Reviewed master reference (`CLAUDE.md`)
- ✅ Understand repository organization

**Key Directories to Bookmark**:
- **Agents**: `.claude/agents/` - All 38+ agent specifications with usage patterns
- **Commands**: `.claude/commands/` - Slash command syntax and examples
- **Docs**: `.claude/docs/` - Comprehensive guides (innovation workflow, architecture, etc.)
- **Utils**: `.claude/utils/` - Helper scripts (KeyVault access, MCP health checks, etc.)

### Task 1.5: First Slash Command Execution

**Purpose**: Execute your first Innovation Nexus command to validate complete workflow

**Steps**:
```bash
# 1. In Claude Code, run subscription list command
/subscription:list

# Expected output:
# Subscription: Brookside BI Production
# ID: cfacbbe8-a2a3-445f-a188-68b3b35f0c84
# State: Enabled
# Is Default: true

# 2. Test innovation command (dry run - won't create anything)
# Ask Claude Code: "Search Ideas Registry for 'invoice' keyword"

# 3. Test cost command
/cost:monthly-spend

# Expected output:
# Total Software Spend: $X,XXX/month
# (Based on current Software & Cost Tracker entries)
```

**Success Criteria**:
- ✅ Slash commands execute without errors
- ✅ Notion searches return results
- ✅ Cost calculations display correctly
- ✅ Comfortable with command syntax

**Day 1 Complete** ✅

**Self-Assessment**:
- Can authenticate to Azure CLI? ☐
- Environment variables configured? ☐
- All MCP servers connected? ☐
- Understand repository structure? ☐
- Successfully executed slash commands? ☐

**If all checked**: Proceed to Day 2. **If not**: Review troubleshooting sections or request support in #innovation-nexus-support Slack channel.

---

## Day 2: First Idea Capture and Research Coordination

**Goal**: Contribute your first innovation idea with viability assessment and initiate research coordination for high-potential concepts.

**Time Estimate**: 1-2 hours

### Task 2.1: Search for Existing Ideas (Protocol Practice)

**Purpose**: Practice the "search-first" protocol to prevent duplicate entries

**Steps**:
```bash
# 1. Think of an innovation idea related to your work
# Example: "Automated expense report processing with OCR"

# 2. ALWAYS search first (CRITICAL habit to develop)
# In Claude Code, ask:
"Search Ideas Registry for expense report automation"

# Agent will execute:
mcp__notion__notion-search {
  "query": "expense report automation",
  "data_source_url": "collection://984a4038-3e45-4a98-8df4-fd64dd8a1032"
}

# 3. Review results
# - If match found: Review existing idea, add comments/updates
# - If no match: Proceed to idea creation
```

**Success Criteria**:
- ✅ Conducted search before attempting creation
- ✅ Reviewed search results to confirm no duplicates
- ✅ Understand "search-first" rationale (prevent duplicate work)

**Common Patterns to Search**:
- Core concept keywords: "expense", "invoice", "dashboard"
- Technology keywords: "Azure OpenAI", "Power BI", "OCR"
- Process keywords: "automation", "reporting", "analysis"

### Task 2.2: Create Your First Idea

**Purpose**: Capture an innovation opportunity with structured viability assessment

**Steps**:
```bash
# 1. Use slash command (recommended approach)
/innovation:new-idea "Automated expense report processing with Azure AI Document Intelligence"

# 2. Review agent's proposal
# Agent will suggest:
# - Viability assessment (High/Medium/Low/Needs Research)
# - Business value estimate
# - Technical complexity estimate
# - Team assignment based on expertise
# - Next steps recommendation

# 3. Approve creation (agent will ask for confirmation)

# 4. Verify entry in Notion
# Visit: https://www.notion.so/Ideas-Registry
# Find your idea (format: "💡 [Your Idea Name]")
```

**Success Criteria**:
- ✅ Idea created in Notion Ideas Registry
- ✅ Viability assessment assigned (High/Medium/Low/Needs Research)
- ✅ Team owner assigned appropriately
- ✅ Next steps documented

**Idea Quality Guidelines**:
- **Good**: "Automated expense report processing with Azure AI Document Intelligence"
  - Specific: Clear what it does
  - Technical: Mentions Azure service
  - Valuable: Obvious business benefit

- **Needs Improvement**: "Make expenses better"
  - Vague: What improvement?
  - No technology mentioned
  - Unclear business value

### Task 2.3: Initiate Research for High-Viability Idea

**Purpose**: Coordinate 4-agent research swarm for feasibility investigation

**Prerequisite**: Idea must have "Needs Research" viability status (if your idea is already High/Medium/Low, choose a different idea or change status manually)

**Steps**:
```bash
# 1. Identify idea requiring research
# In Claude Code, ask:
"Which ideas in Ideas Registry have 'Needs Research' viability?"

# 2. Select idea for research (use your own from Task 2.2 OR existing idea)

# 3. Initiate research via slash command
/innovation:start-research "[research topic]" "[originating-idea-name]"

# Example:
/innovation:start-research "Azure AI Document Intelligence feasibility for expense reports" "Automated Expense Report Processing"

# 4. Monitor research swarm execution
# Agent will invoke in parallel:
# - @market-researcher (competitive analysis, demand validation)
# - @technical-analyst (implementation complexity, architecture)
# - @cost-feasibility-analyst (TCO, ROI projections)
# - @risk-assessor (security, compliance, technical debt)

# 5. Review viability score and recommendation
# Expected duration: 2-4 hours (autonomous)
# Result: 0-100 viability score with Go/No-Go recommendation
```

**Success Criteria**:
- ✅ Research Hub entry created in Notion
- ✅ Linked to originating Idea (relation established)
- ✅ 4-agent swarm executed (market, technical, cost, risk findings documented)
- ✅ Viability score calculated (0-100)
- ✅ Executive summary with recommendation

**Viability Score Interpretation**:
- **85-100**: Auto-approved for build (proceed to Week 1 build task)
- **60-84**: Team review required (schedule discussion with team lead)
- **0-59**: Archive with learnings (document why not viable for future reference)

### Task 2.4: Review Research Findings

**Purpose**: Analyze research output to understand data-driven decision framework

**Steps**:
```bash
# 1. Navigate to Research Hub in Notion
# URL: https://www.notion.so/Research-Hub
# Or search: "Search Research Hub for [your research topic]"

# 2. Open your research entry

# 3. Review each agent's findings:
# - Market Findings: Competitive landscape, demand validation, market size
# - Technical Findings: Implementation complexity, architecture recommendations
# - Cost Findings: TCO calculation, ROI timeline, cost breakdown
# - Risk Findings: Security concerns, compliance requirements, technical debt

# 4. Analyze viability score components:
# - Market Score (25%): How strong is market opportunity?
# - Technical Feasibility (30%): How complex is implementation?
# - Cost/ROI Score (25%): What's the financial return?
# - Risk Assessment (20%): What could go wrong?

# 5. Read executive summary and recommendation
# - Go: Proceed to build (Week 1 task)
# - Review: Schedule team discussion
# - No-Go: Archive with documented learnings
```

**Success Criteria**:
- ✅ Understand how viability score is calculated (weighted average)
- ✅ Can explain each agent's contribution to final score
- ✅ Reviewed executive summary recommendation
- ✅ Know next steps based on viability score

**Day 2 Complete** ✅

**Self-Assessment**:
- Successfully created first idea? ☐
- Practiced search-first protocol? ☐
- Initiated research swarm? ☐
- Understand viability scoring? ☐
- Know how to interpret research findings? ☐

---

## Day 3: Cost Analysis and Repository Intelligence

**Goal**: Develop cost visibility through Software Tracker analysis and repository intelligence through GitHub portfolio scanning.

**Time Estimate**: 1-2 hours

### Task 3.1: Software Cost Analysis

**Purpose**: Understand current software spending and identify optimization opportunities

**Steps**:
```bash
# 1. Query total monthly spend
/cost:monthly-spend

# Expected output:
# Total Software Spend: $X,XXX/month ($XX,XXX/year)

# 2. Analyze top expenses
/cost:top-expenses

# Review top 5 most expensive tools:
# 1. [Software Name] - $X,XXX/month
# 2. [Software Name] - $XXX/month
# ...

# 3. Identify unused software (waste)
/cost:unused-software

# Expected output:
# Tools with 0% utilization:
# - [Software Name] ($XXX/month) - No usage in 90 days
# - [Software Name] ($XX/month) - No active projects

# 4. Find consolidation opportunities
/cost:consolidation-opportunities

# Expected output:
# Duplicate capabilities detected:
# - Project Management: Asana + Monday.com → Microsoft Planner (included in M365)
# - Communication: Slack → Microsoft Teams (included in M365)

# 5. Calculate potential savings
# Sum unused software + consolidation opportunities
```

**Success Criteria**:
- ✅ Identified total monthly software spend
- ✅ Located top 5 most expensive tools
- ✅ Found at least 1 unused software (if exists)
- ✅ Identified consolidation opportunities
- ✅ Calculated potential savings

**Expected Insights**:
- **Typical Findings**: $500-$2,000/month in unused software
- **Common Consolidations**: Communication tools → Teams, Project management → Planner
- **Microsoft-First Principle**: Check if capability exists in M365/Azure before purchasing third-party

### Task 3.2: Deep-Dive on Specific Software

**Purpose**: Analyze individual software entry in Software & Cost Tracker

**Steps**:
```bash
# 1. Choose a software tool to analyze (e.g., "Azure Subscription")
# In Claude Code, ask:
"Fetch Azure Subscription entry from Software & Cost Tracker"

# Agent will execute:
mcp__notion__notion-search {
  "query": "Azure Subscription",
  "data_source_url": "collection://13b5e9de-2dd1-45ec-839a-4f3d50cd8d06"
}
# Then fetch the page for details

# 2. Review properties:
# - Cost per License: $XXX
# - License Count: X
# - Total Monthly Cost: $X,XXX (formula: Cost × Count)
# - Utilization: High/Medium/Low/None
# - Used By Builds: [List of builds using this software]
# - Used By Research: [List of research using this software]
# - Used By Ideas: [List of ideas using this software]

# 3. Analyze utilization:
# - How many builds/research/ideas use this tool?
# - If zero: Candidate for cancellation
# - If low: Candidate for right-sizing (reduce license count)

# 4. Check for Microsoft alternatives
# Review "Microsoft Alternative" field:
# - If populated: Consider consolidation to M365/Azure
# - If empty: Research Microsoft ecosystem for replacement
```

**Success Criteria**:
- ✅ Retrieved detailed software entry from Notion
- ✅ Understand cost rollup formula (Cost per License × License Count)
- ✅ Analyzed utilization via "Used By" relations
- ✅ Identified Microsoft alternative (if applicable)

**Cost Optimization Exercise**:
```bash
# If you find unused software:
# 1. Document in Slack #finance channel
# 2. Recommend cancellation with savings calculation
# 3. Update Status = "Inactive" in Software Tracker
# 4. Track savings in monthly cost review
```

### Task 3.3: Repository Portfolio Scan

**Purpose**: Analyze GitHub organization repositories with automated viability scoring and Claude Code integration detection

**Steps**:
```bash
# 1. Scan all repositories in brookside-bi organization
/repo:scan-org --sync

# Expected duration: 5-10 minutes (depending on repo count)

# Agent will:
# - Scan all repos in GitHub organization
# - Calculate viability scores (0-100) based on:
#   * Test Coverage (30 points)
#   * Activity Score (20 points)
#   * Documentation Quality (25 points)
#   * Dependency Health (25 points)
# - Detect Claude Code integration maturity (Expert/Advanced/Intermediate/Basic/None)
# - Sync results to Notion Example Builds database

# 2. Review scan results
# Output includes:
# - Total repositories scanned
# - High viability repos (75-100)
# - Medium viability repos (50-74)
# - Low viability repos (<50)
# - Claude Code integration breakdown

# 3. Identify top performers
# Example:
# 1. innovation-nexus (Score: 94, Claude: Expert)
# 2. azure-bicep-templates (Score: 89, Claude: Advanced)
# 3. power-bi-governance (Score: 85, Claude: Advanced)

# 4. Identify repos needing attention
# Example:
# 1. legacy-reporting-api (Score: 34, Claude: None) - No tests, inactive
# 2. poc-chatbot (Score: 42, Claude: Basic) - Missing docs, deprecated deps
```

**Success Criteria**:
- ✅ Successfully scanned all organization repositories
- ✅ Viability scores calculated for each repo
- ✅ Claude Code maturity detected
- ✅ Results synced to Notion Example Builds
- ✅ Identified top performers and repos needing attention

**Viability Score Breakdown**:
```
Total Score (0-100) =
  Test Coverage (30 points):
    - >80% coverage: 30 points
    - 50-80%: 20 points
    - <50%: 10 points
    - No tests: 0 points

  Activity Score (20 points):
    - Active (commits <30 days): 20 points
    - Recent (30-90 days): 15 points
    - Stale (90-180 days): 10 points
    - Inactive (>180 days): 0 points

  Documentation (25 points):
    - Comprehensive (README + architecture + API docs): 25 points
    - Good (README + one other): 18 points
    - Basic (README only): 10 points
    - None: 0 points

  Dependencies (25 points):
    - Up-to-date: 25 points
    - Minor outdated: 18 points
    - Major outdated: 10 points
    - Security vulnerabilities: 0 points
```

### Task 3.4: Analyze Single Repository (Deep Dive)

**Purpose**: Perform detailed viability assessment on individual repository

**Steps**:
```bash
# 1. Choose a repository for deep analysis
# Recommend: Choose a repo you work on frequently

# 2. Run deep analysis
/repo:analyze [repo-name] --deep --sync

# Example:
/repo:analyze innovation-nexus --deep --sync

# 3. Review detailed breakdown:
# - Overall Score: XX/100
# - Test Coverage: XX/30 (X% coverage, X test files)
# - Activity: XX/20 (last commit X days ago, X contributors)
# - Documentation: XX/25 (README, architecture docs, API docs present?)
# - Dependencies: XX/25 (X packages, X outdated, X vulnerabilities)

# 4. Review improvement recommendations
# Example output:
# "Improvement Path (Estimated: 40 hours):
#  1. Add unit tests (20 hours) → +25 points
#  2. Update dependencies (8 hours) → +7 points
#  3. Complete documentation (6 hours) → +10 points
#  4. Establish CI/CD pipeline (6 hours) → +5 points
#  Projected Score After Improvements: 81/100"

# 5. If score < 50: Consider archival vs. rebuild decision
```

**Success Criteria**:
- ✅ Deep analysis completed for chosen repository
- ✅ Understand score breakdown across 4 dimensions
- ✅ Reviewed improvement recommendations
- ✅ Know how to interpret viability scores for technical decisions

**Day 3 Complete** ✅

**Self-Assessment**:
- Analyzed software spending? ☐
- Identified cost optimization opportunities? ☐
- Successfully scanned GitHub portfolio? ☐
- Understand viability scoring methodology? ☐
- Can deep-dive analyze individual repositories? ☐

---

## Week 1: First Build Creation

**Goal**: Experience the complete autonomous build pipeline from high-viability idea to deployed Azure application with CI/CD.

**Time Estimate**: 3-4 hours (mostly autonomous - 40-60 min pipeline execution + review time)

**Prerequisite**: High-viability idea (score >85) from Day 2 research OR create new high-confidence idea

### Task W1.1: Select Build Candidate

**Purpose**: Choose appropriate idea for autonomous build pipeline

**Steps**:
```bash
# 1. Review Ideas Registry for high-viability candidates
# In Claude Code, ask:
"Show me all ideas with 'High' viability or research viability score >85"

# 2. Selection criteria:
# ✅ Clear business value (solve real problem)
# ✅ Feasible scope (can build in 40-60 min autonomous pipeline)
# ✅ Azure-compatible (uses Azure services)
# ✅ Team approval (if required for your role)

# 3. Good build candidates for first attempt:
# - Simple API with Azure Functions
# - Static website with Azure App Service
# - Data processing pipeline with Azure Storage + Functions
# - Form submission handler with Azure Form Recognizer

# 4. Avoid for first build:
# - Complex microservices architectures
# - Real-time systems requiring SignalR/WebSockets
# - Machine learning model training (long-running)
# - Multi-tenant SaaS platforms
```

**Success Criteria**:
- ✅ Selected idea with high viability (>85 OR manually assessed as feasible)
- ✅ Scope is appropriate for 40-60 min build
- ✅ Understand business value and technical approach
- ✅ Team approval obtained (if required)

**Recommended First Build**: "Simple REST API for [data operation] with Azure Functions"

### Task W1.2: Execute Autonomous Build Pipeline

**Purpose**: Deploy production-ready application via 3-agent pipeline (build-architect-v2 → code-generator → deployment-orchestrator)

**Steps**:
```bash
# 1. Initiate autonomous pipeline
/autonomous:enable-idea "[your-idea-name]"

# Example:
/autonomous:enable-idea "Simple REST API for Task Management"

# 2. Monitor pipeline execution (approximate timing):
# Phase 1: Architecture Design (10-15 min)
#   - @build-architect-v2 designs Azure resources
#   - Generates Bicep infrastructure-as-code
#   - Creates environment configs (dev/staging/prod)
#   Output: Architecture diagram + Bicep templates

# Phase 2: Code Generation (15-20 min)
#   - @code-generator creates application code
#   - Generates unit tests (80%+ coverage target)
#   - Writes README and API documentation
#   Output: Complete codebase with tests

# Phase 3: Deployment (15-25 min)
#   - @deployment-orchestrator provisions Azure resources
#   - Deploys application to Azure
#   - Sets up CI/CD pipeline (GitHub Actions)
#   - Configures monitoring (Application Insights)
#   Output: Live application + CI/CD pipeline

# 3. Review deliverables during execution
# Agent will provide progress updates:
# - "Architecture design complete. Review diagram?"
# - "Code generation complete. Review repository structure?"
# - "Deployment in progress. Azure resource provisioning..."
# - "Deployment complete! Application available at [URL]"
```

**Success Criteria**:
- ✅ Pipeline completed successfully (all 3 phases)
- ✅ GitHub repository created with code
- ✅ Azure resources provisioned
- ✅ Application deployed and accessible
- ✅ CI/CD pipeline operational (GitHub Actions)
- ✅ Monitoring configured (Application Insights)

**Expected Duration**: 40-60 minutes (fully autonomous)

**Pipeline Troubleshooting**:
- **Architecture phase fails**: Likely invalid service combination or quota issue
  - Resolution: Review architecture recommendations, adjust scope if needed
- **Code generation fails**: Typically dependency version conflicts
  - Resolution: Review error logs, update dependency specifications
- **Deployment fails**: Often Azure quota limits or naming conflicts
  - Resolution: Check Azure Portal for quota, ensure unique resource names

### Task W1.3: Verify Deployment

**Purpose**: Validate deployed application health and functionality

**Steps**:
```bash
# 1. Navigate to deployed application URL
# Agent provides URL in deployment summary:
# "Deployment URL: https://[app-name].azurewebsites.net"

# 2. Test health check endpoint
# In browser or curl:
curl https://[app-name].azurewebsites.net/api/health

# Expected response:
# {"status": "healthy", "timestamp": "2025-01-15T10:30:00Z"}

# 3. Review Azure resources in Portal
# URL: https://portal.azure.com
# Navigate to Resource Group: rg-[project-name]-prod

# Verify resources created:
# ✅ App Service Plan (B1 or P1v2 depending on environment)
# ✅ Function App or App Service (application host)
# ✅ Storage Account (for application data/queues)
# ✅ Key Vault (for secrets management)
# ✅ Application Insights (for monitoring)

# 4. Check CI/CD pipeline
# URL: https://github.com/brookside-bi/[repo-name]/actions
# Verify:
# ✅ GitHub Actions workflow exists (.github/workflows/deploy.yml)
# ✅ Initial deployment workflow completed successfully (green checkmark)
# ✅ Branch protection rules enabled (main branch)

# 5. Review Application Insights dashboard
# Azure Portal → Application Insights → [your-app-insights]
# Check:
# ✅ Telemetry flowing (requests, dependencies, exceptions)
# ✅ Availability monitoring configured
# ✅ Alerts configured (error rate, response time)
```

**Success Criteria**:
- ✅ Health check endpoint returns 200 OK
- ✅ All Azure resources provisioned correctly
- ✅ CI/CD pipeline operational (green build)
- ✅ Application Insights telemetry flowing
- ✅ No errors in deployment logs

### Task W1.4: Link Build to Notion

**Purpose**: Establish complete traceability and cost tracking for build

**Steps**:
```bash
# 1. Verify Example Builds entry exists
# Navigate to Notion Example Builds database
# Search for your build name: "🛠️ [Build Name]"

# 2. Verify required relations are linked:
# ✅ Originating Idea: [Link to your idea from Day 2]
# ✅ Related Research: [Link to research if exists]
# ✅ Software Used: [CRITICAL - must link ALL software/tools]

# 3. Link all software used (REQUIRED for cost tracking):
# In Claude Code, ask:
"Link the following software to my build '[build-name]':
- Azure Subscription
- GitHub Enterprise
- [Any other services used]"

# Agent will execute:
mcp__notion__notion-update-page {
  "data": {
    "page_id": "[build-page-id]",
    "command": "update_properties",
    "properties": {
      "Software Used": [
        "[azure-subscription-page-id]",
        "[github-enterprise-page-id]",
        "[application-insights-page-id]"
      ]
    }
  }
}

# 4. Verify Total Cost formula calculated correctly
# In Notion, check "Total Cost" column
# Expected: SUM(Cost per License × License Count) for all linked software
# Example: $267 (Azure) + $84 (GitHub) + $15 (App Insights) = $366/month

# 5. Update build properties:
# - Status: "✅ Completed"
# - Repository URL: [GitHub repo link]
# - Deployment URL: [Azure app URL]
# - Deployed Date: [Today's date]
```

**Success Criteria**:
- ✅ Example Builds entry exists in Notion
- ✅ Linked to originating Idea and Research (if exists)
- ✅ ALL software linked (Azure + GitHub + any other services)
- ✅ Total Cost formula shows correct monthly cost
- ✅ Repository URL and Deployment URL populated
- ✅ Status updated to Completed

**Critical**: If Total Cost shows $0 despite linking software, verify Software Tracker entries have "Cost per License" and "License Count" populated.

### Task W1.5: Test CI/CD Pipeline

**Purpose**: Validate continuous deployment by making code change and observing auto-deployment

**Steps**:
```bash
# 1. Clone repository locally
git clone https://github.com/brookside-bi/[repo-name].git
cd [repo-name]

# 2. Create feature branch
git checkout -b test-cicd

# 3. Make trivial code change
# Edit README.md or add comment to code file

# 4. Commit and push
git add .
git commit -m "test: Validate CI/CD pipeline with trivial change"
git push origin test-cicd

# 5. Create pull request
# Via GitHub web UI:
# https://github.com/brookside-bi/[repo-name]/pulls
# Click "New Pull Request"
# Base: main, Compare: test-cicd
# Create pull request

# 6. Observe CI/CD execution
# GitHub Actions tab should show:
# ✅ Build workflow triggered automatically
# ✅ Tests executed (all passing)
# ✅ Code quality checks passed
# ⏳ Deployment to staging (if configured)

# 7. Merge pull request (if all checks pass)

# 8. Observe production deployment
# After merge to main:
# ✅ Production deployment workflow triggered
# ✅ Azure resources updated
# ⏳ Deployment completes (2-5 minutes)

# 9. Verify changes deployed
# Visit deployment URL and confirm changes visible
```

**Success Criteria**:
- ✅ Feature branch created and pushed
- ✅ CI/CD pipeline triggered automatically
- ✅ All tests and checks passed
- ✅ Deployment to Azure succeeded
- ✅ Changes visible on production deployment

**Week 1 Complete** ✅

**Self-Assessment**:
- Selected appropriate build candidate? ☐
- Executed autonomous pipeline successfully? ☐
- Verified deployment health? ☐
- Linked build to Notion with cost tracking? ☐
- Tested CI/CD pipeline? ☐

---

## Week 2: Knowledge Vault Contribution and Optimization

**Goal**: Contribute to institutional knowledge through pattern archival and identify system optimization opportunities.

**Time Estimate**: 2-3 hours

### Task W2.1: Archive Build Learnings

**Purpose**: Preserve patterns, lessons learned, and troubleshooting guides in Knowledge Vault

**Steps**:
```bash
# 1. Archive your Week 1 build
/knowledge:archive "[your-build-name]" build

# Agent will:
# - Extract lessons learned (successes and failures)
# - Identify reusable architectural patterns
# - Calculate cost actuals vs. estimates
# - Document common issues and resolutions
# - Create Knowledge Vault entry with search tags

# 2. Review Knowledge Vault entry
# Navigate to Notion Knowledge Vault
# Find your entry: "📚 [Build Name] - [Pattern/Lesson]"

# 3. Verify content quality:
# ✅ Lessons Learned section (what worked, what didn't)
# ✅ Reusable Patterns section (code snippets, architecture diagrams)
# ✅ Cost Actuals (actual spend vs. estimate, variance %)
# ✅ Troubleshooting section (common errors and fixes)
# ✅ Search Keywords (technology tags for discoverability)

# 4. Enhance with personal insights
# Add your own observations:
# - Development challenges you faced
# - Alternative approaches you considered
# - Recommendations for future similar projects
```

**Success Criteria**:
- ✅ Knowledge Vault entry created
- ✅ Linked to origin Build
- ✅ Lessons learned documented (successes AND failures)
- ✅ Reusable patterns identified and preserved
- ✅ Cost actuals vs. estimates calculated
- ✅ Search keywords populated for discoverability

**Knowledge Quality Checklist**:
```markdown
# High-Quality Knowledge Entry
✅ Clear problem statement (what were we trying to solve?)
✅ Solution approach with code examples
✅ Lessons learned (at least 3: what worked, what didn't, what to do differently)
✅ Reuse instructions (how to apply this pattern to new projects)
✅ Cost breakdown (actual vs. estimated with variance %)
✅ Technology tags for searchability
```

### Task W2.2: Search and Reuse Existing Pattern

**Purpose**: Practice knowledge discovery and pattern reuse to accelerate development

**Steps**:
```bash
# 1. Think of a new micro-project you could build
# Example: "Simple notification service with Azure Service Bus"

# 2. Search Knowledge Vault for related patterns
# In Claude Code, ask:
"Search Knowledge Vault for Azure Service Bus messaging patterns"

# Agent executes:
mcp__notion__notion-search {
  "query": "Azure Service Bus messaging",
  "query_type": "internal"
}

# 3. Review pattern matches
# Example results:
# - "Azure Service Bus Queue Processing Pattern" (Reusability: High)
# - "Managed Identity Authentication for Azure Services" (Reusability: High)
# - "Bicep Multi-Environment Deployment Pattern" (Reusability: High)

# 4. Fetch pattern details
# In Claude Code, ask:
"Fetch the Azure Service Bus Queue Processing Pattern from Knowledge Vault"

# 5. Analyze reuse potential
# Review:
# - Code snippets (can I use these directly?)
# - Architecture diagram (does this fit my use case?)
# - Reuse instructions (what do I need to customize?)
# - Time saved estimate (how much faster will this be?)

# 6. Estimate time savings
# Example:
# - Building from scratch: 8 hours
# - Using pattern: 2 hours (customize + integrate)
# - Time saved: 6 hours (75% reduction)
```

**Success Criteria**:
- ✅ Searched Knowledge Vault for relevant patterns
- ✅ Found at least 1 reusable pattern
- ✅ Reviewed pattern code and documentation
- ✅ Estimated time savings from reuse
- ✅ Understand pattern reuse workflow

**Pattern Reuse Workflow**:
```
1. Search Knowledge Vault for relevant technology/pattern
2. Review reusability rating (High/Medium/Low)
3. Fetch pattern details and code snippets
4. Customize for your specific use case
5. Integrate into your project
6. Update pattern usage count in Knowledge Vault
7. Document any enhancements you made
```

### Task W2.3: Agent Activity Review

**Purpose**: Understand agent productivity tracking and contribution visibility

**Steps**:
```bash
# 1. Navigate to Agent Activity Hub in Notion
# URL: https://www.notion.so/72b879f213bd4edb9c59b43089dbef21
# Or search: "Agent Activity Hub"

# 2. Review recent agent sessions
# Filter by your work (look for sessions during your build)

# 3. Analyze a completed session:
# - Agent: Which agent performed the work?
# - Status: In Progress / Completed / Blocked
# - Work Description: What was accomplished?
# - Files Changed: What deliverables were created?
# - Duration: How long did it take?
# - Notion Items: What Ideas/Research/Builds were involved?

# 4. Generate activity summary
/agent:activity-summary week all

# Expected output:
# Agent Activity Summary (Last 7 Days):
# Total Sessions: X
# Total Duration: XX hours
# Most Active Agents:
# 1. @build-architect-v2 (X sessions, XX hours)
# 2. @code-generator (X sessions, XX hours)
# 3. @deployment-orchestrator (X sessions, XX hours)

# 5. Understand automatic activity logging
# Review: .claude/docs/CLAUDE.md section "Agent Activity Center"
# Learn how Phase 4 hook-based automation captures work without manual logging
```

**Success Criteria**:
- ✅ Located Agent Activity Hub in Notion
- ✅ Reviewed recent agent sessions
- ✅ Generated weekly activity summary
- ✅ Understand automatic activity logging mechanism
- ✅ Know how to query agent productivity data

### Task W2.4: Output Styles Testing

**Purpose**: Explore communication pattern optimization through style testing

**Steps**:
```bash
# 1. Test an agent with multiple output styles
/test-agent-style @markdown-expert ?

# This tests @markdown-expert with all 5 styles:
# 1. Technical Implementer (code-heavy, developer-focused)
# 2. Strategic Advisor (business-focused, executive-friendly)
# 3. Visual Architect (diagram-rich, cross-functional teams)
# 4. Interactive Teacher (educational, onboarding-friendly)
# 5. Compliance Auditor (formal, evidence-based, audit-ready)

# 2. Review test results
# Output includes metrics for each style:
# - Effectiveness Score (0-100)
# - Technical Density (0-1)
# - Formality Score (0-1)
# - Clarity Score (0-1)
# - Generation Time

# 3. Compare styles side-by-side
/style:compare @markdown-expert "Create API documentation for expense processing endpoints"

# 4. Review recommended style
# Agent will show:
# 🎯 Recommendation: [Style Name]
# Rationale: [Why this style fits the task and audience]

# 5. Explore Notion test results
# Navigate to Agent Style Tests database
# Find your test entries (format: "AgentName-StyleName-YYYYMMDD")
```

**Success Criteria**:
- ✅ Tested agent with all 5 output styles
- ✅ Reviewed effectiveness metrics for each style
- ✅ Compared styles side-by-side
- ✅ Understand style selection rationale
- ✅ Located test results in Notion

**Style Selection Guidelines**:
```
Technical Implementer:
  → Use when: Developers need code examples, API docs, technical specs
  → Characteristics: High technical density, code blocks, precise terminology

Strategic Advisor:
  → Use when: Executives need business analysis, ROI, strategic recommendations
  → Characteristics: Business-focused, outcome-oriented, minimal technical jargon

Visual Architect:
  → Use when: Cross-functional teams need system diagrams, data flow visualization
  → Characteristics: Diagram-rich, visual explanations, architecture focus

Interactive Teacher:
  → Use when: Training new team members, creating tutorials, knowledge transfer
  → Characteristics: Step-by-step, examples, progressive complexity

Compliance Auditor:
  → Use when: Auditors need evidence, compliance documentation, formal reports
  → Characteristics: Formal language, evidence-based, regulatory focus
```

### Task W2.5: Continuous Improvement Contribution

**Purpose**: Identify and document system optimization opportunities

**Steps**:
```bash
# 1. Reflect on your first 2 weeks
# Consider:
# - What was confusing or unclear?
# - What took longer than expected?
# - What documentation was missing or incomplete?
# - What patterns could be reused more effectively?

# 2. Create improvement idea
/innovation:new-idea "[Your improvement suggestion]"

# Examples of valuable improvements:
# - "Automated onboarding checklist validation"
# - "Pattern discovery dashboard in Notion"
# - "Cost anomaly detection alerts"
# - "Repository health trending visualization"

# 3. Share onboarding feedback
# In Slack #innovation-nexus-support:
# - What worked well?
# - What could be improved?
# - What documentation was most helpful?
# - What should be added to this Quick Start Checklist?

# 4. Update local documentation
# If you found gaps, update docs:
# - Add troubleshooting steps you discovered
# - Clarify confusing instructions
# - Add examples that would have helped you

# 5. Consider advanced topics
# Next learning areas:
# - Phase 3 autonomous pipeline internals (.claude/agents/build-architect-v2.md)
# - Repository analyzer architecture (brookside-repo-analyzer/docs/ARCHITECTURE.md)
# - MCP server development (.claude/docs/mcp-configuration.md)
# - Custom agent creation (.claude/agents/README.md)
```

**Success Criteria**:
- ✅ Documented at least 1 improvement suggestion
- ✅ Shared onboarding feedback with team
- ✅ Updated documentation with learnings (if gaps found)
- ✅ Identified next learning areas
- ✅ Comfortable with Innovation Nexus workflows

**Week 2 Complete** ✅

**Final Self-Assessment**:
- Archived build learnings to Knowledge Vault? ☐
- Successfully searched and reused existing pattern? ☐
- Reviewed agent activity tracking? ☐
- Tested output styles and understand selection criteria? ☐
- Contributed improvement suggestions? ☐

---

## Onboarding Complete - Next Steps

**Congratulations!** You've completed the Innovation Nexus Quick Start and are now proficient with:

✅ **Environment Setup**: Azure CLI, MCP servers, Key Vault access
✅ **Idea Capture**: Search-first protocol, viability assessment, team assignment
✅ **Research Coordination**: 4-agent swarm, viability scoring, data-driven decisions
✅ **Cost Management**: Software tracking, waste identification, optimization opportunities
✅ **Repository Intelligence**: Portfolio scanning, viability assessment, pattern mining
✅ **Autonomous Builds**: 3-agent pipeline, Azure deployment, CI/CD setup
✅ **Knowledge Preservation**: Pattern archival, lesson documentation, institutional memory

### Advanced Topics to Explore

1. **Phase 3 Autonomous Pipeline Internals**
   - Deep-dive: `.claude/agents/build-architect-v2.md`
   - Learn: Architecture design patterns, Bicep template generation, cost optimization strategies
   - Duration: 2-3 hours

2. **Repository Analyzer Architecture**
   - Deep-dive: `brookside-repo-analyzer/docs/ARCHITECTURE.md`
   - Learn: Viability scoring algorithms, Claude maturity detection, pattern extraction
   - Duration: 3-4 hours

3. **Custom Agent Development**
   - Deep-dive: `.claude/agents/README.md` (when created)
   - Learn: Agent specification format, invocation patterns, success criteria
   - Duration: 4-6 hours

4. **MCP Server Configuration and Extension**
   - Deep-dive: `.claude/docs/mcp-configuration.md`
   - Learn: MCP protocol, server development, custom tool creation
   - Duration: 4-6 hours

5. **Output Styles Advanced Optimization**
   - Deep-dive: `.claude/docs/output-styles-advanced-optimization.md`
   - Learn: Custom style creation, UltraThink analysis, quarterly optimization workflows
   - Duration: 2-3 hours

### Ongoing Responsibilities

**Weekly**:
- Review Agent Activity Hub for your agent sessions
- Search Knowledge Vault before starting new work (pattern reuse)
- Monitor software costs and utilization (quarterly deep-dive)

**Monthly**:
- Contribute at least 1 new idea to Ideas Registry
- Archive completed work to Knowledge Vault
- Review output style performance metrics

**Quarterly**:
- Comprehensive cost analysis (`/cost:analyze all`)
- Repository portfolio scan (`/repo:scan-org --deep --sync`)
- Knowledge Vault pattern curation (identify highly reusable patterns)

### Support Resources

**Documentation**:
- **Master Reference**: [CLAUDE.md](../../CLAUDE.md)
- **Innovation Workflow**: [.claude/docs/innovation-workflow.md](../innovation-workflow.md)
- **Team Structure**: [.claude/docs/team-structure.md](../team-structure.md)
- **Common Workflows**: [.claude/docs/common-workflows.md](../common-workflows.md)

**Slack Channels**:
- **#innovation-nexus-support**: Technical issues, questions, troubleshooting
- **#innovation-ideas**: Idea discussions, feasibility questions
- **#finance**: Cost optimization, budget discussions

**Team Contacts**:
- **Technical Issues**: Markus Ahling, Alec Fielding
- **Business/Cost Questions**: Brad Wright
- **Research Coordination**: Stephan Densby
- **Data/Quality Questions**: Mitch Bisbee

**Emergency Support**: Consultations@BrooksideBI.com

---

## Appendix: Common Issues and Resolutions

### Issue: MCP Server Disconnected

**Symptoms**: Commands fail with "MCP server not available"

**Resolution**:
```bash
# 1. Check MCP status
claude mcp list

# 2. Verify Azure authentication
az account show

# 3. Re-configure environment
.\scripts\Set-MCPEnvironment.ps1

# 4. Restart Claude Code
# Close terminal, reopen, run: claude
```

### Issue: Duplicate Notion Entries Created

**Symptoms**: Multiple Ideas with same name, cost rollups incorrect

**Resolution**:
```bash
# Prevention (ALWAYS do this):
# 1. Search BEFORE creating
mcp__notion__notion-search {
  "query": "[concept]",
  "data_source_url": "collection://[database-id]"
}

# Cleanup (if duplicates already exist):
# 2. Identify duplicates
# 3. Merge content into primary entry
# 4. Update all relations to point to primary
# 5. Archive duplicate entries (Status = "⚫ Not Active")
```

### Issue: Total Cost Shows $0

**Symptoms**: Build links software but formula shows $0

**Resolution**:
```bash
# Verify Software Tracker entries have:
# 1. Cost per License: [number]
# 2. License Count: [number]

# If missing, update:
mcp__notion__notion-update-page {
  "data": {
    "page_id": "[software-page-id]",
    "command": "update_properties",
    "properties": {
      "Cost per License": [amount],
      "License Count": [count]
    }
  }
}
```

### Issue: Autonomous Build Pipeline Fails

**Symptoms**: Pipeline errors during architecture, code, or deployment phase

**Resolution**:
```bash
# Architecture phase failure:
# - Check Azure quota limits
# - Verify service availability in region
# - Simplify architecture if too complex

# Code generation failure:
# - Review dependency version conflicts
# - Check language/framework compatibility
# - Verify SDK versions

# Deployment failure:
# - Verify Azure subscription quota
# - Check for resource name conflicts (must be globally unique)
# - Review deployment logs in Azure Portal
```

### Issue: GitHub Actions Workflow Not Triggering

**Symptoms**: Push to main but CI/CD doesn't run

**Resolution**:
```bash
# 1. Verify workflow file exists
# Path: .github/workflows/deploy.yml

# 2. Check branch protection rules
# GitHub → Settings → Branches → main

# 3. Verify GitHub Actions enabled
# GitHub → Settings → Actions → General
# Ensure: "Allow all actions and reusable workflows"

# 4. Check workflow syntax
# GitHub → Actions tab → Click workflow → View error details
```

---

**Quick Start Checklist - Your First 2 Weeks with Innovation Nexus**

**Established by**: Brookside BI Documentation Team
**Last Updated**: January 2025
**Next Review**: March 2025
