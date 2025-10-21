---
title: Documentation Automation Scripts
description: Technical reference for validation scripts including frontmatter validation, duplicate detection, spell checking configuration, and CI/CD integration details.
lastUpdated: 2025-10-08
---

# Documentation Automation Scripts

This directory contains scripts for automated documentation quality assurance.

## Scripts Overview

### 1. `validate-frontmatter.js`
Validates YAML frontmatter in all markdown documentation files.

**Purpose**:
- Ensure all docs have required metadata
- Validate field types and formats
- Detect duplicate titles
- Check SEO-friendly title/description lengths

**Usage**:
```bash
npm run docs:frontmatter
```

**What it checks**:
- ✅ Required field: `title` (string, non-empty)
- ✅ Recommended field: `description` (string, 120-160 chars for SEO)
- ✅ Optional field: `lastUpdated` (date, YYYY-MM-DD format)
- ✅ Optional field: `contributors` (array or string)
- ✅ No duplicate titles across all documentation
- ✅ SEO-friendly lengths (title ≤60 chars, description 120-160 chars)

**Special cases** (no frontmatter required):
- `index.md` with `layout: home`
- `CHANGELOG.md`

**Output**:
- Console: Colored output with errors and warnings
- File: `docs-validation-report.json` (detailed JSON report)

**Exit codes**:
- `0`: All validations passed
- `1`: Validation errors found

---

### 2. `detect-duplicates.js`
Detects duplicate and highly similar content across documentation.

**Purpose**:
- Find exact duplicate content blocks
- Identify files with high similarity
- Detect duplicate "Getting Started" sections
- Recommend consolidation opportunities

**Usage**:
```bash
npm run docs:duplicates
```

**What it checks**:
- 📋 Duplicate content blocks (>100 lines identical)
- 🔍 Files with high similarity (>80% match using Levenshtein distance)
- 🚀 Duplicate "Getting Started" sections (>70% similarity)

**Algorithm**:
- Normalizes text (removes code blocks, formatting, whitespace)
- Calculates Levenshtein distance for similarity
- Configurable thresholds for different check types

**Output**:
- Console: Colored output with duplicate findings
- File: `duplicate-content-report.json` (detailed JSON report)

**Exit codes**:
- `0`: Always exits successfully (duplicates are warnings, not errors)

---

## Configuration Files

### `.cspell.json` (Spell Checker)
Custom dictionary with 400+ technical terms.

**Includes**:
- Cloud platforms: Azure, AWS, GCP, Kubernetes, Docker
- Languages: TypeScript, JavaScript, Python, C#, .NET
- Frameworks: VitePress, React, Vue, FastAPI, SignalR
- Tools: Terraform, Prometheus, Grafana, OpenTelemetry
- Agent Studio specific terminology

**Usage**:
```bash
npm run docs:spell
```

**Adding new terms**:
1. Edit `.cspell.json`
2. Add term to `words` array
3. Keep alphabetically sorted

---

### `.markdown-link-check.json` (Link Checker)
Configuration for markdown link validation.

**Features**:
- ✅ Timeout: 10s per link
- ✅ Retry on 429 (rate limiting): 3 attempts
- ✅ Custom headers for GitHub API
- ✅ Ignores: localhost, placeholders, in-document anchors

**Usage**:
```bash
npm run docs:links
```

**Ignored patterns**:
- Local URLs: `localhost`, `127.0.0.1`
- Placeholders: `example.com`, `<your-*>`, `{...}`
- Anchors: `#section-name` (checked by VitePress)

---

## NPM Scripts

All scripts can be run via npm:

```bash
# Run all documentation checks
npm run docs:lint

# Individual checks
npm run docs:frontmatter    # Validate frontmatter
npm run docs:links         # Check broken links
npm run docs:spell         # Spell check
npm run docs:duplicates    # Detect duplicates

# VitePress commands
npm run docs:dev           # Start dev server
npm run docs:build         # Build production docs
npm run docs:preview       # Preview production build
```

