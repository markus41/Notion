# Common Workflows

**Purpose**: Establish step-by-step procedures for frequently executed Innovation Nexus operations.

**Best for**: Agents executing multi-step workflows, users learning the system, or automating routine processes.

---

## 1. Complete Innovation Lifecycle

**Objective**: Take an idea from concept through research, build, and knowledge archival

**Timeline**: 3-7 days (or 40-60 min autonomous via `/autonomous:enable-idea`)

### Step-by-Step Process

#### Phase 1: Capture Idea (5 min)
```bash
/innovation:new-idea "AI-powered cost optimization platform for Azure"
```

**What Happens**:
1. @ideas-capture agent searches for duplicates
2. Assesses initial viability (High/Medium/Low/Needs Research)
3. Calculates estimated costs (if tools mentioned)
4. Assigns champion based on specialization
5. Creates Ideas Registry entry

**Expected Outcome**: New idea with status "Concept" and viability "Needs Research"

#### Phase 2: Research Investigation (2-4 hours or 1-2 days)
```bash
/innovation:start-research "Azure cost optimization feasibility" "AI cost optimizer"
```

**What Happens**:
1. @research-coordinator creates Research Hub entry
2. Links to origin Idea (maintains lineage)
3. Invokes parallel research swarm (4 agents):
   - @market-researcher → Market viability (0-100)
   - @technical-analyst → Technical feasibility (0-100)
   - @cost-feasibility-analyst → Financial viability (0-100)
   - @risk-assessor → Risk analysis (0-100, inverse)
4. Aggregates scores → Overall Viability Score
5. Updates Idea viability based on findings
6. Recommends next steps

**Expected Outcome**: Research complete with viability score and go/no-go recommendation

**Decision Point**:
- **>85**: Auto-approve for Build phase (autonomous)
- **60-85**: Request human review and decision
- **<60**: Archive with learnings documented

#### Phase 3: Autonomous Build (40-60 min)
```bash
/autonomous:enable-idea "AI cost optimizer"
```

**What Happens** (Zero Human Intervention):
1. **Architecture (10 min)**:
   - @build-architect generates technical specs
   - Selects optimal Azure services
   - Designs data models and API contracts
   - Creates Bicep infrastructure templates

2. **Code Generation (20 min)**:
   - @code-generator produces application code
   - Implements authentication (Managed Identity)
   - Configures database access
   - Creates API endpoints with validation
   - Generates tests (unit + integration)

3. **Infrastructure (15 min)**:
   - @deployment-orchestrator deploys Bicep templates
   - Provisions App Service/Function App
   - Configures networking and security
   - Sets up Key Vault integration

4. **Deployment (10 min)**:
   - Builds application artifacts
   - Deploys to Azure environment
   - Runs smoke tests
   - Verifies health endpoints

**Expected Outcome**: Live application deployed to Azure with CI/CD pipeline

#### Phase 4: Knowledge Archival (15 min)
```bash
/knowledge:archive "AI cost optimizer" build
```

**What Happens**:
1. @knowledge-curator extracts key learnings
2. Categorizes content (Technical Doc, Case Study, etc.)
3. Structures for AI-agent consumption
4. Creates Knowledge Vault entry with relations
5. Tags technologies and patterns
6. Marks as Evergreen or Time-Bound

**Expected Outcome**: Learnings preserved, build marked as Completed

---

## 2. Quarterly Cost Optimization

**Objective**: Identify savings opportunities and optimize software spending

**Timeline**: 2-3 hours

**Frequency**: Quarterly (Jan, Apr, Jul, Oct)

### Step-by-Step Process

#### Step 1: Comprehensive Analysis (30 min)
```bash
/cost:analyze all
```

**Reviews**:
- Total monthly/annual spend
- Cost trends (increasing/decreasing)
- Top 10 most expensive tools
- Unused software (Status=Active, zero usage)
- Microsoft vs. third-party breakdown

**Output**: Summary report with key metrics and flags

#### Step 2: Identify Unused Software (15 min)
```bash
/cost:unused-software
```

**Identifies**:
- Active licenses with zero linked Ideas/Research/Builds
- Software with no activity in >90 days
- Trial/POC tools never promoted to production

**Action**: Review each for cancellation or consolidation

#### Step 3: Find Consolidation Opportunities (20 min)
```bash
/cost:consolidation-opportunities
```

**Analyzes**:
- Duplicate or overlapping tool capabilities
- Microsoft alternatives for third-party tools
- Underutilized licenses (could reduce count)

**Action**: Propose consolidation plan

#### Step 4: Check Expiring Contracts (10 min)
```bash
/cost:expiring-contracts
```

**Lists**: Software with contracts ending within 60 days

**Action**: Negotiate renewals or plan migrations

#### Step 5: Implement Changes (Variable)
- Cancel unused software → Update Status to "Expired"
- Consolidate tools → Migrate data, update relations
- Reduce license counts → Update Software Tracker
- Renegotiate contracts → Update costs and dates

