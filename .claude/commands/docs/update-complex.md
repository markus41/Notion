---
description: Establish comprehensive documentation management through intelligent parallel agent orchestration, automated diagram generation, and systematic quality enforcement across file hierarchies
allowed-tools: Task(@documentation-orchestrator:*, @markdown-expert:*, @mermaid-diagram-expert:*), mcp__github__*, mcp__notion__*, Glob, Read, Write, Edit
argument-hint: <scope> <description> [--diagrams] [--full-refresh] [--commit] [--create-pr] [--sync-notion] [--parallel-agents=N]
model: claude-sonnet-4-5-20250929
---

# Update Complex Documentation

**Category**: Documentation
**Command**: `/docs:update-complex`
**Primary Agent**: `@documentation-orchestrator` (orchestrates 3-5 specialized agents in parallel waves)

## Overview

Streamline documentation workflows across multiple files through intelligent agent coordination, automated quality enforcement, and systematic brand consistency. This command establishes enterprise-grade documentation management by delegating file updates to specialized agents working in parallel waves, generating visual diagrams on demand, validating cross-references, and synchronizing to external systems.

**Best for**: Organizations scaling documentation practices across teams who require comprehensive quality assurance, automated diagram generation, and systematic consistency enforcement for technical documentation hierarchies (3+ files).

**Designed to**: Drive measurable improvements in documentation quality, reduce manual coordination overhead, and establish sustainable documentation practices through parallel execution and automated validation workflows.

---

## Business Value

### Key Outcomes
- **Productivity Gains**: 60-85% time savings through parallel agent execution vs sequential updates
- **Quality Consistency**: Automated enforcement of Brookside BI brand voice and AI-agent executable standards
- **Visual Clarity**: On-demand Mermaid diagram generation for architecture and workflow documentation
- **Cross-File Integrity**: Systematic validation of internal links and terminology consistency
- **Repository Integration**: One-command GitHub PR creation with comprehensive quality reports

### Measurable Impact
- **3-5 files**: Complete in 8-12 minutes (vs 25-35 minutes manually)
- **6-10 files**: Complete in 12-18 minutes (vs 45-60 minutes manually)
- **Quality Score Target**: 85-100/100 through automated validation
- **Brand Compliance**: 95%+ consistency across all documentation

---

## Command Syntax

```bash
/docs:update-complex <scope> <description> [options]
```

### Required Parameters

| Parameter | Type | Description | Examples |
|-----------|------|-------------|----------|
| `scope` | string/pattern | Files to update (single file, glob pattern, or comma-separated list) | `README.md`, `docs/**/*.md`, `file1.md,file2.md,docs/*.md` |
| `description` | string | Comprehensive description of changes across all targeted files | `"Apply Brookside BI brand voice transformations with outcome-focused introductions"` |

### Optional Flags

| Flag | Description | Default | Business Impact |
|------|-------------|---------|-----------------|
| `--diagrams` | Generate Mermaid diagrams for architecture/workflows | `false` | Improves visual comprehension and stakeholder communication |
| `--sync-repo` | Synchronize to GitHub repository after updates | `false` | Enables version control integration and team collaboration |
| `--sync-notion` | Synchronize to Notion Knowledge Vault after updates | `false` | Establishes searchable knowledge base for organizational reference |
| `--full-refresh` | Execute comprehensive quality checks (accessibility, SEO, external links) | `false` | Ensures enterprise-grade documentation standards (+4-6 min overhead) |
| `--parallel-agents` | Maximum agents to execute simultaneously (1-5) | `3` | Balance between speed (higher = faster) and resource utilization |
| `--commit` | Auto-commit with conventional commit message | `false` | Streamlines git workflow with standardized commit conventions |
| `--create-pr` | Create GitHub Pull Request after commit | `false` | Facilitates code review and quality gates before merging |

---

## Usage Examples

### Example 1: Update Multiple API Documentation Files

**Scenario**: Migrate API authentication documentation to new Azure Managed Identity approach across 5 endpoint files.

```bash
/docs:update-complex "docs/api/*.md" \
  "Establish Azure Managed Identity authentication patterns to replace legacy connection strings and improve security posture" \
  --diagrams
```

**Expected Execution Flow**:
1. **Analysis Phase** (30-45 seconds): Identify 5 files matching pattern (`docs/api/*.md`)
2. **Wave 1 - Content Updates** (4-6 minutes): 3 parallel `@markdown-expert` agents transform files with new authentication patterns
3. **Wave 2 - Diagram Generation** (2-3 minutes): `@mermaid-diagram-expert` creates authentication flow sequence diagram
4. **Wave 3 - Validation** (1-2 minutes): Cross-file consistency check, link validation, brand compliance verification
5. **Completion** (30 seconds): Aggregate results and generate quality report

**Output Summary**:
```
✅ Documentation Update Complete

Duration: 407s (6 minutes 47 seconds)
Files Updated: 5
Diagrams Generated: 1 (authentication-flow-sequence.mmd)
Quality Score: 92/100 (EXCELLENT)
Brand Compliance: 97%

✅ No validation issues found

Agents Coordinated: @markdown-expert (x3), @mermaid-diagram-expert, @documentation-orchestrator
```

**Business Outcome**: Security documentation improved with visual authentication flow, consistent terminology across endpoints, and 68% time savings vs manual updates.

---

### Example 2: Architecture Documentation Refresh with Full Quality Validation

**Scenario**: Document new event sourcing pattern implementation across architecture docs with comprehensive quality checks.

