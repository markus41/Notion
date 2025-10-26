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

# Documentation Management
/docs:update-complex <scope> <description> [flags]  # Multi-file docs with diagrams & PR

# Output Styles & Testing
/test-agent-style <agent> <style|?> [--ultrathink]  # Test agent+style effectiveness
/style:compare <agent> "<task>" [--ultrathink]      # Side-by-side comparison
/style:report [--agent=name] [--timeframe=30d]      # Performance analytics

# Team Coordination
/team:assign [work-description] [database]   # Route work by specialization
```

### Core Agents

| Agent | Use Case | Trigger |
|-------|----------|---------|
| `@ideas-capture` | New innovation opportunities | "idea", "concept", "we should build" |
| `@research-coordinator` | Feasibility investigations | "research", "investigate", "feasibility" |
| `@build-architect` | Technical architecture & docs | "build", "prototype", "POC" |
| `@cost-analyst` | Software spend optimization | "costs", "spending", "budget" |
| `@knowledge-curator` | Archive learnings | Build completes or "document learnings" |
| `@archive-manager` | Complete work lifecycle | "archive", "done with", "complete" |

**→ Full Directory**: [38 specialized agents](.claude/agents/) including autonomous pipeline, research swarm, and output styles

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

## Core Database IDs (Essential Reference)

```bash
💡 Ideas Registry        → 984a4038-3e45-4a98-8df4-fd64dd8a1032
�� Research Hub          → 91e8beff-af94-4614-90b9-3a6d3d788d4a
🛠️ Example Builds        → a1cd1528-971d-4873-a176-5e93b93555f6
💰 Software & Cost       → 13b5e9de-2dd1-45ec-839a-4f3d50cd8d06
📚 Knowledge Vault       → (Query programmatically)
🔗 Integration Registry  → (Query programmatically)
🤖 Agent Registry        → 5863265b-eeee-45fc-ab1a-4206d8a523c6
🤖 Agent Activity Hub    → 7163aa38-f3d9-444b-9674-bde61868bd2b
🎨 Output Styles Registry → 199a7a80-224c-470b-9c64-7560ea51b257
🧪 Agent Style Tests     → b109b417-2e3f-4eba-bab1-9d4c047a65c4
```

**Workspace ID**: `81686779-099a-8195-b49e-00037e25c23e`

---

## Critical Rules

### ❌ NEVER Do This

- Create without searching for duplicates first
- Skip linking software/tools to builds/research/ideas
- Ignore cost rollups - always verify Software Tracker relations
- Use timeline language ("due date", "week 1", "by Friday")
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
- Structure technical docs for AI-agent execution
- Check Microsoft ecosystem first (M365 → Azure → Power Platform → GitHub)
- Apply Brookside BI brand voice to all outputs

---

## Agent Activity Logging Requirements

### Automatic Logging (Hook-Based) ✅

**Status**: Fully operational - Phase 4 autonomous infrastructure

The system automatically captures agent work through a PowerShell hook that triggers on every Task tool invocation (agent delegation). This hook-based approach establishes comprehensive activity tracking with zero manual overhead for standard agent operations.

**What's Automatically Logged**:
- Session start timestamps
- Agent identification (subagent_type from Task tool)
- Work description (from task parameters)
- Files created/updated (categorized by type)
- Lines generated (estimated from file sizes)
- Session duration (start to completion)
- Related Notion items (Ideas, Research, Builds)
- Deliverables (organized by category)

**Auto-Logging Criteria** (only logs when ALL conditions met):
- ✅ Agent in approved list (38 specialized agents)
- ✅ Work duration >2 minutes OR files created/updated
- ✅ Not already logged in current session (5-minute deduplication)
- ✅ TodoWrite shows meaningful work completion

**3-Tier Update System**:
1. **Markdown Log**: [.claude/logs/AGENT_ACTIVITY_LOG.md](.claude/logs/AGENT_ACTIVITY_LOG.md)
2. **JSON State**: [.claude/data/agent-state.json](.claude/data/agent-state.json)
3. **Notion Database**: Agent Activity Hub (Data Source: `7163aa38-f3d9-444b-9674-bde61868bd2b`)

**No action required from agents for standard work** - the hook handles session tracking automatically.

### Manual Logging (When Agents MUST Use `/agent:log-activity`)

Agents should explicitly invoke the `/agent:log-activity` command for **special events** that require human visibility or workflow coordination:

**1. Work Handoffs** 🔄
```bash
# When transferring work to another agent or team member
/agent:log-activity @current-agent handed-off "Transferring cost analysis to @cost-analyst - technical feasibility complete, financial analysis needed. See Research Hub entry R-2025-10-26-001 for context."
```

**2. Blockers Encountered** 🚧
```bash
# When progress is blocked and requires external input
/agent:log-activity @build-architect blocked "Azure subscription quota limit reached for F1 App Service plans. Need subscription owner to request quota increase before deployment can proceed."
```

**3. Critical Milestones** 🎯
```bash
# When reaching significant progress points requiring stakeholder awareness
/agent:log-activity @deployment-orchestrator completed "Production deployment successful - Application live at https://app.example.com. Zero-downtime migration completed, all health checks passing."
```

**4. Session Completion with Key Decisions** ✅
```bash
# When finishing work that involved important architectural or strategic decisions
/agent:log-activity @viability-assessor completed "Viability assessment complete: 87/100 (High). Recommend immediate build approval. Key decision: Selected Azure Functions over Container Apps due to cost efficiency ($12/month vs $78/month for expected load)."
```

**5. Early Termination** ⏹️
```bash
# When stopping work before completion due to user request or discovered issues
/agent:log-activity @research-coordinator blocked "Research halted - discovered existing Microsoft solution (Power BI Deployment Pipelines) that fully addresses requirement. Recommend archiving idea as duplicate."
```

### Decision Tree: Automatic vs. Manual

```
Agent completes delegated task
    ↓
