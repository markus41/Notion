# /agent:assign-work - Intelligent Agent Selection Based on Work Description

**Category**: Agent Management
**Related Databases**: Agent Registry, Ideas Registry, Research Hub, Example Builds, Agent Activity Hub
**Agent Compatibility**: @workflow-router, @team-coordinator, @claude-main
**Last Updated**: 2025-10-26

---

## Purpose

Establish intelligent agent selection to streamline task delegation and improve workflow efficiency through automated analysis of work description keywords and domain patterns. This command analyzes the nature of requested work, identifies the optimal specialized agent based on capabilities and performance history, and routes assignments to maximize execution quality—designed to drive measurable productivity outcomes for organizations scaling automation across teams.

**Best for**: Organizations requiring systematic agent delegation where work descriptions are analyzed for capability matching, enabling efficient routing to specialized agents without manual agent selection overhead.

---

## Parameters

### Required Parameters

- **`work-description`** (type: string): Detailed description of the work to be performed, including context, objectives, and expected deliverables. Minimum 20 characters. The system analyzes keywords, technical terms, and domain indicators to match with appropriate agents.

### Optional Parameters

- **`--domain`** (type: string, default: "auto-detect"): Force selection from specific domain category. Valid options: `innovation` | `cost` | `research` | `build` | `compliance` | `documentation` | `deployment`. When omitted, domain is automatically detected from work description keywords.
- **`--priority`** (type: string, default: "normal"): Work priority level affecting agent selection criteria. Valid options: `urgent` | `normal` | `low`. Urgent tasks favor agents with faster average completion times.
- **`--show-alternatives`** (type: boolean, default: false): Display top 3 agent recommendations instead of just the best match, allowing user to override automatic selection.

### Parameter Validation Rules

- `work-description` must contain meaningful content (not just whitespace or punctuation)
- `work-description` should include action verbs and domain-specific terminology for accurate matching
- `--domain` must match one of the seven predefined categories exactly (case-insensitive)
- `--priority` affects ranking algorithm: urgent prioritizes speed, normal prioritizes quality, low prioritizes cost-effectiveness

---

## Workflow

This command executes intelligent agent matching through multi-factor analysis:

### Step 1: Work Description Analysis
- Parse work description for domain keywords and technical indicators
- Extract action verbs: "analyze" → cost domain, "build" → build domain, "research" → research domain
- Identify technology mentions: "Azure", "Notion", "GitHub", "Power BI", etc.
- Classify work type: creation, analysis, deployment, documentation, optimization

### Step 2: Domain Detection
- **Innovation Domain**: Keywords: "idea", "concept", "innovation", "opportunity", "new", "capture"
  - Primary agents: @ideas-capture, @viability-assessor
- **Cost Domain**: Keywords: "cost", "spend", "budget", "expense", "optimize", "savings", "ROI"
  - Primary agents: @cost-analyst, @procurement-specialist
- **Research Domain**: Keywords: "research", "investigate", "feasibility", "analysis", "evaluate", "study"
  - Primary agents: @research-coordinator, @viability-assessor, @research-swarm
- **Build Domain**: Keywords: "build", "develop", "create", "implement", "deploy", "architecture"
  - Primary agents: @build-architect, @code-generator, @deployment-orchestrator
- **Compliance Domain**: Keywords: "compliance", "audit", "security", "policy", "governance", "regulatory"
  - Primary agents: @compliance-orchestrator, @security-automation
- **Documentation Domain**: Keywords: "document", "write", "markdown", "README", "guide", "tutorial"
  - Primary agents: @markdown-expert, @documentation-specialist
- **Deployment Domain**: Keywords: "deploy", "release", "production", "Azure", "infrastructure"
  - Primary agents: @deployment-orchestrator, @devops-specialist

### Step 3: Agent Registry Query
- **Notion Operation**: `notion-search`
- **Target Database**: Agent Registry (ID: 5863265b-eeee-45fc-ab1a-4206d8a523c6)
- **Query**: Filter by detected domain or `--domain` parameter
- **Fetch**: Retrieve agent specializations, performance scores, average duration

### Step 4: Agent Scoring
Calculate composite score for each candidate agent:
```javascript
Score = (Capability Match × 0.40) +
        (Performance Score × 0.30) +
        (Availability × 0.20) +
        (Priority Alignment × 0.10)

Where:
- Capability Match: 0-100 (keyword overlap with specializations)
- Performance Score: 0-100 (from Agent Registry.Performance Score)
- Availability: 0-100 (inverse of current active sessions)
- Priority Alignment: 0-100 (urgent → faster agents, low → cost-effective agents)
```

