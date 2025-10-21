---
title: Documentation Screenshot Guide
description: Establish sustainable screenshot management practices for Agent Studio documentation
---

# Documentation Screenshot Guide

This guide establishes structure and rules for maintaining high-quality documentation screenshots across Agent Studio. These practices are designed to streamline visual documentation workflows and ensure consistency at scale.

**Best for:** Teams managing comprehensive product documentation requiring professional, synchronized visual assets.

## Overview

Agent Studio maintains **120+ automated documentation screenshots** across:
- **2 Themes:** Light and Dark modes
- **3 Viewports:** Desktop (1920×1080), Tablet (768×1024), Mobile (375×667)
- **6 Categories:** Dashboard, Agents, Workflows, Traces, Settings, Errors

All screenshots are captured via **Playwright automation** to ensure visual consistency, reproducibility, and efficient maintenance.

---

## 📁 Directory Structure

```
tests/
├── e2e/
│   ├── screenshots/                    # Screenshot capture tests
│   │   └── screenshot-capture.spec.ts  # Main test suite (120+ screenshots)
│   ├── fixtures/
│   │   └── test-data.ts                # Realistic test data fixtures
│   ├── helpers/
│   │   └── screenshot-helpers.ts       # Reusable helper functions
│   ├── scripts/
│   │   └── optimize-screenshots.js     # Image optimization script
│   ├── playwright.config.ts            # Playwright configuration
│   └── package.json                    # E2E test dependencies
└── docs-screenshots/                   # Output directory
    ├── light-theme/
    │   ├── desktop/
    │   ├── tablet/
    │   └── mobile/
    └── dark-theme/
        ├── desktop/
        ├── tablet/
        └── mobile/
```

**Published Location:** Screenshots are copied to `docs/public/screenshots/` during CI/CD deployment.

---

## 🚀 Quick Start

### Local Screenshot Capture

**Prerequisites:**
```bash
# Install Playwright dependencies
cd tests/e2e
npm install
npx playwright install --with-deps chromium
```

**Capture All Screenshots:**
```bash
# Ensure webapp is running
cd webapp
npm run dev

# In separate terminal, capture screenshots
cd tests/e2e
npm run screenshots
```

**Capture Specific Variants:**
```bash
npm run screenshots:light      # Light theme only
npm run screenshots:dark       # Dark theme only
npm run screenshots:desktop    # Desktop viewport only
npm run screenshots:tablet     # Tablet viewport only
npm run screenshots:mobile     # Mobile viewport only
```

**Optimize Images:**
```bash
npm run optimize-screenshots
```

**View Playwright Report:**
```bash
npm run report
```

---

## 🎨 Screenshot Naming Convention

All screenshots follow a consistent naming pattern for efficient organization:

```
{page}-{state}-{theme}-{viewport}.webp
```

### Examples:

| Category | Example Filename | Description |
|----------|------------------|-------------|
| **Dashboard** | `dashboard-overview-light-desktop.webp` | Dashboard overview in light theme, desktop viewport |
| | `dashboard-empty-dark-mobile.webp` | Empty dashboard state in dark theme, mobile viewport |
| **Agents** | `agents-list-populated-light-tablet.webp` | Populated agent list in light theme, tablet viewport |
| | `agent-detail-dark-desktop.webp` | Agent detail view in dark theme, desktop viewport |
| **Workflows** | `workflow-sequential-example-light-desktop.webp` | Sequential workflow pattern in light theme, desktop |
| | `workflow-execution-view-dark-desktop.webp` | Workflow execution view in dark theme, desktop |
| **Traces** | `traces-list-light-desktop.webp` | Traces list in light theme, desktop viewport |
| | `trace-detail-timeline-dark-desktop.webp` | Trace timeline in dark theme, desktop viewport |
| **Settings** | `settings-profile-light-mobile.webp` | Profile settings in light theme, mobile viewport |
| **Errors** | `error-404-page-dark-desktop.webp` | 404 error page in dark theme, desktop viewport |

---

## 📸 Screenshot Categories & Coverage

### Dashboard Views (20 screenshots)
- Homepage hero section
- Dashboard overview (empty state)
- Dashboard overview (populated state)
- Stats cards
- Activity timeline

**Viewports:** All (desktop, tablet, mobile)
**Themes:** All (light, dark)

### Agent Management (25 screenshots)
- Agent list (empty state)
- Agent list (populated state)
- Agent detail view
- Agent creation form
- Agent configuration panel
- Agent execution history
- Agent performance metrics

