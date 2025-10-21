# Custom Documentation Components Guide

> **Streamline interactive content development** through reusable Vue components, designed to improve user engagement and drive measurable learning outcomes across Agent Studio documentation.

**Best for:** Documentation authors leveraging custom components to create rich, interactive documentation experiences.

**Last Updated:** 2025-10-14 | **Version:** 2.0

---

## Overview

Agent Studio documentation includes custom Vue components built on VitePress to provide enhanced interactivity and dual-layer content support. This guide covers usage, best practices, and implementation details for all custom components.

**Available Components:**
- [BusinessTechToggle](#businesstechtoggle) - Dual-perspective content switcher
- [InteractiveDiagram](#interactivediagram) - Zoomable, interactive diagrams
- [ROICalculator](#roicalculator) - Business value calculator
- [VersionSelector](#versionselector) - Documentation version switcher

---

## Table of Contents

- [Quick Start](#quick-start)
- [BusinessTechToggle](#businesstechtoggle)
- [InteractiveDiagram](#interactivediagram)
- [ROICalculator](#roicalculator)
- [VersionSelector](#versionselector)
- [Best Practices](#best-practices)
- [Accessibility Guidelines](#accessibility-guidelines)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

### Using Components in Markdown

Custom components are globally registered in VitePress and can be used directly in markdown files:

```vue
<ComponentName prop1="value1" :prop2="dynamicValue">
  Content here
</ComponentName>
```

### Script Context

For components requiring JavaScript data:

```vue
<script setup>
const myData = {
  // Data object
};
</script>

<ComponentName :data="myData" />
```

---

## BusinessTechToggle

### Purpose

Provides dual-perspective content display, allowing users to switch between business-focused and technical views within a single document.

**Best for:**
- Content serving both business and technical audiences
- Guides requiring both ROI context and implementation details
- Architecture documents with strategic and technical perspectives

### Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `defaultMode` | `'business' \| 'technical'` | `'business'` | Initial view on component mount |
| `showDescription` | `boolean` | `true` | Show descriptive text below toggle buttons |
| `showKeyboardHints` | `boolean` | `true` | Display keyboard shortcut hints |
| `persistPreference` | `boolean` | `true` | Save user preference to localStorage |
| `storageKey` | `string` | `'bt-toggle-mode'` | localStorage key (if `persistPreference` is true) |

### Events

| Event | Payload | Description |
|-------|---------|-------------|
| `mode-change` | `{ from: string, to: string }` | Emitted when mode changes |

### Usage Example

```vue
<BusinessTechToggle defaultMode="business">
  <template #business>

## Streamline Agent Workflows

This solution is designed to improve operational efficiency by automating complex multi-step processes. Organizations scaling AI agents across departments benefit from centralized orchestration that:

- **Reduces manual intervention** by 60% through automated task scheduling
- **Improves reliability** with checkpoint-based recovery and retry logic
- **Drives measurable outcomes** through real-time monitoring and analytics

**ROI Impact:**
- Time savings: 15-20 hours per week per team
- Cost reduction: $50K-$100K annually
- Error rate improvement: 40% reduction

  </template>
  <template #technical>

## Agent Orchestration Implementation

The orchestration layer uses .NET 8 ASP.NET Core to coordinate Python-based agent execution:

```typescript
public class MetaAgentOrchestrator {
  public async Task<WorkflowResult> ExecuteAsync(WorkflowDefinition workflow) {
    // Establish workflow execution with checkpoint-based recovery
    var executor = new WorkflowExecutor(workflow.Pattern);
    return await executor.RunAsync(workflow.Tasks);
  }
}
```

**Architecture:**
- REST API for workflow submission
- SignalR for real-time updates
- Cosmos DB for state persistence
- Retry with exponential backoff

**Performance:**
- Latency: <200ms p95
- Throughput: 1000 workflows/minute
- Availability: 99.9% SLA

  </template>
</BusinessTechToggle>
```

### Keyboard Shortcuts

Users can switch modes using keyboard shortcuts:
- <kbd>B</kbd> - Switch to Business view
- <kbd>T</kbd> - Switch to Technical view
- <kbd>Tab</kbd> - Navigate between views
- <kbd>←</kbd> / <kbd>→</kbd> - Arrow keys to toggle

### Accessibility Features

- **ARIA attributes:** Proper role, aria-selected, aria-controls
- **Keyboard navigation:** Full keyboard support with visible focus indicators
- **Screen reader support:** Announces mode changes via aria-live
- **Persistent preference:** Remembers user choice across sessions

### Best Practices

#### Content Parity

✅ **Good - Maintain logical equivalence:**
- Business view covers "what" and "why"
- Technical view covers "how" and "what"
- Both sections address same topic

❌ **Bad - Disconnected content:**
- Business view talks about Feature A
- Technical view talks about Feature B

#### Length Balance

✅ **Good:**
- Business view: 2-3 paragraphs with bullet points
- Technical view: 2-3 paragraphs with code examples
- Similar content depth

❌ **Bad:**
- Business view: 1 sentence
- Technical view: 10 paragraphs of code
- Vastly different lengths

#### When to Use

✅ **Use when:**
- Content genuinely serves two audiences
- Both perspectives add value
- You want to avoid duplicate pages

❌ **Don't use when:**
- Content is purely technical
- Only one audience cares
- Would be better as separate documents

---

## InteractiveDiagram

### Purpose

Embeds interactive, zoomable diagrams with optional hotspots, fullscreen mode, and legend support. Designed to make complex diagrams more accessible and engaging.

**Best for:**
- Architecture diagrams with multiple components
- Complex flowcharts requiring zoom
- Diagrams with clickable areas linking to related docs

### Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `title` | `string` | - | Diagram title |
| `type` | `'mermaid' \| 'image' \| 'custom'` | (required) | Diagram type |
| `diagram` | `string` | - | Mermaid code or image path |
| `alt` | `string` | - | Alt text for images |
| `caption` | `string` | - | Figure caption |
| `showZoom` | `boolean` | `true` | Enable zoom controls |
| `showFullscreen` | `boolean` | `true` | Enable fullscreen mode |
| `showDownload` | `boolean` | `true` | Enable download button |
| `showLegend` | `boolean` | `false` | Display legend |
| `hotspots` | `Hotspot[]` | `[]` | Interactive clickable areas |
| `legend` | `LegendItem[]` | `[]` | Legend items |

### Type Definitions

```typescript
interface Hotspot {
  x: number;              // Percentage from left (0-100)
  y: number;              // Percentage from top (0-100)
  title: string;          // Hotspot title
  description: string;    // Hotspot description
  link?: string;          // Optional link URL
  action?: () => void;    // Optional custom action
}

interface LegendItem {
  color: string;          // CSS color value
  label: string;          // Legend label
}
```

### Usage Example: Mermaid Diagram

```vue
<script setup>
const containerDiagram = `
graph TB
    subgraph "Frontend"
        WebApp["React SPA"]
    end
    subgraph "API"
        API["API Gateway"]
        SignalR["SignalR Hub"]
    end
    subgraph "Data"
        DB[("Cosmos DB")]
    end

    WebApp --> API
    WebApp --> SignalR
    API --> DB

    classDef frontend fill:#61dafb,stroke:#4fa8c5,color:#000
    classDef api fill:#512bd4,stroke:#3a1f9d,color:#fff
    classDef data fill:#336791,stroke:#254a6b,color:#fff

    class WebApp frontend
    class API,SignalR api
    class DB data
`;

const hotspots = [
  {
    x: 50, y: 20,
    title: 'React SPA',
    description: 'Single-page application built with React 19 and TypeScript',
    link: '/architecture/frontend'
  },
  {
    x: 30, y: 50,
    title: 'API Gateway',
    description: '.NET 8 ASP.NET Core API for request routing',
    link: '/api/reference'
  },
  {
    x: 70, y: 50,
    title: 'SignalR Hub',
    description: 'Real-time bidirectional communication',
    link: '/api/signalr-hub'
  }
];

const legend = [
  { color: '#61dafb', label: 'Frontend Components' },
  { color: '#512bd4', label: 'API Services' },
  { color: '#336791', label: 'Data Stores' }
];
</script>

<InteractiveDiagram
  title="Container Architecture"
  type="mermaid"
  :diagram="containerDiagram"
  caption="Agent Studio container architecture showing frontend, API, and data tiers"
  :showZoom="true"
  :showFullscreen="true"
  :showDownload="false"
  :showLegend="true"
  :hotspots="hotspots"
  :legend="legend"
/>
```

### Usage Example: Image Diagram

```vue
<InteractiveDiagram
  title="Deployment Architecture"
  type="image"
  diagram="./assets/deployment-architecture.png"
  alt="Azure deployment topology showing multi-region setup with primary and secondary regions"
  caption="Multi-region deployment with automatic failover"
  :showZoom="true"
  :showFullscreen="true"
/>
```

### Controls

**Zoom:**
- **Mouse:** Ctrl + Scroll wheel
- **Buttons:** + / - / Reset buttons
- **Range:** 50% to 200%

**Fullscreen:**
- **Button:** Fullscreen icon (⛶)
- **Keyboard:** <kbd>F11</kbd> (browser fullscreen)
- **Exit:** <kbd>Esc</kbd> or click outside

### Accessibility Features

- **Keyboard navigation:** All controls accessible via keyboard
- **Screen reader support:** Diagram description announced
- **Alt text required:** For image diagrams
- **Hotspot announcements:** Tooltip content read by screen readers

### Best Practices

#### Hotspot Placement

✅ **Good:**
- Position hotspots at logical component locations
- Use percentages for responsive positioning
- Provide clear titles and descriptions

❌ **Bad:**
- Hardcode pixel positions (breaks on resize)
- Overlap hotspots making them hard to click
- Generic titles like "Component 1"

#### Legend Usage

✅ **Use legend when:**
- Diagram uses color-coding extensively
- Color meanings not obvious
- Multiple component types

❌ **Don't need legend when:**
- Simple diagrams with labels
- Color is decorative only
- All information in labels

#### Performance

- Keep Mermaid diagrams under 50 nodes
- Optimize images (<200KB)
- Limit hotspots to <10 per diagram

---

## ROICalculator

### Purpose

Interactive calculator allowing users to estimate return on investment for Agent Studio. Helps business stakeholders quantify potential value.

**Best for:**
- Business value propositions
- Executive summaries
- Pricing and cost analysis pages

### Props

None - component is self-contained with default values.

### Usage Example

```vue
<ROICalculator />
```

### Inputs

The calculator provides the following configurable inputs:

**Team Metrics:**
- Development team size (1-1000 developers)
- Average developer salary ($USD/year)
- Manual task hours per developer (hours/week)
- Incident response time (hours/month)
- Deployment frequency (daily, weekly, bi-weekly, monthly)

**Investment:**
- Platform cost ($USD/month)
- Implementation cost ($USD one-time)

### Outputs

**Primary Metrics:**
- Annual ROI (percentage)
- Net benefit ($USD)
- Payback period (months)

**Savings Breakdown:**
- Automation efficiency savings
- Reduced incident response savings
- Deployment acceleration savings
- Total annual savings

**Time Savings:**
- Hours saved per year
- Hours saved per week

### Calculation Methodology

**Automation Savings:**
- Assumes 40% time reduction on manual tasks
- Formula: `(manual hours * 0.4) * team size * 52 weeks * hourly rate`

**Incident Savings:**
- Assumes 30% reduction in incident response time
- Formula: `(incident hours * 0.3) * 12 months * hourly rate`

**Deployment Savings:**
- Assumes 20% faster deployments
- Formula: `deployments/year * 4 hours * 0.2 * team size * hourly rate`

**ROI Calculation:**
- Net benefit: `Total savings - Platform cost (annual)`
- ROI: `(Net benefit / First year cost) * 100`
- Payback period: `Implementation cost / Monthly net benefit`

### Customization

To customize default values, fork the component:

```vue
<script setup>
const customInputs = reactive({
  teamSize: 25,
  avgSalary: 150000,
  platformCostPerMonth: 3000,
  // ... other defaults
});
</script>

<!-- Pass to forked component -->
```

### Best Practices

#### Context

✅ **Provide context before calculator:**
```markdown
## ROI Analysis

Agent Studio delivers measurable value through automated workflows and improved efficiency. Use the calculator below to estimate your organization's potential ROI.

<ROICalculator />

**Note:** These estimates are based on industry averages. Actual results vary depending on your specific use case, implementation scope, and organizational context.
```

❌ **Don't drop calculator without explanation:**
```markdown
<ROICalculator />
<!-- No context -->
```

#### Disclaimers

Always include a disclaimer:
```markdown
::: warning Estimate Disclaimer
ROI calculations are estimates based on industry benchmarks. Actual results depend on implementation scope, organizational structure, and use case complexity. Contact our team for a custom assessment.
:::
```

#### Placement

✅ **Good locations:**
- Business value proposition pages
- Executive summary sections
- Pricing/comparison pages

❌ **Bad locations:**
- Technical implementation guides
- API reference documentation
- Developer tutorials

---

## VersionSelector

### Purpose

Allows users to switch between different versions of documentation, supporting multi-version documentation sites.

**Best for:**
- Projects with multiple supported versions
- Breaking changes between versions
- Long-term support (LTS) releases

### Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `current` | `string` | `'v2.0'` | Current version identifier |

### Configuration

Version configuration is managed within the component. To customize, edit `VersionSelector.vue`:

```typescript
const versions = ref<Version[]>([
  {
    value: 'v2.0',
    label: 'v2.0 (Current)',
    link: '/',
    badge: 'latest',
    description: 'Meta-Agent First Architecture with enhanced orchestration',
    releaseDate: '2025-01-15'
  },
  {
    value: 'v1.5',
    label: 'v1.5',
    link: '/v1.5/',
    badge: 'stable',
    description: 'Production-ready release with improved performance',
    releaseDate: '2024-11-20'
  },
  // ... more versions
]);
```

### Badge Types

| Badge | Color | Use Case |
|-------|-------|----------|
| `latest` | Brand color | Most recent release |
| `stable` | Green | Current stable release |
| `lts` | Blue | Long-term support |
| `deprecated` | Red | Deprecated versions |

### Usage Example

```vue
<!-- In site theme or layout -->
<VersionSelector current="v2.0" />
```

### Accessibility Features

- **Keyboard navigation:** Full keyboard support
- **ARIA attributes:** Proper button and dropdown roles
- **Focus management:** Focus returns to button on close
- **Screen reader support:** Announces version changes

### Best Practices

#### Version Naming

✅ **Good - Semantic versioning:**
- v2.0, v1.5, v1.0
- 2025.1, 2024.11, 2024.6 (calendar versioning)

❌ **Bad - Unclear naming:**
- Version 2, Version 1
- Latest, Previous, Old

#### Descriptions

✅ **Good - Informative:**
- "Meta-Agent First Architecture with enhanced orchestration"
- "Production-ready release with improved performance"

❌ **Bad - Generic:**
- "Latest version"
- "Version 2.0"

#### Deprecation

When deprecating versions:
1. Add `badge: 'deprecated'`
2. Update description with migration path
3. Keep docs available for 2 release cycles minimum
4. Link to migration guide

---

## Best Practices

### General Component Usage

#### Performance

- **Lazy load large diagrams:** Use `v-if` or `v-show` for conditionally rendered diagrams
- **Limit hotspots:** <10 per diagram to avoid clutter
- **Optimize images:** <200KB, WebP format
- **Minimize data:** Don't pass unnecessarily large data objects

#### Accessibility

- **Provide alternatives:** Text descriptions for all interactive content
- **Keyboard support:** Ensure all interactions work with keyboard
- **Screen readers:** Test with NVDA or VoiceOver
- **Focus management:** Maintain logical focus order

#### Mobile Responsiveness

- **Touch targets:** Minimum 44x44px (48x48px on mobile)
- **Zoom controls:** Work on touch devices
- **Layout:** Components adapt to small screens
- **Performance:** Lightweight on mobile (simplified diagrams if needed)

### Content Guidelines

#### BusinessTechToggle

**Business Content:**
- Lead with outcomes and benefits
- Use quantifiable metrics (percentages, dollar amounts)
- Avoid technical jargon
- Include ROI context
- 2-4 paragraphs maximum

**Technical Content:**
- Include code examples
- Reference architecture diagrams
- Provide implementation details
- Link to API documentation
- Explain patterns and practices

#### InteractiveDiagram

- **Title:** Descriptive and specific
- **Caption:** Summarize key takeaway
- **Hotspots:** Limit to important components
- **Legend:** Use when >3 colors
- **Alt text:** Describe diagram content for screen readers

---

## Accessibility Guidelines

All custom components must meet WCAG 2.1 AA standards:

### Keyboard Navigation

- [ ] All interactive elements reachable via Tab
- [ ] Logical tab order
- [ ] No keyboard traps
- [ ] Visible focus indicators

### Screen Reader Support

- [ ] Proper ARIA roles and attributes
- [ ] Meaningful labels for controls
- [ ] Status announcements (aria-live)
- [ ] Alternative text for visual content

### Color and Contrast

- [ ] Color contrast ≥4.5:1 (normal text)
- [ ] Color contrast ≥3:1 (large text, UI components)
- [ ] Information not conveyed by color alone
- [ ] Support for high contrast mode

### Touch and Pointer

- [ ] Touch targets ≥44x44px (≥48x48px on mobile)
- [ ] Adequate spacing between targets
- [ ] Support for multiple input methods

---

## Troubleshooting

### Common Issues

#### Component Not Rendering

**Symptom:** Component doesn't appear in documentation

**Solutions:**
1. Verify component is registered in `.vitepress/theme/index.ts`
2. Check for syntax errors in component usage
3. Ensure all required props provided
4. Check browser console for errors

#### Mermaid Diagram Not Rendering

**Symptom:** Blank space or error message

**Solutions:**
1. Validate Mermaid syntax at [Mermaid Live Editor](https://mermaid.live)
2. Escape special characters in node IDs
3. Check for missing classDef declarations
4. Verify theme compatibility

#### BusinessTechToggle Not Switching

**Symptom:** Clicking toggle doesn't change view

**Solutions:**
1. Check browser console for JavaScript errors
2. Verify both slots (`#business` and `#technical`) have content
3. Clear localStorage if `persistPreference` enabled
4. Test in incognito mode (clears localStorage)

#### ROICalculator Shows Incorrect Values

**Symptom:** Calculations don't make sense

**Solutions:**
1. Verify input values are reasonable
2. Check for JavaScript errors in console
3. Review calculation formulas in component
4. Ensure number inputs (not strings)

---

## Component Development

### Adding New Components

1. **Create component file:** `docs/.vitepress/theme/components/NewComponent.vue`

2. **Register globally:** In `docs/.vitepress/theme/index.ts`:
   ```typescript
   import NewComponent from './components/NewComponent.vue';

   export default {
     extends: DefaultTheme,
     enhanceApp({ app }) {
       app.component('NewComponent', NewComponent);
     }
   };
   ```

3. **Document usage:** Add to this guide

4. **Test thoroughly:**
   - Keyboard navigation
   - Screen reader compatibility
   - Mobile responsiveness
   - Browser compatibility (Chrome, Firefox, Safari, Edge)

### Component Standards

- **TypeScript:** Use TypeScript for type safety
- **Vue 3 Composition API:** Use `<script setup>`
- **Accessibility:** WCAG 2.1 AA compliance required
- **Responsive:** Mobile-first design
- **Performance:** Lazy load heavy components
- **Documentation:** JSDoc comments for props and events

---

## Additional Resources

- [VitePress Documentation](https://vitepress.dev/)
- [Vue 3 Documentation](https://vuejs.org/)
- [Mermaid Documentation](https://mermaid.js.org/)
- [ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)

---

## Feedback

Improve these components:
- **Issues:** [GitHub Issues](https://github.com/Brookside-Proving-Grounds/Project-Ascension/issues)
- **Feature Requests:** [GitHub Discussions](https://github.com/Brookside-Proving-Grounds/Project-Ascension/discussions)
- **Email:** Consultations@BrooksideBI.com

---

**Maintained by:** Documentation Team | **Last Updated:** 2025-10-14 | **Version:** 2.0
