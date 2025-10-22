# CLAUDE.md

**Brookside BI Innovation Nexus** - Establish structured approaches for tracking ideas from concept through research, building, and knowledge archival. Designed for organizations scaling innovation workflows across teams using Notion as the central hub with Microsoft ecosystem integrations.

---

## Quick Start

### Essential Commands

```bash
# Innovation Lifecycle
/innovation:new-idea [description]           # Capture idea with viability assessment
/innovation:start-research [topic] [idea]    # Structure feasibility investigation
/autonomous:enable-idea [name]               # 40-60 min autonomous pipeline (research → deploy)

# Cost Management
/cost:analyze [all|active|unused|expiring]   # Comprehensive spend analysis
/cost:monthly-spend                          # Quick total
/cost:unused-software                        # Identify waste

# Repository Intelligence
/repo:scan-org [--sync] [--deep]            # Full GitHub portfolio analysis
/repo:analyze <repo> [--sync]                # Single repository assessment

# Knowledge & Archival
/knowledge:archive [item] [idea|research|build]  # Complete lifecycle with learnings

# Team Coordination
/team:assign [work-description] [database]   # Route work by specialization
```

### Core Agents

| Agent | Use Case | Trigger |
|-------|----------|---------|
| `@ideas-capture` | New innovation opportunities | User mentions "idea", "concept", "we should build" |
| `@research-coordinator` | Feasibility investigations | User mentions "research", "investigate", "feasibility" |
| `@build-architect` | Technical architecture & docs | User mentions "build", "prototype", "POC" |
| `@cost-analyst` | Software spend optimization | User asks about "costs", "spending", "budget" |
| `@knowledge-curator` | Archive learnings | Build completes or "document learnings" |
| `@archive-manager` | Complete work lifecycle | User says "archive", "done with", "complete" |

**Full Agent Directory**: [27+ specialized agents](.claude/agents/) including Phase 3 autonomous pipeline (build-architect-v2, code-generator, deployment-orchestrator) and research swarm (market-researcher, technical-analyst, cost-feasibility-analyst, risk-assessor).

---

## Brookside BI Brand Guidelines

### Voice & Tone
- **Professional but Approachable**: Corporate tone, accessible language
- **Solution-Focused**: Frame around business outcomes ("streamline workflows," "drive measurable outcomes")
- **Consultative & Strategic**: Emphasize sustainability and scalability

### Core Language Patterns
- "Establish structure and rules for..."
- "This solution is designed to..."
- "Organizations scaling [technology] across..."
- "Drive measurable outcomes through structured approaches"
- "Best for: [clear use case context]"

### Technical Content Standards

**Code Comments:**
```typescript
// ❌ Initialize database connection
// ✅ Establish scalable data access layer to support multi-team operations
```

**Commit Messages:**
```bash
# ❌ feat: add caching layer
# ✅ feat: Streamline data retrieval with distributed caching for improved performance
```

**Documentation:**
- Lead with benefit/outcome before technical details
- Include "Best for:" context qualifiers
- Structure for AI-agent execution (explicit, idempotent, no ambiguity)

**Contact**: Consultations@BrooksideBI.com | +1 209 487 2047

---

## Innovation Workflow Architecture

```
💡 Idea (Concept) → Viability Assessment
  ↓ (if Needs Research)
🔬 Research (Active) → 4-Agent Parallel Swarm → Viability Score (0-100)
  ↓ (if >85: Auto-Approve | 60-85: Review | <60: Archive)
🛠️ Build (Active) → Autonomous Pipeline (40-60 min) → Azure Deployment
  ↓ (when Complete)
📚 Knowledge Vault (Archived for Reference)
```

### Phase 3: Autonomous Build Pipeline

**Completed**: October 21, 2025

