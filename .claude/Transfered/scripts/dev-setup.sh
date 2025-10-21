#!/bin/bash
#######################################################################
# Agent Studio - Development Environment Setup
#
# Establish reliable development environment configuration to support
# sustainable local development across all platform components.
#
# This script provides automated dependency installation, environment
# configuration, and validation to ensure consistent developer experience.
#
# Best for: New developers onboarding to the Agent Studio platform
#######################################################################

set -e  # Exit on error

# Color output for enhanced readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   Agent Studio - Development Environment Setup                ║"
echo "║   Establish structure and rules for sustainable development   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Function to print status messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Determine project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

print_status "Project root: $PROJECT_ROOT"
cd "$PROJECT_ROOT"

#######################################################################
# PHASE 1: Prerequisite Validation
#######################################################################

print_status "Validating prerequisite tools for sustainable development..."

# Check Node.js
if ! command_exists node; then
    print_error "Node.js is required but not installed."
    print_error "Install from: https://nodejs.org/ (LTS version 20.x recommended)"
    exit 1
fi
NODE_VERSION=$(node --version)
print_success "Node.js detected: $NODE_VERSION"

# Check npm
if ! command_exists npm; then
    print_error "npm is required but not installed."
    exit 1
fi
NPM_VERSION=$(npm --version)
print_success "npm detected: $NPM_VERSION"

# Check .NET SDK
if ! command_exists dotnet; then
    print_error ".NET SDK is required but not installed."
    print_error "Install from: https://dotnet.microsoft.com/download (.NET 8.0 required)"
    exit 1
fi
DOTNET_VERSION=$(dotnet --version)
print_success ".NET SDK detected: $DOTNET_VERSION"

# Check Python
if ! command_exists python && ! command_exists python3; then
    print_error "Python is required but not installed."
    print_error "Install from: https://www.python.org/ (Python 3.10+ required)"
    exit 1
fi

# Determine Python command
PYTHON_CMD="python3"
if ! command_exists python3; then
    PYTHON_CMD="python"
fi
PYTHON_VERSION=$($PYTHON_CMD --version)
print_success "Python detected: $PYTHON_VERSION"

# Check pip
if ! command_exists pip && ! command_exists pip3; then
    print_error "pip is required but not installed."
    exit 1
fi
PIP_CMD="pip3"
if ! command_exists pip3; then
    PIP_CMD="pip"
fi

# Optional: Check Docker
if command_exists docker; then
    DOCKER_VERSION=$(docker --version)
    print_success "Docker detected: $DOCKER_VERSION (optional)"
else
    print_warning "Docker not detected - container-based development workflows will be unavailable"
fi

# Optional: Check Azure CLI
if command_exists az; then
    AZ_VERSION=$(az version --query '"azure-cli"' -o tsv)
    print_success "Azure CLI detected: $AZ_VERSION (optional)"
else
    print_warning "Azure CLI not detected - cloud deployment workflows will be unavailable"
fi

#######################################################################
# PHASE 2: Webapp Dependencies
#######################################################################

print_status "Installing webapp dependencies to establish reliable frontend development..."

if [ -f "webapp/package.json" ]; then
    cd "$PROJECT_ROOT/webapp"

    # Clean install for consistency
    if [ -d "node_modules" ]; then
        print_status "Cleaning existing node_modules..."
        rm -rf node_modules
    fi

    print_status "Running npm install (this may take a few minutes)..."
    npm install

    print_success "Webapp dependencies installed successfully"

    cd "$PROJECT_ROOT"
else
    print_warning "webapp/package.json not found - skipping webapp setup"
fi

#######################################################################
# PHASE 3: Python Dependencies
#######################################################################

print_status "Installing Python dependencies to support meta-agents execution..."

if [ -f "src/python/pyproject.toml" ]; then
    cd "$PROJECT_ROOT/src/python"

    print_status "Installing Python package in editable mode with dev dependencies..."
    $PIP_CMD install -e ".[dev]"

    print_success "Python dependencies installed successfully"

    cd "$PROJECT_ROOT"
else
    print_warning "src/python/pyproject.toml not found - skipping Python setup"
fi

#######################################################################
# PHASE 4: .NET Dependencies
#######################################################################

print_status "Restoring .NET packages to support orchestration services..."

if [ -f "services/dotnet/AgentStudio.sln" ]; then
    cd "$PROJECT_ROOT/services/dotnet"

    print_status "Running dotnet restore..."
    dotnet restore

    print_success ".NET packages restored successfully"

    cd "$PROJECT_ROOT"
else
    print_warning "services/dotnet/AgentStudio.sln not found - skipping .NET setup"
fi

#######################################################################
# PHASE 5: Environment Configuration
#######################################################################

print_status "Configuring environment variables for local development..."

