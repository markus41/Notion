---
title: Documentation CI/CD System
description: Complete technical documentation for the CI/CD automation system that ensures documentation quality through automated checks for frontmatter, links, spelling, and duplicates.
lastUpdated: 2025-10-08
---

# Documentation CI/CD System

## Overview

This document describes the comprehensive CI/CD automation system for the VitePress documentation platform. The system implements automated quality checks to ensure documentation consistency, accuracy, and maintainability.

## Architecture

### Workflow Structure

```
┌─────────────────────────────────────────────────────────────┐
│                     Git Push/PR Trigger                      │
└────────────────────────────┬────────────────────────────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
        ┌───────▼────────┐        ┌──────▼───────┐
        │  docs-lint.yml │        │docs-build.yml│
        └───────┬────────┘        └──────┬───────┘
                │                         │
    ┌───────────┼──────────────┐         │
    │           │              │         │
┌───▼────┐ ┌───▼─────┐ ┌─────▼──┐  ┌───▼────┐
│Frontma-│ │  Link   │ │ Spell  │  │VitePress
│tter    │ │ Check   │ │ Check  │  │ Build  │
│Validate│ │         │ │        │  │Validate│
└───┬────┘ └───┬─────┘ └─────┬──┘  └───┬────┘
    │          │             │          │
    └──────────┴─────────────┴──────────┘
                      │
              ┌───────▼────────┐
              │Quality Summary │
              │    Report      │
              └────────────────┘
```

## CI/CD Workflows

### 1. Documentation Linting Workflow (`.github/workflows/docs-lint.yml`)

**Purpose**: Comprehensive quality checks for documentation content.

**Triggers**:
- Push to `main` branch (when docs modified)
- Pull requests to `main` (when docs modified)
- Manual workflow dispatch

**Jobs**:

#### Job 1: Frontmatter Validation
- **Script**: `scripts/validate-frontmatter.js`
- **Checks**:
  - Required fields: `title`, `description` (recommended)
  - Field type validation (string, array, date formats)
  - Duplicate title detection across all docs
  - Title length validation (SEO: max 60 chars)
  - Description length validation (SEO: 120-160 chars)
  - Special handling for homepage and changelog
- **Exit Code**: Fails on missing required fields or invalid formats
- **Output**: JSON report (`docs-validation-report.json`)

#### Job 2: Link Checking
- **Tool**: `markdown-link-check`
- **Config**: `.markdown-link-check.json`
- **Checks**:
  - Internal links between documentation files
  - External links (with 10s timeout)
  - Broken anchors
