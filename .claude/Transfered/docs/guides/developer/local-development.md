---
title: Local Development Setup
description: Establish a productive local development environment for Agent Studio. Complete guide to building, testing, and deploying agent workflows on your machine.
tags:
  - development
  - setup
  - local
  - environment
  - developer-guide
lastUpdated: 2025-10-09
author: Agent Studio Platform Team
audience: developers
---

# Local Development Setup

**Best for:** Developers building and testing agent workflows, contributing to the platform, or customizing Agent Studio for organizational needs.

This guide establishes a complete local development environment that enables rapid iteration, comprehensive testing, and reliable deployment of agent solutions.

## Prerequisites

### Required Software

| Tool | Version | Purpose |
|------|---------|---------|
| **Node.js** | 20.x or later | Frontend development and tooling |
| **Python** | 3.12 or later | Agent service development |
| **.NET SDK** | 8.0 or later | Orchestration service development |
| **Git** | 2.40+ | Version control |
| **VS Code** | Latest | Recommended IDE |

### Optional Tools

| Tool | Purpose |
|------|---------|
| **Docker Desktop** | Containerization and local service dependencies |
| **Azure CLI** | Azure resource management |
| **GitHub CLI** | Enhanced Git workflows |
| **Postman/Insomnia** | API testing |

### Azure Resources (for full integration)

- **Azure OpenAI Service** with deployed models (GPT-4, GPT-3.5-Turbo)
- **Cosmos DB Account** (or use local Cosmos DB emulator)
- **Azure Key Vault** for secrets management
- **Application Insights** for telemetry

## Quick Start (5 Minutes)

### 1. Clone Repository

```bash
git clone https://github.com/Brookside-Proving-Grounds/Project-Ascension.git
cd Project-Ascension
```

### 2. Install Dependencies

```bash
# Frontend
cd webapp
npm install
cd ..

# Python service
cd src/python
pip install -e ".[dev]"
cd ../..

# .NET service
cd services/dotnet
dotnet restore
cd ../..

# Pre-commit hooks
pip install pre-commit
pre-commit install
```

### 3. Configure Environment

