---
description: Create comprehensive project plans for Innovation Nexus initiatives from Idea through Research, Build, and Knowledge Vault
allowed-tools: Task(@ideas-capture:*), Task(@research-coordinator:*), Task(@build-architect:*), Task(@cost-analyst:*), Task(@workflow-router:*), Task(@integration-specialist:*), Task(@compliance-orchestrator:*), Task(@architect-supreme:*), Task(@viability-assessor:*)
argument-hint: [project-name] [--phase=stage] [--scope=range]
model: claude-sonnet-4-5-20250929
---

# /project-plan - Innovation Nexus Project Planning

**Purpose**: Establish comprehensive project plans that streamline innovation workflows from concept through knowledge preservation, designed to drive measurable outcomes through structured approaches aligned with Microsoft ecosystem best practices.

**Best for**: Organizations scaling innovation management across teams who require detailed planning, resource allocation, risk assessment, and milestone tracking for Ideas, Research, and Example Builds.

---

## Command Parameters

**Basic Syntax**:
```bash
/project-plan [project-name]
```

**Advanced Syntax**:
```bash
/project-plan [project-name] --phase=[stage] --scope=[range] --timeline=[constraint]
```

### Parameters

**`project-name`** (required)
- Innovation initiative to plan
- Examples: "azure-openai-integration", "cost-optimization-initiative", "governance-framework"

**`--phase`** (optional)
- Project lifecycle stage
- Options: `discovery` | `planning` | `research` | `build` | `deployment` | `maintenance`
- Default: `discovery`

**`--scope`** (optional)
- Project scope boundary
- Options: `component` | `feature` | `module` | `platform` | `integration`
- Default: `feature`

**`--timeline`** (optional)
- Status-driven progression milestones
- Options: `quick-win` | `standard` | `strategic` | `flexible`
- Default: `flexible`

---

## Planning Framework

### 1. Project Definition & Viability

**Objective Clarity**:
- Business problem statement
- Success criteria and measurable outcomes
- Alignment with OKRs & Strategic Initiatives
- Business value and ROI analysis
- Technical feasibility assessment

**Stakeholder Identification**:
- Champion assignment (based on team specialization)
- Core team members required
- Supporting roles from Innovation Nexus team:
  - Markus Ahling: Engineering, Operations, AI, Infrastructure
  - Brad Wright: Sales, Business, Finance, Marketing
  - Stephan Densby: Operations, Continuous Improvement, Research
  - Alec Fielding: DevOps, Engineering, Security, Integrations, R&D
  - Mitch Bisbee: DevOps, Engineering, ML, Master Data, Quality

**Viability Assessment** (delegate to `@viability-assessor`):
- Effort vs. Impact analysis
- Risk identification and mitigation strategies
- Preliminary viability rating: HIGH | MEDIUM | LOW | NEEDS_RESEARCH
- Go/No-Go recommendation with clear rationale

**Microsoft Ecosystem Alignment**:
- Azure services applicability
- M365 integration opportunities
- Power Platform automation potential
- GitHub Enterprise repository needs
- Microsoft-first alternatives to third-party tools

---

### 2. Work Breakdown Structure

**Innovation Lifecycle Mapping**:

**Phase A: Idea Capture** (if starting from concept)
- Create Ideas Registry entry via `/innovation:new-idea`
- Status: Concept
- Viability: Needs Research or preliminary assessment
- Champion: [Assigned based on specialization]
- Estimated Cost: [Link software/tools anticipated]

**Phase B: Research Investigation** (if viability = needs research)
- Create Research Hub entry via `/innovation:start-research`
- Hypothesis: Clear testable statement
- Methodology: Investigation approach
- Researchers: Team members assigned
- Key Questions: What unknowns must be resolved?
- Expected Outcomes: Findings that inform build decision

