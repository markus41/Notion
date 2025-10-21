# Interactive Components

Establish world-class interactive experiences to streamline developer workflows and knowledge discovery. These components are designed to drive measurable improvements in documentation engagement and learning outcomes.

**Best for:** Organizations seeking to enhance technical documentation with hands-on interactive elements

---

## CodePlayground

An interactive code editor with multi-language support, real-time execution, and console output. Enables hands-on experimentation directly within documentation pages.

### Features

- **Multi-Language Support**: TypeScript, JavaScript, Python, C#, JSON, YAML
- **Syntax Highlighting**: Real-time code highlighting with language-specific patterns
- **Code Execution**:
  - JavaScript/TypeScript: In-browser execution with console output
  - Python: Redirects to Replit playground
  - C#: Redirects to .NET Fiddle
  - JSON/YAML: Validation and formatting
- **Resizable Panes**: Drag to adjust editor/console split
- **Code Management**: Copy, reset, share via URL
- **Fullscreen Mode**: Expanded view for focused coding
- **Keyboard Navigation**: Full keyboard accessibility
- **Console Output**: Real-time logging with log levels
- **Mobile Responsive**: Adapts to mobile devices

### Basic Usage

```vue
<CodePlayground
  :files="[
    {
      name: 'example.ts',
      language: 'typescript',
      content: 'console.log(\"Hello, Agent Studio!\");'
    }
  ]"
  :runnable="true"
/>
```

### Multi-File Playground

```vue
<CodePlayground
  :files="[
    {
      name: 'agent.ts',
      language: 'typescript',
      content: `interface Agent {
  id: string;
  name: string;
  execute(): Promise<string>;
}

class ArchitectAgent implements Agent {
  constructor(public id: string, public name: string) {}

  async execute(): Promise<string> {
    return \`Agent \${this.name} executing...\`;
  }
}

const agent = new ArchitectAgent('001', 'Architect');
console.log(await agent.execute());`
    },
    {
      name: 'workflow.yaml',
      language: 'yaml',
      content: `name: Code Generation Workflow
version: 1.0
pattern: sequential
tasks:
  - id: architect
    agent: architect-agent
    input: "Design system architecture"
  - id: builder
    agent: builder-agent
    depends_on: architect
    input: "Implement design"`
    },
    {
      name: 'config.json',
      language: 'json',
      content: `{
  "workflow": {
    "maxRetries": 3,
    "timeout": 300,
    "checkpointing": {
      "enabled": true,
      "frequency": "perTask"
    }
  }
}`
    }
  ]"
  :activeFile="0"
  :runnable="true"
  height="600px"
/>
```

### Python Example

```vue
<CodePlayground
  :files="[
    {
      name: 'agent.py',
      language: 'python',
      content: `from typing import Protocol

class Agent(Protocol):
    \"\"\"Base agent interface\"\"\"

    async def execute(self, input_data: str) -> str:
        ...

class ArchitectAgent:
    \"\"\"Architect meta-agent for system design\"\"\"

    def __init__(self, agent_id: str, name: str):
        self.id = agent_id
        self.name = name

    async def execute(self, input_data: str) -> str:
        print(f"Agent {self.name} processing: {input_data}")
        return f"Architecture design for: {input_data}"

# Create and execute agent
agent = ArchitectAgent("001", "Architect")
result = await agent.execute("E-commerce platform")
print(result)`
    }
  ]"
  :runnable="true"
/>
```

### Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `files` | `CodeFile[]` | required | Array of code files to display |
| `activeFile` | `number` | `0` | Index of initially active file |
| `runnable` | `boolean` | `true` | Enable code execution |
| `height` | `string` | `'500px'` | Height of playground container |

### CodeFile Interface

```typescript
interface CodeFile {
  /** File name with extension */
  name: string
  /** Programming language identifier */
  language: string
  /** Initial code content */
  content: string
}
```

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Tab` | Insert 2 spaces (in editor) |
| `Arrow Left/Right` | Navigate between file tabs |
| `Home` | Jump to first tab |
| `End` | Jump to last tab |
| `Escape` | Exit fullscreen mode |

### Accessibility

- Full keyboard navigation support
- ARIA labels and roles
- Screen reader announcements for console output
- Focus management
- High contrast mode support
- Reduced motion support

---

## NavigationMega

A comprehensive mega menu navigation system with search, hierarchical organization, and visual categorization. Designed for large documentation sites requiring structured multi-level navigation.

### Features

- **Hierarchical Structure**: Organize content into sections and categories
- **Search Integration**: Real-time search across all sections and links
- **Visual Categorization**: Icons, badges, and descriptions
- **Keyboard Navigation**: Full keyboard accessibility
- **Responsive Design**: Mobile-friendly slide panel
- **Footer Actions**: Additional quick links
- **Focus Management**: Automatic focus handling
- **Smooth Animations**: Slide-in panel with overlay

### Basic Usage

```vue
<NavigationMega
  :showSearch="true"
  :showFooter="true"
/>
```

### Custom Sections