Is this a STANDARD work completion?
    ├─ YES (99% of cases) → Let automatic hook handle logging
    │                       ✓ Hook captures session data
    │                       ✓ Updates all 3 tiers
    │                       ✓ Zero manual effort
    │
    └─ NO (special event) → Does it involve...?
        ├─ Handoff to another agent/person? → Use /agent:log-activity
        ├─ Blocker requiring external help? → Use /agent:log-activity
        ├─ Critical milestone needing visibility? → Use /agent:log-activity
        ├─ Key decision requiring documentation? → Use /agent:log-activity
        └─ Early termination/scope change? → Use /agent:log-activity
```

### Command Format

```bash
/agent:log-activity <agent-name> <status> "<detailed-description>"

# Status values:
#   - completed:  Work finished successfully
#   - blocked:    Waiting for external input/dependency
#   - handed-off: Transferred to another agent/team member
#   - in-progress: Milestone update while work continues

# Examples:
/agent:log-activity @cost-analyst completed "Quarterly analysis complete - identified $450/month savings opportunity through Microsoft consolidation. See Software Tracker for recommendations."

/agent:log-activity @build-architect handed-off "Architecture complete, transferring to @code-generator for implementation. ADR-2025-10-26-Azure-Functions documents all decisions."

/agent:log-activity @deployment-orchestrator blocked "Bicep validation failed - Microsoft.Web/sites API version 2023-01-01 not supported in target region (West Europe). Need to update template or change region."
```

### Best Practices for Manual Logging

**✅ DO**:
- Provide specific, actionable details (not just "work complete")
- Include file paths, URLs, or Notion page links for context
- Document decisions and rationale (especially cost/architecture choices)
- Mention handoff recipient by name/agent (@recipient)
- Explain blockers clearly with specific resolution requirements

**❌ DON'T**:
- Log routine work that automatic hook already captures
- Use vague descriptions ("made progress", "worked on stuff")
- Skip logging handoffs (causes workflow breaks)
- Forget to update status when blockers are resolved
- Log without including next steps or required actions

### Troubleshooting

**If automatic logging isn't working**:
1. Verify hook configuration in [.claude/settings.local.json](.claude/settings.local.json)
2. Check hook execution log: [.claude/logs/auto-activity-hook.log](.claude/logs/auto-activity-hook.log)
3. Confirm agent is in approved list (see hook script line 58-86)
4. Verify Notion database access permissions

**If Notion tier is queued but not syncing**:
- ✅ **Status**: Notion API integration implemented with full retry logic and error handling
- ⚠️ **Action Required**: Share Agent Activity Hub database with your Notion integration
- 📋 **Queue Location**: [.claude/data/notion-sync-queue.jsonl](.claude/data/notion-sync-queue.jsonl)
- 🔧 **Processor Script**: [.claude/utils/process-notion-queue.ps1](.claude/utils/process-notion-queue.ps1)
- **Database IDs Verified**:
  - Database (page) ID: `72b879f2-13bd-4edb-9c59-b43089dbef21` ✓ Correct
  - Data Source (collection) ID: `7163aa38-f3d9-444b-9674-bde61868bd2b` ✓ Correct

**Setup Steps** (One-time configuration):
1. Open [Agent Activity Hub](https://www.notion.so/72b879f213bd4edb9c59b43089dbef21) in Notion
2. Click "..." menu → "Connections" → "Add connection"
3. Select your Notion integration (the one whose API token is stored in Key Vault as `notion-api-key`)
4. Grant access to the database
5. Test the processor: `.claude\utils\process-notion-queue.ps1`

**How to verify**:
```powershell
# Create test entry (simulates hook behavior)
echo '{"sessionId":"test-$(Get-Date -Format yyyyMMdd-HHmmss)","agentName":"@cost-analyst","status":"completed","workDescription":"Test entry","startTime":"2025-10-26T10:00:00Z","queuedAt":"2025-10-26T10:00:00Z","syncStatus":"pending","retryCount":0}' >> .claude\data\notion-sync-queue.jsonl

