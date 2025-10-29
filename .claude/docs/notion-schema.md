# Notion Database Architecture

**Purpose**: Establish comprehensive understanding of Innovation Nexus database structures, relations, and operational patterns.

**Best for**: Agents performing Notion operations requiring precise schema knowledge and relation management.

---

## Core Databases (Data Source IDs)

| Database | Data Source ID | Purpose |
|----------|---------------|---------|
| 💡 **Ideas Registry** | `984a4038-3e45-4a98-8df4-fd64dd8a1032` | Innovation opportunity tracking |
| 🔬 **Research Hub** | `91e8beff-af94-4614-90b9-3a6d3d788d4a` | Feasibility investigation management |
| 🛠️ **Example Builds** | `a1cd1528-971d-4873-a176-5e93b93555f6` | Technical prototype and application tracking |
| 💰 **Software & Cost Tracker** | `13b5e9de-2dd1-45ec-839a-4f3d50cd8d06` | Centralized software expense management |
| 📚 **Knowledge Vault** | Query programmatically | Archived learnings and reference documentation |
| 🔗 **Integration Registry** | Query programmatically | External system integrations and connectors |
| 📦 **Projects** | `9f75999b-62d2-4c78-943e-c3e0debccfcd` | Active development project tracking with GitHub integration |
| ⚡ **Actions Registry** | `9d5a1db0-585f-4f5b-b2bb-a41f875a7de4` | META database tracking all slash commands and automation |
| 📊 **Data Sources** | `092940f4-1e6d-4321-b06a-1c0a9ee79445` | Client data infrastructure and connection health monitoring |
| 🤖 **Agent Registry** | `5863265b-eeee-45fc-ab1a-4206d8a523c6` | Claude Code agent specifications |
| 🤖 **Agent Activity Hub** | `7163aa38-f3d9-444b-9674-bde61868bd2b` | Agent work tracking and productivity analytics |
| 🎨 **Output Styles Registry** | `199a7a80-224c-470b-9c64-7560ea51b257` | Communication style definitions |
| 🧪 **Agent Style Tests** | `b109b417-2e3f-4eba-bab1-9d4c047a65c4` | Style effectiveness testing and analytics |
| 🎨 **Mermaid Diagram Registry** | `7169c29d-ca42-49a7-a867-0a110ee89532` | Centralized tracking of all Mermaid diagrams across GitHub and Notion |
| 🎯 **OKRs & Initiatives** | Query programmatically | Organizational objectives and key results |

**Workspace ID**: `81686779-099a-8195-b49e-00037e25c23e`

---

## Standard Operations Protocol

**ALWAYS follow this sequence to prevent duplicates and maintain data integrity:**

```
1. Search for existing content (use notion-search tool)
2. Fetch related items to understand structure (use notion-fetch tool)
3. Check existing relations (verify links before creating)
4. Propose action to user (describe what will be created/updated)
5. Execute with proper linking (create with all required relations)
```

**Example Protocol**:
```bash
# Step 1: Search
notion-search "AI cost optimization" type=internal

# Step 2: Fetch related
notion-fetch [idea-id-from-search]

# Step 3: Check relations
# Review existing Research/Builds linked to idea

# Step 4: Propose
"I'll create a new Research Hub entry for AI cost optimization feasibility,
linking to the existing Idea (ID: abc123) and tracking Azure OpenAI and
Power BI software costs."

# Step 5: Execute
notion-create-pages parent={data_source_id: "91e8beff..."}
  properties={
    "Research Topic": "AI cost optimization feasibility",
    "Origin Idea": [relation to abc123],
    "Software Used": [relation to Azure OpenAI, Power BI]
  }
```

---

## Database Schemas

### Ideas Registry

**Data Source ID**: `984a4038-3e45-4a98-8df4-fd64dd8a1032`

