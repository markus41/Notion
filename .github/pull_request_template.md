## Summary

<!-- Provide a clear description of the changes and their business value. Focus on outcomes and benefits. -->

**What**: [Brief description of what was changed]
**Why**: [Business justification or problem being solved]
**Impact**: [Expected improvement or value delivered]

---

## Changes

<!-- List specific technical changes made in this PR -->

-
-
-

---

## Type of Change

<!-- Check all that apply -->

- [ ] **Feature** - New functionality or capability
- [ ] **Fix** - Bug fix or defect resolution
- [ ] **Documentation** - Documentation improvements
- [ ] **Chore** - Maintenance, dependencies, or tooling
- [ ] **Refactor** - Code restructuring without behavior change
- [ ] **Performance** - Performance improvement
- [ ] **Test** - Test additions or improvements
- [ ] **CI/CD** - Build, deployment, or pipeline changes

---

## Testing

<!-- Describe testing performed and provide evidence -->

### Test Coverage
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed
- [ ] Edge cases validated
- [ ] Regression testing performed

### Test Evidence
<!-- Include screenshots, test output, or logs demonstrating successful testing -->

```
[Paste test output here if applicable]
```

---

## Related Issues

<!-- Link related issues using keywords: Closes, Fixes, Resolves -->

Closes #
Fixes #
Relates to #

---

## Breaking Changes

<!-- List any breaking changes and required migration steps -->

- [ ] **No breaking changes** in this PR

**If breaking changes exist:**
- What breaks:
- Migration steps:
- Deprecation timeline:

---

## Checklist

<!-- Ensure all items are completed before requesting review -->

### Code Quality
- [ ] Code follows [Brookside BI brand guidelines](CLAUDE.md#brookside-bi-brand-guidelines)
- [ ] All functions/classes include business-value focused comments
- [ ] No hardcoded secrets or credentials
- [ ] Error handling includes solution-oriented messages

### Git Standards
- [ ] Commit messages follow [Conventional Commits](GIT-STRUCTURE.md#commit-message-conventions)
- [ ] All commits pass pre-commit hook (secret detection, file validation)
- [ ] All commits pass commit-msg hook (brand voice, format)
- [ ] Branch name follows [naming conventions](GIT-STRUCTURE.md#branch-naming-conventions)

### Documentation
- [ ] README.md updated (if user-facing changes)
- [ ] CLAUDE.md updated (if agent behavior changes)
- [ ] CHANGELOG.md updated (if release-worthy)
- [ ] API documentation updated (if applicable)
- [ ] Architecture Decision Record created (if architectural change)

### Testing & Validation
- [ ] All CI/CD checks pass
- [ ] No merge conflicts with main branch
- [ ] Code reviewed by at least 1 team member
- [ ] All review conversations resolved

### Microsoft Ecosystem
- [ ] Microsoft 365/Azure/Power Platform solutions prioritized
- [ ] Third-party dependencies justified (if applicable)
- [ ] Azure Key Vault used for secrets (if applicable)
- [ ] Cost impact assessed (if infrastructure changes)

---

## Deployment Notes

<!-- Provide deployment-specific instructions or considerations -->

### Pre-Deployment
- [ ] Environment variables updated (if applicable)
- [ ] Database migrations prepared (if applicable)
- [ ] Azure resources provisioned (if applicable)

### Deployment Steps
<!-- List manual steps required for deployment, or note "Fully automated" -->

1.
2.
3.

### Post-Deployment Validation
<!-- Describe how to verify successful deployment -->

- [ ] Health check endpoint returns 200
- [ ] Key functionality tested in production
- [ ] Monitoring dashboards reviewed
- [ ] Error logs reviewed (no new errors)

### Rollback Plan
<!-- Describe how to rollback if issues occur -->

**Rollback Procedure**:
1.
2.
3.

---

## Screenshots

<!-- Include visual evidence of changes (UI, dashboards, logs, etc.) -->

**Before:**

**After:**

---

## Additional Context

<!-- Any additional information reviewers should know -->



---

## Reviewer Notes

<!-- For reviewers: Focus areas, specific concerns, or questions -->

**Areas requiring special attention**:
-
-

**Questions for reviewers**:
-
-

---

**Brookside BI Innovation Nexus** - *Driving measurable outcomes through structured development practices*
