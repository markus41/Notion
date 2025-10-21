# Screenshot Guidelines for RealmWorks

This document provides guidelines for capturing, editing, and managing screenshots for RealmWorks documentation.

---

## 📸 When to Capture Screenshots

### Required

- ✅ **After feature completion** (before merging PR)
- ✅ **UI redesigns** (major visual changes)
- ✅ **New automation workflows** (show output in action)
- ✅ **Phase milestones** (document completed phase features)
- ✅ **Visual proof sections** (README collapsibles)

### Optional

- 🔹 **Minor UI tweaks** (button repositioning, color changes)
- 🔹 **Non-visual bug fixes** (backend logic, API changes)
- 🔹 **Documentation updates** (text changes)

---

## 🎯 Screenshot Specifications

### Resolution
- **Minimum**: 1280x720px (720p, 16:9 ratio)
- **Recommended**: 1920x1080px (1080p, 16:9 ratio)
- **Maximum**: 2560x1440px (1440p, 16:9 ratio)

### Format
- **Primary**: PNG (lossless compression)
- **Alternative**: WebP (smaller file size, 80-90% quality)
- **Avoid**: JPEG (lossy compression, poor for UI screenshots)

### File Size
- **Target**: <500KB
- **Maximum**: 1MB
- **Compression**: Use [TinyPNG](https://tinypng.com) or [ImageOptim](https://imageoptim.com)

### Naming Convention
```
XX-feature-name-context.png

XX:           Two-digit sequence (01, 02, 03...)
feature-name: Kebab-case feature identifier
context:      Brief context (comment, dashboard, alert, etc.)
```

**Examples**:
- `01-xp-calculator-comment.png` - XP breakdown on merged PR
- `02-issue-router-assignment.png` - Auto-assigned issue with class label
- `03-codeql-security-comment.png` - CodeQL findings on PR
- `04-sonarcloud-quality-gate.png` - SonarCloud status check
- `05-dependabot-security-alert.png` - Dependabot vulnerability PR

---

## 📁 Storage Location

```
.github/assets/screenshots/
├── phase01/
│   ├── 01-community-health-files.png
│   ├── 02-codeowners-assignment.png
│   └── 03-dependabot-config.png
├── phase02/
│   ├── 01-xp-calculator-comment.png
│   ├── 02-issue-router-assignment.png
│   ├── 03-codeql-security-comment.png
│   ├── 04-sonarcloud-quality-gate.png
│   ├── 05-dependabot-security-alert.png
│   └── 06-release-drafter-changelog.png
├── phase03/
│   ├── 01-readme-visual-banner.png
│   ├── 02-architecture-diagrams.png
│   └── 03-visual-proof-collapsibles.png
└── README.md  # Screenshot catalog
```

---

## ✂️ Capturing Screenshots

### Tools

**macOS**:
- **Cmd+Shift+4**: Select area to capture
- **Cmd+Shift+5**: Screenshot menu with options
- **Preview**: Built-in editor for annotations

**Windows**:
- **Win+Shift+S**: Snipping Tool (select area)
- **Win+PrtScn**: Full screen screenshot
- **Snip & Sketch**: Built-in editor

**Linux**:
- **Flameshot**: Feature-rich screenshot tool
- **Gnome Screenshot**: Built-in GNOME tool
- **Spectacle**: KDE screenshot utility

**Browser Extensions**:
- **Awesome Screenshot**: Full-page capture, annotations
- **Nimbus Screenshot**: Screen capture and recording
- **GoFullPage**: Full-page screenshot (Chrome/Firefox)

### Best Practices

**Framing**:
- ✅ Include context (URL bar, window title)
- ✅ Center important content
- ✅ Leave 20-40px padding around edges
- ❌ Crop too tightly (loses context)
- ❌ Include irrelevant UI elements (bookmarks, extensions)

**Content**:
- ✅ Use realistic data (not "foo", "bar", "test123")
- ✅ Show complete workflows (start to finish)
- ✅ Highlight key information (annotations)
- ❌ Include sensitive data (API keys, emails, passwords)
- ❌ Show error states without explanation

**Timing**:
- ✅ Wait for animations to complete
- ✅ Ensure full content load
- ✅ Show final state (after action completes)
- ❌ Capture mid-animation
- ❌ Show loading spinners (unless relevant)

---

## 🎨 Editing Screenshots

### Annotations

Use annotations **sparingly** and **only when necessary** to highlight specific elements.

**When to Annotate**:
- 🎯 Pointing out specific UI elements in complex interfaces
- 🎯 Highlighting before/after differences
- 🎯 Drawing attention to errors or warnings
- 🎯 Showing data flow in multi-step processes

**When NOT to Annotate**:
- ⛔ Simple, obvious UI elements
- ⛔ Screenshots with clear focus
- ⛔ Overcrowding with too many annotations

### Annotation Types

**Arrows**:
- **Use**: Show direction of flow or draw attention
- **Color**: RPG palette (Blue `#4169E1` for info, Red `#FF0000` for errors)
- **Style**: Solid line, 3-5px width, rounded arrow head

**Boxes/Rectangles**:
- **Use**: Highlight specific areas
- **Color**: Transparent fill with colored border (3px)
- **Style**: Rounded corners (5px radius)

**Text Callouts**:
- **Use**: Explain non-obvious elements
- **Color**: White text on semi-transparent background
- **Font**: System font, 14-16px, bold

**Blur/Pixelate**:
- **Use**: Hide sensitive information (API keys, emails, passwords)
- **Tool**: Gaussian blur (radius 10-20px) or pixelate
- **Coverage**: Blur entire sensitive area (not just part)

### Annotation Colors

**Information** (Blue):
- Color: `#4169E1` (Knight's Steel)
- Use: General highlights, feature callouts

**Success** (Green):
- Color: `#1eff00` (Uncommon/Passing)
- Use: Successful operations, correct examples

**Warning** (Orange):
- Color: `#FFA500`
- Use: Warnings, important notes

**Error** (Red):
- Color: `#FF0000`
- Use: Errors, critical issues, incorrect examples

---

## 📝 Alt Text Guidelines

Alt text describes the screenshot content for accessibility and SEO.

### Bad Examples ❌

```markdown
![Screenshot](image.png)
![Image](image.png)
![XP Calculator](image.png)
```

### Good Examples ✅

```markdown
![PR comment showing XP breakdown: 847 XP earned with detailed formula and bonus multipliers applied](01-xp-calculator-comment.png)

![GitHub issue auto-assigned to Knight of Code character class with backend and API labels](02-issue-router-assignment.png)

![CodeQL security scan results showing 3 medium severity findings with code locations highlighted](03-codeql-security-comment.png)
```

### Alt Text Structure

```
[Action/Feature] [showing/displaying] [key information]: [specific details]
```

**Components**:
1. **Action/Feature**: What the screenshot shows (PR comment, Dashboard, Alert)
2. **Showing/Displaying**: Descriptive verb
3. **Key Information**: Primary content (XP breakdown, Security scan, Assignment)
4. **Specific Details**: Exact values, counts, status (847 XP, 3 findings, Knight of Code)

### Alt Text Best Practices

**Do**:
- ✅ Describe **what the user sees**, not the technical implementation
- ✅ Include **specific values** (XP amount, number of findings, status)
- ✅ Keep to **100-150 characters** (concise but descriptive)
- ✅ Start with the **most important information**

**Don't**:
- ❌ Say "screenshot", "image", or "picture" (screen readers announce this)
- ❌ Repeat surrounding text verbatim
- ❌ Use vague terms ("nice", "good", "awesome")
- ❌ Exceed 200 characters (too verbose)

---

## 🔄 Screenshot Refresh Cadence

### When to Update

**Immediate**:
- ✅ UI redesign or major visual changes
- ✅ Feature behavior changes significantly
- ✅ Screenshot shows outdated branding/colors
- ✅ New phase implementation completes

**Quarterly**:
- 🔹 Minor UI updates accumulate
- 🔹 Data becomes stale (XP values, metrics)
- 🔹 Screenshots show old versions (badges, version numbers)

**Not Necessary**:
- ⛔ Minor text changes
- ⛔ Button repositioning (same flow)
- ⛔ Non-visual bug fixes
- ⛔ Backend logic changes

### Update Process

1. **Identify outdated screenshots**:
   ```bash
   # Find screenshots older than 90 days
   find .github/assets/screenshots -name "*.png" -mtime +90
   ```

2. **Recapture screenshot** following guidelines

3. **Compress** with TinyPNG or ImageOptim

4. **Update alt text** if content changed

5. **Replace file** (use same filename to avoid broken links)

6. **Commit** with descriptive message:
   ```bash
   git add .github/assets/screenshots/phase02/01-xp-calculator-comment.png
   git commit -m "docs(screenshots): Update XP calculator screenshot for Phase 2"
   ```

---

## ✅ Screenshot Checklist

Before adding a screenshot to documentation, verify:

- [ ] **Resolution**: 1280x720px minimum (16:9 ratio)
- [ ] **Format**: PNG or WebP
- [ ] **File Size**: <500KB (compressed)
- [ ] **Naming**: `XX-feature-name-context.png` format
- [ ] **Location**: Correct phase directory
- [ ] **Content**: Realistic data (not "test", "foo", "bar")
- [ ] **Sensitive Data**: No API keys, passwords, or private emails
- [ ] **Annotations**: Only if necessary, using RPG colors
- [ ] **Alt Text**: Descriptive (100-150 chars), specific values included
- [ ] **Context**: Includes surrounding UI for clarity

---

## 📚 Examples

### Example 1: XP Calculator Screenshot

**File**: `01-xp-calculator-comment.png`
**Location**: `.github/assets/screenshots/phase02/`
**Resolution**: 1920x1080px
**File Size**: 247 KB (compressed from 1.2 MB)

**Alt Text**:
```markdown
![Pull request comment showing XP calculation: 847 XP earned with breakdown table displaying base XP (50), complexity multiplier (5x), impact multiplier (2x), and bonuses for tests (+50%), docs (+25%), and character class match (+20%)](01-xp-calculator-comment.png)
```

**Annotations**: None (clear without annotations)

**Context**: GitHub PR comment with full XP breakdown table, leveling progress bar, and next level threshold

---

### Example 2: Issue Router Screenshot

**File**: `02-issue-router-assignment.png`
**Location**: `.github/assets/screenshots/phase02/`
**Resolution**: 1920x1080px
**File Size**: 312 KB

**Alt Text**:
```markdown
![GitHub issue auto-assigned to @markus41 with Knight of Code character class label and backend area label, including bot comment explaining assignment reason based on backend and API keywords](02-issue-router-assignment.png)
```

**Annotations**: Blue arrow pointing to character class label

**Context**: GitHub issue page showing assignee, labels, and bot comment with keyword detection explanation

---

### Example 3: CodeQL Security Screenshot

**File**: `03-codeql-security-comment.png`
**Location**: `.github/assets/screenshots/phase02/`
**Resolution**: 1920x1080px
**File Size**: 398 KB

**Alt Text**:
```markdown
![CodeQL security scan results on pull request showing 3 medium severity findings: SQL injection risk in user input handler, XSS vulnerability in template renderer, and hardcoded credential in config file, with code locations and remediation links](03-codeql-security-comment.png)
```

**Annotations**: Orange boxes highlighting severity badges, red arrows pointing to vulnerable code snippets

**Context**: GitHub PR checks tab with CodeQL results, showing findings table with severity, description, and file locations

---

## 🔧 Screenshot Optimization

### Compression Tools

**Online**:
- [TinyPNG](https://tinypng.com) - PNG/JPEG compression (lossy, high quality)
- [Squoosh](https://squoosh.app) - Image optimization with format conversion
- [Compressor.io](https://compressor.io) - Multi-format compression

**CLI**:
```bash
# ImageOptim (macOS)
imageoptim .github/assets/screenshots/**/*.png

# pngquant (cross-platform)
pngquant --quality=80-90 --ext .png --force screenshot.png

# cwebp (WebP conversion)
cwebp -q 85 screenshot.png -o screenshot.webp
```

**Automated** (GitHub Action):
```yaml
# .github/workflows/optimize-images.yml
name: Optimize Images
on:
  pull_request:
    paths:
      - '.github/assets/screenshots/**'

jobs:
  optimize:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: calibreapp/image-actions@main
        with:
          githubToken: ${{ secrets.GITHUB_TOKEN }}
          jpegQuality: '85'
          pngQuality: '85'
          webpQuality: '85'
```

### Before/After Comparison

**Before Optimization**:
- **File**: `01-xp-calculator-comment.png`
- **Size**: 1.2 MB
- **Resolution**: 1920x1080px
- **Format**: PNG (24-bit color)

**After Optimization**:
- **File**: `01-xp-calculator-comment.png`
- **Size**: 247 KB (79% reduction)
- **Resolution**: 1920x1080px (unchanged)
- **Format**: PNG (24-bit color, optimized palette)
- **Quality**: Visually identical

---

## 📖 Related Documentation

- [Documentation Standard](DOCUMENTATION_STANDARD.md) - Complete style guide
- [Visual Assets README](.github/assets/README.md) - Asset management
- [Badge Catalog](.github/BADGES.md) - Available badges
- [Phase 3 Visual Excellence](.claude/context/project-phases/phase-03-visual-excellence.md)

---

**Last Updated**: 2025-10-05
**Maintained By**: Documentation Team
**Next Review**: 2025-11-05
