# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Brookside BI Innovation Nexus** - An innovation management system designed to establish structured approaches for tracking ideas from concept through research, building, and knowledge archival. This solution is designed for managing innovation workflow using Notion as the central hub with future Microsoft ecosystem integrations.

**Repository Purpose**: Streamline key workflows for innovation management through:
- Notion workspace management via MCP integration
- Future code integrations with Microsoft ecosystem (Azure, GitHub, SharePoint, Teams)
- Documentation generation and knowledge management
- Cost analysis and optimization for software/tools

## Core Architecture

### Innovation Workflow

```
💡 Idea (Concept)
  ↓ (if Needs Research)
🔬 Research (Active) → Viability Assessment
  ↓ (if Next Steps = Build Example)
🛠️ Example Build (Active) → Lessons Learned
  ↓ (when Complete)
📚 Knowledge Vault (Archived for Reference)
```

**Design Principles**:
- Status-driven, not timeline-driven: Active | Not Active | Concept | Archived
- Viability over deadlines: High | Medium | Low | Needs Research
- Every build is for learning - archive everything for future reference
- Cost transparency is critical - track all software/tool expenses
- Microsoft-first ecosystem - prioritize Microsoft solutions
- Agentic development - all technical documentation structured for AI agents

### Notion Database Architecture

The workspace consists of 7 interconnected databases:

1. **💡 Ideas Registry** - Innovation starting point
   - Status: Concept | Active | Not Active | Archived
   - Viability: High | Medium | Low | Needs Research
   - Relations: Research Hub, Example Builds, Software Tracker
   - Key Rollup: Estimated Cost (from linked software)

2. **🔬 Research Hub** - Feasibility investigation
   - Status: Concept | Active | Not Active | Completed
   - Viability Assessment: Highly Viable | Moderately Viable | Not Viable | Inconclusive
   - Next Steps: Build Example | More Research | Archive | Abandon
   - Relations: Ideas Registry, Software Tracker

3. **🛠️ Example Builds** - Working prototypes/demos
   - Status: Concept | Active | Not Active | Completed | Archived
   - Build Type: Prototype | POC | Demo | MVP | Reference Implementation
   - Viability: Production Ready | Needs Work | Reference Only
   - Reusability: Highly Reusable | Partially Reusable | One-Off
   - Relations: Ideas Registry, Research Hub, Software Tracker, Knowledge Vault
   - Key Rollup: Total Cost (from linked software)

4. **💰 Software & Cost Tracker** - Financial hub (central cost source)
   - Status: Active | Trial | Inactive | Cancelled
   - Category: Development | Infrastructure | Productivity | Analytics | Communication | Security | Storage | AI/ML | Design
   - Microsoft Service: Azure | M365 | Power Platform | GitHub | Dynamics | None
   - Formulas: Total Monthly Cost = Cost × License Count, Annual Cost = Cost × 12
   - Relations FROM: All other databases

5. **📚 Knowledge Vault** - Archived learnings
   - Status: Draft | Published | Deprecated | Archived
   - Content Type: Tutorial | Case Study | Technical Doc | Process | Template | Post-Mortem | Reference
   - Evergreen/Dated: Categorizes longevity
   - Relations: Ideas, Research, Builds, Software Tracker

6. **🔗 Integration Registry** - System connections
   - Integration Type: API | Webhook | Database | File Sync | Automation | Embed
   - Authentication Method: Azure AD | Service Principal | API Key | OAuth
   - Security Review Status: Approved | Pending | N/A
   - Relations: Software Tracker, Example Builds

7. **🎯 OKRs & Strategic Initiatives** - Alignment tracker
   - Status: Concept | Active | Not Active | Completed
   - Progress %: 0-100
   - Relations: Ideas Registry, Example Builds

**Database IDs**: After authenticating Notion MCP (restart Claude Code), query the workspace to document actual database IDs for programmatic access.

## Notion MCP Commands

### Authentication Setup

```bash
# Notion MCP is configured in .claude.json
# Restart Claude Code to activate authentication
claude mcp list  # Verify authentication status
```

### Standard Operations Protocol

**ALWAYS follow this search-first protocol:**

```
BEFORE creating anything:
1. Search for existing content (avoid duplicates)
2. Fetch related items to understand current structure
3. Check existing relations
4. Propose action to user
5. Execute with proper linking
```

### Common MCP Operations