```bash
/docs:update-complex "README.md,docs/architecture/*.md,CLAUDE.md" \
  "Document event sourcing pattern for audit trail and cost tracking with Mermaid architecture diagrams and CQRS integration examples" \
  --diagrams \
  --full-refresh \
  --commit
```

**Expected Execution Flow**:
1. **Analysis Phase** (45-60 seconds): Resolve file scope (1 + 4 + 1 = 7 files)
2. **Wave 1 - Content Updates** (6-8 minutes): 3 parallel `@markdown-expert` agents update architecture documentation
3. **Wave 2 - Diagram Generation** (3-4 minutes): `@mermaid-diagram-expert` creates event sourcing architecture diagram + CQRS command flow
4. **Wave 3 - Comprehensive Validation** (4-6 minutes):
   - External link validation (HTTP status checks)
   - Accessibility compliance (WCAG 2.1 AA - alt text, heading hierarchy, semantic HTML)
   - SEO optimization (meta descriptions, keyword density)
   - Brand compliance (outcome-focused language, "Best for:" qualifiers)
   - Cross-reference integrity
5. **Wave 4 - Repository Sync** (1 minute): Auto-commit with conventional commit message
6. **Completion** (30 seconds): Generate quality report

**Output Summary**:
```
✅ Documentation Update Complete

Duration: 847s (14 minutes 7 seconds)
Files Updated: 7
Diagrams Generated: 3 (event-sourcing-architecture.mmd, cqrs-command-flow.mmd, cost-tracking-integration.mmd)
Quality Score: 88/100 (GOOD)
Brand Compliance: 94%

⚠️ Validation Issues Found: 2
- Broken Links: 1 (docs/architecture/legacy-patterns.md - outdated reference)
- Accessibility Violations: 1 (README.md - missing alt text for deployment diagram)

🔗 Auto-Committed
SHA: a3f7b2e
Message: "docs: Document event sourcing pattern for audit trail and cost tracking with Mermaid architecture diagrams and CQRS integration examples"

Agents Coordinated: @markdown-expert (x3), @mermaid-diagram-expert (x2), @documentation-orchestrator

💡 Recommendations:
1. Fix broken link in docs/architecture/legacy-patterns.md (line 47)
2. Add alt text to deployment diagram in README.md (line 112)
3. Consider creating dedicated CQRS implementation guide (currently embedded in architecture docs)
```

**Business Outcome**: Comprehensive architecture documentation with visual diagrams, systematic quality enforcement, and actionable remediation recommendations. 73% time savings vs manual approach while achieving higher quality standards.

---

### Example 3: Repository-Wide Brand Transformation with PR Creation

**Scenario**: Apply Brookside BI brand voice transformations to all markdown documentation and create PR for team review.

```bash
/docs:update-complex "**/*.md" \
  "Apply Brookside BI brand voice transformations: outcome-focused introductions, solution-focused language, Best for qualifiers, and professional consultative tone" \
  --full-refresh \
  --sync-repo \
  --create-pr
```

**Expected Execution Flow**:
1. **Analysis Phase** (60-90 seconds): Identify 23 files matching `**/*.md` pattern
2. **Wave 1 - Content Updates** (12-15 minutes): 3 parallel `@markdown-expert` agents transform brand voice in batches (7+7+9 files)
3. **Wave 2 - Comprehensive Validation** (4-6 minutes): Full quality assessment across all files
4. **Wave 3 - Repository Sync** (2-3 minutes):
   - Create feature branch `docs/update-complex-20251026-143022`
   - Stage all 23 changed files
   - Commit with conventional commit message
   - Generate PR description with quality metrics
   - Create GitHub Pull Request
   - Apply labels: `["documentation", "automated", "brand-transformation"]`
5. **Completion** (30 seconds): Return PR URL and quality report

**Output Summary**:
```
✅ Documentation Update Complete

Duration: 1247s (20 minutes 47 seconds)
Files Updated: 23
Diagrams Generated: 0
Quality Score: 91/100 (EXCELLENT)
Brand Compliance: 98%

✅ No validation issues found

🔗 Pull Request Created
https://github.com/brookside-bi/innovation-nexus/pull/47
Branch: docs/update-complex-20251026-143022
Labels: documentation, automated, brand-transformation

📊 PR Quality Report:
- Documentation Score: 91/100 (EXCELLENT)
- Brand Compliance: 98%
- Broken Links: 0
- Accessibility Violations: 0
- Outcome-Focused Introductions: 23/23 files (100%)
- "Best for:" Qualifiers: 19/23 files (83%)

Agents Coordinated: @markdown-expert (x3 batches), @documentation-orchestrator

💡 Recommendations:
1. Add "Best for:" qualifiers to 4 remaining files (see PR description for list)
2. Consider creating brand voice style guide for future consistency
3. Schedule quarterly brand compliance audits to maintain standards
```

**Business Outcome**: Comprehensive brand transformation with team review process, automated quality gates, and systematic enforcement. PR provides clear metrics for approval decision-making. 78% time savings vs manual file-by-file transformation.

---

## Workflow Execution Architecture

### Multi-Wave Parallel Coordination

Establish efficient documentation updates through intelligent wave sequencing where dependent operations wait for prerequisite completion while independent tasks execute in parallel.

