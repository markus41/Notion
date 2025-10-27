---
name: agent:register
description: Establish new agent registration to expand automation capabilities and maintain comprehensive agent portfolio documentation
allowed-tools: mcp__notion__notion-create-pages, mcp__notion__notion-search
argument-hint: [agent-name] [specialization] [--description=text] [--avg-duration=minutes]
model: claude-sonnet-4-5-20250929
---

# /agent:register

**Category**: Agent Management
**Related Databases**: Agent Registry
**Agent Compatibility**: @claude-main

## Purpose

Establish systematic agent registration to expand automation capabilities and maintain comprehensive agent portfolio documentation with specializations, performance baselines, and capability profiles.

**Best for**: Organizations creating custom agents requiring centralized registry for delegation routing and performance tracking.

---

## Command Parameters

**Required:**
- `agent-name` - Agent identifier (format: @agent-name)
- `specialization` - Primary domain (innovation | cost | research | build | compliance | documentation | deployment)

**Optional Flags:**
- `--description=text` - Detailed capability description
- `--avg-duration=minutes` - Estimated average completion time
- `--status=value` - Initial status (active | in-development, default: active)
- `--performance-score=value` - Initial score 0-100 (default: 75)

---

## Workflow

### Step 1: Validate Agent Name

```javascript
const agentNamePattern = /^@[a-z0-9-]+$/;
if (!agentNamePattern.test(agentName)) {
  console.error(`❌ Invalid agent name format: ${agentName}`);
  console.log(`\nRequired format: @lowercase-with-hyphens`);
  console.log(`Examples: @cost-analyst, @build-architect, @research-coordinator`);
  return;
}
```

### Step 2: Check for Duplicates

```javascript
const existingAgents = await notionSearch({
  query: agentName.replace('@', ''),
  data_source_url: 'collection://5863265b-eeee-45fc-ab1a-4206d8a523c6'
});

if (existingAgents.results.length > 0) {
  console.error(`❌ Agent already registered: ${agentName}`);
  console.log(`\nUse /agent:performance-report ${agentName} to view details`);
  return;
}
```

### Step 3: Create Agent Entry

```javascript
const specializationMap = {
  'innovation': '💡 Innovation',
  'cost': '💰 Cost Optimization',
  'research': '🔬 Research & Analysis',
  'build': '🛠️ Build & Development',
  'compliance': '✅ Compliance & Security',
  'documentation': '📚 Documentation',
  'deployment': '🚀 Deployment'
};

const statusMap = {
  'active': '🟢 Active',
  'in-development': '🔵 In Development'
};

await notionCreatePages({
  parent: { data_source_id: '5863265b-eeee-45fc-ab1a-4206d8a523c6' },
  pages: [{
    properties: {
      "Agent Name": agentName,
      "Specialization": specializationMap[specialization.toLowerCase()],
      "Description": descriptionFlag || `Specialized agent for ${specialization} workflows`,
      "Average Duration": avgDurationFlag || 15,
      "Performance Score": performanceScoreFlag || 75,
      "Total Sessions": 0,
      "Status": statusMap[statusFlag || 'active'],
      "Registered Date": new Date().toISOString().split('T')[0]
    }
  }]
});

console.log(`✅ Agent registered: ${agentName}`);
console.log(`\n**Agent Profile:**`);
console.log(`- Specialization: ${specializationMap[specialization.toLowerCase()]}`);
console.log(`- Performance Score: ${performanceScoreFlag || 75}/100`);
console.log(`- Average Duration: ${avgDurationFlag || 15} minutes`);
console.log(`- Status: ${statusMap[statusFlag || 'active']}`);
```

### Step 4: Next Steps Guidance

```javascript
console.log(`\n**Next Steps:**`);
console.log(`1. Create agent file: .claude/agents/${agentName.replace('@', '')}.md`);
console.log(`2. Define agent prompt and capabilities`);
console.log(`3. Test agent: Task(${agentName}, "test-description")`);
console.log(`4. Monitor performance: /agent:performance-report ${agentName}`);
```

---

## Execution Example

```bash
/agent:register @procurement-specialist cost \
  --description="Vendor management, contract negotiation, cost reduction strategies" \
  --avg-duration=20 \
  --performance-score=80
```

**Output:**
```
✅ Agent registered: @procurement-specialist

**Agent Profile:**
- Specialization: 💰 Cost Optimization
- Performance Score: 80/100
- Average Duration: 20 minutes
- Status: 🟢 Active

**Next Steps:**
1. Create agent file: .claude/agents/procurement-specialist.md
2. Define agent prompt and capabilities
3. Test agent: Task(@procurement-specialist, "test-description")
4. Monitor performance: /agent:performance-report @procurement-specialist
```

---

## Error Handling

**Error 1: Invalid Name Format**
```
Input: /agent:register CostAnalyst cost
Output: ❌ Invalid agent name format: CostAnalyst

        Required format: @lowercase-with-hyphens
        Examples: @cost-analyst, @build-architect, @research-coordinator
```

**Error 2: Duplicate Agent**
```
Input: /agent:register @cost-analyst cost
Output: ❌ Agent already registered: @cost-analyst

        Use /agent:performance-report @cost-analyst to view details
```

**Error 3: Invalid Specialization**
```
Input: /agent:register @test-agent testing
Output: ❌ Invalid specialization: testing

        Valid options: innovation | cost | research | build | compliance | documentation | deployment
```

---

## Success Criteria

- ✅ Agent name validated (format check)
- ✅ Duplicate check performed
- ✅ Agent Registry entry created
- ✅ Initial performance baseline set
- ✅ Next steps guidance provided

---

## Related Commands

- `/agent:assign-work` - Route work to newly registered agent
- `/agent:performance-report` - Track agent effectiveness
- `/agent:list` - View all registered agents

---

## Best Practices

**Do:**
- ✅ Use descriptive agent names matching capabilities
- ✅ Set realistic average duration based on specialization
- ✅ Start with conservative performance score (75)
- ✅ Create corresponding agent file in `.claude/agents/`

**Don't:**
- ❌ Register duplicate agents for same specialization
- ❌ Use generic names (e.g., @helper, @assistant)
- ❌ Set unrealistic performance baselines
- ❌ Skip agent file creation step

---

## Notes for Claude Code

**Automatic Execution**: This command executes immediately without requiring user approval for Notion MCP operations.

**Agent File Template**: After registration, create agent file following `.claude/agents/README.md` template.

**Performance Tracking**: Initial score of 75 will be adjusted based on actual session outcomes in Agent Activity Hub.

---

**Last Updated**: 2025-10-26
**Database**: Agent Registry (`5863265b-eeee-45fc-ab1a-4206d8a523c6`)
