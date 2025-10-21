---
description: Enable autonomous workflow for an idea - from research through deployment with minimal human intervention
allowed-tools: Task(@notion-orchestrator:*)
argument-hint: [idea-name]
model: claude-sonnet-4-5-20250929
---

## Context

Streamline the complete innovation lifecycle by triggering autonomous workflows that coordinate research swarms, viability assessment, build generation, and Azure deployment with less than 5% human intervention.

This solution is designed to accelerate idea-to-production timelines from weeks to days through intelligent agent orchestration and automated decision-making.

## Workflow

Invoke `@notion-orchestrator` agent to execute this autonomous pipeline:

### 1. Locate Idea in Ideas Registry

```bash
# Search for idea by name
$IDEA_NAME = "$ARGUMENTS"

# Query Ideas Registry
# If not found: Error and exit
# If multiple matches: Present options to user
```

### 2. Validate Automation Eligibility

Check that idea meets autonomous workflow criteria:
- ✅ **Status**: Must be "Concept" or "Active"
- ✅ **Viability**: If already assessed, must be ≥ "Medium"
- ✅ **Champion Assigned**: Required for escalation routing
- ✅ **No Active Automation**: Prevent duplicate workflows
- ⚠️ **Effort Estimate Present**: Helps determine fast-track eligibility

If validation fails: Explain blocker and suggest remediation

### 3. Initialize Automation State

Update Ideas Registry entry:
```javascript
{
  "Status": "Active",
  "Automation Status": "In Progress",
  "Automation Stage": "Research Initiation",
  "Last Automation Event": new Date().toISOString()
}
```

Create automation tracking page (optional detailed logging):
- Linked to Ideas Registry entry
- Timeline of agent invocations
- Execution logs and decision points
- Real-time progress updates

### 4. Determine Workflow Path

**Path A: Fast-Track to Build** (High confidence, low risk)
- Condition: Viability = "High" AND Effort IN ["XS", "S"]
- Action: Skip research → Launch build pipeline directly
- Agents: @build-architect → @deployment-manager
- Duration: ~4-8 hours

**Path B: Research-First** (Default for most ideas)
- Condition: Viability = "Needs Research" OR Effort IN ["M", "L", "XL"]
- Action: Launch parallel research swarm
- Agents: @market-researcher, @technical-analyst, @cost-feasibility-analyst, @risk-assessor
- Duration: ~30 minutes research + potential build

**Path C: Immediate Escalation** (Requires human review)
- Condition: Idea flagged as high-risk OR estimated cost > $1000/month
- Action: Generate viability report and notify champion
- Agents: @viability-assessor (report generation)
- Duration: ~10 minutes + human decision time

### 5. Execute Research Swarm (Path B)

**Launch 4 parallel research agents**:

```javascript
const researchResults = await Promise.all([
  // Market Research (15-20 min)
  invoke('Task', {
    subagent_type: 'market-researcher',
    prompt: `Analyze market opportunity for: ${idea.description}
            - Demand validation
            - Competitor landscape
            - Trend analysis
            - Target audience assessment`,
    description: 'Market research for autonomous workflow'
  }),

  // Technical Feasibility (10-15 min)
  invoke('Task', {
    subagent_type: 'technical-analyst',
    prompt: `Assess technical feasibility for: ${idea.description}
            - Microsoft ecosystem fit
            - Existing pattern matching
            - Technology stack recommendation
            - Implementation complexity`,
    description: 'Technical analysis for autonomous workflow'
  }),

  // Cost Analysis (10-12 min)
  invoke('Task', {
    subagent_type: 'cost-feasibility-analyst',
    prompt: `Calculate costs for: ${idea.description}
            - Development costs (Azure, GitHub, tools)
            - Operational costs (monthly recurring)
            - ROI projection
            - Microsoft service alternatives`,
    description: 'Cost analysis for autonomous workflow'
  }),

  // Risk Assessment (8-10 min)
  invoke('Task', {
    subagent_type: 'risk-assessor',
    prompt: `Identify risks for: ${idea.description}
            - Technical blockers
            - Team capacity constraints
            - Dependency risks
            - Mitigation strategies`,
    description: 'Risk assessment for autonomous workflow'
  })
]);
```

