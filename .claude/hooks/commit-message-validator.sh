#!/bin/bash
# Commit Message Validation Hook for Brookside BI Innovation Nexus
# Purpose: Enforce Conventional Commits format and Brookside BI brand voice
# Usage: Configure in .claude/settings.local.json under hooks.tool-call-hook

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Conventional Commit types aligned with Brookside BI
VALID_TYPES=(
    "feat"      # New feature or capability
    "fix"       # Bug fix
    "docs"      # Documentation changes
    "refactor"  # Code refactoring
    "test"      # Test additions or modifications
    "chore"     # Maintenance tasks
    "perf"      # Performance improvements
    "ci"        # CI/CD pipeline changes
    "build"     # Build system changes
    "style"     # Code style changes
    "revert"    # Revert previous commit
)

# Function to validate commit message format
validate_commit_message() {
    local commit_msg="$1"

    # Check if message is empty
    if [[ -z "$commit_msg" ]]; then
        echo -e "${RED}❌ Commit message cannot be empty${NC}"
        return 1
    fi

    # Extract first line (subject)
    local subject=$(echo "$commit_msg" | head -n 1)

    # Check if using Conventional Commits format: type(scope): description
    if ! echo "$subject" | grep -qE "^(feat|fix|docs|refactor|test|chore|perf|ci|build|style|revert)(\([a-z0-9-]+\))?: .+"; then
        echo -e "${RED}❌ Commit message does not follow Conventional Commits format${NC}"
        echo -e "${YELLOW}📋 Expected format:${NC}"
        echo "  type(scope): Brief description of change"
        echo ""
        echo -e "${BLUE}Valid types:${NC}"
        for type in "${VALID_TYPES[@]}"; do
            echo "  • $type"
        done
        echo ""
        echo -e "${BLUE}Examples (Brookside BI style):${NC}"
        echo "  feat: Establish scalable cost tracking infrastructure for multi-team operations"
        echo "  fix: Streamline authentication flow to improve user experience"
        echo "  docs: Add deployment guide to support sustainable infrastructure practices"
        echo "  refactor(api): Optimize data access layer for improved performance across workflows"
        echo ""
        echo -e "${YELLOW}Current message:${NC}"
        echo "  $subject"
        return 1
    fi

    # Extract type and description
    local type=$(echo "$subject" | sed -E 's/^([a-z]+)(\([^)]+\))?: .*/\1/')
    local description=$(echo "$subject" | sed -E 's/^[a-z]+(\([^)]+\))?: (.*)/\2/')

    # Check subject line length (50 chars recommended, 72 max)
    if [[ ${#subject} -gt 72 ]]; then
        echo -e "${YELLOW}⚠️  Subject line exceeds 72 characters (${#subject} chars)${NC}"
        echo -e "${YELLOW}📋 Best practice: Keep subject under 72 characters${NC}"
        echo "  Consider moving details to commit body"
    fi

    # Check if description starts with capital letter (Brookside BI style)
    if ! echo "$description" | grep -qE "^[A-Z]"; then
        echo -e "${YELLOW}⚠️  Description should start with capital letter (Brookside BI brand voice)${NC}"
        echo -e "${YELLOW}Current: $description${NC}"
        echo -e "${GREEN}Better:  ${description^}${NC}"
    fi

    # Check for outcome-focused language (Brookside BI brand)
    local outcome_keywords=(
        "establish" "streamline" "improve" "optimize" "enhance"
        "drive" "support" "enable" "provide" "ensure"
        "build" "create" "implement" "add" "update"
    )

    local has_outcome_focus=0
    for keyword in "${outcome_keywords[@]}"; do
        if echo "$description" | grep -iqE "\b$keyword\b"; then
            has_outcome_focus=1
            break
        fi
    done

    if [[ $has_outcome_focus -eq 0 ]]; then
        echo -e "${BLUE}💡 Brookside BI Tip: Consider outcome-focused language${NC}"
        echo "  Instead of: 'Add caching layer'"
        echo "  Try:        'Streamline data retrieval with distributed caching for improved performance'"
        echo ""
    fi

    # Check for Claude Code co-authorship (if configured)
    if echo "$commit_msg" | grep -q "Co-Authored-By: Claude"; then
        echo -e "${GREEN}✅ Claude Code co-authorship attribution present${NC}"
    fi

    echo -e "${GREEN}✅ Commit message validation passed${NC}"
    return 0
}

# Function to suggest improvements based on Brookside BI brand
suggest_improvements() {
    local commit_msg="$1"
    local subject=$(echo "$commit_msg" | head -n 1)
    local type=$(echo "$subject" | sed -E 's/^([a-z]+)(\([^)]+\))?: .*/\1/')

    echo -e "${BLUE}💡 Brookside BI Brand Guidelines:${NC}"

    case "$type" in
        feat)
            echo "  • Lead with the business benefit"
            echo "  • Example: 'feat: Establish automated viability assessment to accelerate decision-making'"
            ;;
        fix)
            echo "  • Focus on the problem solved"
            echo "  • Example: 'fix: Resolve authentication timeout to ensure reliable access across teams'"
            ;;
        docs)
            echo "  • Emphasize knowledge sharing value"
            echo "  • Example: 'docs: Add API reference to support sustainable integration development'"
            ;;
        refactor)
            echo "  • Highlight the improvement"
            echo "  • Example: 'refactor: Optimize query performance to support scalable operations'"
            ;;
        *)
            echo "  • Use action-oriented, outcome-focused language"
            echo "  • Emphasize business value and measurable results"
            ;;
    esac
}

# Main validation function
main() {
    echo -e "${GREEN}🔍 Validating commit message format...${NC}"

    # Get the commit message from the argument or stdin
    local commit_msg=""
    if [[ -n "$1" ]]; then
        # Message provided as argument
        commit_msg="$1"
    else
        # Read from stdin (when used as git commit-msg hook)
        if [[ -f "$1" ]]; then
            commit_msg=$(cat "$1")
        else
            echo -e "${RED}❌ No commit message provided${NC}"
            exit 1
        fi
    fi

    # Validate the commit message
    if validate_commit_message "$commit_msg"; then
        suggest_improvements "$commit_msg"
        echo -e "${GREEN}✅ Ready to commit${NC}"
        exit 0
    else
        echo ""
        suggest_improvements "$commit_msg"
        echo ""
        echo -e "${RED}❌ Commit message validation failed${NC}"
        echo -e "${YELLOW}📋 Fix the message format or use --no-verify to skip (not recommended)${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
