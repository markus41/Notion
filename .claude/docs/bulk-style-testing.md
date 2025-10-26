# Bulk Style Testing Framework

**Purpose**: Establish systematic methodology for testing all 185 agent+style combinations (37 agents × 5 styles) to build comprehensive effectiveness database enabling data-driven style recommendations and continuous optimization.

**Best for**: Organizations requiring empirical evidence for output style selection where systematic testing across entire agent portfolio drives measurable communication optimization.

---

## Overview

### Testing Scope

**37 Agents × 5 Styles = 185 Combinations**

**Agent Portfolio**:
```yaml
Innovation Lifecycle (6 agents):
  - @ideas-capture
  - @research-coordinator
  - @viability-assessor
  - @build-architect
  - @knowledge-curator
  - @archive-manager

Cost & Software Management (2 agents):
  - @cost-analyst
  - @workflow-router

Phase 3 Autonomous Pipeline (3 agents):
  - @build-architect-v2
  - @code-generator
  - @deployment-orchestrator

Research Swarm (4 agents):
  - @market-researcher
  - @technical-analyst
  - @cost-feasibility-analyst
  - @risk-assessor

Specialized Domain Agents (22 agents):
  - @integration-specialist
  - @compliance-orchestrator
  - @markdown-expert
  - @database-architect
  - @architect-supreme
  - @integration-monitor
  - @github-repo-analyst
  - @github-notion-sync
  - @documentation-sync
  - @notion-page-enhancer
  - @notion-orchestrator
  - @notion-mcp-specialist
  - @schema-manager
  - @repo-analyzer
  - @activity-logger
  - @azure-specialist (hypothetical - adjust based on actual portfolio)
  - @style-orchestrator
  - @ultrathink-analyzer
  - [Additional specialized agents...]
```

**5 Output Styles**:
- 📘 **Technical Implementer**: Developers, Engineers
- 💼 **Strategic Advisor**: Executives, Leadership
- 🎨 **Visual Architect**: Cross-functional Teams
- 🎓 **Interactive Teacher**: New Team Members, Trainees
- ✅ **Compliance Auditor**: Auditors, Compliance Officers

### Expected Testing Duration

**Per Combination**:
- Standard Test: 3-5 minutes
- UltraThink Test: 8-12 minutes

**Total Portfolio**:
- Standard: 185 × 4 min avg = **740 minutes (~12.3 hours)**
- UltraThink: 185 × 10 min avg = **1,850 minutes (~30.8 hours)**

**Recommended Approach**: Parallel batch testing over 3-4 weeks with 10-15 tests/day to avoid fatigue and enable quality assessment between batches.

---

## Testing Methodology

### Phase 1: Test Preparation (Week 0)

**Step 1.1: Create Notion Databases**

```bash
# Create Output Styles Registry
# Schema: Style Name, Style ID, Category, Target Audience, Performance Score, Usage Count, Average Satisfaction, Compatible Agents, Best Use Cases, Status

# Create Agent Style Tests
# Schema: Test Name, Agent, Style, Test Date, Task Description, Output Length, Technical Density, Formality Score, Clarity Score, Visual Elements Count, Code Blocks Count, Goal Achievement, Audience Appropriateness, Style Consistency, Generation Time, User Satisfaction, Overall Effectiveness, Test Output, Notes, Status, UltraThink Tier
```

**Step 1.2: Populate Output Styles Registry**

```javascript
const styles = [
  {
    styleName: 'Technical Implementer',
    styleId: 'technical-implementer',
    category: 'Technical',
    targetAudience: ['Developers', 'Engineers', 'Technical Leads'],
    status: 'Active'
  },
  {
    styleName: 'Strategic Advisor',
    styleId: 'strategic-advisor',
    category: 'Business',
    targetAudience: ['Executives', 'Leadership', 'Decision Makers'],
    status: 'Active'
  },
  {
    styleName: 'Visual Architect',
    styleId: 'visual-architect',
    category: 'Visual',
    targetAudience: ['Cross-functional Teams', 'Architects', 'Designers'],
    status: 'Active'
  },
  {
    styleName: 'Interactive Teacher',
    styleId: 'interactive-teacher',
    category: 'Educational',
    targetAudience: ['New Team Members', 'Trainees', 'Junior Developers'],
    status: 'Active'
  },
  {
    styleName: 'Compliance Auditor',
    styleId: 'compliance-auditor',
    category: 'Compliance',
    targetAudience: ['Auditors', 'Compliance Officers', 'Security Teams'],
    status: 'Active'
  }
];

// Sync to Notion via mcp__notion__*
```