**Capabilities:**
- **End-to-End Execution**: 40-60 minutes from high-viability idea to deployed Azure application
- **3 Build Agents**: @build-architect-v2, @code-generator, @deployment-orchestrator (2,900+ lines)
- **Parallel Research Swarm**: 4 agents (market, technical, cost, risk) → 0-100 viability score
- **Infrastructure as Code**: Bicep templates (Python/TypeScript/C#) with zero-downtime CI/CD
- **Cost Optimization**: 87% reduction via environment-based SKU selection ($20 dev vs $157 prod)
- **Security**: Managed Identity, RBAC, zero hardcoded secrets

**Repository Safety Hooks:**
- 3-layer protection (pre-commit, commit-msg, branch-protection)
- 15+ secret detection patterns preventing credential leaks
- Conventional Commits enforcement with Brookside BI brand voice
- ROI: 500-667% through automated quality enforcement

---

## Notion Database Architecture

### Core Databases (Data Source IDs)

```bash
💡 Ideas Registry        → 984a4038-3e45-4a98-8df4-fd64dd8a1032
🔬 Research Hub          → 91e8beff-af94-4614-90b9-3a6d3d788d4a
🛠️ Example Builds        → a1cd1528-971d-4873-a176-5e93b93555f6
💰 Software & Cost       → 13b5e9de-2dd1-45ec-839a-4f3d50cd8d06
📚 Knowledge Vault       → (Query programmatically)
🔗 Integration Registry  → (Query programmatically)
🤖 Agent Registry        → 5863265b-eeee-45fc-ab1a-4206d8a523c6
🤖 Agent Activity Hub    → 7163aa38-f3d9-444b-9674-bde61868bd2b
🎯 OKRs & Initiatives    → (Query programmatically)
```

**Workspace ID**: `81686779-099a-8195-b49e-00037e25c23e`

### Standard Notion Operations Protocol

**ALWAYS follow this search-first protocol:**

```
1. Search for existing content (avoid duplicates)
2. Fetch related items to understand structure
3. Check existing relations
4. Propose action to user
5. Execute with proper linking
```

### Key Relation Rules

- **Software Tracker = Central Cost Hub**: All databases link TO Software Tracker (not from)
- **Ideas → Research → Builds → Knowledge**: Linear progression with links preserved
- **Every Build MUST link**: Origin Idea + Related Research (if exists) + All Software/Tools
- **Cost Rollups**: Total Cost = SUM(Software relations × License Count)

---

## Azure Infrastructure

### Active Configuration

```bash
# Azure Subscription
Subscription ID: cfacbbe8-a2a3-445f-a188-68b3b35f0c84
Tenant ID: 2930489e-9d8a-456b-9de9-e4787faeab9c

# Key Vault (Centralized Secrets)
Vault Name: kv-brookside-secrets
Vault URI: https://kv-brookside-secrets.vault.azure.net/

# Secrets Stored
github-personal-access-token    # GitHub PAT (repo, workflow, admin:org)
notion-api-key                  # Notion integration token
azure-openai-api-key           # Azure OpenAI service key
azure-openai-endpoint          # Azure OpenAI endpoint URL
```

### Secret Retrieval

```powershell
# Retrieve individual secret
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token"

# Configure all MCP environment variables
.\scripts\Set-MCPEnvironment.ps1 [-Persistent]

# Test Azure MCP connectivity
.\scripts\Test-AzureMCP.ps1
```

**Security Rule**: NEVER hardcode credentials. Always reference Key Vault or use retrieval scripts.

---

## MCP Server Configuration

### Active MCP Servers

| Server | Purpose | Authentication |
|--------|---------|---------------|
| **Notion** | Innovation tracking, database operations | OAuth (auto-configured) |
| **GitHub** | Repository operations, CI/CD | PAT from Key Vault |
| **Azure** | Cloud resource management, deployments | Azure CLI (`az login`) |
| **Playwright** | Browser automation, web testing | Local executable |

**Verify Connection**: `claude mcp list` (all should show ✓ Connected)

### Environment Setup (Daily Workflow)

```powershell
# 1. Authenticate to Azure
az login
az account show  # Verify authentication

# 2. Configure MCP environment variables
.\scripts\Set-MCPEnvironment.ps1

# 3. Launch Claude Code
claude
```

---

## Team Structure & Specializations

| Member | Focus Areas | Assign When |
|--------|-------------|-------------|
| **Markus Ahling** | Engineering, Operations, AI, Infrastructure | Technical architecture, AI/ML projects |
| **Brad Wright** | Sales, Business, Finance, Marketing | Business strategy, sales enablement |
| **Stephan Densby** | Operations, Continuous Improvement, Research | Process optimization, research coordination |
| **Alec Fielding** | DevOps, Engineering, Security, Integrations, R&D | Cloud infrastructure, security, integrations |
| **Mitch Bisbee** | DevOps, Engineering, ML, Master Data, Quality | Data engineering, ML pipelines, quality assurance |

**Auto-Assignment**: Use `/team:assign [work-description] [database]` for intelligent routing.

---

## Architectural Patterns & Templates

### Available Patterns ([.claude/docs/patterns/](.claude/docs/patterns))

1. **Circuit-Breaker** (12KB): Prevent cascading failures in Azure/GitHub/Notion MCP integrations
2. **Retry with Exponential Backoff** (18KB): Handle transient failures intelligently
3. **Saga Pattern** (15KB): Distributed transaction consistency across Notion + GitHub + Azure
4. **Event Sourcing** (27KB): Complete audit trails for compliance and temporal analysis

### Operational Templates ([.claude/templates/](.claude/templates))

1. **ADR Template**: Architecture Decision Records with cost analysis and Microsoft alignment
2. **Runbook Template**: Azure deployment procedures and incident response workflows
3. **Research Hub Entry Template**: Structured research with parallel agent findings

**Usage**: `cp .claude/templates/[template].md [destination]` then fill with agent assistance.

---

## Repository Analyzer (`brookside-repo-analyzer/`)

### Purpose
Automated GitHub portfolio analysis establishing comprehensive repository visibility through multi-dimensional viability scoring, Claude integration detection, and Notion synchronization.

### Key Capabilities
- **Viability Scoring**: 0-100 points (Test Coverage 30pts + Activity 20pts + Documentation 25pts + Dependencies 25pts)
- **Claude Maturity**: Expert | Advanced | Intermediate | Basic | None
- **Pattern Mining**: Extract reusable architectural patterns across repositories
- **Cost Analysis**: Dependency-based cost calculation with Microsoft alternatives
- **Notion Sync**: Auto-populate Example Builds + Software Tracker

### Usage
```bash
# Full organization scan with Notion sync
cd brookside-repo-analyzer/
poetry run brookside-analyze scan --full --sync

# Single repository deep analysis
poetry run brookside-analyze analyze <repo-name> --deep --sync

# Via slash commands (recommended)
/repo:scan-org --sync --deep
/repo:analyze <repo-name> --sync
```

**Deployment**: Azure Function (weekly Sunday scans) + GitHub Actions (PR quality checks)

---

## Critical Rules

### ❌ NEVER Do This

- Create without searching for duplicates first
- Skip linking software/tools to builds/research/ideas
- Ignore cost rollups - always verify Software Tracker relations
- Use timeline language ("due date", "week 1", "by Friday", "1-2 weeks")
- Hardcode secrets or credentials anywhere
- Suggest non-Microsoft solutions without checking Microsoft offerings first
- Archive without documenting lessons learned
- Create builds without linking origin ideas

### ✅ ALWAYS Do This

- Search before creating (every time)
- Link ALL software/tools used (central to cost tracking)
- Maintain status fields accurately (Status over timelines)
- Document viability assessments explicitly
- Track costs transparently with rollups
- Use consistent emojis: 🔵 Concept | 🟢 Active | ⚫ Not Active | ✅ Completed
- Structure technical docs for AI-agent execution (explicit, idempotent, versioned)
- Check Microsoft ecosystem first (M365 → Azure → Power Platform → GitHub → Third-party)
- Apply Brookside BI brand voice to all outputs

---

## Agent Activity Center

**Purpose**: Centralized tracking for Claude Code agent work to establish transparency and workflow continuity.

### 3-Tier Tracking

1. **Notion Database** (Primary): https://www.notion.so/72b879f213bd4edb9c59b43089dbef21
   - Data Source: `7163aa38-f3d9-444b-9674-bde61868bd2b`
   - Team-accessible source of truth with relations

2. **Markdown Log** (Reference): [.claude/logs/AGENT_ACTIVITY_LOG.md](.claude/logs/AGENT_ACTIVITY_LOG.md)
   - Human-readable chronological log

3. **JSON State** (Programmatic): [.claude/data/agent-state.json](.claude/data/agent-state.json)
   - Machine-readable for automation

### Logging Operations

```bash
# Primary method (recommended)
/agent:log-activity [agent-name] [status] [work-description]

# Generate activity reports
/agent:activity-summary [today|week|month|all] [agent-name]
```

**Status Workflow**: In Progress → Completed | Blocked | Handed Off

**Always Log**: Session start, blockers encountered, work completion, agent handoffs, significant milestones

### Automatic Activity Logging (Phase 4)

**Status**: Implemented October 22, 2025

**Purpose**: Eliminate manual logging overhead through intelligent hook-based automation that captures agent work when subagents complete their responses.

**Architecture**:
```
Task Tool Invocation (Agent Delegation)
    ↓
Hook Trigger (.claude/hooks/auto-log-agent-activity.ps1)
    ↓
Intelligent Filtering (duration >2min, files changed, approved agents)
    ↓
@activity-logger Agent (parse deliverables, calculate metrics)
    ↓
3-Tier Update (Notion + Markdown + JSON)
```

**Components**:
- **Hook Script**: [.claude/hooks/auto-log-agent-activity.ps1](.claude/hooks/auto-log-agent-activity.ps1) - PowerShell hook triggered on Task tool calls
- **Activity Logger Agent**: [@activity-logger](.claude/agents/activity-logger.md) - Specialized agent for intelligent data extraction
- **Session Parser**: [.claude/utils/session-parser.ps1](.claude/utils/session-parser.ps1) - Helper utility for context parsing
- **Hook Configuration**: [.claude/settings.local.json](.claude/settings.local.json) - Tool-call-hook enabled for Task tool

**Filtering Rules** (only log when):
- ✅ Agent in approved list (27+ specialized agents)
- ✅ Work duration >2 minutes OR files created/updated
- ✅ Not already logged in current session (5-minute deduplication window)
- ✅ TodoWrite shows meaningful work completion

**Auto-Captured Metrics**:
- Files created/updated (categorized by type: Code, Documentation, Infrastructure, Tests, Scripts)
- Lines generated (estimated from file sizes)
- Session duration (start to completion)
- Deliverables (organized by category with file paths)
- Related Notion items (Ideas, Research, Builds)
- Next steps (inferred from work context)

**Benefits**:
- **Zero Manual Overhead**: No need to remember to log agent work
- **Comprehensive Tracking**: Every significant agent session automatically recorded
- **Productivity Analytics**: Data-driven insights into agent utilization and performance
- **Workflow Continuity**: Seamless handoffs between team members with full context
- **Institutional Memory**: All agent work preserved for future reference

**Phase 2 Enhancements** (Planned):
- Machine learning-based duration prediction
- Anomaly detection for unusually long sessions
- Automated cost attribution to Azure resources
- Real-time activity dashboard
- Quality scoring for agent deliverables

---

## Microsoft Ecosystem Integration Priority

**Selection Order** (always check higher priority first):
1. **Microsoft 365 Suite**: Teams, SharePoint, OneNote, Outlook
2. **Azure Services**: Azure OpenAI, Functions, SQL, DevOps, App Services
3. **Power Platform**: Power BI, Power Automate, Power Apps
4. **GitHub**: Enterprise repositories, Actions, Projects
5. **Third-party**: Only if Microsoft doesn't offer solution

**Cost Optimization**: When suggesting tools, always query Software Tracker for existing Microsoft services that could fulfill the requirement.

---

## Common Workflows (Command-Focused)

### 1. Complete Innovation Lifecycle
```bash
/innovation:new-idea [description]                    # → Ideas Registry entry
  ↓ (if Viability = "Needs Research")
/innovation:start-research [topic] [idea-name]        # → Research Hub entry
  ↓ (Research swarm analyzes: market, technical, cost, risk)
  ↓ (Viability score >85: Auto-approve build)
/autonomous:enable-idea [idea-name]                   # → 40-60 min autonomous pipeline
  ↓ (Code generation + Azure deployment + CI/CD)
/knowledge:archive [build-name] build                 # → Knowledge Vault entry
```

### 2. Quarterly Cost Optimization
```bash
/cost:analyze all                      # Comprehensive spend analysis
/cost:unused-software                  # Identify waste ($0 utilization)
/cost:consolidation-opportunities      # Find duplicate tools
/cost:expiring-contracts               # Check renewals (60 days)
# Review results → Cancel/consolidate → Measure savings
```

### 3. Repository Portfolio Analysis
```bash
/repo:scan-org --sync --deep           # Full GitHub organization scan
  ↓ (Viability scoring + Claude detection + Pattern mining)
  ↓ (Auto-populate Example Builds + Software Tracker)
/repo:extract-patterns --sync          # Identify reusable patterns
/repo:calculate-costs --detailed       # Portfolio cost analysis
```

### 4. Emergency Research (Fast-Track)
```bash
/innovation:new-idea [urgent opportunity]
/innovation:start-research [topic] [idea-name]
  ↓ (Focus: 2-4 hour investigation)
  ↓ (Deliver: Key findings + Viability + Go/No-Go)
# Decision: Build immediately OR Archive with rationale
```

---

## Configuration & Environment

### Claude Code Settings

**Recommended**: Create `.claude/settings.local.json` (git-ignored):

```json
{
  "model": "claude-sonnet-4-5-20250929",
  "cleanupPeriodDays": 90,
  "includeCoAuthoredBy": true,
  "hooks": {
    "Notification": [{"hooks": [{"type": "command", "command": "echo -e '\\a'"}]}],
    "Stop": [{"hooks": [{"type": "command", "command": "echo -e '\\a'"}]}]
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

**Benefits**: Terminal bell notifications, extended chat history, pre-approved MCP commands.

### Environment Variables

```bash
# Azure
AZURE_TENANT_ID=2930489e-9d8a-456b-9de9-e4787faeab9c
AZURE_SUBSCRIPTION_ID=cfacbbe8-a2a3-445f-a188-68b3b35f0c84
AZURE_KEYVAULT_NAME=kv-brookside-secrets

# GitHub
GITHUB_ORG=brookside-bi
GITHUB_PERSONAL_ACCESS_TOKEN=[From Key Vault]

# Notion
NOTION_WORKSPACE_ID=81686779-099a-8195-b49e-00037e25c23e
```

**Auto-Configure**: `.\scripts\Set-MCPEnvironment.ps1`

---

## Quick Reference Cards

### Status Emojis (Consistent Usage)
- 🔵 **Concept** - Initial idea capture
- 🟢 **Active** - Currently working
- ⚫ **Not Active** - Paused/on-hold
- ✅ **Completed/Archived** - Finished work

### Viability Emojis
- 💎 **High** - Production ready (75-100)
- ⚡ **Medium** - Needs work (50-74)
- 🔻 **Low** - Reference only (0-49)
- ❓ **Needs Research** - Insufficient data

### Database Formatting
- Ideas: `💡 [Idea Name]`
- Research: `🔬 [Research Topic]`
- Builds: `🛠️ [Build Name]`
- Knowledge: `📚 [Article Name]`

### Cost Analysis Shortcuts
```bash
/cost:monthly-spend                    # Quick total: $X,XXX/month
/cost:annual-projection                # Yearly forecast: $XX,XXX
/cost:top-expenses                     # Top 5 most expensive tools
/cost:microsoft-alternatives [tool]    # Find M365/Azure replacements
/cost:build-costs [build-name]         # Specific build cost breakdown
```

---

## Notes for Claude Code Agents

### Core Principles
- **Notion = Source of Truth**: All innovation tracking lives here
- **Azure Key Vault = Secret Hub**: All credentials centralized, never hardcoded
- **Cost Tracking = Critical**: Every build/research MUST link software
- **Microsoft-First**: Always check M365 → Azure → Power Platform → GitHub before third-party
- **Status > Timelines**: Focus on viability and progress, not deadlines
- **Archive Liberally**: Every completed build becomes reference material
- **AI-Agent Friendly**: All docs must be executable by future AI agents without human interpretation

### Automated Integration Patterns

**When creating Example Builds:**
1. Create GitHub repo (via GitHub MCP)
2. Link repo URL to Notion Build entry
3. Track ALL software/tools (link to Software Tracker for cost rollup)
4. Generate AI-agent-friendly technical docs (@markdown-expert)
5. Deploy to Azure if needed (via Azure MCP)
6. Register in Integration Registry

**When starting Research:**
1. Create Research Hub entry (via Notion MCP)
2. Link to originating Idea (required)
3. Track research tools in Software Tracker
4. Invoke research swarm: @market-researcher, @technical-analyst, @cost-feasibility-analyst, @risk-assessor
5. Document findings for Knowledge Vault archival

**When managing costs:**
1. Query Software Tracker via Notion MCP
2. Calculate rollups from database relations
3. Identify unused tools (Status = Active, no relations to Ideas/Research/Builds)
4. Check contract expiration dates (within 60 days)
5. Suggest Microsoft alternatives via `/cost:microsoft-alternatives`

### Performance Optimization

**MCP Server Usage:**
- **Notion MCP**: Cache database schemas, reuse queries to minimize API calls
- **GitHub MCP**: Batch file operations when creating/updating multiple files
- **Azure MCP**: Verify `az account show` before operations to avoid auth errors
- **Playwright MCP**: Reuse browser sessions for multi-step testing workflows

### Security Best Practices

**Credential Handling:**
- ✓ Use `scripts/Get-KeyVaultSecret.ps1` to retrieve secrets
- ✓ Reference Key Vault in docs: "Secret stored in Key Vault: kv-brookside-secrets"
- ✓ Use environment variables from `Set-MCPEnvironment.ps1`
- ✗ NEVER display actual secret values in output
- ✗ NEVER commit secrets to Git
- ✗ NEVER hardcode credentials in code/docs

**Azure Deployments:**
- ✓ Use Managed Identity when possible
- ✓ Store app secrets in Key Vault, reference in App Service configuration
- ✓ Document resource IDs and SKUs for cost tracking
- ✗ NEVER use connection strings in code

---

## Success Metrics

**You're driving measurable outcomes when:**
- ✅ Users find existing work quickly (no duplicate Ideas/Research/Builds)
- ✅ All work has explicit viability assessments (High/Medium/Low/Needs Research)
- ✅ Software costs are transparent with accurate rollups
- ✅ Knowledge is captured in Knowledge Vault (not lost in Slack/email)
- ✅ Database relations are properly maintained (Ideas → Research → Builds → Knowledge)
- ✅ Microsoft ecosystem is leveraged effectively (check M365/Azure before third-party)
- ✅ Cost optimization opportunities are identified proactively
- ✅ Technical documentation enables AI-agent deployment without human intervention
- ✅ Builds can be deployed autonomously via `/autonomous:enable-idea` (40-60 min)
- ✅ Team members work within their specializations (optimal productivity)

---

## Additional Resources

### Documentation
- **Patterns**: [.claude/docs/patterns/](.claude/docs/patterns) - Circuit-breaker, Retry, Saga, Event Sourcing
- **Templates**: [.claude/templates/](.claude/templates) - ADR, Runbook, Research Entry
- **Agents**: [.claude/agents/](.claude/agents) - 27+ specialized agents with full specifications
- **Commands**: [.claude/commands/](.claude/commands) - All slash commands with usage examples

### Scripts
- **Get-KeyVaultSecret.ps1**: Retrieve individual secrets from Azure Key Vault
- **Set-MCPEnvironment.ps1**: Configure all MCP environment variables
- **Test-AzureMCP.ps1**: Validate Azure MCP server connectivity

### Logs & State
- **Agent Activity Log**: [.claude/logs/AGENT_ACTIVITY_LOG.md](.claude/logs/AGENT_ACTIVITY_LOG.md)
- **Agent State JSON**: [.claude/data/agent-state.json](.claude/data/agent-state.json)
- **Notion Agent Activity Hub**: https://www.notion.so/72b879f213bd4edb9c59b43089dbef21

### Repository Analyzer
- **Quick Start**: [brookside-repo-analyzer/README.md](brookside-repo-analyzer/README.md)
- **Architecture**: [brookside-repo-analyzer/docs/ARCHITECTURE.md](brookside-repo-analyzer/docs/ARCHITECTURE.md)
- **API Reference**: [brookside-repo-analyzer/docs/API.md](brookside-repo-analyzer/docs/API.md)

---

**Brookside BI Innovation Nexus - Where Ideas Become Examples, and Examples Become Knowledge - Secured by Azure.**
