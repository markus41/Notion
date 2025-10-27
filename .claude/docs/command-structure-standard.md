# Command Structure Standard

**Brookside BI Innovation Nexus - Establish consistent command documentation to streamline workflow automation and improve cross-team clarity.**

**Best for**: Organizations scaling automation infrastructure across teams with standardized command patterns and comprehensive documentation requirements.

---

## Purpose

This standard defines the universal structure for all slash command documentation files within the Brookside BI Innovation Nexus. Consistent command documentation ensures:

- **Predictable Implementation**: Teams execute commands with confidence across all databases
- **Streamlined Onboarding**: New team members understand command capabilities rapidly
- **Sustainable Maintenance**: Updates follow established patterns for long-term clarity
- **AI Agent Compatibility**: Claude and specialized agents parse and execute commands reliably

---

## Universal Command Template

Every command file must follow this exact structure. Copy this template when creating new command documentation.

```markdown
# /[category]:[action]

**Category**: [Innovation|Cost|Knowledge|Team|Repo|Autonomous|Docs|Style]
**Related Databases**: [Database Name 1, Database Name 2, Database Name 3]
**Agent Compatibility**: [@agent-name1, @agent-name2, @agent-name3]
**Last Updated**: YYYY-MM-DD

---

## Purpose

[2-3 sentence business value statement leading with outcomes, followed by technical implementation details. Apply Brookside BI brand voice: solution-focused, consultative, emphasizing measurable results and sustainable practices.]

**Best for**: [Target audience and primary use case - be specific about organizational context]

---

## Parameters

### Required Parameters

- **`parameter-name`** (type: string|number|boolean|array): [Detailed description including constraints, format requirements, and business context]
- **`second-parameter`** (type: string): [Description with examples of valid inputs]

### Optional Parameters

- **`--flag-name`** (type: boolean, default: false): [Description of flag behavior and when to use]
- **`--option-name`** (type: string, default: "value"): [Description with valid options listed]

### Parameter Validation Rules

- [Constraint 1: e.g., "parameter-name must not exceed 100 characters"]
- [Constraint 2: e.g., "numeric-parameter must be between 0 and 100"]
- [Constraint 3: e.g., "date-parameter must be in YYYY-MM-DD format"]

---

## Workflow

This command executes the following steps to ensure reliable, idempotent operations:

### Step 1: Validation
- Verify all required parameters are provided
- Check parameter types and format constraints
- Validate business rules (e.g., viability scores 0-100, valid status values)

### Step 2: Duplicate Detection
- **Notion Operation**: `notion-search`
- **Target Database**: [Database Name with ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx]
- **Query**: Search for existing entries matching [criteria]
- **Behavior if Found**: [Describe whether to skip, update, or prompt user]

### Step 3: Data Retrieval (if applicable)
- **Notion Operation**: `notion-fetch`
- **Target**: [Related page/database to fetch for context]
- **Purpose**: [Why this data is needed - e.g., validate relations, get parent context]

### Step 4: Create/Update Entry
- **Notion Operation**: `notion-create-pages` OR `notion-update-page`
- **Target Database**: [Database Name with ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx]
- **Properties Set**:
  - `Property Name 1`: [Value or derivation logic]
  - `Property Name 2`: [Value or derivation logic]
  - `Status`: [Default status emoji + text]
  - `Created Date`: [Auto-timestamp]

### Step 5: Establish Relations
- **Notion Operation**: `notion-update-page` (for relation properties)
- **Relations to Set**:
  - Link to [Related Database 1]: [Criteria for linking]
  - Link to [Related Database 2]: [Criteria for linking]
- **Validation**: Verify all required relations are established successfully

### Step 6: Trigger Downstream Automation (if applicable)
- [Describe any webhook triggers, Azure Functions, or agent handoffs]
- [Specify conditions that trigger downstream processes]
- [Document expected outcomes from automation]

### Step 7: Activity Logging
- **Notion Operation**: `notion-create-pages`
- **Target Database**: Agent Activity Hub (ID: 7163aa38-f3d9-444b-9674-bde61868bd2b)
- **Log Entry Includes**:
  - Command executed
  - Parameters used
  - Databases modified
  - Timestamp
  - Related work links

### Step 8: Confirmation
- Return success message with:
  - Created/updated entry title and URL
  - Related entries linked
  - Next recommended actions

---

## Examples

### Example 1: [Common Use Case - Descriptive Scenario Name]

```bash
/category:action "primary-parameter-value" --optional-flag
```

**Context**: [When you would use this - specific business scenario]

**Expected Outcome**:
- Creates entry in [Database Name] with status [Status Emoji Status Text]
- Links to [Related Database] entry for [context]
- Triggers [downstream automation if applicable]

**Notion Updates**:
- **[Database Name 1]**: New page created with properties X, Y, Z
- **[Database Name 2]**: Relation established to newly created entry
- **Agent Activity Hub**: Activity log entry recorded

**Success Verification**:
```bash
# Fetch the created entry to verify
notion-fetch [page-id-from-creation]
```

---

### Example 2: [Alternative Scenario with Optional Parameters]

```bash
/category:action "parameter-value" --flag=custom-value
```

**Context**: [Different business scenario requiring optional parameters]

**Expected Outcome**:
- [Different behavior due to optional parameters]
- [Different downstream effects]

**Notion Updates**:
- **[Database Name]**: Entry created with modified properties due to flag

---

### Example 3: [Edge Case or Complex Scenario]

```bash
/category:action "complex-parameter" --flag1 --flag2=value
```

**Context**: [Advanced use case combining multiple parameters]

**Expected Outcome**:
- [Multi-step process outcome]
- [Multiple database updates]
- [Complex relation structure]

**Notion Updates**:
- **[Database Name 1]**: [Specific changes]
- **[Database Name 2]**: [Specific changes]
- **[Database Name 3]**: [Specific changes]

---

### Example 4: [Error Recovery Scenario]

```bash
/category:action "parameter-with-potential-duplicate"
```

**Context**: [When duplicate detection prevents creation]

**Expected Outcome**:
- Duplicate detected in [Database Name]
- User prompted with options: Update existing | Create anyway | Cancel
- [Behavior based on user selection]

**Notion Updates**:
- **If Update Selected**: Existing entry modified with new parameters
- **If Create Anyway**: New entry created with disambiguation in title
- **If Cancel**: No changes made

---

### Example 5: [Integration with Other Commands]

```bash
# Step 1: Execute this command
/category:action "initial-parameter"