# Process queue (syncs to Notion)
.\.claude\utils\process-notion-queue.ps1

# Check results
# - Should show "Successfully processed: 1"
# - Entry should appear in Agent Activity Hub database
# - Queue file should be empty after successful sync
```

**→ Full Documentation**: [Agent Activity Center](.claude/docs/agent-activity-center.md)

---

## Quick Reference Cards

### Status Emojis
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
/cost:monthly-spend                    # Quick total
/cost:annual-projection                # Yearly forecast
/cost:top-expenses                     # Top 5 tools
/cost:microsoft-alternatives [tool]    # M365/Azure replacements
```

---

## Detailed Documentation (Modular Structure)

All comprehensive documentation has been organized into focused, modular files to optimize token usage while maintaining complete information access.

### Innovation & Workflow

**[Innovation Workflow](.claude/docs/innovation-workflow.md)** ⭐ Core
- Complete 4-phase lifecycle (Idea → Research → Build → Knowledge)
- Phase 3 autonomous build pipeline (40-60 min deployments)
- Research swarm coordination (4 parallel agents)
- Repository safety hooks and security patterns
- Decision matrices and integration points

**[Common Workflows](.claude/docs/common-workflows.md)** 🔄 Practical
- Step-by-step procedures for frequent operations
- Complete innovation lifecycle example
- Quarterly cost optimization workflow
- Repository portfolio analysis workflow
- Emergency research fast-track procedures
- Daily startup routines

### Notion & Data

**[Notion Schema](.claude/docs/notion-schema.md)** 📊 Database Architecture
- Complete database schemas with all properties
- Relation rules and rollup formulas
- Standard operations protocol (search-first)
- Query patterns and examples
- Validation checklists

### Azure & Infrastructure

**[Azure Infrastructure](.claude/docs/azure-infrastructure.md)** ☁️ Cloud Configuration
- Active subscription and tenant details
- Key Vault configuration and secret retrieval
- Security best practices and credential handling
- Cost optimization strategies
- Daily authentication workflow

**[MCP Configuration](.claude/docs/mcp-configuration.md)** 🔌 Integration Setup
- Active MCP servers (Notion, GitHub, Azure, Playwright)
- Authentication methods per server
- Environment setup procedures
- Connection verification and troubleshooting
- Performance optimization tips

### Team & Operations

**[Team Structure](.claude/docs/team-structure.md)** 👥 Team Coordination
- Team member specializations (5 members)
- Assignment routing logic and auto-assignment
- Collaboration patterns and handoff procedures
- Workload management and capacity planning

**[Agent Activity Center](.claude/docs/agent-activity-center.md)** 🤖 Activity Tracking
- 3-tier tracking system (Notion + Markdown + JSON)
- Automatic activity logging (Phase 4)
- Hook architecture and filtering rules
- Logging operations and status workflows
- Productivity analytics

### Configuration & Environment

