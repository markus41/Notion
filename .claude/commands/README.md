# Slash Commands - Brookside BI Innovation Nexus

**Best for**: Organizations seeking streamlined innovation workflows through repeatable, structured operations designed to drive measurable outcomes while maintaining cost transparency and knowledge preservation.

## Quick Start

After restarting Claude Code, these commands become available for immediate use:

```bash
# Capture new innovation opportunity
/innovation:new-idea Automated deployment pipeline for Power BI reports

# Analyze software spending
/cost:analyze

# Archive completed work with learnings
/knowledge:archive "Cost Dashboard MVP" build

# Assign work to team members
/team:assign "Azure integration research" research
```

## Available Commands

### Innovation Workflow

| Command | Purpose | Example |
|---------|---------|---------|
| `/innovation:new-idea` | Capture and structure innovation opportunities | `/innovation:new-idea AI-powered cost tracking` |
| `/innovation:start-research` | Begin feasibility investigation | *Coming soon* |
| `/innovation:create-build` | Structure example builds and prototypes | *Coming soon* |

### Cost Management

| Command | Purpose | Example |
|---------|---------|---------|
| `/cost:analyze` | Comprehensive spend analysis with recommendations | `/cost:analyze active` |
| `/cost:add-software` | Add software to cost tracker | *Coming soon* |
| `/cost:optimize` | Interactive cost reduction workflow | *Coming soon* |

### Knowledge Management

| Command | Purpose | Example |
|---------|---------|---------|
| `/knowledge:archive` | Complete work lifecycle with learnings | `/knowledge:archive "Dashboard" build` |
| `/knowledge:document` | Create Knowledge Vault entry | *Coming soon* |

### Team Workflow

| Command | Purpose | Example |
|---------|---------|---------|
| `/team:assign` | Route work based on specialization | `/team:assign "ML model" idea` |
| `/team:workload` | View team workload distribution | *Coming soon* |

## Command Structure

Each command follows consistent patterns for predictable, reliable execution:

### Frontmatter
Commands include metadata that controls behavior:

```yaml
---
description: Business-focused summary (appears in /help)
allowed-tools: Tool1(pattern:*), Tool2(pattern:*)
argument-hint: [expected parameters]
model: claude-sonnet-4-5-20250929
---
```

### Workflow Pattern
All commands follow this structure:

1. **Search existing content** - Prevent duplicates
2. **Fetch context** - Understand current state
3. **Execute operation** - Create/update with proper linking
4. **Verify and report** - Confirm success, suggest next steps

### Parameter Passing

**Simple parameters** - Use `$ARGUMENTS` for single input:
```bash
/innovation:new-idea This is the complete idea description
# $ARGUMENTS = "This is the complete idea description"
```

**Multiple parameters** - Use positional `$1`, `$2`, `$3`:
```bash
/knowledge:archive "Cost Dashboard" build
# $1 = "Cost Dashboard"
# $2 = "build"
```

**Default values** - Commands provide sensible defaults:
```bash
/cost:analyze
# Defaults to scope = "all"

/cost:analyze unused
# Overrides scope to "unused"
```

## Agent Integration

Commands delegate complex workflows to specialized agents from `.claude/agents/`:

- **@ideas-capture** - Innovation opportunity structuring
- **@cost-analyst** - Financial analysis and optimization
- **@archive-manager** - Lifecycle completion and knowledge preservation
- **@workflow-router** - Team assignment and workload balancing
- **@knowledge-curator** - Knowledge Vault curation
- **@build-architect** - Technical documentation and build structuring
- **@research-coordinator** - Research management and feasibility studies

Commands invoke agents using explicit syntax:
```markdown
Invoke @cost-analyst agent to execute comprehensive cost analysis:
1. Query Software Tracker...
2. Calculate spending metrics...
```

## Namespace Organization

Commands are organized by functional area in subdirectories:

```
.claude/commands/
├── innovation/     # Idea, research, build workflows
├── cost/           # Financial analysis and tracking
├── knowledge/      # Documentation and archival
└── team/           # Assignment and workload management
```

**Invocation syntax**: `/category:command-name`

Example: `/innovation:new-idea` executes `innovation/new-idea.md`

## Usage Examples

### Complete Innovation Lifecycle