**Phase C: Example Build Development** (if viable)
- Create Example Build entry via `/innovation:create-build`
- Build Type: Prototype | POC | Demo | MVP | Reference Implementation
- Technical stack selection (Microsoft-first priority)
- GitHub repository creation
- Azure resource requirements
- Integration points (Notion MCP, Azure MCP, GitHub MCP)

**Phase D: Deployment & Operation**
- Azure deployment strategy
- CI/CD pipeline setup (GitHub Actions)
- Monitoring (Application Insights)
- Cost tracking (Software & Cost Tracker)
- Integration Registry entry

**Phase E: Knowledge Preservation**
- Lessons learned documentation
- Knowledge Vault archival via `/knowledge:archive`
- Reusability assessment
- Pattern extraction for future reference

---

### 3. Resource Planning

**Agent Orchestration** (delegate complex workflows):

**Core Planning Agents**:
- `@ideas-capture` - Idea structuring and duplicate prevention
- `@research-coordinator` - Research methodology and team coordination
- `@build-architect` - Technical architecture and documentation
- `@cost-analyst` - Financial analysis and software cost tracking
- `@workflow-router` - Team assignment based on specialization and workload

**Supporting Specialist Agents**:
- `@integration-specialist` - Microsoft ecosystem connections (Azure, GitHub, M365)
- `@compliance-orchestrator` - Licensing, GDPR/CCPA, security reviews
- `@architect-supreme` - Enterprise architecture and ADR documentation
- `@database-architect` - Notion schema optimization and Azure data architecture
- `@viability-assessor` - Feasibility and impact assessment
- `@knowledge-curator` - Documentation and Knowledge Vault management

**Team Workload Balancing** (via `@workflow-router`):
- Check current active item count per team member
- Optimal: 3-5 active items
- Full: 5-7 active items
- ⚠️ Overloaded: >7 active items
- Recommend redistribution if overloaded

---

### 4. Timeline & Milestones (Status-Driven)

**Important**: Innovation Nexus is **status-driven, not timeline-driven**. Focus on viability and progress, not deadlines.

**Status Progression**:
```
Concept → Active → Completed → Archived
```

**Milestone Checkpoints**:

**Checkpoint 1: Viability Assessment Complete**
- Decision: Proceed to Research, Build directly, or Archive
- Deliverable: Viability assessment documented in Ideas Registry
- Cost estimate: Software/tools identified and linked

**Checkpoint 2: Research Findings Complete** (if applicable)
- Decision: Highly Viable, Moderately Viable, Not Viable, Inconclusive
- Deliverable: Research Hub entry with key findings
- Next Steps: Build Example, More Research, Archive, Abandon

**Checkpoint 3: Build Architecture Defined**
- Decision: Technology stack approved, Azure resources scoped
- Deliverable: Architecture Decision Record (ADR) if significant
- Cost breakdown: Total monthly/annual projection

**Checkpoint 4: Build Development Complete**
- Decision: Ready for deployment or requires iteration
- Deliverable: GitHub repository with production-ready code
- Testing: Unit/integration tests passing

**Checkpoint 5: Deployment & Monitoring Live**
- Decision: Move to operational status or continue development
- Deliverable: Azure resources provisioned, Application Insights active
- Cost tracking: All software linked to Software Tracker

**Checkpoint 6: Knowledge Preservation**
- Decision: Archive with learnings or keep active for iteration
- Deliverable: Knowledge Vault entry created
- Reusability: Assessed and documented

---

### 5. Quality & Compliance Standards

**Code Quality Gates**:
- All code follows Brookside BI brand voice in comments
- Technical documentation is AI-agent executable
- No hardcoded credentials (Azure Key Vault required)
- All dependencies tracked in Software & Cost Tracker
- GitHub repository has comprehensive README

**Security Review Checkpoints**:
- Managed Identity for Azure resource access (where possible)
- Service Principal setup documented in Integration Registry
- All secrets stored in Azure Key Vault
- Authentication methods reviewed by `@compliance-orchestrator`
- Network security groups configured for Azure resources

