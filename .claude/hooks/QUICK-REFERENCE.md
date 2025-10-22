# Claude Code Hooks - Quick Reference Card

**One-page guide for common repository safety scenarios**

---

## 🚀 Quick Setup (5 minutes)

```powershell
# 1. Install hooks
.\\.claude\hooks\Install-Hooks.ps1

# 2. Restart Claude Code

# 3. Test
git add .
git commit -m "test: Validate hooks are working"
```

---

## ✅ Good Practices (Do This)

### Commit Messages
```bash
# ✅ Outcome-focused with proper format
git commit -m "feat: Establish scalable cost tracking for multi-team operations"
git commit -m "fix: Resolve authentication timeout to ensure reliable access"
git commit -m "docs: Add API guide to support sustainable development"
git commit -m "refactor: Optimize query performance for improved scalability"
```

### Branch Strategy
```bash
# ✅ Always work on feature branches
git checkout -b feature/cost-tracking
git add .
git commit -m "feat: Add cost tracking dashboard"
git push -u origin feature/cost-tracking

# ✅ Create PR for review
gh pr create --title "feat: Cost tracking dashboard" --body "Adds cost visualization"
```

### Secret Management
```bash
# ✅ Use Azure Key Vault
$apiKey = .\scripts\Get-KeyVaultSecret.ps1 -SecretName "notion-api-key"

# ✅ Use environment variables
$env:NOTION_API_KEY = "retrieved-from-keyvault"

# ✅ Template files with placeholders
# .env.example
NOTION_API_KEY=your-notion-api-key-here
DATABASE_URL=your-database-connection-string
```

---

## ❌ Bad Practices (Avoid This)

### Commit Messages
```bash
# ❌ No type prefix
git commit -m "fixed bug"

# ❌ Not outcome-focused
git commit -m "feat: add caching"

# ❌ Lowercase description
git commit -m "feat: add new feature"

# ❌ Too vague
git commit -m "update stuff"
```

### Branch Strategy
```bash
# ❌ Committing directly to main
git checkout main
git add .
git commit -m "quick fix"  # BLOCKED by hooks

# ❌ Force pushing to protected branches
git push --force origin main  # BLOCKED by hooks

# ❌ Deleting protected branches
git branch -D main  # BLOCKED by hooks
```

### Secret Management
```bash
# ❌ Hardcoded secrets
API_KEY=sk-1234567890abcdef  # BLOCKED by hooks

# ❌ Committing .env files
git add .env  # BLOCKED by hooks

# ❌ Notion tokens in code
const token = "ntn_abc123..."  # BLOCKED by hooks
```

---

## 🔥 Common Scenarios

### Scenario 1: "I committed to main by mistake"
```bash
# Don't panic! Move your commit to a feature branch
git branch feature/my-changes  # Create branch with current commit
git reset --hard HEAD~1  # Remove commit from main
git checkout feature/my-changes  # Switch to feature branch
git push -u origin feature/my-changes  # Push feature branch
```

### Scenario 2: "Hook detected a secret I need to remove"
```bash
# 1. Unstage the file
git reset HEAD path/to/file

# 2. Remove the secret from the file
# Edit file and replace secret with placeholder or Key Vault reference

# 3. Stage and commit again
git add path/to/file
git commit -m "fix: Remove hardcoded secret, use Key Vault reference"
```

### Scenario 3: "I need to bypass hooks for emergency"
```bash
# Emergency hotfix (use sparingly)
git commit --no-verify -m "hotfix: Critical production fix"

# Then create proper PR later
git checkout -b hotfix/proper-fix
git cherry-pick HEAD~1
git push -u origin hotfix/proper-fix
```

### Scenario 4: "Hook says my file is too large"
```bash
# For files >50MB

# Option 1: Use Azure Blob Storage
az storage blob upload --file large-file.zip --container assets

# Option 2: Add to .gitignore
echo "large-file.zip" >> .gitignore

# Option 3: Use Git LFS (for binary files)
git lfs install
git lfs track "*.zip"
git add .gitattributes
git add large-file.zip
git commit -m "chore: Add large file via Git LFS"
```