**Update Research Hub**:
- Create new Research Hub entry (if doesn't exist)
- Link to originating Idea
- Populate with research agent findings
- Calculate composite viability score

### 6. Automated Viability Assessment

**Calculate composite score** (weighted average):
```javascript
const viabilityScore =
  (marketScore * 0.30) +        // 30% weight
  (technicalScore * 0.25) +     // 25% weight
  (costScore * 0.20) +          // 20% weight
  ((100 - riskScore) * 0.15) +  // 15% weight (risk inverted)
  (microsoftFit * 0.10);        // 10% weight
```

**Auto-decision logic**:
```javascript
if (viabilityScore > 85 && effort in ['XS', 'S'] && estimatedCost < 500) {
  // HIGH CONFIDENCE: Auto-approve build
  nextAction = 'AUTO_BUILD';
  updateIdea({
    "Viability": "High",
    "Automation Stage": "Build Pipeline Initiated"
  });

} else if (viabilityScore >= 60 && viabilityScore <= 85) {
  // MEDIUM CONFIDENCE: Human review required
  nextAction = 'ESCALATE_FOR_REVIEW';
  updateIdea({
    "Viability": "Medium",
    "Automation Status": "Requires Review"
  });
  notifyChampion(idea, viabilityReport);

} else if (viabilityScore < 60) {
  // LOW CONFIDENCE: Auto-archive with learnings
  nextAction = 'AUTO_ARCHIVE';
  updateIdea({
    "Viability": "Low",
    "Automation Stage": "Archiving with Learnings"
  });
  invokeKnowledgeCurator(idea, researchResults);
}
```

### 7. Execute Build Pipeline (if auto-approved)

**Sequential build stages**:

**Stage 1: Architecture Design** (30-60 min)
```javascript
const architecture = await invoke('Task', {
  subagent_type: 'build-architect',
  prompt: `Design system architecture for: ${idea.title}
          Research findings: ${researchResults}
          Generate:
          - High-level architecture diagram (Mermaid)
          - Technology stack with versions
          - Data models and API specifications
          - Azure resource requirements`,
  description: 'Architecture design for autonomous build'
});
```

**Stage 2: Code Generation** (1-2 hours)
```javascript
const codebase = await invoke('Task', {
  subagent_type: 'build-architect',
  prompt: `Generate complete codebase for: ${idea.title}
          Architecture: ${architecture}
          Requirements:
          - AI-agent executable documentation
          - Complete test suite (unit + integration)
          - Azure infrastructure as code (Bicep)
          - CI/CD GitHub Actions workflow`,
  description: 'Code generation for autonomous build'
});
```

**Stage 3: GitHub Repository Setup** (10-15 min)
```javascript
await invoke('Task', {
  subagent_type: 'integration-specialist',
  prompt: `Create GitHub repository and push code:
          Repo name: ${sanitize(idea.title)}
          Org: brookside-bi
          Files: ${codebase}
          Configure: Branch protection, CI/CD, secrets`,
  description: 'GitHub setup for autonomous build'
});
```

**Stage 4: Azure Deployment** (1-2 hours)
```javascript
const deployment = await invoke('Task', {
  subagent_type: 'deployment-manager',
  prompt: `Deploy to Azure:
          Build: ${idea.title}
          Infrastructure: ${architecture.azure}
          Source: ${githubRepo}
          Environment: Production
          Health checks: Enable`,
  description: 'Azure deployment for autonomous build'
});
```

**Stage 5: Post-Deployment Validation** (10-15 min)
- Health check verification
- Smoke test execution (via Playwright)
- Cost tracking setup (link Azure resources to Software Tracker)
- Documentation finalization

### 8. Final Status Update

**If Build Successful**:
```javascript
updateBuild({
  "Status": "Live",
  "Automation Status": "Complete",
  "Deployment Health": "Healthy",
  "Live URL": deployment.url,
  "GitHub Repo": githubRepo.url,
  "Total Cost": calculatedCost
});

// Notify champion
notifySuccess(idea.champion, {
  ideaName: idea.title,
  liveURL: deployment.url,
  githubURL: githubRepo.url,
  duration: executionTime,
  cost: calculatedCost
});
```

**If Escalation Required**:
```javascript
updateIdea({
  "Automation Status": "Requires Review",
  "Automation Stage": "Awaiting Human Decision"
});

// Create detailed review package
const reviewPackage = {
  viabilityScore: viabilityScore,
  researchSummary: synthesizeFindings(researchResults),
  recommendation: generateRecommendation(viabilityScore),
  costBreakdown: detailedCosts,
  risks: identifiedRisks,
  nextSteps: [
    "Proceed with build (with modifications)",
    "Conduct deeper research in [specific area]",
    "Archive idea (not viable)"
  ]
};

notifyChampion(idea.champion, reviewPackage);
```

**If Auto-Archived**:
```javascript
updateIdea({
  "Status": "Archived",
  "Automation Status": "Complete",
  "Viability": "Low"
});

// Document learnings
await invoke('Task', {
  subagent_type: 'knowledge-curator',
  prompt: `Create Knowledge Vault entry for: ${idea.title}
          Research findings: ${researchResults}
          Content type: Post-Mortem
          Key learnings: Why idea was not viable`,
  description: 'Knowledge archival for low-viability idea'
});
```

### 9. Report Execution Summary

Present comprehensive workflow report:

```
## 🚀 Autonomous Workflow Complete: [Idea Name]

**Final Status**: ✅ Live | ⚠️ Requires Review | ❌ Archived

### Execution Timeline
- 🟢 Workflow Started: [timestamp]
- 🟢 Research Complete: [timestamp] (30 minutes)
- 🟢 Viability Calculated: 88/100 (High)
- 🟢 Build Pipeline Launched: [timestamp]
- 🟢 Deployment Complete: [timestamp]
- ✅ Total Duration: 6 hours 15 minutes

### Agents Invoked
1. @market-researcher: Market score 85 (competitor analysis, demand validation)
2. @technical-analyst: Technical score 92 (Microsoft ecosystem fit confirmed)
3. @cost-feasibility-analyst: Cost score 90 ($245/month operational cost)
4. @risk-assessor: Risk score 15/100 (low risk)
5. @build-architect: Architecture + code generation successful
6. @deployment-manager: Azure deployment healthy

### Deliverables
- 🔗 Live Application: https://[idea-name].azurewebsites.net
- 📁 GitHub Repository: https://github.com/brookside-bi/[idea-name]
- 📊 Notion Build Entry: [link]
- 💰 Monthly Cost: $245 (Azure App Service S1, SQL Database Basic, Application Insights)

### Business Impact
- ⏱️ Time Saved: ~3 weeks vs. manual workflow
- 💵 Cost Efficiency: $245/month vs. estimated $450 manual approach
- 🎯 Viability: 88/100 (High confidence)
- ♻️ Reusability: Highly Reusable (identified 3 reusable patterns)

**Next Action**: None required - fully autonomous execution
```

## Parameters

- `[idea-name]`: Title or partial name of idea in Ideas Registry

## Examples

```bash
# Enable autonomous workflow for idea
/autonomous:enable-idea Automated Power BI deployment pipeline

# Start automation for research-stage idea
/autonomous:enable-idea Azure OpenAI integration

# Fast-track small idea to production
/autonomous:enable-idea Cost tracking dashboard
```

## Expected Output

**Scenario 1: Full Autonomous Success** (Viability >85, Effort XS/S)
```
🤖 Autonomous Workflow Initiated: Automated Power BI deployment pipeline

⚡ Fast-Track Eligible: Skipping research (High viability, XS effort)

🏗️ Build Pipeline Status:
  [████████████████████░░] 85% Complete

  ✅ Architecture designed (45 min)
  ✅ Code generated (1.5 hrs)
  ✅ GitHub repository created
  ✅ Azure deployment successful
  🔄 Health validation in progress...

🎯 Est. Completion: 30 minutes
💰 Total Cost: $187/month

**Live in**: 6 hrs 20 min | **No human intervention required**
```

**Scenario 2: Requires Human Review** (Viability 60-85)
```
🤖 Autonomous Workflow Initiated: Complex data integration platform

🔬 Research Complete (28 minutes):
  📊 Market Score: 78/100
  🔧 Technical Score: 82/100
  💵 Cost Score: 65/100 ($850/month estimated)
  ⚠️ Risk Score: 35/100 (moderate technical complexity)

📋 Composite Viability: 72/100 (Medium)

⚠️ **Human Review Required**
Champion: Alec Fielding

**Decision Needed**:
✅ Proceed with build (est. 2 weeks, $850/month)
🔬 Conduct deeper technical research (API integration complexity)
❌ Archive idea (cost vs. value threshold)

**Review Package**: [Link to Notion page with detailed analysis]
```

**Scenario 3: Auto-Archived** (Viability <60)
```
🤖 Autonomous Workflow Initiated: Legacy system migration

🔬 Research Complete (25 minutes):
  📊 Market Score: 45/100 (low demand)
  🔧 Technical Score: 38/100 (high complexity, poor Microsoft fit)
  💵 Cost Score: 22/100 ($2,400/month estimated)
  ⚠️ Risk Score: 78/100 (high risk - legacy dependencies)

📋 Composite Viability: 42/100 (Low)

❌ **Auto-Archived with Learnings**

**Rationale**:
- High implementation cost ($2,400/month) vs. low demand
- Poor Microsoft ecosystem alignment
- Significant technical risk (legacy integration challenges)
- Alternative approaches identified for future consideration

**Knowledge Vault**: [Link to post-mortem entry]
**Status**: Archived | **Champion Notified**: Markus Ahling
```

## Related Commands

- `/autonomous:status` - View all active automation workflows
- `/autonomous:pause [idea-name]` - Pause automation for human intervention
- `/autonomous:resume [idea-name]` - Resume paused automation
- `/innovation:new-idea` - Create new idea (manual, not automated)
- `/repo:scan-org --sync` - Analyze GitHub repos for build patterns

## Verification Steps

```bash
# Check automation status in Notion
# View Ideas Registry → [idea-name] → Automation Status property

# View execution logs
# Navigate to automation tracking page linked from idea

# Verify build deployment
# Check Example Builds database for new entry
# Verify Live URL and GitHub repository links
```

## Safety & Governance

**Automatic Safeguards**:
- ✅ Cost threshold: Auto-escalate if estimated cost > $500/month
- ✅ Effort threshold: Auto-escalate if effort estimate = L or XL
- ✅ Risk threshold: Auto-escalate if risk score > 50/100
- ✅ Viability gray zone: Auto-escalate if viability 60-85
- ✅ No duplicate automation: Check for active workflows before initiating
- ✅ Execution timeout: 8 hours max, then auto-escalate
- ✅ Error retry limit: 3 attempts with exponential backoff, then escalate

**Human Oversight Points**:
1. **Pre-execution**: Idea champion notified when automation starts
2. **Mid-execution**: Progress updates every 2 hours if workflow >4 hours
3. **Escalation**: Automatic notification if human review required
4. **Post-execution**: Success/failure summary sent to champion
5. **Emergency pause**: `/autonomous:pause` stops workflow immediately

**Audit Trail**:
- All agent invocations logged in Notion automation tracking page
- Execution timeline with timestamps
- Decision points documented (auto-approval, escalation, archival)
- Cost calculations preserved for analysis

## Best For

Organizations scaling innovation across teams who need to:
- Accelerate idea-to-production timelines from weeks to days
- Reduce human bottlenecks in innovation workflows
- Maintain strategic oversight while automating tactical execution
- Drive measurable outcomes through structured, repeatable processes
- Establish sustainable innovation practices that support long-term growth

---

This command establishes the foundation of autonomous innovation at Brookside BI, transforming Notion from a tracking system into an intelligent execution engine powered by coordinated agent swarms and automated decision-making.