**Regulatory Compliance Validation** (via `@compliance-orchestrator`):
- Software licensing compliance (MIT, GPL, commercial EULA)
- GDPR requirements for EU data (Articles 6, 7, 15, 17, 32)
- CCPA requirements for California data
- Integration security review for third-party tools

**Performance Benchmarking**:
- Load testing for production builds (Azure Load Testing)
- Cost optimization opportunities identified
- Microsoft service alternatives evaluated

**Notion Database Standards**:
- All entries created with complete metadata
- Relations properly linked (Ideas ↔ Research ↔ Builds ↔ Software)
- Cost rollups calculate correctly
- Status fields consistently updated

---

### 6. Innovation Nexus Integration Points

**Notion MCP Operations**:
- Ideas Registry: Create entries with viability assessment
- Research Hub: Link to originating idea, document findings
- Example Builds: GitHub repo links, Azure resource tracking
- Software & Cost Tracker: Link ALL tools used, verify rollups
- Knowledge Vault: Archive learnings with reusability assessment
- Integration Registry: Document authentication and endpoints

**GitHub MCP Operations**:
- Create repository for builds
- Initialize with README template
- Set up branch protection rules
- Configure GitHub Actions for CI/CD
- Link repository URL to Notion Build entry

**Azure MCP Operations**:
- Provision resources (App Service, Functions, SQL, Cosmos DB, etc.)
- Configure Key Vault for secrets
- Set up Application Insights for monitoring
- Deploy build to Azure
- Track costs in Software & Cost Tracker

**Cost Transparency Requirements**:
- All software/tools linked from Software & Cost Tracker
- Monthly and annual projections calculated
- Microsoft vs. third-party breakdown
- Unused software identified quarterly
- Contract expiration monitoring

---

## Deliverables

### Project Charter Document

```markdown
# Project Charter: [Project Name]

**Champion**: [Assigned Team Member]
**Core Team**: [Team Members]
**Status**: [Current Status]
**Viability**: [HIGH | MEDIUM | LOW]

---

## Executive Summary
[2-3 sentences: Problem, solution approach, expected value]

## Business Case
**Problem Statement**: [What business challenge does this address?]
**Success Criteria**: [Measurable outcomes]
**ROI Analysis**: [Cost vs. expected benefits]
**Alignment**: [Link to OKRs & Strategic Initiatives]

## Scope Definition
**In Scope**:
- [Deliverable 1]
- [Deliverable 2]

**Out of Scope**:
- [Exclusion 1]
- [Exclusion 2]

## Risk Register
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| [Risk description] | HIGH/MED/LOW | HIGH/MED/LOW | [Strategy] |

## Resource Requirements
**Team**: [Members and roles]
**Software/Tools**: [Link to Software Tracker entries]
**Azure Services**: [Resources needed]
**Estimated Cost**: $X,XXX/month ($XX,XXX/year)

## Milestones
1. ✅ Viability Assessment Complete
2. ⏳ Research Findings Complete
3. ⏳ Build Architecture Defined
4. ⏳ Development Complete
5. ⏳ Deployment Live
6. ⏳ Knowledge Preserved

## Links
- Ideas Registry: [Link]
- Research Hub: [Link if applicable]
- Example Build: [Link if applicable]
- GitHub Repository: [Link when created]
- Azure Resources: [Portal link when provisioned]
```

### Work Breakdown Structure (WBS)

