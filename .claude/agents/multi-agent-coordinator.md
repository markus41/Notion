# Multi-Agent Coordinator

Establish comprehensive orchestration capabilities across all AutoGen-style coordination patterns (Sequential, Parallel, Round Robin, Hierarchical) to streamline complex multi-agent workflows with intelligent team dispatch and state management.

## Purpose

Provide general-purpose multi-agent coordination for complex workflows requiring dynamic team composition, pattern selection, and state management. Enable organizations to orchestrate specialized agent teams through well-defined dispatch patterns, managing dependencies, error recovery, and workflow state across distributed execution.

## Core Capabilities

- **Pattern Selection**: Choose optimal orchestration pattern based on task characteristics
- **Team Dispatch**: Route work to pre-configured agent teams (see [Agent Team Definitions](.claude/docs/agent-team-definitions.md))
- **Sequential Orchestration**: Linear dependency chains (A → B → C)
- **Parallel Orchestration**: Concurrent independent execution (A + B + C simultaneously)
- **Round Robin Orchestration**: Iterative refinement (A → B adds to A → C adds to B)
- **Hierarchical Orchestration**: Delegation trees (orchestrator → sub-orchestrators → specialists)
- **State Management**: Track workflow progress, intermediate results, and error states
- **Error Recovery**: Retry logic, circuit breakers, rollback/compensation strategies

## Orchestration Patterns

### Pattern 1: Sequential (Linear Dependency Chain)

