# Documentation Quality Checker

**Purpose**: Automated quality assessment for technical documentation to ensure brand compliance, technical accuracy, and AI-agent readability.

**Best for**: Organizations requiring systematic documentation standards enforcement across repositories and knowledge bases.

## Quality Assessment Framework

### Total Score Calculation (0-100)

```
Documentation Quality Score =
  Brand Compliance (30 points) +
  Technical Standards (25 points) +
  Structure & Formatting (20 points) +
  Completeness (15 points) +
  Accessibility (10 points)
```

### 1. Brand Compliance (0-30 points)

**Brookside BI Brand Voice Assessment:**

✓ **Professional but Approachable** (5 points)
- Corporate, professional tone maintained
- Technical jargon explained when used
- Confident expertise without condescension

✓ **Solution-Focused Language** (10 points)
- Leads with benefits/outcomes
- Uses action-oriented language
- Emphasizes tangible results ("streamline", "improve", "drive outcomes")

✓ **Consultative Positioning** (5 points)
- Positions as partnership, not just deliverable
- Focus on sustainability ("sustainable practices", "scalable architecture")
- Demonstrates organizational scaling understanding

✓ **Required Qualifiers Present** (5 points)
- "Best for:" sections included
- "Designed for:" context provided
- Clear target audience definition

✓ **Core Language Patterns** (5 points)
- "Establish structure and rules for..."
- "This solution is designed to..."
- "Organizations scaling [technology] across..."
- "Streamline workflows and improve visibility"

**Scoring:**
- 25-30 points: Excellent brand alignment
- 20-24 points: Good, minor adjustments needed
- 15-19 points: Adequate, needs brand voice enhancement
- <15 points: Poor brand compliance

### 2. Technical Standards (0-25 points)

**AI-Agent Executable Requirements:**

✓ **No Ambiguity** (5 points)
- Instructions executable without human interpretation
- Commands provided with exact syntax
- No vague language ("probably", "might", "should work")

✓ **Explicit Versions** (5 points)
- Dependencies specify exact versions (node >= 18.0.0)
- Tools show minimum required versions
- API versions documented

✓ **Idempotent Steps** (5 points)
- Setup steps runnable multiple times safely
- Script checks for existing state
- Clear instructions for re-running

✓ **Environment Aware** (5 points)
- Dev/staging/prod configurations separated
- Environment variables clearly documented
- Context-specific instructions provided

✓ **Verification Steps** (5 points)
- Commands to verify each step succeeded
- Expected outputs documented
- Health check procedures included

**Scoring:**
- 20-25 points: Production-ready technical documentation
- 15-19 points: Good technical standards, minor gaps
- 10-14 points: Basic technical content, needs improvement
- <10 points: Significant technical documentation gaps

### 3. Structure & Formatting (0-20 points)

**Markdown Standards:**

✓ **Proper Header Hierarchy** (5 points)
- H1 for title only
- H2 for major sections
- H3-H6 for subsections
- No skipped levels

✓ **Code Blocks with Language Tags** (5 points)
- All code blocks have language identifier
- Syntax highlighting enabled
- Examples use realistic data

✓ **Working Examples** (5 points)
- Examples include expected outputs
- Copy-paste ready commands
- Realistic scenario-based examples

✓ **Visual Hierarchy** (5 points)
- Clear section separation
- Proper use of lists, tables, code blocks
- Callouts for important information
- Consistent formatting throughout

**Scoring:**
- 16-20 points: Excellent structure and formatting
- 12-15 points: Good structure, minor formatting issues
- 8-11 points: Basic structure, needs formatting work
- <8 points: Poor structure and formatting

### 4. Completeness (0-15 points)

**Required Documentation Elements:**

✓ **Introduction/Overview** (3 points)
- Clear purpose statement
- Target audience defined
- Value proposition articulated

✓ **Prerequisites** (3 points)
- Required software/tools listed
- Minimum versions specified
- Access/permissions documented

✓ **Setup Instructions** (3 points)
- Step-by-step installation
- Configuration procedures
- Verification commands

✓ **Usage Examples** (3 points)
- Common use cases covered
- Example commands with outputs
- Troubleshooting common issues

✓ **Related Resources** (3 points)
- Links to related documentation
- External references
- Contact information

**Scoring:**
- 12-15 points: Comprehensive documentation
- 9-11 points: Good coverage, minor gaps
- 6-8 points: Basic coverage, missing key sections
- <6 points: Incomplete documentation

### 5. Accessibility (0-10 points)

**Discoverability & Usability:**

✓ **Table of Contents** (2 points)
- TOC for documents >500 lines
- Jump links functional
- Clear section organization

✓ **Search Optimization** (2 points)
- Descriptive headers
- Keywords in first paragraph
- Meaningful anchor links

✓ **Link Validity** (3 points)
- All internal links work
- External links tested
- Relative paths correct

✓ **Cross-References** (3 points)
- Related docs linked
- Consistent terminology
- Navigation between related topics

**Scoring:**
- 8-10 points: Highly accessible documentation
- 6-7 points: Good accessibility
- 4-5 points: Basic accessibility
- <4 points: Poor discoverability

## Quality Ratings

### Overall Documentation Quality