# Step 2: Follow up with related command
/related-category:related-action "follow-up-parameter"
```

**Context**: [Workflow requiring multiple commands in sequence]

**Expected Outcome**:
- First command establishes foundation in [Database Name 1]
- Second command builds upon first entry in [Database Name 2]
- Combined workflow achieves [business outcome]

**Notion Updates**:
- **[Database Name 1]**: Base entry created
- **[Database Name 2]**: Dependent entry linked to base
- **Relations**: Bidirectional links established for traceability

---

## Error Handling

### Duplicate Entry Detected

**Trigger**: Notion search finds existing entry matching parameters

**Behavior**:
- Display existing entry title, status, and URL
- Prompt user with options:
  - `Update`: Merge new parameters with existing entry
  - `Create New`: Proceed with creation (append timestamp to title for disambiguation)
  - `Cancel`: Abort operation without changes
- Log decision to Agent Activity Hub

**Prevention**: Use `--force-new` flag to skip duplicate detection (use with caution)

---

### Validation Failed

**Trigger**: Parameter constraints violated (type, format, business rules)

**Behavior**:
- Display specific validation error with parameter name and constraint violated
- Provide example of valid input format
- Do not execute any Notion operations
- Log validation failure to Agent Activity Hub for pattern analysis

**Example Error Message**:
```
Validation Error: Parameter 'viability-score' must be number between 0-100.
Received: "high" (string)
Valid Example: 85
```

---

### Notion API Error

**Trigger**: MCP server returns error (rate limit, network timeout, permission denied)

**Behavior**:
- **Rate Limit (429)**: Wait 60 seconds, retry up to 3 times with exponential backoff
- **Network Timeout (408)**: Retry immediately up to 2 times
- **Permission Denied (403)**: Display error with database name and required permissions
- **Not Found (404)**: Verify database ID in command configuration, suggest checking `.claude/docs/notion-schema.md`
- **Other Errors**: Display full error message and suggest manual verification in Notion workspace

**Logging**: All API errors logged to Agent Activity Hub with full context for troubleshooting

---

### Missing Required Parameter

**Trigger**: Command invoked without all required parameters

**Behavior**:
- Display usage syntax with all parameters clearly marked (required vs optional)
- Provide example command with sample values
- Do not execute any Notion operations
- Suggest related commands if user intent might be better served elsewhere

**Example Error Message**:
```
Missing Required Parameter: 'description'

Usage:
  /category:action "description" [--optional-flag]

Example:
  /category:action "Automate cost tracking workflow" --priority=high

Required Parameters:
  - description (string): Detailed description of work to be done

Optional Parameters:
  - --priority (string, default: "medium"): Priority level [low|medium|high]
