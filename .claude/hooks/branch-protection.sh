#!/bin/bash
# Branch Protection Hook for Brookside BI Innovation Nexus
# Purpose: Prevent destructive git operations and enforce branch strategy
# Usage: Configure in .claude/settings.local.json under hooks.tool-call-hook

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Protected branches that cannot be deleted or force-pushed
PROTECTED_BRANCHES=("main" "master" "production" "release" "develop")

# Function to check if current branch is protected
is_protected_branch() {
    local branch="$1"
    for protected in "${PROTECTED_BRANCHES[@]}"; do
        if [[ "$branch" == "$protected" ]]; then
            return 0  # True, it is protected
        fi
    done
    return 1  # False, not protected
}

# Function to detect force push attempts
check_force_push() {
    local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")

    # Check if trying to force push to protected branch
    if is_protected_branch "$current_branch"; then
        # Check for --force or -f flag in command
        if [[ "$*" == *"--force"* ]] || [[ "$*" == *"-f"* ]]; then
            echo -e "${RED}❌ BLOCKED: Force push to protected branch '$current_branch' is not allowed${NC}"
            echo -e "${YELLOW}📋 Why this is blocked:${NC}"
            echo "  • Force pushes can overwrite team members' work"
            echo "  • Protected branches maintain shared history"
            echo "  • Disrupts CI/CD pipelines and deployments"
            echo ""
            echo -e "${YELLOW}📋 What to do instead:${NC}"
            echo "  1. Create a feature branch: git checkout -b fix/your-fix"
            echo "  2. Make your changes and push normally"
            echo "  3. Create a pull request for review"
            echo ""
            echo -e "${YELLOW}If you have a conflict:${NC}"
            echo "  • Pull latest changes: git pull origin $current_branch"
            echo "  • Resolve conflicts locally"
            echo "  • Push without --force"
            return 1
        fi
    fi

    return 0
}

# Function to detect branch deletion attempts
check_branch_deletion() {
    local branch_to_delete="$1"

    if is_protected_branch "$branch_to_delete"; then
        echo -e "${RED}❌ BLOCKED: Cannot delete protected branch '$branch_to_delete'${NC}"
        echo -e "${YELLOW}📋 Protected branches:${NC}"
        for branch in "${PROTECTED_BRANCHES[@]}"; do
            echo "  • $branch"
        done
        echo ""
        echo -e "${YELLOW}📋 If you need to delete this branch:${NC}"
        echo "  • Contact repository administrator"
        echo "  • Ensure no deployments depend on this branch"
        echo "  • Consider archiving instead of deleting"
        return 1
    fi

    echo -e "${GREEN}✅ Safe to delete branch: $branch_to_delete${NC}"
    return 0
}

# Function to validate branch naming convention
validate_branch_name() {
    local branch_name="$1"

    # Skip validation for protected branches
    if is_protected_branch "$branch_name"; then
        return 0
    fi

    # Recommended branch naming: type/description
    # Types: feature, fix, docs, refactor, test, chore
    local valid_pattern="^(feature|fix|docs|refactor|test|chore|hotfix|release)/[a-z0-9-]+$"

    if ! echo "$branch_name" | grep -qE "$valid_pattern"; then
        echo -e "${YELLOW}⚠️  Branch name doesn't follow recommended convention${NC}"
        echo -e "${YELLOW}📋 Recommended format:${NC}"
        echo "  type/description-with-hyphens"
        echo ""
        echo -e "${BLUE}Valid types:${NC}"
        echo "  • feature/  - New features or capabilities"
        echo "  • fix/      - Bug fixes"
        echo "  • docs/     - Documentation changes"
        echo "  • refactor/ - Code refactoring"
        echo "  • test/     - Test additions"
        echo "  • chore/    - Maintenance tasks"
        echo "  • hotfix/   - Critical production fixes"
        echo ""
        echo -e "${BLUE}Examples:${NC}"
        echo "  feature/cost-tracking-dashboard"
        echo "  fix/authentication-timeout"
        echo "  docs/deployment-guide"
        echo ""
        echo -e "${YELLOW}Current branch: $branch_name${NC}"
        echo -e "${YELLOW}This is a warning - you can proceed${NC}"
    else
        echo -e "${GREEN}✅ Branch name follows convention: $branch_name${NC}"
    fi

    return 0
}

