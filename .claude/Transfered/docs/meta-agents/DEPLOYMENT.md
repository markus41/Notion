# Deployment Guide

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Local Development Deployment](#local-development-deployment)
- [Azure Deployment](#azure-deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring and Health Checks](#monitoring-and-health-checks)
- [Rollback Procedures](#rollback-procedures)
- [Troubleshooting](#troubleshooting)

## Overview

This guide covers deploying the Meta-Agent Platform across different environments:

- **Local**: Development and testing on localhost
- **Development**: Azure development environment
- **Staging**: Pre-production environment for testing
- **Production**: Live production environment

### Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Production Deployment                     │
│                                                              │
│  ┌──────────────┐     ┌──────────────┐    ┌──────────────┐│
│  │ Azure Front  │────▶│   API        │───▶│    App       ││
│  │    Door      │     │  Management  │    │   Services   ││
│  └──────────────┘     └──────────────┘    └──────┬───────┘│
│                                                    │         │
│  Multi-region, auto-scaling, health monitoring    │         │
│                                                    ▼         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Data & Platform Services                 │  │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐   │  │
│  │  │Cosmos DB│ │  Redis  │ │  Blob   │ │   Key   │   │  │
│  │  │         │ │  Cache  │ │ Storage │ │  Vault  │   │  │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘   │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

### Required Tools

- **Azure CLI**: Version 2.50+ ([Install](https://docs.microsoft.com/cli/azure/install-azure-cli))
- **Azure Bicep**: Version 0.21+ (bundled with Azure CLI)
- **.NET SDK**: Version 8.0+ ([Install](https://dotnet.microsoft.com/download))
- **Python**: Version 3.12+ ([Install](https://python.org/downloads))
- **Node.js**: Version 20+ ([Install](https://nodejs.org))
- **Docker**: Version 24+ (optional, for containers)
- **Git**: Version 2.40+

### Azure Prerequisites

- **Azure Subscription**: Active subscription with contributor access
- **Resource Providers**: Registered providers for:
  - `Microsoft.App` (App Service)
  - `Microsoft.DocumentDB` (Cosmos DB)
  - `Microsoft.Cache` (Redis)
  - `Microsoft.Storage` (Blob Storage)
  - `Microsoft.KeyVault` (Key Vault)
  - `Microsoft.Insights` (Application Insights)

### Azure AD Setup

```bash
# Create Azure AD App Registration for authentication
az ad app create \
  --display-name "Agent Studio API" \
  --sign-in-audience AzureADMyOrg \
  --web-redirect-uris "https://agentstudio.yourdomain.com/signin-oidc" \
  --enable-id-token-issuance true

# Note the Application (client) ID and Tenant ID
```

### Service Principal for OIDC (GitHub Actions)

```bash
# Create service principal for GitHub Actions
az ad sp create-for-rbac \
  --name "github-actions-agent-studio" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth

# Configure federated credentials for OIDC
az ad app federated-credential create \
  --id {app-id} \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YourOrg/Project-Ascension:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

## Environment Setup

### Environment Variables

Create environment-specific configuration files:

#### Development Environment

**`.env.development`**:
```bash
# Azure Configuration
AZURE_SUBSCRIPTION_ID=your-subscription-id
AZURE_TENANT_ID=your-tenant-id
AZURE_RESOURCE_GROUP=rg-agentstudio-dev
AZURE_LOCATION=eastus

# Application Configuration
ENVIRONMENT=development
APP_SERVICE_PLAN_SKU=B1
APP_SERVICE_PLAN_CAPACITY=1
COSMOS_DB_THROUGHPUT=400

# Service URLs
API_URL=https://agentstudio-api-dev.azurewebsites.net
PYTHON_SERVICE_URL=https://agentstudio-python-dev.azurewebsites.net
FRONTEND_URL=https://agentstudio-web-dev.azurewebsites.net

# Azure AD
AZURE_AD_CLIENT_ID=your-client-id
AZURE_AD_TENANT_ID=your-tenant-id

# OpenAI
AZURE_OPENAI_ENDPOINT=https://your-openai.openai.azure.com
AZURE_OPENAI_DEPLOYMENT=gpt-4

# Feature Flags
ENABLE_TELEMETRY=true
ENABLE_CACHE=true
LOG_LEVEL=Debug
```

#### Production Environment

**`.env.production`**:
```bash
# Azure Configuration
AZURE_SUBSCRIPTION_ID=your-subscription-id
AZURE_TENANT_ID=your-tenant-id
AZURE_RESOURCE_GROUP=rg-agentstudio-prod
AZURE_LOCATION=eastus

# Application Configuration
ENVIRONMENT=production
APP_SERVICE_PLAN_SKU=P2v3
APP_SERVICE_PLAN_CAPACITY=3
COSMOS_DB_THROUGHPUT=4000

# Service URLs
API_URL=https://api.agentstudio.com
PYTHON_SERVICE_URL=https://agents.agentstudio.com
FRONTEND_URL=https://app.agentstudio.com

# Security
ENFORCE_HTTPS=true
HSTS_MAX_AGE=31536000
ALLOWED_ORIGINS=https://app.agentstudio.com

# Monitoring
ENABLE_TELEMETRY=true
ENABLE_CACHE=true
LOG_LEVEL=Information
APPLICATION_INSIGHTS_SAMPLING_PERCENTAGE=10
```

## Local Development Deployment

### Step 1: Clone Repository

```bash
git clone https://github.com/Brookside-Proving-Grounds/Project-Ascension.git
cd Project-Ascension
```

### Step 2: Install Dependencies

```bash
# Frontend
cd webapp
npm install
cd ..

# Python Service
cd services/python
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
pip install -r requirements-dev.txt
cd ../..

# .NET Service
cd services/dotnet
dotnet restore
cd ../..
```

### Step 3: Configure Local Secrets

```bash
# .NET User Secrets
cd services/dotnet/AgentStudio.Api
dotnet user-secrets init
dotnet user-secrets set "AzureAd:ClientId" "your-client-id"
dotnet user-secrets set "AzureAd:TenantId" "your-tenant-id"
dotnet user-secrets set "AzureOpenAI:ApiKey" "your-api-key"
dotnet user-secrets set "AzureOpenAI:Endpoint" "https://your-openai.openai.azure.com"
dotnet user-secrets set "CosmosDb:ConnectionString" "AccountEndpoint=https://localhost:8081/;AccountKey=..."
cd ../../..

# Python Environment Variables
cp services/python/.env.example services/python/.env
# Edit .env with your configuration

# Frontend Environment
cp webapp/.env.example webapp/.env
# Edit .env with your configuration
```

### Step 4: Start Local Services

#### Option A: Using Docker Compose (Recommended)

```bash
# Start all services with dependencies
docker-compose up -d

# Services will be available at:
# - Frontend: http://localhost:5173
# - .NET API: http://localhost:5000
# - Python Service: http://localhost:8000
# - Cosmos DB Emulator: https://localhost:8081
# - Redis: localhost:6379
```

#### Option B: Manual Start

```bash
# Terminal 1: Start Cosmos DB Emulator
# Download from: https://docs.microsoft.com/azure/cosmos-db/local-emulator

# Terminal 2: Start Redis
docker run -d -p 6379:6379 redis:7-alpine

# Terminal 3: Start .NET API
cd services/dotnet/AgentStudio.Api
dotnet run

# Terminal 4: Start Python Service
cd services/python
source venv/bin/activate
uvicorn app.main:app --reload --port 8000

# Terminal 5: Start Frontend
cd webapp
npm run dev
```

### Step 5: Verify Local Deployment

```bash
# Check .NET API health
curl http://localhost:5000/health

# Check Python service health
curl http://localhost:8000/health

# Open frontend
open http://localhost:5173
```

## Azure Deployment

### Infrastructure Deployment

#### Step 1: Login to Azure

```bash
az login
az account set --subscription "your-subscription-id"
```

#### Step 2: Create Resource Group

```bash
az group create \
  --name rg-agentstudio-dev \
  --location eastus
```

#### Step 3: Deploy Infrastructure with Bicep

```bash
cd infra

# Validate Bicep template
az deployment group validate \
  --resource-group rg-agentstudio-dev \
  --template-file deploy.bicep \
  --parameters deploy.parameters.dev.json

# Deploy infrastructure
az deployment group create \
  --resource-group rg-agentstudio-dev \
  --template-file deploy.bicep \
  --parameters deploy.parameters.dev.json \
  --mode Incremental

# Deployment will create:
# - App Service Plan
# - App Services (Web, API, Python)
# - Cosmos DB account and databases
# - Azure Cache for Redis
# - Storage Account
# - Key Vault
# - Application Insights
# - Log Analytics Workspace
```

#### Step 4: Configure Secrets in Key Vault

```bash
# Set Azure OpenAI secrets
az keyvault secret set \
  --vault-name kv-agentstudio-dev \
  --name "AzureOpenAI--ApiKey" \
  --value "your-openai-api-key"

az keyvault secret set \
  --vault-name kv-agentstudio-dev \
  --name "AzureOpenAI--Endpoint" \
  --value "https://your-openai.openai.azure.com"

# Set Cosmos DB connection string
az keyvault secret set \
  --vault-name kv-agentstudio-dev \
  --name "CosmosDb--ConnectionString" \
  --value "$(az cosmosdb keys list --name cosmos-agentstudio-dev --resource-group rg-agentstudio-dev --type connection-strings --query 'connectionStrings[0].connectionString' -o tsv)"

# Set Redis connection string
az keyvault secret set \
  --vault-name kv-agentstudio-dev \
  --name "Redis--ConnectionString" \
  --value "$(az redis list-keys --name redis-agentstudio-dev --resource-group rg-agentstudio-dev --query 'primaryKey' -o tsv)"
```

#### Step 5: Enable Managed Identity

```bash
# Enable system-assigned managed identity for App Services
az webapp identity assign \
  --name app-agentstudio-api-dev \
  --resource-group rg-agentstudio-dev

az webapp identity assign \
  --name app-agentstudio-python-dev \
  --resource-group rg-agentstudio-dev

az webapp identity assign \
  --name app-agentstudio-web-dev \
  --resource-group rg-agentstudio-dev

# Grant Key Vault access to managed identities
API_PRINCIPAL_ID=$(az webapp identity show --name app-agentstudio-api-dev --resource-group rg-agentstudio-dev --query 'principalId' -o tsv)

az keyvault set-policy \
  --name kv-agentstudio-dev \
  --object-id $API_PRINCIPAL_ID \
  --secret-permissions get list

PYTHON_PRINCIPAL_ID=$(az webapp identity show --name app-agentstudio-python-dev --resource-group rg-agentstudio-dev --query 'principalId' -o tsv)

az keyvault set-policy \
  --name kv-agentstudio-dev \
  --object-id $PYTHON_PRINCIPAL_ID \
  --secret-permissions get list
```

### Application Deployment

#### Deploy .NET API

```bash
cd services/dotnet/AgentStudio.Api

# Publish application
dotnet publish -c Release -o ./publish

# Create deployment package
cd publish
zip -r ../deploy.zip .
cd ..

# Deploy to Azure
az webapp deployment source config-zip \
  --resource-group rg-agentstudio-dev \
  --name app-agentstudio-api-dev \
  --src deploy.zip

# Configure app settings
az webapp config appsettings set \
  --resource-group rg-agentstudio-dev \
  --name app-agentstudio-api-dev \
  --settings \
    ASPNETCORE_ENVIRONMENT=Development \
    AzureAd__ClientId="your-client-id" \
    AzureAd__TenantId="your-tenant-id" \
    PythonService__BaseUrl="https://app-agentstudio-python-dev.azurewebsites.net"
```

#### Deploy Python Service

```bash
cd services/python

# Create deployment package (exclude venv, __pycache__)
zip -r deploy.zip . -x "venv/*" "__pycache__/*" "*.pyc" ".env"

# Deploy to Azure
az webapp deployment source config-zip \
  --resource-group rg-agentstudio-dev \
  --name app-agentstudio-python-dev \
  --src deploy.zip

# Configure startup command
az webapp config set \
  --resource-group rg-agentstudio-dev \
  --name app-agentstudio-python-dev \
  --startup-file "gunicorn -w 4 -k uvicorn.workers.UvicornWorker app.main:app --bind 0.0.0.0:8000"

# Configure app settings
az webapp config appsettings set \
  --resource-group rg-agentstudio-dev \
  --name app-agentstudio-python-dev \
  --settings \
    ENVIRONMENT=development \
    PYTHONPATH=/home/site/wwwroot
```

#### Deploy React Frontend

```bash
cd webapp

# Build production bundle
npm run build

# Deploy to Azure (Static Web App or App Service)
az webapp deployment source config-zip \
  --resource-group rg-agentstudio-dev \
  --name app-agentstudio-web-dev \
  --src dist.zip

# Configure SPA routing
az webapp config set \
  --resource-group rg-agentstudio-dev \
  --name app-agentstudio-web-dev \
  --startup-file "pm2 serve /home/site/wwwroot --no-daemon --spa"
```

### Container Deployment (Alternative)

#### Build and Push Docker Images

```bash
# Login to Azure Container Registry
az acr login --name acragentstudio

# Build and push .NET API
docker build -f Dockerfile.api -t acragentstudio.azurecr.io/agentstudio-api:latest .
docker push acragentstudio.azurecr.io/agentstudio-api:latest

# Build and push Python service
docker build -f Dockerfile.worker -t acragentstudio.azurecr.io/agentstudio-python:latest .
docker push acragentstudio.azurecr.io/agentstudio-python:latest

# Build and push Frontend
docker build -f Dockerfile.webapp -t acragentstudio.azurecr.io/agentstudio-web:latest .
docker push acragentstudio.azurecr.io/agentstudio-web:latest
```

#### Deploy Containers to App Service

```bash
# Configure container settings for API
az webapp config container set \
  --resource-group rg-agentstudio-dev \
  --name app-agentstudio-api-dev \
  --docker-custom-image-name acragentstudio.azurecr.io/agentstudio-api:latest \
  --docker-registry-server-url https://acragentstudio.azurecr.io

# Configure container settings for Python
az webapp config container set \
  --resource-group rg-agentstudio-dev \
  --name app-agentstudio-python-dev \
  --docker-custom-image-name acragentstudio.azurecr.io/agentstudio-python:latest \
  --docker-registry-server-url https://acragentstudio.azurecr.io

# Configure container settings for Frontend
az webapp config container set \
  --resource-group rg-agentstudio-dev \
  --name app-agentstudio-web-dev \
  --docker-custom-image-name acragentstudio.azurecr.io/agentstudio-web:latest \
  --docker-registry-server-url https://acragentstudio.azurecr.io

# Restart services
az webapp restart --resource-group rg-agentstudio-dev --name app-agentstudio-api-dev
az webapp restart --resource-group rg-agentstudio-dev --name app-agentstudio-python-dev
az webapp restart --resource-group rg-agentstudio-dev --name app-agentstudio-web-dev
```

## CI/CD Pipeline

### GitHub Actions Workflow

The project includes automated CI/CD workflows in `.github/workflows/`:

**`.github/workflows/deploy.yml`**:
```yaml
name: Deploy to Azure

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        type: choice
        options:
          - development
          - staging
          - production

jobs:
  deploy-infrastructure:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'development' }}
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login via OIDC
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy Bicep template
        uses: azure/arm-deploy@v1
        with:
          resourceGroupName: rg-agentstudio-${{ github.event.inputs.environment || 'dev' }}
          template: ./infra/deploy.bicep
          parameters: ./infra/deploy.parameters.${{ github.event.inputs.environment || 'dev' }}.json

  deploy-api:
    needs: deploy-infrastructure
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.0.x'

      - name: Build
        run: dotnet publish services/dotnet/AgentStudio.Api -c Release -o ./publish

      - name: Deploy to Azure Web App
        uses: azure/webapps-deploy@v2
        with:
          app-name: app-agentstudio-api-${{ github.event.inputs.environment || 'dev' }}
          package: ./publish

  deploy-python:
    needs: deploy-infrastructure
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: |
          cd services/python
          pip install -r requirements.txt

      - name: Deploy to Azure Web App
        uses: azure/webapps-deploy@v2
        with:
          app-name: app-agentstudio-python-${{ github.event.inputs.environment || 'dev' }}
          package: ./services/python

  deploy-frontend:
    needs: deploy-infrastructure
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install and build
        run: |
          cd webapp
          npm ci
          npm run build

      - name: Deploy to Azure Web App
        uses: azure/webapps-deploy@v2
        with:
          app-name: app-agentstudio-web-${{ github.event.inputs.environment || 'dev' }}
          package: ./webapp/dist
```

### Required Secrets

Configure these secrets in GitHub repository settings:

```
AZURE_CLIENT_ID          # Service principal client ID
AZURE_TENANT_ID          # Azure AD tenant ID
AZURE_SUBSCRIPTION_ID    # Azure subscription ID
```

### Deployment Strategies

#### Rolling Deployment (Default)

- Gradually replace old instances with new ones
- Zero downtime
- Automatic rollback on health check failure

#### Blue-Green Deployment

```bash
# Deploy to staging slot
az webapp deployment slot create \
  --name app-agentstudio-api-prod \
  --resource-group rg-agentstudio-prod \
  --slot staging

az webapp deployment source config-zip \
  --resource-group rg-agentstudio-prod \
  --name app-agentstudio-api-prod \
  --slot staging \
  --src deploy.zip

# Test staging slot
curl https://app-agentstudio-api-prod-staging.azurewebsites.net/health

# Swap slots (production ↔ staging)
az webapp deployment slot swap \
  --resource-group rg-agentstudio-prod \
  --name app-agentstudio-api-prod \
  --slot staging \
  --target-slot production
```

#### Canary Deployment

```bash
# Route 10% of traffic to new version
az webapp traffic-routing set \
  --resource-group rg-agentstudio-prod \
  --name app-agentstudio-api-prod \
  --distribution staging=10

# Monitor metrics, then increase to 50%
az webapp traffic-routing set \
  --resource-group rg-agentstudio-prod \
  --name app-agentstudio-api-prod \
  --distribution staging=50

# Full cutover
az webapp deployment slot swap \
  --resource-group rg-agentstudio-prod \
  --name app-agentstudio-api-prod \
  --slot staging
```

## Monitoring and Health Checks

### Health Check Endpoints

**.NET Health Check**:
```csharp
// Program.cs
builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy())
    .AddCosmosDb(
        cosmosDbConnectionString,
        name: "cosmosdb",
        failureStatus: HealthStatus.Degraded)
    .AddRedis(
        redisConnectionString,
        name: "redis",
        failureStatus: HealthStatus.Degraded);

app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});

app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});

app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = _ => false // Only self check
});
```

**Python Health Check**:
```python
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "agent-studio-python",
        "version": "1.0.0",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/health/ready")
async def readiness_check():
    # Check dependencies
    checks = {
        "openai": await check_openai_connection(),
        "storage": await check_storage_connection(),
    }

    all_healthy = all(checks.values())

    return {
        "status": "ready" if all_healthy else "not_ready",
        "checks": checks
    }
```

### Configure Azure Health Checks

```bash
# Enable health check monitoring
az webapp config set \
  --resource-group rg-agentstudio-prod \
  --name app-agentstudio-api-prod \
  --health-check-path "/health"

# Configure auto-heal rules
az webapp config set \
  --resource-group rg-agentstudio-prod \
  --name app-agentstudio-api-prod \
  --auto-heal-enabled true
```

### Application Insights Monitoring

**Custom Metrics**:
```csharp
// Track custom metrics
_telemetryClient.TrackMetric("WorkflowExecutionDuration", duration);
_telemetryClient.TrackEvent("WorkflowCompleted", new Dictionary<string, string>
{
    ["WorkflowId"] = workflowId,
    ["Status"] = "Success"
});
```

**Alerts**:
```bash
# Create alert for high error rate
az monitor metrics alert create \
  --name "High Error Rate - API" \
  --resource-group rg-agentstudio-prod \
  --scopes /subscriptions/{subscription-id}/resourceGroups/rg-agentstudio-prod/providers/Microsoft.Web/sites/app-agentstudio-api-prod \
  --condition "count errors > 10" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action /subscriptions/{subscription-id}/resourceGroups/rg-agentstudio-prod/providers/Microsoft.Insights/actionGroups/oncall-team
```

## Rollback Procedures

### Automated Rollback

Health check failures trigger automatic rollback:

```bash
# Configure deployment rollback on health check failure
az webapp deployment slot swap \
  --resource-group rg-agentstudio-prod \
  --name app-agentstudio-api-prod \
  --slot staging \
  --target-slot production \
  --preserve-vnet true \
  --auto-swap-slot-name production
```

### Manual Rollback

#### Rollback to Previous Slot

```bash
# Swap back to previous version
az webapp deployment slot swap \
  --resource-group rg-agentstudio-prod \
  --name app-agentstudio-api-prod \
  --slot production \
  --target-slot staging
```

#### Rollback to Specific Version

```bash
# List deployment history
az webapp deployment list \
  --resource-group rg-agentstudio-prod \
  --name app-agentstudio-api-prod

# Redeploy specific version
az webapp deployment source config-zip \
  --resource-group rg-agentstudio-prod \
  --name app-agentstudio-api-prod \
  --src previous-version.zip
```

### Database Rollback

```bash
# Restore Cosmos DB to specific point in time
az cosmosdb sql database restore \
  --account-name cosmos-agentstudio-prod \
  --resource-group rg-agentstudio-prod \
  --name agentstudio-db \
  --restore-timestamp "2025-10-07T12:00:00Z"
```

## Troubleshooting

### Common Deployment Issues

#### Issue: Deployment Fails with "Conflict" Error

**Cause**: Resource already exists or deployment in progress

**Solution**:
```bash
# Check deployment status
az deployment group show \
  --resource-group rg-agentstudio-dev \
  --name deploymentName

# Cancel stuck deployment
az deployment group cancel \
  --resource-group rg-agentstudio-dev \
  --name deploymentName

# Retry deployment
az deployment group create --resource-group rg-agentstudio-dev --template-file deploy.bicep --parameters deploy.parameters.dev.json
```

#### Issue: App Service Shows "503 Service Unavailable"

**Cause**: Application not started or health check failing

**Solution**:
```bash
# Check application logs
az webapp log tail \
  --resource-group rg-agentstudio-dev \
  --name app-agentstudio-api-dev

# Restart app service
az webapp restart \
  --resource-group rg-agentstudio-dev \
  --name app-agentstudio-api-dev

# Check health endpoint
curl https://app-agentstudio-api-dev.azurewebsites.net/health
```

#### Issue: Key Vault Access Denied

**Cause**: Managed Identity not configured or missing permissions

**Solution**:
```bash
# Enable managed identity
az webapp identity assign \
  --resource-group rg-agentstudio-dev \
  --name app-agentstudio-api-dev

# Get principal ID
PRINCIPAL_ID=$(az webapp identity show --resource-group rg-agentstudio-dev --name app-agentstudio-api-dev --query 'principalId' -o tsv)

# Grant Key Vault access
az keyvault set-policy \
  --name kv-agentstudio-dev \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get list
```

### Diagnostic Commands

```bash
# View deployment logs
az webapp log deployment show \
  --resource-group rg-agentstudio-dev \
  --name app-agentstudio-api-dev

# Stream application logs
az webapp log tail \
  --resource-group rg-agentstudio-dev \
  --name app-agentstudio-api-dev

# Download logs
az webapp log download \
  --resource-group rg-agentstudio-dev \
  --name app-agentstudio-api-dev \
  --log-file app-logs.zip

# Check App Service metrics
az monitor metrics list \
  --resource /subscriptions/{subscription-id}/resourceGroups/rg-agentstudio-dev/providers/Microsoft.Web/sites/app-agentstudio-api-dev \
  --metric "Http5xx" \
  --start-time 2025-10-07T00:00:00Z \
  --end-time 2025-10-07T23:59:59Z
```

---

**Related Documentation**:
- [Architecture Overview](ARCHITECTURE.md)
- [Integration Guide](INTEGRATION.md)
- [Infrastructure README](../../infra/README.md)
- [Runbooks](../runbooks/)

**Last Updated**: 2025-10-07
**Version**: 1.0.0
