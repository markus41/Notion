---
name: Bug Report
about: Report a defect or unexpected behavior in the repository analyzer
title: '[BUG] '
labels: bug, needs-triage
assignees: ''
---

## Bug Description

**Clear, concise description of the bug:**


**Expected behavior:**


**Actual behavior:**


## Reproduction Steps

1. Step 1
2. Step 2
3. Step 3

**Minimal reproduction code (if applicable):**

```python
# Code to reproduce the issue
```

## Environment

**Operating System:**
- [ ] Windows
- [ ] macOS
- [ ] Linux (specify distribution)

**Python Version:**
```bash
python --version
```

**Poetry Version:**
```bash
poetry --version
```

**Azure CLI Version (if Azure-related):**
```bash
az --version
```

**Package Versions:**
```bash
poetry show | grep -E "(httpx|pydantic|azure)"
```

## Error Messages and Logs

**Error output:**
```
Paste full error message and stack trace here
```

**Relevant log files:**
```
Include logs from ~/.brookside-analyzer/logs/ if applicable
```

## Additional Context

**Screenshots (if UI-related):**


**Related Issues:**
- #issue-number

**Attempted Solutions:**


**Impact:**
- [ ] Blocking - Cannot use analyzer at all
- [ ] High - Major functionality broken
- [ ] Medium - Workaround exists
- [ ] Low - Minor inconvenience

## Checklist

- [ ] I have searched existing issues to avoid duplicates
- [ ] I have included all relevant environment information
- [ ] I have provided a minimal reproduction case
- [ ] I have checked the documentation and troubleshooting guide