# Create webapp .env.local if it doesn't exist
if [ -f "webapp/.env.example" ] && [ ! -f "webapp/.env.local" ]; then
    print_status "Creating webapp/.env.local from template..."
    cp webapp/.env.example webapp/.env.local
    print_success "Created webapp/.env.local - please update with your credentials"
elif [ ! -f "webapp/.env.example" ] && [ ! -f "webapp/.env.local" ]; then
    # Create basic .env.local
    print_status "Creating default webapp/.env.local..."
    cat > webapp/.env.local << 'EOF'
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
EOF
    print_success "Created default webapp/.env.local - please update with your credentials"
fi

# Create Python .env if it doesn't exist
if [ -f "src/python/.env.example" ] && [ ! -f "src/python/.env" ]; then
    print_status "Creating src/python/.env from template..."
    cp src/python/.env.example src/python/.env
    print_success "Created src/python/.env - please update with your credentials"
elif [ ! -f "src/python/.env.example" ] && [ ! -f "src/python/.env" ]; then
    # Create basic .env
    print_status "Creating default src/python/.env..."
    cat > src/python/.env << 'EOF'
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
EOF
    print_success "Created default src/python/.env - please update with your credentials"
fi

# Create .NET appsettings.Development.json if it doesn't exist
if [ -f "services/dotnet/AgentStudio.Api/appsettings.json" ] && [ ! -f "services/dotnet/AgentStudio.Api/appsettings.Development.json" ]; then
    print_status "Creating .NET development configuration..."
    cat > services/dotnet/AgentStudio.Api/appsettings.Development.json << 'EOF'
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
EOF
    print_success "Created .NET development configuration - please update with your credentials"
fi

#######################################################################
# PHASE 6: Validation
#######################################################################

print_status "Validating development environment setup..."

# Validate webapp build
if [ -f "webapp/package.json" ]; then
    print_status "Validating webapp TypeScript configuration..."
    cd "$PROJECT_ROOT/webapp"
    if npm run type-check > /dev/null 2>&1; then
        print_success "Webapp TypeScript validation passed"
    else
        print_warning "Webapp TypeScript validation failed - may need configuration updates"
    fi
    cd "$PROJECT_ROOT"
fi

# Validate .NET build
if [ -f "services/dotnet/AgentStudio.sln" ]; then
    print_status "Validating .NET solution build..."
    cd "$PROJECT_ROOT/services/dotnet"
    if dotnet build --configuration Debug --no-restore > /dev/null 2>&1; then
        print_success ".NET solution builds successfully"
    else
        print_warning ".NET solution build failed - may need dependency updates"
    fi
    cd "$PROJECT_ROOT"
fi

# Validate Python imports
if [ -f "src/python/pyproject.toml" ]; then
    print_status "Validating Python package installation..."
    if $PYTHON_CMD -c "import meta_agents" > /dev/null 2>&1; then
        print_success "Python package imports successfully"
    else
        print_warning "Python package import failed - may need dependency updates"
    fi
fi

#######################################################################
# COMPLETION
#######################################################################

echo ""
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   Setup Complete - Development Environment Ready              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

print_success "All development dependencies installed successfully"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "1. ${YELLOW}Configure Azure OpenAI credentials:${NC}"
echo "   - Update webapp/.env.local with your Azure OpenAI endpoint and key"
echo "   - Update src/python/.env with your Azure OpenAI credentials"
echo "   - Update services/dotnet/AgentStudio.Api/appsettings.Development.json"
echo ""
echo "2. ${YELLOW}Start development services:${NC}"
echo "   - Frontend:  cd webapp && npm run dev"
echo "   - .NET API:  cd services/dotnet/AgentStudio.Api && dotnet run"
echo "   - Python:    cd src/python && uvicorn meta_agents.api:app --reload"
echo ""
echo "   ${BLUE}OR use the automated start script:${NC}"
echo "   - ./scripts/start-all.sh (requires tmux)"
echo ""
echo "3. ${YELLOW}Run tests:${NC}"
echo "   - All tests: ./scripts/test-all.sh"
echo "   - Webapp:    cd webapp && npm test"
echo "   - .NET:      cd services/dotnet && dotnet test"
echo "   - Python:    cd src/python && pytest"
echo ""
echo "4. ${YELLOW}Access local services:${NC}"
echo "   - Webapp:    http://localhost:5173"
echo "   - .NET API:  http://localhost:5000/swagger"
echo "   - Python:    http://localhost:8000/docs"
echo "   - Jaeger:    http://localhost:16686"
echo "   - Grafana:   http://localhost:3001"
echo ""
echo -e "${BLUE}For additional help:${NC}"
echo "   - See QUICKSTART.md for detailed guidance"
echo "   - See TEST_COMMANDS.md for testing workflows"
echo "   - Contact: Consultations@BrooksideBI.com"
echo ""
print_success "Deployment automation established - ready for sustainable development"
