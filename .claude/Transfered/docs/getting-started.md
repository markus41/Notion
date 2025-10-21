---
title: Getting Started with Agent Studio
description: Establish your AI agent platform in under 30 minutes. Complete setup guide for developers building scalable, production-ready agent workflows.
tags:
  - getting-started
  - quickstart
  - setup
  - installation
  - tutorial
  - onboarding
lastUpdated: 2025-10-09
author: Agent Studio Team
audience: developers
---

# Getting Started with Agent Studio

Welcome to Agent Studio! This guide will help you get up and running quickly.

## Prerequisites

- **Node.js** 20.x or later
- **Python** 3.12 or later
- **.NET SDK** 8.0 or later
- **Azure CLI** (for deployment)
- **Git**
- **Docker** (optional, for containerization)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Brookside-Proving-Grounds/Project-Ascension.git
cd Project-Ascension
```

### 2. Setup Development Environment

#### Option A: Using DevContainer (Recommended)

If you have VS Code and Docker installed:

1. Open the project in VS Code
2. Click "Reopen in Container" when prompted
3. Wait for the container to build and setup to complete

#### Option B: Manual Setup

**Install dependencies for each component:**

```bash
# Web App
cd webapp
npm install
cd ..

# Python Service
cd services/python
pip install -r requirements.txt
pip install -r requirements-dev.txt
cd ../..

# .NET Service
cd services/dotnet
dotnet restore
cd ../..

# MCP Tool
cd tools/mcp-tool-stub
npm install
cd ../..

# Pre-commit hooks
pip install pre-commit
pre-commit install
```

### 3. Run Services Locally

**Web App (Frontend):**
```bash
cd webapp
npm run dev
```
Access at: http://localhost:5173

**Python Service:**
```bash
cd services/python
uvicorn app.main:app --reload --port 8000
```
Access at: http://localhost:8000

**API Documentation:** http://localhost:8000/docs

**.NET Service:**
```bash
cd services/dotnet
dotnet run --project AgentStudio.Api
```
Access at: http://localhost:5000

### 4. Run Tests

**Web App:**
```bash
cd webapp
npm run test
```

**Python Service:**
```bash
cd services/python
pytest
```

**.NET Service:**
```bash
cd services/dotnet
dotnet test
```

## Project Structure

```
agent-studio/
├── webapp/                 # React + TypeScript + Vite frontend
├── services/
│   ├── dotnet/            # .NET 8 backend service
│   └── python/            # FastAPI Python service
├── agents/                # Agent configuration files
├── workflows/             # Workflow definitions
├── tools/                 # MCP tools and utilities
│   └── mcp-tool-stub/    # Model Context Protocol tool
├── infra/                 # Azure Bicep infrastructure as code
│   └── bicep/
├── docs/                  # Documentation
├── .devcontainer/         # Dev container configuration
├── .github/               # GitHub Actions workflows
└── README.md
```

## Key Concepts

### Agents

Agents are autonomous AI entities that can perform specific tasks. Agent definitions are stored in the `agents/` directory as JSON files.

Example: `agents/code-review-agent.json`

### Workflows

Workflows orchestrate multiple agents to accomplish complex tasks. Workflow definitions are stored in the `workflows/` directory.

Example: `workflows/ci-cd-workflow.json`

### MCP Tools

Model Context Protocol (MCP) tools provide a standardized way for AI models to interact with your systems. The MCP tool stub is in `tools/mcp-tool-stub/`.

## Development Workflow

1. **Create a branch** for your feature or bug fix
2. **Make changes** to the code
3. **Run tests** to ensure everything works
4. **Commit** with conventional commit messages (e.g., `feat:`, `fix:`)
5. **Push** your branch and create a pull request
6. **Wait for CI** to pass and request review

## Deployment

### Deploy to Azure

```bash
# Login to Azure
az login

# Create resource group
az group create --name rg-agent-studio-dev --location eastus

# Deploy infrastructure
cd infra/bicep
az deployment group create \
  --resource-group rg-agent-studio-dev \
  --template-file main.bicep \
  --parameters parameters.dev.json
```

See [Infrastructure Documentation](../infra/README.md) for detailed deployment instructions.

## Configuration

### Environment Variables

Create `.env` files in each service directory:

**webapp/.env:**
```
VITE_API_URL=http://localhost:8000
```

**services/python/.env:**
```
DATABASE_URL=<your-database-url>
LOG_LEVEL=info
```

**services/dotnet/AgentStudio.Api/appsettings.Development.json:**
```json
{
  "ConnectionStrings": {
    "CosmosDb": "<your-cosmos-connection>"
  }
}
```

## Troubleshooting

### Port Already in Use

If you get a "port already in use" error, kill the process using that port:

```bash
# Linux/Mac
lsof -ti:5173 | xargs kill -9

# Windows
netstat -ano | findstr :5173
taskkill /PID <pid> /F
```

### Module Not Found

Make sure you've installed all dependencies:

```bash
# Node.js
npm install

# Python
pip install -r requirements.txt

# .NET
dotnet restore
```

## Next Steps

- [Architecture Overview](architecture.md)
- [API Documentation](api.md)
- [Contributing Guide](../CONTRIBUTING.md)
- [Deployment Guide](../infra/README.md)

## Support

- 📖 [Documentation](README.md)
- 🐛 [Issue Tracker](https://github.com/Brookside-Proving-Grounds/Project-Ascension/issues)
- 💬 [Discussions](https://github.com/Brookside-Proving-Grounds/Project-Ascension/discussions)
