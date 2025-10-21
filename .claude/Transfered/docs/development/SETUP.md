# Development Environment Setup

Complete guide for setting up a development environment for the Meta-Agent Platform.

## Table of Contents

- [System Requirements](#system-requirements)
- [Installing Prerequisites](#installing-prerequisites)
- [Repository Setup](#repository-setup)
- [Local Development Services](#local-development-services)
- [IDE Configuration](#ide-configuration)
- [Testing Setup](#testing-setup)
- [Debugging](#debugging)

## System Requirements

### Minimum Requirements

- **OS**: Windows 10+, macOS 11+, or Ubuntu 20.04+
- **RAM**: 8 GB (16 GB recommended)
- **Disk**: 20 GB free space
- **CPU**: 4 cores (8 cores recommended)

### Required Software

| Tool | Version | Purpose |
|------|---------|---------|
| .NET SDK | 8.0+ | Backend API development |
| Python | 3.12+ | Agent service development |
| Node.js | 20+ | Frontend development |
| Git | 2.40+ | Version control |
| Docker | 24+ | Containerization (optional) |
| Azure CLI | 2.50+ | Azure deployment |

## Installing Prerequisites

### Windows

```powershell
# Using winget
winget install Microsoft.DotNet.SDK.8
winget install Python.Python.3.12
winget install OpenJS.NodeJS.LTS
winget install Git.Git
winget install Docker.DockerDesktop
winget install Microsoft.AzureCLI

# Using Chocolatey
choco install dotnet-8.0-sdk
choco install python --version=3.12
choco install nodejs-lts
choco install git
choco install docker-desktop
choco install azure-cli
```

### macOS

```bash
# Using Homebrew
brew install --cask dotnet-sdk
brew install python@3.12
brew install node@20
brew install git
brew install --cask docker
brew install azure-cli
```

### Linux (Ubuntu/Debian)

```bash
# .NET SDK
wget https://dot.net/v1/dotnet-install.sh
bash dotnet-install.sh --channel 8.0

# Python 3.12
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.12 python3.12-venv python3.12-dev

# Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Git
sudo apt install git

# Docker
sudo apt install docker.io docker-compose

# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

## Repository Setup

### Clone Repository

```bash
git clone https://github.com/Brookside-Proving-Grounds/Project-Ascension.git
cd Project-Ascension
```

### Install Dependencies

#### Frontend (React + TypeScript)

```bash
cd webapp
npm install

# Verify installation
npm run build
```

#### Backend (.NET)

```bash
cd services/dotnet
dotnet restore

# Verify installation
dotnet build
```

#### Python Service

```bash
cd services/python

# Create virtual environment
python -m venv venv

# Activate virtual environment
source venv/bin/activate  # Mac/Linux
venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Verify installation
pytest --version
black --version
```

### Configure Pre-commit Hooks

```bash
# Install pre-commit
pip install pre-commit

# Install git hooks
pre-commit install
pre-commit install --hook-type commit-msg

# Run hooks manually
pre-commit run --all-files
```

## Local Development Services

### Option 1: Docker Compose (Recommended)

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

**Services**:
- Frontend: http://localhost:5173
- .NET API: http://localhost:5000
- Python Service: http://localhost:8000
- Cosmos DB Emulator: https://localhost:8081
- Redis: localhost:6379

### Option 2: Manual Setup

#### Cosmos DB Emulator

**Windows**:
```powershell
# Download and install
# https://docs.microsoft.com/azure/cosmos-db/local-emulator

# Start emulator
"C:\Program Files\Azure Cosmos DB Emulator\CosmosDB.Emulator.exe"
```

**Mac/Linux** (use Docker):
```bash
docker run -p 8081:8081 -p 10251:10251 -p 10252:10252 -p 10253:10253 -p 10254:10254 \
  mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator
```

#### Redis

```bash
# Docker
docker run -d -p 6379:6379 redis:7-alpine

# Or install locally
# Windows: https://github.com/microsoftarchive/redis/releases
# Mac: brew install redis && brew services start redis
# Linux: sudo apt install redis-server && sudo systemctl start redis
```

#### .NET API

```bash
cd services/dotnet/AgentStudio.Api

# Set user secrets
dotnet user-secrets init
dotnet user-secrets set "CosmosDb:ConnectionString" "AccountEndpoint=https://localhost:8081/;AccountKey=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
dotnet user-secrets set "Redis:ConnectionString" "localhost:6379"
dotnet user-secrets set "AzureOpenAI:Endpoint" "https://your-openai.openai.azure.com"
dotnet user-secrets set "AzureOpenAI:ApiKey" "your-api-key"

# Run
dotnet run
```

#### Python Service

```bash
cd services/python

# Create .env file
cp .env.example .env

# Edit .env with your configuration
AZURE_OPENAI_ENDPOINT=https://your-openai.openai.azure.com
AZURE_OPENAI_KEY=your-api-key
COSMOS_DB_ENDPOINT=https://localhost:8081
REDIS_URL=redis://localhost:6379

# Run
source venv/bin/activate
uvicorn app.main:app --reload --port 8000
```

#### Frontend

```bash
cd webapp

# Create .env file
cp .env.example .env

# Edit .env
VITE_API_URL=http://localhost:5000
VITE_SIGNALR_URL=http://localhost:5000/hubs

# Run
npm run dev
```

## IDE Configuration

### Visual Studio Code

#### Recommended Extensions

```json
{
  "recommendations": [
    "ms-dotnettools.csharp",
    "ms-python.python",
    "ms-vscode.vscode-typescript-next",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "ms-azuretools.vscode-docker",
    "ms-vscode.azure-account",
    "github.copilot"
  ]
}
```

#### Workspace Settings

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.tsdk": "node_modules/typescript/lib",
  "python.defaultInterpreterPath": "${workspaceFolder}/services/python/venv/bin/python",
  "python.formatting.provider": "black",
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": false,
  "python.linting.flake8Enabled": true
}
```

#### Launch Configuration

`.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": ".NET API",
      "type": "coreclr",
      "request": "launch",
      "preLaunchTask": "build",
      "program": "${workspaceFolder}/services/dotnet/AgentStudio.Api/bin/Debug/net8.0/AgentStudio.Api.dll",
      "args": [],
      "cwd": "${workspaceFolder}/services/dotnet/AgentStudio.Api",
      "env": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    },
    {
      "name": "Python Service",
      "type": "python",
      "request": "launch",
      "module": "uvicorn",
      "args": [
        "app.main:app",
        "--reload",
        "--port",
        "8000"
      ],
      "cwd": "${workspaceFolder}/services/python"
    }
  ]
}
```

### Visual Studio (Windows)

1. Open `services/dotnet/AgentStudio.sln`
2. Set `AgentStudio.Api` as startup project
3. Configure user secrets:
   - Right-click project → Manage User Secrets
   - Add configuration values

### JetBrains Rider

1. Open `services/dotnet/AgentStudio.sln`
2. Configure user secrets in Run Configuration
3. Install Python plugin for Python development

## Testing Setup

### .NET Tests

```bash
cd services/dotnet

# Run all tests
dotnet test

# Run with coverage
dotnet test /p:CollectCoverage=true /p:CoverageReportFormat=opencover

# Run specific test
dotnet test --filter "FullyQualifiedName~AgentServiceTests"
```

### Python Tests

```bash
cd services/python
source venv/bin/activate

# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test
pytest tests/test_main.py::test_health_check
```

### Frontend Tests

```bash
cd webapp

# Run unit tests
npm run test

# Run with coverage
npm run test:coverage

# Run e2e tests
npm run test:e2e
```

## Debugging

### .NET Debugging

#### Visual Studio Code

1. Set breakpoints in `.cs` files
2. Press F5 or Run → Start Debugging
3. Select ".NET API" configuration

#### Visual Studio

1. Set breakpoints
2. Press F5
3. Debugger attaches automatically

### Python Debugging

#### Visual Studio Code

1. Set breakpoints in `.py` files
2. Press F5
3. Select "Python Service" configuration

#### Command Line

```bash
cd services/python
source venv/bin/activate

# Run with debugger
python -m debugpy --listen 5678 --wait-for-client -m uvicorn app.main:app --reload
```

### Frontend Debugging

#### Browser DevTools

1. Open Chrome DevTools (F12)
2. Set breakpoints in Sources tab
3. Refresh page

#### VS Code

```json
{
  "name": "Chrome Debug",
  "type": "chrome",
  "request": "launch",
  "url": "http://localhost:5173",
  "webRoot": "${workspaceFolder}/webapp/src"
}
```

### Remote Debugging (Azure)

#### .NET

```bash
# Enable remote debugging in Azure
az webapp config set --resource-group rg-agentstudio-dev \
  --name app-agentstudio-api-dev \
  --remote-debugging-enabled true

# Attach in Visual Studio
Debug → Attach to Process → Connection Type: Azure App Services
```

## Environment Variables Reference

### .NET API

```bash
ASPNETCORE_ENVIRONMENT=Development
CosmosDb__Endpoint=https://localhost:8081
CosmosDb__Key=<emulator-key>
Redis__ConnectionString=localhost:6379
AzureOpenAI__Endpoint=https://<your-resource>.openai.azure.com
AzureOpenAI__Key=<your-key>
PythonService__BaseUrl=http://localhost:8000
```

### Python Service

```bash
ENVIRONMENT=development
AZURE_OPENAI_ENDPOINT=https://<your-resource>.openai.azure.com
AZURE_OPENAI_KEY=<your-key>
COSMOS_DB_ENDPOINT=https://localhost:8081
REDIS_URL=redis://localhost:6379
LOG_LEVEL=DEBUG
```

### Frontend

```bash
VITE_API_URL=http://localhost:5000
VITE_SIGNALR_URL=http://localhost:5000/hubs
VITE_AZURE_CLIENT_ID=<your-client-id>
VITE_AZURE_TENANT_ID=<your-tenant-id>
```

---

**Related Documentation**:
- [.NET Development Guide](DOTNET_DEVELOPMENT.md)
- [Python Development Guide](PYTHON_DEVELOPMENT.md)
- [React Development Guide](REACT_DEVELOPMENT.md)
- [Testing Guide](TESTING.md)

**Last Updated**: 2025-10-07
**Version**: 1.0.0