```markdown
# Work Breakdown Structure: [Project Name]

## Epic 1: Discovery & Planning
- [ ] Create Ideas Registry entry
- [ ] Conduct viability assessment
- [ ] Identify required software/tools
- [ ] Estimate costs
- [ ] Assign champion and core team
- [ ] Decision: Proceed to Research or Build?

## Epic 2: Research Investigation (if needed)
- [ ] Create Research Hub entry
- [ ] Define hypothesis and methodology
- [ ] Set up SharePoint/OneNote documentation
- [ ] Conduct investigation
- [ ] Document key findings
- [ ] Viability assessment: Highly Viable | Moderately Viable | Not Viable
- [ ] Decision: Build Example | More Research | Archive

## Epic 3: Build Development
- [ ] Create Example Build entry
- [ ] Design architecture (invoke @architect-supreme for ADR if significant)
- [ ] Create GitHub repository
- [ ] Set up Azure resources
- [ ] Implement core functionality
- [ ] Write unit and integration tests
- [ ] Create technical documentation (AI-agent executable)
- [ ] Link all software/tools to Software Tracker

## Epic 4: Deployment & Integration
- [ ] Configure CI/CD pipeline (GitHub Actions)
- [ ] Deploy to Azure App Service / Functions
- [ ] Set up Application Insights monitoring
- [ ] Create Integration Registry entry
- [ ] Verify cost tracking and rollups
- [ ] Document runbook procedures

## Epic 5: Knowledge Preservation
- [ ] Document lessons learned
- [ ] Assess reusability (Highly Reusable | Partially Reusable | One-Off)
- [ ] Create Knowledge Vault entry
- [ ] Extract patterns for future reference
- [ ] Archive build (if complete)
- [ ] Update status to Archived
```

### Resource Allocation Matrix

```markdown
# Resource Allocation: [Project Name]

| Role | Team Member | Allocation | Responsibilities |
|------|-------------|------------|------------------|
| Champion | [Name] | Lead | Overall ownership, decision-making |
| Technical Lead | [Name] | 60% | Architecture, code reviews |
| Developer | [Name] | 80% | Implementation, testing |
| Cost Analyst | @cost-analyst | As needed | Financial tracking, optimization |
| Integration Specialist | @integration-specialist | As needed | Azure/GitHub/M365 setup |
| Compliance Review | @compliance-orchestrator | Checkpoint | Security, licensing |
| Documentation | @knowledge-curator | As needed | Knowledge Vault entries |
```

### Success Metrics & KPIs

```markdown
# Success Metrics: [Project Name]

**Business Value Metrics**:
- [ ] Cost savings: $X,XXX/year (if applicable)
- [ ] Time savings: X hours/week (if applicable)
- [ ] Improved visibility: [Metric]
- [ ] Process automation: [Metric]

**Technical Quality Metrics**:
- [ ] Test coverage: ≥80%
- [ ] Code quality: All standards met
- [ ] Documentation: AI-agent executable
- [ ] Security: No critical vulnerabilities

**Cost Metrics**:
- [ ] Total monthly cost: $XXX/month
- [ ] Cost vs. estimate: Within X% of projection
- [ ] Microsoft ecosystem: X% of services from Microsoft

**Knowledge Metrics**:
- [ ] Reusability assessment: [HIGH | MEDIUM | LOW]
- [ ] Patterns extracted: X patterns identified
- [ ] Knowledge Vault entry: Created and tagged
```

---

## Execution Examples

### Example 1: Azure OpenAI Integration

```bash
/project-plan azure-openai-integration --phase=planning --scope=integration
```

**Generated Plan**:
```
Project: Azure Open AI Integration with Notion MCP
Champion: Markus Ahling (AI, Infrastructure)
Viability: HIGH (85/100)
Estimated Cost: $250/month ($3,000/year)

Epics:
1. Discovery & Planning (Status: ✅ Complete)
   - Idea created in Ideas Registry
   - Viability assessed by @viability-assessor
   - Software identified: Azure OpenAI, GitHub Actions
   - Total cost: $250/month

2. Research Investigation (Status: ⏳ Active)
   - Research Hub entry created
   - Hypothesis: Azure OpenAI can enhance Notion semantic search
   - Methodology: POC with GPT-4 embeddings
   - Assigned: Markus Ahling (lead), Alec Fielding (Azure integration)

3. Build Development (Status: ⏳ Pending research)
   - Architecture: ADR required (@architect-supreme)
   - Tech stack: Python FastAPI, Azure OpenAI SDK, Notion MCP
   - GitHub repo: To be created
   - Azure resources: Azure OpenAI, App Service, Key Vault

Milestones:
- Week 1: ✅ Viability confirmed
- Week 2: ⏳ Research POC completion
- Week 3-4: Architecture design & ADR
- Week 5-8: Development & testing
- Week 9: Deployment to Azure
- Week 10: Knowledge Vault archival

Next Steps:
1. Complete research POC (in progress)
2. Schedule architecture review with @architect-supreme
3. Create GitHub repository
4. Provision Azure OpenAI resource
```