```
Phase 1: Analysis & Planning (30-60 seconds)
├─ Resolve file patterns using Glob tool
├─ Validate file existence using Read tool
├─ Parse cross-file dependencies and internal links
├─ Create wave-sequenced execution plan
├─ Determine required specialized agents (@markdown-expert, @mermaid-diagram-expert)
└─ Estimate total duration based on file count and validation level

Phase 2: Wave 1 - Content Updates (Parallel - 4-15 minutes depending on file count)
├─ Agent 1: @markdown-expert transforms file A → brand voice + AI-agent executable standards
├─ Agent 2: @markdown-expert transforms file B → heading hierarchy + code block language tags
├─ Agent 3: @markdown-expert transforms file C → "Best for:" qualifiers + outcome-focused language
└─ ⏸️ WAIT: All Wave 1 agents must complete before proceeding to Wave 2

Phase 3: Wave 2 - Diagram Generation (Parallel - 2-4 minutes, conditional on --diagrams flag)
├─ Identify sections requiring visual aids (architecture, workflows, sequences)
├─ Agent 4: @mermaid-diagram-expert generates diagrams → flowcharts, architecture, sequence diagrams
├─ Insert diagram references in documentation with descriptive alt text
└─ ⏸️ WAIT: All Wave 2 agents must complete before proceeding to Wave 3

Phase 4: Wave 3 - Quality Validation (Sequential - 1-6 minutes depending on --full-refresh)
├─ Standard Validation (1-2 minutes):
│  ├─ Internal link validation (cross-references within repository)
│  ├─ Markdown syntax verification
│  ├─ Brand voice consistency check
│  └─ Code block language tag verification
│
└─ Comprehensive Validation (--full-refresh adds 4-6 minutes):
   ├─ External link validation (HTTP status checks for all outbound links)
   ├─ Accessibility compliance (WCAG 2.1 AA):
   │  ├─ Alt text presence for all images
   │  ├─ Proper heading hierarchy (no H1 → H3 skips)
   │  └─ Semantic HTML usage in markdown
   ├─ SEO optimization checks:
   │  ├─ Meta description presence
   │  └─ Keyword density analysis
   └─ Brand compliance validation:
      ├─ "Best for:" qualifiers present
      ├─ Outcome-focused introductions
      └─ Professional consultative tone maintained

Phase 5: Wave 4 - Repository Sync (Sequential - 1-3 minutes, conditional on --create-pr or --commit)
├─ Create GitHub PR (--create-pr):
│  ├─ Create feature branch: docs/update-complex-YYYYMMDD-HHMMSS
│  ├─ Stage all changed files
│  ├─ Commit with conventional commit message format
│  ├─ Generate PR description with quality metrics table
│  ├─ Create PR using mcp__github__create_pull_request
│  ├─ Apply labels: ["documentation", "automated"]
│  └─ Return PR URL to user
│
└─ Auto-commit only (--commit without --create-pr):
   ├─ Stage all changed files
   ├─ Commit with conventional commit message
   └─ Return commit SHA

Phase 6: Completion & Reporting (30 seconds)
├─ Aggregate quality scores across all files
├─ Identify validation issues (broken links, accessibility violations)
├─ Generate comprehensive execution report with metrics
├─ Provide actionable recommendations for remediation
└─ Return structured results to user
```

**Key Architecture Principles**:
- ✅ **Wave Sequencing**: Dependent operations wait for prerequisites; independent tasks execute in parallel
- ✅ **Resource Optimization**: Configurable `--parallel-agents` flag balances speed vs resource utilization
- ✅ **Fail-Fast**: Validation failures halt execution before repository sync
- ✅ **Idempotent Operations**: Re-running command with same inputs produces consistent results
- ✅ **Transparent Reporting**: Every phase provides clear progress indicators and duration metrics

---

## Performance Expectations

### Target Service Level Agreements (SLAs)

Establish predictable documentation update durations based on file count and validation level:

| File Count | Standard Validation | Comprehensive Validation (--full-refresh) | Time Savings vs Manual |
|------------|-------------------|----------------------------------------|---------------------|
| 3-5 files | 8-12 minutes | 12-16 minutes | 60-70% |
| 6-10 files | 12-18 minutes | 16-24 minutes | 70-75% |
| 11-20 files | 18-25 minutes | 25-35 minutes | 75-80% |
| 20+ files | 25-35 minutes | 35-50 minutes | 80-85% |

**Performance Factors**:
- **Parallel Agent Count**: Higher `--parallel-agents` value reduces Wave 1 duration but increases resource utilization
- **Diagram Generation**: `--diagrams` flag adds 2-4 minutes depending on diagram complexity
- **External Link Count**: `--full-refresh` validation time increases with number of external links (HTTP checks)
- **File Size**: Larger files (>1000 lines) increase per-file processing time

### Parallel Efficiency Gains

**Agent Coordination Impact**:
- **1 agent (sequential)**: Baseline duration
- **3 agents (default)**: 60-70% time savings through parallel execution
- **5 agents (maximum)**: 75-85% time savings with optimal resource utilization

**Calculation Example** (10 files, standard validation):
```
Sequential: 10 files × 2 min/file = 20 minutes
3 Agents: (10 files ÷ 3 agents) × 2 min/file = 7 minutes (65% savings)
5 Agents: (10 files ÷ 5 agents) × 2 min/file = 4 minutes (80% savings)
```

---

## Related Commands

Establish comprehensive documentation workflows through complementary command integration:

| Command | Purpose | When to Use Instead | Key Differences |
|---------|---------|---------------------|-----------------|
| `/docs:update-simple` | Single file updates with quick formatting | Minor changes, typo fixes, single file | No parallel agents, no diagram generation, faster execution (1-3 min) |
| `/docs:sync-notion` | Synchronize documentation to Knowledge Vault | Archive completed work, team knowledge sharing | Only Notion sync, no file transformations |
| `/docs:generate-diagrams` | Batch diagram generation without content updates | Visual aids needed but content is current | Only diagram generation, no markdown updates |
| `/docs:validate-links` | Link validation across documentation | Periodic link health checks, no content changes | Validation only, no transformations |

