# /create-agent - Interactive Agent Creation Wizard with Full Ecosystem Integration

**Category**: meta-tools
**Complexity**: Very High
**Execution Time**: 90-120 minutes
**Agent Orchestration**: Heavy (8 phases, 20+ coordinated tasks)

## Purpose

The `/create-agent` command is a comprehensive interactive wizard that guides you through the complete lifecycle of creating, validating, and integrating new specialized agents into your AI ecosystem. This command employs sophisticated multi-agent orchestration to ensure that new agents are well-designed, non-redundant, properly documented, thoroughly tested, and seamlessly integrated with the existing 25-agent ecosystem.

Unlike simpler agent creation approaches, this command:
- Performs intelligent needs analysis to determine optimal agent decomposition
- Prevents duplication by analyzing existing agent capabilities
- Generates production-ready agent definitions with rich personas and detailed methodologies
- Creates comprehensive documentation, usage guides, and integration examples
- Validates agent quality through multiple review cycles
- Establishes test scenarios and validates agent invocation patterns
- Updates all relevant ecosystem documentation (CLAUDE.md, registry, guides)

## Multi-Agent Coordination Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                     MASTER STRATEGIST                           │
│              (Orchestration & Coordination Hub)                 │
└────┬────────────────────────────────────────────────────────────┘
     │
     ├─── Phase 1: Discovery Layer ────────────────────────┐
     │    ├── general-purpose (needs analysis)            │
     │    ├── general-purpose (ecosystem search)          │
     │    └── plan-decomposer (decomposition analysis)    │
     │                                                     │
     ├─── Phase 2-3: Design Layer ──────────────────────┐ │
     │    ├── architect-supreme (architecture)          │ │
     │    ├── documentation-expert (persona design)     │ │
     │    └── documentation-expert (prompt engineering) │ │
     │                                                   │ │
     ├─── Phase 4-6: Generation Layer ────────────────┐ │ │
     │    ├── documentation-expert (file generation)   │ │ │
     │    ├── senior-reviewer (quality validation)     │ │ │
     │    └── documentation-expert (doc updates)       │ │ │
     │                                                 │ │ │
     └─── Phase 7-8: Validation Layer ──────────────┐ │ │ │
          ├── test-engineer (test creation)          │ │ │ │
          ├── general-purpose (test execution)       │ │ │ │
          └── senior-reviewer (final approval)       │ │ │ │
                                                     └─┴─┴─┘