### Example 2: Cost Optimization Initiative

```bash
/project-plan cost-optimization-initiative --phase=discovery --scope=platform
```

**Generated Plan**:
```
Project: Quarterly Cost Optimization Initiative
Champion: Brad Wright (Finance, Business)
Viability: HIGH (90/100 - immediate savings opportunity)
Estimated Savings: $45,000/year

Epics:
1. Current State Analysis (Status: ⏳ Active)
   - Run /cost:analyze to get baseline
   - Identify unused software
   - Find consolidation opportunities
   - Check expiring contracts
   - Delegated to: @cost-analyst

2. Microsoft Ecosystem Migration (Status: ⏳ Planning)
   - Find Microsoft alternatives to third-party tools
   - Architecture design for migrations
   - Cost comparison: Current vs. Microsoft services
   - Delegated to: @architect-supreme

3. Implementation (Status: ⏳ Pending analysis)
   - Cancel unused software (immediate savings)
   - Migrate to Microsoft alternatives
   - Renegotiate contracts
   - Track in Software & Cost Tracker

4. Knowledge Preservation (Status: ⏳ Pending completion)
   - Document cost optimization strategies
   - Create playbook for quarterly reviews
   - Archive to Knowledge Vault

Milestones:
- Month 1: ✅ Analysis complete, opportunities identified
- Month 2: Migration architecture designed
- Month 3: Implement cancellations and migrations
- Month 4: Measure actual savings vs. projected

Expected Outcomes:
- $45,000 annual savings identified
- 10-15% cost reduction achieved
- Microsoft ecosystem consolidation: 85% → 95%
```

### Example 3: Governance Framework

```bash
/project-plan governance-framework --phase=planning --scope=platform
```

**Generated Plan**:
```
Project: Enterprise Governance Framework for Innovation Nexus
Champion: Alec Fielding (Security, Integrations)
Viability: MEDIUM (requires significant database changes)
Estimated Cost: $150/month (Power Automate flows)

Epics:
1. Requirements Gathering (Status: ⏳ Active)
   - Document compliance requirements (GDPR, CCPA)
   - Identify approval workflow needs
   - Define governance policies
   - Delegated to: @compliance-orchestrator

2. Notion Schema Enhancement (Status: ⏳ Pending requirements)
   - Add governance properties to all databases
   - Create approval workflow status fields
   - Implement audit trail tracking
   - Delegated to: @database-architect

3. Workflow Automation (Status: ⏳ Pending schema)
   - Power Automate approval flows
   - Email notifications for governance events
   - Integration Registry updates
   - Delegated to: @integration-specialist

4. Knowledge Preservation (Status: ⏳ Pending implementation)
   - Create governance playbook
   - Document policies and procedures
   - Archive to Knowledge Vault

Milestones:
- Month 1: Requirements documented, policies defined
- Month 2: Notion schema enhanced, properties added
- Month 3: Automation workflows deployed
- Month 4: Team training, Knowledge Vault complete

Risk Register:
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Schema changes break existing workflows | HIGH | MEDIUM | Test in sandbox database first |
| Team adoption resistance | MEDIUM | HIGH | Comprehensive training plan |
| Power Automate cost overruns | MEDIUM | LOW | Monitor flow execution monthly |
```

