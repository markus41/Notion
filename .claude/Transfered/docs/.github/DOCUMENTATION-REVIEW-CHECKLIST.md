# Documentation Review Checklist

> **Streamline documentation quality assurance** through systematic review processes, designed to drive measurable improvements in content accuracy, clarity, and consistency.

**Best for:** Reviewers, editors, and documentation teams ensuring content meets quality standards before publication.

**Last Updated:** 2025-10-14 | **Version:** 2.0

---

## Overview

This checklist provides a systematic approach to reviewing documentation pull requests and content updates. Use this as a gate before merging documentation changes into the main branch.

**Review Levels:**
- **Level 1: Basic** - Essential checks for all documentation (15 min)
- **Level 2: Standard** - Comprehensive review for most documentation (30 min)
- **Level 3: Deep** - Thorough review for critical documentation (60 min)

**Recommend Review Level:**
| Content Type | Level | Rationale |
|--------------|-------|-----------|
| Typo fixes, minor updates | Level 1 | Low risk |
| New guides, tutorials | Level 2 | Standard content |
| API references, architecture docs | Level 3 | Critical, high-impact |

---

## Table of Contents

- [Pre-Review Setup](#pre-review-setup)
- [Level 1: Basic Review](#level-1-basic-review)
- [Level 2: Standard Review](#level-2-standard-review)
- [Level 3: Deep Review](#level-3-deep-review)
- [Common Issues](#common-issues)
- [Reviewer Guidelines](#reviewer-guidelines)

---

## Pre-Review Setup

Before starting the review:

### 1. Understand the Context

- [ ] Read the PR description and linked issues
- [ ] Identify the target audience (business, developer, operator, architect)
- [ ] Understand the change type (new content, update, fix)
- [ ] Check for related documentation that may need updates

### 2. Set Up Review Environment

- [ ] Pull the branch locally
- [ ] Build documentation site: `npm run docs:dev` (if applicable)
- [ ] Have style guide and checklist open
- [ ] Prepare feedback template

### 3. Determine Review Level

Based on content type and risk, select appropriate review level.

---

## Level 1: Basic Review

**Time Estimate:** 15 minutes
**For:** Minor updates, typo fixes, formatting changes

### Content Accuracy

- [ ] **Spelling and grammar** correct
- [ ] **Technical terminology** accurate
- [ ] **Links functional** (no broken links)
- [ ] **Code examples** syntactically correct

**Quick Test:**
```bash
# Check for broken internal links
grep -r "\[.*\](.*\.md)" docs/ | while read line; do
  # Manual verification or use link checker
done

# Spell check
aspell check file.md
```

### Formatting

- [ ] **Markdown syntax** correct
- [ ] **Headings** properly formatted (hierarchy)
- [ ] **Code blocks** have language tags
- [ ] **Lists** formatted consistently

### Frontmatter

- [ ] **Required fields** present (title, description, audience, last_updated)
- [ ] **Metadata** accurate
- [ ] **Tags** relevant

**Example:**
```yaml
---
title: "Workflow Creation Guide"
description: "Streamline agent orchestration by establishing scalable workflows"
audience: [developer]
last_updated: "2025-10-14"
tags: [workflows, orchestration, guide]
---
```

### Brand Alignment

- [ ] **Tone** aligns with Brookside BI guidelines (professional but approachable)
- [ ] **Core language patterns** used where appropriate
- [ ] **No jargon** without explanation

---

## Level 2: Standard Review

**Time Estimate:** 30 minutes
**For:** New guides, tutorials, significant updates

*Includes all Level 1 checks, plus:*

### Content Quality

#### Structure

- [ ] **Clear introduction** establishing context and value
- [ ] **Logical flow** through sections
- [ ] **One idea per paragraph**
- [ ] **Appropriate headings** (descriptive, not generic)
- [ ] **Conclusion or next steps** provided

#### Clarity

- [ ] **Active voice** used (80%+ of sentences)
- [ ] **Present tense** consistent
- [ ] **Second person** ("you") for instructions
- [ ] **Sentences average 15-20 words**
- [ ] **Paragraphs are 3-7 sentences**

**Test:**
```bash
# Check readability score
readability-cli file.md
# Target: Flesch-Kincaid Reading Ease 60+
```

#### Completeness

- [ ] **Prerequisites** clearly listed
- [ ] **All steps** present and detailed
- [ ] **Expected outcomes** described
- [ ] **Validation steps** included
- [ ] **Troubleshooting section** for common issues

### Technical Accuracy

#### Code Examples

- [ ] **Code compiles/runs** without errors
- [ ] **Examples tested** in appropriate environment
- [ ] **Complete examples** (not partial snippets requiring guessing)
- [ ] **Comments explain business value**, not just mechanics
- [ ] **Placeholders clearly marked** (`{placeholder}`)

**Test:**
```bash
# Extract and test code blocks
cat file.md | grep -A 20 "^```typescript" | # Run extracted code
```

#### Commands

- [ ] **Commands tested** and verified
- [ ] **Prerequisites documented** (tool versions, permissions)
- [ ] **Expected output** shown
- [ ] **Error scenarios** addressed

### Visual Elements

#### Images

- [ ] **Alt text descriptive** (not just filename)
- [ ] **Images optimized** (<200KB, WebP preferred)
- [ ] **Images relevant** and add value
- [ ] **Captions provided** where needed

#### Diagrams

- [ ] **Diagrams follow Mermaid standards** (if applicable)
- [ ] **Colors accessible** (sufficient contrast)
- [ ] **Legend provided** for complex diagrams
- [ ] **Diagrams render correctly** in both light/dark mode

### Accessibility

- [ ] **Heading hierarchy logical** (no skipped levels)
- [ ] **Link text descriptive** (no "click here")
- [ ] **Color not sole differentiator**
- [ ] **Tables have headers**

**Quick Test:**
- View in grayscale - still understandable?
- Tab through interactive elements - logical order?

### Cross-References

- [ ] **Internal links correct** and relative
- [ ] **Related docs linked** appropriately
- [ ] **No dead links** (404 errors)
- [ ] **External links valid** and current

---

## Level 3: Deep Review

**Time Estimate:** 60 minutes
**For:** API documentation, architecture docs, critical guides

*Includes all Level 1 and Level 2 checks, plus:*

### Content Depth

#### Comprehensiveness

- [ ] **All use cases covered**
- [ ] **Edge cases documented**
- [ ] **Performance implications** discussed
- [ ] **Security considerations** addressed
- [ ] **Scalability factors** mentioned

#### Technical Accuracy (Advanced)

- [ ] **Architecture diagrams validated** with engineering team
- [ ] **API contracts match implementation** (OpenAPI spec)
- [ ] **Code examples align with latest version**
- [ ] **Performance metrics current** and verifiable
- [ ] **Security guidance compliant** with best practices

**Verification:**
```bash
# Validate OpenAPI spec matches documentation
swagger-cli validate api/specs/openapi.yaml

# Check API endpoint examples match spec
diff <(jq '.paths' api/specs/openapi.yaml) <(grep -A 5 "POST /" docs/api/reference.md)
```

#### Example Quality

- [ ] **Examples production-ready** (not toy examples)
- [ ] **Error handling included** in examples
- [ ] **Best practices demonstrated**
- [ ] **Anti-patterns avoided**

### Consistency

#### Terminology

- [ ] **Consistent term usage** throughout
- [ ] **Terms match glossary** (if applicable)
- [ ] **Acronyms spelled out on first use**
- [ ] **Product names capitalized correctly**

**Check:**
```bash
# Find inconsistent term usage
grep -i "orchestrator\|orchestration engine\|workflow coordinator" docs/file.md
# Should use consistent term
```

#### Cross-Document Consistency

- [ ] **Related docs updated** to reflect changes
- [ ] **Linked docs consistent** in terminology
- [ ] **Version information aligned** across docs

### SEO and Metadata

- [ ] **Title optimized** for search (50-60 chars)
- [ ] **Description compelling** (150-160 chars)
- [ ] **Keywords in H1** and early content
- [ ] **Internal linking strategy** supports SEO
- [ ] **URL structure semantic**

### Accessibility (Advanced)

- [ ] **WCAG 2.1 AA compliant** (all criteria)
- [ ] **Screen reader tested** (sample sections)
- [ ] **Keyboard navigation verified**
- [ ] **Color contrast validated** (4.5:1 minimum)
- [ ] **Reduced motion supported** (if animations)

**Test:**
```bash
# Run automated accessibility audit
axe docs/build/file.html
```

### Maintenance Considerations

- [ ] **Update frequency noted** (in frontmatter)
- [ ] **Deprecation warnings** if applicable
- [ ] **Version information clear**
- [ ] **Changelog updated** (if applicable)
- [ ] **Ownership/contact** identified

---

## Common Issues

### Content Issues

| Issue | Impact | How to Fix |
|-------|--------|------------|
| **Missing prerequisites** | Users can't complete task | Add Prerequisites section with checklist |
| **Unclear error messages** | Frustration, support tickets | Add Troubleshooting section with symptom-solution pairs |
| **Outdated screenshots** | Confusion | Update images or remove if outdated |
| **Broken code examples** | Loss of trust | Test all code examples before publishing |
| **Passive voice overuse** | Harder to read | Rewrite in active voice: "The API validates..." vs "Validation is performed..." |
| **Missing context** | Readers don't understand why | Add "Why this matters" or "Business value" callouts |

### Technical Issues

| Issue | Impact | How to Fix |
|-------|--------|------------|
| **Incorrect API endpoint** | Failed integrations | Verify against OpenAPI spec or actual implementation |
| **Wrong version number** | Compatibility issues | Check package.json, API version headers, release notes |
| **Missing error codes** | Poor error handling | Document all error codes with descriptions |
| **Outdated dependencies** | Security risk | Verify dependency versions in package.json |

### Style Issues

| Issue | Impact | How to Fix |
|-------|--------|------------|
| **Inconsistent terminology** | Confusion | Use consistent terms (e.g., always "workflow" not "pipeline") |
| **Generic headings** | Poor scannability | Make headings descriptive ("Configure Azure AD" not "Setup") |
| **Wall of text** | Low engagement | Break into shorter paragraphs, add lists, use headings |
| **Missing code comments** | Hard to understand | Add comments explaining business value and key decisions |

---

## Reviewer Guidelines

### Providing Feedback

#### Be Constructive

**Good:**
> The introduction would be more effective if it led with the business value. Consider starting with: "This solution is designed to streamline X by Y."

**Bad:**
> This intro is weak.

#### Be Specific

**Good:**
> Line 45: Change "setup" (noun) to "set up" (verb): "Set up your environment before deploying."

**Bad:**
> Fix grammar issues.

#### Prioritize Feedback

**Use labels:**
- **[CRITICAL]** - Blocks publication (broken links, incorrect code)
- **[IMPORTANT]** - Should fix before merge (clarity, accuracy)
- **[OPTIONAL]** - Nice to have (style preference, minor improvements)

#### Suggest Solutions

**Good:**
> [IMPORTANT] This code example is missing error handling. Add a try-catch block:
> ```typescript
> try {
>   const result = await api.execute();
> } catch (error) {
>   console.error('Execution failed:', error);
> }
> ```

### Review Turnaround Time

| Priority | Target Response Time |
|----------|---------------------|
| Critical (security, breaking changes) | 4 hours |
| High (new features, major updates) | 24 hours |
| Normal (guides, tutorials) | 48 hours |
| Low (typos, formatting) | 1 week |

### Approval Criteria

**Approve if:**
- [ ] All critical issues resolved
- [ ] All important issues addressed or documented as follow-up
- [ ] Quality meets standards for review level
- [ ] Author has addressed feedback

**Request changes if:**
- [ ] Critical issues present (broken links, incorrect code)
- [ ] Content incomplete or inaccurate
- [ ] Accessibility issues found
- [ ] Brand guidelines not followed

**Comment (no approval) if:**
- [ ] Only minor/optional suggestions
- [ ] Waiting for additional information
- [ ] Need input from subject matter expert

---

## Automated Checks

Supplement manual review with automated tools:

### Pre-Commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace

  - repo: https://github.com/markdownlint/markdownlint
    hooks:
      - id: markdownlint
        args: [--config, .markdownlint.json]
```

### CI/CD Checks

```yaml
# .github/workflows/docs-lint.yml
name: Documentation Lint

on: [pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Markdown Lint
        uses: articulate/actions-markdownlint@v1

      - name: Link Checker
        uses: gaurav-nelson/github-action-markdown-link-check@v1

      - name: Spell Check
        uses: rojopolis/spellcheck-github-actions@v0
        with:
          config_path: .spellcheck.yml
```

### Manual Testing Checklist

Before approving:

```bash
# 1. Build documentation locally
npm run docs:build

# 2. Check for build errors
npm run docs:dev  # Visit http://localhost:5173

# 3. Run link checker
npx broken-link-checker http://localhost:5173

# 4. Run accessibility audit
axe http://localhost:5173/path/to/page

# 5. Spell check
aspell check --mode=markdown docs/file.md
```

---

## Review Templates

### Level 1 Review Comment Template

```markdown
## Level 1 Review Complete

**Status:** ✅ Approved / ⚠️ Changes Requested / 💬 Comments

### Checks Performed
- [x] Spelling and grammar
- [x] Links functional
- [x] Code syntax correct
- [x] Formatting consistent
- [x] Frontmatter complete

### Issues Found
[CRITICAL]
- None

[IMPORTANT]
- Line 23: Fix typo "recieve" → "receive"

[OPTIONAL]
- Consider adding example for edge case X

### Next Steps
- [ ] Author: Address IMPORTANT issues
- [ ] Reviewer: Re-review after fixes
```

### Level 3 Review Comment Template

```markdown
## Level 3 Deep Review Complete

**Status:** ✅ Approved / ⚠️ Changes Requested / 💬 Comments

### Content Quality
- [x] Structure logical and complete
- [x] Technical accuracy verified
- [x] Examples tested and working
- [ ] Security considerations documented ⚠️

### Accessibility
- [x] WCAG 2.1 AA compliant
- [x] Screen reader tested (sample)
- [x] Keyboard navigation verified
- [x] Color contrast validated (4.5:1)

### Issues Found

#### CRITICAL
- None

#### IMPORTANT
1. **Line 156:** API example missing authentication header
   ```diff
   + Authorization: Bearer {token}
   ```

2. **Security Section:** Add note about token rotation (required for compliance)

#### OPTIONAL
1. Consider adding performance benchmarks table
2. Expand troubleshooting section with more common errors

### Testing Performed
- [x] Code examples run successfully
- [x] API endpoints validated against OpenAPI spec
- [x] Links checked (0 broken)
- [x] Accessibility audit (axe): 0 violations
- [x] Readability score: 65 (target: 60+) ✅

### Recommendation
**Changes Requested** - Address 2 IMPORTANT issues before merge.

Estimated fix time: 15 minutes
```

---

## Additional Resources

- [Documentation Design System](./DOCUMENTATION-DESIGN-SYSTEM.md)
- [Technical Writing Style Guide](./TECHNICAL-WRITING-STYLE-GUIDE.md)
- [Accessibility Checklist](./ACCESSIBILITY-CHECKLIST.md)
- [Content Templates](./templates/)

---

## Feedback

Improve this checklist:
- **Issues:** [GitHub Issues](https://github.com/Brookside-Proving-Grounds/Project-Ascension/issues)
- **Suggestions:** [GitHub Discussions](https://github.com/Brookside-Proving-Grounds/Project-Ascension/discussions)
- **Email:** Consultations@BrooksideBI.com

---

**Maintained by:** Documentation Team | **Last Updated:** 2025-10-14 | **Version:** 2.0
