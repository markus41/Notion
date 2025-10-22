# Playwright MCP Server - API Reference

**Author**: Claude Code Agent (Markdown Expert)
**Date**: October 21, 2025
**Version**: 1.0.0
**Status**: Production Ready

## Overview

Establish automated browser testing and web interaction capabilities through Playwright MCP server integration to streamline quality assurance workflows, web scraping operations, and automated UI testing. This solution is designed for teams requiring reliable browser automation with comprehensive element interaction and screenshot capabilities.

**Best for**: QA teams testing Example Builds, developers performing web scraping for research, and automated UI validation workflows.

## Table of Contents

- [Authentication Setup](#authentication-setup)
- [Browser Management](#browser-management)
- [Navigation Operations](#navigation-operations)
- [Element Interaction](#element-interaction)
- [Form Operations](#form-operations)
- [Screenshot & Snapshots](#screenshot--snapshots)
- [Testing Workflows](#testing-workflows)
- [Common Workflows](#common-workflows)
- [Error Handling](#error-handling)
- [Troubleshooting](#troubleshooting)

## Authentication Setup

### Prerequisites

- Node.js 18.0.0 or higher
- Microsoft Edge browser (recommended) or Chromium
- Claude Code installed with Playwright MCP server enabled

### Configuration

The Playwright MCP server is configured in `.claude.json`:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest", "--browser", "msedge", "--headless"]
    }
  }
}
```

**Configuration Options**:
- `--browser`: Browser engine (`msedge`, `chromium`, `firefox`, `webkit`)
- `--headless`: Run without visible browser window (default for automation)
- `--headed`: Show browser window (useful for debugging)

### Install Browser

If you encounter browser not installed errors:

```bash
# Install Playwright MCP browser
npx @playwright/mcp@latest install

# OR install specific browser
npx playwright install msedge
npx playwright install chromium
```

### Verify Connection

```bash
# Check MCP server status
claude mcp list

# Expected output:
# ✓ playwright: Connected
#   Browser: Microsoft Edge (headless)
#   Status: Ready
```

## Browser Management

### Browser Lifecycle

The Playwright MCP server manages browser instances automatically:
- Browser launches when first operation is called
- Browser stays open between operations for performance
- Browser closes when MCP server stops or on explicit close

### Close Browser

**Tool Name**: `playwright__browser_close`

**Parameters**: None

**Example**:
```typescript
{
  // No parameters required
}
```

**Use Cases**:
- Clean up after test suite completion
- Reset browser state between test runs
- Free system resources

### Resize Browser Window

**Tool Name**: `playwright__browser_resize`

**Parameters**:
- `width` (number, required): Window width in pixels
- `height` (number, required): Window height in pixels

**Example: Desktop Viewport**
```typescript
{
  "width": 1920,
  "height": 1080
}
```

**Example: Mobile Viewport**
```typescript
{
  "width": 375,
  "height": 667
}
```

**Example: Tablet Viewport**
```typescript
{
  "width": 768,
  "height": 1024
}
```

## Navigation Operations

### Navigate to URL

**Tool Name**: `playwright__browser_navigate`

**Parameters**:
- `url` (string, required): Target URL

**Example**:
```typescript
{
  "url": "https://portal.azure.com"
}
```

**Important**: Always use full URLs with protocol (`https://`)

### Navigate Back

**Tool Name**: `playwright__browser_navigate_back`

**Parameters**: None

**Example**:
```typescript
{
  // No parameters required
}
```

### Wait for Condition

**Tool Name**: `playwright__browser_wait_for`

**Parameters**:
- `text` (string, optional): Text to wait for to appear
- `textGone` (string, optional): Text to wait for to disappear
- `time` (number, optional): Time to wait in seconds

**Example: Wait for Text**
```typescript
{
  "text": "Dashboard loaded successfully"
}
```

**Example: Wait for Loading to Complete**
```typescript
{
  "textGone": "Loading..."
}
```

**Example: Wait Fixed Duration**
```typescript
{
  "time": 3  // Wait 3 seconds
}
```

## Element Interaction

### Take Snapshot

**Tool Name**: `playwright__browser_snapshot`

**Parameters**: None

**Example**:
```typescript
{
  // No parameters required
}
```

**Response**: Returns accessibility tree snapshot of current page with element references for interaction.

**Example Response**:
```
heading "Cost Dashboard" [ref: 0]
  navigation "Main menu" [ref: 1]
    link "Dashboard" [ref: 2]
    link "Reports" [ref: 3]
  main [ref: 4]
    heading "Monthly Costs" [ref: 5]
    button "Refresh Data" [ref: 6]
```

**Best for**: Identifying elements before interaction, accessibility testing, page structure analysis.

### Click Element

**Tool Name**: `playwright__browser_click`

**Parameters**:
- `element` (string, required): Human-readable element description
- `ref` (string, required): Element reference from snapshot
- `button` (string, optional): `"left"`, `"right"`, or `"middle"` (default: `"left"`)
- `doubleClick` (boolean, optional): Perform double-click
- `modifiers` (array, optional): Modifier keys (`["Alt"]`, `["Control"]`, `["Shift"]`, etc.)

**Example: Simple Click**
```typescript
{
  "element": "Refresh Data button",
  "ref": "6"
}
```

**Example: Right-Click**
```typescript
{
  "element": "Cost item in table",
  "ref": "15",
  "button": "right"
}
```

**Example: Double-Click**
```typescript
{
  "element": "Editable cell",
  "ref": "23",
  "doubleClick": true
}
```

**Example: Control+Click**
```typescript
{
  "element": "Multi-select option",
  "ref": "18",
  "modifiers": ["Control"]
}
```

### Hover Over Element

**Tool Name**: `playwright__browser_hover`

**Parameters**:
- `element` (string, required): Human-readable element description
- `ref` (string, required): Element reference from snapshot

**Example**:
```typescript
{
  "element": "Cost breakdown chart tooltip trigger",
  "ref": "12"
}
```

**Use Cases**:
- Trigger tooltips
- Activate hover menus
- Test hover states

### Drag and Drop

**Tool Name**: `playwright__browser_drag`

**Parameters**:
- `startElement` (string, required): Source element description
- `startRef` (string, required): Source element reference
- `endElement` (string, required): Target element description
- `endRef` (string, required): Target element reference

**Example**:
```typescript
{
  "startElement": "Cost category widget",
  "startRef": "8",
  "endElement": "Dashboard layout area",
  "endRef": "4"
}
```

## Form Operations

### Type Text

**Tool Name**: `playwright__browser_type`

**Parameters**:
- `element` (string, required): Element description
- `ref` (string, required): Element reference
- `text` (string, required): Text to type
- `slowly` (boolean, optional): Type one character at a time (triggers key handlers)
- `submit` (boolean, optional): Press Enter after typing

**Example: Fill Search Box**
```typescript
{
  "element": "Search input field",
  "ref": "7",
  "text": "Azure OpenAI integration",
  "submit": true
}
```

**Example: Slow Type (for Autocomplete)**
```typescript
{
  "element": "Category filter",
  "ref": "9",
  "text": "Development",
  "slowly": true
}
```

### Fill Form

**Tool Name**: `playwright__browser_fill_form`

**Parameters**:
- `fields` (array, required): Array of field objects
  - `name` (string): Human-readable field name
  - `ref` (string): Element reference
  - `type` (string): Field type (`"textbox"`, `"checkbox"`, `"radio"`, `"combobox"`, `"slider"`)
  - `value` (string): Field value

**Example: Complete Login Form**
```typescript
{
  "fields": [
    {
      "name": "Email address",
      "ref": "10",
      "type": "textbox",
      "value": "user@brooksidebi.com"
    },
    {
      "name": "Password",
      "ref": "11",
      "type": "textbox",
      "value": "secure-password"
    },
    {
      "name": "Remember me",
      "ref": "12",
      "type": "checkbox",
      "value": "true"
    }
  ]
}
```

**Example: Survey Form**
```typescript
{
  "fields": [
    {
      "name": "Product satisfaction",
      "ref": "15",
      "type": "radio",
      "value": "Very Satisfied"
    },
    {
      "name": "Department",
      "ref": "16",
      "type": "combobox",
      "value": "Engineering"
    },
    {
      "name": "Priority level",
      "ref": "17",
      "type": "slider",
      "value": "8"
    }
  ]
}
```

### Select Option

**Tool Name**: `playwright__browser_select_option`

**Parameters**:
- `element` (string, required): Element description
- `ref` (string, required): Element reference
- `values` (array, required): Option values to select

**Example: Single Select**
```typescript
{
  "element": "Category dropdown",
  "ref": "13",
  "values": ["Development"]
}
```

**Example: Multi-Select**
```typescript
{
  "element": "Technology filter",
  "ref": "14",
  "values": ["Azure", "TypeScript", "React"]
}
```

### Press Key

**Tool Name**: `playwright__browser_press_key`

**Parameters**:
- `key` (string, required): Key name or character

**Example: Press Enter**
```typescript
{
  "key": "Enter"
}
```

**Example: Navigation Keys**
```typescript
{
  "key": "ArrowDown"
}
```

**Common Keys**:
- `"Enter"`, `"Tab"`, `"Escape"`
- `"ArrowUp"`, `"ArrowDown"`, `"ArrowLeft"`, `"ArrowRight"`
- `"PageUp"`, `"PageDown"`, `"Home"`, `"End"`
- `"Backspace"`, `"Delete"`
- `"Control+A"`, `"Control+C"`, `"Control+V"` (key combinations)

## Screenshot & Snapshots

### Take Screenshot

**Tool Name**: `playwright__browser_take_screenshot`

**Parameters**:
- `filename` (string, optional): Relative file path (defaults to `page-{timestamp}.png`)
- `fullPage` (boolean, optional): Capture entire scrollable page
- `type` (string, optional): `"png"` (default) or `"jpeg"`
- `element` (string, optional): Element description (for element screenshot)
- `ref` (string, optional): Element reference (for element screenshot)

**Example: Full Page Screenshot**
```typescript
{
  "filename": "cost-dashboard-full.png",
  "fullPage": true,
  "type": "png"
}
```

**Example: Viewport Screenshot**
```typescript
{
  "filename": "current-view.png"
}
```

**Example: Element Screenshot**
```typescript
{
  "element": "Cost breakdown chart",
  "ref": "8",
  "filename": "chart-screenshot.png"
}
```

**Output**: Screenshots saved to current working directory or specified path.

### Access Snapshot

Use `browser_snapshot` (covered above) for accessibility tree structure.

## Testing Workflows

### Test Workflow Pattern

```typescript
// 1. Navigate to page under test
{
  "url": "https://localhost:3000/dashboard"
}

// 2. Wait for page load
{
  "text": "Dashboard"
}

// 3. Take snapshot to identify elements
{}  // browser_snapshot

// 4. Interact with elements
{
  "element": "Refresh button",
  "ref": "6"
}

// 5. Verify expected outcome
{
  "text": "Data refreshed successfully"
}

// 6. Capture screenshot for documentation
{
  "filename": "dashboard-after-refresh.png"
}
```

### Tab Management

**Tool Name**: `playwright__browser_tabs`

**Parameters**:
- `action` (string, required): `"list"`, `"new"`, `"close"`, or `"select"`
- `index` (number, optional): Tab index for close/select operations

**Example: List All Tabs**
```typescript
{
  "action": "list"
}
```

**Example: Open New Tab**
```typescript
{
  "action": "new"
}
```

**Example: Close Tab**
```typescript
{
  "action": "close",
  "index": 1
}
```

**Example: Switch to Tab**
```typescript
{
  "action": "select",
  "index": 0
}
```

## Common Workflows

### Workflow 1: Test Cost Dashboard UI

```typescript
// Step 1: Navigate to dashboard
{
  "url": "https://cost-dashboard.azurewebsites.net"
}

// Step 2: Wait for dashboard load
{
  "text": "Cost Dashboard"
}

// Step 3: Resize to desktop viewport
{
  "width": 1920,
  "height": 1080
}

// Step 4: Take snapshot to identify elements
{}  // browser_snapshot

// Step 5: Test filter interaction
{
  "element": "Category filter dropdown",
  "ref": "8"
}

{
  "values": ["Development"]
}

// Step 6: Verify filtered results
{
  "text": "Showing Development costs"
}

// Step 7: Capture screenshot
{
  "filename": "dashboard-filtered-development.png",
  "fullPage": true
}

// Step 8: Test mobile responsiveness
{
  "width": 375,
  "height": 667
}

{
  "filename": "dashboard-mobile-view.png"
}
```

### Workflow 2: Automated Form Submission

```typescript
// Step 1: Navigate to form
{
  "url": "https://portal.brooksidebi.com/idea-submission"
}

// Step 2: Wait for form load
{
  "textGone": "Loading form..."
}

// Step 3: Get element references
{}  // browser_snapshot

// Step 4: Fill all form fields
{
  "fields": [
    {
      "name": "Idea title",
      "ref": "5",
      "type": "textbox",
      "value": "Automated Cost Tracking Dashboard"
    },
    {
      "name": "Description",
      "ref": "6",
      "type": "textbox",
      "value": "Comprehensive Azure cost tracking with real-time visualization"
    },
    {
      "name": "Innovation type",
      "ref": "7",
      "type": "combobox",
      "value": "Internal Tool"
    },
    {
      "name": "Effort estimate",
      "ref": "8",
      "type": "radio",
      "value": "M"
    },
    {
      "name": "High priority",
      "ref": "9",
      "type": "checkbox",
      "value": "true"
    }
  ]
}

// Step 5: Submit form
{
  "element": "Submit idea button",
  "ref": "10"
}

// Step 6: Verify submission success
{
  "text": "Idea submitted successfully"
}

// Step 7: Capture confirmation screenshot
{
  "filename": "idea-submission-confirmation.png"
}
```

### Workflow 3: Web Scraping for Research

```typescript
// Step 1: Navigate to target site
{
  "url": "https://azure.microsoft.com/en-us/pricing/calculator/"
}

// Step 2: Wait for page load
{
  "text": "Pricing calculator"
}

// Step 3: Take full page snapshot
{}  // browser_snapshot

// Step 4: Interact with calculator
{
  "element": "Service category",
  "ref": "12"
}

{
  "values": ["Compute"]
}

{
  "element": "Virtual Machines option",
  "ref": "15"
}

// Step 5: Fill configuration
{
  "fields": [
    {
      "name": "Region",
      "ref": "18",
      "type": "combobox",
      "value": "East US"
    },
    {
      "name": "Instance type",
      "ref": "19",
      "type": "combobox",
      "value": "D2s v3"
    }
  ]
}

// Step 6: Wait for price calculation
{
  "time": 2
}

// Step 7: Capture pricing screenshot
{
  "filename": "azure-vm-pricing-calculation.png",
  "element": "Pricing summary",
  "ref": "25"
}

// Step 8: Extract data (via snapshot analysis)
{}  // browser_snapshot for text extraction
```

### Workflow 4: E2E Authentication Test

```typescript
// Step 1: Navigate to login page
{
  "url": "https://app.example.com/login"
}

// Step 2: Take snapshot
{}  // browser_snapshot

// Step 3: Fill login form
{
  "fields": [
    {
      "name": "Email",
      "ref": "5",
      "type": "textbox",
      "value": "test@brooksidebi.com"
    },
    {
      "name": "Password",
      "ref": "6",
      "type": "textbox",
      "value": "test-password"
    }
  ]
}

// Step 4: Submit
{
  "element": "Sign in button",
  "ref": "7"
}

// Step 5: Wait for redirect
{
  "text": "Welcome back"
}

// Step 6: Verify authenticated state
{}  // browser_snapshot - check for user menu

// Step 7: Navigate to protected page
{
  "url": "https://app.example.com/dashboard"
}

// Step 8: Verify access granted
{
  "text": "Dashboard"
}

// Step 9: Capture authenticated screenshot
{
  "filename": "authenticated-dashboard.png"
}
```

## Error Handling

### Common Errors

**1. Element Not Found**
```
Error: Could not find element with ref: 12
```

**Solution**:
- Take fresh snapshot before each interaction
- Verify element reference is current (snapshots become stale after navigation)
- Check if element is visible and interactable
- Wait for dynamic content to load

**2. Browser Not Installed**
```
Error: Executable doesn't exist at ...
```

**Solution**:
```bash
# Install browser
npx @playwright/mcp@latest install

# Or use specific browser
npx playwright install msedge
```

**3. Timeout Waiting for Element**
```
Error: Timeout 30000ms exceeded waiting for text: "Dashboard"
```

**Solution**:
- Increase wait time: `{ "time": 10 }`
- Verify text string is exact match
- Check if page loaded correctly
- Inspect network tab for failed requests

**4. Navigation Failed**
```
Error: net::ERR_NAME_NOT_RESOLVED
```

**Solution**:
- Verify URL is correct and accessible
- Check network connectivity
- Ensure URL includes protocol (https://)
- Test URL in regular browser first

### Error Recovery Patterns

**Retry with Fresh Snapshot**:
```typescript
async function clickWithRetry(element: string, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      // Take fresh snapshot
      const snapshot = await browserSnapshot();
      const ref = findElementRef(snapshot, element);

      // Attempt click
      await browserClick({ element, ref });
      return; // Success
    } catch (error) {
      if (attempt === maxRetries) throw error;
      await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
    }
  }
}
```

## Troubleshooting

### Issue: MCP Server Not Responding

**Symptoms**:
- Playwright commands timeout
- `claude mcp list` shows disconnected

**Diagnostics**:
```bash
# Test Playwright directly
npx playwright --version

# Check browser installation
npx playwright list-browsers
```

**Solutions**:
1. Update Playwright MCP: `npm install -g @playwright/mcp@latest`
2. Reinstall browsers: `npx playwright install`
3. Restart Claude Code
4. Check Node.js version: `node --version` (requires 18.0.0+)

### Issue: Element Interactions Failing

**Symptoms**:
- Clicks not registering
- Text not appearing in form fields
- Element "not visible" errors

**Solutions**:
1. Take fresh snapshot before each interaction
2. Add wait before interaction: `{ "time": 1 }`
3. Check element is not covered by overlay
4. Verify element is scrolled into view
5. Use hover before click to trigger states

### Issue: Screenshots Not Saving

**Symptoms**:
- Screenshot command succeeds but no file created
- File path errors

**Solutions**:
- Use relative paths: `screenshots/image.png`
- Ensure directory exists (create if needed)
- Check file permissions
- Verify working directory: `pwd`

### Issue: Headless vs Headed Differences

**Symptoms**:
- Tests pass in headed mode but fail in headless
- Different behavior between modes

**Solutions**:
1. Enable headed mode for debugging:
   - Edit `.claude.json`: Remove `--headless` from args
   - Restart Claude Code
2. Common headless issues:
   - Missing fonts (install system fonts)
   - Different viewport sizes (set explicitly)
   - Timing issues (add waits)
3. Always test in headless mode before deploying automation

## Related Documentation

- [Testing Workflows](../../CLAUDE.md#testing-workflows) - QA patterns for Example Builds
- [Build Architect Agent](../../.claude/agents/build-architect.md) - Build testing integration
- [Playwright Documentation](https://playwright.dev/docs/intro) - Official Playwright guides

## Support

For additional assistance:
- **Playwright Issues**: Check [Playwright GitHub Issues](https://github.com/microsoft/playwright/issues)
- **MCP Configuration**: Engage @integration-specialist agent
- **Test Automation**: Consult @build-architect for testing patterns

---

**Best for**: QA teams requiring reliable browser automation, web scraping for research workflows, and automated UI validation that ensures consistent quality across Example Builds.