---

## Best Practices

### DO: Effective Project Planning

1. **Start with viability assessment**
   - Use `@viability-assessor` to evaluate before detailed planning
   - Don't over-plan low-viability initiatives

2. **Leverage existing agents**
   - Delegate specialized tasks to appropriate agents
   - Use `/orchestrate-complex` for multi-agent workflows

3. **Maintain cost transparency**
   - Link ALL software/tools to Software & Cost Tracker
   - Verify cost rollups calculate correctly
   - Monitor monthly spend against projections

4. **Document continuously**
   - Update Notion entries as work progresses
   - Create ADRs for significant architectural decisions
   - Preserve learnings in Knowledge Vault

5. **Apply Brookside BI brand voice**
   - Lead with outcomes, not features
   - Use consultative, professional tone
   - Emphasize measurable results

### DON'T: Common Mistakes

1. **Don't focus on timelines over viability**
   - Innovation Nexus is status-driven, not deadline-driven
   - Emphasize progress and viability, not due dates

2. **Don't skip viability assessment**
   - Always assess HIGH/MEDIUM/LOW before detailed planning
   - Avoid wasting effort on low-viability initiatives

3. **Don't ignore Microsoft-first strategy**
   - Evaluate Microsoft services before third-party tools
   - Document rationale if choosing non-Microsoft solution

4. **Don't forget to link software**
   - Every tool must be tracked in Software & Cost Tracker
   - Cost rollups depend on proper relations

5. **Don't archive without preserving knowledge**
   - Always run `/knowledge:archive` when completing work
   - Document what worked, what didn't, and why

---

## Integration with Other Commands

**Pre-Planning**:
- `/innovation:new-idea` - Capture initial concept
- `/cost:analyze` - Understand current cost baseline

**During Planning**:
- `/team:assign` - Identify champion and team
- `/cost:build-costs` - Estimate project costs
- `/compliance:audit` - Check licensing and security

**During Execution**:
- `/innovation:start-research` - Initiate research phase
- `/innovation:create-build` - Create build entry
- `/repo:scan-org` - Analyze repository portfolio
- `/orchestrate-complex` - Complex multi-agent workflows

**Post-Execution**:
- `/knowledge:archive` - Preserve learnings
- `/cost:analyze` - Verify actual vs. projected costs

---

## Notes for Claude Code

**When to Use This Command**:
- ✓ User mentions "plan", "project", "initiative", "roadmap"
- ✓ Complex innovation requiring multiple phases
- ✓ Need to coordinate Ideas → Research → Build lifecycle
- ✓ Requires team coordination and resource allocation

**When NOT to Use**:
- ✗ Simple, single-agent tasks (use specific commands like `/innovation:new-idea`)
- ✗ Already have existing plan (update Notion directly)
- ✗ Just exploring concepts (use research commands)

**Command Execution Approach**:
1. Parse parameters (project-name, phase, scope)
2. Invoke `@viability-assessor` first to determine if planning warranted
3. If viable, delegate to appropriate agents based on phase:
   - Discovery: `@ideas-capture` + `@cost-analyst`
   - Planning: `@workflow-router` + `@architect-supreme`
   - Research: `@research-coordinator`
   - Build: `@build-architect` + `@integration-specialist`
   - Deployment: `@integration-specialist` + `@compliance-orchestrator`
4. Generate comprehensive plan document
5. Create or update Notion entries as appropriate
6. Suggest next concrete actions

**Output Format**: Always include:
- Executive summary (2-3 sentences)
- Epic breakdown with task lists
- Milestone checkpoints (status-driven)
- Cost estimates and software links
- Risk identification
- Next steps with specific commands

---

**Best for**: Organizations requiring comprehensive project planning that drives measurable outcomes through structured innovation management workflows aligned with Microsoft ecosystem best practices, sustainable cost management, and enterprise-grade governance frameworks.
