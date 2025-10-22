# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Brookside BI Innovation Nexus** - An innovation management system designed to establish structured approaches for tracking ideas from concept through research, building, and knowledge archival. This solution is designed for managing innovation workflow using Notion as the central hub with future Microsoft ecosystem integrations.

**Repository Purpose**: Streamline key workflows for innovation management through:
- Notion workspace management via MCP integration
- Future code integrations with Microsoft ecosystem (Azure, GitHub, SharePoint, Teams)
- Documentation generation and knowledge management
- Cost analysis and optimization for software/tools

## Integration Summary

**Recent Integration** (October 2025): This project has integrated valuable architectural patterns, specialized agents, and operational templates from enterprise-grade best practices to streamline innovation workflows and establish production-ready standards.

### Phase 3: Autonomous Build Pipeline & Repository Safety Controls

**Completed**: October 21, 2025

**Autonomous Build Pipeline** (40-60 minute end-to-end execution):
- **3 Build Orchestration Agents**: @build-architect-v2, @code-generator, @deployment-orchestrator (2,900+ lines)
- **Parallel Research Swarm**: @market-researcher, @technical-analyst, @cost-feasibility-analyst, @risk-assessor
- **Infrastructure Templates**: Bicep templates for Python, TypeScript, and C# applications
- **CI/CD Workflows**: GitHub Actions with zero-downtime deployments
- **Time Reduction**: 95% improvement (2-4 weeks → 40-60 minutes)
- **Cost Savings**: 87% reduction through environment-based SKU selection ($20 dev vs $157 prod)
- **Security**: Managed Identity, RBAC, zero hardcoded secrets

**Repository Safety Hooks** (Preventive Controls):
- **3-Layer Protection**: Pre-commit, commit-msg, branch-protection hooks
- **Secret Detection**: 15+ patterns preventing credential leaks
- **Conventional Commits**: Enforced format with Brookside BI brand voice
- **Branch Protection**: Prevent force pushes to main/master/production
- **ROI**: 500-667% through automated quality enforcement
- **Monthly Value**: $1,390-$1,540 via reduced security incidents

**Notion Documentation**:
- Phase 3 Example Build entry (16,500 words)
- Repository Hooks Knowledge Vault entry (13,200 words)
- Manual entry preparation guide (3,800 words)

**Validation**: A+ grade on all 4 Phase 3 components, 100% secret prevention rate, 0 Bicep errors/warnings

### What Was Integrated

**27+ Specialized Agents** ([.claude/agents/](.claude/agents)):
- **Core Innovation**: @ideas-capture, @research-coordinator, @build-architect, @viability-assessor, @archive-manager
- **Phase 3 Autonomous**: @build-architect-v2, @code-generator, @deployment-orchestrator
- **Research Swarm**: @market-researcher, @technical-analyst, @cost-feasibility-analyst, @risk-assessor
- **Technical Specialists**: @database-architect, @compliance-orchestrator, @architect-supreme, @integration-specialist
- **Repository Analysis**: @repo-analyzer, @github-repo-analyst
- **Utility**: @markdown-expert, @mermaid-diagram-expert, @notion-mcp-specialist, @workflow-router, @cost-analyst, @knowledge-curator

**4 Architectural Patterns** ([.claude/docs/patterns/](.claude/docs/patterns)):
- **Circuit-Breaker**: Resilience pattern for Azure/GitHub/Notion integrations (12KB)
- **Retry with Exponential Backoff**: Transient failure handling for cloud operations (18KB)
- **Saga Pattern**: Distributed transaction consistency across Notion + GitHub + Azure (15KB)
- **Event Sourcing**: Complete audit trails and temporal analysis for compliance (27KB)

**3 Operational Templates** ([.claude/templates/](.claude/templates)):
- **ADR Template**: Standardized Architecture Decision Record documentation
- **Runbook Template**: Operational procedures for Azure deployments and incident response
- **Research Hub Entry Template**: Structured research documentation with parallel agent findings

**Slash Commands** ([.claude/commands/](.claude/commands)):
- **Innovation**: `/innovation:new-idea`, `/innovation:start-research`, `/innovation:orchestrate-complex`
- **Autonomous**: `/autonomous:enable-idea`, `/autonomous:status`
- **Repository**: `/repo:scan-org`, `/repo:analyze`, `/repo:extract-patterns`, `/repo:calculate-costs`
- **Cost**: `/cost:analyze`, `/cost:unused-software`, `/cost:consolidation-opportunities`, `/cost:expiring-contracts`, 10+ others
- **Compliance**: `/compliance:audit`
- **Knowledge**: `/knowledge:archive`
- **Team**: `/team:assign`

### Integration Value

**Established Capabilities**:
- **Autonomous Innovation**: Idea-to-production in 40-60 minutes with <5% human intervention
- **Repository Intelligence**: Comprehensive GitHub portfolio analysis with viability scoring and Notion sync
- **Production-Ready Resilience**: Circuit-breaker and retry patterns ensure reliable cloud integrations
- **Transaction Consistency**: Saga pattern maintains data integrity across distributed systems
- **Compliance Foundation**: Software licensing audit framework aligned with Innovation Nexus databases
- **Architectural Governance**: ADR templates and architect-supreme agent for structured decision-making
- **Operational Excellence**: Runbook templates for sustainable Azure deployment practices
- **Security Enforcement**: Repository hooks prevent credential leaks and enforce quality standards

**Microsoft Ecosystem Alignment**:
- Azure-specific patterns (App Service, Functions, SQL, Cosmos DB, Key Vault)
- GitHub integration workflows with saga-based rollback
- Notion MCP resilience with circuit-breaker protection
- Power Platform event sourcing for audit compliance
- Microsoft-first cost optimization recommendations

**Best for**: Organizations scaling innovation workflows across teams who require enterprise-grade reliability, autonomous execution capabilities, compliance visibility, and architectural governance while maintaining sustainable development practices.

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

This project uses 27+ specialized sub-agents for specific tasks. The system will route requests to appropriate agents based on context.

### Available Sub-Agents