**Search for existing content:**
```bash
# Search by query
notion-search "query text"

# Fetch specific page/database
notion-fetch "page-url-or-id"
```

**Creating Ideas:**
```
1. Search Ideas Registry for duplicates
2. Create entry with:
   - Status = "Concept" (default)
   - Viability = "Needs Research" or user-specified
   - Champion = Assigned based on team member specialization
   - Innovation Type = Appropriate category
   - Effort = Estimate (XS/S/M/L/XL)
   - Impact Score = 1-10 rating
3. Link related software from Software Tracker
4. Create relations to similar ideas if found
5. Prompt for next steps: Research needed? Build directly?
```

**Creating Research Entries:**
```
1. Create Research Hub entry with:
   - Status = "Active"
   - Link to originating Idea (required)
   - Hypothesis = Clear statement
   - Methodology = Approach description
   - Researchers = Team members
2. Link all software/tools being used
3. Set up SharePoint/OneNote links for detailed docs
4. Remind about final outputs:
   - Key Findings
   - Viability Assessment
   - Next Steps selection
```

**Creating Example Builds:**
```
1. Create Example Build entry with:
   - Status = "Active"
   - Build Type = Prototype/POC/Demo/MVP/Reference
   - Link to Origin Idea (required)
   - Link to Related Research (if exists)
   - Lead Builder = Assigned team member
   - Core Team = Supporting members
2. Get GitHub repo URL
3. Link ALL software/tools used (for cost rollup)
4. Set Reusability assessment
5. Create nested documentation page with:
   - Technical architecture (AI-agent friendly)
   - Setup instructions
   - API documentation
   - Configuration details
6. Prompt for Azure DevOps link, Teams channel
```

**Adding Software/Tools:**
```
1. Check if software exists in Software Tracker
2. If new, create entry with:
   - Cost = Monthly amount (normalize annual to monthly)
   - License Count = Number of seats
   - Status = Active/Trial/Inactive/Cancelled
   - Category = Appropriate classification
   - Microsoft Service = Mark if applicable
   - Owner = Responsible person
   - Users = All users
   - Authentication Method = How team accesses
   - Criticality = Critical/Important/Nice to Have
3. Auto-calculated formulas:
   - Total Monthly Cost = Cost × License Count
   - Annual Cost = Cost × 12
4. Show user: "This will add $X/month to your costs"
```

**Cost Analysis Operations:**
```python
# Total monthly spend
sum(Software Tracker where Status = "Active", field = "Total Monthly Cost")

# Annual projection
total_monthly × 12

# Top 5 most expensive
sort(Software Tracker by "Total Monthly Cost", desc, limit=5)

# Unused tools (optimization opportunity)
filter(Software Tracker where:
    relation_count(Ideas) = 0 AND
    relation_count(Research) = 0 AND
    relation_count(Builds) = 0
)

# Expiring contracts
filter(Software Tracker where:
    Contract End Date within 60 days AND
    Status = "Active"
)
```

**Archiving Protocol:**
```
When user says "archive this":
1. Update Status → "Archived" or "Not Active"
2. Check for documented learnings:
   - Ideas: Final viability assessment
   - Research: Key findings recorded
   - Builds: Lessons learned captured
3. Create Knowledge Vault entry if valuable:
   - Content Type = Post-Mortem or Case Study
   - Link to archived item
   - Evergreen/Dated = Assess longevity
4. Verify all links preserved:
   - GitHub repos still accessible
   - SharePoint/OneNote locations recorded
   - Software/tools still linked for cost tracking
5. Update any dependent items
```

## Team Structure & Specializations

### Team Members & Focus Areas

- **Markus Ahling**: Engineering, Operations, AI, Infrastructure
- **Brad Wright**: Sales, Business, Finance, Marketing
- **Stephan Densby**: Operations, Continuous Improvement, Research
- **Alec Fielding**: DevOps, Engineering, Security, Integrations, R&D, Infrastructure
- **Mitch Bisbee**: DevOps, Engineering, ML, Master Data, Quality

**Champion Assignment Rule**: Match idea/research/build to team member's specialization areas.

## Microsoft Ecosystem Integration

### Priority Order for Tool Selection

Organizations scaling technology across teams require structured approaches. This project prioritizes:

1. **Microsoft 365 Suite**: Teams, SharePoint, OneNote, Outlook
2. **Azure Services**: Azure OpenAI, Functions, SQL, DevOps, App Services
3. **Power Platform**: Power BI, Power Automate, Power Apps
4. **GitHub**: Enterprise repositories, Actions, Projects
5. **Third-party**: Only if Microsoft doesn't offer solution

### Standard Integration Links

- GitHub Organization: `github.com/brookside-bi`
- Azure Portal: [Portal link to be configured]
- SharePoint Site: [Root site URL to be configured]
- Teams Channels: [Team channels to be configured]
- Power BI Workspace: [Workspace URL to be configured]

## Azure Infrastructure

This project establishes secure, scalable Azure infrastructure for centralized secret management and resource deployment.

### Azure Subscription Configuration

**Active Subscription:**
- **Subscription Name**: Azure subscription 1
- **Subscription ID**: `cfacbbe8-a2a3-445f-a188-68b3b35f0c84`
- **Tenant Name**: Personal Portfolio
- **Tenant ID**: `2930489e-9d8a-456b-9de9-e4787faeab9c`

**Best for**: Organizations requiring centralized authentication and governance across all Microsoft services.

### Azure Key Vault - Centralized Secret Management

**Key Vault Configuration:**
- **Vault Name**: `kv-brookside-secrets`
- **Vault URI**: `https://kv-brookside-secrets.vault.azure.net/`
- **Purpose**: Single source of truth for all credentials, API keys, and sensitive configuration
- **Authentication**: Azure CLI (`az login`) for local development, Managed Identity for production

**Secrets Stored:**
```bash
# GitHub Integration
github-personal-access-token    # GitHub PAT with repo, workflow, admin:org scope

# Notion Integration (future)
notion-api-key                  # Notion integration token

# Azure OpenAI (future)
azure-openai-api-key           # Azure OpenAI service key
azure-openai-endpoint          # Azure OpenAI endpoint URL

# Additional secrets as needed
```

**Designed for**: Sustainable secret management that eliminates hardcoded credentials and enables secure team collaboration.

### Secret Retrieval Scripts

**PowerShell Scripts Location**: `scripts/`

1. **Get-KeyVaultSecret.ps1** - Retrieve individual secrets
   ```powershell
   # Usage: Retrieve a single secret
   .\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token"

   # Custom vault name
   .\scripts\Get-KeyVaultSecret.ps1 -SecretName "notion-api-key" -VaultName "kv-brookside-secrets"
   ```

2. **Set-MCPEnvironment.ps1** - Configure all MCP environment variables
   ```powershell
   # Set environment variables for current PowerShell session
   .\scripts\Set-MCPEnvironment.ps1

   # Set persistent user-level environment variables
   .\scripts\Set-MCPEnvironment.ps1 -Persistent
   ```

3. **Test-AzureMCP.ps1** - Validate Azure MCP server configuration
   ```powershell
   # Test Azure CLI authentication and MCP server startup
   .\scripts\Test-AzureMCP.ps1
   ```

**Important**: Always run `Set-MCPEnvironment.ps1` before launching Claude Code to ensure MCP servers have access to required credentials.

### Azure CLI Authentication

**Establish secure connection to Azure services:**

```powershell
# Login to Azure (opens browser for authentication)
az login

# Verify authentication status
az account show

# Set active subscription if you have multiple
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"

# Verify Key Vault access
az keyvault secret list --vault-name kv-brookside-secrets
```

**Designed for**: Seamless authentication across Azure services, Key Vault, and MCP servers.

## GitHub Integration

This project uses GitHub for version control with secure authentication via Azure Key Vault.

### GitHub Organization Structure

**Organization**: `github.com/brookside-bi`

**Repository**: (Current repository)
- **Purpose**: Innovation management system with Notion MCP integration
- **Visibility**: Private
- **Default Branch**: `main`

### GitHub Authentication

**Personal Access Token (PAT):**
- **Storage**: Azure Key Vault secret `github-personal-access-token`
- **Scopes Required**:
  - `repo` - Full repository access
  - `workflow` - GitHub Actions workflow management
  - `admin:org` - Organization administration (if needed)
- **Retrieval**: Use `Get-KeyVaultSecret.ps1` or `Set-MCPEnvironment.ps1`

**Automatic Authentication for Git Operations:**

