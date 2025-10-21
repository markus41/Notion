# /orchestrate-complex

**Purpose**: Orchestrate complex multi-agent workflows with parallel execution, dependency management, and automated coordination to drive measurable outcomes through structured approaches.

**Best for**: Organizations requiring sophisticated task decomposition and parallel agent coordination for high-impact innovation initiatives.

---

## Command Specification

**Syntax**: `/orchestrate-complex [task-description]`

**Parameters**:
- `task-description` (required): High-level description of complex task requiring multi-agent coordination

**Examples**:
```bash
/orchestrate-complex Create comprehensive cost optimization strategy with market research, technical analysis, and implementation roadmap

/orchestrate-complex Build Azure OpenAI integration with Notion MCP including architecture, deployment, testing, and documentation

/orchestrate-complex Establish enterprise governance framework across Ideas Registry, Research Hub, and Example Builds
```

---

## How It Works

### Phase 1: Task Analysis & Decomposition (2-5 minutes)

**Agent**: Primary orchestration logic (this command)

**Activities**:
1. Parse task description to identify domains (cost, research, build, compliance, etc.)
2. Identify required specialized agents based on domain keywords
3. Detect dependencies between subtasks (DAG analysis)
4. Determine parallel execution groups
5. Estimate effort and complexity per subtask

**Output**: Directed Acyclic Graph (DAG) execution plan

### Phase 2: Agent Coordination Plan (1-3 minutes)

**Agent**: Primary orchestration logic

**Activities**:
1. Map subtasks to specialized agents from Innovation Nexus registry
2. Identify data dependencies between agents
3. Group independent tasks for parallel execution
4. Establish context-sharing strategy between agents
5. Define success criteria and validation steps

**Output**: Multi-agent coordination matrix

### Phase 3: Parallel Execution (variable duration)

**Agents**: Multiple specialized agents in parallel

**Execution Strategy**:
```
Wave 1 (Parallel - No Dependencies):
├─ @agent-1: Independent subtask A
├─ @agent-2: Independent subtask B
└─ @agent-3: Independent subtask C

Wave 2 (Parallel - Depends on Wave 1):
├─ @agent-4: Subtask D (uses output from agent-1)
└─ @agent-5: Subtask E (uses output from agent-2)

Wave 3 (Sequential - Depends on Wave 2):
└─ @agent-6: Final integration (uses output from agents 4 & 5)
```

**Resilience Patterns Applied**:
- Circuit-breaker: Fail fast if critical agent fails repeatedly
- Retry with exponential backoff: Handle transient failures
- Saga pattern: Compensating transactions if workflow fails mid-execution

### Phase 4: Integration & Validation (2-5 minutes)

**Agent**: Primary orchestration logic

**Activities**:
1. Collect outputs from all parallel agents
2. Verify success criteria met for each subtask
3. Integrate results into cohesive deliverable
4. Run validation checks (links, JSON, security, etc.)
5. Generate execution summary with metrics

**Output**: Integrated deliverable + execution report

---

## Multi-Agent Coordination Strategy

### Agent Selection Logic

**Keyword Mapping**:
- **Cost/Budget/Spend** → `@cost-analyst`
- **Research/Feasibility/Investigation** → `@research-coordinator`
- **Build/Deploy/Prototype** → `@build-architect`, `@integration-specialist`
- **Database/Schema/Query** → `@database-architect`
- **Compliance/Licensing/Security** → `@compliance-orchestrator`
- **Architecture/Design/ADR** → `@architect-supreme`
- **Knowledge/Document/Archive** → `@knowledge-curator`, `@markdown-expert`
- **Diagram/Visual/Flowchart** → `@mermaid-diagram-expert`
- **Team/Assign/Workload** → `@workflow-router`
- **Viability/Impact/Risk** → `@viability-assessor`

### Dependency Detection

**Common Dependency Patterns**:

1. **Cost Analysis → Build Decision**
   - `@cost-analyst` must complete BEFORE `@build-architect`
   - Output: Total cost estimate used as input to build planning

2. **Research → Viability Assessment → Build**
   - `@research-coordinator` → `@viability-assessor` → `@build-architect`
   - Sequential chain with clear data handoffs

3. **Architecture Design → Multiple Implementations**
   - `@architect-supreme` (Wave 1) → `@build-architect` + `@database-architect` + `@integration-specialist` (Wave 2, parallel)
   - One-to-many parallel expansion

4. **Multiple Analyses → Integration Decision**
   - `@cost-analyst` + `@viability-assessor` + `@compliance-orchestrator` (Wave 1, parallel) → `@workflow-router` (Wave 2)
   - Many-to-one parallel consolidation

### Context Sharing Between Agents

**Shared Context Variables**:
```typescript
// Available to all agents in workflow
const sharedContext = {
  workflowId: string;           // Unique workflow identifier
  taskDescription: string;       // Original user request
  notionDatabases: {             // Database IDs for queries
    ideas: "984a4038-3e45-4a98-8df4-fd64dd8a1032",
    research: "91e8beff-af94-4614-90b9-3a6d3d788d4a",
    builds: "a1cd1528-971d-4873-a176-5e93b93555f6",
    software: "13b5e9de-2dd1-45ec-839a-4f3d50cd8d06"
  },
  outputs: {                     // Agent outputs collected here
    "cost-analyst": { totalCost: 250, breakdown: [...] },
    "viability-assessor": { rating: "HIGH", score: 85 }
  }
};
```

**Data Handoff Example**:
```typescript
// Agent 1: @cost-analyst completes
sharedContext.outputs["cost-analyst"] = {
  totalMonthlyCost: 250,
  breakdown: [
    { service: "Azure OpenAI", cost: 200 },
    { service: "GitHub Actions", cost: 50 }
  ]
};

// Agent 2: @viability-assessor receives context
const costData = sharedContext.outputs["cost-analyst"];
// Uses cost data to assess ROI and viability
```

---

## Execution Examples

### Example 1: Comprehensive Cost Optimization

**User Request**:
```bash
/orchestrate-complex Create comprehensive cost optimization strategy with market research, technical analysis, and implementation roadmap
```

**Execution Plan**:

**Wave 1 (Parallel - 10-15 mins)**:
- `@cost-analyst`: Analyze current spend, identify top expenses, find unused tools
- `@viability-assessor`: Assess cost optimization impact on business operations
- `@compliance-orchestrator`: Check licensing implications of consolidation

**Wave 2 (Parallel - 8-12 mins)**:
- `@architect-supreme`: Design Microsoft ecosystem migration architecture (uses compliance data)
- `@markdown-expert`: Document cost optimization strategy (uses cost analyst data)
- `@workflow-router`: Assign implementation tasks to team (uses viability data)

**Wave 3 (Sequential - 5-8 mins)**:
- `@knowledge-curator`: Create Knowledge Vault entry with complete strategy
- Primary orchestrator: Generate executive summary and implementation timeline

**Total Time**: 23-35 minutes (vs 45-60 minutes sequential)

**Deliverables**:
- ✓ Cost analysis report with $X,XXX annual savings potential
- ✓ Microsoft ecosystem migration architecture
- ✓ Implementation roadmap with team assignments
- ✓ Compliance assessment for all consolidations
- ✓ Knowledge Vault entry for reusability

---

### Example 2: Azure OpenAI Integration Build

**User Request**:
```bash
/orchestrate-complex Build Azure OpenAI integration with Notion MCP including architecture, deployment, testing, and documentation
```

**Execution Plan**:

**Wave 1 (Parallel - 15-20 mins)**:
- `@architect-supreme`: Design Azure OpenAI + Notion MCP architecture with ADR
- `@cost-analyst`: Calculate Azure OpenAI pricing (GPT-4, embeddings, etc.)
- `@compliance-orchestrator`: Assess data privacy and licensing for AI usage

