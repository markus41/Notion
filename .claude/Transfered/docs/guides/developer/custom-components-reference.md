# Custom VitePress Components Reference

Establish comprehensive documentation component library to streamline knowledge discovery and improve user engagement across all documentation workflows.

**Best for:** Organizations requiring interactive, accessible, and performant documentation with enterprise-grade user experience.

---

## Overview

Agent Studio documentation leverages custom Vue 3 components designed to:

- **Streamline workflows** - Reduce friction in learning and decision-making processes
- **Improve visibility** - Surface critical information through interactive visualizations
- **Drive measurable outcomes** - Enable faster onboarding, clearer feature comparison, and informed decisions
- **Support sustainable growth** - Maintain consistency and quality across documentation at scale

All components adhere to **WCAG 2.1 Level AA** accessibility standards and support both light and dark modes.

---

## Component Catalog

### 1. BusinessTechToggle

Establish dual-perspective content display to support diverse audience needs across business and technical stakeholders.

#### Purpose

Enables seamless switching between business-focused (ROI, outcomes) and technical (architecture, code) content views within a single documentation page.

#### Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `defaultMode` | `'business' \| 'technical'` | No | `'business'` | Initial view mode on component mount |
| `showDescription` | `boolean` | No | `true` | Display descriptive text below toggle buttons |
| `showKeyboardHints` | `boolean` | No | `true` | Show keyboard shortcut hints for power users |
| `persistPreference` | `boolean` | No | `true` | Enable localStorage persistence across sessions |
| `storageKey` | `string` | No | `'bt-toggle-mode'` | Unique ID for localStorage key |

#### Events

| Event | Payload | Description |
|-------|---------|-------------|
| `mode-change` | `{ from: string, to: string }` | Emitted when user switches between business and technical views |

#### Slots

| Slot | Description |
|------|-------------|
| `business` | Business-focused content (value propositions, ROI, use cases) |
| `technical` | Technical content (code examples, architecture diagrams, API details) |

#### Usage Example

```vue
<BusinessTechToggle
  :defaultMode="'business'"
  :persistPreference="true"
  @mode-change="handleModeChange"
>
  <template #business>
    <h3>Business Value</h3>
    <p>Reduce deployment time by 60% and improve team productivity...</p>
    <ul>
      <li>Cost savings: $120K annually</li>
      <li>Time to market: 40% faster</li>
      <li>ROI: 180% in first year</li>
    </ul>
  </template>

  <template #technical>
    <h3>Technical Implementation</h3>
    <p>Meta-agent orchestration powered by Azure OpenAI and .NET 8...</p>
    ```typescript
    const orchestrator = new MetaAgentOrchestrator({
      pattern: WorkflowPattern.Sequential
    });
    ```
  </template>
</BusinessTechToggle>
```

#### Accessibility

- **ARIA roles**: `region`, `tab`, `tabpanel`, `tablist`
- **Keyboard shortcuts**:
  - `B` - Switch to Business view
  - `T` - Switch to Technical view
  - `Arrow Left/Right` - Navigate between tabs
  - `Tab` - Move focus to content panel
- **Screen reader support**: Full ARIA labeling with live region announcements
- **Focus management**: Visible focus indicators with 3:1 contrast ratio

#### Best Practices

✅ **DO:**
- Use for content with distinct business and technical audiences
- Provide rich, substantive content in both slots
- Leverage persistence for multi-page documentation sites

❌ **DON'T:**
- Use for simple content that doesn't warrant dual perspectives
- Leave slots empty (always provide meaningful content)
- Override keyboard shortcuts without providing alternatives

#### Common Pitfalls

1. **Empty slots** - Always provide content; component shows placeholder text if slots are empty
2. **Storage conflicts** - Use unique `storageKey` values if using multiple instances
3. **Event handling** - Remember to handle `mode-change` event if tracking analytics

---

### 2. InteractiveDiagram

Establish zoomable, interactive diagrams with hotspot annotations to improve comprehension of complex architectures.

#### Purpose

Enables users to explore Mermaid diagrams, images, or custom SVG content with zoom, pan, fullscreen, and clickable hotspot annotations.

#### Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `title` | `string` | No | `undefined` | Diagram title displayed in header |
| `type` | `'mermaid' \| 'image' \| 'custom'` | Yes | - | Content type to render |
| `diagram` | `string` | Conditional | `undefined` | Mermaid code or image URL (required for mermaid/image types) |
| `alt` | `string` | No | `title` | Alt text for images (accessibility) |
| `caption` | `string` | No | `undefined` | Caption text below diagram |
| `showZoom` | `boolean` | No | `true` | Show zoom controls |
| `showFullscreen` | `boolean` | No | `true` | Show fullscreen toggle |
| `showDownload` | `boolean` | No | `true` | Show download button |
| `showLegend` | `boolean` | No | `false` | Show legend panel |
| `hotspots` | `Hotspot[]` | No | `[]` | Interactive annotation points |
| `legend` | `LegendItem[]` | No | `[]` | Legend color/label pairs |