```vue
<NavigationMega
  :sections="[
    {
      title: 'Getting Started',
      icon: '🚀',
      description: 'Begin your journey with Agent Studio',
      keywords: ['start', 'begin', 'intro'],
      links: [
        {
          href: '/quick-start',
          title: 'Quick Start',
          description: 'Get up and running in 5 minutes',
          keywords: ['quick', 'tutorial'],
          badge: { text: 'Popular', type: 'success' }
        },
        {
          href: '/installation',
          title: 'Installation',
          description: 'Install Agent Studio',
          keywords: ['install', 'setup']
        }
      ]
    },
    {
      title: 'API Reference',
      icon: '⚙️',
      description: 'Complete API documentation',
      keywords: ['api', 'reference'],
      badge: { text: 'New', type: 'info' },
      links: [
        {
          href: '/api/rest',
          title: 'REST API',
          description: 'RESTful API endpoints',
          keywords: ['rest', 'http']
        },
        {
          href: '/api/signalr',
          title: 'SignalR Hub',
          description: 'Real-time communication',
          keywords: ['signalr', 'realtime']
        }
      ]
    }
  ]"
  :showSearch="true"
  :showFooter="true"
/>
```

### Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `sections` | `NavigationSection[]` | Default sections | Navigation sections to display |
| `showSearch` | `boolean` | `true` | Show search bar |
| `showFooter` | `boolean` | `true` | Show footer with quick links |
| `initialOpen` | `boolean` | `false` | Initial open state |

### NavigationSection Interface

```typescript
interface NavigationSection {
  /** Section title */
  title: string
  /** Section icon (emoji) */
  icon: string
  /** Section description */
  description?: string
  /** Section links */
  links: NavigationLink[]
  /** Optional section badge */
  badge?: Badge
  /** Keywords for search */
  keywords?: string[]
}

interface NavigationLink {
  /** Link URL */
  href: string
  /** Link title */
  title: string
  /** Link description */
  description?: string
  /** Optional badge */
  badge?: Badge
  /** Keywords for search */
  keywords?: string[]
}

interface Badge {
  /** Badge text content */
  text: string
  /** Badge visual type */
  type: 'primary' | 'success' | 'warning' | 'danger' | 'info'
}
```

### Default Sections

The component includes comprehensive default sections:

1. **Getting Started** - Quick start, installation, first agent, architecture
2. **Guides** - Business value, development, deployment, patterns
3. **API Reference** - REST API, SignalR Hub, Python SDK, .NET SDK
4. **Concepts** - Meta-agents, workflows, state management, observability
5. **Examples** - Code generation, data processing, customer support, research
6. **Resources** - Templates, tools, integrations, community

### Search Functionality

The search feature filters across:
- Section titles and descriptions
- Section keywords
- Link titles and descriptions
- Link keywords

Search is case-insensitive and supports partial matching.

### Badge Types

| Type | Color | Use Case |
|------|-------|----------|
| `primary` | Purple | Standard badges |
| `success` | Green | Popular/recommended items |
| `warning` | Orange | Beta/experimental features |
| `danger` | Red | Deprecated items |
| `info` | Blue | New features |

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Escape` | Close menu |
| `Tab` | Navigate through links |
| Focus is automatically managed on open/close |

### Accessibility

- Full ARIA implementation
- Keyboard navigation
- Focus trap when open
- Screen reader support
- High contrast mode
- Reduced motion support
- Body scroll lock when open

---

## Best Practices

### CodePlayground

1. **Keep Examples Focused**: Each playground should demonstrate one concept
2. **Provide Context**: Use file names and descriptions to explain the code
3. **Test Code**: Ensure example code runs successfully
4. **Mobile Consideration**: Test on mobile devices for usability
5. **Performance**: Limit playground complexity for better performance

### NavigationMega

1. **Logical Organization**: Group related content in sections
2. **Clear Descriptions**: Write concise, descriptive link descriptions
3. **Search Keywords**: Include relevant keywords for better search
4. **Badge Usage**: Use badges sparingly for important highlights
5. **Footer Links**: Include frequently accessed quick links

---

## Examples in Documentation

### Tutorial Page

```markdown
# Building Your First Agent

Follow along with this interactive tutorial to create your first AI agent.

<CodePlayground
  :files="[
    {
      name: 'agent.ts',
      language: 'typescript',
      content: '// Your code here...'
    }
  ]"
  :runnable="true"
/>
```

### API Reference Page

```markdown
# REST API Reference

Explore our comprehensive API documentation.

<NavigationMega
  :sections="apiSections"
  :showSearch="true"
/>
```

---

## Styling Customization

Both components use CSS variables for theming and can be customized via the theme system:

```css
:root {
  --vp-c-brand: #8b5cf6;
  --vp-c-brand-dark: #7c3aed;
  --glass-bg: rgba(255, 255, 255, 0.7);
  --elevation-3: 0 10px 20px rgba(0, 0, 0, 0.15);
}
```

---

## Performance Considerations

### CodePlayground

- Syntax highlighting is regex-based for performance
- Code execution is sandboxed
- Large files may impact performance
- Consider lazy-loading for multiple playgrounds

### NavigationMega

- Search is debounced for performance
- Content is only rendered when open
- Virtual scrolling not implemented (consider for very large lists)
- Backdrop blur may impact older devices

---

## Browser Support

Both components support:
- Chrome/Edge 90+
- Firefox 88+
- Safari 14+
- Mobile browsers (iOS Safari, Chrome Mobile)

Features gracefully degrade on older browsers.

---

## Related Components

- **CodeTabs** - Multi-language code examples without execution
- **InteractiveDiagram** - Interactive architecture diagrams
- **ThemeCustomizer** - Theme customization panel

---

For questions or support, consult our [support documentation](/support) or [contact the team](mailto:Consultations@BrooksideBI.com).