```

---

### Partial Failure in Multi-Step Workflow

**Trigger**: Operation fails after some steps completed successfully (e.g., entry created but relation failed)

**Behavior**:
- Log all completed steps with Notion page IDs
- Display error message indicating failure point
- Provide manual recovery instructions with specific page URLs
- Do not attempt automatic rollback (preserve completed work)
- Create draft entry in Agent Activity Hub documenting partial completion

**Example Recovery Message**:
```
Partial Completion: Entry created successfully but relation to Software Tracker failed.

Completed Steps:
  ✅ Created entry in Ideas Registry: https://notion.so/[page-id]
  ❌ Failed to link Software Tracker relation

Manual Recovery:
  1. Open created entry: https://notion.so/[page-id]
  2. Add relation to Software Tracker manually in Notion UI
  3. Verify relation established successfully

Error Details: [Full API error message]
```

---

## Success Criteria

Verify the command executed successfully by confirming:

- ✅ **Entry Created/Updated**: Target database contains entry with correct title and properties
- ✅ **Status Set Correctly**: Status field matches expected value for command (e.g., 🔵 Concept for new ideas)
- ✅ **Relations Established**: All required relations to other databases are active and bidirectional
- ✅ **No Duplicates**: Search confirms no unintended duplicate entries created
- ✅ **Activity Logged**: Agent Activity Hub contains entry for this command execution
- ✅ **Downstream Triggered**: Any expected webhooks, Azure Functions, or agent handoffs initiated (if applicable)
- ✅ **User Notification**: Success message displayed with next recommended actions

---

## Related Commands

### Complementary Commands

- **`/related:command1`**: [When to use this instead - different scenario or database]
- **`/related:command2`**: [Use after this command for workflow continuation]
- **`/related:command3`**: [Alternative approach for similar outcome]

### Workflow Sequences

**Common Pattern 1**:
```bash
/category:action "initial-work"      # Start workflow
/related:next-step "follow-up"       # Continue workflow
/related:finalize "completion"       # Complete workflow
```

**Common Pattern 2**:
```bash
/category:action "primary"           # Execute primary operation
/team:assign "assignment"            # Delegate to specialist
/autonomous:enable "automation"      # Enable autonomous processing
```

---

## Best Practices

### When to Use This Command

**Ideal Scenarios**:
- [Specific business context 1]
- [Specific business context 2]
- [Specific business context 3]

**Avoid Using When**:
- [Scenario where different command is more appropriate]
- [Scenario where manual Notion operation is preferable]
- [Scenario where command would create unnecessary overhead]

### Performance Considerations

- **Typical Execution Time**: [X seconds for simple case, Y seconds for complex case]
- **Notion API Calls**: [Number of API calls made - impacts rate limits]
- **Database Locks**: [Whether command locks databases - affects concurrent operations]

### Security & Compliance

- **Credentials Required**: [Azure authentication, Notion API token, GitHub PAT, etc.]
- **Data Sensitivity**: [Whether command handles sensitive data requiring special handling]
- **Audit Trail**: [What gets logged to Agent Activity Hub for compliance]

---

## Troubleshooting

### Common Issues

**Issue**: [Specific problem users might encounter]

**Cause**: [Root cause explanation]

**Resolution**:
1. [Step-by-step resolution]
2. [Verification command or action]
3. [Prevention for future]

---

**Issue**: [Second common problem]

**Cause**: [Root cause explanation]

**Resolution**:
1. [Step-by-step resolution]
2. [Verification command or action]

---

## Implementation Notes

### Technical Requirements

- **Notion MCP Server**: Minimum version X.X.X
- **Azure CLI**: Required for [specific commands only]
- **PowerShell**: Version 7.0+ for [specific commands only]
- **Environment Variables**: [Required variables with example values]

### Database Dependencies

This command requires the following databases to exist with specific schemas:

- **[Database Name 1]** (ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
  - Required Properties: [Property 1, Property 2, Property 3]
  - Required Relations: [Relation to Database X, Relation to Database Y]

- **[Database Name 2]** (ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
  - Required Properties: [Property 1, Property 2]
  - Required Relations: [Relation to Database Z]

### Agent Handoff Protocol

When this command triggers agent handoff:

1. **Handoff Trigger**: [Conditions that initiate handoff]
2. **Target Agent**: [@agent-name with specialization]
3. **Context Provided**: [What information is passed to receiving agent]
4. **Expected Timeline**: [How long handoff should take]
5. **Verification**: [How to confirm handoff succeeded]

---

**Last Updated**: YYYY-MM-DD | **Maintained By**: [Agent or team responsible]
**Related Documentation**: [Links to related docs in .claude/docs/]
```

---

## Section Definitions

### Header Block (Required)

**Purpose**: Establish command identity and categorization for quick reference.

