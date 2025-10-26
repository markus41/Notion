# Innovation Workflow Architecture

**Purpose**: Establish structured approaches for tracking ideas from concept through research, building, and knowledge archival.

**Best for**: Organizations scaling innovation workflows across teams using Notion as the central hub with Microsoft ecosystem integrations.

---

## Workflow Phases

```
💡 Idea (Concept) → Viability Assessment
  ↓ (if Needs Research)
🔬 Research (Active) → 4-Agent Parallel Swarm → Viability Score (0-100)
  ↓ (if >85: Auto-Approve | 60-85: Review | <60: Archive)
🛠️ Build (Active) → Autonomous Pipeline (40-60 min) → Azure Deployment
  ↓ (when Complete)
📚 Knowledge Vault (Archived for Reference)
```

---

## Phase 1: Idea Capture

**Agent**: [@ideas-capture](../agents/ideas-capture.md)

**Triggers**:
- User mentions "idea", "concept", "what if we", "we should build"
- Explicit command: `/innovation:new-idea [description]`

**Process**:
1. Search Ideas Registry for duplicates
2. Assess initial viability (High/Medium/Low/Needs Research)
3. Calculate estimated costs (if software/tools mentioned)
4. Assign champion (based on specialization)
5. Create Ideas Registry entry with relations

**Viability Criteria**:
- **High** (💎): Clear value, low complexity, Microsoft-aligned
- **Medium** (⚡): Moderate complexity, needs investigation
- **Low** (🔻): High complexity, unclear ROI
- **Needs Research** (❓): Insufficient data for decision

---

## Phase 2: Research Investigation

**Agent**: [@research-coordinator](../agents/research-coordinator.md)

**Triggers**:
- Idea status = "Needs Research"
- User mentions "research", "investigate", "feasibility"
- Explicit command: `/innovation:start-research [topic] [idea-name]`

**Process**:
1. Create Research Hub entry linked to origin Idea
2. Invoke parallel research swarm (4 agents):
   - [@market-researcher](../agents/market-researcher.md) → Market viability (0-100)
   - [@technical-analyst](../agents/technical-analyst.md) → Technical feasibility (0-100)
   - [@cost-feasibility-analyst](../agents/cost-feasibility-analyst.md) → Financial viability (0-100)
   - [@risk-assessor](../agents/risk-assessor.md) → Risk analysis (0-100, inverse)
3. Aggregate scores → Overall Viability Score (0-100)
4. Update Idea viability based on research findings
5. Recommend next steps:
   - **>85**: Auto-approve for Build phase
   - **60-85**: Request human review and decision
   - **<60**: Archive with learnings documented

**Research Deliverables**:
- Hypothesis validation
- Market opportunity analysis
- Technical approach recommendation
- Cost-benefit analysis
- Risk mitigation strategies
- Go/No-Go recommendation

---

## Phase 3: Autonomous Build Pipeline

**Completed**: October 21, 2025

**Agents**:
- [@build-architect](../agents/build-architect.md) → Architecture design + GitHub setup
- [@code-generator](../agents/code-generator.md) → Production-quality code generation
- [@deployment-orchestrator](../agents/deployment-orchestrator.md) → Azure infrastructure + CI/CD

**Triggers**:
- Research viability >85 (automatic)
- User command: `/autonomous:enable-idea [idea-name]`
- Manual: "Build [idea-name]" with high viability

**End-to-End Timeline**: 40-60 minutes (zero human intervention)

**Process**:

### 1. Architecture Design (5-10 min)
- Generate technical specifications
- Select optimal Azure services
- Design data models and API contracts
- Create Bicep infrastructure templates
- Establish CI/CD pipeline structure