**Step 1.3: Define Standard Test Tasks**

Create representative tasks for each agent that can be executed consistently across all 5 styles:

```yaml
@cost-analyst:
  standardTask: "Analyze Q4 software spending and provide cost optimization recommendations for executive presentation"
  expectedOutputLength: 500-800 tokens
  targetAudience: Executives

@build-architect:
  standardTask: "Design microservices architecture for customer analytics platform with real-time data processing"
  expectedOutputLength: 600-900 tokens
  targetAudience: Technical Teams + Leadership

@viability-assessor:
  standardTask: "Assess feasibility of AI-powered cost optimization platform for enterprise BI deployments"
  expectedOutputLength: 400-700 tokens
  targetAudience: Product Team

@compliance-orchestrator:
  standardTask: "Document SOC2 CC6.1 logical access controls with evidence artifacts and testing procedures"
  expectedOutputLength: 700-1000 tokens
  targetAudience: Auditors

# [Continue for all 37 agents...]
```

**Step 1.4: Set Up Testing Environment**

```bash
# Validate all agents are accessible
ls .claude/agents/

# Validate all styles are accessible
ls .claude/styles/

# Validate commands are functional
/test-agent-style --help
/style:compare --help
/style:report --help

# Test Azure Key Vault access (for any API keys needed)
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "notion-api-key"

# Configure MCP environment
.\scripts\Set-MCPEnvironment.ps1
```

### Phase 2: Baseline Testing (Weeks 1-2)

**Objective**: Establish baseline effectiveness data for all 185 combinations without UltraThink deep analysis

**Batch Structure**: 15 tests/day × 13 days = 195 tests (185 required + 10 buffer for retests)

**Daily Testing Workflow**:

```bash
# Day 1: Test @cost-analyst across all 5 styles
/test-agent-style @cost-analyst technical-implementer --sync
/test-agent-style @cost-analyst strategic-advisor --sync
/test-agent-style @cost-analyst visual-architect --sync
/test-agent-style @cost-analyst interactive-teacher --sync
/test-agent-style @cost-analyst compliance-auditor --sync

# Day 2: Test @viability-assessor across all 5 styles
/test-agent-style @viability-assessor technical-implementer --sync
/test-agent-style @viability-assessor strategic-advisor --sync
/test-agent-style @viability-assessor visual-architect --sync
/test-agent-style @viability-assessor interactive-teacher --sync
/test-agent-style @viability-assessor compliance-auditor --sync

# Day 3: Test @build-architect across all 5 styles
[...]

# Continue through all 37 agents...
```

**Batch Testing Script** (PowerShell):

```powershell
# bulk-test-baseline.ps1

$agents = @(
    '@ideas-capture',
    '@research-coordinator',
    '@viability-assessor',
    '@build-architect',
    '@knowledge-curator',
    '@archive-manager',
    '@cost-analyst',
    '@workflow-router'
    # [... all 37 agents]
)

$styles = @(
    'technical-implementer',
    'strategic-advisor',
    'visual-architect',
    'interactive-teacher',
    'compliance-auditor'
)

$testResults = @()

foreach ($agent in $agents) {
    Write-Host "Testing $agent across all styles..." -ForegroundColor Cyan

    foreach ($style in $styles) {
        Write-Host "  - Testing $agent + $style" -ForegroundColor Yellow

        # Execute test
        $result = claude invoke /test-agent-style $agent $style --sync

        # Log result
        $testResults += @{
            Agent = $agent
            Style = $style
            Timestamp = Get-Date
            Status = if ($result -match "Error") { "Failed" } else { "Passed" }
        }

        # Brief pause to avoid API rate limits
        Start-Sleep -Seconds 5
    }

    Write-Host "Completed $agent testing`n" -ForegroundColor Green
}

# Export results
$testResults | Export-Csv -Path "baseline-test-results.csv" -NoTypeInformation
Write-Host "Baseline testing complete. Results exported to baseline-test-results.csv" -ForegroundColor Green
```

**Quality Checks Between Batches**:

```bash
# After each day's testing, generate report
/style:report --timeframe=7d --format=summary

