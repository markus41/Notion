# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Agent Studio** is a cloud-native Azure SaaS platform for building, deploying, and managing AI agents using Microsoft's Agentic Framework. This is a **monorepo** containing Python meta-agents, .NET orchestration services, React frontend, and Azure infrastructure.

## Build & Development Commands

### Frontend (React + TypeScript + Vite)
```bash
cd webapp
npm install              # Install dependencies
npm run dev              # Start dev server (http://localhost:5173)
npm run build            # Build for production
npm test                 # Run tests (Vitest)
npm run test:coverage    # Run tests with coverage
npm run lint             # Lint code
npm run type-check       # TypeScript type checking
```

### .NET Orchestration Service
```bash
cd services/dotnet

# Restore and build
dotnet restore
dotnet build --configuration Release

# Run the API
dotnet run --project AgentStudio.Api

# Run tests
dotnet test
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=html

# Run specific test project
dotnet test services/dotnet/AgentStudio.Orchestration.Tests/
```

### Python Meta-Agents Service
```bash
cd src/python

# Install dependencies
pip install -e ".[test]"

# Run FastAPI service
uvicorn meta_agents.api:app --reload --port 8000

# Run tests
pytest
pytest --cov=meta_agents --cov-report=html
pytest -m unit              # Unit tests only
pytest -m integration       # Integration tests only
pytest -n auto              # Parallel execution
```

### E2E Tests (Playwright)
```bash
cd tests/e2e
npx playwright install
npx playwright test
npx playwright test --ui    # Interactive mode
```

### Infrastructure Deployment
```bash
cd infra

# Validate Bicep templates
az bicep build --file deploy.bicep
./validate.sh

# Deploy to environment
az deployment sub create \
  --location eastus \
  --template-file deploy.bicep \
  --parameters environment=dev

# Or use deployment script
./deploy.sh dev
```

### Makefile Commands
The root Makefile provides convenient shortcuts:
```bash
make help           # Show all available targets
make install        # Install all dependencies
make build          # Build all services
make test           # Run all tests
make lint           # Lint all code
make clean          # Clean build artifacts

# Development servers
make dev-webapp     # Start webapp dev server
make dev-python     # Start Python service
make dev-dotnet     # Start .NET service
```

## Architecture Overview

### Three-Layer Architecture

1. **Frontend Layer (React)**
   - Location: `webapp/`
   - Tech: React 19, TypeScript, Vite, Tailwind CSS
   - Pages: Design, Traces, Agents, Assets, Settings
   - Real-time updates via SignalR

2. **Orchestration Layer (.NET)**
   - Location: `services/dotnet/AgentStudio.Orchestration/`
   - Tech: ASP.NET Core 8, C#
   - Components:
     - `MetaAgentOrchestrator`: Main workflow coordination engine
     - `WorkflowExecutor`: Executes workflows (Sequential, Parallel, Iterative, Dynamic)
     - `StateManager`: Cosmos DB state persistence with checkpointing
     - `PythonAgentClient`: HTTP client with retry/circuit breaker
     - `MetaAgentHub`: SignalR real-time communication hub
   - Patterns: Circuit breaker, retry with exponential backoff, optimistic concurrency

3. **Agent Execution Layer (Python)**
   - Location: `src/python/meta_agents/`
   - Tech: Python 3.12, FastAPI
   - Agent Types: Architect, Builder, Validator, Scribe
   - Features: Azure OpenAI integration, streaming responses, LLM mocking for tests

### Key Workflow Patterns

**Sequential**: Tasks execute in order (step-1 → step-2 → step-3)
**Parallel**: Independent tasks run concurrently with dependency management
**Iterative**: Loop with validator feedback until completion (max retries configurable)
**Dynamic**: Runtime-determined execution with agent handoffs

### State Management

- **Cosmos DB Containers**:
  - `workflows`: Workflow execution state
  - `checkpoints`: Recovery checkpoints
  - `thread-message-store`: Agent conversations
  - `agent-entity-store`: Agent configurations

- **Checkpointing**: Automatic checkpoints after each task, with manual/failure/paused types
- **Recovery**: Resume from latest checkpoint or specific checkpoint ID

### Real-time Communication (SignalR)

- Hub endpoint: `/hubs/meta-agent`
- Events: `ReceiveAgentThought`, `ReceiveProgress`, `ReceiveTaskStarted`, `ReceiveTaskCompleted`, `ReceiveWorkflowStarted`, etc.
- Client methods: `SubscribeToWorkflow(workflowId)`, `UnsubscribeFromWorkflow(workflowId)`

## Testing Strategy

### Coverage Target: 85%+