#### Step 6: Measure Savings (10 min)
```bash
/cost:monthly-spend  # Before vs. After comparison
```

**Calculate**:
- Total savings (monthly/annual)
- Percentage reduction
- ROI of optimization effort

**Document**: Update cost optimization tracker, share with leadership

---

## 3. Repository Portfolio Analysis

**Objective**: Analyze all GitHub repositories with viability scoring and Notion sync

**Timeline**: 1-2 hours (initial) + 15 min weekly (maintenance)

**Frequency**: Weekly (Sundays via Azure Function) + On-demand

### Step-by-Step Process

#### Step 1: Full Organization Scan (1 hour)
```bash
/repo:scan-org --sync --deep
```

**What Happens**:
1. @repo-analyzer scans all repos in brookside-bi org
2. Calculates viability scores (0-100):
   - Test Coverage (30 points)
   - Activity (20 points)
   - Documentation (25 points)
   - Dependencies (25 points)
3. Detects Claude integration maturity (Expert → None)
4. Extracts architectural patterns
5. Calculates dependency costs
6. Syncs to Example Builds + Software Tracker

**Expected Outcome**: Complete portfolio visibility in Notion

#### Step 2: Extract Reusable Patterns (20 min)
```bash
/repo:extract-patterns --sync
```

**Identifies**:
- Common architectural patterns (Circuit Breaker, Retry, etc.)
- Shared libraries and utilities
- Reusable infrastructure templates
- Best practices across repos

**Action**: Document patterns in Knowledge Vault

#### Step 3: Calculate Portfolio Costs (10 min)
```bash
/repo:calculate-costs --detailed
```

**Analyzes**:
- Direct costs (GitHub Actions minutes, storage)
- Dependency costs (npm packages, Python libraries)
- Azure resource costs (if deployed)
- Maintenance overhead estimates

**Output**: Total cost of ownership per repository

#### Step 4: Prioritize Improvements (Variable)
- Low viability (<60) → Investigate or archive
- Missing Claude integration → Add CLAUDE.md
- High costs → Optimize dependencies or SKUs
- Outdated dependencies → Security updates

---

## 4. Emergency Research (Fast-Track)

**Objective**: Rapid feasibility assessment for urgent opportunities

**Timeline**: 2-4 hours

**Use When**: Time-sensitive decisions, competitive threats, urgent customer requests

### Step-by-Step Process

#### Step 1: Capture Urgent Idea (2 min)
```bash
/innovation:new-idea "[URGENT] Competitor launched similar feature - evaluate response"
```

**Set Priority**: High (in Notion after creation)

#### Step 2: Immediate Research Kickoff (5 min)
```bash
/innovation:start-research "Competitive feature analysis" "[idea-name]"
```

**Focus**: 2-4 hour investigation (not 1-2 days)

#### Step 3: Parallel Swarm Execution (2 hours)
- @market-researcher: Competitor feature analysis (60 min)
- @technical-analyst: Implementation complexity (45 min)
- @cost-feasibility-analyst: Quick cost estimate (30 min)
- @risk-assessor: Risk assessment (30 min)

**Deliverable**: Key findings + Go/No-Go in 2 hours

#### Step 4: Decision (15 min)
**Options**:
1. **Build Immediately**: High viability + strategic importance
   ```bash
   /autonomous:enable-idea "[idea-name]"  # 40-60 min to deployment
   ```

2. **Archive with Rationale**: Low viability or strategic misfit
   ```bash
   /knowledge:archive "[research-name]" research
   ```

3. **Further Investigation**: More research needed
   - Schedule follow-up research (1-2 days)
   - Define specific questions to answer

---

## 5. Agent Style Testing & Optimization

**Objective**: Test agent+style combinations and optimize communication effectiveness

**Timeline**: 30-45 min per agent

**Frequency**: Quarterly or when agent performance declines

### Step-by-Step Process

#### Step 1: Test All Styles for Agent (20 min)
```bash
/test-agent-style @cost-analyst ? --ultrathink --sync
```

**Tests**: All 5 styles (Technical Implementer, Strategic Advisor, Visual Architect, Interactive Teacher, Compliance Auditor)

**Metrics Collected**:
- Behavioral: Technical density, formality, clarity
- Effectiveness: Goal achievement, audience fit, consistency
- Performance: Generation time, output length
- UltraThink: Tier classification (Gold/Silver/Bronze)

#### Step 2: Compare Top Performers (10 min)
```bash
/style:compare @cost-analyst "Analyze Q4 spending for executives" --ultrathink
```

**Output**: Side-by-side comparison table with recommendations

#### Step 3: Review Historical Performance (5 min)
```bash
/style:report --agent=@cost-analyst --timeframe=90d --format=detailed
```

**Analyzes**:
- Effectiveness trends over time
- User satisfaction scores
- Best/worst style combinations
- Improvement opportunities

#### Step 4: Implement Changes (Variable)
- Update agent specifications with recommended style
- Refine style definitions based on insights
- Re-test after changes to verify improvement

---

## 6. Daily Startup Routine

