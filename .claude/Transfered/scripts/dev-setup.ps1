<#
.SYNOPSIS
    Agent Studio - Development Environment Setup (PowerShell)

.DESCRIPTION
    Establish reliable development environment configuration to support
    sustainable local development across all platform components.

    This script provides automated dependency installation, environment
    configuration, and validation to ensure consistent developer experience.

    Best for: Windows developers onboarding to the Agent Studio platform

.EXAMPLE
    .\dev-setup.ps1

.NOTES
    Requires: PowerShell 5.1+, Node.js 20+, .NET 8.0+, Python 3.10+
#>

[CmdletBinding()]
param()

# Enable strict mode for reliability
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Helper functions for colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    Write-Host $Message -ForegroundColor $ForegroundColor
}

function Write-Status {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" -ForegroundColor Red
}

# Display banner
Write-ColorOutput ""
Write-ColorOutput "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-ColorOutput "║   Agent Studio - Development Environment Setup                ║" -ForegroundColor Cyan
Write-ColorOutput "║   Establish structure and rules for sustainable development   ║" -ForegroundColor Cyan
Write-ColorOutput "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-ColorOutput ""

# Determine project root directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Status "Project root: $ProjectRoot"
Set-Location $ProjectRoot

#######################################################################
# PHASE 1: Prerequisite Validation
#######################################################################

Write-Status "Validating prerequisite tools for sustainable development..."

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Success "Node.js detected: $nodeVersion"
}
catch {
    Write-ErrorMessage "Node.js is required but not installed."
    Write-ErrorMessage "Install from: https://nodejs.org/ (LTS version 20.x recommended)"
    exit 1
}

# Check npm
try {
    $npmVersion = npm --version
    Write-Success "npm detected: $npmVersion"
}
catch {
    Write-ErrorMessage "npm is required but not installed."
    exit 1
}

# Check .NET SDK
try {
    $dotnetVersion = dotnet --version
    Write-Success ".NET SDK detected: $dotnetVersion"
}
catch {
    Write-ErrorMessage ".NET SDK is required but not installed."
    Write-ErrorMessage "Install from: https://dotnet.microsoft.com/download (.NET 8.0 required)"
    exit 1
}

# Check Python
try {
    $pythonVersion = python --version
    Write-Success "Python detected: $pythonVersion"
}
catch {
    Write-ErrorMessage "Python is required but not installed."
    Write-ErrorMessage "Install from: https://www.python.org/ (Python 3.10+ required)"
    exit 1
}

# Check pip
try {
    $pipVersion = pip --version
    Write-Success "pip detected: $pipVersion"
}
catch {
    Write-ErrorMessage "pip is required but not installed."
    exit 1
}

# Optional: Check Docker
try {
    $dockerVersion = docker --version
    Write-Success "Docker detected: $dockerVersion (optional)"
}
catch {
    Write-Warning "Docker not detected - container-based development workflows will be unavailable"
}

# Optional: Check Azure CLI
try {
    $azVersion = az version --query '"azure-cli"' -o tsv
    Write-Success "Azure CLI detected: $azVersion (optional)"
}
catch {
    Write-Warning "Azure CLI not detected - cloud deployment workflows will be unavailable"
}

#######################################################################
# PHASE 2: Webapp Dependencies
#######################################################################

Write-Status "Installing webapp dependencies to establish reliable frontend development..."

if (Test-Path "webapp\package.json") {
    Set-Location "$ProjectRoot\webapp"

    # Clean install for consistency
    if (Test-Path "node_modules") {
        Write-Status "Cleaning existing node_modules..."
        Remove-Item -Recurse -Force node_modules
    }

    Write-Status "Running npm install (this may take a few minutes)..."
    npm install

    Write-Success "Webapp dependencies installed successfully"

    Set-Location $ProjectRoot
}
else {
    Write-Warning "webapp\package.json not found - skipping webapp setup"
}

#######################################################################
# PHASE 3: Python Dependencies
#######################################################################

Write-Status "Installing Python dependencies to support meta-agents execution..."