**Viewports:** All (desktop, tablet, mobile)
**Themes:** All (light, dark)

### Workflow Builder (30 screenshots)
- Workflow canvas (empty state)
- Sequential workflow example
- Parallel workflow example
- Dynamic workflow example
- Workflow node configuration
- Workflow execution view
- Workflow history
- Workflow templates

**Viewports:** Desktop, Tablet (mobile excluded for complex canvas views)
**Themes:** All (light, dark)

### Traces & Observability (20 screenshots)
- Traces list view
- Trace detail with timeline
- Span details panel
- Distributed tracing visualization
- Metrics dashboard
- Log viewer

**Viewports:** All (desktop, tablet, mobile)
**Themes:** All (light, dark)

### Settings & Configuration (15 screenshots)
- User profile settings
- Team management
- API keys management
- Integration settings
- Notification preferences

**Viewports:** All (desktop, tablet, mobile)
**Themes:** All (light, dark)

### Error States (10 screenshots)
- 404 page
- 500 error page
- Failed workflow execution
- Authentication error
- Validation errors

**Viewports:** Desktop (errors typically shown on larger screens)
**Themes:** All (light, dark)

---

## 🔧 Technical Implementation

### Helper Functions

The `screenshot-helpers.ts` module provides reusable utilities:

```typescript
// Capture screenshot with automatic theme/viewport configuration
await captureScreenshot(page, 'dashboard-overview', {
  theme: 'dark',
  viewport: 'desktop',
  waitFor: '[data-testid="dashboard-loaded"]',
  fullPage: true,
  quality: 85
});

// Capture all theme/viewport variants in one call
await captureAllVariants(page, 'agent-detail', {
  waitFor: '[data-testid="agent-header"]',
  fullPage: true
});

// Set theme explicitly
await setTheme(page, 'dark');

// Set viewport explicitly
await setViewport(page, 'tablet');

// Wait for images to load
await waitForImages(page);

// Disable animations for consistency
await disableAnimations(page);

// Scroll element into view
await scrollToElement(page, '[data-testid="footer"]');

// Hide sensitive data
await hideElements(page, ['[data-testid="user-email"]']);
```

### Test Data Fixtures

Realistic test data is provided via `test-data.ts`:

```typescript
// Seed complete test data set
await seedAllTestData(page);

// Seed specific scenario
await seedScenario(page, 'complex');  // Options: empty, basic, complex, errors, high-volume, multi-tenant

// Seed individual data types
await seedAgents(page);
await seedWorkflows(page);
await seedTraces(page);

// Clear all test data
await clearTestData(page);
```

**Available Scenarios:**
- `empty` - Empty application state
- `basic` - 3 agents, 2 workflows
- `complex` - Full dataset (6 agents, 6 workflows, 3 traces)
- `errors` - Error states (failed workflows, agent errors)
- `high-volume` - Simulated high-volume usage
- `multi-tenant` - Multi-department environment

---

## 🎯 Quality Standards

### File Size Requirements

✅ **Target:** <200KB per screenshot
✅ **Format:** WebP with 85% quality
✅ **Retina Variants:** @2x versions generated automatically

The optimization script enforces these standards:

```bash
npm run optimize-screenshots
```

**Optimization Features:**
- Converts JPEG to WebP
- Compresses existing WebP files
- Generates @2x retina variants
- Reports compression statistics
- Validates size compliance

### Visual Consistency

✅ **Animations Disabled:** All animations/transitions suppressed for consistent capture
✅ **Network Idle:** Waits for all API calls to complete
✅ **Images Loaded:** Ensures all images fully rendered
✅ **Stabilization Wait:** 1-second delay after page ready
✅ **Color Scheme:** Enforced via `prefers-color-scheme` media query

### Content Quality

✅ **Realistic Data:** Business-relevant agent names, workflow descriptions
✅ **No Test Data:** Avoid "Test User 1", "Test Agent 1" placeholders
✅ **Sensitive Data Hidden:** Masked API keys, email addresses, tokens
✅ **Alt Text Required:** Accessibility descriptions in documentation
✅ **Proper Context:** Screenshots show meaningful business scenarios

---

## 🤖 Automated CI/CD Workflow

Screenshots are automatically updated via GitHub Actions on every release.

### Trigger Events

**Automatic:** Triggers on release publication
```bash
# When release is published via GitHub UI
# Workflow: .github/workflows/update-screenshots.yml
```