**Python Tests** (pytest):
- Location: `src/python/tests/`
- Run: `pytest --cov=meta_agents --cov-report=html`
- Features: Async support, mocked LLM responses, parametrized tests
- Markers: `-m unit`, `-m integration`, `-m "not slow"`

**.NET Tests** (xUnit):
- Location: `services/dotnet/AgentStudio.Orchestration.Tests/`
- Run: `dotnet test /p:CollectCoverage=true`
- Tools: Moq for mocking, FluentAssertions for assertions
- Tests: `PythonAgentClientTests`, `MetaAgentOrchestratorTests`, `WorkflowExecutorTests`, `StateManagerTests`

**React Tests** (Vitest):
- Location: `webapp/src/**/__tests__/`
- Run: `npm test` or `npm run test:coverage`
- Tools: React Testing Library, MSW for API mocking
- Coverage thresholds: 85% lines, functions, branches, statements

**Integration Tests**:
- Python ↔ .NET integration tests
- SignalR real-time communication tests

**E2E Tests** (Playwright):
- Location: `tests/e2e/`
- Run: `npx playwright test`
- Full user workflows including agent handoffs

### Test Execution Best Practices

- Always mock LLM API calls in tests (no real API costs)
- Use `pytest -n auto` for parallel Python test execution
- Run `pytest --lf` to rerun last failed tests
- Use `dotnet test --filter` to run specific .NET test classes
- Run `npm test -- --changed` to test only modified React files

## Azure Infrastructure

### Core Services (Always Deployed)
- **Resource Group**: `{projectName}-{environment}-rg`
- **Key Vault**: Secrets management with RBAC
- **Container Registry**: Docker images for all services
- **Application Insights**: Telemetry, logs, distributed tracing
- **Cosmos DB**: Serverless, three containers (workflows, checkpoints, threads)
- **Storage Account**: Checkpoint backups

### Agent Platform Services (Configurable)
- **Azure OpenAI**: GPT-4 (10 TPM), GPT-3.5-Turbo (30 TPM), text-embedding-ada-002 (120 TPM)
- **Azure AI Search**: Vector database for agent memory, semantic search
- **SignalR Service**: Real-time communication (Free tier dev, Standard S1 staging/prod)
- **Redis Cache**: Distributed caching, session state (Standard C1 dev, Premium P1 prod)

### Runtime Deployment Options
- **App Service**: Simpler, less features
- **Container Apps**: Recommended, auto-scaling, health probes
- **None**: Infrastructure only (manual deployment)

### Deployment Parameters
```bash
projectName=ascension           # Resource name prefix
environment=dev|staging|prod    # Environment type
runtimeType=appservice|containerapps|none
enableVNet=true|false          # Virtual network (recommended staging/prod)
enableOpenAI=true|false        # Azure OpenAI deployment
enableAISearch=true|false      # Azure AI Search deployment
enableSignalR=true|false       # SignalR Service
enableRedis=true|false         # Redis Cache
```

### Secrets Management
```bash
# Set all secrets
./infra/scripts/set-secrets.sh <key-vault-name>

# Individual secret
az keyvault secret set --vault-name <kv-name> --name <secret-name> --value <value>

# Reference in app
@Microsoft.KeyVault(SecretUri=https://<vault-name>.vault.azure.net/secrets/<secret-name>/)
```

### Observability
- **OTEL Collector**: `infra/observability/otel-collector-config.yaml`
- **Dashboards**: Performance and SLO workbooks in `infra/observability/`
- **Alerts**: Availability SLO (<99.9%), error spikes, high latency, token cost anomalies

## Project Structure Notes

### Key Directories
- `webapp/`: React frontend application
- `services/dotnet/`: .NET orchestration service with 4 projects (Api, Data, Orchestration, Tests)
- `src/python/`: Python meta-agents service (FastAPI)
- `infra/`: Azure Bicep templates and deployment scripts
- `tests/e2e/`: Playwright end-to-end tests
- `docs/`: Comprehensive documentation
- `.github/workflows/`: CI/CD pipelines (ci.yml, containers.yml, deploy.yml, release.yml)

### Important Configuration Files
- `webapp/vite.config.ts`: Vite build configuration
- `webapp/vitest.config.ts`: Test configuration with coverage thresholds
- `src/python/pyproject.toml`: Python dependencies and build config
- `src/python/pytest.ini`: Pytest configuration
- `services/dotnet/AgentStudio.sln`: .NET solution file
- `infra/deploy.bicep`: Main infrastructure template
- `docker-compose.yml`: Local development stack