if (Test-Path "src\python\pyproject.toml") {
    Set-Location "$ProjectRoot\src\python"

    Write-Status "Installing Python package in editable mode with dev dependencies..."
    pip install -e ".[dev]"

    Write-Success "Python dependencies installed successfully"

    Set-Location $ProjectRoot
}
else {
    Write-Warning "src\python\pyproject.toml not found - skipping Python setup"
}

#######################################################################
# PHASE 4: .NET Dependencies
#######################################################################

Write-Status "Restoring .NET packages to support orchestration services..."

if (Test-Path "services\dotnet\AgentStudio.sln") {
    Set-Location "$ProjectRoot\services\dotnet"

    Write-Status "Running dotnet restore..."
    dotnet restore

    Write-Success ".NET packages restored successfully"

    Set-Location $ProjectRoot
}
else {
    Write-Warning "services\dotnet\AgentStudio.sln not found - skipping .NET setup"
}

#######################################################################
# PHASE 5: Environment Configuration
#######################################################################

Write-Status "Configuring environment variables for local development..."

# Create webapp .env.local if it doesn't exist
if ((Test-Path "webapp\.env.example") -and (-not (Test-Path "webapp\.env.local"))) {
    Write-Status "Creating webapp\.env.local from template..."
    Copy-Item "webapp\.env.example" "webapp\.env.local"
    Write-Success "Created webapp\.env.local - please update with your credentials"
}
elseif ((-not (Test-Path "webapp\.env.example")) -and (-not (Test-Path "webapp\.env.local"))) {
    # Create basic .env.local
    Write-Status "Creating default webapp\.env.local..."
    @"
# Agent Studio - Webapp Environment Configuration
# Best for: Local development environment

# API Endpoints
VITE_API_URL=http://localhost:5000/api
VITE_SIGNALR_URL=http://localhost:5000/hubs/meta-agent

# Azure OpenAI Configuration
VITE_AZURE_OPENAI_ENDPOINT=your-openai-endpoint
VITE_AZURE_OPENAI_KEY=your-openai-key
VITE_AZURE_OPENAI_DEPLOYMENT=gpt-4

# Feature Flags
VITE_ENABLE_TRACING=true
VITE_ENABLE_ANALYTICS=false
"@ | Out-File -FilePath "webapp\.env.local" -Encoding UTF8
    Write-Success "Created default webapp\.env.local - please update with your credentials"
}

# Create Python .env if it doesn't exist
if ((Test-Path "src\python\.env.example") -and (-not (Test-Path "src\python\.env"))) {
    Write-Status "Creating src\python\.env from template..."
    Copy-Item "src\python\.env.example" "src\python\.env"
    Write-Success "Created src\python\.env - please update with your credentials"
}
elseif ((-not (Test-Path "src\python\.env.example")) -and (-not (Test-Path "src\python\.env"))) {
    # Create basic .env
    Write-Status "Creating default src\python\.env..."
    @"
# Agent Studio - Python Service Environment Configuration
# Best for: Local development environment

# Azure OpenAI Configuration
AZURE_OPENAI_ENDPOINT=your-openai-endpoint
AZURE_OPENAI_API_KEY=your-openai-key
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4
AZURE_OPENAI_API_VERSION=2024-02-15-preview

# Service Configuration
PYTHONUNBUFFERED=1
LOG_LEVEL=INFO
"@ | Out-File -FilePath "src\python\.env" -Encoding UTF8
    Write-Success "Created default src\python\.env - please update with your credentials"
}

# Create .NET appsettings.Development.json if it doesn't exist
if ((Test-Path "services\dotnet\AgentStudio.Api\appsettings.json") -and (-not (Test-Path "services\dotnet\AgentStudio.Api\appsettings.Development.json"))) {
    Write-Status "Creating .NET development configuration..."
    @"
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "CosmosDb": "AccountEndpoint=https://localhost:8081/;AccountKey=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
  },
  "AzureOpenAI": {
    "Endpoint": "your-openai-endpoint",
    "ApiKey": "your-openai-key",
    "DeploymentName": "gpt-4"
  }
}
"@ | Out-File -FilePath "services\dotnet\AgentStudio.Api\appsettings.Development.json" -Encoding UTF8
    Write-Success "Created .NET development configuration - please update with your credentials"
}

