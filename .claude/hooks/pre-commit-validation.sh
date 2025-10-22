#!/bin/bash
# Pre-Commit Validation Hook for Brookside BI Innovation Nexus
# Purpose: Prevent common repository issues before commits are made
# Usage: Configure in .claude/settings.local.json under hooks.tool-call-hook

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔍 Running pre-commit validation checks...${NC}"

# Function to get current branch
get_current_branch() {
    git branch --show-current 2>/dev/null || echo "unknown"
}

# Function to check if on protected branch
check_protected_branch() {
    local current_branch=$(get_current_branch)
    local protected_branches=("main" "master" "production" "release")

    for branch in "${protected_branches[@]}"; do
        if [[ "$current_branch" == "$branch" ]]; then
            echo -e "${RED}❌ ERROR: Direct commits to '$branch' branch are not allowed${NC}"
            echo -e "${YELLOW}📋 Best Practice:${NC}"
            echo "  1. Create a feature branch: git checkout -b feature/your-feature"
            echo "  2. Make your changes and commit"
            echo "  3. Push and create a pull request"
            echo ""
            echo -e "${YELLOW}Or if you really need to commit:${NC}"
            echo "  git checkout -b temp-branch"
            echo "  git add ."
            echo "  git commit -m 'your message'"
            return 1
        fi
    done

    echo -e "${GREEN}✅ Branch check passed: $current_branch${NC}"
    return 0
}

# Function to check for large files
check_large_files() {
    local max_size_mb=50
    local max_size_bytes=$((max_size_mb * 1024 * 1024))
    local large_files_found=0

    # Get list of staged files
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            local file_size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo 0)
            if [[ $file_size -gt $max_size_bytes ]]; then
                local size_mb=$((file_size / 1024 / 1024))
                echo -e "${RED}❌ Large file detected: $file (${size_mb}MB)${NC}"
                large_files_found=1
            fi
        fi
    done < <(git diff --cached --name-only)

    if [[ $large_files_found -eq 1 ]]; then
        echo -e "${YELLOW}⚠️  Files larger than ${max_size_mb}MB should not be committed to git${NC}"
        echo -e "${YELLOW}📋 Recommended actions:${NC}"
        echo "  • Use Azure Blob Storage for large assets"
        echo "  • Add file to .gitignore"
        echo "  • Use Git LFS for binary files: git lfs track 'pattern'"
        return 1
    fi

    echo -e "${GREEN}✅ File size check passed${NC}"
    return 0
}

# Function to detect potential secrets
check_for_secrets() {
    local secrets_found=0
    local secret_patterns=(
        "password\s*=\s*['\"][^'\"]{8,}"
        "api[_-]?key\s*=\s*['\"][^'\"]{16,}"
        "secret\s*=\s*['\"][^'\"]{16,}"
        "token\s*=\s*['\"][^'\"]{20,}"
        "AKIA[0-9A-Z]{16}"  # AWS Access Key
        "SK[0-9a-zA-Z]{32}"  # Stripe Secret Key
        "sk-[0-9a-zA-Z]{48}"  # OpenAI API Key
        "ghp_[0-9a-zA-Z]{36}"  # GitHub Personal Access Token
        "gho_[0-9a-zA-Z]{36}"  # GitHub OAuth Token
        "ntn_[0-9a-zA-Z]{50}"  # Notion API Key
    )

    # Check staged files for secrets
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            for pattern in "${secret_patterns[@]}"; do
                if grep -iE "$pattern" "$file" > /dev/null 2>&1; then
                    echo -e "${RED}❌ Potential secret detected in: $file${NC}"
                    echo -e "${YELLOW}   Pattern matched: $pattern${NC}"
                    secrets_found=1
                fi
            done
        fi
    done < <(git diff --cached --name-only)

    if [[ $secrets_found -eq 1 ]]; then
        echo -e "${YELLOW}⚠️  Potential secrets or credentials detected${NC}"
        echo -e "${YELLOW}📋 Security best practices:${NC}"
        echo "  • Store secrets in Azure Key Vault"
        echo "  • Use environment variables referenced in code"
        echo "  • Use scripts/Get-KeyVaultSecret.ps1 for retrieval"
        echo "  • Never commit .env files with actual values"
        echo ""
        echo -e "${YELLOW}If this is a false positive:${NC}"
        echo "  • Use generic placeholder values in templates (.env.example)"
        echo "  • Add file to .gitignore if it contains real secrets"
        return 1
    fi

    echo -e "${GREEN}✅ Secret detection passed${NC}"
    return 0
}