### 2. Code Generation (15-25 min)
- Generate application code (Python/TypeScript/C#)
- Implement authentication (Managed Identity)
- Configure database access
- Create API endpoints with validation
- Generate comprehensive tests (unit + integration)
- Add monitoring and logging

### 3. Infrastructure Provisioning (10-15 min)
- Deploy Bicep templates to Azure
- Provision App Service/Function App/Container App
- Configure networking and security
- Set up Key Vault integration
- Establish Application Insights monitoring

### 4. Deployment & Verification (5-10 min)
- Build application artifacts
- Deploy to Azure environment
- Run smoke tests
- Verify health endpoints
- Configure auto-scaling and alerts

**Key Capabilities**:
- **Cost Optimization**: Environment-based SKU selection (87% savings: $20 dev vs $157 prod)
- **Security**: Managed Identity, RBAC, zero hardcoded secrets
- **Infrastructure as Code**: Bicep templates for reproducibility
- **Zero-Downtime CI/CD**: Blue-green deployments with rollback
- **Multi-Language Support**: Python, TypeScript, C#

**Success Metrics**:
- ✅ Deployment success rate: >95%
- ✅ Time to deployment: <60 minutes
- ✅ Security compliance: 100% (no hardcoded secrets)
- ✅ Cost optimization: 87% reduction vs. manual SKU selection

---

## Phase 4: Knowledge Archival

**Agent**: [@knowledge-curator](../agents/knowledge-curator.md)

**Triggers**:
- Build status = "Completed"
- User mentions "document learnings", "archive"
- Explicit command: `/knowledge:archive [item-name] [database]`

**Process**:
1. Extract key learnings from completed work
2. Categorize content type:
   - **Technical Doc**: Architecture, APIs, implementation details
   - **Case Study**: Problem-solution narrative with outcomes
   - **Post-Mortem**: What worked, what didn't, lessons learned
   - **Process**: Reusable workflow or methodology
   - **Tutorial**: Step-by-step guide for replication
3. Structure for AI-agent consumption (explicit, idempotent)
4. Create Knowledge Vault entry with relations
5. Tag relevant technologies and patterns
6. Mark as Evergreen (timeless) or Time-Bound (context-specific)

**Knowledge Vault Benefits**:
- Prevent reinventing solutions
- Enable pattern reuse across projects
- Preserve institutional knowledge
- Accelerate future builds (reference existing implementations)
- Support onboarding and training

---

## Workflow Decision Matrix

| Viability Score | Research Status | Next Action | Approval Required |
|----------------|-----------------|-------------|-------------------|
| >85 | Complete | Auto-approve build | No (autonomous) |
| 60-85 | Complete | Request human review | Yes |
| <60 | Complete | Archive with learnings | No (auto-archive) |
| N/A | Needs Research | Invoke research swarm | No (automatic) |
| >75 | Not Started | Fast-track to build | Yes (human confirm) |

---

## Integration Points

### Notion Databases
- **Ideas Registry** (984a4038-3e45-4a98-8df4-fd64dd8a1032)
- **Research Hub** (91e8beff-af94-4614-90b9-3a6d3d788d4a)
- **Example Builds** (a1cd1528-971d-4873-a176-5e93b93555f6)
- **Knowledge Vault** (query programmatically)

### External Systems
- **GitHub**: Repository creation, CI/CD configuration
- **Azure**: Infrastructure provisioning, app deployment
- **Software Tracker**: Cost tracking for all tools used

### Critical Relations
- Every Build MUST link:
  - Origin Idea (required)
  - Related Research (if exists)
  - All Software/Tools (for cost rollup)
- Every Research MUST link:
  - Origin Idea (required)
  - Software used during investigation

---

## Complete Lifecycle Example

```bash
# 1. Capture Idea
/innovation:new-idea "AI-powered cost optimization platform for Azure"
# → Ideas Registry entry with Viability = "Needs Research"

# 2. Start Research (automatic or manual)
/innovation:start-research "Azure cost optimization feasibility" "AI cost optimizer"
# → Research Hub entry
# → Parallel swarm: Market (85) + Technical (90) + Cost (78) + Risk (82)
# → Overall Viability: 83.75 → Review Recommended

# 3. Human Review & Approval
# Team reviews findings, approves build

# 4. Autonomous Build (40-60 min)
/autonomous:enable-idea "AI cost optimizer"
# → Architecture designed (10 min)
# → Code generated (20 min)
# → Infrastructure provisioned (15 min)
# → Deployed to Azure (10 min)
# → Status: Live in Production

# 5. Archive Learnings
/knowledge:archive "AI cost optimizer" build
# → Knowledge Vault entry: Technical Doc + Case Study
# → Tags: Azure, AI, Cost Optimization, Python, Functions
# → Status: Evergreen (reusable pattern)
```

---

## Repository Safety Hooks

**Phase 3 Security Enhancements**: 3-layer protection preventing credential leaks and enforcing brand consistency

### Hook Types
1. **pre-commit**: Secret detection (15+ patterns) + large file prevention
2. **commit-msg**: Conventional Commits enforcement + Brookside BI brand voice
3. **branch-protection**: Prevent direct pushes to main/master

**Secret Patterns Detected**:
- Azure connection strings
- Storage account keys
- Notion API tokens
- GitHub PATs
- Generic API keys (32+ hex chars)
- Private keys (PEM format)
- Database connection strings
- JWT tokens

**ROI**: 500-667% through automated quality enforcement

**Installation**: Hooks auto-installed on first commit via `/.github/hooks/install-hooks.sh`

---

## Common Issues & Solutions

### Issue: Research swarm returns low viability but idea seems valuable
**Solution**:
1. Review individual agent scores to identify specific concerns
2. Address top concerns (market validation, technical feasibility, costs, risks)
3. Re-run targeted research on problem areas
4. Consider scoping down to MVP if complexity is the issue

### Issue: Autonomous build fails during deployment
**Solution**:
1. Check Azure quota/limits for subscription
2. Verify Azure CLI authentication (`az account show`)
3. Review deployment logs in `.claude/logs/`
4. Engage [@deployment-orchestrator](../agents/deployment-orchestrator.md) for manual intervention
5. Fallback: Manual deployment via Azure Portal

### Issue: Build completes but costs are higher than expected
**Solution**:
1. Review SKU selections in Bicep templates
2. Verify environment-based tier logic (dev vs. prod)
3. Check for unnecessary premium features
4. Consult [@cost-analyst](../agents/cost-analyst.md) for optimization recommendations
5. Consider serverless alternatives (Functions vs. App Service)

---

## Success Metrics

**You're driving measurable innovation outcomes when:**
- ✅ Ideas progress through lifecycle without stalling
- ✅ Research swarm provides consistent viability scores
- ✅ Autonomous builds deploy successfully >95% of time
- ✅ Knowledge is captured and reused (measurable pattern reuse)
- ✅ Team alignment on priority ideas (clear backlog)
- ✅ Cost optimization throughout workflow (not just at end)
- ✅ Security compliance maintained (zero credential leaks)

---

**Last Updated**: 2025-10-26
**Related Documentation**:
- [Notion Schema](./notion-schema.md)
- [Agent Activity Center](./agent-activity-center.md)
- [Common Workflows](./common-workflows.md)