#### Hotspot Interface

```typescript
interface Hotspot {
  x: number;        // X position (percentage 0-100)
  y: number;        // Y position (percentage 0-100)
  title: string;    // Hotspot title
  description: string; // Detailed description
  link?: string;    // Optional navigation URL
  action?: () => void; // Optional custom action
}
```

#### Usage Example

```vue
<InteractiveDiagram
  title="Agent Studio Architecture"
  type="mermaid"
  :diagram="`
    graph TD
      A[Frontend React] --> B[.NET Orchestrator]
      B --> C[Python Agents]
      C --> D[Azure OpenAI]
  `"
  caption="Three-layer architecture with Azure integration"
  :hotspots="[
    {
      x: 50,
      y: 30,
      title: 'Orchestrator Layer',
      description: 'Manages workflow execution and state',
      link: '/architecture/orchestration'
    }
  ]"
  :showLegend="true"
  :legend="[
    { color: '#3b82f6', label: 'Frontend Layer' },
    { color: '#8b5cf6', label: 'Backend Layer' },
    { color: '#22c55e', label: 'AI Services' }
  ]"
/>
```

#### Accessibility

- **ARIA labels**: All interactive controls have descriptive labels
- **Keyboard navigation**: Tab through controls, Escape to close fullscreen
- **Screen reader**: Hotspot titles and descriptions announced
- **Touch gestures**: Pinch-to-zoom on touch devices

#### Best Practices

✅ **DO:**
- Provide meaningful `alt` text for images
- Use hotspots to annotate complex diagrams
- Include captions to provide context
- Test zoom functionality on mobile devices

❌ **DON'T:**
- Embed extremely large images without optimization
- Overcrowd diagrams with too many hotspots (max 5-7)
- Forget to test Mermaid syntax before deploying

---

### 3. ROICalculator

Establish interactive ROI calculation to support informed investment decisions with real-time financial projections.

#### Purpose

Enables prospects and customers to calculate potential return on investment based on their team size, costs, and current workflows.

#### Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| None | - | - | - | Component uses internal state for calculator inputs |

#### Features

- **Input parameters**:
  - Team size
  - Average developer salary
  - Manual task hours per week
  - Incident response time
  - Deployment frequency
  - Platform cost
  - Implementation cost (one-time)

- **Calculated outputs**:
  - Annual ROI percentage
  - Payback period (months)
  - Time saved (hours/year, hours/week)
  - Cost savings breakdown
  - Investment summary

#### Usage Example

```vue
<ROICalculator />
```

#### Accessibility

- **Form controls**: All inputs have associated labels
- **ARIA live regions**: Results update announced to screen readers
- **Keyboard navigation**: Full tab order through inputs
- **Focus management**: Logical focus flow from inputs to results

#### Best Practices

✅ **DO:**
- Encourage users to enter realistic values
- Explain calculation methodology in documentation
- Provide industry benchmark comparisons

❌ **DON'T:**
- Guarantee specific ROI results (include disclaimers)
- Hide calculation formulas (transparency builds trust)
- Make unrealistic default assumptions

---

### 4. VersionSelector

Establish version selection dropdown to streamline navigation across documentation versions.

#### Purpose

Enables users to switch between different documentation versions (latest, stable, LTS, deprecated) with clear visual indicators.

#### Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `current` | `string` | No | `'v2.0'` | Currently active version identifier |

#### Version Interface

```typescript
interface Version {
  value: string;       // Version identifier (e.g., 'v2.0')
  label: string;       // Display label
  link: string;        // Documentation URL for this version
  badge?: 'latest' | 'stable' | 'lts' | 'deprecated'; // Status badge
  description?: string; // Version description
  releaseDate?: string; // Release date (ISO 8601)
}
```

#### Usage Example

```vue
<VersionSelector current="v2.0" />
```

#### Accessibility

- **ARIA**: `aria-expanded`, `aria-haspopup` on toggle button
- **Keyboard**: Escape to close, Enter/Space to activate
- **Focus management**: Returns focus to button on close
- **Screen reader**: Version status and release dates announced

#### Best Practices