### Step 5: Recommendation Generation
- Rank agents by composite score (descending)
- If `--show-alternatives=true`, display top 3 agents with scores
- Otherwise, select highest-scoring agent
- Format recommendation with:
  - Agent name and specialization
  - Confidence score (0-100)
  - Why this agent was selected (capability keywords matched)
  - Estimated completion time (based on historical average)
  - Alternative agents (if `--show-alternatives` enabled)

### Step 6: User Confirmation
- Display recommendation to user
- Provide invocation command: `Task(@agent-name, "work-description")`
- If alternatives shown, allow user to select different agent
- Log selection decision to Agent Activity Hub

### Step 7: Activity Logging
- **Notion Operation**: `notion-create-pages`
- **Target Database**: Agent Activity Hub (ID: 7163aa38-f3d9-444b-9674-bde61868bd2b)
- **Properties Set**:
  - `Activity Title`: "Work Assignment - [work-description-summary] - YYYYMMDD"
  - `Agent`: Relation to selected agent
  - `Status`: "Pending" (not yet executed)
  - `Work Description`: Full work description
  - `Session Start`: Current timestamp
  - `Notes`: Includes scoring breakdown and alternatives considered

---

## Examples

### Example 1: Cost Analysis Work Assignment

```bash
/agent:assign-work "Analyze Q4 software spending across all active subscriptions and identify consolidation opportunities to reduce monthly costs by 15%"
```

**Context**: Finance team needs comprehensive cost optimization analysis before annual budget planning

**Expected Outcome**:
- Domain detected: **Cost** (keywords: "analyze", "spending", "costs", "reduce")
- Recommended agent: **@cost-analyst** (Confidence: 95%)
- Why selected: Specializes in software spend analysis, cost optimization, and ROI calculations
- Estimated completion: 15-20 minutes
- Invocation command provided: `Task(@cost-analyst, "Analyze Q4 software spending...")`

**Notion Updates**:
- **Agent Activity Hub**: New entry "Work Assignment - Q4 cost analysis - 20251026" with Status="Pending"
- **Scoring Breakdown**:
  - @cost-analyst: 95 (Capability: 100, Performance: 92, Availability: 95, Priority: 90)
  - @procurement-specialist: 78 (Capability: 85, Performance: 88, Availability: 80, Priority: 60)

---

### Example 2: Build Work with Alternatives Display

```bash
/agent:assign-work "Design microservices architecture for customer data platform using Azure services with event-driven integration patterns" --show-alternatives
```

**Context**: Need architecture design for complex Azure project, want to see multiple agent options

**Expected Outcome**:
- Domain detected: **Build** (keywords: "design", "architecture", "Azure", "microservices")
- Top 3 Recommendations:
  1. **@build-architect** (Confidence: 92%) - Architecture design specialist, Azure expertise
  2. **@architect-supreme** (Confidence: 88%) - System architecture focus, integration patterns
  3. **@cloud-infrastructure** (Confidence: 75%) - Azure infrastructure, deployment automation

**Notion Updates**:
- **Agent Activity Hub**: Log entry with all 3 alternatives and scoring details
- User can select any of the 3 recommendations

---

### Example 3: Urgent Research Assignment

```bash
/agent:assign-work "Investigate feasibility of migrating legacy Power BI reports to Microsoft Fabric with cost comparison and timeline estimate" --domain=research --priority=urgent
```

**Context**: Executive needs quick feasibility assessment for strategic decision due tomorrow

