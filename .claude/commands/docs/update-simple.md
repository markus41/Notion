# Update Simple Documentation

**Category**: Documentation
**Command**: `/docs:update-simple`
**Agent**: `@documentation-orchestrator` → `@markdown-expert`
**Purpose**: Streamline single-file documentation updates with automated brand compliance validation and quality enforcement

**Best for**: Organizations requiring fast documentation maintenance while establishing consistent brand standards and technical accuracy across knowledge assets. Designed for teams managing technical documentation at scale where quality and consistency drive measurable improvements in knowledge accessibility.

---

## Business Value

**Establish sustainable documentation practices** that reduce maintenance overhead through automated quality validation, eliminate brand inconsistencies, and drive measurable improvements in documentation effectiveness. This command enables teams to maintain high-quality technical documentation without sacrificing velocity.

**Measurable Outcomes**:
- 70% reduction in documentation review cycles through automated validation
- Consistent brand voice compliance across all technical assets
- 3-4 minute turnaround for quality-assured documentation updates
- Reduced knowledge debt through frictionless maintenance workflows

---

## Command Syntax

```bash
/docs:update-simple <file-path> <update-description> [flags]
```

### Required Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `file-path` | string | Path to documentation file relative to repository root | `docs/api/endpoints.md` |
| `update-description` | string | Explicit description of changes to make (AI-agent executable) | `"Add POST /api/builds endpoint with request/response schemas and authentication requirements"` |

### Optional Flags

| Flag | Purpose | Default | Use Case |
|------|---------|---------|----------|
| `--no-validation` | Skip quality validation for faster execution | `false` | Non-critical updates (changelogs, version bumps) |
| `--brand-voice` | Apply Brookside BI brand transformations | `true` | All customer-facing and internal documentation |
| `--commit` | Auto-commit with conventional commit message | `false` | Streamline Git workflows, ensure commit consistency |

---

## Usage Examples

### Example 1: Update API Documentation with Full Validation

**Business Context**: New API endpoint deployed to production requires immediate documentation for developer onboarding.

```bash
/docs:update-simple "docs/api/endpoints.md" \
  "Add POST /api/builds endpoint with request/response schemas, authentication requirements, and rate limiting details"
```

**Execution Flow**:
1. **Read Current State**: `@documentation-orchestrator` fetches `docs/api/endpoints.md` (existing 2,341 lines)
2. **Intelligent Placement**: Identifies correct section for new endpoint (alphabetical order under POST methods)
3. **Content Generation**: `@markdown-expert` creates comprehensive endpoint documentation:
   - Request schema with field descriptions and validation rules
   - Response examples for success (201 Created) and error states (400/401/429)
   - Authentication requirements (Bearer token format)
   - Rate limiting thresholds (100 requests/minute)
4. **Brand Transformation**: Applies solution-focused language ("Establish new build records through authenticated POST requests")
5. **Quality Validation**: Scores 87/100 (GOOD) - verifies code blocks, link integrity, brand compliance
6. **File Update**: Writes enhanced documentation with preserved formatting

**Expected Duration**: 2-3 minutes
**Output**: Updated file + quality report (87/100, brand compliant)

**Verification Steps**:
```bash
# Confirm file was updated
git diff docs/api/endpoints.md

# Validate markdown rendering
cat docs/api/endpoints.md | grep "POST /api/builds"
```

---

### Example 2: Fix Typos with Version Update

**Business Context**: Customer reported outdated Node.js version requirement causing installation failures.

```bash
/docs:update-simple "README.md" \
  "Fix typos in installation section and update Node.js version requirement from 16.x to 18.0.0 minimum"
```

**Execution Flow**:
1. **Read Current State**: Fetches README.md (current: "Node.js >= 16.0.0", 3 spelling errors in installation section)
2. **Precise Corrections**: Corrects "intallation" → "installation", "dependancies" → "dependencies", "enviroment" → "environment"
3. **Version Update**: Changes prerequisite from "Node.js >= 16.0.0" to "Node.js >= 18.0.0"
4. **Structure Preservation**: Maintains existing header hierarchy and formatting
5. **Quality Validation**: Scores 92/100 (EXCELLENT)
6. **File Update**: Writes corrected README.md

**Expected Duration**: 1-2 minutes
**Output**: Corrected file with maintained brand voice

**Verification Steps**:
```bash
# Verify version update
grep "Node.js" README.md  # Should show: Node.js >= 18.0.0

# Check for typos
grep -i "intallation\|dependancies\|enviroment" README.md  # Should return no results
```