**Required Elements**:
- **Command Name**: `/category:action` format following consistent naming conventions
- **Category**: One of the established categories (Innovation, Cost, Knowledge, Team, Repo, Autonomous, Docs, Style)
- **Related Databases**: All Notion databases this command interacts with
- **Agent Compatibility**: Which specialized agents can execute this command
- **Last Updated**: Date in YYYY-MM-DD format for version tracking

**Example**:
```markdown
# /innovation:new-idea

**Category**: Innovation
**Related Databases**: Ideas Registry, Software Tracker, Agent Activity Hub
**Agent Compatibility**: @ideas-capture, @viability-assessor, @claude-main
**Last Updated**: 2025-10-26
```

---

### Purpose Section (Required)

**Purpose**: Communicate business value before technical implementation, following Brookside BI brand voice.

**Structure**:
1. **Opening Statement**: 2-3 sentences leading with business outcomes
2. **Technical Summary**: What the command does technically
3. **Best For Qualifier**: Target audience and primary use case with organizational context

**Brand Voice Application**:
- Lead with measurable outcomes ("streamline workflow," "drive visibility," "establish structure")
- Use consultative language ("designed for," "best for organizations scaling")
- Emphasize sustainability and scalability
- Professional but approachable tone

**Example**:
```markdown
## Purpose

Capture new innovation opportunities with structured viability assessment to streamline idea management and improve decision-making visibility. This command creates entries in the Ideas Registry with automatic software/tool tracking, viability scoring, and team assignment routing—ensuring no ideas are lost and all opportunities are evaluated consistently.

**Best for**: Organizations scaling innovation programs across multiple teams requiring standardized idea capture and transparent evaluation processes.
```

---

### Parameters Section (Required)

**Purpose**: Define all command inputs with explicit types, constraints, and business context.

**Structure**:
- **Required Parameters**: Must be provided for command to execute
- **Optional Parameters**: Modify behavior but have sensible defaults
- **Parameter Validation Rules**: Constraints that prevent errors

**Parameter Format**:
```markdown
- **`parameter-name`** (type: string|number|boolean|array, default: "value" if optional): Description including business context, format requirements, and valid examples
```

**Validation Rules**:
- All parameters must specify data type
- Constraints must be explicit (ranges, formats, valid options)
- Defaults must be documented for optional parameters
- Examples must be provided for complex formats

**Example**:
```markdown
## Parameters

### Required Parameters

- **`idea-description`** (type: string): Detailed description of the innovation opportunity, including business problem addressed and expected impact. Minimum 20 characters, maximum 500 characters.
- **`category`** (type: string): Primary innovation category. Valid options: "Process Automation", "Data Platform", "AI/ML", "Integration", "Security", "Cost Optimization"

### Optional Parameters

- **`--priority`** (type: string, default: "medium"): Initial priority assessment. Valid options: "low", "medium", "high"
- **`--assign-to`** (type: string, default: auto-assign by category): Team member to assign for initial review. Valid values: member names from Team Structure documentation.

### Parameter Validation Rules

- `idea-description` must not contain only whitespace or special characters
- `category` must match one of the six valid options exactly (case-sensitive)
- `--priority` defaults to "medium" if not specified
- `--assign-to` validates against current team member roster
```

---

### Workflow Section (Required)

**Purpose**: Provide explicit, idempotent, step-by-step execution instructions for AI agent consumption.

**Structure**:
- Numbered steps with clear headings
- Notion MCP operation specified for each database interaction
- Target database with ID for precise routing
- Expected outcome for each step
- Conditional logic clearly documented

**Step Format**:
```markdown
### Step X: [Action Description]
- **Notion Operation**: `notion-operation-name`
- **Target Database**: [Database Name with ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx]
- **Query/Data**: [What is searched/created/updated]
- **Behavior**: [What happens with the result]
```

**Validation Requirements**:
- Every Notion operation must specify the exact MCP tool name
- All database IDs must match canonical IDs in notion-schema.md
- Conditional branches must have explicit "if-then-else" logic
- Error scenarios must have documented recovery paths

**Example**:
```markdown
## Workflow

### Step 1: Validation
- Verify `idea-description` meets length requirements (20-500 chars)
- Check `category` against valid options list
- Confirm `--assign-to` exists in team roster (if provided)
- Abort with error message if any validation fails

### Step 2: Duplicate Detection
- **Notion Operation**: `notion-search`
- **Target Database**: Ideas Registry (ID: 984a4038-3e45-4a98-8df4-fd64dd8a1032)
- **Query**: Search for ideas with matching description (fuzzy match >80% similarity)
- **Behavior if Found**: Prompt user with options [Update | Create New | Cancel]

### Step 3: Create Idea Entry
- **Notion Operation**: `notion-create-pages`
- **Target Database**: Ideas Registry (ID: 984a4038-3e45-4a98-8df4-fd64dd8a1032)
- **Properties Set**:
  - `Idea Name`: First 100 chars of idea-description
  - `Full Description`: Complete idea-description
  - `Category`: Provided category value
  - `Status`: "🔵 Concept"
  - `Viability`: "❓ Needs Assessment"
  - `Created Date`: Current timestamp
  - `Assigned To`: Auto-assigned by category or provided --assign-to value
```