**Manual:** Workflow dispatch with options
```bash
# GitHub Actions UI:
# Actions → Update Documentation Screenshots → Run workflow
#
# Options:
# - Theme: all, light, dark
# - Viewport: all, desktop, tablet, mobile
# - Commit: true/false
```

### Workflow Steps

1. **Build Application** - Compile webapp for production
2. **Start Server** - Launch preview server on port 4173
3. **Install Playwright** - Install Chromium browser
4. **Capture Screenshots** - Run Playwright test suite
5. **Optimize Images** - Compress to WebP <200KB
6. **Generate Report** - Statistics and coverage summary
7. **Validate Quality** - Check file sizes and coverage
8. **Commit Changes** - Push to `docs/public/screenshots/`
9. **Create PR** (releases only) - Automated pull request

### Validation Checks

✅ **Size Validation:** All screenshots <200KB
✅ **Coverage Validation:** Minimum 120 screenshots
✅ **Viewport Coverage:** All theme/viewport combinations present
✅ **Accessibility Validation:** Alt text present in docs

---

## 📝 Documentation Integration

### VitePress Markdown Integration

**Standard Screenshot:**
```markdown
![Dashboard Overview](./screenshots/dashboard-overview-light-desktop.webp)
```

**Responsive Screenshot with Theme Variants:**
```markdown
<!-- Light mode -->
<img src="./screenshots/dashboard-overview-light-desktop.webp"
     alt="Dashboard Overview"
     class="light-mode-only" />

<!-- Dark mode -->
<img src="./screenshots/dashboard-overview-dark-desktop.webp"
     alt="Dashboard Overview"
     class="dark-mode-only" />
```

**Multi-Viewport Tabs:**
```markdown
::: tabs
== Desktop
![Desktop View](./screenshots/agents-list-light-desktop.webp)

== Tablet
![Tablet View](./screenshots/agents-list-light-tablet.webp)

== Mobile
![Mobile View](./screenshots/agents-list-light-mobile.webp)
:::
```

**Retina-Optimized Images:**
```html
<img src="./screenshots/dashboard-overview-light-desktop.webp"
     srcset="./screenshots/dashboard-overview-light-desktop@2x.webp 2x"
     alt="Dashboard Overview"
     loading="lazy" />
```

### Accessibility Best Practices

Always provide descriptive alt text:

```markdown
<!-- ❌ Poor alt text -->
![Screenshot](./screenshots/dashboard.webp)

<!-- ✅ Descriptive alt text -->
![Agent Studio dashboard showing workflow execution metrics, active agents panel, and recent activity timeline](./screenshots/dashboard-overview-light-desktop.webp)
```

---

## 🔄 Maintenance Workflow

### Updating Screenshots After UI Changes

1. **Make UI Changes** - Update React components
2. **Local Testing** - Verify changes in dev environment
3. **Run Screenshot Tests** - Capture updated screenshots locally
   ```bash
   cd tests/e2e
   npm run screenshots
   ```
4. **Review Changes** - Compare before/after using Playwright UI mode
   ```bash
   npm run test:ui
   ```
5. **Optimize Images** - Compress screenshots
   ```bash
   npm run optimize-screenshots
   ```
6. **Commit Changes** - Include screenshots in PR
   ```bash
   git add tests/docs-screenshots/
   git commit -m "docs: Update screenshots for new UI design"
   ```

### Handling Screenshot Failures

**Common Issues:**

| Issue | Cause | Solution |
|-------|-------|----------|
| **Element not found** | Test selector changed | Update `data-testid` attributes in components |
| **Timeout waiting for element** | Slow API response | Increase `waitFor` timeout or mock API responses |
| **Flaky screenshots** | Animation timing | Ensure `disableAnimations` is enabled |
| **Incorrect theme** | Theme toggle not working | Verify theme CSS classes applied correctly |
| **Empty state not showing** | Test data not cleared | Call `clearTestData(page)` before test |

**Debugging Steps:**

1. **Run in headed mode** to see browser:
   ```bash
   npm run test:headed
   ```

2. **Use Playwright UI mode** for interactive debugging:
   ```bash
   npm run test:ui
   ```

3. **Check Playwright trace** for failed tests:
   ```bash
   npm run report
   # Click on failed test → View trace
   ```

4. **Add debug waits** in test:
   ```typescript
   await page.pause(); // Interactive debugger
   ```

---

## 📊 Screenshot Statistics & Monitoring

### Check Current Coverage

