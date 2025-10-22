# Agent Output Styles - Brookside BI Innovation Nexus

**Purpose**: Dynamic output style system that enables agents to adapt communication patterns based on audience, context, and task requirements while maintaining Brookside BI brand consistency.

**Best for**: Organizations requiring flexible agent communication that drives measurable outcomes through audience-appropriate output formatting, tone adaptation, and context-sensitive information delivery.

---

## Overview

The Agent Output Style System provides a structured approach to managing how agents communicate, ensuring:

- **Audience Appropriateness**: Match output style to reader expertise level
- **Context Sensitivity**: Adapt formality and detail to situation
- **Brand Consistency**: Maintain Brookside BI voice across all styles
- **Measurable Effectiveness**: Track style performance with comprehensive metrics
- **Intelligent Selection**: Automated style recommendation via Style-Orchestrator agent

---

## Available Output Styles

### 1. 📘 Technical Implementer
**Style ID**: `technical-implementer`
**Target Audience**: Developers, engineers, technical teams
**Category**: Technical

**Characteristics**:
- Code-heavy outputs with implementation details
- Precise technical language
- Focus on "how" over "why"
- Extensive code examples and configurations
- Minimal business context, maximum technical depth

**Best Use Cases**:
- API implementation guidance
- Code reviews and debugging
- Infrastructure configuration
- Technical architecture documentation
- Development workflows

**Capabilities**: Code Generation, Technical Diagrams, Command-line Operations

**File**: [technical-implementer.md](technical-implementer.md)

---

### 2. 💼 Strategic Advisor
**Style ID**: `strategic-advisor`
**Target Audience**: Executives, stakeholders, decision-makers
**Category**: Business

**Characteristics**:
- Executive summaries and high-level overviews
- Business value and ROI focus
- Strategic recommendations with clear outcomes
- Minimal technical jargon
- Data-driven insights and metrics

**Best Use Cases**:
- Executive briefings
- Budget planning and cost analysis
- Strategic roadmap presentations
- Stakeholder communications
- Business case development

**Capabilities**: Tables, Executive Dashboards, ROI Analysis

**File**: [strategic-advisor.md](strategic-advisor.md)

---

### 3. 🎨 Visual Architect
**Style ID**: `visual-architect`
**Target Audience**: Technical teams, stakeholders, mixed audiences
**Category**: Visual

**Characteristics**:
- Diagram-first communication approach
- Visual hierarchy with flowcharts and architecture diagrams
- Mermaid-based visualizations
- Balanced technical depth with visual clarity
- Component-based system breakdowns

**Best Use Cases**:
- System architecture design
- Process workflow documentation
- Integration mapping
- Technical presentations
- Design reviews

**Capabilities**: Mermaid Diagrams, Flowcharts, Architecture Visuals, Interactive Elements

**File**: [visual-architect.md](visual-architect.md)

---

### 4. 🎓 Interactive Teacher
**Style ID**: `interactive-teacher`
**Target Audience**: Junior team members, new hires, learners
**Category**: Educational

**Characteristics**:
- Q&A format with progressive learning
- Accessible explanations without oversimplification
- Examples and exercises for hands-on learning
- Conversational and encouraging tone
- Scaffolded complexity (simple → advanced)

**Best Use Cases**:
- Onboarding documentation
- Training materials
- Concept explanations
- Knowledge transfer sessions
- Technical tutorials

**Capabilities**: Q&A Format, Interactive Elements, Examples with Exercises

**File**: [interactive-teacher.md](interactive-teacher.md)

---

### 5. ✅ Compliance Auditor
**Style ID**: `compliance-auditor`
**Target Audience**: Auditors, compliance officers, legal teams
**Category**: Compliance

**Characteristics**:
- Formal, precise language with regulatory terminology
- Checklist-based structure
- Evidence tables with citations
- Risk assessment matrices
- Policy mapping and control documentation

**Best Use Cases**:
- Audit preparation
- Compliance documentation
- Security assessments (SOC2, ISO, GDPR)
- Regulatory reporting
- Policy documentation

**Capabilities**: Checklists, Tables, Evidence Mapping, Risk Matrices

**File**: [compliance-auditor.md](compliance-auditor.md)

---

## Style Selection Workflow

