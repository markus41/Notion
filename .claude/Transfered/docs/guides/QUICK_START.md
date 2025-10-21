---
title: Platform Quick Start Guide
description: Get up and running with the Meta-Agent Platform in 5 minutes. Deploy infrastructure, create agents, and execute your first workflow quickly.
tags:
  - quick-start
  - getting-started
  - deployment
  - azure
  - setup
  - tutorial
lastUpdated: 2025-10-09
author: Agent Studio Team
audience: developers
---

# Meta-Agent Platform Quick Start

Get up and running with the Meta-Agent Platform in 5 minutes.

## Prerequisites

- **Azure Subscription**: Active subscription with contributor access
- **.NET SDK 8.0+**: [Download](https://dotnet.microsoft.com/download)
- **Python 3.12+**: [Download](https://python.org/downloads)
- **Node.js 20+**: [Download](https://nodejs.org)
- **Azure CLI**: [Install](https://docs.microsoft.com/cli/azure/install-azure-cli)

## Step 1: Clone Repository

```bash
git clone https://github.com/Brookside-Proving-Grounds/Project-Ascension.git
cd Project-Ascension
```

## Step 2: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your Azure credentials
# Required variables:
# - AZURE_SUBSCRIPTION_ID
# - AZURE_TENANT_ID
# - AZURE_OPENAI_ENDPOINT
# - AZURE_OPENAI_KEY
```

## Step 3: Deploy Infrastructure (Azure)

```bash
# Login to Azure
az login

# Deploy infrastructure
cd infra
./deploy.sh dev

# This will create:
# - Resource Group
# - Cosmos DB
# - Redis Cache
# - Storage Account
# - Key Vault
# - App Services
```

## Step 4: Run Locally

### Option A: Docker Compose (Recommended)

```bash
# Start all services
docker-compose up

# Services available at:
# - Frontend: http://localhost:5173
# - .NET API: http://localhost:5000
# - Python Service: http://localhost:8000
```

### Option B: Manual Start

```bash
# Terminal 1: .NET API
cd services/dotnet/AgentStudio.Api
dotnet run

# Terminal 2: Python Service
cd services/python
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload

# Terminal 3: Frontend
cd webapp
npm install
npm run dev
```

## Step 5: Create Your First Agent

### Via Web UI

1. Open http://localhost:5173
2. Click "Create Agent"
3. Fill in details:
   - **Name**: "Code Review Agent"
   - **Type**: "code_review"
   - **Model**: "gpt-4"
4. Click "Create"

### Via API

```bash
curl -X POST http://localhost:5000/api/v1/agents \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{
    "name": "Code Review Agent",
    "type": "code_review",
    "description": "Reviews code for quality and security",
    "configuration": {
      "model": "gpt-4",
      "temperature": 0.3,
      "max_tokens": 3000
    }
  }'
```

## Step 6: Create Your First Workflow

```bash
curl -X POST http://localhost:5000/api/v1/workflows \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{
    "name": "PR Review Pipeline",
    "type": "sequential",
    "steps": [
      {
        "name": "Analyze Code",
        "agent_id": "agent-123",
        "order": 1
      },
      {
        "name": "Security Scan",
        "agent_id": "agent-456",
        "order": 2
      }
    ]
  }'
```

## Step 7: Execute Workflow

```bash
curl -X POST http://localhost:5000/api/v1/workflows/workflow-789/execute \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{
    "parameters": {
      "repository": "org/repo",
      "pull_request": 123
    }
  }'
```

## Verify Setup

### Check Service Health

```bash
# .NET API
curl http://localhost:5000/health

# Python Service
curl http://localhost:8000/health

# Frontend
curl http://localhost:5173
```

### View Logs

```bash
# .NET logs
cd services/dotnet/AgentStudio.Api
dotnet run --verbosity detailed

# Python logs
cd services/python
uvicorn app.main:app --reload --log-level debug
```

## Next Steps

- [Understanding Meta-Agents](META_AGENT_GUIDE.md)
- [Designing Workflows](WORKFLOW_DESIGN.md)
- [API Documentation](../api/META_AGENTS_API.md)
- [Deployment Guide](../meta-agents/DEPLOYMENT.md)

## Troubleshooting

### Port Already in Use

```bash
# Find process using port 5000
lsof -i :5000  # Mac/Linux
netstat -ano | findstr :5000  # Windows

# Kill process or change port in configuration
```

### Azure Authentication Failed

```bash
# Re-login to Azure
az login --tenant YOUR_TENANT_ID

# Verify account
az account show
```

### Python Dependencies Error

```bash
# Upgrade pip
python -m pip install --upgrade pip

# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

## Support

- [Documentation](../README.md)
- [Issue Tracker](https://github.com/Brookside-Proving-Grounds/Project-Ascension/issues)
- [Discussions](https://github.com/Brookside-Proving-Grounds/Project-Ascension/discussions)

---

**Last Updated**: 2025-10-07
**Version**: 1.0.0