# Review for anomalies:
# - Effectiveness scores <40 (potential agent-style mismatch)
# - Generation time >10s (performance issues)
# - Consistency violations (brand voice issues)

# Re-test any failed combinations
/test-agent-style @problem-agent problem-style --interactive --sync
```

### Phase 3: UltraThink Deep Analysis (Weeks 3-4)

**Objective**: Perform extended reasoning analysis on high-priority combinations to establish tier classifications

**Priority Selection Criteria**:

```javascript
const highPriorityCombinations = combinations.filter(combo => {
  // Priority 1: High baseline effectiveness (>75)
  if (combo.baselineEffectiveness >= 75) return true;

  // Priority 2: Core agents (used frequently)
  const coreAgents = ['@cost-analyst', '@build-architect', '@viability-assessor',
                      '@markdown-expert', '@compliance-orchestrator'];
  if (coreAgents.includes(combo.agent)) return true;

  // Priority 3: Unexpected results (>20 point variance from predicted)
  if (Math.abs(combo.baselineEffectiveness - combo.predictedEffectiveness) > 20) return true;

  return false;
});

// Target: 60-80 high-priority combinations for UltraThink analysis
```

**UltraThink Testing Workflow**:

```bash
# Week 3: Test high-priority combinations
/test-agent-style @cost-analyst strategic-advisor --ultrathink --sync
/test-agent-style @build-architect visual-architect --ultrathink --sync
/test-agent-style @viability-assessor strategic-advisor --ultrathink --sync
/test-agent-style @compliance-orchestrator compliance-auditor --ultrathink --sync
# [Continue with high-priority list...]

# Week 4: Fill gaps and re-test edge cases
/test-agent-style @edge-case-agent unexpected-best-style --ultrathink --interactive --sync
```

### Phase 4: Analysis & Optimization (Week 5)

**Step 4.1: Generate Comprehensive Reports**

```bash
# Portfolio-wide performance
/style:report --timeframe=all --format=executive --export=.claude/reports/output-styles-portfolio.md

# Per-agent deep-dives (top 10 most-used agents)
/style:report --agent=@cost-analyst --timeframe=all --format=detailed --export=.claude/reports/cost-analyst-styles.md
/style:report --agent=@build-architect --timeframe=all --format=detailed --export=.claude/reports/build-architect-styles.md
# [Continue for top 10...]

# Per-style cross-agent analysis
/style:report --style=strategic-advisor --timeframe=all --format=detailed --export=.claude/reports/strategic-advisor-performance.md
/style:report --style=technical-implementer --timeframe=all --format=detailed --export=.claude/reports/technical-implementer-performance.md
# [Continue for all 5 styles...]
```

**Step 4.2: Identify Optimization Opportunities**

```sql
-- Query Notion Agent Style Tests database

-- Top 10 best combinations (Gold tier)
SELECT Agent, Style, "Overall Effectiveness", "UltraThink Tier"
FROM "Agent Style Tests"
WHERE "Overall Effectiveness" >= 90
ORDER BY "Overall Effectiveness" DESC
LIMIT 10;

-- Bottom 10 worst combinations (Needs Improvement)
SELECT Agent, Style, "Overall Effectiveness", Status
FROM "Agent Style Tests"
WHERE "Overall Effectiveness" < 60
ORDER BY "Overall Effectiveness" ASC
LIMIT 10;

-- Style performance averages
SELECT Style, AVG("Overall Effectiveness") as AvgEffectiveness, COUNT(*) as TestCount
FROM "Agent Style Tests"
GROUP BY Style
ORDER BY AvgEffectiveness DESC;

-- Agent performance averages
SELECT Agent, AVG("Overall Effectiveness") as AvgEffectiveness, COUNT(*) as TestCount
FROM "Agent Style Tests"
GROUP BY Agent
ORDER BY AvgEffectiveness DESC;
```

**Step 4.3: Update Style Definitions**

```bash
# Based on analysis, refine style transformation rules

# Example: Strategic Advisor performing poorly on technical agents
# Action: Update .claude/styles/strategic-advisor.md
# - Add rule: "When agent specialization is highly technical, maintain 40-50% technical density"
# - Add rule: "Include code examples when agent is @code-generator, @build-architect-v2"