### Manual Selection
Use the `/test-agent-style` command to experiment with different styles:

```bash
# Test specific agent+style combination
/test-agent-style @cost-analyst strategic-advisor --task="Analyze Q4 software spend"

# Compare all styles for an agent
/test-agent-style @markdown-expert ?

# Interactive testing session
/test-agent-style @build-architect visual-architect --interactive
```

### Automated Selection
The **Style-Orchestrator** agent automatically recommends optimal styles based on:
- Task complexity and requirements
- Target audience profile
- Historical performance data
- Agent capabilities
- Time constraints

The orchestrator is consulted automatically by the main workflow coordinator when executing tasks.

---

## Style Architecture

### Style Definition Structure

Each style file contains:

1. **Identity**: Name, ID, category, target audience
2. **Characteristics**: Behavioral traits and communication patterns
3. **Output Transformation Rules**: How the style modifies agent output
4. **Brand Voice Integration**: How Brookside BI guidelines apply
5. **Capabilities Required**: Technical features needed (Mermaid, code gen, etc.)
6. **Best Use Cases**: Ideal scenarios with examples
7. **Effectiveness Metrics**: How success is measured
8. **Example Outputs**: Reference samples showing style in action

### Brand Voice Integration

All output styles maintain Brookside BI brand principles:

**Core Patterns** (Applied Consistently):
- "Establish structure and rules for..."
- "This solution is designed to..."
- "Organizations scaling [technology] across..."
- "Streamline workflows and improve visibility"
- "Drive measurable outcomes through structured approaches"

**Style-Specific Application**:
- **Technical Implementer**: Brand voice in code comments, documentation headers
- **Strategic Advisor**: Full brand voice throughout all communications
- **Visual Architect**: Brand voice in diagram annotations and section headers
- **Interactive Teacher**: Brand voice in learning objectives and outcomes
- **Compliance Auditor**: Brand voice in executive summaries, formal elsewhere

---

## Performance Tracking

### Notion Databases

**🎨 Output Styles Registry**
- Central catalog of all available styles
- Performance scores and usage statistics
- Style compatibility with agents

**🤖 Agent Activity Hub**
- Records which style was used for each session
- Tracks style-specific metrics (technical density, clarity, etc.)
- Links sessions to Ideas, Research, Builds

**🧪 Agent Style Tests**
- Comprehensive test results for agent+style combinations
- Effectiveness scores and user satisfaction ratings
- Comparative analysis across styles

### Key Metrics

**Behavior Metrics**:
- Output Length (tokens)
- Technical Density (0-1 scale)
- Formality Score (0-1 scale)
- Clarity Score (0-1 scale)
- Visual Elements Count
- Code Blocks Count

**Effectiveness Metrics**:
- Goal Achievement (0-1 scale)
- Audience Appropriateness (0-1 scale)
- Style Consistency (0-1 scale)
- Information Density (0-1 scale)

**Performance Metrics**:
- Generation Time (ms)
- User Satisfaction (1-5 rating)
- Task Completion Rate
- Follow-up Questions Count

---

## Creating Custom Styles

### Steps to Add New Style

1. **Create Style Definition File**: `.claude/styles/your-style-name.md`
2. **Follow Template Structure**: Use existing styles as reference
3. **Add to Output Styles Registry**: Create Notion database entry
4. **Test with Multiple Agents**: Use `/test-agent-style` command
5. **Gather Performance Data**: Run comparative tests
6. **Document in README**: Add to available styles list above

### Custom Style Template

```markdown
# [Style Name]

**Style ID**: `style-slug`
**Target Audience**: [Who this style serves]
**Category**: [Technical/Business/Visual/Educational/Compliance/Custom]

## Characteristics
- [Behavioral trait 1]
- [Behavioral trait 2]
- [Communication pattern 1]

## Output Transformation Rules
[How this style modifies agent output]

## Brand Voice Integration
[How Brookside BI guidelines apply in this style]

## Capabilities Required
- [Feature 1: e.g., Mermaid Diagrams]
- [Feature 2: e.g., Code Generation]

## Best Use Cases
1. [Scenario 1 with example]
2. [Scenario 2 with example]

## Effectiveness Criteria
[How success is measured for this style]

## Example Output
[Sample showing style in action]
```