- **Behavior**:
  - Fails on broken internal links
  - Warns on broken external links (doesn't fail - external sites can be temporarily down)
- **Features**:
  - Retry on 429 (rate limiting)
  - Custom headers for GitHub API
  - Ignores localhost, placeholders, and in-document anchors

#### Job 3: Duplicate Content Detection
- **Script**: `scripts/detect-duplicates.js`
- **Checks**:
  - Duplicate content blocks (>100 lines identical)
  - High similarity between files (>80% match)
  - Duplicate "Getting Started" sections (>70% match)
- **Algorithm**: Levenshtein distance for similarity calculation
- **Behavior**: Reports duplicates as warnings (doesn't fail build)
- **Output**: JSON report (`duplicate-content-report.json`)

#### Job 4: Spell Checking
- **Tool**: `cspell` (Code Spell Checker)
- **Config**: `.cspell.json`
- **Dictionary**: 400+ technical terms including:
  - Cloud platforms: Azure, AWS, GCP, Kubernetes, Docker
  - Frameworks: .NET, FastAPI, React, Vue, VitePress
  - Tools: Terraform, Prometheus, Grafana, SignalR
  - Agent Studio specific terms
- **Features**:
  - Ignores code blocks and inline code
  - Ignores URLs and markdown links
  - Case insensitive
  - Uses gitignore patterns
- **Exit Code**: Fails on spelling errors

#### Job 5: Documentation Summary
- **Purpose**: Aggregate results from all checks
- **Output**: GitHub Actions summary with pass/fail status table
- **Behavior**: Fails workflow if any critical check fails

### 2. Documentation Build Validation Workflow (`.github/workflows/docs-build.yml`)

**Purpose**: Validate VitePress build process and output quality.

**Triggers**:
- Push to `main` branch (when docs modified)
- Pull requests to `main` (when docs modified)
- Manual workflow dispatch

**Jobs**:

#### Job 1: VitePress Build
- **Command**: `npm run docs:build`
- **Validation**:
  - Verifies `dist` directory creation
  - Checks for `index.html` presence
  - Counts generated HTML files
  - Verifies assets directory
- **Output**: Build artifacts (retained 7 days)
- **Summary**: File counts (HTML, JS, CSS) and total size

#### Job 2: Performance Check
- **Purpose**: Bundle size analysis
- **Checks**:
  - Lists 5 largest JavaScript files
  - Lists 5 largest CSS files
  - Warns on bundles >500KB
- **Recommendations**: Suggests code splitting or lazy loading

#### Job 3: Accessibility Check
- **Purpose**: Basic HTML validation
- **Checks**:
  - Valid DOCTYPE declaration
  - Viewport meta tag
  - HTML lang attribute
- **Server**: Serves build on localhost:3000 for testing

#### Job 4: Build Summary
- **Purpose**: Aggregate build validation results
- **Behavior**: Fails if VitePress build fails

## Scripts

### 1. Frontmatter Validation (`scripts/validate-frontmatter.js`)

**Features**:
- Simple YAML frontmatter parser (handles basic cases)
- Handles arrays, strings, and special layouts
- SEO-focused validation (title/description lengths)
- Duplicate title detection across all files
- Colored console output (disabled in CI)
- JSON report generation

**Usage**:
```bash
npm run docs:frontmatter
```

**Exit Codes**:
- `0`: All validations passed
- `1`: Validation errors found

### 2. Duplicate Detection (`scripts/detect-duplicates.js`)

**Features**:
- Levenshtein distance algorithm for similarity
- Text normalization (removes code blocks, formatting)
- Multiple detection strategies:
  - Exact duplicate blocks
  - High similarity files
  - Duplicate Getting Started sections
- Configurable thresholds
- JSON report generation

**Usage**:
```bash
npm run docs:duplicates
```

**Exit Codes**:
- `0`: Always (duplicates are warnings, not errors)

## Configuration Files

### 1. Spell Checker Configuration (`.cspell.json`)

**Key Settings**:
```json
{
  "version": "0.2",
  "language": "en",
  "enableFiletypes": ["markdown"],
  "ignorePaths": ["node_modules/**", ".vitepress/**"],
  "ignoreRegExpList": [
    "/```[\\s\\S]*?```/g",  // Code blocks
    "/`[^`]+`/g",           // Inline code
    "/https?:\\/\\/[^\\s]+/g" // URLs
  ],
  "words": [...],  // 400+ technical terms
  "allowCompoundWords": true,
  "minWordLength": 3,
  "caseSensitive": false
}
```

**Adding New Terms**:
1. Add term to `words` array in `.cspell.json`
2. Keep terms alphabetically sorted
3. Include common variations (singular/plural)

### 2. Link Check Configuration (`.markdown-link-check.json`)

**Key Settings**:
```json
{
  "timeout": "10s",
  "retryOn429": true,
  "retryCount": 3,
  "ignorePatterns": [
    {"pattern": "^http://localhost"},
    {"pattern": "^#"}  // In-document anchors
  ],
  "aliveStatusCodes": [200, 201, ..., 308]
}
```

**Ignored Patterns**:
- Local development URLs (`localhost`, `127.0.0.1`)
- Placeholder URLs (`example.com`, `<your-*>`)
- In-document anchors (checked by VitePress)

## NPM Scripts

### Available Commands

```bash
# Run all documentation linting checks
npm run docs:lint

# Individual checks
npm run docs:frontmatter    # Validate frontmatter
npm run docs:links         # Check for broken links
npm run docs:spell         # Spell check
npm run docs:duplicates    # Detect duplicate content

# VitePress commands
npm run docs:dev           # Start dev server
npm run docs:build         # Build production docs
npm run docs:preview       # Preview production build
```

### Local Development Workflow

1. **Before committing**:
   ```bash
   npm run docs:lint
   ```

2. **Fix frontmatter issues**:
   - Check `docs-validation-report.json` for details
   - Add missing titles/descriptions
   - Fix duplicate titles

3. **Fix broken links**:
   - Review link check output
   - Update or remove broken links

4. **Fix spelling**:
   - Review cspell output
   - Either fix typos or add technical terms to `.cspell.json`

5. **Review duplicates**:
   - Check `duplicate-content-report.json`
   - Consider consolidating similar content

## Quality Gates

### Critical (Fail Build)
- ❌ Missing required frontmatter fields
- ❌ Broken internal links
- ❌ Spelling errors
- ❌ VitePress build failures

### Warnings (Don't Fail)
- ⚠️ Missing recommended fields (description)
- ⚠️ Long titles/descriptions (SEO)
- ⚠️ Broken external links (temporary)
- ⚠️ Duplicate content (informational)
- ⚠️ Large bundle sizes (>500KB)

## Performance Targets

### Workflow Execution Time
- **Target**: <3 minutes total
- **Actual**:
  - Frontmatter validation: ~30s
  - Link checking: ~1-2min (depends on external sites)
  - Spell checking: ~15s
  - Duplicate detection: ~30s
  - VitePress build: ~30-60s

### Optimization Strategies
- Parallel job execution
- npm cache for dependencies
- Incremental checks (only modified files)
- Timeout configurations for external checks

## GitHub Actions Summary Output

Each workflow produces a detailed summary in GitHub Actions:

### Docs Lint Summary
```markdown
# 📚 Documentation Quality Report

| Check | Status |
|-------|--------|
| Frontmatter Validation | ✅ Passed |
| Link Checking | ✅ Passed |
| Duplicate Detection | ✅ Passed |
| Spell Checking | ✅ Passed |

## ✅ All checks passed!
```

### Docs Build Summary
```markdown
# 🏗️ Documentation Build Report

| Check | Status |
|-------|--------|
| VitePress Build | ✅ Passed |
| Performance Check | ✅ Passed |
| Accessibility Check | ✅ Passed |

| Metric | Value |
|--------|-------|
| HTML Files | 45 |
| JavaScript Files | 12 |
| CSS Files | 3 |
| Total Size | 2.3MB |
```

## Troubleshooting

### Common Issues

#### Issue: Frontmatter parsing errors
**Solution**: Ensure YAML is properly formatted
```yaml
---
title: My Page Title
description: Page description here
---
```

#### Issue: Link check timeouts
**Solution**: External links may be slow/blocked. Check if URL is accessible.

#### Issue: Spell check false positives
**Solution**: Add technical terms to `.cspell.json` words array

#### Issue: VitePress build fails
**Solution**:
1. Run `npm run docs:build` locally
2. Check for syntax errors in markdown
3. Verify all internal links are valid

### Debug Locally

```bash
# Enable verbose output for link check
find docs -name '*.md' -type f | xargs markdown-link-check --config .markdown-link-check.json

# Show detailed spell check results
cspell "docs/**/*.md" --config .cspell.json --show-context --show-suggestions

# Run validation scripts directly
node scripts/validate-frontmatter.js
node scripts/detect-duplicates.js
```

## Badge Integration

Add badges to README.md:

```markdown
[![Docs Lint](https://github.com/Brookside-Proving-Grounds/Project-Ascension/actions/workflows/docs-lint.yml/badge.svg)](https://github.com/Brookside-Proving-Grounds/Project-Ascension/actions/workflows/docs-lint.yml)

[![Docs Build](https://github.com/Brookside-Proving-Grounds/Project-Ascension/actions/workflows/docs-build.yml/badge.svg)](https://github.com/Brookside-Proving-Grounds/Project-Ascension/actions/workflows/docs-build.yml)
```

## Future Enhancements

### Phase 2 (Planned)
- [ ] Automated link fixing with PR suggestions
- [ ] Content quality scoring (readability metrics)
- [ ] SEO validation (meta tags, OG tags)
- [ ] Image optimization checks
- [ ] Accessibility scoring (WCAG compliance)
- [ ] Dead code detection in examples
- [ ] API schema validation against OpenAPI specs

### Phase 3 (Future)
- [ ] AI-powered content suggestions
- [ ] Auto-generated API documentation
- [ ] Documentation version diffing
- [ ] Translation validation for i18n
- [ ] Performance budgets per page

## Related Documentation

- [VitePress Configuration](docs/.vitepress/config.ts)
- [Documentation Structure](docs/README.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Sprint 1 Tasks](docs/sprints/sprint-1-tasks.md)

## Support

For issues or questions:
- GitHub Issues: [Project-Ascension Issues](https://github.com/Brookside-Proving-Grounds/Project-Ascension/issues)
- GitHub Discussions: [Project-Ascension Discussions](https://github.com/Brookside-Proving-Grounds/Project-Ascension/discussions)

---

**Last Updated**: 2025-10-08
**Maintained By**: DevOps Team
**Status**: ✅ Production Ready