**Decision Matrix**:
- **1 file + quick fix** → `/docs:update-simple`
- **3+ files + brand transformation** → `/docs:update-complex`
- **Need diagrams for existing content** → `/docs:generate-diagrams`
- **Archive to Notion only** → `/docs:sync-notion`
- **Check link integrity** → `/docs:validate-links`

---

## Orchestration Implementation

### Step 1: Parse Arguments and Validate Input

Extract command arguments and validate required parameters before delegating to orchestrator agent:

```javascript
// Extract required arguments
const scope = ARGUMENTS[0];           // File scope (pattern, comma-list, or single file)
const description = ARGUMENTS[1];     // Comprehensive description of changes

// Validate required arguments are provided
if (!scope || scope.trim() === '') {
  throw new Error('❌ Missing required argument: <scope>. Provide file path, glob pattern, or comma-separated list.');
}

if (!description || description.trim() === '') {
  throw new Error('❌ Missing required argument: <description>. Provide comprehensive description of documentation changes.');
}

// Parse optional flags with explicit defaults
const flags = {
  diagrams: hasFlag('--diagrams'),                            // false if not present
  syncRepo: hasFlag('--sync-repo'),                           // false if not present
  syncNotion: hasFlag('--sync-notion'),                       // false if not present
  fullRefresh: hasFlag('--full-refresh'),                     // false if not present
  parallelAgents: getFlagValue('--parallel-agents') || 3,     // default: 3 agents
  commit: hasFlag('--commit'),                                // false if not present
  createPR: hasFlag('--create-pr')                            // false if not present
};

// Validate parallel agent count is within acceptable range (1-5)
if (flags.parallelAgents < 1 || flags.parallelAgents > 5) {
  throw new Error(`❌ Invalid --parallel-agents value: ${flags.parallelAgents}. Must be between 1 and 5.`);
}

// Log configuration for transparency
console.log(`
📋 Configuration
─────────────────────────────────────
Scope: ${scope}
Description: ${description}
Diagrams: ${flags.diagrams ? 'YES' : 'NO'}
Full Refresh: ${flags.fullRefresh ? 'YES (adds 4-6 min)' : 'NO'}
Parallel Agents: ${flags.parallelAgents}
Sync to GitHub: ${flags.commit || flags.createPR ? 'YES' : 'NO'}
Create PR: ${flags.createPR ? 'YES' : 'NO'}
Sync to Notion: ${flags.syncNotion ? 'YES' : 'NO'}
─────────────────────────────────────
`);
```

---

### Step 2: Resolve File Patterns Using Glob Tool

Establish explicit file list by resolving glob patterns, comma-separated lists, and single file paths:

```javascript
// Initialize target files array
let targetFiles = [];

try {
  if (scope.includes(',')) {
    // Handle comma-separated list: "README.md,CLAUDE.md,docs/api/*.md"
    console.log('🔍 Resolving comma-separated file patterns...');
    const patterns = scope.split(',').map(s => s.trim()).filter(s => s !== '');

    for (const pattern of patterns) {
      if (pattern.includes('*')) {
        // Glob pattern - use Glob tool to resolve
        const resolvedFiles = await glob(pattern);
        if (resolvedFiles.length === 0) {
          console.warn(`⚠️ Warning: Pattern "${pattern}" matched 0 files`);
        } else {
          console.log(`  ✓ Pattern "${pattern}" matched ${resolvedFiles.length} file(s)`);
          targetFiles.push(...resolvedFiles);
        }
      } else {
        // Single file path - add directly
        targetFiles.push(pattern);
      }
    }
  } else if (scope.includes('*')) {
    // Single glob pattern: "docs/**/*.md"
    console.log(`🔍 Resolving glob pattern: ${scope}`);
    targetFiles = await glob(scope);

    if (targetFiles.length === 0) {
      throw new Error(`❌ Pattern "${scope}" matched 0 files. Verify pattern syntax and file existence.`);
    }

    console.log(`  ✓ Pattern matched ${targetFiles.length} file(s)`);
  } else {
    // Single file: "README.md"
    console.log(`🔍 Single file specified: ${scope}`);
    targetFiles = [scope];
  }

  // Deduplicate files (in case comma-separated patterns overlap)
  targetFiles = [...new Set(targetFiles)];

  // Validate all resolved files exist using Read tool
  console.log(`\n📂 Validating ${targetFiles.length} file(s) exist...`);
  for (const file of targetFiles) {
    try {
      await Read({ file_path: file, limit: 1 });  // Read first line only to validate existence
      console.log(`  ✓ ${file}`);
    } catch (error) {
      throw new Error(`❌ File does not exist: ${file}. Verify file path is correct.`);
    }
  }

  console.log(`\n✅ Validated ${targetFiles.length} file(s) for update\n`);

} catch (error) {
  console.error(`❌ File resolution failed: ${error.message}`);
  throw error;
}
```

**Key Validation Points**:
- ✅ All glob patterns are resolved to explicit file paths (idempotent execution)
- ✅ File existence is verified before delegation to orchestrator (fail-fast)
- ✅ Empty pattern matches throw explicit errors (prevent silent failures)
- ✅ Duplicate files are removed (comma-separated patterns can overlap)

---

