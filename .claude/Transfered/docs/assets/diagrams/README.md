# Agent Studio Diagram Library

Comprehensive collection of Mermaid diagrams for Agent Studio documentation. All diagrams follow the [Mermaid Standards](./mermaid-standards.md).

## 📁 Diagram Categories

### Architecture Diagrams (8)

**C4 Model Diagrams:**
- [C4 Context](./architecture/c4-context.mmd) - System in environment with external actors
- [C4 Container](./architecture/c4-container.mmd) - Major system containers and technologies
- [C4 Component (Orchestration)](./architecture/c4-component-orchestration.mmd) - Internal components of orchestration API

**System Architecture:**
- [Data Flow - Agent Execution](./architecture/data-flow-agent-execution.mmd) - Detailed agent execution sequence
- [Deployment Topology](./architecture/deployment-topology.mmd) - Azure multi-region deployment
- [Integration Patterns](./architecture/integration-patterns.mmd) - External service integrations
- [Scaling Architecture](./architecture/scaling-architecture.mmd) - Horizontal and vertical scaling
- [Security Architecture](./architecture/security-architecture.mmd) - Multi-layer defense-in-depth

### Workflow Pattern Diagrams (4)

- [Sequential Workflow](./workflows/sequential-workflow.mmd) - Tasks execute one after another
- [Parallel Workflow](./workflows/parallel-workflow.mmd) - Independent tasks run concurrently
- [Saga Pattern](./workflows/saga-pattern.mmd) - Distributed transaction with compensation
- [Event-Driven Workflow](./workflows/event-driven-workflow.mmd) - Reactive event-based orchestration

### Data Flow Diagrams (3)

- [State Management Flow](./data-flows/state-management-flow.mmd) - Checkpoint, recovery, event sourcing
- [Agent Communication Flow](./data-flows/agent-communication-flow.mmd) - Multi-agent coordination via SignalR

### Security Diagrams (1)

- [Authentication Flow](./security/authentication-flow.mmd) - OAuth 2.0 + PKCE with Azure AD

### Database Diagrams (1)

- [Workflow Schema ERD](./database/workflow-schema.mmd) - Complete database schema for workflows

### Deployment Diagrams (1)

- [CI/CD Pipeline](./deployment/cicd-pipeline.mmd) - Complete deployment pipeline with canary releases

### Monitoring Diagrams (1)

- [Observability Architecture](./monitoring/observability-architecture.mmd) - OpenTelemetry + Application Insights

## 📊 Total Diagrams: 19

| Category | Count | Status |
|----------|-------|--------|
| Architecture | 8 | ✅ Complete |
| Workflows | 4 | ✅ Complete |
| Data Flows | 3 | ✅ Complete |
| Security | 1 | ✅ Complete |
| Database | 1 | ✅ Complete |
| Deployment | 1 | ✅ Complete |
| Monitoring | 1 | ✅ Complete |

## 🎨 Diagram Standards

All diagrams follow consistent standards:

- **Color Palette**: Brand-aligned colors (#3eaf7c primary)
- **Semantic Colors**: Success (green), warning (yellow), error (red)
- **Component Colors**: Frontend (#61dafb), Backend (#512bd4), Database (#336791)
- **Agent Layers**: Tactical (#8b5cf6), Strategic (#ec4899), Operational (#06b6d4)
- **Labels**: Clear, descriptive, with technical details
- **Accessibility**: WCAG AA compliant contrast ratios

See [Mermaid Standards](./mermaid-standards.md) for complete guidelines.

## 🚀 Using Diagrams

### In VitePress Documentation

Use the `InteractiveDiagram` component:

```vue
<InteractiveDiagram
  type="mermaid"
  title="System Architecture"
  :diagram="c4ContainerDiagram"
  showZoom
  showFullscreen
  :legend="[
    { color: '#3eaf7c', label: 'Primary System' },
    { color: '#94a3b8', label: 'External System' }
  ]"
/>
```

### Generating PNG/SVG

Use Mermaid CLI:

```bash
# Install Mermaid CLI
npm install -g @mermaid-js/mermaid-cli

# Generate PNG
mmdc -i diagram.mmd -o diagram.png -t default -b transparent

# Generate SVG
mmdc -i diagram.mmd -o diagram.svg -t default
```

### Validating Diagrams

```bash
# Lint all diagrams
npx mermaid-lint docs/assets/diagrams/**/*.mmd

# Check accessibility
npx a11y-audit docs/assets/diagrams/*.png
```

## 📝 Adding New Diagrams

1. **Follow Standards**: Review [Mermaid Standards](./mermaid-standards.md)
2. **Use Templates**: Copy appropriate template from standards guide
3. **Consistent Naming**: Use kebab-case, descriptive names
4. **Add Metadata**: Include title, description, version in file
5. **Update Index**: Add entry to this README
6. **Test Rendering**: Verify diagram renders correctly in VitePress

## 🔍 Diagram Index by Use Case

### For Business Stakeholders
- [C4 Context](./architecture/c4-context.mmd) - High-level system overview
- [Workflow Patterns](./workflows/) - How Agent Studio orchestrates work
- [ROI Documentation](../../guides/business/roi-analysis.md) - Business value

### For Developers
- [C4 Component](./architecture/c4-component-orchestration.mmd) - Internal architecture
- [Agent Communication](./data-flows/agent-communication-flow.mmd) - Multi-agent coordination
- [State Management](./data-flows/state-management-flow.mmd) - Checkpoint and recovery
- [Database Schema](./database/workflow-schema.mmd) - Data model
- [API Documentation](../../api/rest-api.md) - REST API reference

### For DevOps Engineers
- [Deployment Topology](./architecture/deployment-topology.mmd) - Azure infrastructure
- [CI/CD Pipeline](./deployment/cicd-pipeline.mmd) - Build and deployment automation
- [Observability](./monitoring/observability-architecture.mmd) - Monitoring and alerting
- [Scaling Architecture](./architecture/scaling-architecture.mmd) - Auto-scaling configuration

### For Security Engineers
- [Authentication Flow](./security/authentication-flow.mmd) - OAuth 2.0 + PKCE
- [Security Architecture](./architecture/security-architecture.mmd) - Defense-in-depth
- [Integration Patterns](./architecture/integration-patterns.mmd) - Secure external integrations

### For Architects
- [C4 Container](./architecture/c4-container.mmd) - System containers
- [Integration Patterns](./architecture/integration-patterns.mmd) - Integration strategies
- [Scaling Architecture](./architecture/scaling-architecture.mmd) - Scalability patterns
- [Data Flow](./architecture/data-flow-agent-execution.mmd) - End-to-end request flow

## 📚 Related Documentation

- [Architecture Overview](../../architecture/index.md) - Complete architecture documentation
- [Deployment Guide](../../guides/operator/deployment-azure.md) - Azure deployment instructions
- [Developer Guide](../../guides/developer/local-development.md) - Local development setup
- [API Reference](../../api/rest-api.md) - REST API documentation

## 🤝 Contributing

When adding diagrams:
1. Follow the [Mermaid Standards](./mermaid-standards.md)
2. Use semantic versioning in filenames (e.g., `diagram-v2.mmd`)
3. Archive obsolete diagrams with `_archived` suffix
4. Update this index with new diagram entries
5. Test diagrams in VitePress before committing

## 📄 License

All diagrams are licensed under the same license as Agent Studio documentation.

---

*Diagram library maintained by the Agent Studio documentation team*