✅ **DO:**
- Keep version list up-to-date
- Use consistent versioning scheme (semver recommended)
- Provide clear migration guides between versions
- Show deprecation warnings for old versions

❌ **DON'T:**
- List more than 5-6 versions (archive old versions)
- Remove LTS versions without advance notice
- Change URLs without redirects (breaks bookmarks)

---

### 5. CodeTabs

Establish multi-language code examples to streamline developer onboarding across diverse technology stacks.

#### Purpose

Displays code examples in multiple programming languages with syntax highlighting, copy-to-clipboard, and keyboard navigation.

#### Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `tabs` | `CodeTab[]` | Yes | - | Array of code examples in different languages |
| `defaultTab` | `number` | No | `0` | Default active tab index |
| `showDescription` | `boolean` | No | `true` | Show description below code panel |
| `ariaLabel` | `string` | No | `'Code language selector'` | Accessible label for tablist |

#### CodeTab Interface

```typescript
interface CodeTab {
  lang: string;          // Language ID (typescript, python, csharp, etc.)
  label: string;         // Display label for tab
  code: string;          // Code content
  icon?: string;         // Optional emoji icon
  badge?: string;        // Optional badge (e.g., 'Recommended')
  description?: string;  // Optional explanation
}
```

#### Usage Example

```vue
<CodeTabs
  :tabs="[
    {
      lang: 'typescript',
      label: 'TypeScript',
      icon: '📘',
      badge: 'Recommended',
      code: `import { MetaAgent } from '@agent-studio/sdk';

const agent = new MetaAgent({
  name: 'architect',
  model: 'gpt-4'
});

const result = await agent.execute({
  task: 'Design microservices architecture'
});

console.log(result);`,
      description: 'TypeScript provides excellent type safety and IDE support'
    },
    {
      lang: 'python',
      label: 'Python',
      icon: '🐍',
      code: `from agent_studio import MetaAgent

agent = MetaAgent(
    name='architect',
    model='gpt-4'
)

result = agent.execute(
    task='Design microservices architecture'
)

print(result)`,
      description: 'Python offers simple syntax ideal for rapid prototyping'
    },
    {
      lang: 'csharp',
      label: 'C#',
      icon: '🔷',
      code: `using AgentStudio.SDK;

var agent = new MetaAgent
{
    Name = "architect",
    Model = "gpt-4"
};

var result = await agent.ExecuteAsync(new TaskRequest
{
    Task = "Design microservices architecture"
});

Console.WriteLine(result);`,
      description: 'C# provides enterprise-grade performance and Azure integration'
    }
  ]"
  @tab-change="handleTabChange"
/>
```

#### Accessibility

- **ARIA roles**: `tab`, `tabpanel`, `tablist`
- **Keyboard navigation**:
  - `Arrow Left/Right` - Navigate between language tabs
  - `Home` - Jump to first tab
  - `End` - Jump to last tab
  - `Tab` - Focus code panel
- **Screen reader**: Language labels and descriptions announced
- **Copy feedback**: Visual and auditory confirmation on copy

#### Best Practices

✅ **DO:**
- Provide equivalent functionality across all language examples
- Keep code examples concise (< 30 lines)
- Include comments explaining key concepts
- Test all code examples for correctness
- Use realistic, practical examples

❌ **DON'T:**
- Show more than 5 language options (overwhelming)
- Use pseudocode (provide actual, runnable code)
- Forget to escape HTML entities in code strings
- Mix different API versions in examples

#### Common Pitfalls

1. **Syntax errors** - Always test code before adding to docs
2. **Missing imports** - Show full working examples with all imports
3. **Inconsistent formatting** - Use a code formatter for all examples
4. **Outdated examples** - Review code tabs when API changes

---

### 6. FeatureMatrix

Establish comprehensive feature comparison to support informed decision-making across tiers, plans, or versions.

#### Purpose

Displays feature availability across multiple product dimensions (tiers, versions, plans) with support for boolean, text, and partial availability indicators.

#### Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `title` | `string` | No | `undefined` | Matrix title |
| `description` | `string` | No | `undefined` | Matrix description |
| `columns` | `Column[]` | Yes | - | Column definitions (tiers/versions) |
| `features` | `Feature[]` | Yes | - | Feature definitions with values |
| `showExport` | `boolean` | No | `true` | Show CSV/PDF export buttons |
| `defaultExpanded` | `boolean` | No | `true` | Expand all categories by default |

#### Column Interface

```typescript
interface Column {
  id: string;            // Unique identifier
  name: string;          // Display name (e.g., 'Pro', 'Enterprise')
  description?: string;  // Optional description
  badge?: string;        // Badge text ('Popular', 'Recommended')
  highlighted?: boolean; // Highlight this column
}
```