---

## Integration with Main Orchestrator

The Style System integrates seamlessly with the Innovation Nexus orchestrator:

```
User Request
     ↓
Main Orchestrator
     ↓
Style-Orchestrator (recommends optimal style)
     ↓
Select Agent + Load Style
     ↓
Execute Task with Style Applied
     ↓
Log Behavior to 3-Tier System
     ↓
Update Performance Metrics
```

---

## Slash Commands

### `/test-agent-style`
Test agent+style combinations with comprehensive reporting.

**Usage:**
```bash
/test-agent-style <agent-name> <style-name> [--task="description"] [--interactive]
```

**Examples:**
```bash
# Basic test
/test-agent-style @cost-analyst strategic-advisor

# With custom task
/test-agent-style @build-architect visual-architect --task="Design microservices architecture"

# Interactive mode
/test-agent-style @markdown-expert technical-implementer --interactive

# Compare all styles
/test-agent-style @viability-assessor ?
```

### `/style:compare`
Run side-by-side style comparison for same task.

### `/style:report`
Generate performance analytics for specific style or agent.

---

## Best Practices

### For Agents
✅ **Select appropriate style** based on task and audience
✅ **Maintain brand voice** regardless of style chosen
✅ **Log all sessions** with style metadata for analytics
✅ **Respect style constraints** (e.g., technical-implementer stays technical)
✅ **Provide feedback** on style effectiveness after completion

### For Users
✅ **Test styles** before using in high-stakes scenarios
✅ **Review analytics** to understand style performance trends
✅ **Create custom styles** when standard options don't fit
✅ **Provide satisfaction ratings** to improve style recommendations
✅ **Document learnings** when discovering effective style combinations

### For System Optimization
✅ **Monitor effectiveness scores** across all styles
✅ **Identify underperforming combinations** and investigate
✅ **Evolve styles** based on performance data
✅ **Create hybrid styles** for complex multi-audience scenarios
✅ **Archive deprecated styles** but preserve historical data

---

## Troubleshooting

**Style not working as expected?**
- Check agent compatibility (some agents excel with specific styles)
- Verify task matches style use case (technical tasks → technical styles)
- Review historical performance for this combination
- Consider audience mismatch (junior team + compliance-auditor = poor fit)

**Performance scores low?**
- Run comparative test with `/test-agent-style ? `
- Check if custom style parameters need adjustment
- Verify brand voice integration isn't compromising effectiveness
- Consider hybrid style approach

**Style recommendation doesn't make sense?**
- Check Style-Orchestrator decision reasoning
- Verify task description clarity (ambiguous tasks get generic styles)
- Review audience specification (mixed audiences get balanced styles)
- Provide manual override if needed

---

## Future Enhancements

**Phase 3 - Intelligence** (Planned):
- Machine learning-based style effectiveness prediction
- Automatic hybrid style composition
- Real-time style adaptation based on user feedback
- Context-aware style parameter tuning

**Phase 4 - Advanced Features** (Planned):
- Style evolution system (styles improve over time)
- Domain-specific style variants
- Multi-language style support
- Visual performance dashboards

---

## Related Documentation

- **Agent Registry**: [.claude/agents/](../agents/) - All available agents
- **Slash Commands**: [.claude/commands/](../commands/) - Command reference
- **Style-Orchestrator Agent**: [.claude/agents/style-orchestrator.md](../agents/style-orchestrator.md)
- **Testing Guide**: [docs/TESTING_AGENT_STYLES.md](../../docs/TESTING_AGENT_STYLES.md)
- **User Guide**: [docs/AGENT_OUTPUT_STYLES_GUIDE.md](../../docs/AGENT_OUTPUT_STYLES_GUIDE.md)
- **API Reference**: [docs/STYLE_ORCHESTRATOR_API.md](../../docs/STYLE_ORCHESTRATOR_API.md)

---

**🤖 Maintained for Brookside BI Innovation Nexus**

**Version**: 1.0.0
**Last Updated**: 2025-10-21
**Status**: Active (Phase 1-2 MVP)

**Best for**: Organizations requiring intelligent, audience-adaptive communication that drives measurable outcomes through structured style management, systematic performance tracking, and continuous improvement based on empirical effectiveness data.