**Expected Outcome**:
- Domain: **Research** (forced via parameter, validated by keywords "investigate", "feasibility")
- Priority: **Urgent** (favors agents with faster completion times)
- Recommended agent: **@research-coordinator** (Confidence: 90%)
- Estimated completion: 30-45 minutes (faster than @viability-assessor's 60 min average)
- Why selected: Fast turnaround on feasibility studies, Microsoft ecosystem expertise

**Notion Updates**:
- **Agent Activity Hub**: Entry marked with Priority="Urgent", expected completion timestamp
- **Scoring**: Priority Alignment weighted higher (20% instead of 10%) for urgent work

---

### Example 4: Ambiguous Work Description (Clarification Needed)

```bash
/agent:assign-work "Fix the thing that's broken"
```

**Context**: User provides vague description without clear domain indicators

**Expected Outcome**:
- Domain detection fails (no meaningful keywords)
- Error message:
  ```
  ⚠️ Work description too vague for automatic agent assignment

  Please provide more details:
  - What specific system/component needs attention?
  - What type of work is needed? (analysis, development, documentation, etc.)
  - What technologies are involved? (Azure, Notion, GitHub, Power BI, etc.)

  Example: "Analyze GitHub repository dependencies to identify security vulnerabilities"

  Or specify domain explicitly: --domain=build
  ```

**Notion Updates**:
- **Agent Activity Hub**: Entry with Status="Blocked" and Notes="Insufficient detail for assignment"

---

### Example 5: Multi-Domain Work (Documentation + Build)

```bash
/agent:assign-work "Generate comprehensive API documentation for Azure Function endpoints with OpenAPI spec, deployment guide, and example code in Markdown format"
```

**Context**: Work spans both documentation and build domains

**Expected Outcome**:
- Primary domain: **Documentation** (keywords: "documentation", "guide", "Markdown", "example code")
- Secondary domain: **Build** (keywords: "API", "Azure Function", "OpenAPI")
- Recommended agent: **@markdown-expert** (Confidence: 85%)
- Alternative suggestion: "Consider follow-up with @build-architect for OpenAPI schema generation"
- Estimated completion: 25-30 minutes

**Notion Updates**:
- **Agent Activity Hub**: Entry with Notes indicating multi-domain nature and suggestion for sequential delegation

---

## Error Handling

### Vague Work Description

**Trigger**: Work description <20 characters or lacks domain-specific keywords

**Behavior**:
- Display error message with guidance
- Suggest example work descriptions for each domain
- Provide `--domain` parameter option to force category
- Do not create Agent Activity Hub entry (invalid input)

**Example Error Message**:
```
Validation Error: Work description insufficient for agent matching

Your description: "Do the research"

Recommendations:
- Include specific subject matter: "Research Azure cost optimization opportunities"
- Mention technologies/tools: "Investigate Power BI performance tuning"
- Specify expected deliverable: "Feasibility study with viability score 0-100"

Or specify domain: /agent:assign-work "Do the research" --domain=research
```

---

### No Agents Match Criteria

**Trigger**: Detected domain has no active agents in Agent Registry

**Behavior**:
- Display warning that no specialized agents are available
- Suggest @claude-main as fallback general-purpose agent
- Recommend creating specialized agent for this domain
- Log to Agent Activity Hub with Status="Blocked - No Agent Available"

**Example Warning Message**:
```
⚠️ No specialized agents available for Compliance domain

Detected work type: Security audit and policy compliance review
Agents searched: Compliance domain (0 active agents found)

Fallback Option:
- Use @claude-main for general-purpose task execution
- Invocation: Task(@claude-main, "your-work-description")

Recommendation:
- Consider creating specialized @compliance-orchestrator agent
- Reference: .claude/agents/ for agent template
```

---

### Invalid Domain Parameter

**Trigger**: `--domain` parameter value not in predefined list

**Behavior**:
- Display error with valid domain options
- Attempt auto-detection as fallback
- Do not proceed with invalid domain

**Example Error Message**:
```
Parameter Error: Invalid --domain value "testing"

Valid domains:
- innovation (idea capture, opportunity tracking)
- cost (spend analysis, budget optimization)
- research (feasibility studies, investigation)
- build (development, architecture, deployment)
- compliance (audit, security, governance)
- documentation (technical writing, guides, tutorials)
- deployment (Azure infrastructure, release management)

Auto-detection available: Omit --domain to let system analyze work description
```

---

### Agent Registry Connection Failed

**Trigger**: Notion MCP cannot query Agent Registry database

**Behavior**:
- Retry up to 3 times with exponential backoff (2s, 4s, 8s)
- If all retries fail, display fallback agent list from local cache
- Log error to Agent Activity Hub for troubleshooting
- Provide manual agent selection guidance

**Example Error Message**:
```
Connection Error: Unable to query Agent Registry database

Attempted: 3 retries with exponential backoff
Error: Notion API timeout (504)

Fallback Agents (from local cache):
- @cost-analyst - Cost and spend analysis
- @build-architect - System architecture and design
- @research-coordinator - Feasibility and investigation
- @claude-main - General-purpose assistant

Manual Selection: Task(@agent-name, "your-work-description")
```

---

## Success Criteria

Verify the command executed successfully by confirming:

- ✅ **Work Description Parsed**: Domain keywords identified and classified correctly
- ✅ **Agent Scored**: All active agents in detected domain received composite scores
- ✅ **Recommendation Provided**: Top agent selected with confidence score >70%
- ✅ **Invocation Command**: Ready-to-execute Task() command provided to user
- ✅ **Activity Logged**: Agent Activity Hub contains entry with assignment details
- ✅ **Alternatives Available**: If `--show-alternatives=true`, top 3 agents displayed
- ✅ **No Duplicates**: Search confirms no duplicate pending assignments for same work

---

## Related Commands

### Complementary Commands

- **`/agent:performance-report [agent-name]`**: View historical performance metrics before manual agent selection
- **`/agent:register [agent-name]`**: Add new specialized agent when no suitable agent exists for domain
- **`/team:assign [work-description] [database]`**: Assign work to human team members instead of agents

### Workflow Sequences

**Common Pattern 1: Full Work Lifecycle**
```bash
/agent:assign-work "Analyze monthly software costs"  # Recommend @cost-analyst
Task(@cost-analyst, "Analyze monthly software costs") # Execute recommended agent
/agent:performance-report @cost-analyst               # Review agent effectiveness
```

**Common Pattern 2: Agent Discovery**
```bash
/agent:assign-work "your-work" --show-alternatives    # See top 3 agents
/agent:performance-report @agent-option-1             # Compare performance
/agent:performance-report @agent-option-2             # metrics for alternatives
Task(@selected-agent, "your-work")                    # Execute chosen agent
```

---

## Best Practices

### When to Use This Command

**Ideal Scenarios**:
- Unsure which specialized agent to invoke for specific work type
- Want optimal agent selection based on performance history
- Need to route work systematically across team without manual agent research
- Working with new team members who don't know all available agents

**Avoid Using When**:
- You already know the exact agent needed (directly use Task(@agent-name))
- Work is extremely time-sensitive (<5 min) and analysis overhead not justified
- Work description is confidential and auto-logging to Notion not desired
- Testing/experimenting with specific agent capabilities (use direct invocation)

### Performance Considerations

- **Typical Execution Time**: 5-10 seconds for agent scoring and recommendation
- **Notion API Calls**: 2-3 calls (Agent Registry query + Activity Hub logging)
- **Database Locks**: None - read-only operations except Activity Hub insert
- **Caching**: Agent Registry data cached for 5 minutes to reduce API calls

### Security & Compliance

- **Credentials Required**: Notion API token (via MCP server configuration)
- **Data Sensitivity**: Work descriptions logged to Agent Activity Hub in private workspace
- **Audit Trail**: Complete assignment decision history stored with scoring breakdowns
- **Privacy**: Use `--no-log` flag (future) to prevent Notion logging for sensitive work

---

## Troubleshooting

### Common Issues

**Issue**: Recommended agent doesn't match expected expertise

**Cause**: Keyword analysis prioritized different domain than user intended

**Resolution**:
1. Use `--domain` parameter to force category: `/agent:assign-work "description" --domain=build`
2. Add more domain-specific keywords to work description (e.g., "Azure deployment" instead of "deploy")
3. Review Agent Registry specializations to understand keyword mappings
4. Use `--show-alternatives` to see all scoring and manually select best agent

---

**Issue**: Same agent recommended repeatedly despite poor past performance

**Cause**: Agent Registry performance score not updated after recent poor completions

**Resolution**:
1. Check Agent Activity Hub for recent sessions: `/agent:performance-report @agent-name`
2. Manually update Agent Registry performance score if outdated
3. Set agent Status="Deprecated" if consistently underperforming
4. Create new specialized agent with better capability profile

---

**Issue**: "No agents available" despite expecting domain coverage

**Cause**: Agent Registry entries missing or agents set to Status="Deprecated"

**Resolution**:
1. Query Agent Registry manually: Use Notion search for active agents
2. Verify agent Status field = "Active" (not "Deprecated" or "In Development")
3. Register missing agents: `/agent:register @agent-name --specialization="domain"`
4. Use @claude-main as temporary fallback while registering specialists

---

## Implementation Notes

### Technical Requirements

- **Notion MCP Server**: Minimum version 1.0.0
- **Claude Model**: claude-sonnet-4-5 or newer (for keyword analysis and scoring)
- **Agent Registry**: Must have Performance Score and Specialization fields populated
- **Environment Variables**: NOTION_API_KEY for MCP authentication

### Database Dependencies

This command requires the following databases with specific schemas:

- **Agent Registry** (ID: 5863265b-eeee-45fc-ab1a-4206d8a523c6)
  - Required Properties: Agent Name, Specialization, Performance Score, Average Duration, Status
  - Required Relations: Compatible Output Styles, Recent Activity

- **Agent Activity Hub** (ID: 7163aa38-f3d9-444b-9674-bde61868bd2b)
  - Required Properties: Activity Title, Agent, Status, Work Description, Session Start
  - Required Relations: Agent (to Agent Registry)

### Agent Handoff Protocol

This command does NOT perform handoff - it only recommends agents:

1. **Recommendation Generated**: User receives Task(@agent-name) command to execute
2. **User Executes**: User manually invokes Task tool with recommended agent
3. **Logging Occurs**: Automatic activity logging happens when Task tool invokes agent
4. **Verification**: Use `/agent:activity-summary` to confirm execution

**Note**: Future enhancement may add `--execute` flag to automatically invoke recommended agent

---

**Last Updated**: 2025-10-26 | **Maintained By**: @workflow-router
**Related Documentation**: [Agent Guidelines](.claude/docs/agent-guidelines.md), [Agent Activity Center](.claude/docs/agent-activity-center.md)