**Core Properties**:
```yaml
Idea Name: Title (required)
Status: Select (🔵 Concept | 🟢 Active | ⚫ Not Active | ✅ Completed)
Viability: Select (💎 High | ⚡ Medium | 🔻 Low | ❓ Needs Research)
Description: Text (rich text, problem statement + proposed solution)
Champion: Person (team member assigned)
Business Value: Text (expected outcomes and benefits)
Estimated Cost: Number (monthly recurring cost estimate)
Created Date: Date (auto-populated)
Last Updated: Date (auto-updated)
Tags: Multi-select (Technology, Process, Tool, Integration, etc.)

# Relations (outbound)
Related Research: Relation → Research Hub
Related Builds: Relation → Example Builds
Software Needed: Relation → Software & Cost Tracker
Related OKRs: Relation → OKRs & Initiatives

# Rollups
Total Research Count: Rollup (count Related Research)
Total Build Count: Rollup (count Related Builds)
Total Software Cost: Rollup (sum Software Needed.Monthly Cost)
```

**Formatting Standard**: `💡 [Idea Name]`

---

### Research Hub

**Data Source ID**: `91e8beff-af94-4614-90b9-3a6d3d788d4a`

**Core Properties**:
```yaml
Research Topic: Title (required)
Status: Select (🟢 Active | ⚫ Paused | ✅ Completed | ❌ Abandoned)
Research Type: Select (Technical Spike | Market Analysis | Feasibility Study | Competitive Analysis)
Hypothesis: Text (what we're trying to validate)
Methodology: Text (how we'll conduct the research)
Key Findings: Text (major discoveries and insights)
Viability Score: Number 0-100 (aggregate from research swarm)
  - Market Viability: Number 0-100
  - Technical Feasibility: Number 0-100
  - Cost Viability: Number 0-100
  - Risk Score: Number 0-100 (inverse: low risk = high score)
Next Steps: Select (Build Example | More Research | Archive)
Start Date: Date
Completion Date: Date
Duration: Formula (Completion Date - Start Date)

# Relations (required)
Origin Idea: Relation → Ideas Registry (required)
Software Used: Relation → Software & Cost Tracker
Related Builds: Relation → Example Builds (if research leads to build)
Assigned Researchers: Person (multi-select)

# Rollups
Idea Name: Rollup (Origin Idea.Idea Name)
Idea Champion: Rollup (Origin Idea.Champion)
Research Cost: Rollup (sum Software Used.Monthly Cost)
```

**Formatting Standard**: `🔬 [Research Topic]`

**Critical Rule**: Every Research Hub entry MUST link to an Origin Idea.

---

### Example Builds

**Data Source ID**: `a1cd1528-971d-4873-a176-5e93b93555f6`

**Core Properties**:
```yaml
Build Name: Title (required)
Status: Select (🟢 Active | ⚫ Not Active | ✅ Completed | 🔴 Failed)
Build Type: Select (POC | Prototype | MVP | Production | Demo)
Description: Text (what the build does and why it's valuable)
Technical Stack: Multi-select (Python, TypeScript, C#, Azure Functions, etc.)
Repository URL: URL (GitHub repo link)
Deployment URL: URL (live application URL if deployed)
Architecture: Text (system design and components)
Key Features: Text (bulleted list of capabilities)
Deployment Status: Select (Not Deployed | Deployed - Dev | Deployed - Prod)
Start Date: Date
Completion Date: Date
Duration: Formula (Completion Date - Start Date)

# Relations (required)
Origin Idea: Relation → Ideas Registry (required)
Related Research: Relation → Research Hub (if research preceded build)
Software & Tools: Relation → Software & Cost Tracker (required - all tools used)
Integrations: Relation → Integration Registry (external system connections)
Contributors: Person (multi-select, team members involved)

# Rollups
Idea Champion: Rollup (Origin Idea.Champion)
Research Findings: Rollup (Related Research.Key Findings)
Total Build Cost: Rollup (sum Software & Tools.Monthly Cost)
Monthly Recurring Cost: Number (calculated from rollup)
```

**Formatting Standard**: `🛠️ [Build Name]`