```powershell
# Option 1: Set for current session
$env:GITHUB_PERSONAL_ACCESS_TOKEN = .\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token"
git config --global credential.helper store
git config --global user.name "Your Name"
git config --global user.email "your.email@brooksidebi.com"

# Option 2: Use Set-MCPEnvironment.ps1 (recommended)
.\scripts\Set-MCPEnvironment.ps1
```

### Branch Strategy

**Main Branches:**
- `main` - Production-ready code, protected branch
- `develop` - Integration branch for features (if using GitFlow)

**Feature Branches:**
- `feature/[description]` - New features or enhancements
- `fix/[description]` - Bug fixes
- `docs/[description]` - Documentation updates
- `refactor/[description]` - Code refactoring

**Best Practices:**
- Create pull requests for all changes to `main`
- Use conventional commit messages (aligned with Brookside BI brand guidelines)
- Link commits to Notion Idea/Research/Build entries when applicable
- Include Claude Code co-authorship attribution

### GitHub MCP Server

The GitHub MCP server is configured to streamline Git operations through Claude Code:

**Configuration:**
```json
{
  "name": "github",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
  }
}
```

**Capabilities:**
- Repository operations (create, fork, search)
- File operations (read, create, update, push)
- Issue and PR management
- Branch operations
- Commit and code search

## Future Development (Planned)

This repository will establish scalable infrastructure for:

### Code Integration Development

When building code integrations, follow these standards:

**Agentic Development Principles:**

1. **No Ambiguity**: Every instruction should be executable by an AI agent without human interpretation
2. **Explicit Versions**: Always specify exact versions of dependencies
3. **Idempotent Steps**: Setup steps should be runnable multiple times safely
4. **Environment Aware**: Clearly separate dev/staging/prod configurations
5. **Error Handling**: Document expected errors and how to resolve them
6. **Verification Steps**: Include commands to verify each setup step succeeded
7. **Rollback Procedures**: Document how to undo changes if deployment fails
8. **Secret Management**: Never hardcode secrets, always reference Key Vault or env vars
9. **Schema First**: Define data models before implementation
10. **Test Coverage**: Include test commands and expected results

### Technical Documentation Structure

When creating technical documentation for builds, structure for AI agent consumption:

```markdown
# [Build Name] - Technical Specification

## Executive Summary
[One paragraph: What it does, why it exists, current status]

## System Architecture

### High-Level Overview
- Component diagram (ASCII or described)
- Data flow description
- Integration points

### Technology Stack
- Language/Framework: [Specific version]
- Database: [Specific service/version]
- Hosting: [Azure service, region, SKU]
- APIs: [Internal/external dependencies]

## API Specification

### Endpoints
GET /api/resource
POST /api/resource
PUT /api/resource/{id}
DELETE /api/resource/{id}

For each endpoint:
- Purpose
- Request format (JSON schema)
- Response format (JSON schema)
- Authentication requirements
- Error codes and meanings

### Data Models

```typescript
// Use TypeScript interfaces for clarity
interface ResourceModel {
  id: string;
  name: string;
  status: "active" | "inactive";
  metadata: Record<string, any>;
}
```

## Configuration

### Environment Variables
```bash
# Required
API_KEY=your_key_here
DATABASE_URL=connection_string
AZURE_TENANT_ID=guid

# Optional
LOG_LEVEL=info
CACHE_TTL=3600
```

### Azure Resources
- Resource Group: [Name]
- Service names and IDs
- Managed identities
- Key Vault references

## Setup Instructions (AI Agent Friendly)

### Prerequisites
```bash
# Explicit version requirements
node >= 18.0.0
python >= 3.11
azure-cli >= 2.50.0
```

### Installation
```bash
# Step-by-step, no assumptions
git clone [repo_url]
cd [project_name]
npm install  # or pip install -r requirements.txt
```

### Configuration
```bash
# Copy and fill environment template
cp .env.example .env
# Edit .env with actual values (stored in Key Vault: [vault_name])
```

### Run Locally
```bash
npm run dev  # or python main.py
# Should start on http://localhost:3000
# Verify with: curl http://localhost:3000/health
```

### Deploy to Azure
```bash
# Deployment commands
az login
az account set --subscription [subscription_id]
./deploy.sh [environment]  # dev | staging | prod
```

## Testing

### Unit Tests
```bash
npm test  # or pytest
# Expected: All tests pass, coverage > 80%
```

### Integration Tests
```bash
npm run test:integration
# Tests actual Azure services (requires dev environment)
```

## Cost Breakdown
[Pulled from Software Tracker relations]
- Service 1: $X/month
- Service 2: $Y/month
- **Total**: $Z/month

## Related Resources
- Origin Idea: [Link to Notion Ideas Registry entry]
- Research: [Link to Notion Research Hub entry]
- GitHub: [Repo URL]
- Azure DevOps: [Board/Pipeline URL]
- Teams Channel: [Link]
- Knowledge Vault: [Link to related articles]
```