### Step 3: Delegate to @documentation-orchestrator Agent

Invoke the specialized orchestrator agent with comprehensive structured prompt containing all configuration and file context:

```javascript
console.log(`🤖 Delegating to @documentation-orchestrator with ${flags.parallelAgents} parallel agents\n`);

const orchestrationResult = await Task({
  subagent_type: 'documentation-orchestrator',
  description: `Complex documentation update with parallel agent execution across ${targetFiles.length} files`,
  prompt: `
Execute comprehensive documentation update with the following specifications:

## Target Files (${targetFiles.length} total)
${targetFiles.map((f, i) => `${i + 1}. ${f}`).join('\n')}

## Update Description
${description}

## Configuration Flags
- Generate Mermaid Diagrams: ${flags.diagrams ? 'YES' : 'NO'}
- Full Quality Refresh: ${flags.fullRefresh ? 'YES' : 'NO'}
- Parallel Agent Limit: ${flags.parallelAgents} agents
- Sync to Notion: ${flags.syncNotion ? 'YES' : 'NO'}
- Create GitHub PR: ${flags.createPR ? 'YES' : 'NO'}
- Auto-commit: ${flags.commit ? 'YES' : 'NO'}

## Execution Requirements

### Phase 1: Analysis & Planning (30-60 seconds)
Establish execution strategy through systematic analysis:

1. **Parse File Dependencies**: Identify cross-references, shared terminology, internal links between target files
2. **Create Wave-Sequenced Plan**: Group independent files for parallel execution; sequence dependent operations
3. **Determine Required Agents**: Identify specialized agents needed (@markdown-expert, @mermaid-diagram-expert)
4. **Estimate Total Duration**: Calculate based on file count, validation level, and parallel agent count

**Output Required**: Execution plan with wave breakdown and estimated duration

---

### Phase 2: Wave 1 - Content Updates (Parallel)

Streamline documentation transformations through parallel agent execution:

**Delegation Strategy**:
- Delegate each file to **@markdown-expert** for formatting and brand transformation
- Maximum **${flags.parallelAgents} agents** executing simultaneously
- Batch files if count exceeds parallel agent limit (e.g., 10 files with 3 agents = 3 batches of 3+3+4 files)

**Transformation Requirements for Each File**:
1. **Apply Brookside BI Brand Voice**:
   - Lead with business outcomes before technical details
   - Include "Best for:" qualifiers describing ideal use cases
   - Use solution-focused language: "Establish", "Streamline", "Drive measurable outcomes"
   - Maintain professional consultative tone (avoid casual language, overly technical jargon)

2. **Ensure AI-Agent Executable Documentation**:
   - Explicit, idempotent instructions (no ambiguity, same input = same output)
   - Clear verification steps after operations
   - No timeline language ("by Friday", "next week") - use Status-based tracking
   - Version specifications for all dependencies and tools

3. **Fix Markdown Issues**:
   - Proper heading hierarchy (H1 → H2 → H3, no skips)
   - Code blocks have language specifiers (\`\`\`typescript, \`\`\`bash, etc.)
   - Links use descriptive text (not "click here")
   - Images include alt text for accessibility
   - Tables properly formatted with alignment indicators

4. **Structure for Clarity**:
   - Clear sections with descriptive headers
   - Logical information flow (overview → details → examples → related)
   - Examples include expected outputs and verification steps
   - Related commands/resources grouped with decision-making context

**Critical Requirement**: ⏸️ **ALL Wave 1 agents MUST complete before proceeding to Phase 3**

---

### Phase 3: Wave 2 - Diagram Generation (${flags.diagrams ? 'ENABLED' : 'SKIPPED'})

${flags.diagrams ? `
**DIAGRAM GENERATION ENABLED**

Generate visual aids to improve documentation comprehension and stakeholder communication:

1. **Identify Diagram Opportunities**:
   - Architecture documentation → System architecture diagrams, component relationships
   - Workflow documentation → Process flowcharts, decision trees
   - Integration documentation → Sequence diagrams, data flow diagrams
   - State management → State machine diagrams

2. **Delegate to @mermaid-diagram-expert**:
   - Provide context from updated documentation content
   - Specify diagram type (flowchart, sequence, architecture, state machine)
   - Request descriptive alt text for accessibility

3. **Insert Diagram References**:
   - Add diagram markdown with proper syntax
   - Include descriptive alt text
   - Position diagrams adjacent to related content
   - Provide diagram file path reference

**Example Diagram Insertion**:
\`\`\`markdown
### Authentication Flow

The following sequence diagram illustrates the Azure Managed Identity authentication flow between client, API, and Azure Key Vault:

\`\`\`mermaid
sequenceDiagram
    participant Client
    participant API
    participant ManagedIdentity
    participant KeyVault

    Client->>API: Request with bearer token
    API->>ManagedIdentity: Request access token
    ManagedIdentity->>KeyVault: Authenticate with managed identity
    KeyVault-->>ManagedIdentity: Return access token
    ManagedIdentity-->>API: Provide access token
    API->>KeyVault: Request secret with token
    KeyVault-->>API: Return secret
    API-->>Client: Response with processed data
\`\`\`

**Diagram**: Azure Managed Identity authentication sequence showing token acquisition and secret retrieval flow
\`\`\`

**Critical Requirement**: ⏸️ **ALL Wave 2 agents MUST complete before proceeding to Phase 4**
` : `
**DIAGRAM GENERATION SKIPPED** - No diagrams requested (--diagrams flag not provided)
`}

---

