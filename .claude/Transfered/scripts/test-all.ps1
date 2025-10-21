<#
.SYNOPSIS
    Agent Studio - Comprehensive Test Suite Runner (PowerShell)

.DESCRIPTION
    Establish quality gates through automated testing across all platform
    components to ensure reliable, production-ready deployments.

    This script executes the complete test suite (Python, .NET, React)
    with comprehensive coverage reporting and quality validation.

    Best for: Pre-deployment validation and CI/CD quality gates

.EXAMPLE
    .\test-all.ps1

.NOTES
    Requires: All development dependencies installed via dev-setup.ps1
#>

[CmdletBinding()]
param()

# Enable strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"  # Continue on test failures to run all suites

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

function Write-ErrorMessage {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARNING] $Message" -ForegroundColor Yellow
}

# Display banner
Write-ColorOutput ""
Write-ColorOutput "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-ColorOutput "║   Agent Studio - Comprehensive Test Suite                     ║" -ForegroundColor Cyan
Write-ColorOutput "║   Establish quality gates for sustainable deployments         ║" -ForegroundColor Cyan
Write-ColorOutput "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-ColorOutput ""

# Determine project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Set-Location $ProjectRoot

# Track test results
$TestsPassed = 0
$TestsFailed = 0
$TestsSkipped = 0

# Start time
$StartTime = Get-Date

#######################################################################
# PHASE 1: Python Tests
#######################################################################

if (Test-Path "src\python\pyproject.toml") {
    Write-Status "Running Python meta-agents test suite..."
    Write-Host ""

    Set-Location "$ProjectRoot\src\python"

    # Run pytest with coverage
    $pythonTestResult = $true
    try {
        pytest --cov=meta_agents --cov-report=term --cov-report=html --cov-report=xml -v

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Python tests passed"
            $TestsPassed++

            # Check coverage if xml exists
            if (Test-Path "coverage.xml") {
                Write-Status "Python coverage report generated: src\python\htmlcov\index.html"
            }
        }
        else {
            throw "Python tests failed"
        }
    }
    catch {
        Write-ErrorMessage "Python tests failed"
        $TestsFailed++
        $pythonTestResult = $false
    }

    Set-Location $ProjectRoot
    Write-Host ""
}
else {
    Write-Warning "Skipping Python tests - pyproject.toml not found"
    $TestsSkipped++
    Write-Host ""
}

#######################################################################
# PHASE 2: .NET Tests
#######################################################################

if (Test-Path "services\dotnet\AgentStudio.sln") {
    Write-Status "Running .NET orchestration test suite..."
    Write-Host ""

    Set-Location "$ProjectRoot\services\dotnet"

    # Run dotnet test with coverage
    try {
        dotnet test `
            --configuration Release `
            --verbosity normal `
            /p:CollectCoverage=true `
            /p:CoverletOutputFormat=html `
            /p:CoverletOutput=./coverage/

        if ($LASTEXITCODE -eq 0) {
            Write-Success ".NET tests passed"
            $TestsPassed++

            if (Test-Path "coverage\index.html") {
                Write-Status ".NET coverage report generated: services\dotnet\coverage\index.html"
            }
        }
        else {
            throw ".NET tests failed"
        }
    }
    catch {
        Write-ErrorMessage ".NET tests failed"
        $TestsFailed++
    }

    Set-Location $ProjectRoot
    Write-Host ""
}
else {
    Write-Warning "Skipping .NET tests - AgentStudio.sln not found"
    $TestsSkipped++
    Write-Host ""
}

#######################################################################
# PHASE 3: React/Webapp Tests
#######################################################################

if (Test-Path "webapp\package.json") {
    Write-Status "Running React webapp test suite..."
    Write-Host ""

    Set-Location "$ProjectRoot\webapp"

    # Run vitest with coverage
    try {
        npm test -- --coverage

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Webapp tests passed"
            $TestsPassed++

            if (Test-Path "coverage\index.html") {
                Write-Status "Webapp coverage report generated: webapp\coverage\index.html"
            }
        }
        else {
            throw "Webapp tests failed"
        }
    }
    catch {
        Write-ErrorMessage "Webapp tests failed"
        $TestsFailed++
    }

    Set-Location $ProjectRoot
    Write-Host ""
}
else {
    Write-Warning "Skipping Webapp tests - package.json not found"
    $TestsSkipped++
    Write-Host ""
}

#######################################################################
# PHASE 4: Integration Tests (Optional)
#######################################################################

if (Test-Path "tests\integration") {
    Write-Status "Running integration tests..."
    Write-Host ""

    Set-Location "$ProjectRoot\tests\integration"

    try {
        pytest -v

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Integration tests passed"
            $TestsPassed++
        }
        else {
            throw "Integration tests failed"
        }
    }
    catch {
        Write-ErrorMessage "Integration tests failed"
        $TestsFailed++
    }

    Set-Location $ProjectRoot
    Write-Host ""
}

#######################################################################
# SUMMARY
#######################################################################

# End time
$EndTime = Get-Date
$Duration = ($EndTime - $StartTime).TotalSeconds

Write-Host ""
Write-ColorOutput "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

if ($TestsFailed -eq 0) {
    Write-ColorOutput ""
    Write-ColorOutput "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColorOutput "║   All Test Suites Passed - Quality Gates Met                  ║" -ForegroundColor Green
    Write-ColorOutput "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-ColorOutput ""

    Write-Success "Test execution completed successfully"
}
else {
    Write-ColorOutput ""
    Write-ColorOutput "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-ColorOutput "║   Test Failures Detected - Quality Gates Not Met              ║" -ForegroundColor Red
    Write-ColorOutput "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-ColorOutput ""

    Write-ErrorMessage "Test execution completed with failures"
}

Write-Host ""
Write-ColorOutput "Test Summary:" -ForegroundColor Cyan
Write-Host "  ✓ Passed:  $TestsPassed"
Write-Host "  ✗ Failed:  $TestsFailed"
Write-Host "  ⊘ Skipped: $TestsSkipped"
Write-Host "  ⏱ Duration: $([math]::Round($Duration, 2))s"
Write-Host ""

Write-ColorOutput "Coverage Reports:" -ForegroundColor Cyan
if (Test-Path "src\python\htmlcov\index.html") { Write-Host "  - Python:  src\python\htmlcov\index.html" }
if (Test-Path "services\dotnet\coverage\index.html") { Write-Host "  - .NET:    services\dotnet\coverage\index.html" }
if (Test-Path "webapp\coverage\index.html") { Write-Host "  - Webapp:  webapp\coverage\index.html" }
Write-Host ""

Write-ColorOutput "Quality Thresholds:" -ForegroundColor Cyan
Write-Host "  - Code Coverage: 85%+"
Write-Host "  - All tests must pass"
Write-Host "  - No critical security vulnerabilities"
Write-Host ""

if ($TestsFailed -eq 0) {
    Write-Success "Platform ready for deployment"
    exit 0
}
else {
    Write-ErrorMessage "Platform not ready for deployment - resolve test failures"
    exit 1
}