**[Configuration & Environment](.claude/docs/configuration.md)** ⚙️ Setup
- Claude Code settings (settings.local.json)
- Environment variables (complete list)
- Repository hooks (pre-commit, commit-msg, tool-call)
- PowerShell scripts and utilities
- Daily startup routine

**[Microsoft Ecosystem](.claude/docs/microsoft-ecosystem.md)** 🏢 Microsoft-First
- Selection priority order (M365 → Azure → Power Platform → GitHub)
- Service comparison matrices
- Cost optimization benefits
- Integration patterns and decision framework

### Guidelines & Best Practices

**[Agent Guidelines](.claude/docs/agent-guidelines.md)** 📋 Agent Operations
- Core principles for agents
- Automated integration patterns
- Performance optimization (MCP usage)
- Security best practices
- Brookside BI brand voice application

**[Success Metrics](.claude/docs/success-metrics.md)** 📈 Measurement
- Innovation workflow success criteria
- Cost optimization KPIs
- Knowledge reuse metrics
- Team productivity indicators
- Security and compliance standards
- Quarterly review checklists

---

## Innovation Workflow (Quick Summary)

```
💡 Idea (Concept) → Viability Assessment
  ↓ (if Needs Research)
🔬 Research (Active) → 4-Agent Parallel Swarm → Viability Score (0-100)
  ↓ (if >85: Auto-Approve | 60-85: Review | <60: Archive)
🛠️ Build (Active) → Autonomous Pipeline (40-60 min) → Azure Deployment
  ↓ (when Complete)
📚 Knowledge Vault (Archived for Reference)
```

**Phase 3 Autonomous Build Pipeline** (Completed Oct 2025):
- 40-60 min from high-viability idea to deployed Azure application
- 3 specialized build agents (architecture, code, deployment)
- 87% cost savings via environment-based SKU selection
- Zero hardcoded secrets (Managed Identity + Key Vault)

**→ See [Innovation Workflow](.claude/docs/innovation-workflow.md) for complete architecture**

---

## Notion Operations (Quick Summary)

**ALWAYS follow search-first protocol:**
1. Search for existing content (avoid duplicates)
2. Fetch related items to understand structure
3. Check existing relations
4. Propose action to user
5. Execute with proper linking

**Key Relation Rules:**
- **Software Tracker = Central Hub**: All databases link TO Software Tracker (not from)
- **Ideas → Research → Builds → Knowledge**: Linear progression with links preserved
- **Every Build MUST link**: Origin Idea + Related Research (if exists) + ALL Software/Tools

**→ See [Notion Schema](.claude/docs/notion-schema.md) for complete database specifications**

---

## Azure & MCP (Quick Summary)

**Daily Workflow** (3-5 minutes):
```powershell
az login                                # Authenticate to Azure
.\scripts\Set-MCPEnvironment.ps1       # Configure MCP environment variables
.\scripts\Test-AzureMCP.ps1            # Verify connectivity (optional)
claude                                  # Launch Claude Code
```

**Key Vault**: `kv-brookside-secrets`
- All secrets centralized (GitHub PAT, Notion API, Azure OpenAI, webhook secret, APIM subscription key)
- Never hardcode credentials
- Use retrieval scripts: `.\scripts\Get-KeyVaultSecret.ps1`

**Webhook + APIM MCP** (Real-time agent activity tracking):
- **Webhook Endpoint**: `https://notion-webhook-brookside-prod.azurewebsites.net/api/NotionWebhook`
- **APIM Gateway**: `https://apim-brookside-innovation.azure-api.net`
- **MCP Server**: `azure-apim-innovation` (5th MCP server for AI agent API invocation)
- **Status**: 85% complete, [manual deployment steps](NEXT-STEPS-CHECKLIST.md) required
- **→ See [Webhook Architecture](.claude/docs/webhook-architecture.md) for design**
- **→ See [APIM MCP Configuration](.claude/docs/azure-apim-mcp-configuration.md) for setup**
- **→ See [Implementation Status](WEBHOOK-APIM-IMPLEMENTATION-STATUS.md) for detailed progress**

**→ See [Azure Infrastructure](.claude/docs/azure-infrastructure.md) for complete configuration**
**→ See [MCP Configuration](.claude/docs/mcp-configuration.md) for server setup**

---

## Team & Coordination (Quick Summary)

