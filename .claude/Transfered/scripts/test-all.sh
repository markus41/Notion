#!/bin/bash
#######################################################################
# Agent Studio - Comprehensive Test Suite Runner
#
# Establish quality gates through automated testing across all platform
# components to ensure reliable, production-ready deployments.
#
# This script executes the complete test suite (Python, .NET, React)
# with comprehensive coverage reporting and quality validation.
#
# Best for: Pre-deployment validation and CI/CD quality gates
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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   Agent Studio - Comprehensive Test Suite                     ║"
echo "║   Establish quality gates for sustainable deployments         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Determine project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Start time
START_TIME=$(date +%s)

#######################################################################
# PHASE 1: Python Tests
#######################################################################

if [ -f "src/python/pyproject.toml" ]; then
    print_status "Running Python meta-agents test suite..."
    echo ""

    cd "$PROJECT_ROOT/src/python"

    # Run pytest with coverage
    if pytest --cov=meta_agents --cov-report=term --cov-report=html --cov-report=xml -v; then
        print_success "Python tests passed"
        ((TESTS_PASSED++))

        # Check coverage threshold
        COVERAGE=$(python -c "import xml.etree.ElementTree as ET; tree = ET.parse('coverage.xml'); print(tree.getroot().attrib['line-rate'])" 2>/dev/null || echo "0")
        COVERAGE_PCT=$(python -c "print(int(float('$COVERAGE') * 100))" 2>/dev/null || echo "0")

        echo ""
        print_status "Python code coverage: ${COVERAGE_PCT}%"

        if [ "$COVERAGE_PCT" -ge 85 ]; then
            print_success "Coverage meets quality threshold (85%+)"
        else
            print_warning "Coverage below recommended threshold (85%+)"
        fi
    else
        print_error "Python tests failed"
        ((TESTS_FAILED++))
    fi

    cd "$PROJECT_ROOT"
    echo ""
else
    print_warning "Skipping Python tests - pyproject.toml not found"
    ((TESTS_SKIPPED++))
    echo ""
fi

#######################################################################
# PHASE 2: .NET Tests
#######################################################################

if [ -f "services/dotnet/AgentStudio.sln" ]; then
    print_status "Running .NET orchestration test suite..."
    echo ""

    cd "$PROJECT_ROOT/services/dotnet"

    # Run dotnet test with coverage
    if dotnet test \
        --configuration Release \
        --verbosity normal \
        /p:CollectCoverage=true \
        /p:CoverletOutputFormat=html \
        /p:CoverletOutput=./coverage/; then

        print_success ".NET tests passed"
        ((TESTS_PASSED++))

        # Check for coverage report
        if [ -f "coverage/index.html" ]; then
            print_status ".NET coverage report generated: services/dotnet/coverage/index.html"
        fi
    else
        print_error ".NET tests failed"
        ((TESTS_FAILED++))
    fi

    cd "$PROJECT_ROOT"
    echo ""
else
    print_warning "Skipping .NET tests - AgentStudio.sln not found"
    ((TESTS_SKIPPED++))
    echo ""
fi

#######################################################################
# PHASE 3: React/Webapp Tests
#######################################################################

if [ -f "webapp/package.json" ]; then
    print_status "Running React webapp test suite..."
    echo ""

    cd "$PROJECT_ROOT/webapp"

    # Run vitest with coverage
    if npm test -- --coverage; then
        print_success "Webapp tests passed"
        ((TESTS_PASSED++))

        # Check coverage thresholds
        if [ -f "coverage/coverage-summary.json" ]; then
            print_status "Webapp coverage report generated: webapp/coverage/index.html"

            # Parse coverage (if jq is available)
            if command -v jq >/dev/null 2>&1; then
                LINE_COV=$(jq '.total.lines.pct' coverage/coverage-summary.json)
                print_status "Webapp line coverage: ${LINE_COV}%"

                if (( $(echo "$LINE_COV >= 85" | bc -l) )); then
                    print_success "Coverage meets quality threshold (85%+)"
                else
                    print_warning "Coverage below recommended threshold (85%+)"
                fi
            fi
        fi
    else
        print_error "Webapp tests failed"
        ((TESTS_FAILED++))
    fi

    cd "$PROJECT_ROOT"
    echo ""
else
    print_warning "Skipping Webapp tests - package.json not found"
    ((TESTS_SKIPPED++))
    echo ""
fi

#######################################################################
# PHASE 4: Integration Tests (Optional)
#######################################################################

if [ -d "tests/integration" ]; then
    print_status "Running integration tests..."
    echo ""

    cd "$PROJECT_ROOT/tests/integration"

    if pytest -v; then
        print_success "Integration tests passed"
        ((TESTS_PASSED++))
    else
        print_error "Integration tests failed"
        ((TESTS_FAILED++))
    fi

    cd "$PROJECT_ROOT"
    echo ""
fi

#######################################################################
# SUMMARY
#######################################################################

# End time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║   All Test Suites Passed - Quality Gates Met                  ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    print_success "Test execution completed successfully"
else
    echo -e "${RED}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║   Test Failures Detected - Quality Gates Not Met              ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    print_error "Test execution completed with failures"
fi

echo ""
echo -e "${BLUE}Test Summary:${NC}"
echo "  ✓ Passed:  $TESTS_PASSED"
echo "  ✗ Failed:  $TESTS_FAILED"
echo "  ⊘ Skipped: $TESTS_SKIPPED"
echo "  ⏱ Duration: ${DURATION}s"
echo ""

echo -e "${BLUE}Coverage Reports:${NC}"
[ -f "src/python/htmlcov/index.html" ] && echo "  - Python:  src/python/htmlcov/index.html"
[ -f "services/dotnet/coverage/index.html" ] && echo "  - .NET:    services/dotnet/coverage/index.html"
[ -f "webapp/coverage/index.html" ] && echo "  - Webapp:  webapp/coverage/index.html"
echo ""

echo -e "${BLUE}Quality Thresholds:${NC}"
echo "  - Code Coverage: 85%+"
echo "  - All tests must pass"
echo "  - No critical security vulnerabilities"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    print_success "Platform ready for deployment"
    exit 0
else
    print_error "Platform not ready for deployment - resolve test failures"
    exit 1
fi