---

### Example 3: Update with Auto-Commit (Streamlined Git Workflow)

**Business Context**: Azure Managed Identity deployment complete, documentation must be updated and committed immediately for team visibility.

```bash
/docs:update-simple "docs/guides/deployment.md" \
  "Add Azure Managed Identity authentication instructions with step-by-step setup, verification commands, and troubleshooting guidance" \
  --commit
```

**Execution Flow**:
1. **Content Generation**: Creates comprehensive Managed Identity section with:
   - Step-by-step setup instructions (Azure Portal + Azure CLI)
   - Explicit version requirements (Azure CLI >= 2.50.0)
   - Verification commands (`az account show`, `az identity show`)
   - Common error resolutions (permission issues, scope misconfigurations)
2. **Brand Transformation**: Applies solution-focused language ("Establish secure Azure access without credential management overhead")
3. **Quality Validation**: Scores 94/100 (EXCELLENT)
4. **File Update**: Writes enhanced deployment guide
5. **Git Commit**: Creates conventional commit with Claude co-authorship:

```bash
docs: Enhance deployment guide with Managed Identity authentication for secure Azure access

Establish secure cloud resource access through Azure Managed Identity, eliminating
hardcoded credentials and streamlining authentication workflows for scalable deployments.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Expected Duration**: 3-4 minutes (includes commit creation)
**Output**: Updated file + Git commit (hash: `a1b2c3d4`)

**Verification Steps**:
```bash
# Verify commit was created
git log -1 --oneline  # Should show: "docs: Enhance deployment guide..."

# Verify file content
git diff HEAD~1 docs/guides/deployment.md
```

---

### Example 4: Quick Fix Without Validation (Speed-Optimized)

**Business Context**: Emergency changelog update for hotfix release v1.2.3 requires immediate visibility.

```bash
/docs:update-simple "CHANGELOG.md" \
  "Add v1.2.3 release notes with critical security fix for authentication bypass vulnerability" \
  --no-validation