**Team Members**:
- **Markus Ahling**: Engineering, AI/ML, Infrastructure
- **Brad Wright**: Sales, Business Strategy, Finance
- **Stephan Densby**: Operations, Research, Process Optimization
- **Alec Fielding**: DevOps, Security, Integrations
- **Mitch Bisbee**: Data Engineering, ML, Quality Assurance

**Auto-Assignment**: `/team:assign [work-description] [database]`

**→ See [Team Structure](.claude/docs/team-structure.md) for complete specializations**
**→ See [Agent Activity Center](.claude/docs/agent-activity-center.md) for activity tracking**

---

## Microsoft Ecosystem Priority

**Selection Order** (ALWAYS check in this sequence):
1. **Microsoft 365 Suite** (Teams, SharePoint, OneDrive, etc.)
2. **Azure Services** (Functions, SQL, OpenAI, etc.)
3. **Power Platform** (Power BI, Power Apps, Power Automate)
4. **GitHub** (Repositories, Actions, Copilot)
5. **Third-party** (Only if Microsoft doesn't offer solution)

**→ See [Microsoft Ecosystem](.claude/docs/microsoft-ecosystem.md) for decision framework**

---

## Additional Resources

### Documentation Directories
- **Patterns**: [.claude/docs/patterns/](.claude/docs/patterns) - Circuit-breaker, Retry, Saga, Event Sourcing
- **Templates**: [.claude/templates/](.claude/templates) - ADR, Runbook, Research Entry
- **Agents**: [.claude/agents/](.claude/agents) - 38+ specialized agent specifications
- **Commands**: [.claude/commands/](.claude/commands) - All slash commands with usage examples
- **Styles**: [.claude/styles/](.claude/styles) - Output style definitions

### Scripts & Utilities
- **Get-KeyVaultSecret.ps1**: Retrieve individual secrets from Azure Key Vault
- **Set-MCPEnvironment.ps1**: Configure all MCP environment variables
- **Test-AzureMCP.ps1**: Validate Azure MCP server connectivity
- **session-parser.ps1**: Parse Claude session context
- **invoke-agent.ps1**: Manually invoke specialized agents
- **notion-queries.ps1**: Common Notion database queries

### Logs & State
- **Agent Activity Log**: [.claude/logs/AGENT_ACTIVITY_LOG.md](.claude/logs/AGENT_ACTIVITY_LOG.md)
- **Agent State JSON**: [.claude/data/agent-state.json](.claude/data/agent-state.json)
- **Notion Agent Activity Hub**: https://www.notion.so/72b879f213bd4edb9c59b43089dbef21

### Repository Analyzer
- **Quick Start**: [brookside-repo-analyzer/README.md](brookside-repo-analyzer/README.md)
- **Architecture**: [brookside-repo-analyzer/docs/ARCHITECTURE.md](brookside-repo-analyzer/docs/ARCHITECTURE.md)
- **API Reference**: [brookside-repo-analyzer/docs/API.md](brookside-repo-analyzer/docs/API.md)

---

## Success Indicators (At-a-Glance)

**You're driving measurable outcomes when:**
- ✅ Ideas progress through lifecycle without stalling
- ✅ Research swarm provides consistent viability scores (0-100)
- ✅ Autonomous builds deploy successfully >95% of time
- ✅ Knowledge is captured and reused (measurable pattern reuse)
- ✅ All software expenses tracked with accurate cost rollups
- ✅ Microsoft ecosystem leveraged effectively (check M365/Azure first)
- ✅ Security compliance maintained (zero credential leaks)
- ✅ Team members work within specializations >80% of time

**→ See [Success Metrics](.claude/docs/success-metrics.md) for complete measurement framework**

---

## Getting Help

**Documentation Issues**: Check modular docs in `.claude/docs/` for detailed information
**Command Help**: See `.claude/commands/` for slash command specifications
**Agent Questions**: Review `.claude/agents/` for agent capabilities
**Setup Issues**: Follow [Configuration & Environment](.claude/docs/configuration.md)
**Troubleshooting**: See relevant modular doc (Azure, MCP, Notion) for solutions

**Contact**: Consultations@BrooksideBI.com | +1 209 487 2047

---

**Brookside BI Innovation Nexus - Where Ideas Become Examples, and Examples Become Knowledge - Secured by Azure.**

**Last Updated**: 2025-10-26 | **Structure**: Modular (11 detailed documentation files)
