# Pull Request

## Description

**Clear summary of changes:**


**Related Issue:**
Closes #issue-number

**Type of Change:**
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Code refactoring
- [ ] Performance improvement
- [ ] Test coverage improvement

## Changes Made

**Modified files and components:**
- `file1.py` - Description of changes
- `file2.py` - Description of changes

**New dependencies added:**
- Package: Version - Reason

**Configuration changes:**
- Setting: Value - Impact

## Testing

**Test strategy:**
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed
- [ ] E2E tests added/updated

**Test results:**
```bash
# Paste test output here
poetry run pytest tests/ -v
```

**Test coverage:**
```bash
# Coverage report
poetry run pytest --cov=src --cov-report=term-missing
```

## Code Quality Checklist

- [ ] Code follows Brookside BI brand guidelines
- [ ] All functions have comprehensive docstrings
- [ ] Type hints are complete and accurate
- [ ] No hardcoded credentials or secrets
- [ ] All secrets reference Azure Key Vault
- [ ] Error handling is comprehensive
- [ ] Logging is appropriate and informative
- [ ] Pre-commit hooks pass (`pre-commit run --all-files`)
- [ ] Black formatting applied (`poetry run black .`)
- [ ] Ruff linting passed (`poetry run ruff check .`)
- [ ] mypy type checking passed (`poetry run mypy src/`)

## Documentation

- [ ] README.md updated (if applicable)
- [ ] ARCHITECTURE.md updated (if applicable)
- [ ] API.md updated (if applicable)
- [ ] Inline code comments added for complex logic
- [ ] Notion Knowledge Vault entry created (if new feature)

## Deployment Considerations

**Azure Function impact:**
- [ ] No deployment required
- [ ] Configuration changes needed
- [ ] New environment variables required
- [ ] Resource scaling needed

**Breaking changes:**
- [ ] No breaking changes
- [ ] Migration guide provided
- [ ] Backward compatibility maintained

**Rollback plan:**
- [ ] No special rollback needed
- [ ] Rollback procedure documented

## Cost Impact

**New software/services:**


**Estimated monthly cost change:**
- Azure: $
- Third-party: $
- Total: $

**Cost optimization opportunities:**


## Security Review

- [ ] No new authentication methods introduced
- [ ] All credentials stored in Azure Key Vault
- [ ] No sensitive data logged
- [ ] Input validation implemented
- [ ] Security scan passed (Bandit, detect-secrets)
- [ ] No new attack surface introduced

## Performance Impact

**Performance testing results:**


**Expected impact on execution time:**
- [ ] No impact
- [ ] Faster
- [ ] Slower (justified)

**Memory usage:**
- [ ] No change
- [ ] Increased (justified)
- [ ] Decreased

## Notion Integration Impact

**Database changes:**
- [ ] No database changes
- [ ] New properties added
- [ ] Relations modified
- [ ] Formulas updated

**Data migration required:**
- [ ] No migration needed
- [ ] Migration script provided

## Screenshots

**Before:**


**After:**


## Reviewer Guidance

**Areas requiring special attention:**
1.
2.
3.

**Questions for reviewers:**
1.
2.

**Testing instructions for reviewers:**
1. Step 1
2. Step 2
3. Step 3

## Checklist

- [ ] My code follows the Brookside BI brand guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented complex algorithms
- [ ] I have updated documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix/feature works
- [ ] New and existing tests pass locally
- [ ] Any dependent changes have been merged and published
- [ ] I have checked my code for security vulnerabilities
- [ ] I have verified cost impact is acceptable

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