Create `.env` files for each service (see [Configuration](#configuration) section below).

### 4. Start Services

```bash
# Terminal 1: Frontend
cd webapp && npm run dev

# Terminal 2: Python service
cd src/python && uvicorn meta_agents.api:app --reload

# Terminal 3: .NET service
cd services/dotnet && dotnet run --project AgentStudio.Api
```

### 5. Access Applications

- **Frontend**: http://localhost:5173
- **Python API**: http://localhost:8000 (docs at /docs)
- **.NET API**: http://localhost:5000 (Swagger at /swagger)

## Detailed Setup Instructions

### Frontend (React + TypeScript + Vite)

**Install Dependencies:**

```bash
cd webapp
npm install
```

**Configuration:**

Create `webapp/.env.local`:

```env
# API endpoints
VITE_API_BASE_URL=http://localhost:5000
VITE_PYTHON_API_URL=http://localhost:8000

# SignalR hub
VITE_SIGNALR_HUB_URL=http://localhost:5000/hubs/meta-agent

# Feature flags
VITE_ENABLE_TRACING=true
VITE_ENABLE_COST_TRACKING=true

# Environment
VITE_ENVIRONMENT=development
```

**Development Server:**

```bash
npm run dev
```

Starts Vite dev server with hot module replacement at http://localhost:5173.

**Build for Production:**

```bash
npm run build
npm run preview  # Preview production build
```

**Linting and Formatting:**

```bash
npm run lint        # ESLint
npm run lint:fix    # Auto-fix issues
npm run format      # Prettier formatting
npm run type-check  # TypeScript type checking
```

**Testing:**

```bash
npm test                # Run tests with Vitest
npm run test:ui         # Interactive test UI
npm run test:coverage   # Generate coverage report
```

### Python Service (FastAPI)

**Install Dependencies:**

```bash
cd src/python
pip install -e ".[dev]"
```

This installs the package in editable mode with development dependencies (pytest, ruff, mypy, etc.).

**Configuration:**

Create `src/python/.env`:

```env
# Azure OpenAI
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_API_KEY=your-api-key
AZURE_OPENAI_API_VERSION=2024-02-15-preview
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4

# Application
LOG_LEVEL=INFO
ENVIRONMENT=development
ENABLE_TRACING=true

# Optional: Cosmos DB (for state persistence)
COSMOS_DB_ENDPOINT=https://your-account.documents.azure.com:443/
COSMOS_DB_KEY=your-key
COSMOS_DB_DATABASE=agent-studio
```

**Development Server:**

```bash
uvicorn meta_agents.api:app --reload --port 8000
```

- `--reload`: Auto-reload on code changes
- `--port 8000`: Run on port 8000

**API Documentation:**

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

**Linting and Type Checking:**

```bash
ruff check src/         # Linting
ruff format src/        # Formatting
mypy src/               # Type checking
```

**Testing:**

```bash
pytest                          # Run all tests
pytest tests/unit/              # Unit tests only
pytest tests/integration/       # Integration tests only
pytest --cov=meta_agents        # With coverage
pytest -n auto                  # Parallel execution
pytest -v --lf                  # Re-run last failed
```

### .NET Service (ASP.NET Core)

**Restore Dependencies:**

```bash
cd services/dotnet
dotnet restore
```

**Configuration:**

Create `services/dotnet/AgentStudio.Api/appsettings.Development.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "ConnectionStrings": {
    "CosmosDb": "AccountEndpoint=https://localhost:8081/;AccountKey=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
  },
  "AzureOpenAI": {
    "Endpoint": "https://your-resource.openai.azure.com/",
    "ApiKey": "your-api-key",
    "DeploymentName": "gpt-4"
  },
  "PythonAgent": {
    "BaseUrl": "http://localhost:8000"
  },
  "SignalR": {
    "Enabled": true
  },
  "ApplicationInsights": {
    "ConnectionString": "InstrumentationKey=00000000-0000-0000-0000-000000000000"
  }
}
```

**Development Server:**

```bash
dotnet run --project AgentStudio.Api
```

Or for hot reload:

```bash
dotnet watch --project AgentStudio.Api
```

**Build:**

```bash
dotnet build
dotnet build --configuration Release
```

**Testing:**

```bash
dotnet test                                      # Run all tests
dotnet test --filter FullyQualifiedName~WorkflowExecutor  # Specific tests
dotnet test /p:CollectCoverage=true             # With coverage
dotnet test --logger "console;verbosity=detailed"  # Verbose output
```

**Code Quality:**

```bash
dotnet format                # Format code
dotnet build -warnaserror   # Treat warnings as errors
```

## Using Docker Compose

For simplified local development with all dependencies:

**Start All Services:**

```bash
docker-compose up -d
```

This starts:
- Frontend (http://localhost:3000)
- Python API (http://localhost:8000)
- .NET API (http://localhost:5000)
- Cosmos DB Emulator
- Jaeger (tracing at http://localhost:16686)
- Grafana (metrics at http://localhost:3001)

**View Logs:**

```bash
docker-compose logs -f              # All services
docker-compose logs -f webapp       # Specific service
```

**Stop Services:**

```bash
docker-compose down
docker-compose down -v  # Also remove volumes
```

**Rebuild After Changes:**

```bash
docker-compose up -d --build
```

## Configuration Management

### Environment Variables

**Frontend (`webapp/.env.local`):**

```env
VITE_API_BASE_URL=http://localhost:5000
VITE_PYTHON_API_URL=http://localhost:8000
VITE_SIGNALR_HUB_URL=http://localhost:5000/hubs/meta-agent
VITE_ENVIRONMENT=development
```

**Python (`src/python/.env`):**

```env
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_API_KEY=your-api-key
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4
LOG_LEVEL=INFO
ENVIRONMENT=development
```

**.NET (`services/dotnet/AgentStudio.Api/appsettings.Development.json`):**

See full example in [.NET Service Configuration](#net-service-aspnet-core) above.

### User Secrets (.NET)

For sensitive data, use .NET user secrets instead of appsettings:

```bash
cd services/dotnet/AgentStudio.Api

dotnet user-secrets init
dotnet user-secrets set "AzureOpenAI:ApiKey" "your-api-key"
dotnet user-secrets set "ConnectionStrings:CosmosDb" "your-connection-string"
dotnet user-secrets list  # View all secrets
```

### Azure Key Vault (Production)

Reference secrets from Key Vault in production:

```json
{
  "AzureOpenAI": {
    "ApiKey": "@Microsoft.KeyVault(SecretUri=https://your-vault.vault.azure.net/secrets/openai-key/)"
  }
}
```

## Development Workflow

### Creating a Feature Branch

```bash
git checkout -b feature/add-new-agent-type
```

### Making Changes

1. **Edit code** in your preferred IDE
2. **Run tests** to verify changes:

```bash
# Frontend
cd webapp && npm test

# Python
cd src/python && pytest

# .NET
cd services/dotnet && dotnet test
```

3. **Lint and format**:

```bash
# Frontend
npm run lint:fix && npm run format

# Python
ruff check --fix src/ && ruff format src/

# .NET
dotnet format
```

### Committing Changes

Pre-commit hooks automatically run linting and formatting:

```bash
git add .
git commit -m "feat: Add new agent type for data validation"
```

Use [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `test:` Tests
- `refactor:` Code refactoring
- `chore:` Maintenance

### Running Tests

**All Tests:**

```bash
# Using Makefile (from repo root)
make test

# Or individually
cd webapp && npm test
cd src/python && pytest
cd services/dotnet && dotnet test
```

**Specific Test Suites:**

```bash
# Frontend: Specific component
npm test -- AgentCard.test.tsx

# Python: Specific test file
pytest tests/unit/test_architect_agent.py

# .NET: Specific test class
dotnet test --filter FullyQualifiedName~WorkflowExecutorTests
```

### Debugging

**Frontend (VS Code):**

`.vscode/launch.json` for Chrome debugging:

```json
{
  "type": "chrome",
  "request": "launch",
  "name": "Debug Frontend",
  "url": "http://localhost:5173",
  "webRoot": "${workspaceFolder}/webapp/src"
}
```

**Python (VS Code):**

```json
{
  "name": "Debug Python API",
  "type": "python",
  "request": "launch",
  "module": "uvicorn",
  "args": ["meta_agents.api:app", "--reload"],
  "cwd": "${workspaceFolder}/src/python"
}
```

**.NET (VS Code):**

```json
{
  "name": "Debug .NET API",
  "type": "coreclr",
  "request": "launch",
  "program": "${workspaceFolder}/services/dotnet/AgentStudio.Api/bin/Debug/net8.0/AgentStudio.Api.dll",
  "cwd": "${workspaceFolder}/services/dotnet/AgentStudio.Api"
}
```

## Troubleshooting

### Port Already in Use

```bash
# Kill process on port (Linux/Mac)
lsof -ti:5173 | xargs kill -9

# Windows
netstat -ano | findstr :5173
taskkill /PID <pid> /F
```

### Module Not Found Errors

```bash
# Reinstall dependencies
cd webapp && npm install
cd src/python && pip install -e ".[dev]"
cd services/dotnet && dotnet restore
```

### Python Import Errors

Ensure you installed the package in editable mode:

```bash
cd src/python
pip install -e ".[dev]"
```

### .NET Build Errors

Clean and rebuild:

```bash
cd services/dotnet
dotnet clean
dotnet restore
dotnet build
```

### Docker Issues

```bash
# Rebuild containers
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

### Cosmos DB Emulator Connection Issues

If using local Cosmos DB emulator:

1. Ensure emulator is running
2. Accept the self-signed certificate
3. Use the default connection string:

```
AccountEndpoint=https://localhost:8081/;AccountKey=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==
```

## Best Practices

### Code Organization

- Keep components small and focused (single responsibility)
- Use consistent naming conventions
- Write self-documenting code with clear variable names
- Add comments for complex logic only

### Testing

- Write tests for all new features
- Aim for 85%+ code coverage
- Use test-driven development (TDD) where appropriate
- Mock external dependencies (Azure OpenAI, Cosmos DB)

### Git Workflow

- Create feature branches from `main`
- Keep commits atomic and well-described
- Rebase before merging to keep history clean
- Squash fixup commits

### Performance

- Use React DevTools Profiler to identify bottlenecks
- Implement caching for expensive operations
- Lazy load components where appropriate
- Optimize bundle size (analyze with `npm run build`)

## Next Steps

- [Testing Guide](testing.md) - Comprehensive testing strategies
- [Debugging Guide](debugging.md) - Advanced debugging techniques
- [Contributing Guide](../../contributing.md) - Contribution guidelines
- [Architecture Overview](../../architecture.md) - System architecture

## Support

**Documentation:**
Consultations@BrooksideBI.com

**Technical Support:**
+1 209 487 2047

**Community:**
[GitHub Discussions](https://github.com/Brookside-Proving-Grounds/Project-Ascension/discussions)

---

*This guide establishes a productive local development environment that enables rapid iteration and reliable deployment of agent solutions.*

**Last Updated:** 2025-10-09
**Version:** 1.0.0
**Maintained By:** Agent Studio Platform Team