### Phase 4: Wave 3 - Quality Validation (${flags.fullRefresh ? 'COMPREHENSIVE' : 'STANDARD'})

${flags.fullRefresh ? `
**COMPREHENSIVE VALIDATION ENABLED** (adds 4-6 minute overhead)

Establish enterprise-grade documentation standards through systematic validation:

1. **External Link Validation** (HTTP Status Checks):
   - Extract all external links from documentation
   - Execute HTTP HEAD requests to verify link availability
   - Report broken links (4xx, 5xx status codes)
   - Flag redirects (3xx status codes) for review
   - **Business Impact**: Prevent user frustration from broken documentation links

2. **Accessibility Compliance** (WCAG 2.1 AA):
   - **Alt Text for Images**: Verify all \`![alt](url)\` tags have non-empty descriptive alt text
   - **Heading Hierarchy**: Ensure no skipped levels (H1 → H2 → H3, not H1 → H3)
   - **Semantic HTML**: Verify proper use of lists, tables, and structural elements
   - **Business Impact**: Ensure documentation is accessible to all team members including those using screen readers

3. **SEO Optimization Checks**:
   - **Meta Description Presence**: Verify frontmatter includes description field
   - **Keyword Density Analysis**: Ensure primary keywords appear in headers and opening paragraphs
   - **Business Impact**: Improve documentation discoverability in search engines and internal search tools

4. **Brand Compliance Validation**:
   - **"Best for:" Qualifiers**: Verify presence of use case descriptions
   - **Outcome-Focused Introductions**: Ensure opening paragraphs lead with business value
   - **Professional Consultative Tone**: Check for casual language, jargon overuse, or overly technical framing
   - **Solution-Focused Language**: Verify use of "Establish", "Streamline", "Drive measurable outcomes"
   - **Business Impact**: Maintain consistent Brookside BI brand identity across all documentation

5. **Cross-Reference Integrity**:
   - **Internal Link Validation**: Verify all internal links point to existing files and sections
   - **Consistent Terminology**: Check for terminology consistency across files (e.g., "Notion database" vs "Notion table")
   - **Business Impact**: Ensure seamless navigation and prevent confusion from inconsistent terminology

6. **Code Quality Checks**:
   - **Language Tags**: Verify all code blocks have language specifiers
   - **Syntax Validity**: Basic syntax checking for code examples
   - **Business Impact**: Enable proper syntax highlighting and copy-paste reliability
` : `
**STANDARD VALIDATION ENABLED** (1-2 minute overhead)

Execute core quality checks to ensure documentation reliability:

1. **Internal Link Validation**:
   - Extract all internal links (\`[text](path)\` format)
   - Verify target files and sections exist
   - Report broken internal references

2. **Markdown Syntax Verification**:
   - Check for unclosed brackets, mismatched formatting
   - Validate table structure and alignment
   - Verify list indentation consistency

3. **Brand Voice Consistency**:
   - Check for "Best for:" qualifiers in key sections
   - Verify outcome-focused language in introductions
   - Flag casual tone or jargon overuse

4. **Code Block Language Tags**:
   - Ensure all code blocks have language specifiers
   - Flag generic \`\`\` blocks without language identifiers
`}

**Validation Output Required**:
- Total issues found (count)
- Broken links (list with file and line number)
- Accessibility violations (list with file and issue type)
- Brand compliance score (0-100%)
- Actionable recommendations for remediation

---

### Phase 5: Wave 4 - Repository Sync (${flags.createPR || flags.commit ? 'ENABLED' : 'SKIPPED'})

${flags.createPR ? `
**GITHUB PULL REQUEST CREATION ENABLED**

Streamline documentation review workflow through automated PR generation:

1. **Create Feature Branch**:
   - Branch name format: \`docs/update-complex-YYYYMMDD-HHMMSS\`
   - Example: \`docs/update-complex-20251026-143022\`
   - Branch from: \`main\` (or current default branch)

2. **Stage and Commit All Changes**:
   - Stage all ${targetFiles.length} modified files
   - Use conventional commit message format:

   \`\`\`
   docs: ${description}

   - Updated ${targetFiles.length} documentation files
   - Generated ${flags.diagrams ? 'Mermaid architecture diagrams' : 'no diagrams'}
   - Validation: ${flags.fullRefresh ? 'COMPREHENSIVE (external links, accessibility, SEO)' : 'STANDARD (syntax, internal links, brand)'}

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>
   \`\`\`

3. **Generate PR Description with Quality Metrics**:

   \`\`\`markdown
   ## Documentation Update Summary

   ${description}

   ### Files Changed (${targetFiles.length})
   ${targetFiles.map(f => \`- \\\`${f}\\\`\`).join('\\n')}

   ### Quality Metrics
   - **Documentation Score**: XX/100 (EXCELLENT/GOOD/ADEQUATE)
   - **Brand Compliance**: XX%
   - **Broken Links**: X
   - **Missing Diagrams**: X
   - **Accessibility Issues**: X

   ### Validation Level
   ${flags.fullRefresh ? '✅ **Comprehensive Validation**\\n   - External link verification (HTTP status checks)\\n   - Accessibility compliance (WCAG 2.1 AA)\\n   - SEO optimization checks\\n   - Brand compliance validation' : '✅ **Standard Validation**\\n   - Markdown syntax verification\\n   - Internal link validation\\n   - Brand voice consistency'}

   ### Generated Diagrams
   ${flags.diagrams ? '✅ Mermaid diagrams generated for architecture and workflow sections' : '⏭️ No diagrams generated (--diagrams flag not provided)'}

   ### Notion Sync
   ${flags.syncNotion ? '✅ Synced to Knowledge Vault: [URL]' : '⏭️ Not synced to Notion (--sync-notion flag not provided)'}

   ### Recommendations
   <!-- List actionable recommendations from validation -->

   ---

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>
   \`\`\`

4. **Create GitHub Pull Request**:
   - Use **mcp__github__create_pull_request** tool
   - Base branch: \`main\`
   - Head branch: \`docs/update-complex-YYYYMMDD-HHMMSS\`
   - Title: First line of commit message
   - Body: Generated PR description above
   - Labels: \`["documentation", "automated"]\`

5. **Return PR URL to User**:
   - Provide clickable PR URL
   - Display branch name for reference
   - Show quality metrics summary

**Business Impact**: Enable systematic code review process with comprehensive quality context for approval decision-making.
` : flags.commit ? `
**AUTO-COMMIT ENABLED** (without PR creation)

Streamline git workflow with automated commit:

1. **Stage All Changes**:
   - Stage all ${targetFiles.length} modified files

2. **Commit with Conventional Message**:
   \`\`\`
   docs: ${description}

   - Updated ${targetFiles.length} documentation files
   - Generated ${flags.diagrams ? 'Mermaid diagrams' : 'no diagrams'}
   - Validation: ${flags.fullRefresh ? 'COMPREHENSIVE' : 'STANDARD'}

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>
   \`\`\`

3. **Return Commit SHA**:
   - Provide commit SHA for reference
   - Display commit message

**Business Impact**: Maintain git history with standardized conventional commits.
` : `
**REPOSITORY SYNC SKIPPED** - No commit or PR flags provided
`}