**Critical Rules**:
- Every Build MUST link to Origin Idea
- Every Build MUST link to ALL Software & Tools (for cost rollup)
- If Research preceded build, link to Related Research (preserve lineage)

---

### Software & Cost Tracker

**Data Source ID**: `13b5e9de-2dd1-45ec-839a-4f3d50cd8d06`

**Purpose**: Central hub for all software expense tracking. All other databases link TO this database (not from).

**Core Properties**:
```yaml
Software Name: Title (required)
Category: Select (Development Tools | BI & Analytics | Cloud Services | Collaboration | Security | Database | AI/ML | Other)
Vendor: Text (Microsoft, GitHub, Atlassian, etc.)
Monthly Cost per License: Number (base cost per user/unit)
License Count: Number (total licenses owned)
Total Monthly Cost: Formula (Monthly Cost per License × License Count)
Annual Cost: Formula (Total Monthly Cost × 12)
Contract Start Date: Date
Contract End Date: Date
Days Until Renewal: Formula (Contract End Date - Today)
Renewal Status: Formula (if Days Until Renewal <60, "⚠️ Expiring Soon", "✅ Active")
Status: Select (Active | Inactive | Trial | Expired)
Microsoft Alternative: Text (if applicable - e.g., "Azure DevOps" instead of "GitLab")
License Type: Select (Per User | Per Resource | Flat Rate | Usage-Based)
Billing Frequency: Select (Monthly | Annual | Pay-as-you-go)
Primary Contact: Person (who manages this software)
Documentation URL: URL (vendor docs or internal wiki)
Notes: Text (special terms, restrictions, considerations)

# Relations (inbound - all point TO Software Tracker)
Used in Ideas: Relation ← Ideas Registry.Software Needed
Used in Research: Relation ← Research Hub.Software Used
Used in Builds: Relation ← Example Builds.Software & Tools

# Rollups
Total Ideas Using: Rollup (count Used in Ideas)
Total Research Using: Rollup (count Used in Research)
Total Builds Using: Rollup (count Used in Builds)
Total Usage Count: Formula (sum of above rollups)
Utilization Status: Formula (if Total Usage Count = 0 AND Status = Active, "⚠️ Unused", "✅ In Use")
```

**Critical Rules**:
- Software Tracker is the ONLY database that tracks costs
- All other databases link TO Software Tracker (never from)
- Every Idea/Research/Build must link ALL tools used (for accurate rollups)
- Monthly Cost per License × License Count = Total Monthly Cost (formula enforced)

---

### Knowledge Vault

**Purpose**: Archived learnings, technical documentation, case studies, processes, and tutorials for reference and reuse.

**Query**: Use `notion-search query="..." data_source_url="..."` or filter by Content Type

**Core Properties**:
```yaml
Title: Title (required)
Content Type: Select (Technical Doc | Case Study | Post-Mortem | Process | Tutorial | Reference)
Description: Text (summary of what's documented)
Full Content: Text (complete documentation in AI-agent-friendly format)
Origin: Select (Idea | Research | Build | Ad-hoc)
Origin Link: Relation → Ideas/Research/Builds (depending on Origin)
Key Learnings: Text (top 3-5 takeaways)
Related Technologies: Multi-select (tags for discoverability)
Reusability: Select (Evergreen | Time-Bound | Deprecated)
Created Date: Date
Last Updated: Date
Contributors: Person (multi-select)
Views Count: Number (tracked manually or via API)
```

**Formatting Standard**: `📚 [Article Name]`

**Archival Trigger**: Use `/knowledge:archive [item-name] [database]` when work completes

---

### Agent Registry

**Data Source ID**: `5863265b-eeee-45fc-ab1a-4206d8a523c6`

**Purpose**: Specifications for all Claude Code specialized agents.