### Documentation Files to Reference
- `TESTING.md`: Comprehensive testing guide
- `TEST_COMMANDS.md`: Quick reference for test commands
- `ARCHITECTURE.md`: System architecture visualization
- `QUICKSTART.md`: 5-minute setup guide
- `infra/README.md`: Infrastructure deployment guide
- `services/dotnet/AgentStudio.Orchestration/README.md`: Orchestration layer details

## Development Workflow

### Starting Local Development
```bash
# Option 1: Individual services
make dev-webapp     # Terminal 1: Frontend (http://localhost:5173)
make dev-python     # Terminal 2: Python API (http://localhost:8000)
make dev-dotnet     # Terminal 3: .NET API (http://localhost:5000)

# Option 2: Docker Compose
docker-compose up -d
# Access:
# - Jaeger UI: http://localhost:16686
# - Grafana: http://localhost:3001
# - Webapp: http://localhost:3000
```

### Running Single Tests
```bash
# Python
pytest tests/unit/test_architect_agent.py::TestArchitectAgent::test_specific_method -v

# .NET
dotnet test --filter "FullyQualifiedName~PythonAgentClientTests.ExecuteTaskAsync_Success"

# React
npm test -- useMetaAgents.test.ts
```

### Pre-commit Checks
```bash
# Install pre-commit hooks
pip install pre-commit
pre-commit install

# Run manually
pre-commit run --all-files
```

### Commit Convention (Conventional Commits)
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `test:` - Adding/updating tests
- `refactor:` - Code refactoring
- `chore:` - Maintenance tasks

## Common Tasks

### Adding a New Python Agent
1. Create agent class in `src/python/meta_agents/`
2. Inherit from `BaseAgent`
3. Implement `process()` method with `@trace_agent_operation` decorator
4. Add tests in `src/python/tests/unit/test_<agent>_agent.py`
5. Register in FastAPI routes

### Adding a New .NET Workflow Pattern
1. Add pattern enum to `WorkflowPattern`
2. Implement execution logic in `WorkflowExecutor`
3. Add checkpoint creation points
4. Add tests in `WorkflowExecutorTests.cs`

### Adding a New React Page
1. Create component in `webapp/src/pages/`
2. Add route in `App.tsx`
3. Create tests in `webapp/src/pages/__tests__/`
4. Add to navigation if needed

### Updating Infrastructure
1. Modify Bicep files in `infra/modules/`
2. Update `infra/deploy.bicep` if needed
3. Run `az bicep build --file deploy.bicep` to validate
4. Test deployment: `./infra/validate.sh`
5. Deploy to dev: `./infra/deploy.sh dev`

## Troubleshooting

### Common Issues

**Tests Failing with Module Not Found**
```bash
# Python
pip install -e ".[test]"

# React
cd webapp && npm install

# .NET
dotnet restore
```

**Async Tests Timeout**
```python
@pytest.mark.timeout(60)  # Increase timeout
async def test_long_operation():
    pass
```

**ETag Mismatch (Cosmos DB Concurrency)**
- This is expected with optimistic concurrency
- Reload workflow state and retry operation
- Check for concurrent modifications

**SignalR Connection Issues**
- Verify SignalR service is running
- Check CORS configuration
- Implement client reconnection logic

**High Cosmos DB Costs**
- Adjust checkpoint expiration in config
- Monitor checkpoint cleanup service (runs every 6 hours)
- Review checkpoint creation frequency

## Agent Registry

Always check the specialized agent registry for tasks:
- `code-generator-python`: Python code generation with FastAPI/Pydantic patterns
- `typescript-code-generator`: TypeScript/React code generation
- `test-engineer`: Comprehensive test coverage generation
- `senior-reviewer`: Code quality assessment
- `database-architect`: Database schema design and optimization
- `devops-automator`: CI/CD pipelines, infrastructure automation
- `architect-supreme`: System architecture design and ADRs
- `frontend-engineer`: React/UI component implementation
- `security-specialist`: Security audits and vulnerability assessment

Use the Task tool with appropriate subagent_type to leverage these specialists.

## Performance Considerations

- Use `WorkflowPattern.Parallel` for independent tasks
- Configure checkpoint frequency to balance recovery vs. storage costs
- Use Azure SignalR Service for scale-out (multi-instance support)
- Implement connection pooling for Cosmos DB and HTTP clients
- All async operations - no blocking calls
- Redis caching for frequently accessed data

## Security Notes

- API keys in Key Vault, never in code
- Use managed identities for Azure service authentication
- CORS configuration restricted to allowed origins
- Input validation on all API endpoints
- RBAC for Key Vault access (Key Vault Secrets User role)
- Consider rate limiting middleware for production