---

### Examples Section (Required - Minimum 3)

**Purpose**: Demonstrate real-world usage scenarios with executable commands and expected outcomes.

**Requirements**:
- Minimum 3 examples, recommended 5
- Cover common use case, alternative scenario, edge case, error recovery, and integration pattern
- All examples must be executable (no placeholder values like "your-value-here")
- Include context, expected outcome, and Notion updates for each

**Example Format**:
```markdown
### Example X: [Descriptive Scenario Name]

\```bash
/category:action "actual-parameter-value" --flag=actual-value
\```

**Context**: [When you would use this - specific business scenario]

**Expected Outcome**:
- [Specific result 1]
- [Specific result 2]
- [Specific result 3]

**Notion Updates**:
- **[Database Name 1]**: [Exact changes made with property values]
- **[Database Name 2]**: [Exact changes made with property values]
- **[Database Name 3]**: [Exact changes made with property values]

**Success Verification**:
\```bash
# Command to verify result
notion-fetch [page-id-from-creation-output]
\```
```

**Validation**:
- Examples must use realistic, domain-appropriate parameter values
- Expected outcomes must be verifiable with provided verification commands
- Notion updates must reference actual database names and properties
- Success verification must be actionable (not just "check in Notion UI")

---

### Error Handling Section (Required - Minimum 4 Scenarios)

**Purpose**: Document all failure modes with clear recovery paths to ensure reliable operations.

**Required Scenarios**:
1. **Duplicate Entry Detected**: Search finds existing matching entry
2. **Validation Failed**: Parameter constraints violated
3. **Notion API Error**: MCP server errors (rate limit, timeout, permissions, not found)
4. **Missing Required Parameter**: Command invoked without required inputs

**Optional but Recommended**:
5. **Partial Failure in Multi-Step Workflow**: Some steps succeed before error
6. **Downstream Automation Failed**: Webhook or Azure Function error
7. **Relation Linking Failed**: Database relation cannot be established

**Error Format**:
```markdown
### [Error Scenario Name]

**Trigger**: [Specific condition that causes this error]

**Behavior**:
- [What the system does when error occurs]
- [How error is communicated to user]
- [What operations are rolled back or preserved]
- [How error is logged for troubleshooting]

**Prevention**: [How to avoid this error - flags, pre-checks, best practices]

**Example Error Message**:
\```
[Actual error message user would see with specific details]
\```
```

---

### Success Criteria Section (Required)

**Purpose**: Provide clear verification checklist for confirming command executed correctly.

**Structure**: Bulleted checklist with ✅ indicators

**Requirements**:
- Minimum 4 criteria
- Must include entry creation/update verification
- Must include status field verification
- Must include relation verification (if applicable)
- Must include activity logging verification
- Should include downstream automation verification (if applicable)

**Example**:
```markdown
## Success Criteria

Verify the command executed successfully by confirming:

- ✅ **Entry Created**: Ideas Registry contains new entry with title matching first 100 chars of description
- ✅ **Status Set Correctly**: Entry status is "🔵 Concept"
- ✅ **Viability Initialized**: Viability field is "❓ Needs Assessment"
- ✅ **Category Assigned**: Category field matches provided parameter
- ✅ **Team Member Assigned**: Assigned To field populated via auto-assignment or --assign-to parameter
- ✅ **Activity Logged**: Agent Activity Hub contains log entry for this command execution
- ✅ **No Duplicates**: Search confirms no unintended duplicate entries created
- ✅ **Relations Established**: If software/tools mentioned in description, Software Tracker relations created
```

---

### Related Commands Section (Required)

**Purpose**: Guide users toward complementary commands and workflow patterns.

**Structure**:
- **Complementary Commands**: Alternative commands for different scenarios
- **Workflow Sequences**: Common multi-command patterns

**Format**:
```markdown
## Related Commands

### Complementary Commands

- **`/related:command1`**: [When to use instead - different scenario]
- **`/related:command2`**: [When to use after - workflow continuation]
- **`/related:command3`**: [When to use as alternative approach]

### Workflow Sequences

**Common Pattern 1: [Pattern Name]**
\```bash
/category:action "initial-work"      # Start workflow
/related:next-step "follow-up"       # Continue workflow
/related:finalize "completion"       # Complete workflow
\```

**Common Pattern 2: [Pattern Name]**
\```bash
/category:action "primary"           # Execute primary operation
/team:assign "assignment"            # Delegate to specialist
\```
```