# Re-test after refinements
/test-agent-style @technical-agent strategic-advisor --ultrathink --sync
```

---

## Testing Standards

### Quality Gates

**Before marking test as "Passed"**:
- ✅ Effectiveness score ≥ 60 (Bronze tier minimum)
- ✅ Brand consistency score ≥ 0.7 (Brookside BI voice maintained)
- ✅ No generation errors or timeouts
- ✅ Output length within expected range (±30%)
- ✅ All metrics successfully calculated

**Automatic "Needs Review" Triggers**:
- ❌ Effectiveness score < 60
- ❌ Brand consistency score < 0.6
- ❌ Generation time > 15 seconds
- ❌ Missing required output elements (for style type)

### Consistency Validation

**Cross-Test Consistency Checks**:

```javascript
// Run same test 3 times to validate consistency
const consistencyTest = async (agent, style) => {
  const results = [];

  for (let i = 0; i < 3; i++) {
    const result = await testAgentStyle(agent, style);
    results.push(result.overallEffectiveness);
    await sleep(10000); // 10s between tests
  }

  // Calculate variance
  const mean = results.reduce((a, b) => a + b) / results.length;
  const variance = results.reduce((a, b) => a + Math.pow(b - mean, 2), 0) / results.length;
  const stdDev = Math.sqrt(variance);

  // Consistency threshold: StdDev < 5 points
  if (stdDev >= 5) {
    console.warn(`⚠️ High variance detected for ${agent} + ${style}: StdDev=${stdDev.toFixed(2)}`);
    return 'Inconsistent';
  }

  return 'Consistent';
};

// Run consistency tests on high-priority combinations
```

### Documentation Requirements

**For Each Test**:
- Agent name and specialization
- Style name and category
- Task description
- Full output text
- All behavioral metrics (technical density, formality, clarity, etc.)
- All effectiveness metrics (goal achievement, appropriateness, consistency, etc.)
- Generation time and output length
- User satisfaction (if interactive mode)
- UltraThink tier and dimensional scores (if --ultrathink used)
- Status (Passed/Failed/Needs Review)
- Notes on any anomalies or insights

---

## Automation Recommendations

### Continuous Integration Approach

**GitHub Actions Workflow** (.github/workflows/style-testing-ci.yml):

```yaml
name: Continuous Style Testing

on:
  schedule:
    # Run weekly on Sundays at 2 AM
    - cron: '0 2 * * 0'
  workflow_dispatch:
    inputs:
      agent:
        description: 'Specific agent to test (or "all")'
        required: false
        default: 'all'

jobs:
  style-testing:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Configure Azure MCP
        env:
          AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
          AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          NOTION_API_KEY: ${{ secrets.NOTION_API_KEY }}
        run: |
          az login --service-principal -u ${{ secrets.AZURE_CLIENT_ID }} -p ${{ secrets.AZURE_CLIENT_SECRET }} --tenant $AZURE_TENANT_ID
          ./scripts/Set-MCPEnvironment.ps1

      - name: Run style tests
        run: |
          if [ "${{ github.event.inputs.agent }}" == "all" ]; then
            pwsh bulk-test-baseline.ps1
          else
            claude invoke /test-agent-style ${{ github.event.inputs.agent }} ? --sync
          fi

      - name: Generate report
        run: |
          claude invoke /style:report --timeframe=7d --format=executive --export=test-results.md

      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: style-test-results
          path: test-results.md
```

### Azure Function for Automated Testing

**Purpose**: Scheduled testing with results sync to Notion

```csharp
// function-app/StyleTestOrchestrator.cs