### Scenario 5: "I want to fix my commit message"
```bash
# Before pushing
git commit --amend -m "feat: Corrected message with proper format"

# After pushing to feature branch
git commit --amend -m "feat: Corrected message"
git push --force-with-lease origin feature/my-branch
```

---

## 🎯 Hook Behavior Reference

| Scenario | Hook Triggered | Severity | Can Bypass? |
|----------|---------------|----------|-------------|
| Commit to main | pre-commit-validation | **ERROR** | --no-verify |
| Large file (>50MB) | pre-commit-validation | **ERROR** | --no-verify |
| Secret detected | pre-commit-validation | **ERROR** | --no-verify |
| .env file | pre-commit-validation | **ERROR** | --no-verify |
| Invalid commit message | commit-message-validator | **ERROR** | --no-verify |
| Debug code (console.log) | pre-commit-validation | WARNING | N/A |
| Force push to main | branch-protection | **BLOCKED** | Manual git |
| Delete main branch | branch-protection | **BLOCKED** | Manual git |
| Weak commit message | commit-message-validator | WARNING | Continue |

---

## 🔍 Debugging Hooks

### Check if hooks are enabled
```powershell
# View Claude settings
cat .claude\settings.local.json | Select-String -Pattern "hooks"

# Test hook directly
bash .claude/hooks/pre-commit-validation.sh
```

### See what triggered a hook
```bash
# Check git status
git status

# See what's staged
git diff --cached

# Check current branch
git branch --show-current
```

### Bypass hooks temporarily
```bash
# For testing only
git commit --no-verify -m "test: Bypass validation"

# Or disable in settings.local.json
# Remove or comment out hooks section
```

---

## 📋 Commit Message Templates

Copy these templates for common scenarios:

```bash
# New Feature
git commit -m "feat(module): Establish [capability] to [business outcome]"

# Bug Fix
git commit -m "fix(module): Resolve [issue] to [improvement]"

# Documentation
git commit -m "docs: Add [documentation] to support [use case]"

# Refactoring
git commit -m "refactor(module): Optimize [component] for improved [metric]"

# Performance
git commit -m "perf(module): Streamline [operation] to reduce [metric] by [amount]"

# Tests
git commit -m "test(module): Add coverage for [scenario] to ensure [quality]"

# Maintenance
git commit -m "chore: Update [dependency] to maintain [stability/security]"
```

---

## 🛠️ Customization

### Change file size limit (default 50MB)
```bash
# Edit .claude/hooks/pre-commit-validation.sh
local max_size_mb=100  # Change to desired limit
```

### Add custom secret patterns
```bash
# Edit .claude/hooks/pre-commit-validation.sh
local secret_patterns=(
    # ... existing patterns ...
    "your-custom-api-key-[0-9a-z]{32}"
)
```

### Add custom protected branches
```bash
# Edit .claude/hooks/branch-protection.sh
PROTECTED_BRANCHES=("main" "master" "production" "staging")
```

---

## 📞 Quick Help

| Issue | Solution |
|-------|----------|
| Hook not running | Restart Claude Code, check settings.local.json |
| Permission denied | Install Git Bash, make scripts executable |
| False positive (secret) | Use .env.example, add placeholders |
| Hook too strict | Customize patterns in hook files |
| Need emergency bypass | Use --no-verify (sparingly!) |

---

## 📚 Full Documentation

- **Complete Guide**: `.claude/hooks/README.md`
- **Installation**: `.claude/hooks/Install-Hooks.ps1`
- **Settings Example**: `.claude/hooks/claude-settings-example.json`

---

*Print this card for quick reference at your desk!*

**Brookside BI Innovation Nexus - Repository Safety Made Simple**