---

### Best Practices Section (Recommended)

**Purpose**: Provide usage guidance, performance expectations, and security considerations.

**Subsections**:
1. **When to Use This Command**: Ideal scenarios and anti-patterns
2. **Performance Considerations**: Execution time, API call count, database locks
3. **Security & Compliance**: Credentials required, data sensitivity, audit trails

**Example**:
```markdown
## Best Practices

### When to Use This Command

**Ideal Scenarios**:
- Capturing ideas during brainstorming sessions for structured evaluation
- Recording feature requests from clients with automatic team routing
- Documenting process improvement opportunities for quarterly review

**Avoid Using When**:
- Idea is already in Research phase (use `/innovation:start-research` instead)
- Idea is actually a bug report (use issue tracking system)
- Immediate implementation required (use `/innovation:fast-track` for urgent items)

### Performance Considerations

- **Typical Execution Time**: 2-3 seconds for simple case, 5-7 seconds with duplicate detection
- **Notion API Calls**: 2-3 calls (search + create + activity log)
- **Database Locks**: None - safe for concurrent execution

### Security & Compliance

- **Credentials Required**: Notion API token (via MCP server configuration)
- **Data Sensitivity**: Ideas may contain business-sensitive information - stored in private workspace
- **Audit Trail**: Complete command execution logged to Agent Activity Hub with parameters and outcomes
```

---

### Troubleshooting Section (Recommended)

**Purpose**: Document common issues users encounter with resolution steps.

**Format**:
```markdown
## Troubleshooting

### Common Issues

**Issue**: [Specific problem description]

**Cause**: [Root cause explanation]

**Resolution**:
1. [Step-by-step resolution]
2. [Verification command or action]
3. [Prevention for future]

---

**Issue**: [Second common problem]

**Cause**: [Root cause explanation]

**Resolution**:
1. [Step-by-step resolution]
2. [Verification command or action]
```

---

## Validation Checklist

Before finalizing any command documentation file, verify:

### Structure Compliance
- [ ] File follows exact template structure with all required sections
- [ ] Header block includes category, databases, agents, and last updated date
- [ ] Purpose section leads with business value before technical details
- [ ] Parameters section includes required/optional distinction with types and validation rules
- [ ] Workflow section numbers all steps with Notion MCP operations specified
- [ ] Examples section includes minimum 3 executable examples with verification steps
- [ ] Error handling section covers minimum 4 scenarios with recovery paths
- [ ] Success criteria section provides verifiable checklist items
- [ ] Related commands section links to complementary commands and workflow patterns

### Content Quality
- [ ] All examples use realistic values (no "your-value-here" placeholders)
- [ ] All Notion operations specify exact MCP tool names
- [ ] All database references include IDs matching notion-schema.md
- [ ] All parameter types are explicitly defined (string, number, boolean, array)
- [ ] All validation rules are specific and testable
- [ ] All error messages provide actionable resolution steps

### Brand Voice
- [ ] Purpose statement uses Brookside BI core language patterns
- [ ] Content leads with outcomes before technical implementation
- [ ] "Best for:" context qualifier included and specific
- [ ] Professional but approachable tone maintained throughout
- [ ] Solution-focused language emphasizes measurable results
- [ ] Consultative approach positions command as partnership enabler

### Technical Accuracy
- [ ] All Notion MCP operations are valid and current
- [ ] All database IDs match canonical registry
- [ ] All property names match database schemas
- [ ] All workflow steps are idempotent and executable by AI agents
- [ ] All examples have been tested and produce expected outcomes
- [ ] All error scenarios have been validated with actual MCP server responses

---

## Common Anti-Patterns to Avoid

### ❌ Vague Parameter Descriptions

**Bad**:
```markdown
- `input` (string): The input value
```

**Good**:
```markdown
- **`idea-description`** (type: string): Detailed description of the innovation opportunity, including business problem addressed and expected impact. Minimum 20 characters, maximum 500 characters. Example: "Automate monthly cost reporting by integrating Azure Cost Management with Power BI dashboards"
```

---

### ❌ Ambiguous Workflow Steps

**Bad**:
```markdown
1. Check for duplicates
2. Create the entry
3. Link relations
```

**Good**:
```markdown
### Step 2: Duplicate Detection
- **Notion Operation**: `notion-search`
- **Target Database**: Ideas Registry (ID: 984a4038-3e45-4a98-8df4-fd64dd8a1032)
- **Query**: Search for ideas with description matching >80% similarity using fuzzy matching
- **Behavior if Found**: Display existing entry with options [Update | Create New | Cancel]
- **Behavior if Not Found**: Proceed to Step 3
```