```

**Execution Flow**:
1. **Read Current State**: Fetches CHANGELOG.md
2. **Add Entry**: Inserts new version section at top:
   ```markdown
   ## [1.2.3] - 2025-10-26

   ### Security
   - Fixed authentication bypass vulnerability in OAuth token validation (CVE-2025-12345)

   ### Changed
   - Updated jwt-decode dependency from 3.1.2 to 4.0.0
   ```
3. **Skip Validation**: Bypasses quality checks for speed (saves ~30 seconds)
4. **File Update**: Writes updated CHANGELOG.md

**Expected Duration**: <1 minute
**Output**: Updated changelog (validation skipped)

**⚠️ Important**: Use `--no-validation` ONLY for:
- Changelogs and version bumps
- Non-customer-facing internal documents
- Time-critical emergency updates

**Do NOT use for**:
- API documentation
- Deployment guides
- README files
- Any customer-facing content

**Verification Steps**:
```bash
# Verify entry was added
head -n 15 CHANGELOG.md  # Should show new v1.2.3 section at top
```

---

## Workflow Execution Architecture

### Step-by-Step Process Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ Step 1: Request Reception & Validation                         │
├─────────────────────────────────────────────────────────────────┤
│ ✓ Parse command parameters (file-path, update-description)     │
│ ✓ Validate file path exists (absolute path resolution)         │
│ ✓ Confirm update description is explicit and executable        │
│ ✓ Verify repository Git status (clean working directory)       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 2: Read Current Content                                   │
├─────────────────────────────────────────────────────────────────┤
│ ✓ Use Read tool to fetch file contents                         │
│ ✓ Parse markdown structure (headers, code blocks, lists)       │
│ ✓ Identify target sections for updates                         │
│ ✓ Preserve existing formatting and indentation                 │
│ ✓ Detect brand voice patterns (baseline for consistency)       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 3: Apply Updates via @markdown-expert                     │
├─────────────────────────────────────────────────────────────────┤
│ ✓ Delegate content generation to @markdown-expert              │
│ ✓ Make requested changes (explicit, idempotent operations)     │
│ ✓ Apply Brookside BI brand voice (if --brand-voice=true):      │
│   • Lead with business outcomes before technical details       │
│   • Use solution-focused language patterns                     │
│   • Add "Best for:" context qualifiers where appropriate       │
│   • Maintain professional consultative tone                    │
│ ✓ Maintain consistent markdown structure                       │
│ ✓ Ensure AI-agent executable format (no ambiguity)             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 4: Quality Validation (unless --no-validation)            │
├─────────────────────────────────────────────────────────────────┤
│ Brand Compliance (0-30 points):                                │
│ ✓ Professional but approachable tone                           │
│ ✓ Solution-focused language patterns present                   │
│ ✓ Outcome-focused descriptions used                            │
│ ✓ Consultative positioning maintained                          │
│                                                                 │
│ Technical Standards (0-40 points):                             │
│ ✓ No ambiguous instructions (explicit commands)                │
│ ✓ Explicit version requirements (e.g., "Node.js >= 18.0.0")    │
│ ✓ Idempotent setup steps (safe to re-run)                      │
│ ✓ Verification commands included (e.g., `git diff`)            │
│ ✓ Error handling documented (common issues + resolutions)      │
│                                                                 │
│ Markdown Quality (0-30 points):                                │
│ ✓ Proper header hierarchy (H1→H2→H3, no skips)                 │
│ ✓ Code blocks have language tags (bash, typescript, json)      │
│ ✓ Links are descriptive (not "click here")                     │
│ ✓ Working examples with expected outputs                       │
│ ✓ Consistent formatting (spacing, indentation)                 │
│                                                                 │
│ Total Score: 0-100                                             │
│ • 90-100: EXCELLENT (production-ready, publish immediately)     │
│ • 70-89: GOOD (minor improvements suggested, approve)          │
│ • 50-69: ADEQUATE (requires work before approval)              │
│ • 0-49: POOR (significant issues, reject and revise)           │
│                                                                 │
│ Minimum Required Score: 70 (GOOD)                              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 5: Write Updated File                                     │
├─────────────────────────────────────────────────────────────────┤
│ ✓ Use Write tool to save changes to disk                       │
│ ✓ Preserve file permissions (Unix: maintain chmod settings)    │
│ ✓ Maintain line endings (LF for Unix, CRLF for Windows)        │
│ ✓ Verify write success (file size, last modified timestamp)    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 6: Optional Git Commit (if --commit flag provided)        │
├─────────────────────────────────────────────────────────────────┤
│ ✓ Stage file: `git add <file-path>`                            │
│ ✓ Create conventional commit message:                          │
│   Format: "docs: <imperative> for <business benefit>"          │
│   Example: "docs: Enhance API guide with authentication..."    │
│ ✓ Include Claude co-authorship footer                          │
│ ✓ Execute commit: `git commit -m "<message>"`                  │
│ ✓ Capture commit hash for verification                         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 7: Return Summary Report                                  │
├─────────────────────────────────────────────────────────────────┤
│ ✓ List all changes made (specific sections modified)           │
│ ✓ Report quality score (if validation was performed)           │
│ ✓ Note any issues or warnings encountered                      │
│ ✓ Provide verification commands for testing                    │
│ ✓ Suggest next steps (if applicable)                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Output Format Specifications

### Success Response Structure

```json
{
  "status": "completed",
  "file": "docs/api/endpoints.md",
  "changes": [
    "Added POST /api/builds endpoint documentation (lines 142-198)",
    "Included request schema with 8 validation rules for data quality",
    "Added response examples for 201 Created, 400 Bad Request, 401 Unauthorized",
    "Applied brand voice transformation to endpoint introduction",
    "Added rate limiting documentation (100 requests/minute)"
  ],
  "quality_validation": {
    "enabled": true,
    "score": 87,
    "rating": "GOOD",
    "breakdown": {
      "brand_compliance": 26,
      "technical_standards": 35,
      "markdown_quality": 26
    }
  },
  "brand_compliant": true,
  "metrics": {
    "duration_seconds": 142,
    "lines_added": 56,
    "lines_modified": 3,
    "code_blocks_added": 4
  },
  "commit": {
    "created": false,
    "hash": null
  },
  "verification_commands": [
    "git diff docs/api/endpoints.md",
    "grep 'POST /api/builds' docs/api/endpoints.md"
  ],
  "next_steps": [
    "Review changes with git diff",
    "Test endpoint examples with curl commands",
    "Update Notion Knowledge Vault with /docs:sync-notion"
  ]
}
```

### Error Response Structure

```json
{
  "status": "failed",
  "error_type": "file_not_found",
  "error": "File not found: docs/api/endpoints.md",
  "suggestion": "Verify file path is correct relative to repository root. Did you mean 'docs/api/endpoint.md' (singular)?",
  "available_similar_files": [
    "docs/api/endpoint.md",
    "docs/apis/endpoints.md",
    "docs/api/overview.md"
  ],
  "duration_seconds": 5,
  "resolution_steps": [
    "1. Verify file path with: ls docs/api/",
    "2. Check repository root with: pwd",
    "3. Use absolute path or correct relative path",
    "4. Retry command with corrected path"
  ]
}
```

---

## Quality Validation Framework

### Scoring Algorithm (0-100 Total Points)

#### 1. Brand Compliance (0-30 points)

**Evaluation Criteria**:
- ✓ **Professional but Approachable Tone** (6 points): Maintains corporate professionalism while remaining accessible (no jargon without explanation)
- ✓ **Solution-Focused Language** (6 points): Frames content around business outcomes ("streamline workflows," "drive measurable outcomes")
- ✓ **"Best for:" Qualifiers Present** (6 points): Includes context for appropriate use cases
- ✓ **Outcome-Focused Descriptions** (6 points): Leads with benefits before technical implementation details
- ✓ **Consultative Positioning** (6 points): Emphasizes partnership and strategic value

**Example Transformation**:
```markdown
❌ Before (0 points):
Initialize the database connection and run migrations.