[FunctionName("StyleTestOrchestrator")]
public static async Task Run(
    [TimerTrigger("0 0 2 * * 0")] TimerInfo timer, // Every Sunday 2 AM
    ILogger log)
{
    log.LogInformation("Starting automated style testing...");

    var agents = await GetAllAgents();
    var styles = new[] { "technical-implementer", "strategic-advisor", "visual-architect",
                         "interactive-teacher", "compliance-auditor" };

    var testQueue = new Queue<TestRequest>();

    // Queue all combinations
    foreach (var agent in agents)
    {
        foreach (var style in styles)
        {
            testQueue.Enqueue(new TestRequest { Agent = agent, Style = style });
        }
    }

    // Process queue with rate limiting (max 10 concurrent)
    await ProcessTestQueue(testQueue, maxConcurrent: 10, log);

    // Generate and send weekly report
    await GenerateWeeklyReport(log);

    log.LogInformation("Automated style testing complete.");
}
```

---

## Expected Outcomes

### Success Metrics

**After Completion of All 185 Tests**:

- ✅ **100% Coverage**: All 37 agents tested across all 5 styles
- ✅ **Empirical Database**: 185+ test entries in Notion Agent Style Tests
- ✅ **Tier Classifications**: 60-80 high-priority combinations with UltraThink Gold/Silver/Bronze/Needs Improvement tiers
- ✅ **Style Performance Profiles**: Each style has average effectiveness, best agents, worst agents
- ✅ **Agent Performance Profiles**: Each agent has optimal style, acceptable alternatives, avoid styles
- ✅ **Optimization Roadmap**: Documented refinements for underperforming combinations
- ✅ **Continuous Improvement Plan**: Quarterly re-testing schedule established

### Deliverables

**Documentation**:
1. **Portfolio Report**: output-styles-portfolio.md (executive summary)
2. **Agent Reports**: 37 agent-specific performance reports
3. **Style Reports**: 5 style-specific cross-agent analyses
4. **Optimization Plan**: style-refinement-roadmap.md with prioritized improvements

**Databases**:
1. **Output Styles Registry**: 5 entries with performance scores, usage counts, compatible agents
2. **Agent Style Tests**: 185+ entries with full metrics, UltraThink tiers, test outputs

**Operational Assets**:
1. **Testing Scripts**: bulk-test-baseline.ps1, consistency-validator.ps1
2. **CI/CD Pipeline**: GitHub Actions workflow for continuous testing
3. **Azure Function**: Automated weekly testing orchestrator
4. **Monitoring Dashboard**: Power BI report for real-time test insights

---

## Risk Mitigation

### Potential Issues & Solutions

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **API Rate Limits** | High | Medium | Implement 5-10s delays between tests, batch tests across days |
| **Inconsistent Results** | Medium | High | Run consistency validation on high-priority combos (3× same test) |
| **Testing Fatigue** | High | Medium | Limit to 15 tests/day, take 2-day breaks between weeks |
| **Notion Sync Failures** | Medium | Low | Implement retry logic, manual sync backup procedure |
| **Agent Unavailability** | Low | Medium | Validate all agents before Phase 2, skip if deprecated |
| **Style Definition Changes** | Low | High | Version control styles, re-test if definitions updated |

### Rollback Procedures

**If major issues discovered mid-testing**:

1. **Pause Testing**: Stop current batch
2. **Root Cause Analysis**: Identify systemic issue (agent error, style bug, metric calculation issue)
3. **Fix Issue**: Update code/styles/metrics
4. **Invalidate Affected Tests**: Mark tests since issue as "Needs Retest"
5. **Resume with Validation**: Test 5 combinations to verify fix, then resume full testing

---

## Continuous Improvement

### Quarterly Re-Testing Schedule

**Q1 2026**: Re-test all combinations after style refinements from initial results
**Q2 2026**: Spot-check top 50 combinations to validate maintained Gold/Silver tier
**Q3 2026**: Full 185-combination re-test to establish yearly trend data
**Q4 2026**: Re-test new agents added during year, spot-check existing combos

### New Agent Onboarding

**When new agent added to portfolio**:

```bash
# Test across all 5 styles
/test-agent-style @new-agent technical-implementer --sync
/test-agent-style @new-agent strategic-advisor --sync
/test-agent-style @new-agent visual-architect --sync
/test-agent-style @new-agent interactive-teacher --sync
/test-agent-style @new-agent compliance-auditor --sync

# Run UltraThink on best 2 performers
/test-agent-style @new-agent best-style-1 --ultrathink --sync
/test-agent-style @new-agent best-style-2 --ultrathink --sync

# Update portfolio count: 185 → 190 combinations (38 agents × 5 styles)
```

---

**Best for**: Organizations requiring systematic communication optimization where bulk testing establishes empirical effectiveness database enabling data-driven style selection, continuous improvement, and measurable quality enhancement across entire AI agent portfolio.