---

### ❌ Generic Examples

**Bad**:
```markdown
### Example 1: Basic Usage
\```bash
/innovation:new-idea "my idea"
\```
Creates an idea.
```

**Good**:
```markdown
### Example 1: Process Automation Opportunity

\```bash
/innovation:new-idea "Automate monthly cost reporting by integrating Azure Cost Management API with Power BI dashboards to eliminate 8 hours of manual Excel consolidation" --category="Process Automation" --priority=high
\```

**Context**: CFO requests faster monthly cost visibility across 15 Azure subscriptions currently tracked manually

**Expected Outcome**:
- Creates entry in Ideas Registry with status "🔵 Concept"
- Auto-assigns to Markus Ahling (Process Automation category owner)
- Links to Software Tracker entries for Azure Cost Management and Power BI
- Triggers viability assessment workflow

**Notion Updates**:
- **Ideas Registry**: New page "💡 Automate monthly cost reporting..." with Category="Process Automation", Priority=High
- **Software Tracker**: Relations added for Azure Cost Management API and Power BI
- **Agent Activity Hub**: Log entry with command execution timestamp and parameters

**Success Verification**:
\```bash
# Verify entry created with correct properties
notion-fetch [page-id-from-output]
\```
```

---

### ❌ Missing Error Recovery

**Bad**:
```markdown
## Error Handling

If something goes wrong, check Notion and try again.
```

**Good**:
```markdown
## Error Handling

### Notion API Rate Limit (429)

**Trigger**: Too many API calls in short time period (>3 requests/second sustained)

**Behavior**:
- System waits 60 seconds before retry
- Retries up to 3 times with exponential backoff (60s, 120s, 240s)
- If all retries exhausted, displays error with retry-after timestamp
- Logs rate limit event to Agent Activity Hub for pattern analysis

**Prevention**: Use `--batch-mode` flag for bulk operations to implement automatic throttling

**Example Error Message**:
\```
Rate Limit Exceeded: Notion API requests throttled
Retry Attempt: 1 of 3
Next Retry In: 60 seconds
Recommendation: Reduce concurrent command executions or use --batch-mode for bulk operations
\```

**Manual Recovery**:
1. Wait for retry-after period (shown in error message)
2. Verify no partial data created: `notion-search` in target database
3. Re-execute command with same parameters (idempotent design ensures safe retry)
```

---

## Usage Instructions

### For Command Authors

When creating new command documentation:

1. **Copy Template**: Start with the complete Universal Command Template from this document
2. **Fill Required Sections**: Complete all required sections before optional sections
3. **Test Examples**: Execute all examples to verify they produce documented outcomes
4. **Validate Against Checklist**: Use the Validation Checklist section to ensure compliance
5. **Peer Review**: Have another team member review for clarity and completeness
6. **Update Command Registry**: Add new command to `.claude/commands/` directory

### For Command Users

When reading command documentation:

1. **Read Purpose First**: Understand business value and "Best for:" context
2. **Review Examples**: Find example matching your scenario before reviewing full parameters
3. **Check Related Commands**: Verify you're using the most appropriate command for your need
4. **Follow Workflow**: Use workflow section as reference during execution
5. **Reference Error Handling**: If errors occur, consult error handling section for recovery

### For Command Maintainers

When updating existing command documentation:

1. **Update Last Updated Date**: Change date in header to current date (YYYY-MM-DD)
2. **Version Control**: Document what changed in git commit message
3. **Backward Compatibility**: Note any breaking changes prominently at document top
4. **Test After Changes**: Re-test all examples to ensure they still work
5. **Update Related Commands**: If command behavior changes, update related command references

---

## Integration with Innovation Nexus Architecture

### Command Categories and Database Mapping

| Category | Primary Database | Secondary Databases | Typical Agent Compatibility |
|----------|------------------|---------------------|----------------------------|
| Innovation | Ideas Registry, Research Hub, Example Builds | Software Tracker, Knowledge Vault | @ideas-capture, @research-coordinator, @build-architect |
| Cost | Software Tracker | Ideas Registry, Research Hub, Example Builds | @cost-analyst, @procurement-specialist |
| Knowledge | Knowledge Vault | All databases (for archival) | @knowledge-curator, @archive-manager |
| Team | Agent Activity Hub | All databases (for assignment) | @team-coordinator, @resource-allocator |
| Repo | N/A (GitHub external) | Example Builds (for linking) | @repo-analyzer, @integration-specialist |
| Autonomous | Ideas Registry, Research Hub, Example Builds | Software Tracker, Knowledge Vault | @autonomous-orchestrator, @research-swarm |
| Docs | N/A (file system) | All databases (for documentation) | @documentation-specialist, @markdown-expert |
| Style | Agent Style Tests | Agent Registry, Output Styles Registry | @style-analyst, @effectiveness-evaluator |