---

### Phase 6: Completion & Reporting

Generate comprehensive execution report with actionable insights:

**Required Output Structure** (JSON format):
\`\`\`json
{
  "status": "completed",
  "duration_seconds": XXX,
  "files_updated": ${targetFiles.length},
  "diagrams_generated": X,
  "quality_score": XX,
  "brand_compliance_percent": XX,
  "validation": {
    "level": "${flags.fullRefresh ? 'comprehensive' : 'standard'}",
    "issues_found": X,
    "broken_links": X,
    "accessibility_violations": X,
    "details": [
      "Issue description 1 (file.md:line)",
      "Issue description 2 (file.md:line)"
    ]
  },
  "github": {
    "pr_created": ${flags.createPR},
    "pr_url": "https://github.com/org/repo/pull/XXX",
    "branch": "docs/update-complex-YYYYMMDD-HHMMSS",
    "commit_sha": "abc123def"
  },
  "notion": {
    "synced": ${flags.syncNotion},
    "entry_url": "https://notion.so/..."
  },
  "agents_coordinated": [
    "@markdown-expert",
    "@mermaid-diagram-expert",
    "@documentation-orchestrator"
  ],
  "recommendations": [
    "Recommendation 1 with actionable steps",
    "Recommendation 2 with priority indication"
  ]
}
\`\`\`

**Display Requirements**:
- Clear status indicator (✅ success, ⚠️ warnings, ❌ failure)
- Duration in seconds and formatted as minutes
- Quality score with rating (90-100: EXCELLENT, 75-89: GOOD, 60-74: ADEQUATE, <60: NEEDS IMPROVEMENT)
- All validation issues listed with file references
- GitHub PR URL if created (clickable)
- Notion entry URL if synced (clickable)
- Actionable recommendations prioritized (high/medium/low)

---

## Critical Requirements

### Mandatory Execution Standards

✅ **MUST** wait for each wave to complete before starting next wave (prevents race conditions and dependency violations)

✅ **MUST** apply Brookside BI brand voice to all documentation:
   - Outcome-focused introductions (business value before technical details)
   - "Best for:" qualifiers describing ideal use cases
   - Solution-focused language ("Establish", "Streamline", "Drive measurable outcomes")
   - Professional consultative tone (avoid casual language, jargon overuse)

✅ **MUST** structure documentation for AI-agent consumption:
   - Explicit, idempotent instructions (same input = same output)
   - Clear verification steps after operations
   - No ambiguity in commands or procedures
   - Version specifications for all dependencies

✅ **MUST** validate all changes before committing:
   - Markdown syntax correctness
   - Internal link integrity
   - Brand compliance standards
   - Code block language tags

✅ **MUST** report clear outcomes to user:
   - Total duration and file count
   - Quality score with rating
   - Validation issues with file references
   - Actionable recommendations

✅ **MUST** log activity to Agent Activity Hub:
   - Session start timestamp
   - Files processed and agents coordinated
   - Completion status and duration
   - Deliverables (PR URL, commit SHA, Notion URL)

---

## Success Criteria

**You are driving measurable outcomes when**:
- ✅ Documentation quality score achieves 85-100/100 (EXCELLENT/GOOD rating)
- ✅ Brand compliance reaches 95%+ across all files
- ✅ All validation issues are identified with actionable remediation steps
- ✅ Parallel execution achieves 60-85% time savings vs sequential processing
- ✅ Generated PRs contain comprehensive quality context for approval decisions
- ✅ Zero broken internal links after validation
- ✅ All code blocks have proper language specifiers
- ✅ Accessibility standards (WCAG 2.1 AA) are met if --full-refresh enabled

---

**Execute this orchestration with precision, efficiency, and systematic quality enforcement. Streamline documentation workflows through intelligent agent coordination while maintaining Brookside BI brand excellence.**
  `
});
```

---

### Step 4: Display Results to User

Format and present orchestration results with clear, actionable summary and visual indicators:

```javascript
// Helper function to determine quality rating
function getQualityRating(score) {
  if (score >= 90) return 'EXCELLENT';
  if (score >= 75) return 'GOOD';
  if (score >= 60) return 'ADEQUATE';
  return 'NEEDS IMPROVEMENT';
}