```
90-100: EXCELLENT
  - Production-ready documentation
  - Exemplary brand compliance
  - Comprehensive technical coverage
  - Highly accessible and maintainable

70-89: GOOD
  - Well-documented with minor gaps
  - Strong brand alignment
  - Solid technical foundation
  - Generally accessible

50-69: ADEQUATE
  - Basic documentation present
  - Some brand compliance
  - Functional technical content
  - Accessibility improvements needed

0-49: POOR
  - Significant documentation gaps
  - Weak brand compliance
  - Insufficient technical detail
  - Difficult to discover and use
```

## Quality Checker Usage

### Command Line Interface

```bash
# Check single file
node .claude/utils/documentation/quality-checker.js docs/api/endpoints.md

# Check multiple files
node .claude/utils/documentation/quality-checker.js docs/**/*.md

# Check with detailed report
node .claude/utils/documentation/quality-checker.js --detailed README.md

# Check and generate JSON report
node .claude/utils/documentation/quality-checker.js --json docs/architecture/overview.md
```

### Programmatic Usage

```javascript
const { assessDocumentationQuality } = require('.claude/utils/documentation/quality-checker');

const result = await assessDocumentationQuality('docs/api/endpoints.md');

console.log(`Overall Score: ${result.totalScore}/100`);
console.log(`Rating: ${result.rating}`);
console.log(`Brand Compliance: ${result.brandCompliance}/30`);
console.log(`Technical Standards: ${result.technicalStandards}/25`);
```

### Example Output

```json
{
  "file": "docs/api/endpoints.md",
  "totalScore": 87,
  "rating": "GOOD",
  "brandCompliance": {
    "score": 26,
    "maxScore": 30,
    "issues": [
      "Missing 'Best for:' qualifier in introduction"
    ],
    "strengths": [
      "Excellent solution-focused language",
      "Strong consultative positioning",
      "Core language patterns used effectively"
    ]
  },
  "technicalStandards": {
    "score": 22,
    "maxScore": 25,
    "issues": [
      "Missing version specification for 'axios' dependency"
    ],
    "strengths": [
      "All commands are idempotent",
      "Verification steps provided",
      "Environment-specific configurations separated"
    ]
  },
  "structure": {
    "score": 18,
    "maxScore": 20,
    "issues": [
      "One code block missing language tag (line 142)"
    ]
  },
  "completeness": {
    "score": 13,
    "maxScore": 15,
    "issues": [
      "Troubleshooting section incomplete"
    ]
  },
  "accessibility": {
    "score": 8,
    "maxScore": 10,
    "issues": [
      "2 broken internal links"
    ]
  },
  "recommendations": [
    "Add 'Best for:' qualifier to introduction section",
    "Specify exact version for axios dependency (e.g., axios >= 1.4.0)",
    "Add language tag to code block at line 142",
    "Expand troubleshooting section with common error scenarios",
    "Fix broken links to architecture/overview.md and guides/setup.md"
  ]
}
```

## Automated Quality Checks

### Pre-Commit Hook Integration

```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: docs-quality-check
      name: Documentation Quality Check
      entry: node .claude/utils/documentation/quality-checker.js
      language: node
      files: \.(md|markdown)$
      args: ['--min-score', '70']
```

### CI/CD Integration

```yaml
# .github/workflows/documentation-quality.yml
name: Documentation Quality Check

on:
  pull_request:
    paths:
      - '**.md'
      - 'docs/**'

jobs:
  quality-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Quality Checker
        run: |
          node .claude/utils/documentation/quality-checker.js docs/**/*.md --min-score 70
      - name: Comment on PR
        if: failure()
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: 'Documentation quality check failed. Please review the quality report and address issues before merging.'
            })
```

## Brand Compliance Transformations

### Common Fixes Applied Automatically

**Before (Non-Compliant):**
```markdown
# User Authentication

This module handles user login.

## How to Use

Run the setup script to configure authentication.
```

**After (Brand-Compliant):**
```markdown
# User Authentication

Establish secure access control to protect sensitive data across your business environment.

**Best for**: Organizations requiring multi-tenant authentication with role-based access

## Setup Instructions

Streamline authentication configuration through the following structured approach:

1. Execute the setup script to establish authentication infrastructure
2. Configure role-based access rules for sustainable team collaboration
3. Verify security controls to ensure reliable access management
```

## Quality Improvement Workflow

```
Step 1: Run Quality Checker
├─ Assess current documentation score
├─ Identify specific issues
└─ Generate improvement recommendations

Step 2: Apply Automated Fixes
├─ Brand compliance transformations
├─ Add missing qualifiers ("Best for:")
├─ Fix code block language tags
└─ Repair broken links

Step 3: Manual Review
├─ Address technical gaps
├─ Expand incomplete sections
├─ Enhance examples with outputs
└─ Validate accuracy

Step 4: Re-Check Quality
├─ Run quality checker again
├─ Verify score improvement
└─ Confirm all issues resolved

Target: Achieve 70+ (GOOD) rating before merging
```

## Related Tools

- [Brand Voice Transformer](.claude/utils/documentation/brand-transformer.md) - Automated brand compliance
- [Link Validator](.claude/utils/documentation/link-validator.md) - Broken link detection
- [Template Generator](.claude/utils/documentation/template-generator.md) - Documentation scaffolding

---

**Documentation Quality Checker** - Establish systematic documentation standards that drive measurable outcomes through automated quality enforcement, brand compliance validation, and continuous improvement workflows.

**Designed for**: Organizations scaling documentation practices across teams who require enterprise-grade quality standards, AI-agent readability, and Brookside BI brand consistency that supports sustainable growth.
