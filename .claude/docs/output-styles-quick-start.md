# Output Styles Quick Start Guide

**Purpose**: Establish rapid onboarding for teams adopting the Output Styles system to optimize AI agent communication effectiveness through systematic testing and data-driven style selection.

**Best for**: Teams new to output styles requiring immediate productivity with systematic approach to agent communication optimization.

---

## What Are Output Styles?

**Output Styles** are dynamic communication pattern adaptations that transform agent responses to match specific audiences, contexts, and organizational needs. Think of them as "communication lenses" that maintain content accuracy while optimizing presentation for effectiveness.

### The 5 Available Styles

| Style | Icon | When to Use | Target Audience |
|-------|------|-------------|-----------------|
| **Technical Implementer** | 📘 | Code generation, API docs, technical specifications | Developers, Engineers |
| **Strategic Advisor** | 💼 | Business analysis, ROI calculations, executive reports | Executives, Leadership |
| **Visual Architect** | 🎨 | System diagrams, architecture presentations | Cross-functional Teams |
| **Interactive Teacher** | 🎓 | Onboarding, tutorials, knowledge transfer | New Team Members, Trainees |
| **Compliance Auditor** | ✅ | SOC2 docs, audit artifacts, regulatory reporting | Auditors, Compliance Officers |

### Why Use Output Styles?

**Without Output Styles**:
- Agents produce generic one-size-fits-all responses
- Technical details overwhelm non-technical audiences
- Executive presentations lack business value framing
- Compliance documentation misses formal evidence requirements
- No data-driven way to measure communication effectiveness

**With Output Styles**:
- ✅ **Audience-Optimized**: Content automatically adapted for target readers
- ✅ **Measurable Effectiveness**: Track which styles work best for which agents
- ✅ **Data-Driven Selection**: Recommendations based on empirical test data
- ✅ **Consistent Quality**: Maintain Brookside BI brand voice across all styles
- ✅ **Continuous Improvement**: Identify underperformers and optimize over time

---

## Getting Started in 5 Minutes

### Step 1: Understand Your Use Case

**Ask yourself**:
1. **Who is the audience?** (Developers, Executives, Auditors, etc.)
2. **What is the task?** (Code generation, Business analysis, Compliance doc, etc.)
3. **Which agent will I use?** (@cost-analyst, @build-architect, @compliance-orchestrator, etc.)

**Example Scenarios**:

**Scenario A**: "I need @cost-analyst to create a Q4 spending report for our CFO"
- **Audience**: Executive (CFO)
- **Task**: Business analysis with ROI focus
- **Recommended Style**: 💼 **Strategic Advisor**

**Scenario B**: "I need @build-architect to document our microservices architecture for the dev team"
- **Audience**: Developers
- **Task**: Technical specification
- **Recommended Style**: 📘 **Technical Implementer**

**Scenario C**: "I need @compliance-orchestrator to prepare SOC2 control documentation for our audit"
- **Audience**: External Auditors
- **Task**: Compliance evidence
- **Recommended Style**: ✅ **Compliance Auditor**

### Step 2: Test Your First Agent+Style Combination

**Basic Test Command**:
```bash
/test-agent-style <agent-name> <style-name>

# Examples:
/test-agent-style @cost-analyst strategic-advisor
/test-agent-style @build-architect technical-implementer
/test-agent-style @compliance-orchestrator compliance-auditor
```

**What Happens**:
1. Agent executes a representative task in the specified style
2. Output is analyzed for effectiveness metrics (technical density, formality, clarity, etc.)
3. Overall effectiveness score (0-100) calculated
4. Results displayed with key insights

**Example Output**:
```
✅ Test Complete: @cost-analyst + strategic-advisor

📊 Metrics:
- Overall Effectiveness: 87/100
- Technical Density: 0.25 (Business-focused)
- Formality Score: 0.68 (Professional)
- Clarity Score: 0.85 (Accessible)
- Generation Time: 2.3s

🎯 Assessment: Strong performance for executive audience
✅ Status: Passed (>60 threshold)

💡 Recommendation: Use strategic-advisor for cost analysis executive presentations
```

### Step 3: Compare Multiple Styles (Find the Best)

**Comparison Command**:
```bash
/style:compare <agent-name> "<task-description>"

# Example:
/style:compare @cost-analyst "Analyze Q4 software spending for executive presentation"
```

**What Happens**:
1. Agent executes the same task across all 5 styles
2. Side-by-side comparison table generated
3. Top recommendation provided with justification