```

## Execution Flow

### Phase 1: Requirements Discovery & Analysis (0-10 minutes)

**Objective**: Deeply understand the user's needs and determine optimal agent architecture

**Tasks**:
1. **Initial Needs Gathering** (general-purpose)
   - Collect detailed description of desired agent capabilities
   - Identify specific use cases and scenarios
   - Understand integration requirements with existing workflows
   - Determine performance and quality expectations

2. **Ecosystem Compatibility Analysis** (general-purpose)
   - Search existing 25 agents for similar capabilities
   - Identify potential overlaps or redundancies
   - Analyze integration opportunities with existing agents
   - Map capability gaps in current ecosystem

3. **Decomposition Analysis** (plan-decomposer)
   - Evaluate if single agent or multiple agents needed
   - Identify natural boundaries between responsibilities
   - Assess coordination requirements between potential agents
   - Recommend optimal agent architecture (1 vs N agents)

4. **Requirements Validation** (master-strategist)
   - Synthesize findings from discovery tasks
   - Confirm understanding with user
   - Establish success criteria for new agent(s)
   - Create requirements specification document

### Phase 2: Architecture & Design (10-30 minutes)

**Objective**: Design comprehensive agent architecture with clear responsibilities and interfaces

**Tasks**:
5. **Agent Architecture Design** (architect-supreme)
   - Define agent boundaries and responsibilities
   - Design interaction patterns with other agents
   - Specify input/output interfaces
   - Create capability matrix and decision trees
   - Design error handling and fallback strategies

6. **Persona Development** (documentation-expert)
   - Create distinctive agent personality and voice
   - Define communication style and tone
   - Establish expertise boundaries
   - Design behavioral patterns and principles
   - Craft agent backstory and motivation

7. **Capability Specification** (architect-supreme)
   - Define core competencies in detail
   - Specify knowledge domains
   - Establish quality standards and constraints
   - Design output formats and structures
   - Create decision-making frameworks

8. **Integration Planning** (master-strategist)
   - Map touchpoints with existing agents
   - Design handoff protocols
   - Specify orchestration patterns
   - Plan documentation updates
   - Create integration test scenarios

### Phase 3: Prompt Engineering & Optimization (30-50 minutes)

**Objective**: Craft highly effective prompts that embody agent design

**Tasks**:
9. **Core Prompt Development** (documentation-expert)
   - Write comprehensive identity section
   - Develop detailed expertise descriptions
   - Create methodology frameworks
   - Design pattern libraries
   - Establish principle hierarchies

10. **Prompt Optimization** (documentation-expert)
    - Refine instruction clarity and specificity
    - Optimize token efficiency
    - Enhance reasoning chains
    - Strengthen guardrails and constraints
    - Validate prompt coherence

11. **Example Generation** (documentation-expert)
    - Create 5-10 realistic usage examples
    - Design edge case scenarios
    - Develop integration examples
    - Write error handling examples
    - Generate output format samples

12. **Prompt Validation** (senior-reviewer)
    - Review prompt completeness
    - Validate alignment with requirements
    - Check for ambiguities or conflicts
    - Assess prompt engineering best practices
    - Verify ecosystem compatibility

### Phase 4: File Generation & Structure (50-65 minutes)

**Objective**: Generate production-ready agent definition files

**Tasks**:
13. **Agent File Creation** (documentation-expert)
    - Generate `.claude/agents/{name}.md` file(s)
    - Write YAML frontmatter with metadata
    - Structure prompt body with all sections
    - Include comprehensive examples
    - Add integration notes and warnings

14. **Supporting File Generation** (documentation-expert)
    - Create usage guide documents
    - Generate integration examples
    - Write troubleshooting guides
    - Develop best practices documentation
    - Create quick reference cards

15. **Code Example Generation** (code-generator-typescript)
    - Generate TypeScript integration examples (if needed)
    - Create Python usage examples (if needed)
    - Write orchestration code samples
    - Develop test harness code
    - Generate mock response examples

### Phase 5: Quality Validation & Review (65-80 minutes)

**Objective**: Ensure agent quality meets highest standards

**Tasks**:
16. **Technical Review** (senior-reviewer)
    - Validate technical accuracy
    - Check prompt engineering quality
    - Verify capability boundaries
    - Assess error handling completeness
    - Review integration patterns

17. **Documentation Review** (senior-reviewer)
    - Check documentation completeness
    - Validate example quality
    - Verify clarity and readability
    - Assess user guidance adequacy
    - Review troubleshooting coverage

18. **Consistency Check** (general-purpose)
    - Verify naming consistency
    - Check format adherence
    - Validate cross-references
    - Ensure version compatibility
    - Review dependency accuracy

### Phase 6: Integration & Documentation Updates (80-95 minutes)

**Objective**: Fully integrate new agent(s) into ecosystem documentation

**Tasks**:
19. **CLAUDE.md Updates** (documentation-expert)
    - Update agent registry section
    - Add to relevant workflow examples
    - Update orchestration patterns
    - Modify best practices sections
    - Add to troubleshooting guides

20. **Registry Updates** (documentation-expert)
    - Add agent to official registry
    - Update capability matrices
    - Modify agent relationship diagrams
    - Update performance benchmarks
    - Add to agent comparison tables

21. **Guide Creation** (documentation-expert)
    - Write getting started guide
    - Create migration guide (if replacing existing functionality)
    - Develop cookbook recipes
    - Write performance tuning guide
    - Create debugging guide

### Phase 7: Testing & Validation (95-110 minutes)

**Objective**: Thoroughly test new agent(s) to ensure proper functioning

**Tasks**:
22. **Test Scenario Creation** (test-engineer)
    - Design unit test scenarios
    - Create integration test cases
    - Develop end-to-end workflows
    - Design edge case tests
    - Create performance benchmarks

23. **Test Execution** (general-purpose)
    - Run basic invocation tests
    - Execute integration scenarios
    - Validate output formats
    - Test error handling
    - Verify performance characteristics

24. **Results Analysis** (test-engineer)
    - Analyze test results
    - Identify failure patterns
    - Assess performance metrics
    - Evaluate quality scores
    - Generate test report

### Phase 8: Finalization & Deployment (110-120 minutes)

**Objective**: Complete agent creation and prepare for production use

**Tasks**:
25. **Final Adjustments** (documentation-expert)
    - Apply fixes from testing
    - Refine based on test results
    - Update documentation with findings
    - Optimize performance issues
    - Enhance error messages

26. **Deployment Preparation** (master-strategist)
    - Create deployment checklist
    - Generate release notes
    - Prepare announcement template
    - Update change logs
    - Create rollback plan

27. **User Communication** (general-purpose)
    - Generate summary report
    - Create usage instructions
    - Provide integration guide
    - Share best practices
    - Deliver final recommendations

## Agent Coordination Layers

### Discovery Layer (Phase 1)
**Lead**: master-strategist
**Agents**: general-purpose (2x), plan-decomposer
**Responsibility**: Understanding requirements, analyzing ecosystem, determining architecture

### Design Layer (Phases 2-3)
**Lead**: architect-supreme
**Agents**: documentation-expert, senior-reviewer
**Responsibility**: Creating agent architecture, developing personas, engineering prompts

### Generation Layer (Phase 4)
**Lead**: documentation-expert
**Agents**: code-generator-typescript
**Responsibility**: Generating all files, documentation, and code examples

### Validation Layer (Phase 5)
**Lead**: senior-reviewer
**Agents**: general-purpose
**Responsibility**: Ensuring quality, consistency, and completeness

### Integration Layer (Phase 6)
**Lead**: documentation-expert
**Agents**: general-purpose
**Responsibility**: Updating ecosystem documentation and guides

### Testing Layer (Phase 7)
**Lead**: test-engineer
**Agents**: general-purpose
**Responsibility**: Creating and executing comprehensive tests

### Finalization Layer (Phase 8)
**Lead**: master-strategist
**Agents**: documentation-expert, general-purpose
**Responsibility**: Final adjustments, deployment, and user communication

## Usage Examples

### Example 1: Creating a Data Analysis Specialist

<example>
**Context**: User needs an agent specialized in data analysis and visualization

**User**: /create-agent

**Assistant (Phase 1 - Discovery)**:
I'll help you create a new specialized agent. Let me start by understanding your needs.

*general-purpose agent analyzing requirements...*

What specific capabilities do you need this agent to have? Please describe:
1. Primary use cases
2. Types of data it will work with
3. Expected outputs (reports, visualizations, insights)
4. Integration needs with existing tools

**User**: I need an agent that can analyze CSV/JSON data, create visualizations, identify patterns, and generate insight reports. It should work with pandas, matplotlib, and integrate with our existing data-pipeline agent.

**Assistant (Phase 1 - Ecosystem Analysis)**:
*general-purpose agent searching existing agents...*

I've analyzed our existing 25 agents. While we have:
- `data-pipeline`: Handles data ingestion and transformation
- `senior-reviewer`: Can review data quality
- `architect-supreme`: Can design data architectures

We don't have a dedicated data analysis and visualization specialist. This is a valid gap.

*plan-decomposer analyzing architecture...*

**Recommendation**: Single agent "data-analyst" is optimal. It has clear, cohesive responsibilities around analysis and visualization that don't require decomposition.

**Assistant (Phase 2-3 - Design & Prompt Engineering)**:
*architect-supreme designing architecture...*
*documentation-expert creating persona and prompts...*

Designing agent with:
- **Core Skills**: Statistical analysis, pattern recognition, visualization
- **Tools**: pandas, matplotlib, seaborn, plotly integration
- **Outputs**: Insight reports, interactive dashboards, statistical summaries
- **Personality**: Methodical, detail-oriented, clear communicator

[Continues through all phases...]

**Final Output**:
✅ Created: `.claude/agents/data-analyst.md`
✅ Updated: CLAUDE.md agent registry
✅ Generated: 5 test scenarios, 10 usage examples
✅ Integration verified with data-pipeline agent
</example>

### Example 2: Creating Multiple Security Agents

<example>
**Context**: User needs comprehensive security coverage

**User**: /create-agent - I need security agents to handle vulnerability scanning, threat analysis, compliance checking, and incident response

**Assistant (Phase 1 - Decomposition Analysis)**:
*plan-decomposer analyzing requirements...*

This requires multiple specialized agents due to distinct expertise domains:

1. **security-scanner**: Vulnerability scanning and assessment
2. **threat-analyst**: Threat intelligence and analysis
3. **compliance-auditor**: Regulatory compliance verification
4. **incident-responder**: Security incident handling

Each has unique knowledge requirements and methodologies that warrant separate agents working in coordination.

[Creates 4 coordinated agents through all phases...]
</example>

### Example 3: Enhancing Existing Agent

<example>
**Context**: User wants to extend capabilities of existing agent

**User**: /create-agent - The code-generator-python agent needs machine learning capabilities

**Assistant (Phase 1 - Analysis)**:
*general-purpose analyzing existing agent...*

The `code-generator-python` agent exists but lacks ML-specific capabilities.

**Options**:
1. Extend existing agent (not recommended - violates single responsibility)
2. Create new `ml-engineer-python` agent that coordinates with code-generator-python

**Recommendation**: Create specialized `ml-engineer-python` agent for:
- Scikit-learn, TensorFlow, PyTorch code generation
- Model architecture design
- Training pipeline creation
- Hyperparameter tuning code

[Continues with new agent creation...]
</example>

### Example 4: Test-Drive Before Commitment

<example>
**Context**: User wants to test agent concept before full creation

**User**: /create-agent --dry-run - Create a copywriting specialist

**Assistant (Phase 1-3 - Design Only)**:
Running in dry-run mode. I'll design the agent and create a test prompt without generating files.

*Completes Phases 1-3 only*

**Test Prompt Generated**:
```markdown
You are the copywriting specialist...
[Full prompt for testing]
```

You can test this prompt directly. If satisfied, run without --dry-run to complete full creation.
</example>

### Example 5: Replacing Deprecated Functionality

<example>
**Context**: Replacing manual workflow with specialized agent

**User**: /create-agent - We manually handle API documentation but need an agent for this

**Assistant (Phase 1)**:
*general-purpose analyzing workflow...*

I'll create an `api-documenter` agent to automate your API documentation workflow.

**Current Manual Process**:
1. Extract endpoints from code
2. Document parameters and responses
3. Generate OpenAPI specs
4. Create usage examples

**Agent Design**:
- Auto-generates OpenAPI/Swagger specs
- Creates interactive documentation
- Generates client SDKs
- Maintains versioning

[Creates agent with migration guide from manual process...]
</example>

## Expected Outputs

Upon successful completion, the command generates:

### Primary Outputs
1. **Agent Definition Files** (`.claude/agents/{name}.md`)
   - Complete YAML frontmatter with metadata
   - Comprehensive prompt body (2000-4000 words)
   - 5-10 detailed usage examples
   - Integration notes and warnings
   - Model selection (opus/sonnet)

2. **Documentation Updates**
   - CLAUDE.md agent registry entry
   - Updated orchestration patterns
   - Modified workflow examples
   - Enhanced best practices

3. **Usage Guides**
   - Getting started guide (500-1000 words)
   - Integration cookbook (10+ recipes)
   - Troubleshooting guide
   - Performance tuning recommendations

4. **Test Artifacts**
   - Unit test scenarios (10-15 tests)
   - Integration test cases (5-10 tests)
   - End-to-end workflows (3-5 workflows)
   - Test execution reports
   - Performance benchmarks

5. **Integration Materials**
   - Code examples (TypeScript/Python as needed)
   - Orchestration patterns
   - Handoff protocols
   - Error handling examples

### Metadata and Tracking
- Creation timestamp and version
- Author attribution
- Dependency mappings
- Performance baselines
- Quality metrics

### Communication Deliverables
- Executive summary (for stakeholders)
- Technical specification (for developers)
- Usage instructions (for end users)
- Release notes
- Change log entries

## Success Criteria

The agent creation process is considered successful when ALL of the following criteria are met:

### Functional Criteria
1. ✅ **Unique Value**: Agent fills genuine gap in ecosystem without duplicating existing capabilities
2. ✅ **Clear Boundaries**: Agent has well-defined responsibilities that don't overlap unnecessarily
3. ✅ **Comprehensive Prompt**: Agent prompt includes all required sections and is 2000+ words
4. ✅ **Rich Examples**: At least 5 detailed usage examples demonstrating various scenarios
5. ✅ **Proper Integration**: Agent correctly integrates with existing ecosystem agents

### Quality Criteria
6. ✅ **Test Coverage**: All core capabilities have test scenarios with >90% pass rate
7. ✅ **Documentation Complete**: All documentation sections present and comprehensive
8. ✅ **Performance Validated**: Agent responds within acceptable time limits (<30s for most tasks)
9. ✅ **Error Handling**: Graceful handling of edge cases and error conditions
10. ✅ **Consistent Voice**: Agent maintains consistent personality and communication style

### Technical Criteria
11. ✅ **Format Compliance**: Files follow exact required format and structure
12. ✅ **Model Optimization**: Correct model selected (opus for complex, sonnet for simple)
13. ✅ **Token Efficiency**: Prompts optimized for token usage without sacrificing quality
14. ✅ **Version Compatibility**: Works with current Claude API versions
15. ✅ **Dependency Management**: All dependencies clearly documented and available

### Integration Criteria
16. ✅ **Registry Updated**: Agent properly added to all registries and indices
17. ✅ **Cross-references Valid**: All documentation cross-references are accurate
18. ✅ **Orchestration Patterns**: Agent works in defined orchestration patterns
19. ✅ **Handoff Protocols**: Clean handoffs to/from other agents
20. ✅ **Rollback Plan**: Clear rollback procedure if issues arise

## Notes

### Best Practices for Agent Creation

**Agent Naming Conventions**:
- Use lowercase with hyphens: `data-analyst`, `security-scanner`
- Be specific but concise: prefer `code-reviewer-python` over `reviewer`
- Include domain qualifiers when needed: `ml-engineer`, `devops-automator`
- Avoid generic names: not `helper`, `assistant`, `general`

**Prompt Engineering Guidelines**:
- Start with strong identity statement
- Use specific, actionable language
- Include both positive (do) and negative (don't) instructions
- Provide reasoning frameworks, not just rules
- Include self-correction mechanisms
- Build in quality checks and validation steps

**Model Selection**:
- **Opus**: Complex reasoning, creative tasks, multi-step workflows, code generation
- **Sonnet**: Focused tasks, data processing, formatting, simple analysis
- When in doubt, start with Sonnet and upgrade if needed

**Integration Patterns**:
- **Sequential Handoff**: Agent A completes, passes to Agent B
- **Parallel Execution**: Multiple agents work simultaneously
- **Iterative Refinement**: Agents loop until quality met
- **Hierarchical Delegation**: Parent agent delegates to specialists
- **Consensus Building**: Multiple agents validate result

### Common Pitfalls to Avoid

1. **Over-broad Scope**: Trying to make one agent do everything
2. **Under-specified Prompts**: Vague instructions leading to inconsistent behavior
3. **Ignoring Existing Agents**: Duplicating functionality already available
4. **Weak Examples**: Generic examples that don't demonstrate real value
5. **Poor Error Handling**: Not planning for failure cases
6. **Insufficient Testing**: Skipping test phases to save time
7. **Documentation Debt**: Creating agent without proper documentation
8. **Integration Afterthought**: Not planning integration from the start

### Performance Optimization Tips

- Keep prompts focused and concise while maintaining completeness
- Use structured output formats to ease parsing
- Implement caching strategies for repeated operations
- Design for incremental processing where possible
- Consider batch operations for multiple items
- Plan for graceful degradation under load

### Maintenance Considerations

- Agents should be versioned with semantic versioning
- Include deprecation notices when replacing agents
- Maintain backwards compatibility when possible
- Document breaking changes clearly
- Plan for migration paths from old to new agents
- Establish regular review cycles for agent effectiveness

### Emergency Procedures

If agent creation fails or causes issues:
1. Check test reports for specific failures
2. Review senior-reviewer feedback for quality issues
3. Verify no conflicts with existing agents
4. Validate all dependencies are available
5. Use rollback plan if agent was partially deployed
6. Escalate to master-strategist for coordination issues
7. Document lessons learned for future improvements

---

*This command represents the pinnacle of agent creation automation, leveraging the full power of multi-agent orchestration to ensure every new agent is a valuable, well-integrated addition to your AI ecosystem.*