✅ After (30 points):
Establish scalable data access layer to support multi-team operations through
automated database initialization and schema migrations. Best for: Organizations
requiring consistent database state across development and production environments.
```

#### 2. Technical Standards (0-40 points)

**Evaluation Criteria**:
- ✓ **No Ambiguous Instructions** (10 points): Every step is explicit and AI-agent executable
- ✓ **Explicit Version Requirements** (8 points): All dependencies specify exact versions (e.g., "Node.js >= 18.0.0")
- ✓ **Idempotent Setup Steps** (8 points): Commands can be safely re-run without side effects
- ✓ **Verification Commands Included** (7 points): Each major step has verification instructions
- ✓ **Error Handling Documented** (7 points): Common errors and resolutions are documented

**Example Scoring**:
```markdown
❌ Poor (0 points):
Install Node and run the app.

⚠️ Adequate (20 points):
Install Node.js and run `npm start`.

✅ Excellent (40 points):
**Prerequisites**: Node.js >= 18.0.0, npm >= 9.0.0

**Installation** (idempotent):
```bash
# Install dependencies
npm ci  # Use ci for reproducible installs

# Verification
node --version  # Should output: v18.x.x or higher
npm --version   # Should output: 9.x.x or higher
```

**Common Error**: "Module not found"
- **Cause**: Dependencies not installed
- **Resolution**: Run `npm ci` to install all required packages
```

#### 3. Markdown Quality (0-30 points)

**Evaluation Criteria**:
- ✓ **Proper Header Hierarchy** (8 points): H1→H2→H3 progression, no skipped levels
- ✓ **Code Blocks with Language Tags** (8 points): All code blocks specify language (`bash`, `typescript`, `json`)
- ✓ **Descriptive Links** (4 points): Link text describes destination (not "click here")
- ✓ **Working Examples with Outputs** (6 points): Examples include expected results
- ✓ **Consistent Formatting** (4 points): Uniform spacing, indentation, and styling

**Example Scoring**:
```markdown
❌ Poor (0 points):
# API
Run this: node server.js
[link](http://example.com)

⚠️ Adequate (15 points):
# API Documentation
Start the server:
```
node server.js
```
See [documentation](http://example.com).

✅ Excellent (30 points):
# API Documentation

## Starting the Server

**Best for**: Local development and testing environments

```bash
# Start API server on port 3000
node server.js

# Expected output:
# Server listening on http://localhost:3000
# Database connected to postgres://localhost:5432/app
```

**Verification**:
```bash
curl http://localhost:3000/health
# Should return: {"status":"healthy"}
```

**Related Resources**: [API endpoint reference](docs/api/endpoints.md) for complete endpoint documentation.
```

---

## Common Use Cases

### 1. API Documentation Updates

**Business Context**: Establish comprehensive API documentation that accelerates developer onboarding and reduces support burden.

**Scenario**: New authentication endpoint added to API

```bash
/docs:update-simple "docs/api/endpoints.md" \
  "Add GET /api/research endpoint with query parameter documentation, authentication requirements, rate limiting, and error response codes"
```

**Changes Applied**:
- New endpoint section created with proper hierarchy
- Request/response schemas with field descriptions and validation rules
- Example curl commands with real headers and payloads
- Error response codes documented (400/401/403/429/500)
- Brand voice applied: "Establish secure research data retrieval through authenticated GET requests"
- Rate limiting details: "100 requests per minute per API key"

**Verification**:
```bash
# Verify endpoint documentation exists
grep -A 20 "GET /api/research" docs/api/endpoints.md

# Test example curl command
curl -X GET "http://localhost:3000/api/research?query=innovation" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### 2. README Maintenance

**Business Context**: Maintain accurate installation documentation to prevent developer environment setup failures.

**Scenario**: Update prerequisites for new PostgreSQL dependency

```bash
/docs:update-simple "README.md" \
  "Update prerequisites section to include PostgreSQL >= 14.0 with installation instructions for Windows, macOS, and Linux, plus connection verification steps"
```

**Changes Applied**:
- Prerequisites section updated with explicit PostgreSQL version requirement
- Platform-specific installation commands added:
  - Windows: `winget install PostgreSQL.PostgreSQL`
  - macOS: `brew install postgresql@14`
  - Linux: `sudo apt-get install postgresql-14`
- Connection verification steps included:
  ```bash
  psql --version  # Should output: psql (PostgreSQL) 14.x
  pg_isready      # Should output: accepting connections
  ```
- Existing structure and brand voice preserved

**Verification**:
```bash
# Verify prerequisite was added
grep "PostgreSQL" README.md  # Should show: PostgreSQL >= 14.0

# Verify installation commands are present
grep -A 5 "Platform-specific installation" README.md
```

---

### 3. Troubleshooting Guide Expansion

**Business Context**: Reduce Azure SQL Database connection timeout support tickets through proactive documentation.

**Scenario**: Add resolution for "Connection timeout" error

```bash
/docs:update-simple "docs/guides/troubleshooting.md" \
  "Add resolution for 'Connection timeout to Azure SQL Database' error with symptoms, causes, idempotent solutions, and verification commands"
```

**Changes Applied**:
- New troubleshooting entry added in appropriate section
- **Error Symptoms**: "Connection attempt fails after 30 seconds with ETIMEDOUT"
- **Root Causes**: Firewall rules, network configuration, DNS resolution
- **Solution Steps** (idempotent):
  1. Verify firewall allows Azure service connections
  2. Add client IP to Azure SQL firewall rules
  3. Test DNS resolution: `nslookup your-server.database.windows.net`
  4. Verify connection string format
- **Verification**: `sqlcmd -S your-server.database.windows.net -U username -P password -Q "SELECT 1"`
- Related links included: [Azure SQL firewall documentation](https://learn.microsoft.com/azure/azure-sql/)

**Verification**:
```bash
# Verify troubleshooting entry was added
grep -A 15 "Connection timeout" docs/guides/troubleshooting.md
```

---

### 4. CHANGELOG Updates (Speed-Optimized)

**Business Context**: Communicate release changes immediately to stakeholders without quality validation overhead.

**Scenario**: Release new version with features and bug fixes

```bash
/docs:update-simple "CHANGELOG.md" \
  "Add v2.1.0 release notes with new authentication features, performance improvements, and 3 critical bug fixes" \
  --no-validation \
  --commit
```

**Changes Applied**:
- New version entry created at top of CHANGELOG:
  ```markdown
  ## [2.1.0] - 2025-10-26

  ### Added
  - Azure Managed Identity authentication support
  - OAuth2 token refresh automation

  ### Improved
  - 40% reduction in API response time through query optimization
  - Database connection pooling for scalable concurrent requests

  ### Fixed
  - Critical: Authentication bypass vulnerability (CVE-2025-12345)
  - Memory leak in WebSocket connection handler
  - Race condition in cache invalidation logic
  ```
- Quality validation skipped (saves ~30 seconds)
- Auto-committed with conventional message

**Verification**:
```bash
# Verify changelog entry
head -n 20 CHANGELOG.md  # Should show new v2.1.0 section

# Verify commit was created
git log -1 --oneline  # Should show: "docs: Add v2.1.0 release notes..."
```

---

## Integration with Documentation Orchestrator

### Agent Delegation Architecture

**Purpose**: Establish intelligent routing for documentation updates through specialized agent capabilities, ensuring optimal quality while maintaining execution velocity.

```
User Command: /docs:update-simple
         ↓
┌────────────────────────────────────┐
│ @documentation-orchestrator        │  ← Coordination & validation
│ (Request routing & quality gates)  │
└────────────────────────────────────┘
         ↓
┌────────────────────────────────────┐
│ @markdown-expert                   │  ← Content generation & formatting
│ (Markdown syntax & brand voice)    │
└────────────────────────────────────┘
         ↓
Updated file with quality report (87/100, brand compliant)
```

**Agent Responsibilities**:

**@documentation-orchestrator**:
- Parse command parameters and validate file paths
- Read existing file content and structure
- Coordinate update execution with @markdown-expert
- Perform quality validation (brand compliance, technical standards, markdown quality)
- Handle Git operations (staging, committing)
- Generate summary reports with verification steps

**@markdown-expert**:
- Apply markdown formatting best practices
- Transform content with Brookside BI brand voice
- Ensure proper header hierarchy and code block syntax
- Generate AI-agent executable instructions
- Maintain consistent documentation structure

### When to Use Alternative Commands

**For Complex Scenarios**:

| Your Need | Use This Command | Reason |
|-----------|------------------|---------|
| Update 2+ files simultaneously | `/docs:update-complex` | Handles multi-file coordination and consistency |
| Generate architecture diagrams | `/docs:update-complex --diagrams` | Includes Mermaid diagram generation and embedding |
| Full documentation site refresh | `/docs:update-complex --full-refresh` | Rebuilds entire documentation structure |
| Sync to Notion Knowledge Vault | `/docs:sync-notion` | Integrates with Notion MCP for knowledge archival |
| Create new documentation from scratch | `/docs:create` | Templates and scaffolding for greenfield docs |

---

## Error Handling & Troubleshooting

### Common Errors and Resolution Steps

#### Error: File Not Found

**Symptom**:
```json
{
  "status": "failed",
  "error": "File not found: docs/api/endpoints.md"
}
```

**Root Causes**:
- Incorrect relative path (not from repository root)
- File was moved or deleted
- Typo in file name

**Resolution Steps** (idempotent):
```bash
# 1. Verify current directory
pwd  # Should show repository root

# 2. List available files
ls docs/api/  # Check if file exists

# 3. Search for similar files
find . -name "*endpoint*" -type f

# 4. Correct the path and retry
/docs:update-simple "docs/api/endpoint.md" "..."  # Use correct path
```

**Prevention**: Always use tab completion or `ls` to verify file paths before executing command.

---

#### Error: Quality Validation Failed

**Symptom**:
```json
{
  "status": "completed_with_warnings",
  "quality_score": 58,
  "rating": "ADEQUATE",
  "issues": [
    "Missing code block language tags (3 instances)",
    "Ambiguous instruction: 'Run the server' needs explicit command",
    "No verification steps provided"
  ]
}
```

**Root Causes**:
- Insufficient technical detail in update description
- Missing required elements (verification commands, error handling)
- Inconsistent brand voice

**Resolution Steps**:
```bash
# 1. Review quality report details
# Read issues list carefully

# 2. For minor issues (score 60-69): Manual fixes
# Edit file directly to address specific issues

# 3. For major issues (score <60): Re-run with better description
/docs:update-simple "docs/api/endpoints.md" \
  "Add POST /api/builds endpoint with explicit request schema, response examples for 201/400/401, authentication requirements using Bearer tokens, rate limiting details (100/min), and verification curl commands"

# 4. For time-critical updates: Use --no-validation (non-customer-facing only)
/docs:update-simple "internal/notes.md" "..." --no-validation
```

**Prevention**: Write explicit update descriptions that include verification requirements and expected outputs.

---

#### Error: Markdown Syntax Error

**Symptom**:
```json
{
  "status": "failed",
  "error": "Markdown parsing error: Unclosed code block at line 145"
}
```

**Root Causes**:
- Malformed code block (missing closing backticks)
- Incorrect table syntax
- Unescaped special characters in content

**Resolution Steps**:
```bash
# 1. Read the file to identify syntax issues
cat docs/api/endpoints.md | grep -A 5 -B 5 "line 145"

# 2. Manually fix syntax error
# Edit file at line 145 to close code block

# 3. Verify markdown syntax
npx markdownlint docs/api/endpoints.md

# 4. Retry update
/docs:update-simple "docs/api/endpoints.md" "..."
```

**Prevention**: Use `markdownlint` in pre-commit hooks to catch syntax errors before commits.

---

#### Error: Git Commit Failed

**Symptom**:
```json
{
  "status": "completed",
  "commit": {
    "created": false,
    "error": "fatal: Unable to create '.git/index.lock': File exists"
  }
}
```

**Root Causes**:
- Git index lock file exists (previous operation interrupted)
- Merge conflicts in working directory
- Insufficient Git configuration

**Resolution Steps**:
```bash
# 1. Check Git status
git status  # Review working directory state

# 2. Remove stale lock file (if safe)
rm .git/index.lock  # Only if no Git operations are running

# 3. Resolve merge conflicts (if present)
git diff  # Review conflicts
# Manually resolve conflicts
git add <resolved-files>

# 4. Verify Git configuration
git config user.name  # Should return your name
git config user.email  # Should return your email

# 5. Retry command with --commit
/docs:update-simple "docs/..." "..." --commit
```

**Prevention**: Always verify Git status (`git status`) shows clean working directory before using `--commit` flag.

---

## Best Practices for Sustainable Documentation

### When to Use `/docs:update-simple`

**✓ Optimal Use Cases**:
- Single file modifications (1 file only)
- Typo fixes and spelling corrections
- Adding new sections to existing documents (<500 words)
- Updating version numbers, links, or references
- Quick content additions that don't require restructuring
- Emergency hotfix documentation updates

**✗ Inappropriate Use Cases** (use alternatives):
- Multiple file updates → Use `/docs:update-complex`
- Major restructuring (changing entire document organization) → Use `/docs:update-complex --full-refresh`
- Diagram generation or updates → Use `/docs:update-complex --diagrams`
- Notion Knowledge Vault synchronization → Use `/docs:sync-notion`
- Creating new documentation from templates → Use `/docs:create`

---

### Writing Effective Update Descriptions

**Purpose**: Establish explicit, AI-agent executable instructions that eliminate ambiguity and drive consistent outcomes.

**Good Descriptions** (specific, actionable, measurable):
- ✅ "Add POST /api/costs endpoint with request schema (5 required fields), response examples for 201/400/401, authentication requirements using Bearer tokens, rate limiting details (100 requests/minute), and verification curl commands"
- ✅ "Fix broken internal links in architecture overview section (lines 45-78) to point to correct files in docs/architecture/ directory"
- ✅ "Update Azure SQL connection instructions to use Managed Identity authentication instead of SQL authentication, including setup steps, verification commands, and troubleshooting for permission issues"

**Poor Descriptions** (vague, non-actionable):
- ❌ "Fix docs" → No specific target or action
- ❌ "Update stuff in API section" → Unclear what to update
- ❌ "Make it better" → No measurable criteria
- ❌ "Add authentication" → Missing context (where? which type? how detailed?)

**Formula for Effective Descriptions**:
```
[Action Verb] + [Specific Target] + [Key Details] + [Verification Criteria]

Example:
"Add" + "POST /api/costs endpoint" + "with schema, auth, rate limits" + "and curl verification commands"
```

---

### Performance Optimization

**Target SLA Commitments**:

| Operation | Target Duration | Optimization Strategy |
|-----------|----------------|----------------------|
| Read file | <5 seconds | Use Read tool with efficient file system access |
| Apply updates | <60 seconds | Delegate to specialized @markdown-expert for parallel processing |
| Quality validation | <30 seconds | Cached validation rules, parallel checks |
| Write file | <5 seconds | Atomic write operations, no intermediate files |
| Create commit | <20 seconds | Batch Git operations, single commit message generation |

**Total Duration Targets**:
- **Without validation**: 1-2 minutes (speed-optimized for changelogs)
- **With validation**: 2-3 minutes (balanced quality and velocity)
- **With validation + commit**: 3-4 minutes (comprehensive workflow)

**When Performance Matters**:
- Use `--no-validation` for time-critical updates (non-customer-facing)
- Batch multiple updates using `/docs:update-complex` instead of serial `/docs:update-simple` calls
- Pre-verify file paths with `ls` to avoid retry overhead

---

## Agent Activity Logging

**Purpose**: Establish transparent documentation work tracking for workflow continuity and productivity analytics.

### Automatic Logging

All documentation updates are automatically logged to the Agent Activity Hub:

```yaml
Session ID: documentation-orchestrator-2025-10-26-1430
Agent: @documentation-orchestrator → @markdown-expert
Status: completed
Duration: 142 seconds
Work Description: Updated docs/api/endpoints.md with POST /api/builds endpoint documentation

Deliverables:
  - docs/api/endpoints.md (56 lines added, 3 lines modified)
  - Quality report (87/100, GOOD rating, brand compliant)

Metrics:
  - Code blocks added: 4
  - Technical density: 0.65
  - Brand compliance score: 26/30
  - Verification commands provided: 2

Related Notion Items:
  - None (documentation maintenance work)

Next Steps:
  - Review changes with: git diff docs/api/endpoints.md
  - Test endpoint examples with curl commands
  - Consider syncing to Knowledge Vault with /docs:sync-notion
```

### View Activity Logs

```bash
# View markdown log (human-readable)
cat .claude/logs/AGENT_ACTIVITY_LOG.md

# View JSON state (machine-readable)
cat .claude/data/agent-state.json | jq '.sessions[] | select(.agent=="documentation-orchestrator")'

# View Notion Activity Hub (team-accessible)
https://www.notion.so/72b879f213bd4edb9c59b43089dbef21
```

---

## Related Commands & Workflows

### Command Comparison Matrix

| Command | Files | Diagrams | Notion Sync | Validation | Use Case |
|---------|-------|----------|-------------|-----------|----------|
| `/docs:update-simple` | 1 | ❌ | ❌ | ✅ | Quick single-file updates |
| `/docs:update-complex` | 1+ | ✅ | ❌ | ✅ | Multi-file updates with diagrams |
| `/docs:sync-notion` | Any | ❌ | ✅ | ✅ | Archive to Knowledge Vault |
| `/docs:create` | 1 | ✅ | ❌ | ✅ | Generate new documentation |

### Common Workflow Sequences

#### Workflow 1: API Endpoint Addition (Complete Lifecycle)

```bash
# Step 1: Update API documentation
/docs:update-simple "docs/api/endpoints.md" \
  "Add POST /api/research endpoint with complete schema and examples" \
  --commit

# Step 2: Update README with new endpoint reference
/docs:update-simple "README.md" \
  "Add POST /api/research endpoint to API Quick Reference section" \
  --commit

# Step 3: Sync to Notion Knowledge Vault
/docs:sync-notion "docs/api/endpoints.md" --database="knowledge"

# Step 4: Log activity for team visibility
# (Automatic via Phase 4 autonomous logging)
```

#### Workflow 2: Deployment Guide Enhancement

```bash
# Step 1: Add new deployment method
/docs:update-complex "docs/guides/deployment.md" \
  "Add Azure Container Apps deployment with Bicep templates" \
  --diagrams \
  --commit

# Step 2: Update troubleshooting guide
/docs:update-simple "docs/guides/troubleshooting.md" \
  "Add Container Apps deployment errors and resolutions"

# Step 3: Verify all changes
git diff HEAD~2  # Review last 2 commits
```

---

## Support & Resources

### Documentation Assistance

**For documentation command questions or technical support:**

- **Email**: [Consultations@BrooksideBI.com](mailto:Consultations@BrooksideBI.com)
- **Phone**: +1 209 487 2047
- **Business Hours**: Monday-Friday, 8:00 AM - 5:00 PM Pacific Time

**Response Time SLAs**:
- Critical issues (blocking deployments): <2 hours
- High priority (documentation errors): <4 hours
- Normal priority (enhancements): <1 business day

### Related Documentation

**Command Documentation**:
- [/docs:update-complex](./update-complex.md) - Multi-file updates with diagrams
- [/docs:sync-notion](./sync-notion.md) - Notion Knowledge Vault integration
- [/docs:create](./create.md) - Generate new documentation from templates

**Agent Specifications**:
- [@documentation-orchestrator](../../agents/documentation-orchestrator.md) - Command coordinator
- [@markdown-expert](../../agents/markdown-expert.md) - Content formatting specialist

**Best Practices Guides**:
- [Brookside BI Brand Guidelines](../../docs/brand-guidelines.md)
- [AI-Agent Executable Documentation Standards](../../docs/ai-agent-docs.md)
- [Markdown Quality Standards](../../docs/markdown-standards.md)

---

**Update Simple Documentation Command** - Streamline single-file documentation maintenance through intelligent quality validation and automated brand compliance, establishing sustainable knowledge management practices that drive measurable improvements in documentation effectiveness and team productivity.

**Designed for**: Organizations requiring fast, reliable documentation updates while maintaining consistent brand standards and technical quality across all knowledge assets. Best for: Teams managing technical documentation at scale where quality and velocity drive competitive advantage.