```bash
# 1. Capture initial idea
/innovation:new-idea Automated cost tracking dashboard for software spend
# Output: Created idea with champion assignment, cost estimate, next steps

# 2. Start research (once implemented)
/innovation:start-research "Cost tracking automation feasibility" "Automated cost tracking dashboard"
# Output: Research entry with team, documentation links, cost tracking

# 3. Create build (once implemented)
/innovation:create-build "Cost Dashboard MVP" mvp
# Output: Build entry with GitHub link, technical docs, team assignments, total cost

# 4. Archive when complete
/knowledge:archive "Cost Dashboard MVP" build
# Output: Archived with Knowledge Vault entry, preserved links, learnings documented
```

### Quarterly Cost Review

```bash
# 1. Overall analysis
/cost:analyze
# Output: Total spend, top expenses, optimization opportunities, category breakdown

# 2. Find unused software
/cost:analyze unused
# Output: Tools with no active work, potential savings

# 3. Check expiring contracts
/cost:analyze expiring
# Output: Renewals needed in next 60 days, decision deadlines
```

### Team Workload Management

```bash
# 1. Assign new work
/team:assign "Azure OpenAI integration for Power BI" build
# Output: Recommended team member with rationale, workload status, alternatives

# 2. Check team workload (once implemented)
/team:workload
# Output: Full team distribution, overloaded members, recommendations
```

## Best Practices

### DO: Effective Command Usage

1. **Use consistent formatting** when passing parameters
   - Quote multi-word parameters: `/command "parameter with spaces"`
   - Provide complete context in descriptions

2. **Review command output** for next steps
   - Commands suggest follow-up actions
   - Look for cost impacts and optimization opportunities

3. **Leverage command chaining** for complete workflows
   - `/innovation:new-idea` → `/innovation:start-research` → `/innovation:create-build` → `/knowledge:archive`

4. **Check verification steps** to confirm success
   - Commands include validation queries
   - Use `/notion:search` to verify entries created

5. **Trust agent delegation**
   - Commands invoke specialized agents for complex workflows
   - Agents apply consistent patterns and brand voice

### DON'T: Common Mistakes

1. **Don't skip parameters** when required
   - Check `argument-hint` in `/help` for expected format
   - Use quotes for multi-word parameters

2. **Don't create duplicates**
   - Commands search existing content first
   - Review matches before proceeding

3. **Don't ignore cost implications**
   - Commands display cost impacts
   - Link software/tools for accurate tracking

4. **Don't forget to archive**
   - Use `/knowledge:archive` when work completes
   - Preserve learnings for future reference

## Getting Help

```bash
# View all available commands with descriptions
/help

# View documentation for specific command (once implemented)
/help innovation:new-idea
```

## Creating Custom Commands

See `SLASH_COMMANDS_GUIDE.md` for comprehensive guide on:

- Command structure standards
- Frontmatter configuration
- Parameter passing conventions
- Agent integration patterns
- Brookside BI brand voice application
- Testing and validation procedures

## Roadmap

**Planned Commands** (Priority Order):

### Phase 1: Core Innovation Workflow
- `/innovation:start-research` - Research initiation
- `/innovation:create-build` - Build structuring
- `/innovation:update-status` - Lifecycle progression

### Phase 2: Enhanced Cost Management
- `/cost:add-software` - Software entry creation
- `/cost:optimize` - Interactive optimization
- `/cost:forecast` - Budget projection

### Phase 3: Knowledge Operations
- `/knowledge:document` - Manual Knowledge Vault entry
- `/knowledge:search` - Semantic search across vault
- `/knowledge:suggest` - Related content recommendations

### Phase 4: Team Collaboration
- `/team:workload` - Workload visualization
- `/team:reassign` - Work redistribution
- `/team:report` - Status reporting

### Phase 5: Notion Operations
- `/notion:search` - Cross-database search
- `/notion:sync-databases` - Database ID refresh
- `/notion:backup` - Workspace backup

## Support

Questions or issues with commands:

- Review: `SLASH_COMMANDS_GUIDE.md` for detailed documentation
- Check: Project CLAUDE.md for agent descriptions and workflows
- Contact: Consultations@BrooksideBI.com

---

**Brookside BI Innovation Nexus - Streamline Workflows Through Structured Commands**

Designed for organizations scaling innovation management across teams, these commands establish sustainable practices that drive measurable outcomes while maintaining cost transparency and knowledge preservation.