**Core Properties**:
```yaml
Agent Name: Title (required, format: @agent-name)
Agent Type: Select (Innovation | Cost | Research | Build | Knowledge | Operations | Specialized)
Description: Text (what the agent does)
Specialization: Multi-select (BI, Azure, Notion, GitHub, Cost Analysis, etc.)
Primary Use Cases: Text (when to invoke this agent)
File Path: Text (.claude/agents/[agent-name].md)
Status: Select (Active | Deprecated | In Development | Testing)
Performance Score: Number 0-100 (effectiveness rating)
Total Invocations: Number (times used)
Average Duration: Number (minutes per session)
Success Rate: Number 0-100 (% of successful completions)

# Relations
Compatible Output Styles: Relation → Output Styles Registry
Recent Activity: Relation → Agent Activity Hub
Test Results: Relation → Agent Style Tests
```

---

### Agent Activity Hub

**Data Source ID**: `7163aa38-f3d9-444b-9674-bde61868bd2b`

**Purpose**: Track all Claude Code agent work for transparency and workflow continuity.

**Core Properties**:
```yaml
Activity Title: Title (format: AgentName - Work Description - YYYYMMDD)
Agent: Relation → Agent Registry (required)
Status: Select (In Progress | Completed | Blocked | Handed Off)
Work Description: Text (what the agent did)
Session Start: Date & Time
Session End: Date & Time
Duration: Formula (Session End - Session Start)
Files Created: Number
Files Updated: Number
Lines Generated: Number (estimated)
Related Idea: Relation → Ideas Registry
Related Research: Relation → Research Hub
Related Build: Relation → Example Builds
Deliverables: Text (organized by category with file paths)
Next Steps: Text (what should happen next)
Blockers: Text (if status = Blocked)
Notes: Text (additional context)
```

**Logging**: Automatic via Phase 4 hook + manual via `/agent:log-activity`

**→ See [agent-activity-center.md](./agent-activity-center.md) for complete tracking system**

---

### Output Styles Registry

**Data Source ID**: `199a7a80-224c-470b-9c64-7560ea51b257`

**Purpose**: Define communication styles for dynamic agent output adaptation.

**Core Properties**:
```yaml
Style Name: Title (required)
Style ID: Text (technical-implementer, strategic-advisor, etc.)
Category: Select (Technical | Business | Visual | Educational | Compliance)
Target Audience: Multi-select (Developers, Executives, Auditors, Trainees, etc.)
Description: Text (when to use this style)
File Path: Text (.claude/styles/[style-id].md)
Performance Score: Number 0-100 (average effectiveness)
Usage Count: Number (times used)
Average Satisfaction: Number 1-5 (user feedback)
Status: Select (Active | Deprecated | Testing)

# Relations
Compatible Agents: Relation → Agent Registry
Test Results: Relation → Agent Style Tests
Best Use Cases: Text
```

**→ See [output-styles-system.md](./output-styles-system.md) for complete style testing framework**

---

### Agent Style Tests

**Data Source ID**: `b109b417-2e3f-4eba-bab1-9d4c047a65c4`

**Purpose**: Track empirical effectiveness data for agent+style combinations.

**Core Properties**:
```yaml
Test Name: Title (format: AgentName-StyleName-YYYYMMDD)
Agent: Relation → Agent Registry (required)
Style: Relation → Output Styles Registry (required)
Test Date: Date
Task Description: Text (what the agent was asked to do)

# Behavioral Metrics
Output Length: Number (tokens)
Technical Density: Number 0-1 (ratio of technical content)
Formality Score: Number 0-1 (language formality level)
Clarity Score: Number 0-1 (readability assessment)
Visual Elements Count: Number (diagrams, tables, etc.)
Code Blocks Count: Number

# Effectiveness Metrics
Goal Achievement: Number 0-1 (did it accomplish the task?)
Audience Appropriateness: Number 0-1 (fit for target audience?)
Style Consistency: Number 0-1 (adhered to style rules?)
Overall Effectiveness: Formula (weighted average: 30% + 25% + 20% + 15% + 10%)

# Performance Metrics
Generation Time: Number (milliseconds)
User Satisfaction: Number 1-5 (stars)

# UltraThink Analysis
UltraThink Tier: Select (🥇 Gold | 🥈 Silver | 🥉 Bronze | ⚪ Needs Improvement)
Semantic Appropriateness: Number 0-100
Audience Alignment: Number 0-100
Brand Consistency: Number 0-100
Practical Effectiveness: Number 0-100
Innovation Potential: Number 0-100

# Output
Test Output: Text (long - full generated content)
Notes: Text (observations and insights)
Status: Select (Passed | Failed | Needs Review)
```

**Testing**: Use `/test-agent-style` or `/style:compare` commands

---

### 🎨 Mermaid Diagram Registry

**Database ID**: `3d045372-e9b3-45b6-906d-355a3c38430f`
**Data Source ID**: `7169c29d-ca42-49a7-a867-0a110ee89532`

**Purpose**: Centralized tracking of all Mermaid diagrams across GitHub repositories and Notion pages to streamline visual asset management, diagram reuse, and documentation coverage analysis.

**Core Properties**:
```yaml
Name: Title (format: 📊 [Page/File Name] - [Diagram Type])
Diagram Type: Select (Flowchart | Sequence Diagram | Class Diagram | Entity Relationship | State Diagram | Gantt Chart | Pie Chart | User Journey | Git Graph | Mindmap)
Source Type: Select (🐙 GitHub | 📝 Notion | 📄 Local File)
Source Location: URL (GitHub file URL or Notion page URL)
File Path: Text (GitHub file path or Notion page path)
Mermaid Code: Text (long - actual diagram code for reuse)
Description: Text (diagram purpose and context)
Category: Select (Architecture | Workflow | Data Model | Process Flow | System Design | Integration | User Flow | Timeline | Relationship | Other)
Complexity: Select (🟢 Simple | 🟡 Medium | 🔴 Complex)
Status: Select (✅ Active | 🔄 Needs Update | ⚠️ Outdated | 🗃️ Archived)
Tags: Multi-select (Documentation, Architecture, API, Database, Azure, Workflow, Integration, Agent, Webhook, Innovation)
Last Scanned: Date (auto-updated by scanner scripts)
Node Count: Number (approximate number of nodes/elements)
Reusability: Select (🔄 Highly Reusable | ⚡ Moderately Reusable | 📌 Context-Specific)
```

**Formatting Standard**: `📊 [Page/File Name] - [Diagram Type]` (e.g., "📊 Webhook Architecture - Sequence Diagram")

**Population Methods**:
- **GitHub Scanner**: `.\scripts\Scan-GitHubMermaidDiagrams.ps1 -SyncToNotion`
- **Notion Scanner**: `.\scripts\Scan-NotionMermaidDiagrams.ps1 -SyncToRegistry`
- **Manual Entry**: Use Notion UI or create-pages API

**Use Cases**:
- **Diagram Reuse**: Search registry for existing diagrams before creating new ones
- **Documentation Audit**: Identify pages/files lacking visual elements
- **Diagram Inventory**: Track all visual assets across organization
- **Maintenance Tracking**: Monitor outdated diagrams needing updates
- **Pattern Library**: Curate highly reusable diagram templates

**Common Queries**:
```sql
-- Find all architecture diagrams in GitHub
SELECT * WHERE "Source Type" = "🐙 GitHub" AND "Category" = "Architecture"

-- Find highly reusable diagrams for templates
SELECT * WHERE "Reusability" = "🔄 Highly Reusable" AND "Status" = "✅ Active"

-- Find diagrams needing updates
SELECT * WHERE "Status" IN ("🔄 Needs Update", "⚠️ Outdated")

-- Complexity distribution for documentation planning
SELECT "Complexity", COUNT(*) GROUP BY "Complexity"
```

**Automation Scripts**:
- `Scan-GitHubMermaidDiagrams.ps1`: Extract diagrams from all markdown files in GitHub repos
- `Scan-NotionMermaidDiagrams.ps1`: Extract diagrams from Notion page content (requires Claude Code with Notion MCP)

---

### Projects

