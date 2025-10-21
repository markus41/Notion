<#
.SYNOPSIS
    Agent Studio - Unified Service Launcher (PowerShell)

.DESCRIPTION
    Establish automated service orchestration to streamline local
    development workflows and improve productivity across all platform
    components.

    This script launches all Agent Studio services in separate PowerShell
    windows, providing a structured development environment for Windows.

    Best for: Windows developers requiring simultaneous execution of all services

.EXAMPLE
    .\start-all.ps1

.NOTES
    Services will launch in separate windows. Close each window to stop the service.
#>

[CmdletBinding()]
param()

# Enable strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Helper functions
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

# Display banner
Write-ColorOutput ""
Write-ColorOutput "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-ColorOutput "║   Agent Studio - Unified Service Launcher                     ║" -ForegroundColor Cyan
Write-ColorOutput "║   Streamline workflows with automated service orchestration   ║" -ForegroundColor Cyan
Write-ColorOutput "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-ColorOutput ""

# Determine project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Status "Project root: $ProjectRoot"

# Start .NET API
if (Test-Path "$ProjectRoot\services\dotnet\AgentStudio.Api\AgentStudio.Api.csproj") {
    Write-Status "Launching .NET Orchestration API..."

    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "Set-Location '$ProjectRoot\services\dotnet\AgentStudio.Api'; " +
        "Write-Host '╔════════════════════════════════════════════════════════════════╗' -ForegroundColor Cyan; " +
        "Write-Host '║   .NET Orchestration API                                       ║' -ForegroundColor Cyan; " +
        "Write-Host '╚════════════════════════════════════════════════════════════════╝' -ForegroundColor Cyan; " +
        "Write-Host ''; " +
        "Write-Host 'Starting service...' -ForegroundColor Yellow; " +
        "dotnet run"
    )

    Write-Success ".NET API launching in new window"
}
else {
    Write-Status "Skipping .NET API - project not found"
}

# Wait briefly between launches
Start-Sleep -Seconds 1

# Start Python API
$pythonApiPath = "$ProjectRoot\src\python\meta_agents\api.py"
$pythonApiMainPath = "$ProjectRoot\src\python\meta_agents\api\main.py"

if ((Test-Path $pythonApiPath) -or (Test-Path $pythonApiMainPath)) {
    Write-Status "Launching Python Meta-Agents API..."

    $uvicornTarget = if (Test-Path $pythonApiPath) { "meta_agents.api:app" } else { "meta_agents.api.main:app" }

    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "Set-Location '$ProjectRoot\src\python'; " +
        "Write-Host '╔════════════════════════════════════════════════════════════════╗' -ForegroundColor Cyan; " +
        "Write-Host '║   Python Meta-Agents API                                       ║' -ForegroundColor Cyan; " +
        "Write-Host '╚════════════════════════════════════════════════════════════════╝' -ForegroundColor Cyan; " +
        "Write-Host ''; " +
        "Write-Host 'Starting service...' -ForegroundColor Yellow; " +
        "uvicorn $uvicornTarget --reload --port 8000"
    )

    Write-Success "Python API launching in new window"
}
else {
    Write-Status "Skipping Python API - module not found"
}

# Wait briefly between launches
Start-Sleep -Seconds 1

# Start Webapp
if (Test-Path "$ProjectRoot\webapp\package.json") {
    Write-Status "Launching React Webapp..."

    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "Set-Location '$ProjectRoot\webapp'; " +
        "Write-Host '╔════════════════════════════════════════════════════════════════╗' -ForegroundColor Cyan; " +
        "Write-Host '║   React Webapp Development Server                              ║' -ForegroundColor Cyan; " +
        "Write-Host '╚════════════════════════════════════════════════════════════════╝' -ForegroundColor Cyan; " +
        "Write-Host ''; " +
        "Write-Host 'Starting service...' -ForegroundColor Yellow; " +
        "npm run dev"
    )

    Write-Success "Webapp launching in new window"
}
else {
    Write-Status "Skipping Webapp - package.json not found"
}

# Wait briefly between launches
Start-Sleep -Seconds 1

# Start Docker Services (optional)
if (Test-Path "$ProjectRoot\docker-compose.yml") {
    Write-Status "Launching supporting Docker services..."

    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "Set-Location '$ProjectRoot'; " +
        "Write-Host '╔════════════════════════════════════════════════════════════════╗' -ForegroundColor Cyan; " +
        "Write-Host '║   Supporting Services (Redis, Azurite, Jaeger, Grafana)       ║' -ForegroundColor Cyan; " +
        "Write-Host '╚════════════════════════════════════════════════════════════════╝' -ForegroundColor Cyan; " +
        "Write-Host ''; " +
        "Write-Host 'Starting services...' -ForegroundColor Yellow; " +
        "docker-compose up"
    )

    Write-Success "Docker services launching in new window"
}

# Summary
Write-ColorOutput ""
Write-ColorOutput "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-ColorOutput "║   All Services Launching                                       ║" -ForegroundColor Green
Write-ColorOutput "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-ColorOutput ""

Write-Success "Services are starting in separate windows"
Write-ColorOutput ""
Write-ColorOutput "Access points (services may take a moment to fully initialize):" -ForegroundColor Yellow
Write-ColorOutput "  - Webapp:    http://localhost:5173"
Write-ColorOutput "  - .NET API:  http://localhost:5000/swagger"
Write-ColorOutput "  - Python:    http://localhost:8000/docs"
Write-ColorOutput "  - Jaeger:    http://localhost:16686"
Write-ColorOutput "  - Grafana:   http://localhost:3001"
Write-ColorOutput ""
Write-ColorOutput "To stop services:" -ForegroundColor Cyan
Write-ColorOutput "  - Close each PowerShell window individually"
Write-ColorOutput "  - Or press Ctrl+C in each window"
Write-ColorOutput ""
Write-Success "Development environment orchestration complete"