### Naming Conventions

**Command Format**: `/category:action`

**Examples**:
- `/innovation:new-idea`
- `/cost:analyze`
- `/knowledge:archive`
- `/team:assign`
- `/repo:scan-org`
- `/autonomous:enable-idea`
- `/docs:update-complex`
- `/style:test-agent-style`

**Action Verbs** (use consistently):
- `new-*`: Create new entry (new-idea, new-research)
- `start-*`: Initiate workflow (start-research, start-build)
- `enable-*`: Turn on automation (enable-idea, enable-pipeline)
- `assign`: Route work to team member or agent
- `analyze`: Perform analysis and return results
- `update-*`: Modify existing entries (update-properties, update-complex)
- `archive`: Complete lifecycle and move to Knowledge Vault
- `scan-*`: Perform discovery operation (scan-org, scan-portfolio)
- `calculate-*`: Compute metrics (calculate-costs, calculate-viability)
- `extract-*`: Pull data from external source (extract-patterns, extract-insights)
- `test-*`: Run validation or experiment (test-agent-style, test-integration)
- `report`: Generate analytics output (style:report, cost:report)
- `compare`: Side-by-side analysis (style:compare, cost:compare)

---

## Maintenance and Versioning

### Update Frequency

- **Quarterly Review**: All command documentation reviewed for accuracy
- **On Schema Change**: Update immediately when Notion database schemas change
- **On MCP Update**: Update when Notion MCP server adds/changes functionality
- **On User Feedback**: Update when users report confusion or errors

### Version History

Track changes in git commits with clear messages:

```bash
# Good commit messages for command doc updates
docs(commands): Update /innovation:new-idea parameter validation rules to require category selection
docs(commands): Add error handling for rate limit scenario in /cost:analyze command
docs(commands): Expand examples section in /repo:scan-org with deep scan flag usage

# Bad commit messages
docs: update command
docs: fix typo
docs: changes
```

### Deprecation Process

When deprecating a command:

1. **Mark as Deprecated**: Add warning banner at document top
2. **Document Replacement**: Specify which command replaces deprecated one
3. **Grace Period**: Maintain documentation for 90 days minimum
4. **Remove**: After grace period, move to `.claude/docs/archive/deprecated-commands/`

**Deprecation Banner Template**:
```markdown
> ⚠️ **DEPRECATED**: This command is deprecated as of YYYY-MM-DD and will be removed on YYYY-MM-DD.
>
> **Use Instead**: `/new-category:new-action` - [Link to new command documentation]
>
> **Migration Guide**: [Link to migration guide if complex transition]
```

---

## Examples from Existing Commands

### Example 1: Simple Creation Command

See `/innovation:new-idea` for reference implementation of:
- Clear parameter validation rules
- Duplicate detection workflow
- Automatic relation linking to Software Tracker
- Activity logging pattern
- Team assignment routing

### Example 2: Complex Multi-Database Command

See `/knowledge:archive` for reference implementation of:
- Multi-step workflow across 5+ databases
- Conditional logic based on source database
- Relation preservation during archival
- Downstream automation triggers
- Comprehensive error recovery

### Example 3: Analysis Command

See `/cost:analyze` for reference implementation of:
- Read-only database operations
- Complex data aggregation across relations
- Formatted output presentation
- Export options for downstream processing
- Performance optimization for large datasets

### Example 4: Autonomous Pipeline Command

See `/autonomous:enable-idea` for reference implementation of:
- Long-running workflow documentation (40-60 min)
- Multi-agent orchestration
- Progress tracking and status updates
- Failure recovery with partial completion
- Integration with external systems (Azure, GitHub)

---

## Additional Resources

- **[Notion Schema](.claude/docs/notion-schema.md)**: Database structure, properties, relations, IDs
- **[Common Workflows](.claude/docs/common-workflows.md)**: Multi-command patterns and sequences
- **[Agent Guidelines](.claude/docs/agent-guidelines.md)**: Agent capabilities, specializations, handoff protocols
- **[Innovation Workflow](.claude/docs/innovation-workflow.md)**: End-to-end lifecycle from idea to knowledge
- **[MCP Configuration](.claude/docs/mcp-configuration.md)**: Notion MCP server setup and troubleshooting

---

**Last Updated**: 2025-10-26 | **Maintained By**: @markdown-expert, @documentation-specialist
**Version**: 1.0.0 | **Status**: Active

---

**Brookside BI Innovation Nexus - Establish consistent command documentation to streamline workflow automation and improve cross-team clarity.**