**Data Source ID**: `9f75999b-62d2-4c78-943e-c3e0debccfcd`

**Purpose**: Track active development projects with GitHub integration, priority management, and timeline tracking.

**Core Properties**:
```yaml
Project Name: Title (required)
Status: Status (Not Started | In Progress | Blocked | In Review | Done | Archived)
Priority: Select (P0 | P1 | P2 | P3)
  - P0 (red): Critical - immediate attention required
  - P1 (orange): High priority - this quarter
  - P2 (yellow): Medium priority - next quarter
  - P3 (green): Low priority - backlog
Owner: Person (project owner/lead)
GitHub Repo URL: URL (link to repository)
Description: Text (project scope and objectives)
Start Date: Date
Tags: Multi-select (Agents | AI | SaaS | Web App | Internal | Backend)

# Relations
Related Builds: Relation → Example Builds (if project produces builds)
Related Ideas: Relation → Ideas Registry (originating ideas)
Data Sources: Relation → Data Sources (client data infrastructure)

# Common Queries
# Active projects by priority
# Projects without GitHub repos
# Projects by owner
# Timeline view by start date
```

**Formatting Standard**: `📦 [Project Name]`

**Use Cases**:
- Track multi-build initiatives (e.g., DSP Command Central spanning multiple repositories)
- Manage client projects with deliverables
- Coordinate team assignments across related work

---

### Actions Registry

**Data Source ID**: `9d5a1db0-585f-4f5b-b2bb-a41f875a7de4`

**Purpose**: META database tracking all slash commands, automation workflows, and operational procedures. Self-documenting system that registers its own commands.

**Core Properties**:
```yaml
Name: Title (required, format: /command:action)
Category: Select (Innovation | Cost | Knowledge | Team | Repo | Autonomous | Compliance | Sync)
Status: Select (Active | Deprecated | Experimental)
Description: Text (what the command does and why it's valuable)
Parameters: Text (required and optional parameters)
Example Usage: Text (3-5 practical examples)
Workflow Steps: Text (step-by-step execution flow)
Related Databases: Multi-select (Ideas | Research | Builds | Software | Knowledge | Integration | OKRs | Agents | Actions | Repositories)
Created By: Person (who built this automation)
Last Updated: Date

# Relations
Used By Agents: Relation → Agent Registry (which agents invoke this command)
Documented In: Relation → Knowledge Vault (detailed documentation)

# Analytics
Usage Count: Number (times invoked)
Success Rate: Number 0-100 (% successful executions)
Average Duration: Number (seconds per execution)
Last Used: Date

# Common Queries
# Active commands by category
# Deprecated commands needing replacement
# Most-used commands (top 10)
# Commands with low success rate (<80%)
```

**Formatting Standard**: `⚡ /[command]:[action]`

**Critical Use Cases**:
- **Self-Registration**: New slash commands automatically register themselves via `/action:register`
- **Usage Analytics**: Track which commands are most valuable
- **Deprecation Workflow**: Mark obsolete commands and provide replacement guidance
- **Automation Discovery**: Browse all available commands by category

**META Nature**: This database tracks the automation system itself, including the command that creates entries in this database (`/action:register`). Enables recursive self-documentation.

---

### Data Sources

**Data Source ID**: `092940f4-1e6d-4321-b06a-1c0a9ee79445`

**Purpose**: Track client data infrastructure for BI projects - databases, APIs, SharePoint libraries, and external data connections with connection health monitoring.