# Function to check for direct commits to main via GitHub
check_github_branch_protection() {
    local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")

    if is_protected_branch "$current_branch"; then
        # Get remote URL
        local remote_url=$(git config --get remote.origin.url 2>/dev/null || echo "")

        if [[ "$remote_url" == *"github.com"* ]]; then
            echo -e "${BLUE}ℹ️  This repository uses GitHub${NC}"
            echo -e "${YELLOW}📋 Recommendation:${NC}"
            echo "  • Enable branch protection rules in GitHub"
            echo "  • Require pull request reviews before merging"
            echo "  • Require status checks to pass"
            echo "  • Include administrators in restrictions"
            echo ""
            echo -e "${BLUE}Setup instructions:${NC}"
            echo "  1. Go to repository Settings → Branches"
            echo "  2. Add branch protection rule for 'main'"
            echo "  3. Enable: Require pull request reviews"
            echo "  4. Enable: Require status checks"
            echo "  5. Enable: Include administrators"
        fi
    fi

    return 0
}

# Function to detect potentially destructive operations
check_destructive_operations() {
    local git_command="$*"

    # Check for dangerous commands
    local dangerous_patterns=(
        "reset --hard"
        "clean -fd"
        "push --force"
        "push -f"
        "branch -D"
        "rebase -i.*main"
        "rebase -i.*master"
        "filter-branch"
        "reflog delete"
    )

    for pattern in "${dangerous_patterns[@]}"; do
        if echo "$git_command" | grep -qE "$pattern"; then
            echo -e "${RED}⚠️  CAUTION: Potentially destructive operation detected${NC}"
            echo -e "${YELLOW}Command pattern: $pattern${NC}"
            echo ""
            echo -e "${YELLOW}📋 Before proceeding:${NC}"
            echo "  • Ensure you have a backup or can recover"
            echo "  • Verify you're on the correct branch"
            echo "  • Consider if there's a safer alternative"
            echo ""
            echo -e "${YELLOW}Press Enter to continue or Ctrl+C to cancel${NC}"
            read -r
        fi
    done

    return 0
}

# Function to suggest proper workflow
suggest_proper_workflow() {
    echo -e "${BLUE}📋 Brookside BI Git Workflow:${NC}"
    echo ""
    echo "1. Create feature branch from main:"
    echo "   git checkout main"
    echo "   git pull origin main"
    echo "   git checkout -b feature/your-feature"
    echo ""
    echo "2. Make changes and commit:"
    echo "   git add ."
    echo "   git commit -m 'feat: Your changes'"
    echo ""
    echo "3. Push and create PR:"
    echo "   git push -u origin feature/your-feature"
    echo "   gh pr create --title 'feat: Your feature' --body 'Description'"
    echo ""
    echo "4. After approval, merge via GitHub (squash recommended)"
    echo ""
    echo "5. Clean up:"
    echo "   git checkout main"
    echo "   git pull origin main"
    echo "   git branch -d feature/your-feature"
}

# Main function
main() {
    local operation="$1"
    shift

    case "$operation" in
        check-push)
            echo -e "${GREEN}🔍 Checking push safety...${NC}"
            check_force_push "$@"
            check_github_branch_protection
            ;;
        check-delete)
            local branch="$1"
            echo -e "${GREEN}🔍 Checking branch deletion...${NC}"
            check_branch_deletion "$branch"
            ;;
        validate-branch)
            local branch="$1"
            echo -e "${GREEN}🔍 Validating branch name...${NC}"
            validate_branch_name "$branch"
            ;;
        check-command)
            echo -e "${GREEN}🔍 Checking git command safety...${NC}"
            check_destructive_operations "$@"
            ;;
        suggest-workflow)
            suggest_proper_workflow
            ;;
        *)
            echo -e "${YELLOW}Usage: $0 {check-push|check-delete|validate-branch|check-command|suggest-workflow} [args]${NC}"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