#### Feature Interface

```typescript
interface Feature {
  id: string;                    // Unique identifier
  name: string;                  // Feature name
  description?: string;          // Detailed description (shown in modal)
  category?: string;             // Category for grouping
  values: Record<string, FeatureValue>; // Values per column
}

type FeatureValue =
  | boolean                                    // ✓ or ✗
  | string                                     // Text value
  | number                                     // Numeric value
  | { type: 'partial' | 'limited'; label?: string }; // Partial availability
```

#### Usage Example

```vue
<FeatureMatrix
  title="Agent Studio Plans"
  description="Compare features across Free, Pro, and Enterprise tiers"
  :columns="[
    {
      id: 'free',
      name: 'Free',
      description: 'For individuals and small teams',
      badge: undefined,
      highlighted: false
    },
    {
      id: 'pro',
      name: 'Pro',
      description: 'For growing teams',
      badge: 'popular',
      highlighted: true
    },
    {
      id: 'enterprise',
      name: 'Enterprise',
      description: 'For large organizations',
      badge: 'recommended',
      highlighted: false
    }
  ]"
  :features="[
    {
      id: 'agents',
      name: 'AI Agents',
      description: 'Number of concurrent AI agents',
      category: 'Core Features',
      values: {
        free: '5',
        pro: '50',
        enterprise: 'Unlimited'
      }
    },
    {
      id: 'workflows',
      name: 'Workflow Orchestration',
      description: 'Advanced workflow patterns and state management',
      category: 'Core Features',
      values: {
        free: true,
        pro: true,
        enterprise: true
      }
    },
    {
      id: 'observability',
      name: 'Full Observability',
      description: 'Traces, metrics, and distributed logging',
      category: 'Monitoring',
      values: {
        free: false,
        pro: { type: 'partial', label: '30-day retention' },
        enterprise: true
      }
    },
    {
      id: 'support',
      name: 'Support Level',
      category: 'Support',
      values: {
        free: 'Community',
        pro: 'Email (24h)',
        enterprise: 'Dedicated (4h SLA)'
      }
    }
  ]"
  :showExport="true"
/>
```

#### Accessibility

- **ARIA**: Full table semantics with row/column headers
- **Keyboard**: Tab through interactive elements (category toggles, info buttons)
- **Screen reader**: Feature values announced with context
- **Modal dialogs**: ARIA modal with focus trap
- **Sticky headers**: Column headers remain visible on scroll

#### Best Practices

✅ **DO:**
- Group related features into categories
- Highlight recommended/popular tiers
- Provide detailed descriptions for complex features
- Keep feature names concise and scannable
- Export functionality for offline comparison
- Use consistent value types within feature rows

❌ **DON'T:**
- List more than 50 features (overwhelming)
- Use vague terms like "Advanced" without explanation
- Show more than 5 columns (layout breaks)
- Forget mobile optimization (sticky column essential)
- Use inconsistent value formats

#### Common Pitfalls

1. **Too many features** - Prioritize most important features, link to full docs
2. **Unclear partial availability** - Use descriptive labels like "10 GB limit"
3. **Mobile layout breaks** - Test scrolling behavior on small screens
4. **Missing descriptions** - Always explain non-obvious features
5. **Stale data** - Review feature matrix when product changes

---

## Global Styles and Theming

All custom components inherit VitePress theme variables:

```css
/* Brand colors */
--vp-c-brand-1: #3eaf7c
--vp-c-brand-2: #2d9b69
--vp-c-brand-3: #1e7a52
--vp-c-brand-soft: rgba(62, 175, 124, 0.14)

/* Dark mode variants */
.dark --vp-c-brand-1: #4dd99d
.dark --vp-c-brand-2: #3eaf7c
.dark --vp-c-brand-3: #2d9b69
```

### Custom CSS Utilities

Screen reader only text:

```css
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}
```

Keyboard shortcut styling:

```css
kbd {
  padding: 0.15rem 0.4rem;
  font-family: var(--vp-font-family-mono);
  background: var(--vp-c-bg-soft);
  border: 1px solid var(--vp-c-divider);
  border-radius: 3px;
}
```

---

## Testing Components

### Unit Testing with Vitest