# Function to validate .env files
check_env_files() {
    local env_files_found=0

    while IFS= read -r file; do
        if [[ "$file" == *.env ]] && [[ "$file" != *.env.example ]]; then
            echo -e "${RED}❌ .env file detected: $file${NC}"
            env_files_found=1
        fi
    done < <(git diff --cached --name-only)

    if [[ $env_files_found -eq 1 ]]; then
        echo -e "${YELLOW}⚠️  .env files should not be committed${NC}"
        echo -e "${YELLOW}📋 Recommended actions:${NC}"
        echo "  1. Unstage the file: git reset HEAD $file"
        echo "  2. Add to .gitignore: echo '*.env' >> .gitignore"
        echo "  3. Use .env.example for templates with placeholder values"
        echo "  4. Store actual values in Azure Key Vault"
        return 1
    fi

    echo -e "${GREEN}✅ Environment file check passed${NC}"
    return 0
}

# Function to check for Notion database IDs or tokens
check_notion_credentials() {
    local notion_creds_found=0
    local notion_patterns=(
        "secret_[0-9a-zA-Z]{43}"  # Notion integration token
        "ntn_[0-9a-zA-Z]{50}"  # Notion API key
    )

    while IFS= read -r file; do
        if [[ -f "$file" ]] && [[ "$file" != *"CLAUDE.md" ]] && [[ "$file" != *".md" ]]; then
            for pattern in "${notion_patterns[@]}"; do
                if grep -E "$pattern" "$file" > /dev/null 2>&1; then
                    echo -e "${RED}❌ Notion credential detected in: $file${NC}"
                    notion_creds_found=1
                fi
            done
        fi
    done < <(git diff --cached --name-only)

    if [[ $notion_creds_found -eq 1 ]]; then
        echo -e "${YELLOW}⚠️  Notion credentials should not be committed${NC}"
        echo -e "${YELLOW}📋 Brookside BI Security Standard:${NC}"
        echo "  • Notion tokens stored in Azure Key Vault"
        echo "  • Database IDs can be in CLAUDE.md (public workspace)"
        echo "  • Use environment variables for API authentication"
        return 1
    fi

    echo -e "${GREEN}✅ Notion credential check passed${NC}"
    return 0
}

# Function to check for debug code
check_debug_code() {
    local debug_found=0
    local debug_patterns=(
        "console\.log\("
        "print\("
        "debugger;"
        "import pdb"
        "TODO:"
        "FIXME:"
        "HACK:"
    )

    while IFS= read -r file; do
        if [[ -f "$file" ]] && [[ "$file" =~ \.(py|js|ts|tsx|cs)$ ]]; then
            for pattern in "${debug_patterns[@]}"; do
                if grep -n "$pattern" "$file" > /dev/null 2>&1; then
                    local line_nums=$(grep -n "$pattern" "$file" | cut -d: -f1 | tr '\n' ',' | sed 's/,$//')
                    echo -e "${YELLOW}⚠️  Debug code found in $file (lines: $line_nums)${NC}"
                    echo -e "${YELLOW}   Pattern: $pattern${NC}"
                    debug_found=1
                fi
            done
        fi
    done < <(git diff --cached --name-only)

    if [[ $debug_found -eq 1 ]]; then
        echo -e "${YELLOW}⚠️  Debug statements detected${NC}"
        echo -e "${YELLOW}📋 Best practices:${NC}"
        echo "  • Remove console.log/print statements"
        echo "  • Use proper logging (Application Insights for Azure)"
        echo "  • Convert TODO/FIXME to GitHub issues"
        echo ""
        echo -e "${YELLOW}This is a warning - commit will proceed${NC}"
        # Don't fail, just warn
    fi

    return 0
}

# Main validation flow
main() {
    local all_checks_passed=0

    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Not a git repository, skipping validation${NC}"
        exit 0
    fi

    # Check if there are staged changes
    if ! git diff --cached --quiet; then
        echo -e "${GREEN}📦 Validating staged changes...${NC}"

        # Run all validation checks
        check_protected_branch || all_checks_passed=1
        check_large_files || all_checks_passed=1
        check_for_secrets || all_checks_passed=1
        check_env_files || all_checks_passed=1
        check_notion_credentials || all_checks_passed=1
        check_debug_code  # Warning only, doesn't fail

        if [[ $all_checks_passed -eq 0 ]]; then
            echo -e "${GREEN}✅ All pre-commit validation checks passed!${NC}"
            exit 0
        else
            echo -e "${RED}❌ Pre-commit validation failed${NC}"
            echo -e "${YELLOW}📋 Fix the issues above or use --no-verify to skip (not recommended)${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠️  No staged changes to validate${NC}"
        exit 0
    fi
}

# Run main function
main "$@"
