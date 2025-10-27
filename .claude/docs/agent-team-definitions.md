# Agent Team Definitions & Orchestration Patterns

**Created**: 2025-10-26
**Purpose**: Establish structured team-based agent workflows supporting AutoGen-style orchestration patterns for complex multi-agent coordination

**Best for**: Organizations scaling AI agent capabilities across complex workflows requiring hierarchical coordination, parallel execution, and systematic delegation

---

## Orchestration Pattern Reference

### Pattern 1: Sequential (Linear Dependency Chain)

**Description**: Agents execute in strict order where each step depends on the completion of the previous step.

**When to Use**:
- Build and deployment pipelines (design → code → deploy → monitor)
- Content creation workflows (data → analysis → writing → review → publish)
- Research-to-build lifecycle (research → viability → build → archive)

**Example**:
```
Step 1: @architect-supreme → Design architecture
  ↓
Step 2: @code-generator → Generate code
  ↓
Step 3: @deployment-orchestrator → Deploy to Azure
  ↓
Step 4: @observability-specialist → Configure monitoring
```

**Characteristics**:
- ✅ Clear execution order
- ✅ Easy to debug (linear flow)
- ✅ Predictable duration
- ❌ Slower than parallel (no concurrency)
- ❌ Bottlenecks if one step fails

---

### Pattern 2: Parallel (Concurrent Independent Execution)

**Description**: Multiple agents execute simultaneously on independent tasks, results aggregated at completion.

**When to Use**:
- Research swarms (technical, cost, market, risk analysis)
- Data retrieval from multiple sources
- Comparative analysis across competitors
- Quality assurance checks (brand, legal, technical)

**Example**:
```
Parallel Execution:
  ├─ @technical-analyst (technical feasibility) ──┐
  ├─ @cost-feasibility-analyst (cost analysis) ───┤
  ├─ @market-researcher (market viability) ───────┤
  └─ @risk-assessor (risk analysis) ──────────────┤
                                                  ↓
                                          Aggregate Results
                                                  ↓
                                    @research-coordinator (final decision)
```