```typescript
import { describe, it, expect } from 'vitest';
import { mount } from '@vue/test-utils';
import BusinessTechToggle from './BusinessTechToggle.vue';

describe('BusinessTechToggle', () => {
  it('renders business content by default', () => {
    const wrapper = mount(BusinessTechToggle, {
      slots: {
        business: '<p>Business content</p>',
        technical: '<p>Technical content</p>'
      }
    });

    expect(wrapper.text()).toContain('Business content');
    expect(wrapper.text()).not.toContain('Technical content');
  });

  it('switches to technical view on button click', async () => {
    const wrapper = mount(BusinessTechToggle, {
      slots: {
        business: '<p>Business content</p>',
        technical: '<p>Technical content</p>'
      }
    });

    await wrapper.find('.technical-btn').trigger('click');
    expect(wrapper.text()).toContain('Technical content');
  });

  it('emits mode-change event', async () => {
    const wrapper = mount(BusinessTechToggle);
    await wrapper.find('.technical-btn').trigger('click');

    expect(wrapper.emitted('mode-change')).toBeTruthy();
    expect(wrapper.emitted('mode-change')?.[0]).toEqual([
      { from: 'business', to: 'technical' }
    ]);
  });
});
```

### Accessibility Testing

```typescript
import { axe } from 'jest-axe';

it('has no accessibility violations', async () => {
  const wrapper = mount(BusinessTechToggle);
  const results = await axe(wrapper.element);
  expect(results).toHaveNoViolations();
});
```

---

## Performance Considerations

### Code Splitting

Components are automatically code-split when using dynamic imports:

```typescript
const BusinessTechToggle = defineAsyncComponent(
  () => import('./components/BusinessTechToggle.vue')
);
```

### Lazy Loading

For components below the fold:

```vue
<template>
  <Suspense>
    <BusinessTechToggle v-if="visible" />
  </Suspense>
</template>
```

### Bundle Size

| Component | Gzipped Size | Notes |
|-----------|--------------|-------|
| BusinessTechToggle | ~2.1 KB | Minimal dependencies |
| InteractiveDiagram | ~8.4 KB | Includes Mermaid integration |
| ROICalculator | ~3.8 KB | Pure Vue logic |
| VersionSelector | ~2.6 KB | Simple dropdown |
| CodeTabs | ~4.2 KB | Includes syntax highlighting |
| FeatureMatrix | ~5.1 KB | Table rendering logic |

---

## Browser Support

All components support:

- **Modern browsers**: Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- **Mobile**: iOS Safari 14+, Chrome Android 90+
- **Graceful degradation**: Core functionality works without JavaScript
- **Accessibility tools**: NVDA, JAWS, VoiceOver, TalkBack

---

## Migration Guide

### From VitePress Default Components

Replace default code groups:

```diff
- ::: code-group
- ```ts [TypeScript]
- const foo = 'bar';
- ```
- ```py [Python]
- foo = "bar"
- ```
- :::

+ <CodeTabs
+   :tabs="[
+     { lang: 'typescript', label: 'TypeScript', code: 'const foo = \"bar\";' },
+     { lang: 'python', label: 'Python', code: 'foo = \"bar\"' }
+   ]"
+ />
```

---

## Support and Contributing

### Reporting Issues

Found a bug or accessibility issue? Report it:

- **GitHub Issues**: [Project-Ascension/issues](https://github.com/Brookside-Proving-Grounds/Project-Ascension/issues)
- **Email**: Consultations@BrooksideBI.com
- **Phone**: +1 209 487 2047

### Contributing Components

We welcome contributions! Follow these guidelines:

1. **Follow brand voice** - Solution-focused, professional, consultative
2. **Accessibility first** - WCAG 2.1 AA minimum
3. **Type safety** - Full TypeScript interfaces and prop validation
4. **Documentation** - Comprehensive inline comments and usage examples
5. **Testing** - 85%+ test coverage with unit and accessibility tests

### Development Workflow

```bash
# Start documentation dev server
npm run docs:dev

# Run component tests
npm run test

# Check accessibility
npm run test:a11y

# Build for production
npm run docs:build
```

---

## Changelog

### Version 2.0.0 (2025-01-15)

- ✨ Added BusinessTechToggle component with localStorage persistence
- ✨ Added CodeTabs component with multi-language syntax highlighting
- ✨ Added FeatureMatrix component with export functionality
- 🔧 Enhanced InteractiveDiagram with improved touch gesture support
- ♿ Improved keyboard navigation across all components
- 🎨 Updated dark mode color palette for better contrast
- 📚 Created comprehensive component reference documentation

---

**Need help?** Reach out to our team at **Consultations@BrooksideBI.com** or call **+1 209 487 2047** for personalized guidance on implementing these components in your documentation workflow.

---

*Generated with [Agent Studio](https://brookside-proving-grounds.github.io/Project-Ascension/) - Establish sustainable documentation practices that support organizational growth.*
