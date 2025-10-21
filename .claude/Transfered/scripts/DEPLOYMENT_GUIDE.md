# Agent Studio - Deployment Automation Scripts

Establish streamlined deployment workflows to support sustainable operations across all environments with comprehensive automation and quality gates.

## Overview

This directory contains deployment automation scripts designed to:
- **Streamline development workflows** - Automated environment setup and service orchestration
- **Establish quality gates** - Comprehensive testing before deployment
- **Support multi-environment deployments** - Consistent deployment processes across dev, staging, and production
- **Improve productivity** - Reduce manual intervention and deployment time

## Scripts Inventory

### Local Development Scripts

#### `dev-setup.sh` / `dev-setup.ps1`
**Purpose:** Automated development environment setup for new developers

**What it does:**
- Validates prerequisite tools (Node.js, .NET, Python, Docker, Azure CLI)
- Installs all project dependencies (webapp, Python, .NET)
- Creates environment configuration files (.env files)
- Validates installation with basic build checks

**Usage:**
```bash
# Linux/macOS
./scripts/dev-setup.sh

# Windows
.\scripts\dev-setup.ps1
```

**Best for:**
- New developer onboarding
- Clean environment setup after machine reset
- Troubleshooting dependency issues

**Time to complete:** 5-10 minutes (depending on network speed)

---

#### `start-all.sh` / `start-all.ps1`
**Purpose:** Unified service launcher for all Agent Studio components

**What it does:**
- Launches .NET orchestration API (port 5000)
- Launches Python meta-agents worker (port 8000)
- Launches React webapp (port 5173)
- Starts supporting Docker services (Redis, Jaeger, Grafana, etc.)

**Usage:**
```bash
# Linux/macOS (requires tmux)
./scripts/start-all.sh

# Windows
.\scripts\start-all.ps1
```

**Linux/macOS tmux controls:**
- `Ctrl+B, 1` - Switch to .NET API window
- `Ctrl+B, 2` - Switch to Python API window
- `Ctrl+B, 3` - Switch to Webapp window
- `Ctrl+B, 4` - Switch to Docker services window
- `Ctrl+B, d` - Detach from session (services continue running)
- `tmux attach -t agent-studio` - Reattach to session
- `tmux kill-session -t agent-studio` - Stop all services

**Windows behavior:**
- Each service launches in a separate PowerShell window
- Close each window individually to stop services

**Best for:**
- Daily development work requiring all services
- Integration testing across components
- Demo environments

---

#### `test-all.sh` / `test-all.ps1`
**Purpose:** Comprehensive test suite execution with coverage reporting

**What it does:**
- Runs Python tests (pytest with coverage)
- Runs .NET tests (dotnet test with coverage)
- Runs React tests (Vitest with coverage)
- Generates HTML coverage reports
- Validates against quality thresholds (85%+ coverage)

**Usage:**
```bash
# Linux/macOS
./scripts/test-all.sh

# Windows
.\scripts\test-all.ps1
```

**Coverage reports generated:**
- Python: `src/python/htmlcov/index.html`
- .NET: `services/dotnet/coverage/index.html`
- Webapp: `webapp/coverage/index.html`

**Best for:**
- Pre-commit validation
- CI/CD quality gates
- Release readiness assessment

**Time to complete:** 2-5 minutes

---

### Azure Deployment Scripts

Located in `infra/scripts/`:

#### `deploy-full-stack.sh`
**Purpose:** End-to-end deployment automation to Azure

**What it does:**
1. Validates Bicep infrastructure templates
2. Deploys Azure infrastructure (Container Registry, Container Apps, Cosmos DB, etc.)
3. Builds all container images (webapp, API, worker)
4. Pushes images to Azure Container Registry
5. Deploys containers to Azure Container Apps
6. Validates deployment health

**Usage:**
```bash
cd infra/scripts
./deploy-full-stack.sh <environment> [region] [project-name] [skip-infra]

# Examples:
./deploy-full-stack.sh dev eastus agent-studio false
./deploy-full-stack.sh prod westus2 my-project false
./deploy-full-stack.sh staging eastus agent-studio true  # Skip infrastructure
```

**Parameters:**
- `environment` (required): dev, staging, or prod
- `region` (optional): Azure region (default: eastus)
- `project-name` (optional): Project name prefix (default: agent-studio)
- `skip-infra` (optional): Skip infrastructure deployment (default: false)

**Prerequisites:**
- Azure CLI installed and authenticated (`az login`)
- Docker installed and running
- Contributor access to Azure subscription

**Best for:**
- Complete environment deployment
- Disaster recovery scenarios
- New environment provisioning

**Time to complete:** 15-30 minutes (infrastructure + containers)

---

#### `build-containers.sh`
**Purpose:** Standalone container image builds and pushes

**What it does:**
1. Builds optimized multi-stage Docker images
2. Tags images with environment and timestamp
3. Pushes to Azure Container Registry
4. Leverages build caching for faster builds

**Usage:**
```bash
cd infra/scripts
./build-containers.sh <acr-name> [image-tag] [environment]

# Examples:
./build-containers.sh myacrregistry 1.2.3 prod
./build-containers.sh devacr latest dev
```

**Parameters:**
- `acr-name` (required): Azure Container Registry name
- `image-tag` (optional): Docker image tag (default: timestamp)
- `environment` (optional): Target environment (default: dev)

**Images built:**
- `{acr}.azurecr.io/webapp:{tag}`
- `{acr}.azurecr.io/dotnet-api:{tag}`
- `{acr}.azurecr.io/python-worker:{tag}`

**Best for:**
- Rebuilding containers after code changes
- Testing container builds locally
- CI/CD container build steps

**Time to complete:** 5-15 minutes (depending on cache)

---

## Deployment Workflows

### Complete Environment Setup (First Time)

```bash
# 1. Setup local development environment
./scripts/dev-setup.sh

# 2. Deploy infrastructure to Azure
cd infra/scripts
./deploy-full-stack.sh dev eastus agent-studio

# 3. Configure secrets
./set-secrets.sh agent-studio-dev-kv

# 4. Verify deployment
# Visit the webapp URL provided in deployment output
```

---

### Daily Development Workflow

```bash
# 1. Start all services
./scripts/start-all.sh

# 2. Make code changes

# 3. Run tests before committing
./scripts/test-all.sh

# 4. Commit and push
git add .
git commit -m "feat: Add new feature"
git push
```

---

### Deployment to Staging/Production

```bash
# Option 1: Automated via GitHub Actions
# Push to main branch or create a tag triggers deployment

# Option 2: Manual deployment
cd infra/scripts
./deploy-full-stack.sh prod westus2 agent-studio

# 3. Validate deployment
# Check health endpoints and run smoke tests
```

---

## Troubleshooting

### Common Issues

#### "Azure CLI not found"
```bash
# Install Azure CLI
# Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
# macOS: brew install azure-cli
# Windows: Download from https://aka.ms/installazurecliwindows
```

#### "Docker daemon not running"
```bash
# Start Docker Desktop (Windows/macOS)
# Linux: sudo systemctl start docker
```

#### "Tests failing"
```bash
# Clean and reinstall dependencies
cd webapp && rm -rf node_modules && npm install
cd src/python && pip install -e ".[dev]" --force-reinstall
cd services/dotnet && dotnet clean && dotnet restore
```

---

## Support

For questions or issues:
- **Email:** Consultations@BrooksideBI.com
- **Phone:** +1 209 487 2047

---

**Deployment automation established - ready for sustainable, scalable operations.**