**Wave 2 (Parallel - 20-30 mins, depends on Wave 1)**:
- `@build-architect`: Create Example Build entry, GitHub repo, technical docs (uses architecture)
- `@database-architect`: Design Notion schema for AI interaction logs (uses architecture)
- `@integration-specialist`: Set up Azure resources, Key Vault secrets (uses architecture + cost data)

**Wave 3 (Parallel - 15-20 mins, depends on Wave 2)**:
- `@markdown-expert`: Create comprehensive README and API documentation
- `@mermaid-diagram-expert`: Generate architecture diagrams and sequence flows
- `@knowledge-curator`: Document AI integration patterns for Knowledge Vault

**Wave 4 (Sequential - 5-10 mins)**:
- Primary orchestrator: Verify all links, validate JSON, security scan
- `@workflow-router`: Assign lead builder and core team

**Total Time**: 55-80 minutes (vs 90-120 minutes sequential)

**Deliverables**:
- ✓ Example Build entry in Notion with complete metadata
- ✓ GitHub repository with production-ready code
- ✓ Azure resources provisioned (OpenAI, Key Vault, App Service)
- ✓ Architecture Decision Record (ADR) documented
- ✓ Cost breakdown and monthly projections
- ✓ Compliance assessment for AI data handling
- ✓ Comprehensive documentation (README, API docs, diagrams)
- ✓ Knowledge Vault pattern entry for future AI integrations

---

### Example 3: Enterprise Governance Framework

**User Request**:
```bash
/orchestrate-complex Establish enterprise governance framework across Ideas Registry, Research Hub, and Example Builds
```

**Execution Plan**:

**Wave 1 (Parallel - 12-18 mins)**:
- `@database-architect`: Analyze current Notion schema, identify governance gaps
- `@compliance-orchestrator`: Define governance policies (GDPR, licensing, access control)
- `@architect-supreme`: Design governance architecture with approval workflows

**Wave 2 (Parallel - 15-25 mins, depends on Wave 1)**:
- `@schema-manager`: Implement new Notion properties for governance tracking
- `@markdown-expert`: Document governance policies and procedures
- `@integration-specialist`: Set up Power Automate workflows for approval routing

**Wave 3 (Parallel - 10-15 mins, depends on Wave 2)**:
- `@knowledge-curator`: Create governance playbook in Knowledge Vault
- `@workflow-router`: Assign governance roles to team members
- `@cost-analyst`: Calculate governance tooling costs (Power Automate, etc.)

**Wave 4 (Sequential - 5-8 mins)**:
- Primary orchestrator: Validate all database changes, test approval workflows
- Generate governance implementation report

**Total Time**: 42-66 minutes (vs 70-100 minutes sequential)

**Deliverables**:
- ✓ Enhanced Notion schemas with governance properties
- ✓ Documented governance policies aligned with GDPR/CCPA
- ✓ Power Automate approval workflows deployed
- ✓ Team role assignments and responsibilities
- ✓ Governance playbook in Knowledge Vault
- ✓ Cost analysis for governance infrastructure

---

## Resilience & Error Handling

### Circuit-Breaker Pattern

**Applied To**: Critical agent failures that block entire workflow

**Example**:
```
Workflow: Azure OpenAI Integration Build

Wave 1, Agent @architect-supreme:
  Attempt 1: Design architecture → FAIL (timeout)
  Attempt 2: Retry → FAIL (timeout)
  Attempt 3: Retry → FAIL (timeout)
  Circuit-breaker OPENS → Workflow FAILS FAST

Result: User notified immediately instead of waiting for all waves to fail
```

### Retry with Exponential Backoff

**Applied To**: Transient failures in MCP servers (Notion, GitHub, Azure)