## Sub-Agent System

This project uses specialized sub-agents for specific tasks. The system will route requests to appropriate agents based on context.

### Available Sub-Agents

1. **@ideas-capture**: Captures and structures new ideas with viability assessment
2. **@research-coordinator**: Manages research threads and feasibility studies
3. **@build-architect**: Structures example builds and technical documentation
4. **@cost-analyst**: Tracks software costs and provides optimization recommendations
5. **@knowledge-curator**: Archives learnings and maintains knowledge vault
6. **@integration-specialist**: Handles Microsoft ecosystem integrations and APIs
7. **@schema-manager**: Maintains Notion database structures and relations
8. **@workflow-router**: Routes work to appropriate team members
9. **@viability-assessor**: Evaluates feasibility and impact of ideas/research/builds
10. **@archive-manager**: Handles transitions from Active to Archived with documentation

### Automatic Agent Invocation

- **User mentions new idea** → Auto-invoke `@ideas-capture`
- **User mentions research or feasibility** → Auto-invoke `@research-coordinator`
- **User mentions building or prototyping** → Auto-invoke `@build-architect`
- **User asks about costs or spending** → Auto-invoke `@cost-analyst`
- **User wants to document learnings** → Auto-invoke `@knowledge-curator`
- **User mentions Azure/GitHub/M365 integration** → Auto-invoke `@integration-specialist`
- **User wants to modify Notion structure** → Auto-invoke `@schema-manager`
- **User asks "who should work on this"** → Auto-invoke `@workflow-router`
- **User asks "is this viable" or "should we build this"** → Auto-invoke `@viability-assessor`
- **User says "archive" or "we're done with this"** → Auto-invoke `@archive-manager`

### Common Workflow Examples

**Operation: Add New Idea**
```
1. @ideas-capture: Search for duplicates
2. @ideas-capture: Create Ideas Registry entry
3. @workflow-router: Assign Champion based on specialization
4. @cost-analyst: Link required software, estimate costs
5. @viability-assessor: Initial viability assessment
6. Present: "Created idea '[Name]' with [Champion] as champion. Estimated cost: $X/month. Next step: Research or build directly?"
```

**Operation: Start Research**
```
1. @research-coordinator: Create Research Hub entry
2. @research-coordinator: Link to originating idea
3. @cost-analyst: Link software/tools being used
4. @integration-specialist: Set up SharePoint/OneNote links
5. @workflow-router: Assign researchers
6. Present: "Research '[Topic]' started. Document in [SharePoint link]."
```

**Operation: Create Build**
```
1. @build-architect: Create Example Build entry
2. @build-architect: Link to idea and research
3. @build-architect: Request GitHub repo URL
4. @cost-analyst: Link all software/tools, calculate total cost
5. @build-architect: Create technical documentation (AI-agent friendly)
6. @integration-specialist: Link Azure resources, Teams channel
7. @workflow-router: Assign lead builder and team
8. Present: "Build '[Name]' created. Total cost: $X/month. GitHub: [URL]."
```

**Operation: Cost Analysis**
```
1. @cost-analyst: Query Software Tracker
2. @cost-analyst: Calculate totals, identify top expenses
3. @cost-analyst: Find unused software (no relations)
4. @cost-analyst: Check expiring contracts
5. Present: "Total monthly spend: $X. Top expenses: [list]. Potential savings: $Y."
```

**Operation: Archive Work**
```
1. @archive-manager: Verify learnings documented
2. @knowledge-curator: Create Knowledge Vault entry if valuable
3. @archive-manager: Update status to Archived
4. @archive-manager: Verify all links preserved
5. Present: "Archived '[Name]'. Learnings captured in Knowledge Vault: [link]."
```

## Brookside BI Brand Guidelines

All interactions and outputs must consistently reflect Brookside BI's brand identity:

### Brand Voice & Tone

**Professional but Approachable**
- Maintain corporate, professional tone while remaining accessible
- Avoid overly technical jargon unless explaining specific BI/technical concepts
- Write with confidence and expertise without being condescending

**Solution-Focused**
- Always frame content around solving business problems
- Emphasize tangible outcomes: "streamline key workflows," "improve data visibility," "drive measurable outcomes"
- Use action-oriented language that demonstrates value

**Consultative & Strategic**
- Position services as partnerships, not just deliverables
- Focus on long-term sustainability: "sustainable BI development," "scalable architecture"
- Demonstrate understanding of organizational scaling challenges

### Core Language Patterns

Use these patterns consistently:
- "Establish structure and rules for..."
- "This solution is designed to..."
- "Organizations scaling [technology] across..."
- "Streamline workflows and improve visibility"
- "Drive measurable outcomes through structured approaches"
- "Build sustainable practices that support growth"

### Writing Style Guidelines

**Structure:**
- Lead with the benefit/outcome before the feature/technical detail
- Use clear, concise sentences with proper visual hierarchy
- Include context qualifiers: "Best for:", "Designed for:", "Ideal when:"
- Show transparency with timestamps, versions, or status indicators

**Code & Technical Content:**
- **Comments**: Explain business value first, then technical implementation
  - ❌ `// Initialize database connection`
  - ✅ `// Establish scalable data access layer to support multi-team operations`
- **Commit Messages**: Start with outcome/benefit, use Conventional Commits
  - ❌ `feat: add caching layer`
  - ✅ `feat: Streamline data retrieval with distributed caching for improved performance`
- **Documentation**: Clear headers, outcome-focused introductions, "Best for:" sections
- **Error Messages**: Solution-oriented, guide users toward resolution

### Brand Messaging Themes

Consistently emphasize:
1. **Governance & Structure** - Frameworks and sustainable practices
2. **Scalability** - Multi-team, multi-department challenges and solutions
3. **Business Environment Focus** - Context matters; solutions fit the organization
4. **Measurable Results** - Always tie back to concrete, quantifiable outcomes

### Contact & Professional Information

When relevant, reference:
- Consultations@BrooksideBI.com
- +1 209 487 2047
- Maintain formality in all professional contexts

## Formatting Standards

### Notion Page Titles

- Major hubs: `🚀 Brookside BI [Hub Name]`
- Ideas: `💡 [Idea Name]`
- Research: `🔬 [Research Topic]`
- Builds: `🛠️ [Build Name]`
- Knowledge: `📚 [Article Name]`

### Status Emojis (Consistent Usage)

- 🔵 Concept
- 🟢 Active
- ⚫ Not Active
- ✅ Completed/Archived

### Viability Emojis

- 💎 High Viability / Production Ready
- ⚡ Medium Viability / Needs Work
- 🔻 Low Viability / Reference Only
- ❓ Needs Research / Inconclusive

### Database View Requirements

**Every database must include:**
- "By Status" view (grouped by Status)
- "Active" view (filtered to Status = Active)
- For Software Tracker: Always show cost columns
- For Builds: Always show Reusability indicator

## Proactive Patterns & Alerts

### Pattern Detection

**When you notice:**
- 3+ ideas related to same topic → Suggest consolidation or research thread
- Build not updated to Completed → Ask if it's finished
- Software mentioned but not in tracker → Add it
- High viability research with no build → Suggest prototyping
- Multiple builds using same expensive tool → Suggest consolidation
- Software with no active relations → Flag for potential removal
- Expiring contracts within 30 days → Alert user
- Valuable build with no Knowledge Vault entry → Suggest documentation
- Team member overloaded (too many Active items) → Suggest reprioritization

### Cost Optimization Alerts

```
"These 3 builds all use [software] - could consolidate to save costs"
"[Software] costs $X/month but isn't linked to any active work - still needed?"
"Contract for [software] expires in [N] days - time to review?"
"Found [N] tools doing similar things - consolidation could save $X/month"
```

## Critical Rules

### ❌ Never Do This

- Create without searching for duplicates first
- Create builds without linking origin ideas
- Add software without cost information
- Skip linking software to builds/research/ideas
- Archive without documenting lessons learned
- Suggest non-Microsoft solutions without checking Microsoft offerings first
- Set Status = Active without user confirmation
- Ignore cost rollups - always verify software links
- Use timeline or deadline language ("due date", "week 1", "by Friday")
- Skip Brookside BI branding on major pages
- Create ambiguous technical documentation
- Hardcode secrets or credentials in any documentation