```bash
cd tests/e2e
npm run screenshots
# Output displays statistics:
# 📊 Screenshot Capture Statistics:
#    Total Screenshots: 126
#    Light Theme: 63
#    Dark Theme: 63
#    Desktop: 80
#    Tablet: 30
#    Mobile: 16
#    Total Size: 18MB
```

### Programmatic Stats Access

```typescript
import { getScreenshotStats } from './helpers/screenshot-helpers';

const stats = getScreenshotStats();
console.log(`Total: ${stats.totalCount}`);
console.log(`Average size: ${stats.totalSizeKB / stats.totalCount}KB`);
```

---

## 🚨 Troubleshooting

### Webapp Not Starting

```bash
# Check if port 5173 is in use
lsof -i :5173

# Kill existing process
kill -9 <PID>

# Restart webapp
cd webapp
npm run dev
```

### Playwright Browser Issues

```bash
# Reinstall browsers
cd tests/e2e
npx playwright install --with-deps chromium

# Clear cache
rm -rf ~/.cache/ms-playwright
npx playwright install chromium
```

### Screenshot Optimization Failures

```bash
# Check sharp installation
npm ls sharp

# Reinstall sharp with platform binaries
npm rebuild sharp

# Manual optimization
cd tests/e2e
node scripts/optimize-screenshots.js
```

### CI/CD Workflow Failures

**Check GitHub Actions logs:**
1. Navigate to **Actions** tab
2. Select **Update Documentation Screenshots** workflow
3. Review failed step logs

**Common CI Issues:**
- **Webapp build failure** - Check `npm run build` locally
- **Screenshot timeout** - Increase timeout in `playwright.config.ts`
- **Storage limit exceeded** - Reduce screenshot count or increase compression

---

## 🎓 Best Practices

### DO ✅

- **Use data-testid attributes** for stable selectors
- **Seed realistic test data** that demonstrates business value
- **Disable animations** for visual consistency
- **Wait for network idle** before capturing
- **Optimize images** before committing
- **Include alt text** in documentation
- **Test locally** before pushing to CI/CD
- **Review screenshots** in Playwright UI mode

### DON'T ❌

- **Use CSS class selectors** (subject to change)
- **Include real user data** or credentials
- **Commit unoptimized images** (>200KB)
- **Skip viewport variants** (breaks responsive docs)
- **Capture during animations** (causes inconsistency)
- **Use generic filenames** (hard to organize)
- **Forget to mask sensitive data**

---

## 📚 Additional Resources

### Documentation
- [Playwright Documentation](https://playwright.dev)
- [VitePress Image Handling](https://vitepress.dev/guide/asset-handling)
- [WebP Image Format](https://developers.google.com/speed/webp)

### Internal Resources
- `tests/e2e/README.md` - E2E testing guide
- `TESTING.md` - Comprehensive testing strategy
- `ARCHITECTURE.md` - System architecture overview

### Support
- **Technical Issues:** Open GitHub issue with `documentation` label
- **Questions:** Contact team via `#documentation` Slack channel
- **Consultations:** Consultations@BrooksideBI.com

---

## 🔐 Security Considerations

### Sensitive Data Handling

Always mask sensitive information in screenshots:

```typescript
await captureScreenshot(page, 'settings-api-keys', {
  mask: [
    '[data-testid="api-key-value"]',
    '[data-testid="user-email"]',
    '[data-testid="secret-token"]'
  ]
});
```

**Types of Data to Mask:**
- API keys and tokens
- Email addresses
- Phone numbers
- Account IDs
- IP addresses
- Database connection strings

### Review Before Publishing

Before committing screenshots:
1. ✅ Check for visible credentials
2. ✅ Verify no personal information exposed
3. ✅ Confirm no internal URLs/IPs visible
4. ✅ Ensure test data used (not production)

---

## 📈 Future Enhancements

**Planned Improvements:**
- [ ] Visual regression testing (Percy/Chromatic integration)
- [ ] Screenshot diff reporting in PRs
- [ ] Automatic stale screenshot detection
- [ ] Multi-language screenshot variants
- [ ] Video capture for complex workflows
- [ ] Performance metrics overlay on screenshots

**Contribution:** Submit enhancement proposals via GitHub Discussions.

---

**Last Updated:** 2025-10-14
**Maintained By:** Brookside BI Documentation Team
**Version:** 1.0.0

---

*This guide establishes sustainable screenshot management practices that support scalable, professional documentation workflows across Agent Studio. For questions or support, contact Consultations@BrooksideBI.com.*