---

## Local Development Workflow

### Before committing documentation:

```bash
# 1. Run all checks
npm run docs:lint

# 2. Fix any errors
#    - Frontmatter: Check docs-validation-report.json
#    - Links: Update broken links
#    - Spelling: Fix typos or add to .cspell.json
#    - Duplicates: Review duplicate-content-report.json

# 3. Test VitePress build
npm run docs:build

# 4. Preview locally
npm run docs:preview
```

---

## CI/CD Integration

These scripts are integrated into GitHub Actions workflows:

### `.github/workflows/docs-lint.yml`
Runs on: Push to main, PRs to main

**Jobs**:
1. Frontmatter Validation (`validate-frontmatter.js`)
2. Link Checking (`markdown-link-check`)
3. Duplicate Detection (`detect-duplicates.js`)
4. Spell Checking (`cspell`)
5. Summary Report

**Fails on**:
- Missing frontmatter
- Broken internal links
- Spelling errors

**Warns on**:
- Missing descriptions
- Long titles/descriptions
- Duplicate content

### `.github/workflows/docs-build.yml`
Runs on: Push to main, PRs to main

**Jobs**:
1. VitePress Build
2. Performance Check (bundle size)
3. Accessibility Check (HTML validation)
4. Build Summary

**Fails on**:
- Build errors
- Missing HTML files

**Warns on**:
- Large bundles (>500KB)
- Missing meta tags

---

## Troubleshooting

### Script fails with "Cannot find module"
```bash
# Install dependencies
npm ci
```

### "Permission denied" on scripts
```bash
# Make scripts executable (Unix/Mac)
chmod +x scripts/*.js
```

### Frontmatter validation false positives
- Check YAML syntax (proper indentation)
- Ensure frontmatter is wrapped in `---`
- Quote strings with special characters

### Link check timeouts
- External sites may be slow
- Increase timeout in `.markdown-link-check.json`
- Check if site is actually down

### Spell check false positives
- Add technical term to `.cspell.json` words array
- Don't use cspell ignore comments
- Keep dictionary alphabetically sorted

---

## Development

### Adding a new validation script

1. **Create script** in `scripts/`:
```javascript
#!/usr/bin/env node
import { readFileSync } from 'fs';

// Your validation logic
function validate() {
  // ...
}

// Main execution
function main() {
  try {
    validate();
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

main();
```

2. **Add npm script** to `package.json`:
```json
{
  "scripts": {
    "docs:yourcheck": "node scripts/your-check.js"
  }
}
```

3. **Update CI workflow** (`.github/workflows/docs-lint.yml`):
```yaml
your-check:
  name: Your Check
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: '20'
    - run: npm ci
    - run: npm run docs:yourcheck
```

4. **Document it** in this README

---

## Performance

### Execution times (approximate):
- Frontmatter validation: ~30s (44 files)
- Link checking: ~1-2min (depends on external sites)
- Spell checking: ~15s
- Duplicate detection: ~30s
- VitePress build: ~30-60s

### Optimization tips:
- Use `--quiet` flag for less verbose output
- Run checks in parallel where possible
- Cache dependencies in CI
- Use incremental checking for large repos

---

## Resources

- [VitePress Documentation](https://vitepress.dev/)
- [cspell Documentation](https://cspell.org/)
- [markdown-link-check](https://github.com/tcort/markdown-link-check)
- [Levenshtein Distance Algorithm](https://en.wikipedia.org/wiki/Levenshtein_distance)

---

## Support

For issues or questions:
- Check [CI/CD Documentation](../docs/CI-CD-DOCUMENTATION.md)
- See [Quick Guide](../.github/DOCS-QUALITY-GUIDE.md)
- Open [GitHub Issue](https://github.com/Brookside-Proving-Grounds/Project-Ascension/issues)

---

**Maintained by**: DevOps Team
**Last Updated**: 2025-10-08
**Status**: ✅ Production Ready