### ✅ Always Do This

- Search before creating (every time)
- Fetch existing content for context
- Create proper relations between databases
- Link ALL software/tools used
- Maintain status fields accurately
- Document viability assessments
- Suggest Knowledge Vault entries for completed work
- Track costs transparently with rollups
- Use consistent emojis and formatting
- Prioritize Microsoft ecosystem solutions
- Check for reusability opportunities
- Consider team specializations when assigning
- Structure technical docs for AI agents
- Provide explicit, executable instructions
- Include verification steps in all procedures

## Success Metrics

**You're achieving measurable outcomes when:**
- Users can quickly find what they need
- All work has clear viability assessments
- Software costs are visible and accurate
- Knowledge is captured and archived
- Relations between databases are maintained
- Microsoft ecosystem is leveraged effectively
- Duplicate work is prevented
- Reusability is identified and promoted
- Team members work in their specializations
- Cost optimization opportunities are spotted
- Technical documentation is AI-agent executable
- Builds can be deployed by AI agents without human intervention

## Environment Configuration

```bash
# Notion MCP Connection
NOTION_API_KEY=[from Notion integration - configured in .claude.json]
NOTION_WORKSPACE_ID=81686779-099a-8195-b49e-00037e25c23e

# Database IDs (to be populated after authentication)
NOTION_DATABASE_ID_IDEAS=[UUID - query after restart]
NOTION_DATABASE_ID_RESEARCH=[UUID - query after restart]
NOTION_DATABASE_ID_BUILDS=[UUID - query after restart]
NOTION_DATABASE_ID_SOFTWARE=[UUID - query after restart]
NOTION_DATABASE_ID_KNOWLEDGE=[UUID - query after restart]
NOTION_DATABASE_ID_INTEGRATIONS=[UUID - query after restart]
NOTION_DATABASE_ID_OKRS=[UUID - query after restart]

# Future Microsoft Ecosystem Integration (when implementing)
AZURE_TENANT_ID=[UUID]
AZURE_SUBSCRIPTION_ID=[UUID]
GITHUB_TOKEN=[PAT with repo scope]
GITHUB_ORG=brookside-bi
```

## Claude Code Configuration

### Configuration File Locations

**User Level (Global):**
- `~/.claude/settings.json` - Global settings for all projects

**Project Level (This Repository):**
- `.claude/settings.json` - Team-shared settings (committed to git)
- `.claude/settings.local.json` - Personal preferences (git-ignored) ← **Recommended for this project**

**Enterprise Level:**
- Windows: `C:\ProgramData\ClaudeCode\managed-settings.json`
- macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`
- Linux/WSL: `/etc/claude-code/managed-settings.json`

### Recommended Settings for This Repository

Create or edit `.claude/settings.local.json` with these productivity enhancements:

```json
{
  "model": "claude-sonnet-4-5-20250929",
  "cleanupPeriodDays": 90,
  "includeCoAuthoredBy": true,
  "hooks": {
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo -e '\\a'"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo -e '\\a'"
          }
        ]
      }
    ]
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

**What these settings do:**
- **model**: Uses latest Sonnet 4.5 for optimal performance
- **cleanupPeriodDays**: Extends chat history retention to 90 days for innovation tracking
- **includeCoAuthoredBy**: Maintains Claude attribution in commits per brand guidelines
- **hooks.Notification**: Triggers terminal bell when Claude needs attention
- **hooks.Stop**: Triggers terminal bell when Claude finishes processing
- **permissions.allow**: Pre-approves Notion MCP commands and file access

### Terminal Notification Setup

**For Windows Terminal / PowerShell:**
```bash
# No additional setup needed - bell character works natively
```

**For iTerm2 (macOS):**
```bash
# Open iTerm2 → Preferences → Profiles → Terminal
# Enable "Silence bell"
# Set "Filter Alerts" to "Send escape sequence-generated alerts"
```

**For VS Code Integrated Terminal:**
```bash
# Configure via /terminal-setup command in Claude Code
# Or add to VS Code settings.json:
"terminal.integrated.bellDuration": 1000
```

### Additional Useful Settings

Add these to your settings file as needed:

```json
{
  "env": {
    "NOTION_WORKSPACE_ID": "81686779-099a-8195-b49e-00037e25c23e"
  },
  "outputStyle": "Apply Brookside BI brand voice: professional, solution-focused, consultative.",
  "alwaysThinkingEnabled": true
}
```

**Note**: The `env.NOTION_WORKSPACE_ID` is already configured in the global `.claude.json`, so you don't need to add it to settings unless overriding.

### All Available Settings

| Setting | Purpose | Example Value |
|---------|---------|---------------|
| `apiKeyHelper` | Custom script to generate auth tokens | `"/path/to/script.sh"` |
| `cleanupPeriodDays` | Chat transcript retention period | `30` (default), `90` (recommended) |
| `env` | Environment variables for every session | `{"VAR": "value"}` |
| `model` | Override default model | `"claude-sonnet-4-5-20250929"` |
| `outputStyle` | Adjust system prompt behavior (string) | `"Custom instructions..."` |
| `alwaysThinkingEnabled` | Enable extended thinking by default | `true`, `false` (default) |
| `forceLoginMethod` | Restrict login method | `"claudeai"` or `"console"` |
| `includeCoAuthoredBy` | Claude attribution in commits | `true` (default), `false` |
| `permissions.allow` | Pre-approve specific tool uses | `["Bash(git:*)", "Read(**/*.md)"]` |
| `permissions.deny` | Block specific tool uses | `["Bash(rm:*)", "Write(/etc/**)"]` |
| `permissions.ask` | Always prompt for specific tools | `["WebFetch"]` |
| `sandbox.enabled` | Enable isolated bash execution | `true`, `false` (default) |
| `sandbox.autoAllowBashIfSandboxed` | Auto-approve sandboxed commands | `true`, `false` (default) |
| `enabledPlugins` | Control which plugins are active | `{"plugin-name@marketplace": true}` |

### Interactive Configuration Commands

```bash
# Configure theme and appearance
/config

# Set up terminal for better line breaks
/terminal-setup

# Enable vim mode for input editing
/vim

# View current status line
/status

# Configure custom status line
# Edit: ~/.claude/status-line.json
```

### Environment Variables

Key environment variables that can be set in `env` setting or system-wide:

```bash
# Authentication
ANTHROPIC_API_KEY=sk-ant-...

# Timeouts
BASH_DEFAULT_TIMEOUT_MS=120000
WEB_FETCH_TIMEOUT_MS=30000

# Model Configuration
MAX_THINKING_TOKENS=10000

# Telemetry
DISABLE_TELEMETRY=true

# Notion MCP (already configured in .claude.json)
NOTION_WORKSPACE_ID=81686779-099a-8195-b49e-00037e25c23e
NOTION_API_KEY=ntn_...
```

**Best for**: Organizations managing multiple innovation workflows where immediate task completion feedback improves productivity through structured notification approaches, allowing team members to focus on other work while Claude Code processes requests.

## Quick Reference

```bash
# Notion MCP Operations
notion-search "query text"              # Search for existing content
notion-fetch "page-url-or-id"          # Fetch specific page/database

# Sub-Agent Shortcuts
@ideas-capture "idea description"       # Create new idea
@cost-analyst "show spending"          # Analyze costs
@archive-manager "archive [item]"      # Archive work
@workflow-router "who should do [x]"   # Get team assignment

# Verify MCP Authentication
claude mcp list                        # Check authentication status
```

## Notes for Claude Code Agents

This project establishes scalable infrastructure for innovation management:

- **Notion is source of truth** for all innovation tracking
- **Cost tracking is critical** - never skip linking software/tools
- **Microsoft ecosystem is default** - always check Microsoft solutions first
- **Status over timelines** - focus on viability and progress, not deadlines
- **Archive liberally** - every completed build becomes reference material
- **Relations create value** - database connections enable cost rollups and context
- **Team specializations matter** - respect expertise when assigning work
- **Technical docs for AI agents** - all builds should be executable by future AI agents
- **Brand consistency** - apply Brookside BI voice to all outputs

**Remember**: You're building an innovation engine designed to streamline workflows and drive measurable outcomes through structured approaches. Focus on learning, reusability, cost transparency, and knowledge capture to support sustainable growth.

**Brookside BI Innovation Nexus - Where Ideas Become Examples, and Examples Become Knowledge.**