**Objective**: Ensure all systems operational for productive work session

**Timeline**: 3-5 minutes

**Frequency**: Daily (or after system restart)

### Complete Setup Sequence

```powershell
# 1. Authenticate to Azure (tokens expire after 24 hours)
az login
az account show  # Verify: cfacbbe8-a2a3-445f-a188-68b3b35f0c84

# 2. Configure MCP environment variables
.\scripts\Set-MCPEnvironment.ps1

# 3. Verify all MCP servers (optional but recommended)
.\scripts\Test-AzureMCP.ps1
claude mcp list

# 4. Launch Claude Code
claude
```

**Expected State**:
- ✓ Azure CLI authenticated
- ✓ All environment variables set
- ✓ MCP servers connected (Notion, GitHub, Azure, Playwright)
- ✓ Claude Code ready

---

## 7. Build Deployment (Manual Alternative)

**Objective**: Deploy build when autonomous pipeline not suitable

**Timeline**: 2-4 hours

**Use When**: Custom deployment requirements, non-standard architecture, legacy systems

### Step-by-Step Process

#### Step 1: Architecture Review (30 min)
- Review build technical specifications
- Verify Azure services selected
- Validate cost estimates
- Check security requirements

#### Step 2: Infrastructure Setup (45 min)
```bash
# Create resource group
az group create --name rg-[project]-[env] --location westus2

# Deploy Bicep template
az deployment group create \
  --resource-group rg-[project]-[env] \
  --template-file infrastructure/main.bicep \
  --parameters environment=[env]
```

#### Step 3: Application Deployment (30 min)
```bash
# Build application
npm run build  # or dotnet publish, poetry build, etc.

# Deploy to Azure
az webapp deployment source config-zip \
  --resource-group rg-[project]-[env] \
  --name app-[project]-[env] \
  --src dist.zip
```

#### Step 4: Configuration (15 min)
```bash
# Set application settings
az webapp config appsettings set \
  --resource-group rg-[project]-[env] \
  --name app-[project]-[env] \
  --settings KEY_VAULT_NAME=kv-[project]-[env]

# Enable managed identity
az webapp identity assign \
  --resource-group rg-[project]-[env] \
  --name app-[project]-[env]
```

#### Step 5: Smoke Tests (15 min)
- Verify application loads
- Test health endpoint
- Check authentication
- Validate database connectivity
- Review Application Insights logs

#### Step 6: Update Notion (10 min)
- Update Build status to "Deployed - [env]"
- Add deployment URL
- Document any manual configurations
- Link to Application Insights

---

## 8. Knowledge Vault Search & Reuse

**Objective**: Find existing solutions before building from scratch

**Timeline**: 10-15 minutes

**Frequency**: Before starting any new build

### Step-by-Step Process

#### Step 1: Search by Technology
```typescript
// Via Notion search
/notion-search "Azure Functions Python" data_source="Knowledge Vault"
```

#### Step 2: Search by Pattern
```typescript
// Find architectural patterns
/notion-search "circuit breaker" OR "retry logic" data_source="Knowledge Vault"
```

#### Step 3: Review Relevant Entries
- Read full documentation
- Check reusability (Evergreen vs Time-Bound)
- Verify technologies match current build
- Note lessons learned and gotchas

#### Step 4: Adapt and Implement
- Copy reusable code/infrastructure
- Adapt to current requirements
- Credit original build in documentation
- Update Knowledge Vault if improvements made

---

## Workflow Tips

### ✅ Best Practices

1. **Search Before Creating**: Always check for duplicates (Ideas, Research, Builds, Knowledge)
2. **Link Everything**: Maintain relations (Idea → Research → Build → Knowledge)
3. **Track Costs**: Link all software/tools for accurate rollups
4. **Document Learnings**: Archive completed work to Knowledge Vault
5. **Use Automation**: Prefer `/autonomous:enable-idea` for standard builds
6. **Test Styles**: Optimize agent communication with style testing
7. **Review Regularly**: Quarterly cost optimization and portfolio analysis

### ❌ Common Pitfalls

1. **Skipping Research**: Building without feasibility assessment
2. **Missing Relations**: Creating items without linking to origin/software
3. **Ignoring Costs**: Not tracking software expenses
4. **Manual Deployment**: Using manual process when autonomous available
5. **Lost Knowledge**: Completing work without archiving learnings
6. **Wrong Agent**: Using generic approach when specialized agent exists
7. **Default Style**: Not optimizing output style for audience

---

## Related Resources

**Commands**:
- [/innovation:*](./../commands/innovation/) - Full innovation lifecycle
- [/cost:*](./../commands/cost/) - Cost management
- [/repo:*](./../commands/repo/) - Repository analysis
- [/style:*](./../commands/style/) - Output style testing

**Documentation**:
- [Innovation Workflow](./innovation-workflow.md)
- [Notion Schema](./notion-schema.md)
- [Agent Activity Center](./agent-activity-center.md)
- [Output Styles System](./output-styles-system.md)

---

**Last Updated**: 2025-10-26