**Core Properties**:
```yaml
Data Source Name: Title (required)
Source Type: Select (SQL Server | Azure SQL | Snowflake | API | Excel/CSV | SharePoint | Other)
Connection Status: Select (🟢 Active | 🟡 Testing | ⚫ Inactive | 🔴 Error)
Owner: Person (who manages this data source)
Connection Details: Text (connection string, endpoint URL, authentication method - encrypted/redacted)
Documentation Link: URL (vendor docs or internal setup guide)
Refresh Frequency: Select (Real-time | Hourly | Daily | Weekly | Manual)
Last Refresh: Last Edited Time (auto-updated)
Row Count: Number (estimated or actual record count)

# Relations
Projects Using: Relation → Projects (which projects consume this data)
Related Builds: Relation → Example Builds (builds that read/write this data)
Integration Registry: Relation → Integration Registry (technical integration details)

# Data Quality Metrics
Data Quality Score: Number 0-100 (completeness, accuracy, timeliness)
Availability: Number 0-100 (uptime percentage)
Issues: Text (known data quality problems or connection issues)

# Common Queries
# Active data sources by project
# Error status data sources (need attention)
# Data sources without documentation
# Unused data sources (no project relations)
```

**Formatting Standard**: `📊 [Data Source Name]`

**Use Cases**:
- **Client Project Management**: Track which data sources each client project depends on
- **Connection Health Monitoring**: Identify data sources with connectivity issues
- **Refresh Scheduling**: Coordinate data refresh frequencies across projects
- **Dependency Mapping**: Understand impact of data source changes on builds

**Best for**: Organizations managing BI implementations across multiple client data ecosystems requiring systematic data source inventory and health tracking.

---

## Key Relation Rules

### Rule 1: Software Tracker is Central Hub
**ALL databases link TO Software Tracker (never from)**

```
Ideas Registry → Software Tracker (Software Needed)
Research Hub → Software Tracker (Software Used)
Example Builds → Software Tracker (Software & Tools)
```

**Why**: Enables accurate cost rollups and utilization tracking

### Rule 2: Linear Innovation Progression
**Ideas → Research → Builds → Knowledge** (with links preserved)

```
1. Idea created (💡)
2. Research links to Idea (required)
3. Build links to Idea (required) + Research (if exists)
4. Knowledge links to Build/Research/Idea (depending on origin)
```

**Why**: Maintains lineage and enables tracking from concept to archive

### Rule 3: Every Build MUST Link Three Things
```
1. Origin Idea (required - where did this come from?)
2. Related Research (if research preceded build - preserve findings)
3. ALL Software & Tools (required - for cost rollup accuracy)
```

**Why**: Cost tracking depends on accurate software relations

### Rule 4: Agent Work MUST Link Context
**Agent Activity Hub entries link to related Innovation items**

```
Agent Activity → Idea (if working on idea)
Agent Activity → Research (if conducting research)
Agent Activity → Build (if building/deploying)
```

**Why**: Workflow continuity and context preservation

---

## Rollup Formulas

### Total Build Cost (in Example Builds)
```
Property: Total Build Cost
Type: Rollup
Relation: Software & Tools
Rollup Property: Total Monthly Cost
Function: Sum
```

### Software Utilization (in Software Tracker)
```
Property: Total Usage Count
Type: Formula
Formula: prop("Used in Ideas") + prop("Used in Research") + prop("Used in Builds")
```

### Days Until Renewal (in Software Tracker)
```
Property: Days Until Renewal
Type: Formula
Formula: dateBetween(prop("Contract End Date"), now(), "days")
```

### Research Duration (in Research Hub)
```
Property: Duration
Type: Formula
Formula: dateBetween(prop("Start Date"), prop("Completion Date"), "days")
```

---

## Query Patterns

### Find Unused Software
```typescript
notion-search {
  query: "",
  data_source_url: "collection://13b5e9de-2dd1-45ec-839a-4f3d50cd8d06",
  filters: {
    // Software with Status = Active but no usage
  }
}
```

### Find Ideas Needing Research
```typescript
notion-search {
  query: "",
  data_source_url: "collection://984a4038-3e45-4a98-8df4-fd64dd8a1032",
  filters: {
    // Viability = "Needs Research"
  }
}
```

### Find Expiring Contracts (60 days)
```typescript
// Query Software Tracker where Days Until Renewal < 60
```

### Find High-Viability Ideas Ready for Build
```typescript
notion-search {
  query: "",
  data_source_url: "collection://984a4038-3e45-4a98-8df4-fd64dd8a1032",
  filters: {
    // Viability = "High" AND Status = "Active"
  }
}
```