**Core Innovation Agents (10):**
1. **@ideas-capture**: Captures and structures new ideas with viability assessment
2. **@research-coordinator**: Orchestrates parallel research swarms and feasibility studies
3. **@build-architect**: Structures example builds and technical documentation
4. **@build-architect-v2**: Autonomous code generation and end-to-end deployment orchestration (Phase 3)
5. **@code-generator**: Language-specific production code generation (Python/TypeScript/C#) (Phase 3)
6. **@deployment-orchestrator**: Azure infrastructure provisioning and deployment automation (Phase 3)
7. **@viability-assessor**: Evaluates feasibility and impact of ideas/research/builds
8. **@cost-analyst**: Tracks software costs and provides optimization recommendations
9. **@knowledge-curator**: Archives learnings and maintains knowledge vault
10. **@archive-manager**: Handles transitions from Active to Archived with documentation

**Research Swarm Agents (4 - Phase 3):**
11. **@market-researcher**: Market opportunity and competitive landscape analysis
12. **@technical-analyst**: Technology stack assessment and Microsoft ecosystem fit
13. **@cost-feasibility-analyst**: Financial projections, ROI, and cost optimization
14. **@risk-assessor**: Risk identification, mitigation strategies, and impact assessment

**Technical Specialists (6):**
15. **@database-architect**: Azure SQL, Cosmos DB schema design and query optimization
16. **@compliance-orchestrator**: Software licensing, GDPR/CCPA, and governance compliance
17. **@architect-supreme**: Enterprise architecture design and ADR documentation
18. **@integration-specialist**: Microsoft ecosystem integrations (Azure/M365/GitHub/Power Platform)
19. **@github-repo-analyst**: Repository health assessment and code quality analysis
20. **@repo-analyzer**: Comprehensive GitHub portfolio analysis with Notion synchronization

**Workflow & Orchestration (3):**
21. **@workflow-router**: Team assignment and workload balancing based on specializations
22. **@schema-manager**: Notion database structure maintenance and relation management
23. **@notion-orchestrator**: Complex multi-database operations and workflow coordination

**Utility & Documentation (4):**
24. **@markdown-expert**: Technical documentation formatting and markdown best practices
25. **@mermaid-diagram-expert**: Architecture diagram generation and visualization
26. **@notion-mcp-specialist**: Notion API troubleshooting and MCP integration debugging
27. **@github-notion-sync**: Bidirectional synchronization between GitHub and Notion
28. **@documentation-sync**: Documentation consistency across repositories and Notion

### Automatic Agent Invocation

**Core Innovation Workflows:**
- **User mentions new idea** → Auto-invoke `@ideas-capture`
- **User mentions research or feasibility** → Auto-invoke `@research-coordinator` (orchestrates 4-agent swarm)
- **User mentions building or prototyping** → Auto-invoke `@build-architect` or `@build-architect-v2` (autonomous)
- **High viability score (>85)** → Auto-invoke `@build-architect-v2` (autonomous pipeline)
- **User asks "is this viable"** → Auto-invoke `@viability-assessor`
- **User says "archive" or "done"** → Auto-invoke `@archive-manager`

**Cost & Optimization:**
- **User asks about costs or spending** → Auto-invoke `@cost-analyst`
- **Budget threshold exceeded** → Auto-invoke `@cost-feasibility-analyst`
- **Microsoft alternative needed** → Auto-invoke `@cost-analyst` + `@integration-specialist`

**Documentation & Knowledge:**
- **User wants to document learnings** → Auto-invoke `@knowledge-curator`
- **Technical docs need formatting** → Auto-invoke `@markdown-expert`
- **Architecture diagrams needed** → Auto-invoke `@mermaid-diagram-expert`

**Technical Operations:**
- **Azure/GitHub/M365 integration** → Auto-invoke `@integration-specialist`
- **Notion structure modification** → Auto-invoke `@schema-manager`
- **Repository analysis** → Auto-invoke `@repo-analyzer`
- **Compliance audit** → Auto-invoke `@compliance-orchestrator`

**Team Coordination:**
- **Work assignment needed** → Auto-invoke `@workflow-router`
- **Team capacity check** → Auto-invoke `@workflow-router`

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

- **NEVER mention project timelines, duration estimates, time to complete, or how long anything will take** - user does not want ANY time-related estimates in outputs
- Create without searching for duplicates first
- Create builds without linking origin ideas
- Add software without cost information
- Skip linking software to builds/research/ideas
- Archive without documenting lessons learned
- Suggest non-Microsoft solutions without checking Microsoft offerings first
- Set Status = Active without user confirmation
- Ignore cost rollups - always verify software links
- Use timeline or deadline language ("due date", "week 1", "by Friday", "1-2 weeks", "2-8 weeks", "10-15 minutes", etc.)
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

## Notion Workspace Configuration

### Workspace Details

**Workspace ID**: `81686779-099a-8195-b49e-00037e25c23e`
**Workspace Name**: Brookside BI
**TeamSpace**: BrookSide Bi

### Notion Database IDs

**💡 Ideas Registry:**
- Database URL: `https://www.notion.so/c17ec2eb9555449eaa34edba4f0c7b60`
- Data Source ID: `984a4038-3e45-4a98-8df4-fd64dd8a1032`
- Collection URL: `collection://984a4038-3e45-4a98-8df4-fd64dd8a1032`

**🔬 Research Hub:**
- Data Source ID: `91e8beff-af94-4614-90b9-3a6d3d788d4a`
- Collection URL: `collection://91e8beff-af94-4614-90b9-3a6d3d788d4a`

**🛠️ Example Builds:**
- Data Source ID: `a1cd1528-971d-4873-a176-5e93b93555f6`
- Collection URL: `collection://a1cd1528-971d-4873-a176-5e93b93555f6`

**💰 Software & Cost Tracker:**
- Data Source ID: `13b5e9de-2dd1-45ec-839a-4f3d50cd8d06`
- Collection URL: `collection://13b5e9de-2dd1-45ec-839a-4f3d50cd8d06`

**Additional Databases** (query programmatically as needed):
- 📚 Knowledge Vault
- 🔗 Integration Registry
- 🎯 OKRs & Strategic Initiatives

**Best for**: Direct database queries, API integrations, and programmatic access to Notion workspace.

### Notion MCP Authentication

**Method**: HTTP-based MCP via Notion's official server
- **Endpoint**: `https://mcp.notion.com/mcp`
- **Authentication**: Handled automatically via Notion's OAuth flow
- **Status**: ✓ Connected (verify with `claude mcp list`)

**To authenticate Notion MCP:**
1. Restart Claude Code to trigger OAuth flow
2. Follow browser authentication prompt
3. Grant workspace access to Claude Code
4. Verify connection: `claude mcp list` should show "notion: ✓ Connected"

## MCP Servers

This project uses 4 Model Context Protocol (MCP) servers to streamline operations across multiple platforms:

### 1. Notion MCP Server

**Purpose**: Seamless integration with Notion workspace for innovation management

**Configuration:**
```json
{
  "name": "notion",
  "url": "https://mcp.notion.com/mcp",
  "transport": "http"
}
```

**Capabilities:**
- Search workspace content (semantic search with AI)
- Fetch pages and databases
- Create/update pages and database entries
- Manage database properties and relations
- Query databases with filters
- User and team management

**Use Cases:**
- Create Ideas Registry entries
- Document Research findings
- Track Example Builds
- Manage Software & Cost Tracker
- Archive to Knowledge Vault

### 2. GitHub MCP Server

**Purpose**: Version control and repository management

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

**Authentication**: Personal Access Token from Azure Key Vault

**Capabilities:**
- Repository operations (create, fork, search, clone)
- File operations (read, create, update, push multiple files)
- Pull request management (create, review, merge, status checks)
- Issue tracking (create, update, comment, search)
- Branch management (create, list commits)
- Code search across repositories

**Use Cases:**
- Create repositories for Example Builds
- Manage code for prototypes and POCs
- Link GitHub repos to Notion Build entries
- Track issues related to ideas and research
- Collaborative code reviews

### 3. Azure MCP Server

**Purpose**: Azure cloud services management and operations

**Configuration:**
```json
{
  "name": "azure",
  "command": "npx",
  "args": ["-y", "@azure/mcp@latest", "server", "start"]
}
```

**Authentication**: Azure CLI (`az login`)

**Capabilities:**
- Resource management (list, create, configure resources)
- Azure OpenAI operations
- Key Vault secret management
- App Service deployment and management
- Cosmos DB operations
- SQL Database management
- Storage operations (Blob, File, Queue, Table)
- Cost analysis and quota management
- Resource health monitoring

**Use Cases:**
- Deploy Example Builds to Azure
- Manage Key Vault secrets
- Query Azure OpenAI services
- Monitor resource costs
- Health checks for deployed services

### 4. Playwright MCP Server

**Purpose**: Browser automation and web testing

**Configuration:**
```json
{
  "name": "playwright",
  "command": "npx",
  "args": ["@playwright/mcp@latest", "--browser", "msedge", "--headless"]
}
```

**Capabilities:**
- Browser navigation and interaction
- Screenshot capture
- Form filling and submission
- Element clicking and hovering
- Web scraping and data extraction
- Automated testing workflows

**Use Cases:**
- Test web-based Example Builds
- Capture screenshots for documentation
- Automate data collection for research
- Validate integration endpoints
- UI testing for prototypes

## Environment Configuration

**Complete Environment Setup:**

```bash
# Azure Configuration
AZURE_TENANT_ID=2930489e-9d8a-456b-9de9-e4787faeab9c
AZURE_SUBSCRIPTION_ID=cfacbbe8-a2a3-445f-a188-68b3b35f0c84
AZURE_KEYVAULT_NAME=kv-brookside-secrets
AZURE_KEYVAULT_URI=https://kv-brookside-secrets.vault.azure.net/

# GitHub Configuration
GITHUB_ORG=brookside-bi
GITHUB_PERSONAL_ACCESS_TOKEN=[Retrieved from Key Vault]

# Notion Configuration
NOTION_WORKSPACE_ID=81686779-099a-8195-b49e-00037e25c23e
NOTION_DATABASE_ID_IDEAS=984a4038-3e45-4a98-8df4-fd64dd8a1032
NOTION_DATABASE_ID_RESEARCH=91e8beff-af94-4614-90b9-3a6d3d788d4a
NOTION_DATABASE_ID_BUILDS=a1cd1528-971d-4873-a176-5e93b93555f6
NOTION_DATABASE_ID_SOFTWARE=13b5e9de-2dd1-45ec-839a-4f3d50cd8d06

# MCP Server Status (verify with: claude mcp list)
# notion: ✓ Connected
# github: ✓ Connected
# azure: ✓ Connected
# playwright: ✓ Connected
```

**Important**: Use `scripts/Set-MCPEnvironment.ps1` to automatically configure environment variables from Azure Key Vault.

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

## Quick-Start Setup Guide

This guide establishes a fully configured development environment.

### Prerequisites

**Required Software:**
- ✓ Azure CLI 2.50.0 or higher
- ✓ Node.js 18.0.0 or higher
- ✓ Git
- ✓ PowerShell 7.0 or higher
- ✓ Claude Code (latest version)

**Verify Prerequisites:**
```powershell
# Check versions
az --version
node --version
git --version
pwsh --version
```

### Step 1: Azure Authentication

Establish secure connection to Azure services and Key Vault:

```powershell
# Login to Azure (opens browser)
az login

# Verify successful authentication
az account show

# Confirm Key Vault access
az keyvault secret list --vault-name kv-brookside-secrets
```

**Expected Result**: You should see your Azure account details and have access to Key Vault secrets.

### Step 2: Configure MCP Environment

Retrieve secrets from Azure Key Vault and set environment variables:

```powershell
# Navigate to repository
cd C:\Users\MarkusAhling\Notion

# Configure environment for current session
.\scripts\Set-MCPEnvironment.ps1

# OR configure persistent environment variables (optional)
.\scripts\Set-MCPEnvironment.ps1 -Persistent
```

**Expected Result**: Environment variables set successfully with confirmation message.

### Step 3: Verify MCP Server Connectivity

Test all MCP server connections:

```powershell
# Test Azure MCP server
.\scripts\Test-AzureMCP.ps1

# Verify all MCP servers
claude mcp list
```

**Expected Result**: All 4 MCP servers show "✓ Connected":
- ✓ notion
- ✓ github
- ✓ azure
- ✓ playwright

### Step 4: Configure Git

Set up Git authentication with GitHub PAT from Key Vault:

```powershell
# Retrieve GitHub PAT
$githubPAT = .\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token"

# Configure Git (replace with your details)
git config --global user.name "Your Name"
git config --global user.email "your.email@brooksidebi.com"
git config --global credential.helper store

# Test Git connection
git remote -v
git status
```

**Expected Result**: Git configured with your identity and connected to remote repository.

### Step 5: Launch Claude Code

Start Claude Code with fully configured environment:

```powershell
# Launch Claude Code (ensure environment variables are set)
claude
```

**Verification Checklist:**
- [ ] Azure CLI authenticated
- [ ] Key Vault secrets accessible
- [ ] Environment variables configured
- [ ] All 4 MCP servers connected
- [ ] Git configured with GitHub authentication
- [ ] Claude Code launched successfully

### Troubleshooting Common Issues

**Issue: Azure CLI not authenticated**
```powershell
# Solution: Login again
az login
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
```

**Issue: Key Vault access denied**
```powershell
# Solution: Verify permissions
az keyvault show --name kv-brookside-secrets
# Contact Azure administrator if permissions needed
```

**Issue: MCP server not connecting**
```powershell
# Solution: Test individual server
.\scripts\Test-AzureMCP.ps1

# Check environment variables
$env:GITHUB_PERSONAL_ACCESS_TOKEN
$env:NOTION_WORKSPACE_ID

# Re-run environment setup
.\scripts\Set-MCPEnvironment.ps1
```

**Issue: GitHub authentication failing**
```powershell
# Solution: Re-retrieve PAT and configure Git
$env:GITHUB_PERSONAL_ACCESS_TOKEN = .\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token"
git config --global credential.helper store
```

### Daily Workflow

**Every time you start a new session:**

```powershell
# 1. Ensure Azure authentication is active
az account show

# 2. Set environment variables (if not persistent)
.\scripts\Set-MCPEnvironment.ps1

# 3. Launch Claude Code
claude
```

**Best for**: Teams requiring consistent, secure environment setup with minimal manual configuration.

## Quick Reference

```bash
# Azure Operations
az login                                           # Authenticate to Azure
az keyvault secret show --vault-name kv-brookside-secrets --name <secret-name>  # Get secret
.\scripts\Set-MCPEnvironment.ps1                   # Configure all environment variables

# Notion MCP Operations
notion-search "query text"                         # Search for existing content
notion-fetch "page-url-or-id"                     # Fetch specific page/database
claude mcp list                                    # Verify MCP authentication status

# GitHub Operations
git status                                         # Check repository status
git remote -v                                      # View remote repositories

# Sub-Agent Shortcuts
@ideas-capture "idea description"                  # Create new idea
@cost-analyst "show spending"                     # Analyze costs
@archive-manager "archive [item]"                 # Archive work
@workflow-router "who should do [x]"              # Get team assignment

# MCP Server Verification
claude mcp list                                    # Check all MCP connections
.\scripts\Test-AzureMCP.ps1                       # Test Azure MCP specifically
```

## Sub-Agents Quick Reference

This project establishes 14 specialized sub-agents to streamline innovation workflows and drive measurable outcomes through intelligent task delegation.

### Complete Agent Directory

| Agent | Primary Purpose | When to Use | Key Capabilities |
|-------|----------------|-------------|------------------|
| **@ideas-capture** | Capture innovation opportunities with viability assessment | User mentions "idea", "concept", "we should build" | • Duplicate prevention<br>• Champion assignment<br>• Cost estimation |
| **@research-coordinator** | Structure feasibility investigations | User mentions "research", "investigate", "feasibility" | • Hypothesis formation<br>• Methodology design<br>• SharePoint/OneNote setup |
| **@build-architect** | Design technical architecture & documentation | User mentions "build", "prototype", "POC", "demo" | • AI-agent-friendly docs<br>• GitHub integration<br>• Tech stack specification |
| **@cost-analyst** | Analyze software spend & optimize costs | User asks "costs", "spending", "budget", "optimize" | • Total spend calculation<br>• Unused tool detection<br>• Microsoft alternatives |
| **@knowledge-curator** | Archive learnings & maintain knowledge vault | Build completes or user says "document learnings" | • Post-mortem creation<br>• Reusability assessment<br>• Knowledge Vault entries |
| **@integration-specialist** | Configure Microsoft ecosystem connections | User mentions Azure, GitHub, M365, Power Platform | • Service Principal setup<br>• Authentication config<br>• Security reviews |
| **@schema-manager** | Maintain Notion database structures | User wants to "modify database", "add property", "change schema" | • Property management<br>• Relation configuration<br>• Formula creation |
| **@workflow-router** | Assign work based on specialization & workload | User asks "who should", "assign to", "who can handle" | • Specialization matching<br>• Workload balancing<br>• Team distribution |
| **@viability-assessor** | Evaluate feasibility & impact | User asks "should we build", "is this viable", "worth it" | • Effort vs. impact analysis<br>• Risk assessment<br>• Go/No-Go recommendations |
| **@archive-manager** | Complete lifecycle & preserve learnings | User says "archive", "done with", "complete" | • Status updates<br>• Link preservation<br>• Dependent item updates |
| **@github-repo-analyst** | Analyze repository structure & health | User provides GitHub URL or asks about repo | • Code quality assessment<br>• Activity analysis<br>• Dependency evaluation |
| **@notion-mcp-specialist** | Expert Notion operations & troubleshooting | Issues with Notion MCP or complex database operations | • MCP configuration<br>• Relation debugging<br>• Query optimization |
| **@markdown-expert** | Format technical documentation | User needs README, docs, or technical writing | • Structure validation<br>• Markdown best practices<br>• AI-agent readability |
| **@mermaid-diagram-expert** | Create visual diagrams & architecture charts | User needs "diagram", "flowchart", "architecture visual" | • Workflow diagrams<br>• ER diagrams<br>• Sequence diagrams |
| **@database-architect** | Notion optimization and Azure data architecture specialist | User needs database schema design, query optimization, Notion schema enhancement, or data architecture decisions | • Cosmos DB schema design<br>• Azure SQL optimization<br>• Notion database relations<br>• Query performance tuning |
| **@compliance-orchestrator** | Software licensing and governance compliance specialist | User requests compliance audit, software licensing requirements, security reviews, or regulatory assessment | • Software license compliance<br>• GDPR/CCPA assessment<br>• Integration security review<br>• Policy documentation |
| **@architect-supreme** | Microsoft ecosystem architecture and ADR documentation specialist | User needs enterprise architecture design, Microsoft solution evaluation, scalability planning, or ADR creation | • Azure architecture design<br>• ADR documentation<br>• Microsoft service selection<br>• Scalability assessment |

### Agent Invocation Patterns

**Proactive Usage (Always Delegate):**
- New idea mentioned → Immediately invoke `@ideas-capture`
- Research discussed → Automatically engage `@research-coordinator`
- Build creation → Delegate to `@build-architect`
- Cost questions → Route to `@cost-analyst`
- Archive requests → Invoke `@archive-manager`

**On-Demand Usage (User-Triggered):**
- Schema changes → `@schema-manager`
- GitHub analysis → `@github-repo-analyst`
- Diagram creation → `@mermaid-diagram-expert`
- Markdown review → `@markdown-expert`
- Notion troubleshooting → `@notion-mcp-specialist`

**Multi-Agent Workflows:**
- **New Idea**: `@ideas-capture` → `@workflow-router` → `@cost-analyst` → `@viability-assessor`
- **Build Creation**: `@build-architect` → `@integration-specialist` → `@cost-analyst` → `@workflow-router`
- **Archival**: `@archive-manager` → `@knowledge-curator` → `@markdown-expert`
- **Cost Review**: `@cost-analyst` → `@viability-assessor` → `@workflow-router`

**Best for**: Organizations requiring intelligent task routing that maximizes specialized expertise while minimizing manual coordination overhead.

## Architectural Patterns Reference

This project implements production-grade architectural patterns designed for distributed systems, cloud integrations, and compliance requirements. All patterns are documented in [.claude/docs/patterns/](.claude/docs/patterns) with comprehensive examples aligned to Innovation Nexus workflows.

### Available Patterns

#### 1. Circuit-Breaker Pattern
**File**: [circuit-breaker.md](.claude/docs/patterns/circuit-breaker.md) (12KB)
**Purpose**: Prevent cascading failures in Azure, GitHub, and Notion MCP integrations by detecting failures and failing fast
**Use Cases**:
- Azure resource provisioning (quota limits, service outages)
- GitHub API rate limiting
- Notion MCP connection failures
- Transient cloud service interruptions

**Key States**: CLOSED (normal) → OPEN (failing fast) → HALF-OPEN (testing recovery)

#### 2. Retry with Exponential Backoff
**File**: [retry-exponential-backoff.md](.claude/docs/patterns/retry-exponential-backoff.md) (18KB)
**Purpose**: Handle transient failures with intelligent retry scheduling to avoid overwhelming failing services
**Use Cases**:
- Network timeouts
- API rate limiting (429 errors)
- Database connection issues
- Transient Azure service errors

**Algorithm**: Wait time doubles with each retry (1s → 2s → 4s → 8s → 16s) with configurable jitter and max attempts

#### 3. Saga Pattern for Distributed Transactions
**File**: [saga-distributed-transactions.md](.claude/docs/patterns/saga-distributed-transactions.md) (15KB)
**Purpose**: Maintain consistency across Notion + GitHub + Azure workflows with automatic compensation on failure
**Use Cases**:
- Example Build creation (Notion entry + GitHub repo + Azure resources)
- Research investigation setup (Notion + SharePoint + OneNote)
- Software cost tracking (Notion + Integration Registry + Azure billing)

**Workflow**: Execute steps sequentially, compensate in reverse order on failure

**Example**:
```
✓ Step 1: Create Notion Build Entry → buildId=123
✓ Step 2: Create GitHub Repository → repoUrl=github.com/org/repo
✗ Step 3: Provision Azure Resources → FAILED (quota exceeded)
↺ Compensate Step 2 → Delete GitHub repository
↺ Compensate Step 1 → Update buildId=123 status='Cancelled'
Result: Clean state, no orphaned resources
```

#### 4. Event Sourcing
**File**: [event-sourcing.md](.claude/docs/patterns/event-sourcing.md) (27KB)
**Purpose**: Complete audit trails and temporal analysis for compliance, cost tracking, and historical reporting
**Use Cases**:
- Software & Cost Tracker audit trail (license changes, cost updates, approval workflows)
- Compliance event logging (GDPR/CCPA data access, security reviews)
- Idea/Research/Build lifecycle tracking (status transitions, viability assessments)
- "Time travel" queries: "What was our total monthly spend on July 1st?"

**Core Concept**: Store every state change as an immutable event, reconstruct current/historical state by replaying events

### Pattern Integration in Innovation Nexus

**Build Architect + Integration Specialist**:
- Use **Saga Pattern** when creating builds (Notion + GitHub + Azure)
- Use **Circuit-Breaker** for Azure resource provisioning
- Use **Retry** for transient GitHub/Azure API failures

**Cost Analyst**:
- Use **Event Sourcing** for complete cost history and audit compliance
- Track every cost change as immutable event for regulatory reporting

**Compliance Orchestrator**:
- Use **Event Sourcing** for GDPR/CCPA data access audit trails
- Use **Saga Pattern** for multi-system compliance verification workflows

**Research Coordinator + Knowledge Curator**:
- Use **Saga Pattern** for coordinated SharePoint/OneNote/Notion setup
- Use **Event Sourcing** for research decision history and lessons learned

**Best for**: Organizations requiring enterprise-grade reliability, regulatory compliance, and distributed system consistency across Microsoft ecosystem integrations.

## Documentation Templates

This project provides reusable templates for standardizing technical and operational documentation. All templates are available in [.claude/templates/](.claude/templates) and follow Brookside BI brand guidelines with AI-agent-friendly structure.

### Available Templates

#### 1. Architecture Decision Record (ADR) Template
**File**: [adr-template.md](.claude/templates/adr-template.md)
**Purpose**: Document significant architectural decisions with context, alternatives, and rationale
**Agent**: Primarily used by `@architect-supreme` for enterprise architecture governance
**Use Cases**:
- Technology stack selection (Azure SQL vs. Cosmos DB)
- Integration pattern decisions (REST API vs. Event-driven)
- Microsoft service evaluation (Azure Functions vs. App Service)
- Security architecture choices (Managed Identity vs. Service Principal)

**Key Sections**:
- **Context**: Business problem and technical constraints
- **Decision Drivers**: Requirements, priorities, constraints
- **Options Analysis**: Alternatives considered with pros/cons
- **Decision Outcome**: Selected approach with justification
- **Cost Analysis**: Financial implications and ROI
- **Microsoft Ecosystem Alignment**: How decision fits Microsoft-first strategy
- **Monitoring & Validation**: Success criteria and KPIs

**Example Usage**:
```bash
# Create new ADR for database selection
cp .claude/templates/adr-template.md docs/adr/001-cosmos-db-for-event-sourcing.md
# @architect-supreme fills in details based on requirements
```

#### 2. Runbook Template
**File**: [runbook-template.md](.claude/templates/runbook-template.md)
**Purpose**: Standardized operational procedures for Azure deployments and incident response
**Agent**: Primarily used by `@integration-specialist` and `@deployment-orchestrator` (future agent)
**Use Cases**:
- Azure App Service deployment procedures
- Database migration runbooks
- Disaster recovery workflows
- Incident response procedures (SEV1-SEV4)
- Scaling operations

**Key Sections**:
- **Service Overview**: Azure resources, endpoints, dependencies
- **Monitoring & Alerting**: Application Insights queries, alert thresholds
- **Common Operations**: Deployment, rollback, scaling, configuration changes
- **Incident Response**: Severity definitions, escalation procedures, communication templates
- **Troubleshooting Guide**: Common issues, diagnostic steps, resolution procedures
- **Contacts**: On-call rotations, escalation paths

**Example Usage**:
```bash
# Create runbook for Example Build deployment
cp .claude/templates/runbook-template.md docs/runbooks/cost-dashboard-deployment.md
# @integration-specialist documents deployment procedures
```

### Template Usage Guidelines

**When to Create ADR**:
- Technology decisions with long-term impact (> 6 months)
- Architectural changes affecting multiple systems
- Microsoft service evaluations with alternatives
- Security or compliance architecture decisions
- Cost optimization strategies requiring justification

**When to Create Runbook**:
- New Azure service deployment
- Production incident response procedures
- Database migration or scaling operations
- Disaster recovery workflows
- Any operational procedure requiring team coordination

**AI-Agent Friendly Structure**:
- All templates use explicit headers and consistent formatting
- Checklists for verification steps
- Code blocks with exact commands (no ambiguity)
- Environment-specific configurations clearly separated
- Prerequisites and validation steps for every operation

**Brookside BI Brand Alignment**:
- Templates lead with business value and outcomes
- Use consultative, solution-focused language
- Emphasize Microsoft ecosystem integration
- Include cost analysis and ROI considerations
- Structure for scalability and team collaboration

**Best for**: Organizations establishing governance frameworks for architecture decisions and operational excellence while maintaining sustainable practices that support growth across distributed teams.

## Slash Commands Quick Reference

Slash commands provide executable workflows that delegate to specialized agents. This section establishes sustainable command patterns for innovation operations.

### Innovation Commands

**Category**: `.claude/commands/innovation/`

| Command | Purpose | Parameters | Example |
|---------|---------|------------|---------|
| `/innovation:new-idea` | Capture innovation opportunity with duplicate prevention | `[idea description]` | `/innovation:new-idea Automated Power BI deployment pipeline` |
| `/innovation:start-research` | Begin structured feasibility investigation | `[topic] [originating-idea-title]` | `/innovation:start-research "Azure OpenAI integration" "AI-powered insights"` |
| `/orchestrate-complex` | Orchestrate complex multi-agent workflows with parallel execution and dependency management | `[task-description]` | `/orchestrate-complex Build Azure OpenAI integration with architecture, deployment, and documentation` |
| `/project-plan` | Create comprehensive project plans for Innovation Nexus initiatives from Idea through Research, Build, and Knowledge Vault | `[project-name] [--phase=stage] [--scope=range]` | `/project-plan azure-openai-integration --phase=planning` |

**Delegates to**: `@ideas-capture`, `@research-coordinator`, `@workflow-router`, `@cost-analyst` (for ideas/research commands); Multiple specialized agents in parallel waves for `/orchestrate-complex` and `/project-plan`

### Autonomous Commands

**Category**: `.claude/commands/autonomous/`

| Command | Purpose | Parameters | Example |
|---------|---------|------------|---------|
| `/autonomous:enable-idea` | Enable autonomous workflow for idea - from research through deployment with minimal human intervention | `[idea-name]` | `/autonomous:enable-idea Real-time collaboration features` |
| `/autonomous:status` | Display real-time status of autonomous innovation pipelines across Ideas, Research, and Builds | - | `/autonomous:status` |

**Delegates to**: `@notion-orchestrator`, `@research-coordinator`, `@build-architect-v2`, `@deployment-orchestrator`, `@market-researcher`, `@technical-analyst`, `@cost-feasibility-analyst`, `@risk-assessor`

**Workflow Execution:**
1. **Research Swarm** (25-30 min): 4 parallel agents analyze market, technical feasibility, cost, and risk
2. **Viability Assessment** (5 min): Automated scoring with auto-approval (>85), escalation (60-85), or archival (<60)
3. **Code Generation** (30-40 min): Production-ready application scaffolding with tests and infrastructure
4. **Azure Deployment** (15-20 min): Bicep templates provision resources with CI/CD pipelines
5. **Health Validation** (10-15 min): Smoke tests and monitoring setup

**Time Reduction**: 95% improvement (2-4 weeks → 40-60 minutes)
**Human Intervention**: <5% for most workflows

### Repository Analysis Commands

**Category**: `.claude/commands/repo/`

| Command | Purpose | Parameters | Example |
|---------|---------|------------|---------|
| `/repo:scan-org` | Scan all GitHub organization repositories with comprehensive analysis and Notion synchronization | `[--sync] [--deep] [--exclude repo1,repo2]` | `/repo:scan-org --sync --deep` |
| `/repo:analyze` | Analyze single GitHub repository with comprehensive viability assessment and optional Notion sync | `<repo-name> [--sync] [--deep]` | `/repo:analyze repo-analyzer --sync` |
| `/repo:extract-patterns` | Extract cross-repository architectural patterns and assess reusability | `[--min-usage 3] [--sync]` | `/repo:extract-patterns --sync` |
| `/repo:calculate-costs` | Calculate portfolio-wide software costs with optimization recommendations | `[--detailed] [--category <name>]` | `/repo:calculate-costs --detailed` |

**Delegates to**: `@repo-analyzer`, `@github-repo-analyst`, `@cost-analyst`, `@notion-orchestrator`

**Capabilities:**
- **Multi-dimensional Viability Scoring**: Test coverage (30pts), Activity (20pts), Documentation (25pts), Dependencies (25pts)
- **Claude Integration Detection**: Maturity levels (Expert/Advanced/Intermediate/Basic/None) based on agents, commands, MCP servers
- **Pattern Mining**: Identify shared architectural patterns across 3+ repositories
- **Cost Aggregation**: Total monthly spend from dependency analysis with Microsoft alternatives
- **Notion Synchronization**: Automated Example Builds entries with Software Tracker links

**Execution Time**: 3-5 minutes for 50 repositories

### Cost Commands

**Category**: `.claude/commands/cost/`

| Command | Purpose | Parameters | Example |
|---------|---------|------------|---------|
| `/cost:analyze` | Comprehensive spend analysis with optimization | `[scope: all\|active\|unused\|expiring]` | `/cost:analyze unused` |
| `/cost:monthly-spend` | Quick total monthly software spend | - | `/cost:monthly-spend` |
| `/cost:annual-projection` | Yearly cost forecast | - | `/cost:annual-projection` |
| `/cost:expiring-contracts` | Identify renewals within 60 days | - | `/cost:expiring-contracts` |
| `/cost:unused-software` | Find tools with no active relations | - | `/cost:unused-software` |
| `/cost:consolidation-opportunities` | Detect duplicate capabilities | - | `/cost:consolidation-opportunities` |
| `/cost:microsoft-alternatives` | Suggest Microsoft-first replacements | `[software-name]` | `/cost:microsoft-alternatives "Slack"` |
| `/cost:what-if-analysis` | Model cost scenarios | `[scenario description]` | `/cost:what-if-analysis "Remove 5 licenses from GitHub"` |
| `/cost:build-costs` | Calculate costs for specific build | `[build-name]` | `/cost:build-costs "Cost Dashboard MVP"` |
| `/cost:research-costs` | Research-specific cost breakdown | `[research-topic]` | `/cost:research-costs "Azure OpenAI research"` |
| `/cost:cost-by-category` | Category-based spend analysis | `[category]` | `/cost:cost-by-category Development` |
| `/cost:cost-impact` | Assess impact of adding/removing tool | `[tool-name] [action]` | `/cost:cost-impact "Power BI Pro" add` |

**Delegates to**: `@cost-analyst`, `@viability-assessor`

### Knowledge Commands

**Category**: `.claude/commands/knowledge/`

| Command | Purpose | Parameters | Example |
|---------|---------|------------|---------|
| `/knowledge:archive` | Complete lifecycle with learnings preservation | `[item-name] [database: idea\|research\|build]` | `/knowledge:archive "AI Documentation Generator" build` |

**Delegates to**: `@archive-manager`, `@knowledge-curator`, `@markdown-expert`

### Compliance Commands

**Category**: `.claude/commands/compliance/`

| Command | Purpose | Parameters | Example |
|---------|---------|------------|---------|
| `/compliance:audit` | Comprehensive software licensing and governance compliance assessment | `[scope: all\|active\|new]` | `/compliance:audit active` |

**Delegates to**: `@compliance-orchestrator`, `@cost-analyst`, `@integration-specialist`, `@knowledge-curator`

**Compliance Frameworks Supported**:
- **Software Licensing**: MIT, Apache 2.0, GPL, BSD, Commercial licenses, EULA compliance
- **GDPR**: EU data protection regulations (Art. 6, 7, 15, 17, 32)
- **CCPA**: California Consumer Privacy Act requirements
- **Third-Party Integration Security**: Authentication methods, data sharing, access controls

**Audit Workflow**:
1. **Scoping Phase** (3 agents parallel): Identify applicable frameworks, query Software Tracker, assess Integration Registry
2. **Assessment Phase** (4 agents parallel): License compliance, GDPR assessment, CCPA evaluation, security review
3. **Remediation Phase**: Prioritize findings, create action items, assign owners
4. **Documentation Phase**: Generate compliance report, archive to Knowledge Vault

**Output**: Comprehensive compliance report with findings categorized by severity (Critical, High, Medium, Low, Informational), remediation recommendations, and Knowledge Vault documentation.

**Best for**: Organizations requiring regulatory compliance visibility, software licensing audit trails, and third-party integration security reviews across the Innovation Nexus platform.

### Team Commands

**Category**: `.claude/commands/team/`

| Command | Purpose | Parameters | Example |
|---------|---------|------------|---------|
| `/team:assign` | Route work to specialist based on expertise | `[work-description] [database]` | `/team:assign "ML model for forecasting" build` |

**Delegates to**: `@workflow-router`, `@cost-analyst`

### Command Usage Patterns

**Daily Operations:**
```bash
# Morning: Check spend
/cost:monthly-spend

# Capture new idea
/innovation:new-idea Real-time collaboration features using Azure SignalR

# Assign to team member
/team:assign "Azure SignalR integration" idea

# Regular: Review costs
/cost:analyze
```

**Monthly Cost Review:**
```bash
# Step 1: Comprehensive analysis
/cost:analyze all

# Step 2: Find waste
/cost:unused-software

# Step 3: Check renewals
/cost:expiring-contracts

# Step 4: Identify consolidation
/cost:consolidation-opportunities
```

**Complete Innovation Cycle:**
```bash
# 1. Capture
/innovation:new-idea [description]

# 2. Research (if needed)
/innovation:start-research [topic] [idea-name]

# 3. Archive when complete
/knowledge:archive [item-name] [database]
```

**Best for**: Teams seeking repeatable, automated workflows that ensure consistent execution of innovation management operations while maintaining cost transparency and knowledge preservation.

## Common Workflows

These workflows establish sustainable patterns for innovation management that drive measurable outcomes through structured, repeatable processes.

### Workflow 1: Complete Innovation Lifecycle

**Purpose**: Transform raw idea into production-ready example with full knowledge capture

**Stages**: Concept → Research → Build → Deploy → Archive → Knowledge Vault

```
Step 1: Capture Idea
├─ Command: /innovation:new-idea [description]
├─ Agent: @ideas-capture
├─ Outputs: Ideas Registry entry, Champion assigned, Cost estimate
└─ Next: Research or Build?

Step 2: Conduct Research (if Viability = "Needs Research")
├─ Command: /innovation:start-research [topic] [idea-name]
├─ Agent: @research-coordinator
├─ Outputs: Research Hub entry, Hypothesis, Methodology, SharePoint/OneNote links
└─ Next: Viability Assessment

Step 3: Assess Viability
├─ Agent: @viability-assessor (auto-invoked during research completion)
├─ Outputs: Highly Viable | Moderately Viable | Not Viable | Inconclusive
├─ Decision: Build Example | More Research | Archive | Abandon
└─ Next: If "Build Example" → Create Build

Step 4: Create Build
├─ Command: /innovation:create-build [name] [type]
├─ Agent: @build-architect
├─ Outputs: Example Build entry, GitHub repo, Technical docs, Cost rollup
├─ Supporting Agents: @integration-specialist (Azure/M365), @workflow-router (team)
└─ Next: Development work begins

Step 5: Develop & Deploy
├─ Activities: Code, test, document, deploy to Azure
├─ Tools: GitHub, Azure DevOps, Azure services
├─ Tracking: Update Build entry with progress, link resources
└─ Next: Completion & Archive

Step 6: Archive with Learnings
├─ Command: /knowledge:archive [build-name] build
├─ Agent: @archive-manager + @knowledge-curator
├─ Outputs: Status = Archived, Knowledge Vault entry, Lessons documented
├─ Verification: All links preserved, costs tracked, reusability assessed
└─ Complete: Idea → Build → Knowledge lifecycle closed

Verification Steps:
✓ Check Ideas Registry: Idea status updated through lifecycle
✓ Check Research Hub: Findings documented, viability recorded
✓ Check Example Builds: Build entry complete with all links
✓ Check Knowledge Vault: Learnings captured for future reference
✓ Check Software Tracker: All costs properly linked
```

**Best for**: High-value innovations requiring thorough investigation before implementation.

### Workflow 2: Cost Optimization Sprint

**Purpose**: Quarterly cost review to identify savings and optimize spend

**Stages**: Analyze → Identify Waste → Consolidate → Optimize

```
Phase 1: Comprehensive Analysis
├─ Command: /cost:analyze all
├─ Agent: @cost-analyst
├─ Outputs:
│   ├─ Total monthly spend: $X,XXX
│   ├─ Annual projection: $XX,XXX
│   ├─ Top 5 expenses identified
│   ├─ Category breakdown
│   └─ Potential savings estimate
└─ Next: Drill into specific areas

Phase 2: Identify Unused Software
├─ Command: /cost:unused-software
├─ Agent: @cost-analyst
├─ Query: Status = "Active" AND no relations to Ideas/Research/Builds
├─ Outputs: List of tools with $0 utilization
├─ Action: Review with owners, consider cancellation
└─ Potential Savings: $XXX/month

Phase 3: Find Duplicate Tools
├─ Command: /cost:consolidation-opportunities
├─ Agent: @cost-analyst
├─ Detection: Multiple tools in same category
├─ Outputs: Consolidation recommendations
├─ Example: 3 project management tools → 1 Microsoft solution
└─ Potential Savings: $XXX/month

Phase 4: Check Microsoft Alternatives
├─ Command: /cost:microsoft-alternatives [tool-name]
├─ Agent: @cost-analyst
├─ Priority: Microsoft 365 → Azure → Power Platform → GitHub
├─ Outputs: Direct replacements with cost comparison
├─ Example: Slack → Microsoft Teams (included in M365)
└─ Potential Savings: $XXX/month

Phase 5: Contract Renewals
├─ Command: /cost:expiring-contracts
├─ Agent: @cost-analyst
├─ Window: Next 60 days
├─ Outputs: Renewal decisions required
├─ Action: Review each contract, negotiate or cancel
└─ Potential Savings: Renegotiation opportunities

Phase 6: Implementation
├─ Activities:
│   ├─ Cancel unused software
│   ├─ Migrate to Microsoft alternatives
│   ├─ Consolidate duplicate tools
│   ├─ Renegotiate contracts
│   └─ Update Software Tracker with changes
├─ Tracking: Document savings realized
└─ Verification: /cost:monthly-spend before/after comparison

Quarterly Follow-Up:
✓ Month 1: Execute cancellations and migrations
✓ Month 2: Monitor adoption and usage
✓ Month 3: Measure actual savings vs. projected
✓ Quarter end: Run full analysis again, iterate
```

**Expected Outcomes**: 10-20% cost reduction, improved Microsoft ecosystem alignment, reduced tool sprawl.

**Best for**: Finance-driven organizations seeking measurable cost reductions through systematic software optimization.

### Workflow 3: Team Workload Balancing

**Purpose**: Ensure even distribution of work based on specialization and capacity

**Frequency**: Weekly or when assigning new work

```
Step 1: Analyze New Work
├─ Input: Work description from user
├─ Agent: @workflow-router
├─ Analysis:
│   ├─ Extract keywords (Azure, ML, DevOps, Sales, etc.)
│   ├─ Categorize by domain
│   ├─ Assess complexity and effort
│   └─ Identify required specializations
└─ Next: Match to team member

Step 2: Match to Specializations
├─ Team Member Expertise:
│   ├─ Markus Ahling: Engineering, Operations, AI, Infrastructure
│   ├─ Brad Wright: Sales, Business, Finance, Marketing
│   ├─ Stephan Densby: Operations, Continuous Improvement, Research
│   ├─ Alec Fielding: DevOps, Engineering, Security, Integrations, R&D
│   └─ Mitch Bisbee: DevOps, Engineering, ML, Master Data, Quality
├─ Matching Logic:
│   ├─ Primary: Strongest specialization alignment
│   ├─ Secondary: Adjacent skill areas
│   └─ Multi-person: If cross-functional
└─ Next: Check workload

Step 3: Check Current Workload
├─ Command: /team:assign [work-description]
├─ Query per team member:
│   ├─ Active Ideas (Champion = Person)
│   ├─ Active Research (Researchers contains Person)
│   ├─ Active Builds (Lead Builder or Core Team = Person)
│   └─ Total active count
├─ Thresholds:
│   ├─ Optimal: 3-5 active items
│   ├─ Full: 5-7 active items
│   └─ ⚠️ Overloaded: > 7 active items
└─ Next: Assign or rebalance

Step 4: Assignment Decision
├─ If primary match has capacity:
│   ├─ Assign to primary
│   ├─ Update Notion database
│   ├─ Notify assignee
│   └─ Complete
├─ If primary overloaded:
│   ├─ Suggest alternative with matching specialization
│   ├─ OR suggest redistributing existing work
│   ├─ OR delay new assignment
│   └─ User decides
└─ Multi-person work: Assign lead + supporting team

Step 5: Ongoing Monitoring
├─ Weekly team review:
│   ├─ Check: Each person's active item count
│   ├─ Identify: Items stuck or blocked
│   ├─ Action: Redistribute if needed
│   └─ Ensure: No one > 7 active items
└─ Continuous: Update as items complete or archive

Workload Rebalancing Triggers:
✓ Team member has > 7 active items
✓ Critical new work requires specific specialist
✓ Items not progressing
✓ Team member requests redistribution
✓ Vacation or leave upcoming
```

**Best for**: Teams with diverse specializations requiring strategic work distribution to maintain sustainable pace and prevent burnout.

### Workflow 4: Emergency Research Investigation

**Purpose**: Rapid feasibility assessment for time-sensitive opportunities

**Stages**: Idea → Fast Research → Decision → Action

```
Step 1: Rapid Investigation
├─ Command: /innovation:new-idea [urgent opportunity]
├─ Command: /innovation:start-research [topic] [idea-name]
├─ Agent: @research-coordinator
├─ Hypothesis: Clear success criteria defined
├─ Research activities:
│   ├─ Microsoft documentation review
│   ├─ Proof-of-concept code (if technical)
│   ├─ Cost estimation
│   └─ Risk identification
├─ Documentation: Real-time in SharePoint/OneNote
└─ Team: Dedicated focus, minimize distractions

Step 2: Viability Assessment
├─ Complete research documentation
│   ├─ Key Findings: Documented in Research Hub
│   ├─ Viability: Preliminary assessment
│   ├─ Risks: Identified with mitigation strategies
│   └─ Costs: Detailed breakdown
├─ Stakeholder review
│   ├─ Agent: @viability-assessor
│   ├─ Present findings to decision makers
│   ├─ Effort vs. Impact analysis
│   └─ Go/No-Go recommendation
└─ Decision point

Decision Outcomes:
├─ GO: Build Example immediately
│   ├─ Command: /innovation:create-build [name] poc
│   ├─ Fast-track: Skip normal approval process
│   └─ Success criteria: Defined in research
├─ MORE RESEARCH: Needs deeper investigation
│   ├─ Identify unknowns to address
│   └─ Schedule follow-up decision point
└─ NO-GO: Not viable or not worth effort
    ├─ Archive idea with rationale
    ├─ Command: /knowledge:archive [idea-name] idea
    └─ Learnings: Document why rejected

Step 3: Action (if GO)
├─ Build Creation: @build-architect
├─ GitHub Setup: Repository created
├─ Azure Resources: Provisioned if needed
└─ Team Mobilization: Dedicated POC sprint

Verification:
✓ Research completed
✓ Decision made with clear rationale
✓ If GO: POC development underway
✓ If NO-GO: Idea archived with learnings
```

**Best for**: High-stakes opportunities with short decision windows requiring rapid feasibility validation.

### Workflow 5: Build Creation & Deployment

**Purpose**: Structured approach to creating, deploying, and tracking example builds

**Stages**: Architecture → Repository → Documentation → Deploy → Track Costs

```
Phase 1: Architecture Design
├─ Command: /innovation:create-build [name] [type]
├─ Agent: @build-architect
├─ Activities:
│   ├─ System architecture design
│   ├─ Technology stack selection (Microsoft-first)
│   ├─ Data model design
│   ├─ Integration points identified
│   ├─ Security requirements
│   └─ Cost estimation
├─ Outputs:
│   ├─ Example Build entry in Notion
│   ├─ Technical specification page (AI-agent friendly)
│   ├─ Architecture diagrams (@mermaid-diagram-expert)
│   └─ GitHub repository URL required
└─ Next: Repository setup

Phase 2: GitHub Repository Setup
├─ Agent: @integration-specialist
├─ Activities:
│   ├─ Create repository under github.com/brookside-bi
│   ├─ Initialize with README (use @markdown-expert)
│   ├─ Add .gitignore for technology stack
│   ├─ Create branch protection rules
│   ├─ Set up GitHub Actions for CI/CD
│   └─ Link repository to Notion Build entry
├─ Outputs:
│   ├─ Repository URL in Build entry
│   ├─ README with setup instructions
│   ├─ CI/CD pipeline configured
│   └─ Branch strategy documented
└─ Next: Development environment

Phase 3: Documentation
├─ Agent: @markdown-expert
├─ Technical Documentation Required:
│   ├─ README.md: Project overview, quick start
│   ├─ ARCHITECTURE.md: System design, diagrams
│   ├─ API.md: Endpoints, request/response schemas (if applicable)
│   ├─ DEPLOYMENT.md: Azure deployment steps
│   ├─ COST.md: Service breakdown, monthly/annual estimates
│   └─ CHANGELOG.md: Version history
├─ Standards:
│   ├─ AI-agent executable (explicit, no ambiguity)
│   ├─ Idempotent setup steps
│   ├─ Explicit version requirements
│   ├─ Environment variable templates
│   └─ Brookside BI brand voice
└─ Next: Local development

Phase 4: Development
├─ Activities:
│   ├─ Core functionality implementation
│   ├─ Unit and integration tests
│   ├─ Code reviews with team
│   ├─ Documentation updates as architecture evolves
│   └─ Local testing and debugging
├─ Tracking:
│   ├─ Update Build entry with progress
│   ├─ Link pull requests
│   └─ Document blockers and solutions
└─ Next: Azure deployment

Phase 5: Azure Deployment
├─ Agent: @integration-specialist
├─ Azure Resources Setup:
│   ├─ Resource Group creation
│   ├─ App Service / Function App / AKS (depending on build)
│   ├─ Database (SQL, Cosmos, etc. if needed)
│   ├─ Storage Account (if needed)
│   ├─ Application Insights for monitoring
│   ├─ Key Vault for secrets
│   └─ Managed Identity for authentication
├─ Security:
│   ├─ No hardcoded credentials
│   ├─ All secrets in Azure Key Vault
│   ├─ Managed Identity where possible
│   ├─ Network security groups configured
│   └─ Security review completed
├─ Deployment Pipeline:
│   ├─ GitHub Actions workflow
│   ├─ Automated deployment to Azure
│   ├─ Environment-specific configurations (dev/staging/prod)
│   └─ Rollback procedures documented
└─ Next: Cost tracking

Phase 6: Cost Tracking & Linking
├─ Agent: @cost-analyst
├─ Activities:
│   ├─ Identify ALL software/tools used
│   ├─ Search Software Tracker for each
│   ├─ Add new entries if tools not found
│   ├─ Create relations: Software → Build
│   ├─ Verify Total Cost rollup displays
│   └─ Document cost breakdown in COST.md
├─ Software Categories:
│   ├─ Azure services (App Service, SQL, Storage, etc.)
│   ├─ GitHub (if paid org)
│   ├─ Development tools (IDEs, etc.)
│   ├─ Third-party APIs or services
│   └─ Monitoring/observability tools
├─ Command: /cost:build-costs [build-name]
└─ Next: Integration registry

Phase 7: Integration Registry
├─ Agent: @integration-specialist
├─ Activities:
│   ├─ Create Integration Registry entry
│   ├─ Document authentication method
│   ├─ Link to Build and Software entries
│   ├─ Security review status
│   └─ API endpoints and webhooks
└─ Complete: Build operational and tracked

Verification Checklist:
✓ Build entry in Notion with all fields populated
✓ GitHub repository with comprehensive documentation
✓ Azure resources deployed and monitored
✓ All software/tools linked to build
✓ Total Cost rollup displays correctly
✓ Integration Registry entry created (if applicable)
✓ Technical documentation is AI-agent executable
✓ Team can deploy from scratch using docs alone
```

**Best for**: Production-quality builds requiring full deployment lifecycle with cost transparency and knowledge preservation.

### Workflow 6: Knowledge Capture & Sharing

**Purpose**: Extract and preserve learnings from completed work for organizational knowledge base

**Stages**: Complete Work → Extract Learnings → Archive → Share

```
Step 1: Identify Completion
├─ Triggers:
│   ├─ Build Status → "Completed"
│   ├─ Research Next Steps → "Archive"
│   ├─ Idea fully explored
│   └─ User explicitly says "done" or "archive"
└─ Next: Assess knowledge value

Step 2: Assess Knowledge Value
├─ Agent: @knowledge-curator
├─ Criteria for Knowledge Vault:
│   ├─ ✓ Reusable patterns or templates created
│   ├─ ✓ Novel problems solved with documented solutions
│   ├─ ✓ Failed experiments with valuable learnings
│   ├─ ✓ Process improvements that benefit future work
│   ├─ ✓ Technical breakthroughs or innovations
│   └─ ✗ Routine work with no unique insights
├─ Decision: Create Knowledge Vault entry?
│   ├─ YES → Proceed to Step 3
│   └─ NO → Skip to Step 6 (Archive only)
└─ Next: Extract learnings

Step 3: Extract Learnings
├─ Agent: @knowledge-curator + @markdown-expert
├─ Content to Capture:
│   ├─ Problem Statement: What business challenge was addressed?
│   ├─ Solution Approach: How was it solved?
│   ├─ Key Decisions: Architecture choices, technology selections
│   ├─ Challenges Overcome: Blockers and how they were resolved
│   ├─ Unexpected Findings: Surprises during implementation
│   ├─ Cost Insights: Budget vs. actual, optimization opportunities
│   ├─ Team Learnings: Skills developed, collaboration patterns
│   └─ Future Recommendations: What we'd do differently
└─ Next: Structure knowledge entry

Step 4: Create Knowledge Vault Entry
├─ Command: /knowledge:archive [item-name] [database]
├─ Agent: @knowledge-curator
├─ Content Type Selection:
│   ├─ Tutorial: Step-by-step guides for repeatable tasks
│   ├─ Case Study: Complete project story with outcomes
│   ├─ Technical Doc: Architecture, API specs, integration guides
│   ├─ Process: Repeatable workflows and methodologies
│   ├─ Template: Reusable project structures, code templates
│   ├─ Post-Mortem: What worked, what didn't, lessons learned
│   └─ Reference: Quick-lookup information, cheat sheets
├─ Evergreen vs. Dated:
│   ├─ Evergreen: Timeless principles, architectural patterns
│   └─ Dated: Version-specific, time-sensitive information
├─ Entry Structure:
│   ├─ Title: Descriptive, searchable
│   ├─ Summary: 2-3 sentence overview
│   ├─ Full Content: Detailed documentation
│   ├─ Related Resources: Links to Builds, GitHub, docs
│   ├─ Tags: Technology, domain, team members
│   └─ Reusability Assessment: High | Medium | Low
└─ Next: Archive original item

Step 5: Archive Original Item
├─ Agent: @archive-manager
├─ Activities:
│   ├─ Update Status → "Archived" or "Not Active"
│   ├─ Add completion date
│   ├─ Link to Knowledge Vault entry
│   ├─ Verify all external links preserved:
│   │   ├─ GitHub repositories
│   │   ├─ SharePoint/OneNote documents
│   │   ├─ Azure resources
│   │   ├─ Teams channels
│   │   └─ Integration endpoints
│   ├─ Maintain software relations for historical cost tracking
│   └─ Update dependent items
└─ Next: Share knowledge

Step 6: Share Knowledge
├─ Distribution Channels:
│   ├─ Teams announcement in appropriate channels
│   ├─ Email summary to stakeholders
│   ├─ Mention in weekly team sync
│   ├─ Add to onboarding materials (if broadly applicable)
│   └─ Reference in future similar work
├─ Make Discoverable:
│   ├─ Descriptive title optimized for search
│   ├─ Comprehensive tags
│   ├─ Cross-links to related knowledge
│   └─ Listed in relevant "See Also" sections
└─ Complete: Knowledge preserved and shared

Verification:
✓ Knowledge Vault entry created with comprehensive content
✓ Original item archived with link to knowledge entry
✓ All external links preserved
✓ Team notified of new knowledge resource
✓ Content is searchable and discoverable
✓ Reusability clearly assessed
```

**Expected Outcomes**: Organizational learning accelerates, duplicate work prevented, new team members ramp up faster.

**Best for**: Knowledge-driven organizations seeking to build institutional memory and accelerate innovation through systematic learning capture.

## Agent + Command Integration Matrix

This matrix establishes clear delegation patterns showing how slash commands route to specialized agents for execution.

| Command Category | Primary Agent(s) | Supporting Agents | Typical Workflow |
|------------------|------------------|-------------------|------------------|
| **`/innovation:new-idea`** | `@ideas-capture` | `@workflow-router`<br>`@cost-analyst`<br>`@viability-assessor` | Search duplicates → Create entry → Assign champion → Estimate costs → Assess viability |
| **`/innovation:start-research`** | `@research-coordinator` | `@cost-analyst`<br>`@integration-specialist`<br>`@workflow-router` | Create research → Link idea → Setup docs → Assign researchers → Track costs |
| **`/innovation:create-build`** | `@build-architect` | `@integration-specialist`<br>`@cost-analyst`<br>`@workflow-router`<br>`@markdown-expert` | Design architecture → Setup GitHub → Create docs → Assign team → Link costs |
| **`/cost:*`** (all cost commands) | `@cost-analyst` | `@viability-assessor` | Query Software Tracker → Calculate metrics → Identify optimizations → Recommend actions |
| **`/knowledge:archive`** | `@archive-manager`<br>`@knowledge-curator` | `@markdown-expert` | Verify learnings → Create vault entry → Update status → Preserve links |
| **`/team:assign`** | `@workflow-router` | `@cost-analyst` | Analyze work → Match specializations → Check workload → Assign or rebalance |

### Command → Agent Delegation Logic

**Single-Agent Commands:**
- Simple operations delegated to one specialized agent
- Example: `/cost:monthly-spend` → `@cost-analyst` (straightforward query)

**Multi-Agent Workflows:**
- Complex operations requiring multiple specialists
- Example: `/innovation:new-idea` → `@ideas-capture` (lead) + `@workflow-router` + `@cost-analyst` + `@viability-assessor`

**Agent Chaining:**
- Sequential agent invocations based on workflow stage
- Example: `/knowledge:archive` → `@archive-manager` (first) → `@knowledge-curator` (second)

### When to Use Commands vs. Direct Agent Invocation

**Use Slash Commands When:**
- ✓ Workflow is well-defined and repeatable
- ✓ Multiple steps need to execute in sequence
- ✓ User wants standardized operation
- ✓ Documentation/verification steps important

**Use Direct Agent Invocation When:**
- ✓ Custom or one-off operations
- ✓ Need agent's specialized expertise for consultation
- ✓ Troubleshooting or debugging
- ✓ Exploratory analysis without formal workflow

**Example:**
```bash
# Use command for standard operation
/innovation:new-idea Automated cost tracking dashboard

# Use agent directly for custom analysis
@cost-analyst What would happen to our budget if we consolidated
all project management tools to Microsoft Planner?
```

**Best for**: Organizations requiring clear operational patterns that maximize automation while retaining flexibility for custom scenarios through direct agent access.

## Notes for Claude Code Agents

This project establishes scalable infrastructure for innovation management with enterprise-grade security and automation:

### Core Principles

- **Notion is source of truth** for all innovation tracking
- **Azure Key Vault is source of truth** for all secrets and credentials
- **Cost tracking is critical** - never skip linking software/tools
- **Microsoft ecosystem is default** - always check Microsoft solutions first
- **Status over timelines** - focus on viability and progress, not deadlines
- **Archive liberally** - every completed build becomes reference material
- **Relations create value** - database connections enable cost rollups and context
- **Team specializations matter** - respect expertise when assigning work
- **Technical docs for AI agents** - all builds should be executable by future AI agents
- **Brand consistency** - apply Brookside BI voice to all outputs

### Infrastructure Context

**You have access to 4 MCP servers:**
1. **Notion** - Innovation tracking and knowledge management
2. **GitHub** - Version control and repository operations
3. **Azure** - Cloud resources, Key Vault, and deployment
4. **Playwright** - Browser automation and testing

**All secrets are centralized in Azure Key Vault:**
- GitHub PAT: `github-personal-access-token`
- Notion API: `notion-api-key` (when needed)
- Azure OpenAI: `azure-openai-api-key` (when configured)

**Never hardcode credentials** - always reference Key Vault or use `scripts/Get-KeyVaultSecret.ps1`

### Automated Workflows

**When creating Example Builds:**
1. Create GitHub repository (via GitHub MCP)
2. Link repository URL to Notion Build entry
3. Track all software/tools costs (link to Software Tracker)
4. Create AI-agent-friendly technical documentation
5. Deploy to Azure if needed (via Azure MCP)
6. Link Azure resources to Integration Registry

**When starting Research:**
1. Create Research Hub entry (via Notion MCP)
2. Link to originating Idea
3. Track research tools in Software Tracker
4. Set up GitHub repo for research code if needed
5. Document findings for Knowledge Vault

**When managing costs:**
1. Query Software Tracker via Notion MCP
2. Calculate rollups from relations
3. Identify unused tools (no active relations)
4. Check contract expiration dates
5. Suggest Microsoft alternatives where applicable

### Security Best Practices

**When working with credentials:**
- ✓ Use `scripts/Get-KeyVaultSecret.ps1` to retrieve secrets
- ✓ Reference Key Vault in documentation, never actual values
- ✓ Use environment variables from `Set-MCPEnvironment.ps1`
- ✗ Never commit secrets to Git
- ✗ Never display secrets in output or logs
- ✗ Never hardcode credentials in code or documentation

**When deploying to Azure:**
- ✓ Use Managed Identity when possible
- ✓ Reference Key Vault for application secrets
- ✓ Document resource IDs and SKUs
- ✓ Track costs in Software Tracker
- ✗ Never use inline credentials

### Integration Patterns

**Notion ↔ GitHub:**
- Link GitHub repo URLs in Example Builds
- Reference Notion entries in commit messages
- Track integration in Integration Registry

**Notion ↔ Azure:**
- Link Azure resource URLs in Builds
- Deploy builds to Azure App Services
- Store deployment configs in Key Vault
- Track Azure service costs in Software Tracker

**GitHub ↔ Azure:**
- Use GitHub Actions for CI/CD to Azure
- Authenticate with Service Principal (stored in Key Vault)
- Deploy from GitHub to Azure App Services
- Track deployment pipeline in Integration Registry

### Performance Optimization

**MCP Server Usage:**
- Notion MCP: Cache database schemas, reuse queries
- GitHub MCP: Batch file operations when possible
- Azure MCP: Check authentication status before operations
- Playwright MCP: Reuse browser sessions when testing

**Remember**: You're building an innovation engine designed to streamline workflows and drive measurable outcomes through structured approaches. Focus on learning, reusability, cost transparency, knowledge capture, and secure credential management to support sustainable growth.

## Brookside Repository Analyzer

**Location**: `brookside-repo-analyzer/` subdirectory

### Purpose

Automated GitHub organization repository analysis tool designed to establish comprehensive portfolio visibility and drive measurable outcomes through systematic viability assessment, pattern mining, and Notion integration.

**Key Capabilities:**
- Multi-dimensional repository viability scoring (0-100 points)
- Claude Code integration maturity detection
- Cross-repository pattern extraction
- Dependency cost calculation and optimization
- Automated Notion synchronization (Example Builds, Software Tracker, Knowledge Vault)

### Architecture

```
brookside-repo-analyzer/
├── src/
│   ├── config.py                # Pydantic settings
│   ├── auth.py                  # Azure Key Vault integration
│   ├── models.py                # Data models
│   ├── github_mcp_client.py     # GitHub API wrapper
│   ├── notion_client.py         # Notion API wrapper
│   ├── cli.py                   # Click CLI interface
│   └── analyzers/
│       ├── repo_analyzer.py     # Viability scoring
│       ├── claude_detector.py   # .claude/ parsing
│       ├── pattern_miner.py     # Pattern extraction
│       └── cost_calculator.py   # Cost analysis
├── tests/
│   ├── unit/                    # Unit tests (mocked)
│   ├── integration/             # Integration tests (real APIs)
│   └── e2e/                     # End-to-end CLI tests
├── deployment/
│   ├── azure_function/          # Serverless weekly scans
│   └── github_actions/          # CI/CD workflows
└── docs/
    ├── README.md                # Quick start guide
    ├── ARCHITECTURE.md          # System design
    ├── API.md                   # CLI/Python/HTTP API docs
    └── CONTRIBUTING.md          # Developer guide
```

### Claude Code Integration

**Agent**: `@repo-analyzer`
- Orchestrates full organization scans
- Performs viability scoring and Claude detection
- Syncs results to Notion databases

**Slash Commands**:
- `/repo:scan-org [--sync] [--deep]` - Full organization scan
- `/repo:analyze <repo-name> [--sync]` - Single repository analysis
- `/repo:extract-patterns [--min-usage 3]` - Pattern mining
- `/repo:calculate-costs [--detailed]` - Portfolio cost analysis

### Viability Scoring Algorithm

```
Total Score (0-100) = Test Coverage + Activity + Documentation + Dependencies

Test Coverage (0-30 points):
  - 70%+ coverage: 30 points
  - Tests exist: 10+ points scaled by coverage
  - No tests: 0 points

Activity (0-20 points):
  - Commits last 30 days: 20 points
  - Commits last 90 days: 10 points
  - No recent commits: 0 points

Documentation (0-25 points):
  - README + docs + active: 25 points
  - README exists: 15 points
  - No README: 0 points

Dependency Health (0-25 points):
  - 0-10 dependencies: 25 points
  - 11-30 dependencies: 15 points
  - 31+ dependencies: 5 points

Ratings:
  - HIGH (75-100): Production-ready, well-maintained
  - MEDIUM (50-74): Functional but needs work
  - LOW (0-49): Reference only or abandoned
```

### Reusability Assessment

```
Highly Reusable:
  ✓ Viability ≥ 75
  ✓ Has tests
  ✓ Has documentation
  ✓ Not a fork
  ✓ Active (pushed within 90 days)

Partially Reusable:
  ✓ Viability ≥ 50
  ✓ Has tests OR documentation

One-Off:
  All other cases
```

### Claude Integration Detection

**Maturity Levels:**
- **EXPERT (80-100)**: Comprehensive agents, commands, MCP servers, project memory
- **ADVANCED (60-79)**: Multiple agents/commands, some MCP servers
- **INTERMEDIATE (30-59)**: Basic agents or commands
- **BASIC (10-29)**: Minimal .claude/ directory
- **NONE (0-9)**: No meaningful integration

**Scoring Formula:**
```
Score = (agents_count × 10) + (commands_count × 5) + (mcp_servers × 10) + (has_claude_md × 15)
```

### Notion Integration Workflow

**Example Builds Database** (`a1cd1528-971d-4873-a176-5e93b93555f6`):
1. Search for existing build by repository name
2. Create or update entry with:
   - Repository URL and description
   - Viability score and rating
   - Reusability assessment
   - Claude maturity level
   - GitHub statistics (stars, forks, issues)
   - Status (Active if pushed within 90 days)

**Software & Cost Tracker** (`13b5e9de-2dd1-45ec-839a-4f3d50cd8d06`):
1. Extract dependencies from package manifests
2. Search Software Tracker for each dependency
3. Create new entries if not found (with costs from database)
4. Link Software → Build relations
5. Verify cost rollup calculation

**Knowledge Vault**:
1. Create pattern library entries for reusable architectural patterns
2. Document usage statistics and reusability scores
3. Link to example repositories

### Usage Examples

**Full Organization Scan:**
```bash
cd brookside-repo-analyzer/
poetry run brookside-analyze scan --full --sync
```

**Single Repository Analysis:**
```bash
poetry run brookside-analyze analyze repo-analyzer --deep --sync
```

**Pattern Extraction:**
```bash
poetry run brookside-analyze patterns --min-usage 3 --sync
```

**Cost Analysis:**
```bash
poetry run brookside-analyze costs --detailed
```

**Using Slash Commands:**
```bash
# In Claude Code with Notion repository context
/repo:scan-org --sync --deep
/repo:analyze brookside-cost-tracker --sync
/repo:extract-patterns --sync
/repo:calculate-costs --detailed
```

### Deployment Modes

**1. Local CLI** (Current)
- On-demand execution via Poetry
- Manual Azure CLI authentication
- Development and testing

**2. Azure Function** (Planned)
- Weekly scheduled scans (Sunday midnight UTC)
- Managed Identity for credentials
- Automatic Notion sync
- Application Insights monitoring

**3. GitHub Actions** (Configured)
- Event-triggered analysis on repository changes
- CI/CD quality checks on PRs
- Automated deployment to Azure

### Cost Structure

**Monthly Operating Costs:**
- Azure Functions (Consumption): ~$5
- Azure Storage (caching): ~$2
- **Total**: ~$7/month

**Existing Infrastructure** (no additional cost):
- Azure Key Vault
- GitHub Enterprise
- Notion API

### Key Files and Documentation

**For Developers:**
- `README.md` - Quick start and usage guide
- `ARCHITECTURE.md` - System design and data models
- `API.md` - CLI/Python SDK/HTTP API reference
- `CONTRIBUTING.md` - Development standards and workflows

**For Deployment:**
- `deployment/azure_function/README.md` - Azure Function setup guide
- `deployment/github_actions/` - CI/CD workflow configurations
- `.pre-commit-config.yaml` - Code quality automation

**For Configuration:**
- `.env.example` - Environment variable template
- `pyproject.toml` - Poetry dependencies and settings
- `src/data/cost_database.json` - Dependency cost mappings (to be created)

### Integration with Parent Repository

The repository analyzer is a **subdirectory project** within the main Notion Innovation Nexus repository. All Claude Code integration (agents, commands, MCP configuration) resides in the **parent `.claude/`** directory, not in `brookside-repo-analyzer/.claude/`.

**This design ensures:**
- Single source of truth for Claude Code configuration
- Shared agents across all Innovation Nexus tools
- Consistent Notion MCP integration
- Unified credential management via parent Azure Key Vault setup

### Best Practices

1. **Run Weekly**: Schedule Sunday scans to track portfolio evolution over time
2. **Review Results**: Check Notion Example Builds for new/updated repository entries
3. **Cost Monitoring**: Track total monthly cost trends, identify optimization opportunities
4. **Pattern Adoption**: Encourage reuse of high-scoring patterns (90+ reusability)
5. **Claude Integration**: Promote Agent/MCP adoption to reach Expert maturity level
6. **Viability Tracking**: Monitor and improve low-viability repositories quarterly
7. **Microsoft-First**: Prioritize Microsoft service alternatives when optimizing costs

**Brookside BI Innovation Nexus - Where Ideas Become Examples, and Examples Become Knowledge - Secured by Azure.**