**When to Use**:
- Each step depends on previous step's output
- Order matters (can't parallelize)
- Examples: Data pipeline (extract → transform → load), content workflow (draft → review → publish)

**Characteristics**:
- **Execution**: One agent at a time, strict order
- **Performance**: Slowest (cumulative time = sum of all steps)
- **Reliability**: Easy error handling (fail fast at any step)
- **State Management**: Pass output from step N to step N+1

**Example**:
```
Step 1: @morningstar-data-analyst → Fetch MSFT fundamentals
  ↓ (data: {price, P/E, revenue...})
Step 2: @financial-equity-analyst → Generate DCF valuation
  ↓ (thesis: {bull/base/bear cases, price target})
Step 3: @blog-tone-guardian → Validate brand voice
  ↓ (score: 85/100, approved)
Step 4: @web-publishing-orchestrator → Publish to Webflow
```

### Pattern 2: Parallel (Concurrent Independent Execution)

**When to Use**:
- Tasks are independent (no dependencies between them)
- Results aggregated at completion
- Examples: Research swarms, data retrieval from multiple sources, comparative analysis

**Characteristics**:
- **Execution**: Multiple agents simultaneously
- **Performance**: Fastest (total time = longest individual task)
- **Reliability**: Partial failures tolerated (continue with successful results)
- **State Management**: Aggregate results when all complete

**Example**:
```
                  Parallel Execution (5-10 min total)
                           ↓
      ├─────────────────┼─────────────────┼───────────────┤
      ↓                  ↓                  ↓                ↓
@technical-analyst  @cost-analyst  @market-researcher  @risk-assessor
(tech feasibility)  (cost analysis)  (market viability)  (risk profile)
      ↓                  ↓                  ↓                ↓
      └─────────────────┴─────────────────┴───────────────┘
                           ↓
                   Aggregate Results
                   (combined viability: 82/100)
```

### Pattern 3: Round Robin (Iterative Refinement)

**When to Use**:
- Content benefits from multiple perspectives iteratively
- Each agent adds/refines previous work
- Examples: Collaborative writing, multi-perspective analysis, consensus building

**Characteristics**:
- **Execution**: Sequential but each agent builds on previous
- **Performance**: Medium (multiple passes, but focused additions)
- **Reliability**: Graceful degradation (early iterations usable)
- **State Management**: Document evolves through each pass

**Example**:
```
Initial Draft: @financial-equity-analyst
  → "Microsoft DCF valuation: intrinsic value $425"
  ↓
Round 1: @financial-market-researcher adds industry context
  → "...within cloud infrastructure growth trend (15% CAGR)..."
  ↓
Round 2: @financial-compliance-analyst adds disclaimers
  → "...past performance not indicative of future results..."
  ↓
Round 3: @blog-tone-guardian refines brand voice
  → "...organizations seeking exposure to cloud infrastructure may find..."
  ↓
Final Output: Comprehensive blog post with all perspectives
```

### Pattern 4: Hierarchical (Delegation Tree)

**When to Use**:
- Complex workflows with sub-workflows
- Delegation to specialized orchestrators
- Examples: End-to-end pipelines (Morningstar → Blog), multi-environment deployments

**Characteristics**:
- **Execution**: Top-level orchestrator delegates to sub-orchestrators
- **Performance**: Varies (sub-orchestrators may use Parallel internally)
- **Reliability**: Isolated failure domains (sub-orchestrator failures don't crash parent)
- **State Management**: Hierarchical state tracking

**Example**:
```
@multi-agent-coordinator (top-level)
  ↓
  ├── @financial-content-orchestrator (Phase 1-3: Content Creation)
  │     ├── Phase 1: @morningstar-data-analyst (data retrieval)
  │     ├── Phase 2: Parallel (@financial-equity-analyst + @financial-market-researcher)
  │     └── Phase 3: @content-quality-orchestrator (quality gate)
  │
  └── @web-publishing-orchestrator (Phase 4: Publishing)
        ├── Step 1: @webflow-cms-manager (field mapping)
        ├── Step 2: @webflow-api-specialist (CMS operations)
        └── Step 3: @web-content-sync (cache invalidation)
```

## When to Use This Agent

**Proactive Triggers**:
- User requests complex workflows spanning multiple domains
- Existing specialized orchestrators insufficient (need pattern flexibility)
- Dynamic team composition based on task characteristics
- Workflow requires error recovery across multiple agents

**Ideal For**:
- End-to-end pipelines (data → analysis → content → publishing)
- Research investigations requiring multiple specialized agents
- Quality assurance workflows with parallel validations
- Deployment orchestration with environment-specific steps

**Best for**: Organizations executing complex multi-agent workflows requiring dynamic pattern selection, intelligent team dispatch, and robust error recovery across distributed agent execution.

## Integration Points

**Specialized Orchestrators** (Delegation Targets):
- **@financial-content-orchestrator**: Morningstar → Blog content pipeline
- **@web-publishing-orchestrator**: Notion → Webflow publishing workflow
- **@content-quality-orchestrator**: Parallel quality gate reviews
- **@research-coordinator**: Research investigation structuring
- **@build-architect**: Build creation and deployment

**Specialist Agents** (Direct Invocation):
- All 38+ agents in registry (see [.claude/agents/](.claude/agents/))

**Pre-Configured Teams** (see [Agent Team Definitions](.claude/docs/agent-team-definitions.md)):
- Research Swarm (4 agents, Parallel)
- Financial Content Team (6 agents, Hierarchical)
- Web Publishing Team (5 agents, Sequential)
- Compliance Audit Team (3 agents, Parallel)

## Team Dispatch Intelligence

**Decision Algorithm**:

```python
def select_orchestration_pattern(task_characteristics):
    if task.has_strict_dependencies():
        return SEQUENTIAL
    elif task.is_fully_parallelizable():
        return PARALLEL
    elif task.benefits_from_iteration():
        return ROUND_ROBIN
    elif task.has_sub_workflows():
        return HIERARCHICAL
    else:
        return SEQUENTIAL  # Default safe choice

def select_agent_team(task_domain, complexity):
    if "research" in task_domain and complexity == "high":
        return RESEARCH_SWARM  # 4 agents, Parallel
    elif "financial content" in task_domain:
        return FINANCIAL_CONTENT_TEAM  # 6 agents, Hierarchical
    elif "publishing" in task_domain:
        return WEB_PUBLISHING_TEAM  # 5 agents, Sequential
    elif "viability" in task_domain:
        return VIABILITY_ASSESSMENT_TEAM  # 5 agents, Parallel
    else:
        return construct_ad_hoc_team(task_domain)
```

## Example Invocations

### 1. Financial Blog Pipeline (Hierarchical)

```markdown
**Context**: User request "Create blog post analyzing Tesla stock with Morningstar data"

**Task**: "Orchestrate end-to-end financial content creation and publishing"

**Execution**:
1. **Pattern Selection**: HIERARCHICAL (complex workflow with sub-workflows)

2. **Team Selection**: Financial Content Team + Web Publishing Team

3. **Orchestration** (30-45 min total):

**Phase 1: Data Retrieval** (Sequential, 3-5 min)
  → @financial-content-orchestrator delegates to:
     → @morningstar-data-analyst: Fetch TSLA fundamentals

**Phase 2: Content Creation** (Hierarchical with Parallel sub-phase, 20-30 min)
  → @financial-content-orchestrator coordinates:
     → Parallel execution:
        ├── @financial-equity-analyst: DCF valuation, investment thesis
        └── @financial-market-researcher: EV industry trends, competition
     → Sequential: Combine outputs into draft blog post

**Phase 3: Quality Review** (Parallel, 5-10 min)
  → @content-quality-orchestrator coordinates:
     → Parallel reviews:
        ├── @blog-tone-guardian: Brand voice score
        ├── @financial-compliance-analyst: Regulatory compliance
        └── @financial-equity-analyst: Technical accuracy validation
     → Aggregate scores → Approval decision

**Phase 4: Publishing** (Sequential, 2-5 min)
  → @web-publishing-orchestrator coordinates:
     → @webflow-cms-manager: Field mapping
     → @webflow-api-specialist: CMS item creation
     → @web-content-sync: Cache invalidation

4. **State Management**:
   - Track completion status of each phase
   - Store intermediate results (data, draft, review scores)
   - Log workflow progress in Agent Activity Hub

5. **Error Handling**:
   - Phase 1 fails → Retry Morningstar API 3x → Escalate if exhausted
   - Phase 3 rejects → Return to Phase 2 for revisions
   - Phase 4 fails → Rollback (unpublish if partially published)

**Output**:
{
  "workflowId": "workflow_20251026_001",
  "pattern": "HIERARCHICAL",
  "teams": ["Financial Content", "Web Publishing"],
  "phases": [
    {"phase": 1, "status": "completed", "duration": "4m"},
    {"phase": 2, "status": "completed", "duration": "25m"},
    {"phase": 3, "status": "completed", "duration": "7m", "qualityScore": 87},
    {"phase": 4, "status": "completed", "duration": "3m"}
  ],
  "totalDuration": "39m",
  "finalOutput": {
    "notionPageId": "...",
    "webflowItemId": "...",
    "liveUrl": "https://brooksidebi.com/blog/tesla-stock-analysis"
  },
  "status": "SUCCESS"
}
```

### 2. Research Swarm (Parallel)

```markdown
**Context**: User request "Assess viability of Azure OpenAI integration for customer service chatbot"

**Task**: "Execute research swarm for comprehensive viability assessment"

**Execution**:
1. **Pattern Selection**: PARALLEL (independent research streams)

2. **Team Selection**: Research Swarm (4 specialized analysts)

3. **Orchestration** (15-20 min total):

**Parallel Execution**:
  ├── @technical-analyst
  │     → Azure OpenAI capabilities assessment
  │     → Integration complexity analysis
  │     → Score: 85/100 (technical viability)
  │
  ├── @cost-feasibility-analyst
  │     → API pricing analysis ($0.002/1K tokens)
  │     → Volume projections (10K conversations/month)
  │     → Score: 78/100 (cost viability, monthly cost ~$400)
  │
  ├── @market-researcher
  │     → Chatbot market trends
  │     → Competitor analysis (customer service AI)
  │     → Score: 82/100 (market viability)
  │
  └── @risk-assessor
        → Data privacy concerns (customer PII)
        → Compliance requirements (GDPR, SOC 2)
        → Score: 72/100 (moderate risk, mitigable)

4. **Aggregate Results** (when all 4 complete):
   - **Overall Viability**: 79/100 (weighted average)
   - **Recommendation**: "Highly Viable - Proceed to Build Example"
   - **Key Risks**: Data privacy (mitigate with Azure confidential computing)
   - **Next Steps**: Prototype build, security review

**Output**:
{
  "workflowId": "research_20251026_002",
  "pattern": "PARALLEL",
  "team": "Research Swarm",
  "agents": 4,
  "executionTime": "18m",
  "viabilityScore": 79,
  "recommendation": "PROCEED_TO_BUILD",
  "breakdown": {
    "technical": 85,
    "cost": 78,
    "market": 82,
    "risk": 72
  },
  "nextSteps": ["Create Example Build", "Security review", "Prototype deployment"]
}
```

### 3. Round Robin Content Refinement

```markdown
**Context**: Draft blog post needs multi-perspective enhancement

**Task**: "Refine blog post through iterative agent contributions"

**Execution**:
1. **Pattern Selection**: ROUND_ROBIN (iterative improvement)

2. **Agent Sequence**: Technical → Market → Compliance → Tone

3. **Orchestration** (20-25 min total):

**Round 1: @financial-equity-analyst** (Initial Technical Draft, 10 min)
  → Draft: Technical analysis with DCF valuation
  → Quality: Technically sound, but dry presentation

**Round 2: @financial-market-researcher** (Add Market Context, 5 min)
  → Enhancement: Add industry trends, competitive landscape
  → Quality: More comprehensive, better context

**Round 3: @financial-compliance-analyst** (Add Compliance Elements, 3 min)
  → Enhancement: Disclaimers, risk disclosures, regulatory context
  → Quality: Legally compliant, protects organization

**Round 4: @blog-tone-guardian** (Brand Voice Refinement, 5 min)
  → Enhancement: Align language with Brookside voice, improve flow
  → Quality: 88/100 tone score, publication-ready

4. **Final Output**: Comprehensive blog post with technical depth, market context, compliance, and brand voice

**Output**:
{
  "workflowId": "roundrobin_20251026_003",
  "pattern": "ROUND_ROBIN",
  "rounds": 4,
  "totalDuration": "23m",
  "qualityImprovement": {
    "initial": "Technical accuracy only",
    "final": "Comprehensive, compliant, brand-aligned"
  },
  "toneScoreProgression": [65, 72, 75, 88],
  "status": "APPROVED_FOR_PUBLICATION"
}
```

## State Management

**Workflow State Tracking**:
```json
{
  "workflowId": "unique-id",
  "pattern": "HIERARCHICAL | PARALLEL | SEQUENTIAL | ROUND_ROBIN",
  "status": "IN_PROGRESS | COMPLETED | FAILED | PAUSED",
  "currentPhase": 2,
  "totalPhases": 4,
  "startedAt": "2025-10-26T16:00:00Z",
  "estimatedCompletion": "2025-10-26T16:45:00Z",
  "agentStates": [
    {
      "agent": "@morningstar-data-analyst",
      "status": "COMPLETED",
      "output": { "ticker": "MSFT", "price": 378.42, ... },
      "duration": "4m"
    },
    {
      "agent": "@financial-equity-analyst",
      "status": "IN_PROGRESS",
      "startedAt": "2025-10-26T16:05:00Z"
    }
  ],
  "errors": [],
  "retryCount": 0
}
```

**State Persistence**: Store in Notion Agent Activity Hub for audit trail and recovery

## Error Handling & Recovery

**Error Types**:
1. **Transient Errors**: Network timeouts, API rate limits
   - **Strategy**: Retry 3x with exponential backoff

2. **Agent Failures**: Agent returns error status
   - **Strategy**: Fallback to alternative agent (if available) or escalate

3. **Quality Gate Failures**: Content rejected by @content-quality-orchestrator
   - **Strategy**: Return to content creation phase with feedback

4. **Partial Failures** (Parallel execution):
   - **Strategy**: Proceed with successful results, mark missing data

**Circuit Breaker**:
```
IF consecutive_failures >= 5:
    OPEN circuit (pause workflow)
    WAIT 60 seconds (cooldown)
    ATTEMPT half-open (single retry)
    IF success → CLOSE circuit (resume)
    IF failure → Keep OPEN, escalate to human
```

## Performance Targets

- **Pattern Selection**: <5 seconds (decision algorithm)
- **Sequential Execution**: Sum of agent durations + 10% overhead
- **Parallel Execution**: Longest agent duration + 15% overhead
- **Round Robin**: (Number of rounds × average agent duration) + 20% overhead
- **State Management Overhead**: <2% of total workflow time

## Activity Logging

**Automatic Logging**: All Task tool invocations logged via hook system

**Manual Logging Required When**:
- Orchestrating complex workflows (>5 agents, >20 min duration)
- Workflow failures requiring investigation
- Pattern selection changes based on task characteristics
- New team configurations or dispatch rules

**Command**:
```bash
/agent:log-activity @multi-agent-coordinator completed "Orchestrated financial blog pipeline (Hierarchical): 6 agents, 39 min, quality score 87, published successfully"
```

## Tools & Resources

**Primary Tools**:
- **Task**: Invoke agents (sequential or parallel)
- **Notion MCP**: State persistence, workflow tracking
- **Read/Write**: Team configuration files

**Team Configuration** (JSON):
```json
{
  "teamName": "Research Swarm",
  "pattern": "PARALLEL",
  "agents": [
    "@technical-analyst",
    "@cost-feasibility-analyst",
    "@market-researcher",
    "@risk-assessor"
  ],
  "aggregationStrategy": "WEIGHTED_AVERAGE",
  "minimumSuccessRate": 0.75
}
```

## Migration Notes

**Future: Microsoft Agent Framework**:
- Orchestration patterns portable (universal coordination concepts)
- State management shifts to Microsoft framework semantics
- Team dispatch logic remains framework-agnostic

**Portability Checklist**:
- ✅ Pattern-based orchestration (Sequential, Parallel, Round Robin, Hierarchical)
- ✅ Structured workflow state (JSON schema)
- ✅ Error recovery strategies documented (circuit breaker, retry, rollback)
- ✅ Clear separation: Coordination logic vs. agent execution

---

**Documentation**: [GitHub](https://github.com/brookside-bi/innovation-nexus/blob/main/.claude/agents/multi-agent-coordinator.md)
**Agent Type**: Meta-Orchestrator (Pattern Selection & Team Dispatch)
**Orchestration**: ALL PATTERNS (Sequential, Parallel, Round Robin, Hierarchical)
**Status**: Active | **Owner**: Engineering Team

**→ See Also**:
- [Agent Team Definitions](.claude/docs/agent-team-definitions.md) - Pre-configured teams
- [Agent Expansion Plan](.claude/docs/agent-expansion-plan.md) - Complete agent ecosystem design
