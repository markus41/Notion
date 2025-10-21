#!/bin/bash
#######################################################################
# Agent Studio - Unified Service Launcher
#
# Establish automated service orchestration to streamline local
# development workflows and improve productivity across all platform
# components.
#
# This script launches all Agent Studio services in a coordinated
# tmux session, providing a structured development environment.
#
# Best for: Developers requiring simultaneous execution of all services
#######################################################################

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   Agent Studio - Unified Service Launcher                     ║"
echo "║   Streamline workflows with automated service orchestration   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check for tmux
if ! command -v tmux >/dev/null 2>&1; then
    print_error "tmux is required but not installed."
    echo ""
    echo "Install tmux:"
    echo "  - macOS:  brew install tmux"
    echo "  - Ubuntu: sudo apt-get install tmux"
    echo "  - RHEL:   sudo yum install tmux"
    echo ""
    echo "Alternatively, start services manually:"
    echo "  - cd webapp && npm run dev"
    echo "  - cd services/dotnet/AgentStudio.Api && dotnet run"
    echo "  - cd src/python && uvicorn meta_agents.api:app --reload"
    exit 1
fi

# Determine project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SESSION_NAME="agent-studio"

# Check if session already exists
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    print_status "Session '$SESSION_NAME' already exists"

    read -p "Kill existing session and restart? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Terminating existing session..."
        tmux kill-session -t $SESSION_NAME
    else
        print_status "Attaching to existing session..."
        tmux attach -t $SESSION_NAME
        exit 0
    fi
fi

print_status "Creating new tmux session '$SESSION_NAME'..."

# Create new detached tmux session
tmux new-session -d -s $SESSION_NAME -n "logs"

# Window 0: Logs/Info (default window)
tmux send-keys -t $SESSION_NAME:0 "cd $PROJECT_ROOT" C-m
tmux send-keys -t $SESSION_NAME:0 "clear" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '╔════════════════════════════════════════════════════════════════╗'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '║   Agent Studio - Service Monitor                               ║'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '╚════════════════════════════════════════════════════════════════╝'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:0 "echo 'Services starting in separate windows...'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:0 "echo 'Switch between windows:'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '  - Ctrl+B, 1 - .NET API'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '  - Ctrl+B, 2 - Python API'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '  - Ctrl+B, 3 - Webapp'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '  - Ctrl+B, 4 - Docker Services'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '  - Ctrl+B, d - Detach (services continue running)'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:0 "echo 'Access points:'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '  - Webapp:    http://localhost:5173'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '  - .NET API:  http://localhost:5000/swagger'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '  - Python:    http://localhost:8000/docs'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '  - Jaeger:    http://localhost:16686'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '  - Grafana:   http://localhost:3001'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo ''" C-m

# Window 1: .NET API
if [ -f "$PROJECT_ROOT/services/dotnet/AgentStudio.Api/AgentStudio.Api.csproj" ]; then
    print_status "Configuring .NET API service..."
    tmux new-window -t $SESSION_NAME:1 -n ".NET-API"
    tmux send-keys -t $SESSION_NAME:1 "cd $PROJECT_ROOT/services/dotnet/AgentStudio.Api" C-m
    tmux send-keys -t $SESSION_NAME:1 "echo 'Starting .NET Orchestration API...'" C-m
    tmux send-keys -t $SESSION_NAME:1 "dotnet run" C-m
else
    print_status "Skipping .NET API - project not found"
fi

# Window 2: Python API
if [ -f "$PROJECT_ROOT/src/python/meta_agents/api.py" ] || [ -f "$PROJECT_ROOT/src/python/meta_agents/api/main.py" ]; then
    print_status "Configuring Python meta-agents service..."
    tmux new-window -t $SESSION_NAME:2 -n "Python-API"
    tmux send-keys -t $SESSION_NAME:2 "cd $PROJECT_ROOT/src/python" C-m
    tmux send-keys -t $SESSION_NAME:2 "echo 'Starting Python Meta-Agents API...'" C-m

    # Try both possible entry points
    if [ -f "$PROJECT_ROOT/src/python/meta_agents/api.py" ]; then
        tmux send-keys -t $SESSION_NAME:2 "uvicorn meta_agents.api:app --reload --port 8000" C-m
    else
        tmux send-keys -t $SESSION_NAME:2 "uvicorn meta_agents.api.main:app --reload --port 8000" C-m
    fi
else
    print_status "Skipping Python API - module not found"
fi

# Window 3: Webapp
if [ -f "$PROJECT_ROOT/webapp/package.json" ]; then
    print_status "Configuring React webapp..."
    tmux new-window -t $SESSION_NAME:3 -n "Webapp"
    tmux send-keys -t $SESSION_NAME:3 "cd $PROJECT_ROOT/webapp" C-m
    tmux send-keys -t $SESSION_NAME:3 "echo 'Starting React Development Server...'" C-m
    tmux send-keys -t $SESSION_NAME:3 "npm run dev" C-m
else
    print_status "Skipping Webapp - package.json not found"
fi

# Window 4: Docker Services (optional)
if [ -f "$PROJECT_ROOT/docker-compose.yml" ]; then
    print_status "Configuring supporting Docker services..."
    tmux new-window -t $SESSION_NAME:4 -n "Docker"
    tmux send-keys -t $SESSION_NAME:4 "cd $PROJECT_ROOT" C-m
    tmux send-keys -t $SESSION_NAME:4 "echo 'Starting supporting services (Redis, Azurite, Jaeger, Grafana)...'" C-m
    tmux send-keys -t $SESSION_NAME:4 "docker-compose up" C-m
fi

# Select first window (logs)
tmux select-window -t $SESSION_NAME:0

print_success "All services configured and launching"
echo ""
print_status "Attaching to tmux session..."
echo ""
echo -e "${YELLOW}Tip:${NC} Press Ctrl+B, then 'd' to detach (services continue running)"
echo -e "${YELLOW}Tip:${NC} Reattach with: tmux attach -t $SESSION_NAME"
echo -e "${YELLOW}Tip:${NC} Stop all services: tmux kill-session -t $SESSION_NAME"
echo ""

sleep 2

# Attach to session
tmux attach -t $SESSION_NAME
