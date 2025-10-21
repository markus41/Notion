# Onboarding Checklist

Welcome to the Agent Framework project! Use this checklist to ensure a smooth onboarding experience.

## Week 1: Environment Setup

### Day 1-2: Tools & Access
- [ ] Install development tools
  - [ ] Git
  - [ ] Node.js 18+
  - [ ] .NET 8.0 SDK
  - [ ] Python 3.10+
  - [ ] Docker Desktop
  - [ ] VS Code or preferred IDE
- [ ] Clone the repository
  - [ ] `git clone https://github.com/Brookside-Proving-Grounds/Project-Ascension.git`
- [ ] Request access to:
  - [ ] GitHub repository (write access)
  - [ ] Azure subscription (if applicable)
  - [ ] Slack/Teams channel
  - [ ] CI/CD pipelines

### Day 3-4: Build & Run
- [ ] Build .NET samples
  - [ ] `cd src/dotnet && dotnet build`
  - [ ] Run samples: `dotnet run --project AgentFramework.Samples`
  - [ ] Run tests: `dotnet test`
- [ ] Build Python samples
  - [ ] `cd src/python && pip install -e ".[dev]"`
  - [ ] Run samples: `python examples.py`
  - [ ] Run tests: `pytest`
- [ ] Build webapp
  - [ ] `cd src/webapp && npm install`
  - [ ] Start dev server: `npm run dev`
  - [ ] Open `http://localhost:3000`

### Day 5: Infrastructure
- [ ] Start local infrastructure
  - [ ] `docker-compose up -d`
  - [ ] Verify services are running
  - [ ] Access Jaeger UI: `http://localhost:16686`
- [ ] Review architecture
  - [ ] Read [GETTING_STARTED.md](./GETTING_STARTED.md)
  - [ ] Review project structure
  - [ ] Understand workflow patterns

## Week 2: Codebase Familiarization

### Day 1: Agent Framework
- [ ] Read agent implementation
  - [ ] .NET: `src/dotnet/AgentFramework.Samples/Core/AIAgent.cs`
  - [ ] Python: `src/python/agent_framework/core/agent.py`
- [ ] Understand workflows
  - [ ] Sequential workflow
  - [ ] Concurrent workflow
  - [ ] Group chat workflow
  - [ ] Handoff workflow
- [ ] Explore checkpointing
  - [ ] Superstep checkpointing sample
  - [ ] State persistence

### Day 2-3: Tools
- [ ] Review tool implementations
  - [ ] MCP server: `tools/mcp-server/`
  - [ ] OpenAPI tool: `tools/openapi/`
  - [ ] Code execution: `tools/code-exec/`
  - [ ] Web search: `tools/web-search/`
  - [ ] File I/O: `tools/file-io/`
- [ ] Run tool examples
  - [ ] Test MCP server
  - [ ] Test file I/O security guards

### Day 4-5: Webapp
- [ ] Explore webapp structure
  - [ ] Components: `src/webapp/src/components/`
  - [ ] Pages: `src/webapp/src/pages/`
  - [ ] Routing setup
- [ ] Understand features
  - [ ] React Flow canvas (Design page)
  - [ ] Trace visualization (Traces page)
  - [ ] Agent management (Agents page)
  - [ ] Command palette (Cmd+K)
- [ ] Review configuration files
  - [ ] Agent configs: `agents/*.{json,yaml}`
  - [ ] Workflow configs: `workflows/*.{json,yaml}`

## Week 3: Contributing

### Day 1: Development Workflow
- [ ] Read [CONTRIBUTING.md](../CONTRIBUTING.md)
- [ ] Understand branching strategy
  - [ ] `main` branch for stable releases
  - [ ] `develop` branch for integration
  - [ ] Feature branches: `feature/your-feature-name`
- [ ] Set up pre-commit hooks
  - [ ] Install lint-staged (if configured)
  - [ ] Configure formatters (Prettier, Black, dotnet-format)

### Day 2-3: Testing
- [ ] Write a simple test
  - [ ] .NET: Add test to `AgentFramework.Tests`
  - [ ] Python: Add test to `tests/`
  - [ ] Run test suite
- [ ] Review test coverage
  - [ ] .NET: Use built-in coverage tools
  - [ ] Python: `pytest --cov`
- [ ] Understand CI/CD pipeline
  - [ ] Review GitHub Actions workflows (when added)
  - [ ] Understand quality gates

### Day 4-5: First Contribution
- [ ] Pick a good first issue
  - [ ] Look for `good-first-issue` label
  - [ ] Ask questions in team chat
- [ ] Create a feature branch
  - [ ] `git checkout -b feature/my-first-contribution`
- [ ] Make changes
  - [ ] Follow coding standards
  - [ ] Add tests
  - [ ] Update documentation
- [ ] Submit a pull request
  - [ ] Write clear PR description
  - [ ] Reference related issues
  - [ ] Request review

## Week 4: Specialization

Choose an area to focus on based on your interests:

### Backend Development
- [ ] Deep dive into agent framework internals
- [ ] Implement new workflow patterns
- [ ] Optimize performance
- [ ] Add telemetry

### Frontend Development
- [ ] Enhance webapp UI/UX
- [ ] Implement React Flow features
- [ ] Add D3 visualizations
- [ ] Improve responsive design

### DevOps & Infrastructure
- [ ] Improve Docker setup
- [ ] Configure Kubernetes (if applicable)
- [ ] Set up monitoring
- [ ] Optimize CI/CD

### Security
- [ ] Review [THREAT_MODEL.md](./THREAT_MODEL.md)
- [ ] Conduct security testing
- [ ] Implement security controls
- [ ] Document security procedures

### Documentation
- [ ] Improve getting started guide
- [ ] Write tutorials
- [ ] Create architecture diagrams
- [ ] Document APIs

## Continuous Learning

- [ ] Attend team meetings
- [ ] Participate in code reviews
- [ ] Ask questions
- [ ] Share knowledge
- [ ] Stay updated on project changes

## Resources

### Documentation
- [Getting Started](./GETTING_STARTED.md)
- [Threat Model](./THREAT_MODEL.md)
- [Architecture Decisions](./adrs/)

### External Links
- [Microsoft Agentic Framework](https://github.com/microsoft/autogen)
- [React Flow Documentation](https://reactflow.dev/)
- [OpenTelemetry](https://opentelemetry.io/)

### Communication
- GitHub Issues: Questions, bugs, feature requests
- GitHub Discussions: General discussions
- Team Chat: Quick questions, daily updates

## Need Help?

Don't hesitate to reach out!

- **Technical Questions**: Open a GitHub Discussion
- **Blockers**: Mention in team chat
- **Security Issues**: Email security@example.com

---

**Welcome aboard! 🚀**