**Example**:
```
Wave 2, Agent @integration-specialist:
  Attempt 1: Provision Azure OpenAI → FAIL (quota exceeded)
  Wait 2 seconds...
  Attempt 2: Provision Azure OpenAI → FAIL (quota exceeded)
  Wait 4 seconds...
  Attempt 3: Provision Azure OpenAI → SUCCESS

Result: Resilient to temporary Azure quota issues
```

### Saga Pattern (Compensating Transactions)

**Applied To**: Multi-step workflows where later steps fail

**Example**:
```
Workflow: Azure OpenAI Integration Build

Wave 1: ✓ Create Notion Build Entry (buildId=123)
Wave 2: ✓ Create GitHub Repository (repoUrl=github.com/org/ai-integration)
Wave 2: ✓ Provision Azure OpenAI (resourceId=openai-123)
Wave 3: ✗ Create API Documentation → FAIL (markdown-expert error)

Saga Compensation:
  Compensate Wave 2: Mark Azure resource for deletion review (don't auto-delete expensive resources)
  Compensate Wave 2: Archive GitHub repository (preserve code for debugging)
  Compensate Wave 1: Update buildId=123 status='Failed', add error details

Result: Clean partial state, user can review and retry without orphaned resources
```

---

## Success Criteria

**Workflow Completion**:
- ✓ All required agents completed successfully
- ✓ All dependencies satisfied in correct order
- ✓ Outputs integrated into cohesive deliverable
- ✓ Validation checks passed (no broken links, valid JSON, no security issues)
- ✓ Notion databases updated with relations and metadata
- ✓ Knowledge captured for future reuse

**Performance Metrics**:
- **Parallel Efficiency**: (Sequential Time - Parallel Time) / Sequential Time × 100%
  - Target: 35-55% time savings
- **Agent Success Rate**: Successful Agent Completions / Total Agent Invocations
  - Target: ≥ 95%
- **First-Time Success**: Workflows completing without compensating transactions
  - Target: ≥ 80%

**Quality Metrics**:
- All Notion database entries created with required fields
- All GitHub repositories linked with proper documentation
- All Azure resources tracked in Software & Cost Tracker
- All compliance requirements met and documented
- All deliverables follow Brookside BI brand voice

---

## Integration with Innovation Nexus

### Notion Database Interactions

**Ideas Registry** (`984a4038-3e45-4a98-8df4-fd64dd8a1032`):
- Create or update ideas based on workflow outcomes
- Link to related research, builds, software
- Update viability assessments

**Research Hub** (`91e8beff-af94-4614-90b9-3a6d3d788d4a`):
- Create research entries for investigation subtasks
- Document findings and viability assessments
- Link to originating ideas

**Example Builds** (`a1cd1528-971d-4873-a176-5e93b93555f6`):
- Create build entries for implementation subtasks
- Link GitHub repositories and Azure resources
- Track costs via Software Tracker relations

**Software & Cost Tracker** (`13b5e9de-2dd1-45ec-839a-4f3d50cd8d06`):
- Link all tools and services used
- Verify cost rollups calculate correctly
- Identify optimization opportunities

**Knowledge Vault**:
- Capture workflow patterns for reuse
- Document architectural decisions (ADRs)
- Archive learnings and best practices

### Microsoft Ecosystem Alignment

**Azure Services**:
- Provision resources via `@integration-specialist` + Azure MCP
- Store secrets in Azure Key Vault (kv-brookside-secrets)
- Deploy builds to Azure App Services / Functions
- Track costs in Software Tracker

**GitHub Operations**:
- Create repositories via GitHub MCP
- Link to Example Build entries
- Set up CI/CD with GitHub Actions
- Track GitHub costs (Enterprise, Actions minutes)

**Power Platform Integration**:
- Power Automate workflows for approvals
- Power BI dashboards for cost tracking
- Power Apps for governance interfaces

---

## Command Output Format