**Example Output**:
```
Style Comparison: @cost-analyst on "Analyze Q4 spending"

| Style | Effectiveness | Clarity | Technical | Formality | Time |
|-------|--------------|---------|-----------|-----------|------|
| Strategic Advisor | 94/100 | 88% | 25% | 65% | 2.3s |
| Visual Architect | 82/100 | 85% | 45% | 55% | 3.1s |
| Technical Impl. | 71/100 | 75% | 85% | 40% | 2.8s |
| Interactive Teacher | 68/100 | 90% | 15% | 35% | 2.5s |
| Compliance Auditor | 55/100 | 70% | 30% | 95% | 4.2s |

🎯 Recommendation: Strategic Advisor
   → Best for executive-focused cost analysis (94/100 effectiveness)
   → 12 points above next best (Visual Architect)
```

### Step 4: Review Your Results in Notion

All test results are automatically synced to the **🧪 Agent Style Tests** database:

**Access**: [Agent Style Tests Database](https://www.notion.so/d3e04d6f2d4f444aa36e00abfa5dd5c0)

**What You'll See**:
- Test Name (e.g., "cost-analyst-strategic-advisor-20251023")
- Agent (relation to Agent Registry)
- Style (relation to Output Styles Registry)
- All metrics (technical density, formality, clarity, effectiveness, etc.)
- Full test output
- Status (Passed/Failed/Needs Review)

**Use Cases**:
- Filter by agent to see all style performance for a specific agent
- Filter by style to see which agents work best with that style
- Sort by effectiveness to identify top performers
- Create custom views for your team's most-used combinations

### Step 5: Apply Your Findings

**Once you've identified the optimal style**:

1. **Document the recommendation** in your team's workflow docs
2. **Use the style consistently** for that agent+task combination
3. **Monitor performance** over time with periodic re-testing
4. **Share insights** with your team via Notion database

**Example Documentation**:
```yaml
Agent: @cost-analyst
Task Type: Executive cost analysis presentations
Recommended Style: strategic-advisor
Effectiveness: 94/100
Last Tested: 2025-10-23
Re-test: Quarterly (next: 2026-01-23)
```

---

## Common Workflows

### Workflow 1: New Agent Onboarding

**When**: Adding a new agent to your portfolio

```bash
# 1. Test agent across all 5 styles
/style:compare @new-agent "Representative task for this agent"

# 2. Review comparison results and identify top 2 styles

# 3. Run UltraThink analysis on top 2 for deep insights
/test-agent-style @new-agent best-style-1 --ultrathink --sync
/test-agent-style @new-agent best-style-2 --ultrathink --sync

# 4. Document recommendations in team wiki
```

**Time**: 15-20 minutes
**Outcome**: Data-driven style recommendations for new agent

### Workflow 2: Ad-Hoc Task Style Selection

**When**: One-time task requiring optimal style

```bash
# Option A: Let orchestrator recommend
# (Invoke @style-orchestrator via natural language)
"Which output style should @build-architect use for architecture documentation targeting both developers and executives?"

# Option B: Quick comparison
/style:compare @build-architect "Design microservices architecture for analytics platform"

# Option C: Test specific style you suspect is best
/test-agent-style @build-architect visual-architect --interactive
```

**Time**: 3-10 minutes
**Outcome**: Optimal style for immediate use

### Workflow 3: Quarterly Performance Review

**When**: Regular check-in on portfolio effectiveness

```bash
# 1. Generate portfolio report
/style:report --timeframe=90d --format=executive

# 2. Identify underperformers (<60 effectiveness)

# 3. Deep-dive on problem combinations
/style:report --agent=@problem-agent --format=detailed

# 4. Re-test with UltraThink to diagnose issues
/test-agent-style @problem-agent problem-style --ultrathink --interactive

# 5. Refine style definitions or agent prompts based on insights
```

**Time**: 2-3 hours
**Outcome**: Optimized portfolio with improved effectiveness

---

## FAQ

### Q: Do I need to test every agent+style combination?

**A**: No, start with high-priority combinations:
- Core agents you use daily (@cost-analyst, @build-architect, etc.)
- Agents with obvious audience matches (@compliance-orchestrator + compliance-auditor)
- Agents with uncertain optimal styles (test all 5 to find best)

The bulk testing framework (`.claude/docs/bulk-style-testing.md`) covers systematic 185-combination testing for comprehensive portfolios.

### Q: How often should I re-test?

**A**: Recommended schedule:
- **New agents**: Test all 5 styles immediately upon creation
- **Core agents**: Quarterly re-testing to validate maintained performance
- **Style definition changes**: Re-test all affected combinations after updates
- **Poor performers**: Re-test monthly until effectiveness >75

### Q: What's the difference between regular test and UltraThink?

**Regular Test** (`/test-agent-style @agent style`):
- Fast (3-5 minutes)
- Quantitative metrics (technical density, formality, clarity, effectiveness)
- Pass/fail assessment
- Good for bulk testing and quick checks

**UltraThink Test** (`/test-agent-style @agent style --ultrathink`):
- Extended reasoning (8-12 minutes)
- Qualitative analysis (semantic appropriateness, audience alignment, brand consistency, etc.)
- Tier classification (🥇 Gold | 🥈 Silver | 🥉 Bronze | ⚪ Needs Improvement)
- Detailed optimization recommendations
- Good for deep-dives on critical combinations

**When to use UltraThink**:
- First-time testing of core agents
- Investigating underperformers
- Production readiness decisions
- Quarterly deep-dive reviews

### Q: Can I create my own custom output styles?

**A**: Yes! Follow the template in `.claude/styles/README.md`:
1. Create new style file: `.claude/styles/my-custom-style.md`
2. Define identity, characteristics, transformation rules, brand voice integration
3. Add entry to Output Styles Registry in Notion
4. Test with at least 10 agents to validate effectiveness

Custom styles are useful for:
- Niche audiences (e.g., "Regulatory Reviewer", "Data Scientist")
- Organizational-specific communication patterns
- Industry-specific terminology requirements

### Q: What if an agent performs poorly across all styles?

**This indicates potential issues**:
1. **Agent Prompt Quality**: Review agent specification, may need refinement
2. **Task Mismatch**: Agent may not be suited for the task type
3. **Style Incompatibility**: Agent specialization may not align with any existing style

**Remediation Steps**:
1. Run UltraThink analysis to diagnose root cause
2. Review agent `.claude/agents/[agent].md` specification
3. Consider creating custom style tailored to agent's unique output patterns
4. If fundamental mismatch, consider different agent for the task

### Q: How do metrics relate to real-world effectiveness?

**Metric Definitions**:

**Technical Density** (0-1): Ratio of technical terms/code/implementation details
- **0.0-0.2**: Business-focused (good for executives)
- **0.3-0.5**: Balanced (good for cross-functional teams)
- **0.6-0.8**: Technical focus (good for developers)
- **0.9-1.0**: Highly technical (good for engineering deep-dives)

**Formality Score** (0-1): Formal language vs. conversational tone
- **0.0-0.2**: Very casual (good for internal teams)
- **0.3-0.5**: Professional but approachable (Brookside BI standard)
- **0.6-0.8**: Formal business (good for client presentations)
- **0.9-1.0**: Legal/compliance formal (good for audit documentation)

**Clarity Score** (0-1): Flesch Reading Ease approximation
- **0.0-0.3**: Complex, expert knowledge required
- **0.4-0.6**: Moderate, business audience
- **0.7-0.9**: Clear, accessible to general audience
- **0.9-1.0**: Very clear, simple language

**Overall Effectiveness** (0-100): Weighted combination of:
- Goal Achievement (35%)
- Audience Appropriateness (30%)
- Style Consistency (20%)
- Clarity (15%)

**Production Readiness Thresholds**:
- **90-100**: 🥇 Gold - Production-ready, exemplary
- **75-89**: 🥈 Silver - Production-ready, minor optimizations available
- **60-74**: 🥉 Bronze - Acceptable baseline, targeted improvements recommended
- **0-59**: ⚪ Needs Improvement - Consider alternative styles

---

## Next Steps

**You've completed the Quick Start! Now you can**:

1. **Test your first 5 agent+style combinations** (your most-used agents)
2. **Review results in Notion** Agent Style Tests database
3. **Document optimal styles** in your team's workflow documentation
4. **Advance to Testing & Analytics Guide** (`.claude/docs/output-styles-testing-analytics.md`)
5. **Plan quarterly optimization** with Advanced Optimization Guide (`.claude/docs/output-styles-advanced-optimization.md`)

**Resources**:
- Full command reference: `CLAUDE.md` → Output Styles System section
- Agent specifications: `.claude/agents/`
- Style definitions: `.claude/styles/`
- Bulk testing framework: `.claude/docs/bulk-style-testing.md`

---

**Best for**: Teams new to output styles requiring immediate productivity with data-driven approach to agent communication optimization establishing measurable effectiveness across agent portfolio.
