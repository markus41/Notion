---
description: Run side-by-side style comparison for same agent+task. Executes all specified styles (default: all 5) and generates comparative effectiveness analysis with recommendation.
allowed-tools: Task(@style-orchestrator:*, @ultrathink-analyzer:*), mcp__notion__*
argument-hint: <agent-name> "<task-description>" [--styles=style1,style2,...] [--ultrathink]
model: claude-sonnet-4-5-20250929
---

## Context

Streamline style selection decisions by executing identical tasks across multiple output styles with side-by-side comparative analysis, enabling objective evaluation of communication effectiveness trade-offs.

**Best for**: Organizations requiring evidence-based style selection where comparative analysis reveals optimal communication approaches for specific agent+task combinations.

---

## Command Syntax

```bash
/style:compare <agent-name> "<task-description>" [options]

# Arguments:
<agent-name>         - Agent to test (e.g., @cost-analyst)
<task-description>   - Task to execute across all styles

# Options:
--styles=list        - Comma-separated styles to compare (default: all 5)
                       Example: --styles=technical-implementer,strategic-advisor
--ultrathink         - Enable deep analysis with tier classification
--sync               - Sync all results to Notion immediately
--format=type        - Output format: table|detailed|summary (default: table)
```

---

## Usage Examples

### Compare All Styles (Default)
```bash
/style:compare @viability-assessor "Assess AI cost optimization platform idea"
```
**Output**: Runs task with all 5 styles, displays comparison table

### Compare Specific Styles
```bash
/style:compare @build-architect "Design microservices architecture" --styles=visual-architect,technical-implementer,strategic-advisor
```
**Output**: Tests only specified 3 styles

### UltraThink Comparison
```bash
/style:compare @compliance-orchestrator "Document SOC2 controls" --ultrathink --sync
```
**Output**: Deep analysis across styles with tier classification

---

## Workflow

### Phase 1: Execute Tests Across Styles

```javascript
// Parse arguments
const agentName = ARGUMENTS[0];
const taskDescription = ARGUMENTS[1];
const stylesToCompare = parseStyles(options.styles) || ALL_STYLES;

// Run tests in parallel for efficiency
const results = await Promise.all(
  stylesToCompare.map(style =>
    executeTest(agentName, style, taskDescription, options)
  )
);
```

### Phase 2: Generate Comparative Analysis

**Comparison Table Format:**
```
Style Comparison: @cost-analyst on "Analyze Q4 spending"

| Style | Effectiveness | Clarity | Technical | Formality | Time | Tier |
|-------|--------------|---------|-----------|-----------|------|------|
| Strategic Advisor | 94/100 | 88% | 25% | 65% | 2.3s | 🥇 Gold |
| Visual Architect | 82/100 | 85% | 45% | 55% | 3.1s | 🥈 Silver |
| Technical Impl. | 71/100 | 75% | 85% | 40% | 2.8s | 🥉 Bronze |
| Interactive Teacher | 68/100 | 90% | 15% | 35% | 2.5s | 🥉 Bronze |
| Compliance Auditor | 55/100 | 70% | 30% | 95% | 4.2s | ⚪ Needs Improvement |

🎯 Recommendation: Strategic Advisor
   → Best for executive-focused cost analysis with business value emphasis
   → 94/100 effectiveness (12 points above next best)

💡 Alternative: Visual Architect
   → Use when stakeholders need visual cost trend representation
   → Trade-off: +0.8s generation time, -12 effectiveness points
```

### Phase 3: Detailed Reasoning (If Requested)

```
Detailed Analysis:

✅ Strategic Advisor (Winner)
   Strengths:
   • Optimal business focus for executive audience
   • Clear ROI framing and cost optimization recommendations
   • Professional but accessible tone
   • Fast generation (2.3s)

   Weaknesses:
   • May lack technical implementation detail for engineering teams

📊 Key Differentiators:
   1. Effectiveness Gap: 23 points between top and bottom (significant spread)
   2. Audience Alignment: Strategic Advisor optimally matches executive target
   3. Generation Efficiency: All styles completed in <5s (acceptable performance)
   4. Style Consistency: All outputs maintained brand voice (100% compliance)

🚩 Red Flags:
   • Compliance Auditor underperformed (55/100) - not appropriate for cost analysis
   • Technical Implementer formal score low (40%) - may be too casual for stakeholders
```

---

## Output Formats

### Table Format (Default)
Concise side-by-side comparison with key metrics

### Detailed Format
Full metrics breakdown + sample output excerpts + recommendations

### Summary Format
Top recommendation only with 2-3 sentence justification

---

## Integration with /test-agent-style

```bash
# Typical workflow:
# 1. Get quick comparison
/style:compare @markdown-expert "Document API endpoints"

# 2. Deep-dive on winner
/test-agent-style @markdown-expert technical-implementer --task="Document API endpoints" --ultrathink --interactive
```

---

**Best for**: Organizations requiring rapid, evidence-based style selection where side-by-side comparison reveals optimal communication effectiveness for specific scenarios.