// Display comprehensive results
console.log(`
════════════════════════════════════════════════════════════════
✅ Documentation Update Complete
════════════════════════════════════════════════════════════════

📊 Execution Summary
──────────────────────────────────────────────────────────────
Duration: ${orchestrationResult.duration_seconds}s (${Math.floor(orchestrationResult.duration_seconds / 60)} minutes ${orchestrationResult.duration_seconds % 60} seconds)
Files Updated: ${orchestrationResult.files_updated}
Diagrams Generated: ${orchestrationResult.diagrams_generated}
Quality Score: ${orchestrationResult.quality_score}/100 (${getQualityRating(orchestrationResult.quality_score)})
Brand Compliance: ${orchestrationResult.brand_compliance_percent}%

${orchestrationResult.validation.issues_found > 0 ? `
⚠️ Validation Issues Found: ${orchestrationResult.validation.issues_found}
──────────────────────────────────────────────────────────────
${orchestrationResult.validation.details.map((issue, i) => `${i + 1}. ${issue}`).join('\n')}

Broken Links: ${orchestrationResult.validation.broken_links}
Accessibility Violations: ${orchestrationResult.validation.accessibility_violations}
` : `
✅ No Validation Issues Found
──────────────────────────────────────────────────────────────
All documentation meets quality standards
`}

${orchestrationResult.github.pr_created ? `
🔗 GitHub Pull Request Created
──────────────────────────────────────────────────────────────
PR URL: ${orchestrationResult.github.pr_url}
Branch: ${orchestrationResult.github.branch}
Commit SHA: ${orchestrationResult.github.commit_sha}

Review the PR to see comprehensive quality metrics and approve for merge.
` : orchestrationResult.github.commit_sha ? `
🔗 Auto-Committed to Repository
──────────────────────────────────────────────────────────────
Commit SHA: ${orchestrationResult.github.commit_sha}
` : ''}

${orchestrationResult.notion.synced ? `
📚 Synced to Notion Knowledge Vault
──────────────────────────────────────────────────────────────
Entry URL: ${orchestrationResult.notion.entry_url}
` : ''}

🤖 Agents Coordinated
──────────────────────────────────────────────────────────────
${orchestrationResult.agents_coordinated.join(', ')}

${orchestrationResult.recommendations && orchestrationResult.recommendations.length > 0 ? `
💡 Recommendations for Further Optimization
──────────────────────────────────────────────────────────────
${orchestrationResult.recommendations.map((rec, i) => `${i + 1}. ${rec}`).join('\n')}
` : ''}

════════════════════════════════════════════════════════════════
Streamlined documentation workflow through intelligent parallel
agent orchestration with systematic quality enforcement.
════════════════════════════════════════════════════════════════
`);

// Return structured result for programmatic access
return orchestrationResult;
```

**Key Display Principles**:
- ✅ Visual hierarchy with section separators for clarity
- ✅ Color-coded status indicators (✅ success, ⚠️ warnings, ❌ errors)
- ✅ Actionable information (clickable URLs, file references with line numbers)
- ✅ Business context (quality ratings, brand compliance percentages)
- ✅ Transparent agent coordination (list all specialized agents involved)

---

## Execution Notes

### Architectural Principles

**Delegation Model**:
- This command **delegates all orchestration logic** to `@documentation-orchestrator` agent
- Command itself focuses on **argument parsing**, **file pattern resolution**, and **input validation**
- `@documentation-orchestrator` handles **parallel agent coordination**, **quality validation**, and **repository integration**
- Specialized agents (`@markdown-expert`, `@mermaid-diagram-expert`) execute specific transformations

**Separation of Concerns**:
- **Command Layer** (this file): Input validation, pattern resolution, result display
- **Orchestrator Layer** (@documentation-orchestrator): Wave sequencing, agent coordination, validation orchestration
- **Specialist Layer** (@markdown-expert, @mermaid-diagram-expert): File-specific transformations

**Quality Enforcement**:
- All brand compliance standards are **agent responsibilities** (not manual checklist)
- Validation happens systematically through automated checks
- Quality scoring is objective and reproducible (0-100 scale)

**Performance Optimization**:
- Parallel execution reduces total duration by 60-85% vs sequential processing
- Wave sequencing ensures dependent operations complete before proceeding
- Configurable `--parallel-agents` flag allows resource utilization tuning

### Expected Duration by Configuration

**Typical Execution Times**:
- **3-5 files, standard validation**: 8-12 minutes
- **6-10 files, comprehensive validation**: 16-24 minutes
- **20+ files, comprehensive validation + PR**: 35-50 minutes

**Duration Factors**:
- File count and size
- Validation level (standard vs comprehensive)
- Diagram generation requirement
- External link count (for comprehensive validation)
- Parallel agent count configuration

---

**Update Complex Documentation Command** - Establish comprehensive documentation management through intelligent multi-agent orchestration, automated quality enforcement, and systematic brand consistency. Designed for organizations scaling documentation practices who require enterprise-grade consistency and measurable quality improvements.

**Best for**: Multi-file documentation transformations requiring parallel execution efficiency, automated diagram generation, comprehensive validation, and GitHub integration with team review workflows.