---

## Common Operations

### Create Idea with Software Links
```typescript
// 1. Search for duplicates
notion-search { query: "AI cost optimization" }

// 2. Search for software
notion-search { query: "Azure OpenAI", data_source_url: "collection://13b5e9de..." }

// 3. Create idea
notion-create-pages {
  parent: { data_source_id: "984a4038..." },
  pages: [{
    properties: {
      "Idea Name": "AI-powered cost optimization",
      "Status": "Concept",
      "Viability": "Needs Research",
      "Software Needed": [{ id: "azure-openai-id" }]
    }
  }]
}
```

### Create Research Linked to Idea
```typescript
// 1. Fetch origin idea
notion-fetch { id: "idea-page-id" }

// 2. Create research
notion-create-pages {
  parent: { data_source_id: "91e8beff..." },
  pages: [{
    properties: {
      "Research Topic": "AI cost optimization feasibility",
      "Origin Idea": [{ id: "idea-page-id" }],
      "Research Type": "Feasibility Study",
      "Status": "Active"
    }
  }]
}
```

### Create Build with Full Relations
```typescript
// 1. Fetch idea and research
notion-fetch { id: "idea-page-id" }
notion-fetch { id: "research-page-id" }

// 2. Search for all software used
// (Azure Functions, Azure OpenAI, Application Insights, etc.)

// 3. Create build
notion-create-pages {
  parent: { data_source_id: "a1cd1528..." },
  pages: [{
    properties: {
      "Build Name": "AI Cost Optimizer",
      "Status": "Active",
      "Build Type": "MVP",
      "Origin Idea": [{ id: "idea-page-id" }],
      "Related Research": [{ id: "research-page-id" }],
      "Software & Tools": [
        { id: "azure-functions-id" },
        { id: "azure-openai-id" },
        { id: "app-insights-id" }
      ],
      "Repository URL": "https://github.com/brookside-bi/ai-cost-optimizer"
    }
  }]
}
```

---

## Common Issues & Solutions

### Issue: "Relation property not found"
**Cause**: Using wrong property name or database doesn't have that relation
**Solution**:
1. Fetch the database to see schema: `notion-fetch { id: "database-url" }`
2. Use exact property name from schema
3. Verify relation points to correct database

### Issue: Cost rollup shows $0 despite software links
**Cause**: Relation not properly established or software has $0 cost
**Solution**:
1. Verify Software Tracker entries have Monthly Cost populated
2. Check relation is to correct database (Software & Tools property)
3. Ensure License Count > 0 in Software Tracker

### Issue: Can't find database by name
**Cause**: Notion MCP requires database ID or URL, not name
**Solution**:
1. Use data source IDs from this document
2. Or search first: `notion-search { query: "database-name" }`
3. Extract ID from search results

### Issue: Duplicate entries created
**Cause**: Skipped search-first protocol
**Solution**:
1. ALWAYS search before creating
2. Review search results carefully (check all fields, not just title)
3. If unsure, fetch existing item to compare

---

## Validation Checklist

**Before creating ANY Notion entry, verify:**

- ✅ Searched for duplicates (no exact matches found)
- ✅ Identified all required relations (Idea → Research → Build → Software)
- ✅ Fetched related items to understand current state
- ✅ Using correct data source ID for database
- ✅ Using exact property names from schema
- ✅ Proposed action to user (described what will be created)

**After creating Notion entry, verify:**

- ✅ All relations are established correctly
- ✅ Rollup formulas calculate as expected
- ✅ Status fields are accurate
- ✅ Cost tracking is reflected (if applicable)

---

**Last Updated**: 2025-10-28 (Cleaned: Removed Blog Posts database and Webflow-related fields)
**Related Documentation**:
- [Innovation Workflow](./innovation-workflow.md)
- [Agent Activity Center](./agent-activity-center.md)
- [Output Styles System](./output-styles-system.md)