```markdown
# Orchestration Execution Report

**Workflow**: [Task Description]
**Started**: 2025-10-21 14:32:15 UTC
**Completed**: 2025-10-21 15:18:42 UTC
**Total Duration**: 46 minutes 27 seconds
**Parallel Efficiency**: 42% time savings vs sequential

---

## Execution Summary

### Wave 1 (Parallel)
- ✓ @cost-analyst: Cost analysis completed (12 mins)
- ✓ @viability-assessor: Viability assessment completed (10 mins)
- ✓ @compliance-orchestrator: Compliance review completed (14 mins)

### Wave 2 (Parallel)
- ✓ @architect-supreme: Architecture design completed (18 mins)
- ✓ @markdown-expert: Documentation completed (15 mins)

### Wave 3 (Sequential)
- ✓ @knowledge-curator: Knowledge Vault entry created (8 mins)

---

## Deliverables

1. ✓ Cost optimization strategy ($45,000 annual savings identified)
   - Notion: [Link to Knowledge Vault entry]
   - Details: [Link to cost breakdown]

2. ✓ Architecture Decision Record (ADR)
   - Location: `.claude/docs/adr/2025-10-21-cost-optimization.md`
   - Decision: Consolidate to Microsoft ecosystem (Teams, Azure, M365)

3. ✓ Implementation roadmap
   - Assigned to: Alec Fielding (lead), Markus Ahling (Azure migration)
   - Timeline: Q1 2026 execution phase

4. ✓ Compliance assessment
   - GDPR: ✓ Compliant (data residency verified)
   - Licensing: ✓ All Microsoft licenses consolidated

---

## Performance Metrics

- **Agents Invoked**: 6
- **Agents Successful**: 6 (100% success rate)
- **Compensating Transactions**: 0 (first-time success)
- **Sequential Estimate**: 80 minutes
- **Actual Parallel Time**: 46 minutes
- **Time Savings**: 42%

---

## Notion Updates

- ✓ Knowledge Vault: Created "Cost Optimization Strategy 2025" entry
- ✓ Software Tracker: Updated 12 software entries with consolidation notes
- ✓ OKRs: Linked to "Reduce operational costs" strategic initiative
- ✓ Example Builds: No new builds (strategy phase)

---

## Validation Checks

- ✓ All links verified (0 broken links)
- ✓ JSON validation passed
- ✓ Security scan passed (no hardcoded credentials)
- ✓ Cost rollups calculated correctly
- ✓ Brookside BI brand voice applied

---

## Next Steps

1. Review strategy with leadership
2. Obtain approval for Microsoft ecosystem consolidation
3. Execute Phase 1: Cancel unused tools (immediate $1,200/month savings)
4. Execute Phase 2: Migrate to Microsoft Teams (3-month timeline)
5. Monitor cost savings and report quarterly
```

---

## Notes for Claude Code

**When to Use This Command**:
- ✓ Task requires 3+ specialized agents
- ✓ Significant parallel execution opportunities exist
- ✓ Complex dependencies between subtasks
- ✓ High-impact initiative requiring coordination
- ✓ User emphasizes "comprehensive" or "end-to-end" approach

**When NOT to Use**:
- ✗ Simple, single-agent tasks
- ✗ Sequential workflows with no parallelization potential
- ✗ Exploratory/investigative work without clear deliverables

**Orchestration Best Practices**:
1. Always identify dependencies first (build DAG)
2. Group truly independent tasks for parallel execution
3. Don't parallelize if data dependencies exist
4. Apply resilience patterns (circuit-breaker, retry, saga)
5. Share context efficiently between agents
6. Validate outputs before proceeding to next wave
7. Generate comprehensive execution reports
8. Capture patterns in Knowledge Vault for reuse

**Performance Targets**:
- 35-55% time savings through parallelization
- ≥95% agent success rate
- ≥80% first-time workflow success (no compensations)
- All deliverables meet quality standards
- Brookside BI brand voice applied consistently

---

**Best for**: Organizations managing complex, multi-faceted innovation initiatives that require coordinated expertise across cost analysis, architecture, compliance, development, and documentation—delivered with measurable time savings through intelligent parallel execution strategies.