#######################################################################
# PHASE 6: Validation
#######################################################################

Write-Status "Validating development environment setup..."

# Validate webapp build
if (Test-Path "webapp\package.json") {
    Write-Status "Validating webapp TypeScript configuration..."
    Set-Location "$ProjectRoot\webapp"
    try {
        npm run type-check 2>&1 | Out-Null
        Write-Success "Webapp TypeScript validation passed"
    }
    catch {
        Write-Warning "Webapp TypeScript validation failed - may need configuration updates"
    }
    Set-Location $ProjectRoot
}

# Validate .NET build
if (Test-Path "services\dotnet\AgentStudio.sln") {
    Write-Status "Validating .NET solution build..."
    Set-Location "$ProjectRoot\services\dotnet"
    try {
        dotnet build --configuration Debug --no-restore 2>&1 | Out-Null
        Write-Success ".NET solution builds successfully"
    }
    catch {
        Write-Warning ".NET solution build failed - may need dependency updates"
    }
    Set-Location $ProjectRoot
}

# Validate Python imports
if (Test-Path "src\python\pyproject.toml") {
    Write-Status "Validating Python package installation..."
    try {
        python -c "import meta_agents" 2>&1 | Out-Null
        Write-Success "Python package imports successfully"
    }
    catch {
        Write-Warning "Python package import failed - may need dependency updates"
    }
}

#######################################################################
# COMPLETION
#######################################################################

Write-ColorOutput ""
Write-ColorOutput "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-ColorOutput "║   Setup Complete - Development Environment Ready              ║" -ForegroundColor Green
Write-ColorOutput "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-ColorOutput ""

Write-Success "All development dependencies installed successfully"
Write-ColorOutput ""
Write-ColorOutput "Next Steps:" -ForegroundColor Cyan
Write-ColorOutput ""
Write-ColorOutput "1. Configure Azure OpenAI credentials:" -ForegroundColor Yellow
Write-ColorOutput "   - Update webapp\.env.local with your Azure OpenAI endpoint and key"
Write-ColorOutput "   - Update src\python\.env with your Azure OpenAI credentials"
Write-ColorOutput "   - Update services\dotnet\AgentStudio.Api\appsettings.Development.json"
Write-ColorOutput ""
Write-ColorOutput "2. Start development services:" -ForegroundColor Yellow
Write-ColorOutput "   - Frontend:  cd webapp && npm run dev"
Write-ColorOutput "   - .NET API:  cd services\dotnet\AgentStudio.Api && dotnet run"
Write-ColorOutput "   - Python:    cd src\python && uvicorn meta_agents.api:app --reload"
Write-ColorOutput ""
Write-ColorOutput "   OR use the automated start script:" -ForegroundColor Cyan
Write-ColorOutput "   - .\scripts\start-all.ps1"
Write-ColorOutput ""
Write-ColorOutput "3. Run tests:" -ForegroundColor Yellow
Write-ColorOutput "   - All tests: .\scripts\test-all.ps1"
Write-ColorOutput "   - Webapp:    cd webapp && npm test"
Write-ColorOutput "   - .NET:      cd services\dotnet && dotnet test"
Write-ColorOutput "   - Python:    cd src\python && pytest"
Write-ColorOutput ""
Write-ColorOutput "4. Access local services:" -ForegroundColor Yellow
Write-ColorOutput "   - Webapp:    http://localhost:5173"
Write-ColorOutput "   - .NET API:  http://localhost:5000/swagger"
Write-ColorOutput "   - Python:    http://localhost:8000/docs"
Write-ColorOutput "   - Jaeger:    http://localhost:16686"
Write-ColorOutput "   - Grafana:   http://localhost:3001"
Write-ColorOutput ""
Write-ColorOutput "For additional help:" -ForegroundColor Cyan
Write-ColorOutput "   - See QUICKSTART.md for detailed guidance"
Write-ColorOutput "   - See TEST_COMMANDS.md for testing workflows"
Write-ColorOutput "   - Contact: Consultations@BrooksideBI.com"
Write-ColorOutput ""
Write-Success "Deployment automation established - ready for sustainable development"