**Characteristics**:
- ✅ Fastest execution (concurrent)
- ✅ Maximizes agent utilization
- ✅ Fault-tolerant (one failure doesn't block others)
- ❌ Requires result aggregation logic
- ❌ More complex error handling

---

### Pattern 3: Round Robin (Iterative Contribution)

**Description**: Agents take turns contributing to a shared work product, each building on previous agent's output.

**When to Use**:
- Collaborative document writing (draft → review → edit → finalize)
- Iterative design reviews (architect → reviewer → refiner)
- Multi-perspective analysis (agent A perspective → agent B perspective → synthesis)

**Example**:
```
Round 1: @technical-analyst → Technical assessment
  ↓
Round 2: @cost-feasibility-analyst → Add cost analysis
  ↓
Round 3: @market-researcher → Add market context
  ↓
Round 4: @viability-assessor → Synthesize and decide
```

**Characteristics**:
- ✅ Collaborative refinement
- ✅ Each agent benefits from previous context
- ✅ Good for iterative improvement
- ❌ Slower than parallel
- ❌ Can create dependency bottlenecks

---

### Pattern 4: Hierarchical (Delegation Tree)

**Description**: Top-level orchestrator delegates to sub-orchestrators, which coordinate specialist agents.

**When to Use**:
- Complex multi-stage workflows (e.g., financial content pipeline)
- Workflows with distinct phases (e.g., publish workflow: validate → review → publish → cache)
- Large agent teams (>5 agents) needing coordination

**Example**:
```
@financial-content-orchestrator (top-level)
  ├─ Phase 1: Data Retrieval
  │   └─ @morningstar-data-analyst
  ├─ Phase 2: Analysis
  │   ├─ @financial-equity-analyst
  │   └─ @financial-market-researcher
  ├─ Phase 3: Quality Review
  │   └─ @content-quality-orchestrator (sub-orchestrator)
  │       ├─ @blog-tone-guardian
  │       ├─ @financial-compliance-analyst
  │       └─ @financial-equity-analyst (technical review)
  └─ Phase 4: Publishing
      └─ @web-publishing-orchestrator (sub-orchestrator)
          ├─ @notion-webflow-sync
          └─ @web-content-sync
```

**Characteristics**:
- ✅ Scalable to large teams
- ✅ Clear separation of concerns
- ✅ Sub-workflows reusable across contexts
- ❌ Most complex to implement
- ❌ Potential communication overhead

---

## Defined Agent Teams

### Team 1: Research Swarm Team

**Purpose**: Comprehensive viability assessment for innovation ideas through parallel multi-dimensional analysis

**Orchestrator**: `@research-coordinator`

**Pattern**: Parallel → Aggregation

**Team Members**:
- `@technical-analyst` - Technical feasibility (0-100 score)
- `@cost-feasibility-analyst` - Cost viability (0-100 score)
- `@market-researcher` - Market opportunity (0-100 score)
- `@risk-assessor` - Risk analysis (0-100 inverse score)

**Workflow**:
```
User/System: New idea requires viability assessment
  ↓
@research-coordinator initiates parallel swarm
  ↓
Parallel Execution (15-20 min each):
  ├─ @technical-analyst → Technical Score + Report
  ├─ @cost-feasibility-analyst → Cost Score + Report
  ├─ @market-researcher → Market Score + Report
  └─ @risk-assessor → Risk Score + Report
  ↓
@research-coordinator aggregates:
  - Overall Viability Score = Weighted average
  - Confidence Level = Based on score variance
  - Recommendation = Proceed | More Research | Archive
  ↓
Update Research Hub in Notion with findings
```

**Performance Targets**:
- Execution Time: 15-20 minutes (parallel)
- Success Rate: >95%
- Confidence: ≥80% achieve "High" or "Moderate"
- Actionability: ≥90% enable clear decision

**Invocation**:
```bash
/innovation:start-research "Azure OpenAI integration for automated insights" "AI-powered BI enhancement"
```

---

### Team 2: Financial Content Team

**Purpose**: Morningstar financial data → equity analysis → market context → blog content with compliance review

**Orchestrator**: `@financial-content-orchestrator`

**Pattern**: Sequential (data dependencies) with Parallel (quality review)

**Team Members**:
- `@morningstar-data-analyst` - API data retrieval
- `@financial-equity-analyst` - Valuation and analysis
- `@financial-market-researcher` - Industry and market context
- `@financial-compliance-analyst` - Legal/regulatory review
- `@blog-tone-guardian` - Brand voice validation
- `@content-quality-orchestrator` - Quality gate orchestration

**Workflow**:
```
User: "Create blog post analyzing Apple (AAPL) valuation"
  ↓
@financial-content-orchestrator coordinates:
  ↓
Step 1: @morningstar-data-analyst
  → Fetch AAPL fundamentals, ratios, financials (3 min)
  ↓
Step 2: @financial-equity-analyst
  → Perform DCF valuation, competitive analysis (15 min)
  ↓
Step 3: @financial-market-researcher
  → Add tech sector context, industry trends (12 min)
  ↓
Step 4: [User/AI writes blog draft using analysis]
  ↓
Step 5: @content-quality-orchestrator → Parallel Review:
  ├─ @blog-tone-guardian (brand compliance)
  ├─ @financial-compliance-analyst (legal review)
  └─ @financial-equity-analyst (technical accuracy)
  ↓
Aggregate results → Approval decision (4 min)
  ↓
If approved → Hand off to @web-publishing-orchestrator
```

**Performance Targets**:
- Total Duration: 30-45 minutes
- Quality Pass Rate: >85% first-time approval
- Legal Compliance: 100% (zero regulatory risks)
- Brand Score: >90 average

**Invocation**:
```bash
user: "Analyze Microsoft (MSFT) vs Salesforce (CRM) for enterprise SaaS case study"
assistant: "Engaging @financial-content-orchestrator to coordinate data retrieval, comparative analysis, market research, and compliance review"
```

---

### Team 3: Web Publishing Team

**Purpose**: Notion content → quality gates → Webflow publishing → cache invalidation

**Orchestrator**: `@web-publishing-orchestrator`

**Pattern**: Sequential with Parallel (quality checks)

**Team Members**:
- `@notion-mcp-specialist` - Reads Notion content
- `@content-quality-orchestrator` - Quality gates (if financial content)
- `@blog-tone-guardian` - Brand compliance
- `@webflow-cms-manager` - Field mapping strategy
- `@webflow-api-specialist` - Webflow API operations
- `@notion-webflow-sync` - Sync execution
- `@web-content-sync` - Cache invalidation
- `@webflow-designer` - Component/layout validation (optional)

**Workflow**:
```
Notion Update: PublishToWeb = true (webhook trigger)
  ↓
@web-publishing-orchestrator initiates
  ↓
Step 1: Validation
  └─ @notion-mcp-specialist → Check all required fields populated
  ↓
Step 2: Quality Assurance (Parallel)
  ├─ @blog-tone-guardian → Brand voice check (if blog content)
  └─ @content-quality-orchestrator → Full review (if financial)
  ↓
Step 3: Asset Preparation
  ├─ Image optimization (resize, compress)
  ├─ CDN upload (Azure Front Door)
  └─ Generate responsive variants
  ↓
Step 4: Field Mapping
  ├─ @webflow-cms-manager → Validate mapping rules
  └─ @notion-webflow-sync → Execute field transformations
  ↓
Step 5: Publish
  └─ @webflow-api-specialist → Create/update CMS item, publish
  ↓
Step 6: Cache Invalidation
  ├─ @web-content-sync → Invalidate Redis keys
  └─ CDN purge (Azure Front Door)
  ↓
Step 7: Verification
  └─ Verify content live, update sync status in Notion
```

**Performance Targets**:
- Publish Latency: <30 seconds per item
- Batch Throughput: 20 items/minute
- Success Rate: >99% with auto-retry
- Cache Hit Ratio: >95% after sync

**Invocation**:
```bash
user: "Publish all pending Example Builds to Webflow portfolio"
assistant: "Engaging @web-publishing-orchestrator to batch publish 7 builds with validation, quality checks, and cache invalidation"
```

---

### Team 4: Build Pipeline Team

**Purpose**: Idea → architecture → code → deployment → monitoring for autonomous build creation

**Orchestrator**: `@build-architect` (Phase 3 enhanced)

**Pattern**: Sequential (strict build dependencies)

**Team Members**:
- `@build-architect` - Architecture design and build orchestration
- `@code-generator` - Production-quality code generation
- `@deployment-orchestrator` - Azure infrastructure provisioning and deployment
- `@observability-specialist` - Monitoring and telemetry configuration
- `@knowledge-curator` - Documentation and learnings archival

**Workflow**:
```
Idea Approved (Viability ≥85) → Auto-trigger Build
  ↓
@build-architect coordinates:
  ↓
Step 1: @build-architect
  → Design architecture (tech stack, services, patterns) (10 min)
  ↓
Step 2: @code-generator
  → Generate code (API, frontend, tests, Bicep/Terraform) (15 min)
  ↓
Step 3: @deployment-orchestrator
  → Provision Azure infrastructure, deploy application (12 min)
  ↓
Step 4: @observability-specialist
  → Configure Application Insights, alerts, dashboards (5 min)
  ↓
Step 5: @knowledge-curator
  → Document architecture, learnings, patterns (8 min)
  ↓
Total Duration: 40-60 minutes (autonomous)
  ↓
Update Example Build in Notion → Status = Completed
```

**Performance Targets**:
- Total Duration: 40-60 minutes
- Success Rate: >95% (autonomous deployment)
- Cost Optimization: 87% savings (environment-based SKUs)
- Security: 100% (zero hardcoded secrets)

**Invocation**:
```bash
/autonomous:enable-idea "Customer analytics dashboard with Azure OpenAI"
```

---

### Team 5: Knowledge Capture Team

**Purpose**: Completed work → learnings extraction → Knowledge Vault archival with reusable patterns

**Orchestrator**: `@knowledge-curator`

**Pattern**: Sequential (with optional parallel research for context)

**Team Members**:
- `@knowledge-curator` - Knowledge extraction and structuring
- `@markdown-expert` - Documentation formatting
- `@mermaid-diagram-expert` - Visual diagrams for architecture
- `@archive-manager` - Lifecycle completion and status updates

**Workflow**:
```
Work Completed (Idea/Research/Build)
  ↓
@knowledge-curator initiates
  ↓
Step 1: @knowledge-curator
  → Extract key learnings, decisions, patterns
  → Identify reusable components/approaches
  ↓
Step 2: @markdown-expert
  → Structure documentation with proper formatting
  → AI-agent friendly structure (explicit, idempotent)
  ↓
Step 3: @mermaid-diagram-expert (if architecture/workflow)
  → Generate architecture diagrams
  → Create workflow visualizations
  ↓
Step 4: Create Knowledge Vault entry
  → Content Type (Case Study | Technical Doc | Process | Post-Mortem)
  → Link to origin (Idea/Research/Build)
  → Tag with technologies and patterns
  ↓
Step 5: @archive-manager
  → Update origin item status (Completed/Archived)
  → Preserve relations and metadata
```

**Performance Targets**:
- Documentation Quality: >90% AI-agent parseable
- Pattern Reuse: Track knowledge references in future builds
- Completeness: 100% of completed work archived
- Searchability: <5s to find relevant pattern

**Invocation**:
```bash
/knowledge:archive "customer-segmentation-prototype" build
```

---

### Team 6: Deployment & Infrastructure Team

**Purpose**: Infrastructure provisioning, application deployment, environment management for Azure resources

**Orchestrator**: `@deployment-orchestrator`

**Pattern**: Sequential (infrastructure before app deployment)

**Team Members**:
- `@deployment-orchestrator` - Bicep/Terraform execution, Azure deployment
- `@infrastructure-optimizer` - Cost and performance optimization
- `@observability-specialist` - Monitoring and alerting configuration
- `@security-automation` - Security posture validation

**Workflow**:
```
Code Ready for Deployment
  ↓
@deployment-orchestrator coordinates:
  ↓
Step 1: Infrastructure Provisioning
  └─ @deployment-orchestrator
     → Execute Bicep/Terraform templates
     → Create resource groups, services, networking
     → Configure Managed Identity, Key Vault references
  ↓
Step 2: Infrastructure Optimization
  └─ @infrastructure-optimizer
     → Validate SKU selections (environment-based)
     → Configure auto-scaling rules
     → Optimize cost/performance trade-offs
  ↓
Step 3: Application Deployment
  └─ @deployment-orchestrator
     → Deploy application code to Azure services
     → Configure environment variables (from Key Vault)
     → Run database migrations (if applicable)
  ↓
Step 4: Security Validation
  └─ @security-automation
     → Verify Managed Identity assignments
     → Check Key Vault permissions
     → Validate network security groups
  ↓
Step 5: Monitoring Configuration
  └─ @observability-specialist
     → Configure Application Insights
     → Create alert rules (errors, performance)
     → Set up dashboards
  ↓
Step 6: Smoke Testing
  └─ @deployment-orchestrator
     → Verify endpoints accessible
     → Check health checks passing
     → Validate database connectivity
```

**Performance Targets**:
- Deployment Duration: 8-15 minutes
- Success Rate: >98%
- Security Compliance: 100% (zero credential leaks)
- Cost Optimization: >80% savings (dev/test environments)

**Invocation**:
```bash
# Automated via @build-architect pipeline
# Or manual: /build:deploy "cost-tracking-function"
```

---

### Team 7: Compliance & Governance Team

**Purpose**: Security audits, compliance validation, governance policy enforcement

**Orchestrator**: `@compliance-orchestrator`

**Pattern**: Parallel (independent compliance checks)

**Team Members**:
- `@compliance-orchestrator` - Compliance workflow coordination
- `@security-automation` - Security posture assessment
- `@financial-compliance-analyst` - Financial/regulatory compliance
- `@risk-assessor` - Risk analysis and mitigation
- `@cost-analyst` - Budget and cost compliance

**Workflow**:
```
Compliance Audit Triggered (scheduled or on-demand)
  ↓
@compliance-orchestrator coordinates:
  ↓
Parallel Execution:
  ├─ @security-automation
  │   → Azure Security Center assessment
  │   → Key Vault access audit
  │   → Managed Identity permissions review
  │   → Network security validation
  │
  ├─ @financial-compliance-analyst
  │   → Financial content compliance (if blog)
  │   → Data licensing review (Morningstar, Bloomberg)
  │   → Disclosure requirements validation
  │
  ├─ @risk-assessor
  │   → Identify operational risks
  │   → Assess technical debt
  │   → Evaluate dependency vulnerabilities
  │
  └─ @cost-analyst
      → Budget variance analysis
      → Cost allocation review
      → License utilization audit
  ↓
Aggregate Results:
  → Overall Compliance Score (0-100)
  → Critical Issues (must fix)
  → Warnings (should address)
  → Recommendations (nice-to-have)
  ↓
Generate Compliance Report → Store in Knowledge Vault
  ↓
If Critical Issues → Escalate to Team Lead
```

**Performance Targets**:
- Audit Duration: 15-25 minutes (parallel)
- Critical Issue Detection: >95% (low false negatives)
- Compliance Pass Rate: >90% (first-time)
- Remediation Guidance: 100% actionable recommendations

**Invocation**:
```bash
/compliance:audit monthly
# Or automated via scheduled Azure Function
```

---

### Team 8: Documentation Automation Team

**Purpose**: Multi-file documentation updates with diagrams, PR creation, and Notion sync

**Orchestrator**: `@documentation-orchestrator`

**Pattern**: Hierarchical (delegates to specialized sub-teams)

**Team Members**:
- `@documentation-orchestrator` - Top-level workflow coordination
- `@markdown-expert` - Markdown formatting and structure
- `@mermaid-diagram-expert` - Diagram generation
- `@documentation-sync` - GitHub ↔ Notion synchronization
- `@notion-page-enhancer` - Visual enhancement for Notion pages
- `@github-repo-analyst` - Repository analysis for context

**Workflow**:
```
User: "Update documentation for webhook architecture with diagrams"
  ↓
@documentation-orchestrator coordinates:
  ↓
Step 1: Context Gathering
  └─ @github-repo-analyst
     → Analyze repository structure
     → Identify related files
     → Extract existing documentation
  ↓
Step 2: Content Generation (Parallel if multiple files)
  ├─ @markdown-expert → Structure content with hierarchy
  └─ @mermaid-diagram-expert → Generate architecture diagrams
  ↓
Step 3: Documentation Update
  └─ @markdown-expert → Update markdown files
  ↓
Step 4: GitHub Integration
  ├─ Create feature branch
  ├─ Commit changes
  └─ Create Pull Request with summary
  ↓
Step 5: Notion Synchronization (Optional)
  ├─ @documentation-sync → Sync to Notion Knowledge Vault
  └─ @notion-page-enhancer → Add visual enhancements
```

**Performance Targets**:
- Multi-file updates: 5-10 files in single execution
- PR creation: <3 minutes (commit + PR)
- Diagram quality: >90% accurate representations
- Notion sync: <2 minutes per page

**Invocation**:
```bash
/docs:update-complex ".claude/docs/" "Update MCP configuration guide with authentication flow diagram" --diagrams --create-pr --sync-notion
```

---

## Team Coordination Patterns

### Pattern A: Sequential Handoff

**Use Case**: When Team 1's output is required input for Team 2

**Example**: Financial Content → Web Publishing
```
@financial-content-orchestrator completes blog draft
  ↓
Hands off to @web-publishing-orchestrator
  ↓
@web-publishing-orchestrator publishes to Webflow
```

**Implementation**:
```markdown
## Handoff Protocol

**From**: @financial-content-orchestrator
**To**: @web-publishing-orchestrator

**Deliverables**:
- Notion page ID (blog draft)
- Quality review results (approval status)
- Metadata (category, tags, publish date)

**Handoff Command**:
/agent:log-activity @financial-content-orchestrator handed-off "Financial analysis blog draft approved and ready for publishing. Notion page: [page-id]. Quality scores: Brand 91/100, Legal ✅, Technical ✅. Handed off to @web-publishing-orchestrator for Webflow publishing."
```

---

### Pattern B: Parallel Collaboration

**Use Case**: Multiple teams work on independent aspects of same project

**Example**: Build Pipeline + Documentation + Compliance (simultaneous)
```
New Build Deployed
  ↓
Trigger 3 Teams in Parallel:
  ├─ @documentation-orchestrator → Generate docs
  ├─ @compliance-orchestrator → Security audit
  └─ @knowledge-curator → Extract learnings
  ↓
All complete → Mark build as Production Ready
```

**Implementation**:
```bash
# Claude Code parallel agent invocation
assistant: "I'll engage 3 teams in parallel to finalize the build"
<function_calls>
<Task subagent_type="documentation-orchestrator" .../>
<Task subagent_type="compliance-orchestrator" .../>
<Task subagent_type="knowledge-curator" .